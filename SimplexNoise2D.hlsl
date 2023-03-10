#ifndef SIMPLEX_NOISE_2D_INCLUDED
#define SIMPLEX_NOISE_2D_INCLUDED

//
// psrddnoise2.glsl
//
// Authors: Stefan Gustavson (stefan.gustavson@gmail.com)
// and Ian McEwan (ijm567@gmail.com)
// Version 2021-12-02, published under the MIT license (see below)
//
// Copyright (c) 2021 Stefan Gustavson and Ian McEwan.
//
// Permission is hereby granted, free of charge, to any person obtaining a
// copy of this software and associated documentation files (the "Software"),
// to deal in the Software without restriction, including without limitation
// the rights to use, copy, modify, merge, publish, distribute, sublicense,
// and/or sell copies of the Software, and to permit persons to whom the
// Software is furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included
// in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
// THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
// FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
// DEALINGS IN THE SOFTWARE.
//

//
// Periodic (tiling) 2-D simplex noise (hexagonal lattice gradient noise)
// with rotating gradients and first and second order analytic derivatives.
//
// This is (yet) another variation on simplex noise. Unlike previous
// implementations, the grid is axis-aligned and slightly stretched in
// the y direction to permit rectangular tiling.
// The noise pattern can be made to tile seamlessly to any integer period
// in x and any even integer period in y. Odd periods may be specified
// for y, but then the actual tiling period will be twice that number.
//
// The rotating gradients give the appearance of a swirling motion, and
// can serve a similar purpose for animation as motion along z in 3-D
// noise. The rotating gradients in conjunction with the analytic
// derivatives allow for "flow noise" effects as presented by Ken
// Perlin and Fabrice Neyret.
//


//
// 2-D tiling simplex noise with rotating gradients and first and
// second order analytical derivatives.
// "float2 x" is the point (x,y) to evaluate,
// "float2 period" is the desired periods along x and y, and
// "float rotation" is the rotation (in radians) for the swirling gradients.
// The "float" return value is the noise value n,
// the "out float2 gradient" argument returns the first order derivatives,
// and "out float3 dg" returns the second order derivatives as
// dg = (dn2/dx2, dn2/dy2, dn2/dxy)
//
// Setting either period to 0.0 or a negative value will skip the wrapping
// along that dimension. Setting both periods to 0.0 makes the function
// execute about 10% faster.
//
// Not using the return value for some or all of the first or second order
// derivatives will make the compiler eliminate the code for computing them.
// If "dg" is not used, the function executes 15% faster. If neither
// "gradient" nor "dg" are used, the function executes 25-30% faster.
//
// The rotation by rotation uses one single addition. Unlike the 3-D version
// of psrddnoise(), setting rotation == 0.0 gives no speedup.
//

#include "NoiseCommon.hlsl"

float SimplexNoise(float2 x, out float2 gradient, out float3 dg, float2 period = 0.0, float rotation = 0.0)
{
	// Transform to simplex space (axis-aligned hexagonal grid)
	float2 uv = float2(x.x + x.y * 0.5, x.y);

	// Determine which simplex we're in, with i0 being the "base"
	float2 i0 = floor(uv);
	float2 f0 = frac(uv);
	// o1 is the offset in simplex space to the second corner
	float cmp = step(f0.y, f0.x);
	float2 o1 = float2(cmp, 1.0 - cmp);

	// Enumerate the remaining simplex corners
	float2 i1 = i0 + o1;
	float2 i2 = i0 + float2(1.0, 1.0);

	// Transform corners back to texture space
	float2 v0 = float2(i0.x - i0.y * 0.5, i0.y);
	float2 v1 = float2(v0.x + o1.x - o1.y * 0.5, v0.y + o1.y);
	float2 v2 = float2(v0.x + 0.5, v0.y + 1.0);

	// Compute vectors from v to each of the simplex corners
	float2 x0 = x - v0;
	float2 x1 = x - v1;
	float2 x2 = x - v2;

	float3 iu, iv;
	float3 xw, yw;

	// Wrap to periods, if desired
	if (any(period > 0.0))
	{
		xw = float3(v0.x, v1.x, v2.x);
		yw = float3(v0.y, v1.y, v2.y);
		if (period.x > 0.0)
			xw = mod(float3(v0.x, v1.x, v2.x), period.x);
		if (period.y > 0.0)
			yw = mod(float3(v0.y, v1.y, v2.y), period.y);
		// Transform back to simplex space and fix rounding errors
		iu = floor(xw + 0.5 * yw + 0.5);
		iv = floor(yw + 0.5);
	}
	else
	{ // Shortcut if neither x nor y periods are specified
		iu = float3(i0.x, i1.x, i2.x);
		iv = float3(i0.y, i1.y, i2.y);
	}

	// Compute one pseudo-random hash value for each corner
	float3 hash = mod(iu, 289.0);
	hash = mod((hash * 51.0 + 2.0) * hash + iv, 289.0);
	hash = mod((hash * 34.0 + 10.0) * hash, 289.0);

	// Pick a pseudo-random angle and add the desired rotation
	float3 psi = hash * 0.07482 + rotation;
	float3 gx = cos(psi);
	float3 gy = sin(psi);

	// Reorganize for dot products below
	float2 g0 = float2(gx.x, gy.x);
	float2 g1 = float2(gx.y, gy.y);
	float2 g2 = float2(gx.z, gy.z);

	// Radial decay with distance from each simplex corner
	float3 w = 0.8 - float3(dot(x0, x0), dot(x1, x1), dot(x2, x2));
	w = max(w, 0.0);
	float3 w2 = w * w;
	float3 w4 = w2 * w2;

	// The value of the linear ramp from each of the corners
	float3 gdotx = float3(dot(g0, x0), dot(g1, x1), dot(g2, x2));

	// Multiply by the radial decay and sum up the noise value
	float n = dot(w4, gdotx);

	// Compute the first order partial derivatives
	float3 w3 = w2 * w;
	float3 dw = -8.0 * w3 * gdotx;
	float2 dn0 = w4.x * g0 + dw.x * x0;
	float2 dn1 = w4.y * g1 + dw.y * x1;
	float2 dn2 = w4.z * g2 + dw.z * x2;
	gradient = 10.9 * (dn0 + dn1 + dn2);

	// Compute the second order partial derivatives
	float3 dg0, dg1, dg2;
	float3 dw2 = 48.0 * w2 * gdotx;
	// d2n/dx2 and d2n/dy2
	dg0.xy = dw2.x * x0 * x0 - 8.0 * w3.x * (2.0 * g0 * x0 + gdotx.x);
	dg1.xy = dw2.y * x1 * x1 - 8.0 * w3.y * (2.0 * g1 * x1 + gdotx.y);
	dg2.xy = dw2.z * x2 * x2 - 8.0 * w3.z * (2.0 * g2 * x2 + gdotx.z);
	// d2n/dxy
	dg0.z = dw2.x * x0.x * x0.y - 8.0 * w3.x * dot(g0, x0.yx);
	dg1.z = dw2.y * x1.x * x1.y - 8.0 * w3.y * dot(g1, x1.yx);
	dg2.z = dw2.z * x2.x * x2.y - 8.0 * w3.z * dot(g2, x2.yx);
	dg = 10.9 * (dg0 + dg1 + dg2);

	// Scale the return value to fit nicely into the range [-1,1]
	return 10.9 * n;
}

float SimplexNoise(float2 x, out float2 gradient, float2 period = 0.0, float rotation = 0.0)
{
	float3 dg;
	return SimplexNoise(x, gradient, dg, period, rotation);
}

float SimplexNoise(float2 x, float2 period = 0.0, float rotation = 0.0)
{
	float2 gradient;
	return SimplexNoise(x, gradient, period, rotation);
}

#endif
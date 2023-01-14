Unity port of https://github.com/stegu/webgl-noise, with simplex noise improvements from https://github.com/stegu/psrdnoise/.

To use, add this line to your shaders: "#include "packages/com.arycama.webglnoiseunity/Noise.hlsl", which will include all the noise variants.

Or you can reference the individual hlsl includes for the relevant noise type.

Brief description
Cellular2D: 2D Worley/Voronoi/Cellular noise.
Cellular2x2: Similar to above, but only checks up, down, left and right which improves performance, but can introduce artifacts.
Cellular3D: 3D Worley/Voronoi/Cellular noise
Cellular2x2x2: Similar to Cellular3D, but does not check diagonals. Performs better but again may introduce artifacts.

Note that these return a float2, containing the distance to closest feature, and 2nd closest feature. Often you'll just want the first feature, so just use the x component.
Each cellular noise has a periodic variant

SimplexNoise2D: 2D simplex noise, has overloads to control repetition (set to 0 for no repetition), rotation (Range is in 0 to 2*PI), and can output analytical derivatives
SimplexNoise2D: 3D simplex noise, same as above but in 3D. 

There is also a simple sample shader in Sample/NoiseTest, showing how you can use these functions to generate fractal noise, and control tiling/repetion/rotation etc.

Note this does not include all the perlin variants, or the 4D variant, as simplex noise is likely to be better in all situations, and 4d noise is not as commonly used. These could be added in the future however.


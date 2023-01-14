#ifndef NOISE_COMMON_INCLUDED
#define NOISE_COMMON_INCLUDED

// Apparently this is the equivalent of glsl's mod in hlsl
float1 mod(float1 x, float1 y) { return x - y * floor(x / y); }
float2 mod(float2 x, float2 y) { return x - y * floor(x / y); }
float3 mod(float3 x, float3 y) { return x - y * floor(x / y); }
float4 mod(float4 x, float4 y) { return x - y * floor(x / y); }

// Modulo 289 without a division (only multiplications)
float1 mod289(float1 x) { return x - floor(x * (1.0 / 289.0)) * 289.0; }
float2 mod289(float2 x) { return x - floor(x * (1.0 / 289.0)) * 289.0; }
float3 mod289(float3 x) { return x - floor(x * (1.0 / 289.0)) * 289.0; }
float4 mod289(float4 x) { return x - floor(x * (1.0 / 289.0)) * 289.0; }

// Modulo 7 without a division
float1 mod7(float1 x) {	return x - floor(x * (1.0 / 7.0)) * 7.0; }
float2 mod7(float2 x) {	return x - floor(x * (1.0 / 7.0)) * 7.0; }
float3 mod7(float3 x) {	return x - floor(x * (1.0 / 7.0)) * 7.0; }
float4 mod7(float4 x) {	return x - floor(x * (1.0 / 7.0)) * 7.0; }

// Permutation polynomial: (34x^2 + 6x) mod 289
float1 permute(float1 x) { return mod289((34.0 * x + 10.0) * x); }
float2 permute(float2 x) { return mod289((34.0 * x + 10.0) * x); }
float3 permute(float3 x) { return mod289((34.0 * x + 10.0) * x); }
float4 permute(float4 x) { return mod289((34.0 * x + 10.0) * x); }

#endif
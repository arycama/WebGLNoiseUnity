#include "../Noise.hlsl"

struct VertexInput
{
	float3 positionOS : POSITION;
	float2 uv : TEXCOORD0;
};

struct FragmentInput
{
	float4 positionCS : SV_POSITION;
	float2 uv : TEXCOORD0;
};

float4x4 unity_ObjectToWorld, unity_MatrixVP;
float _Period, _Rotation, _Octaves, _OffsetX, _OffsetY, _OffsetZ, _Scale, _Depth;

FragmentInput Vertex(VertexInput input)
{
	FragmentInput output;
	output.positionCS = mul(unity_MatrixVP, float4(mul(unity_ObjectToWorld, float4(input.positionOS, 1.0)).xyz, 1.0));
	output.uv = input.uv;
	return output;
}

float4 Fragment(FragmentInput input) : SV_Target
{
	float rotation = _Rotation * radians(360.0);
	float result = 0.0;
	
	float3 p = (float3(input.uv, _Depth) + float3(_OffsetX, _OffsetY, _OffsetZ)) * _Scale;
	
	float3 dg;
	float2 gradient;
	for (float i = 0; i < _Octaves; i++)
	{
		float amp = exp2(-i);
		float freq = exp2(i);
		
		#if 1
			// Simplex noise
			result += (SimplexNoise(p * freq, _Period * freq, _Rotation * radians(360.0)) * 0.5 + 0.5) * amp;
		#else
			// Cellular
			result += CellularNoise(p.xy * freq, _Period * freq).x * amp;
		#endif
	}
	
	// Normalize
	result /= -2.0 * pow(0.5, _Octaves) + 2.0;
	
	return result;
}
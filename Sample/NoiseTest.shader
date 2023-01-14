Shader "Hidden/NoiseTest"
{
    Properties
    {
        _OffsetX("Offset X", Float) = 0
        _OffsetY("Offset Y", Float) = 0
        _OffsetZ("Offset Z", Float) = 0
        _Scale("Scale", Float) = 1
        _Period("Period", Integer) = 1
        _Rotation("Rotation", Range(0, 1)) = 0
        _Depth("Depth", Float) = 0
        [IntRange] _Octaves("Octaves", Range(1, 9)) = 5
    }

    SubShader
    {
        Pass
        {
            HLSLPROGRAM
            #pragma vertex Vertex
            #pragma fragment Fragment

            #include "NoiseTest.hlsl"
            ENDHLSL
        }
    }
}

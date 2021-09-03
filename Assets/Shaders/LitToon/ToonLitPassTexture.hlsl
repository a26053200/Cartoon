#pragma once

TEXTURE2D(_BaseMap); SAMPLER(sampler_BaseMap);

CBUFFER_START(UnityPerMaterial)
float4 _BaseMap_ST;
CBUFFER_END

struct Attributes
{
    float4 positionOS : POSITION;
};

struct Varyings
{
    float4 positionCS : SV_POSITION;
    float2 uv: TEXCOORD0;
};

Varyings Vertex(Attributes input)
{
    Varyings output = (Varyings) 0;
    VertexPositionInputs vertexInput = GetVertexPositionInputs(v.positionOS.xyz);
    output.positionCS = vertexInput.positionCS;
    output.uv = TRANSFORM_TEX(v.uv, _BaseMap);
    return output;
}

half4 Fragment(Varyings input) : SV_Target
{
    half4 baseMap = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, i.uv);
    return baseMap;
}
#endif
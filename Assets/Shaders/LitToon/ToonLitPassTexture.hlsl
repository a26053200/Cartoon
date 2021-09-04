TEXTURE2D(_BaseMap); SAMPLER(sampler_BaseMap);

CBUFFER_START(UnityPerMaterial)
float4 _BaseMap_ST;
CBUFFER_END

struct Attributes
{
    float4 positionOS : POSITION;
    float2 texcoord: TEXCOORD0;
};

struct Varyings
{
    float4 positionCS : SV_POSITION;
    float2 uv: TEXCOORD0;
};

Varyings vert(Attributes input)
{
    Varyings output = (Varyings) 0;
    VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);
    output.positionCS = vertexInput.positionCS;
    output.uv = TRANSFORM_TEX(input.texcoord, _BaseMap);
    return output;
}

half4 frag(Varyings input) : SV_Target
{
    half4 baseMap = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, input.uv);
    return baseMap;
}

struct Attributes
{
    float4 positionOS: POSITION;
    float2 uv: TEXCOORD0;
    float4 normal: NORMAL;
    float3 color: COLOR;
};

struct Varyings
{
    float4 positionCS: SV_POSITION;
    float2 uv: TEXCOORD0;
    float3 positionWS: TEXCOORD1;
    float3 normal: TEXCOORD2;
    float3 color: TEXCOORD6;
};

TEXTURE2D(_BaseMap); SAMPLER(sampler_BaseMap);
TEXTURE2D(_LightMap); SAMPLER(sampler_LightMap);
TEXTURE2D(_RampMap); SAMPLER(sampler_RampMap);
    
CBUFFER_START(UnityPerMaterial)
float4 _BaseMap_ST, _LightMap_ST, _RampMap_ST;
float4 _BaseColor;
CBUFFER_END

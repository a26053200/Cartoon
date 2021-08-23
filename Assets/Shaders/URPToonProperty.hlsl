struct a2v
{
    float4 positionOS: POSITION;
    float2 uv: TEXCOORD0;
    float4 normal: NORMAL;
    float3 color: COLOR;
};

struct v2f
{
    float4 positionCS: SV_POSITION;
    float2 uv: TEXCOORD0;
    float3 positionWS: TEXCOORD1;
    float3 normal: TEXCOORD2;
    #if _IsFace
        float4 positionSS: TEXCOORD3;
        float posNDCw: TEXCOORD4;
        float4 positionOS: TEXCOORD5;
    #endif
    
    float3 color: TEXCOORD6;
};

TEXTURE2D(_BaseMap);
SAMPLER(sampler_BaseMap);
TEXTURE2D(_HairSoildColor);
SAMPLER(sampler_HairSoildColor);
    
CBUFFER_START(UnityPerMaterial)
float4 _BaseMap_ST;
float4 _BaseColor, _BrightColor, _DarkColor, _MiddleColor, _RimColor;
float _CelShadeMidPoint, _CelShadeSmoothness;
float _RimSmoothness, _RimStrength, _HairShadowDistace, _HeightCorrectMax, _HeightCorrectMin;
CBUFFER_END

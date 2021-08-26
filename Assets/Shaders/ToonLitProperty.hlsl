

struct Attributes
{
    float4 positionOS: POSITION;
    float2 uv: TEXCOORD0;
    float3 normal: NORMAL;
    float4 color: COLOR;
};

struct Varyings
{
    float4 positionCS: SV_POSITION;
    float4 color: COLOR;
    float3 normal: NORMAL;
    float2 uv: TEXCOORD0;
    float3 positionWS: TEXCOORD1;
    float3 viewDirWS: TEXCOORD2;
};

TEXTURE2D(_BaseMap); SAMPLER(sampler_BaseMap);
TEXTURE2D(_LightMap); SAMPLER(sampler_LightMap);
TEXTURE2D(_RampMap); SAMPLER(sampler_RampMap);
    
CBUFFER_START(UnityPerMaterial)
//Base
float4 _BaseMap_ST, _LightMap_ST, _RampMap_ST;
//Shadow
float _ShadowArea, _ShadowSmooth, _DarkShadowArea, _DarkShadowSmooth, _FixDarkShadow;
float4 _BaseColor, _ShadowMultiColor, _DarkShadowMultiColor;
//Specular
float _Glossiness, _SpecularRange;
float4 _SpecularColor;
CBUFFER_END

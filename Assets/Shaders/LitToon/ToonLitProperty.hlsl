// Structs
/*
struct VertexPositionInputs
{
    float3 positionWS; // World space position
    float3 positionVS; // View space position
    float4 positionCS; // Homogeneous clip space position
    float4 positionNDC;// Homogeneous normalized device coordinates
};*/
#ifndef TOON_LIT_PROPERTY
#define TOON_LIT_PROPERTY

struct Attributes
{
    float4 positionOS: POSITION;
    float2 uv: TEXCOORD0;
    float3 normal: NORMAL;
    float4 color: COLOR;
#ifdef _USESMOOTHNORMAL
    float4 tangentOS : TANGENT;
    float2 texcoord7 : TEXCOORD7;
#endif
};

struct Varyings
{
    float4 positionCS: SV_POSITION;
    float4 color: COLOR;
    float3 normal: NORMAL;
    float3 uv: TEXCOORD0; // z is fogCoord
    float3 positionWS: TEXCOORD1;
    float3 positionVS: TEXCOORD2;
    float4 positionNDC: TEXCOORD3;
    float3 samplePositionVS: TEXCOORD4;
    float3 normalVS: TEXCOORD5;
    float3 viewDirWS: TEXCOORD6;
};
    
CBUFFER_START(UnityPerMaterial)
    //Base
    float4 _LightMapMask, _BaseMap_ST, _LightMap_ST, _RampMap_ST;
    //Shadow
    float _ShadowArea, _ShadowSmooth, _DarkShadowArea, _DarkShadowSmooth, _FixDarkShadow;
    float4 _BaseColor, _ShadowMultiColor, _DarkShadowMultiColor;
    //Specular
    float _Glossiness, _SpecularRange;
    float4 _SpecularColor;
    //Rim
    float _RimOffsetMul, _RimThreshold,_FresnelMask,_RimStrength;
    float4 _RimColor;

#ifdef _FACE
    float _FaceShadowOffset, _FaceShadowMapPow;
    float4 _FaceFront,_FaceUp,_FaceLeft,_FaceRight,_FaceShadowColor;
#endif

CBUFFER_END

TEXTURE2D(_BaseMap); SAMPLER(sampler_BaseMap);
TEXTURE2D(_LightMap); SAMPLER(sampler_LightMap);
TEXTURE2D(_RampMap); SAMPLER(sampler_RampMap);
TEXTURE2D_X_FLOAT(_CameraDepthTexture); SAMPLER(sampler_CameraDepthTexture);
#ifdef _FACE
    TEXTURE2D(_FaceLightMap); SAMPLER(sampler_FaceLightMap);
#endif

#endif
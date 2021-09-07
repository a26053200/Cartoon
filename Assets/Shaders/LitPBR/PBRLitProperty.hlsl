/// <summary>
/// <para>Author: zhengnan </para>
/// <para>Create: 2021年09月07日 星期二 23:29 </para>
/// </summary>

/*
struct VertexPositionInputs
{
    float3 positionWS; // World space position
    float3 positionVS; // View space position
    float4 positionCS; // Homogeneous clip space position
    float4 positionNDC;// Homogeneous normalized device coordinates
};*/

#ifndef PBR_LIT_PROPERTY
#define PBR_LIT_PROPERTY


struct Attributes
{
    float4 positionOS   : POSITION;
    float3 normalOS     : NORMAL;
    float3 color        : COLOR;
    float4 tangentOS    : TANGENT;
    float2 texcoord     : TEXCOORD0;
    float2 lightmapUV   : TEXCOORD1;
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct Varyings
{
    float4 positionCS               : SV_POSITION;
    float3 color                    : COLOR;
    float3 normalWS                 : NORMAL;
    float3 uv                       : TEXCOORD0;    // z is fogCoord
    float2 lightmapUV               : TEXCOORD1;
    float3 positionWS               : TEXCOORD2;
    float4 tangentWS                : TEXCOORD3;    // xyz: tangent, w: sign
    float3 viewDirWS                : TEXCOORD4;
    float4 shadowCoord              : TEXCOORD5;
    float3 viewDirTS                : TEXCOORD6;
    
    UNITY_VERTEX_INPUT_INSTANCE_ID
    UNITY_VERTEX_OUTPUT_STEREO
};

//Textures
    TEXTURE2D(_BaseMap); SAMPLER(sampler_BaseMap);
#if defined(ENABLE_BUMPMAP)
    TEXTURE2D(_BumpMap); SAMPLER(sampler_BumpMap);
#endif
    TEXTURE2D(_Mask); SAMPLER(sampler_Mask);

CBUFFER_START(UnityPerMaterial)
    //ST
    float4 _BaseMap_ST, _BumpMap_ST, _Mask_ST;
    
    //color
    float4 _BaseColor, _SpecularColor;
    
    //float
    float _Cutoff, _BumpScale, _Threshold, _Smoothness, _Roughness, _SpecularSmoothness, _SpecularBlend;
CBUFFER_END
#endif
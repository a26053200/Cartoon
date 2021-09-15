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

#ifndef LIT_DISNEY_INPUTS
#define LIT_DISNEY_INPUTS

CBUFFER_START(UnityPerMaterial)
    //ST
    float4 _BaseMap_ST, _BumpMap_ST, _Mask_ST;
    
    //color
    float4 _BaseColor, _SpecularColor, _EmissionColor, _ClearcoatColor, _SheenColor, _ReflectColor;
    
    float _Cutoff, _SSSThreshold;
    
    //float
    float _BumpScale;
    float _Roughness;
    float _Metallic;
    float _Specular;
    float _SpecularTint;
    float _Sheen;
    float _SheenTint;
    float _ClearcoatGloss;
    float _Clearcoat;
    float _Occlusion;
    float _Subsurface;
    float _Anisotropic;
    
    float  _Translucency;
    float  _TransNormalDistortion;
    float  _TransScattering;
    float  _TransDirect;
    float  _TransAmbient;
    float  _TransShadow;
CBUFFER_END


//Textures
    TEXTURE2D(_BaseMap); SAMPLER(sampler_BaseMap);
    TEXTURE2D(_BumpMap); SAMPLER(sampler_BumpMap);
    TEXTURE2D(_MaskMap); SAMPLER(sampler_MaskMap);
    TEXTURE2D(_MaskMap2); SAMPLER(sampler_MaskMap2);
    
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
    float4 normalWS                 : NORMAL;
    float2 uv                       : TEXCOORD0;
    DECLARE_LIGHTMAP_OR_SH(lightmapUV, vertexSH, 1);    // lightmapUV & vertexSH
    float3 positionWS               : TEXCOORD2;
    float4 tangentWS                : TEXCOORD3;    
    float4 bitangentWS              : TEXCOORD4;    
    float4 shadowCoord              : TEXCOORD5;
    float4 fogFactorAndVertexLight  : TEXCOORD6;
    
    UNITY_VERTEX_INPUT_INSTANCE_ID
    UNITY_VERTEX_OUTPUT_STEREO
};
    
struct DisneySurfaceData
{
    float3  albedo;
    float  emission;
    float3  normalTS;
    float   metallic;
    float   roughness;
    float   subsurface;
    float   occlusion;
    float   specular;
    float3  specularTint;
    float   anisotropic;
    float   sheen;
    float3  sheenTint;
    float   clearcoat;
    float   clearcoatGloss;
    float3  reflectColor;
};

struct DisneyInputData
{
    float3  positionWS;
    float3  normalWS;
    float3  tangentWS;
    float3  bitangentWS;
    float3  binormalWS;
    float3  viewDirectionWS;
    float4  shadowCoord;
    float   fogCoord;
    float3  vertexLighting;
    float3  bakedGI;
};

void InitializeDisneySurfaceData(float2 uv, out DisneySurfaceData outSurfaceData)
{
    //float4 baseColorMap = SRGBToLinear(SAMPLE_TEXTURE2D(_BaseMap,sampler_BaseMap,uv));
    float4 baseColorMap = SAMPLE_TEXTURE2D(_BaseMap,sampler_BaseMap,uv);
    outSurfaceData.albedo = baseColorMap.rgb;
    outSurfaceData.emission = baseColorMap.a;

    outSurfaceData.normalTS = UnpackNormal(SAMPLE_TEXTURE2D(_BumpMap, sampler_BumpMap, uv));
    
    float4 maskMap = SAMPLE_TEXTURE2D(_MaskMap,sampler_MaskMap,uv);
    //float4 maskMap2 = SAMPLE_TEXTURE2D(_MaskMap2,sampler_MaskMap2,uv);

    outSurfaceData.anisotropic = lerp(0, _Anisotropic, baseColorMap.a);
    outSurfaceData.subsurface = lerp(lerp(_Subsurface, 0, baseColorMap.a), 0, maskMap.g);
    
    outSurfaceData.metallic = lerp(0, lerp(_Metallic, 0, baseColorMap.a), maskMap.g);
    outSurfaceData.roughness = lerp(_Roughness * maskMap.r, 1, outSurfaceData.subsurface);
    outSurfaceData.occlusion = lerp(1, maskMap.b, _Occlusion);
    
    float smoothness = 1 - outSurfaceData.roughness * outSurfaceData.roughness;

    outSurfaceData.specular = _Specular * smoothness;
    outSurfaceData.specularTint = _SpecularTint * _SpecularColor;
    outSurfaceData.sheen = _Sheen;
    outSurfaceData.sheenTint = _SheenTint * _SheenColor;
    outSurfaceData.clearcoat = _Clearcoat;
    outSurfaceData.clearcoatGloss = _ClearcoatGloss * smoothness;
    
    outSurfaceData.reflectColor = _ReflectColor.rgb;
}


inline void InitializeDisneyInputData(Varyings input, float3 normalTS, out DisneyInputData outInputData)
{
    outInputData = (DisneyInputData)0;

    outInputData.positionWS = input.positionWS;

    outInputData.normalWS = TransformTangentToWorld(normalTS, float3x3(input.tangentWS.xyz, input.bitangentWS.xyz, input.normalWS.xyz));

    outInputData.tangentWS = input.tangentWS.xyz;
    outInputData.bitangentWS = input.bitangentWS.xyz;

    outInputData.normalWS = NormalizeNormalPerPixel(outInputData.normalWS);
    outInputData.binormalWS = cross(outInputData.normalWS,outInputData.tangentWS);
    outInputData.viewDirectionWS = float3(input.normalWS.w, input.tangentWS.w, input.bitangentWS.w);

    outInputData.shadowCoord = input.shadowCoord;

    outInputData.fogCoord = input.fogFactorAndVertexLight.x;
    outInputData.vertexLighting = input.fogFactorAndVertexLight.yzw;
    outInputData.bakedGI = SAMPLE_GI(input.lightmapUV, input.vertexSH, outInputData.normalWS);
}

inline void InitializeBRDFData(float3 albedo, float metallic, float roughness,out BRDFData outBRDFData)
{
    outBRDFData = (BRDFData)0;
    
    //IBL
    float oneMinusReflectivity = OneMinusReflectivityMetallic(metallic);
    float reflectivity = 1.0 - oneMinusReflectivity;

    outBRDFData.diffuse = albedo * oneMinusReflectivity;
    outBRDFData.specular = lerp(kDieletricSpec.rgb, albedo, metallic);

    outBRDFData.grazingTerm = saturate(1 - roughness + reflectivity);
    outBRDFData.perceptualRoughness = roughness;
    outBRDFData.roughness = roughness;
    outBRDFData.roughness2 = outBRDFData.roughness * outBRDFData.roughness;
}

#endif
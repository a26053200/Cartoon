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

#ifndef FAST_LIT_INPUTS
#define FAST_LIT_INPUTS

//Textures
    TEXTURE2D(_BaseMap);    SAMPLER(sampler_BaseMap);
    TEXTURE2D(_BumpMap);    SAMPLER(sampler_BumpMap);
    TEXTURE2D(_MaskMap);    SAMPLER(sampler_MaskMap);
    TEXTURE2D(_ShiftTex);   SAMPLER(sampler_ShiftTex);
    TEXTURE2D(_SSSLUT);     SAMPLER(sampler_SSSLUT);
    TEXTURE2D_X_FLOAT(_CameraDepthTexture); SAMPLER(sampler_CameraDepthTexture);
    
CBUFFER_START(UnityPerMaterial)

    //Base
    float4 _BaseMap_ST, _BumpMap_ST, _Mask_ST;
    float4 _BaseColor, _SpecularColor, _EmissionColor;
    float _BumpScale;
    float _Smoothness;
    float _Occlusion;
    //float _Roughness;
    float _Metallic;
    
    float _Cutoff;
    
    float _Alpha;
    
    float _Fade;
    
    // Advanced
    float _Diffuse;
    float _Specular;
    float _Sheen;
    float _SSAO;
    
    // Rim
    float   _RimStrength;
    float   _RimFresnelMask;
    float3  _RimColor;
    
    // Anisotropic
    float _Anisotropic;
    float4 _ShiftTex_ST;
    float _Gloss;
    float _Shift;
    
    // SSS
    float _Subsurface;
    float4 _SSSLUT_ST;// _SSSColor;
    float _CurveFactor;
    float _SubsurfaceRange;// _SSSPower, _SSSOffset, _SSSScale;
    
CBUFFER_END

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
    float4 positionSS               : TEXCOORD7; // Screen Space Position
    float3 positionVS              : TEXCOORD8; // Screen Space Position
    
    UNITY_VERTEX_INPUT_INSTANCE_ID
    UNITY_VERTEX_OUTPUT_STEREO
};
 

struct DisneyInputData
{
    float3 positionWS;
    float4 positionSS;
    float3 positionVS;
    float3 normalWS;
    float3 tangentWS;
    float3 bitangentWS;
    float3 binormalWS;
    float3 viewDirectionWS;
    float4 shadowCoord;
    float  fogCoord;
    float3 vertexLighting;
    float3 bakedGI;
    float2 normalizedScreenSpaceUV;
    float4 shadowMask;
};
   
struct DisneySurfaceData
{
    float3  albedo;
    float   alpha;
    float   fade;
    float   emission;
    float3  normalTS;
    float3  specularColor;
    
    float   metallic;
    float   smoothness;
    float   occlusion;
    
#ifdef _UseSSS    
    float   subsurface;
    float   curveFactor;
    float   subsurfaceRange;
#endif
    
#ifdef _EnableAdvanced
    float   specular;
    float   diffuse;
    float   sheen;
#endif

#ifdef _UseAnisotropic    
    float   anisotropic;
    float   anisotropicShift;
    float   anisotropicGloss;
#endif

#ifdef _UseRimLight
    float   rimStrength;
    float   rimFresnelMask;
    float3  rimColor;
#endif

};

void InitializeDisneySurfaceData(float2 uv, out DisneySurfaceData outSurfaceData)
{
    //float4 baseColorMap = SRGBToLinear(SAMPLE_TEXTURE2D(_BaseMap,sampler_BaseMap,uv));
    float4 baseColorMap = SAMPLE_TEXTURE2D(_BaseMap,sampler_BaseMap,uv);
    outSurfaceData.albedo = baseColorMap.rgb;
    outSurfaceData.emission = 0;//baseColorMap.a;
    outSurfaceData.alpha = _Alpha;
    outSurfaceData.fade = _Fade;
    
    outSurfaceData.normalTS = UnpackNormal(SAMPLE_TEXTURE2D(_BumpMap, sampler_BumpMap, uv));
    
    float4 maskMap = SAMPLE_TEXTURE2D(_MaskMap,sampler_MaskMap,uv);
    float4 noiseTex = SAMPLE_TEXTURE2D(_ShiftTex,sampler_ShiftTex,uv);
    //float4 maskMap2 = SAMPLE_TEXTURE2D(_MaskMap2,sampler_MaskMap2,uv);

    // HLW2 标准
    half r = maskMap.r;
    half g = maskMap.g;
    half b = maskMap.b;
    half a = baseColorMap.a;
    
    half s = 1 - r;
    outSurfaceData.smoothness   = lerp(s * _Smoothness, _Smoothness, step(s, 1));
    outSurfaceData.metallic     = lerp(0, g, _Metallic);
    outSurfaceData.occlusion    = lerp(1, b, _Occlusion);
    
    outSurfaceData.specularColor = _SpecularColor;//lerp(0, _SpecularColor, g);
    
#ifdef _UseSSS 
    outSurfaceData.subsurface = _Subsurface * (1 - g);
    outSurfaceData.curveFactor = _CurveFactor;
    outSurfaceData.subsurfaceRange = _SubsurfaceRange;
#endif    
 
#ifdef _EnableAdvanced    
    outSurfaceData.specular = _Specular;
    outSurfaceData.diffuse = _Diffuse;
    outSurfaceData.sheen = _Sheen;
#endif

#ifdef _UseAnisotropic 
    outSurfaceData.anisotropic          = lerp(0, _Anisotropic, a);
    outSurfaceData.anisotropicShift     = noiseTex.r - _Shift;
    outSurfaceData.anisotropicGloss     = _Gloss;
#endif

#ifdef _UseRimLight   
    outSurfaceData.rimColor = _RimColor;
    outSurfaceData.rimStrength = _RimStrength;
    outSurfaceData.rimFresnelMask = _RimFresnelMask;
#endif
}


inline void InitializeDisneyInputData(Varyings input, float3 normalTS, out DisneyInputData outInputData)
{
    outInputData = (DisneyInputData)0;

    outInputData.positionWS = input.positionWS;
    outInputData.positionSS = input.positionSS;
    outInputData.positionVS = input.positionVS;
    
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
    outInputData.normalizedScreenSpaceUV = GetNormalizedScreenSpaceUV(input.positionCS);
    outInputData.shadowMask = SAMPLE_SHADOWMASK(input.lightmapUV);
}

inline void InitializeBRDFData(float3 albedo, float metallic, float3 specularColor, float smoothness,out BRDFData brdfData)
{
    brdfData = (BRDFData)0;
    
#ifdef _UseSpecularMode
    half reflectivity = ReflectivitySpecular(specularColor);
    half oneMinusReflectivity = 1.0 - reflectivity;
    brdfData.diffuse = albedo * (half3(1.0h, 1.0h, 1.0h) - specularColor);
    brdfData.specular = specularColor;
#else
    float oneMinusReflectivity = OneMinusReflectivityMetallic(metallic);
    float reflectivity = 1.0 - oneMinusReflectivity;
    brdfData.diffuse             = albedo * oneMinusReflectivity;
    brdfData.specular            = lerp(kDieletricSpec.rgb, albedo, metallic);
#endif
    
    brdfData.grazingTerm         = saturate(smoothness + reflectivity);
    brdfData.perceptualRoughness = PerceptualSmoothnessToPerceptualRoughness(smoothness);
    brdfData.roughness           = PerceptualRoughnessToRoughness(brdfData.perceptualRoughness);
    brdfData.roughness2          = max(brdfData.roughness * brdfData.roughness, HALF_MIN);
    brdfData.normalizationTerm   = brdfData.roughness * 4.0h + 2.0h;
    brdfData.roughness2MinusOne  = brdfData.roughness2 - 1.0h;

}

#endif
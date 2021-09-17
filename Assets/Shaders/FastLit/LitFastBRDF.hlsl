#ifndef FAST_LIT_BRDF_INCLUDED
#define FAST_LIT_BRDF_INCLUDED

#include "LitFastInputs.hlsl"
#include "Unreal4BRDF.hlsl"

#define UNITY_PI 3.14159265358979323846
#define UNITY_INV_PI 0.31830988618f
// Linear values
#define unity_ColorSpaceGrey fixed4(0.214041144, 0.214041144, 0.214041144, 0.5)
#define unity_ColorSpaceDouble fixed4(4.59479380, 4.59479380, 4.59479380, 2.0)
#define unity_ColorSpaceDielectricSpec half4(0.04, 0.04, 0.04, 1.0 - 0.04) // standard dielectric reflectivity coef at incident angle (= 4%)
#define unity_ColorSpaceLuminance half4(0.0396819152, 0.458021790, 0.00609653955, 1.0) // Legacy: alpha is set to 1.0 to specify linear mode

inline float3 fresnelSchlickRoughness(float cosTheta, float3 F0, float roughness)
{
    return F0 + (max(float3(1.0 - roughness, 1.0 - roughness, 1.0 - roughness), F0) - F0) * pow(1.0 - cosTheta, 5.0);
}


float D_GGX_zn(float roughness, float NdotH)
{
	float a = roughness * roughness;
	float NdotH2 = NdotH * NdotH;
	float a2 = a * a;
	float d = NdotH2 * (a2 - 1) + 1;//分母
	return a2 / ( PI * d * d );					// 4 mul, 1 rcp
}
//各向异性D项目
float D_GGXAniso_zn(float TdotH, float BdotH, float mt, float mb, float nh) 
{
	float d = TdotH * TdotH / (mt * mt) + BdotH * BdotH / (mb * mb) + nh * nh;
	return (1.0 / ( UNITY_PI * mt*mb * d*d));
}

//G项子项
 float G_Section(float dot,float k)
 {
     float nom = dot;
     float denom = lerp(dot,1,k);
     return nom/denom;
 }
         
float G_SchlickGGX(float NdotL, float NdotV, float roughness)
 {
     float k = pow(1 + roughness, 2)/8;
     float Gnl = G_Section(NdotL, k);
     float Gnv = G_Section(NdotV, k);
     return Gnl * Gnv;
 }
 
 //F项 直接光
float3 F_Function(float HdotL,float3 F0)
{
    float fresnel = exp2((-5.55473 * HdotL - 6.98316) * HdotL);
    return lerp(fresnel, 1, F0);
}

float3 FastBRDF(BRDFData brdfData, DisneySurfaceData surfaceData, float3 L, float3 V, float3 N, float3 X, float3 Y, float3 lightColor)
{    
    float NdotL = max(saturate(dot(N, L)), 0.000001);
    float NdotV = max(saturate(dot(N, V)), 0.000001);
 
    float3 H = SafeNormalize(L + V);
    float NdotH = max(saturate(dot(N, H)), 0.000001);
    float LdotH = max(saturate(dot(L, H)), 0.000001);
    float VdotH = max(saturate(dot(V, H)), 0.000001);
    float TdotH = max(saturate(dot(X, H)), 0.000001);
    float BdotH = max(saturate(dot(Y, H)), 0.000001);
    
    float3 albedo = surfaceData.albedo * _BaseColor;
    
    float perceptualRoughness = surfaceData.roughness;
    float metallic = surfaceData.metallic;
    float3 F0 = lerp(kDielectricSpec.rgb, albedo, metallic);
    
    float D = D_GGX_zn(brdfData.roughness, NdotH);
    //float D = D_GGXAniso_zn(TdotH, BdotH, 1 - surfaceData.smoothness, 1, NdotH);
    float F = F_Function(LdotH, F0);
    float G = G_SchlickGGX(NdotL, NdotV, brdfData.roughness);
    
    //Cook-Torrance模型 BRDF
    float3 SpecularResult = (D * G * F * 0.25) / (NdotV * NdotL);

    //漫反射系数
    //float3 kd = (1 - F) * (1 - metallic);
    
    //直接光照部分结果
    float3 specColor = SpecularResult * lightColor * NdotL * PI * surfaceData.specular;
    float3 diffColor = brdfData.diffuse * lightColor * NdotL * surfaceData.diffuse;
    float3 DirectLightResult = diffColor + specColor;
 
 #ifdef _UseAnisotropic    
    // Anisotropic
    float shift = surfaceData.anisotropicShift;
    float3 aB = normalize(Y + shift * N); //worldBinormal
    float aBdotH = dot(aB, H);
    float sinTH = sqrt(1.0 - aBdotH * aBdotH);
    float dirAtten = smoothstep(-1, 0, aBdotH);
    float anisotropic = dirAtten * pow(sinTH, surfaceData.anisotropicGloss);
    
    float3 AnisotropicResult = anisotropic * surfaceData.anisotropicStrength * lightColor * saturate(NdotL * 2);
    DirectLightResult += lerp(0, AnisotropicResult, surfaceData.anisotropic);
    //return lerp(0, AnisotropicResult, surfaceData.anisotropic);
  #endif
    
    return DirectLightResult;
}

float3 FastPBR(BRDFData brdfData, DisneySurfaceData surfaceData, Light light, DisneyInputData disneyInputData)
{
    //return float4(light.color,1);
    return FastBRDF(
            brdfData, 
            surfaceData, light.direction, 
            disneyInputData.viewDirectionWS, 
            disneyInputData.normalWS,
            disneyInputData.tangentWS, 
            disneyInputData.bitangentWS, 
            light.color);
}


float3 FastSubsurfaceScattering(float3 L, float3 N, float3 V, float3 lightCol, float subsurface, float shadowAttenuation)
{
    float3 H = SafeNormalize(L + N * _SSSOffset);
	float sss = pow(saturate(dot(V, -H)), _SSSPower);
    return sss * lightCol * subsurface * _SSSColor;
}

float4 DisneyBRDFFragment(DisneyInputData disneyInputData, DisneySurfaceData disneySurfaceData)
{
    BRDFData brdfData;
    InitializeBRDFData(disneySurfaceData.albedo, disneySurfaceData.metallic, disneySurfaceData.roughness, brdfData);
    
    Light mainLight = GetMainLight(disneyInputData.shadowCoord);
    MixRealtimeAndBakedGI(mainLight, disneyInputData.normalWS, disneyInputData.bakedGI);
    
    float3 color = FastPBR(brdfData, disneySurfaceData, mainLight, disneyInputData);
    //return float4(color,1);
    
#ifdef _UseSSS
    float3 sssColor =  FastSubsurfaceScattering(
                mainLight.direction,
                disneyInputData.normalWS,
                disneyInputData.viewDirectionWS,
                disneySurfaceData.subsurface,
                mainLight.color,
                mainLight.shadowAttenuation
                );            
    color += sssColor;//lerp(sssColor, 0, step(disneySurfaceData.roughness, _SSSThreshold));
    //return float4(sssColor,1);
#endif  
    
    float3 iblColor = GlobalIllumination(brdfData, disneyInputData.bakedGI, disneySurfaceData.occlusion, disneyInputData.normalWS, disneyInputData.viewDirectionWS);
    //return float4(iblColor,1);
    color += iblColor;
#ifdef _ADDITIONAL_LIGHTS
    int pixelLightCount = GetAdditionalLightsCount();
    for (int i = 0; i < pixelLightCount; ++i)
    {
        Light addlight = GetAdditionalLight(i, disneyInputData.positionWS.xyz);
        //addlight.color *= ssao;
        color += FastPBR(brdfData, disneySurfaceData, mainLight, disneyInputData);
    }
#endif

#ifdef _ADDITIONAL_LIGHTS_VERTEX
    //color += disneyInputData.vertexLighting * brdfData.diffuse;
#endif

    //color += disneySurfaceData.emission * _EmissionColor;

    return float4(color,1);
}
#endif

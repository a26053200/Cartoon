#ifndef COOK_TORRANCE_BRDF_INCLUDED
#define COOK_TORRANCE_BRDF_INCLUDED

//////////////////////////////
//		 CookTorrance BRDF		//
//////////////////////////////

#include "LitFastInputs.hlsl"
//Diffuse functions
float3 DiffuseLambert(float3 diffuseColor)
{
	return diffuseColor * (1 / PI);
}

float chiGGX(float v)
{
	return v > 0 ? 1 : 0;
}

//Distribution functions
//GGX/Throwbridge-Reitz
float D_GGX2(float roughness, float NoH)
{
	float a = roughness * roughness;
	float a2 = a * a;
	float NoH2 = NoH * NoH;
	float denom = NoH2 * (a2 - 1.0f) + 1.0f;

	return a2 / (PI * denom * denom);
}

//Geometry term functions

float G_Smith_Schlick(float roughness, float NoV, float NoL)
{
	float a = roughness * roughness;
	float k = a * 0.5f;
	
#if K_MODEL_SCHLICK
	k = a * 0.5f;
#elif K_MODEL_CRYTEK
	k = (0.8f + 0.5f * a);
	k = k * k;
	k = 0.5f * k;
#elif K_MODEL_DISNEY
	k = a + 1;
	k = k * k;
	k = k * 0.125f;
#endif

	//k = a * 0.5f;
	float GV = NoV / (NoV * (1 - k) + k);
	float GL = NoL / (NoL * (1 - k) + k);

	return GV * GL;
}

float G_Smith_GGX(float roughness, float NoV, float NoL)
{
	float a = roughness * roughness;
	float GV = NoL * (NoV * (1 - a) + a);
	float GL = NoV * (NoL * (1 - a) + a);
	return 0.5 * rcp(GV + GL);
}

//Fresnel functions
float3 F_None(float3 SpecularColor)
{
	return SpecularColor;
}

float3 F_Schlick2(float3 SpecularColor, float VoH)
{
	float Fc = pow((1 - VoH), 5);

	return saturate(50.0f * SpecularColor.g) * Fc + (1 - Fc) * SpecularColor;
}

//Reflectance at normal incidence
//Reference: codinglabs.net
float3 RefAtNormalIncidence(float3 albedo, float metallic, float reflectivity)
{
	float ior = 1 + reflectivity;
	float3 F0 = abs((1.0 - ior) / (1.0 + ior));
	F0 = F0 * F0;
	F0 = lerp(F0, albedo, metallic);
	return F0;
}

//Epic uses this
float3 F_Schlick_Gau_Ver(float VoH, float3 F0)
{
	//normal way
	//return F0 + (1 - F0) * pow((1 - VoH), 5);

	//Spherical Gaussian Approximation
	//Reference: Seb. Lagarde's Blog (seblagarde.wordpress.com)
	return F0 + (1 - F0) * exp2((-5.55473 * VoH - 6.98316) * VoH);
}

float3 F_Schlick_With_F0(float VoH, float3 albedo, float metallic, float reflectivity)
{
	float3 F0 = RefAtNormalIncidence(albedo, metallic, reflectivity);
	return F_Schlick_Gau_Ver(VoH, F0);
}

float3 F_Schlick_Roughness(float3 SpecularColor, float roughness, float VoH)
{
	float a = roughness * roughness;
	return (SpecularColor + (max(1.0f - a, SpecularColor) - SpecularColor) * pow(1 - VoH, 5));
}

//Cook Torrance model
float CookTorranceSpecFactor(float3 N, float3 V, float metallic, float roughness, float3 L, float3 albedo)
{
	float3 H = SafeNormalize(L + V);
    
    float NdotL = saturate(dot(N, L));
    float NdotV = saturate(dot(N, V));
    float NdotH = saturate(dot(N, H));
    float LdotH = saturate(dot(L, H));
    float VdotH = saturate(dot(V, H));

	float3 realSpec = lerp(0.03f, albedo, metallic);

	//Fresnel
	float3 fresnel;
//#if SPECULAR_F_NONE
	//fresnel = F_None(realSpec);
//#elif SPECULAR_F_SCHLICK
	fresnel = F_Schlick2(realSpec, NdotV);
//#endif
	//G term
	float geometry;
//#if SPECULAR_G_SCHLICK
	geometry = G_Smith_Schlick(roughness, NdotV, NdotL);
//#elif SPECULAR_G_GGX
	//geometry = G_Smith_GGX(roughness, NdotV, NdotL);
//#endif

	float distribution;
//#if SPECULAR_D_GGX
	distribution = D_GGX2(roughness, NdotH);
//#endif

	float3 numerator = (fresnel * geometry * distribution);
	float denominator = 4.0f * (NdotV * NdotL) + 0.000001f; //prevent light aliasing on metals

	return numerator / denominator;
}

//Improved
//Diffuse:
//DiffuseLambert

//Specular:
//D = D_GGX
//G = G_Smith_Schlick
//F = F_Schlick_With_F0

float3 GGXSpecFactor(float3 N, float3 V, float metallic, float roughness, float3 L, float3 albedo)
{
	float3 H = SafeNormalize(L + V);
    
    float NdotL = saturate(dot(N, L));
    float NdotV = saturate(dot(N, V));
    float NdotH = saturate(dot(N, H));
    float LdotH = saturate(dot(L, H));
    float VdotH = saturate(dot(V, H));

    float oneMinusReflectivity = OneMinusReflectivityMetallic(metallic);
    float reflectivity = 1.0 - oneMinusReflectivity;
	float3 fresnel = F_Schlick_With_F0(VdotH, albedo, metallic, reflectivity);
	float geometry = G_Smith_Schlick(roughness, NdotV, NdotL);
	float distribution = D_GGX(roughness, NdotH);

	float3 numerator = (fresnel * geometry * distribution);
	float denominator = 4.0f * (NdotV * NdotL) + 0.000001f; //prevent light aliasing on metals

	return numerator / denominator;
}

float3 FastBRDF(BRDFData brdfData, DisneySurfaceData surfaceData, 
    float3 L, float3 V, float3 N, float3 X, float3 Y, 
    float3 lightColor, float shadowAttenuation)
{ 
    float3 H = SafeNormalize(L + V);
    
    float NdotL = saturate(dot(N, L));
    float NdotV = saturate(dot(N, V));
    float NdotH = saturate(dot(N, H));
    float LdotH = saturate(dot(L, H));
    float VdotH = saturate(dot(V, H));
    
    float3 SpecularResult = GGXSpecFactor(N, V, surfaceData.metallic, brdfData.roughness, L, surfaceData.albedo);
    //float3 SpecularResult = CookTorranceSpecFactor(N, V, surfaceData.metallic, brdfData.roughness, L, surfaceData.albedo);
    //漫反射系数
    //float3 DiffuseResult = (1 - surfaceData.metallic) * surfaceData.albedo / PI;
    float3 DiffuseResult = DiffuseLambert(brdfData.diffuse);
#if defined(_EnableAdvanced)
    float3 DirectLightResult = DiffuseResult;// * surfaceData.diffuse + SpecularResult * surfaceData.specular;
#else
    float3 DirectLightResult = DiffuseResult;// + SpecularResult;
#endif

#if defined(_ReceiveShadow)
     return DirectLightResult * lightColor * shadowAttenuation;// * NdotL;
 #else
     return DirectLightResult * lightColor;// * NdotL;
 #endif 
}

float3 FastPBR(BRDFData brdfData, DisneySurfaceData surfaceData, Light light, DisneyInputData inputData)
{
    //return float4(light.color,1);
    return FastBRDF(
            brdfData, 
            surfaceData, light.direction, 
            inputData.viewDirectionWS, 
            inputData.normalWS,
            inputData.tangentWS, 
            inputData.bitangentWS, 
            light.color,
            light.shadowAttenuation * light.distanceAttenuation
            );
}

float4 FastBRDFFragment(DisneyInputData inputData, DisneySurfaceData surfaceData)
{
    BRDFData brdfData;
    InitializeBRDFData(surfaceData.albedo, surfaceData.metallic, surfaceData.smoothness, brdfData);
    
    Light mainLight = GetMainLight(inputData.shadowCoord);
    MixRealtimeAndBakedGI(mainLight, inputData.normalWS, inputData.bakedGI);
    
    float3 color = FastPBR(brdfData, surfaceData, mainLight, inputData);
    //return float4(color,1);
    
#ifdef _UseSSS
    /*
    float3 sssColor =  FastSubsurfaceScattering(
                mainLight.direction,
                inputData.normalWS,
                inputData.viewDirectionWS,
                surfaceData.subsurface,
                mainLight.color,
                mainLight.shadowAttenuation * mainLight.distanceAttenuation 
                );            
    //color += sssColor;//lerp(sssColor, 0, step(surfaceData.roughness, _SSSThreshold));
    //return float4(sssColor,1);
    */
#endif  
    
    float3 iblColor = GlobalIllumination(brdfData, inputData.bakedGI, surfaceData.occlusion, inputData.normalWS, inputData.viewDirectionWS);
    //return float4(iblColor,1);
#if defined(_EnableAdvanced)
    color += lerp(0, iblColor, surfaceData.sheen);
#else
    color += iblColor;
#endif  

#ifdef _ADDITIONAL_LIGHTS
    int pixelLightCount = GetAdditionalLightsCount();
    for (int i = 0; i < pixelLightCount; ++i)
    {
        Light addlight = GetAdditionalLight(i, inputData.positionWS.xyz);
        //addlight.color *= ssao;
        color += FastPBR(brdfData, surfaceData, mainLight, inputData);
    }
#endif

#ifdef _ADDITIONAL_LIGHTS_VERTEX
    color += inputData.vertexLighting * brdfData.diffuse;
#endif
    color += surfaceData.emission * _EmissionColor;
#ifdef _UseCutoff
    clip(surfaceData.emission - _Cutoff);
#endif
    return float4(color,1);
}
#endif

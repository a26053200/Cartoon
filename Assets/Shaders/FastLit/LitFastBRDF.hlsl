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

inline half3 DecodeHDR (half4 data, half4 decodeInstructions)
{
    // Take into account texture alpha if decodeInstructions.w is true(the alpha value affects the RGB channels)
    half alpha = decodeInstructions.w * (data.a - 1.0) + 1.0;

    // If Linear mode is not supported we can skip exponent part
    #if defined(UNITY_COLORSPACE_GAMMA)
        return (decodeInstructions.x * alpha) * data.rgb;
    #else
    #   if defined(UNITY_USE_NATIVE_HDR)
            return decodeInstructions.x * data.rgb; // Multiplier for future HDRI relative to absolute conversion.
    #   else
            return (decodeInstructions.x * pow(alpha, decodeInstructions.y)) * data.rgb;
    #   endif
    #endif
}

float3 FastSubsurfaceScattering(float3 L, float3 N, float3 V, float3 lightCol, float subsurface, float shadowAttenuation)
{
    float3 H = normalize(L + N * _SSSOffset);
	float sss = pow(saturate(dot(V, -H)), _SSSPower);
    return sss * lightCol * subsurface;
}

float3 FastBRDF(BRDFData brdfData, DisneySurfaceData surfaceData, float3 L, float3 V, float3 N, float3 X, float3 Y, float3 lightColor)
{    
    float NdotL = max(dot(N,L), 0.000001);
    float NdotV = max(dot(N,V), 0.000001);
 
    float3 H = SafeNormalize(L + V);
    float NdotH = max(dot(N,H),0.000001);
    float LdotH = max(dot(L,H),0.000001);
    float VdotH = max(dot(V,H),0.000001);
    
    float3 albedo = surfaceData.albedo * _BaseColor;
    
    float perceptualRoughness = surfaceData.roughness;
    float metallic = surfaceData.metallic;
    float3 F0 = lerp(unity_ColorSpaceDielectricSpec.rgb, albedo, metallic);
    
    float lerpSquareRoughness = pow(lerp(0.002, 1, brdfData.roughness), 2);//Unity把roughness lerp到了0.002
    float D = lerpSquareRoughness / (pow((pow(NdotH, 2) * (lerpSquareRoughness - 1) + 1), 2) * UNITY_PI);
    
    float3 F = F0 + (1 - F0) * exp2((-5.55473 * VdotH - 6.98316) * VdotH);
    
    float kInDirectLight = pow(brdfData.roughness2 + 1, 2) / 8;
    float kInIBL = pow(brdfData.roughness2, 2) / 8;
    float GLeft = NdotL / lerp(NdotL, 1, kInDirectLight);
    float GRight = NdotV / lerp(NdotV, 1, kInDirectLight);
    float G = GLeft * GRight;

    //Cook-Torrance模型BRDF
    float3 SpecularResult = (D * G * F * 0.25) / (NdotV * NdotL);
    
    //漫反射系数
    float3 kd = (1 - F) * (1 - metallic);
    
    float d = NdotH * NdotH * (brdfData.roughness2MinusOne - 1.0h) + 1.00001f;
    float LoH2 = LdotH * LdotH;
    float specularTerm = brdfData.roughness2MinusOne / ((d * d) * max(0.1h, LoH2) * brdfData.normalizationTerm);
    float3 SpecularResult1 = surfaceData.specularColor * specularTerm;
    
    //直接光照部分结果
    float3 specColor = SpecularResult1 * lightColor * NdotL * UNITY_PI;
    float3 diffColor = kd * albedo * lightColor * NdotL;
    float3 DirectLightResult = diffColor + specColor;
     
    // Anisotropic
    float shift = surfaceData.anisotropicShift;
    float3 B = normalize(Y + shift * N); //worldBinormal
    float TdotH = dot(B, H);
    float sinTH = sqrt(1.0 - TdotH * TdotH);
    float dirAtten = smoothstep(-1, 0, TdotH);
    float anisotropic = dirAtten * pow(sinTH, surfaceData.anisotropicGloss);
    
    float3 AnisotropicResult = anisotropic * surfaceData.specularColor * lightColor * surfaceData.albedo * saturate(NdotL * 2);
    //return lerp(0, anisotropicResult, surfaceData.anisotropic);
    return DirectLightResult + lerp(0, AnisotropicResult, surfaceData.anisotropic);
}

float3 FastPBR(BRDFData brdfData, DisneySurfaceData surfaceData, Light light, DisneyInputData disneyInputData)
{
    //return float4(light.color,1);
    return light.color * light.distanceAttenuation * 1 * FastBRDF(
            brdfData, 
            surfaceData, light.direction, 
            disneyInputData.viewDirectionWS, 
            disneyInputData.normalWS,
            disneyInputData.tangentWS, 
            disneyInputData.bitangentWS, 
            light.color);
}

float4 DisneyBRDFFragment(DisneyInputData disneyInputData, DisneySurfaceData disneySurfaceData)
{
    BRDFData brdfData;
    InitializeBRDFData(disneySurfaceData.albedo, disneySurfaceData.metallic, disneySurfaceData.roughness, brdfData);
    
    Light mainLight = GetMainLight(disneyInputData.shadowCoord);
    MixRealtimeAndBakedGI(mainLight, disneyInputData.normalWS, disneyInputData.bakedGI);
    /*
    AmbientOcclusionFactor aoFactor = GetScreenSpaceAmbientOcclusion(disneyInputData.normalizedScreenSpaceUV);
    float ssao = lerp(1, aoFactor.directAmbientOcclusion, _SSAO);
    mainLight.color *= ssao;
    disneyInputData.bakedGI *= lerp(1, aoFactor.indirectAmbientOcclusion, _SSAO);
    */
    float3 color = FastPBR(brdfData, disneySurfaceData, mainLight, disneyInputData);
    //return float4(color,1);
    /*
    float3 sssColor = SkinTranslucency(mainLight.direction,disneyInputData.normalWS,
                    disneyInputData.viewDirectionWS,disneySurfaceData.albedo,
                    disneySurfaceData.subsurface,mainLight.color,mainLight.shadowAttenuation);
                    */
    /*
    float3 sssColor =  FastSubsurfaceScattering(
                mainLight.direction,
                disneyInputData.normalWS,
                disneyInputData.viewDirectionWS,
                disneySurfaceData.subsurface,
                mainLight.color,
                mainLight.shadowAttenuation
                );            
    color += sssColor;//lerp(sssColor, 0, step(disneySurfaceData.roughness, _SSSThreshold));
    return float4(sssColor,1);
    */
    
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
    color += disneyInputData.vertexLighting * brdfData.diffuse;
#endif

    //color += disneySurfaceData.emission * _EmissionColor;

    return float4(color,1);
}
#endif

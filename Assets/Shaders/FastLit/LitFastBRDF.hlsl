#ifndef FAST_LIT_BRDF_INCLUDED
#define FAST_LIT_BRDF_INCLUDED

#include "LitFastInputs.hlsl"

#define UNITY_PI 3.14159265358979323846
#define UNITY_INV_PI 0.31830988618f

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

			
float3 FastBRDF(DisneySurfaceData surfaceData, float3 L, float3 V, float3 N, float3 X, float3 Y, float shadowAttenuation, float3 lightColor, half occlusion)
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

    float roughness = max(PerceptualRoughnessToRoughness(perceptualRoughness), HALF_MIN_SQRT);//perceptualRoughness * perceptualRoughness;
    float roughness2 = max(roughness * roughness, HALF_MIN);//roughness * roughness;
    
    float lerpSquareRoughness = pow(lerp(0.002, 1, roughness), 2);//Unity把roughness lerp到了0.002
    float D = lerpSquareRoughness / (pow((pow(NdotH, 2) * (lerpSquareRoughness - 1) + 1), 2) * UNITY_PI);
    
    float kInDirectLight = pow(roughness2 + 1, 2) / 8;
    float kInIBL = pow(roughness2, 2) / 8;
    float GLeft = NdotL / lerp(NdotL, 1, kInDirectLight);
    float GRight = NdotV / lerp(NdotV, 1, kInDirectLight);
    float G = GLeft * GRight;

    half4 unity_ColorSpaceDielectricSpec = half4(0.04, 0.04, 0.04, 1.0 - 0.04);
    float3 F0 = lerp(unity_ColorSpaceDielectricSpec.rgb, albedo, metallic);
    float3 F = F0 + (1 - F0) * exp2((-5.55473 * VdotH - 6.98316) * VdotH);

    float3 SpecularResult = (D * G * F * 0.25) / (NdotV * NdotL);

    //漫反射系数
    float3 kd = (1 - F) * (1 - metallic);

    //直接光照部分结果
    float3 specColor = SpecularResult * lightColor * NdotL * UNITY_PI;
    float3 diffColor = kd * albedo * lightColor * NdotL;
    float3 DirectLightResult = diffColor + specColor;
    
    //IBL ( Image Based Lighting)
    half3 ambient_contrib = SampleSH(N);
    float3 ambient = 0.03 * albedo;
    float3 iblDiffuse = max(half3(0, 0, 0), ambient.rgb + ambient_contrib);
   
    float mip_roughness = perceptualRoughness * (1.7 - 0.7 * perceptualRoughness);
    float3 reflectVector = reflect(-V, N);

    half mip = PerceptualRoughnessToMipmapLevel(perceptualRoughness);
    half4 encodedIrradiance = SAMPLE_TEXTURECUBE_LOD(unity_SpecCube0, samplerunity_SpecCube0, reflectVector, mip);//根据粗糙度生成lod级别对贴图进行三线性采样

    float3 iblSpecular = DecodeHDREnvironment(encodedIrradiance, unity_SpecCube0_HDR) * occlusion;

    float4 lut = SAMPLE_TEXTURE2D(_LUT, sampler_LUT, float2(lerp(0, 0.99, NdotV), lerp(0, 0.99, roughness)));
    float2 envBDRF = lut.rg;
    //float2 envBDRF = tex2D(_LUT, float2(lerp(0, 0.99, nv), lerp(0, 0.99, roughness))).rg; // LUT采样

    float3 Flast = fresnelSchlickRoughness(max(VdotH, 0.0), F0, roughness);
    float kdLast = (1 - Flast) * (1 - metallic);

    float3 iblDiffuseResult = iblDiffuse * kdLast * albedo;
    float3 iblSpecularResult = iblSpecular * (Flast * envBDRF.r + envBDRF.g);
    float3 IndirectResult = iblDiffuseResult + iblSpecularResult;

    float4 result = float4(DirectLightResult + IndirectResult, 1);

    return lut.r;
}

float3 FastPBR(DisneySurfaceData surfaceData, Light light, float3 normalWS, float3 viewDirectionWS,
                float3 tangentWS, float3 binormalWS, float3 lightColor, float occlusion)
{
    //return float4(light.color,1);
    return light.color * light.distanceAttenuation * 1 * FastBRDF(surfaceData, light.direction,viewDirectionWS,normalWS,tangentWS,binormalWS,light.shadowAttenuation, lightColor, surfaceData.occlusion);
}

float4 DisneyBRDFFragment(DisneyInputData disneyInputData, DisneySurfaceData disneySurfaceData)
{
    BRDFData brdfData;
    InitializeBRDFData(disneySurfaceData.albedo, disneySurfaceData.metallic, disneySurfaceData.roughness, brdfData);
    
    Light mainLight = GetMainLight(disneyInputData.shadowCoord);
    MixRealtimeAndBakedGI(mainLight, disneyInputData.normalWS, disneyInputData.bakedGI, float4(0, 0, 0, 0));

    float3 color = FastPBR(disneySurfaceData, mainLight,
                        disneyInputData.normalWS, disneyInputData.viewDirectionWS,
                        disneyInputData.tangentWS, disneyInputData.bitangentWS, mainLight.color, disneySurfaceData.occlusion);
    return float4(color,1);
    /*
    float3 sssColor = SkinTranslucency(mainLight.direction,disneyInputData.normalWS,
                    disneyInputData.viewDirectionWS,disneySurfaceData.albedo,
                    disneySurfaceData.subsurface,mainLight.color,mainLight.shadowAttenuation);
    color += sssColor;//lerp(sssColor, 0, step(disneySurfaceData.roughness, _SSSThreshold));
    */
    //return float4(color,1);
    color += GlobalIllumination(brdfData, disneyInputData.bakedGI, disneySurfaceData.occlusion, disneyInputData.normalWS, disneyInputData.viewDirectionWS);
#ifdef _ADDITIONAL_LIGHTS
    int pixelLightCount = GetAdditionalLightsCount();
    for (int i = 0; i < pixelLightCount; ++i)
    {
        Light addlight = GetAdditionalLight(i, disneyInputData.positionWS.xyz);
        color += DisneyPBR(disneySurfaceData, addlight,
                    disneyInputData.normalWS, disneyInputData.viewDirectionWS,
                    disneyInputData.tangentWS, disneyInputData.bitangentWS);
    }
#endif

#ifdef _ADDITIONAL_LIGHTS_VERTEX
    color += disneyInputData.vertexLighting * brdfData.diffuse;
#endif

    //color += disneySurfaceData.emission * _EmissionColor;

    return float4(color,1);
}
#endif

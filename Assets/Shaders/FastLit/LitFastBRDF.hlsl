#ifndef FAST_LIT_BRDF_INCLUDED
#define FAST_LIT_BRDF_INCLUDED

//////////////////////////////
//		 Fast BRDF		//
//////////////////////////////

#include "LitFastInputs.hlsl"

float3 FastBRDF(BRDFData brdfData, DisneySurfaceData surfaceData, DisneyInputData inputData, Light light, float NdotL)
{    
    float3 L = light.direction;
    float3 N = inputData.normalWS;
    float3 V = inputData.viewDirectionWS;
    float3 Y = inputData.bitangentWS;
    float3 H = SafeNormalize(L + V);
    
    //float NdotL = saturate(dot(N, L));
    //float NdotV = saturate(dot(N, V));
    float NdotH = saturate(dot(N, H));
    float LdotH = saturate(dot(L, H));
    float VdotH = saturate(dot(V, H));
    //float TdotH = saturate(dot(X, H));
    //float BdotH = saturate(dot(Y, H));
    
    // Unity URP  https://community.arm.com/events/1155
    float d = NdotH * NdotH * brdfData.roughness2MinusOne + 1.00001f;
    half LoH2 = LdotH * LdotH;
    half SpecularResult = brdfData.roughness2 / ((d * d) * max(0.1h, LoH2) * brdfData.normalizationTerm);
    
#if defined (SHADER_API_MOBILE) || defined (SHADER_API_SWITCH)
    SpecularResult = SpecularResult - HALF_MIN;
    SpecularResult = clamp(SpecularResult, 0.0, 100.0); // Prevent FP16 overflow on mobiles
#endif
    return SpecularResult;
}

float3 FastDirectLight(BRDFData brdfData, DisneySurfaceData surfaceData, DisneyInputData inputData, Light light, float NdotL, float shadowAttenuation)
{
    float3 SpecularResult = FastBRDF(brdfData, surfaceData, inputData, light, NdotL);
    
    float3 specColor = SpecularResult;// * lightColor * NdotL * PI;
    float3 diffColor = brdfData.diffuse;
    float3 DirectLightResult = diffColor * surfaceData.diffuse + brdfData.specular * specColor * surfaceData.specular;
#if _ReceiveShadow
    DirectLightResult = DirectLightResult * light.color * NdotL * shadowAttenuation;
#else
    DirectLightResult = DirectLightResult * light.color * NdotL;
#endif
    return DirectLightResult;
}

#ifdef _UseSSS 
    float3 FastSubsurfaceScattering(DisneyInputData inputData, DisneySurfaceData surfaceData, Light light)
    {
        float NdotL = dot(inputData.normalWS, light.direction) * 0.5 + 0.5;
        float VoL = saturate(dot(inputData.viewDirectionWS, -light.direction));
        //float3 H = SafeNormalize(light.direction + inputData.normalWS * _SSSOffset);
        
        float cur = saturate(surfaceData.curveFactor * (length(fwidth(inputData.normalWS)))/length(fwidth(inputData.positionWS))) * 0.5;
        float3 lutSss = SAMPLE_TEXTURE2D(_SSSLUT, sampler_SSSLUT, float2(min(NdotL, surfaceData.subsurfaceRange), min(cur, surfaceData.subsurfaceRange))).rgb;
        return lerp(0, VoL * lutSss, surfaceData.subsurface);
    }
    
    float3 SubsurfaceScattering(DisneyInputData inputData, DisneySurfaceData surfaceData, Light light)
    {
        float3 L = light.direction;
        float3 N = inputData.normalWS;
        float3 V = inputData.viewDirectionWS;
        
        float3 frontLitDir  = normalize(N * surfaceData.curveFactor - L);
        float3 backLitDir   = normalize(N * surfaceData.subsurfaceRange + L);
        float frontSSS      = saturate(dot(V, -frontLitDir));
        float backSSS       = saturate(dot(V, -backLitDir));
        float sss           = saturate(frontSSS * surfaceData.sssOffset + backLitDir);
        float sssPow        = saturate(pow(sss, surfaceData.sssPower));
        float3 result       = lerp(surfaceData.sssColor, light.color, sssPow) * surfaceData.subsurface;
        return result;
    }
#endif

#ifdef _UseAnisotropic 
    float3 FastAnisotropic(DisneyInputData inputData, DisneySurfaceData surfaceData, Light light, float NdotL, float shadowAttenuation)
    {
        // Anisotropic
        float3 L = light.direction;
        float3 N = inputData.normalWS;
        float3 V = inputData.viewDirectionWS;
        float3 Y = inputData.bitangentWS;
        float3 H = SafeNormalize(L + V);
        float shift = surfaceData.anisotropicShift;
        float3 aB = normalize(Y + shift * N); //worldBinormal
        float aBdotH = dot(aB, H);
        float sinTH = sqrt(1.0 - aBdotH * aBdotH);
        float dirAtten = smoothstep(-1, 0, aBdotH);
        float anisotropic = dirAtten * pow(sinTH, surfaceData.anisotropicGloss);
        
        float3 AnisotropicResult = anisotropic * saturate(NdotL * 2);
        #if _ReceiveShadow
            return lerp(0, AnisotropicResult, surfaceData.anisotropic) * shadowAttenuation;
        #else
            return lerp(0, AnisotropicResult, surfaceData.anisotropic) * 1;
        #endif
    }
#endif

#ifdef _UseRimLight 
    float3 FastRimLight(DisneyInputData inputData, DisneySurfaceData surfaceData, Light light, float shadowAttenuation)
    {
        float3 N = inputData.normalWS;
        float3 V = inputData.viewDirectionWS;
        float NdotV = saturate(dot(N, V));
        float rimRatio = 1 - saturate(dot(V, N * surfaceData.rimFresnelMask));
        float rimIntensity = pow(rimRatio, 1 / surfaceData.rimStrength);
        float3 rimColor = lerp(0, surfaceData.rimColor, rimIntensity);
        rimColor = lerp(0, rimColor * surfaceData.rimStrength, NdotV);
         #if _ReceiveShadow
            return rimColor * shadowAttenuation;
        #else
            return rimColor;
        #endif
    }
#endif

float4 FastBRDFFragment(DisneyInputData inputData, DisneySurfaceData surfaceData, float2 uv)
{
    BRDFData brdfData;
    InitializeBRDFData(surfaceData.albedo, surfaceData.metallic, surfaceData.specularColor, surfaceData.smoothness, brdfData);
    
#if defined(SHADOWS_SHADOWMASK) && defined(LIGHTMAP_ON)
    half4 shadowMask = inputData.shadowMask;
#elif !defined (LIGHTMAP_ON)
    half4 shadowMask = unity_ProbesOcclusion;
#else
    half4 shadowMask = half4(1, 1, 1, 1);
#endif
    Light mainLight = GetMainLight(inputData.shadowCoord, inputData.positionWS, shadowMask);
    
    #if defined(_SCREEN_SPACE_OCCLUSION)
        AmbientOcclusionFactor aoFactor = GetScreenSpaceAmbientOcclusion(inputData.normalizedScreenSpaceUV);
        mainLight.color *= lerp(1, aoFactor.directAmbientOcclusion, surfaceData.ssao);
        surfaceData.occlusion = lerp(surfaceData.occlusion, min(surfaceData.occlusion, aoFactor.indirectAmbientOcclusion), surfaceData.ssao);
        
        //return float4(aoFactor.directAmbientOcclusion.rrr, 1);
    #endif
    
    MixRealtimeAndBakedGI(mainLight, inputData.normalWS, inputData.bakedGI);

    float NdotL = saturate(dot(inputData.normalWS, mainLight.direction));
    float shadowAttenuation = mainLight.shadowAttenuation * mainLight.distanceAttenuation;
    shadowAttenuation = lerp(1, shadowAttenuation, surfaceData.shadowAttenuation);
    
    //return float4(mainLight.color.rgb, 1);
    //直接光照部分结果
    float3 DirectLightResult = FastDirectLight(brdfData, surfaceData, inputData, mainLight, NdotL, shadowAttenuation);
    //return float4(DirectLightResult, 1);
    
#ifdef _UseAnisotropic    
    DirectLightResult += FastAnisotropic(inputData, surfaceData, mainLight, NdotL, shadowAttenuation);
    //return float4(DirectLightResult, 1);
#endif
 
#ifdef _UseRimLight
    float3 rimColor = FastRimLight(inputData, surfaceData, mainLight, shadowAttenuation);
    DirectLightResult += rimColor;
    //return float4(rimColor, 1);
#endif

    float3 color = DirectLightResult;
    float3 IndirectLightResult = GlobalIllumination(brdfData, inputData.bakedGI, surfaceData.occlusion, inputData.normalWS, inputData.viewDirectionWS);
    //return float4(IndirectLightResult,1);
    color += lerp(0, IndirectLightResult, surfaceData.sheen);
    
#ifdef _ADDITIONAL_LIGHTS
    float3 sssColor = 0;
    int pixelLightCount = GetAdditionalLightsCount();
    for (int i = 0; i < pixelLightCount; ++i)
    {
        Light addlight = GetAdditionalLight(i, inputData.positionWS, shadowMask);
        float aNdotL = saturate(dot(inputData.normalWS, addlight.direction));
        #if defined(_SCREEN_SPACE_OCCLUSION)
            addlight.color *= aoFactor.directAmbientOcclusion;
        #endif
        color += FastDirectLight(brdfData, surfaceData, inputData, addlight, aNdotL, 1);
#ifdef _UseSSS
        //half3 screenUV = inputData.positionSS.xyz / inputData.positionSS.w;
        sssColor +=  SubsurfaceScattering(inputData, surfaceData, addlight); 
        color += sssColor;
#endif
    }
    return float4(sssColor,1);
#endif

#ifdef _ADDITIONAL_LIGHTS_VERTEX
    color += inputData.vertexLighting * brdfData.diffuse;
#endif

    //color += surfaceData.emission * _EmissionColor;
    
#ifdef _UseCutoff
    clip(surfaceData.emission - _Cutoff);
#endif
    return float4(color,1);
}
#endif

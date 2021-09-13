/// <summary>
/// <para>Author: zhengnan </para>
/// <para>Create: 2021年09月07日 星期二 23:29 </para>
/// </summary>

#ifndef PBR_LIT_UTILS
#define PBR_LIT_UTILS

half AppleAlpha(half outputAlpha, half surfaceType = 0.0)
{
    return surfaceType == 1 ? outputAlpha : 1.0;
}

half3 BlendNormal(Varyings input, float2 uv, TEXTURE2D_PARAM(bumpMap, sampler_bumpMap), half scale = 1.0h)
{
    half4 bump = SAMPLE_TEXTURE2D(bumpMap, sampler_bumpMap, uv);
    #if defined(ENABLE_BUMPMAP_SCALE)
        half3 normalTS =  UnpackNormalScale(bump, scale);
    #else
        half3 normalTS =  UnpackNormal(bump);
    #endif
    float3 bitangent = input.tangentWS.w * cross(input.normalWS.xyz, input.tangentWS.xyz); // should be either +1 or -1
    half3 N = TransformTangentToWorld(normalTS, half3x3(input.tangentWS.xyz, bitangent.xyz, input.normalWS.xyz));
    return N;
}

#endif
/// <summary>
/// <para>Author: zhengnan </para>
/// <para>Create: 2021年09月07日 星期二 23:29 </para>
/// </summary>
#ifndef FAST_LIT_PASS_INCLUDED
#define FAST_LIT_PASS_INCLUDED
 
#include "LitFastInputs.hlsl"
#include "LitFastBRDF.hlsl"
//#include "Unreal4BRDF.hlsl"
//#include "CookTorranceBRDF.hlsl"
#include "DitherDistance.hlsl"

float3 ACESFilm(float3 x)
{
    float a = 2.51f;
    float b = 0.03f;
    float c = 2.43f;
    float d = 0.59f;
    float e = 0.14f;
    return saturate((x*(a*x+b))/(x*(c*x+d)+e));
}

Varyings LitDinesyPassVertex(Attributes input)
{
    Varyings output = (Varyings) 0;
    
    UNITY_SETUP_INSTANCE_ID(input);
    UNITY_TRANSFER_INSTANCE_ID(input, output);
    UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);
    
    VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);
    VertexNormalInputs normalInput = GetVertexNormalInputs(input.normalOS, input.tangentOS);
    output.positionCS = vertexInput.positionCS;
    output.positionWS = vertexInput.positionWS;
    output.positionSS = ComputeScreenPos(input.positionOS);
    
    half3 viewDirWS = GetCameraPositionWS() - vertexInput.positionWS;
    //half3 viewDirWS = GetWorldSpaceViewDir(vertexInput.positionWS);
    half3 vertexLight = VertexLighting(vertexInput.positionWS, normalInput.normalWS);
    half fogFactor = ComputeFogFactor(vertexInput.positionCS.z);
    
    output.normalWS = float4(normalInput.normalWS, viewDirWS.x);
    output.tangentWS = float4(normalInput.tangentWS, viewDirWS.y);
    //real sign = input.tangentOS.w * GetOddNegativeScale();
    //float3 bitangent = sign * cross(normalInput.normalWS.xyz, normalInput.tangentWS.xyz); // should be either +1 or -1
    //output.bitangentWS = float4(bitangent, viewDirWS.z);
    output.bitangentWS = float4(normalInput.bitangentWS, viewDirWS.z);
    
    OUTPUT_LIGHTMAP_UV(input.lightmapUV, unity_LightmapST, output.lightmapUV);
    OUTPUT_SH(output.normalWS.xyz, output.vertexSH);
    
    output.uv = TRANSFORM_TEX(input.texcoord, _BaseMap);
    
    output.fogFactorAndVertexLight = float4(fogFactor, vertexLight);
    
    output.shadowCoord = GetShadowCoord(vertexInput);

    output.color = input.color;
    return output;
}

half4 LitDinesyPassFragment(Varyings input) : SV_Target
{
    UNITY_SETUP_INSTANCE_ID(input);
    UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

    DisneySurfaceData disneySurfaceData;
    InitializeDisneySurfaceData(input.uv.xy, disneySurfaceData);
    
#ifdef _UseFade
    PerformDither(input, disneySurfaceData.fade);
#endif

#ifdef _ALPHATEST_ON
    clip(disneySurfaceData.emission - _Cutoff);
#endif
    DisneyInputData disneyInputData;
    InitializeDisneyInputData(input, disneySurfaceData.normalTS, disneyInputData);

    float4 color = FastBRDFFragment(disneyInputData, disneySurfaceData);
    color.rgb = MixFog(color.rgb,  disneyInputData.fogCoord);
    //color.rgb = ACESFilm(color.rgb);
    //color = LinearToSRGB(color);

    //float4 baseColorMap = SAMPLE_TEXTURE2D(_BaseMap,sampler_BaseMap, input.uv.xy);
    //return baseColorMap;
    return color;
}

#endif

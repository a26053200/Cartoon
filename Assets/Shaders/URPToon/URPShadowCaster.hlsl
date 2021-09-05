CBUFFER_START(UnityPerMaterial)
float4 _BaseMap_ST;
CBUFFER_END

struct Attributes
{
    float3 positionOS: POSITION;
    half3 normalOS: NORMAL;
    half4 tangentOS: TANGENT;
    float2 uv: TEXCOORD0;
};

struct Varyings
{
    float2 uv: TEXCOORD0;
    float4 positionWSAndFogFactor: TEXCOORD2; // xyz: positionWS, w: vertex fog factor
    half3 normalWS: TEXCOORD3;
    
    #ifdef _MAIN_LIGHT_SHADOWS
        float4 shadowCoord: TEXCOORD6; // compute shadow coord per-vertex for the main light
    #endif
    float4 positionCS: SV_POSITION;
};

Varyings ShadowCasterPassVertex(Attributes input)
{
    Varyings output;
    
    // VertexPositionInputs contains position in multiple spaces (world, view, homogeneous clip space)
    // Our compiler will strip all unused references (say you don't use view space).
    // Therefore there is more flexibility at no additional cost with this struct.
    VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS);
    
    // Similar to VertexPositionInputs, VertexNormalInputs will contain normal, tangent and bitangent
    // in world space. If not used it will be stripped.
    VertexNormalInputs vertexNormalInput = GetVertexNormalInputs(input.normalOS, input.tangentOS);
    
    // Computes fog factor per-vertex.
    float fogFactor = ComputeFogFactor(vertexInput.positionCS.z);
    
    // TRANSFORM_TEX is the same as the old shader library.
    output.uv = TRANSFORM_TEX(input.uv, _BaseMap);
    
    // packing posWS.xyz & fog into a vector4
    output.positionWSAndFogFactor = float4(vertexInput.positionWS, fogFactor);
    output.normalWS = vertexNormalInput.normalWS;
    
    #ifdef _MAIN_LIGHT_SHADOWS
        // shadow coord for the light is computed in vertex.
        // After URP 7.21, URP will always resolve shadows in light space, no more screen space resolve.
        // In this case shadowCoord will be the vertex position in light space.
        output.shadowCoord = GetShadowCoord(vertexInput);
    #endif
    
    // Here comes the flexibility of the input structs.
    // We just use the homogeneous clip position from the vertex input
    output.positionCS = vertexInput.positionCS;
    
    // ShadowCaster pass needs special process to clipPos, else shadow artifact will appear
    //--------------------------------------------------------------------------------------
    
    //see GetShadowPositionHClip() in URP/Shaders/ShadowCasterPass.hlsl
    float3 positionWS = vertexInput.positionWS;
    float3 normalWS = vertexNormalInput.normalWS;
    
    
    Light light = GetMainLight();
    float4 positionCS = TransformWorldToHClip(ApplyShadowBias(positionWS, normalWS, light.direction));
    
    #if UNITY_REVERSED_Z
        positionCS.z = min(positionCS.z, positionCS.w * UNITY_NEAR_CLIP_VALUE);
    #else
        positionCS.z = max(positionCS.z, positionCS.w * UNITY_NEAR_CLIP_VALUE);
    #endif
    output.positionCS = positionCS;
    
    //--------------------------------------------------------------------------------------
    
    return output;
}

half4 ShadowCasterPassFragment(Varyings input): SV_TARGET
{
    return 0;
}
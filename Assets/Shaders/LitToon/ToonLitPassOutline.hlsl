#ifndef TOON_LIT_PASS_OUTLINE
#define TOON_LIT_PASS_OUTLINE

CBUFFER_START(UnityPerMaterial)
float4 _OutlineColor;
float _OutlineWidth;
CBUFFER_END

struct Attributes
{
    float4 positionOS : POSITION;
    float3 normalOS : NORMAL;
#ifdef _USESMOOTHNORMAL
    float4 tangentOS : TANGENT;
    float2 texcoord7 : TEXCOORD7;
#endif
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct Varyings
{
    float4 positionCS : SV_POSITION;
    UNITY_VERTEX_INPUT_INSTANCE_ID
    UNITY_VERTEX_OUTPUT_STEREO
};

float4 TransformOutlineToHClipScreenSpace(float4 position, float3 normal, float outlineWidth)
{
    float4 vertex = TransformObjectToHClip(position.xyz);
#ifdef _USESMOOTHNORMAL
    float3 clipNormal = TransformWorldToHClipDir(normal);
#else
    float3 normalWS = TransformObjectToWorldNormal(normal);
    float3 clipNormal = TransformWorldToHClipDir(normalWS);
#endif
    float2 projectedNormal = normalize(clipNormal.xy);
    float4 nearUpperRight = mul(unity_CameraInvProjection, float4(1, 1, UNITY_NEAR_CLIP_VALUE, _ProjectionParams.y));
    float aspect = abs(nearUpperRight.y / nearUpperRight.x);
    projectedNormal.x *= aspect;
    projectedNormal *= min(vertex.w, 5);
    vertex.xy += 0.01 * outlineWidth * projectedNormal.xy;
    return vertex;
}

//https://github.com/Jason-Ma-233/JasonMaToonRenderPipeline
//Get Smooth Outline NormalWS
float3 GetSmoothedWorldNormal(float2 uv7, float3x3 t_tbn)
{
    float3 normal = float3(uv7, 0);
    normal.z = sqrt(1.0 - saturate(dot(normal.xy, normal.xy)));
    return mul(normal, t_tbn);
}

Varyings VertexOutline(Attributes input)
{
    Varyings output = (Varyings) 0;

    UNITY_SETUP_INSTANCE_ID(input);
    UNITY_TRANSFER_INSTANCE_ID(input, output);
    UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);
#ifdef _USESMOOTHNORMAL
    float3 normalDir = TransformObjectToWorldNormal(input.normalOS);
    float3 tangentDir = TransformObjectToWorldNormal(input.tangentOS.xyz);
    float3 bitangentDir = normalize(cross(normalDir, tangentDir) * input.tangentOS.w);
    float3x3 t_tbn = float3x3(tangentDir,bitangentDir,normalDir);
    float3 bakeNormal = GetSmoothedWorldNormal(input.texcoord7,t_tbn);
    output.positionCS = TransformOutlineToHClipScreenSpace(input.positionOS, bakeNormal, _OutlineWidth);
#else
    output.positionCS = TransformOutlineToHClipScreenSpace(input.positionOS, input.normalOS, _OutlineWidth);
#endif
    return output;
}

half4 FragmentOutline(Varyings input) : SV_Target
{
    UNITY_SETUP_INSTANCE_ID(input);
    UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
    return _OutlineColor;
}

#endif //TOON_LIT_PASS_OUTLINE

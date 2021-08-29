/*
R通道:表示高光的强弱; G通道:表示阴影区域; B通道:控制高光区域的大小
A通道:
    0 hard/emission/specular/silk
    77 soft/common
    128 metal
    179 tights
    255 skin
*/
Varyings vert(Attributes v)
{
    Varyings o;
    VertexPositionInputs vertexInput = GetVertexPositionInputs(v.positionOS.xyz);
    o.positionCS = vertexInput.positionCS;
    o.positionWS = vertexInput.positionWS;
    o.positionNDC = vertexInput.positionNDC;
    o.positionVS = vertexInput.positionVS;
            
    o.uv = TRANSFORM_TEX(v.uv, _BaseMap);
    o.viewDirWS = GetCameraPositionWS() - vertexInput.positionWS;
    
    VertexNormalInputs vertexNormalInput = GetVertexNormalInputs(v.normal.xyz);
    o.normal = vertexNormalInput.normalWS;
    o.normalVS = TransformWorldToViewDir(vertexNormalInput.normalWS, true);
    
    o.samplePositionVS = float3(o.positionVS.xy + o.normal.xy * _RimOffsetMul, o.positionVS.z); // 保持z不变（CS.w = -VS.z）
    
    o.color = v.color;
    return o;
}

float4 TransformHClipToViewPortPos(float4 positionCS)
 {
     float4 o = positionCS * 0.5f;
     o.xy = float2(o.x, o.y * _ProjectionParams.x) + o.w;
     o.zw = positionCS.zw;
     return o / o.w;
 }

half4 frag(Varyings i): SV_Target
{
    half4 baseMap = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, i.uv) * _BaseColor;
    half4 finalColor = baseMap;
     // light
    float4 shadowCoord = TransformWorldToShadowCoord(i.positionWS.xyz);
    Light light = GetMainLight(shadowCoord);
    real shadow = light.shadowAttenuation * light.distanceAttenuation;
    
    half3 N = normalize(i.normal);
    half3 L = normalize(light.direction);
    half3 V = normalize(i.viewDirWS);
    half NdotL = max(0, dot(N, L));
    half lambert = NdotL * 0.5 + 0.5;    

    float4 samplePositionCS = TransformWViewToHClip(i.samplePositionVS); // input.positionCS不是真正的CS 而是SV_Position屏幕坐标
    float4 samplePositionVP = TransformHClipToViewPortPos(samplePositionCS);
    float depth = i.positionNDC.z / i.positionNDC.w;
    float linearEyeDepth = LinearEyeDepth(depth, _ZBufferParams); // 离相机越近越小
    float3 depthTex = SAMPLE_TEXTURE2D_X(_CameraDepthTexture, sampler_CameraDepthTexture, samplePositionVP);
    float offsetDepth = depthTex.r; // _CameraDepthTexture.r = input.positionNDC.z / input.positionNDC.w
    float linearEyeOffsetDepth = LinearEyeDepth(offsetDepth, _ZBufferParams);
    float depthDiff = linearEyeOffsetDepth - linearEyeDepth;
    float rimIntensity = step(_RimThreshold, depthDiff);
    float3 rimColor = depthTex;
    //_FresnelMask
    float3 viewDirectionWS = SafeNormalize(GetCameraPositionWS() - i.positionWS);
    float rimRatio = 1 - saturate(dot(viewDirectionWS, N));
    rimRatio = pow(rimRatio, exp2(lerp(4.0, 0.0, _FresnelMask)));
    rimIntensity = lerp(0, rimIntensity, rimRatio);
    //rimColor = lerp(float3(0, 0, 0), float3(1, 1, 1), rimIntensity);

    finalColor.rgb = rimColor;
    return half4(finalColor.rgb, 1);
}
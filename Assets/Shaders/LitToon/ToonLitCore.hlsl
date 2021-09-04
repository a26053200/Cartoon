#ifndef TOON_LIT_CORE
#define TOON_LIT_CORE

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
    Varyings o = (Varyings)0;
     
    VertexPositionInputs vertexInput = GetVertexPositionInputs(v.positionOS.xyz);
    o.positionCS = vertexInput.positionCS;
    o.positionWS = vertexInput.positionWS;
    o.positionNDC = vertexInput.positionNDC;
    o.positionVS = vertexInput.positionVS;
    
    VertexNormalInputs vertexNormalInput = GetVertexNormalInputs(v.normal.xyz);
    o.normal = vertexNormalInput.normalWS;
    o.normalVS = TransformWorldToViewDir(vertexNormalInput.normalWS, true);
   
            
    o.uv.xy = TRANSFORM_TEX(v.uv, _BaseMap);
    o.viewDirWS = GetCameraPositionWS() - vertexInput.positionWS;
    
    o.uv.z = ComputeFogFactor(vertexInput.positionCS.z);
    
    //o.scrPos = ComputeScreenPos(vertexInput.positionCS);
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

half4 frag(Varyings i) : SV_Target
{
    half4 baseMap = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, i.uv.xy) * _BaseColor;
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
#ifdef _BODY
    half4 lightMap = SAMPLE_TEXTURE2D(_LightMap, sampler_LightMap, i.uv.xy);
    half3 shadowColor = baseMap.rgb * _ShadowMultiColor.rgb;
    half3 darkShadowColor = baseMap.rgb * _DarkShadowMultiColor.rgb;
    half shadowMask = dot(lightMap, _LightMapMask);
    
    //如果SFactor = 0,ShallowShadowColor为一级阴影色,否则为BaseColor。
    float sWeight = (shadowMask * i.color.r + lambert) * 0.5 + 1.125;
    float sFactor = floor(sWeight - _ShadowArea);
    half3 shallowShadowColor = sFactor * baseMap.rgb + (1 - sFactor) * shadowColor.rgb;
    
    //如果SFactor = 0,DarkShadowColor为二级阴影色,否则为一级阴影色。
    sFactor = floor(sWeight - _DarkShadowArea);
    darkShadowColor = sFactor * (_FixDarkShadow * shadowColor + (1 - _FixDarkShadow) * shallowShadowColor) + (1 - sFactor) * darkShadowColor;

    // 平滑阴影边缘
    half rampS = smoothstep(0, _ShadowSmooth, lambert - _ShadowArea);
    half rampDS = smoothstep(0, _DarkShadowSmooth, lambert - _DarkShadowArea);
    shallowShadowColor.rgb = lerp(shadowColor, baseMap.rgb, rampS);
    darkShadowColor.rgb = lerp(darkShadowColor.rgb, shadowColor, rampDS);
    
    //如果SFactor = 0,FinalColor为二级阴影，否则为一级阴影。
    sFactor = floor(shadowMask * i.color.r + 0.9f);
    half3 finalShadow = sFactor * shallowShadowColor + (1 - sFactor) * darkShadowColor;
    finalColor.rgb = lerp(finalShadow, baseMap.rgb, baseMap.a);
    
    // Specular Blinn-Phong
    float3 H = normalize(L + V);
    float NdotH = saturate(dot(N, H));
    float specularIntensity = pow(NdotH, _Glossiness);
    //float specularRange = step(_SpecularRange, specularIntensity);
    specularIntensity = step(1.0f - lightMap.b, specularIntensity);
    //float specularRange = specularIntensity - (1 - lightMap.b * _SpecularRange);
    //half3 specular = lerp(0, specularRange * _SpecularColor * lightMap.r, lightMap.b);
    half3 specular = _SpecularRange * specularIntensity * _SpecularColor.rgb * lightMap.r;
    
    //finalColor.rgb = specular.rgb;
    //finalColor.rgb += lerp(specular.rgb, 0, baseMap.a);
    //finalColor.rgb = lerp((finalColor.rgb + specular.rgb) * _BaseColor.rgb, finalColor.rgb, baseMap.a);
#endif

//基于深度的硬边缘光
    float3 rimColor = 0;
#ifdef _RIM
    /*
    float2 screenPos= i.scrPos .xy / i.scrPos .w;
    float depth = SAMPLE_TEXTURE2D_X(_CameraDepthTexture, sampler_CameraDepthTexture, screenPos).r;
    float depthValue = Linear01Depth(depth, _ZBufferParams);
    */
    float4 samplePositionCS = TransformWViewToHClip(i.samplePositionVS); // input.positionCS不是真正的CS 而是SV_Position屏幕坐标
    float4 samplePositionVP = TransformHClipToViewPortPos(samplePositionCS);
    float offsetDepth = SAMPLE_TEXTURE2D_X(_CameraDepthTexture, sampler_CameraDepthTexture, samplePositionVP.xy).r; // _CameraDepthTexture.r = input.positionNDC.z / input.positionNDC.w
    float linearEyeOffsetDepth = LinearEyeDepth(offsetDepth, _ZBufferParams);
    float depth = i.positionNDC.z / i.positionNDC.w;
    float linearEyeDepth = LinearEyeDepth(depth, _ZBufferParams); // 离相机越近越小
    float depthDiff = linearEyeOffsetDepth - linearEyeDepth;
    float rimIntensity = step(_RimThreshold, depthDiff);
    
    //_FresnelMask
    float rimRatio = 1 - saturate(dot(V, N));
    //rimRatio = pow(rimRatio, exp2(lerp(4.0, 0.0, _FresnelMask)));
    rimIntensity = lerp(0, rimIntensity, rimRatio);
    //rimColor = rimIntensity.xxx;
    //rimColor = rimRatio.xxx * _RimStrength;
    rimColor = lerp(0, _RimColor.rgb, rimIntensity);
    finalColor.rgb += rimColor * _RimStrength;
    //rimColor = rimIntensity.xxx;
#endif

#ifdef _FACE
    // 左右翻转
    float2 flipUV = float2(1 - i.uv.x, i.uv.y);
    half4 faceLightMapL = SAMPLE_TEXTURE2D(_FaceLightMap, sampler_FaceLightMap, i.uv.xy);
    half4 faceLightMapR = SAMPLE_TEXTURE2D(_FaceLightMap, sampler_FaceLightMap, flipUV);
    // 计算光照旋转偏移
    float sinx = sin(_FaceShadowOffset);
    float cosx = cos(_FaceShadowOffset);
    float2x2 rotationOffset = float2x2(cosx, -sinx, sinx, cosx);
    float3 Front = _FaceFront.xyz;//unity_ObjectToWorld._12_22_32;
    float3 Right = -_FaceRight.xyz;//unity_ObjectToWorld._13_23_33;
    float2 lightDir = mul(rotationOffset, L.xz);
    
    //计算xz平面下的光照角度
    float FrontL = dot(normalize(Front.xz), normalize(lightDir));
    float RightL = dot(normalize(Right.xz), normalize(lightDir));
    RightL = - (acos(RightL) / PI - 0.5) * 2;

    //左右各采样一次FaceLightMap的阴影数据存于lightData
    float2 lightData = float2(faceLightMapL.r,faceLightMapR.r);
    //修改lightData的变化曲线，使中间大部分变化速度趋于平缓。
    lightData = pow(abs(lightData), _FaceShadowMapPow);

    //根据光照角度判断是否处于背光，使用正向还是反向的lightData。
    float lightAttenuation = step(0, FrontL) * min(step(RightL, lightData.x), step(-RightL, lightData.y));
    float3 faceShadowColor = lerp(_FaceShadowColor.rgb, 1, lightAttenuation);//lerp函数为最后的面部颜色赋值
    //有的角色有脸颊的亮度,不受阴影或者少阴影
    finalColor.rgb *= lerp(faceShadowColor, 1, baseMap.a);	
    /*
    float3 N0 = L - float3(0,1,0) * dot(L, float3(0,1,0));
    float faceLambert = max(0, dot(_FaceFront.rgb, normalize(N0))) * 0.5 + 0.5;
    //当光源从角色背后照射时，面部应该为全阴影。所以要有一个控制量。
    float ctrl = step(0, dot(_FaceFront.xz, L.xz));
    //右侧光源方向就用右侧的阈值图，左侧光源方向就用反向采样的左侧阈值图，使用min函数取两个阈值计算结果的最小值进行融合。
    //最后乘以ctrl，使得背光时面部表现为全阴影
    float faceShadow = ctrl * min(step(dot(_FaceLeft.xz, L.xz), faceLightMapR.r), step(dot(_FaceRight.xz, L.xz), faceLightMapL.r));
     //_AmbientColor是暴露在外的参数，可以随时调整面部阴影颜色。
    finalColor.rgb *= lerp(1, _FaceShadowColor.rgb, faceShadow) * faceLambert;	//lerp函数为最后的面部颜色赋值
    */
#endif
    //Debug
    //finalColor.rgb = rimColor;
    
    // Mix Fog
    finalColor.rgb = MixFog(finalColor.rgb, i.uv.z);
    
    return half4(finalColor.rgb, 1);
}

#endif //TOON_LIT_CORE
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
    o.uv = TRANSFORM_TEX(v.uv, _BaseMap);
    o.viewDirWS = GetCameraPositionWS() - vertexInput.positionWS;
    
    VertexNormalInputs vertexNormalInput = GetVertexNormalInputs(v.normal.xyz);
    o.normal = vertexNormalInput.normalWS;
    
    o.color = v.color;
    return o;
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
#ifdef _BODY
    half4 lightMap = SAMPLE_TEXTURE2D(_LightMap, sampler_LightMap, i.uv);
    half3 shadowColor = baseMap.rgb * _ShadowMultiColor.rgb;
    half3 darkShadowColor = baseMap.rgb * _DarkShadowMultiColor.rgb;
    
    //如果SFactor = 0,ShallowShadowColor为一级阴影色,否则为BaseColor。
    float sWeight = (lightMap.g * i.color.r + lambert) * 0.5 + 1.125;
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
    sFactor = floor(lightMap.g * i.color.r + 0.9f);
    finalColor.rgb = sFactor * shallowShadowColor + (1 - sFactor) * darkShadowColor;
    
    // Specular Blinn-Phong
    float3 H = normalize(L + V);
    float NdotH = saturate(dot(N, H));
    float specularIntensity = pow(NdotH, _Glossiness);
    float specularRange = step(_SpecularRange, specularIntensity);
    //float specularRange = specularIntensity - (1 - lightMap.b * _SpecularRange);
    half3 specular = lerp(0, specularRange * _SpecularColor * lightMap.r, lightMap.b);
    //half3 specular = specularRange * _SpecularColor * lightMap.r;
    
    //finalColor.rgb = specular.rgb;
    finalColor.rgb += specular.rgb;
#endif

#ifdef _FACE
    // 左右翻转
    float2 flipUV = float2(1 - i.uv.x, i.uv.y);
    half4 faceLightMapL = SAMPLE_TEXTURE2D(_FaceLightMap, sampler_FaceLightMap, i.uv);
    half4 faceLightMapR = SAMPLE_TEXTURE2D(_FaceLightMap, sampler_FaceLightMap, flipUV);
    float3 N0 = L - N * dot(L, N);
    float faceLambert = dot(_FaceFront.rgb, normalize(N0));
    
    //当光源从角色背后照射时，面部应该为全阴影。所以要有一个控制量。
    float ctrl = step(0, dot(_FaceFront.xz, L.xz));
    //右侧光源方向就用右侧的阈值图，左侧光源方向就用反向采样的左侧阈值图，使用min函数取两个阈值计算结果的最小值进行融合。
    //最后乘以ctrl，使得背光时面部表现为全阴影
    float faceShadow = ctrl * min(step(dot(_FaceLeft.xz, L.xz), faceLightMapL.r), step(dot(_FaceRight.xz, L.xz), faceLightMapR.r));
     //_AmbientColor是暴露在外的参数，可以随时调整面部阴影颜色。
    finalColor.rgb *= lerp(1, _FaceShadowColor.rgb, faceShadow) * lambert;	//lerp函数为最后的面部颜色赋值

    /*
    float3 N0 = L - N * dot(L, N);
    float Lambert = dot(_FaceFront.rgb, normalize(N0));
    
    half LR = cross(_FaceFront.rgb, L).y;
    half4 faceShadow = lerp(faceLightMapL, faceLightMapR, step(LR, 0));
    faceShadow = lerp(1, 1 - _FaceShadowColor.a, step(faceShadow.a, Lambert));
    finalColor.rgb = lerp(_FaceShadowColor.rgb, finalColor.rgb, faceShadow.rgb);
    */
    /*
    float FrontL = dot(normalize(_FaceFront.xz), normalize(L.xz));
    float RightL = dot(normalize(_FaceRight.xz), normalize(L.xz));
    RightL = -(acos(RightL) / 3.14159265 - 0.5) * 2;
    float lightAttenuation = (FrontL > 0) * min((faceLightMap.r > RightL), (faceLightMap.g > -RightL));
    finalColor.rgb *= lightAttenuation;
    */
#endif
    return half4(finalColor.rgb, 1);
}
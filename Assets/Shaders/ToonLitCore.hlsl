

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
    half4 baseMap = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, i.uv);
    
    half4 finalColor;
#ifdef _BODY
    /*
    R通道:表示高光的强弱; G通道:表示阴影区域; B通道:控制高光区域的大小
    A通道:
        0 hard/emission/specular/silk
        77 soft/common
        128 metal
        179 tights
        255 skin
    */
    half4 lightMap = SAMPLE_TEXTURE2D(_LightMap, sampler_LightMap, i.uv);
    half3 shadowColor = baseMap.rgb * _ShadowMultiColor.rgb;
    half3 darkShadowColor = baseMap.rgb * _DarkShadowMultiColor.rgb;
    // light
    float4 shadowCoord = TransformWorldToShadowCoord(i.positionWS.xyz);
    Light light = GetMainLight(shadowCoord);
    real shadow = light.shadowAttenuation * light.distanceAttenuation;
    
    half3 N = normalize(i.normal);
    half3 L = normalize(light.direction);
    half3 V = normalize(i.viewDirWS);
    half NdotL = max(0, dot(N, L));
    half lambert = NdotL;// * 0.5 + 0.5;
    
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
#else
    finalColor.rgb = baseMap.rgb;
#endif

    return half4(finalColor.rgb, 1);
}
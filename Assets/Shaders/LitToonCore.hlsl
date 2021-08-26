

Varyings vert(Attributes v)
{
    Varyings o;
    
    VertexPositionInputs positionInputs = GetVertexPositionInputs(v.positionOS.xyz);
    o.positionCS = positionInputs.positionCS;
    o.uv = TRANSFORM_TEX(v.uv, _BaseMap);
    
    VertexNormalInputs vertexNormalInput = GetVertexNormalInputs(v.normal.xyz);
    o.normal = vertexNormalInput.normalWS;
    
    o.color = v.color;
    return o;
}


half4 frag(Varyings i): SV_Target
{
    half4 baseMap = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, i.uv);
    half4 lightMap = SAMPLE_TEXTURE2D(_LightMap, sampler_LightMap, i.uv);
    half3 shadowColor = baseMap.rgb * _ShadowMultColor.rgb;
    half3 darkShadowColor = baseMap.rgb * _DarkShadowMultColor.rgb;

    // light
    float4 shadowCoord = TransformWorldToShadowCoord(i.positionWS.xyz);
    Light light = GetMainLight(shadowCoord);
    
    half3 N = i.normal;
    half3 L = light.direction;
    half NdotL = dot(N, L);
    half lambert = NdotL * 0.5 + 0.5;
    
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
    SFactor = floor(LightMapColor.g * input.color.r + 0.9f);
    half4 FinalColor;
    FinalColor.rgb = SFactor * ShallowShadowColor + (1 - SFactor) * DarkShadowColor;

    float3 final = baseMap.rgb;
    
    return float4(final, 1);
}

v2f vert(a2v v)
{
    v2f o;
    
    VertexPositionInputs positionInputs = GetVertexPositionInputs(v.positionOS.xyz);
    o.positionCS = positionInputs.positionCS;
    o.positionWS = positionInputs.positionWS;
    
    #if _IsFace
        o.posNDCw = positionInputs.positionNDC.w;
        o.positionSS = ComputeScreenPos(positionInputs.positionCS);
        o.positionOS = v.positionOS;
    #endif
    
    o.uv = TRANSFORM_TEX(v.uv, _BaseMap);
    
    VertexNormalInputs vertexNormalInput = GetVertexNormalInputs(v.normal.xyz);
    o.normal = vertexNormalInput.normalWS;
    
    o.color = v.color;
    return o;
}


half4 frag(v2f i): SV_Target
{
    half4 baseMap = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, i.uv);
    float4 shadowCoord = TransformWorldToShadowCoord(i.positionWS.xyz);
    Light light = GetMainLight(shadowCoord);
    float3 normal = normalize(i.normal);
    
    //get light and receive shadow
    Light mainLight;
    #if _MAIN_LIGHT_SHADOWS
        mainLight = GetMainLight(TransformWorldToShadowCoord(i.positionWS));
    #else
        mainLight = GetMainLight();
    #endif
    real shadow = mainLight.shadowAttenuation * mainLight.distanceAttenuation;
    
    //basic cel shading
    float CelShadeMidPoint = _CelShadeMidPoint;
    float halfLambert = dot(normal, light.direction) * 0.5 + 0.5;
    half ramp = smoothstep(0, CelShadeMidPoint, pow(saturate(halfLambert - CelShadeMidPoint), _CelShadeSmoothness));
    
    
    //face shadow
    #if _IsFace
        //"heightCorrect" is a easy mask which used to deal with some extreme view angles,
        //you can delete it if you think it's unnecessary.
        //you also can use it to adjust the shadow length, if you want.
        float heightCorrect = smoothstep(_HeightCorrectMax, _HeightCorrectMin, i.positionWS.y);
        
        //In DirectX, z/w from [0, 1], and use reversed Z
        //So, it means we aren't adapt the sample for OpenGL platform
        float depth = (i.positionCS.z / i.positionCS.w);
        
        //get linearEyeDepth which we can using easily
        float linearEyeDepth = LinearEyeDepth(depth, _ZBufferParams);
        float2 scrPos = i.positionSS.xy / i.positionSS.w;
        
        //"min(1, 5/linearEyeDepth)" is a curve to adjust viewLightDir.length by distance
        float3 viewLightDir = normalize(TransformWorldToViewDir(mainLight.direction)) * (1 / min(i.posNDCw, 1)) * min(1, 5 / linearEyeDepth) /** heightCorrect*/;
        
        //get the final sample point
        float2 samplingPoint = scrPos + _HairShadowDistace * viewLightDir.xy;
        
        float hairDepth = SAMPLE_TEXTURE2D(_HairSoildColor, sampler_HairSoildColor, samplingPoint).g;
        hairDepth = LinearEyeDepth(hairDepth, _ZBufferParams);
        
        //0.01 is bias
        float depthContrast = linearEyeDepth  > hairDepth * heightCorrect - 0.01 ? 0: 1;
        
        //deprecated
        //float hairShadow = 1 - SAMPLE_TEXTURE2D(_HairSoildColor, sampler_HairSoildColor, samplingPoint).r;
        
        //0 is shadow part, 1 is bright part
        ramp *= depthContrast;
    #else
        
        ramp *= shadow;
        
    #endif
    
    
    float3 diffuse = lerp(_DarkColor.rgb, _BrightColor.rgb, ramp);
    diffuse *= baseMap.rgb;
    
    //rim light
    float3 viewDirectionWS = SafeNormalize(GetCameraPositionWS() - i.positionWS.xyz);
    float rimStrength = pow(saturate(1 - dot(normal, viewDirectionWS)), _RimSmoothness);
    float3 rimColor = _RimColor.rgb * rimStrength * _RimStrength;
    
    return float4(diffuse + rimColor, 1);
    return baseMap * _BaseColor;
}
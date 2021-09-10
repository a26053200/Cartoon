/// <summary>
/// <para>Author: zhengnan </para>
/// <para>Create: 2021年09月07日 星期二 23:29 </para>
/// </summary>

Varyings vert(Attributes input)
{
    Varyings output = (Varyings) 0;
    
    UNITY_SETUP_INSTANCE_ID(input);
    UNITY_TRANSFER_INSTANCE_ID(input, output);
    UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);
    
    VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);
    output.positionCS = vertexInput.positionCS;
    
    VertexNormalInputs normalInput = GetVertexNormalInputs(input.normalOS, input.tangentOS);
    output.normalWS = normalInput.normalWS;
    #if defined(ENABLE_BUMPMAP)
        real sign = input.tangentOS.w * GetOddNegativeScale();
        half4 tangentWS = half4(normalInput.tangentWS.xyz, sign);
        output.tangentWS = tangentWS;
    #endif

    half3 viewDirWS = GetWorldSpaceViewDir(vertexInput.positionWS);
    half3 vertexLight = VertexLighting(vertexInput.positionWS, normalInput.normalWS);
    half fogFactor = ComputeFogFactor(vertexInput.positionCS.z);
    
    output.uv.xy = TRANSFORM_TEX(input.texcoord, _BaseMap);
    output.uv.z = ComputeFogFactor(vertexInput.positionCS.z);
    
    output.viewDirWS = viewDirWS;
    output.positionWS = vertexInput.positionWS;
    output.shadowCoord = GetShadowCoord(vertexInput);

    output.color = input.color;
    return output;
}


void InitSurfaceData(float2 uv, out PBRSurfaceData outSurfaceData)
{
    half4 albedoAlpha = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, uv);
    half4 maskMap = SAMPLE_TEXTURE2D(_Mask, sampler_Mask, uv);

    outSurfaceData.albedo = albedoAlpha.rgb * _BaseColor.rgb;
    outSurfaceData.metallic = maskMap.g * _Metallic;
    outSurfaceData.specular = _SpecColor.rgb * _SpecColor;
    outSurfaceData.roughness = maskMap.r * _Roughness;
    outSurfaceData.smoothness = (1 - maskMap.r) * _Smoothness;
    //outSurfaceData.normalTS = SampleNormal(uv, TEXTURE2D_ARGS(_BumpMap, sampler_BumpMap), _BumpScale);
    outSurfaceData.occlusion = maskMap.b;
    outSurfaceData.emission = 0;
    outSurfaceData.alpha = 0;
    outSurfaceData.clearCoatMask       = 0.0h;
    outSurfaceData.clearCoatSmoothness = 1.0h;
}

half4 frag(Varyings input) : SV_Target
{
    //lighting
    Light light = GetMainLight(input.shadowCoord);
    real shadow = light.shadowAttenuation * light.distanceAttenuation;
    
    PBRSurfaceData surfaceData;
    InitSurfaceData(input.uv.xy, surfaceData);
    
    
    float3 X = input.tangentWS;
    float3 bitangent = input.tangentWS.w * cross(input.normalWS.xyz, input.tangentWS.xyz); // should be either +1 or -1
    float3 Y = bitangent;
    
    half3 N = input.normalWS;
    #if defined(ENABLE_BUMPMAP)
        #if defined(ENABLE_BUMPMAP_SCALE)
            N = BlendNormal(input, input.uv.xy, TEXTURE2D_ARGS(_BumpMap, sampler_BumpMap), _BumpScale);
        #else
            N = BlendNormal(input, input.uv.xy, TEXTURE2D_ARGS(_BumpMap, sampler_BumpMap));
        #endif
    #endif
    
    half3 L = normalize(light.direction);
    half3 V = normalize(input.viewDirWS);
    half3 H = normalize(V + L);
    half3 R = -reflect(V, N);
    
    half NdotL = max(0, dot(N, L));
    half RdotL = max(0, dot(R, L));
    half NdotH = max(0, dot(N, H));
    
    half diffuse = NdotL * 0.5 + 0.5;
    
    //half3 finalColor = baseMap.rgb * diffuse * light.color;
    
    half3 finalColor = DisneyBRDF(L, V, N, X, Y, 
        surfaceData.albedo,
        surfaceData.roughness,
        surfaceData.metallic,
        surfaceData.specular,
        _SpecColor,
        _Sheen,
        _SheenColor,
        surfaceData.clearCoatMask,
        surfaceData.clearCoatSmoothness,
        _Subsurface,
        _Anisotropic);
    //debug
    //finalColor.rgb = specColor.rgb;
    //clip(baseMap.a - _Cutoff);
    
    //finalColor = MixFog(finalColor, input.uv.z);
    return half4(finalColor.rgb, 1);
}

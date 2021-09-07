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
    
    
    
    /*
    // 计算世界坐标下的顶点，法线，切线，副法线
    float3 worldPos = output.positionWS;
    half3 worldNormal = output.normal;
    half3 worldTangent = TransformObjectToWorldDir(input.tangent.xyz);
    half3 worldBinormal = cross(worldNormal, worldTangent) * input.tangent.w;
    // 计算从切线空间到世界空间的方向变换矩阵
    // 按列摆放得到从切线转世界空间的变换矩阵
    output.TtoW0 = float4(worldTangent.x, worldBinormal.x, worldNormal.x, worldPos.x);
    output.TtoW1 = float4(worldTangent.y, worldBinormal.y, worldNormal.y, worldPos.y);
    output.TtoW2 = float4(worldTangent.z, worldBinormal.z, worldNormal.z, worldPos.z);
    */
    output.color = input.color;
    return output;
}

half4 frag(Varyings input) : SV_Target
{
    half4 baseMap = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, input.uv.xy);
    half4 maskMap = SAMPLE_TEXTURE2D(_Mask, sampler_Mask, input.uv.xy);
    
    //lighting
    Light light = GetMainLight(input.shadowCoord);
    real shadow = light.shadowAttenuation * light.distanceAttenuation;
    
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
    
    half3 finalColor = baseMap.rgb * diffuse * light.color;
    //debug
    //finalColor.rgb = specColor.rgb;
    //clip(baseMap.a - _Cutoff);
    
    finalColor = MixFog(finalColor, input.uv.z);
    return half4(finalColor.rgb, 1);
}

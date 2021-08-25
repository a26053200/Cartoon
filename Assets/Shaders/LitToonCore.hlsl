

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
    
    float3 final = baseMap.rgb;
    
    return float4(final, 1);
}
Varyings vert(Attributes v)
{
    Varyings o;
    VertexPositionInputs vertexInput = GetVertexPositionInputs(v.positionOS.xyz);
    o.positionCS = vertexInput.positionCS;
    return o;
}

half4 frag(Varyings i): SV_Target
{
    half4 baseMap = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, i.uv) * _BaseColor;
    return baseMap;
}
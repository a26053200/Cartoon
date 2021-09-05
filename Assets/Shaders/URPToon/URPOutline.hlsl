CBUFFER_START(UnityPerMaterial)
float4 _OutlineColor;
float _OutlineThickness;
CBUFFER_END

struct a2v
{
    float4 positionOS: POSITION;
    float4 normalOS: NORMAL;
    float4 tangentOS: TANGENT;
    #ifdef _USE_VERTEX_COLOR
        float3 color: COLOR;
    #endif
};

struct v2f
{
    float4 positionCS: SV_POSITION;
};

v2f Vertex(a2v v)
{
    v2f o;
    VertexNormalInputs vertexNormalInput = GetVertexNormalInputs(v.normalOS, v.tangentOS);
    #ifdef _USE_VERTEX_COLOR
        float3 color = v.color * 2 - 1;
        VertexPositionInputs positionInputs = GetVertexPositionInputs(v.positionOS.xyz + float3(color.xy * 0.001 * _OutlineThickness, 0));
        o.positionCS = positionInputs.positionCS;
    #else
        float3 normalWS = vertexNormalInput.normalWS;
        float3 normalCS = TransformWorldToHClipDir(normalWS);
        VertexPositionInputs positionInputs = GetVertexPositionInputs(v.positionOS.xyz);
        o.positionCS = positionInputs.positionCS + float4(normalCS.xy * 0.001 * _OutlineThickness * positionInputs.positionCS.w, 0, 0);
    #endif
    return o;
}

half4 Fragment(v2f i): SV_Target
{
    float4 col = _OutlineColor;
    return col;
}
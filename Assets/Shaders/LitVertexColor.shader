Shader "LitToon/LitVertexColor"
{
    Properties
    {
        
    }
    SubShader
    {
        Tags { "RenderType" = "Opaque" "RenderPipeline" = "UniversalRenderPipeline" }
        
        HLSLINCLUDE
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        
        ENDHLSL
        
        Pass
        {
            Name "LitVertexColor"
            Tags { "LightMode" = "UniversalForward" }
            
            HLSLPROGRAM
            
            #pragma vertex vert
            #pragma fragment frag

            struct Attributes
            {
                float4 positionOS: POSITION;
                float3 normal: NORMAL;
                float4 color: COLOR;
            };
            
            struct Varyings
            {
                float4 positionCS: SV_POSITION;
                float3 normal: NORMAL;
                float4 color: COLOR;
            };
            
            Varyings vert(Attributes v)
            {
                Varyings o;
                
                VertexPositionInputs positionInputs = GetVertexPositionInputs(v.positionOS.xyz);
                o.positionCS = positionInputs.positionCS;
                VertexNormalInputs vertexNormalInput = GetVertexNormalInputs(v.normal.xyz);
                o.normal = vertexNormalInput.normalWS;
                o.color = v.color;
                return o;
            }
            
            half4 frag(Varyings i): SV_Target
            {
                return half4(i.color.rgb, 1);
            }
            ENDHLSL
        }
    }
    CustomEditor "URPToon.LitToonShaderGUI"
}
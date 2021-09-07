/// <summary>
/// <para>Author: zhengnan </para>
/// <para>Create: 2021年09月07日 星期二 23:29 </para>
/// </summary>
Shader "LitPBR/Avatar/PBRBody"
{
    Properties
    {
        [MainTexture] _BaseMap("Albedo", 2D) = "white" {}
        [MainColor] _BaseColor("Color", Color) = (1,1,1,1)
        _BumpScale("Bump Scale", Float) = 1.0
        _BumpMap("Normal Map", 2D) = "bump" {}
        _Cutoff("Alpha Cutoff", Range(0.0, 1.0)) = 0.5

        [Space]
        _Mask("Mask R(高光区域) G(粗糙度) B(高光强度) A(AO)", 2D) = "white" {}
        
        [Space]
        [Header(Specular)][Space]
        _Smoothness("Smoothness", Range(0.0, 1.0)) = 0.5
        _GlossMapScale("Smoothness Scale", Range(0.0, 1.0)) = 1.0
        _SmoothnessTextureChannel("Smoothness texture channel", Float) = 0
        _Metallic("Metallic", Range(0.0, 1.0)) = 0.0
        _SpecColor("Specular", Color) = (0.2, 0.2, 0.2)
        _OcclusionStrength("Strength", Range(0.0, 1.0)) = 1.0
        
    }
    SubShader
    {
        Tags {"Queue" = "Geometry" "RenderPipeline" = "UniversalRenderPipeline" "RenderType" = "Opaque" }
        //Tags {"Queue" = "Transparent" "RenderPipeline" = "UniversalPipeline" "RenderType" = "Transparent"}
        //Tags {"Queue" = "AlphaTest" "RenderPipeline" = "UniversalPipeline" "RenderType" = "TransparentCutout"}
        
        HLSLINCLUDE
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Packing.hlsl"
        ENDHLSL
        
        Pass
        {
            Name "BaseCel"
            Tags { "LightMode" = "UniversalForward" }
            Blend One Zero
            //Blend SrcAlpha OneMinusSrcAlpha
            Cull Back
            
            HLSLPROGRAM
            
            // -------------------------------------
            // Universal Pipeline keywords
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            //#pragma multi_compile_fragment _ _SHADOWS_SOFT
            // -------------------------------------
            
            #pragma vertex vert
            #pragma fragment frag

            #pragma multi_compile_instancing
            #pragma multi_compile_fog
            
            #define ENABLE_BUMPMAP
            #define ENABLE_BUMPMAP_SCALE
            
            #include "PBRLitProperty.hlsl"
            #include "PBRLitUtils.hlsl"
            #include "PBRLitPassForward.hlsl" 
            
            ENDHLSL
        }
        
        UsePass "Universal Render Pipeline/Lit/ShadowCaster" 
    }
    //CustomEditor "URPToon.LitToonShaderGUI"
}
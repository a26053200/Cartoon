/// <summary>
/// <para>Author: zhengnan </para>
/// <para>Create: 2021年09月07日 星期二 23:29 </para>
/// </summary>
Shader "DinesyLit/DinesyLit"
{
    Properties
    {
        [MainTexture] _BaseMap("Albedo", 2D) = "white" {}
        [MainColor] _BaseColor("Color", Color) = (1,1,1,1)
        _Cutoff("Cutoff", Float) = 1.0
        _BumpScale("Bump Scale", Float) = 1.0
        _BumpMap("Normal Map", 2D) = "bump" {}
        
        [Space]
        _MaskMap("Mask Map", 2D) = "bump" {}
        //_MaskMap2("Mask Map 2", 2D) = "bump" {}
        
        [Space]
        [Header(Metallic)][Space]
        _Roughness ("Roughness",       Range(0,1)) = 0.5
        _Metallic ("Metallic",          Range(0,1)) = 0.0
        
        [Space]
        [Header(Specular)][Space]
        _Specular("Specular",           Range(0,1)) = 0.5
        _SpecularTint("SpeculatTint",   Range(0,1)) =0.5
        /*
        [Space]
        [Header(Sheen)][Space]
        _Sheen("Sheen",                Range(0,1)) = 0
        _SheenTint("SheenTint",         Range(0,1)) = 0.5
        */
        [Space]
        [Header(Clearcoat)][Space]
        _ClearcoatGloss("ClearcoatGloss",Range(0,1)) = 1
        _Clearcoat("Clearcoat",         Range(0,1)) = 1
        
        
        [Space]
        [Header(SSS)][Space]
        _Subsurface("Subsurface",       Range(0,1)) = 0.5
        _SSSThreshold("SSS Threshold",       Range(0,1)) = 0.5
        
        [Space]
        [Header(Translucency)][Space]
        _Translucency("Strength", Range( 0 , 50)) = 1
		_TransNormalDistortion("Normal Distortion", Range( 0 , 1)) = 0.5
		_TransScattering("Scaterring Power", Range( 1 , 50)) = 1
		_TransDirect("Direct", Range( 0 , 1)) = .5
		_TransAmbient("Ambient", Range( 0 , 1)) = 0.2
        _TransShadow("TransShadow",Range(0,1)) = 0.5
        
        [Space]
        [Header(Other)][Space]
        _Occlusion("Occlusion",       Range(0,1)) = 0.5
        _Anisotropic("Anisotropic",     Range(0,1)) = 0
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
            Name "BaseDinesy"
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
            
            #pragma vertex LitDinesyPassVertex
            #pragma fragment LitDinesyPassFragment

            #pragma multi_compile_instancing
            #pragma multi_compile_fog
            
            #define ENABLE_BUMPMAP
            #define ENABLE_BUMPMAP_SCALE
            
            //#include "LitDinesyProperty.hlsl"
            //#include "LitDinesyUtils.hlsl"
            #include "LitDinesyPassForward.hlsl" 
            
            ENDHLSL
        }
        
        //UsePass "Universal Render Pipeline/Lit/ShadowCaster" 
    }
    //CustomEditor "URPToon.LitToonShaderGUI"
}
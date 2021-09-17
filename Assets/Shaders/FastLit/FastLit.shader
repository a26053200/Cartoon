/// <summary>
/// <para>Author: zhengnan </para>
/// <para>Create: 2021年09月07日 星期二 23:29 </para>
/// </summary>
Shader "FastLit/FastLit"
{
    Properties
    {
        [MainColor] _BaseColor("Color", Color) = (1,1,1,1)
        [MainTexture] _BaseMap("Albedo", 2D) = "white" {}
        
        //_BumpScale("Bump Scale", Range(0,2)) = 1.0
        _BumpMap("Normal Map", 2D) = "bump" {}
        //_LUT("LUT", 2D) = "white" {}
        _MaskMap("Mask Map", 2D) = "white" {}
        
        [Space]
        [Header(Base)][Space]
        _Cutoff("Cutoff", Float) = 1.0
        _Alpha("Alpha", Range(0,1)) = 1.0
        _Anisotropic("Anisotropic",     Range(0,1)) = 0
        _Occlusion("Occlusion",       Range(0,2)) = 0.5
        //_SSAO ("SSAO",          Range(0,1)) = 0.0
        
        [Space]
        [Header(PBR)][Space]
        _Diffuse ("Diffuse",          Range(0,1)) = 1
        _Specular ("Specular",          Range(0,1)) = 1
        _Smoothness ("Smoothness",       Range(0,1)) = 0.5
        //_Roughness ("Roughness",       Range(0,1)) = 0.5
        _Metallic ("Metallic",          Range(0,1)) = 0.0
       
        [Space]
        [Toggle(Use SSS)]_UseSSS("Use SSS", Float) = 0
        _Subsurface("Subsurface",       Range(0,1)) = 0.5
        _SubsurfaceRange("Subsurface Range",       Range(0,2)) = 0.5
        _SSSPower("Scaterring Power",       Range(1,50)) = 0.5
        _SSSOffset("Scaterring Offset",       Range(0,1)) = 0.5
        _SSSColor("SSS Color",       Color) = (1,1,1,1)
        
        [Space]
        [Toggle(Use Anisotropic)]_UseAnisotropic("Use Anisotropic", Float) = 0
        _AnisotropicStrength("Strength", Range(0, 1)) = 0
		_Gloss("Gloss", Range(8.0, 256)) = 20
		_Shift("Shift", Range(-1, 1)) = 0
		_ShiftTex("ShiftTex" , 2D) = "white"{}
		//_SpecularColor("Specular Color", Color) = (1,1,1,1)
        
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
            #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
            // -------------------------------------
            //#pragma shader_feature_local_fragment _UseSSS
            //#pragma shader_feature_local_fragment _UseAnisotropic
         
            #define _UseSSS
            #define _UseAnisotropic
            
            #pragma vertex LitDinesyPassVertex
            #pragma fragment LitDinesyPassFragment

            #pragma multi_compile_instancing
            #pragma multi_compile_fog
            
            #include "LitFastPassForward.hlsl" 
            
            ENDHLSL
        }
        
        UsePass "Universal Render Pipeline/Lit/ShadowCaster" 
    }
    //CustomEditor "URPToon.LitToonShaderGUI"
}
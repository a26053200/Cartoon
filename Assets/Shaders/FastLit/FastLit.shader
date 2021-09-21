/// <summary>
/// <para>Author: zhengnan </para>
/// <para>Create: 2021年09月07日 星期二 23:29 </para>
/// </summary>
Shader "FastLit/FastLit"
{
    Properties
    {
        [Toggle(Use Specular Mode)]_UseSpecularMode("Use Specular Mode", Float) = 0
        [MainColor] _BaseColor("Color", Color) = (1,1,1,1)
        [MainTexture] _BaseMap("Albedo", 2D) = "white" {}
        _BumpMap("Normal Map", 2D) = "bump" {}
        _MaskMap("Mask Map", 2D) = "white" {}
        
        //[Space]
        //[Header(Fade)][Space]
        [Toggle(Use Fade)]_UseFade("Use Fade", Float) = 0
        _Fade("Fade", Range(0,1)) = 0.5
        
        //[Space]
        //[Header(Cutoff)][Space]
        [Toggle(Use Cutoff)]_UseCutoff("Use Cutoff", Float) = 0
        _Cutoff("Cutoff", Range(0,1)) = 0.5
        
        //[Space]
        //[Header(Alpha)][Space]
        [Toggle(Use Alpha)]_UseAlpha("Use Alpha", Float) = 0
        _Alpha("Alpha", Range(0,1)) = 1.0
        
        //[Space]
        //[Header(Advanced)][Space]
        [Toggle(Enable Advanced)]_EnableAdvanced("Use Advanced", Float) = 0
        _Diffuse ("Diffuse",            Range(0,2)) = 1
        _Specular ("Specular",          Range(0,2)) = 1
        _Sheen ("Sheen",                Range(0,1)) = 1
        
        //_SSAO ("SSAO",          Range(0,1)) = 0.0
        
        //[Space]
        //[Header(PBR)][Space]
        [Toggle(Receive Shadow)]_ReceiveShadow("Receive Shadow", Float) = 0
        _Occlusion("Occlusion",       Range(0,2)) = 1
        _Metallic ("Metallic",          Range(0,1)) = 0.0
        _SpecularColor("Specular Color",       Color) = (1,1,1,1)
        _Smoothness ("Smoothness",      Range(0,1)) = 0.5
       
        //[Space]
        [Toggle(Use SSS)]_UseSSS("Use SSS", Float) = 0
        _Subsurface("Subsurface",       Range(0,1)) = 0.5
        _CurveFactor("CurveFactor",       Range(0,1)) = 0.5
        _SSSLUT ("SSS LUT", 2D) = "white" {}
        _SubsurfaceRange("Range",       Range(0.001,1)) = 0.5
        //_SSSPower("Scaterring Power",       Range(0.001,10)) = 0.5
        //_SSSOffset("Offset",       Range(0,2)) = 0.5
        //_SSSColor("SSS Color",       Color) = (1,1,1,1)
        
        //[Space]
        [Toggle(Use Anisotropic)]_UseAnisotropic("Use Anisotropic", Float) = 0
        _Anisotropic("Anisotropic",     Range(0,1)) = 0
		_Gloss("Gloss", Range(8.0, 256)) = 20
		_Shift("Shift", Range(-1, 1)) = 0
		_ShiftTex("ShiftTex" , 2D) = "white"{}
		//_SpecularColor("Specular Color", Color) = (1,1,1,1)
        
        [Toggle(Use Rim Light)]_UseRimLight("Use Rim Light", Float) = 0
        _RimColor ("Rim Color", Color) = (1, 1, 1, 1)
        _RimStrength("Rim Strength", Range(0, 2)) = 1
        _RimFresnelMask("Rim Fresnel Mask", Range(0, 2)) = 1
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
            #pragma multi_compile_fragment _ _SCREEN_SPACE_OCCLUSION
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile_fragment _ _SHADOWS_SOFT
            #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
            // -------------------------------------
            
            #pragma shader_feature_local_fragment _UseSpecularMode
            
            #pragma shader_feature_local_fragment _ReceiveShadow
            #pragma shader_feature_local_fragment _EnableAdvanced
            
            #pragma shader_feature_local_fragment _UseFade
            #pragma shader_feature_local_fragment _UseCutoff
            #pragma shader_feature_local_fragment _UseAlpha
            #pragma shader_feature_local_fragment _UseSSS
            #pragma shader_feature_local_fragment _UseAnisotropic
            #pragma shader_feature_local_fragment _UseRimLight
            
            #pragma vertex LitDinesyPassVertex
            #pragma fragment LitDinesyPassFragment

            #pragma multi_compile_instancing
            #pragma multi_compile_fog
            
            #include "LitFastPassForward.hlsl" 
            
            ENDHLSL
        }
        
        //UsePass "Universal Render Pipeline/Lit/ShadowCaster" 
        
        //UsePass "Universal Render Pipeline/Lit/DepthOnly" 
        
        //UsePass "Universal Render Pipeline/Lit/DepthNormals" 
    }
    CustomEditor "URPToon.FastLitShaderGUI"
}
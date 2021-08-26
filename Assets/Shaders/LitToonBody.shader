Shader "LitToon/Avatar/LitToonBody"
{
    Properties
    {
        // Base
        [MainTexture]_BaseMap ("Base Map", 2D) = "white" { }
        _BaseColor ("Base Color", Color) = (0, 0.66, 0.73, 1)
        _LightMap ("Light Map", 2D) = "white" { }
        _RampMap ("Ramp Map", 2D) = "white" { }
        
        [Space]
        [Header(Shadow)][Space]
        _ShadowArea("Shadow Area", Range(0, 1)) = 0.5
        _ShadowSmooth("Shadow Smooth", Range(0, 1)) = 0.5
        _ShadowMultiColor ("Shdaow Color", Color) = (1, 1, 1, 1)
        _DarkShadowArea("Dark Shadow Area", Range(0, 1)) = 0.5
        _DarkShadowSmooth("Dark Shadow Smooth", Range(0, 1)) = 0.5
        _DarkShadowMultiColor ("Dark Shdaow Color", Color) = (1, 1, 1, 1)
        _FixDarkShadow("Fix Dark Shadow", Range(0, 1)) = 0.5
        
        [Space]
        [Header(Specular)][Space]
        _Glossiness("Glossiness", Range(0.01, 256)) = 1
        _SpecularRange("Specular Range", Range(0, 3)) = 0.5
        _SpecularColor ("Shdaow Color", Color) = (1, 1, 1, 1)
        
        [Space]
        [Header(OutLine)][Space]
        _OutlineColor ("Outline Color", Color) = (0, 0, 0, 1)
        _OutlineThickness ("Outline Thickness", Range(0,2)) = 0.5
        [ToggleOff] _UseColor ("UseVertexColor", Float) = 0.0
    }
    SubShader
    {
        Tags { "RenderType" = "Opaque" "RenderPipeline" = "UniversalRenderPipeline" }
        
        HLSLINCLUDE
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Packing.hlsl"
        
        ENDHLSL
        
        Pass
        {
            Name "BaseCel"
            Tags { "LightMode" = "UniversalForward" }
            
            HLSLPROGRAM
            
            #pragma vertex vert
            #pragma fragment frag

            #pragma multi_compile_instancing
            
            #pragma shader_feature _ENABLE_RIM
            #pragma shader_feature _IS_FACE
            
            #define _BODY
            
            #include "ToonLitProperty.hlsl"
            #include "ToonLitCore.hlsl"
            ENDHLSL
        }
        
        //easy outline pass
        
        Pass
        {
            Name "OutLine"
            Cull Front
            ZWrite On
            
            HLSLPROGRAM
            
            #pragma vertex Vertex
            #pragma fragment Fragment
            
            #pragma shader_feature_local_vertex _USESMOOTHNORMAL
            #pragma multi_compile_instancing
            #pragma shader_feature_local _USE_VERTEX_COLOR
            
            #include "URPOutline.hlsl"
            //#include "URPToonOutlinePass.hlsl"
            ENDHLSL
        }
        //this Pass copy from https://github.com/ColinLeung-NiloCat/UnityURPToonLitShaderExample
        /*
        Pass
        {
            Name "ShadowCaster"
            Tags { "LightMode" = "ShadowCaster" }
            
            //we don't care about color, we just write to depth
            ColorMask 0
            
            HLSLPROGRAM
            
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
            #pragma multi_compile _ _ADDITIONAL_LIGHT_SHADOWS
            #pragma multi_compile _ _SHADOWS_SOFT
        
            #pragma vertex ShadowCasterPassVertex
            #pragma fragment ShadowCasterPassFragment
            
            #include "URPShadowCaster.hlsl"
            ENDHLSL
            
        }*/
    }
    //CustomEditor "URPToon.LitToonShaderGUI"
}
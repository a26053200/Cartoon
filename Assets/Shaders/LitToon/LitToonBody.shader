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
        [Header(Rim)][Space]
        //_RimMin("Rim Min", Range(0, 2)) = 1
        //_RimMax("Rim Max", Range(2, 4)) = 3
        _RimOffsetMul("_RimWidth", Range(0.001, 0.1)) = 0.012
        _RimThreshold("_Threshold", Range(0.1, 1)) = 0.1
        _RimColor ("Rim Color", Color) = (1, 1, 1, 1)
        _RimStrength("Rim Strength", Range(0, 1)) = 0.09
        //_FresnelMask("_FresnelMask", Range(0, 1)) = 0.012
        
        [Space]
        [Header(OutLine)][Space]
        _OutlineColor ("Outline Color", Color) = (0, 0, 0, 1)
        _OutlineThickness ("Outline Thickness", Range(0,2)) = 0.5
        _OutlineWidth ("Outline Width", Range(0,2)) = 0.5
        //[ToggleOff] _UseColor ("UseVertexColor", Float) = 0.0
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
            Cull Off
            Tags { "LightMode" = "UniversalForward" }
            
            HLSLPROGRAM
            
            #pragma vertex vert
            #pragma fragment frag

            #pragma multi_compile_instancing
            
            #pragma shader_feature _ENABLE_RIM
            #pragma shader_feature _IS_FACE
            
            #define _RIM
            #define _BODY
            
            #include "ToonLitProperty.hlsl"
            //#include "ToonLitUtils.hlsl"
            #include "ToonLitCore.hlsl"
            ENDHLSL
        }
        /*
        //easy outline pass
        Pass
        {
            Name "OutLine"
            Cull Front
            ZWrite On
            
            HLSLPROGRAM
            
            #pragma vertex VertexOutline
            #pragma fragment FragmentOutline
            
            #pragma shader_feature_local_vertex _USESMOOTHNORMAL
            #pragma multi_compile_instancing
            #pragma shader_feature_local _USE_VERTEX_COLOR
            
            #include "ToonLitPassOutline.hlsl"
            //#include "URPToonOutlinePass.hlsl"
            ENDHLSL
        }
        
        Pass
        {
            Name "DepthOnly"
            Tags{"LightMode" = "DepthOnly"}

            ZWrite On
            ColorMask 0
            Cull[_Cull]

            HLSLPROGRAM
            #pragma exclude_renderers gles gles3 glcore
            #pragma target 4.5

            #pragma vertex DepthOnlyVertex
            #pragma fragment DepthOnlyFragment

            // -------------------------------------
            // Material Keywords
            #pragma shader_feature_local_fragment _ALPHATEST_ON
            #pragma shader_feature_local_fragment _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing
            #pragma multi_compile _ DOTS_INSTANCING_ON

            #include "Packages/com.unity.render-pipelines.universal/Shaders/LitInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/DepthOnlyPass.hlsl"
            ENDHLSL
        }
        
        //this Pass copy from https://github.com/ColinLeung-NiloCat/UnityURPToonLitShaderExample
        
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
        }
        */
    }
    //CustomEditor "URPToon.LitToonShaderGUI"
}
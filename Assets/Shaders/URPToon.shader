Shader "URP/Avatar/Toon"
{
    Properties
    {
        [MainTexture]_BaseMap ("Base Map", 2D) = "white" { }
        _BaseColor ("Base Color", Color) = (0, 0.66, 0.73, 1)
        
        [Header(Shading)]
        _BrightColor ("BrightColor", Color) = (1, 1, 1, 1)
        [HDR]_MiddleColor ("MiddleColor", Color) = (0.8, 0.1, 0.1, 1)
        _DarkColor ("DarkColor", Color) = (0.5, 0.5, 0.5, 1)
        _CelShadeMidPoint ("CelShadeMidPoint", Range(0, 1)) = 0.5
        _CelShadeSmoothness ("CelShadeSmoothness", Range(0, 1)) = 0.1
        [Toggle(_IsFace)] _IsFace ("IsFace", Float) = 0.0
        _HairShadowDistace ("_HairShadowDistance", Float) = 1
        
        [Header(Rim)]
        _RimColor ("RimColor", Color) = (1, 1, 1, 1)
        _RimSmoothness ("RimSmoothness", Range(0, 10)) = 10
        _RimStrength ("RimStrength", Range(0, 1)) = 0.1
        
        //[Header(OutLine)]
        [ToggleOff] _EnableOutline("Enable Outline",Float) = 0.0
        _OutlineColor ("Outline Color", Color) = (0, 0, 0, 1)
        _OutlineThickness ("Outline Thickness", float) = 0.5
        _OutlineWidth ("Outline Width", float) = 0.5
        [ToggleOff] _UseColor ("UseVertexColor", Float) = 0.0
        
        [Header(heightCorrectMask)]
        _HeightCorrectMax ("HeightCorrectMax", float) = 1.6
        _HeightCorrectMin ("HeightCorrectMin", float) = 1.51
    }
    SubShader
    {
        Tags { "RenderType" = "Opaque" "RenderPipeline" = "UniversalRenderPipeline" }
        
        HLSLINCLUDE
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Packing.hlsl"
        /*
        #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
        #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
        #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
        #pragma multi_compile _ _ADDITIONAL_LIGHT_SHADOWS
        #pragma multi_compile _ _SHADOWS_SOFT
        */
        ENDHLSL
        
        Pass
        {
            Name "BaseCel"
            Tags { "LightMode" = "UniversalForward" }
            
            HLSLPROGRAM
            
            #pragma vertex vert
            #pragma fragment frag

            #pragma multi_compile_instancing
            #pragma shader_feature _IsFace
            
            #include "URPToonProperty.hlsl"
            #include "URPToonCore.hlsl"
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
            #pragma shader_feature_local _UseColor
            
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
            #pragma vertex ShadowCasterPassVertex
            #pragma fragment ShadowCasterPassFragment
            
            #include "URPShadowCaster.hlsl"
            ENDHLSL
            
        }*/
    }
    CustomEditor "URPToon.URPToonShaderGUI"
}
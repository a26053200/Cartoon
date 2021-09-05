Shader "URP/Avatar/Toon"
{
    Properties
    {
        [MainTexture]_BaseMap ("Base Map", 2D) = "white" { }
        _BaseColor ("Base Color", Color) = (0, 0.66, 0.73, 1)
        
        [Header(Shading)]
        [HDR]_BrightColor ("BrightColor", Color) = (1, 1, 1, 1)
        [HDR]_MiddleColor ("MiddleColor", Color) = (0.8, 0.1, 0.1, 1)
        [HDR]_DarkColor ("DarkColor", Color) = (0.5, 0.5, 0.5, 1)
        _CelShadeMidPoint ("CelShadeMidPoint", Range(0, 1)) = 0.5
        _CelShadeSmoothness ("CelShadeSmoothness", Range(0, 1)) = 0.1
        
        //[Header(Face)]
        [Toggle(Is Face)] _IsFace ("IsFace", Float) = 0.0
        _HairShadowDistance ("_HairShadowDistance", Float) = 1
        _HeightCorrectMax ("HeightCorrectMax", float) = 1.6
        _HeightCorrectMin ("HeightCorrectMin", float) = 1.51
        
        //[Header(Rim)]
        [Toggle(Enable Rim)]_EnableRim ("Enable Rim", Float) = 0.0
        _RimColor ("RimColor", Color) = (1, 1, 1, 1)
        _RimSmoothness ("RimSmoothness", Range(0, 10)) = 10
        _RimStrength ("RimStrength", Range(0, 1)) = 0.1
        
        [Header(OutLine)]
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
            #pragma shader_feature_local _USE_VERTEX_COLOR
            
            #include "URPOutline.hlsl"
            //#include "URPToonOutlinePass.hlsl"
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
    }
    CustomEditor "URPToon.URPToonShaderGUI"
}
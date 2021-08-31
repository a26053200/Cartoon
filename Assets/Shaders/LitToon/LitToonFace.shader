Shader "LitToon/Avatar/LitToonFace"
{
    Properties
    {
        // Base
        [MainTexture]_BaseMap ("Base Map", 2D) = "white" { }
        _BaseColor ("Base Color", Color) = (0, 0.66, 0.73, 1)
        
        [Space]
        [Header(Face)][Space]
        _FaceShadowMapPow ("Face Shadow Map Pow", Range(0.001, 1.0)) = 0.2
        _FaceShadowOffset ("Face Shadow Offset", Range(-1.0, 1.0)) = 0.0
        _FaceLightMap ("Face Light Map", 2D) = "white" { }
        _FaceShadowColor ("Face Shadow Color", Color) = (1, 1, 1, 1)
        
         [Space]
        [Header(OutLine)][Space]
        _OutlineColor ("Outline Color", Color) = (0, 0, 0, 1)
        _OutlineThickness ("Outline Thickness", Range(0,2)) = 0.5
        _OutlineWidth ("Outline Width", Range(0,2)) = 0.5
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
            
            
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #pragma multi_compile_instancing
            
            #define _FACE
            
            #include "ToonLitProperty.hlsl"
            //#include "ToonLitUtils.hlsl"
            #include "ToonLitCore.hlsl"

            ENDHLSL
        }
        
        //easy outline pass
        Pass
        {
            Name "OutLine"
            Tags { "LightMode" = "UniversalForward" }
            Cull Front
            ZWrite On
            
            HLSLPROGRAM
            
            #pragma vertex VertexOutline
            #pragma fragment FragmentOutline
            
            #define _USESMOOTHNORMAL
            #pragma multi_compile_instancing
            
            #include "ToonLitPassOutline.hlsl"
            ENDHLSL
        }
        
        /*
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
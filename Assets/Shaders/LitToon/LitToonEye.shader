Shader "LitToon/Avatar/LitToonEye"
{
    Properties
    {
        // Base
        [MainTexture]_BaseMap ("Base Map", 2D) = "white" { }
        _BaseColor ("Base Color", Color) = (0, 0.66, 0.73, 1)
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
            
            //#include "ToonLitProperty.hlsl"
            //#include "ToonLitCore.hlsl"
            #include "ToonLitPassTexture.hlsl"
            ENDHLSL
        }
        
        //easy outline pass
        /*
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
        */
        
    }
    //CustomEditor "URPToon.LitToonShaderGUI"
}
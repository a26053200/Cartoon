Shader "PBRToon/Avatar/PBRToonBody"
{
    Properties
    {
        // Base
        [MainTexture] _BaseMap("Albedo (A)", 2D) = "white" {}
        [MainColor] _BaseColor("Color", Color) = (1,1,1,1)
         _Cutoff("_Cutoff (Alpha Cutoff)", Range(0.0, 1.0)) = 0.5
         
        [Space]
        _Mask("Mask R(粗糙度) G(高光区域) B(AO) A(MASK)", 2D) = "white" {}
        
        [Space]
        _BumpMap("Normal Map", 2D) = "bump" {}
        _BumpScale("Scale", Float) = 1.0
        
        [Space]
        [Header(Diffuse)][Space]
        _Threshold("Diffuse Threshold", Range(0, 1)) = 0.5 //0.35
        _Smoothness("Diffuse Smoothness", Range(0, 1)) = 0.5 //0.2,0.5,0.8
        
        [Space]
        [Header(Specular)][Space]
        _Roughness("Roughness", Range(0.001, 1)) = 0
        _SpecularColor("Specular Color", Color) = (1,1,1,1)
        _SpecularSmoothness("Specular Smoothness", Range(0, 2)) = 0.5
        _SpecularBlend("Specular Blend", Range(0, 1)) = 0.5
        
        //_Metallic("Metallic", Range(0.0, 1.0)) = 0.0
        //_OcclusionStrength("Strength", Range(0.0, 1.0)) = 1.0
    }
    SubShader
    {
        Tags { "RenderType" = "Opaque" "Queue" = "Geometry" "RenderPipeline" = "UniversalRenderPipeline" }
        //Tags {"RenderType" = "Transparent" "Queue" = "Transparent" "RenderPipeline" = "UniversalPipeline" }
        //Tags {"RenderType" = "TransparentCutout" "Queue" = "AlphaTest" "RenderPipeline" = "UniversalPipeline" }
        
        HLSLINCLUDE
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Packing.hlsl"
        ENDHLSL
        
        Pass
        {
            Name "BaseCel"
            Tags { "LightMode" = "UniversalForward" }
            //Blend SrcAlpha OneMinusSrcAlpha
            Cull Back
            
            HLSLPROGRAM
            
            #pragma vertex vert
            #pragma fragment frag

            #pragma multi_compile_instancing
            #pragma multi_compile_fog
            
            TEXTURE2D(_BaseMap); SAMPLER(sampler_BaseMap);
            TEXTURE2D(_BumpMap); SAMPLER(sampler_BumpMap);
            TEXTURE2D(_Mask); SAMPLER(sampler_Mask);

            CBUFFER_START(UnityPerMaterial)
                //ST
                float4 _BaseMap_ST, _Mask_ST;
                
                //color
                float4 _BaseColor, _SpecularColor;
                
                //float
                float _Cutoff, _BumpScale, _Threshold, _Smoothness, _Roughness, _SpecularSmoothness, _SpecularBlend;
            CBUFFER_END
            
            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 texcoord : TEXCOORD0;
                float3 color : COLOR;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
            };
            
            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float3 color : COLOR;
                float3 normal : NORMAL;
                float3 uv: TEXCOORD0; // z is fogCoord
                float3 positionWS: TEXCOORD1;
                float3 positionVS: TEXCOORD2;
                float3 viewDirWS: TEXCOORD3;
                float4 TtoW0: TEXCOORD4;
                float4 TtoW1: TEXCOORD5;
                float4 TtoW2: TEXCOORD6;
            };
            
            //梯度漫反射
            // nl           代表灯光方向和法线方向的点乘;
            // threshold    控制漫反射明暗交界线的位置;
            // smoothness   控制明暗过渡的软硬程度，值越大，过渡越自然。值越小，过渡越硬，越偏向于卡通;
            half WrapRampNL(half nl, half threshold, half smoothness)
            {
                nl = nl * 0.5 + 0.5;
                nl = smoothstep(threshold - smoothness * 0.5, threshold + smoothness * 0.5, nl);
                return nl;
            }
            
            //UE4 GGX_Mobile
            half GGX_Mobile(half Roughness, half NoH, half3 H, half3 N)
            {
                half3 NxH = cross(N, H);
                half OneMinusNoHSqr = dot(NxH, NxH);
                half a = Roughness * Roughness;
                half n = NoH * a;
                half p = a / (OneMinusNoHSqr + n * n);
                half d = p * p;
                return saturate(d);//saturateMediump(d);
            }
            
            //UE4 CalcSpecular
            half CalcSpecular(half Roughness, half RoL, half NoH, half3 H, half3 N)
            {
              return (Roughness * 0.25 + 0.25) * GGX_Mobile(Roughness, NoH, H, N);
            }
            
            //
            half StylizedSpecular(half specularTerm, half specSmoothness)
            {
                return smoothstep(specSmoothness * 0.5, 0.5 + specSmoothness * 0.5, specularTerm);
            }

            Varyings vert(Attributes input)
            {
                Varyings output = (Varyings) 0;
     
                VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);
                output.positionCS = vertexInput.positionCS;
                output.positionWS = vertexInput.positionWS;
                output.positionVS = vertexInput.positionVS;
                output.viewDirWS = GetCameraPositionWS() - vertexInput.positionWS;
                
                VertexNormalInputs vertexNormalInput = GetVertexNormalInputs(input.normal.xyz);
                output.normal = vertexNormalInput.normalWS;
                //output.normalVS = TransformWorldToViewDir(vertexNormalInput.normalWS, true);
                
                
                output.uv.xy = TRANSFORM_TEX(input.texcoord, _BaseMap);
                output.uv.z = ComputeFogFactor(vertexInput.positionCS.z);
                
                // 计算世界坐标下的顶点，法线，切线，副法线
                float3 worldPos = output.positionWS;
                half3 worldNormal = output.normal;
                half3 worldTangent = TransformObjectToWorldDir(input.tangent.xyz);
                half3 worldBinormal = cross(worldNormal, worldTangent) * input.tangent.w;
                
                // 计算从切线空间到世界空间的方向变换矩阵
                // 按列摆放得到从切线转世界空间的变换矩阵
                output.TtoW0 = float4(worldTangent.x, worldBinormal.x, worldNormal.x, worldPos.x);
                output.TtoW1 = float4(worldTangent.y, worldBinormal.y, worldNormal.y, worldPos.y);
                output.TtoW2 = float4(worldTangent.z, worldBinormal.z, worldNormal.z, worldPos.z);
                
                output.color = input.color;
                return output;
            }
            
            half4 frag(Varyings input) : SV_Target
            {
                half4 baseMap = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, input.uv.xy);
                half4 maskMap = SAMPLE_TEXTURE2D(_Mask, sampler_Mask, input.uv.xy);
                
                //lighting
                float4 shadowCoord = TransformWorldToShadowCoord(input.positionWS.xyz);
                Light light = GetMainLight(shadowCoord);
                real shadow = light.shadowAttenuation * light.distanceAttenuation;
                
                
                half3 bump = UnpackNormal(SAMPLE_TEXTURE2D(_BumpMap, sampler_BumpMap, input.uv.xy)).rgb;
                bump.xy *= _BumpScale;
                bump.z = sqrt(1.0 - saturate(dot(bump.xy, bump.xy)));
                // 将切线空间转换为世界空间
                bump = normalize(half3(dot(input.TtoW0.xyz, bump), dot(input.TtoW1.xyz, bump), dot(input.TtoW2.xyz, bump)));
                
                half normal = input.normal;
                half3 N = normalize(bump);
                half3 L = normalize(light.direction);
                half3 V = normalize(input.viewDirWS);
                half3 H = normalize(V + L);
                half3 R = -reflect(V, N);
                
                half NdotL = max(0, dot(N, L));
                half RdotL = max(0, dot(R, L));
                half NdotH = max(0, dot(N, H));
                
                //Spec
                half roughness = max(0.01, maskMap.r * _Roughness);
                roughness = sqrt(roughness) * 0.85;
                
                half diffuse = WrapRampNL(NdotL, _Threshold, (1 - roughness) * _Smoothness);//NdotL * 0.5 + 0.5;
                half specularTerm = CalcSpecular(roughness, RdotL, NdotH, H, N);
                
                half styleSpec = StylizedSpecular(specularTerm, _SpecularSmoothness) * (1 / roughness);
                specularTerm = lerp(specularTerm, styleSpec, _SpecularBlend);
                half3 specColor = lerp(0, _SpecularColor * specularTerm, maskMap.g);
                
                /*
                //BlinPhong
                half w = fwidth(NdotH) * _SpecularSmoothness;//_SpecularSmoothness越大，过渡越柔和
                half scale = max(0.0001, _SpecularBlend * 0.01);
                half3 specColor = _SpecularColor * smoothstep(-w, w, NdotH - (1 - scale)) * step(0.0001, scale);
                specColor = lerp(0, specColor, maskMap.r) * maskMap.g;
                */
                half3 finalColor = baseMap.rgb * diffuse * light.color + specColor;
                //debug
                //finalColor.rgb = specColor.rgb;
                //clip(baseMap.a - _Cutoff);
                return half4(finalColor.rgb, 1);
            }
            ENDHLSL
        }
    }
    //CustomEditor "URPToon.LitToonShaderGUI"
}
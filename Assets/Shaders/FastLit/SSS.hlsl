#ifndef SSS_INCLUDED
#define SSS_INCLUDED

float SampleSceneDepth(float2 uv)
{
    return SAMPLE_TEXTURE2D_X(_CameraDepthTexture, sampler_CameraDepthTexture, UnityStereoTransformScreenSpaceTex(uv)).r;
}

inline half3 Saturation(half3 color, half saturation)
{
	float P = sqrt(color.r*color.r*0.3 + color.g*color.g*0.5 + color.b*color.b*0.2);

	color.r = P + (color.r - P) * saturation;
	color.g = P + (color.g - P) * saturation;
	color.b = P + (color.b - P) * saturation;

	return color;
}


float3 FastSubsurfaceScattering(DisneySurfaceData surfaceData, float3 L, float3 N, float3 V, float3 lightCol, float shadowAttenuation)
{
    float3 H = SafeNormalize(L + N * _SSSOffset);
	float sss = pow(max(0, dot(V, -H)), _SSSPower);
    return surfaceData.albedo * sss * _SSSColor.rgb * surfaceData.subsurface;
    /*
    float3 InScatter = pow(saturate(dot(L, -V)), 12) * lerp(3, 0.1, _SubsurfaceRange);
    float3 H = SafeNormalize(L + N * _SSSOffset);
	float NormalContribution = saturate(dot(N, H) * _SubsurfaceRange + 1 - _SubsurfaceRange);
	float BackScatter = surfaceData.occlusion * NormalContribution / (PI * 2);
	float3 sssColor = _SSSColor.rgb * lerp(BackScatter, 1, InScatter);
    return sssColor * surfaceData.subsurface;
    */
}


//Diffuse functions
float3 SSS(float3 diffuseColor)
{
    /*
    float offsetDepth = SampleSceneDepth(uv).r; // _CameraDepthTexture.r = input.positionNDC.z / input.positionNDC.w
    float linearEyeOffsetDepth = 1.0 - LinearEyeDepth(offsetDepth, _ZBufferParams) * _SubsurfaceRange;
    float depth = linearEyeOffsetDepth * linearEyeOffsetDepth;
    //return depth.rrr;
    
    // Approximations for skin scatter LUT
	float x = saturate(NdotL * 0.5 + 0.5);
	float x2 = x * x;
	half3 c1 = saturate((x2 * half3(0.8973, 1.3784, 1.4091) + half3(-0.158, -0.4179, -0.4319)) * x2 + half3(0.0063, 0.0152, 0.0155));
	half c0 = saturate((x2 * 1.4125 - 0.4021) * x2 + 0.013);
	half3 c = lerp(c0.xxx, c1, 1.0 - _SubsurfaceRange);
	float sss = pow(saturate(dot(V, H)), _SSSPower);
	return sss * lightCol * c * _SSSColor.rgb * _SSSColor.rgb * PI;
	*/
    //计算正面和背面此表面散射
    /*
    float3 frontLitDir = normalize(N * _SubsurfaceRange - L);
    float3 backLitDir = normalize(N * _SSSOffset + L);
    float frontSSS = saturate(dot(V, -frontLitDir));
    float backSSS = saturate(dot(V, -backLitDir));
    float result = saturate(frontSSS * _CurveFactor + backSSS);
    float3 SSSCol = lerp(_SSSColor.rgb, lightCol, pow(result, _SSSPower));//saturate(pow(result, _SSSPower))).rgb * result;
    return SSSCol;
    */
    /*
    
    float VdotL = saturate(dot(V, -L));//pow(saturate(dot(V, -L)), _SSSPower);
		
    half3 lightAtten = lightCol * _SubsurfaceRange;
    half3 transComponent = lerp(VdotL + surfaceData.albedo, _SSSColor.rgb * _SSSOffset, VdotL);	
    return VdotL.rrr;
    transComponent += (1 - NdotL) * _SSSColor.rgb * lightCol * _CurveFactor * 0.5;
    half3 backLight = lightCol  * NdotL + lightAtten * transComponent;
	return transComponent;
	
    
	float sss = pow(saturate(dot(V, -H)), _SSSPower);
	return _SSSColor.rgb * sss * sss* surfaceData.subsurface;
	*/
	/*
	float s1 = pow(max(0, dot(N, -L)), _SubsurfaceRange);
	float s2 = pow(max(0, dot(N, V)) * 0.5 + 0.5, _SSSPower);
    return (_SSSColor.rgb + 0.8 / 1.8) * s1 * s2;
    */
    
    /*
    float3 InScatter = pow(saturate(dot(L, -V)), 12) * lerp(3, 0.1, _SubsurfaceRange);
    float3 H = SafeNormalize(L + N * _SSSOffset);
	float NormalContribution = saturate(dot(N, H) * _SubsurfaceRange + 1 - _SubsurfaceRange);
	float BackScatter = surfaceData.occlusion * NormalContribution / (PI * 2);
	float3 sssColor = _SSSColor.rgb * lerp(BackScatter, 1, InScatter);
    return sssColor * surfaceData.subsurface;
    */
    return 1;
}

#endif

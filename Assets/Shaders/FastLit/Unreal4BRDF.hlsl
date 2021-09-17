#ifndef UNREAL4_BRDF_INCLUDED
#define UNREAL4_BRDF_INCLUDED

//////////////////////////////
//		 Unreal4 BRDF		//
//////////////////////////////

#define EPSILON 0.000000000001f
//====================
// Utils
//====================

float Pow5(float x)
{
    return x*x*x*x*x;
}

float Square(float x)
{
 return x * x;
}

//====================
// Diffuse
//====================
float3 Diffuse_Lambert(float3 DiffuseColor)
{
	return DiffuseColor * (1 / PI);
}

float3 Diffuse_Burley( float3 DiffuseColor, float Roughness, float NoV, float NoL, float VoH )
{
	float FD90 = 0.5 + 2 * VoH * VoH * Roughness;
	float FdV = 1 + (FD90 - 1) * Pow5( 1 - NoV );
	float FdL = 1 + (FD90 - 1) * Pow5( 1 - NoL );
	return DiffuseColor * ( (1 / PI) * FdV * FdL );
}

float3 Diffuse_OrenNayar( float3 DiffuseColor, float Roughness, float NoV, float NoL, float VoH )
{
	float a = Roughness * Roughness;
	float s = a;// / ( 1.29 + 0.5 * a );
	float s2 = s * s;
	float VoL = 2 * VoH * VoH - 1;		// double angle identity
	float Cosri = VoL - NoV * NoL;
	float C1 = 1 - 0.5 * s2 / (s2 + 0.33);
	float C2 = 0.45 * s2 / (s2 + 0.09) * Cosri * ( Cosri >= 0 ? rcp( max( NoL, NoV ) ) : 1 );
	return DiffuseColor / PI * ( C1 + C2 ) * ( 1 + Roughness * 0.5 );
}

inline float3 F_LambertDiffuse(float3 kd)
{
    return kd / PI;
}
//====================
// Specular
//====================
float D_GGX1( float Roughness, float NoH )
{
	float a = Roughness * Roughness;
	float a2 = a * a;
	float d = ( NoH * a2 - NoH ) * NoH + 1;	// 2 mad
	return a2 / ( PI*d*d );					// 4 mul, 1 rcp
}
/*
float D_Blinn( float Roughness, float NoH )
{
	float a = Roughness * Roughness;
	float a2 = a * a;
	float n = 2 / a2 - 2;
	return (n+2) / (2*PI) * PhongShadingPow( NoH, n );		// 1 mad, 1 exp, 1 mul, 1 log
}
*/
// Anisotropic 
float D_GGXaniso( float RoughnessX, float RoughnessY, float NoH, float3 H, float3 X, float3 Y )
{
	float ax = RoughnessX * RoughnessX;
	float ay = RoughnessY * RoughnessY;
	float XoH = dot( X, H );
	float YoH = dot( Y, H );
	float d = XoH*XoH / (ax*ax) + YoH*YoH / (ay*ay) + NoH*NoH;
	return 1 / ( PI * ax*ay * d*d );
}

// Trowbridge-Reitz GGX Distribution /UE4采用算法
inline float NormalDistributionGGX(float3 N, float3 H, float roughness)
{	
	// more: http://reedbeta.com/blog/hows-the-ndf-really-defined/
	// NDF_GGXTR(N, H, roughness) = roughness^2 / ( PI * ( dot(N, H))^2 * (roughness^2 - 1) + 1 )^2
	const float a = roughness * roughness;
	const float a2 = a * a;
	const float nh2 = pow(max(dot(N, H), 0), 2);
	const float denom = (PI * pow((nh2 * (a2 - 1.0f) + 1.0f), 2));
	if (denom < EPSILON) return 1.0f;
#if 0
	return min(a2 / denom, 10);
#else
	return a2 / denom;
#endif
}

//====================
// Fresnel UE4采用了Schlick的近似值计算方法 
//====================
float3 F_Schlick1( float3 SpecularColor, float VoH )
{
	float Fc = Pow5( 1 - VoH );					// 1 sub, 3 mul
	//return Fc + (1 - Fc) * SpecularColor;		// 1 add, 3 mad

	// Anything less than 2% is physically impossible and is instead considered to be shadowing
	return saturate( 50.0 * SpecularColor.g ) * Fc + (1 - Fc) * SpecularColor;
}

float3 F_Fresnel( float3 SpecularColor, float VoH )
{
	float3 SpecularColorSqrt = sqrt( clamp( float3(0, 0, 0), float3(0.99, 0.99, 0.99), SpecularColor ) );
	float3 n = ( 1 + SpecularColorSqrt ) / ( 1 - SpecularColorSqrt );
	float3 g = sqrt( n*n + VoH*VoH - 1 );
	return 0.5 * Square( (g - VoH) / (g + VoH) ) * ( 1 + Square( ((g+VoH)*VoH - 1) / ((g-VoH)*VoH + 1) ) );
}

inline float3 Fresnel_UE4(float3 N, float3 V, float3 H, float3 F0)
{
	return F0 + (float3(1, 1, 1) - F0) * pow(2, ((-5.55473) * dot(V, H) - 6.98316) * dot(V, H));
}

//====================
// G 几何衰减因子
//====================
float G_Vis_Schlick( float Roughness, float NoV, float NoL )
{
	float k = Square( Roughness ) * 0.5;
	float Vis_SchlickV = NoV * (1 - k) + k;
	float Vis_SchlickL = NoL * (1 - k) + k;
	return 0.25 / ( Vis_SchlickV * Vis_SchlickL );
}

float G_Vis_Kelemen( float VoH )
{
	// constant to prevent NaN
	return rcp( 4 * VoH * VoH + 1e-5);
}

inline float Geometry_Smiths_SchlickGGX(float3 N, float3 V, float roughness)
{	
	// G_ShclickGGX(N, V, k) = ( dot(N,V) ) / ( dot(N,V)*(1-k) + k )

	//				for direct lighting or IBL
	// k_direct	 = (roughness + 1)^2 / 8
	// k_IBL	 = roughness^2 / 2
	//
	const float k = pow((roughness + 1.0f), 2) / 8.0f;
	const float NV = max(0.0f, dot(N, V));
	const float denom = (NV * (1.0f - k) + k) + 0.0001f;
	//if (denom < EPSILON) return 1.0f;
	return NV / denom;
}

// Smith's Schlick-GGX for Direct Lighting (non-IBL)
inline float GeometrySmithsSchlickGGX(float3 normal, float3 w, float roughness)
{
    // describes self shadowing of geometry
    //
    // G_ShclickGGX(N, V, k) = ( dot(N,V) ) / ( dot(N,V)*(1-k) + k )
    //
    // k         :    remapping of roughness based on wheter we're using geometry function 
    //                for direct lighting or IBL
    // k_direct     = (roughness + 1)^2 / 8
    // k_IBL     = roughness^2 / 2
    //
    const float k = pow((roughness + 1.0f), 2) / 8.0f;
    const float nv = max(0.0f, dot(normal, w));
    const float denom = (nv * (1.0f - k) + k) + 0.0001f;
    if (denom < EPSILON)
        return 1.0f;
    return nv / denom;
}

inline float Geometry(float3 normal, float3 wi, float3 wo, float roughness)
{
    // essentially a multiplier [0, 1] measuring microfacet shadowing
    return GeometrySmithsSchlickGGX(normal, wi, roughness) * GeometrySmithsSchlickGGX(normal, wo, roughness);
}

float3 Unreal4BRDF(BRDFData brdfData, DisneySurfaceData surfaceData, float3 L, float3 V, float3 N, float3 X, float3 Y, float3 lightColor)
{ 
    float3 H = SafeNormalize(L + V);
    
    float NdotL = saturate(dot(N, L));
    float NdotV = saturate(dot(N, V));
    float NdotH = saturate(dot(N, H));
    float LdotH = saturate(dot(L, H));
    float VdotH = saturate(dot(V, H));
    
    float3 Wi = -L;
    float3 Wo = -V;
    
    float3 albedo = surfaceData.albedo;
    float roughness = surfaceData.roughness;
    float metallic = surfaceData.metallic;
    // Diffuse
    float3 diffuse = Diffuse_Lambert(surfaceData.albedo);
    //float3 diffuse = Diffuse_Burley(surfaceData.albedo, brdfData.roughness, NdotV, NdotL, VdotH);//( float3 DiffuseColor, float Roughness, float NoV, float NoL, float VoH )
    
    // D(h) 法线分布函数（NDF）
    // F(v,h) 菲尼尔方程 （Fresnel）
    // G(l,v) 几何衰减因子 (Geometrial Attenuation Factor)
    
    //float D = D_GGX1(brdfData.roughness, NdotH);
    //float D = D_Blinn(brdfData.roughness, NdotH);
    //float D = D_GGXaniso(brdfData.roughness, brdfData.roughness, NdotH, H, X, Y);
    //float D = NormalDistributionGGX(N, H, roughness);
    
    float3 F0 = lerp(float3(0.04f, 0.04f, 0.04f), albedo, metallic);
    
    //float F = F_Schlick(surfaceData.specularColor, VdotH);
    //float F = F_Fresnel(surfaceData.specularColor, VdotH);
    float3 F = Fresnel_UE4(N, V, H, F0);
    
    //float G = G_Vis_Schlick(brdfData.roughness, NdotV, NdotL);
    //float G = G_Vis_Kelemen(VdotH);
    float  G   = Geometry(N, Wo, Wi, roughness);
    
    
    float  NDF = NormalDistributionGGX(N, H, roughness);
    float  denom = (4.0f * max(0.0f, dot(Wo, N)) * max(0.0f, dot(Wi, N))) + 0.0001f;
    
    //Unreal4 BRDF
    float3 SpecularResult = NDF * F * G / denom;
    
    float3 kD = (float3(1, 1, 1) - F) * (1.0f - metallic) * albedo;
	float3 DiffuseResult = F_LambertDiffuse(kD);
    
    //Cook-Torrance模型BRDF
    //float3 SpecularResult = (D * G * F * 0.25) / (NdotV * NdotL);
    
    //直接光照部分结果
    //float3 SpecularResult = SpecularResult * NdotL * PI;// * lightColor * NdotL * UNITY_PI;
    //float3 DiffuseResult = diffuse * NdotL;
    float3 DirectLightResult = DiffuseResult + SpecularResult;
    
    return DirectLightResult;
}

#endif

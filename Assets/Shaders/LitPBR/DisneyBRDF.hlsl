/*

# Copyright Disney Enterprises, Inc.  All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License
# and the following modification to it: Section 6 Trademarks.
# deleted and replaced with:
#
# 6. Trademarks. This License does not grant permission to use the
# trade names, trademarks, service marks, or product names of the
# Licensor and its affiliates, except as required for reproducing
# the content of the NOTICE file.
#
# You may obtain a copy of the License at
# http://www.apache.org/licenses/LICENSE-2.0


# variables go here...
# [type] [name] [min val] [max val] [default val]
::begin parameters
color baseColor .82 .67 .16
float metallic 0 1 0
float subsurface 0 1 0
float specular 0 1 .5
float roughness 0 1 .5
float specularTint 0 1 0
float anisotropic 0 1 0
float sheen 0 1 0
float sheenTint 0 1 .5
float clearcoat 0 1 0
float clearcoatGloss 0 1 1
::end parameters
*/

#define PI  3.14159265358979323846

float sqr(float x) 
{ 
    return x * x; 
}

float SchlickFresnel(float u)
{
    float m = clamp(1 - u, 0, 1);
    float m2 = m * m;
    return m2*m2*m; // pow(m,5)
}

float GTR1(float NdotH, float a)
{
    if (a >= 1) 
        return 1 / PI;
    float a2 = a*a;
    float t = 1 + (a2-1)*NdotH*NdotH;
    return (a2-1) / (PI*log(a2)*t);
}

float GTR2(float NdotH, float a)
{
    float a2 = a*a;
    float t = 1 + (a2-1)*NdotH*NdotH;
    return a2 / (PI * t*t);
}

float GTR2_aniso(float NdotH, float HdotX, float HdotY, float ax, float ay)
{
    return 1 / (PI * ax*ay * sqr( sqr(HdotX/ax) + sqr(HdotY/ay) + NdotH*NdotH ));
}

float smithG_GGX(float NdotV, float alphaG)
{
    float a = alphaG*alphaG;
    float b = NdotV*NdotV;
    return 1 / (NdotV + sqrt(a + b - a*b));
}

float smithG_GGX_aniso(float NdotV, float VdotX, float VdotY, float ax, float ay)
{
    return 1 / (NdotV + sqrt( sqr(VdotX*ax) + sqr(VdotY*ay) + sqr(NdotV) ));
}

float3 mon2lin(float3 x)
{
    return float3(pow(x[0], 2.2), pow(x[1], 2.2), pow(x[2], 2.2));
}


/*
basesecolor：半球反射比中反射到次表面散射的那一部分比例（去掉表面反射）
Subsurface： 控制次表面散射的形状
Metallic  0纯次表面散射（绝缘体） 1纯fresnel反射（金属） 在两种模型之间的线性过渡
Specular 高光反射的强度 其实是被用来计算F(0)
Specular tint 对specular的颜色偏移
Roughness：粗糙度，对diiff和specular都有影响
Anisotropic 各项异性程度 控制高光的方向比（从0各项同性到1最大的各项异性）
Sheen：for cloth，即对回射的增强，前面说织物的grazing 回射要强一些
Clearcoat：第二层高光分布
clearcoatGloss ：控制clearcoat的gloss
*/
float3 DisneyBRDF( float3 L, float3 V, float3 N, float3 X, float3 Y, 
            float3 baseColor,
            float metallic, float roughness, 
            float specular, float3 specularTint, 
            float sheen, float3 sheenTint,
            float clearcoat, float clearcoatGloss,
            float subsurface, float anisotropic)
{
    float NdotL = dot(N,L);
    float NdotV = dot(N,V);
    if (NdotL < 0 || NdotV < 0) 
        return float(0);

    float3 H = normalize(L+V);
    float NdotH = dot(N,H);
    float LdotH = dot(L,H);

    float3 Cdlin = baseColor;//mon2lin(baseColor);
    float Cdlum = 1;//0.3 * Cdlin[0] + 0.6 * Cdlin[1]  + 0.1 * Cdlin[2]; // luminance approx.
    //return baseColor * Cdlum;
    
    float3 Ctint = Cdlum > 0 ? Cdlin/Cdlum : float3(1, 1, 1); // normalize lum. to isolate hue+sat
    float3 Cspec0 = lerp(specular * 0.08 * lerp(float3(1, 1, 1), Ctint, specularTint), Cdlin, metallic);
    float3 Csheen = lerp(float3(1, 1, 1), Ctint, sheenTint);

    return Cdlin;
    //return Cspec0;
    //return Csheen;
    // Diffuse fresnel - go from 1 at normal incidence to .5 at grazing
    // and mix in diffuse retro-reflection based on roughness
    float FL = SchlickFresnel(NdotL), FV = SchlickFresnel(NdotV);
    float Fd90 = 0.5 + 2 * LdotH*LdotH * roughness;
    float Fd = lerp(1.0, Fd90, FL) * lerp(1.0, Fd90, FV);

    // Based on Hanrahan-Krueger brdf approximation of isotropic bssrdf
    // 1.25 scale is used to (roughly) preserve albedo
    // Fss90 used to "flatten" retroreflection based on roughness
    float Fss90 = LdotH*LdotH*roughness;
    float Fss = lerp(1.0, Fss90, FL) * lerp(1.0, Fss90, FV);
    float ss = 1.25 * (Fss * (1 / (NdotL + NdotV) - .5) + .5);

    // specular
    float aspect = sqrt(1-anisotropic*.9);
    float ax = max(0.001, sqr(roughness) / aspect);
    float ay = max(0.001, sqr(roughness) * aspect);
    float Ds = GTR2_aniso(NdotH, dot(H, X), dot(H, Y), ax, ay);
    float FH = SchlickFresnel(LdotH);
    float3 Fs = lerp(Cspec0, float3(1,1,1), FH);
    float Gs;
    Gs  = smithG_GGX_aniso(NdotL, dot(L, X), dot(L, Y), ax, ay);
    Gs *= smithG_GGX_aniso(NdotV, dot(V, X), dot(V, Y), ax, ay);

    // sheen
    float3 Fsheen = FH * sheen * Csheen;

    // clearcoat (ior = 1.5 -> F0 = 0.04)
    float Dr = GTR1(NdotH, lerp(.1,.001,clearcoatGloss));
    float Fr = lerp(.04, 1.0, FH);
    float Gr = smithG_GGX(NdotL, .25) * smithG_GGX(NdotV, .25);

    return ((1/PI) * lerp(Fd, ss, subsurface) * Cdlin + Fsheen)
        * (1-metallic)
        + Gs*Fs*Ds + .25*clearcoat*Gr*Fr*Dr;
}


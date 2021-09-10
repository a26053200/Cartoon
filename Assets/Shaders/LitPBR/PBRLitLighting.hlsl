/// <summary>
/// <para>Author: zhengnan </para>
/// <para>Create: 2021年09月07日 星期二 23:29 </para>
/// </summary>

#ifndef PBR_LIT_LIGHTING
#define PBR_LIT_LIGHTING

struct PBRSurfaceData
{
    half3 albedo;
    half3 specular;
    half  metallic;
    half roughness;
    half  smoothness;
    //half3 normalTS;
    half3 emission;
    half  occlusion;
    half  alpha;
    half  clearCoatMask;
    half  clearCoatSmoothness;
};


#endif
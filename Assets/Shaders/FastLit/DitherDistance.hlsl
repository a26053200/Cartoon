/// <summary>
/// <para>Author: zhengnan </para>
/// <para>Create: 2021年09月07日 星期二 23:29 </para>
/// </summary>

#ifndef DITHER_DISTANCE
#define DITHER_DISTANCE

#include "LitFastInputs.hlsl"

#define THRESHOLD_MATRIX float4x4(1.0/17.0, 9.0/17.0, 3.0/17.0, 11.0/17.0,    13.0/17.0, 5.0/17.0, 15.0/17.0, 7.0/17.0,    4.0/17.0, 12.0/17.0, 2.0/17.0, 10.0/17.0,    16.0/17.0, 8.0/17.0, 14.0/17.0, 6.0/17.0)
#define ROW_ACCESS float4x4(1,0,0,0, 0,1,0,0, 0,0,1,0, 0,0,0,1)

void PerformDither(Varyings input, float fade)
{
	float2 pos = input.positionSS.xy / input.positionSS.w;
	pos *= _ScreenParams.xy;
	float distanceValue = 1 - length(_WorldSpaceCameraPos.xyz - input.positionWS.xyz) * fade;
	clip(distanceValue - THRESHOLD_MATRIX[fmod(pos.x, 4)] * ROW_ACCESS[fmod(pos.y, 4)]);
}

#endif
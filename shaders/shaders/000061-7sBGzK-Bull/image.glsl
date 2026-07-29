// Image (image) — Bull by EvilRyu
// https://www.shadertoy.com/view/7sBGzK

// Created by evilryu
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

// PC 4k exe graphics entry of Revision 2021
// A more verbosed version
// Split to more passes just for reducing some compile time here

// FXAA pass
#define REDUCE_MUL (1. / 8.)
#define REDUCE_MIN (1. / 128.)
#define INTENSITY 3.1

float rgb2luma(vec4 col)
{
	return col.y *(.587 / .299) + col.x;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
	vec2 uv = fragCoord / iResolution.xy;
	vec2 eps = 1. / iResolution.xy;

	float topLeft   = rgb2luma(texture(iChannel0, uv + vec2(-eps.x, eps.y)));
	float topRight  = rgb2luma(texture(iChannel0, uv + eps.xy));
	float downLeft  = rgb2luma(texture(iChannel0, uv - eps.xy));
	float downRight = rgb2luma(texture(iChannel0, uv + vec2(eps.x, -eps.y)));
	float center    = rgb2luma(texture(iChannel0, uv));

	vec2 dir        = vec2((topLeft + topRight) - (downLeft + downRight),
		                  (downLeft + topLeft) - (downRight + topRight));
	float dirReduce = max((downLeft + downRight + topLeft + topRight) * REDUCE_MUL * 0.25, REDUCE_MIN);
	float dirMin    = 1. / (min(abs(dir.x), abs(dir.y)) + dirReduce);
	dir             = min(vec2(INTENSITY), max(-vec2(INTENSITY), dir * dirMin)) * eps.xy;

	vec4 colA       = (texture(iChannel0, uv - .166667 * dir) + texture(iChannel0, uv + .166667 *dir)) *.5;
	vec4 colB       = colA *.5 + .25 * (texture(iChannel0, uv - .5 * dir) + texture(iChannel0, uv + .5 * dir));
	float LumB = rgb2luma(colB);

	if (LumB < min(center, min(min(downLeft, downRight), min(topLeft, topRight))) ||
		LumB > max(center, max(max(downLeft, downRight), max(topLeft, topRight))))
		fragColor = colA;
	else
		fragColor = colB;
}
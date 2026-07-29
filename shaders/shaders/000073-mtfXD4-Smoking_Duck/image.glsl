// Image (image) — Smoking Duck by xjorma
// https://www.shadertoy.com/view/mtfXD4

// Created by David Gallardo - xjorma/2023
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0


const int bloomKernel = 5;

vec3 aces_tonemap(vec3 color){	
	mat3 m1 = mat3(
        0.59719, 0.07600, 0.02840,
        0.35458, 0.90834, 0.13383,
        0.04823, 0.01566, 0.83777
	);
	mat3 m2 = mat3(
        1.60475, -0.10208, -0.00327,
        -0.53108,  1.10813, -0.07276,
        -0.07367, -0.00605,  1.07602
	);
	vec3 v = m1 * color;    
	vec3 a = v * (v + 0.0245786) - 0.000090537;
	vec3 b = v * (0.983729 * v + 0.4329510) + 0.238081;
	return pow(clamp(m2 * (a / b), 0.0, 1.0), vec3(1.0 / 2.2));	
}

// No miracle can be done in only one pass.
vec3 Bloom( in vec2 uv, int radius, float lod)
{
    float scale = pow(2.0, lod);
    vec3  bloom = vec3(0);
	for (int x = -radius; x <= radius; x++)
	{
		for (int y = -radius; y <= radius; y++)
		{
            vec2 off = vec2(x, y);
            vec2  v = vec2(off) / float(radius);
            float w = exp(-4.0  * (dot(v, v)));
            //float c = dot(texture(iChannel1, (uv + off * scale) / iResolution.xy, lod).rgb, vec3(1.0 / 3.0));
            float c = dot(texelFetch(iChannel1, ivec2(uv / scale + off), int(lod)).rgb, vec3(1.0 / 3.0));
            bloom += pow(c, 5.0) * w;
		}
	}
    return bloom / (0.25 * float(radius * radius) * pi);   // Gaussian integral
}


void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec3 c = texelFetch(iChannel1, ivec2(fragCoord), 0).rgb;
    
    float w = 0.5;
    vec3 b = vec3(0);
    for(int lod = 0; lod < 4; lod++)
    {
        b += Bloom(fragCoord, bloomKernel, float(lod)) * w;
        w *= 0.54;
    }
    c += b;
    fragColor = vec4(aces_tonemap(c), 1.0);
}


// Image (image) — Fractal Texturing by Xor
// https://www.shadertoy.com/view/mds3R4

/*
    "Fractal Texturing" by @XorDev
    
    While creating a 3D game (https://twitter.com/XorDev/status/1578947873550389248),
    I came across a problem with my texture quality. I needed something that looked good up close
    or far away. That's when I developed what I call "fractal texturing". I'm sure it's been done
    before, but it's new to me and I thought it was quite neat so I'm sharing it here.

    The concept is quite simple:
    Instead of sampling a texture at one scale for all pixels, we'll sample at a different scale
    depending on the pixel's depth. Then by blending smoothly between the scales, we can produce
    a consistent level of detail. This isn't perfect for all textures (e.g. struggles with bricks)
    but it's perfect for many natural textures like dirt or grass and works well for my needs.
    Maybe you'll find a use for it also!
    
    Tutorial: https://mini.gmshaders.com/p/gm-shaders-mini-fractal-texturing-1408552
*/

//Samples at three scales, interpolating between them
vec4 fractal_texture(sampler2D tex, vec2 uv, float depth)
{
    //Find the pixel level of detail
	float LOD = log(depth);
    //Round LOD down
	float LOD_floor = floor(LOD);
    //Compute the fract part for interpolating
	float LOD_fract = LOD - LOD_floor;
	
    //Compute scaled uvs
	vec2 uv1 = uv / exp(LOD_floor - 1.0);
	vec2 uv2 = uv / exp(LOD_floor + 0.0);
	vec2 uv3 = uv / exp(LOD_floor + 1.0);
	
    //Sample at 3 scales
	vec4 tex0 = texture(tex, uv1);
	vec4 tex1 = texture(tex, uv2);
	vec4 tex2 = texture(tex, uv3);
    
    //Blend samples together
	return (tex1 + mix(tex0, tex2, LOD_fract)) * 0.5;
}
//Samples at three scales, interpolating between them (with mipmapping)
vec4 fractal_texture_mip(sampler2D tex, vec2 uv, float depth)
{
	//Find the pixel level of detail
	float LOD = log(depth);
    //Round LOD down
	float LOD_floor = floor(LOD);
    //Compute the fract part for interpolating
	float LOD_fract = LOD - LOD_floor;
	
	//Compute scaled uvs
	vec2 uv1 = uv / exp(LOD_floor - 1.0);
	vec2 uv2 = uv / exp(LOD_floor + 0.0);
	vec2 uv3 = uv / exp(LOD_floor + 1.0);
    
    //Compute continous derivitives
    vec2 dx = dFdx(uv) / depth * exp(1.0);
    vec2 dy = dFdy(uv) / depth * exp(1.0);
	
    //Sample at 3 scales
	vec4 tex0 = textureGrad(tex, uv1, dx, dy);
	vec4 tex1 = textureGrad(tex, uv2, dx, dy);
	vec4 tex2 = textureGrad(tex, uv3, dx, dy);
    
    //Blend samples together
	return (tex1 + mix(tex0, tex2, LOD_fract)) * 0.5;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    //Center coordinates
    vec2 uv = fragCoord/iResolution.xy-0.5;

    //Compute perspective
    float perspective = 1.0/abs(5.0-uv.y*8.0);
    //Scale in and out
    float scale = exp(cos(iTime*0.5)*2.5);
    
    //Compute perspective coordinates
    vec2 coords = uv * perspective * scale;
    //Add scrolling offset
    coords.x += (iTime+sin(iTime*0.5)/0.5)/5e1;
    
    //Compute pixel depth
    float depth = length(vec3(uv, 1)) * scale * perspective;
    //Scale window height
    depth *= 1e3 / iResolution.y;
    
    //Left: Regular mipmapping for comparison
    vec4 tex0 = texture(iChannel0, coords*4.0);
    //Right: Fractal Texturing
    vec4 tex1 = fractal_texture_mip(iChannel0, coords, depth);
    
    //Pick texture for each side
    vec4 col = (uv.x<0.0) ? tex0 : tex1;
    //Add light at the top
    col += 0.6*perspective;
    //Add border between textures
    col *= smoothstep(0.0, 3.0, abs(uv.x) * iResolution.x);
    
    //Output results
    fragColor = col;
}
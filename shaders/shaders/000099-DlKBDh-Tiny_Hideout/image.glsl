// Image (image) — Tiny Hideout by _pwd_
// https://www.shadertoy.com/view/DlKBDh



//
//
// Tiny Hideout  
//
// Short before upcoming xmas I decided to start a little diorama-series as practise and finger exercise. 
// The reference I used for the cabin is pretty naive -> (https://dasprinzip.com/tinker/cabin.png), but
// fits well for my purpose, of working it all out in here.
//
// More to come the next weeks...
//
//
//
// This shader shall exist in its/this form on shadertoy.com only 
// You shall not use this shader in any commercial or non-commercial product, website or project. 
// This shader is not for sale nor can´t be minted (ecofriendly or not) as NFT.
//
//
//
//
//
//
//
// Related examples
//
// Athibaul´s distress flares:
// https://www.shadertoy.com/view/3dGyRc
//
// gaz´s night circuit
// https://www.shadertoy.com/view/tdyBR1
//
// // Gallo´s green field:
// https://www.shadertoy.com/view/7dSGW1
//
// IQ´s article for sure
// https://iquilezles.org/articles/distfunctions/
//  
//
//



vec3 flareCol = vec3(0.15, 1.0, 0.4);

float noise(float x)
{
    return 2.*textureLod(iChannel0, vec2(x+0.5,0)/256., 0.).r-1.;
}

float fbm1D(float x)
{
    return noise(x)*0.5 + noise(2.*x)*0.25 + noise(4.*x)*0.125;
}

float intensityAtTime(float t)
{
    return fbm1D(t*3.)*0.5 + 0.5;
}

float ligIntensity(float t)
{
    return exp(6.*(intensityAtTime(t)-0.5));
}


vec3 flareColor(vec2 p, float time, float dmin)
{
    // Hexagonal shape
    vec2 q = abs(p);
    vec2 n = vec2(-sqrt(3.)/2., 0.5);
    q = dot(q,n) > 0. ? reflect(q,n) : q;
    float d = dot(q,n*vec2(-1,1));
    float intensity = ligIntensity(time) / (1.+abs(p.y));
    return flareCol * pow(d+dmin, -2.) * 0.005 * intensity;
}

vec3 bokeh(vec2 p, float t, float smoo)
{
    float bok = smoothstep(0.5+smoo,0.5-smoo,length(p))
        * (0.5+smoothstep(0.0,0.5, length(p)));
    return bok * 0.01 * flareCol * ligIntensity(t);
}

vec3 bokeh2(vec2 p, float t, float smoo)
{
    float bok = smoothstep(0.5+smoo,0.5-smoo,length(p));
    return bok * 0.01 * flareCol * ligIntensity(t);
}

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

vec3 bloomTile(float lod, vec2 offset, vec2 uv)
{
    return textureLod(iChannel1, uv * exp2(-lod) + offset, 0.0).rgb;
}

vec3 getBloom(vec2 uv)
{
    vec3 blur = vec3(0.0);
    vec2 lOffsetFix = vec2(0.00025, 0.0005);
    blur = pow(bloomTile(2., vec2(0.0, 0.0) + lOffsetFix, uv),vec3(2.2))       	   	+ blur;
    blur = pow(bloomTile(3., vec2(0.3, 0.0) + lOffsetFix, uv),vec3(2.2)) * 1.3        + blur;
    blur = pow(bloomTile(4., vec2(0.0, 0.3) + lOffsetFix, uv),vec3(2.2)) * 1.6        + blur;
    blur = pow(bloomTile(5., vec2(0.1, 0.3) + lOffsetFix, uv),vec3(2.2)) * 1.9 	   	+ blur;
    blur = pow(bloomTile(6., vec2(0.2, 0.3) + lOffsetFix, uv),vec3(2.2)) * 2.2 	   	+ blur;

    return blur * BLOOM_RANGE;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord.xy/iResolution.xy;
	
    vec2 p = (fragCoord*1.5-iResolution.xy)/iResolution.y;
    p.y -= 0.35;
    p.x -= 0.45;
    float camTime = iTime;
    float time = iTime;
    vec2 q = p + vec2(fbm1D(camTime+50.), fbm1D(camTime+20.))*0.1 - vec2(0.7,0.1);
    
    vec4 col = texture(iChannel0, uv);
    //col.rgb += pow(getBloom(uv), vec3(2.2));
    col.rgb += getBloom(uv);
    col.rgb = aces_tonemap(col.rgb);


    col.rgb += flareColor(1.2*p-q, time, 0.1) * 0.15;
    col.rgb += bokeh(2.*p-q + 0.34, time, 0.05) * 0.5;
    col.rgb += bokeh2(3.*(4.*p-q + 0.44), time, 0.2) * 0.5;
    col.rgb += bokeh2(3.*(p-2.*q), time, 0.2) * 0.5;
    col.rgb += bokeh2(5.*(3.*p-2.*q + 0.54), time, 0.1) * 0.3;
    col.rgb += bokeh2(5.*(q+p), time, 0.2) * 0.5;
    col.rgb += flareColor(5.*(p+0.53*q), time, 0.2)*0.5;
    
    fragColor = vec4(col.rgb, 1.0);
}
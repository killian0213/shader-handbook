// Image (image) — Year of Truchets #022 by byt3_m3chanic
// https://www.shadertoy.com/view/dtGGWw

/** 

    License: Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License
    
    Year of Truchets #022
    05/20/2023  @byt3_m3chanic
    
    All year long I'm going to just focus on truchet tiles and the likes!
    Truchet Core \M/->.<-\M/ 2023 
    
*/

#define PI  3.14159265359
vec2 curvature = vec2(8.,12.);

vec2 remapUV(vec2 uv) {
    uv = uv * 2. -1.;
    vec2 offset = abs(uv.yx) / vec2(curvature.x, curvature.y);
    uv = uv + uv * offset * offset;
    uv = uv * .5 + .5;
    return uv;
}

vec4 scanLine(float uv, float resolution, float opacity) {
     float intensity = sin(uv * resolution * PI * 2.);
     intensity = ((.5 * intensity) + .5) * .9 + .1;
     return vec4(vec3(pow(intensity, opacity)), 1.);
}

vec4 vignette(vec2 uv, vec2 resolution, float opacity) {
    float intensity = uv.x * uv.y * (1. - uv.x) * (1. - uv.y);
    return vec4(vec3(clamp(pow((resolution.x / 4.) * intensity, opacity), 0.0, 1.)), 1.);
}

vec2 scanLineOpacity = vec2(.325);

void mainImage( out vec4 fragColor, in vec2 fragCoord ) {  
	vec2 uv = fragCoord.xy/iResolution.xy;
    uv=(uv*1.05)-vec2(.025,.025);
    vec2 vuv = remapUV(uv);
    
    vec4 baseColor = texture(iChannel0, vuv);

    baseColor *= vignette(vuv, iResolution.xy, .75);
    baseColor *= scanLine(vuv.x, iResolution.y*.9, scanLineOpacity.x);
    baseColor *= scanLine(vuv.y, iResolution.x*.9, scanLineOpacity.y);

    if (vuv.x < 0.0 || vuv.y < 0.0 || vuv.x > 1.0 || vuv.y > 1.0){
        baseColor = vec4(vec3(.0),0);
    }
   
    fragColor = baseColor;
}

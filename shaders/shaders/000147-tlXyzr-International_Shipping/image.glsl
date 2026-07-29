// Image (image) — International Shipping by blackle
// https://www.shadertoy.com/view/tlXyzr

//CC0 1.0 Universal https://creativecommons.org/publicdomain/zero/1.0/
//To the extent possible under law, Blackle Mori has waived all copyright and related or neighboring rights to this work.

#define FK(k) floatBitsToInt(cos(k))^floatBitsToInt(k)
float hash(float a, float b) {
    int x = FK(a); int y = FK(b);
    return float((x*x-y)*(y*y+x)-x)/2.14e9 * .5;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
	
    float ltime = float(iFrame)/float(WAVE_DEPTH);

	vec2 uv = (fragCoord/iResolution.xy*2.0-1.0)/2.0;
    fragColor = texelFetch(iChannel0, ivec2(fragCoord), 0);
    fragColor.xyz /= fragColor.w;

    float seed = hash(min(1.,ltime), hash(uv.x,uv.y));
	fragColor += pow(seed,2.)*0.2 *vec4(0.8,0.9,1.0,0.); //noise
	fragColor *= (1.0 - pow(length(uv)*0.70, 2.0)); //vingetting lol
	fragColor = pow(log(fragColor+1.0), vec4(1.3))*1.25; //colour grading
    
    if (fragCoord.y < 10. && ltime < 1.) {
        float grad = sin(fragCoord.y/10.*3.14);
        float bright = pow(clamp(sin(fragCoord.y/15.*3.14),0.,1.),20.);
        float barpos = smoothstep(-1., 1., ltime*iResolution.x - fragCoord.x);
        fragColor.xyz = grad*mix(vec3(.1), vec3(.9,0.1,0), barpos) + bright*0.3;
        return;
    }
}

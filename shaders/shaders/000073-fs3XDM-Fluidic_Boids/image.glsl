// Image (image) — Fluidic Boids by davidar
// https://www.shadertoy.com/view/fs3XDM

//#define DEBUG

void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
    fragColor = vec4(0,0,0,1);
    vec2 uv = fragCoord / iResolution.xy;

#ifdef DEBUG
    if (uv.x < 0.25) {
        vec4 data = textureLod(iChannel0, floor(fragCoord/16.)*16. / iResolution.xy, 4.);
        vec2 vel = data.zw;

        fragColor.rgb = .6 + .6 * cos(atan(vel.y,vel.x) + vec3(0,23,21));
        
        data = textureLod(iChannel1, fragCoord / iResolution.xy, 4.);
    	fragColor.rgb += 60. * length(data.zw);
        return;
    }
#endif

    vec4 data = texture(iChannel0, fragCoord / iResolution.xy);
    particle P = getParticle(data, fragCoord);
    vec2 vel = P.V;

    fragColor.rgb = .6 + .6 * cos(atan(vel.y,vel.x) + vec3(0,23,21));
    fragColor.rgb *= sqrt(clamp(P.M, 0., 1.));

#ifdef DEBUG
    data = texture(iChannel1, fragCoord / iResolution.xy);
    for(int i = -2; i <= 2; i++) {
        for(int j = -2; j <= 2; j++) {
            vec4 data = texture(iChannel1, (fragCoord + vec2(i,j)) / iResolution.xy);
            if(data.x > 0.001) {
                fragColor.rgb += 0.4 * exp(-pow(distance(data.xy, fragCoord), 2.) / 2.);
                return;
            }
        }
    }
#endif
    if (0.00 < uv.y && uv.y < 0.01 && 5.*uv.x < ALIGNMENT)  fragColor += 0.5;
    if (0.01 < uv.y && uv.y < 0.02 && 5.*uv.x < SEPARATION) fragColor += 0.5;
    if (0.02 < uv.y && uv.y < 0.03 && 5.*uv.x < COHESION)   fragColor += 0.5;
}
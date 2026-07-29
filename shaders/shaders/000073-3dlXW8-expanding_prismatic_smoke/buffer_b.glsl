// Buffer B (buffer) — expanding prismatic smoke by morisil
// https://www.shadertoy.com/view/3dlXW8

#define rotate(a) mat2(cos(a),-sin(a),sin(a),cos(a))

bool reset() {
    return texture(iChannel3, vec2(32.5/256.0, 0.5) ).x > 0.5;
}

float getColor(
    float dist,
    const float angle,
    float size,
    float phase
) { 
    dist = dist
        + (sin(angle * 3. + iTime * 1. + phase) + 1.) * .02
        + (cos(angle * 5. - iTime * 1.1 + phase) + 1.) * .01;
	return 
        pow(dist / size, WALL_THINNESS)
        * smoothstep(size, size - PARTICLE_EDGE_SMOOTHING, dist)        
    ;
}

void mainImage(
    out vec4 fragColor,
    in vec2 fragCoord
) {
    vec2 pixel = (fragCoord - (iResolution.xy / 2.)) / iResolution.y;
    pixel *= rotate(iTime * 0.005);
    vec3 mixedColor = texture(iChannel1, fragCoord / iResolution.xy - pixel * 0.005
                             * iResolution.y / iResolution.xy
                             ).rgb;
    mixedColor *= 0.995;
    for (int i = 0; i < PARTICLE_COUNT; i++) {
        vec2 particle = getParticlePosition(i);
  		float dist = distance(particle, pixel);
        if (dist <= PARTICLE_SIZE) { 
            vec2 delta = particle - pixel;
            float angle = atan(delta.x, delta.y);
            float phase = float(i);
			mixedColor += vec3(
                getColor(dist, angle, PARTICLE_SIZE, phase),
                getColor(dist, angle + 0.03, PARTICLE_SIZE, phase),
                getColor(dist, angle + 0.06, PARTICLE_SIZE, phase)
            ) * 0.09
            * getParticleColor(i).rgb; //, mixedColor, 0.5;            
        }
    }
    fragColor = vec4(mixedColor, 1.);
    if (reset()) {
        fragColor = vec4(0);
    }
}

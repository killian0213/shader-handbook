// Buffer C (buffer) — Fluidic Boids by davidar
// https://www.shadertoy.com/view/fs3XDM

// Predators (classic boids)

#define MAX_SPEED 1.2
#define MAX_FORCE 0.1
#define DESIRED_SEPARATION 4

void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
    fragColor = vec4(0);
    if(iFrame < 10) {
        if(hash12(fragCoord) < 0.001) {
            float q = 2.*PI * hash12(1. + fragCoord);
            fragColor = vec4(fragCoord.xy, cos(q), sin(q));
        }
        return;
    }
    
    vec4 data = texture(iChannel0, fragCoord/iResolution.xy);

    if(data == vec4(0)) {
        if (length(hash33(vec3(fragCoord, iFrame))) < 0.015) {
            data = vec4(fragCoord, 0, 0);
        } else {
            return;
        }
    }
    
    vec2 pos = data.xy;
    vec2 vel = data.zw;

    vec2 separation = vec2(0);

    for(int i = -NEIGHBOR_DIST; i <= NEIGHBOR_DIST; i++) {
        for(int j = -NEIGHBOR_DIST; j <= NEIGHBOR_DIST; j++) {
            vec2 ij = vec2(i,j);
            if(ij == vec2(0) || length(ij) > float(NEIGHBOR_DIST)) continue;

            vec4 data2 = textureLod(iChannel0, fract((fragCoord + ij) / iResolution.xy), 0.);
            if(data2.x > 0.001 && distance(pos, data2.xy) < float(DESIRED_SEPARATION))
                separation += normalize(pos - data2.xy) / distance(pos, data2.xy);

            // nearby prey
            data2 = texture(iChannel1, fract((fragCoord + ij) / iResolution.xy));
            particle P2 = getParticle(data2, fragCoord + ij);
            separation -= P2.M * normalize(pos - P2.X);

            // distant prey
            vec2 coord = fragCoord + 16. * ij;
            data2 = textureLod(iChannel1, fract(coord / iResolution.xy), 4.);
            //vec2 vel2 = data2.zw;
            //separation -= normalize(pos - coord) * length(vel2);
            float m = data2.y;
            separation -= normalize(pos - coord) * m;
        }
    }

    vel = MAX_SPEED * normalize(vel + MAX_FORCE * normalize(separation));
    pos = mod(pos + vel, iResolution.xy);
    fragColor = vec4(pos, vel);
}
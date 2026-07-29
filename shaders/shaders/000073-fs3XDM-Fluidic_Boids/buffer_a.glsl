// Buffer A (buffer) — Fluidic Boids by davidar
// https://www.shadertoy.com/view/fs3XDM

// Prey (boids with fluidic characteristics)

#define MAX_SPEED 0.9
#define MAX_FORCE 0.05

void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
    fragColor = vec4(0);
    if(iFrame < 10) {
        float q = 2.*PI * hash12(1. + fragCoord);
        particle P;
        P.X = fragCoord;
        P.V = MAX_SPEED * vec2(cos(q), sin(q));
        P.M = 1.;
        fragColor = saveParticle(P, fragCoord);
        return;
    }
    
    vec4 data = texture(iChannel0, fragCoord/iResolution.xy);
    particle P = getParticle(data, fragCoord);

    if(P.M < 0.01) {
        P.X = fragCoord;
        P.V = vec2(0);
        P.M = 0.05;
    }
    
    vec2 pos = P.X;
    vec2 vel = P.V;

    float nCount = 0.;

    vec2 alignment = vec2(0);
    vec2 cohesion = vec2(0);
    vec2 separation = vec2(0);

    for(int i = -NEIGHBOR_DIST; i <= NEIGHBOR_DIST; i++) {
        for(int j = -NEIGHBOR_DIST; j <= NEIGHBOR_DIST; j++) {
            vec2 ij = vec2(i,j);
            if(ij == vec2(0) || length(ij) > float(NEIGHBOR_DIST)) continue;

            vec4 data2 = texture(iChannel0, fract((fragCoord + ij) / iResolution.xy));
            particle P2 = getParticle(data2, fragCoord + ij);
            vec2 pos2 = P2.X;
            vec2 vel2 = P2.V;
            float m = P2.M;

            separation += m * normalize(pos - pos2) / distance(pos, pos2);

            alignment += m * vel2;
            cohesion += m * pos2;
            nCount += m;

            // nearby predators
            data2 = textureLod(iChannel1, fract((fragCoord + ij) / iResolution.xy), 0.);
            if(data2.x > 0.001) separation += normalize(pos - data2.xy);

            // distant predators
            vec2 coord = fragCoord + 16. * ij;
            data2 = textureLod(iChannel1, fract(coord / iResolution.xy), 4.);
            vel2 = data2.zw;
            separation += normalize(pos - coord) * length(vel2);
        }
    }
    
    if (nCount > 0.) cohesion = cohesion / float(nCount) - pos;

    if(cohesion != vec2(0)) cohesion = clamp_length(
        MAX_SPEED * normalize(cohesion) - vel, MAX_FORCE);
    if(alignment != vec2(0)) alignment = clamp_length(
        MAX_SPEED * normalize(alignment) - vel, MAX_FORCE);
    if(separation != vec2(0)) separation = clamp_length(
        MAX_SPEED * normalize(separation) - vel, MAX_FORCE);

    vel += alignment * ALIGNMENT;
    vel += separation * SEPARATION;
    vel += cohesion * COHESION;
    vel -= 0.1 * textureLod(iChannel0, fragCoord / iResolution.xy, 7.).zw; // zero out average velocity of swarm
    P.V = clamp_length(vel, MAX_SPEED);
    fragColor = saveParticle(P, fragCoord);
}
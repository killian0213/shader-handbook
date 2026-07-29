// Buffer A (buffer) — Niolon by XT95
// https://www.shadertoy.com/view/Nt3XDM

// ---------------------------------------------------------------------------------
// Water heightmap + caustic pass
// I don't remember from where this code from... it's not mine for sure!
// ---------------------------------------------------------------------------------

#define DRAG_MULT 0.048

vec2 wavedx(vec2 position, vec2 direction, float speed, float frequency, float timeshift) {
    float x = dot(direction, position) * frequency + timeshift * speed;
    float wave = exp(sin(x) - 1.0);
    float dx = wave * cos(x);
    return vec2(wave, -dx);
}

float getwaves(vec2 position, int iterations, float weight, float speed){
    float iter = 0.0;
    float phase = 6.0;
    float w = 0.0;
    float ws = 0.0;
    for(int i=0;i<iterations;i++){
        vec2 p = vec2(sin(iter), cos(iter));
        vec2 res = wavedx(position, p, speed, phase, time);
        position += normalize(p) * res.y * weight * DRAG_MULT;
        w += res.x * weight;
        iter += 12.0;
        ws += weight;
        weight = mix(weight, 0.0, 0.2);
        phase *= 1.18;
        speed *= 1.07;
    }
    return w / ws;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 invRes = vec2(1.) / iResolution.xy;
    vec2 uv = fragCoord * invRes;
    
    float wave = getwaves(uv*15.,10,1., 0.5);
    float caustic = pow(getwaves(uv*15.,10, 5., 1.), 5.);
    fragColor = vec4(wave, caustic, 0., 0.);
}
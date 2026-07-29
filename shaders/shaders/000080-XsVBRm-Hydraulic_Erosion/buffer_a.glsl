// Buf A (buffer) — Hydraulic Erosion by davidar
// https://www.shadertoy.com/view/XsVBRm

// 2018 David A Roberts <https://davidar.io>

float slope(vec2 p, vec2 q) {
    return (buf(q).r - buf(p).r) / distance(p,q);
}

vec2 rec(vec2 p) { // direction of water flow at point
    vec2 d = N;
    if (slope(p + NE, p) > slope(p + d, p)) d = NE;
    if (slope(p + E,  p) > slope(p + d, p)) d = E;
    if (slope(p + SE, p) > slope(p + d, p)) d = SE;
    if (slope(p + S,  p) > slope(p + d, p)) d = S;
    if (slope(p + SW, p) > slope(p + d, p)) d = SW;
    if (slope(p + W,  p) > slope(p + d, p)) d = W;
    if (slope(p + NW, p) > slope(p + d, p)) d = NW;
    return d;
}

bool eq(vec2 p, vec2 q) {
    return distance(p,q) < 1e-3;
}

void mainImage( out vec4 r, in vec2 p ) {
    if (iFrame < 10 || iMouse.z > 0.) {
        r.r = clamp(5. * fbm(3. * p / iResolution.xy) + 0.5, 0., 1.);
        return;
    }
    r = buf(p);
    
    // flow accumulation
    r.g = 1.;
    if (eq(rec(p + N),  -N))  r.g += buf(p + N).g;
    if (eq(rec(p + NE), -NE)) r.g += buf(p + NE).g;
    if (eq(rec(p + E),  -E))  r.g += buf(p + E).g;
    if (eq(rec(p + SE), -SE)) r.g += buf(p + SE).g;
    if (eq(rec(p + S),  -S))  r.g += buf(p + S).g;
    if (eq(rec(p + SW), -SW)) r.g += buf(p + SW).g;
    if (eq(rec(p + W),  -W))  r.g += buf(p + W).g;
    if (eq(rec(p + NW), -NW)) r.g += buf(p + NW).g;
    
    // stream power
    vec4 receiver = buf(p + rec(p));
    float pslope = (r.r - receiver.r) / length(rec(p));
    r.r = max(r.r - 0.05 * pow(r.g, 0.8) * pow(pslope, 2.), receiver.r);
    
    // tectonic uplift
    r.r += 0.0004 * p.x/iResolution.x;
}

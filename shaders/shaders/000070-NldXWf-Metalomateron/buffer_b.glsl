// Buffer B (buffer) — Metalomateron by davidar
// https://www.shadertoy.com/view/NldXWf

MAIN {
    r = Du;
    vec4 w = vec4(0);
    if(SHADER == 2) {
        w = vec4(1, 1, .5, 3);
    } else if(SHADER == 3) {
        w = vec4(-.0225 * Du.z, 1, .375, 2);
    } else if(SHADER == 4) {
        w = vec4(-.00675, 1, .75, 0);
    } else if(SHADER == 5 || SHADER == 7) {
        w = vec4(1./8e3, 1, 0, 1);
    //} else if(SHADER == 8.5) {
    //    w = vec4(-1e-6, 0, 1./8., 1);
    //} else if(SHADER == 9) {
    //    w = vec4(-.0015, 1, .5, 0);
    }
    CONVO(8)
        r.xy += w.x * mix(Ai.xy, vec2(1), w.y) * G(w.z * ij)
            * ( w.w == 0. ? ij * Ai.x
              : w.w == 1. ? nij * Ai.z
              : w.w == 2. ? rot90(ij) * Ai.w
              : nij * (Ai.x*.1 + Ad.y*.5));
}

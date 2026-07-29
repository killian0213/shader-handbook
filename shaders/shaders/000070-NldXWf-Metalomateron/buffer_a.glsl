// Buffer A (buffer) — Metalomateron by davidar
// https://www.shadertoy.com/view/NldXWf

#define Dp vec2(dot(nij, Dd.xy), dot(nij, rot90(Dd.xy)))

MAIN {
    r = vec4(0);
    vec4 w = vec4(0);
    if(SHADER == 2) {
        float z = .5*.5 / 3.14; // gaussian normalisation const
        CONV(6) r += z * G(.5 * ij) * vec4(Dp.x, abs(Dp.y), 1,1);
    } else if(SHADER == 3) {
        CONV(8) r += .375 * lij * G(.375 * ij) * vec4(nij * Dd.z, Dp * Di.z);
    } else if(SHADER == 4) {
        CONV(4) r.x += length(Dd.xy);
    } else if(SHADER == 5) {
        w = vec4(.7, .175, .1, 1);
    } else if(SHADER == 6) {
        w = vec4(.66, .25, .1, 1);
    //} else if(SHADER == 7.5) {
    //    w = vec4(2, .5, 1, 1);
    //} else if(SHADER == 8.5) {
    //    CONVO(8) r += vec4(vec2(length(Dd.xy) * sin(dot(ij/8., rot90(Dd))*6.)), dot(nij, rot90(Dd)), 0);
    } else if(SHADER == 7) {
        w = vec4(0,0,1,1);
    //} else if(SHADER == 9) {
    //    CONV(8) r += dot(Di.xy,ij/4.)*G(ij/4.);
    }
    if(w.w != 0.) CONVO(8) r += vec4(nij * Dd.z * cos(w.x * lij) * G(w.y * lij) * w.z, Dp);
}

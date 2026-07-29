// Buffer C (buffer) — Metalomateron by davidar
// https://www.shadertoy.com/view/NldXWf

MAIN {
    r = Bu;
    float w = 1.;
    if(SHADER == 1) {
        r = Du;
    } else if(SHADER == 3) {
        r += Au * (Bu.z-.5);
        w = .5;
    } else if(SHADER == 5) {
        r += Au;
        w = 1.5;
    } else if(SHADER == 6) {
        r = Du + Au;
        w = 1./.75;
    //} else if(SHADER == 7.5) {
    //    r += Au;
    } else if(SHADER == 7) {
        r += Au * (Bu.z-.5)*.3;
    //} else if(SHADER == 9) {
    //    r = Du;
    //    w = 1./6. * (sin(Du.z*3.)*2.+4.);
    }
    float s = 0.;
    CONV(8) s += G(w * (r.xy + ij));
    r = vec4(r.xy, recip(s), 0);
}

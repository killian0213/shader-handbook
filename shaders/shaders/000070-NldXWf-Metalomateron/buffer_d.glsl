// Buffer D (buffer) — Metalomateron by davidar
// https://www.shadertoy.com/view/NldXWf

MAIN {
    r = vec4(0);
    vec4 w = vec4(0);
    /*if(SHADER == 1) {
        CONV(6) r += Di.z * G(Ci.xy+ij) * vec4(Ci.xy+(Ci.xy+ij)*(.8-Di.z),Ci.z,1);
    } else*/ if(SHADER == 2 || SHADER == 4) {
        w = vec4(0,1,0,0);
    } else if(SHADER == 3) {
        w = vec4(1, .5, 0, 0);
    } else if(SHADER == 5) {
        w = vec4(1, 1.5, 0, 0);
    } else if(SHADER == 6) {
        w = vec4(2, 1./.75, 0, 0);
    } else if(SHADER == 7) {
        w = vec4(1,1,0,0);
    //} else if(SHADER == 9) {
    //    CONV(6) r += vec4((Bi * Ci.z * G((Bi.xy-ij)/6. * (sin(Bi.z*3.)*2.+4.))).xyz, 0);
    }

    CONV(8) r += (w.x == 0. ? 1. : w.x == 1. ? Bi.z : Di.z) * G(w.y * (Ci.xy - ij)) * vec4(Ci.xyz, 1);
    r.xy *= recip(r.w);

    int scales[9] = int[](0,22,4,4,8,16,8,8,2);
    float scale = float(scales[SHADER-1]);
    if(iMouse.z>0.) {
        vec2 m = scale*(u-iMouse.xy)/R.y;
        r += vec4(m,0,0)*G(m)*.1;
    }
    if(iFrame < 2) {
        vec2 m = scale * (UV - 0.5);
        //if(SHADER == 9) r = vec4(.1*G(m));
        r = vec4(m,1,1)*G(m);
    }
}

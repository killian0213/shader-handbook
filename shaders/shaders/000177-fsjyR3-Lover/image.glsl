// Image (image) — Lover by wyatt
// https://www.shadertoy.com/view/fsjyR3

Main 
    vec4 b = B(U);
    Q = max(sin(.5+b.x/R.x+vec4(1,2,3,4)),0.);
    vec4 C = vec4(.8)+.3*grad(U).x;
    float q = 0.;
    vec2 v = 4.*(U-.5*R)/R.y+vec2(0,2);
    q += B(U+v).z;
    q += B(U+2.*v).z;
    q += B(U+3.*v).z;
    q += B(U+4.*v).z;
    q += B(U+5.*v).z;
    Q *= 1.+.1*dFdy(q);
    Q = mix(C,Q,min(q,1.));
    float w = 1e9;
    for (float i = 1.; i < 30.; i++) {
        float s = B(U+i*vec2(0,3)).z;
        if (s>0.) {
            w = i;
            break;
        }
    }
    Q -= exp(-.3*(w))*(1.-min(q,1.));
}
// Buffer B (buffer) — Automata X Showcase 3x2 (3x3) by misol101
// https://www.shadertoy.com/view/ds2fD1

// Persistive Keyboard Input buffer & resolution change check

vec4 keyStep(int ix, int iy, int key, float delta, float maxval) {
    vec3 keystate = texelFetch(iChannel0, ivec2(ix,iy), 0 ).xyz;
    float kx=keystate.x;
    float ky=keystate.y;
    if( readKey(key) ) {
        if (ky == 0.) {
            kx+=1.;
            if (kx >= maxval) kx=0.;
            if (kx < 0.) kx=maxval-delta;
        }
        ky+=0.01;
        if (ky >= 1.0) ky=0.;
    }
    else {
        ky = 0.;
    }
    return vec4(kx,ky,0.,0.);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    int ix = int(fragCoord.x), iy = int(fragCoord.y);

    if (iy > 1) {
        fragColor = vec4(0.,0.,0.,1.0);
        return;
    }

    /*if (ix == 0 && iy == 0) {
        vec3 keystate = texelFetch(iChannel0, ivec2(ix,iy), 0 ).xyz;
        float kx=keystate.x;
        float ky=keystate.y;
        if( readKey(KEY_Z)||readKey(KEY_X)||readKey(KEY_C)||readKey(KEY_V) ) {
            if (ky == 0.) {
                if (readKey(KEY_X) || readKey(KEY_V)) {
                    kx+=0.1;
                    if (kx > LAST_PATT*0.1+0.05) kx=0.05;
                } else {
                    kx-=0.1;
                    if (kx < 0.) kx=LAST_PATT*0.1+0.05;
                }
            }
            ky+=0.01;
            if (ky >= 1.0) ky=0.;
        }
        else {
            ky = 0.;
        }
        fragColor = vec4(kx,ky,0.,0.);
        return;
    }*/

    if (ix == 1 && iy == 0) {
        float method = texelFetch(iChannel0, ivec2(ix,iy), 0 ).x;
        if( readKey(KEY_0)) method = 0.5;
        if( readKey(KEY_1)) method = 1.5;
        if( readKey(KEY_2)) method = 2.5;
        if( readKey(KEY_3)) method = 3.5;
        if( readKey(KEY_4)) method = 4.5;
        if( readKey(KEY_5)) method = 5.5;
        if( readKey(KEY_6)) method = 6.5;
        if( readKey(KEY_7)) method = 7.5;
        if( readKey(KEY_8)) method = 8.5;
        if( readKey(KEY_9)) method = 9.5;
        fragColor = vec4(method,0.,0.,0.);
        return;
    }

    if (ix == 2 && iy == 0) {
        float speed = texelFetch(iChannel0, ivec2(ix,iy), 0 ).x;
        if( readKey(KEY_Z)) speed = 0.;
        if( readKey(KEY_X)) speed = 1.;
        if( readKey(KEY_C)) speed = 5.;
        fragColor = vec4(speed,0.,0.,0.);
        return;
    }

    if (ix == 3 && iy == 0) {
        fragColor = keyStep(ix, iy, KEY_M, 1., 2.);
        return;
    }

    if (ix == 4 && iy == 0) {
        fragColor = keyStep(ix, iy, KEY_ENTER, 1., 2.);
        return;
    }

    if (ix == 5 && iy == 0) {
        fragColor = keyStep(ix, iy, KEY_A, 1., 2.);
        return;
    }

    if (ix == 10 && iy == 0) {
        vec2 ppos = texelFetch(iChannel0, ivec2(ix,iy), 0 ).xy;
        float mmul = iMouse.x / iResolution.x;
        vec2 mid = iResolution.xy / 2.;

        float psp=8.;
        if( readKey(KEY_RIGHT)) ppos.x += psp;
        if( readKey(KEY_LEFT)) ppos.x -= psp;
        if( readKey(KEY_DOWN)) ppos.y -= psp;
        if( readKey(KEY_UP)) ppos.y += psp;
        ppos.x = clamp(ppos.x, -mid.x*mmul, mid.x*mmul);
        ppos.y = clamp(ppos.y, -mid.y*mmul, mid.y*mmul);

        fragColor = vec4(ppos,0.,1.);
        return;
    }

    if (ix == 11 && iy == 0) {
        float method = texelFetch(iChannel0, ivec2(ix,iy), 0 ).x;
        if( readKey(KEY_Q)) method = 0.5;
        if( readKey(KEY_W)) method = 1.5;
        if( readKey(KEY_E)) method = 2.5;
        if( readKey(KEY_R)) method = 3.5;
        if( readKey(KEY_T)) method = 4.5;
        fragColor = vec4(method,0.,0.,0.);
        return;
    }


    if (ix == 0 && iy == 1) {
        fragColor = vec4(iResolution.x,0.,0.,0.);
        return;
    }

    fragColor = vec4(0.,0.,0.,1.0);
}
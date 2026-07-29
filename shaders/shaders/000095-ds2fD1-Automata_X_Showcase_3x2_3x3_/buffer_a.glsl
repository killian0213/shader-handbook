// Buffer A (buffer) — Automata X Showcase 3x2 (3x3) by misol101
// https://www.shadertoy.com/view/ds2fD1

// Cellular automata buffer

int cell( in ivec2 p )
{
    ivec2 r = ivec2(textureSize(iChannel0, 0));
    p = (p+r) % r;
    float val = texelFetch(iChannel0, p, 0 ).w;
    return ( val == liveval ) ? 1 : 0;
}
vec4 cellval( in ivec2 p )
{
    ivec2 r = ivec2(textureSize(iChannel0, 0));
    p = (p+r) % r;
    return texelFetch(iChannel0, p, 0 );
}

float randpix(vec2 fragCoord) {
    float rn = hash1(iTime+fragCoord.x*13.0+hash1(fragCoord.y*71.1));
    return clamp(step(1.01-density/100., rn), 0., 1.) * (liveval);
}

float restart(vec2 fragCoord, int method, bool preserve) {
    if (method == 0)
        return randpix(fragCoord);

    vec2 mid = iResolution.xy / 2.; 
    float w=100., h=100., radius=452., rradius=25.;
    if (iResolution.y < 1000.) radius=182.;
    float xrad=569.,yrad=453.;
    float thick=2., wl=w-thick, hl=h-thick;

    if (method == 1) {
        if (length(fragCoord-mid)< radius && length(fragCoord-mid) > (radius-thick))
            return liveval;
    }
    if (method == 2) {
        if (((fragCoord.x > mid.x - w && fragCoord.x < mid.x - wl) || (fragCoord.x > mid.x + wl && fragCoord.x < mid.x + w))
            && fragCoord.y > mid.y - h && fragCoord.y < mid.y + h)
            return liveval;
        if (((fragCoord.y > mid.y - h && fragCoord.y < mid.y - hl) || (fragCoord.y > mid.y + hl && fragCoord.y < mid.y + h))
            && fragCoord.x > mid.x - w && fragCoord.x < mid.x + w)
            return liveval;
    }
    if (method == 3) {
        if (length(vec2((fragCoord.x-mid.x)*0.793,(fragCoord.y-mid.y)*1.0))< radius)
            return randpix(fragCoord);
    }
    if (method == 4) {
        float xmul=1.; if (iResolution.y < 1000.) xmul=1.75;
        if (fragCoord.x > mid.x - rradius*xmul && fragCoord.x < mid.x + rradius*xmul+1. && fragCoord.y > mid.y - rradius && fragCoord.y < mid.y + rradius +1.)
            return randpix(fragCoord);
    }
    return preserve? -1. : 0.;
}


void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    float ix = 0.;
    texelFetch(iChannel2, ivec2(0,0), 0 ).x;
    float xres = texelFetch(iChannel2, ivec2(0,1), 0 ).x;
    int iix = int(texelFetch(iChannel2, ivec2(1,0), 0 ).x);
    int speed = int(texelFetch(iChannel2, ivec2(2,0), 0 ).x);
    int mono = int(texelFetch(iChannel2, ivec2(3,0), 0 ).x);
    int method = int(texelFetch(iChannel2, ivec2(11,0), 0 ).x);
    int rows = 2+ int(texelFetch(iChannel2, ivec2(4,0), 0 ).x);
    
    float xsq = 3., ysq = float(rows);

    float bsh=0.;
    ix = float(iix-1);
    if (ix>=0.) {
        xsq = 1., ysq = 1.;
    } else {
        ix=0.;
        bsh=1.;
    }
    
    float wsq = iResolution.x / xsq;
    float hsq = iResolution.y / ysq;
    float thick = 3.;

    int cix = (int(fragCoord.x / wsq) + int(fragCoord.y / hsq)*int(xsq) + int(ix*10.)) % 9;
    setRules(cix, vec3(0.));
    if (cix==3 && iResolution.y < 400.) { rp*=1.8; gp*=1.8; bp*=1.8; } 

    float dt=density; if (density2 >= 0.) density=density2; if (cix==0 && iResolution.y > 400.) density=0.; if (bsh < 1.) density = 0.;
    float i;
    for (i=0.; i<=xsq; i++) {
        if (fragCoord.x > wsq*i-thick && fragCoord.x < wsq*i+thick ) {
            fragColor = vec4(bsh,bsh,bsh,randpix(fragCoord));
            return;
        }
    }
    for (i=0.; i<=ysq; i++) {
        if (fragCoord.y > hsq*i-thick && fragCoord.y < hsq*i+thick ) {
            fragColor = vec4(bsh,bsh,bsh,randpix(fragCoord));
            return;
        }
    }
    density=dt;

    ivec2 px = ivec2( fragCoord );
    vec4 curr = cellval(px);
    float ev = curr.w;

    if( iFrame==0 || readKey(KEY_SPACE) || readKey(KEY_ENTER) || int(xres) != int(iResolution.x) ) {
        fragColor = vec4( 0.0, 0.0, 0.0, restart(fragCoord, setmethod, false));
        return;
    }

    if( readKey(KEY_0) || readKey(KEY_1) || readKey(KEY_2) || readKey(KEY_3) || readKey(KEY_4) || readKey(KEY_5) || readKey(KEY_6) || readKey(KEY_7) || readKey(KEY_8) || readKey(KEY_9) ) {
        fragColor = vec4( 0.0, 0.0, 0.0, restart(fragCoord, setmethod, false));
        return;
    }

    if( readKey(KEY_Q) || readKey(KEY_W) || readKey(KEY_E) || readKey(KEY_R) || readKey(KEY_T) ) {
        fragColor = vec4( 0.0, 0.0, 0.0, restart(fragCoord, method, false));
        return;
    }

    if (iFrame % (speed+1) > 0) {
        fragColor = curr;
        return;
    }
  
    int k=0;
    
    if (nh == 0) {
        // ..X..
        // .X.X.
        // X.*.X
        // .X.X.
        // ..X..
        k =   cell(px+ivec2(0,-2)) + cell(px+ivec2(-1,-1)) + cell(px+ivec2(1,-1))
            + cell(px+ivec2(-2, 0))                        + cell(px+ivec2(2, 0))
            + cell(px+ivec2(-1, 1)) + cell(px+ivec2(1, 1)) + cell(px+ivec2(0, 2));
    } else if (nh == 4 || nh==5 || nh == 6) {
        // .XXX. 4
        // XXXXX
        // XX*XX
        // XXXXX
        // .XXX.
        k =   cell(px+ivec2(-1, 2)) + cell(px+ivec2(0, 2)) + cell(px+ivec2(1, 2))
            + cell(px+ivec2(-1, -2)) + cell(px+ivec2(0, -2)) + cell(px+ivec2(1, -2))
            + cell(px+ivec2(-2, -1)) + cell(px+ivec2(-2, 0))
            + cell(px+ivec2(-2, 1))
            + cell(px+ivec2(2, -1)) + cell(px+ivec2(2, 0))
            + cell(px+ivec2(2, 1));
        // XXXXX 6
        // X...X
        // X.*.X
        // X...X
        // XXXXX
        if (nh > 4) k += cell(px+ivec2(2, 2)) + cell(px+ivec2(-2, -2)) + cell(px+ivec2(-2, 2)) + cell(px+ivec2(2, -2));
        // XXXXX 5
        // XXXXX
        // XX*XX
        // XXXXX
        // XXXXX
        if (nh < 6)
            k += cell(px+ivec2(0,-1))
            + cell(px+ivec2(-1, 0)) + cell(px+ivec2(1, 0))
            + cell(px+ivec2(0, 1))  + cell(px+ivec2(-1,-1)) + cell(px+ivec2(1,-1))
            + cell(px+ivec2(-1, 1)) + cell(px+ivec2(1, 1));
    } else if (nh == 10) {
        // XXXXX
        // ..X..
        // ..*..
        // ..X..
        // XXXXX    
        k =   cell(px+ivec2(0,-1)) + cell(px+ivec2(0,1)) +
            + cell(px+ivec2(-2, -2)) + cell(px+ivec2(-1, -2)) + cell(px+ivec2(0, -2)) + cell(px+ivec2(1, -2)) + cell(px+ivec2(2, -2))
            + cell(px+ivec2(-2, 2)) + cell(px+ivec2(-1, 2)) + cell(px+ivec2(0, 2)) + cell(px+ivec2(1, 2)) + cell(px+ivec2(2, 2));
    } else {
        // XXX
        // X*X
        // XXX
        k =   cell(px+ivec2(-1,-1)) + cell(px+ivec2(0,-1)) + cell(px+ivec2(1,-1))
            + cell(px+ivec2(-1, 0))                        + cell(px+ivec2(1, 0))
            + cell(px+ivec2(-1, 1)) + cell(px+ivec2(0, 1)) + cell(px+ivec2(1, 1));
    }
    
    float ff = 0.;
    if (ev > 0.5) {
        if (decimate > 0.) ff = ev-decimate;
        if ((stayset & (1<<(k-1))) > 0 ) { ff = float(k); if (clampstay && ff > liveval) ff = liveval; }
    }
    else {
        ff = (bornset & (1<<(k-1))) > 0 ? liveval : 0.;
    }

    if (mono == 0) {
        if (ff >= 1.0) {
            int st = int(ff);

            float mulbase = float(k);
            if (colch == 1) mulbase = ff;
            else if (colch == 2) mulbase = 1.;
            else if (colch == 3) mulbase = float(k^st);
            
            if ((st & ra) > 0) curr.x += cstep*mulbase*rp;
            if ((st & ga) > 0) curr.y += cstep*mulbase*gp;
            if ((st & ba) > 0) curr.z += cstep*mulbase*bp;
            
            if (staypatt == 5 || staypatt == 6) curr.z=curr.y=curr.x;	

        } else {
            float stayt = cstep * stayval;
            
            if (staypatt == 0 || staypatt > 5) {
                curr.x -= cstep*rm;
                curr.y -= cstep*gm;
                curr.z -= cstep*bm;
            }
            else if (staypatt == 1) {
                if(curr.x > cstep) {
                    curr.x -= cstep*rm;
                    curr.y -= cstep*gm;
                    curr.z -= cstep*bm;
                }
            }
            else if (staypatt == 2) {
                if(curr.y > cstep) {
                    curr.x -= cstep*rm;
                    curr.y -= cstep*gm;
                    curr.z -= cstep*bm;
                }
            }
            else if (staypatt == 3) {
                if(curr.z > cstep) {
                    curr.x -= cstep*rm;
                    curr.y -= cstep*gm;
                    curr.z -= cstep*bm;
                }
            }
            else if (staypatt == 4) {
                if(curr.z > cstep) {
                    curr.x -= cstep*rm;
                    curr.y -= cstep*gm;
                }
                if(curr.x > cstep) curr.z -= cstep*bm;
            }
            else if (staypatt == 5) {
                curr.x -= cstep*rm;
                curr.z=curr.y=curr.x;
            }
        }
    }

	fragColor = vec4( clamp(curr.xyz,0.,1.), ff );
}

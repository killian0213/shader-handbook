// Image (image) — Just touching the heart by iq
// https://www.shadertoy.com/view/dljyDc

// Copyright Inigo Quilez, 2023 - https://iquilezles.org/
// I am the sole copyright owner of this Work.
// You cannot host, display, distribute or share this Work neither
// as it is or altered, here on Shadertoy or anywhere else, in any
// form including physical and digital. You cannot use this Work in any
// commercial or non-commercial product, website or project. You cannot
// sell this Work and you cannot mint an NFTs of it or train a neural
// network with it without permission. I share this Work for educational
// purposes, and you can link to it, through an URL, proper attribution
// and unmodified screenshot, as part of your educational material. If
// these conditions are too restrictive please contact me and we'll
// definitely work it out.


// heart shape: https://www.shadertoy.com/view/3tyBzV
float dot2( in vec2 v ) { return dot(v,v); }
float sdHeart( in vec2 p )
{
    p.y += 0.6;
    p.x = abs(p.x);
    if( p.y+p.x>1.0 )
        return sqrt(dot2(p-vec2(0.25,0.75)))-sqrt(2.0)/4.0;
    return sqrt(min(dot2(p-vec2(0.00,1.00)),
                    dot2(p-0.5*max(p.x+p.y,0.0)))); //*sign(p.x-p.y); // don't need sign really for this shader
}

// oldschool rand() from Visual Studio
int seed=666; float frand(void) {seed=seed*0x343fd+0x269ec3;return float((seed>>16)&32767)/32767.0;}

// for each pixel, do math
void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    // coordinates
    vec2  p = (2.0*fragCoord-iResolution.xy)/iResolution.y;
    float px = 2.0/iResolution.y;

    // add circles over time (loop every 15 seconds)
    float time = mod( iTime, 15.0 );
    const int kMaxNum = 1536;
    float fnum = 16.0*(time/10.0) + (float(kMaxNum)-16.0)*pow(time/10.0,3.0);
    int   inum = min(1+int(floor(fnum)),kMaxNum);

    // gradually make brush softer
    float brush = 0.3 + 0.3*pow(max(0.0,1.0-float(inum)/float(kMaxNum)),4.0);

    // draw circles
    float col = 1.0;
    for( int i=0; i<inum-1; i++ )
    {
        // pick random positions
        vec2  q = vec2(1.3,0.9)*(-1.0+2.0*vec2(frand(),frand()));

        // compute the distance to the art
        float r = sdHeart(q/1.15)*1.15;

        // and make a circle of size equal to that distance
        float d = abs(length(p-q)-abs(r))-0.001;

        // put black inc for this circle
        col *= 1.0 - brush*smoothstep(2.0*px, -2.0*px, d);
    }

    // only last cicle needs angular animation
    {
        vec2  q  = vec2(1.3,0.9)*(-1.0+2.0*vec2(frand(),frand()));
        vec2  w  = p - q;
        float ra = atan(w.y,w.x)/6.283185; if(ra<0.0) ra += 1.0;
        float da = fnum-float(inum-1);
        float al = smoothstep( 0.0, 0.1, 1.1*da - ra );
        float r  = sdHeart(q/1.15)*1.15;
        float d  = abs(length(w)-abs(r))-0.001;
        col *= 1.0 - al*brush*smoothstep(2.0*px, -2.0*px, d);
    }
    
    // gradually introduce vignetting
    col *= 1.0 - 0.1*length(p) * (float(inum)/float(kMaxNum));

    // fade to white
    col = mix( col, 1.0, smoothstep(12.0,15.0f,time) );
    
    fragColor = vec4(col,col,col,1.0);
}
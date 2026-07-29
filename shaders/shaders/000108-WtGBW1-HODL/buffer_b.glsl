// Buffer B (buffer) — HODL by BigWIngs
// https://www.shadertoy.com/view/WtGBW1

// "HODL" 
// by Martijn Steinrucken aka The Art of Code/BigWings - 2021
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
// Email: countfrolic@gmail.com
// Twitter: @The_ArtOfCode
// YouTube: youtube.com/TheArtOfCodeIsCool
// Facebook: https://www.facebook.com/groups/theartofcode/
//
// Background layer. See my tutorial about this here:
// https://www.youtube.com/watch?v=3CycKKJiwis

#define S smoothstep
#define NUM_LAYERS 4.

vec2 GetPos(vec2 id, vec2 offs, float t) {
    float 
        n = N21(id+offs),
        n1 = fract(n*10.),
        n2 = fract(n*100.),
        a = t+n;
        
    return offs + vec2(sin(a*n1), cos(a*n2))*.4;
}

float Connect(vec2 a, vec2 b, vec2 uv, float t) {
    t = .5-abs(t-.5);
    float 
        d = Line(uv, a, b),
        d2 = length(a-b),
        fade = S(1.5, .5, d2+t)*S(.9,.6, t*2.),
        r = 6./iResolution.y;
    
    return S(r, 0., d)*fade;
}

float NetLayer(vec2 st, float n, float T) {
    vec2 
        id = floor(st)+n,
        p[9];

    float 
        t = iTime+10.,
        m=0., d, s,
        pulse, sparkle=0.;
    
    st = fract(st)-.5;
    
    int i=0;
    for(float y=-1.; y<=1.; y++) {
    	for(float x=-1.; x<=1.; x++) {
            p[i++] = GetPos(id, vec2(x,y), t);
    	}
    }
    
    for(int i=0; i<9; i++) {
        m += Connect(p[4], p[i], st, T);

        d = length(st-p[i]);

        s = (.005/(d*d));
        s *= S(1., .7, d);
        pulse = sin((fract(p[i].x)+fract(p[i].y)+t)*5.)*.4+.6;
        pulse = pow(pulse, 20.);

        s *= pulse;
        sparkle += s;
    }
    
    m += Connect(p[1], p[3], st, T);
	m += Connect(p[1], p[5], st, T);
    m += Connect(p[7], p[5], st, T);
    m += Connect(p[7], p[3], st, T);
    m += sparkle*S(.05, .5, abs(T-.5));
    
    return m;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    float 
        t, y, m = 0., r, d, glow, moon;
        
    vec2 
        uv = (fragCoord-iResolution.xy*.5)/iResolution.y,
        M = iMouse.xy/iResolution.xy,
        st = uv,
        offs = vec2(0, -y*300.);
    
    vec4 p = GetProgress(iTime, M);
    t = p.x;
    y = p.z;
    offs.y = -p.w;
    
    for(float i=0.; i<1.; i+=1./NUM_LAYERS) {
        float 
            size = mix(15., 1., i),
            fade = S(0., .6, i)*S(1., .8, i);
            
        m += fade * NetLayer(st*size-offs, i, t);
    }
	
    vec3 
        baseCol = GetBgCol(iTime),
        col = baseCol*m*.2;
    
    glow = max(0., -t*(1.-t)*4.+.5-uv.y);
    col += baseCol*(exp(offs.y/10.)+glow*glow);
    
    y = remap01(1., .92, y);
    r = .12;
    st = uv-vec2(0, y);
    d=length(st);
    moon = S(.002, -.002, d-r);
    glow = S(.0,.01,  y)*.0005/(d*d*d);
    glow = mix(glow, .4, moon);
    if(d<r) {
        r = .135; 
        moon *= WaveletNoise(st*5./(sqrt(r*r-d*d)/r), .1, 2.)*.5+.5;
    }
    col += moon+glow;
    
    fragColor = vec4(min(col,vec3(1)),1);
}
// Image (image) — Leopard Fur by BigWIngs
// https://www.shadertoy.com/view/4dcBRB

// Leopard Fur - by Martijn Steinrucken aka BigWings - 2018
// Email:countfrolic@gmail.com Twitter:@The_ArtOfCode
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

// Its not the most efficient but I'm happy with how it turned out.
// If your computer runs this too slow then lower the number of strands.
// Put full screen to see more of the pattern.

// Zoom with mouse.

// Use these values to change the effect


#define NUM_STRANDS 150.
#define STRAND_THICKNESS 1.
#define FUR_SIZE 15.
#define FUR_CURL 1.
#define FUR_ROUGHNESS .13
#define BASE_COL vec3(1., .7, .3)
#define SPOT_COL vec3(.7, .3, .1)
#define RING_COL vec3(.2, .15, .1)
#define MOTTLE .9

vec4 FurLayer(vec2 uv, vec2 offs, vec2 grid, out float alpha) {
    vec2 gv = (uv-offs)*grid;
    vec2 id = floor(gv);
    gv = fract(gv)-.5;
    
    vec4 col = vec4(0);
    col.rgb = N23(id);
    
    vec2 a = vec2(0);
    
    float n = SmoothNoise((floor((uv-offs)*grid)/grid+offs), 4.)*FUR_CURL;
   	float r = (n + N21(id)*FUR_ROUGHNESS)*2.*PI;
    vec2 b = Rot2d(vec2(0,.4), r);
    
    float t = sat( GetT(gv, -b, b));
    float d = length(gv-(2.*b*t-b));
    
    float w = mix(.004, .06, t)*STRAND_THICKNESS;
    float c = S(w, w*.8, d);
    
    alpha = S(w, 0., d)*c*S(.0, .5, t);
    col.a = (1.-t);
    col.rgb *= c*col.a;
    col.a *= col.a;
    
    return col;
}

vec3 LeopardTex(vec2 uv) {
	float n = SmoothNoise(uv, 16.);
    n += SmoothNoise(uv, 32.)*.5;
    n/=1.5;
    
    vec4 h = HexCoords(uv*5.);
    vec2 o = N22(h.zw+76354.);
    
    float r = (.3+sin(h.x*3.+o.x)*.08*o.y);
    r *= mix(.5, 1., fract(o.y*10.));
    float w = .4;
    float c = S(w, .0, abs(h.y-r));
    
    n = n*n + c;
    n = S(1., 1.2, n);
    
    vec3 col = BASE_COL;
   
    col = mix(col, SPOT_COL, S(r*1.5, .0, h.y));
    col = mix(col, RING_COL, n);
    col *= 1.-SmoothNoise(uv, 50.)*MOTTLE;
    return col;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 res = vec2(300, 300)*2.;//iResolution.xy;
    vec2 uv = (fragCoord-.5*res.xy)/res.y;
	vec2 m = (iMouse.xy/iResolution.xy);
    
    uv *= .3+m.y;
    
    float t = iTime*0.3;
    
    uv = Rot2d(uv, t*.1);
    uv += t*.2;
    vec2 grid = vec2(FUR_SIZE);
    
    vec4 col = vec4(0);
    for(float i=0.; i<NUM_STRANDS; i++) {
    	vec2 offs = (N12(i)-.5);
        float alpha;
        vec4 fur = FurLayer(uv, offs, grid, alpha);
        
        if(fur.a>col.a) col = mix(col, fur, alpha);
    }
    
    col.rgb = vec3(max(col.r, max(col.g, col.b)));
    col.rgb *= LeopardTex(uv*.5);
    
    fragColor = col*2.5;
}
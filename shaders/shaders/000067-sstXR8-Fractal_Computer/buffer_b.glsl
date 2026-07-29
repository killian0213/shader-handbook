// Buffer B (buffer) — Fractal Computer by byt3_m3chanic
// https://www.shadertoy.com/view/sstXR8

/** 
    License: Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License
    
    09/28/21 @byt3_m3chanic 
    Title Overlay Template

*/

#define R          iResolution
#define M          iMouse
#define T          iTime
#define PI         3.14159265359
#define PI2        6.28318530718

float time,tmod,ga1,ga2,ga3,ca1,ca2,ca3;
float lsp(float begin, float end, float t) { return clamp((t - begin) / (end - begin), 0.0, 1.0); }
float eoc(float t) { return (t = t - 1.0) * t * t + 1.0; }

////////////////////////////////////////////////////////
// Fabrice Neyret https://www.shadertoy.com/view/llySRh
int CAPS=0;
#define low CAPS=32;
#define caps CAPS=0;
#define spc  U.x-=.44;
#define C(c) spc O+= char(U,64+CAPS+c);
vec4 char(vec2 p, int c) {
    if (p.x<.0|| p.x>1. || p.y<0.|| p.y>1.) return vec4(0,0,0,1e5);
	return textureGrad( iChannel0, p/16. + fract( vec2(c, 15-c/16) / 16. ), dFdx(p/16.),dFdy(p/16.) );
}
// webGL2 variant with dynamic size
vec4 pInt(vec2 p, float n) {
    vec4 v = vec4(0);
    for (int i = int(n); i>0; i/=10, p.x += .5 )
        v += char(p, 48+ i%10 );
    return v;
}
vec4 pFloat(vec2 p, float n) {
    vec4 v = vec4(0);
    if (n < 0.) v += char(p - vec2(-.5,0), 45 ), n = -n;
    v += pInt(p,floor(n)); p.x -= .5;
    v += char(p, 46);      p.x -= .95;
    v += pInt(p,fract(n)*1e2);
    return v;
}
////////////////////////////////////////////////////////

mat2 rot (float a) { return mat2(cos(a),sin(a),-sin(a),cos(a)); }
float hash21(vec2 p) { return fract(sin(dot(p,vec2(23.86,48.32)))*4374.432); }

float box( in vec2 p, in vec2 b ){
    vec2 d = abs(p)-b;
    return length(max(d,0.0)) + min(max(d.x,d.y),0.0);
}

vec4 getHeader(vec2 uv, float px) {
    vec3 C = vec3(1);
    vec4 O = vec4(0);
    vec2 U = ( (uv*8.)+vec2(1.95,+.5) )/.5;

    C(6); low C(18);C(1);C(3);C(20);C(1);C(12); spc caps
    
    C(3); low C(15);C(13);C(16);C(21);C(20);C(5);C(18); spc caps
    
    float shadetext = O.x;
    shadetext = smoothstep(px,.95-px,shadetext);
    float ofs = ca3*.25;
    float tapeline=box(uv+vec2(.235-ofs,.03),vec2(ofs ,.0425));
    tapeline=smoothstep(px,.001-px,tapeline);

    return vec4(vec3(C),ca3>0.?clamp(tapeline-shadetext,0.,1.):0.);
}

vec4 getDate(vec2 uv, float px) {
    vec3 C = vec3(1);
    vec4 O = vec4(0);
    vec2 U = ( (uv*8.)+vec2(1.825,.5) )/.35;

    low C(2);C(25);C(20);U.x-=.4;
    O+=pInt(U,3.);
    spc
    C(13);U.x-=.475;
    O+=pInt(U,3.);
    C(3);C(8);C(1);C(14);C(9);C(3);
    spc spc
    
    O+=pInt(U,9.);C(-49); spc spc
    O+=pInt(U,28.);C(-49); spc spc
    O+=pInt(U,21.);
    
    float shadetext = O.x;
    shadetext = smoothstep(px,.95-px,shadetext);
    float ofs = ca2*.25;
    float tapeline=box(uv+vec2(.235-ofs,.04),vec2(ofs ,.025));
    tapeline=smoothstep(px,.001-px,tapeline);
    
    return vec4(C,ca2>0.?clamp(tapeline-shadetext,0.,1.):0.);
}

float getHatch(vec2 p, float res) {
    p *= res;
    float hRnd = hash21(floor(p*.5));

    if (hRnd > 0.33) p*= rot(1.57079632679);
    float hatch = clamp(sin((p.x - p.y)*PI*2.)*2. + .5, 0., 1.);
    return hatch;
}

vec4 getFrame(vec2 uv, float px) {

    vec2 fv = uv;
    fv.y += .0085*sin(fv.x*70.+T*10.);
    float frame=box(fv-vec2(.7,-.59),vec2(.25,.25));
    frame=smoothstep(px,-px,frame);
    
    vec3 h2 =mix(vec3(0.639,0.000,0.565),vec3(0.165,0.698,0.180),clamp((uv.x)*2.,0.,1.));
    vec3 C=mix(h2,vec3(0.122,0.122,0.122),1.-clamp((uv.y+.615)*1.75,0.,1.));
    float hatch = getHatch(uv,100.);
    C = mix(C,vec3(0.271,0.271,0.271),hatch);
    return vec4(C,frame);
}

void mainImage( out vec4 O, in vec2 F )
{  
    time = T+50.;

    float msw = mod(time,32.);
    float m1 = lsp(0.0, 4.0, msw);
    float m2 = lsp(16.0, 20.0, msw);
    
    ca1 = eoc(m1-m2);
    ca1 = ca1*ca1*ca1;
    
    float m3 = lsp(20.0, 21.0, msw);
    float m4 = lsp(31.0, 32.0, msw);
    
    ca2 = eoc(m3-m4);
    ca2 = ca2*ca2*ca2;
    
    float m5 = lsp(19.5, 20.5, msw);
    float m6 = lsp(30.5, 31.5, msw);
    
    ca3 = eoc(m5-m6);
    ca3 = ca3*ca3*ca3;
    
    vec2 vuv = (2.*F.xy-R.xy)/max(R.x,R.y);
    float px = .002;
    vec3 C = vec3(0,0,0);

    vec4 frame = getFrame(vuv+vec2(0,ca1), px);
    C = mix(C,frame.rgb,frame.w);
  
    vec4 logo = getHeader(vuv-vec2(.65,-(.4+ca1)), px);
    C = mix(C,logo.rgb,logo.w);
    
    vec4 date = getDate(vuv-vec2(.65,-(.475+ca1)), px);
    C = mix(C,date.rgb,date.w);
    
    float alpha = clamp(frame.w+logo.w+date.w,0.,1.);
    O = vec4(C,alpha);
}


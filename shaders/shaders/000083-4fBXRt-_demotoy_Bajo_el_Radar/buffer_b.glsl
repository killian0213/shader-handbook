// Buffer B (buffer) — [demotoy] Bajo el Radar by Kali
// https://www.shadertoy.com/view/4fBXRt

#define st(a) smoothstep(0.005,0.0,a)

float hash(float n){
    return fract(cos(n*89.42)*343.42);
}

float noise(float a) {
    float fr=fract(a);
    float fl=floor(a);
    return mix(hash(fl),hash(fl+1.),fr);
}

mat2 rot(float a) {
    float s=sin(a),c=cos(a);
    return mat2(c,s,-s,c);
}

vec3 gauge(vec2 p, float a) {
    vec3 colg=vec3(.2,1.,.5);
    vec3 cola=vec3(1.,1.,.3);
    vec3 colr=vec3(1.2,.2,.0);
    vec3 col=colg;
    if (a>.5) col=cola;
    if (a>.8) col=colr;
    vec3 c=vec3(0.);
    float disco=length(p)-.3;
    c+=st(disco)*.05;
    float luz=length(p)-.28;
    c+=col*st(luz)*smoothstep(.6,-.6,p.y);
    p.y+=.12;
    vec2 ps2=p;
    p=vec2(atan(p.x,p.y)*.2,length(p)-.17);
    p.y-=.07;
    vec2 ps=p;
    p.x-=.03;
    p.x=fract(p.x*(1.-p.x*2.)*50.);
    c-=step(p.x,.5+p.x*.2)*step(abs(p.y),.015+ps.x*(1.+ps.x)*.03)*step(abs(ps.x),.2);
    p=ps;
    p.y+=.04;
    c-=step(abs(p.y),.003)*step(abs(ps.x+.002),.205);
    c-=step(abs(p.y),.003)*step(abs(ps.x+.002),.205);
    c-=step(abs(p.y+.03),.03)*step(abs(ps.x+.002),.205)*step(0.1,p.x);
    p.y+=.06;
    c-=step(abs(p.y),.003)*step(abs(ps.x+.002),.205)*step(0.,p.x);
    p.y-=.03;
    p.x=fract(p.x*10.);
    c-=step(.9,p.x-p.y)*step(abs(p.y),.03)*step(abs(ps.x),.21);    
    p=ps;
    vec2 pr=p+vec2(.2-.4*a,0.);
    float agu=step(abs(pr.x)+pr.y*.1,.01)*step(abs(pr.y+.12),.16);
    c=mix(c,vec3(.3,.0,.0),agu);
    c-=step(p.y,-.13);
    p=ps2;
    c-=step(p.y,0.)*st(luz)*.75;
    float icon=length(p)-.09;
    c=mix(c,col*.6,st(abs(length(p)-.09)-.003));
    c=mix(c,col*.6,st(abs(length(p)-.07)-.002));
    c=mix(c,col*.6,st(abs(length(p)-.05)-.002));
    c=mix(c,col*.6,st(abs(length(p)-.03)-.002));
    ps=p;
    p.y+=.06;
    c=mix(c,col,st(length(p)-.01)*step(.5,fract(iTime/3.14159*2.)));
    p=ps;
    p*=rot(-iTime*4.+3.);
    c=mix(c,col,st(abs(p.x))*st(icon)*step(p.y,0.));
    return c;
}


void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
   vec2 uv = fragCoord/iResolution.xy-.5;
    uv.x*=iResolution.x/iResolution.y;
    uv.y+=.34;
    uv.x-=.73;
    uv*=2.5;
    float a=0.;
    a+=smoothstep(6.5,7.,iTime)*.5;
    a-=smoothstep(19.,20.,iTime)*.3;
    a+=smoothstep(43.,45.,iTime)*.49;
    a+=smoothstep(47.,49.,iTime)*.2;
    //a=.8;
    a+=noise(iTime*10.)*.15;
    a=clamp(a,0.,1.);
    vec3 col = gauge(uv, a);
    for (float i=-3.;i<3.;i++) {
        for (float j=-3.;j<3.;j++) {
            vec2 p=uv+vec2(i,j)*.25/iResolution.xy;
            col+=gauge(p, a);
        }
    }
    col*=.03;
    vec3 prev=texture(iChannel0,fragCoord/iResolution.xy).rgb;
    col=mix(prev,col,.8*st(length(uv)-.3));
    fragColor = vec4(col,1.);
}


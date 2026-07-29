// Image (image) — Genuary 2025 day 5 by Kali
// https://www.shadertoy.com/view/X3KcWR

#define samples 3

mat2 rot(float a) {
    float c = cos(a);
    float s = sin(a);
    return mat2(c, -s, s, c);
}

float x, y;
float cir1(vec2 p) {
    x=1000., y=1000.;
    for (float i=0.; i<7.; i++) {
        p=abs(p)/clamp(p.x*p.y,.3,5.)-1.;
        x=min(x,abs(p.x));
        y=min(y,abs(p.y));
    }
    x=exp(-.5*x);
    y=exp(-1.*y);
    return x-y*.1;
}

float cir2(vec2 p) {
    p.x-=1.5;
    float x=1000., y=1000.;
    for (float i=0.; i<5.; i++) {
        p=abs(p)/clamp(abs(p.x*p.y),.2,2.)-1.;
        x=min(x,abs(p.x));
        y=min(y,abs(p.y));
    }
    y=exp(-.7*y)-x*.1;
    return y;
}

float struc(vec3 p) {
    float d=length(p+vec3(0.,-3.,0.))+.6;
    d=min(d,length(p.xy+vec2(0.,-3.))+1.3);
    d=min(d,length(p.zy+vec2(0.,-3.))+1.5);
    vec2 s=sign(p.xz);
    p.xz=abs(p.xz);
    d=min(d,max(length(p.xz-5.-s*.5)+.5+p.y*.2,p.y-2.));
    return d;
}


float h;
float de(vec3 p) {
    p.yz*=rot(.6);
    p.xz*=rot(.6);
    p.xy+=iTime*.7+15.;
    p.x+=iTime*.3+0.;
    p.xz=mod(p.xz,16.)-8.;
    float r1=cir1(p.xz*.1);
    float r2=cir2(p.yz*.02);
    float sup = p.y;
    float sph = struc(p);
    float d = min(sup, sph);
    h=r1*.7+r2*1.2;
    d-=h;
    return d*.5;
}

float det = 0.005;

vec3 normal(vec3 p) {
    vec2 e = vec2(0.0, det);
    return normalize(vec3(de(p + e.yxx), de(p + e.xyx), de(p + e.xxy)) - de(p));
}

vec3 march(vec3 from, vec3 dir) {
    from.xy*=5.;
    vec3 p = from, col = vec3(0.0);
    float d=0.;
    for (int i = 0; i < 100; i++) {
        p += d * dir;
        d = de(p);
        if (d < det) break;
    }
    if (d < det) {
        float cx=x,cy=y;
        vec3 n = normal(p);
        vec3 ldir = normalize(vec3(-1., 1., -1.0));
        float dif = smoothstep(.8,1.,max(0., dot(ldir, n)));
        dif+=smoothstep(.5,.8,max(0.,dot(-dir,n)))*.35;
        col = vec3(1.8,1.,.5)*dif;
        float shadow = 1.0;
        vec3 shadowRay = p + n * 0.01;  
        for (int i = 0; i < 30; i++) {
            float d = de(shadowRay);
            if (d < 0.005) {
                shadow = 0.0;  
                break;
            }
            shadowRay += ldir * d;  
        }
        col+=step(cx,.87)*vec3(0.,1.,1.)*.5;
        col*=.3+shadow*.7;
        col+=step(fract(cy*3.),.25)*vec3(1.,0.3,0.1);
    } 
    return col;
}


vec3 antialiasedMarch(vec3 from, vec3 dir) {
    vec3 color = vec3(0.0);  
    vec2 offsetScale = 2./iResolution.xy; 

    for (int i = 0; i < samples; i++) {
        for (int j = 0; j < samples; j++) {
            vec2 offset = vec2(float(i), float(j)) / float(samples) - 0.5;
            vec3 displacedFrom = from + vec3(offset* offsetScale, 0.0) ;
            color += march(displacedFrom, dir);  
        }
    }

    return color / float(samples * samples);  
}
void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = (fragCoord - iResolution.xy * 0.5) / iResolution.y;
    vec3 from = vec3(uv, -6.);
    vec3 dir = normalize(vec3(0.,0., 1.));
    vec3 col = antialiasedMarch(from, dir)+.05;
    col*=exp(-3.*length(fragCoord/iResolution.xy-.5))*1.3+.2;
    fragColor = vec4(col, 1.0);
}

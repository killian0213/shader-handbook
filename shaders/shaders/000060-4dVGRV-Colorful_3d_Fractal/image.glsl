// Image (image) — Colorful 3d Fractal by trirop
// https://www.shadertoy.com/view/4dVGRV

// Created by Robert Schuetze - trirop/2015
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

vec3 map(in vec3 p){for(int i=0;i<100;i++)p.xzy =abs(vec3(1.3,.99,.75)*(p/dot(p,p)-vec3(1,1,.05)));return p/50.;}

vec3 raymarch(vec3 ro, vec3 rd){
    float t = 5.;
    vec3 col = vec3(0.);
    for(int i=0; i<50; i++){t+=0.03;col += map(ro+t*rd);}
    return col;
}

void mainImage(out vec4 o,in vec2 U){
    vec2 p = (U-iResolution.xy/2.)/(iResolution.y);
    float a = iDate.w*0.3-iMouse.x*0.01;
    vec3 r = vec3(3.)*mat3(cos(a),0,-sin(a),0,1,0,sin(a),0,cos(a));
	o.rgb = raymarch(r,normalize(p.x*normalize(cross(r,vec3(0,1,0)))+p.y*normalize(cross(normalize(cross(r,vec3(0,1,0))),r))-r*.3));
}
// 课间餐点 · 自动分阶段（STAGE_SEC=2.75）· 鼠标拖拽 scrub
#define STAGE_N 5
#define STAGE_SEC 2.75

// —— 课间餐点通用：分阶段实时解锁 ——
// 自动：每 STAGE_SEC 秒进入下一阶段并循环
// 交互：按住鼠标左右拖 = 手动 scrub 阶段
#ifndef STAGE_N
#define STAGE_N 5
#endif
#ifndef STAGE_SEC
#define STAGE_SEC 2.75
#endif

int snackStage()
{
    if (iMouse.z > 0.0) {
        float u = clamp(iMouse.x / max(iResolution.x, 1.0), 0.0, 0.999);
        return int(u * float(STAGE_N));
    }
    return int(mod(floor(iTime / STAGE_SEC), float(STAGE_N)));
}

// 底部整条阶段指示（当前格高亮）
vec3 snackHud(vec2 frag, vec3 col, int st)
{
    vec2 uv = frag / iResolution.xy;
    if (uv.y > 0.055) return col;
    float slot = floor(uv.x * float(STAGE_N));
    float on = (int(slot) == st) ? 1.0 : 0.22;
    vec3 bar = mix(vec3(0.05, 0.06, 0.09), vec3(0.98, 0.78, 0.32), on);
    float edge = step(0.96, fract(uv.x * float(STAGE_N)));
    bar = mix(bar, vec3(0.015), edge);
    float a = smoothstep(0.055, 0.028, uv.y);
    return mix(col, bar, a);
}

float map(vec3 p){ return min(length(p-vec3(0,1,0))-1.0, p.y); }
float march(vec3 ro,vec3 rd){
    float t=0.0;
    for(int i=0;i<64;i++){ float h=map(ro+rd*t); if(h<0.001*t||t>40.0)break; t+=h; }
    return t;
}
vec3 calcN(vec3 p){
    vec2 e=vec2(0.001,0.0);
    return normalize(vec3(map(p+e.xyy)-map(p-e.xyy), map(p+e.yxy)-map(p-e.yxy), map(p+e.yyx)-map(p-e.yyx)));
}
float softShadow(vec3 ro,vec3 rd){
    float res=1.0,t=0.02;
    for(int i=0;i<20;i++){ float h=map(ro+rd*t); res=min(res,8.0*h/t); t+=clamp(h,0.02,0.2); if(res<0.01||t>10.0)break; }
    return clamp(res,0.0,1.0);
}
float ao(vec3 p,vec3 n){
    float a=0.0, sc=1.0;
    for(int i=0;i<5;i++){ float fi=float(i)+1.0; float d=map(p+n*0.12*fi); a+=(0.12*fi-d)*sc; sc*=0.7; }
    return clamp(1.0-2.5*a,0.0,1.0);
}
void mainImage(out vec4 fragColor, in vec2 fragCoord){
    int st=snackStage();
    vec2 uv=(2.0*fragCoord-iResolution.xy)/iResolution.y;
    vec3 ro=vec3(0.0,1.3,3.8), ta=vec3(0,0.9,0);
    vec3 ww=normalize(ta-ro), uu=normalize(cross(ww,vec3(0,1,0))), vv=cross(uu,ww);
    vec3 rd=normalize(uv.x*uu+uv.y*vv+1.7*ww);
    float t=march(ro,rd);
    vec3 col=mix(vec3(0.4,0.5,0.65),vec3(0.7,0.85,1.0),rd.y*0.5+0.5);
    if(t<40.0){
        vec3 p=ro+rd*t, n=calcN(p), V=-rd;
        vec3 L=normalize(vec3(0.55,0.8,-0.3));
        vec3 albedo=(p.y<0.01)? vec3(0.35): vec3(0.75,0.25,0.2);
        float ndl=max(dot(n,L),0.0);
        col=albedo*ndl;
        if(st>=1){
            vec3 hemi=mix(vec3(0.2,0.15,0.1), vec3(0.4,0.55,0.8), n.y*0.5+0.5);
            col=albedo*(0.25*hemi+0.85*ndl);
        }
        if(st>=2){
            vec3 H=normalize(L+V);
            float spec=pow(max(dot(n,H),0.0), 64.0);
            col+=vec3(1.0)*spec*0.45;
        }
        if(st>=3){
            float F0=0.06;
            float F=F0+(1.0-F0)*pow(1.0-max(dot(n,V),0.0),5.0);
            col=mix(col, vec3(0.7,0.85,1.0), F*0.65);
        }
        if(st>=4){
            float sh=softShadow(p+n*0.02,L);
            float a=ao(p,n);
            vec3 H=normalize(L+V);
            float spec=pow(max(dot(n,H),0.0),64.0)*sh;
            float F0=0.06; float F=F0+(1.0-F0)*pow(1.0-max(dot(n,V),0.0),5.0);
            vec3 hemi=mix(vec3(0.2,0.15,0.1),vec3(0.4,0.55,0.8),n.y*0.5+0.5);
            col=albedo*(0.22*hemi*a+0.9*ndl*sh)+vec3(1.0)*spec*0.5;
            col=mix(col,vec3(0.7,0.85,1.0),F*0.55);
        }
    }
    col=snackHud(fragCoord,col,st);
    fragColor=vec4(pow(max(col,0.0),vec3(0.95)),1.0);
}

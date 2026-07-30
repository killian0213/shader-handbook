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

#define MAX_STEPS 64
#define MAX_DIST 40.0
float sdSphere(vec3 p, float r){ return length(p)-r; }
vec2 map(vec3 p){
    float d = sdSphere(p-vec3(0.0,1.0,0.0), 1.0);
    float dp = p.y;
    return (dp < d) ? vec2(dp, 2.0) : vec2(d, 1.0);
}
float march(vec3 ro, vec3 rd){
    float t=0.0;
    for(int i=0;i<MAX_STEPS;i++){
        float h=map(ro+rd*t).x;
        if(h<0.001*t || t>MAX_DIST) break;
        t+=h;
    }
    return t;
}
float softShadow(vec3 ro, vec3 rd){
    float res=1.0, t=0.02;
    for(int i=0;i<24;i++){
        float h=map(ro+rd*t).x;
        res=min(res, 8.0*h/t);
        t+=clamp(h,0.02,0.2);
        if(res<0.01||t>12.0) break;
    }
    return clamp(res,0.0,1.0);
}
vec3 calcN(vec3 p){
    vec2 e=vec2(0.001,0.0);
    return normalize(vec3(map(p+e.xyy).x-map(p-e.xyy).x,
                          map(p+e.yxy).x-map(p-e.yxy).x,
                          map(p+e.yyx).x-map(p-e.yyx).x));
}
void mainImage(out vec4 fragColor, in vec2 fragCoord){
    int st=snackStage();
    vec2 uv=(2.0*fragCoord-iResolution.xy)/iResolution.y;
    vec3 ro=vec3(0.0,1.4,4.5);
    vec3 ta=vec3(0.0,0.9,0.0);
    vec3 ww=normalize(ta-ro), uu=normalize(cross(ww,vec3(0,1,0))), vv=cross(uu,ww);
    vec3 rd=normalize(uv.x*uu+uv.y*vv+1.6*ww);
    float t=march(ro,rd);
    vec3 col=vec3(0.55,0.7,0.9)*(0.6+0.4*rd.y);
    if(t<MAX_DIST){
        vec3 p=ro+rd*t;
        vec2 h=map(p);
        if(st==0) col=vec3(0.9);
        else{
            vec3 n=calcN(p);
            if(st==1) col=n*0.5+0.5;
            else{
                vec3 L=normalize(vec3(0.6,0.8,-0.3));
                vec3 albedo=(h.y<1.5)? vec3(0.85,0.35,0.3): mix(vec3(0.25),vec3(0.65),step(0.0,sin(p.x*3.0)*sin(p.z*3.0)));
                float dif=max(dot(n,L),0.0);
                if(st>=3) dif*=softShadow(p+n*0.02,L);
                col=albedo*(0.12+0.88*dif);
                if(st>=4){
                    float fog=1.0-exp(-0.035*t);
                    col=mix(col,vec3(0.7,0.8,0.95),fog);
                }
            }
        }
    }
    if(st>=4){
        vec2 q=fragCoord/iResolution.xy;
        col*=0.6+0.4*pow(16.0*q.x*q.y*(1.0-q.x)*(1.0-q.y),0.35);
    }
    col=snackHud(fragCoord,col,st);
    fragColor=vec4(pow(max(col,0.0),vec3(0.95)),1.0);
}

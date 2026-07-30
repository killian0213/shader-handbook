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

#define MAX_STEPS 70
float map(vec3 p){
    float d1=length(p-vec3(0,1.0,0))-0.85;
    float d2=length(vec2(length(p.xz)-1.35, p.y-1.0))-0.28;
    return min(min(d1,d2), p.y);
}
float march(vec3 ro,vec3 rd, out float steps){
    float t=0.0; steps=0.0;
    for(int i=0;i<MAX_STEPS;i++){
        steps+=1.0;
        float h=map(ro+rd*t);
        if(h<0.001*t||t>40.0) break;
        t+=h;
    }
    return t;
}
vec3 calcN(vec3 p){
    vec2 e=vec2(0.001,0.0);
    return normalize(vec3(map(p+e.xyy)-map(p-e.xyy), map(p+e.yxy)-map(p-e.yxy), map(p+e.yyx)-map(p-e.yyx)));
}
vec3 heat(float u){ return 0.5+0.5*cos(6.28318*(u*0.9+vec3(0.0,0.33,0.67))); }
void mainImage(out vec4 fragColor, in vec2 fragCoord){
    int st=snackStage();
    vec2 uv=(2.0*fragCoord-iResolution.xy)/iResolution.y;
    vec3 ro=vec3(0.0,1.5,4.2), ta=vec3(0,0.9,0);
    vec3 ww=normalize(ta-ro), uu=normalize(cross(ww,vec3(0,1,0))), vv=cross(uu,ww);
    vec3 rd=normalize(uv.x*uu+uv.y*vv+1.7*ww);
    float steps; float t=march(ro,rd,steps);
    vec3 col=vec3(0.1,0.12,0.18);
    if(t<40.0){
        vec3 p=ro+rd*t; vec3 n=calcN(p);
        vec3 L=normalize(vec3(0.5,0.8,-0.3));
        vec3 albedo=(p.y<0.01)?vec3(0.3):vec3(0.55,0.45,0.4);
        col=albedo*(0.15+0.85*max(dot(n,L),0.0));
        if(st==1) col=heat(steps/float(MAX_STEPS));
        if(st==2){
            float band=abs(fract(map(p)*8.0)-0.5);
            col=mix(vec3(0.1), vec3(0.9,0.85,0.4), smoothstep(0.1,0.0,band));
        }
        if(st==3) col=n*0.5+0.5;
        if(st>=4){
            float hot=max(max(col.r,col.g),col.b);
            if(hot>0.95) col=mix(col,vec3(1.0,0.1,0.1),0.5+0.5*sin(iTime*20.0));
            if(any(isnan(col))) col=vec3(1.0,0.0,1.0);
        }
    }else if(st==1) col=heat(steps/float(MAX_STEPS));
    // legend
    if(st==1 && fragCoord.y<12.0) col=heat(fragCoord.x/iResolution.x);
    col=snackHud(fragCoord,col,st);
    fragColor=vec4(col,1.0);
}

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

#define MAX_STEPS 80
#define MAX_DIST 50.0
float sdBox(vec3 p, vec3 b){ vec3 q=abs(p)-b; return length(max(q,0.0))+min(max(q.x,max(q.y,q.z)),0.0); }
float sdSphere(vec3 p,float r){ return length(p)-r; }
float sdCyl(vec3 p, float r, float h){
    vec2 d=abs(vec2(length(p.xz),p.y))-vec2(r,h);
    return min(max(d.x,d.y),0.0)+length(max(d,0.0));
}
float map(vec3 p, int st){
    float d=p.y;
    float base=sdBox(p-vec3(0,0.15,0), vec3(1.6,0.15,1.1));
    d=min(d,base);
    if(st>=1){
        for(int i=0;i<4;i++){
            float fi=float(i);
            vec2 c=vec2((fi<1.5)?-0.9:0.9, (mod(fi,2.0)<0.5)?-0.55:0.55);
            d=min(d, sdCyl(p-vec3(c.x,0.85,c.y), 0.12, 0.55));
        }
    }
    if(st>=2){
        d=min(d, sdBox(p-vec3(0,1.45,0), vec3(1.35,0.1,0.9)));
        vec3 q=p-vec3(0,1.7,0); q.z=abs(q.z);
        d=min(d, sdBox(q, vec3(1.0,0.18,0.15)));
    }
    if(st>=3){
        float dome=max(sdSphere(p-vec3(0,1.85,0),0.55), -(p.y-1.85));
        d=min(d,dome);
    }
    return d;
}
float march(vec3 ro,vec3 rd,int st){
    float t=0.0;
    for(int i=0;i<MAX_STEPS;i++){
        float h=map(ro+rd*t,st);
        if(h<0.001*t||t>MAX_DIST)break;
        t+=h;
    }
    return t;
}
vec3 calcN(vec3 p,int st){
    vec2 e=vec2(0.001,0.0);
    return normalize(vec3(map(p+e.xyy,st)-map(p-e.xyy,st),
                          map(p+e.yxy,st)-map(p-e.yxy,st),
                          map(p+e.yyx,st)-map(p-e.yyx,st)));
}
void mainImage(out vec4 fragColor, in vec2 fragCoord){
    int st=snackStage();
    vec2 uv=(2.0*fragCoord-iResolution.xy)/iResolution.y;
    float ang=iTime*0.15;
    vec3 ro=vec3(4.0*sin(ang),2.2,4.0*cos(ang));
    vec3 ta=vec3(0.0,1.0,0.0);
    vec3 ww=normalize(ta-ro), uu=normalize(cross(ww,vec3(0,1,0))), vv=cross(uu,ww);
    vec3 rd=normalize(uv.x*uu+uv.y*vv+1.8*ww);
    float t=march(ro,rd,st);
    vec3 sky=mix(vec3(0.05,0.06,0.12),vec3(0.15,0.2,0.35),rd.y*0.5+0.5);
    sky+=vec3(0.6,0.7,1.0)*pow(max(dot(rd,normalize(vec3(0.35,0.75,0.4))),0.0),48.0)*0.9;
    vec3 col=sky;
    if(t<MAX_DIST){
        vec3 p=ro+rd*t;
        vec3 n=calcN(p,st);
        vec3 L=normalize(vec3(0.35,0.75,0.4));
        float dif=max(dot(n,L),0.0);
        vec3 albedo=vec3(0.75,0.72,0.68);
        col=albedo*(0.15+0.85*dif);
        if(st>=4){
            float sh=1.0; float tt=0.03;
            for(int i=0;i<20;i++){
                float h=map(p+n*0.02+L*tt,st);
                sh=min(sh,10.0*h/tt); tt+=clamp(h,0.03,0.25);
                if(sh<0.01||tt>10.0)break;
            }
            col=albedo*(0.12+0.88*dif*clamp(sh,0.0,1.0));
            col=mix(col,sky,1.0-exp(-0.02*t));
        }
    }
    col=snackHud(fragCoord,col,st);
    fragColor=vec4(pow(max(col,0.0),vec3(0.95)),1.0);
}

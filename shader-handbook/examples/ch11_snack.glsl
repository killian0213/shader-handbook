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

vec3 pal(float t){ return 0.5+0.5*cos(6.28318*(t+vec3(0.0,0.33,0.67))); }
float mandel(vec2 z0, vec2 c, int st, out vec2 trap){
    vec2 z=z0; float n=0.0; trap=vec2(1e3);
    const float B=256.0;
    for(int i=0;i<80;i++){
        z=vec2(z.x*z.x-z.y*z.y, 2.0*z.x*z.y)+c;
        float m2=dot(z,z);
        trap=min(trap, vec2(m2, min(abs(z.x),abs(z.y))));
        if(m2>B*B) break;
        n+=1.0;
    }
    if(n>79.0) return -1.0;
    if(st==0) return n;
    return n - log2(log2(max(dot(z,z),1.0))) + 4.0;
}
void mainImage(out vec4 fragColor, in vec2 fragCoord){
    int st=snackStage();
    vec2 uv=(2.0*fragCoord-iResolution.xy)/iResolution.y;
    vec2 z0=uv*1.25;
    vec2 c=(st>=4)? 0.78*vec2(cos(iTime*0.4),sin(iTime*0.4)) : z0;
    if(st<4){ c=z0; z0=vec2(0.0); }
    vec2 trap; float sn=mandel(z0,c,st,trap);
    vec3 col=vec3(0.02);
    if(sn<0.0){
        if(st>=3) col=pal(0.3+1.2*sqrt(trap.x))*0.45*(0.3+0.7*smoothstep(0.0,0.2,trap.y));
        else col=vec3(0.05,0.03,0.08);
    }else{
        if(st==0) col=pal(sn*0.05);
        else if(st==1) col=vec3(sn*0.04);
        else col=pal(sqrt(max(sn,0.0))*0.28);
        if(st>=3) col*=0.75+0.4*smoothstep(0.0,0.3,trap.y);
    }
    if(st>=4){
        vec2 q=fragCoord/iResolution.xy;
        col*=0.65+0.35*pow(16.0*q.x*q.y*(1.0-q.x)*(1.0-q.y),0.4);
        col=pow(max(col,0.0),vec3(0.9));
    }
    col=snackHud(fragCoord,col,st);
    fragColor=vec4(col,1.0);
}

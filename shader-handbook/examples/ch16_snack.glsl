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

float hash11(float n){ return fract(sin(n)*43758.5453); }
void mainImage(out vec4 fragColor, in vec2 fragCoord){
    int st=snackStage();
    vec2 uv=fragCoord/iResolution.xy;
    vec2 p=(2.0*fragCoord-iResolution.xy)/iResolution.y;
    vec3 col=vec3(0.03,0.04,0.07);
    float beat=0.5+0.5*sin(iTime*3.2);
    // spectrum bars
    for(int i=0;i<24;i++){
        float fi=float(i);
        float h=0.15+0.55*abs(sin(iTime*2.0+fi*0.4))*hash11(fi+floor(iTime*2.0));
        float x=(fi-11.5)/11.5*0.9;
        float bar=smoothstep(0.02,0.0,abs(p.x-x)-0.025)*smoothstep(0.0,-0.7,p.y+0.65-h);
        col+=vec3(0.3,0.7,1.0)*bar*(0.5+0.5*h);
    }
    if(st>=1){
        float r=0.25+0.08*beat;
        col+=vec3(1.0,0.4,0.7)*exp(-abs(length(p)-r)*20.0)*0.8;
        col+=vec3(1.0,0.5,0.8)*exp(-length(p)*3.0)*0.25*beat;
    }
    if(st>=2){
        vec2 m=(iMouse.z>0.0)?(2.0*iMouse.xy-iResolution.xy)/iResolution.y:vec2(0.0);
        col+=vec3(0.5,1.0,0.7)*exp(-length(p-m)*10.0)*0.5;
    }
    if(st>=3){
        int mode=int(mod(floor(iTime*0.35),3.0));
        vec3 tint=(mode==0)?vec3(1.0,0.3,0.5):(mode==1)?vec3(0.3,0.8,1.0):vec3(0.6,1.0,0.4);
        col*=tint*1.2;
    }
    if(st>=4){
        float hud=step(uv.y,0.12)*step(0.2,uv.x)*step(uv.x,0.8);
        col=mix(col, vec3(0.1,0.12,0.18), hud*0.7);
        col+=hud*vec3(0.9,0.85,0.5)*0.15*step(0.5,fract(uv.x*20.0+iTime));
        vec2 q=uv; col*=0.7+0.3*pow(16.0*q.x*q.y*(1.0-q.x)*(1.0-q.y),0.4);
    }
    col=snackHud(fragCoord,col,st);
    fragColor=vec4(col,1.0);
}

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

float hash21(vec2 p){ p=fract(p*vec2(123.34,456.21)); p+=dot(p,p+45.32); return fract(p.x*p.y); }
vec3 aces(vec3 x){ return clamp((x*(2.51*x+0.03))/(x*(2.43*x+0.59)+0.14),0.0,1.0); }
vec3 scene(vec2 uv){
    vec2 p=(uv*2.0-1.0)*vec2(iResolution.x/iResolution.y,1.0);
    vec3 col=mix(vec3(0.05,0.06,0.1),vec3(0.2,0.25,0.4),uv.y);
    for(int i=0;i<3;i++){
        float fi=float(i);
        vec2 c=vec2(sin(iTime*0.3+fi*2.0), cos(iTime*0.25+fi)*0.4)*0.45+vec2(0.0,0.1);
        float d=length(p-c);
        vec3 pc=0.5+0.5*cos(6.28318*(fi*0.2+vec3(0.0,0.33,0.67)));
        col+=pc*exp(-d*8.0)*1.2;
        col+=pc*exp(-d*40.0)*2.0;
    }
    return col;
}
void mainImage(out vec4 fragColor, in vec2 fragCoord){
    int st=snackStage();
    vec2 uv=fragCoord/iResolution.xy;
    vec3 col=scene(uv);
    if(st>=1){
        vec3 b=vec3(0.0);
        for(int i=-2;i<=2;i++) for(int j=-2;j<=2;j++){
            vec2 o=vec2(float(i),float(j))/iResolution.xy*3.0;
            vec3 s=scene(uv+o);
            b+=max(s-vec3(0.55),0.0);
        }
        col+=b/25.0*2.2;
    }
    if(st>=2){
        vec2 q=uv;
        col*=0.55+0.45*pow(16.0*q.x*q.y*(1.0-q.x)*(1.0-q.y),0.45);
    }
    if(st>=3) col=aces(col*1.1);
    if(st>=4){
        float g=hash21(fragCoord+floor(iTime*24.0));
        col+=(g-0.5)*0.06;
        col*=0.92+0.08*sin(fragCoord.y*2.0);
    }
    col=snackHud(fragCoord,col,st);
    fragColor=vec4(clamp(col,0.0,1.0),1.0);
}

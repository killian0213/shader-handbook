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
    vec2 tip=(iMouse.z>0.0)? (2.0*iMouse.xy-iResolution.xy)/iResolution.y
            : 0.55*vec2(sin(iTime*1.1), cos(iTime*0.9)*0.8);
    vec3 col=vec3(0.02,0.025,0.05);
    int N=(st>=1)?10:1;
    for(int i=0;i<10;i++){
        if(i>=N) break;
        float age=float(i)/9.0;
        vec2 pos=tip;
        if(iMouse.z<=0.0){
            float t=iTime-age*0.55;
            pos=0.55*vec2(sin(t*1.1), cos(t*0.9)*0.8);
        }else{
            pos=tip*(1.0-age*0.15);
        }
        float d=length(p-pos);
        float g=exp(-d*40.0)*(1.0-age);
        vec3 pc=0.5+0.5*cos(6.28318*(age+vec3(0.0,0.33,0.67)));
        if(st>=3){
            col.r+=exp(-length(p-pos-vec2(0.02,0.0))*40.0)*(1.0-age);
            col.g+=g*pc.g;
            col.b+=exp(-length(p-pos+vec2(0.02,0.0))*40.0)*(1.0-age);
        }else col+=pc*g;
    }
    if(st>=2){
        float bright=max(max(col.r,col.g),col.b);
        col+=col*smoothstep(0.3,0.9,bright)*0.8;
    }
    if(st>=4){
        col*=1.15;
        vec2 q=uv;
        col*=0.6+0.4*pow(16.0*q.x*q.y*(1.0-q.x)*(1.0-q.y),0.35);
        col=pow(max(col,0.0),vec3(0.9));
    }
    col=snackHud(fragCoord,col,st);
    fragColor=vec4(col,1.0);
}

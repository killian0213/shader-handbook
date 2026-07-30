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
float noise(vec2 p){
    vec2 i=floor(p),f=fract(p); f=f*f*(3.0-2.0*f);
    return mix(mix(hash21(i),hash21(i+vec2(1,0)),f.x), mix(hash21(i+vec2(0,1)),hash21(i+vec2(1,1)),f.x),f.y);
}
float fbm(vec2 p){ float v=0.,a=.5; for(int i=0;i<5;i++){v+=a*noise(p);p*=2.05;a*=.5;} return v; }
void mainImage(out vec4 fragColor, in vec2 fragCoord){
    int st=snackStage();
    vec2 uv=(2.0*fragCoord-iResolution.xy)/iResolution.y;
    vec3 sky=mix(vec3(0.02,0.03,0.1),vec3(0.05,0.1,0.25),uv.y*0.5+0.5);
    vec3 col=sky;
    // sea
    float y=uv.y+0.35;
    if(y<0.35){
        float h=0.0; vec2 q=vec2(uv.x*3.0, iTime*0.3);
        for(int i=0;i<3;i++){ h+=0.04*sin(q.x*float(i+2)+q.y*2.0); q*=1.8; }
        float fres=pow(1.0-clamp(0.2/(abs(y)+0.05),0.0,1.0),2.0);
        vec3 water=mix(vec3(0.02,0.08,0.18), vec3(0.15,0.35,0.45), fres);
        water+=vec3(0.5,0.7,1.0)*exp(-abs(y-h)*20.0)*0.25;
        col=mix(col,water, smoothstep(0.35,0.1,y));
    }
    if(st>=2){
        float hill=0.12*sin(uv.x*1.8)+0.04*fbm(uv*vec2(2.5,1.0));
        float m=smoothstep(0.03,-0.02,uv.y+0.02-hill);
        col=mix(col, vec3(0.04,0.06,0.1), m*0.9);
    }
    if(st>=3){
        float aur=0.0;
        for(int i=0;i<3;i++){
            float fi=float(i);
            float band=uv.y-0.35-0.08*fi+0.1*sin(uv.x*2.5+iTime*0.4+fi);
            aur+=exp(-band*band*28.0)*(0.55+0.45*sin(uv.x*4.0+iTime*0.7+fi));
        }
        col+=vec3(0.15,0.85,0.5)*aur*0.4*smoothstep(-0.1,0.5,uv.y);
        col+=vec3(0.55,0.25,0.95)*aur*0.18*smoothstep(-0.1,0.5,uv.y);
    }
    if(st>=1){
        // 稀疏雨丝（别做成竖条码）
        float rain=0.0;
        for(int i=0;i<12;i++){
            float fi=float(i);
            float x=fract(sin(fi*12.9898)*43758.5453)*2.0-1.0;
            float y=fract(uv.y*1.8+iTime*1.6+fi*0.37);
            float d=abs(uv.x-x*0.95);
            rain+=smoothstep(0.012,0.0,d)*smoothstep(0.0,0.15,y)*smoothstep(1.0,0.55,y);
        }
        col+=vec3(0.55,0.7,1.0)*rain*0.2;
    }
    if(st>=4){
        float stars=pow(hash21(floor(uv*vec2(90.0,50.0))), 30.0)*step(0.15,uv.y);
        col+=stars*vec3(0.9,0.95,1.0);
        // 窗框感：左右暗边
        float win=smoothstep(0.0,0.08,abs(uv.x)-1.05);
        col*=1.0-win*0.55;
        vec2 q=fragCoord/iResolution.xy;
        col*=0.7+0.3*pow(16.0*q.x*q.y*(1.0-q.x)*(1.0-q.y),0.4);
        col=pow(max(col,0.0),vec3(0.9));
    }
    col=snackHud(fragCoord,col,st);
    fragColor=vec4(col,1.0);
}

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
vec2 hash12(float n){ return fract(sin(vec2(n,n+17.1))*vec2(43758.5453,22578.145)); }
float noise(vec2 p){
    vec2 i=floor(p), f=fract(p); f=f*f*(3.0-2.0*f);
    float a=hash11(i.x+i.y*57.0), b=hash11(i.x+1.0+i.y*57.0);
    float c=hash11(i.x+(i.y+1.0)*57.0), d=hash11(i.x+1.0+(i.y+1.0)*57.0);
    return mix(mix(a,b,f.x), mix(c,d,f.x), f.y);
}
vec2 curl(vec2 p){
    float e=0.01;
    float n1=noise(p+vec2(0,e)), n2=noise(p+vec2(0,-e));
    float n3=noise(p+vec2(e,0)), n4=noise(p+vec2(-e,0));
    return vec2(n1-n2, n4-n3)/e;
}
void mainImage(out vec4 fragColor, in vec2 fragCoord){
    int st=snackStage();
    vec2 uv=(2.0*fragCoord-iResolution.xy)/iResolution.y;
    vec3 col=vec3(0.03,0.05,0.08);
    if(st==0 || st>=4){
        for(int i=0;i<40;i++){
            float id=float(i); vec2 seed=hash12(id);
            vec2 cen=0.55*vec2(sin(iTime*(0.4+0.5*seed.x)+seed.y*6.28), cos(iTime*(0.35+0.4*seed.y)+seed.x*5.0));
            col+= (0.5+0.5*cos(6.28318*(seed.x+vec3(0.0,0.33,0.67)))) * exp(-length(uv-cen)*70.0);
        }
    }
    if(st>=1){
        float w=0.0;
        for(int i=0;i<3;i++){
            float fi=float(i);
            vec2 src=vec2(sin(fi*2.0+iTime*0.3), cos(fi*1.3-iTime*0.2))*0.45;
            float r=length(uv-src);
            w+=sin(r*18.0-iTime*4.0)*exp(-r*1.8);
        }
        col+=vec3(0.2,0.5,0.8)*w*0.15;
    }
    if(st>=2){
        float field=0.0;
        for(int i=0;i<5;i++){
            float fi=float(i);
            vec2 c=0.4*vec2(sin(iTime*0.6+fi), cos(iTime*0.5+fi*1.3));
            field+=0.12/max(dot(uv-c,uv-c),0.002);
        }
        float m=smoothstep(1.0,1.4,field);
        col=mix(col, vec3(0.9,0.4,0.7), m*0.7);
    }
    if(st>=3){
        vec2 q=uv;
        for(int i=0;i<4;i++) q-=curl(q*1.5+iTime*0.1)*0.08;
        float dye=noise(q*2.0+iTime*0.05);
        col=mix(col, 0.5+0.5*cos(6.28318*(dye+vec3(0.1,0.4,0.7))), 0.55);
    }
    if(st>=4){
        col=pow(max(col,0.0),vec3(0.9));
        vec2 q=fragCoord/iResolution.xy;
        col*=0.65+0.35*pow(16.0*q.x*q.y*(1.0-q.x)*(1.0-q.y),0.4);
    }
    col=snackHud(fragCoord,col,st);
    fragColor=vec4(col,1.0);
}

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

// 三种写法算同一类场，用阶段切换「表达密度」的视觉隐喻
float field(vec2 p, int dense){
    float v=0.0;
    if(dense==0){
        for(int i=0;i<3;i++){
            float fi=float(i)+1.0;
            v+=sin(p.x*fi+iTime)*cos(p.y*fi-iTime*0.7)/fi;
        }
    }else if(dense==1){
        for(int i=0;i<5;i++){
            float fi=float(i)+1.0;
            p=0.8*p+0.2*sin(p.yx+iTime+fi);
            v+=sin(p.x*fi+p.y)*0.5/fi;
        }
    }else{
        for(int i=0;i<8;i++){
            p=mat2(0.8,-0.6,0.6,0.8)*p*1.15+sin(p.yx+iTime);
            v+=exp(-length(sin(p*3.0)))/float(i+1);
        }
    }
    return v;
}
void mainImage(out vec4 fragColor, in vec2 fragCoord){
    int st=snackStage();
    vec2 p=(2.0*fragCoord-iResolution.xy)/iResolution.y;
    int dense=(st<=2)?st: int(mod(floor(iTime*2.0),3.0));
    if(st==3) dense=int(mod(floor(iTime*2.5),3.0));
    float v=field(p*1.4, dense);
    vec3 col=0.5+0.5*cos(6.28318*(v*0.6+vec3(0.0,0.33,0.67)+float(dense)*0.1));
    if(st>=4){
        vec2 q=fragCoord/iResolution.xy;
        col*=0.6+0.4*pow(16.0*q.x*q.y*(1.0-q.x)*(1.0-q.y),0.4);
        col=pow(max(col,0.0),vec3(0.95));
    }
    // 角标：密度档
    if(p.x<-1.1 && p.y>0.7) col=mix(col, vec3(0.2+0.3*float(dense),0.8,1.0), 0.5);
    col=snackHud(fragCoord,col,st);
    fragColor=vec4(col,1.0);
}

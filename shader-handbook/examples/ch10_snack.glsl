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
float noise(vec3 x){
    vec3 p=floor(x), f=fract(x); f=f*f*(3.0-2.0*f);
    float n=p.x+p.y*57.0+p.z*113.0;
    return mix(mix(mix(hash21(vec2(n)),hash21(vec2(n+1.0)),f.x),
                   mix(hash21(vec2(n+57.0)),hash21(vec2(n+58.0)),f.x),f.y),
               mix(mix(hash21(vec2(n+113.0)),hash21(vec2(n+114.0)),f.x),
                   mix(hash21(vec2(n+170.0)),hash21(vec2(n+171.0)),f.x),f.y),f.z);
}
float fbm(vec3 p){ float v=0.0,a=0.5; for(int i=0;i<5;i++){ v+=a*noise(p); p=p*2.05+13.0; a*=0.5;} return v; }
float dens(vec3 p, int st){
    float d=length(p-vec3(0.0,0.2,0.0))-0.9;
    float base=smoothstep(0.4,0.0,d);
    if(st<2) return base;
    float n=fbm(p*2.2+vec3(0.0,iTime*0.08,0.0));
    return max(base*(n-0.35)*2.2, 0.0);
}
float hg(float mu,float g){ float g2=g*g; return (1.0-g2)/pow(max(1.0+g2-2.0*g*mu,1e-3),1.5)*0.08; }
void mainImage(out vec4 fragColor, in vec2 fragCoord){
    int st=snackStage();
    vec2 uv=(2.0*fragCoord-iResolution.xy)/iResolution.y;
    vec3 ro=vec3(0.0,0.0,3.2), rd=normalize(vec3(uv, -1.6));
    vec3 sun=normalize(vec3(0.55,0.25,-0.4));
    vec3 sky=mix(vec3(0.95,0.55,0.3), vec3(0.2,0.35,0.7), uv.y*0.5+0.5);
    sky+=vec3(1.0,0.8,0.5)*pow(max(dot(rd,sun),0.0),32.0)*0.8;
    vec3 col=sky;
    float t0=0.5, t1=4.5, dt=(t1-t0)/24.0;
    float T=1.0; vec3 c=vec3(0.0);
    float jitter=hash21(fragCoord)*dt;
    for(int i=0;i<24;i++){
        vec3 p=ro+rd*(t0+float(i)*dt+jitter);
        float d=dens(p,st);
        float absorb=d*1.8;
        vec3 emit=vec3(0.0);
        if(st>=1) emit=vec3(1.0,0.55,0.25)*d*0.9;
        if(st>=3){
            float mu=dot(rd,sun);
            emit*=1.0+3.0*hg(mu,0.65);
        }
        c+=T*emit*dt;
        T*=exp(-absorb*dt);
        if(T<0.01) break;
    }
    col=col*T+c;
    if(st>=4){
        float shafts=0.0;
        for(int i=0;i<10;i++){
            vec3 p=ro+rd*(0.8+float(i)*0.18);
            float shadow=exp(-dens(p+sun*0.3,st)*4.0);
            shafts+=shadow*exp(-dens(p,st)*1.5);
        }
        col+=vec3(1.0,0.75,0.4)*shafts*0.04;
    }
    col=snackHud(fragCoord,col,st);
    fragColor=vec4(pow(max(col,0.0),vec3(0.92)),1.0);
}

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

vec3 SUN=normalize(vec3(0.5,0.75,-0.35));
float iPlane(vec3 ro,vec3 rd){ if(abs(rd.y)<1e-5)return -1.0; float t=-ro.y/rd.y; return t>0.001?t:-1.0; }
float iSphere(vec3 ro,vec3 rd,vec3 c,float r){
    vec3 oc=ro-c; float b=dot(oc,rd), cc=dot(oc,oc)-r*r, h=b*b-cc;
    if(h<0.0)return -1.0; h=sqrt(h); float t=-b-h; if(t<0.001)t=-b+h; return t>0.001?t:-1.0;
}
vec2 hit(vec3 ro,vec3 rd){
    float tp=iPlane(ro,rd), ts=iSphere(ro,rd,vec3(0,1,0),1.0);
    if(tp>0.0 && (ts<0.0||tp<ts)) return vec2(tp,1.0);
    if(ts>0.0) return vec2(ts,2.0);
    return vec2(-1.0,0.0);
}
vec3 sky(vec3 rd){ return mix(vec3(0.45,0.55,0.75),vec3(0.8,0.9,1.0),max(rd.y,0.0))+pow(max(dot(rd,SUN),0.0),48.0)*vec3(1.0,0.9,0.7); }
vec3 aces(vec3 x){ return clamp((x*(2.51*x+0.03))/(x*(2.43*x+0.59)+0.14),0.0,1.0); }
void mainImage(out vec4 fragColor, in vec2 fragCoord){
    int st=snackStage();
    vec2 uv=(2.0*fragCoord-iResolution.xy)/iResolution.y;
    vec3 ro=vec3(0.0,1.4,4.2), rd=normalize(vec3(uv,-1.7));
    vec3 col=sky(rd); vec3 att=vec3(1.0);
    for(int bounce=0; bounce<((st>=3)?4:2); bounce++){
        vec2 h=hit(ro,rd);
        if(h.x<0.0){ col+=att*sky(rd); break; }
        vec3 p=ro+rd*h.x;
        vec3 n=(h.y<1.5)? vec3(0,1,0): normalize(p-vec3(0,1,0));
        if(h.y<1.5){
            vec3 albedo=mix(vec3(0.2),vec3(0.75),step(0.0,sin(p.x*3.0)*sin(p.z*3.0)));
            float sh=1.0;
            if(st>=1){ vec2 hs=hit(p+n*0.01,SUN); sh=(hs.x>0.0 && hs.y>1.5)?0.25:1.0; }
            col+=att*albedo*(0.15+0.85*max(dot(n,SUN),0.0)*sh);
            break;
        }
        if(st<2){ col+=att*vec3(0.7)*max(dot(n,SUN),0.0); break; }
        if(st==2){
            att*=vec3(0.95,0.85,0.65); rd=reflect(rd,n); ro=p+n*0.01; continue;
        }
        // glass
        float ior=1.5; float eta=1.0/ior;
        float F=0.04+(1.0-0.04)*pow(1.0-max(dot(n,-rd),0.0),5.0);
        vec3 refl=reflect(rd,n);
        vec3 refr=refract(rd,n,eta);
        if(st>=3){
            // approximate: mix env
            col+=att*F*sky(refl);
            if(dot(refr,refr)>0.0){ att*=(1.0-F)*vec3(0.9,0.95,1.0); rd=refr; ro=p-n*0.01; }
            else { att*=F; rd=refl; ro=p+n*0.01; }
            continue;
        }
        break;
    }
    if(st>=4){
        col*=1.2; col=aces(col);
        vec2 q=fragCoord/iResolution.xy;
        col*=0.65+0.35*pow(16.0*q.x*q.y*(1.0-q.x)*(1.0-q.y),0.4);
    }
    col=snackHud(fragCoord,col,st);
    fragColor=vec4(pow(max(col,0.0),vec3(0.95)),1.0);
}

// 第 12 章 · 玻璃球（折射 + 菲涅尔 + TIR）
// 修复：玻璃至少需要「入射 → 出射 → 再撞场景」三次路径；
// 旧版 MAX_BOUNCE=2 会在出射后立刻耗尽，整球变成死黑。
// 菲涅尔反射要采地板/天空，不能只采天空，否则下半球容易「一片蓝」。
const vec3  SUN = normalize(vec3(0.55, 0.72, -0.42));
const int   MAX_BOUNCE = 8;
const float IOR = 1.5;
const vec3  GLASS_C = vec3(0.0, 1.02, 0.0); // 略抬起，避免贴地自交
const float GLASS_R = 1.0;

mat3 setCamera(vec3 ro, vec3 ta)
{
    vec3 cw = normalize(ta - ro);
    vec3 cu = normalize(cross(cw, vec3(0.0, 1.0, 0.0)));
    vec3 cv = cross(cu, cw);
    return mat3(cu, cv, cw);
}

float iPlane(vec3 ro, vec3 rd)
{
    if (abs(rd.y) < 1e-5) return -1.0;
    float t = -ro.y / rd.y;
    return (t > 0.001) ? t : -1.0;
}

float iSphere(vec3 ro, vec3 rd, vec3 c, float r)
{
    vec3  oc = ro - c;
    float b  = dot(oc, rd);
    float cc = dot(oc, oc) - r * r;
    float h  = b * b - cc;
    if (h < 0.0) return -1.0;
    h = sqrt(h);
    float t0 = -b - h;
    float t1 = -b + h;
    if (t0 > 0.001) return t0;
    if (t1 > 0.001) return t1;
    return -1.0;
}

vec2 map(vec3 ro, vec3 rd)
{
    float tp = iPlane(ro, rd);
    float ts = iSphere(ro, rd, GLASS_C, GLASS_R);
    if (tp > 0.0 && (ts < 0.0 || tp < ts)) return vec2(tp, 1.0);
    if (ts > 0.0) return vec2(ts, 2.0);
    return vec2(-1.0, 0.0);
}

vec3 getNormal(vec3 p, float mat)
{
    if (mat < 1.5) return vec3(0.0, 1.0, 0.0);
    return normalize(p - GLASS_C);
}

vec3 sky(vec3 rd)
{
    float h = clamp(rd.y * 0.5 + 0.5, 0.0, 1.0);
    vec3  col = mix(vec3(0.55, 0.72, 0.92), vec3(0.90, 0.94, 0.98), h);
    col += vec3(1.0, 0.92, 0.75) * pow(max(dot(rd, SUN), 0.0), 64.0) * 0.45;
    return col;
}

vec3 floorAlbedo(vec3 pos)
{
    float chk = mod(floor(pos.x) + floor(pos.z), 2.0);
    return mix(vec3(0.35, 0.38, 0.42), vec3(0.78, 0.80, 0.84), chk);
}

// 阴影：玻璃只轻度挡光，绝不投死黑圆斑
float shadowAtten(vec3 p, vec3 nor)
{
    vec3 ro = p + nor * 0.003 + SUN * 0.003;
    vec2 h = map(ro, SUN);
    if (h.x <= 0.0) return 1.0;
    if (h.y > 1.5) return 0.72; // 玻璃软挡
    return 0.0;
}

vec3 shadeDiffuse(vec3 pos, vec3 nor)
{
    vec3  alb = floorAlbedo(pos);
    float dif = max(dot(nor, SUN), 0.0);
    float sha = shadowAtten(pos, nor);
    float amb = 0.22 + 0.25 * max(nor.y, 0.0);
    return alb * (amb + dif * sha);
}

// 菲涅尔二次射线：撞地板或天空（不再进玻璃，防递归爆炸）
vec3 bounceEnv(vec3 ro, vec3 rd)
{
    float tp = iPlane(ro, rd);
    if (tp > 0.0) {
        vec3 pos = ro + rd * tp;
        return shadeDiffuse(pos, vec3(0.0, 1.0, 0.0));
    }
    return sky(rd);
}

bool refractDir(vec3 rd, vec3 nor, float eta, out vec3 outRd)
{
    float cosI  = clamp(dot(-rd, nor), -1.0, 1.0);
    float sinT2 = eta * eta * (1.0 - cosI * cosI);
    if (sinT2 > 1.0) return false;
    float cosT  = sqrt(1.0 - sinT2);
    outRd = normalize(eta * rd + (eta * cosI - cosT) * nor);
    return true;
}

float fresnelSchlick(float cosTheta, float f0)
{
    return f0 + (1.0 - f0) * pow(1.0 - clamp(cosTheta, 0.0, 1.0), 5.0);
}

vec3 trace(vec3 ro, vec3 rd)
{
    vec3 col = vec3(0.0);
    vec3 att = vec3(1.0);
    bool inside = false;

    for (int i = 0; i < MAX_BOUNCE; i++) {
        vec2 hit = map(ro, rd);
        if (hit.y <= 0.0) {
            col += att * sky(rd);
            return col;
        }

        vec3 pos = ro + rd * hit.x;
        vec3 nor = getNormal(pos, hit.y);

        if (hit.y < 1.5) {
            col += att * shadeDiffuse(pos, nor);
            return col;
        }

        // —— 玻璃 ——
        if (inside) nor = -nor;

        float cosTheta = max(dot(-rd, nor), 0.0);
        float fr       = fresnelSchlick(cosTheta, 0.04);
        vec3  refl     = reflect(rd, nor);

        // 反射分量采真实场景（地板棋盘），不是死天空
        col += att * fr * bounceEnv(pos + nor * 0.004, refl);

        float eta = inside ? IOR : (1.0 / IOR);
        vec3  refr;
        bool  ok = refractDir(rd, nor, eta, refr);

        if (!ok) {
            rd = refl;
            ro = pos + nor * 0.004;
        } else {
            att *= (1.0 - fr);
            if (inside) att *= exp(-hit.x * vec3(0.12, 0.04, 0.06));
            rd = refr;
            inside = !inside;
            ro = pos + rd * 0.004;
        }
    }

    col += att * sky(rd);
    return col;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 p = (2.0 * fragCoord - iResolution.xy) / iResolution.y;

    float an = 0.32 + 0.10 * sin(iTime * 0.15);
    vec3  ta = vec3(0.0, 0.95, 0.0);
    vec3  ro = vec3(4.0 * sin(an), 1.65, 4.0 * cos(an));
    mat3  ca = setCamera(ro, ta);
    vec3  rd = ca * normalize(vec3(p, 2.2));

    vec3 col = trace(ro, rd);
    col = pow(max(col, 0.0), vec3(0.4545));
    fragColor = vec4(col, 1.0);
}

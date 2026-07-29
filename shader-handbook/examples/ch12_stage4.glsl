// 第 12 章 · 阶梯实战 · 阶段 4：多球场景 + 天空渐变
// 漫反射球、金属球、玻璃球同框；玻璃路径与 stage3 一致（MAX_BOUNCE>=6）。
const vec3  SUN = normalize(vec3(0.55, 0.72, -0.42));
const int   MAX_BOUNCE = 8;
const float IOR = 1.45;

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

// y = 材质：1 地面，2 漫反射，3 金属，4 玻璃
vec2 map(vec3 ro, vec3 rd)
{
    float best = 1e20;
    float mat  = 0.0;

    float tp = iPlane(ro, rd);
    if (tp > 0.0) { best = tp; mat = 1.0; }

    float t1 = iSphere(ro, rd, vec3(-1.4, 0.55, 0.2), 0.55);
    if (t1 > 0.0 && t1 < best) { best = t1; mat = 2.0; }

    float t2 = iSphere(ro, rd, vec3(0.9, 0.70, -0.5), 0.70);
    if (t2 > 0.0 && t2 < best) { best = t2; mat = 3.0; }

    float t3 = iSphere(ro, rd, vec3(0.1, 1.05, 1.6), 1.05);
    if (t3 > 0.0 && t3 < best) { best = t3; mat = 4.0; }

    return (mat > 0.0) ? vec2(best, mat) : vec2(-1.0, 0.0);
}

vec3 getNormal(vec3 p, float mat)
{
    if (mat < 1.5) return vec3(0.0, 1.0, 0.0);
    if (mat < 2.5) return normalize(p - vec3(-1.4, 0.55, 0.2));
    if (mat < 3.5) return normalize(p - vec3(0.9, 0.70, -0.5));
    return normalize(p - vec3(0.1, 1.05, 1.6));
}

vec3 sky(vec3 rd)
{
    float h = clamp(rd.y, 0.0, 1.0);
    vec3  zen = vec3(0.18, 0.38, 0.72);
    vec3  hor = vec3(0.92, 0.78, 0.62);
    vec3  col = mix(hor, zen, pow(h, 0.55));
    col += vec3(1.0, 0.90, 0.70) * pow(max(dot(rd, SUN), 0.0), 48.0) * 0.45;
    return col;
}

// 阴影：玻璃轻度挡光，不投死黑圆斑
float shadowAtten(vec3 p, vec3 nor)
{
    vec3 ro = p + nor * 0.003 + SUN * 0.003;
    vec2 h = map(ro, SUN);
    if (h.x <= 0.0) return 1.0;
    if (h.y > 3.5) return 0.72; // 玻璃
    return 0.0;
}

vec3 shadeDiffuse(vec3 pos, vec3 nor, vec3 alb)
{
    float dif = max(dot(nor, SUN), 0.0);
    float sha = shadowAtten(pos, nor);
    float amb = 0.16 + 0.24 * max(nor.y, 0.0);
    return alb * (amb + dif * sha);
}

// 菲涅尔二次射线：地板/天空（跳过玻璃，防递归）
vec3 bounceEnv(vec3 ro, vec3 rd)
{
    float best = 1e20;
    float mat = 0.0;
    float tp = iPlane(ro, rd);
    if (tp > 0.0) { best = tp; mat = 1.0; }
    float t1 = iSphere(ro, rd, vec3(-1.4, 0.55, 0.2), 0.55);
    if (t1 > 0.0 && t1 < best) { best = t1; mat = 2.0; }
    float t2 = iSphere(ro, rd, vec3(0.9, 0.70, -0.5), 0.70);
    if (t2 > 0.0 && t2 < best) { best = t2; mat = 3.0; }
    if (mat < 0.5) return sky(rd);
    vec3 pos = ro + rd * best;
    if (mat < 1.5) {
        float chk = mod(floor(pos.x) + floor(pos.z), 2.0);
        vec3  alb = mix(vec3(0.32, 0.35, 0.38), vec3(0.72, 0.75, 0.78), chk);
        return shadeDiffuse(pos, vec3(0.0, 1.0, 0.0), alb);
    }
    if (mat < 2.5) return shadeDiffuse(pos, normalize(pos - vec3(-1.4, 0.55, 0.2)), vec3(0.78, 0.42, 0.32));
    // 金属：廉价天空反射
    vec3 nor = normalize(pos - vec3(0.9, 0.70, -0.5));
    return sky(reflect(rd, nor)) * vec3(0.85, 0.80, 0.72);
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
        float mat = hit.y;

        if (mat < 1.5) {
            float chk = mod(floor(pos.x) + floor(pos.z), 2.0);
            vec3  alb = mix(vec3(0.32, 0.35, 0.38), vec3(0.72, 0.75, 0.78), chk);
            col += att * shadeDiffuse(pos, nor, alb);
            return col;
        }
        if (mat < 2.5) {
            col += att * shadeDiffuse(pos, nor, vec3(0.78, 0.42, 0.32));
            return col;
        }
        if (mat < 3.5) {
            float spe = pow(max(dot(reflect(rd, nor), SUN), 0.0), 48.0);
            col += att * vec3(0.85, 0.80, 0.72) * spe * 0.7;
            att *= vec3(0.85, 0.80, 0.72);
            rd = reflect(rd, nor);
            ro = pos + nor * 0.004;
            continue;
        }

        // —— 玻璃 ——
        if (inside) nor = -nor;

        float cosTheta = max(dot(-rd, nor), 0.0);
        float fr       = fresnelSchlick(cosTheta, 0.04);
        vec3  refl     = reflect(rd, nor);

        col += att * fr * bounceEnv(pos + nor * 0.004, refl);

        float eta = inside ? IOR : (1.0 / IOR);
        vec3  refr;
        bool  ok = refractDir(rd, nor, eta, refr);

        if (!ok) {
            rd = refl;
            ro = pos + nor * 0.004;
        } else {
            att *= (1.0 - fr);
            if (inside) att *= exp(-hit.x * vec3(0.15, 0.05, 0.08));
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

    float an = 0.22 + 0.12 * sin(iTime * 0.11);
    vec3  ta = vec3(0.0, 0.65, 0.0);
    vec3  ro = vec3(5.5 * sin(an), 1.55, 5.5 * cos(an));
    mat3  ca = setCamera(ro, ta);
    vec3  rd = ca * normalize(vec3(p, 2.2));

    vec3 col = trace(ro, rd);
    col = pow(max(col, 0.0), vec3(0.4545));
    fragColor = vec4(col, 1.0);
}

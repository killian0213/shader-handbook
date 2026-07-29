// 第 12 章 · 阶梯实战 · 阶段 4：多球场景 + 天空渐变
// 漫反射球、金属球、玻璃球同框；天空渐变作 miss 色，各材质最多二次弹跳。
const vec3 SUN = normalize(vec3(0.55, 0.72, -0.42));
const int  MAX_BOUNCE = 2;
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

bool inShadow(vec3 p, vec3 nor)
{
    vec3 ro = p + nor * 0.002 + SUN * 0.002;
    return map(ro, SUN).x > 0.0;
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

vec3 shadeDiffuse(vec3 pos, vec3 nor, vec3 alb)
{
    float dif = max(dot(nor, SUN), 0.0);
    float sha = inShadow(pos, nor) ? 0.0 : 1.0;
    float amb = 0.16 + 0.24 * max(nor.y, 0.0);
    return alb * (amb + dif * sha);
}

bool refractDir(vec3 rd, vec3 nor, float eta, out vec3 outRd)
{
    float cosI = dot(-rd, nor);
    float sinT2 = eta * eta * (1.0 - cosI * cosI);
    if (sinT2 > 1.0) return false;
    outRd = normalize(eta * rd + (eta * cosI - sqrt(1.0 - sinT2)) * nor);
    return true;
}

float fresnelSchlick(vec3 rd, vec3 nor, float f0)
{
    float cosTheta = max(dot(-rd, nor), 0.0);
    return f0 + (1.0 - f0) * pow(1.0 - cosTheta, 5.0);
}

vec3 trace(vec3 ro, vec3 rd, bool inside, float curMat)
{
    vec3 col = vec3(0.0);
    vec3 att = vec3(1.0);

    for (int i = 0; i < MAX_BOUNCE; i++) {
        vec2 hit = map(ro, rd);
        if (hit.y <= 0.0) {
            col += att * sky(rd);
            break;
        }

        vec3 pos = ro + rd * hit.x;
        vec3 nor = getNormal(pos, hit.y);
        if (inside) nor = -nor;
        float mat = hit.y;

        if (mat < 1.5) {
            float chk = mod(floor(pos.x) + floor(pos.z), 2.0);
            vec3  alb = mix(vec3(0.32, 0.35, 0.38), vec3(0.72, 0.75, 0.78), chk);
            col += att * shadeDiffuse(pos, nor, alb);
            break;
        }
        if (mat < 2.5) {
            col += att * shadeDiffuse(pos, nor, vec3(0.78, 0.42, 0.32));
            break;
        }
        if (mat < 3.5) {
            float spe = pow(max(dot(reflect(rd, nor), SUN), 0.0), 48.0);
            if (i == MAX_BOUNCE - 1)
                col += att * (vec3(0.85, 0.80, 0.72) * spe * 0.7 + sky(reflect(rd, nor)) * 0.12);
            att *= vec3(0.85, 0.80, 0.72);
            rd = reflect(rd, nor);
            ro = pos + nor * 0.002;
            continue;
        }

        float eta = inside ? IOR : (1.0 / IOR);
        vec3  refr;
        vec3  refl = reflect(rd, nor);
        bool  ok   = refractDir(rd, nor, eta, refr);
        float fr   = fresnelSchlick(rd, nor, 0.04);
        rd = (!ok || fr > 0.5) ? refl : refr;
        att *= mix(vec3(1.0), vec3(0.97, 1.0, 1.03), 1.0 - fr);
        inside = !inside;
        ro = pos + rd * 0.002;
    }
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

    vec3 col = trace(ro, rd, false, 0.0);
    col = pow(col, vec3(0.4545));
    fragColor = vec4(col, 1.0);
}

// 第 12 章 · 阶梯实战 · 阶段 3：玻璃球（折射 + 菲涅尔 + TIR）
// 主球改为玻璃：Snell 折射、Schlick 菲涅尔、全内反射时走镜面，最多二次弹跳。
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

vec2 map(vec3 ro, vec3 rd)
{
    float tp = iPlane(ro, rd);
    float ts = iSphere(ro, rd, vec3(0.0, 1.0, 0.0), 1.0);
    if (tp > 0.0 && (ts < 0.0 || tp < ts)) return vec2(tp, 1.0);
    if (ts > 0.0) return vec2(ts, 2.0);
    return vec2(-1.0, 0.0);
}

vec3 getNormal(vec3 p, float mat)
{
    if (mat < 1.5) return vec3(0.0, 1.0, 0.0);
    return normalize(p - vec3(0.0, 1.0, 0.0));
}

bool inShadow(vec3 p, vec3 nor)
{
    vec3 ro = p + nor * 0.002 + SUN * 0.002;
    return map(ro, SUN).x > 0.0;
}

vec3 sky(vec3 rd)
{
    float h = clamp(rd.y * 0.5 + 0.5, 0.0, 1.0);
    vec3  col = mix(vec3(0.55, 0.72, 0.92), vec3(0.88, 0.92, 0.98), h);
    col += vec3(1.0, 0.92, 0.75) * pow(max(dot(rd, SUN), 0.0), 64.0) * 0.35;
    return col;
}

vec3 shadeDiffuse(vec3 pos, vec3 nor)
{
    float chk = mod(floor(pos.x) + floor(pos.z), 2.0);
    vec3  alb = mix(vec3(0.35, 0.38, 0.42), vec3(0.75, 0.78, 0.82), chk);
    float dif = max(dot(nor, SUN), 0.0);
    float sha = inShadow(pos, nor) ? 0.0 : 1.0;
    float amb = 0.18 + 0.22 * max(nor.y, 0.0);
    return alb * (amb + dif * sha);
}

// 折射；判别式 < 0 时返回 false 表示 TIR
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

vec3 traceGlass(vec3 ro, vec3 rd, bool inside)
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

        if (hit.y > 1.5) {
            float eta = inside ? IOR : (1.0 / IOR);
            vec3  refr;
            vec3  refl = reflect(rd, nor);
            bool  ok   = refractDir(rd, nor, eta, refr);
            float fr   = fresnelSchlick(rd, nor, 0.04);

            if (!ok) {
                rd = refl;
            } else {
                // 简化：一次采样折射或反射，不做 split
                rd = (fr > 0.5) ? refl : refr;
                att *= mix(vec3(1.0), vec3(0.98, 1.0, 1.02), 1.0 - fr);
            }
            inside = !inside;
            ro = pos + rd * 0.002;
        } else {
            col += att * shadeDiffuse(pos, nor);
            break;
        }
    }
    return col;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 p = (2.0 * fragCoord - iResolution.xy) / iResolution.y;

    float an = 0.28 + 0.10 * sin(iTime * 0.13);
    vec3  ta = vec3(0.0, 0.95, 0.0);
    vec3  ro = vec3(4.2 * sin(an), 1.45, 4.2 * cos(an));
    mat3  ca = setCamera(ro, ta);
    vec3  rd = ca * normalize(vec3(p, 2.2));

    vec3 col = traceGlass(ro, rd, false);
    col = pow(col, vec3(0.4545));
    fragColor = vec4(col, 1.0);
}

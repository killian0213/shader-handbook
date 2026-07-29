// 第 12 章 · 阶梯实战 · 阶段 2：镜面反射（金属球）
// 在阶段 1 基础上：主球改为金属，最多 2 次弹跳，看见地面与天空的反射。
const vec3 SUN = normalize(vec3(0.55, 0.72, -0.42));
const int  MAX_BOUNCE = 2;

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
    float t = -b - h;
    if (t < 0.001) t = -b + h;
    return (t > 0.001) ? t : -1.0;
}

// y = 材质：1 地面漫反射，2 金属球
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

vec3 trace(vec3 ro, vec3 rd)
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

        if (hit.y > 1.5) {
            // 金属：反射继续，同时叠一点太阳高光
            float spe = pow(max(dot(reflect(rd, nor), SUN), 0.0), 48.0);
            if (i == MAX_BOUNCE - 1) {
                col += att * (vec3(0.82, 0.78, 0.72) * spe * 0.8 + sky(reflect(rd, nor)) * 0.15);
            }
            att *= vec3(0.82, 0.78, 0.72);
            rd = reflect(rd, nor);
            ro = pos + nor * 0.002;
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

    vec3 col = trace(ro, rd);
    col = pow(col, vec3(0.4545));
    fragColor = vec4(col, 1.0);
}

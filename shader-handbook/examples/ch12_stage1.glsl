// 第 12 章 · 阶梯实战 · 阶段 1：解析求交与硬阴影
// 地面 + 球体、棋盘地面、Lambert 漫反射、朝太阳再打一条射线做硬阴影。
const vec3 SUN = normalize(vec3(0.55, 0.72, -0.42));

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

// x = t，y = 材质（1 地面，2 球）
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

// 硬阴影：从着色点朝太阳再求交一次，命中即被挡
bool inShadow(vec3 p, vec3 nor)
{
    vec3 ro = p + nor * 0.002 + SUN * 0.002;
    return map(ro, SUN).x > 0.0;
}

vec3 sky(vec3 rd)
{
    float h = clamp(rd.y * 0.5 + 0.5, 0.0, 1.0);
    return mix(vec3(0.55, 0.72, 0.92), vec3(0.88, 0.92, 0.98), h);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 p = (2.0 * fragCoord - iResolution.xy) / iResolution.y;

    float an = 0.28 + 0.10 * sin(iTime * 0.13);
    vec3  ta = vec3(0.0, 0.95, 0.0);
    vec3  ro = vec3(4.2 * sin(an), 1.45, 4.2 * cos(an));
    mat3  ca = setCamera(ro, ta);
    vec3  rd = ca * normalize(vec3(p, 2.2));

    vec2 hit = map(ro, rd);
    vec3 col = sky(rd);

    if (hit.y > 0.0) {
        vec3 pos = ro + rd * hit.x;
        vec3 nor = getNormal(pos, hit.y);

        vec3 albedo;
        if (hit.y < 1.5) {
            float chk = mod(floor(pos.x) + floor(pos.z), 2.0);
            albedo = mix(vec3(0.35, 0.38, 0.42), vec3(0.75, 0.78, 0.82), chk);
        } else {
            albedo = vec3(0.68, 0.64, 0.58);
        }

        float dif = max(dot(nor, SUN), 0.0);
        float sha = inShadow(pos, nor) ? 0.0 : 1.0;
        float amb = 0.18 + 0.22 * max(nor.y, 0.0);
        col = albedo * (amb + dif * sha);
    }

    col = pow(col, vec3(0.4545));
    fragColor = vec4(col, 1.0);
}

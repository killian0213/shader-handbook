// 第 12 章 · 焦散阶梯 · 阶段 7：折射近似 + 棋盘底焦散
// 不用完整光追：用法线扰动 UV ≈  cheap 折射，采样地板时坐标弯曲。
// 玻璃球/水面下方棋盘格被「挤密」处变亮 —— 焦散感的来源。

const vec3 SUN = normalize(vec3(0.45, 0.78, -0.42));

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
    vec3 oc = ro - c;
    float b = dot(oc, rd);
    float h = b * b - dot(oc, oc) + r * r;
    if (h < 0.0) return -1.0;
    h = sqrt(h);
    float t = -b - h;
    if (t < 0.001) t = -b + h;
    return (t > 0.001) ? t : -1.0;
}

vec2 hash22(vec2 p)
{
    p = fract(p * vec2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(vec2(p.x * p.y, p.y * p.x));
}

float voronoi(vec2 p)
{
    vec2 n = floor(p);
    vec2 f = fract(p);
    float md = 8.0;
    for (int j = -1; j <= 1; j++)
        for (int i = -1; i <= 1; i++) {
            vec2 g = vec2(float(i), float(j));
            vec2 o = hash22(n + g);
            o = 0.5 + 0.5 * sin(iTime * 0.5 + 6.28 * o);
            md = min(md, length(g + o - f));
        }
    return md;
}

float caustic(vec2 xz)
{
    vec2 q = xz + 0.25 * vec2(sin(xz.y * 2.5 + iTime), cos(xz.x * 2.2 - iTime));
    float v = voronoi(q * 3.5);
    return pow(1.0 - smoothstep(0.0, 0.5, v), 3.5);
}

vec3 sky(vec3 rd)
{
    float h = clamp(rd.y * 0.5 + 0.5, 0.0, 1.0);
    return mix(vec3(0.55, 0.72, 0.92), vec3(0.88, 0.94, 0.98), h);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 p = (2.0 * fragCoord - iResolution.xy) / iResolution.y;

    float an = 0.32 + 0.08 * sin(iTime * 0.12);
    vec3 ro = vec3(4.0 * sin(an), 1.35, 4.0 * cos(an));
    vec3 ta = vec3(0.0, 0.55, 0.0);
    mat3 ca = setCamera(ro, ta);
    vec3 rd = ca * normalize(vec3(p, 2.1));

    vec3 col = sky(rd);

    float tp = iPlane(ro, rd);
    float ts = iSphere(ro, rd, vec3(0.0, 0.85, 0.0), 0.75);

    if (tp > 0.0 && (ts < 0.0 || tp < ts)) {
        // 地板：直接命中
        vec3 pos = ro + rd * tp;
        vec2 uv = pos.xz;
        float chk = mod(floor(uv.x) + floor(uv.y), 2.0);
        vec3 alb = mix(vec3(0.32, 0.35, 0.40), vec3(0.78, 0.80, 0.84), chk);
        float dif = max(dot(vec3(0.0, 1.0, 0.0), SUN), 0.0);
        col = alb * (0.22 + 0.78 * dif);
        col += vec3(0.9, 0.98, 1.0) * caustic(uv) * 0.35;
    } else if (ts > 0.0) {
        // 玻璃球：菲涅尔反射 + 折射近似采样地板
        vec3 pos = ro + rd * ts;
        vec3 nor = normalize(pos - vec3(0.0, 0.85, 0.0));
        float fres = pow(1.0 - max(dot(-rd, nor), 0.0), 3.0);

        // cheap refract：用法线.xy 偏移地板 UV
        vec3 rdir = normalize(refract(rd, nor, 0.75));
        float t2 = iPlane(pos + nor * 0.01, rdir);
        vec3 refrCol = sky(rdir);
        if (t2 > 0.0) {
            vec3 fpos = pos + nor * 0.01 + rdir * t2;
            vec2 uv = fpos.xz + nor.xy * 0.35;
            float chk = mod(floor(uv.x) + floor(uv.y), 2.0);
            vec3 alb = mix(vec3(0.30, 0.33, 0.38), vec3(0.75, 0.78, 0.82), chk);
            float dif = max(dot(vec3(0.0, 1.0, 0.0), SUN), 0.0);
            refrCol = alb * (0.20 + 0.80 * dif);
            refrCol += vec3(1.0, 0.96, 0.82) * caustic(uv) * 0.55;
        }

        vec3 reflCol = sky(reflect(rd, nor));
        col = mix(refrCol, reflCol, fres * 0.55 + 0.12);
        col += vec3(1.0) * pow(max(dot(reflect(rd, nor), SUN), 0.0), 48.0) * 0.35;
    }

    col = pow(col, vec3(0.4545));
    fragColor = vec4(col, 1.0);
}

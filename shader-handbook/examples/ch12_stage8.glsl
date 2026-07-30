// 第 12 章 · 焦散阶梯 · 阶段 8：泳池综合展示
// 单 pass：波动水面法线 → 折射采样池底 + 伪焦散 + Fresnel 天空反射带。
// 控制在 ~160 行：够炫、够教，不展开完整光追。

const vec3 SUN = normalize(vec3(0.40, 0.82, -0.38));
const float POOL_Y = 0.0;
const float IOR = 1.33;

mat3 setCamera(vec3 ro, vec3 ta)
{
    vec3 cw = normalize(ta - ro);
    vec3 cu = normalize(cross(cw, vec3(0.0, 1.0, 0.0)));
    return mat3(cu, cross(cu, cw), cw);
}

float hash21(vec2 p)
{
    p = fract(p * vec2(234.34, 435.345));
    p += dot(p, p + 34.345);
    return fract(p.x * p.y);
}

vec2 voronoi(vec2 p)
{
    vec2 n = floor(p), f = fract(p);
    float md = 8.0; vec2 mg;
    for (int j = -1; j <= 1; j++)
        for (int i = -1; i <= 1; i++) {
            vec2 g = vec2(float(i), float(j));
            vec2 o = fract(sin((n + g) * mat2(127.1, 311.7, 269.5, 183.3)) * 43758.5453);
            o = 0.5 + 0.5 * sin(iTime * 0.7 + 6.283 * o);
            vec2 r = g + o - f;
            float d = dot(r, r);
            if (d < md) { md = d; mg = r; }
        }
    return vec2(sqrt(md), hash21(n + mg));
}

float caustic(vec2 xz)
{
    vec2 q = xz + 0.3 * vec2(sin(xz.y * 2.0 + iTime), cos(xz.x * 1.8 - iTime * 0.8));
    float v = voronoi(q * 4.0).x;
    float v2 = voronoi(q * 6.5 + 2.1).x;
    return pow(1.0 - smoothstep(0.0, 0.48, v), 3.0) * 0.7
         + pow(1.0 - smoothstep(0.0, 0.42, v2), 4.0) * 0.5;
}

vec3 poolTiles(vec2 xz)
{
    float chk = mod(floor(xz.x * 1.2) + floor(xz.y * 1.2), 2.0);
    return mix(vec3(0.08, 0.28, 0.38), vec3(0.15, 0.48, 0.58), chk);
}

vec3 sky(vec3 rd)
{
    float h = clamp(rd.y, 0.0, 1.0);
    vec3 col = mix(vec3(0.55, 0.78, 0.95), vec3(0.12, 0.38, 0.82), pow(h, 0.6));
    col += vec3(1.0, 0.92, 0.70) * pow(max(dot(rd, SUN), 0.0), 64.0) * 0.5;
    return col;
}

// Gerstner 式法线：多正弦叠加
vec3 waterNormal(vec2 xz)
{
    float t = iTime;
    vec2 g1 = vec2(0.9, 0.35), g2 = vec2(-0.6, 0.75);
    vec2 dx = 0.12 * g1 * 2.2 * cos(dot(g1, xz) * 2.2 + t * 1.4)
            + 0.08 * g2 * 3.1 * cos(dot(g2, xz) * 3.1 - t * 1.1);
    return normalize(vec3(-dx.x, 1.0, -dx.y));
}

vec3 shadeFloor(vec2 xz, vec3 nor)
{
    vec3 alb = poolTiles(xz);
    float dif = max(dot(nor, SUN), 0.0);
    vec3 col = alb * (0.18 + 0.82 * dif);
    col += vec3(0.85, 0.98, 1.0) * caustic(xz) * (0.6 + 0.4 * dif);
    return col;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 p = (2.0 * fragCoord - iResolution.xy) / iResolution.y;
    float an = 0.25 + 0.06 * sin(iTime * 0.1);
    vec3 ro = vec3(3.8 * sin(an), 1.15, 3.8 * cos(an));
    vec3 rd = setCamera(ro, vec3(0.0, 0.2, 0.0)) * normalize(vec3(p, 2.0));

    vec3 col = sky(rd);

    if (rd.y < -0.001) {
        float t = (POOL_Y - ro.y) / rd.y;
        vec3 pos = ro + rd * t;

        if (abs(pos.x) < 2.2 && abs(pos.z) < 2.2) {
            // 先当作看池底：用 floor 交点
            vec3 bnor = vec3(0.0, 1.0, 0.0);
            col = shadeFloor(pos.xz, bnor);

            // 若射线先碰到「水面高度场」，改走折射路径
            // 简化：在 floor 点反推水面位置，用法线扰动 UV
            vec3 wnor = waterNormal(pos.xz);
            vec3 rdir = normalize(refract(rd, wnor, 1.0 / IOR));
            vec2 uvOff = wnor.xz * 0.28;
            col = shadeFloor(pos.xz + uvOff, bnor);

            // Fresnel 天空反射条（掠射角亮）
            float fres = pow(1.0 - max(dot(-rd, wnor), 0.0), 4.0);
            col = mix(col, sky(reflect(rd, wnor)), fres * 0.55);

            // 水面高光
            col += vec3(1.0) * pow(max(dot(reflect(rd, wnor), SUN), 0.0), 128.0) * 0.45;
        } else {
            col = shadeFloor(pos.xz, vec3(0.0, 1.0, 0.0)) * 0.35;
        }
    }

    // 池壁：简单竖直边界
    float tWall = 1000.0;
    if (abs(rd.x) > 0.001) {
        float tw = (sign(rd.x) * 2.2 - ro.x) / rd.x;
        if (tw > 0.01 && tw < tWall) tWall = tw;
    }
    if (abs(rd.z) > 0.001) {
        float tw = (sign(rd.z) * 2.2 - ro.z) / rd.z;
        if (tw > 0.01 && tw < tWall) tWall = tw;
    }
    if (tWall < 100.0) {
        vec3 wpos = ro + rd * tWall;
        if (wpos.y > POOL_Y && wpos.y < 0.45) {
            vec3 wcol = mix(vec3(0.55, 0.72, 0.78), vec3(0.35, 0.58, 0.68), wpos.y / 0.45);
            col = mix(col, wcol, 0.85);
        }
    }

    col = pow(col, vec3(0.4545));
    fragColor = vec4(col, 1.0);
}

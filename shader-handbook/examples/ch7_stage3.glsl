// 第 7 章 · 阶梯实战 · 阶段 3：地面 + 天空 + Lambert
// 三件新东西：① map 里并进一个 y=0 平面，顺带把返回值改成 vec2(距离, 材质号)；
// ② 命中阈值从常数 0.001 改成相对精度 0.0015*t（不改就等着看远处的同心圆条纹）；
// ③ 最朴素的 Lambert：漫反射 + 一点半球环境光，最后补 gamma。
#define MAX_STEPS 90
#define MAX_DIST  30.0

const vec3 LIG = vec3(0.602, 0.341, -0.722);   // 已单位化的太阳方向：右后方，仰角约 20°

float sdSphere(vec3 p, float r) { return length(p) - r; }

// 有两个物体了，就必须知道命中的是谁 → 返回 vec2(距离, 材质号)
vec2 map(vec3 p)
{
    vec2 res = vec2(sdSphere(p - vec3(0.0, 1.0, 0.0), 1.0), 1.0);   // 主球
    float dp = p.y;                                                  // 地面：y=0 平面
    if (dp < res.x) res = vec2(dp, 2.0);
    return res;
}

// 返回 vec2(命中距离, 材质号)；材质号 < 0 表示什么都没撞到
vec2 raymarch(vec3 ro, vec3 rd)
{
    float t = 0.0;
    float m = -1.0;
    for (int i = 0; i < MAX_STEPS; i++) {
        vec2 h = map(ro + rd * t);
        // 相对精度：远处一个像素覆盖的世界尺度更大，允许更大的误差。
        // 写成常数 0.001，掠射到地面的光线就会耗尽步数，
        // 在远处铺出一圈圈同心的深浅条纹。
        if (h.x < 0.0015 * t) { m = h.y; break; }
        if (t > MAX_DIST) break;
        t += h.x;
    }
    return vec2(t, m);
}

vec3 calcNormal(vec3 pos)
{
    vec2 e = vec2(1.0, -1.0) * 0.5773 * 0.0015;
    return normalize(e.xyy * map(pos + e.xyy).x +
                     e.yyx * map(pos + e.yyx).x +
                     e.yxy * map(pos + e.yxy).x +
                     e.xxx * map(pos + e.xxx).x);
}

// 清晨的天空：地平线附近偏暖奶白，往上迅速转成蓝。
// pow(h, 0.45) 让过渡集中在靠近地平线的那一小段，和真实大气一致。
vec3 sky(vec3 rd)
{
    float h = clamp(rd.y, 0.0, 1.0);
    return mix(vec3(0.90, 0.74, 0.60), vec3(0.14, 0.30, 0.62), pow(h, 0.45));
}

mat3 setCamera(vec3 ro, vec3 ta, float cr)
{
    vec3 cw = normalize(ta - ro);
    vec3 cp = vec3(sin(cr), cos(cr), 0.0);
    vec3 cu = normalize(cross(cw, cp));
    vec3 cv = cross(cu, cw);
    return mat3(cu, cv, cw);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 p = (2.0 * fragCoord - iResolution.xy) / iResolution.y;

    float an = 0.28 + 0.10 * sin(iTime * 0.13);
    vec3  ta = vec3(0.0, 0.95, 0.0);
    vec3  ro = vec3(4.2 * sin(an), 1.45, 4.2 * cos(an));
    mat3  ca = setCamera(ro, ta, 0.0);
    vec3  rd = ca * normalize(vec3(p, 2.2));

    vec2  res = raymarch(ro, rd);
    float t   = res.x;
    vec3  col = sky(rd);

    if (res.y > 0.0) {
        vec3 pos = ro + rd * t;
        vec3 nor = calcNormal(pos);

        // 材质：地面暗哑，主球是一颗浅暖色的瓷球
        vec3 mate = (res.y < 1.5) ? vec3(0.68, 0.64, 0.58)
                                  : vec3(0.26, 0.26, 0.24);

        float dif = clamp(dot(nor, LIG), 0.0, 1.0);   // Lambert
        float amb = 0.5 + 0.5 * nor.y;                // 半球环境光：朝上更亮
        col = mate * (1.25 * dif + 0.28 * amb);
    }

    // 上面的光照是在线性空间算的，输出前必须转回显示空间
    col = pow(col, vec3(0.4545));
    fragColor = vec4(col, 1.0);
}

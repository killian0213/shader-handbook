// 第 9 章 · 阶梯实战 · 阶段 1：一个方向光的漫反射平涂
//
// 几何从这一阶段到最后一阶段【一个字都不改】：一个球（球心 (0,1,0)、半径 1）
// 压在一块地面（y=0）上。之后每一阶段只加一个光照或材质环节 ——
// 画面上多出来的东西，一定就是那一项的贡献。

// 主光方向（从表面【指向】光源）。刻意选成侧上光：
// 球会留下一整片暗面，这正是阶段 1 要暴露的问题。
#define SUN normalize(vec3(0.55, 0.65, -0.20))

// 场景。返回 x = 距离，y = 材质 id（0 = 地面，1 = 球）
vec2 map(vec3 p)
{
    float sph = length(p - vec3(0.0, 1.0, 0.0)) - 1.0;
    return (sph < p.y) ? vec2(sph, 1.0) : vec2(p.y, 0.0);
}

// 最短的球体步进：距离场当步长，撞到就停（第 7 章）。
// 本节的主角是着色，所以求交部分写到够用为止，不再讲究。
vec2 trace(vec3 ro, vec3 rd)
{
    float t = 0.02;
    for (int i = 0; i < 80; i++) {
        vec2 h = map(ro + rd * t);
        if (h.x < 0.002 * t) return vec2(t, h.y);
        t += h.x;
        if (t > 50.0) break;
    }
    return vec2(-1.0, 0.0);
}

// 中心差分法线（第 7 章）
vec3 calcNormal(vec3 p)
{
    vec2 e = vec2(0.0015, 0.0);
    return normalize(vec3(map(p + e.xyy).x - map(p - e.xyy).x,
                          map(p + e.yxy).x - map(p - e.yxy).x,
                          map(p + e.yyx).x - map(p - e.yyx).x));
}

mat3 setCamera(vec3 ro, vec3 ta)
{
    vec3 cw = normalize(ta - ro);
    vec3 cu = normalize(cross(cw, vec3(0.0, 1.0, 0.0)));
    return mat3(cu, cross(cu, cw), cw);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 p = (2.0 * fragCoord - iResolution.xy) / iResolution.y;

    // 相机只极缓地左右摇一点点，构图始终稳定 —— 方便逐阶段对比
    float an = 0.42 + 0.08 * sin(iTime * 0.18);
    vec3  ro = vec3(3.95 * sin(an), 1.45, 3.95 * cos(an));
    vec3  rd = setCamera(ro, vec3(0.0, 0.92, 0.0)) * normalize(vec3(p, 1.7));

    // 天空：这一阶段先用一块平色，好让人只盯着物体的明暗
    vec3 col = vec3(0.18, 0.26, 0.44);

    vec2 h = trace(ro, rd);
    if (h.x > 0.0) {
        vec3 pos = ro + rd * h.x;
        vec3 nor = calcNormal(pos);

        // 材质这一阶段只有一个 base color
        vec3 albedo = (h.y < 0.5) ? vec3(0.16, 0.15, 0.14)    // 地面
                                  : vec3(0.62, 0.13, 0.07);   // 球

        // 唯一的一项光照：Lambert 漫反射（9.2）
        float dif = clamp(dot(nor, SUN), 0.0, 1.0);
        col = albedo * dif * vec3(1.35, 1.10, 0.80);
    }

    // 全程在【线性空间】里算光，最后一步才转 sRGB。
    // 这不是打磨，是从第一行就该做对的事（9.9）
    col = pow(col, vec3(0.4545));
    fragColor = vec4(col, 1.0);
}

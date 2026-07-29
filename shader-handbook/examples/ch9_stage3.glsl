// 第 9 章 · 阶梯实战 · 阶段 3：Blinn-Phong 高光
// 新增：半角向量 hal、每种材质自己的「高光强度 ks + 高光指数 shi」。
// 从这一步开始，球从"一块橡皮"变成"一个有表面的东西"。
#define SUN normalize(vec3(0.55, 0.65, -0.20))

vec2 map(vec3 p)
{
    float sph = length(p - vec3(0.0, 1.0, 0.0)) - 1.0;
    return (sph < p.y) ? vec2(sph, 1.0) : vec2(p.y, 0.0);
}

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

vec3 envColor(vec3 rd)
{
    float h = rd.y;
    vec3 horizon = vec3(0.42, 0.50, 0.62);
    vec3 col = (h > 0.0)
        ? mix(horizon, vec3(0.06, 0.14, 0.36), pow( h, 0.55))
        : mix(horizon, vec3(0.10, 0.09, 0.085), pow(-h, 0.35));
    col += vec3(1.00, 0.72, 0.42) * pow(clamp(dot(rd, SUN), 0.0, 1.0), 40.0) * 1.5;
    return col;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 p = (2.0 * fragCoord - iResolution.xy) / iResolution.y;

    float an = 0.42 + 0.08 * sin(iTime * 0.18);
    vec3  ro = vec3(3.95 * sin(an), 1.45, 3.95 * cos(an));
    vec3  rd = setCamera(ro, vec3(0.0, 0.92, 0.0)) * normalize(vec3(p, 1.7));

    vec3 col = envColor(rd);

    vec2 h = trace(ro, rd);
    if (h.x > 0.0) {
        vec3 pos = ro + rd * h.x;
        vec3 nor = calcNormal(pos);

        vec3 albedo = (h.y < 0.5) ? vec3(0.16, 0.15, 0.14)
                                  : vec3(0.62, 0.13, 0.07);
        // --- 新增：材质多了两个参数。地面是哑光的，球是抛光的 ---
        float ks  = (h.y < 0.5) ? 0.12 : 1.00;    // 高光有多强
        float shi = (h.y < 0.5) ? 10.0 : 48.0;    // 高光有多锐

        float dif = clamp(dot(nor, SUN), 0.0, 1.0);
        float sky = sqrt(clamp(0.5 + 0.5 * nor.y, 0.0, 1.0));
        float bou = clamp(0.25 - 0.75 * nor.y, 0.0, 1.0);

        vec3 lin = vec3(0.0);
        lin += dif * vec3(1.35, 1.10, 0.80);
        lin += sky * vec3(0.22, 0.34, 0.55);
        lin += bou * vec3(0.13, 0.10, 0.07);
        col = albedo * lin;

        // --- 新增：Blinn-Phong 高光（9.2）---
        // hal 是半角向量：法线正好指向它时，太阳光被镜面反射进相机
        vec3  hal = normalize(SUN - rd);
        float spe = pow(clamp(dot(nor, hal), 0.0, 1.0), shi);
        // 乘 dif：背光面不可能有高光。这一乘是必须的，否则暗面会浮出一块假亮斑
        // 高光【加】在最后，而且不乘 albedo —— 它是表面反射，不带物体的体色
        col += ks * spe * dif * vec3(1.10, 0.95, 0.75);
    }

    col = pow(col, vec3(0.4545));
    fragColor = vec4(col, 1.0);
}

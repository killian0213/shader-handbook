// 第 9 章 · 阶梯实战 · 阶段 5：两种遮蔽 —— 软阴影 + 环境光遮蔽
// 新增：calcSoftshadow（乘在直射光上）和 calcAO（乘在间接光上）。
// 这一步球才真正"落"在地上。
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

// --- 新增：iq 的软阴影（9.3）---
// 沿光线走，用 h/t 估计"遮挡物对光源张开多大的角"，取一路上的最小值。
// k=10：越大阴影越硬。24 步够了，因为遮挡物只有一个球。
float calcSoftshadow(vec3 ro, vec3 rd)
{
    float res = 1.0;
    // 起点必须抬离表面：主步进的命中阈值是 0.002*t，落点可能已经陷进去几个千分之一，
    // 此时 map 返回负数 → res=0 → 满屏黑麻点（self-shadow acne）。0.05 一劳永逸。
    float t = 0.05;
    for (int i = 0; i < 24; i++) {
        float h = map(ro + rd * t).x;
        res = min(res, clamp(10.0 * h / t, 0.0, 1.0));
        t += clamp(h, 0.03, 0.35);    // 步长设下限，防止贴着表面原地磨
        if (res < 0.005 || t > 8.0) break;
    }
    return res;
}

// --- 新增：环境光遮蔽（9.4）---
// 沿法线往外采 5 个点。空旷处 map 恰好等于 h（差为 0）；
// 有东西挡着时 map < h，差就是遮挡量。
float calcAO(vec3 pos, vec3 nor)
{
    float occ = 0.0, sca = 1.0;
    for (int i = 0; i < 5; i++) {
        float h = 0.02 + 0.22 * float(i) / 4.0;   // 采样半径要和场景尺度匹配
        occ += (h - map(pos + h * nor).x) * sca;
        sca *= 0.92;                              // 越远的采样点权重越低
    }
    return clamp(1.0 - 2.2 * occ, 0.0, 1.0);
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

        vec3  albedo = (h.y < 0.5) ? vec3(0.16, 0.15, 0.14)
                                   : vec3(0.62, 0.13, 0.07);
        float ks  = (h.y < 0.5) ? 0.12 : 1.00;
        float shi = (h.y < 0.5) ? 10.0 : 48.0;

        float dif = clamp(dot(nor, SUN), 0.0, 1.0);
        float sky = sqrt(clamp(0.5 + 0.5 * nor.y, 0.0, 1.0));
        float bou = clamp(0.25 - 0.75 * nor.y, 0.0, 1.0);
        float fre = pow(clamp(1.0 + dot(nor, rd), 0.0, 1.0), 5.0);

        // 背光面本来就是 0，没必要再打一条阴影射线（9.3 的生产级技巧）
        float sha = (dif > 0.001) ? calcSoftshadow(pos, SUN) : 0.0;
        float occ = calcAO(pos, nor);

        // 分工要严格：直射光乘 sha，间接光乘 occ。
        // 把 occ 也乘到太阳项上，阴影区就会双倍变黑，画面立刻发脏
        vec3 lin = vec3(0.0);
        lin += dif * sha * vec3(1.35, 1.10, 0.80);
        lin += sky * occ * vec3(0.22, 0.34, 0.55);
        lin += bou * occ * vec3(0.13, 0.10, 0.07);
        col = albedo * lin;

        vec3  hal = normalize(SUN - rd);
        float spe = pow(clamp(dot(nor, hal), 0.0, 1.0), shi);
        col += ks * spe * dif * sha * vec3(1.10, 0.95, 0.75);   // 高光也在阴影里熄灭

        // 边缘光反射的是环境，所以也要乘 occ：贴着地面的那一圈看不到天空
        col += ks * fre * sky * occ * envColor(reflect(rd, nor)) * 0.60;
    }

    col = pow(col, vec3(0.4545));
    fragColor = vec4(col, 1.0);
}

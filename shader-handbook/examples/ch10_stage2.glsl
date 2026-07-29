// 第 10 章 · 阶梯实战 · 阶段 2：沿线积分（吸收 + 发光）
// 新东西：固定步长穿过密度球，每步「自己发光 × 前面累计透过率」。
// 关掉发光只剩透过 → 退回阶段 1；漏乘 T → 塑料棉花糖。
#define STEPS 48

const float SIGMA_T = 2.2;             // 消光
const float SIGMA_S = 2.0;             // 散射（≈发光强度）
const vec3  ALBEDO = vec3(1.00, 0.72, 0.45);

float density(vec3 p)
{
    float d = length(p) - 0.80;
    // 软边缘：比硬球更像一团雾
    return clamp(0.55 - d * 1.8, 0.0, 1.0);
}

vec3 sky(vec3 rd)
{
    return mix(vec3(0.12, 0.16, 0.28), vec3(0.55, 0.70, 0.95),
               0.5 + 0.5*rd.y);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = (2.0*fragCoord - iResolution.xy) / iResolution.y;

    // 慢转，方便看体积感
    float a = iTime * 0.25;
    vec3  ro = vec3(sin(a)*2.6, 0.35, cos(a)*2.6);
    vec3  ta = vec3(0.0);
    vec3  ww = normalize(ta - ro);
    vec3  uu = normalize(cross(ww, vec3(0.0, 1.0, 0.0)));
    vec3  vv = cross(uu, ww);
    vec3  rd = normalize(uv.x*uu + uv.y*vv + 1.7*ww);

    // 只在包围盒附近积分
    float tMin = 0.0, tMax = 5.0;
    float dt   = (tMax - tMin) / float(STEPS);

    float T   = 1.0;                   // 累计透过率
    vec3  col = vec3(0.0);

    for (int i = 0; i < STEPS; i++) {
        vec3  p = ro + rd * (tMin + (float(i) + 0.5) * dt);
        float d = density(p);
        if (d > 1e-4) {
            float sigmaT = SIGMA_T * d;
            float absorb = exp(-sigmaT * dt);
            // 源项：简单各向同性自发光（阶段 5 再换成太阳×相函数）
            vec3  emit = ALBEDO * (SIGMA_S * d);
            // ★ 关键：先乘当前 T，再更新 T
            col += T * emit * dt;
            T   *= absorb;
            if (T < 0.01) break;
        }
    }

    col += T * sky(rd);                // 背景也要乘剩余透过率

    fragColor = vec4(col, 1.0);
}

// 第 9 章 · 阶梯实战 · 阶段 6：Fresnel 边缘光 —— 金属 vs 电介质
// 并排两球：左金属（高 F0、强 rim），右电介质（低 F0、弱 rim）。
// Schlick 近似：F = F0 + (1-F0)(1-cosθ)^5，掠射角差异一目了然。
#define SUN normalize(vec3(0.55, 0.65, -0.20))

vec2 map(vec3 p)
{
    float sphL = length(p - vec3(-1.15, 1.0, 0.0)) - 0.85;
    float sphR = length(p - vec3( 1.15, 1.0, 0.0)) - 0.85;
    float sph  = min(sphL, sphR);
    float id   = (sphL < sphR) ? 1.0 : 2.0;
    return (sph < p.y) ? vec2(sph, id) : vec2(p.y, 0.0);
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
        ? mix(horizon, vec3(0.06, 0.14, 0.36), pow(h, 0.55))
        : mix(horizon, vec3(0.10, 0.09, 0.085), pow(-h, 0.35));
    col += vec3(1.00, 0.72, 0.42) * pow(clamp(dot(rd, SUN), 0.0, 1.0), 40.0) * 1.5;
    return col;
}

// Schlick Fresnel
vec3 fresnelSchlick(float cosTheta, vec3 F0)
{
    return F0 + (1.0 - F0) * pow(clamp(1.0 - cosTheta, 0.0, 1.0), 5.0);
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
        float cosTheta = clamp(dot(nor, -rd), 0.0, 1.0);

        bool isMetal = (h.y < 1.5);
        vec3 albedo = isMetal ? vec3(0.85, 0.72, 0.35)   // 金
                              : vec3(0.15, 0.42, 0.78);  // 塑料蓝
        vec3 F0 = isMetal ? albedo : vec3(0.04);         // 金属 F0≈albedo，电介质≈0.04

        vec3 F = fresnelSchlick(cosTheta, F0);

        float dif = clamp(dot(nor, SUN), 0.0, 1.0);
        float sky = sqrt(clamp(0.5 + 0.5 * nor.y, 0.0, 1.0));

        vec3 refl = envColor(reflect(rd, nor));

        // 金属：反射主导；电介质：漫反射 + 弱反射
        vec3 spec = refl * F;
        vec3 diff = isMetal ? vec3(0.0) : albedo * (1.0 - F) * dif * vec3(1.2, 1.0, 0.85);

        vec3 lin = diff;
        lin += spec * (0.6 + 0.4 * dif);
        lin += sky * albedo * (isMetal ? 0.05 : 0.25);

        // 额外 rim 强调边缘（教学用）
        float rim = pow(1.0 - cosTheta, 3.0);
        lin += (isMetal ? vec3(1.0, 0.85, 0.5) : vec3(0.3, 0.5, 0.9)) * rim * (isMetal ? 0.6 : 0.15);

        col = lin;
    }

    col = pow(col, vec3(0.4545));
    fragColor = vec4(col, 1.0);
}

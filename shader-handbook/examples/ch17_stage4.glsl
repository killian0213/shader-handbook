// 第 17 章 · 代码高尔夫 · 阶段 4：可读微 Raymarcher（iq 式短而清晰）
// 对比 156 字符 Microraymarcher：这里保留 map / normal / sky / gamma，不揉变量。
// 场景：地面 + 中心球体 + 渐变天空 —— 标准步进，不是 p*= 压缩步进。

#define MAX_STEPS 64
#define MAX_DIST  20.0

vec2 mapScene(vec3 p)
{
    float sphere = length(p - vec3(0.0, 0.55, 0.0)) - 0.45;
    float ground = p.y;
    if (sphere < ground) return vec2(sphere, 1.0);
    return vec2(ground, 2.0);
}

vec3 calcNormal(vec3 p)
{
    vec2 e = vec2(0.001, -0.001);
    return normalize(e.xyy * mapScene(p + e.xyy).x +
                     e.yyx * mapScene(p + e.yyx).x +
                     e.yxy * mapScene(p + e.yxy).x +
                     e.xxx * mapScene(p + e.xxx).x);
}

vec3 skyColor(vec3 rd)
{
    float h = 0.5 + 0.5 * rd.y;
    return mix(vec3(0.05, 0.08, 0.18), vec3(0.35, 0.55, 0.95), h);
}

vec3 shade(vec3 p, vec3 n, vec3 rd, float matId)
{
    vec3 lightDir = normalize(vec3(0.55, 0.75, -0.35));
    float diff = clamp(dot(n, lightDir), 0.0, 1.0);
    vec3 sky = skyColor(reflect(rd, n));

    if (matId < 1.5) {
        vec3 base = vec3(0.85, 0.35, 0.28);
        float spec = pow(clamp(dot(reflect(-lightDir, n), -rd), 0.0, 1.0), 32.0);
        float fres = pow(1.0 - clamp(dot(n, -rd), 0.0, 1.0), 3.0);
        return base * (0.15 + 0.85 * diff) + spec * 0.35 + sky * fres * 0.25;
    }

    vec3 base = vec3(0.12, 0.13, 0.16);
    float spec = pow(clamp(dot(reflect(-lightDir, n), -rd), 0.0, 1.0), 8.0);
    return base * (0.2 + 0.8 * diff) + spec * 0.08;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = (2.0 * fragCoord - iResolution.xy) / iResolution.y;
    vec3 ro = vec3(0.0, 1.1, 3.2);
    vec3 ta = vec3(0.0, 0.45, 0.0);
    vec3 cw = normalize(ta - ro);
    vec3 cu = normalize(cross(cw, vec3(0.0, 1.0, 0.0)));
    vec3 cv = cross(cu, cw);
    vec3 rd = normalize(uv.x * cu + uv.y * cv + 1.8 * cw);

    float t = 0.0;
    float matId = -1.0;
    for (int i = 0; i < MAX_STEPS; i++) {
        vec2 h = mapScene(ro + rd * t);
        if (h.x < 0.001 * t) { matId = h.y; break; }
        if (t > MAX_DIST) break;
        t += h.x;
    }

    vec3 col = skyColor(rd);
    if (matId > 0.0) {
        vec3 p = ro + rd * t;
        vec3 n = calcNormal(p);
        col = shade(p, n, rd, matId);
        col = mix(col, skyColor(rd), 1.0 - exp(-0.015 * t * t));
    }

    col = pow(col, vec3(0.4545));
    fragColor = vec4(col, 1.0);
}

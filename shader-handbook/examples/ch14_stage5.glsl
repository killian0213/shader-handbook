// 第 14 章 · 阶梯实战 · 阶段 5：鼠标涟漪池
// 多个波源，其中一个跟着 iMouse（若 iMouse.z<=0 则自动跳）；水池感 + 高光。
// 真版 = 双 Buffer 波方程；这里用解析叠加建立「多源干涉 + 鼠标扰动」直觉。
float hash11(float n) { return fract(sin(n) * 43758.5453); }

vec2 autoRipplePos(float t)
{
    return 0.55 * vec2(sin(t * 0.73 + 1.2), cos(t * 0.61 + 0.8));
}

float rippleWave(vec2 p, vec2 c, float t, float gain)
{
    float r = length(p - c);
    float w = sin(38.0 * r - 7.0 * t) * exp(-1.8 * r) * exp(-0.25 * t);
    w *= smoothstep(0.0, 0.04, t - r * 0.85);
    return w * gain;
}

float waveHeight(vec2 p, vec2 mouseSrc, float time)
{
    float h = 0.0;
    const int SRC = 6;
    for (int i = 0; i < SRC; i++) {
        float fi = float(i);
        vec2 c = (i == 0) ? mouseSrc :
                 0.65 * vec2(sin(fi * 2.17 + 0.5), cos(fi * 1.83 + 1.1));
        float t0 = (i == 0) ? 0.0 : fi * 0.7;
        float t  = max(time - t0, 0.0);
        h += rippleWave(p, c, t, i == 0 ? 1.3 : 0.85);
    }
    return h;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = (2.0 * fragCoord - iResolution.xy) / iResolution.y;

    vec2 mouseSrc;
    if (iMouse.z > 0.0) {
        mouseSrc = (2.0 * iMouse.xy - iResolution.xy) / iResolution.y;
    } else {
        float jumpT = floor(iTime * 1.5);
        float blend = fract(iTime * 1.5);
        vec2 a = autoRipplePos(jumpT * 2.1);
        vec2 b = autoRipplePos((jumpT + 1.0) * 2.1);
        mouseSrc = mix(a, b, smoothstep(0.0, 1.0, blend));
    }

    float h = waveHeight(uv, mouseSrc, iTime);

    float poolR = 0.88;
    float edge  = smoothstep(poolR, poolR - 0.04, length(uv));
    h *= edge;

    vec2 eps = vec2(0.004, 0.0);
    float hx = waveHeight(uv + eps, mouseSrc, iTime) - waveHeight(uv - eps, mouseSrc, iTime);
    float hy = waveHeight(uv + eps.yx, mouseSrc, iTime) - waveHeight(uv - eps.yx, mouseSrc, iTime);
    vec3 nrm = normalize(vec3(-hx, -hy, 0.35));
    vec3 lgt = normalize(vec3(0.4, 0.6, 0.7));
    float spec = pow(max(dot(nrm, lgt), 0.0), 48.0);

    vec3 deep = vec3(0.03, 0.08, 0.18);
    vec3 shallow = vec3(0.15, 0.45, 0.72);
    vec3 col = mix(deep, shallow, 0.5 + 0.5 * h);
    col += vec3(0.5, 0.75, 1.0) * spec * (0.4 + 0.3 * h);
    col += vec3(0.3, 0.55, 0.9) * pow(abs(h), 3.0) * 0.35;
    col += vec3(0.6, 0.8, 1.0) * smoothstep(0.02, 0.0, abs(length(uv) - poolR)) * 0.5;

    col *= edge + 0.05;
    fragColor = vec4(clamp(col, 0.0, 1.0), 1.0);
}

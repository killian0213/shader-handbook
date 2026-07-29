// 第 14 章 · 阶梯实战 · 阶段 2：波方程的「样子」
// 真波方程要双历史 Buffer（u^{n}, u^{n-1}）。这里用解析涟漪叠加，
// 先建立「干涉 / 衰减 / 色散」的视觉直觉。
void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = (2.0*fragCoord - iResolution.xy) / iResolution.y;

    float h = 0.0;
    for (int i = 0; i < 5; i++) {
        float fi = float(i);
        vec2  c  = 0.7 * vec2(sin(fi*1.7+0.3), cos(fi*2.3+1.1));
        // 每个源不同时刻「丢石头」
        float t0 = fi * 0.85;
        float t  = max(iTime - t0, 0.0);
        float r  = length(uv - c);
        float w  = sin(40.0*r - 8.0*t) * exp(-2.2*r) * exp(-0.35*t);
        // 波前尚未到达时为 0（因果性）
        w *= smoothstep(0.0, 0.05, t - r*0.9);
        h += w;
    }

    vec3 col = mix(vec3(0.05, 0.10, 0.20), vec3(0.70, 0.90, 1.00), 0.5+0.5*h);
    col += vec3(0.3, 0.6, 1.0) * pow(abs(h), 3.0) * 0.4;
    fragColor = vec4(col, 1.0);
}

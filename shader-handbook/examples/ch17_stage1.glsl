// 第 17 章 · 代码高尔夫 · 阶段 1：Creation 可读教学版
// 经典 Silexars「Creation」隧道/等离子：居中 UV + 径向扭曲 + RGB 相位错开 + 网格辉光。
// 目标：把高尔夫里每一行都翻译成「它在算什么」——不是背压缩技巧。
//
// 高尔夫对照：
//   uv += p/l * (sin(z)+1.) * abs(sin(l*9.-z-z));
//   c[i] = .01 / length(mod(uv,1.)-.5);

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec3 color = vec3(0.0);
    float radiusLen = 0.0;
    float phase = iTime;

    // 同一扭曲算三遍，分别写入 R/G/B；phase 每通道 +0.07 → 色散拖尾
    for (int channel = 0; channel < 3; channel++) {
        // 像素坐标 → [0,1]，再居中并校正宽高比（16:9 下圆不变椭圆）
        vec2 uv = fragCoord / iResolution.xy;
        vec2 centered = uv - 0.5;
        centered.x *= iResolution.x / iResolution.y;

        phase += 0.07;
        radiusLen = length(centered);

        // 径向单位向量：从画面中心指向当前像素
        vec2 radialDir = centered / max(radiusLen, 1e-4);

        // 时间脉动 0..2 + 随半径的环状条纹（l*9 是环密度，2*phase 让环随时间转）
        float pulse = sin(phase) + 1.0;
        float rings = abs(sin(radiusLen * 9.0 - 2.0 * phase));
        float radialPush = pulse * rings;

        // 核心扭曲：沿径向把 UV 推出去 → 隧道/等离子感
        uv += radialDir * radialPush;

        // mod 到单位格，取到最近格心的向量；1/length = 经典点阵辉光
        vec2 cellCenter = mod(uv, 1.0) - 0.5;
        float glow = 0.01 / length(cellCenter);
        color[channel] = glow;
    }

    // 除以半径：中心更亮、边缘衰减； vignette 让 720×405 更耐看
    vec3 col = color / max(radiusLen, 0.15);
    vec2 vignUv = fragCoord / iResolution.xy;
    col *= pow(16.0 * vignUv.x * vignUv.y * (1.0 - vignUv.x) * (1.0 - vignUv.y), 0.12);

    fragColor = vec4(col, 1.0);
}

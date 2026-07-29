void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    // 1. 坐标归一化：中心为原点，纵向 [-1,1]
    vec2 uv = (2.0 * fragCoord - iResolution.xy) / iResolution.y;

    // 2. 鼠标位置，未点击时自动绕圈
    vec2 m;
    if (iMouse.z > 0.0) m = (2.0 * iMouse.xy - iResolution.xy) / iResolution.y;
    else                m = 0.5 * vec2(cos(iTime), sin(iTime * 0.7));

    // 3. 一个跟随鼠标的圆的有符号距离
    float d = length(uv - m) - 0.25;

    // 4. 抗锯齿：过渡带宽度取一个像素
    float px = 2.0 / iResolution.y;
    float shape = smoothstep(px, -px, d);

    // 5. 背景用余弦调色板做渐变（第 4 章详解）
    vec3 bg = 0.5 + 0.5 * cos(iTime + uv.xyx + vec3(0.0, 2.0, 4.0));

    // 6. 合成：先辉光（加法），再实体（mix）
    vec3 col = bg * 0.35;
    col += vec3(1.0, 0.6, 0.2) * exp(-max(d, 0.0) * 8.0) * 0.6;
    col = mix(col, vec3(1.0, 0.95, 0.9), shape);

    // 7. gamma 校正后输出
    fragColor = vec4(pow(col, vec3(0.4545)), 1.0);
}

// 阶段 2：加一个太阳（圆形 SDF + 垂直渐变）
const float HORIZON = -0.15;

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = (2.0 * fragCoord - iResolution.xy) / iResolution.y;

    float t = clamp(uv.y - HORIZON, 0.0, 1.0);
    vec3 col = mix(vec3(1.00, 0.30, 0.45), vec3(0.04, 0.01, 0.16), t);

    // 太阳：圆形有符号距离场，sd < 0 表示在圆内
    vec2  sp = uv - vec2(0.0, 0.30);
    float sd = length(sp) - 0.32;

    // 盘面自身的颜色渐变：顶部偏黄，底部偏品红
    vec3 sunCol = mix(vec3(1.00, 0.95, 0.35), vec3(1.00, 0.15, 0.45),
                      clamp(0.5 - sp.y * 1.5, 0.0, 1.0));

    col = mix(col, sunCol, smoothstep(0.004, -0.004, sd));

    fragColor = vec4(col, 1.0);
}

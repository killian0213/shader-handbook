// 第 6 章 · 阶梯实战 · 阶段 1：极坐标底盘
// 先把 r 用起来：径向渐变 + 同心环。一个字符的花瓣都还没有。
const float TAU = 6.2831853;

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 p = (2.0 * fragCoord - iResolution.xy) / iResolution.y;

    float r = length(p);

    // 底色：中心偏暖、向外偏冷。曼陀罗需要一个"从中心发散"的底子。
    vec3 col = mix(vec3(0.16, 0.06, 0.14), vec3(0.02, 0.02, 0.06),
                   smoothstep(0.0, 1.10, r));

    // 同心环：k 的整数部分是环号，小数部分是环内进度
    float k    = r * 14.0;
    float ring = (abs(fract(k) - 0.5) - 0.18) / 14.0;  // 除以 14 换回屏幕尺度
    col += vec3(0.10, 0.06, 0.16) * smoothstep(0.004, 0.0, ring);

    fragColor = vec4(col, 1.0);
}

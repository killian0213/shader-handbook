// 阶段 1：坐标系 + 天空渐变
const float HORIZON = -0.15;

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    // 屏幕中心为原点，纵向范围固定为 [-1, 1]，横向随宽高比伸展
    vec2 uv = (2.0 * fragCoord - iResolution.xy) / iResolution.y;

    // t: 0 = 地平线，1 = 天顶
    float t = clamp(uv.y - HORIZON, 0.0, 1.0);
    vec3 col = mix(vec3(1.00, 0.30, 0.45), vec3(0.04, 0.01, 0.16), t);

    fragColor = vec4(col, 1.0);
}

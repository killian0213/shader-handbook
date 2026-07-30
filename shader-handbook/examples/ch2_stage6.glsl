// 第 2 章 · 坐标阶梯 · 阶段 6：2.5D 假透视公路
// 经典 demoscene 地板：y' = 1/y 把远处压向地平线，mod 做流动虚线。
// 不是真 3D，而是坐标变换 + 分层上色；足够炫且只有几十行。

const float TAU = 6.2831853;
const float HORIZON = 0.12;

float hash11(float p)
{
    return fract(sin(p * 127.1) * 43758.5453);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = fragCoord / iResolution.xy;
    vec2 p = (2.0 * fragCoord - iResolution.xy) / iResolution.y;

    // 天空 + 太阳
    float skyT = clamp((p.y - HORIZON) / (1.0 - HORIZON), 0.0, 1.0);
    vec3 sky = mix(vec3(0.95, 0.72, 0.45), vec3(0.18, 0.42, 0.82), pow(skyT, 0.65));
    vec2 sunP = vec2(0.35, 0.55);
    sky += vec3(1.0, 0.92, 0.65) * exp(-dot(p - sunP, p - sunP) * 18.0) * 1.2;
    sky += vec3(1.0, 0.85, 0.55) * pow(max(0.0, 1.0 - length(p - sunP) * 1.5), 8.0) * 0.4;

    vec3 col = sky;

    // 地面区域：y < HORIZON 在屏幕下方（路面占大半屏）
    if (p.y < HORIZON) {
        // 透视：距地平线越远（y 越小），1/(HORIZON - y) 越大 → 纹理越密
        float depth = HORIZON - p.y;
        float z = 1.0 / depth;
        float x = p.x * z;

        // 流动速度随深度增加（近处快、远处慢 —— 视觉正确）
        float scroll = iTime * 2.5;
        float lane = abs(fract(x * 0.35) - 0.5);
        float dash = smoothstep(0.08, 0.02, lane)
                   * smoothstep(0.45, 0.05, abs(fract(z * 0.55 - scroll) - 0.5));

        // 横向网格线
        float gridY = smoothstep(0.04, 0.0, abs(fract(z * 0.22 - scroll * 0.35) - 0.5));

        float fog = clamp(depth * 2.8, 0.0, 1.0);
        vec3 road = mix(vec3(0.08, 0.09, 0.12), vec3(0.22, 0.24, 0.30), fog);
        road = mix(road, vec3(0.35, 0.38, 0.42), gridY * 0.35);
        road = mix(road, vec3(1.0, 0.95, 0.55), dash * 0.85);

        // 中路白条
        float center = exp(-abs(x) * 6.0);
        road += vec3(1.0, 0.92, 0.70) * center * 0.12;

        // 路边暗化
        float edge = smoothstep(0.85, 0.35, abs(x));
        road *= 0.55 + 0.45 * edge;

        col = road;

        // 地平线辉光
        col = mix(col, vec3(0.95, 0.78, 0.52), exp(-depth * 14.0) * 0.35);
    }

    // 轻微暗角
    col *= 0.72 + 0.28 * pow(16.0 * uv.x * uv.y * (1.0 - uv.x) * (1.0 - uv.y), 0.22);
    col = pow(col, vec3(0.4545));

    fragColor = vec4(col, 1.0);
}

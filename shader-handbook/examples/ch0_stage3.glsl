// 阶段 3：太阳上切出横向条纹（合成波的标志性符号）
const float HORIZON = -0.15;

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = (2.0 * fragCoord - iResolution.xy) / iResolution.y;

    float t = clamp(uv.y - HORIZON, 0.0, 1.0);
    vec3 col = mix(vec3(1.00, 0.30, 0.45), vec3(0.04, 0.01, 0.16), t);

    vec2  sp = uv - vec2(0.0, 0.30);
    float sd = length(sp) - 0.32;
    vec3 sunCol = mix(vec3(1.00, 0.95, 0.35), vec3(1.00, 0.15, 0.45),
                      clamp(0.5 - sp.y * 1.5, 0.0, 1.0));

    // 条纹：sin 产生周期条带，clamp 项让条纹在顶部被"填满"、在底部被"切光"
    float cut = 3.0 * sin((sp.y + iTime * 0.25) * 90.0)
              + clamp(sp.y * 16.0 + 2.0, -6.0, 6.0);
    cut = clamp(cut, 0.0, 1.0);

    col = mix(col, sunCol, smoothstep(0.004, -0.004, sd) * cut);

    fragColor = vec4(col, 1.0);
}

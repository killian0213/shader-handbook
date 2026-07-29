// 阶段 4：加山脊剪影（一维高度场 + 边缘描光）
const float HORIZON = -0.15;

// 多个不同频率的正弦叠加 —— 这就是 fbm 的手工雏形
float mountain(float x)
{
    float h = 0.0;
    h += 0.26 * sin(x * 1.1 + 0.3);
    h += 0.13 * sin(x * 2.3 + 1.7);
    h += 0.06 * sin(x * 4.7 + 3.1);
    h += 0.03 * sin(x * 9.1 + 0.9);
    return h;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = (2.0 * fragCoord - iResolution.xy) / iResolution.y;

    float t = clamp(uv.y - HORIZON, 0.0, 1.0);
    vec3 col = mix(vec3(1.00, 0.30, 0.45), vec3(0.04, 0.01, 0.16), t);

    vec2  sp = uv - vec2(0.0, 0.30);
    float sd = length(sp) - 0.32;
    vec3 sunCol = mix(vec3(1.00, 0.95, 0.35), vec3(1.00, 0.15, 0.45),
                      clamp(0.5 - sp.y * 1.5, 0.0, 1.0));
    float cut = 3.0 * sin((sp.y + iTime * 0.25) * 90.0)
              + clamp(sp.y * 16.0 + 2.0, -6.0, 6.0);
    cut = clamp(cut, 0.0, 1.0);
    col = mix(col, sunCol, smoothstep(0.004, -0.004, sd) * cut);

    // 山：把 1D 高度曲线变成 2D 剪影，md < 0 即在山体内部
    float md = uv.y - (HORIZON + 0.05 + 0.45 * mountain(uv.x * 2.0));
    col = mix(col, vec3(0.05, 0.01, 0.13), smoothstep(0.004, -0.004, md));
    // 山脊描光：|md| 接近 0 的地方最亮
    col += vec3(1.00, 0.35, 0.90) * smoothstep(0.018, 0.0, abs(md)) * 0.9;

    fragColor = vec4(col, 1.0);
}

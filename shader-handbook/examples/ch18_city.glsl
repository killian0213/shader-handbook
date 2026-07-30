// 第 18 章 · 效果配方 · 夜景城市天际线
// 心法：2.5D 楼块 SDF + 窗户 hash 亮灭；远处雾与街灯 glow。
// 语料对照：City / skyline / night windows 类

float hash11(float n) { return fract(sin(n) * 43758.5453); }
float hash21(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }

float building(vec2 p, float x, float w, float h)
{
    return max(abs(p.x - x) - w, p.y - h);
}

float windowLights(vec2 p, float x, float w, float h, float t)
{
    if (p.y > h || abs(p.x - x) > w) return 0.0;
    vec2 g = vec2((p.x - (x - w)) / (2.0 * w), p.y / h);
    vec2 id = floor(g * vec2(6.0, 12.0));
    vec2 f = fract(g * vec2(6.0, 12.0));
    float hsh = hash21(id + vec2(x, h));
    float on = step(0.55, hsh) * step(0.35, sin(t * (1.0 + hsh * 3.0) + hsh * 20.0) * 0.5 + 0.5);
    float frame = smoothstep(0.45, 0.35, max(abs(f.x - 0.5), abs(f.y - 0.5)));
    return on * frame;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = fragCoord / iResolution.xy;
    vec2 p = (uv - vec2(0.5, 0.08)) * vec2(iResolution.x / iResolution.y, 1.0) * 2.2;
    float t = iTime;

    // 天空渐变
    vec3 col = mix(vec3(0.02, 0.03, 0.08), vec3(0.08, 0.1, 0.18), uv.y);
    col += vec3(0.15, 0.12, 0.08) * exp(-length(uv - vec2(0.75, 0.15)) * 6.0) * 0.2;

    float ground = p.y;
    float scene = ground;

    // 楼群参数：x, 半宽, 高度
    const int N = 10;
    float xs[10];
    float ws[10];
    float hs[10];
    xs[0]=-1.8; ws[0]=0.22; hs[0]=1.1;
    xs[1]=-1.2; ws[1]=0.18; hs[1]=0.85;
    xs[2]=-0.55; ws[2]=0.28; hs[2]=1.35;
    xs[3]=0.05; ws[3]=0.15; hs[3]=0.7;
    xs[4]=0.45; ws[4]=0.2; hs[4]=1.0;
    xs[5]=0.95; ws[5]=0.25; hs[5]=1.25;
    xs[6]=1.45; ws[6]=0.16; hs[6]=0.75;
    xs[7]=-0.05; ws[7]=0.12; hs[7]=1.55;
    xs[8]=1.85; ws[8]=0.2; hs[8]=0.9;
    xs[9]=-1.55; ws[9]=0.14; hs[9]=0.65;

    float fog = exp(-max(p.y, 0.0) * 0.8);

    for (int i = 0; i < N; i++) {
        float d = building(p, xs[i], ws[i], hs[i]);
        scene = min(scene, d);

        if (d < 0.02 && p.y < hs[i]) {
            vec3 bld = vec3(0.04, 0.045, 0.06);
            float win = windowLights(p, xs[i], ws[i] * 0.85, hs[i] * 0.95, t);
            bld += vec3(1.0, 0.85, 0.45) * win * 0.9;
            bld += vec3(0.5, 0.7, 1.0) * win * hash21(floor(p * 10.0)) * 0.15;
            col = mix(col, bld, smoothstep(0.015, -0.005, d));
        }
    }

    // 地面 / 街道
    vec3 street = vec3(0.03, 0.035, 0.04);
    col = mix(col, street, smoothstep(0.01, -0.01, ground));
    col += vec3(1.0, 0.7, 0.35) * exp(-abs(p.x + 0.3) * 3.0) * smoothstep(0.05, -0.02, ground) * 0.15;

    col = mix(col, vec3(0.05, 0.06, 0.1), 1.0 - fog);
    col = pow(col, vec3(0.4545));
    fragColor = vec4(col, 1.0);
}

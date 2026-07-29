// 第 10 章 · 阶梯实战 · 阶段 1：Beer-Lambert 透过率
// 只做一件事：一团均匀密度球挡住背景。没有发光，只有「变暗」。
// 你会看见：穿过球心最暗，擦边几乎透明 —— 这就是 exp(-σ·L)。
const float SIGMA = 1.8;   // 消光系数：调大更「浓」

float densityBall(vec3 p)
{
    // 球内密度恒为 1，球外为 0。最简单的参与介质。
    return step(length(p - vec3(0.0, 0.0, 0.0)), 0.85);
}

// 解析：均匀球与射线的相交弦长。教学阶段先不用步进，把 Beer 看清楚。
float chordOpticalDepth(vec3 ro, vec3 rd, vec3 c, float r)
{
    vec3  oc = ro - c;
    float b  = dot(oc, rd);
    float h  = b*b - dot(oc, oc) + r*r;
    if (h < 0.0) return 0.0;
    h = sqrt(h);
    float t0 = max(0.0, -b - h);
    float t1 = max(0.0, -b + h);
    return max(0.0, t1 - t0);          // 弦长 = 光学路径（密度=1）
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 p = (2.0*fragCoord - iResolution.xy) / iResolution.y;

    vec3 ro = vec3(0.0, 0.0, 2.8);
    vec3 rd = normalize(vec3(p, -1.6));

    // 棋盘背景：用来证明「透过」真的发生了
    float tHit = 6.0;
    vec3  hit  = ro + rd * tHit;
    float chk  = mod(floor(hit.x*1.5) + floor(hit.y*1.5), 2.0);
    vec3  bg   = mix(vec3(0.75, 0.78, 0.85), vec3(0.35, 0.38, 0.45), chk);

    float od = chordOpticalDepth(ro, rd, vec3(0.0), 0.85);
    float T  = exp(-SIGMA * od);       // Beer-Lambert

    vec3 col = bg * T;

    // 侧面小字感：把透过率可视化成色带（右下角）
    if (p.x > 0.55 && p.y < -0.55) {
        float u = (p.x - 0.55) / 0.45;
        col = vec3(exp(-SIGMA * u * 2.5));
    }

    fragColor = vec4(col, 1.0);
}

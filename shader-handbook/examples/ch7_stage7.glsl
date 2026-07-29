// 第 7 章 · 阶梯实战 · 阶段 7：打磨
// 场景、几何、雾全都没动。这一步只做六件小事：
// 轮廓光(Fresnel) / 一点高光 / 朝太阳的镜头辉光 / 电影感色调映射 / 暗角 / 抖动。
// 加起来二十行，画面质感跨一个档次 —— 这就是打磨的性价比。
#define MAX_STEPS 90
#define MAX_DIST  30.0

const vec3 LIG = vec3(0.602, 0.341, -0.722);

float sdSphere(vec3 p, float r) { return length(p) - r; }

vec2 map(vec3 p)
{
    vec2 res = vec2(sdSphere(p - vec3(0.0, 1.0, 0.0), 1.0), 1.0);

    float dp = p.y;
    if (dp < res.x) res = vec2(dp, 2.0);

    float ds = sdSphere(p - vec3(-2.30, 0.35, -0.60), 0.35);
    ds = min(ds, sdSphere(p - vec3(-4.40, 0.25, -2.40), 0.25));
    ds = min(ds, sdSphere(p - vec3( 1.50, 0.45, -3.80), 0.45));
    if (ds < res.x) res = vec2(ds, 3.0);

    return res;
}

vec2 raymarch(vec3 ro, vec3 rd)
{
    float t = 0.0;
    float m = -1.0;
    for (int i = 0; i < MAX_STEPS; i++) {
        vec2 h = map(ro + rd * t);
        if (h.x < 0.0015 * t) { m = h.y; break; }
        if (t > MAX_DIST) break;
        t += h.x;
    }
    return vec2(t, m);
}

vec3 calcNormal(vec3 pos)
{
    vec2 e = vec2(1.0, -1.0) * 0.5773 * 0.0015;
    return normalize(e.xyy * map(pos + e.xyy).x +
                     e.yyx * map(pos + e.yyx).x +
                     e.yxy * map(pos + e.yxy).x +
                     e.xxx * map(pos + e.xxx).x);
}

float softShadow(vec3 ro, vec3 rd)
{
    float res = 1.0;
    float t   = 0.04;
    for (int i = 0; i < 24; i++) {
        float h = map(ro + rd * t).x;
        res = min(res, h / (0.055 * t));
        t += clamp(h, 0.06, 0.9);
        if (res < 0.003 || t > 14.0) break;
    }
    return clamp(res, 0.0, 1.0);
}

float calcAO(vec3 pos, vec3 nor)
{
    float occ = 0.0;
    float sca = 1.0;
    for (int i = 0; i < 5; i++) {
        float h = 0.02 + 0.14 * float(i) / 4.0;
        float d = map(pos + h * nor).x;
        occ += (h - d) * sca;
        sca *= 0.92;
    }
    return clamp(1.0 - 1.8 * occ, 0.0, 1.0);
}

vec3 sky(vec3 rd)
{
    float h = clamp(rd.y, 0.0, 1.0);
    vec3  col = mix(vec3(0.90, 0.74, 0.60), vec3(0.14, 0.30, 0.62), pow(h, 0.45));
    float s = clamp(dot(rd, LIG), 0.0, 1.0);
    col += vec3(1.00, 0.52, 0.22) * pow(s,  4.0) * 0.60;
    col += vec3(1.00, 0.80, 0.55) * pow(s, 40.0) * 0.80;
    return col;
}

float mist(vec3 ro, vec3 rd, float t)
{
    const float H = 0.60;
    const float D = 0.45;
    float ky = rd.y / H;
    float s  = (abs(ky) < 1e-3) ? t : (1.0 - exp(-ky * t)) / ky;
    return 1.0 - exp(-D * exp(-ro.y / H) * s);
}

// Narkowicz 的 ACES 拟合：亮部平滑滚降、暗部略微压深。
// 输入线性、输出线性，之后照常补 gamma。
vec3 tonemap(vec3 x)
{
    return clamp((x * (2.51 * x + 0.03)) / (x * (2.43 * x + 0.59) + 0.14),
                 0.0, 1.0);
}

mat3 setCamera(vec3 ro, vec3 ta, float cr)
{
    vec3 cw = normalize(ta - ro);
    vec3 cp = vec3(sin(cr), cos(cr), 0.0);
    vec3 cu = normalize(cross(cw, cp));
    vec3 cv = cross(cu, cw);
    return mat3(cu, cv, cw);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 p = (2.0 * fragCoord - iResolution.xy) / iResolution.y;

    float an = 0.28 + 0.10 * sin(iTime * 0.13);
    vec3  ta = vec3(0.0, 0.95, 0.0);
    vec3  ro = vec3(4.2 * sin(an), 1.45, 4.2 * cos(an));
    mat3  ca = setCamera(ro, ta, 0.0);
    vec3  rd = ca * normalize(vec3(p, 2.2));

    vec2  res = raymarch(ro, rd);
    float t   = res.x;
    vec3  col = sky(rd);

    if (res.y > 0.0) {
        vec3 pos = ro + rd * t;
        vec3 nor = calcNormal(pos);

        vec3 mate = vec3(0.68, 0.64, 0.58);
        if (res.y > 2.5) {
            mate = vec3(0.13, 0.15, 0.18);
        } else if (res.y > 1.5) {
            mate = vec3(0.26, 0.26, 0.24);
            float chk = mod(floor(pos.x) + floor(pos.z), 2.0);
            mate *= 1.0 + 0.45 * (chk - 0.5) * exp(-0.02 * t * t);
        }

        float dif = clamp(dot(nor, LIG), 0.0, 1.0);
        float sha = (dif > 0.001) ? softShadow(pos + nor * 0.01, LIG) : 0.0;
        float occ = calcAO(pos, nor);

        float skyL = clamp(0.5 + 0.5 * nor.y, 0.0, 1.0);
        float bou  = clamp(0.3 - 0.3 * nor.y, 0.0, 1.0);

        // 掠射角上表面会变成镜子。这一项给所有物体镶了一圈天光边，
        // 主球和背景之间立刻有了"分离"。（Fresnel，第 9 章）
        float fre = pow(clamp(1.0 + dot(rd, nor), 0.0, 1.0), 4.0);
        // 一点点太阳高光，指数压到 20 左右 —— 瓷器，不是不锈钢
        float spe = pow(clamp(dot(reflect(rd, nor), LIG), 0.0, 1.0), 20.0);

        vec3 lin = vec3(0.0);
        lin += vec3(1.30, 1.02, 0.70) * dif * sha;
        lin += vec3(0.26, 0.36, 0.58) * skyL * occ;
        lin += vec3(0.26, 0.20, 0.14) * bou  * occ;
        lin += vec3(0.60, 0.74, 0.95) * fre  * occ * 0.90;
        col = mate * lin;
        col += vec3(0.90, 0.80, 0.66) * spe * sha * 0.35;    // 高光是加的，不乘材质

        vec3 mistCol = mix(vec3(0.80, 0.80, 0.84), vec3(1.05, 0.82, 0.58),
                           pow(clamp(dot(rd, LIG), 0.0, 1.0), 3.0));
        col = mix(col, mistCol, mist(ro, rd, t));
        col = mix(col, sky(rd), 1.0 - exp(-0.0007 * t * t * t));
    }

    // --- 镜头辉光：整幅图朝太阳方向加一层极宽的暖光。
    //     真 bloom 要第二个 pass，这一行是最便宜的替代品。---
    col += vec3(1.00, 0.62, 0.30) * pow(clamp(dot(rd, LIG), 0.0, 1.0), 3.0) * 0.14;

    // --- 收尾流水线，顺序不能乱：色调映射 → gamma → 显示空间的调整 ---
    col = tonemap(col * 1.10);
    col = pow(col, vec3(0.4545));

    // 轻微提饱和：清晨的暖光/冷影对比值得再推一把
    col = mix(vec3(dot(col, vec3(0.299, 0.587, 0.114))), col, 1.12);

    // 暗角：四角压暗，视线自动收到主球上
    vec2 q = fragCoord / iResolution.xy;
    col *= 0.62 + 0.38 * pow(16.0 * q.x * q.y * (1.0 - q.x) * (1.0 - q.y), 0.28);

    // 抖动：天空是一整片缓渐变，8-bit 量化一定会出色带
    col += (fract(sin(dot(fragCoord, vec2(12.9898, 78.233))) * 43758.545) - 0.5) / 255.0;

    fragColor = vec4(clamp(col, 0.0, 1.0), 1.0);
}

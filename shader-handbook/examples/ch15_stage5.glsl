// 第 15 章 · 阶梯实战 · 阶段 5：NPR 卡通（Sobel 边缘 + 量化色阶）
// 对阶段 3 成片做邻域 Sobel 提边 + posterize，得到简单手绘卡通风。
#define BLUR_TAPS 4
const float SIGMA = 1.6;
const vec3 SUN = normalize(vec3(0.55, 0.72, -0.42));

mat3 setCamera(vec3 ro, vec3 ta)
{
    vec3 cw = normalize(ta - ro);
    vec3 cu = normalize(cross(cw, vec3(0.0, 1.0, 0.0)));
    vec3 cv = cross(cu, cw);
    return mat3(cu, cv, cw);
}

float iPlane(vec3 ro, vec3 rd)
{
    if (abs(rd.y) < 1e-5) return -1.0;
    float t = -ro.y / rd.y;
    return (t > 0.001) ? t : -1.0;
}

float iSphere(vec3 ro, vec3 rd, vec3 c, float r)
{
    vec3  oc = ro - c;
    float b  = dot(oc, rd);
    float cc = dot(oc, oc) - r * r;
    float h  = b * b - cc;
    if (h < 0.0) return -1.0;
    h = sqrt(h);
    float t = -b - h;
    if (t < 0.001) t = -b + h;
    return (t > 0.001) ? t : -1.0;
}

vec2 map(vec3 ro, vec3 rd)
{
    float best = 1e20;
    float id   = 0.0;
    float tp = iPlane(ro, rd);
    if (tp > 0.0) { best = tp; id = 1.0; }
    float t1 = iSphere(ro, rd, vec3(-1.2, 0.45, 0.3), 0.45);
    if (t1 > 0.0 && t1 < best) { best = t1; id = 2.0; }
    float t2 = iSphere(ro, rd, vec3(0.8, 0.55, -0.4), 0.55);
    if (t2 > 0.0 && t2 < best) { best = t2; id = 3.0; }
    float t3 = iSphere(ro, rd, vec3(0.0, 1.05, 1.2), 1.05);
    if (t3 > 0.0 && t3 < best) { best = t3; id = 4.0; }
    return (id > 0.0) ? vec2(best, id) : vec2(-1.0, 0.0);
}

vec3 getNormal(vec3 p, float id)
{
    if (id < 1.5) return vec3(0.0, 1.0, 0.0);
    if (id < 2.5) return normalize(p - vec3(-1.2, 0.45, 0.3));
    if (id < 3.5) return normalize(p - vec3(0.8, 0.55, -0.4));
    return normalize(p - vec3(0.0, 1.05, 1.2));
}

vec3 sky(vec3 rd)
{
    float h = clamp(rd.y * 0.5 + 0.5, 0.0, 1.0);
    return mix(vec3(0.12, 0.22, 0.42), vec3(0.55, 0.68, 0.88), h);
}

float gauss(float x) { return exp(-0.5 * x * x / (SIGMA * SIGMA)); }

vec3 renderScene(vec3 ro, vec3 rd)
{
    vec2 hit = map(ro, rd);
    vec3 col = sky(rd);
    if (hit.y > 0.0) {
        vec3 pos = ro + rd * hit.x;
        vec3 nor = getNormal(pos, hit.y);
        vec3 alb; float emit = 0.0;
        if (hit.y < 1.5) {
            float chk = mod(floor(pos.x) + floor(pos.z), 2.0);
            alb = mix(vec3(0.22, 0.24, 0.28), vec3(0.55, 0.58, 0.62), chk);
        } else if (hit.y < 2.5) {
            alb = vec3(1.2, 0.35, 0.18); emit = 0.6;
        } else if (hit.y < 3.5) {
            alb = vec3(0.25, 0.95, 1.15); emit = 0.5;
        } else {
            alb = vec3(0.95, 0.88, 0.55); emit = 0.35;
        }
        float dif = max(dot(nor, SUN), 0.0);
        float amb = 0.12 + 0.18 * max(nor.y, 0.0);
        col = alb * (amb + dif) + alb * emit;
    }
    return col;
}

vec3 sampleScene(vec2 uv, vec2 px)
{
    vec2 p = (uv - 0.5) * vec2(iResolution.x / iResolution.y, 1.0);
    float an = 0.20 + 0.10 * sin(iTime * 0.12);
    vec3  ta = vec3(0.0, 0.55, 0.0);
    vec3  ro = vec3(4.8 * sin(an), 1.35, 4.8 * cos(an));
    mat3  ca = setCamera(ro, ta);
    vec3  rd = ca * normalize(vec3(p, 2.2));
    return renderScene(ro, rd);
}

vec3 blurH(vec2 uv, vec2 px)
{
    vec3 s = vec3(0.0); float w = 0.0;
    for (int i = -BLUR_TAPS; i <= BLUR_TAPS; i++) {
        float g = gauss(float(i));
        s += sampleScene(uv + vec2(float(i) * px.x, 0.0), px) * g;
        w += g;
    }
    return s / w;
}

vec3 blurV(vec2 uv, vec2 px)
{
    vec3 s = vec3(0.0); float w = 0.0;
    for (int i = -BLUR_TAPS; i <= BLUR_TAPS; i++) {
        float g = gauss(float(i));
        s += blurH(uv + vec2(0.0, float(i) * px.y), px) * g;
        w += g;
    }
    return s / w;
}

vec3 tonemap(vec3 x)
{
    return clamp((x * (2.51 * x + 0.03)) / (x * (2.43 * x + 0.59) + 0.14), 0.0, 1.0);
}

vec3 flatColor(vec2 uv)
{
    vec2 px = 2.0 / iResolution.xy;
    vec3 base = sampleScene(uv, px);
    float lum = dot(base, vec3(0.299, 0.587, 0.114));
    vec3 bloom = blurV(uv, px * 2.5) * smoothstep(0.65, 1.05, lum);
    vec3 col = tonemap(base + bloom * 1.25);
    col = pow(col, vec3(0.4545));
    col *= 0.60 + 0.40 * pow(16.0 * uv.x * uv.y * (1.0 - uv.x) * (1.0 - uv.y), 0.28);

    // 量化色阶：posterize
    col = floor(col * 5.0 + 0.5) / 5.0;
    return col;
}

float luma(vec3 c) { return dot(c, vec3(0.299, 0.587, 0.114)); }

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = fragCoord / iResolution.xy;
    vec2 px = 1.5 / iResolution.xy;

    vec3 c  = flatColor(uv);
    vec3 cx = flatColor(uv + vec2(px.x, 0.0));
    vec3 cy = flatColor(uv + vec2(0.0, px.y));

    // 简易 Sobel：亮度梯度
    float gx = luma(cx - flatColor(uv - vec2(px.x, 0.0)));
    float gy = luma(cy - flatColor(uv - vec2(0.0, px.y)));
    float edge = clamp(length(vec2(gx, gy)) * 8.0, 0.0, 1.0);

    vec3 col = mix(c, vec3(0.05, 0.05, 0.08), edge * 0.85);
    fragColor = vec4(col, 1.0);
}

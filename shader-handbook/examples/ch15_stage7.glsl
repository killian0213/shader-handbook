// 第 15 章 · 后期进阶 · 阶段 7：油画 / 绘画风 NPR
// 边缘感知 posterize + 方向性 hatch 阴影 + 简化 Kubelka-Munk 感（厚涂叠色）。
// 场景：简单 SDF 球体阵列。
const vec3 SUN = normalize(vec3(0.55, 0.72, -0.42));
const float TAU = 6.2831853;

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
    float t1 = iSphere(ro, rd, vec3(-1.0, 0.42, 0.5), 0.42);
    if (t1 > 0.0 && t1 < best) { best = t1; id = 2.0; }
    float t2 = iSphere(ro, rd, vec3(0.9, 0.58, -0.2), 0.52);
    if (t2 > 0.0 && t2 < best) { best = t2; id = 3.0; }
    float t3 = iSphere(ro, rd, vec3(0.0, 0.95, 1.4), 0.72);
    if (t3 > 0.0 && t3 < best) { best = t3; id = 4.0; }
    return (id > 0.0) ? vec2(best, id) : vec2(-1.0, 0.0);
}

vec3 getNormal(vec3 p, float id)
{
    if (id < 1.5) return vec3(0.0, 1.0, 0.0);
    if (id < 2.5) return normalize(p - vec3(-1.0, 0.42, 0.5));
    if (id < 3.5) return normalize(p - vec3(0.9, 0.58, -0.2));
    return normalize(p - vec3(0.0, 0.95, 1.4));
}

vec3 sky(vec3 rd)
{
    return mix(vec3(0.75, 0.82, 0.92), vec3(0.45, 0.58, 0.78), clamp(rd.y * 0.5 + 0.5, 0.0, 1.0));
}

// 方向性 hatch：根据法线与光方向画线
float hatch(vec2 uv, vec3 nor, float lum)
{
    float ang = atan(nor.z, nor.x) + lum * 0.5;
    vec2 dir = vec2(cos(ang), sin(ang));
    float lines = sin(dot(uv, dir) * 180.0) * 0.5 + 0.5;
    lines = smoothstep(0.45, 0.55, lines);
    return mix(1.0, 0.72, lines * smoothstep(0.55, 0.25, lum));
}

// 简化 Kubelka-Munk 感：颜料层叠 = 非线性 mix + 略降饱和
vec3 paintLayer(vec3 base, vec3 stroke, float t)
{
    vec3 mixCol = mix(base, stroke, t);
    float sat = dot(mixCol, vec3(0.299, 0.587, 0.114));
    return mix(vec3(sat), mixCol, 1.15);
}

vec3 renderScene(vec2 uv, vec2 px)
{
    vec2 p = (uv - 0.5) * vec2(iResolution.x / iResolution.y, 1.0);
    float an = 0.18 + 0.06 * sin(iTime * 0.08);
    vec3 ta = vec3(0.0, 0.5, 0.0);
    vec3 ro = vec3(4.5 * sin(an), 1.25, 4.5 * cos(an));
    mat3 ca = setCamera(ro, ta);
    vec3 rd = ca * normalize(vec3(p, 2.0));

    vec2 hit = map(ro, rd);
    vec3 col = sky(rd);

    if (hit.y > 0.0) {
        vec3 pos = ro + rd * hit.x;
        vec3 nor = getNormal(pos, hit.y);
        vec3 alb;
        if (hit.y < 1.5) alb = vec3(0.88, 0.86, 0.82);
        else if (hit.y < 2.5) alb = vec3(0.92, 0.35, 0.22);
        else if (hit.y < 3.5) alb = vec3(0.22, 0.55, 0.88);
        else alb = vec3(0.95, 0.78, 0.35);

        float dif = max(dot(nor, SUN), 0.0);
        float lum = dif * 0.75 + 0.15;
        col = alb * (0.25 + dif * 0.75);

        // posterize：色阶量化
        col = floor(col * 6.0 + 0.35) / 6.0;

        // hatch 阴影
        col *= hatch(uv * iResolution.xy * 0.5, nor, lum);

        // 厚涂叠一层暖色 stroke
        col = paintLayer(col, vec3(0.95, 0.72, 0.45), 0.08 * (1.0 - lum));
    }

    return col;
}

float luma(vec3 c) { return dot(c, vec3(0.299, 0.587, 0.114)); }

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = fragCoord / iResolution.xy;
    vec2 px = 1.8 / iResolution.xy;

    vec3 c  = renderScene(uv, px);
    vec3 cx = renderScene(uv + vec2(px.x, 0.0), px);
    vec3 cy = renderScene(uv + vec2(0.0, px.y), px);

    // 边缘感知：只在亮度变化大的地方描边
    float gx = luma(cx - renderScene(uv - vec2(px.x, 0.0), px));
    float gy = luma(cy - renderScene(uv - vec2(0.0, px.y), px));
    float edge = smoothstep(0.04, 0.18, length(vec2(gx, gy)));

    vec3 col = mix(c, vec3(0.12, 0.08, 0.06), edge * 0.75);

    // 纸纹
    float paper = fract(sin(dot(floor(fragCoord * 0.7), vec2(12.9898, 78.233))) * 43758.545);
    col = mix(col, col * 0.97, paper * 0.15);

    col = pow(col, vec3(0.92));
    fragColor = vec4(clamp(col, 0.0, 1.0), 1.0);
}

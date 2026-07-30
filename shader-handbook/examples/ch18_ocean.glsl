// 第 18 章 · 效果配方 · 海洋（Seascape 味道）
// 高度场求交 + Fresnel 混天空；几何少 octave、着色多一点细节。
// 语料：002224 Seascape（TDM）
const mat2 M = mat2(1.6, 1.2, -1.2, 1.6);

float hash21(vec2 p)
{
    p = fract(p * vec2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

float noise(vec2 p)
{
    vec2 i = floor(p), f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    float a = hash21(i);
    float b = hash21(i + vec2(1, 0));
    float c = hash21(i + vec2(0, 1));
    float d = hash21(i + vec2(1, 1));
    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

float seaOctave(vec2 uv, float choppy)
{
    uv += noise(uv);
    vec2 wv  = 1.0 - abs(sin(uv));
    vec2 swv = abs(cos(uv));
    wv = mix(wv, swv, wv);
    return pow(1.0 - pow(wv.x * wv.y, 0.65), choppy);
}

float mapSea(vec2 p, float t, int octs)
{
    float freq = 0.16;
    float amp = 0.6;
    float choppy = 4.0;
    float h = 0.0;
    vec2 uv = p;
    for (int i = 0; i < 6; i++) {
        if (i >= octs) break;
        float d = seaOctave((uv + t) * freq, choppy);
        d += seaOctave((uv - t) * freq, choppy);
        h += d * amp;
        uv *= M;
        freq *= 1.9;
        amp *= 0.22;
        choppy = mix(choppy, 1.0, 0.2);
    }
    return h;
}

vec3 sky(vec3 rd)
{
    float y = max(rd.y, 0.0);
    vec3 col = mix(vec3(0.65, 0.78, 0.95), vec3(0.12, 0.28, 0.65), pow(y, 0.45));
    vec3 sun = normalize(vec3(0.4, 0.35, -0.7));
    col += vec3(1.0, 0.85, 0.55) * pow(max(dot(rd, sun), 0.0), 32.0) * 0.55;
    return col;
}

float heightMapTracing(vec3 ro, vec3 rd, float t, out vec3 hit)
{
    float tm = 0.0, tx = 80.0;
    float hm = mapSea(ro.xz + rd.xz * tm, t, 3) - (ro.y + rd.y * tm);
    if (hm > 0.0) { hit = ro + rd * tm; return tm; }
    float hx = mapSea(ro.xz + rd.xz * tx, t, 3) - (ro.y + rd.y * tx);
    for (int i = 0; i < 48; i++) {
        float tmid = mix(tm, tx, hm / (hm - hx));
        hit = ro + rd * tmid;
        float hmid = mapSea(hit.xz, t, 3) - hit.y;
        if (hmid < 0.0) {
            tx = tmid;
            hx = hmid;
        } else {
            tm = tmid;
            hm = hmid;
        }
        if (abs(hmid) < 0.01) break;
    }
    return tm;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 p = (2.0 * fragCoord - iResolution.xy) / iResolution.y;
    float t = iTime * 0.55;

    // 略高机位，看得见地平线天空带
    vec3  ro = vec3(0.0, 3.4, 8.5);
    vec3  ta = vec3(0.0, 0.8, 0.0);
    vec3  cw = normalize(ta - ro);
    vec3  cu = normalize(cross(cw, vec3(0, 1, 0)));
    vec3  cv = cross(cu, cw);
    vec3  rd = normalize(p.x * cu + p.y * cv + 1.35 * cw);

    vec3 col = sky(rd);

    if (rd.y < 0.2) {
        vec3 hit;
        float dist = heightMapTracing(ro, rd, t, hit);
        if (dist < 79.0) {
            float e = 0.12;
            float hx = mapSea(hit.xz + vec2(e, 0), t, 4) - mapSea(hit.xz - vec2(e, 0), t, 4);
            float hz = mapSea(hit.xz + vec2(0, e), t, 4) - mapSea(hit.xz - vec2(0, e), t, 4);
            vec3  n  = normalize(vec3(hx, 2.0 * e, hz));

            vec3 water = mix(vec3(0.01, 0.06, 0.14), vec3(0.04, 0.28, 0.36), clamp(n.y * 1.2, 0.0, 1.0));
            float fres = pow(1.0 - clamp(dot(n, -rd), 0.0, 1.0), 3.0);
            vec3 refl = sky(reflect(rd, n));
            col = mix(water, refl, fres);

            vec3 sun = normalize(vec3(0.4, 0.45, -0.7));
            float spe = pow(max(dot(reflect(-sun, n), -rd), 0.0), 80.0);
            col += vec3(1.0, 0.92, 0.75) * spe * 0.7;
            // 浪尖一点点青绿 SSS 感
            col += vec3(0.05, 0.25, 0.18) * pow(clamp(1.0 - abs(n.y), 0.0, 1.0), 3.0) * 0.35;

            float fog = 1.0 - exp(-0.00035 * dist * dist);
            col = mix(col, sky(rd), fog);
        }
    }

    col = pow(max(col, 0.0), vec3(0.4545));
    fragColor = vec4(col, 1.0);
}

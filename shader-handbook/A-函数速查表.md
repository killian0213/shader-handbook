# 附录 A · 函数速查表

> 可复制代码库。默认按 **GLSL ES 3.00 / Shadertoy 片元** 书写。
>
> 标注 📄 的尽量指向语料中的真实实现或同作者经典写法；标注 **「合成示例」** 的是为教学整理的等价版本，结构与语料一致。
>
> 使用方式：整段粘贴到 Shadertoy；需要 `map` 的函数请自己提供 `float map(vec3 p)`。

---

## A.1 Hash（伪随机）

### A.1.1 二维 → 一维（极常见）

📄 同型见于 `002224-Ms2SD1-Seascape/image.glsl`（TDM）及大量作品。

```glsl
float hash12(vec2 p) {
    // 经典 sin-hash；大坐标请先缩小或 mod
    float h = dot(p, vec2(127.1, 311.7));
    return fract(sin(h) * 43758.5453123);
}
```

📄 Dave Hoskins 风格（Heartfelt 注释引用），`001078-ltffzl-Heartfelt/image.glsl`：

```glsl
float hash12_dh(vec2 p) {
    vec3 p3 = fract(vec3(p.xyx) * 0.1031);
    p3 += dot(p3, p3.yzx + 19.19);
    return fract((p3.x + p3.y) * p3.z);
}

vec2 hash22_dh(vec2 p) {
    vec3 p3 = fract(vec3(p.xyx) * vec3(0.1031, 0.1030, 0.0973));
    p3 += dot(p3, p3.yzx + 19.19);
    return fract((p3.xx + p3.yz) * p3.zy);
}
```

### A.1.2 二维 → 二维（梯度噪声用）

📄 `000392-XsXSWS-Fires/image.glsl`（iq 程序化噪声系）：

```glsl
vec2 hash22(vec2 p) {
    p = vec2(dot(p, vec2(127.1, 311.7)),
             dot(p, vec2(269.5, 183.3)));
    return -1.0 + 2.0 * fract(sin(p) * 43758.5453123);
}
```

### A.1.3 一维 → 三维

📄 `001078-ltffzl-Heartfelt/image.glsl` 的 `N13`：

```glsl
vec3 hash31(float p) {
    vec3 p3 = fract(vec3(p) * vec3(0.1031, 0.11369, 0.13787));
    p3 += dot(p3, p3.yzx + 19.19);
    return fract(vec3((p3.x + p3.y) * p3.z,
                      (p3.x + p3.z) * p3.y,
                      (p3.y + p3.z) * p3.x));
}
```

---

## A.2 Noise / FBM

### A.2.1 Value noise（-1..1）

📄 结构同 Seascape：

```glsl
float noise2(in vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(mix(hash12(i + vec2(0,0)), hash12(i + vec2(1,0)), u.x),
               mix(hash12(i + vec2(0,1)), hash12(i + vec2(1,1)), u.x), u.y) * 2.0 - 1.0;
}
```

### A.2.2 简易 2D fbm

📄 振幅表同 Fires 的 `fbm`：

<!-- glsl-skip -->
```glsl
mat2 fbm2_m = mat2(1.6, 1.2, -1.2, 1.6);

float fbm2(vec2 uv) {
    float f = 0.0;
    f += 0.5000 * noise2(uv); uv = fbm2_m * uv;
    f += 0.2500 * noise2(uv); uv = fbm2_m * uv;
    f += 0.1250 * noise2(uv); uv = fbm2_m * uv;
    f += 0.0625 * noise2(uv);
    return f; // 约在 [-1,1]；Fires 里还会映射到 0..1
}
```

### A.2.3 Ridged（山脊 / 闪电感）

**合成示例**（技法见第 5/18 章）：

<!-- glsl-skip -->
```glsl
float ridge2(vec2 p) {
    return 1.0 - abs(noise2(p));
}

float fbm_ridge2(vec2 p) {
    float a = 0.5, f = 0.0;
    for (int i = 0; i < 5; i++) {
        f += a * ridge2(p);
        p = fbm2_m * p;
        a *= 0.5;
    }
    return f;
}
```

---

## A.3 旋转

```glsl
mat2 rot2(float a) {
    float c = cos(a), s = sin(a);
    return mat2(c, s, -s, c);
}

// 用法：p.xy *= rot2(angle);
```

📄 极光用 `mm2`：`000724-XtGGRt-Auroras/image.glsl`。

三维绕轴可用罗德里格或基变换；相机见 A.7。

---

## A.4 平滑最小值 smin

语料出现极高（自定义函数名统计里 `smin` 327 次）。指数版与多项式版都常见。

**合成示例**（多项式，iq 常用形）：

```glsl
float smin(float a, float b, float k) {
    float h = clamp(0.5 + 0.5 * (b - a) / k, 0.0, 1.0);
    return mix(b, a, h) - k * h * (1.0 - h);
}

float smax(float a, float b, float k) {
    return -smin(-a, -b, k);
}
```

---

## A.5 常用 2D SDF

**合成示例**（图元集合思路同 `000440-4dfXDn-2d_signed_distance_functions` 与 Inigo Quilez 图元字典）：

```glsl
float sdCircle(vec2 p, float r) {
    return length(p) - r;
}

float sdBox2(vec2 p, vec2 b) {
    vec2 d = abs(p) - b;
    return length(max(d, 0.0)) + min(max(d.x, d.y), 0.0);
}

float sdRoundedBox2(vec2 p, vec2 b, float r) {
    return sdBox2(p, b) - r;
}

float sdSegment2(vec2 p, vec2 a, vec2 b) {
    vec2 pa = p - a, ba = b - a;
    float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
    return length(pa - ba * h);
}

float sdEquilateralTriangle(vec2 p) {
    const float k = sqrt(3.0);
    p.x = abs(p.x) - 1.0;
    p.y = p.y + 1.0 / k;
    if (p.x + k * p.y > 0.0)
        p = vec2(p.x - k * p.y, -k * p.x - p.y) / 2.0;
    p.x -= clamp(p.x, -2.0, 0.0);
    return -length(p) * sign(p.y);
}

// 并 / 交 / 差
float opU(float d1, float d2) { return min(d1, d2); }
float opI(float d1, float d2) { return max(d1, d2); }
float opS(float d1, float d2) { return max(d1, -d2); }

// 描边与辉光辅助
float stroke(float d, float w) {
    return smoothstep(w, 0.0, abs(d));
}
float glow(float d, float k) {
    return exp(-k * abs(d));
}
```

---

## A.6 常用 3D SDF

**合成示例**：

```glsl
float sdSphere(vec3 p, float r) {
    return length(p) - r;
}

float sdBox(vec3 p, vec3 b) {
    vec3 q = abs(p) - b;
    return length(max(q, 0.0)) + min(max(q.x, max(q.y, q.z)), 0.0);
}

float sdRoundBox(vec3 p, vec3 b, float r) {
    return sdBox(p, b) - r;
}

float sdTorus(vec3 p, vec2 t) {
    vec2 q = vec2(length(p.xz) - t.x, p.y);
    return length(q) - t.y;
}

float sdCapsule(vec3 p, vec3 a, vec3 b, float r) {
    vec3 pa = p - a, ba = b - a;
    float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
    return length(pa - ba * h) - r;
}

float sdCylinder(vec3 p, float r, float h) {
    vec2 d = abs(vec2(length(p.xz), p.y)) - vec2(r, h);
    return min(max(d.x, d.y), 0.0) + length(max(d, 0.0));
}

float sdPlaneY(vec3 p, float y) {
    return p.y - y;
}

// 无限重复
vec3 opRep(vec3 p, vec3 c) {
    return mod(p + 0.5 * c, c) - 0.5 * c;
}

// 洋葱空心
float opOnion(float d, float h) {
    return abs(d) - h;
}
```

语料高频名：`sdBox`、`sdSphere` 出现在大量 `map` 中。

---

## A.7 setCamera

📄 Elevated：`000787-MdX3Rr-Elevated/buffer_a.glsl` 的 `setCamera`。

```glsl
mat3 setCamera(in vec3 ro, in vec3 ta, float cr) {
    vec3 cw = normalize(ta - ro);
    vec3 cp = vec3(sin(cr), cos(cr), 0.0);
    vec3 cu = normalize(cross(cw, cp));
    vec3 cv = cross(cu, cw);
    return mat3(cu, cv, cw);
}

// 光线：
// vec3 rd = normalize(setCamera(ro, ta, 0.0) * vec3(uv, fov));
```

**合成示例**（fov 常用写法）：

<!-- glsl-skip -->
```glsl
vec3 rayDir(vec2 fragCoord, vec3 ro, vec3 ta, float fl) {
    vec2 uv = (2.0 * fragCoord - iResolution.xy) / iResolution.y;
    mat3 ca = setCamera(ro, ta, 0.0);
    return normalize(ca * vec3(uv, fl));
}
```

---

## A.8 calcNormal

### 通用 SDF（四面体更省，中心差分更直观）

**合成示例**：

```glsl
vec3 calcNormal(vec3 p) {
    const float e = 0.001;
    return normalize(vec3(
        map(p + vec3(e, 0, 0)) - map(p - vec3(e, 0, 0)),
        map(p + vec3(0, e, 0)) - map(p - vec3(0, e, 0)),
        map(p + vec3(0, 0, e)) - map(p - vec3(0, 0, e))
    ));
}

// 4 采样版（更省）
vec3 calcNormalTetra(vec3 p) {
    const float h = 0.001;
    const vec2 k = vec2(1, -1);
    return normalize(
        k.xyy * map(p + k.xyy * h) +
        k.yyx * map(p + k.yyx * h) +
        k.yxy * map(p + k.yxy * h) +
        k.xxx * map(p + k.xxx * h)
    );
}
```

### 高度场地形

📄 Elevated `calcNormal`：

<!-- glsl-skip -->
```glsl
// 需自备 float terrainH(vec2 x);
vec3 calcNormalTerrain(vec3 pos, float t) {
    vec2 eps = vec2(0.001 * t, 0.0);
    return normalize(vec3(
        terrainH(pos.xz - eps.xy) - terrainH(pos.xz + eps.xy),
        2.0 * eps.x,
        terrainH(pos.xz - eps.yx) - terrainH(pos.xz + eps.yx)
    ));
}
```

---

## A.9 softshadow

**合成示例**（iq 软阴影思路；Elevated 中有高度场版 `softShadow`）：

```glsl
float softshadow(vec3 ro, vec3 rd, float mint, float maxt, float k) {
    float res = 1.0;
    float t = mint;
    for (int i = 0; i < 32; i++) {
        float h = map(ro + rd * t);
        res = min(res, k * h / t);
        t += clamp(h, 0.02, 0.10);
        if (res < 0.001 || t > maxt) break;
    }
    return clamp(res, 0.0, 1.0);
}
```

调用前：`ro += nor * bias`，避免自遮挡。

---

## A.10 calcAO

**合成示例**：

```glsl
float calcAO(vec3 pos, vec3 nor) {
    float occ = 0.0;
    float sca = 1.0;
    for (int i = 0; i < 5; i++) {
        float h = 0.01 + 0.12 * float(i) / 4.0;
        float d = map(pos + nor * h);
        occ += (h - d) * sca;
        sca *= 0.95;
    }
    return clamp(1.0 - 3.0 * occ, 0.0, 1.0);
}
```

---

## A.11 palette（余弦调色板）

📄 思想与演示：`000581-ll2GD3-Palettes/image.glsl`（iq）。

```glsl
vec3 palette(in float t, in vec3 a, in vec3 b, in vec3 c, in vec3 d) {
    return a + b * cos(6.28318 * (c * t + d));
}

// 一组好用的默认（合成示例）
vec3 paletteDefault(float t) {
    return palette(t,
        vec3(0.5, 0.5, 0.5),
        vec3(0.5, 0.5, 0.5),
        vec3(1.0, 1.0, 1.0),
        vec3(0.00, 0.33, 0.67));
}
```

---

## A.12 vignette（暗角）

📄 几乎处处可见；Elevated image Pass 与第 0 章实战：

```glsl
vec3 applyVignette(vec3 col, vec2 fragCoord) {
    vec2 q = fragCoord / iResolution.xy;
    col *= 0.5 + 0.5 * pow(16.0 * q.x * q.y * (1.0 - q.x) * (1.0 - q.y), 0.25);
    return col;
}
```

Elevated 用幂次 `0.1` 更狠一点——按口味改 `pow` 指数。

---

## A.13 额外高频短件

### 坐标归一化

```glsl
vec2 normUV(vec2 fragCoord) {
    return (2.0 * fragCoord - iResolution.xy) / iResolution.y;
}
```

### Gamma / 简易 tone map

```glsl
vec3 tonemapExp(vec3 x) {
    return 1.0 - exp(-x);
}
vec3 toSRGB(vec3 c) {
    return pow(max(c, 0.0), vec3(1.0 / 2.2));
}
```

### 抖动去色带

📄 第 0 章打磨段：

```glsl
float dither(vec2 fragCoord) {
    return (hash12(fragCoord) - 0.5) / 255.0;
}
```

### 域重复单元分解

```glsl
void cell2(vec2 p, out vec2 id, out vec2 localP) {
    id = floor(p);
    localP = fract(p) - 0.5;
}
```

### Fresnel Schlick 近似

```glsl
float fresnelSchlick(float cosTheta, float F0) {
    return F0 + (1.0 - F0) * pow(1.0 - cosTheta, 5.0);
}
```

### 海面折浪 octave（摘录）

📄 `002224-Ms2SD1-Seascape/image.glsl`：

<!-- glsl-skip -->
```glsl
float sea_octave(vec2 uv, float choppy) {
    uv += noise2(uv);
    vec2 wv = 1.0 - abs(sin(uv));
    vec2 swv = abs(cos(uv));
    wv = mix(wv, swv, wv);
    return pow(1.0 - pow(wv.x * wv.y, 0.65), choppy);
}
```

（原文 `noise` 返回约 [-1,1]；若你用 A.2.1，语义一致。）

---

## A.14 最小 Raymarch 骨架（合成示例）

<!-- glsl-skip -->
```glsl
float map(vec3 p) {
    return sdSphere(p, 0.5);
}

float castRay(vec3 ro, vec3 rd) {
    float t = 0.0;
    for (int i = 0; i < 64; i++) {
        float d = map(ro + rd * t);
        if (d < 0.001 * t || t > 50.0) break;
        t += d;
    }
    return t;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = normUV(fragCoord);
    vec3 ro = vec3(0.0, 0.0, 3.0);
    vec3 ta = vec3(0.0);
    vec3 rd = rayDir(fragCoord, ro, ta, 1.5);
    float t = castRay(ro, rd);
    vec3 col = vec3(0.05);
    if (t < 50.0) {
        vec3 p = ro + rd * t;
        vec3 n = calcNormal(p);
        vec3 l = normalize(vec3(0.6, 0.8, -0.4));
        float dif = clamp(dot(n, l), 0.0, 1.0);
        float sh = softshadow(p + n * 0.01, l, 0.02, 10.0, 8.0);
        float ao = calcAO(p, n);
        col = vec3(0.2, 0.4, 0.9) * dif * sh * ao + 0.05;
    }
    col = applyVignette(col, fragCoord);
    fragColor = vec4(col, 1.0);
}
```

把 `map` 换成你的场，就是语料里三分之一作品的起点。

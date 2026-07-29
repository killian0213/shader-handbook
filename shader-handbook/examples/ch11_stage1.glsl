// 第 11 章 · 阶梯实战 · 阶段 1：最朴素的 Mandelbrot
// 迭代次数直接当灰度。它很丑 —— 集合外面那一圈圈同心色带就是后面几步要消灭的东西。
// 先把病灶看清楚，再理解药方，这是本节的顺序。

const int   MAX_ITER = 64;
const float BAILOUT  = 2.0;          // 朴素判据：|z| 一旦超过 2 就一定跑飞

const vec2  CENTER = vec2(-0.7436, 0.0);
const float HALF_H = 1.35;           // 视野半高，单位是复平面

// 返回逃逸之前跑了几次迭代。返回值是【整数】，这正是色带的来源。
float mandel(vec2 c)
{
    vec2  z = vec2(0.0);
    float n = 0.0;
    for (int i = 0; i < MAX_ITER; i++)
    {
        // z ← z² + c。复数平方 (x+yi)² = (x²-y²) + 2xy·i，GLSL 没有复数，用 vec2 手写
        z = vec2(z.x * z.x - z.y * z.y, 2.0 * z.x * z.y) + c;
        // dot(z,z) 就是 |z|²，比 length(z) 省一次 sqrt。整个循环里最该省的就是它
        if (dot(z, z) > BAILOUT * BAILOUT) break;
        n += 1.0;
    }
    return n;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = (2.0 * fragCoord - iResolution.xy) / iResolution.y;
    vec2 c  = CENTER + uv * HALF_H;

    float n   = mandel(c);
    vec3  col = vec3(n / float(MAX_ITER));   // 迭代次数直接当亮度

    fragColor = vec4(col, 1.0);
}

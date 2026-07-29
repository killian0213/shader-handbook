// 第 3 章 · 阶梯实战 · 阶段 1：表壳
// 只有圆和圆环。先把坐标系、抗锯齿宽度、图层顺序这三件事定下来。
const float TAU = 6.2831853;

// 霓虹三色。全书后面所有零件都从这三个里选，画面才不会花。
const vec3 CY = vec3(0.36, 0.90, 1.00);   // 青：结构线
const vec3 AM = vec3(1.00, 0.74, 0.32);   // 琥珀：指针
const vec3 MG = vec3(1.00, 0.34, 0.72);   // 品红：秒/进度

float sdCircle(vec2 p, float r)
{
    return length(p) - r;
}

// 圆环 = 洋葱化的圆：先取 |到圆周的距离|，再当成一条宽 2w 的带子
float sdRing(vec2 p, float r, float w)
{
    return abs(length(p) - r) - w;
}

// 填充蒙版：d<0 为 1。过渡带正好跨在 d=0 上，各半个像素
float fill(float d, float aa)
{
    return smoothstep(aa, -aa, d);
}

// 描边蒙版：|d|<w 的一条带子
float stroke(float d, float w, float aa)
{
    return smoothstep(aa, -aa, abs(d) - w);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2  p  = (2.0 * fragCoord - iResolution.xy) / iResolution.y;
    float aa = 2.0 / iResolution.y;                 // 一个像素在 p 空间里的宽度

    // 表壳中心往下挪 0.10，给上面的表冠和提环留位置。
    // 所有属于"表"的零件都用 q，属于"画面"的（背景、暗角）才用 p。
    vec2 q = p - vec2(0.0, -0.10);

    // 背景：中间稍亮的冷灰，向外掉到近黑。霓虹必须有黑底才亮得起来。
    vec3 col = mix(vec3(0.050, 0.070, 0.110), vec3(0.006, 0.008, 0.020),
                   smoothstep(0.05, 1.25, length(p)));

    float dCase  = sdCircle(q, 0.62);               // 壳体外缘
    float dBezel = sdRing(q, 0.595, 0.025);         // 表圈：0.570 ~ 0.620 的一条环带
    float dDial  = sdCircle(q, 0.555);              // 盘面

    // 图层顺序：暗底从大到小依次盖，最后才用亮线勾边。
    col = mix(col, vec3(0.030, 0.045, 0.075), fill(dCase,  aa));
    col = mix(col, vec3(0.075, 0.115, 0.170), fill(dBezel, aa));
    col = mix(col, vec3(0.012, 0.020, 0.038), fill(dDial,  aa));

    col = mix(col, CY,       stroke(dCase, 0.0045, aa));
    col = mix(col, CY * 0.7, stroke(dDial, 0.0035, aa));

    fragColor = vec4(col, 1.0);
}

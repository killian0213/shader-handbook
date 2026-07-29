// Image (image) — Trilinear Isosurface Explorer by oneshade
// https://www.shadertoy.com/view/3tyfzV

// Line drawing utility
void drawLine(inout vec3 color, in vec3 lineColor, in vec2 p, in vec2 a, in vec2 b) {
     float unit = 2.0 / iResolution.y;
 
     vec2 pa = p - a, ba = b - a;
     float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
     float d = length(pa - ba * h);
 
     color = mix(color, lineColor, smoothstep(unit, 0.0, d));
}

// Modified version of font loader from https://www.shadertoy.com/view/ltcXzs
void drawChar(inout vec3 color, in vec3 charColor, in vec2 uv, in vec2 pos, in vec2 size, in int char) {
    uv = (uv - pos) / size + 0.5;
    vec2 charUv = uv / 16.0;
    vec2 dfdx = dFdx(charUv);
    vec2 dfdy = dFdy(charUv);
    if (all(lessThan(abs(uv - 0.5), vec2(0.5)))) {
        float val = textureGrad(iChannel1, charUv + fract(vec2(char, 15 - char / 16) / 16.0), dfdx, dfdy).r;
        color = mix(color, charColor, val);
    }
}

// Quick slider drawing function, not super customizable
void drawSlider(inout vec3 color, in vec2 p, in vec2 pos, in float len, in float rmin, in float rmax, in float val) {
    p -= pos;

    float hlen = 0.5 * len;
    float unit = 2.0 / iResolution.y;

    float d = length(vec2(max(0.0, abs(p.x) - hlen), p.y)) - 0.01;
    color = mix(color, vec3(0.5), smoothstep(unit, 0.0, d));

    d = length(p - vec2(mix(-hlen, hlen, (val - rmin) / (rmax - rmin)), 0.0)) - 0.02;
    color = mix(color, vec3(1.0), smoothstep(unit, 0.0, d));
}

// Cubic solver
const vec2 eta = vec2(-0.5, sqrt(0.75));
int solveCubic(in float a, in float b, in float c, in float d, out vec3 roots) {
    float h = 18.0 * a * b * c * d - 4.0 * b * b * b * d + b * b * c * c - 4.0 * a * c * c * c - 27.0 * a * a * d * d;

    b /= a, c /= a, d /= a;
    float d0 = b * b - 3.0 * c;
    float d1 = (2.0 * b * b - 9.0 * c) * b + 27.0 * d;
    float q = d1 * d1 - 4.0 * d0 * d0 * d0, j = sqrt(abs(q));

    vec2 C = q < 0.0 ? vec2(d1, j) : vec2(d1 + j, 0.0);
    if (abs(C.x) + abs(C.y) < 1e-3) C = vec2(d1 - j, 0.0);
    float t = atan(C.y, C.x) / 3.0, r = pow(0.25 * dot(C, C), 1.0 / 6.0);
    C = vec2(cos(t), sin(t));

    float w = -d0 / r - r;
    roots.x = (C.x * w - b) / 3.0;
    roots.y = (dot(vec2(C.x, -C.y), eta) * w - b) / 3.0;
    if (h > 0.0) roots.z = (dot(C, eta) * w - b) / 3.0;
    else if (abs(dot(C.yx, eta)) < abs(C.y)) roots.x = roots.y;

    return h < 0.0 ? 1 : 3;
}

vec4 solveCubic2(in float a, in float b, in float c, in float d) {
    vec3 roots;
    int nroots = solveCubic(d, c, b, a, roots);
    roots.x = 1.0 / roots.x;
    if (nroots > 1) roots.yz = 1.0 / roots.yz;
    return vec4(roots, nroots);
}

// Intersection
vec4 iTrilinearIsoSurf(in vec3 ro, in vec3 rd, in float a, in float b, in float c, in float d, in float e, in float f, in float g, in float h) {
    vec4 u = vec4(-a + b + c - d + e - f - g + h, a - b - c + d, a - b - e + f, a - c - e + g);
    vec3 v = vec3(b, c, e) - a;

    vec3 xxyyzz = ro.xxy * ro.yzz;
    vec3 uuvvww = rd.xxy * rd.yzz;

    float t3 = u.x * rd.x * rd.y * rd.z;
    float t2 = dot(ro.zyx, uuvvww) * u.x + dot(u.yzw, uuvvww);
    float t1 = dot(u, vec4(dot(xxyyzz, rd.zyx), dot(ro.xy, rd.yx), dot(ro.xz, rd.zx), dot(ro.yz, rd.zy))) + dot(v, rd);
    float t0 = u.x * ro.x * ro.y * ro.z + dot(u.yzw, xxyyzz) + dot(v, ro) + a;

    return solveCubic2(t3, t2, t1, t0);
}

// Normal
vec3 nTrilinearIsoSurf(in vec3 p, in float a, in float b, in float c, in float d, in float e, in float f, in float g, in float h) {
    vec4 u = vec4(-a + b + c - d + e - f - g + h, a - b - c + d, a - b - e + f, a - c - e + g);
    return normalize(u.x * p.yxx * p.zzy + u.yyz * p.yxx + u.zww * p.zzy + vec3(b, c, e) - a);
}

bool intersectIsValid(in vec3 p, in float t) {
    return t > 0.0 && all(lessThan(abs(p - 0.5), vec3(0.5)));
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 center = 0.5 * iResolution.xy;

    vec2 mouse = ((iMouse.xy - center) / iResolution.y - renderOffs) * 3.14;
    if (ivec2(iMouse.xy) == ivec2(0)) mouse = vec2(0.0);
    if (mouse.x < -1.5) mouse = vec2(0.0);

    vec2 uv1 = (fragCoord - center) / iResolution.y, uv2 = uv1 - renderOffs;
    fragColor = vec4(0.0, 0.0, 0.0, 1.0);

    vec3 ro = vec3(0.0, 0.0, 3.0);
    vec3 rd = normalize(vec3(uv2, -1.0));

    // Rotate with mouse
    float cy = cos(mouse.x), sy = sin(mouse.x);
    float cp = cos(mouse.y), sp = sin(mouse.y);

    ro.yz *= mat2(cp, -sp, sp, cp);
    ro.xz *= mat2(cy, -sy, sy, cy);
    rd.yz *= mat2(cp, -sp, sp, cp);
    rd.xz *= mat2(cy, -sy, sy, cy);

    // Center (the surface goes from (0, 0, 0) to (1, 1, 1))
    ro += 0.5;

    // Isovalues
    float a = texelFetch(iChannel0, ivec2(0, 0), 0).x;
    float b = texelFetch(iChannel0, ivec2(1, 0), 0).x;
    float c = texelFetch(iChannel0, ivec2(2, 0), 0).x;
    float d = texelFetch(iChannel0, ivec2(3, 0), 0).x;
    float e = texelFetch(iChannel0, ivec2(4, 0), 0).x;
    float f = texelFetch(iChannel0, ivec2(5, 0), 0).x;
    float g = texelFetch(iChannel0, ivec2(6, 0), 0).x;
    float h = texelFetch(iChannel0, ivec2(7, 0), 0).x;

    vec4 intersect = iTrilinearIsoSurf(ro, rd, a, b, c, d, e, f, g, h);
    int numIntersects = int(intersect[3]);

    // Find closest valid intersection
    vec3 hitPos;
    float tMin = 1000000.0;
    bool intersecting = false;
    for (int i=0; i < numIntersects; i++) {
        vec3 posCandid = ro + rd * intersect[i];
        float tCandid = intersect[i];
        if (intersectIsValid(posCandid, tCandid) && tCandid < tMin) {
            hitPos = posCandid;
            tMin = tCandid;
            intersecting = true;
        }
    }

    // Render the surface
    if (intersecting) {
        vec3 n = nTrilinearIsoSurf(hitPos, a, b, c, d, e, f, g, h);
        fragColor = vec4(abs(n), 1.0);
    }

    // Bounding box geometry
    vec3[] bboxVerts = vec3[8](vec3(-0.5, -0.5, -0.5), vec3( 0.5, -0.5, -0.5),
                               vec3(-0.5,  0.5, -0.5), vec3( 0.5,  0.5, -0.5),
                               vec3(-0.5, -0.5,  0.5), vec3( 0.5, -0.5,  0.5),
                               vec3(-0.5,  0.5,  0.5), vec3( 0.5,  0.5,  0.5));

    ivec2[] bboxEdges = ivec2[12](ivec2(0, 1), ivec2(1, 3), ivec2(3, 2), ivec2(2, 0),
                                  ivec2(0, 4), ivec2(1, 5), ivec2(2, 6), ivec2(3, 7),
                                  ivec2(4, 5), ivec2(5, 7), ivec2(7, 6), ivec2(6, 4));

    // Transform bounding box vertices
    for (int v=0; v < 8; v++) {
        vec3 vert = bboxVerts[v];
        vert.xz *= mat2(cy, sy, -sy, cy);
        vert.yz *= mat2(cp, sp, -sp, cp);
        vert.z -= 3.0;
        bboxVerts[v] = vert;
    }

    // Render bounding box
    for (int e=0; e < 12; e++) {
        ivec2 edge = bboxEdges[e];
        vec3 a1 = bboxVerts[edge[0]];
        vec3 b1 = bboxVerts[edge[1]];
        if (max(-a1.z, -b1.z) < tMin) {
            vec2 a2 = -a1.xy / a1.z;
            vec2 b2 = -b1.xy / b1.z;
            drawLine(fragColor.rgb, vec3(0.0, 1.0, 0.0), uv2, a2, b2);
        }
    }

    // Draw sliders
    float hlen = 0.5 * sliderLen;
    float[] isovalues = float[8](a, b, c, d, e, f, g, h);
    int[] chars = int[8](65, 66, 67, 68, 69, 70, 71, 72); // A, B, C, D, E, F, G, H
    for (int i=0; i < 8; i++) {
        drawSlider(fragColor.rgb, uv1, sliders[i], sliderLen, sliderMin, sliderMax, isovalues[i]);
        drawChar(fragColor.rgb, vec3(1.0), uv1, vec2(sliders[i].x + hlen + 0.075, sliders[i].y), vec2(0.065), chars[i]);

        // Label the corner
        vec3 corner = bboxVerts[i];
        if (-corner.z < tMin) {
            corner.xy += normalize(corner.xy) * 0.1;
            vec2 charPos = -corner.xy / corner.z;
            drawChar(fragColor.rgb, vec3(1.0), uv2, charPos, vec2(0.065), chars[i]);
        }
    }

    // -
    drawChar(fragColor.rgb, vec3(1.0), uv1, vec2(sliders[0].x - hlen, sliders[0].y + 0.085), vec2(0.065), 45);

    // 5
    drawChar(fragColor.rgb, vec3(1.0), uv1, vec2(sliders[0].x - hlen + 0.025, sliders[0].y + 0.085), vec2(0.065), 53);

    // 0
    drawChar(fragColor.rgb, vec3(1.0), uv1, vec2(sliders[0].x, sliders[0].y + 0.085), vec2(0.065), 48);

    // 5
    drawChar(fragColor.rgb, vec3(1.0), uv1, vec2(sliders[0].x + hlen - 0.025, sliders[0].y + 0.085), vec2(0.065), 53);
}
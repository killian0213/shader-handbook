// Buffer B (buffer) — Smooth Mouse Drawing by fad
// https://www.shadertoy.com/view/dldXR7

// This buffer maintains the SDF for the drawing.

// .x: SDF with quadratic bezier curves
// .y: SDF with linear segments
// .z: SDF for mouse points

float sdSegment(vec2 p, vec2 a, vec2 b) {
    vec2 ap = p - a;
    vec2 ab = b - a;
    return distance(ap, ab * clamp(dot(ap, ab) / dot(ab, ab), 0.0, 1.0));
}

void mainImage(out vec4 fragColor, vec2 fragCoord) {
    float qd = 1e30;
    float ld = 1e30;
    float pd = 1e30;
    
    if (iFrame != 0) {
        qd = texelFetch(iChannel1, ivec2(fragCoord), 0).r;
        ld = texelFetch(iChannel1, ivec2(fragCoord), 0).g;
        pd = texelFetch(iChannel1, ivec2(fragCoord), 0).b;
    }
    
    vec4 mouseA = iFrame > 0 ? texelFetch(iChannel0, ivec2(0, 0), 0) : vec4(0.0);
    vec4 mouseB = iFrame > 0 ? texelFetch(iChannel0, ivec2(1, 0), 0) : vec4(0.0);
    vec4 mouseC = iFrame > 0 ? texelFetch(iChannel0, ivec2(2, 0), 0) : iMouse;
    
    // A: mouse from previous previous frame
    // B: mouse from previous frame
    // C: mouse from this frame
    
    mouseA.xy += 0.5;
    mouseB.xy += 0.5;
    mouseC.xy += 0.5;
    
    if (mouseC.z > 0.0) {
        pd = min(pd, distance(fragCoord, mouseC.xy));
    }
    
    if (mouseB.z > 0.0 && mouseC.z > 0.0) {
        ld = min(ld, sdSegment(fragCoord, mouseB.xy, mouseC.xy));
    } else if (mouseC.z > 0.0) {
        ld = min(ld, distance(fragCoord, mouseC.xy));
    }
    
    if (mouseB.z <= 0.0 && mouseC.z > 0.0) {
        qd = min(qd, distance(fragCoord, mouseC.xy));
    } else if (mouseA.z <= 0.0 && mouseB.z > 0.0 && mouseC.z > 0.0) {
        qd = min(qd, sdSegment(fragCoord, mouseB.xy, mix(mouseB.xy, mouseC.xy, 0.5)));
    } else if (mouseA.z > 0.0 && mouseB.z > 0.0 && mouseC.z > 0.0) {
        qd = min(qd, abs(sdBezier(fragCoord, mix(mouseA.xy, mouseB.xy, 0.5), mouseB.xy, mix(mouseB.xy, mouseC.xy, 0.5))));
    } else if (mouseA.z > 0.0 && mouseB.z > 0.0 && mouseC.z <= 0.0) {
        qd = min(qd, sdSegment(fragCoord, mix(mouseA.xy, mouseB.xy, 0.5), mouseB.xy));
    }
    
    fragColor.r = qd;
    fragColor.g = ld;
    fragColor.b = pd;
}
// Buffer A (buffer) — Analytic Direct Lighting by fad
// https://www.shadertoy.com/view/dlcXR4

// This buffer just handles the interactive geometry.

void mainImage(out vec4 fragColor, vec2 fragCoord) {
    int i = int(fragCoord.x) + int(iResolution.x) * int(fragCoord.y);
    
    if (i >= numPoints) {
        return;
    }
    
    if (iFrame == 0) {
        fragColor.xy = vec2[](
            vec2(0.2, 0.8),
            vec2(0.35, 0.8),
            vec2(0.45, 0.8),
            vec2(0.7, 0.8),
            vec2(0.6, 0.8),
            vec2(0.6, 0.5),
            vec2(0.7, 0.8),
            vec2(0.7, 0.5),
            vec2(0.6, 0.5),
            vec2(0.65, 0.5),
            vec2(0.8, 0.35),
            vec2(0.8, 0.15),
            vec2(0.8, 0.15),
            vec2(0.2, 0.15),
            vec2(0.2, 0.15),
            vec2(0.2, 0.8),
            vec2(0.6, 0.15),
            vec2(0.6, 0.35),
            vec2(0.8, 0.35),
            vec2(0.65, 0.35),
            vec2(0.7, 0.2),
            vec2(0.75, 0.22),
            vec2(0.625, 0.55),
            vec2(0.6875, 0.52),
            vec2(0.6, 0.35),
            vec2(0.65, 0.35)
        )[i] * iResolution.xy;
        fragColor.z = 0.0;
        return;
    }
    
    int bestIndex = -1;
    float bestDist = 1e10;
    
    if (iMouse.z > 0.0) {
        for (int j = 0; j < numPoints; ++j) {
            vec4 data = getPointData(j);
            
            if (data.z > 0.0) {
                bestIndex = j;
                break;
            }
            
            vec2 p = data.xy;
            float d = distance(p, iMouse.xy);
            
            if (d < min(CONTROL_RADIUS, bestDist) && iMouse.w > 0.0) {
                bestIndex = j;
                bestDist = d;
            }
        }
    }
    
    if (i == bestIndex) {
        vec4 data = getPointData(i);
        
        if (data.z <= 0.0) {
            fragColor.zw = iMouse.xy;
        } else {
            fragColor.zw = data.zw;
        }
        
        fragColor.xy = getPoint(i) + iMouse.xy - fragColor.zw;
        fragColor.zw = iMouse.xy;
    } else {
        fragColor.xy = getPoint(i);
        fragColor.zw = vec2(0.0);
    }
    
    if (i == 25) {
        vec2 a = getPoint(24);
        vec2 b = fragColor.xy;
        float r = distance(a, b);
        float t = (0.5 - 0.5 * cos(iTime)) * PI;
        fragColor.xy = a + r * vec2(cos(t), sin(t));
    }
}
// Buffer A (buffer) — Cube Castle by mhnewman
// https://www.shadertoy.com/view/DtBGzt

vec4 run(vec2 pos) {    
    float height = 0.0;
    for (int i = 0; i < 20; ++i) {
        float id = float(i);
        id += iTime + 0.2;
        float top = floor(1.0 + maxFloor * hash1(id));
        vec2 center = 12.0 * hash2(id) - 6.0;
        vec2 size = floor(0.45 * (0.5 + hash2(id + 0.1)) * (maxFloor - top + 2.0));
        if (pos.x > center.x - size.x &&
            pos.x < center.x + size.x &&
            pos.y > center.y - size.y &&
            pos.y < center.y + size.y) {

            height = max(height, top);
        }
    }
    
    vec2 center = 6.0 * hash2(iTime + 0.1) - 3.0;
    vec2 size = vec2(1.0);
    if (pos.x > center.x - size.x &&
        pos.x < center.x + size.x &&
        pos.y > center.y - size.y &&
        pos.y < center.y + size.y) {

        height = max(height, maxFloor);
    }

    return vec4(height);
}

vec4 runFlag() {
    return vec4(floor(6.0 * hash2(iTime + 0.1) - 3.0), 0.0, 0.0);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 pos = floor(fragCoord - 0.5 * iResolution.xy);

    vec4 frame = texture(iChannel0, vec2(0.5) / iResolution.xy);
    vec4 last = texture(iChannel0, vec2(1.5, 0.5) / iResolution.xy);
    float restart = step(abs(frame.y - iResolution.x - iResolution.y), 0.5);
    restart *= float(iMouse.z < 0.5 || last.z > 0.5);

    fragColor = texture(iChannel0, fragCoord.xy / iResolution.xy);
    vec4 flag = texture(iChannel0, vec2(0.5, 1.5) / iResolution.xy);
    if (restart < 0.5) {
        frame.x = step(5.0, iTime) * step(0.8, hash1(iTime));
        fragColor = run(pos);
        flag = runFlag();
    }

    frame.y = iResolution.x + iResolution.y;
    frame.z = mix(1.0, frame.z + 1.0, restart);
    frame.w = restart;

    if (fragCoord.x < 1.0 && fragCoord.y < 1.0)
        fragColor = frame;
    else if (fragCoord.x < 2.0 && fragCoord.y < 1.0)
        fragColor = iMouse;
    else if (fragCoord.x < 1.0 && fragCoord.y < 2.0)
        fragColor = flag;
}
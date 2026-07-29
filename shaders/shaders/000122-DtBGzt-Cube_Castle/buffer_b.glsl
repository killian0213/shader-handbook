// Buffer B (buffer) — Cube Castle by mhnewman
// https://www.shadertoy.com/view/DtBGzt

#define BufA(pos) texture(iChannel0, (floor(pos + 0.5 * iResolution.xy) + 0.5) / iResolution.xy).x

float buildWindow(vec2 pos) {
    vec4 h = hash4(vec2(pos.x, iTime));
    if ((h.w > 0.4 &&
         (mod(pos.y, blockSize) == floor(0.5 * blockSize - 0.5))) ||
        (h.w < 0.6 &&
         (mod(pos.y, blockSize) == floor(0.5 * blockSize + 0.5)))) {
        vec2 h2 = hash2(vec3(pos.x, floor(pos.y / blockSize), iTime));
        float windowSize = floor(1.0 + 3.0 * h.x);
        float windowStart = floor(0.5 + 1.5 * h.y) + floor(1.3 * h2.x);
        float windowSkip = floor(2.0 * h.z + 0.9) + floor(1.3 * h2.y);
        return floor(4.0 * (4.0 * windowSkip + windowStart) + windowSize);
    }
    return 0.0;
}

vec4 run(vec2 pos) {
    vec2 block = floor(pos.xy / blockSize);
    float center = BufA(block);
    float height = blockHeight * center;
    float window = 0.0;
    float roof = 0.0;
    float tree = 0.0;
    float flag = 0.0;
    
    if (height > 0.5) {
        if ((mod(pos.x, blockSize) < 0.5 && BufA(block + vec2(-1.0, 0.0)) < center) ||
            (mod(pos.x, blockSize) > blockSize - 1.5 && BufA(block + vec2(1.0, 0.0)) < center)) {
            height += 1.0 + mod(pos.x + pos.y, 2.0);
            window = buildWindow(pos);
        } else if ((mod(pos.y, blockSize) < 0.5 && BufA(block + vec2(0.0, -1.0)) < center) ||
            (mod(pos.y, blockSize) > blockSize - 1.5 && BufA(block + vec2(0.0, 1.0)) < center)) {
            height += 1.0 + mod(pos.x + pos.y, 2.0);
            window = buildWindow(pos.yx);
        } else if (hash1(vec2(height, iTime)) < 0.3) {
            float dist = blockSize * 3.0;
            vec2 p = pos - blockSize * block;
            for (float x = -4.0; x < 4.5; x += 1.0) {
                for (float y = -4.0; y < 4.5; y += 1.0) {
                    if (BufA(block + vec2(x, y)) < center - 0.5) {
                        float d = max(abs(blockSize * (x + 0.5) - p.x - 0.5), abs(blockSize * (y + 0.5) - p.y - 0.5));
                        dist = min(dist, 0.6 * d - 0.1);
                    }
                }
            }
            roof = height + dist;
        } else if (center < 2.5) {
            bool garden = true;
            for (float x = -1.0; x < 1.5; x += 1.0) {
                for (float y = -1.0; y < 1.5; y += 1.0) {
                    garden = garden && (BufA(block + vec2(x, y)) > center - 0.5);
                }
            }
            if (garden) {
                height = 0.0;
                tree = 1.0;
            }
        }
    } else {
        for (float x = -1.0; x < 1.5; x += 1.0) {
            for (float y = -1.0; y < 1.5; y += 1.0) {
                vec2 offset = vec2(x, y);
                vec2 id = block + offset;
                float clear = 0.0;
                for (float u = -1.0; u < 1.5; u += 1.0) {
                    for (float v = -1.0; v < 1.5; v += 1.0) {
                        clear += BufA(id + vec2(u, v));
                    }
                }
                if (clear < 0.5 && hash1(vec3(id, iTime + 0.2)) < 0.4) {
                    vec2 treeCenter = blockSize * hash2(vec3(id, iTime));
                    float treeSize = 1.0 + 3.0 * hash1(vec3(id, iTime + 0.1));
                    treeCenter += blockSize * offset;
                    float t = treeSize - distance(treeCenter, pos.xy - blockSize * block);
                    tree = max(tree, 4.0 * t);
                }
            }
        }
    }
    
    vec4 h = hash4(iTime + 0.1);
    
    vec4 flagCenter = texture(iChannel0, vec2(0.5, 1.5) / iResolution.xy);
    vec2 flagPole = blockSize * flagCenter.xy + vec2(2.0, 2.0) + floor((2.0 * blockSize - 4.0) * h.xy);
    if (pos == flagPole)
        height = blockHeight * maxFloor + 7.0 + floor(3.0 * h.w);
    
    for (float y = 1.0; y < 1.5 + floor(3.0 * h.z); y += 1.0)
        if (pos == flagPole + vec2(0.0, y))
            flag = blockHeight * maxFloor + 6.0 + 0.25 * floor(1.0 + 3.0 * h.w);
    
    return vec4(height, window, roof - tree, flag);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 pos = floor(fragCoord - 0.5 * iResolution.xy);

    vec4 frame = texture(iChannel0, vec2(0.5) / iResolution.xy);

    fragColor = texture(iChannel1, fragCoord.xy / iResolution.xy);
    if (frame.w < 0.5) {
        fragColor = run(pos);
    }
}
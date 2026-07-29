// Buffer A (buffer) — Cube Falls by mhnewman
// https://www.shadertoy.com/view/dtSGWd

vec2 rotate(vec2 pos, float angle) {
    angle *= 6.2831853;
    float s = sin(angle);
    float c = cos(angle);
    mat2 rot = mat2(c, -s, s, c);
    return rot * pos;
}

vec2 rotate(vec2 pos, float angle, float hash) {
    return rotate(pos, angle * (2.0 * hash1(hash) - 1.0));
}

void waterfall(inout float ground, inout float depth, float dist, vec2 pos, float id) {
    vec2 h = hash2(id);
    float fall = 50.0 * (h.x - 0.5) + 20.0 * fbm1(0.03 * pos.x + 100.0 * id);
    float sq = sqrt(dist);
    ground += 8.0 * h.y * h.y * smoothstep(fall - 4.0 * sq, fall - 2.0 * sq, pos.y);
    float foam = 1.0 - h.y + 0.1 * (fall - pos.y);
    depth = mix(depth, min(depth, foam), step(pos.y, fall));
}

float terrain(vec2 pos, float id) {
    vec4 h = hash4(id);

    vec2 p = rotate(pos, 0.125);
    p = rotate(p, 0.15, id + 0.01);

    float width = 6.0 + 10.0 * h.x;
    float spread = 0.03 * h.y;
    width *= exp(-spread * p.y);

    float dist = abs(p.x) - width;
    dist = mix(dist, 7.0 * dist / width, step(dist, 0.0));
    dist += 20.0 * fbm1(0.1 * p + 10.0 * id);
    
    float land = step(0.0, dist);
    float depth = 0.5 - 0.2 * dist;
    dist = max(dist, 0.0);

    float plateau = 3.0 + 7.0 * h.z;
    float slope = 0.1 + 1.2 * h.w;
    float ground = plateau * (1.0 - exp(-slope * dist / plateau));
    
    waterfall(ground, depth, dist, rotate(p, 0.1, id + 0.11), id + 0.1);
    waterfall(ground, depth, dist, rotate(p, 0.1, id + 0.21), id + 0.2);
    waterfall(ground, depth, dist, rotate(p, 0.1, id + 0.31), id + 0.3);
    waterfall(ground, depth, dist, rotate(p, 0.1, id + 0.41), id + 0.4);
    waterfall(ground, depth, dist, rotate(p, 0.1, id + 0.51), id + 0.5);
    waterfall(ground, depth, dist, rotate(p, 0.1, id + 0.61), id + 0.6);
    
    ground = floor(ground);

    if (land > 0.5) {
        ground += 1.0;
        
        float rocks = step(dist, 4.0 + 6.0 * fbm1(0.3 * p));
        ground += 0.5 * rocks;
        
        vec2 h2 = hash2(id + 0.02);
        float grassProb = 0.2 + 0.8 * h2.x;
        float grassDist = 2.0 + 15.0 * h.y;
        float grass = grassProb * smoothstep(0.0, grassDist, dist);
        grass = step(hash1(vec3(p, id)), grass);
        ground += 1.25 * grass;

        ground = -ground;
    } else {
        ground += step(3.5 * depth, hash1(vec3(p, id)));
        ground += 0.5 * clamp(depth, 0.0, 1.0);
    }
    
    return ground;
}

vec4 run(vec2 pos, float id) {
    vec4 h1 = hash4(id + 0.8);
    float treeSpacing = 8.0 + 8.0 * h1.x;
    float treeSize = (0.6 + 0.4 * h1.y) * treeSpacing;
    float treeProb = 0.1 + 1.5 * h1.z;

    vec4 h2 = hash4(id + 0.9);
    float canopyBottom = 0.8 + 0.8 * h2.x;
    float canopyTop = 0.3 + 1.2 * h2.y;
    
    float colorMin = pow(min(h1.w, h2.w), 1.5);
    float colorScale = pow(max(h1.w, h2.w), 0.7) - colorMin;

    vec2 block = floor(pos / treeSpacing);
    vec2 p = pos - treeSpacing * block;
    float treeTop = 0.0;
    float treeBottom = 1000.0;
    float trunkTop = 0.0;
    float trunkBottom = 1000.0;
    float color = 0.0;
    for (float x = -1.0; x < 1.5; x += 1.0) {
        for (float y = -1.0; y < 1.5; y += 1.0) {
            vec2 offset = vec2(x, y);
            vec2 treeId = block + offset;

            vec4 h1 = hash4(vec3(treeId, id));
            vec4 h2 = hash4(vec3(treeId, id + 0.1));

            vec2 treeCenter = treeSpacing * (h1.xy + offset);
            vec2 trunkCenter = treeSpacing * block + treeCenter;
            float ground = terrain(trunkCenter, id);
            
            float radius = (0.5 + 0.5 * h2.x) * treeSize;
            float bottom = canopyBottom * radius;
            float top = canopyTop * radius;
            
            float d = distance(p, treeCenter);
            float r = d / radius;
            float canopy = 1.0 - r * r + 2.0 * fbm1(0.25 * pos);
            canopy *= canopyTop * radius;
            if (ground < -1.0 && canopy > 0.0 && treeProb > h2.y) {
                float bottom = canopyBottom * radius;
                ground = floor(abs(ground));
                float treeT = floor(canopy + ground + bottom);
                float treeB = floor(ground + bottom - 1.0);
                float trunkT = treeT;
                float trunkB = ground - 1.0;
                bool isTrunk = floor(p) == floor(treeCenter) || r < 0.1;
                bool wasTrunk = color == 0.0;
                float treeColor = colorMin + colorScale * h2.z;
                if (treeT > treeTop) {
                    if (isTrunk) {
                        trunkTop = trunkT;
                        trunkBottom = trunkB;
                        color = 0.0;
                    } else {
                        if (!wasTrunk) {
                            trunkTop = treeTop;
                            trunkBottom = treeBottom;
                            color = 1.0 + floor(16.0 * fract(color));
                        }
                    }
                    treeTop = treeT;
                    treeBottom = treeB;
                    color += treeColor;
                } else if (!wasTrunk && treeT > trunkTop) {
                    if (isTrunk) {
                        trunkTop = trunkT;
                        trunkBottom = trunkB;
                        color = fract(color);
                    } else {
                        trunkTop = treeT;
                        trunkBottom = treeB;
                        color = fract(color) + 1.0 + floor(16.0 * treeColor);;
                    }
                }
            }
        }
    }
    treeBottom = clamp(treeBottom, treeTop - 16.0, treeTop - 1.0);
    float tree = treeTop + (treeTop - treeBottom - 1.0) / 16.0;
    
    trunkTop = clamp(trunkTop, trunkBottom + 1.0, trunkBottom + 16.0);
    float trunk = trunkTop + (trunkTop - trunkBottom - 1.0) / 16.0;
    
    return vec4(terrain(pos, id), tree, trunk, color);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 pos = floor(fragCoord - 0.5 * iResolution.xy);

    vec4 frame = texture(iChannel0, vec2(0.5) / iResolution.xy);
    bool resize = abs(frame.x - iResolution.x) + abs(frame.y - iResolution.y) > 0.5;
    
#if SCENE_TIME == 0
    float id = iTime;
    bool restart = iMouse.z > 0.5 && texture(iChannel0, vec2(1.5, 0.5) / iResolution.xy).z < 0.5;
#else
    float id = floor(iTime / float(SCENE_TIME)) + 45.0;
    bool restart = abs(id - frame.w) > 0.01;
#endif

    frame.xy = iResolution.xy;
    frame.z += 1.0;;
    fragColor = texture(iChannel0, fragCoord.xy / iResolution.xy);
    if (resize || restart) {
        fragColor = run(pos, id);
        frame.z = 1.0;
        frame.w = id;
    }

    if (fragCoord.x < 1.0 && fragCoord.y < 1.0)
        fragColor = frame;
    else if (fragCoord.x < 2.0 && fragCoord.y < 1.0)
        fragColor = iMouse;
}
// Buffer A (buffer) — Cube House by mhnewman
// https://www.shadertoy.com/view/3XSXDm

/*

Buffer A format:

.x := House structure
      3 bits per floor, 4 floors
    0 := Empty
    1 := Post
    2 := Ceiling
    3 := Window frame
    4 := Roof
    5 := Frame above, wall below
    6 := Gutter
    7 := Window/Wall (Needs hint, see .y)
    
    Bottom floor (basement) uses the same lower 2 bits as upper floors, but MSB is beam flag

.y := Window hints
      Because of how I clumsily designed this, x- and y-facing sides need different window hints
      2 bits per floor, 3 floors, each side:
    0 := Floor to ceiling wall
    1 := Floor to ceiling window
    2 := Windows above and below frame
    3 := Window above, wall below frame

.z := Ground height

.w := Ground color
    0-1 := Shades of vegitation
    <0 := Color index

*/

bool hasPool(float id) {
    return hash1(id + 0.3) < chanceForPool;
}
bool isPool(vec2 pos, float id) {
    float h = id + 0.31;
    vec2 center = vec2(8.0, 4.0) * hash2(h += 0.01) - 3.0 + vec2(1.0, 3.0);
    vec2 size = vec2(1.2, 0.6) * hash2(h += 0.01) + 1.0;
    return hasPool(id) &&
           pos.x > center.x - size.x &&
           pos.x < center.x + size.x &&
           pos.y > center.y - size.y &&
           pos.y < center.y + size.y;
}
vec2 poolCenter(float id) {
    float h = id + 0.31;
    return vec2(8.0, 4.0) * hash2(h += 0.01) - 3.0 + vec2(1.0, 3.0);
}

bool hasTree(float id) {
    return hash1(id + 0.4) < chanceForTree;
}
bool isTree(vec2 pos, float id) {
    vec2 center = floor(vec2(8.0, 4.0) * hash2(id + 0.41) - 3.0 + vec2(1.0, 3.0));
    return hasTree(id) &&
           !isPool(pos, id) &&
           (abs(pos.x - center.x) + abs(pos.y - center.y) < 0.1);
}
bool nearTree(vec2 pos, float id) {
    vec2 center = floor(vec2(8.0, 4.0) * hash2(id + 0.41) - 3.0 + vec2(1.0, 3.0));
    return hasTree(id) && (max(abs(pos.x - center.x), abs(pos.y - center.y)) < 1.1);
}
vec2 treeCenter(float id) {
    return floor(vec2(8.0, 4.0) * hash2(id + 0.41) - 3.0 + vec2(1.0, 3.0));
}

bool hasVines(float id) {
    return hash1(id + 0.45) < 0.5;
}

vec2 roofCenter(float id) {
    float h = id + 0.2;
    float maxFloor = floor(1.0 + floorLimit * hash1(h));
    float highest = -1.0;
    vec2 center;
    for (float i = 0.0; i < 5.9; i += 1.0) {
        h = id + 0.2 + 0.005 * i;
        float top = max(floor((1.0 + maxFloor) * hash1(h + 0.001)), step(i, 1.5));
        if (top > highest + 0.1) {
            highest = top;
            center = vec2(8.0, 2.0) * hash2(h + 0.002) + vec2(-4.0, 1.0) + vec2(0.0, -1.0 * top);
        }
    }
    return center;
}
float houseFrame(vec2 pos, float id) {
    if (isPool(pos, id) || isTree(pos, id))
        return 0.0;
    float maxFloor = floor(1.0 + floorLimit * hash1(id + 0.2));
    float height = -1.0;
    for (float i = 0.0; i < 5.9; i += 1.0) {
        float h = id + 0.2 + 0.005 * i;
        float top = max(floor((1.0 + maxFloor) * hash1(h + 0.001)), step(i, 0.5));
        vec2 center = vec2(8.0, 2.0) * hash2(h + 0.002) + vec2(-4.0, 1.0) + vec2(0.0, -1.0 * top);
        vec2 size = vec2(1.0, 0.5) * (1.0 + 0.5 * (floorLimit - top)) * hash2(h + 0.003) + 1.0;
        if (pos.x > center.x - size.x &&
            pos.x < center.x + size.x &&
            pos.y > center.y - size.y &&
            pos.y < center.y + size.y) {

            height = max(height, top);
        }
    }

    if (hash1(id + 0.25) < chanceForPatio) {
        float h = id + 0.26;
        
        vec2 roof = roofCenter(id);
        vec2 patio = vec2(8.0, 2.0) * hash2(h + 0.002) + vec2(-4.0, 0.0);
        vec2 left = min(roof, patio);
        vec2 right = max(roof, patio);
        if (pos.x > left.x - 0.5 &&
            pos.x < right.x + 0.5 &&
            pos.y > left.y - 0.5 &&
            pos.y < right.y + 0.5) {

            height = max(height, 0.5);
        }
    }

    if (height > -0.5 && nearTree(pos, id))
        return 0.0;
    
    // Add a connecting deck
    if (hasPool(id) || hasTree(id)) {
        vec2 left = roofCenter(id);
        vec2 right = left;
        if (hasPool(id)) {
            vec2 center = poolCenter(id);
            left = min(left, center);
            right = max(right, center);
        }
        if (hasTree(id)) {
            vec2 center = treeCenter(id);
            left = min(left, center);
            right = max(right, center);
        }
        if (pos.x > left.x - 0.5 &&
            pos.x < right.x + 0.5 &&
            pos.y > left.y - 0.5 &&
            pos.y < right.y + 0.5) {

            height = max(height, 0.0);
        }
    }
    
    return height;
}


float windowCol(vec3 frame, float col, float bias, bool doubleWindows) {
    float h = 3.0 * hash1(frame.xy + 0.1)+  1.0 * hash1(frame.xy + col + 0.2) + 0.5 * hash1(frame.z + 0.1) + bias;
    
    if (h < 0.0 || (h < 0.5 && !doubleWindows))
        return 0.0;
    if (!doubleWindows)
        return 1.0;
    if (h > 1.0)
        return 2.0;
    return 3.0;
}

float writeWindow(vec3 frame, float pos, float width, float div, float bias, bool doubleWindows) {
    float col = floor(pos * div / width);
    if (pos - col * width / div < 1.0) {
        float left = windowCol(frame, col - 1.0, bias, doubleWindows);
        float right = windowCol(frame, col, bias, doubleWindows);
        if (abs(left) < 0.1 && abs(right) < 0.1)
            return 0.0;
        if (abs(left - 3.0) < 0.1 && abs(right - 3.0) < 0.1)
            return -5.0;
        return -3.0;
    }
    return windowCol(frame, col, bias, doubleWindows);
}

bool overlap(vec2 iDist, vec2 iPos, float iFloor, float iX, float iY, float iXY) {
    return (iX > iFloor - 0.1 && iPos.x < iDist.x) ||
           (iY > iFloor - 0.1 && iPos.y < iDist.y) ||
           (iXY > iFloor - 0.1 && iPos.x < iDist.x && iPos.y < iDist.y);
}

bool overlapCorner(vec2 iDist, vec2 iPos, float iFloor, float iX, float iY, float iXY) {
    return iPos.x < iDist.x && iPos.y < iDist.y &&
            (((iX > iFloor - 0.6 && iX < iFloor + 0.1) ||
              (iY > iFloor - 0.6 && iY < iFloor + 0.1)) ||
             ((iPos.x < 0.1 || iPos.y < 0.1) &&
              (iXY > iFloor - 0.6 && iXY < iFloor + 0.1)));
}

bool overlapPool(vec2 iDist, vec2 iPos, bool iX, bool iY, bool iXY) {
    return (!iX && iPos.x < iDist.x) ||
           (!iY && iPos.y < iDist.y) ||
           (!iXY && iPos.x < iDist.x && iPos.y < iDist.y);
}

vec3 groundCube(vec2 pos, float id) {
    float slope = 0.4 * hash1(id + 0.8) + 0.05;
    float size = floor(maxGroundCube * pow(hash1(vec3(pos, id)), 40.0) + 1.0);
    float height = 30.0 * fbm1(0.02 * pos + id) - slope * pos.y;
    float color = hash1(vec3(pos, id + 0.5));
    return vec3(size + 0.1, 4.0 * size + height, color);
}

vec4 run(vec2 fragCoord, float id) {
    float h = id + 0.1;

    float floorHeight = 1.0;
    float beamHeight = 3.0;
    float frameHeight = floor(range(16.0, 22.0));
    float windowHeight = floor(mix(0.65, 0.35, hash1(id + 0.9)) * frameHeight);

    if (fragCoord.x < 1.0) {
        if (fragCoord.y < heightLoc)
            return vec4(floorHeight, beamHeight, frameHeight, windowHeight);
    
        vec3 color, baseColor;
        writeHSV(frameLoc, range(0.0, 6.0), rangesq(0.0, 0.5), range(0.2, 1.0));
        writeHSV(wallLoc, range(0.0, 6.0), rangesq(0.0, 0.4), range(0.6, 1.0));
        writeHSV(windowFrameLoc, range(0.0, 6.0), rangesq(0.0, 0.1), range(0.0, 1.0));
        writeHSV(windowLoc, range(2.0, 4.0), range(0.0, 0.5), range(0.0, 0.3));
        
        baseColor = vec3(range(0.0, 6.0), 0.0, range(0.1, 0.5));
        writeOffsetHSV(roofLoc1, range(-0.5, 0.5), rangesq(0.0, 0.1), range(0.0, 0.1));
        writeOffsetHSV(roofLoc2, range(-0.5, 0.5), rangesq(0.0, 0.1), range(0.1, 0.2));

        baseColor = vec3(rangesq(5.8, 6.8), 0.0, 0.0);
        writeOffsetHSV(chimneyLoc1, range(-0.1, 0.1), range(0.6, 0.8), range(0.3, 0.5));
        writeOffsetHSV(chimneyLoc2, range(-0.1, 0.1), range(0.6, 0.8), range(0.5, 0.7));

        writeHSV(capLoc, range(0.0, 6.0), rangesq(0.0, 0.1), range(0.05, 0.2));

        baseColor = vec3(range(0.0, 6.0), 0.0, range(0.3, 0.5));
        writeOffsetHSV(foundationLoc1, range(-0.5, 0.5), range(0.0, 0.2), range(0.0, 0.1));
        writeOffsetHSV(foundationLoc2, range(-0.5, 0.5), range(0.0, 0.2), range(0.1, 0.2));

        baseColor = vec3(range(0.3, 0.6), range(0.4, 0.7), range(0.0, 0.1));
        writeOffsetHSV(deckLoc1, range(-0.2, 0.2), range(0.0, 0.3), range(0.0, 0.1));
        writeOffsetHSV(deckLoc2, range(-0.2, 0.2), range(0.0, 0.3), range(0.2, 0.4));

        baseColor = vec3(range(2.7, 3.9), 0.0, 0.0);
        writeOffsetHSV(tileLoc1, range(-0.3, 0.3), range(0.7, 1.0), range(0.6, 0.8));
        writeOffsetHSV(tileLoc2, range(-0.3, 0.3), range(0.7, 1.0), range(0.6, 0.8));
        writeOffsetHSV(waterLoc, 0.0, range(0.8, 1.0), range(0.3, 0.5));

        writeHSV(dirtLoc, 0.5, range(0.1, 0.9), range(0.0, 0.5));

        writeHSV(groundLoc1, range(0.0, 2.0), range(0.8, 1.0), range(0.4, 0.7));
        writeHSV(groundLoc2, range(1.5, 3.0), range(0.8, 1.0), range(0.2, 0.35));
    }

    bool doubleWindows = hash1(id) < chanceForDoubleWindow;
    float divX = 2.0 - floor(1.6 * hash1(h += 0.01));
    float divY = 2.0 + floor(3.0 * hash1(h += 0.01));
    
    float frameWidth = range(6.0 + 4.0 * divX, 10.0 + 5.0 * divX);
    float frameLength = range(8.0 + 4.0 * divY, 12.0 + 6.0 * divY);
    vec2 frameSize = vec2(frameWidth, frameLength);
    
    float windowBiasX = range(0.0, 2.0);
    float windowBiasY = range(0.0, 5.0);
    
    float xOverhang = frange(1.0, 4.0);
    vec2 roofOverhang = vec2(xOverhang + 0.5, frange(max(xOverhang, 2.0), 8.0) + 0.5);
    vec2 groundClearance = max(vec2(6.5), roofOverhang);

    vec2 pos = floor(fragCoord - 0.5 * iResolution.xy);
    vec2 framePos = floor(mod(pos + 0.1, frameSize));
    vec2 frame = floor((pos + 0.1) / frameSize);
    float hf = houseFrame(frame, id);

    vec2 neighborSide = step(0.5 * frameSize, framePos);
    vec2 neighbor = mix(frame - 1.0, frame + 1.0, neighborSide);
    vec2 neighborPos = mix(framePos, frameSize - framePos, neighborSide);
    float hfX = houseFrame(vec2(neighbor.x, frame.y), id);
    float hfY = houseFrame(vec2(frame.x, neighbor.y), id);
    float hfXY = houseFrame(neighbor, id);

    float house = 0.0;
    float floorBit = 1.0;
    float window = 0.0;
    float windowBitX = 0.25;
    float windowBitY = 16.0;
    for (float i = 0.0; i < 3.1; i += 1.0, floorBit *= 8.0, windowBitX *= 4.0, windowBitY *= 4.0) {
        if (hf > i - 0.1 || overlap(vec2(0.1), neighborPos, i, hfX, hfY, hfXY)) {
            if (framePos.x < 0.1 && framePos.y < 0.1) {
                house += floorBit; // Corner post
            } else if (framePos.x < 0.1 || framePos.y < 0.1) {
                house += 2.0 * floorBit; // Ceiling
            } else if (i < 0.5) {
                house += 2.0; // Deck
            } else {
                vec3 pos = vec3(frame, i);
                float windowX = writeWindow(pos, framePos.x, frameSize.x, divX, -windowBiasX, doubleWindows);
                float windowY = writeWindow(pos, framePos.y, frameSize.y, divY, -windowBiasY, doubleWindows);
                if (windowX < -0.1 || windowY < -0.1) {
                    house -= min(windowX, windowY) * floorBit; // Window frame
                } else {
                    house += 7.0 * floorBit; // Window
                    window += windowX * windowBitX;
                    window += windowY * windowBitY;
                }
            }
        } else if (hf > i - 0.6 || overlap(vec2(0.1), neighborPos, i - 0.5, hfX, hfY, hfXY)) {
            if (framePos.x < 0.1 && framePos.y < 0.1) {
                house += floorBit; // Corner post
            } else {
                house += 4.0 * floorBit; // Patio roof
            }
        } else if (i > 0.1) {
            if (overlap(roofOverhang - 1.0, neighborPos, i - 0.5, hfX, hfY, hfXY) &&
                !overlap(roofOverhang - 1.0, neighborPos, i + 0.5, hfX, hfY, hfXY) ||
                overlapCorner(roofOverhang - 1.0, neighborPos, i, hfX, hfY, hfXY)) {
                
                house += 4.0 * floorBit; // Roof
            } else if (overlap(roofOverhang, neighborPos, i - 0.5, hfX, hfY, hfXY) &&
                       !overlap(roofOverhang, neighborPos, i + 0.5, hfX, hfY, hfXY) ||
                       overlapCorner(roofOverhang, neighborPos, i, hfX, hfY, hfXY)) {
                house += 6.0 * floorBit; // Gutter
            }
        }
    }
    
    if (house > 0.1 && framePos.x < 0.1)
        house += 4.0; // Beam flag
    
    float groundHeight = -999.0;
    float groundColor;
    for (float x = -maxGroundCube; x < maxGroundCube + 0.5; x += 1.0) {
        for (float y = -maxGroundCube; y < maxGroundCube + 0.5; y += 1.0) {
            vec3 ground = groundCube(pos + vec2(x, y), id);
            if (max(abs(x), abs(y)) < ground.x && ground.y > groundHeight) {
                groundHeight = ground.y;
                groundColor = ground.z;
            }
        }
    }
    if (hf > -0.5
        || overlap(groundClearance, neighborPos, 0.5, hfX, hfY, hfXY)
        || overlap(vec2(0.1), neighborPos, 0.0, hfX, hfY, hfXY))
        groundHeight = min(groundHeight, -floorHeight - 0.5);
    
    // Cement foundation
    if (hasPool(id) && (hf > -0.5 || overlap(vec2(0.1), neighborPos, 0.0, hfX, hfY, hfXY))) {
        house = 4.0 * floor((house + 0.5) / 4.0); // house & 252
        groundHeight = -1.0;
        groundColor = foundationIndex;
        
        if (isTree(frame, id)) {
            vec2 middle = floor(0.5 * frameSize);
            float radius = floor(0.5 * min(frameSize.x, frameSize.y)) - 1.0;
            float dist = max(abs(framePos.x - middle.x), abs(framePos.y - middle.y));
            if (dist < radius - 2.9) {
                groundHeight = floor(frameHeight * range(0.5, 2.0));
                groundColor = rangesq(1.0, 0.0);
            } else if (dist < radius + 0.1) {
                groundHeight = -2.0;
                groundColor = dirtIndex;
            }
        } else if (isPool(frame, id)) {
            bool poolX = isPool(vec2(neighbor.x, frame.y), id);
            bool poolY = isPool(vec2(frame.x, neighbor.y), id);
            bool poolXY = isPool(neighbor, id);
            
            if (!overlapPool(vec2(5.5), neighborPos, poolX, poolY, poolXY)) {
                groundHeight = -2.0;
                groundColor = waterIndex;
            } else if (!overlapPool(vec2(4.5), neighborPos, poolX, poolY, poolXY)) {
                groundColor = tileIndex;
            }
        }
    } else if (hasPool(id) &&
               hasVines(id) &&
               overlap(vec2(1.1), neighborPos, 0.0, hfX, hfY, hfXY)) {
        float vine = -4.0 + 80.0 * log(hash1(pos + 0.1));
        if (vine > groundHeight + 0.1) {
            groundHeight = vine;
            groundColor = 0.5 + 0.5 * hash1(pos + 0.2);
        }
    } else if (isTree(frame, id)) {
        vec2 middle = floor(0.5 * frameSize);
        float radius = floor(0.5 * min(frameSize.x, frameSize.y)) - 1.0;
        float dist = max(abs(framePos.x - middle.x), abs(framePos.y - middle.y));
        if (dist < radius - 2.9) {
            house = 0.0;
            groundHeight = floor(frameHeight * range(0.5, 2.0));
            groundColor = rangesq(1.0, 0.0);
        } else if (dist < radius + 0.1) {
            house = 0.0;
        }
    }

    // Chimney
    if (hash1(id + 0.6) < chanceForChimney) {
        vec2 chimneyFrame = floor(roofCenter(id) + 0.5);
        float chimneyHeight = houseFrame(chimneyFrame, id);
        vec2 chimneyDir;
        vec2 chimneyOffset;
        vec2 chimneySize;

        float chimneyHash = hash1(id + 0.61);
        if (chimneyHash < 0.3) {
            chimneyDir = vec2(1.0, 0.0);
            chimneyOffset = vec2(0.0, 0.5);
        } else if (chimneyHash < 0.5) {
            chimneyDir = vec2(-1.0, 0.0);
            chimneyOffset = vec2(1.0, 0.5);
        } else if (chimneyHash < 0.8) {
            chimneyDir = vec2(0.0, 1.0);
            chimneyOffset = vec2(0.5, 0.0);
        } else {
            chimneyDir = vec2(0.0, -1.0);
            chimneyOffset = vec2(0.5, 1.0);
        }
    
        if (chimneyHash < 0.5) {
            chimneySize = vec2(3.0, 0.5 * frameSize.y - 1.5);
        } else {
            chimneySize = vec2(0.5 * frameSize.x - 1.5, 3.0);
        }

        for (float i = 0.0; i < 9.9; ++i) {
            float currHeight = houseFrame(chimneyFrame + chimneyDir * i, id);
            if (currHeight > chimneyHeight + 0.1) {
                chimneyHeight = currHeight;
            } else if (currHeight < chimneyHeight - 0.1 && chimneyHeight > 0.9) {
                vec2 chimneyPos = frameSize * (chimneyFrame + chimneyDir * i + chimneyOffset);
                vec2 d = abs(pos - chimneyPos) - chimneySize;
                if (max(d.x, d.y) < -0.9) {
                    groundHeight = frameHeight * chimneyHeight + 4.0;
                    groundColor = capIndex;
                } else if (max(d.x, d.y) < 0.1) {
                    groundHeight = frameHeight * chimneyHeight + 3.0;
                    groundColor = chimneyIndex;
                } else if (max(d.x, d.y) < 1.1 && abs(groundColor - tileIndex) > 0.1 && abs(groundColor - waterIndex) > 0.1) {
                    groundHeight = -1.0;
                    groundColor = foundationIndex;
                    window = 0.0;
                }
                break;
            }
        }
    }

    return vec4(house, window, groundHeight, groundColor);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec4 frame = texture(iChannel0, vec2(0.5) / iResolution.xy);
    bool resize = abs(frame.x - iResolution.x) + abs(frame.y - iResolution.y) > 0.5;
    
#if SCENE_TIME == 0 || defined SCREENSHOT
    float id = iTime;
    bool restart = iMouse.z > 0.5 && texture(iChannel0, vec2(1.5, 0.5) / iResolution.xy).z < 0.5;
#else
    float id = floor(iTime / float(SCENE_TIME));
    bool restart = abs(id - frame.w) > 0.01;
#endif

    frame.xy = iResolution.xy;
    frame.z += 1.0;;
    fragColor = texture(iChannel0, fragCoord.xy / iResolution.xy);
    if (resize || restart) {
        fragColor = run(fragCoord, id + 3.0);
        frame.z = 1.0;
        frame.w = id;
    }

    if (fragCoord.x < 1.0 && fragCoord.y < 1.0)
        fragColor = frame;
    else if (fragCoord.x < 2.0 && fragCoord.y < 1.0)
        fragColor = iMouse;
}
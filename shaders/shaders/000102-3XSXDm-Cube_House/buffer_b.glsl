// Buffer B (buffer) — Cube House by mhnewman
// https://www.shadertoy.com/view/3XSXDm

const float sphericalAberration = 0.0;

#ifdef SCREENSHOT
const float vignetting = 0.0;
const int maxIter = 3000;
const int shadowIter = 200;
#else
const float vignetting = 0.5;
const int maxIter = 1000;
const int shadowIter = 100;
#endif

vec4 height;

float getFloor(float house, float houseFloor) {
    return floor(mod((house + 0.1) / exp2(3.0 * houseFloor), 8.0)); // (house >> (3 * houseFloor)) & 7
}

void setGlobals() {
    height = texture(iChannel0, (vec2(1.0, heightLoc) - 0.5) / iResolution.xy);
}

float readWindow(float hint, float houseFloor, vec3 norm, float floorPos) {
    float window = floor(mod((hint + 0.1) / exp2(6.0 * norm.x + 2.0 * houseFloor - 2.0), 4.0)); // (int(hint) >> (6 * int(norm.x) + 2 * houseFloor - 2)) & 3
    float material = -1.0; // Wall
    if (window > 0.1 && (window < 2.1 || floorPos < height.w - 0.1))
        material = 1.0; // Window
    if (window > 1.1 && floorPos > height.w - 0.5 && floorPos < height.w + 0.5)
        material = 0.0; // Frame
    return material;
}

// Set Camera will position and aim the camera.
//   eye := The location of the camera.
//   center := The location at which the camera is looking.
//   focalDist := Center of focus
//   blurAmount := Amount of depth of field
//   Return value := Camera focal length.
float setCamera(out vec3 eye, out vec3 center, out float focalDist, out float blurAmount) {
    float dist = 800.0;
    focalDist = 750.0;
    blurAmount = 0.01;
    
    vec2 m = vec2(0.08, 0.8);

#if LIVE_ITER > 0
#if SCENE_TIME == 0
    m.x += -0.13 * sin(0.06 * iTime);
#else
    float t = fract(iTime / float(SCENE_TIME));
    m.x += 0.02 - 0.04 * t;
#endif
#endif

    m *= 6.283185 * vec2(1.0, 0.25);    
    center = vec3(0.0, 20.0, 0.0);
    eye = center + vec3(dist * sin(m.x) * sin(m.y), dist * cos(m.x) * sin(m.y), dist * cos(m.y));

#ifdef SCREENSHOT
    return 7.0;
#else
    return 10.0;
#endif 
}

// Voxel Hit returns true if the voxel at pos should be filled.
bool voxelHit(vec3 pos, float time) {
    vec3 fpos = floor(pos);
    vec4 buf = texture(iChannel0, (fpos.xy + floor(0.5 * iResolution.xy) + 0.5) / iResolution.xy);

    if (fpos.z < buf.z + 0.1)
        return true;

    float house = buf.x;
    float beam = floor(mod((house + 0.1) / 4.0, 2.0)); // (house >> 2) & 1
    house -= 4.0 * beam; // house & 4091
    float houseFloor = max(floor((fpos.z + 0.1) / height.z) + 1.0, 0.0);
    house = getFloor(house, houseFloor);
    
    float floorPos = height.z * houseFloor - fpos.z;
    
    return (mod(house + 0.1, 2.0) > 0.1) || // (house & 1) > 0
           ((house > 0.1) && (floorPos < height.x + float(beam) * height.y + 0.1));
}

// Voxel Reflect returns true if the voxel at pos should reflect rays.
bool voxelReflect(vec3 pos, vec3 norm, float time) {
    vec3 fpos = floor(pos);
    vec4 buf = texture(iChannel0, (fpos.xy + floor(0.5 * iResolution.xy) + 0.5) / iResolution.xy);

    if (fpos.z < buf.z + 0.1)
        if (abs(buf.w - waterIndex) < 0.1)
            // Water
            return hash1(vec4(pos, time)) < 0.5;
        else
            // Ground
            return false;

    float houseFloor = max(floor((fpos.z + 0.1) / height.z) + 1.0, 0.0);
    float house = getFloor(buf.x, houseFloor);
    if (house < 6.1)
        return false;

    float floorPos = height.z * houseFloor - fpos.z;
    if (floorPos < height.x + 0.1 || readWindow(buf.y, houseFloor, norm, floorPos) < 0.5)
        return false;

    // Window
    return hash1(vec4(pos, time)) < 0.3;
}

// Voxel Color returns the color at pos with normal vector norm.
vec3 voxelColor(vec3 pos, vec3 norm, float time) {
    vec3 fpos = floor(pos);
    vec4 buf = texture(iChannel0, (fpos.xy + floor(0.5 * iResolution.xy) + 0.5) / iResolution.xy);

    vec3 frameColor = readHSV(frameLoc);
    vec3 wallColor = readHSV(wallLoc);
    vec3 windowFrameColor = readHSV(frameLoc); //readHSV(windowFrameLoc);
    vec3 windowColor = readHSV(windowLoc);
    vec3 capColor = readHSV(capLoc);
    vec3 dirtColor = readHSV(dirtLoc);
    vec3 waterColor = readHSV(waterLoc);

    vec3 groundColor = mix(readHSV(groundLoc1), readHSV(groundLoc2), buf.w);

    float colorMix = hash1(fpos);
    vec3 roofColor = mix(readHSV(roofLoc1), readHSV(roofLoc2), colorMix);
    vec3 tileColor = mix(readHSV(tileLoc1), readHSV(tileLoc2), colorMix);
    
    vec3 brick = floor((fpos + vec3(vec2(floor(1.0 * fpos.z + 2.0 * hash1(fpos.z))), 0.0)) / vec3(4.0, 4.0, 1.0));
    vec3 chimneyColor = mix(readHSV(chimneyLoc1), readHSV(chimneyLoc2), hash1(brick));

    vec2 plank = floor((fpos.xy + vec2(floor(2.0 * fpos.y + 4.0 * hash1(fpos.y)), 0.0)) / vec2(8.0, 1.0));
    vec3 deckColor = mix(readHSV(deckLoc1), readHSV(deckLoc2), hash1(plank));
    
    vec3 slab = floor((fpos + vec3(vec2(floor(2.0 * fpos.z + 4.0 * hash1(fpos.z))), 0.0)) / vec3(8.0, 8.0, 1.0));
    vec3 foundationColor = mix(readHSV(foundationLoc1), readHSV(foundationLoc2), hash1(slab));

    float houseFloor = max(floor((fpos.z + 0.1) / height.z) + 1.0, 0.0);
    float floorPos = height.z * houseFloor - fpos.z;
    
    float beam = floor(mod((buf.x + 0.1) / 4.0, 2.0)); // (house >> 2) & 1
    float house = buf.x - 4.0 * beam; // house & 4091
    float above = getFloor(house, houseFloor + 1.0);
    house = getFloor(house, houseFloor);

    vec3 houseColor = frameColor;
    if (floorPos < height.x + 0.1 && mod(above + 0.1, 2.0) < 0.5 && abs(above - 2.0) > 0.1) {
        houseColor = mix(deckColor,
                         mix(roofColor, frameColor, step(abs(house - 6.0), 0.1)),
                         step(0.1, houseFloor));
    }

    if (house > 6.9 && floorPos > height.x + 0.1) {
        float window = readWindow(buf.y, houseFloor, norm, floorPos);
        houseColor = mix(windowColor,
                         mix(windowFrameColor, wallColor, step(window, -0.5)),
                         step(window, 0.5));
    }

    if (abs(house - 3.0) < 0.1 && floorPos > height.x + 0.1)
        houseColor = windowFrameColor;

    if (abs(house - 5.0) < 0.1 && floorPos > height.x + 0.1) {
        houseColor = mix(wallColor, windowFrameColor, step(floorPos, height.w + 0.5));
    }
    
    groundColor = mix(groundColor, foundationColor, step(abs(buf.w - foundationIndex), 0.1));
    groundColor = mix(groundColor, chimneyColor, step(abs(buf.w - chimneyIndex), 0.1));
    groundColor = mix(groundColor, capColor, step(abs(buf.w - capIndex), 0.1));
    groundColor = mix(groundColor, tileColor, step(abs(buf.w - tileIndex), 0.1));
    groundColor = mix(groundColor, waterColor, step(abs(buf.w - waterIndex), 0.1));
    groundColor = mix(groundColor, dirtColor, step(abs(buf.w - dirtIndex), 0.1));
    
    return hsv2rgb(mix(houseColor, groundColor, step(fpos.z, buf.z + 0.1)));
}

vec3 backgroundColor(vec3 ray) {
    float noise = 0.5 + 0.5 * noise1(50.0 * ray.xy/(ray.z + 0.1));
    vec3 groundColor = mix(readHSV(groundLoc1), readHSV(groundLoc2), noise);
    vec3 skyColor = mix(vec3(3.6, 1.0, 0.8), vec3(3.6, 0.5, 1.0), noise);
    return 0.5 * hsv2rgb(mix(skyColor, groundColor, step(ray.z, 0.0)));
}

float castRay(vec3 eye, vec3 ray, bool canReflect, float time, int iter, out vec3 pos, out vec3 norm) {
    vec3 vox = floor(eye);
    vec3 ri = 1.0 / ray;
    vec3 rs = sign(ray);
    vec3 ris = ri * rs;
    vec3 dis = (vox - eye + 0.5 + rs * 0.5) * ri;
    
    vec3 dim = vec3(0.0);
    for (int i = 0; i < iter; ++i) {
        if (voxelHit(vox, time)) {
            float dist = dot(dis - ris, dim);
            pos = eye + dist * ray;
            norm = -dim * rs;
            
            if (canReflect && voxelReflect(pos - 0.01 * norm, norm, time)) {
                ray = reflect(ray, norm);
                eye = pos + ray * 0.001;
                
                vox = floor(eye);
                ri = 1.0 / ray;
                rs = sign(ray);
                ris = ri * rs;
                dis = (vox - eye + 0.5 + rs * 0.5) * ri;
                
                continue;
            }
            return 1.0;
        }
    
        dim = step(dis, dis.yzx);
		dim *= (1.0 - dim.zxy);
        
        dis += dim * ris;
        vox += dim * rs;
    }

    norm = ray;
	return 0.0;
}

vec3 pass(vec2 coord, float time) {
    vec3 eye, center;
    float focalDist, blurAmount;
    float zoom = setCamera(eye, center, focalDist, blurAmount);
    
    vec3 forward = normalize(center - eye);
    vec3 right = normalize(cross(forward, vec3(0.0, 0.0, 1.0)));
    vec3 up = cross(right, forward);

    // Anti aliasing
    vec2 hash = hash2(vec3(time, coord));
    vec2 xy = (2.0 * (coord + hash - 0.5) - iResolution.xy) / iResolution.y;
    
    // Spherical aberration
    xy /= cos(sphericalAberration * (1.0 + 0.3 * hash1(vec3(time, coord))) * length(xy));
    
    vec3 ray = normalize(xy.x * right + xy.y * up + zoom * forward);
    
    // Depth of field    
    hash = hash2(vec3(time + 0.1, coord));
    float a = sqrt(hash.x);
    float b = a * cos(6.283185 * hash.y);
    float c = a * sin(6.283185 * hash.y);

    vec3 target = eye + ray * focalDist / dot(ray, forward);
    eye += focalDist * blurAmount * (b * right + c * up);
    ray = normalize(target - eye);
    
    // Fast forward heuristic
    float distToRoof = (eye.z - maxHeight) / -ray.z;
    float distToGround = (eye.z - 15.0) / -ray.z;
#ifdef SCREENSHOT
    eye += ray * min(focalDist, max(distToRoof, focalDist - 400.0));
#else
    eye += ray * min(max(distToGround, focalDist - 250.0), max(distToRoof, focalDist - 150.0));
#endif

    // Cast Ray
    vec3 pos;
    vec3 norm;
    float hit = castRay(eye, ray, true, time, maxIter, pos, norm);

    vec3 color = voxelColor(pos - 0.01 * norm, norm, time);
    
    
    pos += 0.001 * norm;
#if REFLECT_SUN_ITER > 0
    // Small angle approximation
    const float sunThreshold = sqrt(1.0 - sunSize * sunSize);
    const float sunScale = 2.0 / (sunSize * sunSize);

    vec3 shade = vec3(0.0);
    for (int i = 0; i < REFLECT_SUN_ITER; ++i) {
        vec3 z = norm;
        vec3 x = normalize(cross(z, vec3(-0.36, -0.48, 0.8)));
        vec3 y = normalize(cross(z, x));

        hash = hash2(vec3(time + 0.2, coord));
        a = sqrt(hash.x);
        b = a * cos(6.283185 * hash.y);
        c = a * sin(6.283185 * hash.y);
        a = sqrt(1.0 - hash.x);
        vec3 shadeDir = b * x + c * y + a * z;
        vec3 shadeRay;
        float ambient = 1.0 - castRay(pos, shadeDir, true, time, shadowIter, z, shadeRay);
        ambient *= step(0.0, shadeRay.z);
        
        shade += ambient * ambientColor;
        
        shade += step(sunThreshold, dot(shadeRay, sunDir)) * sunColor * sunScale;
    }
    color *= shade / float(REFLECT_SUN_ITER);
#else
    // Ambient occlusion
    vec3 z = norm;
    vec3 x = normalize(cross(z, vec3(-0.36, -0.48, 0.8)));
    vec3 y = normalize(cross(z, x));

    hash = hash2(vec3(time + 0.2, coord));
    a = sqrt(hash.x);
    b = a * cos(6.283185 * hash.y);
    c = a * sin(6.283185 * hash.y);
    a = sqrt(1.0 - hash.x);
    vec3 shadeDir = b * x + c * y + a * z;
    vec3 shadeRay;
    float ambient = 1.0 - castRay(pos, shadeDir, true, time, shadowIter, z, shadeRay);
    ambient *= step(0.0, shadeRay.z);
    
    // Sun
    z = sunDir;
    x = normalize(cross(z, vec3(0.0, 1.0, 0.0)));
    y = normalize(cross(z, x));
    
    hash = hash2(vec3(time + 0.3, coord));
    a = sqrt(hash.x);
    b = a * cos(6.283185 * hash.y);
    c = a * sin(6.283185 * hash.y);

    z += sunSize * (b * x + c * y);
    float sun = 1.0 - castRay(pos, normalize(z), false, time, shadowIter, shadeRay, shadeRay);

    color *= ambient * ambientColor + sun * sunColor;
#endif
    
    return mix(backgroundColor(norm), color, hit);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec4 frame = texture(iChannel0, vec2(0.5) / iResolution.xy);

    setGlobals();
    
    // Render pass
	vec3 color = pass(fragCoord, iTime);
#if LIVE_ITER > 0
    for (int i = 1; i < LIVE_ITER; ++i)
        color += pass(fragCoord, iTime + float(i));
    color /= float(LIVE_ITER);
#endif
    
    vec2 uv = 2.0 * fragCoord / iResolution.xy - 1.0;
    color *= vignetting * pow((1.0 - uv.x * uv.x) * (1.0 - uv.y * uv.y), 0.2) + 1.0 - vignetting;
    
#if LIVE_ITER == 0
    // Accumulate color
    vec3 oldColor = texture(iChannel1, fragCoord.xy / iResolution.xy).rgb;
    fragColor = vec4(mix(oldColor, color, 1.0 / frame.z), 1.0);
#else
    fragColor = vec4(color, 1.0);
#endif
}

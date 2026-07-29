// Buffer B (buffer) — Cube Falls by mhnewman
// https://www.shadertoy.com/view/dtSGWd

// Monte carlo ambient occlusion, depth of field, spherical aberration,
// and anti aliasing using accumulation buffer.
//
// Based on www.shadertoy.com/view/llccD2 Monte Carlo Accumulation.
// Create your scene by filling in setCamera(), voxelHit(), and voxelColor().

const float sphericalAberration = 0.1;
const float vignetting = 0.5;
const vec3 backgroundColor = vec3(0.0);
const int hitIter = 400;
const int shadeIter = 100;

// Set Camera will position and aim the camera.
//   eye := The location of the camera.
//   center := The location at which the camera is looking.
//   focalDist := Center of focus
//   blurAmount := Amount of depth of field
//   Return value := Camera focal length.
float setCamera(out vec3 eye, out vec3 center, out float focalDist, out float blurAmount) {
    float dist = 160.0;
    focalDist = 150.0;
    blurAmount = 0.03;    
    
    vec2 m = vec2(0.4, 0.55);
#if LIVE_ITER > 0
#if SCENE_TIME == 0
    m.x += 0.01 * iTime;
#else
    float t = fract(iTime / float(SCENE_TIME));
    m.x += 0.02 * t - 0.01;
    dist -= 20.0 * t;
    focalDist -= 20.0 * t;
#endif
#endif
    m *= 6.283185 * vec2(1.0, 0.25);    
    center = vec3(0.0, 0.0, 0.0);
    eye = center + vec3(dist * sin(m.x) * sin(m.y), dist * cos(m.x) * sin(m.y), dist * cos(m.y));
    return 6.0;
}


// Voxel Hit returns true if the voxel at pos should be filled.
bool voxelHit(vec3 pos) {
    vec4 buf = texture(iChannel0, (floor(pos.xy + 0.5 * iResolution.xy) + 0.5) / iResolution.xy);
    bool ground = pos.z < floor(max(buf.x, -buf.x)) + 0.5;
    float treeTop = floor(buf.y);
    bool tree = pos.z > treeTop - floor((buf.y - treeTop) * 16.0) - 0.5 && pos.z < treeTop + 0.5 && hash1(pos + 0.1) < 0.5;
    //bool tree = pos.z > treeTop - floor((buf.y - treeTop) * 16.0) - 0.5 && pos.z < treeTop + 0.5;
    float trunkTop = floor(buf.z);
    bool trunk = pos.z > trunkTop - floor((buf.z - trunkTop) * 16.0) - 0.5 && pos.z < trunkTop + 0.5;
    return ground || tree || trunk;
}

vec3 leafColor(float id, vec2 hash) {
    float x = id + 0.2 * hash.y - 0.1;
    float x2 = x * x;
    float red = 2.0 * x - x2 - 0.2;
    float green = 0.3 + 0.5 * x - 0.8 * x2;
    float blue = 0.0;
    return clamp(vec3(red, green, blue), 0.0, 1.0) * (0.5 + 0.5 * hash.x);
}

// Voxel Color returns the color at pos with normal vector norm.
vec3 voxelColor(vec3 pos, vec3 norm) {
    vec3 p = floor(pos);
    vec4 buf = texture(iChannel0, (floor(p.xy + 0.5 * iResolution.xy) + 0.5) / iResolution.xy);
    vec2 h = hash2(p);
    
    vec3 water = mix(vec3(0.1, 0.4, 1.0), vec3(0.0, 0.2, 1.0), h.x);
    vec3 foam = mix(vec3(1.0, 1.0, 1.0), vec3(0.5, 0.7, 1.0), h.x);
    float depth = 2.0 * fract(buf.x);
    depth = max(0.0, depth + (0.1 + 0.3 * hash1(p.xy)) * (p.z - floor(buf.x)));
    water = mix(foam, water, depth);
    
    vec3 ground = mix(vec3(0.5, 0.3, 0.2), vec3(0.4, 0.2, 0.1), h.x);
    vec3 rocks = mix(vec3(0.6), vec3(0.4), h.x);
    ground = mix(ground, rocks, floor(2.0 * fract(-buf.x)));
    
    vec3 grass = mix(vec3(0.5, 0.9, 0.0), vec3(0.0, 0.5, 0.2), h.x);
    ground = mix(ground, grass, floor(2.0 * fract(-2.0 * buf.x)) * step(floor(-buf.x) - 0.5, p.z));
    vec3 color = mix(water, ground, step(buf.x, -0.5));
    
    vec3 tree = leafColor(fract(buf.w), h);
    vec3 tree2 = leafColor((floor(buf.w - 1.0) + 0.5) / 16.0, h);
    vec3 trunk = mix(vec3(0.2, 0.15, 0.1), vec3(0.1, 0.05, 0.0), h.x);
    trunk = mix(trunk, tree2, step(1.0, buf.w));

    float treeTop = floor(buf.y);
    if (p.z < treeTop - floor((buf.y - treeTop) * 16.0) - 0.5 || p.z > treeTop + 0.5)
        tree = trunk;
    
    color = mix(color, tree, step(floor(abs(buf.x)) + 0.5, p.z));
    
#ifdef REDUCED_COLOR_PALETTE
    color = floor(4.0 * color + 0.5) / 4.0;
#endif

    return color;
}

////////////////////////////////////////////////////////////////////////////////
// Fill in the functions above.
// The engine below does not need to be modified.
////////////////////////////////////////////////////////////////////////////////

float castRay(vec3 eye, vec3 ray, int maxIter, out float dist, out vec3 norm) {
    vec3 pos = floor(eye);
    vec3 ri = 1.0 / ray;
    vec3 rs = sign(ray);
    vec3 ris = ri * rs;
    vec3 dis = (pos - eye + 0.5 + rs * 0.5) * ri;
    
    vec3 dim = vec3(0.0);
    for (int i = 0; i < maxIter; ++i) {
        if (pos.z < 0.0 || voxelHit(pos)) {
            dist = dot(dis - ris, dim);
            norm = -dim * rs;
            return 1.0;
        }
    
        dim = step(dis, dis.yzx);
		dim *= (1.0 - dim.zxy);
        
        dis += dim * ris;
        pos += dim * rs;
    }

    if (ray.z < 0.0) {
        dist = -eye.z / ray.z;
        norm = vec3(0.0, 0.0, 1.0);
        return 1.0;
    }
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
    
    // Cast Ray
    float dist;
    vec3 norm;
    float hit = castRay(eye, ray, hitIter, dist, norm);
    vec3 pos = eye + dist * ray;

    vec3 color = voxelColor(pos - 0.001 * norm, norm);
    
    // Ambient occlusion
    pos += 0.001 * norm;

    vec3 z = norm;
    vec3 x = normalize(cross(z, vec3(-0.36, -0.48, 0.8)));
    vec3 y = normalize(cross(z, x));

    hash = hash2(vec3(time + 0.2, coord));
    a = sqrt(hash.x);
    b = a * cos(6.283185 * hash.y);
    c = a * sin(6.283185 * hash.y);
    a = sqrt(1.0 - hash.x);
    vec3 shadeDir = b * x + c * y + a * z;
    float ambient = 1.0 - castRay(pos, shadeDir, shadeIter, dist, norm);
    
    // Sun
    z = vec3(0.48, 0.36, 0.8);
    x = normalize(cross(z, vec3(0.0, 1.0, 0.0)));
    y = normalize(cross(z, x));
    
    hash = hash2(vec3(time + 0.3, coord));
    a = sqrt(hash.x);
    b = a * cos(6.283185 * hash.y);
    c = a * sin(6.283185 * hash.y);

    z += 0.04 * (b * x + c * y);
    float sun = 1.0 - castRay(pos, normalize(z), shadeIter, dist, norm);
    
    color *= 0.6 * ambient + 0.4 * sun;
    return mix(backgroundColor, color, hit);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec4 frame = texture(iChannel0, vec2(0.5) / iResolution.xy);
    
    // Render pass
	vec3 color = pass(fragCoord, iTime);
#if LIVE_ITER > 0
    for (int i = 1; i < LIVE_ITER; ++i)
        color += pass(fragCoord, iTime + float(i));
    color /= float(LIVE_ITER);
#endif
    
    // Vignetting
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

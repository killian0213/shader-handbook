// Buffer C (buffer) — Cube Castle by mhnewman
// https://www.shadertoy.com/view/DtBGzt

// Monte carlo ambient occlusion, depth of field, spherical aberration,
// and anti aliasing using accumulation buffer.
//
// Based on www.shadertoy.com/view/llccD2 Monte Carlo Accumulation.
// Create your scene by filling in setCamera(), voxelHit(), and voxelColor().

const float sphericalAberration = 0.1;
const float vignetting = 0.5;
const vec3 backgroundColor = vec3(0.0);
const int maxIter = 600;
const int shadowIter = 100;
bool snow = false;

// Set Camera will position and aim the camera.
//   eye := The location of the camera.
//   center := The location at which the camera is looking.
//   focalDist := Center of focus
//   blurAmount := Amount of depth of field
//   Return value := Camera focal length.
float setCamera(out vec3 eye, out vec3 center, out float focalDist, out float blurAmount) {
    focalDist = 200.0;
    blurAmount = 0.02;    
    
    vec2 m = vec2(0.2, 0.6);
    m *= 6.283185 * vec2(1.0, 0.25);    
    float dist = 220.0;
    center = vec3(0.0, 0.0, 2.0 * blockSize);
    eye = center + vec3(dist * sin(m.x) * sin(m.y), dist * cos(m.x) * sin(m.y), dist * cos(m.y));
    return 6.0;
}

bool scene(vec3 pos) {
    vec4 buf = texture(iChannel1, (floor(pos.xy + 0.5 * iResolution.xy) + 0.5) / iResolution.xy);
    bool castle = pos.z < buf.x;

    float windowBlock = floor(pos.z / blockHeight);
    float windowPos = pos.z - blockHeight * windowBlock;
    float windowSize = mod(buf.y, 4.0);
    float windowStart = mod(floor(buf.y / 4.0), 4.0);
    float windowSkip = 1.0 + floor(buf.y / 16.0);
    bool window = (windowPos > blockHeight - windowSize - 0.5) &&
                  (windowBlock > windowStart - 0.5) &&
                  (mod(windowBlock - windowStart, windowSkip) < 0.5);
                  
    bool roof = pos.z < buf.z;
    bool tree = (pos.z < -buf.z && hash1(pos + 0.1) < 0.7);
    bool flag = pos.z > floor(buf.w) - 0.5 && pos.z < buf.w + 4.0 * fract(buf.w) - 1.0;
    return (castle && !window) || roof || tree || flag;
}

// Voxel Hit returns true if the voxel at pos should be filled.
bool voxelHit(vec3 pos, float time) {
    return scene(pos) || (snow && scene(pos - vec3(0.0, 0.0, 1.0)));
}

// Voxel Color returns the color at pos with normal vector norm.
vec3 voxelColor(vec3 pos, vec3 norm) {
    if (snow && !scene(floor(pos)))
        return vec3(1.0);
    vec3 p = floor(pos);
    float h = hash1(p);
    vec3 ground = mix(vec3(0.5, 0.3, 0.1), vec3(0.3, 0.2, 0.1), h);
    vec3 castle = mix(vec3(0.9, 0.9, 0.85), vec3(0.7), h);
    vec3 roof = mix(vec3(0.3, 0.4, 0.7), vec3(0.2, 0.3, 0.6), h);
    vec3 tree = mix(vec3(0.0, 1.0, 0.0), vec3(0.0, 0.5, 0.2), h);
    vec3 flag = mix(vec3(1.0, 0.0, 0.0), vec3(0.7, 0.0, 0.0), h);
    
    vec4 buf = texture(iChannel1, (floor(pos.xy) + floor(0.5 * iResolution.xy) + 0.5) / iResolution.xy);
    vec3 color = mix(roof, tree, step(buf.z, 0.0));
    color = mix(color, flag, step(max(buf.z, -buf.z), p.z - 0.5));
    color = mix(color, castle, step(pos.z, buf.x));
    return mix(color, ground, step(pos.z, 0.01));
}

////////////////////////////////////////////////////////////////////////////////
// Fill in the functions above.
// The engine below does not need to be modified.
////////////////////////////////////////////////////////////////////////////////

float castRay(vec3 eye, vec3 ray, float time, int iter, out float dist, out vec3 norm) {
    vec3 pos = floor(eye);
    vec3 ri = 1.0 / ray;
    vec3 rs = sign(ray);
    vec3 ris = ri * rs;
    vec3 dis = (pos - eye + 0.5 + rs * 0.5) * ri;
    
    vec3 dim = vec3(0.0);
    for (int i = 0; i < iter; ++i) {
        if (pos.z < 0.0 || voxelHit(pos, time)) {
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
    float hit = castRay(eye, ray, time, maxIter, dist, norm);
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
    color *= 1.0 - castRay(pos, shadeDir, time, shadowIter, dist, norm);
    
    return mix(backgroundColor, color, hit);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec4 frame = texture(iChannel0, vec2(0.5) / iResolution.xy);
    snow = frame.x > 0.5;
    
    // Render pass
	vec3 color = pass(fragCoord, iTime);
    
    // Vignetting
    vec2 uv = 2.0 * fragCoord / iResolution.xy - 1.0;
    color *= vignetting * pow((1.0 - uv.x * uv.x) * (1.0 - uv.y * uv.y), 0.2) + 1.0 - vignetting;
    
    // Accumulate color
    vec3 oldColor = texture(iChannel2, fragCoord.xy / iResolution.xy).rgb;
    fragColor = vec4(mix(oldColor, color, 1.0 / frame.z), 1.0);
}

// Buffer A (buffer) — Monte Carlo Accumulation by mhnewman
// https://www.shadertoy.com/view/llccD2

// Monte carlo ambient occlusion, depth of field, spherical aberration,
// and anti aliasing using accumulation buffer.
//
// Based on www.shadertoy.com/view/4tlfDn Reusable Voxel Engine.
// Create your scene by filling in setCamera(), voxelHit(), and voxelColor().

const float sphericalAberration = 0.1;
const float vignetting = 0.3;
const vec3 backgroundColor = vec3(0.2, 0.1, 0.2);
const int hitIter = 300;
const int shadeIter = 100;

// Set Camera will position and aim the camera.
//   eye := The location of the camera.
//   center := The location at which the camera is looking.
//   focalDist := Center of focus
//   blurAmount := Amount of depth of field
//   Return value := Camera focal length.
float setCamera(out vec3 eye, out vec3 center, out float focalDist, out float blurAmount) {
    focalDist = 85.0;
    blurAmount = 0.01;    
    
    vec2 m = vec2(0.3, 0.83);
    m *= 6.283185 * vec2(1.0, 0.25);    
    float dist = 130.0;
    center = vec3(0.0, 0.0, 0.0);
    eye = center + vec3(dist * sin(m.x) * sin(m.y), dist * cos(m.x) * sin(m.y), dist * cos(m.y));
    return 8.0;
}

// Voxel Hit returns true if the voxel at pos should be filled.
bool voxelHit(vec3 pos) {
    float height = 20.0 * pow(hash1(floor(pos.xy / 3.0)), 3.0) * pow(hash1(pos.xy), 0.3);
    return pos.z < height * step(0.5, mod(pos.x, 3.0)) * step(0.5, mod(pos.y, 3.0));
}

// Voxel Color returns the color at pos with normal vector norm.
vec3 voxelColor(vec3 pos, vec3 norm) {
    vec3 low = vec3(1.0, 0.0, 0.5);
    vec3 mid = vec3(0.8, 0.5, 1.0);
    vec3 hi = vec3(0.0, 0.7, 1.0);
    
    float c = hash1(floor(pos.xy / 3.0) + vec2(0.1));
    c = 0.7 * c + 0.3 * hash1(floor(8.0 * pos.z) + c);
    float a = 0.5 + 0.5 * hash1(floor(8.0 * pos.z) + c);
    c = clamp(2.0 * c, 0.0, 2.0);  
    return a * mix(mix(low, mid, c), mix(mid, hi, c - 1.0), step(1.0, c));
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
        if (voxelHit(pos)) {
            dist = dot(dis - ris, dim);
            norm = -dim * rs;
            return 1.0;
        }
    
        dim = step(dis, dis.yzx);
		dim *= (1.0 - dim.zxy);
        
        dis += dim * ris;
        pos += dim * rs;
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
    color = mix(color, vec3(0.0, 0.0, 0.0), castRay(pos, shadeDir, shadeIter, dist, norm));
    
    return mix(backgroundColor, color, hit);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {    
    // Restart accumulation on window resize
    vec3 frame = texture(iChannel0, vec2(0.5) / iResolution.xy).xyz;
    float resize = step(abs(frame.x - iResolution.x) + abs(frame.y - iResolution.y), 0.5);
    frame.xy = iResolution.xy;
    frame.z = mix(1.0, frame.z + 1.0, resize);
    
    // Render pass
	vec3 color = pass(fragCoord, iTime);
    
    // 10 passes on the first frame to render the preview.
    if (resize < 0.5) {
        for (int i = 1; i < 10; ++i)
	        color += pass(fragCoord, iTime + 0.01 * float(i));
        color *= 0.1;
    }

    // Vignetting
    vec2 uv = 2.0 * fragCoord / iResolution.xy - 1.0;
    color *= vignetting * pow((1.0 - uv.x * uv.x) * (1.0 - uv.y * uv.y), 0.2) + 1.0 - vignetting;
    
    // Accumulate color
    vec3 oldColor = texture(iChannel0, fragCoord.xy / iResolution.xy).rgb;
    vec3 accum = mix(oldColor, color, 1.0 / frame.z);
    fragColor = vec4(mix(accum, frame, step(fragCoord.x + fragCoord.y, 1.5)), 1.0);
}

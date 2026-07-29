// Common (common) — Bloom [skull] by tdhooper
// https://www.shadertoy.com/view/WdScDG

#define DISABLE_DOF
#define DISABLE_SHADOWS

float loopTime(float iTime) {
	return mod(iTime / 3. + .35, 1.);
}

// '3D' Texture Utils
// https://www.shadertoy.com/view/WljSWz
//--------------------------------------------------------

vec2 texSubdivisions = vec2(8,2);

#define MIRROR
#define SCALE (vec3(4.1,1.8,1.75))
#define OFFSET vec3(.95, .05, .05)

int faceIdFromDir(vec3 v) {
    vec3 va = abs(v);
    int id = 0;
    float m = va.x;
    if (va.y > m) id = 1, m = va.y;
    if (va.z > m) id = 2;
    if (v[id] < 0.) id += 3;
    return id;
}

vec3 dirFromFaceId(vec2 uv, int id) {
    vec3 dir = vec3(.5, .5 - uv.yx);
    dir = normalize(dir);
    if (id == 4) dir.yz *= -1.;
    if (id > 2) dir.xz *= -1., id -= 3;
    if (id == 1) return (dir * vec3(1,-1,-1)).zxy;
    if (id == 2) return (dir * vec3(1,1,-1)).zyx;    
    return dir;
}

vec3 texToSpace(vec2 coord, int c, int id, vec2 size) {
    vec2 sub = texSubdivisions;
    vec2 subSize = floor(size / sub);
    vec2 subCoord = floor(coord / subSize);
    float z = 0.;
    z += float(id) * 4. * sub.y * sub.x; // face offset
    z += float(c) * sub.y * sub.x; // channel offset
    z += subCoord.y * sub.x; // y offset
    z += subCoord.x; // x offset
    float zRange = sub.x * sub.y * 4. * 6. - 1.;
    z /= zRange;
    vec2 subUv = mod(coord / subSize, 1.);
    vec3 p = vec3(subUv, z);
    p = p * 2. - 1.; // range -1:1
    return p;
}

mat4 texToSpace(vec2 coord, int id, vec2 size) {
    return mat4(
        vec4(texToSpace(coord, 0, id, size), 0),
        vec4(texToSpace(coord, 1, id, size), 0),
        vec4(texToSpace(coord, 2, id, size), 0),
        vec4(texToSpace(coord, 3, id, size), 0)
    );
}

vec4 spaceToTex(vec3 p, vec2 size) {
    p = clamp(p, -1., 1.);
    p = p * .5 + .5; // range 0:1

    vec2 sub = texSubdivisions;
    vec2 subSize = floor(size / sub);

    float zRange = sub.x * sub.y * 4. * 6. - 1.;
    float i = round(p.z * zRange);

    vec2 coord = p.xy * subSize;

    int faceId = int(floor(i / (4. * sub.y * sub.x)));
    float channel = mod(floor(i / (sub.x * sub.y)), 4.);
    float y = mod(floor(i / sub.x), sub.y);
    float x = mod(i, sub.x);
    
    coord += vec2(x,y) * subSize;
	coord /= size;
    
    vec3 dir = dirFromFaceId(coord, faceId);

    return vec4(dir, channel);
}


float range(float vmin, float vmax, float value) {
  return clamp((value - vmin) / (vmax - vmin), 0., 1.);
}

float mapTex(samplerCube tex, vec3 p, vec2 size) {
    #ifdef MIRROR
        p.x = clamp(p.x, -.95, .95);
    #endif
    vec2 sub = texSubdivisions;
    float zRange = sub.x * sub.y * 4. * 6. - 1.;
    float z = p.z * .5 + .5;
    float zFloor = (floor(z * zRange) / zRange) * 2. - 1.;
    float zCeil = (ceil(z * zRange) / zRange) * 2. - 1.;
    vec4 uvcA = spaceToTex(vec3(p.xy, zFloor), size);
    vec4 uvcB = spaceToTex(vec3(p.xy, zCeil), size);
    float a = texture(tex, uvcA.xyz)[int(uvcA.w)];
    float b = texture(tex, uvcB.xyz)[int(uvcB.w)];
    return mix(a, b, range(zFloor, zCeil, p.z));
}

// Cube A (cubemap) — Interactive liquid metal blob by tmst
// https://www.shadertoy.com/view/3tGXz3

// --------------------------------------
// Helpers for accessing volumetric data
// --------------------------------------

vec2 getDataNearest(vec3 lmn) {
    return texture(iChannel0, vcubeFromLMN(1, lmn)).st;
}

vec2 getDataInterp(vec3 lmn) {
    vec3 flmn = floor(lmn);

    vec2 d000 = getDataNearest( flmn );
    vec2 d001 = getDataNearest( flmn + vec3(0.0, 0.0, 1.0) );
    vec2 d010 = getDataNearest( flmn + vec3(0.0, 1.0, 0.0) );
    vec2 d011 = getDataNearest( flmn + vec3(0.0, 1.0, 1.0) );
    vec2 d100 = getDataNearest( flmn + vec3(1.0, 0.0, 0.0) );
    vec2 d101 = getDataNearest( flmn + vec3(1.0, 0.0, 1.0) );
    vec2 d110 = getDataNearest( flmn + vec3(1.0, 1.0, 0.0) );
    vec2 d111 = getDataNearest( flmn + vec3(1.0, 1.0, 1.0) );

    // TODO: Compare to interpolation in Buf A
    vec3 t = lmn - flmn;
    vec2 dY0Z0 = mix(d000, d100, t.x);
    vec2 dY1Z0 = mix(d010, d110, t.x);
    vec2 dY0Z1 = mix(d001, d101, t.x);
    vec2 dY1Z1 = mix(d011, d111, t.x);
    vec2 dZ0 = mix(dY0Z0, dY1Z0, t.y);
    vec2 dZ1 = mix(dY0Z1, dY1Z1, t.y);
    return mix(dZ0, dZ1, t.z);
}

// ------------------------------
// Some noise for the cube faces
// ------------------------------

float rand(in vec2 p) {
    return fract(sin(dot(p,vec2(12.9898,78.233))) * 43758.5453);
}

float noise(vec2 p) {
    vec2 pi = floor(p);
    vec2 pf = fract(p);

    float r00 = rand(vec2(pi.x    ,pi.y    ));
    float r10 = rand(vec2(pi.x+1.0,pi.y    ));
    float r01 = rand(vec2(pi.x    ,pi.y+1.0));
    float r11 = rand(vec2(pi.x+1.0,pi.y+1.0));

    vec2 m = pf*pf*(3.0-2.0*pf);
    return mix(mix(r00, r10, m.x), mix(r01, r11, m.x), m.y);
}

float fbm(vec2 uv) {
    vec2 p = uv*32.0;

    float v = noise(p);

    p *= 0.5;
    v = mix(v, noise(p), 0.5);

    p *= 0.5;
    v = mix(v, noise(p), 0.5);

    return v;
}

// ----------------------------------------------------------------------
// Rodrigues' formula: v -> (v.n)n + (v-(v.n)n)c - (vxn)s
// in matrix form: (1-c)[n*n^T] + cI - s[[0,n3,-n2][-n3,0,n1][n2,-n1,0]]
// ----------------------------------------------------------------------

mat3 glRotate(vec3 axis, float angle) {
    float c = cos(angle);
    float s = sin(angle);
    vec3 n = normalize(axis);

    return mat3(
        (1.0-c)*n.x*n.x + c,
        (1.0-c)*n.y*n.x + s*n.z,
        (1.0-c)*n.z*n.x - s*n.y,

        (1.0-c)*n.x*n.y - s*n.z,
        (1.0-c)*n.y*n.y + c,
        (1.0-c)*n.z*n.y + s*n.x,

        (1.0-c)*n.x*n.z + s*n.y,
        (1.0-c)*n.y*n.z - s*n.x,
        (1.0-c)*n.z*n.z + c
    );
}

// -----------------------
// Volumetric data update
// -----------------------

// NOTE: These pixels refer to voxel *corners* with s as "density" and
// t as "temperature".  These will be interpolated in the voxel volume.

vec3 cpLine(vec3 q0, vec3 q1, vec3 p) {
    vec3 vEdge = q1 - q0;
    float t = dot(p - q0, vEdge) / dot(vEdge, vEdge);
    return q0 + t*vEdge;
}

float sdLine(vec3 q0, vec3 q1, vec3 p) {
    vec3 x = cpLine(q0, q1, p);
    return distance(x, p);
}

void doPage1(out vec4 fragColor, in vec3 lmn)
{
    float iTimeN = float(iFrame)/60.0;

    vec3 mid = vec3(63.5);
    vec3 absd = abs(lmn-mid);
    float dcorner = max(max(absd.x, absd.y), absd.z);

    vec2 stNext = vec2(0.0);
    if (dcorner > 62.0) {
        // On the cube faces, add density noise at 0 temperature
        float noiseVal = 0.0;

        if (absd.x > 62.0) {
            noiseVal = fbm(0.02*lmn.yz);
        } else if (absd.y > 62.0) {
            noiseVal = fbm(0.02*lmn.xz);
        } else if (absd.z > 62.0) {
            noiseVal = fbm(0.02*lmn.xy);
        }

        float modTime = mod(iTimeN, 12.0);
        float dofull = 1.0 - step(0.64, abs(modTime-3.0));
        float doempty = 1.0 - step(0.45, abs(modTime-9.0));

        float dNext = 2.0*pow(noiseVal, 3.0);
        dNext = mix(dNext, 0.5, mix(0.0, 0.8, dofull));
        dNext = mix(dNext, 0.0, mix(0.0, 0.8, doempty));

        stNext = vec2(dNext, 0.0);

    } else {
        // On the interior: shrink, rotate, increase density, and lower temperature
        vec3 dlmn = lmn - mid;

        float axisAng = 0.75*iTimeN;
        vec3 nvAxis = normalize( vec3(cos(axisAng),0.0,sin(axisAng)) );

        mat3 mr = glRotate(nvAxis, 0.075*cos(iTimeN));
        vec3 dlmnrot = mr * dlmn;
        vec3 lmnrot = mid + dlmnrot;

        float mamt = -0.0125;
        vec3 next = mix(lmnrot, mid, mamt);

        vec2 stOld = getDataInterp(next);
        stNext = vec2( stOld.s*1.07, stOld.t*0.99 );
    }

    // Mouse input
    //---------------------------------------
    // Punch a hole along entry-exit axis, setting density 0 and temperature 1 (max)
    vec4 entry = texelFetch(iChannel1, ivec2(0,0), 0);
    vec4 exit = texelFetch(iChannel1, ivec2(1,0), 0);

    if (entry.a > 0.5 && exit.a > 0.5) {
        vec3 lmnEntry = BOX_N * entry.xyz;
        vec3 lmnExit = BOX_N * exit.xyz;

        float dHole = sdLine(lmnEntry, lmnExit, lmn);
        stNext = mix(
            vec2(0.0, 1.0),
            stNext,
            smoothstep(10.0, 16.0, dHole)
        );
    }
    //---------------------------------------

    fragColor = vec4(stNext, 0.0, 0.0);
}

// -----------------------------------------
// Check if level surface at DENSITY_THRESH
// -----------------------------------------

// NOTE: These pixels refer to the voxel volumes,
// not the corner points as in page 1.

void doPage2(out vec4 fragColor, in vec3 lmn)
{
    vec2 data0 = getDataNearest(lmn);

    float h000 = data0.s;
    float h001 = getDataNearest( lmn + vec3(0.0, 0.0, 1.0) ).s;
    float h010 = getDataNearest( lmn + vec3(0.0, 1.0, 0.0) ).s;
    float h011 = getDataNearest( lmn + vec3(0.0, 1.0, 1.0) ).s;
    float h100 = getDataNearest( lmn + vec3(1.0, 0.0, 0.0) ).s;
    float h101 = getDataNearest( lmn + vec3(1.0, 0.0, 1.0) ).s;
    float h110 = getDataNearest( lmn + vec3(1.0, 1.0, 0.0) ).s;
    float h111 = getDataNearest( lmn + vec3(1.0, 1.0, 1.0) ).s;

    // Check if at least one of the values is beyond threshold
    float solid = (
        step(DENSITY_THRESH, h000) + step(DENSITY_THRESH, h001) +
        step(DENSITY_THRESH, h010) + step(DENSITY_THRESH, h011) +
        step(DENSITY_THRESH, h100) + step(DENSITY_THRESH, h101) +
        step(DENSITY_THRESH, h110) + step(DENSITY_THRESH, h111)
    ) / 8.0;

    // Also record the density/temp here, so it's not off by a frame
    fragColor = vec4(data0, 0.0, solid);
}

// ---------------------------------------
// Compute normals at voxel corner points
// ---------------------------------------

#define GD 2.0

void doPage3(out vec4 fragColor, in vec3 lmn)
{
    // Compute normal
    float hLA = getDataNearest( lmn + vec3(-GD,  0.0,  0.0) ).s;
    float hLB = getDataNearest( lmn + vec3( GD,  0.0,  0.0) ).s;
    float hMA = getDataNearest( lmn + vec3( 0.0, -GD,  0.0) ).s;
    float hMB = getDataNearest( lmn + vec3( 0.0,  GD,  0.0) ).s;
    float hNA = getDataNearest( lmn + vec3( 0.0,  0.0, -GD) ).s;
    float hNB = getDataNearest( lmn + vec3( 0.0,  0.0,  GD) ).s;

    vec3 gradA = vec3(hLB-hLA, hMB-hMA, hNB-hNA);
    vec3 normal = 0.5 + 0.5*(-gradA/(length(gradA) + 1e-5));

    fragColor = vec4(normal, 0.0);
}

// -------------------------------------
// Determine what to do based on rayDir
// -------------------------------------

void mainCubemap(out vec4 fragColor, in vec2 fragCoord, in vec3 rayOri, in vec3 rayDir)
{
    vec3 lmn;
    int pageDst;
    lmnFromVCube(rayDir, pageDst, lmn);

    if (pageDst == 1) {
        doPage1(fragColor, lmn);
    } else if (pageDst == 2) {
        doPage2(fragColor, lmn);
    } else if (pageDst == 3) {
        doPage3(fragColor, lmn);
    }
}

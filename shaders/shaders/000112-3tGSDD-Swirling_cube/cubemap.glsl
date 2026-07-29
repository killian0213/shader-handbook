// Cube A (cubemap) — Swirling cube by tmst
// https://www.shadertoy.com/view/3tGSDD

// --------------------------------------
// Helpers for accessing volumetric data
// --------------------------------------

vec4 getDataNearest(vec3 lmn) {
    return texture(iChannel0, vcubeFromLMN(1, lmn));
}

float getDensityInterp(vec3 lmn) {
    vec3 flmn = floor(lmn);

    float d000 = getDataNearest( flmn ).a;
    float d001 = getDataNearest( flmn + vec3(0.0, 0.0, 1.0) ).a;
    float d010 = getDataNearest( flmn + vec3(0.0, 1.0, 0.0) ).a;
    float d011 = getDataNearest( flmn + vec3(0.0, 1.0, 1.0) ).a;
    float d100 = getDataNearest( flmn + vec3(1.0, 0.0, 0.0) ).a;
    float d101 = getDataNearest( flmn + vec3(1.0, 0.0, 1.0) ).a;
    float d110 = getDataNearest( flmn + vec3(1.0, 1.0, 0.0) ).a;
    float d111 = getDataNearest( flmn + vec3(1.0, 1.0, 1.0) ).a;

    vec3 t = lmn - flmn;
    float dY0Z0 = mix(d000, d100, t.x);
    float dY1Z0 = mix(d010, d110, t.x);
    float dY0Z1 = mix(d001, d101, t.x);
    float dY1Z1 = mix(d011, d111, t.x);
    float dZ0 = mix(dY0Z0, dY1Z0, t.y);
    float dZ1 = mix(dY0Z1, dY1Z1, t.y);
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

#define GD 3.0

void doPage1(out vec4 fragColor, in vec3 lmn)
{
    // -----------------------------------
    // Compute normal from previous frame
    // -----------------------------------
    float hLA = getDataNearest( lmn + vec3(-GD,  0.0,  0.0) ).a;
    float hLB = getDataNearest( lmn + vec3( GD,  0.0,  0.0) ).a;
    float hMA = getDataNearest( lmn + vec3( 0.0, -GD,  0.0) ).a;
    float hMB = getDataNearest( lmn + vec3( 0.0,  GD,  0.0) ).a;
    float hNA = getDataNearest( lmn + vec3( 0.0,  0.0, -GD) ).a;
    float hNB = getDataNearest( lmn + vec3( 0.0,  0.0,  GD) ).a;
    
    vec3 gradA = vec3(hLB-hLA, hMB-hMA, hNB-hNA);
    vec3 nvNormal = -gradA/( length(gradA) + 1e-5 );
    
    // ---------------
    // Update density
    // ---------------
    float iTimeN = float(iFrame)/60.0;
    
    vec3 mid = vec3(63.5);
    vec3 absd = abs(lmn-mid);
    float dcorner = max(max(absd.x, absd.y), absd.z);
    
    float dNext = 0.0;
    if (dcorner > 62.0) {
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

        dNext = 2.0*pow(noiseVal, 3.0);
        dNext = mix(dNext, 0.5, mix(0.0, 0.8, dofull));
        dNext = mix(dNext, 0.0, mix(0.0, 0.8, doempty));
        
    } else {
        vec3 dlmn = lmn - mid;
            
        float axisAng = 0.75*iTimeN;
        vec3 nvAxis = normalize( vec3(cos(axisAng),0.0,sin(axisAng)) );
        
        mat3 mr = glRotate(nvAxis, 0.075*cos(iTimeN));
        vec3 dlmnrot = mr * dlmn;
        vec3 lmnrot = mid + dlmnrot;
        
        float mamt = -0.015;
        vec3 next = mix(lmnrot, mid, mamt);

    	dNext = 1.04 * getDensityInterp( next );
    }
    
    fragColor = vec4(0.5*nvNormal + 0.5, dNext);
}

void mainCubemap( out vec4 fragColor, in vec2 fragCoord, in vec3 rayOri, in vec3 rayDir )
{
    vec3 lmn;
    int pageDst;
    lmnFromVCube(rayDir, pageDst, lmn);

    if (pageDst == 1) {
        doPage1(fragColor, lmn);
    } else {
        discard;
    }
}

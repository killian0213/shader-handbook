// Cube A (cubemap) — Interactive fluid with caustics by tmst
// https://www.shadertoy.com/view/ttdXRf

// Description and references:
// -------------------------------------------------------------------------------
// This shader implements the method for rendering caustics described in [1].
// Multiple render targets are replaced by writing to multiple cube faces.
// - [1] "Fast Real-time Caustics from height Fields" (Yuksel, Keyser)
// -------------------------------------------------------------------------------

// Keyboard input description: https://www.shadertoy.com/view/lsXGzf
#define KEY_SPACE 32

// ================
// Generic helpers
// ================

vec4 read(int page, vec2 fragCoord) {
    return textureLod(iChannel0, vcubeFromFragCoord(page, fragCoord), 0.0);
}

vec2 getHeightData(vec2 fragCoord) {
    return read(1, fragCoord).rg;
}

vec3 getSurfaceNormal(vec2 fragCoord) {
    return 2.0*( read(2, fragCoord).xyz - 0.5 );
}

// ==============
// Shallow water
// ==============

// Helpers for initial/reset value
// ---------------------------------------
float noise(in vec2 p) {
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
// ---------------------------------------

void writePage1(out vec4 fragColor, in vec2 fragCoord)
{
    vec4 data0 = read(1, fragCoord);

    vec2 h0 = data0.rg;
    vec2 hXB = getHeightData( fragCoord + vec2(1.0,0.0) );
    vec2 hXA = getHeightData( fragCoord - vec2(1.0,0.0) );
    vec2 hZB = getHeightData( fragCoord - vec2(0.0,1.0) );
    vec2 hZA = getHeightData( fragCoord + vec2(0.0,1.0) );

    float hAvg = 0.25 * (hXB.s + hXA.s + hZB.s + hZA.s);
    float hNew = mix(h0.t, hAvg, 2.0);

    vec2 uv = fragCoord/vec2(1024.0);

    // Mouse input
    //---------------------------------------
    vec2 packMouse0 = textureLod(iChannel2, vec2(0.0), 0.0).rg;
    vec2 packMouse1 = data0.ba;

    vec2 uvMouse0;
    bool isMousePressed0;
    unpackUVWithBool(packMouse0, uvMouse0, isMousePressed0);

    vec2 uvMouse1;
    bool isMousePressed1;
    unpackUVWithBool(packMouse1, uvMouse1, isMousePressed1);

    if (isMousePressed0 && isMousePressed1) {
        float targetDistUV = sdSeg2(uvMouse0, uvMouse1, uv);

        float bumpHeight = smoothstep(0.0, 0.03, targetDistUV);
        hNew = max(hNew, 1.0-bumpHeight);
    }
    //---------------------------------------

    // Damping
    hNew = mix(hNew, 0.5, 0.003);

    // Initial/reset value
    if (iTime < 0.1) {
        float a = fbm(uv*0.25)*6.28;
        hNew = fbm( uv +  0.25*vec2(cos(a), sin(a)) );
        hNew = smoothstep(0.4, 0.6, hNew);
    }

    // Clamp
    hNew = clamp(hNew, 0.0, 1.0);

    bool isSpacePressed = texelFetch(iChannel1, ivec2(KEY_SPACE,0), 0).x > 0.5;
    fragColor = isSpacePressed ? data0 : vec4(hNew, h0.s, packMouse0);
}

// ====================
// Pool surface normal
// ====================

void writePage2(out vec4 fragColor, in vec2 fragCoord)
{
    float hXB = getHeightData( fragCoord + vec2(1.0,0.0) ).r;
    float hXA = getHeightData( fragCoord - vec2(1.0,0.0) ).r;
    float hZB = getHeightData( fragCoord - vec2(0.0,1.0) ).r;
    float hZA = getHeightData( fragCoord + vec2(0.0,1.0) ).r;

    vec2 pixelWorldSize = (POOL_SURFACE_WORLD_MAX.xz - POOL_SURFACE_WORLD_MIN.xz) / 1024.0;
    vec2 gradh = vec2(hXB-hXA, hZB-hZA) * POOL_BUMP_HEIGHT_WORLD / (2.0 * pixelWorldSize);
    vec3 surfaceNormal = normalize(vec3(-gradh.s, 1.0, -gradh.t));

    fragColor = vec4(0.5 + 0.5*surfaceNormal, 0.0);
}

// =================
// Caustics Pass 1A
// =================

vec3 surfaceUVToWorld(vec2 uv) {
    return vec3(
        mix(POOL_SURFACE_WORLD_MIN.x, POOL_SURFACE_WORLD_MAX.x, uv.s),
        mix(POOL_SURFACE_WORLD_MIN.y, POOL_SURFACE_WORLD_MAX.y, 0.5),
        mix(POOL_SURFACE_WORLD_MAX.z, POOL_SURFACE_WORLD_MIN.z, uv.t)
    );
}

vec2 surfaceWorldToUV(vec3 p) {
    return vec2(
        unmix(POOL_SURFACE_WORLD_MIN.x, POOL_SURFACE_WORLD_MAX.x, p.x),
        unmix(POOL_SURFACE_WORLD_MAX.z, POOL_SURFACE_WORLD_MIN.z, p.z)
    );
}

void causticPass1(out vec4 fragColor, in vec2 fragCoord, float yOffset)
{
    vec2 uv = fragCoord / vec2(1024.0);

    vec3 poolWorldPos = surfaceUVToWorld(uv);
    vec3 baseWorldPos = poolWorldPos - vec3(0.0, POOL_DEPTH_WORLD, 0.0);
    vec3 lightWorldPos = sceneLight(iTime);

    // "Un-refract" to compute the "illumination center" on the pool surface
    // --------------------------------------------------------------------
    // We want the surface point refracting lightWorldPos onto baseWorldPos.
    // For IR ratios 0 and 1, easy to find--correct point is somewhere between.
    // So we do a binary search between those two points.

    vec3 eta0 = poolWorldPos;
    vec3 eta1 = mix(baseWorldPos, lightWorldPos, unmix(baseWorldPos.y, lightWorldPos.y, POOL_SURFACE_CENTER.y));

    vec3 vecOut0 = refract(normalize(eta0-lightWorldPos), vec3(0.0,1.0,0.0), IR_AIR/IR_LIQUID);
    vec3 vecOutBase0 = eta0 - (POOL_DEPTH_WORLD/vecOut0.y)*vecOut0;
    float dsq0 = 0.0;

    vec3 vecOut1 = refract(normalize(eta1-lightWorldPos), vec3(0.0,1.0,0.0), IR_AIR/IR_LIQUID);
    vec3 vecOutBase1 = eta1 - (POOL_DEPTH_WORLD/vecOut1.y)*vecOut1;
    float dsq1 = lensq(vecOutBase0-vecOutBase1);

    float dsqTarget = lensq(vecOutBase0-baseWorldPos);

    float b0 = 0.0;
    float b1 = 1.0;
    for (int k=0; k<10; k++) {
        float bStep = mix(b0, b1, 0.5);
        vec3 test = mix(eta0, eta1, bStep);

        vec3 vecOutTest = refract(normalize(test-lightWorldPos), vec3(0.0,1.0,0.0), IR_AIR/IR_LIQUID);
        vec3 vecOutBaseTest = test - (POOL_DEPTH_WORLD/vecOutTest.y)*vecOutTest;
        float dsqTest = lensq(vecOutBase0-vecOutBaseTest);

        if (dsqTest < dsqTarget) {
            b0 = bStep;
        } else {
            b1 = bStep;
        }
    }

    vec3 icWorld = mix(eta0, eta1, mix(b0, b1, 0.5));
    vec2 icUV = surfaceWorldToUV(icWorld);
    vec2 icFragCoord = icUV * 1024.0;
    // --------------------------------------------------------------------

    vec4 finalResult = vec4(0.0);

    vec2 pixelWorldSize = (POOL_SURFACE_WORLD_MAX.xz - POOL_SURFACE_WORLD_MIN.xz) / 1024.0;
    for (int i=-3; i<=3; i++) {
        vec2 sampleFragCoord = icFragCoord + vec2(float(i), 0.0);

        // "Straighten" normal to make caustics less sensitive to gradients
        vec3 nSurface = getSurfaceNormal(sampleFragCoord);
        nSurface = normalize( mix(vec3(0.0,1.0,0.0), nSurface, 0.25) );

        vec3 sampleWorld = icWorld + vec3(float(i)*pixelWorldSize.x, 0.0, 0.0);

        vec3 vecOut = refract(normalize(sampleWorld-lightWorldPos), nSurface, IR_AIR/IR_LIQUID);
        vec3 vecOutBase = sampleWorld - (POOL_DEPTH_WORLD/vecOut.y)*vecOut;

        vec2 hitFragCoord = surfaceWorldToUV(vecOutBase) * 1024.0;
        float ax = max(0.0, 1.0 - abs( fragCoord.x - hitFragCoord.x ));
        finalResult += ax * vec4(
            max(0.0, 1.0 - abs( fragCoord.y+( 0.0+yOffset) - hitFragCoord.y )),
            max(0.0, 1.0 - abs( fragCoord.y+( 1.0+yOffset) - hitFragCoord.y )),
            max(0.0, 1.0 - abs( fragCoord.y+( 2.0+yOffset) - hitFragCoord.y )),
            max(0.0, 1.0 - abs( fragCoord.y+( 3.0+yOffset) - hitFragCoord.y ))
        );
    }

    fragColor = finalResult;
}

void writePage3(out vec4 fragColor, in vec2 fragCoord) {
    causticPass1(fragColor, fragCoord, 0.0);
}

// =================
// Caustics Pass 1B
// =================

void writePage4(out vec4 fragColor, in vec2 fragCoord) {
    causticPass1(fragColor, fragCoord, -3.0);
}

// ================
// Caustics Pass 2
// ================

void writePage5(out vec4 fragColor, in vec2 fragCoord) {
    float intensity = (
        read(3, fragCoord                ).r +
        read(3, fragCoord - vec2(0.0,1.0)).g +
        read(3, fragCoord - vec2(0.0,2.0)).b +
        read(3, fragCoord - vec2(0.0,3.0)).a +
        read(4, fragCoord + vec2(0.0,3.0)).r +
        read(4, fragCoord + vec2(0.0,2.0)).g +
        read(4, fragCoord + vec2(0.0,1.0)).b
    );
    fragColor = vec4(clamp(0.5*intensity, 0.0, 1.0));
}

// =========================
// Output depends on "page"
// =========================

void mainCubemap( out vec4 fragColor, in vec2 _fragCoord, in vec3 rayOri, in vec3 rayDir )
{
    int page;
    vec2 fragCoord;
    fragCoordFromVCube(rayDir, page, fragCoord);

    if (page == 1) {
        writePage1(fragColor, fragCoord);
    } else if (page == 2) {
        writePage2(fragColor, fragCoord);
    } else if (page == 3) {
        writePage3(fragColor, fragCoord);
    } else if (page == 4) {
        writePage4(fragColor, fragCoord);
    } else if (page == 5) {
        writePage5(fragColor, fragCoord);
    } else {
        discard;
    }
}

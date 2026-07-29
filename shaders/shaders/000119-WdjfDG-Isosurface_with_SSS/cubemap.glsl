// Cube A (cubemap) — Isosurface with SSS by tmst
// https://www.shadertoy.com/view/WdjfDG

#define CUBE_SAMPLER iChannel0

// ==========================
// Store density on "page 1"
// ==========================

vec4 doPage1(vec3 lmn) {
    return vec4(fDensity(lmn, ITIME), 1.0, 1.0, 1.0);
}

// NOTE: Used by "page 2" when computing lighting.  On the first frame, "page 1"
// won't have been written, so we compute rather than just looking up the value.
vec4 getPage1(vec3 lmn) {
    return INITIALIZING ? doPage1(lmn) : texture(CUBE_SAMPLER, vcubeFromLMN(1, lmn));
}

// ===========================
// Store lighting on "page 2"
// ===========================

float march(vec3 p, vec3 nv) {
    float lightAmount = 1.0;

    vec2 tRange;
    bool didHitBox;
    boxClip(BOX_MIN, BOX_MAX, p, nv, tRange, didHitBox);
    tRange.s = max(0.0, tRange.s);

    if (!didHitBox) {
        return 0.0;
    }

    float t = tRange.s;
    for (int i = 0; i < 150; i++) { // Theoretical max steps: (BOX_MAX-BOX_MIN)*sqrt(3)/RAY_STEP_L
        if (t > tRange.t || lightAmount < 1.0-QUIT_ALPHA_L) { break; }

        vec3 rayPos = p + t*nv;
        vec3 lmn = lmnFromWorldPos(rayPos);

        float density = getPage1(lmn).s;
        float calpha = clamp(density * MAX_ALPHA_PER_UNIT_DIST * RAY_STEP_L, 0.0, 1.0);

        lightAmount *= 1.0 - calpha;

        t += RAY_STEP_L;
    }

    return lightAmount;
}

vec4 doPage2(vec3 lmn) {
	vec3 p = worldPosFromLMN(lmn);
    float lightAmount = march(p, normalize(LIGHT_POS(ITIME) - p));

    return vec4(1.0, lightAmount, 1.0, 1.0);
}

// ==================
// Write to cube map
// ==================

void mainCubemap(out vec4 fragColor, in vec2 fragCoord, in vec3 rayOri, in vec3 rayDir) {
    vec3 lmn;
    int pageDst;
    lmnFromVCube(rayDir, pageDst, lmn);

    if (pageDst == 1) {
        fragColor = doPage1(lmn);
    } else if (pageDst == 2) {
        fragColor = doPage2(lmn);
    } else {
        discard;
    }
}

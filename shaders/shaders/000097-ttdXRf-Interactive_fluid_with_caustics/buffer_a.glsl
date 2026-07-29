// Buffer A (buffer) — Interactive fluid with caustics by tmst
// https://www.shadertoy.com/view/ttdXRf

#define MIN_DIST 0.005
#define MAX_DIST 50.0
#define RAY_STEPS 40
#define RAY_STEPS_SHADOW 20

#define CAUSTICS_INTENSITY 0.5
#define LIGHT_COLOR vec3(1.0)
#define GEOMETRY_COLOR_ABOVE vec3(0.2)
#define GEOMETRY_COLOR_BELOW vec3(0.7, 0.7, 0.7)
#define LIQUID_COLOR vec3(0.3, 0.45, 0.375)
#define VOLUMETRIC_MAX_DIST 0.35

#define ID_NONE 0
#define ID_POOL 1
#define ID_GEOMETRY 2

// ================
// General helpers
// ================

float getHeight(vec2 uv) {
    return texture(iChannel0, vcubeFromFragCoord(1, uv*1024.0)).g;
}

vec3 getNormal(vec2 uv) {
    return 2.0 * (texture(iChannel0, vcubeFromFragCoord(2, uv*1024.0)).xyz - 0.5);
}

float getCaustic(vec2 uv) {
    return texture(iChannel0, vcubeFromFragCoord(5, uv*1024.0)).x;
}

void getParallaxMaxOffsets(
    in vec3 tangentS,
    in vec3 tangentT,
    in vec3 nvNormal,
    in vec3 camToFrag,
    in float depthMax,
    out vec2 maxTexOffset,
    out vec3 maxPosOffset
){
    // Scale camToFrag so that its depth into the surface == depthMax
    float camDist = -dot(camToFrag, nvNormal);
    maxPosOffset = (depthMax / camDist) * camToFrag;

    // maxPosOffset = a*tangentS + b*tangentT + N <=> maxTexOffset = [a,b]
    float dss = dot(tangentS, tangentS);
    float dst = dot(tangentS, tangentT);
    float dtt = dot(tangentT, tangentT);
    float dcs = dot(maxPosOffset, tangentS);
    float dct = dot(maxPosOffset, tangentT);
    float invDet = 1.0 / (dss * dtt - dst * dst);
    maxTexOffset = invDet * vec2(dtt*dcs - dst*dct, -dst*dcs + dss*dct);
}

float getParallaxDepthFactor(vec2 uvInitial, vec2 maxTexOffset, int steps) {
    vec2 uvMax = uvInitial + maxTexOffset;
    float dt = 1.0 / float(steps);

    float tOld = 0.0, depthOld = 0.0;
    float tCur = 0.0, depthCur = 0.0;

    for(int i=0; i<=steps; ++i){
        tOld = tCur;
        tCur = float(i)*dt;

        depthOld = depthCur;
        depthCur = 1.0 - getHeight(mix(uvInitial, uvMax, tCur));

        if(tCur > depthCur){
            tCur = mix(tOld, tCur, unmix(depthOld-tOld, depthCur-tCur, 0.0));
            break;
        }
    }

    return tCur;
}

// ===========================
// Scene geometry and shadows
// ===========================

void sdGeometry(in vec3 p, out float sd) {
    float sdA = sdBox( vec3(0.0, -2.0*POOL_DEPTH_WORLD, 0.0), vec3(1.0, 2.0*POOL_DEPTH_WORLD + 0.01, 1.0), p );
    float sdB1 = sdBox( vec3(0.0), vec3(0.8,     POOL_DEPTH_WORLD, 0.8), p );
    float sdB2 = sdBox( vec3(0.0), vec3(0.3, 2.0*POOL_DEPTH_WORLD, 0.3), p );
    sd = max(-min(sdB1, sdB2),sdA);
}

vec3 nvGeometryNormal(in vec3 p) {
    float sdXA, sdXB, sdYA, sdYB, sdZA, sdZB;

    const float eps = 1e-2;
    sdGeometry(p - vec3(eps, 0.0, 0.0), sdXA);
    sdGeometry(p + vec3(eps, 0.0, 0.0), sdXB);
    sdGeometry(p - vec3(0.0, eps, 0.0), sdYA);
    sdGeometry(p + vec3(0.0, eps, 0.0), sdYB);
    sdGeometry(p - vec3(0.0, 0.0, eps), sdZA);
    sdGeometry(p + vec3(0.0, 0.0, eps), sdZB);

    return normalize(vec3(sdXB-sdXA, sdYB-sdYA, sdZB-sdZA));
}

void hitPool(in vec3 p, in vec3 nv, out int idHit, out vec3 pHit, out vec2 uvHit) {
    float poolSurfaceY = mix(POOL_SURFACE_WORLD_MIN.y, POOL_SURFACE_WORLD_MAX.y, 0.5);

    float t = (poolSurfaceY - p.y) / nv.y;
    if (t < MIN_DIST) {
        idHit = ID_NONE;
        return;
    }

    pHit = p + t*nv;
    uvHit = vec2(
        unmix(POOL_SURFACE_WORLD_MIN.x, POOL_SURFACE_WORLD_MAX.x, pHit.x),
        unmix(POOL_SURFACE_WORLD_MAX.z, POOL_SURFACE_WORLD_MIN.z, pHit.z)
    );

    float didHit = isInInterval(0.0, 1.0, uvHit.s) * isInInterval(0.0, 1.0, uvHit.t);
    idHit = didHit < 0.5 ? ID_NONE : ID_POOL;
}

void hitScene(in vec3 p, in vec3 nv, out int idHit, out vec3 pHit) {
    float travel = 0.0;
    vec3 curPos = p;

    for (int k = 0; k < RAY_STEPS; k++) {
        float sdStep;
        sdGeometry(curPos, sdStep);

        if (abs(sdStep) < MIN_DIST) {
            idHit = ID_GEOMETRY;
            pHit = curPos;
            return;
        }

        curPos += sdStep * nv;
        travel += sdStep;
        if (travel > MAX_DIST) {
            break;
        }
    }

    idHit = ID_NONE;
    pHit = curPos;
}

float getShadowCoeff(in vec3 p, in vec3 nv) {
    float tHit = 0.0;
    vec3 curPos = p;
    float shadowCoeff = 0.0;

    for (int k = 0; k < RAY_STEPS_SHADOW; k++) {
        float sdStep;
        sdGeometry(curPos, sdStep);

        float curLightPercent = abs(sdStep)/(0.1*tHit);
        shadowCoeff = max(shadowCoeff, 1.0-curLightPercent);

        if (abs(sdStep) < MIN_DIST) {
            shadowCoeff = 1.0;
            break;
        }

        curPos += sdStep * nv;
        tHit += sdStep;
        if (tHit > MAX_DIST) {
            break;
        }
    }

    return clamp(shadowCoeff, 0.0, 1.0);
}

// =========
// Textures
// =========

vec3 skybox(in vec3 nv) {
    return mix(0.5+0.5*normalize(nv), vec3(0.8, 0.7, 1.0), 0.7);
}

void texPool(
    in vec3 camPos, in vec3 lightPos, in vec3 p,
    out vec3 pBump, out float didHit,
    out vec3 c, out vec3 nvRefl, out float coeffRefl, out vec3 nvRefract, out float coeffRefract
) {
    vec2 uv = vec2(
        unmix(POOL_SURFACE_WORLD_MIN.x, POOL_SURFACE_WORLD_MAX.x, p.x),
        unmix(POOL_SURFACE_WORLD_MAX.z, POOL_SURFACE_WORLD_MIN.z, p.z)
    );

    vec3 tangentS = vec3(POOL_SURFACE_WORLD_MAX.x-POOL_SURFACE_WORLD_MIN.x, 0.0, 0.0);
    vec3 tangentT = vec3(0.0, 0.0, POOL_SURFACE_WORLD_MIN.z-POOL_SURFACE_WORLD_MAX.z);

    // Parallax occlusion mapping: hit surface
    vec2 maxTexOffset;
    vec3 maxPosOffset;
    getParallaxMaxOffsets(
        tangentS,
        tangentT,
        vec3(0.0, 1.0, 0.0),
        p - camPos,
        POOL_BUMP_HEIGHT_WORLD,
        maxTexOffset,
        maxPosOffset
    );

    float depthPct = getParallaxDepthFactor(uv, maxTexOffset, 16);

    vec2 uvBump = uv + depthPct*maxTexOffset;
    vec3 posBump = p + depthPct*maxPosOffset;
    vec3 nvBumpNormal = getNormal(uvBump);

    // Output where (and if) the bumped surface got hit
    pBump = posBump;
    didHit = isInInterval(0.0, 1.0, uvBump.s) * isInInterval(0.0, 1.0, uvBump.t);

    // Material for surface
    vec3 nvBumpPosToCam = normalize(camPos - posBump);
    vec3 nvBumpPosToLight = normalize(lightPos - posBump);

    vec3 matSurface = vec3(1.0);
    vec3 diffuse;
    vec3 specular;
    materialShader(
        0.25, 0.75, 80.0,
        LIGHT_COLOR, matSurface, nvBumpNormal,
        nvBumpPosToLight,
        nvBumpPosToCam,
        diffuse,
        specular
    );
    float shadowCoeff = getShadowCoeff(posBump + 0.005*nvBumpNormal, nvBumpPosToLight);
    diffuse *= (1.0 - shadowCoeff);
    specular *= (1.0 - shadowCoeff);

    // Reflection data (Schlick approximation)
    nvRefl = normalize(reflect(posBump-camPos, nvBumpNormal));

    float r0 = pow((IR_LIQUID-IR_AIR)/(IR_LIQUID+IR_AIR), 2.0);
    float cosHitAngle = dot(nvBumpNormal, nvBumpPosToCam);
    coeffRefl = mix(r0, 1.0, pow(clamp(1.0 - cosHitAngle, 0.0, 1.0), 5.0));

    // Refraction data
    nvRefract = refract(-nvBumpPosToCam, nvBumpNormal, IR_AIR/IR_LIQUID);
    coeffRefract = 0.9*(1.0 - coeffRefl);

    // Base color to be blended with reflection/refraction
    c = specular + (1.0 - (coeffRefl+coeffRefract))*diffuse;
}

void texGeometryBase(
    in vec3 camPos, in vec3 lightPos, in vec3 matColor, in vec3 p,
    out vec3 color, out float shadowCoeff
) {
    vec3 nvNormal = nvGeometryNormal(p);

    vec3 nvPosToCam = normalize(camPos - p);
    vec3 nvPosToLight = normalize(lightPos - p);

    vec3 diffuse;
    vec3 specular;
    materialShader(
        0.6, 0.9, 25.0,
        LIGHT_COLOR, matColor, nvNormal,
        nvPosToLight,
        nvPosToCam,
        diffuse,
        specular
    );
    color = diffuse + specular;
    shadowCoeff = getShadowCoeff(p + 0.005*nvNormal, nvPosToLight);
}

vec3 texGeometry(vec3 camPos, vec3 lightPos, vec3 p) {
    vec3 c;
    float shadowCoeff;
    texGeometryBase(camPos, lightPos, GEOMETRY_COLOR_ABOVE, p, c, shadowCoeff);

    return mix(c, vec3(0.0), shadowCoeff);
}

vec3 texGeometryUnderwater(vec3 camPos, vec3 lightPos, vec3 p) {
    vec3 c;
    float shadowCoeff;
    texGeometryBase(camPos, lightPos, GEOMETRY_COLOR_BELOW, p, c, shadowCoeff);

    // The caustics map assumes that p is POOL_DEPTH_WORLD below poolSurfaceY.
    // In general, we need to shift it based on depth.
    // --------------------------------------------------
    float poolSurfaceY = mix(POOL_SURFACE_WORLD_MIN.y, POOL_SURFACE_WORLD_MAX.y, 0.5);

    vec3 posToLight = lightPos - p;
    float targetY = poolSurfaceY - POOL_DEPTH_WORLD;
    vec3 pCorrected = p + ((targetY - p.y) / posToLight.y)*posToLight;

    vec2 uvCaustic = vec2(
        unmix(POOL_SURFACE_WORLD_MIN.x, POOL_SURFACE_WORLD_MAX.x, pCorrected.x),
        unmix(POOL_SURFACE_WORLD_MAX.z, POOL_SURFACE_WORLD_MIN.z, pCorrected.z)
    );
    // --------------------------------------------------

    float caustic = getCaustic(uvCaustic);
    float causticShadow = CAUSTICS_INTENSITY*clamp(unmix(0.5, 0.0, caustic), 0.0, 1.0);
    float causticHighlight = CAUSTICS_INTENSITY*clamp(unmix(0.5, 1.0, caustic), 0.0, 1.0);

    c = mix(c, LIGHT_COLOR, causticHighlight);
    c = mix(c, vec3(0.0), clamp(causticShadow + shadowCoeff, 0.0, 1.0));
    return c;
}

// ====================================================
// Final image
// ====================================================

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord/iResolution.xy;

    vec3 camPos;
    vec3 nvCamDir;
    sceneCamera(iResolution, fragCoord, iTime, camPos, nvCamDir);
    vec3 lightPos = sceneLight(iTime);

    // Hit scene with signed distance field; hit pool exactly
    // ----------------------------------------------------------
    int idHitScene;
    vec3 pHitScene;
    hitScene(camPos, nvCamDir, idHitScene, pHitScene);

    int idHitPool;
    vec3 pHitPool;
    vec2 uvHitPool;
    hitPool(camPos, nvCamDir, idHitPool, pHitPool, uvHitPool);

    // Combine the hit data for scene and flat pool surface
    int idHit = idHitScene;
    vec3 p = pHitScene;
    if (idHitPool != ID_NONE && (idHit == ID_NONE || distsq(pHitPool, camPos) < distsq(p, camPos))) {
        idHit = ID_POOL;
        p = pHitPool;
    }
    // ----------------------------------------------------------

    vec3 c = vec3(0.0);
    if (idHit == ID_NONE) {
        c = skybox(nvCamDir);
    } else if (idHit == ID_GEOMETRY) {
        c = texGeometry(camPos, lightPos, p);
    } else if (idHit == ID_POOL) {
        vec3 pBump;
        float didHit;

        vec3 cConst;

        vec3 nvRefl;
        float coeffRefl;

        vec3 nvRefract;
        float coeffRefract;

        texPool(
            camPos, lightPos, p,
            pBump, didHit,
            cConst, nvRefl, coeffRefl, nvRefract, coeffRefract
        );

        // Total miss (e.g. ray hitting surface near edge, with water low)
        if (didHit < 0.5) {

            if (idHitScene == ID_GEOMETRY) {
                c = texGeometry(camPos, lightPos, pHitScene);
            }

        // Did actually hit the surface; blend refraction and reflection colors
        } else {
            // Refraction (just do geometry)
            int idHit1;
            vec3 p1;
            hitScene(pBump, nvRefract, idHit1, p1);
            vec3 cRefract = vec3(0.0);
            if (idHit1 == ID_GEOMETRY) {
                float volumetricAmount = clamp(unmix(0.0, VOLUMETRIC_MAX_DIST, distance(pBump, p1)), 0.0, 1.0);
                cRefract = mix(
                    texGeometryUnderwater(camPos, lightPos, p1),
                    LIQUID_COLOR*LIGHT_COLOR,
                    volumetricAmount
                );
            }

            // Reflection (just do skybox)
            vec3 cRefl = skybox(nvRefl);
            c = clamp(cConst + coeffRefract*cRefract + coeffRefl*cRefl, 0.0, 1.0);
        }
    }

    // Mouse input
    //---------------------------------------
    if (fragCoord.x < 1.0 && fragCoord.y < 1.0) {
        vec2 packMouse = packUVWithBool(vec2(0.5), false);
        if (iMouse.z > 0.0) {
            vec3 camPosMouse;
            vec3 nvCamDirMouse;
            sceneCamera(iResolution, iMouse.xy, iTime, camPosMouse, nvCamDirMouse);

            hitPool(camPosMouse, nvCamDirMouse, idHitPool, pHitPool, uvHitPool);
            packMouse = packUVWithBool(clamp(uvHitPool, 0.0, 1.0), true);

        }
        c.rg = packMouse;
    }
    //---------------------------------------

    vec3 focusPoint = POOL_SURFACE_CENTER;
    float distFromFocus = distance(camPos, focusPoint);
    float distFromFrag = distance(camPos, p);
    float blurAmount = clamp(1.0*abs(distFromFocus-distFromFrag), 0.0, 1.0);

    fragColor = vec4(c, blurAmount);
}

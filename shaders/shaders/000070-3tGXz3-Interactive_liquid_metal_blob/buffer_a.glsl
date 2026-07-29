// Buffer A (buffer) — Interactive liquid metal blob by tmst
// https://www.shadertoy.com/view/3tGXz3

#define FIXED_UP vec3(0.0, 1.0, 0.0)
#define TAN_HALF_FOVY 0.5773502691896257
#define CAM_Z_NEAR 0.1
#define CAM_Z_FAR 50.0

#define BOX_MIN vec3(-1.0)
#define BOX_MAX vec3(1.0)
#define EPS 0.0001

// ================
// Generic helpers
// ================

float unmix(float a, float b, float x) {
    return (x - a)/(b - a);
}

mat4 getClipToWorld(float aspectWoverH, vec3 nvCamFw) {
    mat4 clipToEye = mat4(
        aspectWoverH * TAN_HALF_FOVY, 0.0, 0.0, 0.0,
        0.0, TAN_HALF_FOVY, 0.0, 0.0,
        0.0, 0.0,  0.0, (CAM_Z_NEAR - CAM_Z_FAR)/(2.0 * CAM_Z_NEAR * CAM_Z_FAR),
        0.0, 0.0, -1.0, (CAM_Z_NEAR + CAM_Z_FAR)/(2.0 * CAM_Z_NEAR * CAM_Z_FAR)
    );

    vec3 nvCamRt = normalize(cross(nvCamFw, FIXED_UP));
    vec3 nvCamUp = cross(nvCamRt, nvCamFw);
    mat4 eyeToWorld = mat4(
         nvCamRt, 0.0,
         nvCamUp, 0.0,
        -nvCamFw, 0.0,
        0.0, 0.0, 0.0, 1.0
    );

    return eyeToWorld * clipToEye;
}

void materialShader(
    in float diffuseCoefficient,
    in float specularCoefficient,
    in float specularExponent,
    in vec3 lightColor,
    in vec3 texColor,
    in vec3 nvNormal,
    in vec3 nvFragToLight,
    in vec3 nvFragToCam,
    out vec3 diffuse,
    out vec3 specular
) {
    float intensityDiffuse = clamp(dot(nvNormal, nvFragToLight), 0.0, 1.0);
    intensityDiffuse *= diffuseCoefficient;

    vec3 blinnH = normalize(nvFragToLight + nvFragToCam);
    float intensitySpecular = pow(clamp(dot(nvNormal, blinnH), 0.0, 1.0), specularExponent);
    intensitySpecular *= specularCoefficient;

    diffuse = intensityDiffuse * texColor * lightColor;
    specular = intensitySpecular * lightColor;
}

vec3 colormapInferno(float t) {
    return vec3(
        1.0 - (t - 1.0)*(t - 1.0),
        t*t,
        t * (3.0*t - 2.0)*(3.0*t - 2.0)
    );
}

vec3 skybox(vec3 nvDir) {
    return texture(iChannel1, nvDir).rgb;
}

// ========================
// Marching through voxels
// ========================

void boxClip(
    in vec3 boxMin, in vec3 boxMax,
    in vec3 p, in vec3 v,
    out vec2 tRange, out float didHit
){
    //for each coord, clip tRange to only contain t-values for which p+t*v is in range
    vec3 tb0 = (boxMin - p) / v;
    vec3 tb1 = (boxMax - p) / v;
    vec3 tmin = min(tb0, tb1);
    vec3 tmax = max(tb0, tb1);

    //t must be > tRange.s and each tmin, so > max of these; similar for t1
    tRange = vec2(
        max(max(tmin.x, tmin.y), tmin.z),
        min(min(tmax.x, tmax.y), tmax.z)
    );

    //determine whether ray intersects the box
    didHit = step(tRange.s, tRange.t);
}

vec3 lmnFromWorldPos(vec3 p) {
    vec3 uvw = (p - BOX_MIN) / (BOX_MAX - BOX_MIN);
    return floor(uvw * vec3(BOX_N));
}

void readLMN(in vec3 lmn, out vec2 st, out vec3 n) {
    st = texture(iChannel0, vcubeFromLMN(2, lmn)).st;
    n = 2.0 * (texture(iChannel0, vcubeFromLMN(3, lmn)).xyz - 0.5);
}

void boxFromLMN(in vec3 lmn, out vec3 boxMin, out vec3 boxMax) {
    vec3 boxSize = (BOX_MAX - BOX_MIN) / BOX_N;

    boxMin = BOX_MIN + (floor(lmn)/BOX_N) * (BOX_MAX - BOX_MIN);
    boxMax = boxMin + boxSize;
}

// Interpolate normal, density, and temperature in voxel volume
void hitVoxel(
    in vec3 lmn,
    in vec3 pVoxelIn, in vec3 pVoxelOut, in vec3 voxelBoxMin, in vec3 voxelBoxMax,
    out vec3 pHit, out vec3 nvHit, out vec2 stHit, out bool didHit
) {
    vec3  n000,  n001,  n010,  n011,  n100,  n101,  n110,  n111;
    vec2 st000, st001, st010, st011, st100, st101, st110, st111;

    readLMN(lmn, st000, n000);
    readLMN(lmn + vec3(0.0, 0.0, 1.0), st001, n001);
    readLMN(lmn + vec3(0.0, 1.0, 0.0), st010, n010);
    readLMN(lmn + vec3(0.0, 1.0, 1.0), st011, n011);
    readLMN(lmn + vec3(1.0, 0.0, 0.0), st100, n100);
    readLMN(lmn + vec3(1.0, 0.0, 1.0), st101, n101);
    readLMN(lmn + vec3(1.0, 1.0, 0.0), st110, n110);
    readLMN(lmn + vec3(1.0, 1.0, 1.0), st111, n111);

    vec3 nc000 = n000;
    vec3 nc001 = n001 - n000;
    vec3 nc010 = n010 - n000;
    vec3 nc100 = n100 - n000;
    vec3 nc011 = n011 - n001 - n010 + n000;
    vec3 nc101 = n101 - n001 - n100 + n000;
    vec3 nc110 = n110 - n010 - n100 + n000;
    vec3 nc111 = n111 - n011 - n101 - n110 + n001 + n010 + n100 - n000;

    vec2 stc000 = st000;
    vec2 stc001 = st001 - st000;
    vec2 stc010 = st010 - st000;
    vec2 stc100 = st100 - st000;
    vec2 stc011 = st011 - st001 - st010 + st000;
    vec2 stc101 = st101 - st001 - st100 + st000;
    vec2 stc110 = st110 - st010 - st100 + st000;
    vec2 stc111 = st111 - st011 - st101 - st110 + st001 + st010 + st100 - st000;

    vec3 tb0 = (pVoxelIn - voxelBoxMin) / (voxelBoxMax - voxelBoxMin);
    vec3 in0  =  nc000 + tb0.z* nc001 + tb0.y*( nc010 + tb0.z* nc011) + tb0.x*( nc100 + tb0.z* nc101 + tb0.y*( nc110 + tb0.z* nc111));
    vec2 ist0 = stc000 + tb0.z*stc001 + tb0.y*(stc010 + tb0.z*stc011) + tb0.x*(stc100 + tb0.z*stc101 + tb0.y*(stc110 + tb0.z*stc111));

    vec3 tb1 = (pVoxelOut - voxelBoxMin) / (voxelBoxMax - voxelBoxMin);
    vec3 in1  =  nc000 + tb1.z* nc001 + tb1.y*( nc010 + tb1.z* nc011) + tb1.x*( nc100 + tb1.z* nc101 + tb1.y*( nc110 + tb1.z* nc111));
    vec2 ist1 = stc000 + tb1.z*stc001 + tb1.y*(stc010 + tb1.z*stc011) + tb1.x*(stc100 + tb1.z*stc101 + tb1.y*(stc110 + tb1.z*stc111));

    float th = (DENSITY_THRESH - ist0.s) / (ist1.s - ist0.s);
    didHit = th > 0.0 && th < 1.0;
    pHit = mix(pVoxelIn, pVoxelOut, th);
    nvHit = normalize(mix(in0, in1, th));
    stHit = mix(ist0, ist1, th);
}

void march(in vec3 p, in vec3 nv, out vec4 color) {
    vec2 tRange;
    float didHitBox;
    boxClip(BOX_MIN, BOX_MAX, p, nv, tRange, didHitBox);

    color = vec4(0.0);
    if (didHitBox < 0.5) {
        return;
    }

    float t = tRange.s;
    for (int i=0; i<500; i++) {
        // Get voxel data
        vec3 worldPos = p + (t+EPS)*nv;
        vec3 lmn = lmnFromWorldPos(worldPos);

        vec3 curBoxMin, curBoxMax;
        boxFromLMN(lmn, curBoxMin, curBoxMax);

        vec2 curTRange;
        float curDidHit;
        boxClip(curBoxMin, curBoxMax, p, nv, curTRange, curDidHit);

        // Quick lookup to see if the surface intersects this voxel
        float isSolid = texture(iChannel0, vcubeFromLMN(2, lmn)).w;
        if (isSolid > 0.0) {
            // It does, so hit interpolated surface inside the voxel
            vec3 pVoxelIn  = p + curTRange.s * nv;
            vec3 pVoxelOut = p + curTRange.t * nv;

            vec3 pHit;
            vec3 nvHit;
            vec2 stHit;
            bool didHitSurf;
            hitVoxel(
                lmn,
                pVoxelIn, pVoxelOut, curBoxMin, curBoxMax,
                pHit, nvHit, stHit, didHitSurf
            );

            // Hit surface, so determine color and quit
            if (didHitSurf) {
                vec3 lightPos = p + vec3(0.0, 1.0, 0.0);
                vec3 nvFragToLight = normalize(lightPos - pHit);
                vec3 nvFragToCam = normalize(p - pHit);

                vec3 matColor = colormapInferno(stHit.t);
                vec3 lightColor = vec3(1.0);

                vec3 diffuse;
                vec3 specular;
                materialShader(
                    1.0-stHit.t, 1.0-stHit.t, 60.0,
                    lightColor, matColor, nvHit,
                    nvFragToLight,
                    nvFragToCam,
                    diffuse, specular
                );
                vec3 ambient = stHit.t * matColor;

                vec3 vRefl = reflect(-nvFragToCam, nvHit);
                vec3 cRefl = skybox(vRefl);

                vec3 colorFinal = mix(diffuse+ambient, cRefl, 0.75*(1.0-stHit.t)) + specular;

                color = vec4(clamp(colorFinal, 0.0, 1.0), 1.0);
                break;
            }
        }

        // Move up to next voxel
        t = curTRange.t;
        if (t+EPS > tRange.t) { break; }
    }
}

// =============
// Render scene
// =============

void sceneCamera(in vec2 fragCoord, out vec3 camPos, out vec3 nvCamDir) {
    vec2 uv = fragCoord / iResolution.xy;

    vec2 sphPos = vec2(0.1*iTime, 0.5*3.14159);
    camPos = 2.0 * (
        sin(sphPos.y) * vec3(cos(2.0*sphPos.x), 0.0, sin(2.0*sphPos.x)) +
        cos(sphPos.y) * vec3(0.0, 1.0, 0.0)
    );
    vec3 lookTarget = vec3(0.0);

    vec3 nvCamFw = normalize(lookTarget - camPos);
    mat4 clipToWorld = getClipToWorld(iResolution.x/iResolution.y, nvCamFw);

    vec4 vWorld = clipToWorld * vec4(uv*2.0 - 1.0, 1.0, 1.0);
    nvCamDir = normalize(vWorld.xyz / vWorld.w);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec3 camPos;
    vec3 nvCamDir;
    sceneCamera(fragCoord, camPos, nvCamDir);

    vec3 bgColor = skybox(nvCamDir);

    vec4 objColor;
    march(camPos, nvCamDir, objColor);
    vec3 finalColor = objColor.rgb + (1.0 - objColor.a)*bgColor;

    fragColor = vec4(finalColor, 1.0);

    // Mouse input
    // For load/store cf. https://www.shadertoy.com/view/MddGzf
    //---------------------------------------
    ivec2 ipx = ivec2(fragCoord - 0.5);

    bool storeEntry = ipx == ivec2(0,0);
    bool storeExit = ipx == ivec2(1,0);

    if (storeEntry || storeExit) {
        vec4 entry = vec4(0.0);
        vec4 exit = vec4(0.0);

        vec2 mouseXY;
        if (iMouse.z > 0.0) {
            mouseXY = iMouse.xy;
        } else {
            float radius = 0.25*min(iResolution.x,iResolution.y);
            mouseXY = 0.5*iResolution.xy + radius*vec2(cos(2.0*iTime), sin(2.0*iTime));
        }

        vec3 camPosMouse;
        vec3 nvCamDirMouse;
        sceneCamera(mouseXY, camPosMouse, nvCamDirMouse);

        vec2 tRange;
        float didHitBox;
        boxClip(BOX_MIN, BOX_MAX, camPosMouse, nvCamDirMouse, tRange, didHitBox);

        if (didHitBox > 0.5) {
            vec3 pEntry = camPosMouse + tRange.s*nvCamDirMouse;
            vec3 lmnEntry = lmnFromWorldPos(pEntry);
            entry = vec4(lmnEntry / BOX_N, 1.0);

            vec3 pExit = camPosMouse + tRange.t*nvCamDirMouse;
            vec3 lmnExit = lmnFromWorldPos(pExit);
            exit = vec4(lmnExit / BOX_N, 1.0);
        }

        if (storeEntry) {
            fragColor = entry;
        } else if (storeExit) {
            fragColor = exit;
        }
    }
    //---------------------------------------
}

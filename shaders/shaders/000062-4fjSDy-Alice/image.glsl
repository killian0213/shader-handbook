// Image (image) — Alice by SL0ANE
// https://www.shadertoy.com/view/4fjSDy

# define MAX_DISTANCE 1024.0
# define MIN_STEP 64
# define MAX_STEP 512
# define MIN_DIS_SHADOW 0.064
# define BACKGROUND_COLOR vec4(0.89, 0.4, 0.42, 1.0)
# define SLOANE_COLOR vec4(0.98, 0.52, 0.52, 1.0)

# define LIGHT_DIRECTION vec3(-1.0, -0.5, 2.0)
# define LIGHT_COLOR vec4(1.0, 0.98, 0.94, 1.0)
# define LIGHT_STRENGTH 1.0
# define AMBIENT_COLOR vec4(0.4, 0.3, 0.7, 1.0)

# define BLINK_THRESHOLD 0.16
# define FRAMERATE 12.0

# define SKIN_COLOR (vec4(251.0, 209.0, 192.0, 255.0) / 255.0)
// Pre
ObjectInfo sceneSolidMap(vec3 point, bool castShadow, bool withMat, out float outlineDis);
Material sceneBaseMaterial(vec3 point, float len);
vec4 atmosphereShading(vec4 backGroundColor, vec4 LightColor, vec4 ShadowColor, Material material, vec3 normal);
vec4 getColorAtPos(vec3 pos, vec3 ray, float len, vec2 screenCoord, float pixelSize, float dis, inout vec3 normal, bool outlineHit, float disWhenHit, float lenWhenHit);

// Camera Config
float cameraFov = 26.0f;

// Outline Config
float outlineStrength;
float outlineThreshold = 0.05;

// Bone

vec3 positionLocal_Camera = vec3(0.0, 0.0, 0.0);
vec4 rotationLocal_Camera = vec4(0.0, 0.0, 0.0, 1.0);
vec3 positionWorld_Camera;
vec4 rotationWorld_Camera;

vec3 positionLocal_Root = vec3(0.1, 0.48, 21.0);
vec4 rotationLocal_Root = vec4(0.0, 0.0, 0.0, 1.0);
vec3 positionWorld_Root;
vec4 rotationWorld_Root;

vec3 positionLocal_Pin = vec3(-0.25, 0.7, -0.75);
vec4 rotationLocal_Pin = vec4(-0.329, -0.259, -0.094, 0.903);
vec3 positionWorld_Pin;
vec4 rotationWorld_Pin;

vec3 positionLocal_Scarf = vec3(0.0, -1.6, 0.2);
vec4 rotationLocal_Scarf = vec4(0.105, 0.0, 0.0, 0.995);
vec3 positionWorld_Scarf;
vec4 rotationWorld_Scarf;

struct FacialInfo
{
    vec3 skinColor;
    vec3 skinShadeColor;
    vec3 blushColor;
    float blushFactor;
    
    vec3 eyeBallColor;
    vec3 eyeBallSecondColor;
    float eyeBallEmmision;
    float eyeBallSecondEmmision;
    
    vec3 lashColor;
    vec3 browColor;
    
    vec3 hairColor;
    vec3 hairHighlightColor;
    
    vec2 leftEyeBallPos;
    float leftEyeBallScale;
    vec2 rightEyeBallPos;
    float rightEyeBallScale;
    
    float leftUpLidPos;
    float leftDownLidPos;
    float rightUpLidPos;
    float rightDownLidPos;
    
    vec2 leftBrowStart;
    vec2 leftBrowEnd;
    vec2 leftBrowDir;
    vec2 rightBrowStart;
    vec2 rightBrowEnd;
    vec2 rightBrowDir;
    
    float lipBend;
    
};

FacialInfo defaultFacialInfo = FacialInfo(
    vec3(251.0, 209.0, 184.0) / 255.0,
    vec3(200.0, 140.0, 150.0) / 255.0,
    vec3(216.0, 102.0, 102.0) / 255.0,
    0.4,
    
    vec3(0.3, 0.2, 0.24),
    vec3(0.89, 0.2, 0.22),
    0.1,
    0.8,
    
    vec3(0.3, 0.2, 0.24),
    vec3(0.3, 0.2, 0.24),
    
    vec3(236.0, 79.0, 62.0) / 255.0,
    vec3(255.0, 223.0, 162.0) / 255.0,
    
    vec2(-0.25, -0.125),
    1.0,
    vec2(-0.4, -0.125),
    1.0,
    
    0.04,
    0.05,
    0.04,
    0.05,
    
    vec2(-1.0, -0.8),
    vec2(1.0, 0.2),
    vec2(-0.3, 0.5),
    vec2(1.0, -0.8),
    vec2(-1.0, 0.2),
    vec2(0.3, 0.5),
    
    // vec2(-1.0, -0.8),
    // vec2(1.0, 0.2),
    // vec2(-0.3, 0.5),
    // vec2(1.0, -0.8),
    // vec2(-1.0, 0.2),
    // vec2(0.3, 0.5),
    
    0.5
);

// Util
vec3 getSolidNormal(vec3 point, float pixelSize)
{
    vec3 deltaX = vec3(pixelSize, 0.0, 0.0) / 4.0;
    vec3 deltaY = vec3(0.0, pixelSize, 0.0) / 4.0;
    vec3 deltaZ = vec3(0.0, 0.0, pixelSize) / 4.0;
    
    float outlineDis;
    
    float x = sceneSolidMap(point + deltaX, false, false, outlineDis).dis - sceneSolidMap(point - deltaX, false, false, outlineDis).dis;
    float y = sceneSolidMap(point + deltaY, false, false, outlineDis).dis - sceneSolidMap(point - deltaY, false, false, outlineDis).dis;
    float z = sceneSolidMap(point + deltaZ, false, false, outlineDis).dis - sceneSolidMap(point - deltaZ, false, false, outlineDis).dis;
    
    return normalize(vec3(x, y, z));
}

vec3 getRoughSolidNormal(vec3 point, float curDis, float pixelSize)
{
    vec3 deltaX = vec3(pixelSize, 0.0, 0.0) / 4.0;
    vec3 deltaY = vec3(0.0, pixelSize, 0.0) / 4.0;
    vec3 deltaZ = vec3(0.0, 0.0, pixelSize) / 4.0;
    
    float outlineDis;
    
    float x = sceneSolidMap(point + deltaX, false, false, outlineDis).dis - curDis;
    float y = sceneSolidMap(point + deltaY, false, false, outlineDis).dis - curDis;
    float z = sceneSolidMap(point + deltaZ, false, false, outlineDis).dis - curDis;
    
    return normalize(vec3(x, y, z));
}

float softshadow(vec3 ro, vec3 rd, float mint, float maxt, float k)
{
    float res = 1.0;
    float t = mint;
    float outlineDis;
    
    while(t < maxt)
    {
        float h = sceneSolidMap(ro + rd * t, true, false, outlineDis).dis;
        if(h < TOLERANCE)
            return 0.0;
        res = min(res, k * h/t);
        t += h;
    }
    return res;
}
// Object

ObjectInfo animeHead(vec3 p, vec3 sdf_pos, vec4 sdf_rot, float sdf_scale, FacialInfo facialInfo, bool castShadow, bool withMat, out float outlineDis)
{
    ObjectInfo info = ObjectInfo(0.0,
                      Material(
                      vec4(facialInfo.skinColor, 1.0),
                      vec4(facialInfo.skinShadeColor, 1.0),
                      vec4(0.0),
                      vec3(0.0),
                      vec3(0.0),
                      vec3(0.0),
                      0.0, 4.0, 0.2, 0.0, 0.0, 2));
    
    vec3 transPoint = (p - sdf_pos) / sdf_scale;
    transPoint = rotatePoint(transPoint, vec3(0), quaternionInverse(sdf_rot));
    
    float baseSd =  ssub(
                    smin(
                    smin(
                    // 鼻子
                    ssub(
                    ssub(
                         sdEllipsoid(transPoint, vec3(0.0, -0.05, -0.16), vec3(0.02, 0.08, 0.07)),
                         sdEllipsoid(transPoint, vec3(-0.08, 0.12, -0.22), vec3(0.11, 0.32, 0.1)),
                    0.008),
                         sdEllipsoid(transPoint, vec3(0.08, 0.12, -0.22), vec3(0.11, 0.32, 0.1)),
                    0.008),
                    // 鼻子
    
                    // 大致的轮廓
                    ssub(
                    smin(sdEllipsoid(transPoint, vec3(0.0, 0.04, -0.025), vec3(0.16, 0.16,0.18)), // 额头
                         sdRoundCone(transPoint, vec3(0.0, -0.075, -0.05), vec3(0.0, -0.18, -0.12), 0.12, 0.02), // 下颚 
                    0.04),
                         sdSphere(transPoint, vec3(0.0, -0.7, 0.18), 0.56), // 下颚切除
                    0.02),
                    0.02),
                    smin(
                        sdEllipsoid(transPoint, vec3(0.04, -0.07, -0.09), vec3(0.04, 0.04, 0.03)), // 脸颊
                        sdEllipsoid(transPoint, vec3(-0.04, -0.07, -0.09), vec3(0.04, 0.04, 0.03)), // 脸颊
                    0.001),
                    0.09),
                    // 大致的轮廓
                   
                    // 眼眶
                    smin(
                        sdEllipsoid(transPoint, vec3(0.11, -0.03, -0.2), vec3(0.03, 0.02, 0.02)), // 脸颊
                        sdEllipsoid(transPoint, vec3(-0.11, -0.03, -0.2), vec3(0.03, 0.02, 0.02)),
                    0.02),
                    0.12);
    
    // 眼白
    float iBackLeftSd = smin(
                         sdEllipsoid(transPoint, vec3(0.08, -0.022, -0.13), vec3(0.032, 0.03, 0.06)),
                         sdEllipsoid(transPoint, vec3(0.07, -0.042, -0.13), vec3(0.028, 0.04, 0.06)),
                        0.07);
    float iBackRightSd = smin(
                         sdEllipsoid(transPoint, vec3(-0.08, -0.022, -0.13), vec3(0.032, 0.03, 0.06)),
                         sdEllipsoid(transPoint, vec3(-0.07, -0.042, -0.13), vec3(0.028, 0.04, 0.06)),
                        0.07);
    float iBackSd = min(iBackLeftSd, iBackRightSd);
    
   
    // 眼珠
    vec3 iCursor = vec3(0.00, -0.02, -0.03);
    vec3 iBallCenter = vec3(0.07, -0.036, -0.135) + vec3(facialInfo.leftEyeBallPos, 0.0) * 0.03;
    vec3 iBallZ = normalize(iBallCenter - iCursor);
    vec3 iBallX = normalize(cross(iBallZ, vec3(0.0, 1.0, 0.0)));
    vec3 iBallY = -normalize(cross(iBallZ, iBallX));
    vec3 iBallHighlightCenter = iBallCenter + applyTransform(vec3(0.022, -0.015, 0.002), iBallX, iBallY, iBallZ) * facialInfo.leftEyeBallScale;
    
    vec3 iBallTransLeftPoint = transPoint - iBallCenter;
    iBallTransLeftPoint = applyTransform(iBallTransLeftPoint, iBallX, iBallY, iBallZ);
    
    float iBallLeftSd = sdEllipsoid(iBallTransLeftPoint, vec3(0.0), vec3(0.036 * facialInfo.leftEyeBallScale, 0.04 * facialInfo.leftEyeBallScale, 0.005));
    
    
    vec3 iBallHighlightLeftTransPoint = transPoint - iBallHighlightCenter;
    iBallHighlightLeftTransPoint = applyTransform(iBallHighlightLeftTransPoint, iBallX, iBallY, iBallZ);
    
    float iBallHighlightSd = sdEllipsoid(iBallHighlightLeftTransPoint, vec3(0.0), vec3(0.015 * facialInfo.leftEyeBallScale, 0.007 * facialInfo.leftEyeBallScale, 0.0025));
    
    
    iBallCenter = vec3(-0.07, -0.036, -0.135) + vec3(facialInfo.rightEyeBallPos, 0.0) * 0.03;
    iBallZ = normalize(iBallCenter - iCursor);
    iBallX = normalize(cross(iBallZ, vec3(0.0, 1.0, 0.0)));
    iBallY = -normalize(cross(iBallZ, iBallX));
    iBallHighlightCenter = iBallCenter + applyTransform(vec3(0.022, -0.015, 0.002), iBallX, iBallY, iBallZ) * facialInfo.rightEyeBallScale;
    
    vec3 iBallTransRightPoint = transPoint - iBallCenter;
    iBallTransRightPoint = applyTransform(iBallTransRightPoint, iBallX, iBallY, iBallZ);
    
    float iBallRightSd = sdEllipsoid(iBallTransRightPoint, vec3(0.0), vec3(0.036 * facialInfo.rightEyeBallScale, 0.04 * facialInfo.rightEyeBallScale, 0.005));
    float iBallSd = min(iBallLeftSd, iBallRightSd);
    
    
    vec3 iBallHighlightRightTransPoint = transPoint - iBallHighlightCenter;
    iBallHighlightRightTransPoint = applyTransform(iBallHighlightRightTransPoint, iBallX, iBallY, iBallZ);
    
    iBallHighlightSd = min(iBallHighlightSd, sdEllipsoid(iBallHighlightRightTransPoint, vec3(0.0), vec3(0.015 * facialInfo.rightEyeBallScale, 0.007 * facialInfo.rightEyeBallScale, 0.0025)));
    
    // 眼皮
    float iLidSd;
    
    iCursor = vec3(0.00, -0.0, -0.04);
    vec3 iLidCenter = vec3(0.068, -0.0, -0.126);
    iBallZ = normalize(iLidCenter - iCursor);
    iBallX = normalize(cross(iBallZ, vec3(0.0, 1.0, 0.0)));
    iBallY = -normalize(cross(iBallZ, iBallX));
    
    vec3 iLidTrasPoint = transPoint - iLidCenter;
    iLidTrasPoint = applyTransform(iLidTrasPoint, iBallX, iBallY, iBallZ);
    
    float iLidBaseSd = sdEllipsoid(iLidTrasPoint, vec3(0.0), vec3(0.062, 0.1, 0.029));
    iLidBaseSd = onion(iLidBaseSd, 0.005);
    iLidBaseSd = sub(iLidBaseSd, sdBox(iLidTrasPoint, vec3(0.0, 0.5, 0.11), vec3(0.8, 0.8, 0.02)));
    float iLidLeftUpSd = ssub(iLidBaseSd, sdSphere(transPoint, vec3(0.068, mix(-0.15, -0.185, facialInfo.leftUpLidPos), -0.126), mix(0.17, 0.14, facialInfo.leftUpLidPos)), 0.005);
    float iLidLeftDownSd = sint(sdSphere(transPoint, vec3(0.068, mix(-0.32, -0.185, facialInfo.leftDownLidPos), -0.126), mix(0.23, 0.14, facialInfo.leftDownLidPos)), iLidBaseSd, 0.005);
    
    iLidSd = min(iLidLeftUpSd, iLidLeftDownSd);
    
    iLidCenter.x = -iLidCenter.x;
    iBallZ = normalize(iLidCenter - iCursor);
    iBallX = normalize(cross(iBallZ, vec3(0.0, 1.0, 0.0)));
    iBallY = -normalize(cross(iBallZ, iBallX));
    
    iLidTrasPoint = transPoint - iLidCenter;
    iLidTrasPoint = applyTransform(iLidTrasPoint, iBallX, iBallY, iBallZ);
    
    iLidBaseSd = sdEllipsoid(iLidTrasPoint, vec3(0.0), vec3(0.062, 0.1, 0.029));
    iLidBaseSd = onion(iLidBaseSd, 0.005);
    iLidBaseSd = sub(iLidBaseSd, sdBox(iLidTrasPoint, vec3(0.0, 0.5, -0.11), vec3(0.8, 0.8, 0.11)));
    float iLidRightUpSd = ssub(iLidBaseSd, sdSphere(transPoint, vec3(-0.068, mix(-0.15, -0.185, facialInfo.rightUpLidPos), -0.126), mix(0.17, 0.14, facialInfo.rightUpLidPos)), 0.005);
    float iLidRightDownSd = sint(sdSphere(transPoint, vec3(-0.068, mix(-0.32, -0.185, facialInfo.rightDownLidPos), -0.126), mix(0.23, 0.14, facialInfo.rightDownLidPos)), iLidBaseSd, 0.005);
    
    iLidSd = min(iLidSd, min(iLidRightUpSd, iLidRightDownSd));
    
    // 睫毛
    float iLashSd;
    
    float tempFactor = 4.3;
    float tempCos = cos(tempFactor * transPoint.x);
    float tempSin = sin(tempFactor * transPoint.x);
    mat2  tempMat = mat2(tempCos, -tempSin, tempSin ,tempCos);
    vec3  iLashTransPoint = transPoint - vec3(0.0, 0.0, -0.185 - 0.01 * facialInfo.leftUpLidPos * (0.7 - facialInfo.leftUpLidPos));
    iLashTransPoint.xz = tempMat * iLashTransPoint.xz;
    
    float iLashLeftUpSd = sub(sdCircle(iLashTransPoint.xy,
                                 facialInfo.leftUpLidPos <= 0.5 ?
                                 mix(vec2(0.09, -0.032), vec2(0.09, -0.11), facialInfo.leftUpLidPos * 2.0):
                                 mix(vec2(0.09, -0.11), vec2(0.09, -0.145), facialInfo.leftUpLidPos * 2.0 - 1.0),
                                 facialInfo.leftUpLidPos <= 0.5 ?
                                 mix(0.052, 0.103, facialInfo.leftUpLidPos * 2.0):
                                 mix(0.103, 0.103, facialInfo.leftUpLidPos * 2.0 - 1.0)
                                 ),
                               sdCircle(iLashTransPoint.xy,
                                 facialInfo.leftUpLidPos <= 0.5 ?
                                 mix(vec2(0.085, -0.05), vec2(0.092, -0.318), facialInfo.leftUpLidPos * 2.0):
                                 mix(vec2(0.092, -0.318), vec2(0.09, -0.34), facialInfo.leftUpLidPos * 2.0 - 1.0),
                                 facialInfo.leftUpLidPos <= 0.5 ?
                                 mix(0.06, 0.3, facialInfo.leftUpLidPos * 2.0):
                                 mix(0.3, 0.29, facialInfo.leftUpLidPos * 2.0 - 1.0)
                                 ));
    tempFactor = 0.006;
    vec2 tempFlat = vec2(iLashLeftUpSd, abs(iLashTransPoint.z) - tempFactor);
    iLashLeftUpSd = min(max(tempFlat.x,tempFlat.y),0.0) + length(max(tempFlat, 0.0));
    
    
    iLashTransPoint = transPoint - vec3(0.0, 0.0, -0.185 - 0.01 * facialInfo.rightUpLidPos * (0.7 - facialInfo.rightUpLidPos));
    iLashTransPoint.xz = tempMat * iLashTransPoint.xz;
    
    float iLashRightUpSd = sub(sdCircle(iLashTransPoint.xy,
                                 facialInfo.rightUpLidPos <= 0.5 ?
                                 mix(vec2(-0.09, -0.032), vec2(-0.09, -0.11), facialInfo.rightUpLidPos * 2.0):
                                 mix(vec2(-0.09, -0.11), vec2(-0.09, -0.145), facialInfo.rightUpLidPos * 2.0 - 1.0),
                                 facialInfo.rightUpLidPos <= 0.5 ?
                                 mix(0.052, 0.103, facialInfo.rightUpLidPos * 2.0):
                                 mix(0.103, 0.103, facialInfo.rightUpLidPos * 2.0 - 1.0)
                                 ),
                               sdCircle(iLashTransPoint.xy,
                                 facialInfo.rightUpLidPos <= 0.5 ?
                                 mix(vec2(-0.085, -0.05), vec2(-0.092, -0.318), facialInfo.rightUpLidPos * 2.0):
                                 mix(vec2(-0.092, -0.318), vec2(-0.09, -0.34), facialInfo.rightUpLidPos * 2.0 - 1.0),
                                 facialInfo.rightUpLidPos <= 0.5 ?
                                 mix(0.06, 0.3, facialInfo.rightUpLidPos * 2.0):
                                 mix(0.3, 0.29, facialInfo.rightUpLidPos * 2.0 - 1.0)
                                 ));
    
    tempFactor = 0.006;
    tempFlat = vec2(iLashRightUpSd, abs(iLashTransPoint.z) - tempFactor);
    iLashRightUpSd = min(max(tempFlat.x,tempFlat.y),0.0) + length(max(tempFlat, 0.0));
    
    iLashSd = min(iLashRightUpSd, iLashLeftUpSd);
    if(castShadow) iLashSd = 65535.0;
    
    // 嘴巴
    float mouthSd;
    
    tempFactor = 8.0;
    tempCos = cos(tempFactor * transPoint.x);
    tempSin = sin(tempFactor * transPoint.x);
    tempMat = mat2(tempCos, -tempSin, tempSin ,tempCos);
    vec3  mouthTransPoint = transPoint - vec3(0.0, -0.16, -0.145);
    mouthTransPoint.xz = tempMat * mouthTransPoint.xz;
    
    tempFactor = 14.0 + (facialInfo.lipBend > 0.0 ? 22.0 : 11.0) * facialInfo.lipBend;
    tempCos = cos(tempFactor * transPoint.x);
    tempSin = sin(tempFactor * transPoint.x);
    tempMat = mat2(tempCos, -tempSin, tempSin ,tempCos);
    mouthTransPoint.xy = tempMat * mouthTransPoint.xy;
    
    mouthSd = sdVesicaSegment(mouthTransPoint, vec3(0.07, 0.0, 0.0), vec3(-0.07, 0.0, 0.0), 0.006);
    
    // 头发
    float hairCutout = sint(sdEllipsoid(transPoint, vec3(0.0, -0.15, -0.25), vec3(0.24, 0.28, 0.2)),
                           sdEllipsoid(transPoint, vec3(-0.15, -0.36, -0.35), vec3(0.5, 0.5, 0.6)), 0.005);
    float hairBaseSd = sint(
                       sub(
                       sint(sdEllipsoid(transPoint, vec3(0.0, 0.0, 0.03), vec3(0.2, 0.23, 0.28)),
                           sdEllipsoid(transPoint, vec3(0.0, 0.14, 0.11), vec3(0.32, 0.4, 0.32)), 0.05),
                       hairCutout),
                       sdEllipsoid(transPoint, vec3(0.0, 0.03, -0.1), vec3(0.3, 0.24, 0.3)), 0.05);
                       
    vec3 hairBaseMap = normalize(transPoint - vec3(0.0, 0.0, -0.1));
    vec2 hairBaseUV = vec2(atan(hairBaseMap.z, hairBaseMap.x) / (PI * 2.0) + 0.5,
                           atan(hairBaseMap.y, sqrt(hairBaseMap.x * hairBaseMap.x + hairBaseMap.z * hairBaseMap.z)) / PI + 0.5);
                           
    float hairBaseBias = voronoiAndHide(hairBaseUV, vec2(32.0, 1.0), vec2(1.0, 65535.0), vec2(4.0), vec2(0.0), vec2(0.5, 0.5), 0.4)
                         * smoothstep(0.9, 0.5, hairBaseUV.y) * smoothstep(0.3, 0.2, abs(fract(hairBaseUV.x - 0.25) - 0.5));
    hairBaseSd -= 0.005 * smoothstep(0.0, 0.4, hairBaseBias);
    
    tempFactor = 0.5;
    tempCos = cos(tempFactor * transPoint.x);
    tempSin = sin(tempFactor * transPoint.x);
    tempMat = mat2(tempCos, -tempSin, tempSin ,tempCos);
    vec3  hairHornTransPoint = transPoint - vec3(0.0, 0.0, 0.0);
    hairHornTransPoint.xy = tempMat * hairHornTransPoint.xy;
    float hairLeftHorn = sdRoundCone(hairHornTransPoint, vec3(-0.08, -0.12, -0.02), vec3(-0.32, -0.06, 0.06), 0.054, 0.001);
    float hairRightHorn = sdRoundCone(hairHornTransPoint, vec3(0.08, -0.12, -0.02), vec3(0.32, -0.06, 0.06), 0.054, 0.001);
    
    tempFactor = 0.5;
    tempCos = cos(tempFactor * transPoint.z);
    tempSin = sin(tempFactor * transPoint.z);
    tempMat = mat2(tempCos, -tempSin, tempSin ,tempCos);
    hairHornTransPoint = transPoint - vec3(0.0, 0.0, 0.0);
    hairHornTransPoint.zy = tempMat * hairHornTransPoint.zy;
    float hairBackHorn = sdRoundCone(hairHornTransPoint, vec3(0.0, -0.12, 0.05), vec3(0.0, -0.06, 0.3), 0.054, 0.001);
                           
    float hairSd = smin(hairBaseSd, min(min(hairLeftHorn, hairRightHorn), hairBackHorn), 0.003);
    
    // info.dis = baseSd;         
    info.dis = ssub(baseSd, iBackSd, 0.003);
    info.dis = smin(info.dis, mouthSd, 0.005);
    info.dis = smin(info.dis, iLidSd, 0.0005);
    float skinSd = info.dis;
    info.dis = min(info.dis, hairSd);
    outlineDis = info.dis;
    info.dis = min(info.dis, min(iBallSd, iBallHighlightSd));
    info.dis = min(info.dis, iLashSd);
    
    // info.dis = hairSd;
    
    
    // 部分部位屏蔽描边
    if(iBackSd <= 0.02) outlineDis = 65535.0;
   
    
    vec3 cenVector = normalize(transPoint);
    float offset = iTime * 1.0;
    
    if(withMat)
    {   
        // Based on shape
        if(info.dis == iBallSd)
        {
            vec2 uv;
            if(iBallLeftSd < iBallRightSd)
            {
                uv = iBallTransLeftPoint.xy / (vec2(0.036, 0.04) * facialInfo.leftEyeBallScale);
                info.material.vect0 = normalize(vec3(0.3, 0.0, -1.0));
            }
            else
            {
                uv = iBallTransRightPoint.xy / (vec2(0.036, 0.04) * facialInfo.rightEyeBallScale);
                info.material.vect0 = normalize(vec3(-0.3, 0.0, -1.0));
            }
            
            info.material.vect1 = vec3(1.0, 0.0, 0.0);
            info.material.vect2 = vec3(0.0, -1.0, 0.0);
            
            info.material.vect0 = rotatePoint(info.material.vect0, vec3(0), sdf_rot);
            info.material.vect1 = rotatePoint(info.material.vect1, vec3(0), sdf_rot);
            info.material.vect2 = rotatePoint(info.material.vect2, vec3(0), sdf_rot);
            
            info.material.color0 = vec4(facialInfo.eyeBallColor, facialInfo.eyeBallEmmision);
            info.material.color1 = vec4(facialInfo.eyeBallSecondColor, facialInfo.eyeBallSecondEmmision);
            info.material.color2 = vec4(uv, 0.6, 0.4);
            
            info.material.index = 4;
        }
        else if(info.dis == iLashSd)
        {
            info.material.color0 = vec4(facialInfo.lashColor, 1.0);
            info.material.vect0 = normalize(transPoint - vec3(0.09, 0.0, 0.0));
            
            info.material.vect0 = rotatePoint(info.material.vect0, vec3(0), sdf_rot);
            info.material.index = 5;
        }
        else if(info.dis == iBallHighlightSd)
        {
            info.material.color0 = vec4(1.0, 1.0, 1.0, 1.0);
            info.material.index = 0;
        }
        else if(iBackSd < 0.0 && baseSd < 0.0)
        {
            info.material.color0 = vec4(0.96, 1.0, 0.99, 1.0);
            info.material.color1 = vec4(0.87, 0.8, 0.85, 1.0);
            // 覆写法线
            if(iBackLeftSd < iBackRightSd)
            {
                info.material.vect0 = normalize(vec3(0.3, 0.0, -1.0));
            }
            else
            {
                info.material.vect0 = normalize(vec3(-0.3, 0.0, -1.0));
            }
            
            info.material.vect1 = vec3(0.0, 1.0, 0.0);
            info.material.t0 = dot(vec3(0.0, 1.0, 0.0), normalize(vec3(0.00, -0.02, -0.006) - vec3(0.0, transPoint.y, 0.0))) / 2.0 + 0.5;
            info.material.t1 = 0.75; // 自发光
            
            info.material.vect0 = rotatePoint(info.material.vect0, vec3(0), sdf_rot);
            info.material.vect1 = rotatePoint(info.material.vect1, vec3(0), sdf_rot);
            info.material.index = 3;
        }
        else if(info.dis == hairSd)
        {
            info.material.color0 = vec4(facialInfo.hairColor, 1.0);
            info.material.index = 6;
            
            if(abs(info.dis - hairBaseSd) <= 0.005 && abs(info.dis - hairCutout) > 0.005)
            {
                info.material.t3 = hairBaseUV.y;
                info.material.t4 = hairBaseUV.x;
                info.material.color1 = vec4(facialInfo.hairHighlightColor, 1.0);
                info.material.color2 = vec4(0.5, 0.8, 0.05, 0.1);
                info.material.vect0 = vec3(0.0, 1.0, 0.0);
                
                info.material.vect0 = rotatePoint(info.material.vect0, vec3(0), sdf_rot);
            }
            else info.material.t3 = -1.0;
        }
        
        else
        {
            // Unrelated to shapes
            
            
            // 嘴巴勾线
            if(mouthTransPoint.z < 0.0 && mouthTransPoint.x < 0.032 && mouthTransPoint.x > -0.032 && info.dis == skinSd)
            {
                float mouthline = mouthTransPoint.y + 16.0 * mouthTransPoint.x * mouthTransPoint.x - 0.007;
                float mouthlineThick = 0.006 * clamp(abs(mouthTransPoint.x) / 0.028 - 0.02, 0.0, 1.0);
                if(mouthline < mouthlineThick && mouthline > 0.00)
                {
                    info.material.color0 = mix(vec4(0.3, 0.2, 0.24, 1.0), info.material.color0, smoothstep(0.002, 0.0, min(mouthlineThick - mouthline, mouthline)));
                }
            }
            
            
            if(transPoint.z < 0.0 && info.dis == skinSd)
            {
                // 眉毛
                float sdBrow;
                tempFactor = 3.0;
                tempCos = cos(tempFactor * transPoint.x);
                tempSin = sin(tempFactor * transPoint.x);
                tempMat = mat2(tempCos, -tempSin, tempSin ,tempCos);
                vec3  browTransPoint = transPoint;
                browTransPoint.xz = tempMat * browTransPoint.xz;
            
                vec2 leftBrowCenter = vec2(0.042, 0.045) - vec2(0.0, 1.0) * 0.01 * facialInfo.leftUpLidPos;
                vec2 leftBrowStart = facialInfo.leftBrowStart * 0.027 + leftBrowCenter;
                vec2 leftBrowEnd = facialInfo.leftBrowEnd * 0.027 + leftBrowCenter;
                vec2 leftBrowDir = facialInfo.leftBrowDir * 0.027 + leftBrowCenter;
                float leftBrowPos = (browTransPoint.x - leftBrowStart.x) / (leftBrowEnd.x - leftBrowStart.x);
                float leftBrowDis = sdBezier(browTransPoint.xy, leftBrowStart, leftBrowDir, leftBrowEnd);
                float leftBrowThick = 0.004 * 4.0 * leftBrowPos * (1.0 - leftBrowPos) * (1.0 - leftBrowPos);
                
                if(leftBrowDis < leftBrowThick && leftBrowPos > 0.0 && leftBrowPos <= 1.0)
                    info.material.color0 = mix(vec4(facialInfo.browColor, 1.0), info.material.color0, smoothstep(leftBrowThick - 0.0015, leftBrowThick, leftBrowDis));
                
                
                vec2 rightBrowCenter = vec2(-0.042, 0.045) - vec2(0.0, 1.0) * 0.01 * facialInfo.rightUpLidPos;
                vec2 rightBrowStart = facialInfo.rightBrowStart * 0.027 + rightBrowCenter;
                vec2 rightBrowEnd = facialInfo.rightBrowEnd * 0.027 + rightBrowCenter;
                vec2 rightBrowDir = facialInfo.rightBrowDir * 0.027 + rightBrowCenter;
                float rightBrowPos = (browTransPoint.x - rightBrowStart.x) / (rightBrowEnd.x - rightBrowStart.x);
                float rightBrowDis = sdBezier(browTransPoint.xy, rightBrowStart, rightBrowDir, rightBrowEnd);
                float rightBrowThick = 0.004 * 4.0 * rightBrowPos * (1.0 - rightBrowPos) * (1.0 - rightBrowPos);
                
                if(rightBrowDis < rightBrowThick && rightBrowPos > 0.0 && rightBrowPos <= 1.0)
                    info.material.color0 = mix(vec4(facialInfo.browColor, 1.0), info.material.color0, smoothstep(rightBrowThick - 0.0015, rightBrowThick, rightBrowDis));
                
                
                // 腮红
                float sdBlush = min(sdEllipsoid(transPoint, vec3(-0.09, -0.09, -0.13), vec3(0.07, 0.06, 0.07)),
                                    sdEllipsoid(transPoint, vec3(0.09, -0.09, -0.13), vec3(0.07, 0.06, 0.07)));
                                    
                if(sdBlush < 0.0)
                {
                    info.material.color0.rgb = mix(info.material.color0.rgb, facialInfo.blushColor, smoothstep(0.0, -0.06, sdBlush) * facialInfo.blushFactor);
                }
                
            }
        }
        
    }
    
    info.dis *= sdf_scale;
    outlineDis *= sdf_scale;
    
    return info;
}

ObjectInfo hairPin(vec3 p, vec3 sdf_pos, vec4 sdf_rot, float sdf_scale, bool withMat, out float outlineDis)
{
    ObjectInfo info = ObjectInfo(0.0,
                      Material(
                      vec4(1.0, 0.98, 0.91, 1.0),
                      vec4(0.0),
                      vec4(0.0),
                      vec3(0.0),
                      vec3(0.0),
                      vec3(0.0),
                      0.0, 4.0, 0.2, 0.0, 0.0, 7));
    
    vec3 transPoint = (p - sdf_pos) / sdf_scale;
    transPoint = rotatePoint(transPoint, vec3(0), quaternionInverse(sdf_rot));
    
    float tempFactor = 4.0;
    float tempCos = cos(tempFactor * transPoint.y);
    float tempSin = sin(tempFactor * transPoint.y);
    mat2  tempMat = mat2(tempCos, -tempSin, tempSin ,tempCos);
    transPoint -= vec3(0.0, 0.02, -0.1);
    transPoint.yz = tempMat * transPoint.yz;
    
    info.dis = sdTriangleIsosceles(transPoint.xy, vec2(0.0), vec2(0.032, -0.08));
    
    vec2 tempFlat = vec2(info.dis, abs(transPoint.z) - 0.003);
    info.dis = min(max(tempFlat.x,tempFlat.y),0.0) + length(max(tempFlat, 0.0));
    info.dis -= 0.003;
    outlineDis = info.dis;
    
    info.dis *= sdf_scale;
    outlineDis *= sdf_scale;
    
    return info;
}

ObjectInfo scarf(vec3 p, vec3 sdf_pos, vec4 sdf_rot, float sdf_scale, bool withMat, out float outlineDis)
{
    ObjectInfo info = ObjectInfo(0.0,
                      Material(
                      vec4(0.28, 0.24, 0.32, 1.0),
                      vec4(0.0),
                      vec4(0.0),
                      vec3(0.0),
                      vec3(0.0),
                      vec3(0.0),
                      0.0, 4.0, 0.2, 0.0, 0.0, 7));
    
    vec3 transPoint = (p - sdf_pos) / sdf_scale;
    transPoint = rotatePoint(transPoint, vec3(0), quaternionInverse(sdf_rot));
    
    float tempFactor = 1.0;
    float tempCos = cos(tempFactor * transPoint.x);
    float tempSin = sin(tempFactor * transPoint.x);
    mat2  tempMat = mat2(tempCos, -tempSin, tempSin ,tempCos);
    transPoint.xy = tempMat * transPoint.xy;
    
    info.dis = smin(sdEllipsoid(transPoint, vec3(0.0), vec3(0.17, 0.1, 0.19)),
                    sdEllipsoid(transPoint, vec3(0.0, -0.16, 0.02), vec3(0.19, 0.16, 0.23)), 0.05);
    info.dis = onion(info.dis, 0.005);
    info.dis = ssub(info.dis, sdBox(transPoint, vec3(0.0, 0.11, 0.0), vec3(0.4, 0.07, 0.4)), 0.002);
    info.dis = ssub(info.dis, sdBox(transPoint, vec3(0.0, -0.26, 0.0), vec3(0.4, 0.12, 0.4)), 0.002);
    outlineDis = info.dis;
    
    if(withMat)
    {
        float sdLine = sdBox(transPoint, vec3(0.0, -0.056, 0.0), vec3(0.4, 0.02, 0.4));
        info.material.color0.rgb = mix(info.material.color0.rgb, defaultFacialInfo.hairColor, smoothstep(0.002, 0.0, sdLine));
    }
    
    info.dis *= sdf_scale;
    outlineDis *= sdf_scale;
    
    return info;
}

// Project

float outlineMin(float a, float b)
{
    if(a > MAX_DISTANCE) return a;
    if(b > MAX_DISTANCE) return b;
    return min(a, b);
}

ObjectInfo sceneSolidMap(vec3 point, bool castShadow, bool withMat, out float outlineDis)
{
    float headOutline;
    ObjectInfo headInfo = animeHead(point, positionWorld_Root, rotationWorld_Root, 8.0, defaultFacialInfo, castShadow, withMat, headOutline);
    float pinOutline;
    ObjectInfo pinInfo = hairPin(point, positionWorld_Pin, rotationWorld_Pin, 8.0, withMat, pinOutline);
    float scarfOutline;
    ObjectInfo scarfInfo = scarf(point, positionWorld_Scarf, rotationWorld_Scarf, 8.0, withMat, scarfOutline);
    
    ObjectInfo info = objectMin(objectMin(headInfo, pinInfo), scarfInfo);
    outlineDis = outlineMin(outlineMin(headOutline, pinOutline), scarfOutline);
    
    return info;
}

vec4 march(vec3 start, vec3 ray, vec3 front, vec2 screenCoord, float pixelSize, inout vec3 pos, inout vec3 normal, inout float len)
{
    len = 0.0;
    float dis = 0.0;
    vec3 curPos = vec3(0.0);
    
    ObjectInfo curSolidInfo;
    ObjectInfo lastSolidInfo;
    
    ObjectInfo curVolInfo;
    ObjectInfo lastVolInfo;
    
    float stepDis;
    
    int stepCount = 0;
    float threshold_0;
    
    float curPixelSize;
    float disWhenHit = 65535.0;
    float lenWhenHit;
    float disForRealHit = 65535.0;
    float lenForRealHit;
    bool outlineHitFlag = false;
    float outlineDis;
    
    float theta = dot(ray, front);
    
    int outlineHit = 0;

    while(len < MAX_DISTANCE && stepCount <= MAX_STEP)
    {
        curPos = len * ray + start;
        pos = curPos;
        
        curPixelSize = len * theta * pixelSize;
        threshold_0 = curPixelSize * 1.0;
        
        lastSolidInfo = curSolidInfo;
        curSolidInfo = sceneSolidMap(curPos, false, false, outlineDis);
        
        dis = curSolidInfo.dis;
        
        if(dis < threshold_0)
        {
            break;
        }
        
        if(outlineHit == 0)
        {
            // 第一次到范围内
            if(outlineDis <= curPixelSize * outlineStrength) outlineHit = 1;
            
            float currentDis = outlineDis / curPixelSize;
            lenWhenHit = len;
            disWhenHit = currentDis;
        }
        else if(outlineHit == 1)
        {
            if(outlineDis > MAX_DISTANCE)
            {
                outlineHit = 0;
            }
            else if(outlineDis <= curPixelSize * outlineStrength)
            {
                float currentDis = outlineDis / curPixelSize;
                
                if(disWhenHit > currentDis)
                {
                    lenWhenHit = len;
                    disWhenHit = currentDis;
                }
            }
            else
            {
                outlineHit = 0;
                outlineHitFlag = true;
                if(disWhenHit < disForRealHit)
                {
                    disForRealHit = disWhenHit;
                    lenForRealHit = lenWhenHit;
                }
            }
        }

        stepDis = dis * 0.9;
        len += stepDis;
        stepCount += 1;
    }
    
    vec4 outputColor = getColorAtPos(pos, ray, len, screenCoord, curPixelSize, dis, normal, outlineHitFlag, disForRealHit, lenForRealHit);
    
    return outputColor;
}

Material sceneBaseMaterial(vec3 point, float len, vec2 screenCoord)
{
    if(len >= MAX_DISTANCE) {
        Material outMat;
        outMat.color0 = BACKGROUND_COLOR;
        outMat.index = 0;
        return outMat;
    } 
    
    float outlineDis;
    return sceneSolidMap(point, false, true, outlineDis).material;
}

void update()
{
    outlineStrength = 3.0 * pow(iResolution.x / 800.0, 0.5);
    float angle;
    
    // 相机
    positionWorld_Camera = positionLocal_Camera;
    rotationWorld_Camera = rotationLocal_Camera;
    
    
    // 根
    positionWorld_Root = positionLocal_Root;
    
    angle = -PI / 32.0;
    rotationLocal_Root = quaternionMul(load(POINTER_ROT), quaternionMul(vec4(sin(angle / 2.0), 0.0, 0.0, cos(angle / 2.0)), rotationLocal_Root));
    angle = PI / 6.0;
    rotationLocal_Root = quaternionMul(rotationLocal_Root, quaternionMul(vec4(0.0, sin(angle / 2.0), 0.0, cos(angle / 2.0)), rotationLocal_Root));
    rotationWorld_Root = rotationLocal_Root;
    
    // 发卡
    positionWorld_Pin = rotatePoint(positionLocal_Pin + positionWorld_Root, positionWorld_Root, rotationWorld_Root);
    rotationWorld_Pin = quaternionMul(rotationWorld_Root, rotationLocal_Pin);
    
    // 围巾
    positionWorld_Scarf = rotatePoint(positionLocal_Scarf + positionWorld_Root, positionWorld_Root, rotationWorld_Root);
    rotationWorld_Scarf = quaternionMul(rotationWorld_Root, rotationLocal_Scarf);
    
    // 表情
    float frameTime = floor(iTime * FRAMERATE) / FRAMERATE;
    float blinkFactor;
    float biinkTimeline = 2.55 * frameTime;
    float blinkTime = floor(biinkTimeline);
    if(hash11(blinkTime) > BLINK_THRESHOLD) blinkFactor = -1.0;
    else blinkFactor = -cos(fract(biinkTimeline) * 2.0 * PI);
    
    defaultFacialInfo.rightUpLidPos = blinkFactor * 0.5 + 0.5;
    defaultFacialInfo.rightDownLidPos = defaultFacialInfo.rightUpLidPos;
    defaultFacialInfo.leftUpLidPos = defaultFacialInfo.rightUpLidPos;
    defaultFacialInfo.leftDownLidPos = defaultFacialInfo.rightUpLidPos;
    // defaultFacialInfo.lipBend = sin(2.0 * iTime);
    
    // 眼珠
    vec3 front = vec3(0.0, 0.0, -1.0);
    vec3 headLeft = vec3(1.0, 0.0, 0.0);
    vec3 headUp = vec3(0.0, 1.0, 0.0);
    
    headLeft = rotatePoint(headLeft, vec3(0), quaternionInverse(rotationWorld_Root));
    float horOffset = dot(headLeft, front);
    
    defaultFacialInfo.leftEyeBallPos.x = mix(0.5, -0.5, horOffset / 2.0 + 0.5);
    defaultFacialInfo.rightEyeBallPos.x = mix(-0.5, 0.5, -horOffset / 2.0 + 0.5);
    
    headUp = rotatePoint(headUp, vec3(0), quaternionInverse(rotationWorld_Root));
    float verOffset = dot(headUp, front);
    
    defaultFacialInfo.leftEyeBallPos.y = mix(0.6, -0.6, verOffset / 2.0 + 0.5);
    defaultFacialInfo.rightEyeBallPos.y = mix(0.6, -0.6, verOffset / 2.0 + 0.5);
    
}

vec4 defaultShading(vec3 lightDir, float strength, vec4 lightColor, vec4 shadowColor, Material material, vec3 pos, vec3 normal, vec3 view)
{
    float expSmoothness = pow(2.7, 5.0 * material.t0 + 1.0);
    
    float shodow = softshadow(pos, -lightDir, MIN_DIS_SHADOW, MAX_DISTANCE, 24.0);
    float lightLevel = clamp(dot(-normal, lightDir), 0.0, 1.0);
    
    lightLevel = multiStep(lightLevel, 3.0, 0.0, 0.0) * multiStep(shodow, 3.0, 0.0, 0.0);
    
    vec4 diffuse = material.color0 * mix(shadowColor, lightColor, lightLevel) * strength;
    
    float res_0 = dot(normalize(mix(lightDir, view, 0.5)), -normal);
    lightLevel = pow(clamp(res_0, 0.0, 1.0), expSmoothness);
    
    vec4 specular = lightColor * lightLevel * shodow * material.t0 * strength;
    
    float fresnelLevel = pow(1.0 + dot(view, normal), material.t1);
    // fresnelLevel = multiStep(fresnelLevel, 2.0, 0.0, 0.0);
    
    vec4 fresnel = material.t2 * fresnelLevel * material.color0 * lightColor * strength;
    
    return diffuse + specular + fresnel;
}

vec4 hairShading(vec3 lightDir, float strength, vec4 lightColor, vec4 shadowColor, Material material, vec3 pos, vec3 normal, vec3 view)
{
    float expSmoothness = pow(2.7, 5.0 * material.t0 + 1.0);
    
    float shodow = softshadow(pos, -lightDir, MIN_DIS_SHADOW, MAX_DISTANCE, 24.0);
    float diffuseLevel = clamp(dot(-normal, lightDir), 0.0, 1.0);
    
    float lightLevel = multiStep(diffuseLevel, 3.0, 0.0, 0.0) * multiStep(shodow, 3.0, 0.0, 0.0);
    
    vec4 diffuse = material.color0 * mix(shadowColor, lightColor, lightLevel) * strength;
    
    float res_0 = dot(normalize(mix(lightDir, view, 0.5)), -normal);
    lightLevel = pow(clamp(res_0, 0.0, 1.0), expSmoothness);
    
    vec4 specular = lightColor * lightLevel * shodow * material.t0 * strength;
    
    float fresnelLevel = pow(1.0 + dot(view, normal), material.t1);
    
    vec4 fresnel = material.t2 * fresnelLevel * material.color0 * lightColor * strength;
    
    vec4 baseLighting = diffuse + specular + fresnel;
    
    float highlightFactor = dot(material.vect0, lightDir) / 2.0 + 0.5;
    float v = (material.t3 - mix(material.color2.x, material.color2.y, highlightFactor)) / mix(material.color2.z, material.color2.w, highlightFactor);
    if(v < 0.0 || v > 1.0) return baseLighting;
    float u = material.t4;
    float highlightThreshold = mix(0.0, 0.5, diffuseLevel);
    float highlight = smoothstep(highlightThreshold, highlightThreshold - 0.05, voronoiAndHide(vec2(u, v), vec2(36.0, 1.0), vec2(1.0, 65535.0), vec2(8.0, 0.5), vec2(0.0), vec2(1.0, 0.0), 0.3));
    
    
    
    return mix(baseLighting, material.color1, highlight);
}

vec4 skinShading(vec3 lightDir, float strength, vec4 lightColor, Material material, vec3 pos, vec3 normal, vec3 view)
{
    float expSmoothness = pow(2.7, 5.0 * material.t0 + 1.0);
    
    float shodow = softshadow(pos, -lightDir, MIN_DIS_SHADOW, MAX_DISTANCE, 24.0);
    float lightLevel = clamp(dot(-normal, lightDir), 0.0, 1.0);
    
    lightLevel = multiStep(lightLevel, 2.0, 0.0, 0.0) * multiStep(shodow, 2.0, 0.0, 0.0);
    
    vec4 diffuse = material.color0 * mix(material.color1, lightColor, lightLevel) * strength;
    
    float res_0 = dot(normalize(mix(lightDir, view, 0.5)), -normal);
    lightLevel = pow(clamp(res_0, 0.0, 1.0), expSmoothness);
    
    vec4 specular = lightColor * lightLevel * shodow * material.t0 * strength;
    
    float fresnelLevel = pow(1.0 + dot(view, normal), material.t1);
    // fresnelLevel = multiStep(fresnelLevel, 2.0, 0.0, 0.0);
    
    vec4 fresnel = material.t2 * fresnelLevel * material.color0 * lightColor * strength;
    
    return diffuse + specular + fresnel;
}

vec4 eyeLashShading(vec3 lightDir, float strength, vec4 lightColor, vec4 shadowColor, Material material, vec3 pos, vec3 view)
{
    float lightLevel = clamp(dot(-material.vect0, lightDir), 0.0, 1.0);
    lightLevel = multiStep(lightLevel, 2.0, 0.0, 0.0);
    
    vec4 diffuse = material.color0 * mix(shadowColor, lightColor, lightLevel) * strength;
    
    return diffuse;
}

vec4 whiteShading(vec3 lightDir, float strength, vec4 lightColor, vec4 shadowColor, Material material, vec3 pos, vec3 view)
{
    float lightLevel = mix(clamp(dot(-material.vect0, lightDir), 0.0, 1.0), 1.0, material.t1);
    
    vec4 outColor = mix(material.color1, material.color0, clamp(material.t0 + dot(-material.vect1, lightDir), 0.0, 1.0));
    vec4 diffuse = outColor * mix(shadowColor, lightColor, lightLevel) * strength;
    
    return diffuse;
}

vec4 eyeBallShading(vec3 lightDir, float strength, vec4 lightColor, vec4 shadowColor, Material material, vec3 pos, vec3 view)
{
    vec2 uv = material.color2.xy;
    vec2 center = uv / vec2(1.0, 0.56) - vec2(0.0, -1.0) + material.color2.zw * vec2(dot(view, material.vect1), dot(view, material.vect2));
    
    vec2 polarUV;
    polarUV.x = atan(center.y, center.x) / (2.0 * PI) + 0.5;
    polarUV.y = length(center);
            
    float factor = smoothstep(0.9, 0.75, polarUV.y);
                        
    polarUV.x = atan(uv.y, uv.x) / (2.0 * PI) + 0.5;
    polarUV.y = length(uv);
            
    factor *= smoothstep(0.9, 0.85, polarUV.y);
            
    float lightLevel = mix(clamp(dot(-material.vect0, lightDir), 0.0, 1.0), 1.0, mix(material.color0.w, material.color1.w, factor));
    
    vec4 outColor = vec4(mix(material.color0.xyz, material.color1.xyz, factor), 1.0);
    
    vec4 diffuse = outColor * mix(shadowColor, lightColor, lightLevel) * strength;
    
    return diffuse;
}

vec4 getColorAtPos(vec3 pos, vec3 ray, float len, vec2 screenCoord, float pixelSize, float dis, inout vec3 normal, bool outlineHit, float disWhenHit, float lenWhenHit)
{
    Material material = sceneBaseMaterial(pos, len, screenCoord);
    vec4 outlineColor = vec4(0.0);
    
    if(outlineHit)
    {
        float outlineThreshold = mix(0.0, outlineStrength, clamp((len - lenWhenHit) / outlineThreshold, 0.0, 1.0));
        // if(outlineThreshold > disWhenHit) return OUTLINE_COLOR.rgb;
        outlineColor = vec4(vec3(0.3, 0.2, 0.24), clamp(outlineThreshold - disWhenHit - 0.25, 0.0, 1.0));
    }
    
    vec4 solidColor = vec4(0.0);
    if(material.index == 0) solidColor = material.color0;
    else
    {
        normal = getSolidNormal(pos, pixelSize);
    
        if(material.index == 2) solidColor = skinShading(normalize(LIGHT_DIRECTION), LIGHT_STRENGTH, LIGHT_COLOR, material, pos, normal, ray);
        else if(material.index == 3) solidColor = whiteShading(normalize(LIGHT_DIRECTION), LIGHT_STRENGTH, LIGHT_COLOR, AMBIENT_COLOR, material, pos, ray);
        else if(material.index == 4) solidColor = eyeBallShading(normalize(LIGHT_DIRECTION), LIGHT_STRENGTH, LIGHT_COLOR, AMBIENT_COLOR, material, pos, ray);
        else if(material.index == 5) solidColor = eyeLashShading(normalize(LIGHT_DIRECTION), LIGHT_STRENGTH, LIGHT_COLOR, AMBIENT_COLOR, material, pos, ray);
        else if(material.index == 5) solidColor = eyeLashShading(normalize(LIGHT_DIRECTION), LIGHT_STRENGTH, LIGHT_COLOR, AMBIENT_COLOR, material, pos, ray);
        else if(material.index == 6) solidColor = hairShading(normalize(LIGHT_DIRECTION), LIGHT_STRENGTH, LIGHT_COLOR, AMBIENT_COLOR, material, pos, normal, ray);
        else solidColor = defaultShading(normalize(LIGHT_DIRECTION), LIGHT_STRENGTH, LIGHT_COLOR, AMBIENT_COLOR, material, pos, normal, ray);
    }
    
    return mix(solidColor, outlineColor, outlineColor.a);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    update();
    
    vec2 uv = (fragCoord.xy - iResolution.xy / 2.0) / iResolution.x;
    float delta = 1.0 / iResolution.x;
    float tanFov = tan(cameraFov / 360.0 * PI);
    vec3 ray = normalize(vec3(uv, 0.5 / tanFov));
    // 平面距离为1时，每个像素对应的大小
    float pixelSize = 2.0 * tanFov / iResolution.x;
    vec3 front = rotatePoint(vec3(0.0, 0.0, 1.0), vec3(0.0), rotationWorld_Camera);
    ray = rotatePoint(ray, vec3(0.0), rotationWorld_Camera);
    
    vec3 pos;
    vec3 normal;
    float len;
    
    vec4 color = march(positionWorld_Camera, ray, front, fragCoord / iResolution.xy, pixelSize, pos, normal, len);
    // color.rgb = pow(color.rgb, vec3(1.0 / 2.2));
    
    fragColor = color;
}
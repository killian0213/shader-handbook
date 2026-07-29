// Image (image) — Ishigami Kouko by SL0ANE
// https://www.shadertoy.com/view/lcV3Dt

# define MAX_DISTANCE 64.0
# define HAIR_FAR 32.0
# define MAX_STEP 128
# define MAX_COLOR vec4(0.96, 0.95, 0.9, 1.0)
# define MIN_COLOR vec4(0.3, 0.25, 0.2, 1.0)
# define BACKGROUND_COLOR vec4(1.0, 1.0, 1.0, 1.0)

# define OUTLINE_COLOR vec4(0.0, 0.0, 0.0, 0.0)

# define FRAME_RATE 12.0
# define BLINK_THRESHOLD 0.12


// # define SMILING        <---------------------------- 试试这个！


// # define MODELING
// # define SIMPLE_TEXTURE
// # define NOHAIR
// # define EYETEST
// # define CROSSLINE
// # define SHOWUV

// Pre
ObjectInfo sceneBaseMap(vec3 point, vec3 view, float pixelSize, bool castShadow, bool withMat, inout float outlineDis);
Material sceneBaseMaterial(vec3 point, float len);
vec3 getColorAtPos(vec3 pos, vec3 ray, vec3 front, float len, vec2 screenCoord, float pixelSize, float dis, bool outlineHit, float disWhenHit, float lenWhenHit);
ObjectInfo sceneHairMap(vec3 point, vec3 view, float pixelSize, bool castShadow, bool withMat);
Material sceneHairMaterial(vec3 point, float len);
vec4 getHairAtPos(vec3 pos, vec3 ray, vec3 front, float len, vec2 screenCoord, float pixelSize, float dis);

// Camera Config
float cameraFov = 36.0f;

// Outline Config
float outlineStrength = 3.3;
float outlineThreshold = 0.05;

// Bone

vec3 positionLocal_Camera = vec3(0.0, 0.0, 0.0);
vec4 rotationLocal_Camera = vec4(0.0, 0.0, 0.0, 1.0);
vec3 positionWorld_Camera;
vec4 rotationWorld_Camera;

vec3 positionLocal_Root = vec3(0.0, -0.85, 8.5);
vec4 rotationLocal_Root = vec4(0.026, 0.130, -0.003, 0.991);
mat4 transform_Root;

vec3 positionLocal_Neck = vec3(0.0, 0.0, 0.0);
vec4 rotationLocal_Neck = vec4(0.0, 0.0, 0.0, 1.0);
mat4 transform_Neck;

vec3 positionLocal_Head = vec3(0.0, 0.2, -0.05);
vec4 rotationLocal_Head = vec4(0.0, 0.0, 0.0, 1.0);
mat4 transform_Head;

vec3 positionLocal_Ear = vec3(0.64, 0.6, 0.08);
vec4 rotationLocal_Ear = vec4(0.0, 0.383, 0.0, 0.924);
mat4 transform_Ear;

vec2 hairDir_0 = vec2(0.0, -1.0);
vec2 hairDir_1 = vec2(0.0, -1.0);


// Util
float outlineMin(float a, float b)
{
    if(a > MAX_DISTANCE) return a;
    if(b > MAX_DISTANCE) return b;
    return min(a, b);
}


// Object
struct FacialInfo
{
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
    
    vec2 lipStart;
    vec2 lipEnd;
    vec2 lipDir;
    
    float flushSize;
    
};

struct EyeInfo
{
    vec2 eyeballPos;
    float eyeballScale;
    float upLidPos;
    float downLidPos;
    
    vec2 lightPos;
    
    vec2 browStart;
    vec2 browEnd;
    vec2 browDir;
};

struct LipInfo
{
    vec2 lipStart;
    vec2 lipEnd;
    vec2 lipDir;
};

FacialInfo defaultFacialInfo = FacialInfo(
    #ifndef SMILING
    vec2(-0.2, 0.3),
    0.9,
    vec2(0.2, 0.3),
    0.9,

    0.45,
    0.48,
    0.45,
    0.48,

    vec2(-1.1, -0.8),
    vec2(0.9, -0.2),
    vec2(-0.3, -0.6),
    vec2(1.1, -0.8),
    vec2(-0.9, -0.2),
    vec2(0.3, -0.6),

    vec2(1.0, -0.1),
    vec2(-1.0, -0.1),
    vec2(0.0, 0.2),

    1.3
    
    #else
    vec2(0.8, 0.05),
    1.0,
    vec2(0.8, 0.05),
    1.0,

    0.52,
    0.50,
    0.52,
    0.50,

    vec2(-1.1, -0.5),
    vec2(0.9, -0.1),
    vec2(-0.3, -0.1),
    vec2(1.1, -0.5),
    vec2(-0.9, -0.1),
    vec2(0.3, -0.1),

    vec2(1.0, 0.15),
    vec2(-1.1, 0.15),
    vec2(0.1, -0.3),

    0.7
    #endif
);

float getLidSegDis(vec2 uv, float thick, float len, float bend, float angle, vec2 start, vec2 end, vec2 dir, float t)
{
    vec2 segStart = bezier(start, end, dir, t);
    vec2 segTan = bezierTangent(start, end, dir, t);
    float realTan = atan(segTan.y, segTan.x) + angle;
    segTan = vec2(cos(realTan), sin(realTan));
    vec2 segDir = cross(vec3(0.0, 0.0, 1.0), vec3(segTan, 0.0)).xy;
    vec2 segEnd = segStart + len * segDir;
    segDir = segStart + 0.5 * len * segDir;
    segDir = segDir + normalize(segTan * sign(dot(segDir - dir, segTan))) * bend;
    float segCurve;
    
    float baseDis = sdBezier(uv, segStart, segEnd, segDir, segCurve);
    float actualDis = abs(baseDis) - mix(thick / 2.0, 0.0, segCurve);
    
    return actualDis;
}

void getEyeTexture(vec2 uv, EyeInfo info, float pixelSize, float t, inout vec3 outputColor)
{
    float line = outlineStrength * pixelSize / 2.0;
    #ifdef SHOWUV
    outputColor = vec3(uv * 0.5 + 0.5, 0.0);
    return;
    #endif
    
    float eyeBallLerp = sign(t) * pow(abs(t), 2.5);
    
    // 上眼睫毛
    float upLidFactor = smoothstep(0.0, 1.0, info.upLidPos) * 2.0 - 1.0;
    vec2 upLidStartCenter = triLerp(vec2(-0.59, -0.27), vec2(-0.59, 0.1), vec2(-0.59, 0.3), upLidFactor);
    vec2 upLidEndCenter = triLerp(vec2(0.72, -0.23), vec2(0.72, 0.32), vec2(0.72, 0.48), upLidFactor);
    vec2 upLidDirCenter = triLerp(vec2(0.3, -0.05), vec2(0.3, 0.5), vec2(0.0, 0.8), upLidFactor);
    
    vec2 upLidStartRight = triLerp(vec2(-0.1, -0.31), vec2(-0.1, 0.1), vec2(-0.1, 0.3), upLidFactor);
    vec2 upLidEndRight = triLerp(vec2(1.0, -0.15), vec2(1.0, 0.33), vec2(1.0, 0.4), upLidFactor);
    vec2 upLidDirRight = triLerp(vec2(0.36, -0.05), vec2(0.3, 0.5), vec2(0.32, 0.8), upLidFactor);
    
    vec2 upLidStartLeft = triLerp(vec2(0.0, -0.35), vec2(-0.1, 0.0), vec2(-0.1, 0.3), upLidFactor);
    vec2 upLidEndLeft = triLerp(vec2(-0.1, -0.35), vec2(-0.2, 0.4), vec2(-0.2, 0.48), upLidFactor);
    vec2 upLidDirLeft = triLerp(vec2(0.0, 0.05), vec2(-0.2, 0.5), vec2(-0.3, 0.8), upLidFactor);
    
    vec2 upLidStart = triLerp(upLidStartLeft, upLidStartCenter, upLidStartRight, eyeBallLerp);
    vec2 upLidEnd = triLerp(upLidEndLeft, upLidEndCenter , upLidEndRight, eyeBallLerp);
    vec2 upLidDir = triLerp(upLidDirLeft, upLidDirCenter, upLidDirRight, eyeBallLerp);
    
    float upLidCurve;
    float upLidDis = sdBezier(uv, upLidStart, upLidEnd, upLidDir, upLidCurve);
    float upLidThick = mix(0.0, 0.15, smoothmid(upLidCurve, 0.3));
    
    #ifndef SIMPLE_TEXTURE
    
    // 上眼小睫毛
    
    float upLidSegDis;
    float upLidSeg0Dis = getLidSegDis(uv, line, 0.34, 0.05, PI * 0.4, upLidStart, upLidEnd, upLidDir, 0.2);
    float upLidSeg1Dis = getLidSegDis(uv, line, 0.36, 0.05, PI * 0.333, upLidStart, upLidEnd, upLidDir, 0.3);
    float upLidSeg2Dis = getLidSegDis(uv, line, 0.32, 0.05, -PI * 0.3, upLidStart, upLidEnd, upLidDir, 0.52);
    float upLidSeg3Dis = getLidSegDis(uv, line, 0.32, 0.05, -PI * 0.35, upLidStart, upLidEnd, upLidDir, 0.6);
    float upLidSeg4Dis = getLidSegDis(uv, line, 0.32, 0.05, -PI * 0.45, upLidStart, upLidEnd, upLidDir, 0.65);
    
    upLidSegDis = min(upLidSeg0Dis, upLidSeg1Dis);
    upLidSegDis = min(upLidSegDis, upLidSeg2Dis);
    upLidSegDis = min(upLidSegDis, upLidSeg3Dis);
    upLidSegDis = min(upLidSegDis, upLidSeg4Dis);
    
    #endif
    
    // 上眼线
    
    vec2 upLidExtraStartCenter = triLerp(vec2(0.04, 0.14), vec2(0.04, 0.14), vec2(0.05, 0.2), upLidFactor);
    vec2 upLidExtraSEndCenter = triLerp(vec2(-0.19, 0.25), vec2(-0.19, 0.2), vec2(-0.24, 0.22), upLidFactor);
    vec2 upLidExtraSDirCenter = triLerp(vec2(-0.42, 0.24), vec2(-0.5, 0.14), vec2(-0.24, 0.14), upLidFactor);
    
    vec2 upLidExtraStartRight = triLerp(vec2(-0.05, 0.17), vec2(-0.05, 0.2), vec2(0.05, 0.28), upLidFactor);
    vec2 upLidExtraEndRight = triLerp(vec2(-0.3, 0.19), vec2(-0.3, 0.23), vec2(-0.3, 0.3), upLidFactor);
    vec2 upLidExtraDirRight = triLerp(vec2(-0.24, 0.23), vec2(-0.18, 0.14), vec2(-0.18, 0.08), upLidFactor);
    
    vec2 upLidExtraStartLeft = triLerp(vec2(0.1, 0.42), vec2(0.0, 0.3), vec2(0.0, 0.4), upLidFactor);
    vec2 upLidExtraEndLeft = triLerp(vec2(0.1, 0.4), vec2(0.0, 0.2), vec2(0.0, 0.16), upLidFactor);
    vec2 upLidExtraDirLeft = triLerp(vec2(0.1, 0.1), vec2(0.0, 0.1), vec2(0.2, 0.0), upLidFactor);
    
    vec2 upLidExtraStart = upLidStart + triLerp(upLidExtraStartLeft, upLidExtraStartCenter, upLidExtraStartRight, eyeBallLerp);
    vec2 upLidExtraEnd = upLidEnd + triLerp(upLidExtraEndLeft, upLidExtraSEndCenter, upLidExtraEndRight, eyeBallLerp);
    vec2 upLidExtraDir = upLidDir + triLerp(upLidExtraDirLeft, upLidExtraSDirCenter, upLidExtraDirRight, eyeBallLerp);
    
    float upLidExtraCurve;
    float upLidExtraDis = sdBezier(uv, upLidExtraStart, upLidExtraEnd, upLidExtraDir, upLidExtraCurve);
    float upLidExtraThick = mix(line / 5.0 * 2.0, line / 7.0 * 6.0, smoothmid(upLidExtraCurve, 0.3));
    
    // 下眼睫毛
    float downLidFactor = smoothstep(0.0, 1.0, info.downLidPos) * 2.0 - 1.0;
    vec2 downLidStartCenter = triLerp(vec2(-0.4, -0.19), vec2(-0.4, -0.36), vec2(-0.4, -0.48), downLidFactor);
    vec2 downLidEndCenter = triLerp(vec2(0.41, -0.15), vec2(0.41, -0.32), vec2(0.41, -0.46), downLidFactor);
    vec2 downLidDirCenter = triLerp(vec2(-0.1, -0.05), vec2(0.13, -0.5), vec2(0.0, -0.64), downLidFactor);
    
    vec2 downLidStartRight = triLerp(vec2(0.1, -0.21), vec2(0.1, -0.32), vec2(0.1, -0.5), downLidFactor);
    vec2 downLidEndRight = triLerp(vec2(0.74, -0.13), vec2(0.74, -0.16), vec2(0.74, -0.3), downLidFactor);
    vec2 downLidDirRight = triLerp(vec2(0.34, -0.15), vec2(0.34, -0.5), vec2(0.34, -0.64), downLidFactor);
    
    vec2 downLidStartLeft = triLerp(vec2(0.1, -0.15), vec2(0.1, -0.4), vec2(0.1, -0.44), downLidFactor);
    vec2 downLidEndLeft = triLerp(vec2(-0.2, -0.05), vec2(-0.2, -0.1), vec2(-0.2, -0.36), downLidFactor);
    vec2 downLidDirLeft = triLerp(vec2(0.0, -0.1), vec2(0.0, -0.4), vec2(0.0, -0.48), downLidFactor);
    
    vec2 downLidStart = triLerp(downLidStartLeft, downLidStartCenter, downLidStartRight, eyeBallLerp);
    vec2 downLidEnd = triLerp(downLidEndLeft, downLidEndCenter, downLidEndRight, eyeBallLerp);
    vec2 downLidDir = triLerp(downLidDirLeft, downLidDirCenter, downLidDirRight, eyeBallLerp);
    
    float downLidCurve;
    float downLidDis = sdBezier(uv, downLidStart, downLidEnd, downLidDir, downLidCurve);
    float downLidThick = mix(line / 2.0, line, smoothmid(downLidCurve, 0.5));
    
    #ifndef SIMPLE_TEXTURE
    // 下眼小睫毛
    
    float downLidSegDis;
    float downLidSeg0Dis = getLidSegDis(uv, line, 0.06, 0.01, PI * 1.2, downLidStart, downLidEnd, downLidDir, 0.76);
    float downLidSeg1Dis = getLidSegDis(uv, line, 0.1, 0.01, PI * 1.2, downLidStart, downLidEnd, downLidDir, 0.92);
    float downLidSeg2Dis = getLidSegDis(uv, line, 0.1, 0.01, PI * 1.2, downLidStart, downLidEnd, downLidDir, 1.08);
    
    downLidSegDis = min(downLidSeg0Dis, downLidSeg1Dis);
    downLidSegDis = min(downLidSegDis, downLidSeg2Dis);
    #endif
    
    // 左侧边界
    vec2 startEdgeStart = upLidStart;
    vec2 startEdgeEnd = downLidStart;
    vec2 startEdgeDir = triLerp(vec2(-0.2, -0.2), vec2(-0.6, -0.2), vec2(-0.1, -0.2), eyeBallLerp);
    startEdgeDir.y = (upLidStart.y + downLidStart.y) / 2.0;
    float startEdgeCurve;
    float startEdgeDis = sdBezier(uv, startEdgeStart, startEdgeEnd, startEdgeDir, startEdgeCurve);
    
    if(upLidDis > 0.0 && (downLidDis < 0.0 || downLidCurve < 0.0 || downLidCurve > 1.0) && startEdgeDis < 0.0)
    {
        // 眼球
        vec2 ballOriginLeft = quaLerp(vec2(-0.0, 0.05), vec2(-0.2, 0.41), vec2(-0.2, 0.05), vec2(-0.2, -0.31), vec2(-0.2, 0.05), info.eyeballPos);
        vec2 ballOriginCenter = quaLerp(vec2(0.16, 0.0), vec2(0.0, 0.36), vec2(-0.12, 0.0), vec2(0.0, -0.36), vec2(0.0, 0.0), info.eyeballPos);
        vec2 ballOriginRight = quaLerp(vec2(0.45, 0.05), vec2(0.0, 0.25), vec2(0.15, 0.05), vec2(0.15, -0.25), vec2(0.35, 0.05), info.eyeballPos);
        
        vec2 ballOrigin = triLerp(ballOriginLeft, ballOriginCenter, ballOriginRight, eyeBallLerp);
        vec2 ballSize = triLerp(vec2(-0.0, 0.42), vec2(0.38, 0.42), vec2(0.2, 0.42), eyeBallLerp) * info.eyeballScale;
        float ballDis = sdEllipse(uv, ballOrigin, ballSize);
        float ballOutline = 0.12 * info.eyeballScale;
        outputColor = mix(outputColor, vec3(0.0), smoothstep(pixelSize, 0.0, ballDis));
        outputColor = mix(outputColor, vec3(1.0), smoothstep(-ballOutline + pixelSize, -ballOutline, ballDis));
        
        #ifndef SIMPLE_TEXTURE
        
        // 眼球排线
        vec2 ballLineOrigin = ballOrigin + vec2(0.0, ballSize.y);
        vec2 ballLineDirection = normalize(triLerp(vec2(0.5, 1.0), vec2(0.0, 1.0), vec2(-0.5, 1.0), eyeBallLerp));
        
        
        float lineOrigin = dot(ballLineOrigin, ballLineDirection);
        float ballLine = lineOrigin + 0.035;
        float ballLineStep = 0.03;
        float ballLineAccu = 0.0007;
        float ballLineAccuAccu = 0.0003;
        float ballLineCur = dot(uv, ballLineDirection);
        float lineDis = 65535.0;
        
        if(ballDis < 0.0)
        {
            for(int i = ZERO; i < 12; i++)
            {
                ballLineAccu += ballLineAccuAccu;
                ballLineStep += ballLineAccu * info.eyeballScale;
                ballLine -= ballLineStep;
            
                lineDis = min(lineDis, abs(ballLine - ballLineCur));
            }
        
            outputColor = mix(outputColor, vec3(0.0), smoothstep(pixelSize, 0.0, lineDis - line / 6.0));
        }
        
        #endif
        
        // 眼珠
        vec2 irisOriginLeft = quaLerp(vec2(0.05, 0.05), vec2(-0.25, 0.41), vec2(-0.25, 0.05), vec2(-0.25, -0.31), vec2(-0.25, 0.05), info.eyeballPos);
        vec2 irisOriginCenter = quaLerp(vec2(0.19, 0.0), vec2(0.0, 0.36), vec2(-0.15, 0.0), vec2(0.0, -0.36), vec2(0.0, 0.0), info.eyeballPos);
        vec2 irisOriginRight = quaLerp(vec2(0.48, 0.05), vec2(0.0, 0.25), vec2(0.15, 0.05), vec2(0.15, -0.25), vec2(0.37, 0.05), info.eyeballPos);

        ballOrigin = triLerp(irisOriginLeft, irisOriginCenter, irisOriginRight, eyeBallLerp);
        ballSize = triLerp(vec2(-0.05, 0.16), vec2(0.14, 0.16), vec2(0.06, 0.16), eyeBallLerp) * info.eyeballScale;
        ballDis = sdEllipse(uv, ballOrigin, ballSize);
        outputColor = mix(outputColor, vec3(0.0), smoothstep(pixelSize, 0.0, ballDis));
        
        #ifndef SIMPLE_TEXTURE
        
        // 高光
        vec2 lightOriginLeft = quaLerp(vec2(0.0, 0.0), vec2(0.0, 0.0), vec2(0.0, 0.0), vec2(0.0, 0.0), vec2(0.0, 0.0), info.lightPos) * info.eyeballScale + ballOriginLeft;
        vec2 lightOriginCenter = quaLerp(vec2(0.3, 0.0), vec2(0.0, 0.4), vec2(-0.3, 0.0), vec2(0.0, -0.4), vec2(0.0, 0.0), info.lightPos) * info.eyeballScale + ballOriginCenter;
        vec2 lightOriginRight = quaLerp(vec2(0.18, 0.0), vec2(0.0, 0.4), vec2(-0.18, 0.0), vec2(0.0, -0.4), vec2(0.0, 0.0), info.lightPos) * info.eyeballScale + ballOriginRight;
        
        ballOrigin = triLerp(lightOriginLeft, lightOriginCenter, lightOriginRight, eyeBallLerp);
        ballSize = triLerp(vec2(0.11, 0.11), vec2(0.15, 0.1), vec2(0.11, 0.1), eyeBallLerp);
        ballDis = sdEllipse(uv, ballOrigin, ballSize);
        
        float lightWidth = mix(0.0, line / 1.0, clamp(1.0 - (normalize(uv - ballOrigin).x * sign(info.lightPos.x) - 0.6) / 0.35, 0.0, 1.0));
        if(lightWidth > 0.0) outputColor = mix(outputColor, vec3(0.0), smoothstep(pixelSize, 0.0, ballDis));
        outputColor = mix(outputColor, vec3(1.0), smoothstep(-lightWidth + pixelSize, -lightWidth, ballDis));
        
        #endif
        
    }
    
    outputColor = mix(outputColor, vec3(1.0), smoothstep(pixelSize, 0.0, abs(startEdgeDis)));
    
    outputColor = mix(outputColor, vec3(0.0), min(smoothstep(0.0, -pixelSize, abs(upLidDis) - upLidThick), smoothstep(-pixelSize, 0.0, -upLidDis)));
    outputColor = mix(outputColor, vec3(0.0), smoothstep(0.0, -pixelSize, abs(upLidExtraDis) - upLidExtraThick));
    outputColor = mix(outputColor, vec3(0.0), min(smoothstep(0.0, -pixelSize, abs(downLidDis) - downLidThick), smoothstep(pixelSize, 0.0, downLidDis)));
    
    #ifndef SIMPLE_TEXTURE
    if(upLidDis < 0.0) outputColor = mix(outputColor, vec3(0.0), smoothstep(pixelSize, 0.0, upLidSegDis));
    if(downLidDis > 0.0) outputColor = mix(outputColor, vec3(0.0), smoothstep(pixelSize, 0.0, downLidSegDis));
    #endif
    
    // 眉毛
    vec2 browCenter = triLerp(vec2(0.8, 1.04), vec2(0.02, 1.04), vec2(0.4, 1.04), eyeBallLerp);
    vec2 browStart = browCenter + 0.6 * info.browStart;
    vec2 browDir = browCenter + 0.6 * info.browDir;
    vec2 browEnd = browCenter + 0.6 * info.browEnd;
    float browCurve;
        
    float browDis = sdBezier(uv, browStart, browEnd, browDir, browCurve);
    float browThick = mix(0.0, 0.02, smoothmid(browCurve, 0.3));
    
    outputColor = mix(outputColor, vec3(0.0), smoothstep(pixelSize, 0.0, abs(browDis) - browThick));
}

void getNoseTexture(vec2 uv, float pixelSize, float t, inout vec3 outputColor)
{
    #ifdef SHOWUV
    outputColor = vec3(uv * 0.5 + 0.5, 1.0);
    return;
    #endif
    
    float line = outlineStrength * pixelSize / 2.0;
    
    vec2 noseStart = triLerp(vec2(0.3, 0.5), vec2(0.0, 0.2), vec2(-0.3, 0.5), t);
    vec2 noseEnd = triLerp(vec2(0.5, -0.05), vec2(0.0, -0.2), vec2(-0.5, -0.05), t);
    float noseDis = sdSegment(uv, noseStart, noseEnd);
    vec2 vect = noseEnd - noseStart;
    float len = length(vect);
    float proj = dot(uv - noseStart, vect / len) / len;
    float noseThick = mix(0.0, line, smoothmid(proj, 0.5));
    
    outputColor = mix(outputColor, vec3(0.0), smoothstep(0.0, -pixelSize, noseDis - noseThick));
}

void getLipTexture(vec2 uv, LipInfo info, float pixelSize, float t, inout vec3 outputColor)
{
    #ifdef SHOWUV
    outputColor = vec3(uv * 0.5 + 0.5, 0.5);
    return;
    #endif
    
    t = sign(t) * pow(abs(t), 3.0);
    
    float line = outlineStrength * pixelSize / 2.0;
    
    float lipRotate = triLerp(-PI / 24.0 , 0.0, PI / 24.0, t);
    vec2 lipOffset = triLerp(vec2(-0.3, 0.03), vec2(0.0, 0.0), vec2(0.3, 0.03), t);
    vec2 lipDirX = vec2(cos(lipRotate), sin(lipRotate)) * triLerp(0.8, 1.0, 0.8, t);
    vec2 lipDirY = vec2(cos(lipRotate + PI / 2.0), sin(lipRotate + PI / 2.0));
    
    vec2 scale = vec2(0.15, 0.15);
    vec2 lipStart = (info.lipStart.x * lipDirX + info.lipStart.y * lipDirY) * scale + lipOffset;
    vec2 lipEnd = (info.lipEnd.x * lipDirX + info.lipEnd.y * lipDirY) * scale + lipOffset;
    vec2 lipDir = (info.lipDir.x * lipDirX + info.lipDir.y * lipDirY) * scale + lipOffset;
    
    float lipCurve;
    float lipDis = sdBezier(uv, lipStart, lipEnd, lipDir, lipCurve);
    float lipThick = mix(0.0, line, max(smoothmid(lipCurve, 0.05), smoothmid(lipCurve, 0.95)));
    
    outputColor = mix(outputColor, vec3(0.0), smoothstep(0.0, -pixelSize, abs(lipDis) - line * 0.72));
    
    // outputColor = mix(outputColor, vec3(0.0), smoothstep(0.0, -pixelSize, noseDis - noseThick));
}

void getScarTexture(vec2 uv, vec2 sc, float pixelSize, inout vec3 outputColor)
{
    #ifdef SHOWUV
    outputColor = vec3(uv * 0.5 + 0.5, 0.75);
    return;
    #endif
    
    float line = outlineStrength * pixelSize / 2.0;
    float scarDis = 65535.0;
    scarDis = min(scarDis, sdOrientedVesica(uv, vec2(-0.54, -0.4), vec2(0.54, 0.4), 0.14));
    scarDis = smin(scarDis, sdOrientedVesica(uv, vec2(-0.3, 0.4), vec2(0.3, -0.4), 0.18), 0.08);
    
    outputColor = mix(outputColor, vec3(0.0), smoothstep(0.0, -pixelSize, scarDis - line));
    outputColor = mix(outputColor, vec3(1.0), smoothstep(0.0, -pixelSize, scarDis));
    
    #ifndef SIMPLE_TEXTURE
    vec2 lineDirection = normalize(vec2(-0.54, -0.4));
    float lineOrigin = dot(vec2(0.0), lineDirection);
    float linePos = lineOrigin + 0.03;
    float lineStep = 0.12;
    float lineCur = dot(sc, lineDirection);
    float lineDis = 65535.0;
        
    if(scarDis < 0.0)
    {
        for(int i = ZERO - 5; i <= 5; i++)
        {
            linePos = float(i) * lineStep;
            lineDis = min(lineDis, abs(linePos - lineCur));
        }
        
         outputColor = mix(outputColor, vec3(0.0), smoothstep(0.0, -pixelSize, lineDis - line * 0.75));
     }
     #endif
}

void getEarTexture(vec2 uv, float pixelSize, inout vec3 outputColor)
{
    #ifdef SHOWUV
    outputColor = vec3(uv * 0.5 + 0.5, 0.75);
    return;
    #endif
    
    float line = outlineStrength * pixelSize / 2.0;
    
    // 这就是为什么你不应该用sub
    float shapeDis = sdUnevenCapsule(uv, vec2(0.56, 0.34), vec2(-0.12, -0.2), 0.4, 0.36);
    // 突起
    float susDis = sdUnevenCapsule(uv, vec2(0.3, 0.26), vec2(-0.14, 0.18), 0.12, 0.2);
    
    shapeDis = ssub(shapeDis, susDis, 0.2);
    outputColor = mix(outputColor, vec3(0.0), smoothstep(pixelSize, 0.0, shapeDis));
    outputColor = mix(outputColor, vec3(1.0), smoothstep(-line + pixelSize, -line, shapeDis));
    
    // 耳屎出来的地方
    float holeDis = sdCircle(uv, vec2(-0.2, -0.1), 0.18);
    holeDis = max(shapeDis, holeDis);
    outputColor = mix(outputColor, vec3(0.0), smoothstep(pixelSize, 0.0, holeDis));
    
}

void getFlushTexture(vec2 uv, float pixelSize, float flushSize, float t, inout vec3 outputColor)
{
    #ifdef SHOWUV
    outputColor = vec3(uv * 0.5 + 0.5, 0.875);
    return;
    #endif
    
    float line = outlineStrength * pixelSize / 2.0;
    
    #ifndef SIMPLE_TEXTURE
    float flushDis = sdEllipse(uv, vec2(0.0, 0.0), flushSize * vec2(0.48, 0.24));
    float flushFade = flushSize * 0.2;
    
    vec2 lineDirection = normalize(vec2(-0.54, -0.8));
    float lineOrigin = dot(vec2(0.0), lineDirection);
    float linePos = lineOrigin + 0.03;
    float lineStep = 0.08;
    float lineCur = dot(uv, lineDirection);
    float lineDis = 65535.0;
    
    for(int i = ZERO - 8; i <= 8; i++)
    {
        linePos = float(i) * lineStep;
        lineDis = min(lineDis, abs(linePos - lineCur));
    }
        
    outputColor = mix(outputColor, vec3(0.0), smoothstep(0.0, -pixelSize, lineDis - line * 0.5 * smoothstep(0.0, -flushFade, flushDis)));
    
    outputColor = mix(vec3(1.0), outputColor, smoothstep(pixelSize, 0.0, flushDis));
    #endif
}

ObjectInfo ear(vec3 p, mat4 sdf_transform, float pixelSize, bool castShadow, bool withMat, out float outlineDis)
{
    ObjectInfo info = DEFAULT_INFO;
    vec3 transPoint = (sdf_transform * vec4(p, 1.0)).xyz;
    
    float earDis = sdUnevenCapsule(transPoint.xy, vec2(0.16, 0.1), vec2(-0.05, -0.1), 0.108, 0.08);
    earDis = opExtrusion(transPoint, earDis, 0.005) - 0.01;
    
    info.dis = earDis;
    outlineDis = info.dis;
    
    if(withMat)
    {
        if(transPoint.z < 0.0)
        {
            vec3 point = vec3(0.0, 0.0, 0.0);
            float size = 0.24;
            
            vec3 vector = transPoint - point;
            vec2 uv = vector.xy / size;
            
            getEarTexture(uv, pixelSize / size, info.material.color0.rgb);
        }
    }
    
    return info;
}

ObjectInfo animeHead(vec3 p, mat4 sdf_transform, vec3 view, float pixelSize, FacialInfo facialInfo, bool castShadow, bool withMat, out float outlineDis)
{
    ObjectInfo info = DEFAULT_INFO;
    vec3 transPoint = (sdf_transform * vec4(p, 1.0)).xyz;
    
    // 大致轮廓
    float skinDis = 65535.0f;
    
    // 额头
    skinDis = min(skinDis, sdEllipsoid(transPoint, vec3(0.0, 1.16, 0.04), vec3(0.72, 0.64, 0.72)));
   
    // 下巴
    float jawDis = sdRoundCone(transPoint, vec3(0.0, 0.5, -0.1), vec3(0.0, 0.12, -0.45), 0.5, 0.03);
    jawDis = smin(jawDis, sdEllipsoid(transPoint, vec3(0.0, 0.36, -0.3), vec3(0.2, 0.35, 0.2)), 0.3);
    
    skinDis = smin(skinDis, jawDis, 0.54);
    
    // 脸颊
    skinDis = smin(skinDis, transPoint.x < 0.0 ? sdEllipsoid(transPoint, vec3(-0.24, 0.4, -0.26), vec3(0.2, 0.24, 0.25)) :
                                               sdEllipsoid(transPoint, vec3(0.24, 0.4, -0.26), vec3(0.2, 0.24, 0.25)), 0.3);
                                 
    // 下颚切除
    float jawSubDis = sdPlane(transPoint, vec3(0.0, 0.0, 0.0), vec3(0.0, 0.928477, -0.371391));
    jawSubDis = smin(jawSubDis, min(sdPlane(transPoint, vec3(0.0, -0.2, 0.0), vec3(0.496139, 0.868243, 0.0)),
                                    sdPlane(transPoint, vec3(0.0, -0.2, 0.0), vec3(-0.496139, 0.868243, 0.0))), 0.1);
    jawSubDis = smin(jawSubDis, sdPlane(transPoint, vec3(0.0, 0.0, 0.0), vec3(0.0, 0.7071068, -0.7071068)), 0.1);
    
    skinDis = ssub(skinDis, jawSubDis, 0.2);
    
    // 鼻梁
    float noseSubDis = sdCapsule(transPoint, vec3(-1.0, 0.7, -0.8), vec3(1.0, 0.7, -1.0), 0.08);
    
    skinDis = ssub(skinDis, noseSubDis, 0.58);
    
    // 鼻子
    float noseDis;
    
    float nosePart0Dis = sdPyramid(transPoint, vec3(0.0, 0.59, -0.6),
                                               vec3(-0.08, 0.39, -0.6),
                                               vec3(0.0, 0.3, -0.6),
                                               vec3(0.08, 0.39, -0.6),
                                               vec3(0.0, 0.45, -0.75));
                                               
    float nosePart1Dis = sdPyramid(transPoint, vec3(0.0, 0.50, -0.6),
                                               vec3(-0.1, 0.37, -0.6),
                                               vec3(0.0, 0.33, -0.64),
                                               vec3(0.1, 0.37, -0.6),
                                               vec3(0.0, 0.45, -0.8));
    
    
    noseDis = smin(nosePart0Dis, nosePart1Dis, 0.1);
    skinDis = smin(skinDis, noseDis, 0.05);
    
    if(withMat)
    {
        vec3 viewDir = (sdf_transform * vec4(-view, 0.0)).xyz;
        vec3 normal = viewDir;
        normal.y = 0.0;
        normal = normalize(normal);
        vec3 tangent = normalize(cross(normal, vec3(0.0, 1.0, 0.0)));
        vec3 bitangent = normalize(cross(tangent, normal));
        
        if(transPoint.z < -0.1)
        {
            // 红晕
            float t = normal.x;
            vec3 point = triLerp(vec3(0.36, 0.48, -0.54), vec3(0.38, 0.48, -0.54), vec3(0.38, 0.48, -0.24), t);
            float size = 0.32;
            vec3 vector = transPoint - point;
            vec2 uv = vec2(dot(vector, tangent), dot(vector, bitangent)) / size;
            
            if(transPoint.x > 0.0 && abs(uv.x) < 1.0 && abs(uv.y) < 1.0) getFlushTexture(uv, pixelSize / size, facialInfo.flushSize, t, info.material.color0.rgb);
            
            t = -normal.x;
            point = triLerp(vec3(-0.36, 0.48, -0.54), vec3(-0.38, 0.48, -0.54), vec3(-0.38, 0.48, -0.24), t);
            size = 0.32;
            vector = transPoint - point;
            uv = vec2(dot(vector, tangent), dot(vector, bitangent)) / size;
            uv.x = uv.x;
            
            if(transPoint.x < 0.0 && abs(uv.x) < 1.0 && abs(uv.y) < 1.0) getFlushTexture(uv, pixelSize / size, facialInfo.flushSize, t, info.material.color0.rgb);
            
            
            // 鼻子纹理
            size = 0.2;
            uv = (transPoint.xy - vec2(0.0, 0.45)) / size;
            
            if(abs(uv.x) < 1.0 && abs(uv.y) < 1.0) getNoseTexture(uv, pixelSize / size, normal.x, info.material.color0.rgb);
            
            // 嘴巴纹理
            point = vec3(0.0, 0.22, -0.59);
            size = 0.64;
            
            vector = transPoint - point;
            uv = vec2(dot(vector, tangent), dot(vector, bitangent)) / size;
            LipInfo lipInfo = LipInfo(facialInfo.lipStart, facialInfo.lipEnd, facialInfo.lipDir);
            if(normal.z < 0.02 && abs(uv.x) < 1.0 && abs(uv.y) < 0.2) getLipTexture(uv, lipInfo, pixelSize / size, normal.x, info.material.color0.rgb);
            
            // 伤疤纹理
            t = sign(normal.x) * pow(abs(normal.x), 4.0);
            point = triLerp(vec3(-0.3, 1.14, -0.69), vec3(0.0, 1.14, -0.69), vec3(0.3, 1.14, -0.69), t);
            size = 0.32;
            vector = transPoint - point;
            uv = (vector.xy) / size;
            
            vec2 sc = vec2(dot(vector, tangent), dot(vector, bitangent)) / size;
            
            if(abs(uv.x) < 1.0 && abs(uv.y) < 1.0) getScarTexture(uv, sc, pixelSize / size, info.material.color0.rgb);
            
            // if(length(vector) < 0.05) info.material.color0 = vec4(0.0);
            
            if(transPoint.x > 0.0)
            {
                vec3 point = vec3(0.332, 0.67, -0.5);
                float size = 0.32;
            
                vec3 vector = transPoint - point;
                vec2 uv = vec2(dot(vector, tangent), dot(vector, bitangent)) / size;
            
                EyeInfo eyeInfo = EyeInfo(facialInfo.leftEyeBallPos, facialInfo.leftEyeBallScale, facialInfo.leftUpLidPos, facialInfo.leftDownLidPos,
                                      vec2(-1.0, 0.05),
                                      facialInfo.leftBrowStart, facialInfo.leftBrowEnd, facialInfo.leftBrowDir);
                if(normal.z < 0.02 && abs(uv.x) < 1.5 && abs(uv.y) < 1.5) getEyeTexture(uv, eyeInfo, pixelSize / size, normal.x, info.material.color0.rgb);
            }
        
            else
            {
                vec3 point = vec3(-0.332, 0.67, -0.5);
                float size = 0.32;
            
                vec3 vector = transPoint - point;
                vec2 uv = vec2(dot(vector, tangent), dot(vector, bitangent)) / size;
                uv.x = -uv.x;
            
                facialInfo.rightEyeBallPos *= vec2(-1.0, 1.0);
                facialInfo.rightBrowStart *= vec2(-1.0, 1.0);
                facialInfo.rightBrowDir *= vec2(-1.0, 1.0);
                facialInfo.rightBrowEnd  *= vec2(-1.0, 1.0);
            
                EyeInfo eyeInfo = EyeInfo(facialInfo.rightEyeBallPos, facialInfo.rightEyeBallScale, facialInfo.rightUpLidPos, facialInfo.rightDownLidPos,
                                      vec2(1.0, 0.05),
                                      facialInfo.rightBrowStart, facialInfo.rightBrowEnd, facialInfo.rightBrowDir);
                if(normal.z < 0.02 && abs(uv.x) < 1.5 && abs(uv.y) < 1.5) getEyeTexture(uv, eyeInfo, pixelSize / size, -normal.x, info.material.color0.rgb);
            }
        }
        
        
        // 头发
        float hairDis = sdPlane(transPoint, vec3(0.0, 0.4, -0.13), vec3(0.0, -0.1483405, -0.9889364));
        hairDis = smin(hairDis, sdPlane(transPoint, vec3(0.0, 1.25, 0.05), vec3(0.0, -0.7808688, -0.6246951)), 0.1);
        hairDis = ssub(hairDis, sdPlane(transPoint, vec3(0.0, 0.28, 0.05), vec3(0.0, 0.7808688, 0.6246951)), 0.1);
        info.material.color0.rgb = mix(info.material.color0.rgb, vec3(0.0), smoothstep(pixelSize, 0.0, hairDis));
        
        #ifdef CROSSLINE
        if(transPoint.z < -0.2)
        {
            float horLineDis = abs(transPoint.y - 0.45);
            float horLineThres = mix(0.0, 0.005, pow(1.0 - abs(transPoint.x) / 0.5, 0.5));
            
            info.material.color0 = mix(info.material.color0, vec4(0.0), smoothstep(horLineThres + 0.005, horLineThres, horLineDis));
            
            float verLineDis = abs(transPoint.x);
            float verLineThres = mix(0.0, 0.005, pow(1.0 - abs(transPoint.y - 0.6) / 0.6, 0.5));
            
            info.material.color0 = mix(info.material.color0, vec4(0.0), smoothstep(verLineThres + 0.005, verLineThres, verLineDis));
        }
        #endif
    }
    
    info.dis = skinDis;
    outlineDis = info.dis;
    
    float earOutline;
    if(transPoint.x > 0.0) info = objectMin(info, ear(transPoint, transform_Ear, pixelSize, castShadow, withMat, earOutline));
    else
    {
        vec3 transPoint_m = transPoint;
        transPoint_m.x = -transPoint_m.x;
        info = objectMin(info, ear(transPoint_m, transform_Ear, pixelSize, castShadow, withMat, earOutline));
    }
    
    outlineDis = min(earOutline, outlineDis);
    return info;
}

ObjectInfo neck(vec3 p, mat4 sdf_transform, float pixelSize, bool castShadow, bool withMat, out float outlineDis)
{
    ObjectInfo info = DEFAULT_INFO;
    vec3 transPoint = (sdf_transform * vec4(p, 1.0)).xyz;
    
    info.dis = sdCapsule(transPoint, vec3(0.0, 0.0, 0.0), vec3(0.0, 0.5, 0.0), 0.18);
    
    outlineDis = info.dis;
    return info;
}

ObjectInfo body(vec3 transPoint, float pixelSize, bool castShadow, bool withMat, out float outlineDis)
{
    ObjectInfo info = DEFAULT_INFO;
    
    info.dis = sdCapsule(transPoint, vec3(-0.61, -0.4, 0.0), vec3(0.0, -0.29, 0.0), 0.28);
    info.dis = smin(info.dis, sdCapsule(transPoint, vec3(0.61, -0.4, 0.0), vec3(0.0, -0.29, 0.0), 0.28), 0.01);
    
    
    float chestDis = sdSegment(transPoint.xz, vec2(-0.55, 0.0), vec2(0.55, 0.0)) - 0.27;
    float h = 0.3;
    vec2 chestCoord = vec2(chestDis, abs(transPoint.y - (-0.38 - h)) - h);
    chestDis = min(max(chestCoord.x, chestCoord.y),0.0) + length(max(chestCoord, 0.0));
    chestDis = smin(chestDis, sdCapsule(transPoint, vec3(-0.45, -0.5, -0.1), vec3(0.45, -0.5, -0.1), 0.14), 0.3);
    info.dis = smin(info.dis, chestDis, 0.1);
    
    
    info.dis = ssub(info.dis, min(sdSphere(transPoint, vec3(0.55, 0.1, 0.0), 0.1), sdSphere(transPoint, vec3(-0.55, 0.1, 0.0), 0.1)), 0.4);
    info.dis = ssub(info.dis, min(sdPlane(transPoint, vec3(-0.85, -0.3, 0.0), vec3(0.8944272, 0.4472136, 0.0)), sdPlane(transPoint, vec3(0.85, -0.3, 0.0), vec3(-0.8944272, 0.4472136, 0.0))), 0.1);
    
    float armDis = transPoint.x > 0.0 ?
                   sdCapsule(transPoint, vec3(0.75, -0.4, 0.02), vec3(0.85, -0.9, 0.02), 0.2) :
                   sdCapsule(transPoint, vec3(-0.75, -0.4, 0.02), vec3(-0.85, -0.9, 0.02), 0.2);
    info.dis = smin(info.dis, armDis, 0.1);
    
    if(withMat)
    {
        float line = outlineStrength * pixelSize / 2.0 * 0.75;
        float collarDis = sdVesicaSegment(transPoint, vec3(-0.95, -0.1, 0.0), vec3(0.95, -0.1, 0.0), 0.6);
        info.material.color0 = mix(info.material.color0, vec4(0.0), smoothstep(pixelSize, 0.0, -collarDis));
        collarDis = sub(collarDis, sdVesicaSegment(transPoint, vec3(0.0, -0.6, -0.38), vec3(0.0, 0.2, 0.1), 0.32));
        info.material.color0 = mix(info.material.color0, vec4(0.0), smoothstep(line, line - pixelSize, abs(collarDis)));
        
        float stripDis = sdVesicaSegment(transPoint, vec3(-0.69, -0.1, 0.0), vec3(0.69, -0.1, 0.0), 0.58);
        stripDis = sub(stripDis, sdVesicaSegment(transPoint, vec3(-0.55, -0.1, 0.0), vec3(0.55, -0.1, 0.0), 0.54));
        if(abs(transPoint.x) > 0.4 || transPoint.y < -0.2) info.material.color0 = mix(info.material.color0, vec4(0.0), smoothstep(pixelSize, 0.0, collarDis) * smoothstep(pixelSize, -pixelSize, stripDis));
        
        float collarHeight = mix(-0.28, -0.24, smoothstep(0.0, 0.4, abs(transPoint.x)));
        info.material.color0 = mix(info.material.color0, vec4(0.0), smoothstep(0.0, pixelSize, collarDis) * smoothstep(line, line - pixelSize, abs(transPoint.y - collarHeight)));
        
        float stripHeight = mix(-0.38, -0.34, smoothstep(0.0, 0.44, abs(transPoint.x)));
        info.material.color0 = mix(info.material.color0, vec4(0.0), smoothstep(0.0, pixelSize, collarDis) * smoothstep(0.04, 0.04 - pixelSize, abs(transPoint.y - stripHeight)));
    }
    
    outlineDis = info.dis;
    return info;
}

// Base March
ObjectInfo sceneBaseMap(vec3 point, vec3 view, float pixelSize, bool castShadow, bool withMat, inout float outlineDis)
{
    float headOutline;
    ObjectInfo headInfo = animeHead(point, transform_Head, view, pixelSize, defaultFacialInfo, castShadow, withMat, headOutline);
    
    float neckOutline;
    ObjectInfo neckInfo = neck(point, transform_Neck, pixelSize, castShadow, withMat, neckOutline);
    
    vec3 transPoint = (transform_Root * vec4(point, 1.0)).xyz;
    
    float bodyOutline;
    ObjectInfo bodyInfo = body(transPoint, pixelSize, castShadow, withMat, bodyOutline);
    
    ObjectInfo info = objectSmoothMinWithoutBlend(bodyInfo, neckInfo, 0.1);
    info = objectSmoothMinWithoutBlend(headInfo, info, 0.05);

    outlineDis = smin(bodyOutline, neckOutline, 0.1);
    outlineDis = smin(headOutline, outlineDis, 0.05);
    return info;
}

vec3 march(vec3 start, vec3 ray, vec3 front, vec2 screenCoord, float pixelSize, inout vec3 pos, inout float len)
{
    len = 0.0;
    float dis = 0.0;
    vec3 curPos = vec3(0.0);
    
    ObjectInfo curSolidInfo;
    ObjectInfo lastSolidInfo;
    
    float stepDis;
    
    int stepCount = 0;
    
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
        
        lastSolidInfo = curSolidInfo;
        curSolidInfo = sceneBaseMap(curPos, front, curPixelSize, false, false, outlineDis);
        
        dis = curSolidInfo.dis;
        
        if(dis < curPixelSize)
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

        stepDis = dis;
        len += stepDis;
        stepCount += 1;
    }
    
    vec3 outputColor = getColorAtPos(pos, ray, front, len, screenCoord, curPixelSize, dis, outlineHitFlag, disForRealHit, lenForRealHit);
    return outputColor;
}

Material sceneBaseMaterial(vec3 point, vec3 view, float pixelSize, float len, vec2 screenCoord)
{
    if(len >= MAX_DISTANCE) {
        Material outMat;
        outMat.color0 = BACKGROUND_COLOR;
        outMat.index = 0;
        return outMat;
    } 
    
    float outlineDis;
    return sceneBaseMap(point, view, pixelSize, false, true, outlineDis).material;
}

vec3 getColorAtPos(vec3 pos, vec3 ray, vec3 front, float len, vec2 screenCoord, float pixelSize, float dis, bool outlineHit, float disWhenHit, float lenWhenHit)
{
    Material material = sceneBaseMaterial(pos, front, pixelSize, len, screenCoord);
    vec4 outlineColor = vec4(0.0);
    
    if(outlineHit)
    {
        float outlineThreshold = mix(0.0, outlineStrength, clamp((len - lenWhenHit) / outlineThreshold, 0.0, 1.0));
        outlineColor = vec4(OUTLINE_COLOR.rgb, clamp(outlineThreshold - disWhenHit - 0.25, 0.0, 1.0));
    }
    
    vec3 solidColor = vec3(0.0);
    if(material.index == 0) solidColor = material.color0.rgb;
    else
    {
        solidColor = material.color0.rgb;
    }
    
    return mix(solidColor, outlineColor.rgb, outlineColor.a);
}

// Hair March
const float stripCount = 28.0;
const float bangCount = 4.0;
void getSideTexture(vec2 uv, float pixelSize, vec2 start, vec2 dir, vec2 end, vec2 endDiff, float widthStart, float widthEnd, inout vec4 outputColor)
{
    float sideCurve_0;
    vec2 sideEnd_0 = end - endDiff / 2.0;
    vec2 sideDir_0 = dir - endDiff / 8.0;
    float sideDis_0 = abs(sdBezier(uv, start, sideEnd_0, sideDir_0, sideCurve_0));
    float sideWidth_0 = mix(widthStart, widthEnd, smoothstep(0.0, 1.0, sideCurve_0));
    sideDis_0 = sideDis_0 - sideWidth_0;
    vec2 sideOut_0 = normalize(sideEnd_0 - start);
    float sideCut_0 = dot(uv - sideEnd_0, sideOut_0);
    sideDis_0 = max(sideDis_0, sideCut_0);
    
    
    float sideCurve_1;
    vec2 sideEnd_1 = end + endDiff / 2.0;
    vec2 sideDir_1 = dir + endDiff / 8.0;
    float sideDis_1 = abs(sdBezier(uv, start, sideEnd_1, sideDir_1, sideCurve_1));
    float sideWidth_1 = mix(widthStart, widthEnd, smoothstep(0.0, 1.0, sideCurve_1));
    sideDis_1 = sideDis_1 - sideWidth_1;
    vec2 sideOut_1 = normalize(sideEnd_1 - start);
    float sideCut_1 = dot(uv - sideEnd_1, sideOut_1);
    sideDis_1 = max(sideDis_1, sideCut_1);
    
    float sideDis = min(sideDis_0, sideDis_1);
    float factor = smoothstep(pixelSize, 0.0, sideDis);
    
    outputColor.rgb = mix(outputColor.rgb * outputColor.a, vec3(0.0), factor);
    outputColor.a = clamp(outputColor.a + factor, 0.0, 1.0);
    
}
void getBangTexture(vec2 uv, float pixelSize, float start, float range, float width, float len, float cut, inout vec4 outputColor)
{
    float upperEdge = start + range;
    float downEdge = start;
    
    // 侧边界限
    float factor = smoothstep(pixelSize, 0.0, uv.x  - start - mix(range * 1.08, range, linerstep(1.0, 1.0 - len, uv.y)));
    outputColor.rgb = mix(outputColor.rgb * outputColor.a, vec3(0.0), factor);
    outputColor.a = clamp(outputColor.a + factor, 0.0, 1.0);
    
    // 开始边界
    factor = smoothstep(pixelSize, 0.0, uv.x - start - mix(0.0, width, linerstep(1.0 - cut, 1.0 - len, uv.y)));
    outputColor.rgb = mix(outputColor.rgb * outputColor.a, vec3(1.0), factor);
    outputColor.a = clamp(outputColor.a - factor, 0.0, 1.0);
    
    // 下边界
    factor = smoothstep(pixelSize, 0.0, uv.y - 1.0 + len);
    outputColor.rgb = mix(outputColor.rgb * outputColor.a, vec3(1.0), factor);
    outputColor.a = clamp(outputColor.a - factor, 0.0, 1.0);
    
    float cutSpace = (range - width) * 0.4;
    vec2 cutPos = vec2(width + start, 1.0 - len);
    float cutWidth = (range - width) * 0.05;
    float cutThres = 0.8 * len;
    float cutDis;
    for(int i = ZERO; i < 2; i++)
    {
        cutPos.x += cutSpace;
        cutDis = sdSegment(uv, cutPos, vec2(cutPos.x, 1.0));
       
        factor = smoothstep(pixelSize, 0.0, cutDis - mix(cutWidth, 0.0, linerstep(1.0 - len, 1.0 - cutThres, uv.y)));
        outputColor.rgb = mix(outputColor.rgb * outputColor.a, vec3(1.0), factor);
        outputColor.a = clamp(outputColor.a - factor, 0.0, 1.0);
    
        cutSpace /= 1.08;
        cutThres *= 1.08;
        cutWidth /= 1.08;
    }
}

void getHairTexture(vec2 uv, float pixelSize, float t, float ang, inout vec4 outputColor)
{
    #ifdef SHOWUV
    outputColor = vec4(uv.x, 0.0, uv.y, 1.0);
    return;
    #endif
    
    outputColor = vec4(0.0);
    float line = outlineStrength * pixelSize / 2.0;
    
    vec2 uv_m = vec2(1.0 - uv.x, uv.y);
    t = sign(t) * pow(abs(t), 2.0);
    
    // 长条，先整出一个大致的形状
    float stripCoord = mix(mod(uv.x + 0.5, 1.0), smoothstep(0.0, 1.0, mod(uv.x + 0.5, 1.0)), 0.4);
    float stripIndex = round(stripCoord * stripCount);
    float stripPos = stripIndex / stripCount;
    float stripWidth = 0.5 / stripCount;
    float factor;
    float stripFactor = 0.17;
    float stripStart = stripCount * stripFactor;
    float stripEnd = stripCount - stripStart;
    if(stripIndex <= stripStart || stripIndex >= stripEnd)
    {
        float stripDis = sdSegment(vec2(stripCoord, uv.y), vec2(stripPos, 0.0), vec2(stripPos, 1.0)) - mix(1.4 * stripWidth, 0.4 * stripWidth, 1.0 - uv.y);
        float factor = smoothstep(pixelSize, 0.0, stripDis);
        outputColor.rgb = mix(outputColor.rgb * outputColor.a, vec3(0.0), factor);
        outputColor.a = clamp(outputColor.a + factor, 0.0, 1.0);
    }
    
    // 砍掉尾端
    factor = smoothstep(pixelSize, 0.0, uv.y - mix(0.45, 0.19, smoothstep(0.5, 0.0, abs(uv.x - 0.5))));
    outputColor.rgb = mix(outputColor.rgb * outputColor.a, vec3(1.0), factor);
    outputColor.a = clamp(outputColor.a - factor, 0.0, 1.0);
    
    // 刘海
    vec4 bangColor = vec4(0.0);
    float bangStart = 0.0;
    float bangRange_0 = triLerp(0.22, 0.14, 0.22, -t);
    float bangRange_1 = triLerp(0.22, 0.14, 0.22, t);
    float bangCut = 0.09;
    float bangWidth_0 = triLerp(0.02, 0.04, 0.08, -t);
    float bangWidth_1 = triLerp(0.02, 0.04, 0.08, t);
    getBangTexture(uv, pixelSize, bangStart, bangRange_0, bangWidth_0, 0.23, bangCut, bangColor);
    getBangTexture(uv_m, pixelSize, bangStart, bangRange_1, bangWidth_1, 0.23, bangCut, bangColor);
    
    outputColor.rgb = mix(outputColor.rgb * outputColor.a, bangColor.rgb, bangColor.a);
    outputColor.a = clamp(outputColor.a + bangColor.a, 0.0, 1.0);
    
    // 盖子
    
    vec4 sideColor = vec4(0.0);
    float sideWidthStart = 0.02;
    float sideWidthEnd = 0.01;
    vec2 sideStart_0 = vec2(bangStart + bangRange_0 + (sideWidthStart + sideWidthEnd) / 2.0, 1.0);
    vec2 sideStart_1 = vec2(bangStart + bangRange_1 + (sideWidthStart + sideWidthEnd) / 2.0, 1.0);
    float sideOffset_0 = triLerp(0.8, 1.0, 0.8, -t) * sideWidthStart;
    float sideOffset_1 = triLerp(0.8, 1.0, 0.8, t) * sideWidthStart;
    vec2 sideDir_0 = vec2(sideStart_0.x + 2.0 * sideOffset_0, 0.5);
    vec2 sideDir_1 = vec2(sideStart_1.x + 2.0 * sideOffset_1, 0.5);
    vec2 sideEnd_0 = vec2(sideStart_0.x + -4.0 * sideOffset_0, 0.3);
    vec2 sideEnd_1 = vec2(sideStart_1.x + -4.0 * sideOffset_1, 0.3);
    vec2 sideDiff = vec2(0.03, -0.03);
    
    if(uv.x < 0.5)
    {
        factor = linerstep(1.0 - sideStart_0.x, 0.69, uv_m.x);
    }
    else
    {
        factor = linerstep(1.0 - sideStart_1.x, 0.69, uv.x);
    }
    if(factor < 1.0 && factor > 0.0)
    {
        float coverStart = 0.25;
        float coverEnd = 0.26;
                            
        factor *= factor;
        factor = smoothstep(pixelSize, 0.0, (1.0 - mix(coverEnd, coverStart, factor)) - uv.y);
        outputColor.rgb = mix(outputColor.rgb * outputColor.a, vec3(0.0), factor);
        outputColor.a = clamp(outputColor.a + factor, 0.0, 1.0);
    }
    
    // 侧刘海
    getSideTexture(uv, pixelSize, sideStart_0, sideDir_0, sideEnd_0, sideDiff, sideWidthStart, sideWidthEnd, sideColor);
    getSideTexture(uv_m, pixelSize, sideStart_1, sideDir_1, sideEnd_1, sideDiff, sideWidthStart, sideWidthEnd, sideColor);
    
    outputColor.rgb = mix(outputColor.rgb * outputColor.a, sideColor.rgb, sideColor.a);
    outputColor.a = clamp(outputColor.a + sideColor.a, 0.0, 1.0);
    
    // 高光
    float specHeight = (sin(13.0 * (2.0 * PI * uv.x + ang)) * 0.6 + sin(43.0 * (2.0 * PI * uv.x + ang))) * 0.006 + 0.86;
    factor = smoothstep(0.0, -pixelSize, abs(uv.y - specHeight) - (sin(9.0 * (2.0 * PI * uv.x + ang)) + 0.1) * line * 3.0 * smoothstep(0.04, 0.08, uv.x)  * smoothstep(0.96, 0.92, uv.x));
    outputColor.rgb = mix(outputColor.rgb * outputColor.a, vec3(1.0), factor);
    
    
}

float getPolar(vec3 dir, vec3 front, vec3 origin, vec3 point)
{  
    vec3 vector = point - origin;
    vec3 dir_y = normalize(cross(front, dir));
    vec3 dir_x = cross(dir_y, dir);
    
    return atan(dot(point, dir_y), dot(point, dir_x)) / PI * 0.5 + 0.5;
}

float getVert(vec3 dir, vec3 origin, vec3 point, float range, float offset)
{
    float proj = dot(dir, point - origin);
    return (proj + offset) / range;
}

ObjectInfo animeHair(vec3 p, mat4 sdf_transform, vec3 view, float pixelSize, bool castShadow, bool withMat)
{
    vec3 transPoint = (sdf_transform * vec4(p, 1.0)).xyz;
    
    ObjectInfo upper = DEFAULT_INFO;
    vec3 upper_0 = vec3(0.0, 1.17, 0.04);
    vec3 upper_1 = upper_0 + vec3(0.0, 0.0, 0.1) + vec3(hairDir_0 * 1.37, 0.0);
    float upperRad = 0.78;
    
    upper.dis = sdRoundCone(transPoint, upper_0, upper_1, upperRad, 0.76);
    
    ObjectInfo lower = DEFAULT_INFO;
    vec3 lower_0 = upper_1;
    vec3 lower_1 = upper_1 + vec3(0.0, 0.0, 0.1) + vec3(hairDir_1 * 1.16, 0.0);
    float lowerRad = 0.96;
    lower.dis = sdRoundCone(transPoint, lower_0, lower_1, 0.76, lowerRad);
    if(withMat)
    {
        vec3 upperVect = upper_0 - upper_1;
        vec3 lowerVect = lower_0 - lower_1;
        vec3 upperDir = normalize(upperVect);
        vec3 lowerDir = normalize(lowerVect);
        float upperLen = (upperVect.x + upperVect.y + upperVect.z) / (upperDir.x + upperDir.y + upperDir.z);
        float lowerLen = (lowerVect.x + lowerVect.y + lowerVect.z) / (lowerDir.x + lowerDir.y + lowerDir.z);
        float verRange = upperLen + lowerLen + upperRad + lowerRad;
        upper.material.t0 = getPolar(upperDir, vec3(0.0, 0.0, -1.0), upper_1, transPoint);
        lower.material.t0 = getPolar(lowerDir, vec3(0.0, 0.0, -1.0), lower_1, transPoint);
        
        upper.material.t1 = getVert(upperDir, upper_1, transPoint, verRange, lowerLen + lowerRad);
        lower.material.t1 = getVert(lowerDir, lower_1 - lowerRad * lowerDir, transPoint, verRange, 0.0);
    }
    
    ObjectInfo info = objectSmoothMin(upper, lower, 0.1);
    
    if(withMat)
    {
        if(lower.dis - 0.8 > upper.dis || lower.dis - 0.1 < upper.dis && abs(upper.material.t0 - lower.material.t0) > 0.2) info.material.t0 = objectSmoothMinWithoutBlend(upper, lower, 0.1).material.t0;
        vec3 viewDir = (sdf_transform * vec4(-view, 0.0)).xyz;
        vec3 normal = viewDir;
        normal.y = 0.0;
        normal = normalize(normal);
        
        float verRange = upper_0.y + 0.78 - lower_1.y + 0.96;
        
        vec2 uv = vec2(info.material.t0, info.material.t1);
        getHairTexture(uv, pixelSize / verRange, normal.x, atan(normal.z, normal.x), info.material.color0);
    }
    
    return info;
}

ObjectInfo sceneHairMap(vec3 point, vec3 view, float pixelSize, bool castShadow, bool withMat)
{  
    ObjectInfo info = animeHair(point, transform_Head, view, pixelSize, castShadow, withMat);

    return info;
}

vec4 marchHair(vec3 start, vec3 ray, vec3 front, vec2 screenCoord, float direction, float pixelSize, inout vec3 pos, inout float len)
{
    float dis = 0.0;
    vec3 curPos = vec3(0.0);
    
    ObjectInfo curSolidInfo;
    
    float stepDis;
    
    int stepCount = 0;
    
    float curPixelSize;
    
    float theta = dot(ray, front);
    

    while(len < MAX_DISTANCE && len >= 0.0 && stepCount <= MAX_STEP)
    {
        curPos = len * ray + start;
        pos = curPos;
        
        curPixelSize = len * theta * pixelSize;

        curSolidInfo = sceneHairMap(curPos, front, curPixelSize, false, false);
        
        dis = curSolidInfo.dis;
        
        if(dis < curPixelSize)
        {
            break;
        }
        

        stepDis = dis * 0.9 * direction;
        len += stepDis;
        stepCount += 1;
    }
    
    pixelSize = curPixelSize;
    vec4 outputColor = getHairAtPos(pos, ray, front, len, screenCoord, curPixelSize, dis);
    return outputColor;
}

Material sceneHairMaterial(vec3 point, vec3 view, float pixelSize, float len, vec2 screenCoord)
{
    if(len >= MAX_DISTANCE || len < 0.0) {
        Material outMat;
        outMat.color0 = vec4(0.0, 0.0, 0.0, 0.0);
        outMat.index = 0;
        return outMat;
    } 
    
    return sceneHairMap(point, view, pixelSize, false, true).material;
}

vec4 getHairAtPos(vec3 pos, vec3 ray, vec3 front, float len, vec2 screenCoord, float pixelSize, float dis)
{
    Material material = sceneHairMaterial(pos, front, pixelSize, len, screenCoord);
    vec4 outlineColor = vec4(0.0);
    
    vec4 solidColor = vec4(0.0);
    if(material.index == 0) solidColor = material.color0;
    else
    {
        solidColor = material.color0;
    }
    
    return mix(solidColor, outlineColor, outlineColor.a);
}

void update()
{
    outlineStrength = max(2.0, outlineStrength * pow(iResolution.x / 800.0, 0.5));
    float angle;
    
    // 相机
    positionWorld_Camera = positionLocal_Camera;
    rotationWorld_Camera = rotationLocal_Camera;
    
    
    // 根
    angle = -sin(iTime * 0.4) * PI / 8.0f;
    rotationLocal_Root = quaternionMul(vec4(0.0, sin(angle / 2.0), 0.0, cos(angle / 2.0)), rotationLocal_Root);

    float frameTime = floor(iTime * FRAME_RATE) / FRAME_RATE;
    float blinkFactor;
    float blinkTimeline = 2.55 * frameTime;
    float blinkTime = floor(blinkTimeline);
    if(hash11(blinkTime) > BLINK_THRESHOLD) blinkFactor = -1.0;
    else blinkFactor = -cos(fract(blinkTimeline) * 2.0 * PI);
    
    blinkFactor = 0.5 - blinkFactor * 0.5;
    
    defaultFacialInfo.rightUpLidPos = blinkFactor * defaultFacialInfo.rightUpLidPos;
    defaultFacialInfo.rightDownLidPos = blinkFactor * defaultFacialInfo.rightDownLidPos;
    defaultFacialInfo.leftUpLidPos = defaultFacialInfo.rightUpLidPos;
    defaultFacialInfo.leftDownLidPos = defaultFacialInfo.rightDownLidPos;
    
    vec2 browOffset = mix(vec2(0.0, -0.2), vec2(0.0, 0.0), blinkFactor);
    defaultFacialInfo.leftBrowStart += browOffset;
    defaultFacialInfo.leftBrowEnd += browOffset;
    defaultFacialInfo.leftBrowDir += browOffset;
    
    defaultFacialInfo.rightBrowStart += browOffset;
    defaultFacialInfo.rightBrowEnd += browOffset;
    defaultFacialInfo.rightBrowDir += browOffset;
    
    transform_Root = createModelInverseMat(quaternionMul(load(POINTER_ROT), rotationLocal_Root), positionLocal_Root);
    
    // 脖子
    transform_Neck = createModelInverseMat(rotationLocal_Neck, positionLocal_Neck) * transform_Root;
    
    // 头
    transform_Head = createModelInverseMat(rotationLocal_Head, positionLocal_Head) * transform_Neck;
    
    // 耳朵
    transform_Ear = createModelInverseMat(rotationLocal_Ear, positionLocal_Ear);
    
    // 头发
    angle = PI / 2.0 * 3.0 - (sin(frameTime * 3.0) * 0.5 + 0.5) * 0.04;
    hairDir_1 = vec2(cos(angle), sin(angle));
    
    #ifdef EYETEST
    // 眼睛测试
    defaultFacialInfo.leftEyeBallPos = vec2(cos(iTime), sin(iTime));
    defaultFacialInfo.leftUpLidPos = cos(iTime) * 0.5 + 0.5;
    defaultFacialInfo.leftDownLidPos = cos(iTime) * 0.5 + 0.5;
    defaultFacialInfo.leftEyeBallScale = mix(1.0, 0.6, clamp(cos(iTime), 0.0, 1.0));
    
    float browUp = (cos(4.0 * iTime) + 1.0) / 2.0;
    defaultFacialInfo.leftBrowStart.y += browUp * browUp * 0.5;
    defaultFacialInfo.leftBrowEnd.y += browUp * browUp * 0.5;
    defaultFacialInfo.leftBrowDir.y += browUp * 0.5;
    #endif
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    
    vec2 uv = (fragCoord.xy - iResolution.xy / 2.0) / iResolution.x;
    #ifdef MODELING
    
    float angle = -PI / 2.0;
    // angle = PI / 4.0;
    if(uv.x > 0.0) rotationLocal_Root = quaternionMul(vec4(0.0, sin(angle / 2.0), 0.0, cos(angle / 2.0)), rotationLocal_Root);
    
    #endif
    update();
    
    float delta = 1.0 / iResolution.x;
    float tanFov = tan(cameraFov / 360.0 * PI);
    vec3 ray;
    #ifdef MODELING
    if(abs(uv.x) < 1.0 / iResolution.x)
    {
        fragColor = MIN_COLOR;
        return;
    }
    if(uv.x < 0.0) ray = normalize(vec3(uv + vec2(0.25, 0.0), 0.5 / tanFov));
    else ray = normalize(vec3(uv - vec2(0.25, 0.0), 0.5 / tanFov));
    #else
    ray = normalize(vec3(uv, 0.5 / tanFov));
    #endif
    
    if(abs(uv.y) > 0.3)
    {
        fragColor = MIN_COLOR;
        return;
    }
    
    // 平面距离为1时，每个像素对应的大小
    float pixelSize = 2.0 * tanFov / iResolution.x;
    vec3 front = rotatePoint(vec3(0.0, 0.0, 1.0), vec3(0.0), rotationWorld_Camera);
    ray = rotatePoint(ray, vec3(0.0), rotationWorld_Camera);
    
    vec3 pos;
    float len;
    
    vec4 baseColor = vec4(march(positionWorld_Camera, ray, front, fragCoord / iResolution.xy, pixelSize, pos, len), 1.0);
    vec4 color = baseColor;
    
    #ifndef NOHAIR
    // len作为深度使用，单独march头发
    vec4 hairColor;

    // 反面，能想出这玩意真是人才
    float hairLen = HAIR_FAR;
    hairColor = marchHair(positionWorld_Camera, ray, front, fragCoord / iResolution.xy, -1.0, pixelSize, pos, hairLen);
    if(hairLen > 0.0 && hairLen <= len) color = mix(color, hairColor, hairColor.a);
    
    // 正面
    hairLen = 0.0;
    hairColor = marchHair(positionWorld_Camera, ray, front, fragCoord / iResolution.xy, 1.0, pixelSize, pos, hairLen);
    if(hairLen > 0.0 && hairLen <= len) color = mix(color, hairColor, hairColor.a);
    #endif
    
    color = mix(MIN_COLOR, MAX_COLOR, color);
    fragColor = color;
}
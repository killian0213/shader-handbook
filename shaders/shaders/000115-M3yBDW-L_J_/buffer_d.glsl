// Buffer D (buffer) — Lā Jī by SL0ANE
// https://www.shadertoy.com/view/M3yBDW

// 在这个Buffer做Raymarching
// 这样着色的时候能拿到深度图对边缘光之类的事帮助很大
// RGBA通道是输出分别为：步进长度，最近时的描边域距离，最近时的步进长度

mat4 getCameraTransform()
{
    vec4 rot = quaternionInverse(quaternionMul(load(POINTER_ROT), DEFAULT_ROT));
    vec3 cameraForward = rotatePoint(vec3(0.0, 0.0, 1.0), vec3(0.0), rot);
    return createModelMat(rot, vec3(0.0, 0.2, 0.0) - cameraForward * cameraDistance);
}

void update()
{
    cameraTransform = getCameraTransform();
    updateTime(iTime);
}

void march(vec3 start, vec3 ray, vec3 front, float pixelSize, inout float len, inout float outlineMinDis, inout float outlineMinLen)
{
    len = 0.0;
    float dis = 0.0;
    float outlineDis = 0.0;
    vec3 curPos = vec3(0.0);
    float planeScale = 0.0;
    
    float stepDis;
    
    int stepCount = 0;
    
    float curPixelSize;
    outlineMinDis = 65535.0;
    outlineMinLen = 0.0;
    float outlineActualDis = 65535.0;
    float outlineMinDisCache = 65535.0;
    float outlineMinLenCache = 0.0;
    float outlineActualDisCache = 65535.0;
    
    bool approchingFlag = false;
    
    float theta = dot(ray, front);
    
    int outlineHit = 0;

    while(len < MAX_DISTANCE && stepCount <= MAX_STEP)
    {
        curPos = len * ray + start;
        planeScale = len * theta;
        curPixelSize = planeScale * pixelSize;
        
        dis = sceneMap(curPos, iTime);
        
        if(dis < curPixelSize * 0.01)
        {
            return;
        }
        
        outlineDis = dis / planeScale;
        
        if((outlineMinDisCache <= outlineStrength && outlineActualDisCache <= dis && outlineMinLen == 0.0)
        || (outlineMinDis > outlineStrength && outlineMinDisCache <= (outlineStrength + pixelSize) && outlineActualDisCache <= dis))
        {
            // 开始远离后再记录，这样能区别打到物体上的和擦边的
            outlineMinDis = outlineMinDisCache;
            outlineMinLen = outlineMinLenCache;
            outlineActualDis = outlineActualDisCache;
        }
        
        if(outlineMinDisCache > outlineDis)
        {
            outlineMinDisCache = outlineDis;
            outlineMinLenCache = len;
            outlineActualDisCache = dis;
            approchingFlag = true;
        }

        stepDis = dis * 0.98;
        len += stepDis;
        stepCount += 1;
    }
    
    if(approchingFlag && outlineMinLen == 0.0)
    {
        outlineMinDis = outlineMinDisCache;
        outlineMinLen = outlineMinLenCache;
    }
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    update();
    
    vec3 ray;
    vec3 front;
    vec3 start;
    float pixelSize;
    getCameraParam(fragCoord, iResolution.xy, ray, front, start, pixelSize);
    
    float len = 0.0;
    float outlineMinDis = 0.0;
    float outlineMinLen = 0.0;
    
    march(start, ray, front, pixelSize, len, outlineMinDis, outlineMinLen);

    fragColor = vec4(len, outlineMinDis, outlineMinLen, 1.0);
}
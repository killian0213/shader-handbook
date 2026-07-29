// Image (image) — Lā Jī by SL0ANE
// https://www.shadertoy.com/view/M3yBDW

# define LIGHT_DIRECTION vec3(-0.1, -0.5, -1.0)
# define LIGHT_COLOR vec3(0.3, 0.48, 0.3)
# define LIGHT_STRENGTH 1.0
# define AMBIENT_COLOR vec3(0.7, 0.52, 0.7)

# define RIMLIGHT_COLOR vec3(1.0, 0.64, 0.70)
# define RIMLIGHT_THICKNESS 0.01
# define RIMLIGHT_FADE_START 0.01
# define RIMLIGHT_FADE_END 0.4

# define BACKGROUND_COLOR vec3(0.94, 0.86, 0.82)
# define OUTLINE_COLOR vec3(0.3, 0.16, 0.24)

# define OUTLINE_FADE_START 0.01
# define OUTLINE_FADE_END 0.4

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

float getShadow(vec3 ro, vec3 rd, float mint, float maxt, float w )
{
    float res = 1.0;
    float ph = 1e20;
    float t = mint;
    for( int i=0; i<128 && t<maxt; i++ )
    {
        float h = sceneMap(ro + rd*t, iTime);
        if( h<0.001 )
            return 0.0;
        float y = h*h/(2.0*ph);
        float d = sqrt(h*h-y*y);
        res = min( res, d/(w*max(0.0,t-y)) );
        ph = h;
        t += h * 0.98;
    }
    return res;
}

vec3 getNormal(vec3 point, float pixelSize)
{
    vec3 deltaX = vec3(pixelSize, 0.0, 0.0) / 4.0;
    vec3 deltaY = vec3(0.0, pixelSize, 0.0) / 4.0;
    vec3 deltaZ = vec3(0.0, 0.0, pixelSize) / 4.0;
    
    float outlineDis;
    
    float x = sceneMap(point + deltaX, iTime) - sceneMap(point - deltaX, iTime);
    float y = sceneMap(point + deltaY, iTime) - sceneMap(point - deltaY, iTime);
    float z = sceneMap(point + deltaZ, iTime) - sceneMap(point - deltaZ, iTime);
    
    return normalize(vec3(x, y, z));
}

Material sceneMaterial(vec3 pos, vec3 front, vec3 normal, float pixelSize, float planeScale)
{
    ChickenInfo info = getChickenInfo(pos, iTime);
    
    float halfPixelSize = pixelSize / 2.0f;
    float outlineThickness = -dot(normal, front);
    outlineThickness -= 1.0;
    outlineThickness = (outlineThickness * outlineThickness * 0.8 + 1.0);
    outlineThickness = outlineThickness > 0.0 ? outlineStrength * planeScale * outlineThickness : 0.0;
    
    #define BODY_COLOR vec3(0.992, 0.79, 0.32)
    
    // 身体部分
    Material bodyMat;
    bodyMat.color0 = vec4(BODY_COLOR, 1.0);
    bodyMat.index = 0;
    
    // 画眼睛
    vec3 posSclera = vec3(abs(pos.x), pos.y, pos.z) - vec3(0.9, 0.4, 1.2);
    float sdSclera = sdEllipsoid(posSclera, vec3(0.56, 0.6, 0.56));
    bodyMat.color3.a = mix(0.0, 1.0, smoothstep(halfPixelSize, -halfPixelSize, sdSclera - outlineThickness));
    bodyMat.color3.rgb = mix(bodyMat.color3.rgb, OUTLINE_COLOR, smoothstep(halfPixelSize, 0.0, sdSclera - halfPixelSize - outlineThickness));
    bodyMat.color3.rgb = mix(bodyMat.color3.rgb, vec3(1.0, 0.98, 0.9), smoothstep(halfPixelSize, -halfPixelSize, sdSclera));
    bodyMat.color3.rgb = mix(bodyMat.color3.rgb, OUTLINE_COLOR, smoothstep(halfPixelSize, -halfPixelSize, sdSclera + 0.12));
    
    #define METAL_COLOR vec3(0.692, 0.725, 0.835)
    
    // 画胸前补丁
    #define FRONT_PATCH_SIZE 2.8
    #define FRONT_PATCH_SD(p) ((sdQuadraticCircle(p / FRONT_PATCH_SIZE) + 0.75) * FRONT_PATCH_SIZE)
    vec3 patchPos = pos - vec3(0.0, -1.0, 1.0);
    vec3 patchUp = normalize(vec3(0.0, 1.0, -1.0));
    vec3 patchRight = vec3(1.0, 0.0, -0.3);
    patchRight = normalize(patchRight - dot(patchUp, patchRight) * patchUp);
    vec3 patchFront = cross(patchRight, patchUp);
    vec3 uvPatch = vec3(dot(patchPos, patchRight), dot(patchPos, patchUp), dot(patchPos, patchFront));
    float sdPatch = FRONT_PATCH_SD(uvPatch.xz);
    vec2 extPatch = vec2(sdPatch, abs(uvPatch.y) - 0.5);
    sdPatch = min(max(extPatch.x, extPatch.y), 0.0) + length(max(extPatch, 0.0));
    float patchOutline = dot(-normal, patchUp);
    bodyMat.color3.a = mix(bodyMat.color3.a, 1.0, smoothstep(halfPixelSize, -halfPixelSize, sdPatch - outlineThickness * patchOutline));
    bodyMat.color3.a = mix(bodyMat.color3.a, 0.0, smoothstep(halfPixelSize, -halfPixelSize, sdPatch));
    bodyMat.color3.rgb = mix(bodyMat.color3.rgb, OUTLINE_COLOR, smoothstep(halfPixelSize, 0.0, sdPatch - outlineThickness * patchOutline));
    bodyMat.color0.rgb = mix(bodyMat.color0.rgb, METAL_COLOR, smoothstep(pixelSize, halfPixelSize, sdPatch));
    
    // 画胸前补丁上的钉子
    // 天晓得为什么这样编译时间会更长
    /* #define FRONT_NAIL_SCALE 0.5
    #define FRONT_NAIL_INNER 0.1
    #define FRONT_NAIL_COUNT 3
    uvPatch.xz = abs(uvPatch.xz); if(uvPatch.z > uvPatch.x) uvPatch.xz = uvPatch.zx;
    float nailDis = float(FRONT_NAIL_COUNT - 1);
    vec2 nailPos = vec2(FRONT_NAIL_SCALE, FRONT_NAIL_SCALE * clamp(round(uvPatch.z / FRONT_NAIL_SCALE * nailDis), 0.0, nailDis) / nailDis);
    vec2 nailDeltaX = vec2(pixelSize, 0.0) / 4.0;
    vec2 nailDeltaZ = vec2(0.0, pixelSize) / 4.0;
    float sdNail = FRONT_PATCH_SD(nailPos);
    float nailX = FRONT_PATCH_SD(nailPos + nailDeltaX) - FRONT_PATCH_SD(nailPos - nailDeltaX);
    float nailZ = FRONT_PATCH_SD(nailPos + nailDeltaZ) - FRONT_PATCH_SD(nailPos - nailDeltaZ);
    vec2 nailNormal = normalize(vec2(nailX, nailZ));
    nailPos -= nailNormal * (sdNail + FRONT_NAIL_INNER);
        
    sdPatch = distance(uvPatch.xz, nailPos) - outlineThickness * 0.8 * patchOutline;
    extPatch = vec2(sdPatch, abs(uvPatch.y) - 0.8);
    sdPatch = min(max(extPatch.x, extPatch.y), 0.0) + length(max(extPatch, 0.0));
    bodyMat.color3.a = mix(bodyMat.color3.a, 1.0, smoothstep(halfPixelSize, -halfPixelSize, sdPatch)); */
    
    #define FRONT_NAIL_SCALE 0.5
    #define FRONT_NAIL_INNER 0.1
    #define FRONT_NAIL_COUNT 3
    uvPatch.xz = abs(uvPatch.xz); if(uvPatch.z > uvPatch.x) uvPatch.xz = uvPatch.zx;
    sdPatch = 65535.0;
    for(int i = 0; i < FRONT_NAIL_COUNT; i++)
    {
        vec2 nailPos = vec2(FRONT_NAIL_SCALE, FRONT_NAIL_SCALE / float(FRONT_NAIL_COUNT - 1) * float(i));
        vec2 nailDeltaX = vec2(pixelSize, 0.0) / 4.0;
        vec2 nailDeltaZ = vec2(0.0, pixelSize) / 4.0;
        float sdNail = FRONT_PATCH_SD(nailPos);
        float nailX = FRONT_PATCH_SD(nailPos + nailDeltaX) - FRONT_PATCH_SD(nailPos - nailDeltaX);
        float nailZ = FRONT_PATCH_SD(nailPos + nailDeltaZ) - FRONT_PATCH_SD(nailPos - nailDeltaZ);
        vec2 nailNormal = normalize(vec2(nailX, nailZ));
        nailPos -= nailNormal * (sdNail + FRONT_NAIL_INNER);
        
        sdPatch = min(sdPatch, distance(uvPatch.xz, nailPos) - outlineThickness * 0.8 * patchOutline);
    }
    extPatch = vec2(sdPatch, abs(uvPatch.y) - 0.8);
    sdPatch = min(max(extPatch.x, extPatch.y), 0.0) + length(max(extPatch, 0.0));
    bodyMat.color3.a = mix(bodyMat.color3.a, 1.0, smoothstep(halfPixelSize, -halfPixelSize, sdPatch));
    
    // 画屁股补丁
    #define BACK_PATCH_SIZE 1.4
    #define BACK_PATCH_SD(p) ((sdQuadraticCircle(p / BACK_PATCH_SIZE) + 0.64) * BACK_PATCH_SIZE)
    patchPos = pos - vec3(0.0, 1.0, -1.0);
    patchUp = normalize(vec3(0.0, 1.0, 0.0));
    patchRight = vec3(1.0, 0.0, 1.0);
    patchRight = normalize(patchRight - dot(patchUp, patchRight) * patchUp);
    patchFront = cross(patchRight, patchUp);
    uvPatch = vec3(dot(patchPos, patchRight), dot(patchPos, patchUp), dot(patchPos, patchFront));
    sdPatch = BACK_PATCH_SD(uvPatch.xz);
    extPatch = vec2(sdPatch, abs(uvPatch.y) - 0.5);
    sdPatch = min(max(extPatch.x, extPatch.y), 0.0) + length(max(extPatch, 0.0));
    patchOutline = dot(normal, patchUp);
    bodyMat.color3.a = mix(bodyMat.color3.a, 1.0, smoothstep(halfPixelSize, -halfPixelSize, sdPatch - outlineThickness * patchOutline));
    bodyMat.color3.a = mix(bodyMat.color3.a, 0.0, smoothstep(halfPixelSize, -halfPixelSize, sdPatch));
    bodyMat.color3.rgb = mix(bodyMat.color3.rgb, OUTLINE_COLOR, smoothstep(halfPixelSize, 0.0, sdPatch - outlineThickness * patchOutline));
    bodyMat.color0.rgb = mix(bodyMat.color0.rgb, METAL_COLOR, smoothstep(pixelSize, halfPixelSize, sdPatch));
    
    // 画胸前补丁上的钉子
    #define BACK_NAIL_SCALE 0.32
    #define BACK_NAIL_INNER 0.1
    #define BACK_NAIL_COUNT 2
    
    uvPatch.xz = abs(uvPatch.xz); if(uvPatch.z > uvPatch.x) uvPatch.xz = uvPatch.zx;
    sdPatch = 65535.0;
    for(int i = 0; i < BACK_NAIL_COUNT; i++)
    {
        vec2 nailPos = vec2(BACK_NAIL_SCALE, BACK_NAIL_SCALE / float(BACK_NAIL_COUNT - 1) * float(i));
        vec2 nailDeltaX = vec2(pixelSize, 0.0) / 4.0;
        vec2 nailDeltaZ = vec2(0.0, pixelSize) / 4.0;
        float sdNail = BACK_PATCH_SD(nailPos);
        float nailX = BACK_PATCH_SD(nailPos + nailDeltaX) - BACK_PATCH_SD(nailPos - nailDeltaX);
        float nailZ = BACK_PATCH_SD(nailPos + nailDeltaZ) - BACK_PATCH_SD(nailPos - nailDeltaZ);
        vec2 nailNormal = normalize(vec2(nailX, nailZ));
        nailPos -= nailNormal * (sdNail + BACK_NAIL_INNER);
        
        sdPatch = min(sdPatch, distance(uvPatch.xz, nailPos) - outlineThickness * 0.8 * patchOutline);
    }
    extPatch = vec2(sdPatch, abs(uvPatch.y) - 0.8);
    sdPatch = min(max(extPatch.x, extPatch.y), 0.0) + length(max(extPatch, 0.0));
    bodyMat.color3.a = mix(bodyMat.color3.a, 1.0, smoothstep(halfPixelSize, -halfPixelSize, sdPatch));
    
    ObjectInfo bodyInfo = ObjectInfo(sdBody(pos), bodyMat);
    
    
    #define DECO_COLOR vec3(0.96, 0.52, 0.42)
    
    // 喙部分
    Material beakMat;
    beakMat.color0 = vec4(DECO_COLOR, 1.0);
    beakMat.index = 0;
    ObjectInfo beakInfo = ObjectInfo(sdBeak(pos, info.boneBeakOpen), beakMat);
    
    // 鸡冠部分
    Material scombMat;
    scombMat.color0 = vec4(DECO_COLOR, 1.0);
    scombMat.index = 0;
    ObjectInfo scombInfo = ObjectInfo(sdScomb(pos), scombMat);
    
    // 翅膀部分
    Material wingMat;
    wingMat.color0 = vec4(BODY_COLOR, 1.0);
    wingMat.index = 0;
    ObjectInfo wingInfo = ObjectInfo(sdWing(pos, info.boneWingSpread), wingMat);
    
    // 发条部分
    Material springMat;
    springMat.color0 = vec4(METAL_COLOR, 1.0);
    springMat.index = 0;
    ObjectInfo springInfo = ObjectInfo(sdSpring(pos, info.boneSpringSpin), springMat);
    
    // 脚部分
    Material footMat;
    footMat.color0 = vec4(DECO_COLOR, 1.0);
    footMat.index = 0;
    ObjectInfo footInfo = ObjectInfo(sdFoot(pos, info.boneWalk), footMat);
    
    // 地板部分
    Material floorMat;
    floorMat.color0 = vec4(BACKGROUND_COLOR, 1.0);
    floorMat.color1 = vec4(BACKGROUND_COLOR * vec3(0.7, 0.52, 0.6), 1.0);
    floorMat.index = 1;
    ObjectInfo floorInfo = ObjectInfo(sdFloor(pos), floorMat);
    
    ObjectInfo res = objectMin(bodyInfo, beakInfo);
    res = objectMin(res, scombInfo);
    res = objectMin(res, wingInfo);
    res = objectMin(res, springInfo);
    res = objectMin(res, footInfo);
    res = objectMin(res, floorInfo);
    return res.material;
}

vec3 getDefaultMaterialShadingResult(Material mat, vec3 pos, vec3 front, vec3 normal, float len, vec2 fragCoord)
{
    vec3 lightDir = normalize(LIGHT_DIRECTION);
    float ndotl = dot(normal, -lightDir);
    float shadow = getShadow(pos, -lightDir, 0.1, 64.0, 0.3);
    shadow = pow(shadow, 1.0 / 2.2);
    shadow = multistep(shadow, 2.0);
    
    float diffuseStrength = pow(ndotl, 1.0 / 2.2);
    diffuseStrength = max(diffuseStrength, 0.0000001);
    diffuseStrength = multistep(diffuseStrength, 2.0);
    diffuseStrength = min(shadow, diffuseStrength);
    vec3 diffuse = mat.color0.rgb * LIGHT_COLOR * diffuseStrength * LIGHT_STRENGTH;
    vec3 ambient = mat.color0.rgb * AMBIENT_COLOR;
    
    vec3 cameraUp = (cameraTransform * vec4(0.0, 1.0, 0.0, 0.0)).xyz;
    vec3 cameraRight = (cameraTransform * vec4(1.0, 0.0, 0.0, 0.0)).xyz;
    
    vec2 uv = fragCoord / iResolution.xy + vec2(0.5) / iResolution.xy;
    vec2 rimlightDir = vec2(dot(-lightDir, cameraRight), dot(-lightDir, cameraUp));
    float rimlightStrength = length(rimlightDir);
    
    // 采样周围2x2区域的四个像素
    vec2 offsets[4] = vec2[](vec2(-0.5, 0.5), vec2(0.5, 0.5), vec2(-0.5, -0.5), vec2(0.5, -0.5));
    float totalWeight = 0.0;
    vec2 rimlightSampleOrigin = uv - rimlightStrength * rimlightDir * RIMLIGHT_THICKNESS;
    rimlightStrength = 0.0;

    // 计算每个采样点的加权值
    for (int i = 0; i < 4; i++) {
        vec2 sampleUV = rimlightSampleOrigin + offsets[i] / iResolution.xy;
        
        // 采样深度，实际上是物体表面到摄像机的距离，和深度有点区别
        float sampleLen = texture(iChannel0, sampleUV).r;
        float sampleStrength = (sampleLen - len - RIMLIGHT_FADE_START) / (RIMLIGHT_FADE_END - RIMLIGHT_FADE_START);
        sampleStrength = clamp(sampleStrength, 0.0, 1.0);
        
        // 计算与当前像素的距离
        float dist = length(sampleUV - rimlightSampleOrigin);
        float sampleWeight = exp(-dist * dist);  // 使用距离的指数衰减作为权重
        
        rimlightStrength += sampleWeight * sampleStrength;
        totalWeight += sampleWeight;
    }
    
    rimlightStrength = rimlightStrength / totalWeight;
    float rimlightAA = fwidth(rimlightStrength) / 2.0;
    rimlightStrength = smoothstep(0.5 - rimlightAA, 0.5 + rimlightAA, rimlightStrength);

    
    vec3 rimlight = RIMLIGHT_COLOR;
    
    vec3 res = mix(diffuse + ambient, rimlight, rimlightStrength);
    
    res = mix(res, mat.color3.rgb, mat.color3.a);
    
    return res;
}

vec3 getFloorMaterialShadingResult(Material mat, vec3 pos, vec3 front, vec3 normal, float len, vec2 fragCoord)
{
    vec3 lightDir = normalize(LIGHT_DIRECTION);
    float shadow = getShadow(pos, -lightDir, 0.1, 32.0, 0.3);
    shadow = pow(shadow, 1.0 / 2.2);
    shadow = multistep(shadow, 2.0);
    
    return mix(mat.color1.rgb, mat.color0.rgb, shadow);
}

vec3 getShadingResult(float len, vec3 ray, vec3 front, vec3 start, float pixelSize, vec2 fragCoord)
{
    float theta = dot(ray, front);
    float planeScale = len * theta;
    pixelSize = pixelSize * planeScale;
    vec3 pos = len * ray + start;
    vec3 normal = getNormal(pos, pixelSize);
    Material mat = sceneMaterial(pos, front, normal, pixelSize, planeScale);
    
    vec3 result = vec3(0.0);
    
    switch(mat.index)
    {
        case 0:
            result = getDefaultMaterialShadingResult(mat, pos, front, normal, len, fragCoord);
            break;
        case 1:
            result = getFloorMaterialShadingResult(mat, pos, front, normal, len, fragCoord);
            break;
    }
    
    return result;
}

vec3 getSkybox(vec3 dir)
{
    return BACKGROUND_COLOR;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    update();
    
    vec2 uv = fragCoord / iResolution.xy;
    vec4 data = texture(iChannel0, uv);
    float len = data.x;
    float minDis = data.y;
    float minLen = data.z;
    
    vec3 ray;
    vec3 front;
    vec3 start;
    float pixelSize;
    getCameraParam(fragCoord, iResolution.xy, ray, front, start, pixelSize);
    
    bool hit = len < MAX_DISTANCE;
    
    vec3 result = vec3(0.0);
    
    float outlineFactor = clamp((len - minLen - OUTLINE_FADE_START) / (OUTLINE_FADE_END - OUTLINE_FADE_START), 0.0, 1.0);
    outlineFactor = 1.0 - outlineFactor;
    outlineFactor = -(outlineFactor * outlineFactor) + 1.0;
    
    float outline = smoothstep(outlineFactor * outlineStrength + pixelSize, outlineFactor * outlineStrength, minDis);
    outline *= smoothstep(32.0, 28.0, minLen);
    float inner = smoothstep(pixelSize, 0.0, data.g);
    vec3 innerResult = getShadingResult(minLen, ray, front, start, pixelSize, fragCoord);
    vec3 outerResult = hit ? getShadingResult(len, ray, front, start, pixelSize, fragCoord) : getSkybox(ray);
    vec3 outlineResult = mix(outerResult, OUTLINE_COLOR, outline);
    if(inner > 0.0) outlineResult = mix(outlineResult, innerResult, inner);
    result = outlineResult;
    
    fragColor = vec4(result, 1.0);
}
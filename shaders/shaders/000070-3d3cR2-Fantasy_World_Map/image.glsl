// Image (image) — Fantasy World Map by mhnewman
// https://www.shadertoy.com/view/3d3cR2

#define DRAW_TOWNS
//#define GO_CRAZY

const float lineWidth = 0.5;

const float terrainScale = 80.0;
const vec3 landColor = vec3(0.9, 0.8, 0.7);
const vec3 shoreLineColor = vec3(0.0);

const float waterThreshold = -0.04;
const vec3 waterDeepColor = vec3(0.7, 0.8, 0.9);
const vec3 waterShallowColor = vec3(0.5, 0.6, 0.9);
const vec3 waterLineColor = vec3(0.0, 0.1, 0.3);

const float mountainWidth = 20.0;
const float mountainHeight = 16.0;
const float mountainThreshold = 0.23;
const vec3 mountainColor = vec3(0.5, 0.3, 0.1);
const vec3 mountainShadowColor = vec3(0.3, 0.2, 0.0);
const vec3 mountainLineColor = vec3(0.3, 0.1, 0.0);

const float treeScale = 3.5;
const float treeGrow = 1.5;
const float treeGrowthScale = 100.0;
const float treeGrowthThreshold = 0.08;
const float treeTerrainThresholdLow = 0.02;
const float treeTerrainThresholdHigh = 0.12;
const vec3 treeColor = vec3(0.3, 0.8, 0.4);
const vec3 treeShadowColor = vec3(0.0, 0.4, 0.2);
const vec3 treeLineColor = vec3(0.0, 0.3, 0.1);

const float townSpacing = 80.0;
const float buildingLineWidth = 0.3;
const float buildingSize = 5.0;
const float roofSize = 0.3;
const float urbanSprawl = 8.0;
const float townTerrainThresholdLow = 0.0;
const float townTerrainThresholdHigh = 0.18;
const float townTreeThreshold = 0.04;

const float paperTexture = 3.0;
const float dirt = 0.5;
const vec3 dirtColor = vec3(0.6, 0.3, 0.1);

const float vignetting = 0.4;
const vec3 vignettingColor = vec3(0.3, 0.2, 0.0);


const float pi = 3.14159265;

const float terrainScaleInv = 1.0 / terrainScale;
const float mountainWidthInv = 1.0 / mountainWidth;
const float mountainHeightInv = 1.0 / mountainHeight;
const float treeScaleInv = 1.0 / treeScale;
const float treeGrowthScaleInv = 1.0 / treeGrowthScale;
const float townSpacingInv = 1.0 / townSpacing;
const float buildingSizeInv = 1.0 / buildingSize;

float aa;
float lw;
float blw;
float bsdf;


float hash1(vec2 p) {
    vec3 p3  = fract(vec3(p.xyx) * 0.1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

vec2 hash2(vec2 p) {
    vec3 p3 = fract(vec3(p.xyx) * vec3(0.1031, 0.1030, 0.0973));
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.xx + p3.yz) * p3.zy);
}

vec3 hash3(vec2 p) {
    vec3 p3 = fract(vec3(p.xyx) * vec3(0.1031, 0.1030, 0.0973));
    p3 += dot(p3, p3.yxz + 33.33);
    return fract((p3.xxy + p3.yzz) * p3.zyx);
}

float noise1(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(mix(hash1(i + vec2(0.0, 0.0)), 
                   hash1(i + vec2(1.0, 0.0)), u.x),
               mix(hash1(i + vec2(0.0, 1.0)), 
                   hash1(i + vec2(1.0, 1.0)), u.x), u.y);
}

const mat2 m = mat2(1.616, 1.212, -1.212, 1.616);

float fbm1(vec2 p) {
    float f = noise1(p) - 0.5; p = m * p;
    f += 0.5 * (noise1(p) - 0.5); p = m * p;
    f += 0.25 * (noise1(p) - 0.5);
    return f / 1.75;
}

float fbm1high(vec2 p) {
    float f = noise1(p) - 0.5; p = m * p;
    f += 0.5 * (noise1(p) - 0.5); p = m * p;
    f += 0.25 * (noise1(p) - 0.5); p = m * p;
    f += 0.125 * (noise1(p) - 0.5); p = m * p;
    f += 0.0625 * (noise1(p) - 0.5);
    return f / 1.9375;
}

float sdBox(vec2 p, vec2 b) {
    vec2 d = abs(p) - b;
    return length(max(d, 0.0)) + min(max(d.x, d.y), 0.0);
}

float sdTriangleIsosceles(vec2 p, vec2 q) {
    p.x = abs(p.x);
    vec2 a = p - q * clamp(dot(p, q) / dot(q, q), 0.0, 1.0);
    vec2 b = p - q * vec2(clamp(p.x / q.x, 0.0, 1.0 ), 1.0);
    float s = -sign(q.y);
    vec2 d = min(vec2(dot(a, a), s * (p.x * q.y - p.y * q.x)), vec2(dot(b, b), s * (p.y - q.y)));
    return -sqrt(d.x) * sign(d.y);
}

vec3 water(vec3 color, vec2 pos) {
    float terrain = fbm1high(terrainScaleInv * pos) - waterThreshold;

    vec3 waterColor = mix(waterDeepColor, waterShallowColor, exp(20.0 * terrain));
    color = mix(color, waterColor, step(terrain, 0.0));

    float offset = waterThreshold + terrain;
    float dx = fbm1high(terrainScaleInv * (pos + vec2(0.01, 0.0))) - offset;
    float dy = fbm1high(terrainScaleInv * (pos + vec2(0.0, 0.01))) - offset;
    float grad = 0.01 / length(vec2(dx, dy));
    float t0 = terrain * grad;
    float t1 = (terrain + 0.02) * grad;
    float t2 = (terrain + 0.04) * grad;
    float t3 = (terrain + 0.06) * grad;
    float t4 = (terrain + 0.08) * grad;
    float t5 = (terrain + 0.1) * grad;

    color = mix(color, waterLineColor, 0.5 * clamp((lw - abs(t1)) * aa, 0.0, 1.0));
    color = mix(color, waterLineColor, 0.4 * clamp((lw - abs(t2)) * aa, 0.0, 1.0));
    color = mix(color, waterLineColor, 0.3 * clamp((lw - abs(t3)) * aa, 0.0, 1.0));
    color = mix(color, waterLineColor, 0.2 * clamp((lw - abs(t4)) * aa, 0.0, 1.0));
    color = mix(color, waterLineColor, 0.1 * clamp((lw - abs(t5)) * aa, 0.0, 1.0));

    return mix(color, shoreLineColor, clamp((lw - abs(t0)) * aa, 0.0, 1.0));
}

float mountainContour(vec2 p, float y, float squash, float offset) {
    float contour = -0.2;
    contour -= 0.4 * (1.0 - pow(abs(cos((mountainWidthInv * p.x + offset) * pi)), 1.2));
    contour += 0.5 * fbm1(vec2(0.15 * p.x, y));
    contour *= squash;
    return p.y - y + mountainHeight * (contour + 0.4);
}

vec3 mountains(vec3 color, vec2 pos, float offset) {
    float x = mountainWidthInv * pos.x + offset;
    float range = fract(x);
    float antiRange = 1.0 - range;
    x = mountainWidth * ((floor(x) - offset) + 0.5);
    
    float y = mountainHeightInv * pos.y + offset;
    float altitude = fract(y);
    float antiAltitude = 1.0 - altitude;
   	y = mountainHeight * ((floor(y) - offset) + 0.5);
    
    float draw = step(mountainThreshold, fbm1(terrainScaleInv * vec2(x, y)));
    float drawLeft = step(mountainThreshold, fbm1(terrainScaleInv * vec2(x - mountainWidth, y)));
    float drawRight = step(mountainThreshold, fbm1(terrainScaleInv * vec2(x + mountainWidth, y)));
    
    float squash = clamp(4.0 * range * antiRange + drawLeft * step(range, 0.5) + drawRight * step(0.5, range), 0.0, 1.0);
    squash *= squash;
    draw *= clamp(mountainWidth * range * aa + drawLeft, 0.0, 1.0);
    draw *= clamp(mountainWidth * antiRange * aa + drawRight, 0.0, 1.0);
    
   	float ter = mountainContour(pos, y, squash, offset);
    float tdx = mountainContour(pos + vec2(0.01, 0.0), y, squash, offset) - ter;
    float tdy = mountainContour(pos + vec2(0.0, 0.01), y, squash, offset) - ter;
    float tgrad = 0.01 / length(vec2(tdx, tdy));
    float t0 = ter * tgrad;

    vec3 fillColor = mix(landColor, mountainColor, altitude);
    fillColor = mix(fillColor, mountainLineColor, clamp(8.0 * (0.1 - abs(fbm1(0.25 * pos))), 0.0, 1.0));
    fillColor = mix(color, fillColor, smoothstep(0.0, 0.3, altitude)); 
    color = mix(color, fillColor, step(ter, 0.0) * draw);
    
    float shadow = step(0.0, t0) * antiAltitude * antiAltitude * draw * squash;
    color = mix(color, mountainShadowColor, shadow);
    return mix(color, mountainLineColor, clamp((lw - abs(t0)) * aa, 0.0, 1.0) * draw);
}

float treeSDF(vec2 pos, vec2 trunk) {
    vec3 h = hash3(trunk);
    float r = treeScale * (0.9 + 0.35 * h.z);
    trunk += treeScale * 0.5 * (h.xy - 0.5);
    float terrain = fbm1(terrainScaleInv * trunk);
    float plant = step(treeTerrainThresholdLow, terrain) * step(terrain, treeTerrainThresholdHigh);
    plant *= step(treeGrowthThreshold, fbm1(treeGrowthScaleInv * trunk + 100.0));
    return r - distance(pos, trunk) - 100.0 * (1.0 - plant);
}

vec3 trees(vec3 color, vec2 pos) {
    vec2 center = treeScale * (floor(treeScaleInv * pos) + 0.5);
    float shadow = treeSDF(pos, center);
    shadow = max(shadow, treeSDF(pos, center + vec2(treeScale, 0.0)));
    shadow = max(shadow, treeSDF(pos, center + vec2(treeScale, treeScale)));
    shadow = max(shadow, treeSDF(pos, center + vec2(0.0, treeScale)));
    shadow = max(shadow, treeSDF(pos, center + vec2(-treeScale, treeScale)));
    shadow = max(shadow, treeSDF(pos, center + vec2(-treeScale, 0.0)));
    
    color = mix(color, treeShadowColor, step(0.0, shadow));
    color = mix(color, treeLineColor, clamp((lw - abs(shadow)) * aa, 0.0, 1.0));
    
    pos.y -= treeGrow;
    vec2 trunk = treeScale * (floor(treeScaleInv * pos) + 0.5);
    float forrest = treeSDF(pos, trunk);
    forrest = max(forrest, treeSDF(pos, trunk + vec2(treeScale, 0.0)));
    forrest = max(forrest, treeSDF(pos, trunk + vec2(treeScale, treeScale)));
    forrest = max(forrest, treeSDF(pos, trunk + vec2(0.0, treeScale)));
    forrest = max(forrest, treeSDF(pos, trunk + vec2(-treeScale, treeScale)));
    forrest = max(forrest, treeSDF(pos, trunk + vec2(-treeScale, 0.0)));
    forrest = max(forrest, treeSDF(pos, trunk + vec2(-treeScale, -treeScale)));
    forrest = max(forrest, treeSDF(pos, trunk + vec2(0.0, -treeScale)));
    forrest = max(forrest, treeSDF(pos, trunk + vec2(treeScale, -treeScale)));

    color = mix(color, treeColor * (1.0 - exp(-0.5 - clamp(forrest, 0.0, 10.0))), step(0.0, forrest));
    return mix(color, treeLineColor, clamp((lw - abs(forrest)) * aa, 0.0, 1.0));
}

#ifdef DRAW_TOWNS
vec3 building(vec3 color, vec2 pos, vec2 county, float population, vec3 roofColor, vec2 block) {
    vec2 b = buildingSize * block;
    float terrain = fbm1(terrainScaleInv * b);
    float free = step(townTerrainThresholdLow, terrain) * step(terrain, townTerrainThresholdHigh);
    free *= step(fbm1(treeGrowthScaleInv * b + 100.0), townTreeThreshold);
    free *= step(hash1(block), 1.2 - distance(b, county) / ((1.0 + population) * urbanSprawl));
    
    vec3 buildingHash = hash3(block);
    vec2 size = vec2(0.3, 0.1) + vec2(0.25, 0.25) * buildingHash.xy;
    vec2 center = vec2(1.2 * (buildingHash.z - 0.5), size.y - 0.6);
    vec2 p = pos - block - center;
    
    vec2 roofHash = hash2(block);
    float roofWidth = size.x * (0.4 + 0.6 * roofHash.x);
    float roofside = 1.0 - 2.0 * step(roofHash.y, 0.5);
    float triangle = sdTriangleIsosceles(p - vec2(roofside * (roofWidth - size.x), 0.4 + size.y), vec2(roofWidth, -0.4));
    float sdf = sdBox(p, size);
    sdf = min(sdf, triangle);
    sdf -= bsdf;
    
    float roofSdf = min(triangle, sdTriangleIsosceles(p - vec2(roofside * (size.x - roofWidth), 0.4 + size.y), vec2(roofWidth, -0.4)));
    roofSdf = min(roofSdf, sdBox(p - vec2(0.0, 0.2 + size.y), vec2(size.x - roofWidth, 0.2)));
    roofSdf -= roofSize;
    roofSdf = max(roofSdf, size.y - p.y + bsdf);
    color = mix(color, roofColor, step(roofSdf, 0.0) * free);
    color = mix(color, vec3(0.0), clamp((blw - abs(buildingSize * roofSdf)) * aa, 0.0, 1.0) * free);
    
    vec3 sidingHash = hash3(block + 0.1);
    vec3 siding = vec3(0.2 + 0.3 * sidingHash.x + 0.5 * noise1(vec2(6.0, 10.0) * pos)) + sidingHash.y * vec3(0.2, 0.1 + 0.1 * sidingHash.z, 0.0);
    color = mix(color, siding, step(sdf, 0.0) * free);
    
    vec3 windowHash = hash3(block + 0.2);
    vec2 windowSize = vec2(0.2 + 0.1 * windowHash.x, 0.4 + 0.4 * step(windowHash.y, 0.5));
    vec2 windowCenter = vec2(0.8 * (0.5 - windowHash.z), 0.4 - windowSize.y);
    float windowSdf = sdBox(p - size * windowCenter, size * windowSize);
    color = mix(color, 0.5 * roofColor, 0.3 * step(windowSdf, 0.0) * free);
    color = mix(color, vec3(0.0), clamp((blw - abs(buildingSize * windowSdf)) * aa, 0.0, 1.0) * free);
    
    return mix(color, vec3(0.0), clamp((blw - abs(buildingSize * sdf)) * aa, 0.0, 1.0) * free);
}

vec3 town(vec3 color, vec2 pos) {
    vec2 county = townSpacing * (floor(townSpacingInv * pos) + 0.5);
    vec3 h = hash3(county);
    vec3 roofColor = 0.5 + 0.2 * cos(6.2831853 * (vec3(0.0, 0.33, 0.67) + h.x));
    county += townSpacing * 0.6 * (h.xy - 0.5);
    
    vec2 grid = buildingSizeInv * pos;
    vec2 block = floor(grid) + 0.5;
    float offset = mod(block.x, 2.0) - 0.5;
    block.y += offset * (step(0.5, fract(grid.y)) - 0.5);
    
    vec2 p = buildingSizeInv * pos;
    color = building(color, p, county, h.z, roofColor, block + vec2(0.0, 1.0));
    color = building(color, p, county, h.z, roofColor, block + vec2(-1.0, 0.5));
    color = building(color, p, county, h.z, roofColor, block + vec2(1.0, 0.5));
    color = building(color, p, county, h.z, roofColor, block);
    color = building(color, p, county, h.z, roofColor, block + vec2(-1.0, -0.5));
    color = building(color, p, county, h.z, roofColor, block + vec2(1.0, -0.5));
    color = building(color, p, county, h.z, roofColor, block + vec2(0.0, -1.0));
    
    return color;
}
#endif

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec3 center = vec3(40.0 * iTime, 0.0, 0.0);
    vec3 eye = center + vec3(0.0, -40.0 + 30.0 * cos(0.15 * iTime), 120.0 - 50.0 * cos(0.15 * iTime));

#ifdef GO_CRAZY
    center = vec3(250.0 * iTime, 0.0, 0.0);
    eye = center + vec3(70.0 * sin(iTime), 70.0 * cos(iTime), 150.0 + 100.0 * cos(1.4 * iTime));
#endif

    float zoom = 2.0;
    
    vec3 forward = normalize(center - eye);
    vec3 right = normalize(cross(forward, vec3(0.0, 0.0, 1.0)));
    vec3 up = cross(right, forward);
    vec2 xy = 2.0 * fragCoord - iResolution.xy;
    vec3 ray = normalize(xy.x * right + xy.y * up + zoom * forward * iResolution.y);
    
    float t = -eye.z / ray.z;
    vec2 pos = eye.xy + t * ray.xy;
    
    aa = iResolution.y / t;
    lw = lineWidth + 0.5 / aa;
    blw = buildingLineWidth + 0.5 / aa;
    bsdf = blw * buildingSizeInv;
    
    vec3 color = water(landColor, pos);

    float mountainRange = 0.5 * step(fract(mountainHeightInv * pos.y), 0.5);
    color = mountains(color, pos, 0.5 - mountainRange);
    color = mountains(color, pos, mountainRange);
    
    color = trees(color, pos);
    
#ifdef DRAW_TOWNS
    color = town(color, pos);
#endif
    
    color = mix(color, dirtColor, dirt * pow(clamp(fbm1(vec2(0.01, 0.02) * pos), 0.0, 1.0), 1.5));
    
    color *= 1.0 + paperTexture * (fbm1high(vec2(0.05, 0.1) * pos) - fbm1high(vec2(0.05, 0.1) * (pos + vec2(0.1, 0.1))));

    vec2 uv = 2.0 * fragCoord / iResolution.xy - 1.0;
    color = mix(vignettingColor, color, vignetting * pow((1.0 - uv.x * uv.x) * (1.0 - uv.y * uv.y), 0.3) + 1.0 - vignetting);
    
    fragColor = vec4(color, 1.0);
}

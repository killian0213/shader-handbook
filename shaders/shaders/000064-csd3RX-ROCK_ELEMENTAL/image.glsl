// Image (image) — ROCK ELEMENTAL by alro
// https://www.shadertoy.com/view/csd3RX

/*

    Exploring rock modelling and texturing. Use mouse to move camera.
    See BufferB for details
    
    Ocean elemental: https://www.shadertoy.com/view/NdS3zK
    Magma elemental: https://www.shadertoy.com/view/sdBGWh
    Rock elemental: https://www.shadertoy.com/view/csd3RX

*/


const vec3 DETAIL_SCALE = vec3(0.5);
const vec3 BLENDING_SHARPNESS = vec3(10.0);
const float DETAIL_HEIGHT = 0.02;
const float GOLD_DEPTH = 0.02625;

const float SHADOW_SHARPNESS = 8.0;

const float EPSILON = 1e-3;
const float MIN_DIST = 0.01;
const int MAX_STEPS = 64;
const float MAX_DIST = 8.0;

const vec3 modelOffset = vec3(0,0.5,0);

#define CORE 0
#define HEAD 1
#define HANDS 2
#define MIDDLE 3
#define BOTTOM 4

//---------------------------- Camera -----------------------------

vec3 rayDirection(float fieldOfView, vec2 fragCoord) {
    vec2 xy = fragCoord - iResolution.xy / 2.0;
    float z = (0.5 * iResolution.y) / tan(radians(fieldOfView) / 2.0);
    return normalize(vec3(xy, -z));
}

// https://www.geertarien.com/blog/2017/07/30/breakdown-of-the-lookAt-function-in-OpenGL/
mat3 lookAt(vec3 camera, vec3 at, vec3 up){
  vec3 zaxis = normalize(at-camera);    
  vec3 xaxis = normalize(cross(zaxis, up));
  vec3 yaxis = cross(xaxis, zaxis);

  return mat3(xaxis, yaxis, -zaxis);
}

//----------------------------- Rotations -----------------------------

vec3 rotate(vec3 p, vec4 q){
  return 2.0 * cross(q.xyz, p * q.w + cross(q.xyz, p)) + p;
}
vec3 rotateX(vec3 p, float angle){
    return rotate(p, vec4(sin(angle/2.0), 0.0, 0.0, cos(angle/2.0)));
}
vec3 rotateY(vec3 p, float angle){
	return rotate(p, vec4(0.0, sin(angle/2.0), 0.0, cos(angle/2.0)));
}
vec3 rotateZ(vec3 p, float angle){
	return rotate(p, vec4(0.0, 0.0, sin(angle), cos(angle)));
}

//---------------------------- Operations -----------------------------

float smoothSub( float d1, float d2, float k ) {
    float h = clamp( 0.5 - 0.5*(d2+d1)/k, 0.0, 1.0 );
    return mix( d2, -d1, h ) + k*h*(1.0-h); 
}

// https://iquilezles.org/articles/smin
float smoothMin(float a, float b, float k){
    float h = clamp(0.5+0.5*(b-a)/k, 0.0, 1.0 );
    return mix( b, a, h ) - k*h*(1.0-h);
}


//---------------------- Distance functions ----------------------
//https://iquilezles.org/articles/distfunctions/

float sdBox( vec3 p, vec3 b ){
  vec3 q = abs(p) - b;
  return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
}

float sdRoundBox( vec3 p, vec3 b, float r ){
  vec3 q = abs(p) - b;
  return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0) - r;
}

float sphereSDF(vec3 p, float radius) {
    return length(p) - radius;
}

float sdRoundCone( vec3 p, float r1, float r2, float h ){
  vec2 q = vec2( length(p.xz), p.y );
    
  float b = (r1-r2)/h;
  float a = sqrt(1.0-b*b);
  float k = dot(q,vec2(-b,a));
    
  if( k < 0.0 ) return length(q) - r1;
  if( k > a*h ) return length(q-vec2(0.0,h)) - r2;
        
  return dot(q, vec2(a,b) ) - r1;
}

float sdCylinder( vec3 p, vec3 c ){
  return length(p.xz-c.xy)-c.z;
}

//-------------------------- AABB -------------------------

// Only evaluate the distance function when near a feature or when looking at it.
// This improves performance as we skip complex distance calculations for many pixels.

// https://gist.github.com/DomNomNom/46bb1ce47f68d255fd5d
// Compute the near and far intersections using the slab method.
// No intersection if tNear > tFar.
vec2 intersectAABB(vec3 rayOrigin, vec3 rayDir, vec3 boxMin, vec3 boxMax) {
    vec3 tMin = (boxMin - rayOrigin) / rayDir;
    vec3 tMax = (boxMax - rayOrigin) / rayDir;
    vec3 t1 = min(tMin, tMax);
    vec3 t2 = max(tMin, tMax);
    float tNear = max(max(t1.x, t1.y), t1.z);
    float tFar = min(min(t2.x, t2.y), t2.z);
    return vec2(tNear, tFar);
}

bool insideAABB(vec3 p, vec3 boxMin, vec3 boxMax){
    float eps = 1e-4;
	return  (p.x > boxMin.x-eps) && (p.y > boxMin.y-eps) && (p.z > boxMin.z-eps) && 
			(p.x < boxMax.x+eps) && (p.y < boxMax.y+eps) && (p.z < boxMax.z+eps);
}

bool testAABB(vec3 org, vec3 dir, vec3 boxMin, vec3 boxMax){
	vec2 intersections = intersectAABB(org, dir, boxMin, boxMax);
	
    if(insideAABB(org, boxMin, boxMax)){
        intersections.x = 1e-4;
    }
    
    return intersections.x > 0.0 && (intersections.x < intersections.y);
}


//------------------------- Geometry -------------------------

vec3 getCoreRotation(vec3 p){
    p = rotateX(p, 0.03*cos(0.5*iTime)*PI);
    return p;
}
vec3 getCoreInverseRotation(vec3 p){
    p = rotateX(p, -0.03*cos(0.5*iTime)*PI);
    return p;
}

vec3 getCoreOffset(vec3 p){
    p -= modelOffset;
    p.y += 0.05*cos(iTime);
    return p;
}

vec3 getHeadOffset(vec3 p){
    p -= modelOffset;
    p.y += 0.025*cos(2.0*iTime);
    return p;
}

vec3 getHandRotation(vec3 p){
    p = rotateY(p, 0.01*sin(iTime)*PI);
    p = rotateX(p, 0.01*cos(iTime)*PI);
    return p;
}

vec3 getHandInverseRotation(vec3 p){
    p = rotateX(p, -0.01*cos(iTime)*PI);
    p = rotateY(p, -0.01*sin(iTime)*PI);
    return p;
}

vec3 getHandOffset(vec3 p){
    p -= modelOffset;
    p.y += 1.0+0.05*sin(2.0*iTime);
    return p;
}

vec3 getMiddleOffset(vec3 p){
    p.x += 0.15*sin(iTime);
    p.z += 0.15*cos(iTime);
    p.y += 1.0+0.035*sin(2.0*iTime);
    return p;
}

vec3 getMiddleRotation(vec3 p){
    p = rotateY(p, 0.075*iTime*PI);
    p = rotateX(p, 0.15*iTime*PI);
    return p;
}

vec3 getMiddleInverseRotation(vec3 p){
    p = rotateX(p, -0.15*iTime*PI);
    p = rotateY(p, -0.075*iTime*PI);
    return p;
}

vec3 getBottomOffset(vec3 p){
    p.x += 0.1*sin(PI*0.5-iTime);
    p.z += 0.1*cos(PI*0.5-iTime);
    p.y += 1.55+0.025*sin(-2.0*iTime);
    return p;
}

vec3 getBottomRotation(vec3 p){
    p = rotateY(p, 0.05*iTime*PI);
    p = rotateX(p, 0.1*iTime*PI);
    return p;
}

vec3 getBottomInverseRotation(vec3 p){
    p = rotateX(p, -0.1*iTime*PI);
    p = rotateY(p, -0.05*iTime*PI);
    return p;
}

float getHandSDF(vec3 p){

    // Round cone carved by boxes and planes

    vec3 q = p;
    float dist = sdRoundCone(q, 0.5, 0.7, 0.4);

    float smoothness = 0.03;
    
    q = p;
    q = rotateY(q, 0.5*PI);
    dist = smoothSub(-sdBox(q, vec3(0.25, 2.0, 1.5)), dist, smoothness);
    
    q = p;
    q = rotateY(q, 0.35*PI);
    dist = smoothSub(-sdBox(q, vec3(0.25, 2.0, 1.5)), dist, smoothness);
    
    // Fists
    q = p;
    q.y += 0.1;
    q.z += 0.3;
    q = rotateY(q, 0.45*PI);
    q = rotateZ(q, 0.3*PI);
    dist = smoothMin(sdRoundBox(q, vec3(0.2, 0.1, 0.3), 0.1), dist, 0.1);
    
    q = p;
    q.y -= 0.3;
    q = rotateY(q, -0.15*PI);
    dist = smoothSub(-sdBox(q, vec3(0.45, 0.7, 1.5)), dist, smoothness);
    
    q = p;
    q.y -= 0.3;
    q = rotateZ(q, -0.1*PI);
    dist = smoothSub(-sdBox(q, vec3(0.5, 0.7, 1.5)), dist, smoothness);
    
    q = p;
    q.z -= 0.5;
    q = rotateX(q, -0.2*PI);
    q = rotateY(q, -0.05*PI);
    dist = smoothSub(sdBox(q, vec3(1.5, 1.7, 0.25)), dist, smoothness);

    return dist;
}

float getHeadSDF(vec3 p){

    // Main shape is a round box
    vec3 q = p;
    q.y += 0.02;
    q = rotateX(q, 0.03*PI);
    float dist = sdRoundBox(q, vec3(0.275, 0.2, 0.45), 0.05);

    float smoothness = 0.03;
    
    // Carve sphere
    q = p;
    dist = smoothSub(-sphereSDF(q, 0.35), dist, smoothness);
    
    // Carve back of head away from body
    q = p;
    q.x -= 0.3;
    dist = smoothSub(-sphereSDF(q, 0.5), dist, smoothness);

    // Two cylinders for eyes
    q = p;
    float size = q.z > 0.0 ? 0.055 : 0.07;
    q.y += 0.1;
    q.z = abs(q.z);
    q = rotateY(q, -0.5*PI);
    q = rotateX(q, -0.5*PI);
    dist = smoothSub(sdCylinder(q, vec3(-0.175, 0.0, size)), dist, 0.03);

    return dist;
}

float getCoreSDF(vec3 p){

    vec3 q = p;
    float dist = sphereSDF(q, 1.0);

    float smoothness = 0.03;

    // Carve away several planes using wide boxes
    // -------------------------------------------
    q = p;
    q = rotateY(q, 0.2*PI);
    q = rotateZ(q, -0.1*PI);
    dist = smoothSub(-sdBox(q, vec3(0.7, 2.0, 1.5)), dist, smoothness);

    q = p;
    q = rotateY(q, 0.25*PI);
    q = rotateZ(q, 0.1*PI);
    dist = smoothSub(-sdBox(q, vec3(0.75, 2.0, 1.5)), dist, smoothness);

    q = p;
    q = rotateY(q, -0.75*PI);
    q = rotateY(q, -0.5*PI);
    dist = smoothSub(-sdBox(q, vec3(0.75, 2.0, 1.5)), dist, smoothness);

    q = p;
    q = rotateY(q, 0.5*PI);
    dist = smoothSub(-sdBox(q, vec3(0.8, 2.0, 1.5)), dist, smoothness);

    q = p;
    q = rotateY(q, 0.7*PI);
    q = rotateZ(q, 0.35*PI);
    dist = smoothSub(-sdBox(q, vec3(0.8, 2.0, 1.5)), dist, smoothness);

    // -------------------------------------------

    // Hollow for head
    q = p;
    q.x -= 1.6;
    q.y += 0.3;
    dist = smoothSub(sphereSDF(q, 1.0), dist, 0.05);
    
    return dist;
}

float getMiddleSDF(vec3 p){
    vec3 q = p;
    float dist = sdRoundBox(q, vec3(0.175), 0.03);
    
    
    float smoothness = 0.02;
    // Carve away several planes using wide boxes
    // -------------------------------------------
    q = p;
    q = rotateZ(q, -0.3*PI);
    dist = smoothSub(-sdBox(q, vec3(0.175, 2.0, 1.5)), dist, smoothness);
    
    q = p;
    q = rotateY(q, 0.5*PI);
    q = rotateZ(q, 0.4*PI);
    dist = smoothSub(-sdBox(q, vec3(0.175, 2.0, 1.5)), dist, smoothness);

    q = p;
    q = rotateY(q, -0.25*PI);
    q = rotateZ(q, 0.35*PI);
    dist = smoothSub(-sdBox(q, vec3(0.175, 2.0, 1.5)), dist, smoothness);
    
    // -------------------------------------------
    return dist;
}

float getBottomSDF(vec3 p){
    vec3 q = p;
    float dist = sdRoundBox(q, vec3(0.1), 0.03);
    
    
    float smoothness = 0.02;
    // Carve away several planes using wide boxes
    // -------------------------------------------
    q = p;
    q = rotateY(q, 0.5*PI);
    q = rotateZ(q, -0.3*PI);
    dist = smoothSub(-sdBox(q, vec3(0.1, 2.0, 1.5)), dist, smoothness);
    
    q = p;
    q = rotateY(q, -0.25*PI);
    q = rotateZ(q, 0.7*PI);
    dist = smoothSub(-sdBox(q, vec3(0.1, 2.0, 1.5)), dist, smoothness);
    
    // -------------------------------------------
    return dist;
}

float getSDF(vec3 p, vec3 dir, out int partID){

    float dist = 1e5;
    vec3 q = p;
    
    float previousDist = dist;
    partID = -1;
    
    // Core body
    if(testAABB(p, dir, vec3(-1.1, -1.2, -0.9) + modelOffset, 
                        vec3(0.9, 1.1, 0.9) + modelOffset)){
        vec3 q = p;
        q = getCoreOffset(q);
        q = getCoreRotation(q);
        dist = min(getCoreSDF(q), dist);
        
        if(previousDist > dist){
            previousDist = dist;
            partID = CORE;
        }
    }
    
    // Head    
    if(testAABB(p, dir, vec3(0.6, -0.55, -0.4)  + modelOffset, 
                        vec3(1.3, 0.1, 0.4) + modelOffset)){
        q = p;
        q.x -= 0.9;
        q.y += 0.2;
        q = getHeadOffset(q);
        dist = min(getHeadSDF(q), dist);
        if(previousDist > dist){
            previousDist = dist;
            partID = HEAD;
        }
    }
    
    // Hands
    if(testAABB(p, dir, vec3(-0.3, -1.6, 0.6) + modelOffset, 
                        vec3(1.1, 0.1, 1.75) + modelOffset) ||
       testAABB(p, dir, vec3(-0.3, -1.6, -1.75) + modelOffset, 
                        vec3(1.1, 0.1, -0.6) + modelOffset)){
 
        q = p;
        q = getHandOffset(q);
        q = getHandRotation(q);
        q.z = abs(q.z);
        q.z -= 1.3;
        q.x -= 0.5;

        q = rotateZ(q, -0.05*PI);
        q = rotateY(q, -0.15*PI);
        q = rotateX(q, 0.05*PI);

        dist = min(getHandSDF(q), dist);

        if(previousDist > dist){
            previousDist = dist;
            partID = HANDS;
        }
    }
    
    // Middle
    if(testAABB(p, dir, vec3(-0.6, -1.9, -0.6) + modelOffset,
                        vec3(0.6, -1.0, 0.6) + modelOffset)){
        q = p;
        q = getMiddleOffset(q);
        q = getMiddleRotation(q);
        dist = min(getMiddleSDF(q), dist);
        
        if(previousDist > dist){
            previousDist = dist;
            partID = MIDDLE;
        }
    }
    
    // Bottom
    if(testAABB(p, dir, vec3(-0.5, -2.3, -0.5) + modelOffset, 
                        vec3(0.5, -1.7, 0.5) + modelOffset)){
        q = p;
        q = getBottomOffset(q);
        q = getBottomRotation(q);
        dist = min(getBottomSDF(q), dist);
       
        if(previousDist > dist){
            previousDist = dist;
            partID = BOTTOM;
        }
    }

    return dist;
}

float distanceToScene(vec3 cameraPos, vec3 rayDir, float start, float end, out int partID) {
	
    float depth = start;
    
    float dist;
    
    for (int i = ZERO; i < MAX_STEPS; i++){

        dist = getSDF(cameraPos + depth * rayDir, rayDir, partID);

        if (dist < EPSILON){ return depth; }

        depth += dist;

        if (depth >= end){ return end; }
    }
    
    return depth;
}

// Tetrahedral normal technique with a loop to avoid inlining getSDF()
// This should improve compilation times
// https://iquilezles.org/articles/normalsSDF
vec3 getNormal(vec3 p, vec3 dir){
    vec3 n = vec3(0.0);
    int id;
    for(int i = ZERO; i < 4; i++){
        vec3 e = 0.5773*(2.0*vec3((((i+3)>>1)&1),((i>>1)&1),(i&1))-1.0);
        n += e*getSDF(p+e*EPSILON, dir, id);
    }
    return normalize(n);
}

vec4 getTexture(vec2 uv){
    return texture(iChannel1, uv);
}

vec4 getTriplanar(vec3 position, vec3 normal){
    vec4 xaxis = getTexture(DETAIL_SCALE.x*(position.zy));
    vec4 yaxis = getTexture(DETAIL_SCALE.y*(position.zx));
    vec4 zaxis = getTexture(DETAIL_SCALE.z*(position.xy));

    vec3 blending = abs(normal);
	blending = normalize(max(blending, 0.00001));
    blending = pow(blending, BLENDING_SHARPNESS);
	float b = (blending.x + blending.y + blending.z);
	blending /= b;

    return	xaxis * blending.x + 
       		yaxis * blending.y + 
        	zaxis * blending.z;
}



// Return the position of p extruded in the normal direction by normal map
vec3 getDetailExtrusion(vec3 p, vec3 normal){

    // Get rock and seam height texture
    vec2 data = getTriplanar(p, normal).rg;
    
    // Add crevices for gold seam
    float detail = DETAIL_HEIGHT * data.r - GOLD_DEPTH * smoothstep(0.5, 1.0, data.g);
    
    return p + detail * normal;
}

// Return the normal direction after applying a normal map
vec3 getDetailNormal(vec3 p, vec3 normal){
    vec3 tangent;
    vec3 bitangent;
    // Construct orthogonal directions tangent and bitangent to sample detail gradient in
    pixarONB(normal, tangent, bitangent);
    
    tangent = normalize(tangent);
    bitangent = normalize(bitangent);
    
    float EPS = 1e-3;
    vec3 delTangent = 	getDetailExtrusion(p + tangent * EPS, normal) - 
        				getDetailExtrusion(p - tangent * EPS, normal);
    
    vec3 delBitangent = getDetailExtrusion(p + bitangent * EPS, normal) - 
        				getDetailExtrusion(p - bitangent * EPS, normal);
    
    return normalize(cross(delTangent, delBitangent));
}

//---------------------------- Material ----------------------------

vec3 getAlbedo(float h, float m){
    //Grey based on heightmap
    vec3 base = mix(0.125 * vec3(0.75), 0.15 * vec3(1.5), smoothstep(0.15, 1.0, h));
    //Add reddish spots
    vec3 tint = clamp(base * 0.5 * vec3(1, 0.5, 0.3), 0.0, 1.0);
    return base = mix(base, tint, smoothstep(0.45, 0.75, m));
}

float getMetalness(float h){
    return smoothstep(0.6, 0.7, h);
}

float getRoughness(float h){
    return mix(0.4, 0.9, smoothstep(0.8, 0.2, h));
}

//---------------------------- PBR ----------------------------

// Trowbridge-Reitz
float distribution(vec3 n, vec3 h, float roughness){
    float a_2 = roughness * roughness;
	return a_2/(PI * pow(pow(dot_c(n, h), 2.0) * (a_2 - 1.0) + 1.0, 2.0));
}

// GGX and Schlick-Beckmann
float geometry(float cosTheta, float k){
	return (cosTheta) / (cosTheta * (1.0 - k) + k);
}

float smiths(float NdotV, float NdotL, float roughness){
    float k = pow(roughness + 1.0, 2.0) / 8.0; 
	return geometry(NdotV, k) * geometry(NdotL, k);
}

vec3 fresnelSchlickRoughness(float cosTheta, vec3 F0, float roughness){
    return F0 + (max(vec3(1.0-roughness), F0) - F0) * pow(1.0 - cosTheta, 5.0);
}

// Cook-Torrance BRDF
vec3 BRDF(vec3 p, vec3 n, vec3 viewDir, vec3 lightDir, vec3 albedo, float metalness, 
            float roughness, vec3 F0){
            
    vec3 h = normalize(viewDir + lightDir);
    float cosTheta = dot_c(h, viewDir);
    
    // Lambertian diffuse reflectance
    vec3 diffuse = albedo / PI;
    
    // Normal distribution
    // What fraction of microfacets are aligned in the correct direction
    float D;

    // Fresnel term
    // How reflective are the microfacets viewed from the current angle
    vec3 F = fresnelSchlickRoughness(cosTheta, F0, roughness);

    // Geometry term
    // What fraction of the microfacets are lit and visible
    float G;
    
    // Visibility term. 
    // In Filament it combines the geometry term and the denominator
    float V;
    
    float NdotL = dot_c(lightDir, n);
    float NdotV = dot_c(viewDir, n);
    
    D = distribution(n, h, roughness);
    G = smiths(NdotV, NdotL, roughness);
    V = G / max(0.0001, (4.0 * NdotV * NdotL));
        
    // Specular reflectance
    vec3 specular = D * F * V;
    
    // Combine diffuse and specular
    vec3 kD = (1.0 - F) * (1.0 - metalness);
    return kD * diffuse + specular;
}


//---------------------------- Shadows ----------------------------

// https://iquilezles.org/articles/rmshadows
float softShadow(vec3 pos, vec3 rayDir, float start, float end, float k ){
    float res = 1.0;
    float depth = start;
    int id;
    for(int counter = ZERO; counter < 32; counter++){
        float dist = getSDF(pos + rayDir * depth, rayDir, id);
        if( abs(dist) < EPSILON){ return 0.0; }       
        if( depth > end){ break; }
        res = min(res, k*dist/depth);
        depth += dist;
    }
    return res;
}

//---------------------------- Lighting ----------------------------

vec3 getLightPosition(int i){

    float offset = -1.0;

    if(i == 0){
        return vec3(30.0*cos(offset+0.2), 8.0, -30.0*sin(offset+0.2)); 
    }
    return vec3(20.0*cos(3.2+offset), 1.0,  -20.0*sin(3.2+offset));
}

vec3 getEnvironment(vec3 rayDir){
    return mix(0.5*vec3(0.5, 0.3, 0.1), vec3(0.09, 0.35, 0.81), 0.5+0.5*rayDir.y);
}

vec3 getAmbientLight(vec3 normal){
    vec3 gradient = mix(vec3(0.15), vec3(2), 0.5+0.5*normal.y);
    return 1.0*mix(gradient, 4.0*getEnvironment(normal), 0.15);
}

vec3 getIrradiance(vec3 p, vec3 rayDir, vec3 geoNormal, int partID){
    vec3 I = vec3(0);
    vec3 radiance = vec3(0);
    vec3 lightDir = vec3(0);
    vec3 vectorToLight = vec3(0);
    
    // While lighting uses the actual point in space, texturing requires the 
    // position relative to the shape so that it's unaffected by transformation.
    // To undo translation and rotation points are offset and rotated while normals are 
    // only rotated. We obtain object space coordinates and normal
    vec3 textureP = p;
    vec3 textureNormal = geoNormal;
    
    switch(partID){
        case CORE: 
            textureP = getCoreOffset(p);
            textureP = getCoreRotation(textureP);
            textureNormal = getCoreRotation(geoNormal);
            break;
        case HEAD: textureP = getHeadOffset(p); break;
        case HANDS:
            textureP = getHandOffset(p);
            textureP = getHandRotation(textureP);
            textureNormal = getHandRotation(geoNormal);
            break;
        case MIDDLE: 
            textureP = getMiddleOffset(p);
            textureP = getMiddleRotation(textureP);
            textureNormal = getMiddleRotation(geoNormal);
            break;
        case BOTTOM: 
            textureP = getBottomOffset(p);
            textureP = getBottomRotation(textureP);
            textureNormal = getBottomRotation(geoNormal);
            break;
    }
    
    // The detail normal is sampled in object space and then rotated to world-space
    // for shading
    vec3 n = getDetailNormal(textureP, textureNormal);
    
    switch(partID){
    case CORE:
        n = getCoreInverseRotation(n);
        break;
    case HANDS:
        n = getHandInverseRotation(n);
        break;
    case MIDDLE:
        n = getMiddleInverseRotation(n);
        break;
    case BOTTOM:
        n = getBottomInverseRotation(n);
        break;
    }
    
    
    vec4 data = getTriplanar(textureP, textureNormal);
    float h = data.r;
    float ao = data.a;
    
    vec3 albedo = getAlbedo(data.r, data.b);
    
    // Add bright ridges
    albedo += albedo * mix(0.0, 0.35, smoothstep(0.2, 1.5, ao));
    // Add dark crevices
    albedo *= mix(0.95, 1.0, smoothstep(0.25, 0.5, ao));

    float metalness = getMetalness(data.g);
    float roughness = getRoughness(h);
    roughness = mix(roughness, 0.1, metalness);

    // Index of refraction for common dielectrics. Corresponds to f0 0.04
    const float IOR = 1.5;

    // Reflectance of the surface when looking straight at it along the negative normal
    vec3 F0 = vec3(pow(IOR - 1.0, 2.0) / pow(IOR + 1.0, 2.0));
    
    // Metal uses gold reflectance
    F0 = mix(F0, vec3(1.022, 0.782, 0.344), metalness);
    
    // Find direct lighting for all sources
    for(int i = ZERO; i < 2; i++){
        
        vec3 position = getLightPosition(i);
        vectorToLight = position - p;
        lightDir = normalize(vectorToLight);
        radiance = i == 0 ? 3.0 * vec3(1.0, 0.95, 0.9) : 1.5 * vec3(0.45, 0.75, 1.0);
        
        float shadow = softShadow(p + n * EPSILON * 2.0, lightDir, MIN_DIST, 
                                                        MAX_DIST, SHADOW_SHARPNESS);
                                  
        I +=  shadow 
            * BRDF(p, n, -rayDir, lightDir, albedo, metalness, roughness, F0) 
            * radiance 
            * dot_c(n, lightDir);
    }

    
    // Use simple gradient for diffuse ambient light
    vec3 F = fresnelSchlickRoughness(dot_c(n, -rayDir), F0, roughness);
	vec3 kD = (1.0 - F) * (1.0 - metalness);
	vec3 irradiance = getAmbientLight(n);
	vec3 diffuse    = irradiance * albedo / PI;

    // Use low LOD of cubemap for specular ambient
    vec3 env = mix(0.5 * getEnvironment(reflect(rayDir, n)), 
               0.225 * textureLod(iChannel2, normalize(reflect(rayDir, n)), 4.0).rgb, 1.0);
    vec3 specular = env * F;
    
	vec3 ambient  = kD * diffuse + specular;
    
    // Add dark crevices for occlusion
    ambient *= mix(0.9, 1.0, smoothstep(0.25, 0.5, ao));
    
    // Combine direct and ambient lighting
    return ambient + I;
}

//-------------------------- Tonemap and render -------------------------

// https://knarkowicz.wordpress.com/2016/01/06/aces-filmic-tone-mapping-curve/
vec3 ACESFilm(vec3 x){
    return clamp((x * (2.51 * x + 0.03)) / (x * (2.43 * x + 0.59) + 0.14), 0.0, 1.0);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord ){
    
	//----------------- Define a camera -----------------
    
    vec3 rayDir = rayDirection(60.0, fragCoord);

    vec3 cameraPos = texelFetch(iChannel0, ivec2(0.5, 1.5), 0).xyz;
    vec3 targetDir = -cameraPos;
    vec3 up = vec3(0.0, 1.0, 0.0);

    // Get the view matrix from the camera orientation.
    mat3 viewMatrix = lookAt(cameraPos, targetDir, up);

    // Transform the ray to point in the correct direction.
    rayDir = normalize(viewMatrix * rayDir);

    //---------------------------------------------------

    vec3 p = vec3(0);
    vec3 col = vec3(0);
    
    // Keep track which part we render
    int partID = -1;
    float t = distanceToScene(cameraPos, rayDir, MIN_DIST, MAX_DIST, partID);
    
    if(t < MAX_DIST){
        p = cameraPos + rayDir * t;
        vec3 normal = getNormal(p, rayDir);
        col = getIrradiance(p, rayDir, normal, partID);
    } else {
        col = 0.05 * getEnvironment(rayDir);
    }
    
    col = ACESFilm(col);
    col = gamma(col);
    
    // Height map
    //col = texture(iChannel1, fragCoord/iResolution.xy).rrr;
    
    // Occlusion map
    //col = texture(iChannel1, fragCoord/iResolution.xy).aaa;
        
    fragColor = vec4(col, 1.0);
}
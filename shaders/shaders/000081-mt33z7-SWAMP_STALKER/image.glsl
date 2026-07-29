// Image (image) — SWAMP STALKER by alro
// https://www.shadertoy.com/view/mt33z7

/*

    Exploring rough transmission and subsurface scattering. Use mouse to move camera.
    
    Buffer B generates a pre-integrated subsurface scattering texture.
    Buffer C renders the interior geometry.
    
    The Image tab renders the exterior geometry and blends with the interior by blurring 
    based on depth.
    
    See Common tab to reduce the interior render resolution and improve performance.
    
    Bicubic blur for rough transmission based on:
    
    https://developer.download.nvidia.com/SDK/9.5/Samples/DEMOS/OpenGL/src/fast_third_order/docs/Gems2_ch20_SDK.pdf
    https://0xef.wordpress.com/2013/01/12/third-order-texture-filtering-using-linear-interpolation/
    https://www.shadertoy.com/view/Dl2SDW
    https://www.shadertoy.com/view/4df3Dn
    https://stackoverflow.com/questions/13501081/efficient-bicubic-filtering-code-in-glsl

*/

//#define DISPLAY_INTERIOR

//#define DISPLAY_SSS_TEXTURE

// Only for one light
//#define DISPLAY_SSS

const float topTransmission = 0.75;
const float bottomTransmission = 0.0;

vec3 baseColour = 0.15 * vec3(0.9, 0.9, 0.95);
vec3 detailColour = 0.1 * vec3(0.8, 0.3, 0.3);

const float SHADOW_SHARPNESS = 8.0;

const float EPSILON = 1e-4;
const float MIN_DIST = 0.01;
const int MAX_STEPS = 60;
const float MAX_DIST = 8.0;
const vec3 DETAIL_SCALE = vec3(0.15);
const vec3 BLENDING_SHARPNESS = vec3(2.0);
const float DETAIL_HEIGHT = 0.02;

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

float displacement(vec3 p){
    return sin(p.x);
}

vec2 radialRepetition(vec2 p, float cells){
    float an = TWO_PI/cells;
    float fa = (atan(p.y,p.x)+an*0.5)/an;
    float sym = an*floor(fa);
    p.xy = mat2(cos(sym),-sin(sym), sin(sym), cos(sym))*p.xy;
    return p;
}

//---------------------- Distance functions ----------------------
//https://iquilezles.org/articles/distfunctions/

float sdBox( vec3 p, vec3 b ){
  vec3 q = abs(p) - b;
  return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
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


//------------------------- Geometry -------------------------

float legSDF(vec3 p){

    float dist = 1e5;
    vec3 q = p;
    
    q.y += 1.35;
    q.x -= 0.8;
    q = rotateY(q, PI/6.0);

    q.xz = radialRepetition(q.xz, 6.0);
    
    q.y += 0.05*(0.5+0.5*displacement(12.0*q));
    
    q.x -= 0.45;
    q = rotateZ(q, -0.4);
    dist = sdRoundCone(q, 0.09, 0.2, 1.0);
    
    q = rotateZ(q, 0.9);
    dist = smoothMin(dist, sdRoundCone(q, 0.089, 0.07, 0.85), 0.0);
    
    q.y -= 0.85;
    q = rotateZ(q, 0.85);
    dist = smoothMin(dist, sdRoundCone(q, 0.07, 0.03, 0.5), 0.0);
    
    q.y -= 0.5;
    q = rotateZ(q, 0.45);
    dist = smoothMin(dist, sdRoundCone(q, 0.03, 0.005, 0.65), 0.0);
    
    dist = smoothSub(-sdBox(q, vec3(2.0, 2.0, 0.05)), dist, 0.05);
    
    return 0.8*dist;
}

float eyeSDF(vec3 p){

    float dist = 1e5;
    vec3 q = p;
   
    q.x -= 1.1;
    q.y += 0.8;
    q.z = abs(q.z);
    q.z -= 0.15;
    dist = sphereSDF(q, 0.115);

    q.z -= 0.15;
    q.x += 0.05;
    dist = min(dist, sphereSDF(q, 0.075));

    q.y -= 0.125;
    q.z += 0.05;
    q.x -= 0.075;
    dist = min(dist, sphereSDF(q, 0.075));
    
    return dist;
}

float bodySDF(vec3 p){
    float dist = 1e5;
    vec3 q = p;
    
    q.y -= 0.1;
    dist = sphereSDF(q, 1.1);
    q.y -= 0.8;
    q.x += 0.8;
    dist = smoothMin(dist, sphereSDF(q, 0.2), 1.2);
    
    return dist;
}

float getSDF(vec3 p, vec3 dir, out float transmission){

    p -= modelOffset;

    transmission = bottomTransmission;

    float dist = 1e5;
    vec3 q = p;
    
    float previousDist = dist;

    // Legs
    if(testAABB(p, dir, vec3(-0.45, -2.0, -1.4), 
                        vec3(2.1, -0.8, 1.4))){
        q = p;
        q.x -= 0.75;
        q.y += 1.05;
        dist = sphereSDF(q, 0.3);
        dist = smoothMin(dist, legSDF(p), 0.04);

        if(previousDist > dist){
                previousDist = dist;
                transmission = bottomTransmission;
        }
    }
    
    // Body
    if(testAABB(p, dir, vec3(-1.3, -2.0, -1.1), 
                        vec3(1.2, 1.8, 1.1))){
        q = p;
        dist = min(bodySDF(q), dist);

        if(previousDist > dist){
                previousDist = dist;
                q = p;
                q = rotateZ(q, -0.25);
                transmission = mix(bottomTransmission, topTransmission, 
                                            smoothstep(-1.0, 0.0, q.y));
        }
    }
    
    // Head
    if(testAABB(p, dir, vec3(0.0, -1.25, -0.75), 
                        vec3(1.3, 0.1, 0.75))){
        q = p;
        q.x -= 0.75;
        q.y += 0.6;

        // Mix transmission using smoothMin
        transmission = mix( bottomTransmission, 
                            transmission, 
                            saturate(0.5+0.5*(sphereSDF(q, 0.5)-dist)/0.2));
                            
        dist = smoothMin(dist, sphereSDF(q, 0.5), 0.2);

        if(previousDist > dist){
                previousDist = dist;
        }
    }

    // Eyes
    if(testAABB(p, dir, vec3(1.0, -1.0, -0.4), 
                        vec3(1.3, -0.6, 0.4))){
        q = p;
        dist = min(dist, eyeSDF(q));

        if(previousDist > dist){
                transmission = bottomTransmission;
                previousDist = dist;
        }
    }
    return dist;
}

float distanceToScene(vec3 cameraPos, vec3 rayDir, float start, float end, 
                      out float transmission) {
	
    float depth = start;
    
    float dist;
    
    for (int i = ZERO; i < MAX_STEPS; i++){

        dist = getSDF(cameraPos + depth * rayDir, rayDir, transmission);

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
    float t;
    for(int i = ZERO; i < 4; i++){
        vec3 e = 0.5773*(2.0*vec3((((i+3)>>1)&1),((i>>1)&1),(i&1))-1.0);
        n += e*getSDF(p+e*EPSILON, dir, t);
    }
    return normalize(n);
}

float getTriplanar(vec3 position, vec3 normal){
    float xaxis = texture(iChannel1, DETAIL_SCALE.x*(position.zy)).a;
    float yaxis = texture(iChannel1, DETAIL_SCALE.y*(position.zx)).a;
    float zaxis = texture(iChannel1, DETAIL_SCALE.z*(position.xy)).a;

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
    float detail = DETAIL_HEIGHT*length(getTriplanar(p, normal));
    return p + detail * normal;
}

// Get orthonormal basis from surface normal
// https://graphics.pixar.com/library/OrthonormalB/paper.pdf
void pixarONB(vec3 n, out vec3 b1, out vec3 b2){
	float sign_ = n.z >= 0.0 ? 1.0 : -1.0;
	float a = -1.0 / (sign_ + n.z);
	float b = n.x * n.y * a;
	b1 = vec3(1.0 + sign_ * n.x * n.x * a, sign_ * b, -sign_ * n.x);
	b2 = vec3(b, sign_ + n.y * n.y * a, -n.y);
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


//---------------------------- Transmission ----------------------------

// Cubic B-spline weighting
vec2 w0(vec2 a){
    return (1.0/6.0)*(a*(a*(-a + 3.0) - 3.0) + 1.0);
}

vec2 w1(vec2 a){
    return (1.0/6.0)*(a*a*(3.0*a - 6.0) + 4.0);
}

vec2 w2(vec2 a){
    return (1.0/6.0)*(a*(a*(-3.0*a + 3.0) + 3.0) + 1.0);
}

vec2 w3(vec2 a){
    return (1.0/6.0)*(a*a*a);
}

// g0 is the amplitude function
vec2 g0(vec2 a){
    return w0(a) + w1(a);
}

// h0 and h1 are the two offset functions
vec2 h0(vec2 a){
    return -1.0 + w1(a) / (w0(a) + w1(a));
}

vec2 h1(vec2 a){
    return 1.0 + w3(a) / (w2(a) + w3(a));
}

vec4 bicubic(sampler2D tex, vec2 uv, vec2 textureLodSize, float lod){
	
    uv = uv * textureLodSize + 0.5;
    
	vec2 iuv = floor(uv);
	vec2 f = fract(uv);

    // Find offset in texel
    vec2 h0 = h0(f);
    vec2 h1 = h1(f);

    // Four sample points
	vec2 p0 = (iuv + h0 - 0.5) / textureLodSize;
	vec2 p1 = (iuv + vec2(h1.x, h0.y) - 0.5) / textureLodSize;
	vec2 p2 = (iuv + vec2(h0.x, h1.y) - 0.5) / textureLodSize;
	vec2 p3 = (iuv + h1 - 0.5) / textureLodSize;
	
    // Weighted linear interpolation
    // g0 + g1 = 1 so only one is needed for a mix
    vec2 g0 = g0(f);
    return mix( mix(textureLod(tex, p3, lod), textureLod(tex, p2, lod), g0.x),
                mix(textureLod(tex, p1, lod), textureLod(tex, p0, lod), g0.x), g0.y);
}

vec4 textureBicubic(sampler2D s, vec2 uv, float lod) {

    vec2 lodSizeFloor = vec2(textureSize(s, int(lod)));
    vec2 lodSizeCeil = vec2(textureSize(s, int(lod + 1.0)));

    vec4 floorSample = bicubic(s, uv, lodSizeFloor.xy, floor(lod));
    vec4 ceilSample = bicubic(s, uv, lodSizeCeil.xy, ceil(lod));

    return mix(floorSample, ceilSample, fract(lod));
}

vec4 getRoughTransmission(sampler2D s, vec2 uv, float roughness){
    float maxLod = floor(log2(iChannelResolution[3].x));
    float lod = mix(0.0, maxLod-1.0, roughness * roughness);
    
    return textureBicubic(s, uv, lod);
}

//---------------------------- Material ----------------------------

vec3 getAlbedo(vec3 p){
    p -= modelOffset;
    
    p*= 32.0;
    float g = dot(sin(p), cos(p.zxy));
    p *= 0.5;
    g += dot(sin(p), cos(p.zxy));

    return mix(baseColour, detailColour, smoothstep(0.0, 5.8, g));
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
float specularBRDF(vec3 n, vec3 viewDir, vec3 lightDir, vec3 h, float roughness){
    
    // Normal distribution
    // What fraction of microfacets are aligned in the correct direction
    float D;

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
    return D * V;
}

//---------------------------- Shadows ----------------------------

// https://iquilezles.org/articles/rmshadows
float softShadow(vec3 pos, vec3 rayDir, float start, float end, float k ){
    float res = 1.0;
    float depth = start;
    float t;
    for(int counter = ZERO; counter < 16; counter++){
        float dist = getSDF(pos + rayDir * depth, rayDir, t);
        if( abs(dist) < EPSILON){ return 0.0; }       
        if( depth > end){ break; }
        res = min(res, k*dist/depth);
        depth += dist;
    }
    return saturate(res);
}

//---------------------------- Lighting ----------------------------

vec3 getAmbientLight(vec3 normal){
    vec3 gradient = mix(vec3(0.15), vec3(2), 0.5+0.5*normal.y);
    return mix(gradient, 4.0*getEnvironment(normal), 0.15);
}

vec3 getTransmitted(vec2 uv, float t){

    vec4 background = texture(iChannel3, uv * RENDER_SCALE);

    float dist = background.a - t;
    float roughness = mix(0.4, 0.7, smoothstep(0.0, 0.65, dist));
    if(background.a < 0.0){
        roughness = 0.7;
    }

    vec4 roughBackground = getRoughTransmission(iChannel3, uv * RENDER_SCALE, roughness);
    vec3 col = vec3(0);
    col = roughBackground.rgb;
    return col;
}

vec3 getIrradiance(vec3 p, vec3 rayDir, vec3 geoNormal, vec2 uv, float t, float transmission){
    
    vec3 I = vec3(0);
    vec3 radiance = vec3(0);
    vec3 lightDir = vec3(0);
    vec3 vectorToLight = vec3(0);
    
    vec3 albedo = getAlbedo(p);
    
    // Tint legs
    albedo = mix(0.5*vec3(1.0,0.1,0.1) * albedo, albedo, smoothstep(-1.4, -0.5, p.y));
    
    vec3 n = getDetailNormal(p, geoNormal);
  
    float metalness = 0.0;
    float roughness = 0.175;
    roughness = mix(roughness, 0.1, metalness);

    float IOR = 1.44;

    float eyeWeight = smoothstep(5e-3, 0.0, eyeSDF(p - modelOffset));

    albedo = mix(albedo, vec3(0), eyeWeight);
    n = mix(n, geoNormal, eyeWeight);
    IOR = mix(IOR, 2.0, eyeWeight);
    roughness = mix(roughness, 0.05, eyeWeight);
    
    // Reflectance of the surface when looking straight at it along the negative normal
    vec3 F0 = vec3(pow(IOR - 1.0, 2.0) / pow(IOR + 1.0, 2.0));
    
    // Metal uses gold reflectance
    F0 = mix(F0, vec3(1.022, 0.782, 0.344), metalness);
    
    vec3 directDiffuse = vec3(0);
    vec3 directSpecular = vec3(0);
    
    // Find direct lighting for all sources
    for(int i = ZERO; i < 2; i++){
        
        vec3 position = getLightPosition(i);
        vectorToLight = position - p;
        lightDir = normalize(vectorToLight);
        radiance = i == 0 ? 1.0 * vec3(1.0) : 1.0 * vec3(0.45, 0.75, 1.0);
        
        float shadow = softShadow(p + n * EPSILON * 2.0, lightDir, MIN_DIST, 
                                                        MAX_DIST, SHADOW_SHARPNESS);
                                                        
        vec3 h = normalize(-rayDir + lightDir);
        // Fresnel term
        // How reflective are the microfacets viewed from the current angle
        vec3 F = fresnelSchlickRoughness(dot_c(h, -rayDir), F0, roughness);
        vec3 specular = F * specularBRDF(n, -rayDir, lightDir, h, roughness);
        
        float d = 0.5 + 0.5 * dot(geoNormal, lightDir);
        vec3 sss = 0.5 * texture(iChannel1, vec2(max(d, 0.001), 0.75)).rgb;

#ifdef DISPLAY_SSS
        return sss;
#endif
        directDiffuse += sss * albedo * radiance;
        directSpecular += shadow * specular * radiance * dot_c(n, lightDir);
    }
    
    // Use simple gradient for diffuse ambient light
    vec3 F = fresnelSchlickRoughness(dot_c(n, -rayDir), F0, roughness);
	vec3 kD = (1.0 - F) * (1.0 - metalness);
	vec3 irradiance = getAmbientLight(n);
	vec3 ambientDiffuse = kD * irradiance * albedo / PI;

    // Use low LOD of cubemap for specular ambient
    vec3 env = 0.225 * textureLod(iChannel2, normalize(reflect(rayDir, n)), 4.0).rgb;
    vec3 ambientSpecular = env * F;
    
    vec3 diffuse = directDiffuse + ambientDiffuse;
    
    diffuse = mix(diffuse + directDiffuse, getTransmitted(uv, t), transmission);
    
    // Combine direct and ambient lighting
    return  diffuse + directSpecular + ambientSpecular;
}

//-------------------------- Tonemap and render -------------------------

// https://knarkowicz.wordpress.com/2016/01/06/aces-filmic-tone-mapping-curve/
vec3 ACESFilm(vec3 x){
    return clamp((x * (2.51 * x + 0.03)) / (x * (2.43 * x + 0.59) + 0.14), 0.0, 1.0);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord ){

    vec2 uv = fragCoord.xy/iResolution.xy;
    
	//----------------- Define a camera -----------------
    
    vec3 rayDir = rayDirection(60.0, fragCoord, iResolution.xy);

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
    
    float t = MAX_DIST;
    float transmission = 0.0;

    if(testAABB(cameraPos, rayDir, vec3(-1.3, -2.0, -1.4) + modelOffset, 
                                   vec3(2.1, 1.4, 1.4) + modelOffset)){
        t = distanceToScene(cameraPos, rayDir, MIN_DIST, MAX_DIST, transmission);
    }
    
    if(t < MAX_DIST){
        p = cameraPos + rayDir * t;
        vec3 normal = getNormal(p, rayDir);
        col = getIrradiance(p, rayDir, normal, uv, t, transmission);
    } else {
        col = 0.1 * getEnvironment(rayDir);
    }
    
#ifdef DISPLAY_INTERIOR
    col = getRoughTransmission(iChannel3, uv*RENDER_SCALE, 0.0).rgb;
#endif
#ifdef DISPLAY_SSS_TEXTURE
    col = texture(iChannel1, uv).rgb;
#endif
    
    col = ACESFilm(col);
    col = gamma(col);
        
    fragColor = vec4(col, 1.0);
}
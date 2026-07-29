// Image (image) — CURIOUS CRYSTAL by alro
// https://www.shadertoy.com/view/slccDX

/*
    Scattering media inside a refractive substance. Use mouse to move camera.
*/

// Variable iterator initializer to stop loop unrolling
#define ZERO (min(iFrame,0))

const int MAX_STEPS = 64;
const float MIN_DIST = 0.01;
const float MAX_DIST = 5.0;
const float EPSILON = 1e-3;
const float DETAIL_EPSILON = 2e-3;
const float DETAIL_HEIGHT = 0.002;
const vec3 DETAIL_SCALE = vec3(0.35);
const vec3 BLENDING_SHARPNESS = vec3(4.0);

#define IOR 2.0

// Ratios of air and crystal IOR for refraction
// Air to crystal
#define ETA 1.0/IOR
// Crystal to air
#define ETA_REVERSE IOR

// Internal structure
const vec3 mainColour = vec3(0.935, 0.75, 0.5);

const float DENSITY = 1000.0;
const float DENSITY_POW = 1.0;
const float SCALE = 24.0;

const vec3 light = vec3(0.35);
const vec3 lightDirection = normalize(vec3(1));

vec3 getSkyColour(vec3 rayDir){
    return pow(texture(iChannel1, rayDir).rgb, vec3(2.2));
}


//-------------------------------- Camera --------------------------------

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

//-------------------------------- Rotations --------------------------------

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


//---------------------------- Distance functions ----------------------------

// Distance functions and operators from:
// https://iquilezles.org/articles/distfunctions

float displacement(vec3 p){
    return sin(p.x)*sin(p.y)*sin(p.z);
}

float opDisplace(vec3 p){
    vec3 offset = normalize(vec3(1));
    return displacement(15.0*(p+offset));
}

float opSmoothSub( float d1, float d2, float k ) {
    float h = clamp( 0.5 - 0.5*(d2+d1)/k, 0.0, 1.0 );
    return mix( d2, -d1, h ) + k*h*(1.0-h); }

float sphereSDF(vec3 p, float radius) {
    return length(p) - radius;
}

float planeSDF(vec3 p, vec3 normal, float dist){
	return dot(p, normal) - dist;
}

// https://iquilezles.org/articles/smin
float smoothMin(float a, float b, float k){
    float h = clamp(0.5+0.5*(b-a)/k, 0.0, 1.0 );
    return mix( b, a, h ) - k*h*(1.0-h);
}

vec3 getRotatedPoint(vec3 p){
     return rotateX(p, 0.6);
}

float getSDF(vec3 p, float sdfSign){
    
    p = getRotatedPoint(p);
    
    const float SIDES = 7.0;
    float k = 0.002;
    float dist = sphereSDF(p, 10.0);
    for(float i = 0.0; i < SIDES; i += 1.0){
        float angle = i * TWO_PI/SIDES;
        vec3 n = normalize(rotateY(vec3(1, 0, 0), angle+0.707));
        float sideDist = planeSDF(p, n, -0.45);
        dist = opSmoothSub(sideDist, dist, k);
        
        n = normalize(rotateX(vec3(0,0,1), 0.65));
        n = normalize(rotateY(n, angle));
        float topDist = planeSDF(p, n, -0.65);
        dist = opSmoothSub(topDist, dist, k);
        
        n = normalize(rotateX(vec3(0,0,1), -0.65));
        n = normalize(rotateY(n, angle));
        topDist = planeSDF(p, n, -0.65);
        dist = opSmoothSub(topDist, dist, k);
    }

    return sdfSign * dist;
}

float distanceToScene(vec3 cameraPos, vec3 rayDir, float start, float end, float sdfSign){
	
    // Start at a predefined distance from the camera in the ray direction
    float depth = start;
    
    // Variable that tracks the distance to the scene at the current ray endpoint
    float dist;
    
    // For a set number of steps
    for (int i = ZERO; i < MAX_STEPS; i++) {
        
        // Get the sdf value at the ray endpoint, giving the maximum 
        // safe distance we can travel in any direction without hitting a surface
        dist = getSDF(cameraPos + depth * rayDir, sdfSign);
        
        // If it is small enough, we have hit a surface
        // Return the depth that the ray travelled through the scene
        if (dist < EPSILON){
            return depth;
        }
        
        // Else, march the ray by the sdf value
        depth += dist;
        
        // Test if we have left the scene
        if (depth >= end){
            return end;
        }
    }

    return depth;
}


//----------------------------- Normal mapping -----------------------------

// https://tinyurl.com/y5ebd7w7
float getTriplanar(vec3 position, vec3 normal){
    float xaxis = texture(iChannel2, DETAIL_SCALE.x*(position.zy)).b;
    float yaxis = texture(iChannel2, DETAIL_SCALE.y*(position.zx)).b;
    float zaxis = texture(iChannel2, DETAIL_SCALE.z*(position.xy)).b;

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
    float detail = DETAIL_HEIGHT * getTriplanar(p, normal);
    return p + detail * normal;
}

// Tetrahedral normal technique with a loop to avoid inlining getSDF()
// This should improve compilation times
// https://iquilezles.org/articles/normalsSDF
vec3 getNormal(vec3 p, float sdfSign){
    vec3 n = vec3(0.0);
    int id;
    for(int i = ZERO; i < 4; i++){
        vec3 e = 0.5773*(2.0*vec3((((i+3)>>1)&1),((i>>1)&1),(i&1))-1.0);
        n += e*getSDF(p+e*EPSILON, sdfSign);
    }
    return normalize(n);
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

// Return the normal after applying a normal map
vec3 getDetailNormal(vec3 p, vec3 normal){

    vec3 tangent;
    vec3 bitangent;
    
    // Construct orthogonal directions tangent and bitangent to sample detail gradient in
    pixarONB(normal, tangent, bitangent);
    
    tangent = normalize(tangent);
    bitangent = normalize(bitangent);

    vec3 delTangent = vec3(0);
    vec3 delBitangent = vec3(0);
    
    for(int i = ZERO; i < 2; i++){
        
        //i to  s
        //0 ->  1
        //1 -> -1
        float s = 1.0 - 2.0 * float(i&1);
    
        delTangent += s * getDetailExtrusion(p + s * tangent * DETAIL_EPSILON, normal);
        delBitangent += s * getDetailExtrusion(p + s * bitangent * DETAIL_EPSILON, normal);

    }
    
    return normalize(cross(delTangent, delBitangent));
}

float getPerlinNoise(vec3 pos){

    // Find an interesting section of the noise field
    pos += vec3(0.0, 12.0, -3.0);

    // The noise texture is an atlas of 6*6 tiles (36). 
    // Each tile is 32*32 with a 1 pixel wide boundary.
    // Per tile:		32 + 2 = 34.
    // Atlas width:	6 * 34 = 204.
    // The rest of the texture is black.
    // The 3D texture the atlas represents has dimensions 32 * 32 * 36.
    // The green channel is the data of the red channel shifted by one tile.
    // (tex.g is the data one level above tex.r). 
    // To get the necessary data only requires a single texture fetch.
    const float dataWidth = 204.0;
    const float tileRows = 6.0;
    const vec3 atlasDimensions = vec3(32.0, 32.0, 36.0);

    // Change from Y being height to Z being height.
    vec3 p = pos.xzy;

    // Pixel coordinates of point in the 3D data.
    vec3 coord = vec3(mod(p, atlasDimensions));
    float f = fract(coord.z);  
    float level = floor(coord.z);
    float tileY = floor(level/tileRows); 
    float tileX = level - tileY * tileRows;

    // The data coordinates are offset by the x and y tile, the two boundary cells 
    // between each tile pair and the initial boundary cell on the first row/column.
    vec2 offset = atlasDimensions.x * vec2(tileX, tileY) + 2.0 * vec2(tileX, tileY) + 1.0;
    vec2 pixel = coord.xy + offset;
    vec2 data = texture(iChannel2, mod(pixel, dataWidth)/iChannelResolution[0].xy).xy;
    return smoothstep(0.45, 1.0, mix(data.x, data.y, f));
}

float getInternalDensity(vec3 pos){
    pos = getRotatedPoint(pos);
    float clearSides = smoothstep(0.4, 0.0, length(pos.xz));
    float clearTop = smoothstep(0.5, 0.0, pos.y);
    return 0.2 + clearSides * clearTop * DENSITY * pow(getPerlinNoise(SCALE * pos), DENSITY_POW);
}

const vec3 sigmaS = 1.0-mainColour;
const vec3 sigmaA = vec3(0);
// Extinction coefficient.
const vec3 sigmaE = max(sigmaS + sigmaA, vec3(1e-6));

// Get the amount of light that reaches a sample point.
vec3 lightRay(vec3 org, vec3 p, vec3 lightDirection){

    float distToStart = 0.0;
    const float STEPS_LIGHT = 3.0;
    float stepL = 0.03;

	float lightRayDensity = 0.0;

	// Collect total density along light ray.
	for(float j = 0.0; j < STEPS_LIGHT; j++){      
		lightRayDensity += getInternalDensity(p + lightDirection * j * stepL);
	}
    
	return exp(-lightRayDensity * sigmaS * stepL);
}

vec3 getInterior(vec3 org, vec3 rayDir, float rayLength, out vec3 totalTransmittance){
    const float STEP_COUNT = 20.0;
    float stepS = rayLength / STEP_COUNT;

    float density = 0.0;
    vec3 pos = org;
    float dist = 0.0;
    totalTransmittance = vec3(1);

    vec3 colour = vec3(0);
    
    for(float i = 0.0; i < STEP_COUNT; i++){
        density += getInternalDensity(pos);
  
        vec3 sampleSigmaS = sigmaS * density;
        vec3 sampleSigmaE = sigmaE * density;

        // If there is a cloud at the sample point.
        if(density > 0.0 ){

            //Constant lighting factor based on the height of the sample point.
            vec3 ambient = vec3(1);

            // Amount of sunlight that reaches the sample point through the cloud 
            // is the combination of ambient light and attenuated direct light.
            vec3 luminance = light * lightRay(org, pos, lightDirection);

            // Scale light contribution by density of the cloud.
            luminance *= sampleSigmaS;

            // Beer-Lambert.
            vec3 transmittance = exp(-sampleSigmaE * stepS);

            // Better energy conserving integration
            // "From Physically based sky, atmosphere and cloud rendering in Frostbite" 5.6
            // by Sebastian Hillaire.
            colour += 
                totalTransmittance * (luminance - luminance * transmittance) / sampleSigmaE; 

            // Attenuate the amount of light that reaches the camera.
            totalTransmittance *= transmittance;  

            // If ray combined transmittance is close to 0, nothing beyond this sample 
            // point is visible, so break early.
            if(length(totalTransmittance) <= 0.001){
                totalTransmittance = vec3(0.0);
                return colour;
            }
        }

        dist += stepS;

		// Step along ray.
		pos = org + rayDir * dist;
    }

    return colour;
}

// From the closest intersection with the scene, raymarch the negative SDF field to 
// find the far instersection. The distance inside the crystal is used to determine 
// transmittance and the attenuation of the environment.
vec3 getEnvironment(vec3 org, vec3 rayDir){
    float sdfSign = -1.0;

    float distFar = distanceToScene(org, rayDir, MIN_DIST, MAX_DIST, sdfSign);

    vec3 positionFar = org + rayDir * distFar;
    vec3 geoNormalFar = getNormal(positionFar, sdfSign);

    //Use the geometry normal on the far side to reduce noise
    vec3 refractedDir = normalize(refract(rayDir, geoNormalFar, ETA_REVERSE));

    // When total internal reflection occurs, reflect the ray off the far side
    if(dot(-rayDir, geoNormalFar) <= cos(asin(ETA))){
        refractedDir = normalize(reflect(rayDir, geoNormalFar));
    }

    vec3 transmitted = getSkyColour(refractedDir);

    vec3 totalTransmittance = vec3(1);
    vec3 col = getInterior(org, rayDir, distFar, totalTransmittance);
    
    col += transmitted * totalTransmittance;
    return col;
}

//------------------------------- Shading -------------------------------

// Fresnel-Schlick
vec3 fresnel(float cosTheta, vec3 F0){
    return F0 + (1.0 - F0) * pow(1.0 - cosTheta, 5.0);
} 

vec3 shading(vec3 p, vec3 n, vec3 rayDir, vec3 geoNormal){
    vec3 I = vec3(0);

    vec3 albedo = vec3(0.5);    

    // Reflectance of the surface when looking straight at it along the negative normal
    vec3 F0 = vec3(pow(IOR - 1.0, 2.0) / pow(IOR + 1.0, 2.0));
        
    vec3 ambientColour = getEnvironment(p + rayDir * 2.0 * EPSILON, refract(rayDir, n, ETA));                          
    vec3 reflectedCol = getSkyColour(reflect(rayDir, n));

    vec3 F = fresnel(dot_c(n, -rayDir), F0);
    
    return mix(ambientColour, reflectedCol, F);
}

//----------------------------- Tonemapping and output ------------------------------

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
    
    // Find the distance to where the ray stops.
    float dist = distanceToScene(cameraPos, rayDir, MIN_DIST, MAX_DIST, 1.0);
    
    vec3 col = vec3(0);
    
    if(dist < MAX_DIST){
        vec3 position = cameraPos + rayDir * dist;
        vec3 geoNormal = getNormal(position, 1.0);

        // Avoid artefacts when trying to sample detail normals across Z-plane.
        if(abs(geoNormal.z) < 1e-5){
            geoNormal.z = 1e-5;
        }

        geoNormal = normalize(geoNormal);

        vec3 detailNormal = normalize(getDetailNormal(getRotatedPoint(position), geoNormal));

        col = shading(position, detailNormal, rayDir, geoNormal);

    } else {
        col = 0.02 * mix(vec3(0.81, 0.09, 0.33), vec3(0.09, 0.33, 0.81), (0.5 + 0.5 * rayDir.y));
        // col = getSkyColour(rayDir);
    }
    
    // Tonemapping
    col = ACESFilm(col);

    // Gamma
    col = pow(col, vec3(0.4545));
    
    //vec2 uv = fragCoord/iResolution.xy;
    //col = texture(iChannel2, uv).rgb;

    fragColor = vec4(col, 1.0);
}
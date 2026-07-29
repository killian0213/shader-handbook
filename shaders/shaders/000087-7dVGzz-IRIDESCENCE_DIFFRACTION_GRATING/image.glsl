// Image (image) — IRIDESCENCE: DIFFRACTION GRATING by alro
// https://www.shadertoy.com/view/7dVGzz

/*
    Diffraction grating from microsurface features on the scale of the wavelengths of
    visible light leads to structural colour with regular spectral ordering.
    This is most commonly observed in optical disc reflections.

    Thin film iridescence: https://www.shadertoy.com/view/7sV3Rh

    Based on:
        https://www.alanzucconi.com/2017/07/15/the-nature-of-light/
        https://developer.download.nvidia.com/books/HTML/gpugems/gpugems_ch08.html
        https://www.shadertoy.com/view/ls2Bz1

*/

// Edit: The spectrum code should have gamma correction removed

// Variable iterator initializer to stop loop unrolling
#define ZERO (min(iFrame,0))

const vec3 DETAIL_SCALE = vec3(3.0);
const vec3 BLENDING_SHARPNESS = vec3(128.0);

const int MAX_STEPS = 64;
const float MIN_DIST = 0.0;
const float MAX_DIST = 10.0;
const float EPSILON = 3e-3;

const float minDot = 1e-5;

// Clamped dot product
float dot_c(vec3 a, vec3 b){
	return max(dot(a, b), minDot);
}

//----------------------------- Camera ------------------------------

vec3 rayDirection(float fieldOfView, vec2 fragCoord) {
    vec2 xy = fragCoord - iResolution.xy / 2.0;
    float z = (0.5 * iResolution.y) / tan(radians(fieldOfView) / 2.0);
    return normalize(vec3(xy, -z));
}

//https://www.geertarien.com/blog/2017/07/30/breakdown-of-the-lookAt-function-in-OpenGL/
mat3 lookAt(vec3 camera, vec3 targetDir, vec3 up){
    vec3 zaxis = normalize(targetDir);    
    vec3 xaxis = normalize(cross(zaxis, up));
    vec3 yaxis = cross(xaxis, zaxis);

    return mat3(xaxis, yaxis, -zaxis);
}

//-------------------------- SDF and scene ---------------------------

vec3 rotate(vec3 p, vec4 q){
    return 2.0 * cross(q.xyz, p * q.w + cross(q.xyz, p)) + p;
}

vec3 getRotation(vec3 p){
    float angle = PI;
    vec3 axis = normalize(vec3(1.0, 1.0, 1.0));
    return rotate(p, vec4(axis * sin(-angle*0.5), cos(-angle*0.5))); 
}

//https://iquilezles.org/articles/distfunctions
float boxSDF( vec3 p, vec3 b ){
    vec3 q = abs(p) - b;
    return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
}

float getSDF(vec3 position) {
   	position = getRotation(position);
    return boxSDF(position, vec3(1.0));
}

// Tetrahedral normal technique with a loop to avoid inlining getSDF()
// This should improve compilation times
// https://iquilezles.org/articles/normalsSDF
vec3 getNormal(vec3 p){
    vec3 n = vec3(0.0);
    for(int i = ZERO; i < 4; i++){
        vec3 e = 0.5773*(2.0*vec3((((i+3)>>1)&1),((i>>1)&1),(i&1))-1.0);
        n += e*getSDF(p+e*EPSILON);
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

vec3 getTriplanar(vec3 position, vec3 normal){
    position = getRotation(position);
    normal = getRotation(normal);
    
    // Use circular tangent direction from BufferB or construct them from iChannel3
    bool cd = true;
    
    if(abs(normal.x) > 0.5 || abs(normal.y)  > 0.5){
        cd = false;
    }
    
    vec3 xaxis;
    vec3 yaxis;
    vec3 zaxis;
    
    if(cd){

        xaxis = texture(iChannel1, DETAIL_SCALE.x*(position.zy)).rgb;
        yaxis = texture(iChannel1, DETAIL_SCALE.y*(position.zx)).rgb;
        zaxis = texture(iChannel1, DETAIL_SCALE.z*(position.xy)).rgb;

    }else{
    
        float scale = 0.25;
        if(abs(normal.y)  > 0.5){
            scale = 0.05;
        }
        xaxis = texture(iChannel3, scale * (position.zy)).rrr;
        yaxis = texture(iChannel3, scale * (position.zx)).rrr;
        zaxis = texture(iChannel3, scale * (position.xy)).rrr;
    }
    
    vec3 blending = abs(normal);
	blending = normalize(max(blending, 0.00001));
    blending = pow(blending, BLENDING_SHARPNESS);
	float b = (blending.x + blending.y + blending.z);
	blending /= b;
    
    vec3 col = xaxis * blending.x + 
               yaxis * blending.y + 
               zaxis * blending.z;
    
    if(cd){

        return col;

    }else{

        float noise = 2.0*length(col)-1.0;
        vec2 dir = vec2(noise, 0.5);
        return vec3(dir, 0.0);
    }
}

//---------------------------- Raymarching ----------------------------

float distanceToScene(vec3 cameraPos, vec3 rayDir, float start, float end) {
	
    // Start at a predefined distance from the camera in the ray direction
    float depth = start;
    
    // Variable that tracks the distance to the scene at the current ray endpoint
    float dist;
    
    // For a set number of steps
    for (int i = 0; i < MAX_STEPS; i++) {
        
        // Get the SDF value at the ray endpoint, giving the maximum 
        // safe distance we can travel in any direction without hitting a surface
        dist = getSDF(cameraPos + depth * rayDir);
        
        // If the distance is small enough, we have hit a surface
        // Return the depth that the ray travelled through the scene
        if(dist < EPSILON){
            return depth;
        }
        
        // Else, march the ray by the sdf value
        depth += dist;
        
        // Test if we have left the scene
        if(depth >= end){
            return end;
        }
    }
    
    // Return max value if we hit nothing but remain in the scene after max steps
    return end;
}


//---------------------------- Spectrum ----------------------------

// https://www.shadertoy.com/view/ls2Bz1
vec3 bump3y (vec3 x, vec3 yoffset){
	vec3 y = vec3(1) - x * x;
	y = saturate(y - yoffset);
	return y;
}

vec3 getRainbowGradient(float w){
    if(w > 700.0 || w < 400.0){
        return vec3(0);
    }
	float x = saturate((w - 400.0)/ 300.0);

	const vec3 c1 = vec3(3.54585104, 2.93225262, 2.41593945);
	const vec3 x1 = vec3(0.69549072, 0.49228336, 0.27699880);
	const vec3 y1 = vec3(0.02312639, 0.15225084, 0.52607955);

	const vec3 c2 = vec3(3.90307140, 3.21182957, 3.96587128);
	const vec3 x2 = vec3(0.11748627, 0.86755042, 0.66077860);
	const vec3 y2 = vec3(0.84897130, 0.88445281, 0.73949448);

	vec3 col = bump3y(c1 * (x - x1), y1) + bump3y(c2 * (x - x2), y2);

    // https://twitter.com/Atrix256/status/1019359890660192256
    // Undo gamma
    col = inv_gamma(col);

    return col;
}

vec3 getIridescentColour(vec3 rayDir, vec3 normal, vec3 lightDir, vec3 gratingDir, float d){
    vec3 colour = vec3(0);
    
    if(dot(normal, lightDir) < 0.0 || dot(normal, rayDir) < 0.0){
        return colour;
    }

    float sinThetaL = dot(gratingDir, lightDir);
    float sinThetaV = dot(gratingDir, rayDir);

    float u = abs(sinThetaL - sinThetaV);
    if(u == 0.0){
        return vec3(0);
    }

    for(int n = 1; n <= 8; n++){
        float wavelength = u * d / float(n);
        colour += getRainbowGradient(wavelength);
    }
    return saturate(colour);
}

//---------------------------- PBR ----------------------------

vec3 getRadiance(vec3 dir, float level){
    //Shadertoy textures are gamma corrected. Undo for lighting calculations.
    vec3 col = inv_gamma(texture(iChannel2, dir, level).rgb);
    // Add some bloom to the environment
    col += 0.5 * pow(col, vec3(2));
    return col;
}

vec3 fresnelSchlickRoughness(float cosTheta, vec3 F0, float roughness){
    return F0 + (max(vec3(1.0-roughness), F0) - F0) * pow(1.0 - cosTheta, 5.0);
}

//https://google.github.io/filament/Filament.md.html#lighting/imagebasedlights/anisotropy
vec3 getReflectedVector(vec3 v, vec3 n, vec3 dir, float anisotropy) {
    vec3  anisotropicTangent  = cross(dir, -v);
    vec3  anisotropicNormal   = cross(anisotropicTangent, dir);
    vec3  bentNormal          = normalize(mix(n, anisotropicNormal, abs(anisotropy)));

    return reflect(v, bentNormal);
}

vec3 getIrradiance(vec3 p, vec3 rayDir, vec3 normal, vec3 gratingDir){

    // Stripped down version with metalness 1 and no IBL maps
    float anisotropy = 1.0;
    vec3 tintColour = 0.75 * vec3(0.972, 0.960, 0.915);
    vec3 F0 = tintColour;
    
    vec3 F = fresnelSchlickRoughness(dot_c(normal, -rayDir), F0, 0.01);
    vec3 R = getReflectedVector(rayDir, normal, gratingDir, anisotropy);
    
    // For simplicity, we don't use the full PBR specular workflow
    // See https://www.shadertoy.com/view/3tlBW7 for full IBL solution
    vec3 prefilteredColor = getRadiance(R, 5.0);;
    
    return prefilteredColor * F;
}


//----------------------- Tonemapping and render ------------------------

//https://knarkowicz.wordpress.com/2016/01/06/aces-filmic-tone-mapping-curve/
vec3 ACESFilm(vec3 x){
    return clamp((x * (2.51 * x + 0.03)) / (x * (2.43 * x + 0.59) + 0.14), 0.0, 1.0);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord ){

    // Get the default direction of the ray (along the negative Z direction)
    vec3 rayDir = rayDirection(60.0, fragCoord);
    
    //----------------- Define a camera -----------------

    vec3 cameraPos = texelFetch(iChannel0, ivec2(0.5, 1.5), 0).xyz;

    vec3 targetDir = -cameraPos;

    vec3 up = vec3(0.0, 1.0, 0.0);

    // Get the view matrix from the camera orientation.
    mat3 viewMatrix = lookAt(cameraPos, targetDir, up);

    // Transform the ray to point in the correct direction.
    rayDir = normalize(viewMatrix * rayDir);

    //---------------------------------------------------
    
    float dist = distanceToScene(cameraPos, rayDir, MIN_DIST, MAX_DIST);

    vec3 col;
    
    if(dist < MAX_DIST){

        vec3 position = cameraPos + rayDir * dist;
        vec3 normal = getNormal(position);
        
        vec3 tangent;
        vec3 bitangent;

        pixarONB(normal, tangent, bitangent);
        tangent = normalize(tangent);
        bitangent = normalize(bitangent);

        mat3 tbn = mat3(tangent, bitangent, normal);
        vec3 gratingDir = normalize(tbn * getTriplanar(position, normal));

        col = getIrradiance(position, rayDir, normal, gratingDir);
        
        vec3 lightDir = normalize(vec3(0, 1, 0));
        col += getIridescentColour(-rayDir, normal, lightDir, gratingDir, 700.0);

    }else{
        col = getRadiance(rayDir, 0.0);
    }
    
    // Tonemapping
    col = ACESFilm(col);

    // Gamma
    col = gamma(col);
    
    fragColor = vec4(col, 1.0);
}
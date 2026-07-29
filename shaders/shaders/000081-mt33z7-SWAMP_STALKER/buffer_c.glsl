// Buffer C (buffer) — SWAMP STALKER by alro
// https://www.shadertoy.com/view/mt33z7

/*

    Gyroid surface based on:
    
    https://en.wikipedia.org/wiki/Gyroid
    https://www.shadertoy.com/view/wddfDM
    
    Use simple diffuse shading for performance reasons
*/

const float SHADOW_SHARPNESS = 8.0;

const float EPSILON = 1e-4;
const float MIN_DIST = 0.01;
const int MAX_STEPS = 60;
const float MAX_DIST = 8.0;

// https://www.shadertoy.com/view/wddfDM
float gyroid(vec3 p, float scale, float thickness, float bias) {
    p *= scale;
    return abs(dot(sin(1.1*p), cos(0.9*p.zxy)) - bias) / scale - thickness;
}

//---------------------------- Operations -----------------------------

float displacement(vec3 p){
    return dot(sin(p), cos(p.zxy));
}


//------------------------- Geometry -------------------------

float getSDF(vec3 p, vec3 dir){
    
    p -= modelOffset;
    
    float dist = 1e5;
    
    if(testAABB(p, dir, vec3(-1.0, -0.95, -1.0), 
                            vec3(1.0, 1.05, 1.0))){
        p.y -= 0.05;

        p += 0.01 * displacement(-iTime + 3.0 * p);

        float scale = 6.0;

        dist = sphereSDF(p, 1.0);
        dist = smoothSub(-gyroid(p, scale, 0.1, 0.0), dist, 0.1);
        dist = smoothSub(-gyroid(p, scale + 32.0, 0.02, 0.0), dist, 0.03);

        float dist2 = sphereSDF(p, 0.9);
        dist2 = smoothSub(gyroid(p, scale, 0.1, 0.0), dist2, 0.1);
        dist2 = smoothSub(-gyroid(p, scale + 16.0, 0.02, 0.0), dist2, 0.03);

        dist = smoothMin(dist, dist2, 0.0);

        return 0.5 * dist;
    }else{
        return dist;
    }
}

float distanceToScene(vec3 cameraPos, vec3 rayDir, float start, float end) {
	
    float depth = start;
    
    float dist;
    
    for (int i = ZERO; i < MAX_STEPS; i++){

        dist = getSDF(cameraPos + depth * rayDir, rayDir);

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
    for(int i = ZERO; i < 4; i++){
        vec3 e = 0.5773*(2.0*vec3((((i+3)>>1)&1),((i>>1)&1),(i&1))-1.0);
        n += e*getSDF(p+e*EPSILON, dir);
    }
    return normalize(n);
}

//---------------------------- Shadows ----------------------------

// https://iquilezles.org/articles/rmshadows
float softShadow(vec3 pos, vec3 rayDir, float start, float end, float k){
    float res = 1.0;
    float depth = start;
    for(int counter = ZERO; counter < 32; counter++){
        float dist = getSDF(pos + rayDir * depth, rayDir);
        if( abs(dist) < EPSILON){ return 0.0; }       
        if( depth > end){ break; }
        res = min(res, k*dist/depth);
        depth += dist;
    }
    return res;
}

//---------------------------- Lighting ----------------------------

vec3 getAmbientLight(vec3 normal){
    vec3 gradient = mix(vec3(0.5), vec3(1), 0.5+0.5*normal.y);
    return mix(gradient, getEnvironment(normal), 0.15);
}

vec3 getIrradiance(vec3 position, vec3 normal, vec3 rayDir){
    
    vec3 ambientColour = vec3(1, 0.3, 0.1) * getAmbientLight(normal);
    vec3 diffuseColour = vec3(1);
    
    vec3 albedo = mix(vec3(1.0, 0.2, 0.01), 0.5 * vec3(0.6, 0.5, 0.2),  
                  smoothstep(0.7, 1.0, length(position + vec3(0.0, -0.05, 0) - modelOffset)));
    
    vec3 direct = vec3(0);

    // Find direct lighting for all sources
    for(int i = ZERO; i < 2; i++){
        
        vec3 lightPos = getLightPosition(i);
        vec3 lightDir = normalize(lightPos - position);
    
        // How much a fragment faces the light
        float diff = max(dot(normal, lightDir), 0.0);
    
        vec3 diffuse = diff * diffuseColour;

        float shadow = softShadow(position + normal * EPSILON * 2.0, lightDir, MIN_DIST,
                              length(lightPos - position), SHADOW_SHARPNESS);
                              
        direct += shadow * 0.7 * diffuse;
    }

    return clamp(albedo * (0.3 * ambientColour + direct), 0.0, 1.0);
}

//-------------------------- Render -------------------------

void mainImage( out vec4 fragColor, in vec2 fragCoord ){

    if(fragCoord.x > iResolution.x * RENDER_SCALE || 
       fragCoord.y > iResolution.y * RENDER_SCALE){
    
        fragColor = vec4(0);
        
    }else{
    
        //----------------- Define a camera -----------------

        vec3 rayDir = rayDirection(60.0, fragCoord, iResolution.xy * RENDER_SCALE);

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
        bool background = true;
        if(testAABB(p, rayDir, vec3(-1.3, -2.0, -1.1) + modelOffset, 
                               vec3(1.2, 1.8, 1.1) + modelOffset)){

            t = distanceToScene(cameraPos, rayDir, MIN_DIST, MAX_DIST);
            if(t < MAX_DIST){
                p = cameraPos + rayDir * t;
                vec3 normal = getNormal(p, rayDir);
                col = getIrradiance(p, normal, rayDir);
                background = false;
            } 
        }

        if(background){
            col = 0.1 * getEnvironment(rayDir);
            t = -1.0;
        }

        fragColor = vec4(col, t);
    }
}
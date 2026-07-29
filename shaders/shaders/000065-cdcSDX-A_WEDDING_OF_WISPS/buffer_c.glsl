// Buffer C (buffer) — A WEDDING OF WISPS by alro
// https://www.shadertoy.com/view/cdcSDX

/*
    Render camera facing particles
    
    Based on:
        https://www.shadertoy.com/view/lsfGDB
*/

// Buffer B has a separate limit to how many particles positions are provided
// Above 1k things start to slow down significantly
const int particleCount = 300;

const float boundingRadius = 10.0;

// Mix colour with previous frame results
const bool trails = false;

//---------------------------- Camera ----------------------------

vec3 rayDirection(float fieldOfView, vec2 fragCoord, vec2 resolution) {
    vec2 xy = fragCoord - resolution / 2.0;
    float z = (0.5 * resolution.y) / tan(radians(fieldOfView) / 2.0);
    return normalize(vec3(xy, -z));
}


// https://www.geertarien.com/blog/2017/07/30/breakdown-of-the-lookAt-function-in-OpenGL/
mat3 lookAt(vec3 camera, vec3 targetDir, vec3 up){
  vec3 zaxis = normalize(targetDir);    
  vec3 xaxis = normalize(cross(zaxis, up));
  vec3 yaxis = cross(xaxis, zaxis);

  return mat3(xaxis, yaxis, -zaxis);
}

//---------------------------- Intersection functions ----------------------------

// https://www.shadertoy.com/view/lsfGDB
vec3 intersectCoordSys(in vec3 ro, in vec3 rd, vec3 dc, vec3 du, vec3 dv){
	vec3 oc = ro - dc;
	return vec3(
        dot(cross(du, dv), oc),
		dot(cross(oc, du), rd),
		dot(cross(dv, oc), rd)) / 
        dot(cross(dv, du), rd);
}

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

bool insideAABB(vec3 p, vec3 minCorner, vec3 maxCorner){
    float eps = 1e-4;
	return  (p.x > minCorner.x-eps) && (p.y > minCorner.y-eps) && (p.z > minCorner.z-eps) && 
			(p.x < maxCorner.x+eps) && (p.y < maxCorner.y+eps) && (p.z < maxCorner.z+eps);
}

//---------------------------- Colour ----------------------------

float getGlow(float dist, float radius, float intensity){
    dist = max(dist, 1e-6);
	return pow(radius/dist, intensity);
}

// https://iquilezles.org/articles/palettes/
vec3 getColour(float t){
    
    // Blue
    //return vec3(0.1, 0.45, 1.0);
    
    // Orange
    //return vec3(1.0, 0.2, 0.01);

    t += 0.15 * iTime;

    vec3 a = vec3(0.65);
    vec3 b = 1.0 - a;
    vec3 c = vec3(1.0,1.0,1.0);
    vec3 d = vec3(0.15,0.5,0.75);
    
    return a + b * cos(TWO_PI * (c * t + d));
}

//---------------------------- Geometry ----------------------------

vec3 traceParticles(vec3 org, vec3 rayDir){

    // Create a coordinate system from the ray direction
    vec3 n = -rayDir;
    vec3 tangent;
    vec3 bitangent;
    pixarONB(n, tangent, bitangent);
    tangent = normalize(tangent);
    bitangent = normalize(bitangent);

    vec3 col = vec3(0);

    // Cutoff size for particles
    float size = 16.0;
    
    vec3 intersection;
    // Distance of intersection in disc uv space
    float d;
    vec3 glow;
    ivec2 uv;
    vec4 data;
    vec3 pos;
    // Distance of particle from the centre
    float len;
    // 1 - 0 from the centre of the scene to the bounding sphere
    float s;
        
    for(int i = 1; i < particleCount; i++){

        // Fetch particle data from Buffer B
        uv = ivec2(int(mod(float(i), iChannelResolution[1].x)), 
                         i / int(iChannelResolution[1].x));

        data = texelFetch(iChannel1, uv, 0);

        pos = data.xyz;
        len = length(pos);

        // 1 - 0 from the centre of the scene to the bounding sphere
        s = smoothstep(boundingRadius, 0.0, len);

        if(s < 1e-5){
            continue;
        }
        
        intersection = intersectCoordSys(org, rayDir, pos, tangent, bitangent);
        
        // Distance of intersection in disc uv space
        d = dot(intersection.yz, intersection.yz);

        if(d < size){
            // Get an animated glow based on particle index and position
            // Create a brighter core, vary diameter with time
            float glowSize = mix(1.0, 4.0, smoothstep(4.0, 0.0, len)) * 
                             mix(0.001, 0.01, 0.5 + 0.5 * sin(13.0 * iTime + float(i)/6.0));

            vec3 tone = getColour(float(i) / (3.4 * float(particleCount)));

            // Reduce glow radius at the edges of the bounding sphere
            glow = tone * getGlow(d, glowSize, mix(1.0, 0.9, s));
            
            // Smoothly fade in reset particles
            float lifeTime = smoothstep(0.0, 0.5, data.w);
            // Fade particles at the edges of the bounding sphere and fade glow
            // locally based on particle size
            col += lifeTime * s * glow * smoothstep(size, 0.0, d);
        }
    }
    
    return col;
}


//---------------------------- Render ----------------------------

void mainImage( out vec4 fragColor, in vec2 fragCoord ){
    
    if(fragCoord.x > iResolution.x * RENDER_SCALE || 
       fragCoord.y > iResolution.y * RENDER_SCALE){
    
        fragColor = vec4(0);
        
    }else{
    
        //Get the default direction of the ray (along the negative Z direction)
        vec3 rayDir = rayDirection(60.0, fragCoord, iResolution.xy * RENDER_SCALE);

        //----------------- Define a camera -----------------

        vec3 cameraPos = texelFetch(iChannel0, ivec2(0.5, 1.5), 0).xyz;

        vec3 targetDir = -cameraPos;

        vec3 up = vec3(0.0, 1.0, 0.0);

        // Get the view matrix from the camera orientation
        mat3 viewMatrix = lookAt(cameraPos, targetDir, up);
        
        //---------------------------------------------------

        // Transform the ray to point in the correct direction
        rayDir = normalize(viewMatrix * rayDir);

        vec3 col = vec3(0.0, 0.01, 0.02);

        vec2 intersections = intersectAABB(cameraPos, rayDir, 
                                           vec3(-boundingRadius), vec3(boundingRadius));

        if(intersections.x > 0.0 && (intersections.x < intersections.y) || 
           insideAABB(cameraPos, vec3(-boundingRadius), vec3(boundingRadius))){
            col += traceParticles(cameraPos, rayDir);
        }
        
        if(trails){
            if(iMouse.z < 0.0){
                vec3 oldCol = texelFetch(iChannel2, ivec2(fragCoord), 0).rgb;
                oldCol = clamp(oldCol, 0.0, 2.0);
                col = mix(oldCol, col, 0.45);
            }
        }
        
        // Output to screen
        fragColor = vec4(col, 1.0);
    }
}
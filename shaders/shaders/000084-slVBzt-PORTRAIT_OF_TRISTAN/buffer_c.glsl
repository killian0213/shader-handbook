// Buffer C (buffer) — PORTRAIT OF TRISTAN by alro
// https://www.shadertoy.com/view/slVBzt

/*
    Ray march geometry and write normal to RGB and depth to A for recontruction and shading
    in Image tab.
    
    Only renders when camera position has moved or the resolution has changed.
*/

// Variable iterator initializer to stop loop unrolling
#define ZERO (min(iFrame,0))

const int MAX_STEPS = 64;
const float MIN_DIST = 0.001;
const float MAX_DIST = 10.0;
const float EPSILON = 1e-4;

const float AABBLimit = 0.001;

//---------------------------- Part functions ----------------------------

// https://www.youtube.com/watch?v=AGNBb8u38gc&t=18s
float getMouthSDF(vec3 p, float dist){
    // Mouth mound
    vec3 q = p;
    q.x += 0.8;
    q.y += 0.775;
    q = rotateZ(q, -0.15);
    dist = opSmoothMin(sphereSDF(q, 0.1), dist, 0.25);
        
    // Gap between lips
    q = p;
    q.x += 0.72;
    q.y += 0.85;
    q = rotateY(q, PI * 0.5);
    q = rotateX(q, PI * -0.475);
    float an = 0.95;
    dist = opSmoothSub(sdCappedTorus(q, vec2(sin(an), cos(an)), 0.25, 0.001), dist, 0.05);
  
    // Top lip
    q = p;
    q.x += 0.7;
    q.y += 0.81;
    q = rotateZ(q, -0.6);
    dist = opSmoothMin(sdEllipsoid(q, vec3(0.1, 0.25, 0.2)), dist, 0.1);
    
    q = p;
    q.x += 0.74;
    q.y += 0.82;
    q = rotateZ(q, -0.65);
    dist = opSmoothMin(sdEllipsoid(q, vec3(0.075, 0.25, 0.225)), dist, 0.035);
  
    // Depression below bottom lip
    q = p;
    q.x += 1.085;
    q.y += 1.05;
    q = rotateZ(q, PI * 0.15);
    q = rotateY(q, PI * 0.5);
    float am = 1.5;
    dist = opSmoothSub(sdCappedTorus(q, vec2(sin(am), cos(am)), 0.15, 0.015), dist, 0.1);
    
  
    // Bottom lip
    q = p;
    q.x += 0.74;
    q.y += 0.79;
    q = rotateZ(q, 0.55);
    dist = opSmoothMin(sdEllipsoid(q, vec3(0.1, 0.25, 0.2)), dist, 0.025);
    
    // Philtrum
    q = p;
    q.x += 0.925;
    q.y += 0.7;
    q = rotateZ(q, 0.0);
    dist = opSmoothMin(sdCapsule(q, 0.025, 0.0125), dist, 0.1);
    
    q = p;
    q.x += 1.0125;
    q.y += 0.7;
    q = rotateZ(q, 0.0);
    dist = opSmoothSub(sdRoundCone(q, 0.025, 0.0125, 0.025), dist, 0.05);
    
    return dist;
}

float getNoseSDF(vec3 p, float dist){

    p.x -= 0.01;

    // Nose
    vec3 q = p;
    q.x += 1.1;
    q.y += 0.52;
    q = rotateZ(q, 0.24);
    dist = opSmoothMin(sdRoundCone(q, 0.05, 0.005, 0.5), dist, 0.1);
    
    q = p;
    q.x += 0.9;
    q.y += 0.32;
    q = rotateZ(q, 0.175);
    q.y += 0.2;
    dist = opSmoothMin(sdRoundCone(q, 0.075, 0.01, 0.25), dist, 0.125);
    
    // Nostrils
    q = p;
    q.z = abs(q.z);
    q.x += 0.98;
    q.y += 0.58;
    q.z -= 0.085;
    q = rotateZ(q, -0.65);
    q = rotateX(q, 0.7);
    dist = opSmoothMin(sdRoundCone(q, 0.065, 0.075, 0.1), dist, 0.02);
    
    // Septum
    q = p;
    q.x += 1.0;
    q.y += 0.63;
    q = rotateZ(q, -0.45);
    dist = opSmoothMin(sdRoundCone(q, 0.05, 0.07, 0.12), dist, 0.03);

    // Holes
    q = p;
    q.z = abs(q.z);
    q.x += 1.05;
    q.y += 0.64;
    q.z -= 0.08;
    q = rotateZ(q, -0.65);
    q = rotateX(q, 0.7);
    dist = opSmoothSub(sdRoundCone(q, 0.01, 0.015, 0.05), dist, 0.025);
    
    
    q = p;
    q.z = abs(q.z);
    q.x += 1.03;
    q.y += 0.61;
    q.z -= 0.07;
    q = rotateZ(q, -0.78);
    q = rotateX(q, 0.7);
    dist = opSmoothSub(sdCapsule(q, 0.015, 0.07), dist, 0.02);


    // Lower septum
    q = p;
    q.x += 1.07;
    q.y += 0.62;
    q = rotateZ(q, -0.5);
    dist = opSmoothMin(sdCapsule(q, 0.03, 0.03), dist, 0.04);
    
    return dist;
}

float getNeckSDF(vec3 p) {

    vec3 q = p;
    float d = 1e12;
    q.x -= 0.05;
    q.y += 1.3;
    q = rotateZ(q, -0.02);
    d = sdRoundCone(q, 0.525, 0.5, 1.5);
    
    q = p;
    q.x += 0.45;
    q.y += 1.5;
    q = rotateZ(q, 0.1);
    d = opSmoothSub(sdRoundCone(q, 0.3, 0.42, 0.55), d, 0.15);
    
    
    q = p;
    q.x += 0.05;
    q.y += 1.5;
    q = rotateZ(q, -0.2);
    d = opSmoothMin(sdCapsule(q, 0.3, 0.5), d, 0.25);
    
    return d;
}

float getEarSDF(vec3 p) {

    float d = 1e12;
    /*
        The ear was modelled in a separate shader with different coordinates and we need to 
        orient and scale it to fit the scene. Incidentally, modelling ears with distance
        functions made me almost lose my actual mind. Way too much time was spent staring at
        people in the street, trying to figure out what an ear looks like. 
        They are not perfect but, whatever, I tried.
    */
    p.xyz = p.zyx;
    p.z *= -1.0;
    
    // Positioning
    p.x = abs(p.x);
    p.x -= 0.66;
    p.y += 0.345;
    p.z -= 0.13;
    
    // Stretch the ear to fit the head better
    p *= vec3(0.6, 0.6, 0.65);
    
    // Warp centre of ear inward to give it a 3D rather than a planar look
    p.x += mix(0.0, 0.055, smoothstep(0.065, 0.0, length(p.yz-vec2(-0.065, 0.055))));
    
    // Orient
    p = rotateX(p, 0.25);
    p = rotateZ(p, 0.125);
    p = rotateY(p, 0.525);

    // Orient some more
    p = rotateZ(p, PI * 0.025);
    
    vec3 q = p;

    // Helix and main plane makes up the main shape
    q.y -= 0.015;
    d = sphereSDF(q, 0.11);

    q = p;
    q.y += 0.13;
    q.z -= 0.02;
    d = opSmoothMin(sphereSDF(q, 0.055), d, 0.15);
    
    q = p;
    q.x -= 0.11;
    q.y -= 0.015;
    float hollow = sphereSDF(q, 0.105);
    
    q = p;
    q.x -= 0.14;
    q.y += 0.13;
    q.z -= 0.04;
    hollow = opSmoothMin(sphereSDF(q, 0.07), hollow, 0.15);
    
    q = p;
    q.x -= 0.11;
    hollow = opSmoothIntersection(hollow, sdBox(q, vec3(0.075, 0.25, 0.15)), 0.005);
    
    d = opSmoothSub(hollow, d, 0.02);
    
    // Flatten to a plane
    q = p;
    q.x -= 0.055;
    d = opSmoothIntersection(d, sdBox(q, vec3(0.04, 0.25, 0.15)), 0.035);
    
    // Rotation for central geometry
    p = rotateX(p, 0.1);
    p = rotateZ(p, PI * -0.025);
    p = rotateY(p, PI * -0.025);
    
    // Antihelix
    float rot = 0.035;
    p.y -= 0.025;
    p = rotateY(p, PI * -rot);
    float middle = 1e10;
    
    // Two large spheres make up the central shape
    q = p;
    q.y += 0.02;
    q.z += 0.01;
    q.x += 0.075;
    middle = sphereSDF(q, 0.145);
    
    q = p;
    q.x += 0.015;
    q.y += 0.08;
    q.z -= 0.01;
    middle = opSmoothMin(sphereSDF(q, 0.1), middle, 0.015);
    
    // Triangular fossa (top depression)
    q = p;
    q.x -= 0.04;
    q.y += 0.125;
    q.z -= 0.09;
    q = rotateY(q, PI * 0.67);
    float an = 0.5*PI;
    middle = opSmoothSub(sdCappedTorus(q, vec2(sin(an), cos(an)), 0.15, 0.02), middle, 0.01);

    // Concha (central hollow)
    q = p;
    q.x -= 0.04;
    q.z -= 0.045;
    q.y += 0.08;
    middle = opSmoothSub(sphereSDF(q, 0.05), middle, 0.06);
    
    q = p;
    q.x -= 0.04;
    q.z -= 0.0;
    q.y += 0.085;
    middle = opSmoothSub(sphereSDF(q, 0.0025), middle, 0.065);
    
    // Lobe
    q = p;
    q.x -= 0.0;
    q.z -= 0.01;
    q.y += 0.18;
    middle = opSmoothMin(sphereSDF(q, 0.03), middle, 0.04);
  
    q = p;
    q = rotateY(q, 0.2);
    q = rotateZ(q, 0.1);
    q.x -= 0.105;
    q.y -= 0.045;
    q.z += 0.005;
    middle = opSmoothIntersection(middle, sdBox(q, vec3(0.075, 0.3, 0.19)), 0.01);

    p.y += 0.025;
    d = opSmoothMin(middle, d, 0.005);
    
    // Ear back
    q = p;
    q.x -= 0.01;
    q.y += 0.09;
    q.z -= 0.02;
    float back = sphereSDF(q, 0.06);

    q.y -= 0.07;
    back = opSmoothMin(sphereSDF(q, 0.06), back, 0.03);
    
    q = p;
    q = rotateY(q, 0.2);
    q = rotateZ(q, 0.1);
    q.x -= 0.09;
    back = opSmoothSub(sdBox(q, vec3(0.075, 0.25, 0.19)),back, 0.01);
    
    d = opSmoothMin(back, d, 0.025);
    
    return d;
}

float getSDF(vec3 p, vec3 dir){

    float minStart = 1e10;
    float start = 10e10;

    vec3 originalPos = p;
    
    p.y -= 0.25;
    p.x -= 0.2;
    vec3 q = p;
    q.xy += 0.015;
    float dist = sphereSDF(q, 0.8);

    // Far jaw limit
    q = p;
    q.x += 0.15;
    q.y += 0.4;
    q = opElongate(q, vec3(0., 0., -0.)).xyz;
    float distCut = sdCapsule(q, 0.8, 0.25);
    q = p;
    q.x -= 0.85;
    q.y += 0.9;
    distCut = opSmoothSub(sdBox(q, vec3(1.0, 0.35, 1.0)), distCut, 0.5);
    
    dist = opSmoothMin(distCut, dist, 0.05);
   
    q = p;
    q.x -= 0.45;
    q.y += 1.3;
    
    
    // Sides
    q = p;
    q.z = abs(q.z);
    q.z -= 0.9;
    q = rotateY(q, 0.2);
    q = rotateX(q, -0.12);
    dist = opSmoothSub(sdBox(q, vec3(3.0, 3.0, 0.1)), dist, 0.25);
    
    // Jowls
    q = p;
    q.z = abs(q.z);
    q.x += 0.75;
    q.y += 0.8;
    q.z -= 0.5;
    q = rotateX(q, -0.5);
    q = rotateY(q, 0.6);
    dist = opSmoothSub(sdBox(q, vec3(1.5, 1.55, 0.1)), dist, 0.1);
    
    // Forehead
    q = p;
    q.x += 0.55;
    q.y -= 0.25;
    q = rotateZ(q, 0.3);
    q.z *= 0.85;
    dist = opSmoothMin(sphereSDF(q, 0.2), dist, 0.52);
    
    if(testAABB(p, dir, vec3(-1.1, -0.6, -0.6), vec3(-0.7, 0.075, 0.6), start)){
        if(start < AABBLimit){
            // Eye sockets 
            q = p;
            q.x += 0.85;
            q.y += 0.255;
            q.z -= 0.225;
            dist = opSmoothSub(sphereSDF(q, 0.1), dist, 0.25);
            q = p;
            q.x += 0.85;
            q.y += 0.255;
            q.z += 0.225;
            dist = opSmoothSub(sphereSDF(q, 0.1), dist, 0.25);
            
        }else{
            minStart = min(minStart, start);
        }
    }
    
    // Cheekbones
    q = p;
    q.z = abs(q.z);
    q.x += 0.725;
    q.y += 0.43;
    q.z -= 0.25;
    q = rotateY(q, -0.3);
    dist = opSmoothMin(sdEllipsoid(q, vec3(0.1, 0.1, 0.2)), dist, 0.15);
  
    // Inner corner
    q = p;
    q.z = abs(q.z);
    q.x += 0.9;
    q.y += 0.3;
    q.z -= 0.125;
    q = rotateZ(q, -0.2 * PI);;
    q = rotateX(q, 0.2 * PI);
    dist = opSmoothSub(sdRoundCone(q, 0.02, 0.05, 0.15), dist, 0.1);
  
    // Eye hood
    q = p;
    q.z = abs(q.z);
    q.x += 0.72;
    q.y += 0.25;
    q.z -= 0.255;
    q = rotateZ(q, PI * 0.3);
    q = rotateY(q, PI * 0.45);
    float an = PI;
    dist = opSmoothMin(sdCappedTorus(q, vec2(sin(an), cos(an)), 0.12, 0.03), dist, 0.07);
  
    // Brow
    q = p;
    q.x += 0.75;
    q.y += 0.215;
    q.z += 0.235;
    q = rotateZ(q, PI * 0.355);
    q = rotateY(q, PI * -0.55);
    an = PI;
    dist = opSmoothMin(sdCappedTorus(q, vec2(sin(an), cos(an)), 0.165, 0.02), dist, 0.2);
    
    q = p;
    q.x += 0.75;
    q.y += 0.215;
    q.z -= 0.235;
    q = rotateZ(q, PI * 0.355);
    q = rotateY(q, PI * 0.55);
    an = PI;
    dist = opSmoothMin(sdCappedTorus(q, vec2(sin(an), cos(an)), 0.165, 0.02), dist, 0.2);
    
   
    
    if(testAABB(p, dir, vec3(-1.1, -0.4, -0.5),vec3(-0.65, -0.15, 0.5), start)){
        if(start < AABBLimit){
            dist = getEyesSDF(p, dist);
        }else{
            minStart = min(minStart, start);
        }
    }
    
    // Lower cheeks
    q = p;
    q.z = abs(q.z);
    q.x += 0.7;
    q.y += 0.8;
    q.z -= 0.2;
    dist = opSmoothMin(sphereSDF(q, 0.025), dist, 0.22);
    
    // Upper cheeks
    q = p;
    q.z = abs(q.z);
    q.x += 0.8;
    q.y += 0.475;
    q.z -= 0.0;
    
    q = rotateZ(q, 0.2);
    q = rotateY(q, -0.5);
    q = rotateX(q, -0.25);
    dist = opSmoothMin(sdEllipsoid(q, vec3(0.1, 0.1, 0.15)), dist, 0.2);
    
    // Chin
    q = p;
    q.z *= 0.5;
    q.x += 0.85;
    q.y += 1.08;
    q = rotateZ(q, 0.5);   
    dist = opSmoothMin(sdCapsule(q, 0.025, 0.75), dist, 0.225);
    
    // Mouth
    if(testAABB(p, dir, vec3(-1.1, -1.2, -0.5),vec3(-0.7, -0.45, 0.5), start)){
        if(start < AABBLimit){
            vec3 offset = vec3(0.02, 0.0, 0.0);
            dist = getMouthSDF(p + offset, dist);
        }else{
            minStart = min(minStart, start);
        }
    }

    // Nose
    if(testAABB(p, dir, vec3(-1.2, -0.7, -0.2),vec3(-0.5, 0.0, 0.2), start)){ 
        if(start < AABBLimit){
            vec3 offset = vec3(0.0, -0.015, 0.0);
            dist = getNoseSDF(p + offset, dist);
        }else{
            minStart = min(minStart, start);
        }
    }
    
    // Ears
    if(testAABB(vec3(p.x, p.y, abs(p.z)), dir, vec3(-0.4, -0.8, 0.5), vec3(0.1, 0.0, 1.1), start)){ 
        if(start < AABBLimit){
            // Ear hole
            q = p;
            q.z = abs(q.z);
            q.x += 0.2;
            q.y += 0.45;
            q.z -= 0.57;
            dist = opSmoothSub(sphereSDF(q, 0.03), dist, 0.075);

            float earDist = getEarSDF(p);
            dist = opSmoothMin(earDist, dist, 0.01);

            q = p;
            q.z = abs(q.z);
            q.x += 0.22;
            q.y += 0.45;
            q.z -= 0.55;
            dist = opSmoothSub(sphereSDF(q, 0.01), dist, 0.05);

            // Tragus
            q = p;
            q.z = abs(p.z);
            q.x += 0.24;
            q.y += 0.435;
            q.z -= 0.625;
            q = rotateY(q, PI * 0.2);
            q = rotateZ(q, PI * -0.1);

            float distTragus = sdRoundCone(q, 0.015, 0.03, 0.1);
            q = p;
            q.z = abs(p.z);
            q.x += 0.24;
            q.y += 0.455;
            q.z -= 0.615;
            q = rotateY(q, PI * 0.25);
            q = rotateZ(q, PI * -0.35);
            distTragus = opSmoothMin(sdRoundCone(q, 0.015, 0.03, 0.1), distTragus, 0.06);

            dist = opSmoothMin(dist, distTragus, 0.035);

            // Crus helix
            q = p;
            q.z = abs(p.z);
            q.x += 0.19;
            q.y += 0.3125;
            q.z -= 0.655;
            q = rotateY(q, PI * 0.03);
            q = rotateX(q, PI * -0.05);
            float an = PI;
            dist = opSmoothMin(sdCappedTorus(q, vec2(sin(an), cos(an)), 0.075, 0.01), dist, 0.025);
        }else{
            minStart = min(minStart, start);
        }
    }
    
    // Lower jaw limit
    q = p;
    q.y += 1.15;
    q = rotateZ(q, -0.225);
    q.x += 0.45;
    dist = opSmoothSub(sdBox(q, vec3(0.5, 0.3, 1.5)), dist, 0.1);
    
    // Neck
    float neckDist = getNeckSDF(p);
    dist = opSmoothMin(neckDist, dist, 0.075);
    
    q = p;
    dist = opSmoothMin(collarSDF(q), dist, 0.0);
    
    q = p;
    q.y += 1.725;
    q = rotateZ(q, -0.2);
    q.x += 0.45;
    dist = opSmoothSub(sdBox(q, vec3(3.5, 0.4, 3.5)), dist, 0.0);

    q = p;
    dist = opSmoothMin(getEyeballSDF(q), dist, 0.0025);
    
    
    return min(minStart, dist);
}

float distanceToScene(const vec3 cameraPos, const vec3 rayDir, const float start, const float end){
	
    float s;
    if(!testAABB(cameraPos, rayDir, vec3(-1.0, -1.4, -1.0),vec3(1.0, 1.2, 1.0), s)){
        return MAX_DIST;
    }
    
    // Start at a predefined distance from the camera in the ray direction
    float depth = start;
    
    // Variable that tracks the distance to the scene at the current ray endpoint
    float dist;
   
    // For a set number of steps
    for (int i = ZERO; i < MAX_STEPS; i++) {
        
        // Get the sdf value at the ray endpoint, giving the maximum 
        // safe distance we can travel in any direction without hitting a surface
        dist = getSDF(cameraPos + depth * rayDir, rayDir);
    
        // If it is small enough, we have hit a surface
        // Return the depth that the ray travelled through the scene
        if (dist < EPSILON){
            return depth;
        }
        
        // Else, march the ray by the sdf value
        depth += 0.98*dist;
        
        // Test if we have left the scene
        if (depth >= end){
            return end;
        }
    }

    return depth;
}


// Tetrahedral normal technique with a loop to avoid inlining getSDF()
// This should improve compilation times
// https://iquilezles.org/articles/normalsSDF
vec3 getNormal(vec3 p, vec3 rayDir){
    vec3 n = vec3(0.0);
    for(int i = ZERO; i < 4; i++){
        vec3 e = 0.5773*(2.0*vec3((((i+3)>>1)&1),((i>>1)&1),(i&1))-1.0);
        n += e*getSDF(p+e*EPSILON, rayDir);
    }
    return normalize(n);
}

//----------------------------- Output ------------------------------

void mainImage( out vec4 fragColor, in vec2 fragCoord ){

    bool resolutionChanged = texelFetch(iChannel0, ivec2(0.5, 2.5), 0).r > 0.0;
    bool fovChanged = texelFetch(iChannel0, ivec2(0.5, 4.5), 0).x > 0.0;

    if(iFrame < 2 || iMouse.z > 0.0 || resolutionChanged || fovChanged){
    
        //----------------- Define a camera -----------------

        vec3 rayDir = rayDirection(FOV, fragCoord, iResolution.xy);

        vec3 cameraPos = texelFetch(iChannel0, ivec2(0.5, 1.5), 0).xyz;

        vec3 targetDir = -cameraPos;
        vec3 up = vec3(0.0, 1.0, 0.0);

        // Get the view matrix from the camera orientation.
        mat3 viewMatrix = lookAt(cameraPos, targetDir, up);

        // Transform the ray to point in the correct direction.
        rayDir = normalize(viewMatrix * rayDir);

        //---------------------------------------------------

        // Find the distance to where the ray stops.
        float dist = distanceToScene(cameraPos, rayDir, MIN_DIST, MAX_DIST);
        vec3 col = vec3(0);
        if(dist < MAX_DIST){
            vec3 position = cameraPos + rayDir * dist;
            col = getNormal(position, rayDir);
        }

        fragColor = vec4(col, dist);
    }else{
        fragColor = texelFetch(iChannel1, ivec2(fragCoord.xy), 0);
    }
}
// Image (image) — AURORA by alro
// https://www.shadertoy.com/view/ttScDc

// Ray marched northern lights over a field of snow before dawn.
// Is there a fast LUT based 3D gradient noise approach?

#define PI 3.14159
#define TWO_PI 2.0*PI

//Aurora
const float STEPS = 32.0;
const float auroraSpeed = 0.5;
const float strengthMultiplier = 0.015;
const vec3 baseColour = vec3(0.35, 1, 0.01);
const vec3 highColour = vec3(0.5, 0.0, 0.2);

const float auroraStart = 50.0;
const float aabbHeight = 75.0;
const vec3 minCorner = vec3(-250.0, auroraStart, -500.0);
const vec3 maxCorner = vec3(250.0, auroraStart + aabbHeight, 500.0);

//Stars
const float flickerSpeed = 5.0;

//Azimuth
float sunLocation = 0.5;
//0: horizon
float sunHeight = -3.9;

const vec3 skyColour = vec3(0.45, 0.7, 1.0);
//Mountains and distant snow
const vec3 distantColour = 0.04 * skyColour;

//Offset the sample point by blue noise every frame to get rid of banding
#define DITHERING
const float goldenRatio = 1.61803398875;

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

float getGlow(float dist, float radius, float intensity){
    dist = max(dist, 1e-7);
	return pow(radius/dist, intensity);	
}

//---------------------------- 3D Perlin noise ----------------------------
//Used to shape aurora
//https://www.shadertoy.com/view/4sfGzS

float noise( in vec3 x ){  
    vec3 i = floor(x);
    vec3 f = fract(x);
	f = f*f*(3.0-2.0*f);
	vec2 uv = (i.xy+vec2(37.0,17.0)*i.z) + f.xy;
	vec2 rg = textureLod( iChannel2, (uv+0.5)/256.0, 0.0).yx;
	return mix( rg.x, rg.y, f.z );
}

float fbm3D(vec3 pos, int limit){

	float sum = 0.0;
	float weightSum = 0.0;
	float weight = 1.0;
    float frequency = 1.0;
	for(int oct = 0; oct < 3; oct++){

        vec3 p = pos * frequency;
        float val = noise(p * frequency);
        sum += (1.0-abs(val)) * weight;
        weightSum += weight;

        weight *= 0.5;
        frequency *= 2.0;
	}

    float noise = sum / weightSum;
	noise = clamp(noise, 0.0, 1.0);
	return noise;
}

//---------------------------- 1D Perlin noise ----------------------------
//Used to shape aurora and mountains
//https://www.shadertoy.com/view/lt3BWM

#define HASHSCALE 0.1031

float hash(float p){
    vec3 p3  = fract(vec3(p) * HASHSCALE);
    p3 += dot(p3, p3.yzx + 19.19);
    return fract((p3.x + p3.y) * p3.z);
}

float fade(float t) { return t*t*t*(t*(6.*t-15.)+10.); }

float grad(float hash, float p){
    int i = int(1e4*hash);
    return (i & 1) == 0 ? p : -p;
}

float perlinNoise1D(float p){
    float pi = floor(p), pf = p - pi, w = fade(pf);
    return mix(grad(hash(pi), pf), grad(hash(pi + 1.0), pf - 1.0), w) * 2.0;
}

float fbm(float pos, int octaves, float persistence){
    float total = 0.0, frequency = 1.0, amplitude = 1.0, maxValue = 0.0;
    for(int i = 0; i < octaves; ++i){
        total += perlinNoise1D(pos * frequency) * amplitude;
        maxValue += amplitude;
        amplitude *= persistence;
        frequency *= 2.0;
    }
    return total / maxValue;
}

//https://gist.github.com/DomNomNom/46bb1ce47f68d255fd5d
//Compute the near and far intersections using the slab method.
//No intersection if tNear > tFar.
vec2 intersectAABB(vec3 rayOrigin, vec3 rayDir, vec3 boxMin, vec3 boxMax) {
    vec3 tMin = (boxMin - rayOrigin) / rayDir;
    vec3 tMax = (boxMax - rayOrigin) / rayDir;
    vec3 t1 = min(tMin, tMax);
    vec3 t2 = max(tMin, tMax);
    float tNear = max(max(t1.x, t1.y), t1.z);
    float tFar = min(min(t2.x, t2.y), t2.z);
    return vec2(tNear, tFar);
}

bool insideAABB(vec3 p){
    float eps = 1e-4;
	return  (p.x > minCorner.x-eps) && (p.y > minCorner.y-eps) && (p.z > minCorner.z-eps) && 
			(p.x < maxCorner.x+eps) && (p.y < maxCorner.y+eps) && (p.z < maxCorner.z+eps);
}

bool getAABBIntersection(vec3 org, vec3 dir, out float distToStart, out float totalDistance){
	vec2 intersections = intersectAABB(org, dir, minCorner, maxCorner);
	
    if(insideAABB(org)){
        intersections.x = 1e-4;
    }
    
    distToStart = intersections.x;
    totalDistance = intersections.y - intersections.x;
    return intersections.x > 0.0 && (intersections.x < intersections.y);
}

//-------------------------- Aurora --------------------------

vec3 auroraColour(float h){
    return mix(baseColour, highColour, h);
}

vec3 getAuroraPosition(vec3 position, float speed){
    
    //Normalised height of sample point in AABB
    float h = (position.y-auroraStart)/aabbHeight;
    //Stretch in the z direction and add movement in y and z directions
    vec3 pos = 0.042*vec3(position.x, 2.0*speed, 0.225*position.z+speed*0.5);
    //Large arc shape with higher points tilted
    pos.x += 0.3*h + 5.5*cos(0.005*position.z);
    //Smaller waves
    pos.x += 0.02*perlinNoise1D(0.1*position.z+speed*2.0);

    return pos;
}

float getAuroraDensity(vec3 position){

    float speed = iTime * auroraSpeed;
    vec3 pos = getAuroraPosition(position, speed);
    float noise = fbm3D(pos, 3);
  
    vec3 p = vec3(noise, position.y-minCorner.y, noise);
    
    //Stretch in the y direction
    vec3 a = p * vec3(1.0, 0.006, 1.0);
    
    //The nice glow behaviour occurs away from 0 so raise the sample point
    a.y += 0.48;

    //Add horizontally moving strength differences
    a.y += 0.015*perlinNoise1D(1.0*speed + pos.z);
    a.y += 0.015*perlinNoise1D(-2.0*speed + pos.z);
    
	float density = getGlow(length(a), 0.7, 10.0);
    
    //Cut away parts of AABB not along the main arc shape
    density *= cos(0.13*pos.x);
    
    return max(0.0, density);
}

vec3 getAuroraColour(vec3 org, vec3 dir, float offset){

    vec3 colour = vec3(0);
    float density = 0.0;
    //The distance at which to start ray marching.
    float distToStart = 0.0;
    
    //The length of the intersection.
    float totalDistance = 0.0;

    //Determine if ray intersects bounding volume.
	//Set ray parameters in the aurora aabb.
	bool renderAurora = getAABBIntersection(org, dir, distToStart, totalDistance);

	if(!renderAurora){
		return colour;
    }

	//Sampling step size.
    float stepSize = totalDistance / float(STEPS); 
    
    //Offset the starting point by blue noise.
    distToStart += stepSize * offset;

	//Initialise sampling point.
	vec3 p = org + distToStart * dir;
    float dist = distToStart;
    vec3 col = vec3(0);
    
    for(float i = 0.0; i < STEPS; i++){
    	density = getAuroraDensity(p);
        col += density * auroraColour((p.y-minCorner.y)/(maxCorner.y-minCorner.y));
        dist += stepSize;

		//Step along ray.
		p = org + dir * dist;
    }
    
	return strengthMultiplier * col * stepSize;
}


//-------------------------- Sky --------------------------

vec3 rand33(vec3 p3){
	p3 = fract(p3 * vec3(.1031, .1030, .0973));
    p3 += dot(p3, p3.yxz+33.33);
    return fract((p3.xxy + p3.yxx)*p3.zyx);

}

//Get star colour from view direction.
//Technique from https://www.shadertoy.com/view/XtGGRt
float getStars(vec3 rayDir){

    float scale = 112.0;
    vec3 id = floor(rayDir * scale);
    float d = length(scale * rayDir - (id + 0.5));

    float stars = 0.0;
    //rand33 returns better random number for view directions across the 0-planes
    vec3 rnd = rand33(id);
    if(rnd.x > 0.92 && d < 0.15){
        stars = getGlow(d, 0.075, 2.5 - 2.0 * sin(rnd.y * flickerSpeed * iTime));
    }
    return stars;
}

vec3 getSkyColour(vec3 rayDir){
    
    vec3 sunDirection = normalize(vec3(cos(sunLocation), sunHeight, sin(sunLocation)));
    float halo = dot(rayDir, sunDirection);
    float mu = 0.5+0.5*halo;
    
    //Reddish pre-dawn glow on the horizon
    vec3 sunColour = vec3(1.0, 0.25, 0.01);
    vec3 sun = 0.15 * sunColour * getGlow(max(1.0-mu, 0.1), 0.39, 10.0);
    
    //White-blue gradient around the sun
    vec3 blue = mix(vec3(1), skyColour, smoothstep(1.0, -0.5, halo));
    blue = mix(blue, vec3(0), smoothstep(1.0, -0.75, halo));
    
    //Flickering stars
    vec3 stars = vec3(0);
    stars = vec3(getStars(rayDir));
    stars = mix(stars, blue, mu);
    
    //Two bright planets
    vec3 planetDirection = -normalize(vec3(1,1,0));
    float planet = 0.5+0.5*dot(rayDir, planetDirection);
    stars += 0.1*getGlow(planet, 5e-6, 0.95);
    
    planetDirection = -normalize(vec3(0.3, 0.25, 1.0));
    planet = 0.5+0.5*dot(rayDir, planetDirection);
    stars += 0.1*getGlow(planet, 5e-6, 0.95);
    
    //Mix the sun, haze and stars with a red-blue gradient around the horizon
    return mix(0.5*stars, sun, mu) 
        + 0.04*mix(vec3(1.0,0.5,0.3), 0.5*skyColour, smoothstep(0.4, 0.57, 0.5+0.5*rayDir.y));
}

//----------------------- Ground shading ----------------------

//Lighting for snow. Constant blue light from directly above and light from the aurora
vec3 shading(vec3 org, vec3 position, vec3 normal, vec3 rayDir){
    
    vec3 auroraColour = 0.75*baseColour;
    vec3 specularColour = vec3(1);
    
    float ambientStrength = 0.1;
    
    float specularStrength = 0.005;
    float shininess = 1.0;
    
    vec3 ambientColour = vec3(0.1);
    vec3 diffuseColour = vec3(1.15);

    //Light comes from a thin line along the main arc
    vec3 lightPos = vec3(-120.0*cos(0.005*position.z), auroraStart, position.z);
    vec3 lightDirection = normalize(lightPos-position);

    if(length(lightPos - org) > 1500.0){
        auroraColour = vec3(0);
    }
    
	vec3 halfwayDir = normalize(lightDirection - rayDir);  
	float spec = pow(max(dot(normal, halfwayDir), 0.0), shininess);

	//Colour of light sharply reflected into the camera
	vec3 specular = spec * specularColour * auroraColour;
    
	//How much a fragment faces the aurora
	float aurora = max(dot(normal, lightDirection), 0.0);
    vec3 auroraLight = aurora * auroraColour;
    
    //How much the fragment faces up
    float sky = max(dot(normal, vec3(0,1,0)), 0.0);
    //Sky light. A blue light from directly above.
	vec3 skyLight = sky * skyColour;
    
	vec3 result = vec3(0.0); 
    
    //Combine light
    result += 0.03 * auroraLight;
    result += 0.035 * skyLight;
    
    //Light and material interaction
    result *= diffuseColour;
    result += ambientStrength * ambientColour + specularStrength * specular;
    
    float fade = clamp(length(position-org)/900.0, 0.0, 1.0);

    return  mix(result, distantColour, smoothstep(0.35, 1.0, fade));
}

float getHeight(vec3 p){
    //Two layers for driven snow look with surface detail
    return 2.5 * texture(iChannel3, 0.004*p.xz).r
         + 0.002 * texture(iChannel2, 0.25*p.xz).r;
}

vec3 getNormal(vec3 p, float t){
    float eps = 0.001 * t;
    return normalize(vec3( 
            getHeight(vec3(p.x-eps, p.y, p.z)) 
            - getHeight(vec3(p.x+eps, p.y, p.z)),

            2.0*eps,

            getHeight(vec3(p.x, p.y, p.z-eps)) 
            - getHeight(vec3(p.x, p.y, p.z+eps)) 
        ));
}

//From Scratchpixel
//Assume normalised vectors.
bool getPlaneIntersection(vec3 org, vec3 ray, vec3 planePoint, vec3 normal, out float t){
    float denom = dot(normal, ray); 
    if (denom > 1e-6) { 
        vec3 p0l0 = planePoint - org; 
        t = dot(p0l0, normal) / denom; 
        return (t >= 0.0); 
    } 
 
    return false; 
}

vec3 getGround(vec3 org, vec3 rayDir, float t){
    vec3 p = org + t * rayDir;
    vec3 normal = getNormal(p, t);
    return shading(org, p, normal, rayDir);
}

vec3 getMountains(vec3 rayDir, vec3 sky){

    //Angle around the horizon
    float phi = atan(rayDir.x, rayDir.z);

    //Sine wave mountains
    float offset = -0.06*(0.5+0.5*sin(6.0*phi));

    //Add fbm detail
    float detail = 0.045*fbm(phi, 6, 0.55);

    //Remove detail around the -PI -> PI transition to avoid a jump
    float limit = PI*0.99;
    float span = PI - limit;
    if(phi > limit || phi < -limit){
        detail *= -(sign(phi)*phi - PI)/span;
    }
    
    //Shift down
    detail += 0.005;
    
    //Apply detail
    offset += detail;
    
    //Smooth edge transition to sky colour
    return mix(distantColour, sky, smoothstep(0.0, 0.003, rayDir.y+offset));
}

//https://knarkowicz.wordpress.com/2016/01/06/aces-filmic-tone-mapping-curve/
vec3 ACESFilm(vec3 x){
    return clamp((x * (2.51 * x + 0.03)) / (x * (2.43 * x + 0.59) + 0.14), 0.0, 1.0);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord ){
    
    //Get the default direction of the ray (along the negative Z direction)
    vec3 rayDir = rayDirection(60.0, fragCoord);
   
    //----------------- Define a camera -----------------
    
    vec3 cameraPos = vec3(0,10,0);
	
    vec3 targetDir = texelFetch(iChannel0, ivec2(0.5, 1.5), 0).xyz;
    
    vec3 up = vec3(0.0, 1.0, 0.0);
    
    //Get the view matrix from the camera orientation
    mat3 viewMatrix = lookAt(cameraPos, targetDir, up);
    
    //Transform the ray to point in the correct direction
    rayDir = normalize(viewMatrix * rayDir);
    
    //---------------------------------------------------
   
    float offset = 0.0;
    #ifdef DITHERING
    //Sometimes the blue noise texture is not immediately loaded into iChannel1
    //leading to jitters.
    if(iChannelResolution[1].xy == vec2(1024)){
        //From https://blog.demofox.org/2020/05/10/ray-marching-fog-with-blue-noise/
        //Get blue noise for the fragment.
        float blueNoise = texture(iChannel1, fragCoord / 1024.0).r;
        offset = fract(blueNoise + float(iFrame%32) * goldenRatio);
    }
    #endif

    vec3 colour = getAuroraColour(cameraPos + rayDir * 10.0, rayDir, offset);; 

    vec3 background;
    if(rayDir.y > 0.0){
        background = getSkyColour(rayDir);
        background = getMountains(rayDir, background);
    }
    
    float t = 0.0;
    if(getPlaneIntersection(cameraPos, rayDir, vec3(0), vec3(0,-1,0), t)){
        background = getGround(cameraPos, rayDir, t);
    }
    
    colour += background;
   
    //Tonemapping
    colour = ACESFilm(colour);

    //Gamma correction 1.0/2.2 = 0.4545...
    colour = pow(colour, vec3(0.4545));

    //Output to screen
    fragColor = vec4(colour, 1.0);
}
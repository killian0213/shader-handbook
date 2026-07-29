// Buffer B (buffer) — HEAVENLY CREATURE by alro
// https://www.shadertoy.com/view/ddyBRy

/*

    Render cloud by raymarching a volume and sampling from Cubemap A
    See https://www.shadertoy.com/view/3sffzj for more details about cloud lighting
    
*/

// Scattering coefficient based on Earth's atmosphere but tweaked for this look
const vec3 BETA_RAYLEIGH = 100.0 * vec3(0.05802, 0.14558, 0.331);
const vec3 BETA_OZONE = vec3(0.650, 1.881, 0.085);

// Scattering
const vec3 sigmaS = 3.0 * BETA_RAYLEIGH;
// Absorption
const vec3 sigmaA = 2.0 * (BETA_RAYLEIGH + 3.0 * BETA_OZONE);
// Extinction
const vec3 sigmaE = sigmaA + sigmaS;

// Main light strength
const float power = 128.0;

const float starStrength = 0.1;

const float densityMultiplier = 0.2;
const float lightDensityMultiplier = 0.15;

// Raymarching
const int STEPS = 32;

// -------------------- Camera --------------------

vec3 rayDirection(float fieldOfView, vec2 fragCoord, vec2 resolution) {
    vec2 xy = fragCoord - resolution / 2.0;
    float z = (0.5 * resolution.y) / tan(radians(fieldOfView) / 2.0);
    return normalize(vec3(xy, -z));
}

// https://www.geertarien.com/blog/2017/07/30/breakdown-of-the-lookAt-function-in-OpenGL/
mat3 lookAt(vec3 targetDir, vec3 up){
  vec3 zaxis = normalize(targetDir);    
  vec3 xaxis = normalize(cross(zaxis, up));
  vec3 yaxis = normalize(cross(xaxis, zaxis));

  return mat3(xaxis, yaxis, -zaxis);
}

//-------------------------------- Lighting --------------------------------

float HenyeyGreenstein(float g, float costh){
	return (1.0 / (4.0 * 3.1415))  * ((1.0 - g * g) / pow(1.0 + g*g - 2.0*g*costh, 1.5));
}

// https://twitter.com/FewesW/status/1364629939568451587/photo/1
vec3 multipleOctaves(float extinction, float mu){

    vec3 luminance = vec3(0);
    const float octaves = 6.0;
    
    // Attenuation
    float a = 1.0;
    // Contribution
    float b = 1.0;
    // Phase attenuation
    float c = 1.0;
    
    float phase;
    
    for(float i = 0.0; i < octaves; i++){
        // Two-lobed HG
        phase = mix(HenyeyGreenstein(-0.1 * c, mu), HenyeyGreenstein(0.3 * c, mu), 0.7);
        luminance += b * phase * exp(-stepL * extinction * sigmaE * a);
        // Lower is brighter
        a *= 0.3;
        // Higher is brighter
        b *= 0.5;
        c *= 0.5;
    }
    return luminance;
}

// Get the amount of light that reaches a sample point.
vec3 lightRay(vec3 org, vec3 p, float phaseFunction, float mu){

	float lightRayDensity = lightDensityMultiplier * getDataInterpolated(p, iChannel1).r;
    
	vec3 beersLaw = multipleOctaves(lightRayDensity, mu);
	
    // Return product of Beer's law and powder effect depending on the 
    // view direction angle with the light direction.
	return mix(beersLaw * 2.0 * (1.0 - (exp( -stepL * lightRayDensity * 2.0 * sigmaE))), 
               beersLaw, 
               0.5 + 0.5 * mu);
}


//-------------------------------- Raymarching --------------------------------

vec4 cloud(vec3 p){
    return getDataInterpolated(p, iChannel1);
}

// Get the colour along the view ray.
vec3 marchCloud(vec3 org, vec3 dir, inout vec3 totalTransmittance, float totalDistance, float dither){
    
    org *= 0.5 * scale;
    totalDistance *= 0.5 * float(width);
	// Variable to track transmittance along view ray. 
    // Assume clear sky and attenuate light when encountering clouds.
	totalTransmittance = vec3(1.0);

	// Default to black.
	vec3 colour = vec3(0.0);
    
    // The distance at which to start ray marching.
    float distToStart = 0.0;
    
	// Sampling step size.
    float stepS = totalDistance / float(STEPS); 
    
    // Offset the starting point by blue noise.
    distToStart += stepS * dither;
    
    // Track distance to sample point.
    float dist = distToStart;

    // Initialise sampling point.
    vec3 p = org + dist * dir;
    
    float mu = dot(dir, sunDirection);

    // Combine backward and forward scattering to have details in all directions.
	float phaseFunction = mix(HenyeyGreenstein(-0.3, mu), HenyeyGreenstein(0.3, mu), 0.7);
    
    vec3 sunLight = vec3(1);

	for(int i = 0; i < STEPS; i++){

        vec4 data = cloud(p);
        
        float density = densityMultiplier * data.a;

        vec3 sampleSigmaS = sigmaS * density;
        vec3 sampleSigmaE = sigmaE * density;

        // If there is a cloud at the sample point.
        if(density > 0.0 ){
           
            vec3 ambient = vec3(0.08) * smoothstep(0.025, -0.03, density) + starStrength * data.ggg;
            
            // Scale ambient by the density at the sample point
            ambient *= smoothstep(1e-3, 8e-3, density);

            // Amount of sunlight that reaches the sample point through the cloud 
            // is the combination of ambient light and attenuated direct light.
            vec3 luminance = ambient + 
                    sunLight * phaseFunction * power * lightRay(org, p, phaseFunction, mu);

            // Scale light contribution by density of the cloud.
            luminance *= sampleSigmaS;

            // Beer-Lambert.
            vec3 transmittance = exp(-sampleSigmaE * stepS);

            // Better energy conserving integration
            // "From Physically based sky, atmosphere and cloud rendering in Frostbite" 5.6
            // by Sebastian Hillaire.
            colour += totalTransmittance * (luminance - luminance * transmittance) / sampleSigmaE; 

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
		p = org + dir * dist;
	}

	return colour;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord ){

    //----------------- Define a camera -----------------

    // Get the default direction of the ray (along the negative Z direction)
    vec3 rayDir = rayDirection(25.0, fragCoord, iResolution.xy);


    vec3 cameraPos = texelFetch(iChannel0, ivec2(0.5, 1.5), 0).xyz;
    vec3 targetDir = -cameraPos;
    vec3 up = vec3(0.0, 1.0, 0.0);

    // Get the view matrix from the camera orientation
    mat3 viewMatrix = lookAt(targetDir, up);

    // Transform the ray to point in the correct direction
    rayDir = normalize(viewMatrix * rayDir);

    //---------------------------------------------------

    vec3 col = 0.05 * vec3(0.25, 0.3, 0.35);
    vec3 data;

    vec2 intersections = intersectAABB(cameraPos, rayDir, vec3(-1.0, -1.0, -1.0)-(1.0 / scale), 
                                                          vec3(1.0, 1.0, 1.0)+(1.0 / scale));
    if(intersections.x < intersections.y){
        vec3 totalTransmittance = vec3(1);
   
        float dither = 0.0;
        const float goldenRatio = 1.61803398875;
        if(iChannelResolution[2].xy == vec2(1024)){
            float blueNoise = texture(iChannel2, fragCoord / 1024.0).r;
            dither = fract(blueNoise + float(iFrame%32) * goldenRatio);
        }
        
        data = marchCloud(  cameraPos + rayDir * max(0.0, intersections.x), 
                            rayDir,
                            totalTransmittance,
                            intersections.y - intersections.x,
                            dither);
        
        col = mix(data, col, totalTransmittance);
    }

    fragColor = vec4(col, 1.0);
}
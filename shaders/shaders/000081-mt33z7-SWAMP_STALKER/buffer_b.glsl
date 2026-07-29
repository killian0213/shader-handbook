// Buffer B (buffer) — SWAMP STALKER by alro
// https://www.shadertoy.com/view/mt33z7

/*

    Pre-integrated screen-space subsurface scattering based on:

    https://therealmjp.github.io/posts/sss-intro/
    https://www.slideshare.net/slideshow/penner-preintegrated-skin-rendering-siggraph-2011-advances-in-realtime-rendering-course/13966747
    https://developer.nvidia.com/gpugems/gpugems3/part-iii-rendering/chapter-14-advanced-techniques-realistic-real-time-skin
    https://www.shadertoy.com/view/4tXBWr
    https://www.shadertoy.com/view/dt2SWh
*/


// Gaussian definition from Nvidia article although different from standard form
// v: variance
// x: evaluation position
float gaussian(float v, float x){
	return 1.0/sqrt(TWO_PI*v)*exp(-(x*x)/(2.0*v));
}

// Scattering profile for human skin from Nvidia article
vec3 getProfile(float x){
    return gaussian(0.0064, x) * vec3(0.233, 0.455, 0.649) +
    	   gaussian(0.0484, x) * vec3(0.100, 0.336, 0.344) +
    	   gaussian(0.1870, x) * vec3(0.118, 0.198, 0.000) +
    	   gaussian(0.5670, x) * vec3(0.113, 0.007, 0.007) +
    	   gaussian(1.9900, x) * vec3(0.358, 0.004, 0.000) +
    	   gaussian(7.4100, x) * vec3(0.078, 0.000, 0.000);
}

/*
  We want to find the amount of light that travels to the evaluated point through a 
  sphere of a given radius. For this we sample points around a circle, integrating 
  the light contribution from each sample point. We find the amount of light arriving 
  at the sample point using the diffuse Lambertian term, calculate the path length 
  through the sphere and find the amount of light that remains after scattering along 
  this path using the scattering profile. Due to symmetry, this can be done in 2D.
*/
vec3 integrateProfile(float angle, float r){

    vec3 totalLight = vec3(0);
    vec3 weight = vec3(0);

    // Higher count gives more accurate results
    const float STEPS = 128.0;
    float delta = TWO_PI / STEPS;

    // Sample points in a circle
    for(float theta = 0.0; theta < TWO_PI; theta += delta){

        /*
          The distance that light travels from the sample point to the evaluated point
          is the length of the chord between these two points. This assumes light travels 
          straight and does not scatter multiple times. This is the formula for a chord
          length of a circle given an angle and a radius.
          https://en.wikipedia.org/wiki/Chord_(geometry)
        */
        float dist = 2.0 * r * sin(0.5 * theta);
        
        // The amount of light that remains while travelling from the sample point
        // to the evaluated point is determined by the scattering profile.
        vec3 scattering = getProfile(dist);

        // The amount of light at the sample point is determined by its normal in relation
        // to the incoming light direction - the diffuse Lambertian term.
        totalLight += max(0.0, cos(angle + theta)) * scattering;
        
        // Accumulate the light contribution to normalize the integral
        weight += scattering;
    }
    
    // Return normalized integral of all incoming light at the evaluation point.
    return totalLight / weight;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord ){

    bool resolutionChanged = texelFetch(iChannel1, ivec2(0.5, 2.5), 0).r > 0.0;
    
    if(iFrame == 0 || resolutionChanged){
        // Normalized pixel coordinates (from 0 to 1)
        vec2 uv = fragCoord/iResolution.xy;
        vec3 col = integrateProfile(PI - uv.x * PI, 1.0 / uv.y);
        fragColor = vec4(col, 1.0);
    }else{
        fragColor = texelFetch(iChannel0, ivec2(fragCoord), 0);
        
        vec3 normalMap = texture(iChannel2, fragCoord/iResolution.xy).rgb;
        fragColor.a = saturate(length(normalMap));
    }
}
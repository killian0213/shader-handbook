// Buffer C (buffer) — Swiss Alps by piyushslayer
// https://www.shadertoy.com/view/ttcSD8

/**
  Buffer C draws the clouds in the sky. The texture from buffer A is used to model the
  clouds in the ray march and the light march loops. Just like buffer B, only 1 out 16
  pixels are processed per frame and the rest are reprojected. If anyone's interested,
  I've compiled a useful list of resources for rendering realtime volumetric clouds
  here: https://gist.github.com/pxv8270/e3904c49cbd8ff52cb53d95ceda3980e
*/

const vec3 noiseKernel[6u] = vec3[] 
(
	vec3( .38051305,  .92453449, -.02111345),
	vec3(-.50625799, -.03590792, -.86163418),
	vec3(-.32509218, -.94557439,  .01428793),
	vec3( .09026238, -.27376545,  .95755165),
	vec3( .28128598,  .42443639, -.86065785),
	vec3(-.16852403,  .14748697,  .97460106)
);

//-------------------------------------------------------------------------------------
// Clouds modeling
//-------------------------------------------------------------------------------------

float raySphereIntersect(Ray ray, float radius)
{
    // note to future me: don't need "a" bcuz rd is normalized and dot(rd, rd) = 1
 	float b = 2. * dot(ray.origin, ray.direction);
    float c = dot(ray.origin, ray.origin) - radius * radius;
    float d = sqrt(b * b - 4. * c);
    return (-b + d) * .5;
}

float cloudGradient(float h)
{
    return smoothstep(0., .05, h) * smoothstep(1.25, .5, h);
}

float cloudHeightFract(float p)
{
	return (p - EARTH_RADIUS - CLOUD_BOTTOM) / (CLOUD_TOP - CLOUD_BOTTOM);
}

float cloudBase(vec3 p, float y)
{
    vec3 noise = textureLod(iChannel2, (p.xz - (WIND_DIR.xz * iTime * WIND_SPEED))
                            * CLOUD_BASE_FREQ, 0.).rgb;
    float n = y * y * noise.b + pow(1. - y, 12.);
    float cloud = remap01(noise.r - n, noise.g - 1., 1.);
    return cloud;
}

float cloudDetail(vec3 p, float c, float y)
{
    p -= WIND_DIR * 3. * iTime * WIND_SPEED;
    // this is super expensive :(
    float hf = worleyFbm(p, CLOUD_DETAIL_FREQ, false) * .625 +
        	   worleyFbm(p, CLOUD_DETAIL_FREQ*2., false) * .25 +
        	   worleyFbm(p, CLOUD_DETAIL_FREQ*4., false) * .125;
    hf = mix(hf, 1. - hf, y * 4.);
    return remap01(c, hf * .5, 1.);
}

float getCloudDensity(vec3 p, float y, bool detail)
{
    p.xz -= WIND_DIR.xz * y * CLOUD_TOP_OFFSET;
    float d = cloudBase(p, y);
    d = remap01(d, CLOUD_COVERAGE, 1.) * (CLOUD_COVERAGE);
    d *= cloudGradient(y);
    bool cloudDetailTest = (d > 0. && d < .3) && detail; 
    return ((cloudDetailTest) ? cloudDetail(p, d, y) : d);
}

//-------------------------------------------------------------------------------------
// Clouds lighting
//-------------------------------------------------------------------------------------

float henyeyGreenstein( float sunDot, float g) {
	float g2 = g * g;
	return (.25 / PI) * ((1. - g2) / pow( 1. + g2 - 2. * g * sunDot, 1.5));
}

float marchToLight(vec3 p, vec3 sunDir, float sunDot, float scatterHeight)
{
    float lightRayStepSize = 11.;
	vec3 lightRayDir = sunDir * lightRayStepSize;
    vec3 lightRayDist = lightRayDir * .5;
    float coneSpread = length(lightRayDir);
    float totalDensity = 0.;
    for(int i = 0; i < CLOUD_LIGHT_STEPS; ++i)
    {
        // cone sampling as explained in GPU Pro 7 article
     	vec3 cp = p + lightRayDist + coneSpread * noiseKernel[i] * float(i);
        float y = cloudHeightFract(length(p));
        if (y > .95 || totalDensity > .95) break; // early exit
        totalDensity += getCloudDensity(cp, y, false) * lightRayStepSize;
        lightRayDist += lightRayDir;
    }
    
    return 32. * exp(-totalDensity * mix(CLOUD_ABSORPTION_BOTTOM,
				CLOUD_ABSORPTION_TOP, scatterHeight)) * (1. - exp(-totalDensity * 2.));
}

//-------------------------------------------------------------------------------------

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 st = fragCoord / iResolution.xy;
    vec2 uv = (2. * fragCoord - iResolution.xy) / iResolution.y;
    vec2 mouse = (2. * iMouse.xy - iResolution.xy) / iResolution.y;
    float terrainDist = texelFetch(iChannel0, ivec2(fragCoord), 0).w;
    vec4 prevCol = textureLod(iChannel1, st, 0.);
    vec4 col = vec4(0.);
    
    bool updatePixel = writeToPixel(fragCoord, iFrame);
    
    if (updatePixel) // only draw 1/16th resolution per frame
    {
        
        Ray ray = getCameraRay(uv, iTime);
        vec3 sun = getSun(mouse, iTime);
        // clouds don't get blindingly bright with sun at zenith
        sun.z = clamp(sun.z, 0., .8);
        vec3 sunDir = normalize(vec3(sun.x, sun.z, -1.));
        float sunDot = max(0., dot(ray.direction, sunDir));
        float sunHeight = smoothstep(.01, .1, sun.z + .025);
        
        if (terrainDist > CAMERA_FAR)
        {

            // clouds
            ray.origin.y = EARTH_RADIUS;
            float start = raySphereIntersect(ray, EARTH_RADIUS + CLOUD_BOTTOM);
            float end = raySphereIntersect(ray, EARTH_RADIUS + CLOUD_TOP);
            float cameraRayDist = start;
            float cameraRayStepSize = (end - start) / float(CLOUD_STEPS);
            
            // blue noise offset
            cameraRayDist += cameraRayStepSize * texelFetch(iChannel3,
							(ivec2(fragCoord) + iFrame * ivec2(113, 127)) & 1023, 0).r;
            vec3 skyCol = atmosphericScattering(vec2(0.15, 0.05),
                                vec2(.5, sun.y*.5+.25), false);
            skyCol.r *= 1.1;
			skyCol = SAT(pow(skyCol * 2.1, vec3(4.2)));
            float sunScatterHeight = smoothstep(.15, .4, sun.z);
            float hgPhase = mix(henyeyGreenstein(sunDot, .4),
                                henyeyGreenstein(sunDot, -.1), .5);
            // sunrise/sunset hack
            hgPhase = max(hgPhase, 1.6 * henyeyGreenstein(sqrt(sunDot),
							SAT(.8 - sunScatterHeight)));
            // shitty night time hack
            hgPhase = mix(pow(sunDot, .25), hgPhase, sunHeight);
            
            vec4 intScatterTrans = vec4(0., 0., 0., 1.);
            vec3 ambient = vec3(0.);
            for (int i = 0; i < CLOUD_STEPS; ++i)
            {
                vec3 p = ray.origin + cameraRayDist * ray.direction;
                float heightFract = cloudHeightFract(length(p));
                float density = getCloudDensity(p, heightFract, true);
                if (density > 0.)
                {
                    ambient = mix(CLOUDS_AMBIENT_BOTTOM, CLOUDS_AMBIENT_TOP, 
                                  	heightFract);
					
                    // cloud illumination
                    vec3 luminance = (ambient * SAT(pow(sun.z + .04, 1.4))
						+ skyCol * .125 + (sunHeight * skyCol + vec3(.0075, .015, .03))
						* SUN_COLOR * hgPhase
						* marchToLight(p, sunDir, sunDot, sunScatterHeight)) * density;

                    // improved scatter integral by Sébastien Hillaire
                    float transmittance = exp(-density * cameraRayStepSize);
                    vec3 integScatter = (luminance - luminance * transmittance)
                        * (1. / density);
                    intScatterTrans.rgb += intScatterTrans.a * integScatter; 
                    intScatterTrans.a *= transmittance;

                }

                if (intScatterTrans.a < .05)
                    break;
                cameraRayDist += cameraRayStepSize;
            }

            // blend clouds with sky at a distance near the horizon (again super hacky)
            float fogMask = 1. - exp(-smoothstep(.15, 0., ray.direction.y) * 2.);
            vec3 fogCol = atmosphericScattering(uv * .5 + .2, sun.xy * .5 + .2, false);
            intScatterTrans.rgb = mix(intScatterTrans.rgb,
                                      fogCol * sunHeight, fogMask);
            intScatterTrans.a = mix(intScatterTrans.a, 0., fogMask);

            col = vec4(max(vec3(intScatterTrans.rgb), 0.), intScatterTrans.a);
            
            //temporal reprojection
    		col = mix(prevCol, col, .5);
        }
    }
    else
    {
		col = prevCol;
    }
    
    fragColor = col;
}
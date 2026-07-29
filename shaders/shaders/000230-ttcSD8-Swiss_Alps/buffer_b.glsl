// Buffer B (buffer) — Swiss Alps by piyushslayer
// https://www.shadertoy.com/view/ttcSD8

/**
  Buffer B ray marches and shades the terrain using iq's 3 light model and improved
  height fog. This buffer only updates 1 pixel in a 4x4 grid per frame, and the rest
  are reprojected.
*/

// Iq's slightly modified terrain fbm
const mat2 m2 = mat2(.8, -.6, .6, .8);

float terrainFbm(vec2 uv, int octaves, sampler2D smp)
{
    vec2  p = uv * TERRAIN_FREQ;
    float a = 0.;
    float b = 1.;
	vec2  d = vec2(0.);
    
    for (int i = 0; i < octaves; ++i)
    {
        vec3 n = valueNoiseDerivative(p, smp);
        d += n.yz;
        a += b * n.x / (1. + dot(d, d));
		b *= .5;
        p = m2 * p * 2.;
    }
    
    a = abs(a) * 2. - 1.;
    
    return smoothstep(-.95, .5, a) * a * TERRAIN_HEIGHT;
}

vec3 calcNormal(vec3 pos, float freq, float t)
{
    vec2 eps = vec2( 0.002 * t, 0.0 );
    int norLod = int(max(5., float(HQ_OCTAVES) - (float(HQ_OCTAVES) - 1.)
                         * t / CAMERA_FAR));
    return normalize( 
        vec3(terrainFbm(pos.xz - eps.xy, norLod, iChannel0) - terrainFbm(pos.xz
					+ eps.xy, norLod, iChannel0),
             2.0 * eps.x,
             terrainFbm(pos.xz - eps.yx, norLod, iChannel0) - terrainFbm(pos.xz
					+ eps.yx, norLod, iChannel0)));
}

float raymarchShadow(Ray ray)
{
    float shadow = 1.;
	float t = CAMERA_NEAR;
    vec3 p = vec3(0.);
    float h = 0.;
    for(int i = 0; i < 80; ++i)
	{
	    p = ray.origin + t * ray.direction;
        h = p.y - terrainFbm(p.xz, MQ_OCTAVES, iChannel0);
		shadow = min(shadow, 8. * h / t);
		t += h;
		if (shadow < 0.001 || p.z > CAMERA_FAR) break;
	}
	return SAT(shadow);
}

float raymarchTerrain(Ray ray)
{
	float t = CAMERA_NEAR, h = 0.;
    for (int i = 0; i < 200; ++i)
    {
    	vec3 pos = ray.origin + ray.direction * t;
        h = pos.y - terrainFbm(pos.xz, MQ_OCTAVES, iChannel0);
        if (abs(h) < (t * .002) || t > CAMERA_FAR)
            break;
        t += h * .5;
    }
    return t;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 st = fragCoord / iResolution.xy;
    vec2 uv = (2. * fragCoord - iResolution.xy) / iResolution.y;
    vec2 mouse = (2. * iMouse.xy - iResolution.xy) / iResolution.y;
    
    bool updatePixel = writeToPixel(fragCoord, iFrame);
    
    vec4 col = textureLod(iChannel1, st, 0.);
    
    if(updatePixel) // only draw 1/16th resolution per frame
    {
        Ray ray = getCameraRay(uv, iTime);
    
        float terrainDist = raymarchTerrain(ray);

        vec3 sun = getSun(mouse, iTime);
        vec3 sunDir = normalize(vec3(sun.x, sun.z, -1.));
        vec3 sunHalf = normalize(sunDir+ray.direction);
        float sunDot = max(0., dot(ray.direction, sunDir));
        
		vec3 terrainNormal = vec3(0.);
        
        col *= 0.;
        
        if (terrainDist > CAMERA_FAR)
        {
            // sky
            col.rgb += atmosphericScattering(uv * .5 + .225, sun.xy * .5 + .225, true);
            col.gb += .006 - uv.y * .0048; // slight night time blue-green tint

            // stars
            float t = iTime * .15;
            float stars = pow(hash12(fragCoord), 4. * iResolution.x);
            float twinkle = sin(t * 3.7 + uv.x - sin(uv.y * 20. + t) * 10.) * 2.;
            twinkle *= cos(uv.y + t * 4.4 - sin(uv.x * 15. + t) * 7.) * 1.5;
            twinkle = twinkle * .5 + .5;
            col += max(0., stars * twinkle * smoothstep(.075, 0., sun.z) * 2.);
        }
        else
        {
            vec3 marchPos = ray.origin + ray.direction * terrainDist;
            terrainNormal += calcNormal(marchPos, TERRAIN_FREQ, terrainDist); 
			
            // terrain colors
            vec3 rock = vec3(.1, .1, .08);
            vec3 snow = vec3(.9);
            vec3 grass = vec3(.02, .1, .05);

            vec3 albedo = mix(grass, rock, smoothstep(0., .1 * TERRAIN_HEIGHT,
								marchPos.y)); 
            albedo = mix(albedo, snow, smoothstep(.4 * TERRAIN_HEIGHT,
							1.4 * TERRAIN_HEIGHT, marchPos.y));
            albedo = mix(rock, albedo, smoothstep(.4, .7, terrainNormal.y));

            float terrainShadow = clamp(raymarchShadow(Ray(marchPos - sunDir * .001, 
										sunDir)), 0., 8.) + .2;

            float diffuse = max(dot(sunDir, terrainNormal), 0.) * terrainShadow;
            float specular = SAT(dot(sunHalf, ray.direction));
            float skyAmbient = SAT(.5 + .5 * terrainNormal.y);

            col.rgb += SUN_INTENSITY * SUN_COLOR * diffuse; // sun diffuse
            // sky ambient
            col.rgb += vec3(.5, .7, 1.2) * skyAmbient;
            // backlight ambient
            col.rgb += SUN_COLOR * (SAT(.5 + .5 * dot(
                normalize(vec3(-sunDir.x, sunDir.y, sunDir.z)), terrainNormal)));
            // terrain tex color
            col.rgb *= albedo;

            // specular
            col.rgb += SUN_INTENSITY * .4 * SUN_COLOR * diffuse 
                			* pow(SAT(specular), 16.);

            // Iq's height based density fog
            float fogMask = FOG_C * exp(-ray.origin.y * FOG_B) *
                (1. - exp(-pow(terrainDist * FOG_B, 1.5) * ray.direction.y))
                / ray.direction.y;
            vec3 fogCol = mix(atmosphericScattering(uv * .5 + .75, sun.xy * .5 + .225,
								false) * .75, vec3(.8, .6, .3), pow(sunDot, 8.));
            // shitty night time fog hack
            fogCol = mix(vec3(.4, .5, .6), fogCol, smoothstep(0., .1, sun.z));
            col.rgb = mix(col.rgb, fogCol, SAT(fogMask));

            col.rgb *= max(.0, sun.z)
                + mix(vec3(smoothstep(.1, 0., sun.z)) * terrainNormal.y, fogCol, 
                      SAT(fogMask)) * (.012, .024, .048);
        }
        col.a = terrainDist;
    }
    
    fragColor = col;
    
    if (fragCoord.x < 1. && fragCoord.y < 1.)
    {
    	fragColor = vec4(iResolution.x, vec3(0.));   
    }
}
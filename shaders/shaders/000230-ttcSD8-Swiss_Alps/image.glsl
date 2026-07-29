// Image (image) — Swiss Alps by piyushslayer
// https://www.shadertoy.com/view/ttcSD8

/**
  My first attempt at rendering volumetric clouds and ray marched terrain. Terrain is
  rendered based on ray marching techniques by iq, and the clouds are rendered based
  on techniques by Nathan Vos and Andrew Schneider(Guerrilla), and Sébastien Hillaire
  (Epic), see buffer C for more details. 

  This main image tab mostly apples some post-process effects to the terrain and cloud
  textures, including a gaussian blue for the clouds to hide noise/ray marching
  artifacts, and some lens flares and light scattering effects, along with a
  luminance based reinhard tonemapper. 
*/

//-------------------------------------------------------------------------------------
// Gaussian Blur
//-------------------------------------------------------------------------------------

#define texelOffset vec2(1.75 / iResolution.xy)

const float kernel[9] = float[]
(
	.0625, .125, .0625,
    .125,  .25,  .125,
    .0625, .125, .0625  
);

vec4 gaussianBlur(sampler2D buffer, vec2 uv)
{
    vec4 col = vec4(0.);
    
 	vec2 offsets[9] = vec2[](
        vec2(-texelOffset.x,  texelOffset.y),  // top-left
        vec2( 			0.,   texelOffset.y),  // top-center
        vec2( texelOffset.x,  texelOffset.y),  // top-right
        vec2(-texelOffset.x,  			 0.),  // center-left
        vec2( 			0.,			 	 0.),  // center-center
        vec2( texelOffset.x,  	 		 0.),  // center-right
        vec2(-texelOffset.x,  -texelOffset.y), // bottom-left
        vec2( 			0.,   -texelOffset.y), // bottom-center
        vec2( texelOffset.x,  -texelOffset.y)  // bottom-right    
    );
    
    for(int i = 0; i < 9; i++)
    {
        col += textureLod(buffer, uv + offsets[i], 0.) * kernel[i];
    }
    
    return col;
}

//-------------------------------------------------------------------------------------
// Lens Flare (from shadertoy.com/view/XdfXRX)
//-------------------------------------------------------------------------------------

#define ORB_FLARE_COUNT	8
#define DISTORTION_BARREL 1.3

vec2 GetDistOffset(vec2 uv, vec2 pxoffset)
{
    vec2 tocenter = uv.xy;
    vec3 prep = normalize(vec3(tocenter.y, -tocenter.x, 0.0));
    
    float angle = length(tocenter.xy) * 2.221 * DISTORTION_BARREL;
    vec3 oldoffset = vec3(pxoffset, 0.);
    
    vec3 rotated = oldoffset * cos(angle) + cross(prep, oldoffset)
        * sin(angle) + prep * dot(prep, oldoffset) * (1. - cos(angle));
    
    return rotated.xy;
}

vec3 flare(vec2 uv, vec2 pos, float dist, float size)
{
    pos = GetDistOffset(uv, pos);
    
    float r = max(.01 - pow(length(uv + (dist - .05)*pos), 2.4) 
                  *(1. / (size * 2.)), 0.) * 6.0;
	float g = max(.01 - pow(length(uv +  dist       *pos), 2.4) 
                  *(1. / (size * 2.)), 0.) * 6.0;
	float b = max(.01 - pow(length(uv + (dist + .05)*pos), 2.4) 
                  *(1. / (size * 2.)), 0.) * 6.0;
    
    return vec3(r, g, b);
}

vec3 ring(vec2 uv, vec2 pos, float dist)
{
    vec2 uvd = uv*(length(uv));
    
    float r = max(1. / (1. + 32. * pow(length(uvd + (dist - .05)
				  * pos), 2.)), 0.) * .25;
	float g = max(1. / (1. + 32. * pow(length(uvd +  dist       
				  * pos), 2.)), 0.) * .23;
	float b = max(1. / (1. + 32. * pow(length(uvd + (dist + .05)
				  * pos), 2.)), 0.) * .21;
    
    return vec3(r,g,b);
}

vec3 lensflare(vec2 uv,vec2 pos, float brightness, float size)
{
	
    vec3 c = flare(uv, pos, -1., size) * 3.;
    c += flare(uv, pos, .5, .8 * size) * 2.;
    c += flare(uv, pos, -.4, .8 * size);
    
    c += ring(uv, pos, -1.) * .5 * size;
    c += ring(uv, pos, 1.) * .5 * size;
    
    return c * brightness;
}

//-------------------------------------------------------------------------------------
// Light Scattering
//-------------------------------------------------------------------------------------

#define NUM_SAMPLES 48
#define DENSITY .768
#define WEIGHT .14
#define DECAY .97

vec3 lightScattering(vec2 uv, vec2 lightPos, vec3 sun)
{    
    vec2 deltauv = vec2(uv - lightPos);
    vec2 st = uv;
    uv = uv * 2. - 1.;
    uv.x *= iResolution.x / iResolution.y;
    deltauv *= 1. /  float(NUM_SAMPLES) * DENSITY;
    float illuminationDecay = 1.;
    vec3 result = vec3(0.);

    for(int i = 0; i < NUM_SAMPLES; i++)
    {
        st -= deltauv;
        float lightStep = textureLod(iChannel1, st, 0.).a
            		* smoothstep(2.5, -1., length(uv-sun.xy));

        lightStep *= illuminationDecay * WEIGHT;

        result += lightStep;

        illuminationDecay *= DECAY;
    }
    
    return result * (SUN_COLOR) * .2;
}

//-------------------------------------------------------------------------------------
// Tone mapping
//-------------------------------------------------------------------------------------

vec3 luminanceReinhard(vec3 color)
{
	float lum = dot(color, vec3(.2126, .7152, .0722));
	float toneMappedLum = lum / (1. + lum);
	color *= toneMappedLum / lum;
	return color;
}

//-------------------------------------------------------------------------------------

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 st = fragCoord/iResolution.xy;
    vec2 uv = (2. * fragCoord - iResolution.xy) / iResolution.y;
    vec2 mouse = (2. * iMouse.xy - iResolution.xy) / iResolution.y;
    vec3 sun = getSun(mouse, iTime);

	vec4 terrain = textureLod(iChannel0, vec2(st.x, st.y - 1. / iResolution.y), 0.);
    vec4 clouds = gaussianBlur(iChannel1, st);
    float cloudsAlphaMask = clouds.a + (terrain.a > CAMERA_FAR ? 0. : 1.);
    
    vec2 lightPosScreenSpace = vec2(sun.x * iResolution.y/iResolution.x, sun.y) * .5 + .5;
    float lensflareMask = textureLod(iChannel1, lightPosScreenSpace, 0.).a;
    
    vec3 col = vec3(0.);
    col = vec3(clouds.rgb + terrain.rgb * cloudsAlphaMask);
    col += lightScattering(st, lightPosScreenSpace, sun) * smoothstep(.01, .16, sun.z)
        		* smoothstep(.3, 1.5, terrain.a);
	col += lensflare(uv, sun.xy, .8, 4.) * vec3(1.4, 1.2, 1.) * lensflareMask;
    col = mix(col, pow(luminanceReinhard(col), vec3(.4545)), .75);
    col += hash12(fragCoord) * .004;

    fragColor = vec4(col, 1.);
    
    // hide the ugly red pixel
    if (fragCoord.y < 2. && fragCoord.x < 2.)
        fragColor = vec4(.6) * sun.z;
}
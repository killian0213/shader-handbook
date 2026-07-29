// Image (image) — Erosion Idea by TekF
// https://www.shadertoy.com/view/WtlSR7

// Terrain Rendering

const float heightScale = .25;
const int numSlices = 300;
#define WRAP 1
#define PERSPECTIVE 1
#define DRAW_EVERY_N_FRAMES 1
const float cameraOrbitSpeed = .03; // radians per second
const float cameraOrbitStart = .4;
const float cameraPitch = .4;
const float cameraDistance = 2.2;
const vec3 cameraVelocity = vec3(-.1,0,.03); // this really helps hide aliasing problems
const float zoom = 1.5;
/*
const float cameraPitch = .3;
const float cameraDistance = .7;
const float zoom = .8;
*/

const vec3 lightDirection = vec3(-3,1,2);
const vec3 lightTint = vec3(1);
const vec3 shadeTint = vec3(.06,.08,.13)*1.5;


// desert
const vec3 baseColour = vec3(.5,.367,.3);
const vec3 grassColour = vec3(.7,.5,.4);
const vec3 sandColour = vec3(.6,.2,.0);
const vec3 snowColour = vec3(1);
/*
// alpine - looks interesting but adds a lot of visual noise and confusion
const vec3 baseColour = vec3(.6,.533,.5);
const vec3 grassColour = vec3(0,.3,.05);
const vec3 sandColour = vec3(.3,.2,.1);
const vec3 snowColour = vec3(1);
*/
#define DEBUG_COLOURS 0

const vec3 slowWaterColour = vec3(.0,.15,.35);
const vec3 fastWaterColour = vec3(.6,.9,.8);
const float fastWaterSpeed = .13;
const float waterOpacityScale = .03; // looks really cool with lower values here

// could add grassy colours where there's a little water, snow where there's flat high altitude dry bits...

vec4 WrappedTap( ivec2 uv)
{
	ivec2 ires = ivec2(iResolution.xy);
    
    uv = (uv+ires*10)%ires; // mod goes wrong on negative numbers, 10 should be enough to hide this
    if ( uv.x == 0 && uv.y == 0 ) uv.x = 1; // don't read the data texel!
	return texelFetch(iChannel0, uv, 0);
}

vec4 Sample( vec2 uv )
{
     uv = uv*vec2(iResolution.y/iResolution.x,1)+.5;
#if WRAP
    vec2 duvdx = dFdx(uv), duvdy = dFdy(uv);
    uv = fract(uv);
    if ( max(abs(uv.x)*iResolution.x,abs(uv.y)*iResolution.y) < 1.5 ) uv.x = 1.5/iResolution.x; // avoid reading the data pixel
    vec4 tap = textureGrad(iChannel0,uv,duvdx,duvdy); // tile with corrected filtering
//^ this gets an artefact at the edge - probably because of clamping not lerping the wrap pixel
// BUT it's a lot faster!  
        
/*    // instead, bilinearly filter manually with a wrap
    uv *= iResolution.xy;
    ivec2 iuv = ivec2(floor(uv));
    uv -= vec2(iuv);
    
	ivec2 ires = ivec2(iResolution.xy);
    ivec2 d = ivec2(0,1);
    vec4 tap =
        mix(
            mix(
                WrappedTap( (iuv+d.xx+ires*10)%ires ),
                WrappedTap( (iuv+d.yx+ires*10)%ires ),
                uv.x),
            mix(
                WrappedTap( (iuv+d.xy+ires*10)%ires ),
                WrappedTap( (iuv+d.yy+ires*10)%ires ),
                uv.x),
           uv.y );*/
#else
    vec4 tap = texture(iChannel0,uv);
    if ( min(uv.x,uv.y) < 0. || max(uv.x,uv.y) > 1. ) tap.w = -1.;
#endif
	return tap;
}

void mainImage( out vec4 fragColour, in vec2 fragCooord )
{
    if ( iFrame%DRAW_EVERY_N_FRAMES > 0 ) discard;
    
    float camTime = length(vec2(10,max(0.,iTime-10.)))-10.;
    float cameraOrbitTime = camTime*cameraOrbitSpeed - cameraOrbitStart;
    vec3 cameraTarget = vec3(0,-heightScale*.3,0) + camTime*cameraVelocity;
    vec3 cameraPosition = cameraTarget
       				+ (vec3(cos(cameraOrbitTime),0,sin(cameraOrbitTime))*cos(cameraPitch)
                       + vec3(0,sin(cameraPitch),0)
                      )*cameraDistance;
    
    vec2 screenPosition = (fragCooord-iResolution.xy*.5)/iResolution.x;
    #if (PERSPECTIVE)
    	// perspective
    	vec3 ray = vec3(screenPosition,1.2*zoom);
    #endif
    
    vec3 cameraK = normalize(cameraTarget-cameraPosition);
    vec3 cameraI = normalize(cross(vec3(0,1,0),cameraK));
    vec3 cameraJ = cross(cameraK,cameraI);

    #if (!PERSPECTIVE)
    	// orthographic
    	vec3 ray = vec3(0,0,1);
    	cameraPosition += (cameraI*screenPosition.x + cameraJ*screenPosition.y) * .8*cameraDistance/zoom;
    #endif

    ray = ray.x*cameraI + ray.y*cameraJ + ray.z*cameraK;
    ray = normalize(ray);

    fragColour = vec4(.5);
    
    for ( int i=0; i < numSlices; i++ )
    {
        float f = numSlices > 1 ? float(i)/float(numSlices-1) : 0.5;
        f = 1. - f; // from top to bottom!
        
        // intersect ray with horizontal plane at top of height field
        float t = ((f-.5)*heightScale-cameraPosition.y)/ray.y;
        vec3 position = cameraPosition + ray*t;

        vec2 uv = position.xz;

		vec4 tap = Sample(uv);
        
//tap.w += tap.x; // show water level
//tap.w += tap.y; // include sediment to prevent holes when water settles
        
        if ( tap.w > f )
        {
            // estimate dot product with surface normal
            float sampleDistance = .7/iResolution.y;
            vec3 lightDir = normalize(lightDirection);
            
            vec2 sampleOffset = vec2(0,sampleDistance);
            vec2 positionX = position.xz + sampleOffset.yx;
            vec2 positionZ = position.xz + sampleOffset.xy;
            vec2 uvX = positionX;
            float heightX = Sample(uvX).w;
            vec2 uvZ = positionZ;
            float heightZ = Sample(uvZ).w;
            
            float height = tap.w * heightScale;
            heightX *= heightScale;
            heightZ *= heightScale;
            
            // construct a 3D normal, I think ^ that 2D trick doesn't work
            vec3 n = normalize(
                	cross( vec3(positionZ,heightZ).xzy - vec3(position.xz,height).xzy,
                		   vec3(positionX,heightX).xzy - vec3(position.xz,height).xzy )
                );
            
            float light = max(0.,dot(n,lightDir));

            vec3 shade = shadeTint*mix(.3,1.,n.y)*pow(fragColour.a,.25); // add some definition to shadows

            float waterSlowness = 1./(tap.z/fastWaterSpeed+1.);
            vec3 water = mix( fastWaterColour, slowWaterColour, waterSlowness );
            
            float ior = 1.33;
            float schlick = (ior-1.)/(ior+1.);
            vec3 reflection = vec3(10)*waterSlowness*smoothstep(.1,.3,reflect(ray,n).y);
            reflection += pow(max(0.,dot(n,normalize(lightDir-ray))),500.)*20.; // specular
            water = mix( water, reflection, mix( schlick*schlick, 1., pow(1.+dot(n,ray),5.) ) );
            
            vec3 ground = baseColour;
            
            // grass on shallow slopes with enough water
            ground = mix( ground, grassColour, smoothstep(.0,.8,smoothstep(0.,2.,tap.x)*smoothstep(.8,1.,n.y)) );

            // sand/gravel on shallow slopes with too much water
            ground = mix( ground, sandColour, smoothstep(.0,.8,smoothstep(8.,12.,tap.x)*smoothstep(.5,.8,n.y)) );

            // snow on peaks
            ground = mix( ground, snowColour, smoothstep(.0,.1,smoothstep(2.5,0.,tap.x)*smoothstep(.3,1.,tap.w)*smoothstep(.8,1.,n.y)) );

            fragColour.rgb = mix( ground, water, clamp(tap.x*waterOpacityScale,0.,1.) );
			fragColour.rgb *= vec3(pow(tap.a,.5))*.8+.6; // darken deeper areas
		    fragColour.rgb = pow(fragColour.rgb,vec3(2.2));

            fragColour.rgb *= mix( shade, lightTint, light );
            
            // ground fog
            // I found this code in an old email to myself - I think I wrote it but not 100% sure!
            const float a = .12;
            const float b = 8.;
			float o = cameraPosition.y;
		    float k = ray.y;
    		k = sign(k)*max(abs(k),.001); // avoid division by 0, and huge numbers near that
            vec3 fogColour = vec3(.5,.73,1);
            vec3 visibility = exp( (a/(b*k))*( exp(-b*(o+k*t)) - exp(-b*o) ) * fogColour );
            fragColour.rgb = mix( vec3(1), fragColour.rgb, visibility );
            
            // colour correct to bring back some contrat lost in the fog
            // (most aerial photos do this, so it tends to look wrong without this)
            fragColour.rgb -= fogColour*.03;
            
            #if DEBUG_COLOURS
            	fragColour.rgb = tap.xyw;
            #endif
            
            break;
        }
    }
    
    fragColour.rgb = pow(fragColour.rgb,vec3(1./2.2));
}
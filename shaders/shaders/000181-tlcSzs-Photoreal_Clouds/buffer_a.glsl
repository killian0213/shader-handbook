// Buffer A (buffer) — Photoreal Clouds by TekF
// https://www.shadertoy.com/view/tlcSzs

// Photoreal Clouds by Hazel Quantock
// This work is licensed under a Creative Commons Attribution-ShareAlike 4.0 International License. https://creativecommons.org/licenses/by-sa/4.0/

// scene parameters
const float cloudiness = .6;

const vec3 groundColour = vec3(.1,.15,.05); // grassy
//const vec3 groundColour = vec3(.1); // dark grey (looks a bit brown because of tone mapping)
//const vec3 groundColour = vec3(1); // snow

const vec3 lightDirection = normalize(vec3(1,2,3));
const vec3 lightColour = vec3(3);


// control the ray marcher
const float minStepLength = .15;
const float shadowDrawDistance = 8.;

const float directLightProportion = 1./6.; // proportion of scattered rays used to sample direct light (balance graininess of god rays vs graininess of radiosity)
//^ this shouldn't be affecting radiosity brightness, but it is! Bah!

struct ScatterData
{
	float scatter; // proportion of rays scattered per metre - must be less than 1.0
	vec3 tint; // what proportion of RGB light remains after 1m - must be more than 0.0 - applies independent of scatter, so if this is 1,1,1 we still have reduction in visibility caused by scatter
    vec3 emission; // amount of light added per 1m - should work for values > 1 but I'm not sure
	vec3 scatterTint; // particles can have one colour when light bounces off them and a different colour when light is absorbed by them - this can be [0,1]
    float eccentricity; // bias the direction of scattering toward/away from (+ve/-ve) incident light direction
};

ScatterData Mix( ScatterData a, ScatterData b, float c )
{
	// this isn't perfect - interpolated media can have values that look different either of the two being blended
    // e.g. this can cause a halo around very dense objects when they interpolate to the colour of the sky
    // to reduce this effect, premultiply by scatter, to prioritise the parameters of the denser media
    ScatterData m = 
        ScatterData(
            mix( a.scatter, b.scatter, c ),
            mix( a.tint*a.scatter, b.tint*b.scatter, c ),
            mix( a.emission*a.scatter, b.emission*b.scatter, c ),
            mix( a.scatterTint*a.scatter, b.scatterTint*b.scatter, c ),
            mix( a.eccentricity*a.scatter, b.eccentricity*b.scatter, c )
        );
    return
        ScatterData(
            m.scatter,
            m.tint/m.scatter,
            m.emission/m.scatter,
            m.scatterTint/m.scatter,
            m.eccentricity/m.scatter
        );
}


// signed distance field (SDF) for a torus
// returned value is distance of pos from the surface (negative if inside)
float Torus( vec3 position, vec3 axis, float majorRadius, float minorRadius )
{
    axis = normalize(axis);
    float perp = dot(axis,position);
    position -= perp*axis;
    return length( vec2( perp, length(position) - majorRadius ) ) - minorRadius;
}

    
ScatterData SampleMedia( vec3 pos )
{
    ScatterData air = ScatterData( .03, vec3(1,.996,.99), vec3(0), vec3(.6,.8,1), .3 );

    // a curve through 0, steeper on the underside of clouds so they have flat bottoms
	float cloudSDF = pos.y*pos.y/mix(1.,12.,step(0.,pos.y));
    
	// columns of cloud (shadow draw distance is too short to catch shadows from these, but they look cool despite this)
	//cloudSDF = min(cloudSDF,(length((fract((pos.xz-vec2(0,-2))/12.+.5)-.5)*12.)-3.)*.5);
    
    // add layers of noise to the clouds
    vec3 cloudNoisePos = pos;
#ifdef ANIMATE
    cloudNoisePos += iTime*vec3(0,.01,.06);
#endif
    cloudSDF += 1.5*Noise(cloudNoisePos/3.+9.); // lowest frequency defines the boundaries of the clouds
    cloudSDF += .7*(Noise(cloudNoisePos*2.)-.5) + .25*(Noise(cloudNoisePos*6.)-.5) + .16*(Noise(cloudNoisePos*18.)-.5); // higher freqs make the edges lumpy
    cloudSDF -= cloudiness; // offset the SDF to give more/less cloud coverage
    
    ScatterData cloud = ScatterData( .99, vec3(1), vec3(0), vec3(1), .3 /* directionality of scatter - silver lining vs reflected light */ );

    // ground is a very dense gas
	float groundSDF = pos.y+4.+1.*(Noise(pos/3.+1.)-.5);
    ScatterData ground = ScatterData( 1., vec3(1), vec3(0), groundColour, .0 );
    
    // "solid" test objects
    float objSDF = length(pos-vec3(0,-2,0)) - 2.;
//    objSDF = min(objSDF,length(pos-vec3(0,2,-3)) - 2.); // 2nd ball in the sky
    objSDF = min( objSDF, Torus(pos-vec3(4,1.5,-9),vec3(.1,1,.2),12.,1.) ); // giant torus in the sky
//    objSDF += (Noise(pos*1.4)-.5)*.2; // bumpy surface
//    objSDF += sin(Noise(pos*1.3)*20.)*.1; // ripply surface
//    objSDF = max(objSDF,(Noise(pos*3.5)-.65)*10.); // random holes/dents
//    objSDF *= exp2(-8.*smoothstep(.3,.7,Noise(pos*.4))); // soften the edge of the object in random places

    ScatterData obj = ScatterData( 1., vec3(1), vec3(0), vec3(.4,.19,.13), .0 ); // brown

    return
        Mix(Mix(Mix(
            air,
            cloud,
            smoothstep( 1., -1., cloudSDF/.1 ) ),
            obj,
            smoothstep( 1., -1., objSDF/.01 ) ),
            ground,
            smoothstep( 1., -1., groundSDF/.01 )
        );
}

const float tau = 6.283185;

vec3 SphereMap( vec2 uv )
{
    // uv is in the range [0,1)
    // map this range onto a unit sphere, with a uniform distribution of points
    
    // use the fact that the surface area of a slice of a sphere is the same
    // as the surface area of a cylinder with the height of the slice and the
    // radius of the sphere
    
    // wrap the 2D space around a cylinder
    float h = uv.y*2.-1.; // height up cylinder
    float a = uv.x*tau; // angle around the circle
    
    // position on the circular slice of the cylinder at this height
    vec2 v = vec2(sin(a),cos(a));
    
    // project onto the corresponding slice of the sphere
    // by multiplying by width of sphere at this height
    v = v * sqrt(1.-h*h);
    
    return vec3(v,h);
}

/* obsfuscated version:
vec3 SphereMap( vec2 uv )
{
    return vec3( sin((uv.xx+vec2(0,.25))*6.283185)*2.*sqrt(uv.y*(1.-uv.y)), uv.y*2.-1. );
}*/

                 
void mainImage( out vec4 fragColour, in vec2 fragCoord )
{
    ivec2 pixelIndex = ivec2(fragCoord);
#if defined(RESOLUTION_REDUCTION) && RESOLUTION_REDUCTION > 1
    fragCoord *= vec2(RESOLUTION_REDUCTION);
    if ( fragCoord.x > iResolution.x || fragCoord.y > iResolution.y )
    {
        fragColour = vec4(.5,.5,.5,1);
        return;
    }
#endif
    
    vec2 mouse = iMouse.xy/iResolution.xy;
    
    // slightly ugly hack: remap the range of mouse movements to give better camera control without re-adjusting all the magic numbers below.
    mouse.y = pow(mouse.y,.5)*.6+.1;
    mouse.x = mouse.x*1.3;
    
    if ( iMouse.x < 1. && iMouse.y < 1. )
        mouse = vec2(.845,.608);
    
    vec2 camAngle = (mouse-.5)*6.283185*vec2(1.,-.4999);

#ifdef ANIMATE
    camAngle.x+=iTime*.05;
#endif
    
    float mouseH = .608 - mouse.y; // make high camera positions frame the whole torus
    
    vec3 camTarget = vec3(-1.5,-1.,0) + vec3(5.5,2.5,-9)*1.6*mouseH;
    float camDistance = 10.;
    float camZoom = 1.1;

	camDistance *= exp2(3.*mouseH); // move camera in/out
    
    vec3 camPos = camDistance*vec3(-vec2(sin(camAngle.x),cos(camAngle.x))*cos(camAngle.y),sin(camAngle.y)).xzy;
    vec3 camK = normalize( camTarget-camPos );
    vec3 camI = normalize(cross(vec3(0,1,0),camK));
    vec3 camJ = cross(camK,camI);
    

    const int maxPasses = 100;
    
    int sampleCountMul = sampleCountMultiplier;
#if defined(RESOLUTION_REDUCTION) && RESOLUTION_REDUCTION > 1
    sampleCountMul *= (RESOLUTION_REDUCTION*RESOLUTION_REDUCTION);
    sampleCountMul = (sampleCountMul*7)/8; // not sure why but without this res reduction always slows it down
#endif        

    int numPasses = max(1,sampleCountMul*(320*180)/int(iResolution.x*iResolution.y));

    fragColour = vec4(0);
    for ( int pass=0; pass < maxPasses; pass++ )
    {
        float stepLength = minStepLength;

        if ( pass >= numPasses ) break;

        SeedRand( iFrame*numPasses+pass, fragCoord );

        vec2 jitter = vec2(rand2())-.5;
        vec3 ray = normalize( vec3( (fragCoord+jitter-iResolution.xy*.5)/iResolution.y, camZoom ) );

        ray = ray.x*camI + ray.y*camJ + ray.z*camK;

        // First, march through space, allowing the ray to be deflected randomly by scatter
        vec3 pos = camPos;
        pos += ray * rand() * stepLength; // randomize initial step to hide aliasing errors (doesn't fix them, but hides them really well)
        float lastH = stepLength;
        vec3 lastTint = SampleMedia(pos).tint;
        vec3 tint = vec3(1);
        vec3 emission = vec3(0);
		bool lightRay = false;
	    int bounceCount = 0;
        float t = 0.;
        for ( int i=0; i < 150; i++ )
        {
            //if ( max(max(tint.r,tint.g),tint.b) <= .01 ) break; // early out when rays have almost no effect - this doesn't seem to improve performance
            
            // step through media [step size modified by probability]
            ScatterData scatter = SampleMedia(pos);

            float h = stepLength*(1. + .9*(rand()*2.-1.)); // adjust steps randomly to hide aliasing errors

            // experimenting with variable step size
            // at the moment it just increases with distance, so rays can travel further but become less accurate
			// I could do this adaptively, but that's more complicated
			stepLength *= 1.01;

            // accumulate average tint
            tint *= pow(mix(scatter.tint,lastTint,.5),vec3(lastH));

            float pointH = mix(lastH,h,.5); // length of step represented by this scatter sample        

            // accumulate emission with current tint applied        
            emission += tint*(scatter.emission * pointH);  // pretty sure emission should be multiplied not pow'd, so it's additive not exponential

            if ( pow(1.-scatter.scatter, pointH) < rand() )// [modified by average of last/next step size]
            {
                if ( rand() < directLightProportion ) // proportion of rays which become direct light rays
                {
                	// direct light
                    // apply the scatter tint and point the ray at the light

                    // correct brightness by proportion of rays not scattered this way
                    tint /= directLightProportion;
	                tint *= scatter.scatterTint;

                    // apply a curve for eccentricity
                    // this uses the derivative of the curve used for the random scatter
                    // we want to say "how much light is scattered in this direction" rather than "what direction should this light be scattered in"
                    float cos0 = dot(ray,lightDirection);
                    float ae = abs(scatter.eccentricity);
                    
                    float se = (scatter.eccentricity<0.)?-1.:1.; // sign(eccentricity) but without 0.0
					//float cos1 = (pow(cos0*se*.5+.5,1.-ae)*2.-1.)*se;
					// dcos1/dcos0 (computed by wolframalpha.con)
                    float dcos1dcos0 = (1. - ae)*pow( max(.00000001,0.5 - se*0.5*cos0), -ae );

                    // hack to reduce speckly artefacts caused by lighting amplified by multiple bounces
                    // these speckles are technically correct, but they occur as a result of highly unlikely combinations of bounces
                    // so it will take a very long time for them to average out
					if ( bounceCount > 0 ) dcos1dcos0 = clamp(dcos1dcos0,0.,10.);
                    
                    tint *= dcos1dcos0;

                    // break out of this loop so we can do a separate shadow-tracing loop which doesn't scatter
		            ray = lightDirection;
                    lightRay = true;
                    break;
                }
                else
                {
                    vec3 newRay = SphereMap( vec2(rand2()) );

                    // eccentricity - push & scale the sphere along the view ray to bias rays in same/opposite direction
                    // amount of push such that at -1 or 1 the near side of the spheroid hits 0 and the far side hits infinity
                    float cos0 = dot(newRay,ray);

                    // Apply a curve to the distribution of rays.
                    // This isn't ideal, it tends to create a sharp bright spot around the light rather than a softer blob
                    // but it has the advantage that it reduces to 1-dimension which makes it easier to compute the derivative, 
                    // which is needed for direct light.
                    // We can do this in 1D because a slice through the surface of a sphere has the same area for a given
                    // thickness of slice, regardless of where the slice is positioned. (napkin ring problem)
                    float ae = 1.-abs(scatter.eccentricity);
                    float se = (scatter.eccentricity<0.)?-1.:1.;
                    float cos1 = (pow(cos0*se*.5+.5,ae*ae)*2.-1.)*se;
                    newRay = normalize(newRay - cos0*ray);
                    newRay = ray*cos1 + newRay*sqrt(1.-cos1*cos1);
                    ray = newRay;

                    // correct brightness by proportion of rays not scattered this way
                    // to conserve energy (this seems to have a bug, as the image changes significantly when I change directLightProportion)
                    tint /= 1.-directLightProportion;

                    // break energy conservation to prevent speckles caused by rare multiply scattered rays
                    // technically they are correct, but they're so rare the speckles they cause are unlikely
                    // to ever be corrected.
                    // reduce this amount for faster convergence but less radiosity
					tint = clamp(tint,0.,5.);
                    
                    tint *= scatter.scatterTint;
                }
                
                bounceCount++;
            }

            pos += ray*h;
            t += h;
            lastH = h;
            lastTint = scatter.tint;
        }
                
        
        if ( lightRay )
        {
            // haven't balanced this for variable step size, so use a const step
			const float shadowStepLength = minStepLength*1.;
            
            vec3 lastAbsorption;
            float shadowT = 0.;
            for ( int i=0; i < int(shadowDrawDistance/shadowStepLength); i++ )
            {
                // step through media [step size modified by probability]
                ScatterData scatter = SampleMedia(pos);

                float h = shadowStepLength; // todo: port the random stuff here too, and change the loop the same way
                
                // accumulate average tint
               	// don't scatter, just count the proportion of scattered rays as a darkening tint
                vec3 absorption = scatter.tint*(1.-scatter.scatter);
                if ( i > 0 )
                {
                	tint *= pow(mix(absorption,lastAbsorption,.5),vec3(lastH));
                }

                pos += ray*h;
                shadowT += h;
                lastH = h;
                lastAbsorption = absorption;
            }
            
            emission += lightColour*tint;
        }
        fragColour.rgb += emission;

        fragColour.a += 1.;
    }
    
#if defined(RESOLUTION_REDUCTION) && RESOLUTION_REDUCTION > 1
    // precompute checkerboard of negative/positive values
    // required by SampleTextureCatmullRom4Samples
    fragColour = (pixelIndex.x&1)==(pixelIndex.y&1) ? fragColour : -fragColour;
#endif
    
    if ( iFrame > 0 && iMouse.z <= 0. )
    {
        fragColour += texelFetch(iChannel0,pixelIndex,0)
#ifdef ANIMATE
            *.97
#endif
            ;
    }
}

// Image (image) — Day at the Lake by nimitz
// https://www.shadertoy.com/view/wl3czN

// Day at the Lake by nimitz, 2020 (twitter: @stormoid)
// https://www.shadertoy.com/view/wl3czN
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License
// Contact the author for other licensing options

/*
    Originally a shader that was meant to show off a new rain algorithm, which will now get it's
    own shader at some point in the future.
    
    Was also supposed to be a full 24h day, but the addition of the moon and stars would have made
    the compilation times a bit too high for my taste (based on current average hardware capacities).
    

  Technical details:

    Cyclic noise:
        An evolution/generalization of things like what I call "triangle noise" and that I've
        used in multiple shaders before and more recently combinations of periodic circular 
        functions (sine, cosine, etc).
        The basic idea goes like this:
            -Deform the coordinate system uisng a continuous (C0 is enough) periodic/cyclic function
            -Generate an octave of noise using combinations of cyclic funtions
            -Shape the generated octave with modulation functions (abs, pow, smoothstep, etc)
            -Scale the deformation/offset/amplitude parameters for the next octave
            -Scale and rotate (and offset if needed) the coordinate system before adding the next octave
        
        This shader demonstrates the versatility of the algorithm and some of the types of natural shapes
        it can generate. Of note is how easily analityc derivatives can be computed and how easily the
        deformation step can be modified to create more complex natural patterns (like erosion, advection,
        circulation, etc)


    Clouds:
        Shaped with cyclic noise and using analytic derivative of said noise for both internal 
        reshaping and for shading. 
        Colored by sampling the atmosphere colors (at increased depths to mimic scattering of
        light rays that are further away from the observer).
        Drawn by excluding part of the volume from the render (on a smooth field like cyclic noisE)
        to improve convergence speed. 
        
    Terrain:
        Shaped with cyclic noise and a pre-deformation step for increased large-scale divesity. Evaluated
        at lowed detail level for water reflections.
        Improved my method for multi-scale curvature mapping for terrain illumination by performing
        single-axis (variable axis based on scale) laplacian-like (divergence of gradient) numerical
        evaluations. The idea is that small scale curvature visuals can be computed along the normal
        of the terrain and as the scale increase the axis is moved towards the up/down axis to
        better evaluate the large-scale depth of the terrain. This allows for both curvature, ao and
        global illumination like results in a single function call of 9 terrain fetches, as opposed to
        17 fetches (using tetrahedral curvature evaluations as per: https://www.shadertoy.com/view/Xts3WM)
        
    
    Water:
        Computing dynamically-spaced 3-tap averaged numerical derivative of a cyclic noise
        function to disturb the water surface normal. With ggx distributed screenspace reflections
        sampled on a blurred buffer to improve smoothness and reduce sample count.
        
        I tested using analitic derivative to improve performance but even when deriving from a
        simplified cyclic function, the sensitivity of the analytic method did not result in
        usable patterns. Perhaps some more investigation could lead to usable results.

*/

float marchSimp(in vec3 ro, in vec3 rd)
{
	float precis = 0.01;
    float h=precis*2.0;
    float d = 0.;
    for( int i=0; i<14; i++ )
    {
        if( abs(h)<precis || d>FAR ) break;
        d += h;
	    float res = mapSimp(ro+rd*d)*2.;
        h = res;
    }
    
	return d;
}

float radicalInverse_VdC(uint bits) 
{
     bits = (bits << 16u) | (bits >> 16u);
     bits = ((bits & 0x55555555u) << 1u) | ((bits & 0xAAAAAAAAu) >> 1u);
     bits = ((bits & 0x33333333u) << 2u) | ((bits & 0xCCCCCCCCu) >> 2u);
     bits = ((bits & 0x0F0F0F0Fu) << 4u) | ((bits & 0xF0F0F0F0u) >> 4u);
     bits = ((bits & 0x00FF00FFu) << 8u) | ((bits & 0xFF00FF00u) >> 8u);
     return float(bits) * 2.3283064365386963e-10;
 }

 vec2 Hammersley(uint i, uint N) 
 {
     return vec2(float(i)/float(N), radicalInverse_VdC(i));
 }

void basis(in vec3 n, out vec3 f, out vec3 r)
{
    float sgn = sign(n.z);
    float a = 1./(1. + sgn*n.z);
    float b = -n.x*n.y*a;
    f = vec3(1. - n.x*n.x*a, b, -n.x);
    r = vec3(b, 1. - n.y*n.y*a , -n.y);
}

vec3 importanceSampleGGX(vec2 xi, float a, vec3 n, float mnl)
{
	float phi = 6.2831853*xi.x;
	float cosTh = sqrt((1.0 - xi.y)/(1.0 + (a*a - 1.0)*xi.y));		
	float sinTh = sqrt(1.0 - cosTh*cosTh);
    vec3 v = vec3(sinTh * cos(phi), sinTh * sin(phi), cosTh);
    vec3 tx, ty;
    basis(n, ty, tx);
	return (tx*v.x + ty*v.y + n*v.z);
}

float waterMap(vec2 p)
{
    p *= 7.7;
    return waterDsp(p, iTime)*3.;
}

//7-taps version (3 blend, combined diff)
//from my older shader: https://www.shadertoy.com/view/4sfSzf
vec3 water_normal (vec2 p, float h, float dst)
{
    const float wd = 0.5;
    
    float wx = fwidth(p.x)*wd;
    float wy = fwidth(p.y)*wd;
    
    float t0 =  waterMap(p);
    float tu =  waterMap(p + vec2(0., wy));
    float td =  waterMap(p - vec2(0., wy));
    float tl =  waterMap(p - vec2(wx, 0));
    float tr =  waterMap(p + vec2(wx, 0));
    float tdr = waterMap(p + vec2(wx, wy));
    float tul = waterMap(p - vec2(wx, wy));
    
    vec2 t1 = vec2( t0 - tl, tul - tl );
    vec2 t2 = vec2( tr - t0, tu - t0 );
	
    vec2 rz = (t1 + t2)*0.5;
    t1 = vec2( tdr - td, t0 - td );
    rz = mix(rz, (t1 + t2)*0.5, 0.5);

    h *= pow(dst, 2.);
    return normalize( vec3(rz.x, h*9., rz.y ) );
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    ttime = iTime;
    vec2 q = fragCoord.xy / iResolution.xy;
    vec2 p = q - 0.5;
	p.x*=iResolution.x/iResolution.y;
	vec2 mo = iMouse.xy / iResolution.xy-.5;
    mo = (mo==vec2(-.5))?mo=vec2(0.12,0.15):mo;
	mo.x *= iResolution.x/iResolution.y;
    mo*=3.14;
	mo.y = clamp(mo.y*0.6-.5,-4. ,.15 );
    
    vec3 rd, ro;
    mat3 invCam = getRay(p, mo, ro, rd, iTime);

    vec4 bufA = texture(iChannel0, q);
    vec3 col = bufA.rgb;
    vec3 pl = intcPlane(ro, rd, 1.8);
    
    if (pl.x < bufA.w)
    {
        vec3 nor = vec3(0,1,0);
        nor = water_normal(pl.yz*4.3, 0.75, pl.x);
        
        //compute fresnel (schlick)
        float R0 = 0.020367; //air to water
    	float nv = max(dot(-rd, nor), 0.0 );
    	float fr = R0 + (1.0 - R0) * pow( 1.0 - nv, 5.0 );
        
        vec3 attCol = mix(col*0.2, vec3(0.05,0.09,0.3)*dot(col,vec3(2.)), 0.5);
        vec3 pos = ro + rd*pl.x;
        
        vec3 totCol = vec3(0.);
        float totWeight = 0.;
        
        vec2 asp = vec2(iResolution.y/iResolution.x,1.0);
		const uint SAMPLES = 23u;

        for (uint i = 0u; i<SAMPLES; i++)
        {
            vec2 xi = Hammersley(i, SAMPLES)*0.8;
            float mnl = clamp(dot(nor, -rd),0.,1.);
            
            vec3 h = importanceSampleGGX(xi, 0.055, nor, mnl);
            vec3 l = reflect(rd, h);
            
            float nl = max(dot(nor, l), .0);
            
            if (nl > 0.)
            {
                float rz2 = marchSimp(pos + l*0.05, l);
                    
                vec3 epos = (vec3((rz2*l + pos) - ro))*invCam;
                vec2 npos = -fov*epos.xy/epos.z;
                vec2 spos = 0.5 + 1.*npos*asp;
                vec4 rfTx = texture(iChannel1, spos);

                totCol += rfTx.rgb*nl; 
                totWeight += nl;
            }
        }
        
        totCol /= totWeight;
        col = mix(attCol, totCol*0.7, clamp(fr,0.0, 0.85));
    }
    
    float exposure = 2.1;
    col = 1.0 - exp(-col * exposure);
    
    col = pow(clamp(col,0.,1.), vec3(0.416667))*1.055 - 0.055;
    col.rgb *= pow( 32.0*q.x*q.y*(1.0-q.x)*(1.0-q.y), 0.1)*0.35 + 0.65; //Vign

    fragColor = vec4(col, 1.0);
}
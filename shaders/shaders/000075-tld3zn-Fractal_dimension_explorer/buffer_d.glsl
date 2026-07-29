// Buffer D (buffer) — Fractal dimension explorer by michael0884
// https://www.shadertoy.com/view/tld3zn

/// PATH MARCHING

const float PHI = 0.5*(sqrt(5.) + 1.); 
const float PHI2 = 0.5*(sqrt(5.) - 1.); 

vec2 fibonacci_lattice(int i, int n)
{
    return vec2((float(i)+0.5)/float(n), mod(float(i)/PHI, 1.)); 
}

vec2 fcircle(int i, int n)
{
    vec2 xy = fibonacci_lattice(i, n);
    vec2 pt = vec2(2.*PI*xy.y, pow(xy.x, PHI2));
    return pt.y*vec2(cos(pt.x), sin(pt.x));
}

#define Nsamp 512
#define aperture 0.02
#define focal_plane 0.6

void getRay(out vec3 ro, out vec3 rd, vec2 pos, ivec2 p)
{
    vec2 angles = texelFetch(iChannel3,  ivec2(ANGLE_INDX,0), 0).xy;
 	mat3 camera = getCamera(angles);
    int kk = int(iMouse.z);
  	//dither position on the aperture
    vec4 blue = texture(iChannel2, vec2(p)/1024. + PI*iTime);
    int I = int(blue.x * float(Nsamp));
    
    pos += (blue.yz - 0.5)/iResolution.x;
    vec2 delta = 2.*aperture*fcircle(I, Nsamp);
    vec3 ro0 = vec3(delta.x, 0., delta.y);
    vec3 rd0 = focal_plane*vec3(FOV*pos.x, 1, FOV*pos.y) - ro0;
    
    ro = texelFetch(iChannel3,  ivec2(POS_INDX,0), 0).xyz + transpose(camera)*ro0;
    rd = normalize(transpose(camera)*rd0);
}

vec4 light_sphere;
vec4 light( in vec3 pos )
{
    vec4 e = vec4(0.0005,-0.0005, 0.25, -0.25);
    return   (e.zwwz*light_map( pos + e.xyy , iTime) + 
  			  e.wwzz*light_map( pos + e.yyx , iTime) + 
			  e.wzwz*light_map( pos + e.yxy , iTime) + 
              e.zzzz*light_map( pos + e.xxx , iTime) )/vec4(e.xxx, 1.);
}


vec3 light_distr(vec3 p)
{
    return vec3(1,1,1) * (4.*step(-light_sphere.w, -length(p - light_sphere.xyz)));
}

vec3 sky(vec3 ray)
{
    return 0.2*(cos(0.001*iTime)+1.)*vec3(1.15,1.1,1.0)*sqrt(1.-0.95*ray.z*ray.z)*(tanh(10.*ray.z)+1.);
}


vec3 path_march(vec3 p, vec3 ray, float t, float i, float angle, float seed)
{
    vec3 fincol = vec3(1.), finill = vec3(0.);
    vec4 res = vec4(0.);
    for(float b = 0.; (b < MAX_BOUNCE); b++)
    {
        if(b < 1.)
        {
            float h = map(p).w;
            if (h < angle*t || t > MAX_DIST)
            {
                 res = vec4(p, h);
            }
        }
       
        if(res.xyz != p)
        {
            //march next ray
       		res = trace(p, ray, t, i, angle);
        }
         
        if(t > MAX_DIST || (i >= MAX_STEPS && res.w > 5.*angle*t))
        {
            finill += sky(ray)*fincol;
            break;
        }
        
        /// Surface interaction
        vec3 norm = calcNormal(res.xyz, res.w);    
        //discontinuity correction
        p = res.xyz - (res.w - 2.*angle*t)*norm;
        
        vec3 refl = reflect(ray, norm);
        
        float refl_prob = hash(seed*SQRT2);
       
        //random diffusion, random distr already samples cos(theta) closely
        if(refl_prob < reflection)
        {
            vec3 rand = clamp(pow(1.-reflection,4.)*randn(seed*SQRT3),-1.,1.);
        	ray = normalize(refl + rand);
        }
        else
        {
            vec3 rand = random_sphere(seed*SQRT3);
            ray = normalize(norm + rand);
        }
      

        //color and illuminaition
        vec4 colp = map(p);
        fincol = fincol*clamp(colp.xyz,0.,1.);
        
        //add fractal glow
        finill += 5.*light_distr(p)*fincol;
        finill += vec3(1.)*exp(-300.*clamp(pow(abs(length(colp.xyz-vec3(0.2,0.3+0.01*cos(iTime),0.75+0.01*sin(iTime)))),2.),0.,1.))*fincol;
        finill += vec3(0.6)*exp(-300.*clamp(pow(abs(length(colp.xyz-vec3(0.3,0.8,0.3))),2.),0.,1.))*fincol;
        
        angle *= 1.15;
    }
    
    return finill;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
     // Normalized centered pixel coordinates 
    vec2 pos = (fragCoord - iResolution.xy*0.5)/max(iResolution.x,iResolution.y);
    
    vec2 angles = texelFetch(iChannel3,  ivec2(ANGLE_INDX,0), 0).xy;
    
    vec3 rand = 2.*blue3(2.*fragCoord, iTime) - 1.;
 	vec3 ray = getRay(angles, pos+0.5*rand.xy/iResolution.x);
    vec4 p = texelFetch(iChannel3,  ivec2(POS_INDX,0), 0);
    
    light_sphere = texelFetch(iChannel3,  ivec2(LIGHT_INDX,0), 0);
    light_sphere.xyz += 0.*light_sphere.w*vec3(sin(iTime), cos(iTime), 0.);
    
    fragColor = vec4(0.);
	float iter = 0., td = 0.;
    vec4 res = trace(p.xyz, ray, td, iter, LOD);
    iter*=.5; //give the bounces only half of the marches to improve speed
    for(float i = 0.; i <SPP; i++)
    {
        fragColor.xyz += path_march(res.xyz, ray, td, iter, LOD*2., rand.x+hash(iTime+i));
    }
    
    fragColor.xyz /= SPP;

    vec4 posit = texelFetch(iChannel3,  ivec2(POS_INDX,0), 0);
   
    vec4 prev = texture(iChannel0, fragCoord/iResolution.xy);

    float avg = (posit.w>1.)?AVG*tanh(posit.w*0.5*sqrt(1.-AVG)):0.2;
    fragColor.xyz = avg*prev.xyz + (1.- avg)*fragColor.xyz;
    fragColor.w = posit.w;
    if(iFrame < 1)
    {
        fragColor = vec4(0.);
    }
}
// Buffer A (buffer) — Mandelcloud explorer by michael0884
// https://www.shadertoy.com/view/wttyDX

float min_step;

//light positions
vec3 lpos1, lpos2;

//blue noise
vec4 rand4blue()
{
    return texelFetch(iChannel1, shift2(), 0);
}

vec4 mandelbulb_fog(vec3 p, float K) {
    vec3 w = p;
    float m = dot(w, w);
    vec3 orbitTrap = vec3(1.);
	float dz = 1.0;
    for(int i = 0; i < 5; i++){
        if(m > 1.2) break;
        float m2 = m*m;
        float m4 = m2*m2;
		dz = 8.0*sqrt(m4*m2*m)*dz + 1.0;
        float x = w.x; float x2 = x*x; float x4 = x2*x2;
        float y = w.y; float y2 = y*y; float y4 = y2*y2;
        float z = w.z; float z2 = z*z; float z4 = z2*z2;
        float k3 = x2 + z2;
        float k2 = inversesqrt( k3*k3*k3*k3*k3*k3*k3 );
        float k1 = x4 + y4 + z4 - 6.0*y2*z2 - 6.0*x2*y2 + 2.0*z2*x2;
        float k4 = x2 - y2 + z2;
        w.x = p.x +  64.0*x*y*z*(x2-z2)*k4*(x4-6.0*x2*z2+z4)*k1*k2;
        w.y = p.y + -16.0*y2*k3*k4*k4 + k1*k1;
        w.z = p.z +  -8.0*y*k4*(x4*x4 - 28.0*x4*x2*z2 + 70.0*x4*z4 - 28.0*x2*z2*z4 + z4*z4)*k1*k2;
        m = dot(w, w);
        orbitTrap = min(abs(w)*1.2, orbitTrap);
    }
    float sdf = 0.25*log(m)*sqrt(m)/dz;
    vec3 col = max(1. - orbitTrap, 0.0)*smoothstep(K,0.0,sdf);
    return vec4(DENSITY*col, sdf);
}

vec4 box_fog(vec3 p, vec3 b, float k)
{
    vec3 refl = normalize(vec3(0.4,0.6,0.9));
    float sc = 1.0;
    for(int i = 0; i < 6; i++)
    {
        refl.xy = rot(1.6)*refl.xy;
        p -= 2.*max(dot(refl, p), 0.)*refl;
        refl.yz = rot(2.1)*refl.yz;
        p += 0.015*sin(10.*dot(refl,p) + sin(p.x*p.y));
    }
    float sdf = sdBox(p,b)/sc;
    return vec4(DENSITY*(vec3(.3, .6, .9)* + (0.5 + 0.5*sin(40.*vec3(0.392,0.580,1.000)*p.x)))*smoothstep(k,-k,sdf), sdf);
}

vec4 density(vec3 p){
    vec4 box = mandelbulb_fog(p, sharpness);//box_fog(p, vec3(0.7,0.3,0.2), sharpness); 
    float shells = min(MAX_DIST + 5.0 - length(p), min(distance(p, lpos1),distance(p, lpos2))); //light source and background
    return vec4(box.xyz + vec3(0.141,0.439,1.000)*AMBIENT_FOG, min(box.w, shells));
}


vec4 choose_light(vec3 p, float r)
{
    float t1 = distance(lpos1, p);
    float t2 = distance(lpos2, p);
    float prob = t1*t1/(t1*t1+t2*t2);
    return (r > prob)?vec4(lpos1, 1.-prob):vec4(lpos2, prob);
}

//trace a multibounce light path to the lights
vec3 trace(vec3 ro, vec3 id, float dither)
{
    //cumulative opacity
    vec3 k = vec3(1.0);
    //cumulative scattering
    vec3 sk = vec3(1.0);
  
    float step_size;
    float td = 0.;
    
    vec3 pdf = vec3(1.0);
   
    //light importance sampling   
    vec4 l = choose_light(ro, rand());
  
    //light choise pdf
    pdf*=l.w;
    vec3 rd = id;
    float dist = MAX_DIST;
    
    int i = 0;
    
    dist = distance(l.xyz, ro)+2e-2;
   
    pdf*= 4.*PI*dist*dist;
     dist = MAX_DIST;
    bool shadowray = false;
    for(; i < TRACE_STEPS; i++)
    { 
        vec4 rho = density(ro);
        step_size = (1.0 - DITHER*dither)*max(rho.w,max(max(min_step,SCALING*td),5e-5*length(rho)));
        
        vec3 absorption = exp(-step_size*rho.xyz*ABSORPSION); 
        
        //accumulate
        k *= absorption; 
        
        vec4 r = rand4();
        td += step_size;
        //do a scatter
        if(!shadowray)
        {
            //total scattering probability 
            sk *= exp(-step_size*rho.xyz*SCATTERING);
            
            //shoot shadow ray 
            if(r.w < SHADOW_SCATTER_P) 
            {
                pdf*=SHADOW_SCATTER_P/0.5;
                shadowray = true;
                vec3 prd = rd;
                dist = distance(l.xyz, ro)+2e-2;
                rd = (l.xyz - ro)/dist;
                
                //anisotropic scattering 
                pdf/= HenyeyGreenstein(ANISOTROPY, dot(prd, rd));
                pdf/= (1. - sk);
            }
            else //else do normal scattering
            {
               
                rd = normalize(mix(udir(r.yz),rd,exp(-step_size*rho.xyz*SCATTER_K*SCATTERING*(1. - ANISOTROPY))));
            }
            td = 0.;
        }

        
        if(length(k) < 0.07 || distance(ro, vec3(0)) > 2.0 || td > dist) break;
        //step ray
        ro += rd*step_size;

       
    }
    return smoothstep(ERROR_THRESHOLD, 0.0, dist - td)*LIGHT_BRIGHTNESS*k*smoothstep(0.068,0.07,length(k))/pdf;
}

//use previous camera matrix and camera position to reproject a point onto previous frame
vec3 reproject(mat3 pcam_mat, vec3 pcam_pos, vec2 iRes, vec3 p)
{
    float td = distance(pcam_pos, p);
    vec3 dir = (p - pcam_pos)/td;
    vec3 screen = inverse(pcam_mat)*dir;
    return vec3(screen.yz*iRes.y/(FOV*screen.x) + 0.5*iRes.xy, td);
}

void mainImage( out vec4 c, in vec2 p )
{
    rng_initialize(p, iFrame);
    min_step = 1.25/DENSITY;
    vec2 uv = (p - 0.5*iResolution.xy)/iResolution.y;
    
    vec2 angles = GET_DATA(CAM_ANGLE_).xy;
    mat3 cam = get_cam(angles.x, angles.y);
 
    vec3 campos = GET_DATA(CAM_POS_).xyz; 
    vec3 ro = campos;
    vec3 rd = normalize(cam*vec3(1.0, FOV*uv));
    
    lpos1 = GET_DATA(LIGHT_POS1_).xyz;
    lpos2 = GET_DATA(LIGHT_POS2_).xyz;
    
    vec4 brand = rand4blue();
    
    float dither = brand.x;
    //cumulative opacity
    vec3 k = vec3(1.0);
    
    //accumulated incoming light to the camera
    vec3 col = vec3(0.); 
    int L = 0;
    
    //main camera ray
    float step_size;
    
    float td = 0.;
    vec4 maxl_p = vec4(0.);
    
    int i = 0;
    for(; i < MAX_STEPS; i++)
    {
        vec4 rho = density(ro);

        step_size = (1.0 - DITHER*dither)*max(rho.w,max(max(min_step,SCALING*td),2e-5*length(rho)));
        
        vec2 ldis = vec2(distance(lpos1, ro),distance(lpos2, ro));
        
        vec3 absorption = exp(-(ABSORPSION + SCATTERING)*step_size*rho.xyz); 
       
        col += vec3(LIGHT_BRIGHTNESS/10.)*k.xyz*(step(ldis.x,LIGHT_RAD) + step(ldis.y,LIGHT_RAD));
        
        if((rho.z > 0.005 && i%4 == 0) || (rho.z > 4.0))
        {
            vec3 incoming = trace(ro, rd, brand.z);
            float pdf = (rho.z > 0.005 && rho.z < 4.0)?0.25:1.0;
            col += k.xyz*incoming/pdf; 
        }
       
        //accumulate
        k *= absorption;
        
        td += step_size;
        ro += step_size*rd;
    
         
        if(length(k) < 0.2 || distance(ro, vec3(0)) > MAX_DIST) break;
    }
    
    //col = vec3(distance(maxl_p.xyz, campos)/3.);
    
    vec2 pcam_angles = GET_DATA(PCAM_ANGLE_).xy;
    mat3 pcam = get_cam(pcam_angles.x, pcam_angles.y);
    vec3 pcam_pos = GET_DATA(PCAM_POS_).xyz;
    
    vec2 prev_iResolution = GET_DATA(PRESOLUTION_).xy;
    
    //reproject
    vec3 reprj = reproject(pcam, pcam_pos, prev_iResolution, ro);
    vec2 puv = reprj.xy/iResolution.xy;
    vec2 dpuv = abs(puv - vec2(0.5));
    
    float accumulation = TAA //max accumulation
                         *mix(1.0, 0.85, smoothstep(0.0, 0.01, distance(campos,pcam_pos))) //reduce accumulation if moving 
                         *step(dpuv.x, 0.5)*step(dpuv.y, 0.5); //outside prev frame
    //sample prev point
    // vec4 prev = texture(iChannel0, puv);
    vec4 prev = texture_Bicubic(iChannel0, puv);
    
    prev *= accumulation; //remove samples
   
    
    c = vec4(col,1.0) + prev;
    
    if(iFrame < 2) c = vec4(col,1.0);
}
// Buffer B (buffer) — Volumetric laser tracer by michael0884
// https://www.shadertoy.com/view/NtXSR4

#define SPP 3


vec3 opU( vec3 d, float iResult, float mat ) {
	return (iResult < d.y) ? vec3(d.x, iResult, mat) : d;
}
    
vec3 worldhit( in vec3 ro, in vec3 rd, in vec2 dist, out vec3 normal ) {
    vec3 tmp0, tmp1, d = vec3(dist, 0.);
    
    d = opU(d, iPlane      (ro,                  rd, d.xy, normal, vec3(0,1,0), 0.), 1.);
    
    d = opU(d, iBox        (ro-vec3( 0,.252, 1), rd, d.xy, normal, vec3(.25)), 2.);
    d = opU(d, iSphere     (ro-vec3( 0,.252, 0), rd, d.xy, normal, .25), 3.);
    d = opU(d, iSphere     (ro-vec3( 0.6,.252, 0.2), rd, d.xy, normal, .25), 3.);
    d = opU(d, iSphere     (ro-vec3( -0.5,.252, 0.1), rd, d.xy, normal, .25), 3.);

    return d;
}


#define LASER_PATH 14
int cpath;
vec4 path[LASER_PATH];

const float crad = 0.02;
float pathhit(in vec3 ro, in vec3 rd, float td) {
    float acc = 0.0;
    
    for(int i = 0; i <= cpath; i++)
    {
        if(path[i].w > 0.0 && path[i+1].w > 0.0)
        {
            float ct = iCylinder(ro,rd,path[i].xyz,path[i+1].xyz,crad);
            if(ct < td && ct > 0.0)
            {
                vec3 a = (path[i].xyz - path[i+1].xyz);
                vec3 b = rd;
                vec3 c = (path[i+1].xyz - ro);
                vec3 cro = cross(a,b);
                float d = abs(dot(c,cro)/length(cross(a,b)));
                acc += 15.0*smoothstep(1.0, 0., pow(d/crad,0.2));
            }
        }
    }
    return acc;
}

bool getRay(vec2 uv, out vec3 ro, out vec3 rd)
{
    mat3 cam = getCam(get(CamA));
    vec2 apert_cent = -0.*uv; 
    vec2 ap = aperture();  
    if(!(distance(ap, apert_cent) < 1.0)) return false;  
    float apd = length(ap);  
    vec3 daperture = ap.x*cam[0] + ap.y*cam[1]; 
    ro = get(CamP).xyz + aperture_size*daperture;
    float focus =2.5 + 0.8*pow(apd,5.0);
    rd = normalize(focus*(cam*vec3(FOV*uv, 1.0)) - aperture_size*daperture);
    return true;
}

void processhit(in vec3 res, inout vec3 ro, inout vec3 rd, inout float inside,
                in float ior, in vec3 normal, inout vec3 col, inout vec3 att)
{
    ro += rd*res.y;
           
    if(res.z <= 2.0)
    {

        rd = reflect(rd, normalize(nrand3(0.25, normal))); 
    }
    else
    {
        inside = -inside;
        vec3 matn = normalize(nrand3(0.005, -normal*inside));
        vec3 newrd = refract(rd, matn, pow(1.0 + 0.5*ior, inside));
        if(length(newrd) > 0.5) //not total internal reflection
        {
            rd = newrd;
        }
        else
        {
            rd =reflect(rd, matn); 
        } 
    }
}

vec4 render(vec2 fragCoord)
{
    fragCoord += nrand2(0.5, vec2(0.));
    vec2 uv = (fragCoord - 0.5*iResolution.xy)/iResolution.y;
   
    vec3 ro, rd, normal;
  
 
    //trace laser
    
    // get a random refractive index different per pixel
    float ior = (rand()-0.5) + 0.03;
    //ior = (fract(gl_FragCoord.y/3.)-.5);
    float id=1./(1.0 + ior);
    // compute index of refraction associated color 
    vec3 scol = spectral_zucconi(300.0*(ior + 0.5) + 400.0);
   
    
    ro =  nrand3(0.0, vec3( -2,.252, 0));
    rd =  normalize(vec3(0.3,0.,-0.028));
    float inside = 1.0;
    
    vec3 col = vec3(0.0);
    vec3 att = vec3(1.0);
    
    for(cpath = 0; cpath < LASER_PATH - 1; cpath++)
    {
        path[cpath] = vec4(ro, att.x);
        vec3 res = worldhit( ro, rd, vec2(.001, MAX_DIST), normal );
        if (res.z > 0.) 
        {
            processhit(res,ro,rd,inside,id,normal,col,att);
        }
        else 
        {
            ro += rd*res.y;
            break;
        }
    }
    path[cpath+1] = vec4(ro, att.x);
    
    if(!getRay(uv, ro, rd)) return vec4(0,0,0,1);
    
    col = vec3(0.0);
    att = vec3(1.0);
    inside = 1.0;
    
    for(int i = 0; i < 5; i++)
    {
        vec3 res = worldhit( ro, rd, vec2(.00001, MAX_DIST), normal );
        
        vec3 acc = scol*pathhit(ro,rd,res.y);
        col += att*acc;
        
        if (res.z > 0.) 
        {
            processhit(res,ro,rd,inside,ior,normal,col,att);
        }
        else 
        {
            col += 0.*att*texture(iChannel1, rd).xyz;
            break;
        }
    }
   

    return vec4(col, 1.0);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    rng_initialize(fragCoord, iFrame);
    //prev 
    if(get(CamP).w == 0.0)
        fragColor = texture(iChannel0, fragCoord/iResolution.xy);
    else
        fragColor = texture(iChannel0, fragCoord/iResolution.xy)*0.1;
   
   for(int i = 0; i < SPP; i++)
       fragColor += render(fragCoord);
}
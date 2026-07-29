// Buffer B (buffer) — Marble Marcher: SE by michael0884
// https://www.shadertoy.com/view/3lKyDR

//blue noise
vec4 rand4blue()
{
    return texelFetch(iChannel1, shift2(), 0);
}

#define LIGHT_ANGLE 0.2

float shadowtrace(vec3 ro, vec3 rd, float maxd)
{
    float td = 0.;
    //noise to remove shadow artifacts
    float phase = rand() - 0.5;
    float angle = 1e10;
    for(int i = 0; i < 40; i++)
    {
        float de = scene(ro).x*(1. + 0.2*phase);
        if(de < max(CAM_ANGLE*td,MIN_DIST)) {angle*= 0.0; break;}
        if(td > maxd) break;
        td += de; ro += rd*de;
        angle = min(angle, de/td); 
    }
    return smoothstep(0.02, LIGHT_ANGLE, angle);
}

float ambitrace(vec3 ro, vec3 rd)
{
    float td = 0.;
    float angle = 1e10;
    for(int i = 0; i < 7; i++)
    {
        float de = scene(ro).x;
        if(de < max(CAM_ANGLE*td,MIN_DIST)) {angle*= 0.0; break;}
        td += de; ro += rd*de;
        angle = min(angle, de/td); 
    }
    return smoothstep(0.0, 0.3, angle);
}


//rendering samplers
void basis(in vec3 n, out vec3 f, out vec3 r)
{
    if(n.z < -0.999999) {
        f = vec3(0 , -1, 0);
        r = vec3(-1, 0, 0);
    } else {
    	float a = 1./(1. + n.z);
    	float b = -n.x*n.y*a;
    	f = vec3(1. - n.x*n.x*a, b, -n.x);
    	r = vec3(b, 1. - n.y*n.y*a , -n.y);
    }
}

mat3 mat3FromNormal(in vec3 n)
{
    vec3 x; vec3 y;
    basis(n, x, y);
    return mat3(x,y,n);
}

vec3 ggxSample(vec3 wi, float alphax, float alphay, vec2 xi)
{   
    //stretch view
    vec3 v = normalize(vec3(wi.x * alphax, wi.y * alphay, wi.z));

    //orthonormal basis
    vec3 t1 = (v.z < 0.9999) ? normalize(cross(v, vec3(0.0, 0.0, 1.0))) : vec3(1.0, 0.0, 0.0);
    vec3 t2 = cross(t1, v);

    //sample point with polar coordinates
    float a = 1.0 / (1.0 + v.z);
    float r = sqrt(xi.x);
    float phi = (xi.y < a) ? xi.y / a*PI : PI + (xi.y - a) / (1.0 - a) * PI;
    float p1 = r*cos(phi);
    float p2 = r*sin(phi)*((xi.y < a) ? 1.0 : v.z);

    //compute normal
    vec3 n = p1*t1 + p2*t2 + v*sqrt(1.0 - p1*p1 - p2*p2);

    //unstretch
    return normalize(vec3(n.x * alphax, n.y * alphay, n.z));
}

vec2 sampleDisk(vec2 xi)
{
	float theta = TWO_PI * xi.x;
	float r = sqrt(xi.y);
	return vec2(cos(theta), sin(theta)) * r;
}

vec3 cosineHemisphere(vec2 xi)
{
    vec2 disk = sampleDisk(xi);
	return vec3(disk.x, disk.y, sqrt(max(0.0, 1.0 - dot(disk, disk))));
}

float pow2(float x)
{
    return x*x;
}

vec3 fresnel(vec3 V, vec3 H, vec3 F0)
{
    return F0 + (1. - F0)*pow(1.0 - max(dot(V,H), 0.0), 5.0);
}

float NDF_ggx(vec3 m, vec3 n, float alpha)
{
    float alpha2 = alpha*alpha; 
    return alpha2/(PI*pow2( pow2(max(dot(n,m), 0.)) * (alpha2 - 1.0) + 1.0 ));
}

float G_ggx(float NdotV, float alpha)
{
    float alpha2 = alpha*alpha;
    return 2.0*NdotV/(NdotV + sqrt( mix(NdotV*NdotV, 1.0, alpha2) ));
}

vec3 simple_shading(inout vec4 ro, vec3 rd)
{
    vec3 col = vec3(0.);
    bool hit = trace(ro, rd);
    if(hit)
    {
        material mat = getMaterial(ro); 
        
        vec3 V = - rd;
        vec3 N = mat.normal;
        vec3 R = reflect(rd, N);
        vec3 L = iLightDir;
        vec3 H = normalize(V + L);
        
        vec3 kS = fresnel(V, N, mat.F0);
        vec3 kD = 1.0 - kS;
        
        float NdotL = max(dot(N, L), 2e-3);
        float NdotV = max(dot(N, V), 2e-3);
        
        #ifdef SHADOWS
            float shadow = 0.;
            if(NdotL > 0.0) shadow = shadowtrace(ro.xyz, iLightDir, MAX_DIST);
        #else
            float shadow = 0.0;
        #endif
        
        float selfshadow = G_ggx(NdotL,mat.roughness)*G_ggx(NdotV,mat.roughness)/max(4.0*NdotL*NdotV,1e-3);
        vec3 specular = selfshadow*kS*NDF_ggx(H, N, mat.roughness);  
        
        vec3 direct = shadow * (kD * mat.color / PI + specular) * DIRECT_BRIGHTNESS * NdotL;
        
        //AO
        #ifdef AMBIENT_OCCLUSION
            vec4 rnd = rand4blue();
            float ambientshadow = ambitrace(ro.xyz + mat.normal*ro.w*0.001, 
                                            normalize(mat.normal + udir(rnd.xy)));
        #else
            float ambientshadow = 0.5 + 0.5*NdotL;
        #endif
        
        
        vec3 reflection = AMBIENT*kS*texture(iChannel3, R).xyz;
        vec3 ambient = 0.25*mat.color*(ambientshadow + reflection);
        
        col = ambient + direct;
    }
    else
    {
        col = AMBIENT*texture(iChannel3, rd).xyz;
    }
    return col;
}

vec3 pathtrace(inout vec4 ro0, vec3 rd)
{
    vec3 col = vec3(0.);
    vec3 absorption = vec3(1.);
    vec4 ro = ro0; 
    for(int i = 0; i < BOUNCES; i++)
    {
        float id = 0.;
        bool hit = trace(ro, rd);
        if(i == 0) {ro0 = ro;}
        if(hit)
        {
            vec4 rnd = rand4blue();
            
            material mat = getMaterial(ro);
            
            vec3 V = - rd;
            vec3 N = mat.normal*mat.inside;
            vec3 R = reflect(rd, N);
            vec3 L = iLightDir;
            vec3 H = normalize(V + L);
            
            vec3 kS = fresnel(V, N, mat.F0);
            
            //specular probability
            float pS = (kS.x + kS.y + kS.z)/3.0;
            
            mat3 basis = mat3FromNormal(N);
            mat3 inv = transpose(basis);
            vec3 V_local = inv*V;
           
            vec3 incoming = mat.emission; 
            
            #ifdef DIRECT_LIGHT
                float NdotL = max(dot(N, L), 2e-3);
                float NdotV = max(dot(N, V), 2e-3);
                
                float selfshadowL = G_ggx(NdotL,mat.roughness)*G_ggx(NdotV,mat.roughness);
                
                vec3 specular = selfshadowL*kS*NDF_ggx(H, N, mat.roughness)/max(4.0*NdotL*NdotV,1e-3);  

                vec3 direct = (mat.color*(1. - kS)*float(!mat.transparent) / PI + specular) * NdotL;
                
                float shadow = 0.;
                if(length(direct) > 0.04) shadow = shadowtrace(ro.xyz, iLightDir, MAX_DIST);

                incoming += DIRECT_BRIGHTNESS * shadow * direct;
            #endif
            
            
            //sample microfacet normal
            vec3 M = ggxSample(V_local, mat.roughness, mat.roughness, rnd.xy);
            
            rd = reflect(-V_local, M); //new reflected ray direction

            float selfshadowR = G_ggx(rd.z,mat.roughness)*G_ggx(V_local.z,mat.roughness);
            
            if(rnd.z < pS*selfshadowR) //specular bounce
            {
                absorption *= kS/pS;
            }
            else //diffuse/refraction bounce
            { 
                absorption *= mat.color;
                if(mat.transparent) //refraction
                {
                    float F0avg = (mat.F0.x + mat.F0.y + mat.F0.z)/3.0; 
                    float IOR = (1.0 + sqrt(F0avg))/(1.0 - sqrt(F0avg));
                   
                    if(length(rd) != 0.) //not total internal reflection
                    {
                        rd = refract(-V_local, M, pow(IOR,-mat.inside));     
                        //reflect point inside
                        ro.xyz = ro.xyz + 2.0*(mat.cpoint - ro.xyz);
                    }
                }
                else //diffuse
                { 
                    rd = cosineHemisphere(rnd.xy);  
                }  
            }
            
            col += absorption*incoming;
            
            if((absorption.x + absorption.y + absorption.z) < 0.03) break; 
          
            
           
            rd = basis*rd; //return ray direction into world space
        }
        else
        {
            #ifdef DIRECT_LIGHT
            float ambient = AMBIENT*0.5;
            #else
            float ambient = AMBIENT;
            #endif
            col += absorption*(ambient*(texture(iChannel3, rd).xyz + 0.*pow(max(dot(iLightDir, rd),0.),20.)) );
            break;
        }
        
    }
    return col;
}

void getRay(in vec2 p, inout vec3 ro, inout vec3 rd, float aperture)
{
    vec2 uv = (p  - 0.5*iResolution.xy)/iResolution.y;
    vec4 r = rand4blue();
    vec2 ap = aperture*vec2(sin(TWO_PI*r.x), cos(TWO_PI*r.x))*sqrt(r.y);
    vec3 daperture = ap.x*cam[1] + ap.y*cam[2];
    ro = campos + daperture;
    #ifdef AUTO_FOCUS
        float focus = radius*iMarblePos.w;
    #else
        float focus = FOCAL_PLANE;
    #endif
    
    rd = normalize(focus*(cam*vec3(1, FOV*uv)) - daperture);
}

void mainImage( out vec4 c, in vec2 p )
{
    rng_initialize(p, iFrame);
    load_scene(iChannel2, iTime, iResolution.xy);
    
    vec4 col = vec4(0.);
    
    vec4 ro = vec4(0.); vec3 rd; 
    vec2 jitter = halton(iFrame%16) - 0.5; 
    getRay(p + jitter, ro.xyz, rd, APERTURE);
    
    #ifdef PATH_TRACING
        col += vec4(pathtrace(ro, rd), 1.0);
    #else
        col += vec4(simple_shading(ro, rd), 1.0);
    #endif

    c.xyz = tanh(EXPOSURE*pow(col.xyz/col.w, vec3(0.75)));
    c.w = distance(ro.xyz, campos);
}
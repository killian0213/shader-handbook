// Image (image) — 3D Water Box Particles only by michael0884
// https://www.shadertoy.com/view/dstfRf

// Fork of "3D Water Box" by michael0884. https://shadertoy.com/view/dscfRf
// 2023-10-16 20:53:25

#define SHADOWS 
//#define REFRACTION

#define RADIUS 0.3
#define NORMAL_SMOOTHNESS 0.0

#define FOV 2.5
mat3 getCamera(vec2 angles)
{
   mat3 theta_rot = mat3(1,   0,              0,
                          0,  cos(angles.y),  -sin(angles.y),
                          0,  sin(angles.y),  cos(angles.y)); 
        
   mat3 phi_rot = mat3(cos(angles.x),   sin(angles.x), 0.,
        		       -sin(angles.x),   cos(angles.x), 0.,
        		        0.,              0.,            1.); 
        
   return theta_rot*phi_rot;
}

vec3 getRay(vec2 angles, vec2 pos)
{
    mat3 camera = getCamera(angles);
    return normalize(transpose(camera)*vec3(FOV*pos.x, 1., FOV*pos.y));
}


#define MAX_DIST 1e10

struct Ray 
{
    vec3 ro;
    vec3 rd;
    float td;
    vec3 normal;
    vec3 color;
};

void iSphere(inout Ray ray, vec4 sphere, vec3 color)
{
    vec3 ro = ray.ro - sphere.xyz;
    float b = dot(ro, ray.rd);
    float c = dot(ro, ro) - sphere.w*sphere.w;
    float h = b*b - c;
    if (h > 0.) 
    {
	    h = sqrt(h);
        float d1 = -b-h;
        float d2 = -b+h;
        if (d1 >= 0.0 && d1 <= ray.td) {
            ray.normal = normalize(ro + ray.rd*d1);
            ray.color = color;
            ray.td = d1;
        } else if (d2 >= 0.0 && d2 <= ray.td) { 
            ray.normal = normalize(ro + ray.rd*d2); 
            ray.color = color;
            ray.td = d2;
        }
    }
}

vec2 iBox( in vec3 ro, in vec3 rd, in vec3 boxSize ) 
{
    vec3 m = sign(rd)/max(abs(rd), 1e-8);
    vec3 n = m*ro;
    vec3 k = abs(m)*boxSize;
	
    vec3 t1 = -n - k;
    vec3 t2 = -n + k;

	float tN = max( max( t1.x, t1.y ), t1.z );
	float tF = min( min( t2.x, t2.y ), t2.z );
	
    if (tN > tF || tF <= 0.) {
        return vec2(MAX_DIST);
    } else {
        return vec2(tN, tF);
    }
}


void TraceCell(inout Ray ray, vec3 p)
{
    //load the particles 
    vec4 packed = LOAD3D(ch0, p);
    Particle p0, p1;
    unpackParticles(packed, p, p0, p1);

    if(p0.mass > 0u) iSphere(ray, vec4(p0.pos, RADIUS*1.5), vec3(1.000,1.000,1.000));
    if(p1.mass > 0u) iSphere(ray, vec4(p1.pos, RADIUS*1.5), vec3(1.000,1.000,1.000));
}

void TraceCells(inout Ray ray, vec3 p)
{
    vec3 p0 = floor(p);
    vec4 rho = voxel(ch1, p);
    if(rho.z < 1e-3) return;
    range(i, -1, 1) range(j, -1, 1) range(k, -1, 1)
    {
        //load the particles 
        vec3 p1 = p0 + vec3(i, j, k);
        TraceCell(ray, p1);
    }
}


float Density(vec3 p)
{
    return trilinear(ch1, p).z;
}

float Shadow(vec3 p)
{
    float optical_density = trilinear(ch2, p).x;
    return exp(-optical_density)+0.05;
}

vec4 calcNormal(vec3 p, float dx) {
	const vec3 k = vec3(1,-1,0);
	return   (k.xyyx*Density(p + k.xyy*dx) +
			 k.yyxx*Density(p + k.yyx*dx) +
			 k.yxyx*Density(p + k.yxy*dx) +
			 k.xxxx*Density(p + k.xxx*dx))/vec4(4.*dx,4.*dx,4.*dx,4.);
}

float TraceDensity(vec3 ro, vec3 rd)
{
    float dens = 0.0;
    float td = 0.0;
    for(int i = 0; i < 100; i++)
    {
        vec3 p = ro + rd * td;
        if(any(lessThan(p, vec3(1.0))) || any(greaterThan(p, size3d - 1.0))) return dens;
        float d = Density(p);
        dens += d * 2.0;
        td += 2.0;
    }
    return dens;
}


#define ISO_VALUE 0.5
float ParticleDensity(vec3 p)
{
    vec3 p0 = floor(p);
    float rho = voxel(ch1, p).z;
    //if(rho < 0.001) return rho;
    //rho = 0.0;
    ////if larger then compute accurate density from particles
    //range(i, -1, 1) range(j, -1, 1) range(k, -1, 1)
    //{
    //    //load the particles 
    //    vec3 p1 = p0 + vec3(i, j, k);
    //    //load the particles
    //    vec4 packed = LOAD3D(ch0, p1);
    //    Particle p0_, p1_;
    //    unpackParticles(packed, p1, p0_, p1_);
    //    if(p0_.mass > 0u) rho += float(p0_.mass)*GD(length(p0_.pos - p), RADIUS);
    //    if(p1_.mass > 0u) rho += float(p1_.mass)*GD(length(p1_.pos - p), RADIUS);
    //}

    return rho;
}

vec3 ParticleGradient(vec3 p)
{
    vec3 p0 = floor(p);
    vec3 grad = vec3(0.0);

    range(i, -1, 1) range(j, -1, 1) range(k, -1, 1)
    {
        //load the particles 
        vec3 p1 = p0 + vec3(i, j, k);

        //load the particles
        vec4 packed = LOAD3D(ch0, p1);
        Particle p0_, p1_;

        unpackParticles(packed, p1, p0_, p1_);

        if(p0_.mass > 0u) grad += float(p0_.mass)*GGRAD(p0_.pos - p, RADIUS);
        if(p1_.mass > 0u) grad += float(p1_.mass)*GGRAD(p1_.pos - p, RADIUS);
    }

    return grad;
}


float DE(vec3 p)
{
    return ISO_VALUE - ParticleDensity(p);
}

float TraceIsoSurface(Ray ray, float mint, float inside)
{
    const int step_count = 300;
    float td = mint;
    for(int i = 0; i < step_count; i++)
    {
        vec3 p = ray.ro + ray.rd * td;
        if(!all(lessThanEqual(p, size3d)) || !all(greaterThanEqual(p, vec3(0.))))
        {
            return ray.td;
        }
        float d = inside*4.0*DE(p);
        if(d < 0.0)
        {
            return td;
        }
        td += d;
    }
    return td;
}

vec3 Background(vec3 rd)
{
    return 2.0*pow(texture(iChannel3,  rd.yzx).xyz, vec3(2.0));
}


void mainImage( out vec4 col, in vec2 fragCoord )
{    
    InitGrid(iResolution.xy);
    
    vec2 uv = (fragCoord - 0.5*R)/max(R.x, R.y);

    vec2 angles = vec2(2.*PI, PI)*(iMouse.xy/iResolution.xy - 0.5);

    if(iMouse.z <= 0.)
    {
        angles = vec2(0.04, -0.5);
    }
    vec3 rd = getRay(angles, uv);
    vec3 center_rd = getRay(angles, vec2(0.));
 
    float d = sqrt(dot(vec3(size3d), vec3(size3d)))*0.5;
    vec3 ro = vec3(size3d)*vec3(0.5, 0.5, 0.5) - center_rd*d;
    
    

    vec2 tdBox = iBox(ro - vec3(size3d)*0.5, rd, 0.5*vec3(size3d));
    col.xyz =Background(rd);
    if(tdBox.x < MAX_DIST)
    {
        float td = max(tdBox.x+0.5, 0.0);
        Ray ray;
        ray.ro = ro;
        ray.rd = rd;
        ray.td = tdBox.y;
        int i = 0;
        for(; i < 200; i++)
        {
            vec3 p = ro + rd*td;
            TraceCells(ray, p);
            td += 2.5;
            if(td > tdBox.y-1.0)
            {
                break;
            }
            if(ray.td < tdBox.y-1.0)
            {
                break;
            }
        }
        
        //col.xyz = vec3(i)/200.0;
        //return;
        
        //float liq_td = TraceIsoSurface(ray, td);
        //ray.td = min(liq_td, ray.td);
        
        if(ray.td < tdBox.y)
        {
            vec3 p0 = ray.ro + ray.rd*ray.td;
            vec3 normal = normalize(-ParticleGradient(p0));
            vec3 normal1 = normalize(calcNormal(p0, 0.5).xyz);
            normal = -normalize(mix(normal, normal1, NORMAL_SMOOTHNESS));
            vec3 albedo = vec3(0.039,0.153,1.000);
            float LdotN = 0.5*dot(normal, light_dir)+0.5;
            #ifdef SHADOWS
                float shadow_d = TraceDensity(p0+light_dir*1.0, light_dir);
                float shadow = exp(-shadow_d) + 0.3*exp(-0.1*shadow_d);
            #else
                float shadow = 1.0;
            #endif
            vec3 refl_d = reflect(ray.rd, normal);
            vec3 refl = Background(refl_d);
            float K = 1. - pow(max(dot(normal,refl_d),0.), 2.);
            K = mix(0.0, K, 0.1);
            
            #ifdef REFRACTION
            vec3 refr_d = refract(ray.rd, normal, 1.0/1.33);
            
            float liquid_density = TraceDensity(p0, refr_d);
            
            vec3 liquid_color = exp(-0.5*liquid_density*vec3(0.953,0.353,0.247));
            vec3 refr_color = Background(refr_d) * liquid_color;
            col.xyz = 2.5*shadow*refr_color*(1.0 - K) + 0.*ray.color + 0.75*shadow*refl*K;
            #else
            col.xyz = 2.5*shadow*albedo*LdotN*(1.0 - K) + 0.*ray.color + 0.75*shadow*refl*K;
            #endif
        }
        
        //col.xyz = 0.01*vec3(1,1,1)*TraceDensity(ro + rd*max(tdBox.x+0.001,0.0), rd);
    }
    
    col.xyz = 1.0 - exp(-2.5*pow(col.xyz,vec3(1.0/1.4)));
}
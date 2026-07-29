// Image (image) — Anisotropic surface reconstruct by michael0884
// https://www.shadertoy.com/view/csdfD2

// Fork of "3D Water Box" by michael0884. https://shadertoy.com/view/dscfRf
// 2023-10-16 20:53:25

#define SHADOWS 
#define REFRACT
#define REFLECT

const vec3 light = 2.0*vec3(1.0,1.0,1.0);
const vec3 absorb = vec3(0.584,0.843,0.953);
const vec3 albedo = vec3(0.000,0.000,0.000);
const vec3 F0 = vec3(0.05);
const float roughness = 0.065;

#define RADIUS 0.8
#define NORMAL_SMOOTHNESS 0.72

#define FOV 3.
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

vec3 qrot(vec3 x, vec4 q)
{
    return x + 2.0 * cross(cross(x, q.xyz) + q.w * x, q.xyz);
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

vec4 conj_q(vec4 q)
{
    return vec4(-q.xyz, q.w);
}

void iEllipsoid(inout Ray ray, in vec3 p, in vec3 r, in vec4 q)
{
    vec3 ro = ray.ro - p;
    ro = qrot(ro, conj_q(q));
    vec3 rd = qrot(ray.rd, conj_q(q));
    
    vec3 r2 = r*r;
    float a = dot( rd, rd/r2 );
	float b = dot( ro, rd/r2 );
	float c = dot( ro, ro/r2 );
	float h = b*b - a*(c-1.0);
	if( h<0.0 ) return;
    
	float t = (-b - sqrt( h ))/a;
    if(t >= ray.td || t < 0.0) return;
    ray.normal = qrot(normalize( (ro + t * rd)/r2 ), q);
    ray.color = vec3(1.);
    ray.td = t;
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
    
    if(p0.mass + p1.mass == 0u) return;
    Covariance c0, c1;
    unpackCovariance(LOAD3D(ch2, p), c0, c1);

    if(p0.mass > 0u) iEllipsoid(ray, p0.pos, RADIUS*c0.s, c0.q);
    if(p1.mass > 0u) iEllipsoid(ray, p1.pos, RADIUS*c1.s, c1.q);
}

void TraceCells(inout Ray ray, vec3 p)
{
    vec3 p0 = floor(p);
    vec4 rho = voxel(ch1, p);
    if(rho.z < 1e-3) return;
    range(i, -1, 1) range(j, -1, 1) range(k, -1, 1)
    {
        vec3 p1 = p0 + vec3(i, j, k);
        TraceCell(ray, p1);
    }
}


float Density(vec3 p)
{
    return trilinear(ch1, p).z;
}


vec4 calcNormal(vec3 p, float dx) {
	const vec3 k = vec3(1,-1,0);
	return   (k.xyyx*Density(p + k.xyy*dx) +
			 k.yyxx*Density(p + k.yyx*dx) +
			 k.yxyx*Density(p + k.yxy*dx) +
			 k.xxxx*Density(p + k.xxx*dx))/vec4(4.*dx,4.*dx,4.*dx,4.);
}



#define ISO_VALUE 0.2
#define STEP_SIZE 1.0
#define IOR 1.333

vec3 refractFull(vec3 rd, vec3 n, float ior)
{
    vec3 refr = refract(rd, n, ior);
    if(length(refr) < 0.5)
    {
        return reflect(rd, n);
    }
    else return refr;
}

float TraceDensity(vec3 ro, vec3 rd)
{
    float dens = 0.0;
    float td = 0.0;
    for(int i = 0; i < 40; i++)
    {
        vec3 p = ro + rd * td;
        if(any(lessThan(p, vec3(1.0))) || any(greaterThan(p, size3d - 1.0))) return dens;
        float d = Density(p);
        dens += d * 4.0;
        td += 4.0;
    }
    return dens;
}


float TraceDensityMedium(vec3 ro, inout vec3 rd)
{
    float dens = 0.0;
    float td = 0.0;
    float de = 0.0;
    float pde = 0.0;
    bool bounced = false;
    for(int i = 0; i < 60; i++)
    {
        vec3 p = ro + rd * td;
        if(any(lessThan(p, vec3(0.0))) || any(greaterThan(p, size3d))) return dens;
        float ldens = Density(p);
        float d = smoothstep(ISO_VALUE*0.9, ISO_VALUE*1.1, ldens);
        dens += d * STEP_SIZE;
        pde = de;
        de = ldens - ISO_VALUE;
        if(pde > 0.0 && de < 0.0 && !bounced && td > 4.0)
        {
            float std = td - STEP_SIZE*(de/(de-pde));
            vec3 sp = ro + rd*std;
            vec3 normal = normalize(calcNormal(sp, 0.5).xyz);
            ro = sp;
            rd = refractFull(rd, normal, IOR);
            td = 0.0;
            bounced = true;
        }
        td += STEP_SIZE;
    }
    return dens;
}


vec3 Background(vec3 rd)
{
    vec3 col = texture(iChannel3,  rd.yzx).xyz;
    return 2.0*pow(col, vec3(2.0)) + col*exp(15.0*(length(col) - 1.45));
}

vec3 fresnel(vec3 V, vec3 H, vec3 F0)
{
    return F0 + (1. - F0)*pow(1.0 - max(dot(V,H), 0.0), 5.0);
}

float NDF_ggx(vec3 m, vec3 n, float alpha)
{
    float alpha2 = alpha*alpha; 
    return alpha2/(PI*sqr( sqr(max(dot(n,m), 0.)) * (alpha2 - 1.0) + 1.0 ));
}

float G_ggx(float NdotV, float alpha)
{
    float alpha2 = alpha*alpha;
    return 2.0*NdotV/(NdotV + sqrt( mix(NdotV*NdotV, 1.0, alpha2) ));
}


vec3 PBR(vec3 P, vec3 V, vec3 L, vec3 Lcol, vec3 N, vec3 color, vec3 absorb)
{
    vec3 Re = reflect(-V, N);
    vec3 Rf = refract(-V, N, 1.0/1.33);
    vec3 H = normalize(V + L);
    float NdotL = max(dot(N, L), 2e-3);
    float NdotV = max(dot(N, V), 2e-3);

    #ifdef SHADOWS
    float dens = TraceDensity(P+L*2.0, L);
    float shadow = exp(-dens);
    float ambient = 0.4*exp(-0.3*dens) + 0.1*exp(-0.1*dens) + 0.05*exp(-0.05*dens);
    #else
    float shadow = 1.0;
    float ambient = 0.3;
    #endif
    
    #ifdef REFRACT
    float refrDens = TraceDensityMedium(P, Rf);
    vec3 refraction = Background(Rf) * exp(-0.5*refrDens*(1.0 - absorb));
    #else
    vec3 refraction = vec3(0.0);
    #endif
    
    #ifdef REFLECT
    float reflDens = TraceDensity(P, Re);
    vec3 reflection = Background(Re) * exp(-0.5*reflDens*(1.0 - absorb));
    #else
    vec3 reflection = (1.0 - roughness)*Background(Re);
    #endif
    
    float selfshadow = G_ggx(NdotL,roughness)*G_ggx(NdotV,roughness)/max(4.0*NdotL*NdotV,1e-3);
    float specular = selfshadow*NDF_ggx(H, N, roughness) * NdotL;
    
    vec3 Lbright = shadow * Lcol;
    
    vec3 refr = Lbright * color * NdotL / PI + refraction;
    vec3 relf = Lbright * specular + reflection;
    vec3 ambi = ambient * color * (0.7*NdotL + 0.3);
    
    vec3 kS = fresnel(V, N, F0);
    vec3 kD = 1.0 - kS;
    return (ambi + refr) * kD + relf * kS;
}


void mainImage( out vec4 col, in vec2 fragCoord )
{    
    InitGrid(iResolution.xy);
    
    vec2 uv = (fragCoord - 0.5*R)/max(R.x, R.y);

    vec2 angles = vec2(2.*PI, PI)*(iMouse.xy/iResolution.xy - 0.5);

    if(iMouse.z <= 0.)
    {
        angles = vec2(0.04 + 0.05*iTime, -0.5);
    }
    vec3 rd = getRay(angles, uv);
    vec3 center_rd = getRay(angles, vec2(0.));
 
    float d = sqrt(dot(vec3(size3d), vec3(size3d)))*0.4;
    vec3 ro = vec3(size3d)*vec3(0.5, 0.5, 0.5) - center_rd*d;

    vec2 tdBox = iBox(ro - vec3(size3d)*0.5, rd, 0.5*vec3(size3d));
    col.xyz = Background(rd);
    if(tdBox.x < MAX_DIST)
    {
        float td = max(tdBox.x+0.5, 0.0);
        Ray ray;
        ray.ro = ro;
        ray.rd = rd;
        ray.td = tdBox.y;
        int i = 0;
        bool stop = false;
        for(; i < 200; i++)
        {
            vec3 p = ro + rd*td;
            TraceCells(ray, p);
            td += 1.5;
            if(td > tdBox.y-1.0)
            {
                break;
            }
            if(stop) break;
            if(ray.td < tdBox.y-1.0)
            {
                stop = true;
            }
        }
        
        if(ray.td < tdBox.y)
        {
            vec3 p0 = ray.ro + ray.rd*ray.td;
            vec3 normal1 = normalize(calcNormal(p0, 0.5).xyz);
            vec3 normal =  -normalize(mix(-ray.normal, normal1, NORMAL_SMOOTHNESS));
            
            col.xyz = PBR(p0, -ray.rd, light_dir, light, normal, albedo, absorb);
        }
    }
    
    col.xyz = 1.0 - exp(-2.5*pow(col.xyz,vec3(1.0/1.3)));
}
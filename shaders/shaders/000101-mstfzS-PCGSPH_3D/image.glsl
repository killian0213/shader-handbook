// Image (image) — PCGSPH 3D by michael0884
// https://www.shadertoy.com/view/mstfzS

//Particle cluster grid smoothed particle hydrodynamics. Now in 3D.
//Compared to 2D this is muuuch trickier, the effective resolution tolerances are much higher.
//So before noone really made a liquid in 3d that looked even remotely "liquid"
//I think this is probably the highest (visual) resolution fluid sim on shadertoy so far.
//Right now I'm just tracing the particles, but I think maybe its possible to do an isosurface render somehow?

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

#define radius 0.75
#define zoom 0.25

void TraceCell(inout Ray ray, vec3 p)
{
    //load the particles 
    vec4 packed = LOAD3D(ch0, p);
    Particle p0, p1;
    unpackParticles(packed, p, p0, p1);

    if(p0.mass > 0u) iSphere(ray, vec4(p0.pos, 0.85), vec3(0.420,0.302,0.996) * length(p0.vel));
    if(p1.mass > 0u) iSphere(ray, vec4(p1.pos, 0.85), vec3(0.420,0.302,0.996) * length(p0.vel));
}

void TraceCells(inout Ray ray, vec3 p)
{
    vec3 p0 = floor(p);
    vec4 rho = LOAD3D(ch1, p);
    if(rho.z < 1e-5) return;
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



void mainImage( out vec4 col, in vec2 fragCoord )
{    
    InitGrid(iResolution.xy);
    
    vec2 uv = (fragCoord - 0.5*R)/max(R.x, R.y);

    vec2 angles = vec2(2.*PI, PI)*(iMouse.xy/iResolution.xy - 0.5);

    if(iMouse.z <= 0.)
    {
        angles = vec2(0.2*iTime, -0.5);
    }
    vec3 rd = getRay(angles, uv);
    vec3 center_rd = getRay(angles, vec2(0.));
 
    float d = sqrt(dot(vec3(size3d), vec3(size3d)))*0.5;
    vec3 ro = vec3(size3d)*vec3(0.5, 0.5, 0.5) - center_rd*d;
    
    

    vec2 tdBox = iBox(ro - vec3(size3d)*0.5, rd, 0.5*vec3(size3d));
    col = texture(iChannel3,  rd.yzx);
    if(tdBox.x < MAX_DIST)
    {
        float td = max(tdBox.x, 0.0);
        float step_size = 2.0;
        const int step_count = 100;
        Ray ray;
        ray.ro = ro;
        ray.rd = rd;
        ray.td = tdBox.y;

        for(int i = 0; i < step_count; i++)
        {
            vec3 p = ro + rd*td;
            TraceCells(ray, p);

            td += step_size;
            if(td > tdBox.y || ray.td < tdBox.y)
            {
                break;
            }
        }
        
        if(ray.td < tdBox.y)
        {
            vec3 p0 = ray.ro + ray.rd*ray.td;
            vec3 normal = normalize(calcNormal(p0, 0.5).xyz);
            normal = -normalize(mix(normal, ray.normal, 0.25));
            vec3 albedo = vec3(0.220,0.349,1.000);
            float LdotN = dot(normal, light_dir);
            float shadow = Shadow(p0);
            vec3 refl_d = reflect(ray.rd, normal);
            vec3 refl = texture(iChannel3,  refl_d.yzx).xyz;
            float K = 1. - pow(max(dot(normal,refl_d),0.), 3.);
            K = mix(0.0, K, 0.75);
            col.xyz = 2.5*shadow*albedo*LdotN*(1.0 - K) + 0.1*ray.color + shadow*refl*K;
        }
    }
}
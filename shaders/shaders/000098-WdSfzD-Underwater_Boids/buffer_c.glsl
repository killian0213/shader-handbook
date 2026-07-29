// Buffer C (buffer) — Underwater Boids by michael0884
// https://www.shadertoy.com/view/WdSfzD

///SHADING

vec3 ray; vec3 cpos; vec2 angles;
mat3 rmat;
vec2 p;
vec3 getRay(vec2 pos)
{
    rmat = getRot(angles);
    vec2 uv = FOV*(pos - R*0.5)/R.x;
    return normalize(rmat[0]*uv.x + rmat[1]*uv.y + rmat[2]);
}


// iq's smooth HSV to RGB conversion 
vec3 hsv2rgb( in vec3 c )
{
    vec3 rgb = clamp( abs(mod(c.x*6.0+vec3(0.0,4.0,2.0),6.0)-3.0)-1.0, 0.0, 1.0 );

	rgb = rgb*rgb*(3.0-2.0*rgb); // cubic smoothing	

	return c.z * mix( vec3(1.0), rgb, c.y);
}

obj getObj(int id)
{
    obj o;
    
    vec4 a = texel(ch0, i2xy(ivec3(id, 0, 0))); 
    o.X = a.xyz; o.Rho = a.w;
    a = texel(ch0, i2xy(ivec3(id, 1, 0))); 
    o.V = a.xyz; o.Pressure = a.w; 
    a = texel(ch0, i2xy(ivec3(id, 2, 0))); 
    o.Color = a.xyz; o.Scale = a.w;
 
    o.id = id;
    return o;
}

float lstr(vec3 p)
{
    return 0.5*(tanh(0.001*p.z + 0.4) + 1.);
}

vec3 projection(vec3 p)
{
    vec3 dp = normalize(p - cpos);
    float zp = FOV*dot(dp, rmat[2]);
    vec2 prj = zp*R.x*vec2(dot(dp, rmat[0]), dot(dp, rmat[1]))/(0.001+zp*zp);
    return vec3(prj + 0.5*R, sign(zp)); 
}

bool inbouds(vec2 p)
{
    return p.x > 0. && p.y > 0. && R.x - p.x > 0. && R.y - p.y > 0.;
}

// this noise, including the 5.58... scrolling constant are from Jorge Jimenez
float InterleavedGradientNoise(vec2 pixel, int frame) 
{
    pixel += (float(frame) * 5.588238f);
    return fract(52.9829189f * fract(0.06711056f*float(pixel.x) + 0.00583715f*float(pixel.y)));  
}

#define light vec3(0,0,1)
#define sm 5.

//ray screen bound intersection
float screen_max( in vec2 ro, in vec2 rd ) 
{   
    vec2 m = 1.0/rd;
    vec2 n = m*ro;
    vec2 t = vec2(max(- n.x, R.x*m.x - n.x),max(- n.y, R.y*m.y - n.y));
	float tN = min(t.x, t.y);
	return tN;
}

float god_ray(float d)
{
    //ligth position in camera plane
    vec3 lp = projection(light*10000.);
    vec2 r = lp.z*normalize(lp.xy - p + vec2(0.001)); 
    float xl = min(screen_max(p, r),distance(lp.xy, p));
    float dx = 1. + (1. + xl*god_ray_step)*InterleavedGradientNoise(p, iFrame);
    float occ = 0.; float esum = 0.001;
    for(float x = 0.; x < xl; x += dx)
    {
        float cd = length(cpos - texel(ch1, ivec2(p + r*x)).yzw);
        occ += mix(1.,(0.5*tanh(0.2*(cd/d - 1.)) + 0.5), exp(-0.5*fog_depth*cd))*dx;
        esum += dx;
    }
    occ /= esum;
    return mix(1., occ*occ, pow(abs(0.5*(ray.z + 1.)),0.5));
}

vec4 water_fog(float d, vec3 dir)
{
    float alpha = 1. - exp(-fog_depth*d);
    float b = (pow(abs(0.5*(dir.z + 1.)),14.) + 
               0.075*pow(abs(0.5*(dir.z + 1.2)),0.3));
	return vec4(b*wcol, alpha);
}

void mainImage( out vec4 fragColor, in vec2 pos )
{
    sN = SN; 
    N = ivec2(R*P/vec2(sN));
    TN = N.x*N.y;
    ivec2 pi = ivec2(floor(pos));
    p = pos;
    //setup camera
    angles = (iMouse.z>0.)?(iMouse.xy/R)*vec2(2.*PI, PI):vec2(0.15*iTime, PI*0.2+0.5*sin(0.15*iTime));
    cpos = -camd*getRay(R*0.5);
    ray = getRay(pos); 
    
    
    vec4 A = texel(ch1, pi);
    int ID = int(A.x); 
    vec3 ip = A.yzw; //intersection point
	obj o = getObj(ID);
    mat pmat = mat(o.Color, vec3(0.), 0.25, 0.3);
    
    vec3 n = normalize(ip - o.X); //normal
    vec3 r = reflect(ray, n);
    float d = min(distance(ip, cpos), 1e6); 
    
    vec3 col = vec3(0.);
    float shadow = god_ray(d);
    vec4 wfog = water_fog(d, ray);
    if(d < 1e6)
    {
        float b = lstr(ip);
        col += b*wcol*BRDF(-ray, light, n, pmat);//light
        col += b*0.3*wcol*BRDF(-ray, n, n, pmat);//ambient
    }
    vec3 ncol = shadow*mix(col, wfog.xyz, wfog.w);
    // Output to screen
 	vec3 pcol = texel(ch2, pi).xyz;
    fragColor = vec4(mix(pcol,ncol,0.9),1.0);
}
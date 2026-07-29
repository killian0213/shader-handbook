// Common (common) — Fractal terrain generator by michael0884
// https://www.shadertoy.com/view/3lcGRX


#define PI 3.14159265
#define SQRT2 1.4142135
#define SQRT3 1.7320508
#define SQRT5 2.2360679
#define FOV 2.5

#define MAX_DIST 500.
#define MIN_DIST 1e-5
#define MAX_MARCHES 512.
#define LIGHT_ANGLE 0.04

//how much does the terrain change in large scale
#define PERLIN_SCALE 2

//coefficients are fine-tuned
//you can get all kinds of weird terrain by carefully setting the coefficients, 
//even forests are possible, but they may look not as realistic as the rock fractals
const int FRACTAL_ITER = 20;
const float iFracScale = 1.6467;
const float iFracAng1 = 2.7315;
const float iFracAng2 = -0.2082;
const vec3 iFracShift = vec3(-8.92, 3.66, 5.49);
const vec3 iFracCol = vec3(0.3, 0.3, -0.2);

float s1 = sin(iFracAng1), c1 = cos(iFracAng1), s2 = sin(iFracAng2), c2 = cos(iFracAng2);

float PBR_METALLIC = 0.0;
float PBR_ROUGHNESS = 0.7;

vec3 BACKGROUND_COLOR = vec3(0.);
vec3 LIGHT_DIRECTION = normalize(vec3(-1.,1.,0.68));
vec3 LIGHT_COLOR = vec3(1., 0.95, 0.8);
bool SHADOWS_ENABLED = true; 

float gamma_material = 0.1;
float gamma_sky = 0.76;
float gamma_camera = 2.2;

float LOD;

float hash(float p)
{
   p = fract(p * .1031);
    p *= p + 33.33;
    p *= p + p;
    return fract(p);
}

vec4 hash41(float p)
{
	vec4 p4 = fract(vec4(p) * vec4(.1031, .1030, .0973, .1099));
    p4 += dot(p4, p4.wzxy+33.33);
    return fract((p4.xxyz+p4.yzzw)*p4.zywx);
    
}

vec4 hash42(vec2 p)
{
	vec4 p4 = fract(vec4(p.xyxy) * vec4(.1031, .1030, .0973, .1099));
    p4 += dot(p4, p4.wzxy+33.33);
    return fract((p4.xxyz+p4.yzzw)*p4.zywx);

}


//normally distributed random numbers
vec3 randn(float p)
{
    vec4 rand = hash41(p);
    vec3 box_muller = sqrt(-2.*log(max(vec3(rand.x,rand.x,rand.z),1e-8)))*vec3(sin(2.*PI*rand.y),cos(2.*PI*rand.y),sin(2.*PI*rand.w));
    return box_muller;
}

//uniformly inside a sphere
vec3 random_sphere(float p)
{
    return normalize(randn(p))*pow(hash(p+85.67),0.333333);
}

vec3 cosdistr(vec3 dir, float seed)
{
    vec3 rand_dir = normalize(randn(seed*SQRT2));
    vec3 norm_dir = normalize(rand_dir - dot(dir,rand_dir)*dir);
    float u = hash(seed);
    return normalize(dir*sqrt(u) + norm_dir*sqrt(1.-u));
}


vec4 perlin_octave(vec2 p)
{
   vec2 pi = floor(p);
   vec2 pf = p - pi;
   vec2 pfc = 0.5 - 0.5*cos(pf*PI);
   vec2 a = vec2(0.,1.);
   
   vec4 a00 = hash42(pi+a.xx);
   vec4 a01 = hash42(pi+a.xy);
   vec4 a10 = hash42(pi+a.yx);
   vec4 a11 = hash42(pi+a.yy);
   
   vec4 i1 = mix(a00, a01, pfc.y);
   vec4 i2 = mix(a10, a11, pfc.y);
   
   return mix(i1, i2, pfc.x);  
}

mat2 rotat = mat2(cos(0.5), -sin(0.5), sin(0.5), cos(0.5));

vec4 perlin4(vec2 p)
{
	float a = 1.;
	vec4 res = vec4(0.);
	for(int i = 0; i < PERLIN_SCALE; i++)
	{
		res += a*(perlin_octave(p)-0.5);
        //inverse perlin
		p *= 0.6*rotat;
		a *= 1.2;
	}
	return res;
}

/////
/////Code from Marble Marcher Community Edition
/////

#define COL col_scene
#define DE de_scene
//##########################################
//   Space folding
//##########################################
void planeFold(inout vec4 z, vec3 n, float d) {
	z.xyz -= 2.0 * min(0.0, dot(z.xyz, n) - d) * n;
}
void sierpinskiFold(inout vec4 z) {
	z.xy -= min(z.x + z.y, 0.0);
	z.xz -= min(z.x + z.z, 0.0);
	z.yz -= min(z.y + z.z, 0.0);
}

// Polynomial smooth minimum by iq
float smoothmin(float a, float b, float k) {
  float h = clamp(0.5 + 0.5*(a-b)/k, 0.0, 1.0);
  return mix(a, b, h) - k*h*(1.0-h);
}

/*void mengerFold(inout vec4 z) {
	float a = smoothmin(z.x - z.y, 0.0, 0.03);
	z.x -= a;
	z.y += a;
	a = smoothmin(z.x - z.z, 0.0, 0.03);
	z.x -= a;
	z.z += a;
	a = smoothmin(z.y - z.z, 0.0, 0.03);
	z.y -= a;
	z.z += a;
}*/

void mengerFold(inout vec4 z) {
	float a = min(z.x - z.y, 0.0);
	z.x -= a;
	z.y += a;
	a = min(z.x - z.z, 0.0);
	z.x -= a;
	z.z += a;
	a = min(z.y - z.z, 0.0);
	z.y -= a;
	z.z += a;
}
void boxFold(inout vec4 z, vec3 r) {
	z.xyz = clamp(z.xyz, -r, r) * 2.0 - z.xyz;
}
void rotX(inout vec4 z, float s, float c) {
	z.yz = vec2(c*z.y + s*z.z, c*z.z - s*z.y);
}
void rotY(inout vec4 z, float s, float c) {
	z.xz = vec2(c*z.x - s*z.z, c*z.z + s*z.x);
}
void rotZ(inout vec4 z, float s, float c) {
	z.xy = vec2(c*z.x + s*z.y, c*z.y - s*z.x);
}
void rotX(inout vec4 z, float a) {
	rotX(z, sin(a), cos(a));
}
void rotY(inout vec4 z, float a) {
	rotY(z, sin(a), cos(a));
}
void rotZ(inout vec4 z, float a) {
	rotZ(z, sin(a), cos(a));
}

//##########################################
//   Primitive DEs
//##########################################
float de_sphere(vec4 p, float r) {
	return (length(p.xyz) - r) / p.w;
}
float de_box(vec4 p, vec3 s) {
	
	vec3 a = abs(p.xyz) - s;
	return (min(max(max(a.x, a.y), a.z), 0.0) + length(max(a, 0.0))) / p.w;
}
float de_tetrahedron(vec4 p, float r) {
	float md = max(max(-p.x - p.y - p.z, p.x + p.y - p.z),
				max(-p.x + p.y + p.z, p.x - p.y + p.z));
	return (md - r) / (p.w * sqrt(3.0));
}
float de_capsule(vec4 p, float h, float r) {
	p.y -= clamp(p.y, -h, h);
	return (length(p.xyz) - r) / p.w;
}

//##########################################
//   Main DEs
//##########################################
float de_fractal(vec4 p)
{
	vec3 p0 = p.xyz;
	p.xz = mod(p.xz + vec2(0.5*p.w), vec2(1.*p.w)) - vec2(0.5*p.w); 
	vec4 perlin1 = perlin4(p0.xz);
	vec3 shift =iFracShift + 0.35*perlin1.xyz;
	for (int i = 0; i < FRACTAL_ITER; ++i) {
		
		p.xyz = abs(p.xyz);
		
		rotZ(p, s1, c1);
		mengerFold(p);
		rotX(p, s2, c2);
		p *= iFracScale*(1.);
		p.xyz += shift;
		
	}
	
	return 0.66*de_box(p, vec3(6.0));
}

vec4 col_fractal(vec4 p) 
{
	vec3 p0 = p.xyz;
	vec3 orbit = vec3(0.0);
	p.xz = mod(p.xz + vec2(0.5*p.w), vec2(1.*p.w)) - vec2(0.5*p.w); 
	vec4 perlin1 = perlin4(p0.xz);
	vec3 shift =iFracShift + 0.35*(perlin1.xyz - 0.5);
	for (int i = 0; i < FRACTAL_ITER; ++i) {
		p.xyz = abs(p.xyz);
		rotZ(p, s1, c1);
		mengerFold(p);
		rotX(p, s2, c2);
		p *= iFracScale*(1.);
		p.xyz += shift;
		orbit = max(orbit, p.xyz*iFracCol);
	}
	return vec4(orbit, de_box(p, vec3(6.0)));
}

float de_scene(vec3 pos) 
{
	vec4 p = vec4(pos,1.f);
	float d = de_fractal(p);
	return d;
}

vec4 col_scene(vec3 pos) 
{
	vec4 p = vec4(pos,1.f);
	vec4 col = col_fractal(p);
	return vec4(min(col.xyz,1.), 0.0);
}

vec4 calcNormal(vec3 p, float dx) {
	const vec3 k = vec3(1,-1,0);
	return   (k.xyyx*DE(p + k.xyy*dx) +
			 k.yyxx*DE(p + k.yyx*dx) +
			 k.yxyx*DE(p + k.yxy*dx) +
			 k.xxxx*DE(p + k.xxx*dx))/vec4(4.*dx,4.*dx,4.*dx,4.);
}

void scene_material(vec3 pos, inout vec4 color, inout vec2 pbr)
{
	//DE_count = DE_count+1;
	vec4 p = vec4(pos,1.f);
	
	color = vec4(0.99,0.99,0.99,1.);
	
	pbr = vec2(PBR_METALLIC, PBR_ROUGHNESS);
	float reflection = 0.;

	color = vec4(min(color.xyz,1.), reflection);
}


#define overrelax 1.35

void ray_march(inout vec4 p, inout vec4 ray, inout vec4 var, float angle, float max_d)
{
    float prev_h = 0., td = 0.;
    float omega = overrelax;
    float candidate_td = 1.;
    float candidate_error = 1e8;
    for(; ((ray.w+td) < max_d) && (var.x < MAX_MARCHES);   var.x+= 1.)
    {
        p.w = DE(p.xyz + td*ray.xyz);
        
        if(prev_h*omega>max(p.w,0.)+max(prev_h,0.)) //if overtepped
        {
            td += (1.-omega)*prev_h; // step back to the safe distance
            prev_h = 0.;
            omega = (omega - 1.)*0.6 + 1.; //make the overstepping smaller
        }
        else
        {
			if(p.w < 0.)
			{
				candidate_error = 0.;
				candidate_td = td;
				break;
			}
			
            if(p.w/td < candidate_error)
            {
                candidate_error = p.w/td;
                candidate_td = td; 
				
                if(p.w < (ray.w+td)*angle) //if closer to the surface than the cone radius
                {
                    break;
                }
            }
            
            td += p.w*omega; //continue marching
            
            prev_h = p.w;        
        }
    }
    
    ray.w += candidate_td;
	p.xyz = p.xyz + candidate_td*ray.xyz;
	p.w = candidate_error*candidate_td;
}


void ray_march(inout vec4 p, inout vec4 ray, inout vec4 var, float angle)
{
	ray_march(p, ray, var, angle, MAX_DIST);
}



#define shadow_steps 256
float shadow_march(vec4 pos, vec4 dir, float distance2light, float light_angle)
{
	float light_visibility = 1.;
	float ph = 1e5;
	float dDEdt = 0.;
	pos.w = DE(pos.xyz);
	int i = 0;
	for (; i < shadow_steps; i++) {
	
		dir.w += pos.w;
		pos.xyz += pos.w*dir.xyz;
		pos.w = DE(pos.xyz);
		
		float y = pos.w*pos.w/(2.0*ph);
        float d = (pos.w+ph)*0.5*(1.-dDEdt);
		float angle = d/(max(MIN_DIST,dir.w-y)*light_angle);
		
        light_visibility = min(light_visibility, angle);
		
		//minimizing banding even further
		dDEdt = dDEdt*0.75 + 0.25*(pos.w-ph)/ph;
		
		ph = pos.w;
		
		if(dir.w >= distance2light)
		{
			break;
		}
		
		if(dir.w > MAX_DIST || pos.w < max(LOD*dir.w, MIN_DIST))
		{
			return 0.;
		}
	}
	
	if(i >= shadow_steps)
	{
		light_visibility=0.;
	}
	//return light_visibility; //bad
	light_visibility = clamp(2.*light_visibility - 1.,-1.,1.);
	return  0.5 + (light_visibility*sqrt(1.-light_visibility*light_visibility) + asin(light_visibility))/3.14159265; //looks better and is more physically accurate(for a circular light source)
}


#define AMBIENT_MARCHES 3
#define AMBIENT_COLOR 2*vec4(1,1,1,1)


///PBR functions 
vec3 fresnelSchlick(float cosTheta, vec3 F0)
{
    return F0 + (1.0 - F0) * pow(1.0 - cosTheta, 5.0);
}  

float DistributionGGX(vec3 N, vec3 H, float roughness)
{
    float a      = roughness*roughness;
    float a2     = a*a;
    float NdotH  = max(dot(N, H), 0.0);
    float NdotH2 = NdotH*NdotH;
	
    float num   = a2;
    float denom = (NdotH2 * (a2 - 1.0) + 1.0);
    denom = PI * denom * denom;
	
    return num / denom;
}

float GeometrySchlickGGX(float NdotV, float roughness)
{
    float r = (roughness + 1.0);
    float k = (r*r) / 8.0;

    float num   = NdotV;
    float denom = NdotV * (1.0 - k) + k;
	
    return num / denom;
}

float GeometrySmith(vec3 N, vec3 V, vec3 L, float roughness)
{
    float NdotV = max(dot(N, V), 0.0);
    float NdotL = max(dot(N, L), 0.0);
    float ggx2  = GeometrySchlickGGX(NdotV, roughness);
    float ggx1  = GeometrySchlickGGX(NdotL, roughness);
	
    return ggx1 * ggx2;
}
///END PBR functions

const float Br = 0.0025;
const float Bm = 0.0003;
const float g =  0.9800;
const vec3 nitrogen = vec3(0.650, 0.570, 0.475);
const vec3 Kr = Br / pow(nitrogen, vec3(4.0));
const vec3 Km = Bm / pow(nitrogen, vec3(0.84));

vec3 sky_color(in vec3 pos)
{
	// Atmosphere Scattering
	vec3 fsun = LIGHT_DIRECTION;
	float brightnees = exp(-sqrt(pow(abs(min(5.*(pos.y-0.1),0.)),2.)+0.1));
	if(pos.y < 0.)
	{
		pos.y = 0.;
		pos.xyz = normalize(pos.xyz);
	}
    float mu = dot(normalize(pos), normalize(fsun));
	
	vec3 extinction = mix(exp(-exp(-((pos.y + fsun.y * 4.0) * (exp(-pos.y * 16.0) + 0.1) / 80.0) / Br) * (exp(-pos.y * 16.0) + 0.1) * Kr / Br) * exp(-pos.y * exp(-pos.y * 8.0 ) * 4.0) * exp(-pos.y * 2.0) * 4.0, vec3(1.0 - exp(fsun.y)) * 0.2, -fsun.y * 0.2 + 0.5);
	vec3 sky_col = brightnees* 3.0 / (8.0 * 3.14) * (1.0 + mu * mu) * (Kr + Km * (1.0 - g * g) / (2.0 + g * g) / pow(1.0 + g * g - 2.0 * g * mu, 1.5)) / (Br + Bm) * extinction;
	sky_col = 0.4*clamp(sky_col,0.,10.);
	return pow(sky_col,vec3(1./gamma_sky)); 
}

vec3 ambient_sky_color(in vec3 pos)
{
	float y = pos.y;
	pos.xyz = normalize(vec3(1,0,0));
	return sky_color(pos)*exp(-abs(y));
}

vec4 ambient_occlusion(in vec4 pos, in vec4 norm, in vec4 dir)
{	
	vec3 pos0 = pos.xyz;
	
	float occlusion_angle = 0.;
	vec3 direction = normalize(norm.xyz);
	vec3 ambient_color = ambient_sky_color(norm.xyz);
	//step out
	pos.xyz += 0.02*dir.w*direction;
	//march in the direction of the normal
	for(int i = 0; i < AMBIENT_MARCHES; i++)
	{
		pos.xyz += pos.w*direction;
		pos.w = DE(pos.xyz);
		
		norm.w = length(pos0 - pos.xyz);
		occlusion_angle += clamp(pos.w/norm.w,0.,1.);
	}
	
	occlusion_angle /= float(AMBIENT_MARCHES); // average weighted by importance
	return vec4(ambient_color,1.)*(0.5-cos(3.14159265*occlusion_angle)*0.5);
}


vec3 refraction(vec3 rd, vec3 n, float p) {
	float dot_nd = dot(rd, n);
	return p * (rd - dot_nd * n) + sqrt(1.0 - (p * p) * (1.0 - dot_nd * dot_nd)) * n;
}

vec3 lighting(vec4 color, vec2 pbr, vec4 pos, vec4 dir, vec4 norm, vec3 refl, vec3 refr, float shadow) 
{
	vec3 albedo = color.xyz;
	albedo = pow(albedo,vec3(1.f/gamma_material)); //square it to make the fractals more colorfull 
	
	vec4 ambient_color = ambient_occlusion(pos, norm, dir);
	
	float metallic = pbr.x;
	vec3 F0 = vec3(0.04); 
	F0 = mix(F0, albedo, metallic);
	
	//reflectance equation
	vec3 Lo = vec3(0.0);
	vec3 V = -dir.xyz;
	vec3 N = norm.xyz;
	
	{ //ambient occlusion contribution
		float roughness = max(pbr.y,0.5);
		vec3 L = normalize(N);
		vec3 H = normalize(V + L);
		vec3 radiance = ambient_color.xyz;        
		
		// cook-torrance brdf
		float NDF = DistributionGGX(N, H, roughness);        
		float G   = GeometrySmith(N, V, L, roughness);      
		vec3 F    = fresnelSchlick(max(dot(H, V), 0.0), F0);       
		
		vec3 kS = F;
		vec3 kD = vec3(1.0) - kS;
		kD *= 1.0 - metallic;	  
		
		vec3 numerator    = NDF * G * F;
		float denominator = 4.0 * max(dot(N, V), 0.0) * max(dot(N, L), 0.0);
		vec3 specular     = numerator / max(denominator, 0.001);  
			
		// add to outgoing radiance Lo
		float NdotL = max(dot(N, L), 0.0);                
		Lo += (kD * albedo / PI + specular) * radiance * NdotL;
	}
	
	if(!SHADOWS_ENABLED)
	{
		shadow = ambient_color.w;
	}
	
	vec3 sun_color = sky_color(LIGHT_DIRECTION);

	{ //light contribution
		float roughness = pbr.y;
		vec3 L = normalize(LIGHT_DIRECTION);
		vec3 H = normalize(V + L);
		vec3 radiance = sun_color*shadow*(0.8+0.2*ambient_color.w);        
		
		// cook-torrance brdf
		float NDF = DistributionGGX(N, H, roughness);        
		float G   = GeometrySmith(N, V, L, roughness);      
		vec3 F    = fresnelSchlick(max(dot(H, V), 0.0), F0);       
		
		vec3 kS = F;
		vec3 kD = vec3(1.0) - kS;
		kD *= 1.0 - metallic;	  
		
		vec3 numerator    = NDF * G * F;
		float denominator = 4.0 * max(dot(N, V), 0.0) * max(dot(N, L), 0.0);
		vec3 specular     = numerator / max(denominator, 0.001);  
			
		// add to outgoing radiance Lo
		float NdotL = max(dot(N, L), 0.0);                
		Lo += (kD * albedo / PI + specular) * radiance * NdotL;
	}
	
	{ //light reflection, GI imitation
		float roughness = max(PBR_ROUGHNESS,0.8);
		vec3 L = normalize(-LIGHT_DIRECTION);
		vec3 H = normalize(V + L);
		vec3 radiance = 0.5*sun_color*ambient_color.w*(1.-ambient_color.w);        
		
		// cook-torrance brdf
		float NDF = DistributionGGX(N, H, roughness);        
		float G   = GeometrySmith(N, V, L, roughness);      
		vec3 F    = fresnelSchlick(max(dot(H, V), 0.0), F0);       
		
		vec3 kS = F;
		vec3 kD = vec3(1.0) - kS;
		kD *= 1.0 - metallic;	  
		
		vec3 numerator    = NDF * G * F;
		float denominator = 4.0 * max(dot(N, V), 0.0) * max(dot(N, L), 0.0);
		vec3 specular     = numerator / max(denominator, 0.001);  
			
		// add to outgoing radiance Lo
		float NdotL = max(dot(N, L), 0.0);                
		Lo += (kD * albedo / PI + specular) * radiance * NdotL;
	}

	if(color.w>0.5) // if metal
	{
		vec3 n = normalize(norm.xyz);
		vec3 q = dir.xyz - n*(2.*dot(dir.xyz,n));
	
        //metal
        vec3 F0 = vec3(0.6); 
        vec3 L = normalize(q);
        vec3 H = normalize(V + L);
        vec3 F = fresnelSchlick(max(dot(H, V), 0.0), F0);  

        vec3 kS = F;
        vec3 kD = vec3(1.0) - kS;
        Lo += kS*refl;
	}
	
	return Lo;
}

vec3 shading_simple(in vec4 pos, in vec4 dir, float fov, float shadow)
{
	if(pos.w < max(1.*fov*dir.w, MIN_DIST))
	{
		//calculate the normal
		float error = 0.5*fov*dir.w;
		vec4 norm = calcNormal(pos.xyz, max(MIN_DIST, error)); 
		norm.xyz = normalize(norm.xyz);
		if(norm.w < -error)
		{
			return COL(pos.xyz).xyz;
		}
		else
		{
			//optimize color sampling 
			vec3 cpos = pos.xyz - pos.w*norm.xyz;
			//cpos = cpos - DE(cpos)*norm.xyz;
			//cpos = cpos - DE(cpos)*norm.xyz;
			
			vec4 color; vec2 pbr;
			scene_material(cpos, color, pbr);
			return lighting(color, pbr, pos, dir, norm, vec3(0), vec3(0), shadow); 
		}
	}
	else
	{
		return sky_color(dir.xyz);
	}
}


vec3 render_ray(in vec4 pos, in vec4 dir, float fov)
{
	vec4 var = vec4(0,0,0,1);
	ray_march(pos, dir, var, fov); 
    vec4 spos = vec4(pos.xyz, pos.w);
	float shadow = shadow_march(spos, vec4(LIGHT_DIRECTION,0.), 5., LIGHT_ANGLE);
	return shading_simple(pos, dir, fov, shadow);
}

vec3 ACESFilm(vec3 x)
{
    float a = 2.51;
    float b = 0.03;
    float c = 2.43;
    float d = 0.59;
    float e = 0.14;
    return (x*(a*x+b))/(x*(c*x+d)+e);
}

vec3 HDRmapping(vec3 color, float exposure)
{
	// Exposure tone mapping
    vec3 mapped = ACESFilm(color * exposure);
    // Gamma correction 
    return pow(mapped, vec3(1.0 / gamma_camera));
}


mat3 getCamera(vec2 angles)
{
   mat3 theta_rot = mat3(1,   0,              0,
                          0,   cos(angles.y),  sin(angles.y),
                          0,  -sin(angles.y),  cos(angles.y)); 
        
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


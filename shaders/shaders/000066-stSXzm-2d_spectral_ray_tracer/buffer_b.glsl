// Buffer B (buffer) — 2d spectral ray tracer by riouxld
// https://www.shadertoy.com/view/stSXzm

// ------------------------------------------------------------------------------ //
// Spectral, ray tracing and core: this is where the magic happens. Basically, at //
// each pixels we compute flux of incoming ray using Monte Carlo. This means that //
// we sample directions / wavelength uniformly and trace rays from them until     //
// an emiter is met or a maxiumum depth is attained                               //
// ------------------------------------------------------------------------------ // 


// structures
// ----------

struct Ray {
    vec2 origin;
    vec2 dir;
    float wavelength;
};

struct Sample {
    Ray ray;
    float contrib;
    float pdf;
    float attenuation;
};

struct HitQuery {
    float t;
    vec2 p;
    vec2 normal;
    int material;
    float throughput;
};

struct Sphere {
    vec2 center;
    float radius;
    int material;

};

struct Scene {
    Sphere[nb_emiters] emiters;
    Sphere[nb_objects] objects;
};


// dummy missed hit
const HitQuery no_hit = HitQuery(infinity, vec2(0.0), vec2(0.0), none, 0.0);

// RNG: oldschool rand() from Visual Studio, hash to initialize 
// the random sequence (copied from Hugo Elias)
// ------------------------------------------------------------
int  seed = 1;
void srand(int s ) { seed = s; }
int  rand(void) { seed = seed*0x343fd+0x269ec3; return (seed>>16)&32767; }


int hash( int n )
{
	n = (n << 13) ^ n;
    return n * (n * n * 15731 + 789221) + 1376312589;
}

// Wavelength to XYZ conversion 
// ---------------------
// https://www.shadertoy.com/view/llVSDz                  

// Spectrum to xyz approx function from Sloan (& Fabrice)
// Inputs:  Wavelength in nanometers
float xFit_1931(float lambda_nano)
{
    float t1 = (lambda_nano-442.0)*((lambda_nano<442.0)?0.0624:0.0374),
          t2 = (lambda_nano-599.8)*((lambda_nano<599.8)?0.0264:0.0323),
          t3 = (lambda_nano-501.1)*((lambda_nano<501.1)?0.0490:0.0382);
    return 0.362*exp(-0.5*t1*t1) + 1.056*exp(-0.5*t2*t2)- 0.065*exp(-0.5*t3*t3);
}
float yFit_1931(float lambda_nano)
{
    float t1 = (lambda_nano-568.8)*((lambda_nano<568.8)?0.0213:0.0247),
          t2 = (lambda_nano-530.9)*((lambda_nano<530.9)?0.0613:0.0322);
    return 0.821*exp(-0.5*t1*t1) + 0.286*exp(-0.5*t2*t2);
}
float zFit_1931(float lambda_nano)
{
    float t1 = (lambda_nano-437.0)*((lambda_nano<437.0)?0.0845:0.0278),
          t2 = (lambda_nano-459.0)*((lambda_nano<459.0)?0.0385:0.0725);
    return 1.217*exp(-0.5*t1*t1) + 0.681*exp(-0.5*t2*t2);
}

vec3 xyzFit_1931(float lambda_nano) {
    return vec3( xFit_1931(lambda_nano), yFit_1931(lambda_nano), zFit_1931(lambda_nano) );
}


// get ior with respect to wavelength
// ----------------------------------
// https://en.wikipedia.org/wiki/Cauchy%27s_equation
// https://www.shadertoy.com/view/wlSXz3
// Inputs:  Wavelength in nanometers, convert to micro (coefficients are computed that way)
float cauchy_ior(in float lambda_nano) {
    float lambda_micro = lambda_nano*1e-3;
    // impossible material
    return 1.0 + 0.25 / (lambda_micro*lambda_micro);
}

// sampler 
// -------

float sample_uniform(void) {
    return float(rand())/32767.0;
}

float sample_wavelength(void) {
    return (float(spectrum_width))*sample_uniform() + float(spectrum_start);
}


float pdf_direction_uniform () {
    return 1.0f / two_pi;
}

vec2 sample_direction_uniform() {
    float theta = two_pi * sample_uniform();
	return vec2(cos(theta), sin(theta));
}

// coordinates transformations
// ---------------------------

vec2 world2local(vec2 normal, vec2 dir) {
    vec2 tangent = vec2(normal.y, -normal.x);
    return vec2( dir.x * tangent.x + dir.y * tangent.y, 
                 dir.x * normal.x  + dir.y * normal.y );
}


vec2 local2world(vec2 normal, vec2 dir) {
    
    vec2 tangent = vec2(normal.y, -normal.x);
    return vec2(dir.x * tangent.x + dir.y * normal.x, 
                dir.x * tangent.y + dir.y * normal.y );
    
}

// materials
// ---------

Sample sample_mirror(HitQuery hit, Ray ray) {
    
    
    vec2 wi = -ray.dir;
    vec2 normal = hit.normal;
    wi = world2local(normal, wi);
    float cos_theta_i = wi.y;
    
    cos_theta_i = abs(cos_theta_i);
    
    vec2 wo = vec2(-wi.x, wi.y);
    float pdf = 1.0;
    float contrib = 1.0 / cos_theta_i;
    vec2 pert = eps * hit.normal;

    
    wo = local2world(normal, wo);
    
    return Sample(Ray(hit.p + pert, wo, ray.wavelength), contrib, pdf, cos_theta_i);
}


vec2 my_faceforward(vec2 n, vec2 v) {
    return (dot(n, v) < 0.0) ? -n : n;
}

float compute_fresnel(float cos_theta_i, float eta_i, float eta_t) {

    float eta = eta_i / eta_t;
    
    float sin_theta_i = sqrt(max(0.0, 1.0 - cos_theta_i * cos_theta_i));
    float sin_theta_t = eta * sin_theta_i;
    
    if (sin_theta_t >= 1.0)
        return 1.0;
        
    float cos_theta_t = sqrt(max(0.0, 1.0 - sin_theta_t * sin_theta_t));
    
    float R_par = ((eta_t * cos_theta_i) - (eta_i * cos_theta_t)) /
                  ((eta_t * cos_theta_i) + (eta_i * cos_theta_t));
    float R_per = ((eta_i * cos_theta_i) - (eta_t * cos_theta_t)) /
                  ((eta_i * cos_theta_i) + (eta_t * cos_theta_t));
    float fresnel = (R_par * R_par + R_per * R_per) / 2.0;
    
    return fresnel;
}


Sample sample_dielectric(HitQuery hit, Ray ray) {

    vec2 wi = -ray.dir;
    vec2 normal = hit.normal;
    wi = world2local(normal, wi);
    float cos_theta_i = wi.y;
    
    
    bool entering = cos_theta_i > 0.0;
    float eta_i = entering ? 1.0: cauchy_ior(ray.wavelength);
    float eta_t = entering ? cauchy_ior(ray.wavelength): 1.0;
    float eta = eta_i / eta_t;
    
    cos_theta_i = abs(cos_theta_i);
    float fresnel = compute_fresnel(cos_theta_i, eta_i, eta_t);
    
    
    vec2 wo, pert;
    float pdf, contrib;
    if (sample_uniform() < fresnel) {
        wo = vec2(-wi.x, wi.y);
        pdf = fresnel;
        contrib = fresnel / cos_theta_i;
        pert = ( entering ? 1. : -1.) * eps * hit.normal;
    } else {
        float sin2_theta_I = max(0.0, 1.0 - cos_theta_i * cos_theta_i);
        float sin2_theta_t = eta * eta * sin2_theta_I;
        float cos_theta_t = sqrt(1.0 - sin2_theta_t);
        wo = -eta * wi + (eta * cos_theta_i - cos_theta_t) * my_faceforward(vec2(0.0,1.0), wi);
        pdf = 1.0 - fresnel;
        contrib = (1.0 - fresnel) / cos_theta_i;
        pert = ( entering ? -1. : 1.) * eps * hit.normal;
        if (false) {
            contrib *= eta * eta;
        }
    }
    
    
    wo = local2world(normal, wo);
    
    // return sampled ray 
    return Sample(Ray(hit.p + pert, wo, ray.wavelength), contrib, pdf, cos_theta_i);
}


// sphere / ray intersection
// -------------------------
HitQuery intersect_sphere(Ray ray, Sphere sphere) {

    
    float radius_sq = sphere.radius *  sphere.radius;
    
    vec2 origin2center = sphere.center - ray.origin;
    float origin2center_norm = length(origin2center);
    float origin2center_norm_sq = origin2center_norm * origin2center_norm;
    
    bool is_inside =  origin2center_norm <= sphere.radius;
    
    float projection = dot(origin2center, ray.dir);
    float projection_sq = projection*projection;
    
    if ( !is_inside && projection < eps) {
        return no_hit;
    }
    
    float perp_sq = origin2center_norm_sq - projection_sq;
    
    if (!is_inside && perp_sq > radius_sq) {
        return no_hit;
    }
    
    float dist_proj2bdr = sqrt(radius_sq - perp_sq);
    float t1 = projection - dist_proj2bdr;
    float t2 = projection + dist_proj2bdr;
    float t = t1 >= eps ? t1 : (t2 >= eps ? t2 : infinity);


    vec2 p = ray.origin + t * ray.dir;

    vec2 normal = normalize(p - sphere.center);


    return HitQuery(t, p, normal, sphere.material, 1.0);
    
}


// scene intersection
// ------------------
HitQuery intersect_scene(Ray ray, Scene scene) { 
    HitQuery neareast_hit = no_hit;
    
    // find nearest intersected object in the scene (no need for shadow ray)
    for (int i = 0 ; i < nb_emiters ; i++) {
        
        // test intersection with current object
        HitQuery sphere_hit = intersect_sphere(ray, scene.emiters[i]);
        
        // if the object is not intersected, go to next one
        if (sphere_hit.material == none) {
            continue;
        }
        
        // if closer, set as current hit
        if (sphere_hit.t <= neareast_hit.t) {
            neareast_hit = sphere_hit;
        }
        
    }
    
    // find nearest intersected object in the scene (no need for shadow ray)
    for (int i = 0 ; i < nb_objects ; i++) {
        
        // test intersection with current object
        HitQuery sphere_hit = intersect_sphere(ray, scene.objects[i]);
        
        // if the object is not intersected, go to next one
        if (sphere_hit.material == none) {
            continue;
        }
        
        // if closer, set as current hit
        if (sphere_hit.t <= neareast_hit.t) {
            neareast_hit = sphere_hit;
        }
        
    }
    return neareast_hit;
    
}

// ray tracing
// -----------

HitQuery ray_trace(Ray ray, Scene scene) { 
    
 
    float throughput = 1.0;
    HitQuery hit_query = no_hit;
    
    // trace a path recursivly until max_depth
    for (int i = 0; i < max_depth; i++) {
        
        // intersect ray with scene
        hit_query = intersect_scene(ray, scene);
        
        
        // if missed or emiter, stop
        if (hit_query.material == none || hit_query.material == emiter) {
            if (i == 0 && ONLY_INDIRECT) {
                hit_query = no_hit;
            }
            break;
        }
        // oherwise, sample new ray according to material
        else {
            Sample sample_dir;
            if (hit_query.material == mirror) {
                sample_dir = sample_mirror(hit_query, ray);
            } 
            else if (hit_query.material == dielectric) {
                sample_dir = sample_dielectric(hit_query, ray);
            } 
            ray = sample_dir.ray;
            // everything should cancel out, but just for the form.
            throughput *= sample_dir.contrib * sample_dir.attenuation/(sample_dir.pdf + eps);
        }
        
        
        
    }
    hit_query.throughput = throughput;
    return hit_query;

}

// flux computation
// -------------------
vec3 compute_flux( vec2 p , Scene scene) { 
    // Monte Carlo estimator of the flux
    vec3 flux = vec3(0.0);
    for (int i = 0 ; i < n_samples ; i++){
        
        // sample direction uniformly
        vec2 wo = sample_direction_uniform();
        float wavelength = sample_wavelength();
        Ray ray = Ray(p, wo, wavelength);
        
        // ray trace
        HitQuery hit_query = ray_trace(ray, scene);
        
        // if missed, nothing to do
        if (hit_query.material == none) {
            continue;
        }
        
        // if last hit was emiter, accumulate contribution
        if (hit_query.material == emiter) {
            flux += xyzFit_1931(wavelength) * hit_query.throughput / pdf_direction_uniform();
        }
        
    }
    flux /= float(n_samples);
    
    return flux;
}


vec4 accumulate(vec2 uv, vec3 color, int start_frame) {
    if (ACCUMULATE) {
        return texture(iChannel1, uv) * (float(iFrame - start_frame) / float(iFrame + 1 - start_frame)) 
            + vec4(color,1.0)/ float(iFrame + 1 - start_frame);
    } else {
        return vec4(color, 1.0);
    }
            

}

// main
// ----
void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    
    // starting frame accumulation
    int start_frame = int( texelFetch(iChannel0, reset_time_loc,0).x);
        
    // pixelindices (0,width-1)x(0, height-1)
    ivec2 indices = ivec2(fragCoord);
    
    // uv texture coordinate (0,1)x(0,1)
    vec2 uv = (fragCoord)/iResolution.xy;
    
     // init rng seed for each time and pixels
    srand( hash(indices.x+hash(indices.y+hash(iFrame))));
    
    // pixel scrambled coordinate for antialiasing (0,aspectratio)x(0,1)
    vec2 p_center = (fragCoord)/iResolution.y;
    vec2 p = (fragCoord + sample_uniform())/iResolution.y;
   
    // construct scene 
    vec2 light_pos = texelFetch(iChannel0, light_pos_loc, 0).xy; 
    Sphere emiter_1 = Sphere(light_pos, 0.025, emiter);
    Sphere object_1 = Sphere(vec2(0.63,0.5), 0.2, dielectric);
    Sphere object_2 = Sphere(vec2(1.13,0.5), 0.2, dielectric);
    Sphere object_3 = Sphere(vec2(0.83,0.75), 0.1, dielectric);
    
    Scene scene = Scene(Sphere[nb_emiters](emiter_1), Sphere[nb_objects](object_1,object_2, object_3));
    
    // if insight emitters, show light
    for (int i = 0 ; i < nb_emiters ; i++) {
        if (length(p_center - scene.emiters[i].center)  < scene.emiters[i].radius) {
            fragColor = accumulate(uv, vec3(1.0), start_frame);
            return;
        }
    }
    
    // if object border, show object 
    for (int i = 0 ; i < nb_objects ; i++) {
        if (length(p - scene.objects[i].center) <= scene.objects[i].radius + 0.001 
            && length(p - scene.objects[i].center) >= scene.objects[i].radius - 0.001) {
            fragColor = accumulate(uv, vec3(0.25), start_frame);
            return;
        }
    }
    
    
    // compute flux
    vec3 flux = compute_flux(p, scene);

            
    // Accumulate fluence with walking average
    fragColor = accumulate(uv, flux, start_frame);

}
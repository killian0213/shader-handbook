// Buffer B (buffer) — Veach 1997 Fig 9.4 by mplanck
// https://www.shadertoy.com/view/lsV3zV

// Buffer B does the sampling and accumulation work 

// **************************************************************************
// DEFINES

#define PI 3.14159
#define TWO_PI 6.28318
#define INV_TWO_PI .159155
#define PI_OVER_TWO 1.570796

#define REALLY_SMALL_NUMBER 0.0001
#define REALLY_BIG_NUMBER 1000000.

#define MIRROR_ID 1.
#define SEMI_MIRROR_ID 2.
#define SEMI_ROUGH_ID 3.
#define ROUGH_ID 4.
#define LIGHT_ID 5.

#define BACKDROP_ID 6.
#define ENVIRONMENT_ID 7.

// **************************************************************************
// CONSTANTS

const int BRDF_IMPORTANCE_SAMPLING = 2;
const int LIGHT_IMPORTANCE_SAMPLING = 1;
const int MULTIPLE_IMPORTANCE_SAMPLING = 0;

// **************************************************************************
// INLINE MACROS

#define MATCHES_ID(id1, id2) (id1 > (id2 - .5)) && (id1 < (id2 + .5))


// **************************************************************************
// GLOBALS

float g_frame        = 0.;
int g_samplingType = MULTIPLE_IMPORTANCE_SAMPLING;
float g_colorSamples = 0.;


vec4 g_light0 = vec4(-2.,1.8, -3., .1);
vec4 g_light1 = vec4(-.666,1.8, -3., .2);
vec4 g_light2 = vec4(.666,1.8, -3., .3);
vec4 g_light3 = vec4(2.,1.8, -3., .4);

// **************************************************************************
// MATH UTILITIES

// Rotate the input point around the y-axis by the angle given as a cos(angle)
// and sin(angle) argument.  There are many times where I want to reuse the
// same angle on different points, so why do the heavy trig twice. Range of
// outputs := ([-1.,-1.,-1.] -> [1.,1.,1.])
vec3 rotate_yaxis( vec3 point, float cosa, float sina )
{
    return vec3(point.x * cosa  + point.z * sina,
                point.y,
                point.x * -sina + point.z * cosa);
}

// Rotate the input point around the x-axis by the angle given as a cos(angle)
// and sin(angle) argument.  There are many times where  I want to reuse the
// same angle on different points, so why do the  heavy trig twice. Range of
// outputs := ([-1.,-1.,-1.] -> [1.,1.,1.])
vec3 rotate_xaxis( vec3 point, float cosa, float sina )
{
    return vec3(point.x,
                point.y * cosa - point.z * sina,
                point.y * sina + point.z * cosa);
}


// --------------------------------------
// from dave hoskins: https://www.shadertoy.com/view/4djSRW

#define HASHSCALE3 vec3(.1031, .1030, .0973)
vec2 hash21(float p)
{
    vec3 p3 = fract(vec3(p) * HASHSCALE3);
    p3 += dot(p3, p3.yzx + 19.19);
    return fract(vec2((p3.x + p3.y)*p3.z, (p3.x+p3.z)*p3.y));
}

#define HASHSCALE1 .1031
float hash12(vec2 p)
{
    vec3 p3  = fract(vec3(p.xyx) * HASHSCALE1);
    p3 += dot(p3, p3.yzx + 19.19);
    return fract((p3.x + p3.y) * p3.z);
}
// --------------------------------------

float dist_squared(vec3 v1, vec3 v2)
{
    return (v1.x - v2.x) * (v1.x - v2.x) + 
        (v1.y - v2.y) * (v1.y - v2.y) + 
        (v1.z - v2.z) * (v1.z - v2.z);
}

vec4 intersect_sphere(vec3 ro, vec3 rd, vec3 sphc, float sphr)
{
    if (dist_squared(ro,sphc) < sphr * sphr) 
    { 
        return vec4(-1., vec3(0.)); 
    }
    
    vec3 sphro = ro - sphc; 
    float a = dot(rd, rd);
    float b = dot(sphro, rd);
    float c = dot(sphro, sphro) - sphr * sphr;
    float sign = mix(-1., 1., step(0., a));
    float t = (-b + sign * sqrt(b*b - a*c))/a; 
    
    vec3 n = normalize(ro + t * rd - sphc);
    return vec4(step(0., t), n);    
    
}

vec3 polar_to_cartesian(float sinTheta, 
                        float cosTheta, 
                        float sinPhi,
                        float cosPhi)
{
    return vec3(sinTheta * cosPhi,
                sinTheta * sinPhi,
                cosTheta);
}


// **************************************************************************
// DISTANCE FIELDS

float sphere_df( vec3 p, float r) 
{ 
    return length(p) - r; 
}

float envsphere_df ( vec3 p, float r) 
{ 
    return r - length(p); 
}

float roundbox_df ( vec3 p, vec3 b, float r ) 
{
    return length(max(abs(p-vec3(0., .5*b.y, 0.))-.5*b,0.))-r; 
}

// **************************************************************************
// INFORMATION HOLDERS (aka DATA STRUCTURES)

struct RaySampleInfo
{
    vec3 origin;
    vec3 direction;
    vec2 imagePlaneUV;
};

#define INIT_RAY_INFO() RaySampleInfo(vec3(0.) /* origin */, vec3(0.) /* direction */, vec2(0.) /* imagePlaneUV */)

struct SurfaceInfo
{
    float id;
    vec3 incomingRayDir;
    vec3 point;
    vec3 normal;
    float incomingRayLength;
    float rayDepth;
    
};
#define INIT_SURFACE_INFO(incomingRayDir) SurfaceInfo(-1. /* id */, incomingRayDir /* incomingRayDir */, vec3(0.) /* point */, vec3(0.) /* normal */, 0. /* incomingRayLength */, 0. /* rayDepth */)

struct MaterialInfo
{
    float seed;
    float specExponent;
    float specIntensity;
    vec3  baseColor;
};
#define INIT_MATERIAL_INFO(seed) MaterialInfo(seed, 1. /* specExponent */, 1. /* specIntensity */, vec3(.8) /* baseColor */)

// **************************************************************************
// SETUP WORLD

void setup_globals()
{
    
    vec3 storedState = texture(iChannel1, vec2(0., 0.), -100.).rgb;
    g_frame = float(iFrame) - storedState.r ;
    g_samplingType = int(storedState.g + .5);
    g_colorSamples = storedState.b;
}

vec4 get_light(int i)
{
    if (i == 0) { return g_light0; }
    if (i == 1) { return g_light1; }
    if (i == 2) { return g_light2; }
    else { return g_light3; }
}

RaySampleInfo setup_cameraRay(vec2 aaoffset)
{
    
    vec3 origin = vec3(0.0, 2., 6.0);
    vec3 cameraPointsAt = vec3(0., .5, 0.);

    float invAspectRatio = iResolution.y / iResolution.x;
    vec2 imagePlaneUV = (gl_FragCoord.xy + aaoffset) / iResolution.xy - .5;
    imagePlaneUV.y *= invAspectRatio;

    vec3 iu = vec3(0., 1., 0.);

    vec3 iz = normalize( cameraPointsAt - origin );
    vec3 ix = normalize( cross(iz, iu) );
    vec3 iy = cross(ix, iz);

    vec3 direction = normalize( imagePlaneUV.x * ix + imagePlaneUV.y * iy + .8 * iz );

    return RaySampleInfo(origin, direction, imagePlaneUV);

}

// **************************************************************************
// MARCH

vec2 union_obj(vec2 o1, vec2 o2)
{
    return (o1.x < o2.x) ? o1 : o2;
}

vec2 map(float depth, vec3 p)
{
    vec2 roughObj =       vec2(roundbox_df(rotate_xaxis(p - vec3(0., -.4,  1.2), cos( 0.0), sin( 0.0)), vec3(5., .02, 1.), .01), ROUGH_ID);
    vec2 semiroughObj =   vec2(roundbox_df(rotate_xaxis(p - vec3(0., -.38,  0.), cos(-0.12), sin(-0.12)) , vec3(5., .02, 1.), .01), SEMI_ROUGH_ID);
    vec2 semimirrorObj =  vec2(roundbox_df(rotate_xaxis(p - vec3(0., -.2, -1.2), cos(-0.26), sin(-0.26)) , vec3(5., .02, 1.), .01), SEMI_MIRROR_ID);
    vec2 mirrorObj =      vec2(roundbox_df(rotate_xaxis(p - vec3(0., .2, -2.4), cos(-0.5), sin(-0.5)) , vec3(5., .02, 1.), .01), MIRROR_ID);    
    
    
    vec2 resultObj = union_obj(mirrorObj, semimirrorObj);
    resultObj = union_obj(resultObj, semiroughObj);
    resultObj = union_obj(resultObj, roughObj);    
    
    float backdropDF = roundbox_df(p + vec3(0., 1., 0.), vec3(20.,.2,10.), 0.);
    backdropDF = min(backdropDF, roundbox_df(rotate_xaxis(p - vec3(0., -3.8, -3.2), cos(.5), sin(.5)), vec3(20., 10., .2), 0.));
    vec2 backdropObjs = vec2(backdropDF, BACKDROP_ID);    
    resultObj = union_obj(resultObj, backdropObjs);
    
    if (depth < .5)
    {
        vec4 l = get_light(0);
        float lightDF = sphere_df(p - l.xyz, l.w);
        l = get_light(1);
        lightDF = min(lightDF, sphere_df(p - l.xyz, l.w));
        l = get_light(2);
        lightDF = min(lightDF, sphere_df(p - l.xyz, l.w));
        l = get_light(3);
        lightDF = min(lightDF, sphere_df(p - l.xyz, l.w));
        
        vec2 lightObjs =       vec2(lightDF, LIGHT_ID);
        resultObj = union_obj(resultObj, lightObjs);
    }
    
    resultObj = union_obj(resultObj, vec2( envsphere_df(p, 11.), ENVIRONMENT_ID) );
        
    return resultObj;
}

vec3 calc_normal(vec3 p)
{
 
    vec3 epsilon = vec3(0.001, 0., 0.);
    
    vec3 n = vec3(map(1., p + epsilon.xyy).x - map(1., p - epsilon.xyy).x,
                  map(1., p + epsilon.yxy).x - map(1., p - epsilon.yxy).x,
                  map(1., p + epsilon.yyx).x - map(1., p - epsilon.yyx).x);
    
    return normalize(n);
}

SurfaceInfo dist_march(float depth, vec3 ro, vec3 rd)
{
    SurfaceInfo surface = INIT_SURFACE_INFO(rd); 
    
    float t = 0.;
    vec3 p = ro;    
    vec2 obj = vec2(0.);
    float d = REALLY_BIG_NUMBER;
    
    for (int i = 0; i < 64; i++)
    {
        obj = map(depth, p);
        d = obj.x;
        
        t += d;
        p += rd * d;
        
        if (d < .001) { break; }
        obj.y = 0.;
        
    }

    surface.id = obj.y;        
    surface.point = p;
    surface.normal = calc_normal(surface.point);
    surface.incomingRayLength = t;
    surface.rayDepth = depth;
    
    return surface;
}

void calc_binormals(vec3 normal,
                    out vec3 tangent,
                    out vec3 binormal)
{
    if (abs(normal.x) > abs(normal.y))
    {
        tangent = normalize(vec3(-normal.z, 0., normal.x));
    }
    else
    {
        tangent = normalize(vec3(0., normal.z, -normal.y));
    }
    
    binormal = cross(normal, tangent);
}
 
vec3 uniform_sample_cone(vec2 u12, 
                         float cosThetaMax, 
                         vec3 xbasis, vec3 ybasis, vec3 zbasis)
{
    float cosTheta = (1. - u12.x) + u12.x * cosThetaMax;
    float sinTheta = sqrt(1. - cosTheta * cosTheta);
    float phi = u12.y * TWO_PI;
    vec3 samplev = polar_to_cartesian(sinTheta, cosTheta, sin(phi), cos(phi));
    return samplev.x * xbasis + samplev.y * ybasis + samplev.z * zbasis;
}
             
vec3 brdf(vec3 wi, 
          vec3 wo, 
          vec3 n,
          MaterialInfo material)
{
    
    float cosThetaN_Wi = abs(dot(n, wi));
    float cosThetaN_Wo = abs(dot(n, wo));
    vec3 wh = normalize(wi + wo);
    float cosThetaN_Wh = abs(dot(n, wh));   
    
    // Compute geometric term of blinn microfacet      
    float cosThetaWo_Wh = abs(dot(wo, wh));
    float G = min(1., min((2. * cosThetaN_Wh * cosThetaN_Wo / cosThetaWo_Wh),
                           (2. * cosThetaN_Wh * cosThetaN_Wi / cosThetaWo_Wh)));
    
    // Compute distribution term
    float D = (material.specExponent+2.) * INV_TWO_PI * pow(max(0., cosThetaN_Wh), material.specExponent);
    
    // assume no fresnel
    float F = 1.;
    
    return material.baseColor * D * G * F / (4. * cosThetaN_Wi * cosThetaN_Wo);
}
 

vec3 light_emission(vec3 p, vec3 lp, vec3 ln)
{
    return 20. * vec3(1., .98, .95) / dist_squared(p, lp);
}

float calc_visibility( vec3 ro, vec3 rd, float ray_extent )
{
    
    SurfaceInfo surface = dist_march(1., ro, rd);
    return step(ray_extent, surface.incomingRayLength);
    
}

float light_pdf( vec4 light,
                SurfaceInfo surface )
{
    
    float sinThetaMax2 = light.w * light.w / dist_squared(light.xyz, surface.point);
    float cosThetaMax = sqrt(max(0., 1. - sinThetaMax2));
    return 1. / (TWO_PI * (1. - cosThetaMax));
    
}

vec3 sample_light( SurfaceInfo surface,
                   MaterialInfo material,
                   vec4 light,
                 out float pdf )
{
    vec2 u12 = hash21(material.seed);
    
    vec3 tangent = vec3(0.), binormal = vec3(0.);
    vec3 ldir = normalize(light.xyz - surface.point);
    calc_binormals(ldir, tangent, binormal);
    
    float sinThetaMax2 = light.w * light.w / dist_squared(light.xyz, surface.point);
    float cosThetaMax = sqrt(max(0., 1. - sinThetaMax2));
    vec3 light_sample = uniform_sample_cone(u12, cosThetaMax, tangent, binormal, ldir);
    
    pdf = -1.;
    if (dot(light_sample, surface.normal) > 0.)
    {
        pdf = 1. / (TWO_PI * (1. - cosThetaMax));
    }
    
    return light_sample;
    
}
 
float brdf_pdf( vec3 wi, vec3 wo, 
                SurfaceInfo surface, 
                MaterialInfo material )
{
    vec3 wh = normalize(wi + wo);    
    float cosTheta = abs(dot(wh, surface.normal));
        
    float pdf = -1.;
    if (dot(wo, wh) > 0.)
    {
        pdf = ((material.specExponent + 1.) * pow(max(0., cosTheta), material.specExponent))/(TWO_PI * 4. * dot(wo, wh));
    }
    
    return pdf;
}


vec3 sample_brdf( SurfaceInfo surface,
                 MaterialInfo material,
                out float pdf)
{
           
    vec2 u12 = hash21(material.seed);
    
    float cosTheta = pow(max(0., u12.x), 1./(material.specExponent+1.));
    float sinTheta = sqrt(max(0., 1. - cosTheta * cosTheta));
    float phi = u12.y * TWO_PI;
    
    vec3 whLocal = polar_to_cartesian(sinTheta, cosTheta, sin(phi), cos(phi));

    vec3 tangent = vec3(0.), binormal = vec3(0.);
    calc_binormals(surface.normal, tangent, binormal);
    
    vec3 wh = whLocal.x * tangent + whLocal.y * binormal + whLocal.z * surface.normal;
    
    vec3 wo = -surface.incomingRayDir;    
    if (dot(wo, wh) < 0.)
    {
       wh *= -1.;
    }
            
    vec3 wi = reflect(surface.incomingRayDir, wh);
    
    pdf = ((material.specExponent + 1.) * pow(clamp(abs(dot(wh, surface.normal)),0.,1.), material.specExponent))/(TWO_PI * 4. * dot(wo, wh));
    return wi;
}    

float power_heuristic(float nf, 
                      float fPdf, 
                      float ng, 
                      float gPdf)
{
    float f = nf * fPdf;
    float g = ng * gPdf;
    return (f*f)/(f*f + g*g);
}

vec3 integrate_lighting( SurfaceInfo surface,
                       MaterialInfo material,
                       vec3 wi)
{
    vec3 lcol = vec3(0.);
    for (int i = 0; i < 4; i += 1)
    {
        
        vec4 light = get_light(i); 
                
        if (g_samplingType == LIGHT_IMPORTANCE_SAMPLING ||
            g_samplingType == MULTIPLE_IMPORTANCE_SAMPLING)
        {
            // sample light        
            float lpdf = -1.;
            vec3 lightSample = sample_light(surface, material, light, lpdf);

            
            if (lpdf > 0.)
            {
                vec4 r = intersect_sphere(surface.point, lightSample, light.xyz, light.w);
                if (r.x > .0)
                {
                    vec3 colorSamples = mix(vec3(1.), vec3(1., .4, .4), g_colorSamples);
                    float bpdf = brdf_pdf(wi, lightSample, surface, material);
                    float misWeight = power_heuristic(1., lpdf, 1., bpdf);
                    if (g_samplingType == LIGHT_IMPORTANCE_SAMPLING)
                    {
                        misWeight = 1.;
                    }

                    float visibility = calc_visibility( surface.point + lightSample * .01, lightSample, r.x);
                    vec3 le = light_emission(surface.point, surface.point + lightSample * r.x, r.yzw);
                    // specular
                    lcol += material.specIntensity * colorSamples * visibility * brdf(wi, lightSample, surface.normal, material) * 
                                le * abs(dot(lightSample, surface.normal)) *
                                (misWeight/lpdf);

                    // diffuse - cheated lambertian
                    // reuse visibility
                    lcol += material.baseColor * visibility * abs(dot(surface.normal, lightSample)) * le * INV_TWO_PI*
                        (misWeight/lpdf);


                }
            }
        }

            
        
        if (g_samplingType == BRDF_IMPORTANCE_SAMPLING ||
            g_samplingType == MULTIPLE_IMPORTANCE_SAMPLING)
        {
            // sample brdf        
            float bpdf = -1.;
            vec3 brdfSample = sample_brdf(surface, material, bpdf);
            if (bpdf > 0.)
            {              
                vec4 r = intersect_sphere(surface.point, brdfSample, light.xyz, light.w);
                if (r.x > 0.)
                {               
                    vec3 colorSamples = mix(vec3(1.), vec3(.4, 1., .4), g_colorSamples);

                    float lpdf = light_pdf(light, surface);
                    float misWeight = power_heuristic(1., bpdf, 1., lpdf);
                    if (g_samplingType == BRDF_IMPORTANCE_SAMPLING)
                    {
                        misWeight = 1.;
                    }

                    float visibility = calc_visibility( surface.point + brdfSample * .01, brdfSample, r.x);

                    vec3 le = light_emission(surface.point, surface.point + brdfSample * r.x, r.yzw);
                    // specular
                    lcol += material.specIntensity * colorSamples * visibility * brdf(wi, brdfSample, surface.normal, material) *
                        le *
                        abs(dot(brdfSample, surface.normal)) *
                        (misWeight/bpdf);

                    // diffuse - cheated lambertian
                    // reuse visibility
                    lcol += material.baseColor * visibility * abs(dot(surface.normal, brdfSample)) * le * INV_TWO_PI *
                        (misWeight/bpdf);

                }
            }
        }

        
    }
    
    return lcol;
}

vec3 calc_pixelColor( float seed )
{
        
    vec3 pcol = vec3(0.);    

    RaySampleInfo currSample = setup_cameraRay( sin(.712 * seed) * vec2(.6 * cos(.231 * seed), .6 * sin(.231 * seed)) );
    
    
    for (float depth = 0.; depth < 1.; depth+=1.)
    {
        SurfaceInfo surface = dist_march(depth,
                                         currSample.origin, 
                                         currSample.direction);
        
        MaterialInfo material = INIT_MATERIAL_INFO(seed);
        float roughness = 1.;

        if (surface.id < .5)
        {
            break;
        }        
        else if (MATCHES_ID(surface.id, LIGHT_ID))
        {
            pcol = 1. * vec3(1., 1., 1.);
            break;
        }
        else if (MATCHES_ID(surface.id, MIRROR_ID))
        {
            roughness = 0.;
            material.baseColor = vec3(.005);
        }
        else if (MATCHES_ID(surface.id, SEMI_MIRROR_ID))
        {
            roughness = .4;
            material.baseColor = vec3(.005);
        }
        else if (MATCHES_ID(surface.id, SEMI_ROUGH_ID))
        {
            roughness = .8;
            material.baseColor = vec3(.005);
        }
        else if (MATCHES_ID(surface.id, ROUGH_ID))
        {
            roughness = .95;
            material.baseColor = vec3(.005);
        }
                   
        
        else if (MATCHES_ID(surface.id, BACKDROP_ID))
        {
            roughness = 1.;
            material.baseColor = vec3(.015, .012, .012);
        }
         
        else
        {
            break;
        }
        
        material.specExponent = floor(max(1., (1. - pow(roughness, .15)) * 40000.));    
        material.specIntensity = 15.;
        
        pcol += integrate_lighting(surface, material, -surface.incomingRayDir);
        
        currSample.direction = reflect(surface.incomingRayDir, surface.normal);
        currSample.origin = surface.point + .01 * currSample.direction;
        
    }
    
    return pcol;   
}

// **************************************************************************
// MAIN COLOR

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    
    setup_globals();
    vec2 uv = fragCoord.xy / iResolution.xy;        
        
    // ----------------------------------
    // SAMPLING 
    
    float seed = g_frame + hash12( uv );
    //float seed = float(floor(float(g_frame)/10.));
    
    vec3 currPixelColor = calc_pixelColor( seed );    

    // ----------------------------------
    // FINAL GATHER 

    vec3 finalColor = vec3(0.);
    
    if (g_frame > .5)
    {
        finalColor = texture(iChannel0, uv).rgb;
    }
    
    finalColor += currPixelColor;
    
    fragColor = vec4(finalColor,1.0);
}
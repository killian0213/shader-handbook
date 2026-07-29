// Buffer A (buffer) — Creation Stone by mmerchante
// https://www.shadertoy.com/view/XdcyDM

// Buf A: Container raymarching

#define MAX_STEPS 50
#define MAX_STEPS_F float(MAX_STEPS)

#define FIXED_STEP_SIZE .025

#define MAX_DISTANCE 50.0
#define MIN_DISTANCE 4.0
#define EPSILON .025
#define EPSILON_MEDIUM .75
#define EPSILON_NORMAL .05

// hg_sdf
const vec3 GDFVectors[19] = vec3[19](
	vec3(1.0,.0,.0),
	vec3(.0,1.0,.0),
	vec3(.0,.0,1.0),
	vec3(.577,.577,.577),
	vec3(-.577,.577,.577),
	vec3(.577,-.577,.577),
	vec3(.577,.577,-.577),
	vec3(.0,.357,.934),
	vec3(.0,-.357,.934),
	vec3(.934,.0,.357),
	vec3(-.934,.0,.357),
	vec3(.357,.934,.0),
	vec3(-.357,.934,.0),
	vec3(.0,.851,.526),
	vec3(.0,-.851,.526),
	vec3(.526,.0,.851),
	vec3(-.526,.0,.851),
	vec3(.851,.526,.0),
	vec3(-.851,.526,.0)
);


float sdf(vec3 p)
{
	float d = 0.0;
    
    p = abs(p);
    
    d = max(d, dot(p, GDFVectors[2]));
    d = max(d, dot(p, GDFVectors[3]));
    d = max(d, dot(p, GDFVectors[4]));
    d = max(d, dot(p, GDFVectors[5]));
    d = max(d, dot(p, GDFVectors[6]));
    d = max(d, dot(p, GDFVectors[7]));
    d = max(d, dot(p, GDFVectors[8]));
    d = max(d, dot(p, GDFVectors[9]));
    d = max(d, dot(p, GDFVectors[10]));    
    d = max(d, dot(p, GDFVectors[11]));
    d = max(d, dot(p, GDFVectors[12]));
    d = max(d, dot(p, GDFVectors[13]));
    d = max(d, dot(p, GDFVectors[14]));
    d = max(d, dot(p, GDFVectors[15]));
    d = max(d, dot(p, GDFVectors[16]));    
    d = max(d, dot(p, GDFVectors[17]));
    d = max(d, dot(p, GDFVectors[18]));
    
    return (d - 3.0) * 1.25;
}

// ---------------------------------------------------------

struct Intersection
{
    float totalDistance;
    float mediumDistance;
    float sdf;
    float density;
    int materialID;
};
    
struct Camera
{
	vec3 origin;
    vec3 direction;
    vec3 left;
    vec3 up;
};
    
// ---------------------------------------------------------

Intersection Raymarch(Camera camera)
{    
    Intersection outData;
    outData.sdf = 0.0;
    outData.density = 0.0;
    outData.totalDistance = MIN_DISTANCE;
        
	for(int j = 0; j < MAX_STEPS; ++j)
	{
        vec3 p = camera.origin + camera.direction * outData.totalDistance;
		outData.sdf = sdf(p);

		outData.totalDistance += outData.sdf;
                
		if(outData.sdf < EPSILON || outData.totalDistance > MAX_DISTANCE)
            break;
	}
    
    return outData;
}

Camera GetCamera(vec2 uv, float zoom)
{
    float dist = 4.0 / zoom;
    float time = 2.9 + iTime * .2;
    
    vec3 target = vec3(0.0, 1.0, 0.0);
    vec3 p = vec3(0.0, 3.5, 0.0) + vec3(cos(time), 0.0, sin(time)) * dist;
        
    vec3 forward = normalize(target - p);
    vec3 left = normalize(cross(forward, vec3(0.0, 1.0, 0.0)));
    vec3 up = normalize(cross(forward, left));

    Camera cam;   
    cam.origin = p;
    cam.direction = normalize(forward - left * uv.x * zoom - up * uv.y * zoom);
    cam.up = up;
    cam.left = left;
        
    return cam;
}

vec3 sdfNormal(vec3 p, float epsilon)
{
    vec3 eps = vec3(epsilon, -epsilon, 0.0);
    
	float dX = sdf(p + eps.xzz) - sdf(p + eps.yzz);
	float dY = sdf(p + eps.zxz) - sdf(p + eps.zyz);
	float dZ = sdf(p + eps.zzx) - sdf(p + eps.zzy); 

	return normalize(vec3(dX,dY,dZ));
}

// https://www.shadertoy.com/view/Xts3WM
float curv(in vec3 p, in float w)
{
    vec2 e = vec2(-1., 1.) * w;
    
    float t1 = sdf(p + e.yxx), t2 = sdf(p + e.xxy);
    float t3 = sdf(p + e.xyx), t4 = sdf(p + e.yyy);
    
    return .25/e.y*(t1 + t2 + t3 + t4 - 4.0 * sdf(p));
}

vec3 triplanar(vec3 P, vec3 N)
{   
    vec3 Nb = abs(N);
    
    float b = (Nb.x + Nb.y + Nb.z);
    Nb /= vec3(b);
    
    vec3 c0 = textureLod(iChannel0, P.xy, 3.0).rgb * Nb.z;
    vec3 c1 = textureLod(iChannel0, P.yz, 3.0).rgb * Nb.x;
    vec3 c2 = textureLod(iChannel0, P.xz, 3.0).rgb * Nb.y;
    
    return c0 + c1 + c2;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = (-iResolution.xy + (fragCoord*2.0)) / iResolution.y;    
    
    // Cheating here...
    if(abs(uv.y) > .75)
    {
        fragColor = vec4(0.0);
        return;
    }
    
    Camera camera = GetCamera(uv, .5);
    Intersection isect = Raymarch(camera);
    
    vec3 p = camera.origin + camera.direction * isect.totalDistance;
    
    float c = curv(p, .15);
    float longC = curv(p, .45);
    vec3 normal = sdfNormal(p, EPSILON_NORMAL);
    
    vec3 tx = triplanar(p * .75, normal) + triplanar(p * 1.5, normal) * .2;
    tx = tx * 2.0 - 1.0;
    tx *= .025 + longC * .075;
        
    
    // By feeding the curvature into the normal and distance, we ad enough weirdness to make it plausible
    if(isect.sdf < EPSILON)
        isect.totalDistance -= c * 1.5;
    
    fragColor =vec4(normalize(normal + tx - c * .25), isect.totalDistance);
}
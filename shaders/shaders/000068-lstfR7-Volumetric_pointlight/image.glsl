// Image (image) — Volumetric pointlight by robobo1221
// https://www.shadertoy.com/view/lstfR7

//Sphere thingy with volumetrics by robobo1221

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

#define THICKNESS 1.0
#define SELF_SHADOWING
//#define CUSTOM_CAMERA_ANGLE

//#define USE_NOISE_FOG //Makes fog more realistic with 3d noise. 
				        //Really heavy on performance when SELF_SHADOWING is enabled

const vec3 scatterCoeff = vec3(0.3, 0.5, 1.0) * 0.5;
const int steps = 64;

const float farPlane = 10.0;
const float lightBrighness = 3.0;
const vec3 lightColor = vec3(1.0, 0.5, 0.15) * lightBrighness;

const float pi = acos(-1.0);
const float tau = pi * 2.0;

float bayer2(vec2 a){
    a = floor(a);
    return fract( dot(a, vec2(.5, a.y * .75)) );
}

float mod289(float x){return x - floor(x * (1.0 / 289.0)) * 289.0;}
vec4 mod289(vec4 x){return x - floor(x * (1.0 / 289.0)) * 289.0;}
vec4 perm(vec4 x){return mod289(((x * 34.0) + 1.0) * x);}

float noise(vec3 p){
    vec3 a = floor(p);
    vec3 d = p - a;
    d = d * d * (3.0 - 2.0 * d);

    vec4 b = a.xxyy + vec4(0.0, 1.0, 0.0, 1.0);
    vec4 k1 = perm(b.xyxy);
    vec4 k2 = perm(k1.xyxy + b.zzww);

    vec4 c = k2 + a.zzzz;
    vec4 k3 = perm(c);
    vec4 k4 = perm(c + 1.0);

    vec4 o1 = fract(k3 * (1.0 / 41.0));
    vec4 o2 = fract(k4 * (1.0 / 41.0));

    vec4 o3 = o2 * d.z + o1 * (1.0 - d.z);
    vec2 o4 = o3.yw * d.x + o3.xz * (1.0 - d.x);

    return o4.y * d.y + o4.x * (1.0 - d.y);
}

#define bayer4(a)   (bayer2( .5*(a))*.25+bayer2(a))
#define bayer8(a)   (bayer4( .5*(a))*.25+bayer2(a))
#define bayer16(a)  (bayer8( .5*(a))*.25+bayer2(a))
#define bayer32(a)  (bayer16(.5*(a))*.25+bayer2(a))
#define bayer64(a)  (bayer32(.5*(a))*.25+bayer2(a))
#define bayer128(a) (bayer64(.5*(a))*.25+bayer2(a))

mat3 rotationMatrix(vec3 axis, float angle)
{
    axis = normalize(axis);
    float s = sin(angle);
    float c = cos(angle);
    float oc = 1.0 - c;
    
    float xx = axis.x * axis.x;
    float yy = axis.y * axis.y;
    float zz = axis.z * axis.z;
    
    float xy = axis.x * axis.y;
    float xz = axis.x * axis.z;
    float zy = axis.z * axis.y;
    
    return mat3(oc * xx + c, oc * xy - axis.z * s, oc * xz + axis.y * s,
                oc * xy + axis.z * s, oc * yy + c, oc * zy - axis.x * s, 
                oc * xz - axis.y * s, oc * zy + axis.x * s, oc * zz + c);
}

vec3 generateWorldSpacePosition(vec2 p)
{
	    vec3 position = vec3(1.0 - p.x, p.yx) * 2.0 - vec3(0.0, 1.0, 0.0);
    
    	float depth = clamp(1.0 / max(1e-32,-position.y), 0.0, farPlane); //Fake depth
    
        position = position * depth;
	
	return position;
}

vec3 generateWorldSpacePosition(vec2 p, mat3 rotateV, mat3 rotateH)
{
	vec3 position = rotateH * (rotateV * (vec3(1.0 - p.x, p.yx) * 2.0 - vec3(0.0, 1.0, 0.0)));
	
	float depth = clamp(1.0 / max(1e-32,-position.y), 0.0, farPlane); //Fake depth
	
	return position * depth;
}

float sphere(vec3 p, vec3 o)
{
	return 1.0 - distance(p, o);
}

vec3 getLight(vec3 p, vec3 lp)
{
	float dist = distance(p, lp);
	      dist *= dist;
	
	return (1.0 / dist) * lightColor;	
}

float calculateOD(vec3 p)
{
    #ifndef USE_NOISE_FOG
	return THICKNESS;
    #endif
    
    float pattern = noise(p - time) * 0.5;
          pattern += noise(p * 2.0 + iTime) * 0.25;
          pattern += noise(p * 4.0 - iTime) * 0.125;
    
	return (pattern*pattern * 4.0 + 0.25) * THICKNESS;
}

vec3 selfShadow(vec3 p, vec3 o)
{
    #ifndef SELF_SHADOWING
    	return vec3(1.0);
    #endif
    
    const int steps = 8;
    const float iSteps = 1.0 / float(steps);
    
    vec3 increment = o * iSteps;
    vec3 position = p;
    
    vec3 transmittance = vec3(1.0);
    
    for (int i = 0; i < steps; i++)
    {
        float od = calculateOD(position);
		position += increment;
        
        transmittance += od;
    }
    
    return exp2(-transmittance * scatterCoeff * iSteps);
}


vec3 calculateVolumetricLight(vec3 p, vec3 o, vec3 od)
{
	
	vec3 light = getLight(p, o) * selfShadow(p, o);
	vec3 sphere = smoothstep(0.8, 0.81, sphere(p, o)) * lightColor*10.0;
	
	return (light * od + sphere);
}

vec3 getVolumetricRaymarcher(vec3 p, vec3 o, float dither, vec3 background)
{
	const float isteps = 1.0 / float(steps);
	
	vec3 increment = -p * isteps;
	vec3 marchedPosition = increment * dither + p;
	
	float stepLength = length(increment);
	
	vec3 scatter = vec3(0.0);
	vec3 transMittance = vec3(1.0);
	vec3 currentTransmittence = vec3(1.0);
	
	for (int i = 0; i < steps; i++){
		vec3 od = calculateOD(marchedPosition) * scatterCoeff * stepLength;
		
		marchedPosition += increment;
		
		scatter += calculateVolumetricLight(marchedPosition, o, od) * currentTransmittence;
		
		currentTransmittence *= exp2(od);
		transMittance *= exp2(-od);
	}
	
	return background * transMittance + scatter * transMittance;
}

vec3 robobo1221sTonemap(vec3 x){
    return x / sqrt(x*x + 1.0);
}


void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
	vec2 uv = fragCoord.xy / iResolution.xy;
    vec2 cameraDir = iMouse.xy / iResolution.xy;
         cameraDir = cameraDir.x == 0.0 ? vec2(0.5, 0.25) : cameraDir;
    
    #ifdef CUSTOM_CAMERA_ANGLE
        vec2 camRotDir = cameraDir;
             camRotDir = radians((camRotDir * vec2(360.0, 180.0) - vec2(0.0, 90.0)));
             camRotDir.y =- camRotDir.y;
    	vec3 originOffset = vec3(sin(iTime) + 1.0, 0.3, cos(iTime));
             
             cameraDir = vec2(0.0);
    #else
    	vec2 camRotDir = vec2(0.0);
        vec3 originOffset = vec3(0.0, 0.3, 0.0);
    #endif
    
    mat3 rotateH = rotationMatrix(vec3(0.0, 1.0, 0.0), camRotDir.x);
    mat3 rotateV = rotationMatrix(vec3(-1.0, 0.0, 1.0), camRotDir.y);

	vec3 position = generateWorldSpacePosition(uv, rotateV, rotateH);
	vec3 origin = generateWorldSpacePosition(cameraDir) + originOffset;
	
	vec3 worldVector = normalize(position);
	vec3 worldOriginVector = normalize(origin);
	
	vec3 color = vec3(floor(length(cos(position.xz * 10.0)))) * 0.9 + 0.1;
	     color *= getLight(position, origin) * selfShadow(position, origin);
	
	     color = getVolumetricRaymarcher(position, origin, bayer16(gl_FragCoord.xy), color);

	fragColor = vec4(robobo1221sTonemap(color), 1.0 );
}
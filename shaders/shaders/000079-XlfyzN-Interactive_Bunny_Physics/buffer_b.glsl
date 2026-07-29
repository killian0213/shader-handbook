// Buffer B (buffer) — Interactive Bunny Physics by ThomasSchander
// https://www.shadertoy.com/view/XlfyzN


#define saturate(x) clamp(x, 0.0, 1.0)
#define PI 3.14159265359

#define DOF

#define GORE_MODE

// Contains quaterion code from https://www.shadertoy.com/view/lsG3W3
#define txBuf iChannel0
#define txSize iChannelResolution[0].xy

float randomSeed = 0.0;

float hash( float n )
{
    return fract(sin(n)*43758.5453);
}

float floatRand()
{
	return fract(sin(randomSeed += 0.1)*43758.5453123);
}

vec2 floatRand2()
{
	return fract(sin(vec2(randomSeed+=0.1,randomSeed+=0.1))*vec2(43758.5453123,22578.1459123));
}

mat3 QtToRMat (vec4 q) 
{
  mat3 m;
  float a1, a2, s;
  q = normalize (q);
  s = q.w * q.w - 0.5;
  m[0][0] = q.x * q.x + s;  m[1][1] = q.y * q.y + s;  m[2][2] = q.z * q.z + s;
  a1 = q.x * q.y;  a2 = q.z * q.w;  m[0][1] = a1 + a2;  m[1][0] = a1 - a2;
  a1 = q.x * q.z;  a2 = q.y * q.w;  m[2][0] = a1 + a2;  m[0][2] = a1 - a2;
  a1 = q.y * q.z;  a2 = q.x * q.w;  m[1][2] = a1 + a2;  m[2][1] = a1 - a2;
  return 2. * m;
}

vec4 RMatToQt (mat3 m)
{
  vec4 q;
  const float tol = 1e-6;
  q.w = 0.5 * sqrt (max (1. + m[0][0] + m[1][1] + m[2][2], 0.));
  if (abs (q.w) > tol) q.xyz =
     vec3 (m[1][2] - m[2][1], m[2][0] - m[0][2], m[0][1] - m[1][0]) / (4. * q.w);
  else {
    q.x = sqrt (max (0.5 * (1. + m[0][0]), 0.));
    if (abs (q.x) > tol) q.yz = vec2 (m[0][1], m[0][2]) / q.x;
    else {
      q.y = sqrt (max (0.5 * (1. + m[1][1]), 0.));
      if (abs (q.y) > tol) q.z = m[1][2] / q.y;
      else q.z = 1.;
    }
  }
  return normalize (q);
}

const float txRow = 128.;

vec4 Loadv4 (int idVar)
{
  float fi;
  fi = float (idVar);
  return texture (txBuf, (vec2 (mod (fi, txRow), floor (fi / txRow)) + 0.5) /
     txSize);
}

void Savev4 (int idVar, vec4 val, inout vec4 fCol, vec2 fCoord)
{
  vec2 d;
  float fi;
  fi = float (idVar);
  d = abs (fCoord - vec2 (mod (fi, txRow), floor (fi / txRow)) - 0.5);
  if (max (d.x, d.y) < 0.5) fCol = val;
}

float sdPlane(in vec3 p) {
    return p.y;
}

float sdSphere(in vec3 p, float s) {
    return length(p) - s;
}

float sdTorus(in vec3 p, in vec2 t) {
    return length(vec2(length(p.xz) - t.x, p.y)) - t.y;
}

vec2 opUnion(vec2 d1, vec2 d2) {
    return d1.x < d2.x ? d1 : d2;
}

float smin( float a, float b, float k )
{
    float h = clamp( 0.5+0.5*(b-a)/k, 0.0, 1.0 );
    return mix( b, a, h ) - k*h*(1.0-h);
}

float sdEllipsoid( in vec3 p, in vec3 r )
{
    return (length( p/r ) - 1.0) * min(min(r.x,r.y),r.z);
}

float udBox( vec3 p, vec3 b )
{
  return length(max(abs(p)-b,0.0));
}

float combine(float a, float b)
{
    return smin(a,b, 0.07);
}

bool showEar = true;

#define NUM_PHYS_SPHERES 15
vec4 physProxy[] = vec4[](vec4(0.0336538, -0.213592, 0.0843372, 0.35474),
vec4(-0.192308, -0.0970871, 0.0903615, 0.262483),
vec4(-0.120192, 0.218447, -0.108434, 0.158823),
vec4(-0.278846, 0.131068, 0.0361445, 0.169385),
vec4(-0.0144231, 0.315534, -0.168675, 0.0801684),
vec4(-0.341346, 0.106796, 0.222892, 0.156275),
vec4(-0.192308, -0.354369, 0.253012, 0.126427),
vec4(-0.225962, -0.373786, 0.0361445, 0.127061),
vec4(0.317308, -0.315534, 0.108434, 0.146499),
vec4(-0.25, -0.417476, 0.168675, 0.0725712),
vec4(-0.0528846, 0.393204, -0.108434, 0.0474471),
vec4(-0.110577, -0.42233, -0.162651, 0.0710944),
vec4(-0.317308, 0.315534, -0.26506, 0.0679328),
vec4(-0.307692, 0.349515, -0.379518, 0.0577368),
vec4(-0.293269, 0.276699, -0.156627, 0.0891464));

mat3 earRotation;
vec3 earPos;
mat3 earMomentum;
vec3 earVelocity;  

mat3 bunnyRotation;
vec3 bunnyPos;

vec3 earDelta = vec3(0.185, 0.8, 0.25);

vec2 scene(in vec3 pO) {
    vec3 p = pO;
    vec2 sceneShape = vec2(sdPlane(p), 1.0);
    p -= bunnyPos;
    p = bunnyRotation*p;
    float shape = 1e9;    
    p.y -= 0.15;
#if 1
    p += vec3(0.5);    
    shape = combine(shape, sdEllipsoid(p-vec3(0.579787, 0.326087, 0.587838), vec3(0.306784, 0.294628, 0.319604)));
    shape = combine(shape, sdEllipsoid(p-vec3(0.212766, 0.478261, 0.614865), vec3(0.142153, 0.301739, 0.198772)));  
    shape = combine(shape, sdEllipsoid(p-vec3(0.356383, 0.793478, 0.47973), vec3(0.0686655, 0.0734181, 0.049516)));
    shape = combine(shape, sdEllipsoid(p-vec3(0.31383, 0.0652174, 0.75), vec3(0.121429, 0.043445, 0.111769)));
    shape = combine(shape, sdEllipsoid(p-vec3(0.43617, 0.847826, 0.398649), vec3(0.0525406, 0.0724031, 0.0349506)));
    shape = combine(shape, sdEllipsoid(p-vec3(0.164894, 0.597826, 0.662162), vec3(0.116986, 0.180009, 0.232665)));
    shape = combine(shape, sdEllipsoid(p-vec3(0.531915, 0.277174, 0.290541), vec3(0.141038, 0.143824, 0.0819466)));
    shape = combine(shape, sdEllipsoid(p-vec3(0.797872, 0.173913, 0.587838), vec3(0.152242, 0.124905, 0.157487)));  
    shape = combine(shape, sdEllipsoid(p-vec3(0.521277, 0.0978261, 0.581081), vec3(0.305612, 0.0526198, 0.299388))); 
    shape = combine(shape, sdEllipsoid(p-vec3(0.462766, 0.0815217, 0.837838), vec3(0.068863, 0.0449702, 0.0720527)));
    shape = combine(shape, sdEllipsoid(p-vec3(0.356383, 0.375, 0.47973), vec3(0.260118, 0.217964, 0.14091)));
    shape = combine(shape, sdEllipsoid(p-vec3(0.5, 0.891304, 0.331081), vec3(0.0219774, 0.0667988, 0.0356658)));
    shape = combine(shape, sdEllipsoid(p-vec3(0.287234, 0.73913, 0.533784), vec3(0.0541389, 0.0804187, 0.054103)));
    shape = combine(shape, sdEllipsoid(p-vec3(0.579787, 0.277174, 0.878378), vec3(0.120201, 0.160738, 0.0550283)));
    shape = combine(shape, sdEllipsoid(p-vec3(0.393617, 0.820652, 0.445946), vec3(0.0665282, 0.0758984, 0.0433889)));
    shape = combine(shape, sdEllipsoid(p-vec3(0.0851064, 0.576087, 0.797297), vec3(0.0339068, 0.086274, 0.0683804))); 
        
    if(!showEar)
    {
        p = pO;
        p -= earPos;
   	 	p = earRotation*p;
        p += earDelta;
    }
    
    float earShape = 1e9;
    earShape = combine(earShape, sdEllipsoid(p-vec3(0.18617, 0.88587, 0.101351), vec3(0.0194326, 0.0285867, 0.0526812)));
    earShape = combine(earShape, sdEllipsoid(p-vec3(0.180851, 0.809783, 0.283784), vec3(0.0473297, 0.0466274, 0.0946735)));
    earShape = combine(earShape, sdEllipsoid(p-vec3(0.196809, 0.815217, 0.168919), vec3(0.0283318, 0.0726224, 0.0925792)));
    earShape = combine(earShape, sdEllipsoid(p-vec3(0.18617, 0.744565, 0.385135), vec3(0.0512605, 0.0493519, 0.184969))); 
    
    
    if(!showEar)
    {     
        shape = min(shape, earShape);
    }
    else
    {
        shape = combine(shape, earShape);
    }
           
#else
    for(int i = 0; i < 12; i++)
    	shape = min(shape, sdSphere(p-physProxy[i].xyz, physProxy[i].w));
    if(!showEar)
    {
        p = pO;
        p -= earPos;
   	 	p = earRotation*p;
        p += earDelta-vec3(0.5);
    }
    for(int i = 12; i < NUM_PHYS_SPHERES; i++)
    	shape = min(shape, sdSphere(p-physProxy[i].xyz, physProxy[i].w));
#endif

    return opUnion(vec2(shape, 0.0), sceneShape);
}

float shadow(in vec3 origin, in vec3 direction) {
    float hit = 1.0;
    float t = 0.02;
    
    for (int i = 0; i < 1000; i++) {
        vec2 h = scene(origin + direction * t);
        if (h.x < 0.001) return 0.0;
        t += h.x;
        hit = min(hit, 15.0 * h.x / t);
        if (t >= 4.0) break;
    }

    return clamp(hit, 0.0, 1.0);
}

vec2 traceRay(in vec3 origin, in vec3 direction) {
    float material = -1.0;

    float t = 0.004;
    
    for (int i = 0; i < 1000; i++) {
        vec2 hit = scene(origin + direction * t);
        if (hit.x < 0.001 || t > 20.0) break;
        t += hit.x;
        material = hit.y;
    }

    if (t > 20.0) {
        material = -1.0;
    }

    return vec2(t, material);
}

vec3 normal(in vec3 position) {
    vec3 epsilon = vec3(0.001, 0.0, 0.0);
    vec3 n = vec3(
          scene(position + epsilon.xyy).x - scene(position - epsilon.xyy).x,
          scene(position + epsilon.yxy).x - scene(position - epsilon.yxy).x,
          scene(position + epsilon.yyx).x - scene(position - epsilon.yyx).x);
    return normalize(n);
}

float Diffuse_Burley( float linearRoughness, float NoV, float NoL, float VoH, float LoH)
{
	float FD90 = 0.5 + 2.0 * VoH * VoH * linearRoughness;
	float FdV = 1.0 + (FD90 - 1.0) * exp2( (-5.55473 * NoV - 6.98316) * NoV );
	float FdL = 1.0 + (FD90 - 1.0) * exp2( (-5.55473 * NoL - 6.98316) * NoL );
	float epicNormalization = 1.0 - linearRoughness * 0.333;
	return FdV * FdL * epicNormalization; // 1/PI * NoL must still be applied
}

float calcAO( in vec3 pos, in vec3 nor )
{
	float occ = 0.0;
    float sca = 1.0;
    for( int i=0; i<5; i++ )
    {
        float hr = 0.01 + 0.12*float(i)/4.0;
        vec3 aopos =  nor * hr + pos;
        float dd = scene( aopos ).x;
        occ += -(dd-hr)*sca;
        sca *= 0.95;
    }
    return clamp( 1.0 - occ, 0.0, 1.0 );    
}

float HenyeyGreenstein(float mu, float inG)
{
	return (1.-inG * inG)/(pow(1.+inG*inG - 2.0 * inG*mu, 1.5)*4.0* PI);
}
float Schlick (in float f0 , in float f90 , in float cosT )
{
	return f0 + ( f90 - f0 ) * pow (1.0 - cosT , 5.0);
}
float Smith( float roughness, float NoV, float NoL )
{
	float a = roughness*roughness;
	float a2 = a*a;
	float SmithV = NoL * (NoV * (1. - a2) + a2);
	float SmithL = NoV * (NoL * (1. - a2) + a2);
	return 0.5/(SmithV + SmithL);
}

vec3 TangentToWorld( vec3 Vec, vec3 TangentZ )
{
	vec3 UpVector = abs(TangentZ.z) < 0.999 ? vec3(0,0,1) : vec3(1,0,0);
	vec3 TangentX = normalize( cross( UpVector, TangentZ ) );
	vec3 TangentY = cross( TangentZ, TangentX );
	return TangentX * Vec.x + TangentY * Vec.y + TangentZ * Vec.z;
}

float D_GGX( float roughness, float NoH )
{
	float m = roughness * roughness;
	float m2 = m*m;
	float f = ( NoH * m2 - NoH ) * NoH + 1.;
	return m2 / (f*f);
}

vec3 blinnImportanceSampling(vec2 sampling, float exponent)
{
	float phi = 2.0 * PI * sampling.x;
	float cosTheta = pow(1.0-sampling.y, 1.0 / (exponent + 1.0));
	float sinTheta = sqrt(1. - cosTheta * cosTheta);
	return vec3(sinTheta * cos(phi), sinTheta * sin(phi), cosTheta);
}

vec3 sunDirection = normalize(vec3(0.6, 0.7, -0.7));
const vec3 sky = vec3(0.6, 0.85, 1.0);
vec3 background;
vec3 sun = vec3(1.0, 0.9, 0.8);

mat3 setCamera(in vec3 origin, in vec3 target) {
    vec3 forward = normalize(target - origin);
    vec3 orientation = vec3(0.0, 1.0, 0.0);
    vec3 left = normalize(cross(forward, orientation));
    vec3 up = normalize(cross(left, forward));
    return mat3(left, up, forward);
}

vec2 GetSequenceHalton(int i)
{
    i %= 8;
	vec2 result = vec2(0);
	ivec2 base = ivec2(2, 3);
	vec2 f = vec2(1.0) / vec2(base);
  ivec2 index = ivec2(i, i);
  while (index.x > 0 || index.y > 0)
  {
		result = result + f * vec2(ivec2(index) % base);
		index = index / base;
		f = f / vec2(base); 
	}
  return result;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    
    randomSeed = float(iFrame) + dot(fragCoord, vec2(12.245, 93.2125));
    vec4 motionVals = Loadv4(1);
    
    earRotation = QtToRMat(Loadv4(6));
    earPos = Loadv4(7).xyz;
    bunnyRotation = QtToRMat(Loadv4(0));
    bunnyPos = Loadv4(3).xyz; 
       
    vec2 uv = fragCoord / vec2(iResolution.xy);
    vec2 jitter = GetSequenceHalton(iFrame)-vec2(0.5);
    vec2 p = -1.0 + 2.0 * (fragCoord.xy-jitter) / iResolution.xy;
    p.x *= iResolution.x / iResolution.y;
    
    if(motionVals.y > 0.0)
        showEar = false;
    
    if(uv.y < 0.01 && -motionVals.y/0.05 > uv.x)
    {
        fragColor = vec4(0.8, 0.7, 0.6, 0.0);
        return;
    }

    vec3 origin = vec3(0.0, 0.8+sqrt(motionVals.x)*0.08, 0.0);
    vec3 target = vec3(0.0, 0.2, 0.0);  
    
	const float camRad = 3.5;   
    float rotParam = -sin(0.04*iTime);
    origin.x += camRad * cos(3.6+rotParam);
    origin.z += camRad * sin(3.6+rotParam);    
    
#ifdef DOF
    vec3 t1 = cross(origin-target, vec3(0.0, 1.0, 0.0));
    vec3 t2 = cross(origin-target, t1);
    float MOBLUR_STRENGTH = 0.0018;
    origin += MOBLUR_STRENGTH*(floatRand()-0.5) * t1;
    origin += MOBLUR_STRENGTH*(floatRand()-0.5) * t2;
#endif

    mat3 toWorld = setCamera(origin, target);
    vec3 direction = toWorld * normalize(vec3(p.xy, 2.2));

    // Render scene
    float distance = 0.0;
    background = sky - direction.y * 1.0;
	background += 8.0*vec3(1.0, 0.4, 0.2)*HenyeyGreenstein(dot(sunDirection, direction), 0.9);
    vec3 color = background;
    vec2 hit = traceRay(origin, direction);

    // We've hit something in the scene
    if (hit.y != -1.0) {
        vec3 position = origin + hit.x * direction;

        vec3 v = normalize(-direction);
        vec3 n = normal(position);         

        vec3 baseColor = vec3(0.93, 0.86, 0.87);
        vec3 skySpec = vec3(0.0);
        float roughness = 0.9;
        float ao = calcAO(position, n);
        if (hit.y == 1.0)  {
            baseColor = 0.5*pow(textureLod(iChannel1, 0.4*position.zx, 0.0).xyz, vec3(1.8));
            float specExp = 160.0;
            vec2 deltaBlood = position.xz-motionVals.zw;
            float timeDelta = iTime - motionVals.y;
            if(!showEar && 0.14-dot(deltaBlood,deltaBlood)+0.03*(1.0-exp(-0.18*timeDelta)) > baseColor.r)
            {
                baseColor = vec3(0.5, 0.5, 0.5);
#ifdef GORE_MODE
                baseColor = vec3(0.5, 0.02, 0.02);
#endif
                roughness = 0.01;
                specExp = 50000.0;
            }
            else
            {
            	n = normalize(n+0.1*(textureLod(iChannel2, 0.9*position.xz, 0.0).xyz-vec3(0.5)));            
            	roughness = max(0.1, 1.0-2.6*baseColor.b);
            }
            vec3 h = (TangentToWorld(blinnImportanceSampling(floatRand2(), specExp), n));
            float NoV = abs(dot(n, v)) + 1e-5;
            vec3 l = reflect(-v, h);
        	float NoL = saturate(dot(n, l));
        	float NoH = saturate(dot(n, h));
            vec2 specRay = traceRay(position, l);
            skySpec = (specRay.y != -1.0) ? 0.6*vec3(saturate(1.0-exp(-2.0*specRay.x))) : sky;
            skySpec *= Schlick(0.04, 1.0, NoV);
            skySpec *= step(0.5, ao);
        } 
        
        vec3 l = sunDirection;
        vec3 h = normalize(v + l);
        float NoV = abs(dot(n, v)) + 1e-5;
        float NoL = saturate(dot(n, l));
        float NoH = saturate(dot(n, h));
        float LoH = saturate(dot(l, h));
        float VoH = saturate(dot(v, h));        
        float attenuation = shadow(position, l);
        color = baseColor.rgb * (sun*attenuation*Diffuse_Burley(roughness*roughness, NoV, NoL, VoH, LoH)*NoL + ao*(0.5+0.5*n.y)*0.8*sky + 0.1*sun * max(0.0, -n.y)*1.0*(1.0-exp(-3.0*position.y)));       
        color += NoL*sun*attenuation * D_GGX(roughness, NoH)*Schlick(0.04, 1.0, NoV)*Smith(roughness, NoV, NoL);
        color += skySpec;
        distance = hit.x;
    }    
	// Exponential distance fog
    color = mix(background,color, exp(-0.15 * max(0.0, distance-4.0)));        
	color += 6.0*vec3(1.0, 0.4, 0.2)*HenyeyGreenstein(dot(sunDirection, direction), 0.95);
    fragColor = vec4(color, 1.0);
}
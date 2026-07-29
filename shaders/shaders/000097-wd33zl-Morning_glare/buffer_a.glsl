// Buffer A (buffer) — Morning glare by loicvdb
// https://www.shadertoy.com/view/wd33zl

#define Epsilon .002
#define RenderDistance 3.0
#define IoR 1.5
#define GlassColor vec3(1.0, .9, .6)

float Power = 8.0;

vec3 CamPos = vec3(0, .9, -2.5);
vec3 CamRot = vec3(.15, .1, .0);
float CamFocalLength = 2.0;


float distanceEstimation(vec3 pos) {
    float r = length(pos);
    if(r > 1.5) return r-1.2;
    vec3 z = pos;
	float dr = 1.0, theta, phi;
	for (int i = 0; i < 100; i++) {
		r = length(z);
		if (r>1.5) break;
		theta = acos(z.y/r);
		phi = atan(z.z,z.x);
		dr =  pow( r, Power-1.0)*Power*dr + 1.0;
		theta *= Power;
		phi *= Power;
		z = pow(r,Power)*vec3(sin(theta)*cos(phi), cos(theta), sin(phi)*sin(theta)) + pos;
	}
	return 0.5*log(r)*r/dr;
}

vec3 normalEstimation(vec3 pos){
   
  vec3 xDir = vec3(Epsilon, 0.0, 0.0);
  vec3 yDir = vec3(0.0, Epsilon, 0.0);
  vec3 zDir = vec3(0.0, 0.0, Epsilon);

  float normalX = distanceEstimation(pos + xDir)
                - distanceEstimation(pos - xDir);
  float normalY = distanceEstimation(pos + yDir)
                - distanceEstimation(pos - yDir);
  float normalZ = distanceEstimation(pos + zDir)
                - distanceEstimation(pos - zDir);

  return normalize(vec3(normalX, normalY, normalZ));
}

vec3 background(vec3 dir){
    if(dot(dir, normalize(vec3(-.5, .2, 1)))>.995) return vec3(5.0);
    return texture(iChannel0, dir).rgb*1.5;
}

float fresnel(vec3 dir, vec3 normal) {
  float cosi = dot(dir, normal);
  float etai = 1.0, etat = IoR;
  if (cosi > 0.0) {
    float tmp = etai;
    etai = etat;
    etat = tmp;
  }
  float sint = etai / etat * sqrt(max(0.0, 1.0 - cosi * cosi));
  if (sint >= 1.0) return 1.0;
  float cost = sqrt(max(0.0, 1.0 - sint * sint));
  cosi = abs(cosi);
  float sqrtRs = ((etat * cosi) - (etai * cost)) / ((etat * cosi) + (etai * cost));
  float sqrtRp = ((etai * cosi) - (etat * cost)) / ((etai * cosi) + (etat * cost));
  return (sqrtRs * sqrtRs + sqrtRp * sqrtRp) / 2.0;
}

bool hit(inout vec3 pos, in vec3 dir, out vec3 normal){
    for(int i = 0; i < 500; i++){
        float dist = distanceEstimation(pos);
        if(dist < Epsilon) break;
        if(dist > RenderDistance) return false;
        pos += dist*dir;
    }
    for(int i = 0; i < 4; i++){
        float dist = distanceEstimation(pos)-Epsilon;
        pos += dist*dir;
    }
    normal = normalEstimation(pos);
    return true;
}

vec3 reflectCol(vec3 dir, vec3 normal){
	return background(reflect(dir, normal));
}

vec3 refractCol(vec3 dir, vec3 normal){
    return GlassColor * vec3(background(refract(dir, normal, 0.90/IoR)).r,
                             background(refract(dir, normal, 1.00/IoR)).g,
                             background(refract(dir, normal, 1.10/IoR)).b);
}

vec3 glassCol(vec3 dir, vec3 normal){
    float fres = fresnel(dir, normal);
    return (1.0-fres)*refractCol(dir, normal) + fres*reflectCol(dir, normal);
}

vec4 colorAndDepth(vec3 pos, vec3 dir){
    vec3 normal;
    if(hit(pos, dir, normal)){
        return vec4(max(glassCol(dir, normal), vec3(0)), length(pos-CamPos));
    }
   	return vec4(background(dir), RenderDistance);
}

mat3 rotationMatrix(vec3 rotEuler){
    float c = cos(rotEuler.x), s = sin(rotEuler.x);
    mat3 rx = mat3(1, 0, 0, 0, c, -s, 0, s, c);
    c = cos(rotEuler.y), s = sin(rotEuler.y);
    mat3 ry = mat3(c, 0, -s, 0, 1, 0, s, 0, c);
    c = cos(rotEuler.z), s = sin(rotEuler.z);
    mat3 rz = mat3(c, -s, 0, s, c, 0, 0, 0, 1);
    
    return rz * rx * ry;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord ){
    
    float time = iTime;
    
    vec2 uv = (fragCoord-iResolution.xy/2.0) / iResolution.y;
    
    CamRot.y += time/2.0;
    CamPos *= rotationMatrix(vec3(0, time/2.0, 0));
    
    if( iMouse.z > 0.0 )
        CamRot.y += (.5-iMouse.x/iResolution.x)*.75;
    
    vec3 rayDir = normalize(vec3(uv, CamFocalLength)) * rotationMatrix(CamRot);
    
    fragColor = colorAndDepth(CamPos, rayDir);
}
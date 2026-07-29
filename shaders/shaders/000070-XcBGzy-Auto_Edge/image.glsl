// Image (image) — Auto Edge by PauloFalcao
// https://www.shadertoy.com/view/XcBGzy

// Auto Edge
//
// By PauloFalcao
//
// Edges are colored based on the difference between the original SDF and a blured SDF
//
// It's also possible to deform the edges using a noise function
// based on this difference but it's much lower.
//
// The blurred SDF method is explained here https://www.shadertoy.com/view/mdc3RS
//

struct material {
  vec3 baseColor;
  float specular;
  vec3 normal;
};

//https://iquilezles.org/articles/distfunctions
float sdRoundBox( vec3 p, vec3 b, float r )
{
  vec3 q = abs(p) - b;
  return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0) - r;
}
float opSmoothUnion( float d1, float d2, float k )
{
    float h = clamp( 0.5 + 0.5*(d2-d1)/k, 0.0, 1.0 );
    return mix( d2, d1, h ) - k*h*(1.0-h);
}
float opSmoothSubtraction( float d1, float d2, float k )
{
    float h = clamp( 0.5 - 0.5*(d2+d1)/k, 0.0, 1.0 );
    return mix( d2, -d1, h ) + k*h*(1.0-h);
}
vec3 opRepLim(vec3 p,vec3 c,vec3 l){
    p+=(c*l)/2.0;
    return p-c*clamp(floor(p/c+0.5),vec3(0.0),l);
}


vec2 twist_rot(vec2 v, float a) {
	float s = sin(a);
	float c = cos(a);
	mat2 m = mat2(vec2(c, -s),vec2(s, c));
	return m * v;
}

//from Dave_Hoskins https://www.shadertoy.com/view/4djSRW
vec3 hash33(vec3 p3)
{
	p3 = fract(p3 * vec3(.1031,.11369,.13787));
    p3 += dot(p3, p3.yxz+19.19);
    return -1.0 + 2.0 * fract(vec3((p3.x + p3.y)*p3.z, (p3.x+p3.z)*p3.y, (p3.y+p3.z)*p3.x));
}

//from nikat https://www.shadertoy.com/view/XsX3zB
float simplex_noise(vec3 p)
{
    const float K1 = 0.333333333;
    const float K2 = 0.166666667;
    
    vec3 i = floor(p + (p.x + p.y + p.z) * K1);
    vec3 d0 = p - (i - (i.x + i.y + i.z) * K2);
    
    vec3 e = step(vec3(0.0), d0 - d0.yzx);
	  vec3 i1 = e * (1.0 - e.zxy);
	  vec3 i2 = 1.0 - e.zxy * (1.0 - e);
    
    vec3 d1 = d0 - (i1 - 1.0 * K2);
    vec3 d2 = d0 - (i2 - 2.0 * K2);
    vec3 d3 = d0 - (1.0 - 3.0 * K2);
    
    vec4 h = max(0.6 - vec4(dot(d0, d0), dot(d1, d1), dot(d2, d2), dot(d3, d3)), 0.0);
    vec4 n = h * h * h * h * vec4(dot(d0, hash33(i)), dot(d1, hash33(i + i1)), dot(d2, hash33(i + i2)), dot(d3, hash33(i + 1.0)));
    
    return dot(vec4(31.316), n);
}

#define fbm_iterations 6
float fbm(vec3 coord, float persistence) {
	float normalize_factor = 0.0;
	float value = 0.0;
	float scale = 1.0;
	float size = 1.0;
	for (int i = 0; i < fbm_iterations; i++) {
		value += simplex_noise(coord*size) * scale;
		normalize_factor += scale;
		size *= 2.0;
		scale *= persistence;
	}
	return value / normalize_factor;
}

//Rotation
vec2 rot(vec2 p,float f){
    float s=sin(f);float c=cos(f);
    return p*mat2(c,-s,s,c);
}

vec3 obj_trans(vec3 p){
  p.xz=rot(p.xz,-iTime*0.5);
  return p;
}


float obj_sdf_a(vec3 p){
  vec3 t1=p;
  t1.xz=twist_rot(t1.xz,t1.y*1.2);
  float d1=sdRoundBox(t1,vec3(0.35,1.4,0.35),0.1);
  vec3 t2=opRepLim(t1-vec3(0.0,0.6,0.0),vec3(2.0,0.5,2.0),vec3(0.0,3.0,0.0));
  float d2=opSmoothUnion(length(t2.yz)-0.17,length(t2.xy)-0.17,0.14);
  float d3=opSmoothSubtraction(d2,d1,0.1);
  vec3 t3=p;
  t3.y+=1.2;
  float d4=sdRoundBox(t3,vec3(1.3,0.4,1.3),0.05);
  return opSmoothUnion(d3,d4,0.6);
  return d3;
}

float obj_sdf(vec3 p){
  p=obj_trans(p);
  return obj_sdf_a(p);
}

#define blur_iterations 55
// blur obj is sdf_a
// b is the blur amount
// f is just the bounding object size
//   so it only blurs when close to the object
float blursdf3d(/*obj vec3->float*/in vec3 p,in float b,float f){
    /*obj vec3->float = sdf_a*/
	float a=0.0;
	float d=obj_sdf(p);
	if (d<b*f){
        /*iterations*/
		for(int i=0;i<blur_iterations;i++){
	        float y=1.0-2.0*(float(i)/float(blur_iterations));
	        float r=sqrt(1.0-y*y);
	        float t=2.39996322973*float(i);
			a+=obj_sdf(p+vec3(cos(t)*r,y,sin(t)*r)*b);
		}
	} else{
		return d;
	}
	return a/float(blur_iterations);
}


const float cgrad0_0_pos = 0.427273005;
const vec3 cgrad0_0_col = vec3(1.000000000, 0.685059309, 0.496093750);
const float cgrad0_1_pos = 0.709090978;
const vec3 cgrad0_1_col = vec3(0.472656250, 0.129241943, 0.129241943);
vec3 color_grad0(float x) {
  if (x <  cgrad0_0_pos) {
    return cgrad0_0_col;
  } else if (x < cgrad0_1_pos) {
    return mix(cgrad0_0_col, cgrad0_1_col, ((x-cgrad0_0_pos)/(cgrad0_1_pos-cgrad0_0_pos)));
  }
  return cgrad0_1_col;
}

vec3 calcnormal(vec3 p){  
  const vec2 e=vec2(0.001,-0.001);
  float x=obj_sdf(p+e.xyy);
  float y=obj_sdf(p+e.yxy);
  float z=obj_sdf(p+e.yyx);
  return normalize(vec3(x-y-z,-x+y-z,-x-y+z)+obj_sdf(p+e.xxx));
}

material obj_mat3d(vec3 p){
    material m;
    float o0=obj_sdf(p);
    float o1=blursdf3d(p,0.05,0.5);
    float diff=clamp((o1-o0)*100.0,0.0,1.0);
    vec3 mp=p;
    mp=obj_trans(p);
    float n0=fbm(mp*6.5,0.5)*0.5+0.5;
    float n1=fbm((mp+vec3(10.0))*6.5,0.5)*0.5;
    float n2=fbm((mp-vec3(7.0))*6.5,0.5)*0.5;
    vec3 c0=color_grad0(n0);
    m.baseColor=mix((vec3(1.0)-c0)*0.5,c0*2.0,diff);
    m.specular=1.0-diff;
    m.normal=normalize(calcnormal(p)+(vec3((n0-0.5),n1,n2)*(max(p.y*0.9+0.75,0.0))));
    return m;
}

void march(inout float d,out vec3 p,out float dS,in vec3 ro,in vec3 rd){
    for (int i=0; i < 100; i++) {
    	p = ro + rd*d;
        dS = obj_sdf(p);
        d += dS;
        if (d > 20.0 || abs(dS) < 0.0001) break;
    }
}

vec3 hdri(vec3 p,float v) {
	return pow(texture(iChannel0, p).xyz, vec3(2.2))
    + pow(texture(iChannel0, p).xxx, vec3(8.0)) * v;
}

vec3 raymarch(
        vec2 uv,
        vec3 camera,
        float cameraZoom,
        vec3 lookAt,
        float cameraDistance,
        vec3 sun,
        float ambLightIntensity,
        float lightPow,
        float lightSpecular,
        float reflection) {
	vec3 cam=camera*cameraZoom;
	vec3 ray=normalize(lookAt-cam);
	vec3 cX=normalize(cross(vec3(0.0,1.0,0.0),ray));
	vec3 cY=normalize(cross(ray,cX));
	vec3 rd = normalize(ray*cameraDistance+cX*uv.x+cY*uv.y);
	vec3 ro = cam;
	
	float d=0.;
	vec3 p=vec3(0.);
	float dS=0.0;
	march(d,p,dS,ro,rd);
	
  vec3 color=vec3(0.);
	material objMat=obj_mat3d(p);
	vec3 light=normalize(sun);
	if (d<20.0) {
	  vec3 n=objMat.normal;
		float l=clamp(dot(-light,-n),0.,1.0);
		vec3 ref=normalize(reflect(rd,-n));
		float r=clamp(dot(ref,light),0.,1.0);
    lightSpecular*=objMat.specular;
		color=max(ambLightIntensity,l)*objMat.baseColor+pow(r,lightPow)*lightSpecular;
		//reflection
    d=0.01;
		march(d,p,dS,p,ref);
		vec3 objColorRef=vec3(0.);
		if (d<20.0) {
      material mref=obj_mat3d(p);
			objColorRef=mref.baseColor;
			n=mref.normal;
			l=clamp(dot(-light,-n),0.,1.);
			objColorRef=max(l,ambLightIntensity)*objColorRef;
		} else {
			objColorRef=hdri(ref.zyx,2.0);
		}
    reflection*=objMat.specular;
		color=mix(color,objColorRef,reflection);
	} else {
		color=hdri(rd.zyx,0.0);
	}
	return color;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord ){
    //setup uv
    vec2 uv=fragCoord/iResolution.xy-0.5;
    uv.x*=iResolution.x/iResolution.y;

    //rendering parameters
    vec3 camera=vec3(sin(sin(iTime*0.3)*0.5+0.5)*4.0,2.0,cos(cos(iTime*0.2)*0.5+0.5)*4.0);
    float cameraZoom=1.0;
    vec3 lookAt=vec3(0.0,-0.1,0.0);
    float cameraDistance=1.1;
    vec3 sun=vec3(5.0,2.0,-0.2);
    float ambLightIntensity=0.25;
    float lightPow=128.0;
    float lightSpecular=0.7;
    float reflection=0.2;
    vec3 col = raymarch(uv,camera,cameraZoom,lookAt,cameraDistance,sun,
        ambLightIntensity,lightPow,lightSpecular,reflection);

    fragColor = vec4(pow(col,vec3(1.0/2.2)),1.0);
}

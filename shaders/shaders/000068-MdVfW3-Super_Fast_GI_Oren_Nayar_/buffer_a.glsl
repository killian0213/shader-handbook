// Buf A (buffer) — Super Fast GI(Oren Nayar) by 834144373
// https://www.shadertoy.com/view/MdVfW3

#define GI_DEPTH 5

/*
	if we use the "Multiple Importance Sample"
	https://graphics.stanford.edu/courses/cs348b-03/papers/veach-chapter9.pdf
	combine direct light sample and bsdf light sample
*/
const bool UseMIS = true;
/*
	Skylighting form skybox,as well as known the IBL "Image Base Lighting"
	hum...but here no HDR,:)
*/
const float SkyLightIntensity = 1.7;//1.7 up for bright,0.15 lower for weak lighting show AO
const float AreaLightIntersity = 10.;
//------------------------------------Debug-----------------------------------
//#define Linux //else for Windows system

/*Scene Objects*/
#define N_SPHERES 1
#define N_QUADS 2
#define N_BOXES 1

/*Type*/
#define LIGHT 0
#define DIFF 1
#define WOOD 10

/*Material ID Name*/
#define CenterSphere 0
#define Floor 1
#define AreLighing 2
#define Cuboid 3

const vec3 LIGHTCOLOR = vec3(0.8,0.8,0.75);
const vec3 BACKGROUND_COL = vec3(0.336,0.336,0.336);

const vec3 ZERO = vec3(0.,0.,0.);
const vec3 ONE  = vec3(1.,1.,1.);
const vec3 UP   = vec3(0.,1.,0.);

/* 
	hum...you can skip it,it's just intersection primary polygon,
	and you can easy find more free on public internet.:)
*/
struct Ray { vec3 origin; vec3 direction; };
struct Sphere { float radius; vec3 position; vec3 emission; vec3 color; float roughness; int type; int id;};
struct Quad { vec3 normal; vec3 v0; vec3 v1; vec3 v2; vec3 v3; vec3 emission; vec3 color; float roughness; int type; int id;};
struct Box { vec3 minCorner; vec3 maxCorner; vec3 emission; vec3 color; float roughness; int type; int id;};
struct Intersection {vec3 surface;vec3 direction;float distance;vec2 uv; vec3 normal; vec3 emission; vec3 color; float roughness; int type; int id;};

struct Light{float radius;vec3 direction;vec3 emission;float radiance;float pdf;int type;};
struct Material{float id;vec2 uv;vec3 normal;vec3 specular;vec3 diffuse;float roughness;int type;}; 

Sphere spheres[N_SPHERES];
Quad quads[N_QUADS];
Box boxes[N_BOXES];

bool solveQuadratic(float A, float B, float C, out float t0, out float t1){
	float discrim = B*B-4.0*A*C;
	if ( discrim < 0.0 )
        	return false;
	float rootDiscrim = sqrt(discrim);
	float Q = (B > 0.0) ? -0.5 * (B + rootDiscrim) : -0.5 * (B - rootDiscrim); 
	float t_0 = Q / A; 
	float t_1 = C / Q;
	t0 = min( t_0, t_1 );
	t1 = max( t_0, t_1 );
	return true;
}
float SphereIntersect( float rad, vec3 pos, Ray ray ){
	float t = INFINITY;
	float t0, t1;
	vec3 L = ray.origin - pos;
	float a = dot( ray.direction, ray.direction );
	float b = 2.0 * dot( ray.direction, L );
	float c = dot( L, L ) - (rad * rad);
	if (!solveQuadratic( a, b, c, t0, t1))
		return INFINITY;
	if ( t1 > 0.0 )
		t = t1;
	if ( t0 >= 0.0 )
		t = t0;
	return t;
}
float QuadIntersect( vec3 v0, vec3 v1, vec3 v2, vec3 v3, vec3 normal, Ray r ){
	vec3 u, v, n;    // triangle vectors
	vec3 w0, w, x;   // ray and intersection vectors
	float rt, a, b;  // params to calc ray-plane intersect
	// get first triangle edge vectors and plane normal
	v = v2 - v0;
	u = v1 - v0; // switched u and v names to save calculation later below
	//n = cross(v, u); // switched u and v names to save calculation later below
	n = -normal; // can avoid cross product if normal is already known
	w0 = r.origin - v0;
	a = -dot(n,w0);
	b = dot(n, r.direction);
	if (b < 0.0001)   // ray is parallel to quad plane
		return INFINITY;
	// get intersect point of ray with quad plane
	rt = a / b;
	if (rt < 0.0)          // ray goes away from quad
		return INFINITY;   // => no intersect
	x = r.origin + rt * r.direction; // intersect point of ray and plane
	// is x inside first Triangle?
	float uu, uv, vv, wu, wv, D;
	uu = dot(u,u);
	uv = dot(u,v);
	vv = dot(v,v);
	w = x - v0;
	wu = dot(w,u);
	wv = dot(w,v);
	D = 1.0 / (uv * uv - uu * vv);
	// get and test parametric coords
	float s, t;
	s = (uv * wv - vv * wu) * D;
	if (s >= 0.0 && s <= 1.0){
		t = (uv * wu - uu * wv) * D;
		if (t >= 0.0 && (s + t) <= 1.0){
			return rt;
		}
	}
	// is x inside second Triangle?
	u = v3 - v0;
	///v = v2 - v0;  //optimization - already calculated above
	uu = dot(u,u);
	uv = dot(u,v);
	///vv = dot(v,v);//optimization - already calculated above
	///w = x - v0;   //optimization - already calculated above
	wu = dot(w,u);
	///wv = dot(w,v);//optimization - already calculated above
	D = 1.0 / (uv * uv - uu * vv);
	// get and test parametric coords
	s = (uv * wv - vv * wu) * D;
	if (s >= 0.0 && s <= 1.0){
		t = (uv * wu - uu * wv) * D;
		if (t >= 0.0 && (s + t) <= 1.0){
			return rt;
		}
	}
	return INFINITY;
}
float BoxIntersect( vec3 minCorner, vec3 maxCorner, Ray r, out vec3 normal ){
	vec3 invDir = 1.0 / r.direction;
	vec3 tmin = (minCorner - r.origin) * invDir;
	vec3 tmax = (maxCorner - r.origin) * invDir;
	vec3 real_min = min(tmin, tmax);
	vec3 real_max = max(tmin, tmax);
	float minmax = min( min(real_max.x, real_max.y), real_max.z);
	float maxmin = max( max(real_min.x, real_min.y), real_min.z);
	if (minmax > maxmin){
        if (maxmin > 0.0){ // if we are outside the box
			normal = -sign(r.direction) * step(real_min.yzx, real_min) * step(real_min.zxy, real_min);
			return maxmin;	
		}
        else if (minmax > 0.0){ // else if we are inside the box
			normal = -sign(r.direction) * step(real_max, real_max.yzx) * step(real_max, real_max.zxy);
			return minmax;
		}
	}
	return INFINITY;
}

void SetupScene(){
   	spheres[0] = Sphere( 0.6, vec3(0., 0.3,-0.35),vec3(0.,0.,0.),vec3(1.,1.,1.), 1., DIFF,CenterSphere);
    quads[0] = Quad(normalize(vec3(0.,-0.37,1.)),vec3(4.45624,2.70023,-16.2667), vec3(-4.45624,2.70023,-16.2667), vec3(-4.45624 ,11.247,-13.7397), vec3(4.45624,11.247,-13.7397), 2.*LIGHTCOLOR, vec3(1.),0.4, LIGHT,AreLighing);
    quads[1] = Quad(vec3(0.,1.,0.),vec3(-300000,0.,-200000.), vec3(300000.,0.,-200000.), vec3(200000.,0.,200000.), vec3(-200000.,0.,200000.), vec3(0.,0.,0.), vec3(1.),0.05, DIFF,Floor);
    boxes[0] =  Box(vec3(-0.7,1.,0.8),vec3(0.7,0.0,0.94), vec3(0.,0.,0.), vec3(0.,1.,0.), 0.1, DIFF,Cuboid);
}
float SceneIntersect( Ray r, inout Intersection intersec ){
    float d = INFINITY;	
    float t = 0.;
    vec3 normal = vec3(0.);
    for(int i=0;i<spheres.length();i++){
        t = SphereIntersect(spheres[i].radius,spheres[i].position,r);
        if (t < d){
            d = t;
            intersec.normal = normalize((r.origin + r.direction * t) - spheres[i].position);
            intersec.emission = spheres[i].emission;
            intersec.color = spheres[i].color;
            intersec.roughness = spheres[i].roughness;
            intersec.type = spheres[i].type;
            intersec.id = spheres[i].id;
		}
    }
    for(int i=0;i<quads.length();i++){
        t = QuadIntersect( quads[i].v0, quads[i].v1, quads[i].v2, quads[i].v3, quads[i].normal, r );
        if (t < d){
        	d = t;
            intersec.normal = normalize(quads[i].normal);
            intersec.emission = quads[i].emission;
            intersec.color = quads[i].color;
            intersec.roughness = quads[i].roughness;
            intersec.type = quads[i].type;
            intersec.id = quads[i].id;
        }
    }
    for(int i=0;i<boxes.length();i++){
    	t = BoxIntersect(boxes[0].minCorner,boxes[0].maxCorner,r,normal);
        if(t < d){
        	d = t;
            intersec.normal = normalize(normal);
            intersec.emission = boxes[i].emission;
            intersec.color = boxes[i].color;
            intersec.roughness = boxes[i].roughness;
            intersec.type = boxes[i].type;
        	intersec.id = boxes[i].id;
        }
    }
    
    intersec.distance = d;
    intersec.surface  = r.origin + r.direction * d + intersec.normal*0.00001;
    return d;
}

/* 
	All feature materials infomation
	Material GetMaterial(Intersection _intersec){
	Material mat;
    mat.type = _intersec.type;
    mat.uv = _intersec.surface.xz*0.1 - 0.5;
    mat.normal = _intersec.normal;
   
    mat.diffuse = sRGB2Linear(texture(iChannel1,mat.uv).rgb);
    mat.specular = LIGHTCOLOR;
    mat.roughness = _intersec.roughness;
    return mat;
}
*/

OrenNayarBsdf GetOrenNayarMaterial(Intersection _intersec){
	OrenNayarBsdf mat;
    mat.id = _intersec.id;
    mat.uv = fract(_intersec.surface.zx/4.-0.5);
    if(mat.id == Floor)
    	mat.albedo = vec3(0.9,1.,0.);
    else if(mat.id == Cuboid)
        mat.albedo = vec3(0.4,1.,0.);
    else if(mat.id == CenterSphere){
        mat.uv.x = fract(atan(_intersec.surface.z+0.35,_intersec.surface.x)/M_2PI_F);
        mat.uv.y = _intersec.surface.y+0.3;//(atan(abs(_intersec.surface.x),_intersec.surface.y-0.6))/M_PI_F;//_intersec.surface.y/1.2 + 0.;
        mat.albedo = sRGB2Linear(texture(iChannel3,mat.uv).rgb);//clamp(vec3(mat.uv,0.),0.,1.);
    }
	mat.nDir = _intersec.normal;
	mat.roughness = _intersec.roughness;
    return mat;
}

vec3 GetLightIntensity(){
	return AreaLightIntersity*LIGHTCOLOR;
}

float PDF_Area2Angle(float pdf,float dist,float costhe){
    if(costhe > 0.)
		return pdf*dist*dist/costhe;
	return 0.;
}

/*
	Just for area lighting
	The below simple diagrammatic is implement form my method,it descripts how 
	O (a random point on the Area Surface) position is calculated;
 
 vec3 v0; vec3 v1; vec3 v2; vec3 v3
       A		B         C        D
    v3------v2
	|	 O	 |
	v0------v1
	O = v0 + v0v1*X1 + v0v3*X2.       X1 and X2 is uniform random distribute.

	Here is descript the direct light sample,
	we intersect the area light surface within solid angle,
	and the solid angle is object surface direct to light ray set.

	The fist pdf is on the Area Surface,we easy know every emit point on the Light Area
	is uniform distribute,the we can get the probability density is 1/S (S is area)
	but we interesting on the solid angle pdf,so the convert is necessary.
*/
vec3 LightSample(vec3 p,float x1,float x2,out vec3 wo,out float dist,out float pdf){
	vec3 v0v1 = quads[0].v1 - quads[0].v0;
    vec3 v0v3 = quads[0].v3 - quads[0].v0;
    float width  = length(v0v1);
    float height = length(v0v3);
    vec3 O = quads[0].v0 + v0v1*x1 + v0v3*x2;
    wo = O - p;
    dist = length(wo);
    wo = normalize(wo);
    float costhe = dot(-wo,quads[0].normal);
    pdf = PDF_Area2Angle(1./(width*height),dist,clamp(costhe,0.00001,1.));
    return costhe>0. ? GetLightIntensity(): vec3(0.);
}
/*
	Yep!if we catch the light ray is on the Area Lighing Surface,
	we get the solid angle pdf as same as the up.
*/
float GetLight_PDF(in Intersection intersecNow,in Intersection intersecNext){
	float pdf = 0.;
    if(intersecNext.type == LIGHT){
        vec3 v0v1 = quads[0].v1 - quads[0].v0;
    	vec3 v0v3 = quads[0].v3 - quads[0].v0;
    	float width  = length(v0v1);
    	float height = length(v0v3);
        vec3 lDir = intersecNext.surface - intersecNow.surface;
        float dist = length(lDir);
        float costhe = dot(-lDir,quads[0].normal);
        pdf = PDF_Area2Angle(1./(width*height),dist,costhe);
    }
    return pdf;
}

/*
	Hum...just get wi (it called omiga) which is descript 
	a ray that object surface to light.
*/
vec3 DirectLightSample(in Intersection intersecNow,out vec3 wi,out float pdf){
	vec3 Li = vec3(0.);
    float x1 = GetRandom(),x2 = GetRandom();
    float dist = INFINITY;
    vec3 AssumeLi = LightSample(intersecNow.surface,x1,x2,wi,dist,pdf);
    Ray shadowRay = Ray(intersecNow.surface,wi);
    Intersection intersecNext;
    SceneIntersect(shadowRay, intersecNext);
    if(intersecNext.type == LIGHT){
    	Li = AssumeLi;
    }
    return Li;
}
/*
	I implement the BRDF Light Sample direct in Radiance() for clearly read.
	and just adopt a Oren Nayar diffuse model
	vec3 BRDFLightSample(in Intersection intersecNow,out Intersection intersecNext,out vec3 wi,out float pdf){
	vec3 Li = vec3(0.);
    float x1 = GetRandom(),x2 = GetRandom();
    wi = sample_uniform_hemisphere(intersecNow.normal,x1,x2,pdf);
    Ray shadowRay = Ray(intersecNow.surface,wi);
    SceneIntersect(shadowRay, intersecNext);
    return Li;
}
*/

/*
	Get Radiance all the path lighting
*/
vec3 Radiance(Ray ray){
	vec3 Lo = vec3(0.);
    Intersection intersecNow;
	Intersection intersecNext;
	Material mat;
    
    float d = SceneIntersect(ray,intersecNow);
    intersecNow.direction = ray.direction;
    if(d == INFINITY){
    	return texture(iChannel2,ray.direction).rgb*0.2;//BACKGROUND_COL;
    }
    else if(intersecNow.type == LIGHT){
    	return texture(iChannel2,ray.direction).rgb*0.2;//BACKGROUND_COL;//GetLightIntensity();
    }
    
    vec3 BSDFThroughout = vec3(1.);
    vec3 DirectThroughout = vec3(1.);
    for(int i=0;i<GI_DEPTH;i++){
        float BSDF_pdf = 0.;
        float Direct_pdf = 0.;
        vec3 Li = vec3(0.);
		OrenNayarBsdf bsdf = GetOrenNayarMaterial(intersecNow);
		vec3 eval = vec3(0.);
        /*
		  (Light Direct Sample) Calculate Direct Lighing and Indirect Lighing
        */
		{
            vec3 wi = vec3(0.);
        	Li = DirectLightSample(intersecNow,wi,Direct_pdf);
            //intersecNow.normal = faceforward(-intersecNow.normal,wi,intersecNow.normal);
            BSDF_Oren_Nayar_Setup(bsdf);
            eval = BSDF_Oren_Nayar_GetIntensity(bsdf,intersecNow.normal,ray.direction,wi);
            DirectThroughout *= bsdf.albedo;
            
            //use Multiple Importance sample
            float Light_Weight = 1.;
            if(UseMIS){
            	float bsdf_pdf = GetCosWeightSpherePDF(intersecNow.normal,wi);
                Light_Weight = MISWeight(1.,Direct_pdf,1.,bsdf_pdf);
            }
            if(Direct_pdf > 0.){
            	Lo += Li*DirectThroughout*eval*Light_Weight/Direct_pdf;
            }
            
        }
        
        //(BRDF Sample) Calculate Direct Lighing and Indirect Lighing
        {
        	float x1 = GetRandom(),x2 = GetRandom();
            vec3 wi = sample_cos_hemisphere(intersecNow.normal,x1,x2,BSDF_pdf);
           	SceneIntersect(Ray(intersecNow.surface,wi),intersecNext);
            
            //use Multiple Importance sample
            float BSDF_Weight = 1.0;
            if(UseMIS){
            	float light_pdf = GetLight_PDF(intersecNow,intersecNext);
                BSDF_Weight = MISWeight(1.,BSDF_pdf,1.5,light_pdf);
            }
            if(BSDF_pdf > 0.){
            	BSDFThroughout *= bsdf.albedo / BSDF_pdf;
            }
            /*
				use Russian Roulette teminal 
            	for adapt very bright and very dark,
				As one words for in short,elevate unbias,reduce noise.
			*/
			float probability = max(max(BSDFThroughout.x,BSDFThroughout.y),BSDFThroughout.z);
            #ifdef Linux
            	if(probability > 0.){
            		//if(GetRandom() < probability)
                    BSDFThroughout /= probability;
                }
            #else
                if(any(greaterThan(BSDFThroughout,vec3(1.))) ){
                    if(GetRandom() < probability)
                        BSDFThroughout /= probability;
                }
            #endif
			if(intersecNext.distance == INFINITY){
                Li = texture(iChannel2,wi).rgb*SkyLightIntensity;//BACKGROUND_COL;
                eval = BSDF_Oren_Nayar_GetIntensity(bsdf,intersecNow.normal,ray.direction,wi);
                Lo += Li * eval * BSDFThroughout * BSDF_Weight;
                break;
            }
            else if(intersecNext.type == LIGHT){
                Li = GetLightIntensity();
                eval = BSDF_Oren_Nayar_GetIntensity(bsdf,intersecNow.normal,ray.direction,wi);
                Lo += Li * eval * BSDFThroughout * BSDF_Weight;
                break;
            }
        }
        
        //for next tracing path
        intersecNow = intersecNext;
        
    }
    return Lo;
}

const vec2 FRAME_START_UV = vec2(0.,0.);
vec4 readValues(vec2 xy){
	return texture(iChannel0,(xy+0.5)/R);
}
mat3 CameraCoordBase(vec3 campos,vec3 lookAt,vec3 up){
	vec3 LookForward = normalize(lookAt - campos);
    vec3 BaseRight = normalize(cross(LookForward,up));
    vec3 BaseUp    = normalize(cross(BaseRight,LookForward));
    mat3 mat = mat3(BaseRight,BaseUp,LookForward);
	return mat;
}

void mainImage( out vec4 C, in vec2 U ){
	vec2 iU = U - 0.5;
    seed = iTime*sin(iTime) + (U.x+R.x*U.y)/(R.y);
    vec2 uv = (U+U-R)/R.y;
    vec2 mousePos = readValues(FRAME_START_UV).yz;
    if(iFrame <= 1){
         mousePos = vec2(0.,R.y/2.);
	}
    mousePos.y = max(mousePos.y,R.y*0.33);
    mousePos = mousePos/R*10.;
    vec3 pos = vec3(cos(mousePos.x),mousePos.y/2.-0.5,sin(mousePos.x));
    	 pos.xz *= 2.5;
    vec3 dir = normalize(vec3(uv,2.3));
	pos.xy += cos(GetRandom()*M_2PI_F+vec2(0.,M_H_PI_F))*(20.*GetRandom()/length(R));
    dir = RotVector(CameraCoordBase(pos,vec3(0.,0.05,0.),vec3(0.,1.,0.)),dir);
    dir = normalize(dir);
    
    SetupScene();
    //vec2 dither = TriangularNoise2DShereRay(uv,iTime);
    //pos += (RotVector(cameraSpace,vec3(dither,0.)))*0.004;
    Ray ray = Ray(pos,dir);
    vec3 col = Radiance(ray);
    if(all(equal(iU,FRAME_START_UV))){
        if(iFrame == 0){
            C = vec4(1.,vec2(0.,R.y/2.),0.);
        }
        else{
            if(iMouse.z > 1.){
                vec2 mousePos_Before = readValues(FRAME_START_UV).yz;
                C = vec4(1.,iMouse.xy,0.);
                
            }
            else{
                C = readValues(FRAME_START_UV);
                ++C.r;
            }
        }
    }
    else{
        if(iFrame == 0){
        	C = vec4(col.rgb,0.);
        }
        else{
            vec4 Frame_data = readValues(FRAME_START_UV);
            C = texture(iChannel0,U/R);
            /*
				蒙特卡洛 积分(Monte Carlo Integration)
				the math is: sum(x1+x2+x2+...+xn)/N     
				C = C*(1-1/n) + col *(1/n)    the n is ∈(1,N)
			*/
            C = mix(C,vec4(col,1.),1./Frame_data.r);
        }
    }

}
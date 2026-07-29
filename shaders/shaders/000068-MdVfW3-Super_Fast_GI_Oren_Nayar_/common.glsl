// Common (common) — Super Fast GI(Oren Nayar) by 834144373
// https://www.shadertoy.com/view/MdVfW3

#define M_PI_F	 3.14159274101257
#define M_H_PI_F 1.5707963267948966
#define M_2PI_F  6.2831853071795864 
#define M_1_PI_F 0.3183098861837067
#define INFINITY 1000000.0
#define INFINITY_MIN 1.175494351e-38
#define OFFSET_VALUE 0.00001
#define R iResolution.xy

struct OrenNayarBsdf {
	//vec3 weight;
    int id;
    vec2 uv;
    vec3 albedo;
	//float sample_weight;
	vec3 nDir;
	float roughness;
	float a;
	float b;
};
    
float seed;
float GetRandom(){return fract(sin(seed++)*43758.5453123);}    
    
void frisvad(in vec3 n, out vec3 f, out vec3 r){
    if(n.z < -0.999999) {
        f = vec3(0.,-1,0);
        r = vec3(-1, 0, 0);
    } else {
    	float a = 1./(1.+n.z);
    	float b = -n.x*n.y*a;
    	f = vec3(1. - n.x*n.x*a, b, -n.x);
    	r = vec3(b, 1. - n.y*n.y*a , -n.y);
    }
}
mat3 CoordBase(vec3 n){
	vec3 x,y;
    frisvad(n,x,y);
    return mat3(x,y,n);
}
vec3 ToOtherSpaceCoord(mat3 otherSpaceCoord,vec3 vector){
	return vector * otherSpaceCoord;
}
vec3 RotVector(mat3 otherSpaceCoord,vec3 vector){
	return otherSpaceCoord * vector;
}

/* cosin weight */
float GetCosWeightSpherePDF(in vec3 nDir,in vec3 wi){
	float pdf = 1.;
    float costheta = max(0.,dot(nDir,wi));
    pdf = costheta*M_1_PI_F;
    return pdf;
}
vec3 sample_cos_hemisphere(in vec3 N,float x1, float x2,out float pdf){
    float phi = M_2PI_F * x1;
	float r = sqrt(x2);
	x1 = r * cos(phi);
	x2 = r * sin(phi);
	vec3 T, B;
	frisvad (N, T, B);
	float costheta = sqrt(max(1.0f - x1 * x1 - x2 * x2, 0.0));
	pdf = M_1_PI_F;
	return x1 * T + x2 * B + costheta * N;
}
/* sample direction uniformly distributed in hemisphere */
float GetUniformDiffusePDF(){
    return 0.5 * M_1_PI_F;
}
vec3 sample_uniform_hemisphere(in vec3 N,float x1, float x2, out float pdf){
	float z = x1;
	float r = sqrt(max(0., 1. - z*z));
	float phi = M_2PI_F * x2;
	float x = r * cos(phi);
	float y = r * sin(phi);
	vec3 T, B;
	frisvad (N, T, B);
	pdf = 0.5 * M_1_PI_F;
    return x * T + y * B + z * N;
}

void BSDF_Oren_Nayar_Setup(inout OrenNayarBsdf bsdf){
	float sigma = bsdf.roughness;
	sigma = clamp(sigma,0.,1.);
	float div = 1. / (M_PI_F + ((3. * M_PI_F - 4.) / 6.) * sigma);
	bsdf.a = div;
	bsdf.b = sigma * div;
}

//BSDF Oren-Nayar evalution
vec3 BSDF_Oren_Nayar_GetIntensity(OrenNayarBsdf bsdf,vec3 n,vec3 v,vec3 l){
	float nl = max(dot(n, l), 0.);
	float nv = max(dot(n, v), 0.);
	float t = max(dot(l, v),0.) - nl * nv;
	if(t > 0.)
		t /= max(nl, nv) + INFINITY_MIN;
	float is = nl * (bsdf.a + bsdf.b * 0.1);
	return vec3(is);
}


//!!!!!! For BSDF light sample
vec3 BSDF_Oren_Nayar_Sample(OrenNayarBsdf bsdf,vec3 Ng,vec3 vDir,float x1, float x2,out vec3 eval,out vec3 wi,out float pdf){
	//pre values
    BSDF_Oren_Nayar_Setup(bsdf);
    wi = sample_uniform_hemisphere(bsdf.nDir, x1, x2, pdf);
	if(dot(Ng, wi) > 0.){
		eval = BSDF_Oren_Nayar_GetIntensity(bsdf, bsdf.nDir, vDir, wi);
	}
	else{
		pdf = 0.;
		eval = vec3(0.);
	}
	return eval;
}
//!!!!!! For Single Scatter Sample
vec3 BSDF_Oren_Nayar_Eval_Reflect(OrenNayarBsdf bsdf, vec3 vDir, vec3 wi, float pdf){
	if(dot(bsdf.nDir, wi) > 0.) {
		pdf = 0.5 * M_1_PI_F;
		return BSDF_Oren_Nayar_GetIntensity(bsdf, bsdf.nDir, vDir, wi);
	}
	else {
		pdf = 0.0f;
		return vec3(0.);
	}
}



//------------Multiple Importance Sample Weight-----------
/*
	heuristic
	here βis 2;so power of coeff
*/
float MISWeight(float a,float b){
	float a2 = a*a;
	float b2 = b*b;
	return a2/(a2+b2);
}
float MISWeight(float coffe_a,float aPDF,float coffe_b,float bPDF){
    return MISWeight(coffe_a * aPDF,coffe_b*bPDF);
}

/*
	https://github.com/TheRealMJP/BakingLab/blob/master/BakingLab/ToneMapping.hlsl
*/
vec3 Linear2sRGB(vec3 color){
    vec3 x = color * 12.92;
    vec3 y = 1.055 * pow(clamp(color,0.,1.),vec3(0.4166667)) - 0.055;
    vec3 clr = color;
    clr.r = (color.r < 0.0031308) ? x.r : y.r;
    clr.g = (color.g < 0.0031308) ? x.g : y.g;
    clr.b = (color.b < 0.0031308) ? x.b : y.b;
    return clr;
}
vec3 sRGB2Linear(vec3 color){
    vec3 x = color / 12.92f;
    vec3 y = pow(max((color+0.055f)/1.055, 0.0),vec3(2.4));
    vec3 clr = color;
    clr.r = color.r <= 0.04045 ? x.r : y.r;
    clr.g = color.g <= 0.04045 ? x.g : y.g;
    clr.b = color.b <= 0.04045 ? x.b : y.b;
    return clr;
}
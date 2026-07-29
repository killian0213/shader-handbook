// Image (image) — Kleinian variations by iapafoto
// https://www.shadertoy.com/view/ldSyRd


// Created by sebastien durand - 2017
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
//-----------------------------------------------------
// Java/OpenCL fractal playground: https://github.com/iapafoto/FractalOpenCL
// 4K Intro version: https://github.com/iapafoto/Intro-4Kbyte-Kelenian
//-----------------------------------------------------
// Text - Thanks to Andre [Shadertext]
// Andre - https://www.shadertoy.com/view/lddXzM 
//-----------------------------------------------------
// Music - Yann Tiersen - Summer 78 (10dens remix) (2010)
//-----------------------------------------------------


//---------------------------------------------------
// The DOF process :
// For each neigbourg pixels, the algo calculate if the 3D reconstruct pixelPoint is effectively in 
// the 3D cone (circle) of confusion of the pixel. Otherwise it is ignored.
// => Avoid artfacts on the edges
// Inspired by Dave Hoskins bokeh disc [https://www.shadertoy.com/view/4d2Xzw]
// => 3D adaptation
//---------------------------------------------------



//#define WITH_DOF

#ifdef WITH_DOF

const float fov = 3.;
const float aperture = 1.;

const float cosAngle = cos(radians(aperture/2.));
const float GA =2.399;  // golden angle = 2pi/(1+phi)
const mat2 rot = mat2(cos(GA),sin(GA),-sin(GA),cos(GA));

vec2 res;
    

bool inCone(vec3 p, vec3 o, vec3 n, float side) {
	return step(cosAngle,side*dot(normalize(o-p), n)) > 0.5;
}

vec3 RD(const vec2 q) {
    return normalize(vec3((2.* q.x - 1.) * res.x/res.y,  (2.* q.y - 1.), fov));
}

//--------------------------------------------------------------------------
// eiffie's code for calculating the aperture size for a given distance...
float coc(float t) {
	return max(t*.04, (2./iResolution.y) * (1.+t));
}

vec3 dof(sampler2D tex, vec2 uv, float fdist) {
    
	vec4 colMain = texture(tex, uv);
    
    const float amount = 1.;
    
    float rad = min(.5, 10.*coc(abs(colMain.w-fdist)));//.3; // TODO calculate this for Max distance on picture
    
    float r=1.;
    
    vec3 cn = RD(uv),    // Cone axis    
         co = cn*fdist,  // Cone origin
         sum = vec3(0.),  
     	 bokeh = vec3(1),
         acc = vec3(0),
         pixPos;
    

    vec2 pixScreen,
         pixel = 1./iResolution.xy,        
         angle = vec2(0, rad);
    
    vec4 pixCol;
    
    
	for (int j=0;j<80;j++) {  
        r += 1./r;
	    angle *= rot;
        
        pixScreen = uv + pixel*(r-1.)*angle; // Neighbourg Pixel
        pixCol = texture(tex, pixScreen);    // Color of pixel (w is depth)      
        pixPos = pixCol.w * RD(pixScreen);   // Position of 3D point in camera base

        if (inCone(pixPos, co, cn, sign(fdist - pixCol.w))) {        // true if the point is effectivelly in the cone
            bokeh = pow(pixCol.xyz, vec3(9.)) * amount +.4;
            acc += pixCol.xyz * bokeh;			
            sum += bokeh;
        }
	}
    
    return (length(sum) <= 0.) ? // Enable to deal with problem of precision when at thin begining of the cone
		colMain.xyz : acc.xyz/sum;
}


#define NB 16

// Deph of field animation
float[] deph = float[] ( 1.,.65,.6,.4,.2,.4,/*.055,.055,*/.65,.11,.13,1.3,.49,1.2,1.2,.5,.65,.45,1.,1.);


void mainImage(out vec4 fragColor,in vec2 fragCoord) {
    
    res = iResolution.xy;
    
    float t = .1*iTime,
	kt = smoothstep(0.,1.,fract(t));

    // - Interpolate Deph of field ---------------------
    int  i0 = int(t)%NB, i1 = i0+1;    
    float fdist = mix(deph[i0], deph[i1], kt);
    
	vec2 uv = gl_FragCoord.xy / iResolution.xy;
	fragColor=vec4(dof(iChannel0,uv,fdist),2.);
}

#else 


void mainImage(out vec4 fragColor,in vec2 fragCoord)
{
	vec2 uv = gl_FragCoord.xy / iResolution.xy;
	fragColor= pow(texture(iChannel0,uv),vec4(.64));
}


#endif
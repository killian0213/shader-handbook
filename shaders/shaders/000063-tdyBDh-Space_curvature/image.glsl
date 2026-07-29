// Image (image) — Space curvature by iapafoto
// https://www.shadertoy.com/view/tdyBDh

// Created by sebastien durand - 01/2019
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
// *****************************************************************************
// Add 2 rotations to [iq]  https://www.shadertoy.com/view/3ld3DM
// See also           [dr2] https://www.shadertoy.com/view/3l3GD7
// *****************************************************************************

// Buf B: Calculate distance to scene
// Image: DOF post processing


#define WITH_DOF
#define WITH_CONE_TEST


#ifdef WITH_DOF

const float aperture = 2.;

const float cosAngle = cos(radians(aperture/2.));
const float GA = 2.399;  // golden angle = 2pi/(1+phi)
const mat2 rot = mat2(cos(GA),sin(GA),-sin(GA),cos(GA));
    
bool inCone(vec3 p, vec3 o, vec3 n, float side) {
	return side*dot(normalize(o-p), n) >= cosAngle;
}

//--------------------------------------------------------------------------
// eiffie's code for calculating the aperture size for a given distance...
float coc(float t) {
	return max(t*.08, (2./iResolution.y) * (1.+t));
}

vec3 RD(const vec2 q) {
    return normalize(vec3((2.* q.x - 1.) * iResolution.x/iResolution.y,  (2.* q.y - 1.), 2.));
}

vec3 dof(sampler2D tex, vec2 uv, float fdist) {
    
    const float amount = 1.;
	vec4 colMain = texture(tex, uv);
    
    fdist = min(30., fdist);
    float rad = min(.3, coc(abs(colMain.w-fdist))),//.3; // TODO calculate this for Max distance on picture
    	  r=6.;
    
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
    
    bool isInCone = false;
	for (int j=0;j<32;j++) {  
        r += 1./r;
	    angle *= rot;
        pixScreen = uv + pixel*(r-1.)*angle; // Neighbourg Pixel
        pixCol = texture(tex, pixScreen);    // Color of pixel (w is depth)      
        pixPos = pixCol.w * RD(pixScreen);   // Position of 3D point in camera base
#ifdef WITH_CONE_TEST
        if (inCone(pixPos, co, cn, sign(fdist - pixCol.w))) 
#endif            
        {        // true if the point is effectivelly in the cone
            bokeh = pow(pixCol.xyz, vec3(9.)) * amount +.1;
            acc += pixCol.xyz * bokeh;			
            sum += bokeh;
            isInCone = true;
        }
	}
        
 	return (!isInCone) ? colMain.xyz : // Enable to deal with problem of precision when at thin begining of the cone
       acc.xyz/sum;
}


void mainImage(out vec4 fragColor,in vec2 fragCoord) {
	vec2 r = iResolution.xy, m = iMouse.xy / r,
	     q = fragCoord.xy/r.xy;
    
    // Animation
 	float anim = .1*iTime,
   	   aCam = 10. + 4.*anim + 8.*m.x;

    // Camera
	vec3 ro = 1.5*vec3(cos(aCam), 1.2, .2 + sin(aCam));
			
  	// DOF
    float fdist = length(ro-vec3(0,.3,0));
    vec3 c = dof(iChannel0,q,fdist); 
    
    // Vigneting
    c *= pow(16.*q.x*q.y*(1.-q.x)*(1.-q.y), .32); 
    
    fragColor = vec4(c,1.);
}

#else 


void mainImage(out vec4 fragColor,in vec2 fragCoord)
{
	vec2 uv = gl_FragCoord.xy / iResolution.xy;
    vec4 c = texture(iChannel0,uv);
    c *= pow(16.*uv.x*uv.y*(1.-uv.x)*(1.-uv.y), .5); // Vigneting
	fragColor = c; //*.01; 
}

#endif
// Image (image) — Microcars by iapafoto
// https://www.shadertoy.com/view/XlXBWl

// Created by sebastien durand - 05/2017
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
//---------------------------------------------------

// Buf A: generation of truchet map and update position of cars (trick to mix cross and turns)
// Buf B: 3D rendering (using grid optimization)
// Image: DOF post processing

//---------------------------------------------------
// The DOF process :
// For each neigbourg pixels, the algo calculate if the 3D reconstruct pixelPoint is effectively in 
// the 3D cone (circle) of confusion of the pixel. Otherwise it is ignored.
// => Avoid artfacts on the edges
//
// Inspired by Dave Hoskins bokeh disc [https://www.shadertoy.com/view/4d2Xzw]
//---------------------------------------------------



#define WITH_DOF
#define WITH_CONE_TEST


#ifdef WITH_DOF

const float fov = 2.5;
const float aperture = 3.;

const float cosAngle = cos(radians(aperture/2.));
const float GA =2.399;  // golden angle = 2pi/(1+phi)
const mat2 rot = mat2(cos(GA),sin(GA),-sin(GA),cos(GA));

vec2 res;
    


bool inCone(vec3 p, vec3 o, vec3 n, float side) {
	return side*dot(normalize(o-p), n) >= cosAngle;
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
    
    float rad = min(.3, coc(abs(colMain.w-fdist)));//.3; // TODO calculate this for Max distance on picture
    
    float r=2.;
    
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
	for (int j=0;j<60;j++) {  
        r += 1./r;
	    angle *= rot;
        
        pixScreen = uv + pixel*(r-1.)*angle; // Neighbourg Pixel
        pixCol = texture(tex, pixScreen);    // Color of pixel (w is depth)      
        pixPos = pixCol.w * RD(pixScreen);   // Position of 3D point in camera base
#ifdef WITH_CONE_TEST
        if (inCone(pixPos, co, cn, sign(fdist - pixCol.w))) 
#endif            
        {        // true if the point is effectivelly in the cone
            bokeh = pow(pixCol.xyz, vec3(9.)) * amount +.4;
            acc += pixCol.xyz * bokeh;			
            sum += bokeh;
            isInCone = true;
        }
	}
        
    
 	return (!isInCone) ? colMain.xyz : // Enable to deal with problem of precision when at thin begining of the cone
       acc.xyz/sum;
}

vec3 cameraPath( float t )
{
    // procedural path	
    vec2 p  = 100.0*sin( 0.02*t*vec2(1.2,1.0) + vec2(0.1,0.9) );
	     p +=  50.0*sin( 0.04*t*vec2(1.1,1.3) + vec2(1.0,4.5) );
	float y = 5.5 + 2.5*sin(0.1*t-2.);

	return .5*vec3(p.x, y, p.y );
}


void mainImage(out vec4 fragColor,in vec2 fragCoord) {
    
    res = iResolution.xy;
    vec2 mo = (iMouse.xy/iResolution.xy);
//    vec3 ro = 45.*vec3(-cos(mouse.x), max(.8,mouse.x-2.+sin(mouse.x)*cos(mouse.y)), -.5-sin(mouse.y));
    
             vec2 p = -1.0 + 2.0*(fragCoord.xy) / iResolution.xy;
        p.x *= iResolution.x/ iResolution.y;
    
      float gTime = 1.*iTime;
        float time = 0.3*gTime + 50.0*mo.x;
    
    	// camera
        vec3  ro = cameraPath( time );
        vec3  ta = cameraPath( time*2.0+15.0 );
		ta = ro + normalize(ta-ro);
		ta.y = ro.y - 0.6;
        
        float cr = -0.2*cos(0.1*time);
	
        // build ray
        vec3 ww = normalize( ta - ro);
        vec3 uu = normalize(cross( vec3(sin(cr),cos(cr),0.0), ww ));
        vec3 vv = normalize(cross(ww,uu));
        float r2 = p.x*p.x*.32 + p.y*p.y;
        p *= (7.0-sqrt(37.5-11.5*r2))/(r2+1.0);
        vec3 rd = normalize( p.x*uu + p.y*vv + 2.5*ww );
    
 
    
    float fdist = texture(iChannel0,vec2(0,-.4)).w;//length(ro);//; 64.;
    
	vec2 uv = gl_FragCoord.xy / iResolution.xy;
    vec3 c = dof(iChannel0,uv,fdist); 
    c *= pow(16.*uv.x*uv.y*(1.-uv.x)*(1.-uv.y), .5); // Vigneting
	fragColor = vec4(c,1.);
}

#else 


void mainImage(out vec4 fragColor,in vec2 fragCoord)
{
	vec2 uv = gl_FragCoord.xy / iResolution.xy;
    vec4 c= texture(iChannel0,uv);
    c *= pow(16.*uv.x*uv.y*(1.-uv.x)*(1.-uv.y), .5); // Vigneting
	fragColor = c; 
}


#endif
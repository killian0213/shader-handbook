// Image (image) — 30 torus by XT95
// https://www.shadertoy.com/view/3dlcWl

// helpers
float hash(float s) { return fract(sin(s)*42422.42); }
mat2 rot(float v) { float a = cos(v), b = sin(v); return mat2(a,b,-b,a); }
float torus(vec3 p, vec2 q) { return length( vec2(length(p.xz)-q.x,p.y) ) - q.y; } 

// global + params
#define att 15.
float time;
float id;
vec3 glow;

// distance function
float map( vec3 p ) {
    // rotate the world
	p.xy *= rot(time*.1);
	p.xz *= rot(time*.2);
    
    // small point light on the center
	float d =  length(p);
	glow += vec3(1.) / ( .1 + d*200.);
    
    // 30 torus
	float s = .25;
	for(int i=0; i<30; i++) {
    	s += .25;
    	p.xy *= rot(time*.05);
    	p.xz *= rot(time*.1);
        
    	float d2 = torus(p,vec2(s, 0.14));
        
        // we accumulate the lighting here
    	float intensity = 1. / ( 1. + pow(abs(d2*att),1.3));
    	if(i == 6 && id == 0.) {
    		glow += vec3(1.,.3,1.) * intensity;
    	} else if(i == 15 && id == 1.) {
      		glow += vec3(1.,1.,.1) * intensity;
    	} else if(i == 20 && id == 2.) {
      		glow += vec3(.1,1.,.1) * intensity;
    	} else if(i == 25 && id == 3.) {
      		glow += vec3(.1,1.,1.) * intensity;
    	}
        
    	d = min(d, d2);
	}
	return d;
}



void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
	time = iTime + 10.;
    
    // uv stuff
    vec2 uv = fragCoord/iResolution.xy;
  	vec2 v = uv*2.-1.;
  	v.x /= iResolution.y / iResolution.x;

    // which torus is on ?
	id = floor(hash(floor(iTime*5.*hash(floor(time*.2))))*5.);
    
    // ray setup
  	vec3 ro = vec3(0.,0.,-10.);
  	vec3 rd = normalize(vec3(v, 1.));


    // raymarching by distance field
  	vec3 p = ro+rd ;
  	glow = vec3(0.);
  	for(int i=0; i<32; i++) {
    	p += rd * map(p);
  	}
    
    // glow + vignetting + gamma correction
  	vec3 col = glow;
  	col *= pow(uv.x*uv.y*(1.-uv.x)*(1.-uv.y), .8)*2.;
  	col = pow(col,vec3(1./2.2));
    
  	fragColor = vec4(col,1.);
}
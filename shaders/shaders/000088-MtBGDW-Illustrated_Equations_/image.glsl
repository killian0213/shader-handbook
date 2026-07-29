//  (image) — Illustrated Equations  by sben
// https://www.shadertoy.com/view/MtBGDW

// Created by sofiane benchaa - sben/2015
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
#define FIELD 20.0
#define ITERATION 12
#define CHANNEL bvec3(true,true,true)
#define PI4 0.7853981633974483
#define TONE vec3(0.299,0.587,0.114)

//triangle
vec2 triangleEQ( vec3 p, float t )
{
	vec2 h = vec2(0.0);
	vec3 q = abs(p);
	vec2 fx = vec2(1.0);
	fx.x = max(q.x*PI4+p.y*0.5,-p.y);
	return fx;
}
//regular trifolium
vec2 bretzTrifolEQ(vec3 p,float t){	
	vec2 fx = vec2(0.008);
	float x2 = p.x*p.x;
	float y2 = p.y*p.y;
	fx.x = (x2+y2)*(x2+y2)-p.x*(x2-3.0*y2);
	fx.x *= fx.x;
	fx.x += p.z*p.z;
	fx.x /=	fx.y;
	return fx;
}
//quad torus
vec2 quadTorusEQ(vec3 p,float t){
	vec2 fx = vec2(2.0);
	float x2 = p.x*p.x;
	float y2 = p.y*p.y;
	fx.x = x2*pow(1.0-x2,2.0)*pow(4.0-x2,3.0)-20.0*y2;
	fx.x *= fx.x;
	fx.x += 80.0*(p.z*p.z);
	fx.x /=  fx.y;
	return fx;
}
//lemniscat Bernoulli
vec2 bretzBernEQ(vec3 p,float t){
	vec2 fx = vec2(0.01);
	float x2 = p.x*p.x;
	float y2 = p.y*p.y;
	fx.x = ((x2+y2)*(x2+y2)-x2+y2);
	fx.x *= fx.x;
	fx.x /= fx.y;
	return fx;
}
//just a line
vec2 lineEQ(vec3 p,float t){
	vec2 fx = vec2(0.01);
	float r = 1.0;
	vec3 offset=vec3(0.0);
	p+=offset;
	float cx = clamp(p.x,-r,r);
	fx.x = p.y;
	fx.x *= fx.x;
	fx.x /= min(fx.y,abs(abs(cx)-r));
	
	return fx;
}
//iterative equation

//mandelbrot
vec2 complexEQ(vec3 c,float t){
	vec4 z = vec4(c,0.0);
	vec3 zi = vec3(0.0);
	for(int i=0; i<ITERATION; ++i){
		zi.x = (z.x*z.x-z.y*z.y);
		zi.y = (z.x*z.y+z.x*z.y);
		zi.xyz += c;
		if(dot(z.xy,z.xy)>4.0)break;
		z.w++;
		z.xyz=zi;
	}
	z.w/=float(ITERATION);
	return 1.0-z.wx;
}

//
vec2 wolfFaceEQ(vec3 p,float t){
	vec2 fx = p.xy;
	p=(abs(p*2.0));
	const float j=float(ITERATION);
	vec2 ab = vec2(2.0-p.x);
	for(float i=0.0; i<j; i++){
		ab+=(p.xy)-cos(length(p));
		p.y+=sin(ab.x-p.z)*0.5;
		p.x+=sin(ab.y)*0.5;
		p-=(p.x+p.y);
		p+=(fx.y+cos(fx.x));
		ab += vec2(p.y);
	}
	p/=FIELD;
	fx.x=(p.x+p.x+p.y);
	return fx;
}

vec2 dogFaceEQ(vec3 p,float t){
	vec2 fx = p.xy;
	p=(abs(p*2.0));
	const float j=float(ITERATION);
	vec2 ab = vec2(2.0-p.x);
	for(float i=0.0; i<j; i++){		
		ab+=p.xy+cos(length(p));
		p.y+=sin(ab.x-p.z)*0.5;
		p.x+=sin(ab.y)*0.5;
		p-=(p.x+p.y);
		p-=((fx.y)-cos(fx.x));
	}
	p/=FIELD;
	fx.x=(p.x+p.x+p.y);
	return fx;
}

vec2 pieuvreEQ(vec3 p,float t){
	vec2 fx = p.xy;
	fx.x = (fx.y+length(p*fx.x)-cos(t+fx.y));
	fx.x = (fx.y+length(p*fx.x)-cos(t+fx.y));
	fx.x = (fx.y+length(p*fx.x)-cos(t+fx.y));
	fx.x*=fx.x*0.1;
	return fx;
}


////////////////////////////////////////////////////////
vec3 computeColor(vec2 fx){
	vec3 color = vec3(vec3(CHANNEL)*TONE);
	color -= (fx.x);
	color.b += color.g*1.5;
	return clamp(color,(0.0),(1.0));
}

void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
	float time = iTime;
	float ratio = iResolution.y/iResolution.x;
	fragCoord.y *= ratio;
	vec2 position = ( fragCoord.xy / iResolution.xy )-vec2(0.5,0.5*ratio);
	vec3 p = position.xyx*FIELD;
	p.z = 2.0*FIELD*0.5;
	vec3 color = computeColor(wolfFaceEQ(p+vec3(5.0,0.0,0.0),time));
    
	color += computeColor(complexEQ(p+vec3(-5.0,-4.0,0.0),time));
    
	color += computeColor(triangleEQ(p+vec3(-5.0,-1.0,0.0),time));
	p.z = 0.0;
    
	color += computeColor(dogFaceEQ(p*2.0+vec3(0.0,0.0,0.0),time));
    
	color += computeColor(quadTorusEQ(p+vec3(-5.0,1.0,0.0),time));
    
	color += computeColor(bretzTrifolEQ(p+vec3(-6.0,3.0,0.0),time));
	color += computeColor(bretzBernEQ(p+vec3(-4.0,3.0,0.0),time));
	//color += computeColor(lineEQ(p+vec3(-5.0,4.5,0.0),time));
	color += computeColor(pieuvreEQ(p*2.5+vec3(-5.0,8.0,0.0),time));
	fragColor = vec4( color, 1.0 );

}
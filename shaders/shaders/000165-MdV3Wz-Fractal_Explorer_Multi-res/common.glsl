// Common (common) — Fractal Explorer Multi-res. by Dave_Hoskins
// https://www.shadertoy.com/view/MdV3Wz

float hash12(vec2 p)
{
	vec3 p3  = fract(vec3(p.xyx) * .1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}
float hash13(vec3 p3)
{
	p3  = fract(p3 * .1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}


float Scale = 4.;
float MinRad2 = 0.25;

float sr = 4.0;
vec3 fo =vec3 (0.7,.9528,.9);
vec3 gh = vec3 (.8,.7,0.5638);
vec3 gw = vec3 (.3, 0.5 ,.2);
vec4 X = vec4( .1,0.5,0.1,.3);
vec4 Y = vec4(.1, 0.8, .1, .1);
vec4 Z = vec4(.2,0.2,.2,.45902);
vec4 R = vec4(0.19,.1,.1,.2);
vec4 orbitTrap = vec4(40000.0);
//--------------------------------------------------------------------------
float DBFold(vec3 p, float fo, float g, float w){
    if(p.z>p.y) p.yz=p.zy;
    float vx=p.x-2.*fo;
    float vy=p.y-4.*fo;
    float v=max(abs(vx+fo)-fo,vy);
    float v1=max(vx-g,p.y-w);
    v=min(v,v1);
    v1=max(v1,-abs(p.x));
    return min(v,p.x);
}

vec3 DBFoldParallel(vec3 p, vec3 fo, vec3 g, vec3 w){
	vec3 p1=p;
	p.x=DBFold(p1,fo.x,g.x,w.x);
	p.y=DBFold(p1.yzx,fo.y,g.y,w.y);
	p.z=DBFold(p1.zxy,fo.z,g.z,w.z);
	return p;
}

float Map(vec3 p)
{
	vec4 JC=vec4(p,1.);
	float r2=dot(p,p);
	float dd = 1.;
	for(int i = 0; i< 6; i++){
		
		p = p - clamp(p.xyz, -1.0, 1.0) * 2.0;  // mandelbox's box fold

		//Apply pull transformation
		vec3 signs=sign(p);//Save 	the original signs
		p=abs(p);
		p=DBFoldParallel(p,fo,gh,gw);
		
		p*=signs;//resore signs: this way the mandelbrot set won't extend in negative directions
		
		//Sphere fold
		r2=dot(p,p);
		float  t = clamp(1./r2, 1., 1./MinRad2);
		p*=t; dd*=t;
		
		//Scale and shift
		p=p*Scale+JC.xyz; dd=dd*Scale+JC.w;
		p=vec3(1.0,1.0,.92)*p;

		r2=dot(p,p);
		orbitTrap = min(orbitTrap, abs(vec4(p.x,p.y,p.z,r2)));	
	}
	dd=abs(dd);
#if 1
	return (sqrt(r2)-sr)/dd;//bounding volume is a sphere
#else
	p=abs(p); return (max(p.x,max(p.y,p.z))-sr)/dd;//bounding volume is a cube
#endif
}
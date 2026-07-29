// Image (image) — Galaxy in a Sphere by atzedent
// https://www.shadertoy.com/view/tfV3W3

/*********
* made by Matthias Hurrle (@atzedent)
* CC0: Galaxy in a Sphere
* Playing with ideas from S. Guillitte's https://www.shadertoy.com/view/MtX3Ws
*/
#define move iMouse.xy
#define time iTime
#define FC fragCoord
#define R iResolution.xy
#define P (iMouse.z>.0?1:0)
#define T iTime
#define N normalize
#define S smoothstep
#define K (P>0?.01:mix(.01,6.3,fract(T*.2)))
#define MN min(R.x,R.y)
#define rot(a) mat2(cos((a)-vec4(0,11,33,0)))
#define hue(a) (.5+.5*sin(6.3*(a)+vec3(1,2,3)))
#define cmul(a,b) vec2(a.x*b.x-a.y*b.y,a.x*b.y+b.x*a.y)
float swirls(vec3 p) {
	vec3 c=p;
	float d=.1;
	for (float i=.0; i<5.; i++) {
		p=abs(p)/dot(p,p)-.7;
		p.yz=cmul(p.yz,p.zx);
		p=p.zxy;
		d+=exp(-19.*abs(dot(p,c)));
	}
	return d;
}
void anim(inout vec3 p) {
	p.yz*=rot(T*.2);
	p.xz*=rot(-.1/K*1.2+K*.2);
}
vec3 march(vec3 p, vec3 rd) {
	anim(p); anim(rd);
	vec3 col=vec3(0);
	float c=.0, t=.0;
	for (float i=.0; i<60.; i++) {
		t+=exp(-t*.64)*exp(-c*1.05);
		c=swirls(p+rd*t);
		col+=c*hue(sqrt(dot(p,p*1.25))-sqrt(sqrt(c))*1.2)*.008;
	}
	return col;
}
void cam(inout vec3 p) {
    p.yz*=rot(-(P>0?move.y*6.3/MN+3.14:.0)-K*.123);
	p.xz*=rot((P>0?3.14-move.x*6.3/MN:.0)-1./K-K*.1);
}
vec3 render(vec2 FC) {
	vec2 uv=(FC-.5*R)/MN;
	vec3 col=vec3(0),
	p=vec3(0,0,-2),
	rd=N(vec3(uv,.8)), lp=vec3(5,5,-5);
    cam(p); cam(rd); cam(lp);
	float dd=.0, at=.0;
	for (float i=.0; i<400.; i++) {
		float d=length(p)-1.;
		if (abs(d)<1e-3 || dd>3.) break;
		p+=rd*d;
		dd+=d;
		at+=.05*(.05/dd);
	}
	if (dd<3.) {
		vec3 n=N(p), l=N(lp-p);
		col+=march(p*4.,refract(rd,n,.98));
		float dif=clamp(dot(l,n),.0,1.), fres=pow(clamp(1.+dot(rd,n),.0,1.),3.),
		spec=pow(clamp(dot(reflect(rd,n),l),.0,1.),2.);
		dif=sqrt(dif);
		col=mix(col,vec3(S(1.,.9,dif))*sqrt(col),fres);
		col=mix(col,mix(vec3(.1,.2,.3),vec3(dif),1.),fres*fres);
        col=mix(col,texture(iChannel0,reflect(rd,n)).rgb,fres);
		col+=S(-.125,.75,.15*spec*hue(spec)+.15*spec);
		col=mix(col,vec3(1),fres*fres*.2);
		col=S(-.05,.8,col);
		col=max(col,.02);
	} else {
		col=mix(vec3(.1,.2,.3),vec3(.008),pow(S(.0,.65,dot(uv,uv)),.3));
		col+=sqrt(at*vec3(1,.7,.5));
        col=mix(col,S(-.25,1.5,S(1.,.25,dot(uv,uv))*texture(iChannel0,rd).rrr),dot(uv,uv));
		col+=at*vec3(1,.95,.8);
	}
	float t=min((time-.5)*.3,1.);
	col=mix(vec3(0),col,t);
	col=S(-.15,1.1,.9*col);
	return col;
}
void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
    vec3 col=render(FC);
    fragColor = vec4(col,1.0);
}
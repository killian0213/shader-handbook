// Image (image) — Night's Backbone by Kali
// https://www.shadertoy.com/view/fdyfDm

#define period 15.
#define fxrand floor(iTime/period)+iDate.z
#define hash1 rnd(fxrand)
#define hash2 rnd(fxrand+.111)
#define hash3 rnd(fxrand+.222)
#define hash4 rnd(fxrand+.333)
#define hash5 rnd(fxrand+.444)
#define hash6 rnd(fxrand+.555)
#define hash7 rnd(fxrand+.666)
#define hash8 rnd(fxrand+.777)
#define hash9 rnd(fxrand+.877)
#define hash10 rnd(fxrand+.997)
#define hash11 rnd(fxrand+1.11777)
#define hash12 rnd(fxrand+1.411777)

const mat2 m = mat2( 1.6, .2, -1.2,  1.6 );
vec2 uvd;
float zoom;

float hashh(vec2 p) {
	return fract(1e4 * sin(17.0 * p.x + p.y * 0.1) * (0.1 + abs(sin(p.y * 13.0 + p.x))));
}

float hash(vec2 p)
{
	vec3 p3  = fract(vec3(p.xyx) * .1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

float noise(vec2 x) {
	vec2 i = floor(x);
	vec2 f = fract(x);
	float a = hash(i);
	float b = hash(i + vec2(1.0, 0.0));
	float c = hash(i + vec2(0.0, 1.0));
	float d = hash(i + vec2(1.0, 1.0));
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
}

float fbm (in vec2 p) {

    float value = 0.0;
    float freq = 1.0;
    float amp = .5;

    for (int i = 0; i < 14; i++) {
        value += amp * (noise((p - vec2(1.0)) * freq));
        freq *= 1.9;
        amp *= 0.6;
    }
    return value;
}


mat2 rot(float a)
{
    float s=sin(a), c=cos(a);
    return mat2(c,s,-s,c);
}

float rnd(float p)
{
    p*=1234.5678;
    p = fract(p * .1031);
    p *= p + 33.33;
    return fract(2.*p*p);
}


float rand(float r){
	vec2	co=vec2(cos(r*428.7895),sin(r*722.564));
	return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
}


vec3 render(vec3 dir)
{
	float s=0.3,fade=1., fade2=1., pa=0., sd=0.2;
	vec3 v=vec3(0.);
    dir.y+=4.*hash4;
    dir.x+=hash5;
	for (float r=0.; r<15.; r++) {
		vec3 p=s*dir;
        mat2 rt=rot(r);
        p.xz*=rt;
        p.xy*=rt;
        p.yz*=rt;
		p = abs(1.-mod(p*(hash1*2.+1.),2.));
		float pa,a=pa=0.;
		for (int i=0; i<13; i++) {
			if (float(i)>mod(iTime,period)*10.) break;
			p=abs(p)/dot(p,p)-.7-step(.5,hash10)*.1;
			float l=length(p)*.5;
			a+=abs(l-pa);
			pa=length(p);
		}
        fade*=.96;
		sd+=.5;
		float cv=abs(2.-mod(sd,4.));
		v+=normalize(vec3(cv*2.,cv*cv,cv*cv*cv))*pow(a*.02,2.)*fade;
		v.rb*=rot(hash3*3.);
        v=abs(v);
		pa=a;
		s+=.05;
	}
	float sta=v.x;
	vec3 roj=vec3(1.5,1.,.8);
	uvd.x*=sign(hash12-.5);
	uvd*=rot(radians(360.*hash8));
	uvd.y*=1.+(uvd.x+.5)*1.;
	v=pow(v,1.-.5*vec3(smoothstep(.5,0.,abs(uvd.y))));
	v+=.04/(.1+abs(uvd.y*uvd.y))*roj*min(1.,iTime*.3);
	float core=smoothstep(.3,0.,length(uvd))*1.2*min(1.,iTime*.3);
	v+=core*roj;
	v=mix(vec3(length(v)*.7),v,.45);
	float neb=fbm(dir.xy*15.)-.5;
	uvd.y+=neb*.3;
	neb=pow(smoothstep(.8,.0,abs(uvd.y)),2.)*.9;
	v=mix(v*vec3(1.,.9,1.2),vec3(0.),max(neb,.7-neb)+core*.06-sta*.1);
	return pow(v,vec3(1.05))*1.2;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    zoom=iMouse.z>0.?2.:0.;
    vec2 uv = fragCoord/iResolution.xy-.5;
    uv.x*=iResolution.x/iResolution.y;
	uvd=uv;
	vec2 m=iMouse.xy/iResolution.xy-.5;
    m.x*=iResolution.x/iResolution.y;
	float fade=.5;
	if (step(.3,length(uv-m))<.5&&zoom>0.1) {
		float zo=.4/zoom;
		uv-=m;
		uvd-=m;
		uv*=zo;
		uvd*=zo;
		uv+=m;
		uvd+=m;
		fade=1.;
	}
    vec3 dir=normalize(vec3(uv,1.));
    vec3 col = render(dir);
    fragColor = vec4(col,1.0);
}
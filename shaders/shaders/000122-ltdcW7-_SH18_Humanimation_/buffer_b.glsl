// Buffer B (buffer) — [SH18]  Humanimation  by pellicus
// https://www.shadertoy.com/view/ltdcW7

// my SH18 Entry:  
// inspired by this ref https://www.youtube.com/watch?v=kT-I26uFv9M
// The idea is: 
// what ever you draw .. if it's animated like a human... becomes a human!
// i've tons of ideas to try and for sure could be an interesting starting
// point to make some demoscene stuff :D. at least for me.
//
// Animation: 
// 	Samba Dance fbx from www.mixamo.com 
// 	
// Music:
//	BarretoVSLujan Feat. Rozalla E Nikki - Everybody Free Samba (Edih Bueno Mega Mush! Work)
//
// bufA : playback and interpolation of the animation points (pin)
// bufB : modeling and rendering and very simple lighting of the scene
// Image: compositing with some little fx activated by camera change

// modeling, rendering, lighting (veeeery stupid lighting).

vec3 pins(int x) { 	return texelFetch(iChannel0,ivec2(x,0),0).xyz; }
vec3 pins(int x,int to) { 	return texelFetch(iChannel0,ivec2(x,to),0).xyz; }

//modeling features
float puftyfx =0.;
float macho =0.0;
float fatty = 0.;
float pompom =0.;
float faceted=0.;
float springs =0.0;
//bool floormix =false;


// probably i could easily avoid this structure...
struct Camera
{
    vec3 right;//Right, 
    vec3 up;//Up,
    vec3 dir;//Direction,
    vec3 pos;//origin (pos)
};

Camera cam;
/*  
vec3 UpdateCamera(vec2 uv, float t,float uvscl,float zoom)
{
 	if(iMouse.z>0.)
    {
    	t = 2.0*PI*(iMouse.x/iResolution.x);
    }
    cam.pos = vec3(cos(t),sin(t)*.45+0.8,1.2)*zoom;
    cam.dir = normalize(vec3(0,1.0,0.0)-cam.pos);
    cam.right = normalize(cross(cam.dir,vec3(0,1,0)));
    cam.up = cross(cam.right,cam.dir);
    uv*=uvscl;
   return normalize(uv.x*cam.right+uv.y*cam.up+cam.dir);
}
*/
vec3 SetCamera(vec2 uv, vec3 from,vec3 to,float uvscl)
{
   	// here some user mouse interaction..
    vec3 useroff=vec3(0.);
    if(iMouse.z>0.)
    {
        useroff = vec3((iMouse.xy/iResolution.xy)*2.5,0.);
    }
    cam.pos = from+useroff;
    cam.dir = normalize(to-cam.pos);
    cam.right = normalize(cross(cam.dir,vec3(0,1,0)));
    cam.up = cross(cam.right,cam.dir);
    uv*=uvscl;
   return normalize(uv.x*cam.right+uv.y*cam.up+cam.dir);
}

// not sure if it's a good idea.. 

struct Trace
{
    vec2	uv;
    float 	z;
    vec3 	n;
    vec3 	p;
    
    int		id;
};
   
Trace trc;
   

#define MATERIALS_NUM 3
#define ID_SKIN 1.
#define ID_FLOOR 2.
#define ID_WALL 3.
#define ID_MIX -1.



float oS( float d1, float d2 )
{
    return max(-d2,d1);
}

vec4 oU( vec4 d1, vec4 d2 )
{
    return (d1.x<d2.x) ? d1 : d2;
}

float smin(in float a, in float b) 
{ const float k=80.;
    return a - log(1.0+exp(k*(a-b))) * (1. / k); 
}
float smin(in float a, in float b,const float k) 
{ 
    return a - log(1.0+exp(k*(a-b))) * (1. / k); 
}
//iq's  polynomial smooth min https://iquilezles.org
float oB( float a, float b ) {
    const  float k = 0.207821;
    float h = clamp( 0.5+0.5*(b-a)/k, 0.0, 1.0 );
    return mix( b, a, h ) - k*h*(1.0-h);
}
float oB2( float a, float b ) {
    const  float k =0.9207821;
    float h = clamp( 0.5+0.5*(b-a)/k, 0.0, 1.0 );
    return mix( b, a, h ) - k*h*(1.0-h);
}

vec4 oMix(vec4 d1,vec4 d2)
{
	return vec4(oB2(d1.x,d2.x),d1.x<d2.x?d1.yzw:d2.yzw*2.);
}

float sdSph( const vec3 p, const float s )
{
    return length(p)-s;
}
float sdCap( const vec3 p,const  vec3 a, const vec3 b, const float r )
{
    vec3 pa = p-a, ba = b-a;
    float h = clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );
    return length( pa - ba*h ) - r;
}

float sdCap2Original(const vec3 p, const vec3 a, const vec3 b, const float r1,const  float r2) {
    vec3 pa = p - a, ba = b - a;
    float h = clamp(dot(pa,ba)/dot(ba,ba), 0., 1. );
    return length( pa - ba*h ) - mix(r1,r2,h);
}

// to optimize for sure .. 
float cos01(const float x)
{
	return (cos(x)+1.)*.5;
}
// Springs
float sdCap2(const  vec3 p, const vec3 a, const vec3 b, const float r1,const  float r2) {
    vec3 pa = p - a, ba = b - a;
    float h = clamp(dot(pa,ba)/dot(ba,ba), 0., 1. );
    vec3 j=ba*h;
    vec3 pj = pa - j ;
    float ph=length( pj )- cos01(h*PI2*8.)*springs;
    return ph - (mix(r1,r2,h));
}



// SETTINGS RAYMARCHER
#define MIN_DIST 	0.001
#define MAX_DIST	13.
#define MAX_ITERATIONS	60

#define BOUNDS 1.7


float sdHuman(const vec3 p)
{
    // feature: chest/arms biggy
//    float k=sin(iTime)*0.25;
	//float as=1.25+k;
    
    float as =1.0+1.5*macho;
    float ls =1.0+0.6*macho; 
    
 	vec3 r=pins(ROOT),t,n,s,l,sl,sr;
	float z = sdCap2(p,r,s=pins(SPINE),0.16,0.12);
    n=pins(NECK);
    t=pins(HEAD);
	z = min(z,sdCap2(p,n, t+(t-n)*0.6 ,0.0577,0.13));

    z = smin(z,sdCap2(p,s,sl=pins(LSHOULDER),0.160797,as*0.0813));
    z = smin(z,sdCap2(p,s,sr=pins(RSHOULDER),0.160797,as*0.0813));
    z = oB(z,sdCap(p,sl,sr,0.1));
    
    z = min(z,sdCap2(p,sl,t=pins(LELBOW),0.08*as,0.068*as));
	 z = min(z,sdCap2(p,t,l=pins(LHAND),0.068*as,0.052));
    
    z = min(z,sdCap2(p,sr,t=pins(RELBOW),0.08*as,0.068*as));
	 z = min(z,sdCap2(p,t,r=pins(RHAND),0.068*as,0.052));
    
    z = smin(z,sdCap2(p,r=pins(RHIP),t=pins(RKNEE),0.14*ls,0.09));
    z = min(z,sdCap2(p,t,r=pins(RANKLE),0.093,0.0889));
    z = min(z,sdCap2(p,r,t=pins(RFOOT),0.0889,0.0809));
    s=t-r;s.y=0.;
    z = min(z,sdCap2(p,t,t+normalize(s)*.1,0.08,0.06));

//        z = min(z,dCap2(p,t,r=pins(RTOE),0.09,0.06));
    z = smin(z,sdCap2(p,r=pins(LHIP),t=pins(LKNEE),0.14*ls,0.09));
	 z = min(z,sdCap2(p,t,r=pins(LANKLE),0.093,0.0889));
    z = min(z,sdCap2(p,r,t=pins(LFOOT),0.0889,0.0809));
 //   z = min(z,dCap2(p,t,r=pins(LTOE),0.09,0.06));
     s=t-r;s.y=0.;
    z = min(z,sdCap2(p,t,t+normalize(s)*.1,0.08,0.06));

    //feature: fat-ring
    z-= puftyfx*.15;
    
	//z-=clamp(sin(iTime)*0.30,-0.025,5.0);

	return z;
}

float sdFat(const vec3 p)
{
    float k=1.0 + 0.1;
 	vec3 r=pins(ROOT,2),t,n,s,l,sl,sr;
//	float z = sdCap2(p,r,s=pins(SPINE),0.15,0.13);
    float z = sdSph(p-r,0.26);
    z = oB(z, sdSph(p-(pins(SPINE)+vec3(0.,.07,0. )),0.23) );
    vec3 oass=vec3(0.,0.1,0.);
    
    vec3 lhip=pins(LHIP,3);
    vec3 rhip=pins(RHIP,3);
    vec3 back=-cross(rhip-lhip,vec3(0.,1.,0.)) * 0.35;
    z = smin(z, sdSph(p-(rhip + back   ),0.20) , 50.);
     z =smin(z, sdSph(p-(lhip + back   ),0.20) ,50.);
    z = smin(z,sdCap2(p,r=pins(RHIP,2),t=pins(RKNEE),0.20,0.09));
    
    z = smin(z,sdCap2(p,r=pins(LHIP,2),t=pins(LKNEE),0.20,0.09));

 	z-=0.031;
	return z;
}

float sdTrail(const vec3 pos,const int pin,const int n,float sz)
{
        float szdec=sz/float(n);
        vec3 off=vec3(0);
        float z=1000.;
    	for(int h=0;h<n;h+=2)
        {
            // changed! the iq's sphere-thing purple primitive :D 
            // for performance reason.
            z = min( z, sdSph( pos-(pins(pin,h)+off), sz ) + 0.03*sin(50.0*pos.x)*sin(50.0*pos.y)*sin(50.0*pos.z) );
	 //	    z = min(z,sdCapStrk(p,pins(pin,h)+off,pins(pin,h+1)+off-vec3(szdec),sz,sz-szdec  ));
            sz-=szdec;
            off-=vec3(szdec);
        }        
	return z;
}

vec4 sdRoom(const vec3 p)
{

    vec4 r=vec4(p.y,ID_FLOOR,p.xz);
	r=oU(r,vec4(p.z+5.,ID_WALL,p.xy));
    
    return r;
}


vec4 sdScene(const vec3 p ,const bool human)
{	
    vec4 r=sdRoom(p);
    if(human)
    {
        
        
 		 float z=sdHuman(p);
        if(fatty>0.)
	        z=mix(z,smin(z,sdFat(p)),fatty);
        if(pompom>0.)
        {
        z=smin(z,sdTrail(p,LHAND,10,pompom));
        z=smin(z,sdTrail(p,RHAND,10,pompom));
        }
       // here there are space for experimentations :D
      //  for(time_offset=0;time_offset<2;time_offset++)
       //     z=min(z,sdHuman(p));
        
     //    r=floormix?oMix(r,vec4(z,ID_MIX,p.xy)) :
        r=oU(r,vec4(z,ID_SKIN,p.xy)) ;
    }
	return r;
}
    

float rAABB( in vec3 roo, in vec3 rdd, in vec3 rad )
{
    vec3 m = 1.0/rdd;
    vec3 n = m*roo;
    vec3 k = abs(m)*rad;
    
    vec3 t1 = -n - k;
    vec3 t2 = -n + k;
    
    float tN = max( max( t1.x, t1.y ), t1.z );
    float tF = min( min( t2.x, t2.y ), t2.z );
    if( tN > tF || tF < 0.0) return MAX_DIST;
    
    return tN;
}
float rSphere(vec3 o, vec3 d,const vec3 c,const float r)
{
    vec3 e= c - o;
    float a= dot(e, d);
    float b= r*r - dot(e,e) + a*a;
    if(b<0.0)
        return -1.;
    return  a- sqrt(b);
  }


vec4 Raymarcher(vec3 p,vec3 dir,bool A)
{
    float tmin = 1.8;// rFloor(p,dir,0.035);
    
    if(A)
    {
   		 float h=rSphere(p,dir,pins(0)+vec3(0,-0.21,0),BOUNDS);
  		  tmin=min(tmin,h);
    }
    float tmax = MAX_DIST;
    float t = tmin;
    vec4  dist = vec4(MAX_DIST,0.,0.,0.);
    for( int i=0; i<MAX_ITERATIONS; i++ )
    {
	    dist = sdScene( p+dir*t ,A);
        if( (dist.x)<MIN_DIST || t>MAX_DIST ) break;
        t += dist.x;
    }
    
    return vec4( t, dist.yzw );

}


vec3 GetNormal( in vec3 p ,const bool A)
{
/*	const float d = 0.01;
     const vec2 e = vec2(d,-d);
    return normalize( e.xyy*sdScene( p + e.xyy, A ).x +  e.yyx*sdScene( p + e.yyx, A ).x + 
					  e.yxy*sdScene( p + e.yxy, A ).x +  e.xxx*sdScene( p + e.xxx, A ).x );
*/
    //I love it! from Klems!
    vec4 n = vec4(0);
    for (int i = 0 ; i < 4 ; i++) {
        vec4 s = vec4(p, 0);
        s[i] += 0.001;
        n[i] = sdScene(s.xyz,A).x;
    }
    return normalize(n.xyz-n.w);


}



float AO( in vec3 ro, in vec3 rd,bool A ) {
	float occ = 0.0;
    float sca = 1.0;
    
   for( int i=0; i<5; i++ ) {
        float h = 0.001 + 0.25*float(i)/4.0;
        float d = sdScene( ro+rd*h, A ).x;
        occ += (h-d)*sca;
        sca *= 0.95;
    }
    return clamp( 1.0 - 1.2*occ, 0.0, 1.0 );    
}
// not used..
/*
float softshadow(in vec3 ro, in vec3 rd){
    float res = 1.0, t = 0.15; 
    for(int s = 0; s < 26; ++s){
        float h = sdScene(ro + rd*t,true).x;
        if(h < 0.001) return 0.0;
        res = min( res, 2.0*h/t );
        t += h*0.339;
    }
    return res;
}
*/

// sorry .. i dont remember where i found this piece of code
// the idea is to make a sort of low poly thing.
vec2 qu(vec2 v)
{
	float n = 2.0;
	return floor(v * n + 0.15) / n;
}

vec3 faceted_normal(vec3 n)
{
	vec3 an = abs(n);
	
	if(an.x > an.y && an.x > an.z)
	{
		n.yz = qu(n.yz / n.x);
		n.x = 1.0;
	}
	else if(an.y > an.x && an.y > an.z)
	{
		n.xz = qu(n.xz / n.y);
		n.y = 1.0;
	}
	else if(an.z > an.y && an.z > an.x)
	{
		n.xy = qu(n.xy / n.z);
		n.z = 1.0;
	}
    return n; 
}


vec2 getUV(vec3 nor)
{
    float lon = atan(nor.x,nor.z)/3.14;
    float lat = acos(nor.y)/3.14;
    vec2 r = vec2(lat, lon);
    
    return r;
}
bool TraceScene(vec3 p,vec3 dir,bool A)
{
  	vec4 c;  
    //vec4 h=vec4(MAX_DIST,ID_VOID,dir.xy);
	vec4 r=Raymarcher(p,dir,A);
    if(r.x>MAX_DIST)
        return false;  // skycolor.
    
    trc.p =p+r.x*dir;
    trc.uv = r.zw;
	
    trc.id = int(r.y);
    trc.z = r.x;
    if(trc.id<=int(ID_SKIN))
    {
    	trc.n =GetNormal(trc.p,A);
        trc.uv = getUV(trc.n);
        if(faceted>0.)
      		trc.n = faceted_normal(trc.n);

    }
    else    
   		 trc.n =   trc.id==int(ID_FLOOR)?vec3(0,1,0):vec3(0,0,1);
    return true;
}



// from https://www.shadertoy.com/view/4dsSzr
vec3 hueGradient(float t) {
    vec3 p = abs(fract(t + vec3(1.0, 2.0 / 3.0, 1.0 / 3.0)) * 6.0 - 3.0);
	return (clamp(p - 1.0, 0.0, 1.0));
}



// BleepyBlocks https://www.shadertoy.com/view/MsXSzM by Daedalus
#define TIMESCALE 0.225 
#define TILES 8
vec4 BleepyBlocks(  const  vec2 uv,const vec4 color )
{
	
	vec4 noise = texture(iChannel1, floor(uv * float(TILES)) / float(TILES));
	float p = 1.0 - mod(noise.r + noise.g + noise.b + iTime * float(TIMESCALE), 1.0);
	p = min(max(p * 3.0 - 1.8, 0.1), 2.0);
	
	vec2 r = mod(uv * float(TILES), 1.0);
	r = vec2(pow(r.x - 0.5, 2.0), pow(r.y - 0.5, 2.0));
	p *= 1.0 - pow(min(1.0, 12.0 * dot(r, r)), 2.0);
	
	return color * p+ color*0.45;
}


// Plasma 
// from https://www.shadertoy.com/view/4ssyRB by FabriceNeyret2
// .. the same on the towel in the Shadertoy Island :D.
float plasma_noise3( vec3 x ) 
{
    vec3 p = floor(x),f = fract(x);

    f = f*f*(3.-2.*f);  // or smoothstep     // to make derivative continuous at borders

#define plasma_hash3(p)  fract(sin(1e3*dot(p,vec3(1,57,-13.7)))*4375.5453)        // rand
    
    return mix( mix(mix( plasma_hash3(p+vec3(0,0,0)), plasma_hash3(p+vec3(1,0,0)),f.x),       // triilinear interp
                    mix( plasma_hash3(p+vec3(0,1,0)), plasma_hash3(p+vec3(1,1,0)),f.x),f.y),
                mix(mix( plasma_hash3(p+vec3(0,0,1)), plasma_hash3(p+vec3(1,0,1)),f.x),       
                    mix( plasma_hash3(p+vec3(0,1,1)), plasma_hash3(p+vec3(1,1,1)),f.x),f.y), f.z);
}

// pseudoperlin improvement from foxes idea 
#define plasma_noise(x) (plasma_noise3(x)+plasma_noise3(x+11.5)) / 2. 

vec4 plasma(vec2 uv,vec4 amb)
{
  float n = plasma_noise(vec3(uv,.1*iTime)),
          v = sin(6.28*10.*n);
  	  v = smoothstep(0.,1., .7*abs(v)/fwidth(v));
    n = floor(n*20.)/20.;
    return vec4(dot(vec3(.2126, .7152, .0722),v * (.5+.5*cos(12.*n+vec3(0,2.1,-2.1)))) * amb.rgb,1.); 
}

// --------------------------------------------------------------------
vec4 EvaluateMaterials(vec3 p,vec3 dir,const bool A)
{
    float t=floor(iTime*.5);
    vec4 wall_color= hueGradient(mod(t,8.)/8.).xyzx;
    vec4 floor_color= hueGradient(mod(t+4.,8.)/8.).xyzx;
    
    const vec3 ldir=normalize(vec3(.0,1.,-1.0));
    vec3 n = trc.n;
    vec3 hv = normalize(-dir+ldir);
    vec4 spec=vec4(1.)*pow( max(0.0, dot(hv, n)) , 28.2);
    
       float ao=(A&& trc.p.z>-1.50)?AO(trc.p,trc.n,A):1.;
//    float shd=softshadow(trc.p,-ldir);
 	//shd=min(shd,ao);
    vec4  o = vec4( -dot(trc.n, ldir));
 
    float ff=(1.-length(trc.p-vec3(0,1.5,-3.5))/7.5);
    if(trc.id == int(ID_FLOOR))
       o=(ff+vec4(0.1))*BleepyBlocks(trc.uv*0.25,floor_color);
//    texture(iChannel3,trc.uv*.5)*
    if(trc.id == int(ID_WALL))
       o=plasma(trc.uv*1.2,wall_color)*ff;
 	if(trc.id <= int(ID_SKIN))
    {
          o = o*floor_color*vec4(0.35) +(vec4(1.)-o)*wall_color*vec4(0.25); //*vec4( dot(trc.n, ldir));
    		//o+=gaussianSpecular(-ldir,dir,trc.n,1.5);
        if(trc.id<0)
     	  o=o*(BleepyBlocks(trc.uv*0.25,floor_color)+vec4(0.2));
		else
           o=o+(texture(iChannel2,trc.uv)*.5 );
        o+=spec;
    
    }
    return o*ao;
	

}


//----------------------------------------------------------------------------------------------


void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
	vec2 uv = fragCoord.xy / iResolution.xy;
    
    vec2 suv = (fragCoord.xy-0.5*iResolution.xy) / iResolution.xx;
    float t = iTime*0.512;
    vec3 campos=vec3(2.0,0.2,2.5);
       
    vec3 camat=vec3(0,1.2,0.0);
    float camscl=1.15;
    
   // camat=pins(ROOT);
    fatty = iMouse.w/360.;
   
    int  scene=int(floor(t*0.25));
   
    int camchg=scene%4; 
   
    
   // puftyfx=1.;
   // macho=1.0;
    // fatty=0.;
  //  floormix=true;

    vec4 features[]=vec4 [] ( vec4(0),vec4(0.,0.,1.,0.),vec4(0,0,0,.3),vec4(1,0,0,0),
                              vec4(0,1,0,0), vec4(0.5,0.25,0.75,0.1));
    vec4 feat=features[scene% 6];
      puftyfx=feat.x;
      macho=feat.y;
      fatty=feat.z;
	  pompom=feat.w;
  //  floormix=true;
      faceted=scene%5==3?1.:0.;
    
    if(fatty>0.)
        macho = fatty*0.5;
    
   // camchg=3;
    if(camchg==0) { campos = vec3(cos(t),sin(t)*.45+0.8,1.2)*2.3; camat=vec3(0,1,0); 
                   camscl=2.5; 
                  }
    if(camchg==1) {  campos=vec3(2.0,0.2,2.5)+vec3(cos(t*.5)+1.,0.,sin(t*.5)+1.);
       					camat=vec3(0,1.2,0.0);
			    		camscl=1.15; }
    if(camchg==2) { 
    	campos=vec3(-2.0,0.25,3.0)+vec3(cos(t*.5)+1.,0.,sin(t*.5)+1.)*0.25;
       					camat=pins(ROOT);
			    		camscl=1.45;
    	}
    if(camchg==3) { 
    	campos=vec3(0.0,3.25,0.50)+vec3(cos(t*.5)+1.,0.,sin(t*.5)+1.)*0.25;
       					camat=pins(ROOT);camat.y=0.5;camat.z-=0.6;
			    		camscl=2.45;
    	}
    if(scene>=5 && scene<=7)
        springs=0.05;
    if(scene>9)
        springs=cos01(iTime*3.)*0.06;
    
    
    vec3 ray=SetCamera(suv,campos,camat,camscl);

    
    bool A=rSphere(cam.pos,ray,pins(0)+vec3(0,-0.21,0),BOUNDS)>0.;
	
    fragColor=vec4(0.);
    if(TraceScene(cam.pos,ray,A))
    {
    	fragColor=EvaluateMaterials(cam.pos, ray,A);
    }
    
    
}
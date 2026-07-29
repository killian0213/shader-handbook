// Image (image) — Hope by ocb
// https://www.shadertoy.com/view/MllfDX

// Author: ocb
// Title: Hope 

/***********************************************************************
Trying another algorithm to generate city.
Here I am using what I may call "variable size voxels".
In this shader the voxels are 2d as horizontal grid
I am using 3 grids with 3 differents sizes (sizes are not multiples)
with a little shift.
So the interconnection of these grids generates infinite lower-sized squares.

The algorithm is in the 3 first functions.

The trace function goes from square to square.
The map return the height of the square
the getNextPlan function return the closest "square wall".


************************************************************************/

#define PI 3.141592653589793
#define PIdiv2 1.57079632679489
#define TwoPI 6.283185307179586
#define INFINI 1000000.
#define MAXSTEP 127
#define TOP_SURFACE 2.81

#define SKY 1
#define BLOC 2
#define WIN 3
#define SIDE 4


#define moonCtr vec3(.10644925908247,.266123147706175,.958043331742229)
#define moonShad vec3(-.633724250524478,.443606975367135,.633724250524478)
#define moonRefl vec3(.477784395284944,.179169148231854,.8600119115129)

int hitObj = SKY;
float hitScale = 1.;

float Hsh(in float v) { 						
    return fract(sin(v) * 437585.);
}


float Hsh2(in vec2 st) { 						
    return fract(sin(dot(st,vec2(12.9898,8.233))) * 43758.5453123);
}

// thanks IQ
float smin( float a, float b, float k )
{
    float h = clamp( 0.5+0.5*(b-a)/k, 0.0, 1.0 );
    return mix( b, a, h ) - k*h*(1.0-h);
}


/*
this function return the closest side of a squared defined by 3 overlapping grids.
The scales are .13, .21, .47 so they almost never match together generating smaller
squares between their intersections.
Not necessary, but here I add a shift (-.7) and (-.3) to shift the grids from the other.
From a position inside a square, the distance to the previous side is fract() and the distance
to the next side is 1-fract. Next and previous depend on the direction of the ray vector
(here v).
So d (depending on the sign of v),represent 1 in case of 1-fract()
The whole is divided by the ray to obtain the t parameter to reach the side.

This is done for the 3 grids.
Then selecting the smallest one (closest) in both direction (xz)
and finally keeping the smallest one.

Normal is returned too.
*/

vec4 getNextPlan(in vec2 xz, in vec2 v, in float t){
    vec2 s = sign(v);
    vec2 d = step(0.,s);
	vec2 dtp = (d-fract(xz*.13))/.13/v;
    vec2 dtq = (d-fract((xz-.7)*.21))/.21/v;
    vec2 dtr = (d-fract((xz-.3)*.47))/.47/v;

    vec2 dmin = min(min(dtp,dtq),dtr);
    float tmin = min(dmin.x, dmin.y);
    
    s *= -step(dmin,vec2(tmin));
    
    return vec4(vec3(s.x,0.,s.y),tmin);
}


/*
map() function generates the 3 grids.
A random height is found for each square of each grid Hp, Hq, Hr
Pp Pq and Pr are the probability for a square to have a non-null/null value.

The final height of the sub square is a weighted sum of each of the 3 grid square.
*/

float map(in vec2 xz)
{
    vec2 p = floor(xz*.13)/.13;
    vec2 q = floor((xz-.7)*.21)/.21;
    vec2 r = floor((xz-.3)*.47)/.47;
    
    float Hp = Hsh2(p), Hq = Hsh2(q), Hr = Hsh2(r);
    float Pp = step(.6,Hp), Pq = step(.6,Hq), Pr = step(.5,Hr);
    
    float tex = 1.*Hp*Pp + .5*Hq*Pq +.3*Hr*Pr;	  
    hitScale = Pp + 2.5*Pq + 5.*Pr;
    
    return tex;
    
}



/*
Trace() is the raytracing function.
First of all, find the entry point on the Top surface. Top surface represents the highest
value for the bulding. So we do not cross dozen of voxels when there is no chance
to hit the "floor" of a voxel (building).

When under the top surface the ray will navigate from a voxel to another using the 
getNextPlan() function.

p is the position reached.

we mesure the distance of p from the floor (map(p)) and from the closest "voxel wall" getNextPlan(p)
if map(p) is the closest, the ray hit the floor in this voxel, break.
if wall is the closest, go to the next voxel.

When entering a new voxel, check if below the floor.
if below the floor, so you hit a building wall, return wall info, break.

Not sure to be clear...
*/

vec4 trace(in vec3 pos, in vec3 ray)
{
    float dh = 0.;
    float t = 0.;
    if(pos.y > TOP_SURFACE){
        if(ray.y >= 0.) return vec4(vec3(0.),INFINI);
		t = (TOP_SURFACE - pos.y)/ray.y + 0.00001;
    }
    
    vec4 wall = vec4(0.);
    
    for(int i = 0;i<MAXSTEP;i++){
        
        vec3 p = pos+t*ray;
        if(p.y > TOP_SURFACE) break;
        
        float dh = p.y - map(p.xz);
        if(dh<.0) return vec4(wall.xyz,t-.00001);
        
        wall = getNextPlan(p.xz,ray.xz,t);
        float tt = 0.;
        if(ray.y < 0.){
        	float th = dh/(-ray.y);
            tt = min(wall.w,th);
            if(tt==th) return vec4(0.,1.,0.,t+tt);
        }
        else tt = wall.w;
        
        t+= tt+.00001;
        if(t>250.) break;
    }
    
    
    return vec4(0.,0.,0.,INFINI);
}


vec4 boxImpact( in vec3 pos, in vec3 ray, in vec3 ctr, in vec3 dim) 
{
    vec3 m = 1.0/ray;
    vec3 n = m*(ctr-pos);
    vec3 k = abs(m)*dim;
	
    vec3 t1 = n - k;
    vec3 t2 = n + k;

	float tmax = max( max( t1.x, t1.y ), t1.z );
	float tmin = min( min( t2.x, t2.y ), t2.z );
	
	if( tmax > tmin || tmin < 0.0) return vec4(vec3(0.),INFINI);

    vec3 norm = -sign(ray)*step(t2, vec3(tmin));
    return vec4(norm, tmin);
    
}


bool checkWindow(in vec3 ctr){
    float hash = Hsh2(ctr.xz+ctr.yy);
    float a = step(.3,hash)*step(mod(ctr.y,10.),0.);
    float b = step(.6,hash)*step(mod(ctr.y-1.,10.),0.);
    return bool(a+b);
}

vec4 traceWindow(in vec3 pos, in vec3 ray, in float t, in vec3 norm){
    vec3 p = pos + t*ray;
    vec4 info = vec4(norm,t);

    vec3 boxDim = vec3(.25,.025,.25);
	vec3 boxCtr;
    
    for(int i=0; i<5; i++){
    	boxCtr = vec3(floor(p.x*2.),floor(p.y*20.),floor(p.z*2.));
        if(checkWindow(boxCtr)){
            hitObj = SIDE;
            float tf = t + .1/dot(ray,-norm);
            info = boxImpact(pos, ray, (boxCtr+.5)*vec3(.5,.05,.5), boxDim);
            if(tf < info.w){
                hitObj = WIN;
                info = vec4(norm,tf);
                break;
            } 
            p = pos + (info.w+.001)*ray;
        }
        else break;
    }
    return info;
}

vec3 moonGlow(in vec3 ray){
    float a = dot(moonCtr, ray);
    float dl = dot(moonRefl,ray);
    float moon = smoothstep(.9,.902,a);
    float shad = 1.-smoothstep(.4,.7,dot(moonShad, ray));
    float refl = .7*smoothstep(.99,1.,dl);
	float clouds = min(1.,2.*texture(iChannel1,vec2(2.,-2.)*ray.xy-vec2(.2,.3)).r);
    vec3 col = .8*(vec3(0.,.3,.6)+(1.-clouds))*moon+refl;
    col += vec3(.3,.5,.8)*smoothstep(.88,.90,a)*(1.-smoothstep(.89,.95,a))*(dl-.9)*15.;
	col *= shad;
    col -= vec3(.1,.3,.5)*(1.-moon*shad);
    col = clamp(col,0.,1.);
    return col;
}

vec3 stars(in vec3 ray){
    vec3 col = vec3(0.);
    float az = atan(.5*ray.z,-.5*ray.x)/PIdiv2;
    vec2 a = vec2(az,ray.y);
    
    float gr = .5+a.x+a.y;
    float milky = 1.-smoothstep(0.,1.2,abs(gr));
	float nebu = 1.-smoothstep(0.,.7,abs(gr));

    vec3 tex = texture(iChannel3,a+.3).rgb;
    vec3 tex2 = texture(iChannel3,a*.1).rgb;
	vec3 tex3 = texture(iChannel3,a*5.).rgb;
	float dark = 1.-smoothstep(0.,.3*tex.r,abs(gr));
    
    vec2 dty =a*12.;
    col += step(.85,Hsh2(floor(dty)))*(tex+vec3(.0,.1,.1))*max(0.,(.01/length(fract(dty)-.5)-.05));
    
    dty =a*30.;
    col += step(.8,Hsh2(floor(dty)))*tex*max(0.,(.01/length(fract(dty)-.5)-.05))*milky;
    
    dty =a*1000.;
    col += max(0.,Hsh2(floor(dty))-.9)*3.*tex3*milky;
    
    col += (.075+.7*smoothstep(.1,1.,(tex+vec3(.15,0.,0.))*.3))*nebu;
    col += .5*smoothstep(0.,1.,(tex2+vec3(0.,.2,.2))*.2)*milky;
	col -= .15*(tex3 * dark);
    
    return col;
}

vec3 fewStars(in vec3 ray){
	vec3 col = vec3(0.);
    float az = atan(.5*ray.z,-.5*ray.x)/PIdiv2;
    vec2 a = vec2(az,ray.y);
    
    vec3 tex = texture(iChannel3,a+.3).rgb;
    vec2 dty =a*14.;
    col += step(.85,Hsh2(floor(dty)))*(tex+vec3(.0,.1,.1))*max(0.,(.01/length(fract(dty)-.5)-.05));

    return col*(1.-smoothstep(.6,.9,dot(moonCtr,ray)));
}


bool shadTrace(in vec3 pos, in vec3 v){
	float dh = 0.;
    float t = 0.;
    vec4 wall = vec4(0.);
    
    for(int i = 0;i<10;i++){       
        vec3 p = pos + t*v;
        if(p.y > TOP_SURFACE) break;       
        float dh = p.y - map(p.xz);
        if(dh<.0) return true;       
        wall = getNextPlan(p.xz,v.xz,t);       
        t+= wall.w + .0001 ;
    }   
    return false;   
}

float shadow(in vec3 p){
    p += .00001*moonRefl;
    if(shadTrace(p,moonRefl)) return .2;
    else return 1.;
}

vec3 winGlow(in vec2 uv){
    uv.x *= .2;
    uv.y *= .5;
    vec2 k1 = (uv-.05*sin(uv*10.))*10.,
         k2 = (uv-.02*sin(uv*25.))*25.,
         k3 = (uv-.01*sin(uv*50.))*50.;
    
    
    vec2 p = floor(k1)/10.,
         q = floor(k2)/25.,
    	 s = floor(k3)/50.;
    
    vec2 bp = abs(fract(k1)-.5)
    		+ abs(fract(k2)-.5)
    		+ abs(fract(k3)-.5);
    bp /= 1.5;
    bp*=bp*bp;
    
    vec3 tex = texture(iChannel2,p).rgb
    		 + texture(iChannel2,q).rgb
    		 + texture(iChannel2,s).rgb;
    
    tex += .5*(bp.x+bp.y);
    tex *= smoothstep(1.,2.8,tex.r);
    
	return tex;
}


float metalPlate(in vec2 st){
    float coef = 0.;
    
    vec2 p = floor(st);
    float hp = Hsh2(p*0.543234); hp *= step(.2,abs(hp-.5));
    vec2 fp = fract(st)-.5;
    vec2 sfp = smoothstep(.475,.5,abs(fp));
    
    st *= vec2(.5,1.);
    vec2 q = floor(st*4.-.25);
    float hq = Hsh2(q*0.890976); hq *= step(.35,abs(hq-.5));
    vec2 fq = fract(st*4.-.25)-.5;
    vec2 sfq = smoothstep(.45,.5,abs(fq));
	
    st *= vec2(5.,.1);
    vec2 r = floor(st*8.-.25);
    float hr = Hsh2(r*0.123456); hr *= step(.47,abs(hr-.5));
    vec2 fr = fract(st*8.-.25)-.5;
    vec2 sfr = smoothstep(.4,.5,abs(fr));
    
    float h = max(max(hp,hq),hr);
    if(bool(h)){
        vec2 plate =    step(h,hp)*sfp*sign(fp)
                      + step(h,hq)*sfq*sign(fq) 
                      + step(h,hr)*sfr*sign(fr);
        
        coef += .2*h+.8;
        coef += .5*min(1.,plate.x+plate.y);
    }
    else coef = 1.;
    
    return coef;
}


float lightPath(in vec2 uv){    
    return step(.965,Hsh(floor(uv.x*10.)))+step(.965,Hsh(floor(uv.y*10.)));
}

vec3 groundLight(in vec3 pos, in vec3 ray, in float t){
    vec3 col = vec3(0.);
   	float ty = (.00001-pos.y)/ray.y;
    ty += step(ty,0.)*INFINI;
    pos += ty*ray;
    if(ty<t) col += (.05/length(pos.xz*20. - vec2(floor(pos.xz*20.)+.5))-.08)
        			* lightPath(pos.xz);
    return col;
}


float flare(in vec3 s, in vec3 ctr){
    float c = 0.;
	s = normalize(s);
    float sc = dot(s,-moonRefl);
    c += .5*smoothstep(.99,1.,sc);
    
    s = normalize(s+.9*ctr);
    sc = dot(s,-moonRefl);
    c += .3*smoothstep(.9,.91,sc);
    
    s = normalize(s-.6*ctr);
    sc = dot(s,-moonRefl);
    c += smoothstep(.99,1.,sc);
    
    return c;
}


vec3 lensflare3D(in vec3 ray, in vec3 ctr)
{
    vec3 red = vec3(1.,.6,.3);
    vec3 green = vec3(.3,1.,.6);
    vec3 blue = vec3(.6,.3,1.);
	vec3 col = vec3(0.);
    vec3 ref = reflect(ray,ctr);

    col += red*flare(ref,ctr);
    col += green*flare(ref-.15*ctr,ctr);
    col += blue*flare(ref-.3*ctr,ctr);
    
    ref = reflect(ctr,ray);
    col += red*flare(ref,ctr);
    col += green*flare(ref+.15*ctr,ctr);
    col += blue*flare(ref+.3*ctr,ctr);
    
    float d = dot(ctr,moonRefl);
	return .4*col*max(0.,d*d*d*d*d);
}



vec3 getCamPos(in vec3 camTarget){
    float 	rau = 15.,
            alpha = iMouse.x/iResolution.x*4.*PI,
            theta = iMouse.y/iResolution.y*PI+(PI/2.0001);	
    		
            // to start shader
    		if (iMouse.xy == vec2(0.)){
                float ts = smoothstep(18.,22.,iTime)*(iTime-20.);
                float tc = smin( iTime, 30., 3. );
                alpha = -2.-ts*.05;
                theta = 1.5-tc*.05;
            }
    return rau*vec3(-cos(theta)*sin(alpha),sin(theta),cos(theta)*cos(alpha))+camTarget;
}

vec3 getRay(in vec2 st, in vec3 pos, in vec3 camTarget){
    float 	focal = 1.;
    vec3 ww = normalize( camTarget - pos);
    vec3 uu = normalize( cross(ww,vec3(0.0,1.0,0.0)) ) ;
    vec3 vv = cross(uu,ww);
	// create view ray
	return normalize( st.x*uu + st.y*vv + focal*ww );
}

void mainImage( out vec4 fragColor, in vec2 fragCoord ){
    vec2 st = ( fragCoord.xy
               // here below, shifting a little even coordinates (H and V).
               // Do not really manage aliasing, but reduce strongly flickering due to aliasing
               // Far from a good job, but it is absolutly costless!!
               // comment the line below to compare
               -.5*vec2(mod(fragCoord.y,2.),mod(fragCoord.x,2.))
               - .5*iResolution.xy ) / iResolution.y; 
    float ti = iTime*.02;
    
    // camera def
    vec3 camTarget = vec3(-50.*sin(2.*ti),2.1,-30.*cos(3.*ti));
    //vec3 camTarget = vec3(0.);
       
    vec3 pos = getCamPos(camTarget);
    pos.y = max(pos.y,map(pos.xz)+.1);
    
    vec3 ray = getRay(st, pos,camTarget);
	
    bool moonside = bool(step(0.,dot(ray,moonRefl)));
	
    vec3 color = vec3(.0);
    float t = 0.;
    vec3 norm = vec3(0.);

    vec4 info = trace(pos, ray);
    float sc = hitScale;
    t = info.w;
    norm = info.xyz;
    
    float shadow = shadow(pos+t*ray);
    
    if(t==INFINI){
        if(moonside){
            color += moonGlow(ray);
            color += fewStars(ray);
        }
        else color += stars(ray);
    }
    else{
        if(!bool(norm.y)) {
            info = traceWindow(pos ,ray, t, norm);
            if(bool(info.w)) {
                norm = info.xyz;
                t = info.w;
            }
        }
        
        vec3 p = pos + t*ray;

        if(hitObj == WIN){
            vec3 window = winGlow( ((p.xy+p.z)*norm.z + (p.zy+p.x)*norm.x))*(1.-norm.y);
            vec3 refl = reflect(ray,norm);
            color += smoothstep(.95,1.,dot(moonRefl,refl))*norm.z*step(1.,shadow);
            color += window*min(1., 30./t);
        }
        
        else{
            vec2 side = .1*p.xz*norm.y + .5*p.xy*norm.z + .5*p.zy*norm.x;
            color += texture(iChannel0,side).rgb;
            color *= metalPlate(4.*side);
            color += .015*vec3(.5*sc,abs(sc-4.),8.-sc) * min(1.,10./t);

            color *= clamp(dot(norm, moonRefl)+.2,.3,1.);
            if(hitObj == SIDE) color += vec3(.1,.05,.0);
            else color *= shadow;
            
            vec3 refl = reflect(ray,norm);
            color += .3*smoothstep(.9,1.,dot(moonRefl,refl))*norm.z*step(1.,shadow);;

            color += texture(iChannel2,p.xz*.1).rgb*groundLight(pos, ray, t);
            color -= 2.*texture(iChannel2,p.xz*.2).rgb*(norm.x+norm.z)*lightPath(p.xz)*step(.001,p.y)*step(p.y,.08);
        	color = clamp(color,0.,1.);
        }
        color *= min(1., 80./t);
    }
     if(moonside)
    	if(!shadTrace(pos,moonRefl))
    		color += lensflare3D(ray, getRay(vec2(0.), pos,camTarget));
    
	fragColor = vec4(color,1.);
}
    
    
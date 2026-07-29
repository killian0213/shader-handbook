// Image (image) — Trip in Tron 3 by ocb
// https://www.shadertoy.com/view/XsXBDX

// Author: ocb
// Title: Trip in Tron 3

// tron cover for Boreal Spring shader
// https://www.shadertoy.com/view/ldXBRH


// thanks to Dave Hoskins for his function (here named electric())
// https://www.shadertoy.com/view/MdlXz8
// function used to render fairyligths surface and path lag 


#define PI 3.141592653589793
#define PIdiv2 1.57079632679489
#define TwoPI 6.283185307179586
#define INFINI 1000000000.

#define maxTreeH 130.
#define maxHill 300.
#define cellH 430. 	/*treeH + maxHill*/
#define cellD 100.
#define maxCell 150
#define TREE_DENSITY (abs(fract(cell.x/10.)-.5)*abs(fract(cell.y/10.)-.5))*10.

// object name
#define GND -1
#define SKY -1000

#define REDL 1
#define MAGL 2
#define BLUL 3
#define YELL 4

#define COTTA 10
#define WALL 11
#define ROOF 12

#define TREE 20

#define SNOWMAN 40
#define BELLY 41
#define HEAD 42
#define HAT 43
#define NOZ 44

// ground parameters
#define SHIFT 0.
#define AMP 1.
#define P1 .003
#define P2 .0039999  /* P1*1.3333 */
#define P3 .0059661  /* P1*1.9887 */

#define DP2 .0039999 /*.00199995  /* AMP * P2 */
#define DP3 .0059661 /*.00298305  /* AMP * P3 */

#define NRM 4.   /* (1. + AMP + SHIFT) * 2. */

//*******************************************************************************
//Global var

int hitObj = SKY;
float T = INFINI;

// object global
// Ambiance light direction
vec3 lightRay;
// lights
vec3 redO, magO, bluO, yelO;
float redR, magR, bluR, yelR;
// cotta
vec3 wallO, roofO;
float wallR, roofR, roofH;
vec2 cottaCell;

// snowpeople
vec3 belO, hedO, hatO, nozO;
float belR, hedR, hatH, hatR, nozH, nozR;
vec2 snowmanCell;

//tree
vec3 treeO;
float treeR, treeH;

//*******************************************************************************
float rand1 (in float v) { 						
    return fract(sin(v) * 437585.);
}
float rand2 (in vec2 st,in float time) { 						
    return fract(sin(dot(st.xy,vec2(12.9898,8.233))) * 43758.5453123+time);
}

float pattern(in vec2 st, in float index){
    if (index > 0.5) return st.x;
    else return st.y;
}
//*******************************************************************************
// Ground fonction for ray marching *********************************************
float ground(in vec2 p){
    float len = max(1.,0.0001*length(p));
    float hx = max(0., (sin(P1*(p.x+p.y)) + AMP*sin(P2*p.x+PIdiv2) + SHIFT) );
    float hy = max(0., (sin(P1*(p.y+.5*p.x)) + AMP*sin(P3*p.y+PIdiv2) + SHIFT));
    return maxHill*(hx+hy)/NRM/len;
}

// derivation of the above function
vec3 getGndNormal(in vec2 p, in float h) {
    if(h<.001) return vec3(0.,1.,0.);
    else{
        float len = max(1.,0.0005*length(p));
        float dx = maxHill*( P1*cos(P1*(p.x+p.y)) + DP2*cos(P2*p.x+PIdiv2) )/NRM;
        float dy = maxHill*( P1*cos(P1*(p.y+.5*p.x)) + DP3*cos(P3*p.y+PIdiv2) )/NRM;
        return normalize(cross( vec3(1.,dx/len,0.), vec3(0.,dy/len,1.) ));		// divided by len: We may call that "normal fog"
    }
}

// Ray marching (only for ground)
float gndRayTrace(in vec3 p, in vec3 ray){
    float t = 0.;
    float contact = .1;
    float dh = p.y - ground(p.xz);
    if(dh<contact) return .0001;
    for(int i=0; i<100;i++){
        t += dh;			// t = dh/length(ray) but ray normalized
        p += dh*ray;
        if(p.y >= cellH && ray.y>=0.){
            t = INFINI;
            break;
        }
        dh = p.y - ground(p.xz);
        if(abs(dh)<contact)break;
    }
    return t;
}

//*************************************************************************************
// Primitives solution for raytracing *************************************************
float sfcImpact(in vec3 p, in vec3 ray, in float h){
    float t = (h-p.y)/ray.y;
    if (t <= 0.001) t = INFINI;
    return t;
}

float sphereImpact(in vec3 pos, in vec3 sphO, in float sphR, in vec3 ray){
    float t = INFINI;
    vec3 d = sphO - pos;
    float b = dot(d, ray);
    
    if (b >= 0.){	// check if object in frontside first (not behind screen)
        float c = dot(d,d) - sphR*sphR;
    	float disc = b*b - c;
    	if (disc >= 0.){
        	float sqdisc = sqrt(disc);
            float t1= b + sqdisc;
            float t2= b - sqdisc;
        	t = min(t1,t2) ;
        	if (t <= 0.001){
                t = max(t1,t2);
                if (t <= 0.001) t = INFINI;
            } 
        }
    }
    return t;
}

float coneImpact(in vec3 pos, in vec3 coneO, in float coneH, in float coneR, in vec3 ray){
    float t = INFINI, dmin=0.;
    vec3 d = coneO - pos;
    float Dy = coneH + d.y;
    float r2 = coneR*coneR/(coneH*coneH);
    float b = dot(d.xz, ray.xz);
    
    float a = dot(ray.xz,ray.xz);
    float c = dot(d.xz,d.xz) - r2*Dy*Dy;
    float c1 = -b + r2*Dy*ray.y;
    float disc = c1*c1 - (a - r2*ray.y*ray.y) * c;
    if (disc >= 0.){
        float sqdis = sqrt(disc);
        float t1 = (-c1 + sqdis)/(a - r2*ray.y*ray.y);
        float t2 = (-c1 - sqdis)/(a - r2*ray.y*ray.y);

        float ofc = -ray.y*t1 + Dy;
        t1 *= step(0.,ofc)*(1.-step(coneH,ofc));
        if (t1 <= 0.001) t1 = INFINI;

        ofc = -ray.y*t2 + Dy;
        t2 *= step(0.,ofc)*(1.-step(coneH,ofc));
        if (t2 <= 0.001) t2 = INFINI;

        t = min(t1,t2);
    }

	return t;
}

vec2 cylinderImpact(in vec2 pos, in vec2 cylO, in float cylR, in vec2 ray){
    float t1 = INFINI, t2 = INFINI;
    vec2 delta = pos - cylO;

    float a = dot(ray,ray);
    float b = dot(delta, ray);
    float c = dot(delta,delta) - cylR*cylR;
    float d = b*b - a*c;
    
    if (d >= 0.){
        float Vd = sqrt(d);
        t1 = (-b - Vd)/a;
        t2 = (-b + Vd)/a;
        if(t1<0.001) t1 = INFINI;
        if(t2<0.001) t2 = INFINI;
    }
    
	return vec2(t1,t2);
}

//*******************************************************************************************
// Color and render functions ***************************************************************
vec3 skyGlow(in vec3 ray){
    if(ray.y>=0.)return vec3(.5*max(ray.x+.7,0.)*(.8-max(0.,ray.y)), .35,.4)*(1.-ray.y)*(ray.x+1.5)*.4;
    else return vec3(0.);
}

vec3 snowColor(in vec3 pos){
    vec3 col = vec3(.7,.7,.75)+vec3(.05,.05,.05)*rand2(floor(pos.xz*10.), 0.);
    col += vec3(1.,.7,.8)*step(.997,rand2 (floor(pos.xz*20.), 0.));
    return col;
}

vec3 lightColor(in vec3 pos){
    vec3 color = vec3(0.);
    color.r += min(1.,3./length(pos-redO));
    color.rb += min(1.,3./length(pos-magO));
    color.b += min(1.,6./length(pos-bluO));
    color.rg += min(1.,2./length(pos-yelO));
    return color;
}

vec3 window(in float angl, in vec3 pos){
    float dh = pos.y-wallO.y-.25*wallR;
    float an = fract(3.*angl/PI)-.5;
    return vec3(0.522,0.581,1.000)*(smoothstep(-.9,-.8,-abs(abs(dh)-1.))*( smoothstep(-.04,-.03,-abs(abs(an)-.04)))+.2*(1.-smoothstep(.0,.4,abs(an))));
    
}

vec3 winLitcolor(vec3 pos){
    float r = length(pos.xz-wallO.xz)*.01;
    if (r<2.5){
    	float a= fract(3.*atan(pos.z- wallO.z,pos.x - wallO.x)/PI)-.5;
    	return vec3(0.087,0.626,1.000)*.3*smoothstep(-2.,-.0,-r)*smoothstep(.1,.8,r)*smoothstep(-.5,-.0,-abs(a))*smoothstep(-60.,.0,-pos.y+wallO.y);
    }
    else return vec3(0.);
}

vec3 stars(in float a,in vec3 ray){
    vec2 star = vec2(a,ray.y*.7)*30.;
    vec2 p = floor(star);
    if(rand2(p,0.)>.97){
        vec2 f = fract(star)-.5;
    	return  vec3(.7*smoothstep(0.,.3,abs(fract(iTime*.3+3.*a)-.5))*ray.y * (smoothstep(-.01,-.0,-abs(f.x*f.y))+max(0.,.1/length(f)-.2)));
    }
	else return vec3(0.);
}

vec3 boreal(in float a,in vec3 ray){
    vec3 col = vec3(0.);
    float b = .03*(asin(clamp(6.*a+12.,-1.,1.))+PIdiv2);
    float c = .2*(asin(clamp(-.2*a*abs(a)-1.67222,-1.,1.))+2.042);
    float d = .05*(a+1.)*(asin(clamp(a-1.,-1.,1.))+PIdiv2);
    float rebord = smoothstep(1.83333,1.9,-a);
    float rebord2 = smoothstep(-2.,-1.9,-a);
    float var1 = (sin(1./(a+2.2)+a*30. + iTime)+1.)/2.+.5;
    float var2 = (sin(a*10. - iTime)+1.)/2.+.5;
    float var3 = (sin(1./(a+.04)+a*10. + iTime)+1.)/2.+.5;
    col += 2.5*vec3(0.292,ray.y,0.1)*var1*smoothstep(b,b+.5*ray.y,ray.y)*smoothstep(-b-.9*ray.y,-b,-ray.y)*rebord;
    col += 1.*vec3(.6-ray.y,.5*ray.y,0.15)*var2*smoothstep(c,c+.07,ray.y)*smoothstep(-c-.5,-c,-ray.y)*rebord;
    col += 2.5*vec3(0.292,ray.y,0.1)*var3*smoothstep(d,d+.5*ray.y,ray.y)*smoothstep(-d-.9*ray.y,-d,-ray.y)*rebord2;
    col *= .5+.5*smoothstep(-1.,0.,-fract(ray.y+iTime*.1*rand1(floor(a*300.))))*smoothstep(-.7,0.,-abs(fract(a*300.)-.5));
	return col;
}

vec3 skyColor(in vec3 ray){
    float a = atan(ray.z,ray.x);
    vec3 color = skyGlow(ray);
    color += stars(a,ray);
    color += boreal(a, ray);
    return color;
}

vec3 groundColor(in vec3 pos, in vec3 ray, in vec3 norm){
    float len = length(pos.xz);
    float dir = max(0.,dot(-lightRay,norm));
    vec3 color = snowColor(pos)*(.8*dir+.2);
    color *= .5+.5*pos.y/maxHill;
    ray = reflect(ray, norm);
    ray.y = max(0.,ray.y);
    color = mix(.9*skyGlow(ray),color,.7);
    color *= 1.-atan(len/10000.)/PIdiv2;
    color += vec3(.4*max(ray.x+.7,0.), .35,.4)*(ray.x+1.5)*.4*atan(len/20000.)/PIdiv2;
    color += .8*lightColor(pos);
    color += winLitcolor(pos);
	return color;
}

//**********************************************************************************
// cotta functions *****************************************************************
vec3 roofColor(in vec3 p, in vec3 ray, in vec3 norm){
    float an = atan((p.z - roofO.z),(p.x - roofO.x));
    float lim = 6.*(.2*sin(6.*an)+1.1);
    vec3 tile = (smoothstep(.0,.9, abs(fract(p.y)-.5))+smoothstep(0.,.7,abs(fract(20.*an+step(1., mod(p.y,2.0)) * 0.5)-.5)))*vec3(0.085,0.548,0.975);
    vec3 color = step(-p.y+roofO.y,-lim)*tile + step(p.y-roofO.y,lim)*snowColor(p*5.);
    color *= ((dot(lightRay,norm)+1.)*.2 + .2);
    color += 1.5*vec3(0.029,0.560,0.975)*smoothstep(.5,1.,1.-dot(ray.xz,(roofO.xz-p.xz)/roofR));
    color += vec3(0.029,0.560,0.975)*.7*smoothstep(-lim-4.,-lim,roofO.y-p.y)*step(-p.y+roofO.y,-lim);
    color += vec3(0.102,0.147,0.975)*smoothstep(-3.,0.,-abs(roofO.y-p.y));
    color += vec3(0.049,0.956,0.975)*.5*smoothstep(-1.,0.,-abs(roofO.y-p.y));
    color += .8*lightColor(p);
    return color;
}

vec3 wallColor(in vec3 p, in vec3 ray, in vec3 norm){
    float angl = atan((p.z - wallO.z),(p.x - wallO.x));
    float lim = 1.3*(sin(2.*angl)+1.5);
    vec3 tile = 2.*(smoothstep(0.,.6,abs(fract(p.y*2.)-.5))+(1.-smoothstep(0.,.1,abs(fract(2.*angl+iTime*rand1(floor(p.y*2.)))-.5))))*vec3(0.037,0.518,0.975);
    vec3 color = step(p.y,lim)*snowColor(p*5.)*vec3(0.048,0.691,0.990) + step(-p.y,-lim)*tile;
    ray = reflect(ray, norm);
    if(ray.y >0.) color = mix(color,skyGlow(ray),.3);
    else color = mix(color,skyGlow(ray*vec3(1.,-1.,1.)),.3);
    color *= ((dot(lightRay,norm)+1.)*.2 + .2);
    color += window(angl, p);
    color.b += .5*smoothstep(-lim,0.,-p.y);
    color += .8*lightColor(p);
    return color;
}

bool cottaImpact(in vec3 p, in vec3 ray, inout vec3 color){
    bool impact = false;
    float tr = coneImpact(p, roofO, roofH, roofR, ray);
    float tw = sphereImpact(p, wallO, wallR, ray);
    float t = min(tr,tw);
    if(t<T){
        T=t;
        p += t*ray;
        impact = true;
        if(t == tr){
            hitObj = ROOF; 
            vec3 norm = normalize(vec3(p.x - roofO.x,roofR*roofR/(roofH*roofH)*(roofH + roofO.y - p.y),p.z-roofO.z));
            color += .7*roofColor(p, ray, norm);
        }
        else{
            hitObj = WALL;
            vec3 norm = normalize(p-wallO);
            color += wallColor(p, ray, norm);
        }
    }
    return impact;
}

//******************************************************************************************
// Snowman functions ***********************************************************************
float drawPattern(in vec3 p, in vec3 obj){
    float a = 4.*atan(p.z-obj.z,p.x-obj.x);
    vec2 i = floor(vec2(a,p.y));  
    vec2 f = fract(vec2(a,p.y));  
	float tile = pattern(f, rand2(i, iTime*.04));
    return 1.5*(smoothstep(-.1,.0,-abs(tile-.05)));
}

vec3 bellyColor(in vec3 p, in vec3 ray, in vec3 norm, in vec3 belly){
    vec3 color = snowColor(norm*30.);
    ray = reflect(ray, norm);
    if(ray.y >0.) color = mix(color,skyGlow(ray),.3);
    else color = mix(color,skyGlow(ray*vec3(1.,-1.,1.)),.3);
    color *= ((dot(lightRay,norm)+1.)*.2 + .2);
    color *= (1.-step(-.5,-abs(p.z-belly.z))*step(0.,p.x-belly.x)* step(.9, fract((p.y-belly.y)*.4)));
    color += vec3(0.995,0.234,0.177)*drawPattern(p, belO);
    color += lightColor(p);
    color += vec3(0.990,0.395,0.006)*1.5*smoothstep(-3.,0.,-abs(belO.y-1.-p.y));
    return color;
}

vec3 headColor(in vec3 p, in vec3 ray, in vec3 norm, in vec3 head){
    vec3 color = snowColor(norm*30.);
    color -= (1.-step(.3,length(head.yz+vec2(1.5,1.5)-p.yz)))*step(hedO.x,p.x);
    color -= (1.-step(.3,length(head.yz+vec2(1.5,-1.5)-p.yz)))*step(hedO.x,p.x);
    ray = reflect(ray, norm);
    if(ray.y >0.) color = mix(color,skyGlow(ray),.3);
    else color = mix(color,skyGlow(ray*vec3(1.,-1.,1.)),.3);
    color *= ((dot(lightRay,norm)+1.)*.2 + .2);
    color += vec3(0.995,0.234,0.177)*drawPattern(p, hedO)*step(-hedO.y+.4*exp(p.x-hedO.x-2.),-p.y);
    color += lightColor(p);
    return color;
}

vec3 hatColor(in vec3 p, in vec3 ray, in vec3 norm){
    vec3 color = snowColor(p*5.);
    color *= ((dot(lightRay,norm)+1.)*.2 + .2);
    color += smoothstep(-.3,.0,-abs(fract(p.y*.4)-.5))*vec3(0.995,0.336,0.308);
    color += lightColor(p);
    return color;
}

vec3 nozColor(in vec3 p, in vec3 ray, in vec3 norm){
    vec3 color = vec3(0.475,0.250,0.002);
    color *= ((dot(vec3(0.,1.,0.),norm)+1.)*.4 + .2);
    color += lightColor(p);
    return color;
}

vec3 flowpatern(in float a, in float y){
    vec3 color = vec3(0.);
    float i = floor(a/PI*10.);
    float f = fract(a/PI*10.);
    float s = rand1(i*1.22543)+.2;
    float proba = rand1(i*1.3377+floor(3.*iTime*s+y/30.));
    float pattern = smoothstep(-.2,-.1,-abs(f-.5))*rand1(floor((iTime+y)));
    if(bool(step(.95,proba))) color += vec3(0.990,0.729,0.430)*.9*pattern;
    else if(bool(step(.8,proba))) color += vec3(0.139,0.990,0.990)*0.3*pattern;
    return color;
}

bool caracterImpact(in vec3 pos, in vec3 ray,inout vec3 color){
    bool impact = false;
    vec3 p = pos;
    float tbel = sphereImpact(p, belO, belR, ray);
    float thed = sphereImpact(p, hedO, hedR, ray);
    float that = coneImpact(p, hatO, hatH, hatR, ray);
    float tnoz = coneImpact(vec3(-p.y,p.x,p.z), vec3(-nozO.y,nozO.x,nozO.z), nozH, nozR, vec3(-ray.y,ray.x,ray.z));
    float t = min(min(min(tbel,thed),that),tnoz);
    if(t<T){
        T=t;
        p += t*ray;
        impact = true;
        hitObj = SNOWMAN;
        if(t == tbel){
            vec3 norm = normalize(p - belO);
            color += bellyColor(p, ray, norm, belO);
        }
        else if(t == thed){
            vec3 norm = normalize(p - hedO);
            color += headColor(p, ray, norm, hedO);
        }
        else if(t == that){
            vec3 norm;
            norm.xz = p.xz - hatO.xz;
            norm.y = 0.;
            norm = normalize(norm);
            color += hatColor(p, ray, norm);
        }
        else{
            vec3 norm;
            norm.yz = p.yz - nozO.yz;
            norm.x = 0.;
            norm = normalize(norm);
            color += nozColor(p, ray, norm);
        }
    }

    return impact;
}

//**************************************************************************************
// Tree functions **********************************************************************

vec3 treeColor(in vec3 p, in vec3 ray, in vec3 norm){
    float lim = 40.*(.05*sin(.6*p.x)+.5);
    vec3 color = step(-p.y+treeO.y,-lim)*snowColor(fract(p*5.)) + step(p.y-treeO.y,lim)*vec3(0.019,0.966,0.975);
    color *= ((dot(lightRay,norm)+1.)*.2 + .1);
    color += .8*lightColor(p);
    
    float border = 1.-dot(ray.xz,(treeO.xz-p.xz)/treeR);
	color.b += smoothstep(.5,1.,border);
    color += .3*smoothstep(.7,1.,border);
    color += .3*smoothstep(-lim-4.,-lim,treeO.y-p.y)*step(-p.y+treeO.y,-lim);
    color += vec3(0.019,0.966,0.975)*.7*smoothstep(-20.,0.,-abs(treeO.y-p.y));
	color *= 1.-atan(length(p)/10000.)/PI*2.;
    return color;
}

bool getTree(in vec2 cell,inout vec3 treeO, inout float treeH, inout float treeR){
    bool treeOk = bool(step(TREE_DENSITY,rand2(cell*1.331,1.))) && cell != cottaCell;			// check if object depending cell coords
        if (treeOk){ 
            treeH = (.7*rand2(cell*3.86,0.)+.3)*maxTreeH;
            treeR = .15*treeH;
            float lim = (1.-2.*treeR/cellD);
            treeO = vec3(lim*(rand2(cell*2.23,0.) - 0.5) + cell.x, 0., lim*(rand2(cell*1.41,0.) -0.5)  + cell.y) *cellD;
            treeO.y += ground(treeO.xz)-11.;
        }
    return treeOk;
}

bool treeImpact(in vec2 cell, in vec3 p, in vec3 ray, inout vec3 color){
    bool impact = false;
    bool tree = getTree(cell,treeO, treeH, treeR);
    if(tree){
        float t = coneImpact(p, treeO, treeH, treeR, ray);
        if(t<T){
            T=t;
            hitObj = TREE;
            impact = true;
            p += t*ray;
            vec3 norm = normalize(vec3(p.x - treeO.x,treeR*treeR/(treeH*treeH)*(treeH + treeO.y - p.y),p.z-treeO.z));
            color += .5*treeColor(p, ray, norm);
        }
    }
    return impact;
}

//***************************************************************************************************
// fairy light functions ****************************************************************************
vec3 fairyReflect(in vec3 ray,in vec3 norm){
    vec3 r = reflect(ray,norm);
    r.y = abs(r.y);
    return skyGlow(r);
}

// thanks to Dave Hoskins...
// https://www.shadertoy.com/view/MdlXz8
// function used to render fairyligths surface and path
float electric(in vec2 p){
	p = mod(p*TwoPI, TwoPI)-250.0;
	vec2 i = p;
	float c = 1.0;
	float inten = .005;

	for (int n = 0; n < 5; n++) 
	{
		float t = 2.*iTime * (1.0 - (3.5 / float(n+1)));
		i = p + vec2(cos(t - i.x) + sin(t + i.y), sin(t - i.y) + cos(t + i.x));
		c += 1./length(vec2(p.x / (sin(i.x+t)/inten),p.y / (cos(i.y+t)/inten)));
	}
	c /= 5.;
	c = 1.12-pow(c, 1.2);
	return pow(abs(c), 8.0);
}
//...


// set color and render of lights
vec3 fairyLight(in vec3 ray,in vec3 pos,in int hitObj){
    float cs;
    vec3 norm;
    vec3 refl;
    vec3 col=vec3(0.);
    if (hitObj == REDL){
        vec3 v = pos - redO;
    	float a = atan(v.x,v.z);
        col.r += electric(vec2(a/PI+.5, v.y/redR+.5));
        norm = normalize(redO-pos);
        col += .5*fairyReflect(ray,norm);
		cs = dot(ray,norm);
        col.r += .2*smoothstep(-1.,0.,-cs);
    }
    else if (hitObj == MAGL){
        vec3 v = pos - magO;
    	float a = atan(v.x,v.z);
        col.rb += electric(vec2(a/PI+.5, v.y/magR+.5));
        norm = normalize(magO-pos);
        col += .5*fairyReflect(ray,norm);
        cs = dot(ray,norm);
        col.rb += .2*smoothstep(-1.,0.,-cs);
    }
    else if (hitObj == BLUL){
        vec3 v = pos - bluO;
    	float a = atan(v.x,v.z);
        col += vec3(0.,.3,1.)*electric(vec2(a/PI+.5, v.y/bluR+.5));
        norm = normalize(bluO-pos);
        col += .5*fairyReflect(ray,norm);
        cs = dot(ray,norm);
        col += vec3(0.,.3,1.)*.3*smoothstep(-1.,0.,-cs);
    }
	else if (hitObj == YELL){
        col.rg += .15;
        norm = normalize(yelO-pos);
        cs = dot(ray,norm);
        col.rg += .3*smoothstep(-1.,0.,-cs);
    }
    return col;
}

// specific raytracing for the lights with transparency parameter
// if trans = obj then this obj is ignored (transparent)
float lightTrace(in vec3 pos, in vec3 ray,inout int hitLit, in int trans){
    float t = INFINI, tp; 	
    
    if(trans != REDL){
    		tp = sphereImpact(pos, redO, redR, ray);
    		if(tp<t){
            	t = tp;
            	hitLit = REDL;
    		}
        }
    if(trans != MAGL){
    		tp = sphereImpact(pos, magO, magR, ray);
    		if(tp<t){
            	t = tp;
            	hitLit = MAGL;
    		}
        }
    if(trans != BLUL){
    		tp = sphereImpact(pos, bluO, bluR, ray);
    		if(tp<t){
            	t = tp;
            	hitLit = BLUL;
    		}
        }
    if(trans != YELL){
    		tp = sphereImpact(pos, yelO, yelR, ray);
    		if(tp<t){
            	t = tp;
            	hitLit = YELL;
    		}
        }

    return t;
}

//**************************************************************************************
// Space is divided by a grid. Each element (or cell) of the grid may content one object
// (for ex: tree) or nothing. Raytracing occur only in local cell if an object is present.
// Allow lots of objects with only few raytraced object.
// see demo: https://www.shadertoy.com/view/XdffRN

// Key function to find the next cell of the grid
vec2 getNextCell(in vec2 p, in vec2 v, in vec2 cell){
    vec2 d = sign(v);
	vec2 dt = ((cell+d*.5)*cellD-p)/v;
    d *= vec2( step(dt.x-0.02,dt.y) , step(dt.y-0.02,dt.x) );		// -0.020 to avoid cell change for epsilon inside
    return cell+d;
}

// call the involved ratrace funtion, depending of kind of object present in cell of the grid
bool checkCell(in vec2 cell, in vec3 p, in vec3 ray, inout vec3 color){
    bool impact = false;
    if(cell == cottaCell) impact = cottaImpact(p, ray, color);   
    else if(cell == snowmanCell) impact = caracterImpact(p, ray, color);
    else impact = treeImpact(cell, p, ray, color);
    return impact;
}

//**************************************************************************************
// Fairy lights and camera trajectory management

// to circle around an object
vec3 circle(in float ti, in vec3 obj){
    return vec3(80.*cos(ti*TwoPI) + obj.x, 0., 80.*sin(ti*TwoPI) + obj.z);
}

// kind of free flight
vec3 freetrack(in float time){
    return vec3(3000.*cos(time*.02), 0., 3200.*sin(time*.07));
}

// to smoothly change the trajectory to circle fligth to free flight (or reverse)
vec3 transfer(in vec3 tr1, in vec3 tr2, in float dti, in float period){
    float ang = dti*period*PI;
    return tr1*(1.+cos(ang))/2. + tr2*(1.+cos(ang+PI))/2.;
}

// track of the lights
// sometime circle around object, sometime free flight
vec3 getTrac(in float time){
    float ti = 27.*fract(time*.01);
    vec3 track;
    
    if(ti<1.) track = circle(ti,wallO);
    else if(ti<9.) track = transfer(circle(ti,wallO), freetrack(time), ti-1., .125); 	// .125 = 1/(9-1)
    else if(ti<14.) track = freetrack(time);
    else if(ti<22.) track = transfer(freetrack(time), circle(ti,hedO), ti-14.,.125);	// .125 = 1/(22-14)
    else if(ti<23.) track = circle(ti,hedO);
    else track = transfer(circle(ti,hedO), circle(ti,wallO), ti-23.,.25);
       
    return track;
}

// track of the camera
// not the same as fairylight to avoid to get sick when ligth are turning around objects
// when lights circling, cam is fixed on the object
vec3 getCam(in float time, in vec3 track){
    float ti = 27.*fract(time*.01);
    vec3 cam;
    
    if(ti<1.) cam = wallO;
    else if(ti<5.) cam = transfer(wallO, track, ti-1., .25);	// .25 = 1/(5-1)
    else if(ti<18.) cam = track;
    else if(ti<22.) cam = transfer(track, hedO, ti-18., .25);
    else if(ti<23.) cam = hedO;
    else cam = transfer(hedO, wallO, ti-23., .25);	// .25 = 1/(27-23)
    
    return cam;
}

// local flight of fairylight aroud the main track
vec3 flyR(in float time){return vec3(20.*sin(time*2.),5.*sin(time*3.),10.*cos(time*2.));}
vec3 flyM(in float time){return vec3(10.*sin(1.+time*2.),4.*sin(1.6+time*3.),15.*cos(1.+time*2.));}
vec3 flyB(in float time){return vec3(10.*sin(5.+time*3.),2.*sin(3.+time*2.),10.*cos(5.+time*3.));}
vec3 flyY(in float time){return vec3(30.*sin(time*3.),abs(15.*sin(time*4.)+4.),20.*cos(time*3.));}

// BACK IN TIME...
// to generate the glowing path behind the fairiylights
// without using buffer
float glowTrack(in vec2 obj, in vec2 pos, in int lit){
    float d = length(obj.xy-pos.xy);	//current distance from obj at time now
    									// at the speed of the obj, this distance represent a certain amount of time
    									// objective: come back in time to check if position was on the obj path.
    
    // first : finding obj speed by derivation dp/dt
    float past = iTime-.2; //dt
    // what was the obj position a little time ago (dp)
    vec2 delta = (getTrac(past)).xz;
    if(lit == REDL) delta += flyR(past).xz;
    else if(lit == MAGL) delta += flyM(past).xz;
    else if(lit == BLUL) delta += flyB(past).xz;
    
    // obj speed : dp/dt (here dt = .2)
    float v = length(obj.xy-delta.xy)/.2;
    
    // finding "time" to the object at obj speed
    float backInTime = d/v;
    float oldTime = iTime-backInTime;
    
    // finding obj. pos at this old time
    vec2 oldTrac = (getTrac(oldTime)).xz;
    if(lit == REDL) oldTrac += flyR(oldTime).xz;
    else if(lit == MAGL) oldTrac += flyM(oldTime).xz;
    else if(lit == BLUL) oldTrac += flyB(oldTime).xz;
    
    // finding distance from obj when at this old time
    float l = length(oldTrac.xy-pos.xy);
    // if pos was close to obj, then pos is on the track
    // intensity of the color depends how long before it was... 
    float glow = 1.-step(10.,l);
    if(bool(glow)) return (1.-smoothstep(2.,10.,l))*(1.-smoothstep(0.,2.,backInTime))*electric(pos.xy*.02);
    else return 0.;
}

    
void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
	vec2 st = fragCoord.xy/iResolution.xy-.5;
    st.x *= iResolution.x/iResolution.y;
        
    // object def
    
    //cotta
    wallO = vec3(400.,4.,-600.);
    wallO.y += ground(wallO.xz);
    wallR = 20.;
    roofO = wallO+vec3(0.,8.,0.);
    roofH = 42.;
    roofR = 22.;
    cottaCell = vec2(4.,-6.);   //floor(wallO.xz/cellD + .5);
    
    //SnowMan
    belO = vec3(200.,4.,100.);
    belR = 10.;
    belO.y = ground(belO.xz);
    hedO = belO+vec3(0.,13.,0.);
    hedR = 5.;
    hatO = belO+vec3(0.,16.,0.);
    hatH = 15.;
    hatR = 3.8;
    nozO = belO+vec3(4.,13.,0.);
    nozH = 4.;
    nozR = .8;
    snowmanCell = vec2(2.,1.);		//floor(belO.xz/cellD + .5);
    
    //light
    vec3 trac = getTrac(iTime);
    trac.y += ground(trac.xz)+15.;
    vec3 tracb = getTrac(iTime-.5);
    tracb.y += ground(tracb.xz)+1.;
    redO = trac + flyR(iTime);
    redR = 3.;
    magO = trac + flyM(iTime);
    magR = 3.;
    bluO = trac + flyB(iTime);
    bluR = 3.;
    yelO = tracb + flyY(iTime);
    yelR = 1.;
    
    //vec3 camTarget = trac;
    //vec3 camTarget = tracb;
    //vec3 camTarget = wallO*(1.+sin(iTime*.2))/2. + trac*(1.+sin(iTime*.2+PI))/2.;
    //vec3 camTarget = redO;
    //vec3 camTarget = bluO;
    //vec3 camTarget = yelO;
    //vec3 camTarget = (trac+wallO)/2.;
    //vec3 camTarget = wallO;
    //vec3 camTarget = roofO;
    //vec3 camTarget = hedO;
    //vec3 camTarget = CtreeO+vec3(0.,50.,0.);
    vec3 camTarget = getCam(iTime, trac);
    
    // camera def
    float 	focal = 1.;
    float 	rau = 300.*(sin(iTime/7.)+1.) + 50.,
    		//rau = 80.,
    		alpha,
    		theta;	
    // to start shader
    if (iMouse.xy == vec2(0.)){
        alpha = PIdiv2;
        theta = .3;
    }
    else{
        alpha = iMouse.x/iResolution.x*4.*PI/*-iTime/5.*/,
    	theta = -iMouse.y/iResolution.y*PIdiv2+PIdiv2-.2;//(sin(iTime/7.)/2.+0.5)*(PI/2.-1.)+0.05;
    }
    
    vec3 pos = rau*vec3(-cos(theta)*sin(alpha),sin(theta),cos(theta)*cos(alpha)) + camTarget;
	pos.y = max(ground(pos.xz)+15.,pos.y);		//anti-collision
    
    vec3 ww = normalize( camTarget - pos );
    vec3 uu = normalize( cross(ww,vec3(0.0,1.0,0.0)) ) ;
    vec3 vv = cross(uu,ww);
	// create view ray
	vec3 N_ray = normalize( st.x*uu + st.y*vv + focal*ww );
    
	lightRay = vec3(1.,0.,0.);	// global var
	vec3 GNDnorm = vec3(0.);
    
    vec3 color = vec3(.0);
        
    vec2 cell, outCell;
    vec3 p = pos;
    
    // first step getting boundarry of interesting areas
    // find exit cell

    T = gndRayTrace(pos, N_ray);
    if(T<INFINI){
        hitObj = GND;
        vec3 tp = pos+T*N_ray;
        cell = floor(tp.xz/cellD + .5);
        outCell = getNextCell(pos.xz,N_ray.xz,cell);
    }
    else if(pos.y<cellH){
        T = sfcImpact(pos, N_ray, cellH);
        if(T<INFINI){									// hitObj = SKY already default value
            vec3 tp = pos+T*N_ray;
            cell = floor(tp.xz/cellD + .5);
            outCell = getNextCell(pos.xz,N_ray.xz,cell);
            T = INFINI;									// T consistant with SKY
        }
    }
    else outCell = floor(pos.xz/cellD + .5);
	
    //if cam above ceiling, find entry cell
    // ceiling is the upper most top of object
    // no need the grid above ceiling - no objects possible
    if(pos.y>=cellH){
        float t = sfcImpact(pos, N_ray, cellH);
        if(t<INFINI){
            p = pos+t*N_ray;
        }
    }
    
    // MAIN PROCESS
    // going thru the grid checking for existing object in each cell
    // if obj: raytrace
    // if impact: stop the ray
    // else going again thru the grid
    bool objImpact = false;
    cell = floor(p.xz/cellD + .5);
    for(int i=0; i<maxCell;i++){
        if(cell == outCell) break;
        objImpact = checkCell(cell, pos, N_ray, color);
        if(objImpact) break;
        cell = getNextCell(pos.xz,N_ray.xz,cell);
    } 
    
    // Final position reach by the ray
    // if object in grid has been hit, color and rendering already (localy) done
    // if no object, just check for ground hit or sky
    vec3 finalPos = pos + T*N_ray;
    
    if(hitObj == SKY) color += skyColor(N_ray);
    else if(hitObj == GND){
        GNDnorm = getGndNormal(finalPos.xz,finalPos.y);
        color += groundColor(finalPos, N_ray, GNDnorm);
        float shad = 1.-atan(length(finalPos.xz - pos.xz)/20000.)/PI*1.5;
        float cut = step(.8,shad);
		
        // level lines
        color.b += .5*smoothstep(-.2,0.,-abs(fract(finalPos.y/cellD*10.)-.5))*shad;
        
        // blue pulse line
        float line = -abs((sin(finalPos.x*.004)+2.)*fract(finalPos.z*.002)-.5);
        float pulse = fract(.0002*finalPos.x-iTime*.1+3.*sin(floor(finalPos.z*.002)));
        color.gb += .3*smoothstep(-.01,0.,line)*shad;
        color.gb += smoothstep(-.02,0.,line) *smoothstep(.98,1.,pulse)*shad;
        
    	vec2 finalCell = floor(finalPos.xz/cellD + .5);
        // cotta halo
        if(finalCell == cottaCell)
            color.b += .8*max(0.,3./(length(wallO.xz-finalPos.xz)-wallR+3.)-.1);
        // trees halo
        if(getTree(finalCell,treeO, treeH, treeR)){
            float glow = max(0.,(2./(length(treeO.xz-finalPos.xz)-treeR+2.)-.1));
            //color += vec3(0.019,0.966,0.975)*glow*shad*cut;
    		color.gb += 2.*glow*smoothstep(-.4,0.,line)*smoothstep(.0,2.,pulse)*shad*cut;
        }
    	// Snowman halo
        if(finalCell == snowmanCell)
            color += .8*vec3(0.990,0.395,0.006)*max(0.,3./(length(belO.xz-finalPos.xz)-belR+1.)-.1);
    
        
        // glowing multi-track
        // lag behind fairyligths
        color.r += glowTrack(redO.xz, finalPos.xz, REDL);
        color.rb += glowTrack(magO.xz, finalPos.xz, MAGL);
        color.b += 2.*glowTrack(bluO.xz, finalPos.xz, BLUL);
        
    }
    
    // cylinder of data aroud snowman
    // done in global matter instead of grid, because grid height is limited to celling (maxHeight)
    vec2 tc = cylinderImpact(pos.xz, belO.xz, belR, N_ray.xz);
	if(tc.x < T){
        vec3 cpos = pos + tc.x*N_ray;
        color += vec3(0.990,0.395,0.006)*2./(cpos.y-belO.y+1.);
        float a  = atan(cpos.z-belO.z, cpos.x-belO.x);
        color += flowpatern(a, cpos.y);
    }
    if(tc.y < T){
        vec3 cpos = pos + tc.y*N_ray;
        float a  = atan(cpos.z-belO.z, cpos.x-belO.x);
        color += .5*flowpatern(a, cpos.y);
    }
    
        
    // getting lights position (lights independant of cells)
    int lightNbr;
    float tlit;
    tlit = lightTrace(pos,N_ray,lightNbr,0);		// 0 means no transparency requested
    
    if(tlit<T){
        hitObj = lightNbr;
        vec3 trpos = pos + tlit*N_ray; 
        // adding fairy lights
    	color += 1.5*fairyLight(N_ray, trpos, hitObj);
        tlit = lightTrace(pos,N_ray,lightNbr,hitObj);		// hitObj means transparency requested for this obj
        if(tlit<INFINI){									// to make visible the fairy light behind
            trpos = pos + tlit*N_ray;
        	color += fairyLight(N_ray, trpos, lightNbr);
        }
    }
    
    fragColor = vec4(color,1.0);
}


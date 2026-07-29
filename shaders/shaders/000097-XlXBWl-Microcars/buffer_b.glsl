// Buffer B (buffer) — Microcars by iapafoto
// https://www.shadertoy.com/view/XlXBWl



#define WITH_SHADOW
#define WITH_REFLEXION
#define WITH_AO
    
#define PRECISION_FACTOR 2e-2
#define RAYCAST_CARS

#define MIN_DIST_AO .5*PRECISION_FACTOR
#define MAX_DIST_AO .02
#define PRECISION_FACTOR_AO PRECISION_FACTOR

#define ZERO min(iFrame,0)

float hash1( float n ) { return fract(43758.5453123*sin(n)); }

//------------------------------------------------------------

const float MAX_DIST_RAYMARCHING = 35.;
const int g_traceLimit=48;
const float g_traceSize=.001;

const float 
    ID_GROUND = 2.,
    ID_ENGINE = 1.,
    ID_BOX_1 = 1.5,
    ID_BOX_2 = 1.6;
    
#define BACK_COLOR vec3(.008, .016, .034) 
#define PI 3.141592
#define PI_2 1.5708

const float lW = .06, lH = .06; //06; // Pipe width. 
const float bbox = .06;
const float bridgeH = .04;
const float yTopEnd = lH*3.+bridgeH+bbox*2.; 

const vec3 light = 100.*vec3(-.5,.75,-1.);

float gTime;


vec4[12] _PREV = vec4[12](
    vec4(1,0,-1,0), vec4(-1,0, 1,0), vec4(0,-1,0,1), vec4( 0,1,0,-1),
    vec4(0,1,1,0),  vec4( 0,1,-1,0), vec4(0,-1,1,0), vec4(-1,0,0,-1),
    vec4(-1,0,0,1), vec4( 1,0,0,1), vec4(-1,0,0,-1), vec4( 1,0,0,-1)    
);

vec2[4] _DXY = vec2[4](vec2(1,0), vec2(-1,0), vec2(0,1), vec2(0,-1));


vec4 _CX[12] = vec4[12](
    vec4( 1, 1,-1,-1),vec4(-1, 1, 1,-1),vec4(-1,-1, 1, 0),vec4(-1, 1,-1, 0),
    vec4(-1, 1,-1, 0),vec4( 1, 1, 1, 2),vec4(-1,-1, 1, 0),vec4(-1, 1, 1,-1),    
    vec4(-1,1,-PI_2,PI),vec4(1,1,-PI_2,0),vec4(-1,-1,PI_2,PI),vec4(1,-1,PI_2,0));


float hash(float p){
    return dot(vec2(p,p+1.), vec2(1.361, 113.947));
} 

//------------------------------------------------------------
// https://iquilezles.org/articles/distfunctions
//------------------------------------------------------------

float sdBox(vec3 p, vec3 b ) {
  vec3 d = abs(p) - b;
  return min(max(max(d.x,d.y),d.z),0.) + length(max(d,0.));
}

float sdCappedCylinder( vec3 p, vec2 h ) {
  vec2 d = abs(vec2(length(p.xz),p.y)) - h;
  return min(max(d.x,d.y),0.) + length(max(d,0.));
}

float sdCylinder( vec3 p, vec3 c) {
  return length(p.xz-c.xy)-c.z;
}

//------------------------------------------------------------

mat2 rot(float a) {
    float c = cos(a), s = sin(a);
    return mat2(c,s,-s,c);
}

// rotate a point arround a axis
//void rotCY(inout vec2 v, vec2 c, mat2 rot) {
//    v = (v - c) * rot + c;
//}

vec3 rotY(vec3 v, vec3 c, mat2 rot) {
    v.xz = (v.xz - c.xz) * rot + c.xz;
    return v;
}


vec4 state(in vec2 ip ) {
    return texelFetch( iChannel2, ivec2(ip), 0 );
}

vec3 getPos1(int sq, float t, out float a) {
     vec4 cx = _CX[sq];
     if (sq < 8) {
        a = (cx.w+cx.z*t)*PI_2;
     	return vec3(.5+.5*(cx.x+cos(a)), 2.*lH, .5+.5*(cx.y+sin(a)));
     } else {
         a = cx.z;
         float dh = -bridgeH*sin(1.5708+3.14*t*2.);
         return vec3(.5+(.5-t)*cx.x,2.*lH+dh+bridgeH,.5);
     }
}

vec3 getPos2(int sq, float t, out float a) {
     vec4 cx = _CX[sq];
     if (sq < 8) {
        a = (cx.w+cx.z*t)*PI_2;
        a = sq == 4 || sq == 7 ? -a+PI_2 : 
            sq == 5 || sq == 6 ? -a-PI_2 : a+PI;
     	return vec3(.5+.5*(-cx.x+cos(a)),2.*lH, .5+.5*(-cx.y+sin(a)));
     } else {
         a = cx.w;
     	float dh = -2.*bridgeH+bridgeH*sin(1.5708+3.14*t*2.);
  	 	return vec3(.5,2.*lH+bridgeH+dh,(.5-t)*cx.y+.5);
     }
}

 

//------------------------------------------------------------

vec3 palette( float st ) {
	return .5*cos( 2.*PI*st + vec3(0,1,2) )+.5;
}

//------------------------------------------------------------

bool cube(vec3 ro, vec3 rd, vec3 sz, out float tn, out float tf) {
	vec3 m = 1./rd,
         k = abs(m)*sz,
         a = -m*ro-k*.5, 
         b = a+k;
    tn = max(max(a.x,a.y),a.z);
    tf = min(min(b.x,b.y),b.z);
	return tn>0. && tn<tf;
}


bool cubein(vec3 ro, vec3 rd, vec3 sz, out float tn, out float tf) {
	vec3 m = 1./rd,
         k = abs(m)*sz,
         a = -m*ro-k*.5, 
         b = a+k;
    tn = max(max(a.x,a.y),a.z);
    tf = min(min(b.x,b.y),b.z);
    tn = max(0., tn);
	return tn<tf;
}


// ---------------------------------------------------------------


#ifdef RAYCAST_CARS

float map_obj(vec4 st, vec3 pos, vec3 sz) {
	float d = min(
         sdBox(pos - vec3(sz.x*.1,sz.y*.2,0), vec3(sz.x*.6,sz.y*.8,sz.z*.8)),
         sdBox(pos - vec3(0,-sz.y*.2,0), vec3(sz.x,sz.y*.4,sz.z*.8)));
    float r = min(sz.x, sz.y)*.3;
 // pos.z = abs(pos.z); // tis micro optim Crash compilation !
    float roues = min(sdCappedCylinder(pos.yzx - vec3(-sz.y*.8+r,0.,sz.x*.35),vec2(r,sz.z)),
                      sdCappedCylinder(pos.yzx - vec3(-sz.y*.8+r,0.,-sz.x*.4),vec2(r,sz.z))
                   );

    return min(d,roues);

}
    
#else 

float map_obj(vec4 st, vec3 pos, vec3 sz) {
	return sdBox(pos, sz);
}

#endif

float map_08_12(vec4 st, vec3 pos) {
    float dh = bridgeH*sin(PI_2+PI*pos.x*2.);
    vec3 pos2 = pos;
    pos2.y += dh;
    float d1 = sdBox(pos2-vec3(.5,bridgeH+lH,.5), vec3(.501,lH,lW));
    pos2.y += dh;
    d1 = max(d1,-sdBox(pos2-vec3(.5,bridgeH-.02,.5), vec3(.501,lH,lW+.1)));
    
    pos2 = pos;
    pos2.y += bridgeH - bridgeH*sin(PI_2+PI*pos.z*2.);
    float d2 = sdBox(pos2-vec3(.5,lH,.5), vec3(lW,lH,.5)); 
    
	return max(min(d1,d2), sdBox(pos-vec3(.5,4.*lH,.5), vec3(.501,4.*lH,.501)));;
}

float map_00_07(vec4 st, vec3 pos) {
    int sq = int(round(st.z));
    pos-=vec3(.5,lH,.5);
	float l1 = length(pos.xz - .5*_CX[sq].xy) - .5, 
          l2 = length(pos.xz + .5*_CX[sq].xy) - .5;
	return max(sdBox(pos, vec3(.501,lH,.501)),
               min(abs(l1), abs(l2))-lW); 

}

float trace_00_07(vec4 st, vec3 ro, vec3 rd, float traceStart, float traceEnd ) {
    float h, t = traceStart;
    for( int i=ZERO; i < g_traceLimit; i++) {
        h = map_00_07(st, ro+t*rd );
        t += h;
        if (h < g_traceSize || t > traceEnd)
            return t;
    }
	return traceEnd+1.;
}

float trace_08_12(vec4 st, vec3 ro, vec3 rd, float traceStart, float traceEnd ) {
    float h,t = traceStart;
    for( int i=ZERO; i < g_traceLimit; i++) {
        h = map_08_12(st, ro+t*rd );
        t += h;
        if (h < g_traceSize || t > traceEnd)
            return t;
    }
	return traceEnd+1.;
}

// global distance that works localy
float map(in vec3 pos, in vec2 ip) {
    float time = fract(gTime);
    vec4 st = state(ip);
    int sq = int(round(st.z));

    float ha1 = hash(st.x), ha2 = hash(st.y);
    vec3 sz1 = .03+mod(vec3(ha1, ha1*111.11, ha1*7.3), vec3(bbox-.03)),
         sz2 = .03+mod(vec3(ha2, ha2*111.11, ha2*7.3), vec3(bbox-.03));
    
    vec3 pos1 = pos;
    pos1.xz -= ip;
    float d = sq<8?
        map_00_07(st, pos1) :
    	map_08_12(st, pos1); 
  
    
    float a1, a2;
    vec3 pobj1 = getPos1(sq, time, a1);
    vec3 pobj2 = getPos2(sq, time, a2);
  	pobj1.y += sz1.y;
    pobj2.y += sz2.y;
    
#ifdef RAYCAST_CARS        
    mat2 rot1 = rot(a1-PI_2),
         rot2 = rot(a2-PI_2); 
#else
    mat2 rot1 = rot(a1+2.*PI*fract(ha1)),
         rot2 = rot(a2+2.*PI*fract(ha2)); 
#endif
    
    vec3 
    	p1 = rotY(pos1, pobj1, rot1),
    	p2 = rotY(pos1, pobj2, rot2);

    
	d = min(d, map_obj(st, p1-pobj1, sz1));
	d = min(d, map_obj(st, p2-pobj2, sz2));
     
    // Draw closest neigbourg object
    ip += abs(pos1.x) > abs(pos1.z) ? vec2(sign(pos1.x),0.) : vec2(0., sign(pos1.z));
    st = state(ip), 
    pos1 = pos;
    pos1.xz -= ip;
    d = min(d,sq<8 ? map_00_07(st, pos1) : map_08_12(st, pos1)); 

	return d;    
}

             
vec2 trace_obj(vec4 st, vec3 ro, vec3 rd, float traceStart, float traceEnd ) {
    
    float time = fract(gTime);
    int sq = int(round(st.z));
    float ha1 = hash(st.x), ha2 = hash(st.y);

    vec3 sz1 = .03+mod(vec3(ha1, ha1*111.11, ha1*7.3), vec3(bbox-.03)),
         sz2 = .03+mod(vec3(ha2, ha2*111.11, ha2*7.3), vec3(bbox-.03));

    float tstart1, tstart2;
    
    float dh = .06*sin(1.5708+3.14*time*2.);
    float a1, a2;
  	vec3 pobj1 = getPos1(sq, time, a1);
    vec3 pobj2 = getPos2(sq, time, a2);    
    pobj1.y += sz1.y;
    pobj2.y += sz2.y;
#ifdef RAYCAST_CARS        
    mat2 rot1 = rot(a1-PI_2),
         rot2 = rot(a2-PI_2); 
#else
    mat2 rot1 = rot(a1+2.*PI*fract(ha1)),
         rot2 = rot(a2+2.*PI*fract(ha2)); 
#endif
    vec3 ro1 = ro, ro2 = ro, rd1 = rd, rd2 = rd;
    ro1 = rotY(ro, pobj1, rot1);
    ro2 = rotY(ro, pobj2, rot2);
    rd1.xz *= rot1;
    rd2.xz *= rot2;
    
    float tend;


    // Bounding box
    bool cube1 = cube(ro1 - pobj1, rd1, sz1*2., tstart1, tend);
    bool cube2 = cube(ro2 - pobj2, rd2, sz2*2., tstart2, tend);
    

#ifndef RAYCAST_CARS
    if (cube1 && tstart1 > traceStart) {
        if (cube2 && tstart2 > traceStart && tstart2 < tstart1) {
            return vec2(tstart2, ID_BOX_2);
        }
        return vec2(tstart1, ID_BOX_1);
    } else if (cube2 && tstart2 > traceStart) {
    	return vec2(tstart2, ID_BOX_2);
    } else {  
     	return vec2(1000.0, 0.);
    }
#else

    float t = 0.;
    
    if (cube1) t = min(t, tstart1);
    if (cube2) t = min(t, tstart2);
    
    if ((cube1 || cube2) && (t<traceEnd)) {
        
        float objId = 0.;
        t = max(t, traceStart);
             
        float h1,h2,h;

        for( int i=ZERO; i < g_traceLimit; i++) {
            h1 = map_obj(st, ro1+t*rd1-pobj1, sz1);
            h2 = map_obj(st, ro2+t*rd2-pobj2, sz2);
            h = min(h1,h2);
            objId = h1<h2 ? ID_BOX_1 : ID_BOX_2;

            if (h < g_traceSize || t > traceEnd)
                return vec2(t+h, objId);
            t = t+h;
        }
    }
	return vec2(1000.0,0.);
#endif 
}
 


vec4 min4(vec4 a, vec4 b) {
    return a.x<=b.x ? a : b;   
}

vec4 castRay( in vec3 ro, in vec3 rd, in float tstart, in float tend)
{
   
    if (rd.y<.0) { // on regarde vers le bas
		tstart = max(tstart,(yTopEnd-ro.y)/rd.y);
		tend = min(tend, -ro.y/rd.y);
    } else { // on regarde vers le hut
    	float tp = (yTopEnd-ro.y)/rd.y;
		tend = min(tend, (yTopEnd-ro.y)/rd.y);
		tstart = max(tstart, -ro.y/rd.y);
    }
    
	vec2 pos = floor(ro.xz + rd.xz*tstart);
	vec2 ri = 1.0/rd.xz;
	vec2 rs = sign(rd.xz);
	vec2 ris = ri*rs;
	vec2 dis = (pos-ro.xz+ 0.5 + rs*0.5) * ri;

    vec3 rdi = 1.0/rd;
    vec3 rda = abs(rdi);
	vec2 rds = sign(rd.xz);

    
    tend = min(tend, MAX_DIST_RAYMARCHING);
	vec4 res = vec4( tend+1., 4.0, 0.0, 0.0 );
    
    // traverse regular grid (in 2D)
	for( int i=ZERO; i<24; i++ ) 
	{
        float ts, tn;
        
        if (!cubein(ro-vec3(.5+pos.x, yTopEnd*.5, .5+pos.y), rd, vec3(1.01,yTopEnd,1.01), ts, tn)  || (ts > tend || tn < tstart)) {
           break;   
        }

        vec2 ip = floor(pos);   
    	vec4 st = state(ip);
    	int sq = int(round(st.z));
        float d =  sq<8?
             		trace_00_07(st, ro-vec3(pos.x, 0, pos.y), rd, tstart, res.x) :
             		trace_08_12(st, ro-vec3(pos.x, 0, pos.y), rd, tstart, res.x); 
        
        res = min4(res,vec4(d, ID_ENGINE, ip));
          
        vec2 d2 = trace_obj(st, ro-vec3(pos.x, 0, pos.y), rd, tstart, res.x);
        res = min4(res,vec4(d2, ip));

        
        for (int k=0; k<4;k++) {
            vec2 pos2 = pos+ _DXY[k];
	        vec2 ip2 = ip + _DXY[k];   
    		vec4 st2 = state(ip2);
    		int sq2 = int(round(st2.z));
            
            
	        vec2 d2 = trace_obj(st2, ro-vec3(pos2.x, 0, pos2.y), rd, tstart, res.x);
        	res = min4(res,vec4(d2, ip2));
      //     	if (cube(ro-vec3(.5+pos.x, lW, .5+pos), rd, 1.3*vec3(lW,lH,lW), ts, tn)) {
      //     		res = min4(res,vec4(ts, ID_ENGINE, ip2));
      //  	}
        }
       
        
        // step to next cell		
		vec2 mm = step(dis.xy, dis.yx); 
		dis += mm*ris;
        pos += mm*rs;
	}

	return res;
}

vec3 Normal( vec3 pos, vec3 ray, float t, vec4 res) {

	float pitch = .2 * t / iResolution.x;
    
//#ifdef FAST
//	// don't sample smaller than the interpolation errors in Noise()
	pitch = max( pitch, .001 );
//#endif
	
	vec2 d = vec2(-1,1) * pitch;

	vec3 p0 = pos+d.xxx; // tetrahedral offsets
	vec3 p1 = pos+d.xyy;
	vec3 p2 = pos+d.yxy;
	vec3 p3 = pos+d.yyx;
	
	float f0 = map(p0, res.zw);
	float f1 = map(p1, res.zw);
	float f2 = map(p2, res.zw);
	float f3 = map(p3, res.zw);
	
	vec3 grad = p0*f0+p1*f1+p2*f2+p3*f3 - pos*(f0+f1+f2+f3);
	//return normalize(grad);
	// prevent normals pointing away from camera (caused by precision errors)
	return normalize(grad - max(.0,dot (grad,ray ))*ray);
}


vec3 calcNormal( in vec3 pos, in vec3 rd, float d, in vec4 res )
{
	if( res.y>1.99 ) return vec3(0.0,1.0,0.0);
	return Normal(pos, rd, d, res); //normalize(pos*vec3(1.0,1.0-ic,1.0));
}



vec3 cameraPath( float t )
{
    // procedural path	
    vec2 p  = 100.0*sin( 0.02*t*vec2(1.2,1.0) + vec2(0.1,0.9) );
	     p +=  50.0*sin( 0.04*t*vec2(1.1,1.3) + vec2(1.0,4.5) );
	float y = 5.5 + 2.5*sin(0.1*t-2.);

	return .5*vec3(p.x, y, p.y );
}



#ifdef WITH_AO

float calcAO4( const vec3 pos, const vec3 nor ) {
    float hr, occ = 0., sca = 1.;
    vec2 ip;
    for(int i=ZERO; i<5; i++ ) {
        hr = MIN_DIST_AO + MAX_DIST_AO*float(i)/4.;
        ip = floor(nor * hr + pos).xz;
        occ += -(map(nor * hr + pos, ip)-hr)*sca;
        sca *= .95;
    }
    return clamp(1. - 10.*occ, 0., 1.);    
}

#endif


// Adapted from Shane
vec3 doColor(in float matid, in vec3 sp, in vec3 rd, in vec3 sn, in vec3 lp, in vec3 objCol, in bool withShadow){
    
    vec3 ld = lp-sp; // Light direction vector.
    float lDist = max(length(ld), 0.001); // Light to surface distance.
    ld /= lDist; // Normalizing the light vector.
    
    // Standard diffuse term.
    float diff = max(dot(sn, ld), 0.);
    // Standard specualr term.
    float spec = pow(max( dot( reflect(-ld, sn), -rd ), 0.0 ), 8.0);
    // Combining the above terms to produce the final scene color.
    vec3 col = objCol*(diff + 0.15);
    vec3 sceneCol = col + vec3(1., .6, .2)*spec*2.; 
    
#ifdef WITH_AO
    float ao = calcAO4(sp, sn);
    sceneCol *= (.4+.6*ao);
#endif
    
#ifdef WITH_SHADOW
    // shadows
    float sh= 1.;
    if (withShadow) {
        // HACK to avoid an artfact  :/
        if (matid == ID_ENGINE && sp.y>0.11 && (fract(sp.z)<0.07||fract(sp.z)>.97 || fract(sp.x)<0.07||fract(sp.x)>.97)) sp.y +=.2;
    	sh = castRay(sp+sn*.001, ld, .001, 10.).x;
    	sh = 1.-smoothstep(.6,0.2,sh); 
    }      
    sceneCol *= (.4+.6*sh);
#endif
  //  if (matid == ID_ENGINE && (fract(sp.z)<0.07||fract(sp.z)>.97 || fract(sp.x)<0.07||fract(sp.x)>.97)) sceneCol = vec3(1,0,0);
    return sceneCol*.7;
}



void fill(inout vec3 col, vec3 c, float d) {
	col = mix(c, col, smoothstep(0.,.01, d));
}

void draw(inout vec3 col, vec3 c, float d, float ep) {
	col = mix(c, col, smoothstep(0.,ep, abs(d)));
}


void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    gTime = 1.*iTime;
    
    // inputs	
	vec2 q = fragCoord.xy / iResolution.xy;
	
    vec2 mo = iMouse.xy / iResolution.xy;
    if( iMouse.w<=0.00001 ) mo=vec2(0.0);
		
    float t = 1000.;
	
	// montecarlo	
	vec3 tot = vec3(0.0);
	int a = 0;
	{
        vec2 p = -1.0 + 2.0*(fragCoord.xy) / iResolution.xy;
        p.x *= iResolution.x/ iResolution.y;
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
        float r2 = p.x*p.x*0.32 + p.y*p.y;
        p *= (7.0-sqrt(37.5-11.5*r2))/(r2+1.0);
        vec3 rd = normalize( p.x*uu + p.y*vv + 2.5*ww );



        // background color	
		vec3 bgcol = BACK_COLOR;

        vec3 col = bgcol;
		
        float tstart = 0.;
	
        vec4  res = castRay(  ro, rd, tstart, MAX_DIST_RAYMARCHING);
         t = res.x;
          
        if (rd.y<0.)
        	res = min4(res, vec4(((-.01-ro.y)/rd.y), ID_GROUND, 0,0));
            
        if( t > 0.0 ) {
			vec3 pos = ro + rd*res.x;
            vec2 ip = res.zw;
            
            vec4 st = state(ip);
			vec3 nor = calcNormal(pos, rd, t, res );
            vec3 mate = res.y == ID_GROUND ? vec3(.03) :
            			res.y == ID_ENGINE ? vec3(1.) :
                		palette((res.y == ID_BOX_1 ? st.x : st.y));
            
            col = doColor(res.y,pos, rd, nor, light, mate, true);
			col = mix(col, BACK_COLOR, smoothstep(0.3, 1., t/MAX_DIST_RAYMARCHING));
#ifdef WITH_REFLEXION            
            if (res.y == ID_GROUND) {
                
                rd = reflect(rd, nor);
                ro = pos + rd*.01;
           		res = castRay(ro, rd, 0., 1.);
               
                if (res.x > 0.0 ) {
                    vec3 pos = ro + rd*res.x;
                    vec2 ip = res.zw;

                    st = state(ip);
                    nor = calcNormal(pos, rd, res.x, res );
                    mate = res.y == ID_GROUND ? vec3(.1) :
                                res.y == ID_ENGINE ? vec3(1.) :
                                palette((res.y == ID_BOX_1 ? st.x : st.y));

                    vec3 colr = doColor(res.y, pos, rd, nor, light, mate, false);
                    colr = mix(colr, BACK_COLOR, smoothstep(0.3, 1., t/MAX_DIST_RAYMARCHING));
                    col = mix(col, colr,.1*smoothstep(0.3,.0,res.x));

                }    
            }
#endif // WITH_REFLEXION            
        }
		
       // col = clamp(col,0.0,1.0);
		tot += col;
	}
	

	tot = pow( clamp(tot,0.0,1.0), vec3(0.44) );
		
	fragColor = vec4( tot, t>0. ? t : 1000. );
}








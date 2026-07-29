// Buf A (buffer) — volumetric fractal pathtrace by public_int_i
// https://www.shadertoy.com/view/Xtc3RS

//Ethan Alexander Shulman 2016


//montecarlo path tracing pass


#define pi 3.1415926
#define pi2 (pi*2.0)

#define camera_fisheye 1.0

#define iterations 256
#define minDelta .2
#define maxDelta 1.
#define skipDelta .1

#define range 256.


#define sunImportance 0.5

#define clouddeform 0.04
#define clouddeformscale 0.25


#define camerarange 256.


#define fractal_seed 2.054
#define fractal_seed2 1.53
#define fractal_size 18.
#define fractal_iter 3

#define fractal_color vec3(.9)


vec3 sunDirection = normalize(vec3(3.,5.,1.));
const vec3 sunColor = vec3(1.,.74,.94)*2.,
    	   skyColor = vec3(0.04,0.06,0.14)*0.0,
    	   ambientColor = vec3(.99);

const float sunSize = 0.004,//0-1
    		cloudDensity = 1.8,//0-2, density/alpha of the clouds
    		cloudFluff = .6,//0-1, fluffiness/alpha fade of clouds
    		cloudRoughness = 0.,// roughness of the clouds features
            ambientDensity = 0.;//0-2, global mist



#define devrender 0



float ffract(float p) {
    return fract(p)*2.-1.;
}
vec3 ffract(vec3 p) {
    return fract(p)*2.-1.;
}

    
vec2 rot(in vec2 v, in float ang) {
    float si = sin(ang);
    float co = cos(ang);
    return v*mat2(si,co,-co,si);
}


float encodeRot(vec2 r) {
    return fract(r.x/pi2)+floor(.5+fract(r.y/pi2)*2048.);
}
vec2 decodeRot(float r) {
    return vec2(r-floor(r),
                floor(r)/2048.0)*pi2;
}
//random float 0-1 from seed a
float hash(float a) {
    return fract(fract(a*24384.2973)*512.34593+a*128.739623);
}
//random float 0-1 from seed p
float hash3(in vec3 p) {
    return fract(fract(p.x)*128.234+fract(p.y)*124.234+fract(fract(p.z)*128.234)+
                 fract(p.x*128.234)*18.234+fract(p.y*128.234)*18.234+fract(fract(p.z*128.234)*18.234));
}

//random ray in a hemisphere relative to d, uses p as a seed
vec3 randomHemiRay(in vec3 d, in vec3 p) {
    vec3 rand = normalize(ffract(ffract(p)*512.124+ffract(p*16.234)*64.3249+ffract(p*128.234)*12.4345));
    return rand*sign(dot(d,rand));
}

//random ray using p as a seed
vec3 randomRay(in vec3 p) {
    vec3 rand = normalize(ffract(ffract(p)*512.124+ffract(p*16.234)*64.3249+ffract(p*128.234)*12.4345));
    return rand;
}

float sdTorus( vec3 p, vec2 t ) {
  vec2 q = vec2(length(p.xz)-t.x,p.y);
  return length(q)-t.y;
}
float udBox( vec3 p, vec3 b )
{
  return length(max(abs(p)-b,0.0));
}
float sdBox( vec3 p, vec3 b )
{
  vec3 d = abs(p) - b;
  return min(max(d.x,max(d.y,d.z)),0.0) +
         length(max(d,0.0));
}
float sdCapsule( vec3 p, vec3 a, vec3 b, float r )
{
    vec3 pa = p - a, ba = b - a;
    float h = clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );
    return length( pa - ba*h ) - r;
}
float sdTriPrism( vec3 p, vec2 h )
{
    vec3 q = abs(p);
    return max(q.z-h.y,max(q.x*0.866025+p.y*.5,-p.y)-h.x*0.5);
}
float smin( float a, float b, float k )
{
    float h = clamp( 0.5+0.5*(b-a)/k, 0.0, 1.0 );
    return mix( b, a, h ) - k*h*(1.0-h);
}
float smax( float a, float b, float k) {
    return log(exp(k*a)+exp(k*b))/k;
}

//static backgrund
vec3 background(vec3 d) {
    float sun = dot(normalize(sunDirection), d);
    return mix(skyColor,
               sunColor,
               pow(max(0., sun-(1.-sunSize))/sunSize,.3));
}


vec3 color(in vec3 p) {
    return fractal_color;
    
    float mlen = max(abs(p.x),max(abs(p.y),abs(p.z)));
    if (mlen < 30.) {
        return vec3(.85);
    }
    
    #define colorscale 10.
    float id = mod(floor(p.x/colorscale)+floor(p.y/colorscale)+floor(p.z/colorscale), 2.);
    return mix(vec3(1.,.46,.06),vec3(.14,.8,.9),id);
}


float ruins(in vec3 p) {
    vec3 rp = p;
    float d = 0.;
    float s = fractal_size;
    
    #define seed fractal_seed
    #define seed2 fractal_seed2
    for (int i = 0; i < fractal_iter; i++) {
        rp -= s/8.;
        d = max(-sdBox(mod(abs(rp), s*2.)-s, vec3(s*.9)), d);
        
        if (mod(float(i),2.) > 0.) {
            rp.xz = abs(rot(rp.xz,float(i)*1.2+seed));
        } else {
            rp.zy = abs(rot(rp.zy,float(i)*1.2+seed2));
        }
        
    	s /= 2.;
    }
                       
    return max(sdTriPrism(p*vec3(1.,-1.,1.), vec2(60., 40.)), d);
}

//distance function defining the clouds shape
float df(vec3 p) {
	
    //base shape
   	float d = ruins(p);//abs(length(p.xy)-10.)-1.9;
    
    //cloud shape deform
    #ifdef clouddeform
	#define ldst d
    for (int i = 1; i < 4; i++) {
        float pfi = pow(float(i),2.)*clouddeformscale;
        ldst += abs(cos(p.x/pfi+cos(26.2348+ldst*cloudRoughness*p.z/pfi+(p.y*.39)/pfi)*4.)*
     		     cos(p.y/pfi+cos(29.8937+ldst*cloudRoughness*p.x/pfi+(p.z*.37)/pfi)*4.)*
       		     cos(p.z/pfi+cos(14.972+ldst*cloudRoughness*p.y/pfi+(p.x*.41)/pfi)*4.))*pfi*(clouddeform/clouddeformscale);
    }
	#endif
    
    return max(skipDelta, d);
}
//density lerp percent from distance d and point p
float dstToDensity(float d, vec3 p) {
    return min(1., (d-skipDelta)*10.*(1.-cloudFluff));
}


void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec4 camtex = texture(iChannel1, 0.5/iResolution.xy);
    float frame = texture(iChannel2, 0.5/iResolution.xy).x*4096.;
       
    
    vec2 uv = fragCoord/iResolution.xy;
    
    
    //ray direction from uvs and ray position at origin
    vec3 rd = normalize(vec3((fragCoord*2.-iResolution.xy)*vec2(-1.,1.)/iResolution.x,1./camera_fisheye)),
         ird,
         rp = camtex.xyz-camerarange;
    
    vec2 cameraRot = decodeRot(camtex.w);
    rd.yz = rot(rd.yz,cameraRot.y);
    rd.xz = rot(rd.xz,cameraRot.x);
    
    ird = rd;
    float ifrm = float(iFrame);
    #define rndifrm(s) fract(fract(ifrm*.044877+s)*256.494+ifrm*.02934)
    
    vec4 c = vec4(1,1,1,0);
    
    #if devrender == 0
    
    
    //render
    for (int i = 0; i < iterations; i++) {
        float d = df(rp),
              dt = d*(minDelta+hash3(rp+rndifrm(rp)*1024.)*(maxDelta-minDelta)),
              k = dstToDensity(d,rp);
        if (mix(cloudDensity,ambientDensity,k)*max(1.,dt*.1) > hash3(rp+rndifrm(rp)*256.)) {//if density > random then ray hits cloud
            c.xyz *= pow(mix(color(rp),ambientColor,floor(k)),
                             vec3(1.));
            c.w = 1.;
            rd = mix(randomRay(rp+rndifrm(rp*1024.)*1024.), sunDirection, floor(hash3(rp*.9+rndifrm(rp*1.5)*512.)+sunImportance-1e-6));
        }
        
        rp += rd*dt;
        if (length(rp) > range) break;
    }
   
    c.xyz *= background(rd)*float(length(rp)/range > 1.);//if light ray makes it too edge of world illuminate it  
    fragColor = mix(vec4(background(ird),1.), c, c.w)+
    texture(iChannel0, uv)*float(float(iFrame)-frame > 1.0);//blend result with background and add to buffer

    //used for exporting image in the format of r=lighting, g=opacity
    /*(fragColor = vec4(c.x*float(max(length(rp)/range,max(0.,-rp.y)/yRange) > 1.),c.w,0,0)+
                     texture(iChannel0, uv);
    */
    
    #else
    for (int i = 0; i < iterations; i++) {
        float d = df(rp);
        if (d < .2 || c.w > range) break;
        
        rp += rd*d;
        c.w += d;
    }
    if (df(rp) < .2) {
       c = vec4(cloudColor*(.3+max(0.,(df(rp)-df(rp-sunDirection)))),1.);
    } else {
       c = vec4(background(ird),1.); 
    }
    fragColor = c+texture(iChannel0,uv);
    #endif
}
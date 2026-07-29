// Buffer A (buffer) — Psychedelic spins by rcargou
// https://www.shadertoy.com/view/dtBBRc

#define AA 1   // make this 2 or 3 for antialiasing



//------------------------------------------------------------------

#define ZERO (min(iFrame,0))

//------------------------------------------------------------------

// play with thoses
int sym = 1;
int iqheart = 0;
int megamod = 0;

float yuid = 0.;
float sdTunnelDepth(in vec3 p, out vec3 matData, float time, float tid) {
vec3 l = p;
//p.y+=cos(p.x * 4.) / 4.;
float ty = 5.5;
p.z = mod(p.z + time*-18., ty)-ty/2.;
if (sym ==1) {
p.xz = -abs(p.xz);
p.xy *= rotate2d(iTime);
p.xz = -abs(p.xz);

p.xy *= rotate2d(iTime / 4. + 12.);
p.xz = -abs(p.xz);
p.xy *= rotate2d(iTime / 8. + 3.);
p.xz = -abs(p.xz);

p.xy *= rotate2d(iTime/ -3. + 4.);
p.xz = -abs(p.xz);
p.xy *= rotate2d(iTime / - 7. + 5.);
p.xz = -abs(p.xz);
}
//p.zyx*=2.;
float b =.0;
    p.xy *= rotate2d(p.z/ 1.5)/1.;
 
    p.xy*=rotate2d(time * 2.);
    float r = 4.;//+sin(iTime) ;
    p = cartestianToSpherical(p);
   // p.z *= 6.+sin(time) * 5.;
   float a = p.z;
    p.z *= 3.;p.z+=time * -12.;
    
        p = sphericalToCartesian(p);
        if (megamod==1)
    p= mod(p, r) - r/2.;
   // p.xyz = abs(p.xyz);
    //p.x = abs(p.x);
    p.z+=time * -6.;
//    p.xy *= rotate2d(p.z/ 3.5 + time);
    // global transformation
  //  float u = 3.+cos(iTime / 120.) * 3., v = 2.*sin(iTime);
    float u = 3.;
    float v = 1.;
    if (tid==0.){
    p.x += sin(p.z*6. * u) / 11.+sin(p.z/11. + 1.7) / 2. * v;
    p.y += cos(p.z*1. * u + time*3.) / 2. * v;
    p.y += sin(p.z*2.  * u+ cos(time*6.)*2.) / 4. * v;
   // p.xy *= rotate2d(time * 2.);
     p.x += cos(p.z*.5 * u) / 24. * v;
      //p.z += cos(iTime) * 2. * v;

     }
     
    vec3 p1 = p;
    vec3 p2 = p;
 
    // spherical space
    vec3 ps = cartestianToSpherical(p1);
    float id = floor(ps.z / .2245);
    matData.x = ps.z/2.+p.z/2. + time / .1;
    if (tid==0.)
    matData.x += 1.;
//    matData.x = (ps.z+a)*.1+time/2.;//1.*( (ps.z + a)/13. +  p.z*0. + iTime*0.);//(ps.z + a) / 12. + iTime / 4. + p.z * 2.*sin(time / -25.);//3.;//id / .32;
   // ps.z *=1.5 + sin(iTime)/2.;
   
   ps.z*=2.;
   
    //matData.y = mod(ps.z + time*100., 12.) - 6. ;
    ps.z = mod(ps.z, .2245) -1.7;    
    
    p1 = sphericalToCartesian(ps);
    matData.y = id;
    p1.y+=1.5;
    //if (mod(floor( (sin(iTime/ 12.) * 32.)),2.) == 0.)
      // return length(p1.xy) - .05;
    // Per cylinder transformation
   // p1.xy *= rotate2d(id + time);
   vec3 p4 = p1;
    p1.x += cos(p.z*3.5 * hash11(id / 32.) * 21.14) / 12.;
 
     p1.y+=cos(p.z * 2.* hash11(id / 12.)) / 5.;
     float rep = .051;
     p.z+=sin(p.x * 1.) / 2.5;
    p.z+=time*-1.;
    
    p.z = mod(p.z, rep) - rep/2.;   
    
    float tdist = sdTorus(p.xzy, vec2(1.5,.0005));
  //  return tdist;
  
  vec3 pp = p2;
  r = .92;
  pp.xy*=rotate2d(time * -12.);
  pp.x-=11.5;
  
  pp = mod(pp, r) - r/2.;
    float  ppdist = length(pp) - .02;
    return min( min(length(p1.xy) - .05 /*+ sin(iTime) /10.*/, tdist), ppdist);

}

float sdTunnel(in vec3 p, out vec3 matData) {

    float time = iTime / 2.;
    float d1 =  sdTunnelDepth(p, matData, -time/ 6. + yuid*330.1123, 0.);
    
    return d1;
    float d2 =  sdTunnelDepth(p * vec3(.4, .4, .5), matData, time / 7. + 1., 1.);
     matData.z = 1.;
   //  if (mod(floor( (sin(iTime/ 2.) * 32.)),2.) == 0.)
     return d1;
     //return d2;
     if (d1<d2)
     matData.z = 1.;
    // if (sin(iTime) < -.3)
    ;// d1=d2;
    return min(d2,d1);
}

vec2 map( in vec3 pos , out vec3 matData)
{
    vec2 res = vec2( 1e10, 0.0 );
    float d = 0.;
     vec3 matData_tmp;
     if ((d = sdTunnel(pos, matData_tmp)) < res.x) {
        res.x = d;
        res.y = 1.;
        matData=matData_tmp;
    }
    
    return res;
}

const float maxHei = 0.8;

vec2 castRay( in vec3 ro, in vec3 rd, out vec3 matData)
{
    vec2 res = vec2(-1.0,-1.0);

    float tmin = .11;
    float tmax = 30.0;

    // raymarch primitives   
    {
    
        float t = tmin;
        for( int i=0; i<150 && t<tmax; i++ )
        {
            vec2 h = map( ro+rd*t, matData );
            if( abs(h.x)<(0.01*t) )
            { 
                res = vec2(t,h.y); 
                 break;
            }
            t += h.x * .3;
        }
    }
    
    return res;
}

// https://iquilezles.org/articles/normalsSDF
vec3 calcNormal( in vec3 pos )
{
    vec3 t;
    vec2 e = vec2(1.0,-1.0)*0.5773*0.0005;
    return normalize( e.xyy*map( pos + e.xyy,t ).x + 
					  e.yyx*map( pos + e.yyx,t ).x + 
					  e.yxy*map( pos + e.yxy,t ).x + 
					  e.xxx*map( pos + e.xxx,t ).x );
 
}

float calcAO( in vec3 pos, in vec3 nor )
{
	float occ = 0.0;
    float sca = 1.0;
    vec3 t;
    for( int i=ZERO; i<5; i++ )
    {
        float hr = 0.01 + 0.12*float(i)/4.0;
        vec3 aopos =  nor * hr + pos;
        float dd = map( aopos,t ).x;
        occ += -(dd-hr)*sca;
        sca *= 0.95;
    }
    return clamp( 1.0 - 3.0*occ, 0.0, 1.0 ) * (0.5+0.5*nor.y);
}


mat3 setCamera( in vec3 ro, in vec3 ta, float cr )
{
	vec3 cw = normalize(ta-ro);
	vec3 cp = vec3(sin(cr), cos(cr),0.0);
	vec3 cu = normalize( cross(cw,cp) );
	vec3 cv =          ( cross(cu,cw) );
    return mat3( cu, cv, cw );
}

vec3 getcol(float x1) {

float x2= mod(iTime / 3. + yuid * 4., 7.) + 0.;
float x = fract(x1 / 1.);
//x2=0.;
    vec3 cols[7] = vec3[7] (pal( x, vec3(0.5,0.5,0.5),vec3(0.5,0.5,0.5),vec3(1.0,1.0,1.0),vec3(0.0,0.33,0.67) ),
    pal( x, vec3(0.5,0.5,0.5),vec3(0.5,0.5,0.5),vec3(1.0,1.0,1.0),vec3(0.0,0.10,0.20) ),
    pal( x, vec3(0.5,0.5,0.5),vec3(0.5,0.5,0.5),vec3(1.0,1.0,1.0),vec3(0.3,0.20,0.20) ),
    pal( x, vec3(0.5,0.5,0.5),vec3(0.5,0.5,0.5),vec3(1.0,1.0,0.5),vec3(0.8,0.90,0.30) ),
    pal( x, vec3(0.5,0.5,0.5),vec3(0.5,0.5,0.5),vec3(1.0,0.7,0.4),vec3(0.0,0.15,0.20) ),
    pal( x, vec3(0.5,0.5,0.5),vec3(0.5,0.5,0.5),vec3(2.0,1.0,0.0),vec3(0.5,0.20,0.25) ),
    pal( x, vec3(0.8,0.5,0.4),vec3(0.2,0.4,0.2),vec3(2.0,1.0,1.0),vec3(0.0,0.25,0.25) )
    );
    return mix( cols[int(x2)], cols[int(mod(x2, 7.)) + 1] , fract(x2));
}

vec3 render( in vec3 ro, in vec3 rd,vec2 uv )
{ 
    vec3 col = vec3(.0f);
    
    vec3 matData;
    vec2 res = castRay(ro,rd, matData);
    float t = res.x;
	float m = res.y;
    //  vec3 albedo = hash13(matData.x);
    float i = matData.x;
    vec3 nor = calcNormal(ro + rd * res.x);
    float ao = calcAO(ro+rd*res.x, nor);
   // vec3 albedo = pal( i, vec3(0.5,.5,0.5),vec3(.5,0.5,0.501),vec3(1.0,1.0,1.0),vec3(0.3,0.20,0.20) );
    vec3 albedo = getcol(i);
    
  float idL = floor(mod(iTime, 14.));
    if (res.x > .0f) {
    	col = vec3(0.) + albedo* vec3(.9f, .5f, .5f) * max(.1f, dot(normalize((ro+ t * rd) - normalize(vec3(100.0f, 1000.0f, 100.0f))), 
             nor) );
        col *= exp(res.x*-.1);   

        //col *= 1.+15. * smoothstep(.1, .0,abs(matData.y - 1.));
       
       if (int(matData.y) % 22 == 0)
            col *= 5. + 10.*float(sym);
        else if (int(matData.y) % 8 == 0)
            col *= 2. + 5.*float(sym);
            
     } else {
        col = .3*pow(texture(iChannel0, uv/1. + vec2(iTime / 16., 0.)).xyz, vec3(5.)).xyz;
     }
    return col * (1.+ smoothstep(.1, .05, length(uv)) * 20. * float(sym==1));//*ao *ao*4.;
   	return vec3(col*abs(nor));
}



void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 mo = vec2(0);//iMouse.xy/iResolution.xy;
	float time = .0f; //iTime;

    // camera	
    vec3 ro = vec3(.0f, .0f, -4.0f);//vec3( 4.6*cos(0.1*time + 6.0*mo.x), 1.0 + 2.0*mo.y, 0.5 + 4.6*sin(0.1*time + 6.0*mo.x) );
    vec3 ta = vec3( -0.5, -0.4, 0.5 );
    // camera-to-world transformation
    mat3 ca = setCamera( ro, ta, 0.0 );

   
    vec2 p = (-iResolution.xy + 2.0*fragCoord)/iResolution.y;

if (iqheart == 1) {
float rr = 2.;
//p.y-=iTime * 2.;
vec2 ids;
p.y += -iTime * 2. + float(p.x>0.);
 ids = hash22(floor(p / rr));
yuid= ids.x;

p = mod(p, rr) - rr/2.;
}
    // ray direction
    vec3 rd = normalize( vec3(p.xy,.5) );

    // render	
    vec3 col = render( ro, rd, p.xy );

    // gamma
   col = pow( col, vec3(1.2545) );
   //  col = pow( col, vec3(.809545) );
    
    fragColor = vec4( saturate(col), 1.0 );
    
    //	p = (2.0*fragCoord-iResolution.xy)/min(iResolution.y,iResolution.x)/1.5;
	
    // background color
    vec3 bcol = vec3(1.0,0.8,0.7-0.07*p.y)*(1.0-0.25*length(p));

    // animate
    float tt = mod(iTime,1.5)/1.5;
    float ss = pow(tt,.2)*0.5 + 0.5;
    ss = 1.0 + ss*0.5*sin(tt*6.2831*3.0 + p.y*0.5)*exp(-tt*4.0);
    p *= vec2(0.5,1.5) + ss*vec2(0.5,-0.5);

    // shape
	p.y -= 0.25;
    float a = atan(p.x,p.y)/3.141593;
    float r = length(p);
    float h = abs(a);
    float d = (13.0*h - 22.0*h*h + 10.0*h*h*h)/(6.0-5.0*h);
    
	// color
	float s = 0.75 + 0.75*p.x;
	s *= 1.0-0.4*r;
	s = 0.3 + 0.7*s;
	s *= 0.5+0.5*pow( 1.0-clamp(r/d, 0.0, 1.0 ), 0.1 );
	vec3 hcol = vec3(2,0.2*r,0.3) / 15. * s / .5;
	
//     col = mix( col, hcol, smoothstep( -0.01, 0.01, d-r) );
if(iqheart==1)
    col = mix(hcol / 4.,col,min(1., max(0.0,5.*(d-r ))));
    fragColor = vec4(saturate(col),.0);
}
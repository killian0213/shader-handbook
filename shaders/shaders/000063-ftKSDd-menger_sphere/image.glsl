// Image (image) — menger sphere by jorge2017a2
// https://www.shadertoy.com/view/ftKSDd

//----------image
//por jorge2017a1-

//reference
//https://www.shadertoy.com/view/wllXzX .. Mandelbulb Labyrinth

#define MAX_STEPS 100
#define MAX_DIST 100.
#define MIN_DIST 0.001
#define EPSILON 0.001
#define REFLECT 2

vec3 GetColorYMaterial(vec3 p,  vec3 n, vec3 ro,  vec3 rd, int id_color, float id_material);
vec3 getMaterial( vec3 pp, float id_material);
vec3 light_pos1;  vec3 light_color1 ;
vec3 light_pos2;  vec3 light_color2 ;

//operacion de Union  por FabriceNeyret2
#define opU3(d1, d2) ( d1.x < d2.x ? d1 : d2 )
#define opU(d1, d2) ( d1.x < d2.x ? d1 : d2 )


float sdSphere( vec3 p, float s )
	{ return length(p)-s;}
float sdBox( vec3 p, vec3 b )
	{ vec3 d = abs(p) - b;   return length(max(d,0.0))+ min(max(d.x,max(d.y,d.z)),0.0); }
///----------Operacion de Distancia--------
float intersectSDF(float distA, float distB)
	{ return max(distA, distB);}
float unionSDF(float distA, float distB)
	{ return min(distA, distB);}
float differenceSDF(float distA, float distB)
	{ return max(distA, -distB);}

#define MENGER_ITERATIONS	2

#define dot2(x) 			dot(x, x)
float sdPlane(vec3 p, float height)
{
   	return p.y - height;
}

vec4 map(in vec3 p)
{   //float ground = sdPlane(p, 1.8);
    p.xz = mod(p.xz + 1.0, 2.0) -1.0;
    p.y = mod(p.y + 1.0, 2.0) - 1.0;
	
    float d1,d2,d3;
    
    float t1=mod(itime,3.0);
    float t2=mod(itime,4.0);
    if (t1<t2)
    {   
     d1=sdSphere(p-vec3(-0.25,0.0,0.0), 0.5 );
     d2=sdSphere(p-vec3(0.0,0.25,0.0), 0.5 );
     d3=sdSphere(p-vec3(0.25 ,0.0,0.0), 0.5 );
    } 
    else
    {
     d1=sdSphere(p-vec3(-0.25,0.0,0.0), 0.7 );
     d2=sdSphere(p-vec3(0.0,0.25,0.0), 0.20 );
     d3=sdSphere(p-vec3(0.25 ,0.0,0.0), 0.6 );
    }

    float d=min(min(d1,d2),d3);
    vec4 res = vec4(d, 2.0, 0.0, 0.0);
	
    float s = 1.0;
    for(int i = 0; i < MENGER_ITERATIONS; ++i)
    {  vec3 a = mod(p * s, 2.0) - 1.0;
        s *= 5.0;
        vec3 r = abs(1.0 - 3.0 * abs(a));
        float da = max(r.x, r.y);
        float db = max(r.y, r.z);
        float dc = max(r.z, r.x);
        float c = (min(da, min(db, dc)) - 1.3) / s;

        if(c > d)
        {   d = c;
            res = vec4(d, min(res.y, 0.2 * da * db * dc), 0.0, 1.0);
        }
    }
    return res;    
}

vec3 GetDist(vec3 p  ) 
{	vec3 res= vec3(9999.0, -1.0,-1.0);  vec3 p0=p;
   float planeDist1 = p.y-2.0;  //piso inf
    vec4 v4= map(p);
    res =opU3(res, vec3(v4.x,100.0,-1.0));
    res =opU3(res, vec3(planeDist1,13.0,-1.0));
    return res;
}

vec3 GetNormal(vec3 p)
{   float d = GetDist(p).x;
    vec2 e = vec2(.001, 0);
    vec3 n = d - vec3(GetDist(p-e.xyy).x,GetDist(p-e.yxy).x,GetDist(p-e.yyx).x);
    return normalize(n);
}

float RayMarch(vec3 ro, vec3 rd, int PMaxSteps)
{   float t = 0.; 
    vec3 dS=vec3(9999.0,-1.0,-1.0);
    float marchCount = 0.0;
    vec3 p;
    float minDist = 9999.0; 
    
    for(int i=0; i <= PMaxSteps; i++) 
    {  	p = ro + rd*t;
        dS = GetDist(p);
        t += dS.x;
        if ( abs(dS.x)<MIN_DIST  || i == PMaxSteps)
            {mObj.hitbln = true; minDist = abs(t); break;}
        if(t>MAX_DIST)
            {mObj.hitbln = false;    minDist = t;    break; } 
        marchCount++;
    }
    mObj.dist = minDist;
    mObj.id_color = dS.y;
    mObj.marchCount=marchCount;
    mObj.id_material=dS.z;
    mObj.normal=GetNormal(p);
    mObj.phit=p;
    return t;
}

float GetShadow(vec3 p, vec3 plig)
{   vec3 lightPos = plig;
    vec3 l = normalize(lightPos-p);
    vec3 n = GetNormal(p);
    float dif = clamp(dot(n, l), 0., 1.);
    float d = RayMarch(p+n*MIN_DIST*2., l , MAX_STEPS/2);
    if(d<length(lightPos-p)) dif *= .1;
    return dif;
}

float occlusion(vec3 pos, vec3 nor)
{   float sca = 2.0, occ = 0.0;
    for(int i = 0; i < 10; i++) {
        float hr = 0.01 + float(i) * 0.5 / 4.0;        
        float dd = GetDist(nor * hr + pos).x;
        occ += (hr - dd)*sca;
        sca *= 0.6;
    }
    return clamp( 1.0 - occ, 0.0, 1.0 );    
}

vec3 lightingv3(vec3 normal,vec3 p, vec3 lp, vec3 rd, vec3 ro,vec3 col, float t) 
{   vec3 lightPos=lp;
    vec3 hit = ro + rd * t;
    vec3 norm = GetNormal(hit);
    
    vec3 light = lightPos - hit;
    float lightDist = max(length(light), .001);
    float atten = 1. / (1.0 + lightDist * 0.125 + lightDist * lightDist * .05);
    light /= lightDist;
    
    float occ = occlusion(hit, norm);
    float dif = clamp(dot(norm, light), 0.0, 1.0);
    dif = pow(dif, 4.) * 2.;
    float spe = pow(max(dot(reflect(-light, norm), -rd), 0.), 8.);
    vec3 color = col*(dif+.35 +vec3(.35,.45,.5)*spe) + vec3(.7,.9,1)*spe*spe;
    color*=occ;
    return color;   
}
vec3 getColorTextura( vec3 p, vec3 nor,  int i)
{	if (i==100 )
    { vec3 col=tex3D(iChannel0, p/32., nor); return col*2.0; }
	if (i==101 ) { return tex3D(iChannel1, p/32., nor); }
	if (i==102 ) { return tex3D(iChannel2, p/32., nor); }
	if (i==103 ) { return tex3D(iChannel3, p/32., nor); }
}

vec3 Getluz(vec3 p, vec3 ro, vec3 rd, vec3 nor , vec3 colobj ,vec3 plight_pos, float tdist)
{  float intensity=1.0;
     vec3 result;
    result = lightingv3( nor, p, plight_pos,  rd,ro, colobj, tdist);
    return result;
}

vec3 render_sky_color(vec3 rd)
{   float t = (rd.x + 1.0) / 2.0;
    vec3 col= vec3((1.0 - t) + t * 0.3, (1.0 - t) + t * 0.5, (1.0 - t) + t);
    vec3  sky = mix(vec3(.0, .1, .4)*col, vec3(.3, .6, .8), 1.0 - rd.y);
	return sky;
}

vec3 GetColorYMaterial(vec3 p,  vec3 n, vec3 ro,  vec3 rd, int id_color, float id_material)
{  	vec3 colobj; 
    if( mObj.hitbln==false) return  render_sky_color(rd);
    if (id_color<100)
		{ colobj=getColor(int( id_color)); }
    if ( float( id_color)>=100.0  && float( id_color)<=199.0 ) 
 	{  vec3 coltex=getColorTextura(p, n, int( id_color)); colobj=coltex;}
    return colobj;
}

vec3 linear2srgb(vec3 c) 
{   return mix(
        12.92 * c,1.055 * pow(c, vec3(1.0/1.8)) - 0.055,
        step(vec3(0.0031308), c));
}

vec3 exposureToneMapping(float exposure, vec3 hdrColor) 
{    return vec3(1.0) - exp(-hdrColor * exposure);  }

vec3 ACESFilm(vec3 x)
{
    float a = 2.51; float b = 0.03;
    float c = 2.43; float d = 0.59; float e = 0.14;
    return (x*(a*x+b))/(x*(c*x+d)+e);
}

vec3 Render(vec3 ro, vec3 rd)
{  vec3 col = vec3(0);
   TObj Obj;
   mObj.rd=rd;
   mObj.ro=ro;
   vec3 p;

     float d=RayMarch(ro,rd, MAX_STEPS);
   
    Obj=mObj;
    if(mObj.hitbln) 
    {   p = (ro + rd * d );  
        vec3 nor=mObj.normal;
        vec3 colobj;
        colobj=GetColorYMaterial( p, nor, ro, rd,  int( Obj.id_color), Obj.id_material);

        float dif1=1.0;
        vec3 result;
        result=  Getluz( p,ro,rd, nor, colobj ,light_pos1,d)*light_color1;
        result+= Getluz( p,ro,rd, nor, colobj ,light_pos2,d)*light_color2;
   
        col= result;
        col= (ACESFilm(col)+linear2srgb(col)+col+ exposureToneMapping(3.0, col))/4.0 ;
    }
    else if(d>MAX_DIST)
    col= render_sky_color(rd);
   return col;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{  vec2 uv = (fragCoord-.5*iResolution.xy)/iResolution.y;
   mObj.uv=uv;
    float t;
    t=mod(iTime*0.5,360.0);
    itime=t;
	//mObj.blnShadow=false;
    mObj.blnShadow=true;    
 	 light_pos1= vec3(-10.0, 20.0, -10.0 ); light_color1=vec3( 1.0,1.0,1.0 );
 	light_pos2= vec3(10.0, 10.0, 10.0 ); light_color2 =vec3( 1.0,1.0,1.0 ); 
    
   vec3 ro=vec3(0.0,4.,0.0+t);
   vec3 rd=normalize( vec3(uv.x,uv.y,1.0));      
    light_pos1+=ro;
    light_pos2+=ro;
    vec3 col= Render( ro,  rd);
    
    fragColor = vec4(col,1.0);
}


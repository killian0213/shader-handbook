// Buffer A (buffer) — Alcatraz - Equilibrium by Virgill
// https://www.shadertoy.com/view/ls2BRG

// **************************************************************************
// Alcatraz - Equilibrium - 4K intro 
// by Jochen "Virgill" Feldkötter (jochen.feldkoetter{a}outlook.de)
//
// 4kb executable: 	http://www.pouet.net/prod.php?which=71136
// Youtube: 		https://www.youtube.com/watch?v=T6ulp8b8eHw
// Soundtrack:		https://soundcloud.com/virgill/virgill-4klang-equilibrium
// **************************************************************************


int scene_idx =0;		// scene  0      1     2     3       4     5        6     7      8     9         10    11   12   13      14
float scenes_x[15] = float[15] (-0.35,  5.9, -3.2, -1.0 ,  8.0,   0.0,    -1.2, -0.3,  -1.3,  -0.4,     -4.2,  0.0, 1.8, 0.0,     2. );
float scenes_y[15] = float[15] (-0.61,  0.7, -3.0,  0.1,   2.6,   4.5,    -0.5, -3.0,  -0.5,   0.1,      2.5,  3.0, 1.0, 3.0,    -3. );
float duration = 15.; 
float time=0.;

// cubemap (IQ)
vec4 boxmap(sampler2D sam,vec3 p,vec3 n)
{
    vec3 m = pow(abs(n), vec3(32.) );
	vec4 x = texture( sam, p.yz );
	vec4 y = texture( sam, p.zx );
	vec4 z = texture( sam, p.xy );
	return (x*m.x + y*m.y + z*m.z)/(m.x+m.y+m.z);
}

// noise
float rnd(vec2 co)
{
    return fract(sin(dot(co.xy ,vec2(12.98,78.23))) * 43758.54);
}

// signed box
float sdBox(vec3 p,vec3 b)
{
  vec3 d = abs(p)-b;
  return min(max(d.x,max(d.y,d.z)),0.)+length(max(d,0.));
}

// rotation
void pR(inout vec2 p,float a) 
{
	p = cos(a)*p+sin(a)*vec2(p.y,-p.x);
}

// 3D noise function (shane)
float noise(vec3 p)
{
	vec3 ip = floor(p);
    p -= ip; 
    vec3 s = vec3(7,157,113);
    vec4 h = vec4(0.,s.yz,s.y+s.z)+dot(ip,s);
    p = p*p*(3.-2.*p); 
    h = mix(fract(sin(h)*43758.5),fract(sin(h+s.x)*43758.5),p.x);
    h.xy = mix(h.xz,h.yw,p.y);
    return mix(h.x,h.y,p.z); 
}

float map(vec3 p)
{	
	if (scene_idx>9&&scene_idx<14) 
    {
		float a = sdBox(p,vec3(1.2,1.5,2.))-0.1;
    	pR(p.yz,0.2*time);
    	return max(a,-sdBox(p,vec3(0.9,0.5,.1))+0.04);
    }
    float displace = 0.001*noise(15.*p+time); 
    if (scene_idx == 8 || scene_idx == 9) displace = 0.005*noise(10.*p+time)+0.005*sin(10.*p.x+3.*time)+0.002*sin(14.*p.y+4.*time); //!!!!!!!!!!!!!!!
    if (scene_idx < 4 || (scene_idx > 5 && scene_idx < 10)) return sdBox(p,vec3(1.,1.,1.))-0.4+displace; // box ///////////// vec3 1.1.1
    return length(p)-2.0+0.5*noise(1.5*p-0.02*time);     
}

// normal calculation
vec3 calcNormal(vec3 pos)
{
    float eps = 0.0001;
	float d = map(pos);
	return normalize(vec3(map(pos+vec3(eps,0,0))-d,map(pos+vec3(0,eps,0))-d,map(pos+vec3(0,0,eps))-d));
}


// sphere tracing inside
float castRayx(vec3 ro,vec3 rd) 
{
    float precis = .0001;
    float h = precis*2.;
    float t = 0.;
	for(int i=0;i<100;i++) 
	{
        if(abs(h)<precis||t>12.)break;
		h = -map(ro+rd*t); 
        t += h;
	}
    return t;
}

// refraction
float refr(vec3 pos,vec3 lig,vec3 dir,vec3 nor,float angle,out float t2, out vec3 nor2)
{
    float h = 0.;
    t2 = 2.;
	vec3 dir2 = refract(dir,nor,angle);  
 	for(int i=0;i<50;i++) 
	{
		if(abs(h)>3.) break;
		h = map(pos+dir2*t2);
		t2 -= h;
	}
    nor2 = calcNormal(pos+dir2*t2);
    return(.5*clamp(dot(-lig,nor2),0.,1.)+pow(max(dot(reflect(dir2,nor2),lig),0.),8.));
}

// softshadow 
float softshadow(vec3 ro,vec3 rd) 
{
    float sh = 1.;
    float t = .02;
    float h = .0;
    for(int i=0;i<12;i++)  
	{
        if(t>20.)continue;
        h = map(ro+rd*t);
        sh = min(sh,4.*h/t);
        t += h;
    }
    return sh;
}

// *********************************************************************************************************

// main function
void mainImage(out vec4 fragColor,in vec2 fragCoord)
{    
 
// time handling    
	time=iTime*1.;
	if (iTime>150.&&iTime<=165.) time=(iTime-150.)*4.+150.;
	if (iTime>165.) time=iTime+60.;
// scene handling   
    scene_idx = int(floor(time/duration));
    vec2 scene=vec2(scenes_x[scene_idx],scenes_y[scene_idx]); 
    
// camera    
    vec3 dir = normalize(vec3(2.*gl_FragCoord.xy -iResolution.xy, iResolution.y)),org = vec3(0,0,1.);  
    if (scene_idx==10||scene_idx==12||scene_idx>=14) dir+=0.01*rnd(vec2(time,time)); //stutter

    
// try this :P
   //scene = iMouse.yx*0.02;

    pR(dir.zy,scene.x+.8*sin(.02*time));
    pR(dir.xz,scene.y+.8*cos(.05*time-1.));
    
// standard sphere tracing inside an object
    vec3 color,color2 =  vec3(0.);
    float t = castRayx(org,dir);
	vec3 pos = org+dir*t;
	vec3 nor = calcNormal(pos);

// lighting:
    vec3 lig = normalize(vec3(-.2,-6.,.5));

// scene depth    
    float depth = clamp((1.-0.09*t),0.,1.);
     
    vec3 pos2,nor2 = vec3(0.);
    	color2 = vec3(max(dot(lig,nor),0.)  +  pow(max(dot(reflect(dir,nor),lig),0.),16.))*clamp(softshadow(pos,lig),0.,1.);
    	float t2;
		color2.b += refr(pos,lig,dir,nor,0.92, t2, nor2)*depth;
    	color2.g += refr(pos,lig,dir,nor,0.90, t2, nor2)*depth;
    	color2.r += refr(pos,lig,dir,nor,0.88, t2, nor2)*depth;
  		color2 -= clamp(.1*t2,0.,1.);		
	    
// texture
        color2 += 0.7*boxmap(iChannel0,0.25*pos+0.5,nor).xyz; 
        color2 *= depth; 
  
// glow intensity    
    float tmp = 0., T = 1.;
    float intensity = 0.1*-sin(.5*time)-0.05; 
	for(int i=0; i<32; i++)
	{
        float nebula = noise(org);
        float density = intensity-map(org+.5*nor2)*nebula;
		if(density>0.)
		{
			tmp = density / 128.;
            T *= 1. -tmp * 100.;
		}
		org += dir*0.078;
    }    
	vec3 basecol = vec3(1.,.35,1./16.);	
  
    T = clamp(T,0.,1.5); 
    color += basecol* exp(4.*(0.5-T) - 0.8);
    color -= vec3(1.1,.015,.06);
  

    vec3 object = vec3(0.1*color+0.8*color2)*1.3;    
    
    vec2 uv = 0.5-fragCoord.xy/iResolution.xy ; 

    // feedbak noise  
    uv*=0.996;
  	uv=0.5-uv; 
   	uv.x-=0.005*noise(uv.yxx*32.-time)-0.0025;
   	uv.y+=0.005*noise(uv.yxx*32.+time)-0.0025; 
  
    vec3 bufa= texture(iChannel0,uv).xyz;

    float saw = mod(time/duration,1.);
    float powsaw = pow(saw,32.); 					
 	float fade0 =  clamp(mod(1.*time,1.*duration),0.,1.); 	// fade in
    float fade1 =  exp(32.* -powsaw)*fade0; 				// fade out      
    float parabola = 0.75;
    if (scene_idx == 1 || (scene_idx >= 4 && scene_idx<=7) || scene_idx>=9) parabola = 0.8-pow(4.*saw*(1.-saw),2.)*0.6;
    if (scene_idx >13)  parabola=clamp(saw+0.3,0.,0.99);
       
    
 // noise   
	object += 0.25*(0.5-rnd(uv.xy*time))*parabola;			//noise  
    if (scene_idx>3) object -= 0.04*rnd(vec2(time,time));   //flutter    
    
    if (iTime>180.) {object = vec3(0); bufa=vec3(0);}

    fragColor = clamp(vec4(mix(object,bufa,parabola)*fade1,0.),0.,1.0);   

 
    
    

}





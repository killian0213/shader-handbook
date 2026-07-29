// Common (common) — GCLH [Commented] by Yusef28
// https://www.shadertoy.com/view/Mt33W2

//OldVersion

/*
#define SCALE 1.

float rnd(vec2 p)
{
 //return fract(sin(dot(p, vec2(13.234, 72.1849))*43251.1234));   
 return fract(sin(dot(p, vec2(13.234, 72.1849)))*43251.1234);    
}

//
vec3 stripes(vec3 p)
{
    vec3 color;
    
  //makes a chess pattern
    float zTo2 = fract(p.x/2.)*2.;
    float negOTo1 = 1.0-fract(p.x);
   float  oTo1 = fract(p.x);
    float bw = floor( fract(p.z)*2.);
    	
    float s = abs(((zTo2 + negOTo1) - bw ) -1.);
    
    //this was a weird experimental thing

    //float s2 = smoothstep(0.45, 0.5, p.x);
    color = vec3(s);
 return color;
    
}


//not really used.
float plane(vec3 p, vec4 n)
{
    
 return dot(p, n.xyz) + n.w;   
}

float roundBox(vec3 p, vec3 b, float r)
{
    
 return length(max(abs(p)-b,0.0))-r;   
}

mat2 rot(float a)
{
 float cs = cos(a);
    float si = sin(a);
    
    return mat2(cs, -si, si, cs);
}


//makes the dna strands
float helix(vec3 p )
{
    vec2 id = floor(p.xz/20.-10.);
    float idr = fract(sin(dot(floor(p.xz/20.-10.), vec2(12.23432, 73.24234)))*412343.2);
     //p.xy*=rot(1./sin(idr));
    //p.xz*=rot(.01);
     
    vec3 oldp = p;
    float iz =floor(p.z);
 	float ix =floor(p.x);
   
//if(iz > 0. && iz < 20.)
    p.xz = mod(p.xz, 20.) -10.;
    
   // p.xy+=idr;
   p.xz*=rot(p.y*3.14159/7.);
   	
	//p.xy*=rot(0.3);
    
    float cyl1 = length(p.xz + vec2(1.0,0.0)) - 0.2 ;
    float cyl2 = length(p.xz - vec2(1.0, 0.0)) - 0.2 ;;
    
     p.y = mod(p.y,.4)-.2;
    float bar = max(length(p.yz) - 0.07, abs(p.x) - .9) ;
    
	
	float dna =  min(min(cyl1, bar), cyl2);

    
    return dna;
}
    
//Map function is pretty simple I do a mod of rounded boxes on xz plane to make tiles
//and add dna strands, and then return. I commented out some other experiments
float map(vec3 p)
{
    
 float plane = plane(p, vec4(0.0, 1., 0.0, .9  ));//+stripes(p)/20.));
    
    
    //these are options to deform the plane.
   // p.y+=sin(p.x+sin(p.z))/5.+sin(p.z/2.+sin(p.z/9.)*10.)/20.;//+sin(p.z/3.)/4.;
   // p.y+=(floor(abs(p.x))/1.);

    
    //I use a scale factor so I can change the size of the tiling with one variable defined at top.
    float sca = SCALE;
    
    //this line does something interesting
   //p.x += +sin(iTime*floor(p.y)/10.)*8.;
    
    //this line not so much
   //p.y += +sin(iTime*floor(p.x)/100.)*8.;
    
    //height variable not used because changing the heights of blocks based on floor doesn't work out.
    //it creates really bad aliasing and I'm not sure why just yet.
    float height = sin(iTime*floor(p.x))*1.;
    
    
	 vec3 fp;

    fp.xyz = mod(p.xyz, 1./sca)-0.5/sca;
  

  //another option for height variation, also not used.
  height = ((rnd(floor( p.xz/8.)))  )/10.;
    
    
 //creates the boxes
 float tiles = roundBox(vec3(fp.x, p.y, fp.z), 
                       vec3(0.47/sca, 0.47/sca, 0.47/sca), 0.019/sca);
    
 //creates the dna
 float dna = helix(p);


                        //vec3(0.43, 0.028+sin(p.z*0.3)/40.-cos(p.x*1.7)/60., 0.43), 0.0157);
 
    
//more not used stuff

    
  return min(tiles,dna); 
      
}

float trace(vec3 ro, vec3 rd)
{
    float eps = 0.0001;
    float dist;
   	float t = 0.0;
    
    for(int i=0; i<96; i++)
    {
     dist = map(ro + rd*t);
        if(dist<eps || t > 120.)
            break;
        
      t += dist*0.75;
        
    }
    
    
 return t;   
}

//based on shanes reflection tutorial
float rtrace(vec3 ro, vec3 rd)
{
    float eps = 0.0001;
    float dist;
   	float t = 0.0;
    
    for(int i=0; i<48; i++)
    {
     dist = map(ro + rd*t);
        if(dist<eps || t > 120.)
            break;
        
      t += dist;
        
    }
    
    
 return t;   
}

//can find explaination in my earlier shaders
vec3 normal(vec3 sp)
{
    vec3 eps = vec3(.0001, 0.0, 0.0);
    
    vec3 normal = normalize (vec3( map(sp+eps) - map(sp-eps)
                       ,map(sp+eps.yxz) - map(sp-eps.yxz)
                       ,map(sp+eps.yzx) - map(sp-eps.yzx) ));
    
    
 return normal;   
}

//guess who this is from...shane
// "I keep a collection of occlusion routines... OK, that sounded really nerdy. :)
// Anyway, I like this one. I'm assuming it's based on IQ's original."
float calculateAO(in vec3 pos, in vec3 nor)
{
	float sca = 2.0, occ = 0.0;
    for( int i=0; i<5; i++ ){
    
        float hr = 0.01 + float(i)*0.5/4.0;        
        float dd = map(nor * hr + pos);
        occ += (hr - dd)*sca;
        sca *= 0.7;
    }
    return clamp( 1.0 - occ, 0.0, 1.0 );    
}

//based on shanes lighting function but i added reflections using a cubemap
vec3 lighting(vec3 sp, vec3 sn, vec3 lp, vec3 rd)
{
vec3 color;
    
    //some other experiemnts
    //where the id's are based on cells you don't need to pass the id variable around
    //you can just recreate it where needed.

    
    //vec3 tex = texture(iChannel0, sp.xz).xyz*one;
    vec3 lv = lp - sp;
    float ldist = max(length(lv), 0.001);
    vec3 ldir = lv/ldist;
    
    float atte = 1.0/(1.0 + 0.002*ldist*ldist );
    
    float diff = dot(ldir, sn);
    float spec = pow(max(dot(reflect(-ldir, sn), -rd), 0.0), 10.);
    float fres = pow(max(dot(rd, sn) + 1., 0.0), 1.);
	float ao = calculateAO(sp, sn);
    
    vec3 refl = reflect(rd, sn);
    vec3 refr = refract(rd, sn, 0.7);
    
    
    vec3 str = stripes(sp);
    vec3 chessFail = vec3(floor(mod(sp.z, 2.))+floor(mod(sp.x, 2.)));
    float rndTile = rnd(floor(sp.xz*SCALE ));//+ iTime/10.);
    
    
    //color options
    vec3 color1 = vec3(rndTile*2., rndTile*rndTile, 0.1);
    vec3 color2 =vec3(rndTile*rndTile, .0, rndTile/90.);
    vec3 color3 =mix(vec3(0.9, 0., 0.), vec3(1.4), 1.0-floor(rndTile*2.));
    
    //getting reflected and refracted color froma cubemap, only refl is used
    vec4 reflColor = texture(iChannel1, refl);
    vec4 refrColor = texture(iChannel2, refr);
     
    //blue vs orage specular, orange all the way.
    vec3 coolSpec = vec3(.3, 0.5, 0.9);
    vec3 hotSpec = vec3(0.9,0.5, 0.2);
   
    
    //apply color options and add refl/refr options
    color = (diff*color2 +  spec*hotSpec +reflColor.xyz*0.2 )*atte;
	
    
    //apply ambient occlusion and return.
 return color*ao;   
}
mat2 rot2( float a ){ vec2 v = sin(vec2(1.570796, 0) - a);	return mat2(v, -v.y, v.x); }

//path from shane's abstract plane shader
vec2 path(in float z){ float s = sin(z/36.)*cos(z/18.); return vec2(s*16., 0.); }


void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
	vec2 uv = fragCoord.xy / iResolution.xy;
    
    uv=uv*2.0-1.0;
    
    uv.x*=iResolution.x/iResolution.y;
    
    ///this way doesn't work for some reason..////////////////////
    //it causes weird alliasing and doesn't look good.
    vec3 ro = vec3(0.0, 4.0, -1.0+iTime*2.0); //*(sin(iTime)*0.5+0.5)
    vec3 rd = vec3(uv.x, uv.y, 2.7);//*(sin(iTime)*0.5+0.5)
    
    vec3 lp =  ro + vec3(0., 1.2, 2.5);
    
    //////////////////////SO I USE THIS////////////////////////////////////////////////////////////
    //which is from shanes abstract plane shader so it uses a pathand FOV and the basic camera 
    //variables fwd, up, and right. Shanes comments.
    uv = (fragCoord - iResolution.xy*.5)/iResolution.y;
    
    //fisheye - Update 2021 06 17
	uv = normalize(uv) * tan(asin(length(uv) * 1.));
	// Camera Setup.
	vec3 lk = vec3(0, 3.5, iTime*6.);  // "Look At" position.
	 ro = lk + vec3(0, .25, -.25); // Camera position, doubling as the ray origin.
 
    // Light positioning. One is just in front of the camera, and the other is in front of that.
 	 lp = ro + vec3(0, 3.75, 10);// Put it a bit in front of the camera.
	
	// Sending the camera, "look at," and two light vectors across the plain. The "path" function is 
	// synchronized with the distance function.
	lk.xy += path(lk.z);
	ro.xy += path(ro.z);
	lp.xy += path(lp.z);

    	lk.y+=0.2;
    // Using the above to produce the unit ray-direction vector.
    float FOV = 1.57; // FOV - Field of view.
    vec3 fwd = normalize(lk-ro);
    vec3 rgt = normalize(vec3(fwd.z, 0., -fwd.x )); 
    // "right" and "forward" are perpendicular, due to the dot product being zero. Therefore, I'm 
    // assuming no normalizaztion is necessary? The only reason I ask is that lots of people do 
    // normalize, so perhaps I'm overlooking something?
    vec3 up = cross(fwd, rgt); 

    // rd - Ray direction.
    rd = normalize(fwd + FOV*uv.x*rgt + FOV*uv.y*up);
    
    // Swiveling the camera about the XY-plane (from left to right) when turning corners.
    // Naturally, it's synchronized with the path in some kind of way.
	rd.xy *= rot2( path(lk.z).x/64. );


    /////////////////////////////////////////////////////////
    
    float t = trace(ro, rd);
    vec3 sp = ro + rd*t;
    vec3 sn = normal(sp);
   	
    float far = smoothstep(0.0, 1.0, t/120.);
    
    //get cube color from cubemap again this time to apply to the sky,
    //really just so that the reflections on the ground make sense
    
    vec4 cubeColor = texture(iChannel1, rd);
    vec3 color = lighting(sp, sn, lp, rd);//mix(stripes(ro+rd*t),vec3(t), far);
    
    //reflection trace based on shanes reflection tutorial
    vec3 refRay = reflect(rd, sn);
    float rt = rtrace(sp+sn*0.01, refRay);
    vec3 rsp = (sp+refRay*0.01) + refRay*rt;
    vec3 rsn = normal(rsp);
     color += lighting(rsp, rsn, lp, refRay)*0.3;
    
    //here i did this weird thing that resulted in an arc shape and I just kept it.
    vec3 sky = mix(vec3(0.9, 0.5, 0.2)*4., vec3(0.0)-0.4, pow(abs(rd.y), 1./3.))*(1./pow(abs(length(rd.xy)-0.4), 1./3.))/8.;//-sin(atan(rd.y, rd.x)*20.+iTime*8.)/200., 1./5.));
   // sky += (pow(length(rd.xy)-0.3+sin(atan(rd.y, rd.x)*20.+iTime*8.)/200., 1./3.));;//*vec3(0.1, 0.5, 0.9);
   
    float c = 1.0-smoothstep(0.1, 0.15,length(rd.xy)-0.01);
    
    
    sky += cubeColor.xyz*0.1;// + c*vec3(0.2, 0.5, 0.9);
    color = mix(color, sky, far);
    
    float vignette = 1.0-smoothstep(1.0,3.5, length(uv));
    color.xyz *= mix( 0.8, 1.0, vignette);
    
    
	fragColor = vec4(color,1.0);
}
*/
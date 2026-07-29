// Image (image) — GCLH [Commented] by Yusef28
// https://www.shadertoy.com/view/Mt33W2


//take in vec2 return random float 0 - 1
float rnd(vec2 p)
{
    vec2 seed = vec2(13.234, 72.1849);
    return fract(sin(dot(p,seed))*43251.1234);    
}

//rounded box from iq
float roundBox(vec3 p, vec3 b, float r)
{
    return length(max(abs(p)-b,0.0))-r;   
}

//rotation matrix (clockwise)
mat2 rot(float a)
{
     float c = cos(a),s = sin(a);
     return mat2(c, -s, s, c);
}


/*
//makes the dna strands
vec2 helix(vec3 p )
{
    //repeat space on xz
    p.xz = mod(p.xz, 20.) -10.;
    //rotate each cell based on y for helix shape
    p.xz*=rot(p.y*3.14159/7.);
    
    //create two cylinders which will be twisted
    vec2 t = vec2(length(p.xz + vec2(1.0,0.0)) - 0.2, 1.);
    t.x = min(t.x,length(p.xz - vec2(1.0, 0.0)) - 0.2);
    
    vec2 h = vec2(length(p.xz + vec2(1.3,0.0)) - 0.1, 2.);
    h.x = min(h.x,length(p.xz - vec2(1.3, 0.0)) - 0.1);
    
    t.y = t.x < h.x ? t.y : h.y; t.x = min(t.x,h.x);
    //mod space on y for bars
    p.y = mod(p.y,.4)-.2;
    //create y repeated cylinders cut at abs(p.x etc)
    h = vec2(max(length(p.yz) - 0.07, abs(p.x) - .9), 3.) ;
    t.y = t.x < h.x ? t.y : h.y;  t.x = min(t.x,h.x);
    //return helix (union of cylinders and bars)
	return t;
}
*/
//makes the dna strands
float helix(vec3 p )
{
    //repeat space on xz
    p.xz = mod(p.xz, 20.) -10.;
    //rotate each cell based on y for helix shape
    p.xz*=rot(p.y*3.14159/7.);
    //create two cylinders which will be twisted
    float cyl1 = length(p.xz + vec2(1.0,0.0)) - 0.2 ;
    float cyl2 = length(p.xz - vec2(1.0, 0.0)) - 0.2 ;;
    //mod space on y for bars
    p.y = mod(p.y,.4)-.2;
    //create y repeated cylinders cut at abs(p.x etc)
    float bar = max(length(p.yz) - 0.07, abs(p.x) - .9) ;
    //return helix (union of cylinders and bars)
	return min(min(cyl1, bar), cyl2);
}

float tile(vec3 p){
     //repeat xz 
     p.xz = mod(p.xz, 1.)-0.5;
     //create rounded boxes for tiles and return
     return roundBox(p,vec3(0.47), 0.019);
}

//map function
float map(vec3 p)
{
 //the union of tiles and dna
     return min(tile(p),helix(p));    
}

//basic raymarch
float trace(vec3 ro, vec3 rd)
{
   	float t = 0.0,dist;
    for(int i=0; i<96; i++)
    {
     dist = map(ro + rd*t);
     if(dist<0.0001 || t > 120.){break;}
     t += dist*0.75;
    }
 return t;   
}

//reflection trace (see shanes reflection shader)
float rtrace(vec3 ro, vec3 rd)
{
   	float t = 0.0,dist;
    for(int i=0; i<48; i++)
    {
     dist = map(ro + rd*t);
     if(dist<0.0001 || t > 120.){break;}
     t += dist;
    }
 return t;   
}

//basic normal calculation 
vec3 normal(vec3 sp)
{
    //we swizzel a vec2 epsilon to get vec3
    vec2 e = vec2(.0001, 0.0);
    return normalize (
    vec3(map(sp+e.xyy) - map(sp-e.xyy),
         map(sp+e.yxy) - map(sp-e.yxy),
         map(sp+e.yyx) - map(sp-e.yyx))
    );
}

//ao from shane
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

//based on shanes lighting function
vec3 lighting(vec3 sp, vec3 sn, vec3 lp, vec3 rd)
{
    vec3 color;
    //vector from hit position to light position
    vec3 lv = lp - sp;
    //length of that vector
    float ldist = max(length(lv), 0.001);
    //direction of that vector
    vec3 ldir = lv/ldist;
    //attenuation
    float atte = 1.0/(1.0 + 0.002*ldist*ldist );
    //diffuse color
    float diff = dot(ldir, sn);
    //specular reflection
    float spec = pow(max(dot(reflect(-ldir, sn), -rd), 0.0), 10.);
    //fresnel
    float fres = pow(max(dot(rd, sn) + 1., 0.0), 1.);
	//ambient occlusion
    float ao = calculateAO(sp, sn);
    //reflecton
    vec3 refl = reflect(rd, sn);
    //id for random tile color
    float rndTile = rnd(floor(sp.xz));
    //color options
    vec3 color2 =vec3(rndTile*rndTile, .0, rndTile/90.);
    //getting reflected and refracted color froma cubemap, only refl is used
    vec4 reflColor = texture(iChannel0, refl);
    //orage specular
    vec3 hotSpec = vec3(0.9,0.5, 0.2);
    //apply color options and add refl/refr options
    color = (diff*color2 +  spec*hotSpec +reflColor.xyz*0.2 )*atte;
    //apply ambient occlusion and return.
    return color*ao;   
}

//rotation matrix
mat2 rot2( float a ){ vec2 v = sin(vec2(1.570796, 0) - a);	return mat2(v, -v.y, v.x); }

//path from shane's abstract plane shader
vec2 path(in float z){ float s = sin(z/36.)*cos(z/18.); return vec2(s*16., 0.); }


void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
	vec2 uv = (fragCoord - iResolution.xy*.5)/iResolution.y;
    
    //fisheye
	uv = normalize(uv) * tan(asin(length(uv) * 1.));
    
	// Camera Setup.
	vec3 lk = vec3(0, 3.7, iTime*6.);  
    lk.xy += path(lk.z);
	vec3 ro = lk + vec3(0, .05, -.25); 
 	vec3 lp = ro + vec3(0, 3.75, 10);
    
    
    //camera
    float FOV = 1.57;
    vec3 fwd = normalize(lk-ro);
    vec3 rgt = normalize(vec3(fwd.z, 0., -fwd.x )); 
    vec3 up = cross(fwd, rgt); 
    vec3 rd = normalize(fwd + FOV*uv.x*rgt + FOV*uv.y*up);    
	rd.xy *= rot( path(lk.z).x/64. );

    
    //distance to closest hit
    float t = trace(ro, rd);
    //normalized distance
    float far = smoothstep(0.0, 1.0, t/120.);
    //hit point
    vec3 sp = ro + rd*t;
    //normal
    vec3 sn = normal(sp);
    
    vec4 cubeColor = texture(iChannel0, rd);
    //lighting
    vec3 color = lighting(sp, sn, lp, rd);
    //reflection based on shanes reflection shader
    vec3 refRay = reflect(rd, sn);
    
    //trace reflection
    float rt = rtrace(sp+sn*0.01, refRay);
    //relection hit point
    vec3 rsp = (sp+refRay*0.01) + refRay*rt;
    //reflection surfact normal
    vec3 rsn = normal(rsp);
    //add reflection lighting
    color += lighting(rsp, rsn, lp, refRay)*0.3;
    
    //accidental solar halo
    vec3 sky = mix(vec3(0.9, 0.5, 0.2)*4., vec3(0.0)-0.4, pow(abs(rd.y), 1./3.))*(1./pow(abs(length(rd.xy)-0.4), 1./3.))/8.;
    
    //add cube color
    sky += cubeColor.xyz*0.1;
    color = mix(color, sky, far);
    
    //naive vignette
    float vig = 1.0-smoothstep(1.0,3.5, length(uv));
    color.xyz *= mix( 0.8, 1.0, vig);

	fragColor = vec4(color,1.0);
}
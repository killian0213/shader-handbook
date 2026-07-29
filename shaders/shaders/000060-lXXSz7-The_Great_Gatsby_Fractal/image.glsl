// Image (image) — The Great Gatsby Fractal by Yusef28
// https://www.shadertoy.com/view/lXXSz7

/*
Development Modes
--------------------------
1. Object Before Fractal
2. Fractal Fly Through     
3. Mouse Adjust Fractal_P


0.55,0.

vec2[] Camera_Positions = vec2[](
    vec2(0.40, 0.74),
    vec2(0.40, .76),
    vec2(0.40, 0.74),
    vec2(0.46, 0.73),
    vec2(0.60, 0.94),
    vec2(0.64, 0.77),
    vec2(0.59, 0.95),
    vec2(0.53, 0.89),
    vec2(0.56, 0.94)
);
*/

#define FAR 50.
#define DEV_MODE 2.
/*vec2[] Camera_Positions = vec2[](
vec2(0.55, 0.75),
vec2(0.63, 0.79),
vec2(0.72, 0.95),
vec2(0.72, 0.95),//vec2(0.45, 0.75),
vec2(0.39, 0.74),
vec2(0.40, 0.72),
vec2(0.41, 0.74)
); */
vec2[] Camera_Positions = vec2[](
    vec2(0.40, 0.74),
    vec2(0.46, 0.73),
    vec2(0.60, 0.94),
    vec2(0.64, 0.77),
    vec2(0.59, 0.95),
    vec2(0.53, 0.89),
    vec2(0.56, 0.94)
);
struct Object 
{ 
    float rough; 
    vec3 color; 
}; 

Object[] Materials = Object[](
    //base material
    Object(0.6, vec3(0.1,0.55,0.9)),
    //low reflection material
    Object(0.95, vec3(0.9,0.5,0.)),   
    //no reflection material
    Object(0.0, vec3(0.,0.05,0.9)),
    //bumped texture material
    Object(0.95, vec3(0.9,0.5,0.)),
   
    //cylinders / rings
    Object(0., vec3(.0, 0.7, 0.7))

);


vec3 DEV_POSITION = vec3(0.,1.,-5.);
float glow = 0.;
vec3 path(float z){ 
    vec3 ro;
    
    if(DEV_MODE == 1.){
        ro = DEV_POSITION;
    }
    
    else if(DEV_MODE > 1.){
        ro = vec3(0., 1., iTime*2.);//+vec3(60., -10., 0);
    }
    
    return ro;
}
float surface1(vec3 p){
    return 0.1*(abs(fract(p.z*4.)-0.5)+abs(fract(p.x*4.)-0.5)),4.5;
     
}
vec2 tile(vec3 p){
    if(DEV_MODE == 1.){
        if(iMouse.z < 0.5){
            p.zx *= rot(iTime);
        }
     }
     vec3 op = p;
     //p.xy *= rot(3.);
     
     vec3 pp = p;;
     /*
     pp.x = max(abs(pp.x)-1.,0.);
     vec2 t = vec2(sdTorus(pp, vec2(1.7,0.4)),1.);
     t.x = smax(t.x, -rb(p, vec3(3.,0.01,3.), 0.03),0.4);
     vec2 h = vec2(sdTorus(pp, vec2(1.7,0.25)),3.);
     addH;
     h = vec2(sdTorus(pp, vec2(1.7,0.35)),2.);
     h.x = smax(h.x, -rb(p, vec3(1.,2.,3.), 0.03),0.05);
     addH;*/
     pp = p;
     pp.x = mod(pp.x,.2)-0.1;
     vec2 t = vec2(length(pp.xy)-0.05, 1.);
     t = vec2(max(abs(pp.x)-0.04,abs(pp.y)-0.03)-0.01,1.);//-vec2(0.1,0.02),1.);
    // t.x = smax(t.x, sdTorus(p, vec2(0.8, 2.)),0.2); 
     //addH;
     
     
     p = op;
     //p.x-=sin(p.z);
     //boxes
     float w = 3.;//+iMouse.y/iResolution.y;
     float l = 1.;
     pp = p;
     pp.x = abs(pp.x)-w;
    vec2 h = vec2(rb(pp,vec3(0.1,1.,2.),0.04), 4.);
     addH;
     
     //top gold
     pp = p;
     pp.x = abs(pp.x)-w;
     pp.y = abs(pp.y)-1.;
     h = vec2(rb(pp,vec3(0.2,0.2,2.),0.04), 3.);
     addH;
     
     //side gold
     pp = p;
     pp.x = abs(pp.x)-w;
     pp.z = abs(pp.z)-2.;
     h = vec2(rb(pp,vec3(0.2,1.2,0.1),0.04), 3.);
     addH;
     return t;
}
vec3 fractal_position(vec3 p){
    
    float mx = 0.65;//iMouse.x/iResolution.x;
    float my = 0.8;//iMouse.y/iResolution.y;
    
    //0.72, 0.98
    //0.38, 0.73
    //0.57, 0.89
    //.60,0.83
    //0.68, 0.77
    vec2 t = vec2(iTime*0.4,iTime*0.4
   +1.);
    vec2 tt = (mod(floor(t), 7.));
    vec2 mm = mix(Camera_Positions[int(tt.x)],
                   Camera_Positions[int(tt.y)],
                   smoothstep(0.7,1.,fract(t.x)));
    //vec2 mm = Camera_Positions[0];
    
    if(DEV_MODE == 3.){
        mm = iMouse.xy/iResolution.xy;
    }
    
    if(DEV_MODE > 1.){
        
        p.xz = mod(p.xz,40.)-20.;
        for(int i=0;i<6;i++){//3,4 or 5 are all good bros
            p.xz*=rot(mm.x*float(i));
            p.xy*=rot(mm.y*float(i));
            //p=abs(p)-vec3(4.9,5.,5.);
            //p=abs(p)-vec3(4.8,5.,5.5);
            p=abs(p)-vec3(2.6,5.2,5.1);//this idk
            p=abs(p)-vec3(4.8,5.,5.5);

        }
    }
    return p;
}
vec2 map(vec3 p){
    vec3 op = p;
    p = fractal_position(p);
    vec2 t = vec2(tile(p));
    if(DEV_MODE > 1.){
        //op -= vec3(60., -10., 0);
        t.x = smax(t.x, -(length(op.xy)-2.5), 0.1);
    }
    //vec2 h = vec2(6.-op.z, 5.);
    //addH;
    return t;
}
vec2 mapUV(vec3 p, vec3 n){
    if(DEV_MODE == 1.){
        if(iMouse.z < 0.5){
            p.zx *= rot(iTime);
            n.zx *= rot(iTime);
        }
    }
    
    p = fractal_position(p);
    p = fract(p*0.3);
    n = fractal_position(n);
    n = abs(n);
    //n = n*0.5+0.5;
    return (p.xy*n.z + p.xz*n.y + p.yz*n.x)/(n.x+n.y+n.z);  
}
vec2 mapCylUV(vec3 p, vec3 n){
    if(DEV_MODE == 1.){
        if(iMouse.z < 0.5){
            p.zx *= rot(iTime);
            n.zx *= rot(iTime);
        }
    }
    
    p = fractal_position(p);
    float y = fract(abs(p.y+0.5))*0.5;
    float a = fract(((atan(p.z/p.x)+PI)/(2.*PI))*4.);
    return vec2(a,y);
}
vec2 trace(vec3 ro, vec3 rd){
   	vec2 t = vec2(0.),dist;
    for(int i=0; i<96; i++)
    {
         dist = map(ro + rd*t.x);
         
         if(dist.x<0.01 || t.x > FAR){break;}
         //turn the step down if we use smoothstep in our map functions
         t.x += dist.x*0.75;
         t.y = dist.y;
       // glow += 0.1/(0.1+dist.x+20.)*float(dist.y>3.);
       // glow += 0.001/exp(-dist.x*2.);
    }
 return t;   
}
vec3 normal(vec3 p) {
    vec2 e = vec2(.001, 0);
    vec3 n = map(p).x - 
        vec3(
            map(p-e.xyy).x, 
            map(p-e.yxy).x,
            map(p-e.yyx).x
            );
    
    return normalize(n);
}
float calculateAO(in vec3 pos, in vec3 nor){
    //function from shane
	float sca = 2.0, occ = 0.0;
    for( int i=0; i<5; i++ ){
    
        float hr = 0.01 + float(i)*0.5/4.0;        
        float dd = map(nor * hr + pos).x;
        occ += (hr - dd)*sca;
        sca *= 0.7;
    }
    return clamp( 1.0 - occ, 0.0, 1.0 );    
}
float bumpSurf3D( in vec3 p, in vec3 n, float id){
    vec2 uv = id == 4. ? mapCylUV(p,n) : mapUV(p,n);
    return texture(iChannel1,uv).r;
    
}
vec3 doBumpMap(in vec3 p, in vec3 nor, float bumpfactor, float id){
    //this function is from shane
    const vec2 e = vec2(0.01, 0);
    float ref = bumpSurf3D(p, nor,id);                 
    vec3 grad = (vec3(bumpSurf3D(p - e.xyy, nor,id),
                      bumpSurf3D(p - e.yxy, nor,id),
                      bumpSurf3D(p - e.yyx, nor,id) )-ref)/(2.*e.x);                     
          
    grad -= nor*dot(nor, grad);          
                      
    return normalize( nor + grad*bumpfactor );
	
}
vec3 lighting(vec3 sp, vec3 sn, vec3 lp, vec3 rd, float id){
    vec3 color;
    //vector from hit position to light position (shane)
    vec3 lv = lp - sp;
    //length of that vector (shane)
    float ldist = max(length(lv), 0.00);
    //direction of that vector (shane)
    vec3 ldir = lv/ldist;
    //attenuation (shane)
    float atte = 1.0/(1. + 0.02*ldist*ldist );
    //diffuse color
    if(id == 4.){
       sn = doBumpMap(sp,sn,0.6,id);
    }
    float diff = max(dot(ldir, sn),0.);
    //specular reflection (shane)
    float spec = pow(max(dot(reflect(-ldir, sn), -rd), 0.0), 10.);
	//ambient occlusion
    float ao = calculateAO(sp, sn);
    //reflecton
    vec3 refl = reflect(rd, sn);
    //getting reflected and refracted color froma cubemap, only refl is used
    vec4 reflColor = texture(iChannel0, refl);
    //orage specular
    vec3 hotSpec = vec3(0.9,0.5, 0.2);
    
    vec2 uv = id == 4. ? mapCylUV(sp,sn) : mapUV(sp,sn);
    float tex = texture(iChannel1,uv).r;

    //Materials[2].color = mix(vec3(0.,0.7,0.99),vec3(0.9,0.45,0.3),pow((sin(sp.y)+sin(sp.z))+2.,0.9));
  //  Materials[3].color *= (0.5+tex); //*vec3(1.,0.45,0.1);
 //   Materials[3].rough = smoothstep(0.9,0.1,tex)*0.8;;    
    Materials[4].rough = 0.6*smoothstep(0.9,0.1,tex)*0.8;//tex;//*vec3(1.,0.45,0.1);
    //apply color options and add refl/refr options
    vec3 obj_color = Materials[int(id)].color;
    float rough = Materials[int(id)].rough;
    if(id == 5.){
        obj_color = texture(iChannel3,fract(sp.xy*0.075-0.5)).rgb*8.;
        rough = 0.;
    }
    color = obj_color*0.1+(diff*obj_color +  spec*hotSpec +reflColor.xyz*rough )*atte;
    return color*ao;   
    
}
float vig(vec2 uv){
    uv *=  1.0 - uv.yx;
    float vig = uv.x*uv.y * 50.0;
    return pow(vig, 0.3); 
}
void mainImage( out vec4 fragColor, in vec2 fragCoord ){
    
	vec2 uv = (fragCoord - iResolution.xy*.5)/iResolution.y;
	//uv = normalize(uv) * tan(asin(length(uv) *1.));//fisheye
    
	//Camera Setup.
	vec3 lk = path(0.);//  lk.z = 1.;
	vec3 ro = lk + vec3(0, .0, -.5);
 	vec3 lp = ro + vec3(0, 3.75, 10);
    vec2 m = (iMouse.xy - iResolution.xy*.5)/iResolution.y;
    
    float FOV = 1.57;
    vec3 fwd = normalize(lk-ro);
    vec3 rgt = normalize(vec3(fwd.z, 0., -fwd.x )); 
    vec3 up = cross(fwd, rgt); 
    vec3 rd = normalize(fwd + FOV*uv.x*rgt + FOV*uv.y*up);    
	
    if(iMouse.z > 0.5){
        //rd.yz *= rot(-m.y*2.);
        if(DEV_MODE == 1.){
            ro.xz *= rot(-m.x*4.);
            rd.xz *= rot(-m.x*4.);
        }
        else if(DEV_MODE == 2.){
            rd.yz *= rot(-m.y*2.);
            rd.xz *= rot(-m.x*4.);
        }
    }
    else{
        if(DEV_MODE == 2.){
            /*float tt = iTime*0.2;
            float t0 = floor(tt);
            float t0b = floor(tt+1.);
            float t1 = hash11(t0)-0.5;
            float t2 = hash11(t0b)-0.5;//t1+1.;
            float t = mix(t1,t2,smoothstep(0.5,0.6,fract(tt)));
            rd.yz *= rot(t*2.);
            rd.xz *= rot(t*2.);*/
            rd.xy *= rot(sin(iTime*0.5)*0.1);
        }
    }
    vec3 color = vec3(0.);//2.*mix(vec3(0.9, 0.5, 0.2)*4., vec3(0.0)-0.4, pow(abs(rd.y), 1./3.))*(1./pow(abs(length(rd.xy)-0.4), 1./3.))/8.;
    
    vec2 t = trace(ro, rd);
    vec3 sp = ro + rd*t.x;
    vec3 sn = normal(sp);
    if(t.x < FAR){
    color = lighting(sp, sn, lp, rd, t.y);
        float far = smoothstep(0.0, 1.0, t.x/90.);
        vec3 sky = vec3(0.);//2.*mix(vec3(0.9, 0.5, 0.2)*4., vec3(0.0)-0.4, pow(abs(rd.y), 1./3.))/4.;//*(1./pow(abs(length(rd.xy)-0.4), 1./3.))/8.;
        color = mix(color, sky, far);
    }
    
    color = pow(color,vec3(0.65));
    //color.xyz *= vig(fragCoord.xy/iResolution.xy);
    
    if(DEV_MODE == 3.){
        color += texture(iChannel2,uv).rgb;
    }
	fragColor = vec4(color,1.0);
}

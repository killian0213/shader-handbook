// Image (image) — Graffiti night by ocb
// https://www.shadertoy.com/view/4ljyRc

// Author: ocb
// Title: Graffiti night


#define PI 3.141592653589793
#define PIdiv2 1.57079632679489
#define TwoPI 6.283185307179586
#define INFINI 1000000.

#define SKY 0
#define ROAD 1
#define SIDE 2
#define WALL 3
#define SHOP 4
#define DOOR 5
#define SUSHI 6
#define PYL1 7
#define LIT1 8
#define PYL2 9
#define LIT2 10
#define PYL3 11
#define LIT3 12

#define OUTSIDE true
#define INSIDE false

int hitObj= SKY;

vec3 sideDim = vec3(258.,.6,160.);
vec3 sideCtr = vec3(240.,0.,-150.);
vec3 wallDim = vec3(250.,40.,150.);
vec3 wallCtr = vec3(250.,40.,-149.);
vec3 shopDim = vec3(5.,40.,50.);
vec3 shopCtr = vec3(-5.,40.,-48.);
vec3 doorDim = vec3(1.2,5.,5.);
vec3 doorCtr = vec3(-3.,5.8,-3.);
vec3 sushiCtr = vec3(-6.,17.,3.);

vec3 tagCtr = vec3(18.,10.,.8);

vec3 pylBox = vec3(.3,12.,.3);
float pylDim = .2;
float litDim = .7;
vec3 pylCtr1 = vec3(12.,12.,9.);
vec3 litCtr1 = vec3(12.,22.5,8.3);

vec3 pylCtr2 = vec3(100.,12.,9.);
vec3 litCtr2 = vec3(100.,22.5,8.3);
vec3 pylCtr3 = vec3(-63.,12.,20.);
vec3 litCtr3 = vec3(-63.7,22.5,20.);

vec3 aDim = vec3(250.,40.,250.);
vec3 aCtr = vec3(-320.,40.,-149.);
vec3 asDim = vec3(258.,0.6,260.);
vec3 asCtr = vec3(-320.,0.,-150.);

//Hash functions
float H1 (in float v) {return fract(sin(v) * 437585.);}

float H2 (in vec2 st,in float time) { 						
    return fract(sin(dot(st,vec2(12.9898,8.233))) * 43758.5453123 + time);
}

// damping funct used for drop impact
float plic(float x, float d ){
    x /= d;
    return clamp(1. - x*x*(3.-2.*x),0.,1.);
}

// Primitives
float sfcImpact(in float p, in float ray, in float h){
    float t = (h-p)/ray;
    if (t <= 0.001) t = INFINI;
    return t;
}

vec4 boxImpact( in vec3 pos, in vec3 ray, in vec3 ctr, in vec3 dim, bool outside) 
{
    vec3 m = 1.0/ray;
    vec3 n = m*(ctr-pos);
    vec3 k = abs(m)*dim;
	
    vec3 t1 = n - k;
    vec3 t2 = n + k;

	float tmax = max( max( t1.x, t1.y ), t1.z );
	float tmin = min( min( t2.x, t2.y ), t2.z );
	
	if( tmax > tmin || tmin < 0.0) return vec4(vec3(0.),INFINI);

    if(outside){
        vec3 norm = -sign(ray)*step(vec3(tmax),t1);
        return vec4(norm, tmax);
    }
    else{
        vec3 norm = -sign(ray)*step(t2, vec3(tmin));
        return vec4(norm, tmin);
    }
}

vec3 cylinderImpact(in vec2 pos, in vec2 ray, in vec2 cylO, in float cylR){
    float t = INFINI;
    vec2 delta = pos - cylO;
    
    float a = dot(ray,ray);
    float b = dot(delta, ray);
    float c = dot(delta,delta) - cylR*cylR;
    float d = b*b - a*c;
    
    if (d >= 0.){
        float sd = sqrt(d);
        t = (-b - sd)/a;
        if (t < 0.001) t = INFINI;
    }
    
    vec2 norm = pos + t*ray - cylO;
	return vec3(norm,t);
}

vec4 hemisphereImpact(in vec3 pos, in vec3 ray, in vec3 sphO, in float sphR){
    vec2 t = vec2(INFINI);
    vec3 d = sphO - pos;
    float b = dot(d, ray);
    
    if (b >= 0.){	// check if object in frontside first (not behind screen)
        float c = dot(d,d) - sphR*sphR;
    	float disc = b*b - c;
    	if (disc >= 0.){
        	float sqdisc = sqrt(disc);
            t.x = b + sqdisc;
            t.y = b - sqdisc;
        	
            t += step(t,vec2(0.))*INFINI;		// eliminate negative value
            vec2 h = pos.y + t*ray.y;
            
        	t += (1.-step(vec2(sphO.y), h))*INFINI;		// eliminate if intersection is below sphO
        }
    }
    float tt = min(t.x, t.y);
    float s = 1. - 2.*step(t.x,t.y);

    return vec4(s*normalize(pos + tt*ray - sphO), tt);
}

// GRAFFITI
vec3 graffiti(in vec2 uv, in sampler2D chan, in vec2 lit, float dist){
    vec3 col = vec3(0.);
    vec3 texUV = texture(chan,uv).rgb;
    vec2 dShad = lit*vec2(dist);
    vec3 greenRef = texture(chan,vec2(.999,.999)).rgb;
    
    float gr = .7-texUV.g;		// red patches
    col.gb -= vec2(.4,.4)*smoothstep(.1,.4,gr);
    
    gr = texture(chan,uv - vec2(.003,.003)).r - texUV.r;	//Black sketch
    col -= smoothstep(.0,.5,gr);
    gr = texture(chan,uv + vec2(.003,.003)).r - texUV.r;
    col -= smoothstep(.0,.5,gr);
    
    float shad = float(any(bvec3(step(.25,abs(texture(chan,uv + dShad*(1.-float(any(bvec2(step(1.-dShad,uv)))))).rgb - greenRef)))));
    float mask = float(any(bvec3(step(.25,abs(texUV - greenRef)))));
    col -= shad*(1.-mask);
    
    return col;
}

// Raytrace function
vec4 trace(in vec3 pos, in vec3 ray, bool shadow){
    float t = INFINI;
    vec3 norm = vec3(0.);
    
    // ROAD
	t = sfcImpact(pos.y, ray.y, 0.);
    if(t<INFINI){
        hitObj = ROAD;
        norm = vec3(0.,1.,0.);
    }
    
    // Far WALL
    vec4 info = boxImpact(pos,ray, aCtr, aDim, OUTSIDE);
    if(info.w < t){
        hitObj = WALL;
        t = info.w;
        norm = info.xyz;
    }
    
    // Far Sidewalk
    info = boxImpact(pos,ray, asCtr, asDim, OUTSIDE);
    if(info.w < t){
        hitObj = SIDE;
        t = info.w;
        norm = info.xyz;
    }
    
    // Pylon and light cover 1, 2, 3
    if(!shadow){
        if(boxImpact(pos,ray, pylCtr1, pylBox, OUTSIDE).w < INFINI){
            vec3 cinfo = cylinderImpact(pos.xz, ray.xz, pylCtr1.xz, pylDim);
            if(cinfo.z < t){
                hitObj = PYL1;
                t = cinfo.z;
                norm = vec3(cinfo.x,0.,cinfo.y);
            }
        }

        info = hemisphereImpact(pos, ray, litCtr1, litDim);
        if(info.w < t){
            hitObj = LIT1;
            t = info.w;
            norm = info.xyz;
        }
        
        if(boxImpact(pos,ray, pylCtr2, pylBox, OUTSIDE).w < INFINI){
            vec3 cinfo = cylinderImpact(pos.xz, ray.xz, pylCtr2.xz, pylDim);
            if(cinfo.z < t){
                hitObj = PYL2;
                t = cinfo.z;
                norm = vec3(cinfo.x,0.,cinfo.y);
            }
        }

        info = hemisphereImpact(pos, ray, litCtr2, litDim);
        if(info.w < t){
            hitObj = LIT2;
            t = info.w;
            norm = info.xyz;
        }
        
        if(boxImpact(pos,ray, pylCtr3, pylBox, OUTSIDE).w < INFINI){
            vec3 cinfo = cylinderImpact(pos.xz, ray.xz, pylCtr3.xz, pylDim);
            if(cinfo.z < t){
                hitObj = PYL3;
                t = cinfo.z;
                norm = vec3(cinfo.x,0.,cinfo.y);
            }
        }

        info = hemisphereImpact(pos, ray, litCtr3, litDim);
        if(info.w < t){
            hitObj = LIT3;
            t = info.w;
            norm = info.xyz;
        }
    }
    
    // Main Wall
    info = boxImpact(pos,ray, wallCtr, wallDim, OUTSIDE);
    if(info.w < t){
        hitObj = WALL;
        vec2 tp = pos.xy + info.w*ray.xy;
        if( abs(fract(tp.x/12.)*12.-6.) < 5. && abs(fract(tp.y/30.)*30.-10.) < 5.){
        	vec4 info2 = boxImpact(pos,ray, vec3(floor(tp.xy/vec2(12.,30.))*vec2(12.,30.)+vec2(6.,10.),.8), vec3(5.0001,5.0001,.2), INSIDE);
            t = info2.w;
        	norm = info2.xyz;
        }
        else{
            t = info.w;
            norm = info.xyz;
        }
    }
    
    // Sushi shop volume
    info = boxImpact(pos,ray, shopCtr, shopDim, OUTSIDE);
    if(info.w < t){
        vec2 tp = pos.xy + info.w*ray.xy;
        if( all(bvec2(step(abs(tp - doorCtr.xy) , doorDim.xy))) ){
            t = info.w;
            norm = info.xyz;
            hitObj = DOOR;
        }
        else{
            t = info.w;
            norm = info.xyz;
            hitObj = SHOP;
        }
    }
    
    // main Sidewalk
    info = boxImpact(pos,ray, sideCtr, sideDim, OUTSIDE);
    if(info.w < t){
        hitObj = SIDE;
        t = info.w;
        norm = info.xyz;
    }
    
    return vec4(norm,t);
}


// Function drawing letters
float S(in vec3 sp,in float y,in float z){
    vec2 f = vec2(clamp(sp.y-y, -.5,.5) , 2.*(sp.z-z));
    float s = .5*sin(TwoPI*f.x)-.5*f.x;
    return max(0.,.2/abs(f.y-s) -.4)*step(abs(sp.y-y),.5);
}
float U(in vec3 sp,in float y,in float z){
    vec2 f = vec2(clamp(sp.y-y+.5, 0.,1.) , 2.*(sp.z-z));
    float u = .4*sqrt(sqrt(f.x));
    return (max(0.,.14/abs(f.y-u) -.4) + max(0.,.14/abs(f.y+u) -.4))*step(abs(sp.y-y+.03),.5);
}
float H(in vec3 sp,in float y,in float z){
    vec2 f = vec2(clamp(sp.y-y, -1.,1.) , sp.z-z);
    float hc = max(0.,.08/abs(f.x) -.4)*step(abs(f.y),.2);
    float u = .2*sqrt(abs(f.x-1.));
   	float hr = (max(0.,.06/abs(f.y-u) -.4) + max(0.,.06/abs(f.y+u) -.4))*step(abs(sp.y-y),.5);
	return hc+hr;
}
float I(in vec3 sp,in float y,in float z){
	vec2 f = vec2(clamp(sp.y-y, -1.,1.) , sp.z-z);
    float i = .2*sqrt(abs(f.x+.8));
   	float hr = max(0.,.06/abs(f.y-i+.2) -.4)*step(abs(sp.y-y),.5);
	return hr;
}

// Lights Halo used for street light and sushi sign
float bulbHalo(in vec3 lit,in vec3 pos, in vec3 p, in vec3 ray, in vec3 norm, float intensity, float size){
    float d = dot(lit-pos,ray);
    float e = dot(lit-p,norm);
    if( d>0. && e>=0.) return min(1.,max(0.,intensity/(length(cross(lit-pos, ray)) + size) - .1));	// Light halo
	else return 0.;
}

// Cam set functions
vec3 getCamPos(in vec3 camTarget){
    float 	rau = 40.,
    		alpha = iMouse.x/iResolution.x*1.1*PI+1.6,
    		theta = iMouse.y/iResolution.y*1.+2.35;
    		if (iMouse.xy == vec2(0.)){
                alpha = 2.95;
                theta = 3.2;
            }
    
    return rau*vec3(-cos(theta)*sin(alpha),sin(theta),cos(theta)*cos(alpha))+camTarget;
}

vec3 getRay(in vec2 st, in vec3 pos, in vec3 camTarget){
    float 	focal = 1.;
    vec3 ww = normalize( camTarget - pos );
    vec3 uu = normalize( cross(ww,vec3(0.0,1.0,0.0)) ) ;
    vec3 vv = cross(uu,ww);
	// create view ray
	return normalize( st.x*uu + st.y*vv + focal*ww );
}

// MAIN
void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
	vec2 uv = fragCoord.xy / iResolution.xy - vec2(.5);
    vec2 ratio = vec2(1.,iResolution.y/iResolution.x);
    
    vec3 color = vec3(0.);
    vec3 lightColor = vec3(1.,.9,.7);	// street light color
    vec3 advColor = vec3(.9,.4,.1);		// sushi sign color
    
    vec3 camTarget = vec3(6.,10.,0.);	// cam target is JCVD
    vec3 pos = getCamPos(camTarget);
    vec3 ray = getRay(uv, pos ,camTarget);
    
    
    vec4 info = trace(pos, ray, false);		// false: do not trace for shadow calculation
    float t = info.w;
    vec3 norm = info.xyz;
    
    vec3 p = pos + t*ray;
    
    // Lights computation
    vec3 lightVec1 = litCtr1-p;
    vec3 ambiLight1 = normalize(lightVec1);
    float shad1 = .5*dot(ambiLight1,norm)+.5;
    float len = length(lightVec1);
    float light1 = 270./(len*len)
                *(.7*dot(ambiLight1,vec3(0.,1.,0.))+.3);	// to avoid propagation above the source light

    vec3 lightVec2 = litCtr2-p;
    vec3 ambiLight2 = normalize(lightVec2);
    float shad2 = .5*dot(ambiLight2,norm)+.5;
    len = length(lightVec2);
    float light2 = 270./(len*len)
                *(.7*dot(ambiLight2,vec3(0.,1.,0.))+.3);	// to avoid propagation above the source light

    vec3 lightVec3 = litCtr3-p;
    vec3 ambiLight3 = normalize(lightVec3);
    float shad3 = .5*dot(ambiLight3,norm)+.5;
    len = length(lightVec3);
    float light3 = 270./(len*len)
                *(.7*dot(ambiLight3,vec3(0.,1.,0.))+.3);	// to avoid propagation above the source light
    
    // ambiLight is the light direction
    // light is the intensity received due to distance
    // shad is the intensity due to surface orientation
    
    // color and render
    if(hitObj == ROAD)
        color += lightColor*.6*texture(iChannel1,p.xz*.03).rrr*(light1+light2+light3);
    
    else if(hitObj == SIDE){
        color += 1.5*lightColor*texture(iChannel1,(p.xz*norm.y+p.xy*norm.z)*.05).rrr;
        color -= 2.*fract(9.5+p.z)*step(9.5,p.z)*step(-20.,p.x)*step(fract(p.x*.2),.97)*texture(iChannel1,p.xz*.05).rrr;
        color -= fract(-63.+p.x)*step(-63.,p.x)*step(p.x,-20.)*step(fract(p.z*.2),.97)*texture(iChannel1,p.xz*.05).rrr;
        color *= 1.-step(p.x,-20.)*norm.x;
        color -= step(-20.,p.x)*texture(iChannel1,p.xz*.2).b/(abs(p.z)+.00001);
        color *= shad1*light1+shad2*light2+shad3*light3;
    }
    else if(hitObj == WALL || hitObj == SHOP){
        color += lightColor*(.5*texture(iChannel1,(p.xz*norm.y+p.xy*norm.z+p.yz*norm.x)*.02).rrr+.5);	// concret wall
		color *= (.8*texture(iChannel1,(p.xz*norm.y+p.xy*norm.z+p.yz*norm.x)*.03).b +.2);	// dirts on wall
        color -= texture(iChannel1,p.xy*.05).b/p.y;
        color *= (light1*shad1 + light2*shad2 + light3*shad3);
        
        // JCVD graffiti
        float dist;
        float ti = iChannelTime[2];
		// Shadow of graffiti is moving away depending on graffiti movement
        if(ti < 12.5) dist = .15;
        else if(ti < 14.5) dist = .15+(ti-12.5)*.15;
        else if(ti < 33.5) dist = .25;
        else if(ti < 57.5) dist = .15;
        else if(ti < 61.) dist = .15+(ti-57.5)*.15;
        else if(ti < 76.) dist = .15;
        else if(ti < 78.5) dist = .35;
        else if(ti < 98.5) dist = .15;
        else if(ti < 100.8) dist = .30-(ti-98.5)*.10;
        else if(ti < 108.) dist = .15;
        else if(ti < 110.8) dist = .15+(ti-108.)*.15;
        else dist = .15;
            
        vec2 lp = p.xy*.1-vec2(.1,.5);
        if(floor(lp.x)==0. && floor(lp.y)==0.) color += graffiti(lp, iChannel2, ambiLight1.xy, dist);
        
        // NyanCat Graffiti
        float mv = 8.*fract(iTime*.1)-4.;
        lp = p.zy*vec2(.05,.2)-vec2(mv,1.7);
    	if(floor(lp.x)==0. && floor(lp.y)==0.) color += step(p.x,-20.)*graffiti(lp, iChannel0, ambiLight3.zy,.1);

    }
    
    else if(hitObj == DOOR){
        info = boxImpact(pos,ray, doorCtr, doorDim, INSIDE);
        t = info.w;
        norm = info.xyz; 
        vec3 tp = pos + t*ray;
        color += vec3(.7,.6,.4)*2./length(doorCtr + vec3(0.,doorDim.y,3.) - tp); // light inside
		float wind = .03*sin(p.y+3.*p.x)*sin(iTime+p.x)*(10.-p.y);	// little bending mvt to simulate wind on curtain
        vec3 curtCol = vec3(.7,.7,.7) + vec3(.0,-.5,-.5)*step(length((doorCtr.xy+vec2(wind,2.)-p.xy)*ratio), .9);   // white color strip curtain + japan red flag
        color +=curtCol*light1*(1.-smoothstep(.35+wind, .45+wind ,abs(fract((p.x )*1.666667)-.5))) * smoothstep(.39,.4,fract((p.y-.6)/10.));	// curtain with mvt due to wind
        color -= vec3(1.)*smoothstep(.97,.98,fract((p.y-.6)/10.));	// holding bar for curtain
    }
    else if(hitObj == PYL1) color += lightColor*vec3(.5)*light1*dot(norm,vec3(0.,0.,-1.))*max(0.,dot(ambiLight1,vec3(0.,1.,0.)));	// street light pylon
    else if(hitObj == PYL2) color += lightColor*vec3(.5)*light2*dot(norm,vec3(0.,0.,-1.))*max(0.,dot(ambiLight2,vec3(0.,1.,0.)));
    else if(hitObj == PYL3) color += lightColor*vec3(.5)*light3*dot(norm,vec3(0.,0.,-1.))*max(0.,dot(ambiLight3,vec3(0.,1.,0.)));

    else if(hitObj == LIT1) color += lightColor*vec3(.5)*shad1;		// steet light cover
    else if(hitObj == LIT2) color += lightColor*vec3(.5)*shad2;
	else if(hitObj == LIT3) color += lightColor*vec3(.5)*shad3;
 	// else SKY
        
    
    // hard shadow
    // only calculated localy with main street light 1
    if(abs(p.x) < 60.){
        vec3 v = normalize(p - litCtr1);
        info = trace(litCtr1 , v, true);		// true: trace for shadow
        if(info.w<INFINI && length(litCtr1 + info.w*v - p) > .1) color *= .2;
    }   
    
    // street light bulb halo
    color += lightColor*bulbHalo(litCtr1,pos,p, ray, norm,.6,.15);
    color += lightColor*bulbHalo(litCtr2,pos,p, ray, norm,.6,.15);
    color += lightColor*bulbHalo(litCtr3,pos,p, ray, norm,.6,.15);
    
    
    // SUSHI AD LIGHTS
    
    // light vibration - short circuit
    float vibe = 1.-.7*H1(iTime)*step(.8,H1(floor(iTime*5.)*.345632));
    // letters position
    vec3 Sc1 = sushiCtr,					
         Uc = sushiCtr-vec3(0.,1.5,0.),
         Sc2 = sushiCtr-vec3(0.,3.,0.),
         Hc = sushiCtr-vec3(0.,4.5,0.),
         Ic = sushiCtr-vec3(0.,6.,0.);
    
    float st = sfcImpact(pos.x, ray.x, sushiCtr.x);	//sushi sign surface
    
    if(st<t){
        vec3 sp = pos + st*ray;
        // Draw sign rectangle
        float dz = abs(sp.z-sushiCtr.z), dy = abs(sp.y-sushiCtr.y+3.);
        color += .5*vibe*advColor*smoothstep(.45,.55,dz)*(1.-smoothstep(.55,.65,dz))*step(dy,4.);
		color += .5*vibe*advColor*smoothstep(3.9,4.,dy)*(1.-smoothstep(4.,4.1,dy))*step(dz,.55);
        color -= smoothstep(1.9,2.,dy)*(1.-smoothstep(2.,2.1,dy))*step(abs(sp.z-sushiCtr.z+1.1),.55);
		
        // Draw letters
        float d = sushiCtr.y-sp.y;
        if(d<0.6) 		color += advColor * S(sp,Sc1.y,Sc1.z) * vibe;		// Draw S letter
        else if(d<2.1) 	color += advColor * U(sp,Uc.y,Uc.z) * vibe;			// vibe = twinkle effect
        else if(d<3.6) 	color += advColor * S(sp,Sc2.y,Sc2.z) * vibe;
        else if(d<5.1) 	color += advColor * H(sp,Hc.y,Hc.z) * vibe;
        else 			color += advColor * I(sp,Ic.y,Ic.z) * vibe;
	}
    
    // letters Halo
    color += advColor * bulbHalo(Sc1,pos,p, ray, norm,.4,.35) * vibe;
    color += advColor * bulbHalo(Uc,pos,p, ray, norm,.4,.35);
    color += advColor * bulbHalo(Sc2,pos,p, ray, norm,.4,.35) * vibe;
    color += advColor * bulbHalo(Hc,pos,p, ray, norm,.4,.35);
    color += advColor * bulbHalo(Ic,pos,p, ray, norm,.4,.35) * vibe;

    // Wall surface highlighted by ad
    if(norm.z ==1. || norm.y == 1.){
        float sl = .3/length(Sc1-p)+.3/length(Sc2-p)+.3/length(Ic-p);	// taking into account
        color += advColor*min(.5, sl);									// only 3 letters (enough for rendering)
    }
    
    if(hitObj == SHOP && norm.x == 1.) color*= .8;	// shop corner shadow
    
    // Water patches reflection and drops impact
    if(hitObj == SIDE || hitObj == ROAD){
        float tex = texture(iChannel1,p.xz*.025+.3).b;
        // drops impact
        float dt = 1.-fract(iTime+H2(floor(p.xz*10.),0.));
        float rainPlic = dt*plic(2.*abs(fract(p.x*2.)-.5),dt)*dt*plic(2.*abs(fract(p.z*2.)-.5),dt)*step(.5,H2(floor(p.xz*2.),iTime*.05));
        
        // Water patches + drops impact
        float waterPatch = smoothstep(.45,.55,tex)+.5*rainPlic;
        
        vec3 refl = reflect(ray,norm);
        vec3 reflight = step(p.y,.8)*waterPatch*lightColor; //step(p.y,.8) consider only
        vec3 refletter = step(p.y,.8)*waterPatch*advColor;  //road and sidewalk
        vec3 nul = vec3(0.);
        // Street light reflection
        color += reflight * bulbHalo(litCtr1,p,nul, refl, nul,3.,1.); 
    	color += reflight * bulbHalo(litCtr2,p,nul, refl, nul,3.,5.);
        color += reflight * bulbHalo(litCtr3,p,nul, refl, nul,3.,5.);
        // letters reflection
        color += refletter * bulbHalo(Sc1,p,nul, refl, nul,1.,1.8)*vibe;
        color += refletter * bulbHalo(Uc,p,nul, refl, nul,1.,1.8);
        color += refletter * bulbHalo(Sc2,p,nul, refl, nul,1.,1.8)*vibe;
        color += refletter * bulbHalo(Hc,p,nul, refl, nul,1.,1.8);
        color += refletter * bulbHalo(Ic,p,nul, refl, nul,1.,1.8)*vibe;
    }
    
    // Rain
    t = sfcImpact(pos.z, ray.z, camTarget.z);
    vec3 rp = pos + t*ray;
    vec2 sc = vec2(rp.x*.1,rp.y*.002 + iTime*.1);
    color *= 1. + .5*max(0.,2.*(texture(iChannel3,sc).r-.8));    // -.8 change rain intensity
    
    t = sfcImpact(pos.x, ray.x, camTarget.x);
    rp = pos + t*ray;
    sc = vec2(rp.z*.1,rp.y*.002 + iTime*.1);
    color *= 1. + .5*max(0.,2.*(texture(iChannel3,sc).r-.8));
    
	fragColor = vec4(color,1.0);
}
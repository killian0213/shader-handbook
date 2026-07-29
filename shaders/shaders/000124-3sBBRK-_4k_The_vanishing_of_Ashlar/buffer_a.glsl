// Buffer A (buffer) — [4k] The vanishing of Ashlar by NuSan
// https://www.shadertoy.com/view/3sBBRK


// Lower that value if it's too slow
#define SAMPLE_COUNT 30.

#define res iResolution

//////////////////////
// PATHTRACING PASS //
//////////////////////

// we use globals for most parameters, it save space
// s is starting position, r is ray direction
// n is normal at intersection point and d is distance to the intersection
vec3 s,r,n=vec3(0);
float d=10000.;
vec3 boxid=vec3(0);

mat2 rot(float a) {return mat2(cos(a),sin(a),-sin(a),cos(a));}

// Compute octahedron distance from center, os is the size of each of the 4 'axis'
float octaedge(vec3 p, vec4 os) {
    
    vec4 vv=vec4(1.4142,-1.4142,1,-1); // 1.4142 = cos(45)/cos(60)
    vec4 popo = p.xxyy*vv.xyww + p.yyzz*vv.zzxy;
    popo=abs(popo)-os;
          
    float d = max(max(popo.x,popo.y),max(popo.z,popo.w));

    return d;
}

vec4 osize1 = vec4(10);
vec4 osize2 = vec4(2);
vec3 boxrepeat = vec3(1,8,8);
vec3 centerrepeat = vec3(.4,2,2);
float boxanim = 0.;
float centeranim = 0.;
float boxtime = 0.;
float insidedist(vec3 p) {
	return max(octaedge(p, osize1), -octaedge(p, osize2));
}

// analytical box intersection
void box(vec3 basepos, int side) {
	
    // are we on the outside octahedron or the center one
	bool iscenter = octaedge(basepos,osize2)<.1;
	vec3 rep = iscenter ? centerrepeat : boxrepeat;
	
    // main repetition is based on the x axis
	vec3 id2 = floor(basepos.x/rep.x)+vec3(1.7,3,7);
	
    // then we can have integer multiplier subdivision without breaking the illusion
	rep = (rep/(floor(rnd33(id2)*vec3(6))+1.));
	
	vec3 pos=vec3(0);	
    
    // offset on yz axis, box animation
	vec2 ooo = fract(rnd(floor(basepos.x/rep.x)+.7)*vec2(1,3.7))*8.*7.;
    ooo*=boxtime*vec2(1,1.3)*(iscenter?centeranim:boxanim)*rep.yz*0.03;
    basepos.yz += ooo;
	pos.yz += ooo;
  
    // here we are applying the box repetition
	boxid = (floor(basepos/rep)+0.5)*rep;

	vec3 size = rep*0.4;
  
	vec3 vr = r;
	pos=s+pos-boxid;
  
	vec3 box=max((size-pos)/vr,(-size-pos)/vr);
	float bd = min(min(box.x,box.y),box.z);
	if(bd>0. && bd>d*float(side)) {
		vec3 cur = step(abs(pos+vr*d),size);
		if(side>0 ? (min(cur.x,min(cur.y,cur.z))>0.) : insidedist(s+r*bd)>0.) {
			d=bd;
			n=-step(box-bd,vec3(0))*sign(pos+vr*d);
		}
	}
}


// analytical octrahedron intersection, with customisable size for each of the 4 'axis'
void frontocta(vec4 size, int side) {
    
  	vec4 vv=vec4(1.4142,-1.4142,1,-1); // 1.4142 = cos(45)/cos(60)
    vec4 invd = 1. / (r.xxyy*vv.xyww + r.yyzz*vv.zzxy);
  	vec4 popo = -s.xxyy*vv.xyww - s.yyzz*vv.zzxy;
    
    vec4 t0 = (popo - size) * invd;
    vec4 t1 = (popo + size) * invd;
    vec4 mi = min(t0, t1);
    vec4 ma = max(t0, t1);

    float front = min(min(ma.x,ma.y),min(ma.z,ma.w));
    float back = max(max(mi.x,mi.y),max(mi.z,mi.w));
    if(back>front) return;

    if(side==0) {
        back=front;
    }

    if(back<d && back > 0.) {
        d = back;
        vec4 vo = sign(t0-t1) * (side==0 ? step(-back,-ma) : step(back,mi));

        n = vo.xxz - vo.yzw;
        n.y += vo.y-vo.w;
        n*=-sign(float(side)-.5)*vec3(0.817,0.5777,0.817); // = vec3(1,0.5 * 1.4142,1)/1.224 = 1.224 = cos(45) * tan(60)
    }
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
	vec2 frag = fragCoord.xy;
	vec2 uv = (frag-res.xy*0.5)/res.y;
		
	vec3 col = vec3(0);
		
	float time =iTime-.9;
	boxtime = time;

    // Main way to control the intro (camera, DOF focus, shape)
    // Each vec3 is a section of the intro
    // first value is the seed of the camera motionpath/speed/FOV, fractionnal part is a time offset, negative values subdivide the section in two parts
    // second value is the focus distance for the DOF, negative value makes the DOF bigger
    // third value is the shape seed, integer value is the background shape, fractionnal part is the center shape
	vec3 mot[16] = vec3[16]( 
						 vec3(12,2,14.19)
						,vec3(-4.7,11,29)
						,vec3(7,10,7.2)
						,vec3(11,-5,5.63)
						// --------------
						,vec3(16.45,5,17.4)
						,vec3(-12,5,12.2)
						,vec3(2,5,12.2)
						,vec3(0.4,9,10)
						// --------------
						,vec3(17.8,7,11.1)
						,vec3(-7.6,-20,15)
						,vec3(-13,-30,2.2)
						,vec3(7,40,3)
						// --------------
						,vec3(17,20,6)
						,vec3(-5.4,50,15.4)
						,vec3(16,30,13)
						,vec3(12,10,7)
						);


	float light = 0.;
	int section = int(min(16.,time/8.));
	float rest = mod(time,8.);

	vec3 mval = mot[section];
	if(section>5 && section<9) mval.z+=floor(rest)*2.2;

	vec3 pcam = rnd23(vec2(round(abs(mval.x)),0));
		
	//////// SIZES ////////
	if(section==0) osize2 = vec4(6);
	
    // extruding the shapes
	float push2 = max(0.,time-48.)*1.5;
	if(section>7) push2 = 10000.;
	float push = 2.+max(0.,time-40.)*.5+push2;
	float decol=max(0.,time-70.);
	if(section>14) {
		decol=0.;
		push=0.;
		push2=0.;
	}

	if(section>4)osize2 = vec4(2,push,push,2);
	if(section>6)osize1 = vec4(10,10.+push2,10.+push2,10);
	
	//////// REPEATS ////////
	boxrepeat = rnd23(vec2(floor(mval.z),0))*50.;
	centerrepeat = pow(rnd23(vec2(0,fract(mval.z)*31.5+28.)),vec3(2))*10.+.2;

	if(section==3) osize1=vec4(20);
		
	//////// NIGHT ////////
	float skydist = 1.;
	float bright=0.;
	if(section>8 && section<15) {
		boxanim = .3;
		boxrepeat *= 2.;
		centerrepeat *= 10.;
		if(section>11) {
            // transition to night section, with light appearing
			light = sat((time/8.-12.));
			skydist = section>12?200.:20.*light;
			osize1 = vec4(20,push2,push2,20);
			boxanim=0.;
			if(section==14) {
                // center brightening and vanishing
				centerrepeat.xy*=1.1;
				bright=pow(sat(time/8.-14.07),2.);
				osize2.xw = vec2(2.-sqrt(bright+.01-uv.y*.02+uv.x*.001)*2.3,17.*bright+2.);
			}
		}
	}
	centeranim = section>2?(section>7?0.3:0.3):0.;

	//////// CAMERA ANIMATION ////////
    // array value is a seed to an offset on lissajous curves, with various speed factor
	float avance = pcam.x*200. + (rest+(fract(mval.x+.5)-.5)*8.) * (pcam.y-0.2);
	if(mval.x<0.) avance += floor(rest/4.)*3.;
	
	float focusdist = abs(mval.y);
	float dofamount = mval.y>0. ? .05 : .15;
    // extrapush is used to put the camera outside the room without colliding, so we can zoom more
	float extrapush = max(fract(pcam.z*17.23)-.5,0.)*15.;
	float fov = pcam.z*1.5+.5 + extrapush/2.;
	vec3 bs=vec3(0,-1.5 + sin(avance*.2)*1.,0);
	vec3 t = vec3(0,-1.5 + sin(avance*.3)*3.,0);

    // lissajous curve to makes interesting camera motion
	bs.x += 5.*sin(avance*.4 + 0.7);
	bs.z += 5.*sin(avance*.9);

    // camera target is following the same curve in front of the camera but with a random factor to focus more on the center
	float dt=max(0.,fract(pcam.z*24.81)-.2)*6.;
	t.x += dt*sin(avance*.4 + 0.7 + 1.);
	t.z += dt*sin(avance*.9 + 1.);
	
	//////// SKYDIVING ////////
	vec3 govec = vec3(-1,1.41,-1);
	vec3 poff = govec*decol*min(2.,decol)*2.5;
	t -= poff + govec*10.*(step(2.,decol)-bright);
	bs -= poff;
    
	//////// CAMERA COMPUTE ////////
	vec3 cz=normalize(t-bs);
	vec3 cx=normalize(cross(cz,vec3(0,1,0)));
	vec3 cy=cross(cz,cx);

	// Main path tracing loop, do many samples to reduce the noise
    float ZERO=min(0.,iTime); // this is a trick to force the GPU to keep the loop
    // instead of trying to compile a giant shader by duplicating what's inside
	for(float i=ZERO; i<SAMPLE_COUNT; ++i) {
    		
		s=bs;	
		vec2 h = rnd23(frag-13.6-i*184.7).xy;
		// DOF
		vec3 voff = sqrt(h.x)*(cx*sin(h.y*6.283)+cy*cos(h.y*6.283))*dofamount;
		s-=voff;
		r=normalize(uv.x*cx+uv.y*cy+fov*cz + voff*fov/(focusdist+extrapush));

		s += (r-cz) * extrapush;
		
        // number of bounces is 3
		for(float j=0.; j<3.; ++j) {
			////////// TRACE //////////
			d=100000.;
  
            // find instersection with geometry
            
            // first test if we started inside a repeating box
			box(s,-1);
  
            // then intersect with the background octahedron
			frontocta(osize1, 0);
  
            // save that intersection for latter
			float d2=d;
			vec3 s2=s;
			vec3 n2=n;

            // intersect with the center shape
			frontocta(osize2, 1);
  
            // now use that position to carve the repeating box
			box(s+r*d,1);

            // if intersection position is outside the center octahedron, it means that we went trough the shape
            // so we back to the background intersection
			if(octaedge(s+r*d,osize2)>0.01) {
				d=d2;
				n=n2;
                // last possible repeating box intersection on the background octahedron
				box(s+r*d,1);
			}
    
            // and finally the ground plane intersection
			float curplane=(1.1-s.y)/r.y;
			if(curplane>0. && curplane<d) {
				d=curplane;
				n=sign(s.y)*vec3(0,1,0);
			}
    			
			if(d>10000.) break;
			
			// go to the intersection point
			s = s + r * d;
		
            // test if we are outside the 'sky distance'
			float edge1 = octaedge(s,osize1);						
			if(edge1>skydist) {
                // if so, we just push the sky color and early out
				col += mix(vec3(0.6,0.8,1)*0.8, vec3(1,0.7,0.5) * 2., max(r.x+r.z*.3-r.y*.7,0.)*.7);
				break;
			}

            // if we are in the light section
			if(light>0.) {
				float middle = step(7.,edge1);

                // center burning
				col += bright * step(1.,-edge1) * vec3(.5,.7,1)*3.;
				
                // side lights in two colors
				col += middle * vec3(0.4,0.5,0.8) * 1.2 * step(0.7,rnd(dot(boxid,vec3(1,4,7))+floor(time)*0.1));
				col += middle * vec3(0.2,0.5,0.9) * 1.2 * step(0.1,fract(.2+boxid.z*0.01 + floor(time)*13.2)*3.-1.5);			
			}

            // slight increase in perf, get out before computing rebound direction in the last rebound
			if(j==2.) break;

            // roughness computing, depending on if we are on the center shape or not
			vec3 grid = step(fract(s*4.-.1),vec3(.8));
			float rough = octaedge(s,osize2)<.1 ? .5 : mix(1.,0.45*rnd31(floor(s*4.-.1)*27.33),min(grid.x,min(grid.y,grid.z)));
            // slight offset so we get out of the surface before rebound
			s-=r*0.01;
            // random rebound direction according to roughness parameter
			r=normalize(reflect(r,n) + normalize(rnd23(frag+vec2(i*277.,j*375.)+fract(time))-.5)*rough);
            
		}
        
        // tricks by iq to disable unrolling and have faster compilation times
        if( col.x<-100.0 ) break;
	}
	col *= .6/SAMPLE_COUNT;
	
	fragColor = vec4(col, 1);
}
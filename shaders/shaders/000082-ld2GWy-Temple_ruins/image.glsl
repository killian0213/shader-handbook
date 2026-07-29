//  (image) — Temple ruins by avix
// https://www.shadertoy.com/view/ld2GWy

float sdrBox(vec3 p, vec3 b, float r) {
    vec3 d = abs(p) - b;
    return min(max(d.x,max(d.y,d.z)),0.0) + length(max(d,0.0)) - r;
}

float sdCylinder(vec3 p, vec2 h) {
    return max( length(p.xz)-h.x, abs(p.y)-h.y );
}



/***********************************************/
float terrain(vec3 p) {
    float q=smoothstep(0.1, 0.6, texture(iChannel0, p.xz*0.002).x)*0.22;
    float h= q + texture(iChannel0, p.xz*1.6 ).x*0.02;
    return min(p.y+2.7 +h,p.y+7.0 +h-exp(length(p.xz*0.07)));   
}
/***********************************************/

float ruins(vec3 p) {
    vec3 q=p;
    
    //bumps
    float o= texture(iChannel0, p.xy*0.1 ).x*texture(iChannel0, p.yz*0.1 ).x*0.005;

    //pillars bottom
    p.x=clamp(p.x,-8.0,8.0);                                     //limit x
    if ((p.z<2.0 && p.z>-2.0) && (p.x<0.0 && p.x>-4.0)) p.x=0.0; //chop hole in middle 

    p.x=mod(p.x,2.0)-0.5*2.0;                                    //rep x

    p.z=clamp(p.z,-4.0,4.0);                                     //limit z
    if (q.x>2.0 || q.x<-6.0) p.z=clamp(p.z,-2.0,2.0);
    p.z=mod(p.z,2.0)-0.5*2.0;                                    //rep z

    float r= 0.5-clamp( sin(p.y*1.2+1.58)*0.5, 0.0,0.05);
    float d=sdCylinder(p, vec2(r,1.5)) -o;

    //pillars top
    p.y-=2.8;
    r= 0.4-clamp( sin(p.y*1.8+0.8)*0.5, 0.0,0.05);
    
    float h=1.5;
    if (q.x>2.0) { p.y-=0.5; h=2.0; r=0.4-clamp( sin(p.y*1.15+1.1)*0.5, 0.0,0.05); } //pull first 3x2 pillars up
    float t=sdCylinder(p, vec2(r,h)) -o;    

    //mid platform
    q.y-=1.8;
    float c=sdrBox(q, vec3(7.45,0.25,1.45), 0.05) -o;
    q.x+=2.0;
    c=min(c, sdrBox(q, vec3(3.45,0.25,3.45), 0.05) -o);

    //bottom platform
    q.y+=3.55;
    c=min(c, sdrBox(q, vec3(3.65,0.2,3.65), 0.05) -o);
    q.x-=2.0;
    c=min(c, sdrBox(q, vec3(7.65,0.2,1.65), 0.05) -o);
    
    //ground platform
    q.x+=2.0;
    q.y+=0.8;
    c=min(c, sdrBox(q, vec3(4.65,0.6,4.65), 0.05) -o);
    q.x-=2.0;
    c=min(c, sdrBox(q, vec3(8.65,0.6,2.65), 0.05) -o);
    
    //top part
    q.y-=8.0;
    q.x-=5.0;
    c=min(c, sdrBox(q, vec3(2.45,0.15,1.45), 0.05) -o);
    c=max(c, -sdrBox(q, vec3(1.45,0.25,0.45), 0.05) -o);    //left hole
    
    //top right part
    q.y+=1.0;
    q.x+=6.0;
    c=min(c, sdrBox(q, vec3(4.50,0.15,1.65), 0.05) -o);
    q.x+=1.0;
    q.z-=0.85;
    c=min(c, sdrBox(q, vec3(3.45,0.15,2.5), 0.05) -o);
    q.z+=0.85;
c=max(c, -sdrBox(q, vec3(2.25,4.5,2.25), 0.05) -o);    
    
    d=min(min(c,d),t);
	
    return d;
}
/***********************************************/
vec2 opU(vec2 a, vec2 b) {
	return mix(a, b, step(b.x, a.x));
}

/***********************************************/
#define pi 3.14
#define pi2 pi*0.5

vec2 trees(vec3 p){
    float l=8.0;
    float s=4.0;
    
    p.y-=4.0;
    
    //bumps
    float o= texture(iChannel2, p.xy*0.1 ).x*2.2;
    
   	float r=1./l;
	float ofs=s+s/(r*2.0);

	float a= mod( atan(p.x, p.z) + pi2*r, pi*r) -pi2*r;
	p.xz=vec2(sin(a),cos(a))*length(p.xz) -ofs;
	p.x+=ofs;

    vec2 q=vec2(length(p)-s -o ,3.0);
    
    p.y+=6.0;
    return opU(q, vec2(sdCylinder(p,vec2(0.7,2.0)),4.0));

}

/***********************************************/
vec2 DE(vec3 p) {

	vec2 r=vec2( ruins(p), 1.0); 
//	vec2 r=vec2( length(p)-1.0, 1.0);
	
    vec2 t=vec2( terrain(p),2.0);
    vec2 b=trees(p);

	return opU(opU(r,t),b);
}
/***********************************************/
vec3 normal(vec3 p) {
	vec3 e=vec3(0.01,-0.01,0.0);
	return normalize( vec3(	e.xyy*DE(p+e.xyy).x +	e.yyx*DE(p+e.yyx).x +	e.yxy*DE(p+e.yxy).x +	e.xxx*DE(p+e.xxx).x));
}
/***********************************************/
void rot( inout vec3 p, vec3 r) {
	float sa=sin(r.y); float sb=sin(r.x); float sc=sin(r.z);
	float ca=cos(r.y); float cb=cos(r.x); float cc=cos(r.z);
	p*=mat3( cb*cc, cc*sa*sb-ca*sc, ca*cc*sb+sa*sc,	cb*sc, ca*cc+sa*sb*sc, -cc*sa+ca*sb*sc,	-sb, cb*sa, ca*cb );
}
/***********************************************/
vec3 tex3D(vec3 pos, vec3 nor, sampler2D s) {
	return texture( s, pos.yz).xyz*abs(nor.x)+
	       texture( s, pos.xz).xyz*abs(nor.y)+
	       texture( s, pos.xy).xyz*abs(nor.z);
}
float csh( vec3 ro, vec3 rd, float mint, float maxt, float k ) {
    float res = 1.0;
    float dt = 0.02;
    float t = mint;
    for( int i=0; i<10; i++ ) {
        float h = DE( ro + rd*t ).x;
        res = min( res, k*h/t );
        t += max( 0.05, dt )*8.0;
    }
    return clamp( res, 0.0, 1.0 );
}
/***********************************************/
vec3 fog(vec3 col, float d, vec3 p ) {
    p.y-=1.5;
	float n=smoothstep(-2.5,0.5,terrain(p));
	float fog=exp(-0.05 * d*d);
	return mix(vec3(0.6), col, n*fog);
}
/***********************************************/
void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
    vec2 p = -1.0 + 2.0 * fragCoord.xy / iResolution.xy;
    p.x *= iResolution.x/iResolution.y;	
	vec3 ta = vec3(0.0, 0.0, 0.0);
	vec3 ro =vec3(0.0, 0.0, -14.0);
	vec3 lig=normalize(vec3(-2.0, 6.0, -4.0));
	
	vec2 mp=iMouse.xy/iResolution.xy;
	rot(ro,vec3(mp.x,mp.y,0.0));
	rot(lig,vec3(mp.x,mp.y,0.0));

    /* animate camera */
    rot(ro,vec3(iTime*0.2, 
     (sin(iTime*0.2)*0.3+0.3) + (cos(2.24+iTime*0.1)*0.5+0.5),
    0.0));
    

	vec3 cf = normalize( ta - ro );
    vec3 cr = normalize( cross(cf,vec3(0.0,1.0,0.0) ) );
    vec3 cu = normalize( cross(cr,cf));
	vec3 rd = normalize( p.x*cr + p.y*cu + 2.5*cf );

	vec3 col=vec3(0.0);
	/* trace */
	vec2 r=vec2(0.0);	
	float f=0.0;
	vec3 ww;
	for(int i=0; i<90; i++) {
		ww=ro+rd*f;
		r=DE(ww);		
		if( r.x<0.0 ) break;
		f+=r.x;
	}
	/* draw */
	if( f<50.0 ) {
		vec3 nor=normal(ww);

		if (r.y==1.0) {
			col=vec3(1.5)*tex3D(ww*0.3, nor, iChannel1)*(DE(ww+nor).x*.5+.5)*(DE(ww+nor*.5).x+.5);
//		    col=vec3(1.5)*tex3D(ww*0.3, nor, iChannel1);
		        //add moss
		        vec3 m=tex3D(ww*0.1, nor, iChannel2);
		        col=mix(col,(vec3(0.1,1.0,0.3)-m)*0.2,sin(m.y));
		}
		if (r.y==2.0) {
		    col=vec3(0.55,1.0,0.65)*texture( iChannel2, ww.xz*0.02).xyz*0.7;
		}
		if (r.y==3.0) {
		    col=vec3(0.15,0.45,0.25)*tex3D(ww*0.4, nor, iChannel2);
		}
		if (r.y==4.0) {
		    col=vec3(0.4,0.2,0.1)*tex3D(ww*0.4, nor, iChannel2);
		}
		
			float amb =0.3;//0.1*ww.y/2.0;
			float dif =0.7*clamp(dot(lig, nor), 0.0,1.0);
			float bac =0.2*clamp(dot(nor,-lig), 0.0,1.0);
			float sh=csh(ww, lig, 0.05, 2.0, 8.0);
		col*=(amb+dif+bac+sh);

	col=fog(col,1./f,ww);

	col*=exp(.06*-f); col*=2.0;	
	col*=exp(.01*-f); col*=0.9;	
	

	} else {

	col=vec3(0.7,0.8,1.0)*texture( iChannel2, rd.yx*0.1).xyz*2.2;
	    
	}
	
	
	fragColor = vec4( col, 1.0 );
}

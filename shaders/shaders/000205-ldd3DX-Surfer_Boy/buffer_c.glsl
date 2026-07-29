// Buffer C (buffer) — Surfer Boy by iq
// https://www.shadertoy.com/view/ldd3DX

const vec3 corner1 = vec3(-0.088,-0.103,0.084);
const vec3 center  = vec3(-0.005,-0.193,0.14);
const vec3 corner2 = vec3( 0.098,-0.105,0.08);

vec3 transformHead( in vec3 p )
{
  p.x += 0.012;
  return mat3( 0.986264,-0.097838, -0.133010,
               0.086792, 0.992467, -0.086465,
               0.140468, 0.073733,  0.987326)*p;
}

vec3 transformHat(in vec3 p)
{
  p.y -= 0.03;
  p = mat3( 0.79200, -0.141, 0.59400,
           -0.26976,  0.792, 0.54768,
           -0.54768, -0.594, 0.58924)*p;
  p.y -= 0.1;
  return p;
}

const float eyeOff = 0.005;

vec3 map( vec3 p )
{
	vec3 headp = transformHead( p );
	vec3 headq = vec3( abs(headp.x), headp.yz );

    // head
	float d = sdEllipsoid( headp, vec3(0.0,0.015,-0.06 ),vec3(0.33,0.365,0.34) );
	d = smax(d,-sdEllipsoid( vec3( almostIdentity( headq.x, 0.03, 0.01 ), headp.yz),  vec3( 0.25,0.06,0.4),vec3(0.4,0.2,0.2) ), 0.015);
    //d = smax(d,-sdEllipsoid( vec3( sqrt(headq.x*headq.x+0.0001), headp.yz),  vec3( 0.25,0.06,0.4),vec3(0.4,0.2,0.2) ), 0.015);
	d = smin(d,sdEllipsoid( headp, vec3(0.0,-0.165,0.13),vec3(0.22,0.15,0.145)), 0.01 );
	d = smin(d,sdEllipsoid( headp, vec3(0.01,-0.2,0.17),vec3(0.12,0.115,0.105)), 0.01 );
	d = smin(d,sdEllipsoid( headq, vec3(0.1,-0.103,0.09),vec3(0.175,0.146,0.18) ), 0.02);

    
    // nose
	vec3 n = headp-vec3(0.0,0.1,0.23);
	n.x -= n.y*n.y*0.18;
	n.yz = mat2(0.98,0.198997,-0.198997,0.98)*n.yz;
	d = smin( d, sdCone( n, vec2(0.01733,-0.13) ), 0.03);
	n.yz -= vec2(-0.102975, 0.004600);
	vec3 m = vec3(abs(n.x),n.yz);
	float na = sdCone( n, vec2(0.527,-0.85) );
	na = smax( na, sdSphere(n,vec3(0.0,-0.03,-0.04),0.1), 0.015 );
	na = smin( na, sdEllipsoid(m, vec3(0.038,-0.085,0.0),vec3(0.027)), 0.016 );
	na = smin( na, sdEllipsoid(m, vec3(0.0,-0.11,-0.01), vec3(0.02,0.02,0.02)), 0.02 );
	na = smax(na,-sdEllipsoid(m, vec3(0.033,-0.09,0.008),vec3(0.01,0.02,0.009)*1.5), 0.008 );
	d = smin( d, na, 0.01);

    // mouth
	vec3 bocap = headp-vec3(-0.006,-0.026,0.22);
	vec3 bocap3 = bocap;
	bocap.xy = mat2x2(0.99,-0.141,0.141,0.99)*bocap.xy;
	vec3 bocap2 = bocap;
	bocap.yz = mat2x2(0.9,-0.346,0.346,0.9)*bocap.yz;
	float  labioa = sdCone(bocap, vec2(0.219,-0.18) );
	labioa = smax( labioa, sdEllipsoid(bocap,vec3(0.0,0.1,-0.15), vec3(0.22,0.35,0.34)), 0.02 );
	d = smin( d, labioa, 0.015 );
	d = smax( d, -sdCapsule( bocap, vec3(0.0,-0.077,0.115),vec3(0.0,-0.09,0.135), 0.013 ), 0.01 );
	bocap2.y -= min(bocap2.x*bocap2.x*4.0,0.04);
	d = smax( d, -sdEllipsoid(bocap2,vec3(0.0,-0.172,0.15), vec3(0.09+0.008*sign(bocap.x),0.017,0.25)), 0.01 );		
	vec4 b = sdBezier( corner1, center, corner2, bocap );
	d = smin(d,b.x - 0.0075*sqrt(4.0*b.y*(1.0-b.y)), 0.005);

    // ears
	vec3 earq = headq - vec3(0.34,-0.04,0.02);
	earq.xy = mat2(0.9,0.436,-0.436,0.9)*earq.xy;
	earq.xz = mat2(0.8,0.6,-0.6,0.8)*earq.xz;
	float ear = sdEllipsoid( earq, vec3(0.0),vec3(0.08,0.12,0.09) );
	ear = smax( ear, (abs(earq.z)-0.016), 0.01 );
	ear = smin( ear, sdSphere(earq,vec3(0.015,0.0,-0.03),0.04), 0.02);        
	ear = smax( ear, -0.8*sdEllipsoid( earq, vec3(0.0,0.022,0.02),vec3(0.06,0.08,0.027) ),0.01 );
	ear = smax( ear, -sdEllipsoid( earq, vec3(-0.01,-0.01,0.01),vec3(0.04,0.04,0.05) ), 0.01 );
	d = smin(d,ear, 0.015);
    
    
    // eye sockets
	d = smax(d,-sdEllipsoid( headq, vec3(0.1+eyeOff,0.03,0.11),vec3(0.105,max(0.0,0.12-0.2*headq.x),0.115)+0.01),0.01 );
	b = sdBezier( vec3(0.053+eyeOff,0.017,0.225), vec3(0.12+eyeOff,-0.02,0.255), vec3(0.18+eyeOff,0.02,0.205), headq-vec3(0.0,0.03-0.04,0.0) );
	d = smin(d,b.x - 0.003*b.y*(1.0-b.y)*4.0,0.012);

    // chin fold
	n = (headp-vec3(0.14,-0.16,0.297));
	n.xy = mat2(0.8,0.6,-0.6,0.8)*n.xy;
	d = smax(d, -sdEllipsoid( n,  vec3(0.0), vec3(0.096,0.01,0.03)), 0.007);
	
    // neck/body
	{
	vec3 q = vec3( abs(p.x), p.yz );
	d = smin( d, sdCapsule( p, vec4(0.0,-0.1,-0.1,0.1), vec4(0.0,-0.6,-0.1, 0.12 )).x, 0.05 );
	d = smin( d, sdCapsule( q, vec3(0.0,-0.62,-0.08), vec3(0.24,-0.71,0.02-0.1), 0.16 ), 0.05 );        
	d = smin( d, sdCapsule( q, vec4(0.046,-0.555,0.05,0.01), vec4(0.250,-0.55,-0.035,-0.02) ).x, 0.03 );
	}
    
	vec3 res = vec3(d,1.0,1.0);
    

    // eyes
	m = headq - vec3(0.0021,0.0,0.019);
	d = sdEllipsoid( m, vec3(0.1+eyeOff,0.03,0.11),vec3(0.105,0.09,0.1) );
	d = smax(d,-sdEllipsoid( headq, vec3(0.102+eyeOff+0.004*sign(headp.x)*1.8,0.03+0.004*1.8,0.28),vec3(0.07) ),0.001);
	if( d<res.x ) res = vec3(d,2.0,1.0);

    // teeth
	{
	bocap3 = bocap3 - vec3(0.01,-0.055,0.04);
	bocap3.xz = mat2x2(0.99,0.141,-0.141,0.99)*bocap3.xz;
	d = sdCappedCylinder( bocap3.xzy, vec2(0.11,0.01) );
	vec3 dd = bocap3;
	dd.x = mod(dd.x+0.0075,0.015)-0.0075;
	float sp = sdBox( dd-vec3(0.0,-0.1,0.0), vec3(0.0004,0.018,0.015) );
	d = smax(d,-sp,0.003);
	d = max( d, dot(bocap3.xy,vec2(-0.707,0.707))+0.05 );
	if( d<res.x ) res = vec3(d,8.0,1.0);
	}

	
	// eyebrows
	b = sdBezier( vec3(0.035,0.16,0.0), vec3(0.1,0.18,-0.02), vec3(0.2,0.12,-0.1), 
	(headq-vec3(0.0,0.0,0.25))*vec3(1.0,1.0,2.0) );
	d = b.x - 0.01*sqrt(clamp(1.0-b.y,0.0,0.9));
	float fr = (sign(b.w)*headq.x*0.436+0.9*headq.y);
	float cp = cos(1300.0*fr);
	cp -= 0.5*cos(600.0*fr); 
	cp += 0.3*cos(330.0*fr);
	cp *= clamp(1.0-3.0*headq.x,0.0,0.8);
	d -= cp*0.0017;
	d/=1.5;
	if( d<res.x ) { res = vec3(d,3.0,0.4);}

    // hair
	//if( p.x>-0.4 && p.y>-0.1) // +10%
	{
		float hh = 0.27 - headp.y;

		float ss = sign(headp.x);

		vec3 pelop = headp;
		pelop.x += (1.0-hh)*0.007*cos(pelop.y*30.0);
		vec3 peloq = vec3( abs(pelop.x), pelop.yz );
		
		vec3 ta = vec3(0.0);
		float vc = 0.0;

		{
		const vec3 p0a = vec3(0.05,0.3,0.15);
		const vec3 p0b = vec3(0.18,0.17,0.22);
		const vec3 p0c = vec3(0.1,0.2,0.23);
		vec4 b = sdBezier( p0a, p0c, p0b, pelop );
		float d1 = b.x - 0.06*(1.0-0.9*b.y);
		d = d1; ta = p0b - p0a; vc = b.y;
		}
		{
		const vec4 p1a = vec4(-0.04,0.26,0.15,0.075);
		const vec4 p1c = vec4(0.02,0.2,0.24,0.015);
		vec2 b = sdCapsule(pelop, p1a, p1c );
		float d1 = b.x;
		if( d1<d ) { d=d1; ta = (p1a.xyz-p1c.xyz)*vec3(ss,1.0,1.0); vc = b.y;}
		}
		{
		const vec4 p2a = vec4(0.16,0.25,0.14,0.07);
		vec4 p2b = vec4(0.185+0.025*ss,0.14,0.23-0.02*ss,0.006);
		vec2 b = sdCapsule(peloq, p2a, p2b );
		float d1 = b.x;
		if( d1<d ) { d=d1; ta = p2b.xyz-p2a.xyz; vc = b.y;}
		}
		{
		const vec3 p3a = vec3(0.205,0.20,0.14);
		vec3 p3b = vec3(0.255+0.01*ss,0.05,0.17);
		vec3 p3c = vec3(0.21+0.01*ss,0.15,0.18);
		vec4 b = sdBezier( p3a, p3c, p3b, peloq );
		float d1 = b.x - 0.06*(1.0-0.9*b.y);
		if( d1<d ) { d=d1; ta = p3b-p3a; vc = b.y;}
		}
		{
		const vec4 p4a = vec4(0.24,0.16,0.11,0.06);
		vec4 p4b = vec4(0.285,-0.04,0.14,0.006);
		vec2 b = sdCapsule(peloq, p4a, p4b );
		float d1 = b.x;
		if( d1<d ) { d=d1; ta = p4b.xyz-p4a.xyz; vc = b.y; }
		}
		{
		const vec4 p5a = vec4(0.275,0.12,0.07,0.06);
		vec4 p5b = vec4(0.295,-0.09,0.1,0.006);
		vec2 b = sdCapsule(peloq, p5a, p5b );
		float d1 = b.x;
		if( d1<d ) { d=d1; ta = p5b.xyz-p5a.xyz; vc = b.y; }
		}

		
		{
		vec3 vv = normalize(vec3(ta.z*ta.z+ta.y*ta.y, -ta.x*ta.y, -ta.x*ta.z) );
		float ps  = dot(peloq,vv);
		d -= 0.003*sin(300.0*ps);
		d -= 0.008*(-1.0+2.0*textureGood( iChannel0, vec2(1024.0*ps,vc*5.12) ));
		}
		
		if( d<res.x ) res = vec3(d,3.0,vc);
	}

    // eyelashes
	{
	vec3 cp;
	vec4 b = sdBezier2(  vec3(0.0525+0.0025*sign(headp.x)+eyeOff,0.063, 0.225), 
			vec3(0.120+eyeOff,0.135, 0.215), vec3(0.1825+eyeOff+0.0025*sign(headp.x),0.050, 0.200), 
			headq, cp );
	float ls = 4.0*b.y*sqrt(1.0-b.y);
	d = b.x - 0.002*ls;
	d += 0.001*ls*sin(headq.x*300.0-headq.y*300.0)*step(cp.y,headq.y);
	d += 0.001*ls*sin(headq.x*1000.0-headq.y*1000.0)*step(cp.y,headq.y);
	if( d<res.x ) { res = vec3(d,3.0,0.35);}
    }
	

    // hat
    {
	vec3 hatp = transformHat( headp );
	d = sdEllipsoidXY2Z( hatp, vec3(0.36,0.38,0.365) );
	d = abs(d+0.003)-0.003;
	d = smax(d,-0.065-hatp.y,0.006);
	float gb = abs(hatp.x)-hatp.z-0.0975;
	d -= 0.002*sqrt(clamp(abs(gb)/0.015,0.0,1.0)) - 0.002;
	hatp.y += 0.1;
	float p1 = abs(sin(600.0*hatp.x+hatp.y*200.0));
	float p2 = abs(cos(150.0*hatp.z)*sin(150.0*hatp.y));
	p2 *= smoothstep(0.01,0.02,hatp.y-0.035);
	d -= 0.0005*mix(p1,2.0*p2,smoothstep(0.0,0.01,gb));
	if( d<res.x ) res = vec3(d,4.0,1.0);
	vec3 vp = hatp - vec3(0.0,0.19,0.0);
	vp.yz = mat2(0.8,-0.6,0.6,0.8)*vp.yz;
	vp.y -= 0.2*sqrt(clamp(1.0-vp.x*vp.x/0.115,0.0,1.0))-0.1;
	d = 0.8*sdEllipsoid( vp, vec3(0.0,0.0,0.25),vec3(0.3,0.04,0.35) );
	if( d<res.x ) res = vec3(d,5.0,1.0);
    }	
	
	
	return res;
}

// https://iquilezles.org/articles/normalsSDF
vec3 calcNormalmap( in vec3 pos, in float ep )
{
#if 0    
    vec2 e = vec2(1.0,-1.0)*0.5773;
    return normalize(e.xyy*map(pos+e.xyy*ep).x + 
					 e.yyx*map(pos+e.yyx*ep).x + 
					 e.yxy*map(pos+e.yxy*ep).x + 
					 e.xxx*map(pos+e.xxx*ep).x );
#else
    // inspired by tdhooper and klems - a way to prevent the compiler from inlining map() 4 times
    vec3 n = vec3(0.0);
    for( int i=ZERO; i<4; i++ )
    {
        vec3 e = 0.5773*(2.0*vec3((((i+3)>>1)&1),((i>>1)&1),(i&1))-1.0);
        n += e*map(pos+e*ep).x;
    }
    return normalize(n);
#endif    
}

//=========================================================================

float calcAO( in vec3 pos, in vec3 nor )
{
	float ao = 0.0;

	vec3 v = normalize(vec3(0.7,0.5,0.2));
	for( int i=ZERO; i<12; i++ )
	{
		float h = abs(sin(float(i)));
		vec3 kv = v + 2.0*nor*max(0.0,-dot(nor,v));
		ao += clamp( map(pos+nor*0.01+kv*h*0.08).x*3.0, 0.0, 1.0 );
		v = v.yzx; if( (i&2)==2) v.yz *= -1.0;
	}
	ao /= 12.0;
	ao = ao + 2.0*ao*ao;
	return clamp( ao*5.0, 0.0, 1.0 );
}

// https://iquilezles.org/articles/rmshadows
float calcSoftShadow( in vec3 ro, in vec3 rd, float k )
{
	float res = 1.0;
	float t = 0.001;
	for( int i=ZERO; i<50; i++ )
	{
		float h = map(ro + rd*t ).x;
		res = min( res, smoothstep(0.0,1.0,1.4*k*(h+0.0015)/sqrt(t)) );
		t += clamp( h, 0.003, 0.1 );
		if( res<0.001 || t>0.8) break;
	}
	return clamp(res,0.0,1.0);
}


vec3 shade( in vec3 ro, in vec3 rd, in float t, in float m, in float matInfo )
{
	float eps = (abs(m-3.0)<0.2) ? 0.002: 0.0002;
	
	vec3 pos = ro + t*rd;
	vec3 nor = calcNormalmap( pos, eps );
	

	vec3 mateD = vec3(0.0);
	vec2 mateK = vec2(0.0);
	float mateS = 0.0;
	vec3 mateSG = vec3(1.0);

	if( m<1.5 )
	{
		mateD = vec3(0.132,0.06,0.06);
		
		vec3 p = transformHead( pos );
		vec3 headp = p;
		vec3 q = vec3( abs(p.x), p.yz );

		float m = 1.0 - smoothstep( 0.04, 0.14, length(q-vec3(0.16,-0.11,0.23)) );
		float no = texture(iChannel0,p.xy).x;
		m = clamp( m + 0.25*(-1.0+2.0*no), 0.0, 1.0 );
		mateD = mix( mateD, vec3(0.13,0.03,0.03), m );
		

		mateSG = vec3(0.75,0.97,1.0);

					
		m = 1.0 - smoothstep( 0.04, 0.17, length(q-vec3(0.45,-0.01,0.0)) );
		mateD += vec3(1.0,0.01,0.0)*m*0.3*(1.0+0.4*sign(p.x));
		mateSG = mix( mateSG, vec3(0.3-0.1*sign(p.x),0.9,1.0), m );;

		m = 1.0 - smoothstep( 0.05, 0.1, length(vec3(0.5,1.0,1.0)*(q-vec3(0.0,-0.06,0.23))) );

		vec2 uv = pos.xy*22.0;
		vec2 iuv = floor(uv);
		vec2 fuv = fract(uv);
		vec4 ran = texelFetch( iChannel0, (ivec2(iuv)+6)&255, 0 );
		vec2 off = ran.xy;
		float sss = pow(ran.z,5.0);
		float size = max(0.0,(0.5+0.5*m)*(0.3+0.7*sss)*0.12);
		float fr = 1.0 - smoothstep( size*0.5, size*2.0, length(fuv-off) );
		mateD = mix(mateD,vec3(0.25,0.05,0.0)*0.2, 0.6*(1.0-0.4*sss)*fr );
					
		mateK = vec2(0.08,0.5);
		mateS = 1.0;    

		
		vec3 bocap = headp-vec3(-0.006,-0.025,0.22);
		bocap.xy = mat2x2(0.99,-0.141,0.141,0.99)*bocap.xy;
		bocap.yz = mat2x2(0.9,-0.346,0.346,0.9)*bocap.yz;
		
		{
		vec4 b = sdBezier( corner1, center, corner2, bocap );
		float d1 = b.x - 0.01*4.0*b.y*(1.0-b.y);
		float isLip = 1.0-smoothstep( 0.0005, 0.0050, d1 );
		mateD = mix( mateD, vec3(0.14,0.04,0.05), 0.7*isLip );
		mateK = mix( mateK, vec2(0.4,1.5), isLip );
		}
		
		mateK *= 0.5 + no;
	}
	else if( m<2.5 )
	{
		mateD = vec3(0.18,0.18,0.225)*0.85;
		mateK = vec2(0.5,10.0);
		mateSG = vec3(1.0,1.0,0.9);
		
        
		vec3 p = transformHead( pos );
		vec3 q = vec3( abs(p.x), p.yz );
        q.x -= eyeOff;
        
		
		vec2 r = q.xy-vec2(0.102+0.004*sign(p.x),0.03+0.004);
		
		float m = length(r) - 0.042;
		if( m<0.0 )
		{
			m = abs(m);
			mateD = mix( mateD, vec3(0.0), smoothstep(0.0,0.003,m));
			mateD = mix( mateD, vec3(0.06,0.02,0.0), smoothstep(0.003,0.006,m));
			
			r.x *= -sign(p.x);
			float an = atan(r.y,r.x) + 1.5;
			float ca = 1.0-smoothstep(0.0,1.0,abs(an-1.0));
			ca *= 1.0-smoothstep(0.0,0.008,abs(m-0.011));

			float te = texture(iChannel0, vec2(an*0.1,m)).x;
			mateD = mix( mateD, (1.8*te*vec3(0.06,0.02,0.0)+(0.5+0.5*te)*ca*1.3*vec3(0.1,0.07,0.05)), smoothstep(0.003,0.006,m));

			mateD = mix( mateD, vec3(0.0), smoothstep(0.017,0.018,m-0.001));
			mateK = vec2(0.05,8.0);
		}

		r = q.xy-vec2(0.105+0.03*sign(p.x),0.058);
		mateD += (1.0-smoothstep(0.00,0.012,length(r)))*1.0;
	}
	else if( m<3.5 )
	{
		float focc = smoothstep(0.0,1.0,matInfo);

		mateD = vec3(0.025,0.015,0.01)*0.6*focc;
		mateK = vec2(0.1*focc,1.0);
	}
	else if( m<4.5 )
	{
		vec3 hatp = pos;
		hatp = transformHat(hatp);
		hatp.y += 0.1;
		float f = abs(hatp.x)-hatp.z;
		f = smoothstep(0.19,0.2,f );
		
		vec3 blue = vec3(0.01,0.04,0.08);
		vec3 te = 
		texture( iChannel0, 0.15*pos.yz ).xyz+
		texture( iChannel0, 1.0*pos.yz ).xyz;
		blue *= 0.5+0.5*te.z;
		mateD = mix( vec3(0.18), blue, f );
		mateS = 0.05;
		
			
		vec2 si = (hatp.xy-vec2(0.0,-0.18)) * 3.5;
		float h = si.y - 0.1*sin( 8.0*si.x );
		h = min( abs(h-1.15)-0.06, abs(h-1.0)-0.015 );
		h += clamp( (abs(hatp.x)-0.25)/0.1, 0.0, 1.0 );
		mateD = mix( mateD, vec3(0.004,0.008,0.014), 1.0-smoothstep( 0.01, 0.02, h ) );
		
	}
	else if( m<5.5 )
	{
		mateD = 0.5*vec3(0.01,0.04,0.08);
		mateD *= 0.7+0.6*texture( iChannel0, 2.0*pos.xz ).x;
		mateS = 0.05;
	}
	else if( m<8.5 )
	{
		mateD = vec3(0.30,0.30,0.40)*0.5;
		mateK = vec2(0.5,1.0);
		mateS = 0.2;
		
	}
	
	float fre = clamp(1.0+dot(nor,rd), 0.0, 1.0 );
	float occ = calcAO( pos, nor );
	
	vec3 col = vec3(0.0);
	
    {
		// key
		float dif1 = dot(nor,sunDir);
		vec3 hal = normalize( sunDir-rd );
		float spe = pow(clamp(dot(hal,nor),0.0,1.0),0.001+8.0*mateK.y);
		float sha = calcSoftShadow( pos+nor*0.0005, sunDir, 24.0 ); 
		float ssha = 1.0;
		if( abs(m-3.0)<0.2 ) { dif1=0.5*dif1+0.5; sha=0.95*sha+0.05;  }
		if( abs(m-2.0)<0.2 ) { sha=clamp(0.2+sha*dif1*2.0,0.0,1.0); dif1=0.4+0.6*dif1; ssha=0.0; }
		
		dif1 = clamp(dif1,0.0,1.0);

        float sks = (abs(m-1.0)<0.2)?0.5:0.0;
		vec3 sha3 = vec3((1.0-sks)*sha+sks*sqrt(sha),sha*0.4+0.6*sha*sha,sha*sha);
		
		col += mateD*3.1*vec3(2.5,1.1,0.5)*dif1*sha3;
		col += mateK.x*vec3(1.5,1.4,1.3)*dif1*sha*spe*(0.04+0.96*pow(clamp(dot(hal,nor),0.0,1.0),5.0))*ssha;
    }
	{
		// fill
		col += mateD*vec3(0.45,0.75,1.0)*occ*occ*occ*(0.5+0.5*nor.y)*4.5;
		float dif1 = 0.5 + 0.5*nor.y;
		float sha = 1.0;
		float spe = smoothstep( -0.15, 0.15, reflect(rd,nor).y );
		col += mateK.x*vec3(0.7,0.9,1.0)*dif1*sha*spe*(0.04+0.96*pow(clamp(dot(rd,nor),0.0,1.0),5.0))*occ*occ*3.0;
	}
	{
		// bounce
		vec3 bak = normalize( sunDir*vec3(-1.0,-3.5,-1.0));
		float dif = clamp(0.3+0.7*dot(nor,bak),0.0,1.0);
		col += mateD*vec3(1.2,0.8,0.6)*occ*occ*dif*2.5;
	}
	{
		col += mateS*mateD*fre    *vec3(2.0,0.95,0.80)*0.7*occ;
		col += mateS*mateD*fre*fre*vec3(1.1,0.80,0.65)*1.2*occ;
	}

	col = pow( col, mateSG );

    return col;
}

//--------------------------------------------

vec3 intersect( in vec3 ro, in vec3 rd, float mindist, float maxdist )
{
	vec3 res = vec3(-1.0);
	
	float t = mindist;
	for( int i=ZERO; i<150; i++ )
	{
		vec3 p = ro + t*rd;
		vec3 h = map( p );
		res = vec3(t,h.yz);
		if( abs(h.x)<0.00025 || t>maxdist ) break;
		t += h.x;
	}
	return res;
}

///////////////////////////////////////////////

vec3 render( in vec3 ro, in vec3 rd, in vec2 uv, in int sampleID )
{
	vec4 res = texture(iChannel1,uv);
	vec3 col = res.xyz;
	
	const float mindist = 0.8;
	const float maxdist = 1.8;
	
	vec3 tm = intersect( ro, rd, mindist, maxdist );
	if( tm.y>-0.5 && tm.x < maxdist )
	{
		col = shade( ro, rd, tm.x, tm.y, tm.z );
	}

	return col;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{	
	mat3 ca; vec3 ro; float fl;
	computeCamera( iTime, ca, ro, fl );
#if AA<2
	vec2  p = (2.0*fragCoord-iResolution.xy)/iResolution.y;
    vec3  rd = normalize( ca*vec3(p,-fl) );
	vec3 col = render( ro, rd, fragCoord.xy/iResolution.xy, 0 );
#else
	vec3 col = vec3(0.0);
	for( int m=ZERO; m<AA; m++ )
	for( int n=ZERO; n<AA; n++ )
	{
		vec2 rr = vec2( float(m), float(n) ) / float(AA) - 0.5;
		vec2 p = (2.0*(fragCoord.xy+rr)-iResolution.xy)/iResolution.y;
		vec3 rd = normalize( ca * vec3(p,-fl) );
		col += render( ro, rd, (fragCoord+rr)/iResolution.xy, AA*m+n );
	}    
	col /= float(AA*AA);
#endif
		
	fragColor = vec4( col, 1.0 );
}
// Image (image) — Surfer Boy by iq
// https://www.shadertoy.com/view/ldd3DX

// Copyright Inigo Quilez, 2018 - https://iquilezles.org/
// I am the sole copyright owner of this Work. You cannot
// host, display, distribute or share this Work neither as
// is or altered, in any form including physical and
// digital. You cannot use this Work in any commercial or
// non-commercial product, website or project. You cannot
// sell this Work and you cannot mint an NFTs of it. You
// cannot use this Work to train AI models. I share this
// Work for educational purposes, you can link to it as
// an URL, proper attribution and unmodified screenshot,
// as part of your educational material. If these
// conditions are too restrictive please contact me.


// A surfer boy in the beach, disney/pixar style. I had to be very careful
// with the complexity, otherwise the browser would crash during shader
// compilation. I also had to split the boy in two layers because of that,
// see below (the single pass version is smaller of course but takes 3 extra
// seconds to compile, and renders a bit more slowly)
//
// This is totally painted to camera, it won't work from others perspectives.
//
// Common   - contains some basic stuff
// Buffer A - renders the brackground - not super polished really
// Buffer B - blurs the background
// Buffer C - paints the boy, except the hand and the board
// Image    - paints the hand and the board, and does some minimal postpro
//
// If you have a slow PC, you can watch it here: https://www.youtube.com/watch?v=ya3FRzuozQ0


// hands and board
vec3 map( vec3 p )
{
    // hands
    float d = 1.0;
	if( p.x<-0.8 && p.y<-0.1)
	{
		vec3 hp = p - vec3(-0.9,-0.30,0.12);

		hp.z *= 1.2;
		
		float ss = sign(hp.y+0.05);

		vec4 a1 = vec4(-0.030+0.010*ss, -0.050 +0.050 *ss, 0.06, 0.0225);
		vec4 b1 = vec4(-0.070+0.010*ss, -0.049 +0.051 *ss, 0.05, 0.024);
		vec4 c1 = vec4(-0.145+0.015*ss, -0.0465+0.0535*ss, 0.01, 0.027);
		vec4 d1 = vec4(-0.12,           -0.0465+0.0535*ss,-0.06, 0.030);
		vec3 u1 = vec3(-0.0290+0.011*ss,-0.05  +0.05  *ss, 0.08);
		vec3 v1 = vec3(-0.0185,         -0.05  +0.05  *ss, 0.08);

		float dd =     sdCapsule( hp, a1, b1 ).x;
		dd = smin( dd, sdCapsule( hp, b1, c1 ).x, 0.005 );
		dd = smin( dd, sdCapsule( hp, c1, d1 ).x, 0.005 );
		dd = smax( dd,-sdCapsule( hp, u1, v1, 0.021 ),0.005);
		d = min( d, dd/1.2 );
		
		ss = sign(hp.y+0.1);
		
		if( hp.y>-0.1 )
		{
			const vec4 a2 = vec4(-0.02,-0.050, 0.06, 0.024);
			const vec4 b2 = vec4(-0.06,-0.050, 0.05, 0.0256);
			const vec4 c2 = vec4(-0.15,-0.050, 0.01, 0.0288);
			const vec4 d2 = vec4(-0.13,-0.050,-0.06, 0.032);
			const vec3 u2 = vec3(-0.018,-0.05,0.08);
			const vec3 v2 = vec3(-0.017,-0.05,0.08);

			dd =           sdCapsule( hp, a2, b2 ).x;
			dd = smin( dd, sdCapsule( hp, b2, c2 ).x, 0.005 );
			dd = smin( dd, sdCapsule( hp, c2, d2 ).x, 0.005 );
			dd = smax( dd,-sdCapsule( hp, u2, v2, 0.021 ),0.005);
		}
		else
		{
			const vec4 a2 = vec4(-0.07,-0.145, 0.06, 0.021);
			const vec4 b2 = vec4(-0.10,-0.145, 0.05, 0.0224);
			const vec4 c2 = vec4(-0.16,-0.145, 0.01, 0.0252);
			const vec4 d2 = vec4(-0.15,-0.145,-0.06, 0.028);
			const vec3 u2 = vec3(-0.07,-0.145,0.08);
			const vec3 v2 = vec3(-0.05,-0.145,0.08);

			dd =           sdCapsule( hp, a2, b2 ).x;
			dd = smin( dd, sdCapsule( hp, b2, c2 ).x, 0.005 );
			dd = smin( dd, sdCapsule( hp, c2, d2 ).x, 0.005 );
			dd = smax( dd,-sdCapsule( hp, u2, v2, 0.019 ),0.005);
		}
        d = min( d, dd/1.2 );
	}
    
	vec3 res = vec3(d,1.0,1.0);

    // nails
	{
		vec3 np = mat3(0.990,0.0,0.141,
					   0.000,1.0,0.000,
					   -0.141,0.0,0.990)*
					   (p-vec3(-0.9,-0.30,0.12));
		d =       sdEllipsoid(np, vec3(-0.025, 0.000,0.056), vec3(0.022,0.018,0.006) );
		d = min(d,sdEllipsoid(np, vec3(-0.025,-0.050,0.056), vec3(0.023,0.019,0.006) ));
		d = min(d,sdEllipsoid(np, vec3(-0.046,-0.100,0.053), vec3(0.022,0.018,0.006) ));
		d = min(d,sdEllipsoid(np, vec3(-0.073,-0.145,0.048), vec3(0.021,0.017,0.006) ));
		if( d<res.x ) res = vec3(d,9.0,1.0);
	}

	
    // board
	//if( p.x<-0.2 )
	{
	vec3 bp = p - vec3(-0.695,-1.5,0.1 );
    bp.x = 0.15 + sqrt( bp.x*bp.x+0.0002 );
	d = sdEllipsoid( bp, vec3(0.0),vec3(0.65,1.8,0.1) );
	if( d<res.x ) res = vec3(d,6.0,1.0);
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

float calcAO( in vec3 pos, in vec3 nor, in int sampleID )
{
	float ao = 0.0;

	vec3 v = normalize(vec3(0.7,0.5,0.2));
	for( int i=ZERO; i<12; i++ )
	{
		float h = abs(sin(float(i+12*sampleID)));
		
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

		res = min( res, smoothstep(0.0,1.0,1.8*k*(h+0.001)/sqrt(t)) );
		
		t += clamp( h, 0.003, 0.1 );
		if( res<0.001 || t>0.8) break;
	}
	return clamp(res,0.0,1.0);
}

vec3 shade( in vec3 ro, in vec3 rd, in float t, in float m, in float matInfo, in int sampleID )
{
	vec3 pos = ro + t*rd;
	vec3 nor = calcNormalmap( pos, 0.0002 );
	

	vec3 mateD = vec3(0.0);
	vec2 mateK = vec2(0.0);
	float mateS = 0.0;
	vec3 mateSG = vec3(1.0);

	if( m<1.5 )
	{
		mateD = vec3(0.132,0.06,0.06);
		
		vec3 p = pos;
		float no = texture(iChannel0,p.xy).x;
		mateSG = vec3(0.75,0.97,1.0);
		mateK = vec2(0.08,0.5);
		mateS = 1.0;    
		mateK *= 0.5 + no;
	}
	else if( m<6.5 )
	{
        mateD = vec3(0.22,0.24,0.26);
		
		vec3 bp = pos - vec3(-0.695,-1.6,0.1 );

		mateD = mix( mateD, vec3(0.15,0.08,0.05), 1.0-smoothstep(0.003,0.01,abs(bp.x)) );
		
		float h = bp.y - 0.15*sin( 6.0*bp.x );
		h = min( abs(h-1.15)-0.04, abs(h-1.05)-0.01 );
		
		mateD = mix( mateD, vec3(0.004), 1.0-smoothstep( 0.01, 0.02, h ) );
		
		mateD *= 0.9 + 0.1*texture(iChannel0, 1.0*pos.xy ).x;
		mateS = 3.0;
		mateK = vec2(1.0,16.0);
		
		vec2 uv = pos.xy*0.1;
		float te = 0.0;
		float s = 0.5;
		for( int i=0; i<9; i++ )
		{
			te += s*texture(iChannel0,uv).x;
			uv *= 2.11;
			s *= 0.6;
		}
		mateD = mix( mateD, vec3(0.16,0.08,0.0)*0.27, 			0.15*smoothstep(0.6,0.9,te) );
		mateK.x *= 1.0-te;
		
		
	}
	else if( m<9.5 )
	{
		mateD = vec3(0.134,0.07,0.07);
		
		vec3 hp = pos - vec3(-0.945,-0.30,0.12);
		
		float r = length(hp.xy);
		r = min( r, length(hp.xy-vec2(0.0,-0.05)) );
		r = min( r, length(hp.xy-vec2(-0.02,-0.095)) );
		r = min( r, length(hp.xy-vec2(-0.048,-0.14)) );
		
		mateD += 0.023*(1.0 - smoothstep( 0.014,0.018,r));
		
		mateK = vec2(0.2,2.0);
		mateS = 1.0;
		
	}
	
	float fre = clamp(1.0+dot(nor,rd), 0.0, 1.0 );
	float occ = calcAO( pos, nor, sampleID );
	
	vec3 col = vec3(0.0);
	
    {
		// key
		float dif1 = dot(nor,sunDir);
		vec3 hal = normalize( sunDir-rd );
		float spe = pow(clamp(dot(hal,nor),0.0,1.0),0.001+8.0*mateK.y);

		float sha = calcSoftShadow( pos+nor*0.0005, sunDir, 24.0 ); 
        
        sha *= 0.15+0.85*smoothstep(0.1,0.3,length((pos-vec3(-0.45,0.16,0.1))*vec3(1.4,0.4,1.0)));
        
		float ssha = 1.0;
		if( abs(m-3.0)<0.2 ) { dif1=0.5*dif1+0.5; sha=0.95*sha+0.05; }
		if( abs(m-2.0)<0.2 ) { sha=clamp(0.2+sha*dif1*2.0,0.0,1.0); dif1=0.4+0.6*dif1; ssha=0.0; }
		
		dif1 = clamp(dif1,0.0,1.0);

		vec3 sha3 = vec3(sha,sha*0.4+0.6*sha*sha,sha*sha);
		
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
		col = shade( ro, rd, tm.x, tm.y, tm.z, sampleID );
	}

	float sun = clamp(0.5+0.5*dot( rd, sunDir ),0.0,1.0);
	col += 20.0*vec3(1.2,0.7,0.4)*pow(sun,8.0);

	col = pow( col, vec3(0.4545) );

	//col.z += 0.005;

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
		
	vec2 q = fragCoord.xy/iResolution.xy;
	col *= 0.3 + 0.7*pow(16.0*q.x*q.y*(1.0-q.x)*(1.0-q.y),0.1);

	fragColor = vec4( col, 1.0 );
}
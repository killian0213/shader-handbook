// Image (image) — Elephant by iq
// https://www.shadertoy.com/view/4dKGWm

// Copyright Inigo Quilez, 2016 - https://iquilezles.org/
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

float leg( in vec3 p, in vec3 pa, in vec3 pb, in vec3 pc, float m, float h )
{
    vec2 b = sdSegment( p, pa, pb );

    float tr = 0.35 - 0.16*smoothstep(0.0,1.0,b.y);
    float d3 = b.x - tr;

    b = sdSegment( p, pb, pc );
    tr = 0.18;
    d3 = smin( d3, b.x - tr, 0.1 );

    // paw        
    vec3 ww = normalize( mix( normalize(pc-pb), vec3(0.0,1.0,0.0), h) );
    mat3 pr = base( ww );
    vec3 fc = pr*((p-pc))-vec3(0.02,0.0,0.0)*(-1.0+2.0*h);
    float d4 = sdEllipsoid( fc, vec3(0.0), vec3(0.2,0.15,0.2) );

    d3 = smin( d3, d4, 0.1 );

    // nails
    float d6 = sdEllipsoid( fc, vec3(0.14,-0.06,0.0)*(-1.0+2.0*h), vec3(0.1,0.16,0.1));
    d6 = min( d6, sdEllipsoid( vec3(fc.xy,abs(fc.z)), vec3(0.13*(-1.0+2.0*h),-0.08*(-1.0+2.0*h),0.13), vec3(0.09,0.14,0.1)) );
    d3 = smin( d3, d6, 0.001 );
	return d3;
}

vec2 mapElephant( vec3 p, out vec3 matInfo )
{
    matInfo = vec3(0.0);
    
    p.x -= -0.5;
	p.y -= 2.4;
    
    vec3 ph = p;
    float cc = 0.995;
    float ss = 0.0998745;
    ph.yz = mat2(cc,-ss,ss,cc)*ph.yz;
    ph.xy = mat2(cc,-ss,ss,cc)*ph.xy;
    
    // head
    float d1 = sdEllipsoid( ph, vec3(0.0,0.05,0.0), vec3(0.45,0.5,0.3) );
    d1 = smin( d1, sdEllipsoid( ph, vec3(-0.3,0.15,0.0), vec3(0.2,0.2,0.2) ), 0.1 );

    // nose
    vec2 kk;
    vec2 b1 = sdBezier( vec3(-0.15,-0.05,0.0), vec3(-0.7,0.0,0.0), vec3(-0.7,-0.8,0.0), ph, kk );
    float tr1 = 0.30 - 0.17*smoothstep(0.0,1.0,b1.y);
    vec2  b2 = sdBezier( vec3(-0.7,-0.8,0.0), vec3(-0.7,-1.5,0.0), vec3(-0.4,-1.6,0.2), ph, kk );
    float tr2 = 0.30 - 0.17 - 0.05*smoothstep(0.0,1.0,b2.y);
    float bd1 = b1.x-tr1;
    float bd2 = b2.x-tr2;
    float nl = b1.y*0.5;
    float bd = bd1;
    if( bd2<bd1 )
    {
        nl = 0.5 + 0.5*b2.y;
        bd = bd2;
    }
    matInfo.x = clamp(nl * (1.0-smoothstep(0.0,0.2,bd)),0.0,1.0);
    float d2 = bd;
    float xx = nl*120.0;
    float ff = sin(xx + sin(xx + sin(xx + sin(xx))));
    //ff *= smoothstep(0.0,0.01,kk.y);
    d2 += 0.003*ff*(1.0-nl)*(1.0-nl)*smoothstep(0.0,0.1,nl);

    d2 -= (0.05 - 0.05*(1.0-pow(textureLod( iChannel0, vec2(1.0*nl,p.z*0.12), 0.0 ).x,1.0)))*nl*(1.0-nl)*0.5;
    
    float d = smin(d1,d2,0.2);

    // teeth
    vec3 q = vec3( p.xy, abs(p.z) );
    vec3 qh = vec3( ph.xy, abs(ph.z) );
    {
    vec2 s1 = sdSegment( qh, vec3(-0.4,-0.1,0.1), vec3(-0.5,-0.4,0.28) );
    float d3 = s1.x - 0.18*(1.0 - 0.3*smoothstep(0.0,1.0,s1.y));
    d = smin( d, d3, 0.1 );
    }
    
    // eyes
    {
    vec2 s1 = sdSegment( qh, vec3(-0.2,0.2,0.11), vec3(-0.3,-0.0,0.26) );
    float d3 = s1.x - 0.19*(1.0 - 0.3*smoothstep(0.0,1.0,s1.y));
    d = smin( d, d3, 0.03 );

    float st = length(qh.xy-vec2(-0.31,-0.02));
    //d += 0.005*sin(250.0*st)*exp(-110.0*st*st );
    d += 0.0015*sin(250.0*st)*(1.0-smoothstep(0.0,0.2,st));

        
    mat3 rot = mat3(0.8,-0.6,0.0,
                    0.6, 0.8,0.0,
                    0.0, 0.0,1.0 );
    float d4 = sdEllipsoid( rot*(qh-vec3(-0.31,-0.02,0.34)), vec3(0.0), vec3(0.1,0.08,0.07)*0.7 );
	d = smax(d, -d4, 0.02 );
    }
   

    // body
    {
    float co = cos(0.4);
    float si = sin(0.4);
    vec3 w = p;
    w.xy = mat2(co,si,-si,co)*w.xy;

    float d4 = sdEllipsoid( w, vec3(0.6,0.3,0.0), vec3(0.6,0.6,0.6) );
	d = smin(d, d4, 0.1 );

    d4 = sdEllipsoid( w, vec3(1.8,0.3,0.0), vec3(1.2,0.9,0.7) );
	d = smin(d, d4, 0.2 );

    d4 = sdEllipsoid( w, vec3(2.1,0.55,0.0), vec3(1.0,0.9,0.6) );
	d = smin(d, d4, 0.1 );

    d4 = sdEllipsoid( w, vec3(2.0,0.8,0.0), vec3(0.7,0.6,0.8) );
	d = smin(d, d4, 0.1 );
    }

    // back-left leg
    {
    float d3 = leg( q, vec3(2.6,-0.5,0.3), vec3(2.65,-1.45,0.3), vec3(2.6,-2.1,0.25), 1.0, 0.0 );
    d = smin(d,d3,0.1);
    }
    
	// tail
    #if 0
    {
    vec2 b = sdBezier( vec3(2.8,0.2,0.0), vec3(3.4,-0.6,0.0), vec3(3.1,-1.6,0.0), p, kk );
    float tr = 0.10 - 0.07*b.y;
    float d2 = b.x - tr;
    d = smin( d, d2, 0.05 );
    }
    #endif
        
    // front-left leg
    #if 0
    {
    float d3 = leg( q, vec3(0.8,-0.4,0.3), vec3(0.5,-1.55,0.3), vec3(0.5,-2.1,0.3), 1.0, 0.0 );
    d = smin(d,d3,0.15);
    }
    #else
    {
    float d3 = leg( p, vec3(0.8,-0.4,0.3), vec3(0.7,-1.55,0.3), vec3(0.8,-2.1,0.3), 1.0, 0.0 );
    d = smin(d,d3,0.15);
    d3 = leg( p, vec3(0.8,-0.4,-0.3), vec3(0.4,-1.55,-0.3), vec3(0.4,-2.1,-0.3), 1.0, 0.0 );
    d = smin(d,d3,0.15);
    }
    #endif
    
#if 1
    // ear
    float co = cos(0.5);
    float si = sin(0.5);
    vec3 w = qh;
    w.xz = mat2(co,si,-si,co)*w.xz;
    
    vec2 ep = w.zy - vec2(0.5,0.4);
    float aa = atan(ep.x,ep.y);
    float al = length(ep);
    w.x += 0.003*sin(24.0*aa)*smoothstep(0.0,0.5,dot(ep,ep));
    w.x += 0.02*textureLod( iChannel1, vec2(al*0.02,0.5+0.05*sin(aa)), 0.0 ).x * smoothstep(0.0,0.3,dot(ep,ep));
                      
    float r = 0.02*sin( 24.0*atan(ep.x,ep.y))*clamp(-w.y*1000.0,0.0,1.0);
    r += 0.01*sin(15.0*w.z);
    // section        
    float d4 = length(w.zy-vec2( 0.5,-0.2+0.03)) - 0.8 + r;    
    float d5 = length(w.zy-vec2(-0.1, 0.6+0.03)) - 1.5 + r;    
    float d6 = length(w.zy-vec2( 1.8, 0.1+0.03)) - 1.6 + r;    
    d4 = smax( d4, d5, 0.1 );
    d4 = smax( d4, d6, 0.1 );

    float wi = 0.02 + 0.1*pow(clamp(1.0-0.7*w.z+0.3*w.y,0.0,1.0),2.0);
    w.x += 0.05*cos(6.0*w.y);
    
    // cut it!
    d4 = smax( d4, -w.x, 0.03 ); 
    d4 = smax( d4, w.x-wi, 0.03 ); 
    
	matInfo.y = clamp(length(ep),0.0,1.0) * (1.0-smoothstep( -0.1, 0.05, d4 ));
    
    d = smin( d, d4, 0.3*max(qh.y,0.0)+0.0001 ); // trick -> positional smooth
    
    // conection hear/head
    vec2 s1 = sdBezier( vec3(-0.15,0.3,0.0), vec3(0.1,0.6,0.2), vec3(0.35,0.6,0.5), qh, kk );
    float d3 = s1.x - 0.08*(1.0-0.95*s1.y*s1.y);
    d = smin( d, d3, 0.05 );
    
#endif

    d -= 0.002*textureLod( iChannel1, 0.5*p.yz, 0.0 ).x;
    d -= 0.002*textureLod( iChannel1, 0.5*p.yx, 0.0 ).x;
    d += 0.003;
    d -= 0.005*textureLod( iChannel0, 0.5*p.yx, 0.0 ).x*(0.2 + 0.8*smoothstep( 0.8, 1.3, length(p-vec3(-0.5,0.0,0.0)) ));

    
    vec2 res = vec2(d,0.0);
	//=====================
    // teeth
    vec2 b = sdBezier( vec3(-0.5,-0.4,0.28), vec3(-0.5,-0.7,0.32), vec3(-1.0,-0.8,0.45), qh, kk );
    float tr = 0.10 - 0.08*b.y;
    d2 = b.x - tr;
    if( d2<res.x ) 
    {
        res = vec2( d2, 1.0 );
        matInfo.x = b.y;
    }
	//------------------
    //eyeball
    mat3 rot = mat3(0.8,-0.6,0.0,
                    0.6, 0.8,0.0,
                    0.0, 0.0,1.0 );
    d4 = sdEllipsoid( rot*(qh-vec3(-0.31,-0.02,0.33)), vec3(0.0), vec3(0.1,0.08,0.07)*0.7 );
    if( d4<res.x ) res = vec2( d4, 2.0 );

    return res;
}

float sleg( in vec3 p, in vec3 pa, in vec3 pb, in vec3 pc, float m, float h, float sc )
{
    vec2 b = sdSegment( p, pa, pb );

    float tr = 0.35 - 0.15*smoothstep(0.0,1.0,b.y);
    float d3 = b.x - tr*sc;

    b = sdSegment( p, pb, pc );
    tr = 0.18;// - 0.015*smoothstep(0.0,1.0,b.y);
    d3 = smin( d3, b.x - tr*sc, 0.1 );

    // paw        
    vec3 ww = normalize( mix( normalize(pc-pb), vec3(0.0,1.0,0.0), h) );
    mat3 pr = base( ww );
    vec3 fc = pr*((p-pc))-vec3(0.02,0.0,0.0)*(-1.0+2.0*h);
    float d4 = sdEllipsoid( fc, vec3(0.0), vec3(0.2,0.15,0.2) );

    d3 = smin( d3, d4, 0.1 );

    // nails
    float d6 = sdEllipsoid( fc, vec3(0.14,-0.04,0.0)*(-1.0+2.0*h), vec3(0.1,0.16,0.1));
    d6 = min( d6, sdEllipsoid( vec3(fc.xy,abs(fc.z)), vec3(0.13*(-1.0+2.0*h),0.04,0.13), vec3(0.09,0.14,0.1)) );
    d3 = smin( d3, d6, 0.001 );
	return d3;

	return d3;
}

vec2 mapSmallElephant( vec3 p, out vec3 matInfo )
{
    matInfo = vec3(0.0);
    vec3 oop = p;
    const float sca = 2.0;
    p.xz = mat2(0.8,0.6,-0.6,0.8)*p.xz;
    p *= sca;
    
    p -= vec3(-1.1,2.4,-2.0);
        
    vec3 ph = p;
    ph.yz = mat2(0.95,0.31225,-0.31225,0.95)*ph.yz;
        
    // head
    float d1 = sdEllipsoid( ph, vec3(0.0,0.0,0.0), vec3(0.45,0.55,0.38) );

    // nose
    vec2 kk;
    
    vec2 b1 = sdBezier( vec3(-0.15,-0.05,0.0), vec3(-0.7,-0.2,-0.1), vec3(-0.7,-0.5,0.1), ph, kk );    
    float tr1 = 0.30 - 0.17*smoothstep(0.0,1.0,b1.y);
    vec2 b2 = sdBezier( vec3(-0.7,-0.5,0.1), vec3(-0.7,-0.8,0.3), vec3(-0.4,-0.8,0.8), ph, kk );
    
    float tr2 = 0.30 - 0.17 - 0.05*smoothstep(0.0,1.0,b2.y);
    float bd1 = b1.x-tr1;
    float bd2 = b2.x-tr2;
    float nl = b1.y*0.5;
    float bd = bd1;
    if( bd2<bd1 )
    {
        nl = 0.5 + 0.5*b2.y;
        bd = bd2;
    }
    
    matInfo.x = clamp(nl * (1.0-smoothstep(0.0,0.2,bd)),0.0,1.0);
            
    float d2 = bd;
    float xx = nl*120.0;
    float ff = sin(xx + sin(xx + sin(xx + sin(xx))));
    d2 += 0.005*ff*(1.0-nl)*(1.0-nl)*smoothstep(0.0,0.1,nl);

    float d = smin(d1,d2,0.2);

    vec3 qh = vec3( ph.xy, abs(ph.z) );

    // eyes
    {
    vec2 s1 = sdSegment( qh, vec3(-0.2,0.2,0.11), vec3(-0.3,-0.0,0.23) );
    float d3 = s1.x - 0.19*(1.0 - 0.3*smoothstep(0.0,1.0,s1.y));
    d = smin( d, d3, 0.03 );
    mat3 rot = mat3(0.8,-0.6,0.0,
                    0.6, 0.8,0.0,
                    0.0, 0.0,1.0 );
    float d4 = sdEllipsoid( rot*(qh-vec3(-0.31,-0.02,0.34)), vec3(0.0), vec3(0.1,0.08,0.07)*0.7 );
	d = smax(d, -d4, 0.04 );
    }


    vec3 q = vec3( p.xy, abs(p.z) );

    // body
    {
    float co = cos(0.4);
    float si = sin(0.4);
    vec3 w = p;
    w.xy = mat2(co,si,-si,co)*w.xy;
        
    float d4 = sdEllipsoid( w, vec3(0.6,0.3,0.0), vec3(0.6,0.6,0.6) );
	d = smin(d, d4, 0.1 );

    d4 = sdEllipsoid( w, vec3(1.8,0.3,0.0), vec3(1.2,0.9,0.7) );
	d = smin(d, d4, 0.2 );
    }

    // back-left leg
    {
    float d3 = sleg( q, vec3(2.6,-0.6,0.3), vec3(2.65,-1.4,0.3), vec3(2.6,-2.0,0.25), 1.0, 0.0, 0.75 );
    d = smin(d,d3,0.1);
    }
    
	// tail
    #if 0
    {
    vec2 b = sdBezier( vec3(2.6,0.,0.0), vec3(3.4,-0.6,0.0), vec3(3.1,-1.6,0.0), p, kk );
    float tr = 0.10 - 0.07*b.y;
    float d2 = b.x - tr;
    d = smin( d, d2, 0.05 );
    }
    #endif
    
    // front-left leg
    {
    float d3 = sleg( p, vec3(0.8,-0.4,0.2), vec3(0.6,-1.4,0.2), vec3(0.7,-1.9,0.2), 1.0, 0.0, 0.75 );
    d = smin(d,d3,0.15);
    d3 = sleg( p, vec3(0.8,-0.4,-0.2), vec3(0.3,-1.4,-0.2), vec3(0.2,-1.9,-0.2), 1.0, 0.0, 0.75 );
    d = smin(d,d3,0.15);
    }
            
#if 1
    // ear
    float co = cos(0.5);
    float si = sin(0.5);
    vec3 w = qh;
    w.xz = mat2(co,si,-si,co)*w.xz;
    
    vec2 ep = w.zy - vec2(0.5,0.4);
    float aa = atan(ep.x,ep.y);
    float al = length(ep);
    w.x += 0.003*sin( 24.0*aa)*smoothstep(0.0,0.5,dot(ep,ep));
    w.x += 0.02*textureLod( iChannel1, vec2(al*0.02,0.15*aa/3.1416), 0.0 ).x * smoothstep(0.0,0.3,dot(ep,ep));
                      
    float r = 0.02*sin( 24.0*atan(ep.x,ep.y))*clamp(-w.y*1000.0,0.0,1.0);
    r += 0.01*sin(15.0*w.z);
    // section        
    float d4 = length(w.zy-vec2( 0.5,-0.2+0.03)) - 0.8 + r;    
    float d5 = length(w.zy-vec2(-0.1, 0.6+0.03)) - 1.5 + r;    
    float d6 = length(w.zy-vec2( 1.8, 0.1+0.03)) - 1.6 + r;    
    d4 = smax( d4, d5, 0.1 );
    d4 = smax( d4, d6, 0.1 );

    float wi = 0.02 + 0.1*pow(clamp(1.0-0.7*w.z+0.3*w.y,0.0,1.0),2.0);
    w.x += 0.05*cos(6.0*w.y);
    
    // cut it!
    d4 = smax( d4, -w.x, 0.03 ); 
    d4 = smax( d4, w.x-wi, 0.03 ); 
    
	matInfo.y = clamp(length(ep),0.0,1.0) * (1.0-smoothstep( -0.1, 0.05, d4 ));
    
    d = smin( d, d4, 0.3*max(qh.y+0.2,0.0)+0.0001 ); // trick -> positional smooth
    
    // conection hear/head
    vec2 s1 = sdBezier( vec3(-0.15,0.3,0.0), vec3(0.1,0.6,0.2), vec3(0.35,0.6,0.5), qh, kk );
    float d3 = s1.x - 0.08*(1.0-0.95*s1.y*s1.y);
    d = smin( d, d3, 0.05 );
    
#endif
    
    d -= 0.008*textureLod( iChannel1, 0.25*p.yz, 0.0 ).x;
    d -= 0.008*textureLod( iChannel1, 0.25*p.yx, 0.0 ).x;
    d += 0.010;
    d -= 0.012*textureLod( iChannel0, 0.25*p.yx, 0.0 ).x*(0.3 + 0.7*smoothstep( 0.5, 1.0, length(p-vec3(-0.5,0.0,0.0)) ));
    
    vec2 res = vec2(d,0.0);
	//=====================
    //eyeball
    mat3 rot = mat3(0.8,-0.6,0.0,
                    0.6, 0.8,0.0,
                    0.0, 0.0,1.0 );
    d4 = sdEllipsoid( rot*(qh-vec3(-0.31,-0.02,0.33)), vec3(0.0), vec3(0.1,0.08,0.07)*0.7 );
    
    if( d4<res.x ) res = vec2( d4, 2.0 );

    res.x /= sca;
        
    return res;
}

vec2 map( vec3 p, out vec3 matInfo )
{
    vec2 res = vec2(p.y+2.2-1.0);
    
    // bounding volume for big elephant
    //float b2 = length(p-vec3(0.5,1.7,0.0))-2.1;
	//if( b2<res.x )    
    {
        res = mapElephant( p, matInfo );
    }
    
    // bounding volume for small elephant
    float bb = length(p-vec3(-0.4,0.5,-0.8))-1.3;
    if( bb<res.x )
    {
        vec3 mi2;
        vec2 tmp = mapSmallElephant( p, mi2 );
        if( tmp.x<res.x ) { res=tmp; matInfo=mi2; }
    }
    
    return res;
}

vec2 mapWithTerrain( vec3 p, out vec3 matInfo )
{
    vec2 res = map(p,matInfo);
        
    //--------------------
    // terrain
    float h = 2.1+0.1;
    float d2 = p.y + h;
    if( d2<res.x ) res = vec2( d2, 3.0 );
    
    return res;
}

// https://iquilezles.org/articles/normalsSDF
vec3 calcNormal( in vec3 pos, in float eps )
{
    vec3 kk;
#if 0    
    vec2 e = vec2(1.0,-1.0)*0.5773*eps;
    return normalize( e.xyy*map( pos + e.xyy, kk ).x + 
					  e.yyx*map( pos + e.yyx, kk ).x + 
					  e.yxy*map( pos + e.yxy, kk ).x + 
					  e.xxx*map( pos + e.xxx, kk ).x );
#else
    // inspired by tdhooper and klems - a way to prevent the compiler from inlining map() 4 times
    vec3 n = vec3(0.0);
    for( int i=ZERO; i<4; i++ )
    {
        vec3 e = 0.5773*(2.0*vec3((((i+3)>>1)&1),((i>>1)&1),(i&1))-1.0);
        n += e*map(pos+e*eps,kk).x;
    }
    return normalize(n);
#endif    
}

// https://iquilezles.org/articles/rmshadows
float calcSoftShadow( in vec3 ro, in vec3 rd, float k )
{
    vec3 kk;
    float res = 1.0;
    float t = 0.01;
    for( int i=0; i<32; i++ )
    {
        float h = map(ro + rd*t, kk ).x;
        res = min( res, k*h/t );
        t += clamp( h, 0.05, 0.5 );
		if( res<0.01 ) break;
    }
    return smoothstep(0.0,1.0,res);
}

float calcAO( in vec3 pos, in vec3 nor )
{
    vec3 kk;
	float ao = 0.0;
    for( int i=ZERO; i<32; i++ )
    {
        vec3 ap = forwardSF( float(i), 32.0 );
        ap *= sign( dot(ap,nor) );
        float h = hash1(float(i));
		ap *= h*0.3;
        ao += clamp( mapWithTerrain( pos + nor*0.01 + ap, kk ).x*1.0/h, 0.0, 1.0 );
    }
	ao /= 32.0;
	
    return clamp( ao*4.0*(1.0+0.25*nor.y), 0.0, 1.0 );
}

const vec3 sunDir = normalize( vec3(0.15,0.7,0.65) );

float dapples( in vec3 ro, in vec3 rd )
{
    float sha = eliSoftShadow( ro, rd, vec3(0.0,4.0,4.0), vec3(3.0,1.0,3.0), 70.0 );
    
    vec3 uu = normalize( cross( rd, vec3(0.0,0.0,1.0) ) );
    vec3 vv = normalize( cross( uu, rd ) );

    vec3 ce = vec3(0.0,4.0,5.0);
    float t = -dot(ro-ce,rd);
    vec3 po = ro + t*rd;
    vec2 uv = vec2( dot(uu,po-ce), dot(vv,po-ce) );
    
    float dap = 1.0-smoothstep( 0.1, 0.5, texture(iChannel2,0.25+0.4*uv,-100.0).x );
    return 1.0 - 0.9*(1.0-sha)*(1.0-dap);
}

// https://iquilezles.org/articles/filteringrm
void calcDpDxy( in vec3 ro, in vec3 rd, in vec3 rdx, in vec3 rdy, in float t, in vec3 nor, out vec3 dpdx, out vec3 dpdy )
{
    dpdx = t*(rdx*dot(rd,nor)/dot(rdx,nor) - rd);
    dpdy = t*(rdy*dot(rd,nor)/dot(rdy,nor) - rd);
}

vec3 shade( in vec3 ro, in vec3 rd, in float t, in float m, in vec3 matInfo, in vec3 rdx, in vec3 rdy )
{
    float eps = 0.001;
    
    vec3 pos = ro + t*rd;
    vec3 nor = calcNormal( pos, eps*t );
    vec3 dposdx, dposdy;
    calcDpDxy( ro, rd, rdx, rdy, t, nor, dposdx, dposdy );

    float kk;

    vec3 mateD = vec3(0.2,0.16,0.11);
    vec3 mateS = vec3(0.2,0.12,0.07);
    vec3 mateK = vec3(0.0,1.0,0.0); // amount, power, metalic
    float focc = 1.0;
        
    if( m<0.5 ) // body
    {
        mateD = vec3(0.27,0.26,0.25)*0.4;
        mateS = vec3(0.27,0.26,0.25)*0.4;
        mateK = vec3(0.12,20.0,0.0);
        
        float te = texcube( iChannel1, 0.25*pos, nor, 4.0, 0.25*dposdx, 0.25*dposdy ).x;
        mateD *= 0.2+0.6*te;
        mateK *= te;
        
        mateD *= 1.1 - 0.4*smoothstep( 0.3, 0.7, matInfo.x );
        mateD = mix( mateD, mateD*vec3(1.1,0.8,0.7), smoothstep( 0.0, 0.15, matInfo.y ) );

        focc *= 0.5 + 0.5*smoothstep(0.0,3.0,pos.y);
                   
        vec3 q = pos - vec3(-0.5,2.4,0.0);

        //---
        vec2 est = q.xy-vec2(-0.31,-0.02);
        mateD *= mix( vec3(1.0), vec3(0.2,0.15,0.1), exp(-20.0*dot(est,est)) );

        mateD *= 1.2;
        mateS *= 1.2;
        mateK.x *= 1.2;
        
        mateK.xy *= vec2(3.0,2.0);
    }
    else if( m<1.5 ) // teeh
    {
        mateD = vec3(0.3,0.28,0.25)*0.9;
        mateS = vec3(0.3,0.28,0.25)*0.9;
        mateK = vec3(0.2,32.0,0.0);
        mateD *= mix( vec3(0.45,0.4,0.35), vec3(1.0), sqrt(matInfo.x) );
        focc = smoothstep(0.1,0.3,matInfo.x);
        float te = texcube( iChannel1, 0.5*pos, nor, 4.0, 0.5*dposdx, 0.5*dposdy ).x;
        mateD *= te;
        mateK.x *= te;
    }
    else //if( m<2.5 ) //eyeball
    {
        mateD = vec3(0.0);
        mateS = vec3(0.0);
        mateK = vec3(0.4,32.0,0.0);
    }
    
    vec3 hal = normalize( sunDir-rd );
    float fre = clamp(1.0+dot(nor,rd), 0.0, 1.0 );
    float occ = calcAO( pos, nor )*focc;
        
    float dif1 = dot(nor,sunDir);
    if( dif1>0.001 )
    {
    float sha = calcSoftShadow( pos, sunDir, 16.0 );
    sha = min( sha, dapples(pos,sunDir) );
    dif1 *= sha;
    }
    dif1 = clamp( dif1, 0.0, 1.0 );

    float spe1 = clamp( dot(nor,hal), 0.0, 1.0 );
    float bak = clamp( dot(nor,normalize(vec3(-sunDir.x,0.0,-sunDir.z))), 0.0, 1.0 );
    float bou = clamp( 0.3-0.7*nor.y, 0.0, 1.0 );
    float rod1 = 1.0 - (1.0-smoothstep( 0.15,0.2, length(pos.yz-vec2(1.8,0.3))))*(1.0-smoothstep(0.0,0.1,abs(pos.x+0.2)));

    
    // sun
    vec3 col = 8.5*vec3(2.0,1.2,0.65)*dif1;
    // sky
    col += 4.5*vec3(0.35,0.7,1.0)*occ*clamp(0.2+0.8*nor.y,0.0,1.0);
    // ground
    col += 4.0*vec3(0.4,0.25,0.12)*bou*occ;
    // back
    col += 3.5*vec3(0.2,0.2,0.15)*bak*occ*rod1;
    // sss
    col += 25.0*fre*fre*(0.2+0.8*dif1*occ)*mateS*rod1;

    // sun
    vec3 hdir = normalize(sunDir - rd);
    float costd = clamp( dot(sunDir, hdir), 0.0, 1.0 );
    float spp = pow( spe1, mateK.y )*dif1*mateK.x * (0.04 + 0.96*pow(1. - costd,5.0));

    // sky spec
    float sksp = occ*occ*smoothstep(-0.2,0.2,reflect(rd,nor).y)*(0.5+0.5*nor.y)*mateK.x * (0.04 + 0.96*pow(fre,5.0));

    col += mateK.z*15.0*5.0*spp; 

    col *= mateD;

    col += (1.0-mateK.z)*75.0*spp; 
    col += (1.0-mateK.z)* 3.0*sksp*vec3(0.35,0.7,1.0); 

    return col;        
}

vec2 raycast( in vec3 ro, in vec3 rd, in float tmax, out vec3 matInfo )
{
    vec2 res = vec2(-1.0);

    float maxdist = min(tmax,10.0);
    float t = 4.0;

#if 1
    // this bounding cylinder only covers the front half of the
    // elephant, but because of the camera direction, in perspective
    // it also covers the back side. For a different camera direction
    // the true bounding cylinder should be used.
    vec2 bb = iCylinderY(ro,rd,vec4(-0.1,0.0,-0.2,1.45));
    if( bb.y<0.0 ) return res;
    if( bb.x>0.0 ) t = max(t,bb.x);
    //maxdist = min(maxdist,bb.y); // enable only when using the true bounding cylinder
#endif

    for( int i=0; i<128; i++ )
    {
        vec3 p = ro + t*rd;
        vec2 h = map( p, matInfo );
        res = vec2(t,h.y);
        if( h.x<(0.0001*t) || t>maxdist ) break;
        t += h.x;//*0.75;
    }

    if( t>maxdist )
    {
        res = vec2(-1.0);
    }

    return res;
}

vec3 render( in vec3 ro, in vec3 rd, in vec3 col, in float tmax, in vec3 rdx, in vec3 rdy )
{
    vec3 matInfo;
    vec2 tm = raycast( ro, rd, tmax, matInfo );
    if( tm.y>-0.5  )
    {
        col = shade( ro, rd, tm.x, tm.y, matInfo, rdx, rdy );
        float fa = 1.0-exp(-0.0001*(tm.x*tm.x+tm.x));
        col = mix( col, vec3(0.4,0.5,0.65), fa );
    }
	return col;    
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{	
    vec2 q = fragCoord/iResolution.xy;
    vec2 p = (2.0*fragCoord-iResolution.xy)/iResolution.y;

    // camera
    float an = 0.025*sin(0.5*iTime) - 1.25;
    vec3 ro = vec3(5.7*sin(an),1.6,5.7*cos(an));
    vec3 ta = vec3(0.0,1.6,0.0);

    // ray
    mat3 ca = setCamera( ro, ta, 0.0 );
    vec3 rd = normalize( ca * vec3(p,-3.5) );

    // ray differentials
    // https://iquilezles.org/articles/filteringrm
    vec2 px = (2.0*(fragCoord+vec2(1.0,0.0))-iResolution.xy)/iResolution.y;
    vec2 py = (2.0*(fragCoord+vec2(0.0,1.0))-iResolution.xy)/iResolution.y;
    vec3 rdx = normalize( ca * vec3(px,-3.5) );
    vec3 rdy = normalize( ca * vec3(py,-3.5) );
    
    // red background
    vec4 data = texture( iChannel3, q );
    vec3 col = data.xyz;
    float t = data.w;

    // render
    col = render( ro, rd, col, t, rdx, rdy);

    // sun
    float sun = clamp( 0.5 + 0.5*dot(rd,sunDir), 0.0, 1.0 );
    col += 1.5*vec3(1.0,0.8,0.6)*pow(sun,16.0);

    // gamma
    col = pow(col,vec3(0.4545));
    
    // color grade
    col.x += 0.010;
    
    // vignette
    col *= 0.3 + 0.7*pow(16.0*q.x*q.y*(1.0-q.x)*(1.0-q.y),0.1);
    fragColor = vec4( col, 1.0 );
}

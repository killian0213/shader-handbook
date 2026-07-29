// Buffer A (buffer) — Elephant by iq
// https://www.shadertoy.com/view/4dKGWm

// Copyright Inigo Quilez, 2016 - https://iquilezles.org/
// I am the sole copyright owner of this Work.
// You cannot host, display, distribute or share this Work in any form,
// including physical and digital. You cannot use this Work in any
// commercial or non-commercial product, website or project. You cannot
// sell this Work and you cannot mint an NFTs of it.
// I share this Work for educational purposes, and you can link to it,
// through an URL, proper attribution and unmodified screenshot, as part
// of your educational material. If these conditions are too restrictive
// please contact me and we'll definitely work it out.

#define USE_REPROJECTION

float leg( in vec3 p, in vec3 pa, in vec3 pb, in vec3 pc, float m, float h, float sc )
{
    vec2 b = sdSegment( p, pa, pb );

    float tr = 0.35 - 0.16*smoothstep(0.0,1.0,b.y);
    float d3 = b.x - tr*sc;

    b = sdSegment( p, pb, pc );
    tr = 0.18;
    d3 = smin( d3, b.x - tr*sc, 0.1 );

    vec3 ww = normalize( mix( normalize(pc-pb), vec3(0.0,1.0,0.0), h) );
    mat3 pr = base( ww );
    vec3 fc = pr*((p-pc))-vec3(0.02,0.0,0.0)*(-1.0+2.0*h);
    float d4 = sdEllipsoid( fc, vec3(0.0), vec3(0.2,0.15,0.2) );

    d3 = smin( d3, d4, 0.1 );

	return d3;
}

float mapElephantSimple( vec3 p )
{
    p.x -= -0.5;
	p.y -= 2.4;
    
    // head
    float d = sdEllipsoid( p, vec3(0.0,0.0,0.0), vec3(0.55,0.55,0.35) );


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
    vec3 q = vec3( p.xy, abs(p.z) );

    // back-left leg
    {
    float d3 = leg( q, vec3(2.6,-0.6,0.3), vec3(2.65,-1.45,0.3), vec3(2.6,-2.1,0.25), 1.0, 0.0, 1.0 );
    d = smin(d,d3,0.1);
    }

    
    // front-left leg
    float d3 = leg( p, vec3(0.8,-0.4,0.3), vec3(0.7,-1.55,0.3), vec3(0.8,-2.1,0.3), 1.0, 0.0, 1.0 );
    d = smin(d,d3,0.15);
    d3 = leg( p, vec3(0.8,-0.4,-0.3), vec3(0.4,-1.55,-0.3), vec3(0.4,-2.1,-0.3), 1.0, 0.0, 1.0 );
    d = smin(d,d3,0.15);
    
    return d;
}

float mapTree( vec3 p )
{
    float f = length(p);
    if( f>8.0 )
        return f - 8.0 + 0.1;

    vec3 q = p;   
    
    p.xz += 0.1*sin(4.0*p.y+vec2(0.0,1.0));
    vec2 s1 = sdSegment( p, vec3(0.0,-2.0,0.0), vec3(-2.0,3.3,4.0) );
    float d2 = s1.x - (0.25 - 0.12*s1.y);
    s1 = sdSegment( p, vec3(0.0,-2.0,0.0), vec3(-3.0,3.3,0.0) );
    float d4 = s1.x - (0.25 - 0.12*s1.y);
    d2 = min( d2, d4 );
    s1 = sdSegment( p, mix( vec3(0.0,-2.0,0.0), vec3(-3.0,3.3,-1.0), 0.35 ), vec3(-2.0,3.3,-4.0) );
    d4 = s1.x - (0.25 - 0.12*s1.y);
    d2 = min( d2, d4 );
    
    p.y += length(p.xz)*0.1;
    p.y += 0.5*sin(p.x);
    
    float nn = textureLod(iChannel2,0.1*q.zy, 0.0).x;
    d4 = sdEllipsoid( p, vec3( 0.0,3.3,0.0), vec3(4.5,0.9,4.5)*(1.0+nn) );
    
    d4 += max(0.0,3.0*sin(1.5*q.x)*sin(1.5*q.y)*sin(1.5*q.z)*clamp( 1.0 - d4/3.0, 0.0, 1.0 ));

    return min( d2, d4 );
}

mat3 rotationMat( in vec3 xyz )
{
    vec3 si = sin(xyz);
    vec3 co = cos(xyz);

	return mat3( co.y*co.z,                co.y*si.z,               -si.y,    
                 si.x*si.y*co.z-co.x*si.z, si.x*si.y*si.z+co.x*co.z, si.x*co.y,
                 co.x*si.y*co.z+si.x*si.z, co.x*si.y*si.z-si.x*co.z, co.x*co.y );
}

vec2 map( vec3 p, out vec3 matInfo )
{
    matInfo = vec3(0.0);
    
    p.x -= -0.5;
	p.y -= 2.4;
    
    //--------------------
    // ground
    //--------------------
    
    float h = 2.1 + 0.1*textureLod( iChannel2, 0.07*p.xz, 0.0 ).x;
    float d2 = p.y + h;
    vec2 res = vec2( d2, 3.0 );

    
    //--------------------
    // leaves
    //--------------------
#if 1
    for( int j=ZERO; j<2; j++ )
    {
        float dleaves = 1000.0;

        vec3         pl = p - vec3(-0.85,0.30,2.1);
        vec3         pd = vec3(-0.2,-0.5,-0.3);
        if( j==1 ) { pl = p - vec3(-0.00,0.45,2.2);
                     pd = vec3( 0.2,-0.6, 0.1); };
        
        float pr = dot(pl,pl);
        if( sqrt(pr)-1.5<res.x && pr<1.5 )
        {
            float sim = 1.0;
            vec2 uv = vec2(0.0);
            for( int i=ZERO; i<9; i++ )
            {
                float h = float(i);
                float hh = float(i+10*j);
                vec3 sc = hash3(hh*13.92);
                vec3 di = sin(vec3(0.0,1.0,2.0)+hh*vec3(10.0,15.0,20.0));
                vec3 of = pd*h/8.0;

                vec3 q = pl - of;
                q = rotationMat( 6.2831*di*vec3(0.1,-0.1,0.9) + 0.04*sin(20.0*hh + 0.7*iTime) ) * q;

                q.z = q.z*sim - 0.22;

                q.xz += q.y*q.y*2.0;

                q *= 0.75 + 0.4*sc.x;

                d2 =          sdSphere( q, vec3(0.0,-0.1,0.0), 0.25 );
                d2 = max( d2, sdSphere( q, vec3(0.0, 0.1,0.0), 0.25 ) );
                d2 = smax( d2, abs(q.x)-0.003, 0.01 );

                d2 /= 0.75 + 0.4*sc.x;

                if( d2<dleaves )
                {
                    dleaves = d2;
                    uv = q.yz;
                }
                sim *= -1.0;
            }
            vec2 s2 = sdSegment( pl, vec3(0.0), pd );
            d2 = s2.x - 0.01;
            dleaves = min(dleaves,d2); 
            if( dleaves<res.x ) 
            {
                res = vec2( dleaves, 6.0 );
                matInfo.x = 0.0;
                matInfo.yz = uv;
            }
        }
    }
#endif

    //--------------------
    // bushes
    //--------------------
    
#if 1
    float bb = max( -(p.x-18.0), p.y+0.4 );
    if( bb<res.x )
    {
    vec2 idb = floor(p.xz/4.0);        
    //for( int j=ZERO; j<2; j++ )    
    //for( int i=ZERO; i<2; i++ )    
    {
        vec2 id = idb;// + vec2(float(i),float(j));
        if( id.x>4.0 )
        {
            float h = id.x*7.7 + id.y*13.1;
            float si = hash1(h*31.7);
            float al = hash1(h*41.9);

            if( si>0.5 )
            {
                vec3 bc = vec3(id.x*4.0+2.0,-2.0,id.y*4.0+2.0);
                bc.xz -= 1.0*hash3( h*7.7 ).xy;
                vec3 eli = vec3(1.6*(0.3 + 0.7*si),1.5*(0.5 + 0.5*al),1.6*(0.3 + 0.7*si));

                #if 0
                d2 = sdEllipsoid( p, bc, eli );
                if( d2<res.x ) 
                {
                    res = vec2( d2, 4.0 );
                    matInfo.x = hash1(h*77.7);
                }

                #else
                float d4 = 1000.0;
                float d3 = 0.0;
                for( int j=0; j<12; j++ )
                {
                    float h2 = float(j);
                    vec3 of = normalize((-1.0+2.0*hash3(h*11.11+h2*9.13)));

                    of.y = of.y*of.y - 0.1;
                    of *= eli;

                    vec3 bb = bc + of;
                    d2 = sdEllipsoid( p, bb, 0.5*vec3(1.0,0.85,1.0));

                    if( d2<d4)
                    {
                        d4 = d2;
                        d3 = hash1(h*77.7);
                    }
                }

                float di = textureLod(iChannel2,0.06*p.yz,0.0).x +
                           textureLod(iChannel2,0.06*p.xy,0.0).x;
                di /= 2.0;
                d4 -= 0.4*di*di;

                if( d4<res.x ) 
                {
                    res = vec2( d4, 4.0 );
                    matInfo.x = d3;
                    matInfo.y = di;
                }
                #endif
            }
        }
    }
    }
#endif    

    //--------------------
    // trees
    //--------------------
     
#if 1
    {
    const vec3 tc1 = vec3(50.0,0.0,-40.0);
    const vec3 tc2 = vec3(85.0,0.0,5.0);
    float td1 = dot(p.xz-tc1.xz,p.xz-tc1.xz);
    float td2 = dot(p.xz-tc2.xz,p.xz-tc2.xz);
    vec3 tc = (td1<td2) ? tc1 : tc2;
    bb = length(p-tc)-8.0;
    if( bb<res.x )
    {
    float d2 = mapTree( p - tc );
    if( d2<res.x ) 
    {
        res = vec2( d2, 5.0 );
        matInfo.x = 0.0;
    }
    }
    }
#endif

    return res;
}

float mapSmallElephantSimple( vec3 p )
{
    const float sca = 2.0;
    p.xz = mat2(0.8,0.6,-0.6,0.8)*p.xz;
    p *= sca;
    
    p -= vec3(-1.1,2.4,-2.0);
    
    vec3 ph = p;
    ph.yz = mat2(0.95,0.31225,-0.31225,0.95)*ph.yz;
        
    // head
    float d = sdEllipsoid( ph, vec3(0.0,0.0,0.0), vec3(0.45,0.55,0.35) );

    vec3 qh = vec3( ph.xy, abs(ph.z) );

    vec3 q = vec3( p.xy, abs(p.z) );

    // body
    {
    float co = cos(0.4);
    float si = sin(0.4);
    vec3 w = p;
    w.xy = mat2(co,si,-si,co)*w.xy;
        
    float d4 = sdEllipsoid( w, vec3(1.8,0.3,0.0), vec3(1.2,0.9,0.7) );
	d = smin(d, d4, 0.2 );

    }

    // back-left leg
    {
    float d3 = leg( q, vec3(2.6,-0.6,0.3), vec3(2.65,-1.4,0.3), vec3(2.6,-2.0,0.25), 1.0, 0.0, 0.75  );
    d = smin(d,d3,0.1);
    }
    
    
    // front-left leg
    {
    float d3 = leg( p, vec3(0.8,-0.4,0.2), vec3(0.6,-1.4,0.2), vec3(0.7,-1.9,0.2), 1.0, 0.0, 0.75 );
    d = smin(d,d3,0.15);
    d3 = leg( p, vec3(0.8,-0.4,-0.2), vec3(0.3,-1.4,-0.2), vec3(0.2,-1.9,-0.2), 1.0, 0.0, 0.75 );
    d = smin(d,d3,0.15);

    }
    
    return d/sca;
}

float mapWithElephants( vec3 p )
{
    vec3 kk;
    float res = map( p, kk ).x;

    res = min( res, mapElephantSimple(p) );
    res = min( res, mapSmallElephantSimple(p) );

    return res;
}

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
    // trick by klems, to prevent the compiler from inlining map() 4 times
    vec4 n = vec4(0.0);
    for( int i=ZERO; i<4; i++ )
    {
        vec4 s = vec4(pos, 0.0);
        s[i] += eps*0.25;
        n[i] = map(s.xyz,kk).x;
    }
    return normalize(n.xyz-n.w);
#endif    
}

// https://iquilezles.org/articles/rmshadows
float calcSoftShadow( in vec3 ro, in vec3 rd, float k )
{
    float res = 1.0;
    float t = 0.01;
    for( int i=0; i<24; i++ )
    {
        float h = mapWithElephants(ro + rd*t );
        res = min( res, smoothstep(0.0,1.0,k*h/t) );
        t += clamp( h, 0.05, 0.5 );
		if( res<0.01 ) break;
    }
    return clamp(res,0.0,1.0);
}

float calcAO( in vec3 pos, in vec3 nor )
{
	float ao = 0.0;
    for( int i=ZERO; i<8; i++ )
    {
        vec3 ap = forwardSF( float(i), 8.0 );
        float h = hash1(float(i));
        float dk = dot(ap,nor); if( dk<0.0 ) ap -= 2.0*nor*dk;
        ap *= h*0.3;
        ao += clamp( mapWithElephants( pos + nor*0.01 + ap )*2.4, 0.0, 1.0 );
    }
	ao /= 8.0;
	
    return clamp( ao*4.0*(1.0+0.25*nor.y), 0.0, 1.0 );
}

const vec3 sunDir = normalize( vec3(0.15,0.7,0.65) );

float dapples( in vec3 ro, in vec3 rd )
{
    float sha = eliSoftShadow( ro, rd, vec3(0.0,4.0,4.0), vec3(3.0,1.0,3.0), 10.0 );
    
    vec3 uu = normalize( cross( rd, vec3(0.0,0.0,1.0) ) );
    vec3 vv = normalize( cross( uu, rd ) );

    vec3 ce = vec3(0.0,4.0,5.0);
    float t = -dot(ro-ce,rd);
    vec3 po = ro + t*rd;
    vec2 uv = vec2( dot(uu,po-ce), dot(vv,po-ce) );

    float dap = 1.0-smoothstep( 0.1, 0.5, texture(iChannel3,0.25+0.4*uv).x );
    return 1.0 - 0.95*(1.0-sha)*(1.0-dap);
}

vec3 shade( in vec3 ro, in vec3 rd, in float t, in float m, in vec3 matInfo )
{
    float eps = 0.001;
    
    vec3 pos = ro + t*rd;
    vec3 nor = calcNormal( pos, eps*t );
    float kk;

    vec3 mateD = vec3(0.2,0.16,0.11);
    vec3 mateS = vec3(0.2,0.12,0.07);
    vec3 mateK = vec3(0.0,1.0,0.0); // amount, power, metalic
    float focc = 1.0;
    
    if( m<3.5 ) // ground
    {
        mateD = vec3(0.1,0.09,0.07)*0.27;
        mateS = vec3(0.0,0.0,0.0);
        mateD *= 2.0*texture( iChannel1, 0.1*pos.xz ).xyz;
        
        float gr = smoothstep( 0.3,0.4,texture(iChannel2,0.01*pos.zx).x );
        vec3 grcol = vec3(0.3,0.28,0.05)*0.07;
        grcol *= 0.5 + texture( iChannel2, 4.0*pos.xz ).x;
        mateD = mix( mateD, grcol, smoothstep( 0.9,1.0,nor.y)*gr );
        mateD *= 1.2;
        mateK = vec3(1.0,8.0,1.0);
    }
    else if( m<4.5) // bushes
    {
        mateD = vec3(0.2,0.32,0.07)*0.1;
        mateD.x += matInfo.x*0.02;
        mateS = vec3(0.8,0.9,0.1);
        focc = 1.0-matInfo.y;
        mateK = vec3(0.07,16.0,0.0);
    }
    else if( m<5.5 ) // trees
    {
        mateD = vec3(0.2,0.3,0.07)*0.07;
        mateS = vec3(0.0,0.0,0.0);
        mateK = vec3(0.2,16.0,0.0);
    }
    else // leaves
    {
        mateD = vec3(0.2,0.35,0.07)*0.2;
        mateS = vec3(0.8,1.0,0.1)*0.25;
        mateK = vec3(0.07,16.0,0.0);
        float te = texture( iChannel2, 0.35*matInfo.yz ).x;
        mateD *= 1.0 + 0.6*te;
        mateS *= 1.0 + 0.6*te;
        mateD += vec3(0.035) * (1.0-smoothstep(0.005,0.01,abs(matInfo.y)+matInfo.z*0.05) );
    }
    
    vec3 hal = normalize( sunDir-rd );
    float fre = clamp(1.0+dot(nor,rd), 0.0, 1.0 );
    float occ = calcAO( pos, nor )*focc;
        
    float dif1 = clamp( dot(nor,sunDir), 0.0, 1.0 );
    float bak = clamp( dot(nor,normalize(vec3(-sunDir.x,0.0,-sunDir.z))), 0.0, 1.0 );
    float sha = calcSoftShadow( pos, sunDir, 16.0 );
	sha = min( sha, dapples(pos,sunDir) );
              
    dif1 *= sha;
    float spe1 = clamp( dot(nor,hal), 0.0, 1.0 );
    float bou = clamp( 0.3-0.7*nor.y, 0.0, 1.0 );

    // sun
    vec3 col = 8.5*vec3(2.0,1.2,0.65)*dif1;
    // sky
    col += 4.5*vec3(0.35,0.7,1.0)*occ*clamp(0.2+0.8*nor.y,0.0,1.0);
    // ground
    col += 4.0*vec3(0.4,0.25,0.12)*bou*occ;
    // back
    col += 3.5*vec3(0.2,0.2,0.15)*bak*occ;
    // sss
    col += 25.0*fre*fre*(0.2+0.8*dif1*occ)*mateS;

    // sun
    vec3 hdir = normalize(sunDir - rd);
    float costd = clamp( dot(sunDir, hdir), 0.0, 1.0 );
    float spp = pow( spe1, mateK.y )*dif1*mateK.x * (0.04 + 0.96*pow(1. - costd,5.0));
    col += mateK.z*15.0*5.0*spp; 
    
    col *= mateD;

    col += (1.0-mateK.z)*15.0*5.0*spp; 
    
    return col;        
}

vec2 raycast( in vec3 ro, in vec3 rd, out vec3 matInfo )
{
    vec2 res = vec2(-1.0);

    float maxdist = 100.0;
    float t = 1.0;

    float tp = ( 8.0-ro.y)/rd.y; if( tp>0.0 ) maxdist = min( maxdist, tp );
          tp = (-2.2-ro.y)/rd.y; if( tp>0.0 ) maxdist = min( maxdist, tp );
    
    for( int i=0; i<110; i++ )
    {
        vec3 p = ro + t*rd;
        vec2 h = map( p, matInfo );
        res = vec2(t,h.y);
        if( h.x<(0.0001*t) ||  t>maxdist ) break;
        t += h.x*0.75;
    }

    if( t>maxdist )
    {
        res = vec2(-1.0);
    }

    return res;
}

float mapBk( in vec3 pos )
{
    float l = length(pos.xz);
    float f = smoothstep( 1000.0, 1500.0, l );

    float h = 200.0*f*texture( iChannel2, 0.001 + 0.00003*pos.xz ).x;

    return pos.y-h;
}

vec3 calcNormalBk( in vec3 pos, in float eps )
{
#if 0    
    vec2 e = vec2(1.0,-1.0)*0.5773*eps;
    return normalize( e.xyy*mapBk( pos + e.xyy ) + 
					  e.yyx*mapBk( pos + e.yyx ) + 
					  e.yxy*mapBk( pos + e.yxy ) + 
					  e.xxx*mapBk( pos + e.xxx ) );
#else
    // trick by klems, to prevent the compiler from inlining map() 4 times
    vec4 n = vec4(0.0);
    for( int i=ZERO; i<4; i++ )
    {
        vec4 s = vec4(pos, 0.0);
        s[i] += eps;
        n[i] = mapBk(s.xyz);
    }
    return normalize(n.xyz-n.w);
#endif    
}

float calcSoftShadowBk( in vec3 ro, in vec3 rd, float k )
{
    float res = 1.0;
    float t = 0.01;
    for( int i=0; i<16; i++ )
    {
        float h = mapBk(ro + rd*t );
        res = min( res, smoothstep(0.0,1.0,k*h/t) );
        t += clamp( h, 10.0, 100.0 );
		if( res<0.01 ) break;
    }
    return clamp(res,0.0,1.0);
}

vec3 shadeBk( in vec3 ro, in vec3 rd, in float t )
{
    float eps = 0.005;
    
    vec3 pos = ro + t*rd;
    vec3 nor = calcNormalBk( pos, eps*t );
    float kk;

    vec3 mateD = vec3(0.14,0.14,0.12);
    mateD = mix( mateD, vec3(0.04,0.04,0.0), smoothstep(0.85,0.95, nor.y ) );
    mateD *= 0.3;
  
    mateD *= 0.1 + 2.0*texture( iChannel2, pos.xz*0.005 ).x;
    
    vec3 hal = normalize( sunDir-rd );
        
    float dif1 = clamp( dot(nor,sunDir), 0.0, 1.0 );
    //if( dif1>0.001 ) dif1 *= calcSoftShadowBk( pos, sunDir, 16.0 );

    // sun
    vec3 col = 8.0*vec3(1.8,1.2,0.8)*dif1;
    // sky
    col += 4.0*vec3(0.3,0.7,1.0)*clamp(0.2+0.8*nor.y,0.0,1.0);
    
    col *= mateD*1.2;
    return col;        
}

float intersectBk( in vec3 ro, in vec3 rd )
{
    float res = -1.0;

    float maxdist = 2000.0;
    float t = 1000.0;

    for( int i=0; i<100; i++ )
    {
        vec3 p = ro + t*rd;
        float h = mapBk( p );
        res = t;
        if( h<(0.0001*t) ||  t>maxdist ) break;
        t += h*0.75;
    }

    if( t>maxdist ) res = -1.0;

    return res;
}

vec3 render( in vec3 ro, in vec3 rd, out float resT )
{
    resT = 10000.0;
    
    // sky
    //vec3 col = clamp(vec3(0.7,0.9,1.0) - rd.y,0.0,1.0);
    vec3 col = clamp(vec3(0.75,0.9,1.0) - rd.y,0.0,1.0);
    
    // clouds
    float t = (1000.0-ro.y)/rd.y;
    if( t>0.0 )
    {
        vec2 uv = (ro+t*rd).xz;
        float cl = texture( iChannel2, .000013*uv ).x;
        cl = smoothstep(0.4,1.0,cl);
        col = mix( col, vec3(1.0), 0.4*cl );
    }

    // distant mountains
    {
    float tm = intersectBk( ro, rd );
    if( tm>-0.5  )
    {
        col = shadeBk( ro, rd, tm );
        float fa = 1.0-exp(-0.001*tm);
        vec3 pos = ro + rd*tm;
        fa *= exp(-0.001*pos.y);
        col = mix( col, vec3(0.35,0.5,0.8), fa );
        resT = tm;
    }
    }
    
    // landscape
    vec3 matInfo;
    vec2 tm = raycast( ro, rd, matInfo );
    if( tm.y>-0.5  )
    {
        col = shade( ro, rd, tm.x, tm.y, matInfo );
        float fa = 1.0-exp(-0.00018*(tm.x*tm.x*0.4  + 0.6*tm.x));
        col = mix( col, vec3(0.35,0.5,0.75), fa );
        resT = tm.x;
    }
    
    return col;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{	
    #ifdef USE_REPROJECTION
    vec2 o = hash2( float(iFrame) ) - 0.5;
    #else
    vec2 o = vec2(0.0);
    #endif

    vec2 q = fragCoord/iResolution.xy;
    vec2 p = (2.0*(fragCoord+o)-iResolution.xy)/iResolution.y;

    // camera
    float an = 0.025*sin(0.5*iTime) - 1.25;
    vec3 ro = vec3(5.7*sin(an),1.6,5.7*cos(an));
    vec3 ta = vec3(0.0,1.6,0.0);

    // ray
    const float fl = 3.5;
    mat3 ca = setCamera( ro, ta, 0.0 );
    vec3 rd = normalize( ca * vec3(p,-fl) );

    // render
    float t;
    vec3 col = render( ro, rd, t);
    
    //------------------------------------------
	// reproject from previous frame and average
    //------------------------------------------
#ifdef USE_REPROJECTION
    mat4 oldCam = mat4( textureLod(iChannel0,vec2(0.5,0.5)/iResolution.xy, 0.0),
                        textureLod(iChannel0,vec2(1.5,0.5)/iResolution.xy, 0.0),
                        textureLod(iChannel0,vec2(2.5,0.5)/iResolution.xy, 0.0),
                        0.0, 0.0, 0.0, 1.0 );
    
    // world space
    vec4 wpos = vec4(ro + rd*t,1.0);
    // camera space
    vec3 cpos = (wpos*oldCam).xyz; // note inverse multiply
    // ndc space
    vec2 npos = -fl * cpos.xy / cpos.z;
    // screen space
    vec2 spos = 0.5 + 0.5*npos*vec2(iResolution.y/iResolution.x,1.0);
    // undo dither
    spos -= o/iResolution.xy;
	// raster space
    vec2 rpos = spos * iResolution.xy;
    
    if( rpos.y<1.0 && rpos.x<3.0 )
    {
    }
	else
    {
        vec3 ocol = textureLod( iChannel0, spos, 0.0 ).xyz;
    	if( iFrame==0 ) ocol = col;
        col = mix( ocol, col, 0.13 );
    }

    //----------------------------------
                           
	if( fragCoord.y<1.0 && fragCoord.x<3.0 )
    {
        if( abs(fragCoord.x-2.5)<0.5 ) fragColor = vec4( ca[2], -dot(ca[2],ro) );
        if( abs(fragCoord.x-1.5)<0.5 ) fragColor = vec4( ca[1], -dot(ca[1],ro) );
        if( abs(fragCoord.x-0.5)<0.5 ) fragColor = vec4( ca[0], -dot(ca[0],ro) );
    }
    else
    {
        fragColor = vec4( col, t );
    }
#else
    fragColor = vec4( col, t );
#endif
}
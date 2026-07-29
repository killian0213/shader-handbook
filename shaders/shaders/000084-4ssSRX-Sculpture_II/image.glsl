// Image (image) — Sculpture II by iq
// https://www.shadertoy.com/view/4ssSRX

// Copyright Inigo Quilez, 2015 - https://iquilezles.org/
// I am the sole copyright owner of this Work.
// You cannot host, display, distribute or share this Work neither
// as it is or altered, here on Shadertoy or anywhere else, in any
// form including physical and digital. You cannot use this Work in any
// commercial or non-commercial product, website or project. You cannot
// sell this Work and you cannot mint an NFTs of it or train a neural
// network with it without permission. I share this Work for educational
// purposes, and you can link to it, through an URL, proper attribution
// and unmodified screenshot, as part of your educational material. If
// these conditions are too restrictive please contact me and we'll
// definitely work it out.

#define AA 1    // make 2 if you have a fast machine

// box mapping, with differentials
vec4 texCube( sampler2D sam, in vec3 p, in vec3 dpdx, in vec3 dpdy, in vec3 n, in float k )
{
	vec4 x = texture( sam, p.yz );
	vec4 y = texture( sam, p.zx );
	vec4 z = texture( sam, p.xy );
    vec3 w = pow( abs(n), vec3(k) );
	return (x*w.x + y*w.y + z*w.z) / (w.x+w.y+w.z);
}

vec4 mapSculpture( vec3 p )
{
    p.x += 0.5*sin( 3.0*p.y + iTime );
    p.y += 0.5*sin( 3.0*p.z + iTime );
    p.z += 0.5*sin( 3.0*p.x + iTime );
    p.x += 0.5*sin( 3.0*p.y + iTime );
    p.y += 0.5*sin( 3.0*p.z + iTime );
    p.z += 0.5*sin( 3.0*p.x + iTime );
    p.x += 0.5*sin( 3.0*p.y + iTime );
    p.y += 0.5*sin( 3.0*p.z + iTime );
    p.z += 0.5*sin( 3.0*p.x + iTime );
    p.x += 0.5*sin( 3.0*p.y + iTime );
    p.y += 0.5*sin( 3.0*p.z + iTime );
    p.z += 0.5*sin( 3.0*p.x + iTime );

    float d1 = length(p) - 1.0*smoothstep(0.0,2.0,iTime);;
    d1 *= 0.02;

    return vec4( d1, p );
}

vec4 map( vec3 p )
{
    vec4 res = mapSculpture(p);
    
    float d2 = p.y + 1.0;
    if( d2<res.x ) res = vec4( d2, 0.0, 0.0, 0.0 );

	return res;
}

vec4 intersect( in vec3 ro, in vec3 rd, in float maxd )
{
    vec3 res = vec3(-1.0);
	float precis = 0.00005;
    float t = 1.0;
    for( int i=0; i<1024; i++ )
    {
	    vec4 h = map( ro+rd*t );
        res = h.yzw;
        if( h.x<precis||t>maxd ) break;
        t += h.x;
    }
   return vec4( t, res );
}

vec3 calcNormal( in vec3 pos )
{
    const float e = 0.0001;
    const vec2 k = vec2(1.0,-1.0);
    return normalize( k.xyy*map( pos + k.xyy*e ).x + 
					  k.yyx*map( pos + k.yyx*e ).x + 
					  k.yxy*map( pos + k.yxy*e ).x + 
					  k.xxx*map( pos + k.xxx*e ).x );
}

float softshadow( in vec3 ro, in vec3 rd, float k )
{
    float res = 1.0;
    float t = 0.005;
    for( int i=0; i<256; i++ )
    {
        float h = mapSculpture(ro + rd*t).x;
        res = min( res, 5.0*k*h/t );
        if( res<0.0001 || t>5.0 ) break;
        t += clamp( h, 0.015, 0.04 );
    }
    return clamp(res,0.0,1.0);
}

float calcOcc( in vec3 pos, in vec3 nor )
{
    const float h = 0.2;
	float ao = 0.0;
    for( int i=0; i<8; i++ )
    {
        vec3 dir = sin( float(i)*vec3(1.0,7.13,13.71)+vec3(0.0,2.0,4.0) );
        dir *= sign(dot(dir,nor));
        float d = mapSculpture( pos + h*dir ).x;
        ao += max(0.0,h-d*2.0);
    }
    return clamp( 4.0 - 2.5*ao, 0.0, 1.0 )*(0.5+0.5*nor.y);
}

void calcRayForPixel( vec2 pix, out vec3 resRo, out vec3 resRd )
{
	vec2 p = (-iResolution.xy + 2.0*pix) / iResolution.y;
	
    //-----------------------------------------------------
    // camera
    //-----------------------------------------------------
	
	float an = 0.3*iTime + 7.5;

	vec3 ro = vec3(4.5*sin(an),0.5,4.5*cos(an));
    vec3 ta = vec3(0.0,0.5,0.0);

    // camera matrix
    vec3 ww = normalize( ta - ro );
    vec3 uu = normalize( cross(ww,vec3(0.0,1.0,0.0) ) );
    vec3 vv = normalize( cross(uu,ww));

	// create view ray
	vec3 rd = normalize( p.x*uu + p.y*vv + 2.0*ww );
    
	resRo = ro;
	resRd = rd;
}

const vec3 lig = normalize(vec3(1.0,0.7,0.9));

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
            
    vec3 tot = vec3(0.0);
    
    #if AA>1
    #define ZERO min(iFrame,0)
    for( int m=ZERO; m<AA; m++ )
    for( int n=ZERO; n<AA; n++ )
    {
        // pixel coordinates
        vec2 o = vec2(float(m),float(n)) / float(AA) - 0.5;
    #else    
        vec2 o = vec2(0.0,0.0);
    #endif    
 	
    //-----------------------------------------------------
    // camera
    //-----------------------------------------------------
    vec3 ro, rd, ddx_ro, ddx_rd, ddy_ro, ddy_rd;
	calcRayForPixel( fragCoord + o + vec2(0.0,0.0), ro, rd );
	calcRayForPixel( fragCoord + o + vec2(1.0,0.0), ddx_ro, ddx_rd );
	calcRayForPixel( fragCoord + o + vec2(0.0,1.0), ddy_ro, ddy_rd );
    
    //-----------------------------------------------------
	// render
    //-----------------------------------------------------
	vec3 col = vec3(0.0);
	// raymarch
    const float maxd = 9.0;
    vec4  inn = intersect(ro,rd,maxd);
    float t = inn.x;
    if( t<maxd )
    {
        // geometry
        vec3 pos = ro + t*rd;
        vec3 nor = calcNormal(pos);
		vec3 ref = reflect( rd, nor );

        // -----------------------------------------------------------------------
        // compute ray differentials by intersecting the tangent plane to the  
        // surface.		
		// -----------------------------------------------------------------------

		// computer ray differentials
		vec3 ddx_pos = ddx_ro - ddx_rd*dot(ddx_ro-pos,nor)/dot(ddx_rd,nor);
		vec3 ddy_pos = ddy_ro - ddy_rd*dot(ddy_ro-pos,nor)/dot(ddy_rd,nor);		
        
        // material
        col = vec3(0.3,0.3,0.3);
        if( pos.y>-0.99) col += 0.2*inn.yzw;
        vec3 pat = texCube( iChannel0, 0.5*pos, 0.5*ddx_pos, 0.5*ddy_pos, nor, 4.0 ).xyz;
        col *= pat;
        col *= 0.5;
        
		// lighting
		float occ = calcOcc( pos, nor );

        float amb = 0.5 + 0.5*nor.y;
		float dif = max(dot(nor,lig),0.0);
		float bou = max(0.0,-nor.y);
        float bac = max(0.2 + 0.8*dot(nor,-lig),0.0);
		float sha = 0.0; if( dif>0.01 ) sha=softshadow( pos+0.001*nor, lig, 256.0 );
        float fre = pow( clamp( 1.0 + dot(nor,rd), 0.0, 1.0 ), 3.0 );
        float spe = 15.0*pat.x*max( 0.0, pow( clamp( dot(lig,reflect(rd,nor)), 0.0, 1.0), 16.0 ) )*dif*sha*(0.04+0.96*fre);
		
		// lights
		vec3 lin = vec3(0.0);

        lin += 3.5*dif*vec3(6.00,4.00,3.00)*pow(vec3(sha),vec3(1.0,1.2,1.5));
		lin += 1.0*amb*vec3(0.80,0.30,0.30)*occ;
		lin += 1.0*bac*vec3(1.00,0.50,0.20)*occ;
		lin += 1.0*bou*vec3(1.00,0.30,0.20)*occ;
        lin += 4.0*fre*vec3(1.00,0.80,0.70)*(0.1+0.9*dif*sha)*occ;
        lin += spe*2.0;

        // surface-light interacion
		col = col*lin + spe;

        // fade out
        col *= min(200.0*exp(-1.5*t),1.0);
        col *= 1.0-smoothstep( 1.0,6.0,length(pos.xz) );
	}

 	tot += col;
    #if AA>1
    }
    tot /= float(AA*AA);
    #endif

    // gain
    tot = 1.3*tot/(1.0+tot);
        
    // gamma
	tot = pow( clamp(tot,0.0,1.0), vec3(0.4545) );


    // grading
    tot = pow( tot, vec3(0.7,1.0,1.0) );
    
    // vignetting
 	vec2 q = fragCoord.xy / iResolution.xy;
    tot *= pow( 16.0*q.x*q.y*(1.0-q.x)*(1.0-q.y), 0.1 );
	   
    fragColor = vec4( tot, 1.0 );
}
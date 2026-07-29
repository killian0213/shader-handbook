// Image (image) — Wavy by iq
// https://www.shadertoy.com/view/ldX3zS

// Copyright Inigo Quilez, 2013 - https://iquilezles.org/
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

//#define FASTNOISE

#ifdef FASTNOISE
float noise( in vec3 x )
{
	vec3 p = floor(x);
	vec3 f = fract(x);
    f = f*f*(3.0-2.0*f);
    vec2 uv = (p.xy+vec2(37.0,17.0)*p.z) + f.xy;
	vec2 rg = textureLod( iChannel0, (uv+0.5)/256.0, 0.0 ).yx;
	return mix( rg.x, rg.y, f.z );
}
#else
float noise( in vec3 x )
{
    ivec3 p = ivec3(floor(x));
    vec3 f = fract(x);
	f = f*f*(3.0-2.0*f);
    
	ivec2 uv = p.xy + ivec2(37,17)*p.z;

	vec2 rgA = texelFetch( iChannel0, (uv+ivec2(0,0))&255, 0 ).yx;
    vec2 rgB = texelFetch( iChannel0, (uv+ivec2(1,0))&255, 0 ).yx;
    vec2 rgC = texelFetch( iChannel0, (uv+ivec2(0,1))&255, 0 ).yx;
    vec2 rgD = texelFetch( iChannel0, (uv+ivec2(1,1))&255, 0 ).yx;

    vec2 rg = mix( mix( rgA, rgB, f.x ),
                   mix( rgC, rgD, f.x ), f.y );
    return mix( rg.x, rg.y, f.z );
}
#endif

vec4 texcube( sampler2D sam, in vec3 p, in vec3 n )
{
	vec4 x = texture( sam, p.yz );
	vec4 y = texture( sam, p.zx );
	vec4 z = texture( sam, p.xy );
	return x*abs(n.x) + y*abs(n.y) + z*abs(n.z);
}

//=====================================================================

const mat3 m = mat3( 0.00,  0.80,  0.60,
					-0.80,  0.36, -0.48,
					-0.60, -0.48,  0.64 );

float mocc;
vec4 mapTerrain( in vec3 pos )
{
	vec3 q = pos*0.5;
    
    vec3  dir = vec3(0.0,1.0,0.0);
	float spe = 0.04;
	float time = 5.0 + (iTime-10.0)*0.5;
	
	q.xyz += 2.0*noise( 2.0*q )*vec3(1.0,3.0,1.0);
	
	float f;
	q *= vec3(1.0,2.0,1.0);
	q += dir*time*8.0*spe; f  = 0.50000*noise( q ); q = q*2.02;
	q += dir*time*4.0*spe; f += 0.25000*noise( q ); q = q*2.03;
	q += dir*time*2.0*spe; f += 0.12500*noise( q ); q = q*2.01;
    q += dir*time*1.0*spe; f += 0.06250*noise( q );
    
	float d =  pos.y + 0.9 - 2.0*f;
    mocc = f;
	return vec4(q,d);
}

vec4 raymarchTerrain( in vec3 ro, in vec3 rd, in vec2 pixel )
{
	const float maxd = 20.0;
    
	float t = 0.1;
                      
	vec4 res = vec4(0.0);
	for( int i=0; i<256; i++ )
	{
		res = mapTerrain( ro+rd*t );
		if( abs(res.w)<0.001||t>maxd ) break;
		t += res.w*0.07;
	}
	if( t>maxd ) t=-1.0;
	return vec4(res.xyz,t);
}

vec3 calcNormal( in vec3 pos )
{
	vec3 eps = vec3(0.015,0.0,0.0);
	
	return normalize( vec3(
		mapTerrain(pos+eps.xyy).w - mapTerrain(pos-eps.xyy).w,
		mapTerrain(pos+eps.yxy).w - mapTerrain(pos-eps.yxy).w,
		mapTerrain(pos+eps.yyx).w - mapTerrain(pos-eps.yyx).w ) );

}

const vec3 lig = normalize( vec3(0.0,0.2,0.7) );

float softshadow( in vec3 ro, in vec3 rd, float mint, float k )
{
	float res = 1.0;
	float t = mint;

	for( int i=0; i<48; i++ )
	{
		float h = mapTerrain(ro + rd*t).w;
		h = max( h*0.08, 0.0 );
		res = min( res, k*h/t );
		t += clamp( h, 0.02, 0.5 );
		if( h<0.0001 ) break;
	}
	return clamp(res,0.0,1.0);
}

vec3 path( float time )
{
	return vec3( 2.5*cos(0.03*time), 1.5, 2.5*sin(0.03*time) );

}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
	vec2 q = fragCoord.xy / iResolution.xy;
	vec2 p = (-iResolution.xy + 2.0*fragCoord.xy)/iResolution.y;
	
	// camera
	float time = 125.0-iTime+10.0;
	vec3 ro = path( time+0.0 );
	vec3 ta = vec3(0.0,-0.5,0.0);
	float roll = 0.15*cos(0.07*time);
	
	// camera tx
	vec3 cw = normalize(ta-ro);
	vec3 cp = vec3(sin(roll), cos(roll),0.0);
	vec3 cu = normalize(cross(cw,cp));
	vec3 cv = normalize(cross(cu,cw));
	float r2 = p.x*p.x*0.32 + p.y*p.y;
	p *= (7.0-sqrt(37.5-11.5*r2))/(r2+1.0);
	vec3 rd = normalize( p.x*cu + p.y*cv + 1.3*cw );
	
	// sky
	vec3 col = vec3(0.25,0.36,0.36)*1.3 - rd.y*0.5;
	float sun = clamp( dot(rd,lig), 0.0, 1.0 );
	col += vec3(1.0,0.8,0.4)*0.2*pow( sun, 6.0 );
	vec3 bcol = col;
	
	// terrain
	vec4 res = raymarchTerrain(ro, rd, fragCoord);
	float t = res.w;
	if( t>0.0 )
    {
        float occ = pow( clamp(mocc*2.2-0.6,0.0,1.0), 1.5 );
		vec3 pos = ro + t*rd;
		vec3 nor = calcNormal( pos );
		
		// lighting
		float dif = sqrt(clamp( dot( nor, lig ), 0.0, 1.0 ));
		float sha = 0.0; if( dif>0.01) sha=softshadow(pos,lig,0.01, 40.0);
		float bac = clamp( dot( nor, normalize(lig*vec3(-1.0,0.0,-1.0)) ), 0.0, 1.0 );
		float sky = 0.5 + 0.5*nor.y;
		float amb = 1.0;
		
		vec3 brdf  = 1.5*dif*vec3(1.2,0.70,0.50)*sha*(0.8+0.2*occ);
		     brdf += 0.6*amb*vec3(0.4,0.28,0.10)*occ;
             brdf += 0.7*bac*vec3(0.7,0.35,0.15)*occ;
             brdf += 0.8*sky*vec3(0.2,0.35,0.40)*occ;
		
		// surface shading/material
		col  = texcube( iChannel1, 0.005*res.xyz, nor ).xyz;
		col *= texcube( iChannel1, 0.050*res.xyz, nor ).xyz;
		col = sqrt(sqrt(col));
		col *= vec3(1.2,1.1,1.0);
		col = mix( col, col*vec3(2.0,0.4,0.4), 0.8*clamp( 1.0-2.0*occ,0.0,1.0) );
		
		// light/surface interaction
		col = brdf * col;
		col = mix( col, vec3(dot(col,vec3(0.33))), 0.5*dif-0.2 );
		
		// atmospheric
		float hh = 1.0 - smoothstep( -2.0, 1.0, pos.y );
		col = mix( col, (1.0-0.7*hh)*bcol, 1.0-exp(-0.002*t*t*t) );
	}
	
	// sun glow
	col += vec3(1.2,0.7,0.2)*0.53*pow( sun, 3.0 )*clamp( (rd.y+0.4)/(0.0+0.4),0.0,1.0);
	
	// gamma
	col = pow( clamp( col, 0.0, 1.0 ), vec3(0.45) );
	
	// contrast, desat, tint and vignetting
	col = col*col*(3.0-2.0*col);
	col *= 0.5 + 0.5*pow( 16.0*q.x*q.y*(1.0-q.x)*(1.0-q.y), 0.15 );
	
	fragColor = vec4( col, 1.0 );
}
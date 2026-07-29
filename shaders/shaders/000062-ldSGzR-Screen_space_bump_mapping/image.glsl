// Image (image) — Screen space bump mapping by iq
// https://www.shadertoy.com/view/ldSGzR

// The MIT License
// Copyright © 2013 Inigo Quilez
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions: The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software. THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

// Mikkelsen's technique for Bump Mapping Unparametrized Surfaces 
// https://dl.dropboxusercontent.com/u/55891920/papers/mm_sfgrad_bump.pdf
// Pretty much copy & pasted, with minor changes. It aliases quite a bit :(


// make GPU_DERIVATIVES 1 for dFdx()/dFdy() based derivatives, which produces
// 2x2 pixel artifacts (in a deferred renderer you could perhaps compute these
// by manually differencing UVs in the uv buffer)

#define GPU_DERIVATIVES 0

//===============================================================================================
//===============================================================================================
//===============================================================================================
//===============================================================================================
//===============================================================================================


#if GPU_DERIVATIVES==1
vec3 doBump( in vec3 pos, in vec3 nor, in float signal, in float scale )
{
    vec3 dpdx = dFdx( pos );
    vec3 dpdy = dFdy( pos );
    
    float dbdx = dFdx(signal);
    float dbdy = dFdy(signal);

    vec3  u = cross( dpdy, nor );
    vec3  v = cross( nor, dpdx );
    float d = dot( dpdx, u );
	
	vec3 surfGrad = dbdx*u + dbdy*v;
    return normalize( abs(d)*nor - sign(d)*scale*surfGrad );
}

#else    

vec3 doBump( in vec3 dpdx, in vec3 dpdy, in vec3 nor, 
             in float dbdx, in float dbdy,
             in float scale )
{
    vec3  u = cross( dpdy, nor );
    vec3  v = cross( nor, dpdx );
    float d = dot( dpdx, u );
	
	vec3 surfGrad = dbdx*u + dbdy*v;
    return normalize( abs(d)*nor - sign(d)*scale*surfGrad );
}
#endif

//===============================================================================================
//===============================================================================================
//===============================================================================================
//===============================================================================================
//===============================================================================================
float softShadowSphere( in vec3 ro, in vec3 rd, in vec4 sph )
{
    vec3 oc = sph.xyz - ro;
    float b = dot( oc, rd );
	
    float res = 1.0;
    if( b>0.0 )
    {
        float h = dot(oc,oc) - b*b - sph.w*sph.w;
        res = clamp( 2.0 * h / b, 0.0, 1.0 );
    }
    return res;
}

vec4 texcube( sampler2D sam, in vec3 p, in vec3 n )
{
	vec4 x = texture( sam, p.yz );
	vec4 y = texture( sam, p.zx );
	vec4 z = texture( sam, p.xy );
	return x*abs(n.x) + y*abs(n.y) + z*abs(n.z);
}


void calcCamera( out vec3 ro, out vec3 ta )
{
	float an = 3.1 + 0.25*iTime;
	ro = vec3( 2.5*cos(an), 1.0, 2.5*sin(an) );
    ta = vec3( 0.0, 1.0, 0.0 );
}

void calcRayForPixel( in vec2 pix, out vec3 resRo, out vec3 resRd )
{
	vec2 p = (2.0*pix-iResolution.xy)/iResolution.y;
	
     // camera movement	
	vec3 ro, ta;
	calcCamera( ro, ta );
    // camera matrix
    vec3 ww = normalize( ta - ro );
    vec3 uu = normalize( cross(ww,vec3(0.0,1.0,0.0) ) );
    vec3 vv = normalize( cross(uu,ww));
	// create view ray
	vec3 rd = normalize( p.x*uu + p.y*vv + 1.5*ww );
	
	resRo = ro;
	resRd = rd;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    float bump = smoothstep( -0.8, -0.7, cos( 0.5*iTime ) );

	vec3 ro, rd, ddx_ro, ddx_rd, ddy_ro, ddy_rd;
	calcRayForPixel( fragCoord + vec2(0.0,0.0), ro, rd );
	calcRayForPixel( fragCoord + vec2(1.0,0.0), ddx_ro, ddx_rd );
	calcRayForPixel( fragCoord + vec2(0.0,1.0), ddy_ro, ddy_rd );

    
    // sphere center	
	vec3 sc = vec3(0.0,1.0,0.0);

	vec3 mate = vec3(0.0);
	
    // raytrace
	float tmin = 10000.0;
	vec3  nor = vec3(0.0);
	float occ = 1.0;
	vec3  pos = vec3(0.0);
	
	// raytrace-plane
	float h = (0.0-ro.y)/rd.y;
	if( h>0.0 ) 
	{ 
		tmin = h; 
		nor = vec3(0.0,1.0,0.0); 
		pos = ro + h*rd;
		
        vec3 di = sc - pos;
		float l = length(di);
		
        #if GPU_DERIVATIVES==1
		mate = texture( iChannel0, 0.25*pos.zx, .1*l ).xyz;
        float signal = dot(mate,vec3(0.333));
		nor = doBump( pos, nor, signal, 0.1*bump );
        #else
		// computer ray differentials
		vec3 ddx_pos = ddx_ro - ddx_rd*dot(ddx_ro-pos,nor)/dot(ddx_rd,nor);
		vec3 ddy_pos = ddy_ro - ddy_rd*dot(ddy_ro-pos,nor)/dot(ddy_rd,nor);
		vec3 dposdx = ddx_pos - pos;
		vec3 dposdy = ddy_pos - pos;

        mate = texture( iChannel0, 0.25*pos.zx, .1*l ).xyz;
        float signal = dot(mate,vec3(0.33));
        float dsignaldx = dot(texture( iChannel0, 0.25*ddx_pos.zx, .1*l ).xyz,vec3(0.33)) - signal;
        float dsignaldy = dot(texture( iChannel0, 0.25*ddy_pos.zx, .1*l ).xyz,vec3(0.33)) - signal;
		
        nor = doBump( dposdx, dposdy, nor, dsignaldx, dsignaldy, 0.1*bump );
        #endif

        occ = 1.0 - dot(nor,di/l)*1.0*1.0/(l*l); 
	}

	// raytrace-sphere
	vec3  ce = ro - sc;
	float b = dot( rd, ce );
	float c = dot( ce, ce ) - 1.0;
	h = b*b - c;
	if( h>0.0 )
	{
		h = -b - sqrt(h);
		if( h<tmin ) 
		{ 
			tmin=h; 
            pos = ro + tmin*rd;
			nor = normalize(ro+h*rd-sc); 

            #if GPU_DERIVATIVES==1
            mate = texcube( iChannel0, 0.25*pos, nor ).xyz;
            float signal = dot(mate,vec3(0.33));
		    nor = doBump( pos, nor, signal, 0.03*bump );
            #else
            // computer ray differentials
            vec3 ddx_pos = ddx_ro - ddx_rd*dot(ddx_ro-pos,nor)/dot(ddx_rd,nor);
            vec3 ddy_pos = ddy_ro - ddy_rd*dot(ddy_ro-pos,nor)/dot(ddy_rd,nor);
            vec3 dposdx = ddx_pos - pos;
            vec3 dposdy = ddy_pos - pos;

            mate = texcube( iChannel0, 0.25*pos, nor ).xyz;
            float signal = dot(mate,vec3(0.33));
            float dsignaldx = dot(texcube( iChannel0, 0.25*ddx_pos, nor ).xyz,vec3(0.33)) - signal;
            float dsignaldy = dot(texcube( iChannel0, 0.25*ddy_pos, nor ).xyz,vec3(0.33)) - signal;
            
            nor = doBump( dposdx, dposdy, nor, dsignaldx, dsignaldy, 0.03*bump );
            #endif
			occ = 0.5 + 0.5*nor.y;
		}
	}

    // shading/lighting	
	vec3 col = vec3(0.9);
	if( tmin<100.0 )
	{
	    pos = ro + tmin*rd;
		
		float sh = softShadowSphere( pos, vec3(0.57703), vec4(sc,1.0) );
        vec3 lin = vec3(0.8,0.7,0.6)*sh * clamp(dot(nor,vec3(0.57703)),0.0,1.0);
		     lin += occ*vec3(0.2,0.3,0.4);
		     lin += sh*0.5*pow(clamp(dot(reflect(rd,nor),vec3(0.57703)),0.0,1.0),12.0);
		col = mate * lin;
		col = mix( col, vec3(0.9), 1.0-exp( -0.003*tmin*tmin ) );
	}
	
	col = sqrt( col );
	
	fragColor = vec4( col, 1.0 );
}
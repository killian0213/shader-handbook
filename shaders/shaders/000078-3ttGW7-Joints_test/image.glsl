// Image (image) — Joints test by iq
// https://www.shadertoy.com/view/3ttGW7

// The MIT License
// Copyright © 2019 Inigo Quilez
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions: The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software. THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

// A test for sdJoint3D (https://www.shadertoy.com/view/3ld3DM), which
// was inspired by dr2's https://www.shadertoy.com/view/3l3GD7 but
// I think simpler. It's an evolution of my "Torus Pipes" shader
// (https://www.shadertoy.com/view/wlj3zV) but with full UVW texture
// coordinates. This allows for consistent 2D or 3D texture mapping
// and displacement that sticks to the surface, which is very convenient.
//
// The shader shows 2D texturing (the checkerboard), 3D solid
// texturing (the sine wave pattern) and displacement.


#define AA 1


// https://iquilezles.org/articles/smin
vec4 smin( vec4 a, vec4 b, float k )
{
    float h = clamp( 0.5+0.5*(b.x-a.x)/k, 0.0, 1.0 );
    return vec4(mix(b.x,a.x,h)-k*h*(1.0-h), (b.x<a.x)?b.yzw:a.yzw);
}

vec4 dmin( in vec4 a, in vec4 b )
{
    return (a.x<b.x) ? a : b;
}

// https://iquilezles.org/articles/distfunctions
float sdEllipsoid( in vec3 p, in vec3 r ) 
{
    float k0 = length(p/r);
    float k1 = length(p/(r*r));
    return k0*(k0-1.0)/k1;
}

// https://www.shadertoy.com/view/3ld3DM
float dot2( in vec2 v ) { return dot(v,v); }
vec2 sdJoint3D( in vec3 p, in float l, in float a, 
                out vec3 uvw, out vec3 qos, inout float ioV)
{
    qos = p;
    
    // if perfectly straight
    if( abs(a)<0.001 )
    {
        float v = p.y;
        p.y -= clamp(p.y,0.0,l);
        qos.y -= l;
        uvw = vec3(p.x,v,p.z) + vec3(0,ioV,0);
        ioV += l;
		return vec2(length(p),clamp(v/l,0.0,1.0));
    }
    
    // parameters
    vec2  sc = vec2(sin(a),cos(a));
    float ra = 0.5*l/a;
    
    // recenter
    p.x -= ra;
    
    // reflect
    vec2 q = p.xy - 2.0*sc*max(0.0,dot(sc,p.xy));

	// distance
    float u = abs(ra)-length(q);
    float d2 = (q.y<0.0) ? dot2( q+vec2(ra,0.0) ) : u*u;

    // parametrization
    float s = sign(a);
#if 0
    float v = ra*atan(s*p.y,-s*p.x);
    u = u*s;
    if( v<0.0 ) { if( s*p.x>0.0 ) { v = abs(ra)*6.283185 + v; } else { v = p.y; u = q.x + ra; } }
#else
    float v = (p.y>0.0) ? atan(s*p.y,-s*p.x)*ra : (s*p.x<0.0)?p.y:l-p.y;
          u = (p.y>0.0) ? s*u : sign(-s*p.x)*(q.x+ra);
#endif    
    uvw = vec3(u,v,p.z) + vec3(0,ioV,0);
    ioV += l;
    
    // out coordinate system
    vec2 scb = vec2(sc.y*sc.y-sc.x*sc.x,2.0*sc.x*sc.y);
	qos.x -= ra;    
    qos.xy = mat2(scb.x,scb.y,-scb.y,scb.x)*qos.xy;
    qos.x += ra;
    
	// distance    
    return vec2(sqrt(d2+p.z*p.z), clamp(v/l,0.0,1.0));
}

// https://iquilezles.org/articles/distfunctions
vec2 sdLine( vec3 p, in float l, 
             out vec3 uvw, out vec3 qos, inout float ioV )
{
    qos = p + vec3(0,-l,0);
	uvw = p + vec3(0,ioV,0);
    ioV += l;
    float h = clamp( p.y/l, 0.0, 1.0 );
	p.y -= h*l;
    return vec2( length( p ), h );
}

//-------------------------------------------------------------------

vec4 leg( in vec3 pos, in float time )
{
    // basic/stupid/test leg animation
    float tempo = 0.5 + 0.5*sin(time);
    tempo = 0.5*tempo + 0.5*tempo*tempo*(3.0-2.0*tempo);
    float an0 = mix(0.25,-0.75,tempo*tempo*0.5+0.5*tempo);
    float an1 = mix(0.80, 0.80,1.0-(1.0-tempo)*(1.0-tempo));
    an1 -= 0.8*4.0*tempo*(1.0-tempo)*tempo;
    float an2 = -0.65 - 0.2*4.0*tempo*(1.0-tempo);

    //---------------
    
    vec4  res;
    vec3  qos = vec3(0.0);
    float h = 0.0;
    
    // join
    {
        vec3 uvw;
        vec2 d2 = sdJoint3D(pos, 0.4, -an0, uvw, qos, h );
        float d = d2.x - mix(0.26,0.24,smoothstep(0.0,1.0,d2.y) );
        res = vec4(d,uvw);
    }
    
    // segment
    {
        vec3 uvw;
        vec2 d2 = sdLine( qos, 0.4, uvw, qos, h );
        float ra = mix(0.24,0.19,smoothstep(0.0,1.0,d2.y));
        float d = d2.x - ra;
        if( d<res.x ) res = vec4(d,uvw);
    }
    
    // join
    {
        vec3 uvw;
        vec2 d2 = sdJoint3D(qos, 0.3, -an1, uvw, qos, h );
        float d = d2.x - mix(0.19, 0.17, smoothstep(0.0,1.0,d2.y));; 
        if( d<res.x ) res = vec4(d,uvw);
    }

	// segment
    {
        vec3 uvw;
    	vec2 d2 = sdLine( qos, 0.9, uvw, qos, h );
        float ra = 0.17;
        ra = mix(ra,0.19,smoothstep(0.0,0.3,d2.y));
        ra = mix(ra,0.11,smoothstep(0.3,1.0,d2.y));
        ra -= 1.4*sin(atan(uvw.x,uvw.z))*smoothstep(0.0,1.0,d2.y)*(1.0-smoothstep(0.9,1.0,d2.y))*exp2(-d2.y*8.0);
        float d = d2.x - ra;
        
    	if( d<res.x ) res = vec4(d,uvw );
    }
    
    // join
    {
        vec3 uvw;
        vec2 d2 = sdJoint3D(qos, 0.2, -an2, uvw, qos, h );
        float d = d2.x - mix(0.11,0.08,smoothstep(0.0,1.0,d2.y) );
        if( d<res.x ) res = vec4(d,uvw);
    }

	// segment
    {
        vec3 uvw;
    	vec2 d2 = sdLine( qos-vec3(0.0,-0.15,0.0), 0.3, uvw, qos, h );
        uvw.y-=0.15;
        float d = d2.x - 0.08;
    	if( d<res.x ) res = vec4(d,uvw );
    }

    return res;
}

float waves( in vec3 p )
{
    return 0.5+0.5*sin(p.x*80.0)*sin(p.y*80.0)*sin(p.z*80.0);
}

float disp(in vec3 p, in float s )
{
    vec3 q = p;
    p *=0.4;
    p.xz *= 0.2;

    float f = 0.0;
    f += 0.6*waves(p*1.0);    
    f += 0.4*waves(p*2.0+1.0);
    f += 0.03*sin(atan(q.x,q.z-s*0.27)*90.0);

    return f;
}

#define ZERO min(iFrame,0)

vec4 map( in vec3 pos, in float time, float doDisplace )
{
    time = time*3.0;

    // body
	vec3 bpos = pos;
    bpos.y -= 0.3*sqrt(0.5-0.5*cos(time*2.0+1.0));
    bpos.x -= 0.1;
    bpos.y += 0.35;
    bpos.x -= 0.2*pow(0.5+0.5*cos(time*2.0+0.5),2.0);
    vec3 tpos = bpos - vec3(-0.1,0.45,0.0);
    bpos.xy = -bpos.xy;
    vec4 res2 = vec4(sdEllipsoid(tpos,vec3(0.3,0.7,0.45)),bpos);
    
	// legs
#if 0
    vec4 l1 = leg( bpos-vec3(0.0,0.0, 0.27), 3.1416+time );
    vec4 l2 = leg( bpos-vec3(0.0,0.0,-0.27), time );
    vec4 res = dmin(l1,l2);
    res.w += 0.27*sign(l2.x-l1.x);
#else
    // trick to prevent inlining - compiles faster
    vec4 dl[2];
    for( int i=ZERO; i<2; i++ )
       dl[i] = leg( bpos-vec3(0.0,0.0,((i==0)?1.0:-1.0)*0.27), ((i==0)?3.1416:0.0)+time );
    vec4 res = dmin(dl[0],dl[1]);
    res.w += 0.27*sign(dl[1].x-dl[0].x);
#endif    
        
    res = smin( res, res2, 0.08 );

	// displacement
    float di = disp(res.yzw, sign(pos.z));
	float tempo = 0.5 + 0.5*sin(time);
    tempo = 0.5*tempo + 0.5*tempo*tempo*(3.0-2.0*tempo);
    float an0 = mix(1.0,0.0,tempo);
    di *= 0.8 + 1.7*an0*(smoothstep(-0.6,0.40,res.z)-smoothstep(0.8,1.4,res.z));
	di *= 1.0-smoothstep(1.9,1.91,res.z);
    res.x += (0.015-0.03*di)*doDisplace;
    res.x *= 0.85;

    return res;
}

// https://iquilezles.org/articles/normalsSDF
vec3 calcNormal( in vec3 pos, in float time, in float doDisplace )
{
    const float eps = 0.0005;
#if 0    
    vec2 e = vec2(1.0,-1.0)*0.5773;
    return normalize( e.xyy*map( pos + e.xyy*eps,time,doDisplace ).x + 
					  e.yyx*map( pos + e.yyx*eps,time,doDisplace ).x + 
					  e.yxy*map( pos + e.yxy*eps,time,doDisplace ).x + 
					  e.xxx*map( pos + e.xxx*eps,time,doDisplace ).x );
#else
    // trick by klems, to prevent the compiler from inlining map() 4 times
    vec4 n = vec4(0.0);
    for( int i=ZERO; i<4; i++ )
    {
        vec4 s = vec4(pos, 0.0);
        s[i] += eps;
        n[i] = map(s.xyz, time, doDisplace).x;
    }
    return normalize(n.xyz-n.w);
#endif   
}

// https://iquilezles.org/articles/rmshadows
float calcSoftshadow( in vec3 ro, in vec3 rd, in float mint, in float tmax, in float time, in float doDisplace )
{
    float res = 1.0;
    float t = mint;
    for( int i=0; i<25; i++ )
    {
		float h = map( ro + rd*t, time, doDisplace ).x;
        res = min( res, 8.0*h/t );
        t += clamp( h, 0.025, 0.10 );
        if( res<0.005 || t>tmax ) break;
    }
    return clamp( res, 0.0, 1.0 );
}

float calcOcclusion( in vec3 pos, in vec3 nor, in float time, in float doDisplace )
{
	float occ = 0.0;
    float sca = 1.0;
    for( int i=ZERO; i<5; i++ )
    {
        float hr = 0.01 + 0.5*float(i)/4.0;
        vec3 aopos =  nor * hr + pos;
        float dd = map( aopos, time, doDisplace ).x;
        occ += (hr-dd)*sca;
        sca *= 0.98;
    }
    return clamp( 1.0 - occ*0.5, 0.0, 1.0 );
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    // render
    vec3 tot = vec3(0.0);
    
    #if AA>1
    for( int m=ZERO; m<AA; m++ )
    for( int n=ZERO; n<AA; n++ )
    {
        // pixel coordinates
        vec2 o = vec2(float(m),float(n)) / float(AA) - 0.5;
        vec2 p = (-iResolution.xy + 2.0*(fragCoord+o))/iResolution.y;
        float d = 0.5*sin(fragCoord.x*147.0)*sin(fragCoord.y*131.0);
        float time = iTime - 0.5*(1.0/24.0)*(float(m*AA+n)+d)/float(AA*AA-1);
        #else    
        vec2 p = (-iResolution.xy + 2.0*fragCoord)/iResolution.y;
        float time = iTime;
        #endif

        // animation
        float displace = smoothstep(-0.4,0.4,sin(0.5*time));

        // camera movement	
        float an = -0.6 + 0.2*sin(time*0.2) + 9.0*iMouse.x/iResolution.x;
        vec3 ro = vec3( 2.3*sin(an), -0.3, 2.3*cos(an) );
        vec3 ta = vec3( 0.0, -0.8, 0.0 );

        // camera matrix
        vec3 ww = normalize( ta - ro );
        vec3 uu = normalize( cross(ww,vec3(0.0,1.0,0.0) ) );
        vec3 vv =          ( cross(uu,ww));

        // create view ray
        vec3 rd = normalize( p.x*uu + p.y*vv + 1.7*ww );
        
        // raymarch
        const float tmax = 4.0;
        float t = 0.0;
        vec3 uvw = vec3(0.0);
        for( int i=0; i<256; i++ )
        {
            vec3 pos = ro + t*rd;
            
            vec4 h = map(pos,time,displace);
            if( abs(h.x)<0.0001 || t>tmax )
            {
                uvw = h.yzw;
                break;
            }
            t += h.x;
        }
    
        // shading/lighting	
        vec3 col = vec3(0.02);
        if( t<tmax )
        {
            vec3 pos = ro + t*rd;
            vec3 nor = calcNormal(pos, time, displace);
            float fre = clamp(1.0+dot(nor,rd),0.0,1.0);
            vec3 lig = normalize(vec3(0.5,0.4,0.51));
            vec3 hal = normalize(lig-rd);
            float dif = clamp( dot(nor,lig), 0.0, 1.0 );
            dif *= calcSoftshadow( pos, lig, 0.001, 2.0, time, displace );
            float spe = pow(clamp(dot(nor,hal),0.0,1.0),16.0)*dif*(0.04+0.96*pow(clamp(1.0-dot(hal,-rd),0.0,1.0),5.0));
            float amb = 0.55 + 0.45*dot(nor,vec3(0.0,1.0,0.0));
            float occ = calcOcclusion( pos, nor, time, displace );
            amb *= occ;
            
            // basic ligthing
            vec3 lin = vec3(0.0);
            lin += vec3(0.3,0.35,0.4)*amb;
            lin += vec3(1.1,0.9,0.7)*dif;
            
            // material
            col = mix(vec3(0.8),vec3(0.5,0.1,0),smoothstep(-0.1,0.1,(sin( 50.0*uvw.x )+sin( 50.0*uvw.y )+sin( 50.0*uvw.z ))/3.0));
            col = mix(col,vec3(0.4,0.25,0.2), displace*smoothstep(1.9,1.91,uvw.y) );

            col = lin*col + spe + fre*fre*fre*0.1*occ;
        }

        // gamma        
        col = pow( col, vec3(0.4545) );
	    tot += col;
    #if AA>1
    }
    tot /= float(AA*AA);
    #endif

	fragColor = vec4( tot, 1.0 );
}
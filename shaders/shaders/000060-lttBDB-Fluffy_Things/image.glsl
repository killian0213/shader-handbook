// Image (image) — Fluffy Things by iq
// https://www.shadertoy.com/view/lttBDB

// Copyright Inigo Quilez, 2018 - https://iquilezles.org/
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


mat3 makeBase( in vec3 w )
{
	float k = inversesqrt(1.0-w.y*w.y);
    return mat3( vec3(-w.z,0.0,w.x)*k, 
                 vec3(-w.x*w.y,1.0-w.y*w.y,-w.y*w.z)*k,
                 w);
}

// https://iquilezles.org/articles/intersectors
vec2 sphIntersect( in vec3 ro, in vec3 rd, in float rad )
{
	float b = dot( ro, rd );
	float c = dot( ro, ro ) - rad*rad;
	float h = b*b - c;
	if( h<0.0 ) return vec2(-1.0);
    h = sqrt(h);
	return vec2(-b-h,-b+h);
}

// modified Keinert et al's inverse Spherical Fibonacci Mapping
vec4 inverseSF( in vec3 p, in float n )
{
    const float PI = 3.14159265359;
	const float PHI = 1.61803398875;

    float phi = min(atan(p.y,p.x),PI);
    float k   = max(floor(log(n*PI*sqrt(5.0)*(1.-p.z*p.z))/log(PHI+1.)),2.0);
    float Fk  = pow(PHI,k)/sqrt(5.0);
    vec2  F   = vec2(round(Fk),round(Fk*PHI));
    vec2  G   = PI*(fract((F+1.0)*PHI)-(PHI-1.0));    
    
    mat2 iB = mat2(F.y,-F.x,G.y,-G.x)/(F.y*G.x-F.x*G.y);
    vec2 c = floor(iB*0.5*vec2(phi,n*p.z-n+1.0));

    float ma = 0.0;
    vec4 res = vec4(0);
    for( int s=0; s<4; s++ )
    {
        vec2 uv = vec2(s&1,s>>1);
        float i = dot(F,uv+c);
        float phi = 2.0*PI*fract(i*PHI);
        float cT = 1.0 - (2.0*i+1.0)/n;
        float sT = sqrt(1.0-cT*cT);
        vec3 q = vec3(cos(phi)*sT, sin(phi)*sT,cT);
        float a = dot(p,q);
        if (a > ma)
        {
            ma = a;
            res.xyz = q;
            res.w = i;
        }
    }
    return res;
}

float map( in vec3 p, out vec4 color, const in bool doColor )
{
    float lp = length(p);
    float dmin = lp-1.0;
    
    
    float pp = 0.5+0.5*sin(60.0*lp); pp *= pp; pp *= pp; pp *= pp; pp *= pp;
    dmin = min(dmin,p.y+1.0+0.02*pp);
    
    

    color = vec4(0.4,0.5,0.3,1.0)*0.9;
    
    float s = 1.0;
    
    //dmin = min( dmin,lp-2.15 );
    
    for( int i=0; i<2; i++ )
    {
        float h = float(i)/float(2-1);
        
        // Trick. Do not check the 2x2 neighbors, just snap to the
        // closest point. This is wrong and produces discontinuities
        // in the march, but it's okeish for the purposes of this shader
        vec4 fibo = inverseSF(normalize(p), 65.0+35.0*h);
        
        // snap
        p -= fibo.xyz;
        
        // orient to surface
        p *= makeBase(normalize( fibo.xyz + 0.08*sin(fibo.y + 2.0*iTime + vec3(0.0,2.0,4.0))));

        // scale
        float scale = 7.0 + 3.0*sin(111.0*fibo.w);
        if( i==0 ) scale += 4.0*(1.0-smoothstep(-0.5,-0.4,fibo.y));
        scale *= 1.0 + 3.0*smoothstep(0.9,1.0,cos(0.25*iTime + fibo.w*141.7));
        p *= scale;
        
        // translate and deform
        p.z -= 2.3 + length(p.xy)*1.1*abs(sin(fibo.w*212.1));

        //-----
        
        s *= scale;
		// distance to line segment/capsule 
        float d = length( p - vec3(0.0,0.0,clamp(p.z,-6.0,0.0)) ) - 0.1;
        d /= s;

        if( d<dmin )
        {
            if( doColor )
            {
                color.w *= smoothstep(0.0, 5.0/s, dmin-d);
                if( i==0 ) color = vec4(0.4,0.5,0.4,1.0);
                color.xyz += 0.3*(1.0-0.45*h)*sin(fibo.w*211.0+vec3(0.0,1.0,2.0));
                color.xyz = max(color.xyz,0.0);
            }
            dmin = d;
        }
        else
        {
          color.w *= 0.4*(0.1 + 0.9*smoothstep(0.0, 1.0/s, d-dmin));
        }
    }
    
    return dmin;
}


// https://iquilezles.org/articles/normalsSDF
vec3 calcNormal( in vec3 pos, in float ep )
{
    vec4 kk;
    vec2 e = vec2(1.0,-1.0)*0.5773;
    return normalize( e.xyy*map( pos + e.xyy*ep, kk, false ) + 
					  e.yyx*map( pos + e.yyx*ep, kk, false ) + 
					  e.yxy*map( pos + e.yxy*ep, kk, false ) + 
					  e.xxx*map( pos + e.xxx*ep, kk, false ) );
}

// https://iquilezles.org/articles/rmshadows
float calcSoftshadow( in vec3 ro, in vec3 rd, float tmax, const float k )
{
    vec2 bound = sphIntersect( ro, rd, 2.15 );
    tmax = min(tmax,bound.y);
    
	float res = 1.0;
    float t = 0.0;
    //float t = max(0.0,bound.x);
    for( int i=0; i<45; i++ )
    {
    	vec4 kk;
		float h = map( ro + rd*t, kk, false );
        res = min( res, k*h/t );
        t += clamp( h, 0.02, 0.20 );
        if( res<0.005 || t>tmax ) break;
    }
    return clamp( res, 0.0, 1.0 );
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    float an = (iTime-10.0)*0.05 - 0.4;
    
    // camera	
    vec3 ro = vec3( 4.5*sin(an), 0.0, 4.5*cos(an) );
    vec3 ta = vec3( 0.0, 0.2, 0.0 );
    // camera-to-world transformation
    mat3 ca = makeBase( normalize(ta-ro) );
    
    // render    
    vec2 p = (-iResolution.xy + 2.0*fragCoord)/iResolution.y;

    // ray direction
    vec3 rd = ca * normalize( vec3(p.xy,2.3) );

    // background
    vec3 bak = vec3(0.1,0.14,0.18)*1.2 + 0.15*rd.y;

    vec4 col = vec4(0.0);

    // bounding volume
    vec2 bound = sphIntersect( ro, rd, 2.15 );
    if( bound.x>0.0 )
    {
        // raymarch
        vec4 kk;
        float t = bound.x;
        for( int i=0; i<350; i++ )
        {
            vec3 pos = ro + t*rd;
            
            // evaluate distance
            vec4 mate;
            float h = map(pos,mate,true);

            // color contribution            
            float px = t*0.012;
            if( h<px )
            {
                // surface normal                
                vec3 nor = calcNormal(pos, px*0.5);

                // start lighting                
                vec3 lcol = vec3(0.0);

                // key ligh
                {
                    //dif
                    vec3 lig = normalize(vec3(1.0,1.0 ,0.7));
                    float dif = clamp(0.5+0.5*dot(nor,lig),0.0,1.0);
                    float sha = calcSoftshadow( pos+0.01*lig, lig, 2.0, 6.0 );
                    lcol += mate.xyz*dif*vec3(3.0,0.7,0.5)*1.2*vec3(sha,sha*0.3+0.7*sha*sha,sha*sha);
                    // spec
                    vec3 hal = normalize(lig-rd);
                    float spe = clamp( dot(nor,hal), 0.0, 1.0 );
                    float fre = clamp( dot(-rd,lig), 0.0, 1.0 );
                    fre = 0.05 + 0.95*pow(fre,5.0);
                    spe *= spe; spe *= spe;
                    col += 1.0*spe*dif*sha*fre*mate.w;
                }

                // back light
                {
                    vec3 lig = normalize(vec3(-1.0,0.0,0.0));
                    float dif = clamp(0.5+0.5*dot(nor,lig),0.0,1.0);
                    lcol += mate.rgb*dif*vec3(1.0,0.9,0.6)*0.06*mate.w;
                }

                // dome light
                {
                    float dif = clamp(0.3+0.7*nor.y,0.0,1.0);
                    lcol += mate.xyz*dif*1.0*vec3(0.1,0.2,0.4)*mate.w*(0.2+0.8*mate.w);
                }

                // fake sss
                {
                    float fre = clamp(1.0+dot(rd,nor),0.0,1.0);
                    lcol += 0.8*vec3(1.0,0.3,0.2)*mate.xyz*mate.xyz*fre*fre*mate.w;
                    //lcol += 0.2*mate.xyz*mate.xyz*fre*fre*mate.w;
                }

                // grade
                lcol = 0.85*pow( lcol, vec3(0.75,0.9,1.0) );
            

                // composite front to back
                float al = clamp(1.0-h/px,0.0,1.0);
                lcol.rgb *= al;
    			col = col + vec4(lcol,al)*(1.0-col.a);
                if( col.a>0.995 || abs(h)<0.0001 ) break;
            }


            // march ray            
            t += h*0.5;
            if( t>bound.y ) break;
            //if( col.a>0.995 || abs(h)<0.0001 || t>bound.y ) break;
        }
    }


    // composite with background    
    vec3 tot = bak*(1.0-col.w) + col.xyz;

    // gain
    tot *= 0.7 + 0.3*smoothstep( 0.0, 15.0, abs(iTime-25.0) );
    
    // gamma
    tot = pow( tot, vec3(0.4545) );


    // vignetting
 	vec2 q = fragCoord/iResolution.xy;
    tot *= pow( 16.0*q.x*q.y*(1.0-q.x)*(1.0-q.y), 0.2 );

    // output    
    fragColor = vec4( tot, 1.0 );
}
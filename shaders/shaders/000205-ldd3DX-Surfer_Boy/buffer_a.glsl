// Buffer A (buffer) — Surfer Boy by iq
// https://www.shadertoy.com/view/ldd3DX

float noise( in vec2 p )
{
  return -1.0+2.0*textureGood( iChannel0, p-0.5 );
}

const float hmin = -6.0;
const float hmax = -1.0;

float mapWater( in vec3 p )
{
    float w = 0.0;
    float s = 0.5;
    vec2 q = p.xz;
    for( int i=0; i<4; i++ )
    {
        w += s*noise(q*vec2(0.5,1.0));
        q = 2.01*(q + vec2(0.03,0.07));
        s = 0.5*s;
    }
    w /= 0.9375;
    
    
    float h = hmin + (hmax-hmin)*w;
    

    float cr = 0.0;
    float wh = 0.2 + 0.8*smoothstep( 0.0, 75.0, -p.z );
    vec2 pp = p.xz/50.0;
    float d = 1e20;
    for( int j=-2; j<=2; j++ )
    for( int i=-2; i<=2; i++ )
    {
        vec2 o = floor( pp );
        o += vec2( float(i), float(j) );
        vec4 ra = texelFetch( iChannel0, ivec2(o)&255, 0 );
        o += ra.xy;
        vec3 r = p - vec3(o.x*50.0,-4.0-(1.0-wh)*5.0+ra.z*ra.z*2.0-3.0,o.y*50.0 + mod(10.0*iTime*0.2,50.0));
        r.yz = mat2(0.99,0.141,-0.141,0.99)*r.yz;
        d = smin( d, sdEllipsoid( r, vec3(0.0,0.0,0.0), (0.2+0.8*wh)*vec3(35.0,(0.1+0.9*ra.z*ra.z)*3.0,15.0)), 2.10 );
        
        float pm = (0.1+0.9*wh)*15.0;
        float cc = 1.0-smoothstep( 0.0, 2.0, abs(abs(r.z)-pm) );
        cr = max( cr, cc );
    }
    d = d - w*0.5;
    d = smin( d, p.y+4.0, 1.0);
    d = d - w*0.03;

    return d;
}

const vec3 bnor = normalize(vec3(0.0,0.9,-0.05));

float mapBeach( in vec3 p )
{
    float d = dot(p,bnor)-2.8;
    
    vec2 w = vec2(0.0);
    vec2 s = vec2(0.5);
    vec2 t = vec2(0.0);
	
    vec2 q = p.xz*1.25;
    q += 1.0*cos( 0.3*q.yx );
    for( int i=0; i<7;i++ )
    {
        float n = 0.5 + 0.5*noise(q);
		w += s*vec2(1.0-almostIdentity(abs(-1.0+2.0*n),0.1,0.05 ),n);
		t += s;
        q = mat2(1.6,1.2,-1.2,1.6)*q;
		s *= vec2(0.3,0.5);
    }
	w /= t;

	float f = w.x + w.y*0.4;
    
    float wet = 1.0-smoothstep(-16.0, -10.0, p.z );
    
    return d - 0.15*mix(f, (1.0-f)*0.1, wet );
}

// https://iquilezles.org/articles/normalsSDF
vec3 calcNormalmapWater( in vec3 pos, in float ep )
{
    vec2 e = vec2(1.0,-1.0)*0.5773;
    return normalize(e.xyy*mapWater(pos+e.xyy*ep) + 
					 e.yyx*mapWater(pos+e.yyx*ep) + 
					 e.yxy*mapWater(pos+e.yxy*ep) + 
					 e.xxx*mapWater(pos+e.xxx*ep) );
}

// https://iquilezles.org/articles/normalsSDF
vec3 calcNormalmapBeach( in vec3 pos, in float ep )
{
    vec2 e = vec2(1.0,-1.0)*0.5773;
    return normalize(e.xyy*mapBeach(pos+e.xyy*ep) + 
					 e.yyx*mapBeach(pos+e.yyx*ep) + 
					 e.yxy*mapBeach(pos+e.yxy*ep) + 
					 e.xxx*mapBeach(pos+e.xxx*ep) );
}


float intersectWater( in vec3 ro, in vec3 rd, in float mint )
{
    float t = mint;
    for( int i=0; i<200; i++ )
    {
        vec3 p = ro + t*rd;
        float h = mapWater( p );
        if( abs(h)<(0.0004*t) ) break;
        t += h;
    }
	return t;
}

vec3 sky( in vec3 rd )
{
    if( rd.y<0.0 ) return vec3(0.0,0.05,0.10);
    
    // gradient
    float dy = max(0.0,rd.y);
    vec3 col = vec3(0.3,0.7,0.9) - dy*0.5;
	col = mix( col, vec3(1.3,0.45,0.10), exp(-4.0*dy) );
	col = mix( col, vec3(1.5,0.10,0.05), exp(-30.0*dy) );
	col = mix( col, vec3(0.1,0.10,0.10), exp(-60.0*dy) );
    
    // clouds
    vec2 uv = 0.003*rd.xz/rd.y;
	uv += 0.006*sin(100.0*uv.yx);
    float f  = 0.5000*texture( iChannel0, 1.0*uv.xy ).x;
          f += 0.2500*texture( iChannel0, 1.9*uv.yx ).x;
          f += 0.1250*texture( iChannel0, 4.1*uv.xy ).x;
          f += 0.0625*texture( iChannel0, 7.9*uv.yx ).x;
          
    return mix( col, vec3(1.0,0.37,0.4)*(1.0-f)*0.5,0.3*smoothstep(0.4,0.7,f) );
}

vec4 render( in vec3 ro, in vec3 rd )
{
	vec3 col = vec3(0.0);
    
    float ma = -1.0;
    float tmin = 1e20;
    
    float t = (hmax-ro.y)/rd.y;
    if( t>5.0 )
    {
        t = intersectWater( ro, rd, t );
        ma = 0.0;
        tmin = t;
    }

    t = (-2.8-dot(ro,bnor))/dot(rd,bnor);
    if( t>0.0 && t<tmin)
    {
		tmin = t;
		ma = 1.0;
    }

    if( ma<0.0 )
    {
        col = sky( rd );
    }
    else if( ma<0.5 )
    {
    	vec3 pos = ro + tmin*rd;
        vec3 nor = calcNormalmapWater(pos,0.0001*tmin);

        float h = (pos.y - hmin)/(hmax-hmin);
        float f = exp(-0.01*tmin);
        col = mix( vec3(0.03,0.1,0.1), vec3(0.02,0.04,0.08), 1.0-f );
        
        h = 1.0-abs(nor.y);
        col += h*vec3(0.00,0.03,0.03)*2.0;

        vec3 ref = reflect( rd, nor );
        float kr = pow( clamp(1.0 + dot( rd, nor ),0.0,1.0), 5.0 );
        col += 0.7*(0.01 + 0.99*kr)*sky( ref );
        
        
        float dif = clamp( dot(nor,sunDir),0.0,1.0);
        col *= 0.8 + 0.4*dif;
        col *= 0.75;
        
        // foam waves
        float foam = smoothstep( -0.5, 0.1, -nor.y );
		// foam shore
		float te = texture(iChannel0,0.016*pos.xz + vec2(-0.002,-.007)*iTime).x;
		foam += 
		smoothstep(-24.0,-23.0,pos.z + 0.5*sin(pos.x*0.4+te*2.0))*
		smoothstep(0.4,0.5,te)*0.8;
	    col = mix( col, vec3(0.8,0.9,1.0), 0.4*foam );
    
        // fog
		col = mix( col, vec3(0.1), 1.0-exp(-0.000001*tmin*tmin) );
    }
	else if( ma<1.5 )
    {
        col = vec3(0.0);

        vec3 pos = ro + tmin*rd;
        vec3 nor = calcNormalmapBeach(pos,0.0002);

		vec3 mateD = vec3(1.0,0.7,0.5)*0.17;
        vec2 mateK = vec2(1.0,0.5);
        float mateS = 0.0;

		
        float fr = pow(clamp( 1.0+dot(rd,nor), 0.0, 1.0 ),2.0);
		mateD += 0.05*vec3(1.0,0.5,0.2)*fr;

		
        float wet = 1.0-smoothstep(-17.0, -11.0, pos.z );
		mateD = mix( mateD, vec3(0.05,0.02,0.0)*0.8, wet );
        mateK.x += 12.0*wet;
        mateK.y += 9.0*wet;
        
		mateD *= 0.9;
        
		float dif1 = clamp( -0.1+1.4*dot(nor,sunDir),0.0,1.0);
        vec3 hal = normalize( sunDir-rd );
        float spe = pow(clamp(dot(hal,nor),0.0,1.0),0.001+8.0*mateK.y);
		col += mateD*4.0*vec3(2.5,1.0,0.5)*dif1;
			col += mateK.x*vec3(1.4,1.30,1.3)*dif1*spe*(0.04+0.96*pow(clamp(dot(hal,nor),0.0,1.0),5.0));

        col += mateD*vec3(1.0,0.9,0.9)*(0.5+0.5*nor.y)*0.2;
        col += mateK.x*vec3(0.8,0.8,0.9)*smoothstep( -0.1,0.3,reflect(rd,nor).y) *(0.04+0.96*pow(clamp(dot(rd,nor),0.0,1.0),5.0));
        
    }
    
    return vec4(col,tmin);
}


void mainImage( out vec4 fragColor, in vec2 fragCoord )
{	
    mat3 ca; vec3 ro; float fl;
    computeCamera( iTime, ca, ro, fl );
    
    vec2  p = (2.0*fragCoord.xy-iResolution.xy)/iResolution.y;
    vec3  rd = normalize( ca * vec3(p,-fl) );
    
    fragColor = render( ro, rd );
}
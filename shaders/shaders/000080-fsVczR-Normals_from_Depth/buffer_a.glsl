// Buffer A (buffer) — Normals from Depth by iq
// https://www.shadertoy.com/view/fsVczR

//
// Simplified geometry from https://www.shadertoy.com/view/lsf3zr
//


// https://iquilezles.org/articles/distfunctions
float sdBox( in vec3 p, in vec3 b ) 
{
    vec3 q = abs(p) - b;
    return min(max(q.x,max(q.y,q.z)),0.0) + length(max(q,0.0));
}

// https://iquilezles.org/articles/smin
float smin( float a, float b, float k )
{
    float h = max(k-abs(a-b),0.0);
    return min(a, b) - h*h*0.25/k;
}

//------------------------------------------

float column( in float x, in float y, in float z )
{
    float y2=y-0.25;
    float y4=y-1.0;

    const float sqh = sqrt(0.5);
    float nx = max(abs(x),abs(z));
    float nz = min(abs(x),abs(z));	

    float dsp = abs(min(cos(1.125*6.283185*x/0.085), 
                        cos(1.125*6.283185*z/0.085)));
    dsp *= 1.0-smoothstep(0.8,0.9,abs(x/0.085)*abs(z/0.085));
    
    float di1 = sdBox( vec3(x,y,z),   vec3(0.085+dsp*0.0075,1.0,0.085+dsp*0.0075));
    float di2 = sdBox( vec3(x,y,z),   vec3(0.12,0.29,0.12) );
    float di3 = sdBox( vec3(x,y4,z),  vec3(0.14,0.02,0.14) );
    float di4 = sdBox( vec3(nx,y,nz), vec3(0.14,0.3,0.05) );
    float di5 = sdBox( vec3(nx,(y2+nz)*sqh,(nz-y2)*sqh), vec3(0.12, 0.16*sqh, 0.16*sqh));
    float di6 = sdBox( vec3(nx,(y2+nz)*sqh,(nz-y2)*sqh), vec3(0.14, 0.10*sqh, 0.10*sqh));

    return min(min(min(di1,di2),
                   min(di3,di4)),
                   min(di5,di6));
}

float wave( in float x, in float y )
{
    return sin(x)*sin(y);
}

float map( vec3 pos )
{
    // floor
    vec2 id = floor((pos.xz+0.1)/0.2 );
    float h = 0.012 + 0.008*sin(id.x*2313.12+id.y*3231.219);
    vec3 ros = vec3( mod(pos.x+0.1,0.2)-0.1, pos.y, mod(pos.z+0.1,0.2)-0.1 );
    float res = sdBox( ros, vec3(0.096,h,0.096) );

    // ceilin
	float x = fract( pos.x+128.0 ) - 0.5;
	float z = fract( pos.z+128.0 ) - 0.5;
    float y = (1.0 - pos.y)*0.6;
    float dis = 0.4 - smin(sqrt(y*y+x*x),sqrt(y*y+z*z),0.01);
    float dsp = abs(sin(31.416*pos.y)*sin(31.416*pos.x)*sin(31.416*pos.z));
    dis -= 0.02*dsp;
	dis = max( dis, y );
    res = min( res, dis );

    // columns
	vec2 fc = fract( pos.xz+128.5 ) - 0.5;
	float dis2 = column( fc.x, pos.y, fc.y );
    res = min( res, dis2 );
    
    return res;
}

float raycast( in vec3 ro, in vec3 rd, in float precis, in float maxd )
{
    float t = 0.001;
    for( int i=0; i<128; i++ )
    {
	    float d = map( ro+rd*t );
        if( abs(d)<(precis*t)||t>maxd ) break;
        t += d;
    }
    if( t>maxd ) t=-1.0;
    return t;
}

// https://iquilezles.org/articles/normalsSDF
vec3 calcNormal( in vec3 pos )
{
	const vec2 eps = vec2( 0.0002, 0.0 );
	return normalize(vec3(
	    map(pos+eps.xyy) - map(pos-eps.xyy),
	    map(pos+eps.yxy) - map(pos-eps.yxy),
	    map(pos+eps.yyx) - map(pos-eps.yyx) ));
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 p = (2.0*fragCoord-iResolution.xy)/iResolution.y;

    vec3 ro, rd;
    camera( ro, rd, iTime, p );

    float t= raycast(ro,rd,0.00001,100.0);
    if( t>0.0 )
    {
        vec3 pos = ro + t*rd;
        vec3 nor = calcNormal( pos );
        fragColor = vec4(nor,t);
    }
    else
    {
        fragColor = vec4( 0.0, 0.0, 0.0, 1e10 );
    }
}
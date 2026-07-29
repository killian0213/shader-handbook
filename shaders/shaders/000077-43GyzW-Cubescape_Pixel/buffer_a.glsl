// Buffer A (buffer) — Cubescape Pixel by iq
// https://www.shadertoy.com/view/43GyzW

#define SOUND 0

// https://iquilezles.org/articles/boxfunctions
vec4 iBox( in vec3 ro, in vec3 ird, in vec3 rad ) 
{
    vec3  n = ird*ro;
    vec3  k = abs(ird)*rad;
    vec3  t1 = -n - k;
    vec3  t2 = -n + k;
    float tN = max(max(t1.x,t1.y),t1.z);
    float tF = min(min(t2.x,t2.y),t2.z);
	if( tN>tF || tF<0.0 ) return vec4(-1.0);
    return vec4(tN, -sign(ird)*step(tN,t1) );
}

void makeCube( in vec2 pos, out vec3 cen, out vec3 siz, out float oID )
{
	vec2 ipos = floor( pos );
    
    float id = fract(sin(ipos.x+ipos.y*57.0)*13.5453123);
	    
#if SOUND==1        
    float f = textureLod( iChannel0, vec2( id*0.5, 0.25 ), 0.0 ).x;
    f = clamp(1.2*f*f,0.0,1.0);
#else
    float f = 0.0;
    if( f<0.001 ) { f = sin( iTime + id*12.5664 ); f = max(f*f*f,0.0); }
#endif    
    // quantize
    const float st = 2.5*0.5 * 6.0*4.0; f = floor(f*st)/st;
    
    float h = 2.5*f;
    oID = id;
    cen = vec3( pos.x+0.5, 0.5*h, pos.y+0.5 );
    siz = vec3( 0.5, h*0.5+0.05, 0.5 );
         if( sin(17.0*id)>0.5 ) siz.z *= 0.25;
    else if( sin(27.0*id)>0.5 ) siz.x *= 0.25;
}

vec2 trace( vec3 ro, in vec3 rd, in float tmin, in float tmax, out vec3 oNor )
{
    ro += tmin*rd;
    
	vec2 pos = floor(ro.xz);
    vec3 rdi = 1.0/rd;
    vec3 rda = abs(rdi);
	vec2 rds = sign(rd.xz);
	vec2 dis = (pos-ro.xz+0.5+rds*0.5)*rdi.xz;
	
	vec2 res = vec2( -1.0 );

    // traverse regular grid (in 2D)
	vec2 mm = vec2(0.0);
	for( int i=0; i<16; i++ ) 
	{
        // get box
        vec3 cen, siz; float id;
        makeCube( pos, cen, siz, id );

        // intersect box
        vec4 tmp = iBox( ro-cen, rdi, siz );
        if( tmp.x>0.0 )
        {
            res = vec2( tmp.x + tmin, id );
            oNor = tmp.yzw;
            break; 
        }

        // step to next cell		
		mm = step( dis.xy, dis.yx ); 
		dis += mm*rda.xz;
        pos += mm*rds;
	}
    
	return res;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    int kPixelSize = int(2.0 + iResolution.y/360.0);

    ivec2 ip = ivec2(fragCoord);
    ivec2 res = ivec2(iResolution.xy)/kPixelSize;
    if( ip.x>res.x || ip.y>res.y ) return;

    // camera
    vec3 off = floor(iTime*15.0)*vec3(8.0,0.0,0.0)/float(res.y);
    vec3 cu = vec3( sqrt(4.0), sqrt(0.0),-sqrt(4.0));
    vec3 cv = vec3(-sqrt(1.0), sqrt(6.0),-sqrt(1.0));
    vec3 cw = vec3(-sqrt(3.0),-sqrt(2.0),-sqrt(3.0));

    // ray
    vec2 p = vec2(2*ip-res)/float(res.y);
    vec3 ro = (p.x*cu + p.y*cv - 4.0*cw + off)/sqrt(8.0) * 4.0;
    vec3 rd = cw;

    // raycast
    vec3 col = vec3( 0.4, 0.2, 0.05 );
    vec2 tminmax = vec2(0.0, 40.0);

    // bounding volume
    float tp1 = (2.7-ro.y)/rd.y; if( tp1>0.0 ) tminmax.x = max( tminmax.x, tp1 );
    float tp2 = (0.0-ro.y)/rd.y; if( tp2>0.0 ) tminmax.y = min( tminmax.y, tp2 );

    // traverse grid
    vec3 nor = vec3(0.0,1.0,0.0);
    vec2 ti = trace( ro, rd, tminmax.x, tminmax.y, nor );
    if( ti.y > -0.5 )
    {
        // shade
        vec3 pos = ro + ti.x*rd;

        // material	
        vec3 mate = 0.5 + 0.5*cos(6.2831*ti.y*0.55 + vec3(3.1,5.1,6.1));
        mate *= 1.0 + 0.5*nor;

        // ambient light
        col = 0.5*mate*mix(clamp(pos.y/4.0,0.0,1.0),1.0,0.2*max(0.0,nor.y));

        // key light
        const vec3  lig = normalize( vec3(0.8,0.2,0.4) );
        float dif = max( dot(nor,lig), 0.0 );
        if( dif>0.001 )
        {
            vec3 kk;
            dif *= trace( pos, lig, 0.01, 32.0, kk ).x > 0.01 ? 0.0 : 1.0;
        }
        col += 1.0*mate*dif;
    }
    
    col = pow( 1.5*col, vec3(0.32,0.45,0.45) );
    
    float face = nor.x<-0.5?0.0:nor.x>0.5?1.0:
                 nor.y<-0.5?2.0:nor.y>0.5?3.0:
                 nor.z<-0.5?4.0:          5.0;
    float id = 6.0*floor(ti.y*10000.0) + face;
    
    fragColor = vec4( col, id );
}
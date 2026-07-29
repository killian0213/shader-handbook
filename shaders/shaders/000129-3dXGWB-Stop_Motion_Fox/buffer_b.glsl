// Buffer B (buffer) — Stop Motion Fox by iq
// https://www.shadertoy.com/view/3dXGWB

// Created by inigo quilez - iq/2019
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.


#define AA 1 // make 2 if you have a fast computer

// For once, I decided to use other people's talent to mix something together quickly:
//
// Terrain raytracer by Fizzer: https://www.shadertoy.com/view/XlcBRX
// Fox model by pixelmannen: https://opengameart.org/content/fox-and-shiba




// https://iquilezles.org/articles/intersectors
bool boxIntersect( in vec3 ro, in vec3 rd, in vec3 cen, in vec3 rad ) 
{
	vec3 roo = ro - cen;
    if( abs(roo.x)<rad.x && abs(roo.y)<rad.y && abs(roo.z)<rad.z ) return true;

    vec3 m = 1.0/rd;
    vec3 n = m*roo;
    vec3 k = abs(m)*rad;
	
    vec3 t1 = -n - k;
    vec3 t2 = -n + k;

	float tN = max( max( t1.x, t1.y ), t1.z );
	float tF = min( min( t2.x, t2.y ), t2.z );
	
	return ( tN < tF && tF > 0.0);
}


// https://iquilezles.org/articles/intersectors
vec3 triIntersect( in vec3 ro, in vec3 rd, in vec3 v0, in vec3 v1, in vec3 v2 )
{
    vec3 v1v0 = v1 - v0;
    vec3 v2v0 = v2 - v0;
    vec3 rov0 = ro - v0;

    vec3  n = cross( v1v0, v2v0 );
    vec3  q = cross( rov0, rd );
    float d = 1.0/dot( rd, n );
    float u = d*dot( -q, v2v0 );
    float v = d*dot(  q, v1v0 );
    float t = d*dot( -n, rov0 );

    if( u<0.0 || v<0.0 || (u+v)>1.0 ) t = -1.0;
    
    return vec3( t, u, v );
}

//===========================================================================

vec3 getVertex( int faceID, int vertexID )
{
    int row = faceID >> 6;
    int col = faceID & 63;
    return texelFetch( iChannel1, ivec2(col,row*3 + vertexID), 0 ).xyz;
}

// Brute force raytrace, no acceleration structure

#define ZERO min(0,iFrame)

bool intersectMesh( in vec3 ro, in vec3 rd, float tmax, out float oDis, out vec3 oNor, out vec2 oUV, out int oTri )
{
    ro.z += 0.5;
    if( !boxIntersect( ro, rd, vec3(0.0), vec3(0.18,0.3,0.52) ) )
        return false;
        
    bool res = false;
    float tmin = tmax;
    for( int i=ZERO; i<numFaces; i++ )
    {
		// get the triangle
        vec3 v0 = getVertex(i,0);
        vec3 v1 = getVertex(i,1);
        vec3 v2 = getVertex(i,2);

        vec3 h = triIntersect( ro, rd, v0, v1, v2 );
        if( h.x>0.0 && h.x<tmin)
        {
            tmin = h.x;
            oNor = normalize(cross(v1-v0,v2-v0));;
            oDis = tmin;
            oUV = h.yz;
            oTri = i;
            res = true;
        }
    }
    
    return res;
}

bool intersectShadowMesh( in vec3 ro, in vec3 rd )
{
    ro.z += 0.5;
    if( !boxIntersect( ro, rd, vec3(0.0), vec3(0.18,0.3,0.52) ) )
        return false;

    bool res = false;
    for( int i=ZERO; i<numFaces; i++ )
    {
		// get the triangle
        vec3 v0 = getVertex(i,0);
        vec3 v1 = getVertex(i,1);
        vec3 v2 = getVertex(i,2);

        vec3 h = triIntersect( ro, rd, v0, v1, v2 );
        if( h.x>0.0 )
        {
            res = true;
            break;
        }
    }
    
    return res;
}


float hash1( float n ) { return fract(sin(n)*158.5453123); }

//===========================================================================

// Terrain tracer, marches one triangle at a time, by Fizzer
const float minh = -2.3;
const float maxh = 2.23;

float height(vec2 p)
{
    float f = 0.5+0.5*sin(0.3*p.x)*sin(0.3*p.y);
    f *= mix(0.1,1.0,smoothstep(-1.0,0.0,-p.y+0.5*sin(p.x)) + smoothstep(4.0,8.0,p.y) );
	f = 0.95*f + 0.05*hash1( dot(p,vec2(1.0,111.1)));
    return mix(minh, maxh, f );
}

// by Fizzer: https://www.shadertoy.com/view/XlcBRX
vec3 intersectTerrain(vec3 o,vec3 r, out vec3 nn, out int tid)
{
    // Start ray at upper Y bounds
    //if(o.y > maxh) o += r * (maxh - o.y) / r.y;
    
    vec2 oc = vec2(floor(o.x), floor(o.z)), c;
    vec2 dn = normalize(vec2(-1, 1));
    vec3 ta, tb, tc;

    // Initialise the triangle vertices
    ta = vec3(oc.x, height(oc + vec2(0, 0)), oc.y);
    tc = vec3(oc.x + 1., height(oc + vec2(1, 1)), oc.y + 1.);
    if(fract(o.z) < fract(o.x))
        tb = vec3(oc.x + 1., height(oc + vec2(1, 0)), oc.y + 0.);
    else
        tb = vec3(oc.x, height(oc + vec2(0, 1)), oc.y + 1.);

    float t0 = 1e-4, t1;

    // Ray slopes
    vec2 dd = vec2(1) / r.xz;
    float dnt = 1.0 / dot(r.xz, dn);
    
    float s = max(sign(dnt), 0.);
    c = ((oc + max(sign(r.xz), 0.)) - o.xz) * dd;

    vec3 rs = sign(r);

    for(int i=ZERO; i<450; i++)
    {  
        t1 = min(c.x, c.y);

        // Test ray against diagonal plane
        float dt = dot(oc - o.xz, dn) * dnt;
        if(dt > t0 && dt < t1)
            t1 = dt;
 
        // Test ray against triangle plane
        vec3 hn = cross(ta - tb, tc - tb);
        float hh = dot(ta - o, hn) / dot(r, hn);

        if(hh > t0 && hh < t1)
        {
            // Intersection with triangle has been found
            nn = hn;
            
            float s = sign(nn.y);
            nn *= s;
            
            tid = int( dot(oc.xy+s,vec2(113,31)) );
            return o + r * hh;
        }

        vec2 offset;
        
        // Get an "axis selector", which has 1.0 for the near (intersected) axis
        // and 0.0 for the far one
        vec2 ss = step(c, c.yx);

        // Get the coordinate offset of where to read the next vertex height from
        if(dt >= t0 && dt < c.x && dt < c.y)
        {
            offset = vec2(1. - s, s);
        }
        else
        {
            offset = dot(r.xz, ss) > 0. ? vec2(2, 1) : vec2(-1, 0);

            if(c.y < c.x)
                offset = offset.yx;
        }

        // Get the next vertex
        vec3 tnew = vec3(oc + offset, height(oc + offset)).xzy;

        // Update the triangle vertices.
        if(dt >= t0 && dt < c.x && dt < c.y)
        {
            tb = tnew;
        }
        else
        {
            // Swap vertex order based on sign of ray axis
            if(dot(r.xz, ss) > 0.)
            {
                ta = tb;
                tb = tc;
                tc = tnew;
            }
            else
            {
                tc = tb;
                tb = ta;
                ta = tnew;
            }

            // Step the grid coordinates along to the next cell
            oc.xy += rs.xz * ss;
            c.xy += dd.xy * rs.xz * ss;
        }

        t0 = t1;

        // Test if the ray left the upper Y bounds
        if(((maxh - o.y) / r.y < t0 && r.y > 0.) || t0 > 200.)
            break;
    }
    tid = -1;
    return vec3(10000);
}

//=====================================================

mat3 setCamera( in vec3 ro, in vec3 rt, in float cr )
{
	vec3 cw = normalize(rt-ro);
	vec3 cp = vec3(sin(cr), cos(cr),0.0);
	vec3 cu = normalize( cross(cw,cp) );
	vec3 cv =          ( cross(cu,cw) );
    return mat3( cu, cv, -cw );
}


//=====================================================

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec3 tot = vec3(0.0);
    float tottmin = 1e10;
    
    #if AA>1
    for( int m=0; m<AA; m++ )
    for( int n=0; n<AA; n++ )
    {
        // pixel coordinates
        vec2 o = vec2(float(m),float(n)) / float(AA) - 0.5;
        vec2 p = (-iResolution.xy + 2.0*(fragCoord+o))/iResolution.y;
        #else    
        vec2 p = (-iResolution.xy + 2.0*fragCoord)/iResolution.y;
        #endif

        // camera
        float an = -0.07*(iTime-10.0) - 0.375;
        vec3 ro = vec3(1.5*sin(an),0.2,1.5*cos(an)-0.3);
        vec3 ta = vec3(0.2*cos(an),0.0,.2*sin(an)-0.3);
        vec3 of = sin(iTime+vec3(0.0,2.0,4.0));
        ro += 0.005*of*of*of;
        ta += 0.005*of*of*of;
        
        // ray
        mat3 ca = setCamera( ro, ta, -0.05);
        vec3 rd = normalize( ca * vec3(p,-4.0) );

        // sky
		vec3 lig = normalize( vec3( 0.4,0.3,0.3) );
        vec3 col = vec3(0.5,0.7,1.5)*1.25 - rd.y*0.6;
        col += 6.0*vec3(3.0,1.2,0.4)*pow(clamp(dot(rd,lig),0.0,1.0),24.0);

        float tmin = 1e10;
    
        vec3 mate = vec3(-1.0);
        vec3 nor = vec3(0.0);
        float occ = 1.0;
        
        // fox
		{
            float t;
            vec3 tnor;
            vec2 uv;
            int ttri;
            if( intersectMesh( ro, rd, tmin, t, tnor, uv, ttri ) )
            {
                nor = tnor;
                tmin = t;
                mate = vec3(0.2,0.2,0.2);
                mate = 0.35*vec3(0.36,0.13,0.028);
                
                if( ttri<126) mate = vec3(0.17);
				if( ttri>419) mate = 0.1*vec3(0.087, 0.040, 0.013);

                mate *= 0.7+0.6*texture(iChannel0,uv*0.1).x;
                #if 0
                mate *= 0.4 + 0.6*smoothstep( 0.0, 0.05, uv.x ) * 
                                  smoothstep( 0.0, 0.05, uv.y ) * 
                                  smoothstep( 0.0, 0.05, (1.0-uv.x-uv.y) );
                #endif
                mate *= 0.8;
                
                mate *= 0.8+0.4*hash1(float(ttri));
                
                occ = 0.5 + 0.5*nor.y;
            }
        }
        
        {
        // terrain
        vec3 tnor;
        int tid = -1;
        vec3 pos = intersectTerrain(ro*0.5,rd, tnor, tid)/0.5;
		float t = length(pos-ro);
        if( t>0.0 && t<tmin)
        {
            nor = normalize(tnor);
            tmin = t;
            vec3 pos = ro + t*rd;
            mate = 0.14*vec3(0.8,0.9,1.0);
            mate = mix( mate, vec3(0.025,0.02,0.015)*0.6, 1.0-smoothstep(0.9,1.0,nor.y) );
            
            mate *= 0.75+0.5*hash1(float(tid));
            mate *= 0.5+texture(iChannel0,pos.xz).x;
            
            occ *= 0.15 + 0.85*smoothstep( 0.0, 0.35, length((pos.xz-vec2(0.0,-0.46))*vec2(1.0,0.5)) );
        }
        }

        // shading
        if( mate.x>-0.5  )
        {
            vec3 pos = ro + tmin*rd;
            float fre = clamp(1.0+dot(nor,rd),0.0,1.0);
            float bou = clamp(0.3 - 0.7*nor.y,0.0,1.0);
            float dif = clamp(dot(nor,lig ),  0.0,1.0);
            
            if( dif>0.001 )
            if( length(pos.xz-vec2(-0.4,-0.4))<0.9 )
            if( intersectShadowMesh( pos+nor*0.001, lig ) )
                dif = 0.0;

            // perform lighting/shading
            vec3 brdf = 5.0*vec3(0.15,0.50,1.30)*occ + 
                        2.0*vec3(7.00,4.00,2.00)*dif +
                		1.0*vec3(0.60,0.65,0.70)*bou+
                        1.0*fre*(0.5+0.5*occ);

            col =  brdf * mate;

            // fog
            col = mix( col, vec3(0.7,0.9,1.5), 1.0-exp(-0.009*tmin) );
            
            // sun
            col += 1.2*vec3(3.0,1.0,0.4)*pow(clamp(dot(rd,lig),0.0,1.0),16.0);
            
        }
        #if AA>1
		tottmin = min(tottmin,tmin);
        #else
        tottmin = tmin;
        #endif
    
        // gamma
        col = pow( col, vec3(0.4545) );

	    tot += col;
    #if AA>1
    }
    tot /= float(AA*AA);
    #endif
    
    
	fragColor = vec4( tot, tottmin );
}

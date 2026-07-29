// Buffer B (buffer) — Protein by iq
// https://www.shadertoy.com/view/M3BfW3

// https://iquilezles.org/articles/intersectors/
vec2 sphIntersect( in vec3 ro, in vec3 rd, in vec4 sph ) 
{
    vec3 oc = ro - sph.xyz;
    float b = dot( oc, rd );
    float c = dot( oc, oc ) - sph.w*sph.w;
    float h = b*b - c;
    if( h<0.0 ) return vec2(-1.0);
    h = sqrt(h);
    return vec2(-b-h,-b+h);
}

vec3 sphNormal( in vec3 p, in vec4 sph ) 
{
    return (p-sph.xyz)/sph.w;
}

//=====================================================================
//
// L0            _ 1 _
//             _/     \_
//            /         \          Down:  node *= 2
// L1        2           3         Right: node += 1
//         /   \       /   \       Up:    node /= 2
// L2     4     5     6     7
//       / \   / \   / \   / \
// L3   8   9 10 11 12 13 14 15
//
//=====================================================================


vec4 getSphere( in uint id )
{
#if 1
    // precomputed
    return texelFetch( iChannel2, ivec2(id&255u,id>>8), 0 );
#else    
    // not precomputed
    return createSphere( id );
#endif    
}

const uint kMaxLevel = 14u;
const uint kMaxNode = 1u<<kMaxLevel;

// https://iquilezles.org/articles/binarysearchsdf/
float raycastFirst( in vec3 ro, in vec3 rd, out uint oID)
{
    float res = 1e30;
    
    uint nod = 1u;                              // Start at the root node
	for( uint i=0u; i<=kMaxNode; i++ )
	{
        vec4 sph = getSphere( nod );
        vec2 tmp = sphIntersect( ro, rd, sph );
        if( tmp.y>0.0 && tmp.x<res )            // If ray intersects node, and closer
        {
            if( nod>=kMaxNode )                 // if leaf
            {
                res = tmp.x;                    // then store intersection
                oID = nod;
                
                for(;(nod&1u)==1u;nod>>=1);     // and resume traversal
                if( nod==0u ) break;
                nod++;
            }
            else                                // or if node isn't a leaf
            {
                nod <<= 1;                      // then continue down to left child
            }
        }
        else                                    // But if ray doesn't intersect node
        {
            for(;(nod&1u)==1u;nod>>=1);         // then skip whole subtree
            if( nod==0u ) break;
            nod++;
        }
	}

    return res;
}

// https://iquilezles.org/articles/binarysearchsdf/
float raycastAny( in vec3 ro, in vec3 rd )
{
    uint nod = 1u;
	for( uint i=0u; i<=kMaxNode; i++ )
	{
        vec4 sph = getSphere( nod );
        vec2 tmp = sphIntersect( ro, rd, sph );
        if( tmp.y>0.0 )
        {
            if( nod>=kMaxNode ) return 0.0;
            nod <<= 1;
        }
        else
        {
            for(;(nod&1u)==1u;nod>>=1);
            if( nod==0u ) break;
            nod++;
        }
	}
    return 1.0;
}

//=====================================================================

// from fizzer (link no longer exsists)
vec3 cosineDirection( in vec3 nor, in vec2 r)
{
    float a = 6.2831853*r.x;
    float u = 2.0*r.y-1.0;
    return normalize(nor+vec3(sqrt(1.0-u*u)*vec2(cos(a),sin(a)),u));
}

mat4x4 setCameraToWorld( in vec3 ro, in vec3 ta, float cr )
{
	vec3 cw = normalize(ro-ta);
	vec3 cp = vec3(0.0, cos(cr),sin(cr));
	vec3 cu = normalize(cross(cp,cw));
	vec3 cv =          (cross(cw,cu));
    return mat4x4( cu, 0.0, cv, 0.0, cw, 0.0, ro, 1.0);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    ivec2 ip = ivec2(fragCoord);
    
    // randoms
    vec4 r = texelFetch( iChannel1, (ip+ivec2(7,11)*iFrame)&1023, 0 );

    // raster (fragCoord) to ndc space (p)
	vec2 off = r.xy-0.5;
    vec2 p = (2.0*(fragCoord+off)-iResolution.xy)/iResolution.y;

    // camera
    float an = 0.05*iTime;
    float cr = 0.1*sin(an);
	vec3  ta = vec3(0.4,-0.2,1.1);
	vec3  ro = ta + vec3( 3.0*cos(an), 0.5, 3.0*sin(an) );
    float fl = 2.85;
    mat4x4 camera2world = setCameraToWorld( ro, ta, cr );
    
	// ray (in world space)
    vec3 rd = normalize( (camera2world*vec4(p,-fl,0.0)).xyz );
    //ro = (camera2world*vec4(0.0,0.0,0.0,1.0)).xyz;

    // background
    vec3 col = vec3(0.9);
    
    // protein
    uint id = 0u;
    float t = raycastFirst( ro, rd, id );
    if( t<1e29 )
    {
        // surface
        vec4 sph = getSphere(id);
        vec3 pos = ro + t*rd;
        vec3 nor = sphNormal( pos, sph );
        
        // material
        vec3 mate = 0.5 + 0.5*sin( float(id)*0.0002 + 1.0 + vec3(0.0,3.0,4.0) );
        if( sph.w<0.05 ) mate = vec3(1.0);
        mate += 0.2*sin( float(id) + vec3(0.9,2.0,2.4) );
        mate = clamp( mate, 0.0, 1.0 );
        
        // lighting
        #if HW_PERFORMANCE==0
        vec3 dir = cosineDirection(nor,r.zw);
        float occ = (dir.y<0.0 ) ? 0.0 : raycastAny( pos+nor*0.001, dir );
        #else
        float occ = 0.0;
        const int num = 4;
        for( int i=0; i<num; i++ )
        {
            vec4 r = texelFetch( iChannel1, (ip+ivec2(17,13)*(iFrame*7+i))&1023, 0 );
            vec3 dir = cosineDirection(nor,r.zw);
            occ += (dir.y<0.0 ) ? 0.0 : raycastAny( pos+nor*0.001, dir );
        }
        occ /= float(num);
        #endif
        float dif = 0.5+0.5*nor.y;
        vec3  ref = reflect( rd, nor );
        float fre = clamp(1.0+dot(rd,nor),0.0,1.0);
        float spe = smoothstep(-0.1,0.1,ref.y)*(0.04+0.96*pow(fre,5.0))*dif*4.0;
        if( spe>0.001 ) spe *= raycastAny( pos+nor*0.001, ref );
        col = mate*occ*(1.0+fre) + spe;
    }

	// project to previous frame and average
    mat4x4 oldCamera2World = mat4( texelFetch(iChannel0,ivec2(0,0),0),
                                   texelFetch(iChannel0,ivec2(1,0),0),
                                   texelFetch(iChannel0,ivec2(2,0),0),
                                   texelFetch(iChannel0,ivec2(3,0),0) );
    mat4x4 oldWorldToCamera = inverse(oldCamera2World);
    
    // world space
    vec4 wpos = vec4(ro + rd*t,1.0);
    // world to camera
    vec3 cpos = (oldWorldToCamera*wpos).xyz;
    // camera to ndc
    vec2 npos = -fl*cpos.xy/cpos.z;
    // ndc to raster (inverse of line 137)
    vec2 rpos = 0.5*(iResolution.xy + iResolution.y*npos) - off - 0.5;
    
    // blend pixel color history
    ivec2 ipos = ivec2(floor(rpos));
    if( (ipos.y>0 || ipos.x>3) && iFrame>0 && t<1e29)
    {
        #if 1
        vec2 fuv = rpos - vec2(ipos);
        vec4 odata1 = texelFetch(iChannel0,ipos+ivec2(0,0),0);
        vec4 odata2 = texelFetch(iChannel0,ipos+ivec2(1,0),0);
        vec4 odata3 = texelFetch(iChannel0,ipos+ivec2(0,1),0);
        vec4 odata4 = texelFetch(iChannel0,ipos+ivec2(1,1),0);
        vec4 ocol = vec4(0.0);
        if( abs(t-odata1.w)<0.1 ) {ocol+=vec4(odata1.xyz,1.0)*(1.0-fuv.x)*(1.0-fuv.y);}
        if( abs(t-odata2.w)<0.1 ) {ocol+=vec4(odata2.xyz,1.0)*(    fuv.x)*(1.0-fuv.y);}
        if( abs(t-odata3.w)<0.1 ) {ocol+=vec4(odata3.xyz,1.0)*(1.0-fuv.x)*(    fuv.y);}
        if( abs(t-odata4.w)<0.1 ) {ocol+=vec4(odata4.xyz,1.0)*(    fuv.x)*(    fuv.y);}
        if( ocol.w>0.001 ) col = mix( max(ocol.xyz/ocol.w,0.0), col, 0.05 );
		#else
        col = mix( textureLod( iChannel0, (rpos+0.5)/iResolution.xy, 0.0 ).xyz, col, 0.05 );
        #endif
    }

    // output color (or camera matrix)
    fragColor = (ip.y==0 && ip.x<=3) ? camera2world[ip.x] : vec4( col, t );
}
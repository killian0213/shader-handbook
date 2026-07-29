// Buffer A (buffer) — Pixel Art Aesthetics by ChrisK
// https://www.shadertoy.com/view/tt3yR2

// 3D CALCULATIONS HAPPEN HERE

// shapes are generated using simplified versions of
// the functions described by Inigo Quilez in this article:
// https://iquilezles.org/articles/intersectors 


#define rot2(a) mat2(cos(a),-sin(a),sin(a),cos(a))

int shape = 0;

vec3 rotate ( vec3 p, vec3 r ) {
    p.yz *= rot2(r.x);
    p.xz *= rot2(-r.y);
    p.xy *= rot2(r.z);
    return p;
}


float IntersectUnitCube ( vec3 ro, vec3 rd ) {
    vec3 tmin = (0.5-ro)/rd;							// distances to positive planes
    vec3 tmax = (-0.5-ro)/rd;							// distances to negative planes
    vec3 rmin = min(tmin, tmax);						// distances to front-facing planes
    vec3 rmax = max(tmin, tmax);						// distances to back-facing planes
    float dback  = min( min(rmax.x, rmax.y), rmax.z );	// distance to nearest back-facing side
    float dfront = max( max(rmin.x, rmin.y), rmin.z );	// distance to furthest front-facing side (possible collision distance)
    return dback>=dfront ? dfront : -dfront;
}


float IntersectSphere ( vec3 ro, vec3 rd, float rad ) {
    float b = dot(ro,rd);
    float h = b*b - dot(ro,ro) + rad*rad;
    return (h<0.0) ? -1.0 : -b-sqrt(h);   // -b+sqrt(h) = backface distance
}


float IntersectXUnitCylinder ( vec3 ro, vec3 rd, float rad ) {
    vec3 oc = ro + vec3(0.5,0.0,0.0);
    float a = 1.0 - rd.x*rd.x;
    float b = dot(oc,rd) - oc.x*rd.x;
    float c = oc.y*oc.y + oc.z*oc.z - rad*rad;
    float h = b*b - a*c;
    if( h<0.0 ) return -1.0;              // miss
    h = sqrt(h);
    float t = (-b-h)/a;
    float y = oc.x + t*rd.x;
    if( y>0.0 && y<1.0 ) return t;        // body hit?
    t = (float(y>=0.0) - oc.x)/rd.x;
    return ( abs(b+a*t)<h ) ? t : -1.0;   // cap hit?
}


float IntersectCone( vec3 ro, vec3 rd, float h, float r ) {
    vec3  oa = ro - vec3(0.0, h*0.5, 0.0);
    float m0 = h*h;
    float m1 = oa.y*-h;
    float m2 = rd.y*-h;
    if( m1<0.0 && dot(oa*m2-rd*m1, oa*m2-rd*m1)<(r*r*m2*m2) ) return -m1/m2;  // cap hit?
    float hy = m0 + r*r;
    float k2 = m0*m0            - m2*m2*hy;
    float k1 = m0*m0*dot(rd,oa) - m1*m2*hy + m0*r*r* m2;
    float k0 = m0*m0*dot(oa,oa) - m1*m1*hy + m0*r*r*(m1*2.0 - m0);
    float t = ( -k1-sqrt(k1*k1 - k2*k0) ) / k2;
    float y = m1 + t*m2;
    return ( y>=0.0 && y<=m0 ) ? t : -1.0;   // body hit?
}


vec4 getrendersample ( vec3 ro, vec3 rd ) {
    float rl;
    switch(shape) {
    case 0:
        rl = IntersectUnitCube( ro, rd );
        break;
    case 1:
        rl = IntersectSphere( ro, rd, 0.6 );
        break;
    case 2:
        rl = IntersectXUnitCylinder( ro, rd, 0.6 );
        break;
    case 3:
        rl = IntersectCone( ro, rd, 1.2, 0.6 );
        break;
    }
    
    if ( rl > 0.0 ) {
		vec3 xyz = ro + rd*rl;
        
        vec3 nor;                 // surface normal
        float dith = 0.0;         // how much lighting is dithered across surface
        switch(shape) {
        case 0: // unit cube
            nor = round( xyz*1.00001 );
            break;
        case 1: // sphere
            nor = normalize(xyz); dith = 0.35;       
            break;
        case 2: // unit length x-cylinder
            if (abs(xyz.x)>0.4999) { nor = vec3(0.0,0.0,sign(xyz.x)); } else { nor = vec3(0.0,normalize(xyz.yz)); dith = 0.35; }
            break;
        case 3: // cone (h=1.2, r=0.6)
            if (abs(xyz.y)>0.5999) { nor = vec3(0.0,sign(xyz.y),0.0); } else { nor = normalize(vec3(xyz.x,-(length(xyz.xz)/2.0),xyz.z)); dith = 0.35; }
            break;
        }
        
        // material ID
        float mat = (xyz.x>0.0 ^^ xyz.y>0.0 ^^ xyz.z>0.0) ? 1.0 : 2.0;
        
        // lambertian diffuse
        vec3 ld = normalize( vec3(1,2,1) );
        float br = max( dot(-ld,nor), 0.0);
        
        // phong specular
        float spec = 0.0;
        if (br>0.0) {
            vec3 h = -normalize(ld+rd);
            spec = pow( dot(nor,h), 500.0);
        }
        
        // depth
        float depth = rotate(xyz, -vec3(iTime*0.5)).z + 5.0;
        
        return vec4( mat, br, dith, spec );
    } else {
        return vec4( 0.0 );
	}
}


void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
    vec2 uv = fragCoord.xy/IRES;
    uv = uv*2.0 - 1.0;

    vec2 tile = floor( (uv+1.0)*0.5 );
    shape = int( floor( mod(tile.x,2.0) )
               + floor( mod(tile.y,2.0) ) * 2.0 );

    uv = mod( uv+1.0, vec2(2.0) ) - 1.0;
    uv.y *= IRES.y/IRES.x;
    
    //vec3 r = vec3(iTime*0.5);
    vec3 r = vec3( -iMouse.yx/iResolution.yx*7.0, 0.0 ); 
    
    vec3 campos = vec3(0.0,0.0,-2.5);
    vec3 camray = normalize( vec3(uv,1.35) );
    campos = rotate( campos, r );
    camray = rotate( camray, r );
     
    fragColor = getrendersample( campos, camray );
}
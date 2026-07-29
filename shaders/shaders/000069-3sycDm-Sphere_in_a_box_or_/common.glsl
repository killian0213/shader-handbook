// Common (common) — Sphere in a box or ... by xjorma
// https://www.shadertoy.com/view/3sycDm

// my modified round intersection from https://www.shadertoy.com/view/wsyyWw

// intersect capsule : https://iquilezles.org/articles/intersectors
float capIntersect( in vec3 ro, in vec3 rd, in vec3 pa, in vec3 pb, in float r )
{
    vec3  ba = pb - pa;
    vec3  oa = ro - pa;

    float baba = dot(ba,ba);
    float bard = dot(ba,rd);
    float baoa = dot(ba,oa);
    float rdoa = dot(rd,oa);
    float oaoa = dot(oa,oa);

    float a = baba      - bard*bard;
    float b = baba*rdoa - baoa*bard;
    float c = baba*oaoa - baoa*baoa - r*r*baba;
    float h = b*b - a*c;
    if( h>=0.0 )
    {
        float t = (-b-sqrt(h))/a;

        float y = baoa + t*bard;
        
        // body
        if( y>0.0 && y<baba ) return t;

        // caps
        vec3 oc = (y<=0.0) ? oa : ro - pb;
        b = dot(rd,oc);
        c = dot(oc,oc) - r*r;
        h = b*b - c;
        if( h>0.0 )
        {
            return -b - sqrt(h);
        }
    }
    return -1.;
}

// intersect a ray with a rounded box
// https://iquilezles.org/articles/intersectors
// Modified to support bigger radius, probably more optimal solution, but was too lazy and nor as good as IQ :(
// I kept the -1 for no collision paradigm even if I hate it (Make code more complex), but I prefered to stay compatible with IQ interface.
float roundedboxIntersect( in vec3 ro, in vec3 rd, in vec3 size, in float rad )
{
    
	// bounding box
    vec3 m = 1.0/rd;
    vec3 n = m*ro;
    vec3 k = abs(m)*(size+rad);
    vec3 t1 = -n - k;
    vec3 t2 = -n + k;
	float tN = max( max( t1.x, t1.y ), t1.z );
	float tF = min( min( t2.x, t2.y ), t2.z );
	if( tN > tF || tF < 0.0) return -1.0;
    float t = tN;

    // convert to first octant
    vec3 pos = ro+t*rd;
    vec3 s = sign(pos);
    ro  *= s;
    rd  *= s;
    pos *= s;
        
    // faces
    pos -= size;
    pos = max( pos.xyz, pos.yzx );
    if( min(min(pos.x,pos.y),pos.z)<0.0 ) return t;
  
  	// fat edges
    float d;
    d = capIntersect(ro, rd, size * vec3(-1, 1, 1), size, rad);
    t = d > 0. ? d : 1e20;
    d = capIntersect(ro, rd, size * vec3( 1,-1, 1), size, rad);
    t = min(d > 0. ? d : 1e20, t);    
    d = capIntersect(ro, rd, size * vec3( 1, 1,-1), size, rad);
    t = min(d > 0. ? d : 1e20, t);    

    if( t>1e19 ) t=-1.0;
    
	return t;
}

// normal of a rounded box
vec3 roundedboxNormal( in vec3 pos, in vec3 siz, in float rad )
{
    return sign(pos)*normalize(max(abs(pos)-siz,0.0));
    
}

mat3 fromEuler(vec3 ang)
{
    mat3 mx = mat3(
			1.0,		0.0,		0.0,
			0.0,		cos(ang.x),	-sin(ang.x),
			0.0,		sin(ang.x),	cos(ang.x));
    mat3 my = mat3(
			cos(ang.y), 0.0,		sin(ang.y),
			0.0,		1.0,		0.0,
			-sin(ang.y),0.0,		cos(ang.y));
    mat3 mz = mat3(
			cos(ang.z), -sin(ang.z),0.0,
			sin(ang.z),	cos(ang.z),	0.0,
			0.0,		0.0,		1.0);
        
    return mx*my*mz;
}



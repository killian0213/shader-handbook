// Image (image) — iSimplexPrim by paniq
// https://www.shadertoy.com/view/XtSyRD


// uncomment to solve for quadratic surface only
#define HIT_TET_PLANES

void compute_edges(vec3 p[4], out vec3 e[6]) {
    e[0] = p[2] - p[1];
    e[1] = p[0] - p[2];
    e[2] = p[1] - p[0];
    e[3] = p[1] - p[3];
    e[4] = p[2] - p[3];
    e[5] = p[0] - p[3];
}

void compute_planes(vec3 p[4], out vec3 n[3]) {
    vec3 e[6];
    compute_edges(p, e);
    n[0] = cross(e[0], e[3]);
    n[1] = cross(e[1], e[4]);
    n[2] = cross(e[2], e[5]);
    float det = 1.0/dot(n[0], e[1]);
    // premultiply the plane orthogonals by the inverse determinant
    n[0] *= det;
    n[1] *= det;
    n[2] *= det;
}

// computes barycentric coordinates for point from the fourth vertex,
// three plane normals with premultiplied inverse determinant
vec4 to_bary(vec3 p3, vec3 n[3], vec3 t) {
    // weights are scaled distance of point to individual planes
    t -= p3;
    float w0 = dot(t, n[0]); 
    float w1 = dot(t, n[1]); 
    float w2 = dot(t, n[2]); 
    float w3 = 1.0 - w0 - w1 - w2;
    return vec4(w0, w1, w2, w3);
}

vec3 from_bary(vec3 p[4], vec4 w) {
	return p[0] * w.x + p[1] * w.y + p[2] * w.z + p[3] * w.w;
}

vec3 normal_from_bary(vec3 n[3], vec4 w) {
    return normalize(n[0] * (w.w - w.x) + n[1] * (w.w - w.y) + n[2] * (w.w - w.z));
}

// evaluate quadratic in tetrahedron with given corners and midweights
// first set of weights are the weights on face xyz opposite of each vertex
// second set of weights are on edges xyz-w
float eval_quadratic(vec4 w, vec4 c, vec3 m1, vec3 m2) {
    return w.x*w.x*c.x + w.y*w.y*c.y + w.z*w.z*c.z + w.w*w.w*c.w
        + 2.0*(m1.x*w.y*w.z + m1.y*w.x*w.z + m1.z*w.x*w.y
             + m2.x*w.w*w.x + m2.y*w.w*w.y + m2.z*w.w*w.z);
}

// return first derivative at given point in barycentric basis
vec4 eval_quadratic_diff(vec4 w, vec4 c, vec3 m1, vec3 m2) {
    return 2.0*vec4(
    m2.x*w.w + c.x*w.x + m1.z*w.y + m1.y*w.z,
    m2.y*w.w + m1.z*w.x + c.y*w.y + m1.x*w.z,
    m2.z*w.w + m1.y*w.x + m1.x*w.y + c.z*w.z,
    c.w*w.w + m2.x*w.x + m2.y*w.y + m2.z*w.z
	);
}

struct Hit {
    // ray scalar
    float t;
    // barycenter
    vec4 b;
    // normal
    vec3 n;
};

// return normal of nearest plane in barycentric coordinates
vec4 select_plane_normal(vec4 b) {
    float lc = min(min(b.x, b.y), min(b.z, b.w));
    return step(b, vec4(lc));
}

// return the intersection of ray, tetrahedron and a quadratic function
// with the corner weights c and the edge weights m1 and m2
// as well as the barycentric coordinates and normals of the hit points
bool iSimplexPrim(vec3 p[4], 
	vec4 c, vec3 m1, vec3 m2, 
	vec3 ro, vec3 rd, 
	out Hit near, out Hit far) {
    
    vec3 sn[3];
    compute_planes(p, sn);
    
    // convert ray endpoints to barycentric basis
    // this can be optimized further by caching the determinant
    vec4 r0 = to_bary(p[3], sn, ro);
    vec4 r1 = to_bary(p[3], sn, ro + rd);

    // build barycentric ray direction from endpoints
    vec4 brd = r1 - r0;
    // compute ray scalars for each plane
    vec4 t = -r0/brd;
    
    // valid since GL 4.1
    near.t = -1.0 / 0.0;
    far.t = 1.0 / 0.0;    
#if 0
    for (int i = 0; i < 4; ++i) {
        // equivalent to checking dot product of ray dir and plane normal
        if (brd[i] < 0.0) {
            far.t = min(far.t, t[i]);
        } else {
            near.t = max(near.t, t[i]);
        }
    }
#else
    // loopless, branchless alternative
    // equivalent to checking dot product of ray dir and plane normal    
    bvec4 comp = lessThan(brd, vec4(0.0));
    vec4 far4 = mix(vec4(far.t), t, comp);
    vec4 near4 = mix(t, vec4(near.t), comp);
    far.t = min(min(far4.x,far4.y),min(far4.z,far4.w));
    near.t = max(max(near4.x,near4.y),max(near4.z,near4.w));
#endif
    
    if ((far.t <= 0.0) || (far.t <= near.t))
        return false;
    near.b = r0 + brd * near.t;
    far.b = r0 + brd * far.t;

#ifdef HIT_TET_PLANES
    vec4 n0 = select_plane_normal(near.b);
    vec4 n1 = select_plane_normal(far.b);
#else
    vec4 n0;
    vec4 n1;
#endif
        
#if 1
    // reconstruct 1D quadratic coefficients from three samples
    float c0 = eval_quadratic(near.b, c, m1, m2);
    float c1 = eval_quadratic(r0 + brd * (near.t + far.t) * 0.5, c, m1, m2);
    float c2 = eval_quadratic(far.b, c, m1, m2);

    float A = 2.0*(c2 + c0 - 2.0*c1);
    float B = 4.0*c1 - 3.0*c0 - c2;
    float C = c0;
    
    if (A == 0.0) return false;
    // solve quadratic
    float k = B*B - 4.0*A*C;
    if (k < 0.0)
        return false;
    k = sqrt(k);
    float d0 = (-B - k) / (2.0*A);
    float d1 = (-B + k) / (2.0*A);
    
    //if (min(B,C) > 0.0) return false;
    
    if (d0 > 1.0) return false;
    // for a conic surface, d1 can be smaller than d0
    if ((d1 <= d0)||(d1 > 1.0))
        d1 = 1.0;
    else if (d1 < 0.0) return false;
    if (d0 > 0.0) {
        near.t = near.t + (far.t - near.t)*d0;
    }
    far.t = near.t + (far.t - near.t)*d1;
    near.b = r0 + brd * near.t;
    far.b = r0 + brd * far.t;
#ifdef HIT_TET_PLANES
    if ((d0 > 0.0) && (d0 < 1.0)) {
        n0 = -eval_quadratic_diff(near.b, c, m1, m2);
    }
    if ((d1 > 0.0) && (d1 < 1.0)) {
        n1 = -eval_quadratic_diff(far.b, c, m1, m2);
    }
#else
    if ((d0 > 0.0) && (d0 < 1.0)) {
        n0 = -eval_quadratic_diff(near.b, c, m1, m2);
    } else if ((d1 > 0.0) && (d1 < 1.0)) {
        n0 = eval_quadratic_diff(far.b, c, m1, m2);
    }  else {
        return false;
    }
#endif
    
#else
#endif
    near.n = normal_from_bary(sn, n0);
    far.n = normal_from_bary(sn, n1);
    return true;
}

////////////////////////////////////////////////////////////////////////


void doCamera( out vec3 camPos, out vec3 camTar, in float time, in float mouseX )
{
    float an = iTime * 0.5;
    float d = 3.0;
	camPos = vec3(d*sin(an),mix(-0.8,2.0,sin(iTime*0.25)*0.5+0.5),d*cos(an));
    camTar = vec3(0.0,0.0,0.0);
}


vec3 doBackground( void )
{
    return vec3( 0.0, 0.0, 0.0);
}

vec3 hue(float hue) {
    return clamp(
        abs(mod(hue * 6.0 + vec3(0.0, 4.0, 2.0), 6.0) - 3.0) - 1.0,
        0.0, 1.0);
}

vec3 hsl(float h, float s, float l) {
    vec3 rgb = hue(h);
    return l + s * (rgb - 0.5) * (1.0 - abs(2.0 * l - 1.0));
}

vec4 hsl(float h, float s, float l, float a) {
    return vec4(hsl(h,s,l),a);
}

float imTestSphere(vec3 p) {
    float r = 0.5;
    return p.x*p.x + p.y*p.y + p.z*p.z - r*r;
}

float imTestCylinder(vec3 p) {
    float r = 0.5;
    return p.x*p.x + p.y*p.y - r*r;
}

float imTestCone(vec3 p) {
    p.z = (p.z - 1.0)*0.5;
    float r = 0.5;
    return (p.x*p.x + p.y*p.y)/(r * r) - p.z*p.z;
}

float imSolid(vec3 p) {
    float r = 1.0;
    return p.x*p.x + p.y*p.y - r*r;
}

#define SHAPE_COUNT 5.0
void getfactor (int i, out float c[6], out float m[12]) {
    // reference coordinates
    vec3 p[6];
    p[0] = vec3(cos(radians(0.0)),sin(radians(0.0)),-1.0);
    p[1] = vec3(cos(radians(120.0)),sin(radians(120.0)),-1.0);
    p[2] = vec3(cos(radians(240.0)),sin(radians(240.0)),-1.0);
    p[3] = vec3(cos(radians(0.0)),sin(radians(0.0)), 1.0);
    p[4] = vec3(cos(radians(240.0)),sin(radians(240.0)), 1.0);
    p[5] = vec3(cos(radians(120.0)),sin(radians(120.0)), 1.0);

#define DEF_C(F) for (int i = 0; i < 6; ++i) { c[i] = F(p[i]); }
#define DEF_M(I, F, V1, V2) m[I] = F((p[V1]+p[V2])*0.5)*2.0 - (c[V1]+c[V2])*0.5
#define DEF_M0(F) DEF_M(0, F, 1, 2); DEF_M(1, F, 2, 0); DEF_M(2, F, 1, 0);
#define DEF_M1(F) DEF_M(3, F, 4, 5); DEF_M(4, F, 5, 3); DEF_M(5, F, 4, 3);
#define DEF_M2(F) DEF_M(6, F, 3, 0); DEF_M(7, F, 2, 3); DEF_M(8, F, 2, 4);
#define DEF_M3(F) DEF_M(9, F, 4, 1); DEF_M(10, F, 5, 1); DEF_M(11, F, 1, 3);
#define DEF_F(F) DEF_C(F); DEF_M0(F); DEF_M1(F); DEF_M2(F); DEF_M3(F);
    
    if (i == 0) {
        DEF_F(imTestSphere);
    } else if (i == 1) {
        DEF_F(imTestCylinder);
    } else if (i == 2) {
        DEF_F(imTestCone);
    } else if (i == 3) {
        DEF_F(imSolid);
    } else if (i == 4) {
        for (int i = 0; i < 6; ++i) {
            c[i] = 2.0;
        }
        for (int i = 0; i < 12; ++i) {
            m[i] = -1.0;
        }        
    }
}

void anim_coeffs(out float c[6], out float m[12]) {
    float k = iTime*0.5;
    float u = smoothstep(0.0,1.0,smoothstep(0.0,1.0,fract(k)));
    int s1 = int(mod(k,SHAPE_COUNT));
    int s2 = int(mod(k+1.0,SHAPE_COUNT));
    float c1[6];
    float c2[6];
    float m1[12];
    float m2[12];
    getfactor(s1, c1, m1);
    getfactor(s2, c2, m2);
    for (int i = 0; i < 6; ++i) {
        c[i] = mix(c1[i],c2[i],u);
    }
    for (int i = 0; i < 12; ++i) {
        m[i] = mix(m1[i],m2[i],u);
    }
}

vec2 rotate_xy(vec2 p, float a) {
    vec2 o;
    float s = sin(a); float c = cos(a);
    o.x = c*p.x + s*p.y;
    o.y = -s*p.x + c*p.y;
    return o;
}

void anim_split(inout vec3 p[4]) {
#if 0
    vec3 c = (p[0]+p[1]+p[2]+p[3])/4.0;
    float s = mix(1.0, 0.8, clamp(pow(sin(iTime*0.1),16.0),0.0,1.0));
    for (int i = 0; i < 4; ++i) {
	    p[i] = c + (p[i] - c)*s;
    }
#endif
}

bool anim_prism( in vec3 ro, in vec3 rd, out Hit h0, out Hit h1) {
    // prism vertices
    vec3 p[6];
    p[0] = vec3(cos(radians(0.0)),sin(radians(0.0)),-1.0);
    p[1] = vec3(cos(radians(120.0)),sin(radians(120.0)),-1.0);
    p[2] = vec3(cos(radians(240.0)),sin(radians(240.0)),-1.0);
    p[3] = vec3(cos(radians(0.0)),sin(radians(0.0)), 1.0);
    p[4] = vec3(cos(radians(240.0)),sin(radians(240.0)), 1.0);
    p[5] = vec3(cos(radians(120.0)),sin(radians(120.0)), 1.0);
    for (int i = 3; i < 6; ++i) {
        vec3 v = p[i];
        v.xz = rotate_xy(v.xz, sin(iTime * 10.0)*sin(iTime)*0.1);
        v.z += mix(-1.5, 0.0, sin(iTime * 0.2)*0.5+0.5);
        p[i] = v;
        
    }
    float c[6];
    c[0] = 2.0; c[1] = 2.0; c[2] = 2.0;
    c[3] = 2.0; c[4] = 2.0; c[5] = 2.0;
    float m[12];
    m[0] = -1.0; m[ 1] = -1.0; m[ 2] = -1.0;
    m[3] = -1.0; m[ 4] = -1.0; m[ 5] = -1.0;
    m[6] = -1.0; m[ 7] = -1.0; m[ 8] = -1.0;
    m[9] = -1.0; m[10] = -1.0; m[11] = -1.0;

    anim_coeffs(c, m);
    
    vec4 qc; vec3 qm1, qm2;
    
    vec3 q[4];
    Hit near; Hit far;
    h0.t = 1.0/0.0;
	h1.t = -1.0/0.0;
    q[0] = p[0]; q[1] = p[1]; q[2] = p[2]; q[3] = p[3];
    anim_split(q);
    qc = vec4(c[0], c[1], c[2], c[3]);
    qm1 = vec3(m[0], m[1], m[2]); qm2 = vec3(m[6], m[11], m[7]);
    bool hit = false;
    if (iSimplexPrim(q, qc, qm1, qm2, ro, rd, near, far)) {
        if (near.t < h0.t)
            h0 = near;
        if (far.t > h1.t)
            h1 = far;
        hit = true;
    }
    q[0] = p[1]; q[1] = p[2]; q[2] = p[3]; q[3] = p[4];
    anim_split(q);
    qc = vec4(c[1], c[2], c[3], c[4]);
    qm1 = vec3(m[7], m[11], m[0]); qm2 = vec3(m[9], m[8], m[5]);
    if (iSimplexPrim(q, qc, qm1, qm2, ro, rd, near, far)) {
        if (near.t < h0.t)
            h0 = near;
        if (far.t > h1.t)
            h1 = far;
        hit = true;
    }
    q[0] = p[3]; q[1] = p[4]; q[2] = p[5]; q[3] = p[1];
    anim_split(q);
    qc = vec4(c[3], c[4], c[5], c[1]);
    qm1 = vec3(m[3], m[4], m[5]); qm2 = vec3(m[11], m[9], m[10]);
    if (iSimplexPrim(q, qc, qm1, qm2, ro, rd, near, far)) {
        if (near.t < h0.t)
            h0 = near;
        if (far.t > h1.t)
            h1 = far;
        hit = true;
    }    
    return hit;
}

vec3 calc_intersection( in vec3 ro, in vec3 rd ) {
    ro = ro.zxy;
    rd = rd.zxy;    
    vec3 l = normalize(vec3(1.0, -1.0, -2.0));
    
    vec3 col = vec3(0.0);
    
    Hit h0, h1;
    if (anim_prism(ro, rd, h0, h1)) {
        vec4 c = (h0.t > 0.0)?h0.b:h1.b;
        
        float lit = max(0.0, dot(l, -h0.n));
        
        lit += 0.1;
        
#if 1
        col += lit * vec3(0.1, 0.5, 1.0);
#else
        col += lit * (
              c.x * vec3(1.0, 0.0, 0.0)
        	+ c.y * vec3(0.0, 1.0, 0.0)
            + c.z * vec3(0.0, 0.0, 1.0)
            + c.w * vec3(1.0, 1.0, 1.0));
#endif
        col += lit * pow(max(0.0, dot(-l, reflect(rd, h0.n)) - 0.1), 25.0)*1e-7;
    } else {
        float plane_t = -(ro.z + 1.0) / rd.z;
        if (plane_t > 0.0) {
            vec3 plane_p = ro + rd * plane_t;

            float sh = anim_prism(plane_p, -l, h0, h1)?0.3:1.0;
            col += vec3(sh) * abs(rd.z);
        }
    }    
    return col;
}

mat3 calcLookAtMatrix( in vec3 ro, in vec3 ta, in float roll )
{
    vec3 ww = normalize( ta - ro );
    vec3 uu = normalize( cross(ww,vec3(sin(roll),cos(roll),0.0) ) );
    vec3 vv = normalize( cross(uu,ww));
    return mat3( uu, vv, ww );
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 p = (-iResolution.xy + 2.0*fragCoord.xy)/iResolution.y;

    vec3 ro, ta;
    doCamera( ro, ta, iTime, 0.0 );

    // camera matrix
    mat3 camMat = calcLookAtMatrix( ro, ta, 0.0 );  // 0.0 is the camera roll
    
	// create view ray
	vec3 rd = ( camMat * vec3(p.xy,2.0) ); // 2.0 is the lens length

    //-----------------------------------------------------
	// render
    //-----------------------------------------------------

	vec3 col = doBackground();

	// raymarch
    col = calc_intersection( ro, rd );
	   
    fragColor = vec4( sqrt(col), 1.0 );
}
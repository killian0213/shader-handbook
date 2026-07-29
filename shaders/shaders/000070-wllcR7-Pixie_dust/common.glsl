// Common (common) — Pixie dust by rory618
// https://www.shadertoy.com/view/wllcR7

#define R iResolution



const float dMin = 1e3;
const int sortedStage = 106;
const int BBoxStages = 70;
const int BVHStage0 = sortedStage+BBoxStages;
const int BBoxStage0 = BVHStage0+BBoxStages;
const int BBoxStageFinal = BBoxStage0 + BBoxStages - 3;

struct BBox {
    vec3 a;
    vec3 b;
};
    
    

bool inBBox(BBox bbox, vec3 p){
    return (p.x>bbox.a.x && p.y>bbox.a.y && p.z>bbox.a.z && 
            p.x<bbox.b.x && p.y<bbox.b.y && p.z<bbox.b.z);
}
vec2 rayBox(BBox bbox, vec3 p, vec3 rdir){
    if(inBBox(bbox,p)) return vec2(0.);
    vec3 tMin = (bbox.a - p) / rdir;
    vec3 tMax = (bbox.b - p) / rdir;
    vec3 t1 = min(tMin, tMax);
    vec3 t2 = max(tMin, tMax);
    float tNear = max(max(t1.x, t1.y), t1.z);
    float tFar = min(min(t2.x, t2.y), t2.z);
    if(tNear>tFar || tNear < 0.) return vec2(1e9); else return vec2(length(rdir*tNear),length(rdir*tFar));
}


//Treating aabb as a sphere is faster overall
bool PointIntersectsCone(vec3 P0, vec3 cone_o,vec3 cone_d,float cone_a){
    
    float g = abs(dot(normalize(cone_d), normalize(P0-cone_o)));
    return (acos(g)<cone_a);
    /*
    P0 -= cone_o;
    vec3 U = normalize(cone_d);
	float cone_cosAngle = cos(cone_a);
    
    // Test whether P0 or P1 is inside the cone.
    float g = dot(U, P0) - cone_cosAngle * length(P0);
    if (g > 0.)
    {
        // X0 = P0 + V is inside the cone.
        return true;
    }*/
}

bool LineIntersectsCone(vec3 P0, vec3 P1, vec3 cone_o,vec3 cone_d,float cone_a){
    // Define F(X) = Dot(U,X - V)/|X - V|, where U is the unit-length
    // cone axis direction and V is the cone vertex.  The incoming
    // points P0 and P1 are relative to V; that is, the original
    // points are X0 = P0 + V and X1 = P1 + V.  The segment <P0,P1>
    // and cone intersect when a segment point X is inside the cone;
    // that is, when F(X) > cosAngle.  The comparison is converted to
    // an equivalent one that does not involve divisions in order to
    // avoid a division by zero if a vertex or edge contain (0,0,0).
    // The function is G(X) = Dot(U,X-V) - cosAngle*Length(X-V).
    P0 -= cone_o;
    P1 -= cone_o;
    vec3 U = cone_d;
	float cone_cosAngle = cos(cone_a);

    // Test whether an interior segment point is inside the cone.
    vec3 E = P1 - P0;
    vec3 crossP0U = cross(P0, U);
    vec3 crossP0E = cross(P0, E);
    float dphi0 = dot(crossP0E, crossP0U);
    vec3 crossP1U = cross(P1, U);
    float dphi1 = dot(crossP0E, crossP1U);
    float t = dphi0 / (dphi0 - dphi1);
    vec3 PMax = P0 + t * E;
            float g = dot(U, PMax) - cone_cosAngle * length(PMax);

    return (dphi0 > 0.) && (dphi1 < 0.) && (g > 0.);
}

bool BBoxIntersectsCone(BBox b, vec3 cone_o,vec3 cone_d,float cone_a){
    
    vec3 mp = (b.a+b.b)/2.;
    float g = dot(normalize(cone_d), normalize(mp-cone_o));
    //if(g<0.) return false;
    float a = acos(g)-cone_a;
    if(a<0.) return true;
    return length(mp-cone_o)*sin(a)<length(mp-b.a);
    
    
    
    
    /*if(rayBox(b,cone_o,cone_d).x < 1e8){return true;}
    vec3 A = vec3(b.a.x,b.a.y,b.a.z);
    vec3 B = vec3(b.a.x,b.a.y,b.b.z);
    vec3 C = vec3(b.a.x,b.b.y,b.a.z);
    vec3 D = vec3(b.a.x,b.b.y,b.b.z);
    vec3 E = vec3(b.b.x,b.a.y,b.a.z);
    vec3 F = vec3(b.b.x,b.a.y,b.b.z);
    vec3 G = vec3(b.b.x,b.b.y,b.a.z);
    vec3 H = vec3(b.b.x,b.b.y,b.b.z);
    int k = 0;
    if(PointIntersectsCone(A,cone_o,cone_d,cone_a)) return true;
    if(PointIntersectsCone(B,cone_o,cone_d,cone_a)) return true;
    if(PointIntersectsCone(C,cone_o,cone_d,cone_a)) return true;
    if(PointIntersectsCone(D,cone_o,cone_d,cone_a)) return true;
    if(PointIntersectsCone(E,cone_o,cone_d,cone_a)) return true;
    if(PointIntersectsCone(F,cone_o,cone_d,cone_a)) return true;
    if(PointIntersectsCone(G,cone_o,cone_d,cone_a)) return true;
    if(PointIntersectsCone(H,cone_o,cone_d,cone_a)) return true;
    return false;
    if(LineIntersectsCone(A,B,cone_o,cone_d,cone_a)) return true;
    if(LineIntersectsCone(B,D,cone_o,cone_d,cone_a)) return true;
    if(LineIntersectsCone(D,C,cone_o,cone_d,cone_a)) return true;
    if(LineIntersectsCone(C,A,cone_o,cone_d,cone_a)) return true;
    if(LineIntersectsCone(E,F,cone_o,cone_d,cone_a)) return true;
    if(LineIntersectsCone(F,H,cone_o,cone_d,cone_a)) return true;
    if(LineIntersectsCone(H,G,cone_o,cone_d,cone_a)) return true;
    if(LineIntersectsCone(F,E,cone_o,cone_d,cone_a)) return true;
    if(LineIntersectsCone(A,E,cone_o,cone_d,cone_a)) return true;
    if(LineIntersectsCone(B,F,cone_o,cone_d,cone_a)) return true;
    if(LineIntersectsCone(C,G,cone_o,cone_d,cone_a)) return true;
    if(LineIntersectsCone(D,H,cone_o,cone_d,cone_a)) return true;
    return false;*/
}


BBox leafToBBox(vec4 data){
    vec3 point = data.xyz;
    return BBox(floor(point*1024.)/1024.,(floor(point*1024.)+1.)/1024.);
}

//Line segment sdf
float dLine(vec2 p, vec2 a, vec2 b){
    p-=a;
    b-=a;
    float l2 = dot(b,b);
    p -= b*clamp(dot(p,b/l2),0.,1.);
    return length(p);
}


//Magic to convert a binary number 0xbbbb into 0x00b00b00b00b
int spreadBits(int x){
    x = (x | (x << 16)) & 0x030000FF;
    x = (x | (x <<  8)) & 0x0300F00F;
    x = (x | (x <<  4)) & 0x030C30C3;
    x = (x | (x <<  2)) & 0x09249249;
    return x;
}

//Convert a 0-1 xy coordinate to a 20 bit morton/z order code
int ZOrder(vec3 coord){
    int x = int(coord.x*1024.);
    int y = int(coord.y*1024.);
    int z = int(coord.z*1024.);
    return spreadBits(x) | (spreadBits(y)<<1) | (spreadBits(z)<<2);
}
    
//Random number functions
int IHash(int a){
	a = (a ^ 61) ^ (a >> 16);
	a = a + (a << 3);
	a = a ^ (a >> 4);
	a = a * 0x27d4eb2d;
	a = a ^ (a >> 15);
	return a;
}
float Hash(int a){
	return float(IHash(a)) / float(0x7FFFFFFF);
}
vec4 rand4(int seed){
    return vec4(Hash(seed^0x34F85A93),
                Hash(seed^0x85FB93D5),
                Hash(seed^0x6253DF84),
                Hash(seed^0x25FC3625));
}
vec3 rand3(int seed){
    return vec3(Hash(seed^0x348CD593),
                Hash(seed^0x8593FD5),
                Hash(seed^0x62A5D384));
}
vec2 rand2(int seed){
    return vec2(Hash(seed^0x348C5F93),
                Hash(seed^0x8593D5BB));
}


vec2 randn(vec2 randuniform){
    vec2 r = randuniform;
    r.x = sqrt(-2.*log(1e-9+abs(r.x)));
    r.y *= 6.28318;
    r = r.x*vec2(cos(r.y),sin(r.y));
    return r;
}
   
//Cubemap utils to convert between a 1024 x 1024 x 6 buffer coordinate to a cubemap ray direction
vec3 XYFaceToRayDir(ivec3 p){
    vec2 x = vec2(p-512) + 0.5;
           if (p.z==0){     return vec3( 512,-x.y,-x.x);
    } else if (p.z==1){     return vec3( x.x, 512, x.y);
    } else if (p.z==2){     return vec3( x.x,-x.y, 512);
    } else if (p.z==3){     return vec3(-512,-x.y, x.x);
    } else if (p.z==4){     return vec3( x.x,-512,-x.y);
    } else if (p.z==5){     return vec3(-x.x,-x.y,-512);
    } else return vec3(0);
}
ivec3 RayDirToXYFace(vec3 dir){
    
    if        (dir.x>max(abs(dir.y),abs(dir.z))){
        dir /= dir.x/512.;
        return ivec3(-dir.z+512.0, -dir.y+512., 0);
    } else if (dir.y>max(abs(dir.z),abs(dir.x))){
        dir /= dir.y/512.;
        return ivec3(dir.x+512., dir.z+512.,1);
    } else if (dir.z>max(abs(dir.x),abs(dir.y))){
        dir /= dir.z/512.;
        return ivec3(dir.x+512.,-dir.y+512.,2);
    } else if (-dir.x>max(abs(dir.y),abs(dir.z))){
        dir /=-dir.x/512.;
        return ivec3(dir.z+512.,-dir.y+512.,3);
    } else if (-dir.y>max(abs(dir.z),abs(dir.x))){
        dir /=-dir.y/512.;
        return ivec3(dir.x+512.,-dir.z+512.,4);
    } else if (-dir.z>max(abs(dir.x),abs(dir.y))){
        dir /=-dir.z/512.;
        return ivec3(-dir.x+512.,-dir.y+512.,5);
    } else return ivec3(0,0,-1);
}

//Functions to sample a particle coordinate from the cubemap as a 1024 x 6144 buffer and a 16384 x 384 buffer
#define getters \
vec4 sampleXYTall(ivec2 XYTall){\
    ivec3 XYFace = ivec3(XYTall.x, XYTall.y%1024, XYTall.y/1024);\
	return texture(iChannel0, XYFaceToRayDir(XYFace));\
}\
vec4 sampleIndexStage(int index, int stage){\
    ivec2 XYTall = ivec2(index/16, index%16+stage*16);\
    return sampleXYTall(XYTall);
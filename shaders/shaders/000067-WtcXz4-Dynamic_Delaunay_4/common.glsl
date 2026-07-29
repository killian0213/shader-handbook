// Common (common) — Dynamic Delaunay 4 by rory618
// https://www.shadertoy.com/view/WtcXz4

#define R iResolution

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

float dot2(vec2 x){
    return dot(x,x);
}

int cvt(float x){
    return int(x);
    //return floatBitsToInt(x) ^ 0x8593D5BB ;
}

float cvt(int x){
    return float(x);
    //return intBitsToFloat(x ^ 0x8593D5BB);
}

vec2 circumscenter(vec2 ax, vec2 bx, vec2 cx, vec2 R){
    
    vec2 a = vec2(0.);
    vec2 b = bx - ax;
    vec2 c = cx - ax;
    //b = mod(b+R.xy/2.,R.xy)-R.xy/2.;
    //c = mod(c+R.xy/2.,R.xy)-R.xy/2.;
    
    vec3 X = vec3(a.x, b.x, c.x);
    vec3 Y = vec3(a.y, b.y, c.y);
    vec3 D = X*X+Y*Y;
    float sx = determinant( mat3(D,Y,vec3(1)))/2.;
    float sy = determinant( mat3(X,D,vec3(1)))/2.;
    
    return ax+vec2(sx,sy)/determinant( mat3(X,Y,vec3(1)));
}


//IQ sdTriangle 
float sdTriangle( in vec2 px, in vec2 p0x, in vec2 p1x, in vec2 p2x, in vec2 R )
{
    vec2 p = vec2(0);
    vec2 p0 = p0x - px;
    vec2 p1 = p1x - px;
    vec2 p2 = p2x - px;
    
    //p0 = mod(p0+R.xy/2.,R.xy)-R.xy/2.;
    //p1 = mod(p1+R.xy/2.,R.xy)-R.xy/2.;
    //p2 = mod(p2+R.xy/2.,R.xy)-R.xy/2.;
    if(p0==p1 || p1==p2 || p2==p0) return 1e9;
    
    vec2 e0 = p1-p0, e1 = p2-p1, e2 = p0-p2;
    vec2 v0 = p -p0, v1 = p -p1, v2 = p -p2;

    vec2 pq0 = v0 - e0*clamp( dot(v0,e0)/dot(e0,e0), 0.0, 1.0 );
    vec2 pq1 = v1 - e1*clamp( dot(v1,e1)/dot(e1,e1), 0.0, 1.0 );
    vec2 pq2 = v2 - e2*clamp( dot(v2,e2)/dot(e2,e2), 0.0, 1.0 );
    
    float s = sign( e0.x*e2.y - e0.y*e2.x );
    vec2 d = min(min(vec2(dot(pq0,pq0), s*(v0.x*e0.y-v0.y*e0.x)),
                     vec2(dot(pq1,pq1), s*(v1.x*e1.y-v1.y*e1.x))),
                     vec2(dot(pq2,pq2), s*(v2.x*e2.y-v2.y*e2.x)));

    return -sqrt(d.x)*sign(d.y);
}
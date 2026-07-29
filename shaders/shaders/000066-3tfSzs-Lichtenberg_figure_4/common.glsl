// Common (common) — Lichtenberg figure 4 by rory618
// https://www.shadertoy.com/view/3tfSzs

#define R iResolution
#define iR ivec3(R)
#define uR uvec3(R)
#define IHash3(x,y,z) IHash(int(x)^IHash(int(y)^IHash(int(z))))
#define dot2(o) dot((o),(o))
#define tx(ch,p,R) texelFetch(ch, Zmod(p,iR.xy),0)

//Roboust/universal integer modulus function
#define Zmod(x,y) (((x)+(y)+(y)+(y))-(((x)+(y)+(y)+(y))/(y))*(y))
//#define Zmod(x,y) ((x+y*10)%y)

int IHash(int a){
	a = (a ^ 61) ^ (a >> 16);
	a = a + (a << 3);
	a = a ^ (a >> 4);
	a = a * 0x27d4eb2d;
	a = a ^ (a >> 15);
	return a;
}

float Hash(int a){
	a = (a ^ 61) ^ (a >> 16);
	a = a + (a << 3);
	a = a ^ (a >> 4);
	a = a * 0x27d4eb2d;
	a = a ^ (a >> 15);
	return float(a) / float(0x7FFFFFFF);
}
vec4 rand4(int seed){
    return vec4(Hash(seed^0x348593),
                Hash(seed^0x8593D5),
                Hash(seed^0x625384),
                Hash(seed^0x253625));
}
vec3 rand3(int seed){
    return vec3(Hash(seed^0x348593),
                Hash(seed^0x8593D5),
                Hash(seed^0x625384));
}
vec2 rand2(int seed){
    return vec2(Hash(seed^0x348593),
                Hash(seed^0x8593D5));
}


vec2 randn(vec2 randuniform){
    vec2 r = randuniform;
    r.x = sqrt(-2.*log(1e-9+abs(r.x)));
    r.y *= 6.28318;
    r = r.x*vec2(cos(r.y),sin(r.y));
    return r;
}


struct particle {
    bool nil;
    vec2 coord;
    vec3 color;
};
    
vec2 packParticle(particle p){
    uvec2 px = uvec2(p.coord);
    uvec3 c = uvec3(p.color * 7000. + 1000.);
    uint n = uint(p.nil);
    uint x = px.x & 0x7FFu;
    uint y = px.y & 0x7FFu;
    uint r = c.r & 0x1FFFu;
    uint g = c.g & 0x1FFFu;
    uint b = c.b & 0x1FFFu;
    uint A = (b >> 9) | (g << 4) | (r << 17) | (n << 30);
    uint B = (y) | (x << 11) | ((b & 0x1FFu) << 22);
    return vec2(uintBitsToFloat(A),uintBitsToFloat(B));
}
particle unpackParticle(vec2 p){
    uint A = floatBitsToUint(p.x);
    uint B = floatBitsToUint(p.y);
    uint n = (A >> 30) & 0x1u;
    uint r = (A >> 17) & 0x1FFFu;
    uint g = (A >> 4) & 0x1FFFu;
    uint b = ((B >> 22) & 0x1FFu) | ((A & 0xFu) << 9);
    uint y = B & 0x7FFu;
    uint x = (B >> 11) & 0x7FFu;
    return particle(bool(n), vec2(x,y)+.5,(vec3(r,g,b)-1000.)/7000.);
}

#define mapping_iters 2
vec2 forward_mapping(vec2 Z,vec3 R, int seed){
    int p = int(R.x);
    int q = int(R.y);
    
    int x=int(Z.x);
    int y=int(Z.y);
    
    for(int i = 0; i < mapping_iters; i++){
        x = Zmod(x + IHash(y^seed)%p,p);
        y = Zmod(y + IHash(x^seed)%q,q);
    }
        
    return vec2(x,y)+.5;
    
}
vec2 reverse_mapping(vec2 Z,vec3 R, int seed){
    
    int p = int(R.x);
    int q = int(R.y);
    
    int x=int(Z.x);
    int y=int(Z.y);
    
    for(int i = 0; i < mapping_iters; i++){
        x = Zmod(x - IHash(y^seed)%p,p);
        y = Zmod(y - IHash(x^seed)%q,q);
    }
        
    return vec2(x,y)+.5;
}

float score(particle p, vec2 I, vec3 R, int seed){
    if(p.nil) return 1e6;
    
    vec2 Z = forward_mapping(p.coord, R, seed);
    
    vec2 D = Z-I;
    D = mod(D+R.xy/2.,R.xy)-R.xy/2.;
    return max(abs(D.x),abs(D.y));
    
}

//Update ranking, save a list of two particle xy indices. O.xy is better particle, O.zw is a different not as good one
void updateRank2x(particle n, inout vec4 O, inout float s0, inout float s1, vec2 I, vec3 R,int seed){
    float sn = score(n,I,R,seed);
    if(sn<s0){
        //Shift down the line
        s1=s0;
        O.zw=O.xy;
        s0=sn;
        O.xy=packParticle(n);
    } else if(sn<s1){
        //Bump off the bottom one
        s1=sn;
        O.zw=packParticle(n);
        
    }
}
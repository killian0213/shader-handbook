// Common (common) — Spatial Decorrelation by rory618
// https://www.shadertoy.com/view/WsfXzs

#define R iResolution
#define iR ivec3(R)
#define uR uvec3(R)
#define IHash3(x,y,z) IHash(int(x)^IHash(int(y)^IHash(int(z))))
#define dot2(o) dot((o),(o))
#define tx(ch,p,R) texelFetch(ch, Zmod(p,iR.xy),0)

//Roboust/universal integer modulus function
#define Zmod(x,y) (((x)+(y)+(y)+(y))-(((x)+(y)+(y)+(y))/(y))*(y))
//#define Zmod(x,y) ((x+y*10)%y)

float packVec2(vec2 x){
    return uintBitsToFloat(packSnorm2x16(x/10.));
}
vec2 umpackVec2(float x){
    return unpackSnorm2x16(floatBitsToUint(x))*10.;
}

bool inbounds(vec2 x, vec2 y){
    return (x.x>0.&&x.y>0.&&x.x<y.x&&x.y<y.y);
}

//RNG
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

//Random injective mapping from each pixel to a random new pixel
//By alternatively adding some randomness from y into x and then 
//x into y, a reversible hash function is made. To take the inverse,
//simply undo the last "add randomness to y" step by subtracting the
//same random value. You can calculate the random value that was used
//to modify y because it depends only on x.
//Reversible == one to one == injective
//input iFrame/2 to re randoize the mapping every frame
vec2 forward_mapping(vec2 Z,int p, int q, int Fover2){
    //int seed = 0;        // Optionaly keep seed constant for that static randomness look
	int seed = Fover2;
    if(!inbounds(Z,vec2(p,q))){return vec2(0);} //Dont map points from outside the boundry
    int x=int(Z.x);
    int y=int(Z.y);
    
    //Change iterations here to zero to use the identity function as a mapping
    //Some particles seem to have a better chance of getting drawn...
    //But it shows off the artifacts in all their glory, looks pretty cool after a reset
    for(int i = 0; i < 3; i++){
        x = Zmod(x + IHash(y^seed)%p,p);
        y = Zmod(y + IHash(x^seed)%q,q);
    }
    
	//This is the inverse mapping, only difference is - instead of + and the order of x and y
    //uncommenting should have the same effect as reducing iterations above to zero
    //This is a pretty good test of the one to one property of the mapping
    //Originally it seemed to not be working quite right on some platforms so
    //this can confirm if that is happening. The effect of a non injective mapping is collisions
    //And thus many particles getting lost near the final pass.
    /*
    for(int i = 0; i < 5; i++){
        y = Zmod(y - IHash(x)%q,q);
        x = Zmod(x - IHash(y)%p,p);
    }
	*/
    
    return vec2(x,y)+fract(Z);
    
}
vec2 reverse_mapping(vec2 Z,int p, int q, int Fover2){
    //int seed = 0;        // Optionaly keep seed constant for that static randomness look
	int seed = Fover2;
    if(!inbounds(Z,vec2(p,q))){return vec2(0);} //Dont map points from outside the boundry
    int x=int(Z.x);
    int y=int(Z.y);
    
    
    
    for(int i = 0; i < 3; i++){
        y = Zmod(y - IHash(x)%q,q);
        x = Zmod(x - IHash(y)%p,p);
    }
    
    return vec2(x,y)+fract(Z);
    
}

float score(vec2 p, vec2 I, vec3 R){
    if(!inbounds(p,R.xy)) return 1e6; //Bad score for points outside boundry
    //This should get revamped, there is no reasoning to use
    //euclidean distance, this metric probably should reflect the tree strtucture
    //Maybe even output a simple 1 or 0 if the index of this texel leads to the leaf
    //node that this particle p is going towards
    
    //Difference in the noise when using this other metric suggests that 
    //this is indeed screwing performance (likelyhood of missing particles)
    vec2 D = p-I;
    D = mod(D+R.xy/2.,R.xy)-R.xy/2.;
    return max(abs(D.x),abs(D.y));
    //use l infinity in toroidal space
    
    //return dot2(I-p);
}

void updateRank(vec4 t, inout vec4 O, inout float s, vec2 I, vec3 R){
    float sp = score(t.xy,I,R);
    if(sp<s){
        s=sp;
        O=t;
    }
}

//Update ranking, save a list of two particle xy indices. O.xy is better particle, O.zw is a different not as good one
void updateRank2x(vec2 t, inout vec4 O, inout float s0, inout float s1, vec2 I, vec3 R){
    float sp = score(t,I,R);
    if(sp<s0){
        //Shift down the line
        s1=s0;
        O.zw=O.xy;
        s0=sp;
        O.xy=t;
    } else if(sp<s1){
        //Bump off the bottom one
        s1=sp;
        O.zw=t;
        
    }
}
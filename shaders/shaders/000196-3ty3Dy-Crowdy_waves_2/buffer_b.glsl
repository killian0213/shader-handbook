// Buffer B (buffer) — Crowdy waves 2 by FabriceNeyret2
// https://www.shadertoy.com/view/3ty3Dy

// === Voronoï buffer: manage tracking of particles Ids

// --- insert (i,d) and maintain the 4 closest (i_,d_) 
void list_insert(inout vec4 i, inout vec4 d, float i_, float d_){	
    if(i_ == 0.) return;           // not a particle : exit
    if(any(equal(vec4(i_),i))) return; // already in top4 : exit
    if     (d_ < d[0])             // closer to closest: insert here
        i = vec4(i_,i.xyz),    d = vec4(d_,d.xyz);
    else if(d_ < d[1])             // closer to 2nd closest: insert here
        i = vec4(i.x,i_,i.yz), d = vec4(d.x,d_,d.yz);
    else if(d_ < d[2])             // closer to 3rd closest: insert here
        i = vec4(i.xy,i_,i.z), d = vec4(d.xy,d_,d.z);
    else if(d_ < d[3])             // closer to 4th closest: insert here
        i = vec4(i.xyz,i_),    d = vec4(d.xyz,d_);
}

void mainImage( out vec4 O, vec2 I )
{
    vec4  i = vec4(0),
         i0 = T1( I ),             // 4 closests particles here and around
         ia = T1( I + vec2( 1, 0) ),  // NB: could use an array.
         ib = T1( I + vec2( 0, 1) ),
         ic = T1( I + vec2(-1, 0) ),
         id = T1( I + vec2( 0,-1) );

//#define dist(i) length( A(i).xy - I )
//#define dist(i) length( mod( A(i).xy-I + R/2., R) - R/2. )  
vec2 D;
#define dist(i) ( D = mod( A(i).xy-I + R/2., R) - R/2., dot(D,D) )

    vec4  d = vec4(1e9); 
    for(int k = 0; k < 4; k++){    // sorts all these
        list_insert( i, d, i0[k], dist(i0[k]) );
        list_insert( i, d, ia[k], dist(ia[k]) );
        list_insert( i, d, ib[k], dist(ib[k]) );
        list_insert( i, d, ic[k], dist(ic[k]) );
        list_insert( i, d, id[k], dist(id[k]) );
    }
#if 0 // also checking diagonal (to test possibly axis bias)
    ia = T1( I + vec2( 1, 1) ),
    ib = T1( I + vec2(-1, 1) ),
    ic = T1( I + vec2( 1,-1) ),
    id = T1( I + vec2(-1,-1) );
    for(int k = 0; k < 4; k++){    // sorts all these
        list_insert( i, d, ia[k], dist(ia[k]) );
        list_insert( i, d, ib[k], dist(ib[k]) );
        list_insert( i, d, ic[k], dist(ic[k]) );
        list_insert( i, d, id[k], dist(id[k]) );
    }
#endif
    
    for(int k = 0; k < 1; k++){    // try to re-insert some random particle (possibly escaped from tracking)
      //int r = IHash( int(I.x) + int(I.y)*2048 + iFrame*2048*2048 +k*11131); //deterministic
        int r = IHash( int(I.x) + int(I.y)*2141 + iFrame*2141*2141 +k*11131); //without 2048 bias
      //int r = IHash( int(I.x) + int(I.y)*2048 + (int(iTime*2048.)+iFrame)*2048 +k*11131);
        int i_ =  1 + r % ( int(R.x*R.y)/int(N) ); // [ why /10? ]
        list_insert(i, d, float(i_), dist(i_) );
    }
    O = vec4(i);                   // stores 4 closest
    
}
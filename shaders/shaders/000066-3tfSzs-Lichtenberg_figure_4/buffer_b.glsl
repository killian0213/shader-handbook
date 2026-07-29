// Buffer B (buffer) — Lichtenberg figure 4 by rory618
// https://www.shadertoy.com/view/3tfSzs

void mainImage( out vec4 O, in vec2 I )
{
    //Split frames into 8 stages
    int stage = iFrame%8;
    int seed = iFrame/8;
    int size = int(.5+pow(2.45,float(7-stage)));
    
    
    float s0;
    float s1;
    //init with top left corner and center
    if(stage==0){
        vec2 u0 = tx(iChannel0, ivec2(I)-size,R).xy;
        vec2 u1 = tx(iChannel0, ivec2(I),R).xy;
        particle p0 = unpackParticle(u0);
        particle p1 = unpackParticle(u1);
                                                                         
        s0 = score(p0,I,R,seed);
        s1 = score(p1,I,R,seed);
        
        O.xy=u0;
        O.zw=u1;
        
        //Select the better one, make sure scores are in order with s0<s1
        if(s0>s1){
            vec2 _ = O.xy;
            O.xy = O.zw;
            O.zw = _;
            _.x = s0;
            s0 = s1;
            s1 = _.x;
        }
    } else {
        O = tx(iChannel1, ivec2(I)-size,R );
        particle p0 = unpackParticle(O.xy);
        particle p1 = unpackParticle(O.zw);
        s0 = score(p0,I,R,seed);
        s1 = score(p1,I,R,seed);
    }
    for(int i = 1; i < 9; i++){
        if(stage==0){
        	vec2 u = tx(iChannel0,ivec2(I)-size+size*ivec2(i/3,i%3),R).xy;
            particle p = unpackParticle(u);
            updateRank2x(p,O,s0,s1,I,R,seed);
            
        } else {
        	vec4 t;
            vec4 u = tx(iChannel1,ivec2(I)-size+size*ivec2(i/3,i%3),R); 
            particle p0 = unpackParticle(u.xy);
            particle p1 = unpackParticle(u.zw);
            updateRank2x(p0,O,s0,s1,I,R,seed);
            updateRank2x(p1,O,s0,s1,I,R,seed);
        }
        
    }
}
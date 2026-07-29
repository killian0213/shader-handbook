// Buffer C (buffer) — Spatial Decorrelation by rory618
// https://www.shadertoy.com/view/WsfXzs

//3x3 strided sort
//large to small
void mainImage( out vec4 O, in vec2 I )
{
    int stage = iFrame%2;
    
    int size = stage==0?243:9;
    //init with top left corner
    O = tx(iChannel0, ivec2(I)-size, R);
    float s0 = score(O.xy,I,R);
    float s1 = score(O.zw,I,R);
    for(int i = 1; i < 9; i++){
        vec4 t = tx(iChannel0,ivec2(I)-size+size*ivec2(i/3,i%3),R);
        updateRank2x(t.xy,O,s0,s1,I,R);
        updateRank2x(t.zw,O,s0,s1,I,R);
    }
}
// Buffer B (buffer) — Spatial Decorrelation by rory618
// https://www.shadertoy.com/view/WsfXzs

//Strided sort summarry:
//Each pass looks at 9 xy locations stored in the previous pass and selects the closest one
//The locations sampled are arranged in a 3x3 with the center located at I, and the spacing
//a power of 3
//Total 7 passes over two frames sized large to small
//A->B->C->D->B->C->D->Image
//Spacing 3^6 ..., 3^1, 3^0
//I think this gives an optimal data path from each pixel to each other pixel under the constraint of 7 passes

//In each buffer, the pixel to get drawn at index is saved in xy and the exact particle location is saved in zw.
//For more complex particles zw should instead be a pointer to the particle
//zw is unused for sorting, sort only based on xy


//large to small
void mainImage( out vec4 O, in vec2 I )
{
    //Split frames into two stages
    int stage = iFrame%2;
    
    int size = stage==0?729:27; //729=3^6
    float s0;
    float s1;
    //init with top left corner and center
    if(stage==0){
        vec2 t0 = tx(iChannel0, ivec2(I)-size,R).xy;
        vec2 t1 = tx(iChannel0, ivec2(I),R).xy;
                                                                         
        s0 = score(t0,I,R);
        s1 = score(t1,I,R);
        
        O.xy=t0==vec2(0)?vec2(0):forward_mapping(t0, iR.x, iR.y,iFrame/2);
        O.zw=t1==vec2(0)?vec2(0):forward_mapping(t1, iR.x, iR.y,iFrame/2);
        
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
        s0 = score(O.xy,I,R);
        s1 = score(O.zw,I,R);
    }
    for(int i = 1; i < 9; i++){
        if(stage==0){
        	vec2 t = tx(iChannel0,ivec2(I)-size+size*ivec2(i/3,i%3),R).xy;
            t = forward_mapping(t, iR.x, iR.y,iFrame/2);
            updateRank2x(t,O,s0,s1,I,R);
            
        } else {
        	vec4 t;
            t = tx(iChannel1,ivec2(I)-size+size*ivec2(i/3,i%3),R); 
            updateRank2x(t.xy,O,s0,s1,I,R);
            updateRank2x(t.zw,O,s0,s1,I,R);
        }
        
    }
}
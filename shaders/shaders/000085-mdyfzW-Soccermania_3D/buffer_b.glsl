// Buffer B (buffer) — Soccermania 3D by kastorp
// https://www.shadertoy.com/view/mdyfzW

//BUFFER B: 
// x= closest player for each position, y=distance
// z= closest player for the other team, w=distance

void mainImage( out vec4 O, in vec2 U )
{
    O = vec4(0,1e5,0,1e5);
    vec2 uv =  position(U);
    vec4 ball=  texelFetch(iChannel0,ivec2(0),0);
    
    for(int i=1;i<=22;i++)
    {
        vec2 p=  texelFetch(iChannel0,ivec2(i,0),0).xy;
        float  d_fin=  length(p-uv); //final position
        
        if(i<12 && d_fin<O.y)  O.xy =vec2(i,d_fin);              
        if(i>=12 && d_fin<O.w)O.zw=vec2(i,d_fin);              

    }
    for(int i=1;i<=22;i++)
    {
        vec2 p=  texelFetch(iChannel0,ivec2(i,0),0).xy;
        //TODO: implement ball marching instead of approximation
        float d_int=  sdSegment(p,ball.xy,uv)-min(.04,.01+length(ball.xy-p)*.3);//- length(ball.xy-p)*.1; //interception distance 
        if(i<12 && d_int<0. ) O.w=1e5;
        if(i>=12 && d_int<0.) O.y=1e5;

    }   
    if(O.w<O.y) O= O.zwxy;
    
    
    
}
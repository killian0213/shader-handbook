// Common (common) — Fluid physics by lomateron
// https://www.shadertoy.com/view/wdsGWS

#define ZOOM .25        //camera zoom, should be < .5
#define EMPTY 1024.     //there is no ball inside this pixel
#define FTOV .125 		//force to velocity
#define VTOP (FTOV*2.)  //velocity to position
#define FRC1 4.         //repulsion collision force
#define FRC2 1.         //inelastic collision force
//"Buf A" and "Buf B" represent the same thing
//These 2D textures can be pictured as an empty 2D space
//divided in grids
//a grid has side length 2
//a grid is represented by 4 pixels
//a grid can be filled with balls
// a ball has a radius 1
// a ball position is realive to the center of the local grid
//if ball position is outside the range 1 to -1
//it means ball has moved to the neighbour grid
// a ball only collides with local and neighbour grids balls
// a ball is represented by 1 pixel
// a pixel can be empty or ball preganant
//if pixel has ball "xy" = position, "zw" = velocity
//if pixel is empty xyzw = 1024
//rendering "Buf A" to "Buf B" calculates
//collision forces then convert to velocity then convert to position
//rendering "Buf B" to "Buf A" calculates
//which balls are moving to neighbour grids
//a ball souldnt have velocity > 1
//because that means its jumping 2 grids per frame
//which means it will not collide with some balls
//if somehow there are more than 4 balls in a grid
//those balls that dont fit will disapear forever
//doesnt matter because mouse click can create more balls
vec4 rand(vec2 u)
{
    return fract(sin(vec4(dot(u,vec2(23.123,87.987)),
                          dot(u,vec2(34.234,96.876)),
                          dot(u,vec2(45.345,15.765)),
                          dot(u,vec2(56.456,24.654))))*45678.7654);
}
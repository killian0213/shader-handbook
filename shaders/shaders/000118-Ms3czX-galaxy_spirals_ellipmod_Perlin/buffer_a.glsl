// Buffer A (buffer) — galaxy spirals: ellipmod +Perlin by FabriceNeyret2
// https://www.shadertoy.com/view/Ms3czX

// bits of "key group toggles": https://www.shadertoy.com/view/MlffW2

#define keypressed(ascii) ( texelFetch(iChannel3,ivec2(ascii,1),0).x > 0. )

void mainImage( out vec4 O, vec2 U )
{
    if ( iFrame == 0 ) { O = vec4(-1); return; } // initialized at -1
    
    if (U.y>1.) return;
    O = texelFetch(iChannel0,ivec2(U),0);   
    
 	int x = int(U.x);  
    if ( x == 0 ) {
        
        if ( O.x < 0. )     O.x = 3. ;             //    TEX default value
        if (keypressed(32)) O.x = mod(O.x+1.,4.);  // SPACE: 4 states

        if ( O.y < 0. )     O.y = 1. ;             //    MUL default value
        if (keypressed(77)) O.y = 1.-O.y;          //     T: 2 states
     }
               
 // FYI: LEFT:37  UP:38  RIGHT:39  DOWN:40   PAGEUP:33  PAGEDOWN:34  END : 35  HOME: 36 F1:112
}
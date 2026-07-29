// Buffer A (buffer) — Hyperbolic Square by mla
// https://www.shadertoy.com/view/Mlsfzs

// From "key group toggles" by @FabriceNeyret2:
// https://www.shadertoy.com/view/MlffW2

#define keypressed(ascii) ( texelFetch(iChannel3,ivec2(ascii,1),0).x > 0. )

void mainImage( out vec4 O, vec2 U )
{
#if __VERSION__ < 300
    O = vec4(0);
#else
    if ( iFrame == 0 ) { O = vec4(0); return; } // initialized at -1
    
    if (U.y>=1.0) return;
    O = texelFetch(iChannel0,ivec2(U),0); // Get current state   
    
 	int x = int(U.x);  
    if ( x == 0 ) {
        for (int i=1; i<=8; i++)             // (0,0).x = digits
            if (keypressed(48+i)) O.x = float(i);
        for (int i=1; i<=12; i++)            // (0,0).y = F1-F12
            if (keypressed(112+i-1)) O.y = float(i);
        
        if (keypressed(65)) O.z = 0.;        // (0,0).z = a,b,c
        if (keypressed(66)) O.z = 1.;    
        if (keypressed(67)) O.z = 2.;  
            
        if (keypressed(68)) O.w = 0.;        // (0,0).w = d,e,f
        if (keypressed(69)) O.w = 1.;    
        if (keypressed(70)) O.w = 2.;    
     }
            
    if ( x == 1 ) {
        if (keypressed(37)) O.x = 0.;        // (1,0).w = key left, up, right, down
        if (keypressed(38)) O.x = 1.;  
        if (keypressed(39)) O.x = 2.;  
        if (keypressed(40)) O.x = 3.;  
    }
    
 // FYI: LEFT:37  UP:38  RIGHT:39  DOWN:40   PAGEUP:33  PAGEDOWN:34  END : 35  HOME: 36 F1:112
#endif           
}

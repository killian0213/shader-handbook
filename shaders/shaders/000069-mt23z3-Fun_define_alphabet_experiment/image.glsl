// Image (image) — Fun #define alphabet experiment by kishimisu
// https://www.shadertoy.com/view/mt23z3

/* @kishimisu (2023) - https://www.shadertoy.com/view/mt23z3

   Just for fun, check the mainImage ^^
   The compile time can be excessive on some machines.
*/

// Choose color a theme (if you don't have many characters, prefer to use RAINBOW/GOLD)
#define THEME THEME_DEFAULT

// Available themes
#define THEME_MATRIX   vec4(.2,1,.4,1) * (cos(pp[1] + iTime)*.5 + 1.4)
#define THEME_DEFAULT  cos(pp[1] + iTime + tt[3] + tt*2.) + 1.5
#define THEME_GOLD     cos(pp[0]*.2 + tt*2.) + 1.3
#define THEME_RAINBOW  cos(pp[0]*.1 + iTime + tt[3] + tt*2.) + 1.4
#define THEME_PINK     vec4(1,.4,.8,1) * (cos(pp[1]*.8 + iTime + tt[3] + tt*2.) + 1.8)

// Font style (best values between 0.6 and 1.0)
#define FONT_STYLE (.9 + sin(iTime)*.2) // Font style is currently animated between the values 0.7-1.1
#define GLOW_INTENSITY 1.               // Intensity of the glow effect

void mainImage(out vec4 OO, vec2 FF) {
    vec4 tt = vec4(0, .5, FONT_STYLE, 2), ww;
    vec2 pp = (2.*FF-rr)/min(rr[1],rr[0]/1.6)*vec2(28,20)/ZOOM+OFFSET, 
         xz = tt.xz, zx = tt.zx, zz = tt.zz, iv = vec2(1,-1),
         yz = tt.yz, yx = tt.yx, zy = tt.zy, p0 = pp, qq; pp[0] += CW; OO *= 0.;
    
    // Use _ for spaces (automatic with uppercase letters)
         
    T h i s   T e x t   I s   W r i t t e n   I n s i d e
    
    T h e   M a i n i m a g e   U s i n g   D e f i n e s
        
    F o r   E v e r y   C h a r a c t e r   O f   T h e
    
    A l p h a b e t                                         _BRK_
    
    
    I t   F e a t u r e s   M a n u a l   A n d   
    
    A u t o m a t i c    R e t u r n s   T o   L i n e                          
    
    P l u s   C u s t o m   T h e m e s   _EXC_             _BRK_ 
                                                            _BRK_
                                                            
    K i s h i m i s u
;}
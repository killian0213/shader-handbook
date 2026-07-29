// Image (image) — Marble Marcher: SE by michael0884
// https://www.shadertoy.com/view/3lKyDR

//Marble Marcher Shadertoy Edition
//Version 0.9 BETA

//Ported by michael0884 (Mykhailo Moroz)

//Original Marble Marcher by CodeParade
//https://github.com/HackerPoet/MarbleMarcher

//Also check out Marble Marcher Community Edition!
//https://github.com/WAUthethird/Marble-Marcher-Community-Edition

//Notable features:
//Temporal antialiasing with disocclusion rejection, velocity vectors and neighbor clamping
//Lots of blue noise
//Ambient occlusion 
//PBR rendering
//Path tracing support, uncomment the define in Common
//Path tracer is also PBR with refraction support
//Physics in purely shader based

//Instructions
//WASD/Arrows and mouse to move marble. Q/E camera distance. 
//R - restart level
//SPACE - next level(only when you completed this one)
//Backspace - return to main menu
//F - go to free camera mode, in this mode Q/E regulate camera speed
//Change parameters in Common tab
//level transition buttons 
//P - next level
//O - previous level

//comment if the compiler wasn't able to optimize text rendering
#define RENDER_TEXT

#define STRINGS 8
#define TOTCHARS STRLENGTH*STRINGS

const uint[] TEXT_ARRAY = uint[](
  STRING(M,a,r,b,l,e,_,M,a,r,c,h,e,r,_,_,_,_,_,_,_,_,_,_),     //0
  STRING(S,h,a,d,e,r,t,o,y,_,E,d,i,t,i,o,n,_,_,_,_,_,_,_),     //1
  STRING(P,o,r,t,_,b,y,_,m,i,c,h,a,e,l,_0,_8,_8,_4,_,_,_,_,_), //2
  STRING(O,r,i,g,i,n,a,l,_,b,y,_,C,o,d,e,P,a,r,a,d,e,_,_),     //3
  
  STRING(P,r,e,s,s,_,S,p,a,c,e,_,t,o,_,C,o,n,t,i,n,u,e,_),     //4
  STRING(P,r,e,s,s,_,R,_,t,o,_,R,e,s,t,a,r,t,_,L,e,v,e,l),     //5
  
  STRING(P,l,a,y,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_),     //6
  STRING(L,e,v,e,l,s,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_),      //7
  
  STRING(B,a,c,k,_,t,o,_,M,a,i,n,_,M,e,n,u,_,_,_,_,_,_,_),
  STRING(J,u,m,p,_,t,h,e,_,c,r,a,t,e,r,_,_,_,_,_,_,_,_,_),
  STRING(T,o,o,_,m,a,n,y,_,t,r,e,e,s,_,_,_,_,_,_,_,_,_,_),
  STRING(H,o,l,e,_,i,n,_,o,n,e,_,_,_,_,_,_,_,_,_,_,_,_,_),
  STRING(B,e,w,a,r,e,_,o,f,_,b,u,m,p,s,_,_,_,_,_,_,_,_,_),
  STRING(M,o,u,n,t,a,i,n,_,c,l,i,m,b,i,n,g,_,_,_,_,_,_,_),
  STRING(M,i,n,d,_,t,h,e,_,g,a,p,_,_,_,_,_,_,_,_,_,_,_,_),
  STRING(T,h,e,_,s,p,o,n,g,e,_,_,_,_,_,_,_,_,_,_,_,_,_,_),
  STRING(B,u,i,l,d,_,u,p,_,s,p,e,e,d,_,_,_,_,_,_,_,_,_,_),
  STRING(A,r,o,u,n,d,_,t,h,e,_,c,i,t,a,d,e,l,_,_,_,_,_,_),
  STRING(T,o,p,_,o,f,_,t,h,e,_,c,i,t,a,d,e,l,_,_,_,_,_,_),
  STRING(M,e,g,a,_,C,i,t,a,d,e,l,_,_,_,_,_,_,_,_,_,_,_,_)
);

#define CONTOUR 1.1
#define CHAR_WIDTH 0.5

void draw_char(inout vec3 incol, vec2 p, vec3 tcol, vec2 pos, float size, uint char)
{        
  p.y = iResolution.y - p.y;
  p = (p - pos)/vec2(size*CHAR_WIDTH, size); 
  if(p.x < 0.0 || p.x > 1.0 || p.y < 0.0 || p.y > 1.0) return; 
  int code = int(char);
  
  p.x=(fract(p.x) - 0.5)*CHAR_WIDTH + 0.5; p.y=1.-p.y;                 
  p+=vec2(code%16,15-code/16);                          
  float sdf = (texture(iChannel3, p/16.).w - 0.5 + 1.0/256.0)*size;
  
  float blend = smoothstep(CONTOUR, 0.0, sdf);
  vec3 color = tcol*(2.*smoothstep(CONTOUR, -CONTOUR, sdf) - smoothstep(1.2*CONTOUR, 0.0, sdf));
  incol = mix(incol, color, blend);
}

void draw_string(inout vec3 incol, vec2 p, vec3 tcol, vec2 pos, float size, int string) 
{        
  vec2 p0 = p; p.y = iResolution.y - p.y;
  p = (p - pos)/vec2(size*CHAR_WIDTH, size);
  if(p.x < 0.0 || p.x > float(STRLENGTH) || p.y < 0.0 || p.y > 1.0) return;
  draw_char(incol, p0, tcol, pos + vec2(floor(p.x)*size*CHAR_WIDTH,0.), size, TEXT_ARRAY[int(p.x) + string*STRLENGTH]);   
}

void draw_string(inout vec3 incol, in vec2 p, in vec3 tcol, in vec2 pos, in float size, in uint[8] string) 
{        
  vec2 p0 = p; p.y = iResolution.y - p.y;
  p = (p - pos)/vec2(size*CHAR_WIDTH, size);
  if(p.x < 0.0 || p.x > float(8) || p.y < 0.0 || p.y > 1.0) return;
  
  //compiler doesn't want to optimize dynamic array indexing, idk why
  //a loop doesn't work either
  draw_char(incol, p0, tcol, pos + vec2(0.0*size*CHAR_WIDTH,0.), size, string[0]);
  draw_char(incol, p0, tcol, pos + vec2(1.0*size*CHAR_WIDTH,0.), size, string[1]);
  draw_char(incol, p0, tcol, pos + vec2(2.0*size*CHAR_WIDTH,0.), size, string[2]);
  draw_char(incol, p0, tcol, pos + vec2(3.0*size*CHAR_WIDTH,0.), size, string[3]);
  draw_char(incol, p0, tcol, pos + vec2(4.0*size*CHAR_WIDTH,0.), size, string[4]);
  draw_char(incol, p0, tcol, pos + vec2(5.0*size*CHAR_WIDTH,0.), size, string[5]);
  draw_char(incol, p0, tcol, pos + vec2(6.0*size*CHAR_WIDTH,0.), size, string[6]);
  draw_char(incol, p0, tcol, pos + vec2(7.0*size*CHAR_WIDTH,0.), size, string[7]);
}

void draw_menu(inout vec3 incol, vec2 p, vec2 pos, float sizescale, ivec2 range)
{
    for(int i = range.x; i<=range.y; i++)
    {
        vec2 dx = vec2(pos.x - p.x, iResolution.y - pos.y - p.y);
        vec2 size = sizescale*Buttons[i].size;
        incol *= 1.0 - 0.35*step(dx.y - size.x, 0.0)*step(0.0, dx.y)*step(0.0, dx.x + size.y)*step(dx.x, 0.0);
        draw_string(incol, p, vec3(1.), pos, size.x,  Buttons[i].string);
        pos.y +=1.2*size.x;
    }
}
  
#define SHARPEN 1.25
#define LOWSAMPLE_BLUR 1.
vec4 sample_adaptive(sampler2D ch, vec2 uv)
{
    vec3 dx = vec3(1.0/vec2(textureSize(ch, 0)),0.);
    
    vec4 c = texture(ch, uv);
    vec2 v = decode(texelFetch(iChannel0, ivec2(uv*iResolution.xy), 0).w);
    float k = mix(-LOWSAMPLE_BLUR, SHARPEN, smoothstep(0.15, 0.3, v.y*(1. - REPROJECTION)));
    
    vec4 u = texture(ch, uv + dx.zy);
    vec4 d = texture(ch, uv - dx.zy);
    vec4 r = texture(ch, uv + dx.xz);
    vec4 l = texture(ch, uv - dx.xz);
    return (1.+k)*c - 0.25*k*(u+d+r+l); 
}
  
void mainImage( out vec4 c, in vec2 p )
{
    load_scene(iChannel2, iTime, iResolution.xy);
    
    vec2 uv = p/iResolution.xy;
    c.xyz = sample_adaptive(iChannel0, p/iResolution.xy).xyz;
    c.xyz = clamp(c.xyz, 0., 1.0);
    
    #ifdef RENDER_TEXT
    float ms = timers.x*100.0/60.0;
    float se = mod(timers.x/60., 60.);
    float se0 = mod(-timers.x/60., 60.);
    float dse0 = mod(se0, 1.0);
    float mi = timers.x/3600.;
    uint[8] timer = uint[](NUM2CHAR(mi/10.0),NUM2CHAR(mi),C(co),NUM2CHAR(se/10.0),NUM2CHAR(se),C(co),NUM2CHAR(ms/10.0),NUM2CHAR(ms));   
    
    float font_size = FONT_SCALE;
    c.w = 1.0;
    switch(int(MODE/64.0))
    {
    case GAMEMODE_MENU: //MAIN MENU
        draw_string(c.xyz, p, vec3(1.), vec2(0.03, 0.03)*iResolution.xy, 62.0*font_size,  0);
        draw_string(c.xyz, p, vec3(1.), vec2(0.40, 0.15)*iResolution.xy, 35.0*font_size,  1);
        draw_string(c.xyz, p, vec3(1.), vec2(0.03, 0.85)*iResolution.xy, 27.0*font_size,  2);
        draw_string(c.xyz, p, vec3(1.), vec2(0.03, 0.91)*iResolution.xy, 27.0*font_size,  3);
        
        draw_menu(c.xyz, p, MAIN_POS, font_size,  ivec2(0,1));
        break;
    case GAMEMODE_LEVELS: //LEVELS MENU
        draw_menu(c.xyz, p, LEVELS_POS, font_size,  ivec2(2,13));
        break;
    case GAMEMODE_GAME: //TIMER
        if(timers.x>=0.)
        {
            draw_string(c.xyz, p, vec3(1.), vec2(0.39, 0.01)*iResolution.xy, 40.0*font_size,  timer);
        }
        else
        {
            draw_char(c.xyz, p, vec3(1.), vec2(0.47 - 0.008*dse0, 0.01)*iResolution.xy, (80.0 + 40.0*dse0)*font_size,  NUM2CHAR(se0+1.0));
        }
        return;    
    case GAMEMODE_FINISH: 
        draw_string(c.xyz, p,  vec3(0.000,0.702,1.000), vec2(0.39, 0.01)*iResolution.xy, 40.0*font_size,  timer);
        draw_string(c.xyz, p, vec3(1.), vec2(0.03, 0.85)*iResolution.xy, 27.0*font_size,  4);
        draw_string(c.xyz, p, vec3(1.), vec2(0.03, 0.91)*iResolution.xy, 27.0*font_size,  5);
        break;    
    }
    #endif
}
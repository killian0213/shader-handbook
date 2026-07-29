// Image (image) — Van Damme - Distance by Flyguy
// https://www.shadertoy.com/view/Wl3fWX

#define INPUT 0
#define STENCIL 1
#define OUTLINE 2
#define DISTANCE 3
#define NORMAL 4
#define NEON 5

#define VIEW_MODE DISTANCE

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    float ps = 1.0/iResolution.y;
    vec2 uv = fragCoord/iResolution.xy;
    
    vec3 col = vec3(0);
    
    #if(VIEW_MODE == INPUT)
        col = texture(iChannel1, uv, 0.0).aaa;
        
    #elif(VIEW_MODE == STENCIL)
        col = textureCubeFace(iChannel0, 0.0, uv).xxx;
        
    #elif(VIEW_MODE == OUTLINE)
        col = vec3(abs(textureCubeFace(iChannel0, 0.0, uv).x)/1e5);
        
    #elif(VIEW_MODE == DISTANCE)
        float dist = textureCubeFace(iChannel0, 5.0, uv).z;
        col = mix(vec3(0.3,0.5,1),vec3(1,0.7,0.3),step(0.,dist)); //Color based on sign (-/+)
        col *= 0.9+0.1*(-cos(dist*300.0)); //Isolines
        col *= smoothstep(ps,3.0*ps,abs(dist)); //Outline
        col *= 1.0/(1.0+abs(dist)*15.); //Fade out
        
    #elif(VIEW_MODE == NORMAL)
        col.xy = 0.5+0.5*textureCubeFace(iChannel0, 5.0, uv).xy;
        
     #elif(VIEW_MODE == NEON)
        float dist = textureCubeFace(iChannel0, 5.0, uv).z;
        col += vec3(0.1,0.1,1.0)/(abs(dist)*100.0);
        col += vec3(0.1,0.5,0.1)/(abs(dist-0.1)*100.0);
        col += vec3(0.5,0.1,0.1)/(abs(dist-0.2)*100.0);
        
    #endif
    
    fragColor = vec4(col, 1); 
}
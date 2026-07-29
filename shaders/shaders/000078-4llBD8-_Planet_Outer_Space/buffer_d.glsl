// Buf D (buffer) — [Planet] Outer Space by ingagard
// https://www.shadertoy.com/view/4llBD8

//////////////////////////////////////////////////////////////////////////////////////
// AA BUFFER -    REMOVES NOISE
//////////////////////////////////////////////////////////////////////////////////////


#define readRGB(memPos) (  texelFetch(iChannel2, memPos, 0).rgb)
//#pragma optimize(off) 

#define PERFORM_AA_PASS

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
      vec2 uv = fragCoord.xy / iResolution.xy;
  vec2 screenSpace = (-iResolution.xy + 2.0*(fragCoord))/iResolution.y;
  vec4 color = textureLod(iChannel0, uv,0.);

    
 #ifdef PERFORM_AA_PASS
    // Perform AA pass
    if( iFrame>0) 
    {
            // if the camera is kept steady, switch to fine AA pass.
            if(length(readRGB(ivec2(62, 0))-readRGB(ivec2(60, 0)))>0.)           
       {
            // better for moving cameras
            vec3 oldColor = textureLod(iChannel1, uv,1.0).rgb;
            color.rgb = mix(color.rgb,oldColor,0.2);
       }      
            else
            {
                  // good for static camera
             vec3 oldColor = texelFetch(iChannel1, ivec2(fragCoord-0.5), 0 ).rgb;
            color.rgb = mix( oldColor, color.rgb, 0.5 );
            }
    }   
  #endif
    
    fragColor = color;
}
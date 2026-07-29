// Image (image) — Abstract Truchet Inversion  by byt3_m3chanic
// https://www.shadertoy.com/view/7ljXWt

/**
    License: Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License
    
    Abstract Truchet Inversion 
    8/14/21 @byt3_m3chanic

    (mouseable)
    
    suggest music to play (since soundcloud isnt working in shader)
    https://soundcloud.com/relapserecords/07-survive-low-fog
*/
float offset[3] = float[]( 0.01, 1.75, 4.95 );
float weight[3] = float[]( 0.2, 0.35, 0.075 );

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{  
	vec2 uv = fragCoord.xy/iResolution.xy;

    vec3 C = texture(iChannel0, uv).rgb;
    vec3 R = texture(iChannel0, uv).rgb * weight[0];
    for (int i=1; i<3; i++) {
      R += texture(iChannel0, uv + vec2(offset[i])/iResolution.xy, 0.0).rgb * weight[i];
      R += texture(iChannel0, uv - vec2(offset[i])/iResolution.xy, 0.0).rgb * weight[i];
    }
    
    // mask for effect and mixdown 
    float dt = distance(uv.xy,vec2(.5))*.32;
    dt = smoothstep(0.82,.965,1.-dt);
    vec3 Color = mix(R,C,dt);
    
    // output
    Color=pow(Color, vec3(.4545));
    fragColor = vec4(Color,1.);

}
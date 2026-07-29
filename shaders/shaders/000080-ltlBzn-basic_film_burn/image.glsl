// Image (image) — basic film burn by johh
// https://www.shadertoy.com/view/ltlBzn

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
	vec2 uv = fragCoord.xy / iResolution.xy;
    float th = sin( iTime ) / 2. + .5;
    
    float tex = ((texture(iChannel0, uv ).r -.5) + 2. * uv.x ) / 3.;
    float mask = smoothstep( th - .1, th, tex);
    float dist = smoothstep( th - .3, th + .05, tex);
    float col = pow( smoothstep( th - .2, th + .15, tex), 3.);
    
    vec3 color = texture(iChannel1, uv * (.7 + pow(dist, 2.) * .3 )).rgb;
    vec3 discolor = color * vec3( 0.8, 0.4, 0.2 );
    
	fragColor = vec4( mix(discolor, color, col) * mask, 1.0);
}
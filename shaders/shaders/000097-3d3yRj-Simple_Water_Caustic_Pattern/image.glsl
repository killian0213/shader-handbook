// Image (image) — Simple Water Caustic Pattern by jaybird
// https://www.shadertoy.com/view/3d3yRj

// Adapted from https://www.shadertoy.com/view/Ws23RD

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
	vec2 p = (-iResolution.xy + 2.0*fragCoord) / iResolution.y;

    // camera matrix
    vec3 ww = normalize(-vec3(0., 1., 1.));
    vec3 uu = normalize(cross(ww, vec3(0., 1., 0.)));
    vec3 vv = normalize(cross(uu,ww));

	vec3 rd = p.x*uu + p.y*vv + 1.5*ww;	// view ray
    vec3 pos = -ww + rd*(ww.y/rd.y);	// raytrace plane
    pos.y = iTime*1.;					// animate noise slice
    pos *= 3.;							// tiling frequency

    //
    // caustic effect
    //
        
    vec4 n = snoise( pos );
        
    pos -= 0.07*n.xyz;
    n = snoise( pos );

    pos -= 0.07*n.xyz;
    n = snoise( pos );

    // noise [-1..+1] -> color
    float intensity = exp(n.w*3. - 1.5);
	fragColor = vec4(vec3(intensity), 1.);
}
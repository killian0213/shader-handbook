// Image (image) — More Spirograph by eiffie
// https://www.shadertoy.com/view/XlfGzX

//More Spirograph by eiffie
//Trying (and failing) to make a better DE for parameterized curves.

void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
	vec3 col=texture(iChannel0,fragCoord/iResolution.xy).rgb;
    fragColor=vec4(col,1.0);
}

// Image (image) — Distance field outline mask by Good
// https://www.shadertoy.com/view/XtG3Rt

void mainImage( out vec4 o, in vec2 p ){
    o = texture(iChannel0,p.xy/iResolution.xy); 
}
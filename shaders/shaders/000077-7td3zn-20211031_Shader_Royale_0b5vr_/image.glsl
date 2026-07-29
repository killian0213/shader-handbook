// Image (image) — 20211031_Shader Royale (0b5vr) by 0b5vr
// https://www.shadertoy.com/view/7td3zn

void mainImage( out vec4 fragColor, in vec2 fragCoord ){
  fragColor = texture(iChannel0,fragCoord/iResolution.xy);
}
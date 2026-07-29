// Image (image) — [SH17A] 2tweet fluid 2 by flockaroo
// https://www.shadertoy.com/view/4dBfDW

// derived from https://www.shadertoy.com/view/4sSBRm
// with the help of fabrice and 834144373 down to 278 total
// ...v,p,q uninitialized though
// but the fract could be left away in image tab and initialization commented in bufA

void mainImage(out vec4 c, vec2 f){c=fract(texelFetch(iChannel0,ivec2(f),0));}
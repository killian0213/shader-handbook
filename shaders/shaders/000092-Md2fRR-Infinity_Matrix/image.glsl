// Image (image) — Infinity Matrix by KilledByAPixel
// https://www.shadertoy.com/view/Md2fRR

//////////////////////////////////////////////////////////////////////////////////
// Infinity Matrix - Copyright 2017 Frank Force
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
//////////////////////////////////////////////////////////////////////////////////

const float blurSize = 1.0/512.0;
const float blurIntensity = 0.2;

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
   vec2 uv = fragCoord.xy/iResolution.xy;
   vec4 sum = vec4(0);
   sum += texture(iChannel0, vec2(uv.x - blurSize, uv.y)) * 0.5;
   sum += texture(iChannel0, vec2(uv.x + blurSize, uv.y)) * 0.5;
   sum += texture(iChannel0, vec2(uv.x, uv.y - blurSize)) * 0.5;
   sum += texture(iChannel0, vec2(uv.x, uv.y + blurSize)) * 0.5;
   sum += texture(iChannel0, vec2(uv.x - blurSize, uv.y - blurSize)) * 0.3;
   sum += texture(iChannel0, vec2(uv.x + blurSize, uv.y - blurSize)) * 0.3;
   sum += texture(iChannel0, vec2(uv.x - blurSize, uv.y + blurSize)) * 0.3;
   sum += texture(iChannel0, vec2(uv.x + blurSize, uv.y + blurSize)) * 0.3;    

   fragColor = blurIntensity*sum + texture(iChannel0, uv);
}
// Image (image) — TV Scene, wall of TV by morimea
// https://www.shadertoy.com/view/4fffR7


// Created by Danil (2024+) https://github.com/danilw
// https://mastodon.gamedev.place/@danil

// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

// self https://www.shadertoy.com/view/4fffR7


// using:
// https://iquilezles.org/articles/intersectors/
// https://www.shadertoy.com/view/NlycW1 - RayTracing Domain Repetition
// https://www.shadertoy.com/view/cd3XWr - Agx


// for TAA asd everything else look
// https://danilw.github.io/blog/my_shader_templates_list/


// Control:
// keyboard arrows to change move direction
// mouse on borders - same
// mouse on middle - zoom
// (hidden feature - after zoom click with mouse on border direction - zoom stay)
// space - stop movement


vec3 color2agx(vec3 col);
void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord/iResolution.xy;

    vec3 col = vec3(0.0);
    float sharpness = 0.001+0.099*smoothstep(0.5,1.5,iTime);
    for (int dy = -1; dy <= 1; ++dy)
    {
        for (int dx = -1; dx <= 1; ++dx)
        {
            float weight = (dx == 0 && dy == 0)? (1.0 + 8.0*sharpness): -sharpness;
            col += weight * texelFetch(iChannel3, ivec2(fragCoord)+ivec2(dx,dy), 0).rgb;        }
    }
    
    col = max(col, vec3(0.));
    col=col*col*.5+col;
    col = color2agx(col);
    
    uv = fragCoord.xy/iResolution.xy - 0.5;
    float vignetteAmt = 1. - dot(uv * .85, uv * .85);
    col *= vec3(vignetteAmt);

    col = clamp(col, 0., 1.);
    
    fragColor = vec4(col,1.0);
    
}







// Agx from https://www.shadertoy.com/view/cd3XWr
#define AGX_LOOK 2

// AgX
// ->

// Mean error^2: 3.6705141e-06
vec3 agxDefaultContrastApprox(vec3 x) {
  vec3 x2 = x * x;
  vec3 x4 = x2 * x2;
  
  return + 15.5     * x4 * x2
         - 40.14    * x4 * x
         + 31.96    * x4
         - 6.868    * x2 * x
         + 0.4298   * x2
         + 0.1191   * x
         - 0.00232;
}

vec3 agx(vec3 val) {
  const mat3 agx_mat = mat3(
    0.842479062253094, 0.0423282422610123, 0.0423756549057051,
    0.0784335999999992,  0.878468636469772,  0.0784336,
    0.0792237451477643, 0.0791661274605434, 0.879142973793104);
    
  const float min_ev = -12.47393f;
  const float max_ev = 4.026069f;

  // Input transform
  val = agx_mat * val;
  
  // Log2 space encoding
  val = clamp(log2(val), min_ev, max_ev);
  val = (val - min_ev) / (max_ev - min_ev);
  
  // Apply sigmoid function approximation
  val = agxDefaultContrastApprox(val);

  return val;
}

vec3 agxEotf(vec3 val) {
  const mat3 agx_mat_inv = mat3(
    1.19687900512017, -0.0528968517574562, -0.0529716355144438,
    -0.0980208811401368, 1.15190312990417, -0.0980434501171241,
    -0.0990297440797205, -0.0989611768448433, 1.15107367264116);
    
  // Undo input transform
  val = agx_mat_inv * val;
  
  // sRGB IEC 61966-2-1 2.2 Exponent Reference EOTF Display
  //val = pow(val, vec3(2.2));

  return val;
}

vec3 agxLook(vec3 val) {
  const vec3 lw = vec3(0.2126, 0.7152, 0.0722);
  float luma = dot(val, lw);
  
  // Default
  vec3 offset = vec3(0.0);
  vec3 slope = vec3(1.0);
  vec3 power = vec3(1.0);
  float sat = 1.0;
 
#if AGX_LOOK == 1
  // Golden
  slope = vec3(1.0, 0.9, 0.5);
  power = vec3(0.8);
  sat = 0.8;
#elif AGX_LOOK == 2
  // Punchy
  slope = vec3(1.0);
  power = vec3(1.35, 1.35, 1.35);
  sat = 1.4;
#endif
  
  // ASC CDL
  val = pow(val * slope + offset, power);
  return luma + sat * (val - luma);
}

// <-

vec4 toLinear(vec4 sRGB) {
  bvec4 cutoff = lessThan(sRGB, vec4(0.04045));
  vec4 higher = pow((sRGB + vec4(0.055))/vec4(1.055), vec4(2.4));
  vec4 lower = sRGB/vec4(12.92);
  
  return mix(higher, lower, cutoff);
}

vec3 color2agx(vec3 col)
{
  //col = toLinear(vec4(col, 1.0)).rgb;

  col = agx(col);
  col = agxLook(col);
  col = agxEotf(col);

  return col;
}











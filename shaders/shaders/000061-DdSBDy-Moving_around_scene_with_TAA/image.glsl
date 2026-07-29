// Image (image) — Moving around scene with TAA by morimea
// https://www.shadertoy.com/view/DdSBDy


// Created by Danil (2023+) https://github.com/danilw
// License - License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

// self https://www.shadertoy.com/view/DdSBDy


// For Quality:
// increase number of rays in Common 

// Control:
// WASD or arrows to move, mouse click to rotate camera
// move_SUN_circle_inf in Common to keep Sun in same position when move_rounds

// Camera collision - remove #define move_rounds in Common, or Collision_floor line 78 in BufA
// Clouds rendered in BufD - this why on camera rotate clouds with delay movement.
// Other options in Common.

// using:
// TAA from https://www.shadertoy.com/view/DsfGWX
// RayTracing Radial Repetition https://www.shadertoy.com/view/stKcWD
// clouds from https://www.shadertoy.com/view/DtBGR1
// Agx from https://www.shadertoy.com/view/cd3XWr

// this pathtracer template https://www.shadertoy.com/view/dldGWj



// remember to set mipmaps to iChannel3 in Image to use bloom
#define use_bloom
#ifdef use_bloom
mat3 gaussianFilter = mat3(41, 26, 7,
                           26, 16, 4,
                           7,  4,  1) / 273.;
// bloom
vec3 bloom(float scale, float threshold, vec2 fragCoord, sampler2D ich){
    // this does not alway work
    // Shadertoy allocate mipmap once and forever - no way to know if they exit actually
    // maybe this is another webbrower WebGL implementation feature/bug idk
    if(textureSize(ich,1).x<10) return vec3(0.);
    float logScale = log2(scale);
    vec3 bloom = vec3(0);
    for(int y = -2; y <= 2; y++)
        for(int x = -2; x <= 2; x++)
            bloom += gaussianFilter[abs(x)][abs(y)] * textureLod(ich, (fragCoord+vec2(x, y)*scale)/iResolution.xy, logScale).rgb;
    return max(bloom - vec3(threshold), vec3(0.));
}
#endif

#ifdef use_dynamic_TAA
#ifdef enable_volume
// from https://www.shadertoy.com/view/Xltfzj
vec4 GaussianBlur(in vec2 fragCoord, sampler2D ich)
{
    float Directions = 6.0;
    float Quality = 3.0;
    float Size = 3.0;
    vec2 Radius = Size/iResolution.xy;
    vec2 uv = fragCoord/iResolution.xy;
    vec4 Color = texture(ich, uv);
    for( int i=0; i<int(Directions); i++)
    {
        float d=float(i)*TAU/Directions;
		for(int j=0; j<int(Quality); j++)
        {
            float ti=1.0/Quality+float(j)*1.0/Quality;
			Color += textureLod( ich, uv+vec2(cos(d),sin(d))*Radius*ti, 0.);	
        }
    }
    Color /= Quality * Directions+1.;
    return Color;
}
#endif
#endif

// volume raymarch mix color
//----------------------------------------------
#ifdef enable_volume

vec3 raymarchVolume_image(vec3 backGround, float absorb, vec3 sunColor, float lDotV, float fogLitPercent){
    
    float phaseMie = hGPhase(lDotV, 0.8);
    
    vec3 c_fogColorLit = backGround+sunColor * phaseMie*0.5+0.0025*(0.5+sunColor*0.5);
    const vec3 c_fogColorUnlit = vec3(0.);
    
    vec3 fogColor = mix(c_fogColorUnlit, c_fogColorLit, fogLitPercent*fogLitPercent*fogLitPercent);
    return mix(fogColor, backGround, absorb);
}
#endif
//----------------------------------------------
vec3 color2agx(vec3 col);
vec4 toLinear(vec4 sRGB);
vec3 srgb_encode(vec3 v);

void mainImage(out vec4 fragColor, in vec2 fragCoord) {

#ifdef move_rounds
    float l_t = load(LOCAL_T,iChannel0);
    rtimer = l_t;
    float l_t_last = load(LOCAL_T_last,iChannel0);
    rtimer_last = l_t_last;
#ifdef move_SUN_circle_inf
    lightDir.xz=lightDir.xz*MD(-rtimer*rspd);
#endif
#endif
    vec2 fc = fragCoord.xy;
    vec3 texture_color = vec3(1.);
#ifdef use_dynamic_TAA
    vec3 color = texelFetch(iChannel3, ivec2(fc), 0).rgb;
#else
    vec3 color = texelFetch(iChannel2, ivec2(fc), 0).rgb;
#ifdef enable_textures
    texture_color = unpack_Unormfloat3x10(texelFetch(iChannel2, ivec2(fc), 0).a);
#endif
#endif
    
#ifndef enable_textures
#ifdef enable_volume
    
    // unjittering volume fog
    vec2 halton_px_shift = vec2(load(HALTON0,iChannel0),load(HALTON1,iChannel0));
    if(load(INPUT0,iChannel0)<1.) halton_px_shift =vec2(0.);

#ifdef use_dynamic_TAA
#ifdef add_clouds
    float absorb = GaussianBlur(fc-halton_px_shift, iChannel2).a;
#else
    //float absorb = texelFetch(iChannel3, ivec2(fc), 0).a;
    float absorb = GaussianBlur(fc, iChannel3).a; //additional Blur on top of TAA
#endif
    float fogLitPercent = GaussianBlur(fc-halton_px_shift, iChannel1).a;
#else
    float absorb = textureLod(iChannel2, vec2(fc-halton_px_shift)/iResolution.xy, 0.).a;
    float fogLitPercent = textureLod(iChannel1, vec2(fc-halton_px_shift)/iResolution.xy, 0.).a;
#endif

    vec2 uv = (fragCoord)/iResolution.xy * 2.0 - 1.0;
    uv.y *= iResolution.y/iResolution.x;
    vec3 ro;
    vec3 rd;
    SetCamera(uv, iChannel0, ro, rd, iResolution.xy);

    vec3 sunColor = calculateSunColor(lightDir.y);
    float lDotV = dot(rd, lightDir);
    color = raymarchVolume_image(color, absorb, sunColor, lDotV, fogLitPercent);
#endif
#endif
    vec3 blom = vec3(0.);
#ifdef use_bloom
#ifdef use_dynamic_TAA
    blom += bloom(.015 * iResolution.y, 0.002,fragCoord,iChannel3)*0.05;
    blom += bloom(.05 * iResolution.y, 0.002,fragCoord,iChannel3)*0.025;
#else
    //blom += bloom(.015 * iResolution.y, 0.002,fragCoord,iChannel2)*0.05;
    //blom += bloom(.05 * iResolution.y, 0.002,fragCoord,iChannel2)*0.025;
#endif
#endif
    
    //color = ACESFilm(color*texture_color+blom);
    //color = srgb_encode(color);
    
    //color = toLinear(vec4(color, 1.0)).rgb;
    color = color2agx(color*texture_color+blom);
    
	fragColor = vec4(color, 1.0 );
   
}

vec3 srgb_encode(vec3 v) {
  return mix(12.92*v,1.055*pow(v,vec3(.41666))-.055,step(.0031308,v));
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








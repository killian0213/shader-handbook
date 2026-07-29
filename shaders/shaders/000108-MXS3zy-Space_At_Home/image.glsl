// Image (image) — Space At Home by lz
// https://www.shadertoy.com/view/MXS3zy

/*
    Space at home. 
    Copyright © 2024 Leonid Zaides
    Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the “Software”), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
    The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
    THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
    
    //--------------------------------------------------------//
       Notes:
       
       Modeling my 'workspace' at home. Used real measurements for the items in inches (because started with the laptop).
       
       Tested on the following machines:
            Windows with RTX 2060 (mobile). (Full HD 30 - 60 fps)
            Windows with Intel Iris (mobile). (Full HD 15 - 35 fps)
            MacBook Pro M2 (Arm). (3840x2160 10 - 25 fps)
            
        The deferred rendering style is mostly to save compilation time on windows chrome
        which at one time peaked to 25s (without even having all the features). On windows 
        Firefox the compilation time is usually better (about half the time on chrome).
        So I have been rebalancing the workload (compilation time) between the buffers.
        
        One of the consequnces of this was repacking [0 - 1] interval into 8 bit values
        and passing several such values in one channel (see Buffer C). 
        
        Used Cook-Torrance PBR model for lighting (at least for the main part). The N component produces some artifacts
        on edges. A proper solution would probably be filtering (not made the cut)
        
        Heavily optimized for performance:
        - All non-floor items used bounding volumes (not bounding boxes) on trace.
        - Used shadow (and ao) mapping to trace only objects that can cast shadow on a specific object
        - Used maps for normals to calculate the normal only on the hit subpart.
        - When using patterns, calculated distance to nearest cell boundary to avoid
          4 calculations of neighbors. 
        - Floor was calculated analytically (and then it could be filtered analytically as well) and
          it improved performance of the whole trace.
        - Shadows were downsampled and calculated on 1/2 of the resolution and upsampled on image integration.
          The rays were cone-traced and the final result was later smoothed to alleviate artifatcs.
    //--------------------------------------------------------//
*/

const float MAX_KRN_SIZE = 1.;

////
vec3 laplace(in float _dist, in vec3 _val, 
    in sampler2D _ch, in vec2 _uv, in vec2 _eps)
{
  float krnSize = floor(smoothstep(0.35, 1., _dist) * MAX_KRN_SIZE);
  vec3 scol;
  float sw = 0.;
  float w = 0.;
  for (int i = -int(krnSize); i <= int(krnSize); i++)
  {
      for (int j = -int(krnSize); j <= int(krnSize); j++)
      {
         vec3 ncol = texture(_ch, _uv + _eps * vec2(i, j)).rgb;
         w = 1.;
         sw += w;
         scol += w * ncol;
      }
  }
  
  scol /= sw;
  
  vec3 res = mix(_val, scol, krnSize/MAX_KRN_SIZE);

  return scol;
}

////
vec3 laplace_packed(in float _dist, in vec3 _val, 
    in sampler2D _ch, in ivec2 _crd)
{
  float krnSize = floor(smoothstep(0.35, 1., _dist) * MAX_KRN_SIZE);
  vec3 scol;
  float sw = 0.;
  float w = 0.;
  for (int i = -int(krnSize); i <= int(krnSize); i++)
  {
      for (int j = -int(krnSize); j <= int(krnSize); j++)
      {
         float nv = TF(_ch, _crd + ivec2(i, j)).r;
         UNPACK_UINT_TO_CUI3(nv)
         w = 1.;
         sw += w;
         scol += w * unpacked_cui3;
      }
  }
  
  scol /= sw;
  
  vec3 res = mix(_val, scol, krnSize/MAX_KRN_SIZE);

  return scol;
}

vec2 toUV(in vec4 _plane, in vec2 _p, in vec2 _reverse, in vec4 _txcrd)
{
    vec2 tx = ((_p - _plane.xy) / _plane.zw); // 0 - 1 range
    tx = mix(tx, vec2(1.) - tx, _reverse); // reverse axes if needed
    return _txcrd.xy + tx * _txcrd.zw; // convert to texture coordinates
}

// https://iquilezles.org/articles/normalsSDF/
vec3 calcNormal( in vec3 pos, in int _trace_flag, in float _eps ) // for function f(p)
{
    float h = _eps;
    #define ZERO (min(iFrame,0)) // non-constant zero
    vec3 n = vec3(0.0);
    for( int i=ZERO; i<4; i++ )
    {
        vec3 e = 0.5773*(2.0*vec3((((i+3)>>1)&1),((i>>1)&1),(i&1))-1.0);
        n += e*map(pos+e*h, _trace_flag, iChannel3, true, false).x;
    }
    return normalize(n);
}

vec4 triplanar(in vec3 p, in vec3 scale, in vec3 _w)
{  
  vec4 dx = texture(iChannel2, p.yz*scale.yz);
  vec4 dy = texture(iChannel2, p.zx*scale.zx);
  vec4 dz = texture(iChannel2, p.xy*scale.xy);
  
  return dx * _w.x + dy *_w.y + dz * _w.z;
}

vec3 render_floor(in vec3 _p, in float _t, inout vec3 _n) {
    vec2 st = _p.zx;
    float mx = 0.4;
    float dp = smoothstep(0., 1., length(fwidth(_p)));
    float mscl = 0.1 - 0.1 * dp;
    st.x *= mx;
    float my = 0.03 + 0.05 * hash(floor(st.x) + 28.2);
    st.y *= my;
    st.y += hash(floor(st.x));
    vec2 fst = fract(st);
    vec2 vst = smoothstep(vec2(0.), mscl * vec2(mx, my), fst) - smoothstep(vec2(1.) - vec2(mx, my)*mscl, vec2(1.), fst);

    // bump map the floor.
    vec3 dx = vec3(0., 2.*dFdx(vst.x), 1.);
    vec3 dy = vec3(1., 2.*dFdy(vst.y), 0.);
    vec3 n = normalize(cross(dx, dy));
    _n = mix(n, _n, dp);
    
    vec3 clr = (vec3(1., 1., 0.8) - vec3(0.12, 0.12, 0.05)*hash(floor(st)));
    clr = mix(0.5*clr, clr, vst.x * vst.y);
    clr = mix(clr, texture(iChannel2, fract(st*0.1)).rgb, 0.5);
    
    // fade out
    float rst = length(_p.xz);
    float ast = mod(PI + atan(_p.z, _p.x), PI2);
    clr = mix(clr, 0.0 * clr, smoothstep(130., 160., rst));
            
    return clr;
}

vec3 render_laptop(in vec3 _p, in vec3 _n, in vec3 _d, in float _tdist,
    in int _mtl, in float _scrRatio, out vec4 _mtlParams)
{
    vec4 dims = TF3(LAPTOP_H_DIMS);
    const float lpWidth = 0.5;
    const float lpRatio = 0.6965386; // This is laptop ratio
    float lpHeight = lpRatio * lpWidth * _scrRatio;
    
    vec3 frame = vec3(0.55);
    vec3 ldir = normalize(vec3(_d));
    
    // roughness, metalness, emmissive
    _mtlParams = vec4(0.15, 1., 0., 0.);
    
    vec3 col = frame;
    lpTrf = mat4(TF3(LAPTOP_BASE_TRF_0), TF3(LAPTOP_BASE_TRF_1), 
                 TF3(LAPTOP_BASE_TRF_2), TF3(LAPTOP_BASE_TRF_3));
                 
    scrTrf = mat4(TF3(LAPTOP_SCRN_TRF_0), TF3(LAPTOP_SCRN_TRF_1),
                  TF3(LAPTOP_SCRN_TRF_2), TF3(LAPTOP_SCRN_TRF_3));
                  
    vec4 on = (lpTrf * vec4(_n, 0.));
    vec3 op = (lpTrf * vec4(_p, 1.)).xyz;

    if (_mtl == LAPTOP_MTL && on.y > 0.99) // keyboard and trackpad
    {
      col = vec3(1., 0., 0.) * dot(-ldir, _n);
      vec2 tx = toUV(vec4(-dims.xz, 2.*dims.xz), op.xz, vec2(1., 1.), vec4(0.001, 1.-lpHeight, lpWidth - 0.001, lpHeight));
      
      vec2 tuv = toUV(vec4(-dims.xz, 2.*dims.xz), op.xz, vec2(1., 1.), vec4(0., 0., 1., 1.));
       
      // speaker section
      float speakers = float(inBox(abs(vec2(0.5, 0.) - tuv), vec4(0.38, 0.462, 0.115, 0.436)));
      tuv.x *= dims.x/dims.z;
      float dtuv = length(fwidth(tuv));
      vec2 grid = tuv * (iResolution.y) * 0.075;
      float f_speakers = smoothstep(0.05, 0.18, length(fract(grid) - vec2(0.5)));
      
      f_speakers = mix(f_speakers, 0.9, smoothstep(0.001, 0.005, dtuv));
      
      vec4 clr = texture(iChannel3, tx);
      
      vec3 tn = (transpose(lpTrf) * vec4(normalize(vec3(clr.y, 0.0001, clr.z)), 0.)).xyz;
      // sin phi angle
      float sin_phi = (abs(_d.y)/length(_d));
      float f_phi_dir = smoothstep(0., 1., 1. - abs(sin_phi - 0.5));
      float f_btn_border = smoothstep(0., 0.01,length(clr.yz));
      // button light
      float f_button = step(1., clr.w);
      float lf = max(1.,4.*noise(clr.w*sin_phi*0.5 + 30.)*f_phi_dir*f_button);
      // trackpad and button light
      float lf_key_press = float(int(clr.w) == int(TF3(LAPTOP_KEY_ANIM).r));
      
      // color - pressed button highlight color
      col = clr.rrr - (1. - f_btn_border)*0.2*lf_key_press;
      //col += clr.rrr * (f_button);
      col += 0.25*max(dot(tn, _d), 0.)*step(0.5, clr.w)*lf*(1.-lf_key_press*f_btn_border);
      col = mix(col, col * f_speakers, speakers);
      
      float button_light = mix(0., 0.1, 1.-smoothstep(0., 50., _tdist));
      _mtlParams = vec4(0.1*f_button, (1.-f_button), button_light * f_btn_border * f_button, 0.);
      col = mix(col, 0.25*col, smoothstep(0., 0.05, dtuv) * f_button);
    }
    else if (_mtl == (LAPTOP_SCREEN_MTL) && (scrTrf * on).y < -0.9) // screen
    {
        col = vec3(1., 1., 1.);
        vec2 tx = toUV(vec4(-dims.xz, 2.*dims.xz), (scrTrf * vec4(op, 1.)).xz, vec2(1., 0.), vec4(lpWidth, 1.-lpHeight, lpWidth, lpHeight));
        
        vec4 scrCol = texture(iChannel3, tx);
        scrCol.rgb -= scrCol.rgb * (1. - scrCol.a);
        col = scrCol.rgb;
        _mtlParams.rgb = vec3(0.001, 0., 1. * scrCol.a);
        //col = (0.5 * scrTrf * on + vec4(0.5)).rgb;
    }
    else if (_mtl == (LAPTOP_MTL + 3)) // panel
    {
        col = vec3(0.3);
    }
    
    else if (_mtl == (LAPTOP_MTL + 4)) // jacks
    {
        vec3 c = op - vec3(dims.x, 0., -dims.z + 1.075 + 0.14);
        float fc = sdCapsule(c.yz, 0.5, 0.025);
        float fp = 1. - (length(fract((c + vec3(0., 0.4, 0.25)) * 9.).yz - vec2(0.5)) - 0.2);
        col = mix(col, 0.5*col, (1. - smoothstep(0., 0.08, fc)));
        col += (1. - smoothstep(0., 0.02, fc)) * pow(fp, 64.) * vec3(1., 1., 0.2);
    }
    
    if (_mtl == (LAPTOP_MTL + 2) && (scrTrf * on).z > 0.8) // the low normal direction is to account for blending
    {
        col = vec3(0.3);
    }
   
    return vec3(col); 
}

float cushion_pattern(in vec2 _st) {
    vec2 grid0 = _st * vec2(1., 1.);
    vec2 grid1 = grid0;
    grid0.x += noise(grid0.y*0.5 + grid0.x)*0.3;
    grid1.x += noise(grid0.y*0.3 + 3.*grid0.x + 2.)*0.5;
    vec2 fgrid0 = fract(grid0);
    vec2 fgrid1 = fract(grid1);
    
    float f = PULSE_T(fgrid0.x, 0.15, 0.4, 0.6);
    f = max(f, PULSE_T(fgrid1.x, 0.1, 0.3, 0.4));
    return f;
}
vec3 render_cushion(in vec3 _p, in vec3 _n, in vec3 _w) {
    const float n_legs = float(N_CHAIRS);
    vec4 fAng = sdAngularPattern(_p.xz, n_legs, 0.);
    int chId = int(fAng.w*n_legs);
    
    vec2 trp = fAng.y*vec2(cos(fAng.z), sin(fAng.z));
    
    vec3 op = vec3(trp.x, _p.y, trp.y);
    
    float rotAng = TF(iChannel3, ivec2(chId/4, CHAIR_ROT))[chId % 4];
    op.xz *= rot2D(rotAng);
    
    float dz = max(cushion_pattern(op.xy), cushion_pattern(op.yx));
    float dy = max(cushion_pattern(op.zx), cushion_pattern(op.xz));
    float dx = max(cushion_pattern(op.zy), cushion_pattern(op.yz));
    
    vec3 col = mix(vec3(1.5), vec3(0.9), (dx * _w.x + dy *_w.y + dz * _w.z));
    float dpxz = length(fwidth(_p.xz));
    col = mix(col, vec3(1.1), smoothstep(0., 1., dpxz));
    return col;
    //return vec3(0.9);
}

struct MtlParams {
    float roughness; // reflectance
    float metalness;
    float ao; //
    vec3  norm;
    vec3  fresnel_0;
    float emissive;
    vec3  clr;
    vec3  p;
    float t; // debug;
};

vec3 light_shade(const vec3 _p, const vec3 _d, const vec3 _n,
           in int _il, const float _lshadow, 
           const MtlParams _params, const MtlParams _rflParams) {
    vec4 lgeo = TF3(ivec2(LIGHT_GEO, _il));
    vec4 lprop = TF3(ivec2(LIGHT_PROP, _il));
    
    vec3 ldir = (lgeo.xyz - _p);
    vec3 nldir = mix(normalize(lgeo.xyz), normalize(ldir), lgeo.w);
    
    vec3 rfldir = (lgeo.xyz - _rflParams.p);
    vec3 nrfldir = mix(normalize(lgeo.xyz), normalize(rfldir), lgeo.w);
    
    float intensity = mix(lprop.w, lprop.w / pow(0.1*length(ldir), 2.), lgeo.w);
    intensity = max(0., intensity - _lshadow * (1. + length(_rflParams.norm)/(1. + 0.05*_rflParams.t)));
    vec3 h = normalize(-_d + nldir);
    vec3  ns = _params.norm.xyz; // norm for specular light.
    float nh = max(dot(ns, h), 0.0);
    float nv = max(dot(ns, -_d), 0.0);
    float nl = max(dot(ns, nldir), 0.0);
    float ndl = max(dot(_n, nldir), 0.0);
    float hv = max(dot(h, -_d), 0.0);
    float hl = max(dot(h, nldir), 0.0);
    
    
    // cook torrance
    // Normal alignment
    float a = _params.roughness * _params.roughness;
    float a2 = a * a;
    float N = a/(PI*pow(nh*nh*(a-1.) + 1., 2.));
    
    // Geometrical occlusion 
    //float k = 0.125 * pow(_params.roughness + 1., 2.);
    float k = 0.5 * a;
    float gOut = nv / (nv * (1. - k) + k);
    float gIn = nl / (nl * (1. - k) + k);
    
    // Fresnel shlick approximation
    //vec3 specClr = mix(vec3(0.4), _params.clr, _params.metalness);
    //specClr = vec3(0.6);
    vec3 specClr = _params.fresnel_0;
    vec3 light_clr = lprop.rgb  + _rflParams.clr * _rflParams.emissive;
    //specClr = mix(specClr, mix(_params.rflClr.rgb, specClr, 1. - hv), _params.rflClr.w);
    
    vec3 fshlick = specClr + (1. - specClr) * pow(1. - hl, 5.);
    float spec_denom = 4. * nv * nl + T_EPS;
    vec3 spec = (1. - _lshadow) * N * gIn * gOut * fshlick / spec_denom;
    
    // reflection
    float rfl_nl = (1.-_lshadow)*max(dot(_rflParams.norm, nrfldir), 0.1);
    spec += fshlick * rfl_nl * _rflParams.clr / PI;

    vec3 diffuse = (light_clr) * (1.-fshlick) * _params.ao * _params.clr / PI;
    //return vec3(intensity);
    //intensity = min(intensity, 1.);
    // remove emissive from per light computation
    return (spec * hl + diffuse * (ndl) ) * intensity;
    //return (spec * hl) * intensity;
    //return vec3(clamp(N, 0., 1.));
    //return clamp(spec * hl * intensity, 0., 1.) + diffuse * nl * intensity;
}

// This is the color on reflection.
// Basically the same function with some simplifications to
// improve the compilation on windows.
void get_rfl_mtl_color(in vec3 _p, inout vec3 _n, in vec3 _d, in int _mtl,
    in float _t, in float _scr_res, inout MtlParams _params) {
    vec3 base_col;
    bool isMetalFrameMtl = is_metal_mtl(_mtl);
    _params.roughness = 0.9;
    _params.metalness = 0.0;
    _params.emissive = 0.0;
    _params.fresnel_0 = vec3(0.02);
    _params.norm = _n;

    // Because we use triplanar projection multiple times
    // compute it here and use everywhere.
    vec3  nw; // weights
    vec3  n2 = _n * _n;
    float sw = n2.x + n2.y + n2.z;
    nw.x = n2.x/sw;
    nw.y = n2.y/sw;
    nw.z = n2.z/sw;
    
    vec3 wood_mtl = triplanar(_p, vec3(0.01, 0.1, 0.01), nw).rgb;
    vec3 wood_ch_mtl = triplanar(_p, vec3(0.1), nw).rgb;
    if (_mtl == CHAIR_CUSHION_MTL) {
        base_col = vec3(1.1);
        _params.roughness = 0.99;
        _params.fresnel_0 = vec3(0.02);
    }
    else if (isMetalFrameMtl) {
        base_col = vec3(0.84, 0.5, 0.3) * length(wood_ch_mtl);
        _params.roughness = (_mtl == CHAIR_FRAME_MTL) ? 0.275 : 0.2;
        _params.metalness = 1.;
        _params.fresnel_0 = 0.5*base_col;
    }
    else if (_mtl == TABLE_TOP_MTL) {
        base_col = 0.2*wood_mtl;
        _params.roughness = 0.99;
        _params.fresnel_0 = vec3(0.0);
    }
    else if (_mtl == CHAIR_BCK_LEG_MTL || _mtl == CHAIR_FRNT_LEG_MTL) {
        base_col = 2.*wood_ch_mtl;
        _params.roughness = 0.25;
        _params.fresnel_0 = vec3(0.1);
    }
    else if (_mtl == CHAIR_BASE_MTL) {
        base_col = 1.2*wood_ch_mtl;
        _params.roughness = 0.35;
        _params.fresnel_0 = vec3(0.35); // substitue with different parts
    }
    else if (_mtl == CHAIR_BACK_MTL) {
        base_col = 1.2*wood_ch_mtl;
        _params.roughness = 0.05;
        _params.fresnel_0 = vec3(0.35); // substitue with different parts
    }
    else if (_mtl >= LAPTOP_MTL) {
        vec4 mtl;
        base_col = render_laptop(_p, _n, _d, _t, _mtl, _scr_res, mtl);
        _params.roughness = mtl.x;
        _params.metalness = mtl.y;
        _params.emissive = mtl.z;
        _params.fresnel_0 = vec3(0.25);
    }
    
    _params.clr = base_col;
}

void get_mtl_color(in vec3 _p, inout vec3 _n, in vec3 _d, in int _mtl,
    in float _t, in float _scr_res, inout MtlParams _params) {
    vec3 base_col;
    bool isMetalFrameMtl = is_metal_mtl(_mtl);
    _params.roughness = 0.9;
    _params.metalness = 0.0;
    _params.fresnel_0 = vec3(0.02);
    _params.norm = _n;
    
    // Because we use triplanar projection multiple times
    // compute it here and use everywhere.
    vec3  nw; // weights
    vec3  n2 = _n * _n;
    float sw = n2.x + n2.y + n2.z;
    nw.x = n2.x/sw;
    nw.y = n2.y/sw;
    nw.z = n2.z/sw;
    
    vec3 wood_mtl = triplanar(_p, vec3(0.01, 0.1, 0.01), nw).rgb;
    vec3 wood_ch_mtl = triplanar(_p, vec3(0.1), nw).rgb;
    if (_mtl == CHAIR_CUSHION_MTL) {
        base_col = render_cushion(_p, _n * _n, nw);
        _params.roughness = 0.99;
        _params.fresnel_0 = vec3(0.02);
    }
    else if (isMetalFrameMtl) {
        base_col = vec3(0.84, 0.5, 0.3) * length(wood_ch_mtl);
        _params.roughness = 0.2;
        _params.metalness = 1.;
        _params.fresnel_0 = 0.5*base_col;
    }
    else if (_mtl == TABLE_TOP_MTL) {
        base_col = wood_mtl;
        _params.roughness = 0.1 + 0.5*clamp((1. - length(base_col)), 0., 1.);
        _params.fresnel_0 = vec3(0.35);
    }
    else if (_mtl == CHAIR_BCK_LEG_MTL || _mtl == CHAIR_FRNT_LEG_MTL) {
        base_col = 2.*wood_ch_mtl;
        _params.roughness = 0.25;
        _params.fresnel_0 = vec3(0.1);
    }
    else if (_mtl == CHAIR_BASE_MTL) {
        base_col = 1.2*wood_ch_mtl;
        _params.roughness = 0.35;
        _params.fresnel_0 = vec3(0.35); // substitue with different parts
    }
    else if (_mtl == CHAIR_BACK_MTL) {
        base_col = 1.2*wood_ch_mtl;
        _params.roughness = 0.05;
        _params.fresnel_0 = vec3(0.35); // substitue with different parts
    }
    else if (_mtl >= LAPTOP_MTL) {
        vec4 mtl;
        base_col = render_laptop(_p, _n, _d, _t, _mtl, _scr_res, mtl);
        _params.roughness = mtl.x;
        _params.metalness = mtl.y;
        _params.emissive = mtl.z;
        _params.fresnel_0 = vec3(0.25);
    }
    
    _params.clr = base_col;
}

MtlParams getReflectionClr(in float _t, in vec3 _p, in vec3 _d, in vec3 _n, 
    in int _mtl, in int _rfl_mtl, in float _scr_res) {
    
    vec3 rfl_dir = normalize(reflect(_d, _n));
    int rfl_trace_flag = TRACE_NO_FLAG;
    float eps = N_EPS;
    
    if (_mtl == FLOOR_MTL) {
        rfl_trace_flag = TRACE_TABLE_FLAG | TRACE_CHAIRS_FLAG;
    }
    else if ((_mtl == TABLE_TOP_MTL && _n.y > 0.9) || _mtl >= LAPTOP_MTL) {
        rfl_trace_flag = TRACE_LAPTOP_FLAG;
    }
    if (_mtl == LAPTOP_BASE_MTL && _n.y > 0.75)
    {
        rfl_dir = vec3(0., 1., 0.); // emissive light from screen.
        rfl_dir.xz = 0.25*(0.5 - vec2(hash(_p.x), hash(_p.z)));
        rfl_dir = normalize(rfl_dir);
    }
                    
    vec3 rp = _p + (_t + T_EPS) * rfl_dir;
#ifdef PACK_CUI_VALUES
    int i_rfl_mtl = _rfl_mtl;
#else
    int i_rfl_mtl = int(map(rp, rfl_trace_flag, iChannel3, false, true).y);
#endif 
    eps -= 0.9 * N_EPS * float(i_rfl_mtl == LAPTOP_SCREEN_MTL);
    MtlParams params;
    //params.norm = norm_forward(rp, rfl_trace_flag, eps);
    params.norm = calcNormal(rp, rfl_trace_flag, eps);
    params.p = rp;
    params.t = _t;

     get_rfl_mtl_color(rp, params.norm, rfl_dir, i_rfl_mtl, 
         _t, _scr_res, params);
    
    return params;
}

vec3 render_floor_high(in vec3 _o, in vec3 _d, in float _tract_t, 
                        vec2 _lshadows, in MtlParams _rflParams) 
{
    vec3 p = _o + _d * _tract_t;
    vec3 n = vec3(0., 1., 0.);
    MtlParams params;
    
    vec3 base_col = render_floor(p, _tract_t, n);
    params.metalness = 0.;
    params.roughness = 0.3 + 0.7*clamp((1. - length(base_col)), 0., 1.);
    params.fresnel_0 = vec3(0.2);
    params.clr = base_col;
    params.ao = 1.;
    
    vec3 col = vec3(0.);
    for (int il = LIGHT_0; il < LIGHT_0 + N_LIGHTS; il++) {
        col += light_shade(p, _d, n, il, _lshadows[il - LIGHT_0], params, _rflParams);
    }
    
    return vec3(col);
}

vec3 render(in float _ao, in vec3 _o, in vec3 _d, in vec3 _n, 
    in int _mtl, in float _tract_t,  vec2 _lshadows, 
    const float _scr_res, in MtlParams _rflParams, out vec3 _emissive) {
    vec3 p = _o + _d * _tract_t;
    
    vec3 col;
    vec3 n = _n;
    int i_mtl = _mtl;
    vec3 base_col = vec3(1.);//m_cls[i_mtl];
    MtlParams params;
    params.roughness = 0.1;
    params.metalness = 0.5;

    params.ao = _ao;
    get_mtl_color(p, n, _d, _mtl, _tract_t, _scr_res, params);

    col = vec3(0.);
    for (int il = LIGHT_0; il < LIGHT_0 + N_LIGHTS; il++) {
        col += light_shade(p, _d, n, il, _lshadows[il - LIGHT_0], params, _rflParams);
    }
    
    _emissive = params.clr * params.emissive;

    return vec3(col);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = (2.*fragCoord - iResolution.xy)/(iResolution.y);
    vec2 muv = (2.*iMouse.xy - iResolution.xy)/(iResolution.y);
    vec2 ruv = fragCoord/iResolution.xy;
    float scr_resolution = iResolution.x / iResolution.y;

    float full_pixel = 2./iResolution.y;
    float half_pixel = 0.5 * full_pixel;
    float quad_pixel = 0.5 * half_pixel;
    
    vec3 col;
    vec3 n;
    vec4 raycast = texture(iChannel0, ruv);
    vec4 sec_cast = TF1(ivec2(fragCoord));
    vec2 shadow; // entry for each light
    float ao; // ambient occlusion
    int i_mtl = DEFAULT_MTL;
    int i_rfl_mtl = DEFAULT_MTL;
    vec2 truv = ruv;
    vec2 tcrd = fragCoord;
    float tlfactor = 1.;
    
#ifdef DOWNSAMPLE_SHADOWS
    truv = ruv * 0.5;
    tcrd = fragCoord * 0.5;
    tlfactor = 0.5;
#endif

#ifndef PACK_CUI_VALUES
    sec_cast.rgb = texture(iChannel1, truv).rgb;
    sec_cast.rgb = laplace(1., sec_cast.rgb, iChannel1,
        truv, vec2(scr_resolution * tlfactor, tlfactor)/iResolution.y);
    shadow = sec_cast.yz;
    ao = sec_cast.x;
#else
    sec_cast.x = TF1(ivec2(tcrd)).x;
    UNPACK_UINT_TO_CUI3(sec_cast.x)
    unpacked_cui3.rgb = laplace_packed(1., unpacked_cui3.rgb, iChannel1, ivec2(tcrd));
    shadow = unpacked_cui3.rg;
    ao = unpacked_cui3.b;
    i_mtl = int(sec_cast.y);
    i_rfl_mtl = int(sec_cast.z);
    
#endif // PACK_CUI_VALUES
    
    float tfloor = 0.;
    vec3 emit_col;
    vec3 p;
    float dot_p_xz;
    MtlParams rflParams;
    bool hitGeom = raycast.x > T_EPS;

    // camera setup - defining o, d, trg (look at)
    CAMERA_SETUP(uv)

    float iter = MAX_SH_ITER;
    float far = FAR;

    if (hitGeom) {
#ifndef PACK_CUI_VALUES
        i_mtl = int(map(o + raycast.x * d, TRACE_NO_FLOOR, 
            iChannel3, false, true).y);
#endif
            n = normalize(raycast.yzw);
            p = o + raycast.x * d;
    }

    tfloor = rayXFloor(o.y, d.y);
    if (tfloor > 0. && !hitGeom && tfloor < FAR) {
        i_mtl = FLOOR_MTL;
        n = vec3(0., 1., 0.);
        p = o + tfloor * d;
        hitGeom = true;
        ao = 1.;
    }

    dot_p_xz = dot(p.xz, p.xz);

    if (hitGeom && dot_p_xz < FLOOR_BOUNDING_CIRCLE_SQR) {
        if (sec_cast.w > T_EPS)
            rflParams = getReflectionClr(sec_cast.w, p, d, n, i_mtl, i_rfl_mtl, scr_resolution);
    }

    if (i_mtl == FLOOR_MTL  && dot_p_xz < FLOOR_BOUNDING_CIRCLE_SQR) {
        col = render_floor_high(o, d, tfloor, shadow.xy, rflParams);
        for (float iy = quad_pixel; iy < full_pixel; iy += half_pixel) {
            for(float ix = quad_pixel; ix < full_pixel; ix += half_pixel) {
                vec4 trg = TF3(LOOKAT_SEQ);                   \
                vec3 dq = normalize(vec3((uv + vec2(ix, iy))*tan(trg.w), -1.)); \
                dq = lookAt(o, dq, trg.xyz);
                float tf = rayXFloor(o.y, dq.y);
                col += render_floor_high(o, dq, tf, shadow.xy, rflParams);
            }
        }
        col /= 5.;
        emit_col /= 5.;
    }
    else if (i_mtl == FLOOR_MTL) {
        col = vec3(0.);
    }
    else if (hitGeom) {
        col = render(ao, o, d, n, i_mtl, raycast.x, 
            shadow, scr_resolution, rflParams, emit_col);
    }

    // post processing
    // tone mapping    
    col *= 2.;
    col /= (col*0.9 + 1.1);
    col += emit_col;
    col.rgb = pow(col.rgb, vec3(1.6)); // 

    fragColor = vec4(col, 0.);
}
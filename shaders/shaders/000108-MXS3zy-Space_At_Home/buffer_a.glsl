// Buffer A (buffer) — Space At Home by lz
// https://www.shadertoy.com/view/MXS3zy

/*
    Space at home. 
    Copyright © 2024 Leonid Zaides
    Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the “Software”), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
    The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
    THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.   
*/

// Control and texture buffer.
// Camera sequence, laptop sequence, laptop animation and lighting are defined here.

#define _0 vec2(0., 12.)
#define _1 vec2(1., 12.)
#define _2 vec2(2., 12.)
#define _3 vec2(3., 12.)
#define _4 vec2(4., 12.)
#define _5 vec2(5., 12.)
#define _6 vec2(6., 12.)
#define _7 vec2(7., 12.)
#define _8 vec2(8., 12.)
#define _9 vec2(9., 12.)

#define _P vec2(0., 10.)
#define _Q vec2(1., 10.)
#define _R vec2(2., 10.)
#define _S vec2(3., 10.)
#define _T vec2(4., 10.)
#define _U vec2(5., 10.)
#define _V vec2(6., 10.)
#define _W vec2(7., 10.)
#define _X vec2(8., 10.)
#define _Y vec2(9., 10.)
#define _Z vec2(10., 10.)
#define _A vec2(1., 11.)
#define _B vec2(2., 11.)
#define _C vec2(3., 11.)
#define _D vec2(4., 11.)
#define _E vec2(5., 11.)
#define _F vec2(6., 11.)
#define _G vec2(7., 11.)
#define _H vec2(8., 11.)
#define _I vec2(9., 11.)
#define _J vec2(10., 11.)
#define _K vec2(11., 11.)
#define _L vec2(12., 11.)
#define _M vec2(13., 11.)
#define _N vec2(14., 11.)
#define _O vec2(15., 11.)

#define _AT vec2(0., 11.)

#define _EXM    vec2(1., 13.)
#define _DQT    vec2(2., 13.)
#define _SHARP  vec2(3., 13.)
#define _DLR    vec2(4., 13.)
#define _PRC    vec2(5., 13.)
#define _AND    vec2(6., 13.)
#define _QT     vec2(7., 13.)
#define _OPN_RND_BRCK vec2(8., 13.)
#define _CLS_RND_BRCK vec2(9., 13.)
#define _STAR   vec2(10., 13.)
#define _PLUS   vec2(11., 13.)
#define _COMMA  vec2(12., 13.)
#define _DASH   vec2(13., 13.)
#define _DOT    vec2(14., 13.)
#define _SLASH  vec2(15., 13.)

#define _CLN  vec2(10., 12.)
#define _SCLN vec2(11., 12.)
#define _LST  vec2(12., 12.)
#define _EQ   vec2(13., 12.)
#define _GRT  vec2(14., 12.)
#define _QM   vec2(15., 12.)

#define _OPN_SQR_BRCK vec2(11., 10.)
#define _BSLASH       vec2(12., 10.)
#define _CLS_SQR_BRCK vec2(13., 10.)
#define _CIRCUMFLEX   vec2(14., 10.)
#define _LOW_DASH     vec2(15., 10.)

#define _OPN_PRN_BRCK vec2(11., 8.)
#define _PIPE         vec2(12., 8.)
#define _CLS_PRN_BRCK vec2(13., 8.)
#define _TILDA        vec2(14., 8.)

#define _BCKTICK      vec2(0., 9.)

#define _a vec2(4.,3.)

#define tx(_x, _y, _ch) float(iigrid.x == _x && iigrid.y == _y) * texture(iChannel1, 0.0625 * (_ch + cgrid)).r
#define txs(_x, _y, _ch) float(iigrid.x == _x && iigrid.y == _y) * texture(iChannel1, 0.0625 * (_ch + sgrid)).r
#define txn(_x, _y, _ch) float(iigrid.x == _x && iigrid.y == _y) * texture(iChannel1, 0.0625 * (_ch + ngrid)).r

#define tx_custom(_x, _y, _ch, _v) float(iigrid.x == _x && iigrid.y == _y) * texture(iChannel1, 0.0625 * (_ch + _v)).r

#define normUV(_uv, _pln) clamp((_uv - _pln.xy)/(_pln.zw), vec2(0.01), vec2(0.99))

#define ATF(_crd, _pos, _val) if (_crd.x == _pos.x && _crd.y == _pos.y) { col = _val; }

// VISUALIZATION on LAPTOP
const vec2 vhex = normalize(vec2(1., 0.5));
const float hexh = 0.8660254037; // = sqrt(3) / 2;
const float inv_hexh = 1.15470053837;
const vec2 hexGrid = vec2(3., sqrt(3.));
//https://iquilezles.org/articles/palettes/
#define CL(_id, _noise)  0.5 + 0.5*cos(6.28 * (_noise * vec3(0.2, 0.8, 0.4) + vec3(2.3, 1.8, 6.1) * vec3(hash(_id))));

vec4 hexgrid(in vec2 _uv)
{
  vec4 res;
  vec2 a = mod(_uv + 0.5 * hexGrid, hexGrid) - 0.5 * hexGrid;
  vec2 b = mod(_uv, hexGrid) - hexGrid * 0.5;
  
  vec2 fa = vec2(dot(abs(a), vhex), abs(a.y));
  vec2 fb = vec2(dot(abs(b), vhex), abs(b.y));
  
  float ma = max(fa.x, fa.y);
  float mb = max(fb.x, fb.y);
  
  vec2 bord;
  vec2 id;
  
  if (ma < mb)
  {
    bord = fa;
    id = floor((_uv + 0.5 * hexGrid) / hexGrid);
  }
  else
  {
    bord = fb;
    id = floor(_uv/hexGrid) + vec2(123., 273.);
  }
  
  res.x = min(ma, mb);
  res.y = min(1. - bord.x, 1. - bord.y);
  res.zw = id;
  
  return res;
}

vec4 hexThreeGrid(in vec2 _uv, in float _t) {
    vec2 uv = 2.*_uv - 1.;
    float gr_size = 4.;
    vec4 hgrid = hexgrid(uv*gr_size);
    float gid = hgrid.z * 1000. + hgrid.w;
    
    vec3 col1;
    col1 = CL(gid, noise(0.97*iTime + 131.2));
    col1 *= (0.3 + 0.5 * smoothstep(0.0, 0.4, hgrid.y));
    //col1 *= ((0.5 + 0.5 * cos(6.28 * 3. * hgrid.x)));
    
    vec4 hgrid2 = hexgrid((uv + vec2(0.5, hexh)) * gr_size);
    float gid2 = hgrid2.z * 1923. + hgrid2.w;
    vec3 col2 = CL(gid2, noise(_t*0.95 + 113.1));
    col2 *= (0.3 + 0.5 * smoothstep(0.0, 0.4, hgrid2.y));
    //col2 *= ((0.5 + 0.5 * cos(6.28 * 3. * hgrid2.x)));
    vec3 col = mix(col2, col1, 0.5 );
    
    // 
    col = 1.*pow(col, vec3(1.8));
    return vec4(col, 1.);
}

///////

float roundBox(in vec2 _uv, in vec4 _dims, in float _r)
{
    return sdBox(_uv - 0.5 * (2.*_dims.xy + _dims.zw), _dims.zw * (0.5 - 2.*_r)) - _r;
}

vec4 keyboardLayout(in vec2 _uv, in float _ratio)
{
    vec2 grid = _uv * vec2(15., 6.) - vec2(0.4, 0.);
    vec2 igrid = floor(grid);
    
    grid.x -= 0.0 * step(igrid.y, 4.5) + 0.3 * step(igrid.y, 3.5) + 0.3 * step(igrid.y, 2.5)
                + 0.5 * step(igrid.y, 1.5) + 0.3 * step(igrid.y, 0.5);

    igrid = floor(grid);
    vec2 fgrid = fract(grid);
    vec2 cgrid = normUV(fgrid, vec4(0.25, 0.25, 0.5, 0.5)); // center (Letters)
    vec2 sgrid = normUV(fgrid, vec4(0.3, 0.175, 0.4, 0.4)); // south
    vec2 ngrid = normUV(fgrid, vec4(0.3, 0.5, 0.4, 0.4)); // north
    
    vec2 nlgrid = normUV(fgrid, vec4(0.35, 0.5, 0.3, 0.3)); 
    
    ivec2 iigrid = ivec2(igrid);
    
    vec4 col = vec4(0.1, 0., 0., 0.);
    float fb = roundBox(fgrid, vec4(vec2(0.03), vec2(0.97)), 0.05);
    float fk = roundBox(_uv, vec4(vec2(0.001), vec2(0.999)), 0.01);
    
    float fkey = 0.;
    
    // digits
    for (int id = 1; id <= 10; id++)
        fkey += txs(id, 4, vec2(float(id % 10), 12.));
    // symbols above digits
    fkey += txn(1,4,_EXM) + txn(2,4,_AT) + txn(3,4,_SHARP) + txn(4,4,_DLR) + txn(5,4,_PRC) +
            txn(6,4,_CIRCUMFLEX) + txn(7,4,_AND) + txn(8,4,_STAR) + 
            txn(9,4,_OPN_RND_BRCK) + txn(10,4,_CLS_RND_BRCK);
    fkey += txn(12,4,_PLUS) + txs(12,4,_EQ);
            
    fkey += txs(0,4,_BCKTICK) + txn(0,4,_TILDA) + txs(11,4,_DASH) + txn(11,4,_DASH);
    fkey += txs(11,3,_OPN_SQR_BRCK) + txn(11,3,_OPN_PRN_BRCK) + 
            txs(12,3,_CLS_SQR_BRCK) + txn(12,3,_CLS_PRN_BRCK);
    fkey += txs(13,3,_BSLASH) + txn(13,3,_PIPE);
    fkey += txs(10,2,_SCLN) + txn(10,2,_CLN) + txs(11,2,_QT) + tx_custom(11,2,_DQT, nlgrid);
    
    fkey += txs(8,1,_COMMA) + txn(8,1,_LST) + txs(9,1,_DOT) + txn(9,1,_GRT);
    fkey += txs(10,1,_SLASH) + txn(10,1,_QM);
    
    // QWERTY
    fkey += tx(1,3,_Q) + tx(2,3, _W) + tx(3,3,_E) + tx(4,3,_R) + tx(5,3,_T) + tx(6,3,_Y);
    fkey += tx(7,3,_U) + tx(8,3, _I) + tx(9,3,_O) + tx(10,3,_P);
    fkey += tx(1,2,_A) + tx(2,2, _B) + tx(3,2,_D) + tx(4,2,_F) + tx(5,2,_G) + tx(6,2,_H);
    fkey += tx(7,2,_J) + tx(8,2, _K) + tx(9,2,_L);
    fkey += tx(1,1,_Z) + tx(2,1, _X) + tx(3,1, _C) + tx(4,1,_V) + tx(5,1,_B) + tx(6,1,_N) + tx(7,1,_M);
    
    float ikey = float(iigrid.y == 4 && (iigrid.x >= 0 && iigrid.x <= 12));
    ikey += float(iigrid.y == 3 && (iigrid.x >= 1 && iigrid.x <= 13));
    ikey += float(iigrid.y == 2 && (iigrid.x >= 1 && iigrid.x <= 11));
    ikey += float(iigrid.y == 1 && (iigrid.x >= 1 && iigrid.x <= 10));
    
    float in_key = float(iigrid.y == 4) + 
                14. * float(iigrid.y == 3) + 
                27. * float(iigrid.y == 2) +
                38. * float(iigrid.y == 1) + igrid.x;
    
    col.r += fkey*2.;
    fb = 1. - smoothstep(0.0, 0.05, fb);
    fk = 1. - smoothstep(0.0, 0.02, -fk);
    col.gb = -(vec2(dFdx(fb), dFdy(fb))) * ikey - vec2(dFdx(fk), dFdy(fk));
    col.w = ikey * in_key;
    
    return vec4(col);
}

vec4 keyboardTexture(in vec2 _uv, in float _ratio)
{
    vec4 frame = vec4(vec3(0.9), 0.);
    vec4 col = frame;
    
    const vec4 keyboard = vec4(0.115, 0.432, 0.77, 0.486);
    const vec4 trackpad = vec4(0.2767, 0.026, 0.446, 0.3636);
    
    float ftrack = roundBox(_uv, trackpad, 0.02);
    float fkeys = roundBox(_uv, keyboard, 0.02);
    
    if (inBox(abs(vec2(0.5, 0.) - _uv), vec4(0.38, 0.462, 0.115, 0.436)))
    {
        vec2 grid = _uv * (max(iResolution.x, iResolution.y) * 0.1);
        grid.y *= _ratio;
        float f = smoothstep(0.05, 0.15, length(fract(grid) - vec2(0.5)));
        //col = mix(vec4(vec3(0.1), 0.), frame, f);
    }

    float ftr = 1. - smoothstep(0., 0.005, -roundBox(_uv, vec4(trackpad.xy + vec2(0.0001), trackpad.zw - vec2(0.001)), 0.025));
    col.gb = -vec2(dFdx(ftr), dFdy(ftr));
    col.w = 0.5*step(ftrack, 0.);
    
    if (step(fkeys, 0.) > 0.5)
    {
        col = keyboardLayout(normUV(_uv, keyboard), iResolution.x/iResolution.y);
    }
    
    // trackpad
    col.r = mix(col.r, ((0.77) + 0.1*smoothstep(0., 0.001, -ftrack)), step(ftrack, 0.));
     
    return col;
}

float key_press_sequence(const float _time) {
    // key press sequence
    float t120 = mod(_time, 120.);
    float t180 = mod(_time, 180.);
    const float hit_start = 0.;
    float press_rate = 1.5+0.1*noise(t180);
    // 47 keys added.
    // 10% top row, 50% letters, 5% ></ and 35% no key is pressed
    float key_hash = hash(floor(t180 * press_rate));
    int key = 1 + int(13. * key_hash * step(key_hash, 0.1) + // top row
    (13. + 30. * key_hash) * (step(0.1, key_hash) - step(0.6, key_hash)) +
    (43. + 4. * key_hash) * (step(0.6, key_hash) - step(0.65, key_hash)) +
    50. * step(0.65, key_hash));
    
    return float(key);
}

float func(in vec2 _uv, in vec3 _params, in float _tf) {
    float lower = _params.x*pow(abs(_uv.x), 1./abs(_uv.x+0.01));
    //float upper = _params.y - _params.z * _uv.x * _uv.x;
    float upper = _params.y - atan(_params.z*_uv.x*_uv.x);
    
    float f = smoothstep(lower, lower+0.3,_uv.y) *
               smoothstep(_uv.y - 0.2, _uv.y, upper);
              
    f += (0.75 + _tf)*ANIM_T(_uv.y, 0.05, upper) * step(lower, upper);
    
    return f;
    //return step(lower, _uv.y) * step(_uv.y, upper);
}

vec4 welcome_visualization(in vec2 _ruv, in vec2 crd, in float _r) {
    vec2 uvScale = vec2(_r, 1.);
    
    vec2 _uv = uvScale * (_ruv * 2. - 1.);
    vec4 slens = vec4(0.6, 1.2, 1.2, 0.);
    slens.w = 2. * _r - dot(vec3(1.), slens.xyz);
    float time = iTime;
    float s1 = in_box(_uv, vec4(-_r, -1., slens.x, 2.));
    float s2 = in_box(_uv, vec4(-_r + slens.x, -1., slens.y, 2.));
    float s3 = in_box(_uv, vec4(-_r + dot(vec2(1.), slens.xy), -1., slens.z, 2.));
    float s4 = in_box(_uv, vec4(-_r + dot(vec3(1.), slens.xyz), -1., slens.w, 2.));
    
    vec3 c1 = vec3(1., 0., 0.75);
    vec3 c2 = vec3(0.0, 1., 0.1);
    vec3 c3 = vec3(0., 0., 1.);
    vec3 c4 = vec3(0.75, 0., 1.);
    float xtime = mod(time, 5.);
    
    float grad = _uv.y * 0.5 + 0.5;
    grad *= 0.75;
    float circ_mask = pow(length(_uv)/sqrt(_r * _r + 1.), 2.);
    float bsx = ANIM_T(_uv.x, 0.01, -_r + slens.x) + 
                ANIM_T(_uv.x, 0.01, -_r + slens.x + slens.y) + 
                ANIM_T(_uv.x, 0.01, -_r + slens.x + slens.y + slens.z);
    vec2 icell_y = vec2(floor(_uv.y * 10.), fract(_uv.y * 10.));
    int  ycell_id = int(icell_y) + 10;
    float bsy = 1.-PULSE_T(icell_y.y, 0.1, 0.1, 1. - 0.1);
    
    float amp_x = floor((100.*_ruv.x))*0.01;
    float f_amp_x = fract(100.*_ruv.x);
    
    float key_pressed = key_press_sequence(time);
    
    ivec2 key_ij = ivec2(int(key_pressed) / 12, int(key_pressed) % 12);
    float key_y_hit = float(key_ij.y == ycell_id - 7);
    float f_key = float(key_ij.x == 0) * s1 * key_y_hit;
    f_key += float(key_ij.x == 1) * s2 * key_y_hit;
    f_key += float(key_ij.x == 2) * s3 * key_y_hit;
    f_key += float(key_ij.x == 3) * s4 * key_y_hit;
    f_key *= step(key_pressed, 49.);
    
    float samp = 0.;
    const float krn = 3.;
    for (float eq_step = -krn; eq_step <= krn; eq_step++)
        samp += texture(iChannel0, vec2(floor((100.*_ruv.x) + eq_step)*0.01, 0.0)).x;
    samp /= (2.*krn + 1.);
    samp *= 0.5;
        
    float amp = 0.5 * texture(iChannel0, vec2(amp_x, .0)).x;
    
    float tf = ANIM_T(xtime, 0.1, _uv.x*0.5+_r) * step(0., _uv.y);
    
    vec2 fg1 = 1.8*(_uv - vec2(-1.6, -1.6));
    vec2 fg2 = 1.9*(_uv - vec2(-.6, -2.1));
    vec2 fg3 = 2.4*(_uv - vec2(.6, -2.3));
    vec2 fg4 = 2.2*(_uv - vec2(1.5, -1.85));
    
    float f1 = func(fg1, vec3(2.6, 4., 1.), tf);
    float f2 = func(fg2, vec3(2.5, 4.9, 0.4), tf);
    float f3 = func(fg3, vec3(3.8, 6.4, 0.3), tf);
    float f4 = func(fg4, vec3(2.6, 4.4, 0.3), tf);
    
    float scaled_y = smoothstep(0.3, 0.5, _uv.y*0.5 + 0.5);
    float scy = _uv.y*0.5 + 0.5;
    scaled_y += 2.*smoothstep(amp-0.1, amp, _uv.y + 0.2);
    float scaled_x = PULSE_T(f_amp_x, 0.1, 0.1, 0.9);
    
    vec3 col;
   
    col += vec3(bsx*0.25 + 0.5*bsy*grad) + (c1 * s1 + c2 * s2 + c3 * s3 + c4 * s4) * circ_mask;
    col += 0.75*(f1 * c1 + f2 * c2 + f3*c3 + f4*c4);
    
    col = mix(col*1., scaled_x*scaled_y*vec3(1.)*step(_uv.y+0.2, amp)*f3*f4, 0.25);
    col = mix(col*1., scaled_x*scaled_y*vec3(1.)*step(_uv.y+0.2, amp)*f2*f3, 0.25);
    col = mix(col*1., scaled_x*scaled_y*vec3(1.)*step(_uv.y+0.2, amp)*f1*f2, 0.25);
    
    col = mix(col, vec3(1., 0.9, 0.8) * (0.6 + amp), ANIM_T(_uv.y - 0.3 - 0.3*noise(_uv.x + iTime*0.35), 0.02, samp));

    col += vec3(0.1, 0.8, 0.4) * 0.5 * (1. - smoothstep(0., 0.7, length(_uv - vec2(-0.75, 0.2))));
    col += vec3(0.1, 0.6, 0.9) * 0.75 * (1. - smoothstep(0., 0.7, dot(_uv - vec2(0.7, 0.0),_uv - vec2(0.7, 0.0) ) ) );
    
    float fc = (1.-smoothstep(0., 0.0005, dot(_uv - vec2(-1.5, 0.75), _uv - vec2(-1.5, 0.75))));
    fc += 1.-smoothstep(0., 0.0005, dot(_uv - vec2(-0.6, 0.55), _uv - vec2(-0.6, 0.55)));
    fc += 1.-smoothstep(0., 0.0005, dot(_uv - vec2(0.5, 0.75), _uv - vec2(0.5, 0.75)));
    fc += 1.-smoothstep(0., 0.0005, dot(_uv - vec2(1.3, 0.75), _uv - vec2(1.3, 0.75)));
    //fc *= s2*(0.1+noise(iTime));
    fc = clamp(fc, 0., 1.);
    
    col += 0.5*vec3(fc);
    
    col *= (1. + 0.5*f_key);
    
    col /= (col + vec3(1.));
    col = 1.5*pow(col, vec3(1.5));
    //col = vec3(step(_uv.y, amp));
    //col = vec3(0.);
    //col.x = _uv.x;
    //col.y = _uv.y;
    return vec4(col, 1.);
}

vec4 screenTexture(in vec2 _uv, in float _scrRatio, in vec2 _crd)
{
    bool inFrame = inBox(_uv, vec4(0.02, 0.025, 0.96, 0.95));
    float f = sdBox(_uv - vec2(0.5), vec2(0.46, 0.45)) - 0.02;
    vec4 col = vec4(1., 0., 0., 1.);
    
    vec4 frameCol = clamp(mix(vec4(0.05, 0.05, 0.05, 0.), vec4(0.15, 0.15, 0.15, 0.), sqrt(f/0.02)), 0., 1.);
    vec2 st = _uv * 2. - vec2(1.);
    st.x /= _scrRatio;
    vec4 chex = mix(frameCol, hexThreeGrid(_uv, iTime), step(f, 0.));
    vec4 cwlc = mix(frameCol, welcome_visualization(_uv, _crd, _scrRatio), step(f, 0.));
    
    col = mix(chex, cwlc, PULSE_T(iTime, 1., 23., 24.) +
                 PULSE_T(iTime, 1., 109., 148.) +
                 step(ANIM_SEQ, iTime)*PULSE_T(mod(iTime, 37.), 1., 15., 29.));
    col = mix(col, vec4(vec3(0.05), 0.), step(sdBox(_uv - vec2(0.5, 0.05), vec2(1., 0.05)), 0.0));
    
    return col;
}


void getCamera(in vec2 _uv, in vec2 _muv, out vec3 _o, out vec4 _t) {
    
    float fov = 0.5;
    float atime = ANIM_TIME;

#ifndef DEBUG_HIT
#ifdef DEBUG_CIRCULAR_MOTION
    _o = getCameraPosition(atime);
    _t = vec4(getCameraTarget(atime), fov);
#endif // circular motion
#else
    {
    #ifdef DEBUG_CIRCULAR_MOTION
        _o = vec3(0., 30., -190.);
        _t = vec4(/*getCameraPosition(atime)*/0., 0., 20., fov);
    #else
        _o = vec3(75., 25., -75.);
        _o = rotX(_muv.y) * rotY(_muv.x*2.) * _o;
        _t = vec4(0., 5., 1., fov);
    #endif
    }
#endif
}

void prepareLaptopTransform(out mat4 _mainTrf, out mat4 _screenTrf) {
    vec3 targetOrigin = vec3(10., 4.5, 10.);//vec3(16., 5., 12.);
    vec2 screenRot = vec2(0.);
    
    // laptop screen.
    float l_anim_t = mod(ANIM_TIME, ANIM_SEQ);
    screenRot.y = mix(-PI,0.1*PI, smoothstep(4., 10., l_anim_t));
    screenRot.y = mix(screenRot.y, -PI*0.2, smoothstep(133.,136., l_anim_t));
    screenRot.y = mix(screenRot.y, -PI, smoothstep(140., 143., l_anim_t));
    screenRot.x = 0.4*PULSE_T(l_anim_t, 5., 12.6, 105.);
    screenRot.x = mix(screenRot.x, 0.5, smoothstep(140., 145., l_anim_t));
    targetOrigin += vec3(-4., 0., 10.) * PULSE_T(l_anim_t, 4., 10.5, 105.5);
    
    _mainTrf = mat4(1.);
    _mainTrf *= Rxz(screenRot.x*1.57);
    _mainTrf[3].xyz -= targetOrigin;
    
    mat4 tmtx = mat4(1.);
    // this is the screen offset relative to center of the laptop
    vec3 scrOff = vec3(0., 0.175, 9.75 *0.5 - 0.125);
    // the rotation anchor may differs from the screen attachment.
    tmtx[3].xyz = scrOff - vec3(0., 0.15, 0.);
    _screenTrf = Ryz(clamp(1.45 + 1.5*screenRot.y, 0., 2.2));
    _screenTrf *= tmtx;
    tmtx[3].xyz -= 2.*scrOff;
    _screenTrf = tmtx * _screenTrf;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = (2.*fragCoord - iResolution.xy)/(iResolution.y);
    vec2 muv = (2.*iMouse.xy - iResolution.xy)/(iResolution.y);
    
    vec2 ruv = fragCoord.xy / iResolution.y;
    float scrRatio = iResolution.x / iResolution.y;
    float lpWidth = scrRatio * 0.5;
    const float lpRatio = 0.6965386; // this is a constant of a laptop --> width to height ratio.
    float lpHeight = lpWidth * lpRatio;
    vec2 keyStart = vec2(0.5*scrRatio - lpWidth, 1. - lpHeight);
    vec2 scrStart = vec2(lpWidth, 1. - lpHeight);
    vec4 col = vec4(vec3(0.5), 0.);
    float fps;
    float wide_screen_mode = WIDE_SCREEN_AR;
    vec4 prev_res = TF2(RES_DATA);
    vec4 fps_data = TF2(FPS_DATA);
    float res_changed = 1.;
    
    if (inBox(ruv, vec4(keyStart, lpWidth, lpHeight)))
    {
        col = keyboardTexture((ruv - keyStart)/vec2(lpWidth, lpHeight), lpRatio);
        //col = vec4(floor(5.*ruv/vec2(lpWidth, lpHeight)) / 5., 0., 1.);
    }
    else if (inBox(ruv, vec4(scrStart, lpWidth, lpHeight)))
    {
        col = screenTexture((ruv - scrStart)/vec2(lpWidth, lpHeight), scrRatio, fragCoord);
        //col = vec4(0., floor(5.*(ruv - vec2(lpWidth, 0.))/vec2(lpWidth, lpHeight))/5., 1.);
    }
    
    // CONTROL ZONE
    ivec2 crd = ivec2(fragCoord);
    if (crd.y < CTRL_ZONE && iFrame == 0) {
        // mapping of casting shadows materials.
        // DEFAULT_MTL, FLOOR_MTL, TABLE_FRAME_MTL, TABLE_TOP_MTL
        ATF(crd, ivec2(0, GEOM_SHADOW_MAP), vec4(TRACE_NO_FLAG, TRACE_NO_FLOOR, TRACE_TABLE_LAPTOP,TRACE_TABLE_LAPTOP));
        // CHAIR_BASE_MTL, CHAIR_BCK_LEG_MTL, CHAIR_FRNT_LEG_MTL, CHAIR_BACK_MTL
        ATF(crd, ivec2(1, GEOM_SHADOW_MAP), vec4(TRACE_CHAIR_UPPER_W_CUSHION | TRACE_TABLE_TOP_FLAG, TRACE_CHAIR_UPPER_W_CUSHION | TRACE_TABLE_TOP_FLAG, TRACE_CHAIR_UPPER_W_CUSHION | TRACE_TABLE_TOP_FLAG, TRACE_NO_FLAG));
        // CHAIR_FRAME_MTL, CHAIR_CUSHION_MTL, LAPTOP_BASE_MTL, LAPTOP_SCREEN_MTL
        ATF(crd, ivec2(2, GEOM_SHADOW_MAP), vec4(TRACE_NO_FLAG, TRACE_TABLE_LAPTOP | TRACE_CHAIR_UPPER, TRACE_LAPTOP_SCREEN_FLAG, TRACE_NO_FLAG/* | TRACE_TABLE_TOP_FLAG*/));
        
        // mapping of AO
        // DEFAULT_MTL, FLOOR_MTL, TABLE_FRAME_MTL, TABLE_TOP_MTL
        ATF(crd, ivec2(0, GEOM_AO_MAP), vec4(TRACE_NO_FLAG, TRACE_NO_FLAG, TRACE_TABLE_FLAG,TRACE_TABLE_LAPTOP));
        // CHAIR_BASE_MTL, CHAIR_BCK_LEG_MTL, CHAIR_FRNT_LEG_MTL, CHAIR_BACK_MTL
        ATF(crd, ivec2(1, GEOM_AO_MAP), vec4(TRACE_CHAIRS_FLAG, TRACE_CHAIRS_FLAG, TRACE_CHAIRS_FLAG, TRACE_CHAIRS_FLAG));
        // CHAIR_FRAME_MTL, CHAIR_CUSHION_MTL, LAPTOP_BASE_MTL, LAPTOP_SCREEN_MTL
        ATF(crd, ivec2(2, GEOM_AO_MAP), vec4(TRACE_CHAIRS_FLAG, TRACE_CHAIRS_FLAG, TRACE_LAPTOP_FLAG, TRACE_LAPTOP_FLAG/* | TRACE_TABLE_TOP_FLAG*/));
        
        ATF(crd, ivec2(0, CHAIR_ROT), vec4(-0.9*PI -PI/1.1, 1. -PI/1.1, PI/3. -PI/1.1, PI/4. -PI/1.1 + + PI/1.8));
        ATF(crd, ivec2(1, CHAIR_ROT), vec4(PI/4. -PI/1.1,0., 0., 0.));
    
        
    }
    else if (crd.y < CTRL_ZONE) {
        vec4 ctrl = TF2(crd);
        col = ctrl;
        // LIGHTS
        
        float t_light_cycle = mod(ANIM_TIME, ANIM_SEQ);
        float l0_i = PULSE_T(t_light_cycle, 4., 5., ANIM_SEQ-5.);
        float l1_i = PULSE_T(t_light_cycle, 3., 25., ANIM_SEQ-3.);
        vec3  l2_= normalize(vec3(0., -0.5, 1.));
        float l2_i = ASYM_PULSE_T(t_light_cycle, 10., 10.5, 12., 56.);
        
        if (ANIM_TIME > ANIM_SEQ) {
            t_light_cycle = mod(ANIM_TIME, 10.);
            l0_i = PULSE_T(t_light_cycle, 2., 2., 8.);
            l1_i = PULSE_T(t_light_cycle, 2.5, 2.5, 7.5);
        }
        
        l1_i *= 1.2;
        
        ATF(crd, ivec2(LIGHT_GEO, LIGHT_0), vec4(vec4(-10, 70., 10., 1.)));
        ATF(crd, ivec2(LIGHT_PROP, LIGHT_0), vec4(1,0.956863,0.898039,600.*l0_i));
        
        ATF(crd, ivec2(LIGHT_GEO, LIGHT_1), vec4(30., 70., -150., 1.));
        ATF(crd, ivec2(LIGHT_PROP, LIGHT_1), vec4(1,0.839216,0.666667, 800.*l1_i));
        
        // LAPTOP
        ATF(crd, LAPTOP_H_DIMS, 0.5 * vec4(14., 0.5, 9.75, 0.));
        ATF(crd, LAPTOP_KEY_ANIM, vec4(key_press_sequence(iTime), vec3(0.)));
        
        mat4 lpTrf = mat4(1.);
        mat4 lpScrTrf = mat4(1.);
        
        prepareLaptopTransform(lpTrf, lpScrTrf);
        
        ATF(crd, LAPTOP_BASE_TRF_0, lpTrf[0]);
        ATF(crd, LAPTOP_BASE_TRF_1, lpTrf[1]);
        ATF(crd, LAPTOP_BASE_TRF_2, lpTrf[2]);
        ATF(crd, LAPTOP_BASE_TRF_3, lpTrf[3]);
        
        ATF(crd, LAPTOP_SCRN_TRF_0, lpScrTrf[0]);
        ATF(crd, LAPTOP_SCRN_TRF_1, lpScrTrf[1]);
        ATF(crd, LAPTOP_SCRN_TRF_2, lpScrTrf[2]);
        ATF(crd, LAPTOP_SCRN_TRF_3, lpScrTrf[3]);
        
        // CAMERA
        if (crd.y <= CAMERA_SETUP_ROW) {
            vec3 o;
            vec4 t;
            getCamera(uv, muv, o, t);
            ATF(crd, ORIG_SEQ, vec4(o, 1.));
            ATF(crd, LOOKAT_SEQ, t);
        }
        
        // FPS
        //ATF(crd, RES_DATA, vec4(iResolution.xy, 0., 0.));
        if (iFrame % 20 == 1) {
          fps = 20. / (iTime - fps_data.x);
          ATF(crd, FPS_DATA, vec4(iTime, fps, iResolution.y, 0.));
        }
    }

    fragColor = vec4(col);
}
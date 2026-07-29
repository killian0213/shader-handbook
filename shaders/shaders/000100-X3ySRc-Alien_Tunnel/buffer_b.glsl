// Buffer B (buffer) — Alien Tunnel by lz
// https://www.shadertoy.com/view/X3ySRc


float get_slen(in vec3 p, in float _t, in float _factor) {
   return PI2 * (3. + 0.8*sin(iTime * 0.45 + p.x*0.5) + _factor * (18. + noise3(p*0.1) + 0.15*sin(5.*iTime)-2.5*(log(length(p)))) );
}
vec3 double_gyroid(in vec3 p, in float t, in bool high)
{
    vec3 r;
    float s_len = get_slen(p, iTime, 0.5);
    
    float fn = dot(cos(p*PI2 / s_len), sin(p.yzx * PI2 / s_len));
    
    r.x = fn*fn - t*t;
    
    // differentiate gyroid
    r.z = sign( (abs(fn - t) - abs(fn + t)) );
    
    // differentiate side of the gyroid
    r.y = sign( r.x );
    
    r.x = 0.5*abs(r.x);
    
    return r;
}

float srad;
float glow;
vec3 g_col;

float lite_shift(in vec3 _p, in float _t) {
    return 0.13*sin(_p.y*10. + 0.2*_t) + 0.11*sin(_p.y*27. + 0.23*_t + 7.32) + 
           0.134*sin(_p.y*7. + 1.2 + 0.1*_t) +
           0.141*sin(_p.y*12. + 0.7 + 0.3*_t);
}

vec4 geomI(in vec3 p, in bool high)
{
    //p.x += 2.5*sin(p.x*0.01) + 0.1*sin(p.y*2. + iTime*0.5);
    //p.y += 4.3*cos(p.z*0.1) + 0.1*cos(p.z*2. + iTime*0.75) + 0.2*cos(p.x*2. + iTime*0.37);
    //float dfx = PULSE_T(mod(iTime, 4.), 2., 2., 2.);
    vec3 gf = double_gyroid(p, 0.7, high);
    float rf = (high) ? 0.05*fbm(p) : 0.0;
    gf.x += rf;
    
    // create holes
    float s_len = get_slen(p, iTime, 0.5) ;
    vec3 r = (p * PI2) / s_len;
    float ad = max((length(p) - srad)*0.025, 0.);
    float holeGrid = 0.1;
    vec3 q = r - holeGrid*floor((r+0.5*holeGrid)/holeGrid);
    float hf = mix(0., .4*holeGrid, smoothstep(0., 1., ad*30.));
    float f = length(q)- hf;
    
    vec3 gcol = 0.2 + 0.8 * cos(r + vec3(0.1, 0.5, 0.9));
    float lglow = step(f, -0.15*hf)*0.1/(0.1 + f * f);
    
    g_col += lglow * gcol;
    glow += lglow;
    
    //gf.x = mix(gf.x, gf.x + rf, dfx);
    
    //gf.y = float(abs(f) < abs(gf.x));
    gf.x = max(gf.x, -f);
    return vec4(gf, rf);
}

vec4 traceI(in vec3 o, in vec3 d) {
  float t = 0.0;
  float mint = 10.0;

  vec2 res = vec2(mint, 0.);
    
  for (int i=0 ; i < M_ITER ; i++)
  {
    vec3 p = o + t*d;
    
    res = geomI(p, false).xz;
    mint = abs(res.x);
    t += mint;

    if (mint < T_EPS*t || t > FAR) break;
  }
  
   
  return vec4(t, mint, res.y, res.y);
}

vec3 normI(in vec3 p, in bool hres)
{
    vec3 n;
    vec2 e = vec2(N_EPS*10., 0.0);
    
    n.x = geomI(p + e.xyy, hres).x - geomI(p - e.xyy, hres).x;
    n.y = geomI(p + e.yxy, hres).x - geomI(p - e.yxy, hres).x;
    n.z = geomI(p + e.yyx, hres).x - geomI(p - e.yyx, hres).x;
    
    return normalize(n);
}

vec3 normfI(in vec3 p, in bool hres)
{
    vec3 n;
    vec2 e = vec2(N_EPS*10., 0.0);
    
    float f = geomI(p, hres).x;
    n.x = geomI(p + e.xyy, hres).x - f;
    n.y = geomI(p + e.yxy, hres).x - f;
    n.z = geomI(p + e.yyx, hres).x - f;
    
    return normalize(n);
}


vec4 environment(in float t, in vec3 o, in vec3 d) {
    float b = .03 + .01*sin(iTime * .1);
    float alpha = exp(-(t + 5.)*b);
    vec3  light  = vec3(0.1,0.35,0.9);
    
    return vec4(light, 1.-alpha);
}

vec4 triplanar(in vec3 p, in vec3 n, in float scale, in sampler2D s)
{
  //n += 0.7*n + vec3(0.2);
  float sw = n.x + n.y + n.z;
  float wx = n.x/sw;
  float wy = n.y/sw;
  float wz = n.z/sw;
  
  vec4 dx = texture(s, p.yz*scale*n.x);
  vec4 dy = texture(s, p.zx*scale*n.y);
  vec4 dz = texture(s, p.xy*scale*n.z);
  
  return dx * wx + dy *wy + dz * wz;
}

// Fresnel-Shlick
float F(in float _f0, in vec3 _h, in vec3 _v)
{
    float hv = max(dot(_h, _v), 0.);
    float hv1 = pow(1. - hv, 5.);
    return _f0 + (1. - _f0) * hv1;
}

vec4 phase_anim_params(in float _ph_steps, in float _ph_time, 
                       in float _alpha) {
    float phase_time = _ph_time/_ph_steps;
    float light_phase = phase_time * floor(_ph_steps*_alpha)/_ph_steps;
    float phase_in = phase_time * 0.4;
    float phase_hold = phase_time * 0.1;
    float phase_out = phase_time * 0.7;
    
    return vec4(light_phase, phase_in, phase_hold, phase_out);
}

#define AA 1

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    float currRatio = iResolution.y / iResolution.x;
    float ratio = TARGET_RATIO / currRatio;
    vec2 uv = (2.0*fragCoord-iResolution.xy)/(ratio*iResolution.y);
    
    float fov = 0.6 + 0.3*PULSE_T(mod(iTime, 25.), 2., 7., 14.);
    
    vec3 o = getOrigin(0.75*iTime - 1., iChannel1, 1.);
    vec3 target = getOrigin(0.75*iTime - 2., iChannel1, 1.);
    
    vec3 od = normalize(vec3(fov*(2.*(uv-vec2(0.0, -0.5))),-1.));
    vec3 light = normalize(vec3(1., -1., -1.));
    
    mat3 view;
    vec3 d = camera(o, od, target, view);

    vec3 col;
    vec3 bckcol = vec3(0.);
    vec4 ccol = vec4(0.);
    
    float depth = 0.0;
    
    if (abs(uv.y) > 1.0)
    {
        fragColor = vec4(0.);
        return;
    }
    
    srad = 15. + 2.*sin(iTime*0.005 + 2.3);
    
    for (int rw = 0; rw < AA; rw++)
    for (int cl = 0; cl < AA; cl++)
    {
        vec2 off = -0.5 + vec2( float(rw), float(cl) ) / float(AA);
        vec2 tuv = (2.0*(fragCoord + off)-iResolution.xy)/(iResolution.y);
        
        d = normalize(vec3(fov*(2.*(tuv-vec2(0.0, -0.0))),-1.0));
        //rcd.xy += (1./vec2(float(AA*AA)) + vec2(float(row)/float(AA), float(col)/float(AA))) / (iResolution.y);
        d = camera(o, d, 0.75*target, view);
        //ccol += traceCubeCol(o, d, 3);

        float rad = srad;
        vec2 rsph = sphIntersect(o, d, vec3(0.), rad);
        if (rsph.x * rsph.y < 0.)
        {
          vec3 pshp = o + rsph.y * d;
          vec3 nsph = -normalize(pshp);
          vec4 g3res = traceI(pshp, d);
          // hit position to gyroid.
          vec3 totp = pshp + g3res.x * d;
          
          // relative distance from sphere
          float gp_ratio = min((length(totp) - rad) / (0.75*FAR - rad), 1.);
          
          // color sphere
          float rsscl = rsph.y/(rad * 2.);
          vec3 sphCol = vec3(1., rsscl, 0.0);
          vec4 mtl = geomI(pshp + g3res.x * d, true);

          float inside = step(0.1, mtl.y);

          vec3 gcol = mix(vec3(1.), vec3(1., 1., 0.821), step(0.1, mtl.z));

          // differentiate inside/outside
          gcol *= (1. - 0.5*inside);

          depth += g3res.x + rsph.y;
          vec3 n3gyr = normI(totp, true);

          // fake normals for triplanar texturing
          vec3 tn3gyr = normI(totp, false);
          vec3 tcol2 = triplanar(totp, (tn3gyr * tn3gyr), 1. / g3res.x, iChannel3).rgb;
          vec3 tcol = triplanar(totp + length(2.*tcol2), (tn3gyr * tn3gyr), 0.5 / g3res.x, iChannel3).rgb;

          // texture brigthness attenuation.
          gcol *= length(tcol.rrr);
          gcol += tcol2.x * 3. * vec3(1.0, 0.55, 0.185);
          gcol += tcol2.z * 4. * vec3(0.19, 0.58, 1.116);
          gcol *= mix(vec3(1.), vec3(0.95, 0.95, 0.5), g3res.z);
          //gcol += g3res.w * 0.01;

          // bright one of the two gyroids.
          gcol *= (1. + 5.*step(0.1, mtl.z));

          // light direction towards the cube.
          vec3 ldir = normalize(totp);

          vec3 rfl = reflect(d, n3gyr);
          //vec3 dn3gyr = fwidth(n3gyr);
          vec3 h = normalize(ldir - d);
          vec3 spec = vec3(1.)*max(dot(rfl, -ldir), 0.) * 4.*F(0.9, h, -d);

          // spherical distance attenuation
          vec3 ocol = mix(sphCol, gcol, 0.5);
          ocol = mix(ocol, 1. - ocol*ocol, vec3(ccol.a));

          // gyroid distance attenuation
          ocol += 200.*vec3(.96, 0.41, 2.1) * smoothstep(0., g3res.x*g3res.x, 0.25);

          // lighting
          ocol *= (0.25 + max(0.75*dot(n3gyr, -ldir), 0.01)) + spec;
          ocol = mix(2.*ocol*tcol2.y*max(dot(nsph, -d), 0.0), ocol, exp(0.03*(rad - g3res.x)));
          
          
          float t_cycle = mod(iTime, 60.);
          float t_col = mod(iTime, 40.);

          const float phase_steps = 12.;
          
          vec4 aparams = phase_anim_params(phase_steps, 12., gp_ratio);
          
          float t_light = ANIM_T_CF3(t_cycle, 10. + aparams.x, 10. + aparams.z + aparams.x, 51., aparams.y, aparams.w, 2., 1.0, 0.4);
          
          vec3 mp = mod(floor(totp*5.), vec3(4., 4., 4.));
          float block_id = mp.x + mp.y * 4. + mp.z * 16.;
          block_id = hash(block_id);
          
          aparams = phase_anim_params(12., 12., block_id);
          
          // color animation
          vec3 glight = mix(g_col, vec3(5.*glow), ASYM_PULSE_T(t_col, 2., 8., aparams.y + aparams.z + aparams.w, 24. - aparams.x));
          
          vec3 rtotp = totp;
          rtotp.xy = ROT2D(rtotp.xy, rtotp.z);
          mp = mod(floor(rtotp*0.5), vec3(4., 4., 4.));
          block_id = mp.x + mp.y * 4. + mp.z * 16.;
          block_id = hash(block_id);
          
          aparams = phase_anim_params(8., 15., block_id);
          
          // glow/glow + color animation
          glight = mix(glight, vec3(0.), ASYM_PULSE_T(t_cycle, aparams.y, 20.+aparams.x, 2., 49.));
          
          // dark/light mode cycle
          ocol = mix((0.005*glight * g3res.x + 0.01)* ocol,
                     ocol + 0.005*glight * g3res.x, t_light);
          
          // kind of fog
          vec4 fg = environment(g3res.x * (smoothstep(0., 15., g3res.x) - smoothstep(15., 40., g3res.x)), o, d);
          ocol = mix(ocol, fg.rgb, fg.a);

          //ocol = mix(ocol, rocol.rgb * dot(n3gyr, -ldir), 0.7 * clamp(rocol.a, 0., 1.));
          bckcol += ocol;
        }
    }
    
    depth /= float(AA * AA);
    ccol /= float(AA * AA);
    bckcol /= float(AA * AA);
    col = mix(bckcol, ccol.rgb, pow(clamp(1.02*ccol.a, 0., 1.), 2.));
    col = col.bgr;
    col = max(vec3(0.), col);
    //col = mix(col, col.bgr, _ANIMATION(11));
    
    //col = mix(col, tcol.rgb, (step(0.1, ccol.a) - step(0.75, ccol.a)) * 0.5 * smoothstep(1.2, 1.8, length(col - tcol.rgb)) );
    // Output to screen
    fragColor = vec4(col, depth/FAR);
}
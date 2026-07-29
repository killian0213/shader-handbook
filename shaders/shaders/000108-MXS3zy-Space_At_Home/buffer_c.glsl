// Buffer C (buffer) — Space At Home by lz
// https://www.shadertoy.com/view/MXS3zy

/*
    Space at home. 
    Copyright © 2024 Leonid Zaides
    Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the “Software”), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
    The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
    THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.   

    Buffer C - Shadow and AO
             - input: Buffer B - hit objects.
             - output: Shadows from each light source and AO.
*/

int getShadowMap(int _mtl, float _y) {
    int mtl = min(_mtl, LAPTOP_SCREEN_MTL);
    int _trace_flag = (_mtl == TABLE_TOP_MTL && _y > 2.5) ? 
        TRACE_LAPTOP_FLAG : int(TF3(ivec2(mtl/4,GEOM_SHADOW_MAP))[mtl % 4]);
        
    return _trace_flag;
}

int getAoMap(int _mtl) {
    int mtl = min(_mtl, LAPTOP_SCREEN_MTL);
    return int(TF3(ivec2(mtl/4,GEOM_AO_MAP))[mtl % 4]);
}

vec2 trace_sh(in vec3 _o, in vec3 _d, int _trace_flags, const float _fov,
    in sampler2D _ch, const float _iter, const float _far, const float _eps) {
    float t = 0.;
    float mint = 10.;
    vec2 res = vec2(10.);
    float cf = (_fov * 2.) / iResolution.y; // cone tracing
    g_dir = _d;

    for (float fi = 0.; fi < _iter; fi++) {
        vec3 p = _o + _d * t;

        mint = map(p, _trace_flags, _ch, false, false).x;
        
        if (abs(mint) < t * (_eps + cf) || t > _far)
            break;
        if (dot(normalize(p.xz), _d.xz) > 0. 
            && dot(p.xz, p.xz) > GEOM_BOUNDING_CIRCLE_SQR)
            break;
        
        t += mint;
    }
    
    return vec2(t, mint);
}

vec2 calcShadow(in vec3 _p, int i_mtl) {
    vec2 lshadows = vec2(0.);
    for (int il = 0; il < N_LIGHTS; il++) {
        vec4 lgeo = TF3(ivec2(LIGHT_GEO, LIGHT_0 + il));

        vec3 ldir = normalize(lgeo.xyz - _p);
        vec2 sh_ray = trace_sh(_p + ldir*0.001, ldir, getShadowMap(i_mtl, _p.y),
        0.5, iChannel3, MAX_ITER, 0.5*FAR, TS_EPS);
        float sh_cf = mix(isHit(sh_ray, TS_EPS + 0.5), 0.5 * isHit(sh_ray, TS_EPS + 0.5), pow(smoothstep(0., 1., sh_ray.x/75.), 4.));
        lshadows[il] = sh_cf;
    }
    
    return lshadows;
}

//https://www.shadertoy.com/view/4sSfzK
float CalcAO(in vec3 _p, in vec3 _n, in int _mtl) {
    float v0 = 0.276;
    float v1 = 0.133;
    float v2 = 0.179;
    float v3 = 0.080;
    float v4 = 0.772;
    
    float ao = 0.0;
	float s = 1.0;
    #define ZERO float(min(iFrame,0)) // non-constant zero
	for (float i = ZERO; i < 5.; ++i)
	{
		float off = v0 + v1 * i / 6.;
		float t = map(_n * off + _p, getAoMap(_mtl), iChannel3, 
        false, false).x;
		ao += (off - t) * s;
		s *= v2;
	}
    
    ao = mix(1., smoothstep(0., 1., 1. - v3 * 20. * ao), v4);
    return ao;
}

bool computeHitParamsFromRaycast(in vec4 _raycast, in vec2 _uv,
    out vec3 _p, out vec3 _d, out vec3 _n, out int _mtl) {
    float half_pixel = 1./iResolution.y;
    
    CAMERA_SETUP(_uv)
    _d = d;
    
    float iter = MAX_SH_ITER;
    float far = FAR;
    bool hitGeom = _raycast.x > T_EPS;
    
    if (hitGeom) {
        _mtl = int(map(o + _raycast.x * d, TRACE_NO_FLOOR, 
            iChannel3, false, true).y);
            _n = normalize(_raycast.yzw);
            _p = o + _raycast.x * d;
    }
    
    float tfloor = rayXFloor(o.y, d.y);
    if (tfloor > 0. && !hitGeom && tfloor < FAR) {
        _mtl = FLOOR_MTL;
        _n = vec3(0., 1., 0.);
        _p = o + tfloor * d;
        hitGeom = true;
    }
    
    return hitGeom;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = (2.*fragCoord - iResolution.xy)/(iResolution.y);
    vec2 muv = (2.*iMouse.xy - iResolution.xy)/(iResolution.y);
    vec2 ruv = fragCoord/iResolution.xy;
    float scr_resolution = iResolution.x / iResolution.y;

    vec3 n, p, d;
    vec4 raycast = texture(iChannel0, ruv);
    int i_mtl = TRACE_NO_FLAG;
    vec2 shadow; // entry for each light
    float ao = 1.; // ambient occlusion
    bool hitGeom = false;
    
#ifdef DOWNSAMPLE_SHADOWS
    vec2 quad_ruv = ruv * 2.;
    vec2 quad_uv;
    if (quad_ruv.x < 1. && quad_ruv.y < 1.) { // lower left quadrant
        vec4 q_raycast = texture(iChannel0, quad_ruv);
        quad_ruv.x *= scr_resolution;
        quad_uv = quad_ruv * 2. - vec2(scr_resolution, 1.);
        hitGeom = computeHitParamsFromRaycast(q_raycast, quad_uv,
            p, d, n, i_mtl);
    }
#else
    hitGeom = computeHitParamsFromRaycast(raycast, uv,
        p, d, n, i_mtl);
#endif
           
    if (hitGeom && dot(p.xz, p.xz) < FLOOR_BOUNDING_CIRCLE_SQR) {
        shadow = calcShadow(p, i_mtl);
        ao = (i_mtl == FLOOR_MTL) ? 1. : CalcAO(p, n, i_mtl);
    }
    
#ifdef PACK_CUI_VALUES
    // Packing is done to reduce compilation time by saving more work
    // on Buffer D and freeing the Image buffer.
    
    // packing closed unit interval to uint. Because we 
    // eventually pass the packed values as floats and precision is
    // on the lower end, shadow passed first. The shadow values are packed
    // to 255 bit values and ambient occlusion to 127 bit.
    PACK_CUI3_TO_UINT(shadow.x, shadow.y, ao);
    vec4 clr = vec4(float(packed_uint), vec3(0.));
#else
    vec4 clr = vec4(ao, shadow.xy, 0.);
#endif
    
    fragColor = clr;
}
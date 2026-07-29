// Buffer D (buffer) — Space At Home by lz
// https://www.shadertoy.com/view/MXS3zy

/*
    Space at home. 
    Copyright © 2024 Leonid Zaides
    Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the “Software”), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
    The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
    THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.   

    Buffer D - Reflection rays
             - input: Buffer B (hit objects).
             - output: trace t and normal.
             
    Buffer C here is a pass through buffer and only here because
    we can't bind more than 4 buffers for the final image.
*/

float getReflectionHit(in vec3 _p, in vec3 _d, in vec3 _n, in int _mtl, 
    in float _scr_res, out float _rfl_mtl) {

    vec3 rfl_dir = normalize(reflect(_d, _n));
    int rfl_trace_flag = TRACE_NO_FLAG;
    
    float rfar = 12.;
    if (_mtl == FLOOR_MTL) {
        rfar = 40.;
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
    
    //
    const float TR_EPS = T_EPS * 10.;
    rfar = min(rfar / max(dot(rfl_dir, _n), 0.001), FAR);
    vec2 rfl_trace = trace(_p + TR_EPS * rfl_dir,
                    rfl_dir, rfl_trace_flag, iChannel3,
                    64., rfar, TR_EPS);
                    
    float trace_t = 0.;
    _rfl_mtl = float(DEFAULT_MTL);
    
    if (bool(isHit(rfl_trace, TR_EPS))) {
         trace_t = rfl_trace.x;
         vec3 rp = _p + (trace_t + T_EPS) * rfl_dir;
         _rfl_mtl = (map(rp, rfl_trace_flag, iChannel3, false, true).y);
    }
    
    return trace_t;
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
    vec2 ruv = fragCoord/iResolution.xy;
    float scr_resolution = iResolution.x / iResolution.y;

    vec3 n, p, d;
    vec4 raycast = texture(iChannel0, ruv);
    vec4 sec_cast = TF1(ivec2(fragCoord)); // pass through
    int i_mtl = TRACE_NO_FLAG;
    float rfl_trace_t = 0.;
    bool hitGeom = false;
    float rfl_mtl;
    
    hitGeom = computeHitParamsFromRaycast(raycast, uv,
        p, d, n, i_mtl);

    if (hitGeom && dot(p.xz, p.xz) < FLOOR_BOUNDING_CIRCLE_SQR) {
        rfl_trace_t = getReflectionHit(p, d, n, i_mtl, scr_resolution, rfl_mtl);
    }

#ifdef PACK_CUI_VALUES
    vec4 clr = vec4(sec_cast.x, float(i_mtl), rfl_mtl, rfl_trace_t);
#else
    vec4 clr = vec4(sec_cast.xyz, rfl_trace_t);
#endif

    fragColor = clr;
}
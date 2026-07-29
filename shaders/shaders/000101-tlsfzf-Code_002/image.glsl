// Image (image) — Code:002 by Pidhorskyi
// https://www.shadertoy.com/view/tlsfzf

vec4 render(float d, vec3 color, float w)
{
    float anti = fwidth(d) * w;
    return vec4(color, smoothstep(anti, -anti, d));
}

vec4 render(float d, vec4 color)
{
    float anti = fwidth(d) * 1.0;
    return vec4(color.rgb, color.a * smoothstep(anti, -anti, d));
}

vec4 render_stroked(float d, vec3 color, float stroke)
{
    float anti = fwidth(d) * 1.0;
    vec4 strokeLayer = vec4(vec3(0.01), smoothstep(anti, -anti, d - stroke));
    vec4 colorLayer = vec4(color, smoothstep(anti, -anti, d));
    return vec4(mix(strokeLayer.rgb, colorLayer.rgb, colorLayer.a), strokeLayer.a);
}

vec4 render_stroked_masked(float d, vec3 color, float stroke, float stroke_mask)
{
    float anti = fwidth(d) * 1.0;
    vec4 strokeLayer = vec4(vec3(0.01), smoothstep(anti, -anti, d));
    float se = smoothstep(anti, -anti, stroke_mask);
    vec4 colorLayer = vec4(color, smoothstep(anti, -anti, d + stroke));
    return vec4(mix(mix(strokeLayer.rgb, colorLayer.rgb,  se), colorLayer.rgb, colorLayer.a), strokeLayer.a);
}

void render_layer(inout vec4 c, vec4 layer)
{ 
    c.rgb = mix(c.rgb, layer.rgb, layer.a);
}

void render_layer_mul(inout vec4 c, vec4 layer)
{ 
    c.rgb = mix(c.rgb, c.rgb * layer.rgb, layer.a);
}

float exact_intersection(float d1, float d2)
{
    float dmin = min(d1, d2);
    float dmax = max(d1, d2);
    return dmin < 0. ? dmax : dmin;
}

vec4 sdEye(vec2 p)
{
    p += vec2(0.52, -0.15);
    vec2 plt = vec2(-0.035, -0.045); vec2 pmt = vec2(0.56, 0.31); vec2 prt = vec2(0.862, 0.0421);
    vec2 plm = vec2(0.039, -0.3);                                vec2 prm = vec2(0.87, -0.088);
    vec2 plb = vec2(0.31, -0.35); vec2 pmb = vec2(0.55, -0.35); vec2 prb = vec2(0.84, -0.25);
    
    float d1 = sdBezier(prt, pmt, plt, p);
    float d2 = sdBezier(plt, plm, plb, p);
    float d3 = sdBezier(plb, pmb, prb, p);
    float d4 = sdBezier(prb, prm, prt, p);
    
    float d14 = exact_intersection(d1, d4);
    float d23 = exact_intersection(d2, d3);
    float dd = exact_intersection(d23, d14);
    return vec4(dd, d1, d23, d2);
}


float sdPupil(vec2 p, float r, vec2 offset)
{
    return sdEllipse(vec2(0.2, 0.3) * r, p - offset);
}

float pow2(float x) { return x * x; }

vec4 sdHair(vec2 p)
{
    float def1 = p.y + 1.5;
    float def2 = p.y + 0.3;
    
    p.x += pow2(3.8 * max(0.1 - def1 * def1 * 0.15, 0.)) * sign(p.x) * smoothstep(0.40, 0.43, abs(p.x));
    p.x -= pow2(2.5 * max(0.1 - def1 * def1 * 0.15, 0.)) * float(p.x < 0.);
    p.x += pow2(1.5 * max(0.1 - def2 * def2 * 0.35, 0.)) * float(p.x < -0.46);
    
	float d = sdUnevenCapsuleY( p, 0.73, 0.51, 2.1 );
    
    float dcut = 0.16 -p.y - p.x * 0.05;
    float dsub = abs(p.x) - 0.41;
    dsub = max(dsub, -dcut);
    float d3 = max(d, -dsub);
    return vec4(d3, d, dcut, dsub);
}

const float f[]   = float[](0.4, 0.23, 0.1, 0.05);
const float off[] = float[](-0.4, 0.1, 0.5, 0.5);
const float amp[] = float[](8.0, 12.4, 22.4, 32.4);
const float bias[] = float[](0.4, 0.2, 0.2, 0.2);
const int n = 4;
vec4 sdHairBands(vec2 p)   
{	
    vec4 dh = sdHair(p);
    float d = dh.x;
    float dcut = 0.16 -p.y - p.x * 0.05;
    
    p += 0.2 * sin(p.x / 0.4) * (1.0-cos((p.y + 0.15) / 0.4));
    
    float db = -(0.2 - abs(dcut));
    float dmod = -0.2;
    float b1 = 0.0;
    
    for (int i = 0; i< n; ++i)
    {
    	b1 = -amp[i] * (max(mod(p.x + off[i], f[i]), f[i] / 2. ) -5./4.*f[i] + max(mod(-p.x - off[i], f[i]), f[i]/2. ));
    	b1 = -pow(max(b1, 0.0), 2.5) + bias[i];
    	dmod = max(dmod, -b1);
    }

    float k = 4.0;
    dmod = tanh(k * dmod) / k;
    db += dmod;
    
    db += 0.1 * max(1.0 - 5.0 * p.x * p.x, 0.) - 0.1;
    db *= 0.5;
    db = max(db, dh.y);
    
    d = min(db, max(d, -0.1));
        
    return vec4(d, dh.y, dh.z, dh.w);
}
 
#define LayerF(d, color) render_layer(fragColor, render(d, color, 1.))
#define LayerFM(d, color) render_layer_mul(fragColor, render(d, color, 1.))
#define LayerFMW(d, color, w) render_layer_mul(fragColor, render(d, color, w))
#define LayerS(d, color, stroke) render_layer(fragColor, render_stroked(d, color, stroke))
#define LayerSM(d, color, stroke, mask) render_layer(fragColor, render_stroked_masked(d, color, stroke, mask))

struct Params
{
    float size;
    float pixSize;
    float yaw;
    float lj;
    float wj;
    float wc;
    float th;
    float trh;
    float radius;
    float m;
    float stroke;
};

float make_head(inout vec4 fragColor, Params p, vec2 uv)
{
    float a = sdfTriangleDist(p.wj, p.th, (uv + vec2(0.0, p.lj)));
    float b = sdTrapezoid(p.wj, p.wc, p.trh, (uv + vec2(0.0, p.lj - p.th - p.trh)));
    float c = sdfCircle(p.wc * 1.005, uv - vec2(0.0, p.m));
    c = sdfIntersection(c, -uv.y + p.m);

    float e = sdEgg(p.wc * 1.005, 0.04, (uv - vec2(0.0, p.m))  * vec2(1.0, -1.0)) ;
    
    float d = 1e6;
    d = sdfUnion(a, b);
    d = sdfUnion(d, c);
    d = mix(d, e, 0.4 * smoothstep(0.1, p.wj, abs(uv.x)));
    
    d -= p.radius;
    d += disp(uv, 20.0) * 0.001;  
    
    LayerS(d, vec3(0.757, 0.772, 0.796), p.stroke);
    return d;
}


void make_hair_back(inout vec4 fragColor, Params p, vec2 uv)
{
    uv = rotate(uv, -0.09);
    uv += vec2(0.02, -0.31);
    uv *= 1.35;
    float d = sdHair(uv * vec2(1.2, 1.0) + vec2(0.01, 0.12)).y;

    LayerF(d, vec3(0.54, 0.37, 0.46));
}
  
void make_hair_shadow(inout vec4 fragColor, Params p, vec2 uv)
{
    uv = rotate(uv, -0.09);
    uv += vec2(0.02, -0.31);
    uv *= 1.35;
    float ds = sdHairBands(uv * vec2(1.02, 1.0) + vec2(-0.03, 0.05)).x;
    LayerFMW(ds, vec3(0.752, 0.66, 0.69) * 0.9, 3.0);
}

void make_hair(inout vec4 fragColor, Params p, vec2 uv)
{
    uv = rotate(uv, -0.09);
    uv += vec2(0.02, -0.31);
    uv *= 1.35;
    float def = max(-uv.x + 0.6 * uv.y - 0.45, 0.) * 2.0;
    uv.x -= def * def;
    float d = sdHairBands(uv).x;

    d += disp(uv, 2.0) * 0.005;  
    d += disp(uv, 20.0) * 0.001;  

    LayerS(d, vec3(0.75, 0.67, 0.76), p.stroke * 1.5);
    LayerF(d + 0.18, vec3(0.75, 0.84, 0.87));
}

void _make_hair2(inout vec4 fragColor, Params p, vec2 uv, float l)
{
    uv *= 1.35;
    float def1 = uv.y + 1.5;
    uv.x -= pow(2.5 * max(0.1 - def1 * def1 * 0.15, 0.), 2.0) * (1.0 - 0.6 * l);
    uv /= 1.35;
    float d = abs(0.33 - 0.02 * l + uv.x) - 0.03 * (1.0 + 0.5 * (1. - l ) + uv.y * (0.4 + 0.3 * (1.-l)));
    
    d = max(d, uv.y);
    
    float m = -(uv.y - 0.14 + l * 0.07 - uv.x * 0.6);
    
    m = mix(m, min(m, (uv.x + 0.33 - 0.02 * l)), uv.y < -0.75);

    d += disp(uv, 2.0) * 0.005;  
    d += disp(uv, 20.0) * 0.001;  

    LayerSM(d, vec3(0.75, 0.67, 0.76), p.stroke * 0.5, m);
}

void make_hair2(inout vec4 fragColor, Params p, vec2 uv)
{
    float l = float(uv.x > 0.);
    uv += vec2(0.045, -0.31);
    uv = rotate(uv, -0.12 + 0.025 * l);
    uv.x = -abs(uv.x);
    // uv = mix(uv, uv * vec2(1.03, 0.99) - vec2(0.03, -0.005), l);
    _make_hair2(fragColor, p, uv, l);
}

void make_band_and_horns(inout vec4 fragColor, Params p, vec2 uv)
{
    uv = rotate(uv, 0.06);
    uv += vec2(0.05, -0.30);
	float d = sdUnevenCapsuleY(uv, 0.73, 0.32, 2.1 );
    uv += vec2(-0.0, 0.09);
	float d2 = sdUnevenCapsuleY(uv, 1.0, 0.335, 2.1 );
    d = max(d, -d2);
    
    float r = float(uv.x > 0.);
    float ir = 1.0 - r;
    uv.x = -abs(uv.x);

    float a = sdfTriangleDist(0.05, 0.08 - 0.03 * r, rotate( uv + vec2(0.24, -0.16 - 0.038 * r), -0.4));
    a = max(a, -uv.x + uv.y - 0.5);
    d = min(d, a);

    LayerS(d, vec3(0.72, 0.79, 0.88), p.stroke);
    
    vec2 p0 = vec2(-0.010, 0.07 - 0.02 * ir);
	float c = max(uv.y - 0.36, 0.) * (r * 0.5 + 0.5);
    uv -= vec2(c * c * 1.25, 0.0);
    float dh = sdTriangle(p0, p0 + vec2(-0.05 - 0.01 * ir, 0.3), p0 + vec2(0.03 * r, 0.13), uv + vec2(0.24, -0.16));
    // dh = max(dh, -uv.x + uv.y - 0.5);
    dh -= 0.005;

    float dhs = max(dh, uv.x + uv.y * 0.5 + 0.07);
    float dhh = max(dh, uv.x + uv.y * 0.18 + 0.195 + 0.012 * ir) + 0.004;
    
    LayerS(dh, vec3(0.52, 0.24, 0.34), p.stroke);
    LayerF(dhs, vec3(0.28, 0.17, 0.27));
    LayerF(dhh, vec3(0.69, 0.62, 0.72));
}

void make_neck(inout vec4 fragColor, Params p, vec2 uv)
{
    uv += vec2(0.0, p.lj);
    uv += vec2(0.007, 0.1);
    uv *= 2.6;

    vec2 plt = vec2(-0.5,  0.34); vec2 prt = vec2(0.5,  0.34);
    vec2 plm = vec2(-0.4, -0.0);  vec2 prm = vec2(0.4, -0.1);
    vec2 plb = vec2(-0.45, -0.35); vec2 prb = vec2(0.52, -0.2);
    
    float d2 = sdBezier(plt, plm, plb, uv);
    float d4 = sdBezier(prb, prm, prt, uv);
    
    float d24 = exact_intersection(d2, d4);
    float d_caps = max(uv.y - 0.35, -0.34 - uv.y);
    float dd = max(d24, d_caps);
    
    LayerS(dd, vec3(0.54, 0.46, 0.46), p.stroke * 2.6);
}

void make_mouth(inout vec4 fragColor, Params p, vec2 uv)
{
    float mm = sdEllipse(vec2(p.wj * 0.55, p.th * 0.13), opCheapBend(uv + p.yaw * vec2(0.005, 0.), 2.0) + vec2(0.0, p.lj - p.th - 0.01));
    float mme = sdfCircle(0.02, uv + p.yaw * vec2(0.005, 0.) + vec2(-0.03, p.lj - p.th + 0.01));
    mm += disp(uv, 20.0) * 0.002; 
    LayerSM(mm, vec3(0.70, 0.58, 0.6),  p.stroke * (1. + 2. * smoothstep(p.wj * 0.1, p.wj * 0.4, uv.x)), mme);
}

void make_nose(inout vec4 fragColor, Params p, vec2 uv)
{
    uv.x -= 0.005;
    float nn1 = udBezier(vec2(0.01, p.m - p.th * 1.48), vec2(0.008, p.m - p.th * 1.38), vec2(0.017, p.m - p.th * 1.08), uv);
    float nn2 = udBezier(vec2(0.007, p.m - p.th * 0.62), vec2(0.007, p.m - p.th * 0.75), vec2(0.017, p.m - p.th * 0.87), uv);
    float nn3 = udBezier(vec2(0.01, p.m - p.th * 0.2), vec2(0.017, p.m + p.th * 0.1), vec2(0.04, p.m + p.th * 0.3), uv);
    nn1 = min(nn1, nn2);
    nn1 = min(nn1, nn3);
    
    vec2 p0 = vec2(0.001, p.m - p.th * 0.62);
	float c = max(uv.y - 0.36, 0.);
    float def = dot(vec2(p.th * 0.25, 0.01), p0 - uv) - 0.0003;
    def *= 1200.0;
    def = max(1.0 - def * def, 0.);
    uv.y -= def * 0.015;
    float dh = sdTriangle(p0, p0 + vec2(-0.021, -p.th * 0.4), p0 + vec2(0.01, -p.th * 0.25), uv);

    dh -= 0.008;

    LayerFMW(dh, vec3(0.752, 0.66, 0.69), 1.5);
    LayerS(nn1, vec3(0.), p.pixSize * 0.6);
}

void make_eye(inout vec4 fragColor, Params p, vec2 uv, float l)
{
    uv.x += p.wc * 0.8;
    uv.y -= p.m;
    uv += vec2(-0.05, 0.06);
    uv *= 5.2;
    vec4 d = sdEye(uv);
    LayerF(d.x, vec3(0.73, 0.78, 0.83));
    float w = (1.0 - (uv.x * uv.x / 0.5)) * 1.3;
    LayerS(abs(d.y - 0.03 * w), vec3(0.08, 0.14, 0.18),  0.04 * w);
    
    float dh = max(d.w - 0.13 * (1.45 + 3.2 * uv.y), -d.w);
    dh = max(dh, uv.y - uv.x * 0.9 - 0.65);
    dh = max(dh, -uv.y + uv.x * 0.44 + 0.0);
    LayerF(dh, vec3(0.59, 0.31, 0.44));
    
    float m = uv.y + 0.08;
    LayerF(max(abs(d.z)- 0.015, m), vec3(0.08, 0.14, 0.18));
    
    float p1 = sdPupil(uv, 1.0, vec2(-0.05, 0.) * l);
    float p2 = sdPupil(uv, 0.52, vec2(-0.05, 0.) * l + vec2(0.03, 0.) * (l - 0.5) + vec2(0.0, 0.03));
    float p3 = sdPupil(uv, 0.15, vec2(-0.05, 0.) * l + vec2(0.05, 0.) * (l - 0.5) + vec2(0.0, 0.03));
    float s1 = sdPupil(uv, 0.3, vec2(-0.05, 0.) * l + vec2(0.36, 0.) * (l - 0.5));
    
    LayerS(max(p1, d.x), vec3(0.26, 0.45, 0.45),  p.stroke * 5.2);
    LayerS(max(p2, d.x), vec3(0.26, 0.45, 0.45),  p.stroke * 5.2);
    LayerS(max(p3, d.x), vec3(0.08, 0.14, 0.18),  p.stroke * 5.2);
    LayerF(max(s1, d.x), vec3(0.75, 0.84, 0.87));
    {
    	vec2 _uv = uv + vec2(0.4, -0.38) + vec2(0.15, 0.02) * l - 0.1 * uv.x * l;
    	vec2 plt = vec2(0.1, 0.04); vec2 pmt = vec2(0.5, 0.2); vec2 prt = vec2(0.88, 0.05);
    	float du = udBezier(prt, pmt, plt, _uv);
    	LayerS(du, vec3(0.),  p.stroke * 3.);
    }
}

void make_eyebrow(inout vec4 fragColor, Params p, vec2 uv, float l)
{
    uv.x += p.wc * 0.8;
    uv.y -= p.m;
    uv += vec2(-0.05, 0.06);
    uv *= 5.2;

  	vec2 _uv = uv + vec2(0.4, -0.60) + vec2(0.15, 0.02) * l - 0.1 * uv.x * l;
   	vec2 plt = vec2(-0.01, -0.05); vec2 pmt = vec2(0.5, 0.02); vec2 prt = vec2(0.98, 0.18);
   	float du = udBezier(prt, pmt, plt, _uv) - 1.0 * min(dot3(_uv - vec2(-0.01, -0.05)) * dot2(_uv - vec2(0.98, 0.18)), 0.1);
   	LayerS(du, vec3(0.75, 0.67, 0.76),  p.stroke * 3.);
}

void make_eyes(inout vec4 fragColor, Params p, vec2 uv)
{
    float l = float(uv.x > 0.);
    uv.x = -abs(uv.x);
    uv = mix(uv, uv * vec2(1.03, 0.99) - vec2(0.03, -0.005), l);
    make_eye(fragColor, p, uv, l);
}

void make_eyebrows(inout vec4 fragColor, Params p, vec2 uv)
{
    float l = float(uv.x > 0.);
    uv.x = -abs(uv.x);
    uv = mix(uv, uv * vec2(1.03, 0.99) - vec2(0.03, -0.005), l);
    make_eyebrow(fragColor, p, uv, l);
}

void make_ear(inout vec4 fragColor, Params p, vec2 uv, float l, float headd)
{
    uv += vec2(0.38, 0.065) + vec2(-0.075, 0.02) *l;
    uv = rotate(uv, -0.4);
    float def1 = uv.x - uv.y + 0.0;
    float def2 = uv.x + uv.y * 0.7 - 0.05;
    float def3 = uv.x - uv.y + 0.0;
    uv.x -= max(0.02 - def1 * def1, 0.);
    uv.x -= pow(max(0.1 - def2 * def2 * 20.0, 0.), 2.);
    float d = sdEllipse(vec2(0.05, 0.11), uv);
    d = max(d, -headd + p.stroke);
    LayerS(d, vec3(0.757, 0.772, 0.796), p.stroke);
    vec2 uv2 = rotate(uv, -0.2);
    uv2 += vec2(0.005, 0.026);
    float d2 = sdEllipse(vec2(0.024, 0.045), uv2);
    d2 = max(d2, -headd + p.stroke);
    LayerS(d2, vec3(0.49, 0.46, 0.51), p.stroke);
    {
    	vec2 _uv = uv;
    	vec2 plt = vec2(-0.015, 0.085); vec2 pmt = vec2(-0.0, 0.085); vec2 prt = vec2(0.005, 0.035);
    	float du = udBezier(prt, pmt, plt, _uv);
    	LayerS(du, vec3(0.),  p.stroke * 0.5);
    }
}

void make_ears(inout vec4 fragColor, Params p, vec2 uv, float headd)
{
    float l = float(uv.x > 0.);
    uv.x = -abs(uv.x);
    make_ear(fragColor, p, uv, l, headd);
}

void make_body_shadow(inout vec4 fragColor, Params p, vec2 uv)
{
    uv += vec2(-0.045, 0.46);
    uv = rotate(uv, -0.05);
    uv += vec2(-0.01, 0.1);
    float def = uv.y + uv.x * 0.2 - 0.06;
    uv.y += pow(max(def, 0.), 2.) * 12.0;
	float d2 = sdUnevenCapsuleY(uv, 0.5, 0.26, 0.9 ) - 0.04;
    LayerS(d2 + 0.01, vec3(0.31, 0.15, 0.16), p.stroke);
}

void make_body(inout vec4 fragColor, Params p, vec2 uv)
{
    uv += vec2(-0.045, 0.46);
    uv = rotate(uv, -0.05);
    float d = sdTrapezoid(0.14, 0.36, 0.11, uv) - 0.04;
    
    uv += vec2(-0.01, 0.1);
    
	float dw = sdTrapezoid(0.18, 0.30, 0.11, uv) - 0.04;
    float _dw = dw;
    vec2 _uv = uv;
    
    float def = uv.y + uv.x * 0.2 - 0.06;
    uv.y += pow(max(def, 0.), 2.) * 12.0;
    uv.y += 0.25 - pow(abs(uv.x) * 1.2, 1.4);
	float d2 = sdUnevenCapsuleY(uv, 0.5, 0.26, 0.9 ) - 0.04;
    
    uv = _uv;
    def = uv.y + (uv.x - 0.1) * 0.2 - 0.06;
    uv.y += (min(max(uv.y + 0.7, 0.), 0.8) + 0.2) * (0.26 - min(pow(abs(uv.x + uv.y * 0.2 - 0.03) * 1.2, 1.4), 0.26)) * 1.2;
    
	float d22 = sdUnevenCapsuleY(uv, 0.5, 0.26, 0.9 ) - 0.04;
    float dd = max(d, d2);
    dw = max(dw, d2);
    dw = max(dw, -d);
    float _dw_ = dw;
    dw = max(dw, -min(abs(_uv.x + _uv.y * 0.1 + 0.03) -0.02, 0.1));
    
    uv = rotate(_uv, 0.03);
    float def2 = pow(max(-uv.y + uv.x * 0.075 + 0.06, 0.), 3.1);
    float k = 1.5;
    def2 = (1. / (1. + exp(k * def2* 470.0)) - 0.5) / k;
    uv.x += sign(uv.x) * def2;//min(pow(max(def2, 0.), 2.) * 10.0, 0.23);
    uv.x += def2 *0.25;
	float d3 = sdUnevenCapsuleY(uv, 0.5, 0.26, 0.9 ) - 0.04;
    d3 = min(d3, d2);
    d3 = max(d3, -d);
    d3 = max(d3, uv.y - 0.05);
    
    float d33 = max(d3, abs(_uv.x - 0.04) - _uv.y * (0.3 + 4.*max(uv.x, 0.))  - 0.55);
    
    LayerSM(d2, vec3(0.31, 0.15, 0.16), p.stroke * 2.0, -abs(_uv.x + 0.03) + 0.22);
    LayerF(d22, vec3(0.48, 0.2, 0.21));
    LayerS(d3, vec3(0.70, 0.77, 0.87) * 0.9, p.stroke);
    LayerS(d33, vec3(0.70, 0.77, 0.87) * 0.7, p.stroke);
    LayerS(_dw_ + 0.005, vec3(0.70, 0.77, 0.87), p.stroke);
    LayerS(dw, vec3(0.70, 0.77, 0.87), p.stroke);
}

void make_background(inout vec4 c, vec2 uv)
{
    float R = 0.6;
	vec2 grid;
    float uv_ys = uv.x / (1.5*R);
    grid.y = fract(uv_ys);
    float odd = mod(floor(uv_ys), 2.0);
    grid.x = fract(uv.y / (SQRT3 * R) - odd*.5) - 0.5;
    float d =  abs(grid.x);
    d = mix(1e3, d, grid.y > 1./3.);
    grid.x = abs(grid.x); 
    float dd1 = abs(dot(grid - vec2(0, 1./3.), normalize(vec2(1./ 3., 0.5))));
    grid.y = 1.0 - grid.y + 1. + 1./3.; 
    float dd2 = abs(dot(grid - vec2(0, 4./3.), normalize(vec2(1./ 3., 0.5))));
    d = min(dd1, d);
    d = min(dd2, d);
        
    float anti = fwidth(d) * 1.0;
    float sig = 0.00005;
    float hex = 1. - exp(-d*d * 0.5 / sig) * 0.3;//smoothstep(-anti, anti, d - stroke);
    vec3 bcol = vec3(0.3,0.4, 0.57) * (0.8 + 0.2*uv.y) *(1.1-0.1*length(uv));
    
    c = vec4(bcol * (hex * 0.5 + 0.5), 1.0); 
}

void mainImage(out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = (fragCoord-0.5*iResolution.xy)/iResolution.y * 2.0;
    uv /= 1.4;
    uv += vec2(0.3, 0.0);
    
    Params p;
	p.size = min(iResolution.x, iResolution.y);
    p.pixSize = 1.0 / p.size;
    p.yaw = 1.;
    p.lj = 0.3;
    p.wj = 0.21;
    p.wc = 0.29;
    p.th = 0.12;
    p.trh = 0.15;
    p.radius = 0.08;
    p.stroke = p.pixSize * 1.5 + disp(uv, 40.0) * 0.001;
    p.m = -p.lj + p.th + p.trh * 2. + p.radius / 2.0;
    
    make_background(fragColor, uv - vec2(0., 0.5));
    
    uv = rotate(uv, 0.13);
    vec2 uv_nw = uv;
    uv_nw.x -= 0.09 * p.yaw;
    uv.x -= 0.1 * p.yaw * (cos(uv.x / 0.35)) * (cos(max(uv.y - p.m, 0.0) / 0.35));
    
    make_hair_back(fragColor, p, uv_nw);
    make_body_shadow(fragColor, p, uv);
    make_neck(fragColor, p, uv);
    make_body(fragColor, p, uv);
    float headd = make_head(fragColor, p, uv);
    float d = disp(uv, 30.0) * 0.0015 * float(int(iTime * 12.0) % 2 == 0);
    make_mouth(fragColor, p, uv + d);
    make_nose(fragColor, p, uv_nw);
    make_eyebrows(fragColor, p, uv_nw + d);
    make_hair_shadow(fragColor, p, uv_nw);
    float olds = p.stroke;
    p.stroke = p.pixSize * 1.5 + d;
    make_eyes(fragColor, p, uv_nw + d);
    p.stroke = olds;
    make_hair(fragColor, p, uv_nw);
    make_ears(fragColor, p, uv_nw, headd);
    make_hair2(fragColor, p, uv_nw);
    make_band_and_horns(fragColor, p, uv_nw);
    float n = noise(uv_nw * 200.0);
    fragColor += n * 0.04;
}

// Image (image) — TheGrid by dila
// https://www.shadertoy.com/view/llcXWr

vec3 col1 = vec3(0.118, 0.365, 0.467);
vec3 col2 = vec3(0.514, 0.851, 0.933);
vec3 col3 = vec3(0.957, 0.875, 0.29);
vec3 col4 = vec3(0.973, 0.663, 0.106);
vec3 col5 = vec3(0.843, 0.431, 0.176);
vec3 col6 = vec3(0.361, 0.251, 0.145);

mat2 rot(float x)
{
    return mat2(cos(x), sin(x), -sin(x), cos(x));
}

float sdBox( vec3 p, vec3 b )
{
  vec3 d = abs(p) - b;
  return min(max(d.x,max(d.y,d.z)),0.0) + length(max(d,0.0));
}

vec3 tex(vec3 p, float pz)
{
    vec2 q = p.xy;
    float fp = 10.0;
    q = (fract(q / fp) - 0.5) * fp;
    float d = 1000.0;
    float mid = 0.0;
    vec2 mpos = vec2(0.0);
    const int n = 3;
    for (int i = 0; i < n; ++i) {
        for (int j = 0; j < 2; ++j) {
        	q = abs(q) - 0.5;
        	q *= rot(3.141592 * 0.25);
        }
        q = abs(q) - 0.25;
        q *= rot(pz * 0.5);
        q.x += sin(pz);
        float k = sdBox(vec3(q, 0.0), vec3(1.0, 0.5, 1.0));
        if (k < d) {
			d = k;
            mpos = q;
            mid = float(i);
        }
    }
    d = max(d, -sdBox(p, vec3(1.0, 2.0, 1.0)));
    float f = 1.0 / (1.0 + d * d * 1000.0);
    float dl = pz * 0.7 + mid * 0.6 + mpos.x * 0.5;
    dl = sin(dl + iTime) * 0.5 + 0.5;
	vec3 col = mix(vec3(0.0), col2, dl);
    vec3 tex = texture(iChannel0, mpos.xy).xyz;
    tex *= tex;
    float tf = sin(mid + iTime) * 0.5 + 0.5;
    tex = mix(vec3(0.0), tex, tf);
    float lt = max(sign(-d), 0.0);
    return mix(tex * lt * col1, col * 4.0, f);
}

vec3 _texture(vec3 p, float pz)
{
    vec3 ta = tex(p.xyz, pz).xyz;
    vec3 tb = tex(p.xzy, pz).xyz;
    vec3 tc = tex(p.yzx, pz).xyz;
    return (ta + tb + tc) / 3.0;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
	vec2 uv = fragCoord.xy / iResolution.xy;
    uv = uv * 2.0 - 1.0;
    uv.x *= iResolution.x / iResolution.y;
    
    vec3 o = vec3(0.0, 0.0, iTime * 4.0);
    vec3 r = normalize(vec3(uv, 1.3 - dot(uv, uv) * 0.33));
    
	float t = fract(iTime * 0.1) * 4.0;
    vec4 ct = vec4(t, t - 1.0, t - 2.0, t - 3.0);
    ct = clamp(ct, 0.0, 1.0);
    ct = pow(ct, vec4(8.0));
	ct = 1.0 - pow(1.0 - ct, vec4(64.0));
    ct *= 3.14159 * 0.5;
    r.xy *= rot(ct.x + ct.y + ct.z + ct.w);
    
    vec3 fc = vec3(0.0);
    
    const int n = 8;
    for (int i = 0; i < n; ++i) {
        float fi = float(i) / float(n);
        float sr = 1.5;
        vec3 sp = o;
        sp.z = floor(sp.z / sr + 1.0 + float(i)) * sr;
        float t = 0.0;
        for (int i = 0; i < 15; ++i) {
            vec3 p = o + r * t - sp;
            float ws = sin(p.z * 0.125) * 0.5 + 0.5;
            float c = mix(2.0, 6.0, ws) - abs(p.x);
            t += min(-p.z, c);
        }
        vec3 w = o + r * t - sp;
        float back = sr * float(n);
        float f = clamp(t, 0.0, back) / back;
		f = pow(f, 2.0);
        vec3 tex = _texture(w, sp.z);
        fc += tex / float(n);
    }
    
	fragColor = vec4(sqrt(fc), 1.0);
}
//  (image) — try volumetric by candycat
// https://www.shadertoy.com/view/Xsd3R2

vec4 sphere = vec4(0.0, 0.0, 0.0, 1.0);

float noise( in vec3 x )
{
    vec3 f = fract(x);
    vec3 p = floor(x);
    f = f * f * (3.0 - 2.0 * f);
     
    vec2 uv = (p.xy + vec2(37.0, 17.0) * p.z) + f.xy;
    vec2 rg = texture(iChannel0, (uv + 0.5)/256.0, -100.0).yx;
    return mix(rg.x, rg.y, f.z);
}

float fractal_noise(vec3 p)
{
    float f = 0.0;
    // add animation
    p = p - vec3(1.0, 1.0, 0.0) * iTime * 0.1;
    p = p * 3.0;
    f += 0.50000 * noise(p); p = 2.0 * p;
	f += 0.25000 * noise(p); p = 2.0 * p;
	f += 0.12500 * noise(p); p = 2.0 * p;
	f += 0.06250 * noise(p); p = 2.0 * p;
    f += 0.03125 * noise(p);
    
    return f;
}

float sphIntersect( vec3 ro, vec3 rd, vec4 sph )
{
    vec3 oc = ro - sph.xyz;
    float b = dot( oc, rd );
    float c = dot( oc, oc ) - sph.w*sph.w;
    float h = b*b - c;
    if( h<0.0 ) return -1.0;
    h = sqrt( h );
    return -b - h;
}

float density(vec3 pos, float dist)
{    
    float den = -0.2 - dist * 1.5 + 3.0 * fractal_noise(pos);
    den = clamp(den, 0.0, 1.0);
    float size = clamp(texture(iChannel1, vec2(0.5, 0.0)).x * 2.0 + 0.1, 0.4, 0.8);
    float edge = 1.0 - smoothstep(size*sphere.w, sphere.w, dist);
    edge *= edge;
    den *= edge;
    return den;
}

vec3 color(float den, float dist)
{
    // add animation
    vec3 result = mix(vec3(1.0, 0.9, 0.8 + sin(iTime) * 0.1), 
                      vec3(0.5, 0.15, 0.1 + sin(iTime) * 0.1), den * den);
    
    vec3 colBot = 3.0 * vec3(1.0, 0.9, 0.5);
	vec3 colTop = 2.0 * vec3(0.5, 0.55, 0.55);
    result *= mix(colBot, colTop, min((dist+0.5)/sphere.w, 1.0));
    return result;
}

vec3 raymarching(vec3 ro, vec3 rd, float t, vec3 backCol)
{
    vec4 sum = vec4(0.0);
    vec3 pos = ro + rd * t;
    for (int i = 0; i < 30; i++) {
        float dist = length(pos - sphere.xyz);
        if (dist > sphere.w + 0.01 || sum.a > 0.99) break;
        
        float den = density(pos, dist);
        vec4 col = vec4(color(den, dist), den);
        col.rgb *= col.a;
        sum = sum + col*(1.0 - sum.a); 
        
        t += max(0.05, 0.02 * t);
        pos = ro + rd * t;
    }
    
    sum = clamp(sum, 0.0, 1.0);
    return mix(backCol, sum.xyz, sum.a);
}

mat3 setCamera(vec3 ro, vec3 ta, float cr)
{
	vec3 cw = normalize(ta-ro);
	vec3 cp = vec3(sin(cr), cos(cr),0.0);
	vec3 cu = normalize( cross(cw,cp) );
	vec3 cv = normalize( cross(cu,cw) );
    return mat3( cu, cv, cw );
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
	vec2 p = (2.0 * fragCoord.xy - iResolution.xy) / iResolution.yy;
    vec2 mo = vec2(iTime * 0.5);
    if (iMouse.z > 0.0) 
    {
        mo += (2.0 * iMouse.xy - iResolution.xy) / iResolution.yy;
    }
    
    // Rotate the camera
    vec3 ro = vec3(0.0, 0.0, -2.0);
    vec2 cossin = vec2(cos(mo.x), sin(mo.x));
    mat3 rot = mat3(cossin.x, 0.0, -cossin.y,
                   	0.0, 1.0, 0.0,
                   	cossin.y, 0.0, cossin.x);
    ro = rot * ro;
    cossin = vec2(cos(mo.y), sin(mo.y));
    rot = mat3(1.0, 0.0, 0.0,
               0.0, cossin.x, -cossin.y,
               0.0, cossin.y, cossin.x);
    ro = rot * ro;
    
    // Compute the ray
    vec3 rd = setCamera(ro, vec3(0.0), 0.0) * normalize(vec3(p.xy, 1.5));
    
    float dist = sphIntersect(ro, rd, sphere);
    vec3 col = vec3(0.45, 0.4, 0.4) * (1.0- 0.3 * length(p));
    
    if (dist > 0.0) {
        col = raymarching(ro, rd, dist, col);
    }
    
    fragColor = vec4(col, 1.0);
}
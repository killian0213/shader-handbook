// Buffer A (buffer) — Sea of spheres by z0rg
// https://www.shadertoy.com/view/mddSWf

// This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 3.0
// Unported License. To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/3.0/ 
// or send a letter to Creative Commons, PO Box 1866, Mountain View, CA 94042, USA.
// =========================================================================================================

float _seed;
float rand()
{
    _seed++;
    return hash11(_seed);
}

vec2 map(vec3 p)
{
    vec2 acc = vec2(10000.,-1.);
    vec2 rep = vec2(.6);
    vec2 id = floor((p.xz+rep*.5)/rep);
    p.xz = mod(p.xz+rep*.5,rep)-rep*.5;
    p.y += sin(length(id)*.25-iTime)*2.;
    acc = _min(acc, vec2(length(p)-.25, 0.));
    
    return acc;
}

vec3 getNorm(vec3 p, float d)
{
    vec2 e = vec2(0.01, 0.);
    return normalize(vec3(d)-vec3(map(p-e.xyy).x, map(p-e.yxy).x, map(p-e.yyx).x));
}
vec3 accCol;
vec3 trace(vec3 ro, vec3 rd, int steps)
{
    vec3 p = ro;
    for (int i = 0; i < steps && distance(p, ro) < 150.; ++i)
    {
        vec2 res = map(p);
        if (res.x < 0.01)
            return vec3(res.x, distance(p, ro), res.y);
        p+=rd*res.x*.4;
        accCol += vec3(1.)*(1.-sat(res.x/.2))*.01;
    }
    return vec3(-1.);
}

vec3 rdr(vec2 uv)
{
    vec3 col = vec3(0.);
    float d = 60.;
    vec3 ro = vec3(sin(iTime*.5)*20.,-d,-d);
    vec3 ta = vec3(0.,0.,0.);
    vec3 rd = normalize(ta-ro);
    
    rd = getCam(rd, uv);
    vec3 res = trace(ro, rd, 128);
    float depth = 100.;
    if (res.y > 0.)
    {
        depth = res.y;
        vec3 p = ro+rd*res.y;
        vec3 n = getNorm(p, res.x);
        col = n*.5+.5;
        col = mix(
        vec3(1.000,0.451,0.000), 
        vec3(0.094,0.376,0.949),
        1.-pow(sat(-dot(normalize(vec3(1.)), n)*.75),1.));
        col = mix(col, vec3(1.), pow(sat(-dot(rd, n)),5.));
        col = mix(col, col*.5, sat(p.y*.5+.5));
    }
    col += accCol;

    return col;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 ouv = (fragCoord)/iResolution.xy;
    vec2 uv = (fragCoord-.5*iResolution.xy)/iResolution.xx;
    _seed = iTime+texture(iChannel0, uv).x;
    vec2 off = .75*(vec2(rand(), rand())-.5);
    vec3 col = rdr(uv+off*pow(abs(uv.y),3.));
    col = sat(col*1.2);
    col = pow(col, vec3(2.2));
    

    col = mix(col, texture(iChannel1, fragCoord/iResolution.xy).xyz, .95);
    fragColor = vec4(col,1.0);
}
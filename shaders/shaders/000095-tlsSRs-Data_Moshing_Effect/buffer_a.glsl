// Buffer A (buffer) — Data Moshing Effect by slerpy
// https://www.shadertoy.com/view/tlsSRs

mat2 rot(float a)
{
    float s=sin(a),c=cos(a);
    return mat2(c,s,-s,c);
}

float map(vec3 p)
{
    vec3 q = abs(fract(p)-.5);
    q = min(q,q.zxy);
    return max(max(q.x, q.y), q.z) - 0.1;
}

float trace(vec3 ro, vec3 rd)
{
    float m, t=0.1;
    for(int i=0; i++<400;)
        if(t+=m=map(ro+rd*t), m<0.01||t>16.)
            break;
    
	return t;
}

mat3 camera(float t, out vec3 ro)
{
    // placeholder animation
    float p = 4., mt = mod(t, p);
    t = (t - mt) + p*smoothstep(.0, p, mt);
    vec3 dir = vec3(cos(floor(iTime/p)),sin(floor(iTime/p)),.8);
    ro=vec3(0.1*sin(t),0.1*cos(1.2*t),0.2*t);
    
    // rotation matrix for rd
    vec3 cw=normalize(dir);
    vec3 cu=normalize(cross(vec3(0,1,0),cw));
    vec3 cv=normalize(cross(cw,cu));
    return mat3(cu,cv,cw);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    ivec2 u = ivec2(fragCoord);
    vec4 last = texelFetch(iChannel0, u, 0);
    
    // reset after color override
    if(last.w < .0)
    {
        fragColor = vec4(fragCoord, 0, iTime);
        return;
    }
    
    // main trace 
    vec3 ro, rd = camera(iTime, ro) * normalize(vec3(2.*fragCoord-iResolution.xy, iResolution.y));
    
    float t = trace(ro, rd);
    vec3 p = ro + rd * t;
    
    // occlusion trace
    float pt = last.w;
    mat3 m = camera(pt, ro);
    
    vec3 od = ro - p;
    float odl = length(od);
    bool occ = trace(p, od/odl)-odl < .01;
    
    // back projection
    vec2 coord = 0.5 * (od *= m, od.xy / od.z * iResolution.y + iResolution.xy);
    
    // out of range check
    occ = occ || floor(coord/iResolution.xy) != vec2(0);
    
    // far plane check
    if(t > 16.)occ = false;
    
    // occlusion check
    if(occ || iFrame < 3)
    {
        vec4 rv = vec4(round(24.*p), 1);
        for(int i=0; i<8; i++)
            rv = fract(1e4*sin(rv)+ rv.wxyz);
        
        fragColor = vec4(rv.xyz, -1);
        return;
    }
    
    // output coord
    if(iFrame % 8 == 0)pt = iTime;
    fragColor = vec4(coord, 0, pt);
}
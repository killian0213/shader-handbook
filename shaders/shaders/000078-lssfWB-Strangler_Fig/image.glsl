// Image (image) — Strangler Fig by leon
// https://www.shadertoy.com/view/lssfWB

// Raymarching sketch about a plant named Strangler Fig that grows around a tree host.
// Recently saw in real life while traveling with friends in Thailand.
// Look for pictures on internet, it does really amazing shapes.
// Leon 21 / 06 / 2017

// using codes from iq, mercury, lj, koltes

#define PI 3.14159
#define TAU 2.*PI
#define t iTime*.3
#define wood1 vec3(0.658, 0.592, 0.529)
#define wood2 vec3(0.415, 0.352, 0.290)
struct Infos { vec3 color; vec3 pos; float blend; };
Infos infos;
mat2 rot (float a) { float c=cos(a),s=sin(a);return mat2(c,-s,s,c); }
float sphere (vec3 p, float r) { return length(p)-r; }
float cyl (vec2 p, float r) { return length(p)-r; }
float iso (vec3 p, float r) { return dot(p,normalize(sign(p)))-r; }
float smin (float a, float b, float r) {
    float h = clamp(.5+.5*(b-a)/r,0.,1.);
    return mix(b,a,h)-r*h*(1.-h);
}
float scolor (float a, float b, float r) {
    return clamp(.5+.5*(b-a)/r,0.,1.);
}
vec3 moda (vec2 p, float count) {
    float an = TAU/count;
    float a = atan(p.y,p.x)+an*.5;
    float c = floor(a/an);
    a = mod(a,an)-an*.5;
    c = mix(c,abs(c),step(count*.5,abs(c)));
    return vec3(vec2(cos(a),sin(a))*length(p),c);
}

// Martin Palko http://www.martinpalko.com/triplanar-mapping/
vec3 triplanar(vec3 pos, vec3 normal, sampler2D channel, float uvscale) {
    vec2 uvx = pos.yz*uvscale;
    vec2 uvy = pos.xz*uvscale;
    vec2 uvz = pos.xy*uvscale;
    vec3 texx = texture(channel,uvx).rgb;
    vec3 texy = texture(channel,uvy).rgb;
    vec3 texz = texture(channel,uvz).rgb;
    vec3 blends = abs(normal);
    return texx*blends.x+texy*blends.y+texz*blends.z;
}

float map (vec3 p);
vec3 normal (vec3 p) {
    float e = .01;
    return normalize(vec3(map(p+vec3(e,0,0))-map(p+vec3(-e,0,0)),
                          map(p+vec3(0,e,0))-map(p+vec3(0,-e,0)),
                          map(p+vec3(0,0,e))-map(p+vec3(0,0,-e))));
}
float luminance (vec3 c) { return (c.r+c.g+c.b)/3.; }
vec3 camera (vec3 p) {
    //p.xz *= rot(t);
    //p.yz *= rot(t*1.5);
    p.yz *= rot((PI*(iMouse.y/iResolution.y-.5)*step(0.5,iMouse.z)));
    p.xz *= rot((PI*(iMouse.x/iResolution.x-.5)*step(0.5,iMouse.z)));
    p.xz *= rot(0.5);
    p.z += t;
    return p;
}

float root (vec3 p, float count, float torsade, float width, float scale) {
    p.xz *= rot(torsade);
    vec3 p1 = moda(p.xz, count);
    p1.x -= width+.2*sin(p1.z);
    p.xz = p1.xy;
    return cyl(p.xz, scale);
}

float map (vec3 p) {
    
    p = camera(p);
    float treespace = 8.;
    float treeindex = abs(floor(p.x/treespace)+floor(p.z/treespace));
    p.xz = mod(p.xz,treespace)-treespace*.5;
    
    float blendRoots = .2;
    float blendTrunk = .02;
    float trunkWidth = 1.+.25*(.5+.5*sin(-p.y*.5+t*2.+treeindex*3.));
    float hostTrunk = cyl(p.xz, trunkWidth);
    
    // fat
    float seed1 = treeindex*4.+t+p.y*.25+sin(p.y*.2+t);
    float seed2 = treeindex*3.+t+p.y*-.1+sin(p.y*.2+t);
    float roots = root(p, 2.+mod(treeindex,6.), seed1, trunkWidth, .2);
    roots = smin(roots, root(p, 2.+mod(treeindex,6.), seed2, trunkWidth+.1+sin(p.y*.3+t*3.+treeindex)*.3, .3), blendRoots);
    // middle
    float seed3 = treeindex*2.+3.*p.y*-.1+sin(-p.y*.2+t*2.);
    float seed3b = treeindex*2.+.1*p.y+sin(-p.y*.2+t*2.);
    roots = smin(roots, root(p, 3., seed3, trunkWidth+.1, .2), blendRoots);
    roots = smin(roots, root(p, 6.+mod(treeindex,6.), seed3b, trunkWidth+.1, .2), blendRoots);
    // thin
    float seed4 = treeindex*8.+p.y*.5+sin(p.y*2.5+t*3.)*.2;
    float seed5 = treeindex*4.+p.y*-.5+sin(p.y*1.5+t*5.)*.2;
    roots = smin(roots, root(p, 8., seed4, trunkWidth+.1, .09), blendRoots);
    roots = smin(roots, root(p, 6., seed5, trunkWidth+.2, .08), blendRoots);
    
    float scene = smin(roots, hostTrunk, blendTrunk);
    infos.pos = p;
    infos.blend = scolor(hostTrunk, roots, blendTrunk);
    return scene;
}

void mainImage( out vec4 color, in vec2 coord )
{
	vec2 uv = (coord.xy-.5*iResolution.xy)/iResolution.y;
    vec3 eye = vec3(uv,0.), ray = normalize(vec3(uv,.5)), pos = eye;
    int ri = 0;
    for (int i = 0; i < 50; ++i) {
        float dist = map(pos);
        if (dist < 0.001) {
            break;
        }
        pos += ray*dist;
        ri = i;
    }
    float ratio = float(ri)/50.;
    color.rgb = mix(wood1, wood2, infos.blend);
    
    vec3 n = normal(pos);
    
    vec3 tex = triplanar(pos, n, iChannel1,.09);
    tex = mix(tex, triplanar(pos, n, iChannel0,0.5), infos.blend);
    float lum = luminance(tex);
    color.rgb *= smoothstep(-.5,1.,lum)*2.;
    //color.rgb *= dot(-ray,n)*.5+.5;
    //color.rgb = n*.5+.5;
    color.rgb *= 1.-ratio;
}
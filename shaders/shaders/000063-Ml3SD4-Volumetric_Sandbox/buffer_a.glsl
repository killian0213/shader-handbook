// Buf A (buffer) — Volumetric Sandbox by Flyguy
// https://www.shadertoy.com/view/Ml3SD4


float pi = atan(1.0)*4.0;
float tau = atan(1.0)*8.0;

vec3 iVResolution = vec3(0);

void mainVolume( out vec4 voxColor, in vec3 voxCoord);

vec4 texture3D(sampler2D tex, vec3 uvw, vec3 vres)
{
    uvw = mod(floor(uvw * vres), vres);
    float idx = (uvw.z * (vres.x*vres.y)) + (uvw.y * vres.x) + uvw.x;
    vec2 uv = vec2(mod(idx, iResolution.x), floor(idx / iResolution.x));
    
    return texture(tex, (uv + 0.5) / iResolution.xy);
}

vec4 texture3DLinear(sampler2D tex, vec3 uvw, vec3 vres)
{
    vec3 blend = fract(uvw*vres);
    vec4 off = vec4(1.0/vres, 0.0);
    
    vec4 b000 = texture3D(tex, uvw + off.www, vres);
    vec4 b100 = texture3D(tex, uvw + off.xww, vres);
    
    vec4 b010 = texture3D(tex, uvw + off.wyw, vres);
    vec4 b110 = texture3D(tex, uvw + off.xyw, vres);
    
    vec4 b001 = texture3D(tex, uvw + off.wwz, vres);
    vec4 b101 = texture3D(tex, uvw + off.xwz, vres);
    
    vec4 b011 = texture3D(tex, uvw + off.wyz, vres);
    vec4 b111 = texture3D(tex, uvw + off.xyz, vres);
    
    return mix(mix(mix(b000,b100,blend.x), mix(b010,b110,blend.x), blend.y), 
               mix(mix(b001,b101,blend.x), mix(b011,b111,blend.x), blend.y),
               blend.z);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec3 vres = vec3(floor(pow(iResolution.x*iResolution.y, 1.0/3.0)));    
    vec2 uv = floor(fragCoord - 0.5);
    
    float idx = (uv.y * iResolution.x) + uv.x;
    
    vec3 uvw = mod(floor(vec3(idx) / vec3(1.0, vres.x, vres.x*vres.y)), vres);
    
    iVResolution = vres;
    mainVolume(fragColor, uvw);
}

//Write your shader here.
//3D plasma thing.
void mainVolume( out vec4 voxColor, in vec3 voxCoord)
{
    vec3 uvw = voxCoord / iVResolution;

    vec3 color = vec3(1,0,0);
    
    vec3 p0 = sin(vec3(1.3,0.9,2.1) * iTime + 7.0)*.5+.5;
    vec3 p1 = sin(vec3(0.5,1.6,0.8) * iTime + 4.0)*.5+.5;
    vec3 p2 = sin(vec3(0.9,1.2,1.5) * iTime + 2.0)*.5+.5;
    
    float s0 = cos(length(p0-uvw)*28.0);
    float s1 = cos(length(p1-uvw)*19.0);
    float s2 = cos(length(p2-uvw)*22.0);
    
    float dens = (s0+s1+s2)/3.0;
    
    color = vec3(s0,s1,s2);
    
    dens *= 0.5;
    
    voxColor = vec4(color, dens);
}
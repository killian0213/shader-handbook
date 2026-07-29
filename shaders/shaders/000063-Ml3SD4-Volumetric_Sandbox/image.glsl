// Image (image) — Volumetric Sandbox by Flyguy
// https://www.shadertoy.com/view/Ml3SD4


#define LINEAR_SAMPLE 1
#define MAX_VOLUME_STEPS 290
#define VOLUME_STEP_SIZE 0.02
#define MAX_ALPHA 0.95
#define DENSITY_SCALE 1.0

float pi = atan(1.0)*4.0;
float tau = atan(1.0)*8.0;

vec3 vres = vec3(0);

mat2 rotate(float a)
{
    return mat2(cos(a),sin(a),-sin(a),cos(a));
}

vec4 texture3D(sampler2D tex, vec3 uvw, vec3 vres)
{
    uvw = mod(floor(uvw * vres), vres);
    
    //XYZ -> Pixel index
    float idx = (uvw.z * (vres.x*vres.y)) + (uvw.y * vres.x) + uvw.x;
    
    //Pixel index -> Buffer uv coords
    vec2 uv = vec2(mod(idx, iResolution.x), floor(idx / iResolution.x));
    
    //WEBGL 2 FIX: texture(...) caused loop unrolling errors, using textureLod(...) fixes this.
    return textureLod(tex, (uv + 0.5) / iResolution.xy, 0.0);
}

vec4 texture3DLinear(sampler2D tex, vec3 uvw, vec3 vres)
{
    vec3 blend = fract(uvw*vres);
    vec4 off = vec4(1.0/vres, 0.0);
    
    //2x2x2 sample blending
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

//Ray-Cube intersection. x = tmin, y = tmax, hit = tmin < tmax 
vec2 IntersectBox(vec3 orig, vec3 dir, vec3 pos, vec3 size)
{
    size = abs(size / dir / 2.0);

    vec3 tc = (pos - orig) / dir;    

    vec3 t0 = tc - size;
    vec3 t1 = tc + size;
    
    return vec2(
        max(max(t0.x,t0.y),t0.z), 
        min(min(t1.x,t1.y),t1.z)
    );
}

vec4 MarchVolume(vec3 orig, vec3 dir)
{
    vec2 hit = IntersectBox(orig, dir, vec3(0), vec3(2));
    
    if(hit.x > hit.y){ return vec4(0); }
    
    //Step though the volume and add up the opacity.
    float t = hit.x;   
    vec4 dst = vec4(0);
    vec4 src = vec4(0);
    
    for(int i = 0;i < MAX_VOLUME_STEPS;i++)
    {
        t += VOLUME_STEP_SIZE;
        
        //Stop marching if the ray leaves the cube.
        if(t > hit.y){break;}
        
    	vec3 pos = orig + dir * t;
        
        vec3 uvw = 1.0 - (pos * 0.5 + 0.5);
        
        #if(LINEAR_SAMPLE == 1)
            src = texture3DLinear(iChannel0, uvw, vres);
        #else
            src = texture3D(iChannel0, uvw, vres);
        #endif
        
        src = clamp(src, 0.0, 1.0);
        
        src.a *= DENSITY_SCALE;
        src.rgb *= src.a;
        
        dst = (1.0 - dst.a)*src + dst;
        
        //Stop marching if the color is nearly opaque.
        if(dst.a > MAX_ALPHA){break;}
    }
    
    return vec4(dst);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vres = vec3(floor(pow(iResolution.x*iResolution.y, 1.0/3.0)));
    
    vec2 res = iResolution.xy / iResolution.y;
	vec2 uv = fragCoord.xy / iResolution.y;
    
    vec4 color = vec4(0);
    
    //Checkerboard background
    vec2 bguv = uv - res/2.0;
    float back = sin(bguv.x*pi*8.0) * sin(bguv.y*pi*8.0);
    back = step(0.0,back);
    back = back * 0.05 + 0.2;
    color.rgb = vec3(back);
    
    vec3 dir = normalize(vec3(uv-res/2.0,1.0));
    vec3 orig = vec3(0,0,-3.5);
	
    vec2 angles = vec2(0);
    
    if(iMouse.xy == vec2(0))
    {
        angles = vec2(iTime * 0.5, -tau/16.0); 
    }
    else
    {
    	angles = (iMouse.xy / iResolution.xy)*2.0 - 1.0;
    	angles *= vec2(tau, tau/2.0);
    }
    
    mat2 rX = rotate( angles.y);
    mat2 rY = rotate(angles.x);
    
    dir.yz *= rX;
    orig.yz *= rX;
    
    dir.xz *= rY;
    orig.xz *= rY;
    
    vec4 volume = MarchVolume(orig,dir);
    
    color = mix(color, volume, volume.a);
    
	fragColor = vec4(color);
}
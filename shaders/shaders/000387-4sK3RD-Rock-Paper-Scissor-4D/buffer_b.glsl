// Buffer B (buffer) — Rock-Paper-Scissor-4D by Flexi
// https://www.shadertoy.com/view/4sK3RD

#define pi2_inv 0.159154943091895335768883763372

vec2 lower_left(vec2 uv)
{
    return fract(uv * 0.5);
}

vec2 lower_right(vec2 uv)
{
    return fract((uv - vec2(1, 0.)) * 0.5);
}

vec2 upper_left(vec2 uv)
{
    return fract((uv - vec2(0., 1)) * 0.5);
}

vec2 upper_right(vec2 uv)
{
    return fract((uv - 1.) * 0.5);
}

vec2 mouseDelta(){
    vec2 pixelSize = 1. / iResolution.xy;
    float eighth = 1./8.;
    vec4 oldMouse = texture(iChannel3, vec2(7.5 * eighth, 2.5 * eighth));
    vec4 nowMouse = vec4(iMouse.xy / iResolution.xy, iMouse.zw / iResolution.xy);
    if(oldMouse.z > pixelSize.x && oldMouse.w > pixelSize.y && 
       nowMouse.z > pixelSize.x && nowMouse.w > pixelSize.y)
    {
        return nowMouse.xy - oldMouse.xy;
    }
    return vec2(0.);
}

vec4 BlurA(vec2 uv, int level)
{
    if(level <= 0)
    {
        return texture(iChannel0, fract(uv));
    }

    uv = upper_left(uv);
    for(int depth = 1; depth < 8; depth++)
    {
        if(depth >= level)
        {
            break;
        }
        uv = lower_right(uv);
    }

    return texture(iChannel3, uv);
}

vec4 BlurB(vec2 uv, int level)
{
    if(level <= 0)
    {
        return texture(iChannel1, fract(uv));
    }

    uv = lower_left(uv);
    for(int depth = 1; depth < 8; depth++)
    {
        if(depth >= level)
        {
            break;
        }
        uv = lower_right(uv);
    }

    return texture(iChannel3, uv);
}

vec2 GradientA(vec2 uv, vec2 d, vec4 selector, int level){
    vec4 dX = 0.5*BlurA(uv + vec2(1.,0.)*d, level) - 0.5*BlurA(uv - vec2(1.,0.)*d, level);
    vec4 dY = 0.5*BlurA(uv + vec2(0.,1.)*d, level) - 0.5*BlurA(uv - vec2(0.,1.)*d, level);
    return vec2( dot(dX, selector), dot(dY, selector) );
}

vec2 rot90(vec2 vector){
    return vector.yx*vec2(1,-1);
}

vec2 complex_mul(vec2 factorA, vec2 factorB){
    return vec2( factorA.x*factorB.x - factorA.y*factorB.y, factorA.x*factorB.y + factorA.y*factorB.x);
}

vec2 spiralzoom(vec2 domain, vec2 center, float n, float spiral_factor, float zoom_factor, vec2 pos){
    vec2 uv = domain - center;
    float d = length(uv);
    return vec2( atan(uv.y, uv.x)*n*pi2_inv + d*spiral_factor, -log(d)*zoom_factor) + pos;
}

vec2 complex_div(vec2 numerator, vec2 denominator){
    return vec2( numerator.x*denominator.x + numerator.y*denominator.y,
                numerator.y*denominator.x - numerator.x*denominator.y)/
        vec2(denominator.x*denominator.x + denominator.y*denominator.y);
}

float circle(vec2 uv, vec2 aspect, float scale){
    return clamp( 1. - length((uv-0.5)*aspect*scale), 0., 1.);
}

float sigmoid(float x) {
    return 2./(1. + exp2(-x)) - 1.;
}

float smoothcircle(vec2 uv, vec2 aspect, float radius, float ramp){
    return 0.5 - sigmoid( ( length( (uv - 0.5) * aspect) - radius) * ramp) * 0.5;
}

float conetip(vec2 uv, vec2 pos, float size, float min)
{
    vec2 aspect = vec2(1.,iResolution.y/iResolution.x);
    return max( min, 1. - length((uv - pos) * aspect / size) );
}

float warpFilter(vec2 uv, vec2 pos, float size, float ramp)
{
    return 0.5 + sigmoid( conetip(uv, pos, size, -16.) * ramp) * 0.5;
}

vec2 vortex_warp(vec2 uv, vec2 pos, float size, float ramp, vec2 rot)
{
    vec2 aspect = vec2(1.,iResolution.y/iResolution.x);

    vec2 pos_correct = 0.5 + (pos - 0.5);
    vec2 rot_uv = pos_correct + complex_mul((uv - pos_correct)*aspect, rot)/aspect;
    float filterv = warpFilter(uv, pos_correct, size, ramp);
    return mix(uv, rot_uv, filterv);
}

vec2 vortex_pair_warp(vec2 uv, vec2 pos, vec2 vel)
{
    vec2 aspect = vec2(1.,iResolution.y/iResolution.x);
    float ramp = 4.;

    float d = 0.125;

    float l = length(vel);
    vec2 p1 = pos;
    vec2 p2 = pos;

    if(l > 0.){
        vec2 normal = normalize(vel.yx * vec2(-1., 1.))/aspect;
        p1 = pos - normal * d / 2.;
        p2 = pos + normal * d / 2.;
    }

    float w = l / d * 2.;

    // two overlapping rotations that would annihilate when they were not displaced.
    vec2 circle1 = vortex_warp(uv, p1, d, ramp, vec2(cos(w),sin(w)));
    vec2 circle2 = vortex_warp(uv, p2, d, ramp, vec2(cos(-w),sin(-w)));
    return (circle1 + circle2) / 2.;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord.xy / iResolution.xy;
    vec4 noise = texture(iChannel2, fragCoord.xy / iChannelResolution[2].xy + fract(vec2(42,56)*iTime));

    if(iFrame<10)
    {
        fragColor = noise;
        return;
    }


    uv = 0.5 + (uv - 0.5)*0.99;
    vec2 pixelSize = 1./iResolution.xy;
    vec2 mouseV = mouseDelta();
    vec2 aspect = vec2(1.,iResolution.y/iResolution.x);
    uv = vortex_pair_warp(uv, iMouse.xy*pixelSize, mouseV*aspect*1.4);

    float time = float(iFrame)/60.;
    uv = uv + vec2(sin(time*0.1 + uv.x*2. +1.) - sin(time*0.214 + uv.y*2. +1.), sin(time*0.168 + uv.x*2. +1.) - sin(time*0.115 +uv.y*2. +1.))*pixelSize*1.5;

    fragColor = BlurB(uv, 0);
    fragColor += ((BlurB(uv, 1) - BlurB(uv, 2))*0.5 + (noise-0.5) * 0.004); 

    fragColor = clamp(fragColor, 0., 1.);

    //fragColor = noise; // reset
}
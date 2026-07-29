// Buffer D (buffer) — Multiscale Turing Patterns by cornusammonis
// https://www.shadertoy.com/view/MdGGzR

#define Pr 0.299
#define Pg 0.587
#define Pb 0.114
#define saturation 0.9925
#define darkening 0.01
#define rate 0.005
#define blur 0.02

float hash( vec2 p ) {
	float h = dot(p,vec2(127.1,311.7));	
    return fract(sin(h)*43758.5453123);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord.xy / iResolution.xy;
    vec2 texel = 1.0 / iResolution.xy;
    vec4 b0 = vec4(texture(iChannel0, uv).yw, texture(iChannel1, uv).yw);
    vec2 b1 = texture(iChannel2, uv).yw;
    
    const float _K0 = -20.0/6.0; // center weight
    const float _K1 = 4.0/6.0; // edge-neighbors
    const float _K2 = 1.0/6.0; // vertex-neighbors
    
    // 3x3 neighborhood coordinates
    float step_x = texel.x;
    float step_y = texel.y;
    vec2 n  = vec2(0.0, step_y);
    vec2 ne = vec2(step_x, step_y);
    vec2 e  = vec2(step_x, 0.0);
    vec2 se = vec2(step_x, -step_y);
    vec2 s  = vec2(0.0, -step_y);
    vec2 sw = vec2(-step_x, -step_y);
    vec2 w  = vec2(-step_x, 0.0);
    vec2 nw = vec2(-step_x, step_y);

    vec4 is =    texture(iChannel3, uv);
    vec4 is_n =  texture(iChannel3, uv+n);
    vec4 is_e =  texture(iChannel3, uv+e);
    vec4 is_s =  texture(iChannel3, uv+s);
    vec4 is_w =  texture(iChannel3, uv+w);
    vec4 is_nw = texture(iChannel3, uv+nw);
    vec4 is_sw = texture(iChannel3, uv+sw);
    vec4 is_ne = texture(iChannel3, uv+ne);
    vec4 is_se = texture(iChannel3, uv+se);

    // laplacian of all components
    vec4 lapl  = _K0*is + _K1*(is_n + is_e + is_w + is_s) + _K2*(is_nw + is_sw + is_ne + is_se);
    
    vec3 weights[6]; 
    weights[0] = vec3(1.0, -1.0, 1.0); 
    weights[1] = vec3(2.0, 2.0, 1.0); 
    weights[2] = vec3(3.0, -2.0, -4.0); 
    weights[3] = vec3(4.0, 3.0, 6.0); 
    weights[4] = vec3(5.0, 5.0, 3.0); 
    weights[5] = vec3(6.0, 3.0, -2.0);

    // difference of gaussians
    float dogs[6];
    dogs[0] = is.x - b0.x;
    dogs[1] = b0.x - b0.y;
    dogs[2] = b0.y - b0.z;
    dogs[3] = b0.z - b0.w;
    dogs[4] = b0.w - b1.x;
    dogs[5] = b1.x - b1.y;
    
    float lowest_variation = 10000.0;
    vec3 diff = vec3(0.0);
    for(int i = 0; i < 5; i++) {
        float variation = abs(dogs[i]);
        if( variation < lowest_variation )
        {
            lowest_variation = variation;
            diff = sign(dogs[i]) * weights[i];
        }
    }
    
    vec4 p = vec4(sqrt(is.x*is.x*Pr + is.y*is.y*Pg + is.z*is.z*Pb));
    vec4 desaturated = vec4(p) + (is - vec4(p)) * saturation;
    
    vec4 eps = vec4(0.1);
    
    // initialize with noise
    if(iFrame<10) {
        fragColor = vec4(hash(uv));
    } else {
        if(distance(fragCoord.xy, iMouse.xy) < 40.0) {
            fragColor = (vec4(1.0) - eps) * is + eps;    
        } else {
            fragColor = clamp(desaturated + rate * vec4(diff, 0.0) + blur * lapl - darkening, -1.0, 1.0);
        }
    }
    

}
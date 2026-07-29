// Buf A (buffer) — Gaussian SmoothLife by cornusammonis
// https://www.shadertoy.com/view/XtVXzV

// ---------------------------------------------
const float or = 18.0;         // outer gaussian std dev
const float ir = 6.0;         // inner gaussian std dev
const float b1 = 0.19;         // birth1
const float b2 = 0.212;        // birth2
const float s1 = 0.267;        // survival1
const float s2 = 0.445;        // survival2
const float dt = 0.2;          // timestep
const float alpha_n = 0.017;   // sigmoid width for outer fullness
const float alpha_m = 0.112;   // sigmoid width for inner fullness
// ---------------------------------------------

bool reset() {
    return texture(iChannel3, vec2(32.5/256.0, 0.5) ).x > 0.5;
}

// the logistic function is used as a smooth step function
float sigma1(float x,float a,float alpha) 
{ 
    return 1.0 / ( 1.0 + exp( -(x-a)*4.0/alpha ) );
}

float sigma2(float x,float a,float b,float alpha)
{
    return sigma1(x,a,alpha) 
        * ( 1.0-sigma1(x,b,alpha) );
}

float sigma_m(float x,float y,float m,float alpha)
{
    return x * ( 1.0-sigma1(m,0.5,alpha) ) 
        + y * sigma1(m,0.5,alpha);
}

// the transition function
// (n = outer fullness, m = inner fullness)
float s(float n,float m)
{
    return sigma2( n, sigma_m(b1,s1,m,alpha_m), 
        sigma_m(b2,s2,m,alpha_m), alpha_n );
}

#define T(d) texture(iChannel0, fract(uv+d)).x

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 tx = 1.0 / iResolution.xy;
    vec2 uv = fragCoord.xy * tx;
	
    const float _K0 = -20.0/6.0; // center weight
    const float _K1 = 4.0/6.0;   // edge-neighbors
    const float _K2 = 1.0/6.0;   // vertex-neighbors
    
    /* 
	We can optionally add a laplacian to the update rule
	to decrease the appearance of aliasing, but we also
	introduce subtle anisotropy by doing so.
        vec4 t = vec4(tx, -tx.y, 0.0);
        float u =    T( t.ww); float u_n =  T( t.wy); float u_e =  T( t.xw);
        float u_s =  T( t.wz); float u_w =  T(-t.xw); float u_nw = T(-t.xz);
        float u_sw = T(-t.xy); float u_ne = T( t.xy); float u_se = T( t.xz);
        float lapl  = _K0*u + _K1*(u_n + u_e + u_w + u_s) + _K2*(u_nw + u_sw + u_ne + u_se);
    */    

    vec4 current = texture(iChannel0, uv);
    vec2 fullness = texture(iChannel1, uv).xy;
    
    float delta =  2.0 * s( fullness.x, fullness.y ) - 1.0;
    float new = clamp( current.x + dt * delta, 0.0, 1.0 );
    
    if(iMouse.z > 0.0) {
        // from chronos' SmoothLife shader https://www.shadertoy.com/view/XtdSDn
        float dst = length(fragCoord.xy - iMouse.xy);
        if(dst <= or) {
        	new = step((ir+1.5), dst) * (1.0 - step(or, dst));
        }
    }
    
    vec4 init = texture(iChannel2, uv);
    if(iFrame < 10 || reset() || (init != vec4(0) && current.w == 0.0)) {
    	fragColor = vec4(2.0*init.xyz,1.0);    
    } else {
    	fragColor = vec4(new, fullness, current.w);
    }
}
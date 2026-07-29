// Image (image) — Multispectral Paint Blending by cornusammonis
// https://www.shadertoy.com/view/Wtcfz4

/*
    Created by Cornus Ammonis (2021)
	Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
    
    This is an approach to paint mixing that solves the "blue + yellow = green"
    problem. In most color spaces, blending between blue and yellow will produce
    gray instead of green. This is a general problem; without a more robust
    representation of the color spectrum, we are unable to reliably achieve color
    blending results that are consistent with real-life expectations. In practical
    terms, that means that when we only use 3 or 4 color channels and repeatedly
    blend colors together, we tend to rapidly end up with a muddy gray color.
    Or worse, repeated blending may not be stable at all, and the result may tend 
    to blow up or settle on some fixed point in the color space no matter what 
    the input colors are. 
    
    Here, color space is represented by 16 8-bit log-space spectral components,
    which are packed into a vec4. Blending is achieved using simple linear blends
    on the 16 log-space components.
    
    A fluid simulation (Buffer A, C, D) is used to supply advection offset vectors 
    to the paint blending layer (Buffer B). The fluid simulation makes use of the 
    separable multistep Poisson solver method described here 
    
        Fast Separable Poisson SVD https://www.shadertoy.com/view/wsVyzD
        
    to solve for pressure. The fluid simulation is multiscale and incorporates
    methods developed here
    
        Multiscale MIP Fluid https://www.shadertoy.com/view/tsKXR3
        
    along with a few other techniques. I have adapted paniq's Analytical Biquadratic
    Gradient Interpolation method to take an LOD argument (Common Tab).
    
    Developing a colorspace is tricky and requires some choice of tradeoffs.
    I chose constants here to get a relatively accurate conversion from RGB
    while maintaining good saturation. It would be preferable to use higher 
    bit-depth values for each of the spectral components.
    
    A HI_QUALITY #define in the common tab can be enabled to use higher-order
    sampling for the fluid simulation. Buffer A and B have a variety of
    configurable parameters in #defines to change the fluid and blending
    properties.
    
*/

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
	vec2 texel = 1.0/iResolution.xy;
	vec2 uv = fragCoord.xy * texel;
    vec3 n = vec3(sample_biquadratic_gradient(iChannel2, iResolution.xy, uv, 0.0),0.04);

    n = normalize(n);

    vec3 light = normalize(vec3(1,4,3));
    
    float spec = ggx(reflect(light,n), vec3(0,1,0), light, 0.4, 0.8);
    
    float d = texture(iChannel2,uv).x;
    float occ = 0.0;
    float occs = 0.0;
    for (float m = 1.0; m <= 10.0; m +=1.0) {
        float dm = texture(iChannel2, uv, m).x;
        float occw = pow(m,1.0);
        occs += occw;
        occ += occw*softclamp(-1.0, 1.0, (d - dm),8.0);
    }
    occ /= occs;

    occ = pow(softclamp(0.0,1.0,occ,12.0), 0.06);

	fragColor = occ*(0.1*spec + (1.2+0.5*spec) * vec4(colorFromSpectrum(getPackedSpectrum(iChannel1, fragCoord)),1));

}
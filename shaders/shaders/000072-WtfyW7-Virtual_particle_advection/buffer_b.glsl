// Buffer B (buffer) — Virtual particle advection by michael0884
// https://www.shadertoy.com/view/WtfyW7

//velocity blur


void mainImage( out vec4 U, in vec2 pos )
{
    R = iResolution.xy; time = iTime;
    
	U = texel(ch1, pos);
    vec4 av = vec4(0.); float s = 0.0001;
    range(i, -3, 3) range(j, -3, 3)
    {
        vec2 dx = vec2(i,j);
        vec4 dc = decode(texel(ch0, pos + dx).zw);
        float k = dc.z*G(dx/1.);
        s += k;
        av += k*dc.xyzz;
    }
    U = av/s; 
}
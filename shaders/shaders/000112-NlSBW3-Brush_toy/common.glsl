// Common (common) — Brush toy by leon
// https://www.shadertoy.com/view/NlSBW3


// shortcut to sample texture
#define TEX(uv) texture(iChannel0, uv).r

// rotation matrix
mat2 rot (float a) { return mat2(cos(a),-sin(a),sin(a),cos(a)); }

// generated with discrete Fourier transform
vec2 cookie(float t) {
	return vec2(0.08+cos(t-1.58)*0.23+cos(t*2.-1.24)*0.14+cos(t*3.-1.12)*0.09+cos(t*4.-0.76)*0.06+cos(t*5.-0.59)*0.05+cos(t*6.+0.56)*0.03+cos(t*7.-2.73)*0.03+cos(t*8.-1.26)*0.02+cos(t*9.-1.44)*0.02+cos(t*10.-2.09)*0.03+cos(t*11.-2.18)*0.01+cos(t*12.-1.91)*0.02,cos(3.14)*0.05+cos(t+0.35)*0.06+cos(t*2.+0.54)*0.09+cos(t*3.+0.44)*0.03+cos(t*4.+1.02)*0.07+cos(t*6.+0.39)*0.03+cos(t*7.-1.48)*0.02+cos(t*8.-3.06)*0.02+cos(t*9.-0.39)*0.07+cos(t*10.-0.39)*0.03+cos(t*11.-0.03)*0.04+cos(t*12.-2.08)*0.02);
}

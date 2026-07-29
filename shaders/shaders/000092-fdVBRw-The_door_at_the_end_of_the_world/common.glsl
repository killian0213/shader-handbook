// Common (common) — The door at the end of the world by leon
// https://www.shadertoy.com/view/fdVBRw


#define repeat(p,r) (mod(p,r)-r/2.)
#define TEX(uv) texture(iChannel0, uv).r
mat2 rot (float a) { return mat2(cos(a),-sin(a),sin(a),cos(a)); }
float box (vec2 p, vec2 r) { return max(abs(p.x)-r.x,abs(p.y)-r.y); }
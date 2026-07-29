// Buffer B (buffer) — Crowdy waves by rory618
// https://www.shadertoy.com/view/ttyGWw

vec4 A(int i){
    return texture(iChannel0, (vec2((i-1)%int(R.x),(i-1)/int(R.x))+.5)/R.xy);
}



void list_insert(inout ivec4 i, inout vec4 s, int i_, float s_){
	ivec4 ri;
    vec4 rs;
    if(i_ == 0) return;
    if(any(equal(ivec4(i_),i))) return;
    if(s_<s[0]) {
        i = ivec4(i_,i.xyz);
        s = vec4(s_,s.xyz);
    } else if(s_<s[1]) {
        i = ivec4(i.x,i_,i.yz);
        s = vec4(s.x,s_,s.yz);
    } else if(s_<s[2]) {
        i = ivec4(i.xy,i_,i.z);
        s = vec4(s.xy,s_,s.z);
    } else if(s_<s[3]) {
        i = ivec4(i.xyz,i_);
        s = vec4(s.xyz,s_);
    }
}

void mainImage( out vec4 O, in vec2 I )
{
    O = texture(iChannel1, I/R.xy);
    vec4 a = texture(iChannel1, fract((I+vec2(1,0))/R.xy));
    vec4 b = texture(iChannel1, fract((I+vec2(0,1))/R.xy));
    vec4 c = texture(iChannel1, fract((I-vec2(1,0))/R.xy));
    vec4 d = texture(iChannel1, fract((I-vec2(0,1))/R.xy));
    ivec4 i = ivec4(0);
    ivec4 i0 = ivec4(cvt(O.x),cvt(O.y),cvt(O.z),cvt(O.w));
    ivec4 ia = ivec4(cvt(a.x),cvt(a.y),cvt(a.z),cvt(a.w));
    ivec4 ib = ivec4(cvt(b.x),cvt(b.y),cvt(b.z),cvt(b.w));
    ivec4 ic = ivec4(cvt(c.x),cvt(c.y),cvt(c.z),cvt(c.w));
    ivec4 id = ivec4(cvt(d.x),cvt(d.y),cvt(d.z),cvt(d.w));
	#define dist(i) length(mod( A(i).xy-I + R.xy/2., R.xy) - R.xy/2.) 
    vec4 s = vec4(1e9);
    for(int k = 0; k < 4; k++){
        list_insert(i, s, i0[k], dist(i0[k]) );
        list_insert(i, s, ia[k], dist(ia[k]) );
        list_insert(i, s, ib[k], dist(ib[k]) );
        list_insert(i, s, ic[k], dist(ic[k]) );
        list_insert(i, s, id[k], dist(id[k]) );
    }
    int r = IHash(int(I.x) + int(I.y)*2048 + iFrame*2048*2048);
    int i_ = 1+r%(int(R.x)*int(R.y)/10);
    list_insert(i, s, i_, length(I-A(i_).xy));
    O = vec4(cvt(i.x),cvt(i.y),cvt(i.z),cvt(i.w));
    
}
// Buffer D (buffer) — Dynamic Delaunay 4 by rory618
// https://www.shadertoy.com/view/WtcXz4

vec4 A(int i){
    return texture(iChannel0, (vec2((i-1)%int(R.x),(i-1)/int(R.x))+.5)/R.xy);
}
vec4 B(int i){
    return texture(iChannel1, (vec2((i-1)%int(R.x),(i-1)/int(R.x))+.5)/R.xy);
}

bool sameCollection(vec3 a, vec3 b){
    return any(equal(a.xyz,vec3(b.x))) && 
           any(equal(a.xyz,vec3(b.y))) && 
           any(equal(a.xyz,vec3(b.z)));
}

void list_insert(inout ivec4 i, inout vec4 s, int i_, float s_){
	ivec4 ri;
    vec4 rs;
    if(i_ == 0) return;
    
    if(any(equal(ivec4(i_),i))) return;
    vec3 tri = B(i_).xyz;
    if( sameCollection(B(i[0] ).xyz,tri) ||
        sameCollection(B(i[1] ).xyz,tri) ||
        sameCollection(B(i[2] ).xyz,tri) ||
        sameCollection(B(i[3] ).xyz,tri) ) return;
    
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

float score(int e, vec2 I){
    vec4 t = B(e);
    vec2 a = A(cvt(t.x)).xy;
    vec2 b = A(cvt(t.y)).xy;
    vec2 c = A(cvt(t.z)).xy;
    vec2 cc = circumscenter(a,b,c,R.xy);
    vec4 v = texture(iChannel1,cc/R.xy);
    if(!sameCollection(v.xyz,t.xyz) ){
          
        return 1e9;
    }
    
    return sdTriangle(I,a, b, c,R.xy);
}

void mainImage( out vec4 O, in vec2 I )
{
    
    int j = 1+(iFrame%5);j  *= j ;      
    
    O = texture(iChannel2, I/R.xy);
    vec4 a = texture(iChannel2, fract((I+vec2(j,0))/R.xy));
    vec4 b = texture(iChannel2, fract((I+vec2(0,j))/R.xy));
    vec4 c = texture(iChannel2, fract((I-vec2(j,0))/R.xy));
    vec4 d = texture(iChannel2, fract((I-vec2(0,j))/R.xy));
    ivec4 i = ivec4(0);
    ivec4 i0 = ivec4(cvt(O.x),cvt(O.y),cvt(O.z),cvt(O.w));
    ivec4 ia = ivec4(cvt(a.x),cvt(a.y),cvt(a.z),cvt(a.w));
    ivec4 ib = ivec4(cvt(b.x),cvt(b.y),cvt(b.z),cvt(b.w));
    ivec4 ic = ivec4(cvt(c.x),cvt(c.y),cvt(c.z),cvt(c.w));
    ivec4 id = ivec4(cvt(d.x),cvt(d.y),cvt(d.z),cvt(d.w));
    vec4 s = vec4(1e9);
    vec4 s0 = vec4(score(i.x,I),score(i.y,I),score(i.z,I),score(i.w,I));
    for(int k = 0; k < 4; k++){
        list_insert(i, s, i0[k], score(i0[k],I));
        list_insert(i, s, ia[k], score(ia[k],I));
        list_insert(i, s, ib[k], score(ib[k],I));
        list_insert(i, s, ic[k], score(ic[k],I));
        list_insert(i, s, id[k], score(id[k],I));
    }
    int r = IHash(int(I.x) + int(I.y)*2048 + iFrame*2048*2048);
    int i_ = 1+r%(int(R.x)*int(R.y));			
    list_insert(i, s, i_, score(i_,I));
    i_ = 1+int(I.x) + int(I.y)*int(R.x);				
    list_insert(i, s, i_, score(i_,I));
    O = vec4(cvt(i.x),cvt(i.y),cvt(i.z),cvt(i.w));
    
}
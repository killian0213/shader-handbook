// Buffer @ (buffer) — [SH17A] 2tweet fluid 2 by flockaroo
// https://www.shadertoy.com/view/4dBfDW

// derived from https://www.shadertoy.com/view/4sSBRm
// with the help of fabrice and 834144373 down to 278 total
// ...v,p,q uninitialized though
// but the fract could be left away in image tab and initialization commented in bufA

//now even initialized due to some extra chars from 834144373 :-)

#define C(x) texture(iChannel0,(x)/iResolution.xy).xy
#define L(b) for(vec2 a=S;a.x<-6.;b=sin(a++))
void mainImage(out vec4 c, vec2 f){vec2 p,q,S=vec2(-24,31),v=p=q=S-S; L(p)L(q) v+=p*dot(C((p+q).yx*S+f),q);c.xy=C(v+f)+.02/(f-1.);}
// the version below wont diverge - its not below 2 tweets though ;-)
// (amplitude is limited by atan)
//#define mainImage(c,f) vec2 p,q,S=vec2(-24,31),v=p=q=S-S; L(p)L(q) v+=p*dot(C((p+q).yx*S+f),q);c.xy=50.*atan(C(v+f)/50.)+.02/(f-1.)

/*
#define C(x) texture(iChannel0,(f+x)/iResolution.xy).xy
#define L(b) for(vec2 a=S;a.x<-6.;b=sin(a++))
void mainImage(out vec4 c, vec2 f)
{
    // <- uncomment this if you see garbage or nothing
    vec2 p,q,S=vec2(-24,31),v;//=p=q=S-S;
    L(p) L(q) v+=p*dot(C((p+q).yx*S),q);
    c.xy=C(v)+.02/(f-1.);
}
*/
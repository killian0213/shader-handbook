// Buf A (buffer) — [SH17A] 2tweet fluid by flockaroo
// https://www.shadertoy.com/view/4sSBRm

// created by florian berger (flockaroo) - 2017
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

// 2tweet fluid

// down to 261 chars - thx to Fabrice!
// down to 247 chars - thx to Fabrice!  --f doesnt work on my system

// try bigger numbers than 40 in line 15 for bigger vortices

#define C(x) texture(iChannel0,(f+x)/iResolution.xy).xy
//#define C(x) texelFetch(iChannel0,ivec2(f+x),0).xy

// -1 char: 11 is roughly 1.75pi so perfect -pi/4 substitute (instead of 1.6)
// -9 char: if S is chosen wisely the the difference between x and y is roughly (n+.5)*pi
#define L(b) for(float a=0.;a<5.;a++) { b=sin((iTime+a)/.1+S);
// -8 char: still works but less quality
//#define L(b) for(float a=0.;a<5.;a++) { b=sin(a/.1+S);

void mainImage(out vec4 c, vec2 f)
{
    // magic numbers: S.x-S.y must be roughly (n+.5)*pi, so we can use it as phase shift above
    vec2 p,q,v,S=vec2(27,-28);
    // v auto initializes to 0 on my system (might not work on some other platforms)
    //v-=v;
    L(p)
        L(q)
            v+=p*dot(C((p+q).yx*S),q);
        }
    }
    c.xy=C(v)+.1/(f-1.);
}

// Buffer A (buffer) — HODL by BigWIngs
// https://www.shadertoy.com/view/WtGBW1

// "HODL" 
// by Martijn Steinrucken aka The Art of Code/BigWings - 2021
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
// Email: countfrolic@gmail.com
// Twitter: @The_ArtOfCode
// YouTube: youtube.com/TheArtOfCodeIsCool
// Facebook: https://www.facebook.com/groups/theartofcode/
//
// Bitcoin texture. 
// I tried to make use of symmetries as much as possible
// but in the end its just a lot of detail that needs to be hand coded.

#define SS smoothstep
#define sat(x) clamp(x, 0., 1.)

float box(vec2 p, float x, float y, float z, float w, float b) {
	float 
        v = SS(x-b, x+b, p.x)*SS(z+b, z-b, p.x),
        h = SS(y-b, y+b, p.y)*SS(w+b, w-b, p.y);
    return v*h;
}

float sdBox(vec2 p, vec2 s) {
    p = abs(p)-s;
    return length(max(p, 0.)) + min(max(p.x, p.y), 0.);
}

float cir(vec2 uv, float x, float y, float r, float w, float b) {
	return SS(w+b, w-b, abs(r-length(uv-vec2(x, y))));
}

float r = .05;
float _A(vec2 uv) {return box(uv, .1, .1, .9, .5, r)-box(uv, .2, .1, .8, .4, r)+(box(uv, .15, .5, .8, .9, r)-box(uv, .25, .5, .7, .8, r));}
float _B(vec2 uv) {
    uv.y = abs(uv.y-.5);
    return max(min(box(uv, .1, -.1, .74, .4, r),1.-box(uv, .2, .05, .9, .3, r)), step(.675,uv.x)*cir(uv, .675, .175, .175, .05, r));
}
float _D(vec2 uv) {return box(uv, .1, .1, .9, .9, r)-box(uv, .2, .2, .8, .8, r);}
float _F(vec2 uv) {return box(uv, .1, .5, .9, .9, r)-box(uv, .2, .6, 1., .8, r)+box(uv, .1, .1, .2, .5, r);}
float _I(vec2 uv) {return box(uv, .1, .1, .2, .9, r);}
float _L(vec2 uv) {return max(box(uv, .1, .1, .9, .2, r), box(uv, .1, .1, .2, .9, r));}
float _O(vec2 uv) {return _D(uv);}
float _J(vec2 uv) {return min(_O(uv), 1.-box(uv, .0, .3, .8, 1.1, r));}
float _P(vec2 uv) {return box(uv, .1, .5, .9, .9, r)-box(uv, .2, .6, .8, .8, r)+box(uv, .1, .1, .2, .5, r);}
float _C(vec2 uv) {return min(_O(uv), 1.-box(uv, .5, .4, 1., .6, r));}
float _G(vec2 uv) {return max(min(_O(uv), 1.-box(uv, .5, .5, 1., .7, r)), box(uv, .6, .4, .9, .5, r));}
float _E(vec2 uv) {return box(uv, .1, .1, .9, .9, r)-box(uv, .2, .2, 1., .8, r)+box(uv, .2, .45, .9, .55, r);}
float _M(vec2 uv) {return box(uv, .1, .1, .9, .9, r)-box(uv, .2, .0, .8, .8, r)+box(uv, .45, .1, .55, .8, r);}
float _N(vec2 uv) {
    return max(box(vec2(abs(uv.x-.5),uv.y), .3, .1, .4, .9, r), 
               box(vec2(uv.x-(.9-uv.y)*.82, uv.y), .1, .1, .25, .9, r));
}
float _R(vec2 uv) {return _A(uv);}
float _S(vec2 uv) {
    float y = 1.-uv.x;
    y = y*y*y*.15;
    return max(min(max(box(uv, .1, .45, .9, .9, r)
        -box(uv, .2, .55, .8, .8, r),
        +box(uv, .8, .1, .9, .6, r)),
        1.-box(uv, .5, .55, 1., .7, r)),
               box(vec2(uv.x, uv.y-y), .1, .1, .9, .2, r));
}
float _T(vec2 uv) {return max(box(uv, .1, .8, .9, .9, r), box(uv, .45, .1, .55, .85, r));}
float _Y(vec2 uv) {return box(uv, .1, .5, .9, .9, r)-box(uv, .2, .6, .8, 1., r)+box(uv, .45, .1, .55, .5, r);}
float _Z(vec2 uv) {
    float y = abs(uv.y-.5);
    float x = uv.y>.5 ? uv.x : 1.-uv.x;
    return sat(box(vec2(x, y), .1, .3, .9, .4, r)+ 
               box(vec2(uv.y-uv.x*.95+.15, uv.y), .1, .2, .25, .8, r)+
             box(vec2(x,y), .1, .2, .2, .3, r));
}
float _dot(vec2 uv) { return SS(.3+r, .3-r, length(uv-vec2(.5)));}
float _ONE(vec2 uv) {return max(max(box(uv, .2, .1, .3, .9, r), box(uv, .1, .1, .4, .2, r)),box(vec2(uv.x, uv.y-uv.x*.5), .1, .66, .26, .785, r));}
float _NINE(vec2 uv) {return _P(vec2(1.-uv.x, uv.y));}

#define _w if(within(uv, c+=s, .0, c+w, 1.)) e +=
#define _d _w _dot(local(uv, c, .0, c+w, 1.));
#define _s _w 0.;
#define _1 _w _ONE(local(uv, c, .0, c+w, 1.));
#define _9 _w _NINE(local(uv, c, .0, c+w, 1.));
#define A _w _A(local(uv, c, .0, c+w, 1.));
#define B _w _B(local(uv, c, .0, c+w, 1.));
#define D _w _D(local(uv, c, .0, c+w, 1.));
#define E _w _E(local(uv, c, .0, c+w, 1.));
#define F _w _F(local(uv, c, .0, c+w, 1.));
#define G _w _G(local(uv, c, .0, c+w, 1.));
#define I _w _I(local(uv, c, .0, c+w, 1.)); c-=s*.75;
#define J _w _J(local(uv, c, .0, c+w, 1.));
#define L _w _L(local(uv, c, .0, c+w, 1.));
#define R _w _R(local(uv, c, .0, c+w, 1.));
#define S _w _S(local(uv, c, .0, c+w, 1.));
#define T _w _T(local(uv, c, .0, c+w, 1.));
#define C _w _C(local(uv, c, .0, c+w, 1.));
#define M _w _M(local(uv, c, .0, c+w, 1.));
#define N _w _N(local(uv, c, .0, c+w, 1.));
#define O _w _O(local(uv, c, .0, c+w, 1.));
#define P _w _P(local(uv, c, .0, c+w, 1.));
#define Y _w _Y(local(uv, c, .0, c+w, 1.));
#define Z _w _Z(local(uv, c, .0, c+w, 1.));

float Text(vec2 uv) {
    float 
        e = 0.,
        c = 0.,
        w = 1./76.,
        s = w *.9;
    
    if( uv.x<.536) {
        if(uv.x<.287) {
            if(uv.x<.145) {
                _1 T R O Y O Z _s _9 _9 _9 _s
            } else {
                c=.14;
                F I N E _s C O P P E R _s _s
            }
        } else {
            c=.287;
            if(uv.x<.445) {
                M J B _s M O N E T A R Y _s 
            } else {
                c=.44;
                M E T A L S _s _s
            }
        }
    } else {
        c = .532;

        if(uv.x<.70) {
            if(uv.x<.62) {
                B I T C O I N _d 
            } else {
                c = .61;
                D I G I T A L _d
            }
        } else {
            c=.687;

            if(uv.x<.857) {
                D E C E N T R A L I Z E D _d
            } else {
                c=.845;
                P E E R _s T O _s P E E R
            }
        }
    }
    return e;
}

float DooHicky(vec2 p, float reps, float h, float w, float x1, float y1, float x2, float y2) {
    float m = 0.;
    vec2 lp = local(p, x1,y1,x2,y2);
    if(lp.y>0. && lp.y<1.&&lp.x>0.&&lp.x<1.) {
        lp.x-=.5;
        lp.y = fract(lp.y*reps)-.5;
        float d = sdBox(lp, vec2(h));
        m = SS(.1,.0, d)*2.;
        m = max(m, SS(.05, .0, abs(abs(lp.x)-.15)-w));
    }
    return m*.5;
}

float Bitcoin(vec2 uv) {
    // https://www.shadertoy.com/view/WtGBW1
    vec2 m = iMouse.xy/iResolution.xy;
    //uv *= .4; uv -= (m-.5);
    
    float 
        e = 0., d, x, y, k, holes, rings, id;
    r = .05;
    
    vec2 
        st = vec2(atan(uv.x, uv.y)/6.283+.5, length(uv)),
        lp, //used for local coordinates
        p = uv;
    
    st.x = fract(st.x+.29);
    if(st.y>.425 && st.y<.462) {
     	e = Text(local(st, .0917, .425, 1., .462));
    } else if (st.y>.472 && st.y<.5) {
    	y = 1.-(abs(.486-st.y)/.014);
        e = sat(y*2.);
    }
    else 
    if(st.y>.4){ 
        x = fract(st.x*36.-.25);
        y = remap01(.4, .423, st.y);
        e = max(e, box(vec2(x, y), .15, .0, .85, 1., r));
        e = max(e, SS(.2, .1, abs(y-.5))*.5);
    } else { // center 
        d = sdBox(uv-vec2(-.063,-.198), vec2(.027, .1));  // bottom left
        d = min(d, sdBox(uv-vec2(.032,-.178), vec2(.027, .12))); // bottom right
        d = min(d, sdBox(uv-vec2(-.073,.171), vec2(.14, .028)));// top
        d = min(d, sdBox(uv-vec2(-.04+uv.y*.2,-.18-uv.x*.03), vec2(.12, .031)));//bottom
        d = min(d, sdBox(uv-vec2(-.07,.198), vec2(.027, .1))); // top left
        d = min(d, sdBox(uv-vec2(.021,.198), vec2(.028, .1))); // top left
        d = min(d, sdBox(uv, vec2(.135, .17))); // center fill
        d = min(d, length((uv-vec2(.075, .101))*vec2(.82,1))-.098);// top arc
        d = min(d, length((uv-vec2(.075, -.085))*vec2(.82,1))-.12);// bottom arc
        
        holes = length((uv-vec2(.02, .092))*vec2(.9,1))-.055;
        holes = min(holes, sdBox(uv-vec2(-.012,.092), vec2(.034, .055)));   
        holes = min(holes, length((uv-vec2(.04, -.084))*vec2(.8,1))-.06);
        holes = min(holes, sdBox(uv-vec2(-.0,-.084), vec2(.045, .06)));
        
        d = max(d, -holes);
 
        y = st.y*78.;
        id = floor(y);
        rings = fract(y)-.5;
        
        k = 18.
            +step(abs(st.x-.3)-.2, 0.)
            -step(abs(st.x-.6)-.05, 0.)*2.;
        if(d*holes>0. && (id>k||abs(uv.x)<.05)) {
            r = 0.;
            // concentric circles
            if(id>19.&&id<27. && mod(id,2.)==0.) { // resistors
                float len = .55/(id+1.);
                float s = remap01(20.,26., id);
                float ph = mix(.65, .5, pow(s, .8))+.18;
                x = fract(st.x*4.);
                r=SS(.01, .0, abs(x-ph)-len);
            }
            rings = SS(.2, .0, abs(rings)-r*.2)*mix(.5, 1., r);
            lp = uv-vec2(-.024,0);
                
            if(lp.y>.3&&lp.y<.35&&abs(lp.x)<.075) {
                x = remap(.3, .35, .075, .015, uv.y);
                k = step(0., abs(lp.x)-x);
                rings *= k;
                x = Min(abs(lp.x-.06), abs(lp.x-.044), abs(lp.x-.027));
                y = Min(abs(lp.x+.033), abs(lp.x+.054), abs(lp.x+.018));
                x = min(x, y);
                rings += (1.-k)*SS(.003,.0, x)*.5;
            } else if(lp.y<-.3 && lp.y>-.35) {
                lp.x -=.008;
                x = remap(-.3, -.35, .078, .015, uv.y);
                k = step(0., abs(lp.x)-x);
                rings *= k;
                x = Min(abs(lp.x-.065), abs(lp.x-.045), abs(lp.x-.028));
                y = Min(abs(lp.x+.032), abs(lp.x+.053), abs(lp.x+.018));
                x = min(x, y);
                rings += (1.-k)*SS(.003,.0, x)*.5;
            }
            e = max(e, rings);
        }
        
        e = max(e, SS(.005, .0, abs(d)));
        
        // stuff in holes
        if(holes<-.01) {
            lp = local(uv, -.038,-.139+.006,-.022-.005,.141-.004);
            if(lp.x>0.&& lp.x<1.&&lp.y>0.&&lp.y<1.) {
                y = lp.y;
                d = length(fract(lp*vec2(1,27))-.5);
                d = SS(.3, .0, d)*step(.05, abs(abs(y-.573)-.335));
                e = max(e, d);
            }
            e = max(e, DooHicky(uv, 1., .25, .01, -.032,-.137, -.008,-.114));
            e = max(e, DooHicky(uv, 1., .25, .01, -.032,.069, -.005,.046));
            
            d = sdBox(uv-vec2(.045, .097), vec2(.008,.012));
            d = min(d, sdBox(uv-vec2(-.028,.11), vec2(.001,.008))-.001);
            
            r = abs(sdBox(uv-vec2(-.015,.094), vec2(.03,.006))-.03)-.0005;
            d = min(d, max(r, -uv.x-.02));
            d = min(d, sdBox(vec2(abs(uv.x)-.012, uv.y-.113), vec2(.008,.012)));
            
            
            lp = uv-vec2(.017,-.014);
            lp.y = abs(lp.y)-.09;
            d = min(d, sdBox(lp, vec2(.014,.004)));
            d = max(d, -sdBox(lp, vec2(.005,.004)));
            // lines
            lp.x -= lp.y*.3-.01;
            lp.y = abs(lp.y-.0016)-.007;
            d = min(d, sdBox(lp, vec2(.028,.0)));
            
            x = abs(abs(uv.x-.03)-.026)-.013;
            d = min(d, sdBox(vec2(x, uv.y+.068), vec2(.007,.011))-.003);
           
            r = sdBox((uv-vec2(-.015,-.083))*vec2(1,1.4), vec2(.04,.0))-.055;
            r = max(r, uv.x-.056);
            
            r = abs(abs(r)-.011)-.0005;
            d = min(d, max(r, -uv.x-.02));
                  
            e = max(e, SS(.003,-.002, d)); 
        }
        
        x = abs(abs(uv.y-.03)-.022)-.011;
        d = sdBox(vec2(uv.x-.22, x), vec2(.013,.004))-.002; 
        d = min(d, sdBox(uv-vec2(.22, .095), vec2(.013,.015))-.002);
        d = max(d, length(uv)-.24);
        d = min(d, sdBox(uv-vec2(.22, .04), vec2(.001,.05))+.002);
        e = max(e, SS(.004, .0, d));
        
        lp = uv-vec2(-.28,-.037);
        
        if(uv.x<0.) {
            if(lp.y>.0) {
                e *= SS(.00, .001, Line(lp,vec2(-.017,.0125),vec2(.08,.105))-.022);
            
                d = Line(lp,vec2(0,0),vec2(-.034,.027));
                d = min(d, Line(lp,vec2(.026,0),vec2(-.021,.04)));
                d = min(d, Line(lp,vec2(.026,0.025),vec2(-.008,.052)));
                d = min(d, Line(lp,vec2(.04,0.037),vec2(.006,.065)));
                d = min(d, Line(lp,vec2(.066,0.037),vec2(.021,.078)));
                d = min(d, Line(lp,vec2(.068,0.062),vec2(.0365,.094)));
                d = min(d, Line(lp,vec2(.082,0.075),vec2(.055,.112)));
                d = min(d, Line(lp,vec2(.095,0.088),vec2(.075,.126)));
                
                lp.y = abs(lp.y-.135); 
                d = min(d, Line(lp,vec2(.11,.023),vec2(.14,.023)));
                d = min(d, Line(lp,vec2(.11,.023),vec2(.097,.0)));
            } else {
                d = Line(lp,vec2(.015,-.013),vec2(-.026,-.033));
                d = min(d, Line(lp,vec2(.03,-.025),vec2(-.009,-.047)));
                d = min(d, Line(lp,vec2(.045,-.038),vec2(.01,-.063)));
                d = min(d, Line(lp,vec2(.06,-.051),vec2(.031,-.08)));
                d = min(d, Line(lp,vec2(.04,-.072),vec2(.045,-.08)));
                d = min(d, Line(lp,vec2(.09,-.076),vec2(.07,-.09)));
                d = min(d, Line(lp,vec2(.09,-.12),vec2(.07,-.09)));
                      
               e *= SS(.00, .001, Line(lp,vec2(.04,-.06),vec2(-.018,-.01))-.022);
            }
            e = max(e, SS(.003, .0, d)*.5);
        } else {
            if(uv.y>-.07) {
                d = Line(uv,vec2(.38,.05),vec2(.3365,.106));
                d = min(d, Line(uv,vec2(.36,.05),vec2(.326,.095)));
                d = min(d, Line(uv,vec2(.362,.107),vec2(.349,.107)));
                d = min(d, Line(uv,vec2(.347,.038),vec2(.3175,.08)));
                d = min(d, Line(uv,vec2(.336,.026),vec2(.307,.067)));
                d = min(d, Line(uv,vec2(.325,.014),vec2(.2965,.054)));
                d = min(d, Line(uv,vec2(.314,.00),vec2(.286,.039)));
                d = min(d, Line(uv,vec2(.303,-.012),vec2(.275,.024)));
                d = min(d, Line(uv,vec2(.292,-.025),vec2(.263,.008)));
                d = min(d, Line(uv,vec2(.28,-.037),vec2(.25,-.01)));
                d = min(d, Line(uv,vec2(.27,-.05),vec2(.218,-.01)));
                e *= SS(.00, .001, Line(uv,vec2(.352,.08),vec2(.255,-.05))-.028);
            } else {
                d = Line(uv,vec2(.237,-.115),vec2(.278,-.076));
                d = min(d, Line(uv,vec2(.245,-.127),vec2(.288,-.088)));
                d = min(d, Line(uv,vec2(.252,-.141),vec2(.297,-.101)));
                d = min(d, Line(uv,vec2(.26,-.153),vec2(.306,-.114)));
                d = min(d, Line(uv,vec2(.267,-.165),vec2(.315,-.125)));
                e *= SS(.00, .001, Line(uv,vec2(.295,-.18),vec2(.323,-.14))-.01);
                e *= SS(.00, .001, Line(uv,vec2(.259,-.093),vec2(.291,-.147))-.03);
            }
            
            e = max(e, SS(.003, .0, d)*.5);   
        }
    }
    
     // straight lines
    y = remap01(-.132, .082, p.y);
    y += clamp(remap01(.45, .475, st.y),0.,1.)*.05;
   
    if(st.y<.475 && y>0. && y<1.) {
        bool 
            rightSide = (p.x-.197-.19*y>.0 && p.x-.321+.16*y>.0),
            leftSide = (p.x<-.14 && y>.05 && y<.88 && p.x+p.y*1.2>-.325 && p.x-p.y*1.1>-.24);
    
        if ( rightSide || leftSide) {
            y *= 17.;
            id = floor(y);
            y = fract(y)-.5;
            
            r = 0.;
            if(id==7.||id==9.||id==11.)
                r = SS(.002, .0, abs(p.x-.4)-.015);
                
            e = SS(.2, .0, abs(y)-.2*r)*mix(.5, 1., r);
            
            // diagonal lines
            d = sdBox(uv-vec2(.336,-.065), vec2(.03, .03));
            r = SS(-.2, .2, sin((uv.x+uv.y)*250.));
            r *= SS(.01, .0, d+.013);
            d = SS(.003,-.002, d)*.7+r;
            e = max(e, d); 
        }
        
        lp = (uv - vec2(.26,-.063))*.7;
        d = max(sdBox(lp, vec2(.014,.004)), -sdBox(lp, vec2(.005,.004)));
        e = max(e, SS(.003, .0, d));
    }
    
    e = max(e, DooHicky(p, 5., .35, .01, -.212,.02, -.159,-.107));
    e = max(e, DooHicky(p, 2., .35, .05, -.125,-.22, -.099,-.268));
    e = max(e, DooHicky(p, 2., .3, .05, -.143,.12, -.17,.076));
    e = max(e, DooHicky(p, 1., .3, .05, -.143,-.141, -.17,-.114));
   
    lp = vec2(p.x-step(p.y,0.)*.01, abs(p.y+.004));
    e = max(e, DooHicky(lp, 1., .2, .02, .045,.245, .095,.205));
    
    lp = vec2(p.x-step(p.y,0.)*.01, abs(p.y));
    e = max(e, DooHicky(lp, 2., .3, .02, -.045,.3, -.005,.35));
    
    return e;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
    float e = 0.;
    
    vec2 oldRes = texture(iChannel0, vec2(.5)/iResolution.xy).rg;
    
    if(oldRes.x!=iResolution.x)
        e = Bitcoin((fragCoord.xy-.5*iResolution.xy) / iResolution.y);   
    else
        e = texture(iChannel0, fragCoord.xy/iResolution.xy).r;
    
    if(fragCoord == vec2(1,1))
        fragColor = vec4(iResolution.xy, 0,0);
    else    
        fragColor = vec4(e);
}
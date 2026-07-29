// Buffer B (buffer) — The Great Gatsby Fractal by Yusef28
// https://www.shadertoy.com/view/lXXSz7


#define LEVELS 3.
#define EPS 2./iResolution.y
#define EPS_N 10./iResolution.y

#define SCALE 3.

/*

The checkerboard shifting: Deciding which of the two
circles in a cell will be on top and below. You start
with always the upper right circle ontop and 
the lower left below. Then view the cells as a checker
board and flip the order of all the white squares on 
the board.

The part that almost had me was shading because you
have to rotate the coordinate systems back the other
way but only after you do the checkerboard shifting and
creation of the circles. 

And THEN it still matters how you use atan since odd 
multiples of the result will show a discontinuity at 
the cell borders when passed through sin.

*/




vec2 concentricCircles(vec2 st, float r, float num, float type, vec2 checker,float scale){
    float d1 = 
            smax(dot(st,vec2(0.7,-0.7)),
            smax(dot(st,vec2(-0.7,0.7)),
            smax(dot(st,-vec2(0.7,0.7)),
            smax(dot(st,vec2(0.7,0.7)),
            smax(abs(st.x),
            abs(st.y),0.1),0.1),0.1),0.1),0.1);
    float d2 = length(st);
    
    float d = type < 0.90 
              ? mix(d1,d2,sin(iTime*1.9)*0.5+0.5)
              : mix(d2,d1,cos(iTime*1.99 + type)*0.5+0.5);
    float cutoff = smoothstep(r+EPS,r-EPS,d*(1.0+0.02*(scale-0.5)));
    float circles = sin(d*num*PI);
    return vec2(smoothstep(0.,1.,abs(circles*cutoff))+0.2*cutoff,d);
}

float overlappingConcentricCircles(vec2 st, float r, float num, vec2 checker, float a, float scale){
    float type = a;
    vec2 sp1 = st-vec2(1.,1.)+vec2(2.,2.)*checker;
    vec2 group_1 = concentricCircles(sp1, r, num,type,checker,scale);
    vec2 sp2 = st+vec2(1.,1.)-vec2(2.,2.)*checker;
    vec2 group_2 = concentricCircles(sp2, r, num, type,checker,scale);
    
    float total = mix(group_1.x, group_2.x, smoothstep(0.1,0.2,group_2.x));
    
    
    return total;
}
float quadTree(vec2 st){

    float s = 1.;
    float seed;
    vec2 fr, fl;
    float circle_num =  4.;
    for(float i = 0.; i <= LEVELS; i ++){
        fr = fract(st)-0.5;
        fl = floor(st);
        seed = rnd(fl); 
        seed = seed + 0.2*mod(fl.x,2.) + 0.2*mod(fl.y,2.);
        if( seed > 0.7 || LEVELS - i == 1.){
            float a =  (floor(rnd(fl*325.2435)*4.)/4.)*PI*2.;
            fr *= rot(a);
            return overlappingConcentricCircles(fr*2.,
                                                2., 
                                                circle_num,
                                                mod(fl,2.),
                                                a,
                                                s);
        }
        
        s *= 2.;
        st *= 2.;
        circle_num /= 2.;
    }
    return 1.;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = (fragCoord.xy-iResolution.xy*0.5)/iResolution.y;
    vec3 col;

    float d = quadTree(uv*SCALE);

    col = mix(vec3(0.,0.,0.), vec3(0.7,0.1,0.1)*1.3,  smoothstep(0.59,.6,d)); 
    //col = mix(col, vec3(0.45,0.3,0.1)*0.8, smoothstep(0.3,0.299,d));
    //col = mix(col, vec3(0.), smoothstep(0.,3.9,d));
    col = mix(col, vec3(0.1), smoothstep(.8,.3,abs(d-0.6)));
    fragColor = vec4(col,1.0);
}
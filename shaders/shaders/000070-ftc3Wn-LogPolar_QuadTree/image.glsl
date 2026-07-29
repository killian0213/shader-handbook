// Image (image) — LogPolar QuadTree by byt3_m3chanic
// https://www.shadertoy.com/view/ftc3Wn

/**
    License: Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License

    Draft Quadtree [learning number 3]
    11/4/21 @byt3_m3chanic

    throwing it into a log polar transform.
    It's hard to make the design more complex and 
    still look good as it scales, but this was 
    just poking around to see what else you can do.
    
    @Shane has a good example that explains quadtrees
    which is what I used to create this shader.
    https://www.shadertoy.com/view/llcBD7
 
*/

#define R          iResolution
#define M          iMouse
#define T          iTime
#define PI         3.14159265359
#define PI2        6.28318530718

mat2 rot (float a) { return mat2(cos(a),sin(a),-sin(a),cos(a)); }
float hash21(vec2 p){ return fract(sin(dot(p,vec2(26.34,45.32)))*4324.23); }

vec3 hue(float t){ 
    const vec3 d = vec3(0.067,0.812,0.910);
    return .55 + .45*cos(PI2*t*(vec3(.95,.97,.98)*d)); 
}

float box( in vec2 p, in vec2 b ){
    vec2 d = abs(p)-b;
    return length(max(d,0.0)) + min(max(d.x,d.y),0.0);
}

void mainImage( out vec4 O, in vec2 F ) {

    vec2 uv = (2.*F.xy-R.xy)/max(R.x,R.y);
    vec2 vuv= uv*rot(T*.05);

    vuv=vec2(log(length(vuv)), atan(vuv.y, vuv.x))*3.5;
    vuv.x+=T*.25;
    
    float px = fwidth(vuv.x);
    float level=1.;

    vec3 C = vec3(.0325);
    float mask = smoothstep(.65,.0,length(uv)-.2);
    C = mix(C, vec3(.125),mask);
    
    for(int k=0; k<5; k++){
        vec2 id = floor(vuv*level);
        float rnd = hash21(id);
        
        // threshold or if last loop
        if(rnd>.45||k>3) {

            vec2 p = vuv -(id+.5)/level;
            rnd = hash21(rnd+id.yx);

            float d = smoothstep(px,-px,length(p)-.455/level);
            float s = length(p)-.425/level;
 
            if(rnd<.675) {
                if(rnd>.2) s=abs(s)-.05/level;
                s = smoothstep(px,-px,s);
                C=mix(C,hue((id.y*.05)+float(k+1)*.25),s);
            } else {
                C=mix(C,vec3(.2),d);
                            
                if(hash21(rnd+id)>.8) {
                    p*=rot(rnd+T*.5);
                    vec2 cs = vec2(.3,.075)/level;
                    float cx=min(box(p,cs.yx),box(p,cs));
                    C=mix(C,vec3(.8),smoothstep(px,-px,cx));
                }
            }

            break;
        }
        level*=2.;
    }
    
    C = pow(C, vec3(.4545));        
    O = vec4(C,1.0);
}


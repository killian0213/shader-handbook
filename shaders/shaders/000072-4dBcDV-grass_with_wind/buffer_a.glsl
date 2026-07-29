// Buffer A (buffer) — grass with wind by kev7774
// https://www.shadertoy.com/view/4dBcDV

//Adds "fuzz" underneath the grass to cover up the ground when you look down. (range 0.0 - 1.0)
//Looks fine with no fuzz, but 0.2 is a good value to try.   0.5 and higher looks weird.
//NEED TO RESET TIME TO SEE RESULT
#define FUZZ .0

#define PREVIEWSCALE (iResolution.y > 271. ? 1. : .5)

//simple nonlinear function for hashing
float curve(float x)
{
     return x * (x*x + 3.0);
}

#define HASHSCALE (2.711651661)

float rand(vec2 p) {
    p = fract(p*HASHSCALE);
    return fract(curve( p.x + p.y * .618034) * 43758.5453);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    
    if(iFrame > 3){
        fragColor = texture(iChannel0, fragCoord/iResolution.xy);
        return;
    }

    fragCoord = floor(fragCoord);
    
    if(fragCoord.x >= PREVIEWSCALE * 400. && fragCoord.x < (PREVIEWSCALE *400.) + 34. && fragCoord.y < 34.){
        vec2 uv1 = fragCoord - vec2(PREVIEWSCALE*400.,0.);
        uv1 *= PREVIEWSCALE * 8.;
        uv1 += vec2(.5);
        
        vec3 sum = vec3(0.);
        for(int x=0; x<4; x++){
            for(int y=0; y<4; y++){
                vec2 uv2 = uv1 + vec2(float(x*2), float(y*2));
                sum += texture(iChannel0, uv2/iResolution.xy).xyz;
            }
        }
        fragColor = vec4(sum/16., 1.);
        return;
    }
    
    fragCoord = mod(fragCoord, PREVIEWSCALE*vec2(256.,256.));
    
    float m = rand(fragCoord);
    float n = rand(fragCoord + vec2(0.,1.));
    float e = rand(fragCoord + vec2(1.,0.));
    float s = rand(fragCoord + vec2(0.,-1.));
    float w = rand(fragCoord + vec2(-1.,0.));
    
    float ne = rand(fragCoord + vec2(1.,1.));
    float se = rand(fragCoord + vec2(1.,-1.));
    float sw = rand(fragCoord + vec2(-1.,-1.));
    float nw = rand(fragCoord + vec2(-1.,1.));
    
    float res = 1.;
    
    res = (m > n) ? res : 0.;
    res = (m > e) ? res : 0.;
    res = (m > s) ? res : 0.;
    res = (m > w) ? res : 0.;
    
    res = (m > ne) ? res : 0.; 
    //res = (m > se) ? res : 0.;
    res = (m > sw) ? res : 0.;
    //res = (m > nw) ? res : 0.;
    
    float h = rand(fragCoord * vec2(2.24722,7.16163) + vec2(31.12515, 59.1616));
    /*
    h = h*2.-1.;
    h = h*h*h;
    h = h*.5+.5;
    res = h * (.75*res+.25);
    */
    res = mix(res,1.,FUZZ) * sqrt(h);
    
    float r1 = rand(fragCoord * vec2(4.23236,11.843583) + vec2(61.1261661, 22.724727));
    float r2 = rand(fragCoord * vec2(7.8645,3.274247) + vec2(171.2437247, 54.23724372));
    
    vec3 col = mix(vec3(.2,1.,.3), vec3(.42,.86,.15), r1);
    
    col = mix(col, vec3(.05,.65,.10), r2*r2);
    
    fragColor = vec4(col, res);
}
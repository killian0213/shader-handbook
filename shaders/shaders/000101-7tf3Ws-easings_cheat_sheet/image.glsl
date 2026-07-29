// Image (image) — easings_cheat_sheet by skaplun
// https://www.shadertoy.com/view/7tf3Ws

#define AA 20./iResolution.x
#define AA2 7./iResolution
vec2 ASPECT;

const vec2 GRAD_OFFS = vec2(0.001, 0);
#define DISP_SCALE 2.
#define LINE_SIZE 10.
#define GRAD(f, p) (vec2(f(p) - f(p + GRAD_OFFS.xy), f(p) - f(p + GRAD_OFFS.yx)) / GRAD_OFFS.xx)
#define PLOT(f, p) return smoothstep(0.0, (LINE_SIZE / iResolution.y * DISP_SCALE), abs(f(p) / length(GRAD(f,p))))

float plot(vec2 uv, int id){
    switch(id){
        case 0:  PLOT(easeInSine, uv); break;
        case 1:  PLOT(easeOutSine, uv); break;
        case 2:  PLOT(easeInOutSine, uv); break;
        case 3:  PLOT(easeInQuad, uv); break;
        case 4:  PLOT(easeOutQuad, uv); break;
        case 5:  PLOT(easeInOutQuad, uv); break;
        case 6:  PLOT(easeInCubic, uv); break;
        case 7:  PLOT(easeOutCubic, uv); break;
        case 8:  PLOT(easeInOutCubic, uv); break;
        case 9:  PLOT(easeInQuart, uv); break;
        case 10: PLOT(easeOutQuart, uv); break;
        case 11: PLOT(easeInOutQuart, uv); break;
        case 12: PLOT(easeInQuint, uv); break;
        case 13: PLOT(easeOutQuint, uv); break;
        case 14: PLOT(easeInOutQuint, uv); break;
        case 15: PLOT(easeInExpo, uv); break;
        case 16: PLOT(easeOutExpo, uv); break;
        case 17: PLOT(easeInOutExpo, uv); break;
        case 18: PLOT(easeInCirc, uv); break;
        case 19: PLOT(easeOutCirc, uv); break;
        case 20: PLOT(easeInOutCirc, uv); break;
        case 21: PLOT(easeInBack, uv); break;
        case 22: PLOT(easeOutBack, uv); break;
        case 23: PLOT(easeInOutBack, uv); break;
        case 24: PLOT(easeInElastic, uv); break;
        case 25: PLOT(easeOutElastic, uv); break;
        case 26: PLOT(easeInOutElastic, uv); break;
        case 27: PLOT(easeInBounce, uv); break;
        case 28: PLOT(easeOutBounce, uv); break;
        case 29: PLOT(easeInOutBounce, uv); break;
        default:;
    }
}

float fun(float phase, int id){
    switch(id){
        case 0:  return easeInSine(phase);
        case 1:  return easeOutSine(phase);
        case 2:  return easeInOutSine(phase);
        case 3:  return easeInQuad(phase);
        case 4:  return easeOutQuad(phase);
        case 5:  return easeInOutQuad(phase);
        case 6:  return easeInCubic(phase);
        case 7:  return easeOutCubic(phase);
        case 8:  return easeInOutCubic(phase);
        case 9:  return easeInQuart(phase);
        case 10: return easeOutQuart(phase);
        case 11: return easeInOutQuart(phase);
        case 12: return easeInQuint(phase);
        case 13: return easeOutQuint(phase);
        case 14: return easeInOutQuint(phase);
        case 15: return easeInExpo(phase);
        case 16: return easeOutExpo(phase);
        case 17: return easeInOutExpo(phase);
        case 18: return easeInCirc(phase);
        case 19: return easeOutCirc(phase);
        case 20: return easeInOutCirc(phase);
        case 21: return easeInBack(phase);
        case 22: return easeOutBack(phase);
        case 23: return easeInOutBack(phase);
        case 24: return easeInElastic(phase);
        case 25: return easeOutElastic(phase);
        case 26: return easeInOutElastic(phase);
        case 27: return easeInBounce(phase);
        case 28: return easeOutBounce(phase);
        case 29: return easeInOutBounce(phase);
        default: return 0.;
    }
}

const float BG = .2;
const float WIDTH = .05;
vec3 cell(vec2 uv, int id, float time){
    vec3 res = vec3(BG);
    float p = max(smoothstep(AA2.y, 0., distance(uv.y, 0.)) * smoothstep(.5 + AA2.x, .5, distance(uv.x, .5)),
                  smoothstep(AA2.x, 0., distance(uv.x, 0.)) * smoothstep(.5 + AA2.y, .5, distance(uv.y, .5)));
    res = mix(res, vec3(.8), p);
    res = mix(res, vec3(.8), smoothstep(AA2.y, 0., distance(uv.y, -.4)) * smoothstep(.5 + AA2.x, .5, distance(uv.x, .5)));
    res = mix(res, vec3(.5, .5, 0.), smoothstep(AA, 0., distance(uv.x, uv.y)) * smoothstep(.5 + AA2.x, .5, distance(uv.x, .5)));
    
    float t = fun(time, id);
    vec3 pltClr = mix(vec3(1., 0., 0.), vec3(.8), smoothstep(uv.x, uv.x + AA2.x, time));
    float pl = plot(uv, id);
    res = mix(pltClr, res, pl);
    
    res = mix(res, vec3(.2), smoothstep(.5, .5 + AA, distance(uv.x, .5)));
    
    float l = length((uv - vec2(t, -.4)) * ASPECT);
    res = mix(res, vec3(.8), smoothstep(.25 + AA2.y, .25, l));
    res = mix(res, vec3(.4 + .4 * l), smoothstep(.2 + AA2.y, .2, l));
    return res;
}

const vec2 ITEMS_COUNT = vec2(6., 5.);
const vec2 GRID_SIZE = vec2(1.)/ITEMS_COUNT;
void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord/iResolution.xy;
    vec2 gs = GRID_SIZE;
    
    
    vec2 c = floor(uv/gs);
    int id = int(ITEMS_COUNT.x) * int(c.y) + int(c.x);
    
    ASPECT = iResolution.xy/min(iResolution.x, iResolution.y) * GRID_SIZE/GRID_SIZE.y;
    vec2 muv = mod(uv, gs)/gs;
    
    float time = clamp(mod(iTime, 2.)/1.5, 0., 1.);
    vec2 offset = vec2(.5, .9);
    ASPECT *= vec2(1.2, 1.);
    fragColor = vec4(cell(muv * (1. + offset) - offset * .5 - vec2(0., offset.y * .25), id, time), 1.);
}
// Image (image) — alternative alternation by phi16
// https://www.shadertoy.com/view/wts3Dn

float eb(float x) {
    x = 1. - x;
    float y = x*x*(3.*x-2.);
    return 1. - y;
}
float rand(vec2 co){
    return fract(sin(dot(co.xy, vec2(12.9898,78.233))) * 43758.5453);
}

float getBound(vec2 seed, float i) {
    float p = rand(seed.xy + 1.);
    if(i < 1.) {
    	return rand(seed) * 0.1 + 0.4;
    }
    if(i > 1.0) {
	    if(p < 0.07) return 0.;
    	if(p > 0.93) return 1.;
    }
    return rand(seed) * 0.4 + 0.3;
}
float getBound(vec2 seed1, vec2 seed2, float intv, float i) {
    float v1 = getBound(seed1, i);
    float v2 = getBound(seed2, i);
    return mix(v1,v2,eb(clamp(intv*2.0-i*0.3-rand(seed1)*0.2,0.,1.)));
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = (fragCoord - iResolution.xy * 0.5)/iResolution.y*2.1;
    vec2 ouv = uv;
    vec3 col = vec3(1);
    float ti = iTime * 2.0;
    vec2 seed1 = vec2(floor(ti),1);
    vec2 seed2 = vec2(floor(ti)+1.,1);
    vec2 le1 = vec2(floor(rand(seed1.yx)*16.),floor(rand(seed1.xx)*16.))/16.;
    vec2 le2 = vec2(floor(rand(seed2.yx)*16.),floor(rand(seed2.xx)*16.))/16.;

    float intv = fract(ti);
    float ttv = intv;
    if(abs(uv.x) > 2.0 || abs(uv.y) > 1.0) {
    } else {
        float dif = 1.0;
        uv = uv * vec2(0.25,0.5) + 0.5;
        vec2 center1 = vec2(0.5,0.5);
        vec2 size1 = vec2(1,1);
        vec2 center2 = vec2(0.5,0.5);
        vec2 size2 = vec2(1,1);
        for(int i=0;i<8;i++) {
            float boundX = getBound(seed1,seed2,intv,float(i));
            float boundX1 = getBound(seed1, float(i));
            float boundX2 = getBound(seed2, float(i));
            center1.x -= (0.5 - boundX1) * size1.x;
            center2.x -= (0.5 - boundX2) * size2.x;
            if(uv.x < boundX) {
                uv.x /= boundX;
                seed1.x += dif, seed2.x += dif;
                size1.x *= boundX1, size2.x *= boundX2;
                center1.x -= size1.x * 0.5, center2.x -= size2.x * 0.5;
            } else {
                uv.x = (uv.x - boundX) / (1. - boundX);
                seed1.x -= dif, seed2.x -= dif;
                size1.x *= 1. - boundX1, size2.x *= 1. - boundX2;
                center1.x += size1.x * 0.5, center2.x += size2.x * 0.5;
                intv += 0.15 * dif;
            }
	        seed1 = seed1.yx;
	        seed2 = seed2.yx;
            dif /= 2.0;
            
            if(i > 0) {
                float boundY = getBound(seed1, seed2, intv, float(i));
                float boundY1 = getBound(seed1, float(i));
                float boundY2 = getBound(seed2, float(i));
                center1.y -= (0.5 - boundY1) * size1.y;
                center2.y -= (0.5 - boundY2) * size2.y;
                if(uv.y < boundY) {
                    uv.y /= boundY;
                    seed1.y += dif, seed2.y += dif;
                    size1.y *= boundY1, size2.y *= boundY2;
                    center1.y -= size1.y * 0.5, center2.y -= size2.y * 0.5;
                } else {
                    uv.y = (uv.y - boundY) / (1. - boundY);
                    seed1.y -= dif, seed2.y -= dif;
                    size1.y *= 1. - boundY1, size2.y *= 1. - boundY2;
                    center1.y += size1.y * 0.5, center2.y += size2.y * 0.5;
                    intv += 0.15 * dif;
                }
            }
            seed1 = seed1.yx;
            seed2 = seed2.yx;
            dif /= 2.0;
        }
        vec2 coord0 = (center1-vec2(0.25,0))/vec2(8.0,16.0);
        vec2 coord1 = (center2-vec2(0.25,0))/vec2(8.0,16.0);
        coord0 = clamp(coord0, 0., 1./16.);
        coord1 = clamp(coord1, 0., 1./16.);
        vec4 c0 = texture(iChannel0, coord0+le1).xyzw;
        vec4 c1 = texture(iChannel0, coord1+le2).xyzw;
        ttv = smoothstep(0.,1.,-0.7 + ttv*4.0 - rand(center1)*2.0);
        float ld = rand(seed1+seed2) < 0.5 ? 1. : 0.;
        float ldu = rand(seed1-seed2) < 0.5 ? 1. : 0.;
        float lb = mix(1.,-1.,ldu);
        float mixParam = ld < 0.5
            ? step(uv.x, lb*ttv+ldu)
            : step(uv.y, lb*ttv+ldu);
        col *= 1. - mix(c1.x,c0.x,mixParam);
    }
    fragColor = vec4(col,1.0);
}
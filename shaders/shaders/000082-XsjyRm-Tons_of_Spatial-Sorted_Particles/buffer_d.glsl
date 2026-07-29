// Buffer D (buffer) — Tons of Spatial-Sorted Particles by cornusammonis
// https://www.shadertoy.com/view/XsjyRm

#define T(d) texelFetch(iChannel0, d, 0).xy
#define D(d) texelFetch(iChannel1, d, 0)
#define R(v) (vec2(v) / iResolution.xy)

#define WINDOW 3  // half-width of the square accumulation window
#define WIDTH (WINDOW * 2 + 1)
#define DIM (WIDTH * WIDTH)

#define TC 0.95  // time constant of the accumulator

//#define CHECK_CLOSEST_NEIGHBORS // (EXPENSIVE) check the neighborhoods of closest points for neighboring pixels

void findClosest(ivec2 iuv, vec2 uv, inout float gravity, inout float minDist, inout vec2 closest) {
    for (int i = -WINDOW; i <= WINDOW; i++) {
        for (int j = -WINDOW; j <= WINDOW; j++) {
            vec2 pos = T(iuv + ivec2(i,j));
            float dist = distance(uv, pos);
            
            gravity += 1.0 / (dist*dist);
            
            if (dist < minDist) {
            	minDist = dist;
                closest = pos;
            }
        }
    }    
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord / iResolution.xy;
    ivec2 iuv = ivec2(fragCoord);
    vec2 tx = 1.0 / iResolution.xy;
    
    ivec2 iRes = ivec2(iResolution.xy);
    
    float gravity = 0.0;
    float minDist = 1e6;
    
    vec4 prevVec = D(iuv);
    vec2 prevClosest = prevVec.xy;
    
    vec2 closest = vec2(1e6);
    
    vec2 closestNeighbors[DIM + 1];
    
    closestNeighbors[0] = prevClosest;

    int index = 0;
    for (int i = -WINDOW; i <= WINDOW; i++) {
        for (int j = -WINDOW; j <= WINDOW; j++) {
            vec2 pos = T(iuv + ivec2(i,j));
            vec2 nClosest = D(iuv + ivec2(i,j)).xy;
            closestNeighbors[index] = nClosest;
            float dist = distance(uv, pos);
            
            gravity += 1.0 / (dist*dist);
            
            if (dist < minDist) {
            	minDist = dist;
                closest = pos;
            }
            index++;
        }
    }

	#ifdef CHECK_CLOSEST_NEIGHBORS
    for (int i = 0; i <= DIM; i++) {
    	vec2 pos = closestNeighbors[i];
        ivec2 ipos = ivec2(iResolution.xy * pos);
        findClosest(ipos, uv, gravity, minDist, closest);
    }
    #endif
    
    vec2 ewma;
    if (prevVec.zw == vec2(0)) {
        ewma = vec2(0.0, minDist);
    } else {
        float gravp = clamp(0.00000001 * gravity,0.0,1.0);
        ewma = TC * prevVec.zw + (1.0 - TC) * vec2(gravp, minDist);
    }

    fragColor = vec4(closest, ewma);    

}
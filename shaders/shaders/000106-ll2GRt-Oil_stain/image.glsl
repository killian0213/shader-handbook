// Image (image) — Oil stain by noby
// https://www.shadertoy.com/view/ll2GRt

//#define INVERT
mat2 rot2d(float angle){return mat2(cos(angle),-sin(angle),sin(angle),cos(angle));}
float r(float a, float b){return fract(sin(dot(vec2(a,b),vec2(12.9898,78.233)))*43758.5453);}
float h(float a){return fract(sin(dot(a,dot(12.9898,78.233)))*43758.5453);}

float noise(vec3 x){
    vec3 p  = floor(x);
    vec3 f  = fract(x);
    f       = f*f*(3.0-2.0*f);
    float n = p.x + p.y*57.0 + 113.0*p.z;
    return mix(mix(mix( h(n+0.0), h(n+1.0),f.x),
                   mix( h(n+57.0), h(n+58.0),f.x),f.y),
               mix(mix( h(n+113.0), h(n+114.0),f.x),
                   mix( h(n+170.0), h(n+171.0),f.x),f.y),f.z);
}

// https://iquilezles.org/articles/morenoise
// http://www.pouet.net/topic.php?post=401468
vec3 dnoise2f(vec2 p){
    float i = floor(p.x), j = floor(p.y);
    float u = p.x-i, v = p.y-j;
    float du = 30.*u*u*(u*(u-2.)+1.);
    float dv = 30.*v*v*(v*(v-2.)+1.);
    u=u*u*u*(u*(u*6.-15.)+10.);
    v=v*v*v*(v*(v*6.-15.)+10.);
    float a = r(i,     j    );
    float b = r(i+1.0, j    );
    float c = r(i,     j+1.0);
    float d = r(i+1.0, j+1.0);
    float k0 = a;
    float k1 = b-a;
    float k2 = c-a;
    float k3 = a-b-c+d;
    return vec3(k0 + k1*u + k2*v + k3*u*v,
                du*(k1 + k3*v),
                dv*(k2 + k3*u));
}

float fbm(vec2 uv){               
    vec2 p = uv;
	float f, dx, dz, w = 0.5;
    f = dx = dz = 0.0;
    for(int i = 0; i < 28; ++i){        
        vec3 n = dnoise2f(uv);
        dx += n.y;
        dz += n.z;
        f += w * n.x / (1.0 + dx*dx + dz*dz);
        w *= 0.86;
        uv *= vec2(1.16);
        uv *= rot2d(1.25*noise(vec3(p*0.1, 0.12*iTime))+
                    0.75*noise(vec3(p*0.1, 0.20*iTime)));
    }
    return f;
}

float fbmLow(vec2 uv){
    float f, dx, dz, w = 0.5;
    f = dx = dz = 0.0;
    for(int i = 0; i < 4; ++i){        
        vec3 n = dnoise2f(uv);
        dx += n.y;
        dz += n.z;
        f += w * n.x / (1.0 + dx*dx + dz*dz);
        w *= 0.75;
        uv *= vec2(1.5);
    }
    return f;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord){
	vec2 uv = 1.0-2.0*(fragCoord.xy / iResolution.xy);
    uv.y /= iResolution.x/iResolution.y;
    float t = iTime*0.6;
    
    vec2 rv = uv/(length(uv*2.5)*(uv*30.0));
    uv *= rot2d(0.3*t);
    float val = 0.5*fbm(uv*2.0*fbmLow(length(uv)+rv-t));
    uv *= rot2d(-0.6*t);
    
    #ifdef INVERT
    	fragColor = 1.0-1.2*vec4( vec3(0.5*fbm(uv*val*8.0)+0.02*r(uv.x,uv.y)), 1.0 );
    #else
    	fragColor = 1.6*vec4( vec3(0.5*fbm(uv*val*8.0)+0.02*r(uv.x,uv.y)), 1.0 );
    #endif
    
    fragColor.rgb *= 3.8;
    fragColor.rgb = fragColor.rgb/(1.0+fragColor.rgb);
    fragColor.rgb = smoothstep(0.18, 0.88, fragColor.rgb);
    //fragColor.rgb = pow(fragColor.rgb, vec3(1.0/2.2));
}
// Image (image) — Reflective Interference by pyBlob
// https://www.shadertoy.com/view/ldGfRz

const float PI = radians(180.);

float height(vec2 uv)
{
    float h = length(texture(iChannel0, uv).xyz);
    return 0.5e-6 + 2.0e-6 * h;
}

float height2(vec2 uv)
{
    return 5e-6 * uv.x;
}

const int bands = 5;
const float f1 = 0.5; // 1st reflection
const float f2 = 1.0; // 2nd reflection

vec2 light(float w, float s)
{
    s *= 2.0*PI/w;
    return vec2(cos(s), sin(s));
}

float power(vec2 l)
{
    return dot(l, l);
}

float interference(float w, float wd, float h)
{
    float tot = 0.0;
    for (int i=-bands ; i<=bands ; i++)
    {
        float id = float(i)/float(bands);
        float cw = w + wd * id;
        
        vec2 l = vec2(0); // light/phase
        float f = 1.0; // alpha

        // 1st, distance = 0  , shift = PI
        l += -light(cw, 0.0*h) * f * f1;
        f *= 1.0-f1;

        // 2nd, distance = 2*h, shift = 0
        l += +light(cw, 2.0*h) * f * f2;
        f *= 1.0-f2;

    	float sensitivity = cos(id * PI)+1.0;
        tot += sensitivity * power(l) / float(bands*2+1);
    }
    return tot;
}

vec3 measure(float h)
{
    return vec3(
        interference(650e-9, 60e-9, h),
        interference(532e-9, 40e-9, h),
        interference(441e-9, 30e-9, h)
	);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord/iResolution.xy;
    vec3 col = vec3(0.0);

    float cut = iMouse.y/iResolution.y;
    if (cut == 0.0)
        cut = 0.5;
    if (uv.y <= 0.1)
    {
        col = measure(height(vec2(uv.x, cut)));
    }
    else if (uv.y <= 0.2)
    {
        float y = (uv.y-0.1)/0.1;
        vec2 muv = vec2(uv.x, cut);
        col = measure(height(muv));
        vec3 dc = 
            measure(height(muv+vec2(0.5/iResolution.x,0.0))) -
            measure(height(muv-vec2(0.5/iResolution.x,0.0)))
            ;
        col = mix(vec3(1.0), vec3(0.0), smoothstep(0.0, 10.0/iResolution.y, abs(col-vec3(y))-abs(dc*0.5)));
    }
    else if (uv.y <= 0.8)
    {
        col = measure(height(uv));
        col = sqrt(col);
        col = mix(vec3(1.0), col, smoothstep(0.0, 0.5/iResolution.y, abs(uv.y-cut)-0.5/iResolution.y));
    }
    else if (uv.y <= 0.9)
    {
        float y = (uv.y-0.8)/0.1;
        vec2 muv = uv;
        col = measure(height2(muv));
        vec3 dc = 
            measure(height2(muv+vec2(0.5/iResolution.x,0.0))) -
            measure(height2(muv-vec2(0.5/iResolution.x,0.0)))
            ;
        col = mix(vec3(1.0), vec3(0.0), smoothstep(0.0, 10.0/iResolution.y, abs(col-vec3(y))-abs(dc*0.5)));
    }
    else
    {
        col = measure(height2(uv));
    }

    fragColor = vec4(pow(col, vec3(1./2.2)), 1.0);
}
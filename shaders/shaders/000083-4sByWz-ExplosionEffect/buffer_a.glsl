// Buf A (buffer) — ExplosionEffect by kuvkar
// https://www.shadertoy.com/view/4sByWz

/***
 * Explosion effect. A volumetric torus, where I rotate the sample positions in the torus 
   around it's radius.
   
   Finding nice looking colors was perhaps the most difficult part and took me a while.
   In the end adding the bloom made this work colorwise.
*/

mat3 rotx(float a) { mat3 rot; rot[0] = vec3(1.0, 0.0, 0.0); rot[1] = vec3(0.0, cos(a), -sin(a)); rot[2] = vec3(0.0, sin(a), cos(a)); return rot; }
mat3 roty(float a) { mat3 rot; rot[0] = vec3(cos(a), 0.0, sin(a)); rot[1] = vec3(0.0, 1.0, 0.0); rot[2] = vec3(-sin(a), 0.0, cos(a)); return rot; }
mat3 rotz(float a) { mat3 rot; rot[0] = vec3(cos(a), -sin(a), 0.0); rot[1] = vec3(sin(a), cos(a), 0.0); rot[2] = vec3(0.0, 0.0, 1.0); return rot; }

#define PI 3.14159265358
#define SAMPLE samplePos3D 
const vec3 up =  vec3(0.0, 1.0, 0.01);

float RADIUS = 0.;
float THICKNESS = 0.0;
float T = 0.0;
float ROTATION_T = 0.0;
float DECAY = .0;

// https://iquilezles.org/articles/distfunctions
float sdTorus( vec3 p, vec2 t )
{
  vec2 q = vec2(length(p.xz)-t.x,p.y);
  return length(q)-t.y;
}


// from IQ, various places where 3d noise is used.
// Without smoothing, in hope to gain a bit of performance.
float noise( in vec3 x )
{
    vec3 p = floor(x);
    vec3 f = fract(x);
	vec2 uv = (p.xy+vec2(37.0,17.0)*p.z) + f.xy;
	vec2 rg = textureLod( iChannel1, (uv+ 0.5)/256.0, 0. ).yx;
	return mix( rg.x, rg.y, f.z );
}


float map(in vec3 rp)
{
    vec3 v =  cos(T*.15+rp*15.)+ sin(T*.25+rp*10.);
    return sdTorus(rp, vec2(RADIUS, THICKNESS))-dot(v, v)*.005;
}

float mapLo(in vec3 rp)
{
    return sdTorus(rp, vec2(RADIUS, THICKNESS))*.005;
}


/////
// rotates the volume inside the torus, to get the smoke rolling effect.
/////
mat3 rot;
vec3 samplePos3D(in vec3 rp)
{
    vec3 fw = normalize(vec3(rp.x, 0.0, rp.z));
    vec3 pIn = fw * RADIUS;
    vec3 rt =  cross(fw, up);

    vec3 localP = rp-pIn;
    rot[0] = fw; rot[1] = up; rot[2] = rt;
    localP = transpose(rot) * localP; 
    localP = rotz(-ROTATION_T) * localP;
    localP = rot * localP;
    return (localP+pIn);
}

// actual volume sampling
float sampleVolume(in vec3 rp)
{
    float t = map(rp);
    t = -smoothstep(0., -THICKNESS*.5, t);
    float d = noise(SAMPLE(rp)*22.)*.8;
    d += noise(SAMPLE(rp)*70.)*.4;
    d += noise(SAMPLE(rp)*100.)*.2;
    d += noise(SAMPLE(rp)*350.)*.45*d;
    float density = clamp(-t, 0.0, 1.0)*d;
    return clamp((density-0.4)/0.8, 0.0, 1.0);
}

// Palette for the effect
vec3 heatToColor(float heat)
{
    vec3 col = mix(vec3(0.0), vec3(1., .3, .0),clamp(heat * 15. -2.,   0., 1.));
    col = mix(col, vec3(1., 1., .6), clamp(heat * 15.1-4.,   0., 1.));
    col = mix(col, vec3(1., .9, .8), clamp(heat * 190. - 60.,   0., 1.));
    return col;
}

int STEPCOUNT = 0; // debug
void trace(in vec3 rp, in vec3 rd, inout vec4 color)
{
    
    bool hit = false;
    vec3 ro = rp;
    float dist = 0.0;
    
    for (int i = 0; i < 150; ++i)
    {
        dist = mapLo(rp);
        if(dist < 0.0)
        {
            hit = true;
            break;
        }
        rp += rd * max(dist, 0.01);
        ++STEPCOUNT;
        if(length(ro - rp) > 5.0) break;
        
    }
    
    vec4 col = vec4(.0);
    for (int i = 0; i < 400; ++i)
    {
        float density = sampleVolume(rp);
		float dist = mapLo(rp);
        ++STEPCOUNT;

        if (dist < 0.0)
        {
            float heat = density;
            heat = (heat)/(max(1.0, (T*.5)-.1));
            vec3 dcol = heatToColor(heat);

            float smoke = heat/.03;
            if (smoke < 1.0)
            {
                dcol = vec3(smoke*.5);
            }

            float d = density * 0.024 * DECAY;
            col.rgb = mix(col.rgb, dcol, (1.0-col.a)*d);
            col.a += d;
        }
        if (dot(rp, rp) > 10.0) break;
        if (rp.y < -0.2) break;
        if (col.a >= 1.) break;
        rp += rd*(.00075)*(1.0+max(dist*1000., 1.0));
    }
    
    // contrast
    col.rgb = smoothstep(0.0, .3, col.rgb);
    // mixing with bg
    col.a = smoothstep(0.0, 0.95, col.a);
    color = mix(color, col, col.a);
}


mat3 lookat(vec3 from, vec3 to)
{
    vec3 f = normalize(to - from);
    vec3 _tmpr = normalize(cross(f, vec3(0.0, 1.0, 0.0)));
    vec3 u = normalize(cross(_tmpr, f));
    vec3 r = normalize(cross(u, f));
    return mat3(r, u, f);
}


// t = time, b = from, c = delta, d = duration
// http://gizma.com/easing
float easeOut(float t, float b, float c, float d)
{
	t /= d;
	return -c * t*(t-2.) + b;    
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
	vec2 uv = (fragCoord.xy-iResolution.xy*.5) / iResolution.x;
    vec2 im = iMouse.xy;
    if (iMouse.z < 0.0)
    {
        im.y = 40.0;
    }
    
    fragColor = vec4(.0);
    /////////////
    // animation
    ////////////
    T = mod(iTime, 4.5)*4.;
    ROTATION_T = pow(T*.2, 1.2);
    DECAY = 1.-smoothstep(7.0, 20., T);
    
    float expandTime = 2.;
    float ease = easeOut(min(T, expandTime), 0.01, 1.0, expandTime);
	float r = clamp(ease, 0.0, 1.0)*.1;    
    
    RADIUS = r*1.2;
    THICKNESS = r*2.;
    RADIUS += T*.02;
    //////////////////
    // Camera work
    /////////////////
    vec3 rd = normalize(vec3(uv, 1.4));
    vec3 rp = vec3(0.0, 0.0, -2.5);
    
    float camShakeX = smoothstep(2., .0, T)*sin(T*40.);
    float camShakeY = smoothstep(2., .0, T)*cos(T*40.);
    vec3 lookpos = vec3(camShakeX*.025, camShakeY*.025, 0.0);
    rp.x += lookpos.x;
    rp.y += lookpos.y;
    
    rp.y += 4.5*smoothstep(-.6, 1., im.y/iResolution.y);
    rp = roty(im.x*.01) * rp;
    rd = lookat(rp, lookpos) * rd;
    
    //////////////////////////////////////
    // Ground shadowing, glow etc.
    /////////////////////////////////////
    float t = -(0.1 + dot(rp, up))/dot(rd, up);
    if (t > 0.0)
    {
        fragColor=vec4(.4, .5, .6, .0)*.5;
        vec3 rpp = rp+rd*t;
        float dist = map(rpp);
        float dist2 = map(rpp+vec3(-0.1, 0.0, 0.06));
        
        // fake shadow
        dist2 *= 1.+0.5+0.5*dot(normalize(rpp), vec3(-1., 0.0, -.2))*2.8;
        fragColor *= mix(1., texture(iChannel0, rpp.xz*.8).r, .15);
        fragColor.rgb *= mix(1.0, smoothstep(-.0, .4, dist2), .97*smoothstep(-0.34, .3, DECAY));
        
        float TT = T*4.;
        
        fragColor.rgb += vec3(1., .6, .2)*smoothstep(.5, 1.6, (1./(dist+.4)))*1.*smoothstep(.2, 3.0, TT)*smoothstep(28.0, -15., TT);
        fragColor.rgb += vec3(1.4, .4, .0)*smoothstep(.1, -0.2, dist)*.07*(smoothstep(0.5, 1.0, DECAY));
    }
    
    // trace the ray to top of donut.
    t = -(-THICKNESS + dot(rp, up))/dot(rd, up);
	rp += rd*t;
    trace(rp, rd, fragColor);
    
    fragColor.rgb = sqrt(fragColor.rgb);
    fragColor.rgb *= smoothstep(0.7, 0.3, length(uv));
    
    //fragColor.rgb = vec3(float(STEPCOUNT)/400.0);
}


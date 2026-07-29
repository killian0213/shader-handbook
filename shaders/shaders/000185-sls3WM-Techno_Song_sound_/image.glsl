// Image (image) — Techno Song (sound) by athibaul
// https://www.shadertoy.com/view/sls3WM

// ********************************
// Techno Song - by Alexis THIBAULT
// 29/05/2021
// ********************************

// See the "Common" tab for sound design and song structure.


#define dot2(x) dot(x,x)
#define hypot(x, y) sqrt((x)*(x) + (y)*(y))

float onRing(vec2 p, float r1, float r2, float eps)
{
    float d1 = length(p);
    return smoothstep(r1-eps,r1+eps,d1) * smoothstep(r2+eps,r2-eps,d1);
}

float borromeanRings(vec2 p, float eps)
{
    p = p.yx;
    // rotate p back to the two slices around the positive x axis
    float th = TAU/3.*round(atan(p.y,p.x)/TAU*3.);
    p *= mat2(cos(th), sin(th), -sin(th), cos(th));
    
    float rings = 0.;
    float d = 0.65;
    if(p.y > 0.)
    {
        rings += onRing(p-d*vec2(-0.5,-0.866), 0.9, 1.1, eps);
        rings *= 1. - onRing(p-d*vec2(-0.5,0.866), 0.7, 1.3, eps);
        rings += onRing(p-d*vec2(-0.5,0.866), 0.9, 1.1, eps);
        rings *= 1. - onRing(p-d*vec2(1,0), 0.7, 1.3, eps);
        rings += onRing(p-d*vec2(1,0), 0.9, 1.1, eps);
    }
    else
    {
        rings += onRing(p-d*vec2(1,0), 0.9, 1.1, eps);
        rings *= 1. - onRing(p-d*vec2(-0.5,-0.866), 0.7, 1.3, eps);
        rings += onRing(p-d*vec2(-0.5,-0.866), 0.9, 1.1, eps);
        rings *= 1. - onRing(p-d*vec2(-0.5,0.866), 0.7, 1.3, eps);
        rings += onRing(p-d*vec2(-0.5,0.866), 0.9, 1.1, eps);
    }
    
    return rings;
}

vec4 turningDisk(vec2 p, vec3 baseCol, float eps)
{
    float th = -iTime * TAU * 33./60.;
    
    float th0 = atan(p.y, p.x);
    p *= mat2(cos(th), sin(th), -sin(th), cos(th));
    
    float d1 = length(p);
    float th1 = atan(p.y, p.x);
    float r1 = 0.6, r2 = 0.65;
    float relAngle = mod(th1,TAU)-TAU/2.;
    float onEdge = onRing(p, 0.6, 0.65, eps);
    // Thin stripe on the outer edge
    float w = 0.02;
    onEdge *= smoothstep(w-eps,w+eps, abs(p.y)+step(0.,p.x));
    
    // Inner circle
    onEdge += onRing(p, 0.02, 0.18, eps);
    
    // Black logo on the inner circle
    onEdge -= borromeanRings((p - vec2(0.09,0.0))*25., eps*25.);
    
    
    // Flashing color
    vec3 edgeCol = baseCol;
    edgeCol = pow(edgeCol, 1.5*vec3(2. - sin(3.*p.y + p.x +iTime)));
    
    
    vec4 col = vec4(edgeCol, onEdge);
    
    // Vinyl part
    
    float onDisk = onRing(p, 0.18, 0.58, eps);
    float albedo = clamp(6.+6.*sin(d1*80.), 0., 1.) * (0.8+0.1*noise(2.*th1+0.5*d1/eps)*sin(th1)+0.1*noise(0.5*d1/eps));
    float lighting = pow(abs(sin(th0+1.0)), 5.);
    
    col += albedo*lighting*onDisk * 0.4;
    
    return col;
    
}

float onBox(vec2 p, vec2 r, float rounded, float eps)
{
    vec2 q = abs(p) - r + rounded;
    float d = length(max(q,0.)) - rounded;
    return smoothstep(1.5*eps,0.,d);
}

vec4 squarePad(vec2 p, vec2 r, vec3 baseCol, float eps)
{
    float onSquare = onBox(p, r, 0.02, eps);
    vec3 col = pow(baseCol, vec3(2.- sin(iTime)) + 2.*dot2(p/r));
    return vec4(col, onSquare);
}

vec4 waveform(vec2 p, vec3 baseCol, float eps)
{
    float t = p.x + iTime;
    float envSq = exp(-10.*mod(t,0.5));
    envSq += 0.2*exp(-20.*mod(t,0.25)) * (1.+sin(t*4.));
    envSq += window(0.1,0.2,mod(t,0.25)) * (1.-sin(3.*t)) * 0.02;
    float envenv = 0.9 + 0.1*smoothstep(0.,0.5,mod(t,0.5)) * 0.8*window(0.,4.,mod(t,8.));
    envenv *= step(0.,t);
    envenv *= smoothstep(0.,2.,t);
    envSq *= envenv;
    float env = sqrt(envSq) * 0.7;
    vec3 col = pow(baseCol, 3.*vec3(abs(p.y) + 3.*(1.-envenv)));
    return vec4(col, smoothstep(env+eps,env-eps,abs(p.y)));
}

vec4 turntableArm(vec2 p, float eps)
{
    p -= vec2(0.65,0.55);
    float th0 = atan(p.y, p.x);
    float thMin = -0.2, thMax = -0.6;
    float th = mix(thMin, thMax, clamp(iTime/146., 0., 1.));
    
    p *= mat2(cos(th), sin(th), -sin(th), cos(th));
    
    vec4 col = vec4(0);
    
    float len = 0.42;
    float wid = 0.02;
    vec4 shadow = vec4(0,0,0, onBox(p-vec2(0,-len), vec2(wid,len), 0.1, 0.1) * 0.9);
    col = mix(col, shadow, shadow.a);
    float rect = onBox(p-vec2(0.,-len), vec2(wid,len), eps, eps);
    vec3 armcol = vec3(clamp(0.1 - sin(2.*p.x / sqrt(max(wid*wid - p.x*p.x, 0.0002)) - p.y), 0.07, 1.));
    col = mix(col, vec4(armcol, 1), rect);
    
    
    float d = length(p);
    vec3 chromeBrush = vec3(0.8+0.1*noise(5. + 0.5*d/eps));
    float lighting = mix(0.07, 1., pow(abs(sin(th0+1.0)), 8.));
    col = mix(col, vec4(chromeBrush*lighting, 1), onRing(p, 0.,0.1, eps));
    
    p -= vec2(0,-2.*len);
    float head1 = onBox(p, vec2(0.03,0.05), eps, eps);
    col = mix(col, vec4(0.7 - 10.*p.x,0,0,1), head1);
    float head2 = onBox(p-vec2(0,0.02), vec2(0.04,0.05), eps, eps);
    float head2sh = onBox(p-vec2(0,0.02), vec2(0.04,0.05), 0.02, 0.02);
    col = mix(col, vec4(0,0,0,1), head2sh*0.7);
    vec3 headCol = vec3(0.4);
    float rings = borromeanRings(50.*(p-vec2(0,0.02)), 50.*eps);
    headCol = mix(headCol, vec3(0.1,0.1,0.1), rings);
    headCol *= smoothstep(0.1,-0.1,p.x)*2.;
    
    col = mix(col, vec4(headCol, 1), head2);
    
    return col;
}


void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = (2.*fragCoord.xy-iResolution.xy)/iResolution.y;
    
    float eps = 1.5/iResolution.y;
    
    vec3 col = vec3(0);
    
    float t = mod(iTime, 0.5);
    float kickin = (iTime > 2.) ? exp(-t*10.) : 0.;
    vec3 baseCol = mix(vec3(0.5,0.75,1.000), vec3(1.), kickin);
    
    vec2 p = uv - vec2(0.7,-0.2);
    vec4 diskCol = turningDisk(p, baseCol, eps);
    col = mix(col, diskCol.xyz, diskCol.a);
    vec4 armCol = turntableArm(p, eps);
    col = mix(col, armCol.xyz, armCol.a);
    
    
    p = uv - vec2(-1.0,-0.5);
    vec2 padC = clamp(round(p/0.2),-1.,4.)*0.2;
    baseCol = mix(pow(normalize(0.5 + 0.4*cos(iTime+padC.xyx*3.+vec3(0,2,4))), vec3(0.3)), vec3(1.), kickin);
    vec4 padCol = squarePad(p - padC, vec2(0.092), baseCol, eps);
    col = mix(col, padCol.xyz, padCol.a);
    
    baseCol = mix(vec3(0.95,0.8,0.2), vec3(1.), kickin);
    vec4 waveformCol = waveform((uv-vec2(0,0.8)) * 5., baseCol, eps * 5.);
    col = mix(col, waveformCol.xyz, waveformCol.a);
    
    //col = vec3(1)*borromeanRings(uv*2.0, 2.*1.5/iResolution.y);
    
    
    col = sqrt(col);
    fragColor = vec4(col,1.0);
}
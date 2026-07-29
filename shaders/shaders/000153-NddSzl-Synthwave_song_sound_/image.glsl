// Image (image) — Synthwave song (sound) by athibaul
// https://www.shadertoy.com/view/NddSzl


vec4 applyColor(vec4 c1, vec4 c2)
{
    vec3 col = mix(c1.rgb, c2.rgb, c2.a);
    float alpha = 1. - (1.-c1.a) * (1.-c2.a);
    
    return vec4(col, alpha);
}


vec2 wheelPos(float time)
{
    // Angle of the wheels of the tape machine at given time
    
    float phase1 = phasePortamento(time, 0., 1.25, 0.5, 4.0);
    float phase2 = phasePortamento(time, 0., 0.48, 0.5, 4.0);
    
    return TAU*vec2(phase1, phase2); 
}


vec4 drawWheel(vec2 p, float theta0)
{
    // theta0 : angle of symmetry (TAU/3, TAU/4...)
    float d = length(p) - 1.0; // disk
    float theta = atan(p.y,p.x);
    theta = theta0*round(theta/theta0);
    p *= mat2(cos(theta), sin(theta), -sin(theta), cos(theta));
    
    // Symmetric pattern
    d = max(d, 0.2-length(p-vec2(0.62,0.0)));
    
    vec3 col = vec3(0.5);
    float alpha = smoothstep(0.001,-0.001,d);
    
    return vec4(col, alpha);
}


float scoreTime()
{
    return iTime - 4.;
}
float drumTime()
{
    return iTime - 4. - 8.*beatdur;
}
float timeSinceKick()
{
    float t = drumTime();
    return (t > 0.) ? mod(t, 2.*beatdur) : 20.;
}
float timeSinceSnare()
{
    float t = drumTime() - beatdur;
    return (t > 0.) ? mod(t, 2.*beatdur) : 20.;
}



vec2 lensDistortion(vec2 p, float dist)
{
    return (dist > 0.) ? p * (1. + dist*length(p)) : p / (1. - dist*length(p));
}


vec3 sceneOne(vec2 p)
{
    float dist = 1.0*smoothstep(4.0,0.0,iTime);
    // "Acceleration effect": distort picture on riser
    float riserTime = (scoreTime() - 40.*beatdur)/(7.*beatdur);
    riserTime = clamp(riserTime, 0., 1.);
    dist += riserTime * (1.- 0.167/ (1.-riserTime));
    p = lensDistortion(p, dist);

    // Horizontal grid of magenta lines
    
    // Calculate projection onto floor plane
    vec2 q = vec2(p.x/p.y, 1./p.y);
    
    // Animate depending on time
    float offs = -0.2*iTime - phasePortamento(max(scoreTime(),0.), 1.0, 20.0, 40.*beatdur,47.*beatdur);
    q.y += offs;
    
    // Find closest horizontal/vertical line
    vec2 qh = vec2(q.x, round(q.y));
    vec2 qv = vec2(round(q.x), q.y);
    qh.y -= offs;
    qv.y -= offs;
    
    // Reproject onto screen
    vec2 ph = vec2(qh.x/qh.y, 1./qh.y);
    vec2 pv = vec2(qv.x/qv.y, 1./qv.y);
    
    // Clamp vertically to lower half
    ph.y = min(ph.y, 0.);
    pv.y = min(pv.y, 0.);
    
    // Shade according to distance
    float dh = length(p-ph);
    float dv = length(p-pv);
    vec3 col = vec3(0);
    
    float eps = 0.01;
    dh = max(dh-0.1*eps*abs(qh.y),0.);
    dv = max(dv-0.1*eps*abs(qv.y),0.);
    
    float intensity = 0.2 + exp(-8.*timeSinceKick());
    
    col += vec3(1., 0.1, 1.) * 0.001/(dh*dh+eps*eps) * intensity;
    col += vec3(1., 0.1, 1.) * 0.001/(dv*dv+eps*eps) * intensity;
    
    //col = vec3(0.05) * abs(qv.y);
    
    
    // Synthwave "sun"
    
    intensity = 1. + 5.*exp(-5.*timeSinceSnare());
    float d = length(p - vec2(0,0.5)) - 0.62*0.5;
    
    float expo = min(1./abs(p.y),8.);
    vec3 sunBase = vec3(2.,0.6,0.1);
    vec3 sunCol = pow(sunBase, vec3(expo));
    float occl = 0.5+0.5*sin(8./p.y - TAU*offs);
    occl = max(occl - 0.5, 0.);
    //occl = mix(occl, 1., 0.03);
    occl = mix(occl, 1., smoothstep(0.3,0.8,p.y));
    col += 1.5 * sunCol * smoothstep(0.02,0.0,d) * occl * intensity;
    
    // Add sun halo
    col += 0.2 * sunBase * min(0.03/(d*d + 0.3*0.3), 1.) * intensity;
    col += 0.2 * vec3(0.1,1.0,1.0) * smoothstep(0.,0.01,d) * 0.002/(d*d+0.005) * intensity;
    
    
    // Arpeggio animation
    
    for(float i=0.; i < 17.; i++)
    {
        float timeSinceArpUp = mod(scoreTime() - i*0.125*beatdur, 4.*beatdur);
        float timeSinceArpDown = mod(scoreTime() - 4.*beatdur + i*0.125*beatdur, 4.*beatdur);
        float timeSinceNote = min(timeSinceArpUp, timeSinceArpDown);
        timeSinceNote = (scoreTime() >= i*0.125*beatdur) ? timeSinceNote : 10.;
        
        intensity = 5.*exp(-10.*timeSinceNote) + exp(-8.*timeSinceNote);
        
        float d = length(p + vec2(1.62,-0.5) - vec2(0.,0.05*(i-8.))) - 0.01;
        d = min(d, length(p + vec2(-1.62,-0.5) - vec2(0.,0.05*(i-8.))) - 0.01);
        
        col += intensity * smoothstep(0.01,0.0,d) * vec3(0.1,1.,1.) * 2.;
        col += intensity * smoothstep(0.0,0.01,d) * vec3(0.1,1.,1.) * 0.001 / (d*d+0.01);
    }
    
    
    return col * smoothstep(1.0,4.0,iTime);
    
}


float quinticInflectionCurve(float x)
{
    // Polynomial of degree 5 such that:
    //  P(0) = 0 ;  P(1) = 0 ;
    // P'(0) = 1 ; P'(1) = 0 ;
    // P"(0) = 0 ; P"(1) = 0.
    
    // Its maximum is a bit below 0.2
    
    
    return x*(1.-x) + x*x*(x-1.) + 2.*x*x*(x-1.)*(x-1.) - 3.*x*x*x*(x-1.)*(x-1.);
}

vec4 drawCar(vec2 p)
{

    // Curve of the main body 
    float hx = (p.x+0.25)/(1.3+0.25);
    float h = quinticInflectionCurve(hx) * 0.6 + 0.5;
    float alpha = step(-0.25,p.x) * smoothstep(0.,0.01, h - p.y) * step(p.x, 1.3) * step(0.1,p.y);
    
    // Back of the car
    float hy = (p.y-0.1)/(0.5-0.1);
    h = 0.2* hy * (1.-hy) + 1.3;
    alpha = max(alpha, smoothstep(0.,0.01, h-p.x) * step(0.1,p.y) * step(p.y,0.5) * step(1.3,p.x));
    
    // Front of the car
    hx = (p.x+1.35)/(-0.25+1.35);
    h = 0.2 * (1. -(1.-hx)*(1.-hx)) + 0.3;
    alpha = max(alpha, smoothstep(0.,0.01,h-p.y) * step(-1.35,p.x) * step(p.x,-0.25) * step(0.1,p.y));
    // Carve out the intake
    hy = (p.y-0.1)/(0.5-0.1);
    h = -1.35 + 0.2*hy*(1.-hy);
    alpha = min(alpha, smoothstep(0.,0.01,p.x-h));
    // Front lower slope
    hx = (p.x+1.1)/(-1.1+1.35);
    h = 0.2 - 0.1*(1. - hx*hx);
    alpha = min(alpha, 1. - smoothstep(0.,0.01,h-p.y) * step(p.x,-1.1));
    // Back lower slope
    hx = (p.x-1.)/(1.-1.3);
    h = 0.15 - 0.05*(1. - hx*hx);
    alpha = min(alpha, 1. - smoothstep(0.,0.01,h-p.y) * step(1.0,p.x));
    
    // Wheels
    float d = length(p - vec2(-0.85,0.2)) - 0.2;
    alpha = max(alpha, smoothstep(0.01,0.,d));
    d = length(p - vec2(0.85,0.2)) - 0.2;
    alpha = max(alpha, smoothstep(0.01,0.,d));
    
    vec3 col = vec3(0);
    
    // Side line
    vec2 q = p;
    q.x = clamp(q.x, -0.5, 0.6);
    q.y = 0.2 + 0.2*smoothstep(-0.3,0.5,q.x);
    d = length(q-p);
    float intensity = pow(0.5 + 0.5*sin(TAU*p.x - 2.*iTime), 3.) + 0.1;
    col += vec3(0.1,1,1) * 0.0001/(d*d + 0.00001) * smoothstep(-0.8,1.,p.x) * intensity;
    // Headlights
    hy = (p.y-0.3)/(0.5-0.3);
    h = -1.1+0.4*hy*hy;
    col += vec3(8) * smoothstep(0.32,0.33,p.y) * smoothstep(0.,0.01,h-p.x) * smoothstep(-0.95,-1.3,p.x);
    // Backlights
    hy = (p.y-0.1)/(0.5-0.1);
    h = 0.1* hy * (1.-hy) + 1.3;
    col += vec3(2,0.01,0.01) * smoothstep(0.,0.01,p.x-h) * smoothstep(0.35,0.36,p.y);
    
    return vec4(col, alpha);
}

vec3 sceneTwo(vec2 p)
{
    vec3 col = vec3(0.);

    // Backdrop: setting sun
    float intensity = exp(-5.*timeSinceSnare());
    float d = length(p - vec2(-1.0,0.5)) - 0.62*0.5;
    
    float expo = min(1./abs(p.y),8.);
    vec3 sunBase = vec3(2.,0.6,0.1);
    vec3 sunCol = pow(sunBase, vec3(expo));
    float occl = 0.5+0.5*sin(8./p.y + iTime);
    occl = max(occl - 0.5, 0.);
    //occl = mix(occl, 1., 0.03);
    occl = mix(occl, 1., smoothstep(0.3,0.8,p.y));
    col += 20. * sunCol * smoothstep(0.02,0.0,d) * occl;
    
    // Add sun halo
    col += 2. * sunBase * min(0.03/(d*d + 0.3*0.3), 1.) * intensity;
    
    // Add sky
    expo = 4./(p.y+1.03);
    vec3 fogCol = 2.*pow(vec3(0.9,0.5,0.1), vec3(expo));
    col += fogCol;
    
    // Add slight grid in the sky
    vec2 q = 10.*vec2(p.x/(p.y+1.), 2./(p.y+1.));
    vec2 qh = vec2(q.x, round(q.y)), qv = vec2(round(q.x-0.5*iTime)+0.5*iTime, q.y);
    float dq = min(length(q-qh), length(q-qv));
    intensity = exp(-8.*timeSinceKick());
    col += 0.5*fogCol * smoothstep(0.1,0.0,dq) * smoothstep(-0.9,0.5,p.y) * (0.5+intensity);
    
    
    // Background : add skyline
    float bh = rand(round(p.x*10. - 2.*iTime));
    float opacity = 0.8*step(p.y+1.,bh);
    bh = rand(round(p.x*20. - 2.*iTime))*0.5 + 0.2;
    opacity = max(opacity, 0.5*step(p.y+1.,bh));
    col = (opacity > 0.) ? mix(fogCol, vec3(0), opacity) : col;
    
    
    // Draw pretty car
    vec4 car = drawCar(p + vec2(0,1));
    
    col = applyColor(vec4(col,1.), car).rgb;
    
    
    // Add light poles (with bass rhythm)
    float polePos = 8.*(mod(scoreTime() - 0.25*beatdur, 0.5*beatdur)/(0.5*beatdur) - 0.5);
    col = mix(col, vec3(0), smoothstep(0.6,0.0,abs(p.x-polePos)));
    
    
    return col;
}



void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = (2.*fragCoord-iResolution.xy)/iResolution.y;

    
    // Time varying pixel color
    vec3 col = sceneOne(uv);
    if(scoreTime() > 47.*beatdur)
    {
        // Fade from white to black on clap
        float tClap = scoreTime() - 47.*beatdur;
        col = vec3(10.)* exp(-8.*tClap) * smoothstep(1., 0., tClap);
    }
    if(scoreTime() > 48.*beatdur)
    {
        col = sceneTwo(uv);
    }
    

    //col = applyColor(col, drawWheel(uv, TAU/4.));

    // Output to screen
    col.rgb = 1.-exp(-col.rgb); // Tonemap
    col.rgb = pow(col.rgb, vec3(1./2.2));
    fragColor = vec4(col, 1.);
}
// Buffer A (buffer) — Jansen Blueprint by blackle
// https://www.shadertoy.com/view/NlBcRd


//from https://www.shadertoy.com/view/4sKyRK
float distanceToBottleCurve(vec2 point) {
    return point.y-0.1*sin(point.x*2.5 + 0.6) + 0.05*sin(5.0*point.x) + 0.04*sin(7.5*point.x);
}
bool texturee(vec2 uv) {
    float ang = atan(uv.y, uv.x);
    float len = floor(length(uv)*10.0);
    bool val = len == 2. || len == 6. || len == 9.;
    if (len == 3. || len == 4. || len == 5. || len == 8. || len == 10.) {
        val = distanceToBottleCurve(vec2(ang+len,0.0))*7.99 > cos(len*7.99);
    }
    return val;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord/iResolution.xy-.5;
    //I would make a better revision logo but I am too tired :(
    fragColor = vec4(1.0,91.0,188.0,1.0)/255.;
    float rad1 = abs(floor(atan(uv.x,uv.y)/2.)*.04);
    if (texturee(uv*2.5)) {
        fragColor = vec4(255.0,214.0,0.0,1.0)/255.;
    }
}
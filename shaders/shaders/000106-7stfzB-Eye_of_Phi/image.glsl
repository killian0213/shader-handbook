// Image (image) — Eye of Phi by ChunderFPV
// https://www.shadertoy.com/view/7stfzB

// contains a few field transforms for artistic purposes
// the metallic ratio transform is the one that looks like a magnetic field
// see this for a better explanation: https://www.shadertoy.com/view/ssGczz
// phi is often used to refer to the golden ratio which is the first metallic ratio
// hence the name of this shader
// also, here's a remake: https://www.shadertoy.com/view/X3VBR3

void mainImage( out vec4 RGBA, in vec2 XY )
{
    float t = iTime/PI*2.0;
    vec4 m = iMouse; m.xy = m.xy*2.0/R-1.0; // ±1x, ±1y
    if (m.z > 0.0) t += m.y*SCALE; // move time with mouse y
    float z = (m.z > 0.0) ? pow(1.0-abs(m.y), sign(m.y)): 1.0; // zoom (+)
    float e = (m.z > 0.0) ? pow(1.0-abs(m.x), -sign(m.x)): 1.0; // screen exponent (+)
    float se = (m.z > 0.0) ? e*-sign(m.y): 1.0; // spiral exponent
    vec3 bg = vec3(0); // black background
    
    float aa = 3.0; // anti-aliasing
    for (float j = 0.0; j < aa; j++)
    for (float k = 0.0; k < aa; k++)
    {
        vec3 c = vec3(0);
        vec2 o = vec2(j, k)/aa;
        vec2 uv = (XY-0.5*R+o)/R.y*SCALE*z; // apply cartesian, scale and zoom
        if (m.z > 0.0) uv = exp(log(abs(uv))*e)*sign(uv); // warp screen space with exponent

        float px = length(fwidth(uv)); // pixel width
        float x = uv.x; // every pixel on x
        float y = uv.y; // every pixel on y
        float l = length(uv); // hypot of xy: sqrt(x*x+y*y)

        float mc = (x*x+y*y-1.0)/y; // metallic circle at xy
        float g = min(abs(mc), 1.0/abs(mc)); // gradient
        vec3 gold = vec3(1.0, 0.6, 0.0)*g*l;
        vec3 blue = vec3(0.3, 0.5, 0.9)*(1.0-g);
        vec3 rgb = max(gold, blue);

        float w = 0.1; // line width
        float d = 0.4; // shadow depth
        c = max(c, gm(rgb, mc, -t, w, d, false)); // metallic
        c = max(c, gm(rgb, abs(y/x)*sign(y), -t, w, d, false)); // tangent
        c = max(c, gm(rgb, (x*x)/(y*y)*sign(y), -t, w, d, false)); // sqrt cotangent
        c = max(c, gm(rgb, (x*x)+(y*y), t, w, d, true)); // sqrt circles

        c += rgb*ds(uv, se, t/TAU, px*2.0, 2.0, 0.0); // spiral 1a
        c += rgb*ds(uv, se, t/TAU, px*2.0, 2.0, PI); // spiral 1b
        c += rgb*ds(uv, -se, t/TAU, px*2.0, 2.0, 0.0); // spiral 2a
        c += rgb*ds(uv, -se, t/TAU, px*2.0, 2.0, PI); // spiral 2b
        c = max(c, 0.0); // clear negative color

        c += pow(max(1.0-l, 0.0), 3.0/z); // center glow

        if (m.z > 0.0) // display grid on click
        {
            vec2 xyg = abs(fract(uv+0.5)-0.5)/px; // xy grid
            c.gb += 0.2*(1.0-min(min(xyg.x, xyg.y), 1.0));
        }
        bg += c;
    }
    bg /= aa*aa;
    bg *= sqrt(bg)*1.5;
    
    RGBA = vec4(bg, 1.0);
}
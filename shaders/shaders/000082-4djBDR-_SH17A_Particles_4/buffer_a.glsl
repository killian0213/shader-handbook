// Buffer A (buffer) — [SH17A] Particles 4 by aiekick
// https://www.shadertoy.com/view/4djBDR

void mainImage( out vec4 f, vec2 g )
{
    f.a = 1.0;
    f.xyz = iResolution;
    vec2 v = (g+g-f.xy)/f.y*3.;
    f *= texture(iChannel0, g/f.xy) / length(f);
    g = vec2(iFrame + 2, iFrame);
    g = v - sin(g) * fract(iTime*.1 + 4.*sin(g))*3.;
    f += .1 / max(abs(g.x), g.y);
}
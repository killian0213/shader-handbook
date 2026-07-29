// Image (image) — Brush toy by leon
// https://www.shadertoy.com/view/NlSBW3


// Brush toy by Leon Denise 2022-05-17

// I wanted to play further with shading and lighting from 2D heightmap.
// I started by generating a heightmap from noise, then shape and curves.
// Once the curve was drawing nice brush strokes, I wanted to add motion.
// Also wanted to add droplets of paints falling, but that will be
// for another sketch.

// This is the color pass
// Click on left edge to see layers

// The painting pass (Buffer A) is using FBM noise to simulate brush strokes
// The curve was generated with a discrete Fourier Transform,
// from https://www.shadertoy.com/view/3ljXWK

// Frame buffer sampling get offset from brush motion,
// and the mouse also interact with the buffer.


void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec3 color = vec3(.0);
    
    // coordinates
    vec2 uv = fragCoord.xy / iResolution.xy;
    vec3 dither = texture(iChannel1, fragCoord.xy / 1024.).rgb;
    
    // value from noise buffer A
    vec3 noise = texture(iChannel0, uv).rgb;
    float gray = noise.x;
    
    // gradient normal from gray value
    vec3 unit = vec3(3./iResolution.xy,0);
    vec3 normal = normalize(vec3(
        TEX(uv + unit.xz)-TEX(uv - unit.xz),
        TEX(uv - unit.zy)-TEX(uv + unit.zy),
        gray*gray));
    
    
    // specular light
    vec3 dir = normalize(vec3(0,1,2.));
    float specular = pow(dot(normal, dir)*.5+.5,20.);
    color += vec3(.5)*specular;
    
    // rainbow palette
    vec3 tint = .5+.5*cos(vec3(1,2,3)*1.5+gray*5.+uv.x*5.);
    dir = normalize(vec3(uv-.5, 0.));
    color += tint*pow(dot(normal, -dir)*.5+.5, 0.5);
    
    // background blend
    vec3 background = vec3(.8)*smoothstep(1.5,0.,length(uv-.5));
    color = mix(background, clamp(color, 0., 1.), smoothstep(.2,.5,noise.x));
    
    // display layers when clic
    if (iMouse.z > 0.5 && iMouse.x/iResolution.x < .1)
    {
        if (uv.x < .33) color = vec3(gray);
        else if (uv.x < .66) color = normal*.5+.5;
        else color = vec3(.2+specular)*gray;
    }

    fragColor = vec4(color, 1);
}
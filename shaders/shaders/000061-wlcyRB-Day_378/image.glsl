// Image (image) — Day 378 by jeyko
// https://www.shadertoy.com/view/wlcyRB

// Fork of "Day 378" by jeyko. https://shadertoy.com/view/WttyD7
// 2020-12-30 10:41:15


// Cyclic noise from nimitz
// smooth ops & sdfs from IQ
// pModPolar from hgSDF
// FXAA maybe from mudlord


void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = (fragCoord - 0.5*iResolution.xy)/iResolution.y;

    vec3 col = vec3(0);

    col = texture(iChannel0,fragCoord/iResolution.xy).xyz;
    
    col *= vec3(0.9,0.9,0.66);
    col *= exposure;
    
    col = mix(col*1.5,smoothstep(0.,1.,col*vec3(1.,1.1,1.4 ))*1.8,0.6);
    col = mix(acesFilm(col), col, 0.);
    col *= 1. - dot(uv,uv*0.4)*2.;
    
    col = pow(col,vec3(0.454545));
    
    fragColor = vec4(col,1.0);
}

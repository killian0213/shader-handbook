// Image (image) — Brutal Knowledge by yx
// https://www.shadertoy.com/view/3dyXzD

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    fragColor = texelFetch(iChannel0, ivec2(fragCoord), 0);
    fragColor /= fragColor.w;
    fragColor *= 2.5;
    fragColor /= fragColor+1.;
    fragColor = pow(fragColor, vec4(.45));
    fragColor = smoothstep(0.,1.,fragColor);
    fragColor.rgb = mix(vec3(0,.03,.05),vec3(1,1,1),fragColor.rgb);
}

/*
        "Brutal Knowledge"
          by yx/Polarity

      4kb executable graphics
    released at Demosplash 2019
  in the freestyle graphics compo

   based on the architecture of 
      the UCSD Geisel Library

 greetings from across the pond <3

*/
// Image (image) — Wet neural network interactive by gena
// https://www.shadertoy.com/view/dlGfWV

// based on the following tweet:
// https://twitter.com/zozuar/status/1625182758745128981

// gena: added interactivity, tuned colors a bit
// original shader: https://www.shadertoy.com/view/mlBXRK

mat2 rotate2D(float r) {
    return mat2(cos(r), sin(r), -sin(r), cos(r));
}


void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = (fragCoord-.5*iResolution.xy)/iResolution.y;
    vec3 col = vec3(0);
    float t = iTime;
    
    vec2 n = vec2(0),q;
    vec2 N = vec2(0);
    vec2 p = uv + sin(t*0.1)/10.;
    float S = 10.;
    mat2 m = rotate2D(1. - iMouse.x * 0.0001);

    for(float j=0.;j++<30.;){
      p*=m;
      n*=m;
      q=p*S+j+n+t;
      n+=sin(q);
      N+=cos(q)/S;
      S*=1.2;
      
    }
    
    col = vec3(1, 2, 4) * pow((N.x + N.y + 0.2)+.005/length(N), 2.1);
    
    //col=pow(max(vec3(0),(N.x+N.y+.5)*.1*vec3(6,1,2)+.003/length(N)),vec3(.45));
    
    
    // Output to screen
    fragColor = vec4(col,1.0);
}
// Buffer A (buffer) —  Fiber Zooming by leon
// https://www.shadertoy.com/view/3fKyDG

// Fiber Zooming
// Leon Denise 07/12/2025

// inspired by a motion design clip in an episode of "Kurzgesagt"
// "Trees Are So Weird" https://youtu.be/ZSch_NgZpQs?t=193

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    // griding
    vec2 uv = fragCoord/iResolution.xy;
    vec2 p = (2.*fragCoord-iResolution.xy)/iResolution.y;
    float s = sign(p.x);
    p.x = log(.1+abs(p.x)*1.);
    float tt = iTime * 1.5;
    tt = sineInOut(fract(tt)) + floor(tt);
    tt *= 4.;
    float columns = 5.0;
    float column_index = floor(p.x*columns-tt);
    float t = tt * (hash11(column_index+73.)-.5) * 4.;
    float rows = mix(.5, 10., hash11(column_index+753.));
    float row_index = floor(p.y*rows+t);
    p.x = fract(p.x*columns-tt)-0.5;
    p.y = fract(p.y*rows+t)-.5;
    float shape = sdBox(p, vec2(.3,.4));
    float shade = smoothstep(.1,.0, shape);
    
    // coloring
    vec3 color = vec3(0);
    float value = hash11(row_index+column_index+357.);
    float hue = length(vec2(column_index, row_index*10.)) * .01;
    vec3 palette = cos(vec3(1,2,3)*5.5 + iTime + hue);
    color = value * palette * shade;
    fragColor = vec4(color,1.0);
}
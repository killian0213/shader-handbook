// Buffer A (buffer) — The door at the end of the world by leon
// https://www.shadertoy.com/view/fdVBRw


// fbm gyroid cyclic noise
float gyroid (vec3 seed) { return dot(sin(seed),cos(seed.yzx)); }
float fbm (vec3 seed) {
    float result = 0.;
    float a = .5;
    for (int i = 0; i < 4; ++i) {
        result += (gyroid(seed/a))*a;
        a /= 2.;
    }
    return result;
}

// the fluidish simulacre
void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord/iResolution.xy;
    vec2 p = (fragCoord-iResolution.xy/2.)/iResolution.y;
    vec3 blue = texture(iChannel1, fragCoord/1024.).rgb;
    
    float dt = iTimeDelta;
    float current = texture(iChannel0, uv).r;
    
    // shape
    float shape = abs(max(abs(p.x)-.1, abs(p.y)-.2))-.01;    
    
    // masks
    float shade = smoothstep(.01,.0,shape);
    float smoke = pow(uv.y,.5);
    float flame = 1.-uv.y;
    float steam = pow(current, 0.2);
    float cycle = .5 + .5 * sin(iTime-uv.x*3.);
    
    vec2 offset = vec2(0);
    
    // bubble animation cycle
    vec2 pp = fract(p*1.-vec2(.5,iTime*.2))-.5;
    float lpp = length(pp);
    float mask = smoothstep(.5,.0,lpp);
    offset += (-pp)*mask*5.;
    
    // ignit with bubble
    shade *= .5+.5*mask;
    
    // environment
    /*
    vec2 q = p;
    float c = .05;
    q.x += floor(q.y/c)*.02+.1;
    q.y = repeat(q.y, c);
    shape = max(p.y+.22, abs(box(q, vec2(.1,.002))));
    shape = min(shape, abs(length(p+vec2(0,.2))-.8));
    shade = min(1., shade+.75*smoothstep(.01,.0,abs(shape)));
    */
    
    // expansion
    vec4 data = texture(iChannel0, uv);
    vec3 unit = vec3(2./iResolution.xy,0);
    vec3 normal = normalize(vec3(
        TEX(uv - unit.xz)-TEX(uv + unit.xz),
        TEX(uv - unit.zy)-TEX(uv + unit.zy),
        data.x*data.x*data.x)+.001);
    offset -= normal.xy * smoke;
    
    // turbulence
    vec3 seed = vec3(p*4.,p.y+iTime);
    float angle = fbm(seed)*6.28*2.;
    offset += vec2(cos(angle),sin(angle)) * flame;
    
    // energy loss
    vec4 frame = texture(iChannel0, uv+offset/iResolution.xy);
    shade = max(shade, frame.r-dt*.4);
    fragColor = vec4(shade);
}
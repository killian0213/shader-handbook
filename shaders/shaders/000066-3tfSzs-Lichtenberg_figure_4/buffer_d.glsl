// Buffer D (buffer) — Lichtenberg figure 4 by rory618
// https://www.shadertoy.com/view/3tfSzs

void splat(inout vec4 O, vec2 I, particle p){
    if(floor(I) == floor(p.coord) && !p.nil){
        O += vec4(p.color,1); 
    }
}


void mainImage( out vec4 O, in vec2 I )
{

    O = vec4(0);
    int seed = iFrame/8;
    
    if(iFrame%8==7){
            vec2 ip = forward_mapping(I,R,seed);
            vec4 t = texelFetch(iChannel1,ivec2(ip),0);
            

            splat(O,I,unpackParticle(t.xy));
            splat(O,I,unpackParticle(t.zw));
    } else {
        O = texture(iChannel3,I/R.xy);
    }
}
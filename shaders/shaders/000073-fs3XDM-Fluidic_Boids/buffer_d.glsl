// Buffer D (buffer) — Fluidic Boids by davidar
// https://www.shadertoy.com/view/fs3XDM

void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
    fragColor = vec4(0);
    for(int i = -2; i <= 2; i++) {
        for(int j = -2; j <= 2; j++) {
            vec4 data = texture(iChannel0, fract((fragCoord + vec2(i,j)) / iResolution.xy));
            if(abs(data.x - fragCoord.x) < 0.5 && abs(data.y - fragCoord.y) < 0.5) {
                fragColor = data;
                return;
            }
        }
    }
}
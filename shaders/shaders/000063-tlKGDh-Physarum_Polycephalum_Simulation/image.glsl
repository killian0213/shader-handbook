// Image (image) — Physarum Polycephalum Simulation by michael0884
// https://www.shadertoy.com/view/tlKGDh

void mainImage( out vec4 fragColor, in vec2 pos )
{
	vec4 particle = texel(ch0, pos);
    float distr = gauss(pos - particle.xy, prad);
    vec4 pheromone = 2.5*texel(ch1, pos);
    fragColor = vec4(sin(pheromone.xyz*vec3(1,1.2,1.5)), 1.);
}
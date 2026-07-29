// Buffer A (buffer) — International Shipping by blackle
// https://www.shadertoy.com/view/tlXyzr

//generates the heightmap for the waves.
//in the original C code, there was only one seed. in order to improve performance by doing this on the GPU,
//I split the FFT calculation across multiple frames, and each frame has a different starting seed.
#define WAVE_SAMPLES 1024
uint rndseeds[WAVE_DEPTH] = uint[WAVE_DEPTH](
920413359u,344147060u,354025938u,2510083042u,2912208450u,663489309u,61347429u,1209816006u,2738590810u,1234092029u,2528347578u,650889515u,2709794373u,2069110031u,3520323237u,2915168753u,
2322632710u,2989421851u,4280850451u,1474778517u,2881594422u,2265295789u,1910491705u,2277565322u,707509521u,4060625072u,1372978273u,1639299946u,3485656693u,2998509085u,782651004u,2758988468u,
493098580u,3703975077u,1132795244u,576308370u,4166192603u,3865744844u,778731983u,3968879059u,2600244750u,3395962586u,2377424722u,4075108333u,315984429u,1583277414u,3826192035u,586903153u,
1054474534u,745246921u,4256406772u,463193934u,4136561045u,3304490676u,341015040u,1744393505u,972704065u,1478460815u,1812621133u,1603688544u,133969005u,2700557178u,331483363u,3460139081u,
2871210438u,728092432u,1103924991u,3631508649u,754385041u,3315783261u,2534947633u,4169942121u,2234451975u,784357094u,2163247278u,736096301u,46193931u,561970122u,1297583479u,2406700841u,
3250333395u,4178599644u,3702373126u,765792619u,2445818533u,2923499364u,2779363917u,3023050847u,1398972607u,1789970279u,609453859u,2893149445u,1569196009u,849325608u,2774450625u,3723681545u,
2566077401u,3280027661u,3653271294u,4104918169u,1195760183u,4160009305u,3870009279u,1062551007u,2914502300u,909266381u,319407879u,3833525574u,3364539115u,2669656718u,2439999609u,4245366155u,
2936252450u,1040930787u,2376589173u,1582139829u,1312299439u,539453860u,982510869u,1214352644u,652148852u,3976312046u,4133709151u,2936335549u,3245026616u,2197966989u,1791165629u,616285886u);

uint randomstate;
float rand_float() {
	randomstate = randomstate ^ (randomstate << 13u);
	randomstate = randomstate ^ (randomstate >> 17u);
	randomstate = randomstate ^ (randomstate << 5u);
	randomstate *= 1685821657u;
	uint intermediate = ( (randomstate & 0x007FFFFFu) | 0x3F800000u );
	return uintBitsToFloat(intermediate) - 1.0;
}

float rand_gauss() {
	float a = 0.0;
	for (int i = 0; i < 12; i++) {
		a += rand_float();
	}
	return a - 6.0;
}

float phillips_spectrum(float x, float y) {
	float scale = 250.0;
	x *= scale; y *= scale;
	float k = x*x+y*y;
    if (k == 0.) return 0.0;
	if (k > float(WAVE_SAMPLES/2)) return 0.0;
	return exp(-2.0/k)/(k*k) * y;
}


void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    fragColor = texelFetch(iChannel0, ivec2(fragCoord), 0);
    vec2 uv = fragCoord/iResolution.xy;

    int i = iFrame;
    if (i >= WAVE_DEPTH) return;
    randomstate = rndseeds[i];
    for (int j = 0; j < WAVE_DEPTH; j++) {
		float x = float(i)/float(WAVE_SAMPLES);
		float y = float(j)/float(WAVE_SAMPLES);
        float ps = phillips_spectrum(x, y);
        
    	if (i == 0 && j <= 92) continue;
        float re = rand_gauss()*ps;
        float im = rand_gauss()*ps;
        float t = dot(-uv, vec2(j,i))*acos(-1.)*2.;
        fragColor += sin(t)*re + cos(t)*im;
	}
}
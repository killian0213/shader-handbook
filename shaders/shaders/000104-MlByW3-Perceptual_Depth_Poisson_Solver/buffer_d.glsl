// Buf D (buffer) — Perceptual Depth Poisson Solver by cornusammonis
// https://www.shadertoy.com/view/MlByW3

/* 
    This uses a blur kernel to iteratively blur the poisson solver output from Buf B
    in order to fill in areas with small laplacian values.
*/

/* 
	Using normalized convolution to throw out negative values from the solver.
	This speeds up convergence but is less accurate overall
*/
//#define NORMALIZED_CONVOLUTION

// If enabled, use a function that approximates the kernel. Otherwise, use the kernel.
//#define USE_FUNCTION

/* 
	The standard deviation was determined by fitting a gaussian to the kernel below.
	This can be changed in order to control the contrast of the resulting solution 
    if desired. Higher values result in less contrast, lower values in higher contrast.
*/
#define STDEV 15.4866382262
float gaussian(float w) {
    return exp(-(w*w) / STDEV);
}


void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord / iResolution.xy;
    vec2 texel = 1.0 / iResolution.xy;

    /*
		This is a Gaussian kernel, computed in a similar fashion to the Poisson solver kernel
		in Buf B, by performing several iterations of blurring with a 3x3 uniform kernel.
		I'm not sure this is an optimal blur kernel, but it has the best convergence properties
        of the kernels I have tried.        
	*/    
    
    float a[121] = float[](
		79.19345413844742, 186.95982256696507, 355.7725142792509, 557.2478169468127, 728.3177627480716, 792.5919289564812, 728.3177627476995, 557.2478169408488, 355.77251427912773, 186.95982256592688, 79.19345413873424,
		186.959822566632, 425.7969440744425, 791.9803669283782, 1224.530847511507, 1577.426364172433, 1725.1209704031874, 1577.4263641420696, 1224.5308475559118, 791.9803669376721, 425.79694407230176, 186.95982256563883,
		355.7725142799761, 791.9803669291889, 1452.3604097140878, 2209.3999629613313, 2852.94106149519, 3081.611616324168, 2852.941061533745, 2209.399962949136, 1452.3604097512411, 791.9803669249508, 355.77251427710723,
		557.2478169431769, 1224.5308475304664, 2209.399962931118, 3366.385791159061, 4279.72008889292, 4678.378018687814, 4279.720088892726, 3366.3857911950213, 2209.3999629391506, 1224.5308475541954, 557.2478169376274,
		728.3177627458676, 1577.4263641493967, 2852.9410614801927, 4279.720088978485, 5506.183369574301, 5920.756793177247, 5506.1833697747215, 4279.720088900363, 2852.941061422592, 1577.4263641763532, 728.3177627380724,
		792.591928959736, 1725.1209703621885, 3081.6116163468955, 4678.3780186709955, 5920.7567931890435, 6475.16792876658, 5920.756793140686, 4678.378018700188, 3081.611616243516, 1725.1209704374526, 792.5919289262789,
		728.3177627503185, 1577.4263641343025, 2852.941061521645, 4279.720088879328, 5506.1833695725, 5920.756793175392, 5506.183369768556, 4279.72008893864, 2852.941061394854, 1577.4263641878938, 728.3177627378943,
		557.2478169473138, 1224.5308475281577, 2209.3999629803902, 3366.385791173652, 4279.720088896571, 4678.378018637779, 4279.720088907292, 3366.3857911422515, 2209.399962952415, 1224.5308475544125, 557.2478169412809,
		355.7725142789757, 791.9803669328146, 1452.3604096970955, 2209.399962979159, 2852.9410614343005, 3081.611616339055, 2852.941061433329, 2209.3999629672044, 1452.360409748826, 791.9803669233293, 355.77251427842157,
		186.9598225669598, 425.7969440755401, 791.9803669309789, 1224.5308475353752, 1577.426364179527, 1725.120970397883, 1577.4263641778723, 1224.5308475497768, 791.980366930886, 425.79694407371545, 186.95982256558094,
		79.19345413823653, 186.9598225671716, 355.7725142808836, 557.2478169336465, 728.317762748316, 792.5919289394396, 728.3177627443532, 557.2478169373627, 355.7725142796133, 186.95982256574436, 79.19345413875728
	);
     
    vec4 accum = vec4(0);
    vec4 accumw = vec4(0);

    for (int i = -5; i <= 5; i++) {
        for (int j = -5; j <= 5; j++) {
            int index = (j + 5) * 11 + (i + 5);
			
            #ifdef USE_FUNCTION
                float w = gaussian(sqrt(float(i*i+j*j)));
            #else
            	float w =  a[index];
            #endif
           
            vec4 tx = texture(iChannel0, fract(uv + texel * vec2(i,j)));

            #ifdef NORMALIZED_CONVOLUTION
                accumw += step(0.0,tx) * w;
                accum  += step(0.0,tx) * w * tx;
            #else
                accumw += w;
                accum  += w * tx;
            #endif
            
        }
    }
    
	fragColor = accum / accumw;

}
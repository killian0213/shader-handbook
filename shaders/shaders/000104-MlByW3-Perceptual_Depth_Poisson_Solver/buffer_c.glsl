// Buf C (buffer) — Perceptual Depth Poisson Solver by cornusammonis
// https://www.shadertoy.com/view/MlByW3

/*
	This convolves the Laplacian values from Buf A with a specially-designed Poisson solver kernel.
*/

/* 
	Optionally, blend the result of the large-kernel solver and a Jacobi method solver,
	with the value 0.0 being only the fast solver, and 1.0 being only the Jacobi solver.
	Curiously, using a negative value here may result in faster convergence.
*/
#define SOLVER_BLEND 0.0

// If enabled, use a function that approximates the kernel. Otherwise, use the kernel.
//#define USE_FUNCTION

#define AMP 0.4375792
#define OMEGA -1.007177
#define OFFSET 0.002751625

float neg_exp(float w) {
    return OFFSET + AMP*exp(OMEGA*w);
}

vec4 neighbor_avg(sampler2D sampler, vec2 uv, vec2 tx) {

    const float _K1 = 4.0/6.0;   // edge-neighbors
    const float _K2 = 1.0/6.0;   // vertex-neighbors
    
    // 3x3 neighborhood coordinates
    float step_x = tx.x;
    float step_y = tx.y;
    vec2 n  = vec2(0.0, step_y);
    vec2 ne = vec2(step_x, step_y);
    vec2 e  = vec2(step_x, 0.0);
    vec2 se = vec2(step_x, -step_y);
    vec2 s  = vec2(0.0, -step_y);
    vec2 sw = vec2(-step_x, -step_y);
    vec2 w  = vec2(-step_x, 0.0);
    vec2 nw = vec2(-step_x, step_y);

    vec4 p_n =  texture(sampler, fract(uv+n) );
    vec4 p_e =  texture(sampler, fract(uv+e) );
    vec4 p_s =  texture(sampler, fract(uv+s) );
    vec4 p_w =  texture(sampler, fract(uv+w) );
    vec4 p_nw = texture(sampler, fract(uv+nw));
    vec4 p_sw = texture(sampler, fract(uv+sw));
    vec4 p_ne = texture(sampler, fract(uv+ne));
    vec4 p_se = texture(sampler, fract(uv+se));
    
    return _K1*(p_n + p_e + p_w + p_s) + _K2*(p_nw + p_sw + p_ne + p_se);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    const float _K0 = 20.0/6.0; // center weight

    vec2 uv = fragCoord / iResolution.xy;
    vec2 tx = 1.0 / iResolution.xy;
    
    /* 
		Poisson solver kernel, computed using a custom tool. The curve ended up being very close
    	to exp(-x) times a constant (0.43757*exp(-1.0072*x), R^2 = 0.9997).
    	The size of the kernel is truncated such that 99% of the summed kernel weight is accounted for. 
	*/
    float a[121] = float[](
        1.2882849374994847E-4, 3.9883638750009155E-4, 9.515166750018973E-4, 0.0017727328875003466, 0.0025830133546736567, 0.002936729756271805, 0.00258301335467621, 0.0017727328875031007, 9.515166750027364E-4, 3.988363875000509E-4, 1.2882849374998886E-4,
        3.988363875000656E-4, 0.00122005053750234, 0.0029276701875229076, 0.005558204850002636, 0.008287002243739282, 0.009488002668845403, 0.008287002243717386, 0.005558204850002533, 0.002927670187515983, 0.0012200505375028058, 3.988363875001047E-4,
        9.515166750033415E-4, 0.0029276701875211478, 0.007226947743770152, 0.014378101312275642, 0.02243013709214819, 0.026345595431380788, 0.02243013709216395, 0.014378101312311218, 0.007226947743759695, 0.0029276701875111384, 9.515166750008558E-4,
        0.0017727328875040689, 0.005558204850002899, 0.014378101312235814, 0.030803252137257802, 0.052905271651623786, 0.06562027788638072, 0.052905271651324026, 0.03080325213733769, 0.014378101312364885, 0.005558204849979354, 0.0017727328874979902,
        0.0025830133546704635, 0.008287002243679713, 0.02243013709210261, 0.052905271651950365, 0.10825670746239457, 0.15882720544362505, 0.10825670746187367, 0.05290527165080182, 0.02243013709242713, 0.008287002243769156, 0.0025830133546869602,
        0.00293672975627608, 0.009488002668872716, 0.026345595431503218, 0.06562027788603421, 0.15882720544151602, 0.44102631192030745, 0.15882720544590473, 0.06562027788637015, 0.026345595431065568, 0.009488002668778417, 0.0029367297562566848,
        0.0025830133546700966, 0.008287002243704267, 0.022430137092024266, 0.05290527165218751, 0.10825670746234733, 0.1588272054402839, 0.1082567074615041, 0.052905271651381314, 0.022430137092484193, 0.00828700224375486, 0.002583013354686416,
        0.0017727328875014527, 0.005558204850013428, 0.01437810131221156, 0.03080325213737849, 0.05290527165234342, 0.06562027788535467, 0.05290527165227899, 0.03080325213731504, 0.01437810131229074, 0.005558204849973625, 0.0017727328874977803,
        9.515166750022218E-4, 0.002927670187526038, 0.0072269477437592895, 0.014378101312185454, 0.02243013709218059, 0.02634559543148722, 0.0224301370922164, 0.014378101312200022, 0.007226947743773282, 0.0029276701875125123, 9.515166750016471E-4,
        3.988363875000695E-4, 0.0012200505375021846, 0.002927670187525898, 0.005558204849999022, 0.008287002243689638, 0.009488002668901728, 0.008287002243695645, 0.0055582048500028335, 0.002927670187519828, 0.0012200505375025872, 3.988363874999818E-4,
        1.2882849374993535E-4, 3.9883638750004726E-4, 9.515166750034058E-4, 0.0017727328875029819, 0.0025830133546718525, 0.002936729756279661, 0.002583013354672541, 0.0017727328875033709, 9.515166750023861E-4, 3.988363874999023E-4, 1.2882849374998856E-4
    );
    
    vec4 accum = vec4(0);
    for (int i = -5; i <= 5; i++) {
        for (int j = -5; j <= 5; j++) {
            int index = (j + 5) * 11 + (i + 5);
            
            #ifdef USE_FUNCTION
                float w = -neg_exp(sqrt(float(i*i+j*j)));
            #else
            	float w = -a[index];
            #endif

            accum += w * texture(iChannel0, fract(uv + tx * vec2(i,j)));
        }
    }
    
    vec4 fast = texture(iChannel1, uv) + accum;
    vec4 slow = (neighbor_avg(iChannel2, uv, tx) - texture(iChannel0, uv)) / _K0;
	fragColor = mix(fast, slow, SOLVER_BLEND);
}
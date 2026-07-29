// Common (common) — FFT Fluid - analysis rory618 cod by FabriceNeyret2
// https://www.shadertoy.com/view/tdfSR4

// Data structure:

//   O.xyzw contains either V.xy or ^V.xy (even vs odd frames) 
//   that are complex numbers: O.xy = Vx and O.zw = Vy (0 if world velocity)


// Fourier calculation:

// - done independently on Vx and Vy
// - 2D Fourier = Fy(Fx(image)): BufA,B do Fx, BufC,D do Fy
// - 1D Fourier is done by incomplete FFT: Cooley-Tukey on DFT blocks
//   - Data structure:
//       Buf A,B = N0x horizontal blocks of size N1x (NO.N1 = R)
//                 equiv to array(N0x,N1x)
//       Buf C,D = N0y vertical blocks of size N1y 
//                 equiv to array(N0y,N1y)
//   - Algo:
//       Buf A,C : DTF along N0
//       Buf B,D : DTF along N1


// Fluid calculation:

// Forward:  (odd frames)
// - advect velocity (bufA) 
// - Fourier transform V (BuffA,B,C,D) -> ^V
// - apply mass conservation + viscosity in Fourier, see Jos Stam paper http://www.dgp.toronto.edu/people/stam/reality/Research/pdf/jgt01.pdf
// - display only if Fourier required (Image)
// Backward: (even frames)
// - Fourier transform ^V (BuffA,B,C,D) -> V
// - Apply forces (mouse control) (BuffD)
// - display fluid (density faked from velocity turbulent features) (Image)

#define viscosity 1e-7 // 1e-7: turbulent 1e-5: some diffusion

#define pi 3.14159265
#define R  iResolution
#define iR ivec3(R)
#define T(x,y) texelFetch(iChannel0, ivec2(x,y), 0)
#define keypressed(c) (texelFetch(iChannel2,ivec2(c,2),0).x > .5)

// --- (i)FFT sum on blocks
                            // FFT vs iFFT at even vs odd frame
#define FFT_DIR float((iFrame%2)*2-1)
#define FORWARD 1.
#define BACKWARD -1.
                             // exp( s* 2iPi k/N )
#define W(k,n) cexp(vec2(0,FFT_DIR*(2.*pi*float(k)/float(n))))

/**/
                             // partial DFT on blocks
#define SUM(v,n0,n2, V)                  \
    setRadix(R);                         \
    int x = int(I.x),                    \
        y = int(I.y),                    \
        n = v/n0;  v = v%n0;             \
    O = vec4(0);                         \
    for(int i = 0; i < 64; i++){         \
        if (i >= n2) break;              \
        vec2 w = W(i*n,n2);              \
        O.xy += cprod(V.xy,w);           \
        O.zw += cprod(V.zw,w);           \
    }
/**
vec2 sum;                    // sum(expr) on blocks
#define SUM(expr, ind, len)            \
    sum = vec2(0);                     \
    for(int ind = 0; ind < 64; ind++){ \
        if (ind >= len) break;         \
        sum += expr;                   \
    }
/**/

// --- radix calculation:
// partial FFT on blocks N1,N2 close to sqrt(R) with N1.N2=R
// more understanding needed (e.g. N1,N2 vs 64)
// See https://en.wikipedia.org/wiki/Cooley%E2%80%93Tukey_FFT_algorithm

int x_N0, x_N1,
    y_N0, y_N1;

int factor(float x){ // find largest f<sqrt(x) such that f*g = x
    int i = int(x),  // (isn't it costly to do that for each pixel*frame*buffer ?)
        f = int(sqrt(x));
    while( i % f > 0 ) f--;
    return f;
  //return float(i)/float(f);
}

void setRadix(vec3 R){  
    x_N0 = factor(R.x);
    y_N0 = factor(R.y);
    x_N1 = int(R.x)/x_N0;
    y_N1 = int(R.y)/y_N0;
    
}

// --- complex arithmetics

vec2 cprod(vec2 a, vec2 b){
    return mat2(a,-a.y,a.x) * b;
}

vec2 cis(float t){
    return cos(t - vec2(0,pi/2.));
}
vec2 cexp(vec2 z) {
    return exp(z.x)*cis(z.y);
}

float dot2(vec2 x) { return dot(x,x); }

// --- random numbers

int IHash(int a){
	a = (a ^ 61) ^ (a >> 16);
	a = a + (a << 3);
	a = a ^ (a >> 4);
	a = a * 0x27d4eb2d;
	a = a ^ (a >> 15);
	return a;
}

float Hash(int a){
	a = (a ^ 61) ^ (a >> 16);
	a = a + (a << 3);
	a = a ^ (a >> 4);
	a = a * 0x27d4eb2d;
	a = a ^ (a >> 15);
	return float(a) / float(0x7FFFFFFF);
}

#define Ihash3(x,y,z) IHash((x)^IHash((y)^IHash(z)))
    
vec2 rand2(int seed){
    return vec2(Hash(seed^0x348C5F93),
                Hash(seed^0x8593D5BB));
}


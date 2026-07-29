// Common (common) — Hangman+Alphabet Recognizer CNN by kishimisu
// https://www.shadertoy.com/view/mtKGDw

////// Difficulty level ///////////
///                             ///
    #define MAX_ATTEMPTS     7.
///                             ///
///////////////////////////////////

#define R              (iResolution.xy)
#define iAspect        (iResolution.x/iResolution.y)
#define iR             (1. - iResolution.y/iResolution.x)

/// Words dictionnary ///
// Each array contains 4 words
#define word_size  10
int[40] words0 = int[40](80,73,88,69,76,0,0,0,0,0,86,69,67,84,79,82,0,0,0,0,83,72,65,68,69,82,0,0,0,0,82,69,78,68,69,82,0,0,0,0);
int[40] words1 = int[40](86,69,82,84,69,88,0,0,0,0,70,82,65,71,77,69,78,84,0,0,84,69,88,84,85,82,69,0,0,0,66,85,70,70,69,82,0,0,0,0);
int[40] words2 = int[40](67,65,78,86,65,83,0,0,0,0,83,80,82,73,84,69,0,0,0,0,67,85,82,86,69,0,0,0,0,0,80,79,76,89,71,79,78,0,0,0);
int[40] words3 = int[40](83,72,65,68,69,82,0,0,0,0,68,69,80,84,72,0,0,0,0,0,67,79,76,79,82,0,0,0,0,0,70,73,76,84,69,82,0,0,0,0);
int[40] words4 = int[40](76,73,71,72,84,0,0,0,0,0,65,78,73,77,65,84,73,79,78,0,77,79,68,69,76,0,0,0,0,0,77,65,84,82,73,88,0,0,0,0);
int[40] words5 = int[40](66,76,69,78,68,0,0,0,0,0,70,82,65,77,69,0,0,0,0,0,83,67,69,78,69,0,0,0,0,0,82,65,83,84,69,82,0,0,0,0);
int[40] words6 = int[40](65,82,82,65,89,0,0,0,0,0,70,85,78,67,84,73,79,78,0,0,86,65,82,73,65,66,76,69,0,0,67,76,65,83,83,0,0,0,0,0);
int[40] words7 = int[40](79,66,74,69,67,84,0,0,0,0,73,78,72,69,82,73,84,0,0,0,69,86,69,78,84,0,0,0,0,0,81,85,69,85,69,0,0,0,0,0);
int[40] words8 = int[40](83,84,65,67,75,0,0,0,0,0,65,76,71,79,82,73,84,72,77,0,83,69,65,82,67,72,0,0,0,0,71,82,65,80,72,0,0,0,0,0);
int[40] words9 = int[40](67,82,89,80,84,79,0,0,0,0,76,79,71,73,67,0,0,0,0,0,78,69,85,82,65,76,0,0,0,0,76,69,65,82,78,73,78,71,0,0);

/// Neural Network Settings ///
// Input image dimension (28*28 = 784 input nodes)
#define input_res      28.

// Number of feature maps (filters) per layer
#define f1 8.
#define f2 8.
#define f3 8.
#define f4 10.
#define f5 10.
#define f6 10.

// Output filter dimensions for each layer
#define F1 26.
#define F2 24.
#define F3 12.
#define F4 10.
#define F5 8.
#define F6 4.

// Number of output nodes (26 letters: a-z)
#define num_classes    26.

/// "Hack" to display text easily
/// (shader coming soon)
//////////////////////////////////
float char(sampler2D s, vec2 u, int id) {
    return textureLod(s, (u + vec2(id%16, 15. - floor(float(id)/16.))) / 16.,0.).r * step(abs(u.x-.5),.5) * step(abs(u.y-.5),.5);
}
#define makeString(func_name)  float func_name(vec2 u)        { print
#define makeStringI(func_name) float func_name(vec2 u, int i) { print
#define FONT_TEXTURE iChannel3
#define print float d = 0.; (0
#define _end  ); return  d; }
#define _     ); u.x -= .4; d += char(FONT_TEXTURE, u, 
#define __    ); u.x -= .4; (0
#define _ch(i)  _ 65+i
#define _dig(i) _ 48+i
#define _qt _ 34
#define _dd _ 58
#define _un _ 95
#define _bl _ 91
#define _br _ 93
#define _A _ 65
#define _B _ 66
#define _C _ 67
#define _D _ 68
#define _E _ 69
#define _F _ 70
#define _G _ 71
#define _H _ 72
#define _I _ 73
#define _J _ 74
#define _K _ 75
#define _L _ 76
#define _M _ 77
#define _N _ 78
#define _O _ 79
#define _P _ 80
#define _Q _ 81
#define _R _ 82
#define _S _ 83
#define _T _ 84
#define _U _ 85
#define _V _ 86
#define _W _ 87
#define _X _ 88
#define _Y _ 89
#define _Z _ 90
#define _a _ 97
#define _b _ 98
#define _c _ 99
#define _d _ 100
#define _e _ 101
#define _f _ 102
#define _g _ 103
#define _h _ 104
#define _i _ 105
#define _j _ 106
#define _k _ 107
#define _l _ 108
#define _m _ 109
#define _n _ 110
#define _o _ 111
#define _p _ 112
#define _q _ 113
#define _r _ 114
#define _s _ 115
#define _t _ 116
#define _u _ 117
#define _v _ 118
#define _w _ 119
#define _x _ 120
#define _y _ 121
#define _z _ 122
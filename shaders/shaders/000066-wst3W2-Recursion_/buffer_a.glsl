// Buffer A (buffer) — Recursion! by AntoineC
// https://www.shadertoy.com/view/wst3W2

// ----------------------------------------------------------------------------------------
//	"Recursion!" by Antoine Clappier - Sep 2019
//
//	Licensed under:
//  A Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License.
//	http://creativecommons.org/licenses/by-nc-sa/4.0/
// ----------------------------------------------------------------------------------------

#define Width 1072.0
#define Height 603.0
#define ratio (iResolution.x/Width)
#define cp(xx,yy) (round(vec2((xx),(yy))*iResolution.x/1072.0))
#define cs(w,h) (floor(vec2((w),(h))*iResolution.x/(2.*1072.0)))

//#define rgb(r,g,b) vec3(r,g,b)/255.


#define SearchF vec3(1.0)

float dp;

// -------------------------
// IQ's signed distances
float sdBox(vec2 p, float x, float y, float w, float h)
{
    vec2 d = abs(p-vec2(x,y)-0.5*vec2(w,-h))-0.5*vec2(w,h);
    return length(max(d,vec2(0))) + min(max(d.x,d.y),0.0);
}

float sdRoundBox(vec2 p, float x, float y, float w, float h, float r)
{
    vec2 d = abs(p-vec2(x,y)-0.5*vec2(w,-h))-0.5*vec2(w,h)+r;
    return length(max(d,vec2(0))) + min(max(d.x,d.y),0.0) - r;
}

float ndot(vec2 a, vec2 b ) { return a.x*b.x - a.y*b.y; }

float sdRhombus( in vec2 p, in vec2 b ) 
{
    vec2 q = abs(p);
    float h = clamp((-2.0*ndot(q,b)+ndot(b,b))/dot(b,b),-1.0,1.0);
    float d = length( q - 0.5*b*vec2(1.0-h,1.0+h) );
    return d * sign( q.x*b.y + q.y*b.x - b.x*b.y );
}

// ---------------------------

float sdLine(vec2 p, vec2 a,vec2 b)
{ 
    p -= a, b -= a;
    float h = clamp(dot(p, b) / dot(b, b), 0., 1.);
    return length(p - b * h);
}


void Fill(in float sd, in vec3 color, inout vec3 o)
{
    o = mix(color, o, smoothstep(0., dp, sd));
}

void Stroke(in float sd, in vec3 fill, in vec3 stroke, inout vec3 o)
{
    o = mix(fill,   o, smoothstep(-0.5*dp, 0.5*dp, sd));
    o = mix(stroke, o, smoothstep( 0.0, dp, abs(sd)));
}

void FillBox(vec2 p, float x, float y, float w, float h, vec3 fill, inout vec3 o)
{
    float sd = sdBox(p, x,y, w,h);
    Fill(sd, fill, o);
}

void FillRbox(vec2 p, float x, float y, float w, float h, float r, vec3 fill, inout vec3 o)
{
    float sd = sdRoundBox(p, x,y, w,h, r);
    Fill(sd, fill, o);
}

void FillRtbox(vec2 p, float x, float y, float w, float h, float r, vec3 fill, inout vec3 o)
{
    float s = sdRoundBox(p, x, y, w, 2.0*r, r);
    s = min(s, sdBox(p, x, y-r, w, h-r));
    Fill(s, fill, o);
}

void FillRbbox(vec2 p, float x, float y, float w, float h, float r, vec3 fill, inout vec3 o)
{
    float s = sdRoundBox(p, x, y, w, h, r);
    s = min(s, sdBox(p, x, y, w, r));
    Fill(s, fill, o);
}

void StrokeRbox(vec2 p, float x, float y, float w, float h, float r, vec3 fill, vec3 stroke, inout vec3 o)
{
    float sd = sdRoundBox(p, x,y, w,h, r);
    Stroke(sd, fill, stroke, o);
}

void FillDisk(vec2 p, float r, vec3 fill, inout vec3 o)
{
    float s = length(p) - r;
    Fill(s, fill, o);
}


// IQ's heart
void Heart(vec2 p, vec3 color, inout vec3 o)
{
    float size = 1./12.;
    p *= size;
    p.y = -0.1 - p.y*1.2 + abs(p.x)*(1.0-abs(p.x));
    float r = length(p);
	float d = 0.5;
    
    o = mix(color, o, smoothstep(-size*dp, size*dp, r-d));
}


void Share(vec2 p, vec3 color, inout vec3 o)
{
    float size = 1./12.0;
    p *= size;

    float r = 0.16;
    float s;
    s = length(p-vec2(0.05+r, 0.5)) - r;
    s = min(s, length(p-vec2(0.95-r, 0.8)) - r);
    s = min(s, length(p-vec2(0.95-r, 0.2)) - r);
    s = min(s, sdLine(p, vec2(0.05+r, 0.5), vec2(0.95-r, 0.8)) - r/3.); 
    s = min(s, sdLine(p, vec2(0.05+r, 0.5), vec2(0.95-r, 0.2)) - r/3.); 

    o = mix(color, o, smoothstep(-size*dp, size*dp, s));
}

void FullScreen(vec2 p, vec3 color, inout vec3 o)
{
    float s = sdBox(p, 0.,0., 14.,14.);
    s = max(s, -sdBox(p, -1.,-6., 16.,2.));
    s = max(s, -sdBox(p, 6., 1., 2.,16.));
    s = max(s, -sdBox(p, 4.,-4., 6.,6.));
    o = mix(color, o, smoothstep(0., dp, s));
}





// -----------------------------------------------------------------------------
// Additional spacing based on typeface weight:
#define WeightWidth(weight) (0.05*0.4*(weight))

// Char spacing:
#define CharSpacing(size, weight) ((size)*(0.38 + 2.0*WeightWidth(weight)))



// Draw a glyph:
//  ascii:  ASCII character value
//  p:      pixel coordinate. (0,0) is left border and base line of char (corrected for weight).
//  eps:    pixel size.
//  coord:  coordinate of the character. 
//  color:  color.
//  size:   font size.
//  weight: Typeface weight [0.20 3], regular 1.
//  o:      frag color (in/out).
void Glyph(int ascii, vec2 p, float eps, float x, vec3 color, float size, float weight, inout vec3 o)
{
    // Scaling:
    p   /= size;
    eps /= size;
    
    // Weight width:
    float weightWidth = WeightWidth(weight);

    // Typeface Width (condensed = 1.5):
    //p.x *= 1.5;
    
    // Set char position:
    float charSpacing = CharSpacing(size, weight) / size; // divide by size since p is already scaled
    float dx = 0.31 - weightWidth; // bottom left corner of char
    float dy = 0.24 - weightWidth; 
    p += vec2(dx - charSpacing*x, dy);

    // Italic:
    //p.x += -0.30*(p.y-dy);
    
    // Is uv inside of [0 1] for both components?
    if(all(greaterThanEqual(vec4(p,1,1), vec4(0,0,p))))
    {
        // Get the distance (.w component of the sprite sheet):
        float g = texture(iChannel0, 0.0625*(p + vec2(ascii - ascii/16*16,15 - ascii/16))).w;

        // Fill interior:
        float b = 0.5*0.95 + weightWidth;
        float c = smoothstep(b + 0.7*eps, b - 0.7*eps , g);
        
        // Add to output:
        //o = mix(mix(o, vec3(1.,0.,0.), 0.20), color, c);
        o = mix(o, color, c);
    }
}



#define Upk0(idx, code, next) (x < 0 ? 0u : ((x) < (idx) ? code : (next)))
#define Upk(idx, code, next) ((x) < (idx) ? code : (next))

#define Decode4(len, c0) Upk0(len, c0, 0u)
#define Decode8(len, c0, c1) Upk0(4, c0, Upk(len, c1, 0u))
#define Decode12(len, c0, c1, c2) Upk0(4, c0, Upk(8, c1, Upk(len, c2, 0u)))
#define Decode16(len, c0, c1, c2, c3) Upk0(4, c0, Upk(8, c1, Upk(12, c2, Upk(len, c3, 0u))))
#define Decode20(len, c0, c1, c2, c3, c4) Upk0(4, c0, Upk(8, c1, Upk(12, c2, Upk(16, c3, Upk(len, c4, 0u)))))
#define Decode24(len, c0, c1, c2, c3, c4, c5) Upk0(4, c0, Upk(8, c1, Upk(12, c2, Upk(16, c3, Upk(20, c4, Upk(len, c5, 0u))))))

void Text4(vec2 p, float eps, vec2 pp, vec3 color, float size, float weight, inout vec3 o,
           int len, uint c0)
{
    p      -= vec2(pp.x, pp.y);   int x    = int(floor(p.x/CharSpacing(size, weight)));
    uint v  = Decode4(len, c0);          int char = int((v >> uint(8*(3-x%4))) & 0xffu);
    if(char != 0) { Glyph(char, p, eps, float(x), color, size, weight, o); }
}

void Text8(vec2 p, float eps, vec2 pp, vec3 color, float size, float weight, inout vec3 o,
           int len, uint c0, uint c1)
{
    p      -= vec2(pp.x, pp.y);   int x    = int(floor(p.x/CharSpacing(size, weight)));
    uint v  = Decode8(len, c0, c1);      int char = int((v >> uint(8*(3-x%4))) & 0xffu);
    if(char != 0) { Glyph(char, p, eps, float(x), color, size, weight, o); }
}

void Text12(vec2 p, float eps, vec2 pp, vec3 color, float size, float weight, inout vec3 o,
            int len, uint c0, uint c1, uint c2)
{
    p      -= vec2(pp.x, pp.y);   int x    = int(floor(p.x/CharSpacing(size, weight)));
    uint v  = Decode12(len, c0, c1, c2); int char = int((v >> uint(8*(3-x%4))) & 0xffu);
    if(char != 0) { Glyph(char, p, eps, float(x), color, size, weight, o); }
}

void Text16(vec2 p, float eps, vec2 pp, vec3 color, float size, float weight, inout vec3 o,
            int len, uint c0, uint c1, uint c2, uint c3)
{
    p      -= vec2(pp.x, pp.y);   int x    = int(floor(p.x/CharSpacing(size, weight)));
    uint v  = Decode16(len, c0, c1, c2, c3); int char = int((v >> uint(8*(3-x%4))) & 0xffu);
    if(char != 0) { Glyph(char, p, eps, float(x), color, size, weight, o); }
}

void Text20(vec2 p, float eps, vec2 pp, vec3 color, float size, float weight, inout vec3 o,
            int len, uint c0, uint c1, uint c2, uint c3, uint c4)
{
    p      -= vec2(pp.x, pp.y);   int x    = int(floor(p.x/CharSpacing(size, weight)));
    uint v  = Decode20(len, c0, c1, c2, c3, c4); int char = int((v >> uint(8*(3-x%4))) & 0xffu);
    if(char != 0) { Glyph(char, p, eps, float(x), color, size, weight, o); }
}

void Text24(vec2 p, float eps, vec2 pp, vec3 color, float size, float weight, inout vec3 o,
            int len, uint c0, uint c1, uint c2, uint c3, uint c4, uint c5)
{
    p      -= vec2(pp.x, pp.y);   int x    = int(floor(p.x/CharSpacing(size, weight)));
    uint v  = Decode24(len, c0, c1, c2, c3, c4, c5); int char = int((v >> uint(8*(3-x%4))) & 0xffu);
    if(char != 0) { Glyph(char, p, eps, float(x), color, size, weight, o); }
}

// -----------------------------------------------------------------------------

void ShowTime(vec2 p, vec3 color, inout vec3 o)
{
    p -= vec2(105., 246.);
    int t = int(round(iTime*100.0));
    float x = 7.;

    Glyph(0x30 + t%10, p, dp, x, color, 13., 2.0, o); x--; t /= 10;
    Glyph(0x30 + t%10, p, dp, x, color, 13., 2.0, o); x--; t /= 10;
    Glyph(0x2e       , p, dp, x, color, 13., 2.0, o); x--;
    Glyph(0x30 + t%10, p, dp, x, color, 13., 2.0, o); x--; t /= 10;
    if(t > 0) { Glyph(0x30 + t%10, p, dp, x, color, 13., 2.0, o); x--; t /= 10; }
    if(t > 0) { Glyph(0x30 + t%10, p, dp, x, color, 13., 2.0, o); x--; t /= 10; }
    if(t > 0) { Glyph(0x30 + t%10, p, dp, x, color, 13., 2.0, o); x--; t /= 10; }
}


void BufA(vec2 p, vec3 color, inout vec3 o)
{
    p -= vec2(623.,92.);
    float k = 2.8;
    float s;
    s =         sdRhombus(p, vec2(28.0,7.0));   p.y -= 5.0;
    s = max(s, -sdRhombus(p, vec2(28.0,7.0)));  p.y -= 3.0;
    s = min(s,  sdRhombus(p, vec2(28.0,7.0)));  p.y -= 5.0;
    s = max(s, -sdRhombus(p, vec2(28.0,7.0)));  p.y -= 3.0;
    s = min(s,  sdRhombus(p, vec2(28.0,7.0)));  p.y -= 5.0;
    s = min(s,  sdLine(p-vec2(44.,9.), vec2(-k,-k), vec2(k,k)) - 0.7);
    s = min(s,  sdLine(p-vec2(44.,9.), vec2(-k, k), vec2(k,-k)) - 0.7);
    s = min(s,  abs(length(p-vec2(44.,9.))-5.5) - 0.7 );
    o = mix(vec3(1), o, smoothstep(-dp, dp, s));

	p += vec2(5.5, 8.0);
    p.x *= 0.5;
    Glyph(0x42, p, dp, 0., vec3(0), 13., 1.6, o);
    p.x /= 0.5;

	p -= vec2(48.0, -48.0);
    p.x += 0.18*p.y;
    Glyph(0x23, p, dp, 0., color, 18., 2.0, o);
}


void ChannelBox(vec2 p, int idx, vec3 color1, vec3 color2, inout vec3 o)
{
    FillRtbox(p, 0.,  0., 110., 60., 4., vec3(0), o);
    FillRbbox(p, 0., -60., 110., 25., 4., color1, o);
    Text12(p, dp, vec2(5., -78.), color2, 14., 1.6, o, 10, 0x69436861u, 0x6e6e656cu, uint((0x30 + idx)<<24));
}

// --------------------------------------------------------------------
// shader:
#define TAU 6.28318530718


const vec3 BackColor	= vec3(0.0, 0.4, 0.58);
const vec3 CloudColor	= vec3(0.18,0.70,0.87);


float Func(float pX)
{
	return 0.6*(0.5*sin(0.1*pX) + 0.5*sin(0.553*pX) + 0.7*sin(1.2*pX));
}


float FuncR(float pX)
{
	return 0.5 + 0.25*(1.0 + sin(mod(40.0*pX, TAU)));
}


float Layer(vec2 pQ, float pT)
{
	vec2 Qt = 3.5*pQ;
	pT *= 0.5;
	Qt.x += pT;

	float Xi = floor(Qt.x);
	float Xf = Qt.x - Xi -0.5;

	vec2 C;
	float Yi;
	float D = 1.0 - step(Qt.y,  Func(Qt.x));

	// Disk:
	Yi = Func(Xi + 0.5);
	C = vec2(Xf, Qt.y - Yi ); 
	D =  min(D, length(C) - FuncR(Xi+ pT/80.0));

	// Previous disk:
	Yi = Func(Xi+1.0 + 0.5);
	C = vec2(Xf-1.0, Qt.y - Yi ); 
	D =  min(D, length(C) - FuncR(Xi+1.0+ pT/80.0));

	// Next Disk:
	Yi = Func(Xi-1.0 + 0.5);
	C = vec2(Xf+1.0, Qt.y - Yi ); 
	D =  min(D, length(C) - FuncR(Xi-1.0+ pT/80.0));

	return min(1.0, D);
}



vec3 Shader(vec2 UV)
{
	// Render:
	vec3 Color= BackColor;

	for(float J=0.0; J<=1.0; J+=0.2)
	{
		// Cloud Layer: 
		float Lt =  iTime*(0.5  + 2.0*J)*(1.0 + 0.1*sin(226.0*J)) + 17.0*J;
		vec2 Lp = vec2(0.0, 0.3+1.5*( J - 0.5));
		float L = Layer(UV + Lp, Lt);

		// Blur and color:
		float Blur = 4.0*(0.5*abs(2.0 - 5.0*J))/(11.0 - 5.0*J);

		float V = mix( 0.0, 1.0, 1.0 - smoothstep( 0.0, 0.01 +0.2*Blur, L ) );
		vec3 Lc=  mix( CloudColor, vec3(1.0), J);

		Color =mix(Color, Lc,  V);
	}

	return Color;
}
// --------------------------------------------------------------------

#define rgb(r,g,b) (vec3(float(r),float(g),float(b))/255.)

void mainImage( out vec4 o, in vec2 fragCoord )
{
    // Load time and dectect pause:
    //  (from a Morimea idea, see comments) 
     bool paused = (iTime == texelFetch(iChannel2,ivec2(1,0),0).a);
 
    // Switch mode:
    float mode = texture(iChannel2, vec2(0)).w;
	if(texelFetch( iChannel3, ivec2(32,0), 0 ).x > 0.5 && 10.*iTime - floor(mode) > 5.0)
    {
        mode = fract(mode) == 0. ? 0.5 : 0.0;
        mode += floor(10.*iTime);
    }
    
    
    vec2 v;
    dp = Width/iResolution.x;
    v = dp*(fragCoord + 0.5);
    
    vec3 c = vec3(0.,1.,0.);

    // Colors
	vec3 cBack, cTopBar, cBotBar, cText0, cText1, cTextS, cBar, cTabP, cTab, cTabO, 
         cTabS, cSep, cEditor, cCode, cNum, cNumB;
    
    if(fract(mode) == 0.0)
    {
        cBack   = rgb(189,189,189);
        cTopBar = rgb(64,64,64);
        cBotBar = rgb(170,170,170);
        cText0  = rgb(0,0,0);
        cText1  = rgb(255,255,255);
        cTextS  = rgb(153,153,153);
        cBar    = rgb(240,240,240);
        cTabP   = rgb(176,176,176);
        cTab    = rgb(140,140,140);
        cTabO   = rgb(247,176,48);
        cTabS   = rgb(247,176,48);
        cSep    = rgb(219,219,219);
        cEditor = rgb(255,255,255);
        cCode   = rgb(76,76,76);
        cNum    = rgb(115,115,115);
        cNumB   = cBar;
    }
    else
    {
        cBack   = rgb(16,16,16);
        cTopBar = rgb(56,56,56);
        cBotBar = rgb(56,56,56);
        cText0  = rgb(176,176,176);
        cText1  = rgb(255,255,255);
        cTextS  = rgb(153,153,153);
        cBar    = rgb(64,64,64);
        cTabP   = rgb(64,64,64);
        cTab    = rgb(64,64,64);
        cTabO   = rgb(176,80,16);
        cTabS   = rgb(64,64,64);
        cSep    = rgb(219,219,219);
        cEditor = rgb(0,0,0);
        cCode   = rgb(170,170,170);
        cNum    = rgb(170,170,170);
        cNumB   = rgb(0,0,0);
    }
    
 
    // Back texture:
    c = cBack.r+0.15*texture(iChannel1, 0.007*v.yx/dp).rrr;
    c = cBack.r+0.07*texture(iChannel1, 0.007*v.yx/dp).rrr;
    
    // Top and bottom banners:
    c = mix(c, cTopBar, step(Height - 44., v.y)); 
    c = mix(c, cBotBar, step(v.y, 22.));
    
    
    // Top Banner:
    // "Shadertoy"
    vec2 it = v - vec2(29., 576.);
    it.x -= 0.15*it.y;
    Text12(it, dp, vec2(0), cText1, 24., 2.0, c, 9, 0x53686164u, 0x6572746fu, 0x79000000u);
    //  - Search box:
    StrokeRbox(v, 170., 592.0, 300., 22., 5., vec3(1.0), vec3(0.0), c);
    it = v - vec2(180., 576.);
    it.x -= 0.3*it.y;
    Text12(it, dp, vec2(0), cTextS, 14., 1.0, c, 9, 0x53656172u, 0x63682e2eu, 0x2e000000u);
    //  - "Browse   New   Sign In"
    Text24(v, dp, vec2(907., 578.), cText1, 14., 2.0, c, 22, 0x42726f77u, 0x73652020u, 0x204e6577u, 0x20202053u, 0x69676e20u, 0x496e0000u);
   
    // Bottom banner
    // "Documentation"
    Text16(v, dp, vec2(37., 6.), cText0, 14., 1.5, c, 13, 0x446f6375u, 0x6d656e74u, 0x6174696fu, 0x6e000000u);
    // "Terms & Privacy"
    Text16(v, dp, vec2(138., 6.), cText0, 14., 1.5, c, 15, 0x5465726du, 0x73202620u, 0x50726976u, 0x61637900u);
    // "Feedback   Events"
    Text20(v, dp, vec2(250., 6.), cText0, 14., 1.5, c, 17, 0x46656564u, 0x6261636bu, 0x20202045u, 0x76656e74u, 0x73000000u);
    // "Roadmap   About"
    Text16(v, dp, vec2(376., 6.), cText0, 14., 1.5, c, 15, 0x526f6164u, 0x6d617020u, 0x20204162u, 0x6f757400u);
    // "by Beautypi"
    Text12(v, dp, vec2(988., 6.), cText0, 14., 1.5, c, 11, 0x62792042u, 0x65617574u, 0x79706900u);

    
    // Shader player
    //  - Shader
    vec3 cs = Shader(2.0*(v-vec2(36.,+264.)-0.5*vec2(500.,281.))/500.);
    c = mix(cs, c, smoothstep(0., dp, sdRoundBox(v, 36., 545., 500., 285., 4.)));
    
    //  - Player
    FillRbbox(v, 36., 263., 500., 24., 4., cBar, c);
    //  - Rewind:
    Text4(v, dp, vec2(59., 243.), cText0, 24., 1.0, c, 1, 0x02000005u);
    FillBox(v, 58., 257., 3., 13., cText0, c);
    //  - Play:
    if(paused)
    {
        Text4(v, dp, vec2(86., 243.), cText0, 24., 1.0, c, 1, 0x05000005u);
    }
    else
    {
        FillBox(v, 86., 257., 3., 13., cText0, c);
        FillBox(v, 92., 257., 3., 13., cText0, c);
    }
    
    //FillBox(v, 86., 257., 3., 13., cText0, c);
    //FillBox(v, 92., 257., 3., 13., cText0, c);
    // Time:
    ShowTime(v, cText0, c);
    // "60.0 fps   640 x 360"
    Text20(v, dp, vec2(186., 246.),cText0, 13., 2.0, c, 20, 0x36302e30u, 0x20667073u, 0x20202036u, 0x34302078u, 0x20333630u);
    // "REC"
    Text4(v, dp, vec2(427.5, 243.), cText0, 10., 1.3, c, 3, 0x52454300u);
    FillDisk(v-vec2(434.,256.), 3.8, cText0, c);
    //// "VR"
    //FillDisk(vec2(1.3*(v.x-432.),v.y-252.), 6.0, cText0, c);
    //FillDisk(vec2(1.3*(v.x-439.),v.y-252.), 6.0, cText0, c);
	//FillBox(v, 430.5, 258.0, 8., 5., cText0, c);
    //Text4(v, dp, vec2(431.5, 250.), cText1, 8., 1.6, c, 3, 0x56520000u);
    //  - Sound
    Glyph(31, vec2(480.-v.x, v.y-246.), dp, 0., cText0, 22., 1.0, c);
    //  - Fullscreen
    FullScreen(v - vec2(511.,259.), cText0, c);

    // Info:
    //  - "Recursion!"
    Text12(v, dp, vec2(36., 210), cText0, 20., 1.3, c, 10, 0x52656375u, 0x7273696fu, 0x6e210000u);
    //  - Share:
    Share(v - vec2(480., 211.), cText0, c);
    //  - Love:
    Heart(v - vec2(511., 217.), cText0, c);
    //  - Love count:
    Text4(v, dp, vec2(526., 212.), cText0, 14., 1.0, c, 1, 0x38000000u);
	
 	//  - "Views: 42, Tags: 2d"
    Text20(v, dp, vec2(36., 190.), cText0, 12., 1.0, c, 19, 0x56696577u, 0x733a2034u, 0x322c2054u, 0x6167733au, 0x20326400u);
    //  - "Created by"
    Text12(v, dp, vec2(366., 190.), cText0, 12., 1.0, c, 10, 0x43726561u, 0x74656420u, 0x62790000u);
    //  - "AntoineC"
    Text8(v, dp, vec2(420., 190.), cText0, 12., 2.0, c, 8, 0x416e746fu, 0x696e6543u);
    //  - "in 2019-09-25"
    Text16(v, dp, vec2(468., 190.), cText0, 12., 1.0, c, 13, 0x696e2032u, 0x3031392du, 0x30392d32u, 0x37000000u);

    // "An exercise in recursive"
    Text24(v, dp, vec2(36., 160.), cText0, 12., 1.0, c, 24, 0x416e2065u, 0x78657263u, 0x69736520u, 0x696e2072u, 0x65637572u, 0x73697665u);
    // "futility..."
    Text12(v, dp, vec2(162., 160.), cText0, 12., 1.0, c, 11, 0x66757469u, 0x6c697479u, 0x2e2e2e00u);

    //  - "Comments (0)"
    Text12(v, dp, vec2(36., 99.), cText0, 12., 1.0, c, 12, 0x436f6d6du, 0x656e7473u, 0x20283029u);
    //  - "Sign in"
    Text8(v, dp, vec2(36., 72.), cText0, 12., 2.0, c, 7, 0x5369676eu, 0x20696e00u);
    //  - "to post a comment"
    Text20(v, dp, vec2(79., 72.), cText0, 12., 1.0, c, 17, 0x746f2070u, 0x6f737420u, 0x6120636fu, 0x6d6d656eu, 0x74000000u); 


    
     
    // --------------------------

    
    // IDE:
    //  - + Tab
    FillRtbox(v, 566., 540., 42., 22., 8., cTabP, c);
    Text4(v, dp, vec2(581., 521.), cText0, 28., 1.5, c, 1, 0x2b000000u);
    // "Buffer A"
    FillRtbox(v, 613., 540., 70., 22., 8., cTab, c);
    Text8(v, dp, vec2(628., 526.), cText1, 12., 2.1, c, 8, 0x42756666u, 0x65722041u);    
    //  - Buf B Tab
    FillRtbox(v, 688., 540., 70., 22., 8., cTab, c);
    Text8(v, dp, vec2(628.+75., 526.), cText1, 12., 2.1, c, 8, 0x42756666u, 0x65722042u);    
    //  - Image Tab
    FillRtbox(v, 763., 540., 70., 22., 8., cTabO, c);
    Text8(v, dp, vec2(634.+2.*75., 526.), cText1, 12., 2.1, c, 5, 0x496d6167u, 0x65000000u);

    
    //  - Orange separator
    FillBox(v, 566., 518., 470., 4., cTabS, c);

    //  - Shader inputs dropdown
    FillRbox(v, 566., 509., 470., 20., 4., cBar, c);
    Text16(v, dp, vec2(580., 497.), cText0, 12., 1.0, c, 13, 0x53686164u, 0x65722049u, 0x6e707574u, 0x73000000u);
    
    //  - Editor
    FillRbbox(v, 566., 485., 470., 334., 4., cBar, c);
    FillRbbox(v, 566., 485., 470., 310., 4., cNumB, c);
	//  - Code:
    FillBox(v, 600., 485., 10., 310., cSep, c);
    FillBox(v, 602., 485., 434., 310., cEditor, c);
    // "> Compiled is 0.5 secs"
    Text24(v, dp, vec2(576., 159.), cText0, 12., 1.0, c, 22, 0x2020436fu, 0x6d70696cu, 0x65642069u, 0x6e20302eu, 0x35207365u, 0x63730000u);
    Text4(v, dp, vec2(570., 156.), cText0, 24., 1.0, c, 4, 0x05000000u);
    //  - Text size menu
    StrokeRbox(v, 951., 170., 36., 17., 5., cBar, vec3(0.5), c);
    Text4(v, dp, vec2(960., 158.), cText0, 12., 1.0, c, 4, 0x53202076u);
    Text4(v, dp, vec2(1006., 156.), cText0, 18., 1.0, c, 4, 0x3f000000u);
	//  - Full screen
    //FullScreen(v - vec2(919.,169.), cText0, c);
    

    ChannelBox(v - vec2(566. + 0.*119., 132.), 0, cBar, cText0, c);
    BufA(v, cText0, c);
    ChannelBox(v - vec2(566. + 1.*119., 132.), 1, cBar, cText0, c);
    ChannelBox(v - vec2(566. + 2.*119., 132.), 2, cBar, cText0, c);
    ChannelBox(v - vec2(566. + 3.*119., 132.), 3, cBar, cText0, c);

    // Source:
    // "void mainImage(out vec4 "
    Text24(v, dp, vec2(608., 472.), cCode, 12., 1.0, c, 24, 0x766f6964u, 0x206d6169u, 0x6e496d61u, 0x6765286fu, 0x75742076u, 0x65633420u);
    // "o, vec2 u) {o=texture(iC"
    Text24(v, dp, vec2(729., 472.), cCode, 12., 1.0, c, 24, 0x6f2c2076u, 0x65633220u, 0x7529207bu, 0x6f3d7465u, 0x78747572u, 0x65286943u);
    // "hannel0,u/iResolution.xy"
    Text24(v, dp, vec2(850., 472.), cCode, 12., 1.0, c, 24, 0x68616e6eu, 0x656c302cu, 0x752f6952u, 0x65736f6cu, 0x7574696fu, 0x6e2e7879u);
    // ").rgbb;}"
    Text8( v, dp, vec2(971., 472.), cCode, 12., 1.0, c, 8, 0x292e7267u, 0x62623b7du);

    // "78 / 14734 chars"
    Text16(v, dp, vec2(776., 159.), cText0, 12., 1.0, c, 16, 0x3738202fu, 0x20313437u, 0x33342063u, 0x68617273u);

    o = vec4(c, mode);
    
    // Store time:
    if(ivec2(fragCoord) == ivec2(1,0)) { o.w=iTime; }
}
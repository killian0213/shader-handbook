// Image (image) — Op shop jumpers by austinlanc
// https://www.shadertoy.com/view/Mt3yW7

// by Austin Lancaster
// pFrieze() uses code by FabriceNeyret2 found at https://www.shadertoy.com/view/ll2fWG


#define PI 3.14159265359
#define DURATION 4.0

vec2 offset = vec2(0.0);
vec3 col1;
vec3 col2;
bool jumper = true;

float rand(vec2 co){
    return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
}

float random() {
	offset.x+=1.0;
    return rand(offset);
}

mat2 scale(vec2 _scale)
{
    return mat2(_scale.x,0.0,
                0.0,_scale.y);
}

mat2 rotate2d(float _angle){
    return mat2(cos(_angle),-sin(_angle),
                sin(_angle),cos(_angle));
}

vec2 tile (vec2 uv)
{
    float cols = 3.0;
    float rows = 2.0;
    uv.x *= cols;
    uv.y *= rows;
    offset = floor(uv)+floor(iTime / DURATION)*2.0;
    uv = fract(uv);
    uv.x -= ((iResolution.x/cols-iResolution.y/rows)/(iResolution.x/cols))/rows;
    return scale(vec2((iResolution.x/cols)/(iResolution.y/rows), 1.0)) * uv;   
}

vec2 jumper_space (vec2 uv)
{
    uv -= vec2(0.5);
    uv *= vec2(1.7, 1.2);
    uv.y -= 0.075*(-0.5 + pow(abs(uv.x), 2.0));
    uv += vec2(0.5);
    
    // hem
    float s2 = 0.2;
    float s1 = 0.1;
    if (uv.y < s2 && uv.y >= 0.0) {
        uv.x -= 0.5;
        float xsign = sign(uv.x);
        uv.x = abs(uv.x);
        float h = uv.y / s2;
        uv.x += 0.1*(1.0 - pow(h, 0.25));
        uv.x *= xsign;
        uv.x += 0.5;
    }
    if (uv.y < s1 && uv.y >= 0.0 && uv.x < 1.0 && uv.x > 0.0) {
        uv.y = 0.01;
        uv.x = 0.5;
    }
    
    // collar
    vec2 c_uv = uv;
    c_uv.x -= 0.5;
    c_uv.x = abs(c_uv.x);
    float height = 0.15;
    float h = (c_uv.y - (1.0-height))/height;
    c_uv.x *= 4.0;

    float y = pow(c_uv.x, 2.0);
    c_uv.x *= 0.5;
    float y2 = 2.9*pow(c_uv.x, 2.0);
    if (h > y) {
		uv = vec2(-1.0);
    } else if (h > y2 - 0.3 && uv.y < 1.0) {
       uv.y = 0.01;
       uv.x = 0.5;
    }
    
    return uv;
}

vec2 sleeve_space (vec2 uv)
{
    uv.x -= 0.5;
    uv.x = abs(uv.x);
    uv.x += 0.5;
    
    uv -= vec2(0.5);
    uv = rotate2d(PI/8.0) * uv;
    uv = scale(vec2(5.0, 1.3)) * uv;
    uv.x *=0.5;
    uv += vec2(0.5)-vec2(1.65*0.5, -0.145);
    
    uv.x-=0.5;
    uv.y -= 0.075*(-0.5 + pow(abs(uv.x), 2.0));
    uv.x+=0.5;
    
    // sleeve
    float s2=0.35;
    float s1=0.15;
    
    if (uv.y < s2 && uv.y >= 0.0) {
        uv.x-=0.5;
        float xsign = sign(uv.x);
        uv.x = abs(uv.x);
        float h = (uv.y / s2) * PI;
        uv.x+=0.2*0.5*0.5*(cos(h) + 1.0);
        uv.x*=xsign;
        uv.x+=0.5;
    }
    if (uv.y < s1 && uv.y >= 0.0 && uv.x < 0.75 && uv.x > 0.25) {
        uv.y = 0.01;
        uv.x = 0.5;
    }
        
	return uv;
}

bool insideBox (vec2 uv, vec2 scale)
{
 	return abs(uv.x-0.5)<0.5*scale.x && abs(uv.y-0.5)<0.5*scale.y;   
}

bool insideBox (vec2 uv)
{
    
	return insideBox(uv, vec2(1.0, 1.0));
}

vec3 getColor() {
	vec3 col = 0.1+0.7*vec3(random(), random(), random());
    
    vec3 sepia = vec3((col.r * .393) + (col.g *.769) + (col.b * .189),
                (col.r * .349) + (col.g *.686) + (col.b * .168),
                (col.r * .272) + (col.g *.534) + (col.b * .131));
    return mix(col, sepia, 0.6 + 0.4*random());
}

void pickTwoColors() {
    col1 = getColor();
    col2 = getColor();
    
    // ensure a minimum constrasst
    float min_contrast = 0.15;
    vec3 col_diff = col1-col2;
    if (length(col_diff)< min_contrast) {
    	col_diff /= length(col_diff);
        col_diff *= min_contrast;
        col2 = col1-col_diff;
    }
}

vec3 pFrieze(vec2 uv) {
	uv.y = dot( cos( 3.* ceil(uv.y*2.0 + random()*2.0) * max(0.,.5-length(uv = fract(uv)-.5)) - vec2(33,0) ), uv);
    return mix(col1, col2, step(0.0, uv.y));
}

vec3 pLines(vec2 uv) {
    return vec3(0.0);
}

vec3 pJagged(vec2 uv) {
    vec3 col;
    float h = abs(uv.x-0.5)*2.0;
    float a = step(h, uv.y);
    col = mix(col2, col1, a);
	return col;   
}

vec3 pZigzag(vec2 uv) {
    float thickness = 0.1+random()*0.15;
	vec3 col;
    float h = abs(uv.x-0.5)*2.0*(1.0-2.0*thickness) + thickness;
    float a = step(h+thickness, uv.y);
    float b = 1.0-step(h-thickness, uv.y);
    col = mix(col2, col1, a+b);
	return col; 
}

vec3 pWave(vec2 uv) {
    float thickness = 0.2;
    vec3 col;
    float h = sin(uv.x*PI*2.0)*0.5+0.5;
    h *= 1.0-2.0*thickness;
    h += thickness;
    float a = step(h+thickness, uv.y);
    float b = 1.0-step(h-thickness, uv.y);
    col = mix(col2, col1, a+b);
	return col;   
}

vec3 pTexture(vec2 uv) {
    float thickness = 0.1+random()*0.15;
	vec3 col;
    float h = sin(PI*4.0*uv.x);
    float a = step(h+thickness, uv.y);
    float b = 1.0-step(h-thickness, uv.y);
    col = mix(col2, col1, a+b);
	return col; 
 	   
}

float pfCos(float a) {
    float selector = random();
    float middle = random()*0.7;
    return middle + (1.0 - middle)*cos(a*(4.0+4.0*step(0.5, selector)) + PI);
}

float pfCog(float a) {
    float selector = random();
    float middle = random()*0.7;
    return max(middle, cos(a*(4.0+4.0*step(0.5, selector)) + PI));
}

float pfCircle(float a) {
 	return 0.1 + 0.8*random();
}

vec3 pPolar(vec2 uv) {
    uv = vec2(0.5)-uv;
    float r = length(uv)*2.0;
    float a = atan(uv.y,uv.x);
    float f = pfCog(a);
    float x = step(f,r);
    vec3 col;
    col = mix(col2, col1, x);
    return col;
}

vec3 chooseP(vec2 uv) {
	float selector = random();
    if (selector < 0.5) {
        return pPolar(uv);
    } else if (selector < 0.6) {
		return pJagged(uv); 	
    } else if (selector < 0.7) {
        return pZigzag(uv);
    } else if (selector < 0.85) {
        return pWave(uv);
    } else {
        return pFrieze(uv);
    }
}

vec3 lStripe(vec2 uv) {
    vec3 col;
    float x;
    if (random() < 0.5) {
        x = 0.5;
    } else {
        x = random()*0.8 + 0.1;
    }
    if (uv.y > x) {
        col = col1;
    } else {
        col = col2;
    }
    return col;
}

// l for giving random angle?

// l with own selector for square patterns

// repeat pattern horizontally
vec3 lRepeatH(vec2 uv) {
    float repeats = 4.0 + random()*4.0;
	uv.x *= repeats;
    uv.x = fract(uv.x);
    float sel = random();
    return chooseP(uv);
}

vec3 mFullStripe(vec2 uv)
{
    float min = 2.0; float median = 5.0; float max = 14.0;
    uv.y += random();
    float selection = random();
    float rows;
    if (selection < 0.5) {
        selection *= 2.0;
        rows = floor(selection*(median - min) + min);
    } else {
        selection = (selection-0.5)*2.0;
    	rows = floor(selection*(max - median) + median);        
    }
    uv.y = fract(uv.y*rows);
    return lStripe(uv);
}

vec3 mMultipleStripe(vec2 uv)
{
    uv.y += random();
    float old_y = uv.y;
    float n = floor(2.0+random()*2.0);
    float thickness = 0.04+random()*0.09; //0.07+random()*0.06; polar
    uv.y = fract(uv.y*(1.0/thickness));
    float modVal = mod(floor(old_y*(1.0/thickness)),n); // TODO: check that this behaves properly with other offset changes
    offset += modVal; 
    for (float i = 0.0; i<1.0; i+=1.0/n)
    if (modVal > i) {
    	pickTwoColors();
    }
    return lRepeatH(uv);
}

vec3 mOneStrip(vec2 uv)
{
    float height;
    if (jumper) {
        height = 0.6;
    } else {
        uv.y *= 1.25;
        height = 0.25;
    }
    uv.y -= height;
    uv.y = clamp(uv.y*8.0, -0.1, 1.1);
    
    return lRepeatH(uv);
}

vec3 mCurved(vec2 uv)
{
    return vec3(0.0);
}

vec3 mFancyStrip(vec2 uv)
{
    float height; float scale; float sel = random();
    if (jumper) {
        height = 0.45;
        scale = 3.0;
    } else {
        uv.y *= 1.25;
        height = 0.25;
        scale = 12.0;
    }
    uv.y -= height;
    uv.y = clamp(uv.y*scale, -0.001, 1.0);
    if (jumper) {
        if (abs(uv.y-0.5)>0.25) {
            // edge stripes
            uv.y-=0.5;
            uv.y*=4.0;
            uv.y=abs(uv.y);
            uv.y-=1.0;
            
            if (sel > 0.5) {
                // extra stripe
                uv.y=uv.y*2.0;
                if (uv.y > 1.0) {
                    uv.y -= 1.0;   
                }
            }
        } else {
            // middle stripe
            pickTwoColors();
            uv.y-=0.5;
            uv.y*=2.0;
            uv.y+=0.5;
        }        
    }
    return lRepeatH(uv);
}

vec3 mOneDot(vec2 uv) {
    uv -= 0.5;
    uv.y *= 1.7/1.2; // matches with jumper space scaling
    uv *= 1.2;
    uv += 0.5;
    
    if (random() < 0.5) {
        // break into 4
     	uv -= 0.5;
        uv *= 2.0;
        uv = abs(uv);
    }

    if (jumper) {
 		return chooseP(uv);
    } else {
        return col1;
    }
}

vec3 chooseM(vec2 uv) {
    float sel = random();
    vec3 col;
    if (sel < 0.2) {
        col = mOneDot(uv);
    } else if (sel < 0.4) {
        col = mOneStrip(uv);
    } else if (sel < 0.6) {
        col = mMultipleStripe(uv);
    } else if (sel < 0.8) {
        col = mFancyStrip(uv);
    } else {
        col = mFullStripe(uv);   
    }
    return col;
}

vec3 pattern(vec2 uv) {

    vec3 col;
    if (uv.y < 0.02){
        // color trimmings
        col = col1 + (0.5 - step(1.0, length(col1)))*vec3(0.15);
    } else {
        float sel = random();
        return chooseM(uv);
    }
    
    return col;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
        
    vec2 uv = fragCoord/iResolution.xy;
    uv = tile(uv);
    vec2 js = jumper_space(uv);
    vec2 ss = sleeve_space(uv);
    
	pickTwoColors();

    vec3 col = vec3(1.0);
    
    if (insideBox(js)) {
        jumper = true;
        col = pattern(js);
    } else {
        jumper = false;
    }
    if (col == vec3(1.0) && insideBox(ss, vec2(0.5, 1.0))) {
    	col = pattern(ss);
        col *= 0.97;
    }
    if (col == vec3(1.0)) {
        col = vec3(1.0, 1.0, 0.875);
    }
    fragColor = vec4(col,1.5);
}

/*
TODO:
1.macropatterns
	X stripes
	X onedot
	X layeredstripes
	X strip
	X fancy strip
2. offset repeats (dots only)
3. increase variety of patterns looking at google image for inspiration
	more half-halfs
4. bans: 
	only dots for onedot
	only lines for fancy offbits

any way to make fancy stripe more continuous with other patterns?
uneven layeredstripes?
curved top-half?
guaranteed squares?
	separate lines and dots
*/
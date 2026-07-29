// Buffer A (buffer) — Distance field outline mask by Good
// https://www.shadertoy.com/view/XtG3Rt

//////////////////////////////
//   Read Write             //
//////////////////////////////
const vec4 bitShL = vec4(16777216.0, 65536.0, 256.0, 1.0);
const vec4 bitShR = vec4(1.0/16777216.0, 1.0/65536.0, 1.0/256.0, 1.0);
// only positive in range 0-1
vec4 packNormal( const in float value ){
    vec4 res = fract( value*bitShL );
	res.yzw -= res.xyz/256.0;
	return res;
}
float unpackNormal( const in vec4 value ){ return dot( value, bitShR );}

// only positive int
vec4 packInt(int val){
    vec4 res = floor(float(val)*bitShR);
    res.yzw -= res.xyz*256.0;
    return res;
}
float unpackInt( const in vec4 value ){ return dot(value, bitShL);}
// +-2147483 with 3 digit float precigion
vec4 packFloat( const in float val ){
   bool negative = sign(val)==-1.;
   vec4 res = floor(abs(val)*1000.0* bitShR);
   res.gba -= res.rgb*256.0;
   if(negative) res.r+=256.;
   return res;
}
float unpackFloat( in vec4 val ){
    float m = 1.0;
    if(val.r>=256.){ val.r-=256.; m=-1.0; }   
    return dot(val, bitShL)/1000.*m;
}


bool isCell(in vec2 p, in vec2 a) { return floor(p) == a;}
void savePixel(vec4 val, vec2 address, inout vec4 col, vec2 px){ if(isCell(px, address)) col=val;}
vec4 readPixel(vec2 address) { return texture(iChannel0, (floor(address)+0.5) / iChannelResolution[0].xy); }
void saveInt(int val, vec2 address, inout vec4 col, vec2 p){if(isCell(p, address)) col= packInt(val);}
float readInt(vec2 address){ return unpackInt(readPixel(address));}
void saveIntVec2(vec2 val, float id, inout vec4 col, vec2 p){
    saveInt(int(val.x), vec2(id,0.0), col, p);        
    saveInt(int(val.y), vec2(id,1.0), col, p);
}
void saveFloat(float val, vec2 address, inout vec4 col, vec2 px){ if(isCell(px, address)) col= packFloat(val);}
float readFloat(vec2 address){ return unpackFloat(readPixel(address));}

////// Constants ////////////////////////////////////////////////////////////////////////
const float PI    = 3.14159265358979323846;
const float SQRT2 = 1.41421356237309504880;

////// 2D Ttransformations ///////////////////////////////////////////////////////////////
vec2 translate(vec2 p, vec2 t){	return p - t;}
vec2 scale(vec2 p, float s){ return p * mat2(s, 0, 0, s);}
vec2 rotate(vec2 p, float a){return p * mat2(cos(a), -sin(a), sin(a), cos(a));}
vec2 rotateCCW(vec2 p, float a){	return p * mat2(cos(a), sin(a), -sin(a), cos(a));}

////// 2D Matrix Ttransformations /////////////////////////////////////////////////////////
mat3 rotate(float r){float c = cos(r), s = sin(r); return mat3(c,-s,0,  s,c,0,  0,0,1);}
mat3 scale(float s){ return mat3(s,0,0, 0,s,0, 0,0,1);}
mat3 translate(vec2 p) { return mat3(1,0,p.x, 0,1,p.y, 0,0,1);}
mat3 skew(float r) { return mat3(1,tan(r),0, 0,1,0, 0,0,1);}
mat3 skewVert(float r) { return mat3(1,0,0, tan(r),1,0, 0,0,1);}
mat3 inverse2x3(mat3 m){
      float a=m[0][0], b=m[0][1], c=m[0][2], d=m[1][0], e=m[1][1], f=m[1][2], t=a*e-b*d;
      return mat3(e/t, -b/t, (f*b-c*e)/t, -d/t, a/t, (-f*a+c*d)/t, 0, 0, 1);
}
vec2 transform(vec2 p, mat3 m){ return (vec3(p,1)*m).xy;}
////// Distance field functions //////////////////////////////////////////////////////////

float dfBox(vec2 p, vec2 size) {vec2 d = abs(p)-size; return max(d.x, d.y);}
float dfBox(vec2 p, vec4 b) {vec2 d = abs(-b.xy-b.zw*.5 + p) - b.zw*.5; return max(d.x, d.y);}
float dfRoundedBox(vec2 p, vec2 size, float radius){size -= vec2(radius);vec2 d = abs(p) - size; return min(max(d.x, d.y), 0.0) + length(max(d, 0.0)) - radius;}
float dfBoxRounded(vec2 p, vec4 b, float radius){ vec2 size = b.zw*.5-vec2(radius); vec2 d = abs(-b.xy-b.zw*.5 + p)-size;  return min(max(d.x, d.y), 0.0) + length(max(d, 0.0)) - radius;}

float dfCircle(vec2 p, float radius){	
    return length(p) - radius;
}
float dfLine(in vec2 p, in vec2 a, in vec2 b){
    vec2 pa = p - a, ba = b - a;
	float h = clamp(dot(pa,ba) / dot(ba,ba), 0., 1.);	
	return length(pa - ba * h);
}

////// UI /////////////////////////////////////////////////////////////////////////////////
float extract_bit(float n, float b){ return mod(floor(n/exp2(floor(b))),2.0);}
float extract_decimal(float n, float index){ return mod(n/pow(10.0, index),10.0);}
float drawDigit(int n, vec2 p){ p=floor(p);
    int i = n==0?0x69996:n==1?0x62227:n==2?0xE168F:n==3?0xE161E:n==4?0x99711:n==5?0xF8E1E:
    n==6?0x68E96:n==7?0xF1244:n==8?0x69696:n==9?0x69716:n==10?0x00700:n==11?0x00004:0xFFFFF;
    return extract_bit(float(i), mod(p.y,5.0) * 4.0 + 3.0-p.x);
}
float drawFloat(in float val, in float fractPrecision, in vec2 p, vec2 location, int zoom){
    p-=location; p/= float(zoom);
    float n = floor(p.x / 5.0); //current char index 
    p.x -= n*5.; //move origin
    if(p.y<0.||p.y>5.||n<0.||n>8.||p.x<0.||p.x>4.) return 0.; //out of digit bounds
    if(sign(val)<0.0){if(n==0.) return drawDigit(10, p);n-=1.; val=abs(val);}  //draw minus sign 
    float intCount = floor(val)==0.0 ? 1.0 : floor(log(val)/2.302585) +1.;//calculate int part length
    float count = intCount + fractPrecision; //totla number of digits to print 
    if(fractPrecision > 0.){val *= pow(10.,fractPrecision);}  // move decimal point 
    if(intCount <= n){if(intCount == n) return drawDigit(11, p); n-=1.0;}  //draw dot  
    if(count <= n)  return 0.0; //no need to draw more
    return drawDigit(int(extract_decimal(val, count-n-1.)), p); //draw digit   
}
float drawVec2(in vec2 val, in float fractPrecision, in vec2 p, vec2 location, int zoom){
    float r =drawFloat(val.y,fractPrecision, p, location, zoom);
    r+=drawFloat(val.x,fractPrecision, p, location+vec2(0,6*zoom), zoom);
    return r;
}

//////////////////////////////////////////////////////////////////////////////

const vec2 activeUIAddress = vec2(0,4);


float slider(in float id, in vec4 conf, in vec2 loc, in vec2 sp, inout vec4 col, inout float ui){ 
    float val = readFloat(vec2(id,0));//read saved value 
    vec4 data = readPixel(vec2(id,3));
    float activeUIID = readInt(activeUIAddress);    
    float slui = dfBoxRounded(floor(sp), vec4(loc,124,20), 5.0);
    slui = max(-slui-2.0, slui );    
    if(data.x==0.){ //set default value
        val = conf.x; data.x=.05;
    	saveFloat(val, vec2(id,0), col, sp);
    }if(iMouse.z <= 0.){//on mouse up
        data.g = 0.;//stop drag this point
        savePixel(vec4(0), activeUIAddress, col, sp);//unlock other controlls
    }else if(dfBox(iMouse.xy, vec4(loc, 120, 20))<2. && activeUIID==0.0){//on press
        data.g = .05;//start drag this point
        saveInt(int(id),activeUIAddress, col, sp);//lock other controlls
    }else if(data.g>0.0 && activeUIID==id){//on mouse drag
        float distanceFromLeftEdege = clamp(iMouse.x, loc.x, loc.x+120.0)-loc.x;
        val = mix(conf.y, conf.z, distanceFromLeftEdege/120.0);
        val = floor(val/conf.w) * conf.w;        
    	saveFloat(val, vec2(id,0), col, sp);
    }
        
    slui = min(slui, dfBoxRounded(floor(sp), vec4(loc+vec2(2,2),120.0*(val-conf.y)/(conf.z-conf.y),16), 3.0) );
    
    ui = min(ui, -drawFloat(val, 2.0, sp, loc+vec2(128,8), 1)); //val   
    //ui = min(ui, -drawFloat(conf.y, 2.0, sp, loc+vec2(0,24), 1)); //from   
    //ui = min(ui, -drawFloat(conf.z, 2.0, sp, loc+vec2(80,24), 1));  //to   
    //ui = min(ui, -drawFloat(conf.w, 2.0, sp, loc+vec2(50,-10), 1)); //step    
    ui = min(ui, slui);     
    savePixel(data, vec2(id,3), col, sp);     
    return val;    
}


vec2 controlPoint(float id, vec2 loc, mat3 stv, vec2 sp, inout vec4 col, inout float ui){
    
    vec4 data = readPixel(vec2(id,3));
    float activeUIID = readInt(activeUIAddress);
    vec2 m = transform(iMouse.xy, stv); //viewport mouse position 
    vec2 pos = vec2(readFloat(vec2(id,0)),readFloat(vec2(id,1)));//read saved value 
    
    
    if(data.x==0.){ //set default value
        pos = loc; data.x=.05;
    	saveFloat(pos.x, vec2(id,0), col, sp);
    	saveFloat(pos.y, vec2(id,1), col, sp);
    }
    vec2 spos = transform(pos, inverse2x3(stv));
    
    if(iMouse.z <= 0.){//on mouse up
        data.g = 0.;//stop drag this point
        savePixel(vec4(0), activeUIAddress, col, sp);//unlock other controlls
    }else if(distance(spos, iMouse.xy)<20. && activeUIID==0.0){//on press
        data.g = .05;//start drag this point
        saveInt(int(id),activeUIAddress, col, sp);//lock other controlls
        
    }else if(data.g>0.0 && activeUIID==id){//on mouse drag
        pos = m;//drag this point
        spos = iMouse.xy;//drag this point
    	saveFloat(pos.x, vec2(id,0), col, sp);
    	saveFloat(pos.y, vec2(id,1), col, sp);
    } 
    
    ui = min(ui, -drawVec2(pos, 2.0, sp, spos+vec2(10,-5), 1));    
    ui = min(ui, dfCircle(sp-spos, 6.));
    
    savePixel(data, vec2(id,3), col, sp); 
    
    return pos;
}


/////// Combine distance field functions //////////////////////////////////////////////////
float merge(float d1, float d2){return min(d1, d2);}


////// Grid //////////////////////////////////////////////////////////////////////////////
float chessboard(vec2 p){ p=floor(p*2.0); return mod(p.x+p.y, 2.0);}


/////////////////////////////////////////////////////////////////
//    Bezier                                                  //
///////////////////////////////////////////////////////////////
// Test if point p crosses line (a, b), returns sign of result
float testCross(vec2 a, vec2 b, vec2 p) {
    return sign((b.y-a.y) * (p.x-a.x) - (b.x-a.x) * (p.y-a.y));
}
// Solve cubic equation for roots
vec3 solveCubic(float a, float b, float c){
    float p = b - a*a / 3.0, p3 = p*p*p;
    float q = a * (2.0*a*a - 9.0*b) / 27.0 + c;
    float d = q*q + 4.0*p3 / 27.0;
    float offset = -a / 3.0;
    if(d >= 0.0) { 
        float z = sqrt(d);
        vec2 x = (vec2(z, -z) - q) / 2.0;
        vec2 uv = sign(x)*pow(abs(x), vec2(1.0/3.0));
        return vec3(offset + uv.x + uv.y);
    }
    float v = acos(-sqrt(-27.0 / p3) * q / 2.0) / 3.0;
    float m = cos(v), n = sin(v)*1.732050808;
    return vec3(m + m, -n - m, n - m) * sqrt(-p / 3.0) + offset;
}
// Find the unsigned distance from a point to a bezier curve
float usBezier(vec2 A, vec2 B, vec2 C, vec2 p){    
    B = mix(B + vec2(1e-4), B, abs(sign(B * 2.0 - A - C)));
    vec2 a = B - A, b = A - B * 2.0 + C, c = a * 2.0, d = A - p;
    vec3 k = vec3(3.*dot(a,b),2.*dot(a,a)+dot(d,b),dot(d,a)) / dot(b,b);      
    vec3 t = clamp(solveCubic(k.x, k.y, k.z), 0.0, 1.0);
    vec2 pos = A + (c + b*t.x)*t.x;
    float dis = length(pos - p);
    pos = A + (c + b*t.y)*t.y;
    dis = min(dis, length(pos - p));
    pos = A + (c + b*t.z)*t.z;
    dis = min(dis, length(pos - p));
    return dis;
}


bool keyPress(int ascii) {
	return (texture(iChannel1,vec2((.5+float(ascii))/256.,0.25)).x > 0.);
}

////// Masks for drawing /////////////////////////////////////////////////////////////////

float hardFill(float d){return step(0.0, -d);}
float fill(in float d, in float softness, in float offset){
    return clamp((offset +softness*.5 - d)/softness, 0.0, 1.0);
}
float simpleFill(float d){return clamp(-d, 0.0, 1.0);}
float sharpFill(in float d){return clamp(.5-d, 0.0, 1.0);} //same as fill(d, 1.0, 0.0)
float stroke(in float d, in float softness, in float offset, in float width){ 
   d = abs(d-offset);
   return clamp((width/2.0 +softness*.5 - d)/softness, 0.0, 1.0);
}

//////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////

void mainScene(inout vec4 col, in vec2 sp ){
    
    float zoom = 1.;
    
    if (keyPress(32)) { zoom = 1./10.; } //SPACE
    if (keyPress(90)) { zoom = 2.0; } //Z
    if (keyPress(88)) { zoom = .5; } //X
    
    //viewport transformation matrix 
    mat3 screenToView = translate(-iResolution.xy / 2.0)*scale(zoom); 
    mat3 screenToView2 = translate(vec2(-iResolution.x / 2.0, -25))*scale(0.025); 
    
    //ui elements
    float ui = 0.;
    vec2 pt1 = controlPoint(1.0, vec2(-125, -40), screenToView, sp, col, ui);
    vec2 pt2 = controlPoint(2.0, vec2(-35, 122), screenToView, sp, col, ui);    
    vec2 pt3 = controlPoint(3.0, vec2(115, 40), screenToView, sp, col, ui);     
    
    float softness = slider(5.0, vec4(1, 0,10, .25), vec2(20, 240), sp, col, ui);
    float offset = slider(6.0, vec4(0, -5, 5, .25), vec2(20, 200), sp, col, ui);
    float width = slider(7.0, vec4(2.5, 0, 10, .25), vec2(20, 160), sp, col, ui);
    
  
    
    ///////////////// output /////////////////
    if(sp.y > 80.){ //viewport 1
        
        
        vec2 p = transform(sp.xy, screenToView);  //viewport pixel position
        // background     
        col = vec4(0.5, 0.5, 0.5, 1.0) * (1.0 - length(iResolution.xy/2.0 - sp.xy)/iResolution.x); //gradient
        col.r -= .03*chessboard(p*.05); //grid2  
        
        // scene
        float lines = merge(dfLine(p, pt1, pt2), dfLine(p, pt3, pt2));
        float bz = usBezier(pt1, pt2, pt3, p);    
        float cc = dfCircle(p, 50.);

        col = mix(col, vec4(1.0, 0.7, 0.9, 1.0), stroke(cc, softness * zoom, offset * zoom, width * zoom));         
        col = mix(col, vec4(0.5, 0.7, 0.9, 1.0), stroke(bz, softness * zoom, offset * zoom, width * zoom)); 
        col = mix(col, vec4(0.2, 0.2, 0.2, 1.0), stroke(lines, zoom, .0, .5*zoom));
        
    }else if(sp.y > 5.){ //viewport 2    	
        vec2 p = transform(sp.xy, screenToView2);         
        col = vec4(0.5, 0.5, 0.5, 1.0) * (1.0 - length(iResolution.xy/2.0 - sp.xy)/iResolution.x); //gradient
        col.rgb -= .03*chessboard(p*.5); //grid2         
        
        float fn = stroke(p.x, softness, offset, width);
        float ln = p.y < fn ? -1. : 0.;
        col = mix(col, vec4(.4, 0.4, 0.4, 1.0), simpleFill(ln));
        col = mix(col, vec4(0.5, 0.7, 0.9, 1.0), 1.0-step(simpleFill(ln)*p.y,.0));
        col = mix(col, vec4(.3,.3,.3,1), hardFill(dfRoundedBox(p,vec2(.05,10), .0)));
        col = mix(col, vec4(.2,.2,.2,1), hardFill(dfRoundedBox(p-vec2(5,0),vec2(.025,10), .0)));
        col = mix(col, vec4(.2,.2,.2,1), hardFill(dfRoundedBox(p-vec2(-5,0),vec2(.025,10), .0)));
    }
    
    if(sp.y > 5.){ //draw only on non data area
        col = mix(col, vec4(1., 0.6, 0.1, 1.0), simpleFill(ui));
    }
}


void mainImage( out vec4 o, in vec2 p ){ 
    o = p.y <= 5.? texture(iChannel0,p.xy/iResolution.xy) : vec4(0);  //data for next frame
    mainScene(o, p);   
}
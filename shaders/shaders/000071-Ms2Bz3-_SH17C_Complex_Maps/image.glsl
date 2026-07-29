// Image (image) — [SH17C] Complex Maps by ttoinou
// https://www.shadertoy.com/view/Ms2Bz3

#define ANIMATION_SPEED (.75)
#define ENABLE_TEXT 

bool animationMode = true;

// https://www.shadertoy.com/view/ldBBzK
/* http://www.hsluv.org/comparison/ https://raw.githubusercontent.com/williammalo/hsluv-glsl/master/hsluv-glsl.fsh HSLUV-GLSL v4.2 HSLUV is a human-friendly alternative to HSL. ( http://www.hsluv.org ) GLSL port by William Malo ( https://github.com/williammalo ) Put this code in your fragment shader. */ vec3 hsluv_intersectLineLine(vec3 line1x, vec3 line1y, vec3 line2x, vec3 line2y) {  return (line1y - line2y) / (line2x - line1x); } vec3 hsluv_distanceFromPole(vec3 pointx,vec3 pointy) {  return sqrt(pointx*pointx + pointy*pointy); } vec3 hsluv_lengthOfRayUntilIntersect(float theta, vec3 x, vec3 y) {  vec3 len = y / (sin(theta) - x * cos(theta));  if (len.r < 0.0) {len.r=1000.0;}  if (len.g < 0.0) {len.g=1000.0;}  if (len.b < 0.0) {len.b=1000.0;}  return len; } float hsluv_maxSafeChromaForL(float L){  mat3 m2 = mat3(   3.2409699419045214 ,-0.96924363628087983 , 0.055630079696993609,   -1.5373831775700935 , 1.8759675015077207 ,-0.20397695888897657 ,   -0.49861076029300328 , 0.041555057407175613, 1.0569715142428786  );  float sub0 = L + 16.0;  float sub1 = sub0 * sub0 * sub0 * .000000641;  float sub2 = sub1 > 0.0088564516790356308 ? sub1 : L / 903.2962962962963;  vec3 top1 = (284517.0 * m2[0] - 94839.0 * m2[2]) * sub2;  vec3 bottom = (632260.0 * m2[2] - 126452.0 * m2[1]) * sub2;  vec3 top2 = (838422.0 * m2[2] + 769860.0 * m2[1] + 731718.0 * m2[0]) * L * sub2;  vec3 bounds0x = top1 / bottom;  vec3 bounds0y = top2 / bottom;  vec3 bounds1x =    top1 / (bottom+126452.0);  vec3 bounds1y = (top2-769860.0*L) / (bottom+126452.0);  vec3 xs0 = hsluv_intersectLineLine(bounds0x, bounds0y, -1.0/bounds0x, vec3(0.0) );  vec3 xs1 = hsluv_intersectLineLine(bounds1x, bounds1y, -1.0/bounds1x, vec3(0.0) );  vec3 lengths0 = hsluv_distanceFromPole( xs0, bounds0y + xs0 * bounds0x );  vec3 lengths1 = hsluv_distanceFromPole( xs1, bounds1y + xs1 * bounds1x );  return min(lengths0.r,    min(lengths1.r,    min(lengths0.g,    min(lengths1.g,    min(lengths0.b,     lengths1.b))))); } float hsluv_maxChromaForLH(float L, float H) {  float hrad = radians(H);  mat3 m2 = mat3(   3.2409699419045214 ,-0.96924363628087983 , 0.055630079696993609,   -1.5373831775700935 , 1.8759675015077207 ,-0.20397695888897657 ,   -0.49861076029300328 , 0.041555057407175613, 1.0569715142428786  );  float sub1 = pow(L + 16.0, 3.0) / 1560896.0;  float sub2 = sub1 > 0.0088564516790356308 ? sub1 : L / 903.2962962962963;  vec3 top1 = (284517.0 * m2[0] - 94839.0 * m2[2]) * sub2;  vec3 bottom = (632260.0 * m2[2] - 126452.0 * m2[1]) * sub2;  vec3 top2 = (838422.0 * m2[2] + 769860.0 * m2[1] + 731718.0 * m2[0]) * L * sub2;  vec3 bound0x = top1 / bottom;  vec3 bound0y = top2 / bottom;  vec3 bound1x =    top1 / (bottom+126452.0);  vec3 bound1y = (top2-769860.0*L) / (bottom+126452.0);  vec3 lengths0 = hsluv_lengthOfRayUntilIntersect(hrad, bound0x, bound0y );  vec3 lengths1 = hsluv_lengthOfRayUntilIntersect(hrad, bound1x, bound1y );  return min(lengths0.r,    min(lengths1.r,    min(lengths0.g,    min(lengths1.g,    min(lengths0.b,     lengths1.b))))); } float hsluv_fromLinear(float c) {  return c <= 0.0031308 ? 12.92 * c : 1.055 * pow(c, 1.0 / 2.4) - 0.055; } vec3 hsluv_fromLinear(vec3 c) {  return vec3( hsluv_fromLinear(c.r), hsluv_fromLinear(c.g), hsluv_fromLinear(c.b) ); } float hsluv_toLinear(float c) {  return c > 0.04045 ? pow((c + 0.055) / (1.0 + 0.055), 2.4) : c / 12.92; } vec3 hsluv_toLinear(vec3 c) {  return vec3( hsluv_toLinear(c.r), hsluv_toLinear(c.g), hsluv_toLinear(c.b) ); } float hsluv_yToL(float Y){  return Y <= 0.0088564516790356308 ? Y * 903.2962962962963 : 116.0 * pow(Y, 1.0 / 3.0) - 16.0; } float hsluv_lToY(float L) {  return L <= 8.0 ? L / 903.2962962962963 : pow((L + 16.0) / 116.0, 3.0); } vec3 xyzToRgb(vec3 tuple) {  const mat3 m = mat3(   3.2409699419045214 ,-1.5373831775700935 ,-0.49861076029300328 ,   -0.96924363628087983 , 1.8759675015077207 , 0.041555057407175613,   0.055630079696993609,-0.20397695888897657, 1.0569715142428786 );   return hsluv_fromLinear(tuple*m); } vec3 rgbToXyz(vec3 tuple) {  const mat3 m = mat3(   0.41239079926595948 , 0.35758433938387796, 0.18048078840183429 ,   0.21263900587151036 , 0.71516867876775593, 0.072192315360733715,   0.019330818715591851, 0.11919477979462599, 0.95053215224966058  );  return hsluv_toLinear(tuple) * m; } vec3 xyzToLuv(vec3 tuple){  float X = tuple.x;  float Y = tuple.y;  float Z = tuple.z;  float L = hsluv_yToL(Y);   float div = 1./dot(tuple,vec3(1,15,3));   return vec3(   1.,   (52. * (X*div) - 2.57179),   (117.* (Y*div) - 6.08816)  ) * L; }  vec3 luvToXyz(vec3 tuple) {  float L = tuple.x;  float U = tuple.y / (13.0 * L) + 0.19783000664283681;  float V = tuple.z / (13.0 * L) + 0.468319994938791;  float Y = hsluv_lToY(L);  float X = 2.25 * U * Y / V;  float Z = (3./V - 5.)*Y - (X/3.);  return vec3(X, Y, Z); } vec3 luvToLch(vec3 tuple) {  float L = tuple.x;  float U = tuple.y;  float V = tuple.z;  float C = length(tuple.yz);  float H = degrees(atan(V,U));  if (H < 0.0) {   H = 360.0 + H;  }   return vec3(L, C, H); } vec3 lchToLuv(vec3 tuple) {  float hrad = radians(tuple.b);  return vec3(   tuple.r,   cos(hrad) * tuple.g,   sin(hrad) * tuple.g  ); } vec3 hsluvToLch(vec3 tuple) {  tuple.g *= hsluv_maxChromaForLH(tuple.b, tuple.r) * .01;  return tuple.bgr; } vec3 lchToHsluv(vec3 tuple) {  tuple.g /= hsluv_maxChromaForLH(tuple.r, tuple.b) * .01;  return tuple.bgr; } vec3 hpluvToLch(vec3 tuple) {  tuple.g *= hsluv_maxSafeChromaForL(tuple.b) * .01;  return tuple.bgr; } vec3 lchToHpluv(vec3 tuple) {  tuple.g /= hsluv_maxSafeChromaForL(tuple.r) * .01;  return tuple.bgr; } vec3 lchToRgb(vec3 tuple) {  return xyzToRgb(luvToXyz(lchToLuv(tuple))); } vec3 rgbToLch(vec3 tuple) {  return luvToLch(xyzToLuv(rgbToXyz(tuple))); } vec3 hsluvToRgb(vec3 tuple) {  return lchToRgb(hsluvToLch(tuple)); } vec3 rgbToHsluv(vec3 tuple) {  return lchToHsluv(rgbToLch(tuple)); } vec3 hpluvToRgb(vec3 tuple) {  return lchToRgb(hpluvToLch(tuple)); } vec3 rgbToHpluv(vec3 tuple) {  return lchToHpluv(rgbToLch(tuple)); } vec3 luvToRgb(vec3 tuple){  return xyzToRgb(luvToXyz(tuple)); }


#define SPACE_CHAR (0x02U)
#define STOP_CHAR (0x0AU)
float fontSize;

#ifdef ENABLE_TEXT

    #define fontChannel (iChannel1)

    // https://www.shadertoy.com/view/Xd2fzK
    vec4 fontCol;vec3 fontColFill;vec3 fontColBorder;vec4 fontBuffer;vec2 fontCaret;float fontSpacing;vec2 fontUV;vec4 fontTextureLookup(vec2 xy){	float dxy = 1024.*1.5; 	vec2 dx = vec2(1.,0.)/dxy; 	vec2 dy = vec2(0.,1.)/dxy; return (texture(fontChannel,xy + dx + dy)+texture(fontChannel,xy + dx - dy)+texture(fontChannel,xy - dx - dy)+texture(fontChannel,xy - dx + dy)+ 2.*texture(fontChannel,xy))/6.;}void drawStr4(uint str){if( str < 0x100U )str = str * 0x100U + SPACE_CHAR;if( str < 0x10000U )str = str * 0x100U + SPACE_CHAR;if( str < 0x1000000U )str = str * 0x100U + SPACE_CHAR;for( int i = 0; i < 4; i++){uint xy = (str >> 8*(3 - i)) % 256U;if( xy != SPACE_CHAR ){vec2 K = (fontUV-fontCaret)/fontSize;if( length(K) < .6 ){vec4 Q = fontTextureLookup( ( K+ vec2(float(xy/16U) + .5,16. - float(xy%16U) - .5) )/16.);fontBuffer.rgb += Q.rgb * smoothstep(.6,.4,length(K));if( max(abs(K.x),abs(K.y)) < .5 ){fontBuffer.a = min(Q.a,fontBuffer.a);}}}if( xy != STOP_CHAR ) fontCaret.x += fontSpacing*fontSize;}}void beginDraw(){fontBuffer = vec4(.0,.0,.0,1.);fontCol = vec4(.0);fontCaret.x += fontSpacing*fontSize/2.;}void endDraw(){float a = smoothstep(1.,.0, smoothstep(.51,.53,fontBuffer.a));float b = smoothstep(.0,1.,smoothstep(.48,.51,fontBuffer.a));fontCol.rgb = mix( fontColFill , fontColBorder , b );fontCol.a = a;}void _(uint str){beginDraw();drawStr4(str);endDraw();}void _(uvec2 str){beginDraw();drawStr4(str.x);drawStr4(str.y);endDraw();}void _(uvec3 str){beginDraw();drawStr4(str.x);drawStr4(str.y);drawStr4(str.z);endDraw();}void _(uvec4 str){beginDraw();drawStr4(str.x);drawStr4(str.y);drawStr4(str.z);drawStr4(str.w);endDraw();}

    #define _2(a,b) (_(uvec2(a,b)))
    #define _3(a,b,c) (_(uvec3(a,b,c)))
    #define _4(a,b,c,d) (_(uvec4(a,b,c,d)))

#endif

/*
 *    0  1  2  3  4  5  6  7  8  9  A  B  C  D  E  F
 * 1      
 * 2     !                    (  )     +     -     /
 * 3  0  1  2  3  4  5  6  7  8  9     ;           ?
 * 4  @  A  B  C  D  E  F  G  H  I  J  K  L  M  N  O
 * 5  P  Q  R  S  T  U  V  W  X  Y  Z  [  \  ]  ^  _
 * 6     a  b  c  d  e  f  g  h  i  j  k  l  m  n  o
 * 7  p  q  r  s  t  u  v  w  x  y  z
 * 8  
 * 9                                               sqrt
 * A                                               
 * B        ²                                               

 * 
 */
uvec4 Txt_End = uvec4(0x45868702,0x43027516,0x47368696,0xE67602);

uvec4 Txt_Grid = uvec4(0x74279646,SPACE_CHAR,SPACE_CHAR,SPACE_CHAR);

uint  Txt_Func1 = 0xA7210A0AU;
uvec4 Txt_Func2 = uvec4(SPACE_CHAR);
uvec4 Txt_Func3 = uvec4(SPACE_CHAR);
float Txt_FuncOpacity = 0.;

uvec4 Txt_Desc1 = uvec4(0x34F6E666,0xF627D616,0xC602D416,0x073702);
uvec4 Txt_Desc2 = uvec4(SPACE_CHAR);
float Txt_DescOpacity = 0.;

uvec4 Txt_None4 = uvec4(SPACE_CHAR);
uvec4 Txt_Zero = uvec4(0xA55627F6,SPACE_CHAR,SPACE_CHAR,SPACE_CHAR);
uvec4 Txt_Angles = uvec4(0x05275637,0x56276756,0x370214E6,0x76C65637);
uvec4 Txt_1Rainbow = uvec4(0x13022516,0x96E626F6,0x7702,SPACE_CHAR);
uvec4 Txt_5Rainbows = uvec4(0x53022516,0x96E626F6,0x773702,SPACE_CHAR);
uvec4 Txt_7Rainbows = uvec4(0x73022516,0x96E626F6,0x773702,SPACE_CHAR);
uvec4 Txt_Lines = uvec4(0xC496E656,0x3702U,SPACE_CHAR,SPACE_CHAR);
uvec4 Txt_Circles = uvec4(0x34962736,0xC6563702,SPACE_CHAR,SPACE_CHAR);
//uvec4 Txt_Hyperbolas = uvec4(0x84970756,0x2726F6C6,0x163702,SPACE_CHAR);
uvec4 Txt_Parabolas = uvec4(0x05162716,0x26F6C616,0x3702,SPACE_CHAR);
uvec4 Txt_Ellipses = uvec4(0x54C6C696,0x07375637,SPACE_CHAR,SPACE_CHAR);
uvec4 Txt_Pole = uvec4(0x05F6C656,SPACE_CHAR,SPACE_CHAR,SPACE_CHAR);
uvec4 Txt_Trigo = uvec4(0x45279676,0xF602,SPACE_CHAR,SPACE_CHAR);


uvec4 Txt_Fractal = uvec4(0x64271636,0x4716C602,SPACE_CHAR,SPACE_CHAR);
uvec4 Txt_Mandelbrot = uvec4(0xD416E646U,0x56C62627U,0xF647020AU,0x0A0A0A0AU);
uvec4 Txt_Newton = uvec4(0xE4567747,0xF6E6020A,0x0A0A0A0A,0x0A0A0A0A);
uvec4 Txt_Sinus= uvec4(0x3596E657,0x37020A0A,0x0A0A0A0A,0x0A0A0A0A);

uvec4 Txt_Id = uvec4(0xA702,SPACE_CHAR,SPACE_CHAR,SPACE_CHAR);
uvec4 Txt_Squared = uvec4(0xA72B02,SPACE_CHAR,SPACE_CHAR,SPACE_CHAR);
uvec4 Txt_Pow5 = uvec4(0xA7E55302,SPACE_CHAR,SPACE_CHAR,SPACE_CHAR);
uvec4 Txt_Pow5PlusOne = uvec4(0xA7E553B2,0x1302,SPACE_CHAR,SPACE_CHAR);
uvec4 Txt_Polynom1 = uvec4(0x82A7E553,0xB223B296,0xA79282A7,0xD296F243);
uvec4 Txt_Polynom2 = uvec4(0x922B02,SPACE_CHAR,SPACE_CHAR,SPACE_CHAR);
uvec4 Txt_Sqrt = uvec4(0xF9A702U,SPACE_CHAR,SPACE_CHAR,SPACE_CHAR);
uvec4 Txt_Inv = uvec4(0x13F2A702,SPACE_CHAR,SPACE_CHAR,SPACE_CHAR);
uvec4 Txt_Inv3 = uvec4(0x23B213F2,0xA73B02,SPACE_CHAR,SPACE_CHAR);

uvec4 Txt_Exp = uvec4(0x56E5A702,SPACE_CHAR,SPACE_CHAR,SPACE_CHAR);
uvec4 Txt_Exp2 = uvec4(0x56E5A7D2,0x13F256E5,0xA702,SPACE_CHAR);
uvec4 Txt_Sin = uvec4(0x3796E602,0xA702,SPACE_CHAR,SPACE_CHAR);
uvec4 Txt_Tan = uvec4(0x4716E602,0xA702,SPACE_CHAR,SPACE_CHAR);
uvec4 Txt_TanTan = uvec4(0x4716E682,0x4716E602,0xA79202,SPACE_CHAR);
uvec4 Txt_Asin = uvec4(0x163796E6,0x02A702,SPACE_CHAR,SPACE_CHAR);
uvec4 Txt_Log = uvec4(0xC6F67602,0xA702,SPACE_CHAR,SPACE_CHAR);
uvec4 Txt_7Log = uvec4(0x73C6F676,0x02A702,SPACE_CHAR,SPACE_CHAR);
uvec4 Txt_LogLog = uvec4(0xC6F67682,0xC6F67602, 0xA79202,SPACE_CHAR);


uvec4 Txt_FMandelbrot = uvec4(0xA72BB234,SPACE_CHAR,SPACE_CHAR,SPACE_CHAR);
uvec4 Txt_FNewton1 = uvec4(0xA7D282A7,0xE543B256,0xE5964792,0xF28243A7);
uvec4 Txt_FNewton2 = uvec4(0x3B92,SPACE_CHAR,SPACE_CHAR,SPACE_CHAR);


uvec4 Txt_Zeta = uvec4(0xA5564716,0x02A702, SPACE_CHAR,SPACE_CHAR);

vec4 rgbToHpluv_(vec4 c,float gamma)
{
    return vec4(
        rgbToHpluv(
            pow(c.rgb,vec3(gamma))
        )/vec3(360.,100.,100.)
    ,c.a);
}

vec4 hpluvToRgb_(vec4 c,float gamma)
{
    return vec4(
        pow(
        	hpluvToRgb( vec3(c.r*360.,clamp(c.gb*100.,0.,100.)) )
        ,1./vec3(gamma))
    ,c.a);
}

#define PI (3.14159265359)
#define TWOPI (2.*3.14159265359)

// Complex basis
const vec2 c1 = vec2(1.,0.);
const vec2 ci = vec2(0.,1.);
const vec4 d1 = vec4(1.,0.,0.,0.);
const vec4 di = vec4(0.,1.,0.,0.);

/* Reals to Complex functions */

vec2 cpolar( float k , float t ){  return k*vec2(cos(t),sin(t));}

/* Complex to Complex functions */

vec2 cconj( vec2 z )  { return vec2( z.x , -z.y ); }
vec2 cmul( vec2 a, vec2 b )  { return vec2( a.x*b.x - a.y*b.y, a.x*b.y + a.y*b.x ); }
vec2 csquared( vec2 a )  { return vec2( a.x*a.x - a.y*a.y, 2.*a.x*a.y ); }
vec2 cexp( vec2 z ) { return cpolar(exp(z.x) , z.y ); }
vec2 clog( vec2 z ) { return vec2( log(length(z)) , atan(z.y , z.x) ); }
vec2 cdiv( vec2 a, vec2 b )  { float d = dot(b,b); return vec2( dot(a,b), a.y*b.x - a.x*b.y ) / d; }
vec2 cpow( vec2 z , float k ) { return cpolar(pow(length(z),k) , k*atan(z.y,z.x) ); }

#define cinv(a) (cdiv(c1,a))
#define cmuli(a) (cmul(ci,a))

/* Complex functions in .xy + Derivatives in .zw
   Only theses functions should be used
*/

// nothing in k and t should depends on z....
vec4 dpolar( float k , float t ){  return k*vec4(cos(t),sin(t),.0,.0);}

vec4 dmul( vec4 X , vec4 Y ){ return vec4(
    cmul(X.xy,Y.xy) ,
    cmul(X.xy,Y.zw)+cmul(X.zw,Y.xy) // product rule
); }

// special case where dY = 0, multiplication by constant
vec4 dmul( vec4 X , vec2 Y ){ return vec4(
    cmul(X.xy,Y.xy) ,
    cmul(X.zw,Y.xy)
); }

vec4 dsquared( vec4 X ){ return dmul(X,X); }

vec4 dinv( vec4 X ){ return vec4(
      cinv(X.xy) ,
      cdiv(-X.zw,csquared(X.xy)) // -dX/X²
); }

vec4 ddiv( vec4 X , vec4 Y ){ return vec4(
    cdiv(X.xy,Y.xy) ,
    cdiv( cmul(X.xy,Y.zw)-cmul(X.zw,Y.xy) ,csquared(Y.xy)) // division rule
); }


vec4 dchain( vec4 X , vec2 fX , vec2 dfX ){ return vec4(
    fX ,
    cmul(dfX,X.zw) // chain rule
); }

/*vec4 dlog( vec4 Z ){ return vec4(
    clog(Z.xy) ,
    cdiv(Z.zw,Z.xy) // chain rule + derivative is 1/Z
); }*/

vec4 dlog( vec4 Z ){ return dchain( Z , 
    clog(Z.xy) ,
    cinv(Z.xy) // derivative is 1/Z
); }

vec4 dexp( vec4 Z ){ return dchain( Z , 
    cexp(Z.xy) ,
    cexp(Z.xy) // derivative is the same function
); }

vec4 dpow( vec4 X , vec4 Y ){
	return dexp( dmul(dlog(X),Y ));
}

#define function_even(z,k) (dmul(k(z)+k(-z),d1*.5))
#define function_odd(z,k) (dmul(k(z)-k(-z),d1*.5))


vec4 dsin( vec4 X ){
    X = dmul(X,di);// remove this line for hyperbolic
	return function_odd( X , dexp );
}

vec4 dcos( vec4 X ){
    X = dmul(X,di); // remove this line for hyperbolic
	return function_even( X , dexp );
}

vec4 dtan( vec4 X ){
	return ddiv( dsin(X) , dcos(X) );
}

vec4 dacos( vec4 X ){
	return dmul( dlog(dpow(dsquared(X)-d1,.5*d1)+X) ,-di);
}


vec4 dzeta(vec4 Z)
{
    // algo from https://www.shadertoy.com/view/Ms2fWR
    // is it correct ?
    
    vec4 sum = vec4(.0);
    for(float i = 1.; i < 30.; ++i)
    {
        float li = log(i);
        float ck = cos(Z.y*li);
        float sk = sin(Z.y*li);
        //sum += sin(-Z.y * log(i) - vec2(1.57, 0.)) / pow(i, Z.x);
        //sum.xy -= vec2(cos(k),sin(k)) * pow(i, -Z.x);
        // crappy derivative... but works :p 
        //sum.zw -= vec2(sin(k),cos(k)) * pow(i, -Z.x) * log(i);
        sum -= vec4(ck,sk,sk*li,ck*li) * pow(i, -Z.x);
    }
    
     return vec4(sum.xy,sum.zw*24.);
}


/*
vec4 dtan( vec4 X ){
	return d1 - 2.*dinv( dexp( dmul(X,2.*di) ) + d1 );
}
*/
vec4 dasin( vec4 X ){
	return dmul( dlog(dpow(dsquared(X)+d1,.5*d1)+X) ,-di);
}

vec4 datan( vec4 X ){
	return dmul(dlog( 2.*dinv(d1 - X) - d1 ),-di*.5);
}




float viewportMagnify = 4.;
vec4 finalMagnify = d1*1.;

bool showDerivative;
float zeroScale = -4.;
float poleScale = 8.;
float lineThickness;
vec2  lineGrid;
vec4  lineColor1;
vec4  lineColor2;
vec4  zeroColor;
vec4  poleColor;
vec4  derivativeColor;
float hueCoeff;
float fontSpacingCoeff = 1.;
float gridOpacity = .0;

vec4 viewport(vec2 b){
    return vec4( (b / iResolution.xy - vec2(.5))
        *vec2(iResolution.x/iResolution.y,1.)
        *viewportMagnify , vec2(viewportMagnify) );
}

// animationMode == true
vec4 Animation(vec4 oZ,float time)
{
    float t;
    float d;
    float e;
    float dP = 1.; // pause time
    vec4 Z2,Z3,Z4,Z5;
    
    #define ANIM(D) d = D; time -= d; t = smoothstep(-d,.0,time); if(time >= -d)
    // mix Z2 and Z3 into Z2
    #define MORPH(K) Z2 = mix(Z2,Z3,smoothstep(-d,-d+K,time));
    #define CHANGETEXT if(t > .3)
    #define RESET CHANGETEXT{ Txt_Func2 = Txt_Id; } Z3 = oZ; MORPH(d-dP); if( t >= .95 ){Z2 = oZ;}
    
    zeroColor.a = .0;
    poleColor.a = .0;
    fontSpacingCoeff = 1.;
    hueCoeff = .0;
    lineGrid = vec2(1.)/4.;
    gridOpacity = .0;
    
    ANIM(2.)
    {
        Txt_DescOpacity = t;
        Txt_Func2 = Txt_Id;
        Z2 = oZ;
        fontSize = mix(1.,.16,t);
        Txt_FuncOpacity = t;
    }
    
    ANIM(1.)
    {
    }
    
    ANIM(2.) { zeroColor.a = t; CHANGETEXT { Txt_Desc1  = Txt_Zero; } }
    ANIM(2.) { hueCoeff = sqrt(t);  CHANGETEXT { Txt_Desc1  = Txt_1Rainbow; } }
    
    ANIM(2.) { gridOpacity = t;  CHANGETEXT { Txt_Desc1 = Txt_Grid; } }
    
        
    ANIM(4.) { Z3 = dsquared(oZ); MORPH(d-dP); 
              CHANGETEXT { Txt_Desc1 = Txt_Angles; Txt_Func2 = Txt_Squared;  }}
    ANIM(8.) { Z2 = dpow(oZ,d1*(2. + t*3.)); 
              CHANGETEXT { Txt_Func2 = Txt_Pow5; Txt_Desc1 = Txt_5Rainbows; }} 
    ANIM(3.) { Z3 = dpow(oZ,d1*5.) + d1;MORPH(2.); 
              CHANGETEXT { Txt_Func2 = Txt_Pow5PlusOne;  }} 
    ANIM(3.) { Z3 = dmul( dpow(oZ,d1*5.) + d1*2. + dmul(oZ,di),dsquared(oZ-di*.25)) ;MORPH(2.);
                CHANGETEXT { Txt_Func2 = Txt_Polynom1; Txt_Func3 = Txt_Polynom2; Txt_Desc1 = Txt_7Rainbows;
              fontSpacingCoeff = mix(fontSpacingCoeff,.6,clamp(t*3.,0.,1.)); } } 
    ANIM(4.) { Z3 = dpow(oZ,d1*.5)*3.*t; MORPH(d-dP);
               CHANGETEXT { Txt_Desc1 = Txt_Parabolas; Txt_Func2 = Txt_Sqrt; Txt_Func3 = Txt_None4;
                           fontSpacingCoeff = mix(fontSpacingCoeff,1.,t); }  }
    ANIM(2.) { Z2 = dpow(oZ,d1*.5)*(3.+t*6.); }
    
    ANIM(4.) {  Z3 = oZ; MORPH(2.);
              CHANGETEXT { Txt_Desc1 = Txt_Lines;Txt_Func2 = Txt_Id; }}
    ANIM(4.) { Z3 = dinv(oZ); MORPH(d-2.);
              CHANGETEXT { Txt_Func2 = Txt_Inv;  Txt_Desc1 = Txt_Circles;}}
    ANIM(2.) { poleColor.a = t;
              CHANGETEXT { Txt_Desc1 = Txt_Pole;} }
    ANIM(4.) { Z2 = t*d1*.2 + dpow(oZ,d1*(-1. - 2.*t));
              CHANGETEXT { Txt_Func2 = Txt_Inv3;} }
    
    ANIM(4.) { Z3 = oZ; MORPH(2.);
              CHANGETEXT { Txt_Func2 = Txt_Id; Txt_Desc1 = Txt_None4; }}
    ANIM(4.) { lineGrid = mix(lineGrid,vec2(1.,PI)/4.,t);  }
    ANIM(4.) { Z3 = dexp(oZ); Z3 *= 4.; MORPH(d-dP);
              CHANGETEXT { Txt_Func2 = Txt_Exp; Txt_Desc1 = Txt_Trigo;  }}
    ANIM(4.) { Z3 = dexp(oZ)-dexp(-oZ); Z3 *= 4.; MORPH(d-dP); 
              CHANGETEXT { Txt_Func2 = Txt_Exp2; }}
    ANIM(4.) { Z4 = dmul(oZ,mix(d1,di,t)); Z2 = dexp(Z4)-dexp(-Z4); Z2 *= 4.;
              CHANGETEXT { Txt_Func2 = Txt_Sin;  }}
    
    ANIM(4.) { Z3 = dtan(oZ); MORPH(d-dP);
              CHANGETEXT { Txt_Func2 = Txt_Tan;}}
    ANIM(4.) { Z3 = dtan(dtan(oZ)); MORPH(d-dP);
              CHANGETEXT { Txt_Func2 = Txt_TanTan;}}
    ANIM(4.) { RESET }
    ANIM(4.) { Z3 = dasin(oZ)*4.*t; MORPH(d-dP);
              CHANGETEXT { Txt_Func2 = Txt_Asin; Txt_Desc1 = Txt_Ellipses; }}
    ANIM(4.) { Z2 = dasin(oZ)*(4. + 6.*t); }
    ANIM(4.) { Z2 = dmul(dasin(oZ),mix(d1,di,t*.5))*10.;
              CHANGETEXT { Txt_Desc1 = Txt_None4; }}
    
    ANIM(4.) { Z3 = oZ; MORPH(d-dP);
             CHANGETEXT { Txt_Func2 = Txt_Id; }}
    ANIM(5.) { Z3 = dlog(oZ); MORPH(4.);
               CHANGETEXT { Txt_Func2 = Txt_Log;}}
    ANIM(8.) { Z3 = dlog(oZ)*(1. + t*6.); MORPH(7.);
               CHANGETEXT { Txt_Func2 = Txt_7Log;}}
    ANIM(8.) { Z3 = dlog(dlog(oZ))*4.; MORPH(7.);
               CHANGETEXT { Txt_Func2 = Txt_LogLog;}}
    
    ANIM(4.) { RESET }
    
    #define LOOP(K,OP) \
       Z2 = .0*d1; e = min(floor(time+d),K); \
       for( int i = 0 ; i < 14 ; i++ ) \
       { if( float(i) < e ) { Z3 = OP; } } \
       Z4 = OP; \
       Z2 = mix(Z3,Z4,smoothstep(e,e+1.,time+d));
    
    ANIM(6.) { Z5 = mix(oZ,oZ*.4-d1*.8,clamp(t*8.,0.,1.)); Z3 = Z5; LOOP(5.,dsquared(Z3)+Z5);
                { Txt_Func2 = Txt_FMandelbrot;
                           Txt_Desc1 = Txt_Mandelbrot; Txt_Desc2 = Txt_Fractal; } }
    ANIM(4.) { CHANGETEXT{ Txt_Func2 = Txt_Id; Txt_Desc1 = Txt_None4; Txt_Desc2 = Txt_None4; }
              Z3 = oZ;
              Z2 = mix(Z2,Z3,smoothstep(-d,-d+d-dP,time*1.9));
              if( t >= .95 ){Z2 = oZ;}
             }
    ANIM(1.) { RESET }
    
    ANIM(10.) { Z3 = oZ; LOOP(9.,dsin(Z3));
                { Txt_Func2 = Txt_Sin; Txt_Desc1 = Txt_Sinus; Txt_Desc2 = Txt_Fractal; } }
    
    ANIM(2.) { RESET }
    ANIM(1.) { RESET }
    
    // z-(z^4+e^it)/(4z^3)
    ANIM(12.) {  { Txt_Desc1 = Txt_Newton; Txt_Func2 = Txt_FNewton1;
                            Txt_Func3 = Txt_FNewton2; fontSpacingCoeff = mix(fontSpacingCoeff,.6,clamp(t*10.,0.,1.)); }
               Z3 = oZ; LOOP(9.,(Z5 = dsquared(Z3),  Z3 -  ddiv( dsquared(Z5) + dpolar(1.,t*14.) , 4.*dmul(Z5,Z3) ) )    ); }
    ANIM(6.) { RESET; CHANGETEXT {Txt_Func3 = Txt_None4; Txt_Desc2 = Txt_None4; Txt_Desc1 = Txt_None4; fontSpacingCoeff = mix(fontSpacingCoeff,1.,t); } }
    
    
    ANIM(1.) { RESET; Txt_Func2 = Txt_Zeta;  }
    ANIM(7.) { poleScale *= 1. + t; lineGrid = mix(lineGrid,vec2(1)/6.,t);
              Z3 = dmul(dzeta( (oZ+cos(di*time*.3))*3.),dpolar(1.,time*.5));  MORPH(d-dP) }
    
    
    ANIM(5.) { fontSize = mix(.25,.16,1.-t); lineGrid = mix(lineGrid,vec2(1.)/16.,t);
        Txt_Desc1 = Txt_End; }
    
    return Z2;
}


// animationMode == false
vec4 zDeformation(vec4 Z)
{
    return Z;
    //poleScale *= 2.;
    //return dzeta(Z*3.);

     
     //return vec4(sum.xy,sum.xy*16.)/2.;
     //return vec4(sum,sum*16.)/2.;
     //return vec4(sum,cdiv(Z.xy,sum))/2.;
    /*vec4 C = Z;
    for( int i = 0 ; i < 6 ; i++ )
    {
        //vec4 Z2 = dsquared(Z);
        //Z -= ddiv( dmul(Z,Z2) + dpolar(1.,iTime*.3) , 3.*Z2 );  // Newton Fractal Z^3+1
        
        float exponent = 2. + iTime*.3;
        Z -= ddiv( dpow(Z,exponent*d1) + d1 , exponent*dpow(Z,d1*(exponent-1.)) );  // Newton Fractal Z^3+1
        
        //Z = dsin(Z+C);
        //Z = dsquared(Z)+C;
    }
    return Z;*/
    
    /*return dexp(dsquared(Z)+dinv(Z));
    return dsin(Z);
    return dsin(Z);
    return dsin(dasin(Z));
    return datan(Z);
    return dsquared(Z)+dinv(Z);
    return (dtan(dsquared(Z)));
    return dinv(dsquared((Z)));
    return dasin(Z);
    return dmul(dtan(dpow((Z),d1*(-2.+cos(iTime)*4.))),Z);
    return dsin(dsin(dsin(dsin(dsin(Z)))));
    return ddiv( dmul(Z - d1,d1*cos(iTime)),Z + d1 );
    return dmul( ddiv(dlog(Z - d1),dlog(Z + d1 )) , 4.*d1 );
    return dpow(dlog(Z),d1*cos(iTime)*2.);
    return dmul(dlog(Z),dlog(Z));
    return Z;
    return dinv(Z);
    return dexp(dlog(Z));*/
}


vec3 zColor(vec4 Z,vec4 originalZ)
{
    if( showDerivative )
    {
        vec2 T = Z.zw;
        // mathematically more correct than doing nothing ?
        Z.zw = cdiv(Z.zw,originalZ.xy*.5);
        lineThickness *= 1.;
        //*/
        Z.xy = T;
    }
    
    vec2 d = mod(Z.xy,2.*lineGrid);
    d = min( d , 2.*lineGrid - d);
    
    
    
    float norm2 = log(dot(Z.xy,Z.xy));
    float dnorm2 = log(dot(Z.zw,Z.zw));

    vec3 col = hpluvToRgb_(vec4(
        hueCoeff*atan(Z.y,Z.x)/TWOPI,
        1.,//1.-1.*(.5 * + .5*cos(norm2*64.)),
        .8,
        1.
    ),1.).rgb;
    
    // Gradient isolines
    col = mix( col ,
              derivativeColor.rgb - col,
              //derivativeColor.rgb,
              // vec3(dot(col,vec3(.3,.6,.1))),// ,
       smoothstep( 1. - fwidth(log(length(Z.zw)))/lineThickness/256. , 1. , .5 + .5*cos(dnorm2*8.) )
       * derivativeColor.a
    );
    
    
    // Two grids
    col = mix( col , lineColor1.rgb ,
       smoothstep(lineThickness*length(Z.zw),.0,min( d.x , d.y ))*lineColor1.a*gridOpacity
    );
    
    
    d = mod(Z.xy + lineGrid,2.*lineGrid);
    d = min( d , 2.*lineGrid - d);
    
    col = mix( col , lineColor2.rgb ,
       smoothstep(lineThickness*length(Z.zw),.0,min( d.x , d.y ))*lineColor2.a*gridOpacity
    );
    
    // Pole and zero
    col = mix( col , zeroColor.rgb ,
       smoothstep( 4. , 0. , norm2 - zeroScale ) * zeroColor.a 
    );
    
    col = mix( col , poleColor.rgb ,
       smoothstep( 3. , 1.5 , poleScale - norm2 ) * poleColor.a 
    );
    
    /*col = mix( col , vec3(1.,1.,1.) ,
       smoothstep( 0. , 1. ,
                  //fwidth(1./(1. + dnorm2 - norm2) )
                  fwidth(1./Z.w)
                 ) * 1.
    );*/
    
    // bugs
    #define ISNANORINF(x) (isnan(x) || isinf(x))
    if( ISNANORINF(Z.x) || ISNANORINF(Z.y) || ISNANORINF(Z.z) || ISNANORINF(Z.w) )
    {
        col = vec3(1.);
    }
    
    return col;
}

void mainImage( out vec4 fragColor, in vec2 coord )
{
    lineThickness = 1./iResolution.y;
    lineGrid = vec2(1.,PI)/8.; // vec2(1.);//
    lineColor1 = vec4(.1,.6,1.,.5);//vec4(.9,.4,.0,.5);
    lineColor2 = vec4(.1,.6,1.,-.5);
    zeroColor = vec4(.0,.0,.0,1.);
    poleColor = vec4(1.,1.,1.,1.);
    
    float music = texture(iChannel2,vec2(.8,.25)).r + texture(iChannel2,vec2(.1,.25)).r;
    music = pow(max(music-.6,.0)*3.,2.);
    derivativeColor = vec4(.2,.8,.3, mix(.0,.02,music) );
    showDerivative = false;
    hueCoeff = 1.;
	vec4 originalZ = viewport(coord);
    gridOpacity = 1.;
    
    
    /*if( iMouse.z > .5 )
    {
        showDerivative = true;
        derivativeColor.a = .0;
        //poleColor.a *= .5;
        lineThickness *= 1.;
        poleScale += 3.;
        zeroScale += 5.;
    }*/
    
    vec4 Z;
    
    if(animationMode)
    	Z = (Animation(originalZ,iTime*ANIMATION_SPEED));
    else
    	Z = (zDeformation(originalZ));
    
    Z = dmul(Z,finalMagnify);
    
	fragColor = vec4(zColor(Z,originalZ),1.0);
    
    #ifdef ENABLE_TEXT
        //fontSize = .08;//mix(.2,1.2,pow(cos(iTime*2.)*.5+.5,8.));
        fontCaret =  vec2(.02,fontSize*.6);
        fontSpacing = .455;//.9;
        fontUV = coord.xy/iResolution.y;
        fontColFill = vec3(1.);
        fontColBorder = vec3(.0);

        beginDraw();
        	drawStr4(Txt_Desc1.x);
        	drawStr4(Txt_Desc1.y);
        	drawStr4(Txt_Desc1.z);
       	 	drawStr4(Txt_Desc1.w);
    
        	drawStr4(Txt_Desc2.x);
        	drawStr4(Txt_Desc2.y);
        	drawStr4(Txt_Desc2.z);
       	 	drawStr4(Txt_Desc2.w);
        endDraw();
    
 
    
    
        fragColor = mix( fragColor , fontCol , clamp(fontCol.a*Txt_DescOpacity,.0,1.) );


        fontCaret =  vec2(.02, 1. - fontSize*.4 );
        fontSpacing = .8*fontSpacingCoeff;
    
        beginDraw();
        	drawStr4(Txt_Func1);
    
        	drawStr4(Txt_Func2.x);
        	drawStr4(Txt_Func2.y);
        	drawStr4(Txt_Func2.z);
       	 	drawStr4(Txt_Func2.w);
    
        	drawStr4(Txt_Func3.x);
        	drawStr4(Txt_Func3.y);
        	drawStr4(Txt_Func3.z);
       	 	drawStr4(Txt_Func3.w);
        endDraw();
    
        fragColor = mix( fragColor , fontCol , clamp(fontCol.a*Txt_FuncOpacity,.0,1.) );
    
    #endif
}
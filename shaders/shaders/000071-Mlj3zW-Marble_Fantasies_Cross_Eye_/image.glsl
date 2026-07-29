// Image (image) — Marble Fantasies (Cross Eye) by tholzer
// https://www.shadertoy.com/view/Mlj3zW


//---------------------------------------------------------
// MarbleFantasies.glsl  by Antony Holzer
// version:   v1.0  3/2015  initial release
//            v1.1  9/2017  cross eye stereo projection added
//            v1.2  7/2018  key handling added
//            v1.3  1/2019  stereo view correction
//            v1.4 11/2019  toggle background 
// original:  https://www.shadertoy.com/view/MtX3Ws
// info:      3d marble with transparent satiny inner structure
// changes:   added sphere antialiasing, extracted constants
//            texture will be generated
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
// tags:      3d, raytrace, sphere, antialiasing, transparency, satiny
// keys:   a  sphere pattern animation
//         b  toggle background 
//         f  sphere reflections 
//         r  rotate scene
//         s  cross eye stereo view
// mouse: rotate marble
//---------------------------------------------------------

//uniform float time;
//uniform vec2 mouse;
//uniform vec2 resolution;

// shadertoy defines
#define time iTime
#define mouse iMouse
#define resolution iResolution

//---------------------------------------------------------
// get javascript keycode: http://keycode.info/
//----------------------------------------------------------
const int KEY_A = 65;
const int KEY_B = 66;
const int KEY_C = 67;
const int KEY_D = 68;
const int KEY_E = 69;
const int KEY_F = 70;
const int KEY_G = 71;
const int KEY_H = 72;
const int KEY_I = 73;
const int KEY_J = 74;
const int KEY_K = 75;
const int KEY_L = 76;
const int KEY_M = 77;
const int KEY_N = 78;
const int KEY_O = 79;
const int KEY_P = 80;
const int KEY_Q = 81;
const int KEY_R = 82;
const int KEY_S = 83;
const int KEY_T = 84;
const int KEY_U = 85;
const int KEY_V = 86;
const int KEY_W = 87;
const int KEY_X = 88;
const int KEY_Y = 89;
const int KEY_Z = 90;
//----------------------------------------------------------
bool ReadKey(int key, bool toggle)
{
  return 0.5 < texture(iChannel3
    ,vec2((float(key)+0.5) / 256.0, toggle ? 0.75 : 0.25)).x;
}

//---------------------------------------------------------
// global settings
//---------------------------------------------------------
bool animate_pattern = false;    // a
bool show_background = true;     // b
bool show_reflections = false;   // f
bool rotation_scene = true;      // r
bool cross_eye_view = true;      // s
//---------------------------------------------------------
void keyInput()
{
  if (iFrame > 9)
  {
    animate_pattern   = !ReadKey(KEY_A, true);
    show_background   = !ReadKey(KEY_B, true);
    show_reflections  = !ReadKey(KEY_F, true);
    rotation_scene    = !ReadKey(KEY_R, true);
    cross_eye_view    = !ReadKey(KEY_S, true);
  }
}
//---------------------------------------------------------
// here some values to play for you ...

#define MAP_OCTAVE 7
#define BACK_COLOR vec3(0.4, 0.05, 0.05)
#define INNER_COLOR vec3(0.2, 0.2, 0.6)
#define GLAS_COLOR vec3(0.5, 0.5, 0.9)

//---------------------------------------------------------
vec2 csqr( vec2 a )  { return vec2( a.x*a.x - a.y*a.y, 2.*a.x*a.y ); }

mat2 rot(float a)    { return mat2(cos(a),sin(a),-sin(a),cos(a)); }

//---------------------------------------------------------
float map(in vec3 p)
{
    float res = 0.;
    vec3 c = p;
    for (int i = 0; i < MAP_OCTAVE; ++i)
    {
        p =.7*abs(p)/dot(p,p) -.7;
        p.yz += csqr(p.yz);
        p=p.zxy;
        res += exp(-25.0 * abs(dot(p,c)));
    }
    return res;
}
//---------------------------------------------------------
// intersect sphere:         from iq
//   ro = rayOrigin, rd = rayDirection,
//   sph.xyz = sphereCenter, sph.w = sphereRadius
// return intersection point distance
//---------------------------------------------------------
vec2 iSphere( in vec3 ro, in vec3 rd, in vec4 sph )
{
	vec3 oc = ro - sph.xyz;
	float b = dot (rd, oc);
	float c = dot (oc, oc);
	float h = b*b - c + sph.w*sph.w;
	if (h < 0.0) return vec2(-1.0);
	h = sqrt(h);
	return vec2(-b-h, -b+h );
}
//---------------------------------------------------------
vec3 raymarch( in vec3 ro, vec3 rd, vec2 tminmax )
{
    float t = tminmax.x;
    float dt = 0.02;
    if (animate_pattern)
      dt = 0.02 + 0.01*cos(time*0.5);

    vec3 col= vec3(0.);
    float c = 0.;
    for( int i=0; i<64; i++ )
    {
        t+=dt*exp(-2.*c);
        if(t>tminmax.y)break;
        vec3 pos = ro+t*rd;
        c = 0.45 * map(ro+t*rd);
        col = 0.98*col + 0.08*vec3(c*c, c, c*c*c);  // green
        col = 0.99*col + 0.08*vec3(c*c*c, c*c, c);  // blue
        col = 0.99*col + 0.08*vec3(c, c*c*c, c*c);  // red
    }
    return col;
}
//---------------------------------------------------------
void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    keyInput();

    vec2 uv = 2.0*(fragCoord.xy / resolution.xy) - 1.0;
    uv.x *= resolution.x / resolution.y;
    vec2 m = vec2(-0.5);
//  if( mouse.z > 0.0 )      // mouse pressed?
	m = mouse.xy / resolution.xy * 3.14;
//  m += mouse.xy * 3.14;    // use on glslsandbox.com

    float eye = 0.1;
    float radius = 1.4;

    if (cross_eye_view)     // stereo view ?
    {
      radius = 1.0;
      if (uv.x > 0.)
      {
        uv.x -= 0.8;
        eye = -0.1;
      } else {
        uv.x += 0.8;
        eye = 0.1;
      }
    }

    // camera
    vec3 ro = vec3(-6.8,0,0);   // origin
    ro.z += eye;
    ro.yz *= rot(m.y);
    ro.xz *= rot(m.x);
    if (rotation_scene)
      ro.xz *= rot(0.07*time);

    vec3 ta = vec3( 0.0);
    vec3 ww = normalize( ta - ro );
    vec3 uu = normalize( cross(ww,vec3(0.0,1.0,0.0) ) );
    vec3 vv = normalize( cross(uu,ww));
    vec3 rd = normalize( uv.x*uu + uv.y*vv + 4.0*ww );

    vec2 tmm = iSphere( ro, rd, vec4(0.,0.,0.,radius) );

    // raymarch
    vec3 col = raymarch(ro,rd,tmm);  // get sphere Color

    const float taa = 6.3;     // antialiasing limit
    float aa = (2.2*(tmm.x - taa));
    if ((tmm.x < 0.0) || (tmm.x > taa))
    {
        vec3 bgCol = vec3(0);
        if (show_background)
          bgCol = BACK_COLOR * map(rd);      // background color
        if (tmm.x > taa)
    	{
	        //bgCol = vec3(9.0, 5.0, 0.0);   // for testing antialiasing
            col = mix( col, bgCol, aa);      // do antialasing
        }
        else col = bgCol;        // set pure background color
    }

    if (tmm.x > 0.0)             // add sphere reflection ?
    {
        vec3 nor = reflect(rd, (ro+tmm.x*rd) * 0.5);  // sphere normal
        float fre = pow(0.3+ clamp(dot(nor,rd), 0.0, 1.0), 3. )*1.3;
        // add reflecting color
        col += GLAS_COLOR * fre * 0.1 *(1.0-aa);   // add some solid glas
        if (show_reflections)
            col += BACK_COLOR * map(nor) * fre * 0.3 *(1.0-aa);
    }

    // shade
    col = 0.5 *(log(1.0 + col));
    col = clamp(col, 0., 1.0);
    fragColor = vec4( col, 1.0 );
}

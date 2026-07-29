// Image (image) — Lonely sphere by bitless
// https://www.shadertoy.com/view/NtVXDh

// Author: bitless
// Title: A lonely sphere running over a field of voxels

// Thanks to Patricio Gonzalez Vivo & Jen Lowe for "The Book of Shaders"
// and Fabrice Neyret (FabriceNeyret2) for https://shadertoyunofficial.wordpress.com/
// and Inigo Quilez (iq) for  https://iquilezles.org/www/index.htm
// and whole Shadertoy community for inspiration.

// Special thanks to Shane for the "Isometric Height Map"
// https://www.shadertoy.com/view/flcSzX. 
// I got some ideas there to improve my code.

#define h21(p) ( fract(sin(dot(p,vec2(12.9898,78.233)))*43758.5453) ) //hash21
#define rot(a)   mat2(cos(a + vec4(0,11,33,0)))                             //rotate 2d
#define p(t, a, b, c, d) ( a + b*cos( 6.28318*(c*t+d) ) )                   //iq's palette


float noise( in vec2 f ) //gradient noise
{
    vec2 i = floor( f );
    f -= i;
    
    vec2 u = f*f*(3.-2.*f);

    return mix( mix( h21( i + vec2(0,0) ), 
                     h21( i + vec2(1,0) ), u.x),
                mix( h21( i + vec2(0,1) ), 
                     h21( i + vec2(1,1) ), u.x), u.y);
}

vec3 hexToSqr (vec2 st) //hexagonal cell coords to square face coords 
{ 
    vec3 r;
    if (st.y > 0.-abs(st.x)*.57777)
        if (st.x > 0.) 
            r = vec3((vec2(st.x,(st.y+st.x/1.73)*.86)*2.),3); //right face
        else
            r = vec3(-(vec2(st.x,-(st.y-st.x/1.73)*.86)*2.),2); //left face
    else 
        r = vec3 (-(vec2(st.x+st.y*1.73,-st.x+st.y*1.73)),1); //top face
    return r;
}

vec2 toSqr  (vec2 lc)
 {
    return vec2((lc.x+lc.y)*.5,(lc.x-lc.y)*0.28902);
 }
 
float T; //global timer
float sm; //smoothness factor
vec2 sp; //sphere position on isometric plane
 
void voxel (vec2 uv, vec2 id, vec2 lc, vec2 sh, inout vec4 C)
{

    vec2 ic = vec2((uv.x+uv.y*1.73),(uv.x-uv.y*1.73)); //isometic coordinates

    uv += sh*vec2(-1,.28902) ;
    vec2 ii = floor(vec2((uv.x+uv.y*1.73),(uv.x-uv.y*1.73))); //isometric grid cell's id
    float th = mix (                                                                                     //sphere track depth
                        mix(1.,noise (ii*.5)*.3,smoothstep (4.,1.,abs(ii.x+15.-noise(vec2(ii.y*.1,0.))*15.))) //sphere track
                        ,smoothstep(2.,4.,length(ii+sp-vec2(-.5,T+.5)))                                     //spot under sphere
                        ,smoothstep (2., -1., ii.y-T)) 
    
         , s =  pow(noise(vec2(h21(ii)*ii+iTime*.5)),8.)*.75 //small picks of altitude 
         , hg = (pow(noise(ii*.2*rot(1.) - iTime*.02),4.)-.5)*2.     //large noise
                 + s;

    hg = (hg+1.)*th - 1.;   //voxel altitude
    float sz = 1.1 + s*1.5*th; //voxel size variation
    
    vec3 vx = hexToSqr(lc-vec2(sh.x,(sh.y-(hg*2.-1.)/sz)*0.28902));  //voxel sides coords and side id
    
    vx.xy *= sz;
    
    vec4 V = vec4(p(ii.y*.05+hg*.3*th,vec3(.9),vec3(.7),vec3(.26),vec3(.0,.1,.2)),1.); //voxel color
    
    float f = mix(.3, (.9 - vx.z*.15),smoothstep (.45+sm,.45-sm, max(abs(vx.x-.5),abs(vx.y-.5)))); //sides of voxel 
    f = mix (f, 1.-length(vx.xy-vec2(.6)*1.2), smoothstep (.4+sm,.4-sm,length(vx.xy-.5))); //circles on sides
    f = mix (f, .4, smoothstep (.04+sm,-sm,abs(length(vx.xy-.5)-.4))); //circles edge
    f -= f*smoothstep(5.,3.,length(ic+sp-vec2(-.5,T+.5)))*.5; //shadow under sphere
    f += (hg+1.)*.07; //highlighting high-altitude voxels    
//    f = smoothstep (-0.5,1.6,f); //gamma correcton
    C = mix (C, V*f , smoothstep(1.+sm,1.-sm,max(vx.x,vx.y))); //mix colors with voxel mask 
}
 
void Draw (vec2 uv, inout vec4 C)
{
    sp = vec2((1.-noise(vec2(T*.1,0.)))*15.,0.); //sphere position on isometric plane
    vec2    st = vec2((uv.x+uv.y*1.73),(uv.x-uv.y*1.73)) //isometic coordinates
         ,  sc = toSqr(st+sp)-uv+vec2(.0,2.+noise(vec2(iTime*5.,0.))*.2) //sphere center
         ,  vc = uv; //coordinates for voxels 

    if (length(vc+sc) < 3.) //change coords for distortion effect on sphere
    {
        vc += sc;
        vc += vc*(pow(length(vc*.35),4.)) - sc; 
        sm = sm + .07;  //add small blur 
    }
    vc += toSqr(vec2(0.,T));

    vec2 id = floor(vec2((vc.x+vc.y*1.73),(vc.x-vc.y*1.73))); //cell id
    float n = mod(id.x+id.y+1.,2.);  //even and odd cells

    st = vec2((1.-n)*.5-vc.x,vc.y*1.73-n*.5); 
    id = floor(st)*vec2(1.,2.) + vec2(n*.5,n); //corrected cell id
    vec2 lc = fract(st) - vec2(.5);  //local cell corrdinates
    lc.y *= .57804;

    vec2[7] sh = vec2[7] (vec2(0,-2),vec2(.5,-1),vec2(-.5,-1),vec2(0,0),vec2(.5,1),vec2(-.5,1),vec2(0,2)); //coordinate offsets for voxel neighbors 
    
    for (int i = 0 ; i<7 ; i++) voxel (vc, id, lc, sh[i], C); //draw voxel and his neighbors
    
    uv+= sc;

    if (length(uv) < 3.) //add some colors for sphere
    {
        C = mix (C, 
            vec4(0,.05,.15,1),  
            noise(vec2(-uv.x,(uv.y+uv.x/1.73)*.86)*1.5*rot(-T*.15))*.4); //color spots on sphere);
        C += smoothstep(3.,-10., uv.y)*length(uv)*.1; //small light gradient on top of sphere 
    }
    
    C = mix (C, vec4(0),smoothstep (.02+sm,.02-sm,abs(length(uv)-3.))*.25); //small outline of sphere
}

void mainImage( out vec4 C, in vec2 g)
{
    vec2 rz = iResolution.xy
        ,uv = (g+g-rz)/-rz.y;
    uv += -.5;
    uv *= 1.+sin(iTime*.3)*.25; //camera scale
    sm = 3./iResolution.y;
    
    T = -iTime*4.-((sin(iTime*.5)+1.)*5.); //local timer with speed variation

    C = vec4(0);

    Draw (uv*5., C);

    uv*=5.;
    C=pow(C,vec4(1./1.4));
}
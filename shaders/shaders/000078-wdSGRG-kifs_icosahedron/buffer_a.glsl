// Buffer A (buffer) — kifs icosahedron by macbooktall
// https://www.shadertoy.com/view/wdSGRG

#define GIFLENGTH 3.14159
float clock;

// HG_SDF
// Brought to you by MERCURY http://mercury.sexy
// Released as Creative Commons Attribution-NonCommercial (CC BY-NC)

#define TAU (2*PI)
#define PHI (1.618033988749895)
#define GDFVector0 vec3(1, 0, 0)
#define GDFVector1 vec3(0, 1, 0)
#define GDFVector2 vec3(0, 0, 1)

#define GDFVector3 normalize(vec3(1, 1, 1 ))
#define GDFVector4 normalize(vec3(-1, 1, 1))
#define GDFVector5 normalize(vec3(1, -1, 1))
#define GDFVector6 normalize(vec3(1, 1, -1))

#define GDFVector7 normalize(vec3(0, 1, PHI+1.))
#define GDFVector8 normalize(vec3(0, -1, PHI+1.))
#define GDFVector9 normalize(vec3(PHI+1., 0, 1))
#define GDFVector10 normalize(vec3(-PHI-1., 0, 1))
#define GDFVector11 normalize(vec3(1, PHI+1., 0))
#define GDFVector12 normalize(vec3(-1, PHI+1., 0))

#define fGDFBegin float d = 0.;

// Version with variable exponent.
// This is slow and does not produce correct distances, but allows for bulging of objects.
#define fGDFExp(v) d += pow(abs(dot(p, v)), e);

// Version with without exponent, creates objects with sharp edges and flat faces
#define fGDF(v) d = max(d, abs(dot(p, v)));

#define fGDFExpEnd return pow(d, 1./e) - r;
#define fGDFEnd return d - r;

// Primitives follow:

float fIcosahedron(vec3 p, float r) {
fGDFBegin
    fGDF(GDFVector3) fGDF(GDFVector4) fGDF(GDFVector5) fGDF(GDFVector6)
    fGDF(GDFVector7) fGDF(GDFVector8) fGDF(GDFVector9) fGDF(GDFVector10)
    fGDF(GDFVector11) fGDF(GDFVector12)
    fGDFEnd
}

void pR(inout vec2 p, float a) {
p = cos(a)*p + sin(a)*vec2(p.y, -p.x);
}

// end HG_SDF
//----------------------------------------------------------------------


// smin by iq - https://iquilezles.org/articles/smin

float smin( float a, float b, float k ){
    float h = clamp( 0.5+0.5*(b-a)/k, 0.0, 1.0 );
    return mix( b, a, h ) - k*h*(1.0-h);
}

// --

vec2 mousePos;

float map(vec3 pos) {
    
    float scale = .55;
    vec3 spacesize = vec3(3.,4.,2.2);
    float distFromCam = length(pos)*0.4;
	vec3 originalPos = pos;

    // Divide the space into cells
    pos.xyz = mod(pos.xyz, spacesize) - spacesize*0.5;

    vec3 p = pos;
	vec2 mouse = vec2(0.7, 1.05) + mousePos;

    float cube = 1e20;
    float res = cube;
    vec3 displacement = vec3(-1., -.5, -2.)*0.75;

    for (int i = 0; i < 8; i++) {
        p.xyz = abs(p.xyz);

        float phase = clock+float(i)*0.25+distFromCam*2.;
        vec2 dispAnim = vec2( sin(phase), cos(phase))*0.025; 

        displacement.yz += dispAnim;
        
        p += displacement * scale;

        phase = clock+float(i)*0.5 + distFromCam;
        pR(p.xz,-distFromCam+mouse.y+float(i)+sin(phase)*.05);
        pR(p.zy,distFromCam+mouse.x+float(i)+cos(phase)*.075);  
   
		scale *= 0.6;
        
        float octa = fIcosahedron(p,scale);
      
        res = min(res,octa);    
    }

    // Animate the pos of the icosahedron
	originalPos.y += cos(length(pos.xz)*4.+clock)*0.015;
	originalPos+=vec3(1.5,1.1,-1.2);
    pR(originalPos.xy, .2+sin(clock)*0.2);
    pR(originalPos.xz,-iTime);
    
    // Smooth min blend the fractal terrain with itself with a param around zero to give it a scaling effect
    res = smin(res, res, -0.025+ sin(-0.5+clock-length(vec3(pos.x*0.5,pos.y*0.9,pos.z))*12.)*0.05);
    res = smin(res, fIcosahedron(originalPos,.2), 0.1);

    return res;
}

float castRay( in vec3 ro, in vec3 rd )
{
    float t = 0.;
    
    for( int i=0; i<50; i++ )
    {
   		float res = map( ro+rd*t );
   		if (res < 0.001)
            break;
    	t += res;
        if (t > 5.)
            break;
    }

    return t;
}

// by iq - https://www.shadertoy.com/view/Xds3zN


vec3 calcNormal( in vec3 pos )
{
	vec3 eps = vec3( 0.001, 0.0, 0.0 );
	vec3 nor = vec3(map(pos+eps.xyy) - map(pos-eps.xyy),
        			map(pos+eps.yxy) - map(pos-eps.yxy),
        			map(pos+eps.yyx) - map(pos-eps.yyx) );
	return normalize(nor);
}


float calcAO( in vec3 pos, in vec3 nor )
{
	float occ = 0.0;
    float sca = 1.0;
    for( int i=0; i<4; i++ )
    {
        float hr = 0.01 + 0.02*float(i)/4.0;
        vec3 aopos =  nor * hr + pos;
        float dd = map( aopos );
        occ += -(dd-hr)*sca;
        sca *= .95;
    }
    return clamp( 1.0 - 3.0*occ, 0.0, 1.0 );    
}

// -----------------------------

vec4 render( in vec3 ro, in vec3 rd )
{
    vec3 col = vec3(0.);
    float res = castRay(ro,rd);
    vec3 pos = ro + res*rd;
    vec3 nor = calcNormal( pos );
    vec3 ref = reflect( rd, nor );

    float occ = calcAO( pos, nor )*2.5;

    col = vec3(.75+dot(rd,nor));
    nor.b = .1-nor.b;
    nor.g = 0.;
    col *= (nor.rgb*0.5+0.5) ;
	
	col = mix(col, vec3(0.), clamp(res/4., 0., 1.));
    return vec4( clamp(col,0.0,1.0), res );
}

mat3 setCamera( in vec3 ro, in vec3 ta, float cr )
{
    vec3 cw = normalize(ta-ro);
    vec3 cp = vec3(sin(cr), cos(cr),0.0);
    vec3 cu = normalize( cross(cw,cp) );
    vec3 cv = normalize( cross(cu,cw) );
    return mat3( cu, cv, cw );
}

void mainImage( out vec4 fragColor, in vec2 fragCoord ) 
{
    clock = iTime*2.;
    mousePos = 2.*iMouse.xy/iResolution.xy;
    vec2 q = fragCoord.xy/iResolution.xy;
    vec2 p = -1.0+2.0*q;
    p.x *= iResolution.x/iResolution.y;

    vec3 ro = vec3(-0.2, -.75, .5);
    vec3 ta = ro+vec3(-1.8,-.5,1.);
    mat3 ca = setCamera( ro, ta, .0 );
    vec3 rd = ca * normalize(vec3(p.xy,3.6));
    vec4 col = render( ro, rd );

    fragColor=col;
}
// Cube A (cubemap) — Bloom [skull] by tdhooper
// https://www.shadertoy.com/view/WdScDG


// Big un-optimised distance function, mekes heavy use
// of HG_SDF, smooth min, and IQ's accurate ellipse distance

#define saturate(x) clamp(x, 0., 1.)

float smin(float a, float b, float k){
    float f = clamp(0.5 + 0.5 * ((a - b) / k), 0., 1.);
    return (1. - f) * a + f  * b - f * (1. - f) * k;
}

float smax(float a, float b, float k) {
    return -smin(-a, -b, k);
}

float smin2(float a, float b, float r) {
    vec2 u = max(vec2(r - a,r - b), vec2(0));
    return max(r, min (a, b)) - length(u);
}

float smax2(float a, float b, float r) {
    vec2 u = max(vec2(r + a,r + b), vec2(0));
    return min(-r, max (a, b)) + length(u);
}

float smin3(float a, float b, float k){
    return min(
        smin(a, b, k),
        smin2(a, b, k)
    );
}

float smax3(float a, float b, float k){
    return max(
        smax(a, b, k),
        smax2(a, b, k)
    );
}

void pR(inout vec2 p, float a) {
    p = cos(a)*p + sin(a)*vec2(p.y, -p.x);
}

// Shortcut for 45-degrees rotation
void pR45(inout vec2 p) {
    p = (p + vec2(p.y, -p.x))*sqrt(0.5);
}

vec3 pRx(vec3 p, float a) {
    pR(p.yz, a); return p;
}

vec3 pRy(vec3 p, float a) {
    pR(p.xz, a); return p;
}

vec3 pRz(vec3 p, float a) {
    pR(p.xy, a); return p;
}


float vmin(vec2 v) {
    return min(v.x, v.y);
}

float vmax(vec3 v) {
    return max(max(v.x, v.y), v.z);
}

float vmax(vec2 v) {
    return max(v.x, v.y);
}

float fBox(vec3 p, vec3 b) {
    vec3 d = abs(p) - b;
    return length(max(d, vec3(0))) + vmax(min(d, vec3(0)));
}

float fCorner(vec3 p, float r) {
    vec3 d = p + r;
    return length(max(d, vec3(0))) + vmax(min(d, vec3(0))) - r;
}

float fCorner(vec2 p, float r) {
    vec2 d = p + r;
    return length(max(d, vec2(0))) + vmax(min(d, vec2(0))) - r;
}


// iq https://www.shadertoy.com/view/MldfWn
float sdEllipse( vec2 p, in vec2 ab )
{
    p = abs( p ); if( p.x > p.y ){ p=p.yx; ab=ab.yx; }

    float l = ab.y*ab.y - ab.x*ab.x;
    
    float m = ab.x*p.x/l; 
    float n = ab.y*p.y/l; 
    float m2 = m*m;
    float n2 = n*n;
    
    float c = (m2 + n2 - 1.0)/3.0; 
    float c3 = c*c*c;

    float q = c3 + m2*n2*2.0;
    float d = c3 + m2*n2;
    float g = m + m*n2;

    float co;

    if( d<0.0 )
    {
        float h = acos(q/c3)/3.0;
        float s = cos(h);
        float t = sin(h)*sqrt(3.0);
        float rx = sqrt( -c*(s + t + 2.0) + m2 );
        float ry = sqrt( -c*(s - t + 2.0) + m2 );
        co = ( ry + sign(l)*rx + abs(g)/(rx*ry) - m)/2.0;
    }
    else
    {
        float h = 2.0*m*n*sqrt( d );
        float s = sign(q+h)*pow( abs(q+h), 1.0/3.0 );
        float u = sign(q-h)*pow( abs(q-h), 1.0/3.0 );
        float rx = -s - u - c*4.0 + 2.0*m2;
        float ry = (s - u)*sqrt(3.0);
        float rm = sqrt( rx*rx + ry*ry );
        co = (ry/sqrt(rm-rx) + 2.0*g/rm - m)/2.0;
    }

    float si = sqrt( 1.0 - co*co );
 
    vec2 r = ab * vec2(co,si);
    
    return length(r-p) * sign(p.y-r.y);
}

// symmetric ellipsoid - EXACT distance
float sdEllipsoidXXZ( in vec3 p, in vec2 r ) 
{
    return sdEllipse( vec2( length(p.xy), p.z ), r );
}

float sdEllipsoidXXZPill(vec3 p, vec2 r) {
    p.z = min(p.z, 0.);
    return sdEllipsoidXXZ(p, r);
}

float fCone(vec3 p, float angle) {
    vec2 c = vec2(length(p.xz), p.y);
    pR(c, angle);
    return length(max(c, vec2(0))) + vmax(min(c, vec2(0)));
}

float fPillHalf(vec3 p) {
    p.y = min(p.y, 0.);
    return length(p);
}

// Distance to line segment between <a> and <b>, used for fCapsule() version 2below
float fLineSegment(vec3 p, vec3 a, vec3 b) {
    vec3 ab = b - a;
    float t = saturate(dot(p - a, ab) / dot(ab, ab));
    return length((ab*t + a) - p);
}

// Capsule version 2: between two end points <a> and <b> with radius r 
float fCapsule(vec3 p, vec3 a, vec3 b, float r) {
    return fLineSegment(p, a, b) - r;
}

// curve the x axis around the y axis
void pCurve(inout vec3 p, float r) {
    p.z -= r;
    r = abs(r);
    p = vec3(atan(p.x, -p.z) * r, p.y, length(p.xz) - r);
}

float fMaxillaCore(vec3 p) {
    float d = 1e12;
    vec3 pp = p;

    // Core
    p = pRx(p - vec3(0,.33,-.32), .3);
    d = length(p.xz) - .18;
    d = smax(d, -(length((p - vec3(0,0,.1)).xz) - .1), .1);
    d = smax(d, p.y - .02, .1);
    d = smax(d, -p.y - .1, .1);
    p = pp;

    // Gum
    p = pRx(p - vec3(0,.42,-.29), .4);
    d = smin(d, sdEllipsoidXXZ(p, vec2(.2, .27)), .07);
    p = pp;

    // Gum back inner
    p = pRx(p - vec3(0,.42,-.29), .1);
    float gumback = pRy(p, .55).z - .01;
    gumback = smin(gumback, pRy(p, -.55).z - .08, .04);
    d = smax(d, gumback, .08);
    p = pp;

    // Gum back outer
    p = p - vec3(.17,.3,-.24);
    float part = dot(p, normalize(vec3(1,-.2,1)));
    d = smax(d, part, .03);
    p = pp;

    return d;
}

float fMaxillaBottom(vec3 p) {
    float b = p.z + .15;
    p = pRx(p - vec3(0,.42,-.29), .42);
    pCurve(p.zxy, -.8);
    float d = p.y;
    return min(d, -b);
}

float fSocketBump(vec3 p) {
    vec3 pp = p;
    p = pRz(pp - vec3(.13,.04,-.35), .2);
    float d = sdEllipsoidXXZ(p.xzy, vec2(.19,.13));
    p = pp - vec3(.14,.15,-.35);
    d = smin(d, sdEllipsoidXXZ(p, vec2(.19,.16)), .07);
    p = pp - vec3(.24,.03,-.38);
    d = smin(d, length(p) + .005, .15);
    return d;
}

float fSocketInset(vec3 p) {
    vec3 pp = p;
    p = pRz(pp - vec3(.16,.08,-.4), .3);
    p.z = max(p.z, 0.);
    float d = sdEllipsoidXXZ(p.xzy, vec2(.08,.05));
    p = pRz(pp - vec3(.18,.15,-.4), .2);
    d = smin(d, sdEllipsoidXXZ(p.xzy, vec2(.042,.02)), .16);
    p = pp - vec3(.235,.1,-.43);
    d = smin(d, length(p) - .023, .08);
    p = pp - vec3(.26,.11,-.36);
    d = smax(d, dot(p, normalize(vec3(1,.2,1))) + .01, .04);
    return d;
}

float fSocket(vec3 p) {
    vec3 pp = p;
    p = pRz(pp - vec3(.15,.06,-.38), .7);
    float d = sdEllipsoidXXZ(p.xzy, vec2(.11,.08));
    p = pRz(pp - vec3(.15,.16,-.38), -.15);
    d = smin(d, sdEllipsoidXXZ(p.xzy, vec2(.08,.03)), .1);
    p = pp - vec3(.26,.11,-.36);
    d = smax(d, dot(p, normalize(vec3(1.5,.2,1))) + .01, .04);
    return d;
}

float fNoseShape(vec3 p) {
    p = pRz(p, -.4);
    return sdEllipse(p.xy - vec2(-.055, 0), vec2(.1,.18));
}

float fNose(vec3 p) {
    p = pRx(p - vec3(.0,.25,-.5), .4);
    float d = smax(fNoseShape(p), fNoseShape(p * vec3(-1,1,1)), .02);
    d = smax(d, p.y-.09, 0.04);
    d = smax(d, -sdEllipse(p.xy - vec2(0,.18), vec2(.02,.1)), 0.03);
    d = max(d, -p.z-.15);
    d = smax(d, p.z-.05, .05);
    return d;
}

float fNoseCut(vec3 p) {
    float r = .3;
    p = pRy(pRx(p - vec3(0,.49,-.57), -.45), .35);
    return length(p.yz + vec2(0,r)) - r;
}

float fArchhole(vec3 p) {
    p = pRz(pRy(p - vec3(.3,.15,-.25), -.4), .3);
    vec3 pp = p;
    p -= vec3(.045,0,0);
    float d = dot(p, normalize(vec3(1,0,-.12))) + .01;
    p = pp - vec3(0,0,-.085);
    d = smax(d, -dot(p, normalize(vec3(0,-.14,1))), .05);
    p = pRy(pRz(pRx(pp - vec3(.035,.1,-.08), -.29), -.2), .6);
    float h = .1;
    p.z += .013;
    p.z -= h;
    d = smin(d, sdEllipse(p.xz, vec2(.03, h)), .04);
    p = pp - vec3(.015,-.29,0);
    d = smax(d, -dot(p, normalize(vec3(-.1,1,.35))), .1); // top
    p = pp - vec3(-.05,0,-.05);
    d = smax(d, dot(p, normalize(vec3(-1,-.05,-.4))) - .005, .05);
    p = pp - vec3(-.038,-.1,.05);
    d = smax(d, dot(p, normalize(vec3(-.8,-.21,.08))) - .005, .03);
    p = pRz(pRy(pp - vec3(0,-.084,.25), .4), -.27);
    d = smax(d, -(length(p.zy) - .16), .15);
    p = pp - vec3(0,.2,.04);
    d = smax(d, dot(p, normalize(vec3(-.2,.8,1))), .05);
    p = pp;
    d = smax(d, p.y-.25, .1);
    return d;
}

float sdSkull(vec3 p) {

    p.x = abs(p.x);
    vec3 pp = p;
    float d = 1e12;
    float back = sdEllipsoidXXZ(p - vec3(0,-.11,.16), vec2(.4, .32));
    d = min(d, back);
    float base = length(p - vec3(0,-.08,.25)) - .15;
    d = smin(d, base, .3);
    float baseside = length(p - vec3(.2,.1,.25)) - .05;
    d = smin(d, baseside, .25);
    float forehead = sdEllipsoidXXZ(pRx(p - vec3(0,-.15,-.14), .5), vec2(.35, .44) * .97);
    d = smin(d, forehead, .22);
    float foreheadside = length(p - vec3(.17,-.13,-.3)) - .05;
    d = smin(d, foreheadside, .25);
    float socketbump = smin(fSocketBump(p), fSocketBump(p * vec3(-1,1,1)), .15);
    d = smin(d, socketbump, .09);

    p = pRx(p - vec3(0,.23,-.45), -.55);
    float bridge = sdEllipse(p.xz, vec2(.06, .15));
    bridge = max(bridge, -p.y-.3);
    d = smin(d, bridge, .1);
    p = pp;

    p = pRy(pRx(p - vec3(.22,.3,-.4), .4), -.1);
    float cheek = smax(sdEllipsoidXXZ(p.zyx, vec2(.02, .05)), -p.z, 0.05);
    d = smin(d, cheek, 0.1);
    p = pp;
    float maxilla = fMaxillaCore(p);
    d = smin(d, maxilla, .08);
    float foramen = fCone(pRx(pRy(p - vec3(.17,.27,-.465), .5), -.5) * vec3(1,-1,1), .6);
    foramen = smax(foramen, p.y-.45, .1);
    d = smax(d, -foramen - .01, .05);

    float socketinset = smin(fSocketInset(p), fSocketInset(p * vec3(-1,1,1)), .2);
    d = smax(d, -socketinset, .12);
    float socket = fSocket(p);
    d = smax(d, -socket, .04);
    float backbump = sdEllipsoidXXZ(pRx(pRy(p - vec3(.27,-.29,.0), -.25), .0), vec2(.1, .5) * .25);
    d = smin(d, backbump, .34);
    float topbump = sdEllipsoidXXZ(p - vec3(0,-.33,-.05), vec2(.1, .15) * .5);
    d = smin(d, topbump, .3);

    float side = sdEllipsoidXXZ(pRz(p - vec3(.2,.05,-.0), .3).yzx, vec2(.1, .05));
    d = smin(d, side, .25);

    // bridge adjust
    p = pRx(p - vec3(0,.2,-.5), -.2);
    d = smin(d, max(length(p.xz) - .03, -p.y-.3), .05);
    p = pp;

    // canine socket
    p = pRy(pRz(p - vec3(.14,.55,-.495), -.4), .5);
    p.x = max(p.x, 0.);
    float caninesocket = length(p.xz) - .01;
    caninesocket = smax(caninesocket, -p.y-.2, .01);
    d = smin(d, caninesocket, .03);
    p = pp;

    // Nose
    float nos = fNose(p);
    d = smin(d, nos-.01, .02);
    p = pp;

    float nosecut = smin(fNoseCut(p), fNoseCut(p * vec3(-1,1,1)), .04);
    d = smax(d, -nosecut, .01);
    p = pp;

    // Nose hole
    float nosb = fPillHalf((p - vec3(.0,.362,-.54)).xzy) - .005;
    nosb = max(nosb, p.z+.4);
    d = smin(d, nosb, .05);
    d = smax(d, -nos+.005, .02);

    p = pp;
    d = smax(d, fMaxillaBottom(p), .02);
    float roof = sdEllipsoidXXZ(p - vec3(0,.47,-.28), vec2(.13, .22));
    d = smax(d, -roof, .03);

    float temporal = sdEllipsoidXXZ(pRy(pRz(p - vec3(.25,.1,-.03), .2), -.4).yzx, vec2(.18, .08));
    temporal = smax(temporal, dot(p.zy, normalize(vec2(-.3,1))) - .2, .1);
    d = smin(d, temporal, .15);

    float archhole = fArchhole(p);
    d = smax(d, -archhole, .03);

    return d;
}


float map(vec3 p) {
    p -= OFFSET;
    p /= SCALE;
   	return sdSkull(p);
	return length(p) - .45;
}

void mainCubemap( out vec4 fragColor, in vec2 fragCoord, in vec3 rayOri, in vec3 rayDir )
{
    
    int id = faceIdFromDir(rayDir);
    
    vec2 coord = fragCoord.xy;
    vec2 size = iResolution.xy;
    vec2 uv = coord / size;
    
    vec4 lastFrame = texture(iChannel0, rayDir);
    if (lastFrame.x != 0. && iFrame > 2) {
        fragColor = lastFrame;
    	return;
    }
    
    mat4 space = texToSpace(coord, id, size);
    vec4 result = vec4(0);
    
    for (int i = 0; i < 4; i++) {
    	result.x = map(space[i].xyz);
        result = result.yzwx;
    }
    
    fragColor = result;
}

// Buf A (buffer) — pinball game by public_int_i
// https://www.shadertoy.com/view/MdyGDz

//Ethan Shulman/public_int_i 2015
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

//thanks to iq for the great tutorials, code and information


//Buf A - Game logic


//distance functions from iq's site
float udBox( vec2 p, vec2 b )
{
  return length(max(abs(p)-b,0.0));
}
float sdBox( vec2 p, vec2 b )
{
  vec2 d = abs(p) - b;
  return min(max(d.x,d.y),0.0) +
         length(max(d,0.0));
}
float sdSphere( vec2 p, float r) {
    return length(p)-r;
}
float sdCapsule( vec2 p, vec2 a, vec2 b, float r )
{
    vec2 pa = p - a, ba = b - a;
    float h = clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );
    return length( pa - ba*h ) - r;
}


vec4 flap;
    
vec2 rot(in vec2 v, in float ang) {
    float si = sin(ang);
    float co = cos(ang);
    return v*mat2(si,co,-co,si);
}

float pins(in vec2 rp) {
    vec2 p = rp;
    vec2 p2 = rp;
    
    p.x = abs(p.x+.12)-.25;
    
    p2.x -= .7;   
    
    return min(
        sdSphere(p,.03),
        sdSphere(p2,.03) );
}


float flaps(in vec2 rp) {
    vec2 b1 = rp;
    b1.x += .79;
    
    vec2 b2 = b1;
    
    b1.y -= .24;
    b2.y += .24;
    
    b1.xy = rot(b1.xy,2.-flap.x);
    b2.xy = rot(b2.xy,flap.y+1.);
    
    b1.y += .08;
    b2.y -= .08;
    
    return min( udBox(b1, vec2(.013,.12)),
                udBox(b2, vec2(.013,.12)) );
}


float map(in vec2 rp) {
    
    vec2 asr = rp;
    asr.y = abs(asr.y);
    asr.x -= -1.;
    asr.xy = rot(asr.xy, 2.3);
    
    return min( min( min( udBox(abs(asr-vec2(.7,.75))-vec2(.15,.2),vec2(.07,.02)),
                        length(asr-vec2(1.1,1.35))-.1),
                    sdCapsule(asr,vec2(0.,.7),vec2(0.,.4),.05)),
       				-sdBox(rp-vec2(0.,0.),vec2(1.,.5)));
}

float df(vec2 p) {
    return min(map(p),min(flaps(p),pins(p)));
}

vec2 normal(vec2 p) {
    const vec2 NE = vec2(.0001,0.);
	return normalize(vec2(df(p+NE)-df(p-NE),
                            df(p+NE.yx)-df(p-NE.yx)) );
}
vec2 flapsNormal(vec2 p) {
    const vec2 NE = vec2(.0001,0.);
	return normalize(vec2(abs(flaps(p+NE))-abs(flaps(p-NE)),
                          abs(flaps(p+NE.yx))-abs(flaps(p-NE.yx))) );
}

vec4 encodeBall(vec4 b) {
    return b+1.;
}
vec4 decodeBall(vec4 b) {
    return b-1.;
}

const float epsilon = .0001;
const float ballRadius = .035;


void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    int ind = int(floor(fragCoord.x));
    if (ind > 3) { discard;return; }
    
    if (iFrame < 10) {
        //init
        if (ind == 0) {
            fragColor = encodeBall( vec4(-0.5,0.3,0.,0.) );
        }
        if (ind == 1) {
            fragColor = vec4(0.);
        }
        if (ind == 2) {
            fragColor = vec4(0.);
        }
        return;
    }
    
    
    if (ind == 2) {
        //flaps
        vec4 flaps = texture(iChannel0, vec2(2.5,.5)/iResolution.xy);
        
        flaps.z = max(clamp(texture(iChannel1, vec2(90.5, 0.5)/255.).x, 0., 1.),
                      clamp(texture(iChannel1, vec2(37.5, 0.5)/255.).x, 0., 1.));
        flaps.w = max(clamp(texture(iChannel1, vec2(88.5, 0.5)/255.).x, 0., 1.),
                      clamp(texture(iChannel1, vec2(39.5, 0.5)/255.).x, 0., 1.));
        flaps.xy = clamp(flaps.xy+(flaps.zw-.5)*2./5., 0., 1.);
        
        fragColor = flaps;
        return;
    }
    
    vec4 scoring = texture(iChannel0, vec2(1.5, 0.5)/iResolution.xy);
    flap = texture(iChannel0, vec2(2.5, 0.5)/iResolution.xy);
    
    //ball
    vec4 b = decodeBall( texture(iChannel0, vec2(.5)/iResolution.xy) );
	
    b.z -= .02/60.;
    b.zw = clamp(b.zw,-1.,1.);
    
    vec2 dir = normalize(b.zw);
    float len = length(b.zw);
    vec2 reflDir;
    bool hit = false;
    
    float s = 0.;
    for (int i = 0; i < 8; i++) {
        vec2 p = b.xy+dir*s;
        float dst = df(p);
        if (dst < ballRadius) {
            hit = true;
            break;
        }

        s += dst;
        if (s > len) break;
    }
    
    s = min(s,len);
    b.xy += dir*s;
    
    if (ind == 1) {
        if (hit) {
            if (pins(b.xy) < ballRadius+epsilon*10.) {
                scoring.x += floor((b.x+1.)*3.)/4096.;
            }
        }
        if (scoring.y < .2) {
            if (iTime-scoring.z > 2. && max(flap.z,flap.w) > 0.) {
                scoring.x = 0.;
                scoring.y = .2;
            }
        }
        if (b.x < -.9) {
        	scoring.y = .1;
            scoring.z = iTime;
        }
        fragColor = scoring;
        return;
    }
    
    if (hit) {
        vec2 hn = normal(b.xy);
        if (flaps(b.xy) < ballRadius+epsilon*10. && ((b.y > 0. && flap.z > 0.) || (b.y < 0. && flap.w > 0.))) {
            hn = flapsNormal(b.xy-vec2(-.2,0.));
            b.zw += hn*.01;
            b.xy += hn*(ballRadius-df(b.xy)+epsilon*10.);
        } else {
            b.zw = reflect(normalize(b.zw),hn)*length(b.zw)*.75;
            b.xy += hn*(ballRadius-df(b.xy)+epsilon);
        }
    }

    if (scoring.y < .2) {
        b = vec4(-0.5,0.3,0.,0.);
    }
    b = clamp(b,-1.,1.);
    fragColor = encodeBall(b);
}
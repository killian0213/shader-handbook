// Image (image) — Hyperbolic Square by mla
// https://www.shadertoy.com/view/Mlsfzs

////////////////////////////////////////////////////////////////////////////////
//
// (c) Matthew Arcus 2017
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
//
// Hyperbolic kaleidoscope mapped conformally in various ways,
// notably to a square with the Jacobi cn function.
//
// Keys 1-8 select various mappings, otherwise cycle through automatically.
//
// Mouse controls position of image centre (click on image 
// after resize to recentre).
//
// 'd': combine fundamental regions in pairs (P should be even).
// 'c': chiral mapping
// 'f': display principal region only
// 'k': Beltrami-Klein for disc projection
// 'm': display outside disc/halfplane
// 'n': don't normalize rotations - see effect on 'cloverleaf' mapping #2
// 'g': centre on 4-vertex
// 'b': show fundamental region edges
//
////////////////////////////////////////////////////////////////////////////////

int P = 8;   // Central vertex
int Q = 3;   // Second vertex
//int R = 2; // Third vertex, always 2

const int NN = 200; // Number of folding iterations

const float PI = 3.141592654;
const float TWOPI = 2.0*PI;

bool keypress(int code) {
    return texelFetch(iChannel1, ivec2(code,2),0).x != 0.0;
}

int numbertoggle() {
    int i = int(texelFetch(iChannel2,ivec2(0,0),0).x);
    if (i < 0) return 0;
    return i;
}

/// Complex arithmetic ///

// Normal vec2 operations work for
// addition, subtraction and
// multiplication by a scalar.
      
// Multiplication
vec2 cmul(vec2 z0, vec2 z1) {
  float x0 = z0.x; float y0 = z0.y; 
  float x1 = z1.x; float y1 = z1.y;
  return vec2(x0*x1-y0*y1,x0*y1+x1*y0);
}

// Reciprocal
vec2 cinv(vec2 z) {
  float x = z.x; float y = z.y;
  float n = 1.0/(x*x + y*y);
  return vec2(n*x,-n*y);
}

// Division
vec2 cdiv(vec2 z0, vec2 z1) {
  return cmul(z0,cinv(z1));
}

// Exponentiation - e^ix
vec2 expi(float x) {
  x = mod(x,TWOPI);
  vec2 t = vec2(cos(x),sin(x));
  if (!keypress(CHAR_N)) t = normalize(t);
  return(t);
}

// e^iz
vec2 cexp(vec2 z) {
  return exp(z.x) * expi(z.y);
}

vec2 csqrt(vec2 z) {
  float r = length(z);
  return vec2(sqrt(0.5*(r+z.x)),sign(z.y)*sqrt(0.5*(r-z.x)));
}

vec2 clog(vec2 z) {
  return vec2(log(length(z)),atan(z.y,z.x));
}

vec2 csin(vec2 z) {
  float x = z.x, y = z.y;
  return cdiv(cexp(vec2(-y,x))-cexp(vec2(y,-x)), vec2(0,2.0));
}

vec2 cpow(vec2 z, float k) {
  return cexp(k*clog(z));
}

// Taken from NR, simplified by using a fixed number of
// iterations and removing negative modulus case.
// Modulus is passed in as k^2 (_not_ 1-k^2 as in NR).
void sncndn(float u, float k2,
            out float sn, out float cn, out float dn) {
  float emc = 1.0-k2;
  float a,b,c;
  const int N = 4;
  float em[N],en[N];
  a = 1.0;
  dn = 1.0;
  for (int i = 0; i < N; i++) {
    em[i] = a;
    emc = sqrt(emc);
    en[i] = emc;
    c = 0.5*(a+emc);
    emc = a*emc;
    a = c;
  }
  // Nothing up to here depends on u, so
  // could be precalculated.
  u = c*u; sn = sin(u); cn = cos(u);
  if (sn != 0.0) {
    a = cn/sn; c = a*c;
    for(int i = N-1; i >= 0; i--) {
      b = em[i];
      a = c*a;
      c = dn*c;
      dn = (en[i]+a)/(b+a);
      a = c/b;
    }
    a = 1.0/sqrt(c*c + 1.0);
    if (sn < 0.0) sn = -a;
    else sn = a;
    cn = c*sn;
  }
}

// Complex sn. uv are coordinates in a rectangle, map to
// the upper half plane with a Jacobi elliptic function.
// Note: uses k^2 as parameter.
vec2 sn(vec2 z, float k2) {
  float snu,cnu,dnu,snv,cnv,dnv;
  sncndn(z.x,k2,snu,cnu,dnu);
  sncndn(z.y,1.0-k2,snv,cnv,dnv);
  float a = 1.0/(1.0-dnu*dnu*snv*snv);
  return a*vec2(snu*dnv, cnu*dnu*snv*cnv);
}

vec2 cn(vec2 z, float k2) {
  float snu,cnu,dnu,snv,cnv,dnv;
  sncndn(z.x,k2,snu,cnu,dnu);
  sncndn(z.y,1.0-k2,snv,cnv,dnv);
  float a = 1.0/(1.0-dnu*dnu*snv*snv);
  return a*vec2(cnu*cnv,-snu*dnu*snv*dnv);
}

vec2 dn(vec2 z, float k2) {
  float snu,cnu,dnu,snv,cnv,dnv;
  sncndn(z.x,k2,snu,cnu,dnu);
  sncndn(z.y,1.0-k2,snv,cnv,dnv);
  float a = 1.0/(1.0-dnu*dnu*snv*snv);
  return a*vec2(dnu*cnv*dnv,-k2*snu*cnu*snv);
}

#if __VERSION__ < 300
bool isnan(float x) {
  return x != x;
}
bool isnan(vec2 z) {
  return isnan(z.x) || isnan(z.y);
}

#if 0
float atanh(float r) {
  return 0.5*log((1.0+r)/(1.0-r));
}

float tanh(float x) {
  return (exp(2.0*x)-1.0)/(exp(2.0*x)+1.0);
}
#endif
#endif

// Invert z in circle radius r, centre w
vec2 invert(vec2 z, vec2 w, float r2) {
  vec2 z1 = z - w;
  float k = r2/dot(z1,z1);
  return z1*k+w;
}

// Overloading for p on x-axis
vec2 invert(vec2 z, float x, float r2) {
  return invert(z,vec2(x,0),r2);
}

// Invert z in circle p, r2, if it is inside
int tryinvert(inout vec2 z, vec2 p, float r2) {
  vec2 z1 = z - p;
  float d2 = dot(z1,z1);
  if (d2 >= r2) return 0;
  z = z1*r2/d2 + p;
  return 1;
}

int tryreflect(inout vec2 z, vec2 norm) {
  float k = dot(z,norm);
  if (k <= 0.0) {
    return 0;
  } else {
    z -= 2.0*k*norm;
    return 1;
  }
}

vec2 translate(vec2 z, float s) {
  // Do hyperbolic translation, ie. an inversion
  // Translate s (on x axis) to origin of hyperbolic disk with
  // given radius.
  if (abs(s) < 1e-4) {
    z.x = -z.x;
  } else {
    // p*(p-s) = r*r = p*p - radius*radius
    // p*p - p*s = p*p - rad*rad
    // p = s/(rad*rad)
    float p = 1.0/s;
    float r2 = p*(p-s);
    z = invert(z,p,r2);
  }
  return z;
}

// Compute the radius of the disk.
// p is the centre of the inversion
// circle for the hyperbolic triangle, r is its radius,
// so use Pythagoras to find the right angle for a tangent
// with the disk (this needs a picture).
float diskradius(vec2 p, float r) {
  return sqrt((length(p)+r)*(length(p)-r));
}

// For ES 2.0
int imod(int n, int m) {
    return n-n/m*m;
}

// Rotate vector p by angle t.
vec2 rotate(vec2 p, float t) {
  return cmul(expi(t),p); //cos(t)*p + sin(t)*vec2(-p.y,p.x);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
  //Q += int(iTime);
  float rrepeat = 0.0;
  rrepeat = 0.005* iTime; // Makes texture mapping radius dependent
  int display = numbertoggle();
  int NDISPLAYS = 8;
  if (display == 0) display = 1+imod(int(iTime/10.0),NDISPLAYS);
  // Join 2 fundamental regions together
  bool doubleup = keypress(CHAR_D);
  bool chiral = keypress(CHAR_C);
  // Just show one fundamental region
  bool fundamental = keypress(CHAR_F);
  bool mask = !keypress(CHAR_M);
  
#if 0
  if (keypress(CHAR_0+1)) display = 1;
  else if (keypress(CHAR_0+2)) display = 2;
  else if (keypress(CHAR_0+3)) display = 3;
  else if (keypress(CHAR_0+4)) display = 4;
  else if (keypress(CHAR_0+5)) display = 5;
#endif
      
  fragColor = vec4(0,0,0,1); // Background
    
  float theta = PI/float(P); // Central angle of triangle
  float phi = PI/float(Q); // Other angle of triangle
  // Need picture of hyperbolic region
  // Third side of hyperbolic triangle is an inversion circle.
  // ODBC are on x-axis, A is height 1 above B, so OBA is a right angle and BA = 1
  // BOA = COA = theta, OAD = phi, CAB = theta+phi
  // Maybe should scale to make radius 1 always.
  vec2 p = vec2(cos(theta)/sin(theta) + sin(theta+phi)/cos(theta+phi),0.0);
  float r = 1.0/cos(theta+phi);
  float offset = p.x - r;
  float radius = diskradius(p,r); // FIXME!
  p /= radius;
  r /= radius;
  offset /= radius;
  float r2 = r*r;
  
  // norm and norm2 are normals to the radial axes
  // norm2 is second radial axis, either x-axis or norm reflected in x-axis
  vec2 norm = vec2(-sin(theta),cos(theta));
  vec2 norm2 = !doubleup ? vec2(0.0,-1.0) : vec2(-sin(theta),-cos(theta));
  vec2 ci = vec2(0.0,1.0); // Complex i

  vec2 z = (2.0*fragCoord - iResolution.xy)/iResolution.y;
  if (display == 1) {
    z = cdiv(z,vec2(1,1));
    z -= vec2(1,0);
    z *= 1.854; 
    z = cn(z, 0.5);
    z = cmul(z,vec2(0.70711,0.70711));
  } else if (display == 2) {
    //if (keypress(CHAR_K)) z *= (1.0-sqrt(1.0-dot(z,z)))/dot(z,z); // Beltrami-Klein
    z = cpow(cmul(z,normalize(vec2(1))),4.0)-vec2(1,0);
  } else if (display == 3) {
    z = csqrt(z);
    z = cmul(z,ci);
    z = cdiv(ci-z,ci+z);
  } else if (display == 4) {
    // rectangle -> half plane
    z *= 4.0;
    float k2 = 0.5*sin(0.2*iTime)+0.5;
    z.y += 1.0;
    z = sn(z,k2);
  } else if (display == 5) {
    z.y += 1.0;
    z *= 0.5*iResolution.y/iResolution.x;
    z = csin(PI*z); // edges and bottom are boundaries
  } else if (display == 6) {
    z.y += 1.0;
    z *= 0.5;
    z.x *= -1.0;
    z = cexp(PI*z); // top and bottom are boundaries
    z.x *= -1.0;
  } else if (display == 7) {
    z *= 0.5*iResolution.y/iResolution.x;
    z.x += 0.5;
    //z.x *= -1.0;
    z = cexp(PI*z.yx); // swap x,y; sides are boundaries
    z.x *= -1.0;
  } else if (display == 8) {
    z = cmul(z,vec2(0,-1));
    z = csqrt(z);
    z.x -= 0.5;
    z = cmul(z,vec2(0,1));
  }
  if (display > 3) {
    // Map upper half-plane to the disk.
    z = cdiv(ci-z,ci+z);
  }

  z = z.yx; // Flip coords to make image symmetric about y-axis
    
  if(iMouse.x > 0.0) {
    vec2 mouse = (2.0*iMouse.xy-iResolution.xy)/iResolution.y;
    mouse = mouse.yx;
    if (display == 3 || display == 4 || 
        display == 5 || display == 7) {
      mouse.x *= -1.0;
      mouse = mouse.yx;
    }
    // FIXME!
    float r = atan(mouse.y,mouse.x);
    float s = length(mouse);

    z = rotate(z,-r);
    z = translate(z,s);
    z.x *= -1.0;
  }
  
  float psi = iTime*0.1;
  float rho = iTime*0.123;
  z = rotate(z,-rho);
  if (keypress(CHAR_G)) {
    z = translate(z,offset); // Put 4-vertex in centre
  }
  if (dot(z,z) > 1.0) {
    // Or invert to inside the disk
    if (mask) return;
  } else {
    // Only apply rrotation inside the disk
    psi += rrepeat*atanh(length(z));
  }
  
    int flips = 0;
    bool found = false;
    for (int i = 0; i < NN; i++) {
      // Fundamental region is OAB
      // OA is on x-axis, OB is at angle theta
      // AB is circle for hyperbolic case.
      // norm is normal to OB, norm2 is other radial
      // reflection - either x-axis or reflection of OA.
      int k = tryreflect(z,norm) + tryreflect(z,norm2) + tryinvert(z,p,r2);
      if (k == 0) {
        found = true;
        break;
      }
      if (fundamental) return;
      flips += k;
    }
    if (!found) return;
    vec2 z0 = z;
    if (chiral && imod(flips,2) != 0) z.y = -z.y;
  
  float level = 1.0;

  if (keypress(CHAR_B) &&
      // Show region boundary
      (abs(dot(z,norm)) < 0.007 || 
       abs(dot(z,norm2)) < 0.007 ||
       length(p-z)-r < 0.007)) {
    level = 0.0;
  }
  
  // Now convert position (in fundamental region) to texture coord.
  vec2 uv = z;
  //uv = mat2(cos(psi), sin(psi), -sin(psi), cos(psi)) * uv;
  uv = rotate(uv,psi);
  // scale texture access
  uv *= 2.0; z0 *= 2.0;
  // and add a variable offset here?
  //if (iMouse.x > 0.0) uv += 2.0*(iMouse.xy-0.5*iResolution.xy)/iResolution.y;
  uv += vec2(0.5,0.5);

  vec3 texColor;
  if (keypress(CHAR_T)) {
    texColor = texture(iChannel0,uv).xyz;
  } else {
    texColor = textureGrad(iChannel0, uv, dFdx(z0), dFdy(z0)).xyz;
  }
  texColor *= 2.0;
  fragColor = vec4(level*texColor,1.0);
}
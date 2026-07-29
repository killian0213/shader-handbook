// Image (image) — mushroom by zxxuan1001
// https://www.shadertoy.com/view/3lGGWK

#define MAX_DISTANCE 80.0
#define MAX_STEP 120
#define EPSILON 0.0001
#define PI 3.1415
#define RIM_COLOR vec3(0.1,0.05,0.2)
#define LIGHT_COLOR vec3(0.15,0.1,0.3)
#define LIGHT_DIR vec3(cos(iTime),1.0,sin(iTime))
#define SPHERE_COLOR vec3(0.2, 0.6, 1.0)
#define GLOW vec3(0.1, 0.8, 1.0)

//https://iquilezles.org/articles/smin
vec3 sdMin (vec3 d1, vec3 d2)
{
    return d1.x < d2.x ? d1 : d2;
}

vec3 sdMax (vec3 d1, vec3 d2)
{
    return d1.x > d2.x ? d1 : d2;
}

float sdSmoothMin( float d1, float d2, float k ) {
    float h = clamp( 0.5 + 0.5*(d2-d1)/k, 0.0, 1.0 );
    return mix( d2, d1, h ) - k*h*(1.0-h); 
}


float smin(in float a, in float b, in float k)
{
    float h = max( k - abs(a-b), 0.0);
    return min(a,b) - h*h*0.25/k;
}

float smax(in float a, in float b, in float k)
{
    float h = max( k - abs(a-b), 0.0);
    return max(a,b) + h*h*0.25/k;
}

float sphereSDF(vec3 p, float r) 
{
    return length(p) - r;
}

float sdVerticalCapsule( vec3 p, float h, float r )
{
  p.y -= clamp( p.y, 0.0, h );
  return length( p ) - r;
}

float disp (vec3 p) 
{
    float n = texture(iChannel2, p.xy+p.yz+p.xz).r;
    return  (sin(p.z * 25.2 + 10.0*n) + sin(p.x * 28.9 + 10.0*n));
}

float disp1 (vec3 p)
{
    //return (sin(p.x) + sin(p.z)) * sin(p.y);
    return texture(iChannel1, p.xz*0.1).r;
}

float leg(vec3 p, float h, float r) 
{
    vec3 q = p-vec3(0.0,-1.0,0.0) ;
    q.xz += 0.5*sin(q.y*0.3);
    float scale = mix(1.0, 2.2, smoothstep(h-10.0,h, q.y));
    r *= scale;
    float d = sdVerticalCapsule(q, h, r);
    d += 0.008*disp(q*0.5);
    return d;
}

float shell(vec3 p, float r) 
{
    float t = iTime*0.1;
    float scale = mix(0.6+0.2*sin(t), 2.2+0.8*sin(t), smoothstep(-1.2,2.5, -0.6*p.y));
    r *= scale;
    float s1 = sphereSDF(p , r);
    s1 = abs(s1)-0.1;
    
    s1 += 0.18*disp1(p*2.3)*(0.5+0.5*sin(t)); // holes
    s1 *= 0.5;
    
    float plane = dot(p, normalize(vec3(0.0,-1.0,0.0)))-3.65;
    
    //plane -= 0.08*disp1(p*8.0);;
    float d = s1 > plane ? s1 : plane;
    
    return d;
}

mat3 getCamera( in vec3 ro, in vec3 ta) 
{
	vec3 cw = normalize(ta-ro);
	vec3 cp = vec3(0.0, 1.0, 0.0);
	vec3 cu = normalize( cross(cw,cp) );
	vec3 cv =          ( cross(cu,cw) );
    return mat3( cu, cv, cw );
}


float noise(in vec2 uv) {
    return texture(iChannel1, uv/64.0).r;
}

float smoothNoise(in vec2 uv) {
    vec2 luv = fract(uv); //range from 0.0 to 1.0
    vec2 id = floor(uv); //the integer part of uv, 0, 1, 2
    luv = luv*luv*(3.0 - 2.0*luv); //similar to smoothstep
    
    //get values from the cordinates of a square
    float bl = noise(id);
    float br = noise(id + vec2(1.0, 0.0));
    float tl = noise(id + vec2(0.0, 1.0));
    float tr = noise(id + vec2(1.0, 1.0));
    
    float b = mix(bl, br, luv.x); //interpolate between bl and br
    float t = mix(tl, tr, luv.x); //interpolate between tl and tr
    
    return mix(b, t, luv.y);
}

float hash21(vec2 p) {
    p = fract(p*vec2(133.7, 337.1));
    p += dot(p, p+vec2(37.1,17.33));
    return fract(p.x*p.y);
}

vec3 offset = vec3(0.0);
vec4 sceneSDF(vec3 p) 
{
    
    vec3 q = p; // org pos
    
    //head
    float d1 = shell(q, 3.5);
    
    //leg
    float h = 15.0;
    float r = 0.9;
    vec3 q1 = q - vec3(0.0, -h, 0.0);
    float d2 = leg(q1, h, r);
    
    //ground
    float d3 = q1.y + 2.0*texture(iChannel1, q1.xz*0.01).r;
    
    float d = sdSmoothMin(d1, d2, 0.5);
    d = sdSmoothMin(d, d3, 2.0);
    vec3 rst = vec3(d, 1.0, 0.0);
    
    //glow
    float v = 0.2;
    vec3 npos = v*(p-vec3(0.0, -h-1.0, 0.0));
    vec2 nid = floor(vec2(npos.x+0.5, npos.z+0.5));
    vec3 fid = vec3(fract(npos.x+0.5)-0.5, npos.y, fract(npos.z+0.5)-0.5);
    float nn = hash21(nid*3.0);
    vec3 fpos = fid + 0.2*vec3(sin(nn*112.33), 0.0, cos(nn*171.3));
    float rr = pow(nn,3.0);
    fpos.y += 0.08*sin(nid.x * nid.y + iTime*5.0);
    float s2 = sphereSDF(fpos, 0.02+0.2*rr)/v;
    rst = sdMin(rst, vec3(s2, 2.0, 0.0));
    return vec4(rst, s2);
}

vec4 marching( in vec3 ro, in vec3 rd )
{
    vec4 rst = vec4(0.0);
    float t = 0.01;
    float minDist = MAX_DISTANCE;
    for ( int i = 0; i < MAX_STEP; ++i )
    {
        vec3 p = ro + t * rd;
        vec4 dist = sceneSDF(p);
        minDist = min(minDist, dist.w/t);
        rst = vec4(t, dist.y, minDist, dist.w);
        if ( abs(dist.x)< EPSILON || t>MAX_DISTANCE) break;
        t += dist.x; 
    }
    
    if ( t>MAX_DISTANCE )
    {
        rst = vec4(MAX_DISTANCE, -1.0, minDist, MAX_DISTANCE);
    }
    
    return rst;
}

vec3 getNormal(vec3 p) 
{
    return normalize(
            vec3(
                sceneSDF(vec3(p.x + EPSILON, p.y, p.z)).x - sceneSDF(vec3(p.x - EPSILON, p.y, p.z)).x,
                sceneSDF(vec3(p.x, p.y + EPSILON, p.z)).x - sceneSDF(vec3(p.x, p.y - EPSILON, p.z)).x,
                sceneSDF(vec3(p.x, p.y, p.z  + EPSILON)).x - sceneSDF(vec3(p.x, p.y, p.z - EPSILON)).x
            )
    	);
}

vec3 testSurf(vec2 p)
{
    float f0 = mod(floor(p.x*2.0) + floor(p.y*2.0), 4.0);
    float f1 = mod(floor(p.x*4.0) + floor(p.y*4.0), 2.0);
    vec3 col = mix(vec3(0.8, 0.5, 0.4), vec3(0.5, 0.3, 0.7), f0);
    col = mix(col, vec3(0.2, 0.4, 0.3), f1);
    
    return col;
}

vec3 shading(vec4 hit, vec3 ro, vec3 rd) 
{
    vec3 p = ro + hit.x * rd;
    vec3 nor = getNormal(p);
    
    vec3 col = vec3(0.0);
    vec3 surfCol = vec3(0.0);
    vec3 coeff = vec3(0.04, 1.0, 1.0); //ambient, diffuse, specular
    vec3 p1 = p - offset;
    float n = texture(iChannel2, p.xz*0.2).r;
    float nf = texture(iChannel2, floor(p1.xz)).r;
    vec2 polar = vec2(atan(p1.z, p1.x), 0.5+0.1*n);
    float detail = texture(iChannel1,  polar).r;
    vec3 w0 = nor * nor;
    vec3 p2 = 0.2*p1;
    vec3 noiseTex = w0.xxx * texture(iChannel2, p2.yz).rgb 
        			+ w0.yyy * texture(iChannel2, p2.xz).rgb
        			+ w0.zzz * texture(iChannel2, p2.xy).rgb;
    float rimPow = 8.0;
    float t = iTime;
    if (hit.y < 1.5)
    {
        float h = 0.5+0.5*sin(p.y*0.5+1.3); 
        surfCol = mix(vec3(0.1,0.58,0.85), vec3(0.0), h);
        surfCol *= detail;
        float tk = 0.5+0.5*(sin(length(p)+t*3.0)*cos(length(p)+t*2.0));
        surfCol += pow(n,64.0)*vec3(0.0, 100.0,100.0)*tk;
        surfCol *= smoothstep(-10.0, 0.0, p1.y);   
        
        vec3 lightDir = normalize(LIGHT_DIR); 
        vec3 viewDir = normalize(-rd);
        vec3 reflectDir = normalize(reflect(-viewDir, nor));
        float spec = pow(max(dot(reflectDir, viewDir), 0.0), 32.0); 
        float diff = max( dot(nor, lightDir), 0.0);

        float rim = 1.0-max(dot(nor, viewDir), 0.0);
        float rimS = pow(rim, rimPow);
        vec3 rimCol = RIM_COLOR*rimS;
        vec3 refCol = texture(iChannel0, reflectDir).rgb;

        surfCol = coeff.x*surfCol + (coeff.y*surfCol*diff + coeff.z*spec)*LIGHT_COLOR;
        surfCol += rimCol;
    } 
    else if (hit.y < 2.5)
    {
        surfCol = vec3(0.01);
    }
    return surfCol;
}

vec3 render(in vec2 fragCoord) 
{
    vec2 uv = fragCoord/iResolution.xy;
    uv -= 0.5; 
    uv.x *= iResolution.x/iResolution.y; 
    vec2 mo = vec2(0.01) + iMouse.xy  / iResolution.xy ;
    mo = -1.0 + 2.0 * mo;
    
    vec3 ro = vec3(25.0 * cos(mo.x * 2.0 * PI), 0.0, 25.0 * sin(mo.x * 2.0 * PI));
    vec3 ta = vec3(0.0, -5.0, 0.0);
    mat3 cam = getCamera(ro, ta);
    vec3 rd = normalize(cam * vec3(uv, 1.0));
    vec4 hit = marching(ro, rd);
    vec3 col = vec3(0.0,0.001,0.003);
    if (hit.x < MAX_DISTANCE) 
    {
       col = shading(hit, ro, rd);
    }
   
    //glow
    vec3 p = ro + rd * hit.x;
    hit.z = clamp(hit.z, 0.0, 3.0);
    float glow0 = exp(-180.0*hit.z);
    float glow1 = min(pow(0.0013/hit.z, 32.0), 1.0);
    vec3 glowCol = vec3(0.0);
    
    float v = 0.2;
    vec3 npos = v*p;
    vec3 nid = floor(npos+0.5);
    float vc = hash21(nid.xz);
    vec3 vCol = vec3(0.0,1.0,4.0)*vec3(0.0,1.0,4.0);
    vCol.r += 3.0*vc;
    vCol.g += 1.0*fract(vc*111.77);
    glowCol += 0.4*vCol*glow0;  
    glowCol += vCol*glow1; 
    float t = sin(iTime+vc*5.0);
    float y = 3.0*t*(1.0-t); 
    glowCol *= 0.5+0.5*y;
    col += glowCol;
    // fog
    col = mix( col, vec3(0.0), 1.0-exp( -0.001*hit.x*hit.x ) );
    return col;
    
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec3 col = render(fragCoord);
    
    col = pow(col, vec3(1.0/2.2));  

    // Output to screen
    fragColor = vec4(col,1.0);
}
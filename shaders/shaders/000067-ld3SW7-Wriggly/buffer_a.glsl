// Buffer A (buffer) — Wriggly by huwb
// https://www.shadertoy.com/view/ld3SW7

// Edge of tomorrow mimic tech: https://www.youtube.com/watch?v=iiKeTPL6HPk

//#define DRAW_SLICE

struct CamData
{
    vec3 ro;
    vec3 rd;
};
void computePixelRay( in vec2 p, out CamData cam );
vec3 blackbody(float t);

// tentacle temperature (the bright pulses)
float tentTemp( float idx, float z )
{
    float phase = 8./(idx*.5+1.);
    float freq = 10./(idx*.4+1.);
    float s = .5+.5*sin(1.*z+freq*iTime + 0.*phase); // 0.* is linux "fix"..
    return smoothstep(0.99,1.,s);
}

float ten_r;

// each tentacle rotates at a constant rate but in alternating directions around the center
// of the bundle
float GetAngle( float i, float t )
{
    float amp = .75; //.25 is subtle wriggling
	t += amp*sin(1.*t + 4.*iTime + float(i));
    t += .5*iTime;
    float dir = mod(i,2.) < 0.5 ? 1. : -1.;
    return dir * (1./(.5*i+1.)+1.) * t + i/2.;
}

// the local position of each tentacle relative to the bundle center, at 
// the current slice (slice moves with ray)
#define POS_CNT 5
vec2 pos[POS_CNT];

// potential field from the tentacles used as a force to separate them
float Potential( int numNodes, vec2 x )
{
    if( numNodes == 0 ) return 0.;
    
    float res = 0.;
    float k = 8.;
    for( int i = 0; i < POS_CNT; i++ )
    {
        if( i == numNodes ) break;
        // smooth min https://iquilezles.org/articles/smin
        res += exp( -k * length( pos[i]-x ) );
    }
    return -log(res) / k;
}

// this popoulates the pos array. 
void ComputePos_Soft( float t, float z )
{
    // center of first tentacle always next to origin
    float a0 = GetAngle( 0., t );
    vec2 d0 = vec2(cos(a0),sin(a0));
    float r0 = ten_r;
    pos[0] = r0 * d0;
    
    for( int i = 1; i < POS_CNT; i++ )
    {
	    float a = GetAngle( float(i), t );
        vec2 d = vec2(cos(a),sin(a));
        float r = ten_r;
        
        // tentacle bloated by energy
        float bloat = tentTemp( float(i), z );
        
        // some iterations to push tentacles apart. uses potential
        // field of other tentacles and moves out to isoline
        for( int j = 0; j < 5; j++ )
        {
            r += 2.*ten_r/(1.-bloat*.2)-Potential(i,r*d);
        }
        
        // save final pos
        pos[i] = r * d;
    }
}

// distance to tentacles
float dTentacle( vec3 a, vec3 b, vec3 x, out bool inTents, out float minIdx, out vec3 ori, out vec3 ri, out vec3 up )
{
    // compute geometric quantities of tentacle center line
    vec3 BA = b - a;
    float ba2 = dot( BA, BA );
    float t = dot( x - a, BA ) / ba2;
    ori = a + t*BA;
    
    // compute dist to center, if it is too far away treat tentacles a cylinder
    float d2 = dot( x - ori, x - ori );
	float max_r = ten_r * (2.+float(POS_CNT));
    if( d2 > max_r )
    {
        inTents = false;
        return sqrt(d2) - (max_r-ten_r);
    }
    inTents = true;
    
    float ba = sqrt(ba2);
    vec3 BA_n = BA / ba;
    
    // get local frame around tentacle center line.
    // fast orthonormalization of up and BA_n
    // NOTE this wouldn't work if BA was a verticle line
    up = normalize( vec3(0.,1.,0.) - BA_n.y*BA_n );
    ri = cross( up, BA_n );
    
    // offset in local frame
    vec2 off_local = vec2( dot( x - ori, ri ), dot( x - ori, up ) );
    
    // compute local positions of tentacle centers
    //t += 0.025*sin(8.*t + iTime);
    float winding = 2.;
    ComputePos_Soft( winding * t * ba, x.z );
    // compute min dist to all tents
    float d = 1000.;
    for( int i = 0; i < POS_CNT; i++ )
    {
        // tentacle bloated by energy
        float bloat = tentTemp( float(i), x.z );
        // dist to this tentacle
        float di = (1.-.4*bloat)*length( off_local - pos[i] );
        if( di < d )
        {
            // if closest then save it with index
            d = di;
            minIdx = float(i);
        }
    }
    
    // dist is 75% of dist to nearest tentacle, gives a bit of space between.
    // .35 scales down ray step to help convergence
    float r = .25*ten_r;
    // add a bit of bumpyness
    vec2 U = vec2(4.*t,.5);
    r *= sqrt( textureLod( iChannel0, U, 0. ).x );
    return .2*(d - r);
}

float dScene( vec3 x, out bool inTents, out float minIdx, out vec3 o, out vec3 ri, out vec3 up )
{
    float dtent = dTentacle( vec3(0.,0.,-2.5), vec3(0.,0.,2.5), x, inTents, minIdx, o, ri, up );
    return dtent;
}
vec3 normal( vec3 pos )
{
    vec2 dd = vec2(0.01,0.);
    bool dum; float dum2;
    vec3 o, dr, du;
    float c = dScene(pos,dum,dum2,o,dr,du);
    return normalize(
        vec3( dScene(pos+dd.xyy,dum,dum2,o,dr,du)-c, dScene(pos+dd.yxy,dum,dum2,o,dr,du)-c, dScene(pos+dd.yyx,dum,dum2,o,dr,du)-c )
        );
}

#define ZFAR 15.
#define RM_STEPS 70
float rayMarch( CamData cd, out float stepsInTents, out float minIdx, out vec3 o, out vec3 ri, out vec3 up )
{
    stepsInTents = 0.;
    float t = 0.;
    for( int i = 0; i < RM_STEPS; i++ )
    {
        if( t > ZFAR ) break;
        bool intents;
        float d = dScene( cd.ro + t*cd.rd, intents, minIdx, o, ri, up );
        if( abs(d) < 0.02 ) break;
        t += d;
        if( intents )
	        stepsInTents += 1.;
    }
    
    return t;
}

vec3 drawSlice( vec2 uv )
{
    float t = iTime/2. + 5.5;
    ComputePos_Soft(t, 0.);
    float pot = Potential(5,uv);
    float dmin = 10000.;
    for( int i = 0; i < POS_CNT; i++ )
    {
        dmin = min( dmin, length( uv - pos[i] ) );
    }
    float tent = smoothstep(ten_r*1.1,ten_r*.9,dmin);
    tent = .4*tent;
    return vec3(pot)+vec3(0.,tent,0.); // pot field
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    // tentacle radius
	ten_r = 0.08;
    
	vec2 uv = fragCoord.xy / iResolution.xy;
    
    uv = 2. * uv - 1.;
    uv.x *= iResolution.x/iResolution.y;
    
    // bg
	fragColor = vec4(0.05);

    // debug draw slice that is swept along tentacle
    #ifdef DRAW_SLICE
    fragColor.rgb = drawSlice( uv );
    fragColor.a = 1.;
    return;
    #endif
    
    // sample film
    CamData cd;
    computePixelRay( uv, cd );
    
    // raymarch
    float stepCnt;
    float minIdx;
    vec3 o, ri, up;
    float z = rayMarch( cd, stepCnt, minIdx, o, ri, up );
    
    // mask out bg
    if( z < ZFAR )
    {
        // shading pt
        vec3 pt = cd.ro + z*cd.rd;
        vec3 n = normal(pt);
        
        // diffuse col
        fragColor.xyz = vec3(.2);
        
        // ndotl with light source at viewer, helps 3d look
        fragColor.xyz *= mix(0.5,1.,clamp( dot( n, -cd.rd ), 0., 1. ));
        
        // AO based on iters. idea - use potential instead?
        float ao = 1. - .5*smoothstep( 0.1, .2, stepCnt/float(RM_STEPS) );
        fragColor = mix( fragColor, ao*fragColor, .4 );
        
        // add a spiral motif
        float alph = atan( n.y, n.x );
        alph += pt.z*7.;
        alph = mod( alph, 2.*3.141592654 );
        float onSpiral = smoothstep(0.2,0.,abs(fract(7.5*alph/(2.*3.141592654))-.5));
        //bool onSpiral = fract(10.*alph/(2.*3.141592654))<.5;
        fragColor.xyz *= mix( 1., .8, onSpiral );
        
        // black body radiation emitted (added)
        float temp = tentTemp( minIdx, pt.z );
		fragColor.xyz += 2.*max(1.-onSpiral,0.05) * blackbody(temp);
        
        // catch lighting off other tents
        int minIdxi = int(minIdx);
        for( int i = 0; i < POS_CNT; i++ )
        {
            // dont catch lighting off self
            if( i == minIdxi )
                continue;
            
            // evaluate same temperature function to give light intensity from others
            float tempi = tentTemp( float(i), pt.z );
            
            // nodotl to center of other tent
            vec3 lpos = o + pos[i].x*ri + pos[i].y*up;
            vec3 l = lpos - pt;
            float ndotl = dot(n,l);
            if( ndotl > 0. )
            {
                // normalize
                ndotl = ndotl/length(l);
                // hack color added
	            fragColor.xyz += pow(tempi,2.) * .75 * ndotl * vec3(1.,.7,0.4);
            }
        }
        
        // exponential fog
        fragColor.xyz *= exp(-.1*z);
        fragColor.a = 1.;
    }
    else
    {
        fragColor.a = 0.;
    }
    
    // poor mans motion blur
    //fragColor = mix( texture(iChannel1,fragCoord.xy/iResolution.xy), fragColor, .9 );
}

void computePixelRay( in vec2 p, out CamData cam )
{
    // camera orbits around origin
	
    float camRadius = 3.8;
	// use mouse x coord
    float a = -290.0; //iTime*20.;
	if( iMouse.z > 0. )
		a = iMouse.x;
	float theta = -(a-640.)/80.;
    float xoff = camRadius * cos(theta);
    float zoff = camRadius * sin(theta);
    cam.ro = vec3(xoff,3.,zoff);
     
    // camera target
    vec3 target = vec3(0.,0.,0.);
     
    // camera frame
    vec3 fo = normalize(target-cam.ro);
    vec3 ri = normalize(vec3(fo.z, 0., -fo.x ));
    vec3 up = normalize(cross(fo,ri));
     
    // multiplier to emulate a fov control
    float fov = .45;
	
    // ray direction
    cam.rd = normalize(fo + fov*p.x*ri + fov*p.y*up);
}

// blackbody borrowed from here https://www.shadertoy.com/view/MdBSRW
// this is version has a typo, see the comments
//2200.0	// 1500.0 is more realistic
#define TEMPERATURE 3800.
vec3 blackbody(float t)
{
    t *= TEMPERATURE;
    
    float u = ( 0.860117757 + 1.54118254e-4 * t + 1.28641212e-7 * t*t ) 
            / ( 1.0 + 8.42420235e-4 * t + 7.08145163e-7 * t*t );
    
    float v = ( 0.317398726 + 4.22806245e-5 * t + 4.20481691e-8 * t*t ) 
            / ( 1.0 - 2.89741816e-5 * t + 1.61456053e-7 * t*t );

    float x = 3.0*u / (2.0*u - 8.0*v + 4.0);
    float y = 2.0*v / (2.0*u - 8.0*v + 4.0);
    float z = 1.0 - x - y;
    
    float Y = 1.0;
    float X = Y / y * x;
    float Z = Y / y * z;

    mat3 XYZtoRGB = mat3(3.2404542, -1.5371385, -0.4985314,
                        -0.9692660,  1.8760108,  0.0415560,
                         0.0556434, -0.2040259,  1.0572252);
    
	// wrong, see comments
    return XYZtoRGB * vec3(X,Y,Z) * pow(t * 0.0004, 4.0);
}

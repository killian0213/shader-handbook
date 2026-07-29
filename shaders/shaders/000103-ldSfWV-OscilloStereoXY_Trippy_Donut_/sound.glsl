// Sound (sound) — OscilloStereoXY Trippy Donut  by ttoinou
// https://www.shadertoy.com/view/ldSfWV

// copy paste this into sound and remove the next define
#define SOUNDBUFFER
//#define POINTS
#define NBITERATIONS 300 // 1000 if you have a good GPU
#define DT 1.5
#define VOLUME .7

#ifdef SOUNDBUFFER
vec3 iResolution = vec3(.0);
vec3 iMouse = vec3(.0);
#endif

#define TAU 6.2831
#define NBSAMPLES 1

#define CHOOSE(i,a,b,c) (i == 0 ? a : ( i == 1 ? b : c))

mat3 rotationMatrix(vec3 axis, float angle) {
    axis = normalize(axis);
    float s = -sin(angle);
    float c = cos(angle);
    float oc = 1.0 - c;
    
    return mat3(oc * axis.x * axis.x + c,           oc * axis.x * axis.y - axis.z * s,  oc * axis.z * axis.x + axis.y * s,
                oc * axis.x * axis.y + axis.z * s,  oc * axis.y * axis.y + c,           oc * axis.y * axis.z - axis.x * s, 
                oc * axis.z * axis.x - axis.y * s,  oc * axis.y * axis.z + axis.x * s,  oc * axis.z * axis.z + c           );
}

int Shape = 0;

vec2 gen(float t, float f)
{
    float q = t*TAU*f;
    vec2 r;
    
    /*
    float d = 12.;
    r = vec2(
    	cos(12.*q/d)+2.*sin(11.*q/d),
    	sin(13.*q/d)+3.*sin(14.*q/d)
    ) / 4.;
    */
    if(Shape==0)
    {
        r = vec2(.0);
        q *= 3.;
        r += 1.*cos(5.*q+vec2(t,TAU/4.));
        r += 2.*cos(3.*q+vec2(.0,TAU/2.));
        r += .6*cos(8.*q+vec2(t*8.,TAU/2.));
        r /= 4.;
    }
    else
    {
        mat3 Sys = mat3(.0);
        Sys[0][0] = 1.;
        Sys[1][1] = 1.;
        Sys[2][2] = 1.;

        vec3 p = vec3(.0);
        float sumRad = 1.;
        float m = 8.;

        for(float i = 1.; i < 4. ; i++)
        {
            float rad = CHOOSE(int(i)-1,   8.,4.,1.);  // pow(m,-i*.5);//
            float ang = CHOOSE(int(i)-1,   1.*i*q-t,m*i*q+t*2.2,2.*m*i*q);  //i==1. ? 3.*i*q : 4.*i*q+t*2.; // pow(m,i)*i*q;//
            float ca = cos(ang);
            float sa = sin(ang);
            p += Sys*vec3(ca,sa,.0)*rad;


            Sys *= mat3(
                  .0 , .0 , 1. ,
                  ca , sa , .0 ,
                 -sa , ca , .0
            );

            sumRad += rad;
        }

        p *= rotationMatrix(vec3(2.,-1.*cos(t*2.),1.),TAU*.5*t);
        r = p.xy/sumRad;
    }
    
    return r;
}

vec2 mainSound( in int samp, float t )
{
    Shape = (cos(t*.5)+sin(t*3.)) > .8 ? 0 : 1;
    
    vec2 r;
    
    r += gen(t,mix(13.,min(20.+t*3.,500.),pow(cos(t/24.*TAU)*.499+.501,2.)));
    //r += gen(t,120.)*mix(0.,1.,cos(t*.16*TAU)*.5+.5);
    //r += gen(t,48.);
    
    //r /= 2.;
    // limiter
    //r = tanh(r*1.5);
    
    #ifdef SOUNDBUFFER
      r *= VOLUME;
    #endif
    
    return clamp(r,-1.,1.);
}
// segment.x is distance2 to closest point
// segment.y is barycentric coefficient for closest point
vec2 segment( vec2 p, vec2 a, vec2 b )
{
  #ifndef POINTS
  float len = length(b-a);
  //b -= (b-a)*.04;
  if(len<1e-2)
  #endif
      return vec2(dot(p-a,p-a),.0);
        
  
  #ifndef POINTS
  a -= p;
  b -= p;
  vec3 k = vec3( dot(a,a) , dot(b,b) , dot(a,b) );
  float t = (k.x - k.z)/( k.x + k.y - 2.*k.z );
  a = a*(1.-t) + b*t;
  //return vec2( dot(a,a) , t );
    
  if( t < 0. ){
      return vec2( (k.x) , 0. );
  } else if( t > 1. ){
      return vec2( (k.y) , 1.  );
  } else {
  	return vec2( dot(a,a) , t );
  }
    
  #endif
}


#ifndef SOUNDBUFFER

#define linear(x,a,b,c,d) ((x-a)/(b-a)*(d-c)+c)

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
	vec2 uv = fragCoord.xy / iResolution.xy;
    vec2 uv_ = uv - vec2(.5);
    uv_.x *= iResolution.x / iResolution.y;
    uv_ += vec2(.5);
	fragColor = vec4(0.);

    vec2 uvSound = uv_*2.-vec2(1.);
    
    float fps = 60.;
    float t = iTime;
    float dt = iTimeDelta*DT;
    int nbPoints = NBITERATIONS;
    float nbPointsF = float(nbPoints);
    vec4 Color = vec4(1.);
    
	vec2 seg = vec2(.0);
    vec2 A,B;
    
    float LumPower = 6e4;
    
    float tBegin = t-dt*.97;
    float tEnd = t;
    Color.rgb =  vec3(.2,1.,.1);
    
    float tLoop = tBegin;
    A = mainSound( in int samp,tLoop);
    float tStepMin = (tEnd - tBegin)/nbPointsF/4.;
    float tStep = (tEnd - tBegin)/nbPointsF;
    tLoop += tStep;
    
    for(int i = 1; i <= nbPoints && tLoop <= tEnd ; i++)
    {
        float iF = float(i);
    	B = mainSound( in int samp,tLoop);
        seg = segment( uvSound , A , B );
    
        
        #ifndef POINTS
          float k = (iF+seg.y)/nbPointsF-.5;
          //Color.rgb = mix(Color.rgb,cos( (k ) * vec3(5.,7.,4.) * 2. - t*.6 )*.5+.5,.8);
          Color.a = max(1. - k*k*4.,.0);
          Color.a *= Color.a;
          //Color.a = smoothstep(.0,1.,Color.a);
          //Color.a *= cos(k*1e4*TAU)*.5+.5;
        #endif
    
        fragColor += Color*Color.a/(1.+seg.x*LumPower);
        
        tStep = (tEnd - tBegin)/nbPointsF;
        // trying to sample according to derivative... ????
        //tStep = max( length( (B-A) )*1e-4 , tStepMin );
        //tStep = max( length( (B-A) )/tStep*1e-6 , tStepMin );
        //float e = 1e-5;
        //float der = length( (mainSound( in int samp,tLoop+e)-B))/e;
        //tStep = max( der*4e-8 , tStepMin );
        
        tLoop += tStep;
        A = B;
    }

    fragColor += texture(iChannel0,uv)*.85;
    fragColor = tanh(fragColor*1.);
}

#endif
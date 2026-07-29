// Image (image) — Minimal surfaces gyroid by shadertoyjiang
// https://www.shadertoy.com/view/X32czG

// 20240927

#define Shadow 1     // 0 or 1
#define rot(t) mat2(cos(t), sin(t), -sin(t), cos(t))
#define time (iTime*2.)
int obj;
float dist;

float smin(float d1, float d2, float k)
{
        float h =clamp(.5 + .5 *(d2-d1)/k,0.,1.);
        return mix(d2, d1, h)-k*h*(1.-h);
}

float smax(float d1, float d2, float k)
{
        return smin(d1,d2,-k);
}

float gyr(vec3 p){
      obj=0;
      float r=4.25;
      float d1=length(p)-r;
      vec3 q=p ;
      float d2= dot(cos(q.yzx*4.),sin(q*4.))/4.-.0;
      //float d2= dot( (cos(q.yzx*4.)),cos(sin(q*4.)))/4.-.0;
      
      
      //float k = 48.;//floor(iTime);  // 4 12 20 28 36 48
      //float d6= dot(cos(p*k),sin(p.zxy*k))/k;    
      
      float k = 32.;//floor(iTime);  // 4 12 20 28 36 48
      if(iMouse.x>iResolution.x*.55)k=12.;
      float d6= dot(cos(p*k),sin(p.yzx*k))/k;       
      
      float d5 = length(max(abs(vec2(d2,d1)),0.))-.03;            
      
      dist = .5* smin(d5, length(smax(0.,smax(d1,smax(abs(d2),abs(d6)-.01,.03),.03),.01)-.001), .01);// 202409270516
            
      float flr = (100.+r)-length(p-vec3(0,100,0));
      if(flr<dist)obj=1;
      dist = min(dist,flr);
      return dist;
}


float map(vec3 p)
{
        float t = time; // 2.54
        
        //p.yz *=rot(t*.4);
        p.xz *=rot(t*.05);
        //p.xy *=rot(t*.7);
        return gyr(p);        
}


float calcSoftshadow( in vec3 ro, in vec3 rd  )
{// https://www.shadertoy.com/view/lsKcDD - iq
	float res = 1.0;
    float t = .001;
    float ph = 1e10; // big, such that y = 0 on the first iteration
    int technique=1;
    float tmax=5., w=.2;
    int j=0;
    for( int i=0; i<32; i++ )
    {   j++;
		float h = map( ro + rd*t );
        
        float dm = max(dist,.001);
        
        if( technique==0 )
        {
        	res = min( res, dm/(w*t) );
        }
        // improved technique
        else
        {
            // use this if you are getting artifact on the first iteration, or unroll the
            // first iteration out of the loop
            //float y = (i==0) ? 0.0 : h*h/(2.0*ph); 

            float y = dm*dm/(2.0*ph);
            float d = sqrt(dm*dm-y*y);
            res = min( res, d/(w*max(0.0,t-y)) );
            ph = dm;
        }
       
        t += h;//min(max(h,0.001),.5);
        
        if( res<0.0001 || t>tmax ) break;
        
    }
    //if(j>32)return 0.;
    res = clamp( res, 0.0, 1.0 );
    return res*res*(3.0-2.0*res);
}


void mainImage(out vec4 O, vec2 v)
{        
        O = vec4(.5);
        vec4 clr=vec4(1);
        vec2 R = iResolution.xy,
             u = 1. * (v+v+.1 - R) / R.y,       
             m = 1. * (iMouse.xy*2. - R) / R.y; 
        vec3 o = vec3(0, 0, -9),                
             r = normalize(vec3(u+vec2(0,-.0), 1.5)),        
             e = vec3(0, 1e-3, 0),             
             p,n,                                 
             s = normalize(vec3(-1,2,-3));      
        
        float d,t,f,g,c ;
        for(int i;i<256 && t < 8000.;i++)
        {
                p = o + r * t;
                d = map(p);
                if(d<.01)
                {
                        n = normalize(vec3(map(p+e.yxx),map(p+e),map(p+e.xxy))-d);
                        
                        f = .5 + .5 * dot(n, s);
                        g = max(dot(n,s),0.);
                        c = 1. + pow(f, 200.)-f*.3; 
                        //clr=vec4(1,0,0,0)*pow(dot(p,p)/16.,8.);
                        if(obj==1)O = vec4(.5);
                        else if(obj==2)clr=vec4(10);
                        else      O = vec4(c*g)*clr; // 亲
                        
                        #if Shadow==1
                        vec3 rf=normalize(s*100.-p);
                        //
                        float shd=   //pow(dot(p,p)/16.,8.);
                                     calcSoftshadow(p-r*.001,rf);
                        
                        if(iMouse.x<iResolution.x*1.6 )   O   *= (shd+.2);
                        #endif
                        
                        O *= smoothstep(600.,0.,length(p));
                        
                        O = pow(O, vec4(.8));
                        return;
                }
                t += d * .95 ;
        }
}
 






// Buffer A (buffer) — Wackelkontakt (4k intro) by slerpy
// https://www.shadertoy.com/view/ts2yWm

// stage 0: "screen"

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    // [shadertoy fix-up]
    
    P=acos(-1.),T=2.*P;    // calculate pi and tau
    c=.0*R,m=c;            // init c and m as vec4(0)
    
    // ^ Both of these steps are done outside
    //   the main function in the actual intro.

    // [common code across all stages]
    
    vec2 v=gl_FragCoord.xy;  // get short mutable pixel coord
    r=vec4(v,R.yz);          // init random vector using pixel coord + time
    S();S();S();S();         //   and hash it 8 times
    S();S();S();S();         // *shuffle*, *shuffle*, *shuffle*

    float tt=R.z*7./48.,     // current chord playing in the soundtrack
    w=floor(tt)*step(2.,tt), // camera movement offset
    z=1.-.3*smoothstep(-.7,.0,-abs(tt-2.1))   // zoom around 00:14
        +.2*smoothstep(-1.,0.,-abs(tt-20.));  // zoom around 02:17
    if(tt<8.)z-=pow(tt/8.,48.);               // camera plunge at 00:54

    // ^ The camera specific vars are misused
    //   as temporary vars in this stage.
    
    // [stage specific code]
    
    ivec2 j=ivec2(v);                  // set up mask, so every pixel in the fake
    m[j.x%3]=exp(float(1-j.y%3));      //   screen is only either red, green or blue
    vec2 u=vec2(j/3),y=3.*u/R.xy,t,h;  // some useful uv conversions for later effects
    m.xy*=vec2(.8,.9);                 // blue shift
    
    // scene 0: "crosses"
    if(tt<2.)
    {
        t=abs(mod(v,180.+R.z)-90.);  // triangle function / repeating box distance function
        t=max(t/4.,t-t.yx);          // cross distance / intersection between boxes and a diagonal grid
        
        h=10.+8.*step(1.,tt)+vec2(0,.5);  // set size of the crosses (low edge, high edge)
        
        c+=smoothstep(-.5,.5,-cos(dot(2.*v-R.xy,vec2(4))/6e3-T*tt))  // wave effect
            *(1.-smoothstep(h.x,h.y,max(t.x,t.y)));                  // crosses with minor smoothstep AA
        
        // ^ The AA is just make the crosses less snappy as they
        //   slowly drift towards the top right corner of the screen.
    }

	// scene 1: "perlin noise"
    else if(tt<4.)
    {
        t=pr(u/24.+T);  // calculate perlin noise
        
        c+=mix(
            step(fract(.4*R.z+2.*t.x),.2),    // foreground pattern
            dot(normalize(t-.5),pl(20.*tt)),  // background pattern
            .2*(.5-.5*cos(T*tt))              // pulsating effect
            *smoothstep(2.,4.,tt)             // intensify over time
        );
    }

	// scene 2: "burning horse"
    else if(tt<8.)
    {
        t=(2.*v-R.xy)/R.y,h=t; // set uv (in t and h)
        
        for(int i=0;i<2;++i)                 // two step shifting perlin noise
            t+=(.3+.5*smoothstep(5.,7.,tt))  //   distortion effect, which
            	*(pr(3.*t+7.+(tt-6.))-.5);   //   intensifies over time
        
        c+=max(
            step(fract(4.*length(t)-R.z),.1),  // distorted rings
            .04*dot(normalize(h-t),t)          // distortion visualizer
        );
        
        // ^ Notice the background shading indicates how quickly
        //   the rings move at any point on the plane.
    }

	// scene 3: "blocky"
    else if(tt<12.)
    {
        t=v/R.xy;  // set uv
        w=R.z;     // set time
        
        for(int i=int(max(.0,tt-11.9)*100.);i<12;i++)
        	//   ^ the transition out of the scene happends here 
        {
            // divide area into two sides, [0,z) and [z,1)
            z=.5+.2*sin(w+7.*floor(tt));
            
            // decide what side we're in and remap
            if(t.x<z)t.x/=z,w=.6+w*1.1;  // [0,z) -> [0,1) + update time
            else t.x=(t.x-z)/(1.-z);     // [z,1) -> [0,1)
            
            w+=.5;   // update time
            t=t.yx;  // swizzle uv, so we get splits in both axis
        }
        
        c+=.5+.5*cos(.5*P*w); // turn w into a color
    }

	// scene 4: "distorted rain"
    else if(tt<16.)
    {
        t=N(floor(vec2(.5*v.x                                 // get random offset
			+R.y*pr(.8*(.5*v)/R.y+3.).x                       //   with perlin noise distortion,
				*smoothstep(.0,1.,smoothstep(12.7,15.2,tt))   //   which intensifies over time
		,0.)));
        
        // simple gradient + offset = pixel rain
        c+=max(.02*t.y,4.*fract(t.x-.3*R.z-y.y)-3.);
        
        
        // anti strobe filter
        m=mix(vec4(.3),m,.15+.85*smoothstep(.0,.25,max(abs(tt-13.4)-.5,0.)));
        
        // ^ This line drops the saturation down to 15% to
        //   remove violent 60 Hz flickering around 1:32.
        //   Comment out this line at your own risk!
    }

    // scene 5: "ending"
    else
    {
        w=1.7; // set initial brightness
        
        // set uv (with a lot of random screen space distortion and rotation)
        h=pl(floor(min(tt+step(17.85,tt)+step(17.9,tt),19.)-4.)*P/3.);
        y=(((2.+h.y)*v-R.xy)/R.y+.06*H(vec2(j/int(50.-50.*h.x*h.y)))+3.)*mat2(1,1,-1,1)/6.;
        y*=mat2(h.x,h.y,-h.y,h.x);
        
        // ^ The screen distortion is just there to give the viewer something to
        //   focus on. Without it, all you get is 2 layers of random camera movement
        //   (both on and in front of the screen), which is quite disorienting to look at.
        
        // simple parallex effect
        for(int i=0;i<14;i++)
        {
            // update brightness
            w*=.6*(1.-smoothstep(18.,21.,tt));
            
            // draw patterns
            t=abs(fract(y+=vec2(4,1)*R.z/200.)-.5);
            c+=w*step(min(t.x,t.y),.01);
            
            // update scale
            y*=1.5;
        }
    }

    c=max(c*m,0.); // apply mask and clip at 0

    // [common code across all stages]
    
    fragColor=c;
}



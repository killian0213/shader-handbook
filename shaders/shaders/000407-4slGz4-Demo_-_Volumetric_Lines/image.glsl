// Image (image) — Demo - Volumetric Lines by iq
// https://www.shadertoy.com/view/4slGz4

// Copyright Inigo Quilez, 2013 - https://iquilezles.org/
// I am the sole copyright owner of this Work.
// You cannot host, display, distribute or share this Work neither
// as it is or altered, here on Shadertoy or anywhere else, in any
// form including physical and digital. You cannot use this Work in any
// commercial or non-commercial product, website or project. You cannot
// sell this Work and you cannot mint an NFTs of it or train a neural
// network with it without permission. I share this Work for educational
// purposes, and you can link to it, through an URL, proper attribution
// and unmodified screenshot, as part of your educational material. If
// these conditions are too restrictive please contact me and we'll
// definitely work it out.

vec3 hash3( float n )
{
    return fract(sin(vec3(n,n+1.0,n+2.0))*vec3(43758.5453123,22578.1459123,19642.3490423));
}

vec3 snoise3( in float x )
{
    float p = floor(x);
    float f = fract(x);

    f = f*f*(3.0-2.0*f);

    return -1.0 + 2.0*mix( hash3(p+0.0), hash3(p+1.0), f );
}

float freqs[16];

float dot2(in vec3 v ) { return dot(v,v); }
vec2 usqdLineSegment( vec3 ro, vec3 rd, vec3 v0, vec3 v1 )
{
#if 1
	vec3 oa = ro - v0;
    vec3 ob = ro - v1;
	vec3 va = rd*dot(oa,rd)-oa;
    vec3 vb = rd*dot(ob,rd)-ob;
    
    vec3 w1 = va;
    vec3 w2 = vb-w1;
    float h = clamp( -dot(w1,w2)/dot(w2,w2), 0.0, 1.0 );

    float di = dot2(w1+w2*h);
    
    return vec2(di,h);
#else
    vec3 ba = v1-v0, oa = ro-v0;

    float a = dot(ba,ba);
    float b = dot(rd,ba);
    float c = dot(oa,ba);
    float e = dot(oa,rd);

    vec2 st = vec2( c-b*e, b*c-a*e)/(a-b*b);

    st.x = min( max( st.x, 0.0), 1.0 );
    st.y =      max( st.y, 0.0 );

    return vec2( dot2( (v0+st.x*ba)-(ro+st.y*rd) ), st.x );
#endif  
}

vec3 castRay( vec3 ro, vec3 rd, float linesSpeed )
{
	vec3 col = vec3(0.0);
	
		
	float mindist = 10000.0;
	vec3 p = vec3(0.2);
	float h = 0.0;
	float rad = 0.04 + 0.15*freqs[0];
	float mint = 0.0;
    for( int i=0; i<128; i++ )
	{
		vec3 op = p;
		
		op = p;
		p  = 1.25*1.0*normalize(snoise3( 64.0*h + linesSpeed*0.015*iTime ));
		
		vec2 dis = usqdLineSegment( ro, rd, op, p );
		
		vec3 lcol = 0.6 + 0.4*sin( 10.0*6.2831*h + vec3(0.0,0.6,0.9) );
		
		float m = pow( texture( iChannel0, vec2(h*0.5,0.25) ).x, 2.0 )*(1.0+2.0*h);
		
		float f = 1.0 - 4.0*dis.y*(1.0-dis.y);
		float width = 1240.0 - 1000.0*f;
		width *= 0.25;
		float ff = 1.0*exp(-0.06*dis.y*dis.y*dis.y);
		ff *= m;
		col += 0.3*lcol*exp( -0.3*width*dis.x )*ff;
		col += 0.5*lcol*exp( -8.0*width*dis.x )*ff;
		h += 1.0/128.0;
	}


    return col;
}



void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
	vec2 q = fragCoord.xy/iResolution.xy;
    vec2 p = -1.0+2.0*q;
	p.x *= iResolution.x/iResolution.y;
    vec2 mo = iMouse.xy/iResolution.xy;
		 
	float time = iTime;


	for( int i=0; i<16; i++ )
	    freqs[i] = clamp( 1.9*pow( texture( iChannel0, vec2( 0.05 + 0.5*float(i)/16.0, 0.25 ) ).x, 3.0 ), 0.0, 1.0 );
	
	// camera	
	vec3 ta = vec3( 0.0, 0.0, 0.0 );

float isFast = smoothstep( 35.8, 35.81, iChannelTime[0] );
	isFast  -= smoothstep( 61.8, 61.81, iChannelTime[0] );
	isFast  += smoothstep( 78.0, 78.01, iChannelTime[0] );
	isFast  -= smoothstep(103.0,103.01, iChannelTime[0] );
	isFast  += smoothstep(140.0,140.01, iChannelTime[0] );
	isFast  -= smoothstep(204.0,204.01, iChannelTime[0] );
	
    float camSpeed = 1.0 + 40.0*isFast;	


	float beat = floor( max((iChannelTime[0]-35.7+0.4)/0.81,0.0) );
	time += beat*10.0*isFast;
	camSpeed *= mix( 1.0, sign(sin( beat*1.0 )), isFast );

	
float linesSpeed =  smoothstep( 22.7, 22.71, iChannelTime[0] );	
	  linesSpeed -= smoothstep( 61.8, 61.81, iChannelTime[0] );
	  linesSpeed += smoothstep( 78.0, 78.01, iChannelTime[0] );
	  linesSpeed -= smoothstep(140.0,140.01, iChannelTime[0] );

	
	ta  = 0.2*vec3( cos(0.1*time), 0.0*sin(0.1*time), sin(0.07*time) );

	vec3 ro = vec3( 1.0*cos(camSpeed*0.05*time+6.28*mo.x), 0.0, 1.0*sin(camSpeed*0.05*time+6.2831*mo.x) );
	float roll = 0.25*sin(camSpeed*0.01*time);
	
	// camera tx
	vec3 cw = normalize( ta-ro );
	vec3 cp = vec3( sin(roll), cos(roll),0.0 );
	vec3 cu = normalize( cross(cw,cp) );
	vec3 cv = normalize( cross(cu,cw) );
	vec3 rd = normalize( p.x*cu + p.y*cv + 1.2*cw );

	float curve  = smoothstep( 61.8, 71.0, iChannelTime[0] );
	      curve -= smoothstep(103.0,113.0, iChannelTime[0] );
    rd.xy += curve*0.025*vec2( sin(34.0*q.y), cos(34.0*q.x) );
	rd = normalize(rd);
	
	
	ro *= 1.0 - linesSpeed*0.5*freqs[1];
    vec3 col = castRay( ro, rd, 1.0 + 20.0*linesSpeed );
    col = col*col*2.4;
	


	// fade to black
    col *= 1.0 - smoothstep(218.0,228.00, iChannelTime[0] );
    col *=       smoothstep(  0.0,  4.00, iChannelTime[0] );
	if( iChannelTime[0]>61.8 && iChannelTime[0]<65.0 )
	col *= vec3(1.0)*clamp( (iChannelTime[0]-61.8)/(65.0-61.8), 0.0, 1.0 );
   

    col *= 0.15+0.85*pow( 16.0*q.x*q.y*(1.0-q.x)*(1.0-q.y), 0.15 );

    fragColor=vec4( col, 1.0 );
}
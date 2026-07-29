// Sound (sound) — 2nd stage BOSS by 0x4015 by Falken
// https://www.shadertoy.com/view/MsGGDK

////////////////////////////////////////////////////////////////
// 
// "2nd stage BOSS" by 0x4015 & YET11 - Shadertoy port
//   http://www.pouet.net/prod.php?which=66962
//   Big thanks to i-saint for initial GLSL Sandbox port!
//     http://glslsandbox.com/e#31067
// 
////////////////////////////////////////////////////////////////

#define v(a,b) e=j-(123.0/64.0)b;g=-1.0;h=(123.0/64.0)a;
#define r(a,b) if(e>0.0){f=a;g=e;}e-=h b;
#define q(a) if(e>0.0){f=a;g=e;}e-=h;
#define w(a) if(e>0.0)g=-1.0;e-=h a;
#define s if(e>0.0)g=-1.0;e-=h;
#define t(a,b) for(float i=0.0;i<a;++i){b}
#define u if(g>0.0&&e<0.0)

float k,l,m,n,o,p;

vec2 z(vec2 a, float b)
{
	return a*clamp(vec2(b,-b)+1.0,-1.0,1.0);
}

float B(float a, float b)
{
	b*=12.0;
	a=floor(a*b)/b;
	return sin(a*200000.0*sin(a*600078.8));
}

float D(float a, float b)
{
	b*=17.0;
	a=floor(a*b)/b;
	return sin(a*200000.0+sin(a*600078.8)*44.0);
}

float y(float a)
{
	return 55.0*exp2(a/12.0);
}

vec2 E(float a, float b)
{
	b=y(45.0);
	return vec2(smoothstep(D(a,b),D(a,b/3.0),.8));
}

vec2 F(float a, float b)
{
	b=y(b*2.0);
	return clamp(sin(pow(a*b*999.0,.43))*2.0/exp(b*b/22222.0*a) + 
                 (vec2(B(a,b+.1),B(a,b-.1))+B(a,b))/exp(6666666.0/b/b*a)*.4,-1.0,1.0);
}

float C(float a, float b)
{
	return floor(mod(a+1.0,3.0)-1.0)*b;
}

vec2 x(float a, float b)
{
	float d=0.0;
	for(float i=16.0;i<32.0;++i) {
        if (i >= l) break;
		float c=fract(a*exp2(a*p-i)*k*544922.0);
		d+=sin(3.14159265*2.0*y(b)*c/k*123.0/128.0)*m*c*exp(1.0-m*c)*exp2(i-n)*o*.01;
	}
	return vec2(clamp(d,-1.0,1.0));
}

vec2 mainSound( in int samp,float time)
{
	float j=time,e,f,g,h;
	vec2 d=vec2(0);
	t(4.0,
		vec2 a=vec2(0);
		float b=pow(fract(j/(123.0/64.0)/8.0),3.0);
		k=4.0/3.0;
		l=19.0;
		m=22.0-20.0*b;
		n=10.0;
		o=1.0+10.0*b;
		p=0.0;
		v(*16.0,*0.0)
        q(1.0)
        q(1.0)
        s;
		q(1.0)
        u {
			v(/8.0,/16.0)
            w(*i)
            t(14.0,
            	r(1.0,*15.0)
              	q(0.0)
              	r(1.0,*15.0)
              	q(2.0)
            )
            u a+=z((x(g,f+26.0)+x(g,f+33.0))/exp(i),C(i,.7));
		}
		k=1.0;
		n=9.0-5.0*b;
		m=8.0;
		++l;
		v(*4.0,*0.0)
        r(1.0,*16.0)
        s;
		r(1.0,*16.0)
        u {
			v(/8.0,*7.0)
            w(*7.0)
            t(80.0,
            	q(-2.0)
              	r(0.0,*7.0)
            )
            u a+=x(g,f)/2.0;
		}
		l=23.0;
		n=3.0;
		m=19.0-17.0*b;
		o=.2;
		v(*4.0,*32.0)
        w(*i/32.0)
        q(1.0)
        q(1.0)
        q(1.0)
        q(1.0)
        s;
		s;
		q(1.0)
        q(1.0)
        u a+=z(x(g,f+35.0)/exp(i/1.5),C(i,1.5))*2.0;
		p=.2;
		v(*2.0,*30.0)
        q(24.0)
        u a+=x(g+i*.002*g,f);
		k=30.0;
		p=-.2;
   		v(*16.0,*64.0)
        q(30.0)
        u a+=z(x(g+i*.002*g,f)/exp(g/2.0),C(i,.8))*3.0;
		v(/4.0,*16.0)
        t(28.0,
        	q(1.0)
        )
        w(*4.0)
        t(24.0,
        	q(1.0)
        )
        u a+=F(g,f+15.0);
    	v(*1.0,*1.0)
        r(1.0,*46.0)
        s;
		r(1.0,*7.0)
        s;
		r(1.0,*77.0)
        u {
			v(/4.0,*23.0)
            s;
			s;
			t(13.0,
            	s;
              	q(16.0)
            )
            w(*8.0)
            t(18.0,
            	if (i==12.0)
              		h*=.5;
             	q(1.0)
             	q(13.0)
             	w(/2.0)
              	r(1.0,/2.0)
              	q(13.0)
              	q(1.0)
              	q(13.0)
              	w(/2.0)
              	r(1.0,/2.0)
              	q(16.0)
            )
            t(8.0,
              	r(16.0,/2.0)
            )
            t(12.0,
              	r(16.0,/3.0)
            )
            t(32.0,
            	r(16.0,/4.0)
            )
            h*=2.0;
            w(*15.0)
            q(16.0)
            t(66.0,
            	q(1.0)
            )
		}
    	else
        {
            v(/4.0,*55.0)
            t(8.0,
            	r(16.0,/4.0)
              	r(16.0,/2.0)
            )
        }
    
    	u a+=F(g,f+11.0);
    	v(*1.0,*24.0)
        r(1.0,*6.0)
        s;
    	s;
    	r(1.0,*15.0)
        s;
    	r(1.0,*15.0)
        s;
    	u {
            v(/8.0,*24.0)
            t(64.0,
              	q(1.0)
              	q(11.0)
              	q(1.0)
              	r(11.0,*3.0/4.0)
               	r(1.0,/4.0)
            )
            h*=.5;
            t(64.0,
              	q(-3.0)
              	q(8.0)
            )
        }
    	u a+=E(g,f+10.0)/exp(255.0/(f+10.0)*g);
    	v(*2.0,*16.0)
        q(1.0)
        s;
    	s;
    	q(26.0)
        q(1.0)
        s;
    	q(1.0)
        q(26.0)
        q(1.0)
        s;
    	q(1.0)
        s;
    	q(1.0)
        s;
    	q(1.0)
        q(26.0)
        q(1.0)
        s;
    	q(1.0)
        q(26.0)
        q(1.0)
        q(1.0)
        q(1.0)
        h*=.5*.5;
   		q(1.0)
        q(1.0)
        h*=.5;
    	q(1.0)
        q(1.0)
        h*=.5;
    	q(1.0)
        q(1.0)
        q(1.0)
        q(1.0)
        r(1.0,*12.0)
        h=(123.0/64.)*2.0;
    	q(26.0)
        w(/4.0)
        q(1.0)
        u a+=E(g,f)/exp(44.0/(11.0+f)*abs(g-f*.15));
    	d+=clamp(a/4.0,-1.0,1.0);
   	)

	return d / 4.0 * smoothstep(0.0, 25.0, j) * smoothstep(150.0, 130.0, j);
}

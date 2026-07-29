// Sound (sound) — Miracle Snowflakes by foxes
// https://www.shadertoy.com/view/Xsd3zf

// Katy Perry - Firework

// RE -> DO_
// MI -> RE_
// SI -> LYA_
// LYA -> SOL_

#define DO 261.63
#define DO_ 277.183
#define RE 293.66
#define RE_ 311.127
#define MI 329.63
#define FA 349.2
#define FA_ 369.994
#define SOL 392.00
#define SOL_ 415.30
#define LYA 440.00
#define LYA_ 466.164
#define SI 493.88

#define pi 3.1415926535897932384626433832795
#define INS1AV 1.6

float down(float speed,float time) { return clamp((1.0-time*speed),0.0,1.0); }
float up(float speed,float time) { return clamp(time*speed,0.0,1.0); }
float operator1(float frec,float frec2, float dist) { return sin(frec*pi+dist*sin(frec2*pi));}
float operator2(float frec,float frec2, float dist) { return sin((frec+dist*sin(frec2*pi))*sin(frec2*pi)*pi);}

float zoom=4.0;
float ad=INS1AV;

float I1op1k1=0.0;
float I1op1k2=0.0;
float I1op1k3=0.0;
float I1op1k4=0.0;
float I1op1(float _in,float frec,float fm) { I1op1k1+=frec+fm*_in; return sin((I1op1k1)*2.0*pi); }
float I1op2(float _in,float frec,float fm) { I1op1k2+=frec+fm*_in; return sin((I1op1k2)*2.0*pi); }
float I1op3(float _in,float frec,float fm) { I1op1k3+=frec+fm*_in; return sin((I1op1k3)*2.0*pi); }
float I1op4(float _in,float frec,float fm) { I1op1k4+=frec+fm*_in; return sin((I1op1k4)*2.0*pi); }

float I2op1k1=0.0;
float I2op1k2=0.0;
float I2op1k3=0.0;
float I2op1k4=0.0;
float I2op1(float _in,float frec,float fm) { I2op1k1+=frec+fm*_in; return sin((I2op1k1)*2.0*pi); }
float I2op2(float _in,float frec,float fm) { I2op1k2+=frec+fm*_in; return sin((I2op1k2)*2.0*pi); }
float I2op3(float _in,float frec,float fm) { I2op1k3+=frec+fm*_in; return sin((I2op1k3)*2.0*pi); }
float I2op4(float _in,float frec,float fm) { I2op1k4+=frec+fm*_in; return sin((I2op1k4)*2.0*pi); }

float I3op1k1=0.0;
float I3op1k2=0.0;
float I3op1k3=0.0;
float I3op1k4=0.0;
float I3op1(float _in,float frec,float fm) { I3op1k1+=frec+fm*_in; return sin((I3op1k1)*2.0*pi); }
float I3op2(float _in,float frec,float fm) { I3op1k2+=frec+fm*_in; return sin((I3op1k2)*2.0*pi); }
float I3op3(float _in,float frec,float fm) { I3op1k3+=frec+fm*_in; return sin((I3op1k3)*2.0*pi); }
float I3op4(float _in,float frec,float fm) { I3op1k4+=frec+fm*_in; return sin((I3op1k4)*2.0*pi); }

float I4op1k1=0.0;
float I4op1k2=0.0;
float I4op1k3=0.0;
float I4op1k4=0.0;
float I4op1(float _in,float frec,float fm) { I4op1k1+=frec+fm*_in; return sin((I4op1k1)*2.0*pi); }
float I4op2(float _in,float frec,float fm) { I4op1k2+=frec+fm*_in; return sin((I4op1k2)*2.0*pi); }
float I4op3(float _in,float frec,float fm) { I4op1k3+=frec+fm*_in; return sin((I4op1k3)*2.0*pi); }
float I4op4(float _in,float frec,float fm) { I4op1k4+=frec+fm*_in; return sin((I4op1k4)*2.0*pi); }

float I5op1k1=0.0;
float I5op1k2=0.0;
float I5op1k3=0.0;
float I5op1k4=0.0;
float I5op1(float _in,float frec,float fm) { I5op1k1+=frec+fm*_in; return sin((I5op1k1)*2.0*pi); }
float I5op2(float _in,float frec,float fm) { I5op1k2+=frec+fm*_in; return sin((I5op1k2)*2.0*pi); }
float I5op3(float _in,float frec,float fm) { I5op1k3+=frec+fm*_in; return sin((I5op1k3)*2.0*pi); }
float I5op4(float _in,float frec,float fm) { I5op1k4+=frec+fm*_in; return sin((I5op1k4)*2.0*pi); }

float I6op1k1=0.0;
float I6op1k2=0.0;
float I6op1k3=0.0;
float I6op1k4=0.0;
float I6op1(float _in,float frec,float fm) { I6op1k1+=frec+fm*_in; return sin((I6op1k1)*2.0*pi); }
float I6op2(float _in,float frec,float fm) { I6op1k2+=frec+fm*_in; return sin((I6op1k2)*2.0*pi); }
float I6op3(float _in,float frec,float fm) { I6op1k3+=frec+fm*_in; return sin((I6op1k3)*2.0*pi); }
float I6op4(float _in,float frec,float fm) { I6op1k4+=frec+fm*_in; return sin((I6op1k4)*2.0*pi); }

float F0n1=0.0;
float F0n2=0.0;

float Filter01(float b)
{
	float resonanse=200.0*0.00390625; 
	float cutoff=20.0*0.001953125;
	float k3=pi*cutoff; 
	k3=cos(k3)/sin(k3); resonanse=k3*resonanse;	k3=k3*k3; 
	float km=1.0/(1.0+resonanse+k3); 
	resonanse=(1.0-resonanse+k3)/(1.0-k3); k3=2.0*(1.0-k3)*km;

	F0n1=(2.0-k3)*b-k3*F0n1+F0n2; F0n2=(1.0-resonanse)*b+resonanse*(F0n1-F0n2)*0.5; 
	b=km*(F0n1+b)*3.0;
	return b;
}

float n1 = 0.0;
float n2 = 0.0;
float n3 = 0.0;
float n4 = 0.0;
float fb_lp = 0.0;
float fb_hp = 0.0;
float hp = 0.0;
float p4=1.0e-24;

float Filter(float inp, float cut_lp, float res_lp)
{
	fb_lp 	= res_lp+res_lp/(1.0-cut_lp + 1e-20);
	n1 		= n1+cut_lp*(inp-n1+fb_lp*(n1-n2))+p4;
	n2		= n2+cut_lp*(n1-n2);
    return n2;
}

float Instr1(float de,float time,float l)
{
    float b=0.0;
    b=I1op1(sin(de*0.98467*time*pi),de*0.99616*time,ad)*0.06103515625;
    b=I1op2(b,de*0.99808*time,ad)*0.152587890625;
    b=I1op3(b,de*0.99616*time,ad)*0.213623046875;
    b=I1op4(b,de*time,ad)*0.244140625;
    return b*2.0*pow(up(20.0,time)*down(l,time-0.05),3.0);
}

float Instr2(float de, float time, float l)
{
    float b=0.0;
    b=I2op1(sin(de*0.98467*time*pi),de*0.99616*time,ad)*0.06103515625;
    b=I2op2(b,de*0.99808*time,ad)*0.152587890625;
    b=I2op3(b,de*0.99616*time,ad)*0.213623046875;
    b=I2op4(b,de*time,ad)*0.244140625;
    return b*2.0*pow(up(20.0,time)*down(l,time-0.05),3.0);
}

float Instr3(float de,float time, float l)
{
    float b=0.0;
    b=I3op1(sin(de*0.98467*time*pi),de*0.99616*time,ad)*0.06103515625;
    b=I3op2(b,de*0.99808*time,ad)*0.152587890625;
    b=I3op3(b,de*0.99616*time,ad)*0.213623046875;
    b=I3op4(b,de*time,ad)*0.244140625;    
    return b*2.0*pow(up(20.0,time)*down(l,time-0.05),3.0);
}

float Instr4(float de,float time, float l)
{
    float b=0.0;
    b=I4op1(sin(de*0.98467*time*pi),de*0.99616*time,ad)*0.06103515625;
    b=I4op2(b,de*0.99808*time,ad)*0.152587890625;
    b=I4op3(b,de*0.99616*time,ad)*0.213623046875;
    b=I4op4(b,de*time,ad)*0.244140625;  
    return b*2.0*pow(up(20.0,time)*down(l,time-0.05),3.0);
}

float Instr5(float de,float time, float l)
{
    float b=0.0;
    b=I5op1(sin(de*0.98467*time*pi),de*0.99616*time,ad)*0.06103515625;
    b=I5op2(b,de*0.99808*time,ad)*0.152587890625;
    b=I5op3(b,de*0.99616*time,ad)*0.213623046875;
    b=I5op4(b,de*time,ad)*0.244140625;    
    return b*2.0*pow(up(20.0,time)*down(l,time-0.05),3.0);
}

float Instr6(float de,float time, float l)
{
    float b=0.0;
    b=I6op1(sin(de*0.98467*time*pi),de*0.99616*time,ad)*0.06103515625;
    b=I6op2(b,de*0.99808*time,ad)*0.152587890625;
    b=I6op3(b,de*0.99616*time,ad)*0.213623046875;
    b=I6op4(b,de*time,ad)*0.244140625;  
    return b*2.0*pow(up(20.0,time)*down(l,time-0.05),3.0);
}

float Instr20(float de,float time)
{
	float x=pi*time*2.0;
	float f0=de;//*110.0*0.015625;
    float f1=0.2;
  	float f2=0.25;
  	float a=sin(2.0*f0*pi*time);
  	float c=f1*time+f2*a;
  	float b=sin(a*c*2.0*pi)+operator1(de*8.0*time,de*8.0*time,10.0)*0.1;
  	return b*0.9*pow(up(20.0,time),3.0)*down(7.0,time-0.1);
}

    //for (int i=1;i<20;i++) b+=sin(2.0*pi*float(i)*s*time)*(20.0-float(i))*0.01;
    
    //float b=0.0;
    /*float c=0.0;
    float d=de*2.01;
    for (int i=0;i<100;i++) c+=sin(d*2.0*pi*(time+float(i)/44100.0))*float(i)*0.01;
    b+=sin(de*1.01*time*pi+c)*0.1;
    c=0.0;
	d=de*2.005;
    for (int i=0;i<100;i++) c+=sin(d*2.0*pi*(time+float(i)/44100.0))*float(i)*0.01;
    b+=sin(de*1.005*time*pi+c)*0.1;
    c=0.0;
	d=de*1.0;
    for (int i=0;i<100;i++) c+=sin(d*2.0*pi*(time+float(i)/44100.0))*float(i)*0.01;
    b+=sin(de*time*pi+c)*0.5;
    c=0.0;
	d=de*1.995;
    for (int i=0;i<100;i++) c+=sin(d*2.0*pi*(time+float(i)/44100.0))*float(i)*0.01;
    b+=sin(de*0.995*time*pi+c)*0.1;
    c=0.0;
	d=de*1.99;
    for (int i=0;i<100;i++) c+=sin(d*2.0*pi*(time+float(i)/44100.0))*float(i)*0.01;
    b+=sin(de*0.99*time*pi+c)*0.1;
    b*=0.125;*/
    
    //b+=operator1(de*1.0*time,de*1.0*time,3.0)*0.5;
    //b+=operator2(0.2*time,de*2.0*time,0.25)*0.5;
    //b+=operator2(0.5*time,de*2.0*time,0.125)*0.25;
    //b+=operator2(1.0*time,de*1.0*time,10.1155)*0.125;
    //b+=operator(operator(operator(de*time,d*time,0.01),d*time,0.1),d*time,1.0);
    //b+=operator1(de*time,d*time,1.0);
    //b+=operator1(operator1(de*1.0*time,0.0,0.0),de*1.0*time,3.0)*up(19.0,time)*down(10.0,time-0.1)*0.25;
    //b+=operator1(operator1(de*1.001*time,0.0,0.0),10.0*time,1.0);
    //b+=operator(operator(de*2.0*time,0.0,0.0),d*time,1.0);
    //b+=operator(de*16.0*time,d*time,1.0);
    //b+=operator(de*time,261.63*time,10.0);

// bass
float Instr21(float de,float time)
{
	float x=pi*time*2.0;
	float f0=de;//*110.0*0.015625;
    float f1=0.2;
  	float f2=0.25;
  	float a=sin(2.0*f0*pi*time);
  	float c=f1*time+f2*a;
  	float b=sin(a*c*2.0*pi);//+operator1(de*8.0*time,de*8.0*time,10.0)*0.1;
  	return b*0.9*up(20.0,time)*down(7.0,time-0.1)*2.0;
    
    //return sin(de*time*2.0*pi)*up(20.0,time)*down(8.0,time-0.1);
}

float Instr22(float de,float time)
{
	float x=pi*time*2.0;
	float f0=de;//*110.0*0.015625;
    float f1=0.2;
  	float f2=0.25;
  	float a=sin(2.0*f0*pi*time);
  	float c=f1*time+f2*a;
  	float b=sin(a*c*2.0*pi);
  	return (b)*0.9*up(15.0,time)*(down(7.0,time-0.1)+down(1.0,time))*1.5;
}

float instr40(float ds, float time)
{
    ds*=time;
    float val;
    float r=0.0;
    float v=1.0;
    
    for (int i=0;i<2;i++) {
		ds*=2.0; val=fract(ds);
    	if (mod(ds,2.0)>1.0) { val=sin((val+0.5)*pi)*0.5; } else val-=0.5;
        r+=sin(exp(val*2.0)*pi)*v;
        v*=0.15;
    }
    return r*clamp(time*30.0,0.0,1.0)*(1.0+sin((clamp((1.1-time*3.0),0.0,1.0)-0.5)*pi));
}

float instr41(float ds, float time)
{
    float s=ds*time;
    return (fract(s)-0.5)*(1.0+sin((clamp((1.0-time*1.2),0.0,1.0)-0.5)*pi));
}

#define PI00(a,b) if ((f>=a && f<a+4)) r+=Instr1(b*tone,(fract(time*zoom)+float(f-a))/zoom,l)*v;
#define PI01(a,b) if ((f>=a && f<a+4)) r+=Instr2(b*tone,(fract(time*zoom)+float(f-a))/zoom,l)*v;
#define PI02(a,b) if ((f>=a && f<a+4)) r+=Instr3(b*tone,(fract(time*zoom)+float(f-a))/zoom,l)*v;
#define PI03(a,b) if ((f>=a && f<a+4)) r+=Instr4(b*tone,(fract(time*zoom)+float(f-a))/zoom,l)*v;

#define PI20(a,b) if ((f>=a && f<a+2)) r+=Instr20(b*tone,(fract(time*zoom)+float(f-a))/zoom)*v;

vec2 PatternP1( float time )
{
    float zoom=4.0;
    int f=int(mod(floor(time*zoom),32.0));
    
    ad=0.8;
    float l=2.0;
    float tone=0.25;
    float v=0.2;
    float r=0.0;
    	PI20(0,DO)PI20(0,RE_)PI20(1,DO)PI20(1,RE_)PI20(2,DO)PI20(2,RE_)PI20(3,DO)PI20(3,RE_)
        PI20(4,DO)PI20(4,RE_)PI20(5,DO)PI20(5,RE_)PI20(6,DO)PI20(6,RE_)PI20(7,DO)PI20(7,RE_)
    	PI20(8,LYA_*0.5)PI20(8,RE_)PI20(9,LYA_*0.5)PI20(9,RE_)PI20(10,LYA_*0.5)PI20(10,RE_)PI20(11,LYA_*0.5)PI20(11,RE_)
        PI20(12,LYA_*0.5)PI20(12,RE_)PI20(13,LYA_*0.5)PI20(13,RE_)PI20(14,LYA_*0.5)PI20(14,RE_)PI20(15,LYA_*0.5)PI20(15,RE_)
    	PI20(16,SOL_*0.5)PI20(16,RE_)PI20(17,SOL_*0.5)PI20(17,RE_)PI20(18,SOL_*0.5)PI20(18,RE_)PI20(19,SOL_*0.5)PI20(19,RE_)
        PI20(20,SOL_*0.5)PI20(20,RE_)PI20(21,SOL_*0.5)PI20(21,RE_)PI20(22,SOL_*0.5)PI20(22,RE_)PI20(23,SOL_*0.5)PI20(23,RE_)
    	PI20(24,RE_)PI20(25,RE_)PI20(26,RE_)PI20(27,RE_)
        PI20(28,RE_)PI20(29,RE_)PI20(30,RE_)PI20(31,RE_)

  	//float b=;
    
	return vec2(r);//vec2(clamp(abs(Filter(r,10.0,1.0))*0.03,-1.0,1.0)*0.8);
    //return vec2(r);
}

/*vec2 PatternB1( float time )
{
    float zoom=4.0;
    int f=int(mod(floor(time*zoom),64.0));
    
    float tone=0.25;
    float v=0.2;
    float r=0.0;
    	PI21(1,SOL_*0.5)PI21(1,RE_)PI21(3,SOL_*0.5)PI21(3,RE_)PI21(5,SOL_*0.5)PI21(5,RE_)PI21(7,SOL_*0.5)PI21(7,RE_)
		PI21(9,FA_*0.5)PI21(9,DO_)PI21(11,FA_*0.5)PI21(11,DO_)PI21(13,FA_*0.5)PI21(13,DO_)PI21(15,FA_*0.5)PI21(15,DO_)
		PI21(17,FA*0.5)PI21(17,DO)PI21(19,FA*0.5)PI21(19,DO)PI21(21,FA*0.5)PI21(21,DO)PI21(23,FA*0.5)PI21(23,DO)
        PI21(25,DO_)PI21(25,SOL_)PI21(27,DO_)PI21(27,SOL_)PI21(29,DO_)PI21(29,SOL_)PI21(31,DO_)PI21(31,SOL_)
            
  	//float b=;
    
	return vec2(r);//vec2(clamp(abs(Filter(r,10.0,1.0))*0.03,-1.0,1.0)*0.8);
    //return vec2(r);
}*/

#define CH01(a,t) if (f>=a) { d1=t; s1=a; }
#define CH02(a,t) if (f>=a) { d2=t; s2=a; }
#define C1BASS03(a,t) if (f>=a) { d3=t; s3=a; }
#define C1BASS04(a,t) if (f>=a) { d4=t; s4=a; }
#define C1BASS21(a,t) if (f>=a) { d5=t; s5=a; }
#define C1BASS22(a,t) if (f>=a) { d6=t; s6=a; }
#define C1BASS23(a,t) if (f>=a) { d7=t; s7=a; }
#define C1BASS24(a,t) if (f>=a) { d8=t; s8=a; }

vec2 PatternC1( float time,float df )
{
    int f=int(mod(floor(time*zoom),64.0));
    
    float tone=2.0;//0.25;
    float l=2.0;
    float v=0.2;
    float r=0.0;
    float t=0.0;
    
    float d1=0.0;
    float d2=0.0;
    float d3=0.0;
    float d4=0.0;
    float d5=0.0;
    float d6=0.0;
    float d7=0.0;
    float d8=0.0;
    int s1=0;
    int s2=0;
    int s3=0;
    int s4=0;
    int s5=0;
    int s6=0;
    int s7=0;
    int s8=0;
    
    /*tone=1.0;
    	PI00(0,SOL_*0.5)PI01(0,DO)PI00(2,SOL_*0.5)PI01(2,LYA_*0.5)PI00(4,SOL_*0.5)PI01(4,DO)PI00(6,SOL_*0.5)PI01(6,LYA_*0.5)
		PI02(1,SOL_*0.5)PI03(1,DO)PI02(3,SOL_*0.5)PI03(3,LYA_*0.5)PI02(5,SOL_*0.5)PI03(5,DO)PI02(7,SOL_*0.5)PI03(7,LYA_*0.5)
		PI00(8,LYA_*0.5)PI01(8,DO_)PI00(10,LYA_*0.5)PI01(10,DO)PI00(12,LYA_*0.5)PI01(12,DO_)PI00(14,LYA_*0.5)PI01(14,DO)
		PI02(9,LYA_*0.5)PI03(9,DO_)PI02(11,LYA_*0.5)PI03(11,DO)PI02(13,LYA_*0.5)PI03(13,DO_)PI02(15,LYA_*0.5)PI03(15,DO)
		PI00(16,FA_*0.5)PI01(16,LYA_*0.5)PI00(18,FA_*0.5)PI01(18,SOL_*0.5)PI00(20,FA_*0.5)PI01(20,LYA_*0.5)PI00(22,FA_*0.5)PI01(22,SOL_*0.5)
		PI02(17,FA_*0.5)PI03(17,LYA_*0.5)PI02(19,FA_*0.5)PI03(19,SOL_*0.5)PI02(21,FA_*0.5)PI03(21,LYA_*0.5)PI02(23,FA_*0.5)PI03(23,SOL_*0.5)
		PI00(24,DO_*0.5)PI01(24,LYA_*0.5)PI00(26,DO_*0.5)PI01(26,SOL_*0.5)PI00(28,DO_*0.5)PI01(28,LYA_*0.5)PI00(30,DO_*0.5)PI01(30,SOL_*0.5)
		PI02(25,DO_*0.5)PI03(25,LYA_*0.5)PI02(27,DO_*0.5)PI03(27,SOL_*0.5)PI02(29,DO_*0.5)PI03(29,LYA_*0.5)PI02(31,DO_*0.5)PI03(31,SOL_*0.5)
    r=r*0.7;*/
    	C1BASS21(0,SOL_*0.5)C1BASS22(0,DO)C1BASS21(2,SOL_*0.5)C1BASS22(2,LYA_*0.5)C1BASS21(4,SOL_*0.5)C1BASS22(4,DO)C1BASS21(6,SOL_*0.5)C1BASS22(6,LYA_*0.5)
		C1BASS23(1,SOL_*0.5)C1BASS24(1,DO)C1BASS23(3,SOL_*0.5)C1BASS24(3,LYA_*0.5)C1BASS23(5,SOL_*0.5)C1BASS24(5,DO)C1BASS23(7,SOL_*0.5)C1BASS24(7,LYA_*0.5)
        C1BASS21(8,LYA_*0.5)C1BASS22(8,DO_)C1BASS21(10,LYA_*0.5)C1BASS22(10,DO)C1BASS21(12,LYA_*0.5)C1BASS22(12,DO_)C1BASS21(14,LYA_*0.5)C1BASS22(14,DO)
		C1BASS23(9,LYA_*0.5)C1BASS24(9,DO_)C1BASS23(11,LYA_*0.5)C1BASS24(11,DO)C1BASS23(13,LYA_*0.5)C1BASS24(13,DO_)C1BASS23(15,LYA_*0.5)C1BASS24(15,DO)
        C1BASS21(16,FA_*0.5)C1BASS22(16,LYA_*0.5)C1BASS21(18,FA_*0.5)C1BASS22(18,SOL_*0.5)C1BASS21(20,FA_*0.5)C1BASS22(20,LYA_*0.5)C1BASS21(22,FA_*0.5)C1BASS22(22,SOL_*0.5)
		C1BASS23(17,FA_*0.5)C1BASS24(17,LYA_*0.5)C1BASS23(19,FA_*0.5)C1BASS24(19,SOL_*0.5)C1BASS23(21,FA_*0.5)C1BASS24(21,LYA_*0.5)C1BASS23(23,FA_*0.5)C1BASS24(23,SOL_*0.5)
		C1BASS21(24,DO_*0.5)C1BASS22(24,LYA_*0.5)C1BASS21(26,DO_*0.5)C1BASS22(26,SOL_*0.5)C1BASS21(28,DO_*0.5)C1BASS22(28,LYA_*0.5)C1BASS21(30,DO_*0.5)C1BASS22(30,SOL_*0.5)
		C1BASS23(25,DO_*0.5)C1BASS24(25,LYA_*0.5)C1BASS23(27,DO_*0.5)C1BASS24(27,SOL_*0.5)C1BASS23(29,DO_*0.5)C1BASS24(29,LYA_*0.5)C1BASS23(31,DO_*0.5)C1BASS24(31,SOL_*0.5)

		CH01(1,SOL_*0.5)CH02(1,DO)C1BASS03(3,SOL_*0.5)C1BASS04(3,LYA_*0.5)CH01(5,SOL_*0.5)CH02(5,DO)C1BASS03(7,SOL_*0.5)C1BASS04(7,LYA_*0.5)
		CH01(9,LYA_*0.5)CH02(9,DO_)C1BASS03(11,LYA_*0.5)C1BASS04(11,DO)CH01(13,LYA_*0.5)CH02(13,DO_)C1BASS03(15,LYA_*0.5)C1BASS04(15,DO)
		CH01(17,FA_*0.5)CH02(17,LYA_*0.5)C1BASS03(19,FA_*0.5)C1BASS04(19,SOL_*0.5)CH01(21,FA_*0.5)CH02(21,LYA_*0.5)C1BASS03(23,FA_*0.5)C1BASS04(23,SOL_*0.5)
		CH01(25,DO_*0.5)CH02(25,LYA_*0.5)C1BASS03(27,DO_*0.5)C1BASS04(27,SOL_*0.5)CH01(29,DO_*0.5)CH02(29,LYA_*0.5)C1BASS03(31,DO_*0.5)C1BASS04(31,SOL_*0.5)

	tone=0.5;
    r+=instr40(tone*d5,(fract(time*zoom)+float(f-s5))/zoom)*v;
    r+=instr40(tone*d6,(fract(time*zoom)+float(f-s6))/zoom)*v;
    r+=instr40(tone*d7,(fract(time*zoom)+float(f-s7))/zoom)*v;
    r+=instr40(tone*d8,(fract(time*zoom)+float(f-s8))/zoom)*v;   
    t+=r*0.1;
    r=0.0;
    r+=instr41(tone*d1,(fract(time*zoom)+float(f-s1))/zoom)*v;
    r+=instr41(tone*d2,(fract(time*zoom)+float(f-s2))/zoom)*v;
    r+=instr41(tone*d3,(fract(time*zoom)+float(f-s3))/zoom)*v;
    r+=instr41(tone*d4,(fract(time*zoom)+float(f-s4))/zoom)*v;
    t+=r*0.5*df;
    
	return vec2(t*1.0);
}

vec2 PatternC2( float time,float df )
{
    int f=int(mod(floor(time*zoom),64.0));
    
    float tone=2.0;
    float v=0.2;
    float r=0.0;
    float t=0.0;
    
    ad=0.9+df*0.5;
    float l=0.7;
    tone=2.0;//0.5;//0.125;
    	PI00(0,SOL_*0.5)PI01(0,DO)PI02(2,SOL_*0.5)PI03(2,LYA_*0.5)PI00(4,SOL_*0.5)PI01(4,DO)PI02(6,SOL_*0.5)PI03(6,LYA_*0.5)
		PI00(8,LYA_*0.5)PI01(8,DO_)PI02(10,LYA_*0.5)PI03(10,DO)PI00(12,LYA_*0.5)PI01(12,DO_)PI02(14,LYA_*0.5)PI03(14,DO)
		PI00(16,FA_*0.5)PI01(16,LYA_*0.5)PI02(18,FA_*0.5)PI03(18,SOL_*0.5)PI00(20,FA_*0.5)PI01(20,LYA_*0.5)PI02(22,FA_*0.5)PI03(22,SOL_*0.5)
		PI00(24,DO_*0.5)PI01(24,LYA_*0.5)PI02(26,DO_*0.5)PI03(26,SOL_*0.5)PI00(28,DO_*0.5)PI01(28,LYA_*0.5)PI02(30,DO_*0.5)PI03(30,SOL_*0.5)
	t+=r;
    r=0.0;
	tone=4.0;
    	PI00(0,SOL_*0.5)PI01(0,DO)PI02(2,SOL_*0.5)PI03(2,LYA_*0.5)PI00(4,SOL_*0.5)PI01(4,DO)PI02(6,SOL_*0.5)PI03(6,LYA_*0.5)
		PI00(8,LYA_*0.5)PI01(8,DO_)PI02(10,LYA_*0.5)PI03(10,DO)PI00(12,LYA_*0.5)PI01(12,DO_)PI02(14,LYA_*0.5)PI03(14,DO)
		PI00(16,FA_*0.5)PI01(16,LYA_*0.5)PI02(18,FA_*0.5)PI03(18,SOL_*0.5)PI00(20,FA_*0.5)PI01(20,LYA_*0.5)PI02(22,FA_*0.5)PI03(22,SOL_*0.5)
		PI00(24,DO_*0.5)PI01(24,LYA_*0.5)PI02(26,DO_*0.5)PI03(26,SOL_*0.5)PI00(28,DO_*0.5)PI01(28,LYA_*0.5)PI02(30,DO_*0.5)PI03(30,SOL_*0.5)
	t+=r*0.6*df;
    
	return vec2(t*1.0);
}

vec2 PatternSolo1( float time, float df)
{
    int f=int(floor(time*zoom));
    
    float tone=2.0;    
    float v=0.2;
    float r=0.0;
    float t=0.0;
    
    float d1=0.0;
    float d2=0.0;
    float d3=0.0;
    float d4=0.0;
    int s1=0;
    int s2=0;
    int s3=0;
    int s4=0;
    
    CH01(122,SOL_)CH01(123,SOL_)CH01(124,RE_)CH02(124,LYA_*2.0)CH01(125,SOL_)CH01(126,SOL_)CH01(127,RE_)CH02(127,DO*2.0)
    CH01(134,LYA_)CH01(135,FA)CH02(135,DO_*2.0)
	CH01(142,DO*2.0)CH01(143,LYA_)CH02(143,RE_*2.0)
	CH01(150,DO_*2.0)CH01(151,LYA_)CH02(151,FA*2.0)
	CH01(158,SOL*2.0)CH01(159,SOL_*2.0)CH02(159,DO*2.0)
	CH01(166,RE_*2.0)CH01(167,LYA_*2.0)CH02(167,DO_*2.0)
	CH01(173,SOL_*2.0)CH01(174,LYA_*2.0)CH01(175,DO_*3.0)CH02(175,RE_*2.0)
	CH01(179,SOL_*2.0)CH02(179,RE_*2.0)CH01(182,SOL*2.0)CH02(182,RE_*2.0)CH01(183,FA*2.0)CH02(183,DO_*2.0)
	CH01(187,FA*2.0)CH01(188,RE_*3.0)CH01(189,DO_*3.0)CH01(190,DO*3.0)CH01(191,LYA_*2.0)
	CH01(192,LYA_*2.0)CH02(192,RE_*2.0)CH01(198,SOL_*2.0)CH01(199,DO*4.0)CH02(199,FA*2.0)
	CH01(204,RE_*3.0)CH01(205,DO_*3.0)CH01(206,DO*3.0)CH01(207,LYA_*2.0)
	CH01(208,LYA_*2.0)CH02(208,RE_*2.0)CH01(214,SOL_*2.0)CH01(215,DO*4.0)CH02(215,FA*2.0)
	CH01(220,RE_*3.0)CH01(221,DO_*3.0)CH01(222,DO*3.0)CH01(223,LYA_*2.0)
	CH01(224,LYA_*2.0)CH02(224,RE_*2.0)CH01(227,LYA_*2.0)CH02(227,RE_*2.0)CH01(230,LYA_*2.0)CH02(230,RE_*2.0)
	CH01(234,RE_*2.0)CH01(235,RE_*2.0)CH01(236,RE_*3.0)CH01(237,DO_*3.0)CH01(238,DO*3.0)CH01(239,LYA_*2.0)
	CH01(240,LYA_*2.0)CH02(240,RE_*2.0)CH01(243,LYA_*2.0)CH02(243,RE_*2.0)CH01(246,LYA_*2.0)CH02(246,RE_*2.0)
	CH01(253,RE_*2.0)CH01(254,RE_*3.0)CH01(255,DO_*3.0)CH01(256,DO*3.0)CH01(257,LYA_*2.0)
	CH01(256,LYA_*2.0)CH02(256,RE_*2.0)CH01(262,SOL_*2.0)CH01(263,DO*4.0)CH02(263,FA*2.0)
	CH01(268,RE_*3.0)CH01(269,DO_*3.0)CH01(270,DO*3.0)CH01(271,LYA_*2.0)
	CH01(272,LYA_*2.0)CH02(272,RE_*2.0)CH01(278,SOL_*2.0)CH01(279,DO*4.0)CH02(279,FA*2.0)
	CH01(284,RE_*3.0)CH01(285,DO_*3.0)CH01(286,DO*3.0)CH01(287,LYA_*2.0)
	CH01(288,LYA_*2.0)CH02(288,RE_*2.0)CH01(291,LYA_*2.0)CH02(291,RE_*2.0)CH01(294,LYA_*2.0)CH02(294,RE_*2.0)
	CH01(298,RE_*2.0)CH01(299,RE_*2.0)CH01(300,RE_*3.0)CH01(301,DO_*3.0)CH01(302,DO*3.0)CH01(303,LYA_*2.0)
	CH01(304,LYA_*2.0)CH02(304,RE_*2.0)CH01(307,LYA_*2.0)CH02(307,RE_*2.0)CH01(310,LYA_*2.0)CH02(310,RE_*2.0)CH01(312,SOL_*2.0)
	CH01(314,SOL_*2.0)CH02(314,RE_*2.0)
    
	ad=0.6+df*0.6;
	r+=Instr5(tone*d1*0.25,(fract(time*zoom)+float(f-s1))/zoom,0.1)*v;
    r+=Instr6(tone*d2*0.25,(fract(time*zoom)+float(f-s2))/zoom,0.1)*v;
    r+=Instr5(tone*d1,(fract(time*zoom)+float(f-s1))/zoom,0.1)*v;
    r+=Instr6(tone*d2,(fract(time*zoom)+float(f-s2))/zoom,0.1)*v;
    r+=Instr5(tone*d1*2.0,(fract(time*zoom)+float(f-s1))/zoom,0.1)*v*0.5;
    r+=Instr6(tone*d2*2.0,(fract(time*zoom)+float(f-s2))/zoom,0.1)*v*0.5;
    t+=r*0.5;
    
    return vec2(t*1.0);
}

float s=0.0;

vec2 mainSound( in int samp, float time )
{
    vec2 r=vec2(0.0);
    
    /*time+=8.0*5.0;
    //if (time<0.0) return vec2(0.0);
    
    //time=mod(time,8.0*16.0);
    //bool sa=mod(time,16.0)>=8.0;
    float df;
    
    df=clamp((time-8.0*8.0)*0.25,0.0,1.0);
    if (time<8.0*12.0) r+=PatternC2(time,df)*0.4;
    if (time<8.0*13.0) r+=PatternC2(time-8.0,df)*0.4;
    if (time<8.0*12.0) r+=PatternSolo1(time-8.0,df);
    
    df=clamp((time-8.0*7.0)*0.125,0.0,1.0);
    if (time<8.0*12.0) r+=PatternC1(time,df)*0.5;
   	if (time<8.0*13.0) r+=PatternC1(time-8.0,df)*0.5;*/
    
    
    //r+=PatternC1(time-0.01)*0.3;
    //r+=PatternP1(time)*0.5;
    //r+=PatternB1(time)*0.4;
    //r+=PatternB1(time-0.1)*0.2;
    //r+=PatternP1(time-0.1)*0.25;
    //r+=PatternP1(time-0.2)*0.125;
    //return vec2(s);
    return r;
    //return PatternB1(time);
    //vec2(Instr1(DO*2.0,time))+vec2(Instr2(DO*4.0,time))+vec2(Instr3(MI*4.0,time))+vec2(Instr4(SOL*4.0,time));
    //return vec2( sin(6.2831*440.0*time)*exp(-3.0*time) );
}
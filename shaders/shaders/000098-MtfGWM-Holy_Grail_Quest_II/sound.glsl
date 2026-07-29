// Sound (sound) — Holy Grail Quest II by eiffie
// https://www.shadertoy.com/view/MtfGWM

#define bps 6.0
float nofs(float n){//the song's "random" ring
    n=mod(n,8.0);
    if(n<1.0)return 0.0;
    if(n<2.0)return 1.0;
    if(n<3.0)return 2.0;
    if(n<4.0)return 3.0;
    if(n<5.0)return -3.0;
    if(n<6.0)return -2.0;
    if(n<7.0)return -1.0;
    return 0.0;
}

float scale(float note){//throws out dissonant tones
	float n2=mod(note,12.0);
	//if((n2==1.0)||(n2==3.0)||(n2==6.0)||(n2==8.0)||(n2==10.0))note=-100.0;//major
	//if((n2==1.0)||(n2==4.0)||(n2==6.0)||(n2==9.0)||(n2==11.0))note=-100.0;//minor
	if((n2==1.0)||(n2==4.0)||(n2==5.0)||(n2==9.0)||(n2==10.0))note=-100.0;//hungarian minor
	if(note>84.0)note=84.0+n2;
	return note;
}
#define TAO 6.283185
// note number to frequency  from https://www.shadertoy.com/view/ldfSW2
//float ntof(float n){if(n<12.0)return 0.0;return 440.0 * pow(2.0, (n - 67.0) / 12.0);}

float ntof(float note){//note frequencies from wikipedia
	if(note<12.0)return 0.0;
	float octave=floor((note+0.5)/12.0)-5.0;
	note=mod(note,12.0);
	float nt=493.88;
    if(note<0.5)nt=261.63;
	else if(note<1.5)nt=277.18;
	else if(note<2.5)nt=293.66;
    else if(note<3.5)nt=311.13;
    else if(note<4.5)nt=329.63;
    else if(note<5.5)nt=349.23;
    else if(note<6.5)nt=369.99;
    else if(note<7.5)nt=392.0;
    else if(note<8.5)nt=415.30;
    else if(note<9.5)nt=440.0;
    else if(note<10.5)nt=466.16;
	return nt*pow(2.0,octave);
}


float ssaw(float t){return 4.0*abs(fract(t)-0.5)-1.0;}
float rnd(float t){return fract(sin(t*341.545234)*1531.2341);}
float srnd(float t){float t2=fract(t);return mix(rnd(floor(t)),rnd(floor(t+1.0)),t2*t2*(3.0-2.0*t2));}
float harm(float x,float ps,float hm,float sp){//phase shift, harmonics, spacing
	float a2=0.0,s=1.0;
	for(int i=0;i<10;i++){
		if(i<int(hm)){
			a2+=sin((x*s+ps)*TAO)/s;
			s+=sp;
		}
	}
	return a2*0.5;
}
vec2 inst(float n,float t,float bt,float pan,int i){
	float f=ntof(scale(n)),ps=0.0,hm=0.0,sp=1.0;
	if(f<12.0)return vec2(0.0);	
	if(i==0){ps=pow(bt*0.5,0.25)*0.2;hm=9.0;}
	else if(i==1){ps=bt*0.5;hm=4.0;sp=0.5;}
	else if(i==9){ps=bt*rnd(t);hm=10.0-4.0*bt;f*=0.5+0.5*rnd(t);}
	float a=harm(f*t,ps,hm,sp);
	a*=exp(-bt*(0.9+float(i)))*min(min(bt,2.0-bt)*100.0,1.0)*60.0/n;
	return vec2(a*(1.0-pan),a*pan);
}
vec2 inst2(float nn,float no,float of,float t,float bt,float pan,int i){
	return inst(nn+of,t,bt,pan,i)+inst(no+of,t,bt+1.0,pan,i);//plays new note and tail of last note
}
vec2 mainSound( in int samp,float time)
{
	float tim=time*bps;
	if(tim>128.0 && tim<256.0)tim=224.0-tim;
	float b=floor(tim);
	float t0=fract(tim),t1=mod(tim,2.0)*0.5,t2=mod(tim,4.0)*0.25;
	float n2=nofs(b*0.0625)+nofs(b*0.125)+nofs(b*0.25);
	float n1=n2+nofs(b*0.5),n0=n1+nofs(b);
	b-=1.0;//go back in time to finish old notes
	float n5=nofs(b*0.0625)+nofs(b*0.125)+nofs(b*0.25);
	float n4=n5+nofs(b*0.5),n3=n4+nofs(b);
	vec2 a0=inst2(n0,n3,72.0,time,t0,0.8,0);
	b-=1.0;
	n5=nofs(b*0.0625)+nofs(b*0.125)+nofs(b*0.25);
	n4=n5+nofs(b*0.5);
	vec2 a1=inst2(n1,n4,60.0,time,t1,0.5,0);
	vec2 a1h=inst2(n1,n4,57.0,time,t1,0.6,0);
	b-=2.0;
	n5=nofs(b*0.0625)+nofs(b*0.125)+nofs(b*0.25);
	vec2 a2=inst2(n2,n5,36.0,time,t2,0.2,0);
	//vec2 a2h=vec2(0.0);//inst2(n2,n5,53.0,time,t2,0.25,0);
	//vec2 a1hb=inst(n1+64.0,time,t1,0.0,1)*2.0;
	vec2 v=0.25*(a0+a1+a1h+a2);
	return clamp(v,-1.0,1.0);
}

// Sound (sound) —  [SIG15] Oblivion by Dave_Hoskins
// https://www.shadertoy.com/view/XtfXDN

// [SIG15] Oblivion [sound code]
// by David Hoskins.
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

// The sound includes a vocoded 'aaah' and "Tech 4-9, Jack Harper" with formants collected straight from the film.
// Speech coefficients created using Wavesurfer:
// http://sourceforge.net/projects/wavesurfer/


#define TWO_PI 			6.2831
#define MOD2 vec2(.16632,.17369)
#define MOD3 vec3(.16532,.17369,.15787)
#define PLAY_PHRASES

#define cueINCLOUDS 0.0
#define cueFLYIN 14.0
#define cueFRONTOF cueFLYIN + 10.0
#define cueTHREAT cueFRONTOF + 5.
#define cueFLYOFF cueTHREAT + 19.0

float n1 = 0.0;
float n2 = 0.0;
float fb_lp = 0.0;
float lfb_lp = 0.0;
float hp = 0.0;
float p4=1.0e-24;
vec3 drone;
float gTime;
float speed, height;

#define TAU  6.28318530718
#define NT(a, b, c) if(t > a){x = a; n = b; ty = c;}
#define P(a, b, c, d, e, f) if(t >= sec){x = sec; pit = ivec2(a, b), form = ivec4(c, d, e, f);} if(t+step >= sec){pit2 = ivec2(a, b),  form2 = ivec4(c, d, e, f);} sec+=step;


#define N(a, b) if(t > a){x = a; n = b;}

//----------------------------------------------------------------------------------------
//  1 out, 1 in ...
float hash11(float p)
{
	vec2 p2 = fract(vec2(p) * MOD2);
    p2 += dot(p2.yx, p2.xy+19.19);
	return fract(p2.x * p2.y);
}

//----------------------------------------------------------------------------------
float tract(float x, float f, float bandwidth)
{
    float ret = sin(TAU * f * x) * exp(-bandwidth * 3.14159265359 * x);
    return ret;
}

//----------------------------------------------------------------------------------
float noise11(float x)
{
    float p = floor(x);
    float f = fract(x);
    f = f*f*(3.0-2.0*f);
    return mix( hash11(p), hash11(p + 1.0), f)-.5;
}

//----------------------------------------------------------------------------------
float Fricative(float x, float f)
{
    float ret = hash11(floor(f * x)*20.0)-.5;
	return ret*3.0;
}


//----------------------------------------------------------------------------------
float noteMIDI(float n)
{
	return 440.0 * pow(2.0, (n - 69.0) / 12.0);
}

//----------------------------------------------------------------------------------
float saw( float x, float a)
{
    float f = fract( x );
	return (clamp(f/a,0.0,1.0)-clamp((f-a)/(1.0-a),0.0,1.0))*2.0-.5;
}

//----------------------------------------------------------------------------------
float sqr(float t)
{
	return step(fract(t), 0.5)-0.5;
}

//----------------------------------------------------------------------------------
float tri(float t)
{
	return (abs(fract(t)-0.5)*2.-0.5)*2.;
}

//----------------------------------------------------------------------------------
float sine(float t)
{
	return sin(t* 3.141*2.0);
}

//----------------------------------------------------------------------------------------
float softBeep(float t)
{
	float n = 0.0;
    float x = 0.0;
    float ty = 0.0;
 
    //NT(cueFRONTOF-4.0, 61., .2);
    NT(cueFRONTOF-4.0,56., .5);
    
    NT(cueFRONTOF+.7, 56., .4);
    NT(cueFRONTOF+1., 61., .5);
    
    float asr = cueFLYOFF-.9;
    NT(asr+.7, 69.0, .5);

    n = noteMIDI(n);
    
    x = t-x;
    
	float aud = 0.0;
      
    float vol = smoothstep(.0, .05, x) * smoothstep(1.0, .8, x/ty);
    aud += sine(x*n*2.0+t)*sine(x*n*.9+t)*smoothstep(0.0, .04, t)*vol*.3;
    aud = clamp(aud*.9,-1., 1.);

    return aud;
}

//----------------------------------------------------------------------------------------
float beeDoop(float t)
{
	float n = 0.0;
    float x = 0.0;
    float ty = 0.0;
    
    NT(cueTHREAT-1.0, 63.0, .14);
    NT(cueTHREAT-1.0+.14, 51.0, .55);

    NT(cueTHREAT+3.2, 63.0, .14);
    NT(cueTHREAT+3.2+.14, 51.0, .55);

    n = noteMIDI(n);
    
    x = t-x;
    
	float aud = 0.0;
    float vol = smoothstep(.0, .01, x) * smoothstep(1.0, .7, x/ty);
    aud = tri(x*n*4.0) * tri(x*n*.5) * sine(x*n*2.)*vol;
    aud += sine(x*n*2.0+t)*smoothstep(0.0, .04, t)*vol*.3;
    aud = clamp(aud*.7,-1., 1.);

    return aud;
}

 //----------------------------------------------------------------------------------------
// Speech Processing Based on a Sinusoidal Model
// For the vocal part I analylised a sample from the film and extracted
// the vocal formants, which of course turned out to be an 'aaaah!' :)
// https://archive.ll.mit.edu/publications/journal/pdf/vol01_no2/1.2.3.speechprocessing.pdf

float aaaah(float t)
{
	float n = 0.0;
    float x = 0.0;
    float ty = 0.0;
    //t=  mod(t, 2.0)+cueTHREAT;
    NT(cueTHREAT, 52., 1.1);
    NT(cueFLYOFF+2.0, 52., 3.1);
    
    n = noteMIDI(n);
    x = t-x;
    float vol= smoothstep(.0, .03, x) * smoothstep(1.0, .9, x/ty)*.5;
    float pit = smoothstep(.0, .8, x) * smoothstep(1.0, .9, x/ty);
    float formSlide = (smoothstep(.3, .0, x) + smoothstep(.8, 1., x/ty)) * 100.0;
    pit = pow(pit,.1);
    pit = (1.0-pit*.001)/n;
    
    t += noise11(x*7.+45.0)*.0008; // ...Add a bit of random flutter to humanise it.

    // Build the vocal tract with sine waves...
    x = mod(t, pit);
	float aud =	tract(x, 710.0-formSlide, 70.0) *.5 +
       			tract(x, 1000.0+formSlide, 90.0)  * .6 +
	       		tract(x, 2450.0+formSlide, 140.0) * .4;
   	    
    aud = clamp(aud * vol, -1.0, 1.0);
    return aud;
}
float tech49(float t)
{
    //t = mod(t, 7.0)+ cueTHREAT+4.5; // ...test
    float step = .013;
    float vol = .45;
    float adjust = 1.0;
    float sec = cueTHREAT+4.5;
    if (t > cueTHREAT+6.5 && t < cueTHREAT+13.5)
    {
        t-=3.0;
        vol = .7;
        step = 0.023;
        adjust = 1.18;
    }
    
    ivec4 form = ivec4(271,2104,3152,4600), form2 = form;
    ivec2 pit = ivec2(0	,0), pit2 = pit;
    float x = .0;

	// Pitch, intensity and formants for...
    // "Tech 4-9, Jack Harper"
    // Uses the output from free software called WaveSurfer:-
    // http://sourceforge.net/projects/wavesurfer/
    
    // It's still a little rough between the frames, but it's getting there.
    
    // I had to hand edit some of these bastards!...
   
    // Pitch or fricative(0) , gain, f1, f2, f3, f4
    P(0	,42,	271,	2104,	3152,	4600);
    P(0	,30,	515,	1568,	2589,	3820);
    P(0	,20,	650,	1955,	2644,	3900);
    P(154	,40	,650    ,1663,	 2644	,3900);
    P(164	,46	,557	,1663	,2540	,3532);
    P(178	,44	,576	,1641	,2465	,3399);
    P(179	,53	,604	,1677	,2439	,3368);
    P(180	,58	,610	,1751	,2352	,3272);
    P(181	,57	,594	,1805	,2327	,3211);
    P(183	,58	,573	,1847	,2267	,3195);
    P(186	,59	,554	,1594	,1999	,3120);
    P(186	,57	,534	,1611	,1981	,3097);
    P(185	,58	,512	,1762	,1902	,3205);
    P(184	,56	,429	,1848	,2489	,4087);
    P(0	,12	,350,1600,1900,3900	 );
    P(0	,40	,350,1600,1900,3900	 );
    P(0	,30	,300,1950,2800,4400	 );
    P(0	,23	,300,1950,2800,4400		 );
    P(0	,17	,300,1950,2800,4400		 );
    P(0	,0	,755	,1825	,2511	,4083	 );
    P(0	,0	,440	,1811	,2529	,4099	 );
    P(0	,17	,287	,1223	,2455	,3977	 );
    P(0	,28	,280	,1259	,2338	,3707	 );
    P(0	,32	,281	,1288	,2345	,3719	 );
    P(0	,34	,281, 1294, 2361,4166	 );
    P(0	,35	,281, 1294, 2361,4166	 );
    P(0	,45	,281, 1294, 2361,4166	 );
    P(207	,42	,487	,934	,1791	,3100);
    P(214	,48	,489	,993	,1858	,3159);
    P(220	,55	,489	,1005	,1925	,3233);
    P(221	,58	,487	,1014	,1942	,3252);
    P(220	,57	,483	,1038	,1950	,3234);
    P(224	,56	,486	,1057	,1985	,3227);
    P(223	,56	,491	,1058	,1996	,3205);
    P(222	,56	,494	,1078	,2007	,3101);
    P(222	,56	,495	,1320	,2480	,3186);
    P(220	,56	,481	,1523	,2554	,3497);
    P(221	,55	,464	,1539	,2580	,3525);
    P(221	,55	,460	,1547	,2629	,3550);
    P(220	,50	,463	,1562	,2551	,3523);
    P(219	,37	,474	,1573	,2494	,3562);
    P(219	,35	,501	,1604	,2513	,3596);
    P(219	,40	,555	,1650	,2501	,3624);
    P(226	,45	,625	,1598	,2486	,3676);
    P(226	,57	,655	,1562	,2462	,3752);
    P(227	,57	,667	,1552	,2410	,3852);
    P(227	,58	,674	,1552	,2390	,3900);
    P(225	,57	,679	,1549	,2402	,3900);
    P(225	,58	,681	,1537	,2425	,3877);
    P(227	,57	,677	,1513	,2448	,3850);
    P(227	,56	,667	,1504	,2410	,3823);
    P(229	,58	,659	,1536	,2346	,3766);
    P(229	,58	,640	,1604	,2318	,3611);
    P(231	,57	,589	,1791	,2333	,3433);
    P(229	,55	,518	,1852	,2396	,4156);
    P(229	,57	,468	,1907	,2497	,4151);
    P(227	,56	,440	,1973	,2564	,4113);
    P(221	,54	,423	,1970	,2576	,4053);
    P(178	,54	,400	,1857	,2517	,4033);
    P(205	,44	,425	,1690	,2231	,3986);
    P(175	,32	,418	,1566	,2124	,3959);
    P(172	,38	,384	,1569	,2307	,3983);
    P(165	,47	,455	,1783	,2630	,3942);
    P(0,    0, 0, 0, 0, 0);
    P(0,    0, 0, 0, 0, 0);
    P(0,    0, 0, 0, 0, 0);
    P(0,    0, 0, 0, 0, 0);

    P(0,    0, 0, 0, 0, 0);
    P(0,    20,480	,1840	,2697	,3859);
    P(177,  40,	174,1914,3509,3900);
    P(0	,   34,	174,1914,3509,3900);
    P(0	,	25,	174,	1914,	2609,3900);
    P(0	,	 10	,405	,1843	,2603	,3851);
    P(177	,46	,445	,1807	,2487	,2996);
    P(200	,47	,472	,1780	,2465	,3037);
    P(219	,48	,509	,1755	,2454	,3096);
    P(227	,54	,614	,1746	,2435	,3143);
    P(227	,56	,658	,1747	,2421	,3163);
    P(220	,53	,661	,1747	,2409	,3153);
    P(222	,53	,662	,1732	,2365	,3132);
    P(220	,57	,662	,1730	,2426	,3162);
    P(219	,59	,659	,1739	,2506	,3271);
    P(217	,59	,652	,1732	,2440	,3288);
    P(216	,58	,635	,1728	,2347	,3236);
    P(215	,57	,609	,1748	,2277	,3221);
    P(209	,57	,585	,1798	,2202	,3301);
    P(205	,57	,547	,1860	,2126	,3292);
    P(200	,56	,367	,1952	,3296	,4100);
    P(178	,44	,282	,1943	,3417	,4117);
    P(0	,03	,322	,1959	,2548	,4132	 );
    P(0	,27	,409	,1826	,2560	,4125	 );
    P(0	,0	,331,1761,2488,3921	 );
    P(0	,0	,331,1761,2488,3921	 );
    P(0	,30	,331,1761,2488,3921	 );
    P(0	,38	,331,1761,2488,3921	 );
    P(0	,40	,331,1761,2488,3921	 );
    P(189	,35	,600	,1300	,2020	,3912);
    P(193	,44	,621	,1290	,2070	,3972);
    P(201	,50	,636	,1203	,2070	,4011);
    P(208	,53	,643	,1097	,2004	,4119);
    P(217	,54	,644	,1084	,1987	,4227);
    P(220	,55	,642	,1095	,2109	,4224);
    P(217	,57	,642	,1115	,2067	,4193);
    P(215	,54	,643	,1120	,1923	,4078);
    P(214	,54	,647	,1138	,1842	,3808);
    P(216	,56	,650	,1169	,1801	,3762);
    P(218	,56	,652	,1237	,1790	,3768);
    P(220	,55	,648	,1275	,1784	,3763);
    P(223	,53	,621	,1256	,1763	,3629);
    P(225	,50	,533	,1123	,1636	,3516);
    P(222	,52	,386	,1006	,1563	,3361);
    P(192	,48	,255	,1203	,2528	,3211);
    P(183	,35	,304	,1151	,2209	,3086);
    P(156	,29	,303	,841	,1900	,2698);
    P(154	,7	,260	,895	,1884	,2635);
    P(168	,8	,217	,957	,2642	,3825);
    P(0  	,38	,254	,980	,1873	,2688);
    P(148	,28	,338	,1142	,1659	,3780);
    P(143	,26	,436	,1171	,1594	,3789);
    P(179	,25	,464	,1191	,1585	,3822);
    P(162	,31	,465	,1211	,1574	,3756);
    P(231	,44	,462	,1235	,1567	,3678);
    P(229	,53	,461	,1252	,1557	,3670);
    P(229	,53	,461	,1252	,1557	,3670);
    P(226	,52	,459	,1273	,1548	,3658);
    P(224	,57	,468	,1300	,1597	,3665);
    P(222	,56	,492	,1317	,1605	,3715);
    P(217	,52	,492	,1342	,1587	,3734);
    P(209	,49	,444	,1424	,1612	,3770);
    P(198	,46	,399	,1463	,1755	,2960);
    P(179	,38	,303	,1423	,1831	,2912);
    P(0,    0, 0, 0, 0, 0);
    P(0,    0, 0, 0, 0, 0);

    x = t - x;
    float sm = clamp(x/step, 0.0,1.0);

  
    float aud = 0.0;
    float fric = 0.0;
    float intensity = pow(8.0, float(pit.y)/19.0) * .001;
    float intensity2 = pow(8.0, float(pit2.y)/19.0) * .001;
    
    intensity = mix(intensity, intensity2, sm);
    vec4 formants  = mix(vec4(form), vec4(form2), sm);
    
    if (pit.x > 0)
    {

  		float p = 1.0/(float(pit.x)*adjust);
        if (pit2.x > 0)
        {
	       	float p2 = 1.0/(float(pit2.x)*adjust);
            p = max(mix(p, p2, sm), 0.);
        }

        float a = mod(x, p); 
		aud =	tract(a, formants.x, 70.0) +
      			tract(a, formants.y, 90.0)  * .7 +
	       		tract(a, formants.z, 140.0) * .6 + 
        		tract(a, formants.w, 210.0) * .4;
        aud *= intensity;
    }
    else
    {
         vec4 formants  = vec4(form);
         fric += Fricative(t, formants.x) +
      			Fricative(t, formants.y) +
       			Fricative(t, formants.z)*1.8;
        aud = fric*intensity*.25;
    }
  

	aud = clamp(aud*vol, -1.0, 1.0);
    
    return aud;

}


//----------------------------------------------------------------------------------------
float beepPong(float t)
{
	float n = 0.0, x = 0.0, ty = 0.0;
    float asr = cueFLYOFF-4.;
    //t = mod(t, 3.0) + cueFLYOFF-3.5;
    NT(asr, 93.0, .2);
    NT(asr+0.1, 69.0, .3);
    NT(asr+.3, 81.0, .55);
    n = noteMIDI(n);
    x = t-x;
	float aud = 0.0;
    asr = min((t-asr)*18.0, 1.0);
    float vol = smoothstep(.0, .002, x) * smoothstep(1.0, .1, x/ty)*asr;
    aud = sine(x*n)*vol;
   	aud += sine(x*n*.99+t)*smoothstep(0.0, .04, t)*vol*.3;
    aud = clamp(aud*.3,-1., 1.);

    return aud;//(1.5 * aud - 0.5 * aud * aud * aud);
}

//----------------------------------------------------------------------------------------
float boom(float t)
{
	float n = 0.0, x = 0.0, ty = 0.0;
    //t = mod(t, 2.)+cueFLYOFF-.9;
    float asr = cueFLYOFF-.9;

    NT(asr+0.3, 33.0, .1);
    NT(asr+.6, 29.0, .1);
    NT(asr+.9, 26.0, .2);
    
    n = noteMIDI(n);
    x = t-x;
    
	float aud = 0.0;
    float vol = smoothstep(.0, .002, x) * smoothstep(1.0, .9, x/ty);
    n-=x*50.0;
    aud = tri(x*n);
    aud += tri(x*n*2.0);
    aud = clamp(aud*vol,-1., 1.);

    return (1.5 * aud - 0.5 * aud * aud * aud)*.7;
}

//----------------------------------------------------------------------------------------
float scanner(float t)
{
    float n = noteMIDI(21.0);
     float   scannerOn = smoothstep(cueTHREAT+4.0,cueTHREAT+4.2, t)* smoothstep(cueTHREAT+11.5,cueTHREAT+11.2, t);
    float r = sin(t*2.) * scannerOn;
    float vol= (smoothstep(0.4, 0.0,abs(r-.4))+.2) * scannerOn;
	float b = abs(sin(t*8.0))*.3;
    
    float aud = (saw(t*n*2.0, 1.)+saw(t*n*2.1, 1.))*.2;
    aud += saw(t*n*4.0, .6+b)+saw(t*n*4.01, .6+b);
    aud = clamp(aud*vol,-1., 1.);
    return aud;//(1.5 * aud - 0.5 * aud * aud * aud);
}

//----------------------------------------------------------------------------------------
vec2 deepFuzz(float t)
{
	float n = 0.0;
    float x = 0.0;
    float ty = 0.0;
    
    NT(cueFRONTOF-2.2, 28., .5);
    NT(cueFRONTOF-1.2, 28., .5);

    NT(cueTHREAT+1.2, 28., .5);
    NT(cueTHREAT+2.2, 28., .5);
    
    NT(cueTHREAT+10.+1.2, 28., .5);
    NT(cueTHREAT+10.+2.2, 28., 1.5);
   
    n = noteMIDI(n);
    x = t-x;
    
    float vol= smoothstep(.0, .0, x) * smoothstep(1.0, .98, x/ty);
    
    vol *= smoothstep(cueFRONTOF, cueFRONTOF+.2, t)*.9+.1;
    float pit = 1.0+sqr(t*250.0)*.02;
    vec2 aud = vec2(0.0);
    aud.x += saw(t*n*pit, 1.)+saw(t*n*1.01*pit, 1.)+saw(t*n*4.0*pit, 1.);
    aud.y += saw(t*n*pit, 1.)+saw(t*n*.99*pit, 1.)+saw(t*n*4.0*pit, 1.);
    aud = clamp(aud * vol*.5, -1.0, 1.0);
    return aud;//(1.5 * aud - 0.5 * aud * aud * aud);
}
    
//----------------------------------------------------------------------------------------
vec3 dronePath(float ti)
{
    vec3 p = vec3(-2030, 340, 2200.0);
    p = mix(p, vec3(-2030, 340, 2000.0),		smoothstep(cueINCLOUDS, cueFLYIN-.5, ti));
    p = mix(p, vec3(-30.0, 18.0, 300.0),		smoothstep(cueFLYIN, cueFLYIN+4.0, ti));
    p = mix(p, vec3(-35.0, 25.0, 10.0), 		smoothstep(cueFLYIN+4.0,cueFLYIN+8.0, ti));
    p = mix(p, vec3(30.0, 0.0, 15.0), 			smoothstep(cueFRONTOF+.5,cueFRONTOF+2.5, ti)); //../ Move to front of cam.
    p = mix(p, vec3(0.0, 8.0, .0), 				smoothstep(cueTHREAT, cueTHREAT+.5, ti)); 	// ...Threaten
    p = mix(p, vec3(0.0, 8.0, -4.0), 			smoothstep(cueTHREAT+2.0, cueTHREAT+2.3, ti)); 	// ...Threaten
    p = mix(p, vec3(0.0, 8., -12.0), 			smoothstep(cueTHREAT+3.0, cueTHREAT+3.3, ti)); 	// ...Threaten
    p = mix(p, vec3(0.0, 110.0, 0.0), 			smoothstep(cueFLYOFF,cueFLYOFF+1.5, ti)); // ...Fly off
    p = mix(p, vec3(4000.0, 110.0, -4000.0), 	smoothstep(cueFLYOFF+2.6,cueFLYOFF+10.0, ti)); 
    return p; 
}

//----------------------------------------------------------------------------------------
vec3 cameraAni(float ti)
{
    vec3 p;
    p = mix(drone-vec3(0.0,0.0, 10.0), drone-vec3(0.0,0.0, 20.0), smoothstep(cueINCLOUDS,cueINCLOUDS+2.0, ti));
    p = mix(p, drone-vec3(17.0,-14.0, 35.0), smoothstep(cueINCLOUDS+2.0,cueFLYIN-3.0, ti));
    p = mix(p, vec3(0.0, 0.0, -28.0), step(cueFLYIN, ti));
	p = vec3(p.xy, mix(p.z, -40.0, smoothstep(cueTHREAT,cueTHREAT+4.0, ti)));
    return p;
}


//----------------------------------------------------------------------------------------
float engines(float ti)
{
	float  t = ti+ sin(height*.7)*.3+1.0;
	float t1 = texture(iChannel1, vec2(t*(2.44),t*11.33), -4.0).x *  .5-.25;
	t1 += texture(iChannel1, vec2(t*(2.44),t*1.33), -99.0).x -.5;
    float t2 = texture(iChannel0, vec2(ti*13.81,ti*4.73), -4.0).x * .5-.25;
    t2 += texture(iChannel0, vec2(ti*13.81,ti*14.54), -99.0).x * .08-.04;
	float f = mix(t1, t2, speed);
	f+= clamp((texture(iChannel1, vec2(ti*5.44,t*12.33), -99.0).x*2.0-1.) *(smoothstep(cueFLYOFF+.0, cueFLYOFF+2.8, ti))*4.0, -1.,1.);
    f += (texture(iChannel0, vec2(ti*2.4413,ti*4.1375), -3.).x*2.0-1.);
	return clamp(f*(speed+.5), -1.0, 1.0);
}

//----------------------------------------------------------------------------------------
vec2 droneGunAni(float ti)
{
    vec2 a;
   	float mov;
    mov = smoothstep(cueFLYOFF-1., cueFLYOFF-3.0, ti);
    mov = mov*3.1-1.4;
    a.x = (sin(mov)+1.0)*1.5;
    a.y = smoothstep(.3,.7,sin(mov))*3.0;
    return a;
}

//----------------------------------------------------------------------------------------
vec2 guns(float ti)
{
	vec2 a;
    vec2 ga = droneGunAni(ti);
    a = texture(iChannel0, vec2(ga.x*14.4,ga.x*21.33), -99.0).xy-.5;
    a -= texture(iChannel0, vec2(ga.x*14.4,ga.x*21.33), -3.0).xy-.5;
    a *= .3;
    a += texture(iChannel1, vec2(ga.y*1.44,ga.y*1.03), -99.0).xy*2.0-1.;
    return a*.5;
}

//----------------------------------------------------------------------------------------
vec2 allsounds(float t)
{
    vec2 audio = vec2(0);
	audio = vec2(beeDoop(t));
    audio += vec2(aaaah(t));
    audio += vec2(deepFuzz(t));
    audio += vec2(beepPong(t));
    audio += engines(t);
    audio += vec2(scanner(t));
    audio = clamp(audio, -1.0, 1.0);
    audio *= smoothstep(cueFLYOFF-.3, cueFLYOFF-.8, t)+smoothstep(cueFLYOFF, cueFLYOFF+.3, t);
    audio += vec2(boom(t));
    audio += vec2(softBeep(t));
    audio += guns(t);
    audio *= smoothstep(cueFLYIN, cueFLYIN-.2, t)  + smoothstep(cueFLYIN, cueFLYIN+.2, t);
    audio += vec2(tech49(t));
    return audio*.8;
}

//----------------------------------------------------------------------------------------
vec2 mainSound( in int samp,float time)
{
	 float ti = mod(time, 57.);
     // Tests cues...
//   float ti = mod(time, 45.0);
   //float ti = mod(time, 6.5)+cueFRONTOF;
   //float ti = mod(time, 15.)+cueTHREAT+1.0;
   //float ti = mod(time, 8.5)+cueFLYOFF-2.5;
    
    drone = dronePath(ti);
    vec3 camPos = cameraAni(ti);
    float l = max(length(drone-camPos)-20.0, 1.);
    speed = clamp(length(drone -dronePath(ti-.08)),0.0, 1.1);
    height = drone.y;
    float disAtten = clamp(7330.0/(l*l), 0.0, 1.0);

   	vec2 audio = allsounds(ti)*disAtten;
    // Echo, echo echo...
	audio += allsounds(ti-.3)*.12 * vec2(1.0, .3)*disAtten;
    audio += allsounds(ti-.6)*.06 * vec2(.3, 1.)*disAtten;
    audio += allsounds(ti-.9)*.03 * vec2(1., .3)*disAtten;
    //audio += allsounds(ti-.12)*.025 * vec2(.3, 1.)*disAtten;.// ...too much!
    
    return audio * smoothstep(0.0, 2., ti) * smoothstep(57.0, 55., time);
}


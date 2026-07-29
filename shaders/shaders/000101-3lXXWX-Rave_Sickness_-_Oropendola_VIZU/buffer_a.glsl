// Buffer A (buffer) — Rave Sickness - Oropendola VIZU by ttoinou
// https://www.shadertoy.com/view/3lXXWX

// https://www.shadertoy.com/view/XtVGDz

#define buffer iChannel0
#define sound  iChannel1
#define soundRes iChannelResolution[1]
#define step 1.0/iResolution.y
#define inputSound iChannel0
#define fftWidth 		1.0		
#define fftMinBass 		0.00196 	// 1.0/512.0

#define render 0

// fft Options
#if render

#define fftSmoothTime   0.08
#define fftSmooth 		1.3			// smoothness coeff
#define fftPreamp		0.65		// pre amp before dynamic
#define fftBoost  		0.14		// dynamic amp
#define fftAmp			0.65		    // final gain
#define noiseLevel      0.1
#define fftTrebles		2.5
#define fftBass			1.0

#else

#define fftSmoothTime   .7
#define fftSmooth 		1.3			// smoothness coeff
#define fftPreamp		0.65		// pre amp before dynamic
#define fftBoost  		0.14		// dynamic amp
#define fftAmp			0.6			// final gain
#define noiseLevel      0.05
#define fftTrebles		3.0
#define fftBass			1.6

#endif

#define fftRadiusR		3.0/512.0
#define fftRadiusG		fftRadiusR*3.0
#define fftRadiusB		fftRadiusR*3.0*3.0
#define fftSamplesR 	4 // number of iteration for fft sampling, increases quality !
#define fftSamplesG 	fftSamplesR*4
#define fftSamplesB 	fftSamplesR*4*4
#define fftGBGain       1.1

#define to01(x) clamp(x,0.0,1.0)

float remapIntensity(float f, float i){
  //return i;
  // noise level
  i = to01( (i - noiseLevel) / (1.0 - noiseLevel) );
  float k = f-1.0;
  i *= ( fftTrebles - fftBass*k*k ) * fftPreamp;
  // more dynamic
  i *= (i+fftBoost);
    
  return i*fftAmp;
  // limiter, kills dynamic when too loud
  //return 1.0 - 1.0 / ( i*4.0 + 1.0 );
}

float remapFreq(float freq){
 // linear scale
 //return clamp(freq,fftMinBass,1.0);
 // log scale
 return clamp(to01(- log(1.0-freq/1.65 + fftMinBass)),fftMinBass,1.0);
}

float fftR(float f){
    float sum = 0.0;
    float val = 0.0;
    float coeff = 0.0;
    float k = 0.0;
    for( int i = 0; i < fftSamplesR ; i++ ){
        k = float(i)/float(fftSamplesR-1)-0.5;
        coeff = exp(-k*k/(fftSmooth*fftSmooth)*2.0);
		val += texture(sound, vec2( remapFreq(f + k * fftRadiusR)*fftWidth, 0.0) ).r * coeff;
        sum += coeff;
    }
    return remapIntensity(f,val/sum);
}

float fftG(float f){
    float sum = 0.0;
    float val = 0.0;
    float coeff = 0.0;
    float k = 0.0;
    for( int i = 0; i < fftSamplesG ; i++ ){
        k = float(i)/float(fftSamplesG-1)-0.5;
        coeff = exp(-k*k/(fftSmooth*fftSmooth)*2.0);
		val += texture(sound, vec2( remapFreq(f + k * fftRadiusG)*fftWidth, 0.0) ).r * coeff;
        sum += coeff;
    }
    return remapIntensity(f,val/sum)*fftGBGain;
}

float fftB(float f){
    float sum = 0.0;
    float val = 0.0;
    float coeff = 0.0;
    float k = 0.0;
    for( int i = 0; i < fftSamplesB ; i++ ){
        k = float(i)/float(fftSamplesB-1)-0.5;
        coeff = exp(-k*k/(fftSmooth*fftSmooth)*2.0);
		val += texture(sound, vec2( remapFreq(f + k * fftRadiusB)*fftWidth, 0.0) ).r * coeff;
        sum += coeff;
    }
    return remapIntensity(f,val/sum)*fftGBGain*fftGBGain;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord.xy / iResolution.xy;

   	// black by default
    fragColor = vec4(0.0,0.0,0.0,1.0);

     // iFrame == 0 => Reset
    if( iFrame != 0 ){
        // store current fft
        if( fragCoord.y <= 1.0 ){
            
            float freq = uv.x;
            float i1,i2,i3;

            i1 = fftR(freq);
            i2 = fftG(freq);
            i3 = fftB(freq);
	
            fragColor.rgb = vec3(i1,i2,i3);
            fragColor.rgb = mix(texture(buffer,vec2(uv.x,uv.y - step)).rgb,fragColor.rgb,fftSmoothTime);

            #if render
            //vec3 mean = mix(fragColor.rgb,texture(buffer,vec2(uv.x,uv.y - step)).rgb,fftSmoothTime);
            
            /*if( length(mean) > length(fragColor.rgb) ){
               fragColor.rgb = mean.rgb; 
            }
            */
            //fragColor.rgb = max(fragColor.rgb,mean.rgb);
            #endif
            //fragColor.rgb = vec3(0.0);
            fragColor.a = texture(sound,vec2(freq,1.0)).x;
            
        // store previous fft
        } else if( fragCoord.y < iResolution.y - 1.0 ) {
            fragColor=texture(buffer,vec2(uv.x,uv.y - step));
        }
    }
}
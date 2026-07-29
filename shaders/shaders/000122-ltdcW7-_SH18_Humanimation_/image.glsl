// Image (image) — [SH18]  Humanimation  by pellicus
// https://www.shadertoy.com/view/ltdcW7

// my SH18 Entry:  
// inspired by this ref https://www.youtube.com/watch?v=kT-I26uFv9M
// The idea is: 
// what ever you draw .. if it's animated like a human... becomes a human!
// i've tons of ideas to try and for sure could be an interesting starting
// point to make some demoscene stuff :D. at least for me.
//
// Animation: 
// 	Samba Dance fbx from www.mixamo.com 
// 	
// Music:
//	BarretoVSLujan Feat. Rozalla E Nikki - Everybody Free Samba (Edih Bueno Mega Mush! Work)
//
// bufA : playback and interpolation of the animation points (pin)
// bufB : modeling and rendering and very simple lighting of the scene
// Image: compositing with some little fx activated by camera change

// compositing: normal, littlebloom, littleglow, radialblur

vec3 pins(int x) { 	return texelFetch(iChannel1,ivec2(x,0),0).xyz; }
vec3 pins(int x,int to) { 	return texelFetch(iChannel1,ivec2(x,to),0).xyz; }


//	Full Scene Radial Blur by Shane:
//	https://www.shadertoy.com/view/XsKGRW
// Radial blur samples. More is always better, but there's frame rate to consider.
const float SAMPLES = 12.; 
// 2x1 hash. Used to jitter the samples.
float hash( vec2 p ){ return fract(sin(dot(p, vec2(41, 289)))*45758.5453); }
// fixed for me.
vec3 lOff()
{    
    return normalize(vec3(-.50,0,1));
}
    vec4 RadialBlur(vec2 uv)
    {
    // Radial blur factors.
    //
    
    // Falloff, as we radiate outwards.
    float decay = 0.97; 
    // Controls the sample density, which in turn, controls the sample spread.
    float density = 0.5; 
    // Sample weight. Decays as we radiate outwards.
    float weight = 0.1; 
    
    // Light offset. Kind of fake. See above.
    vec3 l = lOff();
    
    // Offset texture position (uv - .5), offset again by the fake light movement.
    // It's used to set the blur direction (a direction vector of sorts), and is used 
    // later to center the spotlight.
    //
    // The range is centered on zero, which allows the accumulation to spread out in
    // all directions. Ie; It's radial.
    vec2 tuv =  uv - .5 - l.xy*.45;
    
    // Dividing the direction vector above by the sample number and a density factor
    // which controls how far the blur spreads out. Higher density means a greater 
    // blur radius.
    vec2 dTuv = tuv*density/SAMPLES;
    
    // Grabbing a portion of the initial texture sample. Higher numbers will make the
    // scene a little clearer, but I'm going for a bit of abstraction.
    vec4 col = texture(iChannel0, uv.xy)*0.25;
    
    // Jittering, to get rid of banding. Vitally important when accumulating discontinuous 
    // samples, especially when only a few layers are being used.
    uv += dTuv*(hash(uv.xy + fract(iTime))*2. - 1.);
    
    // The radial blur loop. Take a texture sample, move a little in the direction of
    // the radial direction vector (dTuv) then take another, slightly less weighted,
    // sample, add it to the total, then repeat the process until done.
    for(float i=0.; i < SAMPLES; i++){
    
        uv -= dTuv;
        col += texture(iChannel0, uv) * weight;
        weight *= decay;
        
    }
    
    // Multiplying the final color with a spotlight centered on the focal point of the radial
    // blur. It's a nice finishing touch... that Passion came up with. If it's a good idea,
    // it didn't come from me. :)
    col *= (1. - dot(tuv, tuv)*.75);
    
    // Smoothstepping the final color, just to bring it out a bit, then applying some 
    // loose gamma correction.
    return sqrt(smoothstep(0., 1., col));
    }



//------------------------------------------------
#define quickblur_points 14
vec2 Circle(float Start, float Points, float Point) 
{
	float Rad = (3.141592 * 2.0 * (1.0 / Points)) * (Point + Start);
	return vec2(sin(Rad), cos(Rad));
}
vec3 quickblur_sample(const vec2 uv,const float i,const vec2 scale)
{

    float ang = (3.141592 * 2.0 * (1.0 / float(quickblur_points)) )*( i +(2./float(quickblur_points)) );
	return texture(iChannel0, uv.xy+scale*vec2(sin(ang), cos(ang))).rgb;
}
vec3 quickblur( const vec2 uv )
{
    vec2 pix = 1.0 / iChannelResolution[0].xy;
    float Start = 2.0 / 14.0;
	vec2 Scale = 0.66 * 4.0 * 2.0 * pix.xy;
    const float W = 1.0 / 15.0;
    vec3 smp = texture(iChannel0, uv).rgb*W;
    for(int i =0;i<quickblur_points;i++)
        smp +=  quickblur_sample(uv,float(i),Scale)*W;
   return smp;
}


vec4  LittleBloom( in vec2 uv)
{
	vec4 src = texture(iChannel0, uv);
    return vec4( 1. - (1. - src.xyz)*(1. - quickblur(uv)),1.);
}
//-------------------------------------------------------------------------

// Little Glow , code stolen :D  from : 
//https://www.shadertoy.com/view/lsXGWn by Seven

//const float blurSize = 1.0/512.0;
//const float intensity = 0.35;
vec4 LittleGlow(  const vec2 texcoord, const float blurSize,const float intensity )
{
   vec4 sum = vec4(0);
   int j;
   int i;
   //thank you! http://www.gamerendering.com/2008/10/11/gaussian-blur-filter-shader/ for the 
   //blur tutorial
   // blur in y (vertical)
   // take nine samples, with the distance blurSize between them
   sum += texture(iChannel0, vec2(texcoord.x - 4.0*blurSize, texcoord.y)) * 0.05;
   sum += texture(iChannel0, vec2(texcoord.x - 3.0*blurSize, texcoord.y)) * 0.09;
   sum += texture(iChannel0, vec2(texcoord.x - 2.0*blurSize, texcoord.y)) * 0.12;
   sum += texture(iChannel0, vec2(texcoord.x - blurSize, texcoord.y)) * 0.15;
   sum += texture(iChannel0, vec2(texcoord.x, texcoord.y)) * 0.16;
   sum += texture(iChannel0, vec2(texcoord.x + blurSize, texcoord.y)) * 0.15;
   sum += texture(iChannel0, vec2(texcoord.x + 2.0*blurSize, texcoord.y)) * 0.12;
   sum += texture(iChannel0, vec2(texcoord.x + 3.0*blurSize, texcoord.y)) * 0.09;
   sum += texture(iChannel0, vec2(texcoord.x + 4.0*blurSize, texcoord.y)) * 0.05;
	
	// blur in y (vertical)
   // take nine samples, with the distance blurSize between them
   sum += texture(iChannel0, vec2(texcoord.x, texcoord.y - 4.0*blurSize)) * 0.05;
   sum += texture(iChannel0, vec2(texcoord.x, texcoord.y - 3.0*blurSize)) * 0.09;
   sum += texture(iChannel0, vec2(texcoord.x, texcoord.y - 2.0*blurSize)) * 0.12;
   sum += texture(iChannel0, vec2(texcoord.x, texcoord.y - blurSize)) * 0.15;
   sum += texture(iChannel0, vec2(texcoord.x, texcoord.y)) * 0.16;
   sum += texture(iChannel0, vec2(texcoord.x, texcoord.y + blurSize)) * 0.15;
   sum += texture(iChannel0, vec2(texcoord.x, texcoord.y + 2.0*blurSize)) * 0.12;
   sum += texture(iChannel0, vec2(texcoord.x, texcoord.y + 3.0*blurSize)) * 0.09;
   sum += texture(iChannel0, vec2(texcoord.x, texcoord.y + 4.0*blurSize)) * 0.05;

   //increase blur with intensity!
   return sum*intensity + texture(iChannel0,texcoord);
}

//-----------------------------------------------------------------------------------

void mainImage( out vec4 fragColor, in vec2 fragCoord ){
    
  
    vec2 uv = fragCoord.xy / iResolution.xy;
       float t = iTime*0.512;
	int  scene=int(floor(t*0.25));
   
    int camchg=scene%5;
    
    fragColor = texture(iChannel0,uv);
    if(camchg==4)
	    fragColor = RadialBlur(uv)*1.8;
	if(camchg==0)
        fragColor = LittleBloom(uv);
	if(camchg==3)
        fragColor = LittleGlow(uv,1.0/300.,1.2);

}


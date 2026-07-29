// Image (image) — Shoreline by glkt
// https://www.shadertoy.com/view/lsBBRR

// The moment one gives close attention to any thing,
// even a blade of grass,
// it becomes a mysterious, awesome, indescribably magnificent world in itself.

//-------------------------------------

// visual parameters ------------------
const bool reverse = true; // reverse vertically 
const int waveNumber = 6;
const float speed = .1;
const float foamDensity = 0.;
const float waveCurve = 4.;
vec3 sandColor = vec3(1.,.95,.8);
const vec3 seaColor = vec3(.0,.7,.85);
const vec3 deepSeaColor = vec3(0.,.2,.3);
//-------------------------------------

const float pi = 3.14159265359;

float hash1( float p ) {
    float h = dot(vec2(p),vec2(127.1,311.7));	
    return fract(sin(h)*43758.5453123);
}
float hash2( vec2 p ) {
    float h = dot(p,vec2(127.1,311.7));	
    return fract(sin(h)*43758.5453123);
}

// basic 1 dimensionnal noise
float noise1d( float p ) {
    float i = floor( p );
    float f = fract( p );
    float u = f*f*f*(f*(f*6.0-15.0)+10.0);
    float v = mix( hash1(i), hash1(i + 1.), u);              
    return v;
}

// layered noise from texture
float noiseLayer(vec2 p, float ti){
    float e =0.;
    for(float j=1.; j<9.; j++){
        e += texture(iChannel0, p * float(j) + vec2(ti*7.89541) + vec2(j*159.78) ).r / (j/2.);
    }
    e /= 8.5;
    return e;
}

// another layered noise from texture: less octaves, more granularity
vec3 sandNoiser(vec2 p, float ti){
    vec3 e = vec3(0.);
    for(int j=1; j<3; j++){
        e += texture(iChannel1, p * (float(j)*1.79) + vec2(ti*7.89541) ).rgb ;
    }
    e /= 3.;
    return e;
}

// get global curve of each wave
float getWaveNoise(float ti, float wA, vec2 uv){
    float wN = hash1(ti)/3. + noise1d( (uv.x+ti)*waveCurve) * (max(0.,wA*1.5-.3));
    return wN;
}

// get height of each wave
float getWaveOffset(float wN, float t, vec2 uv){
	 float offset = (uv.y + sin( t *(2.*pi)) /2.2 - 0.3 ) + wN;
    	return offset;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
	vec2 uv = fragCoord.xy / iResolution.xy;
    uv.y = mix( 1.-uv.y,uv.y, float(reverse)); 
    float t = iTime * speed + 12.2;
    
    // sand color
    vec3 sandNoise = sandNoiser(uv,1.); // sand noise
    sandColor = mix(sandColor, vec3(.9,.7,.5), max(0.,uv.y*-2.+2.) ); // vertical gradient
    sandNoise *= vec3(1.,0.8,.5); // colorize sand noise
    sandNoise = sandNoise/2.+.5; // lower contrast of noise
    sandColor *= .3+sandNoise; // add noise
    float sandDots = clamp(sandNoise.r*5.-1.9,0.,1.); // get small dots from noise
    sandColor *= sandDots; // add dots
    vec4 col = vec4(sandColor,0.);
    
    // prepare wet sand color
    vec3 wetSand = sandColor * vec3(.7,.6,.4);
    
    float lastwA = 10.;// store last wave age
        
    // for each wave
    for(int i =0; i<waveNumber; i++){
        
        float ti = floor(t-.25)+float(i); // get wave "id"
        float wA = fract(t-.25); // wave "age" (to know which wave to draw on top and fade away effects)    
      
        float wN = getWaveNoise(ti,wA,uv); // wave global curve
        float offset = getWaveOffset(wN,t,uv); // wave vertical position        
        vec2 pos = vec2( uv.x, -offset/ (0.2+wA*20.)*2. ); // pos in "wave" space        
        float foam = noiseLayer( pos , ti); // get foam density        
        offset -= foam/10.; // modify wave front by foam
        offset -= noiseLayer(uv/10.,0.)/5.; // add global noise for turbulence effect at wave front
        
        // the same as above, but with static time : when wave is at maximal height
        float shiftTi = floor(t-.25)+float(i);
        float maxWaveNoise = getWaveNoise(ti,.5,uv);
        float maxOffset = getWaveOffset(maxWaveNoise,ti+.5,uv);
        vec2 maxPos = vec2( uv.x, -maxOffset/ (0.2+.5*20.)*2. ); 
        float maxFoam = noiseLayer( maxPos, ti);
        maxOffset -= maxFoam/10.;
        maxOffset -= noiseLayer(uv/10.,0.)/5.;
        
        
        if( offset < 0.){ // if in the wave area            
            if (wA < lastwA){ // if is a newer wave, draw on top                

                // get normal from foam
                vec3 n = vec3(	foam - noiseLayer( pos+vec2(0.001,0.) ,ti),
                              	foam - noiseLayer( pos+vec2( 0.,0.001) ,ti),
                              	0.5);
                
                // make foam weaker with time, and stronger near wave front
                foam = (foam+ .8 -wA*wA + offset*offset*.5 +  clamp(0.,1.,(offset+.2)) );

                // fake lighting
                float l = dot(n, vec3(1.,1.,1.) );                
                
                // colorize waves. Fade away with time to simulate tranparency of shallow water
                col.rgb = mix( sandColor , seaColor, clamp(1.5-wA*3.,0.02,1.) );
                  
                // darken sea color away from wave front (= color gradient)
                col.rgb = mix(col.rgb, deepSeaColor, -offset);
                
                // make the white, dense, foam at wave front
                float denseFoam = clamp(foam*20.-20.+foamDensity,0.,1.)*.8;
                col.rgb = mix(col.rgb, vec3(l)*1.5, denseFoam );
                
                // thin white line at wave front
                col.rgb += max(0.,floor(offset+1.004)*n.r*10.); 
                
                // fake water specular (little white dots)
                col.rgb += max(0., dot(n, vec3(1.,.3,.95))*10.-5.); 
                
                // darken water with foam, to give a bit of texture to the water
                col.rgb *= foam*foam*(1.-wA)+wA*1.2;
                
                // change alpha value to remember this pixel is a wave
                col.a = 1.;
            }
            
            lastwA = wA;
        }else{            
            // sand wetness
            if( col.a == 0. && wA>.5){
              float dryNess = 50. * (1.-wA);
              col.rgb = mix(col.rgb, wetSand, clamp((dryNess-2.5-maxOffset*dryNess*2.),0.,1.) * (1.-wA) );
            }
        }
        t += 1./float(waveNumber);
	}        
    fragColor = col;
}

// One's destination is never a place,
// but rather a new way of looking at things.
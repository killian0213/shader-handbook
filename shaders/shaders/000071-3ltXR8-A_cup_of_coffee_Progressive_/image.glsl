// Image (image) — A cup of coffee (Progressive) by PixelPhil
// https://www.shadertoy.com/view/3ltXR8

//
// A cup of coffee by Philippe Desgranges
// Email: Philippe.desgranges@gmail.com
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
//

// Music: A cup of coffee - DJ Okawari

// For this shader, I started with music as an inspiration. I wanted to present a
// still life scene with as much photorealism I could cram in a shader. I started with
// a porcelain cup reusing the PBR stuff I coded for my Piranah Plant shader, then came
// the metal jug and the ashtray. Because the ashtray looked silly I tried to make it
// transparent. That's the moment I fell into the rabbit hole... It proved to be a much harder
// problem to solve and my first implementation with true refraction (quasi unlimited glass
// layer traversal) ended up compiling in over two minutes on my laptop (which is my benchmark
// for lousy performances). I ended up hacking things up and simplifying it down to 20s by
// removing everything unnecessary from the SDF. The big Aha! moment was when I realized
// that things improved dramatically when tracing opaque objects and transparent ones
// separately and compositing the result afterward. Although it feels like more work
// it compiles much faster and, to my surprise, also performs better as well.
// To reach < 10s I had to sacrifice a few instances of nice Voronoise for some ugly
// texture noise... oh well...

// I seized the opportunity of rendering a 'static' scene to implement a progressive
// rendering scheme and rely heavily on jittering for anything from soft shadows to
// anti-aliasing or glossy reflexions.

// The meat of the code is all in buffer A. If you feel like toying, you will find there
// defines to play with.

//
// DISCLAIMER: Smoking is a bad habit that may cause cancer and many health issue
// it is neither advised nor encouraged by this shader.  ;)
//


// This buffer does only final frame compositing

#define KEN_BURNS_ZOOM

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    // Fetch the secret top ixel and determine if slideshow mode is on
    vec4 mixData = texture(iChannel0, vec2(0,0));
    bool SlideShow = (mixData.z > 0.0);
    
    float fade = 1.0;
    
    vec2 uvs = fragCoord.xy / iResolution.xy;
    
    if (SlideShow)
    {
        // For a better thumbnail the time is offset by 5s
        float time = iTime;
        if (iResolution.x <= 300.0) time -= 5.0;  
            
        // In slideshow mode determine the moment in the slide we are in
        float frameTime = time * 0.1;
        float frameRatio = 1.0 - fract(frameTime);
        
        // Add a fade to black to hide the integration under the rug
        fade  = smoothstep(0.01, 0.15, frameRatio);
        fade *= smoothstep(0.99, 0.95, frameRatio);
        
        
        // Add a Ken burns zoom for a bit of dynamism
        #ifdef KEN_BURNS_ZOOM
        float zoom = 1.0 - frameRatio * frameRatio * 0.1;
        uvs = vec2(0.5) + (uvs - vec2(0.5)) * zoom;
        #endif
    }

	// The image is read in the buffer in linear space
    // it is only encoded into gamma space before being presented
    vec4 linearImage = textureLod(iChannel1, uvs, 0.0);
    vec3 col = pow(linearImage.rgb * fade,vec3(0.4545));
    
    fragColor = vec4(col, 1.0);
}
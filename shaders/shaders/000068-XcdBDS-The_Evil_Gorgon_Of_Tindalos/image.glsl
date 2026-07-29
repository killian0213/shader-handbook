// Image (image) — The Evil Gorgon Of Tindalos by msm01
// https://www.shadertoy.com/view/XcdBDS

// The (now) usual scifi story that goes with this shader is so long it is in
// the Common Tab, after the code. :)

// Technical details :

// Shadertoy's Soundcloud integration has been broken for a long time but if you
// want, you can still open "Face Like A Needle" by Skaven252 in another tab and
// hit PLAY to enjoy this scene as it was meant to. Here's the link :
// https://soundcloud.com/skaven252/face-like-a-needle
// https://creativecommons.org/licenses/by-nc-sa/3.0/

// Since there are options to generate sound on Shadertoy, this time I tried.
// It's very, VERY basic but it does the job. :-/ Not for long, though, I hate
// repeating sounds. So I limited it to 60 seconds in the Sound Tab, you can
// extend it (...BUT WHY WOULD YOU DO THAT ?!) or cut it all (yeah that's much
// much better).

// Some context (for the laughs) :

// So here we go again with a "2D shader" or a "cardboard sandwich" in Evvvvil's
// words. As usual this spiraled out of control fast : I was just trying to make
// circles with noise in order to draw 2D craters. You know, fairly simple msm01
// stuff. Then I saw a shadertoy doing texture feedback with jitter and I wanted
// to try it. So I started with my noisy circle, added a for-loop, got a sort of
// aura-like effect with a central black noisy disk. And there, suddenly, I just
// saw something. Like a nuclear scientist peering into the main shaft of a new
// Penning trap that discovers the unexpected. So I forgot all about jitter and
// it pretty much started evolving on its own. Logically it doesn't make lots of
// sense. Artistically, perhaps a bit more... but not much !
// Anyways, as they say :

//                   "Do not stand between a glsl painter and his framebuffer !"

// And it's even truer when Halloween is closing in, haha ! Also, I hate this
// shader because I had a perfectly fine, 10X better one waiting for release but
// nooooooo, I just HAD TO start improvising on this one 2 weeks before the 31th
// of October ! As a result I missed the deadline FOR BOTH ! *slow clap*
// This pretty much sums up my life.

// This shader is, obviously, another hommage to Lovecraft, Frank Belknap Long,
// Ghostbusters, CERN, and many other things (i.e. tentacles, witchery, Another
// World, Stross, etc) with the hard-scifi twist I'm usually so fond of. I must
// say, as an atheist, I've always been a fan of Ghostbusters's realistic take
// on the paranormal, ghosts and such. I was very amused, while doing this, to
// learn how the proton packs and ghost traps work canonically in the movies or
// video games. Apparently, the streams are supposed to soak ghosts with muons!
// You know, that electron sibling that weights a LOT more. So once the ghost/
// vapor is coated with them, you activate the muon traps, which is the
// technical term for the ghost traps. They only capture muons, really, but
// since the ghost is now full of them, it's dragged inside too ! ... And there
// I'm honestly left speechless in admiration, because I didn't suspect how far
// the explanations would go ! Nice.

// Also read The Hounds of Tindalos. It's a lovecraftian tale by Frank Belknap
// Long. The text honestly feels a bit amateurish when you're into literature
// (as I am) but I appreciate it nonetheless. It has something, an atmosphere
// that really grabs your attention, and has left an impression on many, many
// readers. Also, it's very short. Available for free on Wikisource at :

// https://en.wikisource.org/wiki/Weird_Tales/Volume_30/Issue_1/The_Hounds_of_Tindalos

// Okay congrats for having read this far, I know I talk/write too much so here
// is a bonus short story (hooo, the irony !). Check it out in the Commons Tab,
// after the long 1st one ! See ya...

float traceChar( in vec2 v, float Charac, vec2 PosTxt)
{
      float colorChar = 0.0;
      v = vec2(v.x, 1.0-v.y);
      if( v.x > PosTxt.x && v.x < PosTxt.x + 1.0/16.0 )
      {
          if( v.y > PosTxt.y && v.y < PosTxt.y + 1.0/16.0 )
          {
              vec2 Disp = vec2(mod(Charac,16.0),floor(Charac / 16.0))/16.0;
              colorChar = texture(iChannel1,vec2(Disp.x + (v.x - PosTxt.x),-Disp.y - (v.y - PosTxt.y) )).x;
          };
      };
      return colorChar;
}

vec4 traceLabels(in vec2 p, int Tab, float Nb_Char, vec2 Centrage)
{
     vec4 Label = vec4(0.0);
     float Charac = 0.0;
     for(int i = 0; i<int(Nb_Char); i++)
     {
         if(Tab==0)Charac = float(  Data01[i]);
         if(Tab==1)Charac = float(  Data02[i]);
         if(Tab==2)Charac = float(  Data03[i]);
         if(Tab==2 && float(i)==(Nb_Char-3.0))Charac = (mod(iTime,1.0)>0.5)?float(  Data03[i]):32.0;
         if(Tab==3)Charac = float( Alert01[i]);
         if(Tab==4)Charac = float( Alert02[i]);
         if(Tab==5)Charac = float( Alert03[i]);
         Label += traceChar(p, Charac, vec2(0.028*mod(float(i),Nb_Char) - 0.028*(Nb_Char + 1.0)/2.0 + Centrage.x,Centrage.y));
     };
     return Label;
}

vec4 drawTunnel(in vec2 p, vec4 CS,sampler2D tex, float TimeVar)
{
     float angle = atan(p.y/p.x);
     float dist  = length(p);
     vec3  Tunnel;
     Tunnel = texture( tex,vec2( 0.0080*(1.0/dist) + 1.0*TimeVar, angle/PI)).xyz;
     Tunnel += smoothstep(0.1,0.0,dist);
     Tunnel -= smoothstep(0.0,0.9,dist);
     return vec4(clamp(Tunnel,0.0,1.0),1.0);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
     // Get Coordinates...
     vec2 p = vec2( (fragCoord.x - iResolution.x/2.0) / iResolution.y,fragCoord.y / iResolution.y - 0.5);

     TimeVar = 0.75*iTime;
     
     // Behaviour controls... Based on time stats...
     FIRE_JAWS = (fbm(vec2(    TimeVar)) > 0.50)?true:false;
     FIRE_SEAL = (fbm(vec2(0.1*TimeVar)) > 0.85)?true:false;
     FIRE_SYNC = (fbm(vec2(    TimeVar)) < 0.15)?true:false;
     FIRE_PHAS = (fbm(vec2(2.0*TimeVar)) > 0.95)?true:false;
     MAGN_FAIL = (fbm(vec2(0.1*TimeVar)) > 0.60)?true:false;
     PINB_MODE = (     mod(TimeVar,10.0) > 7.50)?true:false;

     // Saving general base for later
     vec2 last_p = p;

     // Zoom please...
     p *= 10.0;

     // The world is apparently a vector. Not even a big one... :(
     vec4 col = vec4(0.0,0.0,0.0,1.0);

     // Making the Gorgon change position constantly because it's feral and crazy !
     vec2 GorgonMotion = vec2( 0.9 - 1.8*fbm(vec2(2.0*TimeVar + 0.21)), 0.5 - 1.0*fbm(vec2(1.5*TimeVar + 5.77)));

     p += GorgonMotion;

     // Saving Gorgon base for later...
     vec2 s = p;
     vec2 k = p;

     // Setting up a color for later use...
     vec4 ColorWarp = vec4(1.0,0.8,0.5,1.0);

     // Pretty much explicit
     float angle = atan(p.y,p.x);
     
     // Calculating circles with noise that loop on itself...
     // I have exactly ZERO idea why I named these o and ooo. But let's stick with it.
     // And now that I re-read it, I keep hearing Power's astonished "oh ! Oooooh ! OOOOHHHH !"
     // when Denji tells her (so fiercely) he's gonna save her cat ! (very cute/funny scene) :D
     float o     = length(              p ) - 1.5 - 0.20*sin(8.0*angle)*fbm(vec2(4.0*angle +     TimeVar));
     float ooo   = length( r2d(TimeVar)*p ) - 1.2 + 0.25*sin(8.0*angle)*fbm(vec2(4.0*angle + 3.0*TimeVar));

     // Drawing the Gorgon's aura (while eating Gorgonzola)
     float NbIter          = 100.0;
     float ColorVariations =   0.0;
     float ColorScaling    =   0.0;
     for(float g=0.0; g<NbIter; g++)
     {
         // Making the colors scroll in the aura
         ColorVariations = sin((3.0*3.14159/NbIter)*g - 20.0*TimeVar);
         // Just a recurrent thing we can calculate just once per iteration
         ColorScaling    = 1.0-g/NbIter;
         // Calculate the color
         ColorWarp = vec4(1.0              - 0.3*ColorVariations,
                          0.8*ColorScaling - 0.5*ColorVariations,
                          0.5*ColorScaling - 0.5*ColorVariations,
                          1.0);
         // Compute the aura's cloud shape
         o   = length(r2d(TimeVar)*p) + 0.25*sin(8.0*angle)*fbm(vec2(4.0*angle + 3.0*TimeVar)) - 1.5;
         // Draw it
         col = mix(col,ColorScaling*ColorWarp,smoothstep(0.3,0.0,abs(o) - 0.01));
         // ZOOM !
         p*= 0.98;
     };

     // Reset p after all this frantic scaling
     p = s;

     vec4 ColorTube = vec4(vec3(clamp(0.1 + 0.9*smoothstep(5.1,0.0,dot(GorgonMotion,p)),0.0,1.0)),1.0);

     // When the Gorgon fires its beam, the tubes get redder obviously...
     if(FIRE_SYNC)ColorTube = vec4(1.0,0.0,0.0,1.0);

     // We're going to draw the infrastructure within the main chamber so...
     // First we cancel Gorgon's erratic motion.
     p -= GorgonMotion;
     // GorgonMotion... Purple Motion's lesser known brother. :) Sorry if you don't get it. Old demomaking joke.
     // GorgonMotion... The forgotten remix of Global Motion (GMOTION.S3M by Purple Motion on modarchive haha)
     // ... ... Thats an awful lot of motion ! If that makes you sick, take a potion !
     // Okay, break is over, we now go back to our regular program :

     // Make the outer rings spin randomly, so it looks like active, adaptative tech.
     p*= r2d(3.14159*fbm(vec2(0.2*TimeVar)));

     // Distant tubes (probably the exit of the decelerator ring)
     col += 0.15*ColorTube*smoothstep(0.05,0.0,abs(length(p)-2.6) - 0.10);
     col += 0.50*ColorTube*smoothstep(0.05,0.0,abs(length(p)-2.2) - 0.05);

     // Main tube
     col += 0.5*ColorTube*smoothstep(0.05,0.0,abs(length(p)-7.2) - 1.5)
                         *smoothstep(0.0,0.05,abs(length(p)-7.3) - 0.1)
                         *smoothstep(0.0,0.05,abs(length(p)-7.7) - 0.05)
                         *smoothstep(0.0,0.01,abs(p.y - 0.7*clamp(sin(abs(1.7*abs(p.x) + 4.0)),0.0,0.5))-0.01);

     // Totally faked edge-shading, relative to Gorgon position (dot product from ColorTube, certainly wrong)
     col += 0.2*clamp((1.0-ColorTube),0.0,1.0)*smoothstep(0.005,0.0,abs(length(p)-7.15) - 0.01);
     col += 0.2*clamp((1.0-ColorTube),0.0,1.0)*smoothstep(0.005,0.0,abs(length(p)-7.60) - 0.01);
     col += 0.2*clamp((1.0-ColorTube),0.0,1.0)*smoothstep(0.005,0.0,abs(length(p)-8.70) - 0.01);

     // Drawing the supercontinuum laser firing holes
     // First rotate the beams with the exact angle so
     // that the branches of the star sdf are aligned.
     p*=r2d(PI/10.0);
     for(int i = 0 ; i < 10; i++)
     {
         // Adjust scale and position
         p *= vec2(5.0,1.0);
         // Holes
         col -= 0.5*ColorTube*smoothstep(0.05,0.0,length(p-vec2(-30.0,0.0))-0.25);
         // Radial amplifier supercontinuum beams that fire ONLY when the seal blast is activated
         if( FIRE_SEAL )
         {
            col += vec4(0.0,0.5,1.0,1.0)*smoothstep(0.1,0.0,abs(p.y + 0.05*fbm(vec2(2.0*p.x + 100.0*TimeVar))))*smoothstep(0.1,0.0,abs(p.x) - 30.0);
            col += vec4(1.0,1.0,0.0,1.0)*smoothstep(0.02,0.0,abs(p.y) - 0.01)*smoothstep(0.1,0.0,abs(p.x) - 30.0);
         };
         // Return to normal transform
         p *= 1.0/vec2(5.0,1.0);
         // Rotate to next pos for next hole
         p *= r2d(2.0*PI/10.0);
     };
     p *= r2d(PI/10.0);

     if( FIRE_SEAL ) // When the Gorgon beam is firing...
     {
        if(length(p)<5.3) // circular clipping to save GPU
        {
           // Draw the Ancient Seal. The ray is visible in vacuum because the supercontinuum
           // laser pulse is so intense, it actually breaks down spacetime on its path, and
           // makes it bleed tears of pure white light. Who said science had no poetry ?!
           col += abs(sin(1.5*p.y - 20.0*TimeVar))*(smoothstep(0.005,0.0,
                  // The Pentacle can be either positive -"one spike above" config-
                  // Or evil -"two spikes above" config. Here, it rotates, soooo we
                  // get the best of both worlds.
                  abs(sdStar5(p,1.5,2.89))-0.025)
                  +smoothstep(0.3,0.0,abs(sdStar5(1.0*p,1.5,2.89))-0.025)
                  // Draw additional concentric circles
                  + smoothstep(0.05,0.0,abs(length(p)-4.4))
                  + smoothstep(0.05,0.0,abs(length(p)-4.5))
                  + smoothstep(0.05,0.0,abs(length(p)-5.0))
                    // Captain Picard : "Make it glow !"
                  + smoothstep(0.30,0.0,abs(length(p)-4.4))
                  + smoothstep(0.30,0.0,abs(length(p)-4.5))
                  + smoothstep(0.30,0.0,abs(length(p)-5.0)));

           if(abs(length(p) - 4.75) < 0.2) // Ad-hoc Clipping for the seal's text...
           {
              if(abs(length(p) - 4.75) < 0.25)col += 0.95*vec4(1.0,0.5,0.1,1.0)*smoothstep(0.5,0.0,sin(3.0*atan(p.y,p.x) + 25.0*iTime));
              for(int j=0 ; j < 102; j++) // There are 102 chars in the spell...
              {
                  // Write the sacred words in Greek, because it looks better
                  // and more authentic that way !
                  // Since we write in a circle, we need to rotate for each char
                  p*=r2d(-float(j)*2.0*3.14159/102.0);
                  // Zooming a bit...
                  p*= 0.205;
                  // The 63 offset is a specific ROT-13 to translate from Latin to Greek chars.
                  col += traceChar(p,float(SealTxt[j]) + 63.0,vec2(0.0,0.0));
                  // Canceling transforms before going for another round...
                  p*= 1.0/0.205;
                  p*=r2d(float(j)*2.0*3.14159/102.0);
              };
           };
        };
     };

     // Resetting p, good as new !
     p = s;

     // It's time to draw the Gorgon's tentacles ! The more the better !
     // So I've been told by slutty witches, anyways... :)
     float NbTentax = 20.0;

     // Make them radiate
     for(float g=0.0; g<NbTentax; g++)
     {
         if( k.x > 0.0 && abs(k.y) < 0.65) // Static Masking
             col = mix(col,vec4(0.0),smoothstep(0.1,0.0,abs(k.y - 0.40*sin(k.x - 16.0*TimeVar + 2.0*PI*fbm(vec2(25.89*g))) ) - 0.2*clamp(1.0-0.2*k.x,0.0,1.0) + 0.04*fbm(vec2(10.0*k.x - 75.0*TimeVar + 3.258*g)))*vec4(1.0)*smoothstep(0.0,0.2,ooo + 0.5));
         k*=r2d(2.0*PI/NbTentax);
     };

     // Mask the tentacle hub behind the dark body of the Gorgon...
     col = mix(col,vec4(0.0),smoothstep(0.01,0.0,ooo));

     // Drawing the "force-field" jaws... Fun fact : the teeth actually rotate at
     // high-speed like a chainsaw, hence maximising damage. With gruesome results !
     if(FIRE_JAWS) // Make them appear from time to time
     {
        // Teeth params... It used to be better. IDK what I did, but I'm NOT satisfied with this specific config atm.
        float JawsSpeed  =  7.0;
        float TeethSpeed = 50.0;
        float TeethSize  =  0.2;
        float NbIterJaws = 15.0;
        float TeethScale =  0.8;

        // Avoid repeating calculations. This 2D shader is already way heavier than it has any right to be...
        float tmpCalc1   =  0.0;
        float tmpCalc2   =  0.0;
        float tmpCalc3   =  0.0;

        // Variate the orientation
        p *= r2d(0.7*fbm(vec2(2.0*TimeVar)) - 0.35);

        p *= TeethScale;
        for(float g=0.0; g<NbIterJaws; g++)
        {
            ColorWarp = 0.2*vec4(1.0 - 0.3*sin((3.0*3.14159/NbIterJaws)*g - 20.0*TimeVar),
                                  0.8*(1.0-g/NbIterJaws) - 0.5*sin((3.0*3.14159/NbIterJaws)*g - 20.0*TimeVar),
                                  0.5*(1.0-g/NbIterJaws) - 0.5*sin((3.0*3.14159/NbIterJaws)*g - 20.0*TimeVar),
                                  1.0);

            tmpCalc1 = TeethSize*TriangleWave(10.0*p.x + TeethSpeed*TimeVar);
            tmpCalc2 = p.x*p.x*(1.0 - 1.0*fbm(vec2(10.0*TimeVar)));
            tmpCalc3 = smoothstep(0.9,0.0,abs(p.x));
            // Lower Jaw
            col += ColorWarp*smoothstep(0.05,0.0,abs(p.y + tmpCalc1 - tmpCalc2 + 1.1 - 1.1*fbm(vec2(10.0*TimeVar))) - 0.1)*tmpCalc3;
            // Upper Jaw
            col += ColorWarp*smoothstep(0.05,0.0,abs(p.y + tmpCalc1 + tmpCalc2 - 1.1 + 1.1*fbm(vec2(10.0*TimeVar))) - 0.1)*tmpCalc3;

            p*= 0.992; // feedback for very soft color gradient on the teeth
        };
        p*= 1.0/TeethScale;

        p *= r2d(-0.7*fbm(vec2(2.0*TimeVar))+0.35);
     }else{
        // When the jaws are off, we draw the Head,
        // the Eye and the Synchrotron Beam
        float Clipping = smoothstep(0.85,0.0,ooo+0.5);

        // Make the eye dart everywhere because the Gorgon is crazy, and crazy fast !
        // Not sure about this passage. Probably a lot more non-sense than usual...
        vec2 EyeVector = vec2( 0.50 - 1.0*fbm(vec2(4.0*TimeVar + 0.29)),
                               0.25 - 0.5*fbm(vec2(2.5*TimeVar + 3.90)));
        float EVAngle = atan(EyeVector.y,EyeVector.x);

        p += EyeVector;

        float SizeSpot = 0.15;

        if( smoothstep(0.5,0.0,length(EyeVector) - 0.2) < 0.0 )SizeSpot = 0.50;

        SizeSpot += abs(0.15*sin(40.0*TimeVar));

        // The dark center of the Eye, the window to its soul !
        col -= vec4(1.0)*smoothstep(0.5,0.0,length(p) - 0.15 + 0.10*fbm(vec2(5.0*TimeVar)));

        angle = atan(p.y,p.x);

        // "There's a kind of evil glare in its eye, and it's NOT a trick of the light !" (Agent 147)

        ooo   = length( r2d(TimeVar)*p ) - 1.2 + 0.25*sin(8.0*angle + 20.0*TimeVar)*fbm(vec2(4.0*angle + 3.0*TimeVar));

        // "Awwww it's cute, it has some inflatable collar, like the Jurassic Park dinosaurs !" (intern 5)
        col += 0.25*vec4(1.0,0.0,0.0,1.0)*smoothstep(0.7,0.0,ooo + 0.9*fbm(vec2(5.0*TimeVar)));
        float Norm_Synch = (FIRE_SYNC)?2.0:1.0;
        col += Norm_Synch*vec4(1.0,0.5,0.0,1.0)*metaDiamond(p,vec2(0.0,0.0),0.2)*Clipping;

        col+= vec4(1.0,0.8,0.4,1.0)*metaDiamond(p,vec2(0.0,0.0),(0.1 + abs(0.1*sin(50.0*TimeVar))))
                                   *smoothstep(0.8,0.0,ooo + 0.9*fbm(vec2(5.0*TimeVar)))
                                   *Clipping;

        // "Awwwww, and it spits too ! Except it's light instead of tar goo !" (intern 5 again, Note : make sure we never hire her again...)
        if( FIRE_SYNC )
        {
            // The laser/synchrotron thing

            p *= r2d( EVAngle);
            // Beam Bloom (repeat it fast to look stupid, haha)
            col += vec4(1.0,0.6,0.4,1.0)*smoothstep(0.01 + 0.05*abs(p.x),0.0,abs(p.y) - 0.01*fbm(vec2(3.0*p.x + 75.0*TimeVar))*length(p))*smoothstep(0.1,0.0,p.x);
            // Actual Beam
            col += vec4(1.0,0.5,0.5,1.0)*smoothstep(                 0.1,0.0,abs(p.y)*length(p))*smoothstep(0.1,0.0,p.x);
            p *= r2d(-EVAngle);
            // Okay, now we're faking the noisy, pointy property of laser light. In French it's called
            // "tavelures" I think.
            if( length(noise(p))>.7)col+= 0.9*vec4(1.0,0.0,0.0,1.0)*noise(p)*smoothstep(5.0,0.0,length(p));

            // When the motion of the "eye" is close to the center, do some "blinding" trickery...
            if( length(EyeVector) < 0.1 )
            {
                col += 0.5*abs(sin(10.0*TimeVar));
                col += 0.2*smoothstep(1.0,0.0,length(p)-1.5);
                // Draw some flaming tunnel since we're basically staring straight into the jaws of a dragon !
                col += 2.0*drawTunnel(0.1*p, vec4(1.0), iChannel0,TimeVar);
                // Ye Olde Eyeblower, since we're staring into a very coherent beam which has at least
                // "some" internal structure (Bessel/solenoid beam and such), hence interferences and diffraction
                // patterns... IDK really, this just feels right, honestly. Animator's hunch...
                // It certainly adds something right to the blinding flashes, though.
                // Makes for nice screenshots too ! :)
                col -= 0.3*sin(50.0*(length(p-vec2(-0.8,0.0))) - 50.0*TimeVar)
                     + 0.3*sin(50.0*(length(p-vec2( 0.8,0.0))) - 50.0*TimeVar);
            };
        };

        // Add anamorphic streak because at this stage we're faking everything
        // Morpheus (smug) : "You think that's air, you're breathing in here ?"
        col += 0.5*smoothstep(0.1,0.0,abs(p.y) - 0.025)*smoothstep(8.5,0.0,abs(p.x));
     };

     // Sometimes, the colors suddenly invert to simulate a failed "phasing out"
     // attempt... i.e. the Gorgon is trying to escape by slipping through dimensions !
     if( FIRE_PHAS )
     {
        col = 1.0-col;
     }else{
        // This is my last chance at color-keying... and I'm not gonna miss it !
        col *= vec4(1.0,0.7,0.5,1.0); // BAAM ! Subtle, as always. :)
     };

     // Reload the correct base before we switch to text mode
     p = last_p;

     // Very special imaging mode called PINBALL MODE. IDK, don't ask, it just looks cool.
     // and it could actually be a lowres, still experimental mode of the multispectral imager.
     // To detect neutrinos in realtime, or something. (...making shit up is how I roll)
     if( PINB_MODE )col -= smoothstep(0.0,0.8,length(150.0*p -floor(150.0*p) - vec2(0.5)) - 0.1);

     // Screen Grid because good scientists quantify everything...
     col += 0.1*smoothstep(0.025,0.0,abs(sin(30.0*p.y)));
     col += 0.1*smoothstep(0.025,0.0,abs(sin(30.0*p.x)));

     // Screen Text
     vec4 ColorText = vec4(1.0,1.0,0.0,1.0);

     // Lower Text / Technical Data
     if(abs(p.x) < 0.51 && abs(p.y + 0.44) < 0.05) // clipping
     {
        col -= vec4(0.5);
        col = mix(col,ColorText,traceLabels(1.75*p,0,61.0,vec2(0.0,1.78)));
        col = mix(col,ColorText,traceLabels(1.75*p,1,51.0,vec2(0.0,1.70)));
     };

     // Upper Text / Time
     if(abs(p.x - 0.34) < 0.15 && abs(p.y - 0.47) < 0.025) // clipping
     {
        col -= vec4(0.5);
        col = mix(col,ColorText,traceLabels(1.75*p,2,16.0,vec2(0.6,0.15)));
     };

     // Gamma Ray Alert (usually when the Gorgon fires its beam)
     if( FIRE_SYNC )
     {
        // Yellow Tape
        col += vec4(1.0,1.0,0.0,1.0)*smoothstep(0.005,0.0,abs(p.y + 0.33) - 0.03);
        // Calculating beestripes (this could be done soooo much more elegantly. But I just can't be bothered...)
        p*=r2d( PI/4.0);
        vec4 BeeStripes = vec4(1.0)*smoothstep(0.01,0.0,abs(sin(45.0*p.x + 10.0*TimeVar)) - 0.75);
        p*=r2d(-PI/4.0);
        // clipping beestripes to leave some space for the text
        BeeStripes *= smoothstep(0.0,0.005,abs(p.x)-0.25);
        // Text GAMMA RAY ALERT + beestripes
        col = mix(col,vec4(0.0),smoothstep(0.005,0.0,abs(p.y + 0.33) - 0.025)*BeeStripes
                               +traceLabels(p,3,17.0,vec2(0.0,1.3)));
     };

     // Mag Field Failure (The Gorgon's field is becoming too strong, Captain !)
     if( MAGN_FAIL )
     {
        // Red Tape
        col += vec4(1.0,0.0,0.0,1.0)*abs(cos(2.5*iTime))*smoothstep(0.01,0.0,abs(p.y - 0.33) - 0.03);
        // Calculating beestripes (btw bees, being quite efficient, intelligent
        // creatures, would probably disapprove this specific, lame implementation)
        p*=r2d( PI/4.0);
        vec4 BeeStripes = vec4(1.0)*smoothstep(0.01,0.0,abs(sin(45.0*p.x + 10.0*TimeVar)) - 0.75);
        p*=r2d(-PI/4.0);
        // clipping beestripes to leave some space for the text
        BeeStripes *= smoothstep(0.0,0.005,abs(p.x)-0.29);
        // Text MAG FIELD FAILURE + beestripes
        col = mix(col,vec4(1.0,1.0,0.0,1.0),abs(cos(2.5*iTime))*smoothstep(0.005,0.0,abs(p.y - 0.33) - 0.025)*BeeStripes
                               + traceLabels(p,4,19.0,vec2(0.0,0.64)));
     };

     // Emergency Supercontinuum Seal Blast. It somehow makes the Gorgon uncomfortable.
     // IDK why. Go ask Agent 145 for more. I'm no magic specialist, just a regular scientist !
     if( FIRE_SEAL )
     {
        col = mix(col,vec4(1.0,1.0,1.0,1.0)*abs(sin(50.0*abs(p.y+0.23) + 10.0*TimeVar         )),smoothstep(0.005,0.0,abs(p.y+0.23) - 0.025));
        col = mix(col,vec4(0.0),traceLabels(p*0.99,5,35.0,vec2(0.002,1.196)));
        col = mix(col,vec4(1.0,1.0,1.0,1.0)*abs(sin(50.0*abs(p.y+0.23) + 10.0*TimeVar + PI/2.0)),traceLabels(p*0.99,5,35.0,vec2(0.0,1.198)));
     };

     // "I stood on the pale gray shores beyond time and space.
     // In an awful light that was not light,
     // in a silence that shrieked, I saw them."
     // The Hounds Of Tindalos, by Frank Belknap Long
     // "And just behind them, there was a gorgon ! And a squirrel too, which has
     // nothing to do with anything, but it was there, I saw it ! How strange is that ?!"
     // The Strange Squirrel At The End Of Everything, by msm01
     fragColor = clamp(col,0.0,1.0);
}
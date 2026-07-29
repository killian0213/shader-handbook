// Image (image) — Star Trek In A Shader... by msm01
// https://www.shadertoy.com/view/3cdGD4

////////////////////////////////////////////////////////////////////////////////
// This toy is called : "Star Trek In A Shader..." or how You should NEVER, EVER
// underestimate a monkey with a typewriter !!!  Sure,  he does NOT understand a
// single word he's typing,  but he might actually get a few cool Hamlet quotes,
// entirely by chance ! "To be or not to be", though memorable, is only  a short
// sentence, after all.
// *said-monkey lights up a big fat cigar*
// *blows smoke in your face, smiles smugly*

// A few explanations :  I made this shader so that YOU can relax, have a drink,
// sit back, play the perfect soundtrack... And enjoy vast amounts of UNLIMITED,
// FREE, OMNIDIRECTIONAL STARTREKING !
// Because let's be real : that's what shaders were meant for. Rotating 3D cubes
// AND making 2D space scrollers.

// Long story short, I was working on a Captain Future fanart, trying to do some
// cool nebulas, then saw https://www.shadertoy.com/view/WXBSRD by yufengjie and
// it just clicked in my brain. I had been doing simple fbm-based domain-warping
// before (in a yet unpublished Halloween shader) but this somehow suddenly made
// total sense to me.  Exactly 3 minutes later my nebula was upgraded from so-so
// to Mutara-class amazing! Around the same time I had been talking with TommieK
// about his nebula shaders  :  https://www.shadertoy.com/view/w32SWy and also :
// https://www.shadertoy.com/view/WXSSDW  joking that he should include a little
// "Enterprise" silhouette in the clouds ("Star Trek II : Wrath of KAAAAAAAHN !"
// reference) so I took the matter into my own hands. This is the result. Thanks
// to TommieK and yufengjie ! :)

// So, music suggestions !
// -I recently found this cool trumpet-version from Japanese TV on Soundcloud,
// this fits the shader so well (I put a timestamp to skip some speech) :
// https://soundcloud.com/letyasiturena78/star-trek-the-original-series-theme-cover-by-eric-miyashiro?#t=39s
// It's also on youtube !
// ...But you have MANY other suitable choices :
// -"Battle in the Mutara Nebula" - obvious, the connoisseur's pick.
// -"Leaving Drydock" - Nothing beats this.
// -"Stealing the Enterprise" - Already freaking cool 40 years ago, Gandalf !
// -"Klingon Battle" - Scifi classic !
// -"Star Trek TOS : opening" - Never gets old.
// -Any old Star Trek movies ouverture from TOS or TNG - They're all glorious !
// -The Opening of "ST : Strange New Worlds".  - Never been fond of modern Trek
// but this one actually sounds kinda cool, I guess...

// Btw... there's one scene in that specific opening that looks a bit like this
// shader. Discovered that afterwards. Never watched the series. So it is not a
// tribute, just convergent evolution. Also I am aware that the Enterprise from
// TOS ("The Original Series") had NO green bubble deflector shield but I could
// do it so I did ! Let's pretend that Picard, La Forge and Data have gone back
// in time, yet again - because of those damn Borgs leaking tachyons everywhere
// like the disgusting mutants they are - that they have recovered the original
// spaceship, and upgraded the shields to Next-Gen-level tech.
// There. Lore-accurate, Picard, and Bob's your uncle. Happy, now ?! :) With my
// luck, that's the exact synopsis of a specific TNG episode I don't remember.

// Ross : "The word you're searching for is : anyway..."

// This shader is dedicated to Iq for making Shadertoy, to James T. Kirk for
// being the coolest, and Jean-Luc Picard for being French.
// No scifi story this time, sorry guys, you'll have LOTS OF sci-fi pretty soon
// (I hope). With other, more original shaders. I'm sooooo NOT done with domain
// warping, you people have no idea.
// "Domain-Warp 3, Mr Sulu !"
// MSM01, signing off...

#define PI 3.14159
#define s(a,b,c) smoothstep(a,b,c)

float TiltX, AltiY;

// The Usual Tools For Fools !

// 1st place : Miss Rotation Matrix ! Thinks the world revolves around her !
mat2 r2d(float a){float c=cos(a), s=sin(a); return mat2(c,s,-s,c);}

// 2nd place : Dave Hoskins's hash ! Noone can hash hashes like he hashes !
float hash12(vec2 p)
{
      vec3 p3  = fract(vec3(p.xyx) * .1031);
      p3 += dot(p3, p3.yzx + 33.33);
      return fract((p3.x + p3.y) * p3.z);
}
// 3rd place : Smoothed 1D-noise. Just like Zoltraak : stupid simple, yet super
// powerful. Fear the guy that has practiced one move a million times, etc.
float fbm(in vec2 v_p)
{
      float pvpx = 2.0*v_p.x;
      vec2 V1 = vec2(0.5*floor(pvpx      ));
      vec2 V2 = vec2(0.5*floor(pvpx + 1.0));
      return mix(hash12(V1),hash12(V2),smoothstep(0.0,1.0,fract(pvpx)));
}

// 4th place : Sir Metadiamond. All the girls love him !
float metaDiamond(vec2 p, vec2 pixel, float r)
{
      vec2 d = abs(p-pixel);
      return r / (d.x + d.y);
}

// Fifth place : Iq's sdUnevenCapsule. Bet you didn't think it would be
// used for the Enterprise con tower, uh ?!
float sdUnevenCapsule( vec2 p, float r1, float r2, float h )
{
    p.x = abs(p.x);
    float b = (r1-r2)/h;
    float a = sqrt(1.0-b*b);
    float k = dot(p,vec2(-b,a));
    if( k < 0.0 ) return length(p) - r1;
    if( k > a*h ) return length(p-vec2(0.0,h)) - r2;
    return dot(p, vec2(a,b) ) - r1;
}

// Shader Specific Code Start

// Super simple domain-warping. Can built whole galaxies with the right texture...
// Its needs a lot of fiddling, though. "Art more than science", and I like that !
vec2 domain_warping(vec2 p)
{
     vec2 dist;
     float ampli1=0.5;
     mat2 rm= mat2(1.7);
     for( float i = 0.0; i<2.0; i++ )
     {
          dist = 7.0*texture(iChannel0,0.002*rm*p + 0.00*iTime).xy;
          p += ampli1*dist;
          rm *= rm*5.0;
     };
     return p;
}

// The worst tracechar code you've ever seen... today ! :)
float traceChar( in vec2 v,float charac, vec2 PosTxt)
{
      float colorChar = 0.0;
      v = vec2(v.x, 1.0-v.y);
      if( v.x > PosTxt.x && v.x < PosTxt.x + 1.0/16.0 )
      {
          if( v.y > PosTxt.y && v.y < PosTxt.y + 1.0/16.0 )
          {
              vec2 Disp = vec2(mod(float(charac),16.0),floor(float(charac) / 16.0))/16.0;
              colorChar = texture(iChannel1,vec2(Disp.x + (v.x - PosTxt.x),-Disp.y - (v.y - PosTxt.y) )).x;
          };
      };
      return colorChar;
}

// Poorman's palette ! Also called (only by me) "semi-automatic color gun".
vec4 GetColorSpot(vec2 c)
{
     float SelectedColor = floor(mod(c.x,7.0));
     float Mask = s(0.0,0.75,abs(sin(c.x*PI/1.0)));

     if(SelectedColor == 0.0)return vec4(1.0,0.0,0.0,1.0)*Mask;
     if(SelectedColor == 1.0)return vec4(1.0,1.0,1.0,1.0)*Mask;
     if(SelectedColor == 2.0)return vec4(0.1,0.7,0.3,1.0)*Mask;
     if(SelectedColor == 3.0)return vec4(1.0,0.5,0.0,1.0)*Mask;
     if(SelectedColor == 4.0)return vec4(1.0,0.0,1.0,1.0)*Mask;
     if(SelectedColor == 5.0)return vec4(0.0,0.5,0.5,1.0)*Mask;
     if(SelectedColor == 6.0)return vec4(1.0,0.7,0.5,1.0)*Mask;
}

// This is where the magic happens, Mr Frodo !
void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
     // Get Coordinates... You can't do shit if you don't !
     vec2 p = vec2( (fragCoord.x - iResolution.x/2.0)/iResolution.y,fragCoord.y/iResolution.y - 0.5);

     // We're gonna screw up so bad, so better save clean coords while they're
     // still fresh. Like salad, though, it WILL spoil fast !
      vec2 last_p = p;

     // The World. Null vector. Cosmic irony, zero-sum games, and stuff...
     vec4 col = vec4(0.0);

     // "Impulse engines. 10%."
     float Speed = 10.0*iTime;

     // Gotta make people interact, THEY NEED THE INTERACTION !
     TiltX = -0.0150*(iMouse.x - iResolution.x/2.0);
     AltiY =  0.0015*(iMouse.y - iResolution.y/2.0);

     // Poorman's "theatre screen fitted on an old TV" effect. You know you love those black stripes !
     if( abs(p.y) - 0.4 < 0.0)
     {
         // We take a good step back and then... TOM CRUISE IN TROPIC THUNDER !
         p*=12.0;

         // Random French cuisine, as usual...
         p*=1.0 + AltiY;
         p*=r2d(TiltX);

         // Scroll to the right.
         p*=r2d(0.4 + 2.0*PI*fbm(vec2(0.1*iTime)) - PI);

         // duplicating p for later use.
         vec2 b = p, l = p;

         // Where are we ?!
         vec2 ScrollPos = p + vec2(Speed,0.0);

         // BG Nebula : making everything brighter and glowy ! :)
         col = mix(vec4(0.0,0.0,0.0,1.0),GetColorSpot(0.01*ScrollPos),s(5.0,0.0,abs(p.y - 5.5*fbm(0.05*ScrollPos) + 3.0) - 0.0 - 1.0*fbm(0.15*ScrollPos)));

         p = domain_warping(ScrollPos);

         // Get 4 cloud profiles.
         float Nebula1 = p.y - 2.0*fbm(vec2(0.2*p.x+ 124.9));
         float Nebula2 = p.y - 3.0*fbm(vec2(0.5*p.x+ 170.4));
         float Nebula3 = p.y - 2.0*fbm(vec2(0.2*p.x+ 124.9)) - 0.5;
         float Nebula4 = p.y - 2.0*fbm(vec2(0.2*p.x+  15.4)) + 0.5;

         // BG nebula dark, wide
         col+= vec4(0.5,0.5,0.5,1.0)*GetColorSpot(vec2(0.01*p))*texture(iChannel0,0.005*p)
                                    *s(5.5,0.0,abs(p.y-3.5)-10.0*fbm(vec2(0.1*p)));

         // Lighter Nebula ribbon
         Nebula1 = p.y - 2.0*fbm(vec2(0.2*p.x+124.9));
         col+= 0.5*texture(iChannel0,0.005*(p))*s(0.1,0.0,abs(Nebula1)-2.0)*s(0.0,0.3,Nebula2);

         // Main clouds thin highlight...
         col+= 1.0*texture(iChannel0,0.005*(p))*s(0.10,0.0,Nebula3)*s(0.0,0.5,Nebula4);

         // Dark dust cloud ribbon...
         col= mix(col,clamp(3.0*GetColorSpot(0.01*p)*vec4(0.2,0.2,0.3,0.0)*texture(iChannel0,0.005*(p)),0.0,0.4),fbm(0.125*p)*s(1.0-fbm(0.7*p),0.0,abs(Nebula1) - 0.5));

         // Localised Lighter Spaces Within The Main Clouds
         col*= 1.0+1.0*fbm(vec2(0.5*p.x))*texture(iChannel0,0.005*(p))*s(0.01,0.0,abs(Nebula3)-0.2);

         // Getting our p back ! (resetting coords)
         p=b;

         // Getting the Scroller back. "PUT ! THE CANDLE ! BACK !"
         p += vec2(Speed,0.0);

         // 4 lines 2D monolayer starfield. 'Nuff said !
         b = fract(5.0*p);
         p = floor(5.0*p);
         if( fbm(vec2(p.x*p.y)) > (0.95 ) && s(0.0,1.5,abs(Nebula1) - 0.5) > 0.0)
             col += clamp(vec4(0.99)*pow((50.0 - 40.0*fbm(vec2(p.x+p.y)))*length(b-vec2(0.8*fbm(vec2(p.x*p.y)),0.80*fbm(vec2(p.x*p.y+258.2)))),-2.5),0.0,1.0);

         // The Enterprise Saucer
         p=last_p;
         // INTERACTION ! It's important I tell ya.
         p*=1.0 + AltiY;
         p*=r2d(TiltX);
         // Makes the whole universe spin around and around, and around
         // like an old BASS BUMPERS vinyl !
         p*=r2d(0.4 + 2.0*PI*fbm(vec2(0.1*iTime)) - PI);
         // Zoom out a bit. ("Not so close, milady !" :)
         p*=2.5;
         // Introduce random lateral moves to make the scene less static.
         p += vec2(fbm(vec2(0.1*iTime))-0.5,0.0);
         // Turn the ship towards the direction of motion, FFS ! SULU ! Are you drunk ?!
         p*= r2d(-PI/2.0);

         // The Saucer
         col = mix(col,vec4(0.40)+pow(30.0*length(p),-2.0)*s(0.0,0.020,p.y-10.*p.x*p.x - 0.0230),s(0.005,0.0,length(p) - 0.1));
         // Con Tower Dome
         col = mix(col,vec4(0.1),s(0.02,0.0,abs(length(p)-0.01) - 0.001));
         // Outer Rim Ring
         col = mix(col,vec4(0.60),s(0.001,0.0,abs(length(p)-0.100) - 0.001));
         // Circles of shielding.
         col = mix(col,vec4(0.45),s(0.001,0.0,abs(length(p)-0.075) - 0.001));
         col = mix(col,vec4(0.45),s(0.001,0.0,abs(length(p)-0.050) - 0.001));
         col = mix(col,vec4(0.45),s(0.001,0.0,abs(length(p)-0.025) - 0.001));
         // Con Tower Capsule Module
         col = mix(col,vec4(0.2),s(0.01,0.0,abs(sdUnevenCapsule(r2d(PI)*5.0*p,0.1,0.05,0.2)-0.025) - 0.001));
         // Right Green
         col += vec4(0.0,1.0,0.0,1.0)*pow(400.0*(1.0+0.1*abs(sin(2.0*iTime)))*length(p-vec2(0.1,0.0)),-2.0);
         // Left Red
         col += vec4(1.0,0.0,0.0,1.0)*pow(400.0*(1.0+0.1*abs(sin(2.0*iTime + PI/2.0)))*length(p-vec2(-0.1,0.0)),-2.0);
         // Con Tower Upper Porthole
         col += vec4(1.0)*pow(400.0*length(p-vec2(0.0,0.0)),-2.0);
         // Main ID Light
         col += vec4(1.0)*pow(200.0*length(p-vec2(0.0,0.01)),-2.0);
         // Saucer Dual Impulse Engines Glow
         col += vec4(1.0,0.0,0.0,1.0)*pow(400.0*length(p-vec2( 0.0075,-0.1)),-1.5);
         col += vec4(1.0,0.0,0.0,1.0)*pow(400.0*length(p-vec2(-0.0075,-0.1)),-1.5);
         // 4 signature lights.
         p*=r2d(PI/4.0);
         col += vec4(1.0,0.9,0.5,1.0)*pow(400.0*length(p-vec2(0.0, 0.085)),-2.0);
         col += vec4(1.0,0.9,0.5,1.0)*pow(400.0*length(p-vec2(0.0,-0.085)),-2.0);
         col += vec4(1.0,0.9,0.5,1.0)*pow(400.0*length(p-vec2(0.085,0.0)),-2.0);
         col += vec4(1.0,0.9,0.5,1.0)*pow(400.0*length(p-vec2(-0.085,0.0)),-2.0);
         p*=r2d(-PI/4.0);

         // Spaceship Main Body
         p=last_p;
         p*=1.0 + AltiY;
         p*=r2d(TiltX);
         p*=r2d(0.4 + 2.0*PI*fbm(vec2(0.1*iTime)) - PI);
         p*=2.5;
         p += vec2(fbm(vec2(0.1*iTime))-0.5,0.0);
         p*= r2d(-PI/2.0);
         vec4 ColorNCC1701 = vec4(0.4);

         // Drawing the Enterprise classic serial number : NCC-1701
         // I could have used a for-loop and an array, didn't because
         // I'm working on another script atm (shader-doodle) that DOES NOT
         // support arrays. So I have to make do ! Bear with me.
         p*=r2d(PI - 0.60);
         col = mix(col,ColorNCC1701,traceChar(2.5*p,78.0,vec2(-0.043,1.125)));
         p *= r2d(0.18);
         col = mix(col,ColorNCC1701,traceChar(2.5*p,67.0,vec2(-0.043,1.125)));
         p *= r2d(0.18);
         col = mix(col,ColorNCC1701,traceChar(2.5*p,67.0,vec2(-0.043,1.125)));
         p *= r2d(0.18);
         col = mix(col,ColorNCC1701,traceChar(2.5*p,45.0,vec2(-0.043,1.125)));
         p *= r2d(0.18);
         col = mix(col,ColorNCC1701,traceChar(2.5*p,49.0,vec2(-0.043,1.125)));
         p *= r2d(0.18);
         col = mix(col,ColorNCC1701,traceChar(2.5*p,55.0,vec2(-0.043,1.125)));
         p *= r2d(0.18);
         col = mix(col,ColorNCC1701,traceChar(2.5*p,48.0,vec2(-0.043,1.125)));
         p *= r2d(0.18);
         col = mix(col,ColorNCC1701,traceChar(2.5*p,49.0,vec2(-0.043,1.125)));
         p *= r2d(-7.0*0.18);
         p*=r2d(-PI + 0.60);

         // The Enterprise Hangar Deck + Warp Drives Nacelles
         // As everything is x-symetric, we tell it to the shader :
         p.x = abs(p.x);
         p.x -= 0.075;
         // Additional impulse engines, the blue kind. There are none in the original
         // series, but I added them : the Rule of Cool must prevail.
         col += vec4(0.1,0.15,1.0,1.0)*metaDiamond(p,vec2(0.0,-0.327),0.03);
         // Reddish bow domes glow (shielding generators, I think ?)
         col += vec4(1.0,0.75,0.5,1.0)*metaDiamond(p,vec2(0.0,-0.125),0.005+0.003*sin(10.0*iTime));
         // The Dome Caps !
         col += vec4(0.5,0.1,0.1,1.0)*s(0.001,0.0,length(p - vec2(0.0,-0.125)) - 0.008);
         // The nacelles with shading, colored rings and dark aft exhaust
         if(abs(p.y + 0.225) - 0.10 < 0.0)col = mix(col,
         vec4(vec3(0.75*cos(200.0*p.x)),1.0)
         - vec4(0.3)*s(0.001,0.0,abs(p.y + 0.135)-0.0010)
         - vec4(0.3)*s(0.001,0.0,abs(p.y + 0.315)-0.015),
         s(0.005,0.0,abs(p.x) - 0.005));
         // Radiator fins (or wedges, or smth...).
         col = mix(col,vec4(0.7),s(0.001,0.0,abs(p.y+0.265) - 0.025)*s(0.001,0.0,abs(p.x)-0.007)*s(0.0,0.0001,abs(p.x)-0.0040));
         p.x += 0.075;
         // Hangar Deck
         if(abs(p.y +0.15) -0.075 < 0.0)col = mix(col,vec4(vec3(0.75-0.55*sin(100.0*p.x)),1.0),s(0.005,0.0,abs(p.x + clamp(0.005*cos(50.0*p.y + 1.4*PI),0.0,1.0)) - 0.015)*s(0.0,0.01,length(p)-0.10));

         p.y += 0.14;

         // Mounts
         if(abs(p.x)<0.067)col = mix(col,vec4(vec3(0.75*sin((10.0*(p.x+0.05)))),1.0)
         ,s(0.005,0.0,p.y + 0.2*(p.x+0.15))*s(0.0,0.005,p.y + 0.2*(p.x+0.25) + 0.005)
         *s(0.0,0.01,abs(p.x) - 0.0015));

         // Tail Light
         col += vec4(1.0,0.9,0.5,1.0)*pow(500.0*length(p-vec2( 0.0,-0.080)),-2.0);
         // Front Light
         col += vec4(1.0,0.9,0.5,1.0)*pow(500.0*length(p-vec2( 0.0, 0.240)),-2.0);
         // Saucer Mount
         if(abs(p.x)<0.0025)col = mix(col,vec4(0.4),s(0.005,0.0,abs(p.y-0.05) - 0.04));

         // Enemy Shots + Enterprise Hacked STNG Bubble Shield
         if( fbm(vec2(iTime))>0.75) // Probabilistic firing
         {
             p=last_p;
             p*=1.0 + AltiY;
             p*=r2d(TiltX);
         p*=r2d(0.4 + 2.0*PI*fbm(vec2(0.1*iTime)) - PI);
             p*=2.5;
             p += vec2(fbm(vec2(0.1*iTime))-0.5,0.0);
             p += vec2(0.1,0.0);

             // Rotate in any direction to simulate random incoming fire
             p*= r2d(fbm(vec2(floor(iTime)))*2.0*PI);

             // Displays a bubble shield hit by scrolling a texture on a
             // spherical profile. The fun part is I came up with the formula
             // by pure maths impro, i.e. "educated guess". So it's surely
             // massively suboptimal but that's the Shakespearean monkey for you !
             // This uv coords trick has SO many other applications to a 2D
             // space art fan like me. :D Hopefully I'll show you soon.
             col += 3.5*texture(iChannel0,5.0*p/(50.0*cos(length(5.1*p))) + vec2(1.0*iTime,0.0))*s(0.01,0.0,length(p) - 0.3)
             *vec4(0.0,1.0,0.0,1.0)*s(0.0,0.8,length(p - vec2(-0.5,0.0)) - 0.3);

             // Difuse Green Energy Glow
             col += vec4(0.0,0.25,0.0,1.0)*clamp((s(0.1,0.0,length(p) - 0.30)-s(0.01,0.0,length(p) - 0.3)),0.0,1.0);
             // Point Of Impact ! :)
             col += vec4(0.0,1.0,0.5,1.0)*metaDiamond(p,vec2(0.3,0.0),0.10);
             // Move Coords to Point Of Impact
             p += vec2(-0.3,0.0);
             // Random angle of incidence makes the beam more realistic !
             // Tangential shots excluded for obvious reasons, hence the PI/4.0.
             p*= r2d(fbm(vec2(floor(iTime)))*PI/4.0);
             // Trace The Attacking Beam Out Of Bubble Radius, obviously ! :)
             if(p.x>0.0)col += 5.0*vec4(1.0,1.0,0.5,1.0)*clamp(sin(40.0*p.x + 250.0*iTime),0.0,1.0)*s(0.01,0.0,abs(p.y));
         };

         // Basically the same, only for the Enterprise Dual Blue Phaser Arrays !
         if( fbm(vec2(0.5*iTime + 5432.1))>0.9)
         {
             p=last_p;
             p*=1.0 + AltiY;
             p*=r2d(TiltX);
         p*=r2d(0.4 + 2.0*PI*fbm(vec2(0.1*iTime)) - PI);
             p*=2.5;
             p += vec2(fbm(vec2(0.1*iTime))-0.5,0.0);
             p*= r2d(-PI/2.0);

             float FiringAngle = PI*fbm(floor(vec2(0.5*iTime + 123.12)));
             p*= r2d(FiringAngle);
             p*= r2d(-0.01);
             if(p.x>0.1)col = mix(col,vec4(0.5,0.5,1.0,1.0),s(0.01,0.0,abs(p.y + 0.005)));
             if(p.x>0.1)col += vec4(0.0,1.0,1.0,1.0)*s(0.005,0.0,abs(p.y + 0.005));
             p*= r2d(0.02);
             if(p.x>0.1)col = mix(col,vec4(0.5,0.5,1.0,1.0),s(0.01,0.0,abs(p.y - 0.005)));
             if(p.x>0.1)col += vec4(0.0,1.0,1.0,1.0)*s(0.005,0.0,abs(p.y - 0.005));
             p*= r2d(-0.01);
             col += vec4(0.0,1.0,1.0,1.0)*metaDiamond(p,vec2(0.1,0.0),0.02);
             p*= r2d(-FiringAngle);
         };

         // Additional layers of dust... Gives the scene more depth.
         // And beautiful colors superposition.
         // layer 1
         p=l;
         p = domain_warping(p + vec2(2.0*Speed,0.0));
         p *= 0.5;
         p += vec2(0.0,0.5);
         Nebula1 = p.y - 4.0*fbm(vec2(0.2*p.x+124.9));
         col = mix(col,clamp(5.0*GetColorSpot(0.01*p + 4.0)*vec4(0.2,0.2,0.3,0.0)*texture(iChannel0,0.005*(p)),0.0,0.4),fbm(0.5*p)*s(1.0-fbm(0.7*p),0.0,abs(Nebula1) - 2.5));

         // layer 2
         p=l;
         p = domain_warping(p + vec2(8.0*Speed,0.0));
         p *= 0.15;
         p += vec2(0.0,1.0);
         Nebula1 = p.y - 2.0*fbm(vec2(0.2*p.x+124.9));
         col = mix(col,clamp(5.0*GetColorSpot(0.01*p+ 4.0)*vec4(0.2,0.2,0.3,0.0)*texture(iChannel0,0.005*(p)),0.0,0.4),0.5*s(1.0-fbm(0.7*p),0.0,abs(Nebula1) - 0.5));

     }else{
         // Display some text because otherwise we're just space savages !
         p=last_p;
         p*=0.75;
         if( iTime< 4.5)
         {
             // Oh, that time, I DID used the for-loop thing.
             // Because I added these lines at the end. :)
             int[24] TabSTIAS = int[](83, 84, 65, 82, 32, 84, 82, 69, 75, 32, 73, 78, 32, 65, 32, 83, 72, 65, 68, 69, 82, 46, 46, 46);
             for( float h=0.0;h< 24.0; h++)
             {
                  col += vec4(1.0,1.0,0.0,1.0)*traceChar(p,float(TabSTIAS[int(h)]),vec2(-25.0*0.027/2.0 + 0.027*h
                  ,1.30));
             };
         };
         if( iTime > 4.5 && iTime < 9.0)
         {
             // Smug Sam Gamegie : "And Oh ! ...MORE Text !"
             int[48] TabSTIAS2 = int[](80, 76, 65, 89, 32, 83, 79, 77, 69, 32, 83, 84, 65, 82, 32, 84, 82, 69, 75, 32, 77, 85, 83, 73, 67, 44, 32, 83, 73, 84, 32, 66, 65, 67, 75, 32, 65, 78, 68, 32, 69, 78, 74, 79, 89, 46, 46, 46);
             for(float h=0.0;h< 48.0; h++)
             {
                 col += vec4(1.0,1.0,0.0,1.0)*traceChar(p,float(TabSTIAS2[int(h)]),vec2(-49.0*0.027/2.0 + 0.027*h
                 ,1.30));
             };
         };
     };
     // "What does God need with a starship ?!"
     fragColor = col;
}
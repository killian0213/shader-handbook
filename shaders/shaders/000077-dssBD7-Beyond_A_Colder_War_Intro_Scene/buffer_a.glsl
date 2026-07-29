// Buffer A (buffer) — Beyond A Colder War, Intro Scene by msm01
// https://www.shadertoy.com/view/dssBD7

// Short, basic functions.
mat2  r2d( float a ){ float c = cos(a), s = sin(a); return mat2( c, s, -s, c ); }
float noise(vec2 st) { return fract( sin( dot( st.xy, vec2(12.9898,78.233)))*43758.5453123 ); }

float traceChar( in vec2 v,float charac, vec2 PosTxt)
{
      float colorChar = 0.0;
      v = vec2(v.x, 1.0-v.y);
      if( v.x > PosTxt.x && v.x < PosTxt.x + 1.0/16.0 )
      {
          if( v.y > PosTxt.y && v.y < PosTxt.y + 1.0/16.0 )
          {
              vec2 Disp = vec2(mod(float(charac),16.0),floor(float(charac) / 16.0))/16.0;
              colorChar = texture(iChannel3,vec2(Disp.x + (v.x - PosTxt.x),-Disp.y - (v.y - PosTxt.y) )).x;
          };
      };
      return colorChar;
}

// Basic Geometry Functions, Thanks Iq, Shadertoy, Et Alia...

float sdCircle(in vec2 p, float radius, vec2 pos, float prec)
{
      return smoothstep(0.0,prec,radius - length(pos-p));
}

float dis_e(vec2 center, float a, float b, vec2 coord)
{
      float x2 = (coord.x-center.x)*(coord.x-center.x);
      float y2 = (coord.y-center.y)*(coord.y-center.y);
      float a2 = a*a;
      float b2 = b*b;
      float d = 1.0;
      d = x2/a2+y2/b2;
      return d;
}

float sdTriangle( in vec2 p, in vec2 p0, in vec2 p1, in vec2 p2 )
{
      vec2 e0 = p1-p0, e1 = p2-p1, e2 = p0-p2;
      vec2 v0 = p -p0, v1 = p -p1, v2 = p -p2;
      vec2 pq0 = v0 - e0*clamp( dot(v0,e0)/dot(e0,e0), 0.0, 1.0 );
      vec2 pq1 = v1 - e1*clamp( dot(v1,e1)/dot(e1,e1), 0.0, 1.0 );
      vec2 pq2 = v2 - e2*clamp( dot(v2,e2)/dot(e2,e2), 0.0, 1.0 );
      float s = sign( e0.x*e2.y - e0.y*e2.x );
      vec2 d = min(min(vec2(dot(pq0,pq0), s*(v0.x*e0.y-v0.y*e0.x)),
                       vec2(dot(pq1,pq1), s*(v1.x*e1.y-v1.y*e1.x))),
                       vec2(dot(pq2,pq2), s*(v2.x*e2.y-v2.y*e2.x)));
      return -sqrt(d.x)*sign(d.y);
}

float sdBox( in vec2 p, in vec2 b )
{
      vec2 d = abs(p)-b;
      return length(max(d,0.0)) + min(max(d.x,d.y),0.0);
}

float metaDiamond(vec2 p, vec2 pixel, float r, float s)
{
      vec2 d = abs(r2d(s)*(p-pixel));
      return r / (d.x + d.y);
}

// Original code starts !

vec4 drawAtmoGradient(in vec2 p)
{
     return mix( vec4(1.00,0.50,0.20,1.00),vec4(0.025,0.025,0.10,1.00),0.64*sqrt(abs(p.y)));
}

// This is not really fbm, more like "single octave smoothed noise"
// But it's going to be used in ad-hoc fbm functions later on (jungle canopy, mountains, etc).
float fbm(in vec2 p)
{
      return mix(noise(vec2(floor(p.x))),noise(vec2(floor(p.x + 1.0))), smoothstep(0.0,1.0,fract(p.x)));
}

float drawStars(in vec2 p)
{
      float Disp_Star =       0.000;
      float Buff_Star =       0.000;
      float PosX_Star =       0.000;
      float PosY_Star =       0.000;
      float Dist_Star =       0.000;
      float Magn_Star =       0.000;

      for( float j = 0.0; j < 100.0 ; j++ )
      {
           PosX_Star  = mod((7.0*noise(vec2(j))-3.5) - Disp_Star,7.0) - 3.5;
           PosY_Star  = 0.5+3.5*noise(vec2(j + 176.0));
           Dist_Star  = length(p - vec2(PosX_Star,PosY_Star));
           Magn_Star  = 0.00005*noise(vec2(j + 4.0));
           if( length(vec2(PosX_Star,PosY_Star) - vec2( 0.0, 1.7)) > 0.8
            && length(vec2(PosX_Star,PosY_Star) - vec2( 1.7, 2.5)) > 0.1 )
           {
               if( mod(j,20.0)!=0.0 )
               {
                   // Normal Star
                   Buff_Star += Magn_Star*pow(Dist_Star,-1.6);
               }else{
                   // Bigger star with cross
                   Buff_Star += metaDiamond(p,vec2(PosX_Star,PosY_Star),0.005,0.0);
               };
           };
      };
      return Buff_Star;
}

// Pylons and totems built by Mi-Go tribes (?) to praise Yog-Sothoth
vec4 drawPylons(in vec2 p, vec4 c, float TimeVar)
{
     float Disp_Pylon = TimeVar;
     float PosX_Pylon =     0.0;
     float PosY_Pylon =     0.0;
     float Rand_Pylon =     0.0;

     for( float j = 0.0; j < 10.0 ; j+=1.0 )
     {
          PosX_Pylon = mod((10.0*noise(vec2(j+50.0))-5.0) - Disp_Pylon,10.0) - 5.0;
          PosY_Pylon = 0.0;
          Rand_Pylon = 0.3+0.4*noise(vec2(j));
          c = mix( c,
                     vec4(1.0,0.7,0.4,1.0) - texture(iChannel0,abs(2.0*(p - vec2(PosX_Pylon,3.0*Rand_Pylon)) )),
                     smoothstep(0.005,0.0,sdTriangle(p, vec2(-0.02 + PosX_Pylon,              PosY_Pylon),
                                                        vec2( 0.02 + PosX_Pylon,              PosY_Pylon),
                                                        vec2(        PosX_Pylon, Rand_Pylon + PosY_Pylon))));
      };
      return c;
}

// Adding octaves and tweaking freq,amp,speed until it fits !
// i.e. ad-hoc hand-made "fbm".
float FirstTreeLine(in vec2 p, float TimeVar)
{
      return   0.100*fbm(vec2(  1.0*(p + 0.25*TimeVar)))
             + 0.050*fbm(vec2( 10.0*(p + 0.25*TimeVar)))
             + 0.015*fbm(vec2(100.0*(p + 0.25*TimeVar)))
             + 0.050;
}

float SecondTreeLine(in vec2 p, float TimeVar)
{
      return   0.050*fbm(vec2(  1.0*(p + 0.15*TimeVar)))
             + 0.020*fbm(vec2( 10.0*(p + 0.15*TimeVar)))
             + 0.010*fbm(vec2(100.0*(p + 0.15*TimeVar)))
             + 0.150;
}

float ThirdTreeLine(in vec2 p, float TimeVar)
{
      return   0.070*fbm(vec2(  1.0*(p + 0.05*TimeVar)))
             + 0.008*fbm(vec2( 10.0*(p + 0.05*TimeVar)))
             + 0.004*fbm(vec2(100.0*(p + 0.05*TimeVar)))
             + 0.210;
}

float Mountains(in vec2 p, float TimeVar)
{
      p.x += 100.35; // just for varying the noise signal...
      return   0.250*fbm(vec2(  1.0*(p + 0.025*TimeVar)))
             + 0.020*fbm(vec2( 10.0*(p + 0.025*TimeVar)))
             + 0.200;
}

float MountainsFar(in vec2 p, float TimeVar)
{
      p.x += 15.00; // just for varying the noise signal...
      return   0.200*fbm(vec2(  1.0*(p + 0.0125*TimeVar)))
             + 0.050*fbm(vec2( 10.0*(p + 0.0125*TimeVar)))
             + 0.15;
}

float MountainsTex(in vec2 p, float TimeVar)
{
      return  0.5*fbm(vec2( 20.5*(p + 0.025*TimeVar))) + 0.15;
}

float Clouds(in vec2 p, float TimeVar)
{
      return 0.25*fbm(vec2(  2.0*(p + 0.0125*TimeVar))) + 0.25;
}

float WeedsLine(in vec2 p, float TimeVar)
{
      return   0.0500*fbm(vec2(   1.0*(p + TimeVar)))
             + 0.0250*fbm(vec2( 100.0*(p + TimeVar)))
             + 0.0125*fbm(vec2( 250.0*(p + TimeVar)))
             + 2.5300;
}

vec4 drawRingPlanet(in vec2 p, float TimeVar)
{
     // Gas Giant + Terminator
     vec4 RP = texture(iChannel0,vec2(0.07*p.x - 0.0015*TimeVar,p.y))
              *sdCircle(p,0.8,vec2(0.0,0.0),0.01)
              *smoothstep(1.0,0.0,sdCircle(p,0.88,vec2( 0.020,-0.1),0.1));

     // Closest Part Of Ring
     if( p.y < 0.0 ) RP += (1.0+5.0*p.y)*smoothstep(0.12,0.0,abs(1.0 - dis_e(vec2(0.0, 0.000), 1.8, 0.14, p)))  // Smaller Ring
                         + (1.0+3.0*p.y)*smoothstep(0.12,0.0,abs(1.0 - dis_e(vec2(0.0,-0.005), 2.0, 0.20, p))); // Bigger Ring

     // Furthest Part Of Ring
     if( p.y > 0.0 && length(p) > 0.8 ) RP += smoothstep(0.12,0.0,abs(1.0 - dis_e(vec2(0.0, 0.000), 1.8, 0.14 + 0.14*p.y, p)))
                                            + smoothstep(0.12,0.0,abs(1.0 - dis_e(vec2(0.0,-0.005), 2.0, 0.20 - 0.10*p.y, p)));
     return RP;
}

vec4 drawMagSphere(in vec2 p, float TimeVar)
{
     // Awful mashup of old code and new code. It just works.
     float HeightMagSphere = 0.78 + 0.01*cos(0.1*iTime);
     vec4 ColorMag = texture(iChannel0,0.2*vec2(p.x,p.y + 0.05*iTime))*fbm(vec2(20.0*p.x - 1.0*iTime));
     float MagSphere = texture(iChannel0,vec2(p.x + 0.01*TimeVar,0.01*p.y + 0.01*TimeVar)).x
                      *smoothstep(0.0,1.0,1.0-10.0*(abs(p.y)-(HeightMagSphere + 0.05*fbm(vec2(60.0*p.x + 0.5*TimeVar)))));
     MagSphere *= smoothstep(0.0,0.2,abs(p.y) - HeightMagSphere + 0.1);
     MagSphere *= smoothstep(0.05,0.0,abs(p.x) - sqrt(0.8*0.8-HeightMagSphere*HeightMagSphere));
     p = abs(p);
     MagSphere += ColorMag.x*smoothstep(0.125,0.0,abs(p.y - 2.0*sqrt(p.x - 0.02) - 0.8))
                 *smoothstep(0.9 - 0.5*fbm(vec2(0.2*iTime)),0.0,p.x)*smoothstep(0.0,0.2,length(p)-0.8);
     MagSphere += ColorMag.x*smoothstep(0.025,0.0,abs(p.y - 0.95*sqrt(p.x - 0.05) - 0.8))
                 *smoothstep(0.9 - 0.5*fbm(vec2(0.2*iTime)),0.0,p.x)*smoothstep(0.0,0.2,length(p)-0.8);
     return vec4(0.0,MagSphere,0.0,1.0);
}

// Look, I swear there is a valid chain of events that justifies everything in
// the next procedure. In fact there may be several of them.... which explains
// why it looks so messy, yet somehow succeeds at displaying STEP-PYRAMIDS !!!
// IN FAKE 3D ! WITH FREAKING DEATH MASKS ON THE WALLS ! ENERGY BEAMS ! AND MI-GO !
// IN A CAVE ! WITH A BOX OF SCRAPS !
// Also, French croissant in your face ! :D

vec4 drawShrines(in vec2 p, vec4 c, float TimeVar)
{
     Shadow = 1.0;
     // We're gonna display 10 Step-Pyramids on a threadmill, it's gonna be fun ! :)
     // Also we're going to draw each step as a triangle slice becauuuuuuuse...
     // ...it's harder that way and slower too. What could go wrong ?
     for( float k = 0.0 ; k < 10.0 ; k+=1.0 )
     {
          // Define Step-Pyramids characteristics...
          float Temple_X = mod((20.0*noise(vec2(k+1050.2))-10.0) - (0.08 + 0.0025*k)*TimeVar,20.0) - 10.0;
          float Temple_Size  = 1.2 + 0.4*noise(vec2(k+241.1));
          float height_steps = 0.13;
          float Temple_Style = 3.0+ ceil(3.0*fbm(vec2(4.1*k)));
          float Temple_Y     =  0.0;

          if(abs(Temple_X)< 1.0 && abs(Temple_X) < Shadow)Shadow = abs(Temple_X);

          if( k == 9.0){ Temple_Style = 8.0; Temple_Size = 2.0;}; // at least one Class-VIII Step-Pyramid...

          vec2 TranscendVec  = vec2(0.0); // Texture Offset for special effect

          float ChooseTex = mod(k,3.0);

          if( Temple_Style == 8.0 ) // Special Effects When Class-VIII Step-Pyramid (SP)...
          {
              ChooseTex = 0.0;
              float fbm2 = fbm(vec2(TimeVar + 100.0*Temple_Style));
              float fbm3 = fbm(vec2(0.5*TimeVar + 100.0*Temple_Style));

              c += vec4(1.0,0.9,0.8,0.0)*metaDiamond(p,vec2( Temple_X,(Temple_Style+0.5)*height_steps),0.04 + 0.01*sin(20.0*TimeVar),0.0);

              vec2 PosFungi01 = vec2( Temple_X,2.0 + 1.0*fbm3);
              float DistFungi01  = length(p - PosFungi01);
              if(p.y < PosFungi01.y && fbm2 > 0.5)c += 0.7*smoothstep(0.01,0.00,abs(p.x-Temple_X)-0.01*fbm(vec2(10.0*p.y - 20.0*TimeVar)));
              if(DistFungi01< 0.4)c += vec4(0.15,0.15,1.0,1.0)
                                      *metaDiamond(p,PosFungi01,0.09 + 0.005*sin(25.0*TimeVar + 200.0*Temple_Style),0.0)
                                      *smoothstep(0.2,0.0,DistFungi01 - 0.2);
              vec2 PosFungi02 = vec2( Temple_X -0.7 + 1.4*fbm(vec2(0.5*TimeVar + 200.0*Temple_Style)),
                                      0.8 + 0.8*fbm(vec2(0.3*TimeVar + 20.0*Temple_Style)));
              float DistFungi02  = length(p - PosFungi02);
              if(DistFungi02< 0.8)c += vec4(0.15,0.15,1.0,1.0)
                                      *metaDiamond(p,PosFungi02,0.07 - 0.05*fbm(vec2(1.0*TimeVar)),2.5*fbm(vec2(5.0*TimeVar)))
                                      *smoothstep(0.4,0.0,DistFungi02 - 0.4);
              c += 2.0*fbm2*vec4(0.15,0.15,1.0,1.0)*smoothstep(0.0,0.8,1.0-(20.0 + 30.0*fbm2)*abs(p.x-Temple_X));
          };

          // Don't compute pyramids that are out of the window ! :D
          // This is actually ad-hoc masking... Not a great practice.
          if( abs(p.x - Temple_X) < Temple_Size && p.y < height_steps*(Temple_Style + 2.0) )
          {
              // Make the temple texture scroll when in infrared for extra-spookyness
              // i.e. those shrines are "active" in ways we don't normally see...
              if(mod(TimeVar,SeqLength) > SeqLength/2.0 && Temple_Style==8.0)TranscendVec += vec2(0.1*TimeVar,0.0);

              for( float j = 0.0; j < Temple_Style ; j+=1.0 )
              {
                   if( (p.y - height_steps) >= height_steps*j && (p.y - height_steps) <= height_steps*(j+1.0) )
                   {
                       vec4  Front_Texture; // Front Texture
                       vec4  Back_Texture; // Back Texture
                       // Strangely enough, the human mind will make up faces everywhere provided we
                       // give him a few hints of symetry, so we do exactly that : by mirroring textures
                       // and having a proper level of detail (zoom), we can use innocent looking patterns
                       // (i.e. Shadertoy generic textures) and conjure up demons, skulls and menacing faces
                       // for close to zero computing cost. This also makes excellent mayan-style
                       // or Giger-esque decorations, according to your sensibility. And the best part ?
                       // Most of the effect is actually happening in your brain...
                       float SkullsAndDemons;
                       float Space = 0.1;
                       float Ratio = 2.0;
                       if(mod((p.x - Temple_X)/Space,2.0)<1.0)SkullsAndDemons = mod(abs(p.x - Temple_X + k),Space);
                       else SkullsAndDemons = Space-mod(abs(p.x - Temple_X + k),Space);
                       // Here I initially had a simple switch with a sampler2d variable, but it didn't
                       // compile on Shadertoy. So I had to unroll the whole thing. Never could figure
                       // this one out ! It worked at home, though.
                       // I guess it's not very elegant, but it would allow to specifically customize
                       // every case in clear, soooo it's not that stupid... It bothers me though. :-/
                       if( ChooseTex == 0.0)
                       {
                           Front_Texture = texture(iChannel0,vec2(SkullsAndDemons,Ratio*p.y + 0.5*Temple_Style) + TranscendVec);
                           Back_Texture  = texture(iChannel0,2.0*vec2(p.x - Temple_X,p.y));
                       }else{
                           if( ChooseTex == 1.0)
                           {
                               Front_Texture = texture(iChannel1,vec2(SkullsAndDemons,Ratio*p.y + 0.5*Temple_Style) + TranscendVec);
                               Back_Texture  = texture(iChannel1,2.0*vec2(p.x - Temple_X,p.y));
                           }else{
                               Front_Texture = texture(iChannel2,vec2(SkullsAndDemons,Ratio*p.y + 0.5*Temple_Style) + TranscendVec);
                               Back_Texture  = texture(iChannel2,2.0*vec2(p.x - Temple_X,p.y));
                           };
                       };
                       vec4 ColorGlint = vec4(0.8,0.6,0.3,1.0);
                       // Back of the SP
                       c = mix(c,(ColorGlint+0.7*Back_Texture) - 0.3*smoothstep(0.02,0.0,p.y - height_steps*(j+1.0)),
                                       smoothstep(0.01,0.0,sdTriangle(p,     vec2(Temple_X - Temple_Size/2.0 - 0.100*Temple_X,Temple_Y               - height_steps*j),
                                                                             vec2(Temple_X + Temple_Size/2.0 - 0.100*Temple_X,Temple_Y               - height_steps*j),
                                                                             vec2(Temple_X +                              0.0,Temple_Y + Temple_Size - height_steps*j))));
                       // Lines on the sides
                       c -= vec4(0.5)*smoothstep(0.005,0.0,abs(sdTriangle(p, vec2(Temple_X - Temple_Size/2.0 - 0.033*Temple_X,Temple_Y               - height_steps*j),
                                                                             vec2(Temple_X + Temple_Size/2.0 - 0.033*Temple_X,Temple_Y               - height_steps*j),
                                                                             vec2(Temple_X +                              0.0,Temple_Y + Temple_Size - height_steps*j))));
                       c -= vec4(0.5)*smoothstep(0.005,0.0,abs(sdTriangle(p, vec2(Temple_X - Temple_Size/2.0 - 0.066*Temple_X,Temple_Y               - height_steps*j),
                                                                             vec2(Temple_X + Temple_Size/2.0 - 0.066*Temple_X,Temple_Y               - height_steps*j),
                                                                             vec2(Temple_X +                              0.0,Temple_Y + Temple_Size - height_steps*j))));

                       // Front of the SP
                       float PyramidStage = sdTriangle(p, vec2(Temple_X - Temple_Size/2.0,Temple_Y               - height_steps*j),
                                                          vec2(Temple_X + Temple_Size/2.0,Temple_Y               - height_steps*j),
                                                          vec2(Temple_X +             0.0,Temple_Y + Temple_Size - height_steps*j));

                       float AdditionalDeco = smoothstep(0.01,0.0,abs(p.y - height_steps*(j+1.97)))*smoothstep(0.0,0.75,abs(p.x-Temple_X));

                       // Add some highlights on each step
                       c = mix(c,ColorGlint*(0.1+0.05*j) + 0.5*Front_Texture
                                       - 0.1*smoothstep(0.025,0.0,p.y - height_steps*(j+1.0))
                                       + 1.0*ColorGlint*AdditionalDeco,
                                       smoothstep(0.001,0.0,PyramidStage));
                       c += 1.0*ColorGlint*smoothstep(0.005,0.0,abs(PyramidStage))*smoothstep(0.0,0.025,p.y - height_steps*(j+1.0));
                   };
                   if( Temple_Style == 8.0 )
                   {
                       c += vec4(1.0,0.5,0.2,1.0)*metaDiamond(p,vec2( Temple_X,6.1*height_steps),0.015,0.0)
                                                 *smoothstep(0.1,0.0,length(p-vec2(Temple_X,6.1*height_steps)));
                       if( j < 7.0 && p.y < height_steps*(j+1.0))
                       {
                           c+= (1.0+(1.0-Shadow))*vec4(1.0,1.0,0.1,1.0)*texture(iChannel0,p*vec2(1.0,0.1) + vec2((0.08 + 0.0025*k)*TimeVar,0.01*TimeVar + 0.1*j))*smoothstep(0.1,0.00,abs(p.x-Temple_X) - 0.03*(5.0-j));
                           c+= 0.28*vec4(1.0,0.5,0.2,1.0)*smoothstep(0.2,0.00,abs(p.x-Temple_X) - 0.05*(5.0-j));
                       };
                   };
              };
              // Add Stairs (...which begs the question : if the Mi-Go built these structures, why the steps ? These morons can fly, FFS ?!)
              if( Temple_Style < 6.0 || Temple_Style == 8.0)
              {
                  float S = abs(p.x - Temple_X) - 0.1 + 0.55*p.y/Temple_Style - 0.04*mod(p.y,height_steps);
                  float Stairs  = smoothstep(0.01,0.0,S);
                  float Ramps   = smoothstep(0.005,0.0,abs(S));
                  c = mix(c,0.9*texture(iChannel2,p + vec2((0.08 + 0.0035*k)*TimeVar,0.0) ) + 0.1*sin(750.0*p.y),
                                                            0.45*Stairs*smoothstep(0.001,0.0,p.y - Temple_Style*height_steps));
                  c = mix(c,0.1*texture(iChannel2,p + vec2((0.08 + 0.0025*k)*TimeVar,0.0) ),0.5*Ramps*smoothstep(0.001,0.0,p.y - Temple_Style*height_steps));
              };
          };
     };
     return c;
}

vec4 drawTunnel(in vec2 p, vec4 CS,sampler2D tex, float TimeVar)
{
     // Modified tunnel effect for the Nebula
     float angle = atan(p.y/p.x);
     float dist  = length(p);
     vec3  Tunnel;
     Tunnel = texture( tex,vec2( 0.080*(1.0/dist) + 0.3  + 0.01*TimeVar, angle/PI + 1.5*dist + 0.01*TimeVar)).xyz;
     Tunnel += smoothstep(0.2,0.0 ,dist);
     Tunnel -= smoothstep(0.0,0.05,dist);
     return vec4(clamp(Tunnel,0.0,1.0),1.0);
}

vec4 drawSpacePlane(in vec2 p, vec4 col, float TimeVar)
{
     // It is 2023 and we still have no SSTO spaceplane.
     // if it does not make you angry, well it should.
     // Less bloody cubesats, more spaceplanes !
     vec2 PosSpaceplane = vec2( 0.8*cos(0.1*TimeVar), 1.5 + 0.35*sin(0.1*TimeVar));

     float ProfilContrail = 0.005*fbm(vec2(10.0*p.x + 10.0*TimeVar));
     float Contrail       = smoothstep(0.0,0.005,abs(p.y - (PosSpaceplane.y - 0.02)) - ProfilContrail);

     // Contrail, because even with a cloaking hull, water vapor
     // in the atmosphere does not care...
     col += 0.25*smoothstep(0.3,0.0,p.x-PosSpaceplane.x + 0.65)*(1.0-vec4(Contrail));

     // 3-Triangles Super Concorde
     float SC01 = 0.0;
     SC01 = min(smoothstep(0.0,0.005, sdTriangle( p - PosSpaceplane,
                                                  vec2(-0.30, 0.0 ),
                                                  vec2( 0.32, 0.005 ),
                                                  vec2(-0.36,-0.04))),
                smoothstep(0.0,0.002, sdTriangle( p - PosSpaceplane,
                                                  vec2(-0.45, 0.0 ),
                                                  vec2(-0.30, 0.0 ),
                                                  vec2(-0.33,-0.02))));
     SC01 = min(SC01,smoothstep(0.0,0.005, sdTriangle( p - PosSpaceplane,
                                                  vec2(-0.39, 0.0 ),
                                                  vec2(-0.36, 0.05),
                                                  vec2(-0.30, 0.0 ))));
     SC01 = 1.0-SC01;

     // Oscillating Cloaking Factor due to high EM levels and faulty breakers...
     float CloakingFactor = 0.25 + 0.25*sin(-PI/2.0+0.5*TimeVar);
     // Clipping the tail of Super Concorde for signature profile...
     if(p.y < (PosSpaceplane.y + 0.04))col = mix(col,vec4(0.0),CloakingFactor*SC01);

     return col + CloakingFactor*abs(sin(4.0*TimeVar))*metaDiamond(p,PosSpaceplane + vec2(-0.36,0.05),0.003,5.0*TimeVar);
}

vec4 drawArcadesOfYuk(in vec2 p, vec4 c, float TimeVar)
{
     // Draw "The Arcades of Yuk". Time Of Construction : Unknown.
     float fbmArk = fbm(vec2(20.0*p.x + 16.0*TimeVar));
     float noise1 = noise(vec2(floor(5.0*p.x + 4.0*TimeVar)));
     c = mix(c,0.8*texture(iChannel1,vec2(mod(0.5*p.x + 0.4*TimeVar,3.4),p.y)),
               smoothstep(0.01,0.0, p.y - 2.654 + 0.1*noise1 + 0.005*fbmArk)
              *smoothstep(0.0,0.01, p.y - (1.90 + 0.5*abs(cos((p.x - 0.15 + 0.8*TimeVar)*PI/3.4 + PI/2.0)) + 0.01*fbmArk)));

     if( p.y < 3.0 + 0.05*sin((10.0*3.4/PI)*(p.x + 0.8*TimeVar))) // Top Columns
     {
         if( mod(p.x - 0.02*sin(10.0*p.y + PI/4.0) + 0.8*TimeVar,3.4) - 0.3 + 0.04*sin(10.0*p.y + PI/4.0) < 0.0 )
         {
             if( p.y > 0.25)
             {
                 c = texture(iChannel1,vec2(0.05*sin(mod(p.x + 0.8*TimeVar,3.4)*PI/0.3),0.5*p.y + 0.85))
                    *smoothstep(1.0,0.0,0.8*sin(PI*mod(p.x + 0.8*TimeVar,3.4)/0.3));
             }else{
                 c = texture(iChannel2,vec2(0.1*sin(mod(p.x + 0.8*TimeVar,3.4)*PI/0.3),p.y))
                    *smoothstep(1.0,0.0,0.8*sin(PI*mod(p.x + 0.8*TimeVar,3.4)/0.3));
             };
         };
     };

     // Weeds have grown on top...
     c = mix(c,
               vec4(0.7,1.0,0.5,1.0)*(0.5+0.5*texture(iChannel0,vec2(1.0*p.x + 0.8*TimeVar,0.1*p.y))),
               smoothstep(0.01,0.0,(p.y - 1.01*WeedsLine(1.0*p + vec2(100.0),0.8*TimeVar)))*
               smoothstep(0.0,0.01,p.y - (2.65 - 0.1*noise1)));

     // Top
     float fbmTop = fbm(vec2(20.0*p.x + 16.0*TimeVar));
     c = mix(c,
               0.2*texture(iChannel1,vec2(mod(0.5*p.x + 0.4*TimeVar,3.4),p.y)),
               smoothstep(0.01,0.00, p.y - (2.65 - 0.1*noise1 - 0.005*fbmTop))*
               smoothstep(0.00,0.01, p.y - (2.0 + 0.5*abs(cos((p.x - 0.15 + 0.8*TimeVar)*PI/3.4 + PI/2.0)) - 0.02*fbmTop)));

     return c;
}

vec4 drawPentag(in vec2 p, vec4 CS)
{
     p += vec2(0.0,-1.7);
     p *= r2d(- 0.3*TimeVar);

     CS *= fbm(vec2(2.0*TimeVar));
     float Penta;
     vec4 Penta_Color = vec4(0.0,0.0,0.0,1.0);
     // Lets draw a protection seal...
     for( int i =0; i< 5; i++)
     {
          Penta = p.x + 0.35;
          Penta_Color += CS*smoothstep(0.007,0.0,abs(p.y-Penta));
          Penta_Color += 0.25*CS*smoothstep(0.07,0.0,abs(p.y-Penta));
          p *= r2d(PI*2.0/5.0);
     };
     // Draw Echo Lines ("Repel Vaporous Emanations 75% more !",
     // 1985, Egon Spengler, Peter Venkman, Ray Stantz et alia)
     /*p *= r2d(0.6*iTime); // counter-rotating echo lines...
     for( int i =0; i< 15; i++)
     {
          Penta = p.x + 0.3;
          Penta_Color += 0.5*CS*(1.0-smoothstep(0.0,0.004,abs(p.y-Penta)));
          p *= r2d(PI*2.0/15.0);
     };*/
     Penta_Color += CS*smoothstep(0.005,0.00,abs(length(p) - 0.8) - 0.003);
     return Penta_Color;
}

vec4 drawTitle(vec4 c, float TimeVar)
{
     vec2 logo_p = last_p;

     vec4 ColorBeyond = vec4(0.70,1.00,0.00,1.00);
     vec4 ColorACW    = vec4(0.99,0.50,0.20,1.00);

     if( mod(TimeVar,SeqLength/2.0) > SeqLength/4.0)
     {
         ColorBeyond = vec4(0.99,0.50,0.20,1.00);
         ColorACW    = vec4(0.70,1.00,0.00,1.00);
     };

     logo_p = last_p*3.2;  // Re-init !
     logo_p *= r2d(TiltX);
     logo_p *= (1.0+0.3*AltiY);
     c += drawPentag(logo_p,ColorBeyond);
     logo_p = last_p*3.2;  // Re-init !

     logo_p = last_p + vec2(0.0,-0.15);

     float EyeBlower = clamp(0.25*(sin(100.0*length(logo_p-vec2(0.5*sin(TimeVar),0.5*cos(TimeVar))) - 10.0*TimeVar)),0.0,1.0);

     c -= 0.5*smoothstep(0.15,0.0,abs(logo_p.y-0.015*fbm(vec2(2.0*logo_p.x+10.0*TimeVar)) - 0.27) - 0.1);

     Centrage = vec2(-0.171, 0.795);

     // Beyond - Blur

     for( float k = 0.0 ; k < 20.0 ; k++ )
          for( float i = 0.0; i < 6.0; i++ )
               c += (0.2-k*0.01)*(ColorBeyond-EyeBlower)*traceChar(logo_p*(1.4*0.35 + k*0.008),float(TxtTitle1[int(i)]), Centrage + vec2(0.056*mod(i,33.0),0.0));

     // Beyond - Clear

     for( float i = 0.0; i < 6.0; i++ )
          c += 2.0*(ColorBeyond - EyeBlower)*traceChar(logo_p*1.4*0.35,float(TxtTitle1[int(i)]), Centrage + vec2(0.056*mod(i,33.0),0.0));

     // A Colder War

     Centrage = vec2(-0.445, 0.200);

     for( float i = 0.0; i < 12.0; i++ )
          c += 2.5*( ColorACW - EyeBlower)*traceChar(logo_p*1.4,float(TxtTitle2[int(i)]), Centrage + vec2(0.076*mod(i,33.0),0.4));

     return c;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
     vec2 p = vec2( (iResolution.x/iResolution.y) * (fragCoord.x - iResolution.x/2.0) / iResolution.x,
                    fragCoord.y / iResolution.y);

     // Prepare for a lot of seemingly arbitrary (and stupid) decisions :
     // you know... ART ! :D It doesn't make sense, and it doesn't need to !
     // Here goes :

     TimeVar = mod(1.0*iTime,278.437);

     TiltX = -0.0001*(iMouse.x - iResolution.x/2.0);
     AltiY =  0.0020*(iMouse.y - iResolution.y/2.0);

     // Save before screwing up (...because we will , my precious, we will)
     last_p = p;

     // Render with lower rez when "military imaging". It's 1996 after all...
     if( mod(TimeVar,SeqLength) > SeqLength/2.0){ p = 0.004*floor(250.0*p); };

     // Zoom just a bit...
     p = p * 3.2;

     // Small Gate-Travel effect at the beginning...
     // It costs nothing and doesn't look bad. :)
     if(TimeVar<SeqLength/8.0)p.x = (r2d(3.0*(TimeVar-SeqLength/8.0)/length(p - vec2(0.0,1.5)))*p).x;

     // User-induced chaos reduced to a minimum this time.
     p *= r2d(TiltX);
     p *= (1.0+0.3*AltiY);

     // The World begins in darkness.
     // Wether it also ends that way is ours to decide.
     vec4 col = vec4(0.0,0.0,0.0,1.0);

     // Tunnel Nebula
     vec4 Nebula = vec4(0.0,0.0,0.0,1.0);
     Nebula += 0.08*drawTunnel(0.025*(p + vec2( 0.0,-0.5)), vec4(1.0), iChannel0,TimeVar);
     Nebula += 0.08*drawTunnel(0.025*(p + vec2( 0.0,-0.5)), vec4(1.0), iChannel2,TimeVar);
     col += 0.6*Nebula*smoothstep(0.0,0.02,length(p-vec2(0.0, 1.7))-0.78);

     // Atmosphere
     col += drawAtmoGradient(p);

     // "THE STARS ARE RIGHT. THEY HAVE NO MERCY !" ...tagline of the movie poster !
     col += drawStars(p);

     // Add green glow over the poles since the star is flaring ("Check your fucking dosimeters, marines !")
     col += 0.25*abs(sin(0.15*TimeVar))*drawMagSphere(r2d(1.1*PI)*(p + vec2( 0.0,-1.7)),TimeVar);
     // Draw the Giant and Rings (thanks Bonestell for inspiration)
     col += 0.7*drawRingPlanet(r2d(1.1*PI)*(p + vec2( 0.0,-1.7)),TimeVar);
     // Satellite 1
     col += 0.5*clamp(sdCircle(p,0.10,vec2(1.700,2.50), 0.01) - sdCircle(p,0.10,vec2(1.705,2.51), 0.01),0.0,1.0);

     // Add colors in atmo (better colors)
     col *= 2.00;
     col += vec4(1.0,1.0,0.0,1.0)*smoothstep(0.0,1.0,1.0-0.85*sqrt(p.y));
     // Add low clouds on the horizon...
     col += smoothstep(0.08,-0.04,abs(p.y - 0.45))*smoothstep(0.09,0.0,p.y-Clouds(p + vec2(50.0),TimeVar));

     // Draw the main sun
     col += vec4(1.0,0.9,0.7,1.0)*sdCircle(p,0.4,vec2(0.0,0.35),0.05);
     // Draw the distant sun
     col += metaDiamond(p,vec2( 0.0,0.80),0.02,0.0);

     // Distant Mountains
     col = mix(col,vec4(0.7,0.4,0.3,1.0),smoothstep(0.03,0.0,p.y - MountainsFar(p + vec2(400.0),TimeVar)));

     // Draw Mountains and slanted shadows...
     col = mix( col,
                vec4(0.4,0.2,0.2,1.0)-0.05*smoothstep(0.00,0.1,p.y - MountainsTex(p + vec2(0.5*p.y,800.0),TimeVar)),
                smoothstep(0.01,0.0,p.y - Mountains(p + vec2(400.0),TimeVar)));

     // Draw Distant Jungle Line
     col = mix(col,
               vec4(0.2,0.3,0.2,1.0)*(0.5+0.5*texture(iChannel0,0.1*(p + vec2(0.05*TimeVar,0.0)))),
               smoothstep(0.01,0.0,p.y - ThirdTreeLine(p + vec2(100.0),TimeVar)));

     // Draw le Super Concorde
     col = drawSpacePlane(p*1.4,col,TimeVar);

     // Draw The Ten Thousand Shrines Of Yuk (*tribal screams of madness*)
     col = drawShrines(p,col,TimeVar);

     // Draw the Pylons of Yog-Sothoth (*louder tribal screams of madness*)
     if(p.y<0.6)col = drawPylons(p,col,0.12*TimeVar);

     // Draw Medium Jungle Line
     col = mix(col,vec4(0.3,0.4,0.3,1.0)*(0.7+0.3*texture(iChannel0,1.0*(p + vec2(0.15*TimeVar,0.0)))),
           smoothstep(0.008,0.0,p.y - SecondTreeLine(p + vec2(1.0),TimeVar)));

     // Draw Front Jungle Line
     col = mix(col,vec4(0.5,0.6,0.5,1.0)*(0.6+0.4*texture(iChannel0,4.0*(p + vec2(0.25*TimeVar,0.0)))),
           smoothstep(0.008,0.0,p.y - FirstTreeLine(p + vec2(1.0),TimeVar)));

     p *= 1.0/(1.0+0.2*AltiY);

     col = drawArcadesOfYuk(p*(1.1+0.5*AltiY),col,TimeVar);

     col -= 0.15*(1.0-Shadow);

     p *= r2d(-1.0*TiltX);

     // Texts

     p = last_p*3.2;  // Re-init !

     // "Level" tells which song sequence we are currently in
     // Each sequence is divided into 2 parts : first one normal rendering, second one tactical imaging.
     Level = int(floor(TimeVar/SeqLength));

     // Tactical imaging sequences
     if( mod(TimeVar,SeqLength) > SeqLength/2.0)
     {
         if( Level != 0 ) // Except for Title Screen...
         {
             // Print references for military archives...
             Centrage = vec2(-0.602+0.028*last_p.x/2.0,0.4);
             for( float i = 0.0; i < 43.0; i++ )
                  col += 2.5*vec4(0.0,1.0,0.0,1.0)*traceChar(last_p*1.9,float(TxtIRView[int(i)]), Centrage + vec2(0.028*mod(i,43.0),0.5));
         };

         if(int(mod(TimeVar/SeqLength,2.0))>0)
         {
            // Yellow-Green Color (old night-vision color scheme)
            col = vec4(0.4*col.g,0.6*col.g,0.0,1.0);
         }else{
            // Greyscale (cheap combat cameras)
            col = 0.75*col.yyyy;
         };

         // EyeBlower / Interferences ("The gas giant's magnetosphere makes everything worse !")
         col -= 0.005*(sin(80.0*length(p-vec2(0.5*sin(TimeVar),0.5*cos(TimeVar))) - 20.0*TimeVar) + sin(80.0*length(p-vec2(0.0,0.0)) - 20.0*TimeVar));
         // Old LED Matrix Display
         if(mod(fragCoord.y,4.0) > 2.0 && mod(fragCoord.x,4.0) > 2.0) col = clamp(col*2.5,0.0,1.0);

         // Title logo BEYOND A COLDER WAR
         if( Level == 0 || Level >= 7 )col = drawTitle(col,TimeVar);

     }else{
         // Color Keying for normal view... I went for a red-orange apocalyptic feel.
         col *= vec4(1.0,0.7,0.5,1.0);
     };

     if( mod(TimeVar,SeqLength) < SeqLength/2.0)
     {
         if( Level >= 7 )col = drawTitle(col,TimeVar);

         // Draw Comic Panel

         // Getting text coords by sequence...
         vec2 TxtSpan = vec2(0,0);
         switch( Level )
         {
                 case 0 : TxtSpan = vec2(  0.0,  0.0);break;
                 case 1 : TxtSpan = vec2(  0.0,238.0);break;
                 case 2 : TxtSpan = vec2(239.0,423.0);break;
                 case 3 : TxtSpan = vec2(424.0,594.0);break;
                 case 4 : TxtSpan = vec2(595.0,774.0);break;
                 case 5 : TxtSpan = vec2(  0.0,  0.0);break;
                 case 6 : TxtSpan = vec2(  0.0,  0.0);break;
                 case 7 : TxtSpan = vec2(775.0,860.0);break;
         };
         if( Level != 7 )
         {
             // Opening Texts
             Centrage = vec2(0.0,-2.80);
         }else{
             // Ending Text
             Centrage = vec2(0.0,-0.63);
         };

         if( (Level > 0 && Level < 5) || Level == 7)
         {
             // draw text panels
             col = mix(col,vec4(0.0,0.0,0.0,1.0), 0.5*smoothstep(0.02,0.0,    sdBox(p + vec2(-0.05,Centrage.y + ((TxtSpan.y - TxtSpan.x)/50.0) * 0.0625/2.0 + 0.025 ), vec2( 60.0*0.028       , ((TxtSpan.y - TxtSpan.x)/50.0 + 1.0) * 0.0625))-0.005));
             col = mix(col,vec4(1.0,1.0,0.9,1.0),     smoothstep(0.01,0.0,    sdBox(p + vec2( 0.00,Centrage.y + (TxtSpan.y - TxtSpan.x)/50.0 * 0.0625/2.0 - 0.05  ), vec2( 60.0*0.028       , ((TxtSpan.y - TxtSpan.x)/50.0 + 1.0) * 0.0625))-0.005));
             col = mix(col,vec4(0.0,0.0,0.0,1.0),     smoothstep(0.01,0.0,abs(sdBox(p + vec2( 0.00,Centrage.y + (TxtSpan.y - TxtSpan.x)/50.0 * 0.0625/2.0 - 0.05  ), vec2( 60.0*0.028 - 0.01, ((TxtSpan.y - TxtSpan.x)/50.0 + 1.0) * 0.0625  -0.005)))));
         };

         // Draw Text in the Panel
         // Once again, with hand-masking to speed things up a little bit...

         vec4 AHC;
         if( Level != 7 )
         {
             Centrage = vec2(0.0 - 56.0*0.028/2.0,-0.57);
             AHC = vec4(-17.0*0.028,17.0*0.028,0.77,0.93);
         }else{
             Centrage = vec2(0.0 - 56.0*0.028/2.0, 0.61);
             AHC = vec4(-17.0*0.028,17.0*0.028,0.15,0.25);
         };
         float LineHeight = 0.0;
         float CurrentPos = 0.0;
         int   CursorPos  = 0;
         if( last_p.y > AHC[2] && last_p.y < AHC[3] && last_p.x > AHC[0] && last_p.x < AHC[1] )
         {
             for( float i = TxtSpan.x ; i < TxtSpan.y; i++ )
             {
                  if(TxtIntro[int(i)]!=32)col -= traceChar(last_p*1.7,float(TxtIntro[int(i)]), Centrage + vec2(CurrentPos ,0.0 + LineHeight));
                  if( CursorPos > 50 && TxtIntro[int(i)]==32){ CurrentPos = 0.0; LineHeight += 0.05; CursorPos = 0; }else{ CursorPos += 1; CurrentPos += 0.028; };
             };
         };
     };

     // Resetting p
     if( mod(TimeVar,SeqLength) > SeqLength/2.0) p = last_p * 3.2;

     // Draw panel borders...
     col = mix( col, vec4(1.0,1.0,0.9,1.0),smoothstep(0.00,0.01,    sdBox(p + vec2(0.0,-3.2/2.0),vec2(1.6*iResolution.x/iResolution.y - 0.07,1.6*1.0-0.07))));
     col = mix( col, vec4(0.0,0.0,0.0,1.0),smoothstep(0.01,0.00,abs(sdBox(p + vec2(0.0,-3.2/2.0),vec2(1.6*iResolution.x/iResolution.y - 0.05,1.6*1.0-0.05)))));

     // "I have harnessed the shadows that stride from world to world to sow death and madness !"
     fragColor = col;
}
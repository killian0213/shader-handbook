// Buffer A (buffer) — A Flimsy Rocket Paperplane... by msm01
// https://www.shadertoy.com/view/dlfXzl

mat2 r2d( float a ){ float c = cos(a), s = sin(a); return mat2( c, s, -s, c ); }
float noise(vec2 st) { return fract( sin( dot( st.xy, vec2(12.9898,78.233)))*43758.5453123 ); }

// Basic Geometry Functions.

float sdCircle(in vec2 p, float radius, vec2 pos, float prec)
{
      return smoothstep(0.0,prec,radius - length(pos-p));
}

// This belongs to Iq...
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

// This belongs to a nice shadertoy coder whose name I lost.
// Please tell me if you read this !
float metaDiamond(vec2 p, vec2 pixel, float r, float s)
{
      vec2 d = abs((p-pixel));
      return r / (d.x + d.y);
}

// That's it guys, everything else is mine.

vec4 drawAtmoGradient(in vec2 v_p)
{
     return mix( vec4(1.0,0.6,0.1,1.00),vec4(0.5,0.2,0.5,1.00),sqrt(abs(2.7*v_p.y)) - 1.0);
}

// Simple Value Noise Please
float fbm(in vec2 v_p)
{
      float VarX1 = 0.0;
      float VarX2 = 0.0;
      float VarD0 = 0.0;
      float VarS1 = 0.0;
      float Amplitude = 1.0/2.0;
      float Periode   = 2.0;
      VarX1 = Amplitude*floor( Periode*v_p.x);
      VarX2 = Amplitude*floor( Periode*v_p.x + 1.0);
      VarD0 = fract( Periode*v_p.x);
      VarS1 += mix( noise(vec2(VarX1)), noise(vec2(VarX2)), smoothstep( 0.0, 1.0, VarD0));
      return VarS1;
}

// A starfield
float drawStars(in vec2 v_p)
{
      float Disp_Star = 0.000;
      float Accu_Star = 0.000;
      float PosX_Star = 0.000;
      float PosY_Star = 0.000;
      float Dist_Star = 0.000;

      for( int j = 0; j < 50 ; j++ )
      {
           PosX_Star  = mod((4.0*noise(vec2(j))-2.0) - Disp_Star,4.0) - 2.0;
           PosY_Star  = 1.9*noise(vec2(j + 2))+ 0.5;
           Dist_Star  = length(v_p - vec2(PosX_Star,PosY_Star));
           Accu_Star += 0.0002*pow(Dist_Star,-1.1);
      };
      return Accu_Star;
}

// Text function...
vec4 traceChar( in vec2 v,float charac, vec2 PosTxt)
{
     vec4 colorT = vec4(0.0,0.0,0.0,1.0);
     v = vec2(v.x, 1.0-v.y);
     float DispY,DispX;
     DispX = mod(charac,16.0)/16.0;
     DispY = floor(charac/ 16.0)/16.0;

     if( v.x > PosTxt.x
      && v.x < PosTxt.x + 1.0/16.0 )
     {
         if( v.y > PosTxt.y
          && v.y < PosTxt.y + 1.0/16.0 )
         {
             colorT += texture(iChannel3,
                               vec2( DispX + (v.x-PosTxt.x),-DispY - (v.y-PosTxt.y)) ).xxxx;
         };
     };
     return colorT;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
     vec2 p = vec2( (iResolution.x/iResolution.y)
                  * (fragCoord.x - iResolution.x/2.0)
                  / iResolution.x,
                    fragCoord.y / iResolution.y);

     float TiltX =  -0.001*(iMouse.x - iResolution.x/2.0);
     float AltiY =   0.005*(iMouse.y - iResolution.y/2.0);

     vec4 col = vec4(0.0,0.0,0.0,1.0);
     
     float Beat = 64.0/MusicTimeBase;

     if( ( TimeVar > 2.0*MusicTimeBase && TimeVar < 3.0*MusicTimeBase ) ||
         ( TimeVar > 4.0*MusicTimeBase && TimeVar < 5.0*MusicTimeBase )    )
     {
         p = 0.0075*floor(133.333*p); // Pixel Mode
     };

     vec2 last_p = p;

     col = drawAtmoGradient(p);

     // Zoom back during the entire show
     p *= (1.0 + 0.005*TimeVar);

     // Random global animations/zooms/rotations at some timecodes...
     if( ( TimeVar > 4.0*MusicTimeBase )
     &&  ( TimeVar < 5.0*MusicTimeBase ) )
     {
         p *= r2d(0.20*fbm(vec2(floor(TimeVar*Beat))) - 0.1);
         p *= 1.0+(0.20*fbm(vec2(floor(TimeVar*Beat))) - 0.1);
     };

     // Draw starfield but not on the three planets !
     if( length(p - vec2( 0.70,0.90)) - 0.09 > 0.0
      && length(p - vec2(-0.60,0.75)) - 0.19 > 0.0 
      && length(p - vec2( 0.74,0.92)) - 0.03 > 0.0  )
     {
        col = mix(col,vec4(1.0),drawStars(p));
     };

     // Stars and planets
     Beat = 4.0/MusicTimeBase;
     col += vec4(1.0,0.5,0.2,1.0)*sdCircle(p,0.14 + 0.01*sin(TimeVar*3.14/Beat),vec2(0.0,0.9),0.1);
     col += vec4(1.0,0.4,0.1,1.0)*metaDiamond(p,vec2(0.0,0.9),0.05,0.0);
     col += vec4(1.0,0.7,0.5,1.0)*metaDiamond(p,vec2(0.15,0.8),0.008 + 0.003*sin(TimeVar*3.14/(0.5*Beat) + 3.14),0.0);

     // Anamorphic streak
     col += vec4(0.35,0.25,0.0,1.0)
            *smoothstep(0.025,0.0,abs(sin(p.y - 0.9))      )
            *smoothstep(0.000,0.5,abs(cos(p.x      )) - 0.7);

     // Planet 1
     float FD1 = sdCircle(p,0.10,vec2( 0.70, 0.9), 0.01);
     float DS1 = sdCircle(p,0.17,vec2( 0.75, 0.9), 0.07);
     float Croissant1 = FD1 - DS1;
     col += clamp(Croissant1,0.0,1.0);

     // Planet 2
     float FD2 = sdCircle(p,0.20,vec2(-0.60, 0.75), 0.01);
     float DS2 = sdCircle(p,0.27,vec2(-0.64, 0.74), 0.07);
     float Croissant2 = (FD2 - DS2);
     col += 0.2*FD2*texture(iChannel2,p);
     col += clamp(Croissant2,0.0,1.0);

     // Planet 3
     float FD3 = sdCircle(p,0.03,vec2( 0.74, 0.92), 0.005);
     float DS3 = sdCircle(p,0.04,vec2( 0.76, 0.92), 0.010);
     float Croissant3 = (FD3 - DS3);
     col += 0.1*FD3*texture(iChannel2,p);
     col += 0.25*clamp(Croissant3,0.0,1.0);

     // Mountains
     col = mix(col,
               vec4(0.35,0.15,0.15,1.0),
               smoothstep(0.007,0.0,p.y - 0.04*fbm(vec2(7.0*p.x))  - 0.41) );
     // Mountains Highlights
     col += vec4(0.2,0.17,0.10,1.0)
           *texture(iChannel0,p)
           *fbm(vec2(20.0*p.x))
           *smoothstep(0.01,0.0,p.y - 0.04*fbm(vec2(7.0*p.x))  - 0.41);

     // Ground Color
     col = mix(col,vec4(0.3,0.1,0.1,1.0),smoothstep(0.001,0.0,p.y - 0.40) );

     // Dome City

     // Structural Ellipsis - background
     float Factor01 = 0.4 + 0.1*TimeVar;
     if( p.y > 0.4325 && (r2d(Factor01)*(p-vec2( 0.0,0.42))).y < 0.0 )
         col += 0.1
                *vec4(1.0,1.0,0.2,1.0)
                *smoothstep(0.0001,0.0,abs(dis_e(vec2(0.0,0.0),4.2,1.5,r2d(Factor01)*(p-vec2( 0.0,0.42))) - 0.005));
     Factor01 = 2.5 - 0.1*TimeVar + 3.14159/2.0;
     if( p.y > 0.4325 && (r2d(Factor01)*(p-vec2( 0.0,0.42))).y < 0.0 )
         col += 0.1*vec4(1.0,1.0,0.2,1.0)*smoothstep(0.0001,0.0,abs(dis_e(vec2(0.0,0.0),4.2,1.5,r2d(Factor01)*(p-vec2( 0.0,0.42))) - 0.005));

     if( p.y > 0.4 )
     {
         if( (length(p - vec2(0.0, 0.42)) - 0.25) < 0.0)
         {
             // Draw the skyline like it's drenched in sunlight, with an offset
             p += vec2(sign(p.x)*0.004,-0.005);
             col += 2.0*vec4(1.0,0.7,0.6,1.0)
                    *texture(iChannel2,vec2(0.4,20.0)*p).xxxx
                    *(0.1+0.9*smoothstep(0.0,0.99,fbm(vec2(120.0*p.x + 250.5))))
                    *smoothstep(0.004,0.0,p.y - 0.19*fbm(vec2(floor(50.0*p.x)))- 0.02*fbm(vec2(floor(70.0*p.x))) - 0.42);
             p -= vec2(sign(p.x)*0.004,-0.005);

             // Draw the real Skyline
             col = mix(col,
                       3.5*vec4(0.8,0.6,0.5,1.0)*texture(iChannel2,vec2(0.4,20.0)*p).xxxx
                       *(0.1+0.9*smoothstep(0.0,0.99,fbm(vec2(120.0*p.x + 250.5)))),
                       smoothstep(0.004,0.0,p.y - 0.19*fbm(vec2(floor(50.0*p.x))) - 0.02*fbm(vec2(floor(70.0*p.x))) - 0.42));

             // Draw the smaller skyline like it's drenched in sunlight, with an offset
             p += vec2(sign(p.x)*0.002,-0.004);
             col = mix(col,
                       5.0*vec4(1.0,0.5,0.4,1.0)
                       *texture(iChannel2,vec2(0.4,20.0)*p)
                       *(1.0-0.95*smoothstep(0.0,0.9,fbm(vec2(100.0*p.x)))),
                       smoothstep(0.004,0.0,p.y - 0.10*fbm(vec2(floor(40.0*p.x)))  - 0.42));
             p -= vec2(sign(p.x)*0.002,-0.004);

             // Draw the smaller Skyline
             col = mix(col,
                       vec4(0.8,0.5,0.4,0.8)
                       *texture(iChannel2,vec2(0.4,20.0)*p)
                       *(2.0-1.95*smoothstep(0.0,0.9,fbm(vec2(100.0*p.x)))),
                       smoothstep(0.004,0.0,p.y - 0.10*fbm(vec2(floor(40.0*p.x)))  - 0.42));

             // Add some trees at the bottom... :)
             col = mix(col,vec4(0.1,0.5,0.1,1.0)*texture(iChannel0,2.0*p),smoothstep(0.0025,0.0,p.y - 0.01*fbm(vec2(25.0*p.x)) - 0.43));

             // Add some glow at low altitude (useful for night scenes
             // and/or giving the dome some glow)
             col += vec4(0.9,0.7,0.4,1.0)*smoothstep(0.07,0.0,p.y - 0.43);
         };

         // Dome General Color
         col = mix(col,vec4(1.0,0.6,0.5,0.1),0.4*sdCircle(p,0.3,vec2( 0.0,0.4),0.001));

         // Dome Base
         if( (length(p - vec2(0.0, 0.42)) - 0.3) < 0.0 )
         {
             col = mix(col,vec4(0.5,0.3,0.3,1.0)*(0.75 + 0.25*texture(iChannel0,p).xxxx) - 0.1*smoothstep(0.0,1.0,cos(5.0*p.x)),smoothstep(0.005,0.0,abs(p.y - 0.41) - 0.02));
             // Lights / portholes
             col += vec4(1.0,0.3,0.2,1.0)*abs(cos(1000.0*cos(p.x)))*smoothstep(0.002,0.0,abs(p.y - 0.42));
             float ColorLarson = mod(floor(TimeVar * Beat),4.0);
             vec4 ColorLarsonV = vec4(1.0,1.0,1.0,1.0);
             switch( int(ColorLarson) )
             {
                      case 0  : ColorLarsonV = vec4(1.0,0.5,0.5,1.0); break;
                      case 1  : ColorLarsonV = vec4(0.2,1.0,0.2,1.0); break;
                      case 2  : ColorLarsonV = vec4(0.2,0.2,1.0,1.0); break;
                      case 3  : ColorLarsonV = vec4(1.0,0.5,0.2,1.0); break;
                      default : ColorLarsonV = vec4(1.0,1.0,1.0,1.0); break;
             };
             col += smoothstep(0.0,0.5,clamp(cos(20.0*(p.x - TimeVar)),0.0,1.0))*ColorLarsonV*abs(cos(1000.0*cos(p.x)))*smoothstep(0.010,0.0,abs(p.y - 0.42));
         };

         // Wide Dome Entrance - Reminiscent of NASA lunar bases...
         col = mix(col,
                   vec4(0.9,0.4,0.3,1.0),
                   smoothstep(0.01,0.0,abs(p.x)-0.03)*smoothstep(0.002,0.0,abs(p.y - 0.405)-0.005));
     };

     // Dome Outer-Shine : gives off a "spherical feeling".
     if((length(p - vec2(0.0, 0.42)) - 0.3) < 0.0 && p.y>0.43)col += 1.9*vec4(0.9,0.5,0.4,0.1)*smoothstep(1.0,0.0,sdCircle(p,0.41,vec2( 0.0,0.38),0.17))*smoothstep(0.0,0.01,length(p-vec2(0.0,0.4)));

     // Structural Ellipsis - foreground
     if(p.y>0.4325 && (r2d(0.4 + 0.1*TimeVar)*(p-vec2( 0.0,0.42))).y > 0.0)col += 0.9*vec4(1.0,1.0,0.2,1.0)*smoothstep(0.0001,0.0,abs(dis_e(vec2(0.0,0.0),4.2,1.5,r2d(0.4 + 0.1*TimeVar)*(p-vec2( 0.0,0.42))) - 0.005));
     if(p.y>0.4325 && (r2d(2.5 - 0.1*TimeVar + 3.14159/2.0)*(p-vec2( 0.0,0.42))).y > 0.0)col += 0.9*vec4(1.0,1.0,0.2,1.0)*smoothstep(0.0001,0.0,abs(dis_e(vec2(0.0,0.0),4.2,1.5,r2d(2.5 - 0.1*TimeVar + 3.14159/2.0)*(p-vec2( 0.0,0.42))) - 0.005));

     // Star Dome-Reflection
     col += vec4(1.0,1.0,1.0,1.0)
           *metaDiamond(p,vec2(0.0,0.72),0.005 + 0.002*sin(TimeVar*3.14/Beat),0.0);

     if(p.y < 0.4)
     {
        // Receding ground
        col -= 0.05*vec4(texture(iChannel0,vec2( 0.1*p.x/(0.40-p.y),0.19*sin(0.3/(0.40-p.y) - 15.5*TimeVar))));

        // Ground light
        p *= 1.0/(1.0 + 0.005*TimeVar);
        col += 0.3*vec4(1.0,0.5,0.2,1.0)*sdCircle(p,0.6,vec2(0.0,0.4),0.3);
        p *= (1.0 + 0.005*TimeVar);
     };

     vec2 PosLaser;
     if( ( TimeVar > 4.0*MusicTimeBase && TimeVar < 6.0*MusicTimeBase ) ||
         ( TimeVar > 8.0*MusicTimeBase )
     )
     {
         // Choose a random laser source between 4...
         float SourceLaser = mod(floor(4.0*fbm(vec2(0.5*TimeVar))),4.0);
         switch(int(SourceLaser))
         {
                case 0:PosLaser = vec2( 0.0,-0.43);break;
                case 1:PosLaser = vec2( 0.0,-0.72);break;
                case 2:PosLaser = vec2(-0.3,-0.43);break;
                case 3:PosLaser = vec2( 0.3,-0.43);break;
         };
         p += PosLaser; // Move To Current Laser Source
         Factor01 = 5.0*TimeVar;
         p*=r2d( 2.5*fbm(vec2(Factor01)) - 1.25 + 3.14159 + TimeVar);
         col += vec4(0.0,1.0,0.0,1.0)*smoothstep(0.0001 + 0.03*length(p),0.0,abs(p.y) + 0.005*fbm(vec2(40.0*p.x) - 150.0*TimeVar));
         p*=r2d(-2.5*fbm(vec2(Factor01)) + 1.25 - 3.14159 - TimeVar);

         p*=r2d(-2.5*fbm(vec2(Factor01 + 105.6)) + 1.25 + 3.14159 + TimeVar);
         col += vec4(0.5,0.5,1.0,1.0)*smoothstep(0.0001 + 0.03*length(p),0.0,abs(p.y) + 0.005*fbm(vec2(40.0*p.x) - 150.0*TimeVar));
         p*=r2d( 2.5*fbm(vec2(Factor01 + 105.6)) - 1.25 - 3.14159 - TimeVar);

         p*=r2d(-4.5*fbm(vec2(Factor01 + 175.1)) + 2.5 + 3.14159 + TimeVar);
         col += vec4(1.0,1.0,1.0,1.0)*smoothstep(0.0001 + 0.03*length(p),0.0,abs(p.y) + 0.005*fbm(vec2(40.0*p.x) - 150.0*TimeVar));
         p*=r2d( 4.5*fbm(vec2(Factor01 + 175.1)) - 2.5 - 3.14159 - TimeVar);
         p -= PosLaser;

         // Draw a halo on the source position
         col += vec4(1.0,1.0,1.0,1.0)*metaDiamond(p,vec2(-PosLaser),0.004,0.0);

     };

     // Adding an "atmospheric speed effect"
     // similar to the ground effect, but way, way more transparent...
     if(p.y > 0.4)col += (0.02 + 0.02*fbm(vec2(TimeVar)))*vec4(texture(iChannel0,vec2( 0.1*p.x/(p.y-0.4),0.19*sin(0.3/(p.y-0.4) - 15.5*TimeVar))));

     // Just a dust line on the horizon... looks better. :)
     col = mix(col,1.2*vec4(0.35,0.15,0.15,1.0),smoothstep(0.004,0.0,abs(p.y-0.40)));

     // The Paperplane !

     // Quick'n easy fix to make the paperplane colors blend perfectly into the scene...
     vec4 GeneralBrightness = 1.5*vec4(1.0);
     // Pretty straightforward...
     float AltitudePaperplane = 0.6;

     // We want the paperplane to always be at the front so we cancel the "global zoom back"
     p *= 1.0/(1.0 + 0.005*TimeVar);
     //p.x = -p.x;

     // Minute rotations and translations, less static that way...
     p *= r2d(0.05*fbm(vec2(0.1*TimeVar)));
     p.y += 0.01*sin(0.1*TimeVar);

     // Fine-tuning contrail Y position
     p.y -= 0.4;
     // Positioning contrail by rotating it.
     p*=r2d(-1.21);
     // Thruster Contrail
     if(p.y < AltitudePaperplane && p.y > 0.0)col += 2.0*vec4(1.0,0.7,0.5,1.0)*smoothstep(0.001 + 0.05*length(p),0.0,abs(p.x) + 0.01*fbm(vec2(10.0*p.y + 20.0*TimeVar)))*smoothstep(0.0,0.8,p.y);
     p*=r2d( 1.21);
     p.y += 0.4;

     // Fine-tuning x pos...
     p.x -= 0.1;

     // Thruster diamond flame, pulsating for effect...
     col += vec4(1.0,1.0,0.75,1.0)*clamp(metaDiamond(p,vec2(0.40,0.59),0.01 + 0.005*sin(60.0*TimeVar),0.0),0.0,1.0);

     // How to draw an (admittedly) strange arrow paperplane in 3 triangles... A tutorial.

     vec2 Arrowhead = vec2(0.50,0.64);

     // The fbm parts are for making the wingtips wobble fast like there's a little
     // residual wind inside the flow-control bubble-shield... because an active
     // system that small can not be perfect.
     col = mix( col,
                GeneralBrightness*0.8*vec4(1.0,0.7,0.4,1.0),
                smoothstep(0.001,0.0,
                sdTriangle(p,vec2(0.4,0.6),
                             vec2(0.40+0.01*fbm(vec2(70.0*TimeVar)), 0.68+0.01*fbm(vec2(70.0*TimeVar))),
                             Arrowhead)));
     col = mix( col,
                GeneralBrightness*vec4(0.5,0.25,0.2,1.0),
                smoothstep(0.001,0.0,
                sdTriangle(p,vec2(0.4,0.6),
                             vec2(0.49+0.01*fbm(vec2(70.0*TimeVar+1.1)), 0.53+0.01*fbm(vec2(70.0*TimeVar+1.1))),
                             Arrowhead)));
     col = mix(col,
               GeneralBrightness*vec4(1.0,0.7,0.4,1.0),
               smoothstep(0.001,0.0,
               sdTriangle(p,vec2(0.4,0.6),
                            vec2(0.33,0.53+0.01*fbm(vec2(70.0*TimeVar+2.2))),
                            Arrowhead)));

     // Un-Fine-tuning x pos...
     p.x += 0.1;
     //p.x = -p.x;

     // let's go back to p before tracing the paperplane...
     p = last_p;

     // Text

     if( TimeVar > MusicTimeBase )
     {
         float TabTxt[16] = float[]( 72.0 ,65.0 ,80.0 ,80.0 ,89.0 ,32.0 ,78.0 ,69.0 ,87.0 ,32.0 ,89.0 ,69.0 ,65.0 ,82.0 ,32.0 ,33.0 );
         vec2 centrage = vec2(0.0 - 8.0*0.028,0.9);

         // Let's zoom to make the text bigger...
         p *= 0.35;

         if( ( TimeVar > 4.0*MusicTimeBase && TimeVar < 6.0*MusicTimeBase ) ||
             ( TimeVar > 2.0*MusicTimeBase && TimeVar < 3.0*MusicTimeBase ) ||
               TimeVar > 8.0*MusicTimeBase )
         {
             centrage += vec2(0.25*fbm(vec2(floor(TimeVar*64.0/MusicTimeBase) + 1.7)) - 0.125,
                              0.25*fbm(vec2(floor(TimeVar*64.0/MusicTimeBase) + 0.4)) - 0.125 - 0.15);
             p *= r2d(0.90*fbm(vec2(floor(TimeVar*64.0/MusicTimeBase))) - 0.45);
         };

         // We're gonna make A LOT of scaling so... better save a correct base for later.
         last_p = p;

         // Draw the text 10 times with a small offset...
         for( int j = 0; j < 10; j++)
         {
              for( int i= 0; i < 16; i++)
              {
                   centrage.y += 0.01*sin(15.0*p.x + 8.0*TimeVar - 1.5);
                   col += vec4(0.8,0.3,0.1,1.0)*(0.02*mod(float(j) - 50.0*TimeVar,20.0))*traceChar(p,TabTxt[i], centrage + vec2(0.028*mod(float(i),39.0),0.0));
                   centrage.y -= 0.01*sin(15.0*p.x + 8.0*TimeVar - 1.5);
              };
              p *= 1.02;
         };

         // RE-LOOO-OOOAAAD !
         p = last_p;

         // Let's draw the text one more time, but flat, and over the rest,
         // with a scroller effect...
         for( int i = 0; i < 16; i++)
         {
              centrage.y += 0.01*cos(15.0*(p.x-0.5) + 8.0*TimeVar - 1.5);
              if(mod(float(i) - 25.0*TimeVar,18.0) > 10.0)col = mix(col,vec4(1.0,0.95,0.5,1.0),traceChar(p,TabTxt[i], centrage + vec2(0.028*mod(float(i),39.0),0.0)));
              centrage.y -= 0.01*cos(15.0*(p.x-0.5) + 8.0*TimeVar - 1.5);
         };
     };

     // Color-flooding for the last seconds of the show...
     if( TimeVar > 8.0*MusicTimeBase )
     {
         float ColorSplash = mod(floor(TimeVar/(MusicTimeBase/64.0)),5.0);
         switch( int(ColorSplash) )
         {
                 case 0  : col *= vec4(1.0,0.1,0.7,1.0);break;
                 case 1  : col *= vec4(0.0,0.8,0.0,1.0);break;
                 case 2  : col *= vec4(1.0,1.0,1.0,1.0);break;
                 case 3  : col *= vec4(0.0,0.5,1.0,1.0);break;
                 case 4  : col *= vec4(1.0,0.7,0.0,1.0);break;
                 default : col *= vec4(1.0,0.7,0.4,1.0);break;
         };
     };

     fragColor = vec4(col);
}
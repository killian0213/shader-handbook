// Image (image) — Exawatt Sunburn by msm01
// https://www.shadertoy.com/view/Ns2BWt

// "Now the problem, when you fire an exawatt laser gun in the general direction
// of another ship, is that you don't simply focus the heat of a thousand hells
// on a small target to make it die a painful death ! No. In fact, no matter how
// efficient your beam is, you're still somehow bleeding at least a few terawatts
// of 'residual light' randomly into the environment.
// To the uneducated eye, the word 'residual' could make it seem like a detail.
// Let me assure you IT IS NOT !"
// "Dogfighting in 3022", by Sam Launch, callsign : "Red Eye of Sauron"
// 25th Edition, 3021
// Part 1 : Tactical Lasers — Chapter 1 : Secondary Reflections

// (somewhat serious) Forewords :
// Just trying to get really fluent with basic 2D functions.
// I think I'm getting there, although there's still room for progress.
// I have more 2D scenes to come... :)
// Sorry if the code is lame or just plain wrong, or lacks logic.
// I intend to mix art and science, and will surely fail at both sometimes.

// Use this code as you wish, just try to give proper credit when so.
// https://creativecommons.org/licenses/by-nc-sa/3.0/

// Music is "Mauler, Healer, Fighter, Squealer" by Skaven
// This musician is really great, give him a chance !
// https://soundcloud.com/skaven252/mauler-healer-fighter-squealer
// https://creativecommons.org/licenses/by-nc-sa/3.0/

// General Stuff

mat2 r2d( float a ){ float c = cos(a), s = sin(a); return mat2( c, s, -s, c ); }

vec4 over(in vec4 a, in vec4 b){ return a + b*(1.0-a.w); }

float noise(vec2 st) { return fract( sin( dot( st.xy, vec2(12.9898,78.233)))*43758.5453123 ); }

// Basic Geometry Functions.

float sdCircle(in vec2 p, float radius, vec2 pos, float prec)
{
      return smoothstep(0.0,prec,radius - length(pos-p));
}

// Classic from Iq (thanks !)

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

// Nice function from... Woops, forgot !

float metaDiamond(vec2 p, vec2 pixel, float r, float s)
{
      vec2 d = abs(r2d(s*0.1*iTime)*(p-pixel));
      return r / (d.x + d.y);
}

// Noise Please

float fbm(in vec2 v_p)
{
      float VarX1 = floor(v_p.x );
      float VarX2 = floor(v_p.x + 1.0);
      float VarD0 = fract(v_p.x);
      return mix(noise(vec2(VarX1)),noise(vec2(VarX2)),smoothstep(0.0,1.0,VarD0));
}

// 2D Tunnel Effect (...ish)

vec4 drawTunnel(in vec2 p, vec4 CS)
{
     float angle = atan(p.y/p.x);
     float dist = length(p);
     vec4 Tunnel;
     Tunnel = CS*texture(iChannel1,vec2(0.02*(1.0/dist) + 0.5*iTime,angle/3.14159));
     Tunnel *= smoothstep(0.0,1.0,length(p));
     return Tunnel;
}

// Set-Up A Nice 2D Starfield...

float drawStars(in vec2 v_p)
{
      float Disp_Star = 0.000;
      float Buff_Star = 0.000;
      float PosX_Star = 0.000;
      float PosY_Star = 0.000;
      float Dist_Star = 0.000;
      float Magn_Star = 0.000;

      for( int j = 0; j < 100 ; j++ )
      {
           PosX_Star  = mod((3.0*noise(vec2(j))-1.5),3.0) - 1.5;
           PosY_Star  = 2.0*noise(vec2(j + 176));
           Dist_Star  = length(v_p - vec2(PosX_Star,PosY_Star));
           Magn_Star  = 0.000025*noise(vec2(j + 4));
           if( length(vec2(PosX_Star,PosY_Star) - vec2( 0.7, 0.6)) > 0.25 &&
               length(vec2(PosX_Star,PosY_Star) - vec2(0.0,-0.5)) > 0.1 )
           {
               if( mod(float(j),10.0) < 9.0 )
               {
                   Buff_Star += Magn_Star*pow(Dist_Star,-1.5);
               }else{
                   Buff_Star += metaDiamond(v_p,vec2(PosX_Star,PosY_Star),0.0025,0.0);
               };
           };
      };
      return Buff_Star;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
     vec2 p = vec2( (iResolution.x/iResolution.y)
                  * (fragCoord.x - iResolution.x/2.0)
                  / iResolution.x,
                    fragCoord.y / iResolution.y);

     // Random Zoom make for dramatic camera moves ...maybe.
     p *= (1.1 - 0.5*fbm(vec2(0.1*iTime)));

     // Get mouse position to make even more dramatic USER-DEFINED camera angles ! /s
     float TiltX = -0.001*(iMouse.x - iResolution.x/2.0);
     float AltiY =  0.001*(iMouse.y - iResolution.y/2.0);
     
     // Propagate Those User Settings to the engine !
     p += vec2(0.0,AltiY);
     p = r2d(-TiltX)*p;

     // In the beginning, there was "nothing".
     vec4 col = vec4(0.0);

     // "Nothing" was good. So we saved it because we already knew we would screw up !
     vec2 p_save = p;
     
     // Someone then said "Let there be light !"
     col += drawStars(p);

     // Aaaaaaand we picked the wrong color scheme.
     vec4 ColorScheme = vec4( 0.40 + 0.40*sin(0.25*iTime),
                              0.28 + 0.28*sin(0.40*iTime),
                              0.15 + 0.15*sin(0.30*iTime),
                              1.00);

     // Let's draw a star. Big, fat, round, trembling like jelly on the edge...
     col  = over(vec4(1.0,0.5,0.2,1.0)*sdCircle(p,0.2 + 0.0025*sin(100.0*p.y + 2.0*iTime),vec2(0.0,0.5),0.1),col);
     // Let's give her a friendly blue star juuuuuuust on the verge of going blackhole.
     col += over(vec4(0.0,1.0,0.0,1.0)*sdCircle(p,0.05,vec2(-0.5,0.55),0.05),col);
     // Make the blue extra-pretty with some diamond make-up.
     col += vec4(0.1,0.2,0.9,1.0)*metaDiamond(p,vec2(-0.5,0.55),0.1, 0.0);
     // Add another star, another color.
     col += vec4(0.4,0.5,0.2,1.0)*metaDiamond(p,vec2( 0.15,0.75),0.05, 0.0);

     // Let's draw a Gas Giant !
     vec4 GiantPlanet = vec4(0.0);
     if( p.y > (0.05*fbm(2.5*p) - 0.4))
     {
         p += vec2(-0.7,-0.6);
         p = r2d( 2.7)*p;
         // The Giant...
         GiantPlanet += 0.6*sdCircle(p,0.25,vec2(0.0,0.0),0.01)*texture(iChannel1,vec2(0.005*p.x + 0.001*iTime,0.5*p.y));
         // Let's bool-diff the terminator.
         GiantPlanet -= sdCircle(p,0.25,vec2(-0.025, 0.0),0.05)*smoothstep(0.008,0.0,length(p)-0.242);
         p = r2d(-2.7)*p;
         p += vec2( 0.7, 0.6);
     };
     col = over(0.3*GiantPlanet,col);

     // Let's make a quick sky by stretching a texture just right.
     vec4 Sky_Value = 0.2*vec4(texture(iChannel0,vec2( 0.01*(p.x)/((0.40-p.y)),0.05*sin(.01/(0.40-p.y) - 0.2*iTime ))));
     col += 3.0*vec4(Sky_Value.xyz,1.0);

     // Let's make a ground that goes fast, using the same ad-hoc method.
     if( p.y < 0.4 )
     {
         vec4 Ground_Value = vec4(texture(iChannel2,vec2( 0.10*p.x/(0.40-p.y),0.19*sin(.1/(0.40-p.y) + 8.0*iTime))) );
         col = vec4(0.7,0.4,0.4,1.0)*over(vec4(Ground_Value.xxx,1.0),col);
     }else{
         // Let's make some mountains above the horizon. They won't move but nobody will notice since
         // the ships only go forward and draw all the attention ! Plus you can easily justify their
         // stillness if you have to : the two ships are stuck on a 4D topological threadmill.
         // There. Done. Hard Science, man ! :D
         col = over(vec4(0.5,0.2,0.2,1.0)*(1.0-smoothstep(0.0,0.01,p.y - 0.05*fbm(2.5*p) - 0.4))*texture(iChannel2,4.0*p),col);
     };

     // Let's smooth colors around the horizon to make the landscape uniform...
     col += vec4(0.4,0.70,0.7,1.0)*(1.0-smoothstep(0.0,0.5,abs(p.y - 0.4)));

     // First Ship : the circular-shaped far-one that tries to escape.
     p_save = p;
     p += vec2(0.0, -0.41 + 0.01*sin(iTime));
     p = r2d(1.14159*fbm(vec2(0.2*iTime + 5.0))*sin(0.8*iTime))*p;
     p.x = abs(p.x);
     p *= 1.5;
     col -= 0.5*smoothstep(0.0005,0.0,sdTriangle(p,vec2(0.0,0.0),vec2( 0.025,-0.02),vec2( 0.0, 0.001)));
     col -= 0.5*smoothstep(0.0005,0.0,sdTriangle(p,vec2(0.0,0.0),vec2( 0.0, 0.03),vec2( 0.001, 0.0)));
     col -= sdCircle(p,0.005,vec2(0.0,0.0),0.0001);
     if(abs(length(p) - 0.015) < 0.0005 ) col -= sdCircle(p,0.04,vec2(0.0,0.0),0.0001);
     p /= 1.5;
     // Bubble Shield activate when ship targeted by dual exawatt laser.
     if( fbm(vec2(1.0*iTime)) > 0.7){ col -= 2.0*sdCircle(p,0.05,vec2(0.0,0.0),0.1); };
     // Small and very advanced propulsor because the bad guys always have the best tech.
     col += vec4(0.99,0.3,0.1,1.0)*metaDiamond(p,vec2(0.0,0.0),0.01, 40.0);
     p = r2d(-1.14159*fbm(vec2(0.2*iTime + 5.0))*sin(0.8*iTime))*p;
     p += vec2(0.0,  0.41 - 0.01*sin(iTime));
     p = p_save;
     
     // Second Ship : the white one with dual exawatt laser and variable winglets.
     p.y += -0.4;
     p   *= 1.0 + 0.5*(fbm(vec2(0.1*iTime)));
     
     p    = r2d(3.14159*fbm(vec2(0.4*iTime))*sin(0.5*iTime))*p;
     p.y += 0.4;
     p.x  = abs(p.x);

     col = over(smoothstep(0.0050,0.0,vec4(sdTriangle(p,vec2(0.0,-0.060),vec2(0.05,-0.05),vec2(0.00, 0.00)))),col);
     col = over(smoothstep(0.0015,0.0,vec4(sdTriangle(p,vec2(0.0,-0.040),vec2(0.00,-0.03),vec2(0.08,-0.03 - 0.030*fbm(vec2(0.4*iTime)))))),col);
     col = over(smoothstep(0.0015,0.0,vec4(sdTriangle(p,vec2(0.0,-0.005),vec2(0.00,-0.01),vec2(0.03,-0.01)))),col);
     if( fbm(vec2(1.0*iTime)) > 0.7) // Erratic firing pattern...
     {
         // Laser Beam
         col += 1.0*over( 1.0*abs(sin(50.0*p.y - 1000.0*iTime))*smoothstep(0.001,0.0,vec4(sdTriangle(p,vec2( 0.008,-0.01),vec2( 0.002,-0.01),vec2(0.0, 0.40)))),col);
     };
     col -= vec4(0.9)*smoothstep(0.005,0.0,sdTriangle(p,vec2(0.0,-0.059),vec2(0.049,-0.05),vec2(0.0,-0.041)));
     col += vec4(1.0,0.0,0.0,1.0)*sdCircle(p,0.005,vec2(0.02,-0.05),0.001);
     col += vec4(0.99,0.3,0.1,1.0)*metaDiamond(p,vec2(0.02,-0.05),0.05 + 0.002*sin(100.0*iTime), 10.0);
     // Wake of the ship, totally made-up from a parabola and a scrolling texture
     col += 2.5*smoothstep(0.0,0.03,0.5*p.x*p.x)*smoothstep(0.1,0.0,p.y - (-10.0*p.x*p.x - 0.10))*texture(iChannel0,0.10*vec2(p.x,p.y- (-10.0*p.x*p.x - 0.10)) + vec2(0.0,1.5*iTime));

     p = p_save;

     // When the laser hits the target, light diffusion by the bubble shield
     // creates noxious clouds and fumes in the wake, like a beautiful but very
     // lethal tunnel-effect, or plane contrail...
     if( fbm(vec2(1.0*iTime)) > 0.7)
     { 
         p += vec2(0.0, -0.4);
         col -= 1.7*drawTunnel(p,ColorScheme);
     };

     // Let's paint everything (color calibration)
     if( iTime < 102.55 )
     { 
         // "Apocalypse selon Synthwave"
         col = vec4(0.7,0.50,0.50,1.0)*col;
     }else{
         if( iTime < 102.55*2.0)
         {
             // "Chlorine Planet"
             col = vec4(0.3,0.50,0.30,1.0)*col;
         }else{
             // "Twilight Zone : Lost Episode"
             col = 0.25*col.xxxx;
         };
     };

     // POWER UP !
     fragColor = col;
}
// Buffer A (buffer) — Lava blaster by michael0884
// https://www.shadertoy.com/view/WdtXzs

//voronoi particle tracking 

void Check(inout vec4 U, vec2 pos, vec2 dx)
{
    vec4 Unb = SAMPLE(iChannel0, pos+dx, size);
    vec2 rpos1 = mod(pos-Unb.xy+size*0.5,size) - size*0.5;
    vec2 rpos2 = mod(pos-U.xy+size*0.5,size) - size*0.5;
    //check if the stored neighbouring particle is closer to this position 
    if(length(rpos1) < length(rpos2))
    {
        U = Unb; //copy the particle info
    }
}

vec4 B(vec2 pos)
{
   return 5.*SAMPLE(iChannel1, pos, size);
}

void mainImage( out vec4 U, in vec2 pos )
{
    U = SAMPLE(iChannel0, pos, size);
    
    //check neighbours 
    Check(U, pos, vec2(-1,0));
    Check(U, pos, vec2(1,0));
    Check(U, pos, vec2(0,-1));
    Check(U, pos, vec2(0,1));
    Check(U, pos, vec2(-1,-1));
    Check(U, pos, vec2(1,1));
    Check(U, pos, vec2(1,-1));
    Check(U, pos, vec2(1,-1));
    U.xy = mod(U.xy,size); //limit the position to the texture
    
    //make new particles by diverging existing ones
 	if(length(mod(pos-U.xy+size*0.5,size) - size*0.5) > 1./minimal_density)
    {
        U.xy = pos;
    }

    vec2 ppos = U.xy;

    vec2 pressure = vec2(B(ppos+vec2(1,0)).z - B(ppos+vec2(-1,0)).z, B(ppos+vec2(0,1)).z - B(ppos+vec2(0,-1)).z);
    //mouse interaction
    if(iMouse.z>0.)
    {
        float k = gauss(ppos-iMouse.xy, 25.);
        U.zw = U.zw*(1.-k) + k*0.2*vec2(cos(0.02*iTime*dt), sin(0.02*iTime*dt));
    }
	
    #ifdef BLASTER
     U.zw += 0.002*vec2(cos(0.01*iTime*dt), sin(0.01*iTime*dt))*gauss(ppos-size*vec2(0.5,0.5),8.)*dt;
    #endif
    
    //update the particle
    U.zw = U.zw*0.9995; // decrease velocity with time
    U.zw += P*pressure*dt;
    //smooth velocity
    vec2 velocity = 0.*B(ppos).xy + U.zw;
    U.xy += dt*velocity;
    U.xy = mod(U.xy,size); //limit the position to the texture
    
    
    if(iFrame < 1)
    {
      	if(mod(pos, vec2(1./particle_density)).x < 1. && mod(pos, vec2(1./particle_density)).y < 1.)
           U = vec4(pos,0.,0.);
      
    }
}
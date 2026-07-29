// Buffer A (buffer) — Physarum Polycephalum Simulation by michael0884
// https://www.shadertoy.com/view/tlKGDh

//voronoi particle tracking 
//simulating the cells

//loop the vector
vec2 loop_d(vec2 pos)
{
	return mod(pos + size*0.5, size) - size*0.5;
}

//loop the space
vec2 loop(vec2 pos)
{
	return mod(pos, size);
}


void Check(inout vec4 U, vec2 pos, vec2 dx)
{
    vec4 Unb = texel(ch0, loop(pos+dx));
    //check if the stored neighbouring particle is closer to this position 
    if(length(loop_d(Unb.xy - pos)) < length(loop_d(U.xy - pos)))
    {
        U = Unb; //copy the particle info
    }
}

void CheckRadius(inout vec4 U, vec2 pos, float r)
{
    Check(U, pos, vec2(-r,0));
    Check(U, pos, vec2(r,0));
    Check(U, pos, vec2(0,-r));
    Check(U, pos, vec2(0,r));
}

void mainImage( out vec4 U, in vec2 pos )
{
    vec2 muv = iMouse.xy/size;
    
    if(length(muv.xy) >0.)
    {
    	sdist *= muv.x;
  		sst *= muv.y; 
    }
    else
    {
        sdist *= 0.8;
  		sst *= 0.05; 
    }
   
    //this pixel value
    U = texel(ch0, pos);
    
    //check neighbours 
    CheckRadius(U, pos, 1.);
    CheckRadius(U, pos, 2.);
    CheckRadius(U, pos, 3.);
    CheckRadius(U, pos, 4.);
    CheckRadius(U, pos, 5.);
   
    U.xy = loop(U.xy);
    
    //cell cloning 
    if(length(U.xy - pos) > 10.)
    	U.xy += 1.*(hash22(pos)-0.5);

    //sensors
    vec2 sleft = U.xy + sdist*vec2(cos(U.z+sangl), sin(U.z+sangl));
    vec2 sright = U.xy + sdist*vec2(cos(U.z-sangl), sin(U.z-sangl));
    
    float dangl = (pixel(ch1, sleft).x - pixel(ch1, sright).x);
    U.z += dt*sst*tanh(3.*dangl);
   
    vec2 pvel = pspeed*vec2(cos(U.z), sin(U.z)) + 0.1*(hash22(U.xy+iTime)-0.5);;
    
    //update the particle
    U.xy += dt*pvel;
    
    U.xy = loop(U.xy);
    
    
    if(iFrame < 1)
    {
        U.xy = vec2(pdens*round(pos.x/pdens),pdens*round(pos.y/pdens));
        U.zw = hash22(U.xy) - 0.5;
    }
}
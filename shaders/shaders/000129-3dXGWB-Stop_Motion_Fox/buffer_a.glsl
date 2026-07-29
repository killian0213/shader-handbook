// Buffer A (buffer) — Stop Motion Fox by iq
// https://www.shadertoy.com/view/3dXGWB

// Created by inigo quilez - iq/2019
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

// Simple procedural animation for the fox

vec3 animate( vec3 v)
{
    float time = iTime+13.0;
	time = floor(time*8.0)/8.0; // force 8 fps
    
    // breath
    {
      vec3 p = vec3(0.0,0.05,0.23);
      float f = 1.0-smoothstep(0.0,0.16,length(p-v) );
        
      float b = 1.0 + 0.18*f*(0.5+0.5*sin(time*8.0));
      v = p + (v-p)*b;  
        
    }

    // tail
    {
        float k = v.z - (-0.18);
        if( k<0.0 )
        {

        float bn = sin(time*0.11);
        bn = bn*bn*bn;
        float an = sin(time*2.0 + k*6.0 + bn*10.0 + 2.0);
        an *= 0.5*k*an; an += 0.2;
        float co = cos(an);
        float si = sin(an);
        vec2 p = vec2(0.0,-0.18);
        v.xz = p + mat2(co,-si,si,co)*(v.xz-p);
        }
    }
    
    // head
    {
        float k = v.z - (+0.16);
        if( k>0.0 )
        {
            
        float an = sin(time*0.7*0.5);
        an = an*an*an;
        an = 1.5*k*an;
        float co = cos(an);
        float si = sin(an);
        vec2 p = vec2(0.0,0.16);
        v.xz = p + mat2(co,-si,si,co)*(v.xz-p);
            

        an = sin(time*0.5*0.5);
        an = an*an*an;
        an = -0.95*k*abs(an);
        co = cos(an);
        si = sin(an);
        p = vec2(0.0,0.16);
        v.yz = p + mat2(co,-si,si,co)*(v.yz-p);
        }
    }

    return v;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    // prepare to decode into a 64x64 texture
    ivec2 p = ivec2(fragCoord-0.5);
    int faceID   = (p.y/3)*64 + p.x;
    int vertexID = p.y%3;
    if( p.x>64 || faceID>=numFaces || vertexID>2 ) discard;

    // decode
    uint vid = getIndex(faceID,vertexID);
    vec3 v = getVertex( vid );
    
    // animate
    v = animate(v);
    
    // bake
	fragColor = vec4( v, 1.0 );
}
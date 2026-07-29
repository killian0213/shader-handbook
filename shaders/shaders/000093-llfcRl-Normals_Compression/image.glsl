// Image (image) — Normals Compression by iq
// https://www.shadertoy.com/view/llfcRl

// The MIT License
// Copyright © 2017 Inigo Quilez
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions: The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software. THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.


// Surface normals are encoded in 96 bit by default (3 floats). Here I encode
// normals using, into 8, 12, 16, 24 and 32 bits (12x, 8x, 6x, 4x and 3x 
// compression factors respectively), by using a few different method:
//
// Left to right: Direct, Cube, ZIgnore, Spherical, Spheremap, Fibonacci, and Octahedral. 
// Top to bottom: 8 bits, 12 bits, 16 bits, 24 bits and 32 bits.
// See at full screen for best comparison.
//
// Error Color Encoding:   blue = 0.0, red = 0.5 degrees
//
// 32bit Fibonacci is broken probably due to 23 bit mantissa overflow.
//
// Octaheral compression with different bitrates: https://www.shadertoy.com/view/Mtfyzl
// You can compare ithese to Fibonacci projection here: https://www.shadertoy.com/view/4t2XWK



// undef this to try a different shape
#define SPHERES

//-------------------------------------------------------------------------------------------
uint   packSnorm2x12(vec2 v) { uvec2 d = uvec2(round(2047.5 + v*2047.5)); return d.x|(d.y<<12u); }
uint   packSnorm2x8( vec2 v) { uvec2 d = uvec2(round( 127.5 + v* 127.5)); return d.x|(d.y<< 8u); }
vec2 unpackSnorm2x8( uint d) { return vec2(uvec2(d,d>> 8)& 255u)/ 127.5 - 1.0; }
vec2 unpackSnorm2x12(uint d) { return vec2(uvec2(d,d>>12)&4095u)/2047.5 - 1.0; }

//-------------------------------------------------------------------------------------------

//----

uint cube_8( in vec3 nor ) // 3:2:2:1
{
    vec3 mor; uint  id;
                                    mor = nor.xyz; id = 0u;
    if( abs(nor.y) > abs(mor.x) ) { mor = nor.yzx; id = 1u; }
    if( abs(nor.z) > abs(mor.x) ) { mor = nor.zxy; id = 2u; }
    uint is = (mor.x<0.0)?1u:0u;
    vec2 uv = 0.5 + 0.5*mor.yz/abs(mor.x);
    uvec2 iuv = uvec2(round(uv*vec2(7.0,3.0)));
    return iuv.x | (iuv.y<<3u) | (id<<5u) | (is<<7u);
}
vec3 i_cube_8( uint data )
{
    uvec2 iuv = uvec2( data, data>>3u ) & uvec2(7u,3u);
    vec2 uv = vec2(iuv)*2.0/vec2(7.0,3.0) - 1.0;
    uint is = (data>>7u)&1u;
    vec3 nor = vec3((is==0u)?1.0:-1.0,uv.xy);
    uint id = (data>>5u)&3u;
         if(id==0u) nor = nor.xyz;
    else if(id==1u) nor = nor.zxy;
    else            nor = nor.yzx;
    return normalize(nor);
}
uint cube_12( in vec3 nor ) // 5:4:2:1
{
    vec3 mor; uint  id;
                                    mor = nor.xyz; id = 0u;
    if( abs(nor.y) > abs(mor.x) ) { mor = nor.yzx; id = 1u; }
    if( abs(nor.z) > abs(mor.x) ) { mor = nor.zxy; id = 2u; }
    uint is = (mor.x<0.0)?1u:0u;
    vec2 uv = 0.5 + 0.5*mor.yz/abs(mor.x);
    uvec2 iuv = uvec2(round(uv*vec2(31.0,15.0)));
    return iuv.x | (iuv.y<<5u) | (id<<9u) | (is<<11u);
}
vec3 i_cube_12( uint data )
{
    uvec2 iuv = uvec2( data, data>>5u ) & uvec2(31,15);
    vec2 uv = vec2(iuv)*2.0/vec2(31.0,15.0) - 1.0;
    uint is = (data>>11u)&1u;
    vec3 nor = vec3((is==0u)?1.0:-1.0,uv.xy);
    uint id = (data>>9u)&3u;
         if(id==0u) nor = nor.xyz;
    else if(id==1u) nor = nor.zxy;
    else            nor = nor.yzx;
    return normalize(nor);
}
uint cube_16( in vec3 nor )
{
    vec3 mor; uint  id;
                                    mor = nor.xyz; id = 0u;
    if( abs(nor.y) > abs(mor.x) ) { mor = nor.yzx; id = 1u; }
    if( abs(nor.z) > abs(mor.x) ) { mor = nor.zxy; id = 2u; }
    uint is = (mor.x<0.0)?1u:0u;
    vec2 uv = 0.5 + 0.5*mor.yz/abs(mor.x);
    uvec2 iuv = uvec2(round(uv*vec2(127.0,63.0)));
    return iuv.x | (iuv.y<<7u) | (id<<13u) | (is<<15u);
}
vec3 i_cube_16( uint data )
{
    uvec2 iuv = uvec2( data, data>>7u ) & uvec2(127u,63u);
    vec2 uv = vec2(iuv)*2.0/vec2(127.0,63.0) - 1.0;
    uint is = (data>>15u)&1u;
    vec3 nor = vec3((is==0u)?1.0:-1.0,uv.xy);
    uint id = (data>>13u)&3u;
         if(id==0u) nor = nor.xyz;
    else if(id==1u) nor = nor.zxy;
    else            nor = nor.yzx;
    return normalize(nor);
}
uint cube_24( in vec3 nor )
{
    vec3 mor; uint  id;
                                    mor = nor.xyz; id = 0u;
    if( abs(nor.y) > abs(mor.x) ) { mor = nor.yzx; id = 1u; }
    if( abs(nor.z) > abs(mor.x) ) { mor = nor.zxy; id = 2u; }
    uint is = (mor.x<0.0)?1u:0u;
    vec2 uv = 0.5 + 0.5*mor.yz/abs(mor.x);
    uvec2 iuv = uvec2(round(uv*vec2(2047.0,1023.0)));
    return iuv.x | (iuv.y<<11u) | (id<<21u) | (is<<23u);
}
vec3 i_cube_24( uint data )
{
    uvec2 iuv = uvec2( data, data>>11u ) & uvec2(2047,1023);
    vec2 uv = vec2(iuv)*2.0/vec2(2047.0,1023.0) - 1.0;
    uint is = (data>>23u)&1u;
    vec3 nor = vec3((is==0u)?1.0:-1.0,uv.xy);
    uint id = (data>>21u)&3u;
         if(id==0u) nor = nor.xyz;
    else if(id==1u) nor = nor.zxy;
    else            nor = nor.yzx;
    return normalize(nor);
}
uint cube_32( in vec3 nor )
{
    vec3 mor; uint  id;
                                    mor = nor.xyz; id = 0u;
    if( abs(nor.y) > abs(mor.x) ) { mor = nor.yzx; id = 1u; }
    if( abs(nor.z) > abs(mor.x) ) { mor = nor.zxy; id = 2u; }
    uint is = (mor.x<0.0)?1u:0u;
    vec2 uv = 0.5 + 0.5*mor.yz/abs(mor.x);
    uvec2 iuv = uvec2(round(uv*vec2(32767.0,16383.0)));
    return iuv.x | (iuv.y<<15u) | (id<<29u) | (is<<31u);
}
vec3 i_cube_32( uint data )
{
    uvec2 iuv = uvec2( data, data>>15u ) & uvec2(32767u,16383u);
    vec2 uv = vec2(iuv)*2.0/vec2(32767.0,16383.0) - 1.0;
    
    uint is = (data>>31u)&1u;
    vec3 nor = vec3((is==0u)?1.0:-1.0,uv.xy);

    uint id = (data>>29u)&3u;
         if(id==0u) nor = nor.xyz;
    else if(id==1u) nor = nor.zxy;
    else            nor = nor.yzx;
    
    return normalize(nor);
}

//----


uint zignore_8( in vec3 nor )
{
    vec2 v = 0.5 + 0.5*nor.xy;
    uvec2 d = uvec2(round(v*vec2(15.0,7.0)));
    uint s = (nor.z<0.0)?1u:0u;
    return d.x|(d.y<<4u)|(s<<7u);
}
vec3 i_zignore_8( uint data )
{
    uvec3 d = uvec3( data, data>>4, data>>7 ) & uvec3(15u,7u,1u);
    vec3 v;
    v.xy = vec2(d.xy)*2.0/vec2(15.0,7.0) - 1.0;
    v.z = sqrt(1.0 - dot(v.xy, v.xy)) * ((d.z==1u)?-1.0:1.0);
    return v;//normalize(v);
}
uint zignore_12( in vec3 nor )
{
    vec2 v = 0.5 + 0.5*nor.xy;
    uvec2 d = uvec2(round(v*vec2(63.0,31.0)));
    uint s = (nor.z<0.0)?1u:0u;
    return d.x|(d.y<<6u)|(s<<11u);
}
vec3 i_zignore_12( uint data )
{
    uvec3 d = uvec3( data, data>>6, data>>11 ) & uvec3(63u,31u,1u);
    vec3 v = vec3(d)*2.0/vec3(63.0,31.0,1) - 1.0;
    v.z = sqrt(1.0 - dot(v.xy, v.xy)) * ((d.z==1u)?-1.0:1.0);
    return normalize(v);
}
uint zignore_16( in vec3 nor )
{
    vec2 v = 0.5 + 0.5*nor.xy;
    uvec2 d = uvec2(round(v*vec2(127.0,255.0)));
    uint s = (nor.z<0.0)?1u:0u;
    return d.x|(d.y<<7u)|(s<<15u);
}
vec3 i_zignore_16( uint data )
{
    uvec3 d = uvec3( data, data>>7, data>>15 ) & uvec3(127u,255u,1u);
    vec3 v = vec3(d)*2.0/vec3(127.0,255.0,1) - 1.0;
    v.z = sqrt(1.0 - dot(v.xy, v.xy)) * ((d.z==1u)?-1.0:1.0);
    return normalize(v);
}
uint zignore_24( in vec3 nor )
{
    vec2 v = 0.5 + 0.5*nor.xy;
    uvec2 d = uvec2(round(v*vec2(2047.0,4095.0)));
    uint s = (nor.z<0.0)?1u:0u;
    return d.x|(d.y<<11u)|(s<<23u);
}
vec3 i_zignore_24( uint data )
{
    uvec3 d = uvec3( data, data>>11, data>>23 ) & uvec3(2047u,4095u,1u);
    vec3 v = vec3(d)*2.0/vec3(2047.0,4095.0,1) - 1.0;
    v.z = sqrt(1.0 - dot(v.xy, v.xy)) * ((d.z==1u)?-1.0:1.0);
    return normalize(v);
}
uint zignore_32( in vec3 nor )
{
    vec2 v = 0.5 + 0.5*nor.xy;
    uvec2 d = uvec2(round(v*vec2(32767.0,65535.0)));
    uint s = (nor.z<0.0)?1u:0u;
    return d.x|(d.y<<15u)|(s<<31u);
}
vec3 i_zignore_32( uint data )
{
    uvec3 d = uvec3( data, data>>15, data>>31 ) & uvec3(32767u,65535u,1u);
    vec3 v;
    v.xy = vec2(d.xy)*2.0/vec2(32767.0,65535.0) - 1.0;
    v.z = sqrt(1.0 - dot(v.xy, v.xy)) * ((d.z==1u)?-1.0:1.0);
    return v;//normalize(v);
}

//----

uint direct_8( in vec3 nor )
{
    nor /= max(max(abs(nor.x),abs(nor.y)),abs(nor.z));
    vec3 v = 0.5 + 0.5*nor;
    uvec3 d = uvec3(round(v*vec3(7.0,7.0,3.0)));
    return d.x|(d.y<<3u)|(d.z<<6u);
}
vec3 i_direct_8( uint data )
{
    uvec3 d = uvec3( data, data>>3, data>>7 ) & uvec3(7u,7u,3u);
    vec3 v = vec3(d)*2.0/vec3(7.0,7.0,3.0) - 1.0;
    return normalize(v);
}
uint direct_12( in vec3 nor )
{
    nor /= max(max(abs(nor.x),abs(nor.y)),abs(nor.z));
    vec3 v = 0.5 + 0.5*nor;
    uvec3 d = uvec3(round(v*15.0));
    return d.x|(d.y<<4u)|(d.z<<8u);
}
vec3 i_direct_12( uint data )
{
    uvec3 d = uvec3( data, data>>4, data>>8 ) & uvec3(15u,15u,15u);
    vec3 v = vec3(d)*2.0/vec3(15.0,15.0,15.0) - 1.0;
    return normalize( v );
}
uint direct_16( in vec3 nor )
{
    nor /= max(max(abs(nor.x),abs(nor.y)),abs(nor.z)); // optional step (thanks Adam Cichocki), improves quality a bit
    vec3 v = 0.5 + 0.5*nor;
    uvec3 d = uvec3(round(v*vec3(63.0,31.0,31.0)));
    return d.x|(d.y<<6u)|(d.z<<11u);
}
vec3 i_direct_16( uint data )
{
    uvec3 d = uvec3( data, data>>6, data>>11 ) & uvec3(63u,31u,31u);
    vec3 v = vec3(d)*2.0/vec3(63.0,31.0,31.0) - 1.0;
    return normalize(v);
}
uint direct_24( in vec3 nor )
{
    nor /= max(max(abs(nor.x),abs(nor.y)),abs(nor.z));
    vec3 v = 0.5 + 0.5*nor;
    uvec3 d = uvec3(round(v*255.0));
    return d.x|(d.y<<8u)|(d.z<<16u);
}
vec3 i_direct_24( uint data )
{
    uvec3 d = uvec3( data, data>>8, data>>16 ) & 255u;
    vec3 v = vec3(d)/127.5 - 1.0;
    return normalize( v );
}
uint direct_32( in vec3 nor )
{
    nor /= max(max(abs(nor.x),abs(nor.y)),abs(nor.z));
    vec3 v = 0.5 + 0.5*nor;
    uvec3 d = uvec3(round(v*vec3(2047.0,1023.0,2047.0)));
    return d.x|(d.y<<11u)|(d.z<<21u);
}
vec3 i_direct_32( uint data )
{
    uvec3 d = uvec3( data, data>>11, data>>21 ) & uvec3(2047u,1023u,2047u);
    vec3 v = vec3(d)*2.0/vec3(2047.0,1023.0,2047.0) - 1.0;
    return normalize(v);
}

//----

uint spherical_8( in vec3 nor )
{
    vec2 v = vec2( 0.5+0.5*atan(nor.z,nor.x)/3.141593, acos(nor.y)/3.141593 );
    uvec2 d = uvec2(round(v*15.0));
    return d.x|(d.y<<4u);
}
vec3 i_spherical_8( uint data )
{
    vec2 v = vec2(data&15u,data>>4)/15.0;
    v.x = 2.0*v.x-1.0; v *= 3.141593;
    return normalize( vec3( sin(v.y)*cos(v.x), cos(v.y), sin(v.y)*sin(v.x) ));
}
uint spherical_12( in vec3 nor )
{
    vec2 v = vec2( 0.5+0.5*atan(nor.z,nor.x)/3.141593, acos(nor.y)/3.141593 );
    uvec2 d = uvec2(round(v*63.0));
    return d.x|(d.y<<6u);
}
vec3 i_spherical_12( uint data )
{
    vec2 v = vec2(data&63u,data>>6)/63.0;
    v.x = 2.0*v.x-1.0; v *= 3.141593;
    return normalize( vec3( sin(v.y)*cos(v.x), cos(v.y), sin(v.y)*sin(v.x) ));
}
uint spherical_16( in vec3 nor )
{
    vec2 v = vec2( 0.5+0.5*atan(nor.z,nor.x)/3.141593, acos(nor.y)/3.141593 );
    uvec2 d = uvec2(round(v*255.0));
    return d.x|(d.y<<8u);
}
vec3 i_spherical_16( uint data )
{
    vec2 v = vec2(data&255u,data>>8)/255.0;
    v.x = 2.0*v.x-1.0; v *= 3.141593;
    return normalize( vec3( sin(v.y)*cos(v.x), cos(v.y), sin(v.y)*sin(v.x) ));
}
uint spherical_24( in vec3 nor )
{
    vec2 v = vec2( atan(nor.z,nor.x)/3.141593, -1.0+2.0*acos(nor.y)/3.141593 );
    return packSnorm2x12(v);
}
vec3 i_spherical_24( uint data )
{
    vec2 v = unpackSnorm2x12(data);
    v.y = 0.5+0.5*v.y; v *= 3.141593;
    return normalize( vec3( sin(v.y)*cos(v.x), cos(v.y), sin(v.y)*sin(v.x) ));
}
uint spherical_32( in vec3 nor )
{
    vec2 v = vec2( atan(nor.z,nor.x)/3.141593, -1.0+2.0*acos(nor.y)/3.141593 );
    return packSnorm2x16(v);
}
vec3 i_spherical_32( uint data )
{
    vec2 v = unpackSnorm2x16(data);
    v.y = 0.5+0.5*v.y; v *= 3.141593;
    return normalize( vec3( sin(v.y)*cos(v.x), cos(v.y), sin(v.y)*sin(v.x) ));
}

//----

uint spheremap_8( in vec3 nor )
{
    vec2 v = nor.xy * inversesqrt(2.0*nor.z+2.0);
    return (uint(7.5+v.y*7.5)<<4) | uint(7.5+v.x*7.5);
}
vec3 i_spheremap_8( uint data )
{
    vec2 v = vec2(data&15u,data>>4)/7.0-1.0;
    float f = dot(v,v);
    return vec3( 2.0*v*sqrt(1.0-f), 1.0-2.0*f );
}
uint spheremap_12( in vec3 nor )
{
    vec2 v = nor.xy * inversesqrt(2.0*nor.z+2.0);
    return (uint(31.5+v.y*31.5)<<6) | uint(31.5+v.x*31.5);
}
vec3 i_spheremap_12( uint data )
{
    vec2 v = vec2(data&63u,data>>6)/31.0-1.0;
    float f = dot(v,v);
    return vec3( 2.0*v*sqrt(1.0-f), 1.0-2.0*f );
}
uint spheremap_16( in vec3 nor )
{
    vec2 v = nor.xy*inversesqrt(2.0*nor.z+2.0);
    return packSnorm2x8(v);
}
vec3 i_spheremap_16( uint data )
{
    vec2 v = unpackSnorm2x8(data);
    float f = dot(v,v);
    return vec3( 2.0*v*sqrt(1.0-f), 1.0-2.0*f );
}
uint spheremap_24( in vec3 nor )
{
    vec2 v = nor.xy*inversesqrt(2.0*nor.z+2.0);
    return packSnorm2x12(v);
}
vec3 i_spheremap_24( uint data )
{
    vec2 v = unpackSnorm2x12(data);
    float f = dot(v,v);
    return vec3( 2.0*v*sqrt(1.0-f), 1.0-2.0*f );
}
uint spheremap_32( in vec3 nor )
{
    vec2 v = nor.xy * inversesqrt(2.0*nor.z+2.0);
    return packSnorm2x16(v);
}
vec3 i_spheremap_32( uint data )
{
    vec2 v = unpackSnorm2x16(data);
    float f = dot(v,v);
    return vec3( 2.0*v*sqrt(1.0-f), 1.0-2.0*f );
}

//----

vec2 msign( vec2 v )
{
    return vec2( (v.x>=0.0) ? 1.0 : -1.0, 
                 (v.y>=0.0) ? 1.0 : -1.0 );
}

uint octahedral_8( in vec3 nor )
{
    nor.xy /= ( abs( nor.x ) + abs( nor.y ) + abs( nor.z ) );
    nor.xy  = (nor.z >= 0.0) ? nor.xy : (1.0-abs(nor.yx))*msign(nor.xy);
    uvec2 d = uvec2(round(7.5 + nor.xy*7.5));  return d.x|(d.y<<4u);
}
vec3 i_octahedral_8( uint data )
{
    uvec2 iv = uvec2( data, data>>4u ) & 15u; vec2 v = vec2(iv)/7.5 - 1.0;
    vec3 nor = vec3(v, 1.0 - abs(v.x) - abs(v.y)); // Rune Stubbe's version,
    float t = max(-nor.z,0.0);                     // much faster than original
    nor.x += (nor.x>0.0)?-t:t;                     // implementation of this
    nor.y += (nor.y>0.0)?-t:t;                     // technique
    return normalize( nor );
}
uint octahedral_12( in vec3 nor )
{
    nor.xy /= ( abs( nor.x ) + abs( nor.y ) + abs( nor.z ) );
    nor.xy  = (nor.z >= 0.0) ? nor.xy : (1.0-abs(nor.yx))*msign(nor.xy);
    uvec2 d = uvec2(round(31.5 + nor.xy*31.5));  return d.x|(d.y<<6u);
}
vec3 i_octahedral_12( uint data )
{
    uvec2 iv = uvec2( data, data>>6u ) & 63u; vec2 v = vec2(iv)/31.5 - 1.0;
    vec3 nor = vec3(v, 1.0 - abs(v.x) - abs(v.y)); // Rune Stubbe's version,
    float t = max(-nor.z,0.0);                     // much faster than original
    nor.x += (nor.x>0.0)?-t:t;                     // implementation of this
    nor.y += (nor.y>0.0)?-t:t;                     // technique
    return normalize( nor );
}
uint octahedral_16( in vec3 nor )
{
    nor /= ( abs( nor.x ) + abs( nor.y ) + abs( nor.z ) );
    nor.xy = (nor.z >= 0.0) ? nor.xy : (1.0-abs(nor.yx))*msign(nor.xy);
    return packSnorm2x8(nor.xy);
}
vec3 i_octahedral_16( uint data )
{
    vec2 v = unpackSnorm2x8(data);
    vec3 nor = vec3(v, 1.0 - abs(v.x) - abs(v.y)); // Rune Stubbe's version,
    float t = max(-nor.z,0.0);                     // much faster than original
    nor.x += (nor.x>0.0)?-t:t;                     // implementation of this
    nor.y += (nor.y>0.0)?-t:t;                     // technique
    return normalize( nor );
}
uint octahedral_24( in vec3 nor )
{
    nor /= ( abs( nor.x ) + abs( nor.y ) + abs( nor.z ) );
    nor.xy = (nor.z >= 0.0) ? nor.xy : (1.0-abs(nor.yx))*msign(nor.xy);
    return packSnorm2x12(nor.xy);
}
vec3 i_octahedral_24( uint data )
{
    vec2 v = unpackSnorm2x12(data);
    vec3 nor = vec3(v, 1.0 - abs(v.x) - abs(v.y)); // Rune Stubbe's version,
    float t = max(-nor.z,0.0);                     // much faster than original
    nor.x += (nor.x>0.0)?-t:t;                     // implementation of this
    nor.y += (nor.y>0.0)?-t:t;                     // technique
    return normalize( nor );
}
uint octahedral_32( in vec3 nor )
{
    nor.xy /= ( abs( nor.x ) + abs( nor.y ) + abs( nor.z ) );
    nor.xy  = (nor.z >= 0.0) ? nor.xy : (1.0-abs(nor.yx))*msign(nor.xy);
    //return packSnorm2x16(nor.xy);
    uvec2 d = uvec2(round(32767.5 + nor.xy*32767.5));  return d.x|(d.y<<16u);
}
vec3 i_octahedral_32( uint data )
{
    //vec2 v = unpackSnorm2x16(data);
    uvec2 iv = uvec2( data, data>>16u ) & 65535u; vec2 v = vec2(iv)/32767.5 - 1.0;
    vec3 nor = vec3(v, 1.0 - abs(v.x) - abs(v.y)); // Rune Stubbe's version,
    float t = max(-nor.z,0.0);                     // much faster than original
    nor.x += (nor.x>0.0)?-t:t;                     // implementation of this
    nor.y += (nor.y>0.0)?-t:t;                     // technique
    return normalize( nor );
}

//----

const float PI = 3.1415926535897932384626433832795;
const float PHI = 1.6180339887498948482045868343656;
float madfrac( float a,float b) { return a*b-floor(a*b); }
vec2  madfrac( vec2 a, float b) { return a*b-floor(a*b); }
float sf2id(vec3 p, float n) 
{
    float phi = min(atan(p.y, p.x), PI), cosTheta = p.z;
    
    float k  = max(2.0, floor( log(n * PI * sqrt(5.0) * (1.0 - cosTheta*cosTheta))/ log(PHI*PHI)));
    float Fk = pow(PHI, k)/sqrt(5.0);
    
    vec2 F = vec2( round(Fk), round(Fk * PHI) );

    vec2 ka = -2.0*F/n;
    vec2 kb = 2.0*PI*madfrac(F+1.0, PHI-1.0) - 2.0*PI*(PHI-1.0);    
    mat2 iB = mat2( ka.y, -ka.x, -kb.y, kb.x ) / (ka.y*kb.x - ka.x*kb.y);

    vec2 c = floor( iB * vec2(phi, cosTheta - (1.0-1.0/n)));
    float d = 8.0;
    float j = 0.0;
    for( int s=0; s<4; s++ ) 
    {
        vec2 uv = vec2( float(s-2*(s/2)), float(s/2) );
        
        float cosTheta = dot(ka, uv + c) + (1.0-1.0/n);
        
        cosTheta = clamp(cosTheta, -1.0, 1.0)*2.0 - cosTheta;
        float i = floor(n*0.5 - cosTheta*n*0.5);
        float phi = 2.0*PI*madfrac(i, PHI-1.0);
        cosTheta = 1.0 - (2.0*i + 1.0)/n;
        float sinTheta = sqrt(1.0 - cosTheta*cosTheta);
        
        vec3 q = vec3( cos(phi)*sinTheta, sin(phi)*sinTheta, cosTheta);
        float squaredDistance = dot(q-p, q-p);
        if (squaredDistance < d) 
        {
            d = squaredDistance;
            j = i;
        }
    }
    return j;
}

vec3 id2sf( float i, float n) 
{
    float phi = 2.0*PI*madfrac(i,PHI);
    float zi = 1.0 - (2.0*i+1.0)/n;
    float sinTheta = sqrt( 1.0 - zi*zi);
    return vec3( cos(phi)*sinTheta, sin(phi)*sinTheta, zi);
}

uint fibonacci_8( in vec3 nor )
{
    return uint(sf2id(nor,exp2(8.0)));
}
vec3 i_fibonacci_8( uint data )
{
    return id2sf(float(data),exp2(8.0));
}
uint fibonacci_12( in vec3 nor )
{
    return uint(sf2id(nor,float(1<<12)));
}
vec3 i_fibonacci_12( uint data )
{
    return id2sf(float(data),float(1<<12));
}
uint fibonacci_16( in vec3 nor )
{
    return uint(sf2id(nor,float(1<<16)));
}
vec3 i_fibonacci_16( uint data )
{
    return id2sf(float(data),float(1<<16));
}
uint fibonacci_24( in vec3 nor )
{
    return uint(sf2id(nor,float(1<<24)));
}
vec3 i_fibonacci_24( uint data )
{
    return id2sf(float(data),float(1<<24));
}
uint fibonacci_32( in vec3 nor )
{
    return uint(sf2id(nor,exp2(32.0)));
}
vec3 i_fibonacci_32( uint data )
{
    return id2sf(float(data),exp2(32.0));
}
//=============================================================

float map( vec3 p )
{
    p.x *= 0.8;
    p *= 2.6;
    p.xyz += 1.000*sin(  2.0*p.yzx );
    //p.xyz -= 0.500*sin(  4.0*p.yzx );
    float d = length( p.xyz ) - 1.5;
	return d * 0.15;
}


float intersect( in vec3 ro, in vec3 rd )
{
	const float maxd = 4.0;

	float precis = 0.001;
    float h = 1.0;
    float t = 1.0;
    for( int i=0; i<256; i++ )
    {
        if( (h<precis) || (t>maxd) ) break;
	    h = map( ro+rd*t );
        t += h;
    }

    if( t>maxd ) t=-1.0;
	return t;
}

vec3 calcNormal( in vec3 pos )
{
    // from Paul Malin (4 samples only in a tetrahedron	
    vec2 e = vec2(1.0,-1.0)*0.002;
    return normalize( e.xyy*map( pos + e.xyy ) + 
					  e.yyx*map( pos + e.yyx ) + 
					  e.yxy*map( pos + e.yxy ) + 
					  e.xxx*map( pos + e.xxx ) );
}

//============================================================
#define AA 2

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec3 tot = vec3(0.0);
    
    const ivec2 grid = ivec2(7,5);
    
    for( int j=0; j<AA; j++ )
    for( int i=0; i<AA; i++ )
    {
        vec2 off = vec2(i,j)/float(AA) - 0.5;
        
        vec2  uv = vec2(grid)*(fragCoord+off)/iResolution.xy;
        ivec2 cx = ivec2(uv);
        int   id = cx.y*grid.x + cx.x;
        vec2  px = uv - vec2(cx);

        float anim = cos( 0.2*iTime + 2.2 );
        float zoom = smoothstep( 0.2, 0.5, anim ); 
        float serr = smoothstep( 0.85, 0.9, abs(anim) ); 


        //-----------------------------------------------------
        // camera
        //-----------------------------------------------------
        vec2  p = (-1.0+2.0*px) * 7.5 / (vec2(float(grid.x)*iResolution.y,float(grid.y)*iResolution.x)/iResolution.y);
        vec3 ro = vec3(0.0,0.3*zoom,2.9);

        vec3 ta = vec3(0.0,0.0,0.0);

        vec3 rd = normalize( vec3(p.xy,-2.0-6.0*zoom) );

        vec3 col = vec3(0.0);

        //-----------------------------------------------------
        // intersect geometry
        //-----------------------------------------------------
        #ifdef SPHERES
        float b = dot( ro, rd );
        float c = dot( ro, ro ) - 1.0;
        float h = b*b - c;
        #else
        float h = intersect( ro, rd );
        #endif
        if( h>0.0 )
        {
            #ifdef SPHERES
            // compute intersection
            float t = -b - sqrt( h );
            // compute normal
            vec3 nor = normalize( ro + t*rd );
            #else
            vec3 pos = ro + h*rd;
            vec3 nor = calcNormal( pos );
            #endif

            //-----------------------------------------------------
            // compress/encode and decompress/decode normal
            //-----------------------------------------------------
            uint data = 0u;
            vec3 mor = vec3(0.0);

                 if( id==  0 ) { data = direct_32( nor );     mor = i_direct_32( data );}
            else if( id==  1 ) { data = cube_32( nor );       mor = i_cube_32( data );}
            else if( id==  2 ) { data = zignore_32( nor );    mor = i_zignore_32( data );}
            else if( id==  3 ) { data = spherical_32( nor );  mor = i_spherical_32( data );}
            else if( id==  4 ) { data = spheremap_32( nor );  mor = i_spheremap_32( data );}
            else if( id==  5 ) { data = fibonacci_32( nor );  mor = i_fibonacci_32( data );}
            else if( id==  6 ) { data = octahedral_32( nor ); mor = i_octahedral_32( data );}
            
            else if( id==  7 ) { data = direct_24( nor );     mor = i_direct_24( data );}
            else if( id==  8 ) { data = cube_24( nor );       mor = i_cube_24( data );}
            else if( id==  9 ) { data = zignore_24( nor );    mor = i_zignore_24( data );}
            else if( id== 10 ) { data = spherical_24( nor );  mor = i_spherical_24( data );}
            else if( id== 11 ) { data = spheremap_24( nor );  mor = i_spheremap_24( data );}
            else if( id== 12 ) { data = fibonacci_24( nor );  mor = i_fibonacci_24( data );}
            else if( id== 13 ) { data = octahedral_24( nor ); mor = i_octahedral_24( data );}
            
            else if( id== 14 ) { data = direct_16( nor );     mor = i_direct_16( data );}
            else if( id== 15 ) { data = cube_16( nor );       mor = i_cube_16( data );}
            else if( id== 16 ) { data = zignore_16( nor );    mor = i_zignore_16( data );}
            else if( id== 17 ) { data = spherical_16( nor );  mor = i_spherical_16( data );}
            else if( id== 18 ) { data = spheremap_16( nor );  mor = i_spheremap_16( data );}
            else if( id== 19 ) { data = fibonacci_16( nor );  mor = i_fibonacci_16( data );}
            else if( id== 20 ) { data = octahedral_16( nor ); mor = i_octahedral_16( data );}

            else if( id== 21 ) { data = direct_12( nor );     mor = i_direct_12( data );}
            else if( id== 22 ) { data = cube_12( nor );       mor = i_cube_12( data );}
            else if( id== 23 ) { data = zignore_12( nor );    mor = i_zignore_12( data );}
            else if( id== 24 ) { data = spherical_12( nor );  mor = i_spherical_12( data );}
            else if( id== 25 ) { data = spheremap_12( nor );  mor = i_spheremap_12( data );}
            else if( id== 26 ) { data = fibonacci_12( nor );  mor = i_fibonacci_12( data );}
            else if( id== 27 ) { data = octahedral_12( nor ); mor = i_octahedral_12( data );}

            else if( id== 28 ) { data = direct_8( nor );      mor = i_direct_8( data );}
            else if( id== 29 ) { data = cube_8( nor );        mor = i_cube_8( data );}
            else if( id== 30 ) { data = zignore_8( nor );     mor = i_zignore_8( data );}
            else if( id== 31 ) { data = spherical_8( nor );   mor = i_spherical_8( data );}
            else if( id== 32 ) { data = spheremap_8( nor );   mor = i_spheremap_8( data );}
            else if( id== 33 ) { data = fibonacci_8( nor );   mor = i_fibonacci_8( data );}
            else if( id== 34 ) { data = octahedral_8( nor );  mor = i_octahedral_8( data );}
            
            //-----------------------------------------------------
            // render reflection
            //-----------------------------------------------------

            vec3 ref = reflect( rd, mor );
            col = texture(iChannel2,ref).xyz;

            if( p.x>0.0 )
            {
                col = 0.4 + 0.4*ref + 32.0*pow( clamp(dot(ref,vec3(0.5773)),0.0,1.0), 128.0 );
            }

            // error
            float err = acos(dot(mor,nor));
            err = clamp( err/radians(0.5), 0.0, 1.0 );
            col = mix( col, 0.5 - 0.5*cos( sqrt(err)*3.1416 + vec3(0.0,2.0,4.0) ), serr );

            // a bit of shading...
            col *= abs(mor.z);
        }
        tot += col;
    }   
    tot /= float(AA*AA);
    
    fragColor = vec4( tot, 1.0 );
}
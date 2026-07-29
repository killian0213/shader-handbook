// Image (image) — Basic Color Picker by iq
// https://www.shadertoy.com/view/4cjBDc

// The MIT License
// Copyright © 2024 Inigo Quilez
// https://www.youtube.com/c/InigoQuilez
// https://iquilezles.org/
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions: The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software. THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

// Yet another basic color picker.
//    Common tab  : the picker code
//    Buffer A tab: mouse interaction with picker
//    Image tab   : a scene using the color from the picker.
//
// Bonus: the scene shows analytical ambient occlusion, color
//        bleeding and antialiasing.

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    // get color form piker
	vec3 color = pow( picker_getRGB(iChannel0), vec3(2.2) );

    // camera
    vec2 p = (2.0*fragCoord-iResolution.xy)/iResolution.y;
    const float flen = 2.0;
	vec3 ro = vec3(0.0, 0.0, 4.0 );
	vec3 rd = normalize( vec3(p,-flen) );
    
    // render background
    vec3 col = vec3(1.0);

    // render plane
    float t = (-1.0-ro.y)/rd.y;
    if( t>0.0 )
    {
        vec3  pos = ro + t*rd;
        float l2 = dot(pos,pos);
        float occ = 1.0+pos.y/(l2*sqrt(l2)); // https://iquilezles.org/articles/sphereao/
        col = occ*(occ+(1.0-occ)*color);
    }

    // render sphere
	float b = dot( ro, rd );
	float c = dot( ro, ro ) - 1.0;
	float h = b*b - c;
	if( h>0.0 )
    {
	    t = -b-sqrt(h);
        vec3  pos = ro + t*rd;
        vec3  nor = normalize(pos);
        float occ = 0.5+0.5*nor.y; // plane occlusion
        float d = 1.0-sqrt(max(0.0,1.0-h)); // https://iquilezles.org/articles/spherefunctions
        float al = clamp( 0.5*iResolution.y*flen*d/t, 0.0, 1.0 );
        col = mix(col,occ*mix(color,2.0*color*color,max(-nor.y,0.0)),al);
    }
    
    // gamma
    col = pow( col, vec3(0.4545) );

    // render color picker
    col = piker_draw( iChannel0, col, fragCoord, iResolution.xy );

    fragColor = vec4( col, 1.0 );
}
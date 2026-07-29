// Common (common) — Common shader Tab by iq
// https://www.shadertoy.com/view/4l2BW3

// The MIT License
// Copyright © 2018 Inigo Quilez
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions: The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software. THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.


// This shader shows how to use the Common tab in Shadertoy: all tabs inherit the
// code in the "Common" tab. In this case, that's used to get the Image and the
// Sound shader to reuse the same music pattern to display the visuals and produce
// the sound.


const float speed = 1.5;

float patternFrac( float x )
{
    return fract(speed*x);
}

const int wholeNotes[] = int[](0,2,4,5,7,9,11);

float patternNote( float x )
{
    int noteID = int( 7.0+7.0*sin( floor(speed*x) ) );
    return float( wholeNotes[noteID%7] + 12*(noteID/7) );
}

float patternFreq( float x )
{
    float f = patternNote(x);
    return 55.0*pow(2.0,f/12.0);
}
// Buffer C (buffer) — Font: Bitmap vs SDF by MichaelPohoreski
// https://www.shadertoy.com/view/llK3Wm

// SDF "A"

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    float p; 
    int   x, y;
    int   u, v;
    
    u = int( fragCoord.x );
    v = int( fragCoord.y );

    #define _ 1.0
    
    float g = 0.0;
    float c = 0.0; // Black or no background

#if 0
// 8x8
    if (v == 0)
    {
        if (u == 3) g =  84.0;
        if (u == 4) g =  74.0;
    }
    if (v == 1)
    {
        if (u == 2) g =  79.0;
        if (u == 3) g = 255.0;
        if (u == 4) g = 183.0;
    }
    if (v == 2)
    {
        if (u == 2) g = 173.0;
        if (u == 3) g = 166.0;
        if (u == 4) g = 255.0;
    }
    if (v == 3)
    {
        if (u == 2) g = 250.0;
        if (u == 3) g =  77.0;
        if (u == 4) g = 211.0;
        if (u == 5) g = 140.0;
    }
    if (v == 4)
    {
        if (u == 1) g = 122.0;
        if (u == 2) g = 239.0;
        if (u == 3) g = 177.0;
        if (u == 4) g = 177.0;
        if (u == 5) g = 224.0;
    }
    if (v == 5)
    {
        if (u == 1) g = 207.0;
        if (u == 2) g = 144.0;
        if (u == 3) g = 121.0;
        if (u == 4) g = 122.0;
        if (u == 5) g = 255.0;
        if (u == 6) g =  91.0;
    }
    if (v == 6)
    {
        if (u == 0) g =  65.0;
        if (u == 1) g = 207.0;
        if (u == 5) g = 182.0;
        if (u == 6) g = 185.0;
    }
#else
    
// 16x16
    // SDF "A" from
    // https://github.com/Chlumsky/msdfgen
    // https://cloud.githubusercontent.com/assets/18639794/14770360/20c51156-0a70-11e6-8f03-ed7632d07997.png
    if (v == 1)
    {
        if (u == 6) g = 81.0;
        if (u == 7) g = 84.0;
        if (u == 8) g = 85.0;
        if (u == 9) g = 75.0;
    }   
    if (v == 2)
    {
        if (u == 6) g = 154.0;
        if (u == 7) g = 207.0;
        if (u == 8) g = 207.0;
        if (u == 9) g = 140.0;
    }   
    if (v == 3)
    {
        if (u == 5) g =  79.0;
        if (u == 6) g = 196.0;
        if (u == 7) g = 255.0;
        if (u == 8) g = 255.0;
        if (u == 9) g = 183.0;
        if (u ==10) g =  64.0;
    }
    if (v == 4)
    {
        if (u == 5) g = 129.0;
        if (u == 6) g = 234.0;
        if (u == 7) g = 206.0;
        if (u == 8) g = 223.0;
        if (u == 9) g = 224.0;
        if (u ==10) g = 117.0;
    }
    if (v == 5)
    {
        if (u == 4) g =  47.0;
        if (u == 5) g = 173.0;
        if (u == 6) g = 255.0;
        if (u == 7) g = 166.0;
        if (u == 8) g = 185.0; // SDF lack of precision, should be 48x48
        if (u == 9) g = 255.0;
        if (u ==10) g = 162.0;
        if (u ==11) g =  32.0;
    }
    if (v == 6)
    {
        if (u == 4) g = 102.0;
        if (u == 5) g = 212.0;
        if (u == 6) g = 230.0;
        if (u == 7) g = 124.0;
        if (u == 8) g = 144.0;
        if (u == 9) g = 248.0;
        if (u ==10) g = 204.0;
        if (u ==11) g =  91.0;
    }
    if (v == 7)
    {
        if (u == 4) g = 148.0;
        if (u == 5) g = 250.0;
        if (u == 6) g = 194.0;
        if (u == 7) g =  77.0;
        if (u == 8) g =  99.0;
        if (u == 9) g = 211.0;
        if (u ==10) g = 243.0;
        if (u ==11) g = 140.0;
    }
    if (v == 8)
    {
        if (u == 3) g =  72.0;
        if (u == 4) g = 190.0;
        if (u == 5) g = 250.0;
        if (u == 6) g = 155.0;
        if (u == 7) g =  42.0;
        if (u == 8) g =  45.0;
        if (u == 9) g = 173.0;
        if (u ==10) g = 255.0;
        if (u ==11) g = 184.0;
        if (u ==12) g =  64.0;
    }
    if (v == 9)
    {
        if (u == 3) g = 122.0;
        if (u == 4) g = 228.0;
        if (u == 5) g = 239.0;
        if (u == 6) g = 177.0;
        if (u == 7) g = 177.0;
        if (u == 8) g = 177.0;
        if (u == 9) g = 177.0;
        if (u ==10) g = 254.0;
        if (u ==11) g = 224.0;
        if (u ==12) g = 116.0;
    }
    if (v == 10)
    {
        if (u == 3) g = 37.0;
        if (u == 3) g = 166.0;
        if (u == 4) g = 255.0;
        if (u == 5) g = 234.0;
        if (u == 6) g = 235.0;
        if (u == 7) g = 235.0;
        if (u == 8) g = 235.0;
        if (u == 9) g = 235.0;
        if (u ==10) g = 235.0;
        if (u ==11) g = 255.0;
        if (u ==12) g = 163.0;
        if (u ==13) g =  32.0;
    }
    if (v == 11)
    {
        if (u == 2) g =  95.0;
        if (u == 3) g = 207.0;
        if (u == 4) g = 246.0;
        if (u == 5) g = 144.0;
        if (u == 6) g = 122.0;
        if (u == 7) g = 121.0;
        if (u == 8) g = 121.0;
        if (u == 9) g = 122.0;
        if (u ==10) g = 158.0;
        if (u ==11) g = 255.0;
        if (u ==12) g = 204.0;
        if (u ==13) g =  91.0;
    }
    if (v == 12)
    {
        if (u == 2) g = 143.0;
        if (u == 3) g = 245.0;
        if (u == 4) g = 212.0;
        if (u == 5) g = 100.0;

        if (u ==10) g = 113.0;
        if (u ==11) g = 221.0;
        if (u ==12) g = 243.0;
        if (u ==13) g = 141.0;
    }
    if (v == 13)
    {
        if (u == 1) g =  65.0;
        if (u == 2) g = 185.0;
        if (u == 3) g = 207.0;
        if (u == 4) g = 174.0;
        if (u == 5) g =  47.0;

        if (u ==10) g =  60.0;
        if (u ==11) g = 182.0;
        if (u ==12) g = 207.0;
        if (u ==13) g = 184.0;
        if (u ==14) g =  64.0;
    }
    if (v == 14)
    {
        if (u == 1) g =  55.0;
        if (u == 2) g =  84.0;
        if (u == 3) g =  85.0;
        if (u == 4) g =  84.0;

        if (u ==11) g =  85.0;
        if (u ==12) g =  84.0;
        if (u ==13) g =  85.0;
        if (u ==14) g =  44.0;
    }
#endif
    
    c = g / 255.0;
    fragColor = vec4( c );
}
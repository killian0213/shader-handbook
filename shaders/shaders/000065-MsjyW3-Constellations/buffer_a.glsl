// Buf A (buffer) — Constellations by anomes
// https://www.shadertoy.com/view/MsjyW3

// -------------------------------------------
// PRECALCULATE/ANIMATE POINTS PER MACRO-BLOCK
// -------------------------------------------


// must be the same as in 'Main Image'
#define POINTS_SIZE 12
#define POINTS_NUMBER POINTS_SIZE*POINTS_SIZE

// 
#define BLOCK_SIZE 10
#define BLOCK_NUMBER BLOCK_SIZE*BLOCK_SIZE

#define DEPTH_OF_FIELD 3.
#define SPACING 2.8
#define POSITION vec2(  1.4  ,  0.7  )
#define SCALE    vec2(  1.1  ,  0.5  )
#define TIME iTime


int blockIndexForPosition(vec2 pos)
{
	vec2 p2 = vec2(  (pos.x*iResolution.y/iResolution.x+1.)/2.  ,  (pos.y+1.)/2.  );
    float size = 1./float(BLOCK_SIZE);
    return int(p2.x/size) + int(p2.y/size)*BLOCK_SIZE;
}

vec4 rectForBlockIndex(int index)
{
   	float size = 1./float(BLOCK_SIZE);
    int y = index/BLOCK_SIZE;
    int x = index - y*BLOCK_SIZE;
    return vec4( float(x)*size, float(y)*size, size, size );
}

vec4 rectInset(vec4 rect, float inset)
{
    return rect + vec4(-inset,-inset,2.*inset,2.*inset);
}

bool pointInRect(vec4 rect, vec2 point)
{
    return rect.x <= point.x && point.x < rect.x+rect.z &&
           rect.y <= point.y && point.y < rect.y+rect.w;
}

vec4 pointAtIndex(int index)
{
    float i = mod(float(index), float(POINTS_SIZE));
    float j = floor(  float(index)/float(POINTS_SIZE)  );
    float step = SPACING/float(POINTS_SIZE);
    vec4 point = vec4(SCALE.x*step*i-POSITION.x, SCALE.y*step*j-POSITION.y, 0., 0.);
    float factor = mod(  (j+1.)*(i+1.)  ,  22.  ) + 1.;
    point.x += sin((20.+TIME/2.)*0.03*factor+i*0.5)*0.3;
    point.y += cos((20.+TIME/3.)*0.01*factor)*0.3;
    point.z = DEPTH_OF_FIELD*pow(  cos((20.+TIME)*0.01*factor)  ,16.);
    point.w = float(  blockIndexForPosition(point.xy)  );
    return point;
    if( point.w == 0. )
    {
        point.xyz = vec3(1., 0., 0.);
    }
    else if( point.w == 1. )
    {
        point.xyz = vec3(0., 1., 0.);
    }
    else if( point.w == 2. )
    {
        point.xyz = vec3(0., 0., 1.);
    }
    else
    {
        point.xyz = vec3(1., 1., 0.);
    }
    return point;
}


void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec4 color = vec4(-100.);
    if( fragCoord.x <= float(POINTS_NUMBER) && fragCoord.y < float(BLOCK_NUMBER) )
    {
        int index = int(fragCoord.x);
		vec4 point = pointAtIndex(index);
        int blockIndex = int(fragCoord.y);
        vec4 rect = rectForBlockIndex(blockIndex);
        rect = rectInset(rect, 0.1);
		vec2 p2 = vec2(  (point.x*iResolution.y/iResolution.x+1.)/2.  ,  (point.y+1.)/2.  );
        bool inside = pointInRect(rect, p2);
        if(  inside  )//||  (point.w-0.5 < fragCoord.y && fragCoord.y <= point.w+0.5)  )
        {
            color = point;
            //color = vec4(1.);
        }
    }
    fragColor = color;
}



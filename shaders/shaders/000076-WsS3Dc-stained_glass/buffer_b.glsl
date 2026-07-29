// Buffer B (buffer) — stained glass by flockaroo
// https://www.shadertoy.com/view/WsS3Dc

// created by florian berger (flockaroo) - 2019
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

// multi scale subdivision

// recursively find min and max pixel brightness in a certain region
// going from small scales to higher scales
// (emulating multiple passes by dedicating each frame to a different pass)

#define iPassIndex (iFrame%NumPasses)

//#define ResMap (vec2(512,256))
#define ResMap min(pow(vec2(2.),floor(log2(iResolution.xy))),vec2(512,256))

#define Res iResolution.xy
#define Res0 vec2(textureSize(iChannel0,0))
#define Res1 ResMap
#define Res2 vec2(textureSize(iChannel2,0))

bool getNBPixPos(ivec2 coord, int level, inout ivec2 pos1, inout ivec2 pos2)
{
    if (level==0) { pos1=coord*ivec2(2,1); pos2=pos1+ivec2(1,0); return coord.x<int(Res1.x)/2; }
    
    ivec2 dir = ivec2(1,0);
    ivec2 s = ivec2(Res1)/(dir+1);
    ivec2 sp = s;
    ivec2 o = ivec2(0);
    ivec2 op = o;
    for(int i=0;i<level;i++) {
        op=o; o+=s*dir;
        dir=(dir+1)&1;
        sp=s; s/=dir+1;
    }
    
    ivec2 c = coord-o;
    pos1=op+c*(dir+1);
    pos2=pos1+dir;
    return c.x>=0 && c.x<s.x && c.y>=0 && c.y<s.y;
}

vec2 getLevelCoords(vec2 coord, int level, inout vec2 frameCoord)
{

    ivec2 dir = ivec2(1,0);
    ivec2 s = ivec2(Res1)/(dir+1);
    ivec2 sp = s;
    ivec2 o = ivec2(0);
    ivec2 op = o;
    for(int i=0;i<level;i++) {
        op=o; o+=s*dir;
        dir=(dir+1)&1;
        sp=s; s/=dir+1;
    }

    vec2 c = coord*vec2(s)+vec2(o);
    frameCoord=fract(c);
    return (floor(c)+.5)/Res1;
}


float colDist(vec4 c1, vec4 c2)
{
    return dot(c1.xyz-c2.xyz,vec3(.3333));
}

bool isBigger(vec4 c1, vec4 c2)
{
    return colDist(c1,c2)>0.;
}

vec4 getCol(vec2 coord)
{
    return texture(iChannel0,coord/Res1.xy);
}

void mainImage( out vec4 fragColor, vec2 fragCoord )
{
    if( fragCoord.x>Res1.x || fragCoord.y>Res1.y ) discard;
    if(iPassIndex==0) {vec2 coord=fragCoord; fragColor=vec4(coord,coord); return; }
    
    int isVert = (iPassIndex+1)&1;
    ivec2 dir = (ivec2(0,1)+iPassIndex+1)&1;
    
    ivec2 coord=ivec2(fragCoord);

    // copy previous pass
    fragColor=texelFetch(iChannel1,coord,0);
    
    // who are the neighbours?
    ivec2 pos1, pos2;
    if (!getNBPixPos(coord,iPassIndex-1,pos1,pos2)) { return; }
    
    vec4 coordMinMax1 = texelFetch(iChannel1,pos1,0);
    vec4 coordMinMax2 = texelFetch(iChannel1,pos2,0);
    vec4 cmin1=getCol(coordMinMax1.xy);
    vec4 cmin2=getCol(coordMinMax2.xy);
    vec4 cmax1=getCol(coordMinMax1.zw);
    vec4 cmax2=getCol(coordMinMax2.zw);
    
    fragColor.xy = isBigger(cmin2,cmin1)?coordMinMax1.xy:coordMinMax2.xy;
    fragColor.zw = isBigger(cmax1,cmax2)?coordMinMax1.zw:coordMinMax2.zw;
    // debug pass levels
    //fragColor.xyz = vec3(0) + float(iPassIndex)/15.;
    //fragColor.w = 1.;
}


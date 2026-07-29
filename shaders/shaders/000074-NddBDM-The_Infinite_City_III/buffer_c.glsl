// Buffer C (buffer) — The Infinite City III by fancyzero
// https://www.shadertoy.com/view/NddBDM

//render 2d patterns into 3d scene
#define CAMERA_INITAL_DIST (mix(5000.,iResolution.x*1.2, mousePos.y))
#define MAX_TRACE 512
//could be very slow
#define TRANSPARENT_ITERS 1

// Set AA to 1 if your machine is too slow
#if HW_PERFORMANCE==1
#define AA 2
#else
#define AA 1  
#endif
const float maxHeight = 25.;
const float materialDensity = 1.0;

float getScale()
{
    return iResolution.y;
}

float easeOutBounce(float x)
{
    const float n1 = 7.5625;
    const float d1 = 2.75;
    if ( x > 1.)
    return 1.;

    if (x < 1. / d1) {
        return n1 * x * x;
    } else if (x < 2. / d1) {
        return n1 * (x -= 1.5 / d1) * x + 0.75;
    } else if (x < 2.5 / d1) {
        return n1 * (x -= 2.25 / d1) * x + 0.9375;
    } else {
        return n1 * (x -= 2.625 / d1) * x + 0.984375;
    }
}


vec3 pal( in float t, in vec3 a, in vec3 b, in vec3 c, in vec3 d )
{
    return a + b*cos( 6.28318*(c*t+d) );
}


vec4 HeightField( vec2 X )
{
    float aspect = iResolution.x/iResolution.y;
    X /=vec2(getScale()*aspect,getScale() );
    X += .5; 
    vec4 v = texture(iChannel0, X);
    
    float targetHeight = (sin(v.z*0.41)+1.)/2.;
    targetHeight *= targetHeight ;
    
    float height =  2.+(maxHeight-4.)* mix(0., targetHeight,easeOutBounce((iTime-v.y)));
    height = floor(height);
    v.x *= height;
    return v;
}

struct HitInfo
{
    vec2 t;
    vec3 pos;
    vec3 n;
    vec3 pos2;
    vec3 n2;
    vec4 fieldValue;
    float smoothness;
    bool hit;
};

HitInfo Intersect( vec3 cam ,vec3 rayDir, vec2 pixel )
{
    HitInfo ret;
    ret.hit = false;

    float voxelSize = getScale()/iResolution.y;
    vec4 fieldValue = HeightField(pixel);
    float h = max(0.0001,fieldValue.x);
    vec2 center = (floor(pixel/voxelSize)+0.5 )*voxelSize;
    vec3 aabb = vec3(voxelSize*0.5, h, voxelSize*.5 );
    
    vec2 t = boxIntersection(cam-vec3(center.x, 0., center.y), rayDir, aabb, ret.n);
    if ( t.y > t.x )
    {
        ret.pos = cam+rayDir * t.x;
        ret.pos2 = cam+rayDir*t.y;
        ret.t = t;
        ret.n2 = ret.n;
        ret.fieldValue = fieldValue;
        ret.hit = true;
    }
    
    return ret;
}

vec4 getAABB( vec3 worldPos, int level)
{
    return vec4(0.);
}

bool March( vec3 start, vec3 end, out vec3 pos, out vec3 n, out vec3 pos2, out vec3 n2, out vec4 fieldValue )
{
    float voxelSize = getScale()/iResolution.y;
    vec2 p0 = start.xz;
    vec2 p1 = end.xz;
    vec3 rayDir = normalize(end-start);
    vec2 rd = p1-p0;
    vec2 p = floor(p0);
    vec2 rdinv = 1.0 / rd;
    vec2 stp = sign(rd);
	vec2 delta = min(rdinv * stp, 1.0);
    
    // start at intersection of ray with initial cell
    vec2 t_max = abs((p + max(stp, vec2(0.0)) - p0) * rdinv);
    
    for (int i = 0; i < MAX_TRACE; ++i) 
    {         
        HitInfo hitInfo = Intersect(start ,rayDir, p);
        if (hitInfo.hit)
        {
            pos = hitInfo.pos;
            n = hitInfo.n;
            pos2 = hitInfo.pos2;
            n2  = hitInfo.n2;
            fieldValue = hitInfo.fieldValue;
            return true;
        }
        float next_t = min(t_max.x,t_max.y);
        if (next_t > 1.0) 
            return false;
                
        vec2 cmp = step(t_max.xy, t_max.yx);
        t_max += delta * cmp;
        p += stp * cmp;
        
    }    
   
     return false;
}

vec3 getColor(vec3 n, vec3 pos, vec4 fieldValue)
{
     float h = fieldValue.x;
    int width = int(iResolution.x);
    int p =  int( mod(texelFetch(iChannel2, ivec2(width-1,0),0).y,4.) );
    if ( fieldValue.x <= 0.)
        return vec3(0.114,0.114,0.184);
    float a = fieldValue.z*2.718238271823*10.;
    
    vec3 c =  pal( a, vec3(0.5,0.5,0.5),vec3(0.5,0.5,0.5),vec3(1.0,1.0,1.0),vec3(0.0,0.33,0.67) )*fieldValue.a;

     if (p == 1)
            c =pal( a, vec3(0.5,0.5,0.5),vec3(0.5,0.5,0.5),vec3(1.0,1.0,1.0),vec3(0.0,0.10,0.20) )*fieldValue.a;
    if (p == 2)
            c = pal( a, vec3(0.5,0.5,0.5),vec3(0.5,0.5,0.5),vec3(1.2,1.0,1.5),vec3(0.671,0.678,0.000) )*fieldValue.a;
    if (p == 3)
            c =pal( a, vec3(0.8,0.5,0.4),vec3(0.2,0.4,0.2),vec3(2.0,1.0,1.0),vec3(0.0,0.25,0.25) )*fieldValue.a;
     
        return c*0.9;
}

vec2 getShiness(vec4 fieldValue)
{
    if ( fieldValue.x <= 0.)
        return vec2(5,0.2);
       
    return vec2(20,.9);
}

float getDensity(float def, vec4 fieldValue)
{
    if ( fieldValue.x <= 0.)
        return 8000.;
    return def;
}


/////////////////////
//
////////////////////
vec3 MarchLight( float density, vec3 start, vec3 end, vec3 surfaceN, out vec3 firstN)
{    
    float voxelSize = getScale()/iResolution.y;
    vec2 p0 = start.xz;
    vec2 p1 = end.xz;
    vec3 rayDir = normalize(end-start);
    vec2 rd = p1-p0;
    vec2 p = floor(p0);
    vec2 rdinv = 1.0 / rd;
    vec2 stp = sign(rd);
	vec2 delta = min(rdinv * stp, 1.0);
    
    vec3 opticalDepth = vec3(0);
 
    
    // start at intersection of ray with initial cell
    vec2 t_max = abs((p + max(stp, vec2(0.0)) - p0) * rdinv);
    vec3 pos;
    vec3 n;
    vec3 pos2;
    vec3 n2;
    bool firstHit = false;

    for (int i = 0; i < MAX_TRACE; ++i) 
    {   
        HitInfo hitInfo = Intersect(start ,rayDir, p);
        if (hitInfo.hit)
        {
            if (!firstHit)
            {
                firstN = n;
                firstHit = true;
            }
            float far = min( hitInfo.t.y, length(end-start));
            float travelDepth = max(0.,(far-hitInfo.t.x));

            opticalDepth += vec3(travelDepth*getDensity(density,hitInfo.fieldValue)*(1.-getColor(surfaceN,end,hitInfo.fieldValue)));

            if (far < hitInfo.t.y || (opticalDepth.x >30.0 && opticalDepth.x >30.0 && opticalDepth.x >30.0))
            {
                break;
            }
        }
        vec2 cmp = step(t_max.xy, t_max.yx);
        t_max += delta * cmp;
        p += stp * cmp;
    }       
    return opticalDepth;


}


mat3x3 LookAt( vec3 src, vec3 target, vec3 up)
{
    vec3 forward = normalize(target-src);
    vec3 right = normalize(cross(forward, up));
    up = normalize(cross(right, forward));
    return mat3x3(right, -up, forward);
}

vec3 ACESFilm(vec3 x)
{
    float a = 2.51;
    float b = 0.03;
    float c = 2.43;
    float d = 0.59;
    float e = 0.14;
    return (x*(a*x+b))/(x*(c*x+d)+e);
}


void mainImage( out vec4 fragColor, in vec2 fragCoord )
{       
    vec4 totalColor = vec4(0);
    vec2 uv = fragCoord / iResolution.xy;
    float aspect = iResolution.x/iResolution.y;
    vec2 txtUV = uv;


    vec2 mousePos = iMouse.xy / iResolution.xy;
    
    vec3 cam = vec3(4., 4., 4.);
    float near = 1.;
    float fov = 10.0;
 
    float w = 2.* near / sqrt(3.);
    float h = 1./aspect * w;

    vec3 vrb = vec3(-w / 2., -h / 2., near);
    vec3 vlt = vec3(w / 2., h / 2., near);
    

    float theta = mix(-2.14, -1.0, mousePos.x);//.x);
    float phi = mix(1.01, 0.5, mousePos.y);
    cam = vec3(cos(theta) * sin(phi),
           cos(phi),
            sin(theta) * sin(phi)) * CAMERA_INITAL_DIST;
      
    vec3 camLookAt = vec3(0,0,0);
    #if FREE_CAMERA_MOVE
    cam = getCameraPositionFromBufferA( iChannel3);
    mat3 camRot = getCameraRotationFromBufferA( iChannel3, iResolution.xy);
    #endif
    uv = fragCoord / iResolution.xy;
    vec3 lightPos = vec3(3300,2000.,3000);
    vec3 totalPos = vec3(0);
    for ( int aai = 0; aai < AA; aai++ )
    for ( int aaj = 0; aaj < AA; aaj++ )
    {

        float ox = 1./iResolution.x/float(AA)*float(aai);
        float oy= 1./iResolution.y/float(AA)*float(aaj);
        vec3 rayDir = vec3(mix(vlt.x, vrb.x, uv.x+ox), mix(vlt.y, vrb.y, uv.y+oy),  9.);


        mat3x3 rot = LookAt(cam,camLookAt, vec3(0., 1., 0.));
        
        #if FREE_CAMERA_MOVE
        rayDir = normalize(camRot * rayDir);            
        #else
        rayDir = normalize(rot * rayDir);
        #endif

        vec3 hit;
        vec3 n;

        vec3 pos;
        bool hitBox = false;
        vec2 t = boxIntersection(cam-vec3(0.,maxHeight/2.,0.), rayDir, vec3(getScale()*0.5*aspect,maxHeight/2.,getScale()*0.5), n);
        if ( t.y < t.x )
        {
            fragColor = vec4(0);
           // return;
        }



        vec3 boxPos = cam + rayDir * t.x;
        float fogDepth = t.x;
        pos = boxPos;
        //fragColor.xyz = boxPos;

        vec4 fieldValue;
        float transpareness = 1.;
        
        for ( int lt = 0; lt<TRANSPARENT_ITERS; lt++ )
        {
            vec3 pos2;
            vec3 n2;
            
            vec3 marchedColor;
            
            if (March(pos, cam+rayDir*t.y, pos, n, pos2, n2,fieldValue)) 
            {
                
                vec3 fragN = n;
                vec3 fragPos = pos;
                totalPos += pos;
                vec3 lightDir = normalize(pos - lightPos);//normalize(cross(cam, vec3(0,1,0)));
                vec3 hv = normalize(-lightDir - rayDir );
                float ndh = max(0.,dot( n, hv));
                vec2 shiness = getShiness(fieldValue);                
                float specular = pow(ndh,shiness.x)*1.35;
                vec3 subSurface = vec3(0);
                //multile sample sss is very slow
                //int sssamples = 10;
                //float w = 2.;

                
                t = boxIntersection(lightPos-vec3(0,maxHeight/2.,0), lightDir, vec3(getScale()*0.5*aspect,maxHeight/2.,getScale()*0.5), n);
                if (t.x > 0. )
                {
                    //fragColor = vec4(1,0,0,1);
                    
                    boxPos = lightPos + lightDir * t.x;
                    pos = boxPos;    
                    vec3 offset = vec3(0);//w*tn*float(sssx)+w*bn*float(sssy);
                    vec3 hitN;
                    vec3 scattered = MarchLight(materialDensity,pos+offset,fragPos+lightDir*.5,fragN, hitN );
                    subSurface +=exp(-scattered)*1.;
                    //(dot(-lightDir,hitN))*2

                }
     
                
                float nol = max(0.,(dot(lightDir, fragN)));
                //subSurface = subSurface/float((sssamples+1)*(sssamples+1));
                //
                marchedColor.xyz =  0.85*subSurface;
                vec2 grid1 = abs(fract(fragPos.xz*.5)-0.5)*2.;
                float grid = max(grid1.x, grid1.y);
                grid = smoothstep(.3,0.5,grid);

                marchedColor.xyz = mix(marchedColor.xyz,marchedColor.xyz*0.75,(1.-grid)*step(0.9,fragN.y));
                marchedColor.xyz += vec3(max(0.,dot(-lightDir, fragN)))*
                dot(subSurface,vec3(.22,.66,.11))*specular*shiness.y ;

            }
            else
            {
                 marchedColor.xyz = mix(vec3(0.000,0.000,0.000),vec3(0.114,0.114,0.106), 1.+dot(rayDir, normalize(lightPos))/2.);
                 
            }    
            pos = pos2;
            
            
            totalColor.xyz += mix(totalColor.xyz,marchedColor,transpareness);
            
            transpareness *= exp(-(t.y-t.x)*0.0016);
        }
    }
     
    fragColor = totalColor/float(AA*AA*TRANSPARENT_ITERS*TRANSPARENT_ITERS); 
    
    fragColor.a = 1.;//distance(cam,totalPos/4.);
   
    

       //fragColor.xyz = ACESFilm(fragColor.xyz);
    
   // fragColor = sin(texture(iChannel0, uv));
}
// Image (image) — Template - 3D by iq
// https://www.shadertoy.com/view/ldfSWs

// The MIT License
// Copyright © 2014 Inigo Quilez
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions: The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software. THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

// A basic example for an SDF renderer. It does not do soft
// blending, domain repetition, symmetries, mixing materials,
// PBR or global illumination.
//========================================================================

struct Box
{
    mat4x4 worldToObject;
    vec4   size;
    vec3   color;
};

struct Scene
{
    Box box[3];
};

//========================================================================
// SDF evaluation, in World space (returns closest distance and object)
//========================================================================
vec2 compute_SDF( in vec3 pos, in Scene scene )
{
    vec2 res = vec2( 1e38, -1.0 );
    for( int i=0; i<scene.box.length(); i++ )
    {
        Box   b = scene.box[i];
        vec3  q = (b.worldToObject*vec4(pos,1.0) ).xyz;
        float d = sdBox( q, b.size.xyz ) - b.size.w;
        if( d<res.x )
        {
            res = vec2( d, float(i) );
        }
    }
    return res;
}

//========================================================================
// Compute soft shadows, in World space - see https://iquilezles.org/articles/rmshadows
//========================================================================
float compute_soft_shadow( in vec3 ro, in vec3 rd, in float mint, in float tmax, in Scene scene )
{
    float res = 1.0;
    float t = mint;
    for( int i=0; i<32; i++ )
    {
		float h = compute_SDF( ro + rd*t, scene ).x;
        float s = clamp(8.0*h/t,0.0,1.0);
        res = min( res, s );
        t += clamp( h, 0.01, 0.1 );
        if( res<0.004 || t>tmax ) break;
    }
    res = clamp( res, 0.0, 1.0 );
    return res*res*(3.0-2.0*res);
}

//========================================================================
// Compute the scene's surface normal, in World space - see https://iquilezles.org/articles/normalsSDF/
//========================================================================
vec3 compute_normal( in vec3 pos, in Scene scene )
{
    const float eps = 0.002; // precision of the normal computation
    const vec3 v1 = vec3( 1.0,-1.0,-1.0);
    const vec3 v2 = vec3(-1.0,-1.0, 1.0);
    const vec3 v3 = vec3(-1.0, 1.0,-1.0);
    const vec3 v4 = vec3( 1.0, 1.0, 1.0);
	return normalize( v1*compute_SDF( pos + v1*eps, scene ).x + 
					  v2*compute_SDF( pos + v2*eps, scene ).x + 
					  v3*compute_SDF( pos + v3*eps, scene ).x + 
					  v4*compute_SDF( pos + v4*eps, scene ).x );
}

//========================================================================
// SDF raymarching, in World space
//========================================================================
vec2 compute_intersection( in vec3 ro, in vec3 rd, in Scene scene )
{
	const float maxd = 10.0; // far clipping distance
    float t = 0.0;           // near clipping distance
    
    // basic raymarching loop, can be improved in many ways
    vec3 res = vec3(1e38,-1.0,-1.0); // closest, object, ray param
    for( int i=0; i<256; i++ )
    {
	    vec2 d_o = compute_SDF( ro+rd*t, scene );
        if( d_o.x<res.x ) res = vec3(d_o,t);
        if( d_o.x<0.00001 || t>maxd ) break;
        t += d_o.x;
    }
    return t>maxd ? vec2(-1.0) : res.zy;
}

//------------------------------------------------------------------------
// SDF scene description, in World space (two boxes)
//------------------------------------------------------------------------
Scene doScene( in float time )
{
    Scene scene;

    { // a blue box
	  mat4x4 objectToWorld = translate( 0.0, 0.5, 0.0 ) *    // read concatenation like in school, right to left: 
                             rotate( vec3(0.57735), -time ); // first we rotate the blue box, then we move it up
      scene.box[0].worldToObject = inverse( objectToWorld );
      scene.box[0].size = vec4(0.8,0.05,0.4, 0.1);
      scene.box[0].color = vec3(0.1,0.2,0.4 );
    }
    
    { // a yellow "box"
	  mat4x4 objectToWorld = inverse(scene.box[0].worldToObject) *
                             translate( 0.0, 0.5, 0.0 )*
                             rotate( vec3(0.0,1.0,0.0), -3.0*time );
	  scene.box[1].worldToObject = inverse( objectToWorld );
      scene.box[1].size = vec4(0.0,0.0,0.0, 0.35);
      scene.box[1].color = vec3(0.6,0.4,0.05);
    }    
    
    { // a pink box
	  mat4x4 objectToWorld = translate( 0.0, -0.5, 0.0 ); 
	  scene.box[2].worldToObject = inverse( objectToWorld );
      scene.box[2].size = vec4(3.0,0.1,3.0, 0.0);
      scene.box[2].color = vec3(0.5,0.1,0.08);
    }
    
    return scene;
}    

//------------------------------------------------------------------------
// Materials, in World space
//------------------------------------------------------------------------
vec3 doMaterial( in vec3 pos, in vec3 nor, in int obj, in Scene scene )
{
    Box b = scene.box[obj];
    
    // base color
    vec3 col = b.color;
    
    // texture, in Object space
    vec3 q = (b.worldToObject * vec4(pos,1.0) ).xyz;
    vec3 f = cos(10.0*q);
    col *= 0.5 + 0.5*smoothstep( -0.001, 0.001, f.x*f.y*f.z );
    
    return col;
}

//------------------------------------------------------------------------
// Lighting, in World space
//------------------------------------------------------------------------
vec3 doLighting( in vec3 pos, in vec3 nor, in vec3 rd, in float dis, in vec3 albedo, in Scene scene )
{
    vec3 lin = vec3(0.0);

    // key light
    {
      const vec3 dir = normalize(vec3(1.0,0.7,0.2));
      const vec3 col = vec3(1.0,1.0,1.0);

      float dif = max(dot(nor,dir),0.0);
      if( dif>0.0001 ) dif *= compute_soft_shadow( pos, dir, 0.001, 2.0, scene );
      lin += albedo*4.0*col*dif;
      
      vec3  hal = normalize( dir-rd );
      float spe = pow( clamp(dot(nor,hal),0.0,1.0), 16.0 );
      lin += spe*0.5*col*dif;
    }
    
    // ambient light
    {
      float dif = 0.6 + 0.4*nor.y;
      lin += albedo*vec3(0.15,0.15,0.15)*dif;
    }
    
    return lin;
}

//------------------------------------------------------------------------
// Animate Viewer-To-World transform (ie, animate the camera)
//------------------------------------------------------------------------
mat4x4 doViewer( in float time )
{
    float ang = 0.05*iTime;
	vec3  pos = vec3(3.0*sin(ang),1.0,3.0*cos(ang));
    vec3  tar = vec3(0.0,0.0,0.0);
    
    return computeLookAt( pos, tar, 0.0 );
}

//------------------------------------------------------------------------
// Background color, in World space
//------------------------------------------------------------------------
vec3 doBackground( in vec3 rd )
{
    return vec3( 0.05 + 0.3*(1.0+rd.y)*(1.0+rd.y) );
}

//------------------------------------------------------------------------
// Main entry point - for each pixel, compute color!
//------------------------------------------------------------------------

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    // screen coordinates (-1,1) in Y
    vec2 p = (2.0*fragCoord-iResolution.xy)/iResolution.y;
    
    // compute viewer movement
    mat4x4 viewerToWorld = doViewer( iTime );

    // compute scene
    Scene scene = doScene( iTime );
    
	// compute ray for camera, in View space
    float cl = 1.0/tan(radians(53.13)/2.0); // 53.13 degre vertical field of view
    vec3  ro = vec3(0.0,0.0,0.0); // ro = ray origin
    vec3  rd = vec3(p,-cl);       // rd = ray direction

    // convert ray from View to World space    
    ro =            (viewerToWorld*vec4(ro,1.0)).xyz;
	rd = normalize( (viewerToWorld*vec4(rd,0.0)).xyz );

    // compute background, in World space
	vec3 col = doBackground(rd);

	// compute intersection by raymarching the SDF, in World space
    vec2 tm = compute_intersection( ro, rd, scene );
    if( tm.x>-0.5 )
    {
        // geometry, in World space
        vec3 pos = ro + tm.x*rd;
        vec3 nor = compute_normal(pos, scene);

        // materials, in World space
        vec3 alb = doMaterial( pos, nor, int(tm.y), scene );

        // lighting, in World space
        col = doLighting( pos, nor, rd, tm.x, alb, scene );
	}

    // do some gain control (soften the highlights)
    col *= 1.5/(1.0+col);
    
    // convert linear to perceptual/gamma colors
	col = pow( clamp(col,0.0,1.0), vec3(1.0/2.2) );
	   
    // output color to screen
    fragColor = vec4( col, 1.0 );
}
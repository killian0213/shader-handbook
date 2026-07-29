// Common (common) — Wild Sausages by iapafoto
// https://www.shadertoy.com/view/tlsSD2

//-----------------------------------------------------
// Created by sebastien durand - 2019
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
//-----------------------------------------------------
//-----------------------------------------------------
// [dr2]            More Balls               - https://www.shadertoy.com/view/MsfyRn
// [iq]             Capsule - soft shadow    - https://www.shadertoy.com/view/MlGczG
// [iq]             Balls and shadows        - https://www.shadertoy.com/view/lsSSWV
// [Shane]          Desert Canyon            - https://www.shadertoy.com/view/Xs33Df
//-----------------------------------------------------


#define NB_LINES    17  // Number of lines of sausages
#define NB_LELT     56  // Number of sausages parts 
#define NB_ELT  (NB_LELT*NB_LINES) 
    
#define CHAIN 7


// -- PHYSICS -------------------------------------------------

#define DT            .008  // Step for mecanic calculus (.004 = real time => time beween two frame at 240fps)
#define DENSITY       1000. // kg/m3 (density of water here)
#define GRAV          9.81  // m/s-1 (on earth)


// +----------------------------------------------------------+
// |       !!!!  DO NOT CHANGE AFTER THIS LINE !!!!           |  
// +----------------------------------------------------------+

// -- Step of the algorithm -----------------------------------

#define STAGE_INIT            0  // First initialisation
#define STAGE_SIMULATE        1  // Make Sausage dance
// At end go back to

#define NO_LINK               0xFFFF

// -- Position of elements in BufferPicture ------------------
#define LINE_CONF	    NB_LINES

#define POSITION        0
#define ORIENTATION     1
#define VELOCITY        2
#define ROT_VELOCITY    3
#define LINK            4

// -- Constants ----------------------------------------------
#define PI              3.141592653589
#define CUBE_SIZE       vec3(6,6,6)

// -- Functions ----------------------------------------------
#define CON_TO(c)       int(c)%1000
#define CON_AT(c)       (int(c)%10000)/1000
#define CON_TYPE(c)     int(c)/10000


// Force of muscles and ligaments
const float dSpringK = 6000.;

vec4 gRotTetra[4];


// +---------------------------+
// |        Save / Load        |
// +---------------------------+

vec4 LoadConf (sampler2D txBuf, int idVar) {
    return texelFetch(txBuf, ivec2(idVar, LINE_CONF), 0);
}

vec4 Load(sampler2D txBuf, int kind, int eltId) {
    int line = eltId/NB_LELT;
    eltId = eltId%NB_LELT;
    return texelFetch(txBuf, ivec2(NB_LELT*kind + eltId, line), 0);
}

void Save(int kind, int eltId, vec4 val, inout vec4 fCol, vec2 fCoord) {
    int line = eltId/NB_LELT;
    eltId = eltId%NB_LELT;
	vec2 iFrag = floor(fCoord);
    if ((NB_LELT*kind + eltId) == int(iFrag.x) && line == int(iFrag.y)) fCol = val;
}


// +---------------------------+
// |        Quaternions        |
// +---------------------------+

vec4 Quaternion(vec3 n, float a) {
    return normalize(vec4(n*sin(a*.5), -cos(a*.5)));
}

// http://www.euclideanspace.com/maths/algebra/realNormedAlgebra/quaternions/arithmetic/index.htm
vec4 QtMul(vec4 q1, vec4 q2) {
    return vec4(cross(q1.xyz,q2.xyz) + q1.w*q2.xyz + q2.w*q1.xyz, q1.w*q2.w - dot(q1.xyz,q2.xyz));
}


//-----------------------------------------------------------
// [dr2] More Balls - https://www.shadertoy.com/view/MsfyRn

mat3 QtToRMat(vec4 q) {
    mat3 m;
    float a1, a2, s;
    q = normalize (q);
    s = q.w * q.w - 0.5;
    m[0][0] = q.x * q.x + s;  m[1][1] = q.y * q.y + s;  m[2][2] = q.z * q.z + s;
    a1 = q.x * q.y;  a2 = q.z * q.w;  m[0][1] = a1 + a2;  m[1][0] = a1 - a2;
    a1 = q.x * q.z;  a2 = q.y * q.w;  m[2][0] = a1 + a2;  m[0][2] = a1 - a2;
    a1 = q.y * q.z;  a2 = q.x * q.w;  m[1][2] = a1 + a2;  m[2][1] = a1 - a2;
    return 2. * m;
}

//-----------------------------------------------------------
// [dr2] More Balls - https://www.shadertoy.com/view/MsfyRn
vec4 RMatToQt(mat3 m) {
    vec4 q;
    const float tol = 1e-6;
    q.w = .5 * sqrt(max(1. + m[0][0] + m[1][1] + m[2][2], 0.));
    if (abs(q.w) > tol) 
        q.xyz = vec3 (m[1][2] - m[2][1], m[2][0] - m[0][2], m[0][1] - m[1][0]) / (4.*q.w);
    else {
        q.x = sqrt (max(.5 * (1. + m[0][0]), 0.));
        if (abs (q.x) > tol) 
            q.yz = vec2 (m[0][1], m[0][2]) / q.x;
        else {
            q.y = sqrt (max (.5 * (1. + m[1][1]), 0.));
            if (abs (q.y) > tol) q.z = m[1][2] / q.y;
            else q.z = 1.;
        }
    }
    return normalize (q);
}

//-----------------------------------------------------------
// [dr2] More Balls - https://www.shadertoy.com/view/MsfyRn
mat3 LpStepMat (vec3 a) {
    mat3 m1, m2;
    vec3 t, c, s;
    float b1, b2;
    t = .25 * a * a;
    c = (1. - t) / (1. + t);
    s = a / (1. + t);
    m1[0][0] = c.y * c.z;  m2[0][0] = c.y * c.z;
    b1 = s.x * s.y * c.z;  b2 = c.x * s.z;
    m1[0][1] = b1 + b2;    m2[1][0] = b1 - b2;
    b1 = c.x * s.y * c.z;  b2 = s.x * s.z;
    m1[0][2] = - b1 + b2;  m2[2][0] = b1 + b2;
    b1 = c.y * s.z;
    m1[1][0] = - b1;       m2[0][1] = b1;  
    b1 = s.x * s.y * s.z;  b2 = c.x * c.z;
    m1[1][1] = - b1 + b2;  m2[1][1] = b1 + b2; 
    b1 = c.x * s.y * s.z;  b2 = s.x * c.z;
    m1[1][2] = b1 + b2;    m2[2][1] = b1 - b2;
    m1[2][0] = s.y;        m2[0][2] = - s.y;
    b1 = s.x * c.y;
    m1[2][1] = - b1;       m2[1][2] = b1;
    b1 = c.x * c.y;
    m1[2][2] = b1;         m2[2][2] = b1;
    return m1 * m2;
}


// +------------------------------------------------------+
// |                      UTILS                           |
// +------------------------------------------------------+

bool getConnexionBases(sampler2D txBuf, vec4 connexions, int con_pos, vec4 qm1, out vec4 pc2, out mat3 rot1, out mat3 rot2) {
    if (int(connexions[con_pos]) == NO_LINK)
        return false;
    
    int other_con_pos = CON_AT(connexions[con_pos]),
        parentId =      CON_TO(connexions[con_pos]);

    pc2 =      Load(txBuf, POSITION,    parentId);
    vec4 qm2 = Load(txBuf, ORIENTATION, parentId);

    // Orientation of connexion point
    if (con_pos == 0) {
        rot1 = QtToRMat(qm1);
        rot2 = QtToRMat(QtMul(qm2,gRotTetra[other_con_pos]));
    } else {
        rot1 = QtToRMat(QtMul(qm1,gRotTetra[con_pos]));
        rot2 = QtToRMat(qm2);
    }
    return true;
}


// +------------------------------------------------------+
// |                    STAGE INIT                        |
// +------------------------------------------------------+
// Init links of elements 
vec4 InitLinks(int eltId) {
	if (eltId%CHAIN == 0)
    	return vec4(NO_LINK, 20000+eltId+1, NO_LINK, NO_LINK);
    if (eltId%CHAIN == CHAIN-1)
        return vec4(21000+eltId-1, NO_LINK, NO_LINK, NO_LINK);
    return vec4(21000+eltId-1 , 20000+eltId+1, NO_LINK, NO_LINK);
}

// +------------------------------------------------------+
// |                 STAGE_MAKE_BODY                      |
// +------------------------------------------------------+
// Create Initial Pos from ADN

void InitSausagesPositions(sampler2D txBuf, int eltId, out vec3 rm, out vec4 qm, out float rad) {
    int creatureId = eltId/NB_LELT;
    eltId = eltId%NB_LELT;
    float idChain = float(eltId/CHAIN);
    float ca = cos(idChain), sa = sin(idChain);
    rm = vec3(float(NB_LINES)*.25-float(creatureId)*.5, float(eltId%CHAIN - CHAIN/2)*.5, 2.-.5*float(eltId/CHAIN));
    rm.xy *= mat2(ca,sa,-sa,ca);
    qm = vec4(0,0,0,-1);
    rad = .25;
}


// +---------------------------------------------------+
// |                 Animate creatures                 |
// +---------------------------------------------------+

// Spring force
void applyForce(vec4 pc1, mat3 rot1, vec4 pc2, mat3 rot2, vec3 n1, vec3 n2,float springLen, inout vec3 am, inout vec3 wam, float kForce) {
    vec3 p1 = pc1.xyz + pc1.w*rot1*n1,
     	 p2 = pc2.xyz + pc2.w*rot2*n2,
         v = p1 - p2;
    float dLen = length(v);
	vec3 springForce = kForce* (dLen-springLen) * v/dLen;
    am -= springForce;
    wam -= cross(p1 - pc1.xyz, springForce);
}

//-----------------------------------------------------------
// Adapted from
// [dr2] More Balls - https://www.shadertoy.com/view/MsfyRn
//-----------------------------------------------------------
void Simulate(float time, sampler2D txBuf, int eltId, out vec3 rm, out vec3 vm, out vec4 qm, out vec3 wm, out float rad) {

    // Friction between Elements of the elements of sausages
    const float fricNB = 5., fricSB = 5., fricSWB = 10., fricTB = 40.;
    
    // Friction to the ground
    const float fricN = 240., fricS = 240., fricSW = 160., fricT =248.;
    
    vec3  vmN, wmN, dr, dv, am, wam;
    float rSep, radSum, fc, ft, ms, h, fOvlap = 3.*15000.;
        
    vec4 pc1 = Load(txBuf, POSITION, eltId);
    qm = Load(txBuf, ORIENTATION,    eltId);
    vm = Load(txBuf, VELOCITY,       eltId).xyz;
    wm = Load(txBuf, ROT_VELOCITY,   eltId).xyz;

    rm = pc1.xyz;
    rad = pc1.w;

    ms = rad*rad*rad*DENSITY; // Mass

    am = wam = vec3(0); // Sum or forces
 
    // Slow it a bit
    vm *= .99;
    wm *= .97;

    // Check intersection between Elements of the creature
    for (int n =0; n<NB_LELT*NB_LINES; n+=CHAIN) {
        vec4 p = Load(txBuf, POSITION, n+(CHAIN/2));

        if (length(p.xyz-pc1.xyz)-pc1.w*float(CHAIN)<pc1.w) {
            for (int i = 0; i < CHAIN; i++) {
                vec4 pc2 = Load(txBuf, POSITION, n+i);

                dr = pc1.xyz - pc2.xyz;

                rSep = length(dr);
                radSum = pc1.w + pc2.w;

                if (n+i != eltId && rSep < radSum) {

                    // Impulsion de contact
                    fc = fOvlap * (radSum / rSep - 1.);

                    vmN = Load(txBuf, VELOCITY, n+i).xyz;
                    wmN = Load(txBuf, ROT_VELOCITY, n+i).xyz;

                    dv = vm - vmN;
                    h = dot(dr, dv) / (rSep)*(rSep);

                    // friction
                    fc = max(fc - fricNB * h, 0.);
                    am += fc * dr;
                    dv -= h * dr + cross ((2.*pc1.w * wm + 2.*pc2.w * wmN) / (2.*pc1.w + 2.*pc2.w), dr);
                    ft = min (fricTB, fricSB * abs (fc) * rSep / max (0.001, length (dv)));

                    am -= ft * dv;
                    wam += (ft / rSep) * cross (dr, dv);
                }
            }
        }
    }
    
    
    vec4 connexions = Load(txBuf, LINK, eltId);
    mat3 rot1, rot2, rot = QtToRMat(qm);
    
    int creatureId = eltId/NB_LELT;
    // For each possible connexions to other Elts
    for (int con_pos=0; con_pos<2; con_pos++) {
        vec4 pc2; 
        
        if (getConnexionBases(txBuf, connexions, con_pos, qm, pc2, rot1, rot2)) {
            
	        int move_con = CON_TYPE(connexions[con_pos]);
            float anim = .14*cos(time*5. + float(creatureId) + float(move_con/10)*6.28),
			 	  a = PI*2.*float(move_con)/8.,
             	  ca = cos(a), sa = sin(a),
            	  kForce = dSpringK*mix(5., 100.*(pc1.w*pc1.w*pc1.w + pc2.w*pc2.w*pc2.w), .6); // biggest link => strongest
                        
            // Ligaments
            if (con_pos == 0)
                applyForce(pc1, rot1, pc2, rot2, vec3(0,0,1), vec3(0,0,-1),  0., am, wam, 2.*kForce);
            else 
                applyForce(pc1, rot1, pc2, rot2, vec3(0,0,-1), vec3(0,0,1),  0., am, wam, 2.*kForce);
            
            applyForce(pc1, rot1, pc2, rot2, vec3(ca,sa,0), vec3(ca,sa,0), pc1.w+pc2.w, am, wam, 2.*kForce);
            applyForce(pc1, rot1, pc2, rot2,-vec3(ca,sa,0),-vec3(ca,sa,0), pc1.w+pc2.w, am, wam, 2.*kForce);
			
            // Muscles
            applyForce(pc1, rot1, pc2, rot2, vec3(sa,ca,0),vec3(sa,ca,0), (pc1.w+pc2.w)*(1.+anim), am, wam, kForce);
            applyForce(pc1, rot1, pc2, rot2,-vec3(sa,ca,0),-vec3(sa,ca,0), (pc1.w+pc2.w)*(1.-anim), am, wam, kForce);
        }
    }
    

    // Intersection with the ground 
    float radAv = rad + .5;
    vec4 drw = vec4 ((CUBE_SIZE - abs (rm)) * (1. - 2. * step (0., rm)), 0.);

    for (int nf = 0; nf < 3; nf ++) {

        dr = (nf == 1) ? drw.wyw : ((nf == 0) ? drw.xww : drw.wwz);
        rSep = length (dr);

        if (rSep < radAv) {
            // Out of the ground
            rm -= .5*normalize(dr)*(rSep-radAv);

            fc = fOvlap * (radAv / rSep - 1.);
            dv = vm;
            h = dot (dr, dv) / (rSep * rSep);
            fc = max (fc - fricN * h, 0.);

            am += fc * dr;
            dv -= h * dr + cross (wm, dr);

            ft = min (fricT, fricSW * abs (fc) * rSep / max (0.001, length (dv)));
            am -= ft * dv;
            wam += (ft / rSep) * cross (dr, dv);
        }

    }
    
    // Moving gravity
    vec3 vGrav;
    float anim = mod(time,35.);

    if (anim<10.){
  	 	vGrav = vec3(0,0,1); // Classic
    } else if (anim<20.){
     	vGrav = 4.*normalize(pc1.xyz)-pc1.xyz;  // Sphere r=4
    } else { 
    	vGrav = pc1.xyz;	// From center => cube formation
    }
    if (length(vGrav) != 0.)
        vGrav /= length(vGrav);
    
    am += vGrav * ms*GRAV;
 
   // Integrate all
    vm += DT * am/ms;
    rm += DT * vm;
    wm += DT * wam / (ms*rad);
  
    qm = normalize(QtMul(RMatToQt(LpStepMat(.5 * DT * wm)), qm));
}


// +---------------------------+
// |         Main Loop         |
// +---------------------------+

void mainLoop(float iTime, vec4 iMouse, vec2 iResolution, int iFrame, sampler2D txBuf, out vec4 fragColor, in vec2 fragCoord) {

    gRotTetra[0] = vec4(0,0,0,1);
    gRotTetra[1] = vec4(0,0,0,-1);

    vec4 configuration = LoadConf(txBuf, 3);
    
    int stage, nextStage;
    
    if (iFrame == 0) {
        stage = STAGE_INIT;       // Init first ADN

    } else {
        stage = int(configuration.z);
        nextStage = stage;
    }

    vec2 iFrag = floor(fragCoord);
    int pxId = int(iFrag.x);
        
    // By default : do not change value 
    fragColor = texelFetch(txBuf, ivec2(iFrag), 0);
        
    // Win some cycles 
    if (iFrag.y >= float(NB_LINES+1)) {      
		return;
    }

    // Configuration
    if (int(iFrag.y) == LINE_CONF) {  

        if (pxId == 3) {
            // Change states (sequence of actions)
            if (stage == STAGE_INIT) {
                nextStage = STAGE_SIMULATE;
            } 

            configuration = vec4(0, 0, nextStage, 0);
        }
		
		// Save config
        fragColor = configuration;

    } else {

		int eltId = pxId%NB_LELT + int(iFrag.y)*NB_LELT;
		int varColId = pxId/NB_LELT;
        
        vec4 p, qm;
    	vec3 rm, vm, wm;
        float rad;
        
	// -- Init ---------------------------------------------------------

        if (stage == STAGE_INIT) {
  			if (varColId == LINK) {
                fragColor = InitLinks(eltId);
                
            } else if (varColId == VELOCITY || varColId == ROT_VELOCITY) {
                fragColor = vec4(0); // Static at starts
         
            } else if (varColId == POSITION || varColId == ORIENTATION) {
                       
				// ------------------------------------------------------------------
                // Init positions and orientations
                InitSausagesPositions(txBuf, eltId, rm, qm, rad);
                // Save Positon and Orientation
                fragColor = varColId == POSITION ? vec4(rm, rad) : qm;
            }
         
        }  else if (stage == STAGE_SIMULATE) {
 			
            if (varColId < LINK) {    
	            // Do physical simulation
                Simulate(iTime, txBuf, eltId, rm, vm, qm, wm, rad);
				
                // Save new positions, orientation and speeds
                fragColor = varColId == POSITION ? vec4(rm, rad) :
						    varColId == ORIENTATION ? qm :
						    varColId == VELOCITY ? vec4(vm,0) : vec4(wm,0);
            }
        }
    }
    

}





// Image (image) — Link's Awakening by Gallo
// https://www.shadertoy.com/view/WlBXW3

// The MIT License
// Copyright © 2019 David Gallardo @galloscript
// Just modeling over Original IQ Raymarching example https://www.shadertoy.com/view/Xds3zN

//Toggle parts vislibity
#define SHOW_CAP  	1
#define SHOW_SWORD 	1
#define SHOW_SHIELD 1
#define SHOW_HEAD 	1 //dev
#define SHOW_BODY 	1  //dev

#if HW_PERFORMANCE==0
#define AA 0
#else
#define AA 1  // make this 2 or 3 for antialiasing
#endif

//------------------------------------------------------------------

#define ZERO (min(iFrame,0))
#define M_PI 3.142

//------------------------------------------------------------------

vec2 opU( vec2 d1, vec2 d2 )
{
	return (d1.x<d2.x) ? d1 : d2;
}



vec2 map( in vec3 pos )
{
    vec2 res = vec2( 1e10, 0.0 );

    //Note: Think in vec3 variables that ends with xxxxPos as bones.
    
#if defined(SHOW_HEAD) && (SHOW_HEAD == 1)
    //----- HEAD -----
    vec3 lHeadStart = rotation(Y_AXIS, 0.2) *  rotation(X_AXIS, -0.12) * (pos - vec3(0.0, 0.53, -0.00));
    float lHeadBox = sdBox( lHeadStart - vec3(0.0, 0.06, 0.2), vec3(0.32,0.24,0.34) );
    //res = opU( res, vec2( lHeadBox, 4.0) );
    if(res.x > lHeadBox)
    {
        
        
                //Main Head
        float   lHead = sdEllipsoid( rotation(X_AXIS, 0.4) * (lHeadStart), vec3(0.17, 0.14, 0.19));
                lHead = opSmoothUnion(lHead, sdEllipsoid( lHeadStart - vec3(0.0, 0.11, 0.00), vec3(0.15, 0.11, 0.14)), 0.1);
                //Nouse
                //lHead = opSmoothUnion(lHead, sdCapsule(lHeadStart - vec3(0.0, 0.04, -0.16), vec3(0.0, 0.0, 0.0),  vec3(0.0, -0.01, -0.04), 0.025), 0.005);
        		lHead = opSmoothUnion(lHead, sdEllipsoid( lHeadStart - vec3(0.0, 0.02, -0.15), vec3(0.012, 0.012, 0.05)), 0.04);
                //Ears
        vec3	lEarsPos = rotation(Z_AXIS, -0.4) * rotation(Y_AXIS, 0.4) * (opMirrorX(lHeadStart) - vec3(0.2, 0.018, 0.02));
        float 	lEars = sdEllipsoid( lEarsPos, vec3(0.13, 0.044, 0.03));
        		//inner
                lEars = fOpIntersectionRound(lEars, -sdEllipsoid( rotation(Y_AXIS, -0.24) * lEarsPos - vec3(0.0, 0.0, -0.013), vec3(0.07, 0.018, 0.018)), 0.015);
        		//punta
        		float lPuntaCutter = sdEllipsoid( lEarsPos - vec3(0.13, -0.055, 0.0), vec3(0.05, 0.026, 0.04));
        		lEars = fOpIntersectionRound(lEars, -lPuntaCutter, 0.06);

        lHead = opSmoothUnion(lHead, lEars, 0.02);
        res = opU( res, vec2( lHead, 2.0) );
        //res = opU( res, vec2( lPuntaCutter, 4.0) );

        //Eyes
        float lEyes = sdEllipsoid(rotation(Z_AXIS, 0.05) * (opMirrorX(lHeadStart) - vec3(0.055, 0.08, -0.165)),  vec3(0.0195, 0.05, 0.02));
        lEyes = max(lEyes, lHead);
        res = opU( res, vec2( lEyes, 4.0) );
        
        mat3 lRotZEB = rotation(Z_AXIS, -0.2);
        
        float lEyeBrows = sdEllipsoid(lRotZEB * (opMirrorX(lHeadStart) - vec3(0.06, 0.115, -0.14)),  vec3(0.036, 0.012, 0.03));
              lEyeBrows = fOpIntersectionRound(lEyeBrows, -sdEllipsoid(lRotZEB * (opMirrorX(lHeadStart) - vec3(0.058, 0.103, -0.14)), vec3(0.036, 0.011, 0.03)), 0.003);
        	  lEyeBrows = max(lEyeBrows, lHead);
        res = opU( res, vec2( lEyeBrows, 5.0) );
		
        float lMouthBox = sdBox( lHeadStart-vec3(0.0, -0.05, -0.15), vec3(0.12,0.05,0.05) );
        if(res.x > lMouthBox)
        {
        	//Mouth
            float 	lMouth = sdEllipsoid(lHeadStart - vec3(0.0, -0.056, -0.17),  vec3(0.045, 0.03, 0.04));
                    lMouth = fOpIntersectionRound(lMouth, -sdEllipsoid(lHeadStart - vec3(0.0, -0.064, -0.17),  vec3(0.05, 0.03, 0.05)), 0.008);
                    lMouth = max(lMouth, lHead);
            res = opU( res, vec2( lMouth, 4.0) );
        }
        
		
        //Hair
        {
            float 	lHair = 1e10;
            		//Cogorote
            		lHair = min(lHair, sdEllipsoid(lHeadStart - vec3(0.0, 0.08, 0.05), vec3(0.19, 0.18, 0.17)));
            		
            		//Right bulto
                    lHair = min(lHair, sdEllipsoid(rotation(Y_AXIS, -0.4) * rotation(Z_AXIS, 0.3) * (lHeadStart - vec3(0.06, 0.2, -0.05)),  vec3(0.16, 0.07, 0.13)));
            
            		//Right back bulto
            		lHair = min(lHair,  sdEllipsoid(rotation(Y_AXIS, -0.4) * rotation(Z_AXIS, 0.5) * (lHeadStart - vec3(0.12, 0.15, -0.00)),  vec3(0.1, 0.07, 0.1)));
            
                    //Left bulto
                    lHair = min(lHair, sdEllipsoid(rotation(Y_AXIS, -0.4) * rotation(Z_AXIS, -1.0) *  (lHeadStart - vec3(-0.12, 0.16, -0.03)),  vec3(0.1, 0.07, 0.1)));
            
            		//Patillas Left
                    lHair = min(lHair, sdEllipsoid(rotation(Z_AXIS, (lHeadStart.y - 0.18) * -2.5) *  (lHeadStart - vec3(-0.19, 0.0, -0.03)),  vec3(0.03, 0.1, 0.03)));
            
            		//Patillas Right
                    lHair = min(lHair, sdEllipsoid(rotation(Z_AXIS, (lHeadStart.y - 0.18) * 1.1) *  (lHeadStart - vec3(0.19, 0.0, -0.03)),  vec3(0.03, 0.12, 0.03)));
            		
            		//Hair Back
                    lHair = opSmoothUnion(lHair, sdEllipsoid(  (lHeadStart - vec3(0.1, -0.005, 0.12)),  vec3(0.06, 0.14, 0.05)), 0.03);
            		lHair = opSmoothUnion(lHair, sdEllipsoid(  (lHeadStart - vec3(0.0, -0.01, 0.13)),  vec3(0.06, 0.14, 0.05)), 0.03);
            		lHair = opSmoothUnion(lHair, sdEllipsoid(  (lHeadStart - vec3(-0.1, -0.005, 0.12)),  vec3(0.06, 0.14, 0.05)), 0.03);
            
            res = opU( res, vec2( lHair, 7.0) );
            //res = opU( res, vec2( lHairCutter, 4.0) );
        }
        
        #if defined(SHOW_CAP) && (SHOW_CAP == 1)
        //CAP
        float lCapCutter = sdEllipsoid(lHeadStart - vec3(0.0, -0.31, -0.53), vec3(0.7, 0.8, 0.7));
        lCapCutter = min(lCapCutter, sdEllipsoid(lHeadStart - vec3(0.0, 0.31, -0.8), vec3(0.3, 0.3, 0.3)));
        mat3  lCapRot = rotation(X_AXIS, pow(abs(lHeadStart.z), 2.2) * -0.9);
        float lCap = sdEllipsoid( lCapRot * (lHeadStart - vec3(0.0, 0.09, -0.16)), vec3(0.23, 0.2, 0.65));
        lCap = fOpIntersectionRound(lCap, - lCapCutter, 0.02);

        res = opU( res, vec2( lCap, 3.0) );

        float lBandCutter = sdEllipsoid(  rotation(X_AXIS, 0.5) * (lHeadStart - vec3(0.0, 0.11, 0.38)), vec3(0.5, 0.8, 0.25));
        float lCapBand = (lCap - 0.01);
        lCapBand = fOpIntersectionRound(lCapBand, -lBandCutter, 0.01);
        res = opU( res, vec2( lCapBand, 6.0) );

        //res = opU( res, vec2( lCapCutter, 4.0) );
        #endif // SHOW_CAP  

        
    }
    //----- END HEAD ------

  
#endif // SHOW_HEAD
    
 
    vec3 lPosMirrorX = opMirrorX(pos);
    
#if defined(SHOW_BODY) && (SHOW_BODY == 1)
    //----- BOTTOM BODY ------
    float lBottomBox = sdBox( pos-vec3( 0.0, 0.05, -0.05), vec3(0.18,0.06,0.12) );
    //res = opU( res, vec2( lBottomBox, 5.0) );
    if(res.x > lBottomBox)
    {
        //Shoes
        //float lShoes = sdEllipsoid( lPosMirrorX - vec3(0.06, -0.0025, -0.05), vec3(0.045 , 0.04, 0.12));
        {
            vec3 lRightFootPos = rotation(Y_AXIS, 0.2) * (pos - vec3(0.09, 0.0, -0.03));
            float 	lShoes = sdCone( rotation(Z_AXIS, -0.2) * lRightFootPos, vec3(0.0), vec3(0.0, 0.06, 0.0), 0.04, 0.042);
                  	lShoes = opSmoothUnion(lShoes, sdEllipsoid( lRightFootPos - vec3(0.0, 0.008, -0.07), vec3(0.045 , 0.04, 0.048)), 0.05);
                  //lShoes = opSmoothUnion(lShoes, sdEllipsoid( pos - vec3(0.06, -0.001,  0.02), vec3(0.02 , 0.018, 0.015)), 0.08);
            res = opU( res, vec2( lShoes, 5.0) );
            
            //Legs
            float lLegs = sdCone( rotation(Z_AXIS, -0.2) * lRightFootPos - vec3(0.0, 0.04, 0.0), vec3(0.0), vec3(0.0, 0.06, 0.0), 0.038, 0.035);
            res = opU( res, vec2( lLegs, 8.0) );
        }
        {
            
            vec3 lLeftFootPos = rotation(Y_AXIS, -1.2) * (pos - vec3(-0.06, 0.0, -0.03));
            float 	lShoes = sdCone( lLeftFootPos, vec3(0.0), vec3(0.0, 0.06, 0.0), 0.04, 0.042);
            		lShoes = opSmoothUnion(lShoes, sdEllipsoid( lLeftFootPos - vec3(0.0, 0.008, -0.07), vec3(0.045 , 0.04, 0.048)), 0.05);
            //lShoes = opSmoothUnion(lShoes, sdEllipsoid( pos - vec3(-0.06, -0.001,  0.02), vec3(0.02 , 0.018, 0.015)), 0.08);
        	res = opU( res, vec2( lShoes, 5.0) );
			
            //Legs
            float lLegs = sdCone( lLeftFootPos - vec3(0.0, 0.04, 0.0), vec3(0.0), vec3(0.0, 0.06, 0.0), 0.038, 0.035);
            res = opU( res, vec2( lLegs, 8.0) );
        }
    }
    //----- END BOTTOM BODY ------
    
    //----- MIDDLE BODY ------
    float lMiddleBox = sdBox( pos-vec3( 0.0, 0.25, -0.03), vec3(0.22,0.16,0.12) );
    //res = opU( res, vec2( lMiddleBox, 5.0) );
    if(res.x > lMiddleBox)
    {
        
        //Shoulders Cutter
        float lkShouldersCutterFactor = 0.019;
        float lShouldersCutter = sdCappedTorus( (pos -  vec3(0.0, 0.155, -0.03)), vec2(0.065, 0.09), 0.42, 0.2 );
        //fOpIntersectionRound(COSA, -lShouldersCutter, 0.01 );
        //res = opU( res, vec2( lShouldersCutter, 4.0) );
        
        //Torso
        vec3 lTorsoPos =  pos - vec3(0.0, -0.06, -0.03);
        float 	lTorso = sdEllipsoid( lTorsoPos - vec3(0.0, 0.02, 0.0), vec3(0.14, 0.45, 0.11));
        		lTorso = opSmoothUnion( lTorso, sdEllipsoid( lTorsoPos - vec3(0.0, 0.13, 0.0), vec3(0.145, 0.1, 0.115)), 0.02); //falda
        		lTorso = opSmoothUnion( lTorso, sdEllipsoid( lTorsoPos - vec3(0.0, 0.265, -0.055), vec3(0.06, 0.08, 0.035)), 0.04); //barriguita
        float lTorsoCutter = sdBox(lTorsoPos - vec3( 0.0, -0.14 , 0.0), vec3(0.3,0.3,0.3)); //+ lVariance.x * 0.5
              lTorso = fOpIntersectionRound(lTorso, -lTorsoCutter, 0.01 );
        //float lTorso = sdCone( lTorsoPos, vec3(0.0), vec3(0.0, 0.22, 0.0), 0.14, 0.06);
              //Mangas
        //res = opU( res, vec2( lTorso, 3.0) );
        
        float lCinturaCutter = sdTorus( lTorsoPos -  vec3(0.0, 0.23, 0.01), vec2(0.165, 0.008) );
        float 	lTorso2 = fOpIntersectionRound(lTorso, -lCinturaCutter, 0.07 );
        		lTorso2 = fOpIntersectionRound(lTorso2, -lShouldersCutter, lkShouldersCutterFactor );
      
        res = opU( res, vec2( lTorso2, 3.0) );
        
        vec3 	lMangasPos = rotation(X_AXIS, pos.x * -2.2) * rotation(Z_AXIS,-0.6) * (opMirrorX(lTorsoPos) - vec3(0.09, 0.35, 0.0));
        float 	lMangas = sdEllipsoid( lMangasPos,vec3(0.04, 0.09, 0.03));
              	//lMangas = max(lMangas, -sdCone( rotation(Z_AXIS,-0.4) * (opMirrorX(lTorsoPos) - vec3(0.15, 0.22, 0.0)), vec3(0.0), vec3(0.0, 0.1, 0.0), 0.04, 0.04));		
        		lMangas = fOpIntersectionRound(lMangas, -lShouldersCutter, lkShouldersCutterFactor );
        
        		//WARNING: THIS WAS DISCOVERED BY ACCIDENT, CONE WITH 0 HEIGHT DISTORTS THE ELLIPSOID LIKE AN ARM
        		//The result is innacurated compared to original image but is better than just blending a cone with the ellipsoid
        		//lMangas = opSmoothUnion(lMangas, sdCone( (lMangasPos - vec3(0.0, -0.075, 0.0)), vec3(0.0), vec3(0.0, 0.01, 0.0), 0.028, 0.022), 0.02);
        		//Real shirt cuff
        		lMangas = opSmoothUnion(lMangas, sdCone( (lMangasPos - vec3(0.0, -0.106, 0.0)), vec3(0.0), vec3(0.0, 0.045, 0.0), 0.032, 0.019), 0.03);
		res = opU( res, vec2( lMangas, 5.0) );
        

        //res = opU( res, vec2( lCinturaCutter, 4.0) );
        float lUnMirror = (pos.x < 0.0) ? 1.0 : -1.0;
        //Arms
        float 	lArms = sdCone( lMangasPos - vec3(0.0, -0.12, 0.0), vec3(0.0), vec3(0.0, 0.03, 0.0), 0.022, 0.02);
				lArms = opSmoothUnion(lArms, sdSphere(opMirrorX(lTorsoPos) - vec3(0.16, 0.245, lUnMirror * 0.045), 0.036 ), 0.02);
        res = opU( res, vec2( lArms, 2.0) );
    	
        
		//Belt
        float 	lBeltCutter = sdBox(lTorsoPos - vec3( 0.0, -0.09 , 0.0), vec3(0.3,0.3,0.3));
        		lBeltCutter = min(lBeltCutter, sdBox(lTorsoPos - vec3( 0.0, 0.56 , 0.0), vec3(0.3,0.3,0.3)));
        	
        float lBelt = fOpIntersectionRound((lTorso - 0.0006), -lBeltCutter, 0.004);
        res = opU( res, vec2( lBelt, 5.0) );
        
        //Ebilla
        vec3    lEbillaPos = (lTorsoPos - vec3( 0.0, 0.235 , -0.085)); //rotation(X_AXIS, -0.05)
        float 	lEbilla = sdBox( lEbillaPos , vec3(0.036,0.02,0.015) );
        		lEbilla -= 0.005;
        		lEbilla = max(lEbilla, -sdBox( lEbillaPos , vec3(0.032,0.017,0.04) ));
        		
        res = opU( res, vec2( lEbilla, 10.0) );
        
        //TOOD: plunge breast zone (fOpIntersectionRound with sphere should be enough)
        
        //Breast
        float lBreast = sdCylinder( pos - vec3(0.0, 0.35, -0.04), vec2(0.05, 0.1) );
        lBreast = max(lBreast, lTorso2) - 0.0001;
        //Neck
        lBreast = opSmoothUnion(lBreast, sdCylinder( pos - vec3(0.0, 0.38, -0.03), vec2(0.03, 0.02) ), 0.01);
        res = opU( res, vec2( lBreast, 2.0) );
        
    }
    //----- END MIDDLE BODY ------
#endif
    
    //----- SWORD & SHIELD ------
    
#if defined(SHOW_SWORD) && (SHOW_SWORD == 1)
    //Sword
    vec3 lSwordPos = rotation(Y_AXIS, M_PI * -0.28) * rotation(X_AXIS, M_PI * 0.5) * rotation(Y_AXIS, M_PI * -0.2) * (pos - vec3(-0.146, 0.175, 0.02));    
    float 	lSwordBox = sdBox( lSwordPos-vec3( 0.0, 0.16, 0.0), vec3(0.1,0.28,0.04) );
    //res = opU( res, vec2( lSwordBox, 5.0) );
    if(res.x > lSwordBox)
    {

        
        //HANDLE
        //vec3 lSwordPos =  pos - vec3(-0.5, 0.5, 0.0);
        float	lSword = sdCylinder( lSwordPos - vec3(0.0, 0.02, 0.0), vec2(0.018, 0.05) );
        		lSword = min( lSword, sdSphere( lSwordPos - vec3(0.0, -0.05, 0.0), 0.028 ));
        
        //GUARDA
        vec3	lGuardPos = lSwordPos - vec3(0.0, 0.08, 0.0);
        		lSword = min( lSword, sdRoundBox(lGuardPos, vec3(0.05, 0.014, 0.014), 0.006));
        vec3 	lGuardSidesPos = rotation(Z_AXIS, -0.5) * (opMirrorX(lGuardPos) - vec3(0.05, 0.002, 0.0));
        float 	lRedution = abs(lGuardPos.x) < 0.05 ? 0.0 : (abs(lGuardPos.x) - 0.05) * 0.12;
        		lSword = min( lSword, sdRoundBox(lGuardSidesPos - vec3(0.015, 0.0, 0.0), 
                                                 vec3(0.02, 0.014  - lRedution , 0.014  - lRedution), 
                                                 0.006));
        
        //TOOD: try to do guard with a lSwordPos.x altered rotation matrix
        res = opU( res, vec2( lSword, 5.0) );
        
        //METAL
        //vec3 lElongate = opElongate(lSwordPos - vec3(0.0, 0.1, 0.0), vec3(0.028, 0.0, 0.0));
        //float lMetal = sdCylinder( lElongate , vec2(0.008, 0.01) );
        
        float lMetalCutter1 = sdBox(lSwordPos - vec3(0.0, 0.1, 0.0), vec3(0.034, 0.009, 0.008));
        float lMetal = sdEllipsoid( lSwordPos - vec3(0.0, 0.1, 0.0) , vec3(0.033, 0.08, 0.008) );
        lMetal = max(lMetal, lMetalCutter1);
        
        
        //HOJA
        //vec3 lElongateHoja = opElongate(lSwordPos - vec3(0.0, 0.2, 0.0), vec3(0.02, 0.08, 0.0));
        vec3 lHojaPos = lSwordPos - vec3(0.0, 0.22, 0.0);
        //lMetal = min( lMetal, sdOctahedron(lHojaPos * vec3(1.0, lHojaPos.y < 0.0 ? 0.25 : 1.0, 2.5), 0.08));
        float 	lHoja = sdCone( lHojaPos - vec3(0.0, 0.159, 0.0), 0.04, 0.05, 0.0002 );
         		lHoja = min(lHoja, sdCone( lHojaPos, 0.12, 0.029, 0.05 ));
        float	lReducerZHoja = abs(lHojaPos.x * 0.08);
         		lReducerZHoja += (abs(lHojaPos.y) > 0.12) ? (abs(lHojaPos.y) - 0.12) * 0.05  : 0.0;
        		lHoja = max(lHoja, sdBox( lHojaPos, vec3(0.05, 0.3, max(0.0005, 0.004 - lReducerZHoja))));
        
        float 	lAbatanador = sdRoundedCylinder( opMirrorZ(lHojaPos) - vec3(0.0, -0.01, 0.012), 0.005, 0.05, 0.1 );
        		lHoja = max(lHoja, -lAbatanador);
        lMetal = min(lMetal, lHoja);
        
        res = opU( res, vec2( lMetal, 9.0) );
        
        //res = opU( res, vec2( lAbatanador, 4.0) );
    }
#endif
    
#if defined(SHOW_SHIELD) && (SHOW_SHIELD == 1)
    //SHIELD
    vec3 	lShieldPos =  rotation(X_AXIS, M_PI * -0.05) * rotation(Y_AXIS, M_PI * 0.18)  * (pos - vec3(0.2, 0.2, -0.15)) * 0.74;
    float 	lShieldBox = sdBox( lShieldPos-vec3( 0.0, 0.04, 0.0), vec3(0.16,0.16,0.1) );
    //res = opU( res, vec2( lShieldBox, 5.0) );
    if(res.x > lShieldBox)
    {
        		lShieldPos = opMirrorX(lShieldPos);
        float 	lShieldCutter = sdBox(lShieldPos, vec3(0.14, 0.18, 0.024));
        float   lInnerShieldCutter = lShieldCutter;
        	  	lShieldCutter = fOpIntersectionRound(lShieldCutter, -sdSphere(lShieldPos - vec3(0.47, 0.94, 0.0),  0.9), 0.01);
        		lInnerShieldCutter = fOpIntersectionRound(lShieldCutter, -sdSphere(lShieldPos - vec3(0.47, 0.91, 0.0),  0.9), 0.01);
        //float 
        float 	lShield = sdEllipsoid(lShieldPos - vec3(-0.05, 0.1, 0.0), vec3(0.19, 0.22, 0.024));
        		lShield = max(lShield, lShieldCutter);
        
        //INNER
        float 	lInnerShield = sdEllipsoid(lShieldPos - vec3(-0.05, 0.1, -0.01), vec3(0.16, 0.19, 0.024));	
        		lInnerShield = max(lInnerShield, lInnerShieldCutter);
        		lInnerShield = fOpIntersectionRound(lInnerShield, -lShield, 0.004) - 0.005;
       float	lShield2 = max(lShield, -lInnerShield);
        		lInnerShield = max(max(lInnerShield, lShield2 + 0.0009) - 0.0011, lShield);
        		
        //DECORATIONS
        vec3	lConeSize = vec3(0.02, 0.03, 0.018);
		float	lMetalDecorations = sdCone( (lShieldPos - vec3(0.0, -0.07, 0.0)), lConeSize.x, lConeSize.y, lConeSize.z);
        
        		lMetalDecorations = min(lMetalDecorations, sdCone((rotation(Z_AXIS, -1.0) * lShieldPos - vec3(0.02, -0.076, 0.0)), lConeSize.x, lConeSize.y, lConeSize.z));
        		lMetalDecorations = min(lMetalDecorations, sdCone(rotation(Z_AXIS, -2.0) * lShieldPos - vec3(0.028, -0.125, 0.0), lConeSize.x, lConeSize.y, lConeSize.z));
        		lMetalDecorations = min(lMetalDecorations, sdCone(rotation(X_AXIS, -0.2) * (lShieldPos - vec3(0.0, 0.125, 0.0)), 0.02, 0.02, 0.04));
        
        		lMetalDecorations = max(lMetalDecorations, lShield);
        		
        		//Spheres
        		lMetalDecorations = min(lMetalDecorations, sdSphere(lShieldPos - vec3(0.000, -0.080, -0.005), 0.011));
        		lMetalDecorations = min(lMetalDecorations, sdSphere(lShieldPos - vec3(0.070, -0.020, -0.005), 0.011));
        		lMetalDecorations = min(lMetalDecorations, sdSphere(lShieldPos - vec3(0.110,  0.080, -0.007), 0.011));
        		lMetalDecorations = min(lMetalDecorations, sdSphere(lShieldPos - vec3(0.000,  0.140, -0.017), 0.011));
        
        		//lMetalDecorations = min(lMetalDecorations, lInnerShield);
        		//lShield -= 0.01;
    
        float 	lTriforce = sdCone( (lShieldPos - vec3(0.0, 0.09, -0.018)), 0.013, 0.016, 0.0001);
        		lTriforce = min(lTriforce, sdCone( (lShieldPos - vec3(0.016, 0.064, -0.018)), 0.013, 0.016, 0.0001)); 
        		lTriforce = max(lTriforce, lInnerShield - 0.0025);
		
        float	lBird = sdBox( rotation(Z_AXIS, -0.5) * (lShieldPos - vec3(-0.005, 0.026, -0.018)), vec3(0.013, 0.016, 0.04));
        		lBird = min(lBird, sdBox( rotation(Z_AXIS,  0.3) * (lShieldPos - vec3(-0.008, -0.026, -0.018)), vec3(0.013, 0.025, 0.04)));
        vec3 	lBirdBallPos = (lShieldPos - vec3(0.0, 0.02, -0.0));
        		lBird = min(lBird, 
                            max( sdSphere(lBirdBallPos, 0.037), 
                                -sdSphere(lBirdBallPos -vec3(0.0, 0.007, 0.0), 0.034)));
        		lBird = min(lBird, sdBox( rotation(Z_AXIS,  0.1) * (lShieldPos - vec3(0.046, 0.025, -0.018)), vec3(0.018, 0.0035 + (lShieldPos.x * 0.1), 0.04)));
        		lBird = min(lBird, sdBox( rotation(Z_AXIS,  0.3) * (lShieldPos - vec3(0.04, 0.008, -0.018)), vec3(0.015, 0.003 + (lShieldPos.x * 0.08), 0.04)));
        
        		lBird = min(lBird, sdBox( rotation(Z_AXIS,  0.7) * (lShieldPos - vec3(0.032, -0.003, -0.018)), vec3(0.013, 0.002 + (lShieldPos.x * 0.06), 0.04)));
        
        		lBird = max(lBird, lInnerShield - 0.0025);
        
        float   lRays = sdCone( rotation(Z_AXIS,  -0.2 - pow(lShieldPos.x * 5.5, 0.8)) * (lShieldPos - vec3(0.04, 0.08, -0.018)), 0.033, 0.01, 0.001);
            
            	lRays = max(lRays, lInnerShield - 0.0025);
        
        //HANDLE        
        float lHandle = sdTorus( rotation(Z_AXIS, M_PI * 0.5) * (lShieldPos - vec3(0.0, 0.0, 0.02)), vec2(0.03, 0.008) );
              lHandle = max(lHandle, length(lShieldPos - vec3(0.0, 0.0, 0.07)) - 0.08);
        lShield2 = min(lShield2, lHandle);
        
        res = opU( res, vec2( lShield2, 9.0) );
        res = opU( res, vec2( lInnerShield, 11.0) );
        res = opU( res, vec2( lMetalDecorations, 9.0) );
        res = opU( res, vec2( lTriforce, 10.0) );
        res = opU( res, vec2( lBird, 12.0) );
        res = opU( res, vec2( lRays, 9.0) );
    }
#endif
    //----- END SWORD & SHIELD ------
    
    //Debug reference
    //float lFront = sdSphere(pos - vec3(0.0, 0.66, -0.5), 0.08);
    //res = opU( res, vec2( lFront, 4.0) );
    return res;
}

// https://iquilezles.org/articles/boxfunctions
vec2 iBox( in vec3 ro, in vec3 rd, in vec3 rad ) 
{
    vec3 m = 1.0/rd;
    vec3 n = m*ro;
    vec3 k = abs(m)*rad;
    vec3 t1 = -n - k;
    vec3 t2 = -n + k;
	return vec2( max( max( t1.x, t1.y ), t1.z ),
	             min( min( t2.x, t2.y ), t2.z ) );
}

const float maxHei = 0.8;

vec2 castRay( in vec3 ro, in vec3 rd )
{
    vec2 res = vec2(-1.0,-1.0);

    float tmin = 1.0;
    float tmax = 20.0;

    // raytrace floor plane
    float tp1 = (0.0-ro.y)/rd.y;
    if( tp1>0.0 )
    {
        tmax = min( tmax, tp1 );
        res = vec2( tp1, 1.0 );
    }
    //else return res;
    
    // raymarch primitives   
    vec2 tb = iBox( ro-vec3(0.0,0.5,0.1), rd, vec3(0.4,0.5,0.5) );
    if( tb.x<tb.y && tb.y>0.0 && tb.x<tmax)
    {
        tmin = max(tb.x,tmin);
        tmax = min(tb.y,tmax);

        float t = tmin;
        for( int i=0; i<70 && t<tmax; i++ )
        {
            vec2 h = map( ro+rd*t );
            if( abs(h.x)<(0.0001*t) )
            { 
                res = vec2(t,h.y); 
                 break;
            }
            t += h.x;
        }
    }
    
    return res;
}


// https://iquilezles.org/articles/rmshadows
float calcSoftshadow( in vec3 ro, in vec3 rd, in float mint, in float tmax )
{
    // bounding volume
    float tp = (maxHei-ro.y)/rd.y; if( tp>0.0 ) tmax = min( tmax, tp );

    float res = 1.0;
    float t = mint;
    for( int i=ZERO; i<16; i++ )
    {
		float h = map( ro + rd*t ).x;
        float s = clamp(8.0*h/t,0.0,1.0);
        res = min( res, s*s*(3.0-2.0*s) );
        t += clamp( h, 0.02, 0.10 );
        if( res<0.005 || t>tmax ) break;
    }
    return clamp( res, 0.0, 1.0 );
}

// https://iquilezles.org/articles/normalsSDF
vec3 calcNormal( in vec3 pos )
{
#if 0
    vec2 e = vec2(1.0,-1.0)*0.5773*0.0005;
    return normalize( e.xyy*map( pos + e.xyy ).x + 
					  e.yyx*map( pos + e.yyx ).x + 
					  e.yxy*map( pos + e.yxy ).x + 
					  e.xxx*map( pos + e.xxx ).x );
#else
    // inspired by tdhooper and klems - a way to prevent the compiler from inlining map() 4 times
    vec3 n = vec3(0.0);
    for( int i=ZERO; i<4; i++ )
    {
        vec3 e = 0.5773*(2.0*vec3((((i+3)>>1)&1),((i>>1)&1),(i&1))-1.0);
        n += e*map(pos+0.0005*e).x;
    }
    return normalize(n);
#endif    
}

float calcAO( in vec3 pos, in vec3 nor )
{
	float occ = 0.0;
    float sca = 1.0;
    for( int i=ZERO; i<5; i++ )
    {
        float hr = 0.01 + 0.12*float(i)/4.0;
        vec3 aopos =  nor * hr + pos;
        float dd = map( aopos ).x;
        occ += -(dd-hr)*sca;
        sca *= 0.95;
    }
    return clamp( 1.0 - 3.0*occ, 0.0, 1.0 ) * (0.5+0.5*nor.y);
}

// https://iquilezles.org/articles/checkerfiltering
float checkersGradBox( in vec2 p, in vec2 dpdx, in vec2 dpdy )
{
    // filter kernel
    vec2 w = abs(dpdx)+abs(dpdy) + 0.001;
    // analytical integral (box filter)
    vec2 i = 2.0*(abs(fract((p-0.5*w)*0.5)-0.5)-abs(fract((p+0.5*w)*0.5)-0.5))/w;
    // xor pattern
    return 0.5 - 0.5*i.x*i.y;                  
}

vec3 calcColor(float m, vec3 pos, vec3 nor, vec3 ro, vec3 rd, in vec3 rdx, in vec3 rdy)
{
	if( m<1.5 )
	{ 	// project pixel footprint into the plane
	    vec3 dpdx = ro.y*(rd/rd.y-rdx/rdx.y);
	    vec3 dpdy = ro.y*(rd/rd.y-rdy/rdy.y);
	    float f = checkersGradBox( 5.0*pos.xz, 5.0*dpdx.xz, 5.0*dpdy.xz );
	    return 0.15 + f*vec3(0.05);
	}
    else if(m < 2.5)
    { 	//Skin
    	return vec3(1.0, 0.807, 0.705) * 0.4;
    }
    else if(m < 3.5)
    { 	//Traje
        return vec3(0.1, 0.7, 0.2) * 0.35;
    }
    else if(m < 4.5)
    { 	//Black
        return vec3(0.0, 0.0, 0.0);
    }
    else if(m < 5.5)
    { 	//Brown
        return vec3(0.745, 0.270, 0.062) * 0.2;
    }
    else if(m < 6.5)
    {	
        //Clear Green
        return vec3(0.1, 0.9, 0.2) * 0.65;
    }
    else if(m < 7.5)
    {	//Hair
        return vec3(1.0, 0.8, 0.0) * 0.5;
    }
    else if(m < 8.5)
    {	//Leggings
        return vec3(0.5, 0.5, 0.5) * 0.8;
    }
    else if(m < 9.5)
    {	//Metal
        return vec3(0.5, 0.5, 0.5);
    }
    else if(m < 10.5)
    {	
        //Gold
        return vec3(1.0, 0.8, 0.05) * 0.7;
    }
    else if(m < 11.5)
    {	//Metal Blue
        return vec3(0.05, 0.2, 0.8) * 0.65;
    }
    else if(m < 12.5)
    {	//Metal Red
        return vec3(0.8, 0.1, 0.1) * 0.65;
    }
    
    return vec3(0.0, 0.0, 0.0);
}


vec3 render( in vec3 ro, in vec3 rd, in vec3 rdx, in vec3 rdy )
{ 
    vec3 col = vec3(0.7, 0.7, 0.9) - max(rd.y,0.0)*0.3;
    vec2 res = castRay(ro,rd);
    float t = res.x;
	float m = res.y;
    if( m>-0.5 )
    {
        vec3 pos = ro + t*rd;
        vec3 nor = (m<1.5) ? vec3(0.0,1.0,0.0) : calcNormal( pos );
        vec3 ref = reflect( rd, nor );
        
        // material        
        col = calcColor(m, pos, nor, ro, rd, rdx, rdy);


        // lighting
        float occ = calcAO( pos, nor );
		vec3  lig = normalize( vec3(-0.5, 0.4, -0.6) );
        vec3  hal = normalize( lig-rd );
		float amb = sqrt(clamp( 0.5+0.5*nor.y, 0.0, 1.0 ));
        float dif = clamp( dot( nor, lig ), 0.0, 1.0 );
        float bac = clamp( dot( nor, normalize(vec3(-lig.x,0.0,-lig.z))), 0.0, 1.0 )*clamp( 1.0-pos.y,0.0,1.0);
        float dom = smoothstep( -0.2, 0.2, ref.y );
        float fre = pow( clamp(1.0+dot(nor,rd),0.0,1.0), 2.0 );
        
        //Avoid shield decorations self shadow
        if(m < 8.5 && !(m > 5.5 && m < 6.5)) //!(m > 11.5 && m < 12.5)
        {
        	dif *= calcSoftshadow( pos, lig, 0.02, 2.5 );
        }
        
        dom *= calcSoftshadow( pos, ref, 0.02, 2.5 );

		float spe = pow( clamp( dot( nor, hal ), 0.0, 1.0 ),16.0)*
                    dif *
                    (0.04 + 0.96*pow( clamp(1.0+dot(hal,rd),0.0,1.0), 5.0 ));

		vec3 lin = vec3(0.0);
        if(m > 1.5 && m < 2.5)
        {
            vec3 lOccDifShadow = mix(vec3(3.8, 0.874, 0.588) * 0.22, vec3(2.8, 0.874, 0.488) * 0.4, occ);
            lin += mix(lOccDifShadow , col,  dif) * 1.8;
            //exagerated fresnel like in 3D movie
            lin += 3.0*fre*vec3(1.00,1.00,1.00)*occ;
        }
        else if(m > 6.5 && m < 7.5)
        {
            //Hair
            vec3 lOccDifShadow = mix(vec3(1.825, 0.25, 0.41) * 0.4, vec3(0.525, 0.15, 0.1) * 0.8, occ);
            lin += mix(lOccDifShadow , col,  dif) * 1.8;
            //exagerated fresnel like in 3D movie
            lin += 3.0*fre*vec3(1.00,1.00,1.00)*occ;
        }
        
        lin += 1.80*dif*vec3(1.30,1.00,0.70);
        lin += 0.55*amb*vec3(0.40,0.60,1.15)*occ;
        
        if(
            (m > 4.5 && m < 5.5) || 
            (m < 1.5)
          )
        {
        	lin += 0.85*dom*vec3(0.40,0.60,1.30)*occ;
        }
        else if (	
           			(m > 8.5 && m < 12.5)
                )
        {
        	lin += 3.85*dom*vec3(0.40,0.60,1.30)*occ;
        }
        
        lin += 0.55*bac*vec3(0.25,0.25,0.25)*occ;
        lin += 0.25*fre*vec3(1.00,1.00,1.00)*occ;
		col = col*lin;
		col += 1.50*spe*vec3(1.10,0.90,0.70);

        if(  (m > 4.5 && m < 5.5) || 
             (m > 6.5 && m < 7.5) ||
           	 (m > 8.5 && m < 12.5)
           )
    	{ 	//Leather & metals
        	col += 5.50*spe*vec3(1.10,0.90,0.70);
    	}
        
        col = mix( col, vec3(0.7,0.7,0.9), 1.0-exp( -0.0001*t*t*t ) );
    }

	return vec3( clamp(col,0.0,1.0) );
}

mat3 setCamera( in vec3 ro, in vec3 ta, float cr )
{
	vec3 cw = normalize(ta-ro);
	vec3 cp = vec3(sin(cr), cos(cr),0.0);
	vec3 cu = normalize( cross(cw,cp) );
	vec3 cv =          ( cross(cu,cw) );
    return mat3( cu, cv, cw );
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 mo = iMouse.xy/iResolution.xy;
	float time = -20.0 + iTime*1.5;

    // camera	
    vec3 ro = vec3( 1.6*cos(0.1*time + 12.0*mo.x),  0.5 + 2.0*mo.y, 1.6*sin(0.1*time + 12.0*mo.x) );
    vec3 ta = vec3( 0.0, 0.4, 0.0 );
    // camera-to-world transformation
    mat3 ca = setCamera( ro, ta, 0.0 );

    vec3 tot = vec3(0.0);
#if AA>1
    for( int m=ZERO; m<AA; m++ )
    for( int n=ZERO; n<AA; n++ )
    {
        // pixel coordinates
        vec2 o = vec2(float(m),float(n)) / float(AA) - 0.5;
        vec2 p = (-iResolution.xy + 2.0*(fragCoord+o))/iResolution.y;
#else    
        vec2 p = (-iResolution.xy + 2.0*fragCoord)/iResolution.y;
#endif

        // ray direction
        vec3 rd = ca * normalize( vec3(p,2.0) );

         // ray differentials
        vec2 px = (-iResolution.xy+2.0*(fragCoord.xy+vec2(1.0,0.0)))/iResolution.y;
        vec2 py = (-iResolution.xy+2.0*(fragCoord.xy+vec2(0.0,1.0)))/iResolution.y;
        vec3 rdx = ca * normalize( vec3(px,2.0) );
        vec3 rdy = ca * normalize( vec3(py,2.0) );
        
        // render	
        vec3 col = render( ro, rd, rdx, rdy );

		// gamma
        col = pow( col, vec3(0.4545) );

        tot += col;
#if AA>1
    }
    tot /= float(AA*AA);
#endif

    
    fragColor = vec4( tot, 1.0 );
}
﻿// create by JiepengTan 2018-04-13  
// email: jiepengtan@gmail.com
Shader "FishManShaderTutorial/SDF" {
    Properties{
        _MainTex("Base (RGB)", 2D) = "white" {}
    }
    SubShader{
        Pass {
            ZTest Always Cull Off ZWrite Off
            CGPROGRAM
			
#define DEFAULT_MAT_COL
#define DEFAULT_PROCESS_FRAG
#define DEFAULT_RENDER

#pragma vertex vert   
#pragma fragment frag  
#include "ShaderLibs/Framework3D_DefaultRender.cginc"



            float3 rX(const in float3 v, const in float cs, const in float sn) {return mul(v,float3x3(1.0,0.0,0.0,0.0,cs,sn,0.0,-sn,cs));}
            float3 rY(const in float3 v, const in float cs, const in float sn) {return mul(v,float3x3(cs,0.0,-sn,0.0,1.0,0.0,sn,0.0,cs));}
            float3 rZ(const in float3 v, const in float cs, const in float sn) {return mul(v,float3x3(cs,sn,0.0,-sn,cs,0.0,0.0,0.0,1.0));}


            // implicitly specifies shading rules
            #define WOOD_MAT 0.
            #define STRAW_MAT 1.
            #define VILLAGE_MAT 2.

            #define BridgeL 40.
            #define BridgeW 2.
            #define BridgeH 4.

            #define BridgeL1 50.


            #define LegGap (BridgeW*0.45)
            #define LegWid 0.1
            #define LegLenGap LegGap * 4.

            #define BoardLen  0.2

            fixed SdCappedCone( in fixed3 p, in fixed3 c ) // c=fixed3(bottom radius, angle , height)
            {
                fixed2 q = fixed2( length(p.xz), p.y );
                fixed2 v = fixed2( c.z*c.y/c.x, -c.z );
                fixed2 w = v - q;
                fixed2 vv = fixed2( dot(v,v), v.x*v.x );
                fixed2 qv = fixed2( dot(v,w), v.x*w.x );
                fixed2 d = max(qv,0.0)*qv/vv;
                return sqrt( dot(w,w) - max(d.x,d.y) )* sign(max(q.y*v.x-q.x*v.y,w.y));
            }

  
            fixed SdBoatHull( fixed3 vPos )
            {
                vPos.y-=0.4;
                fixed3 vBoatDomain = vPos;
                vBoatDomain.x = abs(vBoatDomain.x);
                
                fixed boatDist = length( vBoatDomain.xyz - fixed3(-3.9,3.2,0.)) - 5.6;
            	
                fixed bs = 14.5;
                fixed gap = 0.3;
                fixed2 offset=fixed2(0.3,bs+gap);
                fixed cylinder= length(vBoatDomain.xy-offset)-bs;
                boatDist=OpS(boatDist,cylinder);
                fixed sSize = 15.0;
                fixed sOff = 0.05;
                fixed sphere = length( vBoatDomain.xyz - fixed3(0,sSize+sOff,0)) - sSize;
                boatDist=OpS(boatDist,sphere);
                
                fixed bx = vPos.y+0.4;
                boatDist=OpS(boatDist,bx);
                
                return boatDist;
            }


            fixed SdHalfCylinder(fixed3 pos , fixed3 h){
                fixed cy=OpS(
                    SdCylinder(pos.yzx,h.xy + fixed2(0.03,-0.03)),
                    SdCylinder(pos.yzx,h.xy)
                );
                fixed bx = SdBox(pos-fixed3(0.,-h.x*h.z*2.,0.),fixed3(h.x+0.3,h.x,h.y+0.3));
                return OpS(cy,bx);
            }



            fixed SdQuant(fixed3 pos){
                pos -= fixed3(-0.,.3,0.);
                fixed barLen = 0.3;
                fixed quantLen = 0.2;
            	fixed cy = SdCylinder(pos-fixed3(0.,0.,0.),fixed2(0.008,barLen));
                fixed bx = SdRoundBox(pos-fixed3(0.,barLen+quantLen,0.),fixed3(0.025,quantLen,0.002),0.003);
                return min(cy,bx);
            }
             
            fixed SdBoat(fixed3 pos){
                fixed ret = 10000.;
                //body
                fixed vb = SdBoatHull(pos);
                pos.y -=0.07;
                fixed vs = SdBoatHull(pos);
                fixed boatBody =  OpS(vb,vs); 
                
                ret = min(ret , boatBody);
                //quant
                fixed3 quantPos = pos ;
                quantPos.x = abs(pos.x);
                quantPos = quantPos- fixed3(0.05,.72,1.5);
                
                fixed degZ= PI*-0.15;
                quantPos = rZ(quantPos,sin(degZ),cos(degZ));
                fixed degX= PI*0.65;
                quantPos = rX(quantPos,sin(degX),cos(degX));
                fixed quant = SdQuant(quantPos*0.5);
                ret = min(ret , quant);
                
                //quant Ring
                
                fixed3 ringPos = pos ;
                ringPos.x = abs(pos.x);
                ringPos = ringPos- fixed3(0.44,.49,1.72);
                
                degZ= PI*-0.05;
                ringPos = rZ(ringPos,sin(degZ),cos(degZ));
                degZ= PI*-0.45;
                ringPos = rX(ringPos,sin(degZ),cos(degZ));
                fixed ringd = SdTorus(ringPos,fixed2(0.05,0.005));
                ret = min(ret , ringd);
                //bar
                fixed3 bpos = pos;
                bpos.z = abs(bpos.z);
                fixed bar1 = SdRoundBox(bpos-fixed3(0.,0.4,1.5),fixed3(.46,0.01,0.04),0.01);
                ret = min(ret , bar1);
                
                // roof
               	fixed3 q1=pos-fixed3(0.,0.65,0.);
                fixed3 roofSize = fixed3(0.65,1.0,0.7);
                fixed roof = SdHalfCylinder(q1,roofSize);
                ret = min(ret , roof);
                
                //pos.x= abs(pos.x);//!! it is strange that i cann't use pos.x= abs(pos.x) to simplify the code
                fixed3 padPos = pos;
                //padPos.x = abs(pos.x);
                fixed paddingT = SdClipCylinder( padPos - fixed3(-0.65,0.42,0.),fixed3(8,0.02,0.003));
                ret = min(ret , paddingT);
                padPos.x = -pos.x;
                paddingT = SdClipCylinder( padPos - fixed3(-0.65,0.42,0.),fixed3(8,0.02,0.003));
                ret = min(ret , paddingT);
                
                return ret;
            }


            fixed BridgeSeg1(fixed mindist,in fixed3 pos){
                fixed dis= 0.;
            	
                // bridge leg
                fixed3 legPos = pos;
                legPos.z -= LegLenGap * 0.5;
                if( legPos.z < BridgeL-LegLenGap && legPos.z >0.){
                	legPos.z = fmod(legPos.z,LegLenGap) - LegLenGap * 0.5;
                }
                
               	dis = SdCylinder( fixed3(abs(legPos.x),legPos.yz)-fixed3(LegGap,0.,0.0), fixed2(LegWid,BridgeH) );
                mindist = min( dis, mindist );
                
                dis = SdBox( legPos-fixed3(0.,BridgeH*0.8,0.0), fixed3(LegGap*0.95,LegWid*0.7,LegWid*0.7) );
                mindist = min( dis, mindist );
                
                // bridge face
                fixed3 facePos = pos;
                dis = SdBox( facePos-fixed3(0.,BridgeH,BridgeL*0.5 ), fixed3(BridgeW,LegWid*0.7,BridgeL*0.5) );
                mindist = min( dis, mindist );
                
                fixed3 boardPos = pos;
                if( boardPos.z < BridgeL && boardPos.z >0.){
                	boardPos.z = fmod(boardPos.z,BoardLen)- BoardLen * 0.5;
                }
                dis = SdBox( boardPos-fixed3(0.,BridgeH + .1,0.), fixed3(BridgeW,0.1,BoardLen*0.3));
                //dis = SdSphere( boardPos-fixed3(0.,BridgeH + 4.,BridgeL*0.5),fixed4(0.,0.,0.,0.5));
                //dis = SdSphere( boardPos, fixed4(0.,BridgeH,0.,0.5) );
                mindist = min( dis, mindist );
               
                return mindist;  
            }

            fixed BridgeSeg2(fixed mindist,in fixed3 pos){
                fixed dis= 0.;
            	pos.z -= BridgeL;
                pos.xz = pos.zx;
                pos.z = -pos.z;
                pos.z += BridgeW;
                
                return BridgeSeg1(mindist,pos);
            }
            fixed SdBridge( in fixed3 pos )
            {
                pos*=3.;
            	fixed mindist = 10000000.0;
            	
                fixed f = 0.5;//-0.5*cos(3.14159*pos.z/20.0);
            	mindist = BridgeSeg1(mindist,pos);
              	mindist = BridgeSeg2(mindist,pos);
            	return 0.25*mindist;
            }

			fixed SdBounceBalls(fixed3 pos){
                fixed SIZE = 2.;
                fixed2 gridSize = fixed2(SIZE,SIZE);
                fixed rv = Hash12( floor((pos.xz) / gridSize));
                pos.xz = OpRep(pos.xz,gridSize);
                fixed bollSize = 0.1;
                fixed bounceH = .5;
                return SdSphere(pos- fixed3(0.,(bollSize+bounceH+sin(_Time.y*3.14 + rv*6.24)*bounceH),0.),bollSize);
            }

            fixed2 Map( in fixed3 pos )
            {
                fixed2 res = fixed2( SdPlane(     pos), 1.0 )  ;
                res = OpU( res, fixed2( SdBounceBalls( pos),1.) );
                res = OpU( res, fixed2( SdBridge( pos),1.) );
                
            	pos -=fixed3(-1,0.,-.5);
                fixed deg = 1.*3.14159/180.;
                pos = rY(pos,sin(deg),cos(deg));
                res = OpU( res, fixed2( SdBoat( pos),1.) );
              
                return res;
            }
            ENDCG
        }//end pass
    }//end SubShader
    FallBack Off
}




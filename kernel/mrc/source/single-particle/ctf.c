/*
 *
 *  Created by Xiangyan Zeng on 1/1/2007
 *  Copyright 2007 __MyCompanyName__. All rights reserved.
 *
 */

 
 
#define  pi      3.1415926


void ctfapply(int sx,int sy, float *Image1, float *ctf_para)
{    
      int i,j,k,m;
  
       float WL,STEPR,THETATR,RAD,ANGLE,C1,C2,ANGDIF,CNTRST,CHI,DF,PHACON,ANGSPT,CCOS, AMPCON,CS1,KV1;
       int   ISIZE=sx;
       float *ctf, SNR, max1,min1,max2,min2;
	 float  CS, KV,  DIFMID1, DIFMID2, ANGAST, DSTEP, XMAG;
  
       fftwf_complex *in, *out;
       fftwf_plan p1,p2;
     

	 CS=ctf_para[0];
	 KV=ctf_para[1];
	 DIFMID1=ctf_para[2];
	 DIFMID2=ctf_para[3];
	 ANGAST=ctf_para[4];
	 DSTEP=ctf_para[5];
	 XMAG=ctf_para[6];
     
       
       ctf=(float *)calloc(sx*sy,sizeof(float));
     

//       in=(fftwf_complex *)fftwf_malloc(sizeof(fftwf_complex)*sx*sy);
       out=( fftwf_complex *)fftwf_malloc(sizeof(fftwf_complex)*sx*sy);
 

       CS1=CS*(10000000);
       KV1=KV*1000;
       WL=12.3/sqrt(KV1+KV1*KV1/(1000000.0));

       STEPR=DSTEP*(10000)/XMAG;
       THETATR=WL/(STEPR*ISIZE); 
       
             
    //   PHACON=0.9975;
    //   AMPCON=sqrt(1-PHACON*PHACON);
    
    
//       printf("CTF: CS=%f  KV=%f  CS1=%f KV1=%f\n",CS,KV,CS1,KV1);
    
            
        AMPCON=0.07;
        PHACON=sqrt(1-AMPCON*AMPCON);
   
/*    Get ctf   */

       SNR=0.01;
       for(i=0;i<sx;i++)
        {  
          for(j=0;j<sy;j++)
	     {  
	        	RAD = sqrtf((i-sx/2)*(i-sx/2)*1.0+(j-sy/2)*(j-sy/2)*1.0);
   	        	ANGLE=RAD*THETATR;
 	        	ANGSPT=atan2(((j-sy/2)*1.0),((i-sx/2)*1.0));
      	     C1=2*pi*ANGLE*ANGLE/(2.0*WL);
      	     C2=-C1*CS1*ANGLE*ANGLE/2.0;
               ANGDIF=ANGSPT-ANGAST*pi/180;
      	     CCOS=cos(2*ANGDIF);
			if(i==sx/2 && j==sy/2) ctf[j+i*sy]=-AMPCON; // 1.0;
			else if(DIFMID1==0.0 || DIFMID2==0.0 )
		     	ctf[j+i*sy]=1.0;
			else
		  	{
      	             DF=0.5*(DIFMID1+DIFMID2+CCOS*(DIFMID1-DIFMID2));
      	             CHI=C1*DF+C2;
       	             ctf[j+i*sy]=-sin(CHI)*PHACON-cos(CHI)*AMPCON;
		     
		  	}	 
	      }  
	}

   
   
       for(i=0;i<sx;i++)
         for(j=0;j<sy;j++)
          {    
             out[j+i*sy][0]=Image1[j+i*sy]*pow(-1,(i+j)*1.0); 
             out[j+i*sy][1]=0;
           } 
  
       p1=fftwf_plan_dft_2d(sx,sy,out,out,FFTW_FORWARD,FFTW_ESTIMATE);
       
       fftwf_execute(p1);
       fftwf_destroy_plan(p1);
      
     
/*  CTF correction of FFT image   */
                               
       for(i=0;i<sx;i++)
	   for(j=0;j<sy;j++)
	   if(ctf[j+i*sy]<0)
	   {      out[j+i*sy][0]=-out[j+i*sy][0];    //*ctf[j+i*sy]/(powf(ctf[j+i*sy],2.0)+0.04);
                out[j+i*sy][1]=-out[j+i*sy][1];    // *ctf[j+i*sy]/(powf(ctf[j+i*sy],2.0)+0.04); 
        }	       
    
  
/*  IFFT transform  */  
       p2=fftwf_plan_dft_2d(sx,sy,out,out,FFTW_BACKWARD,FFTW_ESTIMATE);
       fftwf_execute(p2);
       fftwf_destroy_plan(p2);
    
       max2=-1.0e20;  min2=-max2;
       for(i=0;i<sx;i++)
         for(j=0;j<sy;j++)
	  {
                  Image1[j+i*sy]=out[j+i*sy][0]*pow(-1,(i+j)*1.0);       
                  if(max2<Image1[j+i*sy]) max2=Image1[j+i*sy];
	             if(min2>Image1[j+i*sy]) min2=Image1[j+i*sy];
	  }
	  
  
        for(i=0;i<sx;i++)
          for(j=0;j<sy;j++)
	       Image1[j+i*sy]=(Image1[j+i*sy]-min2)/(max2-min2)*255+1;  
	 

       //  fftwf_free(in);
       fftwf_free(out);
       free(ctf);

      
       
	
      
       

}

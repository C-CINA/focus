/*--------------------------------------------------------------------------------------------------
     Aplly low pass and high pass filtering to the masked PS image
    
    May,2006  by  Xiangyan Zeng  in Stahlberg Lab
    
    Input Parameters:
            sx:   number of rows 
            sy:   number of columns
	   amp:   PS file
	   q_l:   cut of low pass filtering
	   q_h:   cut of high pass filtering
	   
	   
    
    Output file
        2dx_peaksearch-amp_LHpass.mrc   (low-high pass filtered PS image)
      
 ---------------------------------------------------------------------------------------------------*/    
 
#include "common.h" 
 
void low_high_pass(int sx,int sy,float *amp, float q_l, float q_h)
{  
   
   fftwf_complex *in, *out;
   fftwf_plan p1,p2;
   int i,j,k;
   float  *phase, max,min, *temp_amp, mask_low, mask_high, delta_low, delta_high, tt; 

   temp_amp=(float *)malloc(sizeof(float)*sx*sy);
   phase=(float *)malloc(sizeof(float)*sx*sy);
   
  
  


   in=(fftwf_complex *)fftwf_malloc(sizeof(fftwf_complex)*sx*sy);
   out=( fftwf_complex *)fftwf_malloc(sizeof(fftwf_complex)*sx*sy);


   //importWisdom(); 
   p1=fftwf_plan_dft_2d(sx,sy,in,out,FFTW_FORWARD,FFTW_ESTIMATE);
   p2=fftwf_plan_dft_2d(sx,sy,out,in,FFTW_BACKWARD,FFTW_ESTIMATE);



  

    for(i=0;i<sx;i++)
      for(j=0;j<sy;j++)
        {  
           in[j+i*sy][0]=amp[j+i*sy]*pow(-1,(i+j)*1.0); 
           in[j+i*sy][1]=0;
        }
 
   
   
    fftwf_execute(p1);
    //exportWisdom();
    fftwf_destroy_plan(p1); 


/*  Get amplitude and phase of FFT image*/
     for(i=0;i<sx;i++)
      for(j=0;j<sy;j++)
        {
           amp[j+i*sy]=sqrt(pow(out[j+i*sy][0],2)+pow(out[j+i*sy][1],2));

          
           phase[j+i*sy]=atan2(out[j+i*sy][1],out[j+i*sy][0]);
           
        }  



/*  Masking the frequency */
    
    
    delta_low=q_l*(sx+sy)/4;
    delta_high=q_h*(sx+sy)/4;
    for(i=0;i<sx;i++)
       for(j=0;j<sy;j++)
           {   
              tt=-pow((double)(i-sx/2.0),2.0)-pow((double)(j-sy/2.0),2.0);
              mask_low=exp(tt/(2*delta_low*delta_low)); 
              mask_high=exp(tt/(2*delta_high*delta_high));


               // if(abs((double)(i-sx/2)*2)/sx<q_l && abs((double)(i-sx/2)*2)/sx>q_h)
               //    amp[j+i*sy]=0;   /*  for hard cut of frequency  */
            
               amp[j+i*sy]=amp[j+i*sy]*mask_low*(1-mask_high);

	       out[j+i*sy][0]=amp[j+i*sy]*cos(phase[j+i*sy]);
               out[j+i*sy][1]=amp[j+i*sy]*sin(phase[j+i*sy]);                    

           }  



/*  IFFT transform  */



    fftwf_execute(p2);
    fftwf_destroy_plan(p2); 
     

   	
	
     min=1.0e40; max=-min;
     for(i=0;i<sx; i++)
       for(j=0;j<sy;j++)
         { 
	   amp[j+i*sy]=in[j+i*sy][0]*pow(-1,(i+j)*1.0); 
           if(min>amp[j+i*sy]) min=amp[j+i*sy];
           if(max<amp[j+i*sy]) max=amp[j+i*sy];
         }
	
	
     for(i=0;i<sx;i++)
        for(j=0;j<sy;j++)
	  {  amp[j+i*sy]=(amp[j+i*sy]-min)*100.0/(max-min);
             temp_amp[i+j*sx]=amp[j+i*sy];
	  }  
      	
	
	 
     char *complexData = mrcImage::complexFromReal(sx,sy,2,(char*)temp_amp);
     mrcImage::mrcHeader *header = mrcImage::headerFromData(sx/2+1,sy,4,complexData);
   
     char fileName[] = "2dx_peaksearch-amp_LHpass.mrc";
     mrcImage(header,complexData,fileName);
     cout<<fileName<<" written"<<endl;


	 
	 
	 
      
    fftwf_free(in); fftwf_free(out);
    free(phase);    free(temp_amp);


}

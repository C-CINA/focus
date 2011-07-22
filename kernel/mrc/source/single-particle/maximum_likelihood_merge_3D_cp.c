/*  
 *
 *  Created by Xiangyan Zeng on 1/1/2007
 *  Copyright 2007 __MyCompanyName__. All rights reserved.
 *

*   This program merges  multiple crystals  and generates a reference using maximum likelihood merging algorithm 

*   It considers rotation and translation and can be used for merging 2d crystals
*  The rotation of the particles from a single stack is assumed to have Gaussian distribution 
*  The translation offset is assumed to have Gaussian distribution or uniforma distribution 
*
*   The stacks may have different rotation, translation, and noise statistics. A common structure is assumed for all 
*   the crystals to be merged and is obtained by the alignment of individual ML references. 
*
*  Input
*      nx, ny:  image patch size
*      num_images: number of image patches
*      Iteration: maximum iterations of maximum likelihood (normally the stop criterion is that the convergence of parameter is small enough)
*      Image: Stack of whitened image patches 
*      Image_CTF: Stack of CTF corrected image patches   
*   
*  Output
*      refer:                reference obtained from the whole dataset
*      refer1:               reference obtained from even numbers
*      refer2:               reference obtained from odd numbers 
*      Image_refer:
*      Image_refer_CTF:
*/


#include <string>
#include <stdio.h>
#include <stdlib.h>
#include <mrcImage.h>

#ifndef pi
#define pi 3.141592654
#endif


pthread_mutex_t lock1,lock2,lock3, lock4,lock5,lock6,lock7;

#define Max_num 210            /*  Maximum number of particles processed at one time */

#define MaxLoop 10



//#include "MLpthread_cp.c"

#include "CCpthread.c"
//#include "HIO.c"



using namespace std;
 
 

void maximum_likelihood(int Numstack, int nx, int ny, char *dirfilename, float *refer, 
                        float *refer1, float *refer2, FILE *results)

{
       FILE  *input[2], *output[2];
       int  Nthread;
       Nthread=2; 
       int shift=1;  

 //      int  rmax1=2, rmax2=(int)(0.9*nx/2);
       pthread_attr_t* thAttr=NULL;
       my_struct  av[Nthread];
       pthread_t tid[Nthread]; 
  
       fftwf_complex *in3,*out3, *in2, *out2;
       fftwf_plan  p2,p3; 
	  in2=(fftwf_complex *)fftwf_malloc(sizeof(fftwf_complex)*nx*ny);
       out2=(fftwf_complex *)fftwf_malloc(sizeof(fftwf_complex)*nx*ny);      
       in3=(fftwf_complex *)fftwf_malloc(sizeof(fftwf_complex)*nx*ny*nx);
       out3=(fftwf_complex *)fftwf_malloc(sizeof(fftwf_complex)*nx*ny*nx); 


       int CTF=1;
       float Gau=2.0, phas;

       int i,j,k,m,n,k1,k2,k3,k4,sta,Loop,num_refer,Num_angles, num_images_stack, num_temp, Num_images, error;
       int ang1,ang2,ang3,*num, *indx, *indy;
       char *filename1, *filename2;
       float powrefer, pow_RT;
       float *angles, *slice, *pdf, *par, *normal,*normal1, *normal2, *normal_CTF, *re, *im, *re_CTF, *im_CTF, *pow_image, *refer_CTF;
       float *new_re_refer, *new_im_refer, *new_re_refer1, *new_im_refer1, *new_re_refer2, *new_im_refer2, *new_re_refer_CTF, *new_im_refer_CTF, *re_ref, *im_ref, *pow_refer;
       float *B,*dev_sigma, *dev_x, *dev_y, *dev_phi, *dev_theta, *dev_psi, *sigma;
       float new_dev_sigma,new_dev_x, new_dev_y, new_dev_phi, new_dev_theta, new_dev_psi, new_sigma_phi, new_sigma_theta, new_sigma_psi;
       float *dev_sigma_phi, *dev_sigma_theta, *dev_sigma_psi,*new_sigma;
       float dev_sigma_change, st1, st2, st3, st4, st5, All_corr;
       float *temp_image1, *temp_image2, *temp_image3, *SANG, *A2;
float *demo, mind, maxd;
double total_corr_old[Numstack], total_corr[Numstack];
int *count, *count1, *count2,*count_total;


       Num_angles=((int)((2*max_ang1+1)/step_angle1)+1)*((int)((2*max_ang2+1)/step_angle2)+1)*((int)((2*max_ang3+1)/step_angle3)+1);   

       SANG=(float *)calloc(3, sizeof(float));
       temp_image1=(float *)calloc(nx*nx*2,sizeof(float));
       temp_image2=(float *)calloc(nx*nx*2,sizeof(float));
       temp_image3=(float *)calloc(nx/2,sizeof(float)); 
	  A2=(float *)calloc(nx*nx,sizeof(float)); 
         
 
       num=(int *)calloc(nx, sizeof(int));
       par=(float *)calloc((nx/2+20)*Nthread,sizeof(float));
       angles=(float *)calloc(3,sizeof(float));
       slice=(float *)calloc(nx*nx*nx*2,sizeof(float));
       normal=(float *)calloc(nx*nx*nx*Nthread,sizeof(float));
    normal1=(float *)calloc(nx*nx*nx*Nthread,sizeof(float));
    normal2=(float *)calloc(nx*nx*nx*Nthread,sizeof(float));


count=(int *)calloc(nx*nx*nx*Nthread,sizeof(int));
count1=(int *)calloc(nx*nx*nx*Nthread,sizeof(int));
count2=(int *)calloc(nx*nx*nx*Nthread,sizeof(int));

count_total=(int *)calloc(nx*nx*nx,sizeof(int));

       normal_CTF=(float *)calloc(nx*nx*nx*Nthread,sizeof(float));
       new_re_refer=(float *)calloc(nx*nx*nx*Nthread, sizeof(float));
       new_im_refer=(float *)calloc(nx*nx*nx*Nthread, sizeof(float));
  new_re_refer1=(float *)calloc(nx*nx*nx*Nthread, sizeof(float));
       new_im_refer1=(float *)calloc(nx*nx*nx*Nthread, sizeof(float));
  new_re_refer2=(float *)calloc(nx*nx*nx*Nthread, sizeof(float));
       new_im_refer2=(float *)calloc(nx*nx*nx*Nthread, sizeof(float));

       new_re_refer_CTF=(float *)calloc(nx*nx*nx*Nthread, sizeof(float));
       new_im_refer_CTF=(float *)calloc(nx*nx*nx*Nthread, sizeof(float));
       refer_CTF=(float *)calloc(nx*nx*nx, sizeof(float));

        
       pdf=(float *)calloc(nx*ny*Num_angles,sizeof(float));
       re=(float *)malloc(sizeof(float)*nx*ny*Max_num);  
       im=(float *)malloc(sizeof(float)*nx*ny*Max_num);  
       re_CTF=(float *)malloc(sizeof(float)*nx*ny*Max_num);  
       im_CTF=(float *)malloc(sizeof(float)*nx*ny*Max_num);  
       pow_image=(float *)malloc(sizeof(float)*nx/2*Max_num); 
        
       re_ref=(float *)malloc(sizeof(float)*nx*ny*Num_angles);
       im_ref=(float *)malloc(sizeof(float)*nx*ny*Num_angles);
       pow_refer=(float *)malloc(sizeof(float)*nx*Num_angles);
       B=(float *)calloc(nx*nx*2,sizeof(float));
       indx=(int *)malloc(sizeof(int)*nx*nx);
       indy=(int *)malloc(sizeof(int)*nx*nx);
                 
       dev_sigma=(float*)calloc(Numstack,sizeof(float));
       dev_x=(float *)calloc(Numstack,sizeof(float));
       dev_y=(float *)calloc(Numstack,sizeof(float));
       dev_phi=(float *)calloc(Numstack,sizeof(float));
       dev_theta=(float *)calloc(Numstack,sizeof(float));
       dev_psi=(float *)calloc(Numstack,sizeof(float));
       sigma=(float *)calloc(nx/2,sizeof(float));
       dev_sigma_phi=(float *)calloc(Numstack,sizeof(float));
       dev_sigma_theta=(float *)calloc(Numstack,sizeof(float));
       dev_sigma_psi=(float *)calloc(Numstack,sizeof(float));
       new_sigma=(float *)calloc(nx/2,sizeof(float));
      
/* 
       new_dev_sigma=(float *)calloc(Numstack,sizeof(float));
       new_dev_x=(float *)calloc(Numstack,sizeof(float));
       new_dev_y=(float *)calloc(Numstack,sizeof(float));
       new_dev_phi=(float *)calloc(Numstack,sizeof(float));
       new_dev_theta=(float *)calloc(Numstack,sizeof(float));
       new_dev_psi=(float *)calloc(Numstack,sizeof(float));
   
       new_sigma_phi=(float *)calloc(Numstack,sizeof(float));
       new_sigma_theta=(float *)calloc(Numstack,sizeof(float));
       new_sigma_psi=(float *)calloc(Numstack,sizeof(float));
*/

       filename1=(char *)calloc(200,sizeof(char));
       filename2=(char *)calloc(200,sizeof(char));    
    
      
      
//       i=0;

       int it = sizeof(float)*nx*ny;
       
        
     
       printf("Memory  allocation done.\n");   fflush(stdout);
     
       

       printf(": \n");
       printf("::  Loop   Stack   Dev_X  Dev_Y  Dev_Sigma   Dev_phi  Dev_Sigma_phi   Dev_theta  Dev_Sigma_Theta   Dev_psi  Dev_Sigma_psi\n");
       printf("::-----------------------------------------------------------------------------------------------------\n");
     
/*
                Loop=0; 
                mrcImage::mrcHeader *header2 = mrcImage::headerFromData(nx,ny,2,(char*)refer);
                char outputfile [50];
                sprintf(outputfile,"SCRATCH/ML_reference_%03d.mrc",Loop);  
                mrcImage(header2,(char*)refer,outputfile);
                printf("File %s written.\n",outputfile);
                fprintf(results,"# IMAGE: %s <Reference Map %03d>\n",outputfile,Loop);
                fflush(results);

 */            
	/*
	 
        for(i=0;i<Num_angles;i++)
	    angle[i]=min_angle+i*step_angle;  
	*/

        /*   Preallocate the array position used for caculating the translation probability   */

       for(i=0;i<nx/2;i++)
         for(j=0;j<ny;j++)
	      indx[j+i*ny]=i;
	    
       for(i=nx/2;i<nx;i++)
         for(j=0;j<ny;j++)
	      indx[j+i*ny]=-(nx-i);    
	
       for(i=0;i<nx;i++)
         for(j=0;j<ny/2;j++)
	      indy[j+i*ny]=j;
 
       for(i=0;i<nx;i++)
            for(j=ny/2;j<ny;j++)
	      indy[j+i*ny]=-(ny-j);
 
       
        /*  Initialize the parameters  */
       
       for(i=0;i<nx/2;i++)
         sigma[i]=1.0;
       
       for(sta=0;sta<Numstack;sta++)
       {          
             dev_x[sta]=0;  
             dev_y[sta]=0; 
             dev_sigma[sta]=5;   
       
	     dev_phi[sta]=0;
	     dev_sigma_phi[sta]=5;  

             dev_theta[sta]=0;
	     dev_sigma_theta[sta]=5; 

             dev_psi[sta]=0;
	     dev_sigma_psi[sta]=5;         
	}
 


        for(i=0;i<nx;i++)
          num[i]=0;

        for(i=0;i<nx;i++)
           for(j=0;j<ny;j++)
           {   
                m=(int)(sqrtf((i-nx/2)*(i-nx/2)*1.0+(j-ny/2)*(j-ny/2)*1.0));
            
                if(m>=rmax1 && m<=rmax2)    
                  num[m]++;
            }

    
        /*       ML iteration            */     

        dev_sigma_change=1.0; 

        Loop=1;
        num_refer=1;

        powrefer=0;
        for(k3=0;k3<nx;k3++)
          for(k4=0;k4<ny;k4++)
             powrefer+=powf(refer[k4+k3*ny+nx/2*nx*ny],2.0);
 
/*
        for(i=0;i<nx;i++)
          for(j=0;j<nx;j++)
            for(k=0;k<nx;k++)
             refer[k+i*nx+i*nx*nx]=refer[k+j*nx+i*nx*nx]*sqrt(1/powrefer);
*/ 

		 demo=(float *)calloc(nx*ny,sizeof(float));
		 

		    for(sta=0;sta<Numstack; sta++)
				total_corr[sta]=0;


    //    while((Loop<Iteration && (dev_sigma_change>Terminate_ML*Numstack )) || Loop<6) 
	   while(Loop<MaxLoop) 
        { 

All_corr=0.0;

               trans3D(nx,nx/2,refer);
               Symmetrize3D(nx,ny,nx,refer);


			trans3D(nx,nx/2, refer1);
			Symmetrize3D(nx,nx,nx,refer1);

			trans3D(nx,nx/2, refer2);
			Symmetrize3D(nx,nx,nx,refer2);
      //        mask3D(mask_radius,mask_radius, nx,ny,refer);
     
/*
	for(k=0;k<40;k++)
		for(i=0;i<nx;i++)
			for(j=0;j<nx;j++)
			 refer[k+j*nx+i*nx*nx]=0;


 
     for(k=nx;k>nx-40;k--)
		for(i=0;i<nx;i++)
			for(j=0;j<nx;j++)
			 refer[k+j*nx+i*nx*nx]=0;
*/





    
              if(Loop>1)
              {

				for(i=0;i<200;i++)
		   		filename1[i]='\0';
                 	strcpy(filename1,"./SCRATCH/3dmodela_");
                  	i=strlen(filename1);
                 	filename1[i]=Loop/10+'0';
                 	filename1[i+1]=Loop-Loop/10*10+'0';
                 	strcat(filename1,".dat");
                 	printf("Loop=%d   i=%d  rmax2=%d  %s  \n",Loop, i, rmax2, filename1);    
                         
                 	output[0]=fopen(filename1, "w");
                 	fwrite(refer, sizeof(float)*nx*nx*nx, 1, output[0]);
                 	fclose(output[0]);

 
              	 	for(i=0;i<200;i++)
		   		filename1[i]='\0';
                 	strcpy(filename1,"./SCRATCH/3dmodela1_");
                  	i=strlen(filename1);
                 	filename1[i]=Loop/10+'0';
                 	filename1[i+1]=Loop-Loop/10*10+'0';
                 	strcat(filename1,".dat");
                 	printf("Loop=%d   i=%d  rmax2=%d  %s  \n",Loop, i, rmax2, filename1);    
      
printf("REFER1=%f  %f %f \n", refer1[1234], refer1[4567], refer1[5678]);
                  
                 	output[0]=fopen(filename1, "w");
                 	fwrite(refer1, sizeof(float)*nx*nx*nx, 1, output[0]);
                 	fclose(output[0]);


				for(i=0;i<200;i++)
		   		filename1[i]='\0';
                 	strcpy(filename1,"./SCRATCH/3dmodela2_");
                  	i=strlen(filename1);
                 	filename1[i]=Loop/10+'0';
                 	filename1[i+1]=Loop-Loop/10*10+'0';
                 	strcat(filename1,".dat");
                 	printf("Loop=%d   i=%d  rmax2=%d  %s  \n",Loop, i, rmax2, filename1);    
                         
                 	output[0]=fopen(filename1, "w");
                 	fwrite(refer2, sizeof(float)*nx*nx*nx, 1, output[0]);
                 	fclose(output[0]);
      
printf("REFER2=%f  %f %f \n", refer2[1234], refer2[4567], refer2[5678]);

              }
 

               trans3D(nx,nx/2,refer); 


              if(Loop>1)
              {
              	 	for(i=0;i<200;i++)
		   		filename1[i]='\0';
                 	strcpy(filename1,"./SCRATCH/3dmodelb_");
                  	i=strlen(filename1);
                 	filename1[i]=Loop/10+'0';
                 	filename1[i+1]=Loop-Loop/10*10+'0';
                 	strcat(filename1,".dat");
                 	printf("Loop=%d   i=%d   rmax2=%d  %s  \n",Loop, i, rmax2, filename1);    
                         
                 	output[0]=fopen(filename1, "w");
	            //   fwrite(count_total, sizeof(float)*nx*nx*nx, 1, output[0]);
                 //	fwrite(demo, sizeof(float)*nx*nx, 1, output[0]);
 
				fprintf(output[0],"P2 %d %d \n  255 \n",nx,ny);
			
				for(i=0;i<nx;i++)
				{
					for(j=0;j<nx;j++)
						fprintf(output[0],"%d ",(int)demo[j+i*nx]);
					fprintf(output[0], "\n");
				}



                 	fclose(output[0]);
              }
 
	         powrefer=0;
              for(k3=0;k3<nx;k3++)
                for(k4=0;k4<ny;k4++)
                  	powrefer+=powf(refer[k4+k3*ny+nx/2*nx*ny],2.0);
 
              for(i=0;i<nx;i++)
                for(j=0;j<nx;j++)
                  for(k=0;k<nx;k++)
                       refer[k+i*nx+i*nx*nx]=refer[k+j*nx+i*nx*nx]*sqrt(1.0/powrefer);

              /*  FFT of 3D reference */
              for(i=0;i<nx;i++)
	          for(j=0;j<nx;j++)
	          	for(k=0;k<nx;k++)
	          	{   	in3[k+j*nx+i*nx*nx][0]=refer[k+j*nx+i*nx*nx]*powf(-1.0,i+j+k);
                      		in3[k+j*nx+i*nx*nx][1]=0.0;   
	          	}
	        
              p3=fftwf_plan_dft_3d(nx,nx,nx, in3,out3,FFTW_FORWARD,FFTW_ESTIMATE);
              fftwf_execute(p3);
              fftwf_destroy_plan(p3);  

              for(i=0;i<nx;i++)
	        for(j=0;j<ny;j++)
	          for(k=0;k<nx;k++)
	          {	slice[k+j*nx+i*nx*nx]=out3[k+j*nx+i*nx*nx][0];
                    slice[k+j*nx+i*nx*nx+nx*nx*nx]=out3[k+j*nx+i*nx*nx][1];   
	          }

for(i=0;i<nx;i++)
  for(j=0;j<nx;j++)
   {  	B[j+i*nx]=0.0;
    		B[j+i*nx+nx*nx]=0.0;
   } 
angles[0]=57.0; angles[1]=42.0; angles[2]=85.0;
extract2D(B, angles, nx,nx,nx,slice);

/*
for(i=nx/2-3; i<=nx/2+3; i++)
{  printf("\n");
for(j=nx/2-3; j<=nx/2+3; j++)
printf("%6.2f %6.2f   ",B[j+i*nx], B[j+i*nx+nx*nx]);
}

printf("\n\n");
*/



 

for(i=0;i<nx;i++)
for(j=0;j<nx;j++)
{	out2[j+i*nx][0]=B[j+i*nx];
	out2[j+i*nx][1]=B[j+i*nx+nx*nx];
}
for(i=0;i<nx;i++)
 for(j=0;j<nx;j++)
 {     phas=-2*pi*((j+nx/2)*nx/2+(i+nx/2)*nx/2)/nx;
       out2[j+i*nx][0]=B[j+i*nx]*cos(phas)-B[j+i*nx+nx*nx]*sin(phas);
       out2[j+i*nx][1]=B[j+i*nx]*sin(phas)+B[j+i*nx+nx*nx]*cos(phas);      
 }
p3=fftwf_plan_dft_2d(nx,nx,out2,in2,FFTW_BACKWARD,FFTW_ESTIMATE);
fftwf_execute(p3);
fftwf_destroy_plan(p3);
                            
for(i=0;i<nx;i++)
  for(j=0;j<nx;j++) 
    demo[j+i*nx]=in2[j+i*nx][0]*powf(-1.0,i+j); 

/*  
for(i=0;i<nx;i++)
   for(j=0;j<nx;j++)
	demo[j+i*nx]=sqrt(powf(B[j+i*nx],2.0)+powf(B[+i*nx+nx*nx],2.0));
*/
  
mask(realcell_x1_common,realcell_y1_common,nx,nx,demo);
maxd=-1.0e20; mind=-maxd;
for(i=0;i<nx;i++)
   for(j=0;j<nx;j++)
	if(demo[j+i*nx]>maxd) maxd=demo[j+i*nx];
	else if(demo[j+i*nx]<mind) mind=demo[j+i*nx];
for(i=0;i<nx;i++)
   for(j=0;j<nx;j++)
	 demo[j+i*nx]=(demo[j+i*nx]-mind)/(maxd-mind)*255;
	 




              /*initialize the references ( central slices ) and the parameters   */
              for(n=0;n<Nthread;n++)
	        	for(i=0;i<nx;i++)
	           for(j=0;j<nx;j++)
	            for(k=0;k<nx;k++)
	            {  
                        new_re_refer[k+j*nx+i*nx*nx+n*nx*nx*nx]=0.0;
                        new_im_refer[k+j*nx+i*nx*nx+n*nx*nx*nx]=0.0;
                        normal[k+j*nx+i*nx*nx+n*nx*nx*nx]=0.0; 
				    count[k+j*nx+i*nx*nx+n*nx*nx*nx]=0; 

				    new_re_refer1[k+j*nx+i*nx*nx+n*nx*nx*nx]=0.0;
                        new_im_refer1[k+j*nx+i*nx*nx+n*nx*nx*nx]=0.0;
                        normal1[k+j*nx+i*nx*nx+n*nx*nx*nx]=0.0; 
				    count1[k+j*nx+i*nx*nx+n*nx*nx*nx]=0; 

				    new_re_refer2[k+j*nx+i*nx*nx+n*nx*nx*nx]=0.0;
                        new_im_refer2[k+j*nx+i*nx*nx+n*nx*nx*nx]=0.0;
                        normal2[k+j*nx+i*nx*nx+n*nx*nx*nx]=0.0; 
				    count2[k+j*nx+i*nx*nx+n*nx*nx*nx]=0; 
				

                        new_re_refer_CTF[k+j*nx+i*nx*nx+n*nx*nx*nx]=0.0;
                        new_im_refer_CTF[k+j*nx+i*nx*nx+n*nx*nx*nx]=0.0;
                        normal_CTF[k+j*nx+i*nx*nx+n*nx*nx*nx]=0.0; 
	            }
 

	        /*  Initialize the parameters that will be summation over all the particles */
	     
             for(k3=0;k3<nx/2;k3++)
		      new_sigma[k3]=0.0; 
		 	 
 		
              Num_images=0;
       
              /*  Process stacks of particles */
             
              dev_sigma_change=0.0;


   
	         for(sta=0;sta<Numstack;sta++)
              {  

total_corr_old[sta]=total_corr[sta];
total_corr[sta]=0.0;  

 
                  new_dev_x=0;
	             new_dev_y=0; 
                  new_dev_sigma=0;
                  new_dev_phi=0.0;
                  new_sigma_phi=0.0;
		        new_dev_theta=0.0;
		        new_sigma_theta=0.0;
                  new_dev_psi=0.0;
                  new_sigma_psi=0.0; 


                  pthread_mutex_init(&lock1, NULL);
                  pthread_mutex_init(&lock2, NULL);
                  pthread_mutex_init(&lock3, NULL);
                  pthread_mutex_init(&lock4, NULL);
                  pthread_mutex_init(&lock5, NULL);
                  pthread_mutex_init(&lock6, NULL);
                  pthread_mutex_init(&lock7, NULL);


 
                  /*    Calculate the statistical parameters of translation */
                  k2=0;
		        for(ang1=-max_ang1;ang1<=max_ang1; ang1+=step_angle1)
              	    for(ang2=-max_ang2; ang2<=max_ang2; ang2+=step_angle2)
              	      for(ang3=-max_ang3;ang3<=max_ang3;ang3+=step_angle3) 
	     	      {                       
	               	 for(k3=0;k3<nx;k3++)
		     	   	   for(k4=0;k4<ny;k4++)
		             		pdf[k4+k3*ny+k2*nx*ny]=0.0;
	                                             
	                                              
		  	 	      for(k3=0;k3<nx;k3++)
                   	        for(k4=0;k4<ny;k4++)
                             if (powf((float)(indx[k4+k3*ny]-dev_x[sta]),Gau)+powf((float)(indy[k4+k3*ny]-dev_y[sta]),Gau)<=powf(2*shift+1,2.0))
 	              	   	   {   	i=indx[k4+k3*nx];
                               	j=indy[k4+k3*nx];
                                   
 	              	       		st1=powf((float)(indx[k4+k3*ny]-dev_x[sta]),Gau)+powf((float)(indy[k4+k3*ny]-dev_y[sta]),Gau);
			       			st2=Gau*powf(dev_sigma[sta],Gau);
  	                       		st3=-st1/(st2+1.0e-20);

			       			st1=powf((float)(ang1-dev_phi[sta]),Gau);
			       			st2=Gau*powf(dev_sigma_phi[sta],Gau);
			       			st3=st3-st1/(st2+1.0e-20);

			       			st1=powf((float)(ang2-dev_theta[sta]),Gau);
			       			st2=Gau*powf(dev_sigma_theta[sta],Gau);
			       			st3=st3-st1/(st2+1.0e-20);
			  
			       			st1=powf((float)(ang3-dev_psi[sta]),Gau);
			       			st2=Gau*powf(dev_sigma_psi[sta],Gau);
			       			st3=st3-st1/(st2+1.0e-20);
			                 
                              	st5=powf(dev_sigma[sta],Gau)*dev_sigma_phi[sta]*dev_sigma_theta[sta]*dev_sigma_psi[sta];
		   	       			st5=1.0/(powf(sqrtf(2*pi),5.0)*st5+1.0e-20);	
		   			 		 		  			 
	             	       		pdf[k4+k3*ny+k2*nx*ny]=st5*exp(st3);     
	         			                            
		           	   }
                           	else pdf[k4+k3*ny+k2*nx*ny]=0.0;	

                         	k2++; 		   
		      }
 		
                       
                  for(i=0;i<200;i++)
                     filename1[i]='\0';
     
                  j=0; 
                  while(dirfilename[j+sta*200]!='\n')  
                  {      filename1[j]=dirfilename[j+sta*200];
              	         j++;  
                  }
                  filename1[j]='/';
                  strcpy(filename2, filename1);
                  strcat(filename1,"stack_whit.binary"); 
                  input[0]=fopen(filename1,"r");
                  if(input[0]==NULL) 
                  {
                     	printf("\n stack_whit.binary does not exis \n  run 2dx_ML_stack.exe first \n");
                     	exit(0);
                  }  
      
      
                  strcat(filename2,"stack_ctf.binary"); 
                  input[1]=fopen(filename2,"r");
                  if(input[1]==NULL) 
                  {
                      	printf("\n stack_ctf.binary does not exis \n  run 2dx_ML_stack.exe first \n");
                      	exit(0);
                  }  
      

                  //   Extract different projections of  the reference, normalize the projections   
	           
                  fread(SANG, sizeof(float)*3, 1, input[0]);
                  

                  k2=0; 
              	   for(ang1=-max_ang1;ang1<=max_ang1; ang1+=step_angle1)
              	     for(ang2=-max_ang2; ang2<=max_ang2; ang2+=step_angle2)
              	     	for(ang3=-max_ang3;ang3<=max_ang3;ang3+=step_angle3)
              	      	{   
	                		angles[0]=ang1+SANG[0];
	                  		angles[1]=ang2+SANG[1];
	                  		angles[2]=ang3+SANG[2];
/*	                     
	                  		for(i=0;i<nx;i++)
           		           for(j=0;j<nx;j++)
           		   	  	 {  	B[j+i*nx]=0.0;
            		      		B[j+i*nx+nx*nx]=0.0;
          		           }  
*/	                 
	                  		extract2D(B, angles, nx,nx,nx,slice);
 
 
						//  Mask the projections in real space
				//		B[nx/2+nx/2*nx]=0;
                   //         B[nx/2+nx/2*nx+nx*nx]=0;

						for(i=0;i<nx;i++)
           		   		   for(j=0;j<nx;j++)
           		   		   {     phas=-2*pi*((j+nx/2)*nx/2+(i+nx/2)*nx/2)/nx;
           		                   out2[j+i*nx][0]=B[j+i*nx]*cos(phas)-B[j+i*nx+nx*nx]*sin(phas);
            		          	    out2[j+i*nx][1]=B[j+i*nx]*sin(phas)+B[j+i*nx+nx*nx]*cos(phas);      
          		             }
                  
                            
                         	p3=fftwf_plan_dft_2d(nx,nx,out2,in2,FFTW_BACKWARD,FFTW_ESTIMATE);
                         	fftwf_execute(p3);
                         	fftwf_destroy_plan(p3);
                            
                         	for(i=0;i<nx;i++)
           		    		   for(j=0;j<nx;j++) 
           		              A2[j+i*nx]=in2[j+i*nx][0]*powf(-1.0,i+j); 
                     
                         	mask(realcell_x1_common,realcell_y1_common,nx,nx,A2);

                             
                         	for(i=0;i<nx;i++)
           		     	for(j=0;j<nx;j++)
           		     	{        
           		          	in2[j+i*nx][0]=A2[j+i*nx]*powf(-1,i+j);
            		          	in2[j+i*nx][1]=0;      
          		     	}    
                         	p3=fftwf_plan_dft_2d(nx,nx,in2,out2,FFTW_FORWARD,FFTW_ESTIMATE);
                         	fftwf_execute(p3);
                         	fftwf_destroy_plan(p3); 
                             
                         	for(i=0;i<nx;i++)
                            		for(j=0;j<nx;j++)
                            		{    phas=-2*pi*((i+nx/2)*nx/2+(j+nx/2)*nx/2)/nx;
                                   	B[j+i*nx]=out2[j+i*nx][0]*cos(phas)-out2[j+i*nx][1]*sin(phas);
                                   	B[j+i*nx+nx*nx]=out2[j+i*nx][0]*sin(phas)+out2[j+i*nx][1]*cos(phas);
                            		}
                         	B[nx/2+nx/2*nx]=0;
                        		B[nx/2+nx/2*nx+nx*nx]=0;






                          	pow_RT=0;
		          		for(i=0;i<nx;i++)
	                    	   for(j=0;j<ny;j++)
	                    	   {   
	                       			re_ref[j+i*nx+k2*nx*nx]=B[j+i*nx];
	                       			im_ref[j+i*nx+k2*nx*nx]=B[j+i*nx+nx*nx];
	                           
	                       			pow_RT+=powf(re_ref[j+i*nx+k2*nx*nx],2.0)+powf(im_ref[j+i*nx+k2*nx*nx],2.0);
        
                                  }
     
                              for(i=0;i<nx;i++)
	                            for(j=0;j<ny;j++)
	                            {       
                                		re_ref[j+i*nx+k2*nx*nx]=re_ref[j+i*nx+k2*nx*nx]*sqrt(powrefer/pow_RT);
	                        			im_ref[j+i*nx+k2*nx*nx]=im_ref[j+i*nx+k2*nx*nx]*sqrt(powrefer/pow_RT);
                             	   }
                             
                              k2++;             
                          }   

 

                  //   calculate std of projections (references)  
              
                  k2=0;
                  for(ang1=-max_ang1;ang1<=max_ang1; ang1+=step_angle1)
              	    for(ang2=-max_ang2; ang2<=max_ang2; ang2+=step_angle2)
              	      for(ang3=-max_ang3;ang3<=max_ang3;ang3+=step_angle3) 
              	      {  
              	         	for(m=0; m<nx/2;  m++)
                         	pow_refer[k2+m*Num_angles]=0;
 
                         for(i=0; i<nx; i++)
	                 	   for(j=0; j<ny; j++)
                            {    m=(int)(sqrtf((i-nx/2)*(i-nx/2)*1.0+(j-ny/2)*(j-ny/2)*1.0));                 			  
                         	   if(m>=rmax1 && m<=rmax2 )
                         	  	 pow_refer[k2+m*Num_angles]+=(powf(re_ref[j+i*ny+k2*nx*nx],2.0)+powf(im_ref[j+i*ny+k2*nx*nx],2.0));
                             }                              
                         k2++;     
                      }   
    
                  fread(temp_image1, sizeof(float)*nx*ny*2, 1, input[0]);
                  fread(temp_image3, sizeof(float)*nx/2, 1, input[0]);
                  fread(temp_image2, sizeof(float)*nx*ny*2, 1, input[1]);
  

                  num_temp=Max_num;
                  num_images_stack=0;
                        
                  if(feof(input[0])!=0 && feof(input[1])!=0)
                  {   	printf("there are not particles extracted from the files \n");
                      	fflush(stdout);
                      	break;
                  } 
		  	   else 
                  while(num_temp==Max_num)
                  {  
             
                       for(n=0;n<Nthread;n++)
                         for(j=0;j<(nx/2+20);j++)
                            	par[j+n*(nx/2+20)]=0;    
  
                       /*  one iteration processes Max_num images */
                       num_temp=0;
		       	   while(feof(input[0])==0 && num_temp<Max_num)   
                       {    
                          	for(i=0;i<nx;i++)
                            		for(j=0;j<ny;j++)
                            		{   re[j+i*ny+num_temp*nx*ny]=temp_image1[j+i*ny];
                                		im[j+i*ny+num_temp*nx*ny]=temp_image1[j+i*ny+nx*ny];      
	
                                		re_CTF[j+i*ny+num_temp*nx*ny]=temp_image2[j+i*ny];
                                		im_CTF[j+i*ny+num_temp*nx*ny]=temp_image2[j+i*ny+nx*ny];
                            		}

                           	for(i=0;i<nx/2;i++)
                           	     pow_image[i+num_temp*nx/2]=temp_image3[i];
                                            
                           	num_temp++;
                           	fread(temp_image1, sizeof(float)*nx*ny*2, 1, input[0]);
                           	fread(temp_image3, sizeof(float)*nx/2, 1, input[0]);
                           	fread(temp_image2, sizeof(float)*nx*ny*2, 1, input[1]);
                       }                  
                        	 
		       	  Num_images+=num_temp;
		            num_images_stack+=num_temp;
				
		       	   if(num_temp<Max_num)
                       {    	fclose(input[0]);
                             	fclose(input[1]);
                       }
  
                       for(n=0;n<Nthread;n++)
	                  {	av[n].numLoop=Loop;
	                    	av[n].rmax1=rmax1;
	                    	av[n].rmax2=rmax2;
	                    	av[n].shift=shift;
	                    	av[n].dim=nx; 
	                    	av[n].num_angles=Num_angles;  
	           	    		av[n].start=num_temp/Nthread*n;
	            	    		av[n].end=num_temp/Nthread*(n+1);
	            			
	            	    		av[n].pdf=pdf;
	            	    		av[n].dev_x=dev_x[sta];
	            	    		av[n].dev_y=dev_y[sta];
	            	    		av[n].dev_phi=dev_phi[sta];
	            	    		av[n].dev_theta=dev_theta[sta];
	            	    		av[n].dev_psi=dev_psi[sta];
	            	    		av[n].re_reference=re_ref;
	            	    		av[n].im_reference=im_ref;
	            	    		av[n].pow_reference=pow_refer;
	            	    		av[n].re_samp=re;
	            	    		av[n].im_samp=im;
                         	av[n].re_samp_CTF=re_CTF;
	            	    		av[n].im_samp_CTF=im_CTF;
	            	    		av[n].pow_samp=pow_image;
	            	    		av[n].sigma=sigma;
	            	    		av[n].angle=SANG;
	            	    		av[n].new_re_refer=&new_re_refer[n*nx*nx*nx];
	            	    		av[n].new_im_refer=&new_im_refer[n*nx*nx*nx];

	av[n].new_re_refer1=&new_re_refer1[n*nx*nx*nx];
	av[n].new_im_refer1=&new_im_refer1[n*nx*nx*nx];
	av[n].new_re_refer2=&new_re_refer2[n*nx*nx*nx];
	av[n].new_im_refer2=&new_im_refer2[n*nx*nx*nx];

                            	av[n].new_re_refer_CTF=&new_re_refer_CTF[n*nx*nx*nx];
	            	    		av[n].new_im_refer_CTF=&new_im_refer_CTF[n*nx*nx*nx];
	            	    		av[n].normal=&normal[n*nx*nx*nx];
 
	av[n].normal1=&normal1[n*nx*nx*nx];
	av[n].normal2=&normal2[n*nx*nx*nx];


	av[n].count=&count[n*nx*nx*nx];
	av[n].count1=&count1[n*nx*nx*nx];
	av[n].count2=&count2[n*nx*nx*nx];


                            	av[n].normal_CTF=&normal_CTF[n*nx*nx*nx];
	            	    		av[n].new_par=&par[n*(nx/2+20)];	            
	          	
                           	 error=pthread_create(&tid[n], thAttr, CCthread, (void*)&av[n]);
 
	                }   // end of threading
	                
 

            
	                /*   wait for the ending of each thread  */
                       for(n=0;n<Nthread;n++)
                           error=pthread_join(tid[n],NULL);
                        


                       for(n=0;n<Nthread;n++)
	               	{	  
                 	  		new_dev_sigma+=*(av[n].new_par);
                	  		new_dev_x+=*(av[n].new_par+1);
                	  		new_dev_y+=*(av[n].new_par+2);
                	  		new_dev_phi+=*(av[n].new_par+3);
                	  		new_dev_theta+=*(av[n].new_par+4);
                	  		new_dev_psi+=*(av[n].new_par+5);
                	  		new_sigma_phi+=*(av[n].new_par+6);
                	  		new_sigma_theta+=*(av[n].new_par+7);
                 	  		new_sigma_psi+=*(av[n].new_par+8);
                		 
                	     	new_sigma[0]+=*(av[n].new_par+9);  
						total_corr[sta]+=*(av[n].new_par+10); 
              	       }   
 

                  }// end of **  while ** iterations over images in one stack
    	   
//printf("33333333333  in thread \n");
//fflush(stdout);

       
               //         pthread_mutex_lock(&lock1);  
                   

           
                  pthread_mutex_destroy(&lock1); 
                  pthread_mutex_destroy(&lock2); 
                  pthread_mutex_destroy(&lock3); 
                  pthread_mutex_destroy(&lock4); 
                  pthread_mutex_destroy(&lock5); 
                  pthread_mutex_destroy(&lock6); 
                  pthread_mutex_destroy(&lock7);         
   
	 
    	          
    	           
		  dev_sigma_change+=fabs(dev_sigma[sta]-powf(new_dev_sigma/(Gau*num_images_stack), 1.0/Gau));
	          //       dev_sigma_theta_change+=fabs(dev_sigma_theta[sta]-powf(new_sigma_theta[sta]/(num_images_stack), 1.0/Gau));
    	          
    	          
    	         //   sigma[sta]=sqrt(new_sigma[sta]/(num_images_stack*nx*ny));	 
	          dev_sigma[sta]=powf(new_dev_sigma/(Gau*num_images_stack), 1.0/Gau);		 
		  dev_x[sta]=new_dev_x/num_images_stack;
	          dev_y[sta]=new_dev_y/num_images_stack;	
	         
		  dev_phi[sta]=new_dev_theta/num_images_stack;
		  dev_sigma_phi[sta]=powf(new_sigma_theta/(num_images_stack), 1.0/Gau);
		 
                  dev_theta[sta]=new_dev_theta/num_images_stack;
		  dev_sigma_theta[sta]=powf(new_sigma_theta/(num_images_stack), 1.0/Gau);

                  dev_psi[sta]=new_dev_theta/num_images_stack;
		  dev_sigma_psi[sta]=powf(new_sigma_theta/(num_images_stack), 1.0/Gau);

printf("\n ANGLES=%f %f %f \n", SANG[0],SANG[1],SANG[2]);
    	  
    	  
    	          printf("::  Loop   Stack   Dev_X  Dev_Y  Dev_Sigma   Dev_phi  Dev_Sigma_phi   Dev_theta  Dev_Sigma_Theta   Dev_psi  Dev_Sigma_psi\n");
 
/*       
    	          if(sta==0)
    	          {  	printf("::%5d  %5d  %5d %10.3f %10.3f %10.3f %10.3f  ",Loop,  sta, num_images_stack,sigma[0],dev_x[sta],dev_y[sta],dev_sigma[sta]);
	             	printf("%10.3f %10.3f\n",dev_theta[sta],dev_sigma_theta[sta]); 
                     	fflush(stdout);
	          }
	          else
	          {  	printf("::%12d %5d  %10.3f %10.3f %10.3f %10.3f  ",  sta, num_images_stack, sigma[0],dev_x[sta],dev_y[sta],dev_sigma[sta]);
	            	printf("%10.3f %10.3f\n",dev_theta[sta],dev_sigma_theta[sta]); 
                     	fflush(stdout);
    	          }
*/



		     if(sta==0)
    	          {  	printf("::%5d  %5d  %5d  %15.3e  %15.3e ",Loop,  sta, num_images_stack, total_corr_old[sta], total_corr[sta]); 
                     	fflush(stdout);
	          }
	          else
	          {  	printf("::%12d %5d  %15.3e  %15.3e  ",  sta, num_images_stack,total_corr_old[sta], total_corr[sta]);
                     	fflush(stdout);
    	          }

All_corr+=total_corr[sta];

   
              }   // end of ** for ** iteration over the stacks
	 
 	printf("\n End of iterations over the stacks  the total cross cross correlation is %e \n", All_corr);
 	fflush(stdout);
        
               		
              /*  transform the references back to the real space     */
              for(i=0;i<nx;i++)
                for(j=0;j<nx;j++)
                  for(k=0;k<nx;k++) 
                  {   	st1=0.0;
                      	st2=0.0;
                      	st3=0.0;
					st4=0.0;

                      	for(n=0;n<Nthread;n++)
                      	{   st1+=new_re_refer[k+j*nx+i*nx*nx+n*nx*nx*nx];
                           	st2+=new_im_refer[k+j*nx+i*nx*nx+n*nx*nx*nx];
                           	st3+=normal[k+j*nx+i*nx*nx+n*nx*nx*nx];
						st4+=count[k+j*nx+i*nx*nx+n*nx*nx*nx];
                      	} 


					count_total[k+j*nx+i*nx*nx]=(int)(st4);
                      	if(st3>0.0)
                      	{ 
               	         	in3[k+j*nx+i*nx*nx][0]=st1/st3; //*exp(-sqrt(powf(i-nx/2, 2.0)+powf(j-nx/2, 2.0)+powf(k-nx/2,2.0))/(nx/4));  
                         	in3[k+j*nx+i*nx*nx][1]=st2/st3; //*exp(-sqrt(powf(i-nx/2, 2.0)+powf(j-nx/2, 2.0)+powf(k-nx/2,2.0))/(nx/4));      
                      	}
                      	else
                      	{
                           	in3[k+j*nx+i*nx*nx][0]=0.0;
                			in3[k+j*nx+i*nx*nx][1]=0.0;
                      	}
                  }
               p3=fftwf_plan_dft_3d(nx,nx,nx, in3,out3,FFTW_BACKWARD,FFTW_ESTIMATE);
               fftwf_execute(p3);
               fftwf_destroy_plan(p3);
    
         
                for(i=0;i<nx;i++)
                    for(j=0;j<nx;j++) 
                       for(k=0;k<nx;k++)
                           refer[k+j*nx+i*nx*nx]=out3[k+j*nx+i*nx*nx][0]*powf(-1.0,i+j+k);	    

 


			     		
              /*  transform the references back to the real space     */
 
              for(i=0;i<nx;i++)
                for(j=0;j<nx;j++)
                  for(k=0;k<nx;k++) 
                  {   	st1=0.0;
                      	st2=0.0;
                      	st3=0.0;
					st4=0.0;

                      	for(n=0;n<Nthread;n++)
                      	{   st1+=new_re_refer1[k+j*nx+i*nx*nx+n*nx*nx*nx];
                           	st2+=new_im_refer1[k+j*nx+i*nx*nx+n*nx*nx*nx];
                           	st3+=normal1[k+j*nx+i*nx*nx+n*nx*nx*nx];
						st4+=count1[k+j*nx+i*nx*nx+n*nx*nx*nx];
                      	} 


					count_total[k+j*nx+i*nx*nx]=(int)(st4);
                      	if(st3>0.0)
                      	{ 
               	         	in3[k+j*nx+i*nx*nx][0]=st1/st3; //*exp(-sqrt(powf(i-nx/2, 2.0)+powf(j-nx/2, 2.0)+powf(k-nx/2,2.0))/(nx/4));  
                         	in3[k+j*nx+i*nx*nx][1]=st2/st3; //*exp(-sqrt(powf(i-nx/2, 2.0)+powf(j-nx/2, 2.0)+powf(k-nx/2,2.0))/(nx/4));      
                      	}
                      	else
                      	{
                           	in3[k+j*nx+i*nx*nx][0]=0.0;
                			in3[k+j*nx+i*nx*nx][1]=0.0;
                      	}
                  }
               p3=fftwf_plan_dft_3d(nx,nx,nx, in3,out3,FFTW_BACKWARD,FFTW_ESTIMATE);
               fftwf_execute(p3);
               fftwf_destroy_plan(p3);
    
         
                for(i=0;i<nx;i++)
                    for(j=0;j<nx;j++) 
                       for(k=0;k<nx;k++)
                           refer1[k+j*nx+i*nx*nx]=out3[k+j*nx+i*nx*nx][0]*powf(-1.0,i+j+k);	    




     		
              /*  transform the references back to the real space     */
              for(i=0;i<nx;i++)
                for(j=0;j<nx;j++)
                  for(k=0;k<nx;k++) 
                  {   	st1=0.0;
                      	st2=0.0;
                      	st3=0.0;
					st4=0.0;

                      	for(n=0;n<Nthread;n++)
                      	{   st1+=new_re_refer2[k+j*nx+i*nx*nx+n*nx*nx*nx];
                           	st2+=new_im_refer2[k+j*nx+i*nx*nx+n*nx*nx*nx];
                           	st3+=normal2[k+j*nx+i*nx*nx+n*nx*nx*nx];
						st4+=count2[k+j*nx+i*nx*nx+n*nx*nx*nx];
                      	} 


					count_total[k+j*nx+i*nx*nx]=(int)(st4);
                      	if(st3>0.0)
                      	{ 
               	         	in3[k+j*nx+i*nx*nx][0]=st1/st3; //*exp(-sqrt(powf(i-nx/2, 2.0)+powf(j-nx/2, 2.0)+powf(k-nx/2,2.0))/(nx/4));  
                         	in3[k+j*nx+i*nx*nx][1]=st2/st3; //*exp(-sqrt(powf(i-nx/2, 2.0)+powf(j-nx/2, 2.0)+powf(k-nx/2,2.0))/(nx/4));      
                      	}
                      	else
                      	{
                           	in3[k+j*nx+i*nx*nx][0]=0.0;
                			in3[k+j*nx+i*nx*nx][1]=0.0;
                      	}
                  }
               p3=fftwf_plan_dft_3d(nx,nx,nx, in3,out3,FFTW_BACKWARD,FFTW_ESTIMATE);
               fftwf_execute(p3);
               fftwf_destroy_plan(p3);
    
         
                for(i=0;i<nx;i++)
                    for(j=0;j<nx;j++) 
                       for(k=0;k<nx;k++)
                           refer2[k+j*nx+i*nx*nx]=out3[k+j*nx+i*nx*nx][0]*powf(-1.0,i+j+k);	    
 

 
//                trans3D(nx,nx/2,refer); 
//                mask3D(mask_radius,mask_radius, nx,ny,refer);  





                /*   Apply symmetry if applicable   */
//                Symmetrize3D(nx,ny,nx,refer);

 
                
    
                k=0;	   
                for(m=0; m<nx/2; m++)
                if(num[m]>0)
                      k+=num[m];

                sigma[0]=sqrtf(new_sigma[0]/(Num_images*k));	

printf("444444\n");
fflush(stdout);


                 /*  transform the CTF corrected references back to the real space  
                 for(i=0;i<nx;i++)
                   for(j=0;j<nx;j++)
                      for(k=0;k<nx;k++) 
                      {     st1=0;
                            st2=0;
                            st3=0;
                            for(n=0;n<Nthread;n++)
                            {   st1+=new_re_refer_CTF[k+j*nx+i*nx*nx+n*nx*nx*nx];
                                st2+=new_im_refer_CTF[k+j*nx+i*nx*nx+n*nx*nx*nx];
                                st3+=normal_CTF[k+j*nx+i*nx*nx+n*nx*nx*nx];
                            } 
                   	    if(st3>0)
                   	    { 
               			in3[k+j*nx+i*nx*nx][0]=st1/st3*exp(-sqrt(powf(i-nx/2, 2.0)+powf(j-nx/2, 2.0)+powf(k-nx/2,2.0))/(nx/2));  
                		in3[k+j*nx+i*nx*nx][1]=st2/st3*exp(-sqrt(powf(i-nx/2, 2.0)+powf(j-nx/2, 2.0)+powf(k-nx/2,2.0))/(nx/2));      
                   	    }
                   	    else
                  	    {
                        	in3[k+j*nx+i*nx*nx][0]=0;
                		in3[k+j*nx+i*nx*nx][1]=0;
                    	    }
              
                       }
                   p3=fftwf_plan_dft_3d(nx,nx,nx, in3,out3,FFTW_BACKWARD,FFTW_ESTIMATE);
                   fftwf_execute(p3);
                   fftwf_destroy_plan(p3);
    
         
                   for(i=0;i<nx;i++)
                    for(j=0;j<nx;j++) 
                     for(k=0;k<nx;k++)
                      refer_CTF[k+j*nx+i*nx*nx]=out3[k+j*nx+i*nx*nx][0]*powf(-1.0,i+j+k);	
                */
         
                /* 

                mrcImage::mrcHeader *header2 = mrcImage::headerFromData(nx,ny,2,(char*)temp_image);
                char outputfile [50];
                sprintf(outputfile,"SCRATCH/ML_reference_%03d.mrc",Loop);
                mrcImage(header2,(char*)temp_image,outputfile); 
                printf("File %s written.\n",outputfile);
                fprintf(results,"# IMAGE: %s <Reference Map %03d>\n",outputfile,Loop);
            
		for(i=0;i<nx;i++)
		   for(j=0;j<ny;j++)
		     Image_refer[j+i*ny+Loop*nx*ny]=refer[j+i*ny]; 
		     
	        mask(mask_radius,mask_radius,nx,ny,refer); 

                // printf("<<@evaluate>>\n");
                fflush(results);
                fflush(stdout);
                */
		     
	        Loop++;
	        num_refer++;
  
        }	//  end of iteration of Loops	 
	


/*  HIO refine the 3D volume
  
	for(i=0;i<nx;i++)
	 for(j=0;j<nx;j++)
	   for(k=0;k<nx;k++)
		{	 out3[k+j*nx+i*nx*nx][0]= in3[k+j*nx+i*nx*nx][0];
			 out3[k+j*nx+i*nx*nx][1]= in3[k+j*nx+i*nx*nx][1];
		}
  
      p3=fftwf_plan_dft_3d(nx,nx,nx, out3,out3,FFTW_BACKWARD,FFTW_ESTIMATE);
      fftwf_execute(p3);
      fftwf_destroy_plan(p3);
    
         
      for(i=0;i<nx;i++)
           for(j=0;j<nx;j++) 
              for(k=0;k<nx;k++)
                 refer[k+j*nx+i*nx*nx]=out3[k+j*nx+i*nx*nx][0]*powf(-1.0,i+j+k)/sqrt(nx*nx*nx);	    


	trans3D(nx,nx/2,refer);
     Symmetrize3D(nx,ny,nx,refer);

	for(i=0;i<200;i++)
		  filename1[i]='\0';
   	strcpy(filename1,"./SCRATCH/3dmodela_HIO.dat");
                  
     printf("HIO started   \n" );    
                         
     output[0]=fopen(filename1, "w");
     fwrite(refer, sizeof(float)*nx*nx*nx, 1, output[0]);
     fclose(output[0]);

	//  get the FFT of centered object
	for(i=0;i<nx;i++)
		for(j=0; j<nx; j++)
			for(k=0;k<nx;k++)
			{	in3[k+j*nx+i*nx*nx][0]=refer[k+j*nx+i*nx*nx]*powf(-1.0,i+j+k)/sqrt(nx*nx*nx);
				in3[k+j*nx+i*nx*nx][1]=0;
			}
 
	 p3=fftwf_plan_dft_3d(nx,nx,nx, in3,in3,FFTW_FORWARD,FFTW_ESTIMATE);
      fftwf_execute(p3);
      fftwf_destroy_plan(p3);












//  initialize the mssing FFT components using random values

float max1=0, max2=0;
	for(i=0;i<nx;i++)
	 for(j=0;j<nx;j++)
	   for(k=0;k<nx;k++)
	if(powf(in3[k+j*nx+i*nx*nx][0],2.0)+powf(in3[k+j*nx+i*nx*nx][1],2.0)<1.0e-4 &&  powf(i-nx/2,2.0)+powf(j-nx/2,2.0)+powf(k-nx/2,2.0)<rmax2*rmax2*0.49)
		{	 out3[k+j*nx+i*nx*nx][0]=(float)random()/RAND_MAX/100;
			 out3[k+j*nx+i*nx*nx][1]=(float)random()/RAND_MAX/100;

if(powf(out3[k+j*nx+i*nx*nx][0],2.0)+powf( out3[k+j*nx+i*nx*nx][1],2.0)>max1)
max1=powf(out3[k+j*nx+i*nx*nx][0],2.0)+powf( out3[k+j*nx+i*nx*nx][1],2.0);

		}
		else
		{	 out3[k+j*nx+i*nx*nx][0]= in3[k+j*nx+i*nx*nx][0];
			 out3[k+j*nx+i*nx*nx][1]= in3[k+j*nx+i*nx*nx][1];

if(powf(out3[k+j*nx+i*nx*nx][0],2.0)+powf( out3[k+j*nx+i*nx*nx][1],2.0)>max2)
max2=powf(out3[k+j*nx+i*nx*nx][0],2.0)+powf( out3[k+j*nx+i*nx*nx][1],2.0);
		}
	

printf("max1=%f  max2=%f \n",max1,max2);
	 

      p3=fftwf_plan_dft_3d(nx,nx,nx, out3,out3,FFTW_BACKWARD,FFTW_ESTIMATE);
      fftwf_execute(p3);
      fftwf_destroy_plan(p3);
    
         
      for(i=0;i<nx;i++)
           for(j=0;j<nx;j++) 
              for(k=0;k<nx;k++)
                 refer[k+j*nx+i*nx*nx]=out3[k+j*nx+i*nx*nx][0]*powf(-1.0,i+j+k)/sqrt(nx*nx*nx);	    
 
//     Symmetrize3D(nx,ny,nx,refer);

	for(i=0;i<200;i++)
		  filename1[i]='\0';
   	strcpy(filename1,"./SCRATCH/3dmodela_HIO1.dat");
                  
     printf("HIO started   \n" );    
                         
     output[0]=fopen(filename1, "w");
     fwrite(refer, sizeof(float)*nx*nx*nx, 1, output[0]);
     fclose(output[0]);


      
	for(i=0;i<30;i++)
	{
		 HIO(nx, in3, refer);
//		 Symmetrize3D(nx,ny,nx,refer);
	}


	for(i=0;i<200;i++)
		  filename1[i]='\0';
   	strcpy(filename1,"./SCRATCH/3dmodela_HIO2.dat");
                  
     printf("HIO finished    \n" );    
                         
     output[0]=fopen(filename1, "w");
     fwrite(refer, sizeof(float)*nx*nx*nx, 1, output[0]);
     fclose(output[0]);




*/








        if(Loop>=Iteration)
          printf(":Iteration maximum of %d reached.\n",Iteration);
    //    if(dev_sigma_change<=Terminate_ML && dev_sigma_theta_change<=Terminate_ML )
    //      printf(":ML termination due to convergence (dev-change below threshold of %f).\n",Terminate_ML);
	
        printf(":: \n");


 
  
 
        free(num); 
        free(par);
        free(angles);
        free(slice);
        free(normal);
        free(normal_CTF);
        free(new_re_refer);
        free(new_im_refer);
        free(new_re_refer_CTF);
        free(new_im_refer_CTF);
        free(refer_CTF);

        
        free(pdf);
        free(re);  
        free(im);  
        free(re_CTF);  
        free(im_CTF);  
        free(pow_image); 
        
        free(re_ref);
        free(im_ref);
        free(pow_refer);
        free(B);
        free(indx);
        free(indy);
                 
        free(dev_sigma);
        free(dev_x);
        free(dev_y);
        free(dev_phi);
        free(dev_theta);
        free(dev_psi);
        free(sigma);
        free(dev_sigma_phi);
        free(dev_sigma_theta);
        free(dev_sigma_psi);
        free(new_sigma);
/*
        free(new_dev_sigma);
        free(new_dev_x);
        free(new_dev_y);
        free(new_dev_phi);
        free(new_dev_theta);
        free(new_dev_psi);
      
        free(new_sigma_phi);
        free(new_sigma_theta);
        free(new_sigma_psi);
*/

        free(filename1);
        free(filename2);     
 
	 fftwf_free(out2);
     fftwf_free(in2);

	fftwf_free(out3);
     fftwf_free(in3);  
 
 

 
  }			     
	 

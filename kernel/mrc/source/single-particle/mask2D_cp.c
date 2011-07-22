/*    Mask the particles  */
#define pi 3.1415926
void mask(int nx, int ny, int sx, int sy,  float *refer) 
{   
      int i,j, m,n,k;
      float mean ;
      float edge, r,r0,r1,devi;
     
 
     
      r0=(nx+ny)/4-4;
      r1=(nx+ny)/4-8;

      
      mean=0.0;
      int num=0;
      for(i=0;i<sx;i++)
       for(j=0;j<sy;j++)
       {  	 r=sqrtf(powf((float)(i-sx/2),2.0)+powf((float)(j-sy/2),2.0));
           	 if(r<=r0)
            	{	 mean+=refer[j+i*sy];  num++; }
        }
     
     mean/=num;


     for(i=0;i<sx;i++)
       for(j=0;j<sy;j++)
       {    r=sqrtf(powf((float)(i-sx/2),2.0)+powf((float)(j-sy/2),2.0));
             if(r<=r0)
	     {		refer[j+i*sy]-=mean;
             		devi+=powf(refer[j+i*sy],2.0);
	     }	
	}

      devi=sqrt(devi); 	

	for(i=0;i<sx;i++)
        for(j=0;j<sy;j++)
       {    	r=sqrtf(powf((float)(i-sx/2),2.0)+powf((float)(j-sy/2),2.0));
             	if(r<=r0)
	     		refer[j+i*sy]/=devi; 
		else      refer[j+i*sy]=0;     		 
	}

     for(i=0;i<sx;i++)
       for(j=0;j<sy;j++)
       {    r=sqrtf(powf((float)(i-sx/2),2.0)+powf((float)(j-sy/2),2.0));
             if(r<=r0  && r>=r1)
	     { 	 
			 edge=(1.0+cos(pi*(r-r1)/(r0-r1)))/2.0;
               		 refer[j+i*sy]=refer[j+i*sy]*edge;
	     }
              	 
	}



  
    
    
} 	    
      	    
	

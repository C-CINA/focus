#
#
# This is not an independent script.
# This should only be called from another script.
#
#
#
#
#
#
set frames_dir = SCRATCH/MovieA
#
if ( ! -e ${frames_dir} ) then
  \mkdir ${frames_dir}
endif
#
if ( ${show_frames} == "y" || ${show_frame_FFT} == "y" || ${show_frame_CCmap} == "y") then
  set tempkeep = "y"
endif
#
# echo  "# IMAGE-IMPORTANT: ${movie_stackname} <Raw image stack>" >> LOGS/${scriptname}.results
#
if ( ${movie_enable} == "n" ) then
  ${proc_2dx}/linblock "Skipping movie mode unbending."
  exit
endif
#
set ctfcor_noise_toosmall = `echo ${ctfcor_noise} | awk '{ if ( s < 0.8 ) { s = 1 } else { s = 0 } } END { print s } '`
if ( ${ctfcor_noise_toosmall} == "1" ) then
  echo ":: Correcting CTF-correction Noise value to 0.8."
  set ctfcor_noise = "0.8"
  echo "set ctfcor_noise = ${ctfcor_noise}" >> LOGS/${scriptname}.results
endif
#
if ( ${calculate_tiles}x == "nx" || ${calculate_tiles}x == "x" ) then
  set calculate_tiles = "0"
  echo "set calculate_tiles = ${calculate_tiles}" >> LOGS/${scriptname}.results
  echo ":: Correcting calculate_tiles to ${calculate_tiles}"
endif
#
if ( ${movie_stackname} == "ScriptWillPutNameHere" ) then
  ${proc_2dx}/linblock "Movie-file not found. Skipping script."
  set movie_enable = "n"
  echo "set movie_enable = ${movie_enable}" >> LOGS/${scriptname}.results
  exit
endif
#
${proc_2dx}/linblock "Movie Mode."
if ( -e ${movie_stackname}.mrc ) then
  set movie_stackname = ${movie_stackname}.mrc
  echo "set movie_stackname = ${movie_stackname}"  >> LOGS/${scriptname}.results
endif
#
if ( ${MASKING_done} == "y" ) then
  if ( ${movie_masking_mode} == "0" ) then
    ${proc_2dx}/linblock "WARNING: Correcting Frame Masking Mode to 1=Masking based on UnbendII"
    set movie_masking_mode = 1
    echo "set movie_masking_mode = ${movie_masking_mode}" >> LOGS/${scriptname}.results
  endif
endif
# 
if ( ! -e ${movie_stackname}) then
  ${proc_2dx}/protest "ERROR: ${movie_stackname} missing. Aborting."
else
  # Get the number of frames
  e2iminfo.py -H ${movie_stackname} > tmp_stack_header.txt
  set movie_imagenumber = `\grep "MRC.nz:" tmp_stack_header.txt | cut -d' ' -f 2`
  ${proc_2dx}/linblock "Stack contains ${movie_imagenumber} frames"
  set movie_imagenumber_total = ${movie_imagenumber}
  echo "set movie_imagenumber_total = ${movie_imagenumber_total}"  >> LOGS/${scriptname}.results
  \rm tmp_stack_header.txt
endif
#
if ( ${movie_filter_type} == "0" ) then
  #
  # automatic calculation of A and B for exponential filter:  
  # filter type:   res = a * exp(b * N)  ; with N being the frame number, up to Nmax.
  # res should be between 0.0 and 0.5 (Nyquist)
  #
  # For first half of frames, resolution should be the full 0.5.
  # 0.50 = A * exp(B * Nmax/2)
  # At last frame, limit resolution to 0.25
  # 0.25 = A * exp(B * Nmax)
  # 
  # Second equation equals:  A = 0.25 / exp(B * Nmax)
  # Into first equation gives: 
  # 0.50 = 0.25 / exp(B * Nmax) * exp(B * Nmax/2)
  # or: 0.50 = 0.25 / exp(B * Nmax/2)
  # or: 0.5 = exp(B * Nmax/2) 
  # or: ln(0.5) = B * Nmax/2 
  # or: B = 2 * ln(0.5) / Nmax
  # or: B = -1.38629 / Nmax
  #
  # Insertion into first equation gives: 
  # A = 0.5 / exp(2*ln(0.5)/Nmax * Nmax/2)
  # A = 0.5 / exp(2*ln(0.5)/2)
  # A = 0.5 / 0.5 = 1.0
  #
  set filt_a = 1.0
  set filt_b = `echo ${movie_imagenumber_total} | awk '{ s =  -1.38629 / $1 } END { print s }'`
  echo ":Automatic filters: filt_a = ${filt_a},  filt_b = ${filt_b}"
  echo "set filt_a = ${filt_a}"  >> LOGS/${scriptname}.results
  echo "set filt_b = ${filt_b}"  >> LOGS/${scriptname}.results
else
  if ( ${movie_filter_type} == "1" ) then
    set filt_a = `echo ${movie_filter_param} | sed 's/,/ /g' | awk '{ s = $1 } END { print s }'`
    set filt_b = `echo ${movie_filter_param} | sed 's/,/ /g' | awk '{ s = $2 } END { print s }'`
  else
    set filt_a = 1.0
    set filt_b = 0.0
  endif
endif
#
set num_dia = 100
#
set iname = image_ctfcor
#
if ( 1 == 1 ) then
  set movie_smoothing = 8
  echo "set movie_smoothing = ${movie_smoothing}"  >> LOGS/${scriptname}.results
endif
if ( ${movie_smoothing}x == "x" ) then
  set movie_smoothing = 8
  echo "set movie_smoothing = ${movie_smoothing}"  >> LOGS/${scriptname}.results
endif
#
if ( ${use_masked_image} == "y" ) then
  if ( -e ${nonmaskimagename}_manualmask.mrc ) then
    set maskfile = ${nonmaskimagename}_manualmask
  else
    if ( -e ${nonmaskimagename}_automask.mrc ) then
      set maskfile = ${nonmaskimagename}_automask
    else
      if ( -e ${nonmaskimagename}_mask.mrc ) then
        \mv ${nonmaskimagename}_mask.mrc ${nonmaskimagename}_automask.mrc
        set maskfile = ${nonmaskimagename}_automask
      else
        ${proc_2dx}/linblock "No Masking Info file found.  Not masking image."
        set use_masked_image = "n"
        echo "set use_masked_image = ${use_masked_image}"  >> LOGS/${scriptname}.results
      endif 
    endif 
  endif 
endif
#
setenv NCPUS ${Thread_Number}
#
if ( ${movie_masking_mode} == '1' && ${use_masked_image} == "y" ) then 
  if ( ! -e ${maskfile}.mrc ) then
    ${proc_2dx}/protest "ERROR: ${maskfile}.mrc not found. First run UNBEND-II with masking option."
    # ${proc_2dx}/linblock "WARNING: Continuing withoug masking."
    # set movie_masking_mode = 0
    # echo "set movie_masking_mode = ${movie_masking_mode}" >> LOGS/${scriptname}.results
  endif 
  echo  "# IMAGE: ${maskfile}.mrc <Crystal Masking Pattern>" >> LOGS/${scriptname}.results
endif
#
if ( ! -e ${iname}.mrc ) then
  ${proc_2dx}/protest "ERROR:  ${iname}.mrc missing. First run script Correct CTF on tiles"
endif
#
#
#
#
#
#
# Generate subfolder for frame images
\rm -rf ${frames_dir}
if ( ! -d ${frames_dir} ) then
  \mkdir ${frames_dir}
  set olddir = $PWD
  cd ${frames_dir}
  if ( ! -d PS ) then
    \mkdir PS
  endif
  cd ${olddir}
endif
#
#
#
#
##########################################################################
##########################################################################
# Now preparing reference:
##########################################################################
##########################################################################
#
echo "<<@progress: 5>>"
#
set PROFDATA = ${nonmaskimagename}_profile.dat
if ( ! -e ${PROFDATA} ) then
  if ( -e image_ctfcor_profile.dat ) then
    \mv -f image_ctfcor_profile.dat ${PROFDATA}
  endif
endif
if ( ! -e ${PROFDATA} ) then
  ${proc_2dx}/protest "ERROR: First run Unbend II."
endif
#
set cormap = ${iname}_CCmap_unbend2.mrc
#
if ( ! -e ${cormap} ) then
  ${proc_2dx}/protest "ERROR: First run Unbend-I and Unbend-II scripts. File missing: ${cormap}"
endif
# 
if ( ${SYN_Unbending} == "0" ) then
  #
  ###############################################################
  ###############################################################
  ###############################################################
  ${proc_2dx}/linblock "Preparing reference from Fourier-filtered UNBEND-II result"
  ###############################################################
  ###############################################################
  ###############################################################
  #
  ###############################################################
  ${proc_2dx}/linblock "FFTRANS - Calculate FFT of unbent image"
  ###############################################################
  #
  set unbent_fil = unbent.mrc  
  #
  if ( ! -e ${unbent_fil} ) then
    ${proc_2dx}/protest "ERROR: File missing: ${unbent_fil}"
  endif
  # 
  \rm -f SCRATCH/reference_flt_upscale.mrc
  ${bin_2dx}/labelh.exe << eot
${unbent_fil}
39
${frames_dir}/reference_flt_upscale.mrc
eot
  #
  setenv IN  ${frames_dir}/reference_flt_upscale.mrc
  setenv OUT ${frames_dir}/reference_flt_upscale_fft.mrc
  \rm -f     ${frames_dir}/reference_flt_upscale_fft.mrc
  ${bin_2dx}/2dx_fftrans.exe  
  #
  echo  "# IMAGE: ${frames_dir}/reference_flt_upscale_fft.mrc <Unbent image (FFT)>" >> LOGS/${scriptname}.results
  #
  echo "<<@progress: 15>>"
  #
  #
  #########################################################################
  ${proc_2dx}/linblock "MASKTRAN - Lattice-mask FFT of unbent image, small holes"
  #########################################################################
  set maskb = ${maskb01}
  set rmax = 11000  
  #
  setenv IN  ${frames_dir}/reference_flt_upscale_fft.mrc
  setenv OUT ${frames_dir}/reference_flt_upscale_fft_mask.mrc
  \rm -f     ${frames_dir}/reference_flt_upscale_fft_mask.mrc
  setenv SPOTS ${nonmaskimagename}.spt
  ${bin_2dx}/2dx_masktrana.exe << eot
1 F T F ! ISHAPE=1(CIRC),2(GAUSCIR),3(RECT)HOLE,IAMPLIMIT(T or F),ISPOT,IFIL
1 ! RADIUS OF HOLE IF CIRCULAR, X,Y HALF-EDGE-LENGTHS IF RECT.
${lattice},-50,50,-50,50,${rmax},1 ! A/BX/Y,IH/IKMN/MX,RMAX,ITYPE
eot
  echo  "# IMAGE: ${frames_dir}/reference_flt_upscale_fft_mask.mrc <Unbent image, Fourier-filtered (1px) (FFT)>" >> LOGS/${scriptname}.results 
  #
  if ( ${tempkeep} != "y" ) then
    \rm -f SCRATCH/reference_flt_upscale_fft.mrc
  endif
  #
  #
  ###############################################################
  ${proc_2dx}/linblock "FFTRANS - Back to real space"
  ###############################################################
  #
  setenv IN  ${frames_dir}/reference_flt_upscale_fft_mask.mrc
  setenv OUT ${frames_dir}/reference_flt_upscale_fft_mask_fft.mrc
  \rm -f     ${frames_dir}/reference_flt_upscale_fft_mask_fft.mrc
  ${bin_2dx}/2dx_fftrans.exe  
  #
  echo  "# IMAGE: ${frames_dir}/reference_flt_upscale_fft_mask_fft.mrc <Unbent image, Fourier-filtered>" >> LOGS/${scriptname}.results  
  #
  if ( ${tempkeep} != "y" ) then
    \rm -f ${frames_dir}/reference_flt_upscale_fft_mask.mrc
  endif
  #
  echo "<<@progress: 17>>"
  #
  #
  ###############################################################
  ${proc_2dx}/linblock "BOXIMAGE - Boxing reference: ${movie_refboxa}"
  ###############################################################
  #
  python ${proc_2dx}/movie/box_reference.py ${frames_dir}/reference_flt_upscale_fft_mask_fft.mrc ${frames_dir}/reference_flt_upscale_fft_mask_fft_box.mrc ${movie_refboxa}
  #
  if ( ${tempkeep} != "y" ) then
    \rm -f ${frames_dir}/reference_flt_upscale_fft_mask_fft.mrc
  endif
  #
  \rm -f ${frames_dir}/reference_flt_upscale_fft_mask_fft_box_upscale.mrc
  ${bin_2dx}/labelh.exe << eot
${frames_dir}/reference_flt_upscale_fft_mask_fft_box.mrc
39
${frames_dir}/reference_flt_upscale_fft_mask_fft_box_upscale.mrc
eot
  echo  "# IMAGE-IMPORTANT: ${frames_dir}/reference_flt_upscale_fft_mask_fft_box_upscale.mrc <Reference (${movie_refboxa}px)>" >> LOGS/${scriptname}.results
  #
  #
  ###############################################################
  ${proc_2dx}/linblock "FFTRANS - Producing reference in Fourier space"
  ###############################################################
  #
  setenv IN  ${frames_dir}/reference_flt_upscale_fft_mask_fft_box_upscale.mrc
  setenv OUT ${frames_dir}/reference_flt_upscale_fft_mask_fft_box_fft.mrc
  \rm -f     ${frames_dir}/reference_flt_upscale_fft_mask_fft_box_fft.mrc
  ${bin_2dx}/2dx_fftrans.exe 
  #
  echo  "# IMAGE: ${frames_dir}/reference_flt_upscale_fft_mask_fft_box_fft.mrc <Reference (FFT)>" >> LOGS/${scriptname}.results
  #
  #
  #########################################################################
  ${proc_2dx}/linblock "MASKTRAN - Masked FFT of boxed reference"
  #########################################################################
  set maskb = ${maskb01}
  set rmax = 11000
  #
  setenv IN  ${frames_dir}/reference_flt_upscale_fft_mask_fft_box_fft.mrc
  setenv OUT ${frames_dir}/reference_fft.mrc
  \rm -f     ${frames_dir}/reference_fft.mrc
  setenv SPOTS ${nonmaskimagename}.spt
  ${bin_2dx}/2dx_masktrana.exe << eot
1 F T F ! ISHAPE=1(CIRC),2(GAUSCIR),3(RECT)HOLE,IAMPLIMIT(T or F),ISPOT,IFIL
${maskb} ! RADIUS OF HOLE IF CIRCULAR, X,Y HALF-EDGE-LENGTHS IF RECT.
${lattice},-50,50,-50,50,${rmax},1 ! A/BX/Y,IH/IKMN/MX,RMAX,ITYPE
eot
  #
  echo  "# IMAGE: ${frames_dir}/reference_fft.mrc <Reference, Fourier-filtered (${maskb}px) (FFT)>" >> LOGS/${scriptname}.results
  #
  cat ${nonmaskimagename}.spt
  #
  if ( ${tempkeep} != "y" ) then
    \rm -f SCRATCH/reference_flt_upscale_fft_mask_fft_box_fft.mrc
  endif
  #
  #
  #
  #
  #
else
  #
  ###############################################################
  ###############################################################
  ###############################################################
  ${proc_2dx}/linblock "Preparing reference from merged MTZ file"
  ###############################################################
  ###############################################################
  ###############################################################
  #
  set tmp1 = `echo ${SYN_maska} | awk '{s = int( $1 ) } END { print s }'`
  if ( ${tmp1} == ${SYN_maska} ) then
    echo SYN_maska = ${SYN_maska}
  else
    set SYN_maska = ${tmp1}
    echo SYN_maska = ${SYN_maska}
    echo "set SYN_maska = ${SYN_maska}" >> LOGS/${scriptname}.results
    ${proc_2dx}/linblock "Warning: SYN_maska needs to be an integer number. Now corrected." >> LOGS/${scriptname}.results
    echo "#WARNING: Warning: SYN_maska needs to be an integer number. Now corrected." >> LOGS/${scriptname}.results
  endif
  #
  set loc_SYN_mask = ${SYN_maska}
  set loc_SYN_Bfact = ${SYN_Bfact1}
  set locfactor = '1.0'
  #
  source ${proc_2dx}/2dx_make_SynRef_sub.com
  #
  \mv -f SCRATCH/reference_fft.mrc ${frames_dir}/reference_fft.mrc
  echo "# IMAGE: ${frames_dir}/reference_fft.mrc <Synthetic Reference (FFT)>" >> LOGS/${scriptname}.results
  #
  \mv -f SCRATCH/reference.mrc ${frames_dir}/reference.mrc
  echo  "# IMAGE: ${frames_dir}/reference.mrc <Synthetic Reference>" >> LOGS/${scriptname}.results

  #
  #
  #
endif
#
echo "<<@progress: 20>>"
#
#
#
#
#
#
##########################################################################
##########################################################################
# Now preparing frames:
##########################################################################
##########################################################################
#
#
#
#
#
#
#
#
#
#
###############################################################
${proc_2dx}/linblock "Splitting Stack into ${movie_imagenumber_total} frames"
############################################################### 
#
python ${proc_2dx}/movie/movie_mode_split.py ${movie_stackname} ${nonmaskimagename} ${frames_dir}
#
#
#
#
###############################################################
${proc_2dx}/linblock "Pre-processing all frames"
###############################################################
#
set prog_num = 25
echo "<<@progress: ${prog_num}>>"       
#
# i counts the super-frames to process:
set i = 1
while ($i <= ${movie_imagenumber_total})
  #
  # The following line was for testing purposes:
  # cp ${nonmaskimagename}_raw.mrc ${frames_dir}/frame_${i}.mrc
  #
  ${proc_2dx}/lin "Adapting size and limiting resolution for frame ${i}"
  set new_mrc_created = y
  set loc_imagename = ${frames_dir}/frame_${i}
  source ${proc_2dx}/2dx_initialize_make_image_square_sub.com
  source ${proc_2dx}/2dx_initialize_crop_histogram_sub.com
  #
  if ( ${show_frames} == "y" ) then
    echo "# IMAGE: ${frames_dir}/frame_${i}.mrc <Frame ${i}>" >> LOGS/${scriptname}.results
  endif
  #
  if (${ctfcor_imode}x == "0x" || ${ctfcor_imode}x == "4x" || ${ctfcor_imode}x == "5x" || ${ctfcor_imode}x == "6x" ) then
    ${proc_2dx}/linblock "Not applying any CTF correction before unbending."
    set olddir = $PWD
    cd ${frames_dir}
    \ln -s frame_${i}.mrc frame_${i}_ctfcor.mrc
    cd olddir
  else
    #  
    #################################################################################
    ${proc_2dx}/linblock "2dx_ctfcor - CTF correcting frame ${i}"
    #################################################################################  
    #
    \rm -f ${frames_dir}/frame_${i}_ctfcor.mrc
    #
    if ( ${calculate_tiles} == "0" ) then
      ${bin_2dx}/2dx_ctfcor_stripes.exe << eot
${frames_dir}/frame_${i}.mrc
${frames_dir}/frame_${i}_ctfcor.mrc
#
${TLTAXIS},${TLTANG}
${CS},${KV},${phacon},${magnification},${stepdigitizer}
${defocus}
${RESMAX}
${ctfcor_noise}
${ctfcor_imode}
${ctfcor_debug}
eot
      #
    else
      if ( ${calculate_tiles} == "1" ) then
        #
        set ctfcor_tilefile = "${frames_dir}/2dx_ctfcor_tile.mrc"
        set ctfcor_psfile = "${frames_dir}/2dx_ctfcor_psfile.mrc"
        set ctfcor_ctffile = "${frames_dir}/2dx_ctfcor_ctffile.mrc"
        \rm -f ${ctfcor_tilefile}
        \rm -f ${ctfcor_psfile} 
        \rm -f ${ctfcor_ctffile} 
        #
        ${bin_2dx}/2dx_ctfcor_tiles.exe << eot
${frames_dir}/frame_${i}.mrc
${frames_dir}/frame_${i}_ctfcor.mrc
#
#
#
${TLTAXIS},${TLTANG}
${CS},${KV},${phacon},${magnification},${stepdigitizer}
${defocus}
${ctfcor_noise}
${ctfcor_inner_tile}
${ctfcor_outer_tile}
${ctfcor_taper}
${ctfcor_imode}
${ctfcor_debug}
${ctfcor_maxamp_factor}
eot
        #
        echo "# IMAGE: ${frames_dir}/frame_${i}_ctfcor.mrc <Frame ${i}, CTF corrected>" >> LOGS/${scriptname}.results
        #
      else
        #
        set ctfcor_tilefile = "${frames_dir}/2dx_ctfcor_tile.mrc"
        set ctfcor_psfile = "${frames_dir}/2dx_ctfcor_psfile.mrc"
        set ctfcor_ctffile = "${frames_dir}/2dx_ctfcor_ctffile.mrc"
        \rm -f ${ctfcor_tilefile}
        \rm -f ${ctfcor_psfile} 
        \rm -f ${ctfcor_ctffile} 
        #
        ${bin_2dx}/2dx_ctfcor_tiles.exe << eot
${frames_dir}/frame_${i}.mrc
${frames_dir}/frame_${i}_ctfcor.mrc
${ctfcor_tilefile}
${ctfcor_psfile}
${ctfcor_ctffile}
${TLTAXIS},${TLTANG}
${CS},${KV},${phacon},${magnification},${stepdigitizer}
${defocus}
${ctfcor_noise}
${ctfcor_inner_tile}
${ctfcor_outer_tile}
${ctfcor_taper}
${ctfcor_imode}
${ctfcor_debug}
${ctfcor_maxamp_factor}
eot
        #
        echo "# IMAGE: ${frames_dir}/frame_${i}_ctfcor.mrc <Frame ${i}, CTF corrected>" >> LOGS/${scriptname}.results
        \mv -f ${ctfcor_tilefile} ${frames_dir}/frame_${i}_tiles.mrc
        echo "# IMAGE: ${frames_dir}/frame_${i}_tiles.mrc <Frame ${i}, tiles marked>" >> LOGS/${scriptname}.results
        \mv -f ${ctfcor_psfile} ${frames_dir}/frame_${i}_ps.mrc
        echo "# IMAGE: ${frames_dir}/frame_${i}_ps.mrc <Frame ${i}, PowerSpectra>" >> LOGS/${scriptname}.results
        #
        \mv -f ${ctfcor_ctffile} ${frames_dir}/frame_${i}_ctffile.mrc
        if ( ${ctfcor_imode} == "2" ) then
          echo "# IMAGE: ${frames_dir}/frame_${i}_ctffile.mrc <Summed CTF**2 file>" >> LOGS/${scriptname}.results
        else
          echo "# IMAGE: ${frames_dir}/frame_${i}_ctffile.mrc <Summed CTF file>" >> LOGS/${scriptname}.results
        endif
      endif
    endif
    #
  endif
  #
  ###############################################################
  ${proc_2dx}/linblock "cross_correlate.py - Cross-correlate reference with frame ${i}"
  ############################################################### 
  #
  python ${proc_2dx}/movie/cross_correlate.py ${frames_dir}/frame_${i}_ctfcor.mrc ${frames_dir}/reference_fft.mrc ${frames_dir}/CCmap_${i}.mrc
  if ( ${show_frame_CCmap} == "y" ) then
    echo  "# IMAGE: ${frames_dir}/CCmap_${i}.mrc <Frame ${i}, CCmap>" >> LOGS/${scriptname}.results
  endif
  #
  set prog_num = `echo ${i} ${movie_imagenumber_total} | awk '{ s = 25 + int( 75 * $1 / $2 ) } END { print s }'` 
  echo "<<@progress: ${prog_num}>>"       
  #
  #
  @ i += 1
end
#
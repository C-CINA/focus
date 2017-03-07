#!/usr/bin/env python

#############################################################################
#                                                                           #
# Script to apply CTF to an MRC image or stack                				#
#                                                                           #
# (C) 2dx.org, GNU Public License. 	                                        #
#                                                                           #
# Created..........: 27/02/2017                                             #
# Last Modification: 27/02/2017                                             #
# Author...........: Ricardo Righetto                                       #
# 																			#
# This Python script is distributed with the Focus package 					#
# under the terms of the GNU Public License.								#
# 																			#
#############################################################################

import sys
import os
import numpy as np
import matplotlib.pyplot as plt
import focus_ctf as CTF
import focus_utilities as util
import ioMRC
from optparse import OptionParser


def main():

	progname = os.path.basename(sys.argv[0])
	usage = progname + """ <mrc(s) file> [options] 

	Given an MRC file containing one or more 2D images, applies CTF operations on them.
	This program adopts the conventions of the following paper:

	J. A. Mindell and N. Grigorieff, "Accurate determination of local defocus and specimen tilt in electron microscopy," J. Struct. Biol., vol. 142, no. 3, pp. 334-347, Jun. 2003.

	(which is the same adopted in FREALIGN, RELION, CTFFIND3/4 and Gctf, among others)

	"""

	parser = OptionParser(usage)

	parser.add_option("--out", metavar='ctf', type="string", default='ctf', help="Basename of output files. By default, the program uses the name of the MRC file provided as input, otherwise it is set to 'ctf'. ")

	parser.add_option("--angpix", metavar=1.0, default=1.0, type="float", help="Pixel size in Angstroems")

	parser.add_option("--df1", metavar=1000.0, default=0.0, type="float", help="Defocus 1 (or Defocus U in some notations). Principal defocus axis. Underfocus is positive.")

	parser.add_option("--df2", metavar=1000.0, default=None, type="float", help="Defocus 2 (or Defocus V in some notations). Defocus axis orthogonal to the U axis. Only mandatory for astigmatic data.")

	parser.add_option("--ast", metavar=0.0, default=0.0, type="float", help="Angle for astigmatic data (in degrees).")

	parser.add_option("--ampcon", metavar=0.1, default=0.1, type="float", help="Amplitude contrast fraction (between 0.0 and 1.0).")

	parser.add_option("--cs", metavar=2.7, default=2.7, type="float", help="Spherical aberration.")

	parser.add_option("--kv", metavar=300.0, default=300.0, type="float", help="High-tension voltage of the TEM.")

	parser.add_option("--bfac", metavar=0.0, default=0.0, type="float", help="B-factor to apply to CTF model. Not used for CTF correction, only for plotting of theoretical CTF profiles.")

	parser.add_option("--invert", action="store_true", default=False, help="Inverts contrast of images.")

	parser.add_option("--phase_flip", action="store_true", default=False, help="Applies CTF correction by phase-flipping to images.")

	parser.add_option("--ctf_multiply", action="store_true", default=False, help="Applies CTF correction by CTF-multiplication to images.")

	parser.add_option("--wiener_filter", action="store_true", default=False, help="Applies CTF correction by Wiener-filtering to images.")

	parser.add_option("--wiener_constant", metavar=0.1, default=0.1, type="float", help="Constant for the Wiener filter. The smaller this value is, the more amplitudes will be enhanced (but may also amplify noise).")

	parser.add_option("--save_ctf_2d", action="store_true", default=False, help="Return an image containing the 2D CTF?")

	parser.add_option("--save_ctf_1d", action="store_true", default=False, help="Return an image containing the 1D CTF? (assumes non-astigmatic data).")

	parser.add_option("--nsamples", metavar=1024, default=1024, type="int", help="Number of samples to generate 1D and 2D theoretical CTF profiles. If used together with an input image, this will automatically be set to the number of samples corresponding to the image size.")

	parser.add_option("--dpi", metavar=300, type="int", default=300, help="Resolution of the PNG files to store the 1D CTF (assumes non-astigmatic data).")


	(options, args) = parser.parse_args()

	command = ' '.join(sys.argv)

	# print args

	if args != []:


		sys.stdout = open(os.devnull, "w") # Suppress output
		mrc = ioMRC.readMRC( args[0], useMemmap = True )[0]

		bname = os.path.basename( args[0] )
		fname,fext = os.path.splitext( bname )
		options.out = fname

		if mrc.ndim == 2:

			mrc = mrc.reshape(1, mrc.shape[0], mrc.shape[1])

		for i in np.arange( mrc.shape[0] ):

			CTFcor = CTF.CorrectCTF( mrc[i,:,:], DF1 = options.df1, DF2 = options.df2, AST = options.ast, WGH = options.ampcon, invert_contrast = options.invert, Cs = options.cs, kV = options.kv, apix = options.angpix, phase_flip = options.phase_flip, ctf_multiply = options.ctf_multiply, wiener_filter = options.wiener_filter, C = options.wiener_constant, return_ctf = False, rfft = True )

			if CTFcor[-1] != []:

				for j in np.arange( len(CTFcor[-1]) ):

					ioMRC.writeMRC( CTFcor[j], options.out + '_' + CTFcor[-1][j] + fext, dtype='float32', idx = i )

		sys.stdout = sys.__stdout__

	if options.save_ctf_1d:

		if args != []:

			imsize = np.round( np.sqrt( np.sum( np.power( mrc.shape[1:], 2 ) ) ) / np.sqrt(2) ).astype('int')

		else:

			imsize = 2 * options.nsamples

		if options.df2 != None:

			dfavg = 0.5 * ( options.df1 + options.df2 )

		else:

			dfavg = options.df1

		x = np.fft.rfftfreq( imsize ) / options.angpix

		y = CTF.CTF( imsize, DF1 = dfavg, DF2 = dfavg, AST = 0.0, WGH = options.ampcon, Cs = options.cs, kV = options.kv, apix = options.angpix, B = options.bfac, rfft = True )
		# print len(x),len(y)

		if options.invert:

			y *= -1.0

		fig = plt.figure()
		plt.plot(x, y)
		plt.grid()
		plt.ylim([-1.1,1.1])
		plt.xlabel('Resolution [1/A]')
		plt.ylabel('CTF')
		plt.title('Contrast Transfer Function')
		fig.savefig( options.out + '_1d.png', dpi=options.dpi)
		plt.close()

		if options.phase_flip:

			fig = plt.figure()
			plt.plot(x, y * np.sign( y ) )
			plt.grid()
			plt.ylim([-1.1,1.1])
			plt.xlabel('Resolution [1/A]')
			plt.ylabel('CTF')
			plt.title('CTF - Phase Flipped')
			fig.savefig( options.out + '_1d-phase_flipped.png', dpi=options.dpi)
			plt.close()


		if options.ctf_multiply:

			# CTF without envelope (B-factor):
			ynoenv = CTF.CTF( imsize, DF1 = dfavg, DF2 = dfavg, AST = 0.0, WGH = options.ampcon, Cs = options.cs, kV = options.kv, apix = options.angpix, B = 0.0, rfft = True )

			fig = plt.figure()
			plt.plot(x, y * ynoenv )
			plt.grid()
			plt.ylim([-1.1,1.1])
			plt.xlabel('Resolution [1/A]')
			plt.ylabel('CTF')
			plt.title('CTF - CTF Multiplied')
			fig.savefig( options.out + '_1d-ctf_multiplied.png', dpi=options.dpi)
			plt.close()

		if options.wiener_filter:

			# CTF without envelope (B-factor):
			ynoenv = CTF.CTF( imsize, DF1 = dfavg, DF2 = dfavg, AST = 0.0, WGH = options.ampcon, Cs = options.cs, kV = options.kv, apix = options.angpix, B = 0.0, rfft = True )

			fig = plt.figure()
			plt.plot(x, y * ynoenv / ( ynoenv*ynoenv + options.wiener_constant ) )
			plt.grid()
			plt.ylim([-1.1,1.1])
			plt.xlabel('Resolution [1/A]')
			plt.ylabel('CTF')
			plt.title('CTF - Wiener filtered')
			fig.savefig( options.out + '_1d-wiener_filtered.png', dpi=options.dpi)
			plt.close()

	if options.save_ctf_2d:

		if args != []:

			imsize = [mrc.shape[-2], mrc.shape[-1]]

		else:

			imsize = 2 * np.array( [options.nsamples, options.nsamples] )

		if options.df2 != None:

			dfavg = 0.5 * ( options.df1 + options.df2 )

		else:

			dfavg = options.df1

		# x = np.fft.fftfreq( imsize[-1] ) / options.angpix

		y = CTF.CTF( imsize, DF1 = options.df1, DF2 = options.df2, AST = options.ast, WGH = options.ampcon, Cs = options.cs, kV = options.kv, apix = options.angpix, B = options.bfac, rfft = False )
		# print len(x),len(y)

		if options.invert:

			y *= -1.0

		y = np.fft.ifftshift( y )

		sys.stdout = open(os.devnull, "w") # Suppress output
		ioMRC.writeMRC( y, options.out + '_2d.mrc', dtype='float32' )
		ioMRC.writeMRC( y**2, options.out + '_2d-power_spectrum.mrc', dtype='float32' )

		if options.phase_flip:

			pf = y * np.sign( y )

			ioMRC.writeMRC( pf, options.out + '_2d-phase_flipped.mrc', dtype='float32' )
			ioMRC.writeMRC( pf**2, options.out + '_2d-power_spectrum-phase_flipped.mrc', dtype='float32' )


		if options.ctf_multiply:

			# CTF without envelope (B-factor):
			ynoenv = CTF.CTF( imsize, DF1 = options.df1, DF2 = options.df2, AST = options.ast, WGH = options.ampcon, Cs = options.cs, kV = options.kv, apix = options.angpix, B = options.bfac, rfft = False )

			ynoenv = np.fft.ifftshift( ynoenv )
			cm = y * ynoenv

			ioMRC.writeMRC( cm, options.out + '_2d-ctf_multiplied.mrc', dtype='float32' )
			ioMRC.writeMRC( cm**2, options.out + '_2d-power_spectrum-ctf_multiplied.mrc', dtype='float32' )

		if options.wiener_filter:

			# CTF without envelope (B-factor):
			ynoenv = CTF.CTF( imsize, DF1 = options.df1, DF2 = options.df2, AST = options.ast, WGH = options.ampcon, Cs = options.cs, kV = options.kv, apix = options.angpix, B = options.bfac, rfft = False )

			ynoenv = np.fft.ifftshift( ynoenv )
			wf = y * ynoenv / ( ynoenv*ynoenv + options.wiener_constant )

			ioMRC.writeMRC( wf, options.out + '_2d-wiener_filtered.mrc', dtype='float32' )
			ioMRC.writeMRC( wf**2, options.out + '_2d-power_spectrum-wiener_filtered.mrc', dtype='float32' )

		sys.stdout = sys.__stdout__

if __name__ == "__main__":
	main()
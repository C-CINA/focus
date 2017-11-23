# Python utilities for Focus
# Author: Ricardo Righetto
# E-mail: ricardo.righetto@unibas.ch

import numpy as np

# # # NOTE ON FFT # # #
# # At some point I might replace np.fft with pyfftw, but I couldn't get it working properly yet (see below).
# # And, I don't go for scipy.fftpack because the output of scipy.fftpack.rfft is weird, plus I/O datatype manipulation can be cumbersome compared to np.fft. 

# try:

# 	# http://pyfftw.readthedocs.io/en/latest/source/tutorial.html#interfaces-tutorial
# 	import pyfftw

# 	# Monkey patch numpy_fft with pyfftw.interfaces.numpy_fft
# 	np.fft = pyfftw.interfaces.numpy_fft
# 	# np.empty = pyfftw.empty_aligned

# 	# Turn on the cache for optimum performance
# 	pyfftw.interfaces.cache.enable()
# 	pyfftw.interfaces.cache.set_keepalive_time(60)

# except ImportError:

# 	print( "PyFFTW not found. Falling back to numpy.fft (slow).\nYou may want to install PyFFTW by running:\n'pip install pyfftw'" )

# print np.fft.__file__


def RadialIndices( imsize = [100, 100], rounding=True, normalize=False, rfft=False, xyz=[0,0,0], nozero=True ):
# Returns radius and angles for each pixel (or voxel) in a 2D image or 3D volume of shape = imsize
# For 2D returns the angle with the horizontal x- axis
# For 3D returns the angle with the horizontal x,y plane
# If imsize is a scalar, will default to 2D.
# Rounding is to ensure "perfect" radial symmetry, desirable in some applications.
# Normalize=True will normalize the radius to values between 0.0 and 1.0.
# rfft=True will return only half of the radial indices in a way that is compliant with the FFT of real inputs.
# Note: This function is compliant with NumPy fftfreq() and rfftfreq()

	if np.isscalar(imsize):

		imsize = [imsize, imsize]

	if len( imsize ) > 3:

		raise ValueError( "Object should have 2 or 3 dimensions: len(imsize) = %d " % len(imsize))

	xyz = np.flipud( xyz )

	import warnings
	with warnings.catch_warnings():
		warnings.filterwarnings( "ignore", category=RuntimeWarning )

		m = np.mod(imsize, 2) # Check if dimensions are odd or even

		if len(imsize) == 2:

			# [xmesh, ymesh] = np.mgrid[-imsize[0]/2:imsize[0]/2, -imsize[1]/2:imsize[1]/2]
			# The definition below is consistent with numpy np.fft.fftfreq and np.fft.rfftfreq:

			if not rfft:

				[xmesh, ymesh] = np.mgrid[-imsize[0]//2+m[0]-xyz[0]:(imsize[0]-1)//2+1-xyz[0], -imsize[1]//2+m[1]-xyz[1]:(imsize[1]-1)//2+1-xyz[1]]

			else:

				[xmesh, ymesh] = np.mgrid[-imsize[0]//2+m[0]-xyz[0]:(imsize[0]-1)//2+1-xyz[0], 0-xyz[1]:imsize[1]//2+1-xyz[1]]
				xmesh = np.fft.ifftshift( xmesh )

			rmesh = np.sqrt( xmesh*xmesh + ymesh*ymesh )
			
			amesh = np.arctan2( ymesh, xmesh )

			n = 2 # Normalization factor

		else:

			# [xmesh, ymesh, zmesh] = np.mgrid[-imsize[0]/2:imsize[0]/2, -imsize[1]/2:imsize[1]/2, -imsize[2]/2:imsize[2]/2]
			# The definition below is consistent with numpy np.fft.fftfreq and np.fft.rfftfreq:

			if not rfft:

				[xmesh, ymesh, zmesh] = np.mgrid[-imsize[0]//2+m[0]-xyz[0]:(imsize[0]-1)//2+1-xyz[0], -imsize[1]//2+m[1]-xyz[1]:(imsize[1]-1)//2+1-xyz[1], -imsize[2]//2+m[2]-xyz[2]:(imsize[2]-1)//2+1-xyz[2]]

			else:

				[xmesh, ymesh, zmesh] = np.mgrid[-imsize[0]//2+m[0]-xyz[0]:(imsize[0]-1)//2+1-xyz[0], -imsize[1]//2+m[1]-xyz[1]:(imsize[1]-1)//2+1-xyz[1], 0-xyz[2]:imsize[2]//2+1-xyz[2]]
				xmesh = np.fft.ifftshift( xmesh )
				ymesh = np.fft.ifftshift( ymesh )

			rmesh = np.sqrt( xmesh*xmesh + ymesh*ymesh + zmesh*zmesh )

			amesh = np.arccos( zmesh / rmesh )

			n = 3 # Normalization factor

	if rounding:

		rmesh = np.round( rmesh ).astype('int')

	if normalize:

		rmesh = rmesh / ( np.sqrt( np.sum( np.power( imsize, 2 ) ) ) / np.sqrt(n) )

	if nozero:

		rmesh[rmesh == 0] = 1e-3 # Replaces the "zero radius" by a small value to prevent division by zero in other programs

	return rmesh, np.nan_to_num( amesh )

def Shift( img, shift = [0,0,0] ):
# Shifts a 3D volume by phase shifting in Fourier space (2D image to come).
# Compatible with relion_image_handler
# The shift to be applied is given by the array 'shift'
# By default employs rfft for speedup.

	imsize = np.array( img.shape )
	shift = np.array( shift ).astype( 'float' )

	if len( imsize ) != len( shift ):

		raise ValueError( "Shift dimensions do not match image/volume dimensions: len(img.shape) = %d and len(shift) = %d " % len( imsize ) )

	if len( imsize ) > 3:

		raise ValueError( "Object should have 2 or 3 dimensions: len(img.shape) = %d " % len( imsize)  )

	shift = np.flipud( shift )

	import warnings
	with warnings.catch_warnings():
		warnings.filterwarnings( "ignore", category=RuntimeWarning )

		m = np.mod(imsize, 2) # Check if dimensions are odd or even

		if len(imsize) == 2:


			[xmesh, ymesh] = np.mgrid[-imsize[0]//2+m[0]:(imsize[0]-1)//2+1, 0:imsize[1]//2+1]
			xmesh = np.fft.ifftshift( xmesh )

		else:

			[xmesh, ymesh, zmesh] = np.mgrid[-imsize[0]//2+m[0]:(imsize[0]-1)//2+1, -imsize[1]//2+m[1]:(imsize[1]-1)//2+1, 0:imsize[2]//2+1]
			xmesh = np.fft.ifftshift( xmesh )
			ymesh = np.fft.ifftshift( ymesh )

	ft = np.fft.rfftn( img )

	if len( imsize ) == 2:

		ft_shift = np.exp( -2.0 * np.pi * 1j * ( shift[0] * xmesh / imsize[0] + shift[1] * ymesh / imsize[1] ) )

	else:

		ft_shift = np.exp( -2.0 * np.pi * 1j * ( shift[0] * xmesh / imsize[0] + shift[1] * ymesh / imsize[1] + shift[2] * zmesh / imsize[2] ) )


	return np.fft.irfftn( ft * ft_shift , s=img.shape )

def Rotate( img, rot = [0,0,0], interpolation='trilinear' ):
# Rotates a 2D image or 3D volume
# Rotation array 'rot' is given in SPIDER conventions (ZYZ rotation): PHI, THETA, PSI - same as in relion_rotate
# Interpolation can be 'nearest' (fast but poor), 'trilinear' (slower but better) or 'cosine' (slightly slower than trilinear and maybe slightly worse - not clear)
# Even better results can be achieved by resampling the input image beforehand, but that may be very RAM-demanding. See function Resample().
# For detailed definitions please see Baldwin & Penczek, JSB 2007.

	if np.isscalar( rot ):

		rot = [rot]

	imsize = np.array( img.shape )
	rot = np.array( rot ).astype( 'float' ) * np.pi / 180.0

	if len( imsize ) == 3:

		if len( imsize ) != len( rot ):

			raise ValueError( "Rotation dimensions do not match image/volume dimensions: len(img.shape) = %d and len(rot) = %d " % len( imsize ) )

	elif len( imsize ) == 2 and len ( rot ) != 1:

			raise ValueError( "Rotation dimensions do not match image/volume dimensions: len(img.shape) = %d and len(rot) = %d " % len( imsize ) )

	if len( imsize ) > 3:

		raise ValueError( "Object should have 2 or 3 dimensions: len(img.shape) = %d " % len( imsize)  )

	import warnings
	with warnings.catch_warnings():
		warnings.filterwarnings( "ignore", category=RuntimeWarning )

		m = np.mod(imsize, 2) # Check if dimensions are odd or even

		if len(imsize) == 2:

			[xmesh, ymesh] = np.mgrid[-imsize[0]//2+m[0]:(imsize[0]-1)//2+1, -imsize[1]//2+m[1]:(imsize[1]-1)//2+1]
			psi = rot[0]

			rotmat = np.matrix( [[np.cos( psi ), -np.sin( psi )], [np.sin( psi ), np.cos( psi )]] )

			sqrt2 = np.sqrt( 2 )

			ymeshrot = ( sqrt2 * imsize[1] - imsize[1] )//2 + ymesh * rotmat[0,0] + xmesh * rotmat[1,0] + imsize[1]//2 - m[1]
			xmeshrot = ( sqrt2 * imsize[0] - imsize[0] )//2 + ymesh * rotmat[0,1] + xmesh * rotmat[1,1] + imsize[0]//2 - m[0]

			img2 = Resize( img, newsize=imsize * sqrt2 )

			rotimg = np.zeros( img2.shape )

			if interpolation == 'nearest':

				rotimg = img2[ np.round( xmeshrot ).astype('int'), np.round( ymeshrot ).astype('int') ]

			else:

				x0 = np.floor( xmeshrot ).astype( 'int' )
				x1 = np.ceil( xmeshrot ).astype( 'int' )
				y0 = np.floor( ymeshrot ).astype( 'int' )
				y1 = np.ceil( ymeshrot ).astype( 'int' )

				import warnings
				with warnings.catch_warnings():
					warnings.filterwarnings( "ignore", category=RuntimeWarning )

					xd = np.nan_to_num( ( xmeshrot - x0 ) / ( x1 - x0 ) )
					yd = np.nan_to_num( ( ymeshrot - y0 ) / ( y1 - y0 ) )

				if interpolation == 'cosine': # Smoother than trilinear at negligible extra computation cost?

					xd = ( 1 - np.cos( xd * np.pi) ) / 2
					yd = ( 1 - np.cos( yd * np.pi) ) / 2

				# c00 = img2[x0, y0]
				# c01 = img2[x0, y1]
				# c10 = img2[x1, y0]
				# c11 = img2[x1, y1]

				# c0 = c00 * ( 1 - xd ) + c10 * xd
				# c1 = c01 * ( 1 - xd ) + c11 * xd

				# c = c0 * ( 1 - yd ) + c1 * yd

				# Below is the same as the commented above, but in one line:
				rotimg = ( img2[x0, y0] * ( 1 - xd ) + img2[x1, y0] * xd ) * ( 1 - yd ) + ( img2[x0, y1] * ( 1 - xd ) + img2[x1, y1] * xd ) * yd

		else:

			[xmesh, ymesh, zmesh] = np.mgrid[-imsize[0]//2+m[0]:(imsize[0]-1)//2+1, -imsize[1]//2+m[1]:(imsize[1]-1)//2+1, -imsize[2]//2+m[2]:(imsize[2]-1)//2+1]

			# print xmesh.min(),xmesh.max()
			# print ymesh.min(),ymesh.max()
			# print zmesh.min(),zmesh.max()

			phi = rot[0]
			theta = rot[1]
			psi = rot[2]

			mat1 = np.matrix( [[np.cos( psi ), np.sin( psi ), 0], [-np.sin( psi ), np.cos( psi ), 0], [0, 0, 1]] )
			mat2 = np.matrix( [[np.cos( theta ), 0, -np.sin( theta )], [0, 1, 0], [np.sin( theta ), 0, np.cos( theta )]] )
			mat3 = np.matrix( [[np.cos( phi ), np.sin( phi ), 0], [-np.sin( phi ), np.cos( phi ), 0], [0, 0, 1]] )
			rotmat = mat1 * mat2 * mat3

			# print rotmat

			# Original matrix mmultiplications, without bothering about indices:
			# zmeshrot = zmesh * rotmat[0,0] + ymesh * rotmat[1,0] + xmesh * rotmat[2,0]
			# ymeshrot = zmesh * rotmat[0,1] + ymesh * rotmat[1,1] + xmesh * rotmat[2,1]
			# xmeshrot = zmesh * rotmat[0,2] + ymesh * rotmat[1,2] + xmesh * rotmat[2,2]

			sqrt3 = np.sqrt( 3 )

			zmeshrot = ( sqrt3 * imsize[2] - imsize[2] )//2 + zmesh * rotmat[0,0] + ymesh * rotmat[1,0] + xmesh * rotmat[2,0] + imsize[2]//2 - m[0]
			ymeshrot = ( sqrt3 * imsize[1] - imsize[1] )//2 + zmesh * rotmat[0,1] + ymesh * rotmat[1,1] + xmesh * rotmat[2,1] + imsize[1]//2 - m[1]
			xmeshrot = ( sqrt3 * imsize[0] - imsize[0] )//2 + zmesh * rotmat[0,2] + ymesh * rotmat[1,2] + xmesh * rotmat[2,2] + imsize[0]//2 - m[2]

			img2 = Resize( img, newsize=imsize * sqrt3 )

			# zmeshrot = ( 2 * imsize[2] - imsize[2] )//2 + zmesh * rotmat[0,0] + ymesh * rotmat[1,0] + xmesh * rotmat[2,0] + imsize[2]//2 - m[0]
			# ymeshrot = ( 2 * imsize[1] - imsize[1] )//2 + zmesh * rotmat[0,1] + ymesh * rotmat[1,1] + xmesh * rotmat[2,1] + imsize[1]//2 - m[1]
			# xmeshrot = ( 2 * imsize[0] - imsize[0] )//2 + zmesh * rotmat[0,2] + ymesh * rotmat[1,2] + xmesh * rotmat[2,2] + imsize[0]//2 - m[2]

			# img2 = Resize( img, newsize=imsize * 2 )

			# print xmeshrot.min(),xmeshrot.max()
			# print ymeshrot.min(),ymeshrot.max()
			# print zmeshrot.min(),zmeshrot.max()

			rotimg = np.zeros( img2.shape )

			if interpolation == 'nearest':

				rotimg = img2[ np.round( xmeshrot ).astype('int'), np.round( ymeshrot ).astype('int'), np.round( zmeshrot ).astype('int') ]

			else:

				x0 = np.floor( xmeshrot ).astype( 'int' )
				x1 = np.ceil( xmeshrot ).astype( 'int' )
				y0 = np.floor( ymeshrot ).astype( 'int' )
				y1 = np.ceil( ymeshrot ).astype( 'int' )
				z0 = np.floor( zmeshrot ).astype( 'int' )
				z1 = np.ceil( zmeshrot ).astype( 'int' )

				import warnings
				with warnings.catch_warnings():
					warnings.filterwarnings( "ignore", category=RuntimeWarning )

					xd = np.nan_to_num( ( xmeshrot - x0 ) / ( x1 - x0 ) )
					yd = np.nan_to_num( ( ymeshrot - y0 ) / ( y1 - y0 ) )
					zd = np.nan_to_num( ( zmeshrot - z0 ) / ( z1 - z0 ) )

				if interpolation == 'cosine': # Smoother than trilinear at negligible extra computation cost?

					xd = ( 1 - np.cos( xd * np.pi) ) / 2
					yd = ( 1 - np.cos( yd * np.pi) ) / 2
					zd = ( 1 - np.cos( zd * np.pi) ) / 2

				# c000 = img2[x0, y0, z0]
				# c001 = img2[x0, y0, z1]
				# c010 = img2[x0, y1, z0]
				# c011 = img2[x0, y1, z1]
				# c100 = img2[x1, y0, z0]
				# c101 = img2[x1, y0, z1]
				# c110 = img2[x1, y1, z0]
				# c111 = img2[x1, y1, z1]

				# c00 = c000 * ( 1 - xd ) + c100 * xd
				# c01 = c001 * ( 1 - xd ) + c101 * xd
				# c10 = c010 * ( 1 - xd ) + c110 * xd
				# c11 = c011 * ( 1 - xd ) + c111 * xd

				# c0 = c00 * ( 1 - yd ) + c10 * yd
				# c1 = c01 * ( 1 - yd ) + c11 * yd

				# c = c0 * ( 1 - zd ) + c1 * zd

				# Below is the same as the commented above, but in one line:
				rotimg = ( ( img2[x0, y0, z0] * ( 1 - xd ) + img2[x1, y0, z0] * xd ) * ( 1 - yd ) + ( img2[x0, y1, z0] * ( 1 - xd ) + img2[x1, y1, z0] * xd ) * yd ) * ( 1 - zd ) + ( ( img2[x0, y0, z1] * ( 1 - xd ) + img2[x1, y0, z1] * xd ) * ( 1 - yd ) + ( img2[x0, y1, z1] * ( 1 - xd ) + img2[x1, y1, z1] * xd ) * yd ) * zd

	rotimg = Resize( rotimg, newsize=imsize )

	return rotimg
	# return Resample( rotimg, apix=1.0 / pad_factor, newapix=1.0 )

def RotationalAverage( img ):
# Compute the rotational average of a 2D image or 3D volume

	rmesh = RadialIndices( img.shape, rounding=True )[0]

	rotavg = np.zeros( img.shape )

	for r in np.unique( rmesh ):

		idx = rmesh == r
		rotavg[idx] = img[idx].mean()

	return rotavg

def RadialProfile( img, amps=False ):
# Compute the 1D radial profile of a 2D image or 3D volume:
# 'amps' is a flag to tell whether we want a radial profile of the Fourier amplitudes

	orgshape = img.shape

	if amps:

		# img = np.abs( np.fft.fftshift( np.fft.fftn( img ) ) )
		img = np.abs( np.fft.rfftn( img ) )
		rfft = True

	else:

		rfft = False


	rmesh = RadialIndices( orgshape, rounding=True, rfft=rfft )[0]
	# print img.shape,rmesh.shape

	profile = np.zeros( len( np.unique( rmesh ) ) )
	# j = 0
	for j,r in enumerate( np.unique( rmesh ) ):

		idx = rmesh == r
		profile[j] = img[idx].mean()
		# j += 1

	return profile

def RadialFilter( img, filt, return_filter = False ):
# Given a list of factors 'filt', radially multiplies the Fourier Transform of 'img' by the corresponding term in 'filt'

	rmesh = RadialIndices( img.shape, rounding=True, rfft=True )[0]

	ft = np.fft.rfftn( img )
	# print len(np.unique( rmesh )),len(filt)
	# j = 0
	for j,r in enumerate( np.unique( rmesh ) ):

		idx = rmesh == r
		ft[idx] *= filt[j]
		# j += 1

	if return_filter:

		filter2d = np.zeros( rmesh.shape )
		# j = 0
		for j,r in enumerate( np.unique( rmesh ) ):

			idx = rmesh == r
			filter2d[idx] = filt[j]
			# j += 1

	if not return_filter:

		return np.fft.irfftn( ft, s=img.shape )

	else:

		return np.fft.irfftn( ft, s=img.shape ), filter2d

def SoftMask( imsize = [100, 100], radius = 0.5, width = 6.0, rounding=False, xyz=[0,0,0], rfft=False ):
# Generates a circular or spherical mask with a soft cosine edge
# If rfft==True, the output shape will not be imsize, be the shape of an rfft of input shape imsize

	if np.isscalar(imsize):

		imsize = [imsize, imsize]

	if len(imsize) > 3:

		raise ValueError ( "Object should have 2 or 3 dimensions: len(imsize) = %d " % len(imsize))

	rmesh = RadialIndices( imsize, rounding=rounding, xyz=xyz, rfft=rfft )[0]

	if width < 0.0:

		width = 0.0

	if width > 0.0 and width < 1.0:

		width = 0.5 * width * np.min( imsize )

	if radius > 0.0 and radius < 1.0:

		radius = radius * np.min( imsize )

		radius *= 0.5

	if ( radius < 0.0 ) or ( np.min( imsize ) < radius*2 ):

		radius = 0.5 * ( np.min( imsize ) - float(width)/2 )

	rii = radius + width/2
	rih = radius - width/2

	mask = np.zeros( rmesh.shape )

	fill_idx = rmesh <= rih
	mask[fill_idx] = 1.0

	rih_idx = rmesh > rih
	rii_idx = rmesh <= rii
	edge_idx = rih_idx * rii_idx

	mask[edge_idx] = ( 1.0 + np.cos( np.pi * ( rmesh[edge_idx] - rih ) / (width) ) ) / 2.0
	# print mask[edge_idx]

	return mask

def AutoMask( img, apix=1.0, lp=-1, gaussian=False, cosine=True, cosine_edge_width=3.0, absolute_threshold=None, fraction_threshold=None, sigma_threshold=1.0, expand_width = 3.0, expand_soft_width = 3.0, floodfill_rad=-1, floodfill_xyz=[0,0,0], floodfill_fraction=-1, verbose=False ):
# Creates a "smart" soft mask based on an input volume.
# Similar to EMAN2 mask.auto3d processor and relion_mask_create.

	# if type( lp ) == str:

	# 	if lp.lower() == 'auto':

	# 		# lp = 10 * apix # Auto low-pass filtering value (ad-hoc)
	# 		lp = 14.0 # Works well in most cases

	# First we low-pass filter the volume with a Gaussian or Cosine-edge filter:
	if gaussian:

		imglp = FilterGauss( img, apix=apix, lp=lp )
		filter_type = "Gaussian."

	else:

		imglp = FilterCosine( img, apix=apix, lp=lp, width=cosine_edge_width )
		filter_type = "cosine-edge across %.1f Fourier voxels." % cosine_edge_width


	# Then we define a threshold for binarization of the low-pass filtered map:
	if absolute_threshold != None:

		thr = absolute_threshold # Simply take a user-specified value as threshold
		method = "absolute value"

	elif fraction_threshold != None:

		thr = np.sort( np.ravel( imglp ) )[np.round( ( 1.0 - fraction_threshold ) * np.prod( imglp.shape ) ).astype( 'int' )] # Binarize the voxels with the top fraction_threshold densities
		method = "highest %.1f percent of densities" % ( fraction_threshold * 100 )

	elif sigma_threshold != None:

		thr = imglp.mean() + sigma_threshold * imglp.std() # Or define as threshold a multiple of standard deviations above the mean density value

		method = "%.3f standard deviations above the mean" % sigma_threshold

	else:

		thr = 0.0

	if verbose:

		print( "\nAUTO-MASKING INFO:" )
		print( "Input volume will be low-pass filtered at %.2f A by a %s" % ( lp, filter_type ) )
		print( "Stats of input volume before low-pass:\nMin=%.6f, Max=%.6f, Median=%.6f, Mean=%.6f, Std=%.6f" % ( img.min(), img.max(), np.median( img ), img.mean(), img.std() ) )
		print( "Stats of input volume after low-pass (for binarization):\nMin=%.6f, Max=%.6f, Median=%.6f, Mean=%.6f, Std=%.6f" % ( imglp.min(), imglp.max(), np.median( imglp ), imglp.mean(), imglp.std() ) )
		print( "Thresholding method: %s" % method)
		print( "Threshold for initial binarization: %.6f" % thr )
		print( "Binary mask will be expanded by %.1f voxels plus a soft cosine-edge of %.1f voxels." % (expand_width, expand_soft_width) )

	if floodfill_rad < 0 and floodfill_fraction < 0:

		if verbose:

			print( "Binarizing the low-pass filtered volume..." )

		imglpbin = imglp > thr # Binarize the low-pass filtered map with one of the thresholds above

	else:

		if floodfill_fraction < 0:

			if verbose:

				print( "Initializing flood-filling method with a sphere of radius %.1f voxels placed at [%d, %d, %d]..." % ( floodfill_rad, floodfill_xyz[0], floodfill_xyz[1], floodfill_xyz[2] ) )

			inimask = SoftMask( imglp.shape, radius=floodfill_rad, width=0, xyz=floodfill_xyz ) # This will be the initial mask

		else:

			if verbose:

				print( "Initializing flood-filling method binarizing the highest %.1f percent of densities..." % ( floodfill_fraction * 100 ) )

			floodfill_fraction_thr = np.sort( np.ravel( imglp ) )[np.round( ( 1.0 - floodfill_fraction ) * np.prod( imglp.shape ) ).astype( 'int' )] # Binarize the voxels with the top floodfill_fraction densities

			inimask = imglp > floodfill_fraction_thr # Binarize the low-pass filtered map with one of the thresholds above

		imglpbin = FloodFilling( imglp, inimask, thr=thr ) # Binarize the low-pass filtered map using flood-filling approach, works better on non low-pass filtered volumes.

	if expand_width > 0:

		expand_kernel = SoftMask( imglp.shape, radius=expand_width, width=0 ) # Creates a kernel for expanding the binary mask

		mask_expanded = np.fft.fftshift( np.fft.irfftn( np.fft.rfftn( imglpbin ) * np.fft.rfftn( expand_kernel ) ).real ) > 1e-6 # To prevent residual non-zeros from FFTs

	else:

		mask_expanded = imglpbin

	mask_expanded_prev = mask_expanded
	mask_expanded_soft = mask_expanded

	# Expanding with a soft-edge is the same as above but in a loop, 1-voxel-shell at a time, multiplying by a cosine:
	expand_kernel = SoftMask( mask_expanded_prev.shape, radius=1, width=0 )
	if expand_soft_width > 0:

		for i in np.arange( 1, np.round( expand_soft_width ) + 1 ):
		# for i in np.arange( np.round( expand_soft_width ) ):

			mask_expanded_new = np.fft.fftshift( np.fft.irfftn( np.fft.rfftn( mask_expanded_prev ) * np.fft.rfftn( expand_kernel ) ).real ) > 1e-6  # To prevent residual non-zeros from FFTs

			mask_expanded_soft = mask_expanded_soft + ( mask_expanded_new - mask_expanded_prev ) * ( 1.0 + np.cos( np.pi * i / (expand_soft_width + 1) ) ) / 2.0
			# print ( 1.0 + np.cos( np.pi * ( i ) / (expand_soft_width+1) ) ) / 2.0

			mask_expanded_prev = mask_expanded_new

	if verbose:

		print( "Auto-masking done!\n" )

	return mask_expanded_soft

def FloodFilling( img, inimask, thr=0.0 ):
# "Smart" growing of binary volume based on flood-filling algorithm.
# Similar to mask.auto3d processor in EMAN2
	
	# mask = SoftMask( img.shape, radius=rad, width=0, xyz=xyz ) # This will be the initial mask
	mask = inimask
	expand_kernel = SoftMask( img.shape, radius=1, width=0 )
	# print np.sum(mask)

	mask_expanded_prev = mask
	r = 1
	while True:

		# spherenew = SoftMask( img.shape, radius=rad+r, width=0, xyz=xyz )
		mask_expanded_new = np.fft.fftshift( np.fft.irfftn( np.fft.rfftn( mask_expanded_prev ) * np.fft.rfftn( expand_kernel ) ).real ) > 1e-6  # To prevent residual non-zeros from FFTSs
		shell = mask_expanded_new - mask_expanded_prev
		imgshell = img * shell
		shellbin = imgshell > thr
		if np.any( shellbin ):

			mask = mask + shellbin
			mask_expanded_prev = mask

			# print("Expanded mask by %d voxels..." % r)
			# print("Total voxels included: %d" % mask.sum())

		else:

			break

		r += 1

	return mask

def FilterGauss( img, apix=1.0, lp=-1, hp=-1, return_filter=False ):
# Gaussian band-pass filtering of images.

	rmesh = RadialIndices( img.shape, rounding=False, normalize=True, rfft=True )[0] / apix
	rmesh2 = rmesh*rmesh

	if lp <= 0.0:

		lowpass = 1.0

	else:

		lowpass = np.exp( - lp ** 2 * rmesh2 / 2 )

	if hp <= 0.0:

		highpass = 1.0

	else:

		highpass = 1.0 - np.exp( - hp ** 2 * rmesh2 / 2 )

	bandpass = lowpass * highpass

	ft = np.fft.rfftn( img )

	filtered = np.fft.irfftn( ft * bandpass, s=img.shape )

	if return_filter:

		return filtered, bandpass

	else:

		return filtered

def FilterBfactor( img, apix=1.0, B=0.0, return_filter=False ):
# Applies a B-factor to images. B can be positive or negative.

	rmesh = RadialIndices( img.shape, rounding=False, normalize=True, rfft=True )[0] / apix
	rmesh2 = rmesh*rmesh

	bfac = np.exp( - (B * rmesh2  ) /  4  )

	ft = np.fft.rfftn( img )

	filtered = np.fft.irfftn( ft * bfac, s=img.shape )

	if return_filter:

		return filtered, bfac

	else:

		return filtered

def FilterDoseWeight( stack, apix=1.0, frame_dose=1.0, pre_dose = 0.0, total_dose=-1, kv=300.0 ):
# Applies Dose-Weighting filter on a stack of movie frames (Grant & Grigorieff, eLife 2015)
# stack is sequence of aligned movie frames (e.g. as generated by MotionCor2)
# frame_dose is the dose-per-frame (electrons per A^2)
# pre_dose is the total dose to which the movie has been pre-exposed before the first frame (e.g. if the first frame was discarded by MotionCor2)
# total_dose is the desired total dose for the dose-weighted average. If <= zero, will be the total dose of the movie.

	
	n_frames = stack.shape[0]

	if total_dose <= 0:

		total_dose = frame_dose * n_frames

	rmesh = RadialIndices( stack[0].shape, rounding=False, normalize=True, rfft=True )[0] / apix
	# rmesh2 = rmesh*rmesh


	a = 0.245
	b = -1.665
	c = 2.81

	critical_dose = a * ( rmesh ** b ) + c  # Determined at 300 kV
	# kv_factor = 1.0 - ( 300.0 - kv ) * ( 1.0 - 0.8 ) / ( 300.0 - 200.0 ) # This linear approximation is valid in the range 200 - 300 kV, probably not outside it
	kv_factor = 1.0 - ( 300.0 - kv ) * 0.002
	critical_dose *= kv_factor
	optimal_dose = 2.51284 * critical_dose # See electron_dose.f90 in Unblur source code for derivation details, and the paper as well where it says it is ~2.5x the critical_dose

	sum_q2 = np.zeros( rmesh.shape )
	dw_filtered = np.zeros( rmesh.shape ).astype( 'complex128' )
	for i in np.arange( 1, n_frames + 1 ):

		current_dose = ( i * frame_dose ) + pre_dose

		dose_diff = current_dose - total_dose
		if dose_diff > 0 and dose_diff < frame_dose:

			current_dose = total_dose

			stack[i-1] *= ( frame_dose - dose_diff ) / frame_dose # We may have to downweight the last frame to be added to achieve exactly the desired total dose

		if current_dose <= total_dose:
			
			q = np.exp( -0.5 * current_dose / critical_dose )
			q[ optimal_dose < current_dose ] = 0.0 # We cut out all frequencies that have exceeded the optimal dose in the current frame, because it would add just noise

			dw_filtered += q * np.fft.rfftn( stack[i-1] )
			sum_q2 += q * q

	dw_filtered /= np.sqrt( sum_q2 ) # Eq. 9

	dw_avg = np.fft.irfftn( dw_filtered, s=stack[0].shape )

	# if return_filter:

	# 	return dw_avg, bfac

	# else:

	return dw_avg

def FilterCosine( img, apix=1.0, lp=-1, hp=-1, width=6.0, return_filter=False ):
# Band-pass filtering of images with a cosine edge. Good to approximate a top-hat filter while still reducing edge artifacts.

	if width < 0.0:

		width = 0.0

	if width > 0.0 and width <= 1.0:

		width = 0.5 * width * np.min( img.shape )

	if lp <= 0.0:

		lowpass = 1.0

	else:

		lowpass = SoftMask( img.shape, radius=np.min( img.shape ) * apix/lp, width=width, rfft=True )

	if hp <= 0.0:

		highpass = 1.0

	else:

		highpass = 1.0 - SoftMask( img.shape, radius=np.min( img.shape ) * apix/hp, width=width, rfft=True )

	bandpass = lowpass * highpass

	# ft = np.fft.fftshift( np.fft.fftn( img ) )

	# filtered = np.fft.ifftn( np.fft.ifftshift( ft * bandpass ) )

	ft = np.fft.rfftn( img )

	# print ft.shape, bandpass.shape

	filtered = np.fft.irfftn( ft * bandpass )

	if return_filter:

		return filtered.real, bandpass

	else:

		return filtered.real

def FilterTophat( img, apix=1.0, lp=-1, hp=-1, return_filter=False ):
# Just a wrapper to the cosine filter with a hard edge:

	return FilterCosine( img, apix=apix, lp=lp, hp=hp, width=0.0, return_filter=False )

def HighResolutionNoiseSubstitution( img, apix=1.0, lp=-1, parallel=False ):
# Randomizes the phases of a map beyond resolution 'lp'
# If calling many times in parallel, make sure to set the 'parallel' flag to True

	# Get resolution shells:
	rmesh = RadialIndices( img.shape, rounding=False, normalize=True, rfft=True )[0] / apix

	lp = 1.0/lp

	ft = np.fft.rfftn( img )

	# Decompose Fourier transform into amplitudes and phases:
	amps = np.absolute( ft )
	phases = np.angle( ft )

	idx = rmesh > lp # Select only terms beyond desired resolution (not inclusive)

	if lp > 0.0:

		if parallel:
			
			# Just to make sure that parallel jobs launched nearly at the same time won't get the same seed
			np.random.seed()

		# numpy.random.seed( seed=123 ) # We have to enforce the random seed otherwise different runs would not be comparable
		phasesrnd = np.random.random( phases.shape ) * 2.0 * np.pi # Generate random phases in radians

		phases[idx] = phasesrnd[idx]

	ftnew = amps * ( np.cos( phases ) + 1j*np.sin( phases ) )

	return np.fft.irfftn( ftnew, s=img.shape )

def Resample( img, newsize=None, apix=1.0, newapix=None ):
# Resizes a real image or volume by cropping/padding its Fourier Transform, i.e. resampling.

	size = np.array( img.shape )

	if newsize == None and newapix == None:

		newsize = img.shape
		newapix = apix

	elif newapix != None:
		# This will be the new image size:
		newsize = np.round( size * apix / newapix ).astype( 'int' )

	# First calculate the forward FT:
	ft = np.fft.fftn( img )
	# Now FFT-shift to have the zero-frequency in the center:
	ft = np.fft.fftshift( ft )

	# if newapix >= apix:
	# 	# Crop the FT if downsampling:
	# 	if len( img.shape ) == 2:
	# 		ft = ft[size[0]/2-newsize[0]/2:size[0]/2+newsize[0]/2+newsize[0]%2, size[1]/2-newsize[1]/2:size[1]/2+newsize[1]/2+newsize[1]%2]
	# 	elif len( img.shape ) == 3:
	# 		ft = ft[size[0]/2-newsize[0]/2:size[0]/2+newsize[0]/2+newsize[0]%2, size[1]/2-newsize[1]/2:size[1]/2+newsize[1]/2+newsize[1]%2, size[2]/2-newsize[2]/2:size[2]/2+newsize[2]/2+newsize[2]%2]
	# 	else:
	# 		raise ValueError( "Object should have 2 or 3 dimensions: len(imsize) = %d " % len(imsize))


	# elif newapix < apix:
	# 	# Pad the FT with zeroes if upsampling:
	# 	if len( img.shape ) == 2:
	# 		ft = np.pad( ft, ( ( newsize[0]/2-img.shape[0]/2, newsize[0]/2-img.shape[0]/2+newsize[0]%2 ), ( newsize[1]/2-img.shape[1]/2, newsize[1]/2-img.shape[1]/2+newsize[1]%2 ) ), 'constant' )
	# 	elif len( img.shape ) == 3:
	# 		ft = np.pad( ft, ( ( newsize[0]/2-img.shape[0]/2, newsize[0]/2-img.shape[0]/2+newsize[0]%2 ), ( newsize[1]/2-img.shape[1]/2, newsize[1]/2-img.shape[1]/2+newsize[1]%2 ), ( newsize[2]/2-img.shape[2]/2, newsize[2]/2-img.shape[2]/2+newsize[2]%2 ) ), 'constant' )
	# 	else:
	# 		raise ValueError( "Object should have 2 or 3 dimensions: len(imsize) = %d " % len(imsize))

	# Crop or pad the FT to obtain the new sampling:
	ft = Resize( ft, newsize )

	# Restore the ordering of the FT as expected by ifftn:
	ft = np.fft.ifftshift( ft )

	# We invert the cropped-or-padded FT to get the desired result, only the real part to be on the safe side:
	return np.fft.ifftn( ft  ).real

def NormalizeImg( img, mean=0.0, std=1.0, radius=-1 ):
# Normalizes an image to specified mean and standard deviation:
# If 'radius' is specified, will use only the area outside the circle with this radius to calculate 'mean' and 'std'
# which is the way RELION expects images to be normalized

	if radius > 0.0:

		mask = SoftMask( img.shape, radius = radius, width = 0, rounding=False ).astype('int')
		mask = 1 - mask # Get only the area outside the disk
		m = img[mask].mean()
		s = img[mask].std()

	else:

		m = img.mean()
		s = img.std()

	return (img - m + mean) * std / s

def FCC( volume1, volume2, phiArray = [0.0], invertCone = False, xy_only = False, z_only = False ):
	"""
	Fourier conic correlation

	Created on Fri Dec  4 16:35:42 2015
	@author: Robert A. McLeod

	Modified by: Ricardo Righetto
	Date of modification: 23.02.2017 
	Change: now also supports (conical) FRC

	Returns FCC_normed, which has len(phiArray) Fourier conic correlations
	"""

	import warnings
	with warnings.catch_warnings():
		warnings.filterwarnings( "ignore", category=RuntimeWarning )

		m = np.mod(volume1.shape, 2) # Check if dimensions are odd or even

		if volume1.ndim == 3:

			[M,N,P] = volume1.shape
			[zmesh, ymesh, xmesh] = np.mgrid[ -M/2:M/2, -N/2:N/2, -P/2:P/2  ]
			# # The below is for RFFT implementation which is faster but gives numerically different results that potentially affect resolution estimation, DO NOT USE.
			# # The above is consistent with other programs such as FREALIGN v9.11 and relion_postprocess.
			# [zmesh, ymesh, xmesh] = np.mgrid[-M//2+m[0]:(M-1)//2+1, -N//2+m[1]:(N-1)//2+1, 0:P//2+1]
			# zmesh = np.fft.ifftshift( zmesh )
			# ymesh = np.fft.ifftshift( ymesh )

			rhomax = np.int( np.ceil( np.sqrt( M*M/4.0 + N*N/4.0 + P*P/4.0) ) + 1 )
			if xy_only:
				zmesh *= 0
				rhomax = np.int( np.ceil( np.sqrt( N*N/4.0 + P*P/4.0) ) + 1 )
			if z_only:
				xmesh *= 0
				ymesh *= 0
				rhomax = rhomax = np.int( np.ceil( np.sqrt( M*M/4.0 ) ) + 1 )
			rhomesh = np.sqrt( xmesh*xmesh + ymesh*ymesh + zmesh*zmesh )
			phimesh = np.arccos( zmesh / rhomesh )
			phimesh[M/2,N/2,P/2] = 0.0
			phimesh = np.ravel( phimesh )

		elif volume1.ndim == 2:

			[M,N] = volume1.shape
			[ymesh, xmesh] = np.mgrid[ -M/2:M/2, -N/2:N/2  ]
			rhomax = np.int( np.ceil( np.sqrt( M*M/4.0 + N*N/4.0 ) ) + 1 )
			rhomesh = np.sqrt( xmesh*xmesh + ymesh*ymesh )
			phimesh = np.arctan2( ymesh, xmesh )
			phimesh[M/2,N/2] = 0.0
			phimesh = np.ravel( phimesh )

		else:

			raise RuntimeError("Error: FCC only supports 2D and 3D objects.")

	phiArray = np.deg2rad( phiArray )

	rhoround = np.round( rhomesh.ravel() ).astype( 'int' ) # Indices for bincount
	# rhomax = np.int( np.ceil( np.sqrt( M*M/4.0 + N*N/4.0 + P*P/4.0) ) + 1 )

	fft1 = np.ravel( np.fft.fftshift( np.fft.fftn( volume1 ) )  )
	conj_fft2 = np.ravel( np.fft.fftshift( np.fft.fftn( volume2 ) ).conj()  )

	# # RFFT implementation faster but gives numerically different results that potentially affect resolution estimation, DO NOT USE.
	# # The above is consistent with other programs such as FREALIGN v9.11 and relion_postprocess.
	# fft1 = np.ravel( np.fft.rfftn( volume1 ) )
	# conj_fft2 = np.ravel( np.fft.rfftn( volume2 ) ).conj()

	FCC_normed = np.zeros( [rhomax, len(phiArray)] )
	for J, phiAngle in enumerate( phiArray ):

		if phiAngle == 0.0:
			fft1_conic = fft1
			conj_fft2_conic = conj_fft2
			rhoround_conic = rhoround
		else:
			conic = np.ravel( (phimesh <= phiAngle ) + ( (np.abs(phimesh - np.pi)) <= phiAngle )  )
			if invertCone:
				conic = np.invert( conic )
			rhoround_conic = rhoround[conic]
			fft1_conic = fft1[conic]
			conj_fft2_conic = conj_fft2[conic]

		FCC = np.bincount( rhoround_conic, np.real(fft1_conic * conj_fft2_conic) )
		Norm1 = np.bincount( rhoround_conic, np.abs(fft1_conic)*np.abs(fft1_conic) )
		Norm2 = np.bincount( rhoround_conic, np.abs(conj_fft2_conic)*np.abs(conj_fft2_conic) )

		goodIndices = np.argwhere( (Norm1 * Norm2) > 0.0 )[:-1]
		FCC_normed[goodIndices,J] = FCC[goodIndices] / np.sqrt( Norm1[goodIndices] * Norm2[goodIndices] )

	return FCC_normed

def FSC( volume1, volume2, phiArray = [0.0] ):
# FSC is just a wrapper to FCC

	return FCC( volume1, volume2, phiArray = phiArray )

def FRC( image1, image2, phiArray = [0.0] ):
# FSC is just a wrapper to FRC

	return FCC( image1, image2, phiArray = phiArray )

def Resize( img, newsize=None, padval=None, xyz=[0,0,0] ):
# Resizes a real image or volume by cropping/padding. I.e. sampling is not changed.
# xyz is the origin or cropping the image (does not apply to padding)

	xyz = -np.flipud( xyz ) # The minus sign is to ensure the same conventions are followed as for RadialIndices() function.

	if np.any( newsize == None ):

		return img

	else:

		imgshape = np.array( img.shape )
		newshape = np.round( np.array( newsize ) ).astype( 'int' )

		if np.all( imgshape == newshape ):

			return img

		if padval == None:

			padval = 0

		if len( imgshape ) == 2:

			if newshape[0] <= imgshape[0]:

				newimg = img[imgshape[0]/2-newshape[0]/2-xyz[0]:imgshape[0]/2+newshape[0]/2+newshape[0]%2-xyz[0], :]

			else:

				newimg = np.pad( img, ( ( newshape[0]/2-imgshape[0]/2, newshape[0]/2-imgshape[0]/2+newshape[0]%2 ), ( 0, 0 ) ), 'constant', constant_values = ( padval, ) )

			if newshape[1] <= imgshape[1]:

				newimg = newimg[:, imgshape[1]/2-newshape[1]/2-xyz[1]:imgshape[1]/2+newshape[1]/2+newshape[1]%2-xyz[1]]

			else:

				newimg = np.pad( newimg, ( ( 0, 0 ), ( newshape[1]/2-imgshape[1]/2, newshape[1]/2-imgshape[1]/2+newshape[1]%2 ) ), 'constant', constant_values = ( padval, ) )

		elif len( imgshape ) == 3:

			if newshape[0] <= imgshape[0]:

				newimg = img[imgshape[0]/2-newshape[0]/2-xyz[0]:imgshape[0]/2+newshape[0]/2+newshape[0]%2-xyz[0], :, :]

			else:

				newimg = np.pad( img, ( ( newshape[0]/2-imgshape[0]/2, newshape[0]/2-imgshape[0]/2+newshape[0]%2 ), ( 0, 0 ), ( 0, 0 ) ), 'constant', constant_values = ( padval, ) )

			if newshape[1] <= imgshape[1]:

				newimg = newimg[:, imgshape[1]/2-newshape[1]/2-xyz[1]:imgshape[1]/2+newshape[1]/2+newshape[1]%2-xyz[1], :]

			else:

				newimg = np.pad( newimg, ( ( 0, 0 ), ( newshape[1]/2-imgshape[1]/2, newshape[1]/2-imgshape[1]/2+newshape[1]%2 ), ( 0, 0 ) ), 'constant', constant_values = ( padval, ) )

			if newshape[2] <= imgshape[2]:

				newimg = newimg[:, :, imgshape[2]/2-newshape[2]/2-xyz[2]:imgshape[2]/2+newshape[2]/2+newshape[2]%2-xyz[2]]

			else:

				newimg = np.pad( newimg, ( ( 0, 0 ), ( 0, 0 ), ( newshape[2]/2-imgshape[2]/2, newshape[2]/2-imgshape[2]/2+newshape[2]%2 ) ), 'constant', constant_values = ( padval, ) )

		else:

			raise ValueError( "Object should have 2 or 3 dimensions: len(imgshape) = %d " % len(imgshape))

	return newimg
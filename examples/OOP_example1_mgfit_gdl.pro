; Example: mgfit::detect_lines()
;     it multiple Gaussian functions to a list of emission 
;     lines using a least-squares minimization technique and 
;     a random walk method.
;
; Example of object-oriented programming (OOP) for
;     MGFIT object
; 
; --- Begin $MAIN$ program. ---------------
; 
; 

mg=obj_new('mgfit')

base_dir = '../'
input_dir = ['examples','example1','inputs']
output_dir = ['examples','example1','outputs']
image_dir = ['examples','example1','images']
input_file_B = filepath('PB6_flux_B.txt', root_dir=base_dir, subdir=input_dir )
input_file_R = filepath('PB6_flux_R.txt', root_dir=base_dir, subdir=input_dir )
image_output_path = filepath('', root_dir=base_dir, subdir=image_dir )
output_path = filepath('', root_dir=base_dir, subdir=output_dir )

mg->set_output_path, output_path
mg->set_image_output_path, image_output_path

; genetic algorithm settings
popsize=30.
pressure=0.3
generations=500.
; fitting interval setting
interval_wavelength=500
; redshift initial and tolerance
redshift_initial = 1.0
redshift_tolerance=0.001
; initial FWHM and tolerance
fwhm_initial=1.0
fwhm_tolerance=1.4;*fwhm_initial
fwhm_min=0.1
fwhm_max=1.8

mg->read_ascii, input_file_B, wavelB, fluxB
mg->read_ascii, input_file_R, wavelR, fluxR
loc1_B=where(wavelB le 5560.0)
loc1_R=where(wavelR gt 5560.0)
wavelR_max=max(wavelR)
loc1_R1=where(wavelR gt wavelR_max)

; add a free space at the end of the spectrum
wavelR2=wavelR_max+0.451660*(1+INDGEN(100))
fluxR2=wavelR2
fluxR2[*]=0.0
fluxB_loc1=where(fluxB lt 0.)
if fluxB_loc1[0] ne -1 then fluxB[fluxB_loc1]=0.0
fluxR_loc1=where(fluxR lt 0.)
if fluxR_loc1[0] ne -1 then fluxR[fluxR_loc1]=0.0
fluxB=fluxB*1.0e17
fluxR=fluxR*1.0e17
wavel=[wavelB[loc1_B], wavelR[loc1_R], wavelR2] ; concatenate wavelength arrays
flux=[fluxB[loc1_B], fluxR[loc1_R], fluxR2]  ; concatenate flux arrays

; increase the spectrum resolution by 10 times rebinning
rebin_resolution = 10

emissionlines = mg->detect_lines(wavel, flux, $
                                 popsize=popsize, pressure=pressure, $
                                 generations=generations, $
                                 rebin_resolution=rebin_resolution, $
                                 interval_wavelength=interval_wavelength, $
                                 redshift_initial=redshift_initial, $
                                 redshift_tolerance=redshift_tolerance, $
                                 fwhm_initial=fwhm_initial, $
                                 fwhm_tolerance=fwhm_tolerance, $
                                 fwhm_min=fwhm_min, fwhm_max=fwhm_max)

output_filename=output_path+'line_list'
mg->save_lines, emissionlines, output_filename

exit

; docformat = 'rst'

function mgfit_emis_err, syntheticspec, spectrumdata, emissionlines
;+
;     This function estimates the uncertainties introduced by the best-fit 
;     model residuals and the white noise quantified using the signal-dependent 
;     noise model of least-squares Gaussian fitting (Lenz & Ayres 1992; 
;     1992PASP..104.1104L) based on on the work of Landman, Roussel-Dupre, 
;     and Tanigawa (1982; 1982ApJ...261..732L).
;
; :Returns:
;    type=arrays of structures. This function returns the arrays of structures 
;                              { wavelength: 0.0, peak:0.0, sigma1:0.0, flux:0.0, 
;                                uncertainty:0.0, redshift:0.0, resolution:0.0, 
;                                blended:0, Ion:'', Multiplet:'', 
;                                LowerTerm:'', UpperTerm:'', g1:'', g2:''}
;
; :Params:
;     syntheticspec :     in, required, type=arrays of structures
;                         the synthetic spectrum made by mgfit_synth_spec() 
;                         stored in the arrays of structures {wavelength: 0.0, flux:0.0, residual:0.0}
;     
;     spectrumdata  :     in, required, type=arrays of structures
;                         the observed spectrum stored in the arrays 
;                         of structures {wavelength: 0.0, flux:0.0, residual:0.0}
;     
;     emissionlines :     in, required, type=arrays of structures    
;                         the emission lines specified for error estimation 
;                         stored in the arrays of structures 
;                         { wavelength: 0.0, 
;                           peak:0.0, 
;                           sigma1:0.0, 
;                           flux:0.0, 
;                           uncertainty:0.0, 
;                           redshift:0.0, 
;                           resolution:0.0, 
;                           blended:0, 
;                           Ion:'', 
;                           Multiplet:'', 
;                           LowerTerm:'', 
;                           UpperTerm:'', 
;                           g1:'', 
;                           g2:''}
;
; :Examples:
;    For example::
;
;     IDL> emissionlines_section=mgfit_emis_err(syntheticspec_section, spec_section, emissionlines_section)
;
; :Categories:
;   Emission, Uncertainty
;
; :Dirs:
;  ./
;      Main routines
;
; :Author:
;   Ashkbiz Danehkar
;
; :Copyright:
;   This library is released under a GNU General Public License.
;
; :Version:
;   0.1.0
;
; :History:
;     20/07/2014, A. Danehkar, Adopted from Algorithm used 
;                              in the FORTRAN program ALFA by R. Wessson
;     
;     12/04/2015, A. Danehkar, Performance optimized for IDL.
;     
;     20/08/2016, A. Danehkar, Added better performance in noise estimation.
;     
;     22/10/2016, A. Danehkar,  Fixed small bugs.
;     
;     22/02/2016, A. Danehkar, Uncertainties estimation added.
;     
;     15/10/2016, A. Danehkar, Fixed small bugs.
;     
;     21/06/2017, A. Danehkar, Some modifications.
;-
  temp=size(spectrumdata,/DIMENSIONS)
  speclength=temp[0]
  residuals = fltarr(speclength)
  
  ;continuum=mgfit_contin(spectrumdata)
  ;spectrumdata.flux=spectrumdata.flux-continuum.flux
  ;negetive_loc=where(spectrumdata.flux lt 0.0)
  ;spectrumdata[negetive_loc].flux=0.0
  
  residuals=spectrumdata.flux-syntheticspec.flux
  
  strong_line=min(where(emissionlines.peak eq max(emissionlines.peak))) 
  resolution_initial=emissionlines[strong_line].resolution
  
  sigma1=emissionlines[strong_line].wavelength/resolution_initial
  fwhm=2*sqrt(2*alog(2))*emissionlines[strong_line].sigma1

  w_helf=2*sqrt(2*alog(2))
  profile_loc=where(spectrumdata.wavelength ge (emissionlines[strong_line].wavelength-w_helf*fwhm) and spectrumdata.wavelength le (emissionlines[strong_line].wavelength+w_helf*fwhm) )
  temp=size(profile_loc,/DIMENSIONS)
  residuals_num=temp[0]
  residuals_num1=long(residuals_num/2)
  residuals_num=2*residuals_num1
  residuals_num2=long(3./4.*residuals_num)
  
  if residuals_num lt speclength then begin
    for i=residuals_num1,speclength-residuals_num1-1 do begin
      residuals_select=abs(residuals[i-residuals_num1:i+residuals_num1-1])
      residuals_sort=sort(residuals_select)
      residuals_select=residuals_select[residuals_sort]
      rms_noise=(total(residuals_select[0:residuals_num2-1]^2)/float(residuals_num2))^0.5
      spectrumdata[i].residual=rms_noise
    endfor
    spectrumdata[0:residuals_num-1].residual=spectrumdata[residuals_num].residual
  endif else begin
    residuals_select=abs(residuals[0:speclength-1])
    residuals_sort=sort(residuals_select)
    residuals_select=residuals_select[residuals_sort]
    rms_noise=(total(residuals_select[0:speclength-1]^2)/float(speclength))^0.5
    spectrumdata[*].residual=rms_noise
  endelse
  
  temp=size(spectrumdata.residual,/DIMENSIONS)
  residual_size=temp[0]
  spectrumdata[residual_size-residuals_num-1:residual_size-1].residual=spectrumdata[residual_size-residuals_num-2].residual
  ;spectrumdata[residual_size-residuals_num-1:residual_size-1].residual=spectrumdata[residual_size-residuals_num-0].residual
  
  temp=size(emissionlines,/DIMENSIONS)
  if size(temp,/DIMENSIONS) gt 1 then begin
    fit_uncertainty_size=temp[1]
  endif else begin
    fit_uncertainty_size=temp[0]
  endelse
  
  for i=0,fit_uncertainty_size-1 do begin
    waveindex=minloc_idl(abs(spectrumdata.wavelength-emissionlines[i].wavelength),first=1)
    ;if (spectrumdata[waveindex].residual ne 0.0) then begin
    if (emissionlines[i].peak ne 0.0) and (emissionlines[i].resolution ne 0.0) then begin
      ; Equation (1) in Lenz & Ayres 1992PASP..104.1104L 
      ; (1) Fourier Transform Spectrometer (FTS)
      ; (2) Hubble Space Telescope (HST)
      ; (3) International Ultraviolet Explorer (IUE)
      C_x= 0.67 ; C_x(FTS)=0.70, C_x(HST)=0.63, C_x(IUE)=0.64, C_x(all)=0.67
      emissionlines[i].sigma1=emissionlines[i].wavelength/emissionlines[i].resolution
      fwhm=2*sqrt(2*alog(2))*emissionlines[i].sigma1
      rms_noise=spectrumdata[waveindex].residual
      delta_wavelength=abs(spectrumdata[waveindex+1].wavelength - spectrumdata[waveindex].wavelength)
      peak_snr=emissionlines[i].peak/rms_noise
      line_snr=C_x*(fwhm/delta_wavelength)^0.5*peak_snr
      if line_snr ne 0 then begin
        emissionlines[i].flux= emissionlines[i].peak*emissionlines[i].sigma1*sqrt(2*!dpi)
        emissionlines[i].uncertainty=emissionlines[i].flux/line_snr
      endif else begin
        emissionlines[i].uncertainty=0.0
      endelse
    endif else begin
      emissionlines[i].uncertainty=0.0
    endelse
  endfor
  return, emissionlines
end

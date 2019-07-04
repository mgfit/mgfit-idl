; docformat = 'rst'

function mgfit_mutation1
;+
;     This function is for the genetic algorithm mutation type-1
;
; :Returns:
;     type=arrays. This function mutation rate.
;
; :Examples:
;    For example::
;
;     IDL> value=mgfit_mutation1()
;
; :Categories:
;   Genetic Algorithm
;
; :Dirs:
;  ./
;      Subroutines
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
;     20/07/2014, A. Danehkar, Translated to IDL from FORTRAN 
;                 in ALFA by R. Wessson
;- 
  common random_seed, seed
  value=1.0
  random = randomu(seed)
  if (random le 0.05) then begin
    value=1.*random
  endif 
  if (random ge 0.95) then begin
    value=2+(1.*(random-1))
  endif 
;  if (random le 0.02) then begin
;    value=1.*random
;  endif 
;  if (random ge 0.98) then begin
;    value=2+(1.*(random-1))
;  endif 
  return, value
end

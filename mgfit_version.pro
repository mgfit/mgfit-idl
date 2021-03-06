; docformat = 'rst'

;+
; Returns MGFIT version. This file is automatically edited 
; by the builder to include the revision.
;
; :Returns:
;    string
;
; :Keywords:
;    full : in, optional, type=boolean
;       set to return Subversion revision as well
;-
function mgfit_version, full=full
  compile_opt strictarr, hidden

  version = '0.1.0'
  revision = '-01f62b389'

  return, version + (keyword_set(full) ? (' ' + revision) : '')
end

;+
; NAME:
;       kmex_check_dates.pro
;
;
; PURPOSE:
;
;       check out the viability of dates given as inputs to the programs and
;       fuctions of the Kmex system
;
; AUTHOR:
;
;       Pedro Corona Romero
;       Instituto de Geofisica, Unidad Michoacan
;       UNAM, Campus Morelia
;       Antigua Carretera a Patzcuaro
;       Morelia, Michoacan, Mexico
;       piter.cr@gmail.com
;       Mexico, 5.v.mmxvii
;
; CATEGORY:
;
;       Numerical Data Analize
;
; CALLING SEQUENCE:
;
;       kmex_check_dates, initial[, final, STATION=station, ERROR_CODE=error_code, /QUIET, ERROR_MESSAGE=error_message]
;
;       Description:
;       Check out the usability of the input dates introduced by the user into the tools of the Kmex system.
;       The program also identifies CRITICAL ERRORS that the system cannot handle with.
;
;
; PARAMETERS:
;       ???????    : ?????????????
;
; KEYWORD PARAMETERS:
;
;       /????????? : ?????????????
;
; DEPENDENCIAS:
;       NONE
;
; INPUT FILES:
;       kmex/aux/GMS_code.dates
;
; OUTPUT FILES:
;       NONE
;
; HISTORIA:
;-






PRO geomagixs_check_dates, initial, final, ONE_DATE=one_date, $
                                           STATION=station, $
                                           QUIET=quiet
                                           
        On_error, 2
        COMPILE_OPT idl2, hidden
        
;##############################################################################
; initialize directories
;##############################################################################
        geomagixs_setup_commons, QUIET=quiet
        @geomagixs_commons
        

;##############################################################################
; depuring inputs
;##############################################################################
        geomagixs_check_gms, STATION=station, QUIET=quiet
        
        IF N_PARAMS() EQ 0 THEN BEGIN

                IF NOT keyword_set(quiet) THEN BEGIN
                        PRINT, FORMAT="('CRITICAL ERROR: conflict with input date(s), data inconsistent or invalid.')"
                        PRINT, FORMAT="('                impossible to proceed without a date or range of dates.')"
                ENDIF
                error.value[2] += 1
                error.log      += 'Missing date or range of dates, it is mandatory an input date. '
                RETURN
        ENDIF
        
        IF N_PARAMS() GT 2 THEN BEGIN
                IF NOT keyword_set(quiet) THEN BEGIN
                        PRINT, FORMAT="('CRITICAL ERROR: conflict with input date(s), data inconsistent or invalid.')"
                        PRINT, FORMAT="('                impossible to proceed with an ambiguoss range of dates.')"
                ENDIF
                error.value[2] += 1
                error.log      += 'Ambiguous range of dates, it is required only two input dates to define a time period. '
                RETURN

        ENDIF

        IF N_ELEMENTS(final) EQ 0 AND NOT keyword_set(one_date) THEN BEGIN

                IF NOT keyword_set(quiet) THEN BEGIN
                        PRINT, FORMAT="('CRITICAL ERROR: conflict with input date(s), data inconsistent or invalid.')"
                        PRINT, FORMAT="('                impossible to proceed without a well difined range of dates.')"
                ENDIF
                error.value[2] += 1
                error.log      += 'Missing final date. A range of dates requires both, Initial and Final input dates. '
                RETURN
        ENDIF

        IF N_ELEMENTS(final) EQ 3 AND NOT keyword_set(one_date) THEN BEGIN
        
                IF N_ELEMENTS(initial) NE N_ELEMENTS(final) THEN BEGIN
                        IF NOT keyword_set(quiet) THEN BEGIN
                                PRINT, FORMAT="('CRITICAL ERROR: conflict with input date(s), data inconsistent or invalid.')"
                                PRINT, FORMAT="('                input dates must have equal dimensions.')"
                        ENDIF
                        error.value[2] += 1
                        error.log      += 'Incopatibility between format of dates. Input dates must have the same dimensions. '
                        RETURN
                ENDIF
        
                IF N_ELEMENTS(initial) NE 3 THEN BEGIN
                        IF NOT keyword_set(quiet) THEN BEGIN
                                PRINT, FORMAT="('CRITICAL ERROR: conflict with input date(s), data inconsistent or invalid.')"
                                PRINT, FORMAT="('                input dates must have the format: [YYYY, MM, DD].')"
                        ENDIF
                        error.value[2] += 1
                        error.log      += 'Incopatibility of inputs format. Input dates must have the format: [YYYY, MM, DD]. '
                        RETURN
                ENDIF

                IF initial[1] LT 1 OR initial[1] GT 12 OR final[1] LT 1 OR final[1] GT 12 THEN BEGIN
                        IF NOT keyword_set(quiet) THEN BEGIN
                                PRINT, FORMAT="('CRITICAL ERROR: conflict with input date(s), data inconsistent or invalid.')"
                                PRINT, FORMAT="('                input months out of the range: 1<=MM<=12')"
                        ENDIF
                        error.value[2] += 1
                        error.log      += 'Invalid input months. Input months out of the range: 1<=MM<=12. '
                        RETURN
                ENDIF

                initial_n_days = julday(initial[1]+1,0,initial[0])-julday(initial[1],0,initial[0])
                final_n_days   = julday(final[1]+1,0,final[0])-julday(final[1],0,final[0])
                
                IF initial[2] LT 1 OR initial[2] GT initial_n_days OR final[2] LT 1 OR final[2] GT final_n_days THEN BEGIN
                        IF NOT keyword_set(quiet) THEN BEGIN
                                PRINT, FORMAT="('CRITICAL ERROR: conflict with input date(s), data inconsistent or invalid.')"
                                PRINT, FORMAT="('                input days out of the range: 1<=DD<=31')"
                        ENDIF
                        error.value[2] += 1
                        error.log      += 'Invalid input days. Input days out of the range: 1<=DD<=31. '
                        RETURN
                ENDIF

                ;IF 

                initial_year   = initial[0]
                initial_month  = initial[1]
                initial_day    = initial[2]

                final_year     = final[0]
                final_month    = final[1]
                final_day      = final[2]

                initial_JUL = JULDAY(initial_month, initial_day, initial_year)
                final_JUL   = JULDAY(final_month, final_day, final_year)
        
                IF final_JUL LT initial_JUL THEN BEGIN
                        IF NOT keyword_set(quiet) THEN BEGIN
                                PRINT, FORMAT="('CRITICAL ERROR: conflict with input date(s), data inconsistent or invalid.')"
                                PRINT, FORMAT="('                final date must be subsequent or equal to the initial date')"
                        ENDIF
                        error.value[0] += 1
                        error.log      += 'Invalid input dates order. Final date must be subsequent or equal to Initial date. '
                        RETURN
                ENDIF
        
                geomagixs_setup_dates, STATION=station, /QUIET, /force_all

                lower_JUL   = JULDAY(gms[system.gms].dates_data[0,1],gms[system.gms].dates_data[0,2],gms[system.gms].dates_data[0,0])
                upper_JUL   = JULDAY(gms[system.gms].dates_data[1,1],gms[system.gms].dates_data[1,2],gms[system.gms].dates_data[1,0])
                ;lower_JUL_st= JULDAY(system.qdays_dates[0,1],system.qdays_dates[0,2],system.qdays_dates[0,0])
                ;upper_JUL_st= JULDAY(system.qdays_dates[1,1],system.qdays_dates[1,2],system.qdays_dates[1,0])

                IF initial_JUL LT lower_JUL THEN BEGIN
                        tmp_string= STRING(gms[system.gms].dates_data[0,*], FORMAT='(I4,"/",I02,"/",I02)')
                        IF NOT keyword_set(quiet) THEN BEGIN
                                PRINT, FORMAT="('Input Warning: conflict with input date(s), data inconsistent or invalid.')"
                                PRINT, FORMAT="('               initial date should be subsequent to ',A,'.')", tmp_string
                        ENDIF
                        error.value[3] += 1
                        error.log      += 'Inconsistent initial date. Initial date should be subsequent or equal to '+tmp_string+' date. '
                        RETURN
                ENDIF
                
                IF initial_JUL GT upper_JUL THEN BEGIN
                        tmp_string= STRING(gms[system.gms].dates_data[1,*], FORMAT='(I4,"/",I02,"/",I02)')
                        IF NOT keyword_set(quiet) THEN BEGIN
                                PRINT, FORMAT="('Critical Error: Conflict with input data. Data inconsistent or invalid.')"
                                PRINT, FORMAT="('                initial date must be previous to ',A,'.')", tmp_string
                        ENDIF
                        error.value[2] += 1
                        error.log      += 'Invalid initial date. Initial date must be previous or equal to '+tmp_string+' date. '
                        RETURN
                ENDIF
                
                IF final_JUL GT upper_JUL THEN BEGIN
                        tmp_string= STRING(gms[system.gms].dates_data[1,*], FORMAT='(I4,"/",I02,"/",I02)')
                        IF NOT keyword_set(quiet) THEN BEGIN
                                PRINT, FORMAT="('Input Warning: conflict with input date(s), data inconsistent or invalid.')"
                                PRINT, FORMAT="('               final date should be previous to ',A,'.')", tmp_string
                        ENDIF
                        error.value[3] += 1
                        error.log      += 'Inconsistent final date. Final date should be previous or equal to '+tmp_string+' date. '
                        RETURN
                ENDIF
                
                IF final_JUL LT lower_JUL THEN BEGIN 
                        tmp_string= STRING(gms[system.gms].dates_data[0,*], FORMAT='(I4,"/",I02,"/",I02)')
                        IF NOT keyword_set(quiet) THEN BEGIN
                                PRINT, FORMAT="('Critical Error: Conflict with input data. Data inconsistent or invalid.')"
                                PRINT, FORMAT="('               final date must be subsequent to ',A,'.')", tmp_string
                        ENDIF
                        error.value[2] += 1
                        error.log      += 'Invalid final date. Final date must be subsequent or equal to '+tmp_string+' date. '
                        RETURN
                ENDIF
                
        ENDIF ELSE BEGIN
                IF N_ELEMENTS(initial) NE 3 THEN BEGIN
                        IF NOT keyword_set(quiet) THEN BEGIN
                                PRINT, FORMAT="('Critical Error: Conflict with input data. Data inconsistent or invalid.')"
                                PRINT, FORMAT="('                input dates must have the format: [YYYY, MM, DD].')"
                        ENDIF
                        error.value[2] += 1
                        error.log      += 'Invalid input-dates format. Input dates must have the format: [YYYY, MM, DD]. '
                        RETURN
                ENDIF

                IF initial[1] LT 1 OR initial[1] GT 12 THEN BEGIN
                        IF NOT keyword_set(quiet) THEN BEGIN
                                PRINT, FORMAT="('Critical Error: Conflict with input data. Data inconsistent or invalid.')"
                                PRINT, FORMAT="('                input months out of the range: 1<=MM<=12')"
                        ENDIF
                        error.value[2] += 1
                        error.log      += 'Invalid input months. Input months out of the range: 1<=MM<=12. '
                        RETURN
                ENDIF

                IF initial[2] LT 1 OR initial[2] GT 31 THEN BEGIN
                        IF NOT keyword_set(quiet) THEN BEGIN
                                PRINT, FORMAT="('Critical Error: Conflict with input data. Data inconsistent or invalid.')"
                                PRINT, FORMAT="('                input days out of the range: 1<=DD<=31')"
                        ENDIF
                        error.value[2] += 1
                        error.log      += 'Invalid input days. Input days out of the range: 1<=DD<=31. '
                        RETURN
                ENDIF

                initial_year   = initial[0]
                initial_month  = initial[1]
                initial_day    = initial[2]

                initial_JUL = JULDAY(initial_month, initial_day, initial_year)
        
                geomagixs_setup_dates, STATION=station, QUIET=quiet, /force_all

                lower_JUL   = JULDAY(gms[system.gms].dates_data[0,1],gms[system.gms].dates_data[0,2],gms[system.gms].dates_data[0,0])
                upper_JUL   = JULDAY(gms[system.gms].dates_data[1,1],gms[system.gms].dates_data[1,2],gms[system.gms].dates_data[1,0])
                ;lower_JUL_st= JULDAY(system.qdays_dates[0,1],system.qdays_dates[0,2],system.qdays_dates[0,0])
                ;upper_JUL_st= JULDAY(system.qdays_dates[1,1],system.qdays_dates[1,2],system.qdays_dates[1,0])



                IF initial_JUL LT lower_JUL THEN BEGIN
                        tmp_string= STRING(gms[system.gms].dates_data[0,*], FORMAT='(I4,"/",I02,"/",I02)')
                        IF NOT keyword_set(quiet) THEN BEGIN
                                PRINT, FORMAT="('Input Warning: conflict with input date(s), data inconsistent or invalid.')"
                                PRINT, FORMAT="('                input date must be subsequent to ',A,'.')", tmp_string
                        ENDIF
                        error.value[3] += 1
                        error.log      += 'Inconsistent input date. Input date must be subsequent or equal to '+tmp_string+' date. '
                        RETURN
                ENDIF
                
                IF initial_JUL GT upper_JUL THEN BEGIN
                        tmp_string= STRING(gms[system.gms].dates_data[1,*], FORMAT='(I4,"/",I02,"/",I02)')
                        IF NOT keyword_set(quiet) THEN BEGIN
                                PRINT, FORMAT="('Input Warning: conflict with input date(s), data inconsistent or invalid.')"
                                PRINT, FORMAT="('               input date must be previous to ',A,'; proceeding with predefined values and replacing conflictive values with data gaps.')", tmp_string
                        ENDIF
                        error.value[3] += 1
                        error.log      += 'Inconsistent input date. Input date must be previous or equal to '+tmp_string+' date. Proceeding with predefined values and replacing conflictive values with data gaps. '
                        RETURN
                ENDIF
        ENDELSE
        ;kmex_flag_dates = 1

RETURN

END

;+
; NAME:
;       ????????????????
;
;
; PURPOSE:
;
;       ????????????????
;
; AUTHOR:
;
;       Pedro Corona Romero
;       Instituto de Geofisica, UNAM
;       Tzinztuntzan 310, Morelia, Michoacan, Mexico
;       piter.cr@gmail.com
;       Mexico, 23.iii.mmx
;
; CATEGORY:
;
;       Numerical Data Analize
;
; CALLING SEQUENCE:
;
;       ?????????????????????
;
;       Description:
;       ???????????????????????
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
;       ?????????? : ????????????
;
; ARCHIVOS ANALIZADOS:
;       ??????????
;
; ARCHIVOS DE SALIDA:
;
; HISTORIA:
;



PRO check_error, NO_LOG=no_log, PROCESS=process
	On_error, 2
	COMPILE_OPT idl2, HIDDEN
	
        ;commons stantment        
        @cmegd_commons
        
        ;seting up system variables
        cmegd_setup

        IF TOTAL(system.error[0:2]) GT 0 THEN BEGIN
                PRINT, ''
                PRINT, FORMAT="('        # IMPOSSIBLE TO PROCEED: ', I02, ' Critial Errors detected!')", TOTAL(system.error[0:2])
                IF system.error[0] GT 0 THEN PRINT, FORMAT="('        # [', I02, '] : ', A)", system.error[0], error_message[0]
                IF system.error[1] GT 0 THEN PRINT, FORMAT="('        # [', I02, '] : ', A)", system.error[1], error_message[1]
                IF system.error[2] GT 0 THEN PRINT, FORMAT="('        # [', I02, '] : ', A)", system.error[2], error_message[2]
                PRINT, ''
                ;IF NOT keyword_set(no_log) THEN PRINT, FORMAT="('        # System LOG: ', A)", error_log
                
                
                EXIT
        ENDIF

        IF TOTAL(system.error[3:*]) GT 0 THEN BEGIN
                IF NOT keyword_set(no_log) THEN BEGIN
                PRINT, ''
                PRINT, FORMAT="('        # WARNING: ', I02, ' Execution Errors detected!')", TOTAL(system.error[3:*])
                IF system.error[3] GT 0 THEN PRINT, FORMAT="('        # [', I02, '] : ', A)", system.error[3], error_message[3]
                IF system.error[4] GT 0 THEN PRINT, FORMAT="('        # [', I02, '] : ', A)", system.error[4], error_message[4]
                PRINT, ''
                ENDIF
                error_log += 'Execution errors during '+process+'. '
                
                RETURN
        ENDIF

        error_log += 'No errors during '+process+'. '
        IF NOT keyword_set(no_log) THEN PRINT, process, FORMAT="('        # [OK] - ', A, '.')"

RETURN
END








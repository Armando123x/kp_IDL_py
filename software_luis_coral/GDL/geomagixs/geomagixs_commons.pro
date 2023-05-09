;+
; NAME:
;       geomagixs_commons
;
;
; PURPOSE:
;
;       Declares the COMMON variables for geomagixs
;
;       this script is GDL compatible.
;
; AUTHOR:
;
;       Pedro Corona Romero
;       Space Weather National Laboratory (LANCE)
;       Instituto de Geofisica, Unidad Michoacan
;       UNAM, Campus Morelia
;       Antigua Carretera a Patzcuaro
;       Morelia, Michoacan, Mexico
;       piter.cr@gmail.com
;       Mexico, 2021
;
; CATEGORY:
;
;       Numerical Data Analysis
;
; CALLING SEQUENCE:
;
;       @geomagixs_commons
;
;       Description:
;       this file declares de common variables.
;
;
; PARAMETERS:
;       Not Apply
;
; KEYWORD PARAMET
;       Not Apply
;
; DEPENDENCIES:
;       Not Apply
;
; ANALIZED FILES:
;       Not Apply
;
; OUTPUT FILES:
;
; HISTORY:
;-

;##############################################################################
; NOTE: if the forthcoming "COMMON" stantment is modified it is
;       mandatory to update the cme_general_dynamics.pro program.
;##############################################################################

        COMMON GEOMAGIXS_COMMONS,   System, $
                                    Flag_commons, $
                                    Flag_setup, $ ; usada
                                    Flag_dates, $
                                    Flag_error, $
                                    Flag_system, $
                                    GMS, $
                                    Error, $
                                    Dates

                                


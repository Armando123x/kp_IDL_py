; TRUE COLOR AND MAINTAIN BACKING STORE
;DEVICE, true_color = 24
DEVICE, retain = 2

; INTEGERS AT MAIN LEVERL ARE LONG AND ENFORCE SQUARE BRAKETS FOR ARRAYS
COMPILE_OPT IDL2

; GDL PAHT
!PATH = !PATH +':'+$
        EXPAND_PATH('+/home/luis/GDL');+':'+ $
        ;!PATH
        
;!quiet = 1
      
print, 'GDL_STARTUP.pro executed!!!'
print, ''


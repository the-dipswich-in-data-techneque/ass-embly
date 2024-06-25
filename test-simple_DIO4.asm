;; Simple DIO4 board test
;;;;;;;;;;;;;;;;;;;;;;
;; This program as an infinite loop where it reads the values of the Switches and displays them on the 7segment displays and reads the values from the buttons and displays them on the leds (SW -> 7seg, BTN -> LED).
;;
;; The lc3 code for this source is saved starting from address x0500 in test-simple_image.txt
;; and can be executed by pressing ENTER button on the FPGA main board.
;;
.orig x0500
DIO4Start
	LD R2, IO_BASE    ; load IO_BASE and keep it in R2

IOCopy
	LDR R0, R2, x0a   ; load IO_BASE+x0a  (xFE0A: DIO4 Switches) 
	STR R0, R2, x12   ; load IO_BASE+x12  (xFE12: DIO4 7Seg)

	LDR R0, R2, x0e   ; load IO_BASE+x0e  (xFE0E: DI04 Push buttons)
	STR R0, R2, x16   ; load IO_BASE+x16  (xFE16: DI04 Leds)

	;; Repeat it again
	BR IOCopy

; Base address of LC3 I/O registers
IO_BASE .FILL xFE00
.end


        .orig   x3000
;
begin   lea     r0      prompt
        trap    x22
        jsr     readS
        jsr     isPrime
        jsr     resultS
        brnzp   begin
        halt
fail    .stringz        "must be a two digit integer\n"
prompt  .stringz        "write a number "
;lab 2 assignment 1
readS   trap    x20
        add     r1      r0      x0
        trap    x21
        trap    x20
        add     r2      r0      x0
        trap    x21
        and     r0      r0      x0
        add     r0      r0      xa
        trap    x21
        add     r0      r1      #-16
        add     r0      r0      #-16
        add     r0      r0      #-16
        brn     invalid
        add     r0      r1      #-16
        add     r0      r0      #-16
        add     r0      r0      #-16
        add     r0      r0      #-9
        brp     invalid
        add     r0      r2      #-16
        add     r0      r0      #-16
        add     r0      r0      #-16
        brn     invalid
        add     r0      r2      #-16
        add     r0      r0      #-16
        add     r0      r0      #-16
        add     r0      r0      #-9
        brnz    valid
invalid lea     r0      fail
        brnzp   begin
valid   and     r0      r0      x0
        add     r2      r2      #-16
        add     r2      r2      #-16
        add     r2      r2      #-16
        add     r1      r1      #-16
        add     r1      r1      #-16
        add     r1      r1      #-16
        and     r3      r3      x0
        add     r3      r3      x-a
loop1   add     r0      r0      r1
        add     r3      r3      x1
        brn     loop1
        add     r0      r0      r2
;lab 2 assignment 2
isPrime st      r1      recR1
        st      r2      recR2;store register values
        add     r1      r0      x-3
        brn     right
        and     r1      r1      x0
        add     r1      r1      x-2;prepare multiplicator
        and     r2      r2      x0
        add     r2      r2      r0
loop    add     r2      r2      r1;recursive remainder
        brz     final;remainder negative so if r1 = r0 it is prime otherwise it is not
        brp     loop;remainder positive so do it again
next    add     r1      r1      x-1;prepares the next multiplicator to see
        and     r2      r2      x0
        add     r2      r2      r0
        brnzp   loop;do it all again
final   add     r2      r1      r0
        brp     wrong;skip the one   
right   and     r0      r0      x0
        add     r0      r0      x1
        brnzp   x1
wrong   and     r0      r0      x0
        ld      r1      recR1
        ld      r2      recR2
        ret
;recovery memory locations
recR1   .fill   x0
recR2   .fill   x0
;lab 2 assignment 3
resultS add     r0      r0      x0
        brz     x1
        lea     r0      realprime
        brnp    x1
        lea     r0      fakeprime
        trap    x22
        ret

realprime   .stringz    "The number is prime\n"
fakeprime   .stringz    "The number is not prime\n"
        .end
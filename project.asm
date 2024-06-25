.orig x3000
;                                           ;;;;;;;;;;;;;
main        jsr         initcoms
            and         r1      r1      x0  ;current player
normalRun   jsr         progcoms
            lea         r2      playerStart ;;R2 = player data, R3 addres, R4 = math
            add         r3      r2      r1
            ldr         r2      r3      x0
            ld          r4      price
            add         r4      r2   r4
            brn         final
            jsr         roll
            jsr         store
            add         r2      r2      r0
            str         r2      r3      x0      
            add         r1      r1      x1
            brnzp       normalRun
final       and         r0      r0      x0
            add         r0      r0      x-1
            jsr         TX
            jsr         TX
            add         r0      r1      x0
            jsr         TX
            brnzp       main
price       .fill       x-64
;                                           ;;;;;;;;;;;;;;
initcoms    st          r7      storeR7
loopcoms    jsr         RX;;;R1 = cash, R2 = number of players
            add         r0      r0      x0  ;see what was recieved
            brn         setCash
            brp         setCount
            lea         r0      playerStart 
initloop    str         r0      r1      x0  ;store next player's cash
            add         r0      r0      x1
            add         r2      r2      x-1
            brp         initloop
            ld          r0      playerCount 
            ld          r1      arrayStart
            add         r2      r0      r0  ;mult by 10
            add         r2      r2      r2
            add         r2      r2      r2
            add         r2      r2      r0
            add         r2      r2      r0
            not         r2      r2          ;set to negative
            add         r2      r2      x1
            add         r2      r2      r0  ;move the wheel to make space for old results
            st          r2      arrayStart
            ld          r7      storeR7
            ret                             ;;;;;;;;;;;;;;
setcash     not         r0      r0          ;flip to positive
            add         r0      r0      x1
            add         r1      r0      x0
            brnzp       loopcoms
setCount    add         r2      r0      x0  ;store player count
            st          r2      playerCount
            brnzp       loopcoms
;                                           ;;;;;;;;;;;;;;
progcoms    st          R1      storeR1
            st          R2      storeR2
            st          r7      storeR7
            jsr         store
progAgain   jsr         RX
            add         r0      r0      x0
            brp         extend
            brz         progDone
           ;brn         seeOld
seeold      lea         r1      resultStart ;get old results
            add         r1      r1      r0
            ldr         r0      r1      x0
            jsr         TX                  ;send results
            brnzp       progAgain
;                                           ;;;;;;;;;;;;;;
extend      ld          r1      arrayStart
            ld          r2      arrayLength
            add         r1      r1      r2
            str         r0      r1      x0
            add         r2      r2      x1
            st          r2      arrayLength
            brnzp       progAgain
progDone    ld          R1      storeR1
            ld          R2      storeR2
            ld          r7      storeR7
            ret
storeR1     .fill       x0000
storeR2     .fill       x0000
storeR3     .fill       x0000
storeR4     .fill       x0000
storeR5     .fill       x0000
storeR7     .fill       x0000
;                                           ;;;;;;;;;;;;;;
stdindat    .fill       xfe02
stdinstat   .fill       xfe00
;                                           ;;;;;;;;;;;;;;
pbtn        .fill       xFe0B
hex         .fill       xFE12
roll        st          r7      storeR7 ;sub routine
            st          r1      storeR1 ;location
            st          r2      storeR2 ;btn
            st          r3      storeR3 ;math into
            st          r4      storeR4 ;array length
            st          r5      storeR5 ;arrayLocation
            and         r1      r1      x0
            ld          r4      arrayLength
            not         r4      r4
            add         r4      r4      x1
            ld          r0      pbtn
            and         r0      r0      x8
            brz         x-3
            add         r0      r0      x-9 ;tell java to spin wheel
            jsr         TX
            add         r0      r0      x9
btnLoop     add         r0      r0      x1 ; speeding
            add         r1      r1      r0
            add         r3      r1      r4
            brp         x3                  ;modulus operation
            add         r1      r1      r4
            add         r3      r1      r4
            brp         x-3                 ;more modulus
            not         r3      r1
            add         r3      r3      x1
            add         r3      r3      r5
            ldr         r3      r3      x0
            sti         r3      hex
            ld          r2      pbtn
            and         r2      r2      x8
            brp         btnLoop
noBTN       add         r0      r0      x-1 ; slowing
            add         r1      r1      r0
            brp         x3                  ;modulus operation
            add         r1      r1      r4
            add         r3      r1      r4
            brp         x-3                 ;more modulus
            not         r3      r1
            add         r3      r3      x1
            add         r3      r3      r5
            ldr         r3      r3      x0
            sti         r3      hex
            add         r0      r3      x0
            add         r2      r1      r0
            brp         noBTN
            ld          r7      storeR7 ;sub routine
            ld          r1      storeR1 ;location
            ld          r2      storeR2 ;btn
            ld          r3      storeR3 ;math into
            ld          r4      storeR4 ;array length
            ld          r5      storeR5 ;arrayLocation
            ret
;                                           ;;;;;;;;;;;;;;
store       st          R1      tempR1
            st          R2      tempR2
            st          R3      tempR3
            ld          r1      resultStart
            ld          r3      arrayStart
            not         r3      r3
            add         r3      r3      x-1  ;move (so -1 becomes first)
storeLoop   ldr         r2      r1      x0  ;remove from space
            str         r0      r1      x0  ;store from before
            add         r0      r2      x0  ;swap new to old position
            add         r1      r1      x-1 ;move to next
            add         r2      r1      r3  ;see if there is space for mor
            brp         storeLoop           ;repeat
            ld          r1      tempR1
            ld          r2      tempR2
            ld          r3      tempR3
            ret
;                                           ;;;;;;;;;;;;;;
;                                           ;;;;;;;;;;;;;;
RX          st          r1      tempR1
            ld          r0      stdinstat
            brzp        x-2
            ld          r1      stdindat
            add         r1      r1      r1  ;left shift 1
            add         r1      r1      r1  ;2
            add         r1      r1      r1  ;3
            add         r1      r1      r1  ;4
            add         r1      r1      r1  ;5
            add         r1      r1      r1  ;6
            add         r1      r1      r1  ;7
            add         r1      r1      r1  ;8
            ld          r0      stdinstat
            brzp        x-2
            ld          r0      stdindat
            add         r0      r0      r1  ;full word from transmision
            ld          r1      tempR1
            ret
tempR1      .fill   x0
tempR2      .fill   x0
tempR3      .fill   x0
tempR4      .fill   x0
;                                           ;;;;;;;;;;;;;;
stdoutdat   .fill       xfe06
stdoutstat  .fill       xfe04
;                                           ;;;;;;;;;;;;;;
lowerMask   .fill       xff
topMask     .fill       x100
TX          st          r1      tempR1
            st          r2      tempR2
            st          r3      tempR3
            st          r4      tempR4
            ld          r2      topMask
            and         r4      r4      x0  ;find the top 8 bit
            add         r4      r4      x1
loopRS      and         r1      r0      r2
            add         r4      r4      r4
            add         r2      r2      r2
            brnp        loopRS
            ld          r3      stdoutstat
            brzp        x-2
            st          r1      stdoutdat
            ld          r2      lowerMask
            and         r1      r0      r2  ;bottom 8 bit
            ld          r3      stdoutstat
            brzp        x-2
            st          r1      stdoutdat
            ld          r1      tempR1
            ld          r2      tempR2
            ld          r3      tempR3
            ld          r4      tempR4
            ret
;                                           ;;;;;;;;;;;;;;
resultStart .fill       xdfff
arrayStart  .fill       xdfff
arrayLength .fill       x0
playerCount .fill       x0
;                                           ;;;;;;;;;;;;;;
playerStart .fill       x0                  ;this is a position after program
.end
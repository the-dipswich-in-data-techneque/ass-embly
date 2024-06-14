.orig x500
;
initcoms    jsr         RX
            add         r0      r0      x0  ;see what was recieved
            brn         setCash
            brp         setCount
                                            ;finalise from here
            lea         r0      playerStart 
initloop    str         r1      r0      x0  ;store next player's cash
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
            ret
            ;
setcash     not         r0      r0          ;flip to positive
            add         r0      r0      x1
            add         r1      r0      x0
            brnzp       initcoms
setCount    add         r2      r0      x0  ;store player count
            st          r0      playerCount
            brnzp       initcoms
;

;
progcoms    st          R1      storeR1
            st          R2      storeR2
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
            ;
extend      ld          r1      arrayStart
            ld          r2      arrayLength
            add         r1      r1      r2
            str         r0      r1      x0
            add         r2      r2      x1
            st          r2      arrayLength
            brnzp       progAgain
progDone    st          R1      storeR1
            st          R2      storeR2
            ret
storeR1     .fill       x0000
storeR2     .fill       x0000
;
;
stdindat    .fill       xfe02
stdinstat   .fill       xfe00
;
store       st          R1      tempR1
            st          R2      tempR2
            st          R3      tempR3
            ld          r1      resultStart
            ld          r3      arrayStart
            not         r3      r3
            add         r3      r3      x1  ;move (so -1 becomes first)
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
;
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
;
stdoutdat   .fill       xfe06
stdoutstat  .fill       xfe04
;
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
;
;
;
resultStart .fill       xdfff
arrayStart  .fill       xdfff
arrayLength .fill       x0
playerCount .fill       x0

playerStart .fill       x0                  ;this is a position after program
.end
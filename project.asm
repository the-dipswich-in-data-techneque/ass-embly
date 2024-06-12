.orig x500
;
initcoms    jsr         RX
            add         r0      r0      x0
            brn         setCash
            brp         setCount
            lea         r0      players 
initloop    str         r1      r0      x0
            add         r0      r0      x1
            add         r2      r2      x-1
            brp         initloop
            ret
setcash     not         r0      r0
            add         r0      r0      x1
            add         r1      r0      x0
            brnzp       initcoms
setCount    add         r2      r0      x0
            st          r0      playerCount
            brnzp       initcoms
;

;
progcoms
;
;
stdindat    .fill       xfe02
stdinstat   .fill       xfe00
;
RX          st          r1      tempR1
            ld          r0      stdinstat
            brzp        x-2
            ld          r1      stdindat
            add         r1      r1      r1;left shift 1
            add         r1      r1      r1;2
            add         r1      r1      r1;3
            add         r1      r1      r1;4
            add         r1      r1      r1;5
            add         r1      r1      r1;6
            add         r1      r1      r1;7
            add         r1      r1      r1;8
            ld          r0      stdinstat
            brzp        x-2
            ld          r0      stdindat
            add         r0      r0      r1;full word from transmision
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
            and         r3      r3      x0
            and         r4      r4      x0
            add         r4      r4      x1
loopRS      and         r1      r0      r2
            brz         x1
            add         r3      r3      r4
            add         r4      r4      r4
            add         r2      r2      r2
            brnp        loopRS
            ld          r0      stdoutstat
            brzp        x-2
            st          r0      stdoutdat
            and         r1      r0      lowerMask
            ld          r2      stdoutstat
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
arrayStart  .fill       xdfff
arrayLength .fill       x0
playerCount .fill       x0
players     .fill       x0;this is a position after program
.end
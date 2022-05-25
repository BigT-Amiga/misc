***********************************************
* 3d_bob_field                                *
* Fixed for Devpac 3.11 25/5/2022             *
*                                             *
* Original sourced from:                      *
* https://commodore.bombjack.org              *
* /amiga/source-code/LSD.CD1_Assembly.sources *
***********************************************

   SECTION  3d_bob_field,code_c
   INCLUDE  cargo_custom.i

_LVOOldOpenLibrary   EQU   -408

trap_vec0 = $80
tabelle   = $76000
planes    = $60000

   move.l   #start,trap_vec0        ;Trap vector 0
   trap     #0                      ;Execute trap 0 to give full control of the
   rts                              ;68000, needs an RTE to return.

start:
   bsr      tabin
   bsr      tabin2
   bsr      tabin3
   bsr      mouseinit
   bsr      killsys
   bsr      main
   bsr      sysreturn

   rte                              ;Return from exception

*****************************************************************************
*killsys - Disable operating system and interrupts
*****************************************************************************
killsys:
   move.l   $4.w,a6                 ;Execbase vector
   lea      gfxname(pc),a1          ;Pointer to "graphics.library" into a1
   jsr      _LVOOldOpenLibrary(a6)  ;Open this library
   lea      $dff000,a6              ;Pointer to custom chips
   move.l   d0,a0                   ;Address of the graphics library
   move.l   38(a0),sys_copl         ;Remember the System copperlist
   move     intenar(a6),int_set     ;System interrupts
   move     #$7fff,intena(a6)       ;Now switch off all interrupts
   move.l   $6c.w,vbl_vec           ;System vertical blanking int.
   move     dmaconr(a6),dma_set     ;System DMA
   move     #$7fff,dmacon(a6)       ;Clear all DMA
   move     #$87c0,dmacon(a6)       ;Now set the required DMA channels

   move.l   #cop,cop1lch(a6)        ;Init. our own copperlist
   clr      copjmp1(a6)

   rts

gfxname:    dc.b "graphics.library",0
   EVEN
*****************************************************************************
*sysreturn - Re-enable operating system and interrupts
*****************************************************************************
sysreturn:
   lea      $dff000,a6
   move     #$7fff,intena(a6)       ;Clear all interrupts
   move.l   vbl_vec,$6c.w           ;Restore VBL interrupt
   move     int_set,d0
   or       #$c000,d0
   move     d0,intena(a6)           ;Restore system interrupts
   move     #$7fff,dmacon(a6)
   move     dma_set,d0
   or       #$8200,d0
   move     d0,dmacon(a6)           ;Restore system DMA
   move.l   sys_copl,cop1lch(a6)    ;Restore system copperlist
   clr      copjmp1(a6)
   rts

vbl_vec:    dc.l 0
int_set:    dc.l 0
dma_set:    dc.l 0
sys_copl:   dc.l 0

main:
   move.l   vposr(a6),d0
   and.l    #$1ff00,d0
   Cmp.l    #$00100,d0              ;Wait for vertical position 1
   bne      main

   bsr      mouse
   bsr      rout1
   bsr      rout2
   bsr      rout3

   btst     #6,$bfe001              ;Check the left mouse button
   bne.s    main

   moveq    #0,D0
   rts


rout1:
   lea      planepointer1(pc),a0
   move.l   4(a0),d0
   move.l   (a0),4(a0)
   move.l   8(a0),(a0)
   move.l   d0,8(a0)
   lea      cop+2(pc),a0
   add.l    #$00000540,d0
   addq.l   #2,d0
   move.l   d0,d1
   add.l    #$0000002a,d1
   move.w   d0,4(a0)
   move.w   d1,12(a0)
   swap     d0
   swap     d1
   move.w   d0,(a0)
   move.w   d1,8(a0)
   rts

rout2:
   move.l   planepointer2(pc),d0
   addq.l   #2,d0
   add.l    #$00000540,d0
   move.l   d0,bltdpt(a6)
   move.l   #$01000000,bltcon0(a6)  ;no A Shift, Use D only (clear screen)
   move.w   #2,bltdmod(a6)
   move.w   #$4e14,bltsize(a6)      ;312 lines high x 20 words (40 bytes) wide
   add.l    #$00005dd6,d0
   move.l   d0,a5
   movem.l  null(pc),d0-d6/a0-a4
clear:      
   dcb.l    $f6,$48e5fef8           ;BLK.L  $3D8/4,$48E5FEF8
   rts


rout3:
   lea      tabelle+$390c,a1        ;balls of fire
   lea      tabelle+$36b0,a3
   move.w   #$0081,d7
   lea      F9A64(PC),a4
   lea      tabelle,a5
   movem.w  (a4)+,d0-d2
   add.w    d0,Z9A7C
   add.w    d1,Z9A7E
   sub.w    d2,Z96DA
   move.w   Z96DA(pc),d2
   cmp.w    #$0CB2,d2
   bge.s    lbC00004E
lbC000036:
   cmp.w    #$0C99,d2
   bge.s    lbC00005C
   add.w    #$0019,d2
   subq.w   #1,Z9560
   bra.s    lbC000036
 
lbC000048:
   cmp.w    #$0CB2,d2
   ble.s    lbC00005C
lbC00004E:
   sub.w    #$0019,d2
   addq.w   #1,Z9560
   bra.s    lbC000048
 
lbC00005C:
   move.w   d2,Z96DA
   lea      tab(pc),a0
   move.w   Z9560(pc),d0
   bge.s    lbC000074
   add.w    #$0082,d0
   bra.s    lbC00007E
 
lbC000074:
   cmp.w    #$0081,d0
   ble.s    lbC00007E
   sub.w    #$0082,d0
lbC00007E:
   move.w   d0,Z9560
   add.w    d0,d0
   add.w    d0,d0
   add.w    d0,a0
   move.l   planepointer2(pc),a4
lbC00008E:
   btst     #6,dmaconr(a6)
   bne.s    lbC00008E
   move.l   #$ffff0000,bltafwm(a6)  ;blitter first word mask & last word mask
   move.l   #$0026001c,bltcmod(a6)  ;blitter modulo source C & source B
   move.l   #$001c0026,bltamod(a6)  ;blitter modulo source A & destination D
lbC0000AE:
   move.l   a4,a2
   move.w   (a0)+,d0
   move.w   (a0)+,d1
   move.w   d2,-(a7)
   add.w    d2,d2
   move.w   0(a1,d2.w),d6
   add.w    d2,d2
   move.l   0(a5,d2.w),d5
   move.w   d5,d3
   asr.w    #1,d3
   add.w    Z9A7C(pc),d0
   add.w    Z9A7E(pc),d1
   and.w    #$03ff,d0
   and.w    #$03ff,d1
   sub.w    #$0200,d0
   sub.w    #$0200,d1
   muls     d6,d0
   beq.s    lbC000164
   muls     d6,d1
   beq.s    lbC000164
   moveq    #9,d6
   asr.l    d6,d0
   asr.l    d6,d1
   add.w    d3,d1
   add.w    #$00b0,d0
   bmi.s    lbC000164
   cmp.w    #$0150,d0
   bge.s    lbC000164
   add.w    #$009f,d1
   bmi.s    lbC000164
   cmp.w    #$012e,d1
   bge.s    lbC000164
   add.w    d1,d1
   add.w    0(a3,d1.w),a2
   move.w   d0,d6
   asr.w    #3,d6
   add.w    d6,a2
   and.w    #$000f,d0
   ror.w    #4,d0
   move.w   d0,d2
   or.w     #$0fca,d0
   swap     d0
   move.w   d2,d0
   move.l   #ball,d6
   move.l   #maske,d2
   swap     d5
   move.w   d5,d4
   swap     d5
   add.w    d5,d5
   ext.l    d5
   add.l    d5,d2
   add.l    d5,d6
lbC000144:
   btst     #6,dmaconr(a6)
   bne.s    lbC000144
   move.l   a2,bltdpt(a6)           ;blitter pointer to destination D
   move.l   a2,bltcpt(a6)           ;blitter pointer to source C
   move.l   d6,bltbpt(a6)           ;blitter pointer to source B
   move.l   d2,bltapt(a6)           ;blitter pointer to source A
   move.l   d0,bltcon0(a6)          ;blitter control register 0 (A Shift,Use ABCD, LF) & register 1 (B Shift,Line Mode)
   move.w   d4,bltsize(a6)          ;blitter start & size
lbC000164:
   move.w   (a7)+,d2
   sub.w    #$0019,d2
   dbra     d7,lbC0000AE
lbC00016E:
   btst     #6,dmaconr(a6)
   bne.s    lbC00016E
   rts

mouseinit:
   move.b   JOY0DAT+1,d0
   move.b   d0,MHCNT
   move.b   JOY0DAT,d0
   move.b   d0,MVCNT
   rts
mouse:
   move.b   JOY0DAT+1,d4
   move.b   MHCNT(pc),d5
   move.b   d4,MHCNT
   sub.b    d5,d4
   beq.s    pl2
   blt.s    pl1
   cmp.w    #0018,F9A64
   beq.s    pl2
   add.w    #1,F9A64
   bra.s    pl2
pl1:
   cmp.w    #$ffe8,F9A64
   beq.s    pl2
   sub.w    #1,F9A64
pl2:
   move.b   JOY0DAT,d4
   move.b   MVCNT(pc),d5
   move.b   d4,MVCNT
   sub.b    d5,d4
   beq.s    pl4
   blt.s    pl3
   cmp.w    #0018,F9A64+2
   beq.s    pl4
   add.w    #1,F9A64+2
   bra.s    pl4
pl3:
   cmp.w    #$ffe8,F9A64+2
   beq.s    pl4
   sub.w    #1,F9A64+2
pl4:
   rts

MVCNT:      DC.B 0
MHCNT:      DC.B 0

tabin:
   moveq    #0,d0
   moveq    #$54,d1
   move.w   #$012d,d2
   lea      tabelle+$36b0,a0
lbC00000E:
   move.w   d0,(a0)+
   add.l    d1,d0
   dbra     d2,lbC00000E
   rts

tabin2:
   move.w   #1,d0
   lea      tabelle,a0
   move.l   #$00002000,d1
   move.w   #$0dab,d7
lbC000014:
   move.l   d1,d2
   divu     d0,d2
   cmp.w    #15,d2
   ble.s    lbC000020
   moveq    #15,d2
lbC000020:
   move.w   d2,d3
   addq.w   #1,d3
   lsl.w    #7,d3
   addq.w   #2,d3
   move.w   d3,(a0)+
   neg.w    d2
   add.w    #15,d2
   move.w   d2,(a0)+
   addq.w   #1,d0
   dbra     d7,lbC000014
   rts

tabin3:
   move.l   #$40600,d0
   moveq    #$5a,d1
   lea      tabelle+$390c,a0
   move.w   #$0dab,d7
loop:
   move.l   d0,d2
   divu     d1,d2
   move.w   d2,(a0)+
   addq.w   #1,d1
   dbf      d7,loop
   rts


F9A64:   dc.w  $0000,$0000,$0030
Z9A7C:   dc.w  $0000
Z9A7E:   dc.w  $0000
Z96DA:   dc.w  $0c9e
Z9560:   dc.w  $006e

planepointer1:
         dc.l  planes
planepointer2:
         dc.l  planes+$6318
planepointer3:
         dc.l  planes+$c630

null:    dcb.w 36,0                 ;BLK.W 36,0

ball:
   dc.w  $07e0,$07c0,$03c0,$07c0,$07e0,$07c0,$03c0,$0380
   dc.w  $03c0,$0380,$0380,$0380,$0180,$0100,$0080,$0100
   dc.w  $07e0,$07c0,$03c0,$07c0,$07e0,$07c0,$03c0,$0380
   dc.w  $03c0,$0380,$0380,$0380,$0180,$0100,$0180,$0100
   dc.w  $1ff8,$1ff0,$0ff0,$1ff0,$0ff0,$0fe0,$0ff0,$0fe0
   dc.w  $05e0,$07c0,$07c0,$04c0,$02c0,$0280,$0100,$0000
   dc.w  $1ff8,$1ff0,$0ff0,$1ff0,$0ff0,$0fe0,$0ff0,$0fe0
   dc.w  $07e0,$07c0,$05c0,$07c0,$03c0,$0380,$0100,$0000
   dc.w  $3ffc,$3ff8,$1ff8,$3ff8,$1bf8,$1bf0,$0df0,$0de0
   dc.w  $0af0,$0fe0,$07c0,$0580,$0380,$0100,$0000,$0000
   dc.w  $3ffc,$3ff8,$1ff8,$3ff8,$1ff8,$1ff0,$0ff0,$0fe0
   dc.w  $0df0,$0de0,$07e0,$07c0,$03c0,$0100,$0000,$0000
   dc.w  $77fe,$77fc,$3bfc,$3bf8,$35fc,$35f8,$1af8,$1af0
   dc.w  $0de0,$0fc0,$07c0,$0740,$0140,$0000,$0000,$0000
   dc.w  $7ffe,$7ffc,$3ffc,$3ff8,$3bfc,$3bf8,$1df8,$1df0
   dc.w  $0ff0,$0fe0,$07e0,$07c0,$01c0,$0000,$0000,$0000
   dc.w  $6bfe,$6bfc,$35fc,$75fc,$3bf8,$3bf0,$1df0,$1de0
   dc.w  $0fe0,$0fc0,$03a0,$0280,$0000,$0000,$0000,$0000
   dc.w  $77fe,$77fc,$3bfc,$7bfc,$3ffc,$3ff8,$1ff8,$1ff0
   dc.w  $0ff0,$0fe0,$03e0,$0380,$0000,$0000,$0000,$0000
   dc.w  $f7ff,$f7fe,$7bfe,$7bf8,$3ff8,$3ff0,$1ff0,$1fe0
   dc.w  $0fd0,$07a0,$0040,$0000,$0000,$0000,$0000,$0000
   dc.w  $ffff,$fffe,$7ffe,$7ffc,$3ffc,$3ff8,$1ff8,$1ff0
   dc.w  $0ff0,$07e0,$01c0,$0000,$0000,$0000,$0000,$0000
   dc.w  $fffe,$fffc,$7ffc,$7ff8,$3ff8,$3ff0,$1ff0,$0fd0
   dc.w  $07a0,$0240,$0000,$0000,$0000,$0000,$0000,$0000
   dc.w  $ffff,$fffe,$7ffe,$7ffc,$3ffc,$3ff8,$1ff8,$0ff0
   dc.w  $07e0,$03c0,$0000,$0000,$0000,$0000,$0000,$0000
   dc.w  $fffe,$fffc,$7ffc,$7ff8,$3ff8,$3fe8,$0fe8,$0fa0
   dc.w  $0240,$0000,$0000,$0000,$0000,$0000,$0000,$0000
   dc.w  $ffff,$fffe,$7ffe,$7ffc,$3ffc,$3ff8,$0ff8,$0fe0
   dc.w  $03c0,$0000,$0000,$0000,$0000,$0000,$0000,$0000
   dc.w  $fffe,$fffc,$7ffc,$7ff4,$3ff4,$1fd0,$0fd0,$0240
   dc.w  $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
   dc.w  $ffff,$fffe,$7ffe,$7ffc,$3ffc,$1ff0,$0ff0,$03c0
   dc.w  $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
   dc.w  $fffe,$fffa,$3ffa,$3ff0,$1fe8,$0fa0,$0220,$0000
   dc.w  $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
   dc.w  $ffff,$fffe,$3ffe,$3ff8,$1ff8,$0fe0,$03e0,$0000
   dc.w  $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
   dc.w  $fffd,$7ff8,$3ff8,$3fe8,$0fd0,$0440,$0000,$0000
   dc.w  $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
   dc.w  $ffff,$7ffc,$3ffc,$3ff8,$0ff0,$07c0,$0000,$0000
   dc.w  $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
   dc.w  $7ffc,$7ff4,$1ff4,$1f90,$0420,$0000,$0000,$0000
   dc.w  $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
   dc.w  $7ffe,$7ffc,$1ffc,$1ff0,$07e0,$0000,$0000,$0000
   dc.w  $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
   dc.w  $7ffa,$3fe8,$0fc8,$0440,$0000,$0000,$0000,$0000
   dc.w  $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
   dc.w  $7ffe,$3ff8,$0ff8,$07c0,$0000,$0000,$0000,$0000
   dc.w  $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
   dc.w  $3ff4,$1f90,$0220,$0000,$0000,$0000,$0000,$0000
   dc.w  $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
   dc.w  $3ffc,$1ff0,$03e0,$0000,$0000,$0000,$0000,$0000
   dc.w  $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
   dc.w  $1fc8,$0440,$0000,$0000,$0000,$0000,$0000,$0000
   dc.w  $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
   dc.w  $1ff8,$07c0,$0000,$0000,$0000,$0000,$0000,$0000
   dc.w  $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
   dc.w  $0420,$0000,$0000,$0000,$0000,$0000,$0000,$0000
   dc.w  $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
   dc.w  $07e0,$0000,$0000,$0000,$0000,$0000,$0000,$0000
   dc.w  $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000

maske:
   dc.w  $07e0,$07c0,$03c0,$07c0,$07e0,$07c0,$03c0,$0380
   dc.w  $03c0,$0380,$0180,$0380,$0180,$0100,$0180,$0100
   dc.w  $07e0,$07c0,$03c0,$07c0,$07e0,$07c0,$03c0,$0380
   dc.w  $03c0,$0380,$0180,$0380,$0180,$0100,$0180,$0100
   dc.w  $1ff8,$1ff0,$0ff0,$1ff0,$0ff0,$0fe0,$0ff0,$0fe0
   dc.w  $07e0,$07c0,$03c0,$07c0,$03c0,$0380,$0180,$0000
   dc.w  $1ff8,$1ff0,$0ff0,$1ff0,$0ff0,$0fe0,$0ff0,$0fe0
   dc.w  $07e0,$07c0,$03c0,$07c0,$03c0,$0380,$0180,$0000
   dc.w  $3ffc,$3ff8,$1ff8,$3ff8,$1ff8,$1ff0,$0ff0,$0fe0
   dc.w  $0ff0,$0fe0,$07e0,$07c0,$03c0,$0180,$0000,$0000
   dc.w  $3ffc,$3ff8,$1ff8,$3ff8,$1ff8,$1ff0,$0ff0,$0fe0
   dc.w  $0ff0,$0fe0,$07e0,$07c0,$03c0,$0180,$0000,$0000
   dc.w  $7ffe,$7ffc,$3ffc,$3ff8,$3ffc,$3ff8,$1ff8,$1ff0
   dc.w  $0ff0,$0fe0,$07e0,$07c0,$01c0,$0000,$0000,$0000
   dc.w  $7ffe,$7ffc,$3ffc,$3ff8,$3ffc,$3ff8,$1ff8,$1ff0
   dc.w  $0ff0,$0fe0,$07e0,$07c0,$01c0,$0000,$0000,$0000
   dc.w  $7ffe,$7ffc,$3ffc,$7ffc,$3ffc,$3ff8,$1ff8,$1ff0
   dc.w  $0ff0,$0fe0,$03e0,$0380,$0000,$0000,$0000,$0000
   dc.w  $7ffe,$7ffc,$3ffc,$7ffc,$3ffc,$3ff8,$1ff8,$1ff0
   dc.w  $0ff0,$0fe0,$03e0,$0380,$0000,$0000,$0000,$0000
   dc.w  $ffff,$fffe,$7ffe,$7ffc,$3ffc,$3ff8,$1ff8,$1ff0
   dc.w  $0ff0,$07e0,$01c0,$0000,$0000,$0000,$0000,$0000
   dc.w  $ffff,$fffe,$7ffe,$7ffc,$3ffc,$3ff8,$1ff8,$1ff0
   dc.w  $0ff0,$07e0,$01c0,$0000,$0000,$0000,$0000,$0000
   dc.w  $ffff,$fffe,$7ffe,$7ffc,$3ffc,$3ff8,$1ff8,$0ff0
   dc.w  $07e0,$03c0,$0000,$0000,$0000,$0000,$0000,$0000
   dc.w  $ffff,$fffe,$7ffe,$7ffc,$3ffc,$3ff8,$1ff8,$0ff0
   dc.w  $07e0,$03c0,$0000,$0000,$0000,$0000,$0000,$0000
   dc.w  $ffff,$fffe,$7ffe,$7ffc,$3ffc,$3ff8,$0ff8,$0fe0
   dc.w  $03c0,$0000,$0000,$0000,$0000,$0000,$0000,$0000
   dc.w  $ffff,$fffe,$7ffe,$7ffc,$3ffc,$3ff8,$0ff8,$0fe0
   dc.w  $03c0,$0000,$0000,$0000,$0000,$0000,$0000,$0000
   dc.w  $ffff,$fffe,$7ffe,$7ffc,$3ffc,$1ff0,$0ff0,$03c0
   dc.w  $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
   dc.w  $ffff,$fffe,$7ffe,$7ffc,$3ffc,$1ff0,$0ff0,$03c0
   dc.w  $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
   dc.w  $ffff,$fffe,$3ffe,$3ff8,$1ff8,$0fe0,$03e0,$0000
   dc.w  $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
   dc.w  $ffff,$fffe,$3ffe,$3ff8,$1ff8,$0fe0,$03e0,$0000
   dc.w  $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
   dc.w  $ffff,$7ffc,$3ffc,$3ff8,$0ff0,$07c0,$0000,$0000
   dc.w  $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
   dc.w  $ffff,$7ffc,$3ffc,$3ff8,$0ff0,$07c0,$0000,$0000
   dc.w  $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
   dc.w  $7ffe,$7ffc,$1ffc,$1ff0,$07e0,$0000,$0000,$0000
   dc.w  $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
   dc.w  $7ffe,$7ffc,$1ffc,$1ff0,$07e0,$0000,$0000,$0000
   dc.w  $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
   dc.w  $7ffe,$3ff8,$0ff8,$07c0,$0000,$0000,$0000,$0000
   dc.w  $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
   dc.w  $7ffe,$3ff8,$0ff8,$07c0,$0000,$0000,$0000,$0000
   dc.w  $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
   dc.w  $3ffc,$1ff0,$03e0,$0000,$0000,$0000,$0000,$0000
   dc.w  $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
   dc.w  $3ffc,$1ff0,$03e0,$0000,$0000,$0000,$0000,$0000
   dc.w  $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
   dc.w  $1ff8,$07c0,$0000,$0000,$0000,$0000,$0000,$0000
   dc.w  $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
   dc.w  $1ff8,$07c0,$0000,$0000,$0000,$0000,$0000,$0000
   dc.w  $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
   dc.w  $07e0,$0000,$0000,$0000,$0000,$0000,$0000,$0000
   dc.w  $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
   dc.w  $07e0,$0000,$0000,$0000,$0000,$0000,$0000,$0000
   dc.w  $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000

cop:
   dc.w  bpl1pth,$0001,bpl1ptl,$e44c,bpl2pth,$0001,bpl2ptl,$e476
   dc.w  diwstrt,$1867,diwstop,$36d4,ddfstrt,$0038,ddfstop,$00d0
   dc.w  bplcon0,$2200,bplcon2,$0024,bplcon1,$0000,spr0pth,$0000
   dc.w  spr0ptl,$9b76,spr1pth,$0000,spr1ptl,$9eba,spr2pth,$0000
   dc.w  spr2ptl,$a1fe,spr3pth,$0000,spr3ptl,$a542,spr4pth,$0000
   dc.w  spr4ptl,$a886,spr5pth,$0000,spr5ptl,$abca,spr6pth,$0000
   dc.w  spr6ptl,$af0e,spr7pth,$0000,spr7ptl,$b252,dmacon,$0020
   dc.w  bpl1mod,$002c,bpl2mod,$002c,color00,$0000,color01,$0fff
   dc.w  color02,$034b,color03,$0017,color16,$0000,color17,$0000
   dc.w  color18,$0000,color19,$0000,color20,$0000,color21,$0000
   dc.w  color22,$0000,color23,$0000,color24,$0000,color25,$0000
   dc.w  color26,$0000,color27,$0000,color28,$0000,color29,$0000
   dc.w  color30,$0000,color31,$0000,$ffff,$fffe,$0def,$07bc

tab:
   dc.l  $6eed027a,$a8471ef4,$0ce71c92,$a9e9c5c6,$b6fd186a
   dc.l  $3f5099b8,$19b1ec9d,$17f5a22f,$7f9b537b,$bfaced85
   dc.l  $5de54c8a,$2d190a88,$c6d09801,$37348dfa,$f52e3f4b
   dc.l  $18cb9014,$c7e50c8a,$f10130fb,$3f730c11,$46c80c51
   dc.l  $016513e7,$7d6bc9a7,$d5de364c,$63079003,$2e17522c
   dc.l  $a60d8e5f,$98d884ad,$5cc0732a,$4c04afa7,$7bbdf4c4
   dc.l  $a20bf927,$5e6e4a06,$99754feb,$4796b0b8,$525edde8
   dc.l  $d7c9e819,$92f397c7,$97f1b65b,$44fab264,$73cb6424
   dc.l  $f3492b4e,$3a673e0e,$544b3f4a,$1fab1328,$ba7ef0cf
   dc.l  $3bd1b973,$a0f6878b,$09e48865,$24db0edd,$e747de6a
   dc.l  $86e7d15a,$9c2f9b5e,$ace9e549,$cd23a214,$a146a126
   dc.l  $87835fd2,$12731e22,$b9fd3bd2,$cf7cbca0,$b61a29c3
   dc.l  $517f9cb9,$b7b01c46,$2f3227b9,$576e8e72,$a65986a1
   dc.l  $1653fa51,$1a5028a4,$d6376460,$8f873faa,$6040cd13
   dc.l  $300142d0,$e06dbf4e,$c8d46ce5,$6510c6ec,$4cac3bee
   dc.l  $624cf43c,$5049f2a4,$319b5d7f,$8cfb19f1,$8a4a996c
   dc.l  $612ef876,$10fa46ad,$4ed82008,$c422835f,$7a0ce12e
   dc.l  $8f887596,$2e6bd4a4,$bdcbc5d6,$57ac54db,$7ddc219b
   dc.l  $091cfc77,$6380b7d2,$f61933d0,$e5d0bd5e,$fa959d72
   dc.l  $e1b9eb93,$9499a59c,$167d00be,$63bffac5,$a630399c
   dc.l  $adb70f13,$9a3cdcde,$dcc49ae1,$5edcb2ac,$fe3c1642
   dc.l  $41a5891f,$450c4179,$f6f8afc5,$85309d7d,$17917b21
   dc.l  $b93ef37c,$9cfcc328,$7fdccc54,$681b67c5,$9747f71b
   dc.l  $bca2c456,$68ca0798,$c29a412d,$7b4dd1c8,$04e1c610
   dc.l  $fdc3f15b,$f1a840b8,$42b94734,$5ff41f56,$3dcf72eb
   dc.l  $051ed70a,$09375c4f,$fc53626a,$6337aedd,$4715bc01
   dc.l  $6eed027a,$a8471ef4,$0ce71c92,$a9e9c5c6,$b6fd186a
   dc.l  $3f5099b8,$19b1ec9d,$17f5a22f,$7f9b537b,$bfaced85
   dc.l  $5de54c8a,$2d190a88,$c6d09801,$37348dfa,$f52e3f4b
   dc.l  $18cb9014,$c7e50c8a,$f10130fb,$3f730c11,$46c80c51
   dc.l  $016513e7,$7d6bc9a7,$d5de364c,$63079003,$2e17522c
   dc.l  $a60d8e5f,$98d884ad,$5cc0732a,$4c04afa7,$7bbdf4c4
   dc.l  $a20bf927,$5e6e4a06,$99754feb,$4796b0b8,$525edde8
   dc.l  $d7c9e819,$92f397c7,$97f1b65b,$44fab264,$73cb6424
   dc.l  $f3492b4e,$3a673e0e,$544b3f4a,$1fab1328,$ba7ef0cf
   dc.l  $3bd1b973,$a0f6878b,$09e48865,$24db0edd,$e747de6a
   dc.l  $86e7d15a,$9c2f9b5e,$ace9e549,$cd23a214,$a146a126
   dc.l  $87835fd2,$12731e22,$b9fd3bd2,$cf7cbca0,$b61a29c3
   dc.l  $517f9cb9,$b7b01c46,$2f3227b9,$576e8e72,$a65986a1
   dc.l  $1653fa51,$1a5028a4,$d6376460,$8f873faa,$6040cd13
   dc.l  $300142d0,$e06dbf4e,$c8d46ce5,$6510c6ec,$4cac3bee
   dc.l  $624cf43c,$5049f2a4,$319b5d7f,$8cfb19f1,$8a4a996c
   dc.l  $612ef876,$10fa46ad,$4ed82008,$c422835f,$7a0ce12e
   dc.l  $8f887596,$2e6bd4a4,$bdcbc5d6,$57ac54db,$7ddc219b
   dc.l  $091cfc77,$6380b7d2,$f61933d0,$e5d0bd5e,$fa959d72
   dc.l  $e1b9eb93,$9499a59c,$167d00be,$63bffac5,$a630399c
   dc.l  $adb70f13,$9a3cdcde,$dcc49ae1,$5edcb2ac,$fe3c1642
   dc.l  $41a5891f,$450c4179,$f6f8afc5,$85309d7d,$17917b21
   dc.l  $b93ef37c,$9cfcc328,$7fdccc54,$681b67c5,$9747f71b
   dc.l  $bca2c456,$68ca0798,$c29a412d,$7b4dd1c8,$04e1c610
   dc.l  $fdc3f15b,$f1a840b8,$42b94734,$5ff41f56,$3dcf72eb
   dc.l  $051ed70a,$09375c4f,$fc53626a,$6337aedd,$4715bc01
   dc.l  $00000239,$047306ac,$08e40b1c,$0d530f89,$11be13f1
   dc.l  $16231853,$1a821cae,$1ed820ff,$23242546,$27662982
   dc.l  $2b9b2db0,$2fc231d1,$33db35e1,$37e439e1,$3bdb3dcf
   dc.l  $3fbf41aa,$43904570,$474b4921,$4af04cba,$4e7e503c
   dc.l  $51f453a5,$554f56f3,$58915a27,$5bb65d3e,$5ebf6039
   dc.l  $61ab6315,$647865d2,$67256870,$69b36aed,$6c1f6d49
   dc.l  $6e6a6f83,$70927199,$7298738d,$7479755c,$76367707
   dc.l  $77cf788d,$794279ed,$7a8f7b27,$7bb67c3b,$7cb67d28
   dc.l  $7d8f7ded,$7e427e8c,$7ecd7f03,$7f307f53,$7f6c7f7b
   dc.l  $7f807f7b,$7f6c7f53,$7f307f03,$7ecd7e8c,$7e427dee
   dc.l  $7d907d28,$7cb77c3b,$7bb67b28,$7a9079ee,$7943788e
   dc.l  $77d07708,$7637755e,$747a738e,$7299719b,$70946f84
   dc.l  $6e6c6d4a,$6c216aef,$69b46872,$672765d4,$64796317
   dc.l  $61ad603b,$5ec15d40,$5bb85a29,$589356f6,$555253a7
   dc.l  $51f6503e,$4e814cbd,$4af34923,$474e4573,$439241ac
   dc.l  $3fc23dd2,$3bdd39e4,$37e635e4,$33de31d3,$2fc52db3
   dc.l  $2b9e2985,$27682549,$23272102,$1edb1cb1,$1a851856
   dc.l  $162613f4,$11c10f8c,$0d560b1f,$08e706af,$0476023c
   dc.l  $0003fdc8,$fb8ef955,$f71df4e5,$f2aef078,$ee43ec10
   dc.l  $e9dee7ae,$e57fe353,$e129df02,$dcdddabb,$d89bd67f
   dc.l  $d466d251,$d03ece30,$cc26ca1f,$c81dc61f,$c426c231
   dc.l  $c042be57,$bc71ba90,$b8b5b6e0,$b510b346,$b182afc4
   dc.l  $ae0dac5c,$aab1a90d,$a770a5d9,$a44aa2c2,$a1419fc7
   dc.l  $9e559ceb,$9b889a2d,$98da9790,$964d9512,$93e092b7
   dc.l  $9195907d,$8f6d8e66,$8d688c72,$8b868aa3,$89c988f8
   dc.l  $88308772,$86bd8612,$857084d8,$844983c4,$834982d7
   dc.l  $826f8211,$81bd8172,$813280fb,$80ce80ab,$80938084
   dc.l  $807f8083,$809280ab,$80ce80fa,$81318171,$81bc8210
   dc.l  $826e82d5,$834783c2,$844784d5,$856e860f,$86bb876f
   dc.l  $882d88f5,$89c58a9f,$8b828c6f,$8d648e62,$8f699078
   dc.l  $919192b2,$93dc950e,$9648978a,$98d59a28,$9b839ce5
   dc.l  $9e4f9fc1,$a13ba2bc,$a444a5d3,$a769a906,$aaaaac55
   dc.l  $ae06afbd,$b17bb33f,$b509b6d8,$b8aeba89,$bc69be4f
   dc.l  $c03ac229,$c41ec617,$c815ca17,$cc1dce28,$d036d248
   dc.l  $d45ed677,$d893dab2,$dcd4def9,$e121e34a,$e577e7a5
   dc.l  $e9d5ec07,$ee3af06f,$f2a5f4dc,$f714f94c,$fb85fdbf


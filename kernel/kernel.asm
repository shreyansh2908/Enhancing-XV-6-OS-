
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	b6013103          	ld	sp,-1184(sp) # 80008b60 <_GLOBAL_OFFSET_TABLE_+0x8>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	076000ef          	jal	ra,8000008c <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// at timervec in kernelvec.S,
// which turns them into software interrupts for
// devintr() in trap.c.
void
timerinit()
{
    8000001c:	1141                	addi	sp,sp,-16
    8000001e:	e422                	sd	s0,8(sp)
    80000020:	0800                	addi	s0,sp,16
// which hart (core) is this?
static inline uint64
r_mhartid()
{
  uint64 x;
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000022:	f14027f3          	csrr	a5,mhartid
  // each CPU has a separate source of timer interrupts.
  int id = r_mhartid();
    80000026:	0007859b          	sext.w	a1,a5

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    8000002a:	0037979b          	slliw	a5,a5,0x3
    8000002e:	02004737          	lui	a4,0x2004
    80000032:	97ba                	add	a5,a5,a4
    80000034:	0200c737          	lui	a4,0x200c
    80000038:	ff873703          	ld	a4,-8(a4) # 200bff8 <_entry-0x7dff4008>
    8000003c:	000f4637          	lui	a2,0xf4
    80000040:	24060613          	addi	a2,a2,576 # f4240 <_entry-0x7ff0bdc0>
    80000044:	9732                	add	a4,a4,a2
    80000046:	e398                	sd	a4,0(a5)

  // prepare information in scratch[] for timervec.
  // scratch[0..2] : space for timervec to save registers.
  // scratch[3] : address of CLINT MTIMECMP register.
  // scratch[4] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &timer_scratch[id][0];
    80000048:	00259693          	slli	a3,a1,0x2
    8000004c:	96ae                	add	a3,a3,a1
    8000004e:	068e                	slli	a3,a3,0x3
    80000050:	00009717          	auipc	a4,0x9
    80000054:	b7070713          	addi	a4,a4,-1168 # 80008bc0 <timer_scratch>
    80000058:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    8000005a:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    8000005c:	f310                	sd	a2,32(a4)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    8000005e:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    80000062:	00006797          	auipc	a5,0x6
    80000066:	19e78793          	addi	a5,a5,414 # 80006200 <timervec>
    8000006a:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    8000006e:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000072:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000076:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    8000007a:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    8000007e:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    80000082:	30479073          	csrw	mie,a5
}
    80000086:	6422                	ld	s0,8(sp)
    80000088:	0141                	addi	sp,sp,16
    8000008a:	8082                	ret

000000008000008c <start>:
{
    8000008c:	1141                	addi	sp,sp,-16
    8000008e:	e406                	sd	ra,8(sp)
    80000090:	e022                	sd	s0,0(sp)
    80000092:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000094:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    80000098:	7779                	lui	a4,0xffffe
    8000009a:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffdb7cf>
    8000009e:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a0:	6705                	lui	a4,0x1
    800000a2:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a6:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000a8:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ac:	00001797          	auipc	a5,0x1
    800000b0:	dcc78793          	addi	a5,a5,-564 # 80000e78 <main>
    800000b4:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000b8:	4781                	li	a5,0
    800000ba:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000be:	67c1                	lui	a5,0x10
    800000c0:	17fd                	addi	a5,a5,-1 # ffff <_entry-0x7fff0001>
    800000c2:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c6:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000ca:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000ce:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000d2:	10479073          	csrw	sie,a5
  asm volatile("csrw pmpaddr0, %0" : : "r" (x));
    800000d6:	57fd                	li	a5,-1
    800000d8:	83a9                	srli	a5,a5,0xa
    800000da:	3b079073          	csrw	pmpaddr0,a5
  asm volatile("csrw pmpcfg0, %0" : : "r" (x));
    800000de:	47bd                	li	a5,15
    800000e0:	3a079073          	csrw	pmpcfg0,a5
  timerinit();
    800000e4:	00000097          	auipc	ra,0x0
    800000e8:	f38080e7          	jalr	-200(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000ec:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000f0:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000f2:	823e                	mv	tp,a5
  asm volatile("mret");
    800000f4:	30200073          	mret
}
    800000f8:	60a2                	ld	ra,8(sp)
    800000fa:	6402                	ld	s0,0(sp)
    800000fc:	0141                	addi	sp,sp,16
    800000fe:	8082                	ret

0000000080000100 <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    80000100:	715d                	addi	sp,sp,-80
    80000102:	e486                	sd	ra,72(sp)
    80000104:	e0a2                	sd	s0,64(sp)
    80000106:	fc26                	sd	s1,56(sp)
    80000108:	f84a                	sd	s2,48(sp)
    8000010a:	f44e                	sd	s3,40(sp)
    8000010c:	f052                	sd	s4,32(sp)
    8000010e:	ec56                	sd	s5,24(sp)
    80000110:	0880                	addi	s0,sp,80
  int i;

  for(i = 0; i < n; i++){
    80000112:	04c05763          	blez	a2,80000160 <consolewrite+0x60>
    80000116:	8a2a                	mv	s4,a0
    80000118:	84ae                	mv	s1,a1
    8000011a:	89b2                	mv	s3,a2
    8000011c:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    8000011e:	5afd                	li	s5,-1
    80000120:	4685                	li	a3,1
    80000122:	8626                	mv	a2,s1
    80000124:	85d2                	mv	a1,s4
    80000126:	fbf40513          	addi	a0,s0,-65
    8000012a:	00002097          	auipc	ra,0x2
    8000012e:	6c6080e7          	jalr	1734(ra) # 800027f0 <either_copyin>
    80000132:	01550d63          	beq	a0,s5,8000014c <consolewrite+0x4c>
      break;
    uartputc(c);
    80000136:	fbf44503          	lbu	a0,-65(s0)
    8000013a:	00000097          	auipc	ra,0x0
    8000013e:	784080e7          	jalr	1924(ra) # 800008be <uartputc>
  for(i = 0; i < n; i++){
    80000142:	2905                	addiw	s2,s2,1
    80000144:	0485                	addi	s1,s1,1
    80000146:	fd299de3          	bne	s3,s2,80000120 <consolewrite+0x20>
    8000014a:	894e                	mv	s2,s3
  }

  return i;
}
    8000014c:	854a                	mv	a0,s2
    8000014e:	60a6                	ld	ra,72(sp)
    80000150:	6406                	ld	s0,64(sp)
    80000152:	74e2                	ld	s1,56(sp)
    80000154:	7942                	ld	s2,48(sp)
    80000156:	79a2                	ld	s3,40(sp)
    80000158:	7a02                	ld	s4,32(sp)
    8000015a:	6ae2                	ld	s5,24(sp)
    8000015c:	6161                	addi	sp,sp,80
    8000015e:	8082                	ret
  for(i = 0; i < n; i++){
    80000160:	4901                	li	s2,0
    80000162:	b7ed                	j	8000014c <consolewrite+0x4c>

0000000080000164 <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    80000164:	7159                	addi	sp,sp,-112
    80000166:	f486                	sd	ra,104(sp)
    80000168:	f0a2                	sd	s0,96(sp)
    8000016a:	eca6                	sd	s1,88(sp)
    8000016c:	e8ca                	sd	s2,80(sp)
    8000016e:	e4ce                	sd	s3,72(sp)
    80000170:	e0d2                	sd	s4,64(sp)
    80000172:	fc56                	sd	s5,56(sp)
    80000174:	f85a                	sd	s6,48(sp)
    80000176:	f45e                	sd	s7,40(sp)
    80000178:	f062                	sd	s8,32(sp)
    8000017a:	ec66                	sd	s9,24(sp)
    8000017c:	e86a                	sd	s10,16(sp)
    8000017e:	1880                	addi	s0,sp,112
    80000180:	8aaa                	mv	s5,a0
    80000182:	8a2e                	mv	s4,a1
    80000184:	89b2                	mv	s3,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000186:	00060b1b          	sext.w	s6,a2
  acquire(&cons.lock);
    8000018a:	00011517          	auipc	a0,0x11
    8000018e:	b7650513          	addi	a0,a0,-1162 # 80010d00 <cons>
    80000192:	00001097          	auipc	ra,0x1
    80000196:	a44080e7          	jalr	-1468(ra) # 80000bd6 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019a:	00011497          	auipc	s1,0x11
    8000019e:	b6648493          	addi	s1,s1,-1178 # 80010d00 <cons>
      if(killed(myproc())){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a2:	00011917          	auipc	s2,0x11
    800001a6:	bf690913          	addi	s2,s2,-1034 # 80010d98 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];

    if(c == C('D')){  // end-of-file
    800001aa:	4b91                	li	s7,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001ac:	5c7d                	li	s8,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001ae:	4ca9                	li	s9,10
  while(n > 0){
    800001b0:	07305b63          	blez	s3,80000226 <consoleread+0xc2>
    while(cons.r == cons.w){
    800001b4:	0984a783          	lw	a5,152(s1)
    800001b8:	09c4a703          	lw	a4,156(s1)
    800001bc:	02f71763          	bne	a4,a5,800001ea <consoleread+0x86>
      if(killed(myproc())){
    800001c0:	00001097          	auipc	ra,0x1
    800001c4:	7ec080e7          	jalr	2028(ra) # 800019ac <myproc>
    800001c8:	00002097          	auipc	ra,0x2
    800001cc:	472080e7          	jalr	1138(ra) # 8000263a <killed>
    800001d0:	e535                	bnez	a0,8000023c <consoleread+0xd8>
      sleep(&cons.r, &cons.lock);
    800001d2:	85a6                	mv	a1,s1
    800001d4:	854a                	mv	a0,s2
    800001d6:	00002097          	auipc	ra,0x2
    800001da:	064080e7          	jalr	100(ra) # 8000223a <sleep>
    while(cons.r == cons.w){
    800001de:	0984a783          	lw	a5,152(s1)
    800001e2:	09c4a703          	lw	a4,156(s1)
    800001e6:	fcf70de3          	beq	a4,a5,800001c0 <consoleread+0x5c>
    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];
    800001ea:	0017871b          	addiw	a4,a5,1
    800001ee:	08e4ac23          	sw	a4,152(s1)
    800001f2:	07f7f713          	andi	a4,a5,127
    800001f6:	9726                	add	a4,a4,s1
    800001f8:	01874703          	lbu	a4,24(a4)
    800001fc:	00070d1b          	sext.w	s10,a4
    if(c == C('D')){  // end-of-file
    80000200:	077d0563          	beq	s10,s7,8000026a <consoleread+0x106>
    cbuf = c;
    80000204:	f8e40fa3          	sb	a4,-97(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000208:	4685                	li	a3,1
    8000020a:	f9f40613          	addi	a2,s0,-97
    8000020e:	85d2                	mv	a1,s4
    80000210:	8556                	mv	a0,s5
    80000212:	00002097          	auipc	ra,0x2
    80000216:	588080e7          	jalr	1416(ra) # 8000279a <either_copyout>
    8000021a:	01850663          	beq	a0,s8,80000226 <consoleread+0xc2>
    dst++;
    8000021e:	0a05                	addi	s4,s4,1
    --n;
    80000220:	39fd                	addiw	s3,s3,-1
    if(c == '\n'){
    80000222:	f99d17e3          	bne	s10,s9,800001b0 <consoleread+0x4c>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    80000226:	00011517          	auipc	a0,0x11
    8000022a:	ada50513          	addi	a0,a0,-1318 # 80010d00 <cons>
    8000022e:	00001097          	auipc	ra,0x1
    80000232:	a5c080e7          	jalr	-1444(ra) # 80000c8a <release>

  return target - n;
    80000236:	413b053b          	subw	a0,s6,s3
    8000023a:	a811                	j	8000024e <consoleread+0xea>
        release(&cons.lock);
    8000023c:	00011517          	auipc	a0,0x11
    80000240:	ac450513          	addi	a0,a0,-1340 # 80010d00 <cons>
    80000244:	00001097          	auipc	ra,0x1
    80000248:	a46080e7          	jalr	-1466(ra) # 80000c8a <release>
        return -1;
    8000024c:	557d                	li	a0,-1
}
    8000024e:	70a6                	ld	ra,104(sp)
    80000250:	7406                	ld	s0,96(sp)
    80000252:	64e6                	ld	s1,88(sp)
    80000254:	6946                	ld	s2,80(sp)
    80000256:	69a6                	ld	s3,72(sp)
    80000258:	6a06                	ld	s4,64(sp)
    8000025a:	7ae2                	ld	s5,56(sp)
    8000025c:	7b42                	ld	s6,48(sp)
    8000025e:	7ba2                	ld	s7,40(sp)
    80000260:	7c02                	ld	s8,32(sp)
    80000262:	6ce2                	ld	s9,24(sp)
    80000264:	6d42                	ld	s10,16(sp)
    80000266:	6165                	addi	sp,sp,112
    80000268:	8082                	ret
      if(n < target){
    8000026a:	0009871b          	sext.w	a4,s3
    8000026e:	fb677ce3          	bgeu	a4,s6,80000226 <consoleread+0xc2>
        cons.r--;
    80000272:	00011717          	auipc	a4,0x11
    80000276:	b2f72323          	sw	a5,-1242(a4) # 80010d98 <cons+0x98>
    8000027a:	b775                	j	80000226 <consoleread+0xc2>

000000008000027c <consputc>:
{
    8000027c:	1141                	addi	sp,sp,-16
    8000027e:	e406                	sd	ra,8(sp)
    80000280:	e022                	sd	s0,0(sp)
    80000282:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    80000284:	10000793          	li	a5,256
    80000288:	00f50a63          	beq	a0,a5,8000029c <consputc+0x20>
    uartputc_sync(c);
    8000028c:	00000097          	auipc	ra,0x0
    80000290:	560080e7          	jalr	1376(ra) # 800007ec <uartputc_sync>
}
    80000294:	60a2                	ld	ra,8(sp)
    80000296:	6402                	ld	s0,0(sp)
    80000298:	0141                	addi	sp,sp,16
    8000029a:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    8000029c:	4521                	li	a0,8
    8000029e:	00000097          	auipc	ra,0x0
    800002a2:	54e080e7          	jalr	1358(ra) # 800007ec <uartputc_sync>
    800002a6:	02000513          	li	a0,32
    800002aa:	00000097          	auipc	ra,0x0
    800002ae:	542080e7          	jalr	1346(ra) # 800007ec <uartputc_sync>
    800002b2:	4521                	li	a0,8
    800002b4:	00000097          	auipc	ra,0x0
    800002b8:	538080e7          	jalr	1336(ra) # 800007ec <uartputc_sync>
    800002bc:	bfe1                	j	80000294 <consputc+0x18>

00000000800002be <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002be:	1101                	addi	sp,sp,-32
    800002c0:	ec06                	sd	ra,24(sp)
    800002c2:	e822                	sd	s0,16(sp)
    800002c4:	e426                	sd	s1,8(sp)
    800002c6:	e04a                	sd	s2,0(sp)
    800002c8:	1000                	addi	s0,sp,32
    800002ca:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002cc:	00011517          	auipc	a0,0x11
    800002d0:	a3450513          	addi	a0,a0,-1484 # 80010d00 <cons>
    800002d4:	00001097          	auipc	ra,0x1
    800002d8:	902080e7          	jalr	-1790(ra) # 80000bd6 <acquire>

  switch(c){
    800002dc:	47d5                	li	a5,21
    800002de:	0af48663          	beq	s1,a5,8000038a <consoleintr+0xcc>
    800002e2:	0297ca63          	blt	a5,s1,80000316 <consoleintr+0x58>
    800002e6:	47a1                	li	a5,8
    800002e8:	0ef48763          	beq	s1,a5,800003d6 <consoleintr+0x118>
    800002ec:	47c1                	li	a5,16
    800002ee:	10f49a63          	bne	s1,a5,80000402 <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002f2:	00002097          	auipc	ra,0x2
    800002f6:	554080e7          	jalr	1364(ra) # 80002846 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002fa:	00011517          	auipc	a0,0x11
    800002fe:	a0650513          	addi	a0,a0,-1530 # 80010d00 <cons>
    80000302:	00001097          	auipc	ra,0x1
    80000306:	988080e7          	jalr	-1656(ra) # 80000c8a <release>
}
    8000030a:	60e2                	ld	ra,24(sp)
    8000030c:	6442                	ld	s0,16(sp)
    8000030e:	64a2                	ld	s1,8(sp)
    80000310:	6902                	ld	s2,0(sp)
    80000312:	6105                	addi	sp,sp,32
    80000314:	8082                	ret
  switch(c){
    80000316:	07f00793          	li	a5,127
    8000031a:	0af48e63          	beq	s1,a5,800003d6 <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    8000031e:	00011717          	auipc	a4,0x11
    80000322:	9e270713          	addi	a4,a4,-1566 # 80010d00 <cons>
    80000326:	0a072783          	lw	a5,160(a4)
    8000032a:	09872703          	lw	a4,152(a4)
    8000032e:	9f99                	subw	a5,a5,a4
    80000330:	07f00713          	li	a4,127
    80000334:	fcf763e3          	bltu	a4,a5,800002fa <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    80000338:	47b5                	li	a5,13
    8000033a:	0cf48763          	beq	s1,a5,80000408 <consoleintr+0x14a>
      consputc(c);
    8000033e:	8526                	mv	a0,s1
    80000340:	00000097          	auipc	ra,0x0
    80000344:	f3c080e7          	jalr	-196(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000348:	00011797          	auipc	a5,0x11
    8000034c:	9b878793          	addi	a5,a5,-1608 # 80010d00 <cons>
    80000350:	0a07a683          	lw	a3,160(a5)
    80000354:	0016871b          	addiw	a4,a3,1
    80000358:	0007061b          	sext.w	a2,a4
    8000035c:	0ae7a023          	sw	a4,160(a5)
    80000360:	07f6f693          	andi	a3,a3,127
    80000364:	97b6                	add	a5,a5,a3
    80000366:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e-cons.r == INPUT_BUF_SIZE){
    8000036a:	47a9                	li	a5,10
    8000036c:	0cf48563          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000370:	4791                	li	a5,4
    80000372:	0cf48263          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000376:	00011797          	auipc	a5,0x11
    8000037a:	a227a783          	lw	a5,-1502(a5) # 80010d98 <cons+0x98>
    8000037e:	9f1d                	subw	a4,a4,a5
    80000380:	08000793          	li	a5,128
    80000384:	f6f71be3          	bne	a4,a5,800002fa <consoleintr+0x3c>
    80000388:	a07d                	j	80000436 <consoleintr+0x178>
    while(cons.e != cons.w &&
    8000038a:	00011717          	auipc	a4,0x11
    8000038e:	97670713          	addi	a4,a4,-1674 # 80010d00 <cons>
    80000392:	0a072783          	lw	a5,160(a4)
    80000396:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    8000039a:	00011497          	auipc	s1,0x11
    8000039e:	96648493          	addi	s1,s1,-1690 # 80010d00 <cons>
    while(cons.e != cons.w &&
    800003a2:	4929                	li	s2,10
    800003a4:	f4f70be3          	beq	a4,a5,800002fa <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    800003a8:	37fd                	addiw	a5,a5,-1
    800003aa:	07f7f713          	andi	a4,a5,127
    800003ae:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003b0:	01874703          	lbu	a4,24(a4)
    800003b4:	f52703e3          	beq	a4,s2,800002fa <consoleintr+0x3c>
      cons.e--;
    800003b8:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003bc:	10000513          	li	a0,256
    800003c0:	00000097          	auipc	ra,0x0
    800003c4:	ebc080e7          	jalr	-324(ra) # 8000027c <consputc>
    while(cons.e != cons.w &&
    800003c8:	0a04a783          	lw	a5,160(s1)
    800003cc:	09c4a703          	lw	a4,156(s1)
    800003d0:	fcf71ce3          	bne	a4,a5,800003a8 <consoleintr+0xea>
    800003d4:	b71d                	j	800002fa <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003d6:	00011717          	auipc	a4,0x11
    800003da:	92a70713          	addi	a4,a4,-1750 # 80010d00 <cons>
    800003de:	0a072783          	lw	a5,160(a4)
    800003e2:	09c72703          	lw	a4,156(a4)
    800003e6:	f0f70ae3          	beq	a4,a5,800002fa <consoleintr+0x3c>
      cons.e--;
    800003ea:	37fd                	addiw	a5,a5,-1
    800003ec:	00011717          	auipc	a4,0x11
    800003f0:	9af72a23          	sw	a5,-1612(a4) # 80010da0 <cons+0xa0>
      consputc(BACKSPACE);
    800003f4:	10000513          	li	a0,256
    800003f8:	00000097          	auipc	ra,0x0
    800003fc:	e84080e7          	jalr	-380(ra) # 8000027c <consputc>
    80000400:	bded                	j	800002fa <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    80000402:	ee048ce3          	beqz	s1,800002fa <consoleintr+0x3c>
    80000406:	bf21                	j	8000031e <consoleintr+0x60>
      consputc(c);
    80000408:	4529                	li	a0,10
    8000040a:	00000097          	auipc	ra,0x0
    8000040e:	e72080e7          	jalr	-398(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000412:	00011797          	auipc	a5,0x11
    80000416:	8ee78793          	addi	a5,a5,-1810 # 80010d00 <cons>
    8000041a:	0a07a703          	lw	a4,160(a5)
    8000041e:	0017069b          	addiw	a3,a4,1
    80000422:	0006861b          	sext.w	a2,a3
    80000426:	0ad7a023          	sw	a3,160(a5)
    8000042a:	07f77713          	andi	a4,a4,127
    8000042e:	97ba                	add	a5,a5,a4
    80000430:	4729                	li	a4,10
    80000432:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000436:	00011797          	auipc	a5,0x11
    8000043a:	96c7a323          	sw	a2,-1690(a5) # 80010d9c <cons+0x9c>
        wakeup(&cons.r);
    8000043e:	00011517          	auipc	a0,0x11
    80000442:	95a50513          	addi	a0,a0,-1702 # 80010d98 <cons+0x98>
    80000446:	00002097          	auipc	ra,0x2
    8000044a:	fa4080e7          	jalr	-92(ra) # 800023ea <wakeup>
    8000044e:	b575                	j	800002fa <consoleintr+0x3c>

0000000080000450 <consoleinit>:

void
consoleinit(void)
{
    80000450:	1141                	addi	sp,sp,-16
    80000452:	e406                	sd	ra,8(sp)
    80000454:	e022                	sd	s0,0(sp)
    80000456:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    80000458:	00008597          	auipc	a1,0x8
    8000045c:	bb858593          	addi	a1,a1,-1096 # 80008010 <etext+0x10>
    80000460:	00011517          	auipc	a0,0x11
    80000464:	8a050513          	addi	a0,a0,-1888 # 80010d00 <cons>
    80000468:	00000097          	auipc	ra,0x0
    8000046c:	6de080e7          	jalr	1758(ra) # 80000b46 <initlock>

  uartinit();
    80000470:	00000097          	auipc	ra,0x0
    80000474:	32c080e7          	jalr	812(ra) # 8000079c <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000478:	00022797          	auipc	a5,0x22
    8000047c:	a2078793          	addi	a5,a5,-1504 # 80021e98 <devsw>
    80000480:	00000717          	auipc	a4,0x0
    80000484:	ce470713          	addi	a4,a4,-796 # 80000164 <consoleread>
    80000488:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    8000048a:	00000717          	auipc	a4,0x0
    8000048e:	c7670713          	addi	a4,a4,-906 # 80000100 <consolewrite>
    80000492:	ef98                	sd	a4,24(a5)
}
    80000494:	60a2                	ld	ra,8(sp)
    80000496:	6402                	ld	s0,0(sp)
    80000498:	0141                	addi	sp,sp,16
    8000049a:	8082                	ret

000000008000049c <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    8000049c:	7179                	addi	sp,sp,-48
    8000049e:	f406                	sd	ra,40(sp)
    800004a0:	f022                	sd	s0,32(sp)
    800004a2:	ec26                	sd	s1,24(sp)
    800004a4:	e84a                	sd	s2,16(sp)
    800004a6:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004a8:	c219                	beqz	a2,800004ae <printint+0x12>
    800004aa:	08054763          	bltz	a0,80000538 <printint+0x9c>
    x = -xx;
  else
    x = xx;
    800004ae:	2501                	sext.w	a0,a0
    800004b0:	4881                	li	a7,0
    800004b2:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004b6:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004b8:	2581                	sext.w	a1,a1
    800004ba:	00008617          	auipc	a2,0x8
    800004be:	b8660613          	addi	a2,a2,-1146 # 80008040 <digits>
    800004c2:	883a                	mv	a6,a4
    800004c4:	2705                	addiw	a4,a4,1
    800004c6:	02b577bb          	remuw	a5,a0,a1
    800004ca:	1782                	slli	a5,a5,0x20
    800004cc:	9381                	srli	a5,a5,0x20
    800004ce:	97b2                	add	a5,a5,a2
    800004d0:	0007c783          	lbu	a5,0(a5)
    800004d4:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004d8:	0005079b          	sext.w	a5,a0
    800004dc:	02b5553b          	divuw	a0,a0,a1
    800004e0:	0685                	addi	a3,a3,1
    800004e2:	feb7f0e3          	bgeu	a5,a1,800004c2 <printint+0x26>

  if(sign)
    800004e6:	00088c63          	beqz	a7,800004fe <printint+0x62>
    buf[i++] = '-';
    800004ea:	fe070793          	addi	a5,a4,-32
    800004ee:	00878733          	add	a4,a5,s0
    800004f2:	02d00793          	li	a5,45
    800004f6:	fef70823          	sb	a5,-16(a4)
    800004fa:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    800004fe:	02e05763          	blez	a4,8000052c <printint+0x90>
    80000502:	fd040793          	addi	a5,s0,-48
    80000506:	00e784b3          	add	s1,a5,a4
    8000050a:	fff78913          	addi	s2,a5,-1
    8000050e:	993a                	add	s2,s2,a4
    80000510:	377d                	addiw	a4,a4,-1
    80000512:	1702                	slli	a4,a4,0x20
    80000514:	9301                	srli	a4,a4,0x20
    80000516:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    8000051a:	fff4c503          	lbu	a0,-1(s1)
    8000051e:	00000097          	auipc	ra,0x0
    80000522:	d5e080e7          	jalr	-674(ra) # 8000027c <consputc>
  while(--i >= 0)
    80000526:	14fd                	addi	s1,s1,-1
    80000528:	ff2499e3          	bne	s1,s2,8000051a <printint+0x7e>
}
    8000052c:	70a2                	ld	ra,40(sp)
    8000052e:	7402                	ld	s0,32(sp)
    80000530:	64e2                	ld	s1,24(sp)
    80000532:	6942                	ld	s2,16(sp)
    80000534:	6145                	addi	sp,sp,48
    80000536:	8082                	ret
    x = -xx;
    80000538:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    8000053c:	4885                	li	a7,1
    x = -xx;
    8000053e:	bf95                	j	800004b2 <printint+0x16>

0000000080000540 <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    80000540:	1101                	addi	sp,sp,-32
    80000542:	ec06                	sd	ra,24(sp)
    80000544:	e822                	sd	s0,16(sp)
    80000546:	e426                	sd	s1,8(sp)
    80000548:	1000                	addi	s0,sp,32
    8000054a:	84aa                	mv	s1,a0
  pr.locking = 0;
    8000054c:	00011797          	auipc	a5,0x11
    80000550:	8607aa23          	sw	zero,-1932(a5) # 80010dc0 <pr+0x18>
  printf("panic: ");
    80000554:	00008517          	auipc	a0,0x8
    80000558:	ac450513          	addi	a0,a0,-1340 # 80008018 <etext+0x18>
    8000055c:	00000097          	auipc	ra,0x0
    80000560:	02e080e7          	jalr	46(ra) # 8000058a <printf>
  printf(s);
    80000564:	8526                	mv	a0,s1
    80000566:	00000097          	auipc	ra,0x0
    8000056a:	024080e7          	jalr	36(ra) # 8000058a <printf>
  printf("\n");
    8000056e:	00008517          	auipc	a0,0x8
    80000572:	b5a50513          	addi	a0,a0,-1190 # 800080c8 <digits+0x88>
    80000576:	00000097          	auipc	ra,0x0
    8000057a:	014080e7          	jalr	20(ra) # 8000058a <printf>
  panicked = 1; // freeze uart output from other CPUs
    8000057e:	4785                	li	a5,1
    80000580:	00008717          	auipc	a4,0x8
    80000584:	60f72023          	sw	a5,1536(a4) # 80008b80 <panicked>
  for(;;)
    80000588:	a001                	j	80000588 <panic+0x48>

000000008000058a <printf>:
{
    8000058a:	7131                	addi	sp,sp,-192
    8000058c:	fc86                	sd	ra,120(sp)
    8000058e:	f8a2                	sd	s0,112(sp)
    80000590:	f4a6                	sd	s1,104(sp)
    80000592:	f0ca                	sd	s2,96(sp)
    80000594:	ecce                	sd	s3,88(sp)
    80000596:	e8d2                	sd	s4,80(sp)
    80000598:	e4d6                	sd	s5,72(sp)
    8000059a:	e0da                	sd	s6,64(sp)
    8000059c:	fc5e                	sd	s7,56(sp)
    8000059e:	f862                	sd	s8,48(sp)
    800005a0:	f466                	sd	s9,40(sp)
    800005a2:	f06a                	sd	s10,32(sp)
    800005a4:	ec6e                	sd	s11,24(sp)
    800005a6:	0100                	addi	s0,sp,128
    800005a8:	8a2a                	mv	s4,a0
    800005aa:	e40c                	sd	a1,8(s0)
    800005ac:	e810                	sd	a2,16(s0)
    800005ae:	ec14                	sd	a3,24(s0)
    800005b0:	f018                	sd	a4,32(s0)
    800005b2:	f41c                	sd	a5,40(s0)
    800005b4:	03043823          	sd	a6,48(s0)
    800005b8:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005bc:	00011d97          	auipc	s11,0x11
    800005c0:	804dad83          	lw	s11,-2044(s11) # 80010dc0 <pr+0x18>
  if(locking)
    800005c4:	020d9b63          	bnez	s11,800005fa <printf+0x70>
  if (fmt == 0)
    800005c8:	040a0263          	beqz	s4,8000060c <printf+0x82>
  va_start(ap, fmt);
    800005cc:	00840793          	addi	a5,s0,8
    800005d0:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005d4:	000a4503          	lbu	a0,0(s4)
    800005d8:	14050f63          	beqz	a0,80000736 <printf+0x1ac>
    800005dc:	4981                	li	s3,0
    if(c != '%'){
    800005de:	02500a93          	li	s5,37
    switch(c){
    800005e2:	07000b93          	li	s7,112
  consputc('x');
    800005e6:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005e8:	00008b17          	auipc	s6,0x8
    800005ec:	a58b0b13          	addi	s6,s6,-1448 # 80008040 <digits>
    switch(c){
    800005f0:	07300c93          	li	s9,115
    800005f4:	06400c13          	li	s8,100
    800005f8:	a82d                	j	80000632 <printf+0xa8>
    acquire(&pr.lock);
    800005fa:	00010517          	auipc	a0,0x10
    800005fe:	7ae50513          	addi	a0,a0,1966 # 80010da8 <pr>
    80000602:	00000097          	auipc	ra,0x0
    80000606:	5d4080e7          	jalr	1492(ra) # 80000bd6 <acquire>
    8000060a:	bf7d                	j	800005c8 <printf+0x3e>
    panic("null fmt");
    8000060c:	00008517          	auipc	a0,0x8
    80000610:	a1c50513          	addi	a0,a0,-1508 # 80008028 <etext+0x28>
    80000614:	00000097          	auipc	ra,0x0
    80000618:	f2c080e7          	jalr	-212(ra) # 80000540 <panic>
      consputc(c);
    8000061c:	00000097          	auipc	ra,0x0
    80000620:	c60080e7          	jalr	-928(ra) # 8000027c <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000624:	2985                	addiw	s3,s3,1
    80000626:	013a07b3          	add	a5,s4,s3
    8000062a:	0007c503          	lbu	a0,0(a5)
    8000062e:	10050463          	beqz	a0,80000736 <printf+0x1ac>
    if(c != '%'){
    80000632:	ff5515e3          	bne	a0,s5,8000061c <printf+0x92>
    c = fmt[++i] & 0xff;
    80000636:	2985                	addiw	s3,s3,1
    80000638:	013a07b3          	add	a5,s4,s3
    8000063c:	0007c783          	lbu	a5,0(a5)
    80000640:	0007849b          	sext.w	s1,a5
    if(c == 0)
    80000644:	cbed                	beqz	a5,80000736 <printf+0x1ac>
    switch(c){
    80000646:	05778a63          	beq	a5,s7,8000069a <printf+0x110>
    8000064a:	02fbf663          	bgeu	s7,a5,80000676 <printf+0xec>
    8000064e:	09978863          	beq	a5,s9,800006de <printf+0x154>
    80000652:	07800713          	li	a4,120
    80000656:	0ce79563          	bne	a5,a4,80000720 <printf+0x196>
      printint(va_arg(ap, int), 16, 1);
    8000065a:	f8843783          	ld	a5,-120(s0)
    8000065e:	00878713          	addi	a4,a5,8
    80000662:	f8e43423          	sd	a4,-120(s0)
    80000666:	4605                	li	a2,1
    80000668:	85ea                	mv	a1,s10
    8000066a:	4388                	lw	a0,0(a5)
    8000066c:	00000097          	auipc	ra,0x0
    80000670:	e30080e7          	jalr	-464(ra) # 8000049c <printint>
      break;
    80000674:	bf45                	j	80000624 <printf+0x9a>
    switch(c){
    80000676:	09578f63          	beq	a5,s5,80000714 <printf+0x18a>
    8000067a:	0b879363          	bne	a5,s8,80000720 <printf+0x196>
      printint(va_arg(ap, int), 10, 1);
    8000067e:	f8843783          	ld	a5,-120(s0)
    80000682:	00878713          	addi	a4,a5,8
    80000686:	f8e43423          	sd	a4,-120(s0)
    8000068a:	4605                	li	a2,1
    8000068c:	45a9                	li	a1,10
    8000068e:	4388                	lw	a0,0(a5)
    80000690:	00000097          	auipc	ra,0x0
    80000694:	e0c080e7          	jalr	-500(ra) # 8000049c <printint>
      break;
    80000698:	b771                	j	80000624 <printf+0x9a>
      printptr(va_arg(ap, uint64));
    8000069a:	f8843783          	ld	a5,-120(s0)
    8000069e:	00878713          	addi	a4,a5,8
    800006a2:	f8e43423          	sd	a4,-120(s0)
    800006a6:	0007b903          	ld	s2,0(a5)
  consputc('0');
    800006aa:	03000513          	li	a0,48
    800006ae:	00000097          	auipc	ra,0x0
    800006b2:	bce080e7          	jalr	-1074(ra) # 8000027c <consputc>
  consputc('x');
    800006b6:	07800513          	li	a0,120
    800006ba:	00000097          	auipc	ra,0x0
    800006be:	bc2080e7          	jalr	-1086(ra) # 8000027c <consputc>
    800006c2:	84ea                	mv	s1,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006c4:	03c95793          	srli	a5,s2,0x3c
    800006c8:	97da                	add	a5,a5,s6
    800006ca:	0007c503          	lbu	a0,0(a5)
    800006ce:	00000097          	auipc	ra,0x0
    800006d2:	bae080e7          	jalr	-1106(ra) # 8000027c <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006d6:	0912                	slli	s2,s2,0x4
    800006d8:	34fd                	addiw	s1,s1,-1
    800006da:	f4ed                	bnez	s1,800006c4 <printf+0x13a>
    800006dc:	b7a1                	j	80000624 <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006de:	f8843783          	ld	a5,-120(s0)
    800006e2:	00878713          	addi	a4,a5,8
    800006e6:	f8e43423          	sd	a4,-120(s0)
    800006ea:	6384                	ld	s1,0(a5)
    800006ec:	cc89                	beqz	s1,80000706 <printf+0x17c>
      for(; *s; s++)
    800006ee:	0004c503          	lbu	a0,0(s1)
    800006f2:	d90d                	beqz	a0,80000624 <printf+0x9a>
        consputc(*s);
    800006f4:	00000097          	auipc	ra,0x0
    800006f8:	b88080e7          	jalr	-1144(ra) # 8000027c <consputc>
      for(; *s; s++)
    800006fc:	0485                	addi	s1,s1,1
    800006fe:	0004c503          	lbu	a0,0(s1)
    80000702:	f96d                	bnez	a0,800006f4 <printf+0x16a>
    80000704:	b705                	j	80000624 <printf+0x9a>
        s = "(null)";
    80000706:	00008497          	auipc	s1,0x8
    8000070a:	91a48493          	addi	s1,s1,-1766 # 80008020 <etext+0x20>
      for(; *s; s++)
    8000070e:	02800513          	li	a0,40
    80000712:	b7cd                	j	800006f4 <printf+0x16a>
      consputc('%');
    80000714:	8556                	mv	a0,s5
    80000716:	00000097          	auipc	ra,0x0
    8000071a:	b66080e7          	jalr	-1178(ra) # 8000027c <consputc>
      break;
    8000071e:	b719                	j	80000624 <printf+0x9a>
      consputc('%');
    80000720:	8556                	mv	a0,s5
    80000722:	00000097          	auipc	ra,0x0
    80000726:	b5a080e7          	jalr	-1190(ra) # 8000027c <consputc>
      consputc(c);
    8000072a:	8526                	mv	a0,s1
    8000072c:	00000097          	auipc	ra,0x0
    80000730:	b50080e7          	jalr	-1200(ra) # 8000027c <consputc>
      break;
    80000734:	bdc5                	j	80000624 <printf+0x9a>
  if(locking)
    80000736:	020d9163          	bnez	s11,80000758 <printf+0x1ce>
}
    8000073a:	70e6                	ld	ra,120(sp)
    8000073c:	7446                	ld	s0,112(sp)
    8000073e:	74a6                	ld	s1,104(sp)
    80000740:	7906                	ld	s2,96(sp)
    80000742:	69e6                	ld	s3,88(sp)
    80000744:	6a46                	ld	s4,80(sp)
    80000746:	6aa6                	ld	s5,72(sp)
    80000748:	6b06                	ld	s6,64(sp)
    8000074a:	7be2                	ld	s7,56(sp)
    8000074c:	7c42                	ld	s8,48(sp)
    8000074e:	7ca2                	ld	s9,40(sp)
    80000750:	7d02                	ld	s10,32(sp)
    80000752:	6de2                	ld	s11,24(sp)
    80000754:	6129                	addi	sp,sp,192
    80000756:	8082                	ret
    release(&pr.lock);
    80000758:	00010517          	auipc	a0,0x10
    8000075c:	65050513          	addi	a0,a0,1616 # 80010da8 <pr>
    80000760:	00000097          	auipc	ra,0x0
    80000764:	52a080e7          	jalr	1322(ra) # 80000c8a <release>
}
    80000768:	bfc9                	j	8000073a <printf+0x1b0>

000000008000076a <printfinit>:
    ;
}

void
printfinit(void)
{
    8000076a:	1101                	addi	sp,sp,-32
    8000076c:	ec06                	sd	ra,24(sp)
    8000076e:	e822                	sd	s0,16(sp)
    80000770:	e426                	sd	s1,8(sp)
    80000772:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    80000774:	00010497          	auipc	s1,0x10
    80000778:	63448493          	addi	s1,s1,1588 # 80010da8 <pr>
    8000077c:	00008597          	auipc	a1,0x8
    80000780:	8bc58593          	addi	a1,a1,-1860 # 80008038 <etext+0x38>
    80000784:	8526                	mv	a0,s1
    80000786:	00000097          	auipc	ra,0x0
    8000078a:	3c0080e7          	jalr	960(ra) # 80000b46 <initlock>
  pr.locking = 1;
    8000078e:	4785                	li	a5,1
    80000790:	cc9c                	sw	a5,24(s1)
}
    80000792:	60e2                	ld	ra,24(sp)
    80000794:	6442                	ld	s0,16(sp)
    80000796:	64a2                	ld	s1,8(sp)
    80000798:	6105                	addi	sp,sp,32
    8000079a:	8082                	ret

000000008000079c <uartinit>:

void uartstart();

void
uartinit(void)
{
    8000079c:	1141                	addi	sp,sp,-16
    8000079e:	e406                	sd	ra,8(sp)
    800007a0:	e022                	sd	s0,0(sp)
    800007a2:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007a4:	100007b7          	lui	a5,0x10000
    800007a8:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007ac:	f8000713          	li	a4,-128
    800007b0:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007b4:	470d                	li	a4,3
    800007b6:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007ba:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007be:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007c2:	469d                	li	a3,7
    800007c4:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007c8:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007cc:	00008597          	auipc	a1,0x8
    800007d0:	88c58593          	addi	a1,a1,-1908 # 80008058 <digits+0x18>
    800007d4:	00010517          	auipc	a0,0x10
    800007d8:	5f450513          	addi	a0,a0,1524 # 80010dc8 <uart_tx_lock>
    800007dc:	00000097          	auipc	ra,0x0
    800007e0:	36a080e7          	jalr	874(ra) # 80000b46 <initlock>
}
    800007e4:	60a2                	ld	ra,8(sp)
    800007e6:	6402                	ld	s0,0(sp)
    800007e8:	0141                	addi	sp,sp,16
    800007ea:	8082                	ret

00000000800007ec <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007ec:	1101                	addi	sp,sp,-32
    800007ee:	ec06                	sd	ra,24(sp)
    800007f0:	e822                	sd	s0,16(sp)
    800007f2:	e426                	sd	s1,8(sp)
    800007f4:	1000                	addi	s0,sp,32
    800007f6:	84aa                	mv	s1,a0
  push_off();
    800007f8:	00000097          	auipc	ra,0x0
    800007fc:	392080e7          	jalr	914(ra) # 80000b8a <push_off>

  if(panicked){
    80000800:	00008797          	auipc	a5,0x8
    80000804:	3807a783          	lw	a5,896(a5) # 80008b80 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000808:	10000737          	lui	a4,0x10000
  if(panicked){
    8000080c:	c391                	beqz	a5,80000810 <uartputc_sync+0x24>
    for(;;)
    8000080e:	a001                	j	8000080e <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000810:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80000814:	0207f793          	andi	a5,a5,32
    80000818:	dfe5                	beqz	a5,80000810 <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    8000081a:	0ff4f513          	zext.b	a0,s1
    8000081e:	100007b7          	lui	a5,0x10000
    80000822:	00a78023          	sb	a0,0(a5) # 10000000 <_entry-0x70000000>

  pop_off();
    80000826:	00000097          	auipc	ra,0x0
    8000082a:	404080e7          	jalr	1028(ra) # 80000c2a <pop_off>
}
    8000082e:	60e2                	ld	ra,24(sp)
    80000830:	6442                	ld	s0,16(sp)
    80000832:	64a2                	ld	s1,8(sp)
    80000834:	6105                	addi	sp,sp,32
    80000836:	8082                	ret

0000000080000838 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000838:	00008797          	auipc	a5,0x8
    8000083c:	3507b783          	ld	a5,848(a5) # 80008b88 <uart_tx_r>
    80000840:	00008717          	auipc	a4,0x8
    80000844:	35073703          	ld	a4,848(a4) # 80008b90 <uart_tx_w>
    80000848:	06f70a63          	beq	a4,a5,800008bc <uartstart+0x84>
{
    8000084c:	7139                	addi	sp,sp,-64
    8000084e:	fc06                	sd	ra,56(sp)
    80000850:	f822                	sd	s0,48(sp)
    80000852:	f426                	sd	s1,40(sp)
    80000854:	f04a                	sd	s2,32(sp)
    80000856:	ec4e                	sd	s3,24(sp)
    80000858:	e852                	sd	s4,16(sp)
    8000085a:	e456                	sd	s5,8(sp)
    8000085c:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    8000085e:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000862:	00010a17          	auipc	s4,0x10
    80000866:	566a0a13          	addi	s4,s4,1382 # 80010dc8 <uart_tx_lock>
    uart_tx_r += 1;
    8000086a:	00008497          	auipc	s1,0x8
    8000086e:	31e48493          	addi	s1,s1,798 # 80008b88 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    80000872:	00008997          	auipc	s3,0x8
    80000876:	31e98993          	addi	s3,s3,798 # 80008b90 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    8000087a:	00594703          	lbu	a4,5(s2) # 10000005 <_entry-0x6ffffffb>
    8000087e:	02077713          	andi	a4,a4,32
    80000882:	c705                	beqz	a4,800008aa <uartstart+0x72>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000884:	01f7f713          	andi	a4,a5,31
    80000888:	9752                	add	a4,a4,s4
    8000088a:	01874a83          	lbu	s5,24(a4)
    uart_tx_r += 1;
    8000088e:	0785                	addi	a5,a5,1
    80000890:	e09c                	sd	a5,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    80000892:	8526                	mv	a0,s1
    80000894:	00002097          	auipc	ra,0x2
    80000898:	b56080e7          	jalr	-1194(ra) # 800023ea <wakeup>
    
    WriteReg(THR, c);
    8000089c:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    800008a0:	609c                	ld	a5,0(s1)
    800008a2:	0009b703          	ld	a4,0(s3)
    800008a6:	fcf71ae3          	bne	a4,a5,8000087a <uartstart+0x42>
  }
}
    800008aa:	70e2                	ld	ra,56(sp)
    800008ac:	7442                	ld	s0,48(sp)
    800008ae:	74a2                	ld	s1,40(sp)
    800008b0:	7902                	ld	s2,32(sp)
    800008b2:	69e2                	ld	s3,24(sp)
    800008b4:	6a42                	ld	s4,16(sp)
    800008b6:	6aa2                	ld	s5,8(sp)
    800008b8:	6121                	addi	sp,sp,64
    800008ba:	8082                	ret
    800008bc:	8082                	ret

00000000800008be <uartputc>:
{
    800008be:	7179                	addi	sp,sp,-48
    800008c0:	f406                	sd	ra,40(sp)
    800008c2:	f022                	sd	s0,32(sp)
    800008c4:	ec26                	sd	s1,24(sp)
    800008c6:	e84a                	sd	s2,16(sp)
    800008c8:	e44e                	sd	s3,8(sp)
    800008ca:	e052                	sd	s4,0(sp)
    800008cc:	1800                	addi	s0,sp,48
    800008ce:	8a2a                	mv	s4,a0
  acquire(&uart_tx_lock);
    800008d0:	00010517          	auipc	a0,0x10
    800008d4:	4f850513          	addi	a0,a0,1272 # 80010dc8 <uart_tx_lock>
    800008d8:	00000097          	auipc	ra,0x0
    800008dc:	2fe080e7          	jalr	766(ra) # 80000bd6 <acquire>
  if(panicked){
    800008e0:	00008797          	auipc	a5,0x8
    800008e4:	2a07a783          	lw	a5,672(a5) # 80008b80 <panicked>
    800008e8:	e7c9                	bnez	a5,80000972 <uartputc+0xb4>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008ea:	00008717          	auipc	a4,0x8
    800008ee:	2a673703          	ld	a4,678(a4) # 80008b90 <uart_tx_w>
    800008f2:	00008797          	auipc	a5,0x8
    800008f6:	2967b783          	ld	a5,662(a5) # 80008b88 <uart_tx_r>
    800008fa:	02078793          	addi	a5,a5,32
    sleep(&uart_tx_r, &uart_tx_lock);
    800008fe:	00010997          	auipc	s3,0x10
    80000902:	4ca98993          	addi	s3,s3,1226 # 80010dc8 <uart_tx_lock>
    80000906:	00008497          	auipc	s1,0x8
    8000090a:	28248493          	addi	s1,s1,642 # 80008b88 <uart_tx_r>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    8000090e:	00008917          	auipc	s2,0x8
    80000912:	28290913          	addi	s2,s2,642 # 80008b90 <uart_tx_w>
    80000916:	00e79f63          	bne	a5,a4,80000934 <uartputc+0x76>
    sleep(&uart_tx_r, &uart_tx_lock);
    8000091a:	85ce                	mv	a1,s3
    8000091c:	8526                	mv	a0,s1
    8000091e:	00002097          	auipc	ra,0x2
    80000922:	91c080e7          	jalr	-1764(ra) # 8000223a <sleep>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000926:	00093703          	ld	a4,0(s2)
    8000092a:	609c                	ld	a5,0(s1)
    8000092c:	02078793          	addi	a5,a5,32
    80000930:	fee785e3          	beq	a5,a4,8000091a <uartputc+0x5c>
  uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000934:	00010497          	auipc	s1,0x10
    80000938:	49448493          	addi	s1,s1,1172 # 80010dc8 <uart_tx_lock>
    8000093c:	01f77793          	andi	a5,a4,31
    80000940:	97a6                	add	a5,a5,s1
    80000942:	01478c23          	sb	s4,24(a5)
  uart_tx_w += 1;
    80000946:	0705                	addi	a4,a4,1
    80000948:	00008797          	auipc	a5,0x8
    8000094c:	24e7b423          	sd	a4,584(a5) # 80008b90 <uart_tx_w>
  uartstart();
    80000950:	00000097          	auipc	ra,0x0
    80000954:	ee8080e7          	jalr	-280(ra) # 80000838 <uartstart>
  release(&uart_tx_lock);
    80000958:	8526                	mv	a0,s1
    8000095a:	00000097          	auipc	ra,0x0
    8000095e:	330080e7          	jalr	816(ra) # 80000c8a <release>
}
    80000962:	70a2                	ld	ra,40(sp)
    80000964:	7402                	ld	s0,32(sp)
    80000966:	64e2                	ld	s1,24(sp)
    80000968:	6942                	ld	s2,16(sp)
    8000096a:	69a2                	ld	s3,8(sp)
    8000096c:	6a02                	ld	s4,0(sp)
    8000096e:	6145                	addi	sp,sp,48
    80000970:	8082                	ret
    for(;;)
    80000972:	a001                	j	80000972 <uartputc+0xb4>

0000000080000974 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    80000974:	1141                	addi	sp,sp,-16
    80000976:	e422                	sd	s0,8(sp)
    80000978:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    8000097a:	100007b7          	lui	a5,0x10000
    8000097e:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    80000982:	8b85                	andi	a5,a5,1
    80000984:	cb81                	beqz	a5,80000994 <uartgetc+0x20>
    // input data is ready.
    return ReadReg(RHR);
    80000986:	100007b7          	lui	a5,0x10000
    8000098a:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
  } else {
    return -1;
  }
}
    8000098e:	6422                	ld	s0,8(sp)
    80000990:	0141                	addi	sp,sp,16
    80000992:	8082                	ret
    return -1;
    80000994:	557d                	li	a0,-1
    80000996:	bfe5                	j	8000098e <uartgetc+0x1a>

0000000080000998 <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from devintr().
void
uartintr(void)
{
    80000998:	1101                	addi	sp,sp,-32
    8000099a:	ec06                	sd	ra,24(sp)
    8000099c:	e822                	sd	s0,16(sp)
    8000099e:	e426                	sd	s1,8(sp)
    800009a0:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009a2:	54fd                	li	s1,-1
    800009a4:	a029                	j	800009ae <uartintr+0x16>
      break;
    consoleintr(c);
    800009a6:	00000097          	auipc	ra,0x0
    800009aa:	918080e7          	jalr	-1768(ra) # 800002be <consoleintr>
    int c = uartgetc();
    800009ae:	00000097          	auipc	ra,0x0
    800009b2:	fc6080e7          	jalr	-58(ra) # 80000974 <uartgetc>
    if(c == -1)
    800009b6:	fe9518e3          	bne	a0,s1,800009a6 <uartintr+0xe>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009ba:	00010497          	auipc	s1,0x10
    800009be:	40e48493          	addi	s1,s1,1038 # 80010dc8 <uart_tx_lock>
    800009c2:	8526                	mv	a0,s1
    800009c4:	00000097          	auipc	ra,0x0
    800009c8:	212080e7          	jalr	530(ra) # 80000bd6 <acquire>
  uartstart();
    800009cc:	00000097          	auipc	ra,0x0
    800009d0:	e6c080e7          	jalr	-404(ra) # 80000838 <uartstart>
  release(&uart_tx_lock);
    800009d4:	8526                	mv	a0,s1
    800009d6:	00000097          	auipc	ra,0x0
    800009da:	2b4080e7          	jalr	692(ra) # 80000c8a <release>
}
    800009de:	60e2                	ld	ra,24(sp)
    800009e0:	6442                	ld	s0,16(sp)
    800009e2:	64a2                	ld	s1,8(sp)
    800009e4:	6105                	addi	sp,sp,32
    800009e6:	8082                	ret

00000000800009e8 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    800009e8:	1101                	addi	sp,sp,-32
    800009ea:	ec06                	sd	ra,24(sp)
    800009ec:	e822                	sd	s0,16(sp)
    800009ee:	e426                	sd	s1,8(sp)
    800009f0:	e04a                	sd	s2,0(sp)
    800009f2:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    800009f4:	03451793          	slli	a5,a0,0x34
    800009f8:	ebb9                	bnez	a5,80000a4e <kfree+0x66>
    800009fa:	84aa                	mv	s1,a0
    800009fc:	00022797          	auipc	a5,0x22
    80000a00:	63478793          	addi	a5,a5,1588 # 80023030 <end>
    80000a04:	04f56563          	bltu	a0,a5,80000a4e <kfree+0x66>
    80000a08:	47c5                	li	a5,17
    80000a0a:	07ee                	slli	a5,a5,0x1b
    80000a0c:	04f57163          	bgeu	a0,a5,80000a4e <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a10:	6605                	lui	a2,0x1
    80000a12:	4585                	li	a1,1
    80000a14:	00000097          	auipc	ra,0x0
    80000a18:	2be080e7          	jalr	702(ra) # 80000cd2 <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a1c:	00010917          	auipc	s2,0x10
    80000a20:	3e490913          	addi	s2,s2,996 # 80010e00 <kmem>
    80000a24:	854a                	mv	a0,s2
    80000a26:	00000097          	auipc	ra,0x0
    80000a2a:	1b0080e7          	jalr	432(ra) # 80000bd6 <acquire>
  r->next = kmem.freelist;
    80000a2e:	01893783          	ld	a5,24(s2)
    80000a32:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a34:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a38:	854a                	mv	a0,s2
    80000a3a:	00000097          	auipc	ra,0x0
    80000a3e:	250080e7          	jalr	592(ra) # 80000c8a <release>
}
    80000a42:	60e2                	ld	ra,24(sp)
    80000a44:	6442                	ld	s0,16(sp)
    80000a46:	64a2                	ld	s1,8(sp)
    80000a48:	6902                	ld	s2,0(sp)
    80000a4a:	6105                	addi	sp,sp,32
    80000a4c:	8082                	ret
    panic("kfree");
    80000a4e:	00007517          	auipc	a0,0x7
    80000a52:	61250513          	addi	a0,a0,1554 # 80008060 <digits+0x20>
    80000a56:	00000097          	auipc	ra,0x0
    80000a5a:	aea080e7          	jalr	-1302(ra) # 80000540 <panic>

0000000080000a5e <freerange>:
{
    80000a5e:	7179                	addi	sp,sp,-48
    80000a60:	f406                	sd	ra,40(sp)
    80000a62:	f022                	sd	s0,32(sp)
    80000a64:	ec26                	sd	s1,24(sp)
    80000a66:	e84a                	sd	s2,16(sp)
    80000a68:	e44e                	sd	s3,8(sp)
    80000a6a:	e052                	sd	s4,0(sp)
    80000a6c:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000a6e:	6785                	lui	a5,0x1
    80000a70:	fff78713          	addi	a4,a5,-1 # fff <_entry-0x7ffff001>
    80000a74:	00e504b3          	add	s1,a0,a4
    80000a78:	777d                	lui	a4,0xfffff
    80000a7a:	8cf9                	and	s1,s1,a4
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a7c:	94be                	add	s1,s1,a5
    80000a7e:	0095ee63          	bltu	a1,s1,80000a9a <freerange+0x3c>
    80000a82:	892e                	mv	s2,a1
    kfree(p);
    80000a84:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a86:	6985                	lui	s3,0x1
    kfree(p);
    80000a88:	01448533          	add	a0,s1,s4
    80000a8c:	00000097          	auipc	ra,0x0
    80000a90:	f5c080e7          	jalr	-164(ra) # 800009e8 <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a94:	94ce                	add	s1,s1,s3
    80000a96:	fe9979e3          	bgeu	s2,s1,80000a88 <freerange+0x2a>
}
    80000a9a:	70a2                	ld	ra,40(sp)
    80000a9c:	7402                	ld	s0,32(sp)
    80000a9e:	64e2                	ld	s1,24(sp)
    80000aa0:	6942                	ld	s2,16(sp)
    80000aa2:	69a2                	ld	s3,8(sp)
    80000aa4:	6a02                	ld	s4,0(sp)
    80000aa6:	6145                	addi	sp,sp,48
    80000aa8:	8082                	ret

0000000080000aaa <kinit>:
{
    80000aaa:	1141                	addi	sp,sp,-16
    80000aac:	e406                	sd	ra,8(sp)
    80000aae:	e022                	sd	s0,0(sp)
    80000ab0:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000ab2:	00007597          	auipc	a1,0x7
    80000ab6:	5b658593          	addi	a1,a1,1462 # 80008068 <digits+0x28>
    80000aba:	00010517          	auipc	a0,0x10
    80000abe:	34650513          	addi	a0,a0,838 # 80010e00 <kmem>
    80000ac2:	00000097          	auipc	ra,0x0
    80000ac6:	084080e7          	jalr	132(ra) # 80000b46 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000aca:	45c5                	li	a1,17
    80000acc:	05ee                	slli	a1,a1,0x1b
    80000ace:	00022517          	auipc	a0,0x22
    80000ad2:	56250513          	addi	a0,a0,1378 # 80023030 <end>
    80000ad6:	00000097          	auipc	ra,0x0
    80000ada:	f88080e7          	jalr	-120(ra) # 80000a5e <freerange>
}
    80000ade:	60a2                	ld	ra,8(sp)
    80000ae0:	6402                	ld	s0,0(sp)
    80000ae2:	0141                	addi	sp,sp,16
    80000ae4:	8082                	ret

0000000080000ae6 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000ae6:	1101                	addi	sp,sp,-32
    80000ae8:	ec06                	sd	ra,24(sp)
    80000aea:	e822                	sd	s0,16(sp)
    80000aec:	e426                	sd	s1,8(sp)
    80000aee:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000af0:	00010497          	auipc	s1,0x10
    80000af4:	31048493          	addi	s1,s1,784 # 80010e00 <kmem>
    80000af8:	8526                	mv	a0,s1
    80000afa:	00000097          	auipc	ra,0x0
    80000afe:	0dc080e7          	jalr	220(ra) # 80000bd6 <acquire>
  r = kmem.freelist;
    80000b02:	6c84                	ld	s1,24(s1)
  if(r)
    80000b04:	c885                	beqz	s1,80000b34 <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b06:	609c                	ld	a5,0(s1)
    80000b08:	00010517          	auipc	a0,0x10
    80000b0c:	2f850513          	addi	a0,a0,760 # 80010e00 <kmem>
    80000b10:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b12:	00000097          	auipc	ra,0x0
    80000b16:	178080e7          	jalr	376(ra) # 80000c8a <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b1a:	6605                	lui	a2,0x1
    80000b1c:	4595                	li	a1,5
    80000b1e:	8526                	mv	a0,s1
    80000b20:	00000097          	auipc	ra,0x0
    80000b24:	1b2080e7          	jalr	434(ra) # 80000cd2 <memset>
  return (void*)r;
}
    80000b28:	8526                	mv	a0,s1
    80000b2a:	60e2                	ld	ra,24(sp)
    80000b2c:	6442                	ld	s0,16(sp)
    80000b2e:	64a2                	ld	s1,8(sp)
    80000b30:	6105                	addi	sp,sp,32
    80000b32:	8082                	ret
  release(&kmem.lock);
    80000b34:	00010517          	auipc	a0,0x10
    80000b38:	2cc50513          	addi	a0,a0,716 # 80010e00 <kmem>
    80000b3c:	00000097          	auipc	ra,0x0
    80000b40:	14e080e7          	jalr	334(ra) # 80000c8a <release>
  if(r)
    80000b44:	b7d5                	j	80000b28 <kalloc+0x42>

0000000080000b46 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b46:	1141                	addi	sp,sp,-16
    80000b48:	e422                	sd	s0,8(sp)
    80000b4a:	0800                	addi	s0,sp,16
  lk->name = name;
    80000b4c:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000b4e:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000b52:	00053823          	sd	zero,16(a0)
}
    80000b56:	6422                	ld	s0,8(sp)
    80000b58:	0141                	addi	sp,sp,16
    80000b5a:	8082                	ret

0000000080000b5c <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000b5c:	411c                	lw	a5,0(a0)
    80000b5e:	e399                	bnez	a5,80000b64 <holding+0x8>
    80000b60:	4501                	li	a0,0
  return r;
}
    80000b62:	8082                	ret
{
    80000b64:	1101                	addi	sp,sp,-32
    80000b66:	ec06                	sd	ra,24(sp)
    80000b68:	e822                	sd	s0,16(sp)
    80000b6a:	e426                	sd	s1,8(sp)
    80000b6c:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000b6e:	6904                	ld	s1,16(a0)
    80000b70:	00001097          	auipc	ra,0x1
    80000b74:	e20080e7          	jalr	-480(ra) # 80001990 <mycpu>
    80000b78:	40a48533          	sub	a0,s1,a0
    80000b7c:	00153513          	seqz	a0,a0
}
    80000b80:	60e2                	ld	ra,24(sp)
    80000b82:	6442                	ld	s0,16(sp)
    80000b84:	64a2                	ld	s1,8(sp)
    80000b86:	6105                	addi	sp,sp,32
    80000b88:	8082                	ret

0000000080000b8a <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000b8a:	1101                	addi	sp,sp,-32
    80000b8c:	ec06                	sd	ra,24(sp)
    80000b8e:	e822                	sd	s0,16(sp)
    80000b90:	e426                	sd	s1,8(sp)
    80000b92:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000b94:	100024f3          	csrr	s1,sstatus
    80000b98:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000b9c:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000b9e:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000ba2:	00001097          	auipc	ra,0x1
    80000ba6:	dee080e7          	jalr	-530(ra) # 80001990 <mycpu>
    80000baa:	5d3c                	lw	a5,120(a0)
    80000bac:	cf89                	beqz	a5,80000bc6 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bae:	00001097          	auipc	ra,0x1
    80000bb2:	de2080e7          	jalr	-542(ra) # 80001990 <mycpu>
    80000bb6:	5d3c                	lw	a5,120(a0)
    80000bb8:	2785                	addiw	a5,a5,1
    80000bba:	dd3c                	sw	a5,120(a0)
}
    80000bbc:	60e2                	ld	ra,24(sp)
    80000bbe:	6442                	ld	s0,16(sp)
    80000bc0:	64a2                	ld	s1,8(sp)
    80000bc2:	6105                	addi	sp,sp,32
    80000bc4:	8082                	ret
    mycpu()->intena = old;
    80000bc6:	00001097          	auipc	ra,0x1
    80000bca:	dca080e7          	jalr	-566(ra) # 80001990 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000bce:	8085                	srli	s1,s1,0x1
    80000bd0:	8885                	andi	s1,s1,1
    80000bd2:	dd64                	sw	s1,124(a0)
    80000bd4:	bfe9                	j	80000bae <push_off+0x24>

0000000080000bd6 <acquire>:
{
    80000bd6:	1101                	addi	sp,sp,-32
    80000bd8:	ec06                	sd	ra,24(sp)
    80000bda:	e822                	sd	s0,16(sp)
    80000bdc:	e426                	sd	s1,8(sp)
    80000bde:	1000                	addi	s0,sp,32
    80000be0:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000be2:	00000097          	auipc	ra,0x0
    80000be6:	fa8080e7          	jalr	-88(ra) # 80000b8a <push_off>
  if(holding(lk))
    80000bea:	8526                	mv	a0,s1
    80000bec:	00000097          	auipc	ra,0x0
    80000bf0:	f70080e7          	jalr	-144(ra) # 80000b5c <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000bf4:	4705                	li	a4,1
  if(holding(lk))
    80000bf6:	e115                	bnez	a0,80000c1a <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000bf8:	87ba                	mv	a5,a4
    80000bfa:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000bfe:	2781                	sext.w	a5,a5
    80000c00:	ffe5                	bnez	a5,80000bf8 <acquire+0x22>
  __sync_synchronize();
    80000c02:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c06:	00001097          	auipc	ra,0x1
    80000c0a:	d8a080e7          	jalr	-630(ra) # 80001990 <mycpu>
    80000c0e:	e888                	sd	a0,16(s1)
}
    80000c10:	60e2                	ld	ra,24(sp)
    80000c12:	6442                	ld	s0,16(sp)
    80000c14:	64a2                	ld	s1,8(sp)
    80000c16:	6105                	addi	sp,sp,32
    80000c18:	8082                	ret
    panic("acquire");
    80000c1a:	00007517          	auipc	a0,0x7
    80000c1e:	45650513          	addi	a0,a0,1110 # 80008070 <digits+0x30>
    80000c22:	00000097          	auipc	ra,0x0
    80000c26:	91e080e7          	jalr	-1762(ra) # 80000540 <panic>

0000000080000c2a <pop_off>:

void
pop_off(void)
{
    80000c2a:	1141                	addi	sp,sp,-16
    80000c2c:	e406                	sd	ra,8(sp)
    80000c2e:	e022                	sd	s0,0(sp)
    80000c30:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c32:	00001097          	auipc	ra,0x1
    80000c36:	d5e080e7          	jalr	-674(ra) # 80001990 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c3a:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c3e:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c40:	e78d                	bnez	a5,80000c6a <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c42:	5d3c                	lw	a5,120(a0)
    80000c44:	02f05b63          	blez	a5,80000c7a <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000c48:	37fd                	addiw	a5,a5,-1
    80000c4a:	0007871b          	sext.w	a4,a5
    80000c4e:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c50:	eb09                	bnez	a4,80000c62 <pop_off+0x38>
    80000c52:	5d7c                	lw	a5,124(a0)
    80000c54:	c799                	beqz	a5,80000c62 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c56:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000c5a:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c5e:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000c62:	60a2                	ld	ra,8(sp)
    80000c64:	6402                	ld	s0,0(sp)
    80000c66:	0141                	addi	sp,sp,16
    80000c68:	8082                	ret
    panic("pop_off - interruptible");
    80000c6a:	00007517          	auipc	a0,0x7
    80000c6e:	40e50513          	addi	a0,a0,1038 # 80008078 <digits+0x38>
    80000c72:	00000097          	auipc	ra,0x0
    80000c76:	8ce080e7          	jalr	-1842(ra) # 80000540 <panic>
    panic("pop_off");
    80000c7a:	00007517          	auipc	a0,0x7
    80000c7e:	41650513          	addi	a0,a0,1046 # 80008090 <digits+0x50>
    80000c82:	00000097          	auipc	ra,0x0
    80000c86:	8be080e7          	jalr	-1858(ra) # 80000540 <panic>

0000000080000c8a <release>:
{
    80000c8a:	1101                	addi	sp,sp,-32
    80000c8c:	ec06                	sd	ra,24(sp)
    80000c8e:	e822                	sd	s0,16(sp)
    80000c90:	e426                	sd	s1,8(sp)
    80000c92:	1000                	addi	s0,sp,32
    80000c94:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000c96:	00000097          	auipc	ra,0x0
    80000c9a:	ec6080e7          	jalr	-314(ra) # 80000b5c <holding>
    80000c9e:	c115                	beqz	a0,80000cc2 <release+0x38>
  lk->cpu = 0;
    80000ca0:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000ca4:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000ca8:	0f50000f          	fence	iorw,ow
    80000cac:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000cb0:	00000097          	auipc	ra,0x0
    80000cb4:	f7a080e7          	jalr	-134(ra) # 80000c2a <pop_off>
}
    80000cb8:	60e2                	ld	ra,24(sp)
    80000cba:	6442                	ld	s0,16(sp)
    80000cbc:	64a2                	ld	s1,8(sp)
    80000cbe:	6105                	addi	sp,sp,32
    80000cc0:	8082                	ret
    panic("release");
    80000cc2:	00007517          	auipc	a0,0x7
    80000cc6:	3d650513          	addi	a0,a0,982 # 80008098 <digits+0x58>
    80000cca:	00000097          	auipc	ra,0x0
    80000cce:	876080e7          	jalr	-1930(ra) # 80000540 <panic>

0000000080000cd2 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000cd2:	1141                	addi	sp,sp,-16
    80000cd4:	e422                	sd	s0,8(sp)
    80000cd6:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000cd8:	ca19                	beqz	a2,80000cee <memset+0x1c>
    80000cda:	87aa                	mv	a5,a0
    80000cdc:	1602                	slli	a2,a2,0x20
    80000cde:	9201                	srli	a2,a2,0x20
    80000ce0:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    80000ce4:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000ce8:	0785                	addi	a5,a5,1
    80000cea:	fee79de3          	bne	a5,a4,80000ce4 <memset+0x12>
  }
  return dst;
}
    80000cee:	6422                	ld	s0,8(sp)
    80000cf0:	0141                	addi	sp,sp,16
    80000cf2:	8082                	ret

0000000080000cf4 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000cf4:	1141                	addi	sp,sp,-16
    80000cf6:	e422                	sd	s0,8(sp)
    80000cf8:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000cfa:	ca05                	beqz	a2,80000d2a <memcmp+0x36>
    80000cfc:	fff6069b          	addiw	a3,a2,-1 # fff <_entry-0x7ffff001>
    80000d00:	1682                	slli	a3,a3,0x20
    80000d02:	9281                	srli	a3,a3,0x20
    80000d04:	0685                	addi	a3,a3,1
    80000d06:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d08:	00054783          	lbu	a5,0(a0)
    80000d0c:	0005c703          	lbu	a4,0(a1)
    80000d10:	00e79863          	bne	a5,a4,80000d20 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d14:	0505                	addi	a0,a0,1
    80000d16:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d18:	fed518e3          	bne	a0,a3,80000d08 <memcmp+0x14>
  }

  return 0;
    80000d1c:	4501                	li	a0,0
    80000d1e:	a019                	j	80000d24 <memcmp+0x30>
      return *s1 - *s2;
    80000d20:	40e7853b          	subw	a0,a5,a4
}
    80000d24:	6422                	ld	s0,8(sp)
    80000d26:	0141                	addi	sp,sp,16
    80000d28:	8082                	ret
  return 0;
    80000d2a:	4501                	li	a0,0
    80000d2c:	bfe5                	j	80000d24 <memcmp+0x30>

0000000080000d2e <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d2e:	1141                	addi	sp,sp,-16
    80000d30:	e422                	sd	s0,8(sp)
    80000d32:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000d34:	c205                	beqz	a2,80000d54 <memmove+0x26>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d36:	02a5e263          	bltu	a1,a0,80000d5a <memmove+0x2c>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d3a:	1602                	slli	a2,a2,0x20
    80000d3c:	9201                	srli	a2,a2,0x20
    80000d3e:	00c587b3          	add	a5,a1,a2
{
    80000d42:	872a                	mv	a4,a0
      *d++ = *s++;
    80000d44:	0585                	addi	a1,a1,1
    80000d46:	0705                	addi	a4,a4,1 # fffffffffffff001 <end+0xffffffff7ffdbfd1>
    80000d48:	fff5c683          	lbu	a3,-1(a1)
    80000d4c:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000d50:	fef59ae3          	bne	a1,a5,80000d44 <memmove+0x16>

  return dst;
}
    80000d54:	6422                	ld	s0,8(sp)
    80000d56:	0141                	addi	sp,sp,16
    80000d58:	8082                	ret
  if(s < d && s + n > d){
    80000d5a:	02061693          	slli	a3,a2,0x20
    80000d5e:	9281                	srli	a3,a3,0x20
    80000d60:	00d58733          	add	a4,a1,a3
    80000d64:	fce57be3          	bgeu	a0,a4,80000d3a <memmove+0xc>
    d += n;
    80000d68:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000d6a:	fff6079b          	addiw	a5,a2,-1
    80000d6e:	1782                	slli	a5,a5,0x20
    80000d70:	9381                	srli	a5,a5,0x20
    80000d72:	fff7c793          	not	a5,a5
    80000d76:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000d78:	177d                	addi	a4,a4,-1
    80000d7a:	16fd                	addi	a3,a3,-1
    80000d7c:	00074603          	lbu	a2,0(a4)
    80000d80:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000d84:	fee79ae3          	bne	a5,a4,80000d78 <memmove+0x4a>
    80000d88:	b7f1                	j	80000d54 <memmove+0x26>

0000000080000d8a <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000d8a:	1141                	addi	sp,sp,-16
    80000d8c:	e406                	sd	ra,8(sp)
    80000d8e:	e022                	sd	s0,0(sp)
    80000d90:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000d92:	00000097          	auipc	ra,0x0
    80000d96:	f9c080e7          	jalr	-100(ra) # 80000d2e <memmove>
}
    80000d9a:	60a2                	ld	ra,8(sp)
    80000d9c:	6402                	ld	s0,0(sp)
    80000d9e:	0141                	addi	sp,sp,16
    80000da0:	8082                	ret

0000000080000da2 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000da2:	1141                	addi	sp,sp,-16
    80000da4:	e422                	sd	s0,8(sp)
    80000da6:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000da8:	ce11                	beqz	a2,80000dc4 <strncmp+0x22>
    80000daa:	00054783          	lbu	a5,0(a0)
    80000dae:	cf89                	beqz	a5,80000dc8 <strncmp+0x26>
    80000db0:	0005c703          	lbu	a4,0(a1)
    80000db4:	00f71a63          	bne	a4,a5,80000dc8 <strncmp+0x26>
    n--, p++, q++;
    80000db8:	367d                	addiw	a2,a2,-1
    80000dba:	0505                	addi	a0,a0,1
    80000dbc:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000dbe:	f675                	bnez	a2,80000daa <strncmp+0x8>
  if(n == 0)
    return 0;
    80000dc0:	4501                	li	a0,0
    80000dc2:	a809                	j	80000dd4 <strncmp+0x32>
    80000dc4:	4501                	li	a0,0
    80000dc6:	a039                	j	80000dd4 <strncmp+0x32>
  if(n == 0)
    80000dc8:	ca09                	beqz	a2,80000dda <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000dca:	00054503          	lbu	a0,0(a0)
    80000dce:	0005c783          	lbu	a5,0(a1)
    80000dd2:	9d1d                	subw	a0,a0,a5
}
    80000dd4:	6422                	ld	s0,8(sp)
    80000dd6:	0141                	addi	sp,sp,16
    80000dd8:	8082                	ret
    return 0;
    80000dda:	4501                	li	a0,0
    80000ddc:	bfe5                	j	80000dd4 <strncmp+0x32>

0000000080000dde <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000dde:	1141                	addi	sp,sp,-16
    80000de0:	e422                	sd	s0,8(sp)
    80000de2:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000de4:	872a                	mv	a4,a0
    80000de6:	8832                	mv	a6,a2
    80000de8:	367d                	addiw	a2,a2,-1
    80000dea:	01005963          	blez	a6,80000dfc <strncpy+0x1e>
    80000dee:	0705                	addi	a4,a4,1
    80000df0:	0005c783          	lbu	a5,0(a1)
    80000df4:	fef70fa3          	sb	a5,-1(a4)
    80000df8:	0585                	addi	a1,a1,1
    80000dfa:	f7f5                	bnez	a5,80000de6 <strncpy+0x8>
    ;
  while(n-- > 0)
    80000dfc:	86ba                	mv	a3,a4
    80000dfe:	00c05c63          	blez	a2,80000e16 <strncpy+0x38>
    *s++ = 0;
    80000e02:	0685                	addi	a3,a3,1
    80000e04:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000e08:	40d707bb          	subw	a5,a4,a3
    80000e0c:	37fd                	addiw	a5,a5,-1
    80000e0e:	010787bb          	addw	a5,a5,a6
    80000e12:	fef048e3          	bgtz	a5,80000e02 <strncpy+0x24>
  return os;
}
    80000e16:	6422                	ld	s0,8(sp)
    80000e18:	0141                	addi	sp,sp,16
    80000e1a:	8082                	ret

0000000080000e1c <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e1c:	1141                	addi	sp,sp,-16
    80000e1e:	e422                	sd	s0,8(sp)
    80000e20:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e22:	02c05363          	blez	a2,80000e48 <safestrcpy+0x2c>
    80000e26:	fff6069b          	addiw	a3,a2,-1
    80000e2a:	1682                	slli	a3,a3,0x20
    80000e2c:	9281                	srli	a3,a3,0x20
    80000e2e:	96ae                	add	a3,a3,a1
    80000e30:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e32:	00d58963          	beq	a1,a3,80000e44 <safestrcpy+0x28>
    80000e36:	0585                	addi	a1,a1,1
    80000e38:	0785                	addi	a5,a5,1
    80000e3a:	fff5c703          	lbu	a4,-1(a1)
    80000e3e:	fee78fa3          	sb	a4,-1(a5)
    80000e42:	fb65                	bnez	a4,80000e32 <safestrcpy+0x16>
    ;
  *s = 0;
    80000e44:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e48:	6422                	ld	s0,8(sp)
    80000e4a:	0141                	addi	sp,sp,16
    80000e4c:	8082                	ret

0000000080000e4e <strlen>:

int
strlen(const char *s)
{
    80000e4e:	1141                	addi	sp,sp,-16
    80000e50:	e422                	sd	s0,8(sp)
    80000e52:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000e54:	00054783          	lbu	a5,0(a0)
    80000e58:	cf91                	beqz	a5,80000e74 <strlen+0x26>
    80000e5a:	0505                	addi	a0,a0,1
    80000e5c:	87aa                	mv	a5,a0
    80000e5e:	4685                	li	a3,1
    80000e60:	9e89                	subw	a3,a3,a0
    80000e62:	00f6853b          	addw	a0,a3,a5
    80000e66:	0785                	addi	a5,a5,1
    80000e68:	fff7c703          	lbu	a4,-1(a5)
    80000e6c:	fb7d                	bnez	a4,80000e62 <strlen+0x14>
    ;
  return n;
}
    80000e6e:	6422                	ld	s0,8(sp)
    80000e70:	0141                	addi	sp,sp,16
    80000e72:	8082                	ret
  for(n = 0; s[n]; n++)
    80000e74:	4501                	li	a0,0
    80000e76:	bfe5                	j	80000e6e <strlen+0x20>

0000000080000e78 <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000e78:	1141                	addi	sp,sp,-16
    80000e7a:	e406                	sd	ra,8(sp)
    80000e7c:	e022                	sd	s0,0(sp)
    80000e7e:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000e80:	00001097          	auipc	ra,0x1
    80000e84:	b00080e7          	jalr	-1280(ra) # 80001980 <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000e88:	00008717          	auipc	a4,0x8
    80000e8c:	d1070713          	addi	a4,a4,-752 # 80008b98 <started>
  if(cpuid() == 0){
    80000e90:	c139                	beqz	a0,80000ed6 <main+0x5e>
    while(started == 0)
    80000e92:	431c                	lw	a5,0(a4)
    80000e94:	2781                	sext.w	a5,a5
    80000e96:	dff5                	beqz	a5,80000e92 <main+0x1a>
      ;
    __sync_synchronize();
    80000e98:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000e9c:	00001097          	auipc	ra,0x1
    80000ea0:	ae4080e7          	jalr	-1308(ra) # 80001980 <cpuid>
    80000ea4:	85aa                	mv	a1,a0
    80000ea6:	00007517          	auipc	a0,0x7
    80000eaa:	21250513          	addi	a0,a0,530 # 800080b8 <digits+0x78>
    80000eae:	fffff097          	auipc	ra,0xfffff
    80000eb2:	6dc080e7          	jalr	1756(ra) # 8000058a <printf>
    kvminithart();    // turn on paging
    80000eb6:	00000097          	auipc	ra,0x0
    80000eba:	0d8080e7          	jalr	216(ra) # 80000f8e <kvminithart>
    trapinithart();   // install kernel trap vector
    80000ebe:	00002097          	auipc	ra,0x2
    80000ec2:	b38080e7          	jalr	-1224(ra) # 800029f6 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000ec6:	00005097          	auipc	ra,0x5
    80000eca:	37a080e7          	jalr	890(ra) # 80006240 <plicinithart>
  }

  scheduler();        
    80000ece:	00001097          	auipc	ra,0x1
    80000ed2:	0c2080e7          	jalr	194(ra) # 80001f90 <scheduler>
    consoleinit();
    80000ed6:	fffff097          	auipc	ra,0xfffff
    80000eda:	57a080e7          	jalr	1402(ra) # 80000450 <consoleinit>
    printfinit();
    80000ede:	00000097          	auipc	ra,0x0
    80000ee2:	88c080e7          	jalr	-1908(ra) # 8000076a <printfinit>
    printf("\n");
    80000ee6:	00007517          	auipc	a0,0x7
    80000eea:	1e250513          	addi	a0,a0,482 # 800080c8 <digits+0x88>
    80000eee:	fffff097          	auipc	ra,0xfffff
    80000ef2:	69c080e7          	jalr	1692(ra) # 8000058a <printf>
    printf("xv6 kernel is booting\n");
    80000ef6:	00007517          	auipc	a0,0x7
    80000efa:	1aa50513          	addi	a0,a0,426 # 800080a0 <digits+0x60>
    80000efe:	fffff097          	auipc	ra,0xfffff
    80000f02:	68c080e7          	jalr	1676(ra) # 8000058a <printf>
    printf("\n");
    80000f06:	00007517          	auipc	a0,0x7
    80000f0a:	1c250513          	addi	a0,a0,450 # 800080c8 <digits+0x88>
    80000f0e:	fffff097          	auipc	ra,0xfffff
    80000f12:	67c080e7          	jalr	1660(ra) # 8000058a <printf>
    kinit();         // physical page allocator
    80000f16:	00000097          	auipc	ra,0x0
    80000f1a:	b94080e7          	jalr	-1132(ra) # 80000aaa <kinit>
    kvminit();       // create kernel page table
    80000f1e:	00000097          	auipc	ra,0x0
    80000f22:	326080e7          	jalr	806(ra) # 80001244 <kvminit>
    kvminithart();   // turn on paging
    80000f26:	00000097          	auipc	ra,0x0
    80000f2a:	068080e7          	jalr	104(ra) # 80000f8e <kvminithart>
    procinit();      // process table
    80000f2e:	00001097          	auipc	ra,0x1
    80000f32:	99e080e7          	jalr	-1634(ra) # 800018cc <procinit>
    trapinit();      // trap vectors
    80000f36:	00002097          	auipc	ra,0x2
    80000f3a:	a98080e7          	jalr	-1384(ra) # 800029ce <trapinit>
    trapinithart();  // install kernel trap vector
    80000f3e:	00002097          	auipc	ra,0x2
    80000f42:	ab8080e7          	jalr	-1352(ra) # 800029f6 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f46:	00005097          	auipc	ra,0x5
    80000f4a:	2e4080e7          	jalr	740(ra) # 8000622a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f4e:	00005097          	auipc	ra,0x5
    80000f52:	2f2080e7          	jalr	754(ra) # 80006240 <plicinithart>
    binit();         // buffer cache
    80000f56:	00002097          	auipc	ra,0x2
    80000f5a:	492080e7          	jalr	1170(ra) # 800033e8 <binit>
    iinit();         // inode table
    80000f5e:	00003097          	auipc	ra,0x3
    80000f62:	b32080e7          	jalr	-1230(ra) # 80003a90 <iinit>
    fileinit();      // file table
    80000f66:	00004097          	auipc	ra,0x4
    80000f6a:	ad8080e7          	jalr	-1320(ra) # 80004a3e <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f6e:	00005097          	auipc	ra,0x5
    80000f72:	3da080e7          	jalr	986(ra) # 80006348 <virtio_disk_init>
    userinit();      // first user process
    80000f76:	00001097          	auipc	ra,0x1
    80000f7a:	d46080e7          	jalr	-698(ra) # 80001cbc <userinit>
    __sync_synchronize();
    80000f7e:	0ff0000f          	fence
    started = 1;
    80000f82:	4785                	li	a5,1
    80000f84:	00008717          	auipc	a4,0x8
    80000f88:	c0f72a23          	sw	a5,-1004(a4) # 80008b98 <started>
    80000f8c:	b789                	j	80000ece <main+0x56>

0000000080000f8e <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000f8e:	1141                	addi	sp,sp,-16
    80000f90:	e422                	sd	s0,8(sp)
    80000f92:	0800                	addi	s0,sp,16
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000f94:	12000073          	sfence.vma
  // wait for any previous writes to the page table memory to finish.
  sfence_vma();

  w_satp(MAKE_SATP(kernel_pagetable));
    80000f98:	00008797          	auipc	a5,0x8
    80000f9c:	c087b783          	ld	a5,-1016(a5) # 80008ba0 <kernel_pagetable>
    80000fa0:	83b1                	srli	a5,a5,0xc
    80000fa2:	577d                	li	a4,-1
    80000fa4:	177e                	slli	a4,a4,0x3f
    80000fa6:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000fa8:	18079073          	csrw	satp,a5
  asm volatile("sfence.vma zero, zero");
    80000fac:	12000073          	sfence.vma

  // flush stale entries from the TLB.
  sfence_vma();
}
    80000fb0:	6422                	ld	s0,8(sp)
    80000fb2:	0141                	addi	sp,sp,16
    80000fb4:	8082                	ret

0000000080000fb6 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000fb6:	7139                	addi	sp,sp,-64
    80000fb8:	fc06                	sd	ra,56(sp)
    80000fba:	f822                	sd	s0,48(sp)
    80000fbc:	f426                	sd	s1,40(sp)
    80000fbe:	f04a                	sd	s2,32(sp)
    80000fc0:	ec4e                	sd	s3,24(sp)
    80000fc2:	e852                	sd	s4,16(sp)
    80000fc4:	e456                	sd	s5,8(sp)
    80000fc6:	e05a                	sd	s6,0(sp)
    80000fc8:	0080                	addi	s0,sp,64
    80000fca:	84aa                	mv	s1,a0
    80000fcc:	89ae                	mv	s3,a1
    80000fce:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80000fd0:	57fd                	li	a5,-1
    80000fd2:	83e9                	srli	a5,a5,0x1a
    80000fd4:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80000fd6:	4b31                	li	s6,12
  if(va >= MAXVA)
    80000fd8:	04b7f263          	bgeu	a5,a1,8000101c <walk+0x66>
    panic("walk");
    80000fdc:	00007517          	auipc	a0,0x7
    80000fe0:	0f450513          	addi	a0,a0,244 # 800080d0 <digits+0x90>
    80000fe4:	fffff097          	auipc	ra,0xfffff
    80000fe8:	55c080e7          	jalr	1372(ra) # 80000540 <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80000fec:	060a8663          	beqz	s5,80001058 <walk+0xa2>
    80000ff0:	00000097          	auipc	ra,0x0
    80000ff4:	af6080e7          	jalr	-1290(ra) # 80000ae6 <kalloc>
    80000ff8:	84aa                	mv	s1,a0
    80000ffa:	c529                	beqz	a0,80001044 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80000ffc:	6605                	lui	a2,0x1
    80000ffe:	4581                	li	a1,0
    80001000:	00000097          	auipc	ra,0x0
    80001004:	cd2080e7          	jalr	-814(ra) # 80000cd2 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80001008:	00c4d793          	srli	a5,s1,0xc
    8000100c:	07aa                	slli	a5,a5,0xa
    8000100e:	0017e793          	ori	a5,a5,1
    80001012:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001016:	3a5d                	addiw	s4,s4,-9 # ffffffffffffeff7 <end+0xffffffff7ffdbfc7>
    80001018:	036a0063          	beq	s4,s6,80001038 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    8000101c:	0149d933          	srl	s2,s3,s4
    80001020:	1ff97913          	andi	s2,s2,511
    80001024:	090e                	slli	s2,s2,0x3
    80001026:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    80001028:	00093483          	ld	s1,0(s2)
    8000102c:	0014f793          	andi	a5,s1,1
    80001030:	dfd5                	beqz	a5,80000fec <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    80001032:	80a9                	srli	s1,s1,0xa
    80001034:	04b2                	slli	s1,s1,0xc
    80001036:	b7c5                	j	80001016 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    80001038:	00c9d513          	srli	a0,s3,0xc
    8000103c:	1ff57513          	andi	a0,a0,511
    80001040:	050e                	slli	a0,a0,0x3
    80001042:	9526                	add	a0,a0,s1
}
    80001044:	70e2                	ld	ra,56(sp)
    80001046:	7442                	ld	s0,48(sp)
    80001048:	74a2                	ld	s1,40(sp)
    8000104a:	7902                	ld	s2,32(sp)
    8000104c:	69e2                	ld	s3,24(sp)
    8000104e:	6a42                	ld	s4,16(sp)
    80001050:	6aa2                	ld	s5,8(sp)
    80001052:	6b02                	ld	s6,0(sp)
    80001054:	6121                	addi	sp,sp,64
    80001056:	8082                	ret
        return 0;
    80001058:	4501                	li	a0,0
    8000105a:	b7ed                	j	80001044 <walk+0x8e>

000000008000105c <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    8000105c:	57fd                	li	a5,-1
    8000105e:	83e9                	srli	a5,a5,0x1a
    80001060:	00b7f463          	bgeu	a5,a1,80001068 <walkaddr+0xc>
    return 0;
    80001064:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    80001066:	8082                	ret
{
    80001068:	1141                	addi	sp,sp,-16
    8000106a:	e406                	sd	ra,8(sp)
    8000106c:	e022                	sd	s0,0(sp)
    8000106e:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    80001070:	4601                	li	a2,0
    80001072:	00000097          	auipc	ra,0x0
    80001076:	f44080e7          	jalr	-188(ra) # 80000fb6 <walk>
  if(pte == 0)
    8000107a:	c105                	beqz	a0,8000109a <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    8000107c:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    8000107e:	0117f693          	andi	a3,a5,17
    80001082:	4745                	li	a4,17
    return 0;
    80001084:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    80001086:	00e68663          	beq	a3,a4,80001092 <walkaddr+0x36>
}
    8000108a:	60a2                	ld	ra,8(sp)
    8000108c:	6402                	ld	s0,0(sp)
    8000108e:	0141                	addi	sp,sp,16
    80001090:	8082                	ret
  pa = PTE2PA(*pte);
    80001092:	83a9                	srli	a5,a5,0xa
    80001094:	00c79513          	slli	a0,a5,0xc
  return pa;
    80001098:	bfcd                	j	8000108a <walkaddr+0x2e>
    return 0;
    8000109a:	4501                	li	a0,0
    8000109c:	b7fd                	j	8000108a <walkaddr+0x2e>

000000008000109e <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    8000109e:	715d                	addi	sp,sp,-80
    800010a0:	e486                	sd	ra,72(sp)
    800010a2:	e0a2                	sd	s0,64(sp)
    800010a4:	fc26                	sd	s1,56(sp)
    800010a6:	f84a                	sd	s2,48(sp)
    800010a8:	f44e                	sd	s3,40(sp)
    800010aa:	f052                	sd	s4,32(sp)
    800010ac:	ec56                	sd	s5,24(sp)
    800010ae:	e85a                	sd	s6,16(sp)
    800010b0:	e45e                	sd	s7,8(sp)
    800010b2:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    800010b4:	c639                	beqz	a2,80001102 <mappages+0x64>
    800010b6:	8aaa                	mv	s5,a0
    800010b8:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    800010ba:	777d                	lui	a4,0xfffff
    800010bc:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    800010c0:	fff58993          	addi	s3,a1,-1
    800010c4:	99b2                	add	s3,s3,a2
    800010c6:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    800010ca:	893e                	mv	s2,a5
    800010cc:	40f68a33          	sub	s4,a3,a5
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800010d0:	6b85                	lui	s7,0x1
    800010d2:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    800010d6:	4605                	li	a2,1
    800010d8:	85ca                	mv	a1,s2
    800010da:	8556                	mv	a0,s5
    800010dc:	00000097          	auipc	ra,0x0
    800010e0:	eda080e7          	jalr	-294(ra) # 80000fb6 <walk>
    800010e4:	cd1d                	beqz	a0,80001122 <mappages+0x84>
    if(*pte & PTE_V)
    800010e6:	611c                	ld	a5,0(a0)
    800010e8:	8b85                	andi	a5,a5,1
    800010ea:	e785                	bnez	a5,80001112 <mappages+0x74>
    *pte = PA2PTE(pa) | perm | PTE_V;
    800010ec:	80b1                	srli	s1,s1,0xc
    800010ee:	04aa                	slli	s1,s1,0xa
    800010f0:	0164e4b3          	or	s1,s1,s6
    800010f4:	0014e493          	ori	s1,s1,1
    800010f8:	e104                	sd	s1,0(a0)
    if(a == last)
    800010fa:	05390063          	beq	s2,s3,8000113a <mappages+0x9c>
    a += PGSIZE;
    800010fe:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    80001100:	bfc9                	j	800010d2 <mappages+0x34>
    panic("mappages: size");
    80001102:	00007517          	auipc	a0,0x7
    80001106:	fd650513          	addi	a0,a0,-42 # 800080d8 <digits+0x98>
    8000110a:	fffff097          	auipc	ra,0xfffff
    8000110e:	436080e7          	jalr	1078(ra) # 80000540 <panic>
      panic("mappages: remap");
    80001112:	00007517          	auipc	a0,0x7
    80001116:	fd650513          	addi	a0,a0,-42 # 800080e8 <digits+0xa8>
    8000111a:	fffff097          	auipc	ra,0xfffff
    8000111e:	426080e7          	jalr	1062(ra) # 80000540 <panic>
      return -1;
    80001122:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    80001124:	60a6                	ld	ra,72(sp)
    80001126:	6406                	ld	s0,64(sp)
    80001128:	74e2                	ld	s1,56(sp)
    8000112a:	7942                	ld	s2,48(sp)
    8000112c:	79a2                	ld	s3,40(sp)
    8000112e:	7a02                	ld	s4,32(sp)
    80001130:	6ae2                	ld	s5,24(sp)
    80001132:	6b42                	ld	s6,16(sp)
    80001134:	6ba2                	ld	s7,8(sp)
    80001136:	6161                	addi	sp,sp,80
    80001138:	8082                	ret
  return 0;
    8000113a:	4501                	li	a0,0
    8000113c:	b7e5                	j	80001124 <mappages+0x86>

000000008000113e <kvmmap>:
{
    8000113e:	1141                	addi	sp,sp,-16
    80001140:	e406                	sd	ra,8(sp)
    80001142:	e022                	sd	s0,0(sp)
    80001144:	0800                	addi	s0,sp,16
    80001146:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    80001148:	86b2                	mv	a3,a2
    8000114a:	863e                	mv	a2,a5
    8000114c:	00000097          	auipc	ra,0x0
    80001150:	f52080e7          	jalr	-174(ra) # 8000109e <mappages>
    80001154:	e509                	bnez	a0,8000115e <kvmmap+0x20>
}
    80001156:	60a2                	ld	ra,8(sp)
    80001158:	6402                	ld	s0,0(sp)
    8000115a:	0141                	addi	sp,sp,16
    8000115c:	8082                	ret
    panic("kvmmap");
    8000115e:	00007517          	auipc	a0,0x7
    80001162:	f9a50513          	addi	a0,a0,-102 # 800080f8 <digits+0xb8>
    80001166:	fffff097          	auipc	ra,0xfffff
    8000116a:	3da080e7          	jalr	986(ra) # 80000540 <panic>

000000008000116e <kvmmake>:
{
    8000116e:	1101                	addi	sp,sp,-32
    80001170:	ec06                	sd	ra,24(sp)
    80001172:	e822                	sd	s0,16(sp)
    80001174:	e426                	sd	s1,8(sp)
    80001176:	e04a                	sd	s2,0(sp)
    80001178:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    8000117a:	00000097          	auipc	ra,0x0
    8000117e:	96c080e7          	jalr	-1684(ra) # 80000ae6 <kalloc>
    80001182:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    80001184:	6605                	lui	a2,0x1
    80001186:	4581                	li	a1,0
    80001188:	00000097          	auipc	ra,0x0
    8000118c:	b4a080e7          	jalr	-1206(ra) # 80000cd2 <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    80001190:	4719                	li	a4,6
    80001192:	6685                	lui	a3,0x1
    80001194:	10000637          	lui	a2,0x10000
    80001198:	100005b7          	lui	a1,0x10000
    8000119c:	8526                	mv	a0,s1
    8000119e:	00000097          	auipc	ra,0x0
    800011a2:	fa0080e7          	jalr	-96(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    800011a6:	4719                	li	a4,6
    800011a8:	6685                	lui	a3,0x1
    800011aa:	10001637          	lui	a2,0x10001
    800011ae:	100015b7          	lui	a1,0x10001
    800011b2:	8526                	mv	a0,s1
    800011b4:	00000097          	auipc	ra,0x0
    800011b8:	f8a080e7          	jalr	-118(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800011bc:	4719                	li	a4,6
    800011be:	004006b7          	lui	a3,0x400
    800011c2:	0c000637          	lui	a2,0xc000
    800011c6:	0c0005b7          	lui	a1,0xc000
    800011ca:	8526                	mv	a0,s1
    800011cc:	00000097          	auipc	ra,0x0
    800011d0:	f72080e7          	jalr	-142(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800011d4:	00007917          	auipc	s2,0x7
    800011d8:	e2c90913          	addi	s2,s2,-468 # 80008000 <etext>
    800011dc:	4729                	li	a4,10
    800011de:	80007697          	auipc	a3,0x80007
    800011e2:	e2268693          	addi	a3,a3,-478 # 8000 <_entry-0x7fff8000>
    800011e6:	4605                	li	a2,1
    800011e8:	067e                	slli	a2,a2,0x1f
    800011ea:	85b2                	mv	a1,a2
    800011ec:	8526                	mv	a0,s1
    800011ee:	00000097          	auipc	ra,0x0
    800011f2:	f50080e7          	jalr	-176(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    800011f6:	4719                	li	a4,6
    800011f8:	46c5                	li	a3,17
    800011fa:	06ee                	slli	a3,a3,0x1b
    800011fc:	412686b3          	sub	a3,a3,s2
    80001200:	864a                	mv	a2,s2
    80001202:	85ca                	mv	a1,s2
    80001204:	8526                	mv	a0,s1
    80001206:	00000097          	auipc	ra,0x0
    8000120a:	f38080e7          	jalr	-200(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    8000120e:	4729                	li	a4,10
    80001210:	6685                	lui	a3,0x1
    80001212:	00006617          	auipc	a2,0x6
    80001216:	dee60613          	addi	a2,a2,-530 # 80007000 <_trampoline>
    8000121a:	040005b7          	lui	a1,0x4000
    8000121e:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001220:	05b2                	slli	a1,a1,0xc
    80001222:	8526                	mv	a0,s1
    80001224:	00000097          	auipc	ra,0x0
    80001228:	f1a080e7          	jalr	-230(ra) # 8000113e <kvmmap>
  proc_mapstacks(kpgtbl);
    8000122c:	8526                	mv	a0,s1
    8000122e:	00000097          	auipc	ra,0x0
    80001232:	608080e7          	jalr	1544(ra) # 80001836 <proc_mapstacks>
}
    80001236:	8526                	mv	a0,s1
    80001238:	60e2                	ld	ra,24(sp)
    8000123a:	6442                	ld	s0,16(sp)
    8000123c:	64a2                	ld	s1,8(sp)
    8000123e:	6902                	ld	s2,0(sp)
    80001240:	6105                	addi	sp,sp,32
    80001242:	8082                	ret

0000000080001244 <kvminit>:
{
    80001244:	1141                	addi	sp,sp,-16
    80001246:	e406                	sd	ra,8(sp)
    80001248:	e022                	sd	s0,0(sp)
    8000124a:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    8000124c:	00000097          	auipc	ra,0x0
    80001250:	f22080e7          	jalr	-222(ra) # 8000116e <kvmmake>
    80001254:	00008797          	auipc	a5,0x8
    80001258:	94a7b623          	sd	a0,-1716(a5) # 80008ba0 <kernel_pagetable>
}
    8000125c:	60a2                	ld	ra,8(sp)
    8000125e:	6402                	ld	s0,0(sp)
    80001260:	0141                	addi	sp,sp,16
    80001262:	8082                	ret

0000000080001264 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    80001264:	715d                	addi	sp,sp,-80
    80001266:	e486                	sd	ra,72(sp)
    80001268:	e0a2                	sd	s0,64(sp)
    8000126a:	fc26                	sd	s1,56(sp)
    8000126c:	f84a                	sd	s2,48(sp)
    8000126e:	f44e                	sd	s3,40(sp)
    80001270:	f052                	sd	s4,32(sp)
    80001272:	ec56                	sd	s5,24(sp)
    80001274:	e85a                	sd	s6,16(sp)
    80001276:	e45e                	sd	s7,8(sp)
    80001278:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    8000127a:	03459793          	slli	a5,a1,0x34
    8000127e:	e795                	bnez	a5,800012aa <uvmunmap+0x46>
    80001280:	8a2a                	mv	s4,a0
    80001282:	892e                	mv	s2,a1
    80001284:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001286:	0632                	slli	a2,a2,0xc
    80001288:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    8000128c:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000128e:	6b05                	lui	s6,0x1
    80001290:	0735e263          	bltu	a1,s3,800012f4 <uvmunmap+0x90>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    80001294:	60a6                	ld	ra,72(sp)
    80001296:	6406                	ld	s0,64(sp)
    80001298:	74e2                	ld	s1,56(sp)
    8000129a:	7942                	ld	s2,48(sp)
    8000129c:	79a2                	ld	s3,40(sp)
    8000129e:	7a02                	ld	s4,32(sp)
    800012a0:	6ae2                	ld	s5,24(sp)
    800012a2:	6b42                	ld	s6,16(sp)
    800012a4:	6ba2                	ld	s7,8(sp)
    800012a6:	6161                	addi	sp,sp,80
    800012a8:	8082                	ret
    panic("uvmunmap: not aligned");
    800012aa:	00007517          	auipc	a0,0x7
    800012ae:	e5650513          	addi	a0,a0,-426 # 80008100 <digits+0xc0>
    800012b2:	fffff097          	auipc	ra,0xfffff
    800012b6:	28e080e7          	jalr	654(ra) # 80000540 <panic>
      panic("uvmunmap: walk");
    800012ba:	00007517          	auipc	a0,0x7
    800012be:	e5e50513          	addi	a0,a0,-418 # 80008118 <digits+0xd8>
    800012c2:	fffff097          	auipc	ra,0xfffff
    800012c6:	27e080e7          	jalr	638(ra) # 80000540 <panic>
      panic("uvmunmap: not mapped");
    800012ca:	00007517          	auipc	a0,0x7
    800012ce:	e5e50513          	addi	a0,a0,-418 # 80008128 <digits+0xe8>
    800012d2:	fffff097          	auipc	ra,0xfffff
    800012d6:	26e080e7          	jalr	622(ra) # 80000540 <panic>
      panic("uvmunmap: not a leaf");
    800012da:	00007517          	auipc	a0,0x7
    800012de:	e6650513          	addi	a0,a0,-410 # 80008140 <digits+0x100>
    800012e2:	fffff097          	auipc	ra,0xfffff
    800012e6:	25e080e7          	jalr	606(ra) # 80000540 <panic>
    *pte = 0;
    800012ea:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012ee:	995a                	add	s2,s2,s6
    800012f0:	fb3972e3          	bgeu	s2,s3,80001294 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    800012f4:	4601                	li	a2,0
    800012f6:	85ca                	mv	a1,s2
    800012f8:	8552                	mv	a0,s4
    800012fa:	00000097          	auipc	ra,0x0
    800012fe:	cbc080e7          	jalr	-836(ra) # 80000fb6 <walk>
    80001302:	84aa                	mv	s1,a0
    80001304:	d95d                	beqz	a0,800012ba <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    80001306:	6108                	ld	a0,0(a0)
    80001308:	00157793          	andi	a5,a0,1
    8000130c:	dfdd                	beqz	a5,800012ca <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    8000130e:	3ff57793          	andi	a5,a0,1023
    80001312:	fd7784e3          	beq	a5,s7,800012da <uvmunmap+0x76>
    if(do_free){
    80001316:	fc0a8ae3          	beqz	s5,800012ea <uvmunmap+0x86>
      uint64 pa = PTE2PA(*pte);
    8000131a:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    8000131c:	0532                	slli	a0,a0,0xc
    8000131e:	fffff097          	auipc	ra,0xfffff
    80001322:	6ca080e7          	jalr	1738(ra) # 800009e8 <kfree>
    80001326:	b7d1                	j	800012ea <uvmunmap+0x86>

0000000080001328 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    80001328:	1101                	addi	sp,sp,-32
    8000132a:	ec06                	sd	ra,24(sp)
    8000132c:	e822                	sd	s0,16(sp)
    8000132e:	e426                	sd	s1,8(sp)
    80001330:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    80001332:	fffff097          	auipc	ra,0xfffff
    80001336:	7b4080e7          	jalr	1972(ra) # 80000ae6 <kalloc>
    8000133a:	84aa                	mv	s1,a0
  if(pagetable == 0)
    8000133c:	c519                	beqz	a0,8000134a <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    8000133e:	6605                	lui	a2,0x1
    80001340:	4581                	li	a1,0
    80001342:	00000097          	auipc	ra,0x0
    80001346:	990080e7          	jalr	-1648(ra) # 80000cd2 <memset>
  return pagetable;
}
    8000134a:	8526                	mv	a0,s1
    8000134c:	60e2                	ld	ra,24(sp)
    8000134e:	6442                	ld	s0,16(sp)
    80001350:	64a2                	ld	s1,8(sp)
    80001352:	6105                	addi	sp,sp,32
    80001354:	8082                	ret

0000000080001356 <uvmfirst>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvmfirst(pagetable_t pagetable, uchar *src, uint sz)
{
    80001356:	7179                	addi	sp,sp,-48
    80001358:	f406                	sd	ra,40(sp)
    8000135a:	f022                	sd	s0,32(sp)
    8000135c:	ec26                	sd	s1,24(sp)
    8000135e:	e84a                	sd	s2,16(sp)
    80001360:	e44e                	sd	s3,8(sp)
    80001362:	e052                	sd	s4,0(sp)
    80001364:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    80001366:	6785                	lui	a5,0x1
    80001368:	04f67863          	bgeu	a2,a5,800013b8 <uvmfirst+0x62>
    8000136c:	8a2a                	mv	s4,a0
    8000136e:	89ae                	mv	s3,a1
    80001370:	84b2                	mv	s1,a2
    panic("uvmfirst: more than a page");
  mem = kalloc();
    80001372:	fffff097          	auipc	ra,0xfffff
    80001376:	774080e7          	jalr	1908(ra) # 80000ae6 <kalloc>
    8000137a:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    8000137c:	6605                	lui	a2,0x1
    8000137e:	4581                	li	a1,0
    80001380:	00000097          	auipc	ra,0x0
    80001384:	952080e7          	jalr	-1710(ra) # 80000cd2 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    80001388:	4779                	li	a4,30
    8000138a:	86ca                	mv	a3,s2
    8000138c:	6605                	lui	a2,0x1
    8000138e:	4581                	li	a1,0
    80001390:	8552                	mv	a0,s4
    80001392:	00000097          	auipc	ra,0x0
    80001396:	d0c080e7          	jalr	-756(ra) # 8000109e <mappages>
  memmove(mem, src, sz);
    8000139a:	8626                	mv	a2,s1
    8000139c:	85ce                	mv	a1,s3
    8000139e:	854a                	mv	a0,s2
    800013a0:	00000097          	auipc	ra,0x0
    800013a4:	98e080e7          	jalr	-1650(ra) # 80000d2e <memmove>
}
    800013a8:	70a2                	ld	ra,40(sp)
    800013aa:	7402                	ld	s0,32(sp)
    800013ac:	64e2                	ld	s1,24(sp)
    800013ae:	6942                	ld	s2,16(sp)
    800013b0:	69a2                	ld	s3,8(sp)
    800013b2:	6a02                	ld	s4,0(sp)
    800013b4:	6145                	addi	sp,sp,48
    800013b6:	8082                	ret
    panic("uvmfirst: more than a page");
    800013b8:	00007517          	auipc	a0,0x7
    800013bc:	da050513          	addi	a0,a0,-608 # 80008158 <digits+0x118>
    800013c0:	fffff097          	auipc	ra,0xfffff
    800013c4:	180080e7          	jalr	384(ra) # 80000540 <panic>

00000000800013c8 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800013c8:	1101                	addi	sp,sp,-32
    800013ca:	ec06                	sd	ra,24(sp)
    800013cc:	e822                	sd	s0,16(sp)
    800013ce:	e426                	sd	s1,8(sp)
    800013d0:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    800013d2:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800013d4:	00b67d63          	bgeu	a2,a1,800013ee <uvmdealloc+0x26>
    800013d8:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800013da:	6785                	lui	a5,0x1
    800013dc:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    800013de:	00f60733          	add	a4,a2,a5
    800013e2:	76fd                	lui	a3,0xfffff
    800013e4:	8f75                	and	a4,a4,a3
    800013e6:	97ae                	add	a5,a5,a1
    800013e8:	8ff5                	and	a5,a5,a3
    800013ea:	00f76863          	bltu	a4,a5,800013fa <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    800013ee:	8526                	mv	a0,s1
    800013f0:	60e2                	ld	ra,24(sp)
    800013f2:	6442                	ld	s0,16(sp)
    800013f4:	64a2                	ld	s1,8(sp)
    800013f6:	6105                	addi	sp,sp,32
    800013f8:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    800013fa:	8f99                	sub	a5,a5,a4
    800013fc:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    800013fe:	4685                	li	a3,1
    80001400:	0007861b          	sext.w	a2,a5
    80001404:	85ba                	mv	a1,a4
    80001406:	00000097          	auipc	ra,0x0
    8000140a:	e5e080e7          	jalr	-418(ra) # 80001264 <uvmunmap>
    8000140e:	b7c5                	j	800013ee <uvmdealloc+0x26>

0000000080001410 <uvmalloc>:
  if(newsz < oldsz)
    80001410:	0ab66563          	bltu	a2,a1,800014ba <uvmalloc+0xaa>
{
    80001414:	7139                	addi	sp,sp,-64
    80001416:	fc06                	sd	ra,56(sp)
    80001418:	f822                	sd	s0,48(sp)
    8000141a:	f426                	sd	s1,40(sp)
    8000141c:	f04a                	sd	s2,32(sp)
    8000141e:	ec4e                	sd	s3,24(sp)
    80001420:	e852                	sd	s4,16(sp)
    80001422:	e456                	sd	s5,8(sp)
    80001424:	e05a                	sd	s6,0(sp)
    80001426:	0080                	addi	s0,sp,64
    80001428:	8aaa                	mv	s5,a0
    8000142a:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    8000142c:	6785                	lui	a5,0x1
    8000142e:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80001430:	95be                	add	a1,a1,a5
    80001432:	77fd                	lui	a5,0xfffff
    80001434:	00f5f9b3          	and	s3,a1,a5
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001438:	08c9f363          	bgeu	s3,a2,800014be <uvmalloc+0xae>
    8000143c:	894e                	mv	s2,s3
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    8000143e:	0126eb13          	ori	s6,a3,18
    mem = kalloc();
    80001442:	fffff097          	auipc	ra,0xfffff
    80001446:	6a4080e7          	jalr	1700(ra) # 80000ae6 <kalloc>
    8000144a:	84aa                	mv	s1,a0
    if(mem == 0){
    8000144c:	c51d                	beqz	a0,8000147a <uvmalloc+0x6a>
    memset(mem, 0, PGSIZE);
    8000144e:	6605                	lui	a2,0x1
    80001450:	4581                	li	a1,0
    80001452:	00000097          	auipc	ra,0x0
    80001456:	880080e7          	jalr	-1920(ra) # 80000cd2 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    8000145a:	875a                	mv	a4,s6
    8000145c:	86a6                	mv	a3,s1
    8000145e:	6605                	lui	a2,0x1
    80001460:	85ca                	mv	a1,s2
    80001462:	8556                	mv	a0,s5
    80001464:	00000097          	auipc	ra,0x0
    80001468:	c3a080e7          	jalr	-966(ra) # 8000109e <mappages>
    8000146c:	e90d                	bnez	a0,8000149e <uvmalloc+0x8e>
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000146e:	6785                	lui	a5,0x1
    80001470:	993e                	add	s2,s2,a5
    80001472:	fd4968e3          	bltu	s2,s4,80001442 <uvmalloc+0x32>
  return newsz;
    80001476:	8552                	mv	a0,s4
    80001478:	a809                	j	8000148a <uvmalloc+0x7a>
      uvmdealloc(pagetable, a, oldsz);
    8000147a:	864e                	mv	a2,s3
    8000147c:	85ca                	mv	a1,s2
    8000147e:	8556                	mv	a0,s5
    80001480:	00000097          	auipc	ra,0x0
    80001484:	f48080e7          	jalr	-184(ra) # 800013c8 <uvmdealloc>
      return 0;
    80001488:	4501                	li	a0,0
}
    8000148a:	70e2                	ld	ra,56(sp)
    8000148c:	7442                	ld	s0,48(sp)
    8000148e:	74a2                	ld	s1,40(sp)
    80001490:	7902                	ld	s2,32(sp)
    80001492:	69e2                	ld	s3,24(sp)
    80001494:	6a42                	ld	s4,16(sp)
    80001496:	6aa2                	ld	s5,8(sp)
    80001498:	6b02                	ld	s6,0(sp)
    8000149a:	6121                	addi	sp,sp,64
    8000149c:	8082                	ret
      kfree(mem);
    8000149e:	8526                	mv	a0,s1
    800014a0:	fffff097          	auipc	ra,0xfffff
    800014a4:	548080e7          	jalr	1352(ra) # 800009e8 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    800014a8:	864e                	mv	a2,s3
    800014aa:	85ca                	mv	a1,s2
    800014ac:	8556                	mv	a0,s5
    800014ae:	00000097          	auipc	ra,0x0
    800014b2:	f1a080e7          	jalr	-230(ra) # 800013c8 <uvmdealloc>
      return 0;
    800014b6:	4501                	li	a0,0
    800014b8:	bfc9                	j	8000148a <uvmalloc+0x7a>
    return oldsz;
    800014ba:	852e                	mv	a0,a1
}
    800014bc:	8082                	ret
  return newsz;
    800014be:	8532                	mv	a0,a2
    800014c0:	b7e9                	j	8000148a <uvmalloc+0x7a>

00000000800014c2 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800014c2:	7179                	addi	sp,sp,-48
    800014c4:	f406                	sd	ra,40(sp)
    800014c6:	f022                	sd	s0,32(sp)
    800014c8:	ec26                	sd	s1,24(sp)
    800014ca:	e84a                	sd	s2,16(sp)
    800014cc:	e44e                	sd	s3,8(sp)
    800014ce:	e052                	sd	s4,0(sp)
    800014d0:	1800                	addi	s0,sp,48
    800014d2:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800014d4:	84aa                	mv	s1,a0
    800014d6:	6905                	lui	s2,0x1
    800014d8:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014da:	4985                	li	s3,1
    800014dc:	a829                	j	800014f6 <freewalk+0x34>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800014de:	83a9                	srli	a5,a5,0xa
      freewalk((pagetable_t)child);
    800014e0:	00c79513          	slli	a0,a5,0xc
    800014e4:	00000097          	auipc	ra,0x0
    800014e8:	fde080e7          	jalr	-34(ra) # 800014c2 <freewalk>
      pagetable[i] = 0;
    800014ec:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    800014f0:	04a1                	addi	s1,s1,8
    800014f2:	03248163          	beq	s1,s2,80001514 <freewalk+0x52>
    pte_t pte = pagetable[i];
    800014f6:	609c                	ld	a5,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014f8:	00f7f713          	andi	a4,a5,15
    800014fc:	ff3701e3          	beq	a4,s3,800014de <freewalk+0x1c>
    } else if(pte & PTE_V){
    80001500:	8b85                	andi	a5,a5,1
    80001502:	d7fd                	beqz	a5,800014f0 <freewalk+0x2e>
      panic("freewalk: leaf");
    80001504:	00007517          	auipc	a0,0x7
    80001508:	c7450513          	addi	a0,a0,-908 # 80008178 <digits+0x138>
    8000150c:	fffff097          	auipc	ra,0xfffff
    80001510:	034080e7          	jalr	52(ra) # 80000540 <panic>
    }
  }
  kfree((void*)pagetable);
    80001514:	8552                	mv	a0,s4
    80001516:	fffff097          	auipc	ra,0xfffff
    8000151a:	4d2080e7          	jalr	1234(ra) # 800009e8 <kfree>
}
    8000151e:	70a2                	ld	ra,40(sp)
    80001520:	7402                	ld	s0,32(sp)
    80001522:	64e2                	ld	s1,24(sp)
    80001524:	6942                	ld	s2,16(sp)
    80001526:	69a2                	ld	s3,8(sp)
    80001528:	6a02                	ld	s4,0(sp)
    8000152a:	6145                	addi	sp,sp,48
    8000152c:	8082                	ret

000000008000152e <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    8000152e:	1101                	addi	sp,sp,-32
    80001530:	ec06                	sd	ra,24(sp)
    80001532:	e822                	sd	s0,16(sp)
    80001534:	e426                	sd	s1,8(sp)
    80001536:	1000                	addi	s0,sp,32
    80001538:	84aa                	mv	s1,a0
  if(sz > 0)
    8000153a:	e999                	bnez	a1,80001550 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    8000153c:	8526                	mv	a0,s1
    8000153e:	00000097          	auipc	ra,0x0
    80001542:	f84080e7          	jalr	-124(ra) # 800014c2 <freewalk>
}
    80001546:	60e2                	ld	ra,24(sp)
    80001548:	6442                	ld	s0,16(sp)
    8000154a:	64a2                	ld	s1,8(sp)
    8000154c:	6105                	addi	sp,sp,32
    8000154e:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    80001550:	6785                	lui	a5,0x1
    80001552:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80001554:	95be                	add	a1,a1,a5
    80001556:	4685                	li	a3,1
    80001558:	00c5d613          	srli	a2,a1,0xc
    8000155c:	4581                	li	a1,0
    8000155e:	00000097          	auipc	ra,0x0
    80001562:	d06080e7          	jalr	-762(ra) # 80001264 <uvmunmap>
    80001566:	bfd9                	j	8000153c <uvmfree+0xe>

0000000080001568 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    80001568:	c679                	beqz	a2,80001636 <uvmcopy+0xce>
{
    8000156a:	715d                	addi	sp,sp,-80
    8000156c:	e486                	sd	ra,72(sp)
    8000156e:	e0a2                	sd	s0,64(sp)
    80001570:	fc26                	sd	s1,56(sp)
    80001572:	f84a                	sd	s2,48(sp)
    80001574:	f44e                	sd	s3,40(sp)
    80001576:	f052                	sd	s4,32(sp)
    80001578:	ec56                	sd	s5,24(sp)
    8000157a:	e85a                	sd	s6,16(sp)
    8000157c:	e45e                	sd	s7,8(sp)
    8000157e:	0880                	addi	s0,sp,80
    80001580:	8b2a                	mv	s6,a0
    80001582:	8aae                	mv	s5,a1
    80001584:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    80001586:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    80001588:	4601                	li	a2,0
    8000158a:	85ce                	mv	a1,s3
    8000158c:	855a                	mv	a0,s6
    8000158e:	00000097          	auipc	ra,0x0
    80001592:	a28080e7          	jalr	-1496(ra) # 80000fb6 <walk>
    80001596:	c531                	beqz	a0,800015e2 <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    80001598:	6118                	ld	a4,0(a0)
    8000159a:	00177793          	andi	a5,a4,1
    8000159e:	cbb1                	beqz	a5,800015f2 <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    800015a0:	00a75593          	srli	a1,a4,0xa
    800015a4:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    800015a8:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    800015ac:	fffff097          	auipc	ra,0xfffff
    800015b0:	53a080e7          	jalr	1338(ra) # 80000ae6 <kalloc>
    800015b4:	892a                	mv	s2,a0
    800015b6:	c939                	beqz	a0,8000160c <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    800015b8:	6605                	lui	a2,0x1
    800015ba:	85de                	mv	a1,s7
    800015bc:	fffff097          	auipc	ra,0xfffff
    800015c0:	772080e7          	jalr	1906(ra) # 80000d2e <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    800015c4:	8726                	mv	a4,s1
    800015c6:	86ca                	mv	a3,s2
    800015c8:	6605                	lui	a2,0x1
    800015ca:	85ce                	mv	a1,s3
    800015cc:	8556                	mv	a0,s5
    800015ce:	00000097          	auipc	ra,0x0
    800015d2:	ad0080e7          	jalr	-1328(ra) # 8000109e <mappages>
    800015d6:	e515                	bnez	a0,80001602 <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    800015d8:	6785                	lui	a5,0x1
    800015da:	99be                	add	s3,s3,a5
    800015dc:	fb49e6e3          	bltu	s3,s4,80001588 <uvmcopy+0x20>
    800015e0:	a081                	j	80001620 <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    800015e2:	00007517          	auipc	a0,0x7
    800015e6:	ba650513          	addi	a0,a0,-1114 # 80008188 <digits+0x148>
    800015ea:	fffff097          	auipc	ra,0xfffff
    800015ee:	f56080e7          	jalr	-170(ra) # 80000540 <panic>
      panic("uvmcopy: page not present");
    800015f2:	00007517          	auipc	a0,0x7
    800015f6:	bb650513          	addi	a0,a0,-1098 # 800081a8 <digits+0x168>
    800015fa:	fffff097          	auipc	ra,0xfffff
    800015fe:	f46080e7          	jalr	-186(ra) # 80000540 <panic>
      kfree(mem);
    80001602:	854a                	mv	a0,s2
    80001604:	fffff097          	auipc	ra,0xfffff
    80001608:	3e4080e7          	jalr	996(ra) # 800009e8 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    8000160c:	4685                	li	a3,1
    8000160e:	00c9d613          	srli	a2,s3,0xc
    80001612:	4581                	li	a1,0
    80001614:	8556                	mv	a0,s5
    80001616:	00000097          	auipc	ra,0x0
    8000161a:	c4e080e7          	jalr	-946(ra) # 80001264 <uvmunmap>
  return -1;
    8000161e:	557d                	li	a0,-1
}
    80001620:	60a6                	ld	ra,72(sp)
    80001622:	6406                	ld	s0,64(sp)
    80001624:	74e2                	ld	s1,56(sp)
    80001626:	7942                	ld	s2,48(sp)
    80001628:	79a2                	ld	s3,40(sp)
    8000162a:	7a02                	ld	s4,32(sp)
    8000162c:	6ae2                	ld	s5,24(sp)
    8000162e:	6b42                	ld	s6,16(sp)
    80001630:	6ba2                	ld	s7,8(sp)
    80001632:	6161                	addi	sp,sp,80
    80001634:	8082                	ret
  return 0;
    80001636:	4501                	li	a0,0
}
    80001638:	8082                	ret

000000008000163a <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    8000163a:	1141                	addi	sp,sp,-16
    8000163c:	e406                	sd	ra,8(sp)
    8000163e:	e022                	sd	s0,0(sp)
    80001640:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    80001642:	4601                	li	a2,0
    80001644:	00000097          	auipc	ra,0x0
    80001648:	972080e7          	jalr	-1678(ra) # 80000fb6 <walk>
  if(pte == 0)
    8000164c:	c901                	beqz	a0,8000165c <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    8000164e:	611c                	ld	a5,0(a0)
    80001650:	9bbd                	andi	a5,a5,-17
    80001652:	e11c                	sd	a5,0(a0)
}
    80001654:	60a2                	ld	ra,8(sp)
    80001656:	6402                	ld	s0,0(sp)
    80001658:	0141                	addi	sp,sp,16
    8000165a:	8082                	ret
    panic("uvmclear");
    8000165c:	00007517          	auipc	a0,0x7
    80001660:	b6c50513          	addi	a0,a0,-1172 # 800081c8 <digits+0x188>
    80001664:	fffff097          	auipc	ra,0xfffff
    80001668:	edc080e7          	jalr	-292(ra) # 80000540 <panic>

000000008000166c <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    8000166c:	c6bd                	beqz	a3,800016da <copyout+0x6e>
{
    8000166e:	715d                	addi	sp,sp,-80
    80001670:	e486                	sd	ra,72(sp)
    80001672:	e0a2                	sd	s0,64(sp)
    80001674:	fc26                	sd	s1,56(sp)
    80001676:	f84a                	sd	s2,48(sp)
    80001678:	f44e                	sd	s3,40(sp)
    8000167a:	f052                	sd	s4,32(sp)
    8000167c:	ec56                	sd	s5,24(sp)
    8000167e:	e85a                	sd	s6,16(sp)
    80001680:	e45e                	sd	s7,8(sp)
    80001682:	e062                	sd	s8,0(sp)
    80001684:	0880                	addi	s0,sp,80
    80001686:	8b2a                	mv	s6,a0
    80001688:	8c2e                	mv	s8,a1
    8000168a:	8a32                	mv	s4,a2
    8000168c:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    8000168e:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    80001690:	6a85                	lui	s5,0x1
    80001692:	a015                	j	800016b6 <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    80001694:	9562                	add	a0,a0,s8
    80001696:	0004861b          	sext.w	a2,s1
    8000169a:	85d2                	mv	a1,s4
    8000169c:	41250533          	sub	a0,a0,s2
    800016a0:	fffff097          	auipc	ra,0xfffff
    800016a4:	68e080e7          	jalr	1678(ra) # 80000d2e <memmove>

    len -= n;
    800016a8:	409989b3          	sub	s3,s3,s1
    src += n;
    800016ac:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    800016ae:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800016b2:	02098263          	beqz	s3,800016d6 <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    800016b6:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800016ba:	85ca                	mv	a1,s2
    800016bc:	855a                	mv	a0,s6
    800016be:	00000097          	auipc	ra,0x0
    800016c2:	99e080e7          	jalr	-1634(ra) # 8000105c <walkaddr>
    if(pa0 == 0)
    800016c6:	cd01                	beqz	a0,800016de <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    800016c8:	418904b3          	sub	s1,s2,s8
    800016cc:	94d6                	add	s1,s1,s5
    800016ce:	fc99f3e3          	bgeu	s3,s1,80001694 <copyout+0x28>
    800016d2:	84ce                	mv	s1,s3
    800016d4:	b7c1                	j	80001694 <copyout+0x28>
  }
  return 0;
    800016d6:	4501                	li	a0,0
    800016d8:	a021                	j	800016e0 <copyout+0x74>
    800016da:	4501                	li	a0,0
}
    800016dc:	8082                	ret
      return -1;
    800016de:	557d                	li	a0,-1
}
    800016e0:	60a6                	ld	ra,72(sp)
    800016e2:	6406                	ld	s0,64(sp)
    800016e4:	74e2                	ld	s1,56(sp)
    800016e6:	7942                	ld	s2,48(sp)
    800016e8:	79a2                	ld	s3,40(sp)
    800016ea:	7a02                	ld	s4,32(sp)
    800016ec:	6ae2                	ld	s5,24(sp)
    800016ee:	6b42                	ld	s6,16(sp)
    800016f0:	6ba2                	ld	s7,8(sp)
    800016f2:	6c02                	ld	s8,0(sp)
    800016f4:	6161                	addi	sp,sp,80
    800016f6:	8082                	ret

00000000800016f8 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800016f8:	caa5                	beqz	a3,80001768 <copyin+0x70>
{
    800016fa:	715d                	addi	sp,sp,-80
    800016fc:	e486                	sd	ra,72(sp)
    800016fe:	e0a2                	sd	s0,64(sp)
    80001700:	fc26                	sd	s1,56(sp)
    80001702:	f84a                	sd	s2,48(sp)
    80001704:	f44e                	sd	s3,40(sp)
    80001706:	f052                	sd	s4,32(sp)
    80001708:	ec56                	sd	s5,24(sp)
    8000170a:	e85a                	sd	s6,16(sp)
    8000170c:	e45e                	sd	s7,8(sp)
    8000170e:	e062                	sd	s8,0(sp)
    80001710:	0880                	addi	s0,sp,80
    80001712:	8b2a                	mv	s6,a0
    80001714:	8a2e                	mv	s4,a1
    80001716:	8c32                	mv	s8,a2
    80001718:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    8000171a:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    8000171c:	6a85                	lui	s5,0x1
    8000171e:	a01d                	j	80001744 <copyin+0x4c>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    80001720:	018505b3          	add	a1,a0,s8
    80001724:	0004861b          	sext.w	a2,s1
    80001728:	412585b3          	sub	a1,a1,s2
    8000172c:	8552                	mv	a0,s4
    8000172e:	fffff097          	auipc	ra,0xfffff
    80001732:	600080e7          	jalr	1536(ra) # 80000d2e <memmove>

    len -= n;
    80001736:	409989b3          	sub	s3,s3,s1
    dst += n;
    8000173a:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    8000173c:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001740:	02098263          	beqz	s3,80001764 <copyin+0x6c>
    va0 = PGROUNDDOWN(srcva);
    80001744:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001748:	85ca                	mv	a1,s2
    8000174a:	855a                	mv	a0,s6
    8000174c:	00000097          	auipc	ra,0x0
    80001750:	910080e7          	jalr	-1776(ra) # 8000105c <walkaddr>
    if(pa0 == 0)
    80001754:	cd01                	beqz	a0,8000176c <copyin+0x74>
    n = PGSIZE - (srcva - va0);
    80001756:	418904b3          	sub	s1,s2,s8
    8000175a:	94d6                	add	s1,s1,s5
    8000175c:	fc99f2e3          	bgeu	s3,s1,80001720 <copyin+0x28>
    80001760:	84ce                	mv	s1,s3
    80001762:	bf7d                	j	80001720 <copyin+0x28>
  }
  return 0;
    80001764:	4501                	li	a0,0
    80001766:	a021                	j	8000176e <copyin+0x76>
    80001768:	4501                	li	a0,0
}
    8000176a:	8082                	ret
      return -1;
    8000176c:	557d                	li	a0,-1
}
    8000176e:	60a6                	ld	ra,72(sp)
    80001770:	6406                	ld	s0,64(sp)
    80001772:	74e2                	ld	s1,56(sp)
    80001774:	7942                	ld	s2,48(sp)
    80001776:	79a2                	ld	s3,40(sp)
    80001778:	7a02                	ld	s4,32(sp)
    8000177a:	6ae2                	ld	s5,24(sp)
    8000177c:	6b42                	ld	s6,16(sp)
    8000177e:	6ba2                	ld	s7,8(sp)
    80001780:	6c02                	ld	s8,0(sp)
    80001782:	6161                	addi	sp,sp,80
    80001784:	8082                	ret

0000000080001786 <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    80001786:	c2dd                	beqz	a3,8000182c <copyinstr+0xa6>
{
    80001788:	715d                	addi	sp,sp,-80
    8000178a:	e486                	sd	ra,72(sp)
    8000178c:	e0a2                	sd	s0,64(sp)
    8000178e:	fc26                	sd	s1,56(sp)
    80001790:	f84a                	sd	s2,48(sp)
    80001792:	f44e                	sd	s3,40(sp)
    80001794:	f052                	sd	s4,32(sp)
    80001796:	ec56                	sd	s5,24(sp)
    80001798:	e85a                	sd	s6,16(sp)
    8000179a:	e45e                	sd	s7,8(sp)
    8000179c:	0880                	addi	s0,sp,80
    8000179e:	8a2a                	mv	s4,a0
    800017a0:	8b2e                	mv	s6,a1
    800017a2:	8bb2                	mv	s7,a2
    800017a4:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    800017a6:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800017a8:	6985                	lui	s3,0x1
    800017aa:	a02d                	j	800017d4 <copyinstr+0x4e>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    800017ac:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    800017b0:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800017b2:	37fd                	addiw	a5,a5,-1
    800017b4:	0007851b          	sext.w	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800017b8:	60a6                	ld	ra,72(sp)
    800017ba:	6406                	ld	s0,64(sp)
    800017bc:	74e2                	ld	s1,56(sp)
    800017be:	7942                	ld	s2,48(sp)
    800017c0:	79a2                	ld	s3,40(sp)
    800017c2:	7a02                	ld	s4,32(sp)
    800017c4:	6ae2                	ld	s5,24(sp)
    800017c6:	6b42                	ld	s6,16(sp)
    800017c8:	6ba2                	ld	s7,8(sp)
    800017ca:	6161                	addi	sp,sp,80
    800017cc:	8082                	ret
    srcva = va0 + PGSIZE;
    800017ce:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    800017d2:	c8a9                	beqz	s1,80001824 <copyinstr+0x9e>
    va0 = PGROUNDDOWN(srcva);
    800017d4:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800017d8:	85ca                	mv	a1,s2
    800017da:	8552                	mv	a0,s4
    800017dc:	00000097          	auipc	ra,0x0
    800017e0:	880080e7          	jalr	-1920(ra) # 8000105c <walkaddr>
    if(pa0 == 0)
    800017e4:	c131                	beqz	a0,80001828 <copyinstr+0xa2>
    n = PGSIZE - (srcva - va0);
    800017e6:	417906b3          	sub	a3,s2,s7
    800017ea:	96ce                	add	a3,a3,s3
    800017ec:	00d4f363          	bgeu	s1,a3,800017f2 <copyinstr+0x6c>
    800017f0:	86a6                	mv	a3,s1
    char *p = (char *) (pa0 + (srcva - va0));
    800017f2:	955e                	add	a0,a0,s7
    800017f4:	41250533          	sub	a0,a0,s2
    while(n > 0){
    800017f8:	daf9                	beqz	a3,800017ce <copyinstr+0x48>
    800017fa:	87da                	mv	a5,s6
      if(*p == '\0'){
    800017fc:	41650633          	sub	a2,a0,s6
    80001800:	fff48593          	addi	a1,s1,-1
    80001804:	95da                	add	a1,a1,s6
    while(n > 0){
    80001806:	96da                	add	a3,a3,s6
      if(*p == '\0'){
    80001808:	00f60733          	add	a4,a2,a5
    8000180c:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffdbfd0>
    80001810:	df51                	beqz	a4,800017ac <copyinstr+0x26>
        *dst = *p;
    80001812:	00e78023          	sb	a4,0(a5)
      --max;
    80001816:	40f584b3          	sub	s1,a1,a5
      dst++;
    8000181a:	0785                	addi	a5,a5,1
    while(n > 0){
    8000181c:	fed796e3          	bne	a5,a3,80001808 <copyinstr+0x82>
      dst++;
    80001820:	8b3e                	mv	s6,a5
    80001822:	b775                	j	800017ce <copyinstr+0x48>
    80001824:	4781                	li	a5,0
    80001826:	b771                	j	800017b2 <copyinstr+0x2c>
      return -1;
    80001828:	557d                	li	a0,-1
    8000182a:	b779                	j	800017b8 <copyinstr+0x32>
  int got_null = 0;
    8000182c:	4781                	li	a5,0
  if(got_null){
    8000182e:	37fd                	addiw	a5,a5,-1
    80001830:	0007851b          	sext.w	a0,a5
}
    80001834:	8082                	ret

0000000080001836 <proc_mapstacks>:
// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl)
{
    80001836:	7139                	addi	sp,sp,-64
    80001838:	fc06                	sd	ra,56(sp)
    8000183a:	f822                	sd	s0,48(sp)
    8000183c:	f426                	sd	s1,40(sp)
    8000183e:	f04a                	sd	s2,32(sp)
    80001840:	ec4e                	sd	s3,24(sp)
    80001842:	e852                	sd	s4,16(sp)
    80001844:	e456                	sd	s5,8(sp)
    80001846:	e05a                	sd	s6,0(sp)
    80001848:	0080                	addi	s0,sp,64
    8000184a:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    8000184c:	00010497          	auipc	s1,0x10
    80001850:	a0448493          	addi	s1,s1,-1532 # 80011250 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    80001854:	8b26                	mv	s6,s1
    80001856:	00006a97          	auipc	s5,0x6
    8000185a:	7aaa8a93          	addi	s5,s5,1962 # 80008000 <etext>
    8000185e:	04000937          	lui	s2,0x4000
    80001862:	197d                	addi	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    80001864:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001866:	00016a17          	auipc	s4,0x16
    8000186a:	3eaa0a13          	addi	s4,s4,1002 # 80017c50 <tickslock>
    char *pa = kalloc();
    8000186e:	fffff097          	auipc	ra,0xfffff
    80001872:	278080e7          	jalr	632(ra) # 80000ae6 <kalloc>
    80001876:	862a                	mv	a2,a0
    if(pa == 0)
    80001878:	c131                	beqz	a0,800018bc <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    8000187a:	416485b3          	sub	a1,s1,s6
    8000187e:	858d                	srai	a1,a1,0x3
    80001880:	000ab783          	ld	a5,0(s5)
    80001884:	02f585b3          	mul	a1,a1,a5
    80001888:	2585                	addiw	a1,a1,1
    8000188a:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    8000188e:	4719                	li	a4,6
    80001890:	6685                	lui	a3,0x1
    80001892:	40b905b3          	sub	a1,s2,a1
    80001896:	854e                	mv	a0,s3
    80001898:	00000097          	auipc	ra,0x0
    8000189c:	8a6080e7          	jalr	-1882(ra) # 8000113e <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    800018a0:	1a848493          	addi	s1,s1,424
    800018a4:	fd4495e3          	bne	s1,s4,8000186e <proc_mapstacks+0x38>
  }
}
    800018a8:	70e2                	ld	ra,56(sp)
    800018aa:	7442                	ld	s0,48(sp)
    800018ac:	74a2                	ld	s1,40(sp)
    800018ae:	7902                	ld	s2,32(sp)
    800018b0:	69e2                	ld	s3,24(sp)
    800018b2:	6a42                	ld	s4,16(sp)
    800018b4:	6aa2                	ld	s5,8(sp)
    800018b6:	6b02                	ld	s6,0(sp)
    800018b8:	6121                	addi	sp,sp,64
    800018ba:	8082                	ret
      panic("kalloc");
    800018bc:	00007517          	auipc	a0,0x7
    800018c0:	91c50513          	addi	a0,a0,-1764 # 800081d8 <digits+0x198>
    800018c4:	fffff097          	auipc	ra,0xfffff
    800018c8:	c7c080e7          	jalr	-900(ra) # 80000540 <panic>

00000000800018cc <procinit>:

// initialize the proc table.
void
procinit(void)
{
    800018cc:	7139                	addi	sp,sp,-64
    800018ce:	fc06                	sd	ra,56(sp)
    800018d0:	f822                	sd	s0,48(sp)
    800018d2:	f426                	sd	s1,40(sp)
    800018d4:	f04a                	sd	s2,32(sp)
    800018d6:	ec4e                	sd	s3,24(sp)
    800018d8:	e852                	sd	s4,16(sp)
    800018da:	e456                	sd	s5,8(sp)
    800018dc:	e05a                	sd	s6,0(sp)
    800018de:	0080                	addi	s0,sp,64
  struct proc *p;
  
  initlock(&pid_lock, "nextpid");
    800018e0:	00007597          	auipc	a1,0x7
    800018e4:	90058593          	addi	a1,a1,-1792 # 800081e0 <digits+0x1a0>
    800018e8:	0000f517          	auipc	a0,0xf
    800018ec:	53850513          	addi	a0,a0,1336 # 80010e20 <pid_lock>
    800018f0:	fffff097          	auipc	ra,0xfffff
    800018f4:	256080e7          	jalr	598(ra) # 80000b46 <initlock>
  initlock(&wait_lock, "wait_lock");
    800018f8:	00007597          	auipc	a1,0x7
    800018fc:	8f058593          	addi	a1,a1,-1808 # 800081e8 <digits+0x1a8>
    80001900:	0000f517          	auipc	a0,0xf
    80001904:	53850513          	addi	a0,a0,1336 # 80010e38 <wait_lock>
    80001908:	fffff097          	auipc	ra,0xfffff
    8000190c:	23e080e7          	jalr	574(ra) # 80000b46 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001910:	00010497          	auipc	s1,0x10
    80001914:	94048493          	addi	s1,s1,-1728 # 80011250 <proc>
      initlock(&p->lock, "proc");
    80001918:	00007b17          	auipc	s6,0x7
    8000191c:	8e0b0b13          	addi	s6,s6,-1824 # 800081f8 <digits+0x1b8>
      p->state = UNUSED;
      p->kstack = KSTACK((int) (p - proc));
    80001920:	8aa6                	mv	s5,s1
    80001922:	00006a17          	auipc	s4,0x6
    80001926:	6dea0a13          	addi	s4,s4,1758 # 80008000 <etext>
    8000192a:	04000937          	lui	s2,0x4000
    8000192e:	197d                	addi	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    80001930:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001932:	00016997          	auipc	s3,0x16
    80001936:	31e98993          	addi	s3,s3,798 # 80017c50 <tickslock>
      initlock(&p->lock, "proc");
    8000193a:	85da                	mv	a1,s6
    8000193c:	8526                	mv	a0,s1
    8000193e:	fffff097          	auipc	ra,0xfffff
    80001942:	208080e7          	jalr	520(ra) # 80000b46 <initlock>
      p->state = UNUSED;
    80001946:	0004ac23          	sw	zero,24(s1)
      p->kstack = KSTACK((int) (p - proc));
    8000194a:	415487b3          	sub	a5,s1,s5
    8000194e:	878d                	srai	a5,a5,0x3
    80001950:	000a3703          	ld	a4,0(s4)
    80001954:	02e787b3          	mul	a5,a5,a4
    80001958:	2785                	addiw	a5,a5,1
    8000195a:	00d7979b          	slliw	a5,a5,0xd
    8000195e:	40f907b3          	sub	a5,s2,a5
    80001962:	e0bc                	sd	a5,64(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    80001964:	1a848493          	addi	s1,s1,424
    80001968:	fd3499e3          	bne	s1,s3,8000193a <procinit+0x6e>
  }
}
    8000196c:	70e2                	ld	ra,56(sp)
    8000196e:	7442                	ld	s0,48(sp)
    80001970:	74a2                	ld	s1,40(sp)
    80001972:	7902                	ld	s2,32(sp)
    80001974:	69e2                	ld	s3,24(sp)
    80001976:	6a42                	ld	s4,16(sp)
    80001978:	6aa2                	ld	s5,8(sp)
    8000197a:	6b02                	ld	s6,0(sp)
    8000197c:	6121                	addi	sp,sp,64
    8000197e:	8082                	ret

0000000080001980 <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    80001980:	1141                	addi	sp,sp,-16
    80001982:	e422                	sd	s0,8(sp)
    80001984:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001986:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001988:	2501                	sext.w	a0,a0
    8000198a:	6422                	ld	s0,8(sp)
    8000198c:	0141                	addi	sp,sp,16
    8000198e:	8082                	ret

0000000080001990 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void)
{
    80001990:	1141                	addi	sp,sp,-16
    80001992:	e422                	sd	s0,8(sp)
    80001994:	0800                	addi	s0,sp,16
    80001996:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001998:	2781                	sext.w	a5,a5
    8000199a:	079e                	slli	a5,a5,0x7
  return c;
}
    8000199c:	0000f517          	auipc	a0,0xf
    800019a0:	4b450513          	addi	a0,a0,1204 # 80010e50 <cpus>
    800019a4:	953e                	add	a0,a0,a5
    800019a6:	6422                	ld	s0,8(sp)
    800019a8:	0141                	addi	sp,sp,16
    800019aa:	8082                	ret

00000000800019ac <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void)
{
    800019ac:	1101                	addi	sp,sp,-32
    800019ae:	ec06                	sd	ra,24(sp)
    800019b0:	e822                	sd	s0,16(sp)
    800019b2:	e426                	sd	s1,8(sp)
    800019b4:	1000                	addi	s0,sp,32
  push_off();
    800019b6:	fffff097          	auipc	ra,0xfffff
    800019ba:	1d4080e7          	jalr	468(ra) # 80000b8a <push_off>
    800019be:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    800019c0:	2781                	sext.w	a5,a5
    800019c2:	079e                	slli	a5,a5,0x7
    800019c4:	0000f717          	auipc	a4,0xf
    800019c8:	45c70713          	addi	a4,a4,1116 # 80010e20 <pid_lock>
    800019cc:	97ba                	add	a5,a5,a4
    800019ce:	7b84                	ld	s1,48(a5)
  pop_off();
    800019d0:	fffff097          	auipc	ra,0xfffff
    800019d4:	25a080e7          	jalr	602(ra) # 80000c2a <pop_off>
  return p;
}
    800019d8:	8526                	mv	a0,s1
    800019da:	60e2                	ld	ra,24(sp)
    800019dc:	6442                	ld	s0,16(sp)
    800019de:	64a2                	ld	s1,8(sp)
    800019e0:	6105                	addi	sp,sp,32
    800019e2:	8082                	ret

00000000800019e4 <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    800019e4:	1141                	addi	sp,sp,-16
    800019e6:	e406                	sd	ra,8(sp)
    800019e8:	e022                	sd	s0,0(sp)
    800019ea:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    800019ec:	00000097          	auipc	ra,0x0
    800019f0:	fc0080e7          	jalr	-64(ra) # 800019ac <myproc>
    800019f4:	fffff097          	auipc	ra,0xfffff
    800019f8:	296080e7          	jalr	662(ra) # 80000c8a <release>

  if (first) {
    800019fc:	00007797          	auipc	a5,0x7
    80001a00:	fe47a783          	lw	a5,-28(a5) # 800089e0 <first.1>
    80001a04:	eb89                	bnez	a5,80001a16 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001a06:	00001097          	auipc	ra,0x1
    80001a0a:	008080e7          	jalr	8(ra) # 80002a0e <usertrapret>
}
    80001a0e:	60a2                	ld	ra,8(sp)
    80001a10:	6402                	ld	s0,0(sp)
    80001a12:	0141                	addi	sp,sp,16
    80001a14:	8082                	ret
    first = 0;
    80001a16:	00007797          	auipc	a5,0x7
    80001a1a:	fc07a523          	sw	zero,-54(a5) # 800089e0 <first.1>
    fsinit(ROOTDEV);
    80001a1e:	4505                	li	a0,1
    80001a20:	00002097          	auipc	ra,0x2
    80001a24:	ff0080e7          	jalr	-16(ra) # 80003a10 <fsinit>
    80001a28:	bff9                	j	80001a06 <forkret+0x22>

0000000080001a2a <allocpid>:
{
    80001a2a:	1101                	addi	sp,sp,-32
    80001a2c:	ec06                	sd	ra,24(sp)
    80001a2e:	e822                	sd	s0,16(sp)
    80001a30:	e426                	sd	s1,8(sp)
    80001a32:	e04a                	sd	s2,0(sp)
    80001a34:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001a36:	0000f917          	auipc	s2,0xf
    80001a3a:	3ea90913          	addi	s2,s2,1002 # 80010e20 <pid_lock>
    80001a3e:	854a                	mv	a0,s2
    80001a40:	fffff097          	auipc	ra,0xfffff
    80001a44:	196080e7          	jalr	406(ra) # 80000bd6 <acquire>
  pid = nextpid;
    80001a48:	00007797          	auipc	a5,0x7
    80001a4c:	f9c78793          	addi	a5,a5,-100 # 800089e4 <nextpid>
    80001a50:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001a52:	0014871b          	addiw	a4,s1,1
    80001a56:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001a58:	854a                	mv	a0,s2
    80001a5a:	fffff097          	auipc	ra,0xfffff
    80001a5e:	230080e7          	jalr	560(ra) # 80000c8a <release>
}
    80001a62:	8526                	mv	a0,s1
    80001a64:	60e2                	ld	ra,24(sp)
    80001a66:	6442                	ld	s0,16(sp)
    80001a68:	64a2                	ld	s1,8(sp)
    80001a6a:	6902                	ld	s2,0(sp)
    80001a6c:	6105                	addi	sp,sp,32
    80001a6e:	8082                	ret

0000000080001a70 <proc_pagetable>:
{
    80001a70:	1101                	addi	sp,sp,-32
    80001a72:	ec06                	sd	ra,24(sp)
    80001a74:	e822                	sd	s0,16(sp)
    80001a76:	e426                	sd	s1,8(sp)
    80001a78:	e04a                	sd	s2,0(sp)
    80001a7a:	1000                	addi	s0,sp,32
    80001a7c:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001a7e:	00000097          	auipc	ra,0x0
    80001a82:	8aa080e7          	jalr	-1878(ra) # 80001328 <uvmcreate>
    80001a86:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001a88:	c121                	beqz	a0,80001ac8 <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001a8a:	4729                	li	a4,10
    80001a8c:	00005697          	auipc	a3,0x5
    80001a90:	57468693          	addi	a3,a3,1396 # 80007000 <_trampoline>
    80001a94:	6605                	lui	a2,0x1
    80001a96:	040005b7          	lui	a1,0x4000
    80001a9a:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001a9c:	05b2                	slli	a1,a1,0xc
    80001a9e:	fffff097          	auipc	ra,0xfffff
    80001aa2:	600080e7          	jalr	1536(ra) # 8000109e <mappages>
    80001aa6:	02054863          	bltz	a0,80001ad6 <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001aaa:	4719                	li	a4,6
    80001aac:	05893683          	ld	a3,88(s2)
    80001ab0:	6605                	lui	a2,0x1
    80001ab2:	020005b7          	lui	a1,0x2000
    80001ab6:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001ab8:	05b6                	slli	a1,a1,0xd
    80001aba:	8526                	mv	a0,s1
    80001abc:	fffff097          	auipc	ra,0xfffff
    80001ac0:	5e2080e7          	jalr	1506(ra) # 8000109e <mappages>
    80001ac4:	02054163          	bltz	a0,80001ae6 <proc_pagetable+0x76>
}
    80001ac8:	8526                	mv	a0,s1
    80001aca:	60e2                	ld	ra,24(sp)
    80001acc:	6442                	ld	s0,16(sp)
    80001ace:	64a2                	ld	s1,8(sp)
    80001ad0:	6902                	ld	s2,0(sp)
    80001ad2:	6105                	addi	sp,sp,32
    80001ad4:	8082                	ret
    uvmfree(pagetable, 0);
    80001ad6:	4581                	li	a1,0
    80001ad8:	8526                	mv	a0,s1
    80001ada:	00000097          	auipc	ra,0x0
    80001ade:	a54080e7          	jalr	-1452(ra) # 8000152e <uvmfree>
    return 0;
    80001ae2:	4481                	li	s1,0
    80001ae4:	b7d5                	j	80001ac8 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001ae6:	4681                	li	a3,0
    80001ae8:	4605                	li	a2,1
    80001aea:	040005b7          	lui	a1,0x4000
    80001aee:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001af0:	05b2                	slli	a1,a1,0xc
    80001af2:	8526                	mv	a0,s1
    80001af4:	fffff097          	auipc	ra,0xfffff
    80001af8:	770080e7          	jalr	1904(ra) # 80001264 <uvmunmap>
    uvmfree(pagetable, 0);
    80001afc:	4581                	li	a1,0
    80001afe:	8526                	mv	a0,s1
    80001b00:	00000097          	auipc	ra,0x0
    80001b04:	a2e080e7          	jalr	-1490(ra) # 8000152e <uvmfree>
    return 0;
    80001b08:	4481                	li	s1,0
    80001b0a:	bf7d                	j	80001ac8 <proc_pagetable+0x58>

0000000080001b0c <proc_freepagetable>:
{
    80001b0c:	1101                	addi	sp,sp,-32
    80001b0e:	ec06                	sd	ra,24(sp)
    80001b10:	e822                	sd	s0,16(sp)
    80001b12:	e426                	sd	s1,8(sp)
    80001b14:	e04a                	sd	s2,0(sp)
    80001b16:	1000                	addi	s0,sp,32
    80001b18:	84aa                	mv	s1,a0
    80001b1a:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b1c:	4681                	li	a3,0
    80001b1e:	4605                	li	a2,1
    80001b20:	040005b7          	lui	a1,0x4000
    80001b24:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001b26:	05b2                	slli	a1,a1,0xc
    80001b28:	fffff097          	auipc	ra,0xfffff
    80001b2c:	73c080e7          	jalr	1852(ra) # 80001264 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001b30:	4681                	li	a3,0
    80001b32:	4605                	li	a2,1
    80001b34:	020005b7          	lui	a1,0x2000
    80001b38:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001b3a:	05b6                	slli	a1,a1,0xd
    80001b3c:	8526                	mv	a0,s1
    80001b3e:	fffff097          	auipc	ra,0xfffff
    80001b42:	726080e7          	jalr	1830(ra) # 80001264 <uvmunmap>
  uvmfree(pagetable, sz);
    80001b46:	85ca                	mv	a1,s2
    80001b48:	8526                	mv	a0,s1
    80001b4a:	00000097          	auipc	ra,0x0
    80001b4e:	9e4080e7          	jalr	-1564(ra) # 8000152e <uvmfree>
}
    80001b52:	60e2                	ld	ra,24(sp)
    80001b54:	6442                	ld	s0,16(sp)
    80001b56:	64a2                	ld	s1,8(sp)
    80001b58:	6902                	ld	s2,0(sp)
    80001b5a:	6105                	addi	sp,sp,32
    80001b5c:	8082                	ret

0000000080001b5e <freeproc>:
{
    80001b5e:	1101                	addi	sp,sp,-32
    80001b60:	ec06                	sd	ra,24(sp)
    80001b62:	e822                	sd	s0,16(sp)
    80001b64:	e426                	sd	s1,8(sp)
    80001b66:	1000                	addi	s0,sp,32
    80001b68:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001b6a:	6d28                	ld	a0,88(a0)
    80001b6c:	c509                	beqz	a0,80001b76 <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001b6e:	fffff097          	auipc	ra,0xfffff
    80001b72:	e7a080e7          	jalr	-390(ra) # 800009e8 <kfree>
  p->trapframe = 0;
    80001b76:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001b7a:	68a8                	ld	a0,80(s1)
    80001b7c:	c511                	beqz	a0,80001b88 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001b7e:	64ac                	ld	a1,72(s1)
    80001b80:	00000097          	auipc	ra,0x0
    80001b84:	f8c080e7          	jalr	-116(ra) # 80001b0c <proc_freepagetable>
  p->pagetable = 0;
    80001b88:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001b8c:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001b90:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001b94:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001b98:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001b9c:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001ba0:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001ba4:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001ba8:	0004ac23          	sw	zero,24(s1)
}
    80001bac:	60e2                	ld	ra,24(sp)
    80001bae:	6442                	ld	s0,16(sp)
    80001bb0:	64a2                	ld	s1,8(sp)
    80001bb2:	6105                	addi	sp,sp,32
    80001bb4:	8082                	ret

0000000080001bb6 <allocproc>:
{
    80001bb6:	1101                	addi	sp,sp,-32
    80001bb8:	ec06                	sd	ra,24(sp)
    80001bba:	e822                	sd	s0,16(sp)
    80001bbc:	e426                	sd	s1,8(sp)
    80001bbe:	e04a                	sd	s2,0(sp)
    80001bc0:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001bc2:	0000f497          	auipc	s1,0xf
    80001bc6:	68e48493          	addi	s1,s1,1678 # 80011250 <proc>
    80001bca:	00016917          	auipc	s2,0x16
    80001bce:	08690913          	addi	s2,s2,134 # 80017c50 <tickslock>
    acquire(&p->lock);
    80001bd2:	8526                	mv	a0,s1
    80001bd4:	fffff097          	auipc	ra,0xfffff
    80001bd8:	002080e7          	jalr	2(ra) # 80000bd6 <acquire>
    if(p->state == UNUSED) {
    80001bdc:	4c9c                	lw	a5,24(s1)
    80001bde:	cf81                	beqz	a5,80001bf6 <allocproc+0x40>
      release(&p->lock);
    80001be0:	8526                	mv	a0,s1
    80001be2:	fffff097          	auipc	ra,0xfffff
    80001be6:	0a8080e7          	jalr	168(ra) # 80000c8a <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001bea:	1a848493          	addi	s1,s1,424
    80001bee:	ff2492e3          	bne	s1,s2,80001bd2 <allocproc+0x1c>
  return 0;
    80001bf2:	4481                	li	s1,0
    80001bf4:	a069                	j	80001c7e <allocproc+0xc8>
  p->pid = allocpid();
    80001bf6:	00000097          	auipc	ra,0x0
    80001bfa:	e34080e7          	jalr	-460(ra) # 80001a2a <allocpid>
    80001bfe:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001c00:	4785                	li	a5,1
    80001c02:	cc9c                	sw	a5,24(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001c04:	fffff097          	auipc	ra,0xfffff
    80001c08:	ee2080e7          	jalr	-286(ra) # 80000ae6 <kalloc>
    80001c0c:	892a                	mv	s2,a0
    80001c0e:	eca8                	sd	a0,88(s1)
    80001c10:	cd35                	beqz	a0,80001c8c <allocproc+0xd6>
  p->pagetable = proc_pagetable(p);
    80001c12:	8526                	mv	a0,s1
    80001c14:	00000097          	auipc	ra,0x0
    80001c18:	e5c080e7          	jalr	-420(ra) # 80001a70 <proc_pagetable>
    80001c1c:	892a                	mv	s2,a0
    80001c1e:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001c20:	c151                	beqz	a0,80001ca4 <allocproc+0xee>
  memset(&p->context, 0, sizeof(p->context));
    80001c22:	07000613          	li	a2,112
    80001c26:	4581                	li	a1,0
    80001c28:	06048513          	addi	a0,s1,96
    80001c2c:	fffff097          	auipc	ra,0xfffff
    80001c30:	0a6080e7          	jalr	166(ra) # 80000cd2 <memset>
  p->context.ra = (uint64)forkret;
    80001c34:	00000797          	auipc	a5,0x0
    80001c38:	db078793          	addi	a5,a5,-592 # 800019e4 <forkret>
    80001c3c:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001c3e:	60bc                	ld	a5,64(s1)
    80001c40:	6705                	lui	a4,0x1
    80001c42:	97ba                	add	a5,a5,a4
    80001c44:	f4bc                	sd	a5,104(s1)
  	  p->rtime = 0;	
    80001c46:	1604ac23          	sw	zero,376(s1)
  p->etime = 0;	
    80001c4a:	1804a023          	sw	zero,384(s1)
  p->ctime = ticks;	
    80001c4e:	00007797          	auipc	a5,0x7
    80001c52:	f627a783          	lw	a5,-158(a5) # 80008bb0 <ticks>
    80001c56:	16f4ae23          	sw	a5,380(s1)
  p->mask = 0;	
    80001c5a:	1604a423          	sw	zero,360(s1)
  p->no_of_times_scheduled = 0;	
    80001c5e:	1804a223          	sw	zero,388(s1)
    p->entry_time = ticks;	
    80001c62:	18f4a423          	sw	a5,392(s1)
    p->current_queue = 0;	
    80001c66:	1a04a023          	sw	zero,416(s1)
      p->queue_ticks[i] = 0;	
    80001c6a:	1804a623          	sw	zero,396(s1)
    80001c6e:	1804a823          	sw	zero,400(s1)
    80001c72:	1804aa23          	sw	zero,404(s1)
    80001c76:	1804ac23          	sw	zero,408(s1)
    80001c7a:	1804ae23          	sw	zero,412(s1)
}
    80001c7e:	8526                	mv	a0,s1
    80001c80:	60e2                	ld	ra,24(sp)
    80001c82:	6442                	ld	s0,16(sp)
    80001c84:	64a2                	ld	s1,8(sp)
    80001c86:	6902                	ld	s2,0(sp)
    80001c88:	6105                	addi	sp,sp,32
    80001c8a:	8082                	ret
    freeproc(p);
    80001c8c:	8526                	mv	a0,s1
    80001c8e:	00000097          	auipc	ra,0x0
    80001c92:	ed0080e7          	jalr	-304(ra) # 80001b5e <freeproc>
    release(&p->lock);
    80001c96:	8526                	mv	a0,s1
    80001c98:	fffff097          	auipc	ra,0xfffff
    80001c9c:	ff2080e7          	jalr	-14(ra) # 80000c8a <release>
    return 0;
    80001ca0:	84ca                	mv	s1,s2
    80001ca2:	bff1                	j	80001c7e <allocproc+0xc8>
    freeproc(p);
    80001ca4:	8526                	mv	a0,s1
    80001ca6:	00000097          	auipc	ra,0x0
    80001caa:	eb8080e7          	jalr	-328(ra) # 80001b5e <freeproc>
    release(&p->lock);
    80001cae:	8526                	mv	a0,s1
    80001cb0:	fffff097          	auipc	ra,0xfffff
    80001cb4:	fda080e7          	jalr	-38(ra) # 80000c8a <release>
    return 0;
    80001cb8:	84ca                	mv	s1,s2
    80001cba:	b7d1                	j	80001c7e <allocproc+0xc8>

0000000080001cbc <userinit>:
{
    80001cbc:	1101                	addi	sp,sp,-32
    80001cbe:	ec06                	sd	ra,24(sp)
    80001cc0:	e822                	sd	s0,16(sp)
    80001cc2:	e426                	sd	s1,8(sp)
    80001cc4:	1000                	addi	s0,sp,32
  p = allocproc();
    80001cc6:	00000097          	auipc	ra,0x0
    80001cca:	ef0080e7          	jalr	-272(ra) # 80001bb6 <allocproc>
    80001cce:	84aa                	mv	s1,a0
  initproc = p;
    80001cd0:	00007797          	auipc	a5,0x7
    80001cd4:	eca7bc23          	sd	a0,-296(a5) # 80008ba8 <initproc>
  uvmfirst(p->pagetable, initcode, sizeof(initcode));
    80001cd8:	03400613          	li	a2,52
    80001cdc:	00007597          	auipc	a1,0x7
    80001ce0:	d1458593          	addi	a1,a1,-748 # 800089f0 <initcode>
    80001ce4:	6928                	ld	a0,80(a0)
    80001ce6:	fffff097          	auipc	ra,0xfffff
    80001cea:	670080e7          	jalr	1648(ra) # 80001356 <uvmfirst>
  p->sz = PGSIZE;
    80001cee:	6785                	lui	a5,0x1
    80001cf0:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001cf2:	6cb8                	ld	a4,88(s1)
    80001cf4:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001cf8:	6cb8                	ld	a4,88(s1)
    80001cfa:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001cfc:	4641                	li	a2,16
    80001cfe:	00006597          	auipc	a1,0x6
    80001d02:	50258593          	addi	a1,a1,1282 # 80008200 <digits+0x1c0>
    80001d06:	15848513          	addi	a0,s1,344
    80001d0a:	fffff097          	auipc	ra,0xfffff
    80001d0e:	112080e7          	jalr	274(ra) # 80000e1c <safestrcpy>
  p->cwd = namei("/");
    80001d12:	00006517          	auipc	a0,0x6
    80001d16:	4fe50513          	addi	a0,a0,1278 # 80008210 <digits+0x1d0>
    80001d1a:	00002097          	auipc	ra,0x2
    80001d1e:	720080e7          	jalr	1824(ra) # 8000443a <namei>
    80001d22:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001d26:	478d                	li	a5,3
    80001d28:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001d2a:	8526                	mv	a0,s1
    80001d2c:	fffff097          	auipc	ra,0xfffff
    80001d30:	f5e080e7          	jalr	-162(ra) # 80000c8a <release>
}
    80001d34:	60e2                	ld	ra,24(sp)
    80001d36:	6442                	ld	s0,16(sp)
    80001d38:	64a2                	ld	s1,8(sp)
    80001d3a:	6105                	addi	sp,sp,32
    80001d3c:	8082                	ret

0000000080001d3e <growproc>:
{
    80001d3e:	1101                	addi	sp,sp,-32
    80001d40:	ec06                	sd	ra,24(sp)
    80001d42:	e822                	sd	s0,16(sp)
    80001d44:	e426                	sd	s1,8(sp)
    80001d46:	e04a                	sd	s2,0(sp)
    80001d48:	1000                	addi	s0,sp,32
    80001d4a:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80001d4c:	00000097          	auipc	ra,0x0
    80001d50:	c60080e7          	jalr	-928(ra) # 800019ac <myproc>
    80001d54:	84aa                	mv	s1,a0
  sz = p->sz;
    80001d56:	652c                	ld	a1,72(a0)
  if(n > 0){
    80001d58:	01204c63          	bgtz	s2,80001d70 <growproc+0x32>
  } else if(n < 0){
    80001d5c:	02094663          	bltz	s2,80001d88 <growproc+0x4a>
  p->sz = sz;
    80001d60:	e4ac                	sd	a1,72(s1)
  return 0;
    80001d62:	4501                	li	a0,0
}
    80001d64:	60e2                	ld	ra,24(sp)
    80001d66:	6442                	ld	s0,16(sp)
    80001d68:	64a2                	ld	s1,8(sp)
    80001d6a:	6902                	ld	s2,0(sp)
    80001d6c:	6105                	addi	sp,sp,32
    80001d6e:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0) {
    80001d70:	4691                	li	a3,4
    80001d72:	00b90633          	add	a2,s2,a1
    80001d76:	6928                	ld	a0,80(a0)
    80001d78:	fffff097          	auipc	ra,0xfffff
    80001d7c:	698080e7          	jalr	1688(ra) # 80001410 <uvmalloc>
    80001d80:	85aa                	mv	a1,a0
    80001d82:	fd79                	bnez	a0,80001d60 <growproc+0x22>
      return -1;
    80001d84:	557d                	li	a0,-1
    80001d86:	bff9                	j	80001d64 <growproc+0x26>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001d88:	00b90633          	add	a2,s2,a1
    80001d8c:	6928                	ld	a0,80(a0)
    80001d8e:	fffff097          	auipc	ra,0xfffff
    80001d92:	63a080e7          	jalr	1594(ra) # 800013c8 <uvmdealloc>
    80001d96:	85aa                	mv	a1,a0
    80001d98:	b7e1                	j	80001d60 <growproc+0x22>

0000000080001d9a <fork>:
{
    80001d9a:	7139                	addi	sp,sp,-64
    80001d9c:	fc06                	sd	ra,56(sp)
    80001d9e:	f822                	sd	s0,48(sp)
    80001da0:	f426                	sd	s1,40(sp)
    80001da2:	f04a                	sd	s2,32(sp)
    80001da4:	ec4e                	sd	s3,24(sp)
    80001da6:	e852                	sd	s4,16(sp)
    80001da8:	e456                	sd	s5,8(sp)
    80001daa:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80001dac:	00000097          	auipc	ra,0x0
    80001db0:	c00080e7          	jalr	-1024(ra) # 800019ac <myproc>
    80001db4:	8aaa                	mv	s5,a0
  if((np = allocproc()) == 0){
    80001db6:	00000097          	auipc	ra,0x0
    80001dba:	e00080e7          	jalr	-512(ra) # 80001bb6 <allocproc>
    80001dbe:	12050063          	beqz	a0,80001ede <fork+0x144>
    80001dc2:	89aa                	mv	s3,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001dc4:	048ab603          	ld	a2,72(s5)
    80001dc8:	692c                	ld	a1,80(a0)
    80001dca:	050ab503          	ld	a0,80(s5)
    80001dce:	fffff097          	auipc	ra,0xfffff
    80001dd2:	79a080e7          	jalr	1946(ra) # 80001568 <uvmcopy>
    80001dd6:	04054c63          	bltz	a0,80001e2e <fork+0x94>
  np->sz = p->sz;
    80001dda:	048ab783          	ld	a5,72(s5)
    80001dde:	04f9b423          	sd	a5,72(s3)
  np->mask = p->mask; // strace sys call
    80001de2:	168aa783          	lw	a5,360(s5)
    80001de6:	16f9a423          	sw	a5,360(s3)
  *(np->trapframe) = *(p->trapframe);
    80001dea:	058ab683          	ld	a3,88(s5)
    80001dee:	87b6                	mv	a5,a3
    80001df0:	0589b703          	ld	a4,88(s3)
    80001df4:	12068693          	addi	a3,a3,288
    80001df8:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001dfc:	6788                	ld	a0,8(a5)
    80001dfe:	6b8c                	ld	a1,16(a5)
    80001e00:	6f90                	ld	a2,24(a5)
    80001e02:	01073023          	sd	a6,0(a4)
    80001e06:	e708                	sd	a0,8(a4)
    80001e08:	eb0c                	sd	a1,16(a4)
    80001e0a:	ef10                	sd	a2,24(a4)
    80001e0c:	02078793          	addi	a5,a5,32
    80001e10:	02070713          	addi	a4,a4,32
    80001e14:	fed792e3          	bne	a5,a3,80001df8 <fork+0x5e>
  np->trapframe->a0 = 0;
    80001e18:	0589b783          	ld	a5,88(s3)
    80001e1c:	0607b823          	sd	zero,112(a5)
  for(i = 0; i < NOFILE; i++)
    80001e20:	0d0a8493          	addi	s1,s5,208
    80001e24:	0d098913          	addi	s2,s3,208
    80001e28:	150a8a13          	addi	s4,s5,336
    80001e2c:	a00d                	j	80001e4e <fork+0xb4>
    freeproc(np);
    80001e2e:	854e                	mv	a0,s3
    80001e30:	00000097          	auipc	ra,0x0
    80001e34:	d2e080e7          	jalr	-722(ra) # 80001b5e <freeproc>
    release(&np->lock);
    80001e38:	854e                	mv	a0,s3
    80001e3a:	fffff097          	auipc	ra,0xfffff
    80001e3e:	e50080e7          	jalr	-432(ra) # 80000c8a <release>
    return -1;
    80001e42:	597d                	li	s2,-1
    80001e44:	a059                	j	80001eca <fork+0x130>
  for(i = 0; i < NOFILE; i++)
    80001e46:	04a1                	addi	s1,s1,8
    80001e48:	0921                	addi	s2,s2,8
    80001e4a:	01448b63          	beq	s1,s4,80001e60 <fork+0xc6>
    if(p->ofile[i])
    80001e4e:	6088                	ld	a0,0(s1)
    80001e50:	d97d                	beqz	a0,80001e46 <fork+0xac>
      np->ofile[i] = filedup(p->ofile[i]);
    80001e52:	00003097          	auipc	ra,0x3
    80001e56:	c7e080e7          	jalr	-898(ra) # 80004ad0 <filedup>
    80001e5a:	00a93023          	sd	a0,0(s2)
    80001e5e:	b7e5                	j	80001e46 <fork+0xac>
  np->cwd = idup(p->cwd);
    80001e60:	150ab503          	ld	a0,336(s5)
    80001e64:	00002097          	auipc	ra,0x2
    80001e68:	dec080e7          	jalr	-532(ra) # 80003c50 <idup>
    80001e6c:	14a9b823          	sd	a0,336(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001e70:	4641                	li	a2,16
    80001e72:	158a8593          	addi	a1,s5,344
    80001e76:	15898513          	addi	a0,s3,344
    80001e7a:	fffff097          	auipc	ra,0xfffff
    80001e7e:	fa2080e7          	jalr	-94(ra) # 80000e1c <safestrcpy>
  pid = np->pid;
    80001e82:	0309a903          	lw	s2,48(s3)
  release(&np->lock);
    80001e86:	854e                	mv	a0,s3
    80001e88:	fffff097          	auipc	ra,0xfffff
    80001e8c:	e02080e7          	jalr	-510(ra) # 80000c8a <release>
  acquire(&wait_lock);
    80001e90:	0000f497          	auipc	s1,0xf
    80001e94:	fa848493          	addi	s1,s1,-88 # 80010e38 <wait_lock>
    80001e98:	8526                	mv	a0,s1
    80001e9a:	fffff097          	auipc	ra,0xfffff
    80001e9e:	d3c080e7          	jalr	-708(ra) # 80000bd6 <acquire>
  np->parent = p;
    80001ea2:	0359bc23          	sd	s5,56(s3)
  release(&wait_lock);
    80001ea6:	8526                	mv	a0,s1
    80001ea8:	fffff097          	auipc	ra,0xfffff
    80001eac:	de2080e7          	jalr	-542(ra) # 80000c8a <release>
  acquire(&np->lock);
    80001eb0:	854e                	mv	a0,s3
    80001eb2:	fffff097          	auipc	ra,0xfffff
    80001eb6:	d24080e7          	jalr	-732(ra) # 80000bd6 <acquire>
  np->state = RUNNABLE;
    80001eba:	478d                	li	a5,3
    80001ebc:	00f9ac23          	sw	a5,24(s3)
  release(&np->lock);
    80001ec0:	854e                	mv	a0,s3
    80001ec2:	fffff097          	auipc	ra,0xfffff
    80001ec6:	dc8080e7          	jalr	-568(ra) # 80000c8a <release>
}
    80001eca:	854a                	mv	a0,s2
    80001ecc:	70e2                	ld	ra,56(sp)
    80001ece:	7442                	ld	s0,48(sp)
    80001ed0:	74a2                	ld	s1,40(sp)
    80001ed2:	7902                	ld	s2,32(sp)
    80001ed4:	69e2                	ld	s3,24(sp)
    80001ed6:	6a42                	ld	s4,16(sp)
    80001ed8:	6aa2                	ld	s5,8(sp)
    80001eda:	6121                	addi	sp,sp,64
    80001edc:	8082                	ret
    return -1;
    80001ede:	597d                	li	s2,-1
    80001ee0:	b7ed                	j	80001eca <fork+0x130>

0000000080001ee2 <update_time>:
{	
    80001ee2:	7179                	addi	sp,sp,-48
    80001ee4:	f406                	sd	ra,40(sp)
    80001ee6:	f022                	sd	s0,32(sp)
    80001ee8:	ec26                	sd	s1,24(sp)
    80001eea:	e84a                	sd	s2,16(sp)
    80001eec:	e44e                	sd	s3,8(sp)
    80001eee:	1800                	addi	s0,sp,48
  for (p = proc; p < &proc[NPROC]; p++) {	
    80001ef0:	0000f497          	auipc	s1,0xf
    80001ef4:	36048493          	addi	s1,s1,864 # 80011250 <proc>
    if (p->state == RUNNING) {	
    80001ef8:	4991                	li	s3,4
  for (p = proc; p < &proc[NPROC]; p++) {	
    80001efa:	00016917          	auipc	s2,0x16
    80001efe:	d5690913          	addi	s2,s2,-682 # 80017c50 <tickslock>
    80001f02:	a811                	j	80001f16 <update_time+0x34>
    release(&p->lock); 	
    80001f04:	8526                	mv	a0,s1
    80001f06:	fffff097          	auipc	ra,0xfffff
    80001f0a:	d84080e7          	jalr	-636(ra) # 80000c8a <release>
  for (p = proc; p < &proc[NPROC]; p++) {	
    80001f0e:	1a848493          	addi	s1,s1,424
    80001f12:	03248063          	beq	s1,s2,80001f32 <update_time+0x50>
    acquire(&p->lock);	
    80001f16:	8526                	mv	a0,s1
    80001f18:	fffff097          	auipc	ra,0xfffff
    80001f1c:	cbe080e7          	jalr	-834(ra) # 80000bd6 <acquire>
    if (p->state == RUNNING) {	
    80001f20:	4c9c                	lw	a5,24(s1)
    80001f22:	ff3791e3          	bne	a5,s3,80001f04 <update_time+0x22>
      p->rtime++;	
    80001f26:	1784a783          	lw	a5,376(s1)
    80001f2a:	2785                	addiw	a5,a5,1
    80001f2c:	16f4ac23          	sw	a5,376(s1)
    80001f30:	bfd1                	j	80001f04 <update_time+0x22>
}	
    80001f32:	70a2                	ld	ra,40(sp)
    80001f34:	7402                	ld	s0,32(sp)
    80001f36:	64e2                	ld	s1,24(sp)
    80001f38:	6942                	ld	s2,16(sp)
    80001f3a:	69a2                	ld	s3,8(sp)
    80001f3c:	6145                	addi	sp,sp,48
    80001f3e:	8082                	ret

0000000080001f40 <trace>:
{	
    80001f40:	1101                	addi	sp,sp,-32
    80001f42:	ec06                	sd	ra,24(sp)
    80001f44:	e822                	sd	s0,16(sp)
    80001f46:	e426                	sd	s1,8(sp)
    80001f48:	e04a                	sd	s2,0(sp)
    80001f4a:	1000                	addi	s0,sp,32
    80001f4c:	892a                	mv	s2,a0
  struct proc *p = myproc();	
    80001f4e:	00000097          	auipc	ra,0x0
    80001f52:	a5e080e7          	jalr	-1442(ra) # 800019ac <myproc>
    80001f56:	84aa                	mv	s1,a0
  acquire(&p->lock);	
    80001f58:	fffff097          	auipc	ra,0xfffff
    80001f5c:	c7e080e7          	jalr	-898(ra) # 80000bd6 <acquire>
  p->mask = mask;	
    80001f60:	1724a423          	sw	s2,360(s1)
  release(&p->lock);	
    80001f64:	8526                	mv	a0,s1
    80001f66:	fffff097          	auipc	ra,0xfffff
    80001f6a:	d24080e7          	jalr	-732(ra) # 80000c8a <release>
}	
    80001f6e:	60e2                	ld	ra,24(sp)
    80001f70:	6442                	ld	s0,16(sp)
    80001f72:	64a2                	ld	s1,8(sp)
    80001f74:	6902                	ld	s2,0(sp)
    80001f76:	6105                	addi	sp,sp,32
    80001f78:	8082                	ret

0000000080001f7a <set_priority>:
{	
    80001f7a:	1141                	addi	sp,sp,-16
    80001f7c:	e422                	sd	s0,8(sp)
    80001f7e:	0800                	addi	s0,sp,16
    80001f80:	04000793          	li	a5,64
  for (p = proc; p < &proc[NPROC]; p++) {	
    80001f84:	17fd                	addi	a5,a5,-1
    80001f86:	fffd                	bnez	a5,80001f84 <set_priority+0xa>
}
    80001f88:	557d                	li	a0,-1
    80001f8a:	6422                	ld	s0,8(sp)
    80001f8c:	0141                	addi	sp,sp,16
    80001f8e:	8082                	ret

0000000080001f90 <scheduler>:
{
    80001f90:	715d                	addi	sp,sp,-80
    80001f92:	e486                	sd	ra,72(sp)
    80001f94:	e0a2                	sd	s0,64(sp)
    80001f96:	fc26                	sd	s1,56(sp)
    80001f98:	f84a                	sd	s2,48(sp)
    80001f9a:	f44e                	sd	s3,40(sp)
    80001f9c:	f052                	sd	s4,32(sp)
    80001f9e:	ec56                	sd	s5,24(sp)
    80001fa0:	e85a                	sd	s6,16(sp)
    80001fa2:	e45e                	sd	s7,8(sp)
    80001fa4:	e062                	sd	s8,0(sp)
    80001fa6:	0880                	addi	s0,sp,80
    80001fa8:	8792                	mv	a5,tp
  int id = r_tp();
    80001faa:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001fac:	00779693          	slli	a3,a5,0x7
    80001fb0:	0000f717          	auipc	a4,0xf
    80001fb4:	e7070713          	addi	a4,a4,-400 # 80010e20 <pid_lock>
    80001fb8:	9736                	add	a4,a4,a3
    80001fba:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &chosenProc->context);	
    80001fbe:	0000f717          	auipc	a4,0xf
    80001fc2:	e9a70713          	addi	a4,a4,-358 # 80010e58 <cpus+0x8>
    80001fc6:	00e68c33          	add	s8,a3,a4
        if ((ticks - p->entry_time > WAITING_LIMIT) && p->current_queue > 0) {	
    80001fca:	00007a17          	auipc	s4,0x7
    80001fce:	be6a0a13          	addi	s4,s4,-1050 # 80008bb0 <ticks>
    for (p = proc; p < &proc[NPROC]; p++) {	
    80001fd2:	00016997          	auipc	s3,0x16
    80001fd6:	c7e98993          	addi	s3,s3,-898 # 80017c50 <tickslock>
        c->proc = chosenProc;	
    80001fda:	0000fb97          	auipc	s7,0xf
    80001fde:	e46b8b93          	addi	s7,s7,-442 # 80010e20 <pid_lock>
    80001fe2:	9bb6                	add	s7,s7,a3
    80001fe4:	aa35                	j	80002120 <scheduler+0x190>
    for (p = proc; p < &proc[NPROC]; p++) {	
    80001fe6:	1a848493          	addi	s1,s1,424
    80001fea:	07348063          	beq	s1,s3,8000204a <scheduler+0xba>
      if (p->state == RUNNABLE) {	
    80001fee:	4c9c                	lw	a5,24(s1)
    80001ff0:	ff279be3          	bne	a5,s2,80001fe6 <scheduler+0x56>
        if ((ticks - p->entry_time > WAITING_LIMIT) && p->current_queue > 0) {	
    80001ff4:	000a2783          	lw	a5,0(s4)
    80001ff8:	1884a703          	lw	a4,392(s1)
    80001ffc:	9f99                	subw	a5,a5,a4
    80001ffe:	fefaf4e3          	bgeu	s5,a5,80001fe6 <scheduler+0x56>
    80002002:	1a04a783          	lw	a5,416(s1)
    80002006:	d3e5                	beqz	a5,80001fe6 <scheduler+0x56>
          acquire(&p->lock);	
    80002008:	8526                	mv	a0,s1
    8000200a:	fffff097          	auipc	ra,0xfffff
    8000200e:	bcc080e7          	jalr	-1076(ra) # 80000bd6 <acquire>
          p->queue_ticks[p->current_queue] += (ticks - p->entry_time);	
    80002012:	1a04a703          	lw	a4,416(s1)
    80002016:	02071793          	slli	a5,a4,0x20
    8000201a:	01e7d693          	srli	a3,a5,0x1e
    8000201e:	96a6                	add	a3,a3,s1
    80002020:	000a2603          	lw	a2,0(s4)
    80002024:	18c6a783          	lw	a5,396(a3)
    80002028:	1884a583          	lw	a1,392(s1)
    8000202c:	9f8d                	subw	a5,a5,a1
    8000202e:	9fb1                	addw	a5,a5,a2
    80002030:	18f6a623          	sw	a5,396(a3)
          p->current_queue--;	
    80002034:	377d                	addiw	a4,a4,-1
    80002036:	1ae4a023          	sw	a4,416(s1)
          p->entry_time = ticks;	
    8000203a:	18c4a423          	sw	a2,392(s1)
          release(&p->lock);	
    8000203e:	8526                	mv	a0,s1
    80002040:	fffff097          	auipc	ra,0xfffff
    80002044:	c4a080e7          	jalr	-950(ra) # 80000c8a <release>
    80002048:	bf79                	j	80001fe6 <scheduler+0x56>
    8000204a:	0000f797          	auipc	a5,0xf
    8000204e:	3ae78793          	addi	a5,a5,942 # 800113f8 <proc+0x1a8>
    int highest_queue = 5;	
    80002052:	855a                	mv	a0,s6
    struct proc *chosenProc = 0;	
    80002054:	4481                	li	s1,0
    80002056:	a839                	j	80002074 <scheduler+0xe4>
        if (chosenProc == 0) {	
    80002058:	c0b9                	beqz	s1,8000209e <scheduler+0x10e>
        else if (p->current_queue < highest_queue) {	
    8000205a:	ff87a683          	lw	a3,-8(a5)
    8000205e:	0005059b          	sext.w	a1,a0
    80002062:	04b6f263          	bgeu	a3,a1,800020a6 <scheduler+0x116>
          highest_queue = chosenProc->current_queue;	
    80002066:	0006851b          	sext.w	a0,a3
    8000206a:	84b2                	mv	s1,a2
    for (p = proc; p < &proc[NPROC]; p++) {	
    8000206c:	05377763          	bgeu	a4,s3,800020ba <scheduler+0x12a>
    80002070:	1a878793          	addi	a5,a5,424
    80002074:	e5878613          	addi	a2,a5,-424
      if (p->state == RUNNABLE) {	
    80002078:	873e                	mv	a4,a5
    8000207a:	e707a683          	lw	a3,-400(a5)
    8000207e:	fd268de3          	beq	a3,s2,80002058 <scheduler+0xc8>
    for (p = proc; p < &proc[NPROC]; p++) {	
    80002082:	ff37e7e3          	bltu	a5,s3,80002070 <scheduler+0xe0>
    if (chosenProc != 0) {	
    80002086:	e895                	bnez	s1,800020ba <scheduler+0x12a>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002088:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    8000208c:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002090:	10079073          	csrw	sstatus,a5
    for (p = proc; p < &proc[NPROC]; p++) {	
    80002094:	0000f497          	auipc	s1,0xf
    80002098:	1bc48493          	addi	s1,s1,444 # 80011250 <proc>
    8000209c:	bf89                	j	80001fee <scheduler+0x5e>
          highest_queue = chosenProc->current_queue;	
    8000209e:	ff87a503          	lw	a0,-8(a5)
    800020a2:	84b2                	mv	s1,a2
    800020a4:	b7e1                	j	8000206c <scheduler+0xdc>
        else if (p->current_queue == highest_queue && p->entry_time < chosenProc->entry_time) {	
    800020a6:	fcb693e3          	bne	a3,a1,8000206c <scheduler+0xdc>
    800020aa:	fe07a583          	lw	a1,-32(a5)
    800020ae:	1884a683          	lw	a3,392(s1)
    800020b2:	fad5fde3          	bgeu	a1,a3,8000206c <scheduler+0xdc>
    800020b6:	84b2                	mv	s1,a2
    800020b8:	bf55                	j	8000206c <scheduler+0xdc>
      acquire(&chosenProc->lock);	
    800020ba:	8926                	mv	s2,s1
    800020bc:	8526                	mv	a0,s1
    800020be:	fffff097          	auipc	ra,0xfffff
    800020c2:	b18080e7          	jalr	-1256(ra) # 80000bd6 <acquire>
      if (chosenProc->state == RUNNABLE) {	
    800020c6:	4c98                	lw	a4,24(s1)
    800020c8:	478d                	li	a5,3
    800020ca:	04f71663          	bne	a4,a5,80002116 <scheduler+0x186>
        chosenProc->no_of_times_scheduled++;	
    800020ce:	1844a783          	lw	a5,388(s1)
    800020d2:	2785                	addiw	a5,a5,1
    800020d4:	18f4a223          	sw	a5,388(s1)
        chosenProc->entry_time = ticks;	
    800020d8:	000a2783          	lw	a5,0(s4)
    800020dc:	18f4a423          	sw	a5,392(s1)
        chosenProc->state = RUNNING;	
    800020e0:	4791                	li	a5,4
    800020e2:	cc9c                	sw	a5,24(s1)
        c->proc = chosenProc;	
    800020e4:	029bb823          	sd	s1,48(s7)
        swtch(&c->context, &chosenProc->context);	
    800020e8:	06048593          	addi	a1,s1,96
    800020ec:	8562                	mv	a0,s8
    800020ee:	00001097          	auipc	ra,0x1
    800020f2:	876080e7          	jalr	-1930(ra) # 80002964 <swtch>
        c->proc = 0;	
    800020f6:	020bb823          	sd	zero,48(s7)
        chosenProc->queue_ticks[chosenProc->current_queue] += (ticks - chosenProc->entry_time);	
    800020fa:	1a04e783          	lwu	a5,416(s1)
    800020fe:	078a                	slli	a5,a5,0x2
    80002100:	97a6                	add	a5,a5,s1
    80002102:	18c7a703          	lw	a4,396(a5)
    80002106:	1884a683          	lw	a3,392(s1)
    8000210a:	9f15                	subw	a4,a4,a3
    8000210c:	000a2683          	lw	a3,0(s4)
    80002110:	9f35                	addw	a4,a4,a3
    80002112:	18e7a623          	sw	a4,396(a5)
      release(&chosenProc->lock);	
    80002116:	854a                	mv	a0,s2
    80002118:	fffff097          	auipc	ra,0xfffff
    8000211c:	b72080e7          	jalr	-1166(ra) # 80000c8a <release>
      if (p->state == RUNNABLE) {	
    80002120:	490d                	li	s2,3
        if ((ticks - p->entry_time > WAITING_LIMIT) && p->current_queue > 0) {	
    80002122:	4ac1                	li	s5,16
    int highest_queue = 5;	
    80002124:	4b15                	li	s6,5
    80002126:	b78d                	j	80002088 <scheduler+0xf8>

0000000080002128 <sched>:
{
    80002128:	7179                	addi	sp,sp,-48
    8000212a:	f406                	sd	ra,40(sp)
    8000212c:	f022                	sd	s0,32(sp)
    8000212e:	ec26                	sd	s1,24(sp)
    80002130:	e84a                	sd	s2,16(sp)
    80002132:	e44e                	sd	s3,8(sp)
    80002134:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80002136:	00000097          	auipc	ra,0x0
    8000213a:	876080e7          	jalr	-1930(ra) # 800019ac <myproc>
    8000213e:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80002140:	fffff097          	auipc	ra,0xfffff
    80002144:	a1c080e7          	jalr	-1508(ra) # 80000b5c <holding>
    80002148:	c93d                	beqz	a0,800021be <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    8000214a:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    8000214c:	2781                	sext.w	a5,a5
    8000214e:	079e                	slli	a5,a5,0x7
    80002150:	0000f717          	auipc	a4,0xf
    80002154:	cd070713          	addi	a4,a4,-816 # 80010e20 <pid_lock>
    80002158:	97ba                	add	a5,a5,a4
    8000215a:	0a87a703          	lw	a4,168(a5)
    8000215e:	4785                	li	a5,1
    80002160:	06f71763          	bne	a4,a5,800021ce <sched+0xa6>
  if(p->state == RUNNING)
    80002164:	4c98                	lw	a4,24(s1)
    80002166:	4791                	li	a5,4
    80002168:	06f70b63          	beq	a4,a5,800021de <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000216c:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002170:	8b89                	andi	a5,a5,2
  if(intr_get())
    80002172:	efb5                	bnez	a5,800021ee <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002174:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80002176:	0000f917          	auipc	s2,0xf
    8000217a:	caa90913          	addi	s2,s2,-854 # 80010e20 <pid_lock>
    8000217e:	2781                	sext.w	a5,a5
    80002180:	079e                	slli	a5,a5,0x7
    80002182:	97ca                	add	a5,a5,s2
    80002184:	0ac7a983          	lw	s3,172(a5)
    80002188:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    8000218a:	2781                	sext.w	a5,a5
    8000218c:	079e                	slli	a5,a5,0x7
    8000218e:	0000f597          	auipc	a1,0xf
    80002192:	cca58593          	addi	a1,a1,-822 # 80010e58 <cpus+0x8>
    80002196:	95be                	add	a1,a1,a5
    80002198:	06048513          	addi	a0,s1,96
    8000219c:	00000097          	auipc	ra,0x0
    800021a0:	7c8080e7          	jalr	1992(ra) # 80002964 <swtch>
    800021a4:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    800021a6:	2781                	sext.w	a5,a5
    800021a8:	079e                	slli	a5,a5,0x7
    800021aa:	993e                	add	s2,s2,a5
    800021ac:	0b392623          	sw	s3,172(s2)
}
    800021b0:	70a2                	ld	ra,40(sp)
    800021b2:	7402                	ld	s0,32(sp)
    800021b4:	64e2                	ld	s1,24(sp)
    800021b6:	6942                	ld	s2,16(sp)
    800021b8:	69a2                	ld	s3,8(sp)
    800021ba:	6145                	addi	sp,sp,48
    800021bc:	8082                	ret
    panic("sched p->lock");
    800021be:	00006517          	auipc	a0,0x6
    800021c2:	05a50513          	addi	a0,a0,90 # 80008218 <digits+0x1d8>
    800021c6:	ffffe097          	auipc	ra,0xffffe
    800021ca:	37a080e7          	jalr	890(ra) # 80000540 <panic>
    panic("sched locks");
    800021ce:	00006517          	auipc	a0,0x6
    800021d2:	05a50513          	addi	a0,a0,90 # 80008228 <digits+0x1e8>
    800021d6:	ffffe097          	auipc	ra,0xffffe
    800021da:	36a080e7          	jalr	874(ra) # 80000540 <panic>
    panic("sched running");
    800021de:	00006517          	auipc	a0,0x6
    800021e2:	05a50513          	addi	a0,a0,90 # 80008238 <digits+0x1f8>
    800021e6:	ffffe097          	auipc	ra,0xffffe
    800021ea:	35a080e7          	jalr	858(ra) # 80000540 <panic>
    panic("sched interruptible");
    800021ee:	00006517          	auipc	a0,0x6
    800021f2:	05a50513          	addi	a0,a0,90 # 80008248 <digits+0x208>
    800021f6:	ffffe097          	auipc	ra,0xffffe
    800021fa:	34a080e7          	jalr	842(ra) # 80000540 <panic>

00000000800021fe <yield>:
{
    800021fe:	1101                	addi	sp,sp,-32
    80002200:	ec06                	sd	ra,24(sp)
    80002202:	e822                	sd	s0,16(sp)
    80002204:	e426                	sd	s1,8(sp)
    80002206:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002208:	fffff097          	auipc	ra,0xfffff
    8000220c:	7a4080e7          	jalr	1956(ra) # 800019ac <myproc>
    80002210:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002212:	fffff097          	auipc	ra,0xfffff
    80002216:	9c4080e7          	jalr	-1596(ra) # 80000bd6 <acquire>
  p->state = RUNNABLE;
    8000221a:	478d                	li	a5,3
    8000221c:	cc9c                	sw	a5,24(s1)
  sched();
    8000221e:	00000097          	auipc	ra,0x0
    80002222:	f0a080e7          	jalr	-246(ra) # 80002128 <sched>
  release(&p->lock);
    80002226:	8526                	mv	a0,s1
    80002228:	fffff097          	auipc	ra,0xfffff
    8000222c:	a62080e7          	jalr	-1438(ra) # 80000c8a <release>
}
    80002230:	60e2                	ld	ra,24(sp)
    80002232:	6442                	ld	s0,16(sp)
    80002234:	64a2                	ld	s1,8(sp)
    80002236:	6105                	addi	sp,sp,32
    80002238:	8082                	ret

000000008000223a <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    8000223a:	7179                	addi	sp,sp,-48
    8000223c:	f406                	sd	ra,40(sp)
    8000223e:	f022                	sd	s0,32(sp)
    80002240:	ec26                	sd	s1,24(sp)
    80002242:	e84a                	sd	s2,16(sp)
    80002244:	e44e                	sd	s3,8(sp)
    80002246:	1800                	addi	s0,sp,48
    80002248:	89aa                	mv	s3,a0
    8000224a:	892e                	mv	s2,a1
  struct proc *p = myproc();
    8000224c:	fffff097          	auipc	ra,0xfffff
    80002250:	760080e7          	jalr	1888(ra) # 800019ac <myproc>
    80002254:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    80002256:	fffff097          	auipc	ra,0xfffff
    8000225a:	980080e7          	jalr	-1664(ra) # 80000bd6 <acquire>
  release(lk);
    8000225e:	854a                	mv	a0,s2
    80002260:	fffff097          	auipc	ra,0xfffff
    80002264:	a2a080e7          	jalr	-1494(ra) # 80000c8a <release>

  // Go to sleep.
  p->chan = chan;
    80002268:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    8000226c:	4789                	li	a5,2
    8000226e:	cc9c                	sw	a5,24(s1)
  	  #ifdef PBS	
    p->s_start_time = ticks;	
  #endif

  sched();
    80002270:	00000097          	auipc	ra,0x0
    80002274:	eb8080e7          	jalr	-328(ra) # 80002128 <sched>

  // Tidy up.
  p->chan = 0;
    80002278:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    8000227c:	8526                	mv	a0,s1
    8000227e:	fffff097          	auipc	ra,0xfffff
    80002282:	a0c080e7          	jalr	-1524(ra) # 80000c8a <release>
  acquire(lk);
    80002286:	854a                	mv	a0,s2
    80002288:	fffff097          	auipc	ra,0xfffff
    8000228c:	94e080e7          	jalr	-1714(ra) # 80000bd6 <acquire>
}
    80002290:	70a2                	ld	ra,40(sp)
    80002292:	7402                	ld	s0,32(sp)
    80002294:	64e2                	ld	s1,24(sp)
    80002296:	6942                	ld	s2,16(sp)
    80002298:	69a2                	ld	s3,8(sp)
    8000229a:	6145                	addi	sp,sp,48
    8000229c:	8082                	ret

000000008000229e <waitx>:
{	
    8000229e:	711d                	addi	sp,sp,-96
    800022a0:	ec86                	sd	ra,88(sp)
    800022a2:	e8a2                	sd	s0,80(sp)
    800022a4:	e4a6                	sd	s1,72(sp)
    800022a6:	e0ca                	sd	s2,64(sp)
    800022a8:	fc4e                	sd	s3,56(sp)
    800022aa:	f852                	sd	s4,48(sp)
    800022ac:	f456                	sd	s5,40(sp)
    800022ae:	f05a                	sd	s6,32(sp)
    800022b0:	ec5e                	sd	s7,24(sp)
    800022b2:	e862                	sd	s8,16(sp)
    800022b4:	e466                	sd	s9,8(sp)
    800022b6:	e06a                	sd	s10,0(sp)
    800022b8:	1080                	addi	s0,sp,96
    800022ba:	8b2a                	mv	s6,a0
    800022bc:	8c2e                	mv	s8,a1
    800022be:	8bb2                	mv	s7,a2
  struct proc *p = myproc();	
    800022c0:	fffff097          	auipc	ra,0xfffff
    800022c4:	6ec080e7          	jalr	1772(ra) # 800019ac <myproc>
    800022c8:	892a                	mv	s2,a0
  acquire(&wait_lock);	
    800022ca:	0000f517          	auipc	a0,0xf
    800022ce:	b6e50513          	addi	a0,a0,-1170 # 80010e38 <wait_lock>
    800022d2:	fffff097          	auipc	ra,0xfffff
    800022d6:	904080e7          	jalr	-1788(ra) # 80000bd6 <acquire>
    havekids = 0;	
    800022da:	4c81                	li	s9,0
        if(np->state == ZOMBIE){	
    800022dc:	4a15                	li	s4,5
        havekids = 1;	
    800022de:	4a85                	li	s5,1
    for(np = proc; np < &proc[NPROC]; np++){	
    800022e0:	00016997          	auipc	s3,0x16
    800022e4:	97098993          	addi	s3,s3,-1680 # 80017c50 <tickslock>
    sleep(p, &wait_lock);  //DOC: wait-sleep	
    800022e8:	0000fd17          	auipc	s10,0xf
    800022ec:	b50d0d13          	addi	s10,s10,-1200 # 80010e38 <wait_lock>
    havekids = 0;	
    800022f0:	8766                	mv	a4,s9
    for(np = proc; np < &proc[NPROC]; np++){	
    800022f2:	0000f497          	auipc	s1,0xf
    800022f6:	f5e48493          	addi	s1,s1,-162 # 80011250 <proc>
    800022fa:	a059                	j	80002380 <waitx+0xe2>
          pid = np->pid;	
    800022fc:	0304a983          	lw	s3,48(s1)
          *rtime = np->rtime;	
    80002300:	1784a783          	lw	a5,376(s1)
    80002304:	00fc2023          	sw	a5,0(s8)
          *wtime = np->etime - np->ctime - np->rtime;	
    80002308:	17c4a703          	lw	a4,380(s1)
    8000230c:	9f3d                	addw	a4,a4,a5
    8000230e:	1804a783          	lw	a5,384(s1)
    80002312:	9f99                	subw	a5,a5,a4
    80002314:	00fba023          	sw	a5,0(s7)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,	
    80002318:	000b0e63          	beqz	s6,80002334 <waitx+0x96>
    8000231c:	4691                	li	a3,4
    8000231e:	02c48613          	addi	a2,s1,44
    80002322:	85da                	mv	a1,s6
    80002324:	05093503          	ld	a0,80(s2)
    80002328:	fffff097          	auipc	ra,0xfffff
    8000232c:	344080e7          	jalr	836(ra) # 8000166c <copyout>
    80002330:	02054563          	bltz	a0,8000235a <waitx+0xbc>
          freeproc(np);	
    80002334:	8526                	mv	a0,s1
    80002336:	00000097          	auipc	ra,0x0
    8000233a:	828080e7          	jalr	-2008(ra) # 80001b5e <freeproc>
          release(&np->lock);	
    8000233e:	8526                	mv	a0,s1
    80002340:	fffff097          	auipc	ra,0xfffff
    80002344:	94a080e7          	jalr	-1718(ra) # 80000c8a <release>
          release(&wait_lock);	
    80002348:	0000f517          	auipc	a0,0xf
    8000234c:	af050513          	addi	a0,a0,-1296 # 80010e38 <wait_lock>
    80002350:	fffff097          	auipc	ra,0xfffff
    80002354:	93a080e7          	jalr	-1734(ra) # 80000c8a <release>
          return pid;	
    80002358:	a09d                	j	800023be <waitx+0x120>
            release(&np->lock);	
    8000235a:	8526                	mv	a0,s1
    8000235c:	fffff097          	auipc	ra,0xfffff
    80002360:	92e080e7          	jalr	-1746(ra) # 80000c8a <release>
            release(&wait_lock);	
    80002364:	0000f517          	auipc	a0,0xf
    80002368:	ad450513          	addi	a0,a0,-1324 # 80010e38 <wait_lock>
    8000236c:	fffff097          	auipc	ra,0xfffff
    80002370:	91e080e7          	jalr	-1762(ra) # 80000c8a <release>
            return -1;	
    80002374:	59fd                	li	s3,-1
    80002376:	a0a1                	j	800023be <waitx+0x120>
    for(np = proc; np < &proc[NPROC]; np++){	
    80002378:	1a848493          	addi	s1,s1,424
    8000237c:	03348463          	beq	s1,s3,800023a4 <waitx+0x106>
      if(np->parent == p){	
    80002380:	7c9c                	ld	a5,56(s1)
    80002382:	ff279be3          	bne	a5,s2,80002378 <waitx+0xda>
        acquire(&np->lock);	
    80002386:	8526                	mv	a0,s1
    80002388:	fffff097          	auipc	ra,0xfffff
    8000238c:	84e080e7          	jalr	-1970(ra) # 80000bd6 <acquire>
        if(np->state == ZOMBIE){	
    80002390:	4c9c                	lw	a5,24(s1)
    80002392:	f74785e3          	beq	a5,s4,800022fc <waitx+0x5e>
        release(&np->lock);	
    80002396:	8526                	mv	a0,s1
    80002398:	fffff097          	auipc	ra,0xfffff
    8000239c:	8f2080e7          	jalr	-1806(ra) # 80000c8a <release>
        havekids = 1;	
    800023a0:	8756                	mv	a4,s5
    800023a2:	bfd9                	j	80002378 <waitx+0xda>
    if(!havekids || p->killed){	
    800023a4:	c701                	beqz	a4,800023ac <waitx+0x10e>
    800023a6:	02892783          	lw	a5,40(s2)
    800023aa:	cb8d                	beqz	a5,800023dc <waitx+0x13e>
      release(&wait_lock);	
    800023ac:	0000f517          	auipc	a0,0xf
    800023b0:	a8c50513          	addi	a0,a0,-1396 # 80010e38 <wait_lock>
    800023b4:	fffff097          	auipc	ra,0xfffff
    800023b8:	8d6080e7          	jalr	-1834(ra) # 80000c8a <release>
      return -1;	
    800023bc:	59fd                	li	s3,-1
}	
    800023be:	854e                	mv	a0,s3
    800023c0:	60e6                	ld	ra,88(sp)
    800023c2:	6446                	ld	s0,80(sp)
    800023c4:	64a6                	ld	s1,72(sp)
    800023c6:	6906                	ld	s2,64(sp)
    800023c8:	79e2                	ld	s3,56(sp)
    800023ca:	7a42                	ld	s4,48(sp)
    800023cc:	7aa2                	ld	s5,40(sp)
    800023ce:	7b02                	ld	s6,32(sp)
    800023d0:	6be2                	ld	s7,24(sp)
    800023d2:	6c42                	ld	s8,16(sp)
    800023d4:	6ca2                	ld	s9,8(sp)
    800023d6:	6d02                	ld	s10,0(sp)
    800023d8:	6125                	addi	sp,sp,96
    800023da:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep	
    800023dc:	85ea                	mv	a1,s10
    800023de:	854a                	mv	a0,s2
    800023e0:	00000097          	auipc	ra,0x0
    800023e4:	e5a080e7          	jalr	-422(ra) # 8000223a <sleep>
    havekids = 0;	
    800023e8:	b721                	j	800022f0 <waitx+0x52>

00000000800023ea <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    800023ea:	7139                	addi	sp,sp,-64
    800023ec:	fc06                	sd	ra,56(sp)
    800023ee:	f822                	sd	s0,48(sp)
    800023f0:	f426                	sd	s1,40(sp)
    800023f2:	f04a                	sd	s2,32(sp)
    800023f4:	ec4e                	sd	s3,24(sp)
    800023f6:	e852                	sd	s4,16(sp)
    800023f8:	e456                	sd	s5,8(sp)
    800023fa:	0080                	addi	s0,sp,64
    800023fc:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    800023fe:	0000f497          	auipc	s1,0xf
    80002402:	e5248493          	addi	s1,s1,-430 # 80011250 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    80002406:	4989                	li	s3,2
        p->state = RUNNABLE;
    80002408:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    8000240a:	00016917          	auipc	s2,0x16
    8000240e:	84690913          	addi	s2,s2,-1978 # 80017c50 <tickslock>
    80002412:	a811                	j	80002426 <wakeup+0x3c>
         #ifdef PBS	
          p->stime = ticks - p->s_start_time;	
        #endif
      }
      release(&p->lock);
    80002414:	8526                	mv	a0,s1
    80002416:	fffff097          	auipc	ra,0xfffff
    8000241a:	874080e7          	jalr	-1932(ra) # 80000c8a <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    8000241e:	1a848493          	addi	s1,s1,424
    80002422:	03248663          	beq	s1,s2,8000244e <wakeup+0x64>
    if(p != myproc()){
    80002426:	fffff097          	auipc	ra,0xfffff
    8000242a:	586080e7          	jalr	1414(ra) # 800019ac <myproc>
    8000242e:	fea488e3          	beq	s1,a0,8000241e <wakeup+0x34>
      acquire(&p->lock);
    80002432:	8526                	mv	a0,s1
    80002434:	ffffe097          	auipc	ra,0xffffe
    80002438:	7a2080e7          	jalr	1954(ra) # 80000bd6 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    8000243c:	4c9c                	lw	a5,24(s1)
    8000243e:	fd379be3          	bne	a5,s3,80002414 <wakeup+0x2a>
    80002442:	709c                	ld	a5,32(s1)
    80002444:	fd4798e3          	bne	a5,s4,80002414 <wakeup+0x2a>
        p->state = RUNNABLE;
    80002448:	0154ac23          	sw	s5,24(s1)
    8000244c:	b7e1                	j	80002414 <wakeup+0x2a>
    }
  }
}
    8000244e:	70e2                	ld	ra,56(sp)
    80002450:	7442                	ld	s0,48(sp)
    80002452:	74a2                	ld	s1,40(sp)
    80002454:	7902                	ld	s2,32(sp)
    80002456:	69e2                	ld	s3,24(sp)
    80002458:	6a42                	ld	s4,16(sp)
    8000245a:	6aa2                	ld	s5,8(sp)
    8000245c:	6121                	addi	sp,sp,64
    8000245e:	8082                	ret

0000000080002460 <reparent>:
{
    80002460:	7179                	addi	sp,sp,-48
    80002462:	f406                	sd	ra,40(sp)
    80002464:	f022                	sd	s0,32(sp)
    80002466:	ec26                	sd	s1,24(sp)
    80002468:	e84a                	sd	s2,16(sp)
    8000246a:	e44e                	sd	s3,8(sp)
    8000246c:	e052                	sd	s4,0(sp)
    8000246e:	1800                	addi	s0,sp,48
    80002470:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002472:	0000f497          	auipc	s1,0xf
    80002476:	dde48493          	addi	s1,s1,-546 # 80011250 <proc>
      pp->parent = initproc;
    8000247a:	00006a17          	auipc	s4,0x6
    8000247e:	72ea0a13          	addi	s4,s4,1838 # 80008ba8 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002482:	00015997          	auipc	s3,0x15
    80002486:	7ce98993          	addi	s3,s3,1998 # 80017c50 <tickslock>
    8000248a:	a029                	j	80002494 <reparent+0x34>
    8000248c:	1a848493          	addi	s1,s1,424
    80002490:	01348d63          	beq	s1,s3,800024aa <reparent+0x4a>
    if(pp->parent == p){
    80002494:	7c9c                	ld	a5,56(s1)
    80002496:	ff279be3          	bne	a5,s2,8000248c <reparent+0x2c>
      pp->parent = initproc;
    8000249a:	000a3503          	ld	a0,0(s4)
    8000249e:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    800024a0:	00000097          	auipc	ra,0x0
    800024a4:	f4a080e7          	jalr	-182(ra) # 800023ea <wakeup>
    800024a8:	b7d5                	j	8000248c <reparent+0x2c>
}
    800024aa:	70a2                	ld	ra,40(sp)
    800024ac:	7402                	ld	s0,32(sp)
    800024ae:	64e2                	ld	s1,24(sp)
    800024b0:	6942                	ld	s2,16(sp)
    800024b2:	69a2                	ld	s3,8(sp)
    800024b4:	6a02                	ld	s4,0(sp)
    800024b6:	6145                	addi	sp,sp,48
    800024b8:	8082                	ret

00000000800024ba <exit>:
{
    800024ba:	7179                	addi	sp,sp,-48
    800024bc:	f406                	sd	ra,40(sp)
    800024be:	f022                	sd	s0,32(sp)
    800024c0:	ec26                	sd	s1,24(sp)
    800024c2:	e84a                	sd	s2,16(sp)
    800024c4:	e44e                	sd	s3,8(sp)
    800024c6:	e052                	sd	s4,0(sp)
    800024c8:	1800                	addi	s0,sp,48
    800024ca:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    800024cc:	fffff097          	auipc	ra,0xfffff
    800024d0:	4e0080e7          	jalr	1248(ra) # 800019ac <myproc>
    800024d4:	89aa                	mv	s3,a0
  if(p == initproc)
    800024d6:	00006797          	auipc	a5,0x6
    800024da:	6d27b783          	ld	a5,1746(a5) # 80008ba8 <initproc>
    800024de:	0d050493          	addi	s1,a0,208
    800024e2:	15050913          	addi	s2,a0,336
    800024e6:	02a79363          	bne	a5,a0,8000250c <exit+0x52>
    panic("init exiting");
    800024ea:	00006517          	auipc	a0,0x6
    800024ee:	d7650513          	addi	a0,a0,-650 # 80008260 <digits+0x220>
    800024f2:	ffffe097          	auipc	ra,0xffffe
    800024f6:	04e080e7          	jalr	78(ra) # 80000540 <panic>
      fileclose(f);
    800024fa:	00002097          	auipc	ra,0x2
    800024fe:	628080e7          	jalr	1576(ra) # 80004b22 <fileclose>
      p->ofile[fd] = 0;
    80002502:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    80002506:	04a1                	addi	s1,s1,8
    80002508:	01248563          	beq	s1,s2,80002512 <exit+0x58>
    if(p->ofile[fd]){
    8000250c:	6088                	ld	a0,0(s1)
    8000250e:	f575                	bnez	a0,800024fa <exit+0x40>
    80002510:	bfdd                	j	80002506 <exit+0x4c>
  begin_op();
    80002512:	00002097          	auipc	ra,0x2
    80002516:	148080e7          	jalr	328(ra) # 8000465a <begin_op>
  iput(p->cwd);
    8000251a:	1509b503          	ld	a0,336(s3)
    8000251e:	00002097          	auipc	ra,0x2
    80002522:	92a080e7          	jalr	-1750(ra) # 80003e48 <iput>
  end_op();
    80002526:	00002097          	auipc	ra,0x2
    8000252a:	1b2080e7          	jalr	434(ra) # 800046d8 <end_op>
  p->cwd = 0;
    8000252e:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    80002532:	0000f497          	auipc	s1,0xf
    80002536:	90648493          	addi	s1,s1,-1786 # 80010e38 <wait_lock>
    8000253a:	8526                	mv	a0,s1
    8000253c:	ffffe097          	auipc	ra,0xffffe
    80002540:	69a080e7          	jalr	1690(ra) # 80000bd6 <acquire>
  reparent(p);
    80002544:	854e                	mv	a0,s3
    80002546:	00000097          	auipc	ra,0x0
    8000254a:	f1a080e7          	jalr	-230(ra) # 80002460 <reparent>
  wakeup(p->parent);
    8000254e:	0389b503          	ld	a0,56(s3)
    80002552:	00000097          	auipc	ra,0x0
    80002556:	e98080e7          	jalr	-360(ra) # 800023ea <wakeup>
  acquire(&p->lock);
    8000255a:	854e                	mv	a0,s3
    8000255c:	ffffe097          	auipc	ra,0xffffe
    80002560:	67a080e7          	jalr	1658(ra) # 80000bd6 <acquire>
  p->xstate = status;
    80002564:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    80002568:	4795                	li	a5,5
    8000256a:	00f9ac23          	sw	a5,24(s3)
  p->etime = ticks;
    8000256e:	00006797          	auipc	a5,0x6
    80002572:	6427a783          	lw	a5,1602(a5) # 80008bb0 <ticks>
    80002576:	18f9a023          	sw	a5,384(s3)
  release(&wait_lock);
    8000257a:	8526                	mv	a0,s1
    8000257c:	ffffe097          	auipc	ra,0xffffe
    80002580:	70e080e7          	jalr	1806(ra) # 80000c8a <release>
  sched();
    80002584:	00000097          	auipc	ra,0x0
    80002588:	ba4080e7          	jalr	-1116(ra) # 80002128 <sched>
  panic("zombie exit");
    8000258c:	00006517          	auipc	a0,0x6
    80002590:	ce450513          	addi	a0,a0,-796 # 80008270 <digits+0x230>
    80002594:	ffffe097          	auipc	ra,0xffffe
    80002598:	fac080e7          	jalr	-84(ra) # 80000540 <panic>

000000008000259c <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    8000259c:	7179                	addi	sp,sp,-48
    8000259e:	f406                	sd	ra,40(sp)
    800025a0:	f022                	sd	s0,32(sp)
    800025a2:	ec26                	sd	s1,24(sp)
    800025a4:	e84a                	sd	s2,16(sp)
    800025a6:	e44e                	sd	s3,8(sp)
    800025a8:	1800                	addi	s0,sp,48
    800025aa:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    800025ac:	0000f497          	auipc	s1,0xf
    800025b0:	ca448493          	addi	s1,s1,-860 # 80011250 <proc>
    800025b4:	00015997          	auipc	s3,0x15
    800025b8:	69c98993          	addi	s3,s3,1692 # 80017c50 <tickslock>
    acquire(&p->lock);
    800025bc:	8526                	mv	a0,s1
    800025be:	ffffe097          	auipc	ra,0xffffe
    800025c2:	618080e7          	jalr	1560(ra) # 80000bd6 <acquire>
    if(p->pid == pid){
    800025c6:	589c                	lw	a5,48(s1)
    800025c8:	01278d63          	beq	a5,s2,800025e2 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    800025cc:	8526                	mv	a0,s1
    800025ce:	ffffe097          	auipc	ra,0xffffe
    800025d2:	6bc080e7          	jalr	1724(ra) # 80000c8a <release>
  for(p = proc; p < &proc[NPROC]; p++){
    800025d6:	1a848493          	addi	s1,s1,424
    800025da:	ff3491e3          	bne	s1,s3,800025bc <kill+0x20>
  }
  return -1;
    800025de:	557d                	li	a0,-1
    800025e0:	a829                	j	800025fa <kill+0x5e>
      p->killed = 1;
    800025e2:	4785                	li	a5,1
    800025e4:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    800025e6:	4c98                	lw	a4,24(s1)
    800025e8:	4789                	li	a5,2
    800025ea:	00f70f63          	beq	a4,a5,80002608 <kill+0x6c>
      release(&p->lock);
    800025ee:	8526                	mv	a0,s1
    800025f0:	ffffe097          	auipc	ra,0xffffe
    800025f4:	69a080e7          	jalr	1690(ra) # 80000c8a <release>
      return 0;
    800025f8:	4501                	li	a0,0
}
    800025fa:	70a2                	ld	ra,40(sp)
    800025fc:	7402                	ld	s0,32(sp)
    800025fe:	64e2                	ld	s1,24(sp)
    80002600:	6942                	ld	s2,16(sp)
    80002602:	69a2                	ld	s3,8(sp)
    80002604:	6145                	addi	sp,sp,48
    80002606:	8082                	ret
        p->state = RUNNABLE;
    80002608:	478d                	li	a5,3
    8000260a:	cc9c                	sw	a5,24(s1)
    8000260c:	b7cd                	j	800025ee <kill+0x52>

000000008000260e <setkilled>:

void
setkilled(struct proc *p)
{
    8000260e:	1101                	addi	sp,sp,-32
    80002610:	ec06                	sd	ra,24(sp)
    80002612:	e822                	sd	s0,16(sp)
    80002614:	e426                	sd	s1,8(sp)
    80002616:	1000                	addi	s0,sp,32
    80002618:	84aa                	mv	s1,a0
  acquire(&p->lock);
    8000261a:	ffffe097          	auipc	ra,0xffffe
    8000261e:	5bc080e7          	jalr	1468(ra) # 80000bd6 <acquire>
  p->killed = 1;
    80002622:	4785                	li	a5,1
    80002624:	d49c                	sw	a5,40(s1)
  release(&p->lock);
    80002626:	8526                	mv	a0,s1
    80002628:	ffffe097          	auipc	ra,0xffffe
    8000262c:	662080e7          	jalr	1634(ra) # 80000c8a <release>
}
    80002630:	60e2                	ld	ra,24(sp)
    80002632:	6442                	ld	s0,16(sp)
    80002634:	64a2                	ld	s1,8(sp)
    80002636:	6105                	addi	sp,sp,32
    80002638:	8082                	ret

000000008000263a <killed>:

int
killed(struct proc *p)
{
    8000263a:	1101                	addi	sp,sp,-32
    8000263c:	ec06                	sd	ra,24(sp)
    8000263e:	e822                	sd	s0,16(sp)
    80002640:	e426                	sd	s1,8(sp)
    80002642:	e04a                	sd	s2,0(sp)
    80002644:	1000                	addi	s0,sp,32
    80002646:	84aa                	mv	s1,a0
  int k;
  
  acquire(&p->lock);
    80002648:	ffffe097          	auipc	ra,0xffffe
    8000264c:	58e080e7          	jalr	1422(ra) # 80000bd6 <acquire>
  k = p->killed;
    80002650:	0284a903          	lw	s2,40(s1)
  release(&p->lock);
    80002654:	8526                	mv	a0,s1
    80002656:	ffffe097          	auipc	ra,0xffffe
    8000265a:	634080e7          	jalr	1588(ra) # 80000c8a <release>
  return k;
}
    8000265e:	854a                	mv	a0,s2
    80002660:	60e2                	ld	ra,24(sp)
    80002662:	6442                	ld	s0,16(sp)
    80002664:	64a2                	ld	s1,8(sp)
    80002666:	6902                	ld	s2,0(sp)
    80002668:	6105                	addi	sp,sp,32
    8000266a:	8082                	ret

000000008000266c <wait>:
{
    8000266c:	715d                	addi	sp,sp,-80
    8000266e:	e486                	sd	ra,72(sp)
    80002670:	e0a2                	sd	s0,64(sp)
    80002672:	fc26                	sd	s1,56(sp)
    80002674:	f84a                	sd	s2,48(sp)
    80002676:	f44e                	sd	s3,40(sp)
    80002678:	f052                	sd	s4,32(sp)
    8000267a:	ec56                	sd	s5,24(sp)
    8000267c:	e85a                	sd	s6,16(sp)
    8000267e:	e45e                	sd	s7,8(sp)
    80002680:	e062                	sd	s8,0(sp)
    80002682:	0880                	addi	s0,sp,80
    80002684:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    80002686:	fffff097          	auipc	ra,0xfffff
    8000268a:	326080e7          	jalr	806(ra) # 800019ac <myproc>
    8000268e:	892a                	mv	s2,a0
  acquire(&wait_lock);
    80002690:	0000e517          	auipc	a0,0xe
    80002694:	7a850513          	addi	a0,a0,1960 # 80010e38 <wait_lock>
    80002698:	ffffe097          	auipc	ra,0xffffe
    8000269c:	53e080e7          	jalr	1342(ra) # 80000bd6 <acquire>
    havekids = 0;
    800026a0:	4b81                	li	s7,0
        if(pp->state == ZOMBIE){
    800026a2:	4a15                	li	s4,5
        havekids = 1;
    800026a4:	4a85                	li	s5,1
    for(pp = proc; pp < &proc[NPROC]; pp++){
    800026a6:	00015997          	auipc	s3,0x15
    800026aa:	5aa98993          	addi	s3,s3,1450 # 80017c50 <tickslock>
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800026ae:	0000ec17          	auipc	s8,0xe
    800026b2:	78ac0c13          	addi	s8,s8,1930 # 80010e38 <wait_lock>
    havekids = 0;
    800026b6:	875e                	mv	a4,s7
    for(pp = proc; pp < &proc[NPROC]; pp++){
    800026b8:	0000f497          	auipc	s1,0xf
    800026bc:	b9848493          	addi	s1,s1,-1128 # 80011250 <proc>
    800026c0:	a0bd                	j	8000272e <wait+0xc2>
          pid = pp->pid;
    800026c2:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    800026c6:	000b0e63          	beqz	s6,800026e2 <wait+0x76>
    800026ca:	4691                	li	a3,4
    800026cc:	02c48613          	addi	a2,s1,44
    800026d0:	85da                	mv	a1,s6
    800026d2:	05093503          	ld	a0,80(s2)
    800026d6:	fffff097          	auipc	ra,0xfffff
    800026da:	f96080e7          	jalr	-106(ra) # 8000166c <copyout>
    800026de:	02054563          	bltz	a0,80002708 <wait+0x9c>
          freeproc(pp);
    800026e2:	8526                	mv	a0,s1
    800026e4:	fffff097          	auipc	ra,0xfffff
    800026e8:	47a080e7          	jalr	1146(ra) # 80001b5e <freeproc>
          release(&pp->lock);
    800026ec:	8526                	mv	a0,s1
    800026ee:	ffffe097          	auipc	ra,0xffffe
    800026f2:	59c080e7          	jalr	1436(ra) # 80000c8a <release>
          release(&wait_lock);
    800026f6:	0000e517          	auipc	a0,0xe
    800026fa:	74250513          	addi	a0,a0,1858 # 80010e38 <wait_lock>
    800026fe:	ffffe097          	auipc	ra,0xffffe
    80002702:	58c080e7          	jalr	1420(ra) # 80000c8a <release>
          return pid;
    80002706:	a0b5                	j	80002772 <wait+0x106>
            release(&pp->lock);
    80002708:	8526                	mv	a0,s1
    8000270a:	ffffe097          	auipc	ra,0xffffe
    8000270e:	580080e7          	jalr	1408(ra) # 80000c8a <release>
            release(&wait_lock);
    80002712:	0000e517          	auipc	a0,0xe
    80002716:	72650513          	addi	a0,a0,1830 # 80010e38 <wait_lock>
    8000271a:	ffffe097          	auipc	ra,0xffffe
    8000271e:	570080e7          	jalr	1392(ra) # 80000c8a <release>
            return -1;
    80002722:	59fd                	li	s3,-1
    80002724:	a0b9                	j	80002772 <wait+0x106>
    for(pp = proc; pp < &proc[NPROC]; pp++){
    80002726:	1a848493          	addi	s1,s1,424
    8000272a:	03348463          	beq	s1,s3,80002752 <wait+0xe6>
      if(pp->parent == p){
    8000272e:	7c9c                	ld	a5,56(s1)
    80002730:	ff279be3          	bne	a5,s2,80002726 <wait+0xba>
        acquire(&pp->lock);
    80002734:	8526                	mv	a0,s1
    80002736:	ffffe097          	auipc	ra,0xffffe
    8000273a:	4a0080e7          	jalr	1184(ra) # 80000bd6 <acquire>
        if(pp->state == ZOMBIE){
    8000273e:	4c9c                	lw	a5,24(s1)
    80002740:	f94781e3          	beq	a5,s4,800026c2 <wait+0x56>
        release(&pp->lock);
    80002744:	8526                	mv	a0,s1
    80002746:	ffffe097          	auipc	ra,0xffffe
    8000274a:	544080e7          	jalr	1348(ra) # 80000c8a <release>
        havekids = 1;
    8000274e:	8756                	mv	a4,s5
    80002750:	bfd9                	j	80002726 <wait+0xba>
    if(!havekids || killed(p)){
    80002752:	c719                	beqz	a4,80002760 <wait+0xf4>
    80002754:	854a                	mv	a0,s2
    80002756:	00000097          	auipc	ra,0x0
    8000275a:	ee4080e7          	jalr	-284(ra) # 8000263a <killed>
    8000275e:	c51d                	beqz	a0,8000278c <wait+0x120>
      release(&wait_lock);
    80002760:	0000e517          	auipc	a0,0xe
    80002764:	6d850513          	addi	a0,a0,1752 # 80010e38 <wait_lock>
    80002768:	ffffe097          	auipc	ra,0xffffe
    8000276c:	522080e7          	jalr	1314(ra) # 80000c8a <release>
      return -1;
    80002770:	59fd                	li	s3,-1
}
    80002772:	854e                	mv	a0,s3
    80002774:	60a6                	ld	ra,72(sp)
    80002776:	6406                	ld	s0,64(sp)
    80002778:	74e2                	ld	s1,56(sp)
    8000277a:	7942                	ld	s2,48(sp)
    8000277c:	79a2                	ld	s3,40(sp)
    8000277e:	7a02                	ld	s4,32(sp)
    80002780:	6ae2                	ld	s5,24(sp)
    80002782:	6b42                	ld	s6,16(sp)
    80002784:	6ba2                	ld	s7,8(sp)
    80002786:	6c02                	ld	s8,0(sp)
    80002788:	6161                	addi	sp,sp,80
    8000278a:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    8000278c:	85e2                	mv	a1,s8
    8000278e:	854a                	mv	a0,s2
    80002790:	00000097          	auipc	ra,0x0
    80002794:	aaa080e7          	jalr	-1366(ra) # 8000223a <sleep>
    havekids = 0;
    80002798:	bf39                	j	800026b6 <wait+0x4a>

000000008000279a <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    8000279a:	7179                	addi	sp,sp,-48
    8000279c:	f406                	sd	ra,40(sp)
    8000279e:	f022                	sd	s0,32(sp)
    800027a0:	ec26                	sd	s1,24(sp)
    800027a2:	e84a                	sd	s2,16(sp)
    800027a4:	e44e                	sd	s3,8(sp)
    800027a6:	e052                	sd	s4,0(sp)
    800027a8:	1800                	addi	s0,sp,48
    800027aa:	84aa                	mv	s1,a0
    800027ac:	892e                	mv	s2,a1
    800027ae:	89b2                	mv	s3,a2
    800027b0:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800027b2:	fffff097          	auipc	ra,0xfffff
    800027b6:	1fa080e7          	jalr	506(ra) # 800019ac <myproc>
  if(user_dst){
    800027ba:	c08d                	beqz	s1,800027dc <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    800027bc:	86d2                	mv	a3,s4
    800027be:	864e                	mv	a2,s3
    800027c0:	85ca                	mv	a1,s2
    800027c2:	6928                	ld	a0,80(a0)
    800027c4:	fffff097          	auipc	ra,0xfffff
    800027c8:	ea8080e7          	jalr	-344(ra) # 8000166c <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    800027cc:	70a2                	ld	ra,40(sp)
    800027ce:	7402                	ld	s0,32(sp)
    800027d0:	64e2                	ld	s1,24(sp)
    800027d2:	6942                	ld	s2,16(sp)
    800027d4:	69a2                	ld	s3,8(sp)
    800027d6:	6a02                	ld	s4,0(sp)
    800027d8:	6145                	addi	sp,sp,48
    800027da:	8082                	ret
    memmove((char *)dst, src, len);
    800027dc:	000a061b          	sext.w	a2,s4
    800027e0:	85ce                	mv	a1,s3
    800027e2:	854a                	mv	a0,s2
    800027e4:	ffffe097          	auipc	ra,0xffffe
    800027e8:	54a080e7          	jalr	1354(ra) # 80000d2e <memmove>
    return 0;
    800027ec:	8526                	mv	a0,s1
    800027ee:	bff9                	j	800027cc <either_copyout+0x32>

00000000800027f0 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    800027f0:	7179                	addi	sp,sp,-48
    800027f2:	f406                	sd	ra,40(sp)
    800027f4:	f022                	sd	s0,32(sp)
    800027f6:	ec26                	sd	s1,24(sp)
    800027f8:	e84a                	sd	s2,16(sp)
    800027fa:	e44e                	sd	s3,8(sp)
    800027fc:	e052                	sd	s4,0(sp)
    800027fe:	1800                	addi	s0,sp,48
    80002800:	892a                	mv	s2,a0
    80002802:	84ae                	mv	s1,a1
    80002804:	89b2                	mv	s3,a2
    80002806:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002808:	fffff097          	auipc	ra,0xfffff
    8000280c:	1a4080e7          	jalr	420(ra) # 800019ac <myproc>
  if(user_src){
    80002810:	c08d                	beqz	s1,80002832 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    80002812:	86d2                	mv	a3,s4
    80002814:	864e                	mv	a2,s3
    80002816:	85ca                	mv	a1,s2
    80002818:	6928                	ld	a0,80(a0)
    8000281a:	fffff097          	auipc	ra,0xfffff
    8000281e:	ede080e7          	jalr	-290(ra) # 800016f8 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    80002822:	70a2                	ld	ra,40(sp)
    80002824:	7402                	ld	s0,32(sp)
    80002826:	64e2                	ld	s1,24(sp)
    80002828:	6942                	ld	s2,16(sp)
    8000282a:	69a2                	ld	s3,8(sp)
    8000282c:	6a02                	ld	s4,0(sp)
    8000282e:	6145                	addi	sp,sp,48
    80002830:	8082                	ret
    memmove(dst, (char*)src, len);
    80002832:	000a061b          	sext.w	a2,s4
    80002836:	85ce                	mv	a1,s3
    80002838:	854a                	mv	a0,s2
    8000283a:	ffffe097          	auipc	ra,0xffffe
    8000283e:	4f4080e7          	jalr	1268(ra) # 80000d2e <memmove>
    return 0;
    80002842:	8526                	mv	a0,s1
    80002844:	bff9                	j	80002822 <either_copyin+0x32>

0000000080002846 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    80002846:	7119                	addi	sp,sp,-128
    80002848:	fc86                	sd	ra,120(sp)
    8000284a:	f8a2                	sd	s0,112(sp)
    8000284c:	f4a6                	sd	s1,104(sp)
    8000284e:	f0ca                	sd	s2,96(sp)
    80002850:	ecce                	sd	s3,88(sp)
    80002852:	e8d2                	sd	s4,80(sp)
    80002854:	e4d6                	sd	s5,72(sp)
    80002856:	e0da                	sd	s6,64(sp)
    80002858:	fc5e                	sd	s7,56(sp)
    8000285a:	f862                	sd	s8,48(sp)
    8000285c:	f466                	sd	s9,40(sp)
    8000285e:	0100                	addi	s0,sp,128
  #endif	
  #ifdef PBS	
    printf("\nPID\tPriority\tState\trtime\twtime\tnrun");	
  #endif	
  #ifdef MLFQ	
    printf("\nPID\tPriority\tState\trtime\twtime\tnrun\tq0\tq1\tq2\tq3\tq4");	
    80002860:	00006517          	auipc	a0,0x6
    80002864:	a2850513          	addi	a0,a0,-1496 # 80008288 <digits+0x248>
    80002868:	ffffe097          	auipc	ra,0xffffe
    8000286c:	d22080e7          	jalr	-734(ra) # 8000058a <printf>
  #endif

  printf("\n");
    80002870:	00006517          	auipc	a0,0x6
    80002874:	85850513          	addi	a0,a0,-1960 # 800080c8 <digits+0x88>
    80002878:	ffffe097          	auipc	ra,0xffffe
    8000287c:	d12080e7          	jalr	-750(ra) # 8000058a <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002880:	0000f497          	auipc	s1,0xf
    80002884:	9d048493          	addi	s1,s1,-1584 # 80011250 <proc>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002888:	4915                	li	s2,5
      state = states[p->state];
    else
      state = "???";
    8000288a:	00006b97          	auipc	s7,0x6
    8000288e:	9f6b8b93          	addi	s7,s7,-1546 # 80008280 <digits+0x240>
      if (end_time == 0)	
        end_time = ticks;	
      int current_queue = p->current_queue;	
      if (p->state == ZOMBIE)	
        current_queue = -1;	
      printf("%d\t%d\t\t%s\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d", p->pid, current_queue, state, p->rtime, end_time - p->ctime - p->rtime, p->no_of_times_scheduled, p->queue_ticks[0], p->queue_ticks[1], p->queue_ticks[2], p->queue_ticks[3], p->queue_ticks[4]);	
    80002892:	00006a97          	auipc	s5,0x6
    80002896:	a2ea8a93          	addi	s5,s5,-1490 # 800082c0 <digits+0x280>
      printf("\n");	
    8000289a:	00006a17          	auipc	s4,0x6
    8000289e:	82ea0a13          	addi	s4,s4,-2002 # 800080c8 <digits+0x88>
        current_queue = -1;	
    800028a2:	5b7d                	li	s6,-1
        end_time = ticks;	
    800028a4:	00006c97          	auipc	s9,0x6
    800028a8:	30cc8c93          	addi	s9,s9,780 # 80008bb0 <ticks>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800028ac:	00006c17          	auipc	s8,0x6
    800028b0:	a6cc0c13          	addi	s8,s8,-1428 # 80008318 <states.0>
  for(p = proc; p < &proc[NPROC]; p++){
    800028b4:	00015997          	auipc	s3,0x15
    800028b8:	39c98993          	addi	s3,s3,924 # 80017c50 <tickslock>
    800028bc:	a08d                	j	8000291e <procdump+0xd8>
      state = "???";
    800028be:	86de                	mv	a3,s7
    800028c0:	a895                	j	80002934 <procdump+0xee>
    800028c2:	86de                	mv	a3,s7
        end_time = ticks;	
    800028c4:	000ca583          	lw	a1,0(s9)
        current_queue = -1;	
    800028c8:	865a                	mv	a2,s6
      if (p->state == ZOMBIE)	
    800028ca:	01270463          	beq	a4,s2,800028d2 <procdump+0x8c>
      int current_queue = p->current_queue;	
    800028ce:	1a04a603          	lw	a2,416(s1)
      printf("%d\t%d\t\t%s\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d", p->pid, current_queue, state, p->rtime, end_time - p->ctime - p->rtime, p->no_of_times_scheduled, p->queue_ticks[0], p->queue_ticks[1], p->queue_ticks[2], p->queue_ticks[3], p->queue_ticks[4]);	
    800028d2:	1784a703          	lw	a4,376(s1)
    800028d6:	17c4a783          	lw	a5,380(s1)
    800028da:	9fb9                	addw	a5,a5,a4
    800028dc:	19c4a503          	lw	a0,412(s1)
    800028e0:	ec2a                	sd	a0,24(sp)
    800028e2:	1984a503          	lw	a0,408(s1)
    800028e6:	e82a                	sd	a0,16(sp)
    800028e8:	1944a503          	lw	a0,404(s1)
    800028ec:	e42a                	sd	a0,8(sp)
    800028ee:	1904a503          	lw	a0,400(s1)
    800028f2:	e02a                	sd	a0,0(sp)
    800028f4:	18c4a883          	lw	a7,396(s1)
    800028f8:	1844a803          	lw	a6,388(s1)
    800028fc:	40f587bb          	subw	a5,a1,a5
    80002900:	588c                	lw	a1,48(s1)
    80002902:	8556                	mv	a0,s5
    80002904:	ffffe097          	auipc	ra,0xffffe
    80002908:	c86080e7          	jalr	-890(ra) # 8000058a <printf>
      printf("\n");	
    8000290c:	8552                	mv	a0,s4
    8000290e:	ffffe097          	auipc	ra,0xffffe
    80002912:	c7c080e7          	jalr	-900(ra) # 8000058a <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002916:	1a848493          	addi	s1,s1,424
    8000291a:	03348863          	beq	s1,s3,8000294a <procdump+0x104>
    if(p->state == UNUSED)
    8000291e:	4c98                	lw	a4,24(s1)
    80002920:	db7d                	beqz	a4,80002916 <procdump+0xd0>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002922:	00e96d63          	bltu	s2,a4,8000293c <procdump+0xf6>
    80002926:	02071693          	slli	a3,a4,0x20
    8000292a:	01d6d793          	srli	a5,a3,0x1d
    8000292e:	97e2                	add	a5,a5,s8
    80002930:	6394                	ld	a3,0(a5)
    80002932:	d6d1                	beqz	a3,800028be <procdump+0x78>
      int end_time = p->etime;	
    80002934:	1804a583          	lw	a1,384(s1)
      if (end_time == 0)	
    80002938:	f9c1                	bnez	a1,800028c8 <procdump+0x82>
    8000293a:	b769                	j	800028c4 <procdump+0x7e>
      int end_time = p->etime;	
    8000293c:	1804a583          	lw	a1,384(s1)
      if (end_time == 0)	
    80002940:	d1c9                	beqz	a1,800028c2 <procdump+0x7c>
      int current_queue = p->current_queue;	
    80002942:	1a04a603          	lw	a2,416(s1)
      state = "???";
    80002946:	86de                	mv	a3,s7
    80002948:	b769                	j	800028d2 <procdump+0x8c>
    #endif
  }
}
    8000294a:	70e6                	ld	ra,120(sp)
    8000294c:	7446                	ld	s0,112(sp)
    8000294e:	74a6                	ld	s1,104(sp)
    80002950:	7906                	ld	s2,96(sp)
    80002952:	69e6                	ld	s3,88(sp)
    80002954:	6a46                	ld	s4,80(sp)
    80002956:	6aa6                	ld	s5,72(sp)
    80002958:	6b06                	ld	s6,64(sp)
    8000295a:	7be2                	ld	s7,56(sp)
    8000295c:	7c42                	ld	s8,48(sp)
    8000295e:	7ca2                	ld	s9,40(sp)
    80002960:	6109                	addi	sp,sp,128
    80002962:	8082                	ret

0000000080002964 <swtch>:
    80002964:	00153023          	sd	ra,0(a0)
    80002968:	00253423          	sd	sp,8(a0)
    8000296c:	e900                	sd	s0,16(a0)
    8000296e:	ed04                	sd	s1,24(a0)
    80002970:	03253023          	sd	s2,32(a0)
    80002974:	03353423          	sd	s3,40(a0)
    80002978:	03453823          	sd	s4,48(a0)
    8000297c:	03553c23          	sd	s5,56(a0)
    80002980:	05653023          	sd	s6,64(a0)
    80002984:	05753423          	sd	s7,72(a0)
    80002988:	05853823          	sd	s8,80(a0)
    8000298c:	05953c23          	sd	s9,88(a0)
    80002990:	07a53023          	sd	s10,96(a0)
    80002994:	07b53423          	sd	s11,104(a0)
    80002998:	0005b083          	ld	ra,0(a1)
    8000299c:	0085b103          	ld	sp,8(a1)
    800029a0:	6980                	ld	s0,16(a1)
    800029a2:	6d84                	ld	s1,24(a1)
    800029a4:	0205b903          	ld	s2,32(a1)
    800029a8:	0285b983          	ld	s3,40(a1)
    800029ac:	0305ba03          	ld	s4,48(a1)
    800029b0:	0385ba83          	ld	s5,56(a1)
    800029b4:	0405bb03          	ld	s6,64(a1)
    800029b8:	0485bb83          	ld	s7,72(a1)
    800029bc:	0505bc03          	ld	s8,80(a1)
    800029c0:	0585bc83          	ld	s9,88(a1)
    800029c4:	0605bd03          	ld	s10,96(a1)
    800029c8:	0685bd83          	ld	s11,104(a1)
    800029cc:	8082                	ret

00000000800029ce <trapinit>:

extern int devintr();

void
trapinit(void)
{
    800029ce:	1141                	addi	sp,sp,-16
    800029d0:	e406                	sd	ra,8(sp)
    800029d2:	e022                	sd	s0,0(sp)
    800029d4:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    800029d6:	00006597          	auipc	a1,0x6
    800029da:	97258593          	addi	a1,a1,-1678 # 80008348 <states.0+0x30>
    800029de:	00015517          	auipc	a0,0x15
    800029e2:	27250513          	addi	a0,a0,626 # 80017c50 <tickslock>
    800029e6:	ffffe097          	auipc	ra,0xffffe
    800029ea:	160080e7          	jalr	352(ra) # 80000b46 <initlock>
}
    800029ee:	60a2                	ld	ra,8(sp)
    800029f0:	6402                	ld	s0,0(sp)
    800029f2:	0141                	addi	sp,sp,16
    800029f4:	8082                	ret

00000000800029f6 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    800029f6:	1141                	addi	sp,sp,-16
    800029f8:	e422                	sd	s0,8(sp)
    800029fa:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    800029fc:	00003797          	auipc	a5,0x3
    80002a00:	77478793          	addi	a5,a5,1908 # 80006170 <kernelvec>
    80002a04:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002a08:	6422                	ld	s0,8(sp)
    80002a0a:	0141                	addi	sp,sp,16
    80002a0c:	8082                	ret

0000000080002a0e <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002a0e:	1141                	addi	sp,sp,-16
    80002a10:	e406                	sd	ra,8(sp)
    80002a12:	e022                	sd	s0,0(sp)
    80002a14:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002a16:	fffff097          	auipc	ra,0xfffff
    80002a1a:	f96080e7          	jalr	-106(ra) # 800019ac <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a1e:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002a22:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002a24:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    80002a28:	00004697          	auipc	a3,0x4
    80002a2c:	5d868693          	addi	a3,a3,1496 # 80007000 <_trampoline>
    80002a30:	00004717          	auipc	a4,0x4
    80002a34:	5d070713          	addi	a4,a4,1488 # 80007000 <_trampoline>
    80002a38:	8f15                	sub	a4,a4,a3
    80002a3a:	040007b7          	lui	a5,0x4000
    80002a3e:	17fd                	addi	a5,a5,-1 # 3ffffff <_entry-0x7c000001>
    80002a40:	07b2                	slli	a5,a5,0xc
    80002a42:	973e                	add	a4,a4,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002a44:	10571073          	csrw	stvec,a4
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002a48:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002a4a:	18002673          	csrr	a2,satp
    80002a4e:	e310                	sd	a2,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002a50:	6d30                	ld	a2,88(a0)
    80002a52:	6138                	ld	a4,64(a0)
    80002a54:	6585                	lui	a1,0x1
    80002a56:	972e                	add	a4,a4,a1
    80002a58:	e618                	sd	a4,8(a2)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002a5a:	6d38                	ld	a4,88(a0)
    80002a5c:	00000617          	auipc	a2,0x0
    80002a60:	13e60613          	addi	a2,a2,318 # 80002b9a <usertrap>
    80002a64:	eb10                	sd	a2,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002a66:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002a68:	8612                	mv	a2,tp
    80002a6a:	f310                	sd	a2,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a6c:	10002773          	csrr	a4,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002a70:	eff77713          	andi	a4,a4,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002a74:	02076713          	ori	a4,a4,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002a78:	10071073          	csrw	sstatus,a4
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002a7c:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002a7e:	6f18                	ld	a4,24(a4)
    80002a80:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002a84:	6928                	ld	a0,80(a0)
    80002a86:	8131                	srli	a0,a0,0xc

  // jump to userret in trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    80002a88:	00004717          	auipc	a4,0x4
    80002a8c:	61470713          	addi	a4,a4,1556 # 8000709c <userret>
    80002a90:	8f15                	sub	a4,a4,a3
    80002a92:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    80002a94:	577d                	li	a4,-1
    80002a96:	177e                	slli	a4,a4,0x3f
    80002a98:	8d59                	or	a0,a0,a4
    80002a9a:	9782                	jalr	a5
}
    80002a9c:	60a2                	ld	ra,8(sp)
    80002a9e:	6402                	ld	s0,0(sp)
    80002aa0:	0141                	addi	sp,sp,16
    80002aa2:	8082                	ret

0000000080002aa4 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002aa4:	1101                	addi	sp,sp,-32
    80002aa6:	ec06                	sd	ra,24(sp)
    80002aa8:	e822                	sd	s0,16(sp)
    80002aaa:	e426                	sd	s1,8(sp)
    80002aac:	e04a                	sd	s2,0(sp)
    80002aae:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002ab0:	00015917          	auipc	s2,0x15
    80002ab4:	1a090913          	addi	s2,s2,416 # 80017c50 <tickslock>
    80002ab8:	854a                	mv	a0,s2
    80002aba:	ffffe097          	auipc	ra,0xffffe
    80002abe:	11c080e7          	jalr	284(ra) # 80000bd6 <acquire>
  ticks++;
    80002ac2:	00006497          	auipc	s1,0x6
    80002ac6:	0ee48493          	addi	s1,s1,238 # 80008bb0 <ticks>
    80002aca:	409c                	lw	a5,0(s1)
    80002acc:	2785                	addiw	a5,a5,1
    80002ace:	c09c                	sw	a5,0(s1)
   update_time();
    80002ad0:	fffff097          	auipc	ra,0xfffff
    80002ad4:	412080e7          	jalr	1042(ra) # 80001ee2 <update_time>
  wakeup(&ticks);
    80002ad8:	8526                	mv	a0,s1
    80002ada:	00000097          	auipc	ra,0x0
    80002ade:	910080e7          	jalr	-1776(ra) # 800023ea <wakeup>
  release(&tickslock);
    80002ae2:	854a                	mv	a0,s2
    80002ae4:	ffffe097          	auipc	ra,0xffffe
    80002ae8:	1a6080e7          	jalr	422(ra) # 80000c8a <release>
}
    80002aec:	60e2                	ld	ra,24(sp)
    80002aee:	6442                	ld	s0,16(sp)
    80002af0:	64a2                	ld	s1,8(sp)
    80002af2:	6902                	ld	s2,0(sp)
    80002af4:	6105                	addi	sp,sp,32
    80002af6:	8082                	ret

0000000080002af8 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002af8:	1101                	addi	sp,sp,-32
    80002afa:	ec06                	sd	ra,24(sp)
    80002afc:	e822                	sd	s0,16(sp)
    80002afe:	e426                	sd	s1,8(sp)
    80002b00:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002b02:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002b06:	00074d63          	bltz	a4,80002b20 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002b0a:	57fd                	li	a5,-1
    80002b0c:	17fe                	slli	a5,a5,0x3f
    80002b0e:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002b10:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002b12:	06f70363          	beq	a4,a5,80002b78 <devintr+0x80>
  }
}
    80002b16:	60e2                	ld	ra,24(sp)
    80002b18:	6442                	ld	s0,16(sp)
    80002b1a:	64a2                	ld	s1,8(sp)
    80002b1c:	6105                	addi	sp,sp,32
    80002b1e:	8082                	ret
     (scause & 0xff) == 9){
    80002b20:	0ff77793          	zext.b	a5,a4
  if((scause & 0x8000000000000000L) &&
    80002b24:	46a5                	li	a3,9
    80002b26:	fed792e3          	bne	a5,a3,80002b0a <devintr+0x12>
    int irq = plic_claim();
    80002b2a:	00003097          	auipc	ra,0x3
    80002b2e:	74e080e7          	jalr	1870(ra) # 80006278 <plic_claim>
    80002b32:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002b34:	47a9                	li	a5,10
    80002b36:	02f50763          	beq	a0,a5,80002b64 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002b3a:	4785                	li	a5,1
    80002b3c:	02f50963          	beq	a0,a5,80002b6e <devintr+0x76>
    return 1;
    80002b40:	4505                	li	a0,1
    } else if(irq){
    80002b42:	d8f1                	beqz	s1,80002b16 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002b44:	85a6                	mv	a1,s1
    80002b46:	00006517          	auipc	a0,0x6
    80002b4a:	80a50513          	addi	a0,a0,-2038 # 80008350 <states.0+0x38>
    80002b4e:	ffffe097          	auipc	ra,0xffffe
    80002b52:	a3c080e7          	jalr	-1476(ra) # 8000058a <printf>
      plic_complete(irq);
    80002b56:	8526                	mv	a0,s1
    80002b58:	00003097          	auipc	ra,0x3
    80002b5c:	744080e7          	jalr	1860(ra) # 8000629c <plic_complete>
    return 1;
    80002b60:	4505                	li	a0,1
    80002b62:	bf55                	j	80002b16 <devintr+0x1e>
      uartintr();
    80002b64:	ffffe097          	auipc	ra,0xffffe
    80002b68:	e34080e7          	jalr	-460(ra) # 80000998 <uartintr>
    80002b6c:	b7ed                	j	80002b56 <devintr+0x5e>
      virtio_disk_intr();
    80002b6e:	00004097          	auipc	ra,0x4
    80002b72:	bf6080e7          	jalr	-1034(ra) # 80006764 <virtio_disk_intr>
    80002b76:	b7c5                	j	80002b56 <devintr+0x5e>
    if(cpuid() == 0){
    80002b78:	fffff097          	auipc	ra,0xfffff
    80002b7c:	e08080e7          	jalr	-504(ra) # 80001980 <cpuid>
    80002b80:	c901                	beqz	a0,80002b90 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002b82:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002b86:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002b88:	14479073          	csrw	sip,a5
    return 2;
    80002b8c:	4509                	li	a0,2
    80002b8e:	b761                	j	80002b16 <devintr+0x1e>
      clockintr();
    80002b90:	00000097          	auipc	ra,0x0
    80002b94:	f14080e7          	jalr	-236(ra) # 80002aa4 <clockintr>
    80002b98:	b7ed                	j	80002b82 <devintr+0x8a>

0000000080002b9a <usertrap>:
{
    80002b9a:	1101                	addi	sp,sp,-32
    80002b9c:	ec06                	sd	ra,24(sp)
    80002b9e:	e822                	sd	s0,16(sp)
    80002ba0:	e426                	sd	s1,8(sp)
    80002ba2:	e04a                	sd	s2,0(sp)
    80002ba4:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002ba6:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002baa:	1007f793          	andi	a5,a5,256
    80002bae:	e3b1                	bnez	a5,80002bf2 <usertrap+0x58>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002bb0:	00003797          	auipc	a5,0x3
    80002bb4:	5c078793          	addi	a5,a5,1472 # 80006170 <kernelvec>
    80002bb8:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002bbc:	fffff097          	auipc	ra,0xfffff
    80002bc0:	df0080e7          	jalr	-528(ra) # 800019ac <myproc>
    80002bc4:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002bc6:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002bc8:	14102773          	csrr	a4,sepc
    80002bcc:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002bce:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002bd2:	47a1                	li	a5,8
    80002bd4:	02f70763          	beq	a4,a5,80002c02 <usertrap+0x68>
  } else if((which_dev = devintr()) != 0){
    80002bd8:	00000097          	auipc	ra,0x0
    80002bdc:	f20080e7          	jalr	-224(ra) # 80002af8 <devintr>
    80002be0:	892a                	mv	s2,a0
    80002be2:	c151                	beqz	a0,80002c66 <usertrap+0xcc>
  if(killed(p))
    80002be4:	8526                	mv	a0,s1
    80002be6:	00000097          	auipc	ra,0x0
    80002bea:	a54080e7          	jalr	-1452(ra) # 8000263a <killed>
    80002bee:	c929                	beqz	a0,80002c40 <usertrap+0xa6>
    80002bf0:	a099                	j	80002c36 <usertrap+0x9c>
    panic("usertrap: not from user mode");
    80002bf2:	00005517          	auipc	a0,0x5
    80002bf6:	77e50513          	addi	a0,a0,1918 # 80008370 <states.0+0x58>
    80002bfa:	ffffe097          	auipc	ra,0xffffe
    80002bfe:	946080e7          	jalr	-1722(ra) # 80000540 <panic>
    if(killed(p))
    80002c02:	00000097          	auipc	ra,0x0
    80002c06:	a38080e7          	jalr	-1480(ra) # 8000263a <killed>
    80002c0a:	e921                	bnez	a0,80002c5a <usertrap+0xc0>
    p->trapframe->epc += 4;
    80002c0c:	6cb8                	ld	a4,88(s1)
    80002c0e:	6f1c                	ld	a5,24(a4)
    80002c10:	0791                	addi	a5,a5,4
    80002c12:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c14:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002c18:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002c1c:	10079073          	csrw	sstatus,a5
    syscall();
    80002c20:	00000097          	auipc	ra,0x0
    80002c24:	368080e7          	jalr	872(ra) # 80002f88 <syscall>
  if(killed(p))
    80002c28:	8526                	mv	a0,s1
    80002c2a:	00000097          	auipc	ra,0x0
    80002c2e:	a10080e7          	jalr	-1520(ra) # 8000263a <killed>
    80002c32:	c911                	beqz	a0,80002c46 <usertrap+0xac>
    80002c34:	4901                	li	s2,0
    exit(-1);
    80002c36:	557d                	li	a0,-1
    80002c38:	00000097          	auipc	ra,0x0
    80002c3c:	882080e7          	jalr	-1918(ra) # 800024ba <exit>
    if(which_dev == 2) {
    80002c40:	4789                	li	a5,2
    80002c42:	04f90f63          	beq	s2,a5,80002ca0 <usertrap+0x106>
  usertrapret();
    80002c46:	00000097          	auipc	ra,0x0
    80002c4a:	dc8080e7          	jalr	-568(ra) # 80002a0e <usertrapret>
}
    80002c4e:	60e2                	ld	ra,24(sp)
    80002c50:	6442                	ld	s0,16(sp)
    80002c52:	64a2                	ld	s1,8(sp)
    80002c54:	6902                	ld	s2,0(sp)
    80002c56:	6105                	addi	sp,sp,32
    80002c58:	8082                	ret
      exit(-1);
    80002c5a:	557d                	li	a0,-1
    80002c5c:	00000097          	auipc	ra,0x0
    80002c60:	85e080e7          	jalr	-1954(ra) # 800024ba <exit>
    80002c64:	b765                	j	80002c0c <usertrap+0x72>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002c66:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002c6a:	5890                	lw	a2,48(s1)
    80002c6c:	00005517          	auipc	a0,0x5
    80002c70:	72450513          	addi	a0,a0,1828 # 80008390 <states.0+0x78>
    80002c74:	ffffe097          	auipc	ra,0xffffe
    80002c78:	916080e7          	jalr	-1770(ra) # 8000058a <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002c7c:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002c80:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002c84:	00005517          	auipc	a0,0x5
    80002c88:	73c50513          	addi	a0,a0,1852 # 800083c0 <states.0+0xa8>
    80002c8c:	ffffe097          	auipc	ra,0xffffe
    80002c90:	8fe080e7          	jalr	-1794(ra) # 8000058a <printf>
    setkilled(p);
    80002c94:	8526                	mv	a0,s1
    80002c96:	00000097          	auipc	ra,0x0
    80002c9a:	978080e7          	jalr	-1672(ra) # 8000260e <setkilled>
    80002c9e:	b769                	j	80002c28 <usertrap+0x8e>
        struct proc *p = myproc();
    80002ca0:	fffff097          	auipc	ra,0xfffff
    80002ca4:	d0c080e7          	jalr	-756(ra) # 800019ac <myproc>
        if ((ticks - p->entry_time) > (1 << p->current_queue)) {
    80002ca8:	00006617          	auipc	a2,0x6
    80002cac:	f0862603          	lw	a2,-248(a2) # 80008bb0 <ticks>
    80002cb0:	18852783          	lw	a5,392(a0)
    80002cb4:	40f607bb          	subw	a5,a2,a5
    80002cb8:	0007859b          	sext.w	a1,a5
    80002cbc:	1a052683          	lw	a3,416(a0)
    80002cc0:	4705                	li	a4,1
    80002cc2:	00d7173b          	sllw	a4,a4,a3
    80002cc6:	f8b770e3          	bgeu	a4,a1,80002c46 <usertrap+0xac>
          p->queue_ticks[p->current_queue] += (ticks - p->entry_time);
    80002cca:	02069593          	slli	a1,a3,0x20
    80002cce:	01e5d713          	srli	a4,a1,0x1e
    80002cd2:	972a                	add	a4,a4,a0
    80002cd4:	18c72583          	lw	a1,396(a4)
    80002cd8:	9fad                	addw	a5,a5,a1
    80002cda:	18f72623          	sw	a5,396(a4)
          if (p->current_queue < 4)
    80002cde:	478d                	li	a5,3
    80002ce0:	00d7e563          	bltu	a5,a3,80002cea <usertrap+0x150>
            p->current_queue++;
    80002ce4:	2685                	addiw	a3,a3,1
    80002ce6:	1ad52023          	sw	a3,416(a0)
          p->entry_time = ticks;
    80002cea:	18c52423          	sw	a2,392(a0)
          yield();
    80002cee:	fffff097          	auipc	ra,0xfffff
    80002cf2:	510080e7          	jalr	1296(ra) # 800021fe <yield>
    80002cf6:	bf81                	j	80002c46 <usertrap+0xac>

0000000080002cf8 <kerneltrap>:
{
    80002cf8:	7179                	addi	sp,sp,-48
    80002cfa:	f406                	sd	ra,40(sp)
    80002cfc:	f022                	sd	s0,32(sp)
    80002cfe:	ec26                	sd	s1,24(sp)
    80002d00:	e84a                	sd	s2,16(sp)
    80002d02:	e44e                	sd	s3,8(sp)
    80002d04:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002d06:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002d0a:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002d0e:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002d12:	1004f793          	andi	a5,s1,256
    80002d16:	cb85                	beqz	a5,80002d46 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002d18:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002d1c:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002d1e:	ef85                	bnez	a5,80002d56 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002d20:	00000097          	auipc	ra,0x0
    80002d24:	dd8080e7          	jalr	-552(ra) # 80002af8 <devintr>
    80002d28:	cd1d                	beqz	a0,80002d66 <kerneltrap+0x6e>
    if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING) {
    80002d2a:	4789                	li	a5,2
    80002d2c:	06f50a63          	beq	a0,a5,80002da0 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002d30:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002d34:	10049073          	csrw	sstatus,s1
}
    80002d38:	70a2                	ld	ra,40(sp)
    80002d3a:	7402                	ld	s0,32(sp)
    80002d3c:	64e2                	ld	s1,24(sp)
    80002d3e:	6942                	ld	s2,16(sp)
    80002d40:	69a2                	ld	s3,8(sp)
    80002d42:	6145                	addi	sp,sp,48
    80002d44:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002d46:	00005517          	auipc	a0,0x5
    80002d4a:	69a50513          	addi	a0,a0,1690 # 800083e0 <states.0+0xc8>
    80002d4e:	ffffd097          	auipc	ra,0xffffd
    80002d52:	7f2080e7          	jalr	2034(ra) # 80000540 <panic>
    panic("kerneltrap: interrupts enabled");
    80002d56:	00005517          	auipc	a0,0x5
    80002d5a:	6b250513          	addi	a0,a0,1714 # 80008408 <states.0+0xf0>
    80002d5e:	ffffd097          	auipc	ra,0xffffd
    80002d62:	7e2080e7          	jalr	2018(ra) # 80000540 <panic>
    printf("scause %p\n", scause);
    80002d66:	85ce                	mv	a1,s3
    80002d68:	00005517          	auipc	a0,0x5
    80002d6c:	6c050513          	addi	a0,a0,1728 # 80008428 <states.0+0x110>
    80002d70:	ffffe097          	auipc	ra,0xffffe
    80002d74:	81a080e7          	jalr	-2022(ra) # 8000058a <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002d78:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002d7c:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002d80:	00005517          	auipc	a0,0x5
    80002d84:	6b850513          	addi	a0,a0,1720 # 80008438 <states.0+0x120>
    80002d88:	ffffe097          	auipc	ra,0xffffe
    80002d8c:	802080e7          	jalr	-2046(ra) # 8000058a <printf>
    panic("kerneltrap");
    80002d90:	00005517          	auipc	a0,0x5
    80002d94:	6c050513          	addi	a0,a0,1728 # 80008450 <states.0+0x138>
    80002d98:	ffffd097          	auipc	ra,0xffffd
    80002d9c:	7a8080e7          	jalr	1960(ra) # 80000540 <panic>
    if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING) {
    80002da0:	fffff097          	auipc	ra,0xfffff
    80002da4:	c0c080e7          	jalr	-1012(ra) # 800019ac <myproc>
    80002da8:	d541                	beqz	a0,80002d30 <kerneltrap+0x38>
    80002daa:	fffff097          	auipc	ra,0xfffff
    80002dae:	c02080e7          	jalr	-1022(ra) # 800019ac <myproc>
    80002db2:	4d18                	lw	a4,24(a0)
    80002db4:	4791                	li	a5,4
    80002db6:	f6f71de3          	bne	a4,a5,80002d30 <kerneltrap+0x38>
        struct proc *p = myproc();
    80002dba:	fffff097          	auipc	ra,0xfffff
    80002dbe:	bf2080e7          	jalr	-1038(ra) # 800019ac <myproc>
        if ((ticks - p->entry_time) > (1 << p->current_queue)) {
    80002dc2:	00006617          	auipc	a2,0x6
    80002dc6:	dee62603          	lw	a2,-530(a2) # 80008bb0 <ticks>
    80002dca:	18852783          	lw	a5,392(a0)
    80002dce:	40f607bb          	subw	a5,a2,a5
    80002dd2:	0007859b          	sext.w	a1,a5
    80002dd6:	1a052683          	lw	a3,416(a0)
    80002dda:	4705                	li	a4,1
    80002ddc:	00d7173b          	sllw	a4,a4,a3
    80002de0:	f4b778e3          	bgeu	a4,a1,80002d30 <kerneltrap+0x38>
          p->queue_ticks[p->current_queue] += (ticks - p->entry_time);
    80002de4:	02069593          	slli	a1,a3,0x20
    80002de8:	01e5d713          	srli	a4,a1,0x1e
    80002dec:	972a                	add	a4,a4,a0
    80002dee:	18c72583          	lw	a1,396(a4)
    80002df2:	9fad                	addw	a5,a5,a1
    80002df4:	18f72623          	sw	a5,396(a4)
          if (p->current_queue < 4)
    80002df8:	478d                	li	a5,3
    80002dfa:	00d7e563          	bltu	a5,a3,80002e04 <kerneltrap+0x10c>
            p->current_queue++;
    80002dfe:	2685                	addiw	a3,a3,1
    80002e00:	1ad52023          	sw	a3,416(a0)
          p->entry_time = ticks;
    80002e04:	18c52423          	sw	a2,392(a0)
          yield();
    80002e08:	fffff097          	auipc	ra,0xfffff
    80002e0c:	3f6080e7          	jalr	1014(ra) # 800021fe <yield>
    80002e10:	b705                	j	80002d30 <kerneltrap+0x38>

0000000080002e12 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002e12:	1101                	addi	sp,sp,-32
    80002e14:	ec06                	sd	ra,24(sp)
    80002e16:	e822                	sd	s0,16(sp)
    80002e18:	e426                	sd	s1,8(sp)
    80002e1a:	1000                	addi	s0,sp,32
    80002e1c:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002e1e:	fffff097          	auipc	ra,0xfffff
    80002e22:	b8e080e7          	jalr	-1138(ra) # 800019ac <myproc>
  switch (n) {
    80002e26:	4795                	li	a5,5
    80002e28:	0497e163          	bltu	a5,s1,80002e6a <argraw+0x58>
    80002e2c:	048a                	slli	s1,s1,0x2
    80002e2e:	00005717          	auipc	a4,0x5
    80002e32:	79a70713          	addi	a4,a4,1946 # 800085c8 <states.0+0x2b0>
    80002e36:	94ba                	add	s1,s1,a4
    80002e38:	409c                	lw	a5,0(s1)
    80002e3a:	97ba                	add	a5,a5,a4
    80002e3c:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002e3e:	6d3c                	ld	a5,88(a0)
    80002e40:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002e42:	60e2                	ld	ra,24(sp)
    80002e44:	6442                	ld	s0,16(sp)
    80002e46:	64a2                	ld	s1,8(sp)
    80002e48:	6105                	addi	sp,sp,32
    80002e4a:	8082                	ret
    return p->trapframe->a1;
    80002e4c:	6d3c                	ld	a5,88(a0)
    80002e4e:	7fa8                	ld	a0,120(a5)
    80002e50:	bfcd                	j	80002e42 <argraw+0x30>
    return p->trapframe->a2;
    80002e52:	6d3c                	ld	a5,88(a0)
    80002e54:	63c8                	ld	a0,128(a5)
    80002e56:	b7f5                	j	80002e42 <argraw+0x30>
    return p->trapframe->a3;
    80002e58:	6d3c                	ld	a5,88(a0)
    80002e5a:	67c8                	ld	a0,136(a5)
    80002e5c:	b7dd                	j	80002e42 <argraw+0x30>
    return p->trapframe->a4;
    80002e5e:	6d3c                	ld	a5,88(a0)
    80002e60:	6bc8                	ld	a0,144(a5)
    80002e62:	b7c5                	j	80002e42 <argraw+0x30>
    return p->trapframe->a5;
    80002e64:	6d3c                	ld	a5,88(a0)
    80002e66:	6fc8                	ld	a0,152(a5)
    80002e68:	bfe9                	j	80002e42 <argraw+0x30>
  panic("argraw");
    80002e6a:	00005517          	auipc	a0,0x5
    80002e6e:	5f650513          	addi	a0,a0,1526 # 80008460 <states.0+0x148>
    80002e72:	ffffd097          	auipc	ra,0xffffd
    80002e76:	6ce080e7          	jalr	1742(ra) # 80000540 <panic>

0000000080002e7a <fetchaddr>:
{
    80002e7a:	1101                	addi	sp,sp,-32
    80002e7c:	ec06                	sd	ra,24(sp)
    80002e7e:	e822                	sd	s0,16(sp)
    80002e80:	e426                	sd	s1,8(sp)
    80002e82:	e04a                	sd	s2,0(sp)
    80002e84:	1000                	addi	s0,sp,32
    80002e86:	84aa                	mv	s1,a0
    80002e88:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002e8a:	fffff097          	auipc	ra,0xfffff
    80002e8e:	b22080e7          	jalr	-1246(ra) # 800019ac <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002e92:	653c                	ld	a5,72(a0)
    80002e94:	02f4f863          	bgeu	s1,a5,80002ec4 <fetchaddr+0x4a>
    80002e98:	00848713          	addi	a4,s1,8
    80002e9c:	02e7e663          	bltu	a5,a4,80002ec8 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002ea0:	46a1                	li	a3,8
    80002ea2:	8626                	mv	a2,s1
    80002ea4:	85ca                	mv	a1,s2
    80002ea6:	6928                	ld	a0,80(a0)
    80002ea8:	fffff097          	auipc	ra,0xfffff
    80002eac:	850080e7          	jalr	-1968(ra) # 800016f8 <copyin>
    80002eb0:	00a03533          	snez	a0,a0
    80002eb4:	40a00533          	neg	a0,a0
}
    80002eb8:	60e2                	ld	ra,24(sp)
    80002eba:	6442                	ld	s0,16(sp)
    80002ebc:	64a2                	ld	s1,8(sp)
    80002ebe:	6902                	ld	s2,0(sp)
    80002ec0:	6105                	addi	sp,sp,32
    80002ec2:	8082                	ret
    return -1;
    80002ec4:	557d                	li	a0,-1
    80002ec6:	bfcd                	j	80002eb8 <fetchaddr+0x3e>
    80002ec8:	557d                	li	a0,-1
    80002eca:	b7fd                	j	80002eb8 <fetchaddr+0x3e>

0000000080002ecc <fetchstr>:
{
    80002ecc:	7179                	addi	sp,sp,-48
    80002ece:	f406                	sd	ra,40(sp)
    80002ed0:	f022                	sd	s0,32(sp)
    80002ed2:	ec26                	sd	s1,24(sp)
    80002ed4:	e84a                	sd	s2,16(sp)
    80002ed6:	e44e                	sd	s3,8(sp)
    80002ed8:	1800                	addi	s0,sp,48
    80002eda:	892a                	mv	s2,a0
    80002edc:	84ae                	mv	s1,a1
    80002ede:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002ee0:	fffff097          	auipc	ra,0xfffff
    80002ee4:	acc080e7          	jalr	-1332(ra) # 800019ac <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002ee8:	86ce                	mv	a3,s3
    80002eea:	864a                	mv	a2,s2
    80002eec:	85a6                	mv	a1,s1
    80002eee:	6928                	ld	a0,80(a0)
    80002ef0:	fffff097          	auipc	ra,0xfffff
    80002ef4:	896080e7          	jalr	-1898(ra) # 80001786 <copyinstr>
  if(err < 0)
    80002ef8:	00054763          	bltz	a0,80002f06 <fetchstr+0x3a>
  return strlen(buf);
    80002efc:	8526                	mv	a0,s1
    80002efe:	ffffe097          	auipc	ra,0xffffe
    80002f02:	f50080e7          	jalr	-176(ra) # 80000e4e <strlen>
}
    80002f06:	70a2                	ld	ra,40(sp)
    80002f08:	7402                	ld	s0,32(sp)
    80002f0a:	64e2                	ld	s1,24(sp)
    80002f0c:	6942                	ld	s2,16(sp)
    80002f0e:	69a2                	ld	s3,8(sp)
    80002f10:	6145                	addi	sp,sp,48
    80002f12:	8082                	ret

0000000080002f14 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002f14:	1101                	addi	sp,sp,-32
    80002f16:	ec06                	sd	ra,24(sp)
    80002f18:	e822                	sd	s0,16(sp)
    80002f1a:	e426                	sd	s1,8(sp)
    80002f1c:	1000                	addi	s0,sp,32
    80002f1e:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002f20:	00000097          	auipc	ra,0x0
    80002f24:	ef2080e7          	jalr	-270(ra) # 80002e12 <argraw>
    80002f28:	c088                	sw	a0,0(s1)
  return 0;
}
    80002f2a:	4501                	li	a0,0
    80002f2c:	60e2                	ld	ra,24(sp)
    80002f2e:	6442                	ld	s0,16(sp)
    80002f30:	64a2                	ld	s1,8(sp)
    80002f32:	6105                	addi	sp,sp,32
    80002f34:	8082                	ret

0000000080002f36 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002f36:	1101                	addi	sp,sp,-32
    80002f38:	ec06                	sd	ra,24(sp)
    80002f3a:	e822                	sd	s0,16(sp)
    80002f3c:	e426                	sd	s1,8(sp)
    80002f3e:	1000                	addi	s0,sp,32
    80002f40:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002f42:	00000097          	auipc	ra,0x0
    80002f46:	ed0080e7          	jalr	-304(ra) # 80002e12 <argraw>
    80002f4a:	e088                	sd	a0,0(s1)
  return 0;
}
    80002f4c:	4501                	li	a0,0
    80002f4e:	60e2                	ld	ra,24(sp)
    80002f50:	6442                	ld	s0,16(sp)
    80002f52:	64a2                	ld	s1,8(sp)
    80002f54:	6105                	addi	sp,sp,32
    80002f56:	8082                	ret

0000000080002f58 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002f58:	1101                	addi	sp,sp,-32
    80002f5a:	ec06                	sd	ra,24(sp)
    80002f5c:	e822                	sd	s0,16(sp)
    80002f5e:	e426                	sd	s1,8(sp)
    80002f60:	e04a                	sd	s2,0(sp)
    80002f62:	1000                	addi	s0,sp,32
    80002f64:	84ae                	mv	s1,a1
    80002f66:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002f68:	00000097          	auipc	ra,0x0
    80002f6c:	eaa080e7          	jalr	-342(ra) # 80002e12 <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002f70:	864a                	mv	a2,s2
    80002f72:	85a6                	mv	a1,s1
    80002f74:	00000097          	auipc	ra,0x0
    80002f78:	f58080e7          	jalr	-168(ra) # 80002ecc <fetchstr>
}
    80002f7c:	60e2                	ld	ra,24(sp)
    80002f7e:	6442                	ld	s0,16(sp)
    80002f80:	64a2                	ld	s1,8(sp)
    80002f82:	6902                	ld	s2,0(sp)
    80002f84:	6105                	addi	sp,sp,32
    80002f86:	8082                	ret

0000000080002f88 <syscall>:

int syscall_args_num[] = {0, 0, 1, 1, 1, 3, 1, 2, 2, 1, 1, 0, 1, 1, 0, 2, 3, 2, 1, 2, 1, 1, 3, 1, 2};

void
syscall(void)
{
    80002f88:	7179                	addi	sp,sp,-48
    80002f8a:	f406                	sd	ra,40(sp)
    80002f8c:	f022                	sd	s0,32(sp)
    80002f8e:	ec26                	sd	s1,24(sp)
    80002f90:	e84a                	sd	s2,16(sp)
    80002f92:	e44e                	sd	s3,8(sp)
    80002f94:	e052                	sd	s4,0(sp)
    80002f96:	1800                	addi	s0,sp,48
  int num;
  struct proc *p = myproc();
    80002f98:	fffff097          	auipc	ra,0xfffff
    80002f9c:	a14080e7          	jalr	-1516(ra) # 800019ac <myproc>
    80002fa0:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002fa2:	05853903          	ld	s2,88(a0)
    80002fa6:	0a893783          	ld	a5,168(s2)
    80002faa:	0007899b          	sext.w	s3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002fae:	37fd                	addiw	a5,a5,-1
    80002fb0:	475d                	li	a4,23
    80002fb2:	0ef76a63          	bltu	a4,a5,800030a6 <syscall+0x11e>
    80002fb6:	00399713          	slli	a4,s3,0x3
    80002fba:	00005797          	auipc	a5,0x5
    80002fbe:	62678793          	addi	a5,a5,1574 # 800085e0 <syscalls>
    80002fc2:	97ba                	add	a5,a5,a4
    80002fc4:	639c                	ld	a5,0(a5)
    80002fc6:	c3e5                	beqz	a5,800030a6 <syscall+0x11e>
    int first_arg = p->trapframe->a0;
    80002fc8:	07093a03          	ld	s4,112(s2)
    p->trapframe->a0 = syscalls[num]();
    80002fcc:	9782                	jalr	a5
    80002fce:	06a93823          	sd	a0,112(s2)
    int m = p->mask;
    if ((m >> num) & 1) {
    80002fd2:	1684a783          	lw	a5,360(s1)
    80002fd6:	4137d7bb          	sraw	a5,a5,s3
    80002fda:	8b85                	andi	a5,a5,1
    80002fdc:	c7e5                	beqz	a5,800030c4 <syscall+0x13c>
      if (syscall_args_num[num] == 0)
    80002fde:	00299713          	slli	a4,s3,0x2
    80002fe2:	00006797          	auipc	a5,0x6
    80002fe6:	a4678793          	addi	a5,a5,-1466 # 80008a28 <syscall_args_num>
    80002fea:	97ba                	add	a5,a5,a4
    80002fec:	439c                	lw	a5,0(a5)
    80002fee:	c3b1                	beqz	a5,80003032 <syscall+0xaa>
    int first_arg = p->trapframe->a0;
    80002ff0:	000a069b          	sext.w	a3,s4
        printf("%d: syscall %s -> %d\n", p->pid, syscall_names[num], p->trapframe->a0);
      else if (syscall_args_num[num] == 1)
    80002ff4:	4705                	li	a4,1
    80002ff6:	06e78163          	beq	a5,a4,80003058 <syscall+0xd0>
        printf("%d: syscall %s (%d) -> %d\n", p->pid, syscall_names[num], first_arg, p->trapframe->a0);
      else if (syscall_args_num[num] == 2)
    80002ffa:	4709                	li	a4,2
    80002ffc:	08e78163          	beq	a5,a4,8000307e <syscall+0xf6>
        printf("%d: syscall %s (%d %d) -> %d\n", p->pid, syscall_names[num], first_arg, p->trapframe->a1, p->trapframe->a0);
      else if (syscall_args_num[num] == 3)
    80003000:	470d                	li	a4,3
    80003002:	0ce79163          	bne	a5,a4,800030c4 <syscall+0x13c>
        printf("%d: syscall %s (%d %d %d) -> %d\n", p->pid, syscall_names[num], first_arg, p->trapframe->a1, p->trapframe->a2, p->trapframe->a0);
    80003006:	6cb8                	ld	a4,88(s1)
    80003008:	098e                	slli	s3,s3,0x3
    8000300a:	00006617          	auipc	a2,0x6
    8000300e:	a1e60613          	addi	a2,a2,-1506 # 80008a28 <syscall_args_num>
    80003012:	964e                	add	a2,a2,s3
    80003014:	07073803          	ld	a6,112(a4)
    80003018:	635c                	ld	a5,128(a4)
    8000301a:	7f38                	ld	a4,120(a4)
    8000301c:	7630                	ld	a2,104(a2)
    8000301e:	588c                	lw	a1,48(s1)
    80003020:	00005517          	auipc	a0,0x5
    80003024:	4a050513          	addi	a0,a0,1184 # 800084c0 <states.0+0x1a8>
    80003028:	ffffd097          	auipc	ra,0xffffd
    8000302c:	562080e7          	jalr	1378(ra) # 8000058a <printf>
    80003030:	a851                	j	800030c4 <syscall+0x13c>
        printf("%d: syscall %s -> %d\n", p->pid, syscall_names[num], p->trapframe->a0);
    80003032:	6cb8                	ld	a4,88(s1)
    80003034:	098e                	slli	s3,s3,0x3
    80003036:	00006797          	auipc	a5,0x6
    8000303a:	9f278793          	addi	a5,a5,-1550 # 80008a28 <syscall_args_num>
    8000303e:	97ce                	add	a5,a5,s3
    80003040:	7b34                	ld	a3,112(a4)
    80003042:	77b0                	ld	a2,104(a5)
    80003044:	588c                	lw	a1,48(s1)
    80003046:	00005517          	auipc	a0,0x5
    8000304a:	42250513          	addi	a0,a0,1058 # 80008468 <states.0+0x150>
    8000304e:	ffffd097          	auipc	ra,0xffffd
    80003052:	53c080e7          	jalr	1340(ra) # 8000058a <printf>
    80003056:	a0bd                	j	800030c4 <syscall+0x13c>
        printf("%d: syscall %s (%d) -> %d\n", p->pid, syscall_names[num], first_arg, p->trapframe->a0);
    80003058:	6cb8                	ld	a4,88(s1)
    8000305a:	098e                	slli	s3,s3,0x3
    8000305c:	00006797          	auipc	a5,0x6
    80003060:	9cc78793          	addi	a5,a5,-1588 # 80008a28 <syscall_args_num>
    80003064:	97ce                	add	a5,a5,s3
    80003066:	7b38                	ld	a4,112(a4)
    80003068:	77b0                	ld	a2,104(a5)
    8000306a:	588c                	lw	a1,48(s1)
    8000306c:	00005517          	auipc	a0,0x5
    80003070:	41450513          	addi	a0,a0,1044 # 80008480 <states.0+0x168>
    80003074:	ffffd097          	auipc	ra,0xffffd
    80003078:	516080e7          	jalr	1302(ra) # 8000058a <printf>
    8000307c:	a0a1                	j	800030c4 <syscall+0x13c>
        printf("%d: syscall %s (%d %d) -> %d\n", p->pid, syscall_names[num], first_arg, p->trapframe->a1, p->trapframe->a0);
    8000307e:	6cb8                	ld	a4,88(s1)
    80003080:	098e                	slli	s3,s3,0x3
    80003082:	00006617          	auipc	a2,0x6
    80003086:	9a660613          	addi	a2,a2,-1626 # 80008a28 <syscall_args_num>
    8000308a:	964e                	add	a2,a2,s3
    8000308c:	7b3c                	ld	a5,112(a4)
    8000308e:	7f38                	ld	a4,120(a4)
    80003090:	7630                	ld	a2,104(a2)
    80003092:	588c                	lw	a1,48(s1)
    80003094:	00005517          	auipc	a0,0x5
    80003098:	40c50513          	addi	a0,a0,1036 # 800084a0 <states.0+0x188>
    8000309c:	ffffd097          	auipc	ra,0xffffd
    800030a0:	4ee080e7          	jalr	1262(ra) # 8000058a <printf>
    800030a4:	a005                	j	800030c4 <syscall+0x13c>
    }
  } else {
    printf("%d %s: unknown sys call %d\n",
    800030a6:	86ce                	mv	a3,s3
    800030a8:	15848613          	addi	a2,s1,344
    800030ac:	588c                	lw	a1,48(s1)
    800030ae:	00005517          	auipc	a0,0x5
    800030b2:	43a50513          	addi	a0,a0,1082 # 800084e8 <states.0+0x1d0>
    800030b6:	ffffd097          	auipc	ra,0xffffd
    800030ba:	4d4080e7          	jalr	1236(ra) # 8000058a <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    800030be:	6cbc                	ld	a5,88(s1)
    800030c0:	577d                	li	a4,-1
    800030c2:	fbb8                	sd	a4,112(a5)
  }
}
    800030c4:	70a2                	ld	ra,40(sp)
    800030c6:	7402                	ld	s0,32(sp)
    800030c8:	64e2                	ld	s1,24(sp)
    800030ca:	6942                	ld	s2,16(sp)
    800030cc:	69a2                	ld	s3,8(sp)
    800030ce:	6a02                	ld	s4,0(sp)
    800030d0:	6145                	addi	sp,sp,48
    800030d2:	8082                	ret

00000000800030d4 <sys_strace>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_strace(void)
{
    800030d4:	1101                	addi	sp,sp,-32
    800030d6:	ec06                	sd	ra,24(sp)
    800030d8:	e822                	sd	s0,16(sp)
    800030da:	1000                	addi	s0,sp,32
  int trace_mask;

  argint(0, &trace_mask);
    800030dc:	fec40593          	addi	a1,s0,-20
    800030e0:	4501                	li	a0,0
    800030e2:	00000097          	auipc	ra,0x0
    800030e6:	e32080e7          	jalr	-462(ra) # 80002f14 <argint>
  if (trace_mask < 0)
    800030ea:	fec42783          	lw	a5,-20(s0)
    return -1;
    800030ee:	557d                	li	a0,-1
  if (trace_mask < 0)
    800030f0:	0007cb63          	bltz	a5,80003106 <sys_strace+0x32>

  struct proc *p = myproc();
    800030f4:	fffff097          	auipc	ra,0xfffff
    800030f8:	8b8080e7          	jalr	-1864(ra) # 800019ac <myproc>
  p->mask = trace_mask;
    800030fc:	fec42783          	lw	a5,-20(s0)
    80003100:	16f52423          	sw	a5,360(a0)

  return 0;
    80003104:	4501                	li	a0,0
}
    80003106:	60e2                	ld	ra,24(sp)
    80003108:	6442                	ld	s0,16(sp)
    8000310a:	6105                	addi	sp,sp,32
    8000310c:	8082                	ret

000000008000310e <sys_waitx>:
uint64	
sys_waitx(void)	
{	
    8000310e:	7139                	addi	sp,sp,-64
    80003110:	fc06                	sd	ra,56(sp)
    80003112:	f822                	sd	s0,48(sp)
    80003114:	f426                	sd	s1,40(sp)
    80003116:	f04a                	sd	s2,32(sp)
    80003118:	0080                	addi	s0,sp,64
  uint64 addr, addr1, addr2;	
  uint wtime, rtime;	
  if(argaddr(0, &addr) < 0)	
    8000311a:	fd840593          	addi	a1,s0,-40
    8000311e:	4501                	li	a0,0
    80003120:	00000097          	auipc	ra,0x0
    80003124:	e16080e7          	jalr	-490(ra) # 80002f36 <argaddr>
    return -1;	
    80003128:	57fd                	li	a5,-1
  if(argaddr(0, &addr) < 0)	
    8000312a:	08054063          	bltz	a0,800031aa <sys_waitx+0x9c>
  if(argaddr(1, &addr1) < 0) // user virtual memory	
    8000312e:	fd040593          	addi	a1,s0,-48
    80003132:	4505                	li	a0,1
    80003134:	00000097          	auipc	ra,0x0
    80003138:	e02080e7          	jalr	-510(ra) # 80002f36 <argaddr>
    return -1;	
    8000313c:	57fd                	li	a5,-1
  if(argaddr(1, &addr1) < 0) // user virtual memory	
    8000313e:	06054663          	bltz	a0,800031aa <sys_waitx+0x9c>
  if(argaddr(2, &addr2) < 0)	
    80003142:	fc840593          	addi	a1,s0,-56
    80003146:	4509                	li	a0,2
    80003148:	00000097          	auipc	ra,0x0
    8000314c:	dee080e7          	jalr	-530(ra) # 80002f36 <argaddr>
    return -1;	
    80003150:	57fd                	li	a5,-1
  if(argaddr(2, &addr2) < 0)	
    80003152:	04054c63          	bltz	a0,800031aa <sys_waitx+0x9c>
  int ret = waitx(addr, &wtime, &rtime);	
    80003156:	fc040613          	addi	a2,s0,-64
    8000315a:	fc440593          	addi	a1,s0,-60
    8000315e:	fd843503          	ld	a0,-40(s0)
    80003162:	fffff097          	auipc	ra,0xfffff
    80003166:	13c080e7          	jalr	316(ra) # 8000229e <waitx>
    8000316a:	892a                	mv	s2,a0
  struct proc* p = myproc();	
    8000316c:	fffff097          	auipc	ra,0xfffff
    80003170:	840080e7          	jalr	-1984(ra) # 800019ac <myproc>
    80003174:	84aa                	mv	s1,a0
  if (copyout(p->pagetable, addr1,(char*)&wtime, sizeof(int)) < 0)	
    80003176:	4691                	li	a3,4
    80003178:	fc440613          	addi	a2,s0,-60
    8000317c:	fd043583          	ld	a1,-48(s0)
    80003180:	6928                	ld	a0,80(a0)
    80003182:	ffffe097          	auipc	ra,0xffffe
    80003186:	4ea080e7          	jalr	1258(ra) # 8000166c <copyout>
    return -1;	
    8000318a:	57fd                	li	a5,-1
  if (copyout(p->pagetable, addr1,(char*)&wtime, sizeof(int)) < 0)	
    8000318c:	00054f63          	bltz	a0,800031aa <sys_waitx+0x9c>
  if (copyout(p->pagetable, addr2,(char*)&rtime, sizeof(int)) < 0)	
    80003190:	4691                	li	a3,4
    80003192:	fc040613          	addi	a2,s0,-64
    80003196:	fc843583          	ld	a1,-56(s0)
    8000319a:	68a8                	ld	a0,80(s1)
    8000319c:	ffffe097          	auipc	ra,0xffffe
    800031a0:	4d0080e7          	jalr	1232(ra) # 8000166c <copyout>
    800031a4:	00054a63          	bltz	a0,800031b8 <sys_waitx+0xaa>
    return -1;	
  return ret;	
    800031a8:	87ca                	mv	a5,s2
}	
    800031aa:	853e                	mv	a0,a5
    800031ac:	70e2                	ld	ra,56(sp)
    800031ae:	7442                	ld	s0,48(sp)
    800031b0:	74a2                	ld	s1,40(sp)
    800031b2:	7902                	ld	s2,32(sp)
    800031b4:	6121                	addi	sp,sp,64
    800031b6:	8082                	ret
    return -1;	
    800031b8:	57fd                	li	a5,-1
    800031ba:	bfc5                	j	800031aa <sys_waitx+0x9c>

00000000800031bc <sys_set_priority>:
uint64	
sys_set_priority(void)	
{	
    800031bc:	1101                	addi	sp,sp,-32
    800031be:	ec06                	sd	ra,24(sp)
    800031c0:	e822                	sd	s0,16(sp)
    800031c2:	1000                	addi	s0,sp,32
  int priority, pid;	
  if (argint(0, &priority) < 0)	
    800031c4:	fec40593          	addi	a1,s0,-20
    800031c8:	4501                	li	a0,0
    800031ca:	00000097          	auipc	ra,0x0
    800031ce:	d4a080e7          	jalr	-694(ra) # 80002f14 <argint>
    return -1;	
    800031d2:	57fd                	li	a5,-1
  if (argint(0, &priority) < 0)	
    800031d4:	02054563          	bltz	a0,800031fe <sys_set_priority+0x42>
  if (argint(1, &pid) < 0)	
    800031d8:	fe840593          	addi	a1,s0,-24
    800031dc:	4505                	li	a0,1
    800031de:	00000097          	auipc	ra,0x0
    800031e2:	d36080e7          	jalr	-714(ra) # 80002f14 <argint>
    return -1;	
    800031e6:	57fd                	li	a5,-1
  if (argint(1, &pid) < 0)	
    800031e8:	00054b63          	bltz	a0,800031fe <sys_set_priority+0x42>
  return set_priority(priority, pid);	
    800031ec:	fe842583          	lw	a1,-24(s0)
    800031f0:	fec42503          	lw	a0,-20(s0)
    800031f4:	fffff097          	auipc	ra,0xfffff
    800031f8:	d86080e7          	jalr	-634(ra) # 80001f7a <set_priority>
    800031fc:	87aa                	mv	a5,a0
}
    800031fe:	853e                	mv	a0,a5
    80003200:	60e2                	ld	ra,24(sp)
    80003202:	6442                	ld	s0,16(sp)
    80003204:	6105                	addi	sp,sp,32
    80003206:	8082                	ret

0000000080003208 <sys_exit>:
uint64
sys_exit(void)
{
    80003208:	1101                	addi	sp,sp,-32
    8000320a:	ec06                	sd	ra,24(sp)
    8000320c:	e822                	sd	s0,16(sp)
    8000320e:	1000                	addi	s0,sp,32
  int n;
  argint(0, &n);
    80003210:	fec40593          	addi	a1,s0,-20
    80003214:	4501                	li	a0,0
    80003216:	00000097          	auipc	ra,0x0
    8000321a:	cfe080e7          	jalr	-770(ra) # 80002f14 <argint>
  exit(n);
    8000321e:	fec42503          	lw	a0,-20(s0)
    80003222:	fffff097          	auipc	ra,0xfffff
    80003226:	298080e7          	jalr	664(ra) # 800024ba <exit>
  return 0;  // not reached
}
    8000322a:	4501                	li	a0,0
    8000322c:	60e2                	ld	ra,24(sp)
    8000322e:	6442                	ld	s0,16(sp)
    80003230:	6105                	addi	sp,sp,32
    80003232:	8082                	ret

0000000080003234 <sys_getpid>:

uint64
sys_getpid(void)
{
    80003234:	1141                	addi	sp,sp,-16
    80003236:	e406                	sd	ra,8(sp)
    80003238:	e022                	sd	s0,0(sp)
    8000323a:	0800                	addi	s0,sp,16
  return myproc()->pid;
    8000323c:	ffffe097          	auipc	ra,0xffffe
    80003240:	770080e7          	jalr	1904(ra) # 800019ac <myproc>
}
    80003244:	5908                	lw	a0,48(a0)
    80003246:	60a2                	ld	ra,8(sp)
    80003248:	6402                	ld	s0,0(sp)
    8000324a:	0141                	addi	sp,sp,16
    8000324c:	8082                	ret

000000008000324e <sys_fork>:

uint64
sys_fork(void)
{
    8000324e:	1141                	addi	sp,sp,-16
    80003250:	e406                	sd	ra,8(sp)
    80003252:	e022                	sd	s0,0(sp)
    80003254:	0800                	addi	s0,sp,16
  return fork();
    80003256:	fffff097          	auipc	ra,0xfffff
    8000325a:	b44080e7          	jalr	-1212(ra) # 80001d9a <fork>
}
    8000325e:	60a2                	ld	ra,8(sp)
    80003260:	6402                	ld	s0,0(sp)
    80003262:	0141                	addi	sp,sp,16
    80003264:	8082                	ret

0000000080003266 <sys_wait>:

uint64
sys_wait(void)
{
    80003266:	1101                	addi	sp,sp,-32
    80003268:	ec06                	sd	ra,24(sp)
    8000326a:	e822                	sd	s0,16(sp)
    8000326c:	1000                	addi	s0,sp,32
  uint64 p;
  argaddr(0, &p);
    8000326e:	fe840593          	addi	a1,s0,-24
    80003272:	4501                	li	a0,0
    80003274:	00000097          	auipc	ra,0x0
    80003278:	cc2080e7          	jalr	-830(ra) # 80002f36 <argaddr>
  return wait(p);
    8000327c:	fe843503          	ld	a0,-24(s0)
    80003280:	fffff097          	auipc	ra,0xfffff
    80003284:	3ec080e7          	jalr	1004(ra) # 8000266c <wait>
}
    80003288:	60e2                	ld	ra,24(sp)
    8000328a:	6442                	ld	s0,16(sp)
    8000328c:	6105                	addi	sp,sp,32
    8000328e:	8082                	ret

0000000080003290 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80003290:	7179                	addi	sp,sp,-48
    80003292:	f406                	sd	ra,40(sp)
    80003294:	f022                	sd	s0,32(sp)
    80003296:	ec26                	sd	s1,24(sp)
    80003298:	1800                	addi	s0,sp,48
  uint64 addr;
  int n;

  argint(0, &n);
    8000329a:	fdc40593          	addi	a1,s0,-36
    8000329e:	4501                	li	a0,0
    800032a0:	00000097          	auipc	ra,0x0
    800032a4:	c74080e7          	jalr	-908(ra) # 80002f14 <argint>
  addr = myproc()->sz;
    800032a8:	ffffe097          	auipc	ra,0xffffe
    800032ac:	704080e7          	jalr	1796(ra) # 800019ac <myproc>
    800032b0:	6524                	ld	s1,72(a0)
  if(growproc(n) < 0)
    800032b2:	fdc42503          	lw	a0,-36(s0)
    800032b6:	fffff097          	auipc	ra,0xfffff
    800032ba:	a88080e7          	jalr	-1400(ra) # 80001d3e <growproc>
    800032be:	00054863          	bltz	a0,800032ce <sys_sbrk+0x3e>
    return -1;
  return addr;
}
    800032c2:	8526                	mv	a0,s1
    800032c4:	70a2                	ld	ra,40(sp)
    800032c6:	7402                	ld	s0,32(sp)
    800032c8:	64e2                	ld	s1,24(sp)
    800032ca:	6145                	addi	sp,sp,48
    800032cc:	8082                	ret
    return -1;
    800032ce:	54fd                	li	s1,-1
    800032d0:	bfcd                	j	800032c2 <sys_sbrk+0x32>

00000000800032d2 <sys_sleep>:

uint64
sys_sleep(void)
{
    800032d2:	7139                	addi	sp,sp,-64
    800032d4:	fc06                	sd	ra,56(sp)
    800032d6:	f822                	sd	s0,48(sp)
    800032d8:	f426                	sd	s1,40(sp)
    800032da:	f04a                	sd	s2,32(sp)
    800032dc:	ec4e                	sd	s3,24(sp)
    800032de:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  argint(0, &n);
    800032e0:	fcc40593          	addi	a1,s0,-52
    800032e4:	4501                	li	a0,0
    800032e6:	00000097          	auipc	ra,0x0
    800032ea:	c2e080e7          	jalr	-978(ra) # 80002f14 <argint>
  acquire(&tickslock);
    800032ee:	00015517          	auipc	a0,0x15
    800032f2:	96250513          	addi	a0,a0,-1694 # 80017c50 <tickslock>
    800032f6:	ffffe097          	auipc	ra,0xffffe
    800032fa:	8e0080e7          	jalr	-1824(ra) # 80000bd6 <acquire>
  ticks0 = ticks;
    800032fe:	00006917          	auipc	s2,0x6
    80003302:	8b292903          	lw	s2,-1870(s2) # 80008bb0 <ticks>
  while(ticks - ticks0 < n){
    80003306:	fcc42783          	lw	a5,-52(s0)
    8000330a:	cf9d                	beqz	a5,80003348 <sys_sleep+0x76>
    if(killed(myproc())){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    8000330c:	00015997          	auipc	s3,0x15
    80003310:	94498993          	addi	s3,s3,-1724 # 80017c50 <tickslock>
    80003314:	00006497          	auipc	s1,0x6
    80003318:	89c48493          	addi	s1,s1,-1892 # 80008bb0 <ticks>
    if(killed(myproc())){
    8000331c:	ffffe097          	auipc	ra,0xffffe
    80003320:	690080e7          	jalr	1680(ra) # 800019ac <myproc>
    80003324:	fffff097          	auipc	ra,0xfffff
    80003328:	316080e7          	jalr	790(ra) # 8000263a <killed>
    8000332c:	ed15                	bnez	a0,80003368 <sys_sleep+0x96>
    sleep(&ticks, &tickslock);
    8000332e:	85ce                	mv	a1,s3
    80003330:	8526                	mv	a0,s1
    80003332:	fffff097          	auipc	ra,0xfffff
    80003336:	f08080e7          	jalr	-248(ra) # 8000223a <sleep>
  while(ticks - ticks0 < n){
    8000333a:	409c                	lw	a5,0(s1)
    8000333c:	412787bb          	subw	a5,a5,s2
    80003340:	fcc42703          	lw	a4,-52(s0)
    80003344:	fce7ece3          	bltu	a5,a4,8000331c <sys_sleep+0x4a>
  }
  release(&tickslock);
    80003348:	00015517          	auipc	a0,0x15
    8000334c:	90850513          	addi	a0,a0,-1784 # 80017c50 <tickslock>
    80003350:	ffffe097          	auipc	ra,0xffffe
    80003354:	93a080e7          	jalr	-1734(ra) # 80000c8a <release>
  return 0;
    80003358:	4501                	li	a0,0
}
    8000335a:	70e2                	ld	ra,56(sp)
    8000335c:	7442                	ld	s0,48(sp)
    8000335e:	74a2                	ld	s1,40(sp)
    80003360:	7902                	ld	s2,32(sp)
    80003362:	69e2                	ld	s3,24(sp)
    80003364:	6121                	addi	sp,sp,64
    80003366:	8082                	ret
      release(&tickslock);
    80003368:	00015517          	auipc	a0,0x15
    8000336c:	8e850513          	addi	a0,a0,-1816 # 80017c50 <tickslock>
    80003370:	ffffe097          	auipc	ra,0xffffe
    80003374:	91a080e7          	jalr	-1766(ra) # 80000c8a <release>
      return -1;
    80003378:	557d                	li	a0,-1
    8000337a:	b7c5                	j	8000335a <sys_sleep+0x88>

000000008000337c <sys_kill>:

uint64
sys_kill(void)
{
    8000337c:	1101                	addi	sp,sp,-32
    8000337e:	ec06                	sd	ra,24(sp)
    80003380:	e822                	sd	s0,16(sp)
    80003382:	1000                	addi	s0,sp,32
  int pid;

  argint(0, &pid);
    80003384:	fec40593          	addi	a1,s0,-20
    80003388:	4501                	li	a0,0
    8000338a:	00000097          	auipc	ra,0x0
    8000338e:	b8a080e7          	jalr	-1142(ra) # 80002f14 <argint>
  return kill(pid);
    80003392:	fec42503          	lw	a0,-20(s0)
    80003396:	fffff097          	auipc	ra,0xfffff
    8000339a:	206080e7          	jalr	518(ra) # 8000259c <kill>
}
    8000339e:	60e2                	ld	ra,24(sp)
    800033a0:	6442                	ld	s0,16(sp)
    800033a2:	6105                	addi	sp,sp,32
    800033a4:	8082                	ret

00000000800033a6 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    800033a6:	1101                	addi	sp,sp,-32
    800033a8:	ec06                	sd	ra,24(sp)
    800033aa:	e822                	sd	s0,16(sp)
    800033ac:	e426                	sd	s1,8(sp)
    800033ae:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    800033b0:	00015517          	auipc	a0,0x15
    800033b4:	8a050513          	addi	a0,a0,-1888 # 80017c50 <tickslock>
    800033b8:	ffffe097          	auipc	ra,0xffffe
    800033bc:	81e080e7          	jalr	-2018(ra) # 80000bd6 <acquire>
  xticks = ticks;
    800033c0:	00005497          	auipc	s1,0x5
    800033c4:	7f04a483          	lw	s1,2032(s1) # 80008bb0 <ticks>
  release(&tickslock);
    800033c8:	00015517          	auipc	a0,0x15
    800033cc:	88850513          	addi	a0,a0,-1912 # 80017c50 <tickslock>
    800033d0:	ffffe097          	auipc	ra,0xffffe
    800033d4:	8ba080e7          	jalr	-1862(ra) # 80000c8a <release>
  return xticks;
}
    800033d8:	02049513          	slli	a0,s1,0x20
    800033dc:	9101                	srli	a0,a0,0x20
    800033de:	60e2                	ld	ra,24(sp)
    800033e0:	6442                	ld	s0,16(sp)
    800033e2:	64a2                	ld	s1,8(sp)
    800033e4:	6105                	addi	sp,sp,32
    800033e6:	8082                	ret

00000000800033e8 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    800033e8:	7179                	addi	sp,sp,-48
    800033ea:	f406                	sd	ra,40(sp)
    800033ec:	f022                	sd	s0,32(sp)
    800033ee:	ec26                	sd	s1,24(sp)
    800033f0:	e84a                	sd	s2,16(sp)
    800033f2:	e44e                	sd	s3,8(sp)
    800033f4:	e052                	sd	s4,0(sp)
    800033f6:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    800033f8:	00005597          	auipc	a1,0x5
    800033fc:	2b058593          	addi	a1,a1,688 # 800086a8 <syscalls+0xc8>
    80003400:	00015517          	auipc	a0,0x15
    80003404:	86850513          	addi	a0,a0,-1944 # 80017c68 <bcache>
    80003408:	ffffd097          	auipc	ra,0xffffd
    8000340c:	73e080e7          	jalr	1854(ra) # 80000b46 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80003410:	0001d797          	auipc	a5,0x1d
    80003414:	85878793          	addi	a5,a5,-1960 # 8001fc68 <bcache+0x8000>
    80003418:	0001d717          	auipc	a4,0x1d
    8000341c:	ab870713          	addi	a4,a4,-1352 # 8001fed0 <bcache+0x8268>
    80003420:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80003424:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003428:	00015497          	auipc	s1,0x15
    8000342c:	85848493          	addi	s1,s1,-1960 # 80017c80 <bcache+0x18>
    b->next = bcache.head.next;
    80003430:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80003432:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80003434:	00005a17          	auipc	s4,0x5
    80003438:	27ca0a13          	addi	s4,s4,636 # 800086b0 <syscalls+0xd0>
    b->next = bcache.head.next;
    8000343c:	2b893783          	ld	a5,696(s2)
    80003440:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80003442:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80003446:	85d2                	mv	a1,s4
    80003448:	01048513          	addi	a0,s1,16
    8000344c:	00001097          	auipc	ra,0x1
    80003450:	4c8080e7          	jalr	1224(ra) # 80004914 <initsleeplock>
    bcache.head.next->prev = b;
    80003454:	2b893783          	ld	a5,696(s2)
    80003458:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    8000345a:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    8000345e:	45848493          	addi	s1,s1,1112
    80003462:	fd349de3          	bne	s1,s3,8000343c <binit+0x54>
  }
}
    80003466:	70a2                	ld	ra,40(sp)
    80003468:	7402                	ld	s0,32(sp)
    8000346a:	64e2                	ld	s1,24(sp)
    8000346c:	6942                	ld	s2,16(sp)
    8000346e:	69a2                	ld	s3,8(sp)
    80003470:	6a02                	ld	s4,0(sp)
    80003472:	6145                	addi	sp,sp,48
    80003474:	8082                	ret

0000000080003476 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80003476:	7179                	addi	sp,sp,-48
    80003478:	f406                	sd	ra,40(sp)
    8000347a:	f022                	sd	s0,32(sp)
    8000347c:	ec26                	sd	s1,24(sp)
    8000347e:	e84a                	sd	s2,16(sp)
    80003480:	e44e                	sd	s3,8(sp)
    80003482:	1800                	addi	s0,sp,48
    80003484:	892a                	mv	s2,a0
    80003486:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    80003488:	00014517          	auipc	a0,0x14
    8000348c:	7e050513          	addi	a0,a0,2016 # 80017c68 <bcache>
    80003490:	ffffd097          	auipc	ra,0xffffd
    80003494:	746080e7          	jalr	1862(ra) # 80000bd6 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80003498:	0001d497          	auipc	s1,0x1d
    8000349c:	a884b483          	ld	s1,-1400(s1) # 8001ff20 <bcache+0x82b8>
    800034a0:	0001d797          	auipc	a5,0x1d
    800034a4:	a3078793          	addi	a5,a5,-1488 # 8001fed0 <bcache+0x8268>
    800034a8:	02f48f63          	beq	s1,a5,800034e6 <bread+0x70>
    800034ac:	873e                	mv	a4,a5
    800034ae:	a021                	j	800034b6 <bread+0x40>
    800034b0:	68a4                	ld	s1,80(s1)
    800034b2:	02e48a63          	beq	s1,a4,800034e6 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    800034b6:	449c                	lw	a5,8(s1)
    800034b8:	ff279ce3          	bne	a5,s2,800034b0 <bread+0x3a>
    800034bc:	44dc                	lw	a5,12(s1)
    800034be:	ff3799e3          	bne	a5,s3,800034b0 <bread+0x3a>
      b->refcnt++;
    800034c2:	40bc                	lw	a5,64(s1)
    800034c4:	2785                	addiw	a5,a5,1
    800034c6:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800034c8:	00014517          	auipc	a0,0x14
    800034cc:	7a050513          	addi	a0,a0,1952 # 80017c68 <bcache>
    800034d0:	ffffd097          	auipc	ra,0xffffd
    800034d4:	7ba080e7          	jalr	1978(ra) # 80000c8a <release>
      acquiresleep(&b->lock);
    800034d8:	01048513          	addi	a0,s1,16
    800034dc:	00001097          	auipc	ra,0x1
    800034e0:	472080e7          	jalr	1138(ra) # 8000494e <acquiresleep>
      return b;
    800034e4:	a8b9                	j	80003542 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800034e6:	0001d497          	auipc	s1,0x1d
    800034ea:	a324b483          	ld	s1,-1486(s1) # 8001ff18 <bcache+0x82b0>
    800034ee:	0001d797          	auipc	a5,0x1d
    800034f2:	9e278793          	addi	a5,a5,-1566 # 8001fed0 <bcache+0x8268>
    800034f6:	00f48863          	beq	s1,a5,80003506 <bread+0x90>
    800034fa:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    800034fc:	40bc                	lw	a5,64(s1)
    800034fe:	cf81                	beqz	a5,80003516 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003500:	64a4                	ld	s1,72(s1)
    80003502:	fee49de3          	bne	s1,a4,800034fc <bread+0x86>
  panic("bget: no buffers");
    80003506:	00005517          	auipc	a0,0x5
    8000350a:	1b250513          	addi	a0,a0,434 # 800086b8 <syscalls+0xd8>
    8000350e:	ffffd097          	auipc	ra,0xffffd
    80003512:	032080e7          	jalr	50(ra) # 80000540 <panic>
      b->dev = dev;
    80003516:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    8000351a:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    8000351e:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003522:	4785                	li	a5,1
    80003524:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003526:	00014517          	auipc	a0,0x14
    8000352a:	74250513          	addi	a0,a0,1858 # 80017c68 <bcache>
    8000352e:	ffffd097          	auipc	ra,0xffffd
    80003532:	75c080e7          	jalr	1884(ra) # 80000c8a <release>
      acquiresleep(&b->lock);
    80003536:	01048513          	addi	a0,s1,16
    8000353a:	00001097          	auipc	ra,0x1
    8000353e:	414080e7          	jalr	1044(ra) # 8000494e <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003542:	409c                	lw	a5,0(s1)
    80003544:	cb89                	beqz	a5,80003556 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80003546:	8526                	mv	a0,s1
    80003548:	70a2                	ld	ra,40(sp)
    8000354a:	7402                	ld	s0,32(sp)
    8000354c:	64e2                	ld	s1,24(sp)
    8000354e:	6942                	ld	s2,16(sp)
    80003550:	69a2                	ld	s3,8(sp)
    80003552:	6145                	addi	sp,sp,48
    80003554:	8082                	ret
    virtio_disk_rw(b, 0);
    80003556:	4581                	li	a1,0
    80003558:	8526                	mv	a0,s1
    8000355a:	00003097          	auipc	ra,0x3
    8000355e:	fd8080e7          	jalr	-40(ra) # 80006532 <virtio_disk_rw>
    b->valid = 1;
    80003562:	4785                	li	a5,1
    80003564:	c09c                	sw	a5,0(s1)
  return b;
    80003566:	b7c5                	j	80003546 <bread+0xd0>

0000000080003568 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003568:	1101                	addi	sp,sp,-32
    8000356a:	ec06                	sd	ra,24(sp)
    8000356c:	e822                	sd	s0,16(sp)
    8000356e:	e426                	sd	s1,8(sp)
    80003570:	1000                	addi	s0,sp,32
    80003572:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003574:	0541                	addi	a0,a0,16
    80003576:	00001097          	auipc	ra,0x1
    8000357a:	472080e7          	jalr	1138(ra) # 800049e8 <holdingsleep>
    8000357e:	cd01                	beqz	a0,80003596 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003580:	4585                	li	a1,1
    80003582:	8526                	mv	a0,s1
    80003584:	00003097          	auipc	ra,0x3
    80003588:	fae080e7          	jalr	-82(ra) # 80006532 <virtio_disk_rw>
}
    8000358c:	60e2                	ld	ra,24(sp)
    8000358e:	6442                	ld	s0,16(sp)
    80003590:	64a2                	ld	s1,8(sp)
    80003592:	6105                	addi	sp,sp,32
    80003594:	8082                	ret
    panic("bwrite");
    80003596:	00005517          	auipc	a0,0x5
    8000359a:	13a50513          	addi	a0,a0,314 # 800086d0 <syscalls+0xf0>
    8000359e:	ffffd097          	auipc	ra,0xffffd
    800035a2:	fa2080e7          	jalr	-94(ra) # 80000540 <panic>

00000000800035a6 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    800035a6:	1101                	addi	sp,sp,-32
    800035a8:	ec06                	sd	ra,24(sp)
    800035aa:	e822                	sd	s0,16(sp)
    800035ac:	e426                	sd	s1,8(sp)
    800035ae:	e04a                	sd	s2,0(sp)
    800035b0:	1000                	addi	s0,sp,32
    800035b2:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800035b4:	01050913          	addi	s2,a0,16
    800035b8:	854a                	mv	a0,s2
    800035ba:	00001097          	auipc	ra,0x1
    800035be:	42e080e7          	jalr	1070(ra) # 800049e8 <holdingsleep>
    800035c2:	c92d                	beqz	a0,80003634 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    800035c4:	854a                	mv	a0,s2
    800035c6:	00001097          	auipc	ra,0x1
    800035ca:	3de080e7          	jalr	990(ra) # 800049a4 <releasesleep>

  acquire(&bcache.lock);
    800035ce:	00014517          	auipc	a0,0x14
    800035d2:	69a50513          	addi	a0,a0,1690 # 80017c68 <bcache>
    800035d6:	ffffd097          	auipc	ra,0xffffd
    800035da:	600080e7          	jalr	1536(ra) # 80000bd6 <acquire>
  b->refcnt--;
    800035de:	40bc                	lw	a5,64(s1)
    800035e0:	37fd                	addiw	a5,a5,-1
    800035e2:	0007871b          	sext.w	a4,a5
    800035e6:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    800035e8:	eb05                	bnez	a4,80003618 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    800035ea:	68bc                	ld	a5,80(s1)
    800035ec:	64b8                	ld	a4,72(s1)
    800035ee:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    800035f0:	64bc                	ld	a5,72(s1)
    800035f2:	68b8                	ld	a4,80(s1)
    800035f4:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    800035f6:	0001c797          	auipc	a5,0x1c
    800035fa:	67278793          	addi	a5,a5,1650 # 8001fc68 <bcache+0x8000>
    800035fe:	2b87b703          	ld	a4,696(a5)
    80003602:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003604:	0001d717          	auipc	a4,0x1d
    80003608:	8cc70713          	addi	a4,a4,-1844 # 8001fed0 <bcache+0x8268>
    8000360c:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    8000360e:	2b87b703          	ld	a4,696(a5)
    80003612:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003614:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003618:	00014517          	auipc	a0,0x14
    8000361c:	65050513          	addi	a0,a0,1616 # 80017c68 <bcache>
    80003620:	ffffd097          	auipc	ra,0xffffd
    80003624:	66a080e7          	jalr	1642(ra) # 80000c8a <release>
}
    80003628:	60e2                	ld	ra,24(sp)
    8000362a:	6442                	ld	s0,16(sp)
    8000362c:	64a2                	ld	s1,8(sp)
    8000362e:	6902                	ld	s2,0(sp)
    80003630:	6105                	addi	sp,sp,32
    80003632:	8082                	ret
    panic("brelse");
    80003634:	00005517          	auipc	a0,0x5
    80003638:	0a450513          	addi	a0,a0,164 # 800086d8 <syscalls+0xf8>
    8000363c:	ffffd097          	auipc	ra,0xffffd
    80003640:	f04080e7          	jalr	-252(ra) # 80000540 <panic>

0000000080003644 <bpin>:

void
bpin(struct buf *b) {
    80003644:	1101                	addi	sp,sp,-32
    80003646:	ec06                	sd	ra,24(sp)
    80003648:	e822                	sd	s0,16(sp)
    8000364a:	e426                	sd	s1,8(sp)
    8000364c:	1000                	addi	s0,sp,32
    8000364e:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003650:	00014517          	auipc	a0,0x14
    80003654:	61850513          	addi	a0,a0,1560 # 80017c68 <bcache>
    80003658:	ffffd097          	auipc	ra,0xffffd
    8000365c:	57e080e7          	jalr	1406(ra) # 80000bd6 <acquire>
  b->refcnt++;
    80003660:	40bc                	lw	a5,64(s1)
    80003662:	2785                	addiw	a5,a5,1
    80003664:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003666:	00014517          	auipc	a0,0x14
    8000366a:	60250513          	addi	a0,a0,1538 # 80017c68 <bcache>
    8000366e:	ffffd097          	auipc	ra,0xffffd
    80003672:	61c080e7          	jalr	1564(ra) # 80000c8a <release>
}
    80003676:	60e2                	ld	ra,24(sp)
    80003678:	6442                	ld	s0,16(sp)
    8000367a:	64a2                	ld	s1,8(sp)
    8000367c:	6105                	addi	sp,sp,32
    8000367e:	8082                	ret

0000000080003680 <bunpin>:

void
bunpin(struct buf *b) {
    80003680:	1101                	addi	sp,sp,-32
    80003682:	ec06                	sd	ra,24(sp)
    80003684:	e822                	sd	s0,16(sp)
    80003686:	e426                	sd	s1,8(sp)
    80003688:	1000                	addi	s0,sp,32
    8000368a:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000368c:	00014517          	auipc	a0,0x14
    80003690:	5dc50513          	addi	a0,a0,1500 # 80017c68 <bcache>
    80003694:	ffffd097          	auipc	ra,0xffffd
    80003698:	542080e7          	jalr	1346(ra) # 80000bd6 <acquire>
  b->refcnt--;
    8000369c:	40bc                	lw	a5,64(s1)
    8000369e:	37fd                	addiw	a5,a5,-1
    800036a0:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800036a2:	00014517          	auipc	a0,0x14
    800036a6:	5c650513          	addi	a0,a0,1478 # 80017c68 <bcache>
    800036aa:	ffffd097          	auipc	ra,0xffffd
    800036ae:	5e0080e7          	jalr	1504(ra) # 80000c8a <release>
}
    800036b2:	60e2                	ld	ra,24(sp)
    800036b4:	6442                	ld	s0,16(sp)
    800036b6:	64a2                	ld	s1,8(sp)
    800036b8:	6105                	addi	sp,sp,32
    800036ba:	8082                	ret

00000000800036bc <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    800036bc:	1101                	addi	sp,sp,-32
    800036be:	ec06                	sd	ra,24(sp)
    800036c0:	e822                	sd	s0,16(sp)
    800036c2:	e426                	sd	s1,8(sp)
    800036c4:	e04a                	sd	s2,0(sp)
    800036c6:	1000                	addi	s0,sp,32
    800036c8:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    800036ca:	00d5d59b          	srliw	a1,a1,0xd
    800036ce:	0001d797          	auipc	a5,0x1d
    800036d2:	c767a783          	lw	a5,-906(a5) # 80020344 <sb+0x1c>
    800036d6:	9dbd                	addw	a1,a1,a5
    800036d8:	00000097          	auipc	ra,0x0
    800036dc:	d9e080e7          	jalr	-610(ra) # 80003476 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    800036e0:	0074f713          	andi	a4,s1,7
    800036e4:	4785                	li	a5,1
    800036e6:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    800036ea:	14ce                	slli	s1,s1,0x33
    800036ec:	90d9                	srli	s1,s1,0x36
    800036ee:	00950733          	add	a4,a0,s1
    800036f2:	05874703          	lbu	a4,88(a4)
    800036f6:	00e7f6b3          	and	a3,a5,a4
    800036fa:	c69d                	beqz	a3,80003728 <bfree+0x6c>
    800036fc:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    800036fe:	94aa                	add	s1,s1,a0
    80003700:	fff7c793          	not	a5,a5
    80003704:	8f7d                	and	a4,a4,a5
    80003706:	04e48c23          	sb	a4,88(s1)
  log_write(bp);
    8000370a:	00001097          	auipc	ra,0x1
    8000370e:	126080e7          	jalr	294(ra) # 80004830 <log_write>
  brelse(bp);
    80003712:	854a                	mv	a0,s2
    80003714:	00000097          	auipc	ra,0x0
    80003718:	e92080e7          	jalr	-366(ra) # 800035a6 <brelse>
}
    8000371c:	60e2                	ld	ra,24(sp)
    8000371e:	6442                	ld	s0,16(sp)
    80003720:	64a2                	ld	s1,8(sp)
    80003722:	6902                	ld	s2,0(sp)
    80003724:	6105                	addi	sp,sp,32
    80003726:	8082                	ret
    panic("freeing free block");
    80003728:	00005517          	auipc	a0,0x5
    8000372c:	fb850513          	addi	a0,a0,-72 # 800086e0 <syscalls+0x100>
    80003730:	ffffd097          	auipc	ra,0xffffd
    80003734:	e10080e7          	jalr	-496(ra) # 80000540 <panic>

0000000080003738 <balloc>:
{
    80003738:	711d                	addi	sp,sp,-96
    8000373a:	ec86                	sd	ra,88(sp)
    8000373c:	e8a2                	sd	s0,80(sp)
    8000373e:	e4a6                	sd	s1,72(sp)
    80003740:	e0ca                	sd	s2,64(sp)
    80003742:	fc4e                	sd	s3,56(sp)
    80003744:	f852                	sd	s4,48(sp)
    80003746:	f456                	sd	s5,40(sp)
    80003748:	f05a                	sd	s6,32(sp)
    8000374a:	ec5e                	sd	s7,24(sp)
    8000374c:	e862                	sd	s8,16(sp)
    8000374e:	e466                	sd	s9,8(sp)
    80003750:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003752:	0001d797          	auipc	a5,0x1d
    80003756:	bda7a783          	lw	a5,-1062(a5) # 8002032c <sb+0x4>
    8000375a:	cff5                	beqz	a5,80003856 <balloc+0x11e>
    8000375c:	8baa                	mv	s7,a0
    8000375e:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003760:	0001db17          	auipc	s6,0x1d
    80003764:	bc8b0b13          	addi	s6,s6,-1080 # 80020328 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003768:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    8000376a:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000376c:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    8000376e:	6c89                	lui	s9,0x2
    80003770:	a061                	j	800037f8 <balloc+0xc0>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003772:	97ca                	add	a5,a5,s2
    80003774:	8e55                	or	a2,a2,a3
    80003776:	04c78c23          	sb	a2,88(a5)
        log_write(bp);
    8000377a:	854a                	mv	a0,s2
    8000377c:	00001097          	auipc	ra,0x1
    80003780:	0b4080e7          	jalr	180(ra) # 80004830 <log_write>
        brelse(bp);
    80003784:	854a                	mv	a0,s2
    80003786:	00000097          	auipc	ra,0x0
    8000378a:	e20080e7          	jalr	-480(ra) # 800035a6 <brelse>
  bp = bread(dev, bno);
    8000378e:	85a6                	mv	a1,s1
    80003790:	855e                	mv	a0,s7
    80003792:	00000097          	auipc	ra,0x0
    80003796:	ce4080e7          	jalr	-796(ra) # 80003476 <bread>
    8000379a:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    8000379c:	40000613          	li	a2,1024
    800037a0:	4581                	li	a1,0
    800037a2:	05850513          	addi	a0,a0,88
    800037a6:	ffffd097          	auipc	ra,0xffffd
    800037aa:	52c080e7          	jalr	1324(ra) # 80000cd2 <memset>
  log_write(bp);
    800037ae:	854a                	mv	a0,s2
    800037b0:	00001097          	auipc	ra,0x1
    800037b4:	080080e7          	jalr	128(ra) # 80004830 <log_write>
  brelse(bp);
    800037b8:	854a                	mv	a0,s2
    800037ba:	00000097          	auipc	ra,0x0
    800037be:	dec080e7          	jalr	-532(ra) # 800035a6 <brelse>
}
    800037c2:	8526                	mv	a0,s1
    800037c4:	60e6                	ld	ra,88(sp)
    800037c6:	6446                	ld	s0,80(sp)
    800037c8:	64a6                	ld	s1,72(sp)
    800037ca:	6906                	ld	s2,64(sp)
    800037cc:	79e2                	ld	s3,56(sp)
    800037ce:	7a42                	ld	s4,48(sp)
    800037d0:	7aa2                	ld	s5,40(sp)
    800037d2:	7b02                	ld	s6,32(sp)
    800037d4:	6be2                	ld	s7,24(sp)
    800037d6:	6c42                	ld	s8,16(sp)
    800037d8:	6ca2                	ld	s9,8(sp)
    800037da:	6125                	addi	sp,sp,96
    800037dc:	8082                	ret
    brelse(bp);
    800037de:	854a                	mv	a0,s2
    800037e0:	00000097          	auipc	ra,0x0
    800037e4:	dc6080e7          	jalr	-570(ra) # 800035a6 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    800037e8:	015c87bb          	addw	a5,s9,s5
    800037ec:	00078a9b          	sext.w	s5,a5
    800037f0:	004b2703          	lw	a4,4(s6)
    800037f4:	06eaf163          	bgeu	s5,a4,80003856 <balloc+0x11e>
    bp = bread(dev, BBLOCK(b, sb));
    800037f8:	41fad79b          	sraiw	a5,s5,0x1f
    800037fc:	0137d79b          	srliw	a5,a5,0x13
    80003800:	015787bb          	addw	a5,a5,s5
    80003804:	40d7d79b          	sraiw	a5,a5,0xd
    80003808:	01cb2583          	lw	a1,28(s6)
    8000380c:	9dbd                	addw	a1,a1,a5
    8000380e:	855e                	mv	a0,s7
    80003810:	00000097          	auipc	ra,0x0
    80003814:	c66080e7          	jalr	-922(ra) # 80003476 <bread>
    80003818:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000381a:	004b2503          	lw	a0,4(s6)
    8000381e:	000a849b          	sext.w	s1,s5
    80003822:	8762                	mv	a4,s8
    80003824:	faa4fde3          	bgeu	s1,a0,800037de <balloc+0xa6>
      m = 1 << (bi % 8);
    80003828:	00777693          	andi	a3,a4,7
    8000382c:	00d996bb          	sllw	a3,s3,a3
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003830:	41f7579b          	sraiw	a5,a4,0x1f
    80003834:	01d7d79b          	srliw	a5,a5,0x1d
    80003838:	9fb9                	addw	a5,a5,a4
    8000383a:	4037d79b          	sraiw	a5,a5,0x3
    8000383e:	00f90633          	add	a2,s2,a5
    80003842:	05864603          	lbu	a2,88(a2)
    80003846:	00c6f5b3          	and	a1,a3,a2
    8000384a:	d585                	beqz	a1,80003772 <balloc+0x3a>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000384c:	2705                	addiw	a4,a4,1
    8000384e:	2485                	addiw	s1,s1,1
    80003850:	fd471ae3          	bne	a4,s4,80003824 <balloc+0xec>
    80003854:	b769                	j	800037de <balloc+0xa6>
  printf("balloc: out of blocks\n");
    80003856:	00005517          	auipc	a0,0x5
    8000385a:	ea250513          	addi	a0,a0,-350 # 800086f8 <syscalls+0x118>
    8000385e:	ffffd097          	auipc	ra,0xffffd
    80003862:	d2c080e7          	jalr	-724(ra) # 8000058a <printf>
  return 0;
    80003866:	4481                	li	s1,0
    80003868:	bfa9                	j	800037c2 <balloc+0x8a>

000000008000386a <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    8000386a:	7179                	addi	sp,sp,-48
    8000386c:	f406                	sd	ra,40(sp)
    8000386e:	f022                	sd	s0,32(sp)
    80003870:	ec26                	sd	s1,24(sp)
    80003872:	e84a                	sd	s2,16(sp)
    80003874:	e44e                	sd	s3,8(sp)
    80003876:	e052                	sd	s4,0(sp)
    80003878:	1800                	addi	s0,sp,48
    8000387a:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    8000387c:	47ad                	li	a5,11
    8000387e:	02b7e863          	bltu	a5,a1,800038ae <bmap+0x44>
    if((addr = ip->addrs[bn]) == 0){
    80003882:	02059793          	slli	a5,a1,0x20
    80003886:	01e7d593          	srli	a1,a5,0x1e
    8000388a:	00b504b3          	add	s1,a0,a1
    8000388e:	0504a903          	lw	s2,80(s1)
    80003892:	06091e63          	bnez	s2,8000390e <bmap+0xa4>
      addr = balloc(ip->dev);
    80003896:	4108                	lw	a0,0(a0)
    80003898:	00000097          	auipc	ra,0x0
    8000389c:	ea0080e7          	jalr	-352(ra) # 80003738 <balloc>
    800038a0:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    800038a4:	06090563          	beqz	s2,8000390e <bmap+0xa4>
        return 0;
      ip->addrs[bn] = addr;
    800038a8:	0524a823          	sw	s2,80(s1)
    800038ac:	a08d                	j	8000390e <bmap+0xa4>
    }
    return addr;
  }
  bn -= NDIRECT;
    800038ae:	ff45849b          	addiw	s1,a1,-12
    800038b2:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    800038b6:	0ff00793          	li	a5,255
    800038ba:	08e7e563          	bltu	a5,a4,80003944 <bmap+0xda>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    800038be:	08052903          	lw	s2,128(a0)
    800038c2:	00091d63          	bnez	s2,800038dc <bmap+0x72>
      addr = balloc(ip->dev);
    800038c6:	4108                	lw	a0,0(a0)
    800038c8:	00000097          	auipc	ra,0x0
    800038cc:	e70080e7          	jalr	-400(ra) # 80003738 <balloc>
    800038d0:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    800038d4:	02090d63          	beqz	s2,8000390e <bmap+0xa4>
        return 0;
      ip->addrs[NDIRECT] = addr;
    800038d8:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    800038dc:	85ca                	mv	a1,s2
    800038de:	0009a503          	lw	a0,0(s3)
    800038e2:	00000097          	auipc	ra,0x0
    800038e6:	b94080e7          	jalr	-1132(ra) # 80003476 <bread>
    800038ea:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    800038ec:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    800038f0:	02049713          	slli	a4,s1,0x20
    800038f4:	01e75593          	srli	a1,a4,0x1e
    800038f8:	00b784b3          	add	s1,a5,a1
    800038fc:	0004a903          	lw	s2,0(s1)
    80003900:	02090063          	beqz	s2,80003920 <bmap+0xb6>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    80003904:	8552                	mv	a0,s4
    80003906:	00000097          	auipc	ra,0x0
    8000390a:	ca0080e7          	jalr	-864(ra) # 800035a6 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    8000390e:	854a                	mv	a0,s2
    80003910:	70a2                	ld	ra,40(sp)
    80003912:	7402                	ld	s0,32(sp)
    80003914:	64e2                	ld	s1,24(sp)
    80003916:	6942                	ld	s2,16(sp)
    80003918:	69a2                	ld	s3,8(sp)
    8000391a:	6a02                	ld	s4,0(sp)
    8000391c:	6145                	addi	sp,sp,48
    8000391e:	8082                	ret
      addr = balloc(ip->dev);
    80003920:	0009a503          	lw	a0,0(s3)
    80003924:	00000097          	auipc	ra,0x0
    80003928:	e14080e7          	jalr	-492(ra) # 80003738 <balloc>
    8000392c:	0005091b          	sext.w	s2,a0
      if(addr){
    80003930:	fc090ae3          	beqz	s2,80003904 <bmap+0x9a>
        a[bn] = addr;
    80003934:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    80003938:	8552                	mv	a0,s4
    8000393a:	00001097          	auipc	ra,0x1
    8000393e:	ef6080e7          	jalr	-266(ra) # 80004830 <log_write>
    80003942:	b7c9                	j	80003904 <bmap+0x9a>
  panic("bmap: out of range");
    80003944:	00005517          	auipc	a0,0x5
    80003948:	dcc50513          	addi	a0,a0,-564 # 80008710 <syscalls+0x130>
    8000394c:	ffffd097          	auipc	ra,0xffffd
    80003950:	bf4080e7          	jalr	-1036(ra) # 80000540 <panic>

0000000080003954 <iget>:
{
    80003954:	7179                	addi	sp,sp,-48
    80003956:	f406                	sd	ra,40(sp)
    80003958:	f022                	sd	s0,32(sp)
    8000395a:	ec26                	sd	s1,24(sp)
    8000395c:	e84a                	sd	s2,16(sp)
    8000395e:	e44e                	sd	s3,8(sp)
    80003960:	e052                	sd	s4,0(sp)
    80003962:	1800                	addi	s0,sp,48
    80003964:	89aa                	mv	s3,a0
    80003966:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003968:	0001d517          	auipc	a0,0x1d
    8000396c:	9e050513          	addi	a0,a0,-1568 # 80020348 <itable>
    80003970:	ffffd097          	auipc	ra,0xffffd
    80003974:	266080e7          	jalr	614(ra) # 80000bd6 <acquire>
  empty = 0;
    80003978:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    8000397a:	0001d497          	auipc	s1,0x1d
    8000397e:	9e648493          	addi	s1,s1,-1562 # 80020360 <itable+0x18>
    80003982:	0001e697          	auipc	a3,0x1e
    80003986:	46e68693          	addi	a3,a3,1134 # 80021df0 <log>
    8000398a:	a039                	j	80003998 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000398c:	02090b63          	beqz	s2,800039c2 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003990:	08848493          	addi	s1,s1,136
    80003994:	02d48a63          	beq	s1,a3,800039c8 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003998:	449c                	lw	a5,8(s1)
    8000399a:	fef059e3          	blez	a5,8000398c <iget+0x38>
    8000399e:	4098                	lw	a4,0(s1)
    800039a0:	ff3716e3          	bne	a4,s3,8000398c <iget+0x38>
    800039a4:	40d8                	lw	a4,4(s1)
    800039a6:	ff4713e3          	bne	a4,s4,8000398c <iget+0x38>
      ip->ref++;
    800039aa:	2785                	addiw	a5,a5,1
    800039ac:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    800039ae:	0001d517          	auipc	a0,0x1d
    800039b2:	99a50513          	addi	a0,a0,-1638 # 80020348 <itable>
    800039b6:	ffffd097          	auipc	ra,0xffffd
    800039ba:	2d4080e7          	jalr	724(ra) # 80000c8a <release>
      return ip;
    800039be:	8926                	mv	s2,s1
    800039c0:	a03d                	j	800039ee <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800039c2:	f7f9                	bnez	a5,80003990 <iget+0x3c>
    800039c4:	8926                	mv	s2,s1
    800039c6:	b7e9                	j	80003990 <iget+0x3c>
  if(empty == 0)
    800039c8:	02090c63          	beqz	s2,80003a00 <iget+0xac>
  ip->dev = dev;
    800039cc:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    800039d0:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    800039d4:	4785                	li	a5,1
    800039d6:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    800039da:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    800039de:	0001d517          	auipc	a0,0x1d
    800039e2:	96a50513          	addi	a0,a0,-1686 # 80020348 <itable>
    800039e6:	ffffd097          	auipc	ra,0xffffd
    800039ea:	2a4080e7          	jalr	676(ra) # 80000c8a <release>
}
    800039ee:	854a                	mv	a0,s2
    800039f0:	70a2                	ld	ra,40(sp)
    800039f2:	7402                	ld	s0,32(sp)
    800039f4:	64e2                	ld	s1,24(sp)
    800039f6:	6942                	ld	s2,16(sp)
    800039f8:	69a2                	ld	s3,8(sp)
    800039fa:	6a02                	ld	s4,0(sp)
    800039fc:	6145                	addi	sp,sp,48
    800039fe:	8082                	ret
    panic("iget: no inodes");
    80003a00:	00005517          	auipc	a0,0x5
    80003a04:	d2850513          	addi	a0,a0,-728 # 80008728 <syscalls+0x148>
    80003a08:	ffffd097          	auipc	ra,0xffffd
    80003a0c:	b38080e7          	jalr	-1224(ra) # 80000540 <panic>

0000000080003a10 <fsinit>:
fsinit(int dev) {
    80003a10:	7179                	addi	sp,sp,-48
    80003a12:	f406                	sd	ra,40(sp)
    80003a14:	f022                	sd	s0,32(sp)
    80003a16:	ec26                	sd	s1,24(sp)
    80003a18:	e84a                	sd	s2,16(sp)
    80003a1a:	e44e                	sd	s3,8(sp)
    80003a1c:	1800                	addi	s0,sp,48
    80003a1e:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003a20:	4585                	li	a1,1
    80003a22:	00000097          	auipc	ra,0x0
    80003a26:	a54080e7          	jalr	-1452(ra) # 80003476 <bread>
    80003a2a:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003a2c:	0001d997          	auipc	s3,0x1d
    80003a30:	8fc98993          	addi	s3,s3,-1796 # 80020328 <sb>
    80003a34:	02000613          	li	a2,32
    80003a38:	05850593          	addi	a1,a0,88
    80003a3c:	854e                	mv	a0,s3
    80003a3e:	ffffd097          	auipc	ra,0xffffd
    80003a42:	2f0080e7          	jalr	752(ra) # 80000d2e <memmove>
  brelse(bp);
    80003a46:	8526                	mv	a0,s1
    80003a48:	00000097          	auipc	ra,0x0
    80003a4c:	b5e080e7          	jalr	-1186(ra) # 800035a6 <brelse>
  if(sb.magic != FSMAGIC)
    80003a50:	0009a703          	lw	a4,0(s3)
    80003a54:	102037b7          	lui	a5,0x10203
    80003a58:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003a5c:	02f71263          	bne	a4,a5,80003a80 <fsinit+0x70>
  initlog(dev, &sb);
    80003a60:	0001d597          	auipc	a1,0x1d
    80003a64:	8c858593          	addi	a1,a1,-1848 # 80020328 <sb>
    80003a68:	854a                	mv	a0,s2
    80003a6a:	00001097          	auipc	ra,0x1
    80003a6e:	b4a080e7          	jalr	-1206(ra) # 800045b4 <initlog>
}
    80003a72:	70a2                	ld	ra,40(sp)
    80003a74:	7402                	ld	s0,32(sp)
    80003a76:	64e2                	ld	s1,24(sp)
    80003a78:	6942                	ld	s2,16(sp)
    80003a7a:	69a2                	ld	s3,8(sp)
    80003a7c:	6145                	addi	sp,sp,48
    80003a7e:	8082                	ret
    panic("invalid file system");
    80003a80:	00005517          	auipc	a0,0x5
    80003a84:	cb850513          	addi	a0,a0,-840 # 80008738 <syscalls+0x158>
    80003a88:	ffffd097          	auipc	ra,0xffffd
    80003a8c:	ab8080e7          	jalr	-1352(ra) # 80000540 <panic>

0000000080003a90 <iinit>:
{
    80003a90:	7179                	addi	sp,sp,-48
    80003a92:	f406                	sd	ra,40(sp)
    80003a94:	f022                	sd	s0,32(sp)
    80003a96:	ec26                	sd	s1,24(sp)
    80003a98:	e84a                	sd	s2,16(sp)
    80003a9a:	e44e                	sd	s3,8(sp)
    80003a9c:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003a9e:	00005597          	auipc	a1,0x5
    80003aa2:	cb258593          	addi	a1,a1,-846 # 80008750 <syscalls+0x170>
    80003aa6:	0001d517          	auipc	a0,0x1d
    80003aaa:	8a250513          	addi	a0,a0,-1886 # 80020348 <itable>
    80003aae:	ffffd097          	auipc	ra,0xffffd
    80003ab2:	098080e7          	jalr	152(ra) # 80000b46 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003ab6:	0001d497          	auipc	s1,0x1d
    80003aba:	8ba48493          	addi	s1,s1,-1862 # 80020370 <itable+0x28>
    80003abe:	0001e997          	auipc	s3,0x1e
    80003ac2:	34298993          	addi	s3,s3,834 # 80021e00 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003ac6:	00005917          	auipc	s2,0x5
    80003aca:	c9290913          	addi	s2,s2,-878 # 80008758 <syscalls+0x178>
    80003ace:	85ca                	mv	a1,s2
    80003ad0:	8526                	mv	a0,s1
    80003ad2:	00001097          	auipc	ra,0x1
    80003ad6:	e42080e7          	jalr	-446(ra) # 80004914 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003ada:	08848493          	addi	s1,s1,136
    80003ade:	ff3498e3          	bne	s1,s3,80003ace <iinit+0x3e>
}
    80003ae2:	70a2                	ld	ra,40(sp)
    80003ae4:	7402                	ld	s0,32(sp)
    80003ae6:	64e2                	ld	s1,24(sp)
    80003ae8:	6942                	ld	s2,16(sp)
    80003aea:	69a2                	ld	s3,8(sp)
    80003aec:	6145                	addi	sp,sp,48
    80003aee:	8082                	ret

0000000080003af0 <ialloc>:
{
    80003af0:	715d                	addi	sp,sp,-80
    80003af2:	e486                	sd	ra,72(sp)
    80003af4:	e0a2                	sd	s0,64(sp)
    80003af6:	fc26                	sd	s1,56(sp)
    80003af8:	f84a                	sd	s2,48(sp)
    80003afa:	f44e                	sd	s3,40(sp)
    80003afc:	f052                	sd	s4,32(sp)
    80003afe:	ec56                	sd	s5,24(sp)
    80003b00:	e85a                	sd	s6,16(sp)
    80003b02:	e45e                	sd	s7,8(sp)
    80003b04:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003b06:	0001d717          	auipc	a4,0x1d
    80003b0a:	82e72703          	lw	a4,-2002(a4) # 80020334 <sb+0xc>
    80003b0e:	4785                	li	a5,1
    80003b10:	04e7fa63          	bgeu	a5,a4,80003b64 <ialloc+0x74>
    80003b14:	8aaa                	mv	s5,a0
    80003b16:	8bae                	mv	s7,a1
    80003b18:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003b1a:	0001da17          	auipc	s4,0x1d
    80003b1e:	80ea0a13          	addi	s4,s4,-2034 # 80020328 <sb>
    80003b22:	00048b1b          	sext.w	s6,s1
    80003b26:	0044d593          	srli	a1,s1,0x4
    80003b2a:	018a2783          	lw	a5,24(s4)
    80003b2e:	9dbd                	addw	a1,a1,a5
    80003b30:	8556                	mv	a0,s5
    80003b32:	00000097          	auipc	ra,0x0
    80003b36:	944080e7          	jalr	-1724(ra) # 80003476 <bread>
    80003b3a:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003b3c:	05850993          	addi	s3,a0,88
    80003b40:	00f4f793          	andi	a5,s1,15
    80003b44:	079a                	slli	a5,a5,0x6
    80003b46:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003b48:	00099783          	lh	a5,0(s3)
    80003b4c:	c3a1                	beqz	a5,80003b8c <ialloc+0x9c>
    brelse(bp);
    80003b4e:	00000097          	auipc	ra,0x0
    80003b52:	a58080e7          	jalr	-1448(ra) # 800035a6 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003b56:	0485                	addi	s1,s1,1
    80003b58:	00ca2703          	lw	a4,12(s4)
    80003b5c:	0004879b          	sext.w	a5,s1
    80003b60:	fce7e1e3          	bltu	a5,a4,80003b22 <ialloc+0x32>
  printf("ialloc: no inodes\n");
    80003b64:	00005517          	auipc	a0,0x5
    80003b68:	bfc50513          	addi	a0,a0,-1028 # 80008760 <syscalls+0x180>
    80003b6c:	ffffd097          	auipc	ra,0xffffd
    80003b70:	a1e080e7          	jalr	-1506(ra) # 8000058a <printf>
  return 0;
    80003b74:	4501                	li	a0,0
}
    80003b76:	60a6                	ld	ra,72(sp)
    80003b78:	6406                	ld	s0,64(sp)
    80003b7a:	74e2                	ld	s1,56(sp)
    80003b7c:	7942                	ld	s2,48(sp)
    80003b7e:	79a2                	ld	s3,40(sp)
    80003b80:	7a02                	ld	s4,32(sp)
    80003b82:	6ae2                	ld	s5,24(sp)
    80003b84:	6b42                	ld	s6,16(sp)
    80003b86:	6ba2                	ld	s7,8(sp)
    80003b88:	6161                	addi	sp,sp,80
    80003b8a:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    80003b8c:	04000613          	li	a2,64
    80003b90:	4581                	li	a1,0
    80003b92:	854e                	mv	a0,s3
    80003b94:	ffffd097          	auipc	ra,0xffffd
    80003b98:	13e080e7          	jalr	318(ra) # 80000cd2 <memset>
      dip->type = type;
    80003b9c:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003ba0:	854a                	mv	a0,s2
    80003ba2:	00001097          	auipc	ra,0x1
    80003ba6:	c8e080e7          	jalr	-882(ra) # 80004830 <log_write>
      brelse(bp);
    80003baa:	854a                	mv	a0,s2
    80003bac:	00000097          	auipc	ra,0x0
    80003bb0:	9fa080e7          	jalr	-1542(ra) # 800035a6 <brelse>
      return iget(dev, inum);
    80003bb4:	85da                	mv	a1,s6
    80003bb6:	8556                	mv	a0,s5
    80003bb8:	00000097          	auipc	ra,0x0
    80003bbc:	d9c080e7          	jalr	-612(ra) # 80003954 <iget>
    80003bc0:	bf5d                	j	80003b76 <ialloc+0x86>

0000000080003bc2 <iupdate>:
{
    80003bc2:	1101                	addi	sp,sp,-32
    80003bc4:	ec06                	sd	ra,24(sp)
    80003bc6:	e822                	sd	s0,16(sp)
    80003bc8:	e426                	sd	s1,8(sp)
    80003bca:	e04a                	sd	s2,0(sp)
    80003bcc:	1000                	addi	s0,sp,32
    80003bce:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003bd0:	415c                	lw	a5,4(a0)
    80003bd2:	0047d79b          	srliw	a5,a5,0x4
    80003bd6:	0001c597          	auipc	a1,0x1c
    80003bda:	76a5a583          	lw	a1,1898(a1) # 80020340 <sb+0x18>
    80003bde:	9dbd                	addw	a1,a1,a5
    80003be0:	4108                	lw	a0,0(a0)
    80003be2:	00000097          	auipc	ra,0x0
    80003be6:	894080e7          	jalr	-1900(ra) # 80003476 <bread>
    80003bea:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003bec:	05850793          	addi	a5,a0,88
    80003bf0:	40d8                	lw	a4,4(s1)
    80003bf2:	8b3d                	andi	a4,a4,15
    80003bf4:	071a                	slli	a4,a4,0x6
    80003bf6:	97ba                	add	a5,a5,a4
  dip->type = ip->type;
    80003bf8:	04449703          	lh	a4,68(s1)
    80003bfc:	00e79023          	sh	a4,0(a5)
  dip->major = ip->major;
    80003c00:	04649703          	lh	a4,70(s1)
    80003c04:	00e79123          	sh	a4,2(a5)
  dip->minor = ip->minor;
    80003c08:	04849703          	lh	a4,72(s1)
    80003c0c:	00e79223          	sh	a4,4(a5)
  dip->nlink = ip->nlink;
    80003c10:	04a49703          	lh	a4,74(s1)
    80003c14:	00e79323          	sh	a4,6(a5)
  dip->size = ip->size;
    80003c18:	44f8                	lw	a4,76(s1)
    80003c1a:	c798                	sw	a4,8(a5)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003c1c:	03400613          	li	a2,52
    80003c20:	05048593          	addi	a1,s1,80
    80003c24:	00c78513          	addi	a0,a5,12
    80003c28:	ffffd097          	auipc	ra,0xffffd
    80003c2c:	106080e7          	jalr	262(ra) # 80000d2e <memmove>
  log_write(bp);
    80003c30:	854a                	mv	a0,s2
    80003c32:	00001097          	auipc	ra,0x1
    80003c36:	bfe080e7          	jalr	-1026(ra) # 80004830 <log_write>
  brelse(bp);
    80003c3a:	854a                	mv	a0,s2
    80003c3c:	00000097          	auipc	ra,0x0
    80003c40:	96a080e7          	jalr	-1686(ra) # 800035a6 <brelse>
}
    80003c44:	60e2                	ld	ra,24(sp)
    80003c46:	6442                	ld	s0,16(sp)
    80003c48:	64a2                	ld	s1,8(sp)
    80003c4a:	6902                	ld	s2,0(sp)
    80003c4c:	6105                	addi	sp,sp,32
    80003c4e:	8082                	ret

0000000080003c50 <idup>:
{
    80003c50:	1101                	addi	sp,sp,-32
    80003c52:	ec06                	sd	ra,24(sp)
    80003c54:	e822                	sd	s0,16(sp)
    80003c56:	e426                	sd	s1,8(sp)
    80003c58:	1000                	addi	s0,sp,32
    80003c5a:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003c5c:	0001c517          	auipc	a0,0x1c
    80003c60:	6ec50513          	addi	a0,a0,1772 # 80020348 <itable>
    80003c64:	ffffd097          	auipc	ra,0xffffd
    80003c68:	f72080e7          	jalr	-142(ra) # 80000bd6 <acquire>
  ip->ref++;
    80003c6c:	449c                	lw	a5,8(s1)
    80003c6e:	2785                	addiw	a5,a5,1
    80003c70:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003c72:	0001c517          	auipc	a0,0x1c
    80003c76:	6d650513          	addi	a0,a0,1750 # 80020348 <itable>
    80003c7a:	ffffd097          	auipc	ra,0xffffd
    80003c7e:	010080e7          	jalr	16(ra) # 80000c8a <release>
}
    80003c82:	8526                	mv	a0,s1
    80003c84:	60e2                	ld	ra,24(sp)
    80003c86:	6442                	ld	s0,16(sp)
    80003c88:	64a2                	ld	s1,8(sp)
    80003c8a:	6105                	addi	sp,sp,32
    80003c8c:	8082                	ret

0000000080003c8e <ilock>:
{
    80003c8e:	1101                	addi	sp,sp,-32
    80003c90:	ec06                	sd	ra,24(sp)
    80003c92:	e822                	sd	s0,16(sp)
    80003c94:	e426                	sd	s1,8(sp)
    80003c96:	e04a                	sd	s2,0(sp)
    80003c98:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003c9a:	c115                	beqz	a0,80003cbe <ilock+0x30>
    80003c9c:	84aa                	mv	s1,a0
    80003c9e:	451c                	lw	a5,8(a0)
    80003ca0:	00f05f63          	blez	a5,80003cbe <ilock+0x30>
  acquiresleep(&ip->lock);
    80003ca4:	0541                	addi	a0,a0,16
    80003ca6:	00001097          	auipc	ra,0x1
    80003caa:	ca8080e7          	jalr	-856(ra) # 8000494e <acquiresleep>
  if(ip->valid == 0){
    80003cae:	40bc                	lw	a5,64(s1)
    80003cb0:	cf99                	beqz	a5,80003cce <ilock+0x40>
}
    80003cb2:	60e2                	ld	ra,24(sp)
    80003cb4:	6442                	ld	s0,16(sp)
    80003cb6:	64a2                	ld	s1,8(sp)
    80003cb8:	6902                	ld	s2,0(sp)
    80003cba:	6105                	addi	sp,sp,32
    80003cbc:	8082                	ret
    panic("ilock");
    80003cbe:	00005517          	auipc	a0,0x5
    80003cc2:	aba50513          	addi	a0,a0,-1350 # 80008778 <syscalls+0x198>
    80003cc6:	ffffd097          	auipc	ra,0xffffd
    80003cca:	87a080e7          	jalr	-1926(ra) # 80000540 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003cce:	40dc                	lw	a5,4(s1)
    80003cd0:	0047d79b          	srliw	a5,a5,0x4
    80003cd4:	0001c597          	auipc	a1,0x1c
    80003cd8:	66c5a583          	lw	a1,1644(a1) # 80020340 <sb+0x18>
    80003cdc:	9dbd                	addw	a1,a1,a5
    80003cde:	4088                	lw	a0,0(s1)
    80003ce0:	fffff097          	auipc	ra,0xfffff
    80003ce4:	796080e7          	jalr	1942(ra) # 80003476 <bread>
    80003ce8:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003cea:	05850593          	addi	a1,a0,88
    80003cee:	40dc                	lw	a5,4(s1)
    80003cf0:	8bbd                	andi	a5,a5,15
    80003cf2:	079a                	slli	a5,a5,0x6
    80003cf4:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003cf6:	00059783          	lh	a5,0(a1)
    80003cfa:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003cfe:	00259783          	lh	a5,2(a1)
    80003d02:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003d06:	00459783          	lh	a5,4(a1)
    80003d0a:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003d0e:	00659783          	lh	a5,6(a1)
    80003d12:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003d16:	459c                	lw	a5,8(a1)
    80003d18:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003d1a:	03400613          	li	a2,52
    80003d1e:	05b1                	addi	a1,a1,12
    80003d20:	05048513          	addi	a0,s1,80
    80003d24:	ffffd097          	auipc	ra,0xffffd
    80003d28:	00a080e7          	jalr	10(ra) # 80000d2e <memmove>
    brelse(bp);
    80003d2c:	854a                	mv	a0,s2
    80003d2e:	00000097          	auipc	ra,0x0
    80003d32:	878080e7          	jalr	-1928(ra) # 800035a6 <brelse>
    ip->valid = 1;
    80003d36:	4785                	li	a5,1
    80003d38:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003d3a:	04449783          	lh	a5,68(s1)
    80003d3e:	fbb5                	bnez	a5,80003cb2 <ilock+0x24>
      panic("ilock: no type");
    80003d40:	00005517          	auipc	a0,0x5
    80003d44:	a4050513          	addi	a0,a0,-1472 # 80008780 <syscalls+0x1a0>
    80003d48:	ffffc097          	auipc	ra,0xffffc
    80003d4c:	7f8080e7          	jalr	2040(ra) # 80000540 <panic>

0000000080003d50 <iunlock>:
{
    80003d50:	1101                	addi	sp,sp,-32
    80003d52:	ec06                	sd	ra,24(sp)
    80003d54:	e822                	sd	s0,16(sp)
    80003d56:	e426                	sd	s1,8(sp)
    80003d58:	e04a                	sd	s2,0(sp)
    80003d5a:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003d5c:	c905                	beqz	a0,80003d8c <iunlock+0x3c>
    80003d5e:	84aa                	mv	s1,a0
    80003d60:	01050913          	addi	s2,a0,16
    80003d64:	854a                	mv	a0,s2
    80003d66:	00001097          	auipc	ra,0x1
    80003d6a:	c82080e7          	jalr	-894(ra) # 800049e8 <holdingsleep>
    80003d6e:	cd19                	beqz	a0,80003d8c <iunlock+0x3c>
    80003d70:	449c                	lw	a5,8(s1)
    80003d72:	00f05d63          	blez	a5,80003d8c <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003d76:	854a                	mv	a0,s2
    80003d78:	00001097          	auipc	ra,0x1
    80003d7c:	c2c080e7          	jalr	-980(ra) # 800049a4 <releasesleep>
}
    80003d80:	60e2                	ld	ra,24(sp)
    80003d82:	6442                	ld	s0,16(sp)
    80003d84:	64a2                	ld	s1,8(sp)
    80003d86:	6902                	ld	s2,0(sp)
    80003d88:	6105                	addi	sp,sp,32
    80003d8a:	8082                	ret
    panic("iunlock");
    80003d8c:	00005517          	auipc	a0,0x5
    80003d90:	a0450513          	addi	a0,a0,-1532 # 80008790 <syscalls+0x1b0>
    80003d94:	ffffc097          	auipc	ra,0xffffc
    80003d98:	7ac080e7          	jalr	1964(ra) # 80000540 <panic>

0000000080003d9c <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003d9c:	7179                	addi	sp,sp,-48
    80003d9e:	f406                	sd	ra,40(sp)
    80003da0:	f022                	sd	s0,32(sp)
    80003da2:	ec26                	sd	s1,24(sp)
    80003da4:	e84a                	sd	s2,16(sp)
    80003da6:	e44e                	sd	s3,8(sp)
    80003da8:	e052                	sd	s4,0(sp)
    80003daa:	1800                	addi	s0,sp,48
    80003dac:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003dae:	05050493          	addi	s1,a0,80
    80003db2:	08050913          	addi	s2,a0,128
    80003db6:	a021                	j	80003dbe <itrunc+0x22>
    80003db8:	0491                	addi	s1,s1,4
    80003dba:	01248d63          	beq	s1,s2,80003dd4 <itrunc+0x38>
    if(ip->addrs[i]){
    80003dbe:	408c                	lw	a1,0(s1)
    80003dc0:	dde5                	beqz	a1,80003db8 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003dc2:	0009a503          	lw	a0,0(s3)
    80003dc6:	00000097          	auipc	ra,0x0
    80003dca:	8f6080e7          	jalr	-1802(ra) # 800036bc <bfree>
      ip->addrs[i] = 0;
    80003dce:	0004a023          	sw	zero,0(s1)
    80003dd2:	b7dd                	j	80003db8 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003dd4:	0809a583          	lw	a1,128(s3)
    80003dd8:	e185                	bnez	a1,80003df8 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003dda:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003dde:	854e                	mv	a0,s3
    80003de0:	00000097          	auipc	ra,0x0
    80003de4:	de2080e7          	jalr	-542(ra) # 80003bc2 <iupdate>
}
    80003de8:	70a2                	ld	ra,40(sp)
    80003dea:	7402                	ld	s0,32(sp)
    80003dec:	64e2                	ld	s1,24(sp)
    80003dee:	6942                	ld	s2,16(sp)
    80003df0:	69a2                	ld	s3,8(sp)
    80003df2:	6a02                	ld	s4,0(sp)
    80003df4:	6145                	addi	sp,sp,48
    80003df6:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003df8:	0009a503          	lw	a0,0(s3)
    80003dfc:	fffff097          	auipc	ra,0xfffff
    80003e00:	67a080e7          	jalr	1658(ra) # 80003476 <bread>
    80003e04:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003e06:	05850493          	addi	s1,a0,88
    80003e0a:	45850913          	addi	s2,a0,1112
    80003e0e:	a021                	j	80003e16 <itrunc+0x7a>
    80003e10:	0491                	addi	s1,s1,4
    80003e12:	01248b63          	beq	s1,s2,80003e28 <itrunc+0x8c>
      if(a[j])
    80003e16:	408c                	lw	a1,0(s1)
    80003e18:	dde5                	beqz	a1,80003e10 <itrunc+0x74>
        bfree(ip->dev, a[j]);
    80003e1a:	0009a503          	lw	a0,0(s3)
    80003e1e:	00000097          	auipc	ra,0x0
    80003e22:	89e080e7          	jalr	-1890(ra) # 800036bc <bfree>
    80003e26:	b7ed                	j	80003e10 <itrunc+0x74>
    brelse(bp);
    80003e28:	8552                	mv	a0,s4
    80003e2a:	fffff097          	auipc	ra,0xfffff
    80003e2e:	77c080e7          	jalr	1916(ra) # 800035a6 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003e32:	0809a583          	lw	a1,128(s3)
    80003e36:	0009a503          	lw	a0,0(s3)
    80003e3a:	00000097          	auipc	ra,0x0
    80003e3e:	882080e7          	jalr	-1918(ra) # 800036bc <bfree>
    ip->addrs[NDIRECT] = 0;
    80003e42:	0809a023          	sw	zero,128(s3)
    80003e46:	bf51                	j	80003dda <itrunc+0x3e>

0000000080003e48 <iput>:
{
    80003e48:	1101                	addi	sp,sp,-32
    80003e4a:	ec06                	sd	ra,24(sp)
    80003e4c:	e822                	sd	s0,16(sp)
    80003e4e:	e426                	sd	s1,8(sp)
    80003e50:	e04a                	sd	s2,0(sp)
    80003e52:	1000                	addi	s0,sp,32
    80003e54:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003e56:	0001c517          	auipc	a0,0x1c
    80003e5a:	4f250513          	addi	a0,a0,1266 # 80020348 <itable>
    80003e5e:	ffffd097          	auipc	ra,0xffffd
    80003e62:	d78080e7          	jalr	-648(ra) # 80000bd6 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003e66:	4498                	lw	a4,8(s1)
    80003e68:	4785                	li	a5,1
    80003e6a:	02f70363          	beq	a4,a5,80003e90 <iput+0x48>
  ip->ref--;
    80003e6e:	449c                	lw	a5,8(s1)
    80003e70:	37fd                	addiw	a5,a5,-1
    80003e72:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003e74:	0001c517          	auipc	a0,0x1c
    80003e78:	4d450513          	addi	a0,a0,1236 # 80020348 <itable>
    80003e7c:	ffffd097          	auipc	ra,0xffffd
    80003e80:	e0e080e7          	jalr	-498(ra) # 80000c8a <release>
}
    80003e84:	60e2                	ld	ra,24(sp)
    80003e86:	6442                	ld	s0,16(sp)
    80003e88:	64a2                	ld	s1,8(sp)
    80003e8a:	6902                	ld	s2,0(sp)
    80003e8c:	6105                	addi	sp,sp,32
    80003e8e:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003e90:	40bc                	lw	a5,64(s1)
    80003e92:	dff1                	beqz	a5,80003e6e <iput+0x26>
    80003e94:	04a49783          	lh	a5,74(s1)
    80003e98:	fbf9                	bnez	a5,80003e6e <iput+0x26>
    acquiresleep(&ip->lock);
    80003e9a:	01048913          	addi	s2,s1,16
    80003e9e:	854a                	mv	a0,s2
    80003ea0:	00001097          	auipc	ra,0x1
    80003ea4:	aae080e7          	jalr	-1362(ra) # 8000494e <acquiresleep>
    release(&itable.lock);
    80003ea8:	0001c517          	auipc	a0,0x1c
    80003eac:	4a050513          	addi	a0,a0,1184 # 80020348 <itable>
    80003eb0:	ffffd097          	auipc	ra,0xffffd
    80003eb4:	dda080e7          	jalr	-550(ra) # 80000c8a <release>
    itrunc(ip);
    80003eb8:	8526                	mv	a0,s1
    80003eba:	00000097          	auipc	ra,0x0
    80003ebe:	ee2080e7          	jalr	-286(ra) # 80003d9c <itrunc>
    ip->type = 0;
    80003ec2:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003ec6:	8526                	mv	a0,s1
    80003ec8:	00000097          	auipc	ra,0x0
    80003ecc:	cfa080e7          	jalr	-774(ra) # 80003bc2 <iupdate>
    ip->valid = 0;
    80003ed0:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003ed4:	854a                	mv	a0,s2
    80003ed6:	00001097          	auipc	ra,0x1
    80003eda:	ace080e7          	jalr	-1330(ra) # 800049a4 <releasesleep>
    acquire(&itable.lock);
    80003ede:	0001c517          	auipc	a0,0x1c
    80003ee2:	46a50513          	addi	a0,a0,1130 # 80020348 <itable>
    80003ee6:	ffffd097          	auipc	ra,0xffffd
    80003eea:	cf0080e7          	jalr	-784(ra) # 80000bd6 <acquire>
    80003eee:	b741                	j	80003e6e <iput+0x26>

0000000080003ef0 <iunlockput>:
{
    80003ef0:	1101                	addi	sp,sp,-32
    80003ef2:	ec06                	sd	ra,24(sp)
    80003ef4:	e822                	sd	s0,16(sp)
    80003ef6:	e426                	sd	s1,8(sp)
    80003ef8:	1000                	addi	s0,sp,32
    80003efa:	84aa                	mv	s1,a0
  iunlock(ip);
    80003efc:	00000097          	auipc	ra,0x0
    80003f00:	e54080e7          	jalr	-428(ra) # 80003d50 <iunlock>
  iput(ip);
    80003f04:	8526                	mv	a0,s1
    80003f06:	00000097          	auipc	ra,0x0
    80003f0a:	f42080e7          	jalr	-190(ra) # 80003e48 <iput>
}
    80003f0e:	60e2                	ld	ra,24(sp)
    80003f10:	6442                	ld	s0,16(sp)
    80003f12:	64a2                	ld	s1,8(sp)
    80003f14:	6105                	addi	sp,sp,32
    80003f16:	8082                	ret

0000000080003f18 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003f18:	1141                	addi	sp,sp,-16
    80003f1a:	e422                	sd	s0,8(sp)
    80003f1c:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003f1e:	411c                	lw	a5,0(a0)
    80003f20:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003f22:	415c                	lw	a5,4(a0)
    80003f24:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003f26:	04451783          	lh	a5,68(a0)
    80003f2a:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003f2e:	04a51783          	lh	a5,74(a0)
    80003f32:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003f36:	04c56783          	lwu	a5,76(a0)
    80003f3a:	e99c                	sd	a5,16(a1)
}
    80003f3c:	6422                	ld	s0,8(sp)
    80003f3e:	0141                	addi	sp,sp,16
    80003f40:	8082                	ret

0000000080003f42 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003f42:	457c                	lw	a5,76(a0)
    80003f44:	0ed7e963          	bltu	a5,a3,80004036 <readi+0xf4>
{
    80003f48:	7159                	addi	sp,sp,-112
    80003f4a:	f486                	sd	ra,104(sp)
    80003f4c:	f0a2                	sd	s0,96(sp)
    80003f4e:	eca6                	sd	s1,88(sp)
    80003f50:	e8ca                	sd	s2,80(sp)
    80003f52:	e4ce                	sd	s3,72(sp)
    80003f54:	e0d2                	sd	s4,64(sp)
    80003f56:	fc56                	sd	s5,56(sp)
    80003f58:	f85a                	sd	s6,48(sp)
    80003f5a:	f45e                	sd	s7,40(sp)
    80003f5c:	f062                	sd	s8,32(sp)
    80003f5e:	ec66                	sd	s9,24(sp)
    80003f60:	e86a                	sd	s10,16(sp)
    80003f62:	e46e                	sd	s11,8(sp)
    80003f64:	1880                	addi	s0,sp,112
    80003f66:	8b2a                	mv	s6,a0
    80003f68:	8bae                	mv	s7,a1
    80003f6a:	8a32                	mv	s4,a2
    80003f6c:	84b6                	mv	s1,a3
    80003f6e:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    80003f70:	9f35                	addw	a4,a4,a3
    return 0;
    80003f72:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003f74:	0ad76063          	bltu	a4,a3,80004014 <readi+0xd2>
  if(off + n > ip->size)
    80003f78:	00e7f463          	bgeu	a5,a4,80003f80 <readi+0x3e>
    n = ip->size - off;
    80003f7c:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003f80:	0a0a8963          	beqz	s5,80004032 <readi+0xf0>
    80003f84:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003f86:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003f8a:	5c7d                	li	s8,-1
    80003f8c:	a82d                	j	80003fc6 <readi+0x84>
    80003f8e:	020d1d93          	slli	s11,s10,0x20
    80003f92:	020ddd93          	srli	s11,s11,0x20
    80003f96:	05890613          	addi	a2,s2,88
    80003f9a:	86ee                	mv	a3,s11
    80003f9c:	963a                	add	a2,a2,a4
    80003f9e:	85d2                	mv	a1,s4
    80003fa0:	855e                	mv	a0,s7
    80003fa2:	ffffe097          	auipc	ra,0xffffe
    80003fa6:	7f8080e7          	jalr	2040(ra) # 8000279a <either_copyout>
    80003faa:	05850d63          	beq	a0,s8,80004004 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003fae:	854a                	mv	a0,s2
    80003fb0:	fffff097          	auipc	ra,0xfffff
    80003fb4:	5f6080e7          	jalr	1526(ra) # 800035a6 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003fb8:	013d09bb          	addw	s3,s10,s3
    80003fbc:	009d04bb          	addw	s1,s10,s1
    80003fc0:	9a6e                	add	s4,s4,s11
    80003fc2:	0559f763          	bgeu	s3,s5,80004010 <readi+0xce>
    uint addr = bmap(ip, off/BSIZE);
    80003fc6:	00a4d59b          	srliw	a1,s1,0xa
    80003fca:	855a                	mv	a0,s6
    80003fcc:	00000097          	auipc	ra,0x0
    80003fd0:	89e080e7          	jalr	-1890(ra) # 8000386a <bmap>
    80003fd4:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003fd8:	cd85                	beqz	a1,80004010 <readi+0xce>
    bp = bread(ip->dev, addr);
    80003fda:	000b2503          	lw	a0,0(s6)
    80003fde:	fffff097          	auipc	ra,0xfffff
    80003fe2:	498080e7          	jalr	1176(ra) # 80003476 <bread>
    80003fe6:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003fe8:	3ff4f713          	andi	a4,s1,1023
    80003fec:	40ec87bb          	subw	a5,s9,a4
    80003ff0:	413a86bb          	subw	a3,s5,s3
    80003ff4:	8d3e                	mv	s10,a5
    80003ff6:	2781                	sext.w	a5,a5
    80003ff8:	0006861b          	sext.w	a2,a3
    80003ffc:	f8f679e3          	bgeu	a2,a5,80003f8e <readi+0x4c>
    80004000:	8d36                	mv	s10,a3
    80004002:	b771                	j	80003f8e <readi+0x4c>
      brelse(bp);
    80004004:	854a                	mv	a0,s2
    80004006:	fffff097          	auipc	ra,0xfffff
    8000400a:	5a0080e7          	jalr	1440(ra) # 800035a6 <brelse>
      tot = -1;
    8000400e:	59fd                	li	s3,-1
  }
  return tot;
    80004010:	0009851b          	sext.w	a0,s3
}
    80004014:	70a6                	ld	ra,104(sp)
    80004016:	7406                	ld	s0,96(sp)
    80004018:	64e6                	ld	s1,88(sp)
    8000401a:	6946                	ld	s2,80(sp)
    8000401c:	69a6                	ld	s3,72(sp)
    8000401e:	6a06                	ld	s4,64(sp)
    80004020:	7ae2                	ld	s5,56(sp)
    80004022:	7b42                	ld	s6,48(sp)
    80004024:	7ba2                	ld	s7,40(sp)
    80004026:	7c02                	ld	s8,32(sp)
    80004028:	6ce2                	ld	s9,24(sp)
    8000402a:	6d42                	ld	s10,16(sp)
    8000402c:	6da2                	ld	s11,8(sp)
    8000402e:	6165                	addi	sp,sp,112
    80004030:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80004032:	89d6                	mv	s3,s5
    80004034:	bff1                	j	80004010 <readi+0xce>
    return 0;
    80004036:	4501                	li	a0,0
}
    80004038:	8082                	ret

000000008000403a <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    8000403a:	457c                	lw	a5,76(a0)
    8000403c:	10d7e863          	bltu	a5,a3,8000414c <writei+0x112>
{
    80004040:	7159                	addi	sp,sp,-112
    80004042:	f486                	sd	ra,104(sp)
    80004044:	f0a2                	sd	s0,96(sp)
    80004046:	eca6                	sd	s1,88(sp)
    80004048:	e8ca                	sd	s2,80(sp)
    8000404a:	e4ce                	sd	s3,72(sp)
    8000404c:	e0d2                	sd	s4,64(sp)
    8000404e:	fc56                	sd	s5,56(sp)
    80004050:	f85a                	sd	s6,48(sp)
    80004052:	f45e                	sd	s7,40(sp)
    80004054:	f062                	sd	s8,32(sp)
    80004056:	ec66                	sd	s9,24(sp)
    80004058:	e86a                	sd	s10,16(sp)
    8000405a:	e46e                	sd	s11,8(sp)
    8000405c:	1880                	addi	s0,sp,112
    8000405e:	8aaa                	mv	s5,a0
    80004060:	8bae                	mv	s7,a1
    80004062:	8a32                	mv	s4,a2
    80004064:	8936                	mv	s2,a3
    80004066:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80004068:	00e687bb          	addw	a5,a3,a4
    8000406c:	0ed7e263          	bltu	a5,a3,80004150 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80004070:	00043737          	lui	a4,0x43
    80004074:	0ef76063          	bltu	a4,a5,80004154 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004078:	0c0b0863          	beqz	s6,80004148 <writei+0x10e>
    8000407c:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    8000407e:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80004082:	5c7d                	li	s8,-1
    80004084:	a091                	j	800040c8 <writei+0x8e>
    80004086:	020d1d93          	slli	s11,s10,0x20
    8000408a:	020ddd93          	srli	s11,s11,0x20
    8000408e:	05848513          	addi	a0,s1,88
    80004092:	86ee                	mv	a3,s11
    80004094:	8652                	mv	a2,s4
    80004096:	85de                	mv	a1,s7
    80004098:	953a                	add	a0,a0,a4
    8000409a:	ffffe097          	auipc	ra,0xffffe
    8000409e:	756080e7          	jalr	1878(ra) # 800027f0 <either_copyin>
    800040a2:	07850263          	beq	a0,s8,80004106 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    800040a6:	8526                	mv	a0,s1
    800040a8:	00000097          	auipc	ra,0x0
    800040ac:	788080e7          	jalr	1928(ra) # 80004830 <log_write>
    brelse(bp);
    800040b0:	8526                	mv	a0,s1
    800040b2:	fffff097          	auipc	ra,0xfffff
    800040b6:	4f4080e7          	jalr	1268(ra) # 800035a6 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800040ba:	013d09bb          	addw	s3,s10,s3
    800040be:	012d093b          	addw	s2,s10,s2
    800040c2:	9a6e                	add	s4,s4,s11
    800040c4:	0569f663          	bgeu	s3,s6,80004110 <writei+0xd6>
    uint addr = bmap(ip, off/BSIZE);
    800040c8:	00a9559b          	srliw	a1,s2,0xa
    800040cc:	8556                	mv	a0,s5
    800040ce:	fffff097          	auipc	ra,0xfffff
    800040d2:	79c080e7          	jalr	1948(ra) # 8000386a <bmap>
    800040d6:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    800040da:	c99d                	beqz	a1,80004110 <writei+0xd6>
    bp = bread(ip->dev, addr);
    800040dc:	000aa503          	lw	a0,0(s5)
    800040e0:	fffff097          	auipc	ra,0xfffff
    800040e4:	396080e7          	jalr	918(ra) # 80003476 <bread>
    800040e8:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    800040ea:	3ff97713          	andi	a4,s2,1023
    800040ee:	40ec87bb          	subw	a5,s9,a4
    800040f2:	413b06bb          	subw	a3,s6,s3
    800040f6:	8d3e                	mv	s10,a5
    800040f8:	2781                	sext.w	a5,a5
    800040fa:	0006861b          	sext.w	a2,a3
    800040fe:	f8f674e3          	bgeu	a2,a5,80004086 <writei+0x4c>
    80004102:	8d36                	mv	s10,a3
    80004104:	b749                	j	80004086 <writei+0x4c>
      brelse(bp);
    80004106:	8526                	mv	a0,s1
    80004108:	fffff097          	auipc	ra,0xfffff
    8000410c:	49e080e7          	jalr	1182(ra) # 800035a6 <brelse>
  }

  if(off > ip->size)
    80004110:	04caa783          	lw	a5,76(s5)
    80004114:	0127f463          	bgeu	a5,s2,8000411c <writei+0xe2>
    ip->size = off;
    80004118:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    8000411c:	8556                	mv	a0,s5
    8000411e:	00000097          	auipc	ra,0x0
    80004122:	aa4080e7          	jalr	-1372(ra) # 80003bc2 <iupdate>

  return tot;
    80004126:	0009851b          	sext.w	a0,s3
}
    8000412a:	70a6                	ld	ra,104(sp)
    8000412c:	7406                	ld	s0,96(sp)
    8000412e:	64e6                	ld	s1,88(sp)
    80004130:	6946                	ld	s2,80(sp)
    80004132:	69a6                	ld	s3,72(sp)
    80004134:	6a06                	ld	s4,64(sp)
    80004136:	7ae2                	ld	s5,56(sp)
    80004138:	7b42                	ld	s6,48(sp)
    8000413a:	7ba2                	ld	s7,40(sp)
    8000413c:	7c02                	ld	s8,32(sp)
    8000413e:	6ce2                	ld	s9,24(sp)
    80004140:	6d42                	ld	s10,16(sp)
    80004142:	6da2                	ld	s11,8(sp)
    80004144:	6165                	addi	sp,sp,112
    80004146:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004148:	89da                	mv	s3,s6
    8000414a:	bfc9                	j	8000411c <writei+0xe2>
    return -1;
    8000414c:	557d                	li	a0,-1
}
    8000414e:	8082                	ret
    return -1;
    80004150:	557d                	li	a0,-1
    80004152:	bfe1                	j	8000412a <writei+0xf0>
    return -1;
    80004154:	557d                	li	a0,-1
    80004156:	bfd1                	j	8000412a <writei+0xf0>

0000000080004158 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80004158:	1141                	addi	sp,sp,-16
    8000415a:	e406                	sd	ra,8(sp)
    8000415c:	e022                	sd	s0,0(sp)
    8000415e:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80004160:	4639                	li	a2,14
    80004162:	ffffd097          	auipc	ra,0xffffd
    80004166:	c40080e7          	jalr	-960(ra) # 80000da2 <strncmp>
}
    8000416a:	60a2                	ld	ra,8(sp)
    8000416c:	6402                	ld	s0,0(sp)
    8000416e:	0141                	addi	sp,sp,16
    80004170:	8082                	ret

0000000080004172 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80004172:	7139                	addi	sp,sp,-64
    80004174:	fc06                	sd	ra,56(sp)
    80004176:	f822                	sd	s0,48(sp)
    80004178:	f426                	sd	s1,40(sp)
    8000417a:	f04a                	sd	s2,32(sp)
    8000417c:	ec4e                	sd	s3,24(sp)
    8000417e:	e852                	sd	s4,16(sp)
    80004180:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80004182:	04451703          	lh	a4,68(a0)
    80004186:	4785                	li	a5,1
    80004188:	00f71a63          	bne	a4,a5,8000419c <dirlookup+0x2a>
    8000418c:	892a                	mv	s2,a0
    8000418e:	89ae                	mv	s3,a1
    80004190:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80004192:	457c                	lw	a5,76(a0)
    80004194:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80004196:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004198:	e79d                	bnez	a5,800041c6 <dirlookup+0x54>
    8000419a:	a8a5                	j	80004212 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    8000419c:	00004517          	auipc	a0,0x4
    800041a0:	5fc50513          	addi	a0,a0,1532 # 80008798 <syscalls+0x1b8>
    800041a4:	ffffc097          	auipc	ra,0xffffc
    800041a8:	39c080e7          	jalr	924(ra) # 80000540 <panic>
      panic("dirlookup read");
    800041ac:	00004517          	auipc	a0,0x4
    800041b0:	60450513          	addi	a0,a0,1540 # 800087b0 <syscalls+0x1d0>
    800041b4:	ffffc097          	auipc	ra,0xffffc
    800041b8:	38c080e7          	jalr	908(ra) # 80000540 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800041bc:	24c1                	addiw	s1,s1,16
    800041be:	04c92783          	lw	a5,76(s2)
    800041c2:	04f4f763          	bgeu	s1,a5,80004210 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800041c6:	4741                	li	a4,16
    800041c8:	86a6                	mv	a3,s1
    800041ca:	fc040613          	addi	a2,s0,-64
    800041ce:	4581                	li	a1,0
    800041d0:	854a                	mv	a0,s2
    800041d2:	00000097          	auipc	ra,0x0
    800041d6:	d70080e7          	jalr	-656(ra) # 80003f42 <readi>
    800041da:	47c1                	li	a5,16
    800041dc:	fcf518e3          	bne	a0,a5,800041ac <dirlookup+0x3a>
    if(de.inum == 0)
    800041e0:	fc045783          	lhu	a5,-64(s0)
    800041e4:	dfe1                	beqz	a5,800041bc <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    800041e6:	fc240593          	addi	a1,s0,-62
    800041ea:	854e                	mv	a0,s3
    800041ec:	00000097          	auipc	ra,0x0
    800041f0:	f6c080e7          	jalr	-148(ra) # 80004158 <namecmp>
    800041f4:	f561                	bnez	a0,800041bc <dirlookup+0x4a>
      if(poff)
    800041f6:	000a0463          	beqz	s4,800041fe <dirlookup+0x8c>
        *poff = off;
    800041fa:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    800041fe:	fc045583          	lhu	a1,-64(s0)
    80004202:	00092503          	lw	a0,0(s2)
    80004206:	fffff097          	auipc	ra,0xfffff
    8000420a:	74e080e7          	jalr	1870(ra) # 80003954 <iget>
    8000420e:	a011                	j	80004212 <dirlookup+0xa0>
  return 0;
    80004210:	4501                	li	a0,0
}
    80004212:	70e2                	ld	ra,56(sp)
    80004214:	7442                	ld	s0,48(sp)
    80004216:	74a2                	ld	s1,40(sp)
    80004218:	7902                	ld	s2,32(sp)
    8000421a:	69e2                	ld	s3,24(sp)
    8000421c:	6a42                	ld	s4,16(sp)
    8000421e:	6121                	addi	sp,sp,64
    80004220:	8082                	ret

0000000080004222 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80004222:	711d                	addi	sp,sp,-96
    80004224:	ec86                	sd	ra,88(sp)
    80004226:	e8a2                	sd	s0,80(sp)
    80004228:	e4a6                	sd	s1,72(sp)
    8000422a:	e0ca                	sd	s2,64(sp)
    8000422c:	fc4e                	sd	s3,56(sp)
    8000422e:	f852                	sd	s4,48(sp)
    80004230:	f456                	sd	s5,40(sp)
    80004232:	f05a                	sd	s6,32(sp)
    80004234:	ec5e                	sd	s7,24(sp)
    80004236:	e862                	sd	s8,16(sp)
    80004238:	e466                	sd	s9,8(sp)
    8000423a:	e06a                	sd	s10,0(sp)
    8000423c:	1080                	addi	s0,sp,96
    8000423e:	84aa                	mv	s1,a0
    80004240:	8b2e                	mv	s6,a1
    80004242:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80004244:	00054703          	lbu	a4,0(a0)
    80004248:	02f00793          	li	a5,47
    8000424c:	02f70363          	beq	a4,a5,80004272 <namex+0x50>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80004250:	ffffd097          	auipc	ra,0xffffd
    80004254:	75c080e7          	jalr	1884(ra) # 800019ac <myproc>
    80004258:	15053503          	ld	a0,336(a0)
    8000425c:	00000097          	auipc	ra,0x0
    80004260:	9f4080e7          	jalr	-1548(ra) # 80003c50 <idup>
    80004264:	8a2a                	mv	s4,a0
  while(*path == '/')
    80004266:	02f00913          	li	s2,47
  if(len >= DIRSIZ)
    8000426a:	4cb5                	li	s9,13
  len = path - s;
    8000426c:	4b81                	li	s7,0

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    8000426e:	4c05                	li	s8,1
    80004270:	a87d                	j	8000432e <namex+0x10c>
    ip = iget(ROOTDEV, ROOTINO);
    80004272:	4585                	li	a1,1
    80004274:	4505                	li	a0,1
    80004276:	fffff097          	auipc	ra,0xfffff
    8000427a:	6de080e7          	jalr	1758(ra) # 80003954 <iget>
    8000427e:	8a2a                	mv	s4,a0
    80004280:	b7dd                	j	80004266 <namex+0x44>
      iunlockput(ip);
    80004282:	8552                	mv	a0,s4
    80004284:	00000097          	auipc	ra,0x0
    80004288:	c6c080e7          	jalr	-916(ra) # 80003ef0 <iunlockput>
      return 0;
    8000428c:	4a01                	li	s4,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    8000428e:	8552                	mv	a0,s4
    80004290:	60e6                	ld	ra,88(sp)
    80004292:	6446                	ld	s0,80(sp)
    80004294:	64a6                	ld	s1,72(sp)
    80004296:	6906                	ld	s2,64(sp)
    80004298:	79e2                	ld	s3,56(sp)
    8000429a:	7a42                	ld	s4,48(sp)
    8000429c:	7aa2                	ld	s5,40(sp)
    8000429e:	7b02                	ld	s6,32(sp)
    800042a0:	6be2                	ld	s7,24(sp)
    800042a2:	6c42                	ld	s8,16(sp)
    800042a4:	6ca2                	ld	s9,8(sp)
    800042a6:	6d02                	ld	s10,0(sp)
    800042a8:	6125                	addi	sp,sp,96
    800042aa:	8082                	ret
      iunlock(ip);
    800042ac:	8552                	mv	a0,s4
    800042ae:	00000097          	auipc	ra,0x0
    800042b2:	aa2080e7          	jalr	-1374(ra) # 80003d50 <iunlock>
      return ip;
    800042b6:	bfe1                	j	8000428e <namex+0x6c>
      iunlockput(ip);
    800042b8:	8552                	mv	a0,s4
    800042ba:	00000097          	auipc	ra,0x0
    800042be:	c36080e7          	jalr	-970(ra) # 80003ef0 <iunlockput>
      return 0;
    800042c2:	8a4e                	mv	s4,s3
    800042c4:	b7e9                	j	8000428e <namex+0x6c>
  len = path - s;
    800042c6:	40998633          	sub	a2,s3,s1
    800042ca:	00060d1b          	sext.w	s10,a2
  if(len >= DIRSIZ)
    800042ce:	09acd863          	bge	s9,s10,8000435e <namex+0x13c>
    memmove(name, s, DIRSIZ);
    800042d2:	4639                	li	a2,14
    800042d4:	85a6                	mv	a1,s1
    800042d6:	8556                	mv	a0,s5
    800042d8:	ffffd097          	auipc	ra,0xffffd
    800042dc:	a56080e7          	jalr	-1450(ra) # 80000d2e <memmove>
    800042e0:	84ce                	mv	s1,s3
  while(*path == '/')
    800042e2:	0004c783          	lbu	a5,0(s1)
    800042e6:	01279763          	bne	a5,s2,800042f4 <namex+0xd2>
    path++;
    800042ea:	0485                	addi	s1,s1,1
  while(*path == '/')
    800042ec:	0004c783          	lbu	a5,0(s1)
    800042f0:	ff278de3          	beq	a5,s2,800042ea <namex+0xc8>
    ilock(ip);
    800042f4:	8552                	mv	a0,s4
    800042f6:	00000097          	auipc	ra,0x0
    800042fa:	998080e7          	jalr	-1640(ra) # 80003c8e <ilock>
    if(ip->type != T_DIR){
    800042fe:	044a1783          	lh	a5,68(s4)
    80004302:	f98790e3          	bne	a5,s8,80004282 <namex+0x60>
    if(nameiparent && *path == '\0'){
    80004306:	000b0563          	beqz	s6,80004310 <namex+0xee>
    8000430a:	0004c783          	lbu	a5,0(s1)
    8000430e:	dfd9                	beqz	a5,800042ac <namex+0x8a>
    if((next = dirlookup(ip, name, 0)) == 0){
    80004310:	865e                	mv	a2,s7
    80004312:	85d6                	mv	a1,s5
    80004314:	8552                	mv	a0,s4
    80004316:	00000097          	auipc	ra,0x0
    8000431a:	e5c080e7          	jalr	-420(ra) # 80004172 <dirlookup>
    8000431e:	89aa                	mv	s3,a0
    80004320:	dd41                	beqz	a0,800042b8 <namex+0x96>
    iunlockput(ip);
    80004322:	8552                	mv	a0,s4
    80004324:	00000097          	auipc	ra,0x0
    80004328:	bcc080e7          	jalr	-1076(ra) # 80003ef0 <iunlockput>
    ip = next;
    8000432c:	8a4e                	mv	s4,s3
  while(*path == '/')
    8000432e:	0004c783          	lbu	a5,0(s1)
    80004332:	01279763          	bne	a5,s2,80004340 <namex+0x11e>
    path++;
    80004336:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004338:	0004c783          	lbu	a5,0(s1)
    8000433c:	ff278de3          	beq	a5,s2,80004336 <namex+0x114>
  if(*path == 0)
    80004340:	cb9d                	beqz	a5,80004376 <namex+0x154>
  while(*path != '/' && *path != 0)
    80004342:	0004c783          	lbu	a5,0(s1)
    80004346:	89a6                	mv	s3,s1
  len = path - s;
    80004348:	8d5e                	mv	s10,s7
    8000434a:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    8000434c:	01278963          	beq	a5,s2,8000435e <namex+0x13c>
    80004350:	dbbd                	beqz	a5,800042c6 <namex+0xa4>
    path++;
    80004352:	0985                	addi	s3,s3,1
  while(*path != '/' && *path != 0)
    80004354:	0009c783          	lbu	a5,0(s3)
    80004358:	ff279ce3          	bne	a5,s2,80004350 <namex+0x12e>
    8000435c:	b7ad                	j	800042c6 <namex+0xa4>
    memmove(name, s, len);
    8000435e:	2601                	sext.w	a2,a2
    80004360:	85a6                	mv	a1,s1
    80004362:	8556                	mv	a0,s5
    80004364:	ffffd097          	auipc	ra,0xffffd
    80004368:	9ca080e7          	jalr	-1590(ra) # 80000d2e <memmove>
    name[len] = 0;
    8000436c:	9d56                	add	s10,s10,s5
    8000436e:	000d0023          	sb	zero,0(s10)
    80004372:	84ce                	mv	s1,s3
    80004374:	b7bd                	j	800042e2 <namex+0xc0>
  if(nameiparent){
    80004376:	f00b0ce3          	beqz	s6,8000428e <namex+0x6c>
    iput(ip);
    8000437a:	8552                	mv	a0,s4
    8000437c:	00000097          	auipc	ra,0x0
    80004380:	acc080e7          	jalr	-1332(ra) # 80003e48 <iput>
    return 0;
    80004384:	4a01                	li	s4,0
    80004386:	b721                	j	8000428e <namex+0x6c>

0000000080004388 <dirlink>:
{
    80004388:	7139                	addi	sp,sp,-64
    8000438a:	fc06                	sd	ra,56(sp)
    8000438c:	f822                	sd	s0,48(sp)
    8000438e:	f426                	sd	s1,40(sp)
    80004390:	f04a                	sd	s2,32(sp)
    80004392:	ec4e                	sd	s3,24(sp)
    80004394:	e852                	sd	s4,16(sp)
    80004396:	0080                	addi	s0,sp,64
    80004398:	892a                	mv	s2,a0
    8000439a:	8a2e                	mv	s4,a1
    8000439c:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    8000439e:	4601                	li	a2,0
    800043a0:	00000097          	auipc	ra,0x0
    800043a4:	dd2080e7          	jalr	-558(ra) # 80004172 <dirlookup>
    800043a8:	e93d                	bnez	a0,8000441e <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800043aa:	04c92483          	lw	s1,76(s2)
    800043ae:	c49d                	beqz	s1,800043dc <dirlink+0x54>
    800043b0:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800043b2:	4741                	li	a4,16
    800043b4:	86a6                	mv	a3,s1
    800043b6:	fc040613          	addi	a2,s0,-64
    800043ba:	4581                	li	a1,0
    800043bc:	854a                	mv	a0,s2
    800043be:	00000097          	auipc	ra,0x0
    800043c2:	b84080e7          	jalr	-1148(ra) # 80003f42 <readi>
    800043c6:	47c1                	li	a5,16
    800043c8:	06f51163          	bne	a0,a5,8000442a <dirlink+0xa2>
    if(de.inum == 0)
    800043cc:	fc045783          	lhu	a5,-64(s0)
    800043d0:	c791                	beqz	a5,800043dc <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800043d2:	24c1                	addiw	s1,s1,16
    800043d4:	04c92783          	lw	a5,76(s2)
    800043d8:	fcf4ede3          	bltu	s1,a5,800043b2 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    800043dc:	4639                	li	a2,14
    800043de:	85d2                	mv	a1,s4
    800043e0:	fc240513          	addi	a0,s0,-62
    800043e4:	ffffd097          	auipc	ra,0xffffd
    800043e8:	9fa080e7          	jalr	-1542(ra) # 80000dde <strncpy>
  de.inum = inum;
    800043ec:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800043f0:	4741                	li	a4,16
    800043f2:	86a6                	mv	a3,s1
    800043f4:	fc040613          	addi	a2,s0,-64
    800043f8:	4581                	li	a1,0
    800043fa:	854a                	mv	a0,s2
    800043fc:	00000097          	auipc	ra,0x0
    80004400:	c3e080e7          	jalr	-962(ra) # 8000403a <writei>
    80004404:	1541                	addi	a0,a0,-16
    80004406:	00a03533          	snez	a0,a0
    8000440a:	40a00533          	neg	a0,a0
}
    8000440e:	70e2                	ld	ra,56(sp)
    80004410:	7442                	ld	s0,48(sp)
    80004412:	74a2                	ld	s1,40(sp)
    80004414:	7902                	ld	s2,32(sp)
    80004416:	69e2                	ld	s3,24(sp)
    80004418:	6a42                	ld	s4,16(sp)
    8000441a:	6121                	addi	sp,sp,64
    8000441c:	8082                	ret
    iput(ip);
    8000441e:	00000097          	auipc	ra,0x0
    80004422:	a2a080e7          	jalr	-1494(ra) # 80003e48 <iput>
    return -1;
    80004426:	557d                	li	a0,-1
    80004428:	b7dd                	j	8000440e <dirlink+0x86>
      panic("dirlink read");
    8000442a:	00004517          	auipc	a0,0x4
    8000442e:	39650513          	addi	a0,a0,918 # 800087c0 <syscalls+0x1e0>
    80004432:	ffffc097          	auipc	ra,0xffffc
    80004436:	10e080e7          	jalr	270(ra) # 80000540 <panic>

000000008000443a <namei>:

struct inode*
namei(char *path)
{
    8000443a:	1101                	addi	sp,sp,-32
    8000443c:	ec06                	sd	ra,24(sp)
    8000443e:	e822                	sd	s0,16(sp)
    80004440:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80004442:	fe040613          	addi	a2,s0,-32
    80004446:	4581                	li	a1,0
    80004448:	00000097          	auipc	ra,0x0
    8000444c:	dda080e7          	jalr	-550(ra) # 80004222 <namex>
}
    80004450:	60e2                	ld	ra,24(sp)
    80004452:	6442                	ld	s0,16(sp)
    80004454:	6105                	addi	sp,sp,32
    80004456:	8082                	ret

0000000080004458 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80004458:	1141                	addi	sp,sp,-16
    8000445a:	e406                	sd	ra,8(sp)
    8000445c:	e022                	sd	s0,0(sp)
    8000445e:	0800                	addi	s0,sp,16
    80004460:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80004462:	4585                	li	a1,1
    80004464:	00000097          	auipc	ra,0x0
    80004468:	dbe080e7          	jalr	-578(ra) # 80004222 <namex>
}
    8000446c:	60a2                	ld	ra,8(sp)
    8000446e:	6402                	ld	s0,0(sp)
    80004470:	0141                	addi	sp,sp,16
    80004472:	8082                	ret

0000000080004474 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80004474:	1101                	addi	sp,sp,-32
    80004476:	ec06                	sd	ra,24(sp)
    80004478:	e822                	sd	s0,16(sp)
    8000447a:	e426                	sd	s1,8(sp)
    8000447c:	e04a                	sd	s2,0(sp)
    8000447e:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80004480:	0001e917          	auipc	s2,0x1e
    80004484:	97090913          	addi	s2,s2,-1680 # 80021df0 <log>
    80004488:	01892583          	lw	a1,24(s2)
    8000448c:	02892503          	lw	a0,40(s2)
    80004490:	fffff097          	auipc	ra,0xfffff
    80004494:	fe6080e7          	jalr	-26(ra) # 80003476 <bread>
    80004498:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    8000449a:	02c92683          	lw	a3,44(s2)
    8000449e:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    800044a0:	02d05863          	blez	a3,800044d0 <write_head+0x5c>
    800044a4:	0001e797          	auipc	a5,0x1e
    800044a8:	97c78793          	addi	a5,a5,-1668 # 80021e20 <log+0x30>
    800044ac:	05c50713          	addi	a4,a0,92
    800044b0:	36fd                	addiw	a3,a3,-1
    800044b2:	02069613          	slli	a2,a3,0x20
    800044b6:	01e65693          	srli	a3,a2,0x1e
    800044ba:	0001e617          	auipc	a2,0x1e
    800044be:	96a60613          	addi	a2,a2,-1686 # 80021e24 <log+0x34>
    800044c2:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    800044c4:	4390                	lw	a2,0(a5)
    800044c6:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    800044c8:	0791                	addi	a5,a5,4
    800044ca:	0711                	addi	a4,a4,4 # 43004 <_entry-0x7ffbcffc>
    800044cc:	fed79ce3          	bne	a5,a3,800044c4 <write_head+0x50>
  }
  bwrite(buf);
    800044d0:	8526                	mv	a0,s1
    800044d2:	fffff097          	auipc	ra,0xfffff
    800044d6:	096080e7          	jalr	150(ra) # 80003568 <bwrite>
  brelse(buf);
    800044da:	8526                	mv	a0,s1
    800044dc:	fffff097          	auipc	ra,0xfffff
    800044e0:	0ca080e7          	jalr	202(ra) # 800035a6 <brelse>
}
    800044e4:	60e2                	ld	ra,24(sp)
    800044e6:	6442                	ld	s0,16(sp)
    800044e8:	64a2                	ld	s1,8(sp)
    800044ea:	6902                	ld	s2,0(sp)
    800044ec:	6105                	addi	sp,sp,32
    800044ee:	8082                	ret

00000000800044f0 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    800044f0:	0001e797          	auipc	a5,0x1e
    800044f4:	92c7a783          	lw	a5,-1748(a5) # 80021e1c <log+0x2c>
    800044f8:	0af05d63          	blez	a5,800045b2 <install_trans+0xc2>
{
    800044fc:	7139                	addi	sp,sp,-64
    800044fe:	fc06                	sd	ra,56(sp)
    80004500:	f822                	sd	s0,48(sp)
    80004502:	f426                	sd	s1,40(sp)
    80004504:	f04a                	sd	s2,32(sp)
    80004506:	ec4e                	sd	s3,24(sp)
    80004508:	e852                	sd	s4,16(sp)
    8000450a:	e456                	sd	s5,8(sp)
    8000450c:	e05a                	sd	s6,0(sp)
    8000450e:	0080                	addi	s0,sp,64
    80004510:	8b2a                	mv	s6,a0
    80004512:	0001ea97          	auipc	s5,0x1e
    80004516:	90ea8a93          	addi	s5,s5,-1778 # 80021e20 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000451a:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    8000451c:	0001e997          	auipc	s3,0x1e
    80004520:	8d498993          	addi	s3,s3,-1836 # 80021df0 <log>
    80004524:	a00d                	j	80004546 <install_trans+0x56>
    brelse(lbuf);
    80004526:	854a                	mv	a0,s2
    80004528:	fffff097          	auipc	ra,0xfffff
    8000452c:	07e080e7          	jalr	126(ra) # 800035a6 <brelse>
    brelse(dbuf);
    80004530:	8526                	mv	a0,s1
    80004532:	fffff097          	auipc	ra,0xfffff
    80004536:	074080e7          	jalr	116(ra) # 800035a6 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000453a:	2a05                	addiw	s4,s4,1
    8000453c:	0a91                	addi	s5,s5,4
    8000453e:	02c9a783          	lw	a5,44(s3)
    80004542:	04fa5e63          	bge	s4,a5,8000459e <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004546:	0189a583          	lw	a1,24(s3)
    8000454a:	014585bb          	addw	a1,a1,s4
    8000454e:	2585                	addiw	a1,a1,1
    80004550:	0289a503          	lw	a0,40(s3)
    80004554:	fffff097          	auipc	ra,0xfffff
    80004558:	f22080e7          	jalr	-222(ra) # 80003476 <bread>
    8000455c:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    8000455e:	000aa583          	lw	a1,0(s5)
    80004562:	0289a503          	lw	a0,40(s3)
    80004566:	fffff097          	auipc	ra,0xfffff
    8000456a:	f10080e7          	jalr	-240(ra) # 80003476 <bread>
    8000456e:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004570:	40000613          	li	a2,1024
    80004574:	05890593          	addi	a1,s2,88
    80004578:	05850513          	addi	a0,a0,88
    8000457c:	ffffc097          	auipc	ra,0xffffc
    80004580:	7b2080e7          	jalr	1970(ra) # 80000d2e <memmove>
    bwrite(dbuf);  // write dst to disk
    80004584:	8526                	mv	a0,s1
    80004586:	fffff097          	auipc	ra,0xfffff
    8000458a:	fe2080e7          	jalr	-30(ra) # 80003568 <bwrite>
    if(recovering == 0)
    8000458e:	f80b1ce3          	bnez	s6,80004526 <install_trans+0x36>
      bunpin(dbuf);
    80004592:	8526                	mv	a0,s1
    80004594:	fffff097          	auipc	ra,0xfffff
    80004598:	0ec080e7          	jalr	236(ra) # 80003680 <bunpin>
    8000459c:	b769                	j	80004526 <install_trans+0x36>
}
    8000459e:	70e2                	ld	ra,56(sp)
    800045a0:	7442                	ld	s0,48(sp)
    800045a2:	74a2                	ld	s1,40(sp)
    800045a4:	7902                	ld	s2,32(sp)
    800045a6:	69e2                	ld	s3,24(sp)
    800045a8:	6a42                	ld	s4,16(sp)
    800045aa:	6aa2                	ld	s5,8(sp)
    800045ac:	6b02                	ld	s6,0(sp)
    800045ae:	6121                	addi	sp,sp,64
    800045b0:	8082                	ret
    800045b2:	8082                	ret

00000000800045b4 <initlog>:
{
    800045b4:	7179                	addi	sp,sp,-48
    800045b6:	f406                	sd	ra,40(sp)
    800045b8:	f022                	sd	s0,32(sp)
    800045ba:	ec26                	sd	s1,24(sp)
    800045bc:	e84a                	sd	s2,16(sp)
    800045be:	e44e                	sd	s3,8(sp)
    800045c0:	1800                	addi	s0,sp,48
    800045c2:	892a                	mv	s2,a0
    800045c4:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    800045c6:	0001e497          	auipc	s1,0x1e
    800045ca:	82a48493          	addi	s1,s1,-2006 # 80021df0 <log>
    800045ce:	00004597          	auipc	a1,0x4
    800045d2:	20258593          	addi	a1,a1,514 # 800087d0 <syscalls+0x1f0>
    800045d6:	8526                	mv	a0,s1
    800045d8:	ffffc097          	auipc	ra,0xffffc
    800045dc:	56e080e7          	jalr	1390(ra) # 80000b46 <initlock>
  log.start = sb->logstart;
    800045e0:	0149a583          	lw	a1,20(s3)
    800045e4:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    800045e6:	0109a783          	lw	a5,16(s3)
    800045ea:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    800045ec:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    800045f0:	854a                	mv	a0,s2
    800045f2:	fffff097          	auipc	ra,0xfffff
    800045f6:	e84080e7          	jalr	-380(ra) # 80003476 <bread>
  log.lh.n = lh->n;
    800045fa:	4d34                	lw	a3,88(a0)
    800045fc:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    800045fe:	02d05663          	blez	a3,8000462a <initlog+0x76>
    80004602:	05c50793          	addi	a5,a0,92
    80004606:	0001e717          	auipc	a4,0x1e
    8000460a:	81a70713          	addi	a4,a4,-2022 # 80021e20 <log+0x30>
    8000460e:	36fd                	addiw	a3,a3,-1
    80004610:	02069613          	slli	a2,a3,0x20
    80004614:	01e65693          	srli	a3,a2,0x1e
    80004618:	06050613          	addi	a2,a0,96
    8000461c:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    8000461e:	4390                	lw	a2,0(a5)
    80004620:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004622:	0791                	addi	a5,a5,4
    80004624:	0711                	addi	a4,a4,4
    80004626:	fed79ce3          	bne	a5,a3,8000461e <initlog+0x6a>
  brelse(buf);
    8000462a:	fffff097          	auipc	ra,0xfffff
    8000462e:	f7c080e7          	jalr	-132(ra) # 800035a6 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80004632:	4505                	li	a0,1
    80004634:	00000097          	auipc	ra,0x0
    80004638:	ebc080e7          	jalr	-324(ra) # 800044f0 <install_trans>
  log.lh.n = 0;
    8000463c:	0001d797          	auipc	a5,0x1d
    80004640:	7e07a023          	sw	zero,2016(a5) # 80021e1c <log+0x2c>
  write_head(); // clear the log
    80004644:	00000097          	auipc	ra,0x0
    80004648:	e30080e7          	jalr	-464(ra) # 80004474 <write_head>
}
    8000464c:	70a2                	ld	ra,40(sp)
    8000464e:	7402                	ld	s0,32(sp)
    80004650:	64e2                	ld	s1,24(sp)
    80004652:	6942                	ld	s2,16(sp)
    80004654:	69a2                	ld	s3,8(sp)
    80004656:	6145                	addi	sp,sp,48
    80004658:	8082                	ret

000000008000465a <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    8000465a:	1101                	addi	sp,sp,-32
    8000465c:	ec06                	sd	ra,24(sp)
    8000465e:	e822                	sd	s0,16(sp)
    80004660:	e426                	sd	s1,8(sp)
    80004662:	e04a                	sd	s2,0(sp)
    80004664:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004666:	0001d517          	auipc	a0,0x1d
    8000466a:	78a50513          	addi	a0,a0,1930 # 80021df0 <log>
    8000466e:	ffffc097          	auipc	ra,0xffffc
    80004672:	568080e7          	jalr	1384(ra) # 80000bd6 <acquire>
  while(1){
    if(log.committing){
    80004676:	0001d497          	auipc	s1,0x1d
    8000467a:	77a48493          	addi	s1,s1,1914 # 80021df0 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000467e:	4979                	li	s2,30
    80004680:	a039                	j	8000468e <begin_op+0x34>
      sleep(&log, &log.lock);
    80004682:	85a6                	mv	a1,s1
    80004684:	8526                	mv	a0,s1
    80004686:	ffffe097          	auipc	ra,0xffffe
    8000468a:	bb4080e7          	jalr	-1100(ra) # 8000223a <sleep>
    if(log.committing){
    8000468e:	50dc                	lw	a5,36(s1)
    80004690:	fbed                	bnez	a5,80004682 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004692:	5098                	lw	a4,32(s1)
    80004694:	2705                	addiw	a4,a4,1
    80004696:	0007069b          	sext.w	a3,a4
    8000469a:	0027179b          	slliw	a5,a4,0x2
    8000469e:	9fb9                	addw	a5,a5,a4
    800046a0:	0017979b          	slliw	a5,a5,0x1
    800046a4:	54d8                	lw	a4,44(s1)
    800046a6:	9fb9                	addw	a5,a5,a4
    800046a8:	00f95963          	bge	s2,a5,800046ba <begin_op+0x60>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    800046ac:	85a6                	mv	a1,s1
    800046ae:	8526                	mv	a0,s1
    800046b0:	ffffe097          	auipc	ra,0xffffe
    800046b4:	b8a080e7          	jalr	-1142(ra) # 8000223a <sleep>
    800046b8:	bfd9                	j	8000468e <begin_op+0x34>
    } else {
      log.outstanding += 1;
    800046ba:	0001d517          	auipc	a0,0x1d
    800046be:	73650513          	addi	a0,a0,1846 # 80021df0 <log>
    800046c2:	d114                	sw	a3,32(a0)
      release(&log.lock);
    800046c4:	ffffc097          	auipc	ra,0xffffc
    800046c8:	5c6080e7          	jalr	1478(ra) # 80000c8a <release>
      break;
    }
  }
}
    800046cc:	60e2                	ld	ra,24(sp)
    800046ce:	6442                	ld	s0,16(sp)
    800046d0:	64a2                	ld	s1,8(sp)
    800046d2:	6902                	ld	s2,0(sp)
    800046d4:	6105                	addi	sp,sp,32
    800046d6:	8082                	ret

00000000800046d8 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    800046d8:	7139                	addi	sp,sp,-64
    800046da:	fc06                	sd	ra,56(sp)
    800046dc:	f822                	sd	s0,48(sp)
    800046de:	f426                	sd	s1,40(sp)
    800046e0:	f04a                	sd	s2,32(sp)
    800046e2:	ec4e                	sd	s3,24(sp)
    800046e4:	e852                	sd	s4,16(sp)
    800046e6:	e456                	sd	s5,8(sp)
    800046e8:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    800046ea:	0001d497          	auipc	s1,0x1d
    800046ee:	70648493          	addi	s1,s1,1798 # 80021df0 <log>
    800046f2:	8526                	mv	a0,s1
    800046f4:	ffffc097          	auipc	ra,0xffffc
    800046f8:	4e2080e7          	jalr	1250(ra) # 80000bd6 <acquire>
  log.outstanding -= 1;
    800046fc:	509c                	lw	a5,32(s1)
    800046fe:	37fd                	addiw	a5,a5,-1
    80004700:	0007891b          	sext.w	s2,a5
    80004704:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004706:	50dc                	lw	a5,36(s1)
    80004708:	e7b9                	bnez	a5,80004756 <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    8000470a:	04091e63          	bnez	s2,80004766 <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    8000470e:	0001d497          	auipc	s1,0x1d
    80004712:	6e248493          	addi	s1,s1,1762 # 80021df0 <log>
    80004716:	4785                	li	a5,1
    80004718:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    8000471a:	8526                	mv	a0,s1
    8000471c:	ffffc097          	auipc	ra,0xffffc
    80004720:	56e080e7          	jalr	1390(ra) # 80000c8a <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004724:	54dc                	lw	a5,44(s1)
    80004726:	06f04763          	bgtz	a5,80004794 <end_op+0xbc>
    acquire(&log.lock);
    8000472a:	0001d497          	auipc	s1,0x1d
    8000472e:	6c648493          	addi	s1,s1,1734 # 80021df0 <log>
    80004732:	8526                	mv	a0,s1
    80004734:	ffffc097          	auipc	ra,0xffffc
    80004738:	4a2080e7          	jalr	1186(ra) # 80000bd6 <acquire>
    log.committing = 0;
    8000473c:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004740:	8526                	mv	a0,s1
    80004742:	ffffe097          	auipc	ra,0xffffe
    80004746:	ca8080e7          	jalr	-856(ra) # 800023ea <wakeup>
    release(&log.lock);
    8000474a:	8526                	mv	a0,s1
    8000474c:	ffffc097          	auipc	ra,0xffffc
    80004750:	53e080e7          	jalr	1342(ra) # 80000c8a <release>
}
    80004754:	a03d                	j	80004782 <end_op+0xaa>
    panic("log.committing");
    80004756:	00004517          	auipc	a0,0x4
    8000475a:	08250513          	addi	a0,a0,130 # 800087d8 <syscalls+0x1f8>
    8000475e:	ffffc097          	auipc	ra,0xffffc
    80004762:	de2080e7          	jalr	-542(ra) # 80000540 <panic>
    wakeup(&log);
    80004766:	0001d497          	auipc	s1,0x1d
    8000476a:	68a48493          	addi	s1,s1,1674 # 80021df0 <log>
    8000476e:	8526                	mv	a0,s1
    80004770:	ffffe097          	auipc	ra,0xffffe
    80004774:	c7a080e7          	jalr	-902(ra) # 800023ea <wakeup>
  release(&log.lock);
    80004778:	8526                	mv	a0,s1
    8000477a:	ffffc097          	auipc	ra,0xffffc
    8000477e:	510080e7          	jalr	1296(ra) # 80000c8a <release>
}
    80004782:	70e2                	ld	ra,56(sp)
    80004784:	7442                	ld	s0,48(sp)
    80004786:	74a2                	ld	s1,40(sp)
    80004788:	7902                	ld	s2,32(sp)
    8000478a:	69e2                	ld	s3,24(sp)
    8000478c:	6a42                	ld	s4,16(sp)
    8000478e:	6aa2                	ld	s5,8(sp)
    80004790:	6121                	addi	sp,sp,64
    80004792:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    80004794:	0001da97          	auipc	s5,0x1d
    80004798:	68ca8a93          	addi	s5,s5,1676 # 80021e20 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    8000479c:	0001da17          	auipc	s4,0x1d
    800047a0:	654a0a13          	addi	s4,s4,1620 # 80021df0 <log>
    800047a4:	018a2583          	lw	a1,24(s4)
    800047a8:	012585bb          	addw	a1,a1,s2
    800047ac:	2585                	addiw	a1,a1,1
    800047ae:	028a2503          	lw	a0,40(s4)
    800047b2:	fffff097          	auipc	ra,0xfffff
    800047b6:	cc4080e7          	jalr	-828(ra) # 80003476 <bread>
    800047ba:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    800047bc:	000aa583          	lw	a1,0(s5)
    800047c0:	028a2503          	lw	a0,40(s4)
    800047c4:	fffff097          	auipc	ra,0xfffff
    800047c8:	cb2080e7          	jalr	-846(ra) # 80003476 <bread>
    800047cc:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    800047ce:	40000613          	li	a2,1024
    800047d2:	05850593          	addi	a1,a0,88
    800047d6:	05848513          	addi	a0,s1,88
    800047da:	ffffc097          	auipc	ra,0xffffc
    800047de:	554080e7          	jalr	1364(ra) # 80000d2e <memmove>
    bwrite(to);  // write the log
    800047e2:	8526                	mv	a0,s1
    800047e4:	fffff097          	auipc	ra,0xfffff
    800047e8:	d84080e7          	jalr	-636(ra) # 80003568 <bwrite>
    brelse(from);
    800047ec:	854e                	mv	a0,s3
    800047ee:	fffff097          	auipc	ra,0xfffff
    800047f2:	db8080e7          	jalr	-584(ra) # 800035a6 <brelse>
    brelse(to);
    800047f6:	8526                	mv	a0,s1
    800047f8:	fffff097          	auipc	ra,0xfffff
    800047fc:	dae080e7          	jalr	-594(ra) # 800035a6 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004800:	2905                	addiw	s2,s2,1
    80004802:	0a91                	addi	s5,s5,4
    80004804:	02ca2783          	lw	a5,44(s4)
    80004808:	f8f94ee3          	blt	s2,a5,800047a4 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    8000480c:	00000097          	auipc	ra,0x0
    80004810:	c68080e7          	jalr	-920(ra) # 80004474 <write_head>
    install_trans(0); // Now install writes to home locations
    80004814:	4501                	li	a0,0
    80004816:	00000097          	auipc	ra,0x0
    8000481a:	cda080e7          	jalr	-806(ra) # 800044f0 <install_trans>
    log.lh.n = 0;
    8000481e:	0001d797          	auipc	a5,0x1d
    80004822:	5e07af23          	sw	zero,1534(a5) # 80021e1c <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004826:	00000097          	auipc	ra,0x0
    8000482a:	c4e080e7          	jalr	-946(ra) # 80004474 <write_head>
    8000482e:	bdf5                	j	8000472a <end_op+0x52>

0000000080004830 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004830:	1101                	addi	sp,sp,-32
    80004832:	ec06                	sd	ra,24(sp)
    80004834:	e822                	sd	s0,16(sp)
    80004836:	e426                	sd	s1,8(sp)
    80004838:	e04a                	sd	s2,0(sp)
    8000483a:	1000                	addi	s0,sp,32
    8000483c:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    8000483e:	0001d917          	auipc	s2,0x1d
    80004842:	5b290913          	addi	s2,s2,1458 # 80021df0 <log>
    80004846:	854a                	mv	a0,s2
    80004848:	ffffc097          	auipc	ra,0xffffc
    8000484c:	38e080e7          	jalr	910(ra) # 80000bd6 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004850:	02c92603          	lw	a2,44(s2)
    80004854:	47f5                	li	a5,29
    80004856:	06c7c563          	blt	a5,a2,800048c0 <log_write+0x90>
    8000485a:	0001d797          	auipc	a5,0x1d
    8000485e:	5b27a783          	lw	a5,1458(a5) # 80021e0c <log+0x1c>
    80004862:	37fd                	addiw	a5,a5,-1
    80004864:	04f65e63          	bge	a2,a5,800048c0 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004868:	0001d797          	auipc	a5,0x1d
    8000486c:	5a87a783          	lw	a5,1448(a5) # 80021e10 <log+0x20>
    80004870:	06f05063          	blez	a5,800048d0 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004874:	4781                	li	a5,0
    80004876:	06c05563          	blez	a2,800048e0 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    8000487a:	44cc                	lw	a1,12(s1)
    8000487c:	0001d717          	auipc	a4,0x1d
    80004880:	5a470713          	addi	a4,a4,1444 # 80021e20 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004884:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004886:	4314                	lw	a3,0(a4)
    80004888:	04b68c63          	beq	a3,a1,800048e0 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    8000488c:	2785                	addiw	a5,a5,1
    8000488e:	0711                	addi	a4,a4,4
    80004890:	fef61be3          	bne	a2,a5,80004886 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004894:	0621                	addi	a2,a2,8
    80004896:	060a                	slli	a2,a2,0x2
    80004898:	0001d797          	auipc	a5,0x1d
    8000489c:	55878793          	addi	a5,a5,1368 # 80021df0 <log>
    800048a0:	97b2                	add	a5,a5,a2
    800048a2:	44d8                	lw	a4,12(s1)
    800048a4:	cb98                	sw	a4,16(a5)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    800048a6:	8526                	mv	a0,s1
    800048a8:	fffff097          	auipc	ra,0xfffff
    800048ac:	d9c080e7          	jalr	-612(ra) # 80003644 <bpin>
    log.lh.n++;
    800048b0:	0001d717          	auipc	a4,0x1d
    800048b4:	54070713          	addi	a4,a4,1344 # 80021df0 <log>
    800048b8:	575c                	lw	a5,44(a4)
    800048ba:	2785                	addiw	a5,a5,1
    800048bc:	d75c                	sw	a5,44(a4)
    800048be:	a82d                	j	800048f8 <log_write+0xc8>
    panic("too big a transaction");
    800048c0:	00004517          	auipc	a0,0x4
    800048c4:	f2850513          	addi	a0,a0,-216 # 800087e8 <syscalls+0x208>
    800048c8:	ffffc097          	auipc	ra,0xffffc
    800048cc:	c78080e7          	jalr	-904(ra) # 80000540 <panic>
    panic("log_write outside of trans");
    800048d0:	00004517          	auipc	a0,0x4
    800048d4:	f3050513          	addi	a0,a0,-208 # 80008800 <syscalls+0x220>
    800048d8:	ffffc097          	auipc	ra,0xffffc
    800048dc:	c68080e7          	jalr	-920(ra) # 80000540 <panic>
  log.lh.block[i] = b->blockno;
    800048e0:	00878693          	addi	a3,a5,8
    800048e4:	068a                	slli	a3,a3,0x2
    800048e6:	0001d717          	auipc	a4,0x1d
    800048ea:	50a70713          	addi	a4,a4,1290 # 80021df0 <log>
    800048ee:	9736                	add	a4,a4,a3
    800048f0:	44d4                	lw	a3,12(s1)
    800048f2:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    800048f4:	faf609e3          	beq	a2,a5,800048a6 <log_write+0x76>
  }
  release(&log.lock);
    800048f8:	0001d517          	auipc	a0,0x1d
    800048fc:	4f850513          	addi	a0,a0,1272 # 80021df0 <log>
    80004900:	ffffc097          	auipc	ra,0xffffc
    80004904:	38a080e7          	jalr	906(ra) # 80000c8a <release>
}
    80004908:	60e2                	ld	ra,24(sp)
    8000490a:	6442                	ld	s0,16(sp)
    8000490c:	64a2                	ld	s1,8(sp)
    8000490e:	6902                	ld	s2,0(sp)
    80004910:	6105                	addi	sp,sp,32
    80004912:	8082                	ret

0000000080004914 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004914:	1101                	addi	sp,sp,-32
    80004916:	ec06                	sd	ra,24(sp)
    80004918:	e822                	sd	s0,16(sp)
    8000491a:	e426                	sd	s1,8(sp)
    8000491c:	e04a                	sd	s2,0(sp)
    8000491e:	1000                	addi	s0,sp,32
    80004920:	84aa                	mv	s1,a0
    80004922:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004924:	00004597          	auipc	a1,0x4
    80004928:	efc58593          	addi	a1,a1,-260 # 80008820 <syscalls+0x240>
    8000492c:	0521                	addi	a0,a0,8
    8000492e:	ffffc097          	auipc	ra,0xffffc
    80004932:	218080e7          	jalr	536(ra) # 80000b46 <initlock>
  lk->name = name;
    80004936:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    8000493a:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    8000493e:	0204a423          	sw	zero,40(s1)
}
    80004942:	60e2                	ld	ra,24(sp)
    80004944:	6442                	ld	s0,16(sp)
    80004946:	64a2                	ld	s1,8(sp)
    80004948:	6902                	ld	s2,0(sp)
    8000494a:	6105                	addi	sp,sp,32
    8000494c:	8082                	ret

000000008000494e <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    8000494e:	1101                	addi	sp,sp,-32
    80004950:	ec06                	sd	ra,24(sp)
    80004952:	e822                	sd	s0,16(sp)
    80004954:	e426                	sd	s1,8(sp)
    80004956:	e04a                	sd	s2,0(sp)
    80004958:	1000                	addi	s0,sp,32
    8000495a:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    8000495c:	00850913          	addi	s2,a0,8
    80004960:	854a                	mv	a0,s2
    80004962:	ffffc097          	auipc	ra,0xffffc
    80004966:	274080e7          	jalr	628(ra) # 80000bd6 <acquire>
  while (lk->locked) {
    8000496a:	409c                	lw	a5,0(s1)
    8000496c:	cb89                	beqz	a5,8000497e <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    8000496e:	85ca                	mv	a1,s2
    80004970:	8526                	mv	a0,s1
    80004972:	ffffe097          	auipc	ra,0xffffe
    80004976:	8c8080e7          	jalr	-1848(ra) # 8000223a <sleep>
  while (lk->locked) {
    8000497a:	409c                	lw	a5,0(s1)
    8000497c:	fbed                	bnez	a5,8000496e <acquiresleep+0x20>
  }
  lk->locked = 1;
    8000497e:	4785                	li	a5,1
    80004980:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004982:	ffffd097          	auipc	ra,0xffffd
    80004986:	02a080e7          	jalr	42(ra) # 800019ac <myproc>
    8000498a:	591c                	lw	a5,48(a0)
    8000498c:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    8000498e:	854a                	mv	a0,s2
    80004990:	ffffc097          	auipc	ra,0xffffc
    80004994:	2fa080e7          	jalr	762(ra) # 80000c8a <release>
}
    80004998:	60e2                	ld	ra,24(sp)
    8000499a:	6442                	ld	s0,16(sp)
    8000499c:	64a2                	ld	s1,8(sp)
    8000499e:	6902                	ld	s2,0(sp)
    800049a0:	6105                	addi	sp,sp,32
    800049a2:	8082                	ret

00000000800049a4 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    800049a4:	1101                	addi	sp,sp,-32
    800049a6:	ec06                	sd	ra,24(sp)
    800049a8:	e822                	sd	s0,16(sp)
    800049aa:	e426                	sd	s1,8(sp)
    800049ac:	e04a                	sd	s2,0(sp)
    800049ae:	1000                	addi	s0,sp,32
    800049b0:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800049b2:	00850913          	addi	s2,a0,8
    800049b6:	854a                	mv	a0,s2
    800049b8:	ffffc097          	auipc	ra,0xffffc
    800049bc:	21e080e7          	jalr	542(ra) # 80000bd6 <acquire>
  lk->locked = 0;
    800049c0:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800049c4:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    800049c8:	8526                	mv	a0,s1
    800049ca:	ffffe097          	auipc	ra,0xffffe
    800049ce:	a20080e7          	jalr	-1504(ra) # 800023ea <wakeup>
  release(&lk->lk);
    800049d2:	854a                	mv	a0,s2
    800049d4:	ffffc097          	auipc	ra,0xffffc
    800049d8:	2b6080e7          	jalr	694(ra) # 80000c8a <release>
}
    800049dc:	60e2                	ld	ra,24(sp)
    800049de:	6442                	ld	s0,16(sp)
    800049e0:	64a2                	ld	s1,8(sp)
    800049e2:	6902                	ld	s2,0(sp)
    800049e4:	6105                	addi	sp,sp,32
    800049e6:	8082                	ret

00000000800049e8 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    800049e8:	7179                	addi	sp,sp,-48
    800049ea:	f406                	sd	ra,40(sp)
    800049ec:	f022                	sd	s0,32(sp)
    800049ee:	ec26                	sd	s1,24(sp)
    800049f0:	e84a                	sd	s2,16(sp)
    800049f2:	e44e                	sd	s3,8(sp)
    800049f4:	1800                	addi	s0,sp,48
    800049f6:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    800049f8:	00850913          	addi	s2,a0,8
    800049fc:	854a                	mv	a0,s2
    800049fe:	ffffc097          	auipc	ra,0xffffc
    80004a02:	1d8080e7          	jalr	472(ra) # 80000bd6 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004a06:	409c                	lw	a5,0(s1)
    80004a08:	ef99                	bnez	a5,80004a26 <holdingsleep+0x3e>
    80004a0a:	4481                	li	s1,0
  release(&lk->lk);
    80004a0c:	854a                	mv	a0,s2
    80004a0e:	ffffc097          	auipc	ra,0xffffc
    80004a12:	27c080e7          	jalr	636(ra) # 80000c8a <release>
  return r;
}
    80004a16:	8526                	mv	a0,s1
    80004a18:	70a2                	ld	ra,40(sp)
    80004a1a:	7402                	ld	s0,32(sp)
    80004a1c:	64e2                	ld	s1,24(sp)
    80004a1e:	6942                	ld	s2,16(sp)
    80004a20:	69a2                	ld	s3,8(sp)
    80004a22:	6145                	addi	sp,sp,48
    80004a24:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004a26:	0284a983          	lw	s3,40(s1)
    80004a2a:	ffffd097          	auipc	ra,0xffffd
    80004a2e:	f82080e7          	jalr	-126(ra) # 800019ac <myproc>
    80004a32:	5904                	lw	s1,48(a0)
    80004a34:	413484b3          	sub	s1,s1,s3
    80004a38:	0014b493          	seqz	s1,s1
    80004a3c:	bfc1                	j	80004a0c <holdingsleep+0x24>

0000000080004a3e <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004a3e:	1141                	addi	sp,sp,-16
    80004a40:	e406                	sd	ra,8(sp)
    80004a42:	e022                	sd	s0,0(sp)
    80004a44:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004a46:	00004597          	auipc	a1,0x4
    80004a4a:	dea58593          	addi	a1,a1,-534 # 80008830 <syscalls+0x250>
    80004a4e:	0001d517          	auipc	a0,0x1d
    80004a52:	4ea50513          	addi	a0,a0,1258 # 80021f38 <ftable>
    80004a56:	ffffc097          	auipc	ra,0xffffc
    80004a5a:	0f0080e7          	jalr	240(ra) # 80000b46 <initlock>
}
    80004a5e:	60a2                	ld	ra,8(sp)
    80004a60:	6402                	ld	s0,0(sp)
    80004a62:	0141                	addi	sp,sp,16
    80004a64:	8082                	ret

0000000080004a66 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004a66:	1101                	addi	sp,sp,-32
    80004a68:	ec06                	sd	ra,24(sp)
    80004a6a:	e822                	sd	s0,16(sp)
    80004a6c:	e426                	sd	s1,8(sp)
    80004a6e:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004a70:	0001d517          	auipc	a0,0x1d
    80004a74:	4c850513          	addi	a0,a0,1224 # 80021f38 <ftable>
    80004a78:	ffffc097          	auipc	ra,0xffffc
    80004a7c:	15e080e7          	jalr	350(ra) # 80000bd6 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004a80:	0001d497          	auipc	s1,0x1d
    80004a84:	4d048493          	addi	s1,s1,1232 # 80021f50 <ftable+0x18>
    80004a88:	0001e717          	auipc	a4,0x1e
    80004a8c:	46870713          	addi	a4,a4,1128 # 80022ef0 <disk>
    if(f->ref == 0){
    80004a90:	40dc                	lw	a5,4(s1)
    80004a92:	cf99                	beqz	a5,80004ab0 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004a94:	02848493          	addi	s1,s1,40
    80004a98:	fee49ce3          	bne	s1,a4,80004a90 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004a9c:	0001d517          	auipc	a0,0x1d
    80004aa0:	49c50513          	addi	a0,a0,1180 # 80021f38 <ftable>
    80004aa4:	ffffc097          	auipc	ra,0xffffc
    80004aa8:	1e6080e7          	jalr	486(ra) # 80000c8a <release>
  return 0;
    80004aac:	4481                	li	s1,0
    80004aae:	a819                	j	80004ac4 <filealloc+0x5e>
      f->ref = 1;
    80004ab0:	4785                	li	a5,1
    80004ab2:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004ab4:	0001d517          	auipc	a0,0x1d
    80004ab8:	48450513          	addi	a0,a0,1156 # 80021f38 <ftable>
    80004abc:	ffffc097          	auipc	ra,0xffffc
    80004ac0:	1ce080e7          	jalr	462(ra) # 80000c8a <release>
}
    80004ac4:	8526                	mv	a0,s1
    80004ac6:	60e2                	ld	ra,24(sp)
    80004ac8:	6442                	ld	s0,16(sp)
    80004aca:	64a2                	ld	s1,8(sp)
    80004acc:	6105                	addi	sp,sp,32
    80004ace:	8082                	ret

0000000080004ad0 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004ad0:	1101                	addi	sp,sp,-32
    80004ad2:	ec06                	sd	ra,24(sp)
    80004ad4:	e822                	sd	s0,16(sp)
    80004ad6:	e426                	sd	s1,8(sp)
    80004ad8:	1000                	addi	s0,sp,32
    80004ada:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004adc:	0001d517          	auipc	a0,0x1d
    80004ae0:	45c50513          	addi	a0,a0,1116 # 80021f38 <ftable>
    80004ae4:	ffffc097          	auipc	ra,0xffffc
    80004ae8:	0f2080e7          	jalr	242(ra) # 80000bd6 <acquire>
  if(f->ref < 1)
    80004aec:	40dc                	lw	a5,4(s1)
    80004aee:	02f05263          	blez	a5,80004b12 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004af2:	2785                	addiw	a5,a5,1
    80004af4:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004af6:	0001d517          	auipc	a0,0x1d
    80004afa:	44250513          	addi	a0,a0,1090 # 80021f38 <ftable>
    80004afe:	ffffc097          	auipc	ra,0xffffc
    80004b02:	18c080e7          	jalr	396(ra) # 80000c8a <release>
  return f;
}
    80004b06:	8526                	mv	a0,s1
    80004b08:	60e2                	ld	ra,24(sp)
    80004b0a:	6442                	ld	s0,16(sp)
    80004b0c:	64a2                	ld	s1,8(sp)
    80004b0e:	6105                	addi	sp,sp,32
    80004b10:	8082                	ret
    panic("filedup");
    80004b12:	00004517          	auipc	a0,0x4
    80004b16:	d2650513          	addi	a0,a0,-730 # 80008838 <syscalls+0x258>
    80004b1a:	ffffc097          	auipc	ra,0xffffc
    80004b1e:	a26080e7          	jalr	-1498(ra) # 80000540 <panic>

0000000080004b22 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004b22:	7139                	addi	sp,sp,-64
    80004b24:	fc06                	sd	ra,56(sp)
    80004b26:	f822                	sd	s0,48(sp)
    80004b28:	f426                	sd	s1,40(sp)
    80004b2a:	f04a                	sd	s2,32(sp)
    80004b2c:	ec4e                	sd	s3,24(sp)
    80004b2e:	e852                	sd	s4,16(sp)
    80004b30:	e456                	sd	s5,8(sp)
    80004b32:	0080                	addi	s0,sp,64
    80004b34:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004b36:	0001d517          	auipc	a0,0x1d
    80004b3a:	40250513          	addi	a0,a0,1026 # 80021f38 <ftable>
    80004b3e:	ffffc097          	auipc	ra,0xffffc
    80004b42:	098080e7          	jalr	152(ra) # 80000bd6 <acquire>
  if(f->ref < 1)
    80004b46:	40dc                	lw	a5,4(s1)
    80004b48:	06f05163          	blez	a5,80004baa <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004b4c:	37fd                	addiw	a5,a5,-1
    80004b4e:	0007871b          	sext.w	a4,a5
    80004b52:	c0dc                	sw	a5,4(s1)
    80004b54:	06e04363          	bgtz	a4,80004bba <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004b58:	0004a903          	lw	s2,0(s1)
    80004b5c:	0094ca83          	lbu	s5,9(s1)
    80004b60:	0104ba03          	ld	s4,16(s1)
    80004b64:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004b68:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004b6c:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004b70:	0001d517          	auipc	a0,0x1d
    80004b74:	3c850513          	addi	a0,a0,968 # 80021f38 <ftable>
    80004b78:	ffffc097          	auipc	ra,0xffffc
    80004b7c:	112080e7          	jalr	274(ra) # 80000c8a <release>

  if(ff.type == FD_PIPE){
    80004b80:	4785                	li	a5,1
    80004b82:	04f90d63          	beq	s2,a5,80004bdc <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004b86:	3979                	addiw	s2,s2,-2
    80004b88:	4785                	li	a5,1
    80004b8a:	0527e063          	bltu	a5,s2,80004bca <fileclose+0xa8>
    begin_op();
    80004b8e:	00000097          	auipc	ra,0x0
    80004b92:	acc080e7          	jalr	-1332(ra) # 8000465a <begin_op>
    iput(ff.ip);
    80004b96:	854e                	mv	a0,s3
    80004b98:	fffff097          	auipc	ra,0xfffff
    80004b9c:	2b0080e7          	jalr	688(ra) # 80003e48 <iput>
    end_op();
    80004ba0:	00000097          	auipc	ra,0x0
    80004ba4:	b38080e7          	jalr	-1224(ra) # 800046d8 <end_op>
    80004ba8:	a00d                	j	80004bca <fileclose+0xa8>
    panic("fileclose");
    80004baa:	00004517          	auipc	a0,0x4
    80004bae:	c9650513          	addi	a0,a0,-874 # 80008840 <syscalls+0x260>
    80004bb2:	ffffc097          	auipc	ra,0xffffc
    80004bb6:	98e080e7          	jalr	-1650(ra) # 80000540 <panic>
    release(&ftable.lock);
    80004bba:	0001d517          	auipc	a0,0x1d
    80004bbe:	37e50513          	addi	a0,a0,894 # 80021f38 <ftable>
    80004bc2:	ffffc097          	auipc	ra,0xffffc
    80004bc6:	0c8080e7          	jalr	200(ra) # 80000c8a <release>
  }
}
    80004bca:	70e2                	ld	ra,56(sp)
    80004bcc:	7442                	ld	s0,48(sp)
    80004bce:	74a2                	ld	s1,40(sp)
    80004bd0:	7902                	ld	s2,32(sp)
    80004bd2:	69e2                	ld	s3,24(sp)
    80004bd4:	6a42                	ld	s4,16(sp)
    80004bd6:	6aa2                	ld	s5,8(sp)
    80004bd8:	6121                	addi	sp,sp,64
    80004bda:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004bdc:	85d6                	mv	a1,s5
    80004bde:	8552                	mv	a0,s4
    80004be0:	00000097          	auipc	ra,0x0
    80004be4:	34c080e7          	jalr	844(ra) # 80004f2c <pipeclose>
    80004be8:	b7cd                	j	80004bca <fileclose+0xa8>

0000000080004bea <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004bea:	715d                	addi	sp,sp,-80
    80004bec:	e486                	sd	ra,72(sp)
    80004bee:	e0a2                	sd	s0,64(sp)
    80004bf0:	fc26                	sd	s1,56(sp)
    80004bf2:	f84a                	sd	s2,48(sp)
    80004bf4:	f44e                	sd	s3,40(sp)
    80004bf6:	0880                	addi	s0,sp,80
    80004bf8:	84aa                	mv	s1,a0
    80004bfa:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004bfc:	ffffd097          	auipc	ra,0xffffd
    80004c00:	db0080e7          	jalr	-592(ra) # 800019ac <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004c04:	409c                	lw	a5,0(s1)
    80004c06:	37f9                	addiw	a5,a5,-2
    80004c08:	4705                	li	a4,1
    80004c0a:	04f76763          	bltu	a4,a5,80004c58 <filestat+0x6e>
    80004c0e:	892a                	mv	s2,a0
    ilock(f->ip);
    80004c10:	6c88                	ld	a0,24(s1)
    80004c12:	fffff097          	auipc	ra,0xfffff
    80004c16:	07c080e7          	jalr	124(ra) # 80003c8e <ilock>
    stati(f->ip, &st);
    80004c1a:	fb840593          	addi	a1,s0,-72
    80004c1e:	6c88                	ld	a0,24(s1)
    80004c20:	fffff097          	auipc	ra,0xfffff
    80004c24:	2f8080e7          	jalr	760(ra) # 80003f18 <stati>
    iunlock(f->ip);
    80004c28:	6c88                	ld	a0,24(s1)
    80004c2a:	fffff097          	auipc	ra,0xfffff
    80004c2e:	126080e7          	jalr	294(ra) # 80003d50 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004c32:	46e1                	li	a3,24
    80004c34:	fb840613          	addi	a2,s0,-72
    80004c38:	85ce                	mv	a1,s3
    80004c3a:	05093503          	ld	a0,80(s2)
    80004c3e:	ffffd097          	auipc	ra,0xffffd
    80004c42:	a2e080e7          	jalr	-1490(ra) # 8000166c <copyout>
    80004c46:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004c4a:	60a6                	ld	ra,72(sp)
    80004c4c:	6406                	ld	s0,64(sp)
    80004c4e:	74e2                	ld	s1,56(sp)
    80004c50:	7942                	ld	s2,48(sp)
    80004c52:	79a2                	ld	s3,40(sp)
    80004c54:	6161                	addi	sp,sp,80
    80004c56:	8082                	ret
  return -1;
    80004c58:	557d                	li	a0,-1
    80004c5a:	bfc5                	j	80004c4a <filestat+0x60>

0000000080004c5c <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004c5c:	7179                	addi	sp,sp,-48
    80004c5e:	f406                	sd	ra,40(sp)
    80004c60:	f022                	sd	s0,32(sp)
    80004c62:	ec26                	sd	s1,24(sp)
    80004c64:	e84a                	sd	s2,16(sp)
    80004c66:	e44e                	sd	s3,8(sp)
    80004c68:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004c6a:	00854783          	lbu	a5,8(a0)
    80004c6e:	c3d5                	beqz	a5,80004d12 <fileread+0xb6>
    80004c70:	84aa                	mv	s1,a0
    80004c72:	89ae                	mv	s3,a1
    80004c74:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004c76:	411c                	lw	a5,0(a0)
    80004c78:	4705                	li	a4,1
    80004c7a:	04e78963          	beq	a5,a4,80004ccc <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004c7e:	470d                	li	a4,3
    80004c80:	04e78d63          	beq	a5,a4,80004cda <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004c84:	4709                	li	a4,2
    80004c86:	06e79e63          	bne	a5,a4,80004d02 <fileread+0xa6>
    ilock(f->ip);
    80004c8a:	6d08                	ld	a0,24(a0)
    80004c8c:	fffff097          	auipc	ra,0xfffff
    80004c90:	002080e7          	jalr	2(ra) # 80003c8e <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004c94:	874a                	mv	a4,s2
    80004c96:	5094                	lw	a3,32(s1)
    80004c98:	864e                	mv	a2,s3
    80004c9a:	4585                	li	a1,1
    80004c9c:	6c88                	ld	a0,24(s1)
    80004c9e:	fffff097          	auipc	ra,0xfffff
    80004ca2:	2a4080e7          	jalr	676(ra) # 80003f42 <readi>
    80004ca6:	892a                	mv	s2,a0
    80004ca8:	00a05563          	blez	a0,80004cb2 <fileread+0x56>
      f->off += r;
    80004cac:	509c                	lw	a5,32(s1)
    80004cae:	9fa9                	addw	a5,a5,a0
    80004cb0:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004cb2:	6c88                	ld	a0,24(s1)
    80004cb4:	fffff097          	auipc	ra,0xfffff
    80004cb8:	09c080e7          	jalr	156(ra) # 80003d50 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004cbc:	854a                	mv	a0,s2
    80004cbe:	70a2                	ld	ra,40(sp)
    80004cc0:	7402                	ld	s0,32(sp)
    80004cc2:	64e2                	ld	s1,24(sp)
    80004cc4:	6942                	ld	s2,16(sp)
    80004cc6:	69a2                	ld	s3,8(sp)
    80004cc8:	6145                	addi	sp,sp,48
    80004cca:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004ccc:	6908                	ld	a0,16(a0)
    80004cce:	00000097          	auipc	ra,0x0
    80004cd2:	3c6080e7          	jalr	966(ra) # 80005094 <piperead>
    80004cd6:	892a                	mv	s2,a0
    80004cd8:	b7d5                	j	80004cbc <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004cda:	02451783          	lh	a5,36(a0)
    80004cde:	03079693          	slli	a3,a5,0x30
    80004ce2:	92c1                	srli	a3,a3,0x30
    80004ce4:	4725                	li	a4,9
    80004ce6:	02d76863          	bltu	a4,a3,80004d16 <fileread+0xba>
    80004cea:	0792                	slli	a5,a5,0x4
    80004cec:	0001d717          	auipc	a4,0x1d
    80004cf0:	1ac70713          	addi	a4,a4,428 # 80021e98 <devsw>
    80004cf4:	97ba                	add	a5,a5,a4
    80004cf6:	639c                	ld	a5,0(a5)
    80004cf8:	c38d                	beqz	a5,80004d1a <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004cfa:	4505                	li	a0,1
    80004cfc:	9782                	jalr	a5
    80004cfe:	892a                	mv	s2,a0
    80004d00:	bf75                	j	80004cbc <fileread+0x60>
    panic("fileread");
    80004d02:	00004517          	auipc	a0,0x4
    80004d06:	b4e50513          	addi	a0,a0,-1202 # 80008850 <syscalls+0x270>
    80004d0a:	ffffc097          	auipc	ra,0xffffc
    80004d0e:	836080e7          	jalr	-1994(ra) # 80000540 <panic>
    return -1;
    80004d12:	597d                	li	s2,-1
    80004d14:	b765                	j	80004cbc <fileread+0x60>
      return -1;
    80004d16:	597d                	li	s2,-1
    80004d18:	b755                	j	80004cbc <fileread+0x60>
    80004d1a:	597d                	li	s2,-1
    80004d1c:	b745                	j	80004cbc <fileread+0x60>

0000000080004d1e <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004d1e:	715d                	addi	sp,sp,-80
    80004d20:	e486                	sd	ra,72(sp)
    80004d22:	e0a2                	sd	s0,64(sp)
    80004d24:	fc26                	sd	s1,56(sp)
    80004d26:	f84a                	sd	s2,48(sp)
    80004d28:	f44e                	sd	s3,40(sp)
    80004d2a:	f052                	sd	s4,32(sp)
    80004d2c:	ec56                	sd	s5,24(sp)
    80004d2e:	e85a                	sd	s6,16(sp)
    80004d30:	e45e                	sd	s7,8(sp)
    80004d32:	e062                	sd	s8,0(sp)
    80004d34:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004d36:	00954783          	lbu	a5,9(a0)
    80004d3a:	10078663          	beqz	a5,80004e46 <filewrite+0x128>
    80004d3e:	892a                	mv	s2,a0
    80004d40:	8b2e                	mv	s6,a1
    80004d42:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004d44:	411c                	lw	a5,0(a0)
    80004d46:	4705                	li	a4,1
    80004d48:	02e78263          	beq	a5,a4,80004d6c <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004d4c:	470d                	li	a4,3
    80004d4e:	02e78663          	beq	a5,a4,80004d7a <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004d52:	4709                	li	a4,2
    80004d54:	0ee79163          	bne	a5,a4,80004e36 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004d58:	0ac05d63          	blez	a2,80004e12 <filewrite+0xf4>
    int i = 0;
    80004d5c:	4981                	li	s3,0
    80004d5e:	6b85                	lui	s7,0x1
    80004d60:	c00b8b93          	addi	s7,s7,-1024 # c00 <_entry-0x7ffff400>
    80004d64:	6c05                	lui	s8,0x1
    80004d66:	c00c0c1b          	addiw	s8,s8,-1024 # c00 <_entry-0x7ffff400>
    80004d6a:	a861                	j	80004e02 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004d6c:	6908                	ld	a0,16(a0)
    80004d6e:	00000097          	auipc	ra,0x0
    80004d72:	22e080e7          	jalr	558(ra) # 80004f9c <pipewrite>
    80004d76:	8a2a                	mv	s4,a0
    80004d78:	a045                	j	80004e18 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004d7a:	02451783          	lh	a5,36(a0)
    80004d7e:	03079693          	slli	a3,a5,0x30
    80004d82:	92c1                	srli	a3,a3,0x30
    80004d84:	4725                	li	a4,9
    80004d86:	0cd76263          	bltu	a4,a3,80004e4a <filewrite+0x12c>
    80004d8a:	0792                	slli	a5,a5,0x4
    80004d8c:	0001d717          	auipc	a4,0x1d
    80004d90:	10c70713          	addi	a4,a4,268 # 80021e98 <devsw>
    80004d94:	97ba                	add	a5,a5,a4
    80004d96:	679c                	ld	a5,8(a5)
    80004d98:	cbdd                	beqz	a5,80004e4e <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004d9a:	4505                	li	a0,1
    80004d9c:	9782                	jalr	a5
    80004d9e:	8a2a                	mv	s4,a0
    80004da0:	a8a5                	j	80004e18 <filewrite+0xfa>
    80004da2:	00048a9b          	sext.w	s5,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004da6:	00000097          	auipc	ra,0x0
    80004daa:	8b4080e7          	jalr	-1868(ra) # 8000465a <begin_op>
      ilock(f->ip);
    80004dae:	01893503          	ld	a0,24(s2)
    80004db2:	fffff097          	auipc	ra,0xfffff
    80004db6:	edc080e7          	jalr	-292(ra) # 80003c8e <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004dba:	8756                	mv	a4,s5
    80004dbc:	02092683          	lw	a3,32(s2)
    80004dc0:	01698633          	add	a2,s3,s6
    80004dc4:	4585                	li	a1,1
    80004dc6:	01893503          	ld	a0,24(s2)
    80004dca:	fffff097          	auipc	ra,0xfffff
    80004dce:	270080e7          	jalr	624(ra) # 8000403a <writei>
    80004dd2:	84aa                	mv	s1,a0
    80004dd4:	00a05763          	blez	a0,80004de2 <filewrite+0xc4>
        f->off += r;
    80004dd8:	02092783          	lw	a5,32(s2)
    80004ddc:	9fa9                	addw	a5,a5,a0
    80004dde:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004de2:	01893503          	ld	a0,24(s2)
    80004de6:	fffff097          	auipc	ra,0xfffff
    80004dea:	f6a080e7          	jalr	-150(ra) # 80003d50 <iunlock>
      end_op();
    80004dee:	00000097          	auipc	ra,0x0
    80004df2:	8ea080e7          	jalr	-1814(ra) # 800046d8 <end_op>

      if(r != n1){
    80004df6:	009a9f63          	bne	s5,s1,80004e14 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004dfa:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004dfe:	0149db63          	bge	s3,s4,80004e14 <filewrite+0xf6>
      int n1 = n - i;
    80004e02:	413a04bb          	subw	s1,s4,s3
    80004e06:	0004879b          	sext.w	a5,s1
    80004e0a:	f8fbdce3          	bge	s7,a5,80004da2 <filewrite+0x84>
    80004e0e:	84e2                	mv	s1,s8
    80004e10:	bf49                	j	80004da2 <filewrite+0x84>
    int i = 0;
    80004e12:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004e14:	013a1f63          	bne	s4,s3,80004e32 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004e18:	8552                	mv	a0,s4
    80004e1a:	60a6                	ld	ra,72(sp)
    80004e1c:	6406                	ld	s0,64(sp)
    80004e1e:	74e2                	ld	s1,56(sp)
    80004e20:	7942                	ld	s2,48(sp)
    80004e22:	79a2                	ld	s3,40(sp)
    80004e24:	7a02                	ld	s4,32(sp)
    80004e26:	6ae2                	ld	s5,24(sp)
    80004e28:	6b42                	ld	s6,16(sp)
    80004e2a:	6ba2                	ld	s7,8(sp)
    80004e2c:	6c02                	ld	s8,0(sp)
    80004e2e:	6161                	addi	sp,sp,80
    80004e30:	8082                	ret
    ret = (i == n ? n : -1);
    80004e32:	5a7d                	li	s4,-1
    80004e34:	b7d5                	j	80004e18 <filewrite+0xfa>
    panic("filewrite");
    80004e36:	00004517          	auipc	a0,0x4
    80004e3a:	a2a50513          	addi	a0,a0,-1494 # 80008860 <syscalls+0x280>
    80004e3e:	ffffb097          	auipc	ra,0xffffb
    80004e42:	702080e7          	jalr	1794(ra) # 80000540 <panic>
    return -1;
    80004e46:	5a7d                	li	s4,-1
    80004e48:	bfc1                	j	80004e18 <filewrite+0xfa>
      return -1;
    80004e4a:	5a7d                	li	s4,-1
    80004e4c:	b7f1                	j	80004e18 <filewrite+0xfa>
    80004e4e:	5a7d                	li	s4,-1
    80004e50:	b7e1                	j	80004e18 <filewrite+0xfa>

0000000080004e52 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004e52:	7179                	addi	sp,sp,-48
    80004e54:	f406                	sd	ra,40(sp)
    80004e56:	f022                	sd	s0,32(sp)
    80004e58:	ec26                	sd	s1,24(sp)
    80004e5a:	e84a                	sd	s2,16(sp)
    80004e5c:	e44e                	sd	s3,8(sp)
    80004e5e:	e052                	sd	s4,0(sp)
    80004e60:	1800                	addi	s0,sp,48
    80004e62:	84aa                	mv	s1,a0
    80004e64:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004e66:	0005b023          	sd	zero,0(a1)
    80004e6a:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004e6e:	00000097          	auipc	ra,0x0
    80004e72:	bf8080e7          	jalr	-1032(ra) # 80004a66 <filealloc>
    80004e76:	e088                	sd	a0,0(s1)
    80004e78:	c551                	beqz	a0,80004f04 <pipealloc+0xb2>
    80004e7a:	00000097          	auipc	ra,0x0
    80004e7e:	bec080e7          	jalr	-1044(ra) # 80004a66 <filealloc>
    80004e82:	00aa3023          	sd	a0,0(s4)
    80004e86:	c92d                	beqz	a0,80004ef8 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004e88:	ffffc097          	auipc	ra,0xffffc
    80004e8c:	c5e080e7          	jalr	-930(ra) # 80000ae6 <kalloc>
    80004e90:	892a                	mv	s2,a0
    80004e92:	c125                	beqz	a0,80004ef2 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004e94:	4985                	li	s3,1
    80004e96:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004e9a:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004e9e:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004ea2:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004ea6:	00003597          	auipc	a1,0x3
    80004eaa:	67a58593          	addi	a1,a1,1658 # 80008520 <states.0+0x208>
    80004eae:	ffffc097          	auipc	ra,0xffffc
    80004eb2:	c98080e7          	jalr	-872(ra) # 80000b46 <initlock>
  (*f0)->type = FD_PIPE;
    80004eb6:	609c                	ld	a5,0(s1)
    80004eb8:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004ebc:	609c                	ld	a5,0(s1)
    80004ebe:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004ec2:	609c                	ld	a5,0(s1)
    80004ec4:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004ec8:	609c                	ld	a5,0(s1)
    80004eca:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004ece:	000a3783          	ld	a5,0(s4)
    80004ed2:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004ed6:	000a3783          	ld	a5,0(s4)
    80004eda:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004ede:	000a3783          	ld	a5,0(s4)
    80004ee2:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004ee6:	000a3783          	ld	a5,0(s4)
    80004eea:	0127b823          	sd	s2,16(a5)
  return 0;
    80004eee:	4501                	li	a0,0
    80004ef0:	a025                	j	80004f18 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004ef2:	6088                	ld	a0,0(s1)
    80004ef4:	e501                	bnez	a0,80004efc <pipealloc+0xaa>
    80004ef6:	a039                	j	80004f04 <pipealloc+0xb2>
    80004ef8:	6088                	ld	a0,0(s1)
    80004efa:	c51d                	beqz	a0,80004f28 <pipealloc+0xd6>
    fileclose(*f0);
    80004efc:	00000097          	auipc	ra,0x0
    80004f00:	c26080e7          	jalr	-986(ra) # 80004b22 <fileclose>
  if(*f1)
    80004f04:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004f08:	557d                	li	a0,-1
  if(*f1)
    80004f0a:	c799                	beqz	a5,80004f18 <pipealloc+0xc6>
    fileclose(*f1);
    80004f0c:	853e                	mv	a0,a5
    80004f0e:	00000097          	auipc	ra,0x0
    80004f12:	c14080e7          	jalr	-1004(ra) # 80004b22 <fileclose>
  return -1;
    80004f16:	557d                	li	a0,-1
}
    80004f18:	70a2                	ld	ra,40(sp)
    80004f1a:	7402                	ld	s0,32(sp)
    80004f1c:	64e2                	ld	s1,24(sp)
    80004f1e:	6942                	ld	s2,16(sp)
    80004f20:	69a2                	ld	s3,8(sp)
    80004f22:	6a02                	ld	s4,0(sp)
    80004f24:	6145                	addi	sp,sp,48
    80004f26:	8082                	ret
  return -1;
    80004f28:	557d                	li	a0,-1
    80004f2a:	b7fd                	j	80004f18 <pipealloc+0xc6>

0000000080004f2c <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004f2c:	1101                	addi	sp,sp,-32
    80004f2e:	ec06                	sd	ra,24(sp)
    80004f30:	e822                	sd	s0,16(sp)
    80004f32:	e426                	sd	s1,8(sp)
    80004f34:	e04a                	sd	s2,0(sp)
    80004f36:	1000                	addi	s0,sp,32
    80004f38:	84aa                	mv	s1,a0
    80004f3a:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004f3c:	ffffc097          	auipc	ra,0xffffc
    80004f40:	c9a080e7          	jalr	-870(ra) # 80000bd6 <acquire>
  if(writable){
    80004f44:	02090d63          	beqz	s2,80004f7e <pipeclose+0x52>
    pi->writeopen = 0;
    80004f48:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004f4c:	21848513          	addi	a0,s1,536
    80004f50:	ffffd097          	auipc	ra,0xffffd
    80004f54:	49a080e7          	jalr	1178(ra) # 800023ea <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004f58:	2204b783          	ld	a5,544(s1)
    80004f5c:	eb95                	bnez	a5,80004f90 <pipeclose+0x64>
    release(&pi->lock);
    80004f5e:	8526                	mv	a0,s1
    80004f60:	ffffc097          	auipc	ra,0xffffc
    80004f64:	d2a080e7          	jalr	-726(ra) # 80000c8a <release>
    kfree((char*)pi);
    80004f68:	8526                	mv	a0,s1
    80004f6a:	ffffc097          	auipc	ra,0xffffc
    80004f6e:	a7e080e7          	jalr	-1410(ra) # 800009e8 <kfree>
  } else
    release(&pi->lock);
}
    80004f72:	60e2                	ld	ra,24(sp)
    80004f74:	6442                	ld	s0,16(sp)
    80004f76:	64a2                	ld	s1,8(sp)
    80004f78:	6902                	ld	s2,0(sp)
    80004f7a:	6105                	addi	sp,sp,32
    80004f7c:	8082                	ret
    pi->readopen = 0;
    80004f7e:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004f82:	21c48513          	addi	a0,s1,540
    80004f86:	ffffd097          	auipc	ra,0xffffd
    80004f8a:	464080e7          	jalr	1124(ra) # 800023ea <wakeup>
    80004f8e:	b7e9                	j	80004f58 <pipeclose+0x2c>
    release(&pi->lock);
    80004f90:	8526                	mv	a0,s1
    80004f92:	ffffc097          	auipc	ra,0xffffc
    80004f96:	cf8080e7          	jalr	-776(ra) # 80000c8a <release>
}
    80004f9a:	bfe1                	j	80004f72 <pipeclose+0x46>

0000000080004f9c <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004f9c:	711d                	addi	sp,sp,-96
    80004f9e:	ec86                	sd	ra,88(sp)
    80004fa0:	e8a2                	sd	s0,80(sp)
    80004fa2:	e4a6                	sd	s1,72(sp)
    80004fa4:	e0ca                	sd	s2,64(sp)
    80004fa6:	fc4e                	sd	s3,56(sp)
    80004fa8:	f852                	sd	s4,48(sp)
    80004faa:	f456                	sd	s5,40(sp)
    80004fac:	f05a                	sd	s6,32(sp)
    80004fae:	ec5e                	sd	s7,24(sp)
    80004fb0:	e862                	sd	s8,16(sp)
    80004fb2:	1080                	addi	s0,sp,96
    80004fb4:	84aa                	mv	s1,a0
    80004fb6:	8aae                	mv	s5,a1
    80004fb8:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004fba:	ffffd097          	auipc	ra,0xffffd
    80004fbe:	9f2080e7          	jalr	-1550(ra) # 800019ac <myproc>
    80004fc2:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004fc4:	8526                	mv	a0,s1
    80004fc6:	ffffc097          	auipc	ra,0xffffc
    80004fca:	c10080e7          	jalr	-1008(ra) # 80000bd6 <acquire>
  while(i < n){
    80004fce:	0b405663          	blez	s4,8000507a <pipewrite+0xde>
  int i = 0;
    80004fd2:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004fd4:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004fd6:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004fda:	21c48b93          	addi	s7,s1,540
    80004fde:	a089                	j	80005020 <pipewrite+0x84>
      release(&pi->lock);
    80004fe0:	8526                	mv	a0,s1
    80004fe2:	ffffc097          	auipc	ra,0xffffc
    80004fe6:	ca8080e7          	jalr	-856(ra) # 80000c8a <release>
      return -1;
    80004fea:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004fec:	854a                	mv	a0,s2
    80004fee:	60e6                	ld	ra,88(sp)
    80004ff0:	6446                	ld	s0,80(sp)
    80004ff2:	64a6                	ld	s1,72(sp)
    80004ff4:	6906                	ld	s2,64(sp)
    80004ff6:	79e2                	ld	s3,56(sp)
    80004ff8:	7a42                	ld	s4,48(sp)
    80004ffa:	7aa2                	ld	s5,40(sp)
    80004ffc:	7b02                	ld	s6,32(sp)
    80004ffe:	6be2                	ld	s7,24(sp)
    80005000:	6c42                	ld	s8,16(sp)
    80005002:	6125                	addi	sp,sp,96
    80005004:	8082                	ret
      wakeup(&pi->nread);
    80005006:	8562                	mv	a0,s8
    80005008:	ffffd097          	auipc	ra,0xffffd
    8000500c:	3e2080e7          	jalr	994(ra) # 800023ea <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80005010:	85a6                	mv	a1,s1
    80005012:	855e                	mv	a0,s7
    80005014:	ffffd097          	auipc	ra,0xffffd
    80005018:	226080e7          	jalr	550(ra) # 8000223a <sleep>
  while(i < n){
    8000501c:	07495063          	bge	s2,s4,8000507c <pipewrite+0xe0>
    if(pi->readopen == 0 || killed(pr)){
    80005020:	2204a783          	lw	a5,544(s1)
    80005024:	dfd5                	beqz	a5,80004fe0 <pipewrite+0x44>
    80005026:	854e                	mv	a0,s3
    80005028:	ffffd097          	auipc	ra,0xffffd
    8000502c:	612080e7          	jalr	1554(ra) # 8000263a <killed>
    80005030:	f945                	bnez	a0,80004fe0 <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80005032:	2184a783          	lw	a5,536(s1)
    80005036:	21c4a703          	lw	a4,540(s1)
    8000503a:	2007879b          	addiw	a5,a5,512
    8000503e:	fcf704e3          	beq	a4,a5,80005006 <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80005042:	4685                	li	a3,1
    80005044:	01590633          	add	a2,s2,s5
    80005048:	faf40593          	addi	a1,s0,-81
    8000504c:	0509b503          	ld	a0,80(s3)
    80005050:	ffffc097          	auipc	ra,0xffffc
    80005054:	6a8080e7          	jalr	1704(ra) # 800016f8 <copyin>
    80005058:	03650263          	beq	a0,s6,8000507c <pipewrite+0xe0>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    8000505c:	21c4a783          	lw	a5,540(s1)
    80005060:	0017871b          	addiw	a4,a5,1
    80005064:	20e4ae23          	sw	a4,540(s1)
    80005068:	1ff7f793          	andi	a5,a5,511
    8000506c:	97a6                	add	a5,a5,s1
    8000506e:	faf44703          	lbu	a4,-81(s0)
    80005072:	00e78c23          	sb	a4,24(a5)
      i++;
    80005076:	2905                	addiw	s2,s2,1
    80005078:	b755                	j	8000501c <pipewrite+0x80>
  int i = 0;
    8000507a:	4901                	li	s2,0
  wakeup(&pi->nread);
    8000507c:	21848513          	addi	a0,s1,536
    80005080:	ffffd097          	auipc	ra,0xffffd
    80005084:	36a080e7          	jalr	874(ra) # 800023ea <wakeup>
  release(&pi->lock);
    80005088:	8526                	mv	a0,s1
    8000508a:	ffffc097          	auipc	ra,0xffffc
    8000508e:	c00080e7          	jalr	-1024(ra) # 80000c8a <release>
  return i;
    80005092:	bfa9                	j	80004fec <pipewrite+0x50>

0000000080005094 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80005094:	715d                	addi	sp,sp,-80
    80005096:	e486                	sd	ra,72(sp)
    80005098:	e0a2                	sd	s0,64(sp)
    8000509a:	fc26                	sd	s1,56(sp)
    8000509c:	f84a                	sd	s2,48(sp)
    8000509e:	f44e                	sd	s3,40(sp)
    800050a0:	f052                	sd	s4,32(sp)
    800050a2:	ec56                	sd	s5,24(sp)
    800050a4:	e85a                	sd	s6,16(sp)
    800050a6:	0880                	addi	s0,sp,80
    800050a8:	84aa                	mv	s1,a0
    800050aa:	892e                	mv	s2,a1
    800050ac:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    800050ae:	ffffd097          	auipc	ra,0xffffd
    800050b2:	8fe080e7          	jalr	-1794(ra) # 800019ac <myproc>
    800050b6:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    800050b8:	8526                	mv	a0,s1
    800050ba:	ffffc097          	auipc	ra,0xffffc
    800050be:	b1c080e7          	jalr	-1252(ra) # 80000bd6 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    800050c2:	2184a703          	lw	a4,536(s1)
    800050c6:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    800050ca:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    800050ce:	02f71763          	bne	a4,a5,800050fc <piperead+0x68>
    800050d2:	2244a783          	lw	a5,548(s1)
    800050d6:	c39d                	beqz	a5,800050fc <piperead+0x68>
    if(killed(pr)){
    800050d8:	8552                	mv	a0,s4
    800050da:	ffffd097          	auipc	ra,0xffffd
    800050de:	560080e7          	jalr	1376(ra) # 8000263a <killed>
    800050e2:	e949                	bnez	a0,80005174 <piperead+0xe0>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    800050e4:	85a6                	mv	a1,s1
    800050e6:	854e                	mv	a0,s3
    800050e8:	ffffd097          	auipc	ra,0xffffd
    800050ec:	152080e7          	jalr	338(ra) # 8000223a <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    800050f0:	2184a703          	lw	a4,536(s1)
    800050f4:	21c4a783          	lw	a5,540(s1)
    800050f8:	fcf70de3          	beq	a4,a5,800050d2 <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800050fc:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    800050fe:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005100:	05505463          	blez	s5,80005148 <piperead+0xb4>
    if(pi->nread == pi->nwrite)
    80005104:	2184a783          	lw	a5,536(s1)
    80005108:	21c4a703          	lw	a4,540(s1)
    8000510c:	02f70e63          	beq	a4,a5,80005148 <piperead+0xb4>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80005110:	0017871b          	addiw	a4,a5,1
    80005114:	20e4ac23          	sw	a4,536(s1)
    80005118:	1ff7f793          	andi	a5,a5,511
    8000511c:	97a6                	add	a5,a5,s1
    8000511e:	0187c783          	lbu	a5,24(a5)
    80005122:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80005126:	4685                	li	a3,1
    80005128:	fbf40613          	addi	a2,s0,-65
    8000512c:	85ca                	mv	a1,s2
    8000512e:	050a3503          	ld	a0,80(s4)
    80005132:	ffffc097          	auipc	ra,0xffffc
    80005136:	53a080e7          	jalr	1338(ra) # 8000166c <copyout>
    8000513a:	01650763          	beq	a0,s6,80005148 <piperead+0xb4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    8000513e:	2985                	addiw	s3,s3,1
    80005140:	0905                	addi	s2,s2,1
    80005142:	fd3a91e3          	bne	s5,s3,80005104 <piperead+0x70>
    80005146:	89d6                	mv	s3,s5
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80005148:	21c48513          	addi	a0,s1,540
    8000514c:	ffffd097          	auipc	ra,0xffffd
    80005150:	29e080e7          	jalr	670(ra) # 800023ea <wakeup>
  release(&pi->lock);
    80005154:	8526                	mv	a0,s1
    80005156:	ffffc097          	auipc	ra,0xffffc
    8000515a:	b34080e7          	jalr	-1228(ra) # 80000c8a <release>
  return i;
}
    8000515e:	854e                	mv	a0,s3
    80005160:	60a6                	ld	ra,72(sp)
    80005162:	6406                	ld	s0,64(sp)
    80005164:	74e2                	ld	s1,56(sp)
    80005166:	7942                	ld	s2,48(sp)
    80005168:	79a2                	ld	s3,40(sp)
    8000516a:	7a02                	ld	s4,32(sp)
    8000516c:	6ae2                	ld	s5,24(sp)
    8000516e:	6b42                	ld	s6,16(sp)
    80005170:	6161                	addi	sp,sp,80
    80005172:	8082                	ret
      release(&pi->lock);
    80005174:	8526                	mv	a0,s1
    80005176:	ffffc097          	auipc	ra,0xffffc
    8000517a:	b14080e7          	jalr	-1260(ra) # 80000c8a <release>
      return -1;
    8000517e:	59fd                	li	s3,-1
    80005180:	bff9                	j	8000515e <piperead+0xca>

0000000080005182 <flags2perm>:
#include "elf.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

int flags2perm(int flags)
{
    80005182:	1141                	addi	sp,sp,-16
    80005184:	e422                	sd	s0,8(sp)
    80005186:	0800                	addi	s0,sp,16
    80005188:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    8000518a:	8905                	andi	a0,a0,1
    8000518c:	050e                	slli	a0,a0,0x3
      perm = PTE_X;
    if(flags & 0x2)
    8000518e:	8b89                	andi	a5,a5,2
    80005190:	c399                	beqz	a5,80005196 <flags2perm+0x14>
      perm |= PTE_W;
    80005192:	00456513          	ori	a0,a0,4
    return perm;
}
    80005196:	6422                	ld	s0,8(sp)
    80005198:	0141                	addi	sp,sp,16
    8000519a:	8082                	ret

000000008000519c <exec>:

int
exec(char *path, char **argv)
{
    8000519c:	de010113          	addi	sp,sp,-544
    800051a0:	20113c23          	sd	ra,536(sp)
    800051a4:	20813823          	sd	s0,528(sp)
    800051a8:	20913423          	sd	s1,520(sp)
    800051ac:	21213023          	sd	s2,512(sp)
    800051b0:	ffce                	sd	s3,504(sp)
    800051b2:	fbd2                	sd	s4,496(sp)
    800051b4:	f7d6                	sd	s5,488(sp)
    800051b6:	f3da                	sd	s6,480(sp)
    800051b8:	efde                	sd	s7,472(sp)
    800051ba:	ebe2                	sd	s8,464(sp)
    800051bc:	e7e6                	sd	s9,456(sp)
    800051be:	e3ea                	sd	s10,448(sp)
    800051c0:	ff6e                	sd	s11,440(sp)
    800051c2:	1400                	addi	s0,sp,544
    800051c4:	892a                	mv	s2,a0
    800051c6:	dea43423          	sd	a0,-536(s0)
    800051ca:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    800051ce:	ffffc097          	auipc	ra,0xffffc
    800051d2:	7de080e7          	jalr	2014(ra) # 800019ac <myproc>
    800051d6:	84aa                	mv	s1,a0

  begin_op();
    800051d8:	fffff097          	auipc	ra,0xfffff
    800051dc:	482080e7          	jalr	1154(ra) # 8000465a <begin_op>

  if((ip = namei(path)) == 0){
    800051e0:	854a                	mv	a0,s2
    800051e2:	fffff097          	auipc	ra,0xfffff
    800051e6:	258080e7          	jalr	600(ra) # 8000443a <namei>
    800051ea:	c93d                	beqz	a0,80005260 <exec+0xc4>
    800051ec:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    800051ee:	fffff097          	auipc	ra,0xfffff
    800051f2:	aa0080e7          	jalr	-1376(ra) # 80003c8e <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    800051f6:	04000713          	li	a4,64
    800051fa:	4681                	li	a3,0
    800051fc:	e5040613          	addi	a2,s0,-432
    80005200:	4581                	li	a1,0
    80005202:	8556                	mv	a0,s5
    80005204:	fffff097          	auipc	ra,0xfffff
    80005208:	d3e080e7          	jalr	-706(ra) # 80003f42 <readi>
    8000520c:	04000793          	li	a5,64
    80005210:	00f51a63          	bne	a0,a5,80005224 <exec+0x88>
    goto bad;

  if(elf.magic != ELF_MAGIC)
    80005214:	e5042703          	lw	a4,-432(s0)
    80005218:	464c47b7          	lui	a5,0x464c4
    8000521c:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80005220:	04f70663          	beq	a4,a5,8000526c <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80005224:	8556                	mv	a0,s5
    80005226:	fffff097          	auipc	ra,0xfffff
    8000522a:	cca080e7          	jalr	-822(ra) # 80003ef0 <iunlockput>
    end_op();
    8000522e:	fffff097          	auipc	ra,0xfffff
    80005232:	4aa080e7          	jalr	1194(ra) # 800046d8 <end_op>
  }
  return -1;
    80005236:	557d                	li	a0,-1
}
    80005238:	21813083          	ld	ra,536(sp)
    8000523c:	21013403          	ld	s0,528(sp)
    80005240:	20813483          	ld	s1,520(sp)
    80005244:	20013903          	ld	s2,512(sp)
    80005248:	79fe                	ld	s3,504(sp)
    8000524a:	7a5e                	ld	s4,496(sp)
    8000524c:	7abe                	ld	s5,488(sp)
    8000524e:	7b1e                	ld	s6,480(sp)
    80005250:	6bfe                	ld	s7,472(sp)
    80005252:	6c5e                	ld	s8,464(sp)
    80005254:	6cbe                	ld	s9,456(sp)
    80005256:	6d1e                	ld	s10,448(sp)
    80005258:	7dfa                	ld	s11,440(sp)
    8000525a:	22010113          	addi	sp,sp,544
    8000525e:	8082                	ret
    end_op();
    80005260:	fffff097          	auipc	ra,0xfffff
    80005264:	478080e7          	jalr	1144(ra) # 800046d8 <end_op>
    return -1;
    80005268:	557d                	li	a0,-1
    8000526a:	b7f9                	j	80005238 <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    8000526c:	8526                	mv	a0,s1
    8000526e:	ffffd097          	auipc	ra,0xffffd
    80005272:	802080e7          	jalr	-2046(ra) # 80001a70 <proc_pagetable>
    80005276:	8b2a                	mv	s6,a0
    80005278:	d555                	beqz	a0,80005224 <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    8000527a:	e7042783          	lw	a5,-400(s0)
    8000527e:	e8845703          	lhu	a4,-376(s0)
    80005282:	c735                	beqz	a4,800052ee <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80005284:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005286:	e0043423          	sd	zero,-504(s0)
    if(ph.vaddr % PGSIZE != 0)
    8000528a:	6a05                	lui	s4,0x1
    8000528c:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    80005290:	dee43023          	sd	a4,-544(s0)
loadseg(pagetable_t pagetable, uint64 va, struct inode *ip, uint offset, uint sz)
{
  uint i, n;
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    80005294:	6d85                	lui	s11,0x1
    80005296:	7d7d                	lui	s10,0xfffff
    80005298:	ac3d                	j	800054d6 <exec+0x33a>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    8000529a:	00003517          	auipc	a0,0x3
    8000529e:	5d650513          	addi	a0,a0,1494 # 80008870 <syscalls+0x290>
    800052a2:	ffffb097          	auipc	ra,0xffffb
    800052a6:	29e080e7          	jalr	670(ra) # 80000540 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    800052aa:	874a                	mv	a4,s2
    800052ac:	009c86bb          	addw	a3,s9,s1
    800052b0:	4581                	li	a1,0
    800052b2:	8556                	mv	a0,s5
    800052b4:	fffff097          	auipc	ra,0xfffff
    800052b8:	c8e080e7          	jalr	-882(ra) # 80003f42 <readi>
    800052bc:	2501                	sext.w	a0,a0
    800052be:	1aa91963          	bne	s2,a0,80005470 <exec+0x2d4>
  for(i = 0; i < sz; i += PGSIZE){
    800052c2:	009d84bb          	addw	s1,s11,s1
    800052c6:	013d09bb          	addw	s3,s10,s3
    800052ca:	1f74f663          	bgeu	s1,s7,800054b6 <exec+0x31a>
    pa = walkaddr(pagetable, va + i);
    800052ce:	02049593          	slli	a1,s1,0x20
    800052d2:	9181                	srli	a1,a1,0x20
    800052d4:	95e2                	add	a1,a1,s8
    800052d6:	855a                	mv	a0,s6
    800052d8:	ffffc097          	auipc	ra,0xffffc
    800052dc:	d84080e7          	jalr	-636(ra) # 8000105c <walkaddr>
    800052e0:	862a                	mv	a2,a0
    if(pa == 0)
    800052e2:	dd45                	beqz	a0,8000529a <exec+0xfe>
      n = PGSIZE;
    800052e4:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    800052e6:	fd49f2e3          	bgeu	s3,s4,800052aa <exec+0x10e>
      n = sz - i;
    800052ea:	894e                	mv	s2,s3
    800052ec:	bf7d                	j	800052aa <exec+0x10e>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    800052ee:	4901                	li	s2,0
  iunlockput(ip);
    800052f0:	8556                	mv	a0,s5
    800052f2:	fffff097          	auipc	ra,0xfffff
    800052f6:	bfe080e7          	jalr	-1026(ra) # 80003ef0 <iunlockput>
  end_op();
    800052fa:	fffff097          	auipc	ra,0xfffff
    800052fe:	3de080e7          	jalr	990(ra) # 800046d8 <end_op>
  p = myproc();
    80005302:	ffffc097          	auipc	ra,0xffffc
    80005306:	6aa080e7          	jalr	1706(ra) # 800019ac <myproc>
    8000530a:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    8000530c:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80005310:	6785                	lui	a5,0x1
    80005312:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80005314:	97ca                	add	a5,a5,s2
    80005316:	777d                	lui	a4,0xfffff
    80005318:	8ff9                	and	a5,a5,a4
    8000531a:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    8000531e:	4691                	li	a3,4
    80005320:	6609                	lui	a2,0x2
    80005322:	963e                	add	a2,a2,a5
    80005324:	85be                	mv	a1,a5
    80005326:	855a                	mv	a0,s6
    80005328:	ffffc097          	auipc	ra,0xffffc
    8000532c:	0e8080e7          	jalr	232(ra) # 80001410 <uvmalloc>
    80005330:	8c2a                	mv	s8,a0
  ip = 0;
    80005332:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80005334:	12050e63          	beqz	a0,80005470 <exec+0x2d4>
  uvmclear(pagetable, sz-2*PGSIZE);
    80005338:	75f9                	lui	a1,0xffffe
    8000533a:	95aa                	add	a1,a1,a0
    8000533c:	855a                	mv	a0,s6
    8000533e:	ffffc097          	auipc	ra,0xffffc
    80005342:	2fc080e7          	jalr	764(ra) # 8000163a <uvmclear>
  stackbase = sp - PGSIZE;
    80005346:	7afd                	lui	s5,0xfffff
    80005348:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    8000534a:	df043783          	ld	a5,-528(s0)
    8000534e:	6388                	ld	a0,0(a5)
    80005350:	c925                	beqz	a0,800053c0 <exec+0x224>
    80005352:	e9040993          	addi	s3,s0,-368
    80005356:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    8000535a:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    8000535c:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    8000535e:	ffffc097          	auipc	ra,0xffffc
    80005362:	af0080e7          	jalr	-1296(ra) # 80000e4e <strlen>
    80005366:	0015079b          	addiw	a5,a0,1
    8000536a:	40f907b3          	sub	a5,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    8000536e:	ff07f913          	andi	s2,a5,-16
    if(sp < stackbase)
    80005372:	13596663          	bltu	s2,s5,8000549e <exec+0x302>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80005376:	df043d83          	ld	s11,-528(s0)
    8000537a:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    8000537e:	8552                	mv	a0,s4
    80005380:	ffffc097          	auipc	ra,0xffffc
    80005384:	ace080e7          	jalr	-1330(ra) # 80000e4e <strlen>
    80005388:	0015069b          	addiw	a3,a0,1
    8000538c:	8652                	mv	a2,s4
    8000538e:	85ca                	mv	a1,s2
    80005390:	855a                	mv	a0,s6
    80005392:	ffffc097          	auipc	ra,0xffffc
    80005396:	2da080e7          	jalr	730(ra) # 8000166c <copyout>
    8000539a:	10054663          	bltz	a0,800054a6 <exec+0x30a>
    ustack[argc] = sp;
    8000539e:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    800053a2:	0485                	addi	s1,s1,1
    800053a4:	008d8793          	addi	a5,s11,8
    800053a8:	def43823          	sd	a5,-528(s0)
    800053ac:	008db503          	ld	a0,8(s11)
    800053b0:	c911                	beqz	a0,800053c4 <exec+0x228>
    if(argc >= MAXARG)
    800053b2:	09a1                	addi	s3,s3,8
    800053b4:	fb3c95e3          	bne	s9,s3,8000535e <exec+0x1c2>
  sz = sz1;
    800053b8:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800053bc:	4a81                	li	s5,0
    800053be:	a84d                	j	80005470 <exec+0x2d4>
  sp = sz;
    800053c0:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    800053c2:	4481                	li	s1,0
  ustack[argc] = 0;
    800053c4:	00349793          	slli	a5,s1,0x3
    800053c8:	f9078793          	addi	a5,a5,-112
    800053cc:	97a2                	add	a5,a5,s0
    800053ce:	f007b023          	sd	zero,-256(a5)
  sp -= (argc+1) * sizeof(uint64);
    800053d2:	00148693          	addi	a3,s1,1
    800053d6:	068e                	slli	a3,a3,0x3
    800053d8:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    800053dc:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    800053e0:	01597663          	bgeu	s2,s5,800053ec <exec+0x250>
  sz = sz1;
    800053e4:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800053e8:	4a81                	li	s5,0
    800053ea:	a059                	j	80005470 <exec+0x2d4>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    800053ec:	e9040613          	addi	a2,s0,-368
    800053f0:	85ca                	mv	a1,s2
    800053f2:	855a                	mv	a0,s6
    800053f4:	ffffc097          	auipc	ra,0xffffc
    800053f8:	278080e7          	jalr	632(ra) # 8000166c <copyout>
    800053fc:	0a054963          	bltz	a0,800054ae <exec+0x312>
  p->trapframe->a1 = sp;
    80005400:	058bb783          	ld	a5,88(s7)
    80005404:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80005408:	de843783          	ld	a5,-536(s0)
    8000540c:	0007c703          	lbu	a4,0(a5)
    80005410:	cf11                	beqz	a4,8000542c <exec+0x290>
    80005412:	0785                	addi	a5,a5,1
    if(*s == '/')
    80005414:	02f00693          	li	a3,47
    80005418:	a039                	j	80005426 <exec+0x28a>
      last = s+1;
    8000541a:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    8000541e:	0785                	addi	a5,a5,1
    80005420:	fff7c703          	lbu	a4,-1(a5)
    80005424:	c701                	beqz	a4,8000542c <exec+0x290>
    if(*s == '/')
    80005426:	fed71ce3          	bne	a4,a3,8000541e <exec+0x282>
    8000542a:	bfc5                	j	8000541a <exec+0x27e>
  safestrcpy(p->name, last, sizeof(p->name));
    8000542c:	4641                	li	a2,16
    8000542e:	de843583          	ld	a1,-536(s0)
    80005432:	158b8513          	addi	a0,s7,344
    80005436:	ffffc097          	auipc	ra,0xffffc
    8000543a:	9e6080e7          	jalr	-1562(ra) # 80000e1c <safestrcpy>
  oldpagetable = p->pagetable;
    8000543e:	050bb503          	ld	a0,80(s7)
  p->pagetable = pagetable;
    80005442:	056bb823          	sd	s6,80(s7)
  p->sz = sz;
    80005446:	058bb423          	sd	s8,72(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    8000544a:	058bb783          	ld	a5,88(s7)
    8000544e:	e6843703          	ld	a4,-408(s0)
    80005452:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80005454:	058bb783          	ld	a5,88(s7)
    80005458:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    8000545c:	85ea                	mv	a1,s10
    8000545e:	ffffc097          	auipc	ra,0xffffc
    80005462:	6ae080e7          	jalr	1710(ra) # 80001b0c <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80005466:	0004851b          	sext.w	a0,s1
    8000546a:	b3f9                	j	80005238 <exec+0x9c>
    8000546c:	df243c23          	sd	s2,-520(s0)
    proc_freepagetable(pagetable, sz);
    80005470:	df843583          	ld	a1,-520(s0)
    80005474:	855a                	mv	a0,s6
    80005476:	ffffc097          	auipc	ra,0xffffc
    8000547a:	696080e7          	jalr	1686(ra) # 80001b0c <proc_freepagetable>
  if(ip){
    8000547e:	da0a93e3          	bnez	s5,80005224 <exec+0x88>
  return -1;
    80005482:	557d                	li	a0,-1
    80005484:	bb55                	j	80005238 <exec+0x9c>
    80005486:	df243c23          	sd	s2,-520(s0)
    8000548a:	b7dd                	j	80005470 <exec+0x2d4>
    8000548c:	df243c23          	sd	s2,-520(s0)
    80005490:	b7c5                	j	80005470 <exec+0x2d4>
    80005492:	df243c23          	sd	s2,-520(s0)
    80005496:	bfe9                	j	80005470 <exec+0x2d4>
    80005498:	df243c23          	sd	s2,-520(s0)
    8000549c:	bfd1                	j	80005470 <exec+0x2d4>
  sz = sz1;
    8000549e:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800054a2:	4a81                	li	s5,0
    800054a4:	b7f1                	j	80005470 <exec+0x2d4>
  sz = sz1;
    800054a6:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800054aa:	4a81                	li	s5,0
    800054ac:	b7d1                	j	80005470 <exec+0x2d4>
  sz = sz1;
    800054ae:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800054b2:	4a81                	li	s5,0
    800054b4:	bf75                	j	80005470 <exec+0x2d4>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    800054b6:	df843903          	ld	s2,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800054ba:	e0843783          	ld	a5,-504(s0)
    800054be:	0017869b          	addiw	a3,a5,1
    800054c2:	e0d43423          	sd	a3,-504(s0)
    800054c6:	e0043783          	ld	a5,-512(s0)
    800054ca:	0387879b          	addiw	a5,a5,56
    800054ce:	e8845703          	lhu	a4,-376(s0)
    800054d2:	e0e6dfe3          	bge	a3,a4,800052f0 <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    800054d6:	2781                	sext.w	a5,a5
    800054d8:	e0f43023          	sd	a5,-512(s0)
    800054dc:	03800713          	li	a4,56
    800054e0:	86be                	mv	a3,a5
    800054e2:	e1840613          	addi	a2,s0,-488
    800054e6:	4581                	li	a1,0
    800054e8:	8556                	mv	a0,s5
    800054ea:	fffff097          	auipc	ra,0xfffff
    800054ee:	a58080e7          	jalr	-1448(ra) # 80003f42 <readi>
    800054f2:	03800793          	li	a5,56
    800054f6:	f6f51be3          	bne	a0,a5,8000546c <exec+0x2d0>
    if(ph.type != ELF_PROG_LOAD)
    800054fa:	e1842783          	lw	a5,-488(s0)
    800054fe:	4705                	li	a4,1
    80005500:	fae79de3          	bne	a5,a4,800054ba <exec+0x31e>
    if(ph.memsz < ph.filesz)
    80005504:	e4043483          	ld	s1,-448(s0)
    80005508:	e3843783          	ld	a5,-456(s0)
    8000550c:	f6f4ede3          	bltu	s1,a5,80005486 <exec+0x2ea>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80005510:	e2843783          	ld	a5,-472(s0)
    80005514:	94be                	add	s1,s1,a5
    80005516:	f6f4ebe3          	bltu	s1,a5,8000548c <exec+0x2f0>
    if(ph.vaddr % PGSIZE != 0)
    8000551a:	de043703          	ld	a4,-544(s0)
    8000551e:	8ff9                	and	a5,a5,a4
    80005520:	fbad                	bnez	a5,80005492 <exec+0x2f6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80005522:	e1c42503          	lw	a0,-484(s0)
    80005526:	00000097          	auipc	ra,0x0
    8000552a:	c5c080e7          	jalr	-932(ra) # 80005182 <flags2perm>
    8000552e:	86aa                	mv	a3,a0
    80005530:	8626                	mv	a2,s1
    80005532:	85ca                	mv	a1,s2
    80005534:	855a                	mv	a0,s6
    80005536:	ffffc097          	auipc	ra,0xffffc
    8000553a:	eda080e7          	jalr	-294(ra) # 80001410 <uvmalloc>
    8000553e:	dea43c23          	sd	a0,-520(s0)
    80005542:	d939                	beqz	a0,80005498 <exec+0x2fc>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80005544:	e2843c03          	ld	s8,-472(s0)
    80005548:	e2042c83          	lw	s9,-480(s0)
    8000554c:	e3842b83          	lw	s7,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005550:	f60b83e3          	beqz	s7,800054b6 <exec+0x31a>
    80005554:	89de                	mv	s3,s7
    80005556:	4481                	li	s1,0
    80005558:	bb9d                	j	800052ce <exec+0x132>

000000008000555a <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    8000555a:	7179                	addi	sp,sp,-48
    8000555c:	f406                	sd	ra,40(sp)
    8000555e:	f022                	sd	s0,32(sp)
    80005560:	ec26                	sd	s1,24(sp)
    80005562:	e84a                	sd	s2,16(sp)
    80005564:	1800                	addi	s0,sp,48
    80005566:	892e                	mv	s2,a1
    80005568:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    8000556a:	fdc40593          	addi	a1,s0,-36
    8000556e:	ffffe097          	auipc	ra,0xffffe
    80005572:	9a6080e7          	jalr	-1626(ra) # 80002f14 <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005576:	fdc42703          	lw	a4,-36(s0)
    8000557a:	47bd                	li	a5,15
    8000557c:	02e7eb63          	bltu	a5,a4,800055b2 <argfd+0x58>
    80005580:	ffffc097          	auipc	ra,0xffffc
    80005584:	42c080e7          	jalr	1068(ra) # 800019ac <myproc>
    80005588:	fdc42703          	lw	a4,-36(s0)
    8000558c:	01a70793          	addi	a5,a4,26 # fffffffffffff01a <end+0xffffffff7ffdbfea>
    80005590:	078e                	slli	a5,a5,0x3
    80005592:	953e                	add	a0,a0,a5
    80005594:	611c                	ld	a5,0(a0)
    80005596:	c385                	beqz	a5,800055b6 <argfd+0x5c>
    return -1;
  if(pfd)
    80005598:	00090463          	beqz	s2,800055a0 <argfd+0x46>
    *pfd = fd;
    8000559c:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    800055a0:	4501                	li	a0,0
  if(pf)
    800055a2:	c091                	beqz	s1,800055a6 <argfd+0x4c>
    *pf = f;
    800055a4:	e09c                	sd	a5,0(s1)
}
    800055a6:	70a2                	ld	ra,40(sp)
    800055a8:	7402                	ld	s0,32(sp)
    800055aa:	64e2                	ld	s1,24(sp)
    800055ac:	6942                	ld	s2,16(sp)
    800055ae:	6145                	addi	sp,sp,48
    800055b0:	8082                	ret
    return -1;
    800055b2:	557d                	li	a0,-1
    800055b4:	bfcd                	j	800055a6 <argfd+0x4c>
    800055b6:	557d                	li	a0,-1
    800055b8:	b7fd                	j	800055a6 <argfd+0x4c>

00000000800055ba <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    800055ba:	1101                	addi	sp,sp,-32
    800055bc:	ec06                	sd	ra,24(sp)
    800055be:	e822                	sd	s0,16(sp)
    800055c0:	e426                	sd	s1,8(sp)
    800055c2:	1000                	addi	s0,sp,32
    800055c4:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    800055c6:	ffffc097          	auipc	ra,0xffffc
    800055ca:	3e6080e7          	jalr	998(ra) # 800019ac <myproc>
    800055ce:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    800055d0:	0d050793          	addi	a5,a0,208
    800055d4:	4501                	li	a0,0
    800055d6:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    800055d8:	6398                	ld	a4,0(a5)
    800055da:	cb19                	beqz	a4,800055f0 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    800055dc:	2505                	addiw	a0,a0,1
    800055de:	07a1                	addi	a5,a5,8
    800055e0:	fed51ce3          	bne	a0,a3,800055d8 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    800055e4:	557d                	li	a0,-1
}
    800055e6:	60e2                	ld	ra,24(sp)
    800055e8:	6442                	ld	s0,16(sp)
    800055ea:	64a2                	ld	s1,8(sp)
    800055ec:	6105                	addi	sp,sp,32
    800055ee:	8082                	ret
      p->ofile[fd] = f;
    800055f0:	01a50793          	addi	a5,a0,26
    800055f4:	078e                	slli	a5,a5,0x3
    800055f6:	963e                	add	a2,a2,a5
    800055f8:	e204                	sd	s1,0(a2)
      return fd;
    800055fa:	b7f5                	j	800055e6 <fdalloc+0x2c>

00000000800055fc <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    800055fc:	715d                	addi	sp,sp,-80
    800055fe:	e486                	sd	ra,72(sp)
    80005600:	e0a2                	sd	s0,64(sp)
    80005602:	fc26                	sd	s1,56(sp)
    80005604:	f84a                	sd	s2,48(sp)
    80005606:	f44e                	sd	s3,40(sp)
    80005608:	f052                	sd	s4,32(sp)
    8000560a:	ec56                	sd	s5,24(sp)
    8000560c:	e85a                	sd	s6,16(sp)
    8000560e:	0880                	addi	s0,sp,80
    80005610:	8b2e                	mv	s6,a1
    80005612:	89b2                	mv	s3,a2
    80005614:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005616:	fb040593          	addi	a1,s0,-80
    8000561a:	fffff097          	auipc	ra,0xfffff
    8000561e:	e3e080e7          	jalr	-450(ra) # 80004458 <nameiparent>
    80005622:	84aa                	mv	s1,a0
    80005624:	14050f63          	beqz	a0,80005782 <create+0x186>
    return 0;

  ilock(dp);
    80005628:	ffffe097          	auipc	ra,0xffffe
    8000562c:	666080e7          	jalr	1638(ra) # 80003c8e <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005630:	4601                	li	a2,0
    80005632:	fb040593          	addi	a1,s0,-80
    80005636:	8526                	mv	a0,s1
    80005638:	fffff097          	auipc	ra,0xfffff
    8000563c:	b3a080e7          	jalr	-1222(ra) # 80004172 <dirlookup>
    80005640:	8aaa                	mv	s5,a0
    80005642:	c931                	beqz	a0,80005696 <create+0x9a>
    iunlockput(dp);
    80005644:	8526                	mv	a0,s1
    80005646:	fffff097          	auipc	ra,0xfffff
    8000564a:	8aa080e7          	jalr	-1878(ra) # 80003ef0 <iunlockput>
    ilock(ip);
    8000564e:	8556                	mv	a0,s5
    80005650:	ffffe097          	auipc	ra,0xffffe
    80005654:	63e080e7          	jalr	1598(ra) # 80003c8e <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005658:	000b059b          	sext.w	a1,s6
    8000565c:	4789                	li	a5,2
    8000565e:	02f59563          	bne	a1,a5,80005688 <create+0x8c>
    80005662:	044ad783          	lhu	a5,68(s5) # fffffffffffff044 <end+0xffffffff7ffdc014>
    80005666:	37f9                	addiw	a5,a5,-2
    80005668:	17c2                	slli	a5,a5,0x30
    8000566a:	93c1                	srli	a5,a5,0x30
    8000566c:	4705                	li	a4,1
    8000566e:	00f76d63          	bltu	a4,a5,80005688 <create+0x8c>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    80005672:	8556                	mv	a0,s5
    80005674:	60a6                	ld	ra,72(sp)
    80005676:	6406                	ld	s0,64(sp)
    80005678:	74e2                	ld	s1,56(sp)
    8000567a:	7942                	ld	s2,48(sp)
    8000567c:	79a2                	ld	s3,40(sp)
    8000567e:	7a02                	ld	s4,32(sp)
    80005680:	6ae2                	ld	s5,24(sp)
    80005682:	6b42                	ld	s6,16(sp)
    80005684:	6161                	addi	sp,sp,80
    80005686:	8082                	ret
    iunlockput(ip);
    80005688:	8556                	mv	a0,s5
    8000568a:	fffff097          	auipc	ra,0xfffff
    8000568e:	866080e7          	jalr	-1946(ra) # 80003ef0 <iunlockput>
    return 0;
    80005692:	4a81                	li	s5,0
    80005694:	bff9                	j	80005672 <create+0x76>
  if((ip = ialloc(dp->dev, type)) == 0){
    80005696:	85da                	mv	a1,s6
    80005698:	4088                	lw	a0,0(s1)
    8000569a:	ffffe097          	auipc	ra,0xffffe
    8000569e:	456080e7          	jalr	1110(ra) # 80003af0 <ialloc>
    800056a2:	8a2a                	mv	s4,a0
    800056a4:	c539                	beqz	a0,800056f2 <create+0xf6>
  ilock(ip);
    800056a6:	ffffe097          	auipc	ra,0xffffe
    800056aa:	5e8080e7          	jalr	1512(ra) # 80003c8e <ilock>
  ip->major = major;
    800056ae:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    800056b2:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    800056b6:	4905                	li	s2,1
    800056b8:	052a1523          	sh	s2,74(s4)
  iupdate(ip);
    800056bc:	8552                	mv	a0,s4
    800056be:	ffffe097          	auipc	ra,0xffffe
    800056c2:	504080e7          	jalr	1284(ra) # 80003bc2 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    800056c6:	000b059b          	sext.w	a1,s6
    800056ca:	03258b63          	beq	a1,s2,80005700 <create+0x104>
  if(dirlink(dp, name, ip->inum) < 0)
    800056ce:	004a2603          	lw	a2,4(s4)
    800056d2:	fb040593          	addi	a1,s0,-80
    800056d6:	8526                	mv	a0,s1
    800056d8:	fffff097          	auipc	ra,0xfffff
    800056dc:	cb0080e7          	jalr	-848(ra) # 80004388 <dirlink>
    800056e0:	06054f63          	bltz	a0,8000575e <create+0x162>
  iunlockput(dp);
    800056e4:	8526                	mv	a0,s1
    800056e6:	fffff097          	auipc	ra,0xfffff
    800056ea:	80a080e7          	jalr	-2038(ra) # 80003ef0 <iunlockput>
  return ip;
    800056ee:	8ad2                	mv	s5,s4
    800056f0:	b749                	j	80005672 <create+0x76>
    iunlockput(dp);
    800056f2:	8526                	mv	a0,s1
    800056f4:	ffffe097          	auipc	ra,0xffffe
    800056f8:	7fc080e7          	jalr	2044(ra) # 80003ef0 <iunlockput>
    return 0;
    800056fc:	8ad2                	mv	s5,s4
    800056fe:	bf95                	j	80005672 <create+0x76>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005700:	004a2603          	lw	a2,4(s4)
    80005704:	00003597          	auipc	a1,0x3
    80005708:	18c58593          	addi	a1,a1,396 # 80008890 <syscalls+0x2b0>
    8000570c:	8552                	mv	a0,s4
    8000570e:	fffff097          	auipc	ra,0xfffff
    80005712:	c7a080e7          	jalr	-902(ra) # 80004388 <dirlink>
    80005716:	04054463          	bltz	a0,8000575e <create+0x162>
    8000571a:	40d0                	lw	a2,4(s1)
    8000571c:	00003597          	auipc	a1,0x3
    80005720:	17c58593          	addi	a1,a1,380 # 80008898 <syscalls+0x2b8>
    80005724:	8552                	mv	a0,s4
    80005726:	fffff097          	auipc	ra,0xfffff
    8000572a:	c62080e7          	jalr	-926(ra) # 80004388 <dirlink>
    8000572e:	02054863          	bltz	a0,8000575e <create+0x162>
  if(dirlink(dp, name, ip->inum) < 0)
    80005732:	004a2603          	lw	a2,4(s4)
    80005736:	fb040593          	addi	a1,s0,-80
    8000573a:	8526                	mv	a0,s1
    8000573c:	fffff097          	auipc	ra,0xfffff
    80005740:	c4c080e7          	jalr	-948(ra) # 80004388 <dirlink>
    80005744:	00054d63          	bltz	a0,8000575e <create+0x162>
    dp->nlink++;  // for ".."
    80005748:	04a4d783          	lhu	a5,74(s1)
    8000574c:	2785                	addiw	a5,a5,1
    8000574e:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005752:	8526                	mv	a0,s1
    80005754:	ffffe097          	auipc	ra,0xffffe
    80005758:	46e080e7          	jalr	1134(ra) # 80003bc2 <iupdate>
    8000575c:	b761                	j	800056e4 <create+0xe8>
  ip->nlink = 0;
    8000575e:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    80005762:	8552                	mv	a0,s4
    80005764:	ffffe097          	auipc	ra,0xffffe
    80005768:	45e080e7          	jalr	1118(ra) # 80003bc2 <iupdate>
  iunlockput(ip);
    8000576c:	8552                	mv	a0,s4
    8000576e:	ffffe097          	auipc	ra,0xffffe
    80005772:	782080e7          	jalr	1922(ra) # 80003ef0 <iunlockput>
  iunlockput(dp);
    80005776:	8526                	mv	a0,s1
    80005778:	ffffe097          	auipc	ra,0xffffe
    8000577c:	778080e7          	jalr	1912(ra) # 80003ef0 <iunlockput>
  return 0;
    80005780:	bdcd                	j	80005672 <create+0x76>
    return 0;
    80005782:	8aaa                	mv	s5,a0
    80005784:	b5fd                	j	80005672 <create+0x76>

0000000080005786 <sys_dup>:
{
    80005786:	7179                	addi	sp,sp,-48
    80005788:	f406                	sd	ra,40(sp)
    8000578a:	f022                	sd	s0,32(sp)
    8000578c:	ec26                	sd	s1,24(sp)
    8000578e:	e84a                	sd	s2,16(sp)
    80005790:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005792:	fd840613          	addi	a2,s0,-40
    80005796:	4581                	li	a1,0
    80005798:	4501                	li	a0,0
    8000579a:	00000097          	auipc	ra,0x0
    8000579e:	dc0080e7          	jalr	-576(ra) # 8000555a <argfd>
    return -1;
    800057a2:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    800057a4:	02054363          	bltz	a0,800057ca <sys_dup+0x44>
  if((fd=fdalloc(f)) < 0)
    800057a8:	fd843903          	ld	s2,-40(s0)
    800057ac:	854a                	mv	a0,s2
    800057ae:	00000097          	auipc	ra,0x0
    800057b2:	e0c080e7          	jalr	-500(ra) # 800055ba <fdalloc>
    800057b6:	84aa                	mv	s1,a0
    return -1;
    800057b8:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    800057ba:	00054863          	bltz	a0,800057ca <sys_dup+0x44>
  filedup(f);
    800057be:	854a                	mv	a0,s2
    800057c0:	fffff097          	auipc	ra,0xfffff
    800057c4:	310080e7          	jalr	784(ra) # 80004ad0 <filedup>
  return fd;
    800057c8:	87a6                	mv	a5,s1
}
    800057ca:	853e                	mv	a0,a5
    800057cc:	70a2                	ld	ra,40(sp)
    800057ce:	7402                	ld	s0,32(sp)
    800057d0:	64e2                	ld	s1,24(sp)
    800057d2:	6942                	ld	s2,16(sp)
    800057d4:	6145                	addi	sp,sp,48
    800057d6:	8082                	ret

00000000800057d8 <sys_read>:
{
    800057d8:	7179                	addi	sp,sp,-48
    800057da:	f406                	sd	ra,40(sp)
    800057dc:	f022                	sd	s0,32(sp)
    800057de:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    800057e0:	fd840593          	addi	a1,s0,-40
    800057e4:	4505                	li	a0,1
    800057e6:	ffffd097          	auipc	ra,0xffffd
    800057ea:	750080e7          	jalr	1872(ra) # 80002f36 <argaddr>
  argint(2, &n);
    800057ee:	fe440593          	addi	a1,s0,-28
    800057f2:	4509                	li	a0,2
    800057f4:	ffffd097          	auipc	ra,0xffffd
    800057f8:	720080e7          	jalr	1824(ra) # 80002f14 <argint>
  if(argfd(0, 0, &f) < 0)
    800057fc:	fe840613          	addi	a2,s0,-24
    80005800:	4581                	li	a1,0
    80005802:	4501                	li	a0,0
    80005804:	00000097          	auipc	ra,0x0
    80005808:	d56080e7          	jalr	-682(ra) # 8000555a <argfd>
    8000580c:	87aa                	mv	a5,a0
    return -1;
    8000580e:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005810:	0007cc63          	bltz	a5,80005828 <sys_read+0x50>
  return fileread(f, p, n);
    80005814:	fe442603          	lw	a2,-28(s0)
    80005818:	fd843583          	ld	a1,-40(s0)
    8000581c:	fe843503          	ld	a0,-24(s0)
    80005820:	fffff097          	auipc	ra,0xfffff
    80005824:	43c080e7          	jalr	1084(ra) # 80004c5c <fileread>
}
    80005828:	70a2                	ld	ra,40(sp)
    8000582a:	7402                	ld	s0,32(sp)
    8000582c:	6145                	addi	sp,sp,48
    8000582e:	8082                	ret

0000000080005830 <sys_write>:
{
    80005830:	7179                	addi	sp,sp,-48
    80005832:	f406                	sd	ra,40(sp)
    80005834:	f022                	sd	s0,32(sp)
    80005836:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    80005838:	fd840593          	addi	a1,s0,-40
    8000583c:	4505                	li	a0,1
    8000583e:	ffffd097          	auipc	ra,0xffffd
    80005842:	6f8080e7          	jalr	1784(ra) # 80002f36 <argaddr>
  argint(2, &n);
    80005846:	fe440593          	addi	a1,s0,-28
    8000584a:	4509                	li	a0,2
    8000584c:	ffffd097          	auipc	ra,0xffffd
    80005850:	6c8080e7          	jalr	1736(ra) # 80002f14 <argint>
  if(argfd(0, 0, &f) < 0)
    80005854:	fe840613          	addi	a2,s0,-24
    80005858:	4581                	li	a1,0
    8000585a:	4501                	li	a0,0
    8000585c:	00000097          	auipc	ra,0x0
    80005860:	cfe080e7          	jalr	-770(ra) # 8000555a <argfd>
    80005864:	87aa                	mv	a5,a0
    return -1;
    80005866:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005868:	0007cc63          	bltz	a5,80005880 <sys_write+0x50>
  return filewrite(f, p, n);
    8000586c:	fe442603          	lw	a2,-28(s0)
    80005870:	fd843583          	ld	a1,-40(s0)
    80005874:	fe843503          	ld	a0,-24(s0)
    80005878:	fffff097          	auipc	ra,0xfffff
    8000587c:	4a6080e7          	jalr	1190(ra) # 80004d1e <filewrite>
}
    80005880:	70a2                	ld	ra,40(sp)
    80005882:	7402                	ld	s0,32(sp)
    80005884:	6145                	addi	sp,sp,48
    80005886:	8082                	ret

0000000080005888 <sys_close>:
{
    80005888:	1101                	addi	sp,sp,-32
    8000588a:	ec06                	sd	ra,24(sp)
    8000588c:	e822                	sd	s0,16(sp)
    8000588e:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005890:	fe040613          	addi	a2,s0,-32
    80005894:	fec40593          	addi	a1,s0,-20
    80005898:	4501                	li	a0,0
    8000589a:	00000097          	auipc	ra,0x0
    8000589e:	cc0080e7          	jalr	-832(ra) # 8000555a <argfd>
    return -1;
    800058a2:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    800058a4:	02054463          	bltz	a0,800058cc <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    800058a8:	ffffc097          	auipc	ra,0xffffc
    800058ac:	104080e7          	jalr	260(ra) # 800019ac <myproc>
    800058b0:	fec42783          	lw	a5,-20(s0)
    800058b4:	07e9                	addi	a5,a5,26
    800058b6:	078e                	slli	a5,a5,0x3
    800058b8:	953e                	add	a0,a0,a5
    800058ba:	00053023          	sd	zero,0(a0)
  fileclose(f);
    800058be:	fe043503          	ld	a0,-32(s0)
    800058c2:	fffff097          	auipc	ra,0xfffff
    800058c6:	260080e7          	jalr	608(ra) # 80004b22 <fileclose>
  return 0;
    800058ca:	4781                	li	a5,0
}
    800058cc:	853e                	mv	a0,a5
    800058ce:	60e2                	ld	ra,24(sp)
    800058d0:	6442                	ld	s0,16(sp)
    800058d2:	6105                	addi	sp,sp,32
    800058d4:	8082                	ret

00000000800058d6 <sys_fstat>:
{
    800058d6:	1101                	addi	sp,sp,-32
    800058d8:	ec06                	sd	ra,24(sp)
    800058da:	e822                	sd	s0,16(sp)
    800058dc:	1000                	addi	s0,sp,32
  argaddr(1, &st);
    800058de:	fe040593          	addi	a1,s0,-32
    800058e2:	4505                	li	a0,1
    800058e4:	ffffd097          	auipc	ra,0xffffd
    800058e8:	652080e7          	jalr	1618(ra) # 80002f36 <argaddr>
  if(argfd(0, 0, &f) < 0)
    800058ec:	fe840613          	addi	a2,s0,-24
    800058f0:	4581                	li	a1,0
    800058f2:	4501                	li	a0,0
    800058f4:	00000097          	auipc	ra,0x0
    800058f8:	c66080e7          	jalr	-922(ra) # 8000555a <argfd>
    800058fc:	87aa                	mv	a5,a0
    return -1;
    800058fe:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005900:	0007ca63          	bltz	a5,80005914 <sys_fstat+0x3e>
  return filestat(f, st);
    80005904:	fe043583          	ld	a1,-32(s0)
    80005908:	fe843503          	ld	a0,-24(s0)
    8000590c:	fffff097          	auipc	ra,0xfffff
    80005910:	2de080e7          	jalr	734(ra) # 80004bea <filestat>
}
    80005914:	60e2                	ld	ra,24(sp)
    80005916:	6442                	ld	s0,16(sp)
    80005918:	6105                	addi	sp,sp,32
    8000591a:	8082                	ret

000000008000591c <sys_link>:
{
    8000591c:	7169                	addi	sp,sp,-304
    8000591e:	f606                	sd	ra,296(sp)
    80005920:	f222                	sd	s0,288(sp)
    80005922:	ee26                	sd	s1,280(sp)
    80005924:	ea4a                	sd	s2,272(sp)
    80005926:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005928:	08000613          	li	a2,128
    8000592c:	ed040593          	addi	a1,s0,-304
    80005930:	4501                	li	a0,0
    80005932:	ffffd097          	auipc	ra,0xffffd
    80005936:	626080e7          	jalr	1574(ra) # 80002f58 <argstr>
    return -1;
    8000593a:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000593c:	10054e63          	bltz	a0,80005a58 <sys_link+0x13c>
    80005940:	08000613          	li	a2,128
    80005944:	f5040593          	addi	a1,s0,-176
    80005948:	4505                	li	a0,1
    8000594a:	ffffd097          	auipc	ra,0xffffd
    8000594e:	60e080e7          	jalr	1550(ra) # 80002f58 <argstr>
    return -1;
    80005952:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005954:	10054263          	bltz	a0,80005a58 <sys_link+0x13c>
  begin_op();
    80005958:	fffff097          	auipc	ra,0xfffff
    8000595c:	d02080e7          	jalr	-766(ra) # 8000465a <begin_op>
  if((ip = namei(old)) == 0){
    80005960:	ed040513          	addi	a0,s0,-304
    80005964:	fffff097          	auipc	ra,0xfffff
    80005968:	ad6080e7          	jalr	-1322(ra) # 8000443a <namei>
    8000596c:	84aa                	mv	s1,a0
    8000596e:	c551                	beqz	a0,800059fa <sys_link+0xde>
  ilock(ip);
    80005970:	ffffe097          	auipc	ra,0xffffe
    80005974:	31e080e7          	jalr	798(ra) # 80003c8e <ilock>
  if(ip->type == T_DIR){
    80005978:	04449703          	lh	a4,68(s1)
    8000597c:	4785                	li	a5,1
    8000597e:	08f70463          	beq	a4,a5,80005a06 <sys_link+0xea>
  ip->nlink++;
    80005982:	04a4d783          	lhu	a5,74(s1)
    80005986:	2785                	addiw	a5,a5,1
    80005988:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000598c:	8526                	mv	a0,s1
    8000598e:	ffffe097          	auipc	ra,0xffffe
    80005992:	234080e7          	jalr	564(ra) # 80003bc2 <iupdate>
  iunlock(ip);
    80005996:	8526                	mv	a0,s1
    80005998:	ffffe097          	auipc	ra,0xffffe
    8000599c:	3b8080e7          	jalr	952(ra) # 80003d50 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    800059a0:	fd040593          	addi	a1,s0,-48
    800059a4:	f5040513          	addi	a0,s0,-176
    800059a8:	fffff097          	auipc	ra,0xfffff
    800059ac:	ab0080e7          	jalr	-1360(ra) # 80004458 <nameiparent>
    800059b0:	892a                	mv	s2,a0
    800059b2:	c935                	beqz	a0,80005a26 <sys_link+0x10a>
  ilock(dp);
    800059b4:	ffffe097          	auipc	ra,0xffffe
    800059b8:	2da080e7          	jalr	730(ra) # 80003c8e <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    800059bc:	00092703          	lw	a4,0(s2)
    800059c0:	409c                	lw	a5,0(s1)
    800059c2:	04f71d63          	bne	a4,a5,80005a1c <sys_link+0x100>
    800059c6:	40d0                	lw	a2,4(s1)
    800059c8:	fd040593          	addi	a1,s0,-48
    800059cc:	854a                	mv	a0,s2
    800059ce:	fffff097          	auipc	ra,0xfffff
    800059d2:	9ba080e7          	jalr	-1606(ra) # 80004388 <dirlink>
    800059d6:	04054363          	bltz	a0,80005a1c <sys_link+0x100>
  iunlockput(dp);
    800059da:	854a                	mv	a0,s2
    800059dc:	ffffe097          	auipc	ra,0xffffe
    800059e0:	514080e7          	jalr	1300(ra) # 80003ef0 <iunlockput>
  iput(ip);
    800059e4:	8526                	mv	a0,s1
    800059e6:	ffffe097          	auipc	ra,0xffffe
    800059ea:	462080e7          	jalr	1122(ra) # 80003e48 <iput>
  end_op();
    800059ee:	fffff097          	auipc	ra,0xfffff
    800059f2:	cea080e7          	jalr	-790(ra) # 800046d8 <end_op>
  return 0;
    800059f6:	4781                	li	a5,0
    800059f8:	a085                	j	80005a58 <sys_link+0x13c>
    end_op();
    800059fa:	fffff097          	auipc	ra,0xfffff
    800059fe:	cde080e7          	jalr	-802(ra) # 800046d8 <end_op>
    return -1;
    80005a02:	57fd                	li	a5,-1
    80005a04:	a891                	j	80005a58 <sys_link+0x13c>
    iunlockput(ip);
    80005a06:	8526                	mv	a0,s1
    80005a08:	ffffe097          	auipc	ra,0xffffe
    80005a0c:	4e8080e7          	jalr	1256(ra) # 80003ef0 <iunlockput>
    end_op();
    80005a10:	fffff097          	auipc	ra,0xfffff
    80005a14:	cc8080e7          	jalr	-824(ra) # 800046d8 <end_op>
    return -1;
    80005a18:	57fd                	li	a5,-1
    80005a1a:	a83d                	j	80005a58 <sys_link+0x13c>
    iunlockput(dp);
    80005a1c:	854a                	mv	a0,s2
    80005a1e:	ffffe097          	auipc	ra,0xffffe
    80005a22:	4d2080e7          	jalr	1234(ra) # 80003ef0 <iunlockput>
  ilock(ip);
    80005a26:	8526                	mv	a0,s1
    80005a28:	ffffe097          	auipc	ra,0xffffe
    80005a2c:	266080e7          	jalr	614(ra) # 80003c8e <ilock>
  ip->nlink--;
    80005a30:	04a4d783          	lhu	a5,74(s1)
    80005a34:	37fd                	addiw	a5,a5,-1
    80005a36:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005a3a:	8526                	mv	a0,s1
    80005a3c:	ffffe097          	auipc	ra,0xffffe
    80005a40:	186080e7          	jalr	390(ra) # 80003bc2 <iupdate>
  iunlockput(ip);
    80005a44:	8526                	mv	a0,s1
    80005a46:	ffffe097          	auipc	ra,0xffffe
    80005a4a:	4aa080e7          	jalr	1194(ra) # 80003ef0 <iunlockput>
  end_op();
    80005a4e:	fffff097          	auipc	ra,0xfffff
    80005a52:	c8a080e7          	jalr	-886(ra) # 800046d8 <end_op>
  return -1;
    80005a56:	57fd                	li	a5,-1
}
    80005a58:	853e                	mv	a0,a5
    80005a5a:	70b2                	ld	ra,296(sp)
    80005a5c:	7412                	ld	s0,288(sp)
    80005a5e:	64f2                	ld	s1,280(sp)
    80005a60:	6952                	ld	s2,272(sp)
    80005a62:	6155                	addi	sp,sp,304
    80005a64:	8082                	ret

0000000080005a66 <sys_unlink>:
{
    80005a66:	7151                	addi	sp,sp,-240
    80005a68:	f586                	sd	ra,232(sp)
    80005a6a:	f1a2                	sd	s0,224(sp)
    80005a6c:	eda6                	sd	s1,216(sp)
    80005a6e:	e9ca                	sd	s2,208(sp)
    80005a70:	e5ce                	sd	s3,200(sp)
    80005a72:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005a74:	08000613          	li	a2,128
    80005a78:	f3040593          	addi	a1,s0,-208
    80005a7c:	4501                	li	a0,0
    80005a7e:	ffffd097          	auipc	ra,0xffffd
    80005a82:	4da080e7          	jalr	1242(ra) # 80002f58 <argstr>
    80005a86:	18054163          	bltz	a0,80005c08 <sys_unlink+0x1a2>
  begin_op();
    80005a8a:	fffff097          	auipc	ra,0xfffff
    80005a8e:	bd0080e7          	jalr	-1072(ra) # 8000465a <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005a92:	fb040593          	addi	a1,s0,-80
    80005a96:	f3040513          	addi	a0,s0,-208
    80005a9a:	fffff097          	auipc	ra,0xfffff
    80005a9e:	9be080e7          	jalr	-1602(ra) # 80004458 <nameiparent>
    80005aa2:	84aa                	mv	s1,a0
    80005aa4:	c979                	beqz	a0,80005b7a <sys_unlink+0x114>
  ilock(dp);
    80005aa6:	ffffe097          	auipc	ra,0xffffe
    80005aaa:	1e8080e7          	jalr	488(ra) # 80003c8e <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005aae:	00003597          	auipc	a1,0x3
    80005ab2:	de258593          	addi	a1,a1,-542 # 80008890 <syscalls+0x2b0>
    80005ab6:	fb040513          	addi	a0,s0,-80
    80005aba:	ffffe097          	auipc	ra,0xffffe
    80005abe:	69e080e7          	jalr	1694(ra) # 80004158 <namecmp>
    80005ac2:	14050a63          	beqz	a0,80005c16 <sys_unlink+0x1b0>
    80005ac6:	00003597          	auipc	a1,0x3
    80005aca:	dd258593          	addi	a1,a1,-558 # 80008898 <syscalls+0x2b8>
    80005ace:	fb040513          	addi	a0,s0,-80
    80005ad2:	ffffe097          	auipc	ra,0xffffe
    80005ad6:	686080e7          	jalr	1670(ra) # 80004158 <namecmp>
    80005ada:	12050e63          	beqz	a0,80005c16 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005ade:	f2c40613          	addi	a2,s0,-212
    80005ae2:	fb040593          	addi	a1,s0,-80
    80005ae6:	8526                	mv	a0,s1
    80005ae8:	ffffe097          	auipc	ra,0xffffe
    80005aec:	68a080e7          	jalr	1674(ra) # 80004172 <dirlookup>
    80005af0:	892a                	mv	s2,a0
    80005af2:	12050263          	beqz	a0,80005c16 <sys_unlink+0x1b0>
  ilock(ip);
    80005af6:	ffffe097          	auipc	ra,0xffffe
    80005afa:	198080e7          	jalr	408(ra) # 80003c8e <ilock>
  if(ip->nlink < 1)
    80005afe:	04a91783          	lh	a5,74(s2)
    80005b02:	08f05263          	blez	a5,80005b86 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005b06:	04491703          	lh	a4,68(s2)
    80005b0a:	4785                	li	a5,1
    80005b0c:	08f70563          	beq	a4,a5,80005b96 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005b10:	4641                	li	a2,16
    80005b12:	4581                	li	a1,0
    80005b14:	fc040513          	addi	a0,s0,-64
    80005b18:	ffffb097          	auipc	ra,0xffffb
    80005b1c:	1ba080e7          	jalr	442(ra) # 80000cd2 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005b20:	4741                	li	a4,16
    80005b22:	f2c42683          	lw	a3,-212(s0)
    80005b26:	fc040613          	addi	a2,s0,-64
    80005b2a:	4581                	li	a1,0
    80005b2c:	8526                	mv	a0,s1
    80005b2e:	ffffe097          	auipc	ra,0xffffe
    80005b32:	50c080e7          	jalr	1292(ra) # 8000403a <writei>
    80005b36:	47c1                	li	a5,16
    80005b38:	0af51563          	bne	a0,a5,80005be2 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005b3c:	04491703          	lh	a4,68(s2)
    80005b40:	4785                	li	a5,1
    80005b42:	0af70863          	beq	a4,a5,80005bf2 <sys_unlink+0x18c>
  iunlockput(dp);
    80005b46:	8526                	mv	a0,s1
    80005b48:	ffffe097          	auipc	ra,0xffffe
    80005b4c:	3a8080e7          	jalr	936(ra) # 80003ef0 <iunlockput>
  ip->nlink--;
    80005b50:	04a95783          	lhu	a5,74(s2)
    80005b54:	37fd                	addiw	a5,a5,-1
    80005b56:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005b5a:	854a                	mv	a0,s2
    80005b5c:	ffffe097          	auipc	ra,0xffffe
    80005b60:	066080e7          	jalr	102(ra) # 80003bc2 <iupdate>
  iunlockput(ip);
    80005b64:	854a                	mv	a0,s2
    80005b66:	ffffe097          	auipc	ra,0xffffe
    80005b6a:	38a080e7          	jalr	906(ra) # 80003ef0 <iunlockput>
  end_op();
    80005b6e:	fffff097          	auipc	ra,0xfffff
    80005b72:	b6a080e7          	jalr	-1174(ra) # 800046d8 <end_op>
  return 0;
    80005b76:	4501                	li	a0,0
    80005b78:	a84d                	j	80005c2a <sys_unlink+0x1c4>
    end_op();
    80005b7a:	fffff097          	auipc	ra,0xfffff
    80005b7e:	b5e080e7          	jalr	-1186(ra) # 800046d8 <end_op>
    return -1;
    80005b82:	557d                	li	a0,-1
    80005b84:	a05d                	j	80005c2a <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005b86:	00003517          	auipc	a0,0x3
    80005b8a:	d1a50513          	addi	a0,a0,-742 # 800088a0 <syscalls+0x2c0>
    80005b8e:	ffffb097          	auipc	ra,0xffffb
    80005b92:	9b2080e7          	jalr	-1614(ra) # 80000540 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005b96:	04c92703          	lw	a4,76(s2)
    80005b9a:	02000793          	li	a5,32
    80005b9e:	f6e7f9e3          	bgeu	a5,a4,80005b10 <sys_unlink+0xaa>
    80005ba2:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005ba6:	4741                	li	a4,16
    80005ba8:	86ce                	mv	a3,s3
    80005baa:	f1840613          	addi	a2,s0,-232
    80005bae:	4581                	li	a1,0
    80005bb0:	854a                	mv	a0,s2
    80005bb2:	ffffe097          	auipc	ra,0xffffe
    80005bb6:	390080e7          	jalr	912(ra) # 80003f42 <readi>
    80005bba:	47c1                	li	a5,16
    80005bbc:	00f51b63          	bne	a0,a5,80005bd2 <sys_unlink+0x16c>
    if(de.inum != 0)
    80005bc0:	f1845783          	lhu	a5,-232(s0)
    80005bc4:	e7a1                	bnez	a5,80005c0c <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005bc6:	29c1                	addiw	s3,s3,16
    80005bc8:	04c92783          	lw	a5,76(s2)
    80005bcc:	fcf9ede3          	bltu	s3,a5,80005ba6 <sys_unlink+0x140>
    80005bd0:	b781                	j	80005b10 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005bd2:	00003517          	auipc	a0,0x3
    80005bd6:	ce650513          	addi	a0,a0,-794 # 800088b8 <syscalls+0x2d8>
    80005bda:	ffffb097          	auipc	ra,0xffffb
    80005bde:	966080e7          	jalr	-1690(ra) # 80000540 <panic>
    panic("unlink: writei");
    80005be2:	00003517          	auipc	a0,0x3
    80005be6:	cee50513          	addi	a0,a0,-786 # 800088d0 <syscalls+0x2f0>
    80005bea:	ffffb097          	auipc	ra,0xffffb
    80005bee:	956080e7          	jalr	-1706(ra) # 80000540 <panic>
    dp->nlink--;
    80005bf2:	04a4d783          	lhu	a5,74(s1)
    80005bf6:	37fd                	addiw	a5,a5,-1
    80005bf8:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005bfc:	8526                	mv	a0,s1
    80005bfe:	ffffe097          	auipc	ra,0xffffe
    80005c02:	fc4080e7          	jalr	-60(ra) # 80003bc2 <iupdate>
    80005c06:	b781                	j	80005b46 <sys_unlink+0xe0>
    return -1;
    80005c08:	557d                	li	a0,-1
    80005c0a:	a005                	j	80005c2a <sys_unlink+0x1c4>
    iunlockput(ip);
    80005c0c:	854a                	mv	a0,s2
    80005c0e:	ffffe097          	auipc	ra,0xffffe
    80005c12:	2e2080e7          	jalr	738(ra) # 80003ef0 <iunlockput>
  iunlockput(dp);
    80005c16:	8526                	mv	a0,s1
    80005c18:	ffffe097          	auipc	ra,0xffffe
    80005c1c:	2d8080e7          	jalr	728(ra) # 80003ef0 <iunlockput>
  end_op();
    80005c20:	fffff097          	auipc	ra,0xfffff
    80005c24:	ab8080e7          	jalr	-1352(ra) # 800046d8 <end_op>
  return -1;
    80005c28:	557d                	li	a0,-1
}
    80005c2a:	70ae                	ld	ra,232(sp)
    80005c2c:	740e                	ld	s0,224(sp)
    80005c2e:	64ee                	ld	s1,216(sp)
    80005c30:	694e                	ld	s2,208(sp)
    80005c32:	69ae                	ld	s3,200(sp)
    80005c34:	616d                	addi	sp,sp,240
    80005c36:	8082                	ret

0000000080005c38 <sys_open>:

uint64
sys_open(void)
{
    80005c38:	7131                	addi	sp,sp,-192
    80005c3a:	fd06                	sd	ra,184(sp)
    80005c3c:	f922                	sd	s0,176(sp)
    80005c3e:	f526                	sd	s1,168(sp)
    80005c40:	f14a                	sd	s2,160(sp)
    80005c42:	ed4e                	sd	s3,152(sp)
    80005c44:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    80005c46:	f4c40593          	addi	a1,s0,-180
    80005c4a:	4505                	li	a0,1
    80005c4c:	ffffd097          	auipc	ra,0xffffd
    80005c50:	2c8080e7          	jalr	712(ra) # 80002f14 <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005c54:	08000613          	li	a2,128
    80005c58:	f5040593          	addi	a1,s0,-176
    80005c5c:	4501                	li	a0,0
    80005c5e:	ffffd097          	auipc	ra,0xffffd
    80005c62:	2fa080e7          	jalr	762(ra) # 80002f58 <argstr>
    80005c66:	87aa                	mv	a5,a0
    return -1;
    80005c68:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005c6a:	0a07c963          	bltz	a5,80005d1c <sys_open+0xe4>

  begin_op();
    80005c6e:	fffff097          	auipc	ra,0xfffff
    80005c72:	9ec080e7          	jalr	-1556(ra) # 8000465a <begin_op>

  if(omode & O_CREATE){
    80005c76:	f4c42783          	lw	a5,-180(s0)
    80005c7a:	2007f793          	andi	a5,a5,512
    80005c7e:	cfc5                	beqz	a5,80005d36 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005c80:	4681                	li	a3,0
    80005c82:	4601                	li	a2,0
    80005c84:	4589                	li	a1,2
    80005c86:	f5040513          	addi	a0,s0,-176
    80005c8a:	00000097          	auipc	ra,0x0
    80005c8e:	972080e7          	jalr	-1678(ra) # 800055fc <create>
    80005c92:	84aa                	mv	s1,a0
    if(ip == 0){
    80005c94:	c959                	beqz	a0,80005d2a <sys_open+0xf2>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005c96:	04449703          	lh	a4,68(s1)
    80005c9a:	478d                	li	a5,3
    80005c9c:	00f71763          	bne	a4,a5,80005caa <sys_open+0x72>
    80005ca0:	0464d703          	lhu	a4,70(s1)
    80005ca4:	47a5                	li	a5,9
    80005ca6:	0ce7ed63          	bltu	a5,a4,80005d80 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005caa:	fffff097          	auipc	ra,0xfffff
    80005cae:	dbc080e7          	jalr	-580(ra) # 80004a66 <filealloc>
    80005cb2:	89aa                	mv	s3,a0
    80005cb4:	10050363          	beqz	a0,80005dba <sys_open+0x182>
    80005cb8:	00000097          	auipc	ra,0x0
    80005cbc:	902080e7          	jalr	-1790(ra) # 800055ba <fdalloc>
    80005cc0:	892a                	mv	s2,a0
    80005cc2:	0e054763          	bltz	a0,80005db0 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005cc6:	04449703          	lh	a4,68(s1)
    80005cca:	478d                	li	a5,3
    80005ccc:	0cf70563          	beq	a4,a5,80005d96 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005cd0:	4789                	li	a5,2
    80005cd2:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005cd6:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005cda:	0099bc23          	sd	s1,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005cde:	f4c42783          	lw	a5,-180(s0)
    80005ce2:	0017c713          	xori	a4,a5,1
    80005ce6:	8b05                	andi	a4,a4,1
    80005ce8:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005cec:	0037f713          	andi	a4,a5,3
    80005cf0:	00e03733          	snez	a4,a4
    80005cf4:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005cf8:	4007f793          	andi	a5,a5,1024
    80005cfc:	c791                	beqz	a5,80005d08 <sys_open+0xd0>
    80005cfe:	04449703          	lh	a4,68(s1)
    80005d02:	4789                	li	a5,2
    80005d04:	0af70063          	beq	a4,a5,80005da4 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005d08:	8526                	mv	a0,s1
    80005d0a:	ffffe097          	auipc	ra,0xffffe
    80005d0e:	046080e7          	jalr	70(ra) # 80003d50 <iunlock>
  end_op();
    80005d12:	fffff097          	auipc	ra,0xfffff
    80005d16:	9c6080e7          	jalr	-1594(ra) # 800046d8 <end_op>

  return fd;
    80005d1a:	854a                	mv	a0,s2
}
    80005d1c:	70ea                	ld	ra,184(sp)
    80005d1e:	744a                	ld	s0,176(sp)
    80005d20:	74aa                	ld	s1,168(sp)
    80005d22:	790a                	ld	s2,160(sp)
    80005d24:	69ea                	ld	s3,152(sp)
    80005d26:	6129                	addi	sp,sp,192
    80005d28:	8082                	ret
      end_op();
    80005d2a:	fffff097          	auipc	ra,0xfffff
    80005d2e:	9ae080e7          	jalr	-1618(ra) # 800046d8 <end_op>
      return -1;
    80005d32:	557d                	li	a0,-1
    80005d34:	b7e5                	j	80005d1c <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005d36:	f5040513          	addi	a0,s0,-176
    80005d3a:	ffffe097          	auipc	ra,0xffffe
    80005d3e:	700080e7          	jalr	1792(ra) # 8000443a <namei>
    80005d42:	84aa                	mv	s1,a0
    80005d44:	c905                	beqz	a0,80005d74 <sys_open+0x13c>
    ilock(ip);
    80005d46:	ffffe097          	auipc	ra,0xffffe
    80005d4a:	f48080e7          	jalr	-184(ra) # 80003c8e <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005d4e:	04449703          	lh	a4,68(s1)
    80005d52:	4785                	li	a5,1
    80005d54:	f4f711e3          	bne	a4,a5,80005c96 <sys_open+0x5e>
    80005d58:	f4c42783          	lw	a5,-180(s0)
    80005d5c:	d7b9                	beqz	a5,80005caa <sys_open+0x72>
      iunlockput(ip);
    80005d5e:	8526                	mv	a0,s1
    80005d60:	ffffe097          	auipc	ra,0xffffe
    80005d64:	190080e7          	jalr	400(ra) # 80003ef0 <iunlockput>
      end_op();
    80005d68:	fffff097          	auipc	ra,0xfffff
    80005d6c:	970080e7          	jalr	-1680(ra) # 800046d8 <end_op>
      return -1;
    80005d70:	557d                	li	a0,-1
    80005d72:	b76d                	j	80005d1c <sys_open+0xe4>
      end_op();
    80005d74:	fffff097          	auipc	ra,0xfffff
    80005d78:	964080e7          	jalr	-1692(ra) # 800046d8 <end_op>
      return -1;
    80005d7c:	557d                	li	a0,-1
    80005d7e:	bf79                	j	80005d1c <sys_open+0xe4>
    iunlockput(ip);
    80005d80:	8526                	mv	a0,s1
    80005d82:	ffffe097          	auipc	ra,0xffffe
    80005d86:	16e080e7          	jalr	366(ra) # 80003ef0 <iunlockput>
    end_op();
    80005d8a:	fffff097          	auipc	ra,0xfffff
    80005d8e:	94e080e7          	jalr	-1714(ra) # 800046d8 <end_op>
    return -1;
    80005d92:	557d                	li	a0,-1
    80005d94:	b761                	j	80005d1c <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005d96:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005d9a:	04649783          	lh	a5,70(s1)
    80005d9e:	02f99223          	sh	a5,36(s3)
    80005da2:	bf25                	j	80005cda <sys_open+0xa2>
    itrunc(ip);
    80005da4:	8526                	mv	a0,s1
    80005da6:	ffffe097          	auipc	ra,0xffffe
    80005daa:	ff6080e7          	jalr	-10(ra) # 80003d9c <itrunc>
    80005dae:	bfa9                	j	80005d08 <sys_open+0xd0>
      fileclose(f);
    80005db0:	854e                	mv	a0,s3
    80005db2:	fffff097          	auipc	ra,0xfffff
    80005db6:	d70080e7          	jalr	-656(ra) # 80004b22 <fileclose>
    iunlockput(ip);
    80005dba:	8526                	mv	a0,s1
    80005dbc:	ffffe097          	auipc	ra,0xffffe
    80005dc0:	134080e7          	jalr	308(ra) # 80003ef0 <iunlockput>
    end_op();
    80005dc4:	fffff097          	auipc	ra,0xfffff
    80005dc8:	914080e7          	jalr	-1772(ra) # 800046d8 <end_op>
    return -1;
    80005dcc:	557d                	li	a0,-1
    80005dce:	b7b9                	j	80005d1c <sys_open+0xe4>

0000000080005dd0 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005dd0:	7175                	addi	sp,sp,-144
    80005dd2:	e506                	sd	ra,136(sp)
    80005dd4:	e122                	sd	s0,128(sp)
    80005dd6:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005dd8:	fffff097          	auipc	ra,0xfffff
    80005ddc:	882080e7          	jalr	-1918(ra) # 8000465a <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005de0:	08000613          	li	a2,128
    80005de4:	f7040593          	addi	a1,s0,-144
    80005de8:	4501                	li	a0,0
    80005dea:	ffffd097          	auipc	ra,0xffffd
    80005dee:	16e080e7          	jalr	366(ra) # 80002f58 <argstr>
    80005df2:	02054963          	bltz	a0,80005e24 <sys_mkdir+0x54>
    80005df6:	4681                	li	a3,0
    80005df8:	4601                	li	a2,0
    80005dfa:	4585                	li	a1,1
    80005dfc:	f7040513          	addi	a0,s0,-144
    80005e00:	fffff097          	auipc	ra,0xfffff
    80005e04:	7fc080e7          	jalr	2044(ra) # 800055fc <create>
    80005e08:	cd11                	beqz	a0,80005e24 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005e0a:	ffffe097          	auipc	ra,0xffffe
    80005e0e:	0e6080e7          	jalr	230(ra) # 80003ef0 <iunlockput>
  end_op();
    80005e12:	fffff097          	auipc	ra,0xfffff
    80005e16:	8c6080e7          	jalr	-1850(ra) # 800046d8 <end_op>
  return 0;
    80005e1a:	4501                	li	a0,0
}
    80005e1c:	60aa                	ld	ra,136(sp)
    80005e1e:	640a                	ld	s0,128(sp)
    80005e20:	6149                	addi	sp,sp,144
    80005e22:	8082                	ret
    end_op();
    80005e24:	fffff097          	auipc	ra,0xfffff
    80005e28:	8b4080e7          	jalr	-1868(ra) # 800046d8 <end_op>
    return -1;
    80005e2c:	557d                	li	a0,-1
    80005e2e:	b7fd                	j	80005e1c <sys_mkdir+0x4c>

0000000080005e30 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005e30:	7135                	addi	sp,sp,-160
    80005e32:	ed06                	sd	ra,152(sp)
    80005e34:	e922                	sd	s0,144(sp)
    80005e36:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005e38:	fffff097          	auipc	ra,0xfffff
    80005e3c:	822080e7          	jalr	-2014(ra) # 8000465a <begin_op>
  argint(1, &major);
    80005e40:	f6c40593          	addi	a1,s0,-148
    80005e44:	4505                	li	a0,1
    80005e46:	ffffd097          	auipc	ra,0xffffd
    80005e4a:	0ce080e7          	jalr	206(ra) # 80002f14 <argint>
  argint(2, &minor);
    80005e4e:	f6840593          	addi	a1,s0,-152
    80005e52:	4509                	li	a0,2
    80005e54:	ffffd097          	auipc	ra,0xffffd
    80005e58:	0c0080e7          	jalr	192(ra) # 80002f14 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005e5c:	08000613          	li	a2,128
    80005e60:	f7040593          	addi	a1,s0,-144
    80005e64:	4501                	li	a0,0
    80005e66:	ffffd097          	auipc	ra,0xffffd
    80005e6a:	0f2080e7          	jalr	242(ra) # 80002f58 <argstr>
    80005e6e:	02054b63          	bltz	a0,80005ea4 <sys_mknod+0x74>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005e72:	f6841683          	lh	a3,-152(s0)
    80005e76:	f6c41603          	lh	a2,-148(s0)
    80005e7a:	458d                	li	a1,3
    80005e7c:	f7040513          	addi	a0,s0,-144
    80005e80:	fffff097          	auipc	ra,0xfffff
    80005e84:	77c080e7          	jalr	1916(ra) # 800055fc <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005e88:	cd11                	beqz	a0,80005ea4 <sys_mknod+0x74>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005e8a:	ffffe097          	auipc	ra,0xffffe
    80005e8e:	066080e7          	jalr	102(ra) # 80003ef0 <iunlockput>
  end_op();
    80005e92:	fffff097          	auipc	ra,0xfffff
    80005e96:	846080e7          	jalr	-1978(ra) # 800046d8 <end_op>
  return 0;
    80005e9a:	4501                	li	a0,0
}
    80005e9c:	60ea                	ld	ra,152(sp)
    80005e9e:	644a                	ld	s0,144(sp)
    80005ea0:	610d                	addi	sp,sp,160
    80005ea2:	8082                	ret
    end_op();
    80005ea4:	fffff097          	auipc	ra,0xfffff
    80005ea8:	834080e7          	jalr	-1996(ra) # 800046d8 <end_op>
    return -1;
    80005eac:	557d                	li	a0,-1
    80005eae:	b7fd                	j	80005e9c <sys_mknod+0x6c>

0000000080005eb0 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005eb0:	7135                	addi	sp,sp,-160
    80005eb2:	ed06                	sd	ra,152(sp)
    80005eb4:	e922                	sd	s0,144(sp)
    80005eb6:	e526                	sd	s1,136(sp)
    80005eb8:	e14a                	sd	s2,128(sp)
    80005eba:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005ebc:	ffffc097          	auipc	ra,0xffffc
    80005ec0:	af0080e7          	jalr	-1296(ra) # 800019ac <myproc>
    80005ec4:	892a                	mv	s2,a0
  
  begin_op();
    80005ec6:	ffffe097          	auipc	ra,0xffffe
    80005eca:	794080e7          	jalr	1940(ra) # 8000465a <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005ece:	08000613          	li	a2,128
    80005ed2:	f6040593          	addi	a1,s0,-160
    80005ed6:	4501                	li	a0,0
    80005ed8:	ffffd097          	auipc	ra,0xffffd
    80005edc:	080080e7          	jalr	128(ra) # 80002f58 <argstr>
    80005ee0:	04054b63          	bltz	a0,80005f36 <sys_chdir+0x86>
    80005ee4:	f6040513          	addi	a0,s0,-160
    80005ee8:	ffffe097          	auipc	ra,0xffffe
    80005eec:	552080e7          	jalr	1362(ra) # 8000443a <namei>
    80005ef0:	84aa                	mv	s1,a0
    80005ef2:	c131                	beqz	a0,80005f36 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005ef4:	ffffe097          	auipc	ra,0xffffe
    80005ef8:	d9a080e7          	jalr	-614(ra) # 80003c8e <ilock>
  if(ip->type != T_DIR){
    80005efc:	04449703          	lh	a4,68(s1)
    80005f00:	4785                	li	a5,1
    80005f02:	04f71063          	bne	a4,a5,80005f42 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005f06:	8526                	mv	a0,s1
    80005f08:	ffffe097          	auipc	ra,0xffffe
    80005f0c:	e48080e7          	jalr	-440(ra) # 80003d50 <iunlock>
  iput(p->cwd);
    80005f10:	15093503          	ld	a0,336(s2)
    80005f14:	ffffe097          	auipc	ra,0xffffe
    80005f18:	f34080e7          	jalr	-204(ra) # 80003e48 <iput>
  end_op();
    80005f1c:	ffffe097          	auipc	ra,0xffffe
    80005f20:	7bc080e7          	jalr	1980(ra) # 800046d8 <end_op>
  p->cwd = ip;
    80005f24:	14993823          	sd	s1,336(s2)
  return 0;
    80005f28:	4501                	li	a0,0
}
    80005f2a:	60ea                	ld	ra,152(sp)
    80005f2c:	644a                	ld	s0,144(sp)
    80005f2e:	64aa                	ld	s1,136(sp)
    80005f30:	690a                	ld	s2,128(sp)
    80005f32:	610d                	addi	sp,sp,160
    80005f34:	8082                	ret
    end_op();
    80005f36:	ffffe097          	auipc	ra,0xffffe
    80005f3a:	7a2080e7          	jalr	1954(ra) # 800046d8 <end_op>
    return -1;
    80005f3e:	557d                	li	a0,-1
    80005f40:	b7ed                	j	80005f2a <sys_chdir+0x7a>
    iunlockput(ip);
    80005f42:	8526                	mv	a0,s1
    80005f44:	ffffe097          	auipc	ra,0xffffe
    80005f48:	fac080e7          	jalr	-84(ra) # 80003ef0 <iunlockput>
    end_op();
    80005f4c:	ffffe097          	auipc	ra,0xffffe
    80005f50:	78c080e7          	jalr	1932(ra) # 800046d8 <end_op>
    return -1;
    80005f54:	557d                	li	a0,-1
    80005f56:	bfd1                	j	80005f2a <sys_chdir+0x7a>

0000000080005f58 <sys_exec>:

uint64
sys_exec(void)
{
    80005f58:	7145                	addi	sp,sp,-464
    80005f5a:	e786                	sd	ra,456(sp)
    80005f5c:	e3a2                	sd	s0,448(sp)
    80005f5e:	ff26                	sd	s1,440(sp)
    80005f60:	fb4a                	sd	s2,432(sp)
    80005f62:	f74e                	sd	s3,424(sp)
    80005f64:	f352                	sd	s4,416(sp)
    80005f66:	ef56                	sd	s5,408(sp)
    80005f68:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    80005f6a:	e3840593          	addi	a1,s0,-456
    80005f6e:	4505                	li	a0,1
    80005f70:	ffffd097          	auipc	ra,0xffffd
    80005f74:	fc6080e7          	jalr	-58(ra) # 80002f36 <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    80005f78:	08000613          	li	a2,128
    80005f7c:	f4040593          	addi	a1,s0,-192
    80005f80:	4501                	li	a0,0
    80005f82:	ffffd097          	auipc	ra,0xffffd
    80005f86:	fd6080e7          	jalr	-42(ra) # 80002f58 <argstr>
    80005f8a:	87aa                	mv	a5,a0
    return -1;
    80005f8c:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    80005f8e:	0c07c363          	bltz	a5,80006054 <sys_exec+0xfc>
  }
  memset(argv, 0, sizeof(argv));
    80005f92:	10000613          	li	a2,256
    80005f96:	4581                	li	a1,0
    80005f98:	e4040513          	addi	a0,s0,-448
    80005f9c:	ffffb097          	auipc	ra,0xffffb
    80005fa0:	d36080e7          	jalr	-714(ra) # 80000cd2 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005fa4:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005fa8:	89a6                	mv	s3,s1
    80005faa:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005fac:	02000a13          	li	s4,32
    80005fb0:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005fb4:	00391513          	slli	a0,s2,0x3
    80005fb8:	e3040593          	addi	a1,s0,-464
    80005fbc:	e3843783          	ld	a5,-456(s0)
    80005fc0:	953e                	add	a0,a0,a5
    80005fc2:	ffffd097          	auipc	ra,0xffffd
    80005fc6:	eb8080e7          	jalr	-328(ra) # 80002e7a <fetchaddr>
    80005fca:	02054a63          	bltz	a0,80005ffe <sys_exec+0xa6>
      goto bad;
    }
    if(uarg == 0){
    80005fce:	e3043783          	ld	a5,-464(s0)
    80005fd2:	c3b9                	beqz	a5,80006018 <sys_exec+0xc0>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005fd4:	ffffb097          	auipc	ra,0xffffb
    80005fd8:	b12080e7          	jalr	-1262(ra) # 80000ae6 <kalloc>
    80005fdc:	85aa                	mv	a1,a0
    80005fde:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005fe2:	cd11                	beqz	a0,80005ffe <sys_exec+0xa6>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005fe4:	6605                	lui	a2,0x1
    80005fe6:	e3043503          	ld	a0,-464(s0)
    80005fea:	ffffd097          	auipc	ra,0xffffd
    80005fee:	ee2080e7          	jalr	-286(ra) # 80002ecc <fetchstr>
    80005ff2:	00054663          	bltz	a0,80005ffe <sys_exec+0xa6>
    if(i >= NELEM(argv)){
    80005ff6:	0905                	addi	s2,s2,1
    80005ff8:	09a1                	addi	s3,s3,8
    80005ffa:	fb491be3          	bne	s2,s4,80005fb0 <sys_exec+0x58>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005ffe:	f4040913          	addi	s2,s0,-192
    80006002:	6088                	ld	a0,0(s1)
    80006004:	c539                	beqz	a0,80006052 <sys_exec+0xfa>
    kfree(argv[i]);
    80006006:	ffffb097          	auipc	ra,0xffffb
    8000600a:	9e2080e7          	jalr	-1566(ra) # 800009e8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000600e:	04a1                	addi	s1,s1,8
    80006010:	ff2499e3          	bne	s1,s2,80006002 <sys_exec+0xaa>
  return -1;
    80006014:	557d                	li	a0,-1
    80006016:	a83d                	j	80006054 <sys_exec+0xfc>
      argv[i] = 0;
    80006018:	0a8e                	slli	s5,s5,0x3
    8000601a:	fc0a8793          	addi	a5,s5,-64
    8000601e:	00878ab3          	add	s5,a5,s0
    80006022:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80006026:	e4040593          	addi	a1,s0,-448
    8000602a:	f4040513          	addi	a0,s0,-192
    8000602e:	fffff097          	auipc	ra,0xfffff
    80006032:	16e080e7          	jalr	366(ra) # 8000519c <exec>
    80006036:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006038:	f4040993          	addi	s3,s0,-192
    8000603c:	6088                	ld	a0,0(s1)
    8000603e:	c901                	beqz	a0,8000604e <sys_exec+0xf6>
    kfree(argv[i]);
    80006040:	ffffb097          	auipc	ra,0xffffb
    80006044:	9a8080e7          	jalr	-1624(ra) # 800009e8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006048:	04a1                	addi	s1,s1,8
    8000604a:	ff3499e3          	bne	s1,s3,8000603c <sys_exec+0xe4>
  return ret;
    8000604e:	854a                	mv	a0,s2
    80006050:	a011                	j	80006054 <sys_exec+0xfc>
  return -1;
    80006052:	557d                	li	a0,-1
}
    80006054:	60be                	ld	ra,456(sp)
    80006056:	641e                	ld	s0,448(sp)
    80006058:	74fa                	ld	s1,440(sp)
    8000605a:	795a                	ld	s2,432(sp)
    8000605c:	79ba                	ld	s3,424(sp)
    8000605e:	7a1a                	ld	s4,416(sp)
    80006060:	6afa                	ld	s5,408(sp)
    80006062:	6179                	addi	sp,sp,464
    80006064:	8082                	ret

0000000080006066 <sys_pipe>:

uint64
sys_pipe(void)
{
    80006066:	7139                	addi	sp,sp,-64
    80006068:	fc06                	sd	ra,56(sp)
    8000606a:	f822                	sd	s0,48(sp)
    8000606c:	f426                	sd	s1,40(sp)
    8000606e:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80006070:	ffffc097          	auipc	ra,0xffffc
    80006074:	93c080e7          	jalr	-1732(ra) # 800019ac <myproc>
    80006078:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    8000607a:	fd840593          	addi	a1,s0,-40
    8000607e:	4501                	li	a0,0
    80006080:	ffffd097          	auipc	ra,0xffffd
    80006084:	eb6080e7          	jalr	-330(ra) # 80002f36 <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    80006088:	fc840593          	addi	a1,s0,-56
    8000608c:	fd040513          	addi	a0,s0,-48
    80006090:	fffff097          	auipc	ra,0xfffff
    80006094:	dc2080e7          	jalr	-574(ra) # 80004e52 <pipealloc>
    return -1;
    80006098:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    8000609a:	0c054463          	bltz	a0,80006162 <sys_pipe+0xfc>
  fd0 = -1;
    8000609e:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    800060a2:	fd043503          	ld	a0,-48(s0)
    800060a6:	fffff097          	auipc	ra,0xfffff
    800060aa:	514080e7          	jalr	1300(ra) # 800055ba <fdalloc>
    800060ae:	fca42223          	sw	a0,-60(s0)
    800060b2:	08054b63          	bltz	a0,80006148 <sys_pipe+0xe2>
    800060b6:	fc843503          	ld	a0,-56(s0)
    800060ba:	fffff097          	auipc	ra,0xfffff
    800060be:	500080e7          	jalr	1280(ra) # 800055ba <fdalloc>
    800060c2:	fca42023          	sw	a0,-64(s0)
    800060c6:	06054863          	bltz	a0,80006136 <sys_pipe+0xd0>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    800060ca:	4691                	li	a3,4
    800060cc:	fc440613          	addi	a2,s0,-60
    800060d0:	fd843583          	ld	a1,-40(s0)
    800060d4:	68a8                	ld	a0,80(s1)
    800060d6:	ffffb097          	auipc	ra,0xffffb
    800060da:	596080e7          	jalr	1430(ra) # 8000166c <copyout>
    800060de:	02054063          	bltz	a0,800060fe <sys_pipe+0x98>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    800060e2:	4691                	li	a3,4
    800060e4:	fc040613          	addi	a2,s0,-64
    800060e8:	fd843583          	ld	a1,-40(s0)
    800060ec:	0591                	addi	a1,a1,4
    800060ee:	68a8                	ld	a0,80(s1)
    800060f0:	ffffb097          	auipc	ra,0xffffb
    800060f4:	57c080e7          	jalr	1404(ra) # 8000166c <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    800060f8:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    800060fa:	06055463          	bgez	a0,80006162 <sys_pipe+0xfc>
    p->ofile[fd0] = 0;
    800060fe:	fc442783          	lw	a5,-60(s0)
    80006102:	07e9                	addi	a5,a5,26
    80006104:	078e                	slli	a5,a5,0x3
    80006106:	97a6                	add	a5,a5,s1
    80006108:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    8000610c:	fc042783          	lw	a5,-64(s0)
    80006110:	07e9                	addi	a5,a5,26
    80006112:	078e                	slli	a5,a5,0x3
    80006114:	94be                	add	s1,s1,a5
    80006116:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    8000611a:	fd043503          	ld	a0,-48(s0)
    8000611e:	fffff097          	auipc	ra,0xfffff
    80006122:	a04080e7          	jalr	-1532(ra) # 80004b22 <fileclose>
    fileclose(wf);
    80006126:	fc843503          	ld	a0,-56(s0)
    8000612a:	fffff097          	auipc	ra,0xfffff
    8000612e:	9f8080e7          	jalr	-1544(ra) # 80004b22 <fileclose>
    return -1;
    80006132:	57fd                	li	a5,-1
    80006134:	a03d                	j	80006162 <sys_pipe+0xfc>
    if(fd0 >= 0)
    80006136:	fc442783          	lw	a5,-60(s0)
    8000613a:	0007c763          	bltz	a5,80006148 <sys_pipe+0xe2>
      p->ofile[fd0] = 0;
    8000613e:	07e9                	addi	a5,a5,26
    80006140:	078e                	slli	a5,a5,0x3
    80006142:	97a6                	add	a5,a5,s1
    80006144:	0007b023          	sd	zero,0(a5)
    fileclose(rf);
    80006148:	fd043503          	ld	a0,-48(s0)
    8000614c:	fffff097          	auipc	ra,0xfffff
    80006150:	9d6080e7          	jalr	-1578(ra) # 80004b22 <fileclose>
    fileclose(wf);
    80006154:	fc843503          	ld	a0,-56(s0)
    80006158:	fffff097          	auipc	ra,0xfffff
    8000615c:	9ca080e7          	jalr	-1590(ra) # 80004b22 <fileclose>
    return -1;
    80006160:	57fd                	li	a5,-1
}
    80006162:	853e                	mv	a0,a5
    80006164:	70e2                	ld	ra,56(sp)
    80006166:	7442                	ld	s0,48(sp)
    80006168:	74a2                	ld	s1,40(sp)
    8000616a:	6121                	addi	sp,sp,64
    8000616c:	8082                	ret
	...

0000000080006170 <kernelvec>:
    80006170:	7111                	addi	sp,sp,-256
    80006172:	e006                	sd	ra,0(sp)
    80006174:	e40a                	sd	sp,8(sp)
    80006176:	e80e                	sd	gp,16(sp)
    80006178:	ec12                	sd	tp,24(sp)
    8000617a:	f016                	sd	t0,32(sp)
    8000617c:	f41a                	sd	t1,40(sp)
    8000617e:	f81e                	sd	t2,48(sp)
    80006180:	fc22                	sd	s0,56(sp)
    80006182:	e0a6                	sd	s1,64(sp)
    80006184:	e4aa                	sd	a0,72(sp)
    80006186:	e8ae                	sd	a1,80(sp)
    80006188:	ecb2                	sd	a2,88(sp)
    8000618a:	f0b6                	sd	a3,96(sp)
    8000618c:	f4ba                	sd	a4,104(sp)
    8000618e:	f8be                	sd	a5,112(sp)
    80006190:	fcc2                	sd	a6,120(sp)
    80006192:	e146                	sd	a7,128(sp)
    80006194:	e54a                	sd	s2,136(sp)
    80006196:	e94e                	sd	s3,144(sp)
    80006198:	ed52                	sd	s4,152(sp)
    8000619a:	f156                	sd	s5,160(sp)
    8000619c:	f55a                	sd	s6,168(sp)
    8000619e:	f95e                	sd	s7,176(sp)
    800061a0:	fd62                	sd	s8,184(sp)
    800061a2:	e1e6                	sd	s9,192(sp)
    800061a4:	e5ea                	sd	s10,200(sp)
    800061a6:	e9ee                	sd	s11,208(sp)
    800061a8:	edf2                	sd	t3,216(sp)
    800061aa:	f1f6                	sd	t4,224(sp)
    800061ac:	f5fa                	sd	t5,232(sp)
    800061ae:	f9fe                	sd	t6,240(sp)
    800061b0:	b49fc0ef          	jal	ra,80002cf8 <kerneltrap>
    800061b4:	6082                	ld	ra,0(sp)
    800061b6:	6122                	ld	sp,8(sp)
    800061b8:	61c2                	ld	gp,16(sp)
    800061ba:	7282                	ld	t0,32(sp)
    800061bc:	7322                	ld	t1,40(sp)
    800061be:	73c2                	ld	t2,48(sp)
    800061c0:	7462                	ld	s0,56(sp)
    800061c2:	6486                	ld	s1,64(sp)
    800061c4:	6526                	ld	a0,72(sp)
    800061c6:	65c6                	ld	a1,80(sp)
    800061c8:	6666                	ld	a2,88(sp)
    800061ca:	7686                	ld	a3,96(sp)
    800061cc:	7726                	ld	a4,104(sp)
    800061ce:	77c6                	ld	a5,112(sp)
    800061d0:	7866                	ld	a6,120(sp)
    800061d2:	688a                	ld	a7,128(sp)
    800061d4:	692a                	ld	s2,136(sp)
    800061d6:	69ca                	ld	s3,144(sp)
    800061d8:	6a6a                	ld	s4,152(sp)
    800061da:	7a8a                	ld	s5,160(sp)
    800061dc:	7b2a                	ld	s6,168(sp)
    800061de:	7bca                	ld	s7,176(sp)
    800061e0:	7c6a                	ld	s8,184(sp)
    800061e2:	6c8e                	ld	s9,192(sp)
    800061e4:	6d2e                	ld	s10,200(sp)
    800061e6:	6dce                	ld	s11,208(sp)
    800061e8:	6e6e                	ld	t3,216(sp)
    800061ea:	7e8e                	ld	t4,224(sp)
    800061ec:	7f2e                	ld	t5,232(sp)
    800061ee:	7fce                	ld	t6,240(sp)
    800061f0:	6111                	addi	sp,sp,256
    800061f2:	10200073          	sret
    800061f6:	00000013          	nop
    800061fa:	00000013          	nop
    800061fe:	0001                	nop

0000000080006200 <timervec>:
    80006200:	34051573          	csrrw	a0,mscratch,a0
    80006204:	e10c                	sd	a1,0(a0)
    80006206:	e510                	sd	a2,8(a0)
    80006208:	e914                	sd	a3,16(a0)
    8000620a:	6d0c                	ld	a1,24(a0)
    8000620c:	7110                	ld	a2,32(a0)
    8000620e:	6194                	ld	a3,0(a1)
    80006210:	96b2                	add	a3,a3,a2
    80006212:	e194                	sd	a3,0(a1)
    80006214:	4589                	li	a1,2
    80006216:	14459073          	csrw	sip,a1
    8000621a:	6914                	ld	a3,16(a0)
    8000621c:	6510                	ld	a2,8(a0)
    8000621e:	610c                	ld	a1,0(a0)
    80006220:	34051573          	csrrw	a0,mscratch,a0
    80006224:	30200073          	mret
	...

000000008000622a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    8000622a:	1141                	addi	sp,sp,-16
    8000622c:	e422                	sd	s0,8(sp)
    8000622e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80006230:	0c0007b7          	lui	a5,0xc000
    80006234:	4705                	li	a4,1
    80006236:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80006238:	c3d8                	sw	a4,4(a5)
}
    8000623a:	6422                	ld	s0,8(sp)
    8000623c:	0141                	addi	sp,sp,16
    8000623e:	8082                	ret

0000000080006240 <plicinithart>:

void
plicinithart(void)
{
    80006240:	1141                	addi	sp,sp,-16
    80006242:	e406                	sd	ra,8(sp)
    80006244:	e022                	sd	s0,0(sp)
    80006246:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006248:	ffffb097          	auipc	ra,0xffffb
    8000624c:	738080e7          	jalr	1848(ra) # 80001980 <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80006250:	0085171b          	slliw	a4,a0,0x8
    80006254:	0c0027b7          	lui	a5,0xc002
    80006258:	97ba                	add	a5,a5,a4
    8000625a:	40200713          	li	a4,1026
    8000625e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80006262:	00d5151b          	slliw	a0,a0,0xd
    80006266:	0c2017b7          	lui	a5,0xc201
    8000626a:	97aa                	add	a5,a5,a0
    8000626c:	0007a023          	sw	zero,0(a5) # c201000 <_entry-0x73dff000>
}
    80006270:	60a2                	ld	ra,8(sp)
    80006272:	6402                	ld	s0,0(sp)
    80006274:	0141                	addi	sp,sp,16
    80006276:	8082                	ret

0000000080006278 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80006278:	1141                	addi	sp,sp,-16
    8000627a:	e406                	sd	ra,8(sp)
    8000627c:	e022                	sd	s0,0(sp)
    8000627e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006280:	ffffb097          	auipc	ra,0xffffb
    80006284:	700080e7          	jalr	1792(ra) # 80001980 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80006288:	00d5151b          	slliw	a0,a0,0xd
    8000628c:	0c2017b7          	lui	a5,0xc201
    80006290:	97aa                	add	a5,a5,a0
  return irq;
}
    80006292:	43c8                	lw	a0,4(a5)
    80006294:	60a2                	ld	ra,8(sp)
    80006296:	6402                	ld	s0,0(sp)
    80006298:	0141                	addi	sp,sp,16
    8000629a:	8082                	ret

000000008000629c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    8000629c:	1101                	addi	sp,sp,-32
    8000629e:	ec06                	sd	ra,24(sp)
    800062a0:	e822                	sd	s0,16(sp)
    800062a2:	e426                	sd	s1,8(sp)
    800062a4:	1000                	addi	s0,sp,32
    800062a6:	84aa                	mv	s1,a0
  int hart = cpuid();
    800062a8:	ffffb097          	auipc	ra,0xffffb
    800062ac:	6d8080e7          	jalr	1752(ra) # 80001980 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    800062b0:	00d5151b          	slliw	a0,a0,0xd
    800062b4:	0c2017b7          	lui	a5,0xc201
    800062b8:	97aa                	add	a5,a5,a0
    800062ba:	c3c4                	sw	s1,4(a5)
}
    800062bc:	60e2                	ld	ra,24(sp)
    800062be:	6442                	ld	s0,16(sp)
    800062c0:	64a2                	ld	s1,8(sp)
    800062c2:	6105                	addi	sp,sp,32
    800062c4:	8082                	ret

00000000800062c6 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    800062c6:	1141                	addi	sp,sp,-16
    800062c8:	e406                	sd	ra,8(sp)
    800062ca:	e022                	sd	s0,0(sp)
    800062cc:	0800                	addi	s0,sp,16
  if(i >= NUM)
    800062ce:	479d                	li	a5,7
    800062d0:	04a7cc63          	blt	a5,a0,80006328 <free_desc+0x62>
    panic("free_desc 1");
  if(disk.free[i])
    800062d4:	0001d797          	auipc	a5,0x1d
    800062d8:	c1c78793          	addi	a5,a5,-996 # 80022ef0 <disk>
    800062dc:	97aa                	add	a5,a5,a0
    800062de:	0187c783          	lbu	a5,24(a5)
    800062e2:	ebb9                	bnez	a5,80006338 <free_desc+0x72>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    800062e4:	00451693          	slli	a3,a0,0x4
    800062e8:	0001d797          	auipc	a5,0x1d
    800062ec:	c0878793          	addi	a5,a5,-1016 # 80022ef0 <disk>
    800062f0:	6398                	ld	a4,0(a5)
    800062f2:	9736                	add	a4,a4,a3
    800062f4:	00073023          	sd	zero,0(a4)
  disk.desc[i].len = 0;
    800062f8:	6398                	ld	a4,0(a5)
    800062fa:	9736                	add	a4,a4,a3
    800062fc:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    80006300:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    80006304:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    80006308:	97aa                	add	a5,a5,a0
    8000630a:	4705                	li	a4,1
    8000630c:	00e78c23          	sb	a4,24(a5)
  wakeup(&disk.free[0]);
    80006310:	0001d517          	auipc	a0,0x1d
    80006314:	bf850513          	addi	a0,a0,-1032 # 80022f08 <disk+0x18>
    80006318:	ffffc097          	auipc	ra,0xffffc
    8000631c:	0d2080e7          	jalr	210(ra) # 800023ea <wakeup>
}
    80006320:	60a2                	ld	ra,8(sp)
    80006322:	6402                	ld	s0,0(sp)
    80006324:	0141                	addi	sp,sp,16
    80006326:	8082                	ret
    panic("free_desc 1");
    80006328:	00002517          	auipc	a0,0x2
    8000632c:	5b850513          	addi	a0,a0,1464 # 800088e0 <syscalls+0x300>
    80006330:	ffffa097          	auipc	ra,0xffffa
    80006334:	210080e7          	jalr	528(ra) # 80000540 <panic>
    panic("free_desc 2");
    80006338:	00002517          	auipc	a0,0x2
    8000633c:	5b850513          	addi	a0,a0,1464 # 800088f0 <syscalls+0x310>
    80006340:	ffffa097          	auipc	ra,0xffffa
    80006344:	200080e7          	jalr	512(ra) # 80000540 <panic>

0000000080006348 <virtio_disk_init>:
{
    80006348:	1101                	addi	sp,sp,-32
    8000634a:	ec06                	sd	ra,24(sp)
    8000634c:	e822                	sd	s0,16(sp)
    8000634e:	e426                	sd	s1,8(sp)
    80006350:	e04a                	sd	s2,0(sp)
    80006352:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80006354:	00002597          	auipc	a1,0x2
    80006358:	5ac58593          	addi	a1,a1,1452 # 80008900 <syscalls+0x320>
    8000635c:	0001d517          	auipc	a0,0x1d
    80006360:	cbc50513          	addi	a0,a0,-836 # 80023018 <disk+0x128>
    80006364:	ffffa097          	auipc	ra,0xffffa
    80006368:	7e2080e7          	jalr	2018(ra) # 80000b46 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    8000636c:	100017b7          	lui	a5,0x10001
    80006370:	4398                	lw	a4,0(a5)
    80006372:	2701                	sext.w	a4,a4
    80006374:	747277b7          	lui	a5,0x74727
    80006378:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    8000637c:	14f71b63          	bne	a4,a5,800064d2 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80006380:	100017b7          	lui	a5,0x10001
    80006384:	43dc                	lw	a5,4(a5)
    80006386:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006388:	4709                	li	a4,2
    8000638a:	14e79463          	bne	a5,a4,800064d2 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000638e:	100017b7          	lui	a5,0x10001
    80006392:	479c                	lw	a5,8(a5)
    80006394:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80006396:	12e79e63          	bne	a5,a4,800064d2 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    8000639a:	100017b7          	lui	a5,0x10001
    8000639e:	47d8                	lw	a4,12(a5)
    800063a0:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800063a2:	554d47b7          	lui	a5,0x554d4
    800063a6:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    800063aa:	12f71463          	bne	a4,a5,800064d2 <virtio_disk_init+0x18a>
  *R(VIRTIO_MMIO_STATUS) = status;
    800063ae:	100017b7          	lui	a5,0x10001
    800063b2:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    800063b6:	4705                	li	a4,1
    800063b8:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800063ba:	470d                	li	a4,3
    800063bc:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    800063be:	4b98                	lw	a4,16(a5)
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    800063c0:	c7ffe6b7          	lui	a3,0xc7ffe
    800063c4:	75f68693          	addi	a3,a3,1887 # ffffffffc7ffe75f <end+0xffffffff47fdb72f>
    800063c8:	8f75                	and	a4,a4,a3
    800063ca:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800063cc:	472d                	li	a4,11
    800063ce:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    800063d0:	5bbc                	lw	a5,112(a5)
    800063d2:	0007891b          	sext.w	s2,a5
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    800063d6:	8ba1                	andi	a5,a5,8
    800063d8:	10078563          	beqz	a5,800064e2 <virtio_disk_init+0x19a>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    800063dc:	100017b7          	lui	a5,0x10001
    800063e0:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    800063e4:	43fc                	lw	a5,68(a5)
    800063e6:	2781                	sext.w	a5,a5
    800063e8:	10079563          	bnez	a5,800064f2 <virtio_disk_init+0x1aa>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    800063ec:	100017b7          	lui	a5,0x10001
    800063f0:	5bdc                	lw	a5,52(a5)
    800063f2:	2781                	sext.w	a5,a5
  if(max == 0)
    800063f4:	10078763          	beqz	a5,80006502 <virtio_disk_init+0x1ba>
  if(max < NUM)
    800063f8:	471d                	li	a4,7
    800063fa:	10f77c63          	bgeu	a4,a5,80006512 <virtio_disk_init+0x1ca>
  disk.desc = kalloc();
    800063fe:	ffffa097          	auipc	ra,0xffffa
    80006402:	6e8080e7          	jalr	1768(ra) # 80000ae6 <kalloc>
    80006406:	0001d497          	auipc	s1,0x1d
    8000640a:	aea48493          	addi	s1,s1,-1302 # 80022ef0 <disk>
    8000640e:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    80006410:	ffffa097          	auipc	ra,0xffffa
    80006414:	6d6080e7          	jalr	1750(ra) # 80000ae6 <kalloc>
    80006418:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    8000641a:	ffffa097          	auipc	ra,0xffffa
    8000641e:	6cc080e7          	jalr	1740(ra) # 80000ae6 <kalloc>
    80006422:	87aa                	mv	a5,a0
    80006424:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    80006426:	6088                	ld	a0,0(s1)
    80006428:	cd6d                	beqz	a0,80006522 <virtio_disk_init+0x1da>
    8000642a:	0001d717          	auipc	a4,0x1d
    8000642e:	ace73703          	ld	a4,-1330(a4) # 80022ef8 <disk+0x8>
    80006432:	cb65                	beqz	a4,80006522 <virtio_disk_init+0x1da>
    80006434:	c7fd                	beqz	a5,80006522 <virtio_disk_init+0x1da>
  memset(disk.desc, 0, PGSIZE);
    80006436:	6605                	lui	a2,0x1
    80006438:	4581                	li	a1,0
    8000643a:	ffffb097          	auipc	ra,0xffffb
    8000643e:	898080e7          	jalr	-1896(ra) # 80000cd2 <memset>
  memset(disk.avail, 0, PGSIZE);
    80006442:	0001d497          	auipc	s1,0x1d
    80006446:	aae48493          	addi	s1,s1,-1362 # 80022ef0 <disk>
    8000644a:	6605                	lui	a2,0x1
    8000644c:	4581                	li	a1,0
    8000644e:	6488                	ld	a0,8(s1)
    80006450:	ffffb097          	auipc	ra,0xffffb
    80006454:	882080e7          	jalr	-1918(ra) # 80000cd2 <memset>
  memset(disk.used, 0, PGSIZE);
    80006458:	6605                	lui	a2,0x1
    8000645a:	4581                	li	a1,0
    8000645c:	6888                	ld	a0,16(s1)
    8000645e:	ffffb097          	auipc	ra,0xffffb
    80006462:	874080e7          	jalr	-1932(ra) # 80000cd2 <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006466:	100017b7          	lui	a5,0x10001
    8000646a:	4721                	li	a4,8
    8000646c:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    8000646e:	4098                	lw	a4,0(s1)
    80006470:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    80006474:	40d8                	lw	a4,4(s1)
    80006476:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    8000647a:	6498                	ld	a4,8(s1)
    8000647c:	0007069b          	sext.w	a3,a4
    80006480:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    80006484:	9701                	srai	a4,a4,0x20
    80006486:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    8000648a:	6898                	ld	a4,16(s1)
    8000648c:	0007069b          	sext.w	a3,a4
    80006490:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    80006494:	9701                	srai	a4,a4,0x20
    80006496:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    8000649a:	4705                	li	a4,1
    8000649c:	c3f8                	sw	a4,68(a5)
    disk.free[i] = 1;
    8000649e:	00e48c23          	sb	a4,24(s1)
    800064a2:	00e48ca3          	sb	a4,25(s1)
    800064a6:	00e48d23          	sb	a4,26(s1)
    800064aa:	00e48da3          	sb	a4,27(s1)
    800064ae:	00e48e23          	sb	a4,28(s1)
    800064b2:	00e48ea3          	sb	a4,29(s1)
    800064b6:	00e48f23          	sb	a4,30(s1)
    800064ba:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    800064be:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    800064c2:	0727a823          	sw	s2,112(a5)
}
    800064c6:	60e2                	ld	ra,24(sp)
    800064c8:	6442                	ld	s0,16(sp)
    800064ca:	64a2                	ld	s1,8(sp)
    800064cc:	6902                	ld	s2,0(sp)
    800064ce:	6105                	addi	sp,sp,32
    800064d0:	8082                	ret
    panic("could not find virtio disk");
    800064d2:	00002517          	auipc	a0,0x2
    800064d6:	43e50513          	addi	a0,a0,1086 # 80008910 <syscalls+0x330>
    800064da:	ffffa097          	auipc	ra,0xffffa
    800064de:	066080e7          	jalr	102(ra) # 80000540 <panic>
    panic("virtio disk FEATURES_OK unset");
    800064e2:	00002517          	auipc	a0,0x2
    800064e6:	44e50513          	addi	a0,a0,1102 # 80008930 <syscalls+0x350>
    800064ea:	ffffa097          	auipc	ra,0xffffa
    800064ee:	056080e7          	jalr	86(ra) # 80000540 <panic>
    panic("virtio disk should not be ready");
    800064f2:	00002517          	auipc	a0,0x2
    800064f6:	45e50513          	addi	a0,a0,1118 # 80008950 <syscalls+0x370>
    800064fa:	ffffa097          	auipc	ra,0xffffa
    800064fe:	046080e7          	jalr	70(ra) # 80000540 <panic>
    panic("virtio disk has no queue 0");
    80006502:	00002517          	auipc	a0,0x2
    80006506:	46e50513          	addi	a0,a0,1134 # 80008970 <syscalls+0x390>
    8000650a:	ffffa097          	auipc	ra,0xffffa
    8000650e:	036080e7          	jalr	54(ra) # 80000540 <panic>
    panic("virtio disk max queue too short");
    80006512:	00002517          	auipc	a0,0x2
    80006516:	47e50513          	addi	a0,a0,1150 # 80008990 <syscalls+0x3b0>
    8000651a:	ffffa097          	auipc	ra,0xffffa
    8000651e:	026080e7          	jalr	38(ra) # 80000540 <panic>
    panic("virtio disk kalloc");
    80006522:	00002517          	auipc	a0,0x2
    80006526:	48e50513          	addi	a0,a0,1166 # 800089b0 <syscalls+0x3d0>
    8000652a:	ffffa097          	auipc	ra,0xffffa
    8000652e:	016080e7          	jalr	22(ra) # 80000540 <panic>

0000000080006532 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006532:	7119                	addi	sp,sp,-128
    80006534:	fc86                	sd	ra,120(sp)
    80006536:	f8a2                	sd	s0,112(sp)
    80006538:	f4a6                	sd	s1,104(sp)
    8000653a:	f0ca                	sd	s2,96(sp)
    8000653c:	ecce                	sd	s3,88(sp)
    8000653e:	e8d2                	sd	s4,80(sp)
    80006540:	e4d6                	sd	s5,72(sp)
    80006542:	e0da                	sd	s6,64(sp)
    80006544:	fc5e                	sd	s7,56(sp)
    80006546:	f862                	sd	s8,48(sp)
    80006548:	f466                	sd	s9,40(sp)
    8000654a:	f06a                	sd	s10,32(sp)
    8000654c:	ec6e                	sd	s11,24(sp)
    8000654e:	0100                	addi	s0,sp,128
    80006550:	8aaa                	mv	s5,a0
    80006552:	8c2e                	mv	s8,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006554:	00c52d03          	lw	s10,12(a0)
    80006558:	001d1d1b          	slliw	s10,s10,0x1
    8000655c:	1d02                	slli	s10,s10,0x20
    8000655e:	020d5d13          	srli	s10,s10,0x20

  acquire(&disk.vdisk_lock);
    80006562:	0001d517          	auipc	a0,0x1d
    80006566:	ab650513          	addi	a0,a0,-1354 # 80023018 <disk+0x128>
    8000656a:	ffffa097          	auipc	ra,0xffffa
    8000656e:	66c080e7          	jalr	1644(ra) # 80000bd6 <acquire>
  for(int i = 0; i < 3; i++){
    80006572:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006574:	44a1                	li	s1,8
      disk.free[i] = 0;
    80006576:	0001db97          	auipc	s7,0x1d
    8000657a:	97ab8b93          	addi	s7,s7,-1670 # 80022ef0 <disk>
  for(int i = 0; i < 3; i++){
    8000657e:	4b0d                	li	s6,3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006580:	0001dc97          	auipc	s9,0x1d
    80006584:	a98c8c93          	addi	s9,s9,-1384 # 80023018 <disk+0x128>
    80006588:	a08d                	j	800065ea <virtio_disk_rw+0xb8>
      disk.free[i] = 0;
    8000658a:	00fb8733          	add	a4,s7,a5
    8000658e:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    80006592:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    80006594:	0207c563          	bltz	a5,800065be <virtio_disk_rw+0x8c>
  for(int i = 0; i < 3; i++){
    80006598:	2905                	addiw	s2,s2,1
    8000659a:	0611                	addi	a2,a2,4 # 1004 <_entry-0x7fffeffc>
    8000659c:	05690c63          	beq	s2,s6,800065f4 <virtio_disk_rw+0xc2>
    idx[i] = alloc_desc();
    800065a0:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    800065a2:	0001d717          	auipc	a4,0x1d
    800065a6:	94e70713          	addi	a4,a4,-1714 # 80022ef0 <disk>
    800065aa:	87ce                	mv	a5,s3
    if(disk.free[i]){
    800065ac:	01874683          	lbu	a3,24(a4)
    800065b0:	fee9                	bnez	a3,8000658a <virtio_disk_rw+0x58>
  for(int i = 0; i < NUM; i++){
    800065b2:	2785                	addiw	a5,a5,1
    800065b4:	0705                	addi	a4,a4,1
    800065b6:	fe979be3          	bne	a5,s1,800065ac <virtio_disk_rw+0x7a>
    idx[i] = alloc_desc();
    800065ba:	57fd                	li	a5,-1
    800065bc:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    800065be:	01205d63          	blez	s2,800065d8 <virtio_disk_rw+0xa6>
    800065c2:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    800065c4:	000a2503          	lw	a0,0(s4)
    800065c8:	00000097          	auipc	ra,0x0
    800065cc:	cfe080e7          	jalr	-770(ra) # 800062c6 <free_desc>
      for(int j = 0; j < i; j++)
    800065d0:	2d85                	addiw	s11,s11,1
    800065d2:	0a11                	addi	s4,s4,4
    800065d4:	ff2d98e3          	bne	s11,s2,800065c4 <virtio_disk_rw+0x92>
    sleep(&disk.free[0], &disk.vdisk_lock);
    800065d8:	85e6                	mv	a1,s9
    800065da:	0001d517          	auipc	a0,0x1d
    800065de:	92e50513          	addi	a0,a0,-1746 # 80022f08 <disk+0x18>
    800065e2:	ffffc097          	auipc	ra,0xffffc
    800065e6:	c58080e7          	jalr	-936(ra) # 8000223a <sleep>
  for(int i = 0; i < 3; i++){
    800065ea:	f8040a13          	addi	s4,s0,-128
{
    800065ee:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    800065f0:	894e                	mv	s2,s3
    800065f2:	b77d                	j	800065a0 <virtio_disk_rw+0x6e>
  }

  // format the three descriptors.
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800065f4:	f8042503          	lw	a0,-128(s0)
    800065f8:	00a50713          	addi	a4,a0,10
    800065fc:	0712                	slli	a4,a4,0x4

  if(write)
    800065fe:	0001d797          	auipc	a5,0x1d
    80006602:	8f278793          	addi	a5,a5,-1806 # 80022ef0 <disk>
    80006606:	00e786b3          	add	a3,a5,a4
    8000660a:	01803633          	snez	a2,s8
    8000660e:	c690                	sw	a2,8(a3)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    80006610:	0006a623          	sw	zero,12(a3)
  buf0->sector = sector;
    80006614:	01a6b823          	sd	s10,16(a3)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80006618:	f6070613          	addi	a2,a4,-160
    8000661c:	6394                	ld	a3,0(a5)
    8000661e:	96b2                	add	a3,a3,a2
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006620:	00870593          	addi	a1,a4,8
    80006624:	95be                	add	a1,a1,a5
  disk.desc[idx[0]].addr = (uint64) buf0;
    80006626:	e28c                	sd	a1,0(a3)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006628:	0007b803          	ld	a6,0(a5)
    8000662c:	9642                	add	a2,a2,a6
    8000662e:	46c1                	li	a3,16
    80006630:	c614                	sw	a3,8(a2)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006632:	4585                	li	a1,1
    80006634:	00b61623          	sh	a1,12(a2)
  disk.desc[idx[0]].next = idx[1];
    80006638:	f8442683          	lw	a3,-124(s0)
    8000663c:	00d61723          	sh	a3,14(a2)

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006640:	0692                	slli	a3,a3,0x4
    80006642:	9836                	add	a6,a6,a3
    80006644:	058a8613          	addi	a2,s5,88
    80006648:	00c83023          	sd	a2,0(a6)
  disk.desc[idx[1]].len = BSIZE;
    8000664c:	0007b803          	ld	a6,0(a5)
    80006650:	96c2                	add	a3,a3,a6
    80006652:	40000613          	li	a2,1024
    80006656:	c690                	sw	a2,8(a3)
  if(write)
    80006658:	001c3613          	seqz	a2,s8
    8000665c:	0016161b          	slliw	a2,a2,0x1
    disk.desc[idx[1]].flags = 0; // device reads b->data
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    80006660:	00166613          	ori	a2,a2,1
    80006664:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    80006668:	f8842603          	lw	a2,-120(s0)
    8000666c:	00c69723          	sh	a2,14(a3)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006670:	00250693          	addi	a3,a0,2
    80006674:	0692                	slli	a3,a3,0x4
    80006676:	96be                	add	a3,a3,a5
    80006678:	58fd                	li	a7,-1
    8000667a:	01168823          	sb	a7,16(a3)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    8000667e:	0612                	slli	a2,a2,0x4
    80006680:	9832                	add	a6,a6,a2
    80006682:	f9070713          	addi	a4,a4,-112
    80006686:	973e                	add	a4,a4,a5
    80006688:	00e83023          	sd	a4,0(a6)
  disk.desc[idx[2]].len = 1;
    8000668c:	6398                	ld	a4,0(a5)
    8000668e:	9732                	add	a4,a4,a2
    80006690:	c70c                	sw	a1,8(a4)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80006692:	4609                	li	a2,2
    80006694:	00c71623          	sh	a2,12(a4)
  disk.desc[idx[2]].next = 0;
    80006698:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    8000669c:	00baa223          	sw	a1,4(s5)
  disk.info[idx[0]].b = b;
    800066a0:	0156b423          	sd	s5,8(a3)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    800066a4:	6794                	ld	a3,8(a5)
    800066a6:	0026d703          	lhu	a4,2(a3)
    800066aa:	8b1d                	andi	a4,a4,7
    800066ac:	0706                	slli	a4,a4,0x1
    800066ae:	96ba                	add	a3,a3,a4
    800066b0:	00a69223          	sh	a0,4(a3)

  __sync_synchronize();
    800066b4:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    800066b8:	6798                	ld	a4,8(a5)
    800066ba:	00275783          	lhu	a5,2(a4)
    800066be:	2785                	addiw	a5,a5,1
    800066c0:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    800066c4:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    800066c8:	100017b7          	lui	a5,0x10001
    800066cc:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    800066d0:	004aa783          	lw	a5,4(s5)
    sleep(b, &disk.vdisk_lock);
    800066d4:	0001d917          	auipc	s2,0x1d
    800066d8:	94490913          	addi	s2,s2,-1724 # 80023018 <disk+0x128>
  while(b->disk == 1) {
    800066dc:	4485                	li	s1,1
    800066de:	00b79c63          	bne	a5,a1,800066f6 <virtio_disk_rw+0x1c4>
    sleep(b, &disk.vdisk_lock);
    800066e2:	85ca                	mv	a1,s2
    800066e4:	8556                	mv	a0,s5
    800066e6:	ffffc097          	auipc	ra,0xffffc
    800066ea:	b54080e7          	jalr	-1196(ra) # 8000223a <sleep>
  while(b->disk == 1) {
    800066ee:	004aa783          	lw	a5,4(s5)
    800066f2:	fe9788e3          	beq	a5,s1,800066e2 <virtio_disk_rw+0x1b0>
  }

  disk.info[idx[0]].b = 0;
    800066f6:	f8042903          	lw	s2,-128(s0)
    800066fa:	00290713          	addi	a4,s2,2
    800066fe:	0712                	slli	a4,a4,0x4
    80006700:	0001c797          	auipc	a5,0x1c
    80006704:	7f078793          	addi	a5,a5,2032 # 80022ef0 <disk>
    80006708:	97ba                	add	a5,a5,a4
    8000670a:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    8000670e:	0001c997          	auipc	s3,0x1c
    80006712:	7e298993          	addi	s3,s3,2018 # 80022ef0 <disk>
    80006716:	00491713          	slli	a4,s2,0x4
    8000671a:	0009b783          	ld	a5,0(s3)
    8000671e:	97ba                	add	a5,a5,a4
    80006720:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80006724:	854a                	mv	a0,s2
    80006726:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    8000672a:	00000097          	auipc	ra,0x0
    8000672e:	b9c080e7          	jalr	-1124(ra) # 800062c6 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    80006732:	8885                	andi	s1,s1,1
    80006734:	f0ed                	bnez	s1,80006716 <virtio_disk_rw+0x1e4>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80006736:	0001d517          	auipc	a0,0x1d
    8000673a:	8e250513          	addi	a0,a0,-1822 # 80023018 <disk+0x128>
    8000673e:	ffffa097          	auipc	ra,0xffffa
    80006742:	54c080e7          	jalr	1356(ra) # 80000c8a <release>
}
    80006746:	70e6                	ld	ra,120(sp)
    80006748:	7446                	ld	s0,112(sp)
    8000674a:	74a6                	ld	s1,104(sp)
    8000674c:	7906                	ld	s2,96(sp)
    8000674e:	69e6                	ld	s3,88(sp)
    80006750:	6a46                	ld	s4,80(sp)
    80006752:	6aa6                	ld	s5,72(sp)
    80006754:	6b06                	ld	s6,64(sp)
    80006756:	7be2                	ld	s7,56(sp)
    80006758:	7c42                	ld	s8,48(sp)
    8000675a:	7ca2                	ld	s9,40(sp)
    8000675c:	7d02                	ld	s10,32(sp)
    8000675e:	6de2                	ld	s11,24(sp)
    80006760:	6109                	addi	sp,sp,128
    80006762:	8082                	ret

0000000080006764 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006764:	1101                	addi	sp,sp,-32
    80006766:	ec06                	sd	ra,24(sp)
    80006768:	e822                	sd	s0,16(sp)
    8000676a:	e426                	sd	s1,8(sp)
    8000676c:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    8000676e:	0001c497          	auipc	s1,0x1c
    80006772:	78248493          	addi	s1,s1,1922 # 80022ef0 <disk>
    80006776:	0001d517          	auipc	a0,0x1d
    8000677a:	8a250513          	addi	a0,a0,-1886 # 80023018 <disk+0x128>
    8000677e:	ffffa097          	auipc	ra,0xffffa
    80006782:	458080e7          	jalr	1112(ra) # 80000bd6 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006786:	10001737          	lui	a4,0x10001
    8000678a:	533c                	lw	a5,96(a4)
    8000678c:	8b8d                	andi	a5,a5,3
    8000678e:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006790:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006794:	689c                	ld	a5,16(s1)
    80006796:	0204d703          	lhu	a4,32(s1)
    8000679a:	0027d783          	lhu	a5,2(a5)
    8000679e:	04f70863          	beq	a4,a5,800067ee <virtio_disk_intr+0x8a>
    __sync_synchronize();
    800067a2:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800067a6:	6898                	ld	a4,16(s1)
    800067a8:	0204d783          	lhu	a5,32(s1)
    800067ac:	8b9d                	andi	a5,a5,7
    800067ae:	078e                	slli	a5,a5,0x3
    800067b0:	97ba                	add	a5,a5,a4
    800067b2:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    800067b4:	00278713          	addi	a4,a5,2
    800067b8:	0712                	slli	a4,a4,0x4
    800067ba:	9726                	add	a4,a4,s1
    800067bc:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    800067c0:	e721                	bnez	a4,80006808 <virtio_disk_intr+0xa4>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    800067c2:	0789                	addi	a5,a5,2
    800067c4:	0792                	slli	a5,a5,0x4
    800067c6:	97a6                	add	a5,a5,s1
    800067c8:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    800067ca:	00052223          	sw	zero,4(a0)
    wakeup(b);
    800067ce:	ffffc097          	auipc	ra,0xffffc
    800067d2:	c1c080e7          	jalr	-996(ra) # 800023ea <wakeup>

    disk.used_idx += 1;
    800067d6:	0204d783          	lhu	a5,32(s1)
    800067da:	2785                	addiw	a5,a5,1
    800067dc:	17c2                	slli	a5,a5,0x30
    800067de:	93c1                	srli	a5,a5,0x30
    800067e0:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    800067e4:	6898                	ld	a4,16(s1)
    800067e6:	00275703          	lhu	a4,2(a4)
    800067ea:	faf71ce3          	bne	a4,a5,800067a2 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    800067ee:	0001d517          	auipc	a0,0x1d
    800067f2:	82a50513          	addi	a0,a0,-2006 # 80023018 <disk+0x128>
    800067f6:	ffffa097          	auipc	ra,0xffffa
    800067fa:	494080e7          	jalr	1172(ra) # 80000c8a <release>
}
    800067fe:	60e2                	ld	ra,24(sp)
    80006800:	6442                	ld	s0,16(sp)
    80006802:	64a2                	ld	s1,8(sp)
    80006804:	6105                	addi	sp,sp,32
    80006806:	8082                	ret
      panic("virtio_disk_intr status");
    80006808:	00002517          	auipc	a0,0x2
    8000680c:	1c050513          	addi	a0,a0,448 # 800089c8 <syscalls+0x3e8>
    80006810:	ffffa097          	auipc	ra,0xffffa
    80006814:	d30080e7          	jalr	-720(ra) # 80000540 <panic>
	...

0000000080007000 <_trampoline>:
    80007000:	14051073          	csrw	sscratch,a0
    80007004:	02000537          	lui	a0,0x2000
    80007008:	357d                	addiw	a0,a0,-1 # 1ffffff <_entry-0x7e000001>
    8000700a:	0536                	slli	a0,a0,0xd
    8000700c:	02153423          	sd	ra,40(a0)
    80007010:	02253823          	sd	sp,48(a0)
    80007014:	02353c23          	sd	gp,56(a0)
    80007018:	04453023          	sd	tp,64(a0)
    8000701c:	04553423          	sd	t0,72(a0)
    80007020:	04653823          	sd	t1,80(a0)
    80007024:	04753c23          	sd	t2,88(a0)
    80007028:	f120                	sd	s0,96(a0)
    8000702a:	f524                	sd	s1,104(a0)
    8000702c:	fd2c                	sd	a1,120(a0)
    8000702e:	e150                	sd	a2,128(a0)
    80007030:	e554                	sd	a3,136(a0)
    80007032:	e958                	sd	a4,144(a0)
    80007034:	ed5c                	sd	a5,152(a0)
    80007036:	0b053023          	sd	a6,160(a0)
    8000703a:	0b153423          	sd	a7,168(a0)
    8000703e:	0b253823          	sd	s2,176(a0)
    80007042:	0b353c23          	sd	s3,184(a0)
    80007046:	0d453023          	sd	s4,192(a0)
    8000704a:	0d553423          	sd	s5,200(a0)
    8000704e:	0d653823          	sd	s6,208(a0)
    80007052:	0d753c23          	sd	s7,216(a0)
    80007056:	0f853023          	sd	s8,224(a0)
    8000705a:	0f953423          	sd	s9,232(a0)
    8000705e:	0fa53823          	sd	s10,240(a0)
    80007062:	0fb53c23          	sd	s11,248(a0)
    80007066:	11c53023          	sd	t3,256(a0)
    8000706a:	11d53423          	sd	t4,264(a0)
    8000706e:	11e53823          	sd	t5,272(a0)
    80007072:	11f53c23          	sd	t6,280(a0)
    80007076:	140022f3          	csrr	t0,sscratch
    8000707a:	06553823          	sd	t0,112(a0)
    8000707e:	00853103          	ld	sp,8(a0)
    80007082:	02053203          	ld	tp,32(a0)
    80007086:	01053283          	ld	t0,16(a0)
    8000708a:	00053303          	ld	t1,0(a0)
    8000708e:	12000073          	sfence.vma
    80007092:	18031073          	csrw	satp,t1
    80007096:	12000073          	sfence.vma
    8000709a:	8282                	jr	t0

000000008000709c <userret>:
    8000709c:	12000073          	sfence.vma
    800070a0:	18051073          	csrw	satp,a0
    800070a4:	12000073          	sfence.vma
    800070a8:	02000537          	lui	a0,0x2000
    800070ac:	357d                	addiw	a0,a0,-1 # 1ffffff <_entry-0x7e000001>
    800070ae:	0536                	slli	a0,a0,0xd
    800070b0:	02853083          	ld	ra,40(a0)
    800070b4:	03053103          	ld	sp,48(a0)
    800070b8:	03853183          	ld	gp,56(a0)
    800070bc:	04053203          	ld	tp,64(a0)
    800070c0:	04853283          	ld	t0,72(a0)
    800070c4:	05053303          	ld	t1,80(a0)
    800070c8:	05853383          	ld	t2,88(a0)
    800070cc:	7120                	ld	s0,96(a0)
    800070ce:	7524                	ld	s1,104(a0)
    800070d0:	7d2c                	ld	a1,120(a0)
    800070d2:	6150                	ld	a2,128(a0)
    800070d4:	6554                	ld	a3,136(a0)
    800070d6:	6958                	ld	a4,144(a0)
    800070d8:	6d5c                	ld	a5,152(a0)
    800070da:	0a053803          	ld	a6,160(a0)
    800070de:	0a853883          	ld	a7,168(a0)
    800070e2:	0b053903          	ld	s2,176(a0)
    800070e6:	0b853983          	ld	s3,184(a0)
    800070ea:	0c053a03          	ld	s4,192(a0)
    800070ee:	0c853a83          	ld	s5,200(a0)
    800070f2:	0d053b03          	ld	s6,208(a0)
    800070f6:	0d853b83          	ld	s7,216(a0)
    800070fa:	0e053c03          	ld	s8,224(a0)
    800070fe:	0e853c83          	ld	s9,232(a0)
    80007102:	0f053d03          	ld	s10,240(a0)
    80007106:	0f853d83          	ld	s11,248(a0)
    8000710a:	10053e03          	ld	t3,256(a0)
    8000710e:	10853e83          	ld	t4,264(a0)
    80007112:	11053f03          	ld	t5,272(a0)
    80007116:	11853f83          	ld	t6,280(a0)
    8000711a:	7928                	ld	a0,112(a0)
    8000711c:	10200073          	sret
	...

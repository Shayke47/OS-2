
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	86013103          	ld	sp,-1952(sp) # 80008860 <_GLOBAL_OFFSET_TABLE_+0x8>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	078000ef          	jal	ra,8000008e <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// which arrive at timervec in kernelvec.S,
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
    80000026:	0007869b          	sext.w	a3,a5

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    8000002a:	0037979b          	slliw	a5,a5,0x3
    8000002e:	02004737          	lui	a4,0x2004
    80000032:	97ba                	add	a5,a5,a4
    80000034:	0200c737          	lui	a4,0x200c
    80000038:	ff873583          	ld	a1,-8(a4) # 200bff8 <_entry-0x7dff4008>
    8000003c:	000f4637          	lui	a2,0xf4
    80000040:	24060613          	addi	a2,a2,576 # f4240 <_entry-0x7ff0bdc0>
    80000044:	95b2                	add	a1,a1,a2
    80000046:	e38c                	sd	a1,0(a5)

  // prepare information in scratch[] for timervec.
  // scratch[0..2] : space for timervec to save registers.
  // scratch[3] : address of CLINT MTIMECMP register.
  // scratch[4] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &timer_scratch[id][0];
    80000048:	00269713          	slli	a4,a3,0x2
    8000004c:	9736                	add	a4,a4,a3
    8000004e:	00371693          	slli	a3,a4,0x3
    80000052:	00009717          	auipc	a4,0x9
    80000056:	fee70713          	addi	a4,a4,-18 # 80009040 <timer_scratch>
    8000005a:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    8000005c:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    8000005e:	f310                	sd	a2,32(a4)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    80000060:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    80000064:	00006797          	auipc	a5,0x6
    80000068:	aac78793          	addi	a5,a5,-1364 # 80005b10 <timervec>
    8000006c:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000070:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000074:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000078:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    8000007c:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    80000080:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    80000084:	30479073          	csrw	mie,a5
}
    80000088:	6422                	ld	s0,8(sp)
    8000008a:	0141                	addi	sp,sp,16
    8000008c:	8082                	ret

000000008000008e <start>:
{
    8000008e:	1141                	addi	sp,sp,-16
    80000090:	e406                	sd	ra,8(sp)
    80000092:	e022                	sd	s0,0(sp)
    80000094:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000096:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    8000009a:	7779                	lui	a4,0xffffe
    8000009c:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffd87ff>
    800000a0:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a2:	6705                	lui	a4,0x1
    800000a4:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000aa:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ae:	00001797          	auipc	a5,0x1
    800000b2:	de078793          	addi	a5,a5,-544 # 80000e8e <main>
    800000b6:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000ba:	4781                	li	a5,0
    800000bc:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000c0:	67c1                	lui	a5,0x10
    800000c2:	17fd                	addi	a5,a5,-1
    800000c4:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c8:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000cc:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000d0:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000d4:	10479073          	csrw	sie,a5
  asm volatile("csrw pmpaddr0, %0" : : "r" (x));
    800000d8:	57fd                	li	a5,-1
    800000da:	83a9                	srli	a5,a5,0xa
    800000dc:	3b079073          	csrw	pmpaddr0,a5
  asm volatile("csrw pmpcfg0, %0" : : "r" (x));
    800000e0:	47bd                	li	a5,15
    800000e2:	3a079073          	csrw	pmpcfg0,a5
  timerinit();
    800000e6:	00000097          	auipc	ra,0x0
    800000ea:	f36080e7          	jalr	-202(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000ee:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000f2:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000f4:	823e                	mv	tp,a5
  asm volatile("mret");
    800000f6:	30200073          	mret
}
    800000fa:	60a2                	ld	ra,8(sp)
    800000fc:	6402                	ld	s0,0(sp)
    800000fe:	0141                	addi	sp,sp,16
    80000100:	8082                	ret

0000000080000102 <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    80000102:	715d                	addi	sp,sp,-80
    80000104:	e486                	sd	ra,72(sp)
    80000106:	e0a2                	sd	s0,64(sp)
    80000108:	fc26                	sd	s1,56(sp)
    8000010a:	f84a                	sd	s2,48(sp)
    8000010c:	f44e                	sd	s3,40(sp)
    8000010e:	f052                	sd	s4,32(sp)
    80000110:	ec56                	sd	s5,24(sp)
    80000112:	0880                	addi	s0,sp,80
  int i;

  for(i = 0; i < n; i++){
    80000114:	04c05663          	blez	a2,80000160 <consolewrite+0x5e>
    80000118:	8a2a                	mv	s4,a0
    8000011a:	84ae                	mv	s1,a1
    8000011c:	89b2                	mv	s3,a2
    8000011e:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    80000120:	5afd                	li	s5,-1
    80000122:	4685                	li	a3,1
    80000124:	8626                	mv	a2,s1
    80000126:	85d2                	mv	a1,s4
    80000128:	fbf40513          	addi	a0,s0,-65
    8000012c:	00002097          	auipc	ra,0x2
    80000130:	32c080e7          	jalr	812(ra) # 80002458 <either_copyin>
    80000134:	01550c63          	beq	a0,s5,8000014c <consolewrite+0x4a>
      break;
    uartputc(c);
    80000138:	fbf44503          	lbu	a0,-65(s0)
    8000013c:	00000097          	auipc	ra,0x0
    80000140:	78e080e7          	jalr	1934(ra) # 800008ca <uartputc>
  for(i = 0; i < n; i++){
    80000144:	2905                	addiw	s2,s2,1
    80000146:	0485                	addi	s1,s1,1
    80000148:	fd299de3          	bne	s3,s2,80000122 <consolewrite+0x20>
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
    80000162:	b7ed                	j	8000014c <consolewrite+0x4a>

0000000080000164 <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    80000164:	7119                	addi	sp,sp,-128
    80000166:	fc86                	sd	ra,120(sp)
    80000168:	f8a2                	sd	s0,112(sp)
    8000016a:	f4a6                	sd	s1,104(sp)
    8000016c:	f0ca                	sd	s2,96(sp)
    8000016e:	ecce                	sd	s3,88(sp)
    80000170:	e8d2                	sd	s4,80(sp)
    80000172:	e4d6                	sd	s5,72(sp)
    80000174:	e0da                	sd	s6,64(sp)
    80000176:	fc5e                	sd	s7,56(sp)
    80000178:	f862                	sd	s8,48(sp)
    8000017a:	f466                	sd	s9,40(sp)
    8000017c:	f06a                	sd	s10,32(sp)
    8000017e:	ec6e                	sd	s11,24(sp)
    80000180:	0100                	addi	s0,sp,128
    80000182:	8b2a                	mv	s6,a0
    80000184:	8aae                	mv	s5,a1
    80000186:	8a32                	mv	s4,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000188:	00060b9b          	sext.w	s7,a2
  acquire(&cons.lock);
    8000018c:	00011517          	auipc	a0,0x11
    80000190:	ff450513          	addi	a0,a0,-12 # 80011180 <cons>
    80000194:	00001097          	auipc	ra,0x1
    80000198:	a50080e7          	jalr	-1456(ra) # 80000be4 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019c:	00011497          	auipc	s1,0x11
    800001a0:	fe448493          	addi	s1,s1,-28 # 80011180 <cons>
      if(myproc()->killed){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a4:	89a6                	mv	s3,s1
    800001a6:	00011917          	auipc	s2,0x11
    800001aa:	07290913          	addi	s2,s2,114 # 80011218 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF];

    if(c == C('D')){  // end-of-file
    800001ae:	4c91                	li	s9,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001b0:	5d7d                	li	s10,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001b2:	4da9                	li	s11,10
  while(n > 0){
    800001b4:	07405863          	blez	s4,80000224 <consoleread+0xc0>
    while(cons.r == cons.w){
    800001b8:	0984a783          	lw	a5,152(s1)
    800001bc:	09c4a703          	lw	a4,156(s1)
    800001c0:	02f71463          	bne	a4,a5,800001e8 <consoleread+0x84>
      if(myproc()->killed){
    800001c4:	00001097          	auipc	ra,0x1
    800001c8:	7ec080e7          	jalr	2028(ra) # 800019b0 <myproc>
    800001cc:	551c                	lw	a5,40(a0)
    800001ce:	e7b5                	bnez	a5,8000023a <consoleread+0xd6>
      sleep(&cons.r, &cons.lock);
    800001d0:	85ce                	mv	a1,s3
    800001d2:	854a                	mv	a0,s2
    800001d4:	00002097          	auipc	ra,0x2
    800001d8:	e8a080e7          	jalr	-374(ra) # 8000205e <sleep>
    while(cons.r == cons.w){
    800001dc:	0984a783          	lw	a5,152(s1)
    800001e0:	09c4a703          	lw	a4,156(s1)
    800001e4:	fef700e3          	beq	a4,a5,800001c4 <consoleread+0x60>
    c = cons.buf[cons.r++ % INPUT_BUF];
    800001e8:	0017871b          	addiw	a4,a5,1
    800001ec:	08e4ac23          	sw	a4,152(s1)
    800001f0:	07f7f713          	andi	a4,a5,127
    800001f4:	9726                	add	a4,a4,s1
    800001f6:	01874703          	lbu	a4,24(a4)
    800001fa:	00070c1b          	sext.w	s8,a4
    if(c == C('D')){  // end-of-file
    800001fe:	079c0663          	beq	s8,s9,8000026a <consoleread+0x106>
    cbuf = c;
    80000202:	f8e407a3          	sb	a4,-113(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000206:	4685                	li	a3,1
    80000208:	f8f40613          	addi	a2,s0,-113
    8000020c:	85d6                	mv	a1,s5
    8000020e:	855a                	mv	a0,s6
    80000210:	00002097          	auipc	ra,0x2
    80000214:	1f2080e7          	jalr	498(ra) # 80002402 <either_copyout>
    80000218:	01a50663          	beq	a0,s10,80000224 <consoleread+0xc0>
    dst++;
    8000021c:	0a85                	addi	s5,s5,1
    --n;
    8000021e:	3a7d                	addiw	s4,s4,-1
    if(c == '\n'){
    80000220:	f9bc1ae3          	bne	s8,s11,800001b4 <consoleread+0x50>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    80000224:	00011517          	auipc	a0,0x11
    80000228:	f5c50513          	addi	a0,a0,-164 # 80011180 <cons>
    8000022c:	00001097          	auipc	ra,0x1
    80000230:	a6c080e7          	jalr	-1428(ra) # 80000c98 <release>

  return target - n;
    80000234:	414b853b          	subw	a0,s7,s4
    80000238:	a811                	j	8000024c <consoleread+0xe8>
        release(&cons.lock);
    8000023a:	00011517          	auipc	a0,0x11
    8000023e:	f4650513          	addi	a0,a0,-186 # 80011180 <cons>
    80000242:	00001097          	auipc	ra,0x1
    80000246:	a56080e7          	jalr	-1450(ra) # 80000c98 <release>
        return -1;
    8000024a:	557d                	li	a0,-1
}
    8000024c:	70e6                	ld	ra,120(sp)
    8000024e:	7446                	ld	s0,112(sp)
    80000250:	74a6                	ld	s1,104(sp)
    80000252:	7906                	ld	s2,96(sp)
    80000254:	69e6                	ld	s3,88(sp)
    80000256:	6a46                	ld	s4,80(sp)
    80000258:	6aa6                	ld	s5,72(sp)
    8000025a:	6b06                	ld	s6,64(sp)
    8000025c:	7be2                	ld	s7,56(sp)
    8000025e:	7c42                	ld	s8,48(sp)
    80000260:	7ca2                	ld	s9,40(sp)
    80000262:	7d02                	ld	s10,32(sp)
    80000264:	6de2                	ld	s11,24(sp)
    80000266:	6109                	addi	sp,sp,128
    80000268:	8082                	ret
      if(n < target){
    8000026a:	000a071b          	sext.w	a4,s4
    8000026e:	fb777be3          	bgeu	a4,s7,80000224 <consoleread+0xc0>
        cons.r--;
    80000272:	00011717          	auipc	a4,0x11
    80000276:	faf72323          	sw	a5,-90(a4) # 80011218 <cons+0x98>
    8000027a:	b76d                	j	80000224 <consoleread+0xc0>

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
    80000290:	564080e7          	jalr	1380(ra) # 800007f0 <uartputc_sync>
}
    80000294:	60a2                	ld	ra,8(sp)
    80000296:	6402                	ld	s0,0(sp)
    80000298:	0141                	addi	sp,sp,16
    8000029a:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    8000029c:	4521                	li	a0,8
    8000029e:	00000097          	auipc	ra,0x0
    800002a2:	552080e7          	jalr	1362(ra) # 800007f0 <uartputc_sync>
    800002a6:	02000513          	li	a0,32
    800002aa:	00000097          	auipc	ra,0x0
    800002ae:	546080e7          	jalr	1350(ra) # 800007f0 <uartputc_sync>
    800002b2:	4521                	li	a0,8
    800002b4:	00000097          	auipc	ra,0x0
    800002b8:	53c080e7          	jalr	1340(ra) # 800007f0 <uartputc_sync>
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
    800002d0:	eb450513          	addi	a0,a0,-332 # 80011180 <cons>
    800002d4:	00001097          	auipc	ra,0x1
    800002d8:	910080e7          	jalr	-1776(ra) # 80000be4 <acquire>

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
    800002f6:	1bc080e7          	jalr	444(ra) # 800024ae <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002fa:	00011517          	auipc	a0,0x11
    800002fe:	e8650513          	addi	a0,a0,-378 # 80011180 <cons>
    80000302:	00001097          	auipc	ra,0x1
    80000306:	996080e7          	jalr	-1642(ra) # 80000c98 <release>
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
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    8000031e:	00011717          	auipc	a4,0x11
    80000322:	e6270713          	addi	a4,a4,-414 # 80011180 <cons>
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
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000348:	00011797          	auipc	a5,0x11
    8000034c:	e3878793          	addi	a5,a5,-456 # 80011180 <cons>
    80000350:	0a07a703          	lw	a4,160(a5)
    80000354:	0017069b          	addiw	a3,a4,1
    80000358:	0006861b          	sext.w	a2,a3
    8000035c:	0ad7a023          	sw	a3,160(a5)
    80000360:	07f77713          	andi	a4,a4,127
    80000364:	97ba                	add	a5,a5,a4
    80000366:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e == cons.r+INPUT_BUF){
    8000036a:	47a9                	li	a5,10
    8000036c:	0cf48563          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000370:	4791                	li	a5,4
    80000372:	0cf48263          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000376:	00011797          	auipc	a5,0x11
    8000037a:	ea27a783          	lw	a5,-350(a5) # 80011218 <cons+0x98>
    8000037e:	0807879b          	addiw	a5,a5,128
    80000382:	f6f61ce3          	bne	a2,a5,800002fa <consoleintr+0x3c>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000386:	863e                	mv	a2,a5
    80000388:	a07d                	j	80000436 <consoleintr+0x178>
    while(cons.e != cons.w &&
    8000038a:	00011717          	auipc	a4,0x11
    8000038e:	df670713          	addi	a4,a4,-522 # 80011180 <cons>
    80000392:	0a072783          	lw	a5,160(a4)
    80000396:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    8000039a:	00011497          	auipc	s1,0x11
    8000039e:	de648493          	addi	s1,s1,-538 # 80011180 <cons>
    while(cons.e != cons.w &&
    800003a2:	4929                	li	s2,10
    800003a4:	f4f70be3          	beq	a4,a5,800002fa <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
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
    800003da:	daa70713          	addi	a4,a4,-598 # 80011180 <cons>
    800003de:	0a072783          	lw	a5,160(a4)
    800003e2:	09c72703          	lw	a4,156(a4)
    800003e6:	f0f70ae3          	beq	a4,a5,800002fa <consoleintr+0x3c>
      cons.e--;
    800003ea:	37fd                	addiw	a5,a5,-1
    800003ec:	00011717          	auipc	a4,0x11
    800003f0:	e2f72a23          	sw	a5,-460(a4) # 80011220 <cons+0xa0>
      consputc(BACKSPACE);
    800003f4:	10000513          	li	a0,256
    800003f8:	00000097          	auipc	ra,0x0
    800003fc:	e84080e7          	jalr	-380(ra) # 8000027c <consputc>
    80000400:	bded                	j	800002fa <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    80000402:	ee048ce3          	beqz	s1,800002fa <consoleintr+0x3c>
    80000406:	bf21                	j	8000031e <consoleintr+0x60>
      consputc(c);
    80000408:	4529                	li	a0,10
    8000040a:	00000097          	auipc	ra,0x0
    8000040e:	e72080e7          	jalr	-398(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000412:	00011797          	auipc	a5,0x11
    80000416:	d6e78793          	addi	a5,a5,-658 # 80011180 <cons>
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
    8000043a:	dec7a323          	sw	a2,-538(a5) # 8001121c <cons+0x9c>
        wakeup(&cons.r);
    8000043e:	00011517          	auipc	a0,0x11
    80000442:	dda50513          	addi	a0,a0,-550 # 80011218 <cons+0x98>
    80000446:	00002097          	auipc	ra,0x2
    8000044a:	da4080e7          	jalr	-604(ra) # 800021ea <wakeup>
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
    80000464:	d2050513          	addi	a0,a0,-736 # 80011180 <cons>
    80000468:	00000097          	auipc	ra,0x0
    8000046c:	6ec080e7          	jalr	1772(ra) # 80000b54 <initlock>

  uartinit();
    80000470:	00000097          	auipc	ra,0x0
    80000474:	330080e7          	jalr	816(ra) # 800007a0 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000478:	00021797          	auipc	a5,0x21
    8000047c:	ea078793          	addi	a5,a5,-352 # 80021318 <devsw>
    80000480:	00000717          	auipc	a4,0x0
    80000484:	ce470713          	addi	a4,a4,-796 # 80000164 <consoleread>
    80000488:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    8000048a:	00000717          	auipc	a4,0x0
    8000048e:	c7870713          	addi	a4,a4,-904 # 80000102 <consolewrite>
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
    800004aa:	08054663          	bltz	a0,80000536 <printint+0x9a>
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
    800004e6:	00088b63          	beqz	a7,800004fc <printint+0x60>
    buf[i++] = '-';
    800004ea:	fe040793          	addi	a5,s0,-32
    800004ee:	973e                	add	a4,a4,a5
    800004f0:	02d00793          	li	a5,45
    800004f4:	fef70823          	sb	a5,-16(a4)
    800004f8:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    800004fc:	02e05763          	blez	a4,8000052a <printint+0x8e>
    80000500:	fd040793          	addi	a5,s0,-48
    80000504:	00e784b3          	add	s1,a5,a4
    80000508:	fff78913          	addi	s2,a5,-1
    8000050c:	993a                	add	s2,s2,a4
    8000050e:	377d                	addiw	a4,a4,-1
    80000510:	1702                	slli	a4,a4,0x20
    80000512:	9301                	srli	a4,a4,0x20
    80000514:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    80000518:	fff4c503          	lbu	a0,-1(s1)
    8000051c:	00000097          	auipc	ra,0x0
    80000520:	d60080e7          	jalr	-672(ra) # 8000027c <consputc>
  while(--i >= 0)
    80000524:	14fd                	addi	s1,s1,-1
    80000526:	ff2499e3          	bne	s1,s2,80000518 <printint+0x7c>
}
    8000052a:	70a2                	ld	ra,40(sp)
    8000052c:	7402                	ld	s0,32(sp)
    8000052e:	64e2                	ld	s1,24(sp)
    80000530:	6942                	ld	s2,16(sp)
    80000532:	6145                	addi	sp,sp,48
    80000534:	8082                	ret
    x = -xx;
    80000536:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    8000053a:	4885                	li	a7,1
    x = -xx;
    8000053c:	bf9d                	j	800004b2 <printint+0x16>

000000008000053e <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    8000053e:	1101                	addi	sp,sp,-32
    80000540:	ec06                	sd	ra,24(sp)
    80000542:	e822                	sd	s0,16(sp)
    80000544:	e426                	sd	s1,8(sp)
    80000546:	1000                	addi	s0,sp,32
    80000548:	84aa                	mv	s1,a0
  pr.locking = 0;
    8000054a:	00011797          	auipc	a5,0x11
    8000054e:	ce07ab23          	sw	zero,-778(a5) # 80011240 <pr+0x18>
  printf("panic: ");
    80000552:	00008517          	auipc	a0,0x8
    80000556:	ac650513          	addi	a0,a0,-1338 # 80008018 <etext+0x18>
    8000055a:	00000097          	auipc	ra,0x0
    8000055e:	02e080e7          	jalr	46(ra) # 80000588 <printf>
  printf(s);
    80000562:	8526                	mv	a0,s1
    80000564:	00000097          	auipc	ra,0x0
    80000568:	024080e7          	jalr	36(ra) # 80000588 <printf>
  printf("\n");
    8000056c:	00008517          	auipc	a0,0x8
    80000570:	b5c50513          	addi	a0,a0,-1188 # 800080c8 <digits+0x88>
    80000574:	00000097          	auipc	ra,0x0
    80000578:	014080e7          	jalr	20(ra) # 80000588 <printf>
  panicked = 1; // freeze uart output from other CPUs
    8000057c:	4785                	li	a5,1
    8000057e:	00009717          	auipc	a4,0x9
    80000582:	a8f72123          	sw	a5,-1406(a4) # 80009000 <panicked>
  for(;;)
    80000586:	a001                	j	80000586 <panic+0x48>

0000000080000588 <printf>:
{
    80000588:	7131                	addi	sp,sp,-192
    8000058a:	fc86                	sd	ra,120(sp)
    8000058c:	f8a2                	sd	s0,112(sp)
    8000058e:	f4a6                	sd	s1,104(sp)
    80000590:	f0ca                	sd	s2,96(sp)
    80000592:	ecce                	sd	s3,88(sp)
    80000594:	e8d2                	sd	s4,80(sp)
    80000596:	e4d6                	sd	s5,72(sp)
    80000598:	e0da                	sd	s6,64(sp)
    8000059a:	fc5e                	sd	s7,56(sp)
    8000059c:	f862                	sd	s8,48(sp)
    8000059e:	f466                	sd	s9,40(sp)
    800005a0:	f06a                	sd	s10,32(sp)
    800005a2:	ec6e                	sd	s11,24(sp)
    800005a4:	0100                	addi	s0,sp,128
    800005a6:	8a2a                	mv	s4,a0
    800005a8:	e40c                	sd	a1,8(s0)
    800005aa:	e810                	sd	a2,16(s0)
    800005ac:	ec14                	sd	a3,24(s0)
    800005ae:	f018                	sd	a4,32(s0)
    800005b0:	f41c                	sd	a5,40(s0)
    800005b2:	03043823          	sd	a6,48(s0)
    800005b6:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005ba:	00011d97          	auipc	s11,0x11
    800005be:	c86dad83          	lw	s11,-890(s11) # 80011240 <pr+0x18>
  if(locking)
    800005c2:	020d9b63          	bnez	s11,800005f8 <printf+0x70>
  if (fmt == 0)
    800005c6:	040a0263          	beqz	s4,8000060a <printf+0x82>
  va_start(ap, fmt);
    800005ca:	00840793          	addi	a5,s0,8
    800005ce:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005d2:	000a4503          	lbu	a0,0(s4)
    800005d6:	16050263          	beqz	a0,8000073a <printf+0x1b2>
    800005da:	4481                	li	s1,0
    if(c != '%'){
    800005dc:	02500a93          	li	s5,37
    switch(c){
    800005e0:	07000b13          	li	s6,112
  consputc('x');
    800005e4:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005e6:	00008b97          	auipc	s7,0x8
    800005ea:	a5ab8b93          	addi	s7,s7,-1446 # 80008040 <digits>
    switch(c){
    800005ee:	07300c93          	li	s9,115
    800005f2:	06400c13          	li	s8,100
    800005f6:	a82d                	j	80000630 <printf+0xa8>
    acquire(&pr.lock);
    800005f8:	00011517          	auipc	a0,0x11
    800005fc:	c3050513          	addi	a0,a0,-976 # 80011228 <pr>
    80000600:	00000097          	auipc	ra,0x0
    80000604:	5e4080e7          	jalr	1508(ra) # 80000be4 <acquire>
    80000608:	bf7d                	j	800005c6 <printf+0x3e>
    panic("null fmt");
    8000060a:	00008517          	auipc	a0,0x8
    8000060e:	a1e50513          	addi	a0,a0,-1506 # 80008028 <etext+0x28>
    80000612:	00000097          	auipc	ra,0x0
    80000616:	f2c080e7          	jalr	-212(ra) # 8000053e <panic>
      consputc(c);
    8000061a:	00000097          	auipc	ra,0x0
    8000061e:	c62080e7          	jalr	-926(ra) # 8000027c <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000622:	2485                	addiw	s1,s1,1
    80000624:	009a07b3          	add	a5,s4,s1
    80000628:	0007c503          	lbu	a0,0(a5)
    8000062c:	10050763          	beqz	a0,8000073a <printf+0x1b2>
    if(c != '%'){
    80000630:	ff5515e3          	bne	a0,s5,8000061a <printf+0x92>
    c = fmt[++i] & 0xff;
    80000634:	2485                	addiw	s1,s1,1
    80000636:	009a07b3          	add	a5,s4,s1
    8000063a:	0007c783          	lbu	a5,0(a5)
    8000063e:	0007891b          	sext.w	s2,a5
    if(c == 0)
    80000642:	cfe5                	beqz	a5,8000073a <printf+0x1b2>
    switch(c){
    80000644:	05678a63          	beq	a5,s6,80000698 <printf+0x110>
    80000648:	02fb7663          	bgeu	s6,a5,80000674 <printf+0xec>
    8000064c:	09978963          	beq	a5,s9,800006de <printf+0x156>
    80000650:	07800713          	li	a4,120
    80000654:	0ce79863          	bne	a5,a4,80000724 <printf+0x19c>
      printint(va_arg(ap, int), 16, 1);
    80000658:	f8843783          	ld	a5,-120(s0)
    8000065c:	00878713          	addi	a4,a5,8
    80000660:	f8e43423          	sd	a4,-120(s0)
    80000664:	4605                	li	a2,1
    80000666:	85ea                	mv	a1,s10
    80000668:	4388                	lw	a0,0(a5)
    8000066a:	00000097          	auipc	ra,0x0
    8000066e:	e32080e7          	jalr	-462(ra) # 8000049c <printint>
      break;
    80000672:	bf45                	j	80000622 <printf+0x9a>
    switch(c){
    80000674:	0b578263          	beq	a5,s5,80000718 <printf+0x190>
    80000678:	0b879663          	bne	a5,s8,80000724 <printf+0x19c>
      printint(va_arg(ap, int), 10, 1);
    8000067c:	f8843783          	ld	a5,-120(s0)
    80000680:	00878713          	addi	a4,a5,8
    80000684:	f8e43423          	sd	a4,-120(s0)
    80000688:	4605                	li	a2,1
    8000068a:	45a9                	li	a1,10
    8000068c:	4388                	lw	a0,0(a5)
    8000068e:	00000097          	auipc	ra,0x0
    80000692:	e0e080e7          	jalr	-498(ra) # 8000049c <printint>
      break;
    80000696:	b771                	j	80000622 <printf+0x9a>
      printptr(va_arg(ap, uint64));
    80000698:	f8843783          	ld	a5,-120(s0)
    8000069c:	00878713          	addi	a4,a5,8
    800006a0:	f8e43423          	sd	a4,-120(s0)
    800006a4:	0007b983          	ld	s3,0(a5)
  consputc('0');
    800006a8:	03000513          	li	a0,48
    800006ac:	00000097          	auipc	ra,0x0
    800006b0:	bd0080e7          	jalr	-1072(ra) # 8000027c <consputc>
  consputc('x');
    800006b4:	07800513          	li	a0,120
    800006b8:	00000097          	auipc	ra,0x0
    800006bc:	bc4080e7          	jalr	-1084(ra) # 8000027c <consputc>
    800006c0:	896a                	mv	s2,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006c2:	03c9d793          	srli	a5,s3,0x3c
    800006c6:	97de                	add	a5,a5,s7
    800006c8:	0007c503          	lbu	a0,0(a5)
    800006cc:	00000097          	auipc	ra,0x0
    800006d0:	bb0080e7          	jalr	-1104(ra) # 8000027c <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006d4:	0992                	slli	s3,s3,0x4
    800006d6:	397d                	addiw	s2,s2,-1
    800006d8:	fe0915e3          	bnez	s2,800006c2 <printf+0x13a>
    800006dc:	b799                	j	80000622 <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006de:	f8843783          	ld	a5,-120(s0)
    800006e2:	00878713          	addi	a4,a5,8
    800006e6:	f8e43423          	sd	a4,-120(s0)
    800006ea:	0007b903          	ld	s2,0(a5)
    800006ee:	00090e63          	beqz	s2,8000070a <printf+0x182>
      for(; *s; s++)
    800006f2:	00094503          	lbu	a0,0(s2)
    800006f6:	d515                	beqz	a0,80000622 <printf+0x9a>
        consputc(*s);
    800006f8:	00000097          	auipc	ra,0x0
    800006fc:	b84080e7          	jalr	-1148(ra) # 8000027c <consputc>
      for(; *s; s++)
    80000700:	0905                	addi	s2,s2,1
    80000702:	00094503          	lbu	a0,0(s2)
    80000706:	f96d                	bnez	a0,800006f8 <printf+0x170>
    80000708:	bf29                	j	80000622 <printf+0x9a>
        s = "(null)";
    8000070a:	00008917          	auipc	s2,0x8
    8000070e:	91690913          	addi	s2,s2,-1770 # 80008020 <etext+0x20>
      for(; *s; s++)
    80000712:	02800513          	li	a0,40
    80000716:	b7cd                	j	800006f8 <printf+0x170>
      consputc('%');
    80000718:	8556                	mv	a0,s5
    8000071a:	00000097          	auipc	ra,0x0
    8000071e:	b62080e7          	jalr	-1182(ra) # 8000027c <consputc>
      break;
    80000722:	b701                	j	80000622 <printf+0x9a>
      consputc('%');
    80000724:	8556                	mv	a0,s5
    80000726:	00000097          	auipc	ra,0x0
    8000072a:	b56080e7          	jalr	-1194(ra) # 8000027c <consputc>
      consputc(c);
    8000072e:	854a                	mv	a0,s2
    80000730:	00000097          	auipc	ra,0x0
    80000734:	b4c080e7          	jalr	-1204(ra) # 8000027c <consputc>
      break;
    80000738:	b5ed                	j	80000622 <printf+0x9a>
  if(locking)
    8000073a:	020d9163          	bnez	s11,8000075c <printf+0x1d4>
}
    8000073e:	70e6                	ld	ra,120(sp)
    80000740:	7446                	ld	s0,112(sp)
    80000742:	74a6                	ld	s1,104(sp)
    80000744:	7906                	ld	s2,96(sp)
    80000746:	69e6                	ld	s3,88(sp)
    80000748:	6a46                	ld	s4,80(sp)
    8000074a:	6aa6                	ld	s5,72(sp)
    8000074c:	6b06                	ld	s6,64(sp)
    8000074e:	7be2                	ld	s7,56(sp)
    80000750:	7c42                	ld	s8,48(sp)
    80000752:	7ca2                	ld	s9,40(sp)
    80000754:	7d02                	ld	s10,32(sp)
    80000756:	6de2                	ld	s11,24(sp)
    80000758:	6129                	addi	sp,sp,192
    8000075a:	8082                	ret
    release(&pr.lock);
    8000075c:	00011517          	auipc	a0,0x11
    80000760:	acc50513          	addi	a0,a0,-1332 # 80011228 <pr>
    80000764:	00000097          	auipc	ra,0x0
    80000768:	534080e7          	jalr	1332(ra) # 80000c98 <release>
}
    8000076c:	bfc9                	j	8000073e <printf+0x1b6>

000000008000076e <printfinit>:
    ;
}

void
printfinit(void)
{
    8000076e:	1101                	addi	sp,sp,-32
    80000770:	ec06                	sd	ra,24(sp)
    80000772:	e822                	sd	s0,16(sp)
    80000774:	e426                	sd	s1,8(sp)
    80000776:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    80000778:	00011497          	auipc	s1,0x11
    8000077c:	ab048493          	addi	s1,s1,-1360 # 80011228 <pr>
    80000780:	00008597          	auipc	a1,0x8
    80000784:	8b858593          	addi	a1,a1,-1864 # 80008038 <etext+0x38>
    80000788:	8526                	mv	a0,s1
    8000078a:	00000097          	auipc	ra,0x0
    8000078e:	3ca080e7          	jalr	970(ra) # 80000b54 <initlock>
  pr.locking = 1;
    80000792:	4785                	li	a5,1
    80000794:	cc9c                	sw	a5,24(s1)
}
    80000796:	60e2                	ld	ra,24(sp)
    80000798:	6442                	ld	s0,16(sp)
    8000079a:	64a2                	ld	s1,8(sp)
    8000079c:	6105                	addi	sp,sp,32
    8000079e:	8082                	ret

00000000800007a0 <uartinit>:

void uartstart();

void
uartinit(void)
{
    800007a0:	1141                	addi	sp,sp,-16
    800007a2:	e406                	sd	ra,8(sp)
    800007a4:	e022                	sd	s0,0(sp)
    800007a6:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007a8:	100007b7          	lui	a5,0x10000
    800007ac:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007b0:	f8000713          	li	a4,-128
    800007b4:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007b8:	470d                	li	a4,3
    800007ba:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007be:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007c2:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007c6:	469d                	li	a3,7
    800007c8:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007cc:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007d0:	00008597          	auipc	a1,0x8
    800007d4:	88858593          	addi	a1,a1,-1912 # 80008058 <digits+0x18>
    800007d8:	00011517          	auipc	a0,0x11
    800007dc:	a7050513          	addi	a0,a0,-1424 # 80011248 <uart_tx_lock>
    800007e0:	00000097          	auipc	ra,0x0
    800007e4:	374080e7          	jalr	884(ra) # 80000b54 <initlock>
}
    800007e8:	60a2                	ld	ra,8(sp)
    800007ea:	6402                	ld	s0,0(sp)
    800007ec:	0141                	addi	sp,sp,16
    800007ee:	8082                	ret

00000000800007f0 <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007f0:	1101                	addi	sp,sp,-32
    800007f2:	ec06                	sd	ra,24(sp)
    800007f4:	e822                	sd	s0,16(sp)
    800007f6:	e426                	sd	s1,8(sp)
    800007f8:	1000                	addi	s0,sp,32
    800007fa:	84aa                	mv	s1,a0
  push_off();
    800007fc:	00000097          	auipc	ra,0x0
    80000800:	39c080e7          	jalr	924(ra) # 80000b98 <push_off>

  if(panicked){
    80000804:	00008797          	auipc	a5,0x8
    80000808:	7fc7a783          	lw	a5,2044(a5) # 80009000 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000080c:	10000737          	lui	a4,0x10000
  if(panicked){
    80000810:	c391                	beqz	a5,80000814 <uartputc_sync+0x24>
    for(;;)
    80000812:	a001                	j	80000812 <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000814:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80000818:	0ff7f793          	andi	a5,a5,255
    8000081c:	0207f793          	andi	a5,a5,32
    80000820:	dbf5                	beqz	a5,80000814 <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    80000822:	0ff4f793          	andi	a5,s1,255
    80000826:	10000737          	lui	a4,0x10000
    8000082a:	00f70023          	sb	a5,0(a4) # 10000000 <_entry-0x70000000>

  pop_off();
    8000082e:	00000097          	auipc	ra,0x0
    80000832:	40a080e7          	jalr	1034(ra) # 80000c38 <pop_off>
}
    80000836:	60e2                	ld	ra,24(sp)
    80000838:	6442                	ld	s0,16(sp)
    8000083a:	64a2                	ld	s1,8(sp)
    8000083c:	6105                	addi	sp,sp,32
    8000083e:	8082                	ret

0000000080000840 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000840:	00008717          	auipc	a4,0x8
    80000844:	7c873703          	ld	a4,1992(a4) # 80009008 <uart_tx_r>
    80000848:	00008797          	auipc	a5,0x8
    8000084c:	7c87b783          	ld	a5,1992(a5) # 80009010 <uart_tx_w>
    80000850:	06e78c63          	beq	a5,a4,800008c8 <uartstart+0x88>
{
    80000854:	7139                	addi	sp,sp,-64
    80000856:	fc06                	sd	ra,56(sp)
    80000858:	f822                	sd	s0,48(sp)
    8000085a:	f426                	sd	s1,40(sp)
    8000085c:	f04a                	sd	s2,32(sp)
    8000085e:	ec4e                	sd	s3,24(sp)
    80000860:	e852                	sd	s4,16(sp)
    80000862:	e456                	sd	s5,8(sp)
    80000864:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000866:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    8000086a:	00011a17          	auipc	s4,0x11
    8000086e:	9dea0a13          	addi	s4,s4,-1570 # 80011248 <uart_tx_lock>
    uart_tx_r += 1;
    80000872:	00008497          	auipc	s1,0x8
    80000876:	79648493          	addi	s1,s1,1942 # 80009008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    8000087a:	00008997          	auipc	s3,0x8
    8000087e:	79698993          	addi	s3,s3,1942 # 80009010 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000882:	00594783          	lbu	a5,5(s2) # 10000005 <_entry-0x6ffffffb>
    80000886:	0ff7f793          	andi	a5,a5,255
    8000088a:	0207f793          	andi	a5,a5,32
    8000088e:	c785                	beqz	a5,800008b6 <uartstart+0x76>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000890:	01f77793          	andi	a5,a4,31
    80000894:	97d2                	add	a5,a5,s4
    80000896:	0187ca83          	lbu	s5,24(a5)
    uart_tx_r += 1;
    8000089a:	0705                	addi	a4,a4,1
    8000089c:	e098                	sd	a4,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    8000089e:	8526                	mv	a0,s1
    800008a0:	00002097          	auipc	ra,0x2
    800008a4:	94a080e7          	jalr	-1718(ra) # 800021ea <wakeup>
    
    WriteReg(THR, c);
    800008a8:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    800008ac:	6098                	ld	a4,0(s1)
    800008ae:	0009b783          	ld	a5,0(s3)
    800008b2:	fce798e3          	bne	a5,a4,80000882 <uartstart+0x42>
  }
}
    800008b6:	70e2                	ld	ra,56(sp)
    800008b8:	7442                	ld	s0,48(sp)
    800008ba:	74a2                	ld	s1,40(sp)
    800008bc:	7902                	ld	s2,32(sp)
    800008be:	69e2                	ld	s3,24(sp)
    800008c0:	6a42                	ld	s4,16(sp)
    800008c2:	6aa2                	ld	s5,8(sp)
    800008c4:	6121                	addi	sp,sp,64
    800008c6:	8082                	ret
    800008c8:	8082                	ret

00000000800008ca <uartputc>:
{
    800008ca:	7179                	addi	sp,sp,-48
    800008cc:	f406                	sd	ra,40(sp)
    800008ce:	f022                	sd	s0,32(sp)
    800008d0:	ec26                	sd	s1,24(sp)
    800008d2:	e84a                	sd	s2,16(sp)
    800008d4:	e44e                	sd	s3,8(sp)
    800008d6:	e052                	sd	s4,0(sp)
    800008d8:	1800                	addi	s0,sp,48
    800008da:	89aa                	mv	s3,a0
  acquire(&uart_tx_lock);
    800008dc:	00011517          	auipc	a0,0x11
    800008e0:	96c50513          	addi	a0,a0,-1684 # 80011248 <uart_tx_lock>
    800008e4:	00000097          	auipc	ra,0x0
    800008e8:	300080e7          	jalr	768(ra) # 80000be4 <acquire>
  if(panicked){
    800008ec:	00008797          	auipc	a5,0x8
    800008f0:	7147a783          	lw	a5,1812(a5) # 80009000 <panicked>
    800008f4:	c391                	beqz	a5,800008f8 <uartputc+0x2e>
    for(;;)
    800008f6:	a001                	j	800008f6 <uartputc+0x2c>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008f8:	00008797          	auipc	a5,0x8
    800008fc:	7187b783          	ld	a5,1816(a5) # 80009010 <uart_tx_w>
    80000900:	00008717          	auipc	a4,0x8
    80000904:	70873703          	ld	a4,1800(a4) # 80009008 <uart_tx_r>
    80000908:	02070713          	addi	a4,a4,32
    8000090c:	02f71b63          	bne	a4,a5,80000942 <uartputc+0x78>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000910:	00011a17          	auipc	s4,0x11
    80000914:	938a0a13          	addi	s4,s4,-1736 # 80011248 <uart_tx_lock>
    80000918:	00008497          	auipc	s1,0x8
    8000091c:	6f048493          	addi	s1,s1,1776 # 80009008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000920:	00008917          	auipc	s2,0x8
    80000924:	6f090913          	addi	s2,s2,1776 # 80009010 <uart_tx_w>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000928:	85d2                	mv	a1,s4
    8000092a:	8526                	mv	a0,s1
    8000092c:	00001097          	auipc	ra,0x1
    80000930:	732080e7          	jalr	1842(ra) # 8000205e <sleep>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000934:	00093783          	ld	a5,0(s2)
    80000938:	6098                	ld	a4,0(s1)
    8000093a:	02070713          	addi	a4,a4,32
    8000093e:	fef705e3          	beq	a4,a5,80000928 <uartputc+0x5e>
      uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000942:	00011497          	auipc	s1,0x11
    80000946:	90648493          	addi	s1,s1,-1786 # 80011248 <uart_tx_lock>
    8000094a:	01f7f713          	andi	a4,a5,31
    8000094e:	9726                	add	a4,a4,s1
    80000950:	01370c23          	sb	s3,24(a4)
      uart_tx_w += 1;
    80000954:	0785                	addi	a5,a5,1
    80000956:	00008717          	auipc	a4,0x8
    8000095a:	6af73d23          	sd	a5,1722(a4) # 80009010 <uart_tx_w>
      uartstart();
    8000095e:	00000097          	auipc	ra,0x0
    80000962:	ee2080e7          	jalr	-286(ra) # 80000840 <uartstart>
      release(&uart_tx_lock);
    80000966:	8526                	mv	a0,s1
    80000968:	00000097          	auipc	ra,0x0
    8000096c:	330080e7          	jalr	816(ra) # 80000c98 <release>
}
    80000970:	70a2                	ld	ra,40(sp)
    80000972:	7402                	ld	s0,32(sp)
    80000974:	64e2                	ld	s1,24(sp)
    80000976:	6942                	ld	s2,16(sp)
    80000978:	69a2                	ld	s3,8(sp)
    8000097a:	6a02                	ld	s4,0(sp)
    8000097c:	6145                	addi	sp,sp,48
    8000097e:	8082                	ret

0000000080000980 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    80000980:	1141                	addi	sp,sp,-16
    80000982:	e422                	sd	s0,8(sp)
    80000984:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    80000986:	100007b7          	lui	a5,0x10000
    8000098a:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    8000098e:	8b85                	andi	a5,a5,1
    80000990:	cb91                	beqz	a5,800009a4 <uartgetc+0x24>
    // input data is ready.
    return ReadReg(RHR);
    80000992:	100007b7          	lui	a5,0x10000
    80000996:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
    8000099a:	0ff57513          	andi	a0,a0,255
  } else {
    return -1;
  }
}
    8000099e:	6422                	ld	s0,8(sp)
    800009a0:	0141                	addi	sp,sp,16
    800009a2:	8082                	ret
    return -1;
    800009a4:	557d                	li	a0,-1
    800009a6:	bfe5                	j	8000099e <uartgetc+0x1e>

00000000800009a8 <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from trap.c.
void
uartintr(void)
{
    800009a8:	1101                	addi	sp,sp,-32
    800009aa:	ec06                	sd	ra,24(sp)
    800009ac:	e822                	sd	s0,16(sp)
    800009ae:	e426                	sd	s1,8(sp)
    800009b0:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009b2:	54fd                	li	s1,-1
    int c = uartgetc();
    800009b4:	00000097          	auipc	ra,0x0
    800009b8:	fcc080e7          	jalr	-52(ra) # 80000980 <uartgetc>
    if(c == -1)
    800009bc:	00950763          	beq	a0,s1,800009ca <uartintr+0x22>
      break;
    consoleintr(c);
    800009c0:	00000097          	auipc	ra,0x0
    800009c4:	8fe080e7          	jalr	-1794(ra) # 800002be <consoleintr>
  while(1){
    800009c8:	b7f5                	j	800009b4 <uartintr+0xc>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009ca:	00011497          	auipc	s1,0x11
    800009ce:	87e48493          	addi	s1,s1,-1922 # 80011248 <uart_tx_lock>
    800009d2:	8526                	mv	a0,s1
    800009d4:	00000097          	auipc	ra,0x0
    800009d8:	210080e7          	jalr	528(ra) # 80000be4 <acquire>
  uartstart();
    800009dc:	00000097          	auipc	ra,0x0
    800009e0:	e64080e7          	jalr	-412(ra) # 80000840 <uartstart>
  release(&uart_tx_lock);
    800009e4:	8526                	mv	a0,s1
    800009e6:	00000097          	auipc	ra,0x0
    800009ea:	2b2080e7          	jalr	690(ra) # 80000c98 <release>
}
    800009ee:	60e2                	ld	ra,24(sp)
    800009f0:	6442                	ld	s0,16(sp)
    800009f2:	64a2                	ld	s1,8(sp)
    800009f4:	6105                	addi	sp,sp,32
    800009f6:	8082                	ret

00000000800009f8 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    800009f8:	1101                	addi	sp,sp,-32
    800009fa:	ec06                	sd	ra,24(sp)
    800009fc:	e822                	sd	s0,16(sp)
    800009fe:	e426                	sd	s1,8(sp)
    80000a00:	e04a                	sd	s2,0(sp)
    80000a02:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    80000a04:	03451793          	slli	a5,a0,0x34
    80000a08:	ebb9                	bnez	a5,80000a5e <kfree+0x66>
    80000a0a:	84aa                	mv	s1,a0
    80000a0c:	00025797          	auipc	a5,0x25
    80000a10:	5f478793          	addi	a5,a5,1524 # 80026000 <end>
    80000a14:	04f56563          	bltu	a0,a5,80000a5e <kfree+0x66>
    80000a18:	47c5                	li	a5,17
    80000a1a:	07ee                	slli	a5,a5,0x1b
    80000a1c:	04f57163          	bgeu	a0,a5,80000a5e <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a20:	6605                	lui	a2,0x1
    80000a22:	4585                	li	a1,1
    80000a24:	00000097          	auipc	ra,0x0
    80000a28:	2bc080e7          	jalr	700(ra) # 80000ce0 <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a2c:	00011917          	auipc	s2,0x11
    80000a30:	85490913          	addi	s2,s2,-1964 # 80011280 <kmem>
    80000a34:	854a                	mv	a0,s2
    80000a36:	00000097          	auipc	ra,0x0
    80000a3a:	1ae080e7          	jalr	430(ra) # 80000be4 <acquire>
  r->next = kmem.freelist;
    80000a3e:	01893783          	ld	a5,24(s2)
    80000a42:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a44:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a48:	854a                	mv	a0,s2
    80000a4a:	00000097          	auipc	ra,0x0
    80000a4e:	24e080e7          	jalr	590(ra) # 80000c98 <release>
}
    80000a52:	60e2                	ld	ra,24(sp)
    80000a54:	6442                	ld	s0,16(sp)
    80000a56:	64a2                	ld	s1,8(sp)
    80000a58:	6902                	ld	s2,0(sp)
    80000a5a:	6105                	addi	sp,sp,32
    80000a5c:	8082                	ret
    panic("kfree");
    80000a5e:	00007517          	auipc	a0,0x7
    80000a62:	60250513          	addi	a0,a0,1538 # 80008060 <digits+0x20>
    80000a66:	00000097          	auipc	ra,0x0
    80000a6a:	ad8080e7          	jalr	-1320(ra) # 8000053e <panic>

0000000080000a6e <freerange>:
{
    80000a6e:	7179                	addi	sp,sp,-48
    80000a70:	f406                	sd	ra,40(sp)
    80000a72:	f022                	sd	s0,32(sp)
    80000a74:	ec26                	sd	s1,24(sp)
    80000a76:	e84a                	sd	s2,16(sp)
    80000a78:	e44e                	sd	s3,8(sp)
    80000a7a:	e052                	sd	s4,0(sp)
    80000a7c:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000a7e:	6785                	lui	a5,0x1
    80000a80:	fff78493          	addi	s1,a5,-1 # fff <_entry-0x7ffff001>
    80000a84:	94aa                	add	s1,s1,a0
    80000a86:	757d                	lui	a0,0xfffff
    80000a88:	8ce9                	and	s1,s1,a0
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a8a:	94be                	add	s1,s1,a5
    80000a8c:	0095ee63          	bltu	a1,s1,80000aa8 <freerange+0x3a>
    80000a90:	892e                	mv	s2,a1
    kfree(p);
    80000a92:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a94:	6985                	lui	s3,0x1
    kfree(p);
    80000a96:	01448533          	add	a0,s1,s4
    80000a9a:	00000097          	auipc	ra,0x0
    80000a9e:	f5e080e7          	jalr	-162(ra) # 800009f8 <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000aa2:	94ce                	add	s1,s1,s3
    80000aa4:	fe9979e3          	bgeu	s2,s1,80000a96 <freerange+0x28>
}
    80000aa8:	70a2                	ld	ra,40(sp)
    80000aaa:	7402                	ld	s0,32(sp)
    80000aac:	64e2                	ld	s1,24(sp)
    80000aae:	6942                	ld	s2,16(sp)
    80000ab0:	69a2                	ld	s3,8(sp)
    80000ab2:	6a02                	ld	s4,0(sp)
    80000ab4:	6145                	addi	sp,sp,48
    80000ab6:	8082                	ret

0000000080000ab8 <kinit>:
{
    80000ab8:	1141                	addi	sp,sp,-16
    80000aba:	e406                	sd	ra,8(sp)
    80000abc:	e022                	sd	s0,0(sp)
    80000abe:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000ac0:	00007597          	auipc	a1,0x7
    80000ac4:	5a858593          	addi	a1,a1,1448 # 80008068 <digits+0x28>
    80000ac8:	00010517          	auipc	a0,0x10
    80000acc:	7b850513          	addi	a0,a0,1976 # 80011280 <kmem>
    80000ad0:	00000097          	auipc	ra,0x0
    80000ad4:	084080e7          	jalr	132(ra) # 80000b54 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000ad8:	45c5                	li	a1,17
    80000ada:	05ee                	slli	a1,a1,0x1b
    80000adc:	00025517          	auipc	a0,0x25
    80000ae0:	52450513          	addi	a0,a0,1316 # 80026000 <end>
    80000ae4:	00000097          	auipc	ra,0x0
    80000ae8:	f8a080e7          	jalr	-118(ra) # 80000a6e <freerange>
}
    80000aec:	60a2                	ld	ra,8(sp)
    80000aee:	6402                	ld	s0,0(sp)
    80000af0:	0141                	addi	sp,sp,16
    80000af2:	8082                	ret

0000000080000af4 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000af4:	1101                	addi	sp,sp,-32
    80000af6:	ec06                	sd	ra,24(sp)
    80000af8:	e822                	sd	s0,16(sp)
    80000afa:	e426                	sd	s1,8(sp)
    80000afc:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000afe:	00010497          	auipc	s1,0x10
    80000b02:	78248493          	addi	s1,s1,1922 # 80011280 <kmem>
    80000b06:	8526                	mv	a0,s1
    80000b08:	00000097          	auipc	ra,0x0
    80000b0c:	0dc080e7          	jalr	220(ra) # 80000be4 <acquire>
  r = kmem.freelist;
    80000b10:	6c84                	ld	s1,24(s1)
  if(r)
    80000b12:	c885                	beqz	s1,80000b42 <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b14:	609c                	ld	a5,0(s1)
    80000b16:	00010517          	auipc	a0,0x10
    80000b1a:	76a50513          	addi	a0,a0,1898 # 80011280 <kmem>
    80000b1e:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b20:	00000097          	auipc	ra,0x0
    80000b24:	178080e7          	jalr	376(ra) # 80000c98 <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b28:	6605                	lui	a2,0x1
    80000b2a:	4595                	li	a1,5
    80000b2c:	8526                	mv	a0,s1
    80000b2e:	00000097          	auipc	ra,0x0
    80000b32:	1b2080e7          	jalr	434(ra) # 80000ce0 <memset>
  return (void*)r;
}
    80000b36:	8526                	mv	a0,s1
    80000b38:	60e2                	ld	ra,24(sp)
    80000b3a:	6442                	ld	s0,16(sp)
    80000b3c:	64a2                	ld	s1,8(sp)
    80000b3e:	6105                	addi	sp,sp,32
    80000b40:	8082                	ret
  release(&kmem.lock);
    80000b42:	00010517          	auipc	a0,0x10
    80000b46:	73e50513          	addi	a0,a0,1854 # 80011280 <kmem>
    80000b4a:	00000097          	auipc	ra,0x0
    80000b4e:	14e080e7          	jalr	334(ra) # 80000c98 <release>
  if(r)
    80000b52:	b7d5                	j	80000b36 <kalloc+0x42>

0000000080000b54 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b54:	1141                	addi	sp,sp,-16
    80000b56:	e422                	sd	s0,8(sp)
    80000b58:	0800                	addi	s0,sp,16
  lk->name = name;
    80000b5a:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000b5c:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000b60:	00053823          	sd	zero,16(a0)
}
    80000b64:	6422                	ld	s0,8(sp)
    80000b66:	0141                	addi	sp,sp,16
    80000b68:	8082                	ret

0000000080000b6a <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000b6a:	411c                	lw	a5,0(a0)
    80000b6c:	e399                	bnez	a5,80000b72 <holding+0x8>
    80000b6e:	4501                	li	a0,0
  return r;
}
    80000b70:	8082                	ret
{
    80000b72:	1101                	addi	sp,sp,-32
    80000b74:	ec06                	sd	ra,24(sp)
    80000b76:	e822                	sd	s0,16(sp)
    80000b78:	e426                	sd	s1,8(sp)
    80000b7a:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000b7c:	6904                	ld	s1,16(a0)
    80000b7e:	00001097          	auipc	ra,0x1
    80000b82:	e16080e7          	jalr	-490(ra) # 80001994 <mycpu>
    80000b86:	40a48533          	sub	a0,s1,a0
    80000b8a:	00153513          	seqz	a0,a0
}
    80000b8e:	60e2                	ld	ra,24(sp)
    80000b90:	6442                	ld	s0,16(sp)
    80000b92:	64a2                	ld	s1,8(sp)
    80000b94:	6105                	addi	sp,sp,32
    80000b96:	8082                	ret

0000000080000b98 <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000b98:	1101                	addi	sp,sp,-32
    80000b9a:	ec06                	sd	ra,24(sp)
    80000b9c:	e822                	sd	s0,16(sp)
    80000b9e:	e426                	sd	s1,8(sp)
    80000ba0:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000ba2:	100024f3          	csrr	s1,sstatus
    80000ba6:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000baa:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000bac:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000bb0:	00001097          	auipc	ra,0x1
    80000bb4:	de4080e7          	jalr	-540(ra) # 80001994 <mycpu>
    80000bb8:	5d3c                	lw	a5,120(a0)
    80000bba:	cf89                	beqz	a5,80000bd4 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bbc:	00001097          	auipc	ra,0x1
    80000bc0:	dd8080e7          	jalr	-552(ra) # 80001994 <mycpu>
    80000bc4:	5d3c                	lw	a5,120(a0)
    80000bc6:	2785                	addiw	a5,a5,1
    80000bc8:	dd3c                	sw	a5,120(a0)
}
    80000bca:	60e2                	ld	ra,24(sp)
    80000bcc:	6442                	ld	s0,16(sp)
    80000bce:	64a2                	ld	s1,8(sp)
    80000bd0:	6105                	addi	sp,sp,32
    80000bd2:	8082                	ret
    mycpu()->intena = old;
    80000bd4:	00001097          	auipc	ra,0x1
    80000bd8:	dc0080e7          	jalr	-576(ra) # 80001994 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000bdc:	8085                	srli	s1,s1,0x1
    80000bde:	8885                	andi	s1,s1,1
    80000be0:	dd64                	sw	s1,124(a0)
    80000be2:	bfe9                	j	80000bbc <push_off+0x24>

0000000080000be4 <acquire>:
{
    80000be4:	1101                	addi	sp,sp,-32
    80000be6:	ec06                	sd	ra,24(sp)
    80000be8:	e822                	sd	s0,16(sp)
    80000bea:	e426                	sd	s1,8(sp)
    80000bec:	1000                	addi	s0,sp,32
    80000bee:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000bf0:	00000097          	auipc	ra,0x0
    80000bf4:	fa8080e7          	jalr	-88(ra) # 80000b98 <push_off>
  if(holding(lk))
    80000bf8:	8526                	mv	a0,s1
    80000bfa:	00000097          	auipc	ra,0x0
    80000bfe:	f70080e7          	jalr	-144(ra) # 80000b6a <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c02:	4705                	li	a4,1
  if(holding(lk))
    80000c04:	e115                	bnez	a0,80000c28 <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c06:	87ba                	mv	a5,a4
    80000c08:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000c0c:	2781                	sext.w	a5,a5
    80000c0e:	ffe5                	bnez	a5,80000c06 <acquire+0x22>
  __sync_synchronize();
    80000c10:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c14:	00001097          	auipc	ra,0x1
    80000c18:	d80080e7          	jalr	-640(ra) # 80001994 <mycpu>
    80000c1c:	e888                	sd	a0,16(s1)
}
    80000c1e:	60e2                	ld	ra,24(sp)
    80000c20:	6442                	ld	s0,16(sp)
    80000c22:	64a2                	ld	s1,8(sp)
    80000c24:	6105                	addi	sp,sp,32
    80000c26:	8082                	ret
    panic("acquire");
    80000c28:	00007517          	auipc	a0,0x7
    80000c2c:	44850513          	addi	a0,a0,1096 # 80008070 <digits+0x30>
    80000c30:	00000097          	auipc	ra,0x0
    80000c34:	90e080e7          	jalr	-1778(ra) # 8000053e <panic>

0000000080000c38 <pop_off>:

void
pop_off(void)
{
    80000c38:	1141                	addi	sp,sp,-16
    80000c3a:	e406                	sd	ra,8(sp)
    80000c3c:	e022                	sd	s0,0(sp)
    80000c3e:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c40:	00001097          	auipc	ra,0x1
    80000c44:	d54080e7          	jalr	-684(ra) # 80001994 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c48:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c4c:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c4e:	e78d                	bnez	a5,80000c78 <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c50:	5d3c                	lw	a5,120(a0)
    80000c52:	02f05b63          	blez	a5,80000c88 <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000c56:	37fd                	addiw	a5,a5,-1
    80000c58:	0007871b          	sext.w	a4,a5
    80000c5c:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c5e:	eb09                	bnez	a4,80000c70 <pop_off+0x38>
    80000c60:	5d7c                	lw	a5,124(a0)
    80000c62:	c799                	beqz	a5,80000c70 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c64:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000c68:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c6c:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000c70:	60a2                	ld	ra,8(sp)
    80000c72:	6402                	ld	s0,0(sp)
    80000c74:	0141                	addi	sp,sp,16
    80000c76:	8082                	ret
    panic("pop_off - interruptible");
    80000c78:	00007517          	auipc	a0,0x7
    80000c7c:	40050513          	addi	a0,a0,1024 # 80008078 <digits+0x38>
    80000c80:	00000097          	auipc	ra,0x0
    80000c84:	8be080e7          	jalr	-1858(ra) # 8000053e <panic>
    panic("pop_off");
    80000c88:	00007517          	auipc	a0,0x7
    80000c8c:	40850513          	addi	a0,a0,1032 # 80008090 <digits+0x50>
    80000c90:	00000097          	auipc	ra,0x0
    80000c94:	8ae080e7          	jalr	-1874(ra) # 8000053e <panic>

0000000080000c98 <release>:
{
    80000c98:	1101                	addi	sp,sp,-32
    80000c9a:	ec06                	sd	ra,24(sp)
    80000c9c:	e822                	sd	s0,16(sp)
    80000c9e:	e426                	sd	s1,8(sp)
    80000ca0:	1000                	addi	s0,sp,32
    80000ca2:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000ca4:	00000097          	auipc	ra,0x0
    80000ca8:	ec6080e7          	jalr	-314(ra) # 80000b6a <holding>
    80000cac:	c115                	beqz	a0,80000cd0 <release+0x38>
  lk->cpu = 0;
    80000cae:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000cb2:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000cb6:	0f50000f          	fence	iorw,ow
    80000cba:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000cbe:	00000097          	auipc	ra,0x0
    80000cc2:	f7a080e7          	jalr	-134(ra) # 80000c38 <pop_off>
}
    80000cc6:	60e2                	ld	ra,24(sp)
    80000cc8:	6442                	ld	s0,16(sp)
    80000cca:	64a2                	ld	s1,8(sp)
    80000ccc:	6105                	addi	sp,sp,32
    80000cce:	8082                	ret
    panic("release");
    80000cd0:	00007517          	auipc	a0,0x7
    80000cd4:	3c850513          	addi	a0,a0,968 # 80008098 <digits+0x58>
    80000cd8:	00000097          	auipc	ra,0x0
    80000cdc:	866080e7          	jalr	-1946(ra) # 8000053e <panic>

0000000080000ce0 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000ce0:	1141                	addi	sp,sp,-16
    80000ce2:	e422                	sd	s0,8(sp)
    80000ce4:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000ce6:	ce09                	beqz	a2,80000d00 <memset+0x20>
    80000ce8:	87aa                	mv	a5,a0
    80000cea:	fff6071b          	addiw	a4,a2,-1
    80000cee:	1702                	slli	a4,a4,0x20
    80000cf0:	9301                	srli	a4,a4,0x20
    80000cf2:	0705                	addi	a4,a4,1
    80000cf4:	972a                	add	a4,a4,a0
    cdst[i] = c;
    80000cf6:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000cfa:	0785                	addi	a5,a5,1
    80000cfc:	fee79de3          	bne	a5,a4,80000cf6 <memset+0x16>
  }
  return dst;
}
    80000d00:	6422                	ld	s0,8(sp)
    80000d02:	0141                	addi	sp,sp,16
    80000d04:	8082                	ret

0000000080000d06 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000d06:	1141                	addi	sp,sp,-16
    80000d08:	e422                	sd	s0,8(sp)
    80000d0a:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000d0c:	ca05                	beqz	a2,80000d3c <memcmp+0x36>
    80000d0e:	fff6069b          	addiw	a3,a2,-1
    80000d12:	1682                	slli	a3,a3,0x20
    80000d14:	9281                	srli	a3,a3,0x20
    80000d16:	0685                	addi	a3,a3,1
    80000d18:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d1a:	00054783          	lbu	a5,0(a0)
    80000d1e:	0005c703          	lbu	a4,0(a1)
    80000d22:	00e79863          	bne	a5,a4,80000d32 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d26:	0505                	addi	a0,a0,1
    80000d28:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d2a:	fed518e3          	bne	a0,a3,80000d1a <memcmp+0x14>
  }

  return 0;
    80000d2e:	4501                	li	a0,0
    80000d30:	a019                	j	80000d36 <memcmp+0x30>
      return *s1 - *s2;
    80000d32:	40e7853b          	subw	a0,a5,a4
}
    80000d36:	6422                	ld	s0,8(sp)
    80000d38:	0141                	addi	sp,sp,16
    80000d3a:	8082                	ret
  return 0;
    80000d3c:	4501                	li	a0,0
    80000d3e:	bfe5                	j	80000d36 <memcmp+0x30>

0000000080000d40 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d40:	1141                	addi	sp,sp,-16
    80000d42:	e422                	sd	s0,8(sp)
    80000d44:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000d46:	ca0d                	beqz	a2,80000d78 <memmove+0x38>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d48:	00a5f963          	bgeu	a1,a0,80000d5a <memmove+0x1a>
    80000d4c:	02061693          	slli	a3,a2,0x20
    80000d50:	9281                	srli	a3,a3,0x20
    80000d52:	00d58733          	add	a4,a1,a3
    80000d56:	02e56463          	bltu	a0,a4,80000d7e <memmove+0x3e>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d5a:	fff6079b          	addiw	a5,a2,-1
    80000d5e:	1782                	slli	a5,a5,0x20
    80000d60:	9381                	srli	a5,a5,0x20
    80000d62:	0785                	addi	a5,a5,1
    80000d64:	97ae                	add	a5,a5,a1
    80000d66:	872a                	mv	a4,a0
      *d++ = *s++;
    80000d68:	0585                	addi	a1,a1,1
    80000d6a:	0705                	addi	a4,a4,1
    80000d6c:	fff5c683          	lbu	a3,-1(a1)
    80000d70:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000d74:	fef59ae3          	bne	a1,a5,80000d68 <memmove+0x28>

  return dst;
}
    80000d78:	6422                	ld	s0,8(sp)
    80000d7a:	0141                	addi	sp,sp,16
    80000d7c:	8082                	ret
    d += n;
    80000d7e:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000d80:	fff6079b          	addiw	a5,a2,-1
    80000d84:	1782                	slli	a5,a5,0x20
    80000d86:	9381                	srli	a5,a5,0x20
    80000d88:	fff7c793          	not	a5,a5
    80000d8c:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000d8e:	177d                	addi	a4,a4,-1
    80000d90:	16fd                	addi	a3,a3,-1
    80000d92:	00074603          	lbu	a2,0(a4)
    80000d96:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000d9a:	fef71ae3          	bne	a4,a5,80000d8e <memmove+0x4e>
    80000d9e:	bfe9                	j	80000d78 <memmove+0x38>

0000000080000da0 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000da0:	1141                	addi	sp,sp,-16
    80000da2:	e406                	sd	ra,8(sp)
    80000da4:	e022                	sd	s0,0(sp)
    80000da6:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000da8:	00000097          	auipc	ra,0x0
    80000dac:	f98080e7          	jalr	-104(ra) # 80000d40 <memmove>
}
    80000db0:	60a2                	ld	ra,8(sp)
    80000db2:	6402                	ld	s0,0(sp)
    80000db4:	0141                	addi	sp,sp,16
    80000db6:	8082                	ret

0000000080000db8 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000db8:	1141                	addi	sp,sp,-16
    80000dba:	e422                	sd	s0,8(sp)
    80000dbc:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000dbe:	ce11                	beqz	a2,80000dda <strncmp+0x22>
    80000dc0:	00054783          	lbu	a5,0(a0)
    80000dc4:	cf89                	beqz	a5,80000dde <strncmp+0x26>
    80000dc6:	0005c703          	lbu	a4,0(a1)
    80000dca:	00f71a63          	bne	a4,a5,80000dde <strncmp+0x26>
    n--, p++, q++;
    80000dce:	367d                	addiw	a2,a2,-1
    80000dd0:	0505                	addi	a0,a0,1
    80000dd2:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000dd4:	f675                	bnez	a2,80000dc0 <strncmp+0x8>
  if(n == 0)
    return 0;
    80000dd6:	4501                	li	a0,0
    80000dd8:	a809                	j	80000dea <strncmp+0x32>
    80000dda:	4501                	li	a0,0
    80000ddc:	a039                	j	80000dea <strncmp+0x32>
  if(n == 0)
    80000dde:	ca09                	beqz	a2,80000df0 <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000de0:	00054503          	lbu	a0,0(a0)
    80000de4:	0005c783          	lbu	a5,0(a1)
    80000de8:	9d1d                	subw	a0,a0,a5
}
    80000dea:	6422                	ld	s0,8(sp)
    80000dec:	0141                	addi	sp,sp,16
    80000dee:	8082                	ret
    return 0;
    80000df0:	4501                	li	a0,0
    80000df2:	bfe5                	j	80000dea <strncmp+0x32>

0000000080000df4 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000df4:	1141                	addi	sp,sp,-16
    80000df6:	e422                	sd	s0,8(sp)
    80000df8:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000dfa:	872a                	mv	a4,a0
    80000dfc:	8832                	mv	a6,a2
    80000dfe:	367d                	addiw	a2,a2,-1
    80000e00:	01005963          	blez	a6,80000e12 <strncpy+0x1e>
    80000e04:	0705                	addi	a4,a4,1
    80000e06:	0005c783          	lbu	a5,0(a1)
    80000e0a:	fef70fa3          	sb	a5,-1(a4)
    80000e0e:	0585                	addi	a1,a1,1
    80000e10:	f7f5                	bnez	a5,80000dfc <strncpy+0x8>
    ;
  while(n-- > 0)
    80000e12:	00c05d63          	blez	a2,80000e2c <strncpy+0x38>
    80000e16:	86ba                	mv	a3,a4
    *s++ = 0;
    80000e18:	0685                	addi	a3,a3,1
    80000e1a:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000e1e:	fff6c793          	not	a5,a3
    80000e22:	9fb9                	addw	a5,a5,a4
    80000e24:	010787bb          	addw	a5,a5,a6
    80000e28:	fef048e3          	bgtz	a5,80000e18 <strncpy+0x24>
  return os;
}
    80000e2c:	6422                	ld	s0,8(sp)
    80000e2e:	0141                	addi	sp,sp,16
    80000e30:	8082                	ret

0000000080000e32 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e32:	1141                	addi	sp,sp,-16
    80000e34:	e422                	sd	s0,8(sp)
    80000e36:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e38:	02c05363          	blez	a2,80000e5e <safestrcpy+0x2c>
    80000e3c:	fff6069b          	addiw	a3,a2,-1
    80000e40:	1682                	slli	a3,a3,0x20
    80000e42:	9281                	srli	a3,a3,0x20
    80000e44:	96ae                	add	a3,a3,a1
    80000e46:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e48:	00d58963          	beq	a1,a3,80000e5a <safestrcpy+0x28>
    80000e4c:	0585                	addi	a1,a1,1
    80000e4e:	0785                	addi	a5,a5,1
    80000e50:	fff5c703          	lbu	a4,-1(a1)
    80000e54:	fee78fa3          	sb	a4,-1(a5)
    80000e58:	fb65                	bnez	a4,80000e48 <safestrcpy+0x16>
    ;
  *s = 0;
    80000e5a:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e5e:	6422                	ld	s0,8(sp)
    80000e60:	0141                	addi	sp,sp,16
    80000e62:	8082                	ret

0000000080000e64 <strlen>:

int
strlen(const char *s)
{
    80000e64:	1141                	addi	sp,sp,-16
    80000e66:	e422                	sd	s0,8(sp)
    80000e68:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000e6a:	00054783          	lbu	a5,0(a0)
    80000e6e:	cf91                	beqz	a5,80000e8a <strlen+0x26>
    80000e70:	0505                	addi	a0,a0,1
    80000e72:	87aa                	mv	a5,a0
    80000e74:	4685                	li	a3,1
    80000e76:	9e89                	subw	a3,a3,a0
    80000e78:	00f6853b          	addw	a0,a3,a5
    80000e7c:	0785                	addi	a5,a5,1
    80000e7e:	fff7c703          	lbu	a4,-1(a5)
    80000e82:	fb7d                	bnez	a4,80000e78 <strlen+0x14>
    ;
  return n;
}
    80000e84:	6422                	ld	s0,8(sp)
    80000e86:	0141                	addi	sp,sp,16
    80000e88:	8082                	ret
  for(n = 0; s[n]; n++)
    80000e8a:	4501                	li	a0,0
    80000e8c:	bfe5                	j	80000e84 <strlen+0x20>

0000000080000e8e <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000e8e:	1141                	addi	sp,sp,-16
    80000e90:	e406                	sd	ra,8(sp)
    80000e92:	e022                	sd	s0,0(sp)
    80000e94:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000e96:	00001097          	auipc	ra,0x1
    80000e9a:	aee080e7          	jalr	-1298(ra) # 80001984 <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000e9e:	00008717          	auipc	a4,0x8
    80000ea2:	17a70713          	addi	a4,a4,378 # 80009018 <started>
  if(cpuid() == 0){
    80000ea6:	c139                	beqz	a0,80000eec <main+0x5e>
    while(started == 0)
    80000ea8:	431c                	lw	a5,0(a4)
    80000eaa:	2781                	sext.w	a5,a5
    80000eac:	dff5                	beqz	a5,80000ea8 <main+0x1a>
      ;
    __sync_synchronize();
    80000eae:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000eb2:	00001097          	auipc	ra,0x1
    80000eb6:	ad2080e7          	jalr	-1326(ra) # 80001984 <cpuid>
    80000eba:	85aa                	mv	a1,a0
    80000ebc:	00007517          	auipc	a0,0x7
    80000ec0:	1fc50513          	addi	a0,a0,508 # 800080b8 <digits+0x78>
    80000ec4:	fffff097          	auipc	ra,0xfffff
    80000ec8:	6c4080e7          	jalr	1732(ra) # 80000588 <printf>
    kvminithart();    // turn on paging
    80000ecc:	00000097          	auipc	ra,0x0
    80000ed0:	0d8080e7          	jalr	216(ra) # 80000fa4 <kvminithart>
    trapinithart();   // install kernel trap vector
    80000ed4:	00001097          	auipc	ra,0x1
    80000ed8:	71a080e7          	jalr	1818(ra) # 800025ee <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000edc:	00005097          	auipc	ra,0x5
    80000ee0:	c74080e7          	jalr	-908(ra) # 80005b50 <plicinithart>
  }

  scheduler();        
    80000ee4:	00001097          	auipc	ra,0x1
    80000ee8:	fc8080e7          	jalr	-56(ra) # 80001eac <scheduler>
    consoleinit();
    80000eec:	fffff097          	auipc	ra,0xfffff
    80000ef0:	564080e7          	jalr	1380(ra) # 80000450 <consoleinit>
    printfinit();
    80000ef4:	00000097          	auipc	ra,0x0
    80000ef8:	87a080e7          	jalr	-1926(ra) # 8000076e <printfinit>
    printf("\n");
    80000efc:	00007517          	auipc	a0,0x7
    80000f00:	1cc50513          	addi	a0,a0,460 # 800080c8 <digits+0x88>
    80000f04:	fffff097          	auipc	ra,0xfffff
    80000f08:	684080e7          	jalr	1668(ra) # 80000588 <printf>
    printf("xv6 kernel is booting\n");
    80000f0c:	00007517          	auipc	a0,0x7
    80000f10:	19450513          	addi	a0,a0,404 # 800080a0 <digits+0x60>
    80000f14:	fffff097          	auipc	ra,0xfffff
    80000f18:	674080e7          	jalr	1652(ra) # 80000588 <printf>
    printf("\n");
    80000f1c:	00007517          	auipc	a0,0x7
    80000f20:	1ac50513          	addi	a0,a0,428 # 800080c8 <digits+0x88>
    80000f24:	fffff097          	auipc	ra,0xfffff
    80000f28:	664080e7          	jalr	1636(ra) # 80000588 <printf>
    kinit();         // physical page allocator
    80000f2c:	00000097          	auipc	ra,0x0
    80000f30:	b8c080e7          	jalr	-1140(ra) # 80000ab8 <kinit>
    kvminit();       // create kernel page table
    80000f34:	00000097          	auipc	ra,0x0
    80000f38:	322080e7          	jalr	802(ra) # 80001256 <kvminit>
    kvminithart();   // turn on paging
    80000f3c:	00000097          	auipc	ra,0x0
    80000f40:	068080e7          	jalr	104(ra) # 80000fa4 <kvminithart>
    procinit();      // process table
    80000f44:	00001097          	auipc	ra,0x1
    80000f48:	990080e7          	jalr	-1648(ra) # 800018d4 <procinit>
    trapinit();      // trap vectors
    80000f4c:	00001097          	auipc	ra,0x1
    80000f50:	67a080e7          	jalr	1658(ra) # 800025c6 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f54:	00001097          	auipc	ra,0x1
    80000f58:	69a080e7          	jalr	1690(ra) # 800025ee <trapinithart>
    plicinit();      // set up interrupt controller
    80000f5c:	00005097          	auipc	ra,0x5
    80000f60:	bde080e7          	jalr	-1058(ra) # 80005b3a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f64:	00005097          	auipc	ra,0x5
    80000f68:	bec080e7          	jalr	-1044(ra) # 80005b50 <plicinithart>
    binit();         // buffer cache
    80000f6c:	00002097          	auipc	ra,0x2
    80000f70:	dc4080e7          	jalr	-572(ra) # 80002d30 <binit>
    iinit();         // inode table
    80000f74:	00002097          	auipc	ra,0x2
    80000f78:	454080e7          	jalr	1108(ra) # 800033c8 <iinit>
    fileinit();      // file table
    80000f7c:	00003097          	auipc	ra,0x3
    80000f80:	3fe080e7          	jalr	1022(ra) # 8000437a <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f84:	00005097          	auipc	ra,0x5
    80000f88:	cee080e7          	jalr	-786(ra) # 80005c72 <virtio_disk_init>
    userinit();      // first user process
    80000f8c:	00001097          	auipc	ra,0x1
    80000f90:	cee080e7          	jalr	-786(ra) # 80001c7a <userinit>
    __sync_synchronize();
    80000f94:	0ff0000f          	fence
    started = 1;
    80000f98:	4785                	li	a5,1
    80000f9a:	00008717          	auipc	a4,0x8
    80000f9e:	06f72f23          	sw	a5,126(a4) # 80009018 <started>
    80000fa2:	b789                	j	80000ee4 <main+0x56>

0000000080000fa4 <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000fa4:	1141                	addi	sp,sp,-16
    80000fa6:	e422                	sd	s0,8(sp)
    80000fa8:	0800                	addi	s0,sp,16
  w_satp(MAKE_SATP(kernel_pagetable));
    80000faa:	00008797          	auipc	a5,0x8
    80000fae:	0767b783          	ld	a5,118(a5) # 80009020 <kernel_pagetable>
    80000fb2:	83b1                	srli	a5,a5,0xc
    80000fb4:	577d                	li	a4,-1
    80000fb6:	177e                	slli	a4,a4,0x3f
    80000fb8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000fba:	18079073          	csrw	satp,a5
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000fbe:	12000073          	sfence.vma
  sfence_vma();
}
    80000fc2:	6422                	ld	s0,8(sp)
    80000fc4:	0141                	addi	sp,sp,16
    80000fc6:	8082                	ret

0000000080000fc8 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000fc8:	7139                	addi	sp,sp,-64
    80000fca:	fc06                	sd	ra,56(sp)
    80000fcc:	f822                	sd	s0,48(sp)
    80000fce:	f426                	sd	s1,40(sp)
    80000fd0:	f04a                	sd	s2,32(sp)
    80000fd2:	ec4e                	sd	s3,24(sp)
    80000fd4:	e852                	sd	s4,16(sp)
    80000fd6:	e456                	sd	s5,8(sp)
    80000fd8:	e05a                	sd	s6,0(sp)
    80000fda:	0080                	addi	s0,sp,64
    80000fdc:	84aa                	mv	s1,a0
    80000fde:	89ae                	mv	s3,a1
    80000fe0:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80000fe2:	57fd                	li	a5,-1
    80000fe4:	83e9                	srli	a5,a5,0x1a
    80000fe6:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80000fe8:	4b31                	li	s6,12
  if(va >= MAXVA)
    80000fea:	04b7f263          	bgeu	a5,a1,8000102e <walk+0x66>
    panic("walk");
    80000fee:	00007517          	auipc	a0,0x7
    80000ff2:	0e250513          	addi	a0,a0,226 # 800080d0 <digits+0x90>
    80000ff6:	fffff097          	auipc	ra,0xfffff
    80000ffa:	548080e7          	jalr	1352(ra) # 8000053e <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80000ffe:	060a8663          	beqz	s5,8000106a <walk+0xa2>
    80001002:	00000097          	auipc	ra,0x0
    80001006:	af2080e7          	jalr	-1294(ra) # 80000af4 <kalloc>
    8000100a:	84aa                	mv	s1,a0
    8000100c:	c529                	beqz	a0,80001056 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    8000100e:	6605                	lui	a2,0x1
    80001010:	4581                	li	a1,0
    80001012:	00000097          	auipc	ra,0x0
    80001016:	cce080e7          	jalr	-818(ra) # 80000ce0 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    8000101a:	00c4d793          	srli	a5,s1,0xc
    8000101e:	07aa                	slli	a5,a5,0xa
    80001020:	0017e793          	ori	a5,a5,1
    80001024:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001028:	3a5d                	addiw	s4,s4,-9
    8000102a:	036a0063          	beq	s4,s6,8000104a <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    8000102e:	0149d933          	srl	s2,s3,s4
    80001032:	1ff97913          	andi	s2,s2,511
    80001036:	090e                	slli	s2,s2,0x3
    80001038:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    8000103a:	00093483          	ld	s1,0(s2)
    8000103e:	0014f793          	andi	a5,s1,1
    80001042:	dfd5                	beqz	a5,80000ffe <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    80001044:	80a9                	srli	s1,s1,0xa
    80001046:	04b2                	slli	s1,s1,0xc
    80001048:	b7c5                	j	80001028 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    8000104a:	00c9d513          	srli	a0,s3,0xc
    8000104e:	1ff57513          	andi	a0,a0,511
    80001052:	050e                	slli	a0,a0,0x3
    80001054:	9526                	add	a0,a0,s1
}
    80001056:	70e2                	ld	ra,56(sp)
    80001058:	7442                	ld	s0,48(sp)
    8000105a:	74a2                	ld	s1,40(sp)
    8000105c:	7902                	ld	s2,32(sp)
    8000105e:	69e2                	ld	s3,24(sp)
    80001060:	6a42                	ld	s4,16(sp)
    80001062:	6aa2                	ld	s5,8(sp)
    80001064:	6b02                	ld	s6,0(sp)
    80001066:	6121                	addi	sp,sp,64
    80001068:	8082                	ret
        return 0;
    8000106a:	4501                	li	a0,0
    8000106c:	b7ed                	j	80001056 <walk+0x8e>

000000008000106e <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    8000106e:	57fd                	li	a5,-1
    80001070:	83e9                	srli	a5,a5,0x1a
    80001072:	00b7f463          	bgeu	a5,a1,8000107a <walkaddr+0xc>
    return 0;
    80001076:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    80001078:	8082                	ret
{
    8000107a:	1141                	addi	sp,sp,-16
    8000107c:	e406                	sd	ra,8(sp)
    8000107e:	e022                	sd	s0,0(sp)
    80001080:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    80001082:	4601                	li	a2,0
    80001084:	00000097          	auipc	ra,0x0
    80001088:	f44080e7          	jalr	-188(ra) # 80000fc8 <walk>
  if(pte == 0)
    8000108c:	c105                	beqz	a0,800010ac <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    8000108e:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    80001090:	0117f693          	andi	a3,a5,17
    80001094:	4745                	li	a4,17
    return 0;
    80001096:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    80001098:	00e68663          	beq	a3,a4,800010a4 <walkaddr+0x36>
}
    8000109c:	60a2                	ld	ra,8(sp)
    8000109e:	6402                	ld	s0,0(sp)
    800010a0:	0141                	addi	sp,sp,16
    800010a2:	8082                	ret
  pa = PTE2PA(*pte);
    800010a4:	00a7d513          	srli	a0,a5,0xa
    800010a8:	0532                	slli	a0,a0,0xc
  return pa;
    800010aa:	bfcd                	j	8000109c <walkaddr+0x2e>
    return 0;
    800010ac:	4501                	li	a0,0
    800010ae:	b7fd                	j	8000109c <walkaddr+0x2e>

00000000800010b0 <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    800010b0:	715d                	addi	sp,sp,-80
    800010b2:	e486                	sd	ra,72(sp)
    800010b4:	e0a2                	sd	s0,64(sp)
    800010b6:	fc26                	sd	s1,56(sp)
    800010b8:	f84a                	sd	s2,48(sp)
    800010ba:	f44e                	sd	s3,40(sp)
    800010bc:	f052                	sd	s4,32(sp)
    800010be:	ec56                	sd	s5,24(sp)
    800010c0:	e85a                	sd	s6,16(sp)
    800010c2:	e45e                	sd	s7,8(sp)
    800010c4:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    800010c6:	c205                	beqz	a2,800010e6 <mappages+0x36>
    800010c8:	8aaa                	mv	s5,a0
    800010ca:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    800010cc:	77fd                	lui	a5,0xfffff
    800010ce:	00f5fa33          	and	s4,a1,a5
  last = PGROUNDDOWN(va + size - 1);
    800010d2:	15fd                	addi	a1,a1,-1
    800010d4:	00c589b3          	add	s3,a1,a2
    800010d8:	00f9f9b3          	and	s3,s3,a5
  a = PGROUNDDOWN(va);
    800010dc:	8952                	mv	s2,s4
    800010de:	41468a33          	sub	s4,a3,s4
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800010e2:	6b85                	lui	s7,0x1
    800010e4:	a015                	j	80001108 <mappages+0x58>
    panic("mappages: size");
    800010e6:	00007517          	auipc	a0,0x7
    800010ea:	ff250513          	addi	a0,a0,-14 # 800080d8 <digits+0x98>
    800010ee:	fffff097          	auipc	ra,0xfffff
    800010f2:	450080e7          	jalr	1104(ra) # 8000053e <panic>
      panic("mappages: remap");
    800010f6:	00007517          	auipc	a0,0x7
    800010fa:	ff250513          	addi	a0,a0,-14 # 800080e8 <digits+0xa8>
    800010fe:	fffff097          	auipc	ra,0xfffff
    80001102:	440080e7          	jalr	1088(ra) # 8000053e <panic>
    a += PGSIZE;
    80001106:	995e                	add	s2,s2,s7
  for(;;){
    80001108:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    8000110c:	4605                	li	a2,1
    8000110e:	85ca                	mv	a1,s2
    80001110:	8556                	mv	a0,s5
    80001112:	00000097          	auipc	ra,0x0
    80001116:	eb6080e7          	jalr	-330(ra) # 80000fc8 <walk>
    8000111a:	cd19                	beqz	a0,80001138 <mappages+0x88>
    if(*pte & PTE_V)
    8000111c:	611c                	ld	a5,0(a0)
    8000111e:	8b85                	andi	a5,a5,1
    80001120:	fbf9                	bnez	a5,800010f6 <mappages+0x46>
    *pte = PA2PTE(pa) | perm | PTE_V;
    80001122:	80b1                	srli	s1,s1,0xc
    80001124:	04aa                	slli	s1,s1,0xa
    80001126:	0164e4b3          	or	s1,s1,s6
    8000112a:	0014e493          	ori	s1,s1,1
    8000112e:	e104                	sd	s1,0(a0)
    if(a == last)
    80001130:	fd391be3          	bne	s2,s3,80001106 <mappages+0x56>
    pa += PGSIZE;
  }
  return 0;
    80001134:	4501                	li	a0,0
    80001136:	a011                	j	8000113a <mappages+0x8a>
      return -1;
    80001138:	557d                	li	a0,-1
}
    8000113a:	60a6                	ld	ra,72(sp)
    8000113c:	6406                	ld	s0,64(sp)
    8000113e:	74e2                	ld	s1,56(sp)
    80001140:	7942                	ld	s2,48(sp)
    80001142:	79a2                	ld	s3,40(sp)
    80001144:	7a02                	ld	s4,32(sp)
    80001146:	6ae2                	ld	s5,24(sp)
    80001148:	6b42                	ld	s6,16(sp)
    8000114a:	6ba2                	ld	s7,8(sp)
    8000114c:	6161                	addi	sp,sp,80
    8000114e:	8082                	ret

0000000080001150 <kvmmap>:
{
    80001150:	1141                	addi	sp,sp,-16
    80001152:	e406                	sd	ra,8(sp)
    80001154:	e022                	sd	s0,0(sp)
    80001156:	0800                	addi	s0,sp,16
    80001158:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    8000115a:	86b2                	mv	a3,a2
    8000115c:	863e                	mv	a2,a5
    8000115e:	00000097          	auipc	ra,0x0
    80001162:	f52080e7          	jalr	-174(ra) # 800010b0 <mappages>
    80001166:	e509                	bnez	a0,80001170 <kvmmap+0x20>
}
    80001168:	60a2                	ld	ra,8(sp)
    8000116a:	6402                	ld	s0,0(sp)
    8000116c:	0141                	addi	sp,sp,16
    8000116e:	8082                	ret
    panic("kvmmap");
    80001170:	00007517          	auipc	a0,0x7
    80001174:	f8850513          	addi	a0,a0,-120 # 800080f8 <digits+0xb8>
    80001178:	fffff097          	auipc	ra,0xfffff
    8000117c:	3c6080e7          	jalr	966(ra) # 8000053e <panic>

0000000080001180 <kvmmake>:
{
    80001180:	1101                	addi	sp,sp,-32
    80001182:	ec06                	sd	ra,24(sp)
    80001184:	e822                	sd	s0,16(sp)
    80001186:	e426                	sd	s1,8(sp)
    80001188:	e04a                	sd	s2,0(sp)
    8000118a:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    8000118c:	00000097          	auipc	ra,0x0
    80001190:	968080e7          	jalr	-1688(ra) # 80000af4 <kalloc>
    80001194:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    80001196:	6605                	lui	a2,0x1
    80001198:	4581                	li	a1,0
    8000119a:	00000097          	auipc	ra,0x0
    8000119e:	b46080e7          	jalr	-1210(ra) # 80000ce0 <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    800011a2:	4719                	li	a4,6
    800011a4:	6685                	lui	a3,0x1
    800011a6:	10000637          	lui	a2,0x10000
    800011aa:	100005b7          	lui	a1,0x10000
    800011ae:	8526                	mv	a0,s1
    800011b0:	00000097          	auipc	ra,0x0
    800011b4:	fa0080e7          	jalr	-96(ra) # 80001150 <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    800011b8:	4719                	li	a4,6
    800011ba:	6685                	lui	a3,0x1
    800011bc:	10001637          	lui	a2,0x10001
    800011c0:	100015b7          	lui	a1,0x10001
    800011c4:	8526                	mv	a0,s1
    800011c6:	00000097          	auipc	ra,0x0
    800011ca:	f8a080e7          	jalr	-118(ra) # 80001150 <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800011ce:	4719                	li	a4,6
    800011d0:	004006b7          	lui	a3,0x400
    800011d4:	0c000637          	lui	a2,0xc000
    800011d8:	0c0005b7          	lui	a1,0xc000
    800011dc:	8526                	mv	a0,s1
    800011de:	00000097          	auipc	ra,0x0
    800011e2:	f72080e7          	jalr	-142(ra) # 80001150 <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800011e6:	00007917          	auipc	s2,0x7
    800011ea:	e1a90913          	addi	s2,s2,-486 # 80008000 <etext>
    800011ee:	4729                	li	a4,10
    800011f0:	80007697          	auipc	a3,0x80007
    800011f4:	e1068693          	addi	a3,a3,-496 # 8000 <_entry-0x7fff8000>
    800011f8:	4605                	li	a2,1
    800011fa:	067e                	slli	a2,a2,0x1f
    800011fc:	85b2                	mv	a1,a2
    800011fe:	8526                	mv	a0,s1
    80001200:	00000097          	auipc	ra,0x0
    80001204:	f50080e7          	jalr	-176(ra) # 80001150 <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    80001208:	4719                	li	a4,6
    8000120a:	46c5                	li	a3,17
    8000120c:	06ee                	slli	a3,a3,0x1b
    8000120e:	412686b3          	sub	a3,a3,s2
    80001212:	864a                	mv	a2,s2
    80001214:	85ca                	mv	a1,s2
    80001216:	8526                	mv	a0,s1
    80001218:	00000097          	auipc	ra,0x0
    8000121c:	f38080e7          	jalr	-200(ra) # 80001150 <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    80001220:	4729                	li	a4,10
    80001222:	6685                	lui	a3,0x1
    80001224:	00006617          	auipc	a2,0x6
    80001228:	ddc60613          	addi	a2,a2,-548 # 80007000 <_trampoline>
    8000122c:	040005b7          	lui	a1,0x4000
    80001230:	15fd                	addi	a1,a1,-1
    80001232:	05b2                	slli	a1,a1,0xc
    80001234:	8526                	mv	a0,s1
    80001236:	00000097          	auipc	ra,0x0
    8000123a:	f1a080e7          	jalr	-230(ra) # 80001150 <kvmmap>
  proc_mapstacks(kpgtbl);
    8000123e:	8526                	mv	a0,s1
    80001240:	00000097          	auipc	ra,0x0
    80001244:	5fe080e7          	jalr	1534(ra) # 8000183e <proc_mapstacks>
}
    80001248:	8526                	mv	a0,s1
    8000124a:	60e2                	ld	ra,24(sp)
    8000124c:	6442                	ld	s0,16(sp)
    8000124e:	64a2                	ld	s1,8(sp)
    80001250:	6902                	ld	s2,0(sp)
    80001252:	6105                	addi	sp,sp,32
    80001254:	8082                	ret

0000000080001256 <kvminit>:
{
    80001256:	1141                	addi	sp,sp,-16
    80001258:	e406                	sd	ra,8(sp)
    8000125a:	e022                	sd	s0,0(sp)
    8000125c:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    8000125e:	00000097          	auipc	ra,0x0
    80001262:	f22080e7          	jalr	-222(ra) # 80001180 <kvmmake>
    80001266:	00008797          	auipc	a5,0x8
    8000126a:	daa7bd23          	sd	a0,-582(a5) # 80009020 <kernel_pagetable>
}
    8000126e:	60a2                	ld	ra,8(sp)
    80001270:	6402                	ld	s0,0(sp)
    80001272:	0141                	addi	sp,sp,16
    80001274:	8082                	ret

0000000080001276 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    80001276:	715d                	addi	sp,sp,-80
    80001278:	e486                	sd	ra,72(sp)
    8000127a:	e0a2                	sd	s0,64(sp)
    8000127c:	fc26                	sd	s1,56(sp)
    8000127e:	f84a                	sd	s2,48(sp)
    80001280:	f44e                	sd	s3,40(sp)
    80001282:	f052                	sd	s4,32(sp)
    80001284:	ec56                	sd	s5,24(sp)
    80001286:	e85a                	sd	s6,16(sp)
    80001288:	e45e                	sd	s7,8(sp)
    8000128a:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    8000128c:	03459793          	slli	a5,a1,0x34
    80001290:	e795                	bnez	a5,800012bc <uvmunmap+0x46>
    80001292:	8a2a                	mv	s4,a0
    80001294:	892e                	mv	s2,a1
    80001296:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001298:	0632                	slli	a2,a2,0xc
    8000129a:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    8000129e:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012a0:	6b05                	lui	s6,0x1
    800012a2:	0735e863          	bltu	a1,s3,80001312 <uvmunmap+0x9c>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    800012a6:	60a6                	ld	ra,72(sp)
    800012a8:	6406                	ld	s0,64(sp)
    800012aa:	74e2                	ld	s1,56(sp)
    800012ac:	7942                	ld	s2,48(sp)
    800012ae:	79a2                	ld	s3,40(sp)
    800012b0:	7a02                	ld	s4,32(sp)
    800012b2:	6ae2                	ld	s5,24(sp)
    800012b4:	6b42                	ld	s6,16(sp)
    800012b6:	6ba2                	ld	s7,8(sp)
    800012b8:	6161                	addi	sp,sp,80
    800012ba:	8082                	ret
    panic("uvmunmap: not aligned");
    800012bc:	00007517          	auipc	a0,0x7
    800012c0:	e4450513          	addi	a0,a0,-444 # 80008100 <digits+0xc0>
    800012c4:	fffff097          	auipc	ra,0xfffff
    800012c8:	27a080e7          	jalr	634(ra) # 8000053e <panic>
      panic("uvmunmap: walk");
    800012cc:	00007517          	auipc	a0,0x7
    800012d0:	e4c50513          	addi	a0,a0,-436 # 80008118 <digits+0xd8>
    800012d4:	fffff097          	auipc	ra,0xfffff
    800012d8:	26a080e7          	jalr	618(ra) # 8000053e <panic>
      panic("uvmunmap: not mapped");
    800012dc:	00007517          	auipc	a0,0x7
    800012e0:	e4c50513          	addi	a0,a0,-436 # 80008128 <digits+0xe8>
    800012e4:	fffff097          	auipc	ra,0xfffff
    800012e8:	25a080e7          	jalr	602(ra) # 8000053e <panic>
      panic("uvmunmap: not a leaf");
    800012ec:	00007517          	auipc	a0,0x7
    800012f0:	e5450513          	addi	a0,a0,-428 # 80008140 <digits+0x100>
    800012f4:	fffff097          	auipc	ra,0xfffff
    800012f8:	24a080e7          	jalr	586(ra) # 8000053e <panic>
      uint64 pa = PTE2PA(*pte);
    800012fc:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    800012fe:	0532                	slli	a0,a0,0xc
    80001300:	fffff097          	auipc	ra,0xfffff
    80001304:	6f8080e7          	jalr	1784(ra) # 800009f8 <kfree>
    *pte = 0;
    80001308:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000130c:	995a                	add	s2,s2,s6
    8000130e:	f9397ce3          	bgeu	s2,s3,800012a6 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    80001312:	4601                	li	a2,0
    80001314:	85ca                	mv	a1,s2
    80001316:	8552                	mv	a0,s4
    80001318:	00000097          	auipc	ra,0x0
    8000131c:	cb0080e7          	jalr	-848(ra) # 80000fc8 <walk>
    80001320:	84aa                	mv	s1,a0
    80001322:	d54d                	beqz	a0,800012cc <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    80001324:	6108                	ld	a0,0(a0)
    80001326:	00157793          	andi	a5,a0,1
    8000132a:	dbcd                	beqz	a5,800012dc <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    8000132c:	3ff57793          	andi	a5,a0,1023
    80001330:	fb778ee3          	beq	a5,s7,800012ec <uvmunmap+0x76>
    if(do_free){
    80001334:	fc0a8ae3          	beqz	s5,80001308 <uvmunmap+0x92>
    80001338:	b7d1                	j	800012fc <uvmunmap+0x86>

000000008000133a <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    8000133a:	1101                	addi	sp,sp,-32
    8000133c:	ec06                	sd	ra,24(sp)
    8000133e:	e822                	sd	s0,16(sp)
    80001340:	e426                	sd	s1,8(sp)
    80001342:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    80001344:	fffff097          	auipc	ra,0xfffff
    80001348:	7b0080e7          	jalr	1968(ra) # 80000af4 <kalloc>
    8000134c:	84aa                	mv	s1,a0
  if(pagetable == 0)
    8000134e:	c519                	beqz	a0,8000135c <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    80001350:	6605                	lui	a2,0x1
    80001352:	4581                	li	a1,0
    80001354:	00000097          	auipc	ra,0x0
    80001358:	98c080e7          	jalr	-1652(ra) # 80000ce0 <memset>
  return pagetable;
}
    8000135c:	8526                	mv	a0,s1
    8000135e:	60e2                	ld	ra,24(sp)
    80001360:	6442                	ld	s0,16(sp)
    80001362:	64a2                	ld	s1,8(sp)
    80001364:	6105                	addi	sp,sp,32
    80001366:	8082                	ret

0000000080001368 <uvminit>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
    80001368:	7179                	addi	sp,sp,-48
    8000136a:	f406                	sd	ra,40(sp)
    8000136c:	f022                	sd	s0,32(sp)
    8000136e:	ec26                	sd	s1,24(sp)
    80001370:	e84a                	sd	s2,16(sp)
    80001372:	e44e                	sd	s3,8(sp)
    80001374:	e052                	sd	s4,0(sp)
    80001376:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    80001378:	6785                	lui	a5,0x1
    8000137a:	04f67863          	bgeu	a2,a5,800013ca <uvminit+0x62>
    8000137e:	8a2a                	mv	s4,a0
    80001380:	89ae                	mv	s3,a1
    80001382:	84b2                	mv	s1,a2
    panic("inituvm: more than a page");
  mem = kalloc();
    80001384:	fffff097          	auipc	ra,0xfffff
    80001388:	770080e7          	jalr	1904(ra) # 80000af4 <kalloc>
    8000138c:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    8000138e:	6605                	lui	a2,0x1
    80001390:	4581                	li	a1,0
    80001392:	00000097          	auipc	ra,0x0
    80001396:	94e080e7          	jalr	-1714(ra) # 80000ce0 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    8000139a:	4779                	li	a4,30
    8000139c:	86ca                	mv	a3,s2
    8000139e:	6605                	lui	a2,0x1
    800013a0:	4581                	li	a1,0
    800013a2:	8552                	mv	a0,s4
    800013a4:	00000097          	auipc	ra,0x0
    800013a8:	d0c080e7          	jalr	-756(ra) # 800010b0 <mappages>
  memmove(mem, src, sz);
    800013ac:	8626                	mv	a2,s1
    800013ae:	85ce                	mv	a1,s3
    800013b0:	854a                	mv	a0,s2
    800013b2:	00000097          	auipc	ra,0x0
    800013b6:	98e080e7          	jalr	-1650(ra) # 80000d40 <memmove>
}
    800013ba:	70a2                	ld	ra,40(sp)
    800013bc:	7402                	ld	s0,32(sp)
    800013be:	64e2                	ld	s1,24(sp)
    800013c0:	6942                	ld	s2,16(sp)
    800013c2:	69a2                	ld	s3,8(sp)
    800013c4:	6a02                	ld	s4,0(sp)
    800013c6:	6145                	addi	sp,sp,48
    800013c8:	8082                	ret
    panic("inituvm: more than a page");
    800013ca:	00007517          	auipc	a0,0x7
    800013ce:	d8e50513          	addi	a0,a0,-626 # 80008158 <digits+0x118>
    800013d2:	fffff097          	auipc	ra,0xfffff
    800013d6:	16c080e7          	jalr	364(ra) # 8000053e <panic>

00000000800013da <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800013da:	1101                	addi	sp,sp,-32
    800013dc:	ec06                	sd	ra,24(sp)
    800013de:	e822                	sd	s0,16(sp)
    800013e0:	e426                	sd	s1,8(sp)
    800013e2:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    800013e4:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800013e6:	00b67d63          	bgeu	a2,a1,80001400 <uvmdealloc+0x26>
    800013ea:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800013ec:	6785                	lui	a5,0x1
    800013ee:	17fd                	addi	a5,a5,-1
    800013f0:	00f60733          	add	a4,a2,a5
    800013f4:	767d                	lui	a2,0xfffff
    800013f6:	8f71                	and	a4,a4,a2
    800013f8:	97ae                	add	a5,a5,a1
    800013fa:	8ff1                	and	a5,a5,a2
    800013fc:	00f76863          	bltu	a4,a5,8000140c <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    80001400:	8526                	mv	a0,s1
    80001402:	60e2                	ld	ra,24(sp)
    80001404:	6442                	ld	s0,16(sp)
    80001406:	64a2                	ld	s1,8(sp)
    80001408:	6105                	addi	sp,sp,32
    8000140a:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    8000140c:	8f99                	sub	a5,a5,a4
    8000140e:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    80001410:	4685                	li	a3,1
    80001412:	0007861b          	sext.w	a2,a5
    80001416:	85ba                	mv	a1,a4
    80001418:	00000097          	auipc	ra,0x0
    8000141c:	e5e080e7          	jalr	-418(ra) # 80001276 <uvmunmap>
    80001420:	b7c5                	j	80001400 <uvmdealloc+0x26>

0000000080001422 <uvmalloc>:
  if(newsz < oldsz)
    80001422:	0ab66163          	bltu	a2,a1,800014c4 <uvmalloc+0xa2>
{
    80001426:	7139                	addi	sp,sp,-64
    80001428:	fc06                	sd	ra,56(sp)
    8000142a:	f822                	sd	s0,48(sp)
    8000142c:	f426                	sd	s1,40(sp)
    8000142e:	f04a                	sd	s2,32(sp)
    80001430:	ec4e                	sd	s3,24(sp)
    80001432:	e852                	sd	s4,16(sp)
    80001434:	e456                	sd	s5,8(sp)
    80001436:	0080                	addi	s0,sp,64
    80001438:	8aaa                	mv	s5,a0
    8000143a:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    8000143c:	6985                	lui	s3,0x1
    8000143e:	19fd                	addi	s3,s3,-1
    80001440:	95ce                	add	a1,a1,s3
    80001442:	79fd                	lui	s3,0xfffff
    80001444:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001448:	08c9f063          	bgeu	s3,a2,800014c8 <uvmalloc+0xa6>
    8000144c:	894e                	mv	s2,s3
    mem = kalloc();
    8000144e:	fffff097          	auipc	ra,0xfffff
    80001452:	6a6080e7          	jalr	1702(ra) # 80000af4 <kalloc>
    80001456:	84aa                	mv	s1,a0
    if(mem == 0){
    80001458:	c51d                	beqz	a0,80001486 <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    8000145a:	6605                	lui	a2,0x1
    8000145c:	4581                	li	a1,0
    8000145e:	00000097          	auipc	ra,0x0
    80001462:	882080e7          	jalr	-1918(ra) # 80000ce0 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    80001466:	4779                	li	a4,30
    80001468:	86a6                	mv	a3,s1
    8000146a:	6605                	lui	a2,0x1
    8000146c:	85ca                	mv	a1,s2
    8000146e:	8556                	mv	a0,s5
    80001470:	00000097          	auipc	ra,0x0
    80001474:	c40080e7          	jalr	-960(ra) # 800010b0 <mappages>
    80001478:	e905                	bnez	a0,800014a8 <uvmalloc+0x86>
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000147a:	6785                	lui	a5,0x1
    8000147c:	993e                	add	s2,s2,a5
    8000147e:	fd4968e3          	bltu	s2,s4,8000144e <uvmalloc+0x2c>
  return newsz;
    80001482:	8552                	mv	a0,s4
    80001484:	a809                	j	80001496 <uvmalloc+0x74>
      uvmdealloc(pagetable, a, oldsz);
    80001486:	864e                	mv	a2,s3
    80001488:	85ca                	mv	a1,s2
    8000148a:	8556                	mv	a0,s5
    8000148c:	00000097          	auipc	ra,0x0
    80001490:	f4e080e7          	jalr	-178(ra) # 800013da <uvmdealloc>
      return 0;
    80001494:	4501                	li	a0,0
}
    80001496:	70e2                	ld	ra,56(sp)
    80001498:	7442                	ld	s0,48(sp)
    8000149a:	74a2                	ld	s1,40(sp)
    8000149c:	7902                	ld	s2,32(sp)
    8000149e:	69e2                	ld	s3,24(sp)
    800014a0:	6a42                	ld	s4,16(sp)
    800014a2:	6aa2                	ld	s5,8(sp)
    800014a4:	6121                	addi	sp,sp,64
    800014a6:	8082                	ret
      kfree(mem);
    800014a8:	8526                	mv	a0,s1
    800014aa:	fffff097          	auipc	ra,0xfffff
    800014ae:	54e080e7          	jalr	1358(ra) # 800009f8 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    800014b2:	864e                	mv	a2,s3
    800014b4:	85ca                	mv	a1,s2
    800014b6:	8556                	mv	a0,s5
    800014b8:	00000097          	auipc	ra,0x0
    800014bc:	f22080e7          	jalr	-222(ra) # 800013da <uvmdealloc>
      return 0;
    800014c0:	4501                	li	a0,0
    800014c2:	bfd1                	j	80001496 <uvmalloc+0x74>
    return oldsz;
    800014c4:	852e                	mv	a0,a1
}
    800014c6:	8082                	ret
  return newsz;
    800014c8:	8532                	mv	a0,a2
    800014ca:	b7f1                	j	80001496 <uvmalloc+0x74>

00000000800014cc <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800014cc:	7179                	addi	sp,sp,-48
    800014ce:	f406                	sd	ra,40(sp)
    800014d0:	f022                	sd	s0,32(sp)
    800014d2:	ec26                	sd	s1,24(sp)
    800014d4:	e84a                	sd	s2,16(sp)
    800014d6:	e44e                	sd	s3,8(sp)
    800014d8:	e052                	sd	s4,0(sp)
    800014da:	1800                	addi	s0,sp,48
    800014dc:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800014de:	84aa                	mv	s1,a0
    800014e0:	6905                	lui	s2,0x1
    800014e2:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014e4:	4985                	li	s3,1
    800014e6:	a821                	j	800014fe <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800014e8:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    800014ea:	0532                	slli	a0,a0,0xc
    800014ec:	00000097          	auipc	ra,0x0
    800014f0:	fe0080e7          	jalr	-32(ra) # 800014cc <freewalk>
      pagetable[i] = 0;
    800014f4:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    800014f8:	04a1                	addi	s1,s1,8
    800014fa:	03248163          	beq	s1,s2,8000151c <freewalk+0x50>
    pte_t pte = pagetable[i];
    800014fe:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001500:	00f57793          	andi	a5,a0,15
    80001504:	ff3782e3          	beq	a5,s3,800014e8 <freewalk+0x1c>
    } else if(pte & PTE_V){
    80001508:	8905                	andi	a0,a0,1
    8000150a:	d57d                	beqz	a0,800014f8 <freewalk+0x2c>
      panic("freewalk: leaf");
    8000150c:	00007517          	auipc	a0,0x7
    80001510:	c6c50513          	addi	a0,a0,-916 # 80008178 <digits+0x138>
    80001514:	fffff097          	auipc	ra,0xfffff
    80001518:	02a080e7          	jalr	42(ra) # 8000053e <panic>
    }
  }
  kfree((void*)pagetable);
    8000151c:	8552                	mv	a0,s4
    8000151e:	fffff097          	auipc	ra,0xfffff
    80001522:	4da080e7          	jalr	1242(ra) # 800009f8 <kfree>
}
    80001526:	70a2                	ld	ra,40(sp)
    80001528:	7402                	ld	s0,32(sp)
    8000152a:	64e2                	ld	s1,24(sp)
    8000152c:	6942                	ld	s2,16(sp)
    8000152e:	69a2                	ld	s3,8(sp)
    80001530:	6a02                	ld	s4,0(sp)
    80001532:	6145                	addi	sp,sp,48
    80001534:	8082                	ret

0000000080001536 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    80001536:	1101                	addi	sp,sp,-32
    80001538:	ec06                	sd	ra,24(sp)
    8000153a:	e822                	sd	s0,16(sp)
    8000153c:	e426                	sd	s1,8(sp)
    8000153e:	1000                	addi	s0,sp,32
    80001540:	84aa                	mv	s1,a0
  if(sz > 0)
    80001542:	e999                	bnez	a1,80001558 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    80001544:	8526                	mv	a0,s1
    80001546:	00000097          	auipc	ra,0x0
    8000154a:	f86080e7          	jalr	-122(ra) # 800014cc <freewalk>
}
    8000154e:	60e2                	ld	ra,24(sp)
    80001550:	6442                	ld	s0,16(sp)
    80001552:	64a2                	ld	s1,8(sp)
    80001554:	6105                	addi	sp,sp,32
    80001556:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    80001558:	6605                	lui	a2,0x1
    8000155a:	167d                	addi	a2,a2,-1
    8000155c:	962e                	add	a2,a2,a1
    8000155e:	4685                	li	a3,1
    80001560:	8231                	srli	a2,a2,0xc
    80001562:	4581                	li	a1,0
    80001564:	00000097          	auipc	ra,0x0
    80001568:	d12080e7          	jalr	-750(ra) # 80001276 <uvmunmap>
    8000156c:	bfe1                	j	80001544 <uvmfree+0xe>

000000008000156e <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    8000156e:	c679                	beqz	a2,8000163c <uvmcopy+0xce>
{
    80001570:	715d                	addi	sp,sp,-80
    80001572:	e486                	sd	ra,72(sp)
    80001574:	e0a2                	sd	s0,64(sp)
    80001576:	fc26                	sd	s1,56(sp)
    80001578:	f84a                	sd	s2,48(sp)
    8000157a:	f44e                	sd	s3,40(sp)
    8000157c:	f052                	sd	s4,32(sp)
    8000157e:	ec56                	sd	s5,24(sp)
    80001580:	e85a                	sd	s6,16(sp)
    80001582:	e45e                	sd	s7,8(sp)
    80001584:	0880                	addi	s0,sp,80
    80001586:	8b2a                	mv	s6,a0
    80001588:	8aae                	mv	s5,a1
    8000158a:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    8000158c:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    8000158e:	4601                	li	a2,0
    80001590:	85ce                	mv	a1,s3
    80001592:	855a                	mv	a0,s6
    80001594:	00000097          	auipc	ra,0x0
    80001598:	a34080e7          	jalr	-1484(ra) # 80000fc8 <walk>
    8000159c:	c531                	beqz	a0,800015e8 <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    8000159e:	6118                	ld	a4,0(a0)
    800015a0:	00177793          	andi	a5,a4,1
    800015a4:	cbb1                	beqz	a5,800015f8 <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    800015a6:	00a75593          	srli	a1,a4,0xa
    800015aa:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    800015ae:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    800015b2:	fffff097          	auipc	ra,0xfffff
    800015b6:	542080e7          	jalr	1346(ra) # 80000af4 <kalloc>
    800015ba:	892a                	mv	s2,a0
    800015bc:	c939                	beqz	a0,80001612 <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    800015be:	6605                	lui	a2,0x1
    800015c0:	85de                	mv	a1,s7
    800015c2:	fffff097          	auipc	ra,0xfffff
    800015c6:	77e080e7          	jalr	1918(ra) # 80000d40 <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    800015ca:	8726                	mv	a4,s1
    800015cc:	86ca                	mv	a3,s2
    800015ce:	6605                	lui	a2,0x1
    800015d0:	85ce                	mv	a1,s3
    800015d2:	8556                	mv	a0,s5
    800015d4:	00000097          	auipc	ra,0x0
    800015d8:	adc080e7          	jalr	-1316(ra) # 800010b0 <mappages>
    800015dc:	e515                	bnez	a0,80001608 <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    800015de:	6785                	lui	a5,0x1
    800015e0:	99be                	add	s3,s3,a5
    800015e2:	fb49e6e3          	bltu	s3,s4,8000158e <uvmcopy+0x20>
    800015e6:	a081                	j	80001626 <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    800015e8:	00007517          	auipc	a0,0x7
    800015ec:	ba050513          	addi	a0,a0,-1120 # 80008188 <digits+0x148>
    800015f0:	fffff097          	auipc	ra,0xfffff
    800015f4:	f4e080e7          	jalr	-178(ra) # 8000053e <panic>
      panic("uvmcopy: page not present");
    800015f8:	00007517          	auipc	a0,0x7
    800015fc:	bb050513          	addi	a0,a0,-1104 # 800081a8 <digits+0x168>
    80001600:	fffff097          	auipc	ra,0xfffff
    80001604:	f3e080e7          	jalr	-194(ra) # 8000053e <panic>
      kfree(mem);
    80001608:	854a                	mv	a0,s2
    8000160a:	fffff097          	auipc	ra,0xfffff
    8000160e:	3ee080e7          	jalr	1006(ra) # 800009f8 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    80001612:	4685                	li	a3,1
    80001614:	00c9d613          	srli	a2,s3,0xc
    80001618:	4581                	li	a1,0
    8000161a:	8556                	mv	a0,s5
    8000161c:	00000097          	auipc	ra,0x0
    80001620:	c5a080e7          	jalr	-934(ra) # 80001276 <uvmunmap>
  return -1;
    80001624:	557d                	li	a0,-1
}
    80001626:	60a6                	ld	ra,72(sp)
    80001628:	6406                	ld	s0,64(sp)
    8000162a:	74e2                	ld	s1,56(sp)
    8000162c:	7942                	ld	s2,48(sp)
    8000162e:	79a2                	ld	s3,40(sp)
    80001630:	7a02                	ld	s4,32(sp)
    80001632:	6ae2                	ld	s5,24(sp)
    80001634:	6b42                	ld	s6,16(sp)
    80001636:	6ba2                	ld	s7,8(sp)
    80001638:	6161                	addi	sp,sp,80
    8000163a:	8082                	ret
  return 0;
    8000163c:	4501                	li	a0,0
}
    8000163e:	8082                	ret

0000000080001640 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    80001640:	1141                	addi	sp,sp,-16
    80001642:	e406                	sd	ra,8(sp)
    80001644:	e022                	sd	s0,0(sp)
    80001646:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    80001648:	4601                	li	a2,0
    8000164a:	00000097          	auipc	ra,0x0
    8000164e:	97e080e7          	jalr	-1666(ra) # 80000fc8 <walk>
  if(pte == 0)
    80001652:	c901                	beqz	a0,80001662 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    80001654:	611c                	ld	a5,0(a0)
    80001656:	9bbd                	andi	a5,a5,-17
    80001658:	e11c                	sd	a5,0(a0)
}
    8000165a:	60a2                	ld	ra,8(sp)
    8000165c:	6402                	ld	s0,0(sp)
    8000165e:	0141                	addi	sp,sp,16
    80001660:	8082                	ret
    panic("uvmclear");
    80001662:	00007517          	auipc	a0,0x7
    80001666:	b6650513          	addi	a0,a0,-1178 # 800081c8 <digits+0x188>
    8000166a:	fffff097          	auipc	ra,0xfffff
    8000166e:	ed4080e7          	jalr	-300(ra) # 8000053e <panic>

0000000080001672 <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001672:	c6bd                	beqz	a3,800016e0 <copyout+0x6e>
{
    80001674:	715d                	addi	sp,sp,-80
    80001676:	e486                	sd	ra,72(sp)
    80001678:	e0a2                	sd	s0,64(sp)
    8000167a:	fc26                	sd	s1,56(sp)
    8000167c:	f84a                	sd	s2,48(sp)
    8000167e:	f44e                	sd	s3,40(sp)
    80001680:	f052                	sd	s4,32(sp)
    80001682:	ec56                	sd	s5,24(sp)
    80001684:	e85a                	sd	s6,16(sp)
    80001686:	e45e                	sd	s7,8(sp)
    80001688:	e062                	sd	s8,0(sp)
    8000168a:	0880                	addi	s0,sp,80
    8000168c:	8b2a                	mv	s6,a0
    8000168e:	8c2e                	mv	s8,a1
    80001690:	8a32                	mv	s4,a2
    80001692:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    80001694:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    80001696:	6a85                	lui	s5,0x1
    80001698:	a015                	j	800016bc <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    8000169a:	9562                	add	a0,a0,s8
    8000169c:	0004861b          	sext.w	a2,s1
    800016a0:	85d2                	mv	a1,s4
    800016a2:	41250533          	sub	a0,a0,s2
    800016a6:	fffff097          	auipc	ra,0xfffff
    800016aa:	69a080e7          	jalr	1690(ra) # 80000d40 <memmove>

    len -= n;
    800016ae:	409989b3          	sub	s3,s3,s1
    src += n;
    800016b2:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    800016b4:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800016b8:	02098263          	beqz	s3,800016dc <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    800016bc:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800016c0:	85ca                	mv	a1,s2
    800016c2:	855a                	mv	a0,s6
    800016c4:	00000097          	auipc	ra,0x0
    800016c8:	9aa080e7          	jalr	-1622(ra) # 8000106e <walkaddr>
    if(pa0 == 0)
    800016cc:	cd01                	beqz	a0,800016e4 <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    800016ce:	418904b3          	sub	s1,s2,s8
    800016d2:	94d6                	add	s1,s1,s5
    if(n > len)
    800016d4:	fc99f3e3          	bgeu	s3,s1,8000169a <copyout+0x28>
    800016d8:	84ce                	mv	s1,s3
    800016da:	b7c1                	j	8000169a <copyout+0x28>
  }
  return 0;
    800016dc:	4501                	li	a0,0
    800016de:	a021                	j	800016e6 <copyout+0x74>
    800016e0:	4501                	li	a0,0
}
    800016e2:	8082                	ret
      return -1;
    800016e4:	557d                	li	a0,-1
}
    800016e6:	60a6                	ld	ra,72(sp)
    800016e8:	6406                	ld	s0,64(sp)
    800016ea:	74e2                	ld	s1,56(sp)
    800016ec:	7942                	ld	s2,48(sp)
    800016ee:	79a2                	ld	s3,40(sp)
    800016f0:	7a02                	ld	s4,32(sp)
    800016f2:	6ae2                	ld	s5,24(sp)
    800016f4:	6b42                	ld	s6,16(sp)
    800016f6:	6ba2                	ld	s7,8(sp)
    800016f8:	6c02                	ld	s8,0(sp)
    800016fa:	6161                	addi	sp,sp,80
    800016fc:	8082                	ret

00000000800016fe <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800016fe:	c6bd                	beqz	a3,8000176c <copyin+0x6e>
{
    80001700:	715d                	addi	sp,sp,-80
    80001702:	e486                	sd	ra,72(sp)
    80001704:	e0a2                	sd	s0,64(sp)
    80001706:	fc26                	sd	s1,56(sp)
    80001708:	f84a                	sd	s2,48(sp)
    8000170a:	f44e                	sd	s3,40(sp)
    8000170c:	f052                	sd	s4,32(sp)
    8000170e:	ec56                	sd	s5,24(sp)
    80001710:	e85a                	sd	s6,16(sp)
    80001712:	e45e                	sd	s7,8(sp)
    80001714:	e062                	sd	s8,0(sp)
    80001716:	0880                	addi	s0,sp,80
    80001718:	8b2a                	mv	s6,a0
    8000171a:	8a2e                	mv	s4,a1
    8000171c:	8c32                	mv	s8,a2
    8000171e:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    80001720:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001722:	6a85                	lui	s5,0x1
    80001724:	a015                	j	80001748 <copyin+0x4a>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    80001726:	9562                	add	a0,a0,s8
    80001728:	0004861b          	sext.w	a2,s1
    8000172c:	412505b3          	sub	a1,a0,s2
    80001730:	8552                	mv	a0,s4
    80001732:	fffff097          	auipc	ra,0xfffff
    80001736:	60e080e7          	jalr	1550(ra) # 80000d40 <memmove>

    len -= n;
    8000173a:	409989b3          	sub	s3,s3,s1
    dst += n;
    8000173e:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    80001740:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001744:	02098263          	beqz	s3,80001768 <copyin+0x6a>
    va0 = PGROUNDDOWN(srcva);
    80001748:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    8000174c:	85ca                	mv	a1,s2
    8000174e:	855a                	mv	a0,s6
    80001750:	00000097          	auipc	ra,0x0
    80001754:	91e080e7          	jalr	-1762(ra) # 8000106e <walkaddr>
    if(pa0 == 0)
    80001758:	cd01                	beqz	a0,80001770 <copyin+0x72>
    n = PGSIZE - (srcva - va0);
    8000175a:	418904b3          	sub	s1,s2,s8
    8000175e:	94d6                	add	s1,s1,s5
    if(n > len)
    80001760:	fc99f3e3          	bgeu	s3,s1,80001726 <copyin+0x28>
    80001764:	84ce                	mv	s1,s3
    80001766:	b7c1                	j	80001726 <copyin+0x28>
  }
  return 0;
    80001768:	4501                	li	a0,0
    8000176a:	a021                	j	80001772 <copyin+0x74>
    8000176c:	4501                	li	a0,0
}
    8000176e:	8082                	ret
      return -1;
    80001770:	557d                	li	a0,-1
}
    80001772:	60a6                	ld	ra,72(sp)
    80001774:	6406                	ld	s0,64(sp)
    80001776:	74e2                	ld	s1,56(sp)
    80001778:	7942                	ld	s2,48(sp)
    8000177a:	79a2                	ld	s3,40(sp)
    8000177c:	7a02                	ld	s4,32(sp)
    8000177e:	6ae2                	ld	s5,24(sp)
    80001780:	6b42                	ld	s6,16(sp)
    80001782:	6ba2                	ld	s7,8(sp)
    80001784:	6c02                	ld	s8,0(sp)
    80001786:	6161                	addi	sp,sp,80
    80001788:	8082                	ret

000000008000178a <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    8000178a:	c6c5                	beqz	a3,80001832 <copyinstr+0xa8>
{
    8000178c:	715d                	addi	sp,sp,-80
    8000178e:	e486                	sd	ra,72(sp)
    80001790:	e0a2                	sd	s0,64(sp)
    80001792:	fc26                	sd	s1,56(sp)
    80001794:	f84a                	sd	s2,48(sp)
    80001796:	f44e                	sd	s3,40(sp)
    80001798:	f052                	sd	s4,32(sp)
    8000179a:	ec56                	sd	s5,24(sp)
    8000179c:	e85a                	sd	s6,16(sp)
    8000179e:	e45e                	sd	s7,8(sp)
    800017a0:	0880                	addi	s0,sp,80
    800017a2:	8a2a                	mv	s4,a0
    800017a4:	8b2e                	mv	s6,a1
    800017a6:	8bb2                	mv	s7,a2
    800017a8:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    800017aa:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800017ac:	6985                	lui	s3,0x1
    800017ae:	a035                	j	800017da <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    800017b0:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    800017b4:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800017b6:	0017b793          	seqz	a5,a5
    800017ba:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800017be:	60a6                	ld	ra,72(sp)
    800017c0:	6406                	ld	s0,64(sp)
    800017c2:	74e2                	ld	s1,56(sp)
    800017c4:	7942                	ld	s2,48(sp)
    800017c6:	79a2                	ld	s3,40(sp)
    800017c8:	7a02                	ld	s4,32(sp)
    800017ca:	6ae2                	ld	s5,24(sp)
    800017cc:	6b42                	ld	s6,16(sp)
    800017ce:	6ba2                	ld	s7,8(sp)
    800017d0:	6161                	addi	sp,sp,80
    800017d2:	8082                	ret
    srcva = va0 + PGSIZE;
    800017d4:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    800017d8:	c8a9                	beqz	s1,8000182a <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    800017da:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800017de:	85ca                	mv	a1,s2
    800017e0:	8552                	mv	a0,s4
    800017e2:	00000097          	auipc	ra,0x0
    800017e6:	88c080e7          	jalr	-1908(ra) # 8000106e <walkaddr>
    if(pa0 == 0)
    800017ea:	c131                	beqz	a0,8000182e <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    800017ec:	41790833          	sub	a6,s2,s7
    800017f0:	984e                	add	a6,a6,s3
    if(n > max)
    800017f2:	0104f363          	bgeu	s1,a6,800017f8 <copyinstr+0x6e>
    800017f6:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    800017f8:	955e                	add	a0,a0,s7
    800017fa:	41250533          	sub	a0,a0,s2
    while(n > 0){
    800017fe:	fc080be3          	beqz	a6,800017d4 <copyinstr+0x4a>
    80001802:	985a                	add	a6,a6,s6
    80001804:	87da                	mv	a5,s6
      if(*p == '\0'){
    80001806:	41650633          	sub	a2,a0,s6
    8000180a:	14fd                	addi	s1,s1,-1
    8000180c:	9b26                	add	s6,s6,s1
    8000180e:	00f60733          	add	a4,a2,a5
    80001812:	00074703          	lbu	a4,0(a4)
    80001816:	df49                	beqz	a4,800017b0 <copyinstr+0x26>
        *dst = *p;
    80001818:	00e78023          	sb	a4,0(a5)
      --max;
    8000181c:	40fb04b3          	sub	s1,s6,a5
      dst++;
    80001820:	0785                	addi	a5,a5,1
    while(n > 0){
    80001822:	ff0796e3          	bne	a5,a6,8000180e <copyinstr+0x84>
      dst++;
    80001826:	8b42                	mv	s6,a6
    80001828:	b775                	j	800017d4 <copyinstr+0x4a>
    8000182a:	4781                	li	a5,0
    8000182c:	b769                	j	800017b6 <copyinstr+0x2c>
      return -1;
    8000182e:	557d                	li	a0,-1
    80001830:	b779                	j	800017be <copyinstr+0x34>
  int got_null = 0;
    80001832:	4781                	li	a5,0
  if(got_null){
    80001834:	0017b793          	seqz	a5,a5
    80001838:	40f00533          	neg	a0,a5
}
    8000183c:	8082                	ret

000000008000183e <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl) {
    8000183e:	7139                	addi	sp,sp,-64
    80001840:	fc06                	sd	ra,56(sp)
    80001842:	f822                	sd	s0,48(sp)
    80001844:	f426                	sd	s1,40(sp)
    80001846:	f04a                	sd	s2,32(sp)
    80001848:	ec4e                	sd	s3,24(sp)
    8000184a:	e852                	sd	s4,16(sp)
    8000184c:	e456                	sd	s5,8(sp)
    8000184e:	e05a                	sd	s6,0(sp)
    80001850:	0080                	addi	s0,sp,64
    80001852:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    80001854:	00010497          	auipc	s1,0x10
    80001858:	e7c48493          	addi	s1,s1,-388 # 800116d0 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    8000185c:	8b26                	mv	s6,s1
    8000185e:	00006a97          	auipc	s5,0x6
    80001862:	7a2a8a93          	addi	s5,s5,1954 # 80008000 <etext>
    80001866:	04000937          	lui	s2,0x4000
    8000186a:	197d                	addi	s2,s2,-1
    8000186c:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    8000186e:	00016a17          	auipc	s4,0x16
    80001872:	862a0a13          	addi	s4,s4,-1950 # 800170d0 <tickslock>
    char *pa = kalloc();
    80001876:	fffff097          	auipc	ra,0xfffff
    8000187a:	27e080e7          	jalr	638(ra) # 80000af4 <kalloc>
    8000187e:	862a                	mv	a2,a0
    if(pa == 0)
    80001880:	c131                	beqz	a0,800018c4 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    80001882:	416485b3          	sub	a1,s1,s6
    80001886:	858d                	srai	a1,a1,0x3
    80001888:	000ab783          	ld	a5,0(s5)
    8000188c:	02f585b3          	mul	a1,a1,a5
    80001890:	2585                	addiw	a1,a1,1
    80001892:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001896:	4719                	li	a4,6
    80001898:	6685                	lui	a3,0x1
    8000189a:	40b905b3          	sub	a1,s2,a1
    8000189e:	854e                	mv	a0,s3
    800018a0:	00000097          	auipc	ra,0x0
    800018a4:	8b0080e7          	jalr	-1872(ra) # 80001150 <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    800018a8:	16848493          	addi	s1,s1,360
    800018ac:	fd4495e3          	bne	s1,s4,80001876 <proc_mapstacks+0x38>
  }
}
    800018b0:	70e2                	ld	ra,56(sp)
    800018b2:	7442                	ld	s0,48(sp)
    800018b4:	74a2                	ld	s1,40(sp)
    800018b6:	7902                	ld	s2,32(sp)
    800018b8:	69e2                	ld	s3,24(sp)
    800018ba:	6a42                	ld	s4,16(sp)
    800018bc:	6aa2                	ld	s5,8(sp)
    800018be:	6b02                	ld	s6,0(sp)
    800018c0:	6121                	addi	sp,sp,64
    800018c2:	8082                	ret
      panic("kalloc");
    800018c4:	00007517          	auipc	a0,0x7
    800018c8:	91450513          	addi	a0,a0,-1772 # 800081d8 <digits+0x198>
    800018cc:	fffff097          	auipc	ra,0xfffff
    800018d0:	c72080e7          	jalr	-910(ra) # 8000053e <panic>

00000000800018d4 <procinit>:

// initialize the proc table at boot time.
void
procinit(void)
{
    800018d4:	7139                	addi	sp,sp,-64
    800018d6:	fc06                	sd	ra,56(sp)
    800018d8:	f822                	sd	s0,48(sp)
    800018da:	f426                	sd	s1,40(sp)
    800018dc:	f04a                	sd	s2,32(sp)
    800018de:	ec4e                	sd	s3,24(sp)
    800018e0:	e852                	sd	s4,16(sp)
    800018e2:	e456                	sd	s5,8(sp)
    800018e4:	e05a                	sd	s6,0(sp)
    800018e6:	0080                	addi	s0,sp,64
  struct proc *p;
  
  initlock(&pid_lock, "nextpid");
    800018e8:	00007597          	auipc	a1,0x7
    800018ec:	8f858593          	addi	a1,a1,-1800 # 800081e0 <digits+0x1a0>
    800018f0:	00010517          	auipc	a0,0x10
    800018f4:	9b050513          	addi	a0,a0,-1616 # 800112a0 <pid_lock>
    800018f8:	fffff097          	auipc	ra,0xfffff
    800018fc:	25c080e7          	jalr	604(ra) # 80000b54 <initlock>
  initlock(&wait_lock, "wait_lock");
    80001900:	00007597          	auipc	a1,0x7
    80001904:	8e858593          	addi	a1,a1,-1816 # 800081e8 <digits+0x1a8>
    80001908:	00010517          	auipc	a0,0x10
    8000190c:	9b050513          	addi	a0,a0,-1616 # 800112b8 <wait_lock>
    80001910:	fffff097          	auipc	ra,0xfffff
    80001914:	244080e7          	jalr	580(ra) # 80000b54 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001918:	00010497          	auipc	s1,0x10
    8000191c:	db848493          	addi	s1,s1,-584 # 800116d0 <proc>
      initlock(&p->lock, "proc");
    80001920:	00007b17          	auipc	s6,0x7
    80001924:	8d8b0b13          	addi	s6,s6,-1832 # 800081f8 <digits+0x1b8>
      p->kstack = KSTACK((int) (p - proc));
    80001928:	8aa6                	mv	s5,s1
    8000192a:	00006a17          	auipc	s4,0x6
    8000192e:	6d6a0a13          	addi	s4,s4,1750 # 80008000 <etext>
    80001932:	04000937          	lui	s2,0x4000
    80001936:	197d                	addi	s2,s2,-1
    80001938:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    8000193a:	00015997          	auipc	s3,0x15
    8000193e:	79698993          	addi	s3,s3,1942 # 800170d0 <tickslock>
      initlock(&p->lock, "proc");
    80001942:	85da                	mv	a1,s6
    80001944:	8526                	mv	a0,s1
    80001946:	fffff097          	auipc	ra,0xfffff
    8000194a:	20e080e7          	jalr	526(ra) # 80000b54 <initlock>
      p->kstack = KSTACK((int) (p - proc));
    8000194e:	415487b3          	sub	a5,s1,s5
    80001952:	878d                	srai	a5,a5,0x3
    80001954:	000a3703          	ld	a4,0(s4)
    80001958:	02e787b3          	mul	a5,a5,a4
    8000195c:	2785                	addiw	a5,a5,1
    8000195e:	00d7979b          	slliw	a5,a5,0xd
    80001962:	40f907b3          	sub	a5,s2,a5
    80001966:	e0bc                	sd	a5,64(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    80001968:	16848493          	addi	s1,s1,360
    8000196c:	fd349be3          	bne	s1,s3,80001942 <procinit+0x6e>
  }
}
    80001970:	70e2                	ld	ra,56(sp)
    80001972:	7442                	ld	s0,48(sp)
    80001974:	74a2                	ld	s1,40(sp)
    80001976:	7902                	ld	s2,32(sp)
    80001978:	69e2                	ld	s3,24(sp)
    8000197a:	6a42                	ld	s4,16(sp)
    8000197c:	6aa2                	ld	s5,8(sp)
    8000197e:	6b02                	ld	s6,0(sp)
    80001980:	6121                	addi	sp,sp,64
    80001982:	8082                	ret

0000000080001984 <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    80001984:	1141                	addi	sp,sp,-16
    80001986:	e422                	sd	s0,8(sp)
    80001988:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    8000198a:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    8000198c:	2501                	sext.w	a0,a0
    8000198e:	6422                	ld	s0,8(sp)
    80001990:	0141                	addi	sp,sp,16
    80001992:	8082                	ret

0000000080001994 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void) {
    80001994:	1141                	addi	sp,sp,-16
    80001996:	e422                	sd	s0,8(sp)
    80001998:	0800                	addi	s0,sp,16
    8000199a:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    8000199c:	2781                	sext.w	a5,a5
    8000199e:	079e                	slli	a5,a5,0x7
  return c;
}
    800019a0:	00010517          	auipc	a0,0x10
    800019a4:	93050513          	addi	a0,a0,-1744 # 800112d0 <cpus>
    800019a8:	953e                	add	a0,a0,a5
    800019aa:	6422                	ld	s0,8(sp)
    800019ac:	0141                	addi	sp,sp,16
    800019ae:	8082                	ret

00000000800019b0 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void) {
    800019b0:	1101                	addi	sp,sp,-32
    800019b2:	ec06                	sd	ra,24(sp)
    800019b4:	e822                	sd	s0,16(sp)
    800019b6:	e426                	sd	s1,8(sp)
    800019b8:	1000                	addi	s0,sp,32
  push_off();
    800019ba:	fffff097          	auipc	ra,0xfffff
    800019be:	1de080e7          	jalr	478(ra) # 80000b98 <push_off>
    800019c2:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    800019c4:	2781                	sext.w	a5,a5
    800019c6:	079e                	slli	a5,a5,0x7
    800019c8:	00010717          	auipc	a4,0x10
    800019cc:	8d870713          	addi	a4,a4,-1832 # 800112a0 <pid_lock>
    800019d0:	97ba                	add	a5,a5,a4
    800019d2:	7b84                	ld	s1,48(a5)
  pop_off();
    800019d4:	fffff097          	auipc	ra,0xfffff
    800019d8:	264080e7          	jalr	612(ra) # 80000c38 <pop_off>
  return p;
}
    800019dc:	8526                	mv	a0,s1
    800019de:	60e2                	ld	ra,24(sp)
    800019e0:	6442                	ld	s0,16(sp)
    800019e2:	64a2                	ld	s1,8(sp)
    800019e4:	6105                	addi	sp,sp,32
    800019e6:	8082                	ret

00000000800019e8 <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    800019e8:	1141                	addi	sp,sp,-16
    800019ea:	e406                	sd	ra,8(sp)
    800019ec:	e022                	sd	s0,0(sp)
    800019ee:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    800019f0:	00000097          	auipc	ra,0x0
    800019f4:	fc0080e7          	jalr	-64(ra) # 800019b0 <myproc>
    800019f8:	fffff097          	auipc	ra,0xfffff
    800019fc:	2a0080e7          	jalr	672(ra) # 80000c98 <release>

  if (first) {
    80001a00:	00007797          	auipc	a5,0x7
    80001a04:	e107a783          	lw	a5,-496(a5) # 80008810 <first.1678>
    80001a08:	eb89                	bnez	a5,80001a1a <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001a0a:	00001097          	auipc	ra,0x1
    80001a0e:	bfc080e7          	jalr	-1028(ra) # 80002606 <usertrapret>
}
    80001a12:	60a2                	ld	ra,8(sp)
    80001a14:	6402                	ld	s0,0(sp)
    80001a16:	0141                	addi	sp,sp,16
    80001a18:	8082                	ret
    first = 0;
    80001a1a:	00007797          	auipc	a5,0x7
    80001a1e:	de07ab23          	sw	zero,-522(a5) # 80008810 <first.1678>
    fsinit(ROOTDEV);
    80001a22:	4505                	li	a0,1
    80001a24:	00002097          	auipc	ra,0x2
    80001a28:	924080e7          	jalr	-1756(ra) # 80003348 <fsinit>
    80001a2c:	bff9                	j	80001a0a <forkret+0x22>

0000000080001a2e <allocpid>:
allocpid() {
    80001a2e:	1101                	addi	sp,sp,-32
    80001a30:	ec06                	sd	ra,24(sp)
    80001a32:	e822                	sd	s0,16(sp)
    80001a34:	e426                	sd	s1,8(sp)
    80001a36:	e04a                	sd	s2,0(sp)
    80001a38:	1000                	addi	s0,sp,32
    pid = nextpid;
    80001a3a:	00007917          	auipc	s2,0x7
    80001a3e:	dda90913          	addi	s2,s2,-550 # 80008814 <nextpid>
    80001a42:	00092483          	lw	s1,0(s2)
  } while (cas(&nextpid, pid, pid+1));
    80001a46:	0014861b          	addiw	a2,s1,1
    80001a4a:	85a6                	mv	a1,s1
    80001a4c:	854a                	mv	a0,s2
    80001a4e:	00004097          	auipc	ra,0x4
    80001a52:	708080e7          	jalr	1800(ra) # 80006156 <cas>
    80001a56:	f575                	bnez	a0,80001a42 <allocpid+0x14>
}
    80001a58:	8526                	mv	a0,s1
    80001a5a:	60e2                	ld	ra,24(sp)
    80001a5c:	6442                	ld	s0,16(sp)
    80001a5e:	64a2                	ld	s1,8(sp)
    80001a60:	6902                	ld	s2,0(sp)
    80001a62:	6105                	addi	sp,sp,32
    80001a64:	8082                	ret

0000000080001a66 <proc_pagetable>:
{
    80001a66:	1101                	addi	sp,sp,-32
    80001a68:	ec06                	sd	ra,24(sp)
    80001a6a:	e822                	sd	s0,16(sp)
    80001a6c:	e426                	sd	s1,8(sp)
    80001a6e:	e04a                	sd	s2,0(sp)
    80001a70:	1000                	addi	s0,sp,32
    80001a72:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001a74:	00000097          	auipc	ra,0x0
    80001a78:	8c6080e7          	jalr	-1850(ra) # 8000133a <uvmcreate>
    80001a7c:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001a7e:	c121                	beqz	a0,80001abe <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001a80:	4729                	li	a4,10
    80001a82:	00005697          	auipc	a3,0x5
    80001a86:	57e68693          	addi	a3,a3,1406 # 80007000 <_trampoline>
    80001a8a:	6605                	lui	a2,0x1
    80001a8c:	040005b7          	lui	a1,0x4000
    80001a90:	15fd                	addi	a1,a1,-1
    80001a92:	05b2                	slli	a1,a1,0xc
    80001a94:	fffff097          	auipc	ra,0xfffff
    80001a98:	61c080e7          	jalr	1564(ra) # 800010b0 <mappages>
    80001a9c:	02054863          	bltz	a0,80001acc <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001aa0:	4719                	li	a4,6
    80001aa2:	05893683          	ld	a3,88(s2)
    80001aa6:	6605                	lui	a2,0x1
    80001aa8:	020005b7          	lui	a1,0x2000
    80001aac:	15fd                	addi	a1,a1,-1
    80001aae:	05b6                	slli	a1,a1,0xd
    80001ab0:	8526                	mv	a0,s1
    80001ab2:	fffff097          	auipc	ra,0xfffff
    80001ab6:	5fe080e7          	jalr	1534(ra) # 800010b0 <mappages>
    80001aba:	02054163          	bltz	a0,80001adc <proc_pagetable+0x76>
}
    80001abe:	8526                	mv	a0,s1
    80001ac0:	60e2                	ld	ra,24(sp)
    80001ac2:	6442                	ld	s0,16(sp)
    80001ac4:	64a2                	ld	s1,8(sp)
    80001ac6:	6902                	ld	s2,0(sp)
    80001ac8:	6105                	addi	sp,sp,32
    80001aca:	8082                	ret
    uvmfree(pagetable, 0);
    80001acc:	4581                	li	a1,0
    80001ace:	8526                	mv	a0,s1
    80001ad0:	00000097          	auipc	ra,0x0
    80001ad4:	a66080e7          	jalr	-1434(ra) # 80001536 <uvmfree>
    return 0;
    80001ad8:	4481                	li	s1,0
    80001ada:	b7d5                	j	80001abe <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001adc:	4681                	li	a3,0
    80001ade:	4605                	li	a2,1
    80001ae0:	040005b7          	lui	a1,0x4000
    80001ae4:	15fd                	addi	a1,a1,-1
    80001ae6:	05b2                	slli	a1,a1,0xc
    80001ae8:	8526                	mv	a0,s1
    80001aea:	fffff097          	auipc	ra,0xfffff
    80001aee:	78c080e7          	jalr	1932(ra) # 80001276 <uvmunmap>
    uvmfree(pagetable, 0);
    80001af2:	4581                	li	a1,0
    80001af4:	8526                	mv	a0,s1
    80001af6:	00000097          	auipc	ra,0x0
    80001afa:	a40080e7          	jalr	-1472(ra) # 80001536 <uvmfree>
    return 0;
    80001afe:	4481                	li	s1,0
    80001b00:	bf7d                	j	80001abe <proc_pagetable+0x58>

0000000080001b02 <proc_freepagetable>:
{
    80001b02:	1101                	addi	sp,sp,-32
    80001b04:	ec06                	sd	ra,24(sp)
    80001b06:	e822                	sd	s0,16(sp)
    80001b08:	e426                	sd	s1,8(sp)
    80001b0a:	e04a                	sd	s2,0(sp)
    80001b0c:	1000                	addi	s0,sp,32
    80001b0e:	84aa                	mv	s1,a0
    80001b10:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b12:	4681                	li	a3,0
    80001b14:	4605                	li	a2,1
    80001b16:	040005b7          	lui	a1,0x4000
    80001b1a:	15fd                	addi	a1,a1,-1
    80001b1c:	05b2                	slli	a1,a1,0xc
    80001b1e:	fffff097          	auipc	ra,0xfffff
    80001b22:	758080e7          	jalr	1880(ra) # 80001276 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001b26:	4681                	li	a3,0
    80001b28:	4605                	li	a2,1
    80001b2a:	020005b7          	lui	a1,0x2000
    80001b2e:	15fd                	addi	a1,a1,-1
    80001b30:	05b6                	slli	a1,a1,0xd
    80001b32:	8526                	mv	a0,s1
    80001b34:	fffff097          	auipc	ra,0xfffff
    80001b38:	742080e7          	jalr	1858(ra) # 80001276 <uvmunmap>
  uvmfree(pagetable, sz);
    80001b3c:	85ca                	mv	a1,s2
    80001b3e:	8526                	mv	a0,s1
    80001b40:	00000097          	auipc	ra,0x0
    80001b44:	9f6080e7          	jalr	-1546(ra) # 80001536 <uvmfree>
}
    80001b48:	60e2                	ld	ra,24(sp)
    80001b4a:	6442                	ld	s0,16(sp)
    80001b4c:	64a2                	ld	s1,8(sp)
    80001b4e:	6902                	ld	s2,0(sp)
    80001b50:	6105                	addi	sp,sp,32
    80001b52:	8082                	ret

0000000080001b54 <freeproc>:
{
    80001b54:	1101                	addi	sp,sp,-32
    80001b56:	ec06                	sd	ra,24(sp)
    80001b58:	e822                	sd	s0,16(sp)
    80001b5a:	e426                	sd	s1,8(sp)
    80001b5c:	1000                	addi	s0,sp,32
    80001b5e:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001b60:	6d28                	ld	a0,88(a0)
    80001b62:	c509                	beqz	a0,80001b6c <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001b64:	fffff097          	auipc	ra,0xfffff
    80001b68:	e94080e7          	jalr	-364(ra) # 800009f8 <kfree>
  p->trapframe = 0;
    80001b6c:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001b70:	68a8                	ld	a0,80(s1)
    80001b72:	c511                	beqz	a0,80001b7e <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001b74:	64ac                	ld	a1,72(s1)
    80001b76:	00000097          	auipc	ra,0x0
    80001b7a:	f8c080e7          	jalr	-116(ra) # 80001b02 <proc_freepagetable>
  p->pagetable = 0;
    80001b7e:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001b82:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001b86:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001b8a:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001b8e:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001b92:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001b96:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001b9a:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001b9e:	0004ac23          	sw	zero,24(s1)
}
    80001ba2:	60e2                	ld	ra,24(sp)
    80001ba4:	6442                	ld	s0,16(sp)
    80001ba6:	64a2                	ld	s1,8(sp)
    80001ba8:	6105                	addi	sp,sp,32
    80001baa:	8082                	ret

0000000080001bac <allocproc>:
{
    80001bac:	1101                	addi	sp,sp,-32
    80001bae:	ec06                	sd	ra,24(sp)
    80001bb0:	e822                	sd	s0,16(sp)
    80001bb2:	e426                	sd	s1,8(sp)
    80001bb4:	e04a                	sd	s2,0(sp)
    80001bb6:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001bb8:	00010497          	auipc	s1,0x10
    80001bbc:	b1848493          	addi	s1,s1,-1256 # 800116d0 <proc>
    80001bc0:	00015917          	auipc	s2,0x15
    80001bc4:	51090913          	addi	s2,s2,1296 # 800170d0 <tickslock>
    acquire(&p->lock);
    80001bc8:	8526                	mv	a0,s1
    80001bca:	fffff097          	auipc	ra,0xfffff
    80001bce:	01a080e7          	jalr	26(ra) # 80000be4 <acquire>
    if(p->state == UNUSED) {
    80001bd2:	4c9c                	lw	a5,24(s1)
    80001bd4:	cf81                	beqz	a5,80001bec <allocproc+0x40>
      release(&p->lock);
    80001bd6:	8526                	mv	a0,s1
    80001bd8:	fffff097          	auipc	ra,0xfffff
    80001bdc:	0c0080e7          	jalr	192(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001be0:	16848493          	addi	s1,s1,360
    80001be4:	ff2492e3          	bne	s1,s2,80001bc8 <allocproc+0x1c>
  return 0;
    80001be8:	4481                	li	s1,0
    80001bea:	a889                	j	80001c3c <allocproc+0x90>
  p->pid = allocpid();
    80001bec:	00000097          	auipc	ra,0x0
    80001bf0:	e42080e7          	jalr	-446(ra) # 80001a2e <allocpid>
    80001bf4:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001bf6:	4785                	li	a5,1
    80001bf8:	cc9c                	sw	a5,24(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001bfa:	fffff097          	auipc	ra,0xfffff
    80001bfe:	efa080e7          	jalr	-262(ra) # 80000af4 <kalloc>
    80001c02:	892a                	mv	s2,a0
    80001c04:	eca8                	sd	a0,88(s1)
    80001c06:	c131                	beqz	a0,80001c4a <allocproc+0x9e>
  p->pagetable = proc_pagetable(p);
    80001c08:	8526                	mv	a0,s1
    80001c0a:	00000097          	auipc	ra,0x0
    80001c0e:	e5c080e7          	jalr	-420(ra) # 80001a66 <proc_pagetable>
    80001c12:	892a                	mv	s2,a0
    80001c14:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001c16:	c531                	beqz	a0,80001c62 <allocproc+0xb6>
  memset(&p->context, 0, sizeof(p->context));
    80001c18:	07000613          	li	a2,112
    80001c1c:	4581                	li	a1,0
    80001c1e:	06048513          	addi	a0,s1,96
    80001c22:	fffff097          	auipc	ra,0xfffff
    80001c26:	0be080e7          	jalr	190(ra) # 80000ce0 <memset>
  p->context.ra = (uint64)forkret;
    80001c2a:	00000797          	auipc	a5,0x0
    80001c2e:	dbe78793          	addi	a5,a5,-578 # 800019e8 <forkret>
    80001c32:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001c34:	60bc                	ld	a5,64(s1)
    80001c36:	6705                	lui	a4,0x1
    80001c38:	97ba                	add	a5,a5,a4
    80001c3a:	f4bc                	sd	a5,104(s1)
}
    80001c3c:	8526                	mv	a0,s1
    80001c3e:	60e2                	ld	ra,24(sp)
    80001c40:	6442                	ld	s0,16(sp)
    80001c42:	64a2                	ld	s1,8(sp)
    80001c44:	6902                	ld	s2,0(sp)
    80001c46:	6105                	addi	sp,sp,32
    80001c48:	8082                	ret
    freeproc(p);
    80001c4a:	8526                	mv	a0,s1
    80001c4c:	00000097          	auipc	ra,0x0
    80001c50:	f08080e7          	jalr	-248(ra) # 80001b54 <freeproc>
    release(&p->lock);
    80001c54:	8526                	mv	a0,s1
    80001c56:	fffff097          	auipc	ra,0xfffff
    80001c5a:	042080e7          	jalr	66(ra) # 80000c98 <release>
    return 0;
    80001c5e:	84ca                	mv	s1,s2
    80001c60:	bff1                	j	80001c3c <allocproc+0x90>
    freeproc(p);
    80001c62:	8526                	mv	a0,s1
    80001c64:	00000097          	auipc	ra,0x0
    80001c68:	ef0080e7          	jalr	-272(ra) # 80001b54 <freeproc>
    release(&p->lock);
    80001c6c:	8526                	mv	a0,s1
    80001c6e:	fffff097          	auipc	ra,0xfffff
    80001c72:	02a080e7          	jalr	42(ra) # 80000c98 <release>
    return 0;
    80001c76:	84ca                	mv	s1,s2
    80001c78:	b7d1                	j	80001c3c <allocproc+0x90>

0000000080001c7a <userinit>:
{
    80001c7a:	1101                	addi	sp,sp,-32
    80001c7c:	ec06                	sd	ra,24(sp)
    80001c7e:	e822                	sd	s0,16(sp)
    80001c80:	e426                	sd	s1,8(sp)
    80001c82:	1000                	addi	s0,sp,32
  p = allocproc();
    80001c84:	00000097          	auipc	ra,0x0
    80001c88:	f28080e7          	jalr	-216(ra) # 80001bac <allocproc>
    80001c8c:	84aa                	mv	s1,a0
  initproc = p;
    80001c8e:	00007797          	auipc	a5,0x7
    80001c92:	38a7bd23          	sd	a0,922(a5) # 80009028 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001c96:	03400613          	li	a2,52
    80001c9a:	00007597          	auipc	a1,0x7
    80001c9e:	b8658593          	addi	a1,a1,-1146 # 80008820 <initcode>
    80001ca2:	6928                	ld	a0,80(a0)
    80001ca4:	fffff097          	auipc	ra,0xfffff
    80001ca8:	6c4080e7          	jalr	1732(ra) # 80001368 <uvminit>
  p->sz = PGSIZE;
    80001cac:	6785                	lui	a5,0x1
    80001cae:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001cb0:	6cb8                	ld	a4,88(s1)
    80001cb2:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001cb6:	6cb8                	ld	a4,88(s1)
    80001cb8:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001cba:	4641                	li	a2,16
    80001cbc:	00006597          	auipc	a1,0x6
    80001cc0:	54458593          	addi	a1,a1,1348 # 80008200 <digits+0x1c0>
    80001cc4:	15848513          	addi	a0,s1,344
    80001cc8:	fffff097          	auipc	ra,0xfffff
    80001ccc:	16a080e7          	jalr	362(ra) # 80000e32 <safestrcpy>
  p->cwd = namei("/");
    80001cd0:	00006517          	auipc	a0,0x6
    80001cd4:	54050513          	addi	a0,a0,1344 # 80008210 <digits+0x1d0>
    80001cd8:	00002097          	auipc	ra,0x2
    80001cdc:	09e080e7          	jalr	158(ra) # 80003d76 <namei>
    80001ce0:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001ce4:	478d                	li	a5,3
    80001ce6:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001ce8:	8526                	mv	a0,s1
    80001cea:	fffff097          	auipc	ra,0xfffff
    80001cee:	fae080e7          	jalr	-82(ra) # 80000c98 <release>
}
    80001cf2:	60e2                	ld	ra,24(sp)
    80001cf4:	6442                	ld	s0,16(sp)
    80001cf6:	64a2                	ld	s1,8(sp)
    80001cf8:	6105                	addi	sp,sp,32
    80001cfa:	8082                	ret

0000000080001cfc <growproc>:
{
    80001cfc:	1101                	addi	sp,sp,-32
    80001cfe:	ec06                	sd	ra,24(sp)
    80001d00:	e822                	sd	s0,16(sp)
    80001d02:	e426                	sd	s1,8(sp)
    80001d04:	e04a                	sd	s2,0(sp)
    80001d06:	1000                	addi	s0,sp,32
    80001d08:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001d0a:	00000097          	auipc	ra,0x0
    80001d0e:	ca6080e7          	jalr	-858(ra) # 800019b0 <myproc>
    80001d12:	892a                	mv	s2,a0
  sz = p->sz;
    80001d14:	652c                	ld	a1,72(a0)
    80001d16:	0005861b          	sext.w	a2,a1
  if(n > 0){
    80001d1a:	00904f63          	bgtz	s1,80001d38 <growproc+0x3c>
  } else if(n < 0){
    80001d1e:	0204cc63          	bltz	s1,80001d56 <growproc+0x5a>
  p->sz = sz;
    80001d22:	1602                	slli	a2,a2,0x20
    80001d24:	9201                	srli	a2,a2,0x20
    80001d26:	04c93423          	sd	a2,72(s2)
  return 0;
    80001d2a:	4501                	li	a0,0
}
    80001d2c:	60e2                	ld	ra,24(sp)
    80001d2e:	6442                	ld	s0,16(sp)
    80001d30:	64a2                	ld	s1,8(sp)
    80001d32:	6902                	ld	s2,0(sp)
    80001d34:	6105                	addi	sp,sp,32
    80001d36:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80001d38:	9e25                	addw	a2,a2,s1
    80001d3a:	1602                	slli	a2,a2,0x20
    80001d3c:	9201                	srli	a2,a2,0x20
    80001d3e:	1582                	slli	a1,a1,0x20
    80001d40:	9181                	srli	a1,a1,0x20
    80001d42:	6928                	ld	a0,80(a0)
    80001d44:	fffff097          	auipc	ra,0xfffff
    80001d48:	6de080e7          	jalr	1758(ra) # 80001422 <uvmalloc>
    80001d4c:	0005061b          	sext.w	a2,a0
    80001d50:	fa69                	bnez	a2,80001d22 <growproc+0x26>
      return -1;
    80001d52:	557d                	li	a0,-1
    80001d54:	bfe1                	j	80001d2c <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001d56:	9e25                	addw	a2,a2,s1
    80001d58:	1602                	slli	a2,a2,0x20
    80001d5a:	9201                	srli	a2,a2,0x20
    80001d5c:	1582                	slli	a1,a1,0x20
    80001d5e:	9181                	srli	a1,a1,0x20
    80001d60:	6928                	ld	a0,80(a0)
    80001d62:	fffff097          	auipc	ra,0xfffff
    80001d66:	678080e7          	jalr	1656(ra) # 800013da <uvmdealloc>
    80001d6a:	0005061b          	sext.w	a2,a0
    80001d6e:	bf55                	j	80001d22 <growproc+0x26>

0000000080001d70 <fork>:
{
    80001d70:	7179                	addi	sp,sp,-48
    80001d72:	f406                	sd	ra,40(sp)
    80001d74:	f022                	sd	s0,32(sp)
    80001d76:	ec26                	sd	s1,24(sp)
    80001d78:	e84a                	sd	s2,16(sp)
    80001d7a:	e44e                	sd	s3,8(sp)
    80001d7c:	e052                	sd	s4,0(sp)
    80001d7e:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001d80:	00000097          	auipc	ra,0x0
    80001d84:	c30080e7          	jalr	-976(ra) # 800019b0 <myproc>
    80001d88:	892a                	mv	s2,a0
  if((np = allocproc()) == 0){
    80001d8a:	00000097          	auipc	ra,0x0
    80001d8e:	e22080e7          	jalr	-478(ra) # 80001bac <allocproc>
    80001d92:	10050b63          	beqz	a0,80001ea8 <fork+0x138>
    80001d96:	89aa                	mv	s3,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001d98:	04893603          	ld	a2,72(s2)
    80001d9c:	692c                	ld	a1,80(a0)
    80001d9e:	05093503          	ld	a0,80(s2)
    80001da2:	fffff097          	auipc	ra,0xfffff
    80001da6:	7cc080e7          	jalr	1996(ra) # 8000156e <uvmcopy>
    80001daa:	04054663          	bltz	a0,80001df6 <fork+0x86>
  np->sz = p->sz;
    80001dae:	04893783          	ld	a5,72(s2)
    80001db2:	04f9b423          	sd	a5,72(s3)
  *(np->trapframe) = *(p->trapframe);
    80001db6:	05893683          	ld	a3,88(s2)
    80001dba:	87b6                	mv	a5,a3
    80001dbc:	0589b703          	ld	a4,88(s3)
    80001dc0:	12068693          	addi	a3,a3,288
    80001dc4:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001dc8:	6788                	ld	a0,8(a5)
    80001dca:	6b8c                	ld	a1,16(a5)
    80001dcc:	6f90                	ld	a2,24(a5)
    80001dce:	01073023          	sd	a6,0(a4)
    80001dd2:	e708                	sd	a0,8(a4)
    80001dd4:	eb0c                	sd	a1,16(a4)
    80001dd6:	ef10                	sd	a2,24(a4)
    80001dd8:	02078793          	addi	a5,a5,32
    80001ddc:	02070713          	addi	a4,a4,32
    80001de0:	fed792e3          	bne	a5,a3,80001dc4 <fork+0x54>
  np->trapframe->a0 = 0;
    80001de4:	0589b783          	ld	a5,88(s3)
    80001de8:	0607b823          	sd	zero,112(a5)
    80001dec:	0d000493          	li	s1,208
  for(i = 0; i < NOFILE; i++)
    80001df0:	15000a13          	li	s4,336
    80001df4:	a03d                	j	80001e22 <fork+0xb2>
    freeproc(np);
    80001df6:	854e                	mv	a0,s3
    80001df8:	00000097          	auipc	ra,0x0
    80001dfc:	d5c080e7          	jalr	-676(ra) # 80001b54 <freeproc>
    release(&np->lock);
    80001e00:	854e                	mv	a0,s3
    80001e02:	fffff097          	auipc	ra,0xfffff
    80001e06:	e96080e7          	jalr	-362(ra) # 80000c98 <release>
    return -1;
    80001e0a:	5a7d                	li	s4,-1
    80001e0c:	a069                	j	80001e96 <fork+0x126>
      np->ofile[i] = filedup(p->ofile[i]);
    80001e0e:	00002097          	auipc	ra,0x2
    80001e12:	5fe080e7          	jalr	1534(ra) # 8000440c <filedup>
    80001e16:	009987b3          	add	a5,s3,s1
    80001e1a:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    80001e1c:	04a1                	addi	s1,s1,8
    80001e1e:	01448763          	beq	s1,s4,80001e2c <fork+0xbc>
    if(p->ofile[i])
    80001e22:	009907b3          	add	a5,s2,s1
    80001e26:	6388                	ld	a0,0(a5)
    80001e28:	f17d                	bnez	a0,80001e0e <fork+0x9e>
    80001e2a:	bfcd                	j	80001e1c <fork+0xac>
  np->cwd = idup(p->cwd);
    80001e2c:	15093503          	ld	a0,336(s2)
    80001e30:	00001097          	auipc	ra,0x1
    80001e34:	752080e7          	jalr	1874(ra) # 80003582 <idup>
    80001e38:	14a9b823          	sd	a0,336(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001e3c:	4641                	li	a2,16
    80001e3e:	15890593          	addi	a1,s2,344
    80001e42:	15898513          	addi	a0,s3,344
    80001e46:	fffff097          	auipc	ra,0xfffff
    80001e4a:	fec080e7          	jalr	-20(ra) # 80000e32 <safestrcpy>
  pid = np->pid;
    80001e4e:	0309aa03          	lw	s4,48(s3)
  release(&np->lock);
    80001e52:	854e                	mv	a0,s3
    80001e54:	fffff097          	auipc	ra,0xfffff
    80001e58:	e44080e7          	jalr	-444(ra) # 80000c98 <release>
  acquire(&wait_lock);
    80001e5c:	0000f497          	auipc	s1,0xf
    80001e60:	45c48493          	addi	s1,s1,1116 # 800112b8 <wait_lock>
    80001e64:	8526                	mv	a0,s1
    80001e66:	fffff097          	auipc	ra,0xfffff
    80001e6a:	d7e080e7          	jalr	-642(ra) # 80000be4 <acquire>
  np->parent = p;
    80001e6e:	0329bc23          	sd	s2,56(s3)
  release(&wait_lock);
    80001e72:	8526                	mv	a0,s1
    80001e74:	fffff097          	auipc	ra,0xfffff
    80001e78:	e24080e7          	jalr	-476(ra) # 80000c98 <release>
  acquire(&np->lock);
    80001e7c:	854e                	mv	a0,s3
    80001e7e:	fffff097          	auipc	ra,0xfffff
    80001e82:	d66080e7          	jalr	-666(ra) # 80000be4 <acquire>
  np->state = RUNNABLE;
    80001e86:	478d                	li	a5,3
    80001e88:	00f9ac23          	sw	a5,24(s3)
  release(&np->lock);
    80001e8c:	854e                	mv	a0,s3
    80001e8e:	fffff097          	auipc	ra,0xfffff
    80001e92:	e0a080e7          	jalr	-502(ra) # 80000c98 <release>
}
    80001e96:	8552                	mv	a0,s4
    80001e98:	70a2                	ld	ra,40(sp)
    80001e9a:	7402                	ld	s0,32(sp)
    80001e9c:	64e2                	ld	s1,24(sp)
    80001e9e:	6942                	ld	s2,16(sp)
    80001ea0:	69a2                	ld	s3,8(sp)
    80001ea2:	6a02                	ld	s4,0(sp)
    80001ea4:	6145                	addi	sp,sp,48
    80001ea6:	8082                	ret
    return -1;
    80001ea8:	5a7d                	li	s4,-1
    80001eaa:	b7f5                	j	80001e96 <fork+0x126>

0000000080001eac <scheduler>:
{
    80001eac:	7139                	addi	sp,sp,-64
    80001eae:	fc06                	sd	ra,56(sp)
    80001eb0:	f822                	sd	s0,48(sp)
    80001eb2:	f426                	sd	s1,40(sp)
    80001eb4:	f04a                	sd	s2,32(sp)
    80001eb6:	ec4e                	sd	s3,24(sp)
    80001eb8:	e852                	sd	s4,16(sp)
    80001eba:	e456                	sd	s5,8(sp)
    80001ebc:	e05a                	sd	s6,0(sp)
    80001ebe:	0080                	addi	s0,sp,64
    80001ec0:	8792                	mv	a5,tp
  int id = r_tp();
    80001ec2:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001ec4:	00779a93          	slli	s5,a5,0x7
    80001ec8:	0000f717          	auipc	a4,0xf
    80001ecc:	3d870713          	addi	a4,a4,984 # 800112a0 <pid_lock>
    80001ed0:	9756                	add	a4,a4,s5
    80001ed2:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    80001ed6:	0000f717          	auipc	a4,0xf
    80001eda:	40270713          	addi	a4,a4,1026 # 800112d8 <cpus+0x8>
    80001ede:	9aba                	add	s5,s5,a4
      if(p->state == RUNNABLE) {
    80001ee0:	498d                	li	s3,3
        p->state = RUNNING;
    80001ee2:	4b11                	li	s6,4
        c->proc = p;
    80001ee4:	079e                	slli	a5,a5,0x7
    80001ee6:	0000fa17          	auipc	s4,0xf
    80001eea:	3baa0a13          	addi	s4,s4,954 # 800112a0 <pid_lock>
    80001eee:	9a3e                	add	s4,s4,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    80001ef0:	00015917          	auipc	s2,0x15
    80001ef4:	1e090913          	addi	s2,s2,480 # 800170d0 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001ef8:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001efc:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001f00:	10079073          	csrw	sstatus,a5
    80001f04:	0000f497          	auipc	s1,0xf
    80001f08:	7cc48493          	addi	s1,s1,1996 # 800116d0 <proc>
    80001f0c:	a03d                	j	80001f3a <scheduler+0x8e>
        p->state = RUNNING;
    80001f0e:	0164ac23          	sw	s6,24(s1)
        c->proc = p;
    80001f12:	029a3823          	sd	s1,48(s4)
        swtch(&c->context, &p->context);
    80001f16:	06048593          	addi	a1,s1,96
    80001f1a:	8556                	mv	a0,s5
    80001f1c:	00000097          	auipc	ra,0x0
    80001f20:	640080e7          	jalr	1600(ra) # 8000255c <swtch>
        c->proc = 0;
    80001f24:	020a3823          	sd	zero,48(s4)
      release(&p->lock);
    80001f28:	8526                	mv	a0,s1
    80001f2a:	fffff097          	auipc	ra,0xfffff
    80001f2e:	d6e080e7          	jalr	-658(ra) # 80000c98 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80001f32:	16848493          	addi	s1,s1,360
    80001f36:	fd2481e3          	beq	s1,s2,80001ef8 <scheduler+0x4c>
      acquire(&p->lock);
    80001f3a:	8526                	mv	a0,s1
    80001f3c:	fffff097          	auipc	ra,0xfffff
    80001f40:	ca8080e7          	jalr	-856(ra) # 80000be4 <acquire>
      if(p->state == RUNNABLE) {
    80001f44:	4c9c                	lw	a5,24(s1)
    80001f46:	ff3791e3          	bne	a5,s3,80001f28 <scheduler+0x7c>
    80001f4a:	b7d1                	j	80001f0e <scheduler+0x62>

0000000080001f4c <sched>:
{
    80001f4c:	7179                	addi	sp,sp,-48
    80001f4e:	f406                	sd	ra,40(sp)
    80001f50:	f022                	sd	s0,32(sp)
    80001f52:	ec26                	sd	s1,24(sp)
    80001f54:	e84a                	sd	s2,16(sp)
    80001f56:	e44e                	sd	s3,8(sp)
    80001f58:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001f5a:	00000097          	auipc	ra,0x0
    80001f5e:	a56080e7          	jalr	-1450(ra) # 800019b0 <myproc>
    80001f62:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80001f64:	fffff097          	auipc	ra,0xfffff
    80001f68:	c06080e7          	jalr	-1018(ra) # 80000b6a <holding>
    80001f6c:	c93d                	beqz	a0,80001fe2 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001f6e:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80001f70:	2781                	sext.w	a5,a5
    80001f72:	079e                	slli	a5,a5,0x7
    80001f74:	0000f717          	auipc	a4,0xf
    80001f78:	32c70713          	addi	a4,a4,812 # 800112a0 <pid_lock>
    80001f7c:	97ba                	add	a5,a5,a4
    80001f7e:	0a87a703          	lw	a4,168(a5)
    80001f82:	4785                	li	a5,1
    80001f84:	06f71763          	bne	a4,a5,80001ff2 <sched+0xa6>
  if(p->state == RUNNING)
    80001f88:	4c98                	lw	a4,24(s1)
    80001f8a:	4791                	li	a5,4
    80001f8c:	06f70b63          	beq	a4,a5,80002002 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001f90:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80001f94:	8b89                	andi	a5,a5,2
  if(intr_get())
    80001f96:	efb5                	bnez	a5,80002012 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001f98:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80001f9a:	0000f917          	auipc	s2,0xf
    80001f9e:	30690913          	addi	s2,s2,774 # 800112a0 <pid_lock>
    80001fa2:	2781                	sext.w	a5,a5
    80001fa4:	079e                	slli	a5,a5,0x7
    80001fa6:	97ca                	add	a5,a5,s2
    80001fa8:	0ac7a983          	lw	s3,172(a5)
    80001fac:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80001fae:	2781                	sext.w	a5,a5
    80001fb0:	079e                	slli	a5,a5,0x7
    80001fb2:	0000f597          	auipc	a1,0xf
    80001fb6:	32658593          	addi	a1,a1,806 # 800112d8 <cpus+0x8>
    80001fba:	95be                	add	a1,a1,a5
    80001fbc:	06048513          	addi	a0,s1,96
    80001fc0:	00000097          	auipc	ra,0x0
    80001fc4:	59c080e7          	jalr	1436(ra) # 8000255c <swtch>
    80001fc8:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80001fca:	2781                	sext.w	a5,a5
    80001fcc:	079e                	slli	a5,a5,0x7
    80001fce:	97ca                	add	a5,a5,s2
    80001fd0:	0b37a623          	sw	s3,172(a5)
}
    80001fd4:	70a2                	ld	ra,40(sp)
    80001fd6:	7402                	ld	s0,32(sp)
    80001fd8:	64e2                	ld	s1,24(sp)
    80001fda:	6942                	ld	s2,16(sp)
    80001fdc:	69a2                	ld	s3,8(sp)
    80001fde:	6145                	addi	sp,sp,48
    80001fe0:	8082                	ret
    panic("sched p->lock");
    80001fe2:	00006517          	auipc	a0,0x6
    80001fe6:	23650513          	addi	a0,a0,566 # 80008218 <digits+0x1d8>
    80001fea:	ffffe097          	auipc	ra,0xffffe
    80001fee:	554080e7          	jalr	1364(ra) # 8000053e <panic>
    panic("sched locks");
    80001ff2:	00006517          	auipc	a0,0x6
    80001ff6:	23650513          	addi	a0,a0,566 # 80008228 <digits+0x1e8>
    80001ffa:	ffffe097          	auipc	ra,0xffffe
    80001ffe:	544080e7          	jalr	1348(ra) # 8000053e <panic>
    panic("sched running");
    80002002:	00006517          	auipc	a0,0x6
    80002006:	23650513          	addi	a0,a0,566 # 80008238 <digits+0x1f8>
    8000200a:	ffffe097          	auipc	ra,0xffffe
    8000200e:	534080e7          	jalr	1332(ra) # 8000053e <panic>
    panic("sched interruptible");
    80002012:	00006517          	auipc	a0,0x6
    80002016:	23650513          	addi	a0,a0,566 # 80008248 <digits+0x208>
    8000201a:	ffffe097          	auipc	ra,0xffffe
    8000201e:	524080e7          	jalr	1316(ra) # 8000053e <panic>

0000000080002022 <yield>:
{
    80002022:	1101                	addi	sp,sp,-32
    80002024:	ec06                	sd	ra,24(sp)
    80002026:	e822                	sd	s0,16(sp)
    80002028:	e426                	sd	s1,8(sp)
    8000202a:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    8000202c:	00000097          	auipc	ra,0x0
    80002030:	984080e7          	jalr	-1660(ra) # 800019b0 <myproc>
    80002034:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002036:	fffff097          	auipc	ra,0xfffff
    8000203a:	bae080e7          	jalr	-1106(ra) # 80000be4 <acquire>
  p->state = RUNNABLE;
    8000203e:	478d                	li	a5,3
    80002040:	cc9c                	sw	a5,24(s1)
  sched();
    80002042:	00000097          	auipc	ra,0x0
    80002046:	f0a080e7          	jalr	-246(ra) # 80001f4c <sched>
  release(&p->lock);
    8000204a:	8526                	mv	a0,s1
    8000204c:	fffff097          	auipc	ra,0xfffff
    80002050:	c4c080e7          	jalr	-948(ra) # 80000c98 <release>
}
    80002054:	60e2                	ld	ra,24(sp)
    80002056:	6442                	ld	s0,16(sp)
    80002058:	64a2                	ld	s1,8(sp)
    8000205a:	6105                	addi	sp,sp,32
    8000205c:	8082                	ret

000000008000205e <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    8000205e:	7179                	addi	sp,sp,-48
    80002060:	f406                	sd	ra,40(sp)
    80002062:	f022                	sd	s0,32(sp)
    80002064:	ec26                	sd	s1,24(sp)
    80002066:	e84a                	sd	s2,16(sp)
    80002068:	e44e                	sd	s3,8(sp)
    8000206a:	1800                	addi	s0,sp,48
    8000206c:	89aa                	mv	s3,a0
    8000206e:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002070:	00000097          	auipc	ra,0x0
    80002074:	940080e7          	jalr	-1728(ra) # 800019b0 <myproc>
    80002078:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    8000207a:	fffff097          	auipc	ra,0xfffff
    8000207e:	b6a080e7          	jalr	-1174(ra) # 80000be4 <acquire>
  release(lk);
    80002082:	854a                	mv	a0,s2
    80002084:	fffff097          	auipc	ra,0xfffff
    80002088:	c14080e7          	jalr	-1004(ra) # 80000c98 <release>

  // Go to sleep.
  p->chan = chan;
    8000208c:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    80002090:	4789                	li	a5,2
    80002092:	cc9c                	sw	a5,24(s1)

  sched();
    80002094:	00000097          	auipc	ra,0x0
    80002098:	eb8080e7          	jalr	-328(ra) # 80001f4c <sched>

  // Tidy up.
  p->chan = 0;
    8000209c:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    800020a0:	8526                	mv	a0,s1
    800020a2:	fffff097          	auipc	ra,0xfffff
    800020a6:	bf6080e7          	jalr	-1034(ra) # 80000c98 <release>
  acquire(lk);
    800020aa:	854a                	mv	a0,s2
    800020ac:	fffff097          	auipc	ra,0xfffff
    800020b0:	b38080e7          	jalr	-1224(ra) # 80000be4 <acquire>
}
    800020b4:	70a2                	ld	ra,40(sp)
    800020b6:	7402                	ld	s0,32(sp)
    800020b8:	64e2                	ld	s1,24(sp)
    800020ba:	6942                	ld	s2,16(sp)
    800020bc:	69a2                	ld	s3,8(sp)
    800020be:	6145                	addi	sp,sp,48
    800020c0:	8082                	ret

00000000800020c2 <wait>:
{
    800020c2:	715d                	addi	sp,sp,-80
    800020c4:	e486                	sd	ra,72(sp)
    800020c6:	e0a2                	sd	s0,64(sp)
    800020c8:	fc26                	sd	s1,56(sp)
    800020ca:	f84a                	sd	s2,48(sp)
    800020cc:	f44e                	sd	s3,40(sp)
    800020ce:	f052                	sd	s4,32(sp)
    800020d0:	ec56                	sd	s5,24(sp)
    800020d2:	e85a                	sd	s6,16(sp)
    800020d4:	e45e                	sd	s7,8(sp)
    800020d6:	e062                	sd	s8,0(sp)
    800020d8:	0880                	addi	s0,sp,80
    800020da:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    800020dc:	00000097          	auipc	ra,0x0
    800020e0:	8d4080e7          	jalr	-1836(ra) # 800019b0 <myproc>
    800020e4:	892a                	mv	s2,a0
  acquire(&wait_lock);
    800020e6:	0000f517          	auipc	a0,0xf
    800020ea:	1d250513          	addi	a0,a0,466 # 800112b8 <wait_lock>
    800020ee:	fffff097          	auipc	ra,0xfffff
    800020f2:	af6080e7          	jalr	-1290(ra) # 80000be4 <acquire>
    havekids = 0;
    800020f6:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    800020f8:	4a15                	li	s4,5
    for(np = proc; np < &proc[NPROC]; np++){
    800020fa:	00015997          	auipc	s3,0x15
    800020fe:	fd698993          	addi	s3,s3,-42 # 800170d0 <tickslock>
        havekids = 1;
    80002102:	4a85                	li	s5,1
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002104:	0000fc17          	auipc	s8,0xf
    80002108:	1b4c0c13          	addi	s8,s8,436 # 800112b8 <wait_lock>
    havekids = 0;
    8000210c:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    8000210e:	0000f497          	auipc	s1,0xf
    80002112:	5c248493          	addi	s1,s1,1474 # 800116d0 <proc>
    80002116:	a0bd                	j	80002184 <wait+0xc2>
          pid = np->pid;
    80002118:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    8000211c:	000b0e63          	beqz	s6,80002138 <wait+0x76>
    80002120:	4691                	li	a3,4
    80002122:	02c48613          	addi	a2,s1,44
    80002126:	85da                	mv	a1,s6
    80002128:	05093503          	ld	a0,80(s2)
    8000212c:	fffff097          	auipc	ra,0xfffff
    80002130:	546080e7          	jalr	1350(ra) # 80001672 <copyout>
    80002134:	02054563          	bltz	a0,8000215e <wait+0x9c>
          freeproc(np);
    80002138:	8526                	mv	a0,s1
    8000213a:	00000097          	auipc	ra,0x0
    8000213e:	a1a080e7          	jalr	-1510(ra) # 80001b54 <freeproc>
          release(&np->lock);
    80002142:	8526                	mv	a0,s1
    80002144:	fffff097          	auipc	ra,0xfffff
    80002148:	b54080e7          	jalr	-1196(ra) # 80000c98 <release>
          release(&wait_lock);
    8000214c:	0000f517          	auipc	a0,0xf
    80002150:	16c50513          	addi	a0,a0,364 # 800112b8 <wait_lock>
    80002154:	fffff097          	auipc	ra,0xfffff
    80002158:	b44080e7          	jalr	-1212(ra) # 80000c98 <release>
          return pid;
    8000215c:	a09d                	j	800021c2 <wait+0x100>
            release(&np->lock);
    8000215e:	8526                	mv	a0,s1
    80002160:	fffff097          	auipc	ra,0xfffff
    80002164:	b38080e7          	jalr	-1224(ra) # 80000c98 <release>
            release(&wait_lock);
    80002168:	0000f517          	auipc	a0,0xf
    8000216c:	15050513          	addi	a0,a0,336 # 800112b8 <wait_lock>
    80002170:	fffff097          	auipc	ra,0xfffff
    80002174:	b28080e7          	jalr	-1240(ra) # 80000c98 <release>
            return -1;
    80002178:	59fd                	li	s3,-1
    8000217a:	a0a1                	j	800021c2 <wait+0x100>
    for(np = proc; np < &proc[NPROC]; np++){
    8000217c:	16848493          	addi	s1,s1,360
    80002180:	03348463          	beq	s1,s3,800021a8 <wait+0xe6>
      if(np->parent == p){
    80002184:	7c9c                	ld	a5,56(s1)
    80002186:	ff279be3          	bne	a5,s2,8000217c <wait+0xba>
        acquire(&np->lock);
    8000218a:	8526                	mv	a0,s1
    8000218c:	fffff097          	auipc	ra,0xfffff
    80002190:	a58080e7          	jalr	-1448(ra) # 80000be4 <acquire>
        if(np->state == ZOMBIE){
    80002194:	4c9c                	lw	a5,24(s1)
    80002196:	f94781e3          	beq	a5,s4,80002118 <wait+0x56>
        release(&np->lock);
    8000219a:	8526                	mv	a0,s1
    8000219c:	fffff097          	auipc	ra,0xfffff
    800021a0:	afc080e7          	jalr	-1284(ra) # 80000c98 <release>
        havekids = 1;
    800021a4:	8756                	mv	a4,s5
    800021a6:	bfd9                	j	8000217c <wait+0xba>
    if(!havekids || p->killed){
    800021a8:	c701                	beqz	a4,800021b0 <wait+0xee>
    800021aa:	02892783          	lw	a5,40(s2)
    800021ae:	c79d                	beqz	a5,800021dc <wait+0x11a>
      release(&wait_lock);
    800021b0:	0000f517          	auipc	a0,0xf
    800021b4:	10850513          	addi	a0,a0,264 # 800112b8 <wait_lock>
    800021b8:	fffff097          	auipc	ra,0xfffff
    800021bc:	ae0080e7          	jalr	-1312(ra) # 80000c98 <release>
      return -1;
    800021c0:	59fd                	li	s3,-1
}
    800021c2:	854e                	mv	a0,s3
    800021c4:	60a6                	ld	ra,72(sp)
    800021c6:	6406                	ld	s0,64(sp)
    800021c8:	74e2                	ld	s1,56(sp)
    800021ca:	7942                	ld	s2,48(sp)
    800021cc:	79a2                	ld	s3,40(sp)
    800021ce:	7a02                	ld	s4,32(sp)
    800021d0:	6ae2                	ld	s5,24(sp)
    800021d2:	6b42                	ld	s6,16(sp)
    800021d4:	6ba2                	ld	s7,8(sp)
    800021d6:	6c02                	ld	s8,0(sp)
    800021d8:	6161                	addi	sp,sp,80
    800021da:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800021dc:	85e2                	mv	a1,s8
    800021de:	854a                	mv	a0,s2
    800021e0:	00000097          	auipc	ra,0x0
    800021e4:	e7e080e7          	jalr	-386(ra) # 8000205e <sleep>
    havekids = 0;
    800021e8:	b715                	j	8000210c <wait+0x4a>

00000000800021ea <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    800021ea:	7139                	addi	sp,sp,-64
    800021ec:	fc06                	sd	ra,56(sp)
    800021ee:	f822                	sd	s0,48(sp)
    800021f0:	f426                	sd	s1,40(sp)
    800021f2:	f04a                	sd	s2,32(sp)
    800021f4:	ec4e                	sd	s3,24(sp)
    800021f6:	e852                	sd	s4,16(sp)
    800021f8:	e456                	sd	s5,8(sp)
    800021fa:	0080                	addi	s0,sp,64
    800021fc:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    800021fe:	0000f497          	auipc	s1,0xf
    80002202:	4d248493          	addi	s1,s1,1234 # 800116d0 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    80002206:	4989                	li	s3,2
        p->state = RUNNABLE;
    80002208:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    8000220a:	00015917          	auipc	s2,0x15
    8000220e:	ec690913          	addi	s2,s2,-314 # 800170d0 <tickslock>
    80002212:	a821                	j	8000222a <wakeup+0x40>
        p->state = RUNNABLE;
    80002214:	0154ac23          	sw	s5,24(s1)
      }
      release(&p->lock);
    80002218:	8526                	mv	a0,s1
    8000221a:	fffff097          	auipc	ra,0xfffff
    8000221e:	a7e080e7          	jalr	-1410(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80002222:	16848493          	addi	s1,s1,360
    80002226:	03248463          	beq	s1,s2,8000224e <wakeup+0x64>
    if(p != myproc()){
    8000222a:	fffff097          	auipc	ra,0xfffff
    8000222e:	786080e7          	jalr	1926(ra) # 800019b0 <myproc>
    80002232:	fea488e3          	beq	s1,a0,80002222 <wakeup+0x38>
      acquire(&p->lock);
    80002236:	8526                	mv	a0,s1
    80002238:	fffff097          	auipc	ra,0xfffff
    8000223c:	9ac080e7          	jalr	-1620(ra) # 80000be4 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    80002240:	4c9c                	lw	a5,24(s1)
    80002242:	fd379be3          	bne	a5,s3,80002218 <wakeup+0x2e>
    80002246:	709c                	ld	a5,32(s1)
    80002248:	fd4798e3          	bne	a5,s4,80002218 <wakeup+0x2e>
    8000224c:	b7e1                	j	80002214 <wakeup+0x2a>
    }
  }
}
    8000224e:	70e2                	ld	ra,56(sp)
    80002250:	7442                	ld	s0,48(sp)
    80002252:	74a2                	ld	s1,40(sp)
    80002254:	7902                	ld	s2,32(sp)
    80002256:	69e2                	ld	s3,24(sp)
    80002258:	6a42                	ld	s4,16(sp)
    8000225a:	6aa2                	ld	s5,8(sp)
    8000225c:	6121                	addi	sp,sp,64
    8000225e:	8082                	ret

0000000080002260 <reparent>:
{
    80002260:	7179                	addi	sp,sp,-48
    80002262:	f406                	sd	ra,40(sp)
    80002264:	f022                	sd	s0,32(sp)
    80002266:	ec26                	sd	s1,24(sp)
    80002268:	e84a                	sd	s2,16(sp)
    8000226a:	e44e                	sd	s3,8(sp)
    8000226c:	e052                	sd	s4,0(sp)
    8000226e:	1800                	addi	s0,sp,48
    80002270:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002272:	0000f497          	auipc	s1,0xf
    80002276:	45e48493          	addi	s1,s1,1118 # 800116d0 <proc>
      pp->parent = initproc;
    8000227a:	00007a17          	auipc	s4,0x7
    8000227e:	daea0a13          	addi	s4,s4,-594 # 80009028 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002282:	00015997          	auipc	s3,0x15
    80002286:	e4e98993          	addi	s3,s3,-434 # 800170d0 <tickslock>
    8000228a:	a029                	j	80002294 <reparent+0x34>
    8000228c:	16848493          	addi	s1,s1,360
    80002290:	01348d63          	beq	s1,s3,800022aa <reparent+0x4a>
    if(pp->parent == p){
    80002294:	7c9c                	ld	a5,56(s1)
    80002296:	ff279be3          	bne	a5,s2,8000228c <reparent+0x2c>
      pp->parent = initproc;
    8000229a:	000a3503          	ld	a0,0(s4)
    8000229e:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    800022a0:	00000097          	auipc	ra,0x0
    800022a4:	f4a080e7          	jalr	-182(ra) # 800021ea <wakeup>
    800022a8:	b7d5                	j	8000228c <reparent+0x2c>
}
    800022aa:	70a2                	ld	ra,40(sp)
    800022ac:	7402                	ld	s0,32(sp)
    800022ae:	64e2                	ld	s1,24(sp)
    800022b0:	6942                	ld	s2,16(sp)
    800022b2:	69a2                	ld	s3,8(sp)
    800022b4:	6a02                	ld	s4,0(sp)
    800022b6:	6145                	addi	sp,sp,48
    800022b8:	8082                	ret

00000000800022ba <exit>:
{
    800022ba:	7179                	addi	sp,sp,-48
    800022bc:	f406                	sd	ra,40(sp)
    800022be:	f022                	sd	s0,32(sp)
    800022c0:	ec26                	sd	s1,24(sp)
    800022c2:	e84a                	sd	s2,16(sp)
    800022c4:	e44e                	sd	s3,8(sp)
    800022c6:	e052                	sd	s4,0(sp)
    800022c8:	1800                	addi	s0,sp,48
    800022ca:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    800022cc:	fffff097          	auipc	ra,0xfffff
    800022d0:	6e4080e7          	jalr	1764(ra) # 800019b0 <myproc>
    800022d4:	89aa                	mv	s3,a0
  if(p == initproc)
    800022d6:	00007797          	auipc	a5,0x7
    800022da:	d527b783          	ld	a5,-686(a5) # 80009028 <initproc>
    800022de:	0d050493          	addi	s1,a0,208
    800022e2:	15050913          	addi	s2,a0,336
    800022e6:	02a79363          	bne	a5,a0,8000230c <exit+0x52>
    panic("init exiting");
    800022ea:	00006517          	auipc	a0,0x6
    800022ee:	f7650513          	addi	a0,a0,-138 # 80008260 <digits+0x220>
    800022f2:	ffffe097          	auipc	ra,0xffffe
    800022f6:	24c080e7          	jalr	588(ra) # 8000053e <panic>
      fileclose(f);
    800022fa:	00002097          	auipc	ra,0x2
    800022fe:	164080e7          	jalr	356(ra) # 8000445e <fileclose>
      p->ofile[fd] = 0;
    80002302:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    80002306:	04a1                	addi	s1,s1,8
    80002308:	01248563          	beq	s1,s2,80002312 <exit+0x58>
    if(p->ofile[fd]){
    8000230c:	6088                	ld	a0,0(s1)
    8000230e:	f575                	bnez	a0,800022fa <exit+0x40>
    80002310:	bfdd                	j	80002306 <exit+0x4c>
  begin_op();
    80002312:	00002097          	auipc	ra,0x2
    80002316:	c80080e7          	jalr	-896(ra) # 80003f92 <begin_op>
  iput(p->cwd);
    8000231a:	1509b503          	ld	a0,336(s3)
    8000231e:	00001097          	auipc	ra,0x1
    80002322:	45c080e7          	jalr	1116(ra) # 8000377a <iput>
  end_op();
    80002326:	00002097          	auipc	ra,0x2
    8000232a:	cec080e7          	jalr	-788(ra) # 80004012 <end_op>
  p->cwd = 0;
    8000232e:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    80002332:	0000f497          	auipc	s1,0xf
    80002336:	f8648493          	addi	s1,s1,-122 # 800112b8 <wait_lock>
    8000233a:	8526                	mv	a0,s1
    8000233c:	fffff097          	auipc	ra,0xfffff
    80002340:	8a8080e7          	jalr	-1880(ra) # 80000be4 <acquire>
  reparent(p);
    80002344:	854e                	mv	a0,s3
    80002346:	00000097          	auipc	ra,0x0
    8000234a:	f1a080e7          	jalr	-230(ra) # 80002260 <reparent>
  wakeup(p->parent);
    8000234e:	0389b503          	ld	a0,56(s3)
    80002352:	00000097          	auipc	ra,0x0
    80002356:	e98080e7          	jalr	-360(ra) # 800021ea <wakeup>
  acquire(&p->lock);
    8000235a:	854e                	mv	a0,s3
    8000235c:	fffff097          	auipc	ra,0xfffff
    80002360:	888080e7          	jalr	-1912(ra) # 80000be4 <acquire>
  p->xstate = status;
    80002364:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    80002368:	4795                	li	a5,5
    8000236a:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    8000236e:	8526                	mv	a0,s1
    80002370:	fffff097          	auipc	ra,0xfffff
    80002374:	928080e7          	jalr	-1752(ra) # 80000c98 <release>
  sched();
    80002378:	00000097          	auipc	ra,0x0
    8000237c:	bd4080e7          	jalr	-1068(ra) # 80001f4c <sched>
  panic("zombie exit");
    80002380:	00006517          	auipc	a0,0x6
    80002384:	ef050513          	addi	a0,a0,-272 # 80008270 <digits+0x230>
    80002388:	ffffe097          	auipc	ra,0xffffe
    8000238c:	1b6080e7          	jalr	438(ra) # 8000053e <panic>

0000000080002390 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    80002390:	7179                	addi	sp,sp,-48
    80002392:	f406                	sd	ra,40(sp)
    80002394:	f022                	sd	s0,32(sp)
    80002396:	ec26                	sd	s1,24(sp)
    80002398:	e84a                	sd	s2,16(sp)
    8000239a:	e44e                	sd	s3,8(sp)
    8000239c:	1800                	addi	s0,sp,48
    8000239e:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    800023a0:	0000f497          	auipc	s1,0xf
    800023a4:	33048493          	addi	s1,s1,816 # 800116d0 <proc>
    800023a8:	00015997          	auipc	s3,0x15
    800023ac:	d2898993          	addi	s3,s3,-728 # 800170d0 <tickslock>
    acquire(&p->lock);
    800023b0:	8526                	mv	a0,s1
    800023b2:	fffff097          	auipc	ra,0xfffff
    800023b6:	832080e7          	jalr	-1998(ra) # 80000be4 <acquire>
    if(p->pid == pid){
    800023ba:	589c                	lw	a5,48(s1)
    800023bc:	01278d63          	beq	a5,s2,800023d6 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    800023c0:	8526                	mv	a0,s1
    800023c2:	fffff097          	auipc	ra,0xfffff
    800023c6:	8d6080e7          	jalr	-1834(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    800023ca:	16848493          	addi	s1,s1,360
    800023ce:	ff3491e3          	bne	s1,s3,800023b0 <kill+0x20>
  }
  return -1;
    800023d2:	557d                	li	a0,-1
    800023d4:	a829                	j	800023ee <kill+0x5e>
      p->killed = 1;
    800023d6:	4785                	li	a5,1
    800023d8:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    800023da:	4c98                	lw	a4,24(s1)
    800023dc:	4789                	li	a5,2
    800023de:	00f70f63          	beq	a4,a5,800023fc <kill+0x6c>
      release(&p->lock);
    800023e2:	8526                	mv	a0,s1
    800023e4:	fffff097          	auipc	ra,0xfffff
    800023e8:	8b4080e7          	jalr	-1868(ra) # 80000c98 <release>
      return 0;
    800023ec:	4501                	li	a0,0
}
    800023ee:	70a2                	ld	ra,40(sp)
    800023f0:	7402                	ld	s0,32(sp)
    800023f2:	64e2                	ld	s1,24(sp)
    800023f4:	6942                	ld	s2,16(sp)
    800023f6:	69a2                	ld	s3,8(sp)
    800023f8:	6145                	addi	sp,sp,48
    800023fa:	8082                	ret
        p->state = RUNNABLE;
    800023fc:	478d                	li	a5,3
    800023fe:	cc9c                	sw	a5,24(s1)
    80002400:	b7cd                	j	800023e2 <kill+0x52>

0000000080002402 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002402:	7179                	addi	sp,sp,-48
    80002404:	f406                	sd	ra,40(sp)
    80002406:	f022                	sd	s0,32(sp)
    80002408:	ec26                	sd	s1,24(sp)
    8000240a:	e84a                	sd	s2,16(sp)
    8000240c:	e44e                	sd	s3,8(sp)
    8000240e:	e052                	sd	s4,0(sp)
    80002410:	1800                	addi	s0,sp,48
    80002412:	84aa                	mv	s1,a0
    80002414:	892e                	mv	s2,a1
    80002416:	89b2                	mv	s3,a2
    80002418:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    8000241a:	fffff097          	auipc	ra,0xfffff
    8000241e:	596080e7          	jalr	1430(ra) # 800019b0 <myproc>
  if(user_dst){
    80002422:	c08d                	beqz	s1,80002444 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    80002424:	86d2                	mv	a3,s4
    80002426:	864e                	mv	a2,s3
    80002428:	85ca                	mv	a1,s2
    8000242a:	6928                	ld	a0,80(a0)
    8000242c:	fffff097          	auipc	ra,0xfffff
    80002430:	246080e7          	jalr	582(ra) # 80001672 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002434:	70a2                	ld	ra,40(sp)
    80002436:	7402                	ld	s0,32(sp)
    80002438:	64e2                	ld	s1,24(sp)
    8000243a:	6942                	ld	s2,16(sp)
    8000243c:	69a2                	ld	s3,8(sp)
    8000243e:	6a02                	ld	s4,0(sp)
    80002440:	6145                	addi	sp,sp,48
    80002442:	8082                	ret
    memmove((char *)dst, src, len);
    80002444:	000a061b          	sext.w	a2,s4
    80002448:	85ce                	mv	a1,s3
    8000244a:	854a                	mv	a0,s2
    8000244c:	fffff097          	auipc	ra,0xfffff
    80002450:	8f4080e7          	jalr	-1804(ra) # 80000d40 <memmove>
    return 0;
    80002454:	8526                	mv	a0,s1
    80002456:	bff9                	j	80002434 <either_copyout+0x32>

0000000080002458 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002458:	7179                	addi	sp,sp,-48
    8000245a:	f406                	sd	ra,40(sp)
    8000245c:	f022                	sd	s0,32(sp)
    8000245e:	ec26                	sd	s1,24(sp)
    80002460:	e84a                	sd	s2,16(sp)
    80002462:	e44e                	sd	s3,8(sp)
    80002464:	e052                	sd	s4,0(sp)
    80002466:	1800                	addi	s0,sp,48
    80002468:	892a                	mv	s2,a0
    8000246a:	84ae                	mv	s1,a1
    8000246c:	89b2                	mv	s3,a2
    8000246e:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002470:	fffff097          	auipc	ra,0xfffff
    80002474:	540080e7          	jalr	1344(ra) # 800019b0 <myproc>
  if(user_src){
    80002478:	c08d                	beqz	s1,8000249a <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    8000247a:	86d2                	mv	a3,s4
    8000247c:	864e                	mv	a2,s3
    8000247e:	85ca                	mv	a1,s2
    80002480:	6928                	ld	a0,80(a0)
    80002482:	fffff097          	auipc	ra,0xfffff
    80002486:	27c080e7          	jalr	636(ra) # 800016fe <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    8000248a:	70a2                	ld	ra,40(sp)
    8000248c:	7402                	ld	s0,32(sp)
    8000248e:	64e2                	ld	s1,24(sp)
    80002490:	6942                	ld	s2,16(sp)
    80002492:	69a2                	ld	s3,8(sp)
    80002494:	6a02                	ld	s4,0(sp)
    80002496:	6145                	addi	sp,sp,48
    80002498:	8082                	ret
    memmove(dst, (char*)src, len);
    8000249a:	000a061b          	sext.w	a2,s4
    8000249e:	85ce                	mv	a1,s3
    800024a0:	854a                	mv	a0,s2
    800024a2:	fffff097          	auipc	ra,0xfffff
    800024a6:	89e080e7          	jalr	-1890(ra) # 80000d40 <memmove>
    return 0;
    800024aa:	8526                	mv	a0,s1
    800024ac:	bff9                	j	8000248a <either_copyin+0x32>

00000000800024ae <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    800024ae:	715d                	addi	sp,sp,-80
    800024b0:	e486                	sd	ra,72(sp)
    800024b2:	e0a2                	sd	s0,64(sp)
    800024b4:	fc26                	sd	s1,56(sp)
    800024b6:	f84a                	sd	s2,48(sp)
    800024b8:	f44e                	sd	s3,40(sp)
    800024ba:	f052                	sd	s4,32(sp)
    800024bc:	ec56                	sd	s5,24(sp)
    800024be:	e85a                	sd	s6,16(sp)
    800024c0:	e45e                	sd	s7,8(sp)
    800024c2:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    800024c4:	00006517          	auipc	a0,0x6
    800024c8:	c0450513          	addi	a0,a0,-1020 # 800080c8 <digits+0x88>
    800024cc:	ffffe097          	auipc	ra,0xffffe
    800024d0:	0bc080e7          	jalr	188(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800024d4:	0000f497          	auipc	s1,0xf
    800024d8:	35448493          	addi	s1,s1,852 # 80011828 <proc+0x158>
    800024dc:	00015917          	auipc	s2,0x15
    800024e0:	d4c90913          	addi	s2,s2,-692 # 80017228 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800024e4:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    800024e6:	00006997          	auipc	s3,0x6
    800024ea:	d9a98993          	addi	s3,s3,-614 # 80008280 <digits+0x240>
    printf("%d %s %s", p->pid, state, p->name);
    800024ee:	00006a97          	auipc	s5,0x6
    800024f2:	d9aa8a93          	addi	s5,s5,-614 # 80008288 <digits+0x248>
    printf("\n");
    800024f6:	00006a17          	auipc	s4,0x6
    800024fa:	bd2a0a13          	addi	s4,s4,-1070 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800024fe:	00006b97          	auipc	s7,0x6
    80002502:	dc2b8b93          	addi	s7,s7,-574 # 800082c0 <states.1715>
    80002506:	a00d                	j	80002528 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002508:	ed86a583          	lw	a1,-296(a3)
    8000250c:	8556                	mv	a0,s5
    8000250e:	ffffe097          	auipc	ra,0xffffe
    80002512:	07a080e7          	jalr	122(ra) # 80000588 <printf>
    printf("\n");
    80002516:	8552                	mv	a0,s4
    80002518:	ffffe097          	auipc	ra,0xffffe
    8000251c:	070080e7          	jalr	112(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002520:	16848493          	addi	s1,s1,360
    80002524:	03248163          	beq	s1,s2,80002546 <procdump+0x98>
    if(p->state == UNUSED)
    80002528:	86a6                	mv	a3,s1
    8000252a:	ec04a783          	lw	a5,-320(s1)
    8000252e:	dbed                	beqz	a5,80002520 <procdump+0x72>
      state = "???";
    80002530:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002532:	fcfb6be3          	bltu	s6,a5,80002508 <procdump+0x5a>
    80002536:	1782                	slli	a5,a5,0x20
    80002538:	9381                	srli	a5,a5,0x20
    8000253a:	078e                	slli	a5,a5,0x3
    8000253c:	97de                	add	a5,a5,s7
    8000253e:	6390                	ld	a2,0(a5)
    80002540:	f661                	bnez	a2,80002508 <procdump+0x5a>
      state = "???";
    80002542:	864e                	mv	a2,s3
    80002544:	b7d1                	j	80002508 <procdump+0x5a>
  }
}
    80002546:	60a6                	ld	ra,72(sp)
    80002548:	6406                	ld	s0,64(sp)
    8000254a:	74e2                	ld	s1,56(sp)
    8000254c:	7942                	ld	s2,48(sp)
    8000254e:	79a2                	ld	s3,40(sp)
    80002550:	7a02                	ld	s4,32(sp)
    80002552:	6ae2                	ld	s5,24(sp)
    80002554:	6b42                	ld	s6,16(sp)
    80002556:	6ba2                	ld	s7,8(sp)
    80002558:	6161                	addi	sp,sp,80
    8000255a:	8082                	ret

000000008000255c <swtch>:
    8000255c:	00153023          	sd	ra,0(a0)
    80002560:	00253423          	sd	sp,8(a0)
    80002564:	e900                	sd	s0,16(a0)
    80002566:	ed04                	sd	s1,24(a0)
    80002568:	03253023          	sd	s2,32(a0)
    8000256c:	03353423          	sd	s3,40(a0)
    80002570:	03453823          	sd	s4,48(a0)
    80002574:	03553c23          	sd	s5,56(a0)
    80002578:	05653023          	sd	s6,64(a0)
    8000257c:	05753423          	sd	s7,72(a0)
    80002580:	05853823          	sd	s8,80(a0)
    80002584:	05953c23          	sd	s9,88(a0)
    80002588:	07a53023          	sd	s10,96(a0)
    8000258c:	07b53423          	sd	s11,104(a0)
    80002590:	0005b083          	ld	ra,0(a1)
    80002594:	0085b103          	ld	sp,8(a1)
    80002598:	6980                	ld	s0,16(a1)
    8000259a:	6d84                	ld	s1,24(a1)
    8000259c:	0205b903          	ld	s2,32(a1)
    800025a0:	0285b983          	ld	s3,40(a1)
    800025a4:	0305ba03          	ld	s4,48(a1)
    800025a8:	0385ba83          	ld	s5,56(a1)
    800025ac:	0405bb03          	ld	s6,64(a1)
    800025b0:	0485bb83          	ld	s7,72(a1)
    800025b4:	0505bc03          	ld	s8,80(a1)
    800025b8:	0585bc83          	ld	s9,88(a1)
    800025bc:	0605bd03          	ld	s10,96(a1)
    800025c0:	0685bd83          	ld	s11,104(a1)
    800025c4:	8082                	ret

00000000800025c6 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    800025c6:	1141                	addi	sp,sp,-16
    800025c8:	e406                	sd	ra,8(sp)
    800025ca:	e022                	sd	s0,0(sp)
    800025cc:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    800025ce:	00006597          	auipc	a1,0x6
    800025d2:	d2258593          	addi	a1,a1,-734 # 800082f0 <states.1715+0x30>
    800025d6:	00015517          	auipc	a0,0x15
    800025da:	afa50513          	addi	a0,a0,-1286 # 800170d0 <tickslock>
    800025de:	ffffe097          	auipc	ra,0xffffe
    800025e2:	576080e7          	jalr	1398(ra) # 80000b54 <initlock>
}
    800025e6:	60a2                	ld	ra,8(sp)
    800025e8:	6402                	ld	s0,0(sp)
    800025ea:	0141                	addi	sp,sp,16
    800025ec:	8082                	ret

00000000800025ee <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    800025ee:	1141                	addi	sp,sp,-16
    800025f0:	e422                	sd	s0,8(sp)
    800025f2:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    800025f4:	00003797          	auipc	a5,0x3
    800025f8:	48c78793          	addi	a5,a5,1164 # 80005a80 <kernelvec>
    800025fc:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002600:	6422                	ld	s0,8(sp)
    80002602:	0141                	addi	sp,sp,16
    80002604:	8082                	ret

0000000080002606 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002606:	1141                	addi	sp,sp,-16
    80002608:	e406                	sd	ra,8(sp)
    8000260a:	e022                	sd	s0,0(sp)
    8000260c:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    8000260e:	fffff097          	auipc	ra,0xfffff
    80002612:	3a2080e7          	jalr	930(ra) # 800019b0 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002616:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    8000261a:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000261c:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    80002620:	00005617          	auipc	a2,0x5
    80002624:	9e060613          	addi	a2,a2,-1568 # 80007000 <_trampoline>
    80002628:	00005697          	auipc	a3,0x5
    8000262c:	9d868693          	addi	a3,a3,-1576 # 80007000 <_trampoline>
    80002630:	8e91                	sub	a3,a3,a2
    80002632:	040007b7          	lui	a5,0x4000
    80002636:	17fd                	addi	a5,a5,-1
    80002638:	07b2                	slli	a5,a5,0xc
    8000263a:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000263c:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002640:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002642:	180026f3          	csrr	a3,satp
    80002646:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002648:	6d38                	ld	a4,88(a0)
    8000264a:	6134                	ld	a3,64(a0)
    8000264c:	6585                	lui	a1,0x1
    8000264e:	96ae                	add	a3,a3,a1
    80002650:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002652:	6d38                	ld	a4,88(a0)
    80002654:	00000697          	auipc	a3,0x0
    80002658:	13868693          	addi	a3,a3,312 # 8000278c <usertrap>
    8000265c:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    8000265e:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002660:	8692                	mv	a3,tp
    80002662:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002664:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002668:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    8000266c:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002670:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002674:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002676:	6f18                	ld	a4,24(a4)
    80002678:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    8000267c:	692c                	ld	a1,80(a0)
    8000267e:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    80002680:	00005717          	auipc	a4,0x5
    80002684:	a1070713          	addi	a4,a4,-1520 # 80007090 <userret>
    80002688:	8f11                	sub	a4,a4,a2
    8000268a:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    8000268c:	577d                	li	a4,-1
    8000268e:	177e                	slli	a4,a4,0x3f
    80002690:	8dd9                	or	a1,a1,a4
    80002692:	02000537          	lui	a0,0x2000
    80002696:	157d                	addi	a0,a0,-1
    80002698:	0536                	slli	a0,a0,0xd
    8000269a:	9782                	jalr	a5
}
    8000269c:	60a2                	ld	ra,8(sp)
    8000269e:	6402                	ld	s0,0(sp)
    800026a0:	0141                	addi	sp,sp,16
    800026a2:	8082                	ret

00000000800026a4 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    800026a4:	1101                	addi	sp,sp,-32
    800026a6:	ec06                	sd	ra,24(sp)
    800026a8:	e822                	sd	s0,16(sp)
    800026aa:	e426                	sd	s1,8(sp)
    800026ac:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    800026ae:	00015497          	auipc	s1,0x15
    800026b2:	a2248493          	addi	s1,s1,-1502 # 800170d0 <tickslock>
    800026b6:	8526                	mv	a0,s1
    800026b8:	ffffe097          	auipc	ra,0xffffe
    800026bc:	52c080e7          	jalr	1324(ra) # 80000be4 <acquire>
  ticks++;
    800026c0:	00007517          	auipc	a0,0x7
    800026c4:	97050513          	addi	a0,a0,-1680 # 80009030 <ticks>
    800026c8:	411c                	lw	a5,0(a0)
    800026ca:	2785                	addiw	a5,a5,1
    800026cc:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    800026ce:	00000097          	auipc	ra,0x0
    800026d2:	b1c080e7          	jalr	-1252(ra) # 800021ea <wakeup>
  release(&tickslock);
    800026d6:	8526                	mv	a0,s1
    800026d8:	ffffe097          	auipc	ra,0xffffe
    800026dc:	5c0080e7          	jalr	1472(ra) # 80000c98 <release>
}
    800026e0:	60e2                	ld	ra,24(sp)
    800026e2:	6442                	ld	s0,16(sp)
    800026e4:	64a2                	ld	s1,8(sp)
    800026e6:	6105                	addi	sp,sp,32
    800026e8:	8082                	ret

00000000800026ea <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    800026ea:	1101                	addi	sp,sp,-32
    800026ec:	ec06                	sd	ra,24(sp)
    800026ee:	e822                	sd	s0,16(sp)
    800026f0:	e426                	sd	s1,8(sp)
    800026f2:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    800026f4:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    800026f8:	00074d63          	bltz	a4,80002712 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    800026fc:	57fd                	li	a5,-1
    800026fe:	17fe                	slli	a5,a5,0x3f
    80002700:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002702:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002704:	06f70363          	beq	a4,a5,8000276a <devintr+0x80>
  }
}
    80002708:	60e2                	ld	ra,24(sp)
    8000270a:	6442                	ld	s0,16(sp)
    8000270c:	64a2                	ld	s1,8(sp)
    8000270e:	6105                	addi	sp,sp,32
    80002710:	8082                	ret
     (scause & 0xff) == 9){
    80002712:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002716:	46a5                	li	a3,9
    80002718:	fed792e3          	bne	a5,a3,800026fc <devintr+0x12>
    int irq = plic_claim();
    8000271c:	00003097          	auipc	ra,0x3
    80002720:	46c080e7          	jalr	1132(ra) # 80005b88 <plic_claim>
    80002724:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002726:	47a9                	li	a5,10
    80002728:	02f50763          	beq	a0,a5,80002756 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    8000272c:	4785                	li	a5,1
    8000272e:	02f50963          	beq	a0,a5,80002760 <devintr+0x76>
    return 1;
    80002732:	4505                	li	a0,1
    } else if(irq){
    80002734:	d8f1                	beqz	s1,80002708 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002736:	85a6                	mv	a1,s1
    80002738:	00006517          	auipc	a0,0x6
    8000273c:	bc050513          	addi	a0,a0,-1088 # 800082f8 <states.1715+0x38>
    80002740:	ffffe097          	auipc	ra,0xffffe
    80002744:	e48080e7          	jalr	-440(ra) # 80000588 <printf>
      plic_complete(irq);
    80002748:	8526                	mv	a0,s1
    8000274a:	00003097          	auipc	ra,0x3
    8000274e:	462080e7          	jalr	1122(ra) # 80005bac <plic_complete>
    return 1;
    80002752:	4505                	li	a0,1
    80002754:	bf55                	j	80002708 <devintr+0x1e>
      uartintr();
    80002756:	ffffe097          	auipc	ra,0xffffe
    8000275a:	252080e7          	jalr	594(ra) # 800009a8 <uartintr>
    8000275e:	b7ed                	j	80002748 <devintr+0x5e>
      virtio_disk_intr();
    80002760:	00004097          	auipc	ra,0x4
    80002764:	92c080e7          	jalr	-1748(ra) # 8000608c <virtio_disk_intr>
    80002768:	b7c5                	j	80002748 <devintr+0x5e>
    if(cpuid() == 0){
    8000276a:	fffff097          	auipc	ra,0xfffff
    8000276e:	21a080e7          	jalr	538(ra) # 80001984 <cpuid>
    80002772:	c901                	beqz	a0,80002782 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002774:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002778:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    8000277a:	14479073          	csrw	sip,a5
    return 2;
    8000277e:	4509                	li	a0,2
    80002780:	b761                	j	80002708 <devintr+0x1e>
      clockintr();
    80002782:	00000097          	auipc	ra,0x0
    80002786:	f22080e7          	jalr	-222(ra) # 800026a4 <clockintr>
    8000278a:	b7ed                	j	80002774 <devintr+0x8a>

000000008000278c <usertrap>:
{
    8000278c:	1101                	addi	sp,sp,-32
    8000278e:	ec06                	sd	ra,24(sp)
    80002790:	e822                	sd	s0,16(sp)
    80002792:	e426                	sd	s1,8(sp)
    80002794:	e04a                	sd	s2,0(sp)
    80002796:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002798:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    8000279c:	1007f793          	andi	a5,a5,256
    800027a0:	e3ad                	bnez	a5,80002802 <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    800027a2:	00003797          	auipc	a5,0x3
    800027a6:	2de78793          	addi	a5,a5,734 # 80005a80 <kernelvec>
    800027aa:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    800027ae:	fffff097          	auipc	ra,0xfffff
    800027b2:	202080e7          	jalr	514(ra) # 800019b0 <myproc>
    800027b6:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    800027b8:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800027ba:	14102773          	csrr	a4,sepc
    800027be:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    800027c0:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    800027c4:	47a1                	li	a5,8
    800027c6:	04f71c63          	bne	a4,a5,8000281e <usertrap+0x92>
    if(p->killed)
    800027ca:	551c                	lw	a5,40(a0)
    800027cc:	e3b9                	bnez	a5,80002812 <usertrap+0x86>
    p->trapframe->epc += 4;
    800027ce:	6cb8                	ld	a4,88(s1)
    800027d0:	6f1c                	ld	a5,24(a4)
    800027d2:	0791                	addi	a5,a5,4
    800027d4:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800027d6:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800027da:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800027de:	10079073          	csrw	sstatus,a5
    syscall();
    800027e2:	00000097          	auipc	ra,0x0
    800027e6:	2e0080e7          	jalr	736(ra) # 80002ac2 <syscall>
  if(p->killed)
    800027ea:	549c                	lw	a5,40(s1)
    800027ec:	ebc1                	bnez	a5,8000287c <usertrap+0xf0>
  usertrapret();
    800027ee:	00000097          	auipc	ra,0x0
    800027f2:	e18080e7          	jalr	-488(ra) # 80002606 <usertrapret>
}
    800027f6:	60e2                	ld	ra,24(sp)
    800027f8:	6442                	ld	s0,16(sp)
    800027fa:	64a2                	ld	s1,8(sp)
    800027fc:	6902                	ld	s2,0(sp)
    800027fe:	6105                	addi	sp,sp,32
    80002800:	8082                	ret
    panic("usertrap: not from user mode");
    80002802:	00006517          	auipc	a0,0x6
    80002806:	b1650513          	addi	a0,a0,-1258 # 80008318 <states.1715+0x58>
    8000280a:	ffffe097          	auipc	ra,0xffffe
    8000280e:	d34080e7          	jalr	-716(ra) # 8000053e <panic>
      exit(-1);
    80002812:	557d                	li	a0,-1
    80002814:	00000097          	auipc	ra,0x0
    80002818:	aa6080e7          	jalr	-1370(ra) # 800022ba <exit>
    8000281c:	bf4d                	j	800027ce <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    8000281e:	00000097          	auipc	ra,0x0
    80002822:	ecc080e7          	jalr	-308(ra) # 800026ea <devintr>
    80002826:	892a                	mv	s2,a0
    80002828:	c501                	beqz	a0,80002830 <usertrap+0xa4>
  if(p->killed)
    8000282a:	549c                	lw	a5,40(s1)
    8000282c:	c3a1                	beqz	a5,8000286c <usertrap+0xe0>
    8000282e:	a815                	j	80002862 <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002830:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002834:	5890                	lw	a2,48(s1)
    80002836:	00006517          	auipc	a0,0x6
    8000283a:	b0250513          	addi	a0,a0,-1278 # 80008338 <states.1715+0x78>
    8000283e:	ffffe097          	auipc	ra,0xffffe
    80002842:	d4a080e7          	jalr	-694(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002846:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    8000284a:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    8000284e:	00006517          	auipc	a0,0x6
    80002852:	b1a50513          	addi	a0,a0,-1254 # 80008368 <states.1715+0xa8>
    80002856:	ffffe097          	auipc	ra,0xffffe
    8000285a:	d32080e7          	jalr	-718(ra) # 80000588 <printf>
    p->killed = 1;
    8000285e:	4785                	li	a5,1
    80002860:	d49c                	sw	a5,40(s1)
    exit(-1);
    80002862:	557d                	li	a0,-1
    80002864:	00000097          	auipc	ra,0x0
    80002868:	a56080e7          	jalr	-1450(ra) # 800022ba <exit>
  if(which_dev == 2)
    8000286c:	4789                	li	a5,2
    8000286e:	f8f910e3          	bne	s2,a5,800027ee <usertrap+0x62>
    yield();
    80002872:	fffff097          	auipc	ra,0xfffff
    80002876:	7b0080e7          	jalr	1968(ra) # 80002022 <yield>
    8000287a:	bf95                	j	800027ee <usertrap+0x62>
  int which_dev = 0;
    8000287c:	4901                	li	s2,0
    8000287e:	b7d5                	j	80002862 <usertrap+0xd6>

0000000080002880 <kerneltrap>:
{
    80002880:	7179                	addi	sp,sp,-48
    80002882:	f406                	sd	ra,40(sp)
    80002884:	f022                	sd	s0,32(sp)
    80002886:	ec26                	sd	s1,24(sp)
    80002888:	e84a                	sd	s2,16(sp)
    8000288a:	e44e                	sd	s3,8(sp)
    8000288c:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000288e:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002892:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002896:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    8000289a:	1004f793          	andi	a5,s1,256
    8000289e:	cb85                	beqz	a5,800028ce <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800028a0:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800028a4:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    800028a6:	ef85                	bnez	a5,800028de <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    800028a8:	00000097          	auipc	ra,0x0
    800028ac:	e42080e7          	jalr	-446(ra) # 800026ea <devintr>
    800028b0:	cd1d                	beqz	a0,800028ee <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    800028b2:	4789                	li	a5,2
    800028b4:	06f50a63          	beq	a0,a5,80002928 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    800028b8:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800028bc:	10049073          	csrw	sstatus,s1
}
    800028c0:	70a2                	ld	ra,40(sp)
    800028c2:	7402                	ld	s0,32(sp)
    800028c4:	64e2                	ld	s1,24(sp)
    800028c6:	6942                	ld	s2,16(sp)
    800028c8:	69a2                	ld	s3,8(sp)
    800028ca:	6145                	addi	sp,sp,48
    800028cc:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    800028ce:	00006517          	auipc	a0,0x6
    800028d2:	aba50513          	addi	a0,a0,-1350 # 80008388 <states.1715+0xc8>
    800028d6:	ffffe097          	auipc	ra,0xffffe
    800028da:	c68080e7          	jalr	-920(ra) # 8000053e <panic>
    panic("kerneltrap: interrupts enabled");
    800028de:	00006517          	auipc	a0,0x6
    800028e2:	ad250513          	addi	a0,a0,-1326 # 800083b0 <states.1715+0xf0>
    800028e6:	ffffe097          	auipc	ra,0xffffe
    800028ea:	c58080e7          	jalr	-936(ra) # 8000053e <panic>
    printf("scause %p\n", scause);
    800028ee:	85ce                	mv	a1,s3
    800028f0:	00006517          	auipc	a0,0x6
    800028f4:	ae050513          	addi	a0,a0,-1312 # 800083d0 <states.1715+0x110>
    800028f8:	ffffe097          	auipc	ra,0xffffe
    800028fc:	c90080e7          	jalr	-880(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002900:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002904:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002908:	00006517          	auipc	a0,0x6
    8000290c:	ad850513          	addi	a0,a0,-1320 # 800083e0 <states.1715+0x120>
    80002910:	ffffe097          	auipc	ra,0xffffe
    80002914:	c78080e7          	jalr	-904(ra) # 80000588 <printf>
    panic("kerneltrap");
    80002918:	00006517          	auipc	a0,0x6
    8000291c:	ae050513          	addi	a0,a0,-1312 # 800083f8 <states.1715+0x138>
    80002920:	ffffe097          	auipc	ra,0xffffe
    80002924:	c1e080e7          	jalr	-994(ra) # 8000053e <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002928:	fffff097          	auipc	ra,0xfffff
    8000292c:	088080e7          	jalr	136(ra) # 800019b0 <myproc>
    80002930:	d541                	beqz	a0,800028b8 <kerneltrap+0x38>
    80002932:	fffff097          	auipc	ra,0xfffff
    80002936:	07e080e7          	jalr	126(ra) # 800019b0 <myproc>
    8000293a:	4d18                	lw	a4,24(a0)
    8000293c:	4791                	li	a5,4
    8000293e:	f6f71de3          	bne	a4,a5,800028b8 <kerneltrap+0x38>
    yield();
    80002942:	fffff097          	auipc	ra,0xfffff
    80002946:	6e0080e7          	jalr	1760(ra) # 80002022 <yield>
    8000294a:	b7bd                	j	800028b8 <kerneltrap+0x38>

000000008000294c <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    8000294c:	1101                	addi	sp,sp,-32
    8000294e:	ec06                	sd	ra,24(sp)
    80002950:	e822                	sd	s0,16(sp)
    80002952:	e426                	sd	s1,8(sp)
    80002954:	1000                	addi	s0,sp,32
    80002956:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002958:	fffff097          	auipc	ra,0xfffff
    8000295c:	058080e7          	jalr	88(ra) # 800019b0 <myproc>
  switch (n) {
    80002960:	4795                	li	a5,5
    80002962:	0497e163          	bltu	a5,s1,800029a4 <argraw+0x58>
    80002966:	048a                	slli	s1,s1,0x2
    80002968:	00006717          	auipc	a4,0x6
    8000296c:	ac870713          	addi	a4,a4,-1336 # 80008430 <states.1715+0x170>
    80002970:	94ba                	add	s1,s1,a4
    80002972:	409c                	lw	a5,0(s1)
    80002974:	97ba                	add	a5,a5,a4
    80002976:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002978:	6d3c                	ld	a5,88(a0)
    8000297a:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    8000297c:	60e2                	ld	ra,24(sp)
    8000297e:	6442                	ld	s0,16(sp)
    80002980:	64a2                	ld	s1,8(sp)
    80002982:	6105                	addi	sp,sp,32
    80002984:	8082                	ret
    return p->trapframe->a1;
    80002986:	6d3c                	ld	a5,88(a0)
    80002988:	7fa8                	ld	a0,120(a5)
    8000298a:	bfcd                	j	8000297c <argraw+0x30>
    return p->trapframe->a2;
    8000298c:	6d3c                	ld	a5,88(a0)
    8000298e:	63c8                	ld	a0,128(a5)
    80002990:	b7f5                	j	8000297c <argraw+0x30>
    return p->trapframe->a3;
    80002992:	6d3c                	ld	a5,88(a0)
    80002994:	67c8                	ld	a0,136(a5)
    80002996:	b7dd                	j	8000297c <argraw+0x30>
    return p->trapframe->a4;
    80002998:	6d3c                	ld	a5,88(a0)
    8000299a:	6bc8                	ld	a0,144(a5)
    8000299c:	b7c5                	j	8000297c <argraw+0x30>
    return p->trapframe->a5;
    8000299e:	6d3c                	ld	a5,88(a0)
    800029a0:	6fc8                	ld	a0,152(a5)
    800029a2:	bfe9                	j	8000297c <argraw+0x30>
  panic("argraw");
    800029a4:	00006517          	auipc	a0,0x6
    800029a8:	a6450513          	addi	a0,a0,-1436 # 80008408 <states.1715+0x148>
    800029ac:	ffffe097          	auipc	ra,0xffffe
    800029b0:	b92080e7          	jalr	-1134(ra) # 8000053e <panic>

00000000800029b4 <fetchaddr>:
{
    800029b4:	1101                	addi	sp,sp,-32
    800029b6:	ec06                	sd	ra,24(sp)
    800029b8:	e822                	sd	s0,16(sp)
    800029ba:	e426                	sd	s1,8(sp)
    800029bc:	e04a                	sd	s2,0(sp)
    800029be:	1000                	addi	s0,sp,32
    800029c0:	84aa                	mv	s1,a0
    800029c2:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800029c4:	fffff097          	auipc	ra,0xfffff
    800029c8:	fec080e7          	jalr	-20(ra) # 800019b0 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    800029cc:	653c                	ld	a5,72(a0)
    800029ce:	02f4f863          	bgeu	s1,a5,800029fe <fetchaddr+0x4a>
    800029d2:	00848713          	addi	a4,s1,8
    800029d6:	02e7e663          	bltu	a5,a4,80002a02 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    800029da:	46a1                	li	a3,8
    800029dc:	8626                	mv	a2,s1
    800029de:	85ca                	mv	a1,s2
    800029e0:	6928                	ld	a0,80(a0)
    800029e2:	fffff097          	auipc	ra,0xfffff
    800029e6:	d1c080e7          	jalr	-740(ra) # 800016fe <copyin>
    800029ea:	00a03533          	snez	a0,a0
    800029ee:	40a00533          	neg	a0,a0
}
    800029f2:	60e2                	ld	ra,24(sp)
    800029f4:	6442                	ld	s0,16(sp)
    800029f6:	64a2                	ld	s1,8(sp)
    800029f8:	6902                	ld	s2,0(sp)
    800029fa:	6105                	addi	sp,sp,32
    800029fc:	8082                	ret
    return -1;
    800029fe:	557d                	li	a0,-1
    80002a00:	bfcd                	j	800029f2 <fetchaddr+0x3e>
    80002a02:	557d                	li	a0,-1
    80002a04:	b7fd                	j	800029f2 <fetchaddr+0x3e>

0000000080002a06 <fetchstr>:
{
    80002a06:	7179                	addi	sp,sp,-48
    80002a08:	f406                	sd	ra,40(sp)
    80002a0a:	f022                	sd	s0,32(sp)
    80002a0c:	ec26                	sd	s1,24(sp)
    80002a0e:	e84a                	sd	s2,16(sp)
    80002a10:	e44e                	sd	s3,8(sp)
    80002a12:	1800                	addi	s0,sp,48
    80002a14:	892a                	mv	s2,a0
    80002a16:	84ae                	mv	s1,a1
    80002a18:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002a1a:	fffff097          	auipc	ra,0xfffff
    80002a1e:	f96080e7          	jalr	-106(ra) # 800019b0 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002a22:	86ce                	mv	a3,s3
    80002a24:	864a                	mv	a2,s2
    80002a26:	85a6                	mv	a1,s1
    80002a28:	6928                	ld	a0,80(a0)
    80002a2a:	fffff097          	auipc	ra,0xfffff
    80002a2e:	d60080e7          	jalr	-672(ra) # 8000178a <copyinstr>
  if(err < 0)
    80002a32:	00054763          	bltz	a0,80002a40 <fetchstr+0x3a>
  return strlen(buf);
    80002a36:	8526                	mv	a0,s1
    80002a38:	ffffe097          	auipc	ra,0xffffe
    80002a3c:	42c080e7          	jalr	1068(ra) # 80000e64 <strlen>
}
    80002a40:	70a2                	ld	ra,40(sp)
    80002a42:	7402                	ld	s0,32(sp)
    80002a44:	64e2                	ld	s1,24(sp)
    80002a46:	6942                	ld	s2,16(sp)
    80002a48:	69a2                	ld	s3,8(sp)
    80002a4a:	6145                	addi	sp,sp,48
    80002a4c:	8082                	ret

0000000080002a4e <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002a4e:	1101                	addi	sp,sp,-32
    80002a50:	ec06                	sd	ra,24(sp)
    80002a52:	e822                	sd	s0,16(sp)
    80002a54:	e426                	sd	s1,8(sp)
    80002a56:	1000                	addi	s0,sp,32
    80002a58:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002a5a:	00000097          	auipc	ra,0x0
    80002a5e:	ef2080e7          	jalr	-270(ra) # 8000294c <argraw>
    80002a62:	c088                	sw	a0,0(s1)
  return 0;
}
    80002a64:	4501                	li	a0,0
    80002a66:	60e2                	ld	ra,24(sp)
    80002a68:	6442                	ld	s0,16(sp)
    80002a6a:	64a2                	ld	s1,8(sp)
    80002a6c:	6105                	addi	sp,sp,32
    80002a6e:	8082                	ret

0000000080002a70 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002a70:	1101                	addi	sp,sp,-32
    80002a72:	ec06                	sd	ra,24(sp)
    80002a74:	e822                	sd	s0,16(sp)
    80002a76:	e426                	sd	s1,8(sp)
    80002a78:	1000                	addi	s0,sp,32
    80002a7a:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002a7c:	00000097          	auipc	ra,0x0
    80002a80:	ed0080e7          	jalr	-304(ra) # 8000294c <argraw>
    80002a84:	e088                	sd	a0,0(s1)
  return 0;
}
    80002a86:	4501                	li	a0,0
    80002a88:	60e2                	ld	ra,24(sp)
    80002a8a:	6442                	ld	s0,16(sp)
    80002a8c:	64a2                	ld	s1,8(sp)
    80002a8e:	6105                	addi	sp,sp,32
    80002a90:	8082                	ret

0000000080002a92 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002a92:	1101                	addi	sp,sp,-32
    80002a94:	ec06                	sd	ra,24(sp)
    80002a96:	e822                	sd	s0,16(sp)
    80002a98:	e426                	sd	s1,8(sp)
    80002a9a:	e04a                	sd	s2,0(sp)
    80002a9c:	1000                	addi	s0,sp,32
    80002a9e:	84ae                	mv	s1,a1
    80002aa0:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002aa2:	00000097          	auipc	ra,0x0
    80002aa6:	eaa080e7          	jalr	-342(ra) # 8000294c <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002aaa:	864a                	mv	a2,s2
    80002aac:	85a6                	mv	a1,s1
    80002aae:	00000097          	auipc	ra,0x0
    80002ab2:	f58080e7          	jalr	-168(ra) # 80002a06 <fetchstr>
}
    80002ab6:	60e2                	ld	ra,24(sp)
    80002ab8:	6442                	ld	s0,16(sp)
    80002aba:	64a2                	ld	s1,8(sp)
    80002abc:	6902                	ld	s2,0(sp)
    80002abe:	6105                	addi	sp,sp,32
    80002ac0:	8082                	ret

0000000080002ac2 <syscall>:
[SYS_close]   sys_close,
};

void
syscall(void)
{
    80002ac2:	1101                	addi	sp,sp,-32
    80002ac4:	ec06                	sd	ra,24(sp)
    80002ac6:	e822                	sd	s0,16(sp)
    80002ac8:	e426                	sd	s1,8(sp)
    80002aca:	e04a                	sd	s2,0(sp)
    80002acc:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002ace:	fffff097          	auipc	ra,0xfffff
    80002ad2:	ee2080e7          	jalr	-286(ra) # 800019b0 <myproc>
    80002ad6:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002ad8:	05853903          	ld	s2,88(a0)
    80002adc:	0a893783          	ld	a5,168(s2)
    80002ae0:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002ae4:	37fd                	addiw	a5,a5,-1
    80002ae6:	4751                	li	a4,20
    80002ae8:	00f76f63          	bltu	a4,a5,80002b06 <syscall+0x44>
    80002aec:	00369713          	slli	a4,a3,0x3
    80002af0:	00006797          	auipc	a5,0x6
    80002af4:	95878793          	addi	a5,a5,-1704 # 80008448 <syscalls>
    80002af8:	97ba                	add	a5,a5,a4
    80002afa:	639c                	ld	a5,0(a5)
    80002afc:	c789                	beqz	a5,80002b06 <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    80002afe:	9782                	jalr	a5
    80002b00:	06a93823          	sd	a0,112(s2)
    80002b04:	a839                	j	80002b22 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002b06:	15848613          	addi	a2,s1,344
    80002b0a:	588c                	lw	a1,48(s1)
    80002b0c:	00006517          	auipc	a0,0x6
    80002b10:	90450513          	addi	a0,a0,-1788 # 80008410 <states.1715+0x150>
    80002b14:	ffffe097          	auipc	ra,0xffffe
    80002b18:	a74080e7          	jalr	-1420(ra) # 80000588 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002b1c:	6cbc                	ld	a5,88(s1)
    80002b1e:	577d                	li	a4,-1
    80002b20:	fbb8                	sd	a4,112(a5)
  }
}
    80002b22:	60e2                	ld	ra,24(sp)
    80002b24:	6442                	ld	s0,16(sp)
    80002b26:	64a2                	ld	s1,8(sp)
    80002b28:	6902                	ld	s2,0(sp)
    80002b2a:	6105                	addi	sp,sp,32
    80002b2c:	8082                	ret

0000000080002b2e <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002b2e:	1101                	addi	sp,sp,-32
    80002b30:	ec06                	sd	ra,24(sp)
    80002b32:	e822                	sd	s0,16(sp)
    80002b34:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002b36:	fec40593          	addi	a1,s0,-20
    80002b3a:	4501                	li	a0,0
    80002b3c:	00000097          	auipc	ra,0x0
    80002b40:	f12080e7          	jalr	-238(ra) # 80002a4e <argint>
    return -1;
    80002b44:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002b46:	00054963          	bltz	a0,80002b58 <sys_exit+0x2a>
  exit(n);
    80002b4a:	fec42503          	lw	a0,-20(s0)
    80002b4e:	fffff097          	auipc	ra,0xfffff
    80002b52:	76c080e7          	jalr	1900(ra) # 800022ba <exit>
  return 0;  // not reached
    80002b56:	4781                	li	a5,0
}
    80002b58:	853e                	mv	a0,a5
    80002b5a:	60e2                	ld	ra,24(sp)
    80002b5c:	6442                	ld	s0,16(sp)
    80002b5e:	6105                	addi	sp,sp,32
    80002b60:	8082                	ret

0000000080002b62 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002b62:	1141                	addi	sp,sp,-16
    80002b64:	e406                	sd	ra,8(sp)
    80002b66:	e022                	sd	s0,0(sp)
    80002b68:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002b6a:	fffff097          	auipc	ra,0xfffff
    80002b6e:	e46080e7          	jalr	-442(ra) # 800019b0 <myproc>
}
    80002b72:	5908                	lw	a0,48(a0)
    80002b74:	60a2                	ld	ra,8(sp)
    80002b76:	6402                	ld	s0,0(sp)
    80002b78:	0141                	addi	sp,sp,16
    80002b7a:	8082                	ret

0000000080002b7c <sys_fork>:

uint64
sys_fork(void)
{
    80002b7c:	1141                	addi	sp,sp,-16
    80002b7e:	e406                	sd	ra,8(sp)
    80002b80:	e022                	sd	s0,0(sp)
    80002b82:	0800                	addi	s0,sp,16
  return fork();
    80002b84:	fffff097          	auipc	ra,0xfffff
    80002b88:	1ec080e7          	jalr	492(ra) # 80001d70 <fork>
}
    80002b8c:	60a2                	ld	ra,8(sp)
    80002b8e:	6402                	ld	s0,0(sp)
    80002b90:	0141                	addi	sp,sp,16
    80002b92:	8082                	ret

0000000080002b94 <sys_wait>:

uint64
sys_wait(void)
{
    80002b94:	1101                	addi	sp,sp,-32
    80002b96:	ec06                	sd	ra,24(sp)
    80002b98:	e822                	sd	s0,16(sp)
    80002b9a:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002b9c:	fe840593          	addi	a1,s0,-24
    80002ba0:	4501                	li	a0,0
    80002ba2:	00000097          	auipc	ra,0x0
    80002ba6:	ece080e7          	jalr	-306(ra) # 80002a70 <argaddr>
    80002baa:	87aa                	mv	a5,a0
    return -1;
    80002bac:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002bae:	0007c863          	bltz	a5,80002bbe <sys_wait+0x2a>
  return wait(p);
    80002bb2:	fe843503          	ld	a0,-24(s0)
    80002bb6:	fffff097          	auipc	ra,0xfffff
    80002bba:	50c080e7          	jalr	1292(ra) # 800020c2 <wait>
}
    80002bbe:	60e2                	ld	ra,24(sp)
    80002bc0:	6442                	ld	s0,16(sp)
    80002bc2:	6105                	addi	sp,sp,32
    80002bc4:	8082                	ret

0000000080002bc6 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002bc6:	7179                	addi	sp,sp,-48
    80002bc8:	f406                	sd	ra,40(sp)
    80002bca:	f022                	sd	s0,32(sp)
    80002bcc:	ec26                	sd	s1,24(sp)
    80002bce:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80002bd0:	fdc40593          	addi	a1,s0,-36
    80002bd4:	4501                	li	a0,0
    80002bd6:	00000097          	auipc	ra,0x0
    80002bda:	e78080e7          	jalr	-392(ra) # 80002a4e <argint>
    80002bde:	87aa                	mv	a5,a0
    return -1;
    80002be0:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    80002be2:	0207c063          	bltz	a5,80002c02 <sys_sbrk+0x3c>
  addr = myproc()->sz;
    80002be6:	fffff097          	auipc	ra,0xfffff
    80002bea:	dca080e7          	jalr	-566(ra) # 800019b0 <myproc>
    80002bee:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    80002bf0:	fdc42503          	lw	a0,-36(s0)
    80002bf4:	fffff097          	auipc	ra,0xfffff
    80002bf8:	108080e7          	jalr	264(ra) # 80001cfc <growproc>
    80002bfc:	00054863          	bltz	a0,80002c0c <sys_sbrk+0x46>
    return -1;
  return addr;
    80002c00:	8526                	mv	a0,s1
}
    80002c02:	70a2                	ld	ra,40(sp)
    80002c04:	7402                	ld	s0,32(sp)
    80002c06:	64e2                	ld	s1,24(sp)
    80002c08:	6145                	addi	sp,sp,48
    80002c0a:	8082                	ret
    return -1;
    80002c0c:	557d                	li	a0,-1
    80002c0e:	bfd5                	j	80002c02 <sys_sbrk+0x3c>

0000000080002c10 <sys_sleep>:

uint64
sys_sleep(void)
{
    80002c10:	7139                	addi	sp,sp,-64
    80002c12:	fc06                	sd	ra,56(sp)
    80002c14:	f822                	sd	s0,48(sp)
    80002c16:	f426                	sd	s1,40(sp)
    80002c18:	f04a                	sd	s2,32(sp)
    80002c1a:	ec4e                	sd	s3,24(sp)
    80002c1c:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80002c1e:	fcc40593          	addi	a1,s0,-52
    80002c22:	4501                	li	a0,0
    80002c24:	00000097          	auipc	ra,0x0
    80002c28:	e2a080e7          	jalr	-470(ra) # 80002a4e <argint>
    return -1;
    80002c2c:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002c2e:	06054563          	bltz	a0,80002c98 <sys_sleep+0x88>
  acquire(&tickslock);
    80002c32:	00014517          	auipc	a0,0x14
    80002c36:	49e50513          	addi	a0,a0,1182 # 800170d0 <tickslock>
    80002c3a:	ffffe097          	auipc	ra,0xffffe
    80002c3e:	faa080e7          	jalr	-86(ra) # 80000be4 <acquire>
  ticks0 = ticks;
    80002c42:	00006917          	auipc	s2,0x6
    80002c46:	3ee92903          	lw	s2,1006(s2) # 80009030 <ticks>
  while(ticks - ticks0 < n){
    80002c4a:	fcc42783          	lw	a5,-52(s0)
    80002c4e:	cf85                	beqz	a5,80002c86 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002c50:	00014997          	auipc	s3,0x14
    80002c54:	48098993          	addi	s3,s3,1152 # 800170d0 <tickslock>
    80002c58:	00006497          	auipc	s1,0x6
    80002c5c:	3d848493          	addi	s1,s1,984 # 80009030 <ticks>
    if(myproc()->killed){
    80002c60:	fffff097          	auipc	ra,0xfffff
    80002c64:	d50080e7          	jalr	-688(ra) # 800019b0 <myproc>
    80002c68:	551c                	lw	a5,40(a0)
    80002c6a:	ef9d                	bnez	a5,80002ca8 <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80002c6c:	85ce                	mv	a1,s3
    80002c6e:	8526                	mv	a0,s1
    80002c70:	fffff097          	auipc	ra,0xfffff
    80002c74:	3ee080e7          	jalr	1006(ra) # 8000205e <sleep>
  while(ticks - ticks0 < n){
    80002c78:	409c                	lw	a5,0(s1)
    80002c7a:	412787bb          	subw	a5,a5,s2
    80002c7e:	fcc42703          	lw	a4,-52(s0)
    80002c82:	fce7efe3          	bltu	a5,a4,80002c60 <sys_sleep+0x50>
  }
  release(&tickslock);
    80002c86:	00014517          	auipc	a0,0x14
    80002c8a:	44a50513          	addi	a0,a0,1098 # 800170d0 <tickslock>
    80002c8e:	ffffe097          	auipc	ra,0xffffe
    80002c92:	00a080e7          	jalr	10(ra) # 80000c98 <release>
  return 0;
    80002c96:	4781                	li	a5,0
}
    80002c98:	853e                	mv	a0,a5
    80002c9a:	70e2                	ld	ra,56(sp)
    80002c9c:	7442                	ld	s0,48(sp)
    80002c9e:	74a2                	ld	s1,40(sp)
    80002ca0:	7902                	ld	s2,32(sp)
    80002ca2:	69e2                	ld	s3,24(sp)
    80002ca4:	6121                	addi	sp,sp,64
    80002ca6:	8082                	ret
      release(&tickslock);
    80002ca8:	00014517          	auipc	a0,0x14
    80002cac:	42850513          	addi	a0,a0,1064 # 800170d0 <tickslock>
    80002cb0:	ffffe097          	auipc	ra,0xffffe
    80002cb4:	fe8080e7          	jalr	-24(ra) # 80000c98 <release>
      return -1;
    80002cb8:	57fd                	li	a5,-1
    80002cba:	bff9                	j	80002c98 <sys_sleep+0x88>

0000000080002cbc <sys_kill>:

uint64
sys_kill(void)
{
    80002cbc:	1101                	addi	sp,sp,-32
    80002cbe:	ec06                	sd	ra,24(sp)
    80002cc0:	e822                	sd	s0,16(sp)
    80002cc2:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80002cc4:	fec40593          	addi	a1,s0,-20
    80002cc8:	4501                	li	a0,0
    80002cca:	00000097          	auipc	ra,0x0
    80002cce:	d84080e7          	jalr	-636(ra) # 80002a4e <argint>
    80002cd2:	87aa                	mv	a5,a0
    return -1;
    80002cd4:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80002cd6:	0007c863          	bltz	a5,80002ce6 <sys_kill+0x2a>
  return kill(pid);
    80002cda:	fec42503          	lw	a0,-20(s0)
    80002cde:	fffff097          	auipc	ra,0xfffff
    80002ce2:	6b2080e7          	jalr	1714(ra) # 80002390 <kill>
}
    80002ce6:	60e2                	ld	ra,24(sp)
    80002ce8:	6442                	ld	s0,16(sp)
    80002cea:	6105                	addi	sp,sp,32
    80002cec:	8082                	ret

0000000080002cee <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002cee:	1101                	addi	sp,sp,-32
    80002cf0:	ec06                	sd	ra,24(sp)
    80002cf2:	e822                	sd	s0,16(sp)
    80002cf4:	e426                	sd	s1,8(sp)
    80002cf6:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002cf8:	00014517          	auipc	a0,0x14
    80002cfc:	3d850513          	addi	a0,a0,984 # 800170d0 <tickslock>
    80002d00:	ffffe097          	auipc	ra,0xffffe
    80002d04:	ee4080e7          	jalr	-284(ra) # 80000be4 <acquire>
  xticks = ticks;
    80002d08:	00006497          	auipc	s1,0x6
    80002d0c:	3284a483          	lw	s1,808(s1) # 80009030 <ticks>
  release(&tickslock);
    80002d10:	00014517          	auipc	a0,0x14
    80002d14:	3c050513          	addi	a0,a0,960 # 800170d0 <tickslock>
    80002d18:	ffffe097          	auipc	ra,0xffffe
    80002d1c:	f80080e7          	jalr	-128(ra) # 80000c98 <release>
  return xticks;
}
    80002d20:	02049513          	slli	a0,s1,0x20
    80002d24:	9101                	srli	a0,a0,0x20
    80002d26:	60e2                	ld	ra,24(sp)
    80002d28:	6442                	ld	s0,16(sp)
    80002d2a:	64a2                	ld	s1,8(sp)
    80002d2c:	6105                	addi	sp,sp,32
    80002d2e:	8082                	ret

0000000080002d30 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002d30:	7179                	addi	sp,sp,-48
    80002d32:	f406                	sd	ra,40(sp)
    80002d34:	f022                	sd	s0,32(sp)
    80002d36:	ec26                	sd	s1,24(sp)
    80002d38:	e84a                	sd	s2,16(sp)
    80002d3a:	e44e                	sd	s3,8(sp)
    80002d3c:	e052                	sd	s4,0(sp)
    80002d3e:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80002d40:	00005597          	auipc	a1,0x5
    80002d44:	7b858593          	addi	a1,a1,1976 # 800084f8 <syscalls+0xb0>
    80002d48:	00014517          	auipc	a0,0x14
    80002d4c:	3a050513          	addi	a0,a0,928 # 800170e8 <bcache>
    80002d50:	ffffe097          	auipc	ra,0xffffe
    80002d54:	e04080e7          	jalr	-508(ra) # 80000b54 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80002d58:	0001c797          	auipc	a5,0x1c
    80002d5c:	39078793          	addi	a5,a5,912 # 8001f0e8 <bcache+0x8000>
    80002d60:	0001c717          	auipc	a4,0x1c
    80002d64:	5f070713          	addi	a4,a4,1520 # 8001f350 <bcache+0x8268>
    80002d68:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80002d6c:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002d70:	00014497          	auipc	s1,0x14
    80002d74:	39048493          	addi	s1,s1,912 # 80017100 <bcache+0x18>
    b->next = bcache.head.next;
    80002d78:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80002d7a:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80002d7c:	00005a17          	auipc	s4,0x5
    80002d80:	784a0a13          	addi	s4,s4,1924 # 80008500 <syscalls+0xb8>
    b->next = bcache.head.next;
    80002d84:	2b893783          	ld	a5,696(s2)
    80002d88:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80002d8a:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80002d8e:	85d2                	mv	a1,s4
    80002d90:	01048513          	addi	a0,s1,16
    80002d94:	00001097          	auipc	ra,0x1
    80002d98:	4bc080e7          	jalr	1212(ra) # 80004250 <initsleeplock>
    bcache.head.next->prev = b;
    80002d9c:	2b893783          	ld	a5,696(s2)
    80002da0:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80002da2:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002da6:	45848493          	addi	s1,s1,1112
    80002daa:	fd349de3          	bne	s1,s3,80002d84 <binit+0x54>
  }
}
    80002dae:	70a2                	ld	ra,40(sp)
    80002db0:	7402                	ld	s0,32(sp)
    80002db2:	64e2                	ld	s1,24(sp)
    80002db4:	6942                	ld	s2,16(sp)
    80002db6:	69a2                	ld	s3,8(sp)
    80002db8:	6a02                	ld	s4,0(sp)
    80002dba:	6145                	addi	sp,sp,48
    80002dbc:	8082                	ret

0000000080002dbe <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80002dbe:	7179                	addi	sp,sp,-48
    80002dc0:	f406                	sd	ra,40(sp)
    80002dc2:	f022                	sd	s0,32(sp)
    80002dc4:	ec26                	sd	s1,24(sp)
    80002dc6:	e84a                	sd	s2,16(sp)
    80002dc8:	e44e                	sd	s3,8(sp)
    80002dca:	1800                	addi	s0,sp,48
    80002dcc:	89aa                	mv	s3,a0
    80002dce:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    80002dd0:	00014517          	auipc	a0,0x14
    80002dd4:	31850513          	addi	a0,a0,792 # 800170e8 <bcache>
    80002dd8:	ffffe097          	auipc	ra,0xffffe
    80002ddc:	e0c080e7          	jalr	-500(ra) # 80000be4 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80002de0:	0001c497          	auipc	s1,0x1c
    80002de4:	5c04b483          	ld	s1,1472(s1) # 8001f3a0 <bcache+0x82b8>
    80002de8:	0001c797          	auipc	a5,0x1c
    80002dec:	56878793          	addi	a5,a5,1384 # 8001f350 <bcache+0x8268>
    80002df0:	02f48f63          	beq	s1,a5,80002e2e <bread+0x70>
    80002df4:	873e                	mv	a4,a5
    80002df6:	a021                	j	80002dfe <bread+0x40>
    80002df8:	68a4                	ld	s1,80(s1)
    80002dfa:	02e48a63          	beq	s1,a4,80002e2e <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80002dfe:	449c                	lw	a5,8(s1)
    80002e00:	ff379ce3          	bne	a5,s3,80002df8 <bread+0x3a>
    80002e04:	44dc                	lw	a5,12(s1)
    80002e06:	ff2799e3          	bne	a5,s2,80002df8 <bread+0x3a>
      b->refcnt++;
    80002e0a:	40bc                	lw	a5,64(s1)
    80002e0c:	2785                	addiw	a5,a5,1
    80002e0e:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002e10:	00014517          	auipc	a0,0x14
    80002e14:	2d850513          	addi	a0,a0,728 # 800170e8 <bcache>
    80002e18:	ffffe097          	auipc	ra,0xffffe
    80002e1c:	e80080e7          	jalr	-384(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    80002e20:	01048513          	addi	a0,s1,16
    80002e24:	00001097          	auipc	ra,0x1
    80002e28:	466080e7          	jalr	1126(ra) # 8000428a <acquiresleep>
      return b;
    80002e2c:	a8b9                	j	80002e8a <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002e2e:	0001c497          	auipc	s1,0x1c
    80002e32:	56a4b483          	ld	s1,1386(s1) # 8001f398 <bcache+0x82b0>
    80002e36:	0001c797          	auipc	a5,0x1c
    80002e3a:	51a78793          	addi	a5,a5,1306 # 8001f350 <bcache+0x8268>
    80002e3e:	00f48863          	beq	s1,a5,80002e4e <bread+0x90>
    80002e42:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80002e44:	40bc                	lw	a5,64(s1)
    80002e46:	cf81                	beqz	a5,80002e5e <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002e48:	64a4                	ld	s1,72(s1)
    80002e4a:	fee49de3          	bne	s1,a4,80002e44 <bread+0x86>
  panic("bget: no buffers");
    80002e4e:	00005517          	auipc	a0,0x5
    80002e52:	6ba50513          	addi	a0,a0,1722 # 80008508 <syscalls+0xc0>
    80002e56:	ffffd097          	auipc	ra,0xffffd
    80002e5a:	6e8080e7          	jalr	1768(ra) # 8000053e <panic>
      b->dev = dev;
    80002e5e:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    80002e62:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    80002e66:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80002e6a:	4785                	li	a5,1
    80002e6c:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002e6e:	00014517          	auipc	a0,0x14
    80002e72:	27a50513          	addi	a0,a0,634 # 800170e8 <bcache>
    80002e76:	ffffe097          	auipc	ra,0xffffe
    80002e7a:	e22080e7          	jalr	-478(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    80002e7e:	01048513          	addi	a0,s1,16
    80002e82:	00001097          	auipc	ra,0x1
    80002e86:	408080e7          	jalr	1032(ra) # 8000428a <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80002e8a:	409c                	lw	a5,0(s1)
    80002e8c:	cb89                	beqz	a5,80002e9e <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80002e8e:	8526                	mv	a0,s1
    80002e90:	70a2                	ld	ra,40(sp)
    80002e92:	7402                	ld	s0,32(sp)
    80002e94:	64e2                	ld	s1,24(sp)
    80002e96:	6942                	ld	s2,16(sp)
    80002e98:	69a2                	ld	s3,8(sp)
    80002e9a:	6145                	addi	sp,sp,48
    80002e9c:	8082                	ret
    virtio_disk_rw(b, 0);
    80002e9e:	4581                	li	a1,0
    80002ea0:	8526                	mv	a0,s1
    80002ea2:	00003097          	auipc	ra,0x3
    80002ea6:	f14080e7          	jalr	-236(ra) # 80005db6 <virtio_disk_rw>
    b->valid = 1;
    80002eaa:	4785                	li	a5,1
    80002eac:	c09c                	sw	a5,0(s1)
  return b;
    80002eae:	b7c5                	j	80002e8e <bread+0xd0>

0000000080002eb0 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80002eb0:	1101                	addi	sp,sp,-32
    80002eb2:	ec06                	sd	ra,24(sp)
    80002eb4:	e822                	sd	s0,16(sp)
    80002eb6:	e426                	sd	s1,8(sp)
    80002eb8:	1000                	addi	s0,sp,32
    80002eba:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80002ebc:	0541                	addi	a0,a0,16
    80002ebe:	00001097          	auipc	ra,0x1
    80002ec2:	466080e7          	jalr	1126(ra) # 80004324 <holdingsleep>
    80002ec6:	cd01                	beqz	a0,80002ede <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80002ec8:	4585                	li	a1,1
    80002eca:	8526                	mv	a0,s1
    80002ecc:	00003097          	auipc	ra,0x3
    80002ed0:	eea080e7          	jalr	-278(ra) # 80005db6 <virtio_disk_rw>
}
    80002ed4:	60e2                	ld	ra,24(sp)
    80002ed6:	6442                	ld	s0,16(sp)
    80002ed8:	64a2                	ld	s1,8(sp)
    80002eda:	6105                	addi	sp,sp,32
    80002edc:	8082                	ret
    panic("bwrite");
    80002ede:	00005517          	auipc	a0,0x5
    80002ee2:	64250513          	addi	a0,a0,1602 # 80008520 <syscalls+0xd8>
    80002ee6:	ffffd097          	auipc	ra,0xffffd
    80002eea:	658080e7          	jalr	1624(ra) # 8000053e <panic>

0000000080002eee <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80002eee:	1101                	addi	sp,sp,-32
    80002ef0:	ec06                	sd	ra,24(sp)
    80002ef2:	e822                	sd	s0,16(sp)
    80002ef4:	e426                	sd	s1,8(sp)
    80002ef6:	e04a                	sd	s2,0(sp)
    80002ef8:	1000                	addi	s0,sp,32
    80002efa:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80002efc:	01050913          	addi	s2,a0,16
    80002f00:	854a                	mv	a0,s2
    80002f02:	00001097          	auipc	ra,0x1
    80002f06:	422080e7          	jalr	1058(ra) # 80004324 <holdingsleep>
    80002f0a:	c92d                	beqz	a0,80002f7c <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80002f0c:	854a                	mv	a0,s2
    80002f0e:	00001097          	auipc	ra,0x1
    80002f12:	3d2080e7          	jalr	978(ra) # 800042e0 <releasesleep>

  acquire(&bcache.lock);
    80002f16:	00014517          	auipc	a0,0x14
    80002f1a:	1d250513          	addi	a0,a0,466 # 800170e8 <bcache>
    80002f1e:	ffffe097          	auipc	ra,0xffffe
    80002f22:	cc6080e7          	jalr	-826(ra) # 80000be4 <acquire>
  b->refcnt--;
    80002f26:	40bc                	lw	a5,64(s1)
    80002f28:	37fd                	addiw	a5,a5,-1
    80002f2a:	0007871b          	sext.w	a4,a5
    80002f2e:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80002f30:	eb05                	bnez	a4,80002f60 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80002f32:	68bc                	ld	a5,80(s1)
    80002f34:	64b8                	ld	a4,72(s1)
    80002f36:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80002f38:	64bc                	ld	a5,72(s1)
    80002f3a:	68b8                	ld	a4,80(s1)
    80002f3c:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80002f3e:	0001c797          	auipc	a5,0x1c
    80002f42:	1aa78793          	addi	a5,a5,426 # 8001f0e8 <bcache+0x8000>
    80002f46:	2b87b703          	ld	a4,696(a5)
    80002f4a:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80002f4c:	0001c717          	auipc	a4,0x1c
    80002f50:	40470713          	addi	a4,a4,1028 # 8001f350 <bcache+0x8268>
    80002f54:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80002f56:	2b87b703          	ld	a4,696(a5)
    80002f5a:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80002f5c:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80002f60:	00014517          	auipc	a0,0x14
    80002f64:	18850513          	addi	a0,a0,392 # 800170e8 <bcache>
    80002f68:	ffffe097          	auipc	ra,0xffffe
    80002f6c:	d30080e7          	jalr	-720(ra) # 80000c98 <release>
}
    80002f70:	60e2                	ld	ra,24(sp)
    80002f72:	6442                	ld	s0,16(sp)
    80002f74:	64a2                	ld	s1,8(sp)
    80002f76:	6902                	ld	s2,0(sp)
    80002f78:	6105                	addi	sp,sp,32
    80002f7a:	8082                	ret
    panic("brelse");
    80002f7c:	00005517          	auipc	a0,0x5
    80002f80:	5ac50513          	addi	a0,a0,1452 # 80008528 <syscalls+0xe0>
    80002f84:	ffffd097          	auipc	ra,0xffffd
    80002f88:	5ba080e7          	jalr	1466(ra) # 8000053e <panic>

0000000080002f8c <bpin>:

void
bpin(struct buf *b) {
    80002f8c:	1101                	addi	sp,sp,-32
    80002f8e:	ec06                	sd	ra,24(sp)
    80002f90:	e822                	sd	s0,16(sp)
    80002f92:	e426                	sd	s1,8(sp)
    80002f94:	1000                	addi	s0,sp,32
    80002f96:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80002f98:	00014517          	auipc	a0,0x14
    80002f9c:	15050513          	addi	a0,a0,336 # 800170e8 <bcache>
    80002fa0:	ffffe097          	auipc	ra,0xffffe
    80002fa4:	c44080e7          	jalr	-956(ra) # 80000be4 <acquire>
  b->refcnt++;
    80002fa8:	40bc                	lw	a5,64(s1)
    80002faa:	2785                	addiw	a5,a5,1
    80002fac:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80002fae:	00014517          	auipc	a0,0x14
    80002fb2:	13a50513          	addi	a0,a0,314 # 800170e8 <bcache>
    80002fb6:	ffffe097          	auipc	ra,0xffffe
    80002fba:	ce2080e7          	jalr	-798(ra) # 80000c98 <release>
}
    80002fbe:	60e2                	ld	ra,24(sp)
    80002fc0:	6442                	ld	s0,16(sp)
    80002fc2:	64a2                	ld	s1,8(sp)
    80002fc4:	6105                	addi	sp,sp,32
    80002fc6:	8082                	ret

0000000080002fc8 <bunpin>:

void
bunpin(struct buf *b) {
    80002fc8:	1101                	addi	sp,sp,-32
    80002fca:	ec06                	sd	ra,24(sp)
    80002fcc:	e822                	sd	s0,16(sp)
    80002fce:	e426                	sd	s1,8(sp)
    80002fd0:	1000                	addi	s0,sp,32
    80002fd2:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80002fd4:	00014517          	auipc	a0,0x14
    80002fd8:	11450513          	addi	a0,a0,276 # 800170e8 <bcache>
    80002fdc:	ffffe097          	auipc	ra,0xffffe
    80002fe0:	c08080e7          	jalr	-1016(ra) # 80000be4 <acquire>
  b->refcnt--;
    80002fe4:	40bc                	lw	a5,64(s1)
    80002fe6:	37fd                	addiw	a5,a5,-1
    80002fe8:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80002fea:	00014517          	auipc	a0,0x14
    80002fee:	0fe50513          	addi	a0,a0,254 # 800170e8 <bcache>
    80002ff2:	ffffe097          	auipc	ra,0xffffe
    80002ff6:	ca6080e7          	jalr	-858(ra) # 80000c98 <release>
}
    80002ffa:	60e2                	ld	ra,24(sp)
    80002ffc:	6442                	ld	s0,16(sp)
    80002ffe:	64a2                	ld	s1,8(sp)
    80003000:	6105                	addi	sp,sp,32
    80003002:	8082                	ret

0000000080003004 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003004:	1101                	addi	sp,sp,-32
    80003006:	ec06                	sd	ra,24(sp)
    80003008:	e822                	sd	s0,16(sp)
    8000300a:	e426                	sd	s1,8(sp)
    8000300c:	e04a                	sd	s2,0(sp)
    8000300e:	1000                	addi	s0,sp,32
    80003010:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003012:	00d5d59b          	srliw	a1,a1,0xd
    80003016:	0001c797          	auipc	a5,0x1c
    8000301a:	7ae7a783          	lw	a5,1966(a5) # 8001f7c4 <sb+0x1c>
    8000301e:	9dbd                	addw	a1,a1,a5
    80003020:	00000097          	auipc	ra,0x0
    80003024:	d9e080e7          	jalr	-610(ra) # 80002dbe <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003028:	0074f713          	andi	a4,s1,7
    8000302c:	4785                	li	a5,1
    8000302e:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003032:	14ce                	slli	s1,s1,0x33
    80003034:	90d9                	srli	s1,s1,0x36
    80003036:	00950733          	add	a4,a0,s1
    8000303a:	05874703          	lbu	a4,88(a4)
    8000303e:	00e7f6b3          	and	a3,a5,a4
    80003042:	c69d                	beqz	a3,80003070 <bfree+0x6c>
    80003044:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003046:	94aa                	add	s1,s1,a0
    80003048:	fff7c793          	not	a5,a5
    8000304c:	8ff9                	and	a5,a5,a4
    8000304e:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    80003052:	00001097          	auipc	ra,0x1
    80003056:	118080e7          	jalr	280(ra) # 8000416a <log_write>
  brelse(bp);
    8000305a:	854a                	mv	a0,s2
    8000305c:	00000097          	auipc	ra,0x0
    80003060:	e92080e7          	jalr	-366(ra) # 80002eee <brelse>
}
    80003064:	60e2                	ld	ra,24(sp)
    80003066:	6442                	ld	s0,16(sp)
    80003068:	64a2                	ld	s1,8(sp)
    8000306a:	6902                	ld	s2,0(sp)
    8000306c:	6105                	addi	sp,sp,32
    8000306e:	8082                	ret
    panic("freeing free block");
    80003070:	00005517          	auipc	a0,0x5
    80003074:	4c050513          	addi	a0,a0,1216 # 80008530 <syscalls+0xe8>
    80003078:	ffffd097          	auipc	ra,0xffffd
    8000307c:	4c6080e7          	jalr	1222(ra) # 8000053e <panic>

0000000080003080 <balloc>:
{
    80003080:	711d                	addi	sp,sp,-96
    80003082:	ec86                	sd	ra,88(sp)
    80003084:	e8a2                	sd	s0,80(sp)
    80003086:	e4a6                	sd	s1,72(sp)
    80003088:	e0ca                	sd	s2,64(sp)
    8000308a:	fc4e                	sd	s3,56(sp)
    8000308c:	f852                	sd	s4,48(sp)
    8000308e:	f456                	sd	s5,40(sp)
    80003090:	f05a                	sd	s6,32(sp)
    80003092:	ec5e                	sd	s7,24(sp)
    80003094:	e862                	sd	s8,16(sp)
    80003096:	e466                	sd	s9,8(sp)
    80003098:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    8000309a:	0001c797          	auipc	a5,0x1c
    8000309e:	7127a783          	lw	a5,1810(a5) # 8001f7ac <sb+0x4>
    800030a2:	cbd1                	beqz	a5,80003136 <balloc+0xb6>
    800030a4:	8baa                	mv	s7,a0
    800030a6:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800030a8:	0001cb17          	auipc	s6,0x1c
    800030ac:	700b0b13          	addi	s6,s6,1792 # 8001f7a8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800030b0:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    800030b2:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800030b4:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    800030b6:	6c89                	lui	s9,0x2
    800030b8:	a831                	j	800030d4 <balloc+0x54>
    brelse(bp);
    800030ba:	854a                	mv	a0,s2
    800030bc:	00000097          	auipc	ra,0x0
    800030c0:	e32080e7          	jalr	-462(ra) # 80002eee <brelse>
  for(b = 0; b < sb.size; b += BPB){
    800030c4:	015c87bb          	addw	a5,s9,s5
    800030c8:	00078a9b          	sext.w	s5,a5
    800030cc:	004b2703          	lw	a4,4(s6)
    800030d0:	06eaf363          	bgeu	s5,a4,80003136 <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    800030d4:	41fad79b          	sraiw	a5,s5,0x1f
    800030d8:	0137d79b          	srliw	a5,a5,0x13
    800030dc:	015787bb          	addw	a5,a5,s5
    800030e0:	40d7d79b          	sraiw	a5,a5,0xd
    800030e4:	01cb2583          	lw	a1,28(s6)
    800030e8:	9dbd                	addw	a1,a1,a5
    800030ea:	855e                	mv	a0,s7
    800030ec:	00000097          	auipc	ra,0x0
    800030f0:	cd2080e7          	jalr	-814(ra) # 80002dbe <bread>
    800030f4:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800030f6:	004b2503          	lw	a0,4(s6)
    800030fa:	000a849b          	sext.w	s1,s5
    800030fe:	8662                	mv	a2,s8
    80003100:	faa4fde3          	bgeu	s1,a0,800030ba <balloc+0x3a>
      m = 1 << (bi % 8);
    80003104:	41f6579b          	sraiw	a5,a2,0x1f
    80003108:	01d7d69b          	srliw	a3,a5,0x1d
    8000310c:	00c6873b          	addw	a4,a3,a2
    80003110:	00777793          	andi	a5,a4,7
    80003114:	9f95                	subw	a5,a5,a3
    80003116:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    8000311a:	4037571b          	sraiw	a4,a4,0x3
    8000311e:	00e906b3          	add	a3,s2,a4
    80003122:	0586c683          	lbu	a3,88(a3)
    80003126:	00d7f5b3          	and	a1,a5,a3
    8000312a:	cd91                	beqz	a1,80003146 <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000312c:	2605                	addiw	a2,a2,1
    8000312e:	2485                	addiw	s1,s1,1
    80003130:	fd4618e3          	bne	a2,s4,80003100 <balloc+0x80>
    80003134:	b759                	j	800030ba <balloc+0x3a>
  panic("balloc: out of blocks");
    80003136:	00005517          	auipc	a0,0x5
    8000313a:	41250513          	addi	a0,a0,1042 # 80008548 <syscalls+0x100>
    8000313e:	ffffd097          	auipc	ra,0xffffd
    80003142:	400080e7          	jalr	1024(ra) # 8000053e <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003146:	974a                	add	a4,a4,s2
    80003148:	8fd5                	or	a5,a5,a3
    8000314a:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    8000314e:	854a                	mv	a0,s2
    80003150:	00001097          	auipc	ra,0x1
    80003154:	01a080e7          	jalr	26(ra) # 8000416a <log_write>
        brelse(bp);
    80003158:	854a                	mv	a0,s2
    8000315a:	00000097          	auipc	ra,0x0
    8000315e:	d94080e7          	jalr	-620(ra) # 80002eee <brelse>
  bp = bread(dev, bno);
    80003162:	85a6                	mv	a1,s1
    80003164:	855e                	mv	a0,s7
    80003166:	00000097          	auipc	ra,0x0
    8000316a:	c58080e7          	jalr	-936(ra) # 80002dbe <bread>
    8000316e:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003170:	40000613          	li	a2,1024
    80003174:	4581                	li	a1,0
    80003176:	05850513          	addi	a0,a0,88
    8000317a:	ffffe097          	auipc	ra,0xffffe
    8000317e:	b66080e7          	jalr	-1178(ra) # 80000ce0 <memset>
  log_write(bp);
    80003182:	854a                	mv	a0,s2
    80003184:	00001097          	auipc	ra,0x1
    80003188:	fe6080e7          	jalr	-26(ra) # 8000416a <log_write>
  brelse(bp);
    8000318c:	854a                	mv	a0,s2
    8000318e:	00000097          	auipc	ra,0x0
    80003192:	d60080e7          	jalr	-672(ra) # 80002eee <brelse>
}
    80003196:	8526                	mv	a0,s1
    80003198:	60e6                	ld	ra,88(sp)
    8000319a:	6446                	ld	s0,80(sp)
    8000319c:	64a6                	ld	s1,72(sp)
    8000319e:	6906                	ld	s2,64(sp)
    800031a0:	79e2                	ld	s3,56(sp)
    800031a2:	7a42                	ld	s4,48(sp)
    800031a4:	7aa2                	ld	s5,40(sp)
    800031a6:	7b02                	ld	s6,32(sp)
    800031a8:	6be2                	ld	s7,24(sp)
    800031aa:	6c42                	ld	s8,16(sp)
    800031ac:	6ca2                	ld	s9,8(sp)
    800031ae:	6125                	addi	sp,sp,96
    800031b0:	8082                	ret

00000000800031b2 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    800031b2:	7179                	addi	sp,sp,-48
    800031b4:	f406                	sd	ra,40(sp)
    800031b6:	f022                	sd	s0,32(sp)
    800031b8:	ec26                	sd	s1,24(sp)
    800031ba:	e84a                	sd	s2,16(sp)
    800031bc:	e44e                	sd	s3,8(sp)
    800031be:	e052                	sd	s4,0(sp)
    800031c0:	1800                	addi	s0,sp,48
    800031c2:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    800031c4:	47ad                	li	a5,11
    800031c6:	04b7fe63          	bgeu	a5,a1,80003222 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    800031ca:	ff45849b          	addiw	s1,a1,-12
    800031ce:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    800031d2:	0ff00793          	li	a5,255
    800031d6:	0ae7e363          	bltu	a5,a4,8000327c <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    800031da:	08052583          	lw	a1,128(a0)
    800031de:	c5ad                	beqz	a1,80003248 <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    800031e0:	00092503          	lw	a0,0(s2)
    800031e4:	00000097          	auipc	ra,0x0
    800031e8:	bda080e7          	jalr	-1062(ra) # 80002dbe <bread>
    800031ec:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    800031ee:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    800031f2:	02049593          	slli	a1,s1,0x20
    800031f6:	9181                	srli	a1,a1,0x20
    800031f8:	058a                	slli	a1,a1,0x2
    800031fa:	00b784b3          	add	s1,a5,a1
    800031fe:	0004a983          	lw	s3,0(s1)
    80003202:	04098d63          	beqz	s3,8000325c <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    80003206:	8552                	mv	a0,s4
    80003208:	00000097          	auipc	ra,0x0
    8000320c:	ce6080e7          	jalr	-794(ra) # 80002eee <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003210:	854e                	mv	a0,s3
    80003212:	70a2                	ld	ra,40(sp)
    80003214:	7402                	ld	s0,32(sp)
    80003216:	64e2                	ld	s1,24(sp)
    80003218:	6942                	ld	s2,16(sp)
    8000321a:	69a2                	ld	s3,8(sp)
    8000321c:	6a02                	ld	s4,0(sp)
    8000321e:	6145                	addi	sp,sp,48
    80003220:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    80003222:	02059493          	slli	s1,a1,0x20
    80003226:	9081                	srli	s1,s1,0x20
    80003228:	048a                	slli	s1,s1,0x2
    8000322a:	94aa                	add	s1,s1,a0
    8000322c:	0504a983          	lw	s3,80(s1)
    80003230:	fe0990e3          	bnez	s3,80003210 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    80003234:	4108                	lw	a0,0(a0)
    80003236:	00000097          	auipc	ra,0x0
    8000323a:	e4a080e7          	jalr	-438(ra) # 80003080 <balloc>
    8000323e:	0005099b          	sext.w	s3,a0
    80003242:	0534a823          	sw	s3,80(s1)
    80003246:	b7e9                	j	80003210 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    80003248:	4108                	lw	a0,0(a0)
    8000324a:	00000097          	auipc	ra,0x0
    8000324e:	e36080e7          	jalr	-458(ra) # 80003080 <balloc>
    80003252:	0005059b          	sext.w	a1,a0
    80003256:	08b92023          	sw	a1,128(s2)
    8000325a:	b759                	j	800031e0 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    8000325c:	00092503          	lw	a0,0(s2)
    80003260:	00000097          	auipc	ra,0x0
    80003264:	e20080e7          	jalr	-480(ra) # 80003080 <balloc>
    80003268:	0005099b          	sext.w	s3,a0
    8000326c:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    80003270:	8552                	mv	a0,s4
    80003272:	00001097          	auipc	ra,0x1
    80003276:	ef8080e7          	jalr	-264(ra) # 8000416a <log_write>
    8000327a:	b771                	j	80003206 <bmap+0x54>
  panic("bmap: out of range");
    8000327c:	00005517          	auipc	a0,0x5
    80003280:	2e450513          	addi	a0,a0,740 # 80008560 <syscalls+0x118>
    80003284:	ffffd097          	auipc	ra,0xffffd
    80003288:	2ba080e7          	jalr	698(ra) # 8000053e <panic>

000000008000328c <iget>:
{
    8000328c:	7179                	addi	sp,sp,-48
    8000328e:	f406                	sd	ra,40(sp)
    80003290:	f022                	sd	s0,32(sp)
    80003292:	ec26                	sd	s1,24(sp)
    80003294:	e84a                	sd	s2,16(sp)
    80003296:	e44e                	sd	s3,8(sp)
    80003298:	e052                	sd	s4,0(sp)
    8000329a:	1800                	addi	s0,sp,48
    8000329c:	89aa                	mv	s3,a0
    8000329e:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    800032a0:	0001c517          	auipc	a0,0x1c
    800032a4:	52850513          	addi	a0,a0,1320 # 8001f7c8 <itable>
    800032a8:	ffffe097          	auipc	ra,0xffffe
    800032ac:	93c080e7          	jalr	-1732(ra) # 80000be4 <acquire>
  empty = 0;
    800032b0:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800032b2:	0001c497          	auipc	s1,0x1c
    800032b6:	52e48493          	addi	s1,s1,1326 # 8001f7e0 <itable+0x18>
    800032ba:	0001e697          	auipc	a3,0x1e
    800032be:	fb668693          	addi	a3,a3,-74 # 80021270 <log>
    800032c2:	a039                	j	800032d0 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800032c4:	02090b63          	beqz	s2,800032fa <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800032c8:	08848493          	addi	s1,s1,136
    800032cc:	02d48a63          	beq	s1,a3,80003300 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    800032d0:	449c                	lw	a5,8(s1)
    800032d2:	fef059e3          	blez	a5,800032c4 <iget+0x38>
    800032d6:	4098                	lw	a4,0(s1)
    800032d8:	ff3716e3          	bne	a4,s3,800032c4 <iget+0x38>
    800032dc:	40d8                	lw	a4,4(s1)
    800032de:	ff4713e3          	bne	a4,s4,800032c4 <iget+0x38>
      ip->ref++;
    800032e2:	2785                	addiw	a5,a5,1
    800032e4:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    800032e6:	0001c517          	auipc	a0,0x1c
    800032ea:	4e250513          	addi	a0,a0,1250 # 8001f7c8 <itable>
    800032ee:	ffffe097          	auipc	ra,0xffffe
    800032f2:	9aa080e7          	jalr	-1622(ra) # 80000c98 <release>
      return ip;
    800032f6:	8926                	mv	s2,s1
    800032f8:	a03d                	j	80003326 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800032fa:	f7f9                	bnez	a5,800032c8 <iget+0x3c>
    800032fc:	8926                	mv	s2,s1
    800032fe:	b7e9                	j	800032c8 <iget+0x3c>
  if(empty == 0)
    80003300:	02090c63          	beqz	s2,80003338 <iget+0xac>
  ip->dev = dev;
    80003304:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003308:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    8000330c:	4785                	li	a5,1
    8000330e:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003312:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003316:	0001c517          	auipc	a0,0x1c
    8000331a:	4b250513          	addi	a0,a0,1202 # 8001f7c8 <itable>
    8000331e:	ffffe097          	auipc	ra,0xffffe
    80003322:	97a080e7          	jalr	-1670(ra) # 80000c98 <release>
}
    80003326:	854a                	mv	a0,s2
    80003328:	70a2                	ld	ra,40(sp)
    8000332a:	7402                	ld	s0,32(sp)
    8000332c:	64e2                	ld	s1,24(sp)
    8000332e:	6942                	ld	s2,16(sp)
    80003330:	69a2                	ld	s3,8(sp)
    80003332:	6a02                	ld	s4,0(sp)
    80003334:	6145                	addi	sp,sp,48
    80003336:	8082                	ret
    panic("iget: no inodes");
    80003338:	00005517          	auipc	a0,0x5
    8000333c:	24050513          	addi	a0,a0,576 # 80008578 <syscalls+0x130>
    80003340:	ffffd097          	auipc	ra,0xffffd
    80003344:	1fe080e7          	jalr	510(ra) # 8000053e <panic>

0000000080003348 <fsinit>:
fsinit(int dev) {
    80003348:	7179                	addi	sp,sp,-48
    8000334a:	f406                	sd	ra,40(sp)
    8000334c:	f022                	sd	s0,32(sp)
    8000334e:	ec26                	sd	s1,24(sp)
    80003350:	e84a                	sd	s2,16(sp)
    80003352:	e44e                	sd	s3,8(sp)
    80003354:	1800                	addi	s0,sp,48
    80003356:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003358:	4585                	li	a1,1
    8000335a:	00000097          	auipc	ra,0x0
    8000335e:	a64080e7          	jalr	-1436(ra) # 80002dbe <bread>
    80003362:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003364:	0001c997          	auipc	s3,0x1c
    80003368:	44498993          	addi	s3,s3,1092 # 8001f7a8 <sb>
    8000336c:	02000613          	li	a2,32
    80003370:	05850593          	addi	a1,a0,88
    80003374:	854e                	mv	a0,s3
    80003376:	ffffe097          	auipc	ra,0xffffe
    8000337a:	9ca080e7          	jalr	-1590(ra) # 80000d40 <memmove>
  brelse(bp);
    8000337e:	8526                	mv	a0,s1
    80003380:	00000097          	auipc	ra,0x0
    80003384:	b6e080e7          	jalr	-1170(ra) # 80002eee <brelse>
  if(sb.magic != FSMAGIC)
    80003388:	0009a703          	lw	a4,0(s3)
    8000338c:	102037b7          	lui	a5,0x10203
    80003390:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003394:	02f71263          	bne	a4,a5,800033b8 <fsinit+0x70>
  initlog(dev, &sb);
    80003398:	0001c597          	auipc	a1,0x1c
    8000339c:	41058593          	addi	a1,a1,1040 # 8001f7a8 <sb>
    800033a0:	854a                	mv	a0,s2
    800033a2:	00001097          	auipc	ra,0x1
    800033a6:	b4c080e7          	jalr	-1204(ra) # 80003eee <initlog>
}
    800033aa:	70a2                	ld	ra,40(sp)
    800033ac:	7402                	ld	s0,32(sp)
    800033ae:	64e2                	ld	s1,24(sp)
    800033b0:	6942                	ld	s2,16(sp)
    800033b2:	69a2                	ld	s3,8(sp)
    800033b4:	6145                	addi	sp,sp,48
    800033b6:	8082                	ret
    panic("invalid file system");
    800033b8:	00005517          	auipc	a0,0x5
    800033bc:	1d050513          	addi	a0,a0,464 # 80008588 <syscalls+0x140>
    800033c0:	ffffd097          	auipc	ra,0xffffd
    800033c4:	17e080e7          	jalr	382(ra) # 8000053e <panic>

00000000800033c8 <iinit>:
{
    800033c8:	7179                	addi	sp,sp,-48
    800033ca:	f406                	sd	ra,40(sp)
    800033cc:	f022                	sd	s0,32(sp)
    800033ce:	ec26                	sd	s1,24(sp)
    800033d0:	e84a                	sd	s2,16(sp)
    800033d2:	e44e                	sd	s3,8(sp)
    800033d4:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    800033d6:	00005597          	auipc	a1,0x5
    800033da:	1ca58593          	addi	a1,a1,458 # 800085a0 <syscalls+0x158>
    800033de:	0001c517          	auipc	a0,0x1c
    800033e2:	3ea50513          	addi	a0,a0,1002 # 8001f7c8 <itable>
    800033e6:	ffffd097          	auipc	ra,0xffffd
    800033ea:	76e080e7          	jalr	1902(ra) # 80000b54 <initlock>
  for(i = 0; i < NINODE; i++) {
    800033ee:	0001c497          	auipc	s1,0x1c
    800033f2:	40248493          	addi	s1,s1,1026 # 8001f7f0 <itable+0x28>
    800033f6:	0001e997          	auipc	s3,0x1e
    800033fa:	e8a98993          	addi	s3,s3,-374 # 80021280 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    800033fe:	00005917          	auipc	s2,0x5
    80003402:	1aa90913          	addi	s2,s2,426 # 800085a8 <syscalls+0x160>
    80003406:	85ca                	mv	a1,s2
    80003408:	8526                	mv	a0,s1
    8000340a:	00001097          	auipc	ra,0x1
    8000340e:	e46080e7          	jalr	-442(ra) # 80004250 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003412:	08848493          	addi	s1,s1,136
    80003416:	ff3498e3          	bne	s1,s3,80003406 <iinit+0x3e>
}
    8000341a:	70a2                	ld	ra,40(sp)
    8000341c:	7402                	ld	s0,32(sp)
    8000341e:	64e2                	ld	s1,24(sp)
    80003420:	6942                	ld	s2,16(sp)
    80003422:	69a2                	ld	s3,8(sp)
    80003424:	6145                	addi	sp,sp,48
    80003426:	8082                	ret

0000000080003428 <ialloc>:
{
    80003428:	715d                	addi	sp,sp,-80
    8000342a:	e486                	sd	ra,72(sp)
    8000342c:	e0a2                	sd	s0,64(sp)
    8000342e:	fc26                	sd	s1,56(sp)
    80003430:	f84a                	sd	s2,48(sp)
    80003432:	f44e                	sd	s3,40(sp)
    80003434:	f052                	sd	s4,32(sp)
    80003436:	ec56                	sd	s5,24(sp)
    80003438:	e85a                	sd	s6,16(sp)
    8000343a:	e45e                	sd	s7,8(sp)
    8000343c:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    8000343e:	0001c717          	auipc	a4,0x1c
    80003442:	37672703          	lw	a4,886(a4) # 8001f7b4 <sb+0xc>
    80003446:	4785                	li	a5,1
    80003448:	04e7fa63          	bgeu	a5,a4,8000349c <ialloc+0x74>
    8000344c:	8aaa                	mv	s5,a0
    8000344e:	8bae                	mv	s7,a1
    80003450:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003452:	0001ca17          	auipc	s4,0x1c
    80003456:	356a0a13          	addi	s4,s4,854 # 8001f7a8 <sb>
    8000345a:	00048b1b          	sext.w	s6,s1
    8000345e:	0044d593          	srli	a1,s1,0x4
    80003462:	018a2783          	lw	a5,24(s4)
    80003466:	9dbd                	addw	a1,a1,a5
    80003468:	8556                	mv	a0,s5
    8000346a:	00000097          	auipc	ra,0x0
    8000346e:	954080e7          	jalr	-1708(ra) # 80002dbe <bread>
    80003472:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003474:	05850993          	addi	s3,a0,88
    80003478:	00f4f793          	andi	a5,s1,15
    8000347c:	079a                	slli	a5,a5,0x6
    8000347e:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003480:	00099783          	lh	a5,0(s3)
    80003484:	c785                	beqz	a5,800034ac <ialloc+0x84>
    brelse(bp);
    80003486:	00000097          	auipc	ra,0x0
    8000348a:	a68080e7          	jalr	-1432(ra) # 80002eee <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    8000348e:	0485                	addi	s1,s1,1
    80003490:	00ca2703          	lw	a4,12(s4)
    80003494:	0004879b          	sext.w	a5,s1
    80003498:	fce7e1e3          	bltu	a5,a4,8000345a <ialloc+0x32>
  panic("ialloc: no inodes");
    8000349c:	00005517          	auipc	a0,0x5
    800034a0:	11450513          	addi	a0,a0,276 # 800085b0 <syscalls+0x168>
    800034a4:	ffffd097          	auipc	ra,0xffffd
    800034a8:	09a080e7          	jalr	154(ra) # 8000053e <panic>
      memset(dip, 0, sizeof(*dip));
    800034ac:	04000613          	li	a2,64
    800034b0:	4581                	li	a1,0
    800034b2:	854e                	mv	a0,s3
    800034b4:	ffffe097          	auipc	ra,0xffffe
    800034b8:	82c080e7          	jalr	-2004(ra) # 80000ce0 <memset>
      dip->type = type;
    800034bc:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    800034c0:	854a                	mv	a0,s2
    800034c2:	00001097          	auipc	ra,0x1
    800034c6:	ca8080e7          	jalr	-856(ra) # 8000416a <log_write>
      brelse(bp);
    800034ca:	854a                	mv	a0,s2
    800034cc:	00000097          	auipc	ra,0x0
    800034d0:	a22080e7          	jalr	-1502(ra) # 80002eee <brelse>
      return iget(dev, inum);
    800034d4:	85da                	mv	a1,s6
    800034d6:	8556                	mv	a0,s5
    800034d8:	00000097          	auipc	ra,0x0
    800034dc:	db4080e7          	jalr	-588(ra) # 8000328c <iget>
}
    800034e0:	60a6                	ld	ra,72(sp)
    800034e2:	6406                	ld	s0,64(sp)
    800034e4:	74e2                	ld	s1,56(sp)
    800034e6:	7942                	ld	s2,48(sp)
    800034e8:	79a2                	ld	s3,40(sp)
    800034ea:	7a02                	ld	s4,32(sp)
    800034ec:	6ae2                	ld	s5,24(sp)
    800034ee:	6b42                	ld	s6,16(sp)
    800034f0:	6ba2                	ld	s7,8(sp)
    800034f2:	6161                	addi	sp,sp,80
    800034f4:	8082                	ret

00000000800034f6 <iupdate>:
{
    800034f6:	1101                	addi	sp,sp,-32
    800034f8:	ec06                	sd	ra,24(sp)
    800034fa:	e822                	sd	s0,16(sp)
    800034fc:	e426                	sd	s1,8(sp)
    800034fe:	e04a                	sd	s2,0(sp)
    80003500:	1000                	addi	s0,sp,32
    80003502:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003504:	415c                	lw	a5,4(a0)
    80003506:	0047d79b          	srliw	a5,a5,0x4
    8000350a:	0001c597          	auipc	a1,0x1c
    8000350e:	2b65a583          	lw	a1,694(a1) # 8001f7c0 <sb+0x18>
    80003512:	9dbd                	addw	a1,a1,a5
    80003514:	4108                	lw	a0,0(a0)
    80003516:	00000097          	auipc	ra,0x0
    8000351a:	8a8080e7          	jalr	-1880(ra) # 80002dbe <bread>
    8000351e:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003520:	05850793          	addi	a5,a0,88
    80003524:	40c8                	lw	a0,4(s1)
    80003526:	893d                	andi	a0,a0,15
    80003528:	051a                	slli	a0,a0,0x6
    8000352a:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    8000352c:	04449703          	lh	a4,68(s1)
    80003530:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003534:	04649703          	lh	a4,70(s1)
    80003538:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    8000353c:	04849703          	lh	a4,72(s1)
    80003540:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003544:	04a49703          	lh	a4,74(s1)
    80003548:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    8000354c:	44f8                	lw	a4,76(s1)
    8000354e:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003550:	03400613          	li	a2,52
    80003554:	05048593          	addi	a1,s1,80
    80003558:	0531                	addi	a0,a0,12
    8000355a:	ffffd097          	auipc	ra,0xffffd
    8000355e:	7e6080e7          	jalr	2022(ra) # 80000d40 <memmove>
  log_write(bp);
    80003562:	854a                	mv	a0,s2
    80003564:	00001097          	auipc	ra,0x1
    80003568:	c06080e7          	jalr	-1018(ra) # 8000416a <log_write>
  brelse(bp);
    8000356c:	854a                	mv	a0,s2
    8000356e:	00000097          	auipc	ra,0x0
    80003572:	980080e7          	jalr	-1664(ra) # 80002eee <brelse>
}
    80003576:	60e2                	ld	ra,24(sp)
    80003578:	6442                	ld	s0,16(sp)
    8000357a:	64a2                	ld	s1,8(sp)
    8000357c:	6902                	ld	s2,0(sp)
    8000357e:	6105                	addi	sp,sp,32
    80003580:	8082                	ret

0000000080003582 <idup>:
{
    80003582:	1101                	addi	sp,sp,-32
    80003584:	ec06                	sd	ra,24(sp)
    80003586:	e822                	sd	s0,16(sp)
    80003588:	e426                	sd	s1,8(sp)
    8000358a:	1000                	addi	s0,sp,32
    8000358c:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    8000358e:	0001c517          	auipc	a0,0x1c
    80003592:	23a50513          	addi	a0,a0,570 # 8001f7c8 <itable>
    80003596:	ffffd097          	auipc	ra,0xffffd
    8000359a:	64e080e7          	jalr	1614(ra) # 80000be4 <acquire>
  ip->ref++;
    8000359e:	449c                	lw	a5,8(s1)
    800035a0:	2785                	addiw	a5,a5,1
    800035a2:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    800035a4:	0001c517          	auipc	a0,0x1c
    800035a8:	22450513          	addi	a0,a0,548 # 8001f7c8 <itable>
    800035ac:	ffffd097          	auipc	ra,0xffffd
    800035b0:	6ec080e7          	jalr	1772(ra) # 80000c98 <release>
}
    800035b4:	8526                	mv	a0,s1
    800035b6:	60e2                	ld	ra,24(sp)
    800035b8:	6442                	ld	s0,16(sp)
    800035ba:	64a2                	ld	s1,8(sp)
    800035bc:	6105                	addi	sp,sp,32
    800035be:	8082                	ret

00000000800035c0 <ilock>:
{
    800035c0:	1101                	addi	sp,sp,-32
    800035c2:	ec06                	sd	ra,24(sp)
    800035c4:	e822                	sd	s0,16(sp)
    800035c6:	e426                	sd	s1,8(sp)
    800035c8:	e04a                	sd	s2,0(sp)
    800035ca:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    800035cc:	c115                	beqz	a0,800035f0 <ilock+0x30>
    800035ce:	84aa                	mv	s1,a0
    800035d0:	451c                	lw	a5,8(a0)
    800035d2:	00f05f63          	blez	a5,800035f0 <ilock+0x30>
  acquiresleep(&ip->lock);
    800035d6:	0541                	addi	a0,a0,16
    800035d8:	00001097          	auipc	ra,0x1
    800035dc:	cb2080e7          	jalr	-846(ra) # 8000428a <acquiresleep>
  if(ip->valid == 0){
    800035e0:	40bc                	lw	a5,64(s1)
    800035e2:	cf99                	beqz	a5,80003600 <ilock+0x40>
}
    800035e4:	60e2                	ld	ra,24(sp)
    800035e6:	6442                	ld	s0,16(sp)
    800035e8:	64a2                	ld	s1,8(sp)
    800035ea:	6902                	ld	s2,0(sp)
    800035ec:	6105                	addi	sp,sp,32
    800035ee:	8082                	ret
    panic("ilock");
    800035f0:	00005517          	auipc	a0,0x5
    800035f4:	fd850513          	addi	a0,a0,-40 # 800085c8 <syscalls+0x180>
    800035f8:	ffffd097          	auipc	ra,0xffffd
    800035fc:	f46080e7          	jalr	-186(ra) # 8000053e <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003600:	40dc                	lw	a5,4(s1)
    80003602:	0047d79b          	srliw	a5,a5,0x4
    80003606:	0001c597          	auipc	a1,0x1c
    8000360a:	1ba5a583          	lw	a1,442(a1) # 8001f7c0 <sb+0x18>
    8000360e:	9dbd                	addw	a1,a1,a5
    80003610:	4088                	lw	a0,0(s1)
    80003612:	fffff097          	auipc	ra,0xfffff
    80003616:	7ac080e7          	jalr	1964(ra) # 80002dbe <bread>
    8000361a:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    8000361c:	05850593          	addi	a1,a0,88
    80003620:	40dc                	lw	a5,4(s1)
    80003622:	8bbd                	andi	a5,a5,15
    80003624:	079a                	slli	a5,a5,0x6
    80003626:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003628:	00059783          	lh	a5,0(a1)
    8000362c:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003630:	00259783          	lh	a5,2(a1)
    80003634:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003638:	00459783          	lh	a5,4(a1)
    8000363c:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003640:	00659783          	lh	a5,6(a1)
    80003644:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003648:	459c                	lw	a5,8(a1)
    8000364a:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    8000364c:	03400613          	li	a2,52
    80003650:	05b1                	addi	a1,a1,12
    80003652:	05048513          	addi	a0,s1,80
    80003656:	ffffd097          	auipc	ra,0xffffd
    8000365a:	6ea080e7          	jalr	1770(ra) # 80000d40 <memmove>
    brelse(bp);
    8000365e:	854a                	mv	a0,s2
    80003660:	00000097          	auipc	ra,0x0
    80003664:	88e080e7          	jalr	-1906(ra) # 80002eee <brelse>
    ip->valid = 1;
    80003668:	4785                	li	a5,1
    8000366a:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    8000366c:	04449783          	lh	a5,68(s1)
    80003670:	fbb5                	bnez	a5,800035e4 <ilock+0x24>
      panic("ilock: no type");
    80003672:	00005517          	auipc	a0,0x5
    80003676:	f5e50513          	addi	a0,a0,-162 # 800085d0 <syscalls+0x188>
    8000367a:	ffffd097          	auipc	ra,0xffffd
    8000367e:	ec4080e7          	jalr	-316(ra) # 8000053e <panic>

0000000080003682 <iunlock>:
{
    80003682:	1101                	addi	sp,sp,-32
    80003684:	ec06                	sd	ra,24(sp)
    80003686:	e822                	sd	s0,16(sp)
    80003688:	e426                	sd	s1,8(sp)
    8000368a:	e04a                	sd	s2,0(sp)
    8000368c:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    8000368e:	c905                	beqz	a0,800036be <iunlock+0x3c>
    80003690:	84aa                	mv	s1,a0
    80003692:	01050913          	addi	s2,a0,16
    80003696:	854a                	mv	a0,s2
    80003698:	00001097          	auipc	ra,0x1
    8000369c:	c8c080e7          	jalr	-884(ra) # 80004324 <holdingsleep>
    800036a0:	cd19                	beqz	a0,800036be <iunlock+0x3c>
    800036a2:	449c                	lw	a5,8(s1)
    800036a4:	00f05d63          	blez	a5,800036be <iunlock+0x3c>
  releasesleep(&ip->lock);
    800036a8:	854a                	mv	a0,s2
    800036aa:	00001097          	auipc	ra,0x1
    800036ae:	c36080e7          	jalr	-970(ra) # 800042e0 <releasesleep>
}
    800036b2:	60e2                	ld	ra,24(sp)
    800036b4:	6442                	ld	s0,16(sp)
    800036b6:	64a2                	ld	s1,8(sp)
    800036b8:	6902                	ld	s2,0(sp)
    800036ba:	6105                	addi	sp,sp,32
    800036bc:	8082                	ret
    panic("iunlock");
    800036be:	00005517          	auipc	a0,0x5
    800036c2:	f2250513          	addi	a0,a0,-222 # 800085e0 <syscalls+0x198>
    800036c6:	ffffd097          	auipc	ra,0xffffd
    800036ca:	e78080e7          	jalr	-392(ra) # 8000053e <panic>

00000000800036ce <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    800036ce:	7179                	addi	sp,sp,-48
    800036d0:	f406                	sd	ra,40(sp)
    800036d2:	f022                	sd	s0,32(sp)
    800036d4:	ec26                	sd	s1,24(sp)
    800036d6:	e84a                	sd	s2,16(sp)
    800036d8:	e44e                	sd	s3,8(sp)
    800036da:	e052                	sd	s4,0(sp)
    800036dc:	1800                	addi	s0,sp,48
    800036de:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    800036e0:	05050493          	addi	s1,a0,80
    800036e4:	08050913          	addi	s2,a0,128
    800036e8:	a021                	j	800036f0 <itrunc+0x22>
    800036ea:	0491                	addi	s1,s1,4
    800036ec:	01248d63          	beq	s1,s2,80003706 <itrunc+0x38>
    if(ip->addrs[i]){
    800036f0:	408c                	lw	a1,0(s1)
    800036f2:	dde5                	beqz	a1,800036ea <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    800036f4:	0009a503          	lw	a0,0(s3)
    800036f8:	00000097          	auipc	ra,0x0
    800036fc:	90c080e7          	jalr	-1780(ra) # 80003004 <bfree>
      ip->addrs[i] = 0;
    80003700:	0004a023          	sw	zero,0(s1)
    80003704:	b7dd                	j	800036ea <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003706:	0809a583          	lw	a1,128(s3)
    8000370a:	e185                	bnez	a1,8000372a <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    8000370c:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003710:	854e                	mv	a0,s3
    80003712:	00000097          	auipc	ra,0x0
    80003716:	de4080e7          	jalr	-540(ra) # 800034f6 <iupdate>
}
    8000371a:	70a2                	ld	ra,40(sp)
    8000371c:	7402                	ld	s0,32(sp)
    8000371e:	64e2                	ld	s1,24(sp)
    80003720:	6942                	ld	s2,16(sp)
    80003722:	69a2                	ld	s3,8(sp)
    80003724:	6a02                	ld	s4,0(sp)
    80003726:	6145                	addi	sp,sp,48
    80003728:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    8000372a:	0009a503          	lw	a0,0(s3)
    8000372e:	fffff097          	auipc	ra,0xfffff
    80003732:	690080e7          	jalr	1680(ra) # 80002dbe <bread>
    80003736:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003738:	05850493          	addi	s1,a0,88
    8000373c:	45850913          	addi	s2,a0,1112
    80003740:	a811                	j	80003754 <itrunc+0x86>
        bfree(ip->dev, a[j]);
    80003742:	0009a503          	lw	a0,0(s3)
    80003746:	00000097          	auipc	ra,0x0
    8000374a:	8be080e7          	jalr	-1858(ra) # 80003004 <bfree>
    for(j = 0; j < NINDIRECT; j++){
    8000374e:	0491                	addi	s1,s1,4
    80003750:	01248563          	beq	s1,s2,8000375a <itrunc+0x8c>
      if(a[j])
    80003754:	408c                	lw	a1,0(s1)
    80003756:	dde5                	beqz	a1,8000374e <itrunc+0x80>
    80003758:	b7ed                	j	80003742 <itrunc+0x74>
    brelse(bp);
    8000375a:	8552                	mv	a0,s4
    8000375c:	fffff097          	auipc	ra,0xfffff
    80003760:	792080e7          	jalr	1938(ra) # 80002eee <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003764:	0809a583          	lw	a1,128(s3)
    80003768:	0009a503          	lw	a0,0(s3)
    8000376c:	00000097          	auipc	ra,0x0
    80003770:	898080e7          	jalr	-1896(ra) # 80003004 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003774:	0809a023          	sw	zero,128(s3)
    80003778:	bf51                	j	8000370c <itrunc+0x3e>

000000008000377a <iput>:
{
    8000377a:	1101                	addi	sp,sp,-32
    8000377c:	ec06                	sd	ra,24(sp)
    8000377e:	e822                	sd	s0,16(sp)
    80003780:	e426                	sd	s1,8(sp)
    80003782:	e04a                	sd	s2,0(sp)
    80003784:	1000                	addi	s0,sp,32
    80003786:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003788:	0001c517          	auipc	a0,0x1c
    8000378c:	04050513          	addi	a0,a0,64 # 8001f7c8 <itable>
    80003790:	ffffd097          	auipc	ra,0xffffd
    80003794:	454080e7          	jalr	1108(ra) # 80000be4 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003798:	4498                	lw	a4,8(s1)
    8000379a:	4785                	li	a5,1
    8000379c:	02f70363          	beq	a4,a5,800037c2 <iput+0x48>
  ip->ref--;
    800037a0:	449c                	lw	a5,8(s1)
    800037a2:	37fd                	addiw	a5,a5,-1
    800037a4:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    800037a6:	0001c517          	auipc	a0,0x1c
    800037aa:	02250513          	addi	a0,a0,34 # 8001f7c8 <itable>
    800037ae:	ffffd097          	auipc	ra,0xffffd
    800037b2:	4ea080e7          	jalr	1258(ra) # 80000c98 <release>
}
    800037b6:	60e2                	ld	ra,24(sp)
    800037b8:	6442                	ld	s0,16(sp)
    800037ba:	64a2                	ld	s1,8(sp)
    800037bc:	6902                	ld	s2,0(sp)
    800037be:	6105                	addi	sp,sp,32
    800037c0:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800037c2:	40bc                	lw	a5,64(s1)
    800037c4:	dff1                	beqz	a5,800037a0 <iput+0x26>
    800037c6:	04a49783          	lh	a5,74(s1)
    800037ca:	fbf9                	bnez	a5,800037a0 <iput+0x26>
    acquiresleep(&ip->lock);
    800037cc:	01048913          	addi	s2,s1,16
    800037d0:	854a                	mv	a0,s2
    800037d2:	00001097          	auipc	ra,0x1
    800037d6:	ab8080e7          	jalr	-1352(ra) # 8000428a <acquiresleep>
    release(&itable.lock);
    800037da:	0001c517          	auipc	a0,0x1c
    800037de:	fee50513          	addi	a0,a0,-18 # 8001f7c8 <itable>
    800037e2:	ffffd097          	auipc	ra,0xffffd
    800037e6:	4b6080e7          	jalr	1206(ra) # 80000c98 <release>
    itrunc(ip);
    800037ea:	8526                	mv	a0,s1
    800037ec:	00000097          	auipc	ra,0x0
    800037f0:	ee2080e7          	jalr	-286(ra) # 800036ce <itrunc>
    ip->type = 0;
    800037f4:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    800037f8:	8526                	mv	a0,s1
    800037fa:	00000097          	auipc	ra,0x0
    800037fe:	cfc080e7          	jalr	-772(ra) # 800034f6 <iupdate>
    ip->valid = 0;
    80003802:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003806:	854a                	mv	a0,s2
    80003808:	00001097          	auipc	ra,0x1
    8000380c:	ad8080e7          	jalr	-1320(ra) # 800042e0 <releasesleep>
    acquire(&itable.lock);
    80003810:	0001c517          	auipc	a0,0x1c
    80003814:	fb850513          	addi	a0,a0,-72 # 8001f7c8 <itable>
    80003818:	ffffd097          	auipc	ra,0xffffd
    8000381c:	3cc080e7          	jalr	972(ra) # 80000be4 <acquire>
    80003820:	b741                	j	800037a0 <iput+0x26>

0000000080003822 <iunlockput>:
{
    80003822:	1101                	addi	sp,sp,-32
    80003824:	ec06                	sd	ra,24(sp)
    80003826:	e822                	sd	s0,16(sp)
    80003828:	e426                	sd	s1,8(sp)
    8000382a:	1000                	addi	s0,sp,32
    8000382c:	84aa                	mv	s1,a0
  iunlock(ip);
    8000382e:	00000097          	auipc	ra,0x0
    80003832:	e54080e7          	jalr	-428(ra) # 80003682 <iunlock>
  iput(ip);
    80003836:	8526                	mv	a0,s1
    80003838:	00000097          	auipc	ra,0x0
    8000383c:	f42080e7          	jalr	-190(ra) # 8000377a <iput>
}
    80003840:	60e2                	ld	ra,24(sp)
    80003842:	6442                	ld	s0,16(sp)
    80003844:	64a2                	ld	s1,8(sp)
    80003846:	6105                	addi	sp,sp,32
    80003848:	8082                	ret

000000008000384a <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    8000384a:	1141                	addi	sp,sp,-16
    8000384c:	e422                	sd	s0,8(sp)
    8000384e:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003850:	411c                	lw	a5,0(a0)
    80003852:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003854:	415c                	lw	a5,4(a0)
    80003856:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003858:	04451783          	lh	a5,68(a0)
    8000385c:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003860:	04a51783          	lh	a5,74(a0)
    80003864:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003868:	04c56783          	lwu	a5,76(a0)
    8000386c:	e99c                	sd	a5,16(a1)
}
    8000386e:	6422                	ld	s0,8(sp)
    80003870:	0141                	addi	sp,sp,16
    80003872:	8082                	ret

0000000080003874 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003874:	457c                	lw	a5,76(a0)
    80003876:	0ed7e963          	bltu	a5,a3,80003968 <readi+0xf4>
{
    8000387a:	7159                	addi	sp,sp,-112
    8000387c:	f486                	sd	ra,104(sp)
    8000387e:	f0a2                	sd	s0,96(sp)
    80003880:	eca6                	sd	s1,88(sp)
    80003882:	e8ca                	sd	s2,80(sp)
    80003884:	e4ce                	sd	s3,72(sp)
    80003886:	e0d2                	sd	s4,64(sp)
    80003888:	fc56                	sd	s5,56(sp)
    8000388a:	f85a                	sd	s6,48(sp)
    8000388c:	f45e                	sd	s7,40(sp)
    8000388e:	f062                	sd	s8,32(sp)
    80003890:	ec66                	sd	s9,24(sp)
    80003892:	e86a                	sd	s10,16(sp)
    80003894:	e46e                	sd	s11,8(sp)
    80003896:	1880                	addi	s0,sp,112
    80003898:	8baa                	mv	s7,a0
    8000389a:	8c2e                	mv	s8,a1
    8000389c:	8ab2                	mv	s5,a2
    8000389e:	84b6                	mv	s1,a3
    800038a0:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    800038a2:	9f35                	addw	a4,a4,a3
    return 0;
    800038a4:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    800038a6:	0ad76063          	bltu	a4,a3,80003946 <readi+0xd2>
  if(off + n > ip->size)
    800038aa:	00e7f463          	bgeu	a5,a4,800038b2 <readi+0x3e>
    n = ip->size - off;
    800038ae:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800038b2:	0a0b0963          	beqz	s6,80003964 <readi+0xf0>
    800038b6:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    800038b8:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    800038bc:	5cfd                	li	s9,-1
    800038be:	a82d                	j	800038f8 <readi+0x84>
    800038c0:	020a1d93          	slli	s11,s4,0x20
    800038c4:	020ddd93          	srli	s11,s11,0x20
    800038c8:	05890613          	addi	a2,s2,88
    800038cc:	86ee                	mv	a3,s11
    800038ce:	963a                	add	a2,a2,a4
    800038d0:	85d6                	mv	a1,s5
    800038d2:	8562                	mv	a0,s8
    800038d4:	fffff097          	auipc	ra,0xfffff
    800038d8:	b2e080e7          	jalr	-1234(ra) # 80002402 <either_copyout>
    800038dc:	05950d63          	beq	a0,s9,80003936 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    800038e0:	854a                	mv	a0,s2
    800038e2:	fffff097          	auipc	ra,0xfffff
    800038e6:	60c080e7          	jalr	1548(ra) # 80002eee <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800038ea:	013a09bb          	addw	s3,s4,s3
    800038ee:	009a04bb          	addw	s1,s4,s1
    800038f2:	9aee                	add	s5,s5,s11
    800038f4:	0569f763          	bgeu	s3,s6,80003942 <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    800038f8:	000ba903          	lw	s2,0(s7)
    800038fc:	00a4d59b          	srliw	a1,s1,0xa
    80003900:	855e                	mv	a0,s7
    80003902:	00000097          	auipc	ra,0x0
    80003906:	8b0080e7          	jalr	-1872(ra) # 800031b2 <bmap>
    8000390a:	0005059b          	sext.w	a1,a0
    8000390e:	854a                	mv	a0,s2
    80003910:	fffff097          	auipc	ra,0xfffff
    80003914:	4ae080e7          	jalr	1198(ra) # 80002dbe <bread>
    80003918:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    8000391a:	3ff4f713          	andi	a4,s1,1023
    8000391e:	40ed07bb          	subw	a5,s10,a4
    80003922:	413b06bb          	subw	a3,s6,s3
    80003926:	8a3e                	mv	s4,a5
    80003928:	2781                	sext.w	a5,a5
    8000392a:	0006861b          	sext.w	a2,a3
    8000392e:	f8f679e3          	bgeu	a2,a5,800038c0 <readi+0x4c>
    80003932:	8a36                	mv	s4,a3
    80003934:	b771                	j	800038c0 <readi+0x4c>
      brelse(bp);
    80003936:	854a                	mv	a0,s2
    80003938:	fffff097          	auipc	ra,0xfffff
    8000393c:	5b6080e7          	jalr	1462(ra) # 80002eee <brelse>
      tot = -1;
    80003940:	59fd                	li	s3,-1
  }
  return tot;
    80003942:	0009851b          	sext.w	a0,s3
}
    80003946:	70a6                	ld	ra,104(sp)
    80003948:	7406                	ld	s0,96(sp)
    8000394a:	64e6                	ld	s1,88(sp)
    8000394c:	6946                	ld	s2,80(sp)
    8000394e:	69a6                	ld	s3,72(sp)
    80003950:	6a06                	ld	s4,64(sp)
    80003952:	7ae2                	ld	s5,56(sp)
    80003954:	7b42                	ld	s6,48(sp)
    80003956:	7ba2                	ld	s7,40(sp)
    80003958:	7c02                	ld	s8,32(sp)
    8000395a:	6ce2                	ld	s9,24(sp)
    8000395c:	6d42                	ld	s10,16(sp)
    8000395e:	6da2                	ld	s11,8(sp)
    80003960:	6165                	addi	sp,sp,112
    80003962:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003964:	89da                	mv	s3,s6
    80003966:	bff1                	j	80003942 <readi+0xce>
    return 0;
    80003968:	4501                	li	a0,0
}
    8000396a:	8082                	ret

000000008000396c <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    8000396c:	457c                	lw	a5,76(a0)
    8000396e:	10d7e863          	bltu	a5,a3,80003a7e <writei+0x112>
{
    80003972:	7159                	addi	sp,sp,-112
    80003974:	f486                	sd	ra,104(sp)
    80003976:	f0a2                	sd	s0,96(sp)
    80003978:	eca6                	sd	s1,88(sp)
    8000397a:	e8ca                	sd	s2,80(sp)
    8000397c:	e4ce                	sd	s3,72(sp)
    8000397e:	e0d2                	sd	s4,64(sp)
    80003980:	fc56                	sd	s5,56(sp)
    80003982:	f85a                	sd	s6,48(sp)
    80003984:	f45e                	sd	s7,40(sp)
    80003986:	f062                	sd	s8,32(sp)
    80003988:	ec66                	sd	s9,24(sp)
    8000398a:	e86a                	sd	s10,16(sp)
    8000398c:	e46e                	sd	s11,8(sp)
    8000398e:	1880                	addi	s0,sp,112
    80003990:	8b2a                	mv	s6,a0
    80003992:	8c2e                	mv	s8,a1
    80003994:	8ab2                	mv	s5,a2
    80003996:	8936                	mv	s2,a3
    80003998:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    8000399a:	00e687bb          	addw	a5,a3,a4
    8000399e:	0ed7e263          	bltu	a5,a3,80003a82 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    800039a2:	00043737          	lui	a4,0x43
    800039a6:	0ef76063          	bltu	a4,a5,80003a86 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800039aa:	0c0b8863          	beqz	s7,80003a7a <writei+0x10e>
    800039ae:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    800039b0:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    800039b4:	5cfd                	li	s9,-1
    800039b6:	a091                	j	800039fa <writei+0x8e>
    800039b8:	02099d93          	slli	s11,s3,0x20
    800039bc:	020ddd93          	srli	s11,s11,0x20
    800039c0:	05848513          	addi	a0,s1,88
    800039c4:	86ee                	mv	a3,s11
    800039c6:	8656                	mv	a2,s5
    800039c8:	85e2                	mv	a1,s8
    800039ca:	953a                	add	a0,a0,a4
    800039cc:	fffff097          	auipc	ra,0xfffff
    800039d0:	a8c080e7          	jalr	-1396(ra) # 80002458 <either_copyin>
    800039d4:	07950263          	beq	a0,s9,80003a38 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    800039d8:	8526                	mv	a0,s1
    800039da:	00000097          	auipc	ra,0x0
    800039de:	790080e7          	jalr	1936(ra) # 8000416a <log_write>
    brelse(bp);
    800039e2:	8526                	mv	a0,s1
    800039e4:	fffff097          	auipc	ra,0xfffff
    800039e8:	50a080e7          	jalr	1290(ra) # 80002eee <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800039ec:	01498a3b          	addw	s4,s3,s4
    800039f0:	0129893b          	addw	s2,s3,s2
    800039f4:	9aee                	add	s5,s5,s11
    800039f6:	057a7663          	bgeu	s4,s7,80003a42 <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    800039fa:	000b2483          	lw	s1,0(s6)
    800039fe:	00a9559b          	srliw	a1,s2,0xa
    80003a02:	855a                	mv	a0,s6
    80003a04:	fffff097          	auipc	ra,0xfffff
    80003a08:	7ae080e7          	jalr	1966(ra) # 800031b2 <bmap>
    80003a0c:	0005059b          	sext.w	a1,a0
    80003a10:	8526                	mv	a0,s1
    80003a12:	fffff097          	auipc	ra,0xfffff
    80003a16:	3ac080e7          	jalr	940(ra) # 80002dbe <bread>
    80003a1a:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003a1c:	3ff97713          	andi	a4,s2,1023
    80003a20:	40ed07bb          	subw	a5,s10,a4
    80003a24:	414b86bb          	subw	a3,s7,s4
    80003a28:	89be                	mv	s3,a5
    80003a2a:	2781                	sext.w	a5,a5
    80003a2c:	0006861b          	sext.w	a2,a3
    80003a30:	f8f674e3          	bgeu	a2,a5,800039b8 <writei+0x4c>
    80003a34:	89b6                	mv	s3,a3
    80003a36:	b749                	j	800039b8 <writei+0x4c>
      brelse(bp);
    80003a38:	8526                	mv	a0,s1
    80003a3a:	fffff097          	auipc	ra,0xfffff
    80003a3e:	4b4080e7          	jalr	1204(ra) # 80002eee <brelse>
  }

  if(off > ip->size)
    80003a42:	04cb2783          	lw	a5,76(s6)
    80003a46:	0127f463          	bgeu	a5,s2,80003a4e <writei+0xe2>
    ip->size = off;
    80003a4a:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003a4e:	855a                	mv	a0,s6
    80003a50:	00000097          	auipc	ra,0x0
    80003a54:	aa6080e7          	jalr	-1370(ra) # 800034f6 <iupdate>

  return tot;
    80003a58:	000a051b          	sext.w	a0,s4
}
    80003a5c:	70a6                	ld	ra,104(sp)
    80003a5e:	7406                	ld	s0,96(sp)
    80003a60:	64e6                	ld	s1,88(sp)
    80003a62:	6946                	ld	s2,80(sp)
    80003a64:	69a6                	ld	s3,72(sp)
    80003a66:	6a06                	ld	s4,64(sp)
    80003a68:	7ae2                	ld	s5,56(sp)
    80003a6a:	7b42                	ld	s6,48(sp)
    80003a6c:	7ba2                	ld	s7,40(sp)
    80003a6e:	7c02                	ld	s8,32(sp)
    80003a70:	6ce2                	ld	s9,24(sp)
    80003a72:	6d42                	ld	s10,16(sp)
    80003a74:	6da2                	ld	s11,8(sp)
    80003a76:	6165                	addi	sp,sp,112
    80003a78:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003a7a:	8a5e                	mv	s4,s7
    80003a7c:	bfc9                	j	80003a4e <writei+0xe2>
    return -1;
    80003a7e:	557d                	li	a0,-1
}
    80003a80:	8082                	ret
    return -1;
    80003a82:	557d                	li	a0,-1
    80003a84:	bfe1                	j	80003a5c <writei+0xf0>
    return -1;
    80003a86:	557d                	li	a0,-1
    80003a88:	bfd1                	j	80003a5c <writei+0xf0>

0000000080003a8a <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003a8a:	1141                	addi	sp,sp,-16
    80003a8c:	e406                	sd	ra,8(sp)
    80003a8e:	e022                	sd	s0,0(sp)
    80003a90:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003a92:	4639                	li	a2,14
    80003a94:	ffffd097          	auipc	ra,0xffffd
    80003a98:	324080e7          	jalr	804(ra) # 80000db8 <strncmp>
}
    80003a9c:	60a2                	ld	ra,8(sp)
    80003a9e:	6402                	ld	s0,0(sp)
    80003aa0:	0141                	addi	sp,sp,16
    80003aa2:	8082                	ret

0000000080003aa4 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003aa4:	7139                	addi	sp,sp,-64
    80003aa6:	fc06                	sd	ra,56(sp)
    80003aa8:	f822                	sd	s0,48(sp)
    80003aaa:	f426                	sd	s1,40(sp)
    80003aac:	f04a                	sd	s2,32(sp)
    80003aae:	ec4e                	sd	s3,24(sp)
    80003ab0:	e852                	sd	s4,16(sp)
    80003ab2:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003ab4:	04451703          	lh	a4,68(a0)
    80003ab8:	4785                	li	a5,1
    80003aba:	00f71a63          	bne	a4,a5,80003ace <dirlookup+0x2a>
    80003abe:	892a                	mv	s2,a0
    80003ac0:	89ae                	mv	s3,a1
    80003ac2:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003ac4:	457c                	lw	a5,76(a0)
    80003ac6:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003ac8:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003aca:	e79d                	bnez	a5,80003af8 <dirlookup+0x54>
    80003acc:	a8a5                	j	80003b44 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003ace:	00005517          	auipc	a0,0x5
    80003ad2:	b1a50513          	addi	a0,a0,-1254 # 800085e8 <syscalls+0x1a0>
    80003ad6:	ffffd097          	auipc	ra,0xffffd
    80003ada:	a68080e7          	jalr	-1432(ra) # 8000053e <panic>
      panic("dirlookup read");
    80003ade:	00005517          	auipc	a0,0x5
    80003ae2:	b2250513          	addi	a0,a0,-1246 # 80008600 <syscalls+0x1b8>
    80003ae6:	ffffd097          	auipc	ra,0xffffd
    80003aea:	a58080e7          	jalr	-1448(ra) # 8000053e <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003aee:	24c1                	addiw	s1,s1,16
    80003af0:	04c92783          	lw	a5,76(s2)
    80003af4:	04f4f763          	bgeu	s1,a5,80003b42 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003af8:	4741                	li	a4,16
    80003afa:	86a6                	mv	a3,s1
    80003afc:	fc040613          	addi	a2,s0,-64
    80003b00:	4581                	li	a1,0
    80003b02:	854a                	mv	a0,s2
    80003b04:	00000097          	auipc	ra,0x0
    80003b08:	d70080e7          	jalr	-656(ra) # 80003874 <readi>
    80003b0c:	47c1                	li	a5,16
    80003b0e:	fcf518e3          	bne	a0,a5,80003ade <dirlookup+0x3a>
    if(de.inum == 0)
    80003b12:	fc045783          	lhu	a5,-64(s0)
    80003b16:	dfe1                	beqz	a5,80003aee <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003b18:	fc240593          	addi	a1,s0,-62
    80003b1c:	854e                	mv	a0,s3
    80003b1e:	00000097          	auipc	ra,0x0
    80003b22:	f6c080e7          	jalr	-148(ra) # 80003a8a <namecmp>
    80003b26:	f561                	bnez	a0,80003aee <dirlookup+0x4a>
      if(poff)
    80003b28:	000a0463          	beqz	s4,80003b30 <dirlookup+0x8c>
        *poff = off;
    80003b2c:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003b30:	fc045583          	lhu	a1,-64(s0)
    80003b34:	00092503          	lw	a0,0(s2)
    80003b38:	fffff097          	auipc	ra,0xfffff
    80003b3c:	754080e7          	jalr	1876(ra) # 8000328c <iget>
    80003b40:	a011                	j	80003b44 <dirlookup+0xa0>
  return 0;
    80003b42:	4501                	li	a0,0
}
    80003b44:	70e2                	ld	ra,56(sp)
    80003b46:	7442                	ld	s0,48(sp)
    80003b48:	74a2                	ld	s1,40(sp)
    80003b4a:	7902                	ld	s2,32(sp)
    80003b4c:	69e2                	ld	s3,24(sp)
    80003b4e:	6a42                	ld	s4,16(sp)
    80003b50:	6121                	addi	sp,sp,64
    80003b52:	8082                	ret

0000000080003b54 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003b54:	711d                	addi	sp,sp,-96
    80003b56:	ec86                	sd	ra,88(sp)
    80003b58:	e8a2                	sd	s0,80(sp)
    80003b5a:	e4a6                	sd	s1,72(sp)
    80003b5c:	e0ca                	sd	s2,64(sp)
    80003b5e:	fc4e                	sd	s3,56(sp)
    80003b60:	f852                	sd	s4,48(sp)
    80003b62:	f456                	sd	s5,40(sp)
    80003b64:	f05a                	sd	s6,32(sp)
    80003b66:	ec5e                	sd	s7,24(sp)
    80003b68:	e862                	sd	s8,16(sp)
    80003b6a:	e466                	sd	s9,8(sp)
    80003b6c:	1080                	addi	s0,sp,96
    80003b6e:	84aa                	mv	s1,a0
    80003b70:	8b2e                	mv	s6,a1
    80003b72:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003b74:	00054703          	lbu	a4,0(a0)
    80003b78:	02f00793          	li	a5,47
    80003b7c:	02f70363          	beq	a4,a5,80003ba2 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003b80:	ffffe097          	auipc	ra,0xffffe
    80003b84:	e30080e7          	jalr	-464(ra) # 800019b0 <myproc>
    80003b88:	15053503          	ld	a0,336(a0)
    80003b8c:	00000097          	auipc	ra,0x0
    80003b90:	9f6080e7          	jalr	-1546(ra) # 80003582 <idup>
    80003b94:	89aa                	mv	s3,a0
  while(*path == '/')
    80003b96:	02f00913          	li	s2,47
  len = path - s;
    80003b9a:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    80003b9c:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003b9e:	4c05                	li	s8,1
    80003ba0:	a865                	j	80003c58 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003ba2:	4585                	li	a1,1
    80003ba4:	4505                	li	a0,1
    80003ba6:	fffff097          	auipc	ra,0xfffff
    80003baa:	6e6080e7          	jalr	1766(ra) # 8000328c <iget>
    80003bae:	89aa                	mv	s3,a0
    80003bb0:	b7dd                	j	80003b96 <namex+0x42>
      iunlockput(ip);
    80003bb2:	854e                	mv	a0,s3
    80003bb4:	00000097          	auipc	ra,0x0
    80003bb8:	c6e080e7          	jalr	-914(ra) # 80003822 <iunlockput>
      return 0;
    80003bbc:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003bbe:	854e                	mv	a0,s3
    80003bc0:	60e6                	ld	ra,88(sp)
    80003bc2:	6446                	ld	s0,80(sp)
    80003bc4:	64a6                	ld	s1,72(sp)
    80003bc6:	6906                	ld	s2,64(sp)
    80003bc8:	79e2                	ld	s3,56(sp)
    80003bca:	7a42                	ld	s4,48(sp)
    80003bcc:	7aa2                	ld	s5,40(sp)
    80003bce:	7b02                	ld	s6,32(sp)
    80003bd0:	6be2                	ld	s7,24(sp)
    80003bd2:	6c42                	ld	s8,16(sp)
    80003bd4:	6ca2                	ld	s9,8(sp)
    80003bd6:	6125                	addi	sp,sp,96
    80003bd8:	8082                	ret
      iunlock(ip);
    80003bda:	854e                	mv	a0,s3
    80003bdc:	00000097          	auipc	ra,0x0
    80003be0:	aa6080e7          	jalr	-1370(ra) # 80003682 <iunlock>
      return ip;
    80003be4:	bfe9                	j	80003bbe <namex+0x6a>
      iunlockput(ip);
    80003be6:	854e                	mv	a0,s3
    80003be8:	00000097          	auipc	ra,0x0
    80003bec:	c3a080e7          	jalr	-966(ra) # 80003822 <iunlockput>
      return 0;
    80003bf0:	89d2                	mv	s3,s4
    80003bf2:	b7f1                	j	80003bbe <namex+0x6a>
  len = path - s;
    80003bf4:	40b48633          	sub	a2,s1,a1
    80003bf8:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80003bfc:	094cd463          	bge	s9,s4,80003c84 <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003c00:	4639                	li	a2,14
    80003c02:	8556                	mv	a0,s5
    80003c04:	ffffd097          	auipc	ra,0xffffd
    80003c08:	13c080e7          	jalr	316(ra) # 80000d40 <memmove>
  while(*path == '/')
    80003c0c:	0004c783          	lbu	a5,0(s1)
    80003c10:	01279763          	bne	a5,s2,80003c1e <namex+0xca>
    path++;
    80003c14:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003c16:	0004c783          	lbu	a5,0(s1)
    80003c1a:	ff278de3          	beq	a5,s2,80003c14 <namex+0xc0>
    ilock(ip);
    80003c1e:	854e                	mv	a0,s3
    80003c20:	00000097          	auipc	ra,0x0
    80003c24:	9a0080e7          	jalr	-1632(ra) # 800035c0 <ilock>
    if(ip->type != T_DIR){
    80003c28:	04499783          	lh	a5,68(s3)
    80003c2c:	f98793e3          	bne	a5,s8,80003bb2 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003c30:	000b0563          	beqz	s6,80003c3a <namex+0xe6>
    80003c34:	0004c783          	lbu	a5,0(s1)
    80003c38:	d3cd                	beqz	a5,80003bda <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003c3a:	865e                	mv	a2,s7
    80003c3c:	85d6                	mv	a1,s5
    80003c3e:	854e                	mv	a0,s3
    80003c40:	00000097          	auipc	ra,0x0
    80003c44:	e64080e7          	jalr	-412(ra) # 80003aa4 <dirlookup>
    80003c48:	8a2a                	mv	s4,a0
    80003c4a:	dd51                	beqz	a0,80003be6 <namex+0x92>
    iunlockput(ip);
    80003c4c:	854e                	mv	a0,s3
    80003c4e:	00000097          	auipc	ra,0x0
    80003c52:	bd4080e7          	jalr	-1068(ra) # 80003822 <iunlockput>
    ip = next;
    80003c56:	89d2                	mv	s3,s4
  while(*path == '/')
    80003c58:	0004c783          	lbu	a5,0(s1)
    80003c5c:	05279763          	bne	a5,s2,80003caa <namex+0x156>
    path++;
    80003c60:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003c62:	0004c783          	lbu	a5,0(s1)
    80003c66:	ff278de3          	beq	a5,s2,80003c60 <namex+0x10c>
  if(*path == 0)
    80003c6a:	c79d                	beqz	a5,80003c98 <namex+0x144>
    path++;
    80003c6c:	85a6                	mv	a1,s1
  len = path - s;
    80003c6e:	8a5e                	mv	s4,s7
    80003c70:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80003c72:	01278963          	beq	a5,s2,80003c84 <namex+0x130>
    80003c76:	dfbd                	beqz	a5,80003bf4 <namex+0xa0>
    path++;
    80003c78:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80003c7a:	0004c783          	lbu	a5,0(s1)
    80003c7e:	ff279ce3          	bne	a5,s2,80003c76 <namex+0x122>
    80003c82:	bf8d                	j	80003bf4 <namex+0xa0>
    memmove(name, s, len);
    80003c84:	2601                	sext.w	a2,a2
    80003c86:	8556                	mv	a0,s5
    80003c88:	ffffd097          	auipc	ra,0xffffd
    80003c8c:	0b8080e7          	jalr	184(ra) # 80000d40 <memmove>
    name[len] = 0;
    80003c90:	9a56                	add	s4,s4,s5
    80003c92:	000a0023          	sb	zero,0(s4)
    80003c96:	bf9d                	j	80003c0c <namex+0xb8>
  if(nameiparent){
    80003c98:	f20b03e3          	beqz	s6,80003bbe <namex+0x6a>
    iput(ip);
    80003c9c:	854e                	mv	a0,s3
    80003c9e:	00000097          	auipc	ra,0x0
    80003ca2:	adc080e7          	jalr	-1316(ra) # 8000377a <iput>
    return 0;
    80003ca6:	4981                	li	s3,0
    80003ca8:	bf19                	j	80003bbe <namex+0x6a>
  if(*path == 0)
    80003caa:	d7fd                	beqz	a5,80003c98 <namex+0x144>
  while(*path != '/' && *path != 0)
    80003cac:	0004c783          	lbu	a5,0(s1)
    80003cb0:	85a6                	mv	a1,s1
    80003cb2:	b7d1                	j	80003c76 <namex+0x122>

0000000080003cb4 <dirlink>:
{
    80003cb4:	7139                	addi	sp,sp,-64
    80003cb6:	fc06                	sd	ra,56(sp)
    80003cb8:	f822                	sd	s0,48(sp)
    80003cba:	f426                	sd	s1,40(sp)
    80003cbc:	f04a                	sd	s2,32(sp)
    80003cbe:	ec4e                	sd	s3,24(sp)
    80003cc0:	e852                	sd	s4,16(sp)
    80003cc2:	0080                	addi	s0,sp,64
    80003cc4:	892a                	mv	s2,a0
    80003cc6:	8a2e                	mv	s4,a1
    80003cc8:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003cca:	4601                	li	a2,0
    80003ccc:	00000097          	auipc	ra,0x0
    80003cd0:	dd8080e7          	jalr	-552(ra) # 80003aa4 <dirlookup>
    80003cd4:	e93d                	bnez	a0,80003d4a <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003cd6:	04c92483          	lw	s1,76(s2)
    80003cda:	c49d                	beqz	s1,80003d08 <dirlink+0x54>
    80003cdc:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003cde:	4741                	li	a4,16
    80003ce0:	86a6                	mv	a3,s1
    80003ce2:	fc040613          	addi	a2,s0,-64
    80003ce6:	4581                	li	a1,0
    80003ce8:	854a                	mv	a0,s2
    80003cea:	00000097          	auipc	ra,0x0
    80003cee:	b8a080e7          	jalr	-1142(ra) # 80003874 <readi>
    80003cf2:	47c1                	li	a5,16
    80003cf4:	06f51163          	bne	a0,a5,80003d56 <dirlink+0xa2>
    if(de.inum == 0)
    80003cf8:	fc045783          	lhu	a5,-64(s0)
    80003cfc:	c791                	beqz	a5,80003d08 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003cfe:	24c1                	addiw	s1,s1,16
    80003d00:	04c92783          	lw	a5,76(s2)
    80003d04:	fcf4ede3          	bltu	s1,a5,80003cde <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80003d08:	4639                	li	a2,14
    80003d0a:	85d2                	mv	a1,s4
    80003d0c:	fc240513          	addi	a0,s0,-62
    80003d10:	ffffd097          	auipc	ra,0xffffd
    80003d14:	0e4080e7          	jalr	228(ra) # 80000df4 <strncpy>
  de.inum = inum;
    80003d18:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003d1c:	4741                	li	a4,16
    80003d1e:	86a6                	mv	a3,s1
    80003d20:	fc040613          	addi	a2,s0,-64
    80003d24:	4581                	li	a1,0
    80003d26:	854a                	mv	a0,s2
    80003d28:	00000097          	auipc	ra,0x0
    80003d2c:	c44080e7          	jalr	-956(ra) # 8000396c <writei>
    80003d30:	872a                	mv	a4,a0
    80003d32:	47c1                	li	a5,16
  return 0;
    80003d34:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003d36:	02f71863          	bne	a4,a5,80003d66 <dirlink+0xb2>
}
    80003d3a:	70e2                	ld	ra,56(sp)
    80003d3c:	7442                	ld	s0,48(sp)
    80003d3e:	74a2                	ld	s1,40(sp)
    80003d40:	7902                	ld	s2,32(sp)
    80003d42:	69e2                	ld	s3,24(sp)
    80003d44:	6a42                	ld	s4,16(sp)
    80003d46:	6121                	addi	sp,sp,64
    80003d48:	8082                	ret
    iput(ip);
    80003d4a:	00000097          	auipc	ra,0x0
    80003d4e:	a30080e7          	jalr	-1488(ra) # 8000377a <iput>
    return -1;
    80003d52:	557d                	li	a0,-1
    80003d54:	b7dd                	j	80003d3a <dirlink+0x86>
      panic("dirlink read");
    80003d56:	00005517          	auipc	a0,0x5
    80003d5a:	8ba50513          	addi	a0,a0,-1862 # 80008610 <syscalls+0x1c8>
    80003d5e:	ffffc097          	auipc	ra,0xffffc
    80003d62:	7e0080e7          	jalr	2016(ra) # 8000053e <panic>
    panic("dirlink");
    80003d66:	00005517          	auipc	a0,0x5
    80003d6a:	9ba50513          	addi	a0,a0,-1606 # 80008720 <syscalls+0x2d8>
    80003d6e:	ffffc097          	auipc	ra,0xffffc
    80003d72:	7d0080e7          	jalr	2000(ra) # 8000053e <panic>

0000000080003d76 <namei>:

struct inode*
namei(char *path)
{
    80003d76:	1101                	addi	sp,sp,-32
    80003d78:	ec06                	sd	ra,24(sp)
    80003d7a:	e822                	sd	s0,16(sp)
    80003d7c:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80003d7e:	fe040613          	addi	a2,s0,-32
    80003d82:	4581                	li	a1,0
    80003d84:	00000097          	auipc	ra,0x0
    80003d88:	dd0080e7          	jalr	-560(ra) # 80003b54 <namex>
}
    80003d8c:	60e2                	ld	ra,24(sp)
    80003d8e:	6442                	ld	s0,16(sp)
    80003d90:	6105                	addi	sp,sp,32
    80003d92:	8082                	ret

0000000080003d94 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80003d94:	1141                	addi	sp,sp,-16
    80003d96:	e406                	sd	ra,8(sp)
    80003d98:	e022                	sd	s0,0(sp)
    80003d9a:	0800                	addi	s0,sp,16
    80003d9c:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80003d9e:	4585                	li	a1,1
    80003da0:	00000097          	auipc	ra,0x0
    80003da4:	db4080e7          	jalr	-588(ra) # 80003b54 <namex>
}
    80003da8:	60a2                	ld	ra,8(sp)
    80003daa:	6402                	ld	s0,0(sp)
    80003dac:	0141                	addi	sp,sp,16
    80003dae:	8082                	ret

0000000080003db0 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80003db0:	1101                	addi	sp,sp,-32
    80003db2:	ec06                	sd	ra,24(sp)
    80003db4:	e822                	sd	s0,16(sp)
    80003db6:	e426                	sd	s1,8(sp)
    80003db8:	e04a                	sd	s2,0(sp)
    80003dba:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80003dbc:	0001d917          	auipc	s2,0x1d
    80003dc0:	4b490913          	addi	s2,s2,1204 # 80021270 <log>
    80003dc4:	01892583          	lw	a1,24(s2)
    80003dc8:	02892503          	lw	a0,40(s2)
    80003dcc:	fffff097          	auipc	ra,0xfffff
    80003dd0:	ff2080e7          	jalr	-14(ra) # 80002dbe <bread>
    80003dd4:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80003dd6:	02c92683          	lw	a3,44(s2)
    80003dda:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80003ddc:	02d05763          	blez	a3,80003e0a <write_head+0x5a>
    80003de0:	0001d797          	auipc	a5,0x1d
    80003de4:	4c078793          	addi	a5,a5,1216 # 800212a0 <log+0x30>
    80003de8:	05c50713          	addi	a4,a0,92
    80003dec:	36fd                	addiw	a3,a3,-1
    80003dee:	1682                	slli	a3,a3,0x20
    80003df0:	9281                	srli	a3,a3,0x20
    80003df2:	068a                	slli	a3,a3,0x2
    80003df4:	0001d617          	auipc	a2,0x1d
    80003df8:	4b060613          	addi	a2,a2,1200 # 800212a4 <log+0x34>
    80003dfc:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80003dfe:	4390                	lw	a2,0(a5)
    80003e00:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80003e02:	0791                	addi	a5,a5,4
    80003e04:	0711                	addi	a4,a4,4
    80003e06:	fed79ce3          	bne	a5,a3,80003dfe <write_head+0x4e>
  }
  bwrite(buf);
    80003e0a:	8526                	mv	a0,s1
    80003e0c:	fffff097          	auipc	ra,0xfffff
    80003e10:	0a4080e7          	jalr	164(ra) # 80002eb0 <bwrite>
  brelse(buf);
    80003e14:	8526                	mv	a0,s1
    80003e16:	fffff097          	auipc	ra,0xfffff
    80003e1a:	0d8080e7          	jalr	216(ra) # 80002eee <brelse>
}
    80003e1e:	60e2                	ld	ra,24(sp)
    80003e20:	6442                	ld	s0,16(sp)
    80003e22:	64a2                	ld	s1,8(sp)
    80003e24:	6902                	ld	s2,0(sp)
    80003e26:	6105                	addi	sp,sp,32
    80003e28:	8082                	ret

0000000080003e2a <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80003e2a:	0001d797          	auipc	a5,0x1d
    80003e2e:	4727a783          	lw	a5,1138(a5) # 8002129c <log+0x2c>
    80003e32:	0af05d63          	blez	a5,80003eec <install_trans+0xc2>
{
    80003e36:	7139                	addi	sp,sp,-64
    80003e38:	fc06                	sd	ra,56(sp)
    80003e3a:	f822                	sd	s0,48(sp)
    80003e3c:	f426                	sd	s1,40(sp)
    80003e3e:	f04a                	sd	s2,32(sp)
    80003e40:	ec4e                	sd	s3,24(sp)
    80003e42:	e852                	sd	s4,16(sp)
    80003e44:	e456                	sd	s5,8(sp)
    80003e46:	e05a                	sd	s6,0(sp)
    80003e48:	0080                	addi	s0,sp,64
    80003e4a:	8b2a                	mv	s6,a0
    80003e4c:	0001da97          	auipc	s5,0x1d
    80003e50:	454a8a93          	addi	s5,s5,1108 # 800212a0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003e54:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80003e56:	0001d997          	auipc	s3,0x1d
    80003e5a:	41a98993          	addi	s3,s3,1050 # 80021270 <log>
    80003e5e:	a035                	j	80003e8a <install_trans+0x60>
      bunpin(dbuf);
    80003e60:	8526                	mv	a0,s1
    80003e62:	fffff097          	auipc	ra,0xfffff
    80003e66:	166080e7          	jalr	358(ra) # 80002fc8 <bunpin>
    brelse(lbuf);
    80003e6a:	854a                	mv	a0,s2
    80003e6c:	fffff097          	auipc	ra,0xfffff
    80003e70:	082080e7          	jalr	130(ra) # 80002eee <brelse>
    brelse(dbuf);
    80003e74:	8526                	mv	a0,s1
    80003e76:	fffff097          	auipc	ra,0xfffff
    80003e7a:	078080e7          	jalr	120(ra) # 80002eee <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003e7e:	2a05                	addiw	s4,s4,1
    80003e80:	0a91                	addi	s5,s5,4
    80003e82:	02c9a783          	lw	a5,44(s3)
    80003e86:	04fa5963          	bge	s4,a5,80003ed8 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80003e8a:	0189a583          	lw	a1,24(s3)
    80003e8e:	014585bb          	addw	a1,a1,s4
    80003e92:	2585                	addiw	a1,a1,1
    80003e94:	0289a503          	lw	a0,40(s3)
    80003e98:	fffff097          	auipc	ra,0xfffff
    80003e9c:	f26080e7          	jalr	-218(ra) # 80002dbe <bread>
    80003ea0:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80003ea2:	000aa583          	lw	a1,0(s5)
    80003ea6:	0289a503          	lw	a0,40(s3)
    80003eaa:	fffff097          	auipc	ra,0xfffff
    80003eae:	f14080e7          	jalr	-236(ra) # 80002dbe <bread>
    80003eb2:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80003eb4:	40000613          	li	a2,1024
    80003eb8:	05890593          	addi	a1,s2,88
    80003ebc:	05850513          	addi	a0,a0,88
    80003ec0:	ffffd097          	auipc	ra,0xffffd
    80003ec4:	e80080e7          	jalr	-384(ra) # 80000d40 <memmove>
    bwrite(dbuf);  // write dst to disk
    80003ec8:	8526                	mv	a0,s1
    80003eca:	fffff097          	auipc	ra,0xfffff
    80003ece:	fe6080e7          	jalr	-26(ra) # 80002eb0 <bwrite>
    if(recovering == 0)
    80003ed2:	f80b1ce3          	bnez	s6,80003e6a <install_trans+0x40>
    80003ed6:	b769                	j	80003e60 <install_trans+0x36>
}
    80003ed8:	70e2                	ld	ra,56(sp)
    80003eda:	7442                	ld	s0,48(sp)
    80003edc:	74a2                	ld	s1,40(sp)
    80003ede:	7902                	ld	s2,32(sp)
    80003ee0:	69e2                	ld	s3,24(sp)
    80003ee2:	6a42                	ld	s4,16(sp)
    80003ee4:	6aa2                	ld	s5,8(sp)
    80003ee6:	6b02                	ld	s6,0(sp)
    80003ee8:	6121                	addi	sp,sp,64
    80003eea:	8082                	ret
    80003eec:	8082                	ret

0000000080003eee <initlog>:
{
    80003eee:	7179                	addi	sp,sp,-48
    80003ef0:	f406                	sd	ra,40(sp)
    80003ef2:	f022                	sd	s0,32(sp)
    80003ef4:	ec26                	sd	s1,24(sp)
    80003ef6:	e84a                	sd	s2,16(sp)
    80003ef8:	e44e                	sd	s3,8(sp)
    80003efa:	1800                	addi	s0,sp,48
    80003efc:	892a                	mv	s2,a0
    80003efe:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80003f00:	0001d497          	auipc	s1,0x1d
    80003f04:	37048493          	addi	s1,s1,880 # 80021270 <log>
    80003f08:	00004597          	auipc	a1,0x4
    80003f0c:	71858593          	addi	a1,a1,1816 # 80008620 <syscalls+0x1d8>
    80003f10:	8526                	mv	a0,s1
    80003f12:	ffffd097          	auipc	ra,0xffffd
    80003f16:	c42080e7          	jalr	-958(ra) # 80000b54 <initlock>
  log.start = sb->logstart;
    80003f1a:	0149a583          	lw	a1,20(s3)
    80003f1e:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80003f20:	0109a783          	lw	a5,16(s3)
    80003f24:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80003f26:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80003f2a:	854a                	mv	a0,s2
    80003f2c:	fffff097          	auipc	ra,0xfffff
    80003f30:	e92080e7          	jalr	-366(ra) # 80002dbe <bread>
  log.lh.n = lh->n;
    80003f34:	4d3c                	lw	a5,88(a0)
    80003f36:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80003f38:	02f05563          	blez	a5,80003f62 <initlog+0x74>
    80003f3c:	05c50713          	addi	a4,a0,92
    80003f40:	0001d697          	auipc	a3,0x1d
    80003f44:	36068693          	addi	a3,a3,864 # 800212a0 <log+0x30>
    80003f48:	37fd                	addiw	a5,a5,-1
    80003f4a:	1782                	slli	a5,a5,0x20
    80003f4c:	9381                	srli	a5,a5,0x20
    80003f4e:	078a                	slli	a5,a5,0x2
    80003f50:	06050613          	addi	a2,a0,96
    80003f54:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    80003f56:	4310                	lw	a2,0(a4)
    80003f58:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    80003f5a:	0711                	addi	a4,a4,4
    80003f5c:	0691                	addi	a3,a3,4
    80003f5e:	fef71ce3          	bne	a4,a5,80003f56 <initlog+0x68>
  brelse(buf);
    80003f62:	fffff097          	auipc	ra,0xfffff
    80003f66:	f8c080e7          	jalr	-116(ra) # 80002eee <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80003f6a:	4505                	li	a0,1
    80003f6c:	00000097          	auipc	ra,0x0
    80003f70:	ebe080e7          	jalr	-322(ra) # 80003e2a <install_trans>
  log.lh.n = 0;
    80003f74:	0001d797          	auipc	a5,0x1d
    80003f78:	3207a423          	sw	zero,808(a5) # 8002129c <log+0x2c>
  write_head(); // clear the log
    80003f7c:	00000097          	auipc	ra,0x0
    80003f80:	e34080e7          	jalr	-460(ra) # 80003db0 <write_head>
}
    80003f84:	70a2                	ld	ra,40(sp)
    80003f86:	7402                	ld	s0,32(sp)
    80003f88:	64e2                	ld	s1,24(sp)
    80003f8a:	6942                	ld	s2,16(sp)
    80003f8c:	69a2                	ld	s3,8(sp)
    80003f8e:	6145                	addi	sp,sp,48
    80003f90:	8082                	ret

0000000080003f92 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80003f92:	1101                	addi	sp,sp,-32
    80003f94:	ec06                	sd	ra,24(sp)
    80003f96:	e822                	sd	s0,16(sp)
    80003f98:	e426                	sd	s1,8(sp)
    80003f9a:	e04a                	sd	s2,0(sp)
    80003f9c:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80003f9e:	0001d517          	auipc	a0,0x1d
    80003fa2:	2d250513          	addi	a0,a0,722 # 80021270 <log>
    80003fa6:	ffffd097          	auipc	ra,0xffffd
    80003faa:	c3e080e7          	jalr	-962(ra) # 80000be4 <acquire>
  while(1){
    if(log.committing){
    80003fae:	0001d497          	auipc	s1,0x1d
    80003fb2:	2c248493          	addi	s1,s1,706 # 80021270 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80003fb6:	4979                	li	s2,30
    80003fb8:	a039                	j	80003fc6 <begin_op+0x34>
      sleep(&log, &log.lock);
    80003fba:	85a6                	mv	a1,s1
    80003fbc:	8526                	mv	a0,s1
    80003fbe:	ffffe097          	auipc	ra,0xffffe
    80003fc2:	0a0080e7          	jalr	160(ra) # 8000205e <sleep>
    if(log.committing){
    80003fc6:	50dc                	lw	a5,36(s1)
    80003fc8:	fbed                	bnez	a5,80003fba <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80003fca:	509c                	lw	a5,32(s1)
    80003fcc:	0017871b          	addiw	a4,a5,1
    80003fd0:	0007069b          	sext.w	a3,a4
    80003fd4:	0027179b          	slliw	a5,a4,0x2
    80003fd8:	9fb9                	addw	a5,a5,a4
    80003fda:	0017979b          	slliw	a5,a5,0x1
    80003fde:	54d8                	lw	a4,44(s1)
    80003fe0:	9fb9                	addw	a5,a5,a4
    80003fe2:	00f95963          	bge	s2,a5,80003ff4 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80003fe6:	85a6                	mv	a1,s1
    80003fe8:	8526                	mv	a0,s1
    80003fea:	ffffe097          	auipc	ra,0xffffe
    80003fee:	074080e7          	jalr	116(ra) # 8000205e <sleep>
    80003ff2:	bfd1                	j	80003fc6 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80003ff4:	0001d517          	auipc	a0,0x1d
    80003ff8:	27c50513          	addi	a0,a0,636 # 80021270 <log>
    80003ffc:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80003ffe:	ffffd097          	auipc	ra,0xffffd
    80004002:	c9a080e7          	jalr	-870(ra) # 80000c98 <release>
      break;
    }
  }
}
    80004006:	60e2                	ld	ra,24(sp)
    80004008:	6442                	ld	s0,16(sp)
    8000400a:	64a2                	ld	s1,8(sp)
    8000400c:	6902                	ld	s2,0(sp)
    8000400e:	6105                	addi	sp,sp,32
    80004010:	8082                	ret

0000000080004012 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004012:	7139                	addi	sp,sp,-64
    80004014:	fc06                	sd	ra,56(sp)
    80004016:	f822                	sd	s0,48(sp)
    80004018:	f426                	sd	s1,40(sp)
    8000401a:	f04a                	sd	s2,32(sp)
    8000401c:	ec4e                	sd	s3,24(sp)
    8000401e:	e852                	sd	s4,16(sp)
    80004020:	e456                	sd	s5,8(sp)
    80004022:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004024:	0001d497          	auipc	s1,0x1d
    80004028:	24c48493          	addi	s1,s1,588 # 80021270 <log>
    8000402c:	8526                	mv	a0,s1
    8000402e:	ffffd097          	auipc	ra,0xffffd
    80004032:	bb6080e7          	jalr	-1098(ra) # 80000be4 <acquire>
  log.outstanding -= 1;
    80004036:	509c                	lw	a5,32(s1)
    80004038:	37fd                	addiw	a5,a5,-1
    8000403a:	0007891b          	sext.w	s2,a5
    8000403e:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004040:	50dc                	lw	a5,36(s1)
    80004042:	efb9                	bnez	a5,800040a0 <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004044:	06091663          	bnez	s2,800040b0 <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    80004048:	0001d497          	auipc	s1,0x1d
    8000404c:	22848493          	addi	s1,s1,552 # 80021270 <log>
    80004050:	4785                	li	a5,1
    80004052:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004054:	8526                	mv	a0,s1
    80004056:	ffffd097          	auipc	ra,0xffffd
    8000405a:	c42080e7          	jalr	-958(ra) # 80000c98 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    8000405e:	54dc                	lw	a5,44(s1)
    80004060:	06f04763          	bgtz	a5,800040ce <end_op+0xbc>
    acquire(&log.lock);
    80004064:	0001d497          	auipc	s1,0x1d
    80004068:	20c48493          	addi	s1,s1,524 # 80021270 <log>
    8000406c:	8526                	mv	a0,s1
    8000406e:	ffffd097          	auipc	ra,0xffffd
    80004072:	b76080e7          	jalr	-1162(ra) # 80000be4 <acquire>
    log.committing = 0;
    80004076:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    8000407a:	8526                	mv	a0,s1
    8000407c:	ffffe097          	auipc	ra,0xffffe
    80004080:	16e080e7          	jalr	366(ra) # 800021ea <wakeup>
    release(&log.lock);
    80004084:	8526                	mv	a0,s1
    80004086:	ffffd097          	auipc	ra,0xffffd
    8000408a:	c12080e7          	jalr	-1006(ra) # 80000c98 <release>
}
    8000408e:	70e2                	ld	ra,56(sp)
    80004090:	7442                	ld	s0,48(sp)
    80004092:	74a2                	ld	s1,40(sp)
    80004094:	7902                	ld	s2,32(sp)
    80004096:	69e2                	ld	s3,24(sp)
    80004098:	6a42                	ld	s4,16(sp)
    8000409a:	6aa2                	ld	s5,8(sp)
    8000409c:	6121                	addi	sp,sp,64
    8000409e:	8082                	ret
    panic("log.committing");
    800040a0:	00004517          	auipc	a0,0x4
    800040a4:	58850513          	addi	a0,a0,1416 # 80008628 <syscalls+0x1e0>
    800040a8:	ffffc097          	auipc	ra,0xffffc
    800040ac:	496080e7          	jalr	1174(ra) # 8000053e <panic>
    wakeup(&log);
    800040b0:	0001d497          	auipc	s1,0x1d
    800040b4:	1c048493          	addi	s1,s1,448 # 80021270 <log>
    800040b8:	8526                	mv	a0,s1
    800040ba:	ffffe097          	auipc	ra,0xffffe
    800040be:	130080e7          	jalr	304(ra) # 800021ea <wakeup>
  release(&log.lock);
    800040c2:	8526                	mv	a0,s1
    800040c4:	ffffd097          	auipc	ra,0xffffd
    800040c8:	bd4080e7          	jalr	-1068(ra) # 80000c98 <release>
  if(do_commit){
    800040cc:	b7c9                	j	8000408e <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    800040ce:	0001da97          	auipc	s5,0x1d
    800040d2:	1d2a8a93          	addi	s5,s5,466 # 800212a0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    800040d6:	0001da17          	auipc	s4,0x1d
    800040da:	19aa0a13          	addi	s4,s4,410 # 80021270 <log>
    800040de:	018a2583          	lw	a1,24(s4)
    800040e2:	012585bb          	addw	a1,a1,s2
    800040e6:	2585                	addiw	a1,a1,1
    800040e8:	028a2503          	lw	a0,40(s4)
    800040ec:	fffff097          	auipc	ra,0xfffff
    800040f0:	cd2080e7          	jalr	-814(ra) # 80002dbe <bread>
    800040f4:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    800040f6:	000aa583          	lw	a1,0(s5)
    800040fa:	028a2503          	lw	a0,40(s4)
    800040fe:	fffff097          	auipc	ra,0xfffff
    80004102:	cc0080e7          	jalr	-832(ra) # 80002dbe <bread>
    80004106:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004108:	40000613          	li	a2,1024
    8000410c:	05850593          	addi	a1,a0,88
    80004110:	05848513          	addi	a0,s1,88
    80004114:	ffffd097          	auipc	ra,0xffffd
    80004118:	c2c080e7          	jalr	-980(ra) # 80000d40 <memmove>
    bwrite(to);  // write the log
    8000411c:	8526                	mv	a0,s1
    8000411e:	fffff097          	auipc	ra,0xfffff
    80004122:	d92080e7          	jalr	-622(ra) # 80002eb0 <bwrite>
    brelse(from);
    80004126:	854e                	mv	a0,s3
    80004128:	fffff097          	auipc	ra,0xfffff
    8000412c:	dc6080e7          	jalr	-570(ra) # 80002eee <brelse>
    brelse(to);
    80004130:	8526                	mv	a0,s1
    80004132:	fffff097          	auipc	ra,0xfffff
    80004136:	dbc080e7          	jalr	-580(ra) # 80002eee <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000413a:	2905                	addiw	s2,s2,1
    8000413c:	0a91                	addi	s5,s5,4
    8000413e:	02ca2783          	lw	a5,44(s4)
    80004142:	f8f94ee3          	blt	s2,a5,800040de <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004146:	00000097          	auipc	ra,0x0
    8000414a:	c6a080e7          	jalr	-918(ra) # 80003db0 <write_head>
    install_trans(0); // Now install writes to home locations
    8000414e:	4501                	li	a0,0
    80004150:	00000097          	auipc	ra,0x0
    80004154:	cda080e7          	jalr	-806(ra) # 80003e2a <install_trans>
    log.lh.n = 0;
    80004158:	0001d797          	auipc	a5,0x1d
    8000415c:	1407a223          	sw	zero,324(a5) # 8002129c <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004160:	00000097          	auipc	ra,0x0
    80004164:	c50080e7          	jalr	-944(ra) # 80003db0 <write_head>
    80004168:	bdf5                	j	80004064 <end_op+0x52>

000000008000416a <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    8000416a:	1101                	addi	sp,sp,-32
    8000416c:	ec06                	sd	ra,24(sp)
    8000416e:	e822                	sd	s0,16(sp)
    80004170:	e426                	sd	s1,8(sp)
    80004172:	e04a                	sd	s2,0(sp)
    80004174:	1000                	addi	s0,sp,32
    80004176:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004178:	0001d917          	auipc	s2,0x1d
    8000417c:	0f890913          	addi	s2,s2,248 # 80021270 <log>
    80004180:	854a                	mv	a0,s2
    80004182:	ffffd097          	auipc	ra,0xffffd
    80004186:	a62080e7          	jalr	-1438(ra) # 80000be4 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    8000418a:	02c92603          	lw	a2,44(s2)
    8000418e:	47f5                	li	a5,29
    80004190:	06c7c563          	blt	a5,a2,800041fa <log_write+0x90>
    80004194:	0001d797          	auipc	a5,0x1d
    80004198:	0f87a783          	lw	a5,248(a5) # 8002128c <log+0x1c>
    8000419c:	37fd                	addiw	a5,a5,-1
    8000419e:	04f65e63          	bge	a2,a5,800041fa <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    800041a2:	0001d797          	auipc	a5,0x1d
    800041a6:	0ee7a783          	lw	a5,238(a5) # 80021290 <log+0x20>
    800041aa:	06f05063          	blez	a5,8000420a <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    800041ae:	4781                	li	a5,0
    800041b0:	06c05563          	blez	a2,8000421a <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    800041b4:	44cc                	lw	a1,12(s1)
    800041b6:	0001d717          	auipc	a4,0x1d
    800041ba:	0ea70713          	addi	a4,a4,234 # 800212a0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    800041be:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    800041c0:	4314                	lw	a3,0(a4)
    800041c2:	04b68c63          	beq	a3,a1,8000421a <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    800041c6:	2785                	addiw	a5,a5,1
    800041c8:	0711                	addi	a4,a4,4
    800041ca:	fef61be3          	bne	a2,a5,800041c0 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    800041ce:	0621                	addi	a2,a2,8
    800041d0:	060a                	slli	a2,a2,0x2
    800041d2:	0001d797          	auipc	a5,0x1d
    800041d6:	09e78793          	addi	a5,a5,158 # 80021270 <log>
    800041da:	963e                	add	a2,a2,a5
    800041dc:	44dc                	lw	a5,12(s1)
    800041de:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    800041e0:	8526                	mv	a0,s1
    800041e2:	fffff097          	auipc	ra,0xfffff
    800041e6:	daa080e7          	jalr	-598(ra) # 80002f8c <bpin>
    log.lh.n++;
    800041ea:	0001d717          	auipc	a4,0x1d
    800041ee:	08670713          	addi	a4,a4,134 # 80021270 <log>
    800041f2:	575c                	lw	a5,44(a4)
    800041f4:	2785                	addiw	a5,a5,1
    800041f6:	d75c                	sw	a5,44(a4)
    800041f8:	a835                	j	80004234 <log_write+0xca>
    panic("too big a transaction");
    800041fa:	00004517          	auipc	a0,0x4
    800041fe:	43e50513          	addi	a0,a0,1086 # 80008638 <syscalls+0x1f0>
    80004202:	ffffc097          	auipc	ra,0xffffc
    80004206:	33c080e7          	jalr	828(ra) # 8000053e <panic>
    panic("log_write outside of trans");
    8000420a:	00004517          	auipc	a0,0x4
    8000420e:	44650513          	addi	a0,a0,1094 # 80008650 <syscalls+0x208>
    80004212:	ffffc097          	auipc	ra,0xffffc
    80004216:	32c080e7          	jalr	812(ra) # 8000053e <panic>
  log.lh.block[i] = b->blockno;
    8000421a:	00878713          	addi	a4,a5,8
    8000421e:	00271693          	slli	a3,a4,0x2
    80004222:	0001d717          	auipc	a4,0x1d
    80004226:	04e70713          	addi	a4,a4,78 # 80021270 <log>
    8000422a:	9736                	add	a4,a4,a3
    8000422c:	44d4                	lw	a3,12(s1)
    8000422e:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004230:	faf608e3          	beq	a2,a5,800041e0 <log_write+0x76>
  }
  release(&log.lock);
    80004234:	0001d517          	auipc	a0,0x1d
    80004238:	03c50513          	addi	a0,a0,60 # 80021270 <log>
    8000423c:	ffffd097          	auipc	ra,0xffffd
    80004240:	a5c080e7          	jalr	-1444(ra) # 80000c98 <release>
}
    80004244:	60e2                	ld	ra,24(sp)
    80004246:	6442                	ld	s0,16(sp)
    80004248:	64a2                	ld	s1,8(sp)
    8000424a:	6902                	ld	s2,0(sp)
    8000424c:	6105                	addi	sp,sp,32
    8000424e:	8082                	ret

0000000080004250 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004250:	1101                	addi	sp,sp,-32
    80004252:	ec06                	sd	ra,24(sp)
    80004254:	e822                	sd	s0,16(sp)
    80004256:	e426                	sd	s1,8(sp)
    80004258:	e04a                	sd	s2,0(sp)
    8000425a:	1000                	addi	s0,sp,32
    8000425c:	84aa                	mv	s1,a0
    8000425e:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004260:	00004597          	auipc	a1,0x4
    80004264:	41058593          	addi	a1,a1,1040 # 80008670 <syscalls+0x228>
    80004268:	0521                	addi	a0,a0,8
    8000426a:	ffffd097          	auipc	ra,0xffffd
    8000426e:	8ea080e7          	jalr	-1814(ra) # 80000b54 <initlock>
  lk->name = name;
    80004272:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004276:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    8000427a:	0204a423          	sw	zero,40(s1)
}
    8000427e:	60e2                	ld	ra,24(sp)
    80004280:	6442                	ld	s0,16(sp)
    80004282:	64a2                	ld	s1,8(sp)
    80004284:	6902                	ld	s2,0(sp)
    80004286:	6105                	addi	sp,sp,32
    80004288:	8082                	ret

000000008000428a <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    8000428a:	1101                	addi	sp,sp,-32
    8000428c:	ec06                	sd	ra,24(sp)
    8000428e:	e822                	sd	s0,16(sp)
    80004290:	e426                	sd	s1,8(sp)
    80004292:	e04a                	sd	s2,0(sp)
    80004294:	1000                	addi	s0,sp,32
    80004296:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004298:	00850913          	addi	s2,a0,8
    8000429c:	854a                	mv	a0,s2
    8000429e:	ffffd097          	auipc	ra,0xffffd
    800042a2:	946080e7          	jalr	-1722(ra) # 80000be4 <acquire>
  while (lk->locked) {
    800042a6:	409c                	lw	a5,0(s1)
    800042a8:	cb89                	beqz	a5,800042ba <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    800042aa:	85ca                	mv	a1,s2
    800042ac:	8526                	mv	a0,s1
    800042ae:	ffffe097          	auipc	ra,0xffffe
    800042b2:	db0080e7          	jalr	-592(ra) # 8000205e <sleep>
  while (lk->locked) {
    800042b6:	409c                	lw	a5,0(s1)
    800042b8:	fbed                	bnez	a5,800042aa <acquiresleep+0x20>
  }
  lk->locked = 1;
    800042ba:	4785                	li	a5,1
    800042bc:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    800042be:	ffffd097          	auipc	ra,0xffffd
    800042c2:	6f2080e7          	jalr	1778(ra) # 800019b0 <myproc>
    800042c6:	591c                	lw	a5,48(a0)
    800042c8:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    800042ca:	854a                	mv	a0,s2
    800042cc:	ffffd097          	auipc	ra,0xffffd
    800042d0:	9cc080e7          	jalr	-1588(ra) # 80000c98 <release>
}
    800042d4:	60e2                	ld	ra,24(sp)
    800042d6:	6442                	ld	s0,16(sp)
    800042d8:	64a2                	ld	s1,8(sp)
    800042da:	6902                	ld	s2,0(sp)
    800042dc:	6105                	addi	sp,sp,32
    800042de:	8082                	ret

00000000800042e0 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    800042e0:	1101                	addi	sp,sp,-32
    800042e2:	ec06                	sd	ra,24(sp)
    800042e4:	e822                	sd	s0,16(sp)
    800042e6:	e426                	sd	s1,8(sp)
    800042e8:	e04a                	sd	s2,0(sp)
    800042ea:	1000                	addi	s0,sp,32
    800042ec:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800042ee:	00850913          	addi	s2,a0,8
    800042f2:	854a                	mv	a0,s2
    800042f4:	ffffd097          	auipc	ra,0xffffd
    800042f8:	8f0080e7          	jalr	-1808(ra) # 80000be4 <acquire>
  lk->locked = 0;
    800042fc:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004300:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004304:	8526                	mv	a0,s1
    80004306:	ffffe097          	auipc	ra,0xffffe
    8000430a:	ee4080e7          	jalr	-284(ra) # 800021ea <wakeup>
  release(&lk->lk);
    8000430e:	854a                	mv	a0,s2
    80004310:	ffffd097          	auipc	ra,0xffffd
    80004314:	988080e7          	jalr	-1656(ra) # 80000c98 <release>
}
    80004318:	60e2                	ld	ra,24(sp)
    8000431a:	6442                	ld	s0,16(sp)
    8000431c:	64a2                	ld	s1,8(sp)
    8000431e:	6902                	ld	s2,0(sp)
    80004320:	6105                	addi	sp,sp,32
    80004322:	8082                	ret

0000000080004324 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004324:	7179                	addi	sp,sp,-48
    80004326:	f406                	sd	ra,40(sp)
    80004328:	f022                	sd	s0,32(sp)
    8000432a:	ec26                	sd	s1,24(sp)
    8000432c:	e84a                	sd	s2,16(sp)
    8000432e:	e44e                	sd	s3,8(sp)
    80004330:	1800                	addi	s0,sp,48
    80004332:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004334:	00850913          	addi	s2,a0,8
    80004338:	854a                	mv	a0,s2
    8000433a:	ffffd097          	auipc	ra,0xffffd
    8000433e:	8aa080e7          	jalr	-1878(ra) # 80000be4 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004342:	409c                	lw	a5,0(s1)
    80004344:	ef99                	bnez	a5,80004362 <holdingsleep+0x3e>
    80004346:	4481                	li	s1,0
  release(&lk->lk);
    80004348:	854a                	mv	a0,s2
    8000434a:	ffffd097          	auipc	ra,0xffffd
    8000434e:	94e080e7          	jalr	-1714(ra) # 80000c98 <release>
  return r;
}
    80004352:	8526                	mv	a0,s1
    80004354:	70a2                	ld	ra,40(sp)
    80004356:	7402                	ld	s0,32(sp)
    80004358:	64e2                	ld	s1,24(sp)
    8000435a:	6942                	ld	s2,16(sp)
    8000435c:	69a2                	ld	s3,8(sp)
    8000435e:	6145                	addi	sp,sp,48
    80004360:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004362:	0284a983          	lw	s3,40(s1)
    80004366:	ffffd097          	auipc	ra,0xffffd
    8000436a:	64a080e7          	jalr	1610(ra) # 800019b0 <myproc>
    8000436e:	5904                	lw	s1,48(a0)
    80004370:	413484b3          	sub	s1,s1,s3
    80004374:	0014b493          	seqz	s1,s1
    80004378:	bfc1                	j	80004348 <holdingsleep+0x24>

000000008000437a <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    8000437a:	1141                	addi	sp,sp,-16
    8000437c:	e406                	sd	ra,8(sp)
    8000437e:	e022                	sd	s0,0(sp)
    80004380:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004382:	00004597          	auipc	a1,0x4
    80004386:	2fe58593          	addi	a1,a1,766 # 80008680 <syscalls+0x238>
    8000438a:	0001d517          	auipc	a0,0x1d
    8000438e:	02e50513          	addi	a0,a0,46 # 800213b8 <ftable>
    80004392:	ffffc097          	auipc	ra,0xffffc
    80004396:	7c2080e7          	jalr	1986(ra) # 80000b54 <initlock>
}
    8000439a:	60a2                	ld	ra,8(sp)
    8000439c:	6402                	ld	s0,0(sp)
    8000439e:	0141                	addi	sp,sp,16
    800043a0:	8082                	ret

00000000800043a2 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    800043a2:	1101                	addi	sp,sp,-32
    800043a4:	ec06                	sd	ra,24(sp)
    800043a6:	e822                	sd	s0,16(sp)
    800043a8:	e426                	sd	s1,8(sp)
    800043aa:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    800043ac:	0001d517          	auipc	a0,0x1d
    800043b0:	00c50513          	addi	a0,a0,12 # 800213b8 <ftable>
    800043b4:	ffffd097          	auipc	ra,0xffffd
    800043b8:	830080e7          	jalr	-2000(ra) # 80000be4 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800043bc:	0001d497          	auipc	s1,0x1d
    800043c0:	01448493          	addi	s1,s1,20 # 800213d0 <ftable+0x18>
    800043c4:	0001e717          	auipc	a4,0x1e
    800043c8:	fac70713          	addi	a4,a4,-84 # 80022370 <ftable+0xfb8>
    if(f->ref == 0){
    800043cc:	40dc                	lw	a5,4(s1)
    800043ce:	cf99                	beqz	a5,800043ec <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800043d0:	02848493          	addi	s1,s1,40
    800043d4:	fee49ce3          	bne	s1,a4,800043cc <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    800043d8:	0001d517          	auipc	a0,0x1d
    800043dc:	fe050513          	addi	a0,a0,-32 # 800213b8 <ftable>
    800043e0:	ffffd097          	auipc	ra,0xffffd
    800043e4:	8b8080e7          	jalr	-1864(ra) # 80000c98 <release>
  return 0;
    800043e8:	4481                	li	s1,0
    800043ea:	a819                	j	80004400 <filealloc+0x5e>
      f->ref = 1;
    800043ec:	4785                	li	a5,1
    800043ee:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    800043f0:	0001d517          	auipc	a0,0x1d
    800043f4:	fc850513          	addi	a0,a0,-56 # 800213b8 <ftable>
    800043f8:	ffffd097          	auipc	ra,0xffffd
    800043fc:	8a0080e7          	jalr	-1888(ra) # 80000c98 <release>
}
    80004400:	8526                	mv	a0,s1
    80004402:	60e2                	ld	ra,24(sp)
    80004404:	6442                	ld	s0,16(sp)
    80004406:	64a2                	ld	s1,8(sp)
    80004408:	6105                	addi	sp,sp,32
    8000440a:	8082                	ret

000000008000440c <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    8000440c:	1101                	addi	sp,sp,-32
    8000440e:	ec06                	sd	ra,24(sp)
    80004410:	e822                	sd	s0,16(sp)
    80004412:	e426                	sd	s1,8(sp)
    80004414:	1000                	addi	s0,sp,32
    80004416:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004418:	0001d517          	auipc	a0,0x1d
    8000441c:	fa050513          	addi	a0,a0,-96 # 800213b8 <ftable>
    80004420:	ffffc097          	auipc	ra,0xffffc
    80004424:	7c4080e7          	jalr	1988(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    80004428:	40dc                	lw	a5,4(s1)
    8000442a:	02f05263          	blez	a5,8000444e <filedup+0x42>
    panic("filedup");
  f->ref++;
    8000442e:	2785                	addiw	a5,a5,1
    80004430:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004432:	0001d517          	auipc	a0,0x1d
    80004436:	f8650513          	addi	a0,a0,-122 # 800213b8 <ftable>
    8000443a:	ffffd097          	auipc	ra,0xffffd
    8000443e:	85e080e7          	jalr	-1954(ra) # 80000c98 <release>
  return f;
}
    80004442:	8526                	mv	a0,s1
    80004444:	60e2                	ld	ra,24(sp)
    80004446:	6442                	ld	s0,16(sp)
    80004448:	64a2                	ld	s1,8(sp)
    8000444a:	6105                	addi	sp,sp,32
    8000444c:	8082                	ret
    panic("filedup");
    8000444e:	00004517          	auipc	a0,0x4
    80004452:	23a50513          	addi	a0,a0,570 # 80008688 <syscalls+0x240>
    80004456:	ffffc097          	auipc	ra,0xffffc
    8000445a:	0e8080e7          	jalr	232(ra) # 8000053e <panic>

000000008000445e <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    8000445e:	7139                	addi	sp,sp,-64
    80004460:	fc06                	sd	ra,56(sp)
    80004462:	f822                	sd	s0,48(sp)
    80004464:	f426                	sd	s1,40(sp)
    80004466:	f04a                	sd	s2,32(sp)
    80004468:	ec4e                	sd	s3,24(sp)
    8000446a:	e852                	sd	s4,16(sp)
    8000446c:	e456                	sd	s5,8(sp)
    8000446e:	0080                	addi	s0,sp,64
    80004470:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004472:	0001d517          	auipc	a0,0x1d
    80004476:	f4650513          	addi	a0,a0,-186 # 800213b8 <ftable>
    8000447a:	ffffc097          	auipc	ra,0xffffc
    8000447e:	76a080e7          	jalr	1898(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    80004482:	40dc                	lw	a5,4(s1)
    80004484:	06f05163          	blez	a5,800044e6 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004488:	37fd                	addiw	a5,a5,-1
    8000448a:	0007871b          	sext.w	a4,a5
    8000448e:	c0dc                	sw	a5,4(s1)
    80004490:	06e04363          	bgtz	a4,800044f6 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004494:	0004a903          	lw	s2,0(s1)
    80004498:	0094ca83          	lbu	s5,9(s1)
    8000449c:	0104ba03          	ld	s4,16(s1)
    800044a0:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    800044a4:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    800044a8:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    800044ac:	0001d517          	auipc	a0,0x1d
    800044b0:	f0c50513          	addi	a0,a0,-244 # 800213b8 <ftable>
    800044b4:	ffffc097          	auipc	ra,0xffffc
    800044b8:	7e4080e7          	jalr	2020(ra) # 80000c98 <release>

  if(ff.type == FD_PIPE){
    800044bc:	4785                	li	a5,1
    800044be:	04f90d63          	beq	s2,a5,80004518 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    800044c2:	3979                	addiw	s2,s2,-2
    800044c4:	4785                	li	a5,1
    800044c6:	0527e063          	bltu	a5,s2,80004506 <fileclose+0xa8>
    begin_op();
    800044ca:	00000097          	auipc	ra,0x0
    800044ce:	ac8080e7          	jalr	-1336(ra) # 80003f92 <begin_op>
    iput(ff.ip);
    800044d2:	854e                	mv	a0,s3
    800044d4:	fffff097          	auipc	ra,0xfffff
    800044d8:	2a6080e7          	jalr	678(ra) # 8000377a <iput>
    end_op();
    800044dc:	00000097          	auipc	ra,0x0
    800044e0:	b36080e7          	jalr	-1226(ra) # 80004012 <end_op>
    800044e4:	a00d                	j	80004506 <fileclose+0xa8>
    panic("fileclose");
    800044e6:	00004517          	auipc	a0,0x4
    800044ea:	1aa50513          	addi	a0,a0,426 # 80008690 <syscalls+0x248>
    800044ee:	ffffc097          	auipc	ra,0xffffc
    800044f2:	050080e7          	jalr	80(ra) # 8000053e <panic>
    release(&ftable.lock);
    800044f6:	0001d517          	auipc	a0,0x1d
    800044fa:	ec250513          	addi	a0,a0,-318 # 800213b8 <ftable>
    800044fe:	ffffc097          	auipc	ra,0xffffc
    80004502:	79a080e7          	jalr	1946(ra) # 80000c98 <release>
  }
}
    80004506:	70e2                	ld	ra,56(sp)
    80004508:	7442                	ld	s0,48(sp)
    8000450a:	74a2                	ld	s1,40(sp)
    8000450c:	7902                	ld	s2,32(sp)
    8000450e:	69e2                	ld	s3,24(sp)
    80004510:	6a42                	ld	s4,16(sp)
    80004512:	6aa2                	ld	s5,8(sp)
    80004514:	6121                	addi	sp,sp,64
    80004516:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004518:	85d6                	mv	a1,s5
    8000451a:	8552                	mv	a0,s4
    8000451c:	00000097          	auipc	ra,0x0
    80004520:	34c080e7          	jalr	844(ra) # 80004868 <pipeclose>
    80004524:	b7cd                	j	80004506 <fileclose+0xa8>

0000000080004526 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004526:	715d                	addi	sp,sp,-80
    80004528:	e486                	sd	ra,72(sp)
    8000452a:	e0a2                	sd	s0,64(sp)
    8000452c:	fc26                	sd	s1,56(sp)
    8000452e:	f84a                	sd	s2,48(sp)
    80004530:	f44e                	sd	s3,40(sp)
    80004532:	0880                	addi	s0,sp,80
    80004534:	84aa                	mv	s1,a0
    80004536:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004538:	ffffd097          	auipc	ra,0xffffd
    8000453c:	478080e7          	jalr	1144(ra) # 800019b0 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004540:	409c                	lw	a5,0(s1)
    80004542:	37f9                	addiw	a5,a5,-2
    80004544:	4705                	li	a4,1
    80004546:	04f76763          	bltu	a4,a5,80004594 <filestat+0x6e>
    8000454a:	892a                	mv	s2,a0
    ilock(f->ip);
    8000454c:	6c88                	ld	a0,24(s1)
    8000454e:	fffff097          	auipc	ra,0xfffff
    80004552:	072080e7          	jalr	114(ra) # 800035c0 <ilock>
    stati(f->ip, &st);
    80004556:	fb840593          	addi	a1,s0,-72
    8000455a:	6c88                	ld	a0,24(s1)
    8000455c:	fffff097          	auipc	ra,0xfffff
    80004560:	2ee080e7          	jalr	750(ra) # 8000384a <stati>
    iunlock(f->ip);
    80004564:	6c88                	ld	a0,24(s1)
    80004566:	fffff097          	auipc	ra,0xfffff
    8000456a:	11c080e7          	jalr	284(ra) # 80003682 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    8000456e:	46e1                	li	a3,24
    80004570:	fb840613          	addi	a2,s0,-72
    80004574:	85ce                	mv	a1,s3
    80004576:	05093503          	ld	a0,80(s2)
    8000457a:	ffffd097          	auipc	ra,0xffffd
    8000457e:	0f8080e7          	jalr	248(ra) # 80001672 <copyout>
    80004582:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004586:	60a6                	ld	ra,72(sp)
    80004588:	6406                	ld	s0,64(sp)
    8000458a:	74e2                	ld	s1,56(sp)
    8000458c:	7942                	ld	s2,48(sp)
    8000458e:	79a2                	ld	s3,40(sp)
    80004590:	6161                	addi	sp,sp,80
    80004592:	8082                	ret
  return -1;
    80004594:	557d                	li	a0,-1
    80004596:	bfc5                	j	80004586 <filestat+0x60>

0000000080004598 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004598:	7179                	addi	sp,sp,-48
    8000459a:	f406                	sd	ra,40(sp)
    8000459c:	f022                	sd	s0,32(sp)
    8000459e:	ec26                	sd	s1,24(sp)
    800045a0:	e84a                	sd	s2,16(sp)
    800045a2:	e44e                	sd	s3,8(sp)
    800045a4:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    800045a6:	00854783          	lbu	a5,8(a0)
    800045aa:	c3d5                	beqz	a5,8000464e <fileread+0xb6>
    800045ac:	84aa                	mv	s1,a0
    800045ae:	89ae                	mv	s3,a1
    800045b0:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    800045b2:	411c                	lw	a5,0(a0)
    800045b4:	4705                	li	a4,1
    800045b6:	04e78963          	beq	a5,a4,80004608 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800045ba:	470d                	li	a4,3
    800045bc:	04e78d63          	beq	a5,a4,80004616 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    800045c0:	4709                	li	a4,2
    800045c2:	06e79e63          	bne	a5,a4,8000463e <fileread+0xa6>
    ilock(f->ip);
    800045c6:	6d08                	ld	a0,24(a0)
    800045c8:	fffff097          	auipc	ra,0xfffff
    800045cc:	ff8080e7          	jalr	-8(ra) # 800035c0 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    800045d0:	874a                	mv	a4,s2
    800045d2:	5094                	lw	a3,32(s1)
    800045d4:	864e                	mv	a2,s3
    800045d6:	4585                	li	a1,1
    800045d8:	6c88                	ld	a0,24(s1)
    800045da:	fffff097          	auipc	ra,0xfffff
    800045de:	29a080e7          	jalr	666(ra) # 80003874 <readi>
    800045e2:	892a                	mv	s2,a0
    800045e4:	00a05563          	blez	a0,800045ee <fileread+0x56>
      f->off += r;
    800045e8:	509c                	lw	a5,32(s1)
    800045ea:	9fa9                	addw	a5,a5,a0
    800045ec:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    800045ee:	6c88                	ld	a0,24(s1)
    800045f0:	fffff097          	auipc	ra,0xfffff
    800045f4:	092080e7          	jalr	146(ra) # 80003682 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    800045f8:	854a                	mv	a0,s2
    800045fa:	70a2                	ld	ra,40(sp)
    800045fc:	7402                	ld	s0,32(sp)
    800045fe:	64e2                	ld	s1,24(sp)
    80004600:	6942                	ld	s2,16(sp)
    80004602:	69a2                	ld	s3,8(sp)
    80004604:	6145                	addi	sp,sp,48
    80004606:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004608:	6908                	ld	a0,16(a0)
    8000460a:	00000097          	auipc	ra,0x0
    8000460e:	3c8080e7          	jalr	968(ra) # 800049d2 <piperead>
    80004612:	892a                	mv	s2,a0
    80004614:	b7d5                	j	800045f8 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004616:	02451783          	lh	a5,36(a0)
    8000461a:	03079693          	slli	a3,a5,0x30
    8000461e:	92c1                	srli	a3,a3,0x30
    80004620:	4725                	li	a4,9
    80004622:	02d76863          	bltu	a4,a3,80004652 <fileread+0xba>
    80004626:	0792                	slli	a5,a5,0x4
    80004628:	0001d717          	auipc	a4,0x1d
    8000462c:	cf070713          	addi	a4,a4,-784 # 80021318 <devsw>
    80004630:	97ba                	add	a5,a5,a4
    80004632:	639c                	ld	a5,0(a5)
    80004634:	c38d                	beqz	a5,80004656 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004636:	4505                	li	a0,1
    80004638:	9782                	jalr	a5
    8000463a:	892a                	mv	s2,a0
    8000463c:	bf75                	j	800045f8 <fileread+0x60>
    panic("fileread");
    8000463e:	00004517          	auipc	a0,0x4
    80004642:	06250513          	addi	a0,a0,98 # 800086a0 <syscalls+0x258>
    80004646:	ffffc097          	auipc	ra,0xffffc
    8000464a:	ef8080e7          	jalr	-264(ra) # 8000053e <panic>
    return -1;
    8000464e:	597d                	li	s2,-1
    80004650:	b765                	j	800045f8 <fileread+0x60>
      return -1;
    80004652:	597d                	li	s2,-1
    80004654:	b755                	j	800045f8 <fileread+0x60>
    80004656:	597d                	li	s2,-1
    80004658:	b745                	j	800045f8 <fileread+0x60>

000000008000465a <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    8000465a:	715d                	addi	sp,sp,-80
    8000465c:	e486                	sd	ra,72(sp)
    8000465e:	e0a2                	sd	s0,64(sp)
    80004660:	fc26                	sd	s1,56(sp)
    80004662:	f84a                	sd	s2,48(sp)
    80004664:	f44e                	sd	s3,40(sp)
    80004666:	f052                	sd	s4,32(sp)
    80004668:	ec56                	sd	s5,24(sp)
    8000466a:	e85a                	sd	s6,16(sp)
    8000466c:	e45e                	sd	s7,8(sp)
    8000466e:	e062                	sd	s8,0(sp)
    80004670:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004672:	00954783          	lbu	a5,9(a0)
    80004676:	10078663          	beqz	a5,80004782 <filewrite+0x128>
    8000467a:	892a                	mv	s2,a0
    8000467c:	8aae                	mv	s5,a1
    8000467e:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004680:	411c                	lw	a5,0(a0)
    80004682:	4705                	li	a4,1
    80004684:	02e78263          	beq	a5,a4,800046a8 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004688:	470d                	li	a4,3
    8000468a:	02e78663          	beq	a5,a4,800046b6 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    8000468e:	4709                	li	a4,2
    80004690:	0ee79163          	bne	a5,a4,80004772 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004694:	0ac05d63          	blez	a2,8000474e <filewrite+0xf4>
    int i = 0;
    80004698:	4981                	li	s3,0
    8000469a:	6b05                	lui	s6,0x1
    8000469c:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    800046a0:	6b85                	lui	s7,0x1
    800046a2:	c00b8b9b          	addiw	s7,s7,-1024
    800046a6:	a861                	j	8000473e <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    800046a8:	6908                	ld	a0,16(a0)
    800046aa:	00000097          	auipc	ra,0x0
    800046ae:	22e080e7          	jalr	558(ra) # 800048d8 <pipewrite>
    800046b2:	8a2a                	mv	s4,a0
    800046b4:	a045                	j	80004754 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    800046b6:	02451783          	lh	a5,36(a0)
    800046ba:	03079693          	slli	a3,a5,0x30
    800046be:	92c1                	srli	a3,a3,0x30
    800046c0:	4725                	li	a4,9
    800046c2:	0cd76263          	bltu	a4,a3,80004786 <filewrite+0x12c>
    800046c6:	0792                	slli	a5,a5,0x4
    800046c8:	0001d717          	auipc	a4,0x1d
    800046cc:	c5070713          	addi	a4,a4,-944 # 80021318 <devsw>
    800046d0:	97ba                	add	a5,a5,a4
    800046d2:	679c                	ld	a5,8(a5)
    800046d4:	cbdd                	beqz	a5,8000478a <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    800046d6:	4505                	li	a0,1
    800046d8:	9782                	jalr	a5
    800046da:	8a2a                	mv	s4,a0
    800046dc:	a8a5                	j	80004754 <filewrite+0xfa>
    800046de:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    800046e2:	00000097          	auipc	ra,0x0
    800046e6:	8b0080e7          	jalr	-1872(ra) # 80003f92 <begin_op>
      ilock(f->ip);
    800046ea:	01893503          	ld	a0,24(s2)
    800046ee:	fffff097          	auipc	ra,0xfffff
    800046f2:	ed2080e7          	jalr	-302(ra) # 800035c0 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    800046f6:	8762                	mv	a4,s8
    800046f8:	02092683          	lw	a3,32(s2)
    800046fc:	01598633          	add	a2,s3,s5
    80004700:	4585                	li	a1,1
    80004702:	01893503          	ld	a0,24(s2)
    80004706:	fffff097          	auipc	ra,0xfffff
    8000470a:	266080e7          	jalr	614(ra) # 8000396c <writei>
    8000470e:	84aa                	mv	s1,a0
    80004710:	00a05763          	blez	a0,8000471e <filewrite+0xc4>
        f->off += r;
    80004714:	02092783          	lw	a5,32(s2)
    80004718:	9fa9                	addw	a5,a5,a0
    8000471a:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    8000471e:	01893503          	ld	a0,24(s2)
    80004722:	fffff097          	auipc	ra,0xfffff
    80004726:	f60080e7          	jalr	-160(ra) # 80003682 <iunlock>
      end_op();
    8000472a:	00000097          	auipc	ra,0x0
    8000472e:	8e8080e7          	jalr	-1816(ra) # 80004012 <end_op>

      if(r != n1){
    80004732:	009c1f63          	bne	s8,s1,80004750 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004736:	013489bb          	addw	s3,s1,s3
    while(i < n){
    8000473a:	0149db63          	bge	s3,s4,80004750 <filewrite+0xf6>
      int n1 = n - i;
    8000473e:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004742:	84be                	mv	s1,a5
    80004744:	2781                	sext.w	a5,a5
    80004746:	f8fb5ce3          	bge	s6,a5,800046de <filewrite+0x84>
    8000474a:	84de                	mv	s1,s7
    8000474c:	bf49                	j	800046de <filewrite+0x84>
    int i = 0;
    8000474e:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004750:	013a1f63          	bne	s4,s3,8000476e <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004754:	8552                	mv	a0,s4
    80004756:	60a6                	ld	ra,72(sp)
    80004758:	6406                	ld	s0,64(sp)
    8000475a:	74e2                	ld	s1,56(sp)
    8000475c:	7942                	ld	s2,48(sp)
    8000475e:	79a2                	ld	s3,40(sp)
    80004760:	7a02                	ld	s4,32(sp)
    80004762:	6ae2                	ld	s5,24(sp)
    80004764:	6b42                	ld	s6,16(sp)
    80004766:	6ba2                	ld	s7,8(sp)
    80004768:	6c02                	ld	s8,0(sp)
    8000476a:	6161                	addi	sp,sp,80
    8000476c:	8082                	ret
    ret = (i == n ? n : -1);
    8000476e:	5a7d                	li	s4,-1
    80004770:	b7d5                	j	80004754 <filewrite+0xfa>
    panic("filewrite");
    80004772:	00004517          	auipc	a0,0x4
    80004776:	f3e50513          	addi	a0,a0,-194 # 800086b0 <syscalls+0x268>
    8000477a:	ffffc097          	auipc	ra,0xffffc
    8000477e:	dc4080e7          	jalr	-572(ra) # 8000053e <panic>
    return -1;
    80004782:	5a7d                	li	s4,-1
    80004784:	bfc1                	j	80004754 <filewrite+0xfa>
      return -1;
    80004786:	5a7d                	li	s4,-1
    80004788:	b7f1                	j	80004754 <filewrite+0xfa>
    8000478a:	5a7d                	li	s4,-1
    8000478c:	b7e1                	j	80004754 <filewrite+0xfa>

000000008000478e <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    8000478e:	7179                	addi	sp,sp,-48
    80004790:	f406                	sd	ra,40(sp)
    80004792:	f022                	sd	s0,32(sp)
    80004794:	ec26                	sd	s1,24(sp)
    80004796:	e84a                	sd	s2,16(sp)
    80004798:	e44e                	sd	s3,8(sp)
    8000479a:	e052                	sd	s4,0(sp)
    8000479c:	1800                	addi	s0,sp,48
    8000479e:	84aa                	mv	s1,a0
    800047a0:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    800047a2:	0005b023          	sd	zero,0(a1)
    800047a6:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    800047aa:	00000097          	auipc	ra,0x0
    800047ae:	bf8080e7          	jalr	-1032(ra) # 800043a2 <filealloc>
    800047b2:	e088                	sd	a0,0(s1)
    800047b4:	c551                	beqz	a0,80004840 <pipealloc+0xb2>
    800047b6:	00000097          	auipc	ra,0x0
    800047ba:	bec080e7          	jalr	-1044(ra) # 800043a2 <filealloc>
    800047be:	00aa3023          	sd	a0,0(s4)
    800047c2:	c92d                	beqz	a0,80004834 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    800047c4:	ffffc097          	auipc	ra,0xffffc
    800047c8:	330080e7          	jalr	816(ra) # 80000af4 <kalloc>
    800047cc:	892a                	mv	s2,a0
    800047ce:	c125                	beqz	a0,8000482e <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    800047d0:	4985                	li	s3,1
    800047d2:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    800047d6:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    800047da:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    800047de:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    800047e2:	00004597          	auipc	a1,0x4
    800047e6:	ede58593          	addi	a1,a1,-290 # 800086c0 <syscalls+0x278>
    800047ea:	ffffc097          	auipc	ra,0xffffc
    800047ee:	36a080e7          	jalr	874(ra) # 80000b54 <initlock>
  (*f0)->type = FD_PIPE;
    800047f2:	609c                	ld	a5,0(s1)
    800047f4:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    800047f8:	609c                	ld	a5,0(s1)
    800047fa:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    800047fe:	609c                	ld	a5,0(s1)
    80004800:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004804:	609c                	ld	a5,0(s1)
    80004806:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    8000480a:	000a3783          	ld	a5,0(s4)
    8000480e:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004812:	000a3783          	ld	a5,0(s4)
    80004816:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    8000481a:	000a3783          	ld	a5,0(s4)
    8000481e:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004822:	000a3783          	ld	a5,0(s4)
    80004826:	0127b823          	sd	s2,16(a5)
  return 0;
    8000482a:	4501                	li	a0,0
    8000482c:	a025                	j	80004854 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    8000482e:	6088                	ld	a0,0(s1)
    80004830:	e501                	bnez	a0,80004838 <pipealloc+0xaa>
    80004832:	a039                	j	80004840 <pipealloc+0xb2>
    80004834:	6088                	ld	a0,0(s1)
    80004836:	c51d                	beqz	a0,80004864 <pipealloc+0xd6>
    fileclose(*f0);
    80004838:	00000097          	auipc	ra,0x0
    8000483c:	c26080e7          	jalr	-986(ra) # 8000445e <fileclose>
  if(*f1)
    80004840:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004844:	557d                	li	a0,-1
  if(*f1)
    80004846:	c799                	beqz	a5,80004854 <pipealloc+0xc6>
    fileclose(*f1);
    80004848:	853e                	mv	a0,a5
    8000484a:	00000097          	auipc	ra,0x0
    8000484e:	c14080e7          	jalr	-1004(ra) # 8000445e <fileclose>
  return -1;
    80004852:	557d                	li	a0,-1
}
    80004854:	70a2                	ld	ra,40(sp)
    80004856:	7402                	ld	s0,32(sp)
    80004858:	64e2                	ld	s1,24(sp)
    8000485a:	6942                	ld	s2,16(sp)
    8000485c:	69a2                	ld	s3,8(sp)
    8000485e:	6a02                	ld	s4,0(sp)
    80004860:	6145                	addi	sp,sp,48
    80004862:	8082                	ret
  return -1;
    80004864:	557d                	li	a0,-1
    80004866:	b7fd                	j	80004854 <pipealloc+0xc6>

0000000080004868 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004868:	1101                	addi	sp,sp,-32
    8000486a:	ec06                	sd	ra,24(sp)
    8000486c:	e822                	sd	s0,16(sp)
    8000486e:	e426                	sd	s1,8(sp)
    80004870:	e04a                	sd	s2,0(sp)
    80004872:	1000                	addi	s0,sp,32
    80004874:	84aa                	mv	s1,a0
    80004876:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004878:	ffffc097          	auipc	ra,0xffffc
    8000487c:	36c080e7          	jalr	876(ra) # 80000be4 <acquire>
  if(writable){
    80004880:	02090d63          	beqz	s2,800048ba <pipeclose+0x52>
    pi->writeopen = 0;
    80004884:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004888:	21848513          	addi	a0,s1,536
    8000488c:	ffffe097          	auipc	ra,0xffffe
    80004890:	95e080e7          	jalr	-1698(ra) # 800021ea <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004894:	2204b783          	ld	a5,544(s1)
    80004898:	eb95                	bnez	a5,800048cc <pipeclose+0x64>
    release(&pi->lock);
    8000489a:	8526                	mv	a0,s1
    8000489c:	ffffc097          	auipc	ra,0xffffc
    800048a0:	3fc080e7          	jalr	1020(ra) # 80000c98 <release>
    kfree((char*)pi);
    800048a4:	8526                	mv	a0,s1
    800048a6:	ffffc097          	auipc	ra,0xffffc
    800048aa:	152080e7          	jalr	338(ra) # 800009f8 <kfree>
  } else
    release(&pi->lock);
}
    800048ae:	60e2                	ld	ra,24(sp)
    800048b0:	6442                	ld	s0,16(sp)
    800048b2:	64a2                	ld	s1,8(sp)
    800048b4:	6902                	ld	s2,0(sp)
    800048b6:	6105                	addi	sp,sp,32
    800048b8:	8082                	ret
    pi->readopen = 0;
    800048ba:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    800048be:	21c48513          	addi	a0,s1,540
    800048c2:	ffffe097          	auipc	ra,0xffffe
    800048c6:	928080e7          	jalr	-1752(ra) # 800021ea <wakeup>
    800048ca:	b7e9                	j	80004894 <pipeclose+0x2c>
    release(&pi->lock);
    800048cc:	8526                	mv	a0,s1
    800048ce:	ffffc097          	auipc	ra,0xffffc
    800048d2:	3ca080e7          	jalr	970(ra) # 80000c98 <release>
}
    800048d6:	bfe1                	j	800048ae <pipeclose+0x46>

00000000800048d8 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    800048d8:	7159                	addi	sp,sp,-112
    800048da:	f486                	sd	ra,104(sp)
    800048dc:	f0a2                	sd	s0,96(sp)
    800048de:	eca6                	sd	s1,88(sp)
    800048e0:	e8ca                	sd	s2,80(sp)
    800048e2:	e4ce                	sd	s3,72(sp)
    800048e4:	e0d2                	sd	s4,64(sp)
    800048e6:	fc56                	sd	s5,56(sp)
    800048e8:	f85a                	sd	s6,48(sp)
    800048ea:	f45e                	sd	s7,40(sp)
    800048ec:	f062                	sd	s8,32(sp)
    800048ee:	ec66                	sd	s9,24(sp)
    800048f0:	1880                	addi	s0,sp,112
    800048f2:	84aa                	mv	s1,a0
    800048f4:	8aae                	mv	s5,a1
    800048f6:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    800048f8:	ffffd097          	auipc	ra,0xffffd
    800048fc:	0b8080e7          	jalr	184(ra) # 800019b0 <myproc>
    80004900:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004902:	8526                	mv	a0,s1
    80004904:	ffffc097          	auipc	ra,0xffffc
    80004908:	2e0080e7          	jalr	736(ra) # 80000be4 <acquire>
  while(i < n){
    8000490c:	0d405163          	blez	s4,800049ce <pipewrite+0xf6>
    80004910:	8ba6                	mv	s7,s1
  int i = 0;
    80004912:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004914:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004916:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    8000491a:	21c48c13          	addi	s8,s1,540
    8000491e:	a08d                	j	80004980 <pipewrite+0xa8>
      release(&pi->lock);
    80004920:	8526                	mv	a0,s1
    80004922:	ffffc097          	auipc	ra,0xffffc
    80004926:	376080e7          	jalr	886(ra) # 80000c98 <release>
      return -1;
    8000492a:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    8000492c:	854a                	mv	a0,s2
    8000492e:	70a6                	ld	ra,104(sp)
    80004930:	7406                	ld	s0,96(sp)
    80004932:	64e6                	ld	s1,88(sp)
    80004934:	6946                	ld	s2,80(sp)
    80004936:	69a6                	ld	s3,72(sp)
    80004938:	6a06                	ld	s4,64(sp)
    8000493a:	7ae2                	ld	s5,56(sp)
    8000493c:	7b42                	ld	s6,48(sp)
    8000493e:	7ba2                	ld	s7,40(sp)
    80004940:	7c02                	ld	s8,32(sp)
    80004942:	6ce2                	ld	s9,24(sp)
    80004944:	6165                	addi	sp,sp,112
    80004946:	8082                	ret
      wakeup(&pi->nread);
    80004948:	8566                	mv	a0,s9
    8000494a:	ffffe097          	auipc	ra,0xffffe
    8000494e:	8a0080e7          	jalr	-1888(ra) # 800021ea <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004952:	85de                	mv	a1,s7
    80004954:	8562                	mv	a0,s8
    80004956:	ffffd097          	auipc	ra,0xffffd
    8000495a:	708080e7          	jalr	1800(ra) # 8000205e <sleep>
    8000495e:	a839                	j	8000497c <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004960:	21c4a783          	lw	a5,540(s1)
    80004964:	0017871b          	addiw	a4,a5,1
    80004968:	20e4ae23          	sw	a4,540(s1)
    8000496c:	1ff7f793          	andi	a5,a5,511
    80004970:	97a6                	add	a5,a5,s1
    80004972:	f9f44703          	lbu	a4,-97(s0)
    80004976:	00e78c23          	sb	a4,24(a5)
      i++;
    8000497a:	2905                	addiw	s2,s2,1
  while(i < n){
    8000497c:	03495d63          	bge	s2,s4,800049b6 <pipewrite+0xde>
    if(pi->readopen == 0 || pr->killed){
    80004980:	2204a783          	lw	a5,544(s1)
    80004984:	dfd1                	beqz	a5,80004920 <pipewrite+0x48>
    80004986:	0289a783          	lw	a5,40(s3)
    8000498a:	fbd9                	bnez	a5,80004920 <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    8000498c:	2184a783          	lw	a5,536(s1)
    80004990:	21c4a703          	lw	a4,540(s1)
    80004994:	2007879b          	addiw	a5,a5,512
    80004998:	faf708e3          	beq	a4,a5,80004948 <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    8000499c:	4685                	li	a3,1
    8000499e:	01590633          	add	a2,s2,s5
    800049a2:	f9f40593          	addi	a1,s0,-97
    800049a6:	0509b503          	ld	a0,80(s3)
    800049aa:	ffffd097          	auipc	ra,0xffffd
    800049ae:	d54080e7          	jalr	-684(ra) # 800016fe <copyin>
    800049b2:	fb6517e3          	bne	a0,s6,80004960 <pipewrite+0x88>
  wakeup(&pi->nread);
    800049b6:	21848513          	addi	a0,s1,536
    800049ba:	ffffe097          	auipc	ra,0xffffe
    800049be:	830080e7          	jalr	-2000(ra) # 800021ea <wakeup>
  release(&pi->lock);
    800049c2:	8526                	mv	a0,s1
    800049c4:	ffffc097          	auipc	ra,0xffffc
    800049c8:	2d4080e7          	jalr	724(ra) # 80000c98 <release>
  return i;
    800049cc:	b785                	j	8000492c <pipewrite+0x54>
  int i = 0;
    800049ce:	4901                	li	s2,0
    800049d0:	b7dd                	j	800049b6 <pipewrite+0xde>

00000000800049d2 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    800049d2:	715d                	addi	sp,sp,-80
    800049d4:	e486                	sd	ra,72(sp)
    800049d6:	e0a2                	sd	s0,64(sp)
    800049d8:	fc26                	sd	s1,56(sp)
    800049da:	f84a                	sd	s2,48(sp)
    800049dc:	f44e                	sd	s3,40(sp)
    800049de:	f052                	sd	s4,32(sp)
    800049e0:	ec56                	sd	s5,24(sp)
    800049e2:	e85a                	sd	s6,16(sp)
    800049e4:	0880                	addi	s0,sp,80
    800049e6:	84aa                	mv	s1,a0
    800049e8:	892e                	mv	s2,a1
    800049ea:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    800049ec:	ffffd097          	auipc	ra,0xffffd
    800049f0:	fc4080e7          	jalr	-60(ra) # 800019b0 <myproc>
    800049f4:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    800049f6:	8b26                	mv	s6,s1
    800049f8:	8526                	mv	a0,s1
    800049fa:	ffffc097          	auipc	ra,0xffffc
    800049fe:	1ea080e7          	jalr	490(ra) # 80000be4 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004a02:	2184a703          	lw	a4,536(s1)
    80004a06:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004a0a:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004a0e:	02f71463          	bne	a4,a5,80004a36 <piperead+0x64>
    80004a12:	2244a783          	lw	a5,548(s1)
    80004a16:	c385                	beqz	a5,80004a36 <piperead+0x64>
    if(pr->killed){
    80004a18:	028a2783          	lw	a5,40(s4)
    80004a1c:	ebc1                	bnez	a5,80004aac <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004a1e:	85da                	mv	a1,s6
    80004a20:	854e                	mv	a0,s3
    80004a22:	ffffd097          	auipc	ra,0xffffd
    80004a26:	63c080e7          	jalr	1596(ra) # 8000205e <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004a2a:	2184a703          	lw	a4,536(s1)
    80004a2e:	21c4a783          	lw	a5,540(s1)
    80004a32:	fef700e3          	beq	a4,a5,80004a12 <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004a36:	09505263          	blez	s5,80004aba <piperead+0xe8>
    80004a3a:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004a3c:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80004a3e:	2184a783          	lw	a5,536(s1)
    80004a42:	21c4a703          	lw	a4,540(s1)
    80004a46:	02f70d63          	beq	a4,a5,80004a80 <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004a4a:	0017871b          	addiw	a4,a5,1
    80004a4e:	20e4ac23          	sw	a4,536(s1)
    80004a52:	1ff7f793          	andi	a5,a5,511
    80004a56:	97a6                	add	a5,a5,s1
    80004a58:	0187c783          	lbu	a5,24(a5)
    80004a5c:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004a60:	4685                	li	a3,1
    80004a62:	fbf40613          	addi	a2,s0,-65
    80004a66:	85ca                	mv	a1,s2
    80004a68:	050a3503          	ld	a0,80(s4)
    80004a6c:	ffffd097          	auipc	ra,0xffffd
    80004a70:	c06080e7          	jalr	-1018(ra) # 80001672 <copyout>
    80004a74:	01650663          	beq	a0,s6,80004a80 <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004a78:	2985                	addiw	s3,s3,1
    80004a7a:	0905                	addi	s2,s2,1
    80004a7c:	fd3a91e3          	bne	s5,s3,80004a3e <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004a80:	21c48513          	addi	a0,s1,540
    80004a84:	ffffd097          	auipc	ra,0xffffd
    80004a88:	766080e7          	jalr	1894(ra) # 800021ea <wakeup>
  release(&pi->lock);
    80004a8c:	8526                	mv	a0,s1
    80004a8e:	ffffc097          	auipc	ra,0xffffc
    80004a92:	20a080e7          	jalr	522(ra) # 80000c98 <release>
  return i;
}
    80004a96:	854e                	mv	a0,s3
    80004a98:	60a6                	ld	ra,72(sp)
    80004a9a:	6406                	ld	s0,64(sp)
    80004a9c:	74e2                	ld	s1,56(sp)
    80004a9e:	7942                	ld	s2,48(sp)
    80004aa0:	79a2                	ld	s3,40(sp)
    80004aa2:	7a02                	ld	s4,32(sp)
    80004aa4:	6ae2                	ld	s5,24(sp)
    80004aa6:	6b42                	ld	s6,16(sp)
    80004aa8:	6161                	addi	sp,sp,80
    80004aaa:	8082                	ret
      release(&pi->lock);
    80004aac:	8526                	mv	a0,s1
    80004aae:	ffffc097          	auipc	ra,0xffffc
    80004ab2:	1ea080e7          	jalr	490(ra) # 80000c98 <release>
      return -1;
    80004ab6:	59fd                	li	s3,-1
    80004ab8:	bff9                	j	80004a96 <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004aba:	4981                	li	s3,0
    80004abc:	b7d1                	j	80004a80 <piperead+0xae>

0000000080004abe <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004abe:	df010113          	addi	sp,sp,-528
    80004ac2:	20113423          	sd	ra,520(sp)
    80004ac6:	20813023          	sd	s0,512(sp)
    80004aca:	ffa6                	sd	s1,504(sp)
    80004acc:	fbca                	sd	s2,496(sp)
    80004ace:	f7ce                	sd	s3,488(sp)
    80004ad0:	f3d2                	sd	s4,480(sp)
    80004ad2:	efd6                	sd	s5,472(sp)
    80004ad4:	ebda                	sd	s6,464(sp)
    80004ad6:	e7de                	sd	s7,456(sp)
    80004ad8:	e3e2                	sd	s8,448(sp)
    80004ada:	ff66                	sd	s9,440(sp)
    80004adc:	fb6a                	sd	s10,432(sp)
    80004ade:	f76e                	sd	s11,424(sp)
    80004ae0:	0c00                	addi	s0,sp,528
    80004ae2:	84aa                	mv	s1,a0
    80004ae4:	dea43c23          	sd	a0,-520(s0)
    80004ae8:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004aec:	ffffd097          	auipc	ra,0xffffd
    80004af0:	ec4080e7          	jalr	-316(ra) # 800019b0 <myproc>
    80004af4:	892a                	mv	s2,a0

  begin_op();
    80004af6:	fffff097          	auipc	ra,0xfffff
    80004afa:	49c080e7          	jalr	1180(ra) # 80003f92 <begin_op>

  if((ip = namei(path)) == 0){
    80004afe:	8526                	mv	a0,s1
    80004b00:	fffff097          	auipc	ra,0xfffff
    80004b04:	276080e7          	jalr	630(ra) # 80003d76 <namei>
    80004b08:	c92d                	beqz	a0,80004b7a <exec+0xbc>
    80004b0a:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004b0c:	fffff097          	auipc	ra,0xfffff
    80004b10:	ab4080e7          	jalr	-1356(ra) # 800035c0 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004b14:	04000713          	li	a4,64
    80004b18:	4681                	li	a3,0
    80004b1a:	e5040613          	addi	a2,s0,-432
    80004b1e:	4581                	li	a1,0
    80004b20:	8526                	mv	a0,s1
    80004b22:	fffff097          	auipc	ra,0xfffff
    80004b26:	d52080e7          	jalr	-686(ra) # 80003874 <readi>
    80004b2a:	04000793          	li	a5,64
    80004b2e:	00f51a63          	bne	a0,a5,80004b42 <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80004b32:	e5042703          	lw	a4,-432(s0)
    80004b36:	464c47b7          	lui	a5,0x464c4
    80004b3a:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004b3e:	04f70463          	beq	a4,a5,80004b86 <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004b42:	8526                	mv	a0,s1
    80004b44:	fffff097          	auipc	ra,0xfffff
    80004b48:	cde080e7          	jalr	-802(ra) # 80003822 <iunlockput>
    end_op();
    80004b4c:	fffff097          	auipc	ra,0xfffff
    80004b50:	4c6080e7          	jalr	1222(ra) # 80004012 <end_op>
  }
  return -1;
    80004b54:	557d                	li	a0,-1
}
    80004b56:	20813083          	ld	ra,520(sp)
    80004b5a:	20013403          	ld	s0,512(sp)
    80004b5e:	74fe                	ld	s1,504(sp)
    80004b60:	795e                	ld	s2,496(sp)
    80004b62:	79be                	ld	s3,488(sp)
    80004b64:	7a1e                	ld	s4,480(sp)
    80004b66:	6afe                	ld	s5,472(sp)
    80004b68:	6b5e                	ld	s6,464(sp)
    80004b6a:	6bbe                	ld	s7,456(sp)
    80004b6c:	6c1e                	ld	s8,448(sp)
    80004b6e:	7cfa                	ld	s9,440(sp)
    80004b70:	7d5a                	ld	s10,432(sp)
    80004b72:	7dba                	ld	s11,424(sp)
    80004b74:	21010113          	addi	sp,sp,528
    80004b78:	8082                	ret
    end_op();
    80004b7a:	fffff097          	auipc	ra,0xfffff
    80004b7e:	498080e7          	jalr	1176(ra) # 80004012 <end_op>
    return -1;
    80004b82:	557d                	li	a0,-1
    80004b84:	bfc9                	j	80004b56 <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80004b86:	854a                	mv	a0,s2
    80004b88:	ffffd097          	auipc	ra,0xffffd
    80004b8c:	ede080e7          	jalr	-290(ra) # 80001a66 <proc_pagetable>
    80004b90:	8baa                	mv	s7,a0
    80004b92:	d945                	beqz	a0,80004b42 <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004b94:	e7042983          	lw	s3,-400(s0)
    80004b98:	e8845783          	lhu	a5,-376(s0)
    80004b9c:	c7ad                	beqz	a5,80004c06 <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004b9e:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004ba0:	4b01                	li	s6,0
    if((ph.vaddr % PGSIZE) != 0)
    80004ba2:	6c85                	lui	s9,0x1
    80004ba4:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80004ba8:	def43823          	sd	a5,-528(s0)
    80004bac:	a42d                	j	80004dd6 <exec+0x318>
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004bae:	00004517          	auipc	a0,0x4
    80004bb2:	b1a50513          	addi	a0,a0,-1254 # 800086c8 <syscalls+0x280>
    80004bb6:	ffffc097          	auipc	ra,0xffffc
    80004bba:	988080e7          	jalr	-1656(ra) # 8000053e <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004bbe:	8756                	mv	a4,s5
    80004bc0:	012d86bb          	addw	a3,s11,s2
    80004bc4:	4581                	li	a1,0
    80004bc6:	8526                	mv	a0,s1
    80004bc8:	fffff097          	auipc	ra,0xfffff
    80004bcc:	cac080e7          	jalr	-852(ra) # 80003874 <readi>
    80004bd0:	2501                	sext.w	a0,a0
    80004bd2:	1aaa9963          	bne	s5,a0,80004d84 <exec+0x2c6>
  for(i = 0; i < sz; i += PGSIZE){
    80004bd6:	6785                	lui	a5,0x1
    80004bd8:	0127893b          	addw	s2,a5,s2
    80004bdc:	77fd                	lui	a5,0xfffff
    80004bde:	01478a3b          	addw	s4,a5,s4
    80004be2:	1f897163          	bgeu	s2,s8,80004dc4 <exec+0x306>
    pa = walkaddr(pagetable, va + i);
    80004be6:	02091593          	slli	a1,s2,0x20
    80004bea:	9181                	srli	a1,a1,0x20
    80004bec:	95ea                	add	a1,a1,s10
    80004bee:	855e                	mv	a0,s7
    80004bf0:	ffffc097          	auipc	ra,0xffffc
    80004bf4:	47e080e7          	jalr	1150(ra) # 8000106e <walkaddr>
    80004bf8:	862a                	mv	a2,a0
    if(pa == 0)
    80004bfa:	d955                	beqz	a0,80004bae <exec+0xf0>
      n = PGSIZE;
    80004bfc:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    80004bfe:	fd9a70e3          	bgeu	s4,s9,80004bbe <exec+0x100>
      n = sz - i;
    80004c02:	8ad2                	mv	s5,s4
    80004c04:	bf6d                	j	80004bbe <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004c06:	4901                	li	s2,0
  iunlockput(ip);
    80004c08:	8526                	mv	a0,s1
    80004c0a:	fffff097          	auipc	ra,0xfffff
    80004c0e:	c18080e7          	jalr	-1000(ra) # 80003822 <iunlockput>
  end_op();
    80004c12:	fffff097          	auipc	ra,0xfffff
    80004c16:	400080e7          	jalr	1024(ra) # 80004012 <end_op>
  p = myproc();
    80004c1a:	ffffd097          	auipc	ra,0xffffd
    80004c1e:	d96080e7          	jalr	-618(ra) # 800019b0 <myproc>
    80004c22:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80004c24:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004c28:	6785                	lui	a5,0x1
    80004c2a:	17fd                	addi	a5,a5,-1
    80004c2c:	993e                	add	s2,s2,a5
    80004c2e:	757d                	lui	a0,0xfffff
    80004c30:	00a977b3          	and	a5,s2,a0
    80004c34:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004c38:	6609                	lui	a2,0x2
    80004c3a:	963e                	add	a2,a2,a5
    80004c3c:	85be                	mv	a1,a5
    80004c3e:	855e                	mv	a0,s7
    80004c40:	ffffc097          	auipc	ra,0xffffc
    80004c44:	7e2080e7          	jalr	2018(ra) # 80001422 <uvmalloc>
    80004c48:	8b2a                	mv	s6,a0
  ip = 0;
    80004c4a:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004c4c:	12050c63          	beqz	a0,80004d84 <exec+0x2c6>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004c50:	75f9                	lui	a1,0xffffe
    80004c52:	95aa                	add	a1,a1,a0
    80004c54:	855e                	mv	a0,s7
    80004c56:	ffffd097          	auipc	ra,0xffffd
    80004c5a:	9ea080e7          	jalr	-1558(ra) # 80001640 <uvmclear>
  stackbase = sp - PGSIZE;
    80004c5e:	7c7d                	lui	s8,0xfffff
    80004c60:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    80004c62:	e0043783          	ld	a5,-512(s0)
    80004c66:	6388                	ld	a0,0(a5)
    80004c68:	c535                	beqz	a0,80004cd4 <exec+0x216>
    80004c6a:	e9040993          	addi	s3,s0,-368
    80004c6e:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80004c72:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    80004c74:	ffffc097          	auipc	ra,0xffffc
    80004c78:	1f0080e7          	jalr	496(ra) # 80000e64 <strlen>
    80004c7c:	2505                	addiw	a0,a0,1
    80004c7e:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004c82:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80004c86:	13896363          	bltu	s2,s8,80004dac <exec+0x2ee>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004c8a:	e0043d83          	ld	s11,-512(s0)
    80004c8e:	000dba03          	ld	s4,0(s11)
    80004c92:	8552                	mv	a0,s4
    80004c94:	ffffc097          	auipc	ra,0xffffc
    80004c98:	1d0080e7          	jalr	464(ra) # 80000e64 <strlen>
    80004c9c:	0015069b          	addiw	a3,a0,1
    80004ca0:	8652                	mv	a2,s4
    80004ca2:	85ca                	mv	a1,s2
    80004ca4:	855e                	mv	a0,s7
    80004ca6:	ffffd097          	auipc	ra,0xffffd
    80004caa:	9cc080e7          	jalr	-1588(ra) # 80001672 <copyout>
    80004cae:	10054363          	bltz	a0,80004db4 <exec+0x2f6>
    ustack[argc] = sp;
    80004cb2:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004cb6:	0485                	addi	s1,s1,1
    80004cb8:	008d8793          	addi	a5,s11,8
    80004cbc:	e0f43023          	sd	a5,-512(s0)
    80004cc0:	008db503          	ld	a0,8(s11)
    80004cc4:	c911                	beqz	a0,80004cd8 <exec+0x21a>
    if(argc >= MAXARG)
    80004cc6:	09a1                	addi	s3,s3,8
    80004cc8:	fb3c96e3          	bne	s9,s3,80004c74 <exec+0x1b6>
  sz = sz1;
    80004ccc:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004cd0:	4481                	li	s1,0
    80004cd2:	a84d                	j	80004d84 <exec+0x2c6>
  sp = sz;
    80004cd4:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    80004cd6:	4481                	li	s1,0
  ustack[argc] = 0;
    80004cd8:	00349793          	slli	a5,s1,0x3
    80004cdc:	f9040713          	addi	a4,s0,-112
    80004ce0:	97ba                	add	a5,a5,a4
    80004ce2:	f007b023          	sd	zero,-256(a5) # f00 <_entry-0x7ffff100>
  sp -= (argc+1) * sizeof(uint64);
    80004ce6:	00148693          	addi	a3,s1,1
    80004cea:	068e                	slli	a3,a3,0x3
    80004cec:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004cf0:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80004cf4:	01897663          	bgeu	s2,s8,80004d00 <exec+0x242>
  sz = sz1;
    80004cf8:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004cfc:	4481                	li	s1,0
    80004cfe:	a059                	j	80004d84 <exec+0x2c6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80004d00:	e9040613          	addi	a2,s0,-368
    80004d04:	85ca                	mv	a1,s2
    80004d06:	855e                	mv	a0,s7
    80004d08:	ffffd097          	auipc	ra,0xffffd
    80004d0c:	96a080e7          	jalr	-1686(ra) # 80001672 <copyout>
    80004d10:	0a054663          	bltz	a0,80004dbc <exec+0x2fe>
  p->trapframe->a1 = sp;
    80004d14:	058ab783          	ld	a5,88(s5)
    80004d18:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80004d1c:	df843783          	ld	a5,-520(s0)
    80004d20:	0007c703          	lbu	a4,0(a5)
    80004d24:	cf11                	beqz	a4,80004d40 <exec+0x282>
    80004d26:	0785                	addi	a5,a5,1
    if(*s == '/')
    80004d28:	02f00693          	li	a3,47
    80004d2c:	a039                	j	80004d3a <exec+0x27c>
      last = s+1;
    80004d2e:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    80004d32:	0785                	addi	a5,a5,1
    80004d34:	fff7c703          	lbu	a4,-1(a5)
    80004d38:	c701                	beqz	a4,80004d40 <exec+0x282>
    if(*s == '/')
    80004d3a:	fed71ce3          	bne	a4,a3,80004d32 <exec+0x274>
    80004d3e:	bfc5                	j	80004d2e <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    80004d40:	4641                	li	a2,16
    80004d42:	df843583          	ld	a1,-520(s0)
    80004d46:	158a8513          	addi	a0,s5,344
    80004d4a:	ffffc097          	auipc	ra,0xffffc
    80004d4e:	0e8080e7          	jalr	232(ra) # 80000e32 <safestrcpy>
  oldpagetable = p->pagetable;
    80004d52:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    80004d56:	057ab823          	sd	s7,80(s5)
  p->sz = sz;
    80004d5a:	056ab423          	sd	s6,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80004d5e:	058ab783          	ld	a5,88(s5)
    80004d62:	e6843703          	ld	a4,-408(s0)
    80004d66:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80004d68:	058ab783          	ld	a5,88(s5)
    80004d6c:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80004d70:	85ea                	mv	a1,s10
    80004d72:	ffffd097          	auipc	ra,0xffffd
    80004d76:	d90080e7          	jalr	-624(ra) # 80001b02 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80004d7a:	0004851b          	sext.w	a0,s1
    80004d7e:	bbe1                	j	80004b56 <exec+0x98>
    80004d80:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    80004d84:	e0843583          	ld	a1,-504(s0)
    80004d88:	855e                	mv	a0,s7
    80004d8a:	ffffd097          	auipc	ra,0xffffd
    80004d8e:	d78080e7          	jalr	-648(ra) # 80001b02 <proc_freepagetable>
  if(ip){
    80004d92:	da0498e3          	bnez	s1,80004b42 <exec+0x84>
  return -1;
    80004d96:	557d                	li	a0,-1
    80004d98:	bb7d                	j	80004b56 <exec+0x98>
    80004d9a:	e1243423          	sd	s2,-504(s0)
    80004d9e:	b7dd                	j	80004d84 <exec+0x2c6>
    80004da0:	e1243423          	sd	s2,-504(s0)
    80004da4:	b7c5                	j	80004d84 <exec+0x2c6>
    80004da6:	e1243423          	sd	s2,-504(s0)
    80004daa:	bfe9                	j	80004d84 <exec+0x2c6>
  sz = sz1;
    80004dac:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004db0:	4481                	li	s1,0
    80004db2:	bfc9                	j	80004d84 <exec+0x2c6>
  sz = sz1;
    80004db4:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004db8:	4481                	li	s1,0
    80004dba:	b7e9                	j	80004d84 <exec+0x2c6>
  sz = sz1;
    80004dbc:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004dc0:	4481                	li	s1,0
    80004dc2:	b7c9                	j	80004d84 <exec+0x2c6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80004dc4:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004dc8:	2b05                	addiw	s6,s6,1
    80004dca:	0389899b          	addiw	s3,s3,56
    80004dce:	e8845783          	lhu	a5,-376(s0)
    80004dd2:	e2fb5be3          	bge	s6,a5,80004c08 <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80004dd6:	2981                	sext.w	s3,s3
    80004dd8:	03800713          	li	a4,56
    80004ddc:	86ce                	mv	a3,s3
    80004dde:	e1840613          	addi	a2,s0,-488
    80004de2:	4581                	li	a1,0
    80004de4:	8526                	mv	a0,s1
    80004de6:	fffff097          	auipc	ra,0xfffff
    80004dea:	a8e080e7          	jalr	-1394(ra) # 80003874 <readi>
    80004dee:	03800793          	li	a5,56
    80004df2:	f8f517e3          	bne	a0,a5,80004d80 <exec+0x2c2>
    if(ph.type != ELF_PROG_LOAD)
    80004df6:	e1842783          	lw	a5,-488(s0)
    80004dfa:	4705                	li	a4,1
    80004dfc:	fce796e3          	bne	a5,a4,80004dc8 <exec+0x30a>
    if(ph.memsz < ph.filesz)
    80004e00:	e4043603          	ld	a2,-448(s0)
    80004e04:	e3843783          	ld	a5,-456(s0)
    80004e08:	f8f669e3          	bltu	a2,a5,80004d9a <exec+0x2dc>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80004e0c:	e2843783          	ld	a5,-472(s0)
    80004e10:	963e                	add	a2,a2,a5
    80004e12:	f8f667e3          	bltu	a2,a5,80004da0 <exec+0x2e2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80004e16:	85ca                	mv	a1,s2
    80004e18:	855e                	mv	a0,s7
    80004e1a:	ffffc097          	auipc	ra,0xffffc
    80004e1e:	608080e7          	jalr	1544(ra) # 80001422 <uvmalloc>
    80004e22:	e0a43423          	sd	a0,-504(s0)
    80004e26:	d141                	beqz	a0,80004da6 <exec+0x2e8>
    if((ph.vaddr % PGSIZE) != 0)
    80004e28:	e2843d03          	ld	s10,-472(s0)
    80004e2c:	df043783          	ld	a5,-528(s0)
    80004e30:	00fd77b3          	and	a5,s10,a5
    80004e34:	fba1                	bnez	a5,80004d84 <exec+0x2c6>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80004e36:	e2042d83          	lw	s11,-480(s0)
    80004e3a:	e3842c03          	lw	s8,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80004e3e:	f80c03e3          	beqz	s8,80004dc4 <exec+0x306>
    80004e42:	8a62                	mv	s4,s8
    80004e44:	4901                	li	s2,0
    80004e46:	b345                	j	80004be6 <exec+0x128>

0000000080004e48 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80004e48:	7179                	addi	sp,sp,-48
    80004e4a:	f406                	sd	ra,40(sp)
    80004e4c:	f022                	sd	s0,32(sp)
    80004e4e:	ec26                	sd	s1,24(sp)
    80004e50:	e84a                	sd	s2,16(sp)
    80004e52:	1800                	addi	s0,sp,48
    80004e54:	892e                	mv	s2,a1
    80004e56:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    80004e58:	fdc40593          	addi	a1,s0,-36
    80004e5c:	ffffe097          	auipc	ra,0xffffe
    80004e60:	bf2080e7          	jalr	-1038(ra) # 80002a4e <argint>
    80004e64:	04054063          	bltz	a0,80004ea4 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80004e68:	fdc42703          	lw	a4,-36(s0)
    80004e6c:	47bd                	li	a5,15
    80004e6e:	02e7ed63          	bltu	a5,a4,80004ea8 <argfd+0x60>
    80004e72:	ffffd097          	auipc	ra,0xffffd
    80004e76:	b3e080e7          	jalr	-1218(ra) # 800019b0 <myproc>
    80004e7a:	fdc42703          	lw	a4,-36(s0)
    80004e7e:	01a70793          	addi	a5,a4,26
    80004e82:	078e                	slli	a5,a5,0x3
    80004e84:	953e                	add	a0,a0,a5
    80004e86:	611c                	ld	a5,0(a0)
    80004e88:	c395                	beqz	a5,80004eac <argfd+0x64>
    return -1;
  if(pfd)
    80004e8a:	00090463          	beqz	s2,80004e92 <argfd+0x4a>
    *pfd = fd;
    80004e8e:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80004e92:	4501                	li	a0,0
  if(pf)
    80004e94:	c091                	beqz	s1,80004e98 <argfd+0x50>
    *pf = f;
    80004e96:	e09c                	sd	a5,0(s1)
}
    80004e98:	70a2                	ld	ra,40(sp)
    80004e9a:	7402                	ld	s0,32(sp)
    80004e9c:	64e2                	ld	s1,24(sp)
    80004e9e:	6942                	ld	s2,16(sp)
    80004ea0:	6145                	addi	sp,sp,48
    80004ea2:	8082                	ret
    return -1;
    80004ea4:	557d                	li	a0,-1
    80004ea6:	bfcd                	j	80004e98 <argfd+0x50>
    return -1;
    80004ea8:	557d                	li	a0,-1
    80004eaa:	b7fd                	j	80004e98 <argfd+0x50>
    80004eac:	557d                	li	a0,-1
    80004eae:	b7ed                	j	80004e98 <argfd+0x50>

0000000080004eb0 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80004eb0:	1101                	addi	sp,sp,-32
    80004eb2:	ec06                	sd	ra,24(sp)
    80004eb4:	e822                	sd	s0,16(sp)
    80004eb6:	e426                	sd	s1,8(sp)
    80004eb8:	1000                	addi	s0,sp,32
    80004eba:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80004ebc:	ffffd097          	auipc	ra,0xffffd
    80004ec0:	af4080e7          	jalr	-1292(ra) # 800019b0 <myproc>
    80004ec4:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80004ec6:	0d050793          	addi	a5,a0,208 # fffffffffffff0d0 <end+0xffffffff7ffd90d0>
    80004eca:	4501                	li	a0,0
    80004ecc:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80004ece:	6398                	ld	a4,0(a5)
    80004ed0:	cb19                	beqz	a4,80004ee6 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80004ed2:	2505                	addiw	a0,a0,1
    80004ed4:	07a1                	addi	a5,a5,8
    80004ed6:	fed51ce3          	bne	a0,a3,80004ece <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80004eda:	557d                	li	a0,-1
}
    80004edc:	60e2                	ld	ra,24(sp)
    80004ede:	6442                	ld	s0,16(sp)
    80004ee0:	64a2                	ld	s1,8(sp)
    80004ee2:	6105                	addi	sp,sp,32
    80004ee4:	8082                	ret
      p->ofile[fd] = f;
    80004ee6:	01a50793          	addi	a5,a0,26
    80004eea:	078e                	slli	a5,a5,0x3
    80004eec:	963e                	add	a2,a2,a5
    80004eee:	e204                	sd	s1,0(a2)
      return fd;
    80004ef0:	b7f5                	j	80004edc <fdalloc+0x2c>

0000000080004ef2 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80004ef2:	715d                	addi	sp,sp,-80
    80004ef4:	e486                	sd	ra,72(sp)
    80004ef6:	e0a2                	sd	s0,64(sp)
    80004ef8:	fc26                	sd	s1,56(sp)
    80004efa:	f84a                	sd	s2,48(sp)
    80004efc:	f44e                	sd	s3,40(sp)
    80004efe:	f052                	sd	s4,32(sp)
    80004f00:	ec56                	sd	s5,24(sp)
    80004f02:	0880                	addi	s0,sp,80
    80004f04:	89ae                	mv	s3,a1
    80004f06:	8ab2                	mv	s5,a2
    80004f08:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80004f0a:	fb040593          	addi	a1,s0,-80
    80004f0e:	fffff097          	auipc	ra,0xfffff
    80004f12:	e86080e7          	jalr	-378(ra) # 80003d94 <nameiparent>
    80004f16:	892a                	mv	s2,a0
    80004f18:	12050f63          	beqz	a0,80005056 <create+0x164>
    return 0;

  ilock(dp);
    80004f1c:	ffffe097          	auipc	ra,0xffffe
    80004f20:	6a4080e7          	jalr	1700(ra) # 800035c0 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80004f24:	4601                	li	a2,0
    80004f26:	fb040593          	addi	a1,s0,-80
    80004f2a:	854a                	mv	a0,s2
    80004f2c:	fffff097          	auipc	ra,0xfffff
    80004f30:	b78080e7          	jalr	-1160(ra) # 80003aa4 <dirlookup>
    80004f34:	84aa                	mv	s1,a0
    80004f36:	c921                	beqz	a0,80004f86 <create+0x94>
    iunlockput(dp);
    80004f38:	854a                	mv	a0,s2
    80004f3a:	fffff097          	auipc	ra,0xfffff
    80004f3e:	8e8080e7          	jalr	-1816(ra) # 80003822 <iunlockput>
    ilock(ip);
    80004f42:	8526                	mv	a0,s1
    80004f44:	ffffe097          	auipc	ra,0xffffe
    80004f48:	67c080e7          	jalr	1660(ra) # 800035c0 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80004f4c:	2981                	sext.w	s3,s3
    80004f4e:	4789                	li	a5,2
    80004f50:	02f99463          	bne	s3,a5,80004f78 <create+0x86>
    80004f54:	0444d783          	lhu	a5,68(s1)
    80004f58:	37f9                	addiw	a5,a5,-2
    80004f5a:	17c2                	slli	a5,a5,0x30
    80004f5c:	93c1                	srli	a5,a5,0x30
    80004f5e:	4705                	li	a4,1
    80004f60:	00f76c63          	bltu	a4,a5,80004f78 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    80004f64:	8526                	mv	a0,s1
    80004f66:	60a6                	ld	ra,72(sp)
    80004f68:	6406                	ld	s0,64(sp)
    80004f6a:	74e2                	ld	s1,56(sp)
    80004f6c:	7942                	ld	s2,48(sp)
    80004f6e:	79a2                	ld	s3,40(sp)
    80004f70:	7a02                	ld	s4,32(sp)
    80004f72:	6ae2                	ld	s5,24(sp)
    80004f74:	6161                	addi	sp,sp,80
    80004f76:	8082                	ret
    iunlockput(ip);
    80004f78:	8526                	mv	a0,s1
    80004f7a:	fffff097          	auipc	ra,0xfffff
    80004f7e:	8a8080e7          	jalr	-1880(ra) # 80003822 <iunlockput>
    return 0;
    80004f82:	4481                	li	s1,0
    80004f84:	b7c5                	j	80004f64 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    80004f86:	85ce                	mv	a1,s3
    80004f88:	00092503          	lw	a0,0(s2)
    80004f8c:	ffffe097          	auipc	ra,0xffffe
    80004f90:	49c080e7          	jalr	1180(ra) # 80003428 <ialloc>
    80004f94:	84aa                	mv	s1,a0
    80004f96:	c529                	beqz	a0,80004fe0 <create+0xee>
  ilock(ip);
    80004f98:	ffffe097          	auipc	ra,0xffffe
    80004f9c:	628080e7          	jalr	1576(ra) # 800035c0 <ilock>
  ip->major = major;
    80004fa0:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    80004fa4:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    80004fa8:	4785                	li	a5,1
    80004faa:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80004fae:	8526                	mv	a0,s1
    80004fb0:	ffffe097          	auipc	ra,0xffffe
    80004fb4:	546080e7          	jalr	1350(ra) # 800034f6 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80004fb8:	2981                	sext.w	s3,s3
    80004fba:	4785                	li	a5,1
    80004fbc:	02f98a63          	beq	s3,a5,80004ff0 <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    80004fc0:	40d0                	lw	a2,4(s1)
    80004fc2:	fb040593          	addi	a1,s0,-80
    80004fc6:	854a                	mv	a0,s2
    80004fc8:	fffff097          	auipc	ra,0xfffff
    80004fcc:	cec080e7          	jalr	-788(ra) # 80003cb4 <dirlink>
    80004fd0:	06054b63          	bltz	a0,80005046 <create+0x154>
  iunlockput(dp);
    80004fd4:	854a                	mv	a0,s2
    80004fd6:	fffff097          	auipc	ra,0xfffff
    80004fda:	84c080e7          	jalr	-1972(ra) # 80003822 <iunlockput>
  return ip;
    80004fde:	b759                	j	80004f64 <create+0x72>
    panic("create: ialloc");
    80004fe0:	00003517          	auipc	a0,0x3
    80004fe4:	70850513          	addi	a0,a0,1800 # 800086e8 <syscalls+0x2a0>
    80004fe8:	ffffb097          	auipc	ra,0xffffb
    80004fec:	556080e7          	jalr	1366(ra) # 8000053e <panic>
    dp->nlink++;  // for ".."
    80004ff0:	04a95783          	lhu	a5,74(s2)
    80004ff4:	2785                	addiw	a5,a5,1
    80004ff6:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    80004ffa:	854a                	mv	a0,s2
    80004ffc:	ffffe097          	auipc	ra,0xffffe
    80005000:	4fa080e7          	jalr	1274(ra) # 800034f6 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005004:	40d0                	lw	a2,4(s1)
    80005006:	00003597          	auipc	a1,0x3
    8000500a:	6f258593          	addi	a1,a1,1778 # 800086f8 <syscalls+0x2b0>
    8000500e:	8526                	mv	a0,s1
    80005010:	fffff097          	auipc	ra,0xfffff
    80005014:	ca4080e7          	jalr	-860(ra) # 80003cb4 <dirlink>
    80005018:	00054f63          	bltz	a0,80005036 <create+0x144>
    8000501c:	00492603          	lw	a2,4(s2)
    80005020:	00003597          	auipc	a1,0x3
    80005024:	6e058593          	addi	a1,a1,1760 # 80008700 <syscalls+0x2b8>
    80005028:	8526                	mv	a0,s1
    8000502a:	fffff097          	auipc	ra,0xfffff
    8000502e:	c8a080e7          	jalr	-886(ra) # 80003cb4 <dirlink>
    80005032:	f80557e3          	bgez	a0,80004fc0 <create+0xce>
      panic("create dots");
    80005036:	00003517          	auipc	a0,0x3
    8000503a:	6d250513          	addi	a0,a0,1746 # 80008708 <syscalls+0x2c0>
    8000503e:	ffffb097          	auipc	ra,0xffffb
    80005042:	500080e7          	jalr	1280(ra) # 8000053e <panic>
    panic("create: dirlink");
    80005046:	00003517          	auipc	a0,0x3
    8000504a:	6d250513          	addi	a0,a0,1746 # 80008718 <syscalls+0x2d0>
    8000504e:	ffffb097          	auipc	ra,0xffffb
    80005052:	4f0080e7          	jalr	1264(ra) # 8000053e <panic>
    return 0;
    80005056:	84aa                	mv	s1,a0
    80005058:	b731                	j	80004f64 <create+0x72>

000000008000505a <sys_dup>:
{
    8000505a:	7179                	addi	sp,sp,-48
    8000505c:	f406                	sd	ra,40(sp)
    8000505e:	f022                	sd	s0,32(sp)
    80005060:	ec26                	sd	s1,24(sp)
    80005062:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005064:	fd840613          	addi	a2,s0,-40
    80005068:	4581                	li	a1,0
    8000506a:	4501                	li	a0,0
    8000506c:	00000097          	auipc	ra,0x0
    80005070:	ddc080e7          	jalr	-548(ra) # 80004e48 <argfd>
    return -1;
    80005074:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005076:	02054363          	bltz	a0,8000509c <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    8000507a:	fd843503          	ld	a0,-40(s0)
    8000507e:	00000097          	auipc	ra,0x0
    80005082:	e32080e7          	jalr	-462(ra) # 80004eb0 <fdalloc>
    80005086:	84aa                	mv	s1,a0
    return -1;
    80005088:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    8000508a:	00054963          	bltz	a0,8000509c <sys_dup+0x42>
  filedup(f);
    8000508e:	fd843503          	ld	a0,-40(s0)
    80005092:	fffff097          	auipc	ra,0xfffff
    80005096:	37a080e7          	jalr	890(ra) # 8000440c <filedup>
  return fd;
    8000509a:	87a6                	mv	a5,s1
}
    8000509c:	853e                	mv	a0,a5
    8000509e:	70a2                	ld	ra,40(sp)
    800050a0:	7402                	ld	s0,32(sp)
    800050a2:	64e2                	ld	s1,24(sp)
    800050a4:	6145                	addi	sp,sp,48
    800050a6:	8082                	ret

00000000800050a8 <sys_read>:
{
    800050a8:	7179                	addi	sp,sp,-48
    800050aa:	f406                	sd	ra,40(sp)
    800050ac:	f022                	sd	s0,32(sp)
    800050ae:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800050b0:	fe840613          	addi	a2,s0,-24
    800050b4:	4581                	li	a1,0
    800050b6:	4501                	li	a0,0
    800050b8:	00000097          	auipc	ra,0x0
    800050bc:	d90080e7          	jalr	-624(ra) # 80004e48 <argfd>
    return -1;
    800050c0:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800050c2:	04054163          	bltz	a0,80005104 <sys_read+0x5c>
    800050c6:	fe440593          	addi	a1,s0,-28
    800050ca:	4509                	li	a0,2
    800050cc:	ffffe097          	auipc	ra,0xffffe
    800050d0:	982080e7          	jalr	-1662(ra) # 80002a4e <argint>
    return -1;
    800050d4:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800050d6:	02054763          	bltz	a0,80005104 <sys_read+0x5c>
    800050da:	fd840593          	addi	a1,s0,-40
    800050de:	4505                	li	a0,1
    800050e0:	ffffe097          	auipc	ra,0xffffe
    800050e4:	990080e7          	jalr	-1648(ra) # 80002a70 <argaddr>
    return -1;
    800050e8:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800050ea:	00054d63          	bltz	a0,80005104 <sys_read+0x5c>
  return fileread(f, p, n);
    800050ee:	fe442603          	lw	a2,-28(s0)
    800050f2:	fd843583          	ld	a1,-40(s0)
    800050f6:	fe843503          	ld	a0,-24(s0)
    800050fa:	fffff097          	auipc	ra,0xfffff
    800050fe:	49e080e7          	jalr	1182(ra) # 80004598 <fileread>
    80005102:	87aa                	mv	a5,a0
}
    80005104:	853e                	mv	a0,a5
    80005106:	70a2                	ld	ra,40(sp)
    80005108:	7402                	ld	s0,32(sp)
    8000510a:	6145                	addi	sp,sp,48
    8000510c:	8082                	ret

000000008000510e <sys_write>:
{
    8000510e:	7179                	addi	sp,sp,-48
    80005110:	f406                	sd	ra,40(sp)
    80005112:	f022                	sd	s0,32(sp)
    80005114:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005116:	fe840613          	addi	a2,s0,-24
    8000511a:	4581                	li	a1,0
    8000511c:	4501                	li	a0,0
    8000511e:	00000097          	auipc	ra,0x0
    80005122:	d2a080e7          	jalr	-726(ra) # 80004e48 <argfd>
    return -1;
    80005126:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005128:	04054163          	bltz	a0,8000516a <sys_write+0x5c>
    8000512c:	fe440593          	addi	a1,s0,-28
    80005130:	4509                	li	a0,2
    80005132:	ffffe097          	auipc	ra,0xffffe
    80005136:	91c080e7          	jalr	-1764(ra) # 80002a4e <argint>
    return -1;
    8000513a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000513c:	02054763          	bltz	a0,8000516a <sys_write+0x5c>
    80005140:	fd840593          	addi	a1,s0,-40
    80005144:	4505                	li	a0,1
    80005146:	ffffe097          	auipc	ra,0xffffe
    8000514a:	92a080e7          	jalr	-1750(ra) # 80002a70 <argaddr>
    return -1;
    8000514e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005150:	00054d63          	bltz	a0,8000516a <sys_write+0x5c>
  return filewrite(f, p, n);
    80005154:	fe442603          	lw	a2,-28(s0)
    80005158:	fd843583          	ld	a1,-40(s0)
    8000515c:	fe843503          	ld	a0,-24(s0)
    80005160:	fffff097          	auipc	ra,0xfffff
    80005164:	4fa080e7          	jalr	1274(ra) # 8000465a <filewrite>
    80005168:	87aa                	mv	a5,a0
}
    8000516a:	853e                	mv	a0,a5
    8000516c:	70a2                	ld	ra,40(sp)
    8000516e:	7402                	ld	s0,32(sp)
    80005170:	6145                	addi	sp,sp,48
    80005172:	8082                	ret

0000000080005174 <sys_close>:
{
    80005174:	1101                	addi	sp,sp,-32
    80005176:	ec06                	sd	ra,24(sp)
    80005178:	e822                	sd	s0,16(sp)
    8000517a:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    8000517c:	fe040613          	addi	a2,s0,-32
    80005180:	fec40593          	addi	a1,s0,-20
    80005184:	4501                	li	a0,0
    80005186:	00000097          	auipc	ra,0x0
    8000518a:	cc2080e7          	jalr	-830(ra) # 80004e48 <argfd>
    return -1;
    8000518e:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005190:	02054463          	bltz	a0,800051b8 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005194:	ffffd097          	auipc	ra,0xffffd
    80005198:	81c080e7          	jalr	-2020(ra) # 800019b0 <myproc>
    8000519c:	fec42783          	lw	a5,-20(s0)
    800051a0:	07e9                	addi	a5,a5,26
    800051a2:	078e                	slli	a5,a5,0x3
    800051a4:	97aa                	add	a5,a5,a0
    800051a6:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    800051aa:	fe043503          	ld	a0,-32(s0)
    800051ae:	fffff097          	auipc	ra,0xfffff
    800051b2:	2b0080e7          	jalr	688(ra) # 8000445e <fileclose>
  return 0;
    800051b6:	4781                	li	a5,0
}
    800051b8:	853e                	mv	a0,a5
    800051ba:	60e2                	ld	ra,24(sp)
    800051bc:	6442                	ld	s0,16(sp)
    800051be:	6105                	addi	sp,sp,32
    800051c0:	8082                	ret

00000000800051c2 <sys_fstat>:
{
    800051c2:	1101                	addi	sp,sp,-32
    800051c4:	ec06                	sd	ra,24(sp)
    800051c6:	e822                	sd	s0,16(sp)
    800051c8:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800051ca:	fe840613          	addi	a2,s0,-24
    800051ce:	4581                	li	a1,0
    800051d0:	4501                	li	a0,0
    800051d2:	00000097          	auipc	ra,0x0
    800051d6:	c76080e7          	jalr	-906(ra) # 80004e48 <argfd>
    return -1;
    800051da:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800051dc:	02054563          	bltz	a0,80005206 <sys_fstat+0x44>
    800051e0:	fe040593          	addi	a1,s0,-32
    800051e4:	4505                	li	a0,1
    800051e6:	ffffe097          	auipc	ra,0xffffe
    800051ea:	88a080e7          	jalr	-1910(ra) # 80002a70 <argaddr>
    return -1;
    800051ee:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800051f0:	00054b63          	bltz	a0,80005206 <sys_fstat+0x44>
  return filestat(f, st);
    800051f4:	fe043583          	ld	a1,-32(s0)
    800051f8:	fe843503          	ld	a0,-24(s0)
    800051fc:	fffff097          	auipc	ra,0xfffff
    80005200:	32a080e7          	jalr	810(ra) # 80004526 <filestat>
    80005204:	87aa                	mv	a5,a0
}
    80005206:	853e                	mv	a0,a5
    80005208:	60e2                	ld	ra,24(sp)
    8000520a:	6442                	ld	s0,16(sp)
    8000520c:	6105                	addi	sp,sp,32
    8000520e:	8082                	ret

0000000080005210 <sys_link>:
{
    80005210:	7169                	addi	sp,sp,-304
    80005212:	f606                	sd	ra,296(sp)
    80005214:	f222                	sd	s0,288(sp)
    80005216:	ee26                	sd	s1,280(sp)
    80005218:	ea4a                	sd	s2,272(sp)
    8000521a:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000521c:	08000613          	li	a2,128
    80005220:	ed040593          	addi	a1,s0,-304
    80005224:	4501                	li	a0,0
    80005226:	ffffe097          	auipc	ra,0xffffe
    8000522a:	86c080e7          	jalr	-1940(ra) # 80002a92 <argstr>
    return -1;
    8000522e:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005230:	10054e63          	bltz	a0,8000534c <sys_link+0x13c>
    80005234:	08000613          	li	a2,128
    80005238:	f5040593          	addi	a1,s0,-176
    8000523c:	4505                	li	a0,1
    8000523e:	ffffe097          	auipc	ra,0xffffe
    80005242:	854080e7          	jalr	-1964(ra) # 80002a92 <argstr>
    return -1;
    80005246:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005248:	10054263          	bltz	a0,8000534c <sys_link+0x13c>
  begin_op();
    8000524c:	fffff097          	auipc	ra,0xfffff
    80005250:	d46080e7          	jalr	-698(ra) # 80003f92 <begin_op>
  if((ip = namei(old)) == 0){
    80005254:	ed040513          	addi	a0,s0,-304
    80005258:	fffff097          	auipc	ra,0xfffff
    8000525c:	b1e080e7          	jalr	-1250(ra) # 80003d76 <namei>
    80005260:	84aa                	mv	s1,a0
    80005262:	c551                	beqz	a0,800052ee <sys_link+0xde>
  ilock(ip);
    80005264:	ffffe097          	auipc	ra,0xffffe
    80005268:	35c080e7          	jalr	860(ra) # 800035c0 <ilock>
  if(ip->type == T_DIR){
    8000526c:	04449703          	lh	a4,68(s1)
    80005270:	4785                	li	a5,1
    80005272:	08f70463          	beq	a4,a5,800052fa <sys_link+0xea>
  ip->nlink++;
    80005276:	04a4d783          	lhu	a5,74(s1)
    8000527a:	2785                	addiw	a5,a5,1
    8000527c:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005280:	8526                	mv	a0,s1
    80005282:	ffffe097          	auipc	ra,0xffffe
    80005286:	274080e7          	jalr	628(ra) # 800034f6 <iupdate>
  iunlock(ip);
    8000528a:	8526                	mv	a0,s1
    8000528c:	ffffe097          	auipc	ra,0xffffe
    80005290:	3f6080e7          	jalr	1014(ra) # 80003682 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005294:	fd040593          	addi	a1,s0,-48
    80005298:	f5040513          	addi	a0,s0,-176
    8000529c:	fffff097          	auipc	ra,0xfffff
    800052a0:	af8080e7          	jalr	-1288(ra) # 80003d94 <nameiparent>
    800052a4:	892a                	mv	s2,a0
    800052a6:	c935                	beqz	a0,8000531a <sys_link+0x10a>
  ilock(dp);
    800052a8:	ffffe097          	auipc	ra,0xffffe
    800052ac:	318080e7          	jalr	792(ra) # 800035c0 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    800052b0:	00092703          	lw	a4,0(s2)
    800052b4:	409c                	lw	a5,0(s1)
    800052b6:	04f71d63          	bne	a4,a5,80005310 <sys_link+0x100>
    800052ba:	40d0                	lw	a2,4(s1)
    800052bc:	fd040593          	addi	a1,s0,-48
    800052c0:	854a                	mv	a0,s2
    800052c2:	fffff097          	auipc	ra,0xfffff
    800052c6:	9f2080e7          	jalr	-1550(ra) # 80003cb4 <dirlink>
    800052ca:	04054363          	bltz	a0,80005310 <sys_link+0x100>
  iunlockput(dp);
    800052ce:	854a                	mv	a0,s2
    800052d0:	ffffe097          	auipc	ra,0xffffe
    800052d4:	552080e7          	jalr	1362(ra) # 80003822 <iunlockput>
  iput(ip);
    800052d8:	8526                	mv	a0,s1
    800052da:	ffffe097          	auipc	ra,0xffffe
    800052de:	4a0080e7          	jalr	1184(ra) # 8000377a <iput>
  end_op();
    800052e2:	fffff097          	auipc	ra,0xfffff
    800052e6:	d30080e7          	jalr	-720(ra) # 80004012 <end_op>
  return 0;
    800052ea:	4781                	li	a5,0
    800052ec:	a085                	j	8000534c <sys_link+0x13c>
    end_op();
    800052ee:	fffff097          	auipc	ra,0xfffff
    800052f2:	d24080e7          	jalr	-732(ra) # 80004012 <end_op>
    return -1;
    800052f6:	57fd                	li	a5,-1
    800052f8:	a891                	j	8000534c <sys_link+0x13c>
    iunlockput(ip);
    800052fa:	8526                	mv	a0,s1
    800052fc:	ffffe097          	auipc	ra,0xffffe
    80005300:	526080e7          	jalr	1318(ra) # 80003822 <iunlockput>
    end_op();
    80005304:	fffff097          	auipc	ra,0xfffff
    80005308:	d0e080e7          	jalr	-754(ra) # 80004012 <end_op>
    return -1;
    8000530c:	57fd                	li	a5,-1
    8000530e:	a83d                	j	8000534c <sys_link+0x13c>
    iunlockput(dp);
    80005310:	854a                	mv	a0,s2
    80005312:	ffffe097          	auipc	ra,0xffffe
    80005316:	510080e7          	jalr	1296(ra) # 80003822 <iunlockput>
  ilock(ip);
    8000531a:	8526                	mv	a0,s1
    8000531c:	ffffe097          	auipc	ra,0xffffe
    80005320:	2a4080e7          	jalr	676(ra) # 800035c0 <ilock>
  ip->nlink--;
    80005324:	04a4d783          	lhu	a5,74(s1)
    80005328:	37fd                	addiw	a5,a5,-1
    8000532a:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000532e:	8526                	mv	a0,s1
    80005330:	ffffe097          	auipc	ra,0xffffe
    80005334:	1c6080e7          	jalr	454(ra) # 800034f6 <iupdate>
  iunlockput(ip);
    80005338:	8526                	mv	a0,s1
    8000533a:	ffffe097          	auipc	ra,0xffffe
    8000533e:	4e8080e7          	jalr	1256(ra) # 80003822 <iunlockput>
  end_op();
    80005342:	fffff097          	auipc	ra,0xfffff
    80005346:	cd0080e7          	jalr	-816(ra) # 80004012 <end_op>
  return -1;
    8000534a:	57fd                	li	a5,-1
}
    8000534c:	853e                	mv	a0,a5
    8000534e:	70b2                	ld	ra,296(sp)
    80005350:	7412                	ld	s0,288(sp)
    80005352:	64f2                	ld	s1,280(sp)
    80005354:	6952                	ld	s2,272(sp)
    80005356:	6155                	addi	sp,sp,304
    80005358:	8082                	ret

000000008000535a <sys_unlink>:
{
    8000535a:	7151                	addi	sp,sp,-240
    8000535c:	f586                	sd	ra,232(sp)
    8000535e:	f1a2                	sd	s0,224(sp)
    80005360:	eda6                	sd	s1,216(sp)
    80005362:	e9ca                	sd	s2,208(sp)
    80005364:	e5ce                	sd	s3,200(sp)
    80005366:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005368:	08000613          	li	a2,128
    8000536c:	f3040593          	addi	a1,s0,-208
    80005370:	4501                	li	a0,0
    80005372:	ffffd097          	auipc	ra,0xffffd
    80005376:	720080e7          	jalr	1824(ra) # 80002a92 <argstr>
    8000537a:	18054163          	bltz	a0,800054fc <sys_unlink+0x1a2>
  begin_op();
    8000537e:	fffff097          	auipc	ra,0xfffff
    80005382:	c14080e7          	jalr	-1004(ra) # 80003f92 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005386:	fb040593          	addi	a1,s0,-80
    8000538a:	f3040513          	addi	a0,s0,-208
    8000538e:	fffff097          	auipc	ra,0xfffff
    80005392:	a06080e7          	jalr	-1530(ra) # 80003d94 <nameiparent>
    80005396:	84aa                	mv	s1,a0
    80005398:	c979                	beqz	a0,8000546e <sys_unlink+0x114>
  ilock(dp);
    8000539a:	ffffe097          	auipc	ra,0xffffe
    8000539e:	226080e7          	jalr	550(ra) # 800035c0 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    800053a2:	00003597          	auipc	a1,0x3
    800053a6:	35658593          	addi	a1,a1,854 # 800086f8 <syscalls+0x2b0>
    800053aa:	fb040513          	addi	a0,s0,-80
    800053ae:	ffffe097          	auipc	ra,0xffffe
    800053b2:	6dc080e7          	jalr	1756(ra) # 80003a8a <namecmp>
    800053b6:	14050a63          	beqz	a0,8000550a <sys_unlink+0x1b0>
    800053ba:	00003597          	auipc	a1,0x3
    800053be:	34658593          	addi	a1,a1,838 # 80008700 <syscalls+0x2b8>
    800053c2:	fb040513          	addi	a0,s0,-80
    800053c6:	ffffe097          	auipc	ra,0xffffe
    800053ca:	6c4080e7          	jalr	1732(ra) # 80003a8a <namecmp>
    800053ce:	12050e63          	beqz	a0,8000550a <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    800053d2:	f2c40613          	addi	a2,s0,-212
    800053d6:	fb040593          	addi	a1,s0,-80
    800053da:	8526                	mv	a0,s1
    800053dc:	ffffe097          	auipc	ra,0xffffe
    800053e0:	6c8080e7          	jalr	1736(ra) # 80003aa4 <dirlookup>
    800053e4:	892a                	mv	s2,a0
    800053e6:	12050263          	beqz	a0,8000550a <sys_unlink+0x1b0>
  ilock(ip);
    800053ea:	ffffe097          	auipc	ra,0xffffe
    800053ee:	1d6080e7          	jalr	470(ra) # 800035c0 <ilock>
  if(ip->nlink < 1)
    800053f2:	04a91783          	lh	a5,74(s2)
    800053f6:	08f05263          	blez	a5,8000547a <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    800053fa:	04491703          	lh	a4,68(s2)
    800053fe:	4785                	li	a5,1
    80005400:	08f70563          	beq	a4,a5,8000548a <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005404:	4641                	li	a2,16
    80005406:	4581                	li	a1,0
    80005408:	fc040513          	addi	a0,s0,-64
    8000540c:	ffffc097          	auipc	ra,0xffffc
    80005410:	8d4080e7          	jalr	-1836(ra) # 80000ce0 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005414:	4741                	li	a4,16
    80005416:	f2c42683          	lw	a3,-212(s0)
    8000541a:	fc040613          	addi	a2,s0,-64
    8000541e:	4581                	li	a1,0
    80005420:	8526                	mv	a0,s1
    80005422:	ffffe097          	auipc	ra,0xffffe
    80005426:	54a080e7          	jalr	1354(ra) # 8000396c <writei>
    8000542a:	47c1                	li	a5,16
    8000542c:	0af51563          	bne	a0,a5,800054d6 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005430:	04491703          	lh	a4,68(s2)
    80005434:	4785                	li	a5,1
    80005436:	0af70863          	beq	a4,a5,800054e6 <sys_unlink+0x18c>
  iunlockput(dp);
    8000543a:	8526                	mv	a0,s1
    8000543c:	ffffe097          	auipc	ra,0xffffe
    80005440:	3e6080e7          	jalr	998(ra) # 80003822 <iunlockput>
  ip->nlink--;
    80005444:	04a95783          	lhu	a5,74(s2)
    80005448:	37fd                	addiw	a5,a5,-1
    8000544a:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    8000544e:	854a                	mv	a0,s2
    80005450:	ffffe097          	auipc	ra,0xffffe
    80005454:	0a6080e7          	jalr	166(ra) # 800034f6 <iupdate>
  iunlockput(ip);
    80005458:	854a                	mv	a0,s2
    8000545a:	ffffe097          	auipc	ra,0xffffe
    8000545e:	3c8080e7          	jalr	968(ra) # 80003822 <iunlockput>
  end_op();
    80005462:	fffff097          	auipc	ra,0xfffff
    80005466:	bb0080e7          	jalr	-1104(ra) # 80004012 <end_op>
  return 0;
    8000546a:	4501                	li	a0,0
    8000546c:	a84d                	j	8000551e <sys_unlink+0x1c4>
    end_op();
    8000546e:	fffff097          	auipc	ra,0xfffff
    80005472:	ba4080e7          	jalr	-1116(ra) # 80004012 <end_op>
    return -1;
    80005476:	557d                	li	a0,-1
    80005478:	a05d                	j	8000551e <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    8000547a:	00003517          	auipc	a0,0x3
    8000547e:	2ae50513          	addi	a0,a0,686 # 80008728 <syscalls+0x2e0>
    80005482:	ffffb097          	auipc	ra,0xffffb
    80005486:	0bc080e7          	jalr	188(ra) # 8000053e <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    8000548a:	04c92703          	lw	a4,76(s2)
    8000548e:	02000793          	li	a5,32
    80005492:	f6e7f9e3          	bgeu	a5,a4,80005404 <sys_unlink+0xaa>
    80005496:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000549a:	4741                	li	a4,16
    8000549c:	86ce                	mv	a3,s3
    8000549e:	f1840613          	addi	a2,s0,-232
    800054a2:	4581                	li	a1,0
    800054a4:	854a                	mv	a0,s2
    800054a6:	ffffe097          	auipc	ra,0xffffe
    800054aa:	3ce080e7          	jalr	974(ra) # 80003874 <readi>
    800054ae:	47c1                	li	a5,16
    800054b0:	00f51b63          	bne	a0,a5,800054c6 <sys_unlink+0x16c>
    if(de.inum != 0)
    800054b4:	f1845783          	lhu	a5,-232(s0)
    800054b8:	e7a1                	bnez	a5,80005500 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800054ba:	29c1                	addiw	s3,s3,16
    800054bc:	04c92783          	lw	a5,76(s2)
    800054c0:	fcf9ede3          	bltu	s3,a5,8000549a <sys_unlink+0x140>
    800054c4:	b781                	j	80005404 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    800054c6:	00003517          	auipc	a0,0x3
    800054ca:	27a50513          	addi	a0,a0,634 # 80008740 <syscalls+0x2f8>
    800054ce:	ffffb097          	auipc	ra,0xffffb
    800054d2:	070080e7          	jalr	112(ra) # 8000053e <panic>
    panic("unlink: writei");
    800054d6:	00003517          	auipc	a0,0x3
    800054da:	28250513          	addi	a0,a0,642 # 80008758 <syscalls+0x310>
    800054de:	ffffb097          	auipc	ra,0xffffb
    800054e2:	060080e7          	jalr	96(ra) # 8000053e <panic>
    dp->nlink--;
    800054e6:	04a4d783          	lhu	a5,74(s1)
    800054ea:	37fd                	addiw	a5,a5,-1
    800054ec:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    800054f0:	8526                	mv	a0,s1
    800054f2:	ffffe097          	auipc	ra,0xffffe
    800054f6:	004080e7          	jalr	4(ra) # 800034f6 <iupdate>
    800054fa:	b781                	j	8000543a <sys_unlink+0xe0>
    return -1;
    800054fc:	557d                	li	a0,-1
    800054fe:	a005                	j	8000551e <sys_unlink+0x1c4>
    iunlockput(ip);
    80005500:	854a                	mv	a0,s2
    80005502:	ffffe097          	auipc	ra,0xffffe
    80005506:	320080e7          	jalr	800(ra) # 80003822 <iunlockput>
  iunlockput(dp);
    8000550a:	8526                	mv	a0,s1
    8000550c:	ffffe097          	auipc	ra,0xffffe
    80005510:	316080e7          	jalr	790(ra) # 80003822 <iunlockput>
  end_op();
    80005514:	fffff097          	auipc	ra,0xfffff
    80005518:	afe080e7          	jalr	-1282(ra) # 80004012 <end_op>
  return -1;
    8000551c:	557d                	li	a0,-1
}
    8000551e:	70ae                	ld	ra,232(sp)
    80005520:	740e                	ld	s0,224(sp)
    80005522:	64ee                	ld	s1,216(sp)
    80005524:	694e                	ld	s2,208(sp)
    80005526:	69ae                	ld	s3,200(sp)
    80005528:	616d                	addi	sp,sp,240
    8000552a:	8082                	ret

000000008000552c <sys_open>:

uint64
sys_open(void)
{
    8000552c:	7131                	addi	sp,sp,-192
    8000552e:	fd06                	sd	ra,184(sp)
    80005530:	f922                	sd	s0,176(sp)
    80005532:	f526                	sd	s1,168(sp)
    80005534:	f14a                	sd	s2,160(sp)
    80005536:	ed4e                	sd	s3,152(sp)
    80005538:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    8000553a:	08000613          	li	a2,128
    8000553e:	f5040593          	addi	a1,s0,-176
    80005542:	4501                	li	a0,0
    80005544:	ffffd097          	auipc	ra,0xffffd
    80005548:	54e080e7          	jalr	1358(ra) # 80002a92 <argstr>
    return -1;
    8000554c:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    8000554e:	0c054163          	bltz	a0,80005610 <sys_open+0xe4>
    80005552:	f4c40593          	addi	a1,s0,-180
    80005556:	4505                	li	a0,1
    80005558:	ffffd097          	auipc	ra,0xffffd
    8000555c:	4f6080e7          	jalr	1270(ra) # 80002a4e <argint>
    80005560:	0a054863          	bltz	a0,80005610 <sys_open+0xe4>

  begin_op();
    80005564:	fffff097          	auipc	ra,0xfffff
    80005568:	a2e080e7          	jalr	-1490(ra) # 80003f92 <begin_op>

  if(omode & O_CREATE){
    8000556c:	f4c42783          	lw	a5,-180(s0)
    80005570:	2007f793          	andi	a5,a5,512
    80005574:	cbdd                	beqz	a5,8000562a <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005576:	4681                	li	a3,0
    80005578:	4601                	li	a2,0
    8000557a:	4589                	li	a1,2
    8000557c:	f5040513          	addi	a0,s0,-176
    80005580:	00000097          	auipc	ra,0x0
    80005584:	972080e7          	jalr	-1678(ra) # 80004ef2 <create>
    80005588:	892a                	mv	s2,a0
    if(ip == 0){
    8000558a:	c959                	beqz	a0,80005620 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    8000558c:	04491703          	lh	a4,68(s2)
    80005590:	478d                	li	a5,3
    80005592:	00f71763          	bne	a4,a5,800055a0 <sys_open+0x74>
    80005596:	04695703          	lhu	a4,70(s2)
    8000559a:	47a5                	li	a5,9
    8000559c:	0ce7ec63          	bltu	a5,a4,80005674 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    800055a0:	fffff097          	auipc	ra,0xfffff
    800055a4:	e02080e7          	jalr	-510(ra) # 800043a2 <filealloc>
    800055a8:	89aa                	mv	s3,a0
    800055aa:	10050263          	beqz	a0,800056ae <sys_open+0x182>
    800055ae:	00000097          	auipc	ra,0x0
    800055b2:	902080e7          	jalr	-1790(ra) # 80004eb0 <fdalloc>
    800055b6:	84aa                	mv	s1,a0
    800055b8:	0e054663          	bltz	a0,800056a4 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    800055bc:	04491703          	lh	a4,68(s2)
    800055c0:	478d                	li	a5,3
    800055c2:	0cf70463          	beq	a4,a5,8000568a <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    800055c6:	4789                	li	a5,2
    800055c8:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    800055cc:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    800055d0:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    800055d4:	f4c42783          	lw	a5,-180(s0)
    800055d8:	0017c713          	xori	a4,a5,1
    800055dc:	8b05                	andi	a4,a4,1
    800055de:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    800055e2:	0037f713          	andi	a4,a5,3
    800055e6:	00e03733          	snez	a4,a4
    800055ea:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    800055ee:	4007f793          	andi	a5,a5,1024
    800055f2:	c791                	beqz	a5,800055fe <sys_open+0xd2>
    800055f4:	04491703          	lh	a4,68(s2)
    800055f8:	4789                	li	a5,2
    800055fa:	08f70f63          	beq	a4,a5,80005698 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    800055fe:	854a                	mv	a0,s2
    80005600:	ffffe097          	auipc	ra,0xffffe
    80005604:	082080e7          	jalr	130(ra) # 80003682 <iunlock>
  end_op();
    80005608:	fffff097          	auipc	ra,0xfffff
    8000560c:	a0a080e7          	jalr	-1526(ra) # 80004012 <end_op>

  return fd;
}
    80005610:	8526                	mv	a0,s1
    80005612:	70ea                	ld	ra,184(sp)
    80005614:	744a                	ld	s0,176(sp)
    80005616:	74aa                	ld	s1,168(sp)
    80005618:	790a                	ld	s2,160(sp)
    8000561a:	69ea                	ld	s3,152(sp)
    8000561c:	6129                	addi	sp,sp,192
    8000561e:	8082                	ret
      end_op();
    80005620:	fffff097          	auipc	ra,0xfffff
    80005624:	9f2080e7          	jalr	-1550(ra) # 80004012 <end_op>
      return -1;
    80005628:	b7e5                	j	80005610 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    8000562a:	f5040513          	addi	a0,s0,-176
    8000562e:	ffffe097          	auipc	ra,0xffffe
    80005632:	748080e7          	jalr	1864(ra) # 80003d76 <namei>
    80005636:	892a                	mv	s2,a0
    80005638:	c905                	beqz	a0,80005668 <sys_open+0x13c>
    ilock(ip);
    8000563a:	ffffe097          	auipc	ra,0xffffe
    8000563e:	f86080e7          	jalr	-122(ra) # 800035c0 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005642:	04491703          	lh	a4,68(s2)
    80005646:	4785                	li	a5,1
    80005648:	f4f712e3          	bne	a4,a5,8000558c <sys_open+0x60>
    8000564c:	f4c42783          	lw	a5,-180(s0)
    80005650:	dba1                	beqz	a5,800055a0 <sys_open+0x74>
      iunlockput(ip);
    80005652:	854a                	mv	a0,s2
    80005654:	ffffe097          	auipc	ra,0xffffe
    80005658:	1ce080e7          	jalr	462(ra) # 80003822 <iunlockput>
      end_op();
    8000565c:	fffff097          	auipc	ra,0xfffff
    80005660:	9b6080e7          	jalr	-1610(ra) # 80004012 <end_op>
      return -1;
    80005664:	54fd                	li	s1,-1
    80005666:	b76d                	j	80005610 <sys_open+0xe4>
      end_op();
    80005668:	fffff097          	auipc	ra,0xfffff
    8000566c:	9aa080e7          	jalr	-1622(ra) # 80004012 <end_op>
      return -1;
    80005670:	54fd                	li	s1,-1
    80005672:	bf79                	j	80005610 <sys_open+0xe4>
    iunlockput(ip);
    80005674:	854a                	mv	a0,s2
    80005676:	ffffe097          	auipc	ra,0xffffe
    8000567a:	1ac080e7          	jalr	428(ra) # 80003822 <iunlockput>
    end_op();
    8000567e:	fffff097          	auipc	ra,0xfffff
    80005682:	994080e7          	jalr	-1644(ra) # 80004012 <end_op>
    return -1;
    80005686:	54fd                	li	s1,-1
    80005688:	b761                	j	80005610 <sys_open+0xe4>
    f->type = FD_DEVICE;
    8000568a:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    8000568e:	04691783          	lh	a5,70(s2)
    80005692:	02f99223          	sh	a5,36(s3)
    80005696:	bf2d                	j	800055d0 <sys_open+0xa4>
    itrunc(ip);
    80005698:	854a                	mv	a0,s2
    8000569a:	ffffe097          	auipc	ra,0xffffe
    8000569e:	034080e7          	jalr	52(ra) # 800036ce <itrunc>
    800056a2:	bfb1                	j	800055fe <sys_open+0xd2>
      fileclose(f);
    800056a4:	854e                	mv	a0,s3
    800056a6:	fffff097          	auipc	ra,0xfffff
    800056aa:	db8080e7          	jalr	-584(ra) # 8000445e <fileclose>
    iunlockput(ip);
    800056ae:	854a                	mv	a0,s2
    800056b0:	ffffe097          	auipc	ra,0xffffe
    800056b4:	172080e7          	jalr	370(ra) # 80003822 <iunlockput>
    end_op();
    800056b8:	fffff097          	auipc	ra,0xfffff
    800056bc:	95a080e7          	jalr	-1702(ra) # 80004012 <end_op>
    return -1;
    800056c0:	54fd                	li	s1,-1
    800056c2:	b7b9                	j	80005610 <sys_open+0xe4>

00000000800056c4 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    800056c4:	7175                	addi	sp,sp,-144
    800056c6:	e506                	sd	ra,136(sp)
    800056c8:	e122                	sd	s0,128(sp)
    800056ca:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    800056cc:	fffff097          	auipc	ra,0xfffff
    800056d0:	8c6080e7          	jalr	-1850(ra) # 80003f92 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    800056d4:	08000613          	li	a2,128
    800056d8:	f7040593          	addi	a1,s0,-144
    800056dc:	4501                	li	a0,0
    800056de:	ffffd097          	auipc	ra,0xffffd
    800056e2:	3b4080e7          	jalr	948(ra) # 80002a92 <argstr>
    800056e6:	02054963          	bltz	a0,80005718 <sys_mkdir+0x54>
    800056ea:	4681                	li	a3,0
    800056ec:	4601                	li	a2,0
    800056ee:	4585                	li	a1,1
    800056f0:	f7040513          	addi	a0,s0,-144
    800056f4:	fffff097          	auipc	ra,0xfffff
    800056f8:	7fe080e7          	jalr	2046(ra) # 80004ef2 <create>
    800056fc:	cd11                	beqz	a0,80005718 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800056fe:	ffffe097          	auipc	ra,0xffffe
    80005702:	124080e7          	jalr	292(ra) # 80003822 <iunlockput>
  end_op();
    80005706:	fffff097          	auipc	ra,0xfffff
    8000570a:	90c080e7          	jalr	-1780(ra) # 80004012 <end_op>
  return 0;
    8000570e:	4501                	li	a0,0
}
    80005710:	60aa                	ld	ra,136(sp)
    80005712:	640a                	ld	s0,128(sp)
    80005714:	6149                	addi	sp,sp,144
    80005716:	8082                	ret
    end_op();
    80005718:	fffff097          	auipc	ra,0xfffff
    8000571c:	8fa080e7          	jalr	-1798(ra) # 80004012 <end_op>
    return -1;
    80005720:	557d                	li	a0,-1
    80005722:	b7fd                	j	80005710 <sys_mkdir+0x4c>

0000000080005724 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005724:	7135                	addi	sp,sp,-160
    80005726:	ed06                	sd	ra,152(sp)
    80005728:	e922                	sd	s0,144(sp)
    8000572a:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    8000572c:	fffff097          	auipc	ra,0xfffff
    80005730:	866080e7          	jalr	-1946(ra) # 80003f92 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005734:	08000613          	li	a2,128
    80005738:	f7040593          	addi	a1,s0,-144
    8000573c:	4501                	li	a0,0
    8000573e:	ffffd097          	auipc	ra,0xffffd
    80005742:	354080e7          	jalr	852(ra) # 80002a92 <argstr>
    80005746:	04054a63          	bltz	a0,8000579a <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    8000574a:	f6c40593          	addi	a1,s0,-148
    8000574e:	4505                	li	a0,1
    80005750:	ffffd097          	auipc	ra,0xffffd
    80005754:	2fe080e7          	jalr	766(ra) # 80002a4e <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005758:	04054163          	bltz	a0,8000579a <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    8000575c:	f6840593          	addi	a1,s0,-152
    80005760:	4509                	li	a0,2
    80005762:	ffffd097          	auipc	ra,0xffffd
    80005766:	2ec080e7          	jalr	748(ra) # 80002a4e <argint>
     argint(1, &major) < 0 ||
    8000576a:	02054863          	bltz	a0,8000579a <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    8000576e:	f6841683          	lh	a3,-152(s0)
    80005772:	f6c41603          	lh	a2,-148(s0)
    80005776:	458d                	li	a1,3
    80005778:	f7040513          	addi	a0,s0,-144
    8000577c:	fffff097          	auipc	ra,0xfffff
    80005780:	776080e7          	jalr	1910(ra) # 80004ef2 <create>
     argint(2, &minor) < 0 ||
    80005784:	c919                	beqz	a0,8000579a <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005786:	ffffe097          	auipc	ra,0xffffe
    8000578a:	09c080e7          	jalr	156(ra) # 80003822 <iunlockput>
  end_op();
    8000578e:	fffff097          	auipc	ra,0xfffff
    80005792:	884080e7          	jalr	-1916(ra) # 80004012 <end_op>
  return 0;
    80005796:	4501                	li	a0,0
    80005798:	a031                	j	800057a4 <sys_mknod+0x80>
    end_op();
    8000579a:	fffff097          	auipc	ra,0xfffff
    8000579e:	878080e7          	jalr	-1928(ra) # 80004012 <end_op>
    return -1;
    800057a2:	557d                	li	a0,-1
}
    800057a4:	60ea                	ld	ra,152(sp)
    800057a6:	644a                	ld	s0,144(sp)
    800057a8:	610d                	addi	sp,sp,160
    800057aa:	8082                	ret

00000000800057ac <sys_chdir>:

uint64
sys_chdir(void)
{
    800057ac:	7135                	addi	sp,sp,-160
    800057ae:	ed06                	sd	ra,152(sp)
    800057b0:	e922                	sd	s0,144(sp)
    800057b2:	e526                	sd	s1,136(sp)
    800057b4:	e14a                	sd	s2,128(sp)
    800057b6:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    800057b8:	ffffc097          	auipc	ra,0xffffc
    800057bc:	1f8080e7          	jalr	504(ra) # 800019b0 <myproc>
    800057c0:	892a                	mv	s2,a0
  
  begin_op();
    800057c2:	ffffe097          	auipc	ra,0xffffe
    800057c6:	7d0080e7          	jalr	2000(ra) # 80003f92 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    800057ca:	08000613          	li	a2,128
    800057ce:	f6040593          	addi	a1,s0,-160
    800057d2:	4501                	li	a0,0
    800057d4:	ffffd097          	auipc	ra,0xffffd
    800057d8:	2be080e7          	jalr	702(ra) # 80002a92 <argstr>
    800057dc:	04054b63          	bltz	a0,80005832 <sys_chdir+0x86>
    800057e0:	f6040513          	addi	a0,s0,-160
    800057e4:	ffffe097          	auipc	ra,0xffffe
    800057e8:	592080e7          	jalr	1426(ra) # 80003d76 <namei>
    800057ec:	84aa                	mv	s1,a0
    800057ee:	c131                	beqz	a0,80005832 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    800057f0:	ffffe097          	auipc	ra,0xffffe
    800057f4:	dd0080e7          	jalr	-560(ra) # 800035c0 <ilock>
  if(ip->type != T_DIR){
    800057f8:	04449703          	lh	a4,68(s1)
    800057fc:	4785                	li	a5,1
    800057fe:	04f71063          	bne	a4,a5,8000583e <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005802:	8526                	mv	a0,s1
    80005804:	ffffe097          	auipc	ra,0xffffe
    80005808:	e7e080e7          	jalr	-386(ra) # 80003682 <iunlock>
  iput(p->cwd);
    8000580c:	15093503          	ld	a0,336(s2)
    80005810:	ffffe097          	auipc	ra,0xffffe
    80005814:	f6a080e7          	jalr	-150(ra) # 8000377a <iput>
  end_op();
    80005818:	ffffe097          	auipc	ra,0xffffe
    8000581c:	7fa080e7          	jalr	2042(ra) # 80004012 <end_op>
  p->cwd = ip;
    80005820:	14993823          	sd	s1,336(s2)
  return 0;
    80005824:	4501                	li	a0,0
}
    80005826:	60ea                	ld	ra,152(sp)
    80005828:	644a                	ld	s0,144(sp)
    8000582a:	64aa                	ld	s1,136(sp)
    8000582c:	690a                	ld	s2,128(sp)
    8000582e:	610d                	addi	sp,sp,160
    80005830:	8082                	ret
    end_op();
    80005832:	ffffe097          	auipc	ra,0xffffe
    80005836:	7e0080e7          	jalr	2016(ra) # 80004012 <end_op>
    return -1;
    8000583a:	557d                	li	a0,-1
    8000583c:	b7ed                	j	80005826 <sys_chdir+0x7a>
    iunlockput(ip);
    8000583e:	8526                	mv	a0,s1
    80005840:	ffffe097          	auipc	ra,0xffffe
    80005844:	fe2080e7          	jalr	-30(ra) # 80003822 <iunlockput>
    end_op();
    80005848:	ffffe097          	auipc	ra,0xffffe
    8000584c:	7ca080e7          	jalr	1994(ra) # 80004012 <end_op>
    return -1;
    80005850:	557d                	li	a0,-1
    80005852:	bfd1                	j	80005826 <sys_chdir+0x7a>

0000000080005854 <sys_exec>:

uint64
sys_exec(void)
{
    80005854:	7145                	addi	sp,sp,-464
    80005856:	e786                	sd	ra,456(sp)
    80005858:	e3a2                	sd	s0,448(sp)
    8000585a:	ff26                	sd	s1,440(sp)
    8000585c:	fb4a                	sd	s2,432(sp)
    8000585e:	f74e                	sd	s3,424(sp)
    80005860:	f352                	sd	s4,416(sp)
    80005862:	ef56                	sd	s5,408(sp)
    80005864:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005866:	08000613          	li	a2,128
    8000586a:	f4040593          	addi	a1,s0,-192
    8000586e:	4501                	li	a0,0
    80005870:	ffffd097          	auipc	ra,0xffffd
    80005874:	222080e7          	jalr	546(ra) # 80002a92 <argstr>
    return -1;
    80005878:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    8000587a:	0c054a63          	bltz	a0,8000594e <sys_exec+0xfa>
    8000587e:	e3840593          	addi	a1,s0,-456
    80005882:	4505                	li	a0,1
    80005884:	ffffd097          	auipc	ra,0xffffd
    80005888:	1ec080e7          	jalr	492(ra) # 80002a70 <argaddr>
    8000588c:	0c054163          	bltz	a0,8000594e <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005890:	10000613          	li	a2,256
    80005894:	4581                	li	a1,0
    80005896:	e4040513          	addi	a0,s0,-448
    8000589a:	ffffb097          	auipc	ra,0xffffb
    8000589e:	446080e7          	jalr	1094(ra) # 80000ce0 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    800058a2:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    800058a6:	89a6                	mv	s3,s1
    800058a8:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    800058aa:	02000a13          	li	s4,32
    800058ae:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    800058b2:	00391513          	slli	a0,s2,0x3
    800058b6:	e3040593          	addi	a1,s0,-464
    800058ba:	e3843783          	ld	a5,-456(s0)
    800058be:	953e                	add	a0,a0,a5
    800058c0:	ffffd097          	auipc	ra,0xffffd
    800058c4:	0f4080e7          	jalr	244(ra) # 800029b4 <fetchaddr>
    800058c8:	02054a63          	bltz	a0,800058fc <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    800058cc:	e3043783          	ld	a5,-464(s0)
    800058d0:	c3b9                	beqz	a5,80005916 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    800058d2:	ffffb097          	auipc	ra,0xffffb
    800058d6:	222080e7          	jalr	546(ra) # 80000af4 <kalloc>
    800058da:	85aa                	mv	a1,a0
    800058dc:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    800058e0:	cd11                	beqz	a0,800058fc <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    800058e2:	6605                	lui	a2,0x1
    800058e4:	e3043503          	ld	a0,-464(s0)
    800058e8:	ffffd097          	auipc	ra,0xffffd
    800058ec:	11e080e7          	jalr	286(ra) # 80002a06 <fetchstr>
    800058f0:	00054663          	bltz	a0,800058fc <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    800058f4:	0905                	addi	s2,s2,1
    800058f6:	09a1                	addi	s3,s3,8
    800058f8:	fb491be3          	bne	s2,s4,800058ae <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800058fc:	10048913          	addi	s2,s1,256
    80005900:	6088                	ld	a0,0(s1)
    80005902:	c529                	beqz	a0,8000594c <sys_exec+0xf8>
    kfree(argv[i]);
    80005904:	ffffb097          	auipc	ra,0xffffb
    80005908:	0f4080e7          	jalr	244(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000590c:	04a1                	addi	s1,s1,8
    8000590e:	ff2499e3          	bne	s1,s2,80005900 <sys_exec+0xac>
  return -1;
    80005912:	597d                	li	s2,-1
    80005914:	a82d                	j	8000594e <sys_exec+0xfa>
      argv[i] = 0;
    80005916:	0a8e                	slli	s5,s5,0x3
    80005918:	fc040793          	addi	a5,s0,-64
    8000591c:	9abe                	add	s5,s5,a5
    8000591e:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005922:	e4040593          	addi	a1,s0,-448
    80005926:	f4040513          	addi	a0,s0,-192
    8000592a:	fffff097          	auipc	ra,0xfffff
    8000592e:	194080e7          	jalr	404(ra) # 80004abe <exec>
    80005932:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005934:	10048993          	addi	s3,s1,256
    80005938:	6088                	ld	a0,0(s1)
    8000593a:	c911                	beqz	a0,8000594e <sys_exec+0xfa>
    kfree(argv[i]);
    8000593c:	ffffb097          	auipc	ra,0xffffb
    80005940:	0bc080e7          	jalr	188(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005944:	04a1                	addi	s1,s1,8
    80005946:	ff3499e3          	bne	s1,s3,80005938 <sys_exec+0xe4>
    8000594a:	a011                	j	8000594e <sys_exec+0xfa>
  return -1;
    8000594c:	597d                	li	s2,-1
}
    8000594e:	854a                	mv	a0,s2
    80005950:	60be                	ld	ra,456(sp)
    80005952:	641e                	ld	s0,448(sp)
    80005954:	74fa                	ld	s1,440(sp)
    80005956:	795a                	ld	s2,432(sp)
    80005958:	79ba                	ld	s3,424(sp)
    8000595a:	7a1a                	ld	s4,416(sp)
    8000595c:	6afa                	ld	s5,408(sp)
    8000595e:	6179                	addi	sp,sp,464
    80005960:	8082                	ret

0000000080005962 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005962:	7139                	addi	sp,sp,-64
    80005964:	fc06                	sd	ra,56(sp)
    80005966:	f822                	sd	s0,48(sp)
    80005968:	f426                	sd	s1,40(sp)
    8000596a:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    8000596c:	ffffc097          	auipc	ra,0xffffc
    80005970:	044080e7          	jalr	68(ra) # 800019b0 <myproc>
    80005974:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005976:	fd840593          	addi	a1,s0,-40
    8000597a:	4501                	li	a0,0
    8000597c:	ffffd097          	auipc	ra,0xffffd
    80005980:	0f4080e7          	jalr	244(ra) # 80002a70 <argaddr>
    return -1;
    80005984:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005986:	0e054063          	bltz	a0,80005a66 <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    8000598a:	fc840593          	addi	a1,s0,-56
    8000598e:	fd040513          	addi	a0,s0,-48
    80005992:	fffff097          	auipc	ra,0xfffff
    80005996:	dfc080e7          	jalr	-516(ra) # 8000478e <pipealloc>
    return -1;
    8000599a:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    8000599c:	0c054563          	bltz	a0,80005a66 <sys_pipe+0x104>
  fd0 = -1;
    800059a0:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    800059a4:	fd043503          	ld	a0,-48(s0)
    800059a8:	fffff097          	auipc	ra,0xfffff
    800059ac:	508080e7          	jalr	1288(ra) # 80004eb0 <fdalloc>
    800059b0:	fca42223          	sw	a0,-60(s0)
    800059b4:	08054c63          	bltz	a0,80005a4c <sys_pipe+0xea>
    800059b8:	fc843503          	ld	a0,-56(s0)
    800059bc:	fffff097          	auipc	ra,0xfffff
    800059c0:	4f4080e7          	jalr	1268(ra) # 80004eb0 <fdalloc>
    800059c4:	fca42023          	sw	a0,-64(s0)
    800059c8:	06054863          	bltz	a0,80005a38 <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    800059cc:	4691                	li	a3,4
    800059ce:	fc440613          	addi	a2,s0,-60
    800059d2:	fd843583          	ld	a1,-40(s0)
    800059d6:	68a8                	ld	a0,80(s1)
    800059d8:	ffffc097          	auipc	ra,0xffffc
    800059dc:	c9a080e7          	jalr	-870(ra) # 80001672 <copyout>
    800059e0:	02054063          	bltz	a0,80005a00 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    800059e4:	4691                	li	a3,4
    800059e6:	fc040613          	addi	a2,s0,-64
    800059ea:	fd843583          	ld	a1,-40(s0)
    800059ee:	0591                	addi	a1,a1,4
    800059f0:	68a8                	ld	a0,80(s1)
    800059f2:	ffffc097          	auipc	ra,0xffffc
    800059f6:	c80080e7          	jalr	-896(ra) # 80001672 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    800059fa:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    800059fc:	06055563          	bgez	a0,80005a66 <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005a00:	fc442783          	lw	a5,-60(s0)
    80005a04:	07e9                	addi	a5,a5,26
    80005a06:	078e                	slli	a5,a5,0x3
    80005a08:	97a6                	add	a5,a5,s1
    80005a0a:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005a0e:	fc042503          	lw	a0,-64(s0)
    80005a12:	0569                	addi	a0,a0,26
    80005a14:	050e                	slli	a0,a0,0x3
    80005a16:	9526                	add	a0,a0,s1
    80005a18:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005a1c:	fd043503          	ld	a0,-48(s0)
    80005a20:	fffff097          	auipc	ra,0xfffff
    80005a24:	a3e080e7          	jalr	-1474(ra) # 8000445e <fileclose>
    fileclose(wf);
    80005a28:	fc843503          	ld	a0,-56(s0)
    80005a2c:	fffff097          	auipc	ra,0xfffff
    80005a30:	a32080e7          	jalr	-1486(ra) # 8000445e <fileclose>
    return -1;
    80005a34:	57fd                	li	a5,-1
    80005a36:	a805                	j	80005a66 <sys_pipe+0x104>
    if(fd0 >= 0)
    80005a38:	fc442783          	lw	a5,-60(s0)
    80005a3c:	0007c863          	bltz	a5,80005a4c <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005a40:	01a78513          	addi	a0,a5,26
    80005a44:	050e                	slli	a0,a0,0x3
    80005a46:	9526                	add	a0,a0,s1
    80005a48:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005a4c:	fd043503          	ld	a0,-48(s0)
    80005a50:	fffff097          	auipc	ra,0xfffff
    80005a54:	a0e080e7          	jalr	-1522(ra) # 8000445e <fileclose>
    fileclose(wf);
    80005a58:	fc843503          	ld	a0,-56(s0)
    80005a5c:	fffff097          	auipc	ra,0xfffff
    80005a60:	a02080e7          	jalr	-1534(ra) # 8000445e <fileclose>
    return -1;
    80005a64:	57fd                	li	a5,-1
}
    80005a66:	853e                	mv	a0,a5
    80005a68:	70e2                	ld	ra,56(sp)
    80005a6a:	7442                	ld	s0,48(sp)
    80005a6c:	74a2                	ld	s1,40(sp)
    80005a6e:	6121                	addi	sp,sp,64
    80005a70:	8082                	ret
	...

0000000080005a80 <kernelvec>:
    80005a80:	7111                	addi	sp,sp,-256
    80005a82:	e006                	sd	ra,0(sp)
    80005a84:	e40a                	sd	sp,8(sp)
    80005a86:	e80e                	sd	gp,16(sp)
    80005a88:	ec12                	sd	tp,24(sp)
    80005a8a:	f016                	sd	t0,32(sp)
    80005a8c:	f41a                	sd	t1,40(sp)
    80005a8e:	f81e                	sd	t2,48(sp)
    80005a90:	fc22                	sd	s0,56(sp)
    80005a92:	e0a6                	sd	s1,64(sp)
    80005a94:	e4aa                	sd	a0,72(sp)
    80005a96:	e8ae                	sd	a1,80(sp)
    80005a98:	ecb2                	sd	a2,88(sp)
    80005a9a:	f0b6                	sd	a3,96(sp)
    80005a9c:	f4ba                	sd	a4,104(sp)
    80005a9e:	f8be                	sd	a5,112(sp)
    80005aa0:	fcc2                	sd	a6,120(sp)
    80005aa2:	e146                	sd	a7,128(sp)
    80005aa4:	e54a                	sd	s2,136(sp)
    80005aa6:	e94e                	sd	s3,144(sp)
    80005aa8:	ed52                	sd	s4,152(sp)
    80005aaa:	f156                	sd	s5,160(sp)
    80005aac:	f55a                	sd	s6,168(sp)
    80005aae:	f95e                	sd	s7,176(sp)
    80005ab0:	fd62                	sd	s8,184(sp)
    80005ab2:	e1e6                	sd	s9,192(sp)
    80005ab4:	e5ea                	sd	s10,200(sp)
    80005ab6:	e9ee                	sd	s11,208(sp)
    80005ab8:	edf2                	sd	t3,216(sp)
    80005aba:	f1f6                	sd	t4,224(sp)
    80005abc:	f5fa                	sd	t5,232(sp)
    80005abe:	f9fe                	sd	t6,240(sp)
    80005ac0:	dc1fc0ef          	jal	ra,80002880 <kerneltrap>
    80005ac4:	6082                	ld	ra,0(sp)
    80005ac6:	6122                	ld	sp,8(sp)
    80005ac8:	61c2                	ld	gp,16(sp)
    80005aca:	7282                	ld	t0,32(sp)
    80005acc:	7322                	ld	t1,40(sp)
    80005ace:	73c2                	ld	t2,48(sp)
    80005ad0:	7462                	ld	s0,56(sp)
    80005ad2:	6486                	ld	s1,64(sp)
    80005ad4:	6526                	ld	a0,72(sp)
    80005ad6:	65c6                	ld	a1,80(sp)
    80005ad8:	6666                	ld	a2,88(sp)
    80005ada:	7686                	ld	a3,96(sp)
    80005adc:	7726                	ld	a4,104(sp)
    80005ade:	77c6                	ld	a5,112(sp)
    80005ae0:	7866                	ld	a6,120(sp)
    80005ae2:	688a                	ld	a7,128(sp)
    80005ae4:	692a                	ld	s2,136(sp)
    80005ae6:	69ca                	ld	s3,144(sp)
    80005ae8:	6a6a                	ld	s4,152(sp)
    80005aea:	7a8a                	ld	s5,160(sp)
    80005aec:	7b2a                	ld	s6,168(sp)
    80005aee:	7bca                	ld	s7,176(sp)
    80005af0:	7c6a                	ld	s8,184(sp)
    80005af2:	6c8e                	ld	s9,192(sp)
    80005af4:	6d2e                	ld	s10,200(sp)
    80005af6:	6dce                	ld	s11,208(sp)
    80005af8:	6e6e                	ld	t3,216(sp)
    80005afa:	7e8e                	ld	t4,224(sp)
    80005afc:	7f2e                	ld	t5,232(sp)
    80005afe:	7fce                	ld	t6,240(sp)
    80005b00:	6111                	addi	sp,sp,256
    80005b02:	10200073          	sret
    80005b06:	00000013          	nop
    80005b0a:	00000013          	nop
    80005b0e:	0001                	nop

0000000080005b10 <timervec>:
    80005b10:	34051573          	csrrw	a0,mscratch,a0
    80005b14:	e10c                	sd	a1,0(a0)
    80005b16:	e510                	sd	a2,8(a0)
    80005b18:	e914                	sd	a3,16(a0)
    80005b1a:	6d0c                	ld	a1,24(a0)
    80005b1c:	7110                	ld	a2,32(a0)
    80005b1e:	6194                	ld	a3,0(a1)
    80005b20:	96b2                	add	a3,a3,a2
    80005b22:	e194                	sd	a3,0(a1)
    80005b24:	4589                	li	a1,2
    80005b26:	14459073          	csrw	sip,a1
    80005b2a:	6914                	ld	a3,16(a0)
    80005b2c:	6510                	ld	a2,8(a0)
    80005b2e:	610c                	ld	a1,0(a0)
    80005b30:	34051573          	csrrw	a0,mscratch,a0
    80005b34:	30200073          	mret
	...

0000000080005b3a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005b3a:	1141                	addi	sp,sp,-16
    80005b3c:	e422                	sd	s0,8(sp)
    80005b3e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005b40:	0c0007b7          	lui	a5,0xc000
    80005b44:	4705                	li	a4,1
    80005b46:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005b48:	c3d8                	sw	a4,4(a5)
}
    80005b4a:	6422                	ld	s0,8(sp)
    80005b4c:	0141                	addi	sp,sp,16
    80005b4e:	8082                	ret

0000000080005b50 <plicinithart>:

void
plicinithart(void)
{
    80005b50:	1141                	addi	sp,sp,-16
    80005b52:	e406                	sd	ra,8(sp)
    80005b54:	e022                	sd	s0,0(sp)
    80005b56:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005b58:	ffffc097          	auipc	ra,0xffffc
    80005b5c:	e2c080e7          	jalr	-468(ra) # 80001984 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005b60:	0085171b          	slliw	a4,a0,0x8
    80005b64:	0c0027b7          	lui	a5,0xc002
    80005b68:	97ba                	add	a5,a5,a4
    80005b6a:	40200713          	li	a4,1026
    80005b6e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005b72:	00d5151b          	slliw	a0,a0,0xd
    80005b76:	0c2017b7          	lui	a5,0xc201
    80005b7a:	953e                	add	a0,a0,a5
    80005b7c:	00052023          	sw	zero,0(a0)
}
    80005b80:	60a2                	ld	ra,8(sp)
    80005b82:	6402                	ld	s0,0(sp)
    80005b84:	0141                	addi	sp,sp,16
    80005b86:	8082                	ret

0000000080005b88 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005b88:	1141                	addi	sp,sp,-16
    80005b8a:	e406                	sd	ra,8(sp)
    80005b8c:	e022                	sd	s0,0(sp)
    80005b8e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005b90:	ffffc097          	auipc	ra,0xffffc
    80005b94:	df4080e7          	jalr	-524(ra) # 80001984 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005b98:	00d5179b          	slliw	a5,a0,0xd
    80005b9c:	0c201537          	lui	a0,0xc201
    80005ba0:	953e                	add	a0,a0,a5
  return irq;
}
    80005ba2:	4148                	lw	a0,4(a0)
    80005ba4:	60a2                	ld	ra,8(sp)
    80005ba6:	6402                	ld	s0,0(sp)
    80005ba8:	0141                	addi	sp,sp,16
    80005baa:	8082                	ret

0000000080005bac <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005bac:	1101                	addi	sp,sp,-32
    80005bae:	ec06                	sd	ra,24(sp)
    80005bb0:	e822                	sd	s0,16(sp)
    80005bb2:	e426                	sd	s1,8(sp)
    80005bb4:	1000                	addi	s0,sp,32
    80005bb6:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005bb8:	ffffc097          	auipc	ra,0xffffc
    80005bbc:	dcc080e7          	jalr	-564(ra) # 80001984 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005bc0:	00d5151b          	slliw	a0,a0,0xd
    80005bc4:	0c2017b7          	lui	a5,0xc201
    80005bc8:	97aa                	add	a5,a5,a0
    80005bca:	c3c4                	sw	s1,4(a5)
}
    80005bcc:	60e2                	ld	ra,24(sp)
    80005bce:	6442                	ld	s0,16(sp)
    80005bd0:	64a2                	ld	s1,8(sp)
    80005bd2:	6105                	addi	sp,sp,32
    80005bd4:	8082                	ret

0000000080005bd6 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005bd6:	1141                	addi	sp,sp,-16
    80005bd8:	e406                	sd	ra,8(sp)
    80005bda:	e022                	sd	s0,0(sp)
    80005bdc:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005bde:	479d                	li	a5,7
    80005be0:	06a7c963          	blt	a5,a0,80005c52 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    80005be4:	0001d797          	auipc	a5,0x1d
    80005be8:	41c78793          	addi	a5,a5,1052 # 80023000 <disk>
    80005bec:	00a78733          	add	a4,a5,a0
    80005bf0:	6789                	lui	a5,0x2
    80005bf2:	97ba                	add	a5,a5,a4
    80005bf4:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80005bf8:	e7ad                	bnez	a5,80005c62 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80005bfa:	00451793          	slli	a5,a0,0x4
    80005bfe:	0001f717          	auipc	a4,0x1f
    80005c02:	40270713          	addi	a4,a4,1026 # 80025000 <disk+0x2000>
    80005c06:	6314                	ld	a3,0(a4)
    80005c08:	96be                	add	a3,a3,a5
    80005c0a:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    80005c0e:	6314                	ld	a3,0(a4)
    80005c10:	96be                	add	a3,a3,a5
    80005c12:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80005c16:	6314                	ld	a3,0(a4)
    80005c18:	96be                	add	a3,a3,a5
    80005c1a:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    80005c1e:	6318                	ld	a4,0(a4)
    80005c20:	97ba                	add	a5,a5,a4
    80005c22:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80005c26:	0001d797          	auipc	a5,0x1d
    80005c2a:	3da78793          	addi	a5,a5,986 # 80023000 <disk>
    80005c2e:	97aa                	add	a5,a5,a0
    80005c30:	6509                	lui	a0,0x2
    80005c32:	953e                	add	a0,a0,a5
    80005c34:	4785                	li	a5,1
    80005c36:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    80005c3a:	0001f517          	auipc	a0,0x1f
    80005c3e:	3de50513          	addi	a0,a0,990 # 80025018 <disk+0x2018>
    80005c42:	ffffc097          	auipc	ra,0xffffc
    80005c46:	5a8080e7          	jalr	1448(ra) # 800021ea <wakeup>
}
    80005c4a:	60a2                	ld	ra,8(sp)
    80005c4c:	6402                	ld	s0,0(sp)
    80005c4e:	0141                	addi	sp,sp,16
    80005c50:	8082                	ret
    panic("free_desc 1");
    80005c52:	00003517          	auipc	a0,0x3
    80005c56:	b1650513          	addi	a0,a0,-1258 # 80008768 <syscalls+0x320>
    80005c5a:	ffffb097          	auipc	ra,0xffffb
    80005c5e:	8e4080e7          	jalr	-1820(ra) # 8000053e <panic>
    panic("free_desc 2");
    80005c62:	00003517          	auipc	a0,0x3
    80005c66:	b1650513          	addi	a0,a0,-1258 # 80008778 <syscalls+0x330>
    80005c6a:	ffffb097          	auipc	ra,0xffffb
    80005c6e:	8d4080e7          	jalr	-1836(ra) # 8000053e <panic>

0000000080005c72 <virtio_disk_init>:
{
    80005c72:	1101                	addi	sp,sp,-32
    80005c74:	ec06                	sd	ra,24(sp)
    80005c76:	e822                	sd	s0,16(sp)
    80005c78:	e426                	sd	s1,8(sp)
    80005c7a:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005c7c:	00003597          	auipc	a1,0x3
    80005c80:	b0c58593          	addi	a1,a1,-1268 # 80008788 <syscalls+0x340>
    80005c84:	0001f517          	auipc	a0,0x1f
    80005c88:	4a450513          	addi	a0,a0,1188 # 80025128 <disk+0x2128>
    80005c8c:	ffffb097          	auipc	ra,0xffffb
    80005c90:	ec8080e7          	jalr	-312(ra) # 80000b54 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005c94:	100017b7          	lui	a5,0x10001
    80005c98:	4398                	lw	a4,0(a5)
    80005c9a:	2701                	sext.w	a4,a4
    80005c9c:	747277b7          	lui	a5,0x74727
    80005ca0:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005ca4:	0ef71163          	bne	a4,a5,80005d86 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005ca8:	100017b7          	lui	a5,0x10001
    80005cac:	43dc                	lw	a5,4(a5)
    80005cae:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005cb0:	4705                	li	a4,1
    80005cb2:	0ce79a63          	bne	a5,a4,80005d86 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005cb6:	100017b7          	lui	a5,0x10001
    80005cba:	479c                	lw	a5,8(a5)
    80005cbc:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005cbe:	4709                	li	a4,2
    80005cc0:	0ce79363          	bne	a5,a4,80005d86 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005cc4:	100017b7          	lui	a5,0x10001
    80005cc8:	47d8                	lw	a4,12(a5)
    80005cca:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005ccc:	554d47b7          	lui	a5,0x554d4
    80005cd0:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005cd4:	0af71963          	bne	a4,a5,80005d86 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005cd8:	100017b7          	lui	a5,0x10001
    80005cdc:	4705                	li	a4,1
    80005cde:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005ce0:	470d                	li	a4,3
    80005ce2:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80005ce4:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80005ce6:	c7ffe737          	lui	a4,0xc7ffe
    80005cea:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd875f>
    80005cee:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80005cf0:	2701                	sext.w	a4,a4
    80005cf2:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005cf4:	472d                	li	a4,11
    80005cf6:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005cf8:	473d                	li	a4,15
    80005cfa:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    80005cfc:	6705                	lui	a4,0x1
    80005cfe:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80005d00:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80005d04:	5bdc                	lw	a5,52(a5)
    80005d06:	2781                	sext.w	a5,a5
  if(max == 0)
    80005d08:	c7d9                	beqz	a5,80005d96 <virtio_disk_init+0x124>
  if(max < NUM)
    80005d0a:	471d                	li	a4,7
    80005d0c:	08f77d63          	bgeu	a4,a5,80005da6 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80005d10:	100014b7          	lui	s1,0x10001
    80005d14:	47a1                	li	a5,8
    80005d16:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80005d18:	6609                	lui	a2,0x2
    80005d1a:	4581                	li	a1,0
    80005d1c:	0001d517          	auipc	a0,0x1d
    80005d20:	2e450513          	addi	a0,a0,740 # 80023000 <disk>
    80005d24:	ffffb097          	auipc	ra,0xffffb
    80005d28:	fbc080e7          	jalr	-68(ra) # 80000ce0 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    80005d2c:	0001d717          	auipc	a4,0x1d
    80005d30:	2d470713          	addi	a4,a4,724 # 80023000 <disk>
    80005d34:	00c75793          	srli	a5,a4,0xc
    80005d38:	2781                	sext.w	a5,a5
    80005d3a:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    80005d3c:	0001f797          	auipc	a5,0x1f
    80005d40:	2c478793          	addi	a5,a5,708 # 80025000 <disk+0x2000>
    80005d44:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    80005d46:	0001d717          	auipc	a4,0x1d
    80005d4a:	33a70713          	addi	a4,a4,826 # 80023080 <disk+0x80>
    80005d4e:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    80005d50:	0001e717          	auipc	a4,0x1e
    80005d54:	2b070713          	addi	a4,a4,688 # 80024000 <disk+0x1000>
    80005d58:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    80005d5a:	4705                	li	a4,1
    80005d5c:	00e78c23          	sb	a4,24(a5)
    80005d60:	00e78ca3          	sb	a4,25(a5)
    80005d64:	00e78d23          	sb	a4,26(a5)
    80005d68:	00e78da3          	sb	a4,27(a5)
    80005d6c:	00e78e23          	sb	a4,28(a5)
    80005d70:	00e78ea3          	sb	a4,29(a5)
    80005d74:	00e78f23          	sb	a4,30(a5)
    80005d78:	00e78fa3          	sb	a4,31(a5)
}
    80005d7c:	60e2                	ld	ra,24(sp)
    80005d7e:	6442                	ld	s0,16(sp)
    80005d80:	64a2                	ld	s1,8(sp)
    80005d82:	6105                	addi	sp,sp,32
    80005d84:	8082                	ret
    panic("could not find virtio disk");
    80005d86:	00003517          	auipc	a0,0x3
    80005d8a:	a1250513          	addi	a0,a0,-1518 # 80008798 <syscalls+0x350>
    80005d8e:	ffffa097          	auipc	ra,0xffffa
    80005d92:	7b0080e7          	jalr	1968(ra) # 8000053e <panic>
    panic("virtio disk has no queue 0");
    80005d96:	00003517          	auipc	a0,0x3
    80005d9a:	a2250513          	addi	a0,a0,-1502 # 800087b8 <syscalls+0x370>
    80005d9e:	ffffa097          	auipc	ra,0xffffa
    80005da2:	7a0080e7          	jalr	1952(ra) # 8000053e <panic>
    panic("virtio disk max queue too short");
    80005da6:	00003517          	auipc	a0,0x3
    80005daa:	a3250513          	addi	a0,a0,-1486 # 800087d8 <syscalls+0x390>
    80005dae:	ffffa097          	auipc	ra,0xffffa
    80005db2:	790080e7          	jalr	1936(ra) # 8000053e <panic>

0000000080005db6 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80005db6:	7159                	addi	sp,sp,-112
    80005db8:	f486                	sd	ra,104(sp)
    80005dba:	f0a2                	sd	s0,96(sp)
    80005dbc:	eca6                	sd	s1,88(sp)
    80005dbe:	e8ca                	sd	s2,80(sp)
    80005dc0:	e4ce                	sd	s3,72(sp)
    80005dc2:	e0d2                	sd	s4,64(sp)
    80005dc4:	fc56                	sd	s5,56(sp)
    80005dc6:	f85a                	sd	s6,48(sp)
    80005dc8:	f45e                	sd	s7,40(sp)
    80005dca:	f062                	sd	s8,32(sp)
    80005dcc:	ec66                	sd	s9,24(sp)
    80005dce:	e86a                	sd	s10,16(sp)
    80005dd0:	1880                	addi	s0,sp,112
    80005dd2:	892a                	mv	s2,a0
    80005dd4:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80005dd6:	00c52c83          	lw	s9,12(a0)
    80005dda:	001c9c9b          	slliw	s9,s9,0x1
    80005dde:	1c82                	slli	s9,s9,0x20
    80005de0:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80005de4:	0001f517          	auipc	a0,0x1f
    80005de8:	34450513          	addi	a0,a0,836 # 80025128 <disk+0x2128>
    80005dec:	ffffb097          	auipc	ra,0xffffb
    80005df0:	df8080e7          	jalr	-520(ra) # 80000be4 <acquire>
  for(int i = 0; i < 3; i++){
    80005df4:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80005df6:	4c21                	li	s8,8
      disk.free[i] = 0;
    80005df8:	0001db97          	auipc	s7,0x1d
    80005dfc:	208b8b93          	addi	s7,s7,520 # 80023000 <disk>
    80005e00:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    80005e02:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    80005e04:	8a4e                	mv	s4,s3
    80005e06:	a051                	j	80005e8a <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    80005e08:	00fb86b3          	add	a3,s7,a5
    80005e0c:	96da                	add	a3,a3,s6
    80005e0e:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    80005e12:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    80005e14:	0207c563          	bltz	a5,80005e3e <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80005e18:	2485                	addiw	s1,s1,1
    80005e1a:	0711                	addi	a4,a4,4
    80005e1c:	25548063          	beq	s1,s5,8000605c <virtio_disk_rw+0x2a6>
    idx[i] = alloc_desc();
    80005e20:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    80005e22:	0001f697          	auipc	a3,0x1f
    80005e26:	1f668693          	addi	a3,a3,502 # 80025018 <disk+0x2018>
    80005e2a:	87d2                	mv	a5,s4
    if(disk.free[i]){
    80005e2c:	0006c583          	lbu	a1,0(a3)
    80005e30:	fde1                	bnez	a1,80005e08 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80005e32:	2785                	addiw	a5,a5,1
    80005e34:	0685                	addi	a3,a3,1
    80005e36:	ff879be3          	bne	a5,s8,80005e2c <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    80005e3a:	57fd                	li	a5,-1
    80005e3c:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    80005e3e:	02905a63          	blez	s1,80005e72 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80005e42:	f9042503          	lw	a0,-112(s0)
    80005e46:	00000097          	auipc	ra,0x0
    80005e4a:	d90080e7          	jalr	-624(ra) # 80005bd6 <free_desc>
      for(int j = 0; j < i; j++)
    80005e4e:	4785                	li	a5,1
    80005e50:	0297d163          	bge	a5,s1,80005e72 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80005e54:	f9442503          	lw	a0,-108(s0)
    80005e58:	00000097          	auipc	ra,0x0
    80005e5c:	d7e080e7          	jalr	-642(ra) # 80005bd6 <free_desc>
      for(int j = 0; j < i; j++)
    80005e60:	4789                	li	a5,2
    80005e62:	0097d863          	bge	a5,s1,80005e72 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80005e66:	f9842503          	lw	a0,-104(s0)
    80005e6a:	00000097          	auipc	ra,0x0
    80005e6e:	d6c080e7          	jalr	-660(ra) # 80005bd6 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80005e72:	0001f597          	auipc	a1,0x1f
    80005e76:	2b658593          	addi	a1,a1,694 # 80025128 <disk+0x2128>
    80005e7a:	0001f517          	auipc	a0,0x1f
    80005e7e:	19e50513          	addi	a0,a0,414 # 80025018 <disk+0x2018>
    80005e82:	ffffc097          	auipc	ra,0xffffc
    80005e86:	1dc080e7          	jalr	476(ra) # 8000205e <sleep>
  for(int i = 0; i < 3; i++){
    80005e8a:	f9040713          	addi	a4,s0,-112
    80005e8e:	84ce                	mv	s1,s3
    80005e90:	bf41                	j	80005e20 <virtio_disk_rw+0x6a>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    80005e92:	20058713          	addi	a4,a1,512
    80005e96:	00471693          	slli	a3,a4,0x4
    80005e9a:	0001d717          	auipc	a4,0x1d
    80005e9e:	16670713          	addi	a4,a4,358 # 80023000 <disk>
    80005ea2:	9736                	add	a4,a4,a3
    80005ea4:	4685                	li	a3,1
    80005ea6:	0ad72423          	sw	a3,168(a4)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    80005eaa:	20058713          	addi	a4,a1,512
    80005eae:	00471693          	slli	a3,a4,0x4
    80005eb2:	0001d717          	auipc	a4,0x1d
    80005eb6:	14e70713          	addi	a4,a4,334 # 80023000 <disk>
    80005eba:	9736                	add	a4,a4,a3
    80005ebc:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    80005ec0:	0b973823          	sd	s9,176(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80005ec4:	7679                	lui	a2,0xffffe
    80005ec6:	963e                	add	a2,a2,a5
    80005ec8:	0001f697          	auipc	a3,0x1f
    80005ecc:	13868693          	addi	a3,a3,312 # 80025000 <disk+0x2000>
    80005ed0:	6298                	ld	a4,0(a3)
    80005ed2:	9732                	add	a4,a4,a2
    80005ed4:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80005ed6:	6298                	ld	a4,0(a3)
    80005ed8:	9732                	add	a4,a4,a2
    80005eda:	4541                	li	a0,16
    80005edc:	c708                	sw	a0,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80005ede:	6298                	ld	a4,0(a3)
    80005ee0:	9732                	add	a4,a4,a2
    80005ee2:	4505                	li	a0,1
    80005ee4:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[0]].next = idx[1];
    80005ee8:	f9442703          	lw	a4,-108(s0)
    80005eec:	6288                	ld	a0,0(a3)
    80005eee:	962a                	add	a2,a2,a0
    80005ef0:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd800e>

  disk.desc[idx[1]].addr = (uint64) b->data;
    80005ef4:	0712                	slli	a4,a4,0x4
    80005ef6:	6290                	ld	a2,0(a3)
    80005ef8:	963a                	add	a2,a2,a4
    80005efa:	05890513          	addi	a0,s2,88
    80005efe:	e208                	sd	a0,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    80005f00:	6294                	ld	a3,0(a3)
    80005f02:	96ba                	add	a3,a3,a4
    80005f04:	40000613          	li	a2,1024
    80005f08:	c690                	sw	a2,8(a3)
  if(write)
    80005f0a:	140d0063          	beqz	s10,8000604a <virtio_disk_rw+0x294>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    80005f0e:	0001f697          	auipc	a3,0x1f
    80005f12:	0f26b683          	ld	a3,242(a3) # 80025000 <disk+0x2000>
    80005f16:	96ba                	add	a3,a3,a4
    80005f18:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    80005f1c:	0001d817          	auipc	a6,0x1d
    80005f20:	0e480813          	addi	a6,a6,228 # 80023000 <disk>
    80005f24:	0001f517          	auipc	a0,0x1f
    80005f28:	0dc50513          	addi	a0,a0,220 # 80025000 <disk+0x2000>
    80005f2c:	6114                	ld	a3,0(a0)
    80005f2e:	96ba                	add	a3,a3,a4
    80005f30:	00c6d603          	lhu	a2,12(a3)
    80005f34:	00166613          	ori	a2,a2,1
    80005f38:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    80005f3c:	f9842683          	lw	a3,-104(s0)
    80005f40:	6110                	ld	a2,0(a0)
    80005f42:	9732                	add	a4,a4,a2
    80005f44:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80005f48:	20058613          	addi	a2,a1,512
    80005f4c:	0612                	slli	a2,a2,0x4
    80005f4e:	9642                	add	a2,a2,a6
    80005f50:	577d                	li	a4,-1
    80005f52:	02e60823          	sb	a4,48(a2)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80005f56:	00469713          	slli	a4,a3,0x4
    80005f5a:	6114                	ld	a3,0(a0)
    80005f5c:	96ba                	add	a3,a3,a4
    80005f5e:	03078793          	addi	a5,a5,48
    80005f62:	97c2                	add	a5,a5,a6
    80005f64:	e29c                	sd	a5,0(a3)
  disk.desc[idx[2]].len = 1;
    80005f66:	611c                	ld	a5,0(a0)
    80005f68:	97ba                	add	a5,a5,a4
    80005f6a:	4685                	li	a3,1
    80005f6c:	c794                	sw	a3,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80005f6e:	611c                	ld	a5,0(a0)
    80005f70:	97ba                	add	a5,a5,a4
    80005f72:	4809                	li	a6,2
    80005f74:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    80005f78:	611c                	ld	a5,0(a0)
    80005f7a:	973e                	add	a4,a4,a5
    80005f7c:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80005f80:	00d92223          	sw	a3,4(s2)
  disk.info[idx[0]].b = b;
    80005f84:	03263423          	sd	s2,40(a2)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80005f88:	6518                	ld	a4,8(a0)
    80005f8a:	00275783          	lhu	a5,2(a4)
    80005f8e:	8b9d                	andi	a5,a5,7
    80005f90:	0786                	slli	a5,a5,0x1
    80005f92:	97ba                	add	a5,a5,a4
    80005f94:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    80005f98:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80005f9c:	6518                	ld	a4,8(a0)
    80005f9e:	00275783          	lhu	a5,2(a4)
    80005fa2:	2785                	addiw	a5,a5,1
    80005fa4:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80005fa8:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80005fac:	100017b7          	lui	a5,0x10001
    80005fb0:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80005fb4:	00492703          	lw	a4,4(s2)
    80005fb8:	4785                	li	a5,1
    80005fba:	02f71163          	bne	a4,a5,80005fdc <virtio_disk_rw+0x226>
    sleep(b, &disk.vdisk_lock);
    80005fbe:	0001f997          	auipc	s3,0x1f
    80005fc2:	16a98993          	addi	s3,s3,362 # 80025128 <disk+0x2128>
  while(b->disk == 1) {
    80005fc6:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80005fc8:	85ce                	mv	a1,s3
    80005fca:	854a                	mv	a0,s2
    80005fcc:	ffffc097          	auipc	ra,0xffffc
    80005fd0:	092080e7          	jalr	146(ra) # 8000205e <sleep>
  while(b->disk == 1) {
    80005fd4:	00492783          	lw	a5,4(s2)
    80005fd8:	fe9788e3          	beq	a5,s1,80005fc8 <virtio_disk_rw+0x212>
  }

  disk.info[idx[0]].b = 0;
    80005fdc:	f9042903          	lw	s2,-112(s0)
    80005fe0:	20090793          	addi	a5,s2,512
    80005fe4:	00479713          	slli	a4,a5,0x4
    80005fe8:	0001d797          	auipc	a5,0x1d
    80005fec:	01878793          	addi	a5,a5,24 # 80023000 <disk>
    80005ff0:	97ba                	add	a5,a5,a4
    80005ff2:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    80005ff6:	0001f997          	auipc	s3,0x1f
    80005ffa:	00a98993          	addi	s3,s3,10 # 80025000 <disk+0x2000>
    80005ffe:	00491713          	slli	a4,s2,0x4
    80006002:	0009b783          	ld	a5,0(s3)
    80006006:	97ba                	add	a5,a5,a4
    80006008:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    8000600c:	854a                	mv	a0,s2
    8000600e:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80006012:	00000097          	auipc	ra,0x0
    80006016:	bc4080e7          	jalr	-1084(ra) # 80005bd6 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    8000601a:	8885                	andi	s1,s1,1
    8000601c:	f0ed                	bnez	s1,80005ffe <virtio_disk_rw+0x248>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    8000601e:	0001f517          	auipc	a0,0x1f
    80006022:	10a50513          	addi	a0,a0,266 # 80025128 <disk+0x2128>
    80006026:	ffffb097          	auipc	ra,0xffffb
    8000602a:	c72080e7          	jalr	-910(ra) # 80000c98 <release>
}
    8000602e:	70a6                	ld	ra,104(sp)
    80006030:	7406                	ld	s0,96(sp)
    80006032:	64e6                	ld	s1,88(sp)
    80006034:	6946                	ld	s2,80(sp)
    80006036:	69a6                	ld	s3,72(sp)
    80006038:	6a06                	ld	s4,64(sp)
    8000603a:	7ae2                	ld	s5,56(sp)
    8000603c:	7b42                	ld	s6,48(sp)
    8000603e:	7ba2                	ld	s7,40(sp)
    80006040:	7c02                	ld	s8,32(sp)
    80006042:	6ce2                	ld	s9,24(sp)
    80006044:	6d42                	ld	s10,16(sp)
    80006046:	6165                	addi	sp,sp,112
    80006048:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    8000604a:	0001f697          	auipc	a3,0x1f
    8000604e:	fb66b683          	ld	a3,-74(a3) # 80025000 <disk+0x2000>
    80006052:	96ba                	add	a3,a3,a4
    80006054:	4609                	li	a2,2
    80006056:	00c69623          	sh	a2,12(a3)
    8000605a:	b5c9                	j	80005f1c <virtio_disk_rw+0x166>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    8000605c:	f9042583          	lw	a1,-112(s0)
    80006060:	20058793          	addi	a5,a1,512
    80006064:	0792                	slli	a5,a5,0x4
    80006066:	0001d517          	auipc	a0,0x1d
    8000606a:	04250513          	addi	a0,a0,66 # 800230a8 <disk+0xa8>
    8000606e:	953e                	add	a0,a0,a5
  if(write)
    80006070:	e20d11e3          	bnez	s10,80005e92 <virtio_disk_rw+0xdc>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    80006074:	20058713          	addi	a4,a1,512
    80006078:	00471693          	slli	a3,a4,0x4
    8000607c:	0001d717          	auipc	a4,0x1d
    80006080:	f8470713          	addi	a4,a4,-124 # 80023000 <disk>
    80006084:	9736                	add	a4,a4,a3
    80006086:	0a072423          	sw	zero,168(a4)
    8000608a:	b505                	j	80005eaa <virtio_disk_rw+0xf4>

000000008000608c <virtio_disk_intr>:

void
virtio_disk_intr()
{
    8000608c:	1101                	addi	sp,sp,-32
    8000608e:	ec06                	sd	ra,24(sp)
    80006090:	e822                	sd	s0,16(sp)
    80006092:	e426                	sd	s1,8(sp)
    80006094:	e04a                	sd	s2,0(sp)
    80006096:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006098:	0001f517          	auipc	a0,0x1f
    8000609c:	09050513          	addi	a0,a0,144 # 80025128 <disk+0x2128>
    800060a0:	ffffb097          	auipc	ra,0xffffb
    800060a4:	b44080e7          	jalr	-1212(ra) # 80000be4 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    800060a8:	10001737          	lui	a4,0x10001
    800060ac:	533c                	lw	a5,96(a4)
    800060ae:	8b8d                	andi	a5,a5,3
    800060b0:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    800060b2:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    800060b6:	0001f797          	auipc	a5,0x1f
    800060ba:	f4a78793          	addi	a5,a5,-182 # 80025000 <disk+0x2000>
    800060be:	6b94                	ld	a3,16(a5)
    800060c0:	0207d703          	lhu	a4,32(a5)
    800060c4:	0026d783          	lhu	a5,2(a3)
    800060c8:	06f70163          	beq	a4,a5,8000612a <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800060cc:	0001d917          	auipc	s2,0x1d
    800060d0:	f3490913          	addi	s2,s2,-204 # 80023000 <disk>
    800060d4:	0001f497          	auipc	s1,0x1f
    800060d8:	f2c48493          	addi	s1,s1,-212 # 80025000 <disk+0x2000>
    __sync_synchronize();
    800060dc:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800060e0:	6898                	ld	a4,16(s1)
    800060e2:	0204d783          	lhu	a5,32(s1)
    800060e6:	8b9d                	andi	a5,a5,7
    800060e8:	078e                	slli	a5,a5,0x3
    800060ea:	97ba                	add	a5,a5,a4
    800060ec:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    800060ee:	20078713          	addi	a4,a5,512
    800060f2:	0712                	slli	a4,a4,0x4
    800060f4:	974a                	add	a4,a4,s2
    800060f6:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    800060fa:	e731                	bnez	a4,80006146 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    800060fc:	20078793          	addi	a5,a5,512
    80006100:	0792                	slli	a5,a5,0x4
    80006102:	97ca                	add	a5,a5,s2
    80006104:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    80006106:	00052223          	sw	zero,4(a0)
    wakeup(b);
    8000610a:	ffffc097          	auipc	ra,0xffffc
    8000610e:	0e0080e7          	jalr	224(ra) # 800021ea <wakeup>

    disk.used_idx += 1;
    80006112:	0204d783          	lhu	a5,32(s1)
    80006116:	2785                	addiw	a5,a5,1
    80006118:	17c2                	slli	a5,a5,0x30
    8000611a:	93c1                	srli	a5,a5,0x30
    8000611c:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006120:	6898                	ld	a4,16(s1)
    80006122:	00275703          	lhu	a4,2(a4)
    80006126:	faf71be3          	bne	a4,a5,800060dc <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    8000612a:	0001f517          	auipc	a0,0x1f
    8000612e:	ffe50513          	addi	a0,a0,-2 # 80025128 <disk+0x2128>
    80006132:	ffffb097          	auipc	ra,0xffffb
    80006136:	b66080e7          	jalr	-1178(ra) # 80000c98 <release>
}
    8000613a:	60e2                	ld	ra,24(sp)
    8000613c:	6442                	ld	s0,16(sp)
    8000613e:	64a2                	ld	s1,8(sp)
    80006140:	6902                	ld	s2,0(sp)
    80006142:	6105                	addi	sp,sp,32
    80006144:	8082                	ret
      panic("virtio_disk_intr status");
    80006146:	00002517          	auipc	a0,0x2
    8000614a:	6b250513          	addi	a0,a0,1714 # 800087f8 <syscalls+0x3b0>
    8000614e:	ffffa097          	auipc	ra,0xffffa
    80006152:	3f0080e7          	jalr	1008(ra) # 8000053e <panic>

0000000080006156 <cas>:
    80006156:	100522af          	lr.w	t0,(a0)
    8000615a:	00b29563          	bne	t0,a1,80006164 <fail>
    8000615e:	18c5252f          	sc.w	a0,a2,(a0)
    80006162:	8082                	ret

0000000080006164 <fail>:
    80006164:	4505                	li	a0,1
    80006166:	8082                	ret
	...

0000000080007000 <_trampoline>:
    80007000:	14051573          	csrrw	a0,sscratch,a0
    80007004:	02153423          	sd	ra,40(a0)
    80007008:	02253823          	sd	sp,48(a0)
    8000700c:	02353c23          	sd	gp,56(a0)
    80007010:	04453023          	sd	tp,64(a0)
    80007014:	04553423          	sd	t0,72(a0)
    80007018:	04653823          	sd	t1,80(a0)
    8000701c:	04753c23          	sd	t2,88(a0)
    80007020:	f120                	sd	s0,96(a0)
    80007022:	f524                	sd	s1,104(a0)
    80007024:	fd2c                	sd	a1,120(a0)
    80007026:	e150                	sd	a2,128(a0)
    80007028:	e554                	sd	a3,136(a0)
    8000702a:	e958                	sd	a4,144(a0)
    8000702c:	ed5c                	sd	a5,152(a0)
    8000702e:	0b053023          	sd	a6,160(a0)
    80007032:	0b153423          	sd	a7,168(a0)
    80007036:	0b253823          	sd	s2,176(a0)
    8000703a:	0b353c23          	sd	s3,184(a0)
    8000703e:	0d453023          	sd	s4,192(a0)
    80007042:	0d553423          	sd	s5,200(a0)
    80007046:	0d653823          	sd	s6,208(a0)
    8000704a:	0d753c23          	sd	s7,216(a0)
    8000704e:	0f853023          	sd	s8,224(a0)
    80007052:	0f953423          	sd	s9,232(a0)
    80007056:	0fa53823          	sd	s10,240(a0)
    8000705a:	0fb53c23          	sd	s11,248(a0)
    8000705e:	11c53023          	sd	t3,256(a0)
    80007062:	11d53423          	sd	t4,264(a0)
    80007066:	11e53823          	sd	t5,272(a0)
    8000706a:	11f53c23          	sd	t6,280(a0)
    8000706e:	140022f3          	csrr	t0,sscratch
    80007072:	06553823          	sd	t0,112(a0)
    80007076:	00853103          	ld	sp,8(a0)
    8000707a:	02053203          	ld	tp,32(a0)
    8000707e:	01053283          	ld	t0,16(a0)
    80007082:	00053303          	ld	t1,0(a0)
    80007086:	18031073          	csrw	satp,t1
    8000708a:	12000073          	sfence.vma
    8000708e:	8282                	jr	t0

0000000080007090 <userret>:
    80007090:	18059073          	csrw	satp,a1
    80007094:	12000073          	sfence.vma
    80007098:	07053283          	ld	t0,112(a0)
    8000709c:	14029073          	csrw	sscratch,t0
    800070a0:	02853083          	ld	ra,40(a0)
    800070a4:	03053103          	ld	sp,48(a0)
    800070a8:	03853183          	ld	gp,56(a0)
    800070ac:	04053203          	ld	tp,64(a0)
    800070b0:	04853283          	ld	t0,72(a0)
    800070b4:	05053303          	ld	t1,80(a0)
    800070b8:	05853383          	ld	t2,88(a0)
    800070bc:	7120                	ld	s0,96(a0)
    800070be:	7524                	ld	s1,104(a0)
    800070c0:	7d2c                	ld	a1,120(a0)
    800070c2:	6150                	ld	a2,128(a0)
    800070c4:	6554                	ld	a3,136(a0)
    800070c6:	6958                	ld	a4,144(a0)
    800070c8:	6d5c                	ld	a5,152(a0)
    800070ca:	0a053803          	ld	a6,160(a0)
    800070ce:	0a853883          	ld	a7,168(a0)
    800070d2:	0b053903          	ld	s2,176(a0)
    800070d6:	0b853983          	ld	s3,184(a0)
    800070da:	0c053a03          	ld	s4,192(a0)
    800070de:	0c853a83          	ld	s5,200(a0)
    800070e2:	0d053b03          	ld	s6,208(a0)
    800070e6:	0d853b83          	ld	s7,216(a0)
    800070ea:	0e053c03          	ld	s8,224(a0)
    800070ee:	0e853c83          	ld	s9,232(a0)
    800070f2:	0f053d03          	ld	s10,240(a0)
    800070f6:	0f853d83          	ld	s11,248(a0)
    800070fa:	10053e03          	ld	t3,256(a0)
    800070fe:	10853e83          	ld	t4,264(a0)
    80007102:	11053f03          	ld	t5,272(a0)
    80007106:	11853f83          	ld	t6,280(a0)
    8000710a:	14051573          	csrrw	a0,sscratch,a0
    8000710e:	10200073          	sret
	...

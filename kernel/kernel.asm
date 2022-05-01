
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	89013103          	ld	sp,-1904(sp) # 80008890 <_GLOBAL_OFFSET_TABLE_+0x8>
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
    80000068:	c3c78793          	addi	a5,a5,-964 # 80005ca0 <timervec>
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
    80000130:	432080e7          	jalr	1074(ra) # 8000255e <either_copyin>
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
    800001c4:	00002097          	auipc	ra,0x2
    800001c8:	8ee080e7          	jalr	-1810(ra) # 80001ab2 <myproc>
    800001cc:	551c                	lw	a5,40(a0)
    800001ce:	e7b5                	bnez	a5,8000023a <consoleread+0xd6>
      sleep(&cons.r, &cons.lock);
    800001d0:	85ce                	mv	a1,s3
    800001d2:	854a                	mv	a0,s2
    800001d4:	00002097          	auipc	ra,0x2
    800001d8:	f90080e7          	jalr	-112(ra) # 80002164 <sleep>
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
    80000214:	2f8080e7          	jalr	760(ra) # 80002508 <either_copyout>
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
    800002f6:	2c2080e7          	jalr	706(ra) # 800025b4 <procdump>
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
    8000044a:	eaa080e7          	jalr	-342(ra) # 800022f0 <wakeup>
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
    8000047c:	0c078793          	addi	a5,a5,192 # 80021538 <devsw>
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
    800008a4:	a50080e7          	jalr	-1456(ra) # 800022f0 <wakeup>
    
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
    8000092c:	00002097          	auipc	ra,0x2
    80000930:	838080e7          	jalr	-1992(ra) # 80002164 <sleep>
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
    80000b82:	f18080e7          	jalr	-232(ra) # 80001a96 <mycpu>
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
    80000bb4:	ee6080e7          	jalr	-282(ra) # 80001a96 <mycpu>
    80000bb8:	5d3c                	lw	a5,120(a0)
    80000bba:	cf89                	beqz	a5,80000bd4 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bbc:	00001097          	auipc	ra,0x1
    80000bc0:	eda080e7          	jalr	-294(ra) # 80001a96 <mycpu>
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
    80000bd8:	ec2080e7          	jalr	-318(ra) # 80001a96 <mycpu>
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
    80000c18:	e82080e7          	jalr	-382(ra) # 80001a96 <mycpu>
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
    80000c44:	e56080e7          	jalr	-426(ra) # 80001a96 <mycpu>
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
    80000e9a:	bf0080e7          	jalr	-1040(ra) # 80001a86 <cpuid>
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
    80000eb6:	bd4080e7          	jalr	-1068(ra) # 80001a86 <cpuid>
    80000eba:	85aa                	mv	a1,a0
    80000ebc:	00007517          	auipc	a0,0x7
    80000ec0:	1fc50513          	addi	a0,a0,508 # 800080b8 <digits+0x78>
    80000ec4:	fffff097          	auipc	ra,0xfffff
    80000ec8:	6c4080e7          	jalr	1732(ra) # 80000588 <printf>
    kvminithart();    // turn on paging
    80000ecc:	00000097          	auipc	ra,0x0
    80000ed0:	0d8080e7          	jalr	216(ra) # 80000fa4 <kvminithart>
    trapinithart();   // install kernel trap vector
    80000ed4:	00002097          	auipc	ra,0x2
    80000ed8:	864080e7          	jalr	-1948(ra) # 80002738 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000edc:	00005097          	auipc	ra,0x5
    80000ee0:	e04080e7          	jalr	-508(ra) # 80005ce0 <plicinithart>
  }

  scheduler();        
    80000ee4:	00001097          	auipc	ra,0x1
    80000ee8:	0ce080e7          	jalr	206(ra) # 80001fb2 <scheduler>
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
    80000f48:	a92080e7          	jalr	-1390(ra) # 800019d6 <procinit>
    trapinit();      // trap vectors
    80000f4c:	00001097          	auipc	ra,0x1
    80000f50:	7c4080e7          	jalr	1988(ra) # 80002710 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f54:	00001097          	auipc	ra,0x1
    80000f58:	7e4080e7          	jalr	2020(ra) # 80002738 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f5c:	00005097          	auipc	ra,0x5
    80000f60:	d6e080e7          	jalr	-658(ra) # 80005cca <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f64:	00005097          	auipc	ra,0x5
    80000f68:	d7c080e7          	jalr	-644(ra) # 80005ce0 <plicinithart>
    binit();         // buffer cache
    80000f6c:	00002097          	auipc	ra,0x2
    80000f70:	f58080e7          	jalr	-168(ra) # 80002ec4 <binit>
    iinit();         // inode table
    80000f74:	00002097          	auipc	ra,0x2
    80000f78:	5e8080e7          	jalr	1512(ra) # 8000355c <iinit>
    fileinit();      // file table
    80000f7c:	00003097          	auipc	ra,0x3
    80000f80:	592080e7          	jalr	1426(ra) # 8000450e <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f84:	00005097          	auipc	ra,0x5
    80000f88:	e7e080e7          	jalr	-386(ra) # 80005e02 <virtio_disk_init>
    userinit();      // first user process
    80000f8c:	00001097          	auipc	ra,0x1
    80000f90:	df4080e7          	jalr	-524(ra) # 80001d80 <userinit>
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
    80001244:	700080e7          	jalr	1792(ra) # 80001940 <proc_mapstacks>
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

000000008000183e <get_last>:
int sleeping_list;
int unused_list;

struct proc proc[NPROC];

struct proc* get_last(int* head){
    8000183e:	1141                	addi	sp,sp,-16
    80001840:	e422                	sd	s0,8(sp)
    80001842:	0800                	addi	s0,sp,16
  int index;
  int curr_head = *head;
    80001844:	411c                	lw	a5,0(a0)
  struct proc* p = &proc[curr_head];
  for(index = curr_head; index != -1;){
    80001846:	577d                	li	a4,-1
    80001848:	02e78b63          	beq	a5,a4,8000187e <get_last+0x40>
    p = &proc[index];
    index = p->next;
    8000184c:	00010617          	auipc	a2,0x10
    80001850:	e8460613          	addi	a2,a2,-380 # 800116d0 <proc>
    80001854:	17000693          	li	a3,368
    80001858:	853e                	mv	a0,a5
    8000185a:	02d787b3          	mul	a5,a5,a3
    8000185e:	97b2                	add	a5,a5,a2
    80001860:	5bdc                	lw	a5,52(a5)
  for(index = curr_head; index != -1;){
    80001862:	fee79be3          	bne	a5,a4,80001858 <get_last+0x1a>
    p = &proc[index];
    80001866:	17000793          	li	a5,368
    8000186a:	02f50533          	mul	a0,a0,a5
    8000186e:	00010797          	auipc	a5,0x10
    80001872:	e6278793          	addi	a5,a5,-414 # 800116d0 <proc>
    80001876:	953e                	add	a0,a0,a5

    // in case that the head is removed while adding another process to the list!@#!@#!@#!@#!@
  }
  return p;
}
    80001878:	6422                	ld	s0,8(sp)
    8000187a:	0141                	addi	sp,sp,16
    8000187c:	8082                	ret
  struct proc* p = &proc[curr_head];
    8000187e:	00010517          	auipc	a0,0x10
    80001882:	ce250513          	addi	a0,a0,-798 # 80011560 <cpus+0x290>
  return p;
    80001886:	bfcd                	j	80001878 <get_last+0x3a>

0000000080001888 <add_proc_to_list>:

void 
add_proc_to_list(int pindex, int* head)
{
    80001888:	1101                	addi	sp,sp,-32
    8000188a:	ec06                	sd	ra,24(sp)
    8000188c:	e822                	sd	s0,16(sp)
    8000188e:	e426                	sd	s1,8(sp)
    80001890:	e04a                	sd	s2,0(sp)
    80001892:	1000                	addi	s0,sp,32
    80001894:	84ae                	mv	s1,a1
  if(pindex < 0 || pindex > NPROC){
    80001896:	892a                	mv	s2,a0
    80001898:	04000793          	li	a5,64
    8000189c:	02a7e663          	bltu	a5,a0,800018c8 <add_proc_to_list+0x40>
    panic("Add proc to list");
  }
  struct proc* currlast;
  do{
    currlast = get_last(head);
    800018a0:	8526                	mv	a0,s1
    800018a2:	00000097          	auipc	ra,0x0
    800018a6:	f9c080e7          	jalr	-100(ra) # 8000183e <get_last>
  }while(cas(&(currlast->next), -1, pindex));
    800018aa:	864a                	mv	a2,s2
    800018ac:	55fd                	li	a1,-1
    800018ae:	03450513          	addi	a0,a0,52
    800018b2:	00005097          	auipc	ra,0x5
    800018b6:	a34080e7          	jalr	-1484(ra) # 800062e6 <cas>
    800018ba:	f17d                	bnez	a0,800018a0 <add_proc_to_list+0x18>
}
    800018bc:	60e2                	ld	ra,24(sp)
    800018be:	6442                	ld	s0,16(sp)
    800018c0:	64a2                	ld	s1,8(sp)
    800018c2:	6902                	ld	s2,0(sp)
    800018c4:	6105                	addi	sp,sp,32
    800018c6:	8082                	ret
    panic("Add proc to list");
    800018c8:	00007517          	auipc	a0,0x7
    800018cc:	91050513          	addi	a0,a0,-1776 # 800081d8 <digits+0x198>
    800018d0:	fffff097          	auipc	ra,0xfffff
    800018d4:	c6e080e7          	jalr	-914(ra) # 8000053e <panic>

00000000800018d8 <remove>:

int 
remove(int* head)
{
    800018d8:	7179                	addi	sp,sp,-48
    800018da:	f406                	sd	ra,40(sp)
    800018dc:	f022                	sd	s0,32(sp)
    800018de:	ec26                	sd	s1,24(sp)
    800018e0:	e84a                	sd	s2,16(sp)
    800018e2:	e44e                	sd	s3,8(sp)
    800018e4:	e052                	sd	s4,0(sp)
    800018e6:	1800                	addi	s0,sp,48
  if(*head == -1)
    800018e8:	4104                	lw	s1,0(a0)
    800018ea:	57fd                	li	a5,-1
    800018ec:	04f48163          	beq	s1,a5,8000192e <remove+0x56>
    800018f0:	892a                	mv	s2,a0
  struct proc *p;
  int next_head;
  do{
    to_remove = *head;
    p = &proc[to_remove];
    next_head = p->next;
    800018f2:	00010a17          	auipc	s4,0x10
    800018f6:	ddea0a13          	addi	s4,s4,-546 # 800116d0 <proc>
    800018fa:	17000993          	li	s3,368
    to_remove = *head;
    800018fe:	00092483          	lw	s1,0(s2) # 1000 <_entry-0x7ffff000>
    next_head = p->next;
    80001902:	033487b3          	mul	a5,s1,s3
    80001906:	97d2                	add	a5,a5,s4
  }while (cas(head, to_remove, next_head));
    80001908:	5bd0                	lw	a2,52(a5)
    8000190a:	85a6                	mv	a1,s1
    8000190c:	854a                	mv	a0,s2
    8000190e:	00005097          	auipc	ra,0x5
    80001912:	9d8080e7          	jalr	-1576(ra) # 800062e6 <cas>
    80001916:	f565                	bnez	a0,800018fe <remove+0x26>
  p->next = -1;
    80001918:	17000793          	li	a5,368
    8000191c:	02f48733          	mul	a4,s1,a5
    80001920:	00010797          	auipc	a5,0x10
    80001924:	db078793          	addi	a5,a5,-592 # 800116d0 <proc>
    80001928:	97ba                	add	a5,a5,a4
    8000192a:	577d                	li	a4,-1
    8000192c:	dbd8                	sw	a4,52(a5)
  return to_remove;
}
    8000192e:	8526                	mv	a0,s1
    80001930:	70a2                	ld	ra,40(sp)
    80001932:	7402                	ld	s0,32(sp)
    80001934:	64e2                	ld	s1,24(sp)
    80001936:	6942                	ld	s2,16(sp)
    80001938:	69a2                	ld	s3,8(sp)
    8000193a:	6a02                	ld	s4,0(sp)
    8000193c:	6145                	addi	sp,sp,48
    8000193e:	8082                	ret

0000000080001940 <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl) {
    80001940:	7139                	addi	sp,sp,-64
    80001942:	fc06                	sd	ra,56(sp)
    80001944:	f822                	sd	s0,48(sp)
    80001946:	f426                	sd	s1,40(sp)
    80001948:	f04a                	sd	s2,32(sp)
    8000194a:	ec4e                	sd	s3,24(sp)
    8000194c:	e852                	sd	s4,16(sp)
    8000194e:	e456                	sd	s5,8(sp)
    80001950:	e05a                	sd	s6,0(sp)
    80001952:	0080                	addi	s0,sp,64
    80001954:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    80001956:	00010497          	auipc	s1,0x10
    8000195a:	d7a48493          	addi	s1,s1,-646 # 800116d0 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    8000195e:	8b26                	mv	s6,s1
    80001960:	00006a97          	auipc	s5,0x6
    80001964:	6a0a8a93          	addi	s5,s5,1696 # 80008000 <etext>
    80001968:	04000937          	lui	s2,0x4000
    8000196c:	197d                	addi	s2,s2,-1
    8000196e:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001970:	00016a17          	auipc	s4,0x16
    80001974:	960a0a13          	addi	s4,s4,-1696 # 800172d0 <ready_list>
    char *pa = kalloc();
    80001978:	fffff097          	auipc	ra,0xfffff
    8000197c:	17c080e7          	jalr	380(ra) # 80000af4 <kalloc>
    80001980:	862a                	mv	a2,a0
    if(pa == 0)
    80001982:	c131                	beqz	a0,800019c6 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    80001984:	416485b3          	sub	a1,s1,s6
    80001988:	8591                	srai	a1,a1,0x4
    8000198a:	000ab783          	ld	a5,0(s5)
    8000198e:	02f585b3          	mul	a1,a1,a5
    80001992:	2585                	addiw	a1,a1,1
    80001994:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001998:	4719                	li	a4,6
    8000199a:	6685                	lui	a3,0x1
    8000199c:	40b905b3          	sub	a1,s2,a1
    800019a0:	854e                	mv	a0,s3
    800019a2:	fffff097          	auipc	ra,0xfffff
    800019a6:	7ae080e7          	jalr	1966(ra) # 80001150 <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    800019aa:	17048493          	addi	s1,s1,368
    800019ae:	fd4495e3          	bne	s1,s4,80001978 <proc_mapstacks+0x38>
  }
}
    800019b2:	70e2                	ld	ra,56(sp)
    800019b4:	7442                	ld	s0,48(sp)
    800019b6:	74a2                	ld	s1,40(sp)
    800019b8:	7902                	ld	s2,32(sp)
    800019ba:	69e2                	ld	s3,24(sp)
    800019bc:	6a42                	ld	s4,16(sp)
    800019be:	6aa2                	ld	s5,8(sp)
    800019c0:	6b02                	ld	s6,0(sp)
    800019c2:	6121                	addi	sp,sp,64
    800019c4:	8082                	ret
      panic("kalloc");
    800019c6:	00007517          	auipc	a0,0x7
    800019ca:	82a50513          	addi	a0,a0,-2006 # 800081f0 <digits+0x1b0>
    800019ce:	fffff097          	auipc	ra,0xfffff
    800019d2:	b70080e7          	jalr	-1168(ra) # 8000053e <panic>

00000000800019d6 <procinit>:

// initialize the proc table at boot time.
void
procinit(void)
{
    800019d6:	7139                	addi	sp,sp,-64
    800019d8:	fc06                	sd	ra,56(sp)
    800019da:	f822                	sd	s0,48(sp)
    800019dc:	f426                	sd	s1,40(sp)
    800019de:	f04a                	sd	s2,32(sp)
    800019e0:	ec4e                	sd	s3,24(sp)
    800019e2:	e852                	sd	s4,16(sp)
    800019e4:	e456                	sd	s5,8(sp)
    800019e6:	e05a                	sd	s6,0(sp)
    800019e8:	0080                	addi	s0,sp,64
  struct proc *p;
  
  initlock(&pid_lock, "nextpid");
    800019ea:	00007597          	auipc	a1,0x7
    800019ee:	80e58593          	addi	a1,a1,-2034 # 800081f8 <digits+0x1b8>
    800019f2:	00010517          	auipc	a0,0x10
    800019f6:	8ae50513          	addi	a0,a0,-1874 # 800112a0 <pid_lock>
    800019fa:	fffff097          	auipc	ra,0xfffff
    800019fe:	15a080e7          	jalr	346(ra) # 80000b54 <initlock>
  initlock(&wait_lock, "wait_lock");
    80001a02:	00006597          	auipc	a1,0x6
    80001a06:	7fe58593          	addi	a1,a1,2046 # 80008200 <digits+0x1c0>
    80001a0a:	00010517          	auipc	a0,0x10
    80001a0e:	8ae50513          	addi	a0,a0,-1874 # 800112b8 <wait_lock>
    80001a12:	fffff097          	auipc	ra,0xfffff
    80001a16:	142080e7          	jalr	322(ra) # 80000b54 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001a1a:	00010497          	auipc	s1,0x10
    80001a1e:	cb648493          	addi	s1,s1,-842 # 800116d0 <proc>
      initlock(&p->lock, "proc");
    80001a22:	00006b17          	auipc	s6,0x6
    80001a26:	7eeb0b13          	addi	s6,s6,2030 # 80008210 <digits+0x1d0>
      p->kstack = KSTACK((int) (p - proc));
    80001a2a:	8aa6                	mv	s5,s1
    80001a2c:	00006a17          	auipc	s4,0x6
    80001a30:	5d4a0a13          	addi	s4,s4,1492 # 80008000 <etext>
    80001a34:	04000937          	lui	s2,0x4000
    80001a38:	197d                	addi	s2,s2,-1
    80001a3a:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001a3c:	00016997          	auipc	s3,0x16
    80001a40:	89498993          	addi	s3,s3,-1900 # 800172d0 <ready_list>
      initlock(&p->lock, "proc");
    80001a44:	85da                	mv	a1,s6
    80001a46:	8526                	mv	a0,s1
    80001a48:	fffff097          	auipc	ra,0xfffff
    80001a4c:	10c080e7          	jalr	268(ra) # 80000b54 <initlock>
      p->kstack = KSTACK((int) (p - proc));
    80001a50:	415487b3          	sub	a5,s1,s5
    80001a54:	8791                	srai	a5,a5,0x4
    80001a56:	000a3703          	ld	a4,0(s4)
    80001a5a:	02e787b3          	mul	a5,a5,a4
    80001a5e:	2785                	addiw	a5,a5,1
    80001a60:	00d7979b          	slliw	a5,a5,0xd
    80001a64:	40f907b3          	sub	a5,s2,a5
    80001a68:	e4bc                	sd	a5,72(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    80001a6a:	17048493          	addi	s1,s1,368
    80001a6e:	fd349be3          	bne	s1,s3,80001a44 <procinit+0x6e>
  }
}
    80001a72:	70e2                	ld	ra,56(sp)
    80001a74:	7442                	ld	s0,48(sp)
    80001a76:	74a2                	ld	s1,40(sp)
    80001a78:	7902                	ld	s2,32(sp)
    80001a7a:	69e2                	ld	s3,24(sp)
    80001a7c:	6a42                	ld	s4,16(sp)
    80001a7e:	6aa2                	ld	s5,8(sp)
    80001a80:	6b02                	ld	s6,0(sp)
    80001a82:	6121                	addi	sp,sp,64
    80001a84:	8082                	ret

0000000080001a86 <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    80001a86:	1141                	addi	sp,sp,-16
    80001a88:	e422                	sd	s0,8(sp)
    80001a8a:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001a8c:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001a8e:	2501                	sext.w	a0,a0
    80001a90:	6422                	ld	s0,8(sp)
    80001a92:	0141                	addi	sp,sp,16
    80001a94:	8082                	ret

0000000080001a96 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void) {
    80001a96:	1141                	addi	sp,sp,-16
    80001a98:	e422                	sd	s0,8(sp)
    80001a9a:	0800                	addi	s0,sp,16
    80001a9c:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001a9e:	2781                	sext.w	a5,a5
    80001aa0:	079e                	slli	a5,a5,0x7
  return c;
}
    80001aa2:	00010517          	auipc	a0,0x10
    80001aa6:	82e50513          	addi	a0,a0,-2002 # 800112d0 <cpus>
    80001aaa:	953e                	add	a0,a0,a5
    80001aac:	6422                	ld	s0,8(sp)
    80001aae:	0141                	addi	sp,sp,16
    80001ab0:	8082                	ret

0000000080001ab2 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void) {
    80001ab2:	1101                	addi	sp,sp,-32
    80001ab4:	ec06                	sd	ra,24(sp)
    80001ab6:	e822                	sd	s0,16(sp)
    80001ab8:	e426                	sd	s1,8(sp)
    80001aba:	1000                	addi	s0,sp,32
  push_off();
    80001abc:	fffff097          	auipc	ra,0xfffff
    80001ac0:	0dc080e7          	jalr	220(ra) # 80000b98 <push_off>
    80001ac4:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    80001ac6:	2781                	sext.w	a5,a5
    80001ac8:	079e                	slli	a5,a5,0x7
    80001aca:	0000f717          	auipc	a4,0xf
    80001ace:	7d670713          	addi	a4,a4,2006 # 800112a0 <pid_lock>
    80001ad2:	97ba                	add	a5,a5,a4
    80001ad4:	7b84                	ld	s1,48(a5)
  pop_off();
    80001ad6:	fffff097          	auipc	ra,0xfffff
    80001ada:	162080e7          	jalr	354(ra) # 80000c38 <pop_off>
  return p;
}
    80001ade:	8526                	mv	a0,s1
    80001ae0:	60e2                	ld	ra,24(sp)
    80001ae2:	6442                	ld	s0,16(sp)
    80001ae4:	64a2                	ld	s1,8(sp)
    80001ae6:	6105                	addi	sp,sp,32
    80001ae8:	8082                	ret

0000000080001aea <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    80001aea:	1141                	addi	sp,sp,-16
    80001aec:	e406                	sd	ra,8(sp)
    80001aee:	e022                	sd	s0,0(sp)
    80001af0:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001af2:	00000097          	auipc	ra,0x0
    80001af6:	fc0080e7          	jalr	-64(ra) # 80001ab2 <myproc>
    80001afa:	fffff097          	auipc	ra,0xfffff
    80001afe:	19e080e7          	jalr	414(ra) # 80000c98 <release>

  if (first) {
    80001b02:	00007797          	auipc	a5,0x7
    80001b06:	d3e7a783          	lw	a5,-706(a5) # 80008840 <first.1711>
    80001b0a:	eb89                	bnez	a5,80001b1c <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001b0c:	00001097          	auipc	ra,0x1
    80001b10:	c44080e7          	jalr	-956(ra) # 80002750 <usertrapret>
}
    80001b14:	60a2                	ld	ra,8(sp)
    80001b16:	6402                	ld	s0,0(sp)
    80001b18:	0141                	addi	sp,sp,16
    80001b1a:	8082                	ret
    first = 0;
    80001b1c:	00007797          	auipc	a5,0x7
    80001b20:	d207a223          	sw	zero,-732(a5) # 80008840 <first.1711>
    fsinit(ROOTDEV);
    80001b24:	4505                	li	a0,1
    80001b26:	00002097          	auipc	ra,0x2
    80001b2a:	9b6080e7          	jalr	-1610(ra) # 800034dc <fsinit>
    80001b2e:	bff9                	j	80001b0c <forkret+0x22>

0000000080001b30 <allocpid>:
allocpid() {
    80001b30:	1101                	addi	sp,sp,-32
    80001b32:	ec06                	sd	ra,24(sp)
    80001b34:	e822                	sd	s0,16(sp)
    80001b36:	e426                	sd	s1,8(sp)
    80001b38:	e04a                	sd	s2,0(sp)
    80001b3a:	1000                	addi	s0,sp,32
    pid = nextpid;
    80001b3c:	00007917          	auipc	s2,0x7
    80001b40:	d0890913          	addi	s2,s2,-760 # 80008844 <nextpid>
    80001b44:	00092483          	lw	s1,0(s2)
  } while (cas(&nextpid, pid, pid+1));
    80001b48:	0014861b          	addiw	a2,s1,1
    80001b4c:	85a6                	mv	a1,s1
    80001b4e:	854a                	mv	a0,s2
    80001b50:	00004097          	auipc	ra,0x4
    80001b54:	796080e7          	jalr	1942(ra) # 800062e6 <cas>
    80001b58:	f575                	bnez	a0,80001b44 <allocpid+0x14>
}
    80001b5a:	8526                	mv	a0,s1
    80001b5c:	60e2                	ld	ra,24(sp)
    80001b5e:	6442                	ld	s0,16(sp)
    80001b60:	64a2                	ld	s1,8(sp)
    80001b62:	6902                	ld	s2,0(sp)
    80001b64:	6105                	addi	sp,sp,32
    80001b66:	8082                	ret

0000000080001b68 <proc_pagetable>:
{
    80001b68:	1101                	addi	sp,sp,-32
    80001b6a:	ec06                	sd	ra,24(sp)
    80001b6c:	e822                	sd	s0,16(sp)
    80001b6e:	e426                	sd	s1,8(sp)
    80001b70:	e04a                	sd	s2,0(sp)
    80001b72:	1000                	addi	s0,sp,32
    80001b74:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001b76:	fffff097          	auipc	ra,0xfffff
    80001b7a:	7c4080e7          	jalr	1988(ra) # 8000133a <uvmcreate>
    80001b7e:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001b80:	c121                	beqz	a0,80001bc0 <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001b82:	4729                	li	a4,10
    80001b84:	00005697          	auipc	a3,0x5
    80001b88:	47c68693          	addi	a3,a3,1148 # 80007000 <_trampoline>
    80001b8c:	6605                	lui	a2,0x1
    80001b8e:	040005b7          	lui	a1,0x4000
    80001b92:	15fd                	addi	a1,a1,-1
    80001b94:	05b2                	slli	a1,a1,0xc
    80001b96:	fffff097          	auipc	ra,0xfffff
    80001b9a:	51a080e7          	jalr	1306(ra) # 800010b0 <mappages>
    80001b9e:	02054863          	bltz	a0,80001bce <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001ba2:	4719                	li	a4,6
    80001ba4:	06093683          	ld	a3,96(s2)
    80001ba8:	6605                	lui	a2,0x1
    80001baa:	020005b7          	lui	a1,0x2000
    80001bae:	15fd                	addi	a1,a1,-1
    80001bb0:	05b6                	slli	a1,a1,0xd
    80001bb2:	8526                	mv	a0,s1
    80001bb4:	fffff097          	auipc	ra,0xfffff
    80001bb8:	4fc080e7          	jalr	1276(ra) # 800010b0 <mappages>
    80001bbc:	02054163          	bltz	a0,80001bde <proc_pagetable+0x76>
}
    80001bc0:	8526                	mv	a0,s1
    80001bc2:	60e2                	ld	ra,24(sp)
    80001bc4:	6442                	ld	s0,16(sp)
    80001bc6:	64a2                	ld	s1,8(sp)
    80001bc8:	6902                	ld	s2,0(sp)
    80001bca:	6105                	addi	sp,sp,32
    80001bcc:	8082                	ret
    uvmfree(pagetable, 0);
    80001bce:	4581                	li	a1,0
    80001bd0:	8526                	mv	a0,s1
    80001bd2:	00000097          	auipc	ra,0x0
    80001bd6:	964080e7          	jalr	-1692(ra) # 80001536 <uvmfree>
    return 0;
    80001bda:	4481                	li	s1,0
    80001bdc:	b7d5                	j	80001bc0 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001bde:	4681                	li	a3,0
    80001be0:	4605                	li	a2,1
    80001be2:	040005b7          	lui	a1,0x4000
    80001be6:	15fd                	addi	a1,a1,-1
    80001be8:	05b2                	slli	a1,a1,0xc
    80001bea:	8526                	mv	a0,s1
    80001bec:	fffff097          	auipc	ra,0xfffff
    80001bf0:	68a080e7          	jalr	1674(ra) # 80001276 <uvmunmap>
    uvmfree(pagetable, 0);
    80001bf4:	4581                	li	a1,0
    80001bf6:	8526                	mv	a0,s1
    80001bf8:	00000097          	auipc	ra,0x0
    80001bfc:	93e080e7          	jalr	-1730(ra) # 80001536 <uvmfree>
    return 0;
    80001c00:	4481                	li	s1,0
    80001c02:	bf7d                	j	80001bc0 <proc_pagetable+0x58>

0000000080001c04 <proc_freepagetable>:
{
    80001c04:	1101                	addi	sp,sp,-32
    80001c06:	ec06                	sd	ra,24(sp)
    80001c08:	e822                	sd	s0,16(sp)
    80001c0a:	e426                	sd	s1,8(sp)
    80001c0c:	e04a                	sd	s2,0(sp)
    80001c0e:	1000                	addi	s0,sp,32
    80001c10:	84aa                	mv	s1,a0
    80001c12:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001c14:	4681                	li	a3,0
    80001c16:	4605                	li	a2,1
    80001c18:	040005b7          	lui	a1,0x4000
    80001c1c:	15fd                	addi	a1,a1,-1
    80001c1e:	05b2                	slli	a1,a1,0xc
    80001c20:	fffff097          	auipc	ra,0xfffff
    80001c24:	656080e7          	jalr	1622(ra) # 80001276 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001c28:	4681                	li	a3,0
    80001c2a:	4605                	li	a2,1
    80001c2c:	020005b7          	lui	a1,0x2000
    80001c30:	15fd                	addi	a1,a1,-1
    80001c32:	05b6                	slli	a1,a1,0xd
    80001c34:	8526                	mv	a0,s1
    80001c36:	fffff097          	auipc	ra,0xfffff
    80001c3a:	640080e7          	jalr	1600(ra) # 80001276 <uvmunmap>
  uvmfree(pagetable, sz);
    80001c3e:	85ca                	mv	a1,s2
    80001c40:	8526                	mv	a0,s1
    80001c42:	00000097          	auipc	ra,0x0
    80001c46:	8f4080e7          	jalr	-1804(ra) # 80001536 <uvmfree>
}
    80001c4a:	60e2                	ld	ra,24(sp)
    80001c4c:	6442                	ld	s0,16(sp)
    80001c4e:	64a2                	ld	s1,8(sp)
    80001c50:	6902                	ld	s2,0(sp)
    80001c52:	6105                	addi	sp,sp,32
    80001c54:	8082                	ret

0000000080001c56 <freeproc>:
{
    80001c56:	1101                	addi	sp,sp,-32
    80001c58:	ec06                	sd	ra,24(sp)
    80001c5a:	e822                	sd	s0,16(sp)
    80001c5c:	e426                	sd	s1,8(sp)
    80001c5e:	1000                	addi	s0,sp,32
    80001c60:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001c62:	7128                	ld	a0,96(a0)
    80001c64:	c509                	beqz	a0,80001c6e <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001c66:	fffff097          	auipc	ra,0xfffff
    80001c6a:	d92080e7          	jalr	-622(ra) # 800009f8 <kfree>
  p->trapframe = 0;
    80001c6e:	0604b023          	sd	zero,96(s1)
  if(p->pagetable)
    80001c72:	6ca8                	ld	a0,88(s1)
    80001c74:	c511                	beqz	a0,80001c80 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001c76:	68ac                	ld	a1,80(s1)
    80001c78:	00000097          	auipc	ra,0x0
    80001c7c:	f8c080e7          	jalr	-116(ra) # 80001c04 <proc_freepagetable>
  p->pagetable = 0;
    80001c80:	0404bc23          	sd	zero,88(s1)
  p->sz = 0;
    80001c84:	0404b823          	sd	zero,80(s1)
  p->pid = 0;
    80001c88:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001c8c:	0404b023          	sd	zero,64(s1)
  p->name[0] = 0;
    80001c90:	16048023          	sb	zero,352(s1)
  p->chan = 0;
    80001c94:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001c98:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001c9c:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001ca0:	0004ac23          	sw	zero,24(s1)
}
    80001ca4:	60e2                	ld	ra,24(sp)
    80001ca6:	6442                	ld	s0,16(sp)
    80001ca8:	64a2                	ld	s1,8(sp)
    80001caa:	6105                	addi	sp,sp,32
    80001cac:	8082                	ret

0000000080001cae <allocproc>:
{
    80001cae:	1101                	addi	sp,sp,-32
    80001cb0:	ec06                	sd	ra,24(sp)
    80001cb2:	e822                	sd	s0,16(sp)
    80001cb4:	e426                	sd	s1,8(sp)
    80001cb6:	e04a                	sd	s2,0(sp)
    80001cb8:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001cba:	00010497          	auipc	s1,0x10
    80001cbe:	a1648493          	addi	s1,s1,-1514 # 800116d0 <proc>
    80001cc2:	00015917          	auipc	s2,0x15
    80001cc6:	60e90913          	addi	s2,s2,1550 # 800172d0 <ready_list>
    acquire(&p->lock);
    80001cca:	8526                	mv	a0,s1
    80001ccc:	fffff097          	auipc	ra,0xfffff
    80001cd0:	f18080e7          	jalr	-232(ra) # 80000be4 <acquire>
    if(p->state == UNUSED) {
    80001cd4:	4c9c                	lw	a5,24(s1)
    80001cd6:	cf81                	beqz	a5,80001cee <allocproc+0x40>
      release(&p->lock);
    80001cd8:	8526                	mv	a0,s1
    80001cda:	fffff097          	auipc	ra,0xfffff
    80001cde:	fbe080e7          	jalr	-66(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001ce2:	17048493          	addi	s1,s1,368
    80001ce6:	ff2492e3          	bne	s1,s2,80001cca <allocproc+0x1c>
  return 0;
    80001cea:	4481                	li	s1,0
    80001cec:	a899                	j	80001d42 <allocproc+0x94>
  p->pid = allocpid();
    80001cee:	00000097          	auipc	ra,0x0
    80001cf2:	e42080e7          	jalr	-446(ra) # 80001b30 <allocpid>
    80001cf6:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001cf8:	4785                	li	a5,1
    80001cfa:	cc9c                	sw	a5,24(s1)
  p->next = -1;
    80001cfc:	57fd                	li	a5,-1
    80001cfe:	d8dc                	sw	a5,52(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001d00:	fffff097          	auipc	ra,0xfffff
    80001d04:	df4080e7          	jalr	-524(ra) # 80000af4 <kalloc>
    80001d08:	892a                	mv	s2,a0
    80001d0a:	f0a8                	sd	a0,96(s1)
    80001d0c:	c131                	beqz	a0,80001d50 <allocproc+0xa2>
  p->pagetable = proc_pagetable(p);
    80001d0e:	8526                	mv	a0,s1
    80001d10:	00000097          	auipc	ra,0x0
    80001d14:	e58080e7          	jalr	-424(ra) # 80001b68 <proc_pagetable>
    80001d18:	892a                	mv	s2,a0
    80001d1a:	eca8                	sd	a0,88(s1)
  if(p->pagetable == 0){
    80001d1c:	c531                	beqz	a0,80001d68 <allocproc+0xba>
  memset(&p->context, 0, sizeof(p->context));
    80001d1e:	07000613          	li	a2,112
    80001d22:	4581                	li	a1,0
    80001d24:	06848513          	addi	a0,s1,104
    80001d28:	fffff097          	auipc	ra,0xfffff
    80001d2c:	fb8080e7          	jalr	-72(ra) # 80000ce0 <memset>
  p->context.ra = (uint64)forkret;
    80001d30:	00000797          	auipc	a5,0x0
    80001d34:	dba78793          	addi	a5,a5,-582 # 80001aea <forkret>
    80001d38:	f4bc                	sd	a5,104(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001d3a:	64bc                	ld	a5,72(s1)
    80001d3c:	6705                	lui	a4,0x1
    80001d3e:	97ba                	add	a5,a5,a4
    80001d40:	f8bc                	sd	a5,112(s1)
}
    80001d42:	8526                	mv	a0,s1
    80001d44:	60e2                	ld	ra,24(sp)
    80001d46:	6442                	ld	s0,16(sp)
    80001d48:	64a2                	ld	s1,8(sp)
    80001d4a:	6902                	ld	s2,0(sp)
    80001d4c:	6105                	addi	sp,sp,32
    80001d4e:	8082                	ret
    freeproc(p);
    80001d50:	8526                	mv	a0,s1
    80001d52:	00000097          	auipc	ra,0x0
    80001d56:	f04080e7          	jalr	-252(ra) # 80001c56 <freeproc>
    release(&p->lock);
    80001d5a:	8526                	mv	a0,s1
    80001d5c:	fffff097          	auipc	ra,0xfffff
    80001d60:	f3c080e7          	jalr	-196(ra) # 80000c98 <release>
    return 0;
    80001d64:	84ca                	mv	s1,s2
    80001d66:	bff1                	j	80001d42 <allocproc+0x94>
    freeproc(p);
    80001d68:	8526                	mv	a0,s1
    80001d6a:	00000097          	auipc	ra,0x0
    80001d6e:	eec080e7          	jalr	-276(ra) # 80001c56 <freeproc>
    release(&p->lock);
    80001d72:	8526                	mv	a0,s1
    80001d74:	fffff097          	auipc	ra,0xfffff
    80001d78:	f24080e7          	jalr	-220(ra) # 80000c98 <release>
    return 0;
    80001d7c:	84ca                	mv	s1,s2
    80001d7e:	b7d1                	j	80001d42 <allocproc+0x94>

0000000080001d80 <userinit>:
{
    80001d80:	1101                	addi	sp,sp,-32
    80001d82:	ec06                	sd	ra,24(sp)
    80001d84:	e822                	sd	s0,16(sp)
    80001d86:	e426                	sd	s1,8(sp)
    80001d88:	1000                	addi	s0,sp,32
  p = allocproc();
    80001d8a:	00000097          	auipc	ra,0x0
    80001d8e:	f24080e7          	jalr	-220(ra) # 80001cae <allocproc>
    80001d92:	84aa                	mv	s1,a0
  initproc = p;
    80001d94:	00007797          	auipc	a5,0x7
    80001d98:	28a7ba23          	sd	a0,660(a5) # 80009028 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001d9c:	03400613          	li	a2,52
    80001da0:	00007597          	auipc	a1,0x7
    80001da4:	ab058593          	addi	a1,a1,-1360 # 80008850 <initcode>
    80001da8:	6d28                	ld	a0,88(a0)
    80001daa:	fffff097          	auipc	ra,0xfffff
    80001dae:	5be080e7          	jalr	1470(ra) # 80001368 <uvminit>
  p->sz = PGSIZE;
    80001db2:	6785                	lui	a5,0x1
    80001db4:	e8bc                	sd	a5,80(s1)
  p->trapframe->epc = 0;      // user program counter
    80001db6:	70b8                	ld	a4,96(s1)
    80001db8:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001dbc:	70b8                	ld	a4,96(s1)
    80001dbe:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001dc0:	4641                	li	a2,16
    80001dc2:	00006597          	auipc	a1,0x6
    80001dc6:	45658593          	addi	a1,a1,1110 # 80008218 <digits+0x1d8>
    80001dca:	16048513          	addi	a0,s1,352
    80001dce:	fffff097          	auipc	ra,0xfffff
    80001dd2:	064080e7          	jalr	100(ra) # 80000e32 <safestrcpy>
  p->cwd = namei("/");
    80001dd6:	00006517          	auipc	a0,0x6
    80001dda:	45250513          	addi	a0,a0,1106 # 80008228 <digits+0x1e8>
    80001dde:	00002097          	auipc	ra,0x2
    80001de2:	12c080e7          	jalr	300(ra) # 80003f0a <namei>
    80001de6:	14a4bc23          	sd	a0,344(s1)
  p->state = RUNNABLE;
    80001dea:	478d                	li	a5,3
    80001dec:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001dee:	8526                	mv	a0,s1
    80001df0:	fffff097          	auipc	ra,0xfffff
    80001df4:	ea8080e7          	jalr	-344(ra) # 80000c98 <release>
}
    80001df8:	60e2                	ld	ra,24(sp)
    80001dfa:	6442                	ld	s0,16(sp)
    80001dfc:	64a2                	ld	s1,8(sp)
    80001dfe:	6105                	addi	sp,sp,32
    80001e00:	8082                	ret

0000000080001e02 <growproc>:
{
    80001e02:	1101                	addi	sp,sp,-32
    80001e04:	ec06                	sd	ra,24(sp)
    80001e06:	e822                	sd	s0,16(sp)
    80001e08:	e426                	sd	s1,8(sp)
    80001e0a:	e04a                	sd	s2,0(sp)
    80001e0c:	1000                	addi	s0,sp,32
    80001e0e:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001e10:	00000097          	auipc	ra,0x0
    80001e14:	ca2080e7          	jalr	-862(ra) # 80001ab2 <myproc>
    80001e18:	892a                	mv	s2,a0
  sz = p->sz;
    80001e1a:	692c                	ld	a1,80(a0)
    80001e1c:	0005861b          	sext.w	a2,a1
  if(n > 0){
    80001e20:	00904f63          	bgtz	s1,80001e3e <growproc+0x3c>
  } else if(n < 0){
    80001e24:	0204cc63          	bltz	s1,80001e5c <growproc+0x5a>
  p->sz = sz;
    80001e28:	1602                	slli	a2,a2,0x20
    80001e2a:	9201                	srli	a2,a2,0x20
    80001e2c:	04c93823          	sd	a2,80(s2)
  return 0;
    80001e30:	4501                	li	a0,0
}
    80001e32:	60e2                	ld	ra,24(sp)
    80001e34:	6442                	ld	s0,16(sp)
    80001e36:	64a2                	ld	s1,8(sp)
    80001e38:	6902                	ld	s2,0(sp)
    80001e3a:	6105                	addi	sp,sp,32
    80001e3c:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80001e3e:	9e25                	addw	a2,a2,s1
    80001e40:	1602                	slli	a2,a2,0x20
    80001e42:	9201                	srli	a2,a2,0x20
    80001e44:	1582                	slli	a1,a1,0x20
    80001e46:	9181                	srli	a1,a1,0x20
    80001e48:	6d28                	ld	a0,88(a0)
    80001e4a:	fffff097          	auipc	ra,0xfffff
    80001e4e:	5d8080e7          	jalr	1496(ra) # 80001422 <uvmalloc>
    80001e52:	0005061b          	sext.w	a2,a0
    80001e56:	fa69                	bnez	a2,80001e28 <growproc+0x26>
      return -1;
    80001e58:	557d                	li	a0,-1
    80001e5a:	bfe1                	j	80001e32 <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001e5c:	9e25                	addw	a2,a2,s1
    80001e5e:	1602                	slli	a2,a2,0x20
    80001e60:	9201                	srli	a2,a2,0x20
    80001e62:	1582                	slli	a1,a1,0x20
    80001e64:	9181                	srli	a1,a1,0x20
    80001e66:	6d28                	ld	a0,88(a0)
    80001e68:	fffff097          	auipc	ra,0xfffff
    80001e6c:	572080e7          	jalr	1394(ra) # 800013da <uvmdealloc>
    80001e70:	0005061b          	sext.w	a2,a0
    80001e74:	bf55                	j	80001e28 <growproc+0x26>

0000000080001e76 <fork>:
{
    80001e76:	7179                	addi	sp,sp,-48
    80001e78:	f406                	sd	ra,40(sp)
    80001e7a:	f022                	sd	s0,32(sp)
    80001e7c:	ec26                	sd	s1,24(sp)
    80001e7e:	e84a                	sd	s2,16(sp)
    80001e80:	e44e                	sd	s3,8(sp)
    80001e82:	e052                	sd	s4,0(sp)
    80001e84:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001e86:	00000097          	auipc	ra,0x0
    80001e8a:	c2c080e7          	jalr	-980(ra) # 80001ab2 <myproc>
    80001e8e:	892a                	mv	s2,a0
  if((np = allocproc()) == 0){
    80001e90:	00000097          	auipc	ra,0x0
    80001e94:	e1e080e7          	jalr	-482(ra) # 80001cae <allocproc>
    80001e98:	10050b63          	beqz	a0,80001fae <fork+0x138>
    80001e9c:	89aa                	mv	s3,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001e9e:	05093603          	ld	a2,80(s2)
    80001ea2:	6d2c                	ld	a1,88(a0)
    80001ea4:	05893503          	ld	a0,88(s2)
    80001ea8:	fffff097          	auipc	ra,0xfffff
    80001eac:	6c6080e7          	jalr	1734(ra) # 8000156e <uvmcopy>
    80001eb0:	04054663          	bltz	a0,80001efc <fork+0x86>
  np->sz = p->sz;
    80001eb4:	05093783          	ld	a5,80(s2)
    80001eb8:	04f9b823          	sd	a5,80(s3)
  *(np->trapframe) = *(p->trapframe);
    80001ebc:	06093683          	ld	a3,96(s2)
    80001ec0:	87b6                	mv	a5,a3
    80001ec2:	0609b703          	ld	a4,96(s3)
    80001ec6:	12068693          	addi	a3,a3,288
    80001eca:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001ece:	6788                	ld	a0,8(a5)
    80001ed0:	6b8c                	ld	a1,16(a5)
    80001ed2:	6f90                	ld	a2,24(a5)
    80001ed4:	01073023          	sd	a6,0(a4)
    80001ed8:	e708                	sd	a0,8(a4)
    80001eda:	eb0c                	sd	a1,16(a4)
    80001edc:	ef10                	sd	a2,24(a4)
    80001ede:	02078793          	addi	a5,a5,32
    80001ee2:	02070713          	addi	a4,a4,32
    80001ee6:	fed792e3          	bne	a5,a3,80001eca <fork+0x54>
  np->trapframe->a0 = 0;
    80001eea:	0609b783          	ld	a5,96(s3)
    80001eee:	0607b823          	sd	zero,112(a5)
    80001ef2:	0d800493          	li	s1,216
  for(i = 0; i < NOFILE; i++)
    80001ef6:	15800a13          	li	s4,344
    80001efa:	a03d                	j	80001f28 <fork+0xb2>
    freeproc(np);
    80001efc:	854e                	mv	a0,s3
    80001efe:	00000097          	auipc	ra,0x0
    80001f02:	d58080e7          	jalr	-680(ra) # 80001c56 <freeproc>
    release(&np->lock);
    80001f06:	854e                	mv	a0,s3
    80001f08:	fffff097          	auipc	ra,0xfffff
    80001f0c:	d90080e7          	jalr	-624(ra) # 80000c98 <release>
    return -1;
    80001f10:	5a7d                	li	s4,-1
    80001f12:	a069                	j	80001f9c <fork+0x126>
      np->ofile[i] = filedup(p->ofile[i]);
    80001f14:	00002097          	auipc	ra,0x2
    80001f18:	68c080e7          	jalr	1676(ra) # 800045a0 <filedup>
    80001f1c:	009987b3          	add	a5,s3,s1
    80001f20:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    80001f22:	04a1                	addi	s1,s1,8
    80001f24:	01448763          	beq	s1,s4,80001f32 <fork+0xbc>
    if(p->ofile[i])
    80001f28:	009907b3          	add	a5,s2,s1
    80001f2c:	6388                	ld	a0,0(a5)
    80001f2e:	f17d                	bnez	a0,80001f14 <fork+0x9e>
    80001f30:	bfcd                	j	80001f22 <fork+0xac>
  np->cwd = idup(p->cwd);
    80001f32:	15893503          	ld	a0,344(s2)
    80001f36:	00001097          	auipc	ra,0x1
    80001f3a:	7e0080e7          	jalr	2016(ra) # 80003716 <idup>
    80001f3e:	14a9bc23          	sd	a0,344(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001f42:	4641                	li	a2,16
    80001f44:	16090593          	addi	a1,s2,352
    80001f48:	16098513          	addi	a0,s3,352
    80001f4c:	fffff097          	auipc	ra,0xfffff
    80001f50:	ee6080e7          	jalr	-282(ra) # 80000e32 <safestrcpy>
  pid = np->pid;
    80001f54:	0309aa03          	lw	s4,48(s3)
  release(&np->lock);
    80001f58:	854e                	mv	a0,s3
    80001f5a:	fffff097          	auipc	ra,0xfffff
    80001f5e:	d3e080e7          	jalr	-706(ra) # 80000c98 <release>
  acquire(&wait_lock);
    80001f62:	0000f497          	auipc	s1,0xf
    80001f66:	35648493          	addi	s1,s1,854 # 800112b8 <wait_lock>
    80001f6a:	8526                	mv	a0,s1
    80001f6c:	fffff097          	auipc	ra,0xfffff
    80001f70:	c78080e7          	jalr	-904(ra) # 80000be4 <acquire>
  np->parent = p;
    80001f74:	0529b023          	sd	s2,64(s3)
  release(&wait_lock);
    80001f78:	8526                	mv	a0,s1
    80001f7a:	fffff097          	auipc	ra,0xfffff
    80001f7e:	d1e080e7          	jalr	-738(ra) # 80000c98 <release>
  acquire(&np->lock);
    80001f82:	854e                	mv	a0,s3
    80001f84:	fffff097          	auipc	ra,0xfffff
    80001f88:	c60080e7          	jalr	-928(ra) # 80000be4 <acquire>
  np->state = RUNNABLE;
    80001f8c:	478d                	li	a5,3
    80001f8e:	00f9ac23          	sw	a5,24(s3)
  release(&np->lock);
    80001f92:	854e                	mv	a0,s3
    80001f94:	fffff097          	auipc	ra,0xfffff
    80001f98:	d04080e7          	jalr	-764(ra) # 80000c98 <release>
}
    80001f9c:	8552                	mv	a0,s4
    80001f9e:	70a2                	ld	ra,40(sp)
    80001fa0:	7402                	ld	s0,32(sp)
    80001fa2:	64e2                	ld	s1,24(sp)
    80001fa4:	6942                	ld	s2,16(sp)
    80001fa6:	69a2                	ld	s3,8(sp)
    80001fa8:	6a02                	ld	s4,0(sp)
    80001faa:	6145                	addi	sp,sp,48
    80001fac:	8082                	ret
    return -1;
    80001fae:	5a7d                	li	s4,-1
    80001fb0:	b7f5                	j	80001f9c <fork+0x126>

0000000080001fb2 <scheduler>:
{
    80001fb2:	7139                	addi	sp,sp,-64
    80001fb4:	fc06                	sd	ra,56(sp)
    80001fb6:	f822                	sd	s0,48(sp)
    80001fb8:	f426                	sd	s1,40(sp)
    80001fba:	f04a                	sd	s2,32(sp)
    80001fbc:	ec4e                	sd	s3,24(sp)
    80001fbe:	e852                	sd	s4,16(sp)
    80001fc0:	e456                	sd	s5,8(sp)
    80001fc2:	e05a                	sd	s6,0(sp)
    80001fc4:	0080                	addi	s0,sp,64
    80001fc6:	8792                	mv	a5,tp
  int id = r_tp();
    80001fc8:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001fca:	00779a93          	slli	s5,a5,0x7
    80001fce:	0000f717          	auipc	a4,0xf
    80001fd2:	2d270713          	addi	a4,a4,722 # 800112a0 <pid_lock>
    80001fd6:	9756                	add	a4,a4,s5
    80001fd8:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    80001fdc:	0000f717          	auipc	a4,0xf
    80001fe0:	2fc70713          	addi	a4,a4,764 # 800112d8 <cpus+0x8>
    80001fe4:	9aba                	add	s5,s5,a4
      if(p->state == RUNNABLE) {
    80001fe6:	498d                	li	s3,3
        p->state = RUNNING;
    80001fe8:	4b11                	li	s6,4
        c->proc = p;
    80001fea:	079e                	slli	a5,a5,0x7
    80001fec:	0000fa17          	auipc	s4,0xf
    80001ff0:	2b4a0a13          	addi	s4,s4,692 # 800112a0 <pid_lock>
    80001ff4:	9a3e                	add	s4,s4,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    80001ff6:	00015917          	auipc	s2,0x15
    80001ffa:	2da90913          	addi	s2,s2,730 # 800172d0 <ready_list>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001ffe:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002002:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002006:	10079073          	csrw	sstatus,a5
    8000200a:	0000f497          	auipc	s1,0xf
    8000200e:	6c648493          	addi	s1,s1,1734 # 800116d0 <proc>
    80002012:	a03d                	j	80002040 <scheduler+0x8e>
        p->state = RUNNING;
    80002014:	0164ac23          	sw	s6,24(s1)
        c->proc = p;
    80002018:	029a3823          	sd	s1,48(s4)
        swtch(&c->context, &p->context);
    8000201c:	06848593          	addi	a1,s1,104
    80002020:	8556                	mv	a0,s5
    80002022:	00000097          	auipc	ra,0x0
    80002026:	684080e7          	jalr	1668(ra) # 800026a6 <swtch>
        c->proc = 0;
    8000202a:	020a3823          	sd	zero,48(s4)
      release(&p->lock);
    8000202e:	8526                	mv	a0,s1
    80002030:	fffff097          	auipc	ra,0xfffff
    80002034:	c68080e7          	jalr	-920(ra) # 80000c98 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80002038:	17048493          	addi	s1,s1,368
    8000203c:	fd2481e3          	beq	s1,s2,80001ffe <scheduler+0x4c>
      acquire(&p->lock);
    80002040:	8526                	mv	a0,s1
    80002042:	fffff097          	auipc	ra,0xfffff
    80002046:	ba2080e7          	jalr	-1118(ra) # 80000be4 <acquire>
      if(p->state == RUNNABLE) {
    8000204a:	4c9c                	lw	a5,24(s1)
    8000204c:	ff3791e3          	bne	a5,s3,8000202e <scheduler+0x7c>
    80002050:	b7d1                	j	80002014 <scheduler+0x62>

0000000080002052 <sched>:
{
    80002052:	7179                	addi	sp,sp,-48
    80002054:	f406                	sd	ra,40(sp)
    80002056:	f022                	sd	s0,32(sp)
    80002058:	ec26                	sd	s1,24(sp)
    8000205a:	e84a                	sd	s2,16(sp)
    8000205c:	e44e                	sd	s3,8(sp)
    8000205e:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80002060:	00000097          	auipc	ra,0x0
    80002064:	a52080e7          	jalr	-1454(ra) # 80001ab2 <myproc>
    80002068:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    8000206a:	fffff097          	auipc	ra,0xfffff
    8000206e:	b00080e7          	jalr	-1280(ra) # 80000b6a <holding>
    80002072:	c93d                	beqz	a0,800020e8 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002074:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80002076:	2781                	sext.w	a5,a5
    80002078:	079e                	slli	a5,a5,0x7
    8000207a:	0000f717          	auipc	a4,0xf
    8000207e:	22670713          	addi	a4,a4,550 # 800112a0 <pid_lock>
    80002082:	97ba                	add	a5,a5,a4
    80002084:	0a87a703          	lw	a4,168(a5)
    80002088:	4785                	li	a5,1
    8000208a:	06f71763          	bne	a4,a5,800020f8 <sched+0xa6>
  if(p->state == RUNNING)
    8000208e:	4c98                	lw	a4,24(s1)
    80002090:	4791                	li	a5,4
    80002092:	06f70b63          	beq	a4,a5,80002108 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002096:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    8000209a:	8b89                	andi	a5,a5,2
  if(intr_get())
    8000209c:	efb5                	bnez	a5,80002118 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    8000209e:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    800020a0:	0000f917          	auipc	s2,0xf
    800020a4:	20090913          	addi	s2,s2,512 # 800112a0 <pid_lock>
    800020a8:	2781                	sext.w	a5,a5
    800020aa:	079e                	slli	a5,a5,0x7
    800020ac:	97ca                	add	a5,a5,s2
    800020ae:	0ac7a983          	lw	s3,172(a5)
    800020b2:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    800020b4:	2781                	sext.w	a5,a5
    800020b6:	079e                	slli	a5,a5,0x7
    800020b8:	0000f597          	auipc	a1,0xf
    800020bc:	22058593          	addi	a1,a1,544 # 800112d8 <cpus+0x8>
    800020c0:	95be                	add	a1,a1,a5
    800020c2:	06848513          	addi	a0,s1,104
    800020c6:	00000097          	auipc	ra,0x0
    800020ca:	5e0080e7          	jalr	1504(ra) # 800026a6 <swtch>
    800020ce:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    800020d0:	2781                	sext.w	a5,a5
    800020d2:	079e                	slli	a5,a5,0x7
    800020d4:	97ca                	add	a5,a5,s2
    800020d6:	0b37a623          	sw	s3,172(a5)
}
    800020da:	70a2                	ld	ra,40(sp)
    800020dc:	7402                	ld	s0,32(sp)
    800020de:	64e2                	ld	s1,24(sp)
    800020e0:	6942                	ld	s2,16(sp)
    800020e2:	69a2                	ld	s3,8(sp)
    800020e4:	6145                	addi	sp,sp,48
    800020e6:	8082                	ret
    panic("sched p->lock");
    800020e8:	00006517          	auipc	a0,0x6
    800020ec:	14850513          	addi	a0,a0,328 # 80008230 <digits+0x1f0>
    800020f0:	ffffe097          	auipc	ra,0xffffe
    800020f4:	44e080e7          	jalr	1102(ra) # 8000053e <panic>
    panic("sched locks");
    800020f8:	00006517          	auipc	a0,0x6
    800020fc:	14850513          	addi	a0,a0,328 # 80008240 <digits+0x200>
    80002100:	ffffe097          	auipc	ra,0xffffe
    80002104:	43e080e7          	jalr	1086(ra) # 8000053e <panic>
    panic("sched running");
    80002108:	00006517          	auipc	a0,0x6
    8000210c:	14850513          	addi	a0,a0,328 # 80008250 <digits+0x210>
    80002110:	ffffe097          	auipc	ra,0xffffe
    80002114:	42e080e7          	jalr	1070(ra) # 8000053e <panic>
    panic("sched interruptible");
    80002118:	00006517          	auipc	a0,0x6
    8000211c:	14850513          	addi	a0,a0,328 # 80008260 <digits+0x220>
    80002120:	ffffe097          	auipc	ra,0xffffe
    80002124:	41e080e7          	jalr	1054(ra) # 8000053e <panic>

0000000080002128 <yield>:
{
    80002128:	1101                	addi	sp,sp,-32
    8000212a:	ec06                	sd	ra,24(sp)
    8000212c:	e822                	sd	s0,16(sp)
    8000212e:	e426                	sd	s1,8(sp)
    80002130:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002132:	00000097          	auipc	ra,0x0
    80002136:	980080e7          	jalr	-1664(ra) # 80001ab2 <myproc>
    8000213a:	84aa                	mv	s1,a0
  acquire(&p->lock);
    8000213c:	fffff097          	auipc	ra,0xfffff
    80002140:	aa8080e7          	jalr	-1368(ra) # 80000be4 <acquire>
  p->state = RUNNABLE;
    80002144:	478d                	li	a5,3
    80002146:	cc9c                	sw	a5,24(s1)
  sched();
    80002148:	00000097          	auipc	ra,0x0
    8000214c:	f0a080e7          	jalr	-246(ra) # 80002052 <sched>
  release(&p->lock);
    80002150:	8526                	mv	a0,s1
    80002152:	fffff097          	auipc	ra,0xfffff
    80002156:	b46080e7          	jalr	-1210(ra) # 80000c98 <release>
}
    8000215a:	60e2                	ld	ra,24(sp)
    8000215c:	6442                	ld	s0,16(sp)
    8000215e:	64a2                	ld	s1,8(sp)
    80002160:	6105                	addi	sp,sp,32
    80002162:	8082                	ret

0000000080002164 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    80002164:	7179                	addi	sp,sp,-48
    80002166:	f406                	sd	ra,40(sp)
    80002168:	f022                	sd	s0,32(sp)
    8000216a:	ec26                	sd	s1,24(sp)
    8000216c:	e84a                	sd	s2,16(sp)
    8000216e:	e44e                	sd	s3,8(sp)
    80002170:	1800                	addi	s0,sp,48
    80002172:	89aa                	mv	s3,a0
    80002174:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002176:	00000097          	auipc	ra,0x0
    8000217a:	93c080e7          	jalr	-1732(ra) # 80001ab2 <myproc>
    8000217e:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    80002180:	fffff097          	auipc	ra,0xfffff
    80002184:	a64080e7          	jalr	-1436(ra) # 80000be4 <acquire>
  release(lk);
    80002188:	854a                	mv	a0,s2
    8000218a:	fffff097          	auipc	ra,0xfffff
    8000218e:	b0e080e7          	jalr	-1266(ra) # 80000c98 <release>

  // Go to sleep.
  p->chan = chan;
    80002192:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    80002196:	4789                	li	a5,2
    80002198:	cc9c                	sw	a5,24(s1)

  sched();
    8000219a:	00000097          	auipc	ra,0x0
    8000219e:	eb8080e7          	jalr	-328(ra) # 80002052 <sched>

  // Tidy up.
  p->chan = 0;
    800021a2:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    800021a6:	8526                	mv	a0,s1
    800021a8:	fffff097          	auipc	ra,0xfffff
    800021ac:	af0080e7          	jalr	-1296(ra) # 80000c98 <release>
  acquire(lk);
    800021b0:	854a                	mv	a0,s2
    800021b2:	fffff097          	auipc	ra,0xfffff
    800021b6:	a32080e7          	jalr	-1486(ra) # 80000be4 <acquire>
}
    800021ba:	70a2                	ld	ra,40(sp)
    800021bc:	7402                	ld	s0,32(sp)
    800021be:	64e2                	ld	s1,24(sp)
    800021c0:	6942                	ld	s2,16(sp)
    800021c2:	69a2                	ld	s3,8(sp)
    800021c4:	6145                	addi	sp,sp,48
    800021c6:	8082                	ret

00000000800021c8 <wait>:
{
    800021c8:	715d                	addi	sp,sp,-80
    800021ca:	e486                	sd	ra,72(sp)
    800021cc:	e0a2                	sd	s0,64(sp)
    800021ce:	fc26                	sd	s1,56(sp)
    800021d0:	f84a                	sd	s2,48(sp)
    800021d2:	f44e                	sd	s3,40(sp)
    800021d4:	f052                	sd	s4,32(sp)
    800021d6:	ec56                	sd	s5,24(sp)
    800021d8:	e85a                	sd	s6,16(sp)
    800021da:	e45e                	sd	s7,8(sp)
    800021dc:	e062                	sd	s8,0(sp)
    800021de:	0880                	addi	s0,sp,80
    800021e0:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    800021e2:	00000097          	auipc	ra,0x0
    800021e6:	8d0080e7          	jalr	-1840(ra) # 80001ab2 <myproc>
    800021ea:	892a                	mv	s2,a0
  acquire(&wait_lock);
    800021ec:	0000f517          	auipc	a0,0xf
    800021f0:	0cc50513          	addi	a0,a0,204 # 800112b8 <wait_lock>
    800021f4:	fffff097          	auipc	ra,0xfffff
    800021f8:	9f0080e7          	jalr	-1552(ra) # 80000be4 <acquire>
    havekids = 0;
    800021fc:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    800021fe:	4a15                	li	s4,5
    for(np = proc; np < &proc[NPROC]; np++){
    80002200:	00015997          	auipc	s3,0x15
    80002204:	0d098993          	addi	s3,s3,208 # 800172d0 <ready_list>
        havekids = 1;
    80002208:	4a85                	li	s5,1
    sleep(p, &wait_lock);  //DOC: wait-sleep
    8000220a:	0000fc17          	auipc	s8,0xf
    8000220e:	0aec0c13          	addi	s8,s8,174 # 800112b8 <wait_lock>
    havekids = 0;
    80002212:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    80002214:	0000f497          	auipc	s1,0xf
    80002218:	4bc48493          	addi	s1,s1,1212 # 800116d0 <proc>
    8000221c:	a0bd                	j	8000228a <wait+0xc2>
          pid = np->pid;
    8000221e:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    80002222:	000b0e63          	beqz	s6,8000223e <wait+0x76>
    80002226:	4691                	li	a3,4
    80002228:	02c48613          	addi	a2,s1,44
    8000222c:	85da                	mv	a1,s6
    8000222e:	05893503          	ld	a0,88(s2)
    80002232:	fffff097          	auipc	ra,0xfffff
    80002236:	440080e7          	jalr	1088(ra) # 80001672 <copyout>
    8000223a:	02054563          	bltz	a0,80002264 <wait+0x9c>
          freeproc(np);
    8000223e:	8526                	mv	a0,s1
    80002240:	00000097          	auipc	ra,0x0
    80002244:	a16080e7          	jalr	-1514(ra) # 80001c56 <freeproc>
          release(&np->lock);
    80002248:	8526                	mv	a0,s1
    8000224a:	fffff097          	auipc	ra,0xfffff
    8000224e:	a4e080e7          	jalr	-1458(ra) # 80000c98 <release>
          release(&wait_lock);
    80002252:	0000f517          	auipc	a0,0xf
    80002256:	06650513          	addi	a0,a0,102 # 800112b8 <wait_lock>
    8000225a:	fffff097          	auipc	ra,0xfffff
    8000225e:	a3e080e7          	jalr	-1474(ra) # 80000c98 <release>
          return pid;
    80002262:	a09d                	j	800022c8 <wait+0x100>
            release(&np->lock);
    80002264:	8526                	mv	a0,s1
    80002266:	fffff097          	auipc	ra,0xfffff
    8000226a:	a32080e7          	jalr	-1486(ra) # 80000c98 <release>
            release(&wait_lock);
    8000226e:	0000f517          	auipc	a0,0xf
    80002272:	04a50513          	addi	a0,a0,74 # 800112b8 <wait_lock>
    80002276:	fffff097          	auipc	ra,0xfffff
    8000227a:	a22080e7          	jalr	-1502(ra) # 80000c98 <release>
            return -1;
    8000227e:	59fd                	li	s3,-1
    80002280:	a0a1                	j	800022c8 <wait+0x100>
    for(np = proc; np < &proc[NPROC]; np++){
    80002282:	17048493          	addi	s1,s1,368
    80002286:	03348463          	beq	s1,s3,800022ae <wait+0xe6>
      if(np->parent == p){
    8000228a:	60bc                	ld	a5,64(s1)
    8000228c:	ff279be3          	bne	a5,s2,80002282 <wait+0xba>
        acquire(&np->lock);
    80002290:	8526                	mv	a0,s1
    80002292:	fffff097          	auipc	ra,0xfffff
    80002296:	952080e7          	jalr	-1710(ra) # 80000be4 <acquire>
        if(np->state == ZOMBIE){
    8000229a:	4c9c                	lw	a5,24(s1)
    8000229c:	f94781e3          	beq	a5,s4,8000221e <wait+0x56>
        release(&np->lock);
    800022a0:	8526                	mv	a0,s1
    800022a2:	fffff097          	auipc	ra,0xfffff
    800022a6:	9f6080e7          	jalr	-1546(ra) # 80000c98 <release>
        havekids = 1;
    800022aa:	8756                	mv	a4,s5
    800022ac:	bfd9                	j	80002282 <wait+0xba>
    if(!havekids || p->killed){
    800022ae:	c701                	beqz	a4,800022b6 <wait+0xee>
    800022b0:	02892783          	lw	a5,40(s2)
    800022b4:	c79d                	beqz	a5,800022e2 <wait+0x11a>
      release(&wait_lock);
    800022b6:	0000f517          	auipc	a0,0xf
    800022ba:	00250513          	addi	a0,a0,2 # 800112b8 <wait_lock>
    800022be:	fffff097          	auipc	ra,0xfffff
    800022c2:	9da080e7          	jalr	-1574(ra) # 80000c98 <release>
      return -1;
    800022c6:	59fd                	li	s3,-1
}
    800022c8:	854e                	mv	a0,s3
    800022ca:	60a6                	ld	ra,72(sp)
    800022cc:	6406                	ld	s0,64(sp)
    800022ce:	74e2                	ld	s1,56(sp)
    800022d0:	7942                	ld	s2,48(sp)
    800022d2:	79a2                	ld	s3,40(sp)
    800022d4:	7a02                	ld	s4,32(sp)
    800022d6:	6ae2                	ld	s5,24(sp)
    800022d8:	6b42                	ld	s6,16(sp)
    800022da:	6ba2                	ld	s7,8(sp)
    800022dc:	6c02                	ld	s8,0(sp)
    800022de:	6161                	addi	sp,sp,80
    800022e0:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800022e2:	85e2                	mv	a1,s8
    800022e4:	854a                	mv	a0,s2
    800022e6:	00000097          	auipc	ra,0x0
    800022ea:	e7e080e7          	jalr	-386(ra) # 80002164 <sleep>
    havekids = 0;
    800022ee:	b715                	j	80002212 <wait+0x4a>

00000000800022f0 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    800022f0:	7139                	addi	sp,sp,-64
    800022f2:	fc06                	sd	ra,56(sp)
    800022f4:	f822                	sd	s0,48(sp)
    800022f6:	f426                	sd	s1,40(sp)
    800022f8:	f04a                	sd	s2,32(sp)
    800022fa:	ec4e                	sd	s3,24(sp)
    800022fc:	e852                	sd	s4,16(sp)
    800022fe:	e456                	sd	s5,8(sp)
    80002300:	0080                	addi	s0,sp,64
    80002302:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    80002304:	0000f497          	auipc	s1,0xf
    80002308:	3cc48493          	addi	s1,s1,972 # 800116d0 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    8000230c:	4989                	li	s3,2
        p->state = RUNNABLE;
    8000230e:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    80002310:	00015917          	auipc	s2,0x15
    80002314:	fc090913          	addi	s2,s2,-64 # 800172d0 <ready_list>
    80002318:	a821                	j	80002330 <wakeup+0x40>
        p->state = RUNNABLE;
    8000231a:	0154ac23          	sw	s5,24(s1)
      }
      release(&p->lock);
    8000231e:	8526                	mv	a0,s1
    80002320:	fffff097          	auipc	ra,0xfffff
    80002324:	978080e7          	jalr	-1672(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80002328:	17048493          	addi	s1,s1,368
    8000232c:	03248463          	beq	s1,s2,80002354 <wakeup+0x64>
    if(p != myproc()){
    80002330:	fffff097          	auipc	ra,0xfffff
    80002334:	782080e7          	jalr	1922(ra) # 80001ab2 <myproc>
    80002338:	fea488e3          	beq	s1,a0,80002328 <wakeup+0x38>
      acquire(&p->lock);
    8000233c:	8526                	mv	a0,s1
    8000233e:	fffff097          	auipc	ra,0xfffff
    80002342:	8a6080e7          	jalr	-1882(ra) # 80000be4 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    80002346:	4c9c                	lw	a5,24(s1)
    80002348:	fd379be3          	bne	a5,s3,8000231e <wakeup+0x2e>
    8000234c:	709c                	ld	a5,32(s1)
    8000234e:	fd4798e3          	bne	a5,s4,8000231e <wakeup+0x2e>
    80002352:	b7e1                	j	8000231a <wakeup+0x2a>
    }
  }
}
    80002354:	70e2                	ld	ra,56(sp)
    80002356:	7442                	ld	s0,48(sp)
    80002358:	74a2                	ld	s1,40(sp)
    8000235a:	7902                	ld	s2,32(sp)
    8000235c:	69e2                	ld	s3,24(sp)
    8000235e:	6a42                	ld	s4,16(sp)
    80002360:	6aa2                	ld	s5,8(sp)
    80002362:	6121                	addi	sp,sp,64
    80002364:	8082                	ret

0000000080002366 <reparent>:
{
    80002366:	7179                	addi	sp,sp,-48
    80002368:	f406                	sd	ra,40(sp)
    8000236a:	f022                	sd	s0,32(sp)
    8000236c:	ec26                	sd	s1,24(sp)
    8000236e:	e84a                	sd	s2,16(sp)
    80002370:	e44e                	sd	s3,8(sp)
    80002372:	e052                	sd	s4,0(sp)
    80002374:	1800                	addi	s0,sp,48
    80002376:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002378:	0000f497          	auipc	s1,0xf
    8000237c:	35848493          	addi	s1,s1,856 # 800116d0 <proc>
      pp->parent = initproc;
    80002380:	00007a17          	auipc	s4,0x7
    80002384:	ca8a0a13          	addi	s4,s4,-856 # 80009028 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002388:	00015997          	auipc	s3,0x15
    8000238c:	f4898993          	addi	s3,s3,-184 # 800172d0 <ready_list>
    80002390:	a029                	j	8000239a <reparent+0x34>
    80002392:	17048493          	addi	s1,s1,368
    80002396:	01348d63          	beq	s1,s3,800023b0 <reparent+0x4a>
    if(pp->parent == p){
    8000239a:	60bc                	ld	a5,64(s1)
    8000239c:	ff279be3          	bne	a5,s2,80002392 <reparent+0x2c>
      pp->parent = initproc;
    800023a0:	000a3503          	ld	a0,0(s4)
    800023a4:	e0a8                	sd	a0,64(s1)
      wakeup(initproc);
    800023a6:	00000097          	auipc	ra,0x0
    800023aa:	f4a080e7          	jalr	-182(ra) # 800022f0 <wakeup>
    800023ae:	b7d5                	j	80002392 <reparent+0x2c>
}
    800023b0:	70a2                	ld	ra,40(sp)
    800023b2:	7402                	ld	s0,32(sp)
    800023b4:	64e2                	ld	s1,24(sp)
    800023b6:	6942                	ld	s2,16(sp)
    800023b8:	69a2                	ld	s3,8(sp)
    800023ba:	6a02                	ld	s4,0(sp)
    800023bc:	6145                	addi	sp,sp,48
    800023be:	8082                	ret

00000000800023c0 <exit>:
{
    800023c0:	7179                	addi	sp,sp,-48
    800023c2:	f406                	sd	ra,40(sp)
    800023c4:	f022                	sd	s0,32(sp)
    800023c6:	ec26                	sd	s1,24(sp)
    800023c8:	e84a                	sd	s2,16(sp)
    800023ca:	e44e                	sd	s3,8(sp)
    800023cc:	e052                	sd	s4,0(sp)
    800023ce:	1800                	addi	s0,sp,48
    800023d0:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    800023d2:	fffff097          	auipc	ra,0xfffff
    800023d6:	6e0080e7          	jalr	1760(ra) # 80001ab2 <myproc>
    800023da:	89aa                	mv	s3,a0
  if(p == initproc)
    800023dc:	00007797          	auipc	a5,0x7
    800023e0:	c4c7b783          	ld	a5,-948(a5) # 80009028 <initproc>
    800023e4:	0d850493          	addi	s1,a0,216
    800023e8:	15850913          	addi	s2,a0,344
    800023ec:	02a79363          	bne	a5,a0,80002412 <exit+0x52>
    panic("init exiting");
    800023f0:	00006517          	auipc	a0,0x6
    800023f4:	e8850513          	addi	a0,a0,-376 # 80008278 <digits+0x238>
    800023f8:	ffffe097          	auipc	ra,0xffffe
    800023fc:	146080e7          	jalr	326(ra) # 8000053e <panic>
      fileclose(f);
    80002400:	00002097          	auipc	ra,0x2
    80002404:	1f2080e7          	jalr	498(ra) # 800045f2 <fileclose>
      p->ofile[fd] = 0;
    80002408:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    8000240c:	04a1                	addi	s1,s1,8
    8000240e:	01248563          	beq	s1,s2,80002418 <exit+0x58>
    if(p->ofile[fd]){
    80002412:	6088                	ld	a0,0(s1)
    80002414:	f575                	bnez	a0,80002400 <exit+0x40>
    80002416:	bfdd                	j	8000240c <exit+0x4c>
  begin_op();
    80002418:	00002097          	auipc	ra,0x2
    8000241c:	d0e080e7          	jalr	-754(ra) # 80004126 <begin_op>
  iput(p->cwd);
    80002420:	1589b503          	ld	a0,344(s3)
    80002424:	00001097          	auipc	ra,0x1
    80002428:	4ea080e7          	jalr	1258(ra) # 8000390e <iput>
  end_op();
    8000242c:	00002097          	auipc	ra,0x2
    80002430:	d7a080e7          	jalr	-646(ra) # 800041a6 <end_op>
  p->cwd = 0;
    80002434:	1409bc23          	sd	zero,344(s3)
  acquire(&wait_lock);
    80002438:	0000f497          	auipc	s1,0xf
    8000243c:	e8048493          	addi	s1,s1,-384 # 800112b8 <wait_lock>
    80002440:	8526                	mv	a0,s1
    80002442:	ffffe097          	auipc	ra,0xffffe
    80002446:	7a2080e7          	jalr	1954(ra) # 80000be4 <acquire>
  reparent(p);
    8000244a:	854e                	mv	a0,s3
    8000244c:	00000097          	auipc	ra,0x0
    80002450:	f1a080e7          	jalr	-230(ra) # 80002366 <reparent>
  wakeup(p->parent);
    80002454:	0409b503          	ld	a0,64(s3)
    80002458:	00000097          	auipc	ra,0x0
    8000245c:	e98080e7          	jalr	-360(ra) # 800022f0 <wakeup>
  acquire(&p->lock);
    80002460:	854e                	mv	a0,s3
    80002462:	ffffe097          	auipc	ra,0xffffe
    80002466:	782080e7          	jalr	1922(ra) # 80000be4 <acquire>
  p->xstate = status;
    8000246a:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    8000246e:	4795                	li	a5,5
    80002470:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    80002474:	8526                	mv	a0,s1
    80002476:	fffff097          	auipc	ra,0xfffff
    8000247a:	822080e7          	jalr	-2014(ra) # 80000c98 <release>
  sched();
    8000247e:	00000097          	auipc	ra,0x0
    80002482:	bd4080e7          	jalr	-1068(ra) # 80002052 <sched>
  panic("zombie exit");
    80002486:	00006517          	auipc	a0,0x6
    8000248a:	e0250513          	addi	a0,a0,-510 # 80008288 <digits+0x248>
    8000248e:	ffffe097          	auipc	ra,0xffffe
    80002492:	0b0080e7          	jalr	176(ra) # 8000053e <panic>

0000000080002496 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    80002496:	7179                	addi	sp,sp,-48
    80002498:	f406                	sd	ra,40(sp)
    8000249a:	f022                	sd	s0,32(sp)
    8000249c:	ec26                	sd	s1,24(sp)
    8000249e:	e84a                	sd	s2,16(sp)
    800024a0:	e44e                	sd	s3,8(sp)
    800024a2:	1800                	addi	s0,sp,48
    800024a4:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    800024a6:	0000f497          	auipc	s1,0xf
    800024aa:	22a48493          	addi	s1,s1,554 # 800116d0 <proc>
    800024ae:	00015997          	auipc	s3,0x15
    800024b2:	e2298993          	addi	s3,s3,-478 # 800172d0 <ready_list>
    acquire(&p->lock);
    800024b6:	8526                	mv	a0,s1
    800024b8:	ffffe097          	auipc	ra,0xffffe
    800024bc:	72c080e7          	jalr	1836(ra) # 80000be4 <acquire>
    if(p->pid == pid){
    800024c0:	589c                	lw	a5,48(s1)
    800024c2:	01278d63          	beq	a5,s2,800024dc <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    800024c6:	8526                	mv	a0,s1
    800024c8:	ffffe097          	auipc	ra,0xffffe
    800024cc:	7d0080e7          	jalr	2000(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    800024d0:	17048493          	addi	s1,s1,368
    800024d4:	ff3491e3          	bne	s1,s3,800024b6 <kill+0x20>
  }
  return -1;
    800024d8:	557d                	li	a0,-1
    800024da:	a829                	j	800024f4 <kill+0x5e>
      p->killed = 1;
    800024dc:	4785                	li	a5,1
    800024de:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    800024e0:	4c98                	lw	a4,24(s1)
    800024e2:	4789                	li	a5,2
    800024e4:	00f70f63          	beq	a4,a5,80002502 <kill+0x6c>
      release(&p->lock);
    800024e8:	8526                	mv	a0,s1
    800024ea:	ffffe097          	auipc	ra,0xffffe
    800024ee:	7ae080e7          	jalr	1966(ra) # 80000c98 <release>
      return 0;
    800024f2:	4501                	li	a0,0
}
    800024f4:	70a2                	ld	ra,40(sp)
    800024f6:	7402                	ld	s0,32(sp)
    800024f8:	64e2                	ld	s1,24(sp)
    800024fa:	6942                	ld	s2,16(sp)
    800024fc:	69a2                	ld	s3,8(sp)
    800024fe:	6145                	addi	sp,sp,48
    80002500:	8082                	ret
        p->state = RUNNABLE;
    80002502:	478d                	li	a5,3
    80002504:	cc9c                	sw	a5,24(s1)
    80002506:	b7cd                	j	800024e8 <kill+0x52>

0000000080002508 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002508:	7179                	addi	sp,sp,-48
    8000250a:	f406                	sd	ra,40(sp)
    8000250c:	f022                	sd	s0,32(sp)
    8000250e:	ec26                	sd	s1,24(sp)
    80002510:	e84a                	sd	s2,16(sp)
    80002512:	e44e                	sd	s3,8(sp)
    80002514:	e052                	sd	s4,0(sp)
    80002516:	1800                	addi	s0,sp,48
    80002518:	84aa                	mv	s1,a0
    8000251a:	892e                	mv	s2,a1
    8000251c:	89b2                	mv	s3,a2
    8000251e:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002520:	fffff097          	auipc	ra,0xfffff
    80002524:	592080e7          	jalr	1426(ra) # 80001ab2 <myproc>
  if(user_dst){
    80002528:	c08d                	beqz	s1,8000254a <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    8000252a:	86d2                	mv	a3,s4
    8000252c:	864e                	mv	a2,s3
    8000252e:	85ca                	mv	a1,s2
    80002530:	6d28                	ld	a0,88(a0)
    80002532:	fffff097          	auipc	ra,0xfffff
    80002536:	140080e7          	jalr	320(ra) # 80001672 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    8000253a:	70a2                	ld	ra,40(sp)
    8000253c:	7402                	ld	s0,32(sp)
    8000253e:	64e2                	ld	s1,24(sp)
    80002540:	6942                	ld	s2,16(sp)
    80002542:	69a2                	ld	s3,8(sp)
    80002544:	6a02                	ld	s4,0(sp)
    80002546:	6145                	addi	sp,sp,48
    80002548:	8082                	ret
    memmove((char *)dst, src, len);
    8000254a:	000a061b          	sext.w	a2,s4
    8000254e:	85ce                	mv	a1,s3
    80002550:	854a                	mv	a0,s2
    80002552:	ffffe097          	auipc	ra,0xffffe
    80002556:	7ee080e7          	jalr	2030(ra) # 80000d40 <memmove>
    return 0;
    8000255a:	8526                	mv	a0,s1
    8000255c:	bff9                	j	8000253a <either_copyout+0x32>

000000008000255e <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    8000255e:	7179                	addi	sp,sp,-48
    80002560:	f406                	sd	ra,40(sp)
    80002562:	f022                	sd	s0,32(sp)
    80002564:	ec26                	sd	s1,24(sp)
    80002566:	e84a                	sd	s2,16(sp)
    80002568:	e44e                	sd	s3,8(sp)
    8000256a:	e052                	sd	s4,0(sp)
    8000256c:	1800                	addi	s0,sp,48
    8000256e:	892a                	mv	s2,a0
    80002570:	84ae                	mv	s1,a1
    80002572:	89b2                	mv	s3,a2
    80002574:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002576:	fffff097          	auipc	ra,0xfffff
    8000257a:	53c080e7          	jalr	1340(ra) # 80001ab2 <myproc>
  if(user_src){
    8000257e:	c08d                	beqz	s1,800025a0 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    80002580:	86d2                	mv	a3,s4
    80002582:	864e                	mv	a2,s3
    80002584:	85ca                	mv	a1,s2
    80002586:	6d28                	ld	a0,88(a0)
    80002588:	fffff097          	auipc	ra,0xfffff
    8000258c:	176080e7          	jalr	374(ra) # 800016fe <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    80002590:	70a2                	ld	ra,40(sp)
    80002592:	7402                	ld	s0,32(sp)
    80002594:	64e2                	ld	s1,24(sp)
    80002596:	6942                	ld	s2,16(sp)
    80002598:	69a2                	ld	s3,8(sp)
    8000259a:	6a02                	ld	s4,0(sp)
    8000259c:	6145                	addi	sp,sp,48
    8000259e:	8082                	ret
    memmove(dst, (char*)src, len);
    800025a0:	000a061b          	sext.w	a2,s4
    800025a4:	85ce                	mv	a1,s3
    800025a6:	854a                	mv	a0,s2
    800025a8:	ffffe097          	auipc	ra,0xffffe
    800025ac:	798080e7          	jalr	1944(ra) # 80000d40 <memmove>
    return 0;
    800025b0:	8526                	mv	a0,s1
    800025b2:	bff9                	j	80002590 <either_copyin+0x32>

00000000800025b4 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    800025b4:	715d                	addi	sp,sp,-80
    800025b6:	e486                	sd	ra,72(sp)
    800025b8:	e0a2                	sd	s0,64(sp)
    800025ba:	fc26                	sd	s1,56(sp)
    800025bc:	f84a                	sd	s2,48(sp)
    800025be:	f44e                	sd	s3,40(sp)
    800025c0:	f052                	sd	s4,32(sp)
    800025c2:	ec56                	sd	s5,24(sp)
    800025c4:	e85a                	sd	s6,16(sp)
    800025c6:	e45e                	sd	s7,8(sp)
    800025c8:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    800025ca:	00006517          	auipc	a0,0x6
    800025ce:	afe50513          	addi	a0,a0,-1282 # 800080c8 <digits+0x88>
    800025d2:	ffffe097          	auipc	ra,0xffffe
    800025d6:	fb6080e7          	jalr	-74(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800025da:	0000f497          	auipc	s1,0xf
    800025de:	25648493          	addi	s1,s1,598 # 80011830 <proc+0x160>
    800025e2:	00015917          	auipc	s2,0x15
    800025e6:	e4e90913          	addi	s2,s2,-434 # 80017430 <bcache+0x128>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800025ea:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    800025ec:	00006997          	auipc	s3,0x6
    800025f0:	cac98993          	addi	s3,s3,-852 # 80008298 <digits+0x258>
    printf("%d %s %s", p->pid, state, p->name);
    800025f4:	00006a97          	auipc	s5,0x6
    800025f8:	caca8a93          	addi	s5,s5,-852 # 800082a0 <digits+0x260>
    printf("\n");
    800025fc:	00006a17          	auipc	s4,0x6
    80002600:	acca0a13          	addi	s4,s4,-1332 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002604:	00006b97          	auipc	s7,0x6
    80002608:	cd4b8b93          	addi	s7,s7,-812 # 800082d8 <states.1748>
    8000260c:	a00d                	j	8000262e <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    8000260e:	ed06a583          	lw	a1,-304(a3)
    80002612:	8556                	mv	a0,s5
    80002614:	ffffe097          	auipc	ra,0xffffe
    80002618:	f74080e7          	jalr	-140(ra) # 80000588 <printf>
    printf("\n");
    8000261c:	8552                	mv	a0,s4
    8000261e:	ffffe097          	auipc	ra,0xffffe
    80002622:	f6a080e7          	jalr	-150(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002626:	17048493          	addi	s1,s1,368
    8000262a:	03248163          	beq	s1,s2,8000264c <procdump+0x98>
    if(p->state == UNUSED)
    8000262e:	86a6                	mv	a3,s1
    80002630:	eb84a783          	lw	a5,-328(s1)
    80002634:	dbed                	beqz	a5,80002626 <procdump+0x72>
      state = "???";
    80002636:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002638:	fcfb6be3          	bltu	s6,a5,8000260e <procdump+0x5a>
    8000263c:	1782                	slli	a5,a5,0x20
    8000263e:	9381                	srli	a5,a5,0x20
    80002640:	078e                	slli	a5,a5,0x3
    80002642:	97de                	add	a5,a5,s7
    80002644:	6390                	ld	a2,0(a5)
    80002646:	f661                	bnez	a2,8000260e <procdump+0x5a>
      state = "???";
    80002648:	864e                	mv	a2,s3
    8000264a:	b7d1                	j	8000260e <procdump+0x5a>
  }
}
    8000264c:	60a6                	ld	ra,72(sp)
    8000264e:	6406                	ld	s0,64(sp)
    80002650:	74e2                	ld	s1,56(sp)
    80002652:	7942                	ld	s2,48(sp)
    80002654:	79a2                	ld	s3,40(sp)
    80002656:	7a02                	ld	s4,32(sp)
    80002658:	6ae2                	ld	s5,24(sp)
    8000265a:	6b42                	ld	s6,16(sp)
    8000265c:	6ba2                	ld	s7,8(sp)
    8000265e:	6161                	addi	sp,sp,80
    80002660:	8082                	ret

0000000080002662 <set_cpu>:

int 
set_cpu(int cpu_num)
{
  if(cpu_num<0 || cpu_num>NCPU){
    80002662:	47a1                	li	a5,8
    80002664:	02a7e763          	bltu	a5,a0,80002692 <set_cpu+0x30>
{
    80002668:	1101                	addi	sp,sp,-32
    8000266a:	ec06                	sd	ra,24(sp)
    8000266c:	e822                	sd	s0,16(sp)
    8000266e:	e426                	sd	s1,8(sp)
    80002670:	1000                	addi	s0,sp,32
    80002672:	84aa                	mv	s1,a0
    return -1;
  }
  myproc()->cpu_id = cpu_num;
    80002674:	fffff097          	auipc	ra,0xfffff
    80002678:	43e080e7          	jalr	1086(ra) # 80001ab2 <myproc>
    8000267c:	dd04                	sw	s1,56(a0)
  yield();
    8000267e:	00000097          	auipc	ra,0x0
    80002682:	aaa080e7          	jalr	-1366(ra) # 80002128 <yield>
  return cpu_num;
    80002686:	8526                	mv	a0,s1
}
    80002688:	60e2                	ld	ra,24(sp)
    8000268a:	6442                	ld	s0,16(sp)
    8000268c:	64a2                	ld	s1,8(sp)
    8000268e:	6105                	addi	sp,sp,32
    80002690:	8082                	ret
    return -1;
    80002692:	557d                	li	a0,-1
}
    80002694:	8082                	ret

0000000080002696 <get_cpu>:

int 
get_cpu()
{
    80002696:	1141                	addi	sp,sp,-16
    80002698:	e422                	sd	s0,8(sp)
    8000269a:	0800                	addi	s0,sp,16
    8000269c:	8512                	mv	a0,tp
  return cpuid();
}
    8000269e:	2501                	sext.w	a0,a0
    800026a0:	6422                	ld	s0,8(sp)
    800026a2:	0141                	addi	sp,sp,16
    800026a4:	8082                	ret

00000000800026a6 <swtch>:
    800026a6:	00153023          	sd	ra,0(a0)
    800026aa:	00253423          	sd	sp,8(a0)
    800026ae:	e900                	sd	s0,16(a0)
    800026b0:	ed04                	sd	s1,24(a0)
    800026b2:	03253023          	sd	s2,32(a0)
    800026b6:	03353423          	sd	s3,40(a0)
    800026ba:	03453823          	sd	s4,48(a0)
    800026be:	03553c23          	sd	s5,56(a0)
    800026c2:	05653023          	sd	s6,64(a0)
    800026c6:	05753423          	sd	s7,72(a0)
    800026ca:	05853823          	sd	s8,80(a0)
    800026ce:	05953c23          	sd	s9,88(a0)
    800026d2:	07a53023          	sd	s10,96(a0)
    800026d6:	07b53423          	sd	s11,104(a0)
    800026da:	0005b083          	ld	ra,0(a1)
    800026de:	0085b103          	ld	sp,8(a1)
    800026e2:	6980                	ld	s0,16(a1)
    800026e4:	6d84                	ld	s1,24(a1)
    800026e6:	0205b903          	ld	s2,32(a1)
    800026ea:	0285b983          	ld	s3,40(a1)
    800026ee:	0305ba03          	ld	s4,48(a1)
    800026f2:	0385ba83          	ld	s5,56(a1)
    800026f6:	0405bb03          	ld	s6,64(a1)
    800026fa:	0485bb83          	ld	s7,72(a1)
    800026fe:	0505bc03          	ld	s8,80(a1)
    80002702:	0585bc83          	ld	s9,88(a1)
    80002706:	0605bd03          	ld	s10,96(a1)
    8000270a:	0685bd83          	ld	s11,104(a1)
    8000270e:	8082                	ret

0000000080002710 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002710:	1141                	addi	sp,sp,-16
    80002712:	e406                	sd	ra,8(sp)
    80002714:	e022                	sd	s0,0(sp)
    80002716:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002718:	00006597          	auipc	a1,0x6
    8000271c:	bf058593          	addi	a1,a1,-1040 # 80008308 <states.1748+0x30>
    80002720:	00015517          	auipc	a0,0x15
    80002724:	bd050513          	addi	a0,a0,-1072 # 800172f0 <tickslock>
    80002728:	ffffe097          	auipc	ra,0xffffe
    8000272c:	42c080e7          	jalr	1068(ra) # 80000b54 <initlock>
}
    80002730:	60a2                	ld	ra,8(sp)
    80002732:	6402                	ld	s0,0(sp)
    80002734:	0141                	addi	sp,sp,16
    80002736:	8082                	ret

0000000080002738 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002738:	1141                	addi	sp,sp,-16
    8000273a:	e422                	sd	s0,8(sp)
    8000273c:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000273e:	00003797          	auipc	a5,0x3
    80002742:	4d278793          	addi	a5,a5,1234 # 80005c10 <kernelvec>
    80002746:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    8000274a:	6422                	ld	s0,8(sp)
    8000274c:	0141                	addi	sp,sp,16
    8000274e:	8082                	ret

0000000080002750 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002750:	1141                	addi	sp,sp,-16
    80002752:	e406                	sd	ra,8(sp)
    80002754:	e022                	sd	s0,0(sp)
    80002756:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002758:	fffff097          	auipc	ra,0xfffff
    8000275c:	35a080e7          	jalr	858(ra) # 80001ab2 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002760:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002764:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002766:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    8000276a:	00005617          	auipc	a2,0x5
    8000276e:	89660613          	addi	a2,a2,-1898 # 80007000 <_trampoline>
    80002772:	00005697          	auipc	a3,0x5
    80002776:	88e68693          	addi	a3,a3,-1906 # 80007000 <_trampoline>
    8000277a:	8e91                	sub	a3,a3,a2
    8000277c:	040007b7          	lui	a5,0x4000
    80002780:	17fd                	addi	a5,a5,-1
    80002782:	07b2                	slli	a5,a5,0xc
    80002784:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002786:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    8000278a:	7138                	ld	a4,96(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    8000278c:	180026f3          	csrr	a3,satp
    80002790:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002792:	7138                	ld	a4,96(a0)
    80002794:	6534                	ld	a3,72(a0)
    80002796:	6585                	lui	a1,0x1
    80002798:	96ae                	add	a3,a3,a1
    8000279a:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    8000279c:	7138                	ld	a4,96(a0)
    8000279e:	00000697          	auipc	a3,0x0
    800027a2:	13868693          	addi	a3,a3,312 # 800028d6 <usertrap>
    800027a6:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    800027a8:	7138                	ld	a4,96(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    800027aa:	8692                	mv	a3,tp
    800027ac:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800027ae:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    800027b2:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    800027b6:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800027ba:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    800027be:	7138                	ld	a4,96(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    800027c0:	6f18                	ld	a4,24(a4)
    800027c2:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    800027c6:	6d2c                	ld	a1,88(a0)
    800027c8:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    800027ca:	00005717          	auipc	a4,0x5
    800027ce:	8c670713          	addi	a4,a4,-1850 # 80007090 <userret>
    800027d2:	8f11                	sub	a4,a4,a2
    800027d4:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    800027d6:	577d                	li	a4,-1
    800027d8:	177e                	slli	a4,a4,0x3f
    800027da:	8dd9                	or	a1,a1,a4
    800027dc:	02000537          	lui	a0,0x2000
    800027e0:	157d                	addi	a0,a0,-1
    800027e2:	0536                	slli	a0,a0,0xd
    800027e4:	9782                	jalr	a5
}
    800027e6:	60a2                	ld	ra,8(sp)
    800027e8:	6402                	ld	s0,0(sp)
    800027ea:	0141                	addi	sp,sp,16
    800027ec:	8082                	ret

00000000800027ee <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    800027ee:	1101                	addi	sp,sp,-32
    800027f0:	ec06                	sd	ra,24(sp)
    800027f2:	e822                	sd	s0,16(sp)
    800027f4:	e426                	sd	s1,8(sp)
    800027f6:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    800027f8:	00015497          	auipc	s1,0x15
    800027fc:	af848493          	addi	s1,s1,-1288 # 800172f0 <tickslock>
    80002800:	8526                	mv	a0,s1
    80002802:	ffffe097          	auipc	ra,0xffffe
    80002806:	3e2080e7          	jalr	994(ra) # 80000be4 <acquire>
  ticks++;
    8000280a:	00007517          	auipc	a0,0x7
    8000280e:	83250513          	addi	a0,a0,-1998 # 8000903c <ticks>
    80002812:	411c                	lw	a5,0(a0)
    80002814:	2785                	addiw	a5,a5,1
    80002816:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002818:	00000097          	auipc	ra,0x0
    8000281c:	ad8080e7          	jalr	-1320(ra) # 800022f0 <wakeup>
  release(&tickslock);
    80002820:	8526                	mv	a0,s1
    80002822:	ffffe097          	auipc	ra,0xffffe
    80002826:	476080e7          	jalr	1142(ra) # 80000c98 <release>
}
    8000282a:	60e2                	ld	ra,24(sp)
    8000282c:	6442                	ld	s0,16(sp)
    8000282e:	64a2                	ld	s1,8(sp)
    80002830:	6105                	addi	sp,sp,32
    80002832:	8082                	ret

0000000080002834 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002834:	1101                	addi	sp,sp,-32
    80002836:	ec06                	sd	ra,24(sp)
    80002838:	e822                	sd	s0,16(sp)
    8000283a:	e426                	sd	s1,8(sp)
    8000283c:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000283e:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002842:	00074d63          	bltz	a4,8000285c <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002846:	57fd                	li	a5,-1
    80002848:	17fe                	slli	a5,a5,0x3f
    8000284a:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    8000284c:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    8000284e:	06f70363          	beq	a4,a5,800028b4 <devintr+0x80>
  }
}
    80002852:	60e2                	ld	ra,24(sp)
    80002854:	6442                	ld	s0,16(sp)
    80002856:	64a2                	ld	s1,8(sp)
    80002858:	6105                	addi	sp,sp,32
    8000285a:	8082                	ret
     (scause & 0xff) == 9){
    8000285c:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002860:	46a5                	li	a3,9
    80002862:	fed792e3          	bne	a5,a3,80002846 <devintr+0x12>
    int irq = plic_claim();
    80002866:	00003097          	auipc	ra,0x3
    8000286a:	4b2080e7          	jalr	1202(ra) # 80005d18 <plic_claim>
    8000286e:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002870:	47a9                	li	a5,10
    80002872:	02f50763          	beq	a0,a5,800028a0 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002876:	4785                	li	a5,1
    80002878:	02f50963          	beq	a0,a5,800028aa <devintr+0x76>
    return 1;
    8000287c:	4505                	li	a0,1
    } else if(irq){
    8000287e:	d8f1                	beqz	s1,80002852 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002880:	85a6                	mv	a1,s1
    80002882:	00006517          	auipc	a0,0x6
    80002886:	a8e50513          	addi	a0,a0,-1394 # 80008310 <states.1748+0x38>
    8000288a:	ffffe097          	auipc	ra,0xffffe
    8000288e:	cfe080e7          	jalr	-770(ra) # 80000588 <printf>
      plic_complete(irq);
    80002892:	8526                	mv	a0,s1
    80002894:	00003097          	auipc	ra,0x3
    80002898:	4a8080e7          	jalr	1192(ra) # 80005d3c <plic_complete>
    return 1;
    8000289c:	4505                	li	a0,1
    8000289e:	bf55                	j	80002852 <devintr+0x1e>
      uartintr();
    800028a0:	ffffe097          	auipc	ra,0xffffe
    800028a4:	108080e7          	jalr	264(ra) # 800009a8 <uartintr>
    800028a8:	b7ed                	j	80002892 <devintr+0x5e>
      virtio_disk_intr();
    800028aa:	00004097          	auipc	ra,0x4
    800028ae:	972080e7          	jalr	-1678(ra) # 8000621c <virtio_disk_intr>
    800028b2:	b7c5                	j	80002892 <devintr+0x5e>
    if(cpuid() == 0){
    800028b4:	fffff097          	auipc	ra,0xfffff
    800028b8:	1d2080e7          	jalr	466(ra) # 80001a86 <cpuid>
    800028bc:	c901                	beqz	a0,800028cc <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    800028be:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    800028c2:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    800028c4:	14479073          	csrw	sip,a5
    return 2;
    800028c8:	4509                	li	a0,2
    800028ca:	b761                	j	80002852 <devintr+0x1e>
      clockintr();
    800028cc:	00000097          	auipc	ra,0x0
    800028d0:	f22080e7          	jalr	-222(ra) # 800027ee <clockintr>
    800028d4:	b7ed                	j	800028be <devintr+0x8a>

00000000800028d6 <usertrap>:
{
    800028d6:	1101                	addi	sp,sp,-32
    800028d8:	ec06                	sd	ra,24(sp)
    800028da:	e822                	sd	s0,16(sp)
    800028dc:	e426                	sd	s1,8(sp)
    800028de:	e04a                	sd	s2,0(sp)
    800028e0:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800028e2:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    800028e6:	1007f793          	andi	a5,a5,256
    800028ea:	e3ad                	bnez	a5,8000294c <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    800028ec:	00003797          	auipc	a5,0x3
    800028f0:	32478793          	addi	a5,a5,804 # 80005c10 <kernelvec>
    800028f4:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    800028f8:	fffff097          	auipc	ra,0xfffff
    800028fc:	1ba080e7          	jalr	442(ra) # 80001ab2 <myproc>
    80002900:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002902:	713c                	ld	a5,96(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002904:	14102773          	csrr	a4,sepc
    80002908:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000290a:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    8000290e:	47a1                	li	a5,8
    80002910:	04f71c63          	bne	a4,a5,80002968 <usertrap+0x92>
    if(p->killed)
    80002914:	551c                	lw	a5,40(a0)
    80002916:	e3b9                	bnez	a5,8000295c <usertrap+0x86>
    p->trapframe->epc += 4;
    80002918:	70b8                	ld	a4,96(s1)
    8000291a:	6f1c                	ld	a5,24(a4)
    8000291c:	0791                	addi	a5,a5,4
    8000291e:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002920:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002924:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002928:	10079073          	csrw	sstatus,a5
    syscall();
    8000292c:	00000097          	auipc	ra,0x0
    80002930:	2e0080e7          	jalr	736(ra) # 80002c0c <syscall>
  if(p->killed)
    80002934:	549c                	lw	a5,40(s1)
    80002936:	ebc1                	bnez	a5,800029c6 <usertrap+0xf0>
  usertrapret();
    80002938:	00000097          	auipc	ra,0x0
    8000293c:	e18080e7          	jalr	-488(ra) # 80002750 <usertrapret>
}
    80002940:	60e2                	ld	ra,24(sp)
    80002942:	6442                	ld	s0,16(sp)
    80002944:	64a2                	ld	s1,8(sp)
    80002946:	6902                	ld	s2,0(sp)
    80002948:	6105                	addi	sp,sp,32
    8000294a:	8082                	ret
    panic("usertrap: not from user mode");
    8000294c:	00006517          	auipc	a0,0x6
    80002950:	9e450513          	addi	a0,a0,-1564 # 80008330 <states.1748+0x58>
    80002954:	ffffe097          	auipc	ra,0xffffe
    80002958:	bea080e7          	jalr	-1046(ra) # 8000053e <panic>
      exit(-1);
    8000295c:	557d                	li	a0,-1
    8000295e:	00000097          	auipc	ra,0x0
    80002962:	a62080e7          	jalr	-1438(ra) # 800023c0 <exit>
    80002966:	bf4d                	j	80002918 <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    80002968:	00000097          	auipc	ra,0x0
    8000296c:	ecc080e7          	jalr	-308(ra) # 80002834 <devintr>
    80002970:	892a                	mv	s2,a0
    80002972:	c501                	beqz	a0,8000297a <usertrap+0xa4>
  if(p->killed)
    80002974:	549c                	lw	a5,40(s1)
    80002976:	c3a1                	beqz	a5,800029b6 <usertrap+0xe0>
    80002978:	a815                	j	800029ac <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000297a:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    8000297e:	5890                	lw	a2,48(s1)
    80002980:	00006517          	auipc	a0,0x6
    80002984:	9d050513          	addi	a0,a0,-1584 # 80008350 <states.1748+0x78>
    80002988:	ffffe097          	auipc	ra,0xffffe
    8000298c:	c00080e7          	jalr	-1024(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002990:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002994:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002998:	00006517          	auipc	a0,0x6
    8000299c:	9e850513          	addi	a0,a0,-1560 # 80008380 <states.1748+0xa8>
    800029a0:	ffffe097          	auipc	ra,0xffffe
    800029a4:	be8080e7          	jalr	-1048(ra) # 80000588 <printf>
    p->killed = 1;
    800029a8:	4785                	li	a5,1
    800029aa:	d49c                	sw	a5,40(s1)
    exit(-1);
    800029ac:	557d                	li	a0,-1
    800029ae:	00000097          	auipc	ra,0x0
    800029b2:	a12080e7          	jalr	-1518(ra) # 800023c0 <exit>
  if(which_dev == 2)
    800029b6:	4789                	li	a5,2
    800029b8:	f8f910e3          	bne	s2,a5,80002938 <usertrap+0x62>
    yield();
    800029bc:	fffff097          	auipc	ra,0xfffff
    800029c0:	76c080e7          	jalr	1900(ra) # 80002128 <yield>
    800029c4:	bf95                	j	80002938 <usertrap+0x62>
  int which_dev = 0;
    800029c6:	4901                	li	s2,0
    800029c8:	b7d5                	j	800029ac <usertrap+0xd6>

00000000800029ca <kerneltrap>:
{
    800029ca:	7179                	addi	sp,sp,-48
    800029cc:	f406                	sd	ra,40(sp)
    800029ce:	f022                	sd	s0,32(sp)
    800029d0:	ec26                	sd	s1,24(sp)
    800029d2:	e84a                	sd	s2,16(sp)
    800029d4:	e44e                	sd	s3,8(sp)
    800029d6:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800029d8:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029dc:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    800029e0:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    800029e4:	1004f793          	andi	a5,s1,256
    800029e8:	cb85                	beqz	a5,80002a18 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029ea:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800029ee:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    800029f0:	ef85                	bnez	a5,80002a28 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    800029f2:	00000097          	auipc	ra,0x0
    800029f6:	e42080e7          	jalr	-446(ra) # 80002834 <devintr>
    800029fa:	cd1d                	beqz	a0,80002a38 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    800029fc:	4789                	li	a5,2
    800029fe:	06f50a63          	beq	a0,a5,80002a72 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002a02:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002a06:	10049073          	csrw	sstatus,s1
}
    80002a0a:	70a2                	ld	ra,40(sp)
    80002a0c:	7402                	ld	s0,32(sp)
    80002a0e:	64e2                	ld	s1,24(sp)
    80002a10:	6942                	ld	s2,16(sp)
    80002a12:	69a2                	ld	s3,8(sp)
    80002a14:	6145                	addi	sp,sp,48
    80002a16:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002a18:	00006517          	auipc	a0,0x6
    80002a1c:	98850513          	addi	a0,a0,-1656 # 800083a0 <states.1748+0xc8>
    80002a20:	ffffe097          	auipc	ra,0xffffe
    80002a24:	b1e080e7          	jalr	-1250(ra) # 8000053e <panic>
    panic("kerneltrap: interrupts enabled");
    80002a28:	00006517          	auipc	a0,0x6
    80002a2c:	9a050513          	addi	a0,a0,-1632 # 800083c8 <states.1748+0xf0>
    80002a30:	ffffe097          	auipc	ra,0xffffe
    80002a34:	b0e080e7          	jalr	-1266(ra) # 8000053e <panic>
    printf("scause %p\n", scause);
    80002a38:	85ce                	mv	a1,s3
    80002a3a:	00006517          	auipc	a0,0x6
    80002a3e:	9ae50513          	addi	a0,a0,-1618 # 800083e8 <states.1748+0x110>
    80002a42:	ffffe097          	auipc	ra,0xffffe
    80002a46:	b46080e7          	jalr	-1210(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a4a:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002a4e:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002a52:	00006517          	auipc	a0,0x6
    80002a56:	9a650513          	addi	a0,a0,-1626 # 800083f8 <states.1748+0x120>
    80002a5a:	ffffe097          	auipc	ra,0xffffe
    80002a5e:	b2e080e7          	jalr	-1234(ra) # 80000588 <printf>
    panic("kerneltrap");
    80002a62:	00006517          	auipc	a0,0x6
    80002a66:	9ae50513          	addi	a0,a0,-1618 # 80008410 <states.1748+0x138>
    80002a6a:	ffffe097          	auipc	ra,0xffffe
    80002a6e:	ad4080e7          	jalr	-1324(ra) # 8000053e <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002a72:	fffff097          	auipc	ra,0xfffff
    80002a76:	040080e7          	jalr	64(ra) # 80001ab2 <myproc>
    80002a7a:	d541                	beqz	a0,80002a02 <kerneltrap+0x38>
    80002a7c:	fffff097          	auipc	ra,0xfffff
    80002a80:	036080e7          	jalr	54(ra) # 80001ab2 <myproc>
    80002a84:	4d18                	lw	a4,24(a0)
    80002a86:	4791                	li	a5,4
    80002a88:	f6f71de3          	bne	a4,a5,80002a02 <kerneltrap+0x38>
    yield();
    80002a8c:	fffff097          	auipc	ra,0xfffff
    80002a90:	69c080e7          	jalr	1692(ra) # 80002128 <yield>
    80002a94:	b7bd                	j	80002a02 <kerneltrap+0x38>

0000000080002a96 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002a96:	1101                	addi	sp,sp,-32
    80002a98:	ec06                	sd	ra,24(sp)
    80002a9a:	e822                	sd	s0,16(sp)
    80002a9c:	e426                	sd	s1,8(sp)
    80002a9e:	1000                	addi	s0,sp,32
    80002aa0:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002aa2:	fffff097          	auipc	ra,0xfffff
    80002aa6:	010080e7          	jalr	16(ra) # 80001ab2 <myproc>
  switch (n) {
    80002aaa:	4795                	li	a5,5
    80002aac:	0497e163          	bltu	a5,s1,80002aee <argraw+0x58>
    80002ab0:	048a                	slli	s1,s1,0x2
    80002ab2:	00006717          	auipc	a4,0x6
    80002ab6:	99670713          	addi	a4,a4,-1642 # 80008448 <states.1748+0x170>
    80002aba:	94ba                	add	s1,s1,a4
    80002abc:	409c                	lw	a5,0(s1)
    80002abe:	97ba                	add	a5,a5,a4
    80002ac0:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002ac2:	713c                	ld	a5,96(a0)
    80002ac4:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002ac6:	60e2                	ld	ra,24(sp)
    80002ac8:	6442                	ld	s0,16(sp)
    80002aca:	64a2                	ld	s1,8(sp)
    80002acc:	6105                	addi	sp,sp,32
    80002ace:	8082                	ret
    return p->trapframe->a1;
    80002ad0:	713c                	ld	a5,96(a0)
    80002ad2:	7fa8                	ld	a0,120(a5)
    80002ad4:	bfcd                	j	80002ac6 <argraw+0x30>
    return p->trapframe->a2;
    80002ad6:	713c                	ld	a5,96(a0)
    80002ad8:	63c8                	ld	a0,128(a5)
    80002ada:	b7f5                	j	80002ac6 <argraw+0x30>
    return p->trapframe->a3;
    80002adc:	713c                	ld	a5,96(a0)
    80002ade:	67c8                	ld	a0,136(a5)
    80002ae0:	b7dd                	j	80002ac6 <argraw+0x30>
    return p->trapframe->a4;
    80002ae2:	713c                	ld	a5,96(a0)
    80002ae4:	6bc8                	ld	a0,144(a5)
    80002ae6:	b7c5                	j	80002ac6 <argraw+0x30>
    return p->trapframe->a5;
    80002ae8:	713c                	ld	a5,96(a0)
    80002aea:	6fc8                	ld	a0,152(a5)
    80002aec:	bfe9                	j	80002ac6 <argraw+0x30>
  panic("argraw");
    80002aee:	00006517          	auipc	a0,0x6
    80002af2:	93250513          	addi	a0,a0,-1742 # 80008420 <states.1748+0x148>
    80002af6:	ffffe097          	auipc	ra,0xffffe
    80002afa:	a48080e7          	jalr	-1464(ra) # 8000053e <panic>

0000000080002afe <fetchaddr>:
{
    80002afe:	1101                	addi	sp,sp,-32
    80002b00:	ec06                	sd	ra,24(sp)
    80002b02:	e822                	sd	s0,16(sp)
    80002b04:	e426                	sd	s1,8(sp)
    80002b06:	e04a                	sd	s2,0(sp)
    80002b08:	1000                	addi	s0,sp,32
    80002b0a:	84aa                	mv	s1,a0
    80002b0c:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002b0e:	fffff097          	auipc	ra,0xfffff
    80002b12:	fa4080e7          	jalr	-92(ra) # 80001ab2 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002b16:	693c                	ld	a5,80(a0)
    80002b18:	02f4f863          	bgeu	s1,a5,80002b48 <fetchaddr+0x4a>
    80002b1c:	00848713          	addi	a4,s1,8
    80002b20:	02e7e663          	bltu	a5,a4,80002b4c <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002b24:	46a1                	li	a3,8
    80002b26:	8626                	mv	a2,s1
    80002b28:	85ca                	mv	a1,s2
    80002b2a:	6d28                	ld	a0,88(a0)
    80002b2c:	fffff097          	auipc	ra,0xfffff
    80002b30:	bd2080e7          	jalr	-1070(ra) # 800016fe <copyin>
    80002b34:	00a03533          	snez	a0,a0
    80002b38:	40a00533          	neg	a0,a0
}
    80002b3c:	60e2                	ld	ra,24(sp)
    80002b3e:	6442                	ld	s0,16(sp)
    80002b40:	64a2                	ld	s1,8(sp)
    80002b42:	6902                	ld	s2,0(sp)
    80002b44:	6105                	addi	sp,sp,32
    80002b46:	8082                	ret
    return -1;
    80002b48:	557d                	li	a0,-1
    80002b4a:	bfcd                	j	80002b3c <fetchaddr+0x3e>
    80002b4c:	557d                	li	a0,-1
    80002b4e:	b7fd                	j	80002b3c <fetchaddr+0x3e>

0000000080002b50 <fetchstr>:
{
    80002b50:	7179                	addi	sp,sp,-48
    80002b52:	f406                	sd	ra,40(sp)
    80002b54:	f022                	sd	s0,32(sp)
    80002b56:	ec26                	sd	s1,24(sp)
    80002b58:	e84a                	sd	s2,16(sp)
    80002b5a:	e44e                	sd	s3,8(sp)
    80002b5c:	1800                	addi	s0,sp,48
    80002b5e:	892a                	mv	s2,a0
    80002b60:	84ae                	mv	s1,a1
    80002b62:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002b64:	fffff097          	auipc	ra,0xfffff
    80002b68:	f4e080e7          	jalr	-178(ra) # 80001ab2 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002b6c:	86ce                	mv	a3,s3
    80002b6e:	864a                	mv	a2,s2
    80002b70:	85a6                	mv	a1,s1
    80002b72:	6d28                	ld	a0,88(a0)
    80002b74:	fffff097          	auipc	ra,0xfffff
    80002b78:	c16080e7          	jalr	-1002(ra) # 8000178a <copyinstr>
  if(err < 0)
    80002b7c:	00054763          	bltz	a0,80002b8a <fetchstr+0x3a>
  return strlen(buf);
    80002b80:	8526                	mv	a0,s1
    80002b82:	ffffe097          	auipc	ra,0xffffe
    80002b86:	2e2080e7          	jalr	738(ra) # 80000e64 <strlen>
}
    80002b8a:	70a2                	ld	ra,40(sp)
    80002b8c:	7402                	ld	s0,32(sp)
    80002b8e:	64e2                	ld	s1,24(sp)
    80002b90:	6942                	ld	s2,16(sp)
    80002b92:	69a2                	ld	s3,8(sp)
    80002b94:	6145                	addi	sp,sp,48
    80002b96:	8082                	ret

0000000080002b98 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002b98:	1101                	addi	sp,sp,-32
    80002b9a:	ec06                	sd	ra,24(sp)
    80002b9c:	e822                	sd	s0,16(sp)
    80002b9e:	e426                	sd	s1,8(sp)
    80002ba0:	1000                	addi	s0,sp,32
    80002ba2:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002ba4:	00000097          	auipc	ra,0x0
    80002ba8:	ef2080e7          	jalr	-270(ra) # 80002a96 <argraw>
    80002bac:	c088                	sw	a0,0(s1)
  return 0;
}
    80002bae:	4501                	li	a0,0
    80002bb0:	60e2                	ld	ra,24(sp)
    80002bb2:	6442                	ld	s0,16(sp)
    80002bb4:	64a2                	ld	s1,8(sp)
    80002bb6:	6105                	addi	sp,sp,32
    80002bb8:	8082                	ret

0000000080002bba <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002bba:	1101                	addi	sp,sp,-32
    80002bbc:	ec06                	sd	ra,24(sp)
    80002bbe:	e822                	sd	s0,16(sp)
    80002bc0:	e426                	sd	s1,8(sp)
    80002bc2:	1000                	addi	s0,sp,32
    80002bc4:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002bc6:	00000097          	auipc	ra,0x0
    80002bca:	ed0080e7          	jalr	-304(ra) # 80002a96 <argraw>
    80002bce:	e088                	sd	a0,0(s1)
  return 0;
}
    80002bd0:	4501                	li	a0,0
    80002bd2:	60e2                	ld	ra,24(sp)
    80002bd4:	6442                	ld	s0,16(sp)
    80002bd6:	64a2                	ld	s1,8(sp)
    80002bd8:	6105                	addi	sp,sp,32
    80002bda:	8082                	ret

0000000080002bdc <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002bdc:	1101                	addi	sp,sp,-32
    80002bde:	ec06                	sd	ra,24(sp)
    80002be0:	e822                	sd	s0,16(sp)
    80002be2:	e426                	sd	s1,8(sp)
    80002be4:	e04a                	sd	s2,0(sp)
    80002be6:	1000                	addi	s0,sp,32
    80002be8:	84ae                	mv	s1,a1
    80002bea:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002bec:	00000097          	auipc	ra,0x0
    80002bf0:	eaa080e7          	jalr	-342(ra) # 80002a96 <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002bf4:	864a                	mv	a2,s2
    80002bf6:	85a6                	mv	a1,s1
    80002bf8:	00000097          	auipc	ra,0x0
    80002bfc:	f58080e7          	jalr	-168(ra) # 80002b50 <fetchstr>
}
    80002c00:	60e2                	ld	ra,24(sp)
    80002c02:	6442                	ld	s0,16(sp)
    80002c04:	64a2                	ld	s1,8(sp)
    80002c06:	6902                	ld	s2,0(sp)
    80002c08:	6105                	addi	sp,sp,32
    80002c0a:	8082                	ret

0000000080002c0c <syscall>:
[SYS_get_cpu] sys_get_cpu
};

void
syscall(void)
{
    80002c0c:	1101                	addi	sp,sp,-32
    80002c0e:	ec06                	sd	ra,24(sp)
    80002c10:	e822                	sd	s0,16(sp)
    80002c12:	e426                	sd	s1,8(sp)
    80002c14:	e04a                	sd	s2,0(sp)
    80002c16:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002c18:	fffff097          	auipc	ra,0xfffff
    80002c1c:	e9a080e7          	jalr	-358(ra) # 80001ab2 <myproc>
    80002c20:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002c22:	06053903          	ld	s2,96(a0)
    80002c26:	0a893783          	ld	a5,168(s2)
    80002c2a:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002c2e:	37fd                	addiw	a5,a5,-1
    80002c30:	4759                	li	a4,22
    80002c32:	00f76f63          	bltu	a4,a5,80002c50 <syscall+0x44>
    80002c36:	00369713          	slli	a4,a3,0x3
    80002c3a:	00006797          	auipc	a5,0x6
    80002c3e:	82678793          	addi	a5,a5,-2010 # 80008460 <syscalls>
    80002c42:	97ba                	add	a5,a5,a4
    80002c44:	639c                	ld	a5,0(a5)
    80002c46:	c789                	beqz	a5,80002c50 <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    80002c48:	9782                	jalr	a5
    80002c4a:	06a93823          	sd	a0,112(s2)
    80002c4e:	a839                	j	80002c6c <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002c50:	16048613          	addi	a2,s1,352
    80002c54:	588c                	lw	a1,48(s1)
    80002c56:	00005517          	auipc	a0,0x5
    80002c5a:	7d250513          	addi	a0,a0,2002 # 80008428 <states.1748+0x150>
    80002c5e:	ffffe097          	auipc	ra,0xffffe
    80002c62:	92a080e7          	jalr	-1750(ra) # 80000588 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002c66:	70bc                	ld	a5,96(s1)
    80002c68:	577d                	li	a4,-1
    80002c6a:	fbb8                	sd	a4,112(a5)
  }
}
    80002c6c:	60e2                	ld	ra,24(sp)
    80002c6e:	6442                	ld	s0,16(sp)
    80002c70:	64a2                	ld	s1,8(sp)
    80002c72:	6902                	ld	s2,0(sp)
    80002c74:	6105                	addi	sp,sp,32
    80002c76:	8082                	ret

0000000080002c78 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002c78:	1101                	addi	sp,sp,-32
    80002c7a:	ec06                	sd	ra,24(sp)
    80002c7c:	e822                	sd	s0,16(sp)
    80002c7e:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002c80:	fec40593          	addi	a1,s0,-20
    80002c84:	4501                	li	a0,0
    80002c86:	00000097          	auipc	ra,0x0
    80002c8a:	f12080e7          	jalr	-238(ra) # 80002b98 <argint>
    return -1;
    80002c8e:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002c90:	00054963          	bltz	a0,80002ca2 <sys_exit+0x2a>
  exit(n);
    80002c94:	fec42503          	lw	a0,-20(s0)
    80002c98:	fffff097          	auipc	ra,0xfffff
    80002c9c:	728080e7          	jalr	1832(ra) # 800023c0 <exit>
  return 0;  // not reached
    80002ca0:	4781                	li	a5,0
}
    80002ca2:	853e                	mv	a0,a5
    80002ca4:	60e2                	ld	ra,24(sp)
    80002ca6:	6442                	ld	s0,16(sp)
    80002ca8:	6105                	addi	sp,sp,32
    80002caa:	8082                	ret

0000000080002cac <sys_getpid>:

uint64
sys_getpid(void)
{
    80002cac:	1141                	addi	sp,sp,-16
    80002cae:	e406                	sd	ra,8(sp)
    80002cb0:	e022                	sd	s0,0(sp)
    80002cb2:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002cb4:	fffff097          	auipc	ra,0xfffff
    80002cb8:	dfe080e7          	jalr	-514(ra) # 80001ab2 <myproc>
}
    80002cbc:	5908                	lw	a0,48(a0)
    80002cbe:	60a2                	ld	ra,8(sp)
    80002cc0:	6402                	ld	s0,0(sp)
    80002cc2:	0141                	addi	sp,sp,16
    80002cc4:	8082                	ret

0000000080002cc6 <sys_fork>:

uint64
sys_fork(void)
{
    80002cc6:	1141                	addi	sp,sp,-16
    80002cc8:	e406                	sd	ra,8(sp)
    80002cca:	e022                	sd	s0,0(sp)
    80002ccc:	0800                	addi	s0,sp,16
  return fork();
    80002cce:	fffff097          	auipc	ra,0xfffff
    80002cd2:	1a8080e7          	jalr	424(ra) # 80001e76 <fork>
}
    80002cd6:	60a2                	ld	ra,8(sp)
    80002cd8:	6402                	ld	s0,0(sp)
    80002cda:	0141                	addi	sp,sp,16
    80002cdc:	8082                	ret

0000000080002cde <sys_wait>:

uint64
sys_wait(void)
{
    80002cde:	1101                	addi	sp,sp,-32
    80002ce0:	ec06                	sd	ra,24(sp)
    80002ce2:	e822                	sd	s0,16(sp)
    80002ce4:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002ce6:	fe840593          	addi	a1,s0,-24
    80002cea:	4501                	li	a0,0
    80002cec:	00000097          	auipc	ra,0x0
    80002cf0:	ece080e7          	jalr	-306(ra) # 80002bba <argaddr>
    80002cf4:	87aa                	mv	a5,a0
    return -1;
    80002cf6:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002cf8:	0007c863          	bltz	a5,80002d08 <sys_wait+0x2a>
  return wait(p);
    80002cfc:	fe843503          	ld	a0,-24(s0)
    80002d00:	fffff097          	auipc	ra,0xfffff
    80002d04:	4c8080e7          	jalr	1224(ra) # 800021c8 <wait>
}
    80002d08:	60e2                	ld	ra,24(sp)
    80002d0a:	6442                	ld	s0,16(sp)
    80002d0c:	6105                	addi	sp,sp,32
    80002d0e:	8082                	ret

0000000080002d10 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002d10:	7179                	addi	sp,sp,-48
    80002d12:	f406                	sd	ra,40(sp)
    80002d14:	f022                	sd	s0,32(sp)
    80002d16:	ec26                	sd	s1,24(sp)
    80002d18:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80002d1a:	fdc40593          	addi	a1,s0,-36
    80002d1e:	4501                	li	a0,0
    80002d20:	00000097          	auipc	ra,0x0
    80002d24:	e78080e7          	jalr	-392(ra) # 80002b98 <argint>
    80002d28:	87aa                	mv	a5,a0
    return -1;
    80002d2a:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    80002d2c:	0207c063          	bltz	a5,80002d4c <sys_sbrk+0x3c>
  addr = myproc()->sz;
    80002d30:	fffff097          	auipc	ra,0xfffff
    80002d34:	d82080e7          	jalr	-638(ra) # 80001ab2 <myproc>
    80002d38:	4924                	lw	s1,80(a0)
  if(growproc(n) < 0)
    80002d3a:	fdc42503          	lw	a0,-36(s0)
    80002d3e:	fffff097          	auipc	ra,0xfffff
    80002d42:	0c4080e7          	jalr	196(ra) # 80001e02 <growproc>
    80002d46:	00054863          	bltz	a0,80002d56 <sys_sbrk+0x46>
    return -1;
  return addr;
    80002d4a:	8526                	mv	a0,s1
}
    80002d4c:	70a2                	ld	ra,40(sp)
    80002d4e:	7402                	ld	s0,32(sp)
    80002d50:	64e2                	ld	s1,24(sp)
    80002d52:	6145                	addi	sp,sp,48
    80002d54:	8082                	ret
    return -1;
    80002d56:	557d                	li	a0,-1
    80002d58:	bfd5                	j	80002d4c <sys_sbrk+0x3c>

0000000080002d5a <sys_sleep>:

uint64
sys_sleep(void)
{
    80002d5a:	7139                	addi	sp,sp,-64
    80002d5c:	fc06                	sd	ra,56(sp)
    80002d5e:	f822                	sd	s0,48(sp)
    80002d60:	f426                	sd	s1,40(sp)
    80002d62:	f04a                	sd	s2,32(sp)
    80002d64:	ec4e                	sd	s3,24(sp)
    80002d66:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80002d68:	fcc40593          	addi	a1,s0,-52
    80002d6c:	4501                	li	a0,0
    80002d6e:	00000097          	auipc	ra,0x0
    80002d72:	e2a080e7          	jalr	-470(ra) # 80002b98 <argint>
    return -1;
    80002d76:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002d78:	06054563          	bltz	a0,80002de2 <sys_sleep+0x88>
  acquire(&tickslock);
    80002d7c:	00014517          	auipc	a0,0x14
    80002d80:	57450513          	addi	a0,a0,1396 # 800172f0 <tickslock>
    80002d84:	ffffe097          	auipc	ra,0xffffe
    80002d88:	e60080e7          	jalr	-416(ra) # 80000be4 <acquire>
  ticks0 = ticks;
    80002d8c:	00006917          	auipc	s2,0x6
    80002d90:	2b092903          	lw	s2,688(s2) # 8000903c <ticks>
  while(ticks - ticks0 < n){
    80002d94:	fcc42783          	lw	a5,-52(s0)
    80002d98:	cf85                	beqz	a5,80002dd0 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002d9a:	00014997          	auipc	s3,0x14
    80002d9e:	55698993          	addi	s3,s3,1366 # 800172f0 <tickslock>
    80002da2:	00006497          	auipc	s1,0x6
    80002da6:	29a48493          	addi	s1,s1,666 # 8000903c <ticks>
    if(myproc()->killed){
    80002daa:	fffff097          	auipc	ra,0xfffff
    80002dae:	d08080e7          	jalr	-760(ra) # 80001ab2 <myproc>
    80002db2:	551c                	lw	a5,40(a0)
    80002db4:	ef9d                	bnez	a5,80002df2 <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80002db6:	85ce                	mv	a1,s3
    80002db8:	8526                	mv	a0,s1
    80002dba:	fffff097          	auipc	ra,0xfffff
    80002dbe:	3aa080e7          	jalr	938(ra) # 80002164 <sleep>
  while(ticks - ticks0 < n){
    80002dc2:	409c                	lw	a5,0(s1)
    80002dc4:	412787bb          	subw	a5,a5,s2
    80002dc8:	fcc42703          	lw	a4,-52(s0)
    80002dcc:	fce7efe3          	bltu	a5,a4,80002daa <sys_sleep+0x50>
  }
  release(&tickslock);
    80002dd0:	00014517          	auipc	a0,0x14
    80002dd4:	52050513          	addi	a0,a0,1312 # 800172f0 <tickslock>
    80002dd8:	ffffe097          	auipc	ra,0xffffe
    80002ddc:	ec0080e7          	jalr	-320(ra) # 80000c98 <release>
  return 0;
    80002de0:	4781                	li	a5,0
}
    80002de2:	853e                	mv	a0,a5
    80002de4:	70e2                	ld	ra,56(sp)
    80002de6:	7442                	ld	s0,48(sp)
    80002de8:	74a2                	ld	s1,40(sp)
    80002dea:	7902                	ld	s2,32(sp)
    80002dec:	69e2                	ld	s3,24(sp)
    80002dee:	6121                	addi	sp,sp,64
    80002df0:	8082                	ret
      release(&tickslock);
    80002df2:	00014517          	auipc	a0,0x14
    80002df6:	4fe50513          	addi	a0,a0,1278 # 800172f0 <tickslock>
    80002dfa:	ffffe097          	auipc	ra,0xffffe
    80002dfe:	e9e080e7          	jalr	-354(ra) # 80000c98 <release>
      return -1;
    80002e02:	57fd                	li	a5,-1
    80002e04:	bff9                	j	80002de2 <sys_sleep+0x88>

0000000080002e06 <sys_kill>:

uint64
sys_kill(void)
{
    80002e06:	1101                	addi	sp,sp,-32
    80002e08:	ec06                	sd	ra,24(sp)
    80002e0a:	e822                	sd	s0,16(sp)
    80002e0c:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80002e0e:	fec40593          	addi	a1,s0,-20
    80002e12:	4501                	li	a0,0
    80002e14:	00000097          	auipc	ra,0x0
    80002e18:	d84080e7          	jalr	-636(ra) # 80002b98 <argint>
    80002e1c:	87aa                	mv	a5,a0
    return -1;
    80002e1e:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80002e20:	0007c863          	bltz	a5,80002e30 <sys_kill+0x2a>
  return kill(pid);
    80002e24:	fec42503          	lw	a0,-20(s0)
    80002e28:	fffff097          	auipc	ra,0xfffff
    80002e2c:	66e080e7          	jalr	1646(ra) # 80002496 <kill>
}
    80002e30:	60e2                	ld	ra,24(sp)
    80002e32:	6442                	ld	s0,16(sp)
    80002e34:	6105                	addi	sp,sp,32
    80002e36:	8082                	ret

0000000080002e38 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002e38:	1101                	addi	sp,sp,-32
    80002e3a:	ec06                	sd	ra,24(sp)
    80002e3c:	e822                	sd	s0,16(sp)
    80002e3e:	e426                	sd	s1,8(sp)
    80002e40:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002e42:	00014517          	auipc	a0,0x14
    80002e46:	4ae50513          	addi	a0,a0,1198 # 800172f0 <tickslock>
    80002e4a:	ffffe097          	auipc	ra,0xffffe
    80002e4e:	d9a080e7          	jalr	-614(ra) # 80000be4 <acquire>
  xticks = ticks;
    80002e52:	00006497          	auipc	s1,0x6
    80002e56:	1ea4a483          	lw	s1,490(s1) # 8000903c <ticks>
  release(&tickslock);
    80002e5a:	00014517          	auipc	a0,0x14
    80002e5e:	49650513          	addi	a0,a0,1174 # 800172f0 <tickslock>
    80002e62:	ffffe097          	auipc	ra,0xffffe
    80002e66:	e36080e7          	jalr	-458(ra) # 80000c98 <release>
  return xticks;
}
    80002e6a:	02049513          	slli	a0,s1,0x20
    80002e6e:	9101                	srli	a0,a0,0x20
    80002e70:	60e2                	ld	ra,24(sp)
    80002e72:	6442                	ld	s0,16(sp)
    80002e74:	64a2                	ld	s1,8(sp)
    80002e76:	6105                	addi	sp,sp,32
    80002e78:	8082                	ret

0000000080002e7a <sys_get_cpu>:

uint64
sys_get_cpu(void)
{
    80002e7a:	1141                	addi	sp,sp,-16
    80002e7c:	e406                	sd	ra,8(sp)
    80002e7e:	e022                	sd	s0,0(sp)
    80002e80:	0800                	addi	s0,sp,16
  return get_cpu();
    80002e82:	00000097          	auipc	ra,0x0
    80002e86:	814080e7          	jalr	-2028(ra) # 80002696 <get_cpu>
}
    80002e8a:	60a2                	ld	ra,8(sp)
    80002e8c:	6402                	ld	s0,0(sp)
    80002e8e:	0141                	addi	sp,sp,16
    80002e90:	8082                	ret

0000000080002e92 <sys_set_cpu>:

uint64
sys_set_cpu(void)
{
    80002e92:	1101                	addi	sp,sp,-32
    80002e94:	ec06                	sd	ra,24(sp)
    80002e96:	e822                	sd	s0,16(sp)
    80002e98:	1000                	addi	s0,sp,32
  int cpu_num;

  if(argint(0, &cpu_num) < 0)
    80002e9a:	fec40593          	addi	a1,s0,-20
    80002e9e:	4501                	li	a0,0
    80002ea0:	00000097          	auipc	ra,0x0
    80002ea4:	cf8080e7          	jalr	-776(ra) # 80002b98 <argint>
    80002ea8:	87aa                	mv	a5,a0
    return -1;
    80002eaa:	557d                	li	a0,-1
  if(argint(0, &cpu_num) < 0)
    80002eac:	0007c863          	bltz	a5,80002ebc <sys_set_cpu+0x2a>
  return set_cpu(cpu_num);
    80002eb0:	fec42503          	lw	a0,-20(s0)
    80002eb4:	fffff097          	auipc	ra,0xfffff
    80002eb8:	7ae080e7          	jalr	1966(ra) # 80002662 <set_cpu>
    80002ebc:	60e2                	ld	ra,24(sp)
    80002ebe:	6442                	ld	s0,16(sp)
    80002ec0:	6105                	addi	sp,sp,32
    80002ec2:	8082                	ret

0000000080002ec4 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002ec4:	7179                	addi	sp,sp,-48
    80002ec6:	f406                	sd	ra,40(sp)
    80002ec8:	f022                	sd	s0,32(sp)
    80002eca:	ec26                	sd	s1,24(sp)
    80002ecc:	e84a                	sd	s2,16(sp)
    80002ece:	e44e                	sd	s3,8(sp)
    80002ed0:	e052                	sd	s4,0(sp)
    80002ed2:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80002ed4:	00005597          	auipc	a1,0x5
    80002ed8:	64c58593          	addi	a1,a1,1612 # 80008520 <syscalls+0xc0>
    80002edc:	00014517          	auipc	a0,0x14
    80002ee0:	42c50513          	addi	a0,a0,1068 # 80017308 <bcache>
    80002ee4:	ffffe097          	auipc	ra,0xffffe
    80002ee8:	c70080e7          	jalr	-912(ra) # 80000b54 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80002eec:	0001c797          	auipc	a5,0x1c
    80002ef0:	41c78793          	addi	a5,a5,1052 # 8001f308 <bcache+0x8000>
    80002ef4:	0001c717          	auipc	a4,0x1c
    80002ef8:	67c70713          	addi	a4,a4,1660 # 8001f570 <bcache+0x8268>
    80002efc:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80002f00:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002f04:	00014497          	auipc	s1,0x14
    80002f08:	41c48493          	addi	s1,s1,1052 # 80017320 <bcache+0x18>
    b->next = bcache.head.next;
    80002f0c:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80002f0e:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80002f10:	00005a17          	auipc	s4,0x5
    80002f14:	618a0a13          	addi	s4,s4,1560 # 80008528 <syscalls+0xc8>
    b->next = bcache.head.next;
    80002f18:	2b893783          	ld	a5,696(s2)
    80002f1c:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80002f1e:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80002f22:	85d2                	mv	a1,s4
    80002f24:	01048513          	addi	a0,s1,16
    80002f28:	00001097          	auipc	ra,0x1
    80002f2c:	4bc080e7          	jalr	1212(ra) # 800043e4 <initsleeplock>
    bcache.head.next->prev = b;
    80002f30:	2b893783          	ld	a5,696(s2)
    80002f34:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80002f36:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002f3a:	45848493          	addi	s1,s1,1112
    80002f3e:	fd349de3          	bne	s1,s3,80002f18 <binit+0x54>
  }
}
    80002f42:	70a2                	ld	ra,40(sp)
    80002f44:	7402                	ld	s0,32(sp)
    80002f46:	64e2                	ld	s1,24(sp)
    80002f48:	6942                	ld	s2,16(sp)
    80002f4a:	69a2                	ld	s3,8(sp)
    80002f4c:	6a02                	ld	s4,0(sp)
    80002f4e:	6145                	addi	sp,sp,48
    80002f50:	8082                	ret

0000000080002f52 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80002f52:	7179                	addi	sp,sp,-48
    80002f54:	f406                	sd	ra,40(sp)
    80002f56:	f022                	sd	s0,32(sp)
    80002f58:	ec26                	sd	s1,24(sp)
    80002f5a:	e84a                	sd	s2,16(sp)
    80002f5c:	e44e                	sd	s3,8(sp)
    80002f5e:	1800                	addi	s0,sp,48
    80002f60:	89aa                	mv	s3,a0
    80002f62:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    80002f64:	00014517          	auipc	a0,0x14
    80002f68:	3a450513          	addi	a0,a0,932 # 80017308 <bcache>
    80002f6c:	ffffe097          	auipc	ra,0xffffe
    80002f70:	c78080e7          	jalr	-904(ra) # 80000be4 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80002f74:	0001c497          	auipc	s1,0x1c
    80002f78:	64c4b483          	ld	s1,1612(s1) # 8001f5c0 <bcache+0x82b8>
    80002f7c:	0001c797          	auipc	a5,0x1c
    80002f80:	5f478793          	addi	a5,a5,1524 # 8001f570 <bcache+0x8268>
    80002f84:	02f48f63          	beq	s1,a5,80002fc2 <bread+0x70>
    80002f88:	873e                	mv	a4,a5
    80002f8a:	a021                	j	80002f92 <bread+0x40>
    80002f8c:	68a4                	ld	s1,80(s1)
    80002f8e:	02e48a63          	beq	s1,a4,80002fc2 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80002f92:	449c                	lw	a5,8(s1)
    80002f94:	ff379ce3          	bne	a5,s3,80002f8c <bread+0x3a>
    80002f98:	44dc                	lw	a5,12(s1)
    80002f9a:	ff2799e3          	bne	a5,s2,80002f8c <bread+0x3a>
      b->refcnt++;
    80002f9e:	40bc                	lw	a5,64(s1)
    80002fa0:	2785                	addiw	a5,a5,1
    80002fa2:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002fa4:	00014517          	auipc	a0,0x14
    80002fa8:	36450513          	addi	a0,a0,868 # 80017308 <bcache>
    80002fac:	ffffe097          	auipc	ra,0xffffe
    80002fb0:	cec080e7          	jalr	-788(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    80002fb4:	01048513          	addi	a0,s1,16
    80002fb8:	00001097          	auipc	ra,0x1
    80002fbc:	466080e7          	jalr	1126(ra) # 8000441e <acquiresleep>
      return b;
    80002fc0:	a8b9                	j	8000301e <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002fc2:	0001c497          	auipc	s1,0x1c
    80002fc6:	5f64b483          	ld	s1,1526(s1) # 8001f5b8 <bcache+0x82b0>
    80002fca:	0001c797          	auipc	a5,0x1c
    80002fce:	5a678793          	addi	a5,a5,1446 # 8001f570 <bcache+0x8268>
    80002fd2:	00f48863          	beq	s1,a5,80002fe2 <bread+0x90>
    80002fd6:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80002fd8:	40bc                	lw	a5,64(s1)
    80002fda:	cf81                	beqz	a5,80002ff2 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002fdc:	64a4                	ld	s1,72(s1)
    80002fde:	fee49de3          	bne	s1,a4,80002fd8 <bread+0x86>
  panic("bget: no buffers");
    80002fe2:	00005517          	auipc	a0,0x5
    80002fe6:	54e50513          	addi	a0,a0,1358 # 80008530 <syscalls+0xd0>
    80002fea:	ffffd097          	auipc	ra,0xffffd
    80002fee:	554080e7          	jalr	1364(ra) # 8000053e <panic>
      b->dev = dev;
    80002ff2:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    80002ff6:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    80002ffa:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80002ffe:	4785                	li	a5,1
    80003000:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003002:	00014517          	auipc	a0,0x14
    80003006:	30650513          	addi	a0,a0,774 # 80017308 <bcache>
    8000300a:	ffffe097          	auipc	ra,0xffffe
    8000300e:	c8e080e7          	jalr	-882(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    80003012:	01048513          	addi	a0,s1,16
    80003016:	00001097          	auipc	ra,0x1
    8000301a:	408080e7          	jalr	1032(ra) # 8000441e <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    8000301e:	409c                	lw	a5,0(s1)
    80003020:	cb89                	beqz	a5,80003032 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80003022:	8526                	mv	a0,s1
    80003024:	70a2                	ld	ra,40(sp)
    80003026:	7402                	ld	s0,32(sp)
    80003028:	64e2                	ld	s1,24(sp)
    8000302a:	6942                	ld	s2,16(sp)
    8000302c:	69a2                	ld	s3,8(sp)
    8000302e:	6145                	addi	sp,sp,48
    80003030:	8082                	ret
    virtio_disk_rw(b, 0);
    80003032:	4581                	li	a1,0
    80003034:	8526                	mv	a0,s1
    80003036:	00003097          	auipc	ra,0x3
    8000303a:	f10080e7          	jalr	-240(ra) # 80005f46 <virtio_disk_rw>
    b->valid = 1;
    8000303e:	4785                	li	a5,1
    80003040:	c09c                	sw	a5,0(s1)
  return b;
    80003042:	b7c5                	j	80003022 <bread+0xd0>

0000000080003044 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003044:	1101                	addi	sp,sp,-32
    80003046:	ec06                	sd	ra,24(sp)
    80003048:	e822                	sd	s0,16(sp)
    8000304a:	e426                	sd	s1,8(sp)
    8000304c:	1000                	addi	s0,sp,32
    8000304e:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003050:	0541                	addi	a0,a0,16
    80003052:	00001097          	auipc	ra,0x1
    80003056:	466080e7          	jalr	1126(ra) # 800044b8 <holdingsleep>
    8000305a:	cd01                	beqz	a0,80003072 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    8000305c:	4585                	li	a1,1
    8000305e:	8526                	mv	a0,s1
    80003060:	00003097          	auipc	ra,0x3
    80003064:	ee6080e7          	jalr	-282(ra) # 80005f46 <virtio_disk_rw>
}
    80003068:	60e2                	ld	ra,24(sp)
    8000306a:	6442                	ld	s0,16(sp)
    8000306c:	64a2                	ld	s1,8(sp)
    8000306e:	6105                	addi	sp,sp,32
    80003070:	8082                	ret
    panic("bwrite");
    80003072:	00005517          	auipc	a0,0x5
    80003076:	4d650513          	addi	a0,a0,1238 # 80008548 <syscalls+0xe8>
    8000307a:	ffffd097          	auipc	ra,0xffffd
    8000307e:	4c4080e7          	jalr	1220(ra) # 8000053e <panic>

0000000080003082 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003082:	1101                	addi	sp,sp,-32
    80003084:	ec06                	sd	ra,24(sp)
    80003086:	e822                	sd	s0,16(sp)
    80003088:	e426                	sd	s1,8(sp)
    8000308a:	e04a                	sd	s2,0(sp)
    8000308c:	1000                	addi	s0,sp,32
    8000308e:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003090:	01050913          	addi	s2,a0,16
    80003094:	854a                	mv	a0,s2
    80003096:	00001097          	auipc	ra,0x1
    8000309a:	422080e7          	jalr	1058(ra) # 800044b8 <holdingsleep>
    8000309e:	c92d                	beqz	a0,80003110 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    800030a0:	854a                	mv	a0,s2
    800030a2:	00001097          	auipc	ra,0x1
    800030a6:	3d2080e7          	jalr	978(ra) # 80004474 <releasesleep>

  acquire(&bcache.lock);
    800030aa:	00014517          	auipc	a0,0x14
    800030ae:	25e50513          	addi	a0,a0,606 # 80017308 <bcache>
    800030b2:	ffffe097          	auipc	ra,0xffffe
    800030b6:	b32080e7          	jalr	-1230(ra) # 80000be4 <acquire>
  b->refcnt--;
    800030ba:	40bc                	lw	a5,64(s1)
    800030bc:	37fd                	addiw	a5,a5,-1
    800030be:	0007871b          	sext.w	a4,a5
    800030c2:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    800030c4:	eb05                	bnez	a4,800030f4 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    800030c6:	68bc                	ld	a5,80(s1)
    800030c8:	64b8                	ld	a4,72(s1)
    800030ca:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    800030cc:	64bc                	ld	a5,72(s1)
    800030ce:	68b8                	ld	a4,80(s1)
    800030d0:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    800030d2:	0001c797          	auipc	a5,0x1c
    800030d6:	23678793          	addi	a5,a5,566 # 8001f308 <bcache+0x8000>
    800030da:	2b87b703          	ld	a4,696(a5)
    800030de:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    800030e0:	0001c717          	auipc	a4,0x1c
    800030e4:	49070713          	addi	a4,a4,1168 # 8001f570 <bcache+0x8268>
    800030e8:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    800030ea:	2b87b703          	ld	a4,696(a5)
    800030ee:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    800030f0:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    800030f4:	00014517          	auipc	a0,0x14
    800030f8:	21450513          	addi	a0,a0,532 # 80017308 <bcache>
    800030fc:	ffffe097          	auipc	ra,0xffffe
    80003100:	b9c080e7          	jalr	-1124(ra) # 80000c98 <release>
}
    80003104:	60e2                	ld	ra,24(sp)
    80003106:	6442                	ld	s0,16(sp)
    80003108:	64a2                	ld	s1,8(sp)
    8000310a:	6902                	ld	s2,0(sp)
    8000310c:	6105                	addi	sp,sp,32
    8000310e:	8082                	ret
    panic("brelse");
    80003110:	00005517          	auipc	a0,0x5
    80003114:	44050513          	addi	a0,a0,1088 # 80008550 <syscalls+0xf0>
    80003118:	ffffd097          	auipc	ra,0xffffd
    8000311c:	426080e7          	jalr	1062(ra) # 8000053e <panic>

0000000080003120 <bpin>:

void
bpin(struct buf *b) {
    80003120:	1101                	addi	sp,sp,-32
    80003122:	ec06                	sd	ra,24(sp)
    80003124:	e822                	sd	s0,16(sp)
    80003126:	e426                	sd	s1,8(sp)
    80003128:	1000                	addi	s0,sp,32
    8000312a:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000312c:	00014517          	auipc	a0,0x14
    80003130:	1dc50513          	addi	a0,a0,476 # 80017308 <bcache>
    80003134:	ffffe097          	auipc	ra,0xffffe
    80003138:	ab0080e7          	jalr	-1360(ra) # 80000be4 <acquire>
  b->refcnt++;
    8000313c:	40bc                	lw	a5,64(s1)
    8000313e:	2785                	addiw	a5,a5,1
    80003140:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003142:	00014517          	auipc	a0,0x14
    80003146:	1c650513          	addi	a0,a0,454 # 80017308 <bcache>
    8000314a:	ffffe097          	auipc	ra,0xffffe
    8000314e:	b4e080e7          	jalr	-1202(ra) # 80000c98 <release>
}
    80003152:	60e2                	ld	ra,24(sp)
    80003154:	6442                	ld	s0,16(sp)
    80003156:	64a2                	ld	s1,8(sp)
    80003158:	6105                	addi	sp,sp,32
    8000315a:	8082                	ret

000000008000315c <bunpin>:

void
bunpin(struct buf *b) {
    8000315c:	1101                	addi	sp,sp,-32
    8000315e:	ec06                	sd	ra,24(sp)
    80003160:	e822                	sd	s0,16(sp)
    80003162:	e426                	sd	s1,8(sp)
    80003164:	1000                	addi	s0,sp,32
    80003166:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003168:	00014517          	auipc	a0,0x14
    8000316c:	1a050513          	addi	a0,a0,416 # 80017308 <bcache>
    80003170:	ffffe097          	auipc	ra,0xffffe
    80003174:	a74080e7          	jalr	-1420(ra) # 80000be4 <acquire>
  b->refcnt--;
    80003178:	40bc                	lw	a5,64(s1)
    8000317a:	37fd                	addiw	a5,a5,-1
    8000317c:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000317e:	00014517          	auipc	a0,0x14
    80003182:	18a50513          	addi	a0,a0,394 # 80017308 <bcache>
    80003186:	ffffe097          	auipc	ra,0xffffe
    8000318a:	b12080e7          	jalr	-1262(ra) # 80000c98 <release>
}
    8000318e:	60e2                	ld	ra,24(sp)
    80003190:	6442                	ld	s0,16(sp)
    80003192:	64a2                	ld	s1,8(sp)
    80003194:	6105                	addi	sp,sp,32
    80003196:	8082                	ret

0000000080003198 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003198:	1101                	addi	sp,sp,-32
    8000319a:	ec06                	sd	ra,24(sp)
    8000319c:	e822                	sd	s0,16(sp)
    8000319e:	e426                	sd	s1,8(sp)
    800031a0:	e04a                	sd	s2,0(sp)
    800031a2:	1000                	addi	s0,sp,32
    800031a4:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    800031a6:	00d5d59b          	srliw	a1,a1,0xd
    800031aa:	0001d797          	auipc	a5,0x1d
    800031ae:	83a7a783          	lw	a5,-1990(a5) # 8001f9e4 <sb+0x1c>
    800031b2:	9dbd                	addw	a1,a1,a5
    800031b4:	00000097          	auipc	ra,0x0
    800031b8:	d9e080e7          	jalr	-610(ra) # 80002f52 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    800031bc:	0074f713          	andi	a4,s1,7
    800031c0:	4785                	li	a5,1
    800031c2:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    800031c6:	14ce                	slli	s1,s1,0x33
    800031c8:	90d9                	srli	s1,s1,0x36
    800031ca:	00950733          	add	a4,a0,s1
    800031ce:	05874703          	lbu	a4,88(a4)
    800031d2:	00e7f6b3          	and	a3,a5,a4
    800031d6:	c69d                	beqz	a3,80003204 <bfree+0x6c>
    800031d8:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    800031da:	94aa                	add	s1,s1,a0
    800031dc:	fff7c793          	not	a5,a5
    800031e0:	8ff9                	and	a5,a5,a4
    800031e2:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    800031e6:	00001097          	auipc	ra,0x1
    800031ea:	118080e7          	jalr	280(ra) # 800042fe <log_write>
  brelse(bp);
    800031ee:	854a                	mv	a0,s2
    800031f0:	00000097          	auipc	ra,0x0
    800031f4:	e92080e7          	jalr	-366(ra) # 80003082 <brelse>
}
    800031f8:	60e2                	ld	ra,24(sp)
    800031fa:	6442                	ld	s0,16(sp)
    800031fc:	64a2                	ld	s1,8(sp)
    800031fe:	6902                	ld	s2,0(sp)
    80003200:	6105                	addi	sp,sp,32
    80003202:	8082                	ret
    panic("freeing free block");
    80003204:	00005517          	auipc	a0,0x5
    80003208:	35450513          	addi	a0,a0,852 # 80008558 <syscalls+0xf8>
    8000320c:	ffffd097          	auipc	ra,0xffffd
    80003210:	332080e7          	jalr	818(ra) # 8000053e <panic>

0000000080003214 <balloc>:
{
    80003214:	711d                	addi	sp,sp,-96
    80003216:	ec86                	sd	ra,88(sp)
    80003218:	e8a2                	sd	s0,80(sp)
    8000321a:	e4a6                	sd	s1,72(sp)
    8000321c:	e0ca                	sd	s2,64(sp)
    8000321e:	fc4e                	sd	s3,56(sp)
    80003220:	f852                	sd	s4,48(sp)
    80003222:	f456                	sd	s5,40(sp)
    80003224:	f05a                	sd	s6,32(sp)
    80003226:	ec5e                	sd	s7,24(sp)
    80003228:	e862                	sd	s8,16(sp)
    8000322a:	e466                	sd	s9,8(sp)
    8000322c:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    8000322e:	0001c797          	auipc	a5,0x1c
    80003232:	79e7a783          	lw	a5,1950(a5) # 8001f9cc <sb+0x4>
    80003236:	cbd1                	beqz	a5,800032ca <balloc+0xb6>
    80003238:	8baa                	mv	s7,a0
    8000323a:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    8000323c:	0001cb17          	auipc	s6,0x1c
    80003240:	78cb0b13          	addi	s6,s6,1932 # 8001f9c8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003244:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003246:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003248:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    8000324a:	6c89                	lui	s9,0x2
    8000324c:	a831                	j	80003268 <balloc+0x54>
    brelse(bp);
    8000324e:	854a                	mv	a0,s2
    80003250:	00000097          	auipc	ra,0x0
    80003254:	e32080e7          	jalr	-462(ra) # 80003082 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003258:	015c87bb          	addw	a5,s9,s5
    8000325c:	00078a9b          	sext.w	s5,a5
    80003260:	004b2703          	lw	a4,4(s6)
    80003264:	06eaf363          	bgeu	s5,a4,800032ca <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    80003268:	41fad79b          	sraiw	a5,s5,0x1f
    8000326c:	0137d79b          	srliw	a5,a5,0x13
    80003270:	015787bb          	addw	a5,a5,s5
    80003274:	40d7d79b          	sraiw	a5,a5,0xd
    80003278:	01cb2583          	lw	a1,28(s6)
    8000327c:	9dbd                	addw	a1,a1,a5
    8000327e:	855e                	mv	a0,s7
    80003280:	00000097          	auipc	ra,0x0
    80003284:	cd2080e7          	jalr	-814(ra) # 80002f52 <bread>
    80003288:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000328a:	004b2503          	lw	a0,4(s6)
    8000328e:	000a849b          	sext.w	s1,s5
    80003292:	8662                	mv	a2,s8
    80003294:	faa4fde3          	bgeu	s1,a0,8000324e <balloc+0x3a>
      m = 1 << (bi % 8);
    80003298:	41f6579b          	sraiw	a5,a2,0x1f
    8000329c:	01d7d69b          	srliw	a3,a5,0x1d
    800032a0:	00c6873b          	addw	a4,a3,a2
    800032a4:	00777793          	andi	a5,a4,7
    800032a8:	9f95                	subw	a5,a5,a3
    800032aa:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    800032ae:	4037571b          	sraiw	a4,a4,0x3
    800032b2:	00e906b3          	add	a3,s2,a4
    800032b6:	0586c683          	lbu	a3,88(a3)
    800032ba:	00d7f5b3          	and	a1,a5,a3
    800032be:	cd91                	beqz	a1,800032da <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800032c0:	2605                	addiw	a2,a2,1
    800032c2:	2485                	addiw	s1,s1,1
    800032c4:	fd4618e3          	bne	a2,s4,80003294 <balloc+0x80>
    800032c8:	b759                	j	8000324e <balloc+0x3a>
  panic("balloc: out of blocks");
    800032ca:	00005517          	auipc	a0,0x5
    800032ce:	2a650513          	addi	a0,a0,678 # 80008570 <syscalls+0x110>
    800032d2:	ffffd097          	auipc	ra,0xffffd
    800032d6:	26c080e7          	jalr	620(ra) # 8000053e <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    800032da:	974a                	add	a4,a4,s2
    800032dc:	8fd5                	or	a5,a5,a3
    800032de:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    800032e2:	854a                	mv	a0,s2
    800032e4:	00001097          	auipc	ra,0x1
    800032e8:	01a080e7          	jalr	26(ra) # 800042fe <log_write>
        brelse(bp);
    800032ec:	854a                	mv	a0,s2
    800032ee:	00000097          	auipc	ra,0x0
    800032f2:	d94080e7          	jalr	-620(ra) # 80003082 <brelse>
  bp = bread(dev, bno);
    800032f6:	85a6                	mv	a1,s1
    800032f8:	855e                	mv	a0,s7
    800032fa:	00000097          	auipc	ra,0x0
    800032fe:	c58080e7          	jalr	-936(ra) # 80002f52 <bread>
    80003302:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003304:	40000613          	li	a2,1024
    80003308:	4581                	li	a1,0
    8000330a:	05850513          	addi	a0,a0,88
    8000330e:	ffffe097          	auipc	ra,0xffffe
    80003312:	9d2080e7          	jalr	-1582(ra) # 80000ce0 <memset>
  log_write(bp);
    80003316:	854a                	mv	a0,s2
    80003318:	00001097          	auipc	ra,0x1
    8000331c:	fe6080e7          	jalr	-26(ra) # 800042fe <log_write>
  brelse(bp);
    80003320:	854a                	mv	a0,s2
    80003322:	00000097          	auipc	ra,0x0
    80003326:	d60080e7          	jalr	-672(ra) # 80003082 <brelse>
}
    8000332a:	8526                	mv	a0,s1
    8000332c:	60e6                	ld	ra,88(sp)
    8000332e:	6446                	ld	s0,80(sp)
    80003330:	64a6                	ld	s1,72(sp)
    80003332:	6906                	ld	s2,64(sp)
    80003334:	79e2                	ld	s3,56(sp)
    80003336:	7a42                	ld	s4,48(sp)
    80003338:	7aa2                	ld	s5,40(sp)
    8000333a:	7b02                	ld	s6,32(sp)
    8000333c:	6be2                	ld	s7,24(sp)
    8000333e:	6c42                	ld	s8,16(sp)
    80003340:	6ca2                	ld	s9,8(sp)
    80003342:	6125                	addi	sp,sp,96
    80003344:	8082                	ret

0000000080003346 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    80003346:	7179                	addi	sp,sp,-48
    80003348:	f406                	sd	ra,40(sp)
    8000334a:	f022                	sd	s0,32(sp)
    8000334c:	ec26                	sd	s1,24(sp)
    8000334e:	e84a                	sd	s2,16(sp)
    80003350:	e44e                	sd	s3,8(sp)
    80003352:	e052                	sd	s4,0(sp)
    80003354:	1800                	addi	s0,sp,48
    80003356:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003358:	47ad                	li	a5,11
    8000335a:	04b7fe63          	bgeu	a5,a1,800033b6 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    8000335e:	ff45849b          	addiw	s1,a1,-12
    80003362:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003366:	0ff00793          	li	a5,255
    8000336a:	0ae7e363          	bltu	a5,a4,80003410 <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    8000336e:	08052583          	lw	a1,128(a0)
    80003372:	c5ad                	beqz	a1,800033dc <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    80003374:	00092503          	lw	a0,0(s2)
    80003378:	00000097          	auipc	ra,0x0
    8000337c:	bda080e7          	jalr	-1062(ra) # 80002f52 <bread>
    80003380:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003382:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003386:	02049593          	slli	a1,s1,0x20
    8000338a:	9181                	srli	a1,a1,0x20
    8000338c:	058a                	slli	a1,a1,0x2
    8000338e:	00b784b3          	add	s1,a5,a1
    80003392:	0004a983          	lw	s3,0(s1)
    80003396:	04098d63          	beqz	s3,800033f0 <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    8000339a:	8552                	mv	a0,s4
    8000339c:	00000097          	auipc	ra,0x0
    800033a0:	ce6080e7          	jalr	-794(ra) # 80003082 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    800033a4:	854e                	mv	a0,s3
    800033a6:	70a2                	ld	ra,40(sp)
    800033a8:	7402                	ld	s0,32(sp)
    800033aa:	64e2                	ld	s1,24(sp)
    800033ac:	6942                	ld	s2,16(sp)
    800033ae:	69a2                	ld	s3,8(sp)
    800033b0:	6a02                	ld	s4,0(sp)
    800033b2:	6145                	addi	sp,sp,48
    800033b4:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    800033b6:	02059493          	slli	s1,a1,0x20
    800033ba:	9081                	srli	s1,s1,0x20
    800033bc:	048a                	slli	s1,s1,0x2
    800033be:	94aa                	add	s1,s1,a0
    800033c0:	0504a983          	lw	s3,80(s1)
    800033c4:	fe0990e3          	bnez	s3,800033a4 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    800033c8:	4108                	lw	a0,0(a0)
    800033ca:	00000097          	auipc	ra,0x0
    800033ce:	e4a080e7          	jalr	-438(ra) # 80003214 <balloc>
    800033d2:	0005099b          	sext.w	s3,a0
    800033d6:	0534a823          	sw	s3,80(s1)
    800033da:	b7e9                	j	800033a4 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    800033dc:	4108                	lw	a0,0(a0)
    800033de:	00000097          	auipc	ra,0x0
    800033e2:	e36080e7          	jalr	-458(ra) # 80003214 <balloc>
    800033e6:	0005059b          	sext.w	a1,a0
    800033ea:	08b92023          	sw	a1,128(s2)
    800033ee:	b759                	j	80003374 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    800033f0:	00092503          	lw	a0,0(s2)
    800033f4:	00000097          	auipc	ra,0x0
    800033f8:	e20080e7          	jalr	-480(ra) # 80003214 <balloc>
    800033fc:	0005099b          	sext.w	s3,a0
    80003400:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    80003404:	8552                	mv	a0,s4
    80003406:	00001097          	auipc	ra,0x1
    8000340a:	ef8080e7          	jalr	-264(ra) # 800042fe <log_write>
    8000340e:	b771                	j	8000339a <bmap+0x54>
  panic("bmap: out of range");
    80003410:	00005517          	auipc	a0,0x5
    80003414:	17850513          	addi	a0,a0,376 # 80008588 <syscalls+0x128>
    80003418:	ffffd097          	auipc	ra,0xffffd
    8000341c:	126080e7          	jalr	294(ra) # 8000053e <panic>

0000000080003420 <iget>:
{
    80003420:	7179                	addi	sp,sp,-48
    80003422:	f406                	sd	ra,40(sp)
    80003424:	f022                	sd	s0,32(sp)
    80003426:	ec26                	sd	s1,24(sp)
    80003428:	e84a                	sd	s2,16(sp)
    8000342a:	e44e                	sd	s3,8(sp)
    8000342c:	e052                	sd	s4,0(sp)
    8000342e:	1800                	addi	s0,sp,48
    80003430:	89aa                	mv	s3,a0
    80003432:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003434:	0001c517          	auipc	a0,0x1c
    80003438:	5b450513          	addi	a0,a0,1460 # 8001f9e8 <itable>
    8000343c:	ffffd097          	auipc	ra,0xffffd
    80003440:	7a8080e7          	jalr	1960(ra) # 80000be4 <acquire>
  empty = 0;
    80003444:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003446:	0001c497          	auipc	s1,0x1c
    8000344a:	5ba48493          	addi	s1,s1,1466 # 8001fa00 <itable+0x18>
    8000344e:	0001e697          	auipc	a3,0x1e
    80003452:	04268693          	addi	a3,a3,66 # 80021490 <log>
    80003456:	a039                	j	80003464 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003458:	02090b63          	beqz	s2,8000348e <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    8000345c:	08848493          	addi	s1,s1,136
    80003460:	02d48a63          	beq	s1,a3,80003494 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003464:	449c                	lw	a5,8(s1)
    80003466:	fef059e3          	blez	a5,80003458 <iget+0x38>
    8000346a:	4098                	lw	a4,0(s1)
    8000346c:	ff3716e3          	bne	a4,s3,80003458 <iget+0x38>
    80003470:	40d8                	lw	a4,4(s1)
    80003472:	ff4713e3          	bne	a4,s4,80003458 <iget+0x38>
      ip->ref++;
    80003476:	2785                	addiw	a5,a5,1
    80003478:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    8000347a:	0001c517          	auipc	a0,0x1c
    8000347e:	56e50513          	addi	a0,a0,1390 # 8001f9e8 <itable>
    80003482:	ffffe097          	auipc	ra,0xffffe
    80003486:	816080e7          	jalr	-2026(ra) # 80000c98 <release>
      return ip;
    8000348a:	8926                	mv	s2,s1
    8000348c:	a03d                	j	800034ba <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000348e:	f7f9                	bnez	a5,8000345c <iget+0x3c>
    80003490:	8926                	mv	s2,s1
    80003492:	b7e9                	j	8000345c <iget+0x3c>
  if(empty == 0)
    80003494:	02090c63          	beqz	s2,800034cc <iget+0xac>
  ip->dev = dev;
    80003498:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    8000349c:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    800034a0:	4785                	li	a5,1
    800034a2:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    800034a6:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    800034aa:	0001c517          	auipc	a0,0x1c
    800034ae:	53e50513          	addi	a0,a0,1342 # 8001f9e8 <itable>
    800034b2:	ffffd097          	auipc	ra,0xffffd
    800034b6:	7e6080e7          	jalr	2022(ra) # 80000c98 <release>
}
    800034ba:	854a                	mv	a0,s2
    800034bc:	70a2                	ld	ra,40(sp)
    800034be:	7402                	ld	s0,32(sp)
    800034c0:	64e2                	ld	s1,24(sp)
    800034c2:	6942                	ld	s2,16(sp)
    800034c4:	69a2                	ld	s3,8(sp)
    800034c6:	6a02                	ld	s4,0(sp)
    800034c8:	6145                	addi	sp,sp,48
    800034ca:	8082                	ret
    panic("iget: no inodes");
    800034cc:	00005517          	auipc	a0,0x5
    800034d0:	0d450513          	addi	a0,a0,212 # 800085a0 <syscalls+0x140>
    800034d4:	ffffd097          	auipc	ra,0xffffd
    800034d8:	06a080e7          	jalr	106(ra) # 8000053e <panic>

00000000800034dc <fsinit>:
fsinit(int dev) {
    800034dc:	7179                	addi	sp,sp,-48
    800034de:	f406                	sd	ra,40(sp)
    800034e0:	f022                	sd	s0,32(sp)
    800034e2:	ec26                	sd	s1,24(sp)
    800034e4:	e84a                	sd	s2,16(sp)
    800034e6:	e44e                	sd	s3,8(sp)
    800034e8:	1800                	addi	s0,sp,48
    800034ea:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    800034ec:	4585                	li	a1,1
    800034ee:	00000097          	auipc	ra,0x0
    800034f2:	a64080e7          	jalr	-1436(ra) # 80002f52 <bread>
    800034f6:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    800034f8:	0001c997          	auipc	s3,0x1c
    800034fc:	4d098993          	addi	s3,s3,1232 # 8001f9c8 <sb>
    80003500:	02000613          	li	a2,32
    80003504:	05850593          	addi	a1,a0,88
    80003508:	854e                	mv	a0,s3
    8000350a:	ffffe097          	auipc	ra,0xffffe
    8000350e:	836080e7          	jalr	-1994(ra) # 80000d40 <memmove>
  brelse(bp);
    80003512:	8526                	mv	a0,s1
    80003514:	00000097          	auipc	ra,0x0
    80003518:	b6e080e7          	jalr	-1170(ra) # 80003082 <brelse>
  if(sb.magic != FSMAGIC)
    8000351c:	0009a703          	lw	a4,0(s3)
    80003520:	102037b7          	lui	a5,0x10203
    80003524:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003528:	02f71263          	bne	a4,a5,8000354c <fsinit+0x70>
  initlog(dev, &sb);
    8000352c:	0001c597          	auipc	a1,0x1c
    80003530:	49c58593          	addi	a1,a1,1180 # 8001f9c8 <sb>
    80003534:	854a                	mv	a0,s2
    80003536:	00001097          	auipc	ra,0x1
    8000353a:	b4c080e7          	jalr	-1204(ra) # 80004082 <initlog>
}
    8000353e:	70a2                	ld	ra,40(sp)
    80003540:	7402                	ld	s0,32(sp)
    80003542:	64e2                	ld	s1,24(sp)
    80003544:	6942                	ld	s2,16(sp)
    80003546:	69a2                	ld	s3,8(sp)
    80003548:	6145                	addi	sp,sp,48
    8000354a:	8082                	ret
    panic("invalid file system");
    8000354c:	00005517          	auipc	a0,0x5
    80003550:	06450513          	addi	a0,a0,100 # 800085b0 <syscalls+0x150>
    80003554:	ffffd097          	auipc	ra,0xffffd
    80003558:	fea080e7          	jalr	-22(ra) # 8000053e <panic>

000000008000355c <iinit>:
{
    8000355c:	7179                	addi	sp,sp,-48
    8000355e:	f406                	sd	ra,40(sp)
    80003560:	f022                	sd	s0,32(sp)
    80003562:	ec26                	sd	s1,24(sp)
    80003564:	e84a                	sd	s2,16(sp)
    80003566:	e44e                	sd	s3,8(sp)
    80003568:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    8000356a:	00005597          	auipc	a1,0x5
    8000356e:	05e58593          	addi	a1,a1,94 # 800085c8 <syscalls+0x168>
    80003572:	0001c517          	auipc	a0,0x1c
    80003576:	47650513          	addi	a0,a0,1142 # 8001f9e8 <itable>
    8000357a:	ffffd097          	auipc	ra,0xffffd
    8000357e:	5da080e7          	jalr	1498(ra) # 80000b54 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003582:	0001c497          	auipc	s1,0x1c
    80003586:	48e48493          	addi	s1,s1,1166 # 8001fa10 <itable+0x28>
    8000358a:	0001e997          	auipc	s3,0x1e
    8000358e:	f1698993          	addi	s3,s3,-234 # 800214a0 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003592:	00005917          	auipc	s2,0x5
    80003596:	03e90913          	addi	s2,s2,62 # 800085d0 <syscalls+0x170>
    8000359a:	85ca                	mv	a1,s2
    8000359c:	8526                	mv	a0,s1
    8000359e:	00001097          	auipc	ra,0x1
    800035a2:	e46080e7          	jalr	-442(ra) # 800043e4 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    800035a6:	08848493          	addi	s1,s1,136
    800035aa:	ff3498e3          	bne	s1,s3,8000359a <iinit+0x3e>
}
    800035ae:	70a2                	ld	ra,40(sp)
    800035b0:	7402                	ld	s0,32(sp)
    800035b2:	64e2                	ld	s1,24(sp)
    800035b4:	6942                	ld	s2,16(sp)
    800035b6:	69a2                	ld	s3,8(sp)
    800035b8:	6145                	addi	sp,sp,48
    800035ba:	8082                	ret

00000000800035bc <ialloc>:
{
    800035bc:	715d                	addi	sp,sp,-80
    800035be:	e486                	sd	ra,72(sp)
    800035c0:	e0a2                	sd	s0,64(sp)
    800035c2:	fc26                	sd	s1,56(sp)
    800035c4:	f84a                	sd	s2,48(sp)
    800035c6:	f44e                	sd	s3,40(sp)
    800035c8:	f052                	sd	s4,32(sp)
    800035ca:	ec56                	sd	s5,24(sp)
    800035cc:	e85a                	sd	s6,16(sp)
    800035ce:	e45e                	sd	s7,8(sp)
    800035d0:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    800035d2:	0001c717          	auipc	a4,0x1c
    800035d6:	40272703          	lw	a4,1026(a4) # 8001f9d4 <sb+0xc>
    800035da:	4785                	li	a5,1
    800035dc:	04e7fa63          	bgeu	a5,a4,80003630 <ialloc+0x74>
    800035e0:	8aaa                	mv	s5,a0
    800035e2:	8bae                	mv	s7,a1
    800035e4:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    800035e6:	0001ca17          	auipc	s4,0x1c
    800035ea:	3e2a0a13          	addi	s4,s4,994 # 8001f9c8 <sb>
    800035ee:	00048b1b          	sext.w	s6,s1
    800035f2:	0044d593          	srli	a1,s1,0x4
    800035f6:	018a2783          	lw	a5,24(s4)
    800035fa:	9dbd                	addw	a1,a1,a5
    800035fc:	8556                	mv	a0,s5
    800035fe:	00000097          	auipc	ra,0x0
    80003602:	954080e7          	jalr	-1708(ra) # 80002f52 <bread>
    80003606:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003608:	05850993          	addi	s3,a0,88
    8000360c:	00f4f793          	andi	a5,s1,15
    80003610:	079a                	slli	a5,a5,0x6
    80003612:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003614:	00099783          	lh	a5,0(s3)
    80003618:	c785                	beqz	a5,80003640 <ialloc+0x84>
    brelse(bp);
    8000361a:	00000097          	auipc	ra,0x0
    8000361e:	a68080e7          	jalr	-1432(ra) # 80003082 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003622:	0485                	addi	s1,s1,1
    80003624:	00ca2703          	lw	a4,12(s4)
    80003628:	0004879b          	sext.w	a5,s1
    8000362c:	fce7e1e3          	bltu	a5,a4,800035ee <ialloc+0x32>
  panic("ialloc: no inodes");
    80003630:	00005517          	auipc	a0,0x5
    80003634:	fa850513          	addi	a0,a0,-88 # 800085d8 <syscalls+0x178>
    80003638:	ffffd097          	auipc	ra,0xffffd
    8000363c:	f06080e7          	jalr	-250(ra) # 8000053e <panic>
      memset(dip, 0, sizeof(*dip));
    80003640:	04000613          	li	a2,64
    80003644:	4581                	li	a1,0
    80003646:	854e                	mv	a0,s3
    80003648:	ffffd097          	auipc	ra,0xffffd
    8000364c:	698080e7          	jalr	1688(ra) # 80000ce0 <memset>
      dip->type = type;
    80003650:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003654:	854a                	mv	a0,s2
    80003656:	00001097          	auipc	ra,0x1
    8000365a:	ca8080e7          	jalr	-856(ra) # 800042fe <log_write>
      brelse(bp);
    8000365e:	854a                	mv	a0,s2
    80003660:	00000097          	auipc	ra,0x0
    80003664:	a22080e7          	jalr	-1502(ra) # 80003082 <brelse>
      return iget(dev, inum);
    80003668:	85da                	mv	a1,s6
    8000366a:	8556                	mv	a0,s5
    8000366c:	00000097          	auipc	ra,0x0
    80003670:	db4080e7          	jalr	-588(ra) # 80003420 <iget>
}
    80003674:	60a6                	ld	ra,72(sp)
    80003676:	6406                	ld	s0,64(sp)
    80003678:	74e2                	ld	s1,56(sp)
    8000367a:	7942                	ld	s2,48(sp)
    8000367c:	79a2                	ld	s3,40(sp)
    8000367e:	7a02                	ld	s4,32(sp)
    80003680:	6ae2                	ld	s5,24(sp)
    80003682:	6b42                	ld	s6,16(sp)
    80003684:	6ba2                	ld	s7,8(sp)
    80003686:	6161                	addi	sp,sp,80
    80003688:	8082                	ret

000000008000368a <iupdate>:
{
    8000368a:	1101                	addi	sp,sp,-32
    8000368c:	ec06                	sd	ra,24(sp)
    8000368e:	e822                	sd	s0,16(sp)
    80003690:	e426                	sd	s1,8(sp)
    80003692:	e04a                	sd	s2,0(sp)
    80003694:	1000                	addi	s0,sp,32
    80003696:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003698:	415c                	lw	a5,4(a0)
    8000369a:	0047d79b          	srliw	a5,a5,0x4
    8000369e:	0001c597          	auipc	a1,0x1c
    800036a2:	3425a583          	lw	a1,834(a1) # 8001f9e0 <sb+0x18>
    800036a6:	9dbd                	addw	a1,a1,a5
    800036a8:	4108                	lw	a0,0(a0)
    800036aa:	00000097          	auipc	ra,0x0
    800036ae:	8a8080e7          	jalr	-1880(ra) # 80002f52 <bread>
    800036b2:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    800036b4:	05850793          	addi	a5,a0,88
    800036b8:	40c8                	lw	a0,4(s1)
    800036ba:	893d                	andi	a0,a0,15
    800036bc:	051a                	slli	a0,a0,0x6
    800036be:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    800036c0:	04449703          	lh	a4,68(s1)
    800036c4:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    800036c8:	04649703          	lh	a4,70(s1)
    800036cc:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    800036d0:	04849703          	lh	a4,72(s1)
    800036d4:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    800036d8:	04a49703          	lh	a4,74(s1)
    800036dc:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    800036e0:	44f8                	lw	a4,76(s1)
    800036e2:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    800036e4:	03400613          	li	a2,52
    800036e8:	05048593          	addi	a1,s1,80
    800036ec:	0531                	addi	a0,a0,12
    800036ee:	ffffd097          	auipc	ra,0xffffd
    800036f2:	652080e7          	jalr	1618(ra) # 80000d40 <memmove>
  log_write(bp);
    800036f6:	854a                	mv	a0,s2
    800036f8:	00001097          	auipc	ra,0x1
    800036fc:	c06080e7          	jalr	-1018(ra) # 800042fe <log_write>
  brelse(bp);
    80003700:	854a                	mv	a0,s2
    80003702:	00000097          	auipc	ra,0x0
    80003706:	980080e7          	jalr	-1664(ra) # 80003082 <brelse>
}
    8000370a:	60e2                	ld	ra,24(sp)
    8000370c:	6442                	ld	s0,16(sp)
    8000370e:	64a2                	ld	s1,8(sp)
    80003710:	6902                	ld	s2,0(sp)
    80003712:	6105                	addi	sp,sp,32
    80003714:	8082                	ret

0000000080003716 <idup>:
{
    80003716:	1101                	addi	sp,sp,-32
    80003718:	ec06                	sd	ra,24(sp)
    8000371a:	e822                	sd	s0,16(sp)
    8000371c:	e426                	sd	s1,8(sp)
    8000371e:	1000                	addi	s0,sp,32
    80003720:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003722:	0001c517          	auipc	a0,0x1c
    80003726:	2c650513          	addi	a0,a0,710 # 8001f9e8 <itable>
    8000372a:	ffffd097          	auipc	ra,0xffffd
    8000372e:	4ba080e7          	jalr	1210(ra) # 80000be4 <acquire>
  ip->ref++;
    80003732:	449c                	lw	a5,8(s1)
    80003734:	2785                	addiw	a5,a5,1
    80003736:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003738:	0001c517          	auipc	a0,0x1c
    8000373c:	2b050513          	addi	a0,a0,688 # 8001f9e8 <itable>
    80003740:	ffffd097          	auipc	ra,0xffffd
    80003744:	558080e7          	jalr	1368(ra) # 80000c98 <release>
}
    80003748:	8526                	mv	a0,s1
    8000374a:	60e2                	ld	ra,24(sp)
    8000374c:	6442                	ld	s0,16(sp)
    8000374e:	64a2                	ld	s1,8(sp)
    80003750:	6105                	addi	sp,sp,32
    80003752:	8082                	ret

0000000080003754 <ilock>:
{
    80003754:	1101                	addi	sp,sp,-32
    80003756:	ec06                	sd	ra,24(sp)
    80003758:	e822                	sd	s0,16(sp)
    8000375a:	e426                	sd	s1,8(sp)
    8000375c:	e04a                	sd	s2,0(sp)
    8000375e:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003760:	c115                	beqz	a0,80003784 <ilock+0x30>
    80003762:	84aa                	mv	s1,a0
    80003764:	451c                	lw	a5,8(a0)
    80003766:	00f05f63          	blez	a5,80003784 <ilock+0x30>
  acquiresleep(&ip->lock);
    8000376a:	0541                	addi	a0,a0,16
    8000376c:	00001097          	auipc	ra,0x1
    80003770:	cb2080e7          	jalr	-846(ra) # 8000441e <acquiresleep>
  if(ip->valid == 0){
    80003774:	40bc                	lw	a5,64(s1)
    80003776:	cf99                	beqz	a5,80003794 <ilock+0x40>
}
    80003778:	60e2                	ld	ra,24(sp)
    8000377a:	6442                	ld	s0,16(sp)
    8000377c:	64a2                	ld	s1,8(sp)
    8000377e:	6902                	ld	s2,0(sp)
    80003780:	6105                	addi	sp,sp,32
    80003782:	8082                	ret
    panic("ilock");
    80003784:	00005517          	auipc	a0,0x5
    80003788:	e6c50513          	addi	a0,a0,-404 # 800085f0 <syscalls+0x190>
    8000378c:	ffffd097          	auipc	ra,0xffffd
    80003790:	db2080e7          	jalr	-590(ra) # 8000053e <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003794:	40dc                	lw	a5,4(s1)
    80003796:	0047d79b          	srliw	a5,a5,0x4
    8000379a:	0001c597          	auipc	a1,0x1c
    8000379e:	2465a583          	lw	a1,582(a1) # 8001f9e0 <sb+0x18>
    800037a2:	9dbd                	addw	a1,a1,a5
    800037a4:	4088                	lw	a0,0(s1)
    800037a6:	fffff097          	auipc	ra,0xfffff
    800037aa:	7ac080e7          	jalr	1964(ra) # 80002f52 <bread>
    800037ae:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    800037b0:	05850593          	addi	a1,a0,88
    800037b4:	40dc                	lw	a5,4(s1)
    800037b6:	8bbd                	andi	a5,a5,15
    800037b8:	079a                	slli	a5,a5,0x6
    800037ba:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    800037bc:	00059783          	lh	a5,0(a1)
    800037c0:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    800037c4:	00259783          	lh	a5,2(a1)
    800037c8:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    800037cc:	00459783          	lh	a5,4(a1)
    800037d0:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    800037d4:	00659783          	lh	a5,6(a1)
    800037d8:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    800037dc:	459c                	lw	a5,8(a1)
    800037de:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    800037e0:	03400613          	li	a2,52
    800037e4:	05b1                	addi	a1,a1,12
    800037e6:	05048513          	addi	a0,s1,80
    800037ea:	ffffd097          	auipc	ra,0xffffd
    800037ee:	556080e7          	jalr	1366(ra) # 80000d40 <memmove>
    brelse(bp);
    800037f2:	854a                	mv	a0,s2
    800037f4:	00000097          	auipc	ra,0x0
    800037f8:	88e080e7          	jalr	-1906(ra) # 80003082 <brelse>
    ip->valid = 1;
    800037fc:	4785                	li	a5,1
    800037fe:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003800:	04449783          	lh	a5,68(s1)
    80003804:	fbb5                	bnez	a5,80003778 <ilock+0x24>
      panic("ilock: no type");
    80003806:	00005517          	auipc	a0,0x5
    8000380a:	df250513          	addi	a0,a0,-526 # 800085f8 <syscalls+0x198>
    8000380e:	ffffd097          	auipc	ra,0xffffd
    80003812:	d30080e7          	jalr	-720(ra) # 8000053e <panic>

0000000080003816 <iunlock>:
{
    80003816:	1101                	addi	sp,sp,-32
    80003818:	ec06                	sd	ra,24(sp)
    8000381a:	e822                	sd	s0,16(sp)
    8000381c:	e426                	sd	s1,8(sp)
    8000381e:	e04a                	sd	s2,0(sp)
    80003820:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003822:	c905                	beqz	a0,80003852 <iunlock+0x3c>
    80003824:	84aa                	mv	s1,a0
    80003826:	01050913          	addi	s2,a0,16
    8000382a:	854a                	mv	a0,s2
    8000382c:	00001097          	auipc	ra,0x1
    80003830:	c8c080e7          	jalr	-884(ra) # 800044b8 <holdingsleep>
    80003834:	cd19                	beqz	a0,80003852 <iunlock+0x3c>
    80003836:	449c                	lw	a5,8(s1)
    80003838:	00f05d63          	blez	a5,80003852 <iunlock+0x3c>
  releasesleep(&ip->lock);
    8000383c:	854a                	mv	a0,s2
    8000383e:	00001097          	auipc	ra,0x1
    80003842:	c36080e7          	jalr	-970(ra) # 80004474 <releasesleep>
}
    80003846:	60e2                	ld	ra,24(sp)
    80003848:	6442                	ld	s0,16(sp)
    8000384a:	64a2                	ld	s1,8(sp)
    8000384c:	6902                	ld	s2,0(sp)
    8000384e:	6105                	addi	sp,sp,32
    80003850:	8082                	ret
    panic("iunlock");
    80003852:	00005517          	auipc	a0,0x5
    80003856:	db650513          	addi	a0,a0,-586 # 80008608 <syscalls+0x1a8>
    8000385a:	ffffd097          	auipc	ra,0xffffd
    8000385e:	ce4080e7          	jalr	-796(ra) # 8000053e <panic>

0000000080003862 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003862:	7179                	addi	sp,sp,-48
    80003864:	f406                	sd	ra,40(sp)
    80003866:	f022                	sd	s0,32(sp)
    80003868:	ec26                	sd	s1,24(sp)
    8000386a:	e84a                	sd	s2,16(sp)
    8000386c:	e44e                	sd	s3,8(sp)
    8000386e:	e052                	sd	s4,0(sp)
    80003870:	1800                	addi	s0,sp,48
    80003872:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003874:	05050493          	addi	s1,a0,80
    80003878:	08050913          	addi	s2,a0,128
    8000387c:	a021                	j	80003884 <itrunc+0x22>
    8000387e:	0491                	addi	s1,s1,4
    80003880:	01248d63          	beq	s1,s2,8000389a <itrunc+0x38>
    if(ip->addrs[i]){
    80003884:	408c                	lw	a1,0(s1)
    80003886:	dde5                	beqz	a1,8000387e <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003888:	0009a503          	lw	a0,0(s3)
    8000388c:	00000097          	auipc	ra,0x0
    80003890:	90c080e7          	jalr	-1780(ra) # 80003198 <bfree>
      ip->addrs[i] = 0;
    80003894:	0004a023          	sw	zero,0(s1)
    80003898:	b7dd                	j	8000387e <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    8000389a:	0809a583          	lw	a1,128(s3)
    8000389e:	e185                	bnez	a1,800038be <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    800038a0:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    800038a4:	854e                	mv	a0,s3
    800038a6:	00000097          	auipc	ra,0x0
    800038aa:	de4080e7          	jalr	-540(ra) # 8000368a <iupdate>
}
    800038ae:	70a2                	ld	ra,40(sp)
    800038b0:	7402                	ld	s0,32(sp)
    800038b2:	64e2                	ld	s1,24(sp)
    800038b4:	6942                	ld	s2,16(sp)
    800038b6:	69a2                	ld	s3,8(sp)
    800038b8:	6a02                	ld	s4,0(sp)
    800038ba:	6145                	addi	sp,sp,48
    800038bc:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    800038be:	0009a503          	lw	a0,0(s3)
    800038c2:	fffff097          	auipc	ra,0xfffff
    800038c6:	690080e7          	jalr	1680(ra) # 80002f52 <bread>
    800038ca:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    800038cc:	05850493          	addi	s1,a0,88
    800038d0:	45850913          	addi	s2,a0,1112
    800038d4:	a811                	j	800038e8 <itrunc+0x86>
        bfree(ip->dev, a[j]);
    800038d6:	0009a503          	lw	a0,0(s3)
    800038da:	00000097          	auipc	ra,0x0
    800038de:	8be080e7          	jalr	-1858(ra) # 80003198 <bfree>
    for(j = 0; j < NINDIRECT; j++){
    800038e2:	0491                	addi	s1,s1,4
    800038e4:	01248563          	beq	s1,s2,800038ee <itrunc+0x8c>
      if(a[j])
    800038e8:	408c                	lw	a1,0(s1)
    800038ea:	dde5                	beqz	a1,800038e2 <itrunc+0x80>
    800038ec:	b7ed                	j	800038d6 <itrunc+0x74>
    brelse(bp);
    800038ee:	8552                	mv	a0,s4
    800038f0:	fffff097          	auipc	ra,0xfffff
    800038f4:	792080e7          	jalr	1938(ra) # 80003082 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    800038f8:	0809a583          	lw	a1,128(s3)
    800038fc:	0009a503          	lw	a0,0(s3)
    80003900:	00000097          	auipc	ra,0x0
    80003904:	898080e7          	jalr	-1896(ra) # 80003198 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003908:	0809a023          	sw	zero,128(s3)
    8000390c:	bf51                	j	800038a0 <itrunc+0x3e>

000000008000390e <iput>:
{
    8000390e:	1101                	addi	sp,sp,-32
    80003910:	ec06                	sd	ra,24(sp)
    80003912:	e822                	sd	s0,16(sp)
    80003914:	e426                	sd	s1,8(sp)
    80003916:	e04a                	sd	s2,0(sp)
    80003918:	1000                	addi	s0,sp,32
    8000391a:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    8000391c:	0001c517          	auipc	a0,0x1c
    80003920:	0cc50513          	addi	a0,a0,204 # 8001f9e8 <itable>
    80003924:	ffffd097          	auipc	ra,0xffffd
    80003928:	2c0080e7          	jalr	704(ra) # 80000be4 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    8000392c:	4498                	lw	a4,8(s1)
    8000392e:	4785                	li	a5,1
    80003930:	02f70363          	beq	a4,a5,80003956 <iput+0x48>
  ip->ref--;
    80003934:	449c                	lw	a5,8(s1)
    80003936:	37fd                	addiw	a5,a5,-1
    80003938:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    8000393a:	0001c517          	auipc	a0,0x1c
    8000393e:	0ae50513          	addi	a0,a0,174 # 8001f9e8 <itable>
    80003942:	ffffd097          	auipc	ra,0xffffd
    80003946:	356080e7          	jalr	854(ra) # 80000c98 <release>
}
    8000394a:	60e2                	ld	ra,24(sp)
    8000394c:	6442                	ld	s0,16(sp)
    8000394e:	64a2                	ld	s1,8(sp)
    80003950:	6902                	ld	s2,0(sp)
    80003952:	6105                	addi	sp,sp,32
    80003954:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003956:	40bc                	lw	a5,64(s1)
    80003958:	dff1                	beqz	a5,80003934 <iput+0x26>
    8000395a:	04a49783          	lh	a5,74(s1)
    8000395e:	fbf9                	bnez	a5,80003934 <iput+0x26>
    acquiresleep(&ip->lock);
    80003960:	01048913          	addi	s2,s1,16
    80003964:	854a                	mv	a0,s2
    80003966:	00001097          	auipc	ra,0x1
    8000396a:	ab8080e7          	jalr	-1352(ra) # 8000441e <acquiresleep>
    release(&itable.lock);
    8000396e:	0001c517          	auipc	a0,0x1c
    80003972:	07a50513          	addi	a0,a0,122 # 8001f9e8 <itable>
    80003976:	ffffd097          	auipc	ra,0xffffd
    8000397a:	322080e7          	jalr	802(ra) # 80000c98 <release>
    itrunc(ip);
    8000397e:	8526                	mv	a0,s1
    80003980:	00000097          	auipc	ra,0x0
    80003984:	ee2080e7          	jalr	-286(ra) # 80003862 <itrunc>
    ip->type = 0;
    80003988:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    8000398c:	8526                	mv	a0,s1
    8000398e:	00000097          	auipc	ra,0x0
    80003992:	cfc080e7          	jalr	-772(ra) # 8000368a <iupdate>
    ip->valid = 0;
    80003996:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    8000399a:	854a                	mv	a0,s2
    8000399c:	00001097          	auipc	ra,0x1
    800039a0:	ad8080e7          	jalr	-1320(ra) # 80004474 <releasesleep>
    acquire(&itable.lock);
    800039a4:	0001c517          	auipc	a0,0x1c
    800039a8:	04450513          	addi	a0,a0,68 # 8001f9e8 <itable>
    800039ac:	ffffd097          	auipc	ra,0xffffd
    800039b0:	238080e7          	jalr	568(ra) # 80000be4 <acquire>
    800039b4:	b741                	j	80003934 <iput+0x26>

00000000800039b6 <iunlockput>:
{
    800039b6:	1101                	addi	sp,sp,-32
    800039b8:	ec06                	sd	ra,24(sp)
    800039ba:	e822                	sd	s0,16(sp)
    800039bc:	e426                	sd	s1,8(sp)
    800039be:	1000                	addi	s0,sp,32
    800039c0:	84aa                	mv	s1,a0
  iunlock(ip);
    800039c2:	00000097          	auipc	ra,0x0
    800039c6:	e54080e7          	jalr	-428(ra) # 80003816 <iunlock>
  iput(ip);
    800039ca:	8526                	mv	a0,s1
    800039cc:	00000097          	auipc	ra,0x0
    800039d0:	f42080e7          	jalr	-190(ra) # 8000390e <iput>
}
    800039d4:	60e2                	ld	ra,24(sp)
    800039d6:	6442                	ld	s0,16(sp)
    800039d8:	64a2                	ld	s1,8(sp)
    800039da:	6105                	addi	sp,sp,32
    800039dc:	8082                	ret

00000000800039de <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    800039de:	1141                	addi	sp,sp,-16
    800039e0:	e422                	sd	s0,8(sp)
    800039e2:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    800039e4:	411c                	lw	a5,0(a0)
    800039e6:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    800039e8:	415c                	lw	a5,4(a0)
    800039ea:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    800039ec:	04451783          	lh	a5,68(a0)
    800039f0:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    800039f4:	04a51783          	lh	a5,74(a0)
    800039f8:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    800039fc:	04c56783          	lwu	a5,76(a0)
    80003a00:	e99c                	sd	a5,16(a1)
}
    80003a02:	6422                	ld	s0,8(sp)
    80003a04:	0141                	addi	sp,sp,16
    80003a06:	8082                	ret

0000000080003a08 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003a08:	457c                	lw	a5,76(a0)
    80003a0a:	0ed7e963          	bltu	a5,a3,80003afc <readi+0xf4>
{
    80003a0e:	7159                	addi	sp,sp,-112
    80003a10:	f486                	sd	ra,104(sp)
    80003a12:	f0a2                	sd	s0,96(sp)
    80003a14:	eca6                	sd	s1,88(sp)
    80003a16:	e8ca                	sd	s2,80(sp)
    80003a18:	e4ce                	sd	s3,72(sp)
    80003a1a:	e0d2                	sd	s4,64(sp)
    80003a1c:	fc56                	sd	s5,56(sp)
    80003a1e:	f85a                	sd	s6,48(sp)
    80003a20:	f45e                	sd	s7,40(sp)
    80003a22:	f062                	sd	s8,32(sp)
    80003a24:	ec66                	sd	s9,24(sp)
    80003a26:	e86a                	sd	s10,16(sp)
    80003a28:	e46e                	sd	s11,8(sp)
    80003a2a:	1880                	addi	s0,sp,112
    80003a2c:	8baa                	mv	s7,a0
    80003a2e:	8c2e                	mv	s8,a1
    80003a30:	8ab2                	mv	s5,a2
    80003a32:	84b6                	mv	s1,a3
    80003a34:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003a36:	9f35                	addw	a4,a4,a3
    return 0;
    80003a38:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003a3a:	0ad76063          	bltu	a4,a3,80003ada <readi+0xd2>
  if(off + n > ip->size)
    80003a3e:	00e7f463          	bgeu	a5,a4,80003a46 <readi+0x3e>
    n = ip->size - off;
    80003a42:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003a46:	0a0b0963          	beqz	s6,80003af8 <readi+0xf0>
    80003a4a:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003a4c:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003a50:	5cfd                	li	s9,-1
    80003a52:	a82d                	j	80003a8c <readi+0x84>
    80003a54:	020a1d93          	slli	s11,s4,0x20
    80003a58:	020ddd93          	srli	s11,s11,0x20
    80003a5c:	05890613          	addi	a2,s2,88
    80003a60:	86ee                	mv	a3,s11
    80003a62:	963a                	add	a2,a2,a4
    80003a64:	85d6                	mv	a1,s5
    80003a66:	8562                	mv	a0,s8
    80003a68:	fffff097          	auipc	ra,0xfffff
    80003a6c:	aa0080e7          	jalr	-1376(ra) # 80002508 <either_copyout>
    80003a70:	05950d63          	beq	a0,s9,80003aca <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003a74:	854a                	mv	a0,s2
    80003a76:	fffff097          	auipc	ra,0xfffff
    80003a7a:	60c080e7          	jalr	1548(ra) # 80003082 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003a7e:	013a09bb          	addw	s3,s4,s3
    80003a82:	009a04bb          	addw	s1,s4,s1
    80003a86:	9aee                	add	s5,s5,s11
    80003a88:	0569f763          	bgeu	s3,s6,80003ad6 <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003a8c:	000ba903          	lw	s2,0(s7)
    80003a90:	00a4d59b          	srliw	a1,s1,0xa
    80003a94:	855e                	mv	a0,s7
    80003a96:	00000097          	auipc	ra,0x0
    80003a9a:	8b0080e7          	jalr	-1872(ra) # 80003346 <bmap>
    80003a9e:	0005059b          	sext.w	a1,a0
    80003aa2:	854a                	mv	a0,s2
    80003aa4:	fffff097          	auipc	ra,0xfffff
    80003aa8:	4ae080e7          	jalr	1198(ra) # 80002f52 <bread>
    80003aac:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003aae:	3ff4f713          	andi	a4,s1,1023
    80003ab2:	40ed07bb          	subw	a5,s10,a4
    80003ab6:	413b06bb          	subw	a3,s6,s3
    80003aba:	8a3e                	mv	s4,a5
    80003abc:	2781                	sext.w	a5,a5
    80003abe:	0006861b          	sext.w	a2,a3
    80003ac2:	f8f679e3          	bgeu	a2,a5,80003a54 <readi+0x4c>
    80003ac6:	8a36                	mv	s4,a3
    80003ac8:	b771                	j	80003a54 <readi+0x4c>
      brelse(bp);
    80003aca:	854a                	mv	a0,s2
    80003acc:	fffff097          	auipc	ra,0xfffff
    80003ad0:	5b6080e7          	jalr	1462(ra) # 80003082 <brelse>
      tot = -1;
    80003ad4:	59fd                	li	s3,-1
  }
  return tot;
    80003ad6:	0009851b          	sext.w	a0,s3
}
    80003ada:	70a6                	ld	ra,104(sp)
    80003adc:	7406                	ld	s0,96(sp)
    80003ade:	64e6                	ld	s1,88(sp)
    80003ae0:	6946                	ld	s2,80(sp)
    80003ae2:	69a6                	ld	s3,72(sp)
    80003ae4:	6a06                	ld	s4,64(sp)
    80003ae6:	7ae2                	ld	s5,56(sp)
    80003ae8:	7b42                	ld	s6,48(sp)
    80003aea:	7ba2                	ld	s7,40(sp)
    80003aec:	7c02                	ld	s8,32(sp)
    80003aee:	6ce2                	ld	s9,24(sp)
    80003af0:	6d42                	ld	s10,16(sp)
    80003af2:	6da2                	ld	s11,8(sp)
    80003af4:	6165                	addi	sp,sp,112
    80003af6:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003af8:	89da                	mv	s3,s6
    80003afa:	bff1                	j	80003ad6 <readi+0xce>
    return 0;
    80003afc:	4501                	li	a0,0
}
    80003afe:	8082                	ret

0000000080003b00 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003b00:	457c                	lw	a5,76(a0)
    80003b02:	10d7e863          	bltu	a5,a3,80003c12 <writei+0x112>
{
    80003b06:	7159                	addi	sp,sp,-112
    80003b08:	f486                	sd	ra,104(sp)
    80003b0a:	f0a2                	sd	s0,96(sp)
    80003b0c:	eca6                	sd	s1,88(sp)
    80003b0e:	e8ca                	sd	s2,80(sp)
    80003b10:	e4ce                	sd	s3,72(sp)
    80003b12:	e0d2                	sd	s4,64(sp)
    80003b14:	fc56                	sd	s5,56(sp)
    80003b16:	f85a                	sd	s6,48(sp)
    80003b18:	f45e                	sd	s7,40(sp)
    80003b1a:	f062                	sd	s8,32(sp)
    80003b1c:	ec66                	sd	s9,24(sp)
    80003b1e:	e86a                	sd	s10,16(sp)
    80003b20:	e46e                	sd	s11,8(sp)
    80003b22:	1880                	addi	s0,sp,112
    80003b24:	8b2a                	mv	s6,a0
    80003b26:	8c2e                	mv	s8,a1
    80003b28:	8ab2                	mv	s5,a2
    80003b2a:	8936                	mv	s2,a3
    80003b2c:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    80003b2e:	00e687bb          	addw	a5,a3,a4
    80003b32:	0ed7e263          	bltu	a5,a3,80003c16 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003b36:	00043737          	lui	a4,0x43
    80003b3a:	0ef76063          	bltu	a4,a5,80003c1a <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003b3e:	0c0b8863          	beqz	s7,80003c0e <writei+0x10e>
    80003b42:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003b44:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003b48:	5cfd                	li	s9,-1
    80003b4a:	a091                	j	80003b8e <writei+0x8e>
    80003b4c:	02099d93          	slli	s11,s3,0x20
    80003b50:	020ddd93          	srli	s11,s11,0x20
    80003b54:	05848513          	addi	a0,s1,88
    80003b58:	86ee                	mv	a3,s11
    80003b5a:	8656                	mv	a2,s5
    80003b5c:	85e2                	mv	a1,s8
    80003b5e:	953a                	add	a0,a0,a4
    80003b60:	fffff097          	auipc	ra,0xfffff
    80003b64:	9fe080e7          	jalr	-1538(ra) # 8000255e <either_copyin>
    80003b68:	07950263          	beq	a0,s9,80003bcc <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003b6c:	8526                	mv	a0,s1
    80003b6e:	00000097          	auipc	ra,0x0
    80003b72:	790080e7          	jalr	1936(ra) # 800042fe <log_write>
    brelse(bp);
    80003b76:	8526                	mv	a0,s1
    80003b78:	fffff097          	auipc	ra,0xfffff
    80003b7c:	50a080e7          	jalr	1290(ra) # 80003082 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003b80:	01498a3b          	addw	s4,s3,s4
    80003b84:	0129893b          	addw	s2,s3,s2
    80003b88:	9aee                	add	s5,s5,s11
    80003b8a:	057a7663          	bgeu	s4,s7,80003bd6 <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003b8e:	000b2483          	lw	s1,0(s6)
    80003b92:	00a9559b          	srliw	a1,s2,0xa
    80003b96:	855a                	mv	a0,s6
    80003b98:	fffff097          	auipc	ra,0xfffff
    80003b9c:	7ae080e7          	jalr	1966(ra) # 80003346 <bmap>
    80003ba0:	0005059b          	sext.w	a1,a0
    80003ba4:	8526                	mv	a0,s1
    80003ba6:	fffff097          	auipc	ra,0xfffff
    80003baa:	3ac080e7          	jalr	940(ra) # 80002f52 <bread>
    80003bae:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003bb0:	3ff97713          	andi	a4,s2,1023
    80003bb4:	40ed07bb          	subw	a5,s10,a4
    80003bb8:	414b86bb          	subw	a3,s7,s4
    80003bbc:	89be                	mv	s3,a5
    80003bbe:	2781                	sext.w	a5,a5
    80003bc0:	0006861b          	sext.w	a2,a3
    80003bc4:	f8f674e3          	bgeu	a2,a5,80003b4c <writei+0x4c>
    80003bc8:	89b6                	mv	s3,a3
    80003bca:	b749                	j	80003b4c <writei+0x4c>
      brelse(bp);
    80003bcc:	8526                	mv	a0,s1
    80003bce:	fffff097          	auipc	ra,0xfffff
    80003bd2:	4b4080e7          	jalr	1204(ra) # 80003082 <brelse>
  }

  if(off > ip->size)
    80003bd6:	04cb2783          	lw	a5,76(s6)
    80003bda:	0127f463          	bgeu	a5,s2,80003be2 <writei+0xe2>
    ip->size = off;
    80003bde:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003be2:	855a                	mv	a0,s6
    80003be4:	00000097          	auipc	ra,0x0
    80003be8:	aa6080e7          	jalr	-1370(ra) # 8000368a <iupdate>

  return tot;
    80003bec:	000a051b          	sext.w	a0,s4
}
    80003bf0:	70a6                	ld	ra,104(sp)
    80003bf2:	7406                	ld	s0,96(sp)
    80003bf4:	64e6                	ld	s1,88(sp)
    80003bf6:	6946                	ld	s2,80(sp)
    80003bf8:	69a6                	ld	s3,72(sp)
    80003bfa:	6a06                	ld	s4,64(sp)
    80003bfc:	7ae2                	ld	s5,56(sp)
    80003bfe:	7b42                	ld	s6,48(sp)
    80003c00:	7ba2                	ld	s7,40(sp)
    80003c02:	7c02                	ld	s8,32(sp)
    80003c04:	6ce2                	ld	s9,24(sp)
    80003c06:	6d42                	ld	s10,16(sp)
    80003c08:	6da2                	ld	s11,8(sp)
    80003c0a:	6165                	addi	sp,sp,112
    80003c0c:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003c0e:	8a5e                	mv	s4,s7
    80003c10:	bfc9                	j	80003be2 <writei+0xe2>
    return -1;
    80003c12:	557d                	li	a0,-1
}
    80003c14:	8082                	ret
    return -1;
    80003c16:	557d                	li	a0,-1
    80003c18:	bfe1                	j	80003bf0 <writei+0xf0>
    return -1;
    80003c1a:	557d                	li	a0,-1
    80003c1c:	bfd1                	j	80003bf0 <writei+0xf0>

0000000080003c1e <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003c1e:	1141                	addi	sp,sp,-16
    80003c20:	e406                	sd	ra,8(sp)
    80003c22:	e022                	sd	s0,0(sp)
    80003c24:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003c26:	4639                	li	a2,14
    80003c28:	ffffd097          	auipc	ra,0xffffd
    80003c2c:	190080e7          	jalr	400(ra) # 80000db8 <strncmp>
}
    80003c30:	60a2                	ld	ra,8(sp)
    80003c32:	6402                	ld	s0,0(sp)
    80003c34:	0141                	addi	sp,sp,16
    80003c36:	8082                	ret

0000000080003c38 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003c38:	7139                	addi	sp,sp,-64
    80003c3a:	fc06                	sd	ra,56(sp)
    80003c3c:	f822                	sd	s0,48(sp)
    80003c3e:	f426                	sd	s1,40(sp)
    80003c40:	f04a                	sd	s2,32(sp)
    80003c42:	ec4e                	sd	s3,24(sp)
    80003c44:	e852                	sd	s4,16(sp)
    80003c46:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003c48:	04451703          	lh	a4,68(a0)
    80003c4c:	4785                	li	a5,1
    80003c4e:	00f71a63          	bne	a4,a5,80003c62 <dirlookup+0x2a>
    80003c52:	892a                	mv	s2,a0
    80003c54:	89ae                	mv	s3,a1
    80003c56:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003c58:	457c                	lw	a5,76(a0)
    80003c5a:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003c5c:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003c5e:	e79d                	bnez	a5,80003c8c <dirlookup+0x54>
    80003c60:	a8a5                	j	80003cd8 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003c62:	00005517          	auipc	a0,0x5
    80003c66:	9ae50513          	addi	a0,a0,-1618 # 80008610 <syscalls+0x1b0>
    80003c6a:	ffffd097          	auipc	ra,0xffffd
    80003c6e:	8d4080e7          	jalr	-1836(ra) # 8000053e <panic>
      panic("dirlookup read");
    80003c72:	00005517          	auipc	a0,0x5
    80003c76:	9b650513          	addi	a0,a0,-1610 # 80008628 <syscalls+0x1c8>
    80003c7a:	ffffd097          	auipc	ra,0xffffd
    80003c7e:	8c4080e7          	jalr	-1852(ra) # 8000053e <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003c82:	24c1                	addiw	s1,s1,16
    80003c84:	04c92783          	lw	a5,76(s2)
    80003c88:	04f4f763          	bgeu	s1,a5,80003cd6 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003c8c:	4741                	li	a4,16
    80003c8e:	86a6                	mv	a3,s1
    80003c90:	fc040613          	addi	a2,s0,-64
    80003c94:	4581                	li	a1,0
    80003c96:	854a                	mv	a0,s2
    80003c98:	00000097          	auipc	ra,0x0
    80003c9c:	d70080e7          	jalr	-656(ra) # 80003a08 <readi>
    80003ca0:	47c1                	li	a5,16
    80003ca2:	fcf518e3          	bne	a0,a5,80003c72 <dirlookup+0x3a>
    if(de.inum == 0)
    80003ca6:	fc045783          	lhu	a5,-64(s0)
    80003caa:	dfe1                	beqz	a5,80003c82 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003cac:	fc240593          	addi	a1,s0,-62
    80003cb0:	854e                	mv	a0,s3
    80003cb2:	00000097          	auipc	ra,0x0
    80003cb6:	f6c080e7          	jalr	-148(ra) # 80003c1e <namecmp>
    80003cba:	f561                	bnez	a0,80003c82 <dirlookup+0x4a>
      if(poff)
    80003cbc:	000a0463          	beqz	s4,80003cc4 <dirlookup+0x8c>
        *poff = off;
    80003cc0:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003cc4:	fc045583          	lhu	a1,-64(s0)
    80003cc8:	00092503          	lw	a0,0(s2)
    80003ccc:	fffff097          	auipc	ra,0xfffff
    80003cd0:	754080e7          	jalr	1876(ra) # 80003420 <iget>
    80003cd4:	a011                	j	80003cd8 <dirlookup+0xa0>
  return 0;
    80003cd6:	4501                	li	a0,0
}
    80003cd8:	70e2                	ld	ra,56(sp)
    80003cda:	7442                	ld	s0,48(sp)
    80003cdc:	74a2                	ld	s1,40(sp)
    80003cde:	7902                	ld	s2,32(sp)
    80003ce0:	69e2                	ld	s3,24(sp)
    80003ce2:	6a42                	ld	s4,16(sp)
    80003ce4:	6121                	addi	sp,sp,64
    80003ce6:	8082                	ret

0000000080003ce8 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003ce8:	711d                	addi	sp,sp,-96
    80003cea:	ec86                	sd	ra,88(sp)
    80003cec:	e8a2                	sd	s0,80(sp)
    80003cee:	e4a6                	sd	s1,72(sp)
    80003cf0:	e0ca                	sd	s2,64(sp)
    80003cf2:	fc4e                	sd	s3,56(sp)
    80003cf4:	f852                	sd	s4,48(sp)
    80003cf6:	f456                	sd	s5,40(sp)
    80003cf8:	f05a                	sd	s6,32(sp)
    80003cfa:	ec5e                	sd	s7,24(sp)
    80003cfc:	e862                	sd	s8,16(sp)
    80003cfe:	e466                	sd	s9,8(sp)
    80003d00:	1080                	addi	s0,sp,96
    80003d02:	84aa                	mv	s1,a0
    80003d04:	8b2e                	mv	s6,a1
    80003d06:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003d08:	00054703          	lbu	a4,0(a0)
    80003d0c:	02f00793          	li	a5,47
    80003d10:	02f70363          	beq	a4,a5,80003d36 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003d14:	ffffe097          	auipc	ra,0xffffe
    80003d18:	d9e080e7          	jalr	-610(ra) # 80001ab2 <myproc>
    80003d1c:	15853503          	ld	a0,344(a0)
    80003d20:	00000097          	auipc	ra,0x0
    80003d24:	9f6080e7          	jalr	-1546(ra) # 80003716 <idup>
    80003d28:	89aa                	mv	s3,a0
  while(*path == '/')
    80003d2a:	02f00913          	li	s2,47
  len = path - s;
    80003d2e:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    80003d30:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003d32:	4c05                	li	s8,1
    80003d34:	a865                	j	80003dec <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003d36:	4585                	li	a1,1
    80003d38:	4505                	li	a0,1
    80003d3a:	fffff097          	auipc	ra,0xfffff
    80003d3e:	6e6080e7          	jalr	1766(ra) # 80003420 <iget>
    80003d42:	89aa                	mv	s3,a0
    80003d44:	b7dd                	j	80003d2a <namex+0x42>
      iunlockput(ip);
    80003d46:	854e                	mv	a0,s3
    80003d48:	00000097          	auipc	ra,0x0
    80003d4c:	c6e080e7          	jalr	-914(ra) # 800039b6 <iunlockput>
      return 0;
    80003d50:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003d52:	854e                	mv	a0,s3
    80003d54:	60e6                	ld	ra,88(sp)
    80003d56:	6446                	ld	s0,80(sp)
    80003d58:	64a6                	ld	s1,72(sp)
    80003d5a:	6906                	ld	s2,64(sp)
    80003d5c:	79e2                	ld	s3,56(sp)
    80003d5e:	7a42                	ld	s4,48(sp)
    80003d60:	7aa2                	ld	s5,40(sp)
    80003d62:	7b02                	ld	s6,32(sp)
    80003d64:	6be2                	ld	s7,24(sp)
    80003d66:	6c42                	ld	s8,16(sp)
    80003d68:	6ca2                	ld	s9,8(sp)
    80003d6a:	6125                	addi	sp,sp,96
    80003d6c:	8082                	ret
      iunlock(ip);
    80003d6e:	854e                	mv	a0,s3
    80003d70:	00000097          	auipc	ra,0x0
    80003d74:	aa6080e7          	jalr	-1370(ra) # 80003816 <iunlock>
      return ip;
    80003d78:	bfe9                	j	80003d52 <namex+0x6a>
      iunlockput(ip);
    80003d7a:	854e                	mv	a0,s3
    80003d7c:	00000097          	auipc	ra,0x0
    80003d80:	c3a080e7          	jalr	-966(ra) # 800039b6 <iunlockput>
      return 0;
    80003d84:	89d2                	mv	s3,s4
    80003d86:	b7f1                	j	80003d52 <namex+0x6a>
  len = path - s;
    80003d88:	40b48633          	sub	a2,s1,a1
    80003d8c:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80003d90:	094cd463          	bge	s9,s4,80003e18 <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003d94:	4639                	li	a2,14
    80003d96:	8556                	mv	a0,s5
    80003d98:	ffffd097          	auipc	ra,0xffffd
    80003d9c:	fa8080e7          	jalr	-88(ra) # 80000d40 <memmove>
  while(*path == '/')
    80003da0:	0004c783          	lbu	a5,0(s1)
    80003da4:	01279763          	bne	a5,s2,80003db2 <namex+0xca>
    path++;
    80003da8:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003daa:	0004c783          	lbu	a5,0(s1)
    80003dae:	ff278de3          	beq	a5,s2,80003da8 <namex+0xc0>
    ilock(ip);
    80003db2:	854e                	mv	a0,s3
    80003db4:	00000097          	auipc	ra,0x0
    80003db8:	9a0080e7          	jalr	-1632(ra) # 80003754 <ilock>
    if(ip->type != T_DIR){
    80003dbc:	04499783          	lh	a5,68(s3)
    80003dc0:	f98793e3          	bne	a5,s8,80003d46 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003dc4:	000b0563          	beqz	s6,80003dce <namex+0xe6>
    80003dc8:	0004c783          	lbu	a5,0(s1)
    80003dcc:	d3cd                	beqz	a5,80003d6e <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003dce:	865e                	mv	a2,s7
    80003dd0:	85d6                	mv	a1,s5
    80003dd2:	854e                	mv	a0,s3
    80003dd4:	00000097          	auipc	ra,0x0
    80003dd8:	e64080e7          	jalr	-412(ra) # 80003c38 <dirlookup>
    80003ddc:	8a2a                	mv	s4,a0
    80003dde:	dd51                	beqz	a0,80003d7a <namex+0x92>
    iunlockput(ip);
    80003de0:	854e                	mv	a0,s3
    80003de2:	00000097          	auipc	ra,0x0
    80003de6:	bd4080e7          	jalr	-1068(ra) # 800039b6 <iunlockput>
    ip = next;
    80003dea:	89d2                	mv	s3,s4
  while(*path == '/')
    80003dec:	0004c783          	lbu	a5,0(s1)
    80003df0:	05279763          	bne	a5,s2,80003e3e <namex+0x156>
    path++;
    80003df4:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003df6:	0004c783          	lbu	a5,0(s1)
    80003dfa:	ff278de3          	beq	a5,s2,80003df4 <namex+0x10c>
  if(*path == 0)
    80003dfe:	c79d                	beqz	a5,80003e2c <namex+0x144>
    path++;
    80003e00:	85a6                	mv	a1,s1
  len = path - s;
    80003e02:	8a5e                	mv	s4,s7
    80003e04:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80003e06:	01278963          	beq	a5,s2,80003e18 <namex+0x130>
    80003e0a:	dfbd                	beqz	a5,80003d88 <namex+0xa0>
    path++;
    80003e0c:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80003e0e:	0004c783          	lbu	a5,0(s1)
    80003e12:	ff279ce3          	bne	a5,s2,80003e0a <namex+0x122>
    80003e16:	bf8d                	j	80003d88 <namex+0xa0>
    memmove(name, s, len);
    80003e18:	2601                	sext.w	a2,a2
    80003e1a:	8556                	mv	a0,s5
    80003e1c:	ffffd097          	auipc	ra,0xffffd
    80003e20:	f24080e7          	jalr	-220(ra) # 80000d40 <memmove>
    name[len] = 0;
    80003e24:	9a56                	add	s4,s4,s5
    80003e26:	000a0023          	sb	zero,0(s4)
    80003e2a:	bf9d                	j	80003da0 <namex+0xb8>
  if(nameiparent){
    80003e2c:	f20b03e3          	beqz	s6,80003d52 <namex+0x6a>
    iput(ip);
    80003e30:	854e                	mv	a0,s3
    80003e32:	00000097          	auipc	ra,0x0
    80003e36:	adc080e7          	jalr	-1316(ra) # 8000390e <iput>
    return 0;
    80003e3a:	4981                	li	s3,0
    80003e3c:	bf19                	j	80003d52 <namex+0x6a>
  if(*path == 0)
    80003e3e:	d7fd                	beqz	a5,80003e2c <namex+0x144>
  while(*path != '/' && *path != 0)
    80003e40:	0004c783          	lbu	a5,0(s1)
    80003e44:	85a6                	mv	a1,s1
    80003e46:	b7d1                	j	80003e0a <namex+0x122>

0000000080003e48 <dirlink>:
{
    80003e48:	7139                	addi	sp,sp,-64
    80003e4a:	fc06                	sd	ra,56(sp)
    80003e4c:	f822                	sd	s0,48(sp)
    80003e4e:	f426                	sd	s1,40(sp)
    80003e50:	f04a                	sd	s2,32(sp)
    80003e52:	ec4e                	sd	s3,24(sp)
    80003e54:	e852                	sd	s4,16(sp)
    80003e56:	0080                	addi	s0,sp,64
    80003e58:	892a                	mv	s2,a0
    80003e5a:	8a2e                	mv	s4,a1
    80003e5c:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003e5e:	4601                	li	a2,0
    80003e60:	00000097          	auipc	ra,0x0
    80003e64:	dd8080e7          	jalr	-552(ra) # 80003c38 <dirlookup>
    80003e68:	e93d                	bnez	a0,80003ede <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e6a:	04c92483          	lw	s1,76(s2)
    80003e6e:	c49d                	beqz	s1,80003e9c <dirlink+0x54>
    80003e70:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003e72:	4741                	li	a4,16
    80003e74:	86a6                	mv	a3,s1
    80003e76:	fc040613          	addi	a2,s0,-64
    80003e7a:	4581                	li	a1,0
    80003e7c:	854a                	mv	a0,s2
    80003e7e:	00000097          	auipc	ra,0x0
    80003e82:	b8a080e7          	jalr	-1142(ra) # 80003a08 <readi>
    80003e86:	47c1                	li	a5,16
    80003e88:	06f51163          	bne	a0,a5,80003eea <dirlink+0xa2>
    if(de.inum == 0)
    80003e8c:	fc045783          	lhu	a5,-64(s0)
    80003e90:	c791                	beqz	a5,80003e9c <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e92:	24c1                	addiw	s1,s1,16
    80003e94:	04c92783          	lw	a5,76(s2)
    80003e98:	fcf4ede3          	bltu	s1,a5,80003e72 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80003e9c:	4639                	li	a2,14
    80003e9e:	85d2                	mv	a1,s4
    80003ea0:	fc240513          	addi	a0,s0,-62
    80003ea4:	ffffd097          	auipc	ra,0xffffd
    80003ea8:	f50080e7          	jalr	-176(ra) # 80000df4 <strncpy>
  de.inum = inum;
    80003eac:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003eb0:	4741                	li	a4,16
    80003eb2:	86a6                	mv	a3,s1
    80003eb4:	fc040613          	addi	a2,s0,-64
    80003eb8:	4581                	li	a1,0
    80003eba:	854a                	mv	a0,s2
    80003ebc:	00000097          	auipc	ra,0x0
    80003ec0:	c44080e7          	jalr	-956(ra) # 80003b00 <writei>
    80003ec4:	872a                	mv	a4,a0
    80003ec6:	47c1                	li	a5,16
  return 0;
    80003ec8:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003eca:	02f71863          	bne	a4,a5,80003efa <dirlink+0xb2>
}
    80003ece:	70e2                	ld	ra,56(sp)
    80003ed0:	7442                	ld	s0,48(sp)
    80003ed2:	74a2                	ld	s1,40(sp)
    80003ed4:	7902                	ld	s2,32(sp)
    80003ed6:	69e2                	ld	s3,24(sp)
    80003ed8:	6a42                	ld	s4,16(sp)
    80003eda:	6121                	addi	sp,sp,64
    80003edc:	8082                	ret
    iput(ip);
    80003ede:	00000097          	auipc	ra,0x0
    80003ee2:	a30080e7          	jalr	-1488(ra) # 8000390e <iput>
    return -1;
    80003ee6:	557d                	li	a0,-1
    80003ee8:	b7dd                	j	80003ece <dirlink+0x86>
      panic("dirlink read");
    80003eea:	00004517          	auipc	a0,0x4
    80003eee:	74e50513          	addi	a0,a0,1870 # 80008638 <syscalls+0x1d8>
    80003ef2:	ffffc097          	auipc	ra,0xffffc
    80003ef6:	64c080e7          	jalr	1612(ra) # 8000053e <panic>
    panic("dirlink");
    80003efa:	00005517          	auipc	a0,0x5
    80003efe:	84e50513          	addi	a0,a0,-1970 # 80008748 <syscalls+0x2e8>
    80003f02:	ffffc097          	auipc	ra,0xffffc
    80003f06:	63c080e7          	jalr	1596(ra) # 8000053e <panic>

0000000080003f0a <namei>:

struct inode*
namei(char *path)
{
    80003f0a:	1101                	addi	sp,sp,-32
    80003f0c:	ec06                	sd	ra,24(sp)
    80003f0e:	e822                	sd	s0,16(sp)
    80003f10:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80003f12:	fe040613          	addi	a2,s0,-32
    80003f16:	4581                	li	a1,0
    80003f18:	00000097          	auipc	ra,0x0
    80003f1c:	dd0080e7          	jalr	-560(ra) # 80003ce8 <namex>
}
    80003f20:	60e2                	ld	ra,24(sp)
    80003f22:	6442                	ld	s0,16(sp)
    80003f24:	6105                	addi	sp,sp,32
    80003f26:	8082                	ret

0000000080003f28 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80003f28:	1141                	addi	sp,sp,-16
    80003f2a:	e406                	sd	ra,8(sp)
    80003f2c:	e022                	sd	s0,0(sp)
    80003f2e:	0800                	addi	s0,sp,16
    80003f30:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80003f32:	4585                	li	a1,1
    80003f34:	00000097          	auipc	ra,0x0
    80003f38:	db4080e7          	jalr	-588(ra) # 80003ce8 <namex>
}
    80003f3c:	60a2                	ld	ra,8(sp)
    80003f3e:	6402                	ld	s0,0(sp)
    80003f40:	0141                	addi	sp,sp,16
    80003f42:	8082                	ret

0000000080003f44 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80003f44:	1101                	addi	sp,sp,-32
    80003f46:	ec06                	sd	ra,24(sp)
    80003f48:	e822                	sd	s0,16(sp)
    80003f4a:	e426                	sd	s1,8(sp)
    80003f4c:	e04a                	sd	s2,0(sp)
    80003f4e:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80003f50:	0001d917          	auipc	s2,0x1d
    80003f54:	54090913          	addi	s2,s2,1344 # 80021490 <log>
    80003f58:	01892583          	lw	a1,24(s2)
    80003f5c:	02892503          	lw	a0,40(s2)
    80003f60:	fffff097          	auipc	ra,0xfffff
    80003f64:	ff2080e7          	jalr	-14(ra) # 80002f52 <bread>
    80003f68:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80003f6a:	02c92683          	lw	a3,44(s2)
    80003f6e:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80003f70:	02d05763          	blez	a3,80003f9e <write_head+0x5a>
    80003f74:	0001d797          	auipc	a5,0x1d
    80003f78:	54c78793          	addi	a5,a5,1356 # 800214c0 <log+0x30>
    80003f7c:	05c50713          	addi	a4,a0,92
    80003f80:	36fd                	addiw	a3,a3,-1
    80003f82:	1682                	slli	a3,a3,0x20
    80003f84:	9281                	srli	a3,a3,0x20
    80003f86:	068a                	slli	a3,a3,0x2
    80003f88:	0001d617          	auipc	a2,0x1d
    80003f8c:	53c60613          	addi	a2,a2,1340 # 800214c4 <log+0x34>
    80003f90:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80003f92:	4390                	lw	a2,0(a5)
    80003f94:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80003f96:	0791                	addi	a5,a5,4
    80003f98:	0711                	addi	a4,a4,4
    80003f9a:	fed79ce3          	bne	a5,a3,80003f92 <write_head+0x4e>
  }
  bwrite(buf);
    80003f9e:	8526                	mv	a0,s1
    80003fa0:	fffff097          	auipc	ra,0xfffff
    80003fa4:	0a4080e7          	jalr	164(ra) # 80003044 <bwrite>
  brelse(buf);
    80003fa8:	8526                	mv	a0,s1
    80003faa:	fffff097          	auipc	ra,0xfffff
    80003fae:	0d8080e7          	jalr	216(ra) # 80003082 <brelse>
}
    80003fb2:	60e2                	ld	ra,24(sp)
    80003fb4:	6442                	ld	s0,16(sp)
    80003fb6:	64a2                	ld	s1,8(sp)
    80003fb8:	6902                	ld	s2,0(sp)
    80003fba:	6105                	addi	sp,sp,32
    80003fbc:	8082                	ret

0000000080003fbe <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80003fbe:	0001d797          	auipc	a5,0x1d
    80003fc2:	4fe7a783          	lw	a5,1278(a5) # 800214bc <log+0x2c>
    80003fc6:	0af05d63          	blez	a5,80004080 <install_trans+0xc2>
{
    80003fca:	7139                	addi	sp,sp,-64
    80003fcc:	fc06                	sd	ra,56(sp)
    80003fce:	f822                	sd	s0,48(sp)
    80003fd0:	f426                	sd	s1,40(sp)
    80003fd2:	f04a                	sd	s2,32(sp)
    80003fd4:	ec4e                	sd	s3,24(sp)
    80003fd6:	e852                	sd	s4,16(sp)
    80003fd8:	e456                	sd	s5,8(sp)
    80003fda:	e05a                	sd	s6,0(sp)
    80003fdc:	0080                	addi	s0,sp,64
    80003fde:	8b2a                	mv	s6,a0
    80003fe0:	0001da97          	auipc	s5,0x1d
    80003fe4:	4e0a8a93          	addi	s5,s5,1248 # 800214c0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003fe8:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80003fea:	0001d997          	auipc	s3,0x1d
    80003fee:	4a698993          	addi	s3,s3,1190 # 80021490 <log>
    80003ff2:	a035                	j	8000401e <install_trans+0x60>
      bunpin(dbuf);
    80003ff4:	8526                	mv	a0,s1
    80003ff6:	fffff097          	auipc	ra,0xfffff
    80003ffa:	166080e7          	jalr	358(ra) # 8000315c <bunpin>
    brelse(lbuf);
    80003ffe:	854a                	mv	a0,s2
    80004000:	fffff097          	auipc	ra,0xfffff
    80004004:	082080e7          	jalr	130(ra) # 80003082 <brelse>
    brelse(dbuf);
    80004008:	8526                	mv	a0,s1
    8000400a:	fffff097          	auipc	ra,0xfffff
    8000400e:	078080e7          	jalr	120(ra) # 80003082 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004012:	2a05                	addiw	s4,s4,1
    80004014:	0a91                	addi	s5,s5,4
    80004016:	02c9a783          	lw	a5,44(s3)
    8000401a:	04fa5963          	bge	s4,a5,8000406c <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    8000401e:	0189a583          	lw	a1,24(s3)
    80004022:	014585bb          	addw	a1,a1,s4
    80004026:	2585                	addiw	a1,a1,1
    80004028:	0289a503          	lw	a0,40(s3)
    8000402c:	fffff097          	auipc	ra,0xfffff
    80004030:	f26080e7          	jalr	-218(ra) # 80002f52 <bread>
    80004034:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004036:	000aa583          	lw	a1,0(s5)
    8000403a:	0289a503          	lw	a0,40(s3)
    8000403e:	fffff097          	auipc	ra,0xfffff
    80004042:	f14080e7          	jalr	-236(ra) # 80002f52 <bread>
    80004046:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004048:	40000613          	li	a2,1024
    8000404c:	05890593          	addi	a1,s2,88
    80004050:	05850513          	addi	a0,a0,88
    80004054:	ffffd097          	auipc	ra,0xffffd
    80004058:	cec080e7          	jalr	-788(ra) # 80000d40 <memmove>
    bwrite(dbuf);  // write dst to disk
    8000405c:	8526                	mv	a0,s1
    8000405e:	fffff097          	auipc	ra,0xfffff
    80004062:	fe6080e7          	jalr	-26(ra) # 80003044 <bwrite>
    if(recovering == 0)
    80004066:	f80b1ce3          	bnez	s6,80003ffe <install_trans+0x40>
    8000406a:	b769                	j	80003ff4 <install_trans+0x36>
}
    8000406c:	70e2                	ld	ra,56(sp)
    8000406e:	7442                	ld	s0,48(sp)
    80004070:	74a2                	ld	s1,40(sp)
    80004072:	7902                	ld	s2,32(sp)
    80004074:	69e2                	ld	s3,24(sp)
    80004076:	6a42                	ld	s4,16(sp)
    80004078:	6aa2                	ld	s5,8(sp)
    8000407a:	6b02                	ld	s6,0(sp)
    8000407c:	6121                	addi	sp,sp,64
    8000407e:	8082                	ret
    80004080:	8082                	ret

0000000080004082 <initlog>:
{
    80004082:	7179                	addi	sp,sp,-48
    80004084:	f406                	sd	ra,40(sp)
    80004086:	f022                	sd	s0,32(sp)
    80004088:	ec26                	sd	s1,24(sp)
    8000408a:	e84a                	sd	s2,16(sp)
    8000408c:	e44e                	sd	s3,8(sp)
    8000408e:	1800                	addi	s0,sp,48
    80004090:	892a                	mv	s2,a0
    80004092:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004094:	0001d497          	auipc	s1,0x1d
    80004098:	3fc48493          	addi	s1,s1,1020 # 80021490 <log>
    8000409c:	00004597          	auipc	a1,0x4
    800040a0:	5ac58593          	addi	a1,a1,1452 # 80008648 <syscalls+0x1e8>
    800040a4:	8526                	mv	a0,s1
    800040a6:	ffffd097          	auipc	ra,0xffffd
    800040aa:	aae080e7          	jalr	-1362(ra) # 80000b54 <initlock>
  log.start = sb->logstart;
    800040ae:	0149a583          	lw	a1,20(s3)
    800040b2:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    800040b4:	0109a783          	lw	a5,16(s3)
    800040b8:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    800040ba:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    800040be:	854a                	mv	a0,s2
    800040c0:	fffff097          	auipc	ra,0xfffff
    800040c4:	e92080e7          	jalr	-366(ra) # 80002f52 <bread>
  log.lh.n = lh->n;
    800040c8:	4d3c                	lw	a5,88(a0)
    800040ca:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    800040cc:	02f05563          	blez	a5,800040f6 <initlog+0x74>
    800040d0:	05c50713          	addi	a4,a0,92
    800040d4:	0001d697          	auipc	a3,0x1d
    800040d8:	3ec68693          	addi	a3,a3,1004 # 800214c0 <log+0x30>
    800040dc:	37fd                	addiw	a5,a5,-1
    800040de:	1782                	slli	a5,a5,0x20
    800040e0:	9381                	srli	a5,a5,0x20
    800040e2:	078a                	slli	a5,a5,0x2
    800040e4:	06050613          	addi	a2,a0,96
    800040e8:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    800040ea:	4310                	lw	a2,0(a4)
    800040ec:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    800040ee:	0711                	addi	a4,a4,4
    800040f0:	0691                	addi	a3,a3,4
    800040f2:	fef71ce3          	bne	a4,a5,800040ea <initlog+0x68>
  brelse(buf);
    800040f6:	fffff097          	auipc	ra,0xfffff
    800040fa:	f8c080e7          	jalr	-116(ra) # 80003082 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    800040fe:	4505                	li	a0,1
    80004100:	00000097          	auipc	ra,0x0
    80004104:	ebe080e7          	jalr	-322(ra) # 80003fbe <install_trans>
  log.lh.n = 0;
    80004108:	0001d797          	auipc	a5,0x1d
    8000410c:	3a07aa23          	sw	zero,948(a5) # 800214bc <log+0x2c>
  write_head(); // clear the log
    80004110:	00000097          	auipc	ra,0x0
    80004114:	e34080e7          	jalr	-460(ra) # 80003f44 <write_head>
}
    80004118:	70a2                	ld	ra,40(sp)
    8000411a:	7402                	ld	s0,32(sp)
    8000411c:	64e2                	ld	s1,24(sp)
    8000411e:	6942                	ld	s2,16(sp)
    80004120:	69a2                	ld	s3,8(sp)
    80004122:	6145                	addi	sp,sp,48
    80004124:	8082                	ret

0000000080004126 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004126:	1101                	addi	sp,sp,-32
    80004128:	ec06                	sd	ra,24(sp)
    8000412a:	e822                	sd	s0,16(sp)
    8000412c:	e426                	sd	s1,8(sp)
    8000412e:	e04a                	sd	s2,0(sp)
    80004130:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004132:	0001d517          	auipc	a0,0x1d
    80004136:	35e50513          	addi	a0,a0,862 # 80021490 <log>
    8000413a:	ffffd097          	auipc	ra,0xffffd
    8000413e:	aaa080e7          	jalr	-1366(ra) # 80000be4 <acquire>
  while(1){
    if(log.committing){
    80004142:	0001d497          	auipc	s1,0x1d
    80004146:	34e48493          	addi	s1,s1,846 # 80021490 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000414a:	4979                	li	s2,30
    8000414c:	a039                	j	8000415a <begin_op+0x34>
      sleep(&log, &log.lock);
    8000414e:	85a6                	mv	a1,s1
    80004150:	8526                	mv	a0,s1
    80004152:	ffffe097          	auipc	ra,0xffffe
    80004156:	012080e7          	jalr	18(ra) # 80002164 <sleep>
    if(log.committing){
    8000415a:	50dc                	lw	a5,36(s1)
    8000415c:	fbed                	bnez	a5,8000414e <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000415e:	509c                	lw	a5,32(s1)
    80004160:	0017871b          	addiw	a4,a5,1
    80004164:	0007069b          	sext.w	a3,a4
    80004168:	0027179b          	slliw	a5,a4,0x2
    8000416c:	9fb9                	addw	a5,a5,a4
    8000416e:	0017979b          	slliw	a5,a5,0x1
    80004172:	54d8                	lw	a4,44(s1)
    80004174:	9fb9                	addw	a5,a5,a4
    80004176:	00f95963          	bge	s2,a5,80004188 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    8000417a:	85a6                	mv	a1,s1
    8000417c:	8526                	mv	a0,s1
    8000417e:	ffffe097          	auipc	ra,0xffffe
    80004182:	fe6080e7          	jalr	-26(ra) # 80002164 <sleep>
    80004186:	bfd1                	j	8000415a <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004188:	0001d517          	auipc	a0,0x1d
    8000418c:	30850513          	addi	a0,a0,776 # 80021490 <log>
    80004190:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004192:	ffffd097          	auipc	ra,0xffffd
    80004196:	b06080e7          	jalr	-1274(ra) # 80000c98 <release>
      break;
    }
  }
}
    8000419a:	60e2                	ld	ra,24(sp)
    8000419c:	6442                	ld	s0,16(sp)
    8000419e:	64a2                	ld	s1,8(sp)
    800041a0:	6902                	ld	s2,0(sp)
    800041a2:	6105                	addi	sp,sp,32
    800041a4:	8082                	ret

00000000800041a6 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    800041a6:	7139                	addi	sp,sp,-64
    800041a8:	fc06                	sd	ra,56(sp)
    800041aa:	f822                	sd	s0,48(sp)
    800041ac:	f426                	sd	s1,40(sp)
    800041ae:	f04a                	sd	s2,32(sp)
    800041b0:	ec4e                	sd	s3,24(sp)
    800041b2:	e852                	sd	s4,16(sp)
    800041b4:	e456                	sd	s5,8(sp)
    800041b6:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    800041b8:	0001d497          	auipc	s1,0x1d
    800041bc:	2d848493          	addi	s1,s1,728 # 80021490 <log>
    800041c0:	8526                	mv	a0,s1
    800041c2:	ffffd097          	auipc	ra,0xffffd
    800041c6:	a22080e7          	jalr	-1502(ra) # 80000be4 <acquire>
  log.outstanding -= 1;
    800041ca:	509c                	lw	a5,32(s1)
    800041cc:	37fd                	addiw	a5,a5,-1
    800041ce:	0007891b          	sext.w	s2,a5
    800041d2:	d09c                	sw	a5,32(s1)
  if(log.committing)
    800041d4:	50dc                	lw	a5,36(s1)
    800041d6:	efb9                	bnez	a5,80004234 <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    800041d8:	06091663          	bnez	s2,80004244 <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    800041dc:	0001d497          	auipc	s1,0x1d
    800041e0:	2b448493          	addi	s1,s1,692 # 80021490 <log>
    800041e4:	4785                	li	a5,1
    800041e6:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    800041e8:	8526                	mv	a0,s1
    800041ea:	ffffd097          	auipc	ra,0xffffd
    800041ee:	aae080e7          	jalr	-1362(ra) # 80000c98 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    800041f2:	54dc                	lw	a5,44(s1)
    800041f4:	06f04763          	bgtz	a5,80004262 <end_op+0xbc>
    acquire(&log.lock);
    800041f8:	0001d497          	auipc	s1,0x1d
    800041fc:	29848493          	addi	s1,s1,664 # 80021490 <log>
    80004200:	8526                	mv	a0,s1
    80004202:	ffffd097          	auipc	ra,0xffffd
    80004206:	9e2080e7          	jalr	-1566(ra) # 80000be4 <acquire>
    log.committing = 0;
    8000420a:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    8000420e:	8526                	mv	a0,s1
    80004210:	ffffe097          	auipc	ra,0xffffe
    80004214:	0e0080e7          	jalr	224(ra) # 800022f0 <wakeup>
    release(&log.lock);
    80004218:	8526                	mv	a0,s1
    8000421a:	ffffd097          	auipc	ra,0xffffd
    8000421e:	a7e080e7          	jalr	-1410(ra) # 80000c98 <release>
}
    80004222:	70e2                	ld	ra,56(sp)
    80004224:	7442                	ld	s0,48(sp)
    80004226:	74a2                	ld	s1,40(sp)
    80004228:	7902                	ld	s2,32(sp)
    8000422a:	69e2                	ld	s3,24(sp)
    8000422c:	6a42                	ld	s4,16(sp)
    8000422e:	6aa2                	ld	s5,8(sp)
    80004230:	6121                	addi	sp,sp,64
    80004232:	8082                	ret
    panic("log.committing");
    80004234:	00004517          	auipc	a0,0x4
    80004238:	41c50513          	addi	a0,a0,1052 # 80008650 <syscalls+0x1f0>
    8000423c:	ffffc097          	auipc	ra,0xffffc
    80004240:	302080e7          	jalr	770(ra) # 8000053e <panic>
    wakeup(&log);
    80004244:	0001d497          	auipc	s1,0x1d
    80004248:	24c48493          	addi	s1,s1,588 # 80021490 <log>
    8000424c:	8526                	mv	a0,s1
    8000424e:	ffffe097          	auipc	ra,0xffffe
    80004252:	0a2080e7          	jalr	162(ra) # 800022f0 <wakeup>
  release(&log.lock);
    80004256:	8526                	mv	a0,s1
    80004258:	ffffd097          	auipc	ra,0xffffd
    8000425c:	a40080e7          	jalr	-1472(ra) # 80000c98 <release>
  if(do_commit){
    80004260:	b7c9                	j	80004222 <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004262:	0001da97          	auipc	s5,0x1d
    80004266:	25ea8a93          	addi	s5,s5,606 # 800214c0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    8000426a:	0001da17          	auipc	s4,0x1d
    8000426e:	226a0a13          	addi	s4,s4,550 # 80021490 <log>
    80004272:	018a2583          	lw	a1,24(s4)
    80004276:	012585bb          	addw	a1,a1,s2
    8000427a:	2585                	addiw	a1,a1,1
    8000427c:	028a2503          	lw	a0,40(s4)
    80004280:	fffff097          	auipc	ra,0xfffff
    80004284:	cd2080e7          	jalr	-814(ra) # 80002f52 <bread>
    80004288:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    8000428a:	000aa583          	lw	a1,0(s5)
    8000428e:	028a2503          	lw	a0,40(s4)
    80004292:	fffff097          	auipc	ra,0xfffff
    80004296:	cc0080e7          	jalr	-832(ra) # 80002f52 <bread>
    8000429a:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    8000429c:	40000613          	li	a2,1024
    800042a0:	05850593          	addi	a1,a0,88
    800042a4:	05848513          	addi	a0,s1,88
    800042a8:	ffffd097          	auipc	ra,0xffffd
    800042ac:	a98080e7          	jalr	-1384(ra) # 80000d40 <memmove>
    bwrite(to);  // write the log
    800042b0:	8526                	mv	a0,s1
    800042b2:	fffff097          	auipc	ra,0xfffff
    800042b6:	d92080e7          	jalr	-622(ra) # 80003044 <bwrite>
    brelse(from);
    800042ba:	854e                	mv	a0,s3
    800042bc:	fffff097          	auipc	ra,0xfffff
    800042c0:	dc6080e7          	jalr	-570(ra) # 80003082 <brelse>
    brelse(to);
    800042c4:	8526                	mv	a0,s1
    800042c6:	fffff097          	auipc	ra,0xfffff
    800042ca:	dbc080e7          	jalr	-580(ra) # 80003082 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800042ce:	2905                	addiw	s2,s2,1
    800042d0:	0a91                	addi	s5,s5,4
    800042d2:	02ca2783          	lw	a5,44(s4)
    800042d6:	f8f94ee3          	blt	s2,a5,80004272 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    800042da:	00000097          	auipc	ra,0x0
    800042de:	c6a080e7          	jalr	-918(ra) # 80003f44 <write_head>
    install_trans(0); // Now install writes to home locations
    800042e2:	4501                	li	a0,0
    800042e4:	00000097          	auipc	ra,0x0
    800042e8:	cda080e7          	jalr	-806(ra) # 80003fbe <install_trans>
    log.lh.n = 0;
    800042ec:	0001d797          	auipc	a5,0x1d
    800042f0:	1c07a823          	sw	zero,464(a5) # 800214bc <log+0x2c>
    write_head();    // Erase the transaction from the log
    800042f4:	00000097          	auipc	ra,0x0
    800042f8:	c50080e7          	jalr	-944(ra) # 80003f44 <write_head>
    800042fc:	bdf5                	j	800041f8 <end_op+0x52>

00000000800042fe <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    800042fe:	1101                	addi	sp,sp,-32
    80004300:	ec06                	sd	ra,24(sp)
    80004302:	e822                	sd	s0,16(sp)
    80004304:	e426                	sd	s1,8(sp)
    80004306:	e04a                	sd	s2,0(sp)
    80004308:	1000                	addi	s0,sp,32
    8000430a:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    8000430c:	0001d917          	auipc	s2,0x1d
    80004310:	18490913          	addi	s2,s2,388 # 80021490 <log>
    80004314:	854a                	mv	a0,s2
    80004316:	ffffd097          	auipc	ra,0xffffd
    8000431a:	8ce080e7          	jalr	-1842(ra) # 80000be4 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    8000431e:	02c92603          	lw	a2,44(s2)
    80004322:	47f5                	li	a5,29
    80004324:	06c7c563          	blt	a5,a2,8000438e <log_write+0x90>
    80004328:	0001d797          	auipc	a5,0x1d
    8000432c:	1847a783          	lw	a5,388(a5) # 800214ac <log+0x1c>
    80004330:	37fd                	addiw	a5,a5,-1
    80004332:	04f65e63          	bge	a2,a5,8000438e <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004336:	0001d797          	auipc	a5,0x1d
    8000433a:	17a7a783          	lw	a5,378(a5) # 800214b0 <log+0x20>
    8000433e:	06f05063          	blez	a5,8000439e <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004342:	4781                	li	a5,0
    80004344:	06c05563          	blez	a2,800043ae <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004348:	44cc                	lw	a1,12(s1)
    8000434a:	0001d717          	auipc	a4,0x1d
    8000434e:	17670713          	addi	a4,a4,374 # 800214c0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004352:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004354:	4314                	lw	a3,0(a4)
    80004356:	04b68c63          	beq	a3,a1,800043ae <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    8000435a:	2785                	addiw	a5,a5,1
    8000435c:	0711                	addi	a4,a4,4
    8000435e:	fef61be3          	bne	a2,a5,80004354 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004362:	0621                	addi	a2,a2,8
    80004364:	060a                	slli	a2,a2,0x2
    80004366:	0001d797          	auipc	a5,0x1d
    8000436a:	12a78793          	addi	a5,a5,298 # 80021490 <log>
    8000436e:	963e                	add	a2,a2,a5
    80004370:	44dc                	lw	a5,12(s1)
    80004372:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004374:	8526                	mv	a0,s1
    80004376:	fffff097          	auipc	ra,0xfffff
    8000437a:	daa080e7          	jalr	-598(ra) # 80003120 <bpin>
    log.lh.n++;
    8000437e:	0001d717          	auipc	a4,0x1d
    80004382:	11270713          	addi	a4,a4,274 # 80021490 <log>
    80004386:	575c                	lw	a5,44(a4)
    80004388:	2785                	addiw	a5,a5,1
    8000438a:	d75c                	sw	a5,44(a4)
    8000438c:	a835                	j	800043c8 <log_write+0xca>
    panic("too big a transaction");
    8000438e:	00004517          	auipc	a0,0x4
    80004392:	2d250513          	addi	a0,a0,722 # 80008660 <syscalls+0x200>
    80004396:	ffffc097          	auipc	ra,0xffffc
    8000439a:	1a8080e7          	jalr	424(ra) # 8000053e <panic>
    panic("log_write outside of trans");
    8000439e:	00004517          	auipc	a0,0x4
    800043a2:	2da50513          	addi	a0,a0,730 # 80008678 <syscalls+0x218>
    800043a6:	ffffc097          	auipc	ra,0xffffc
    800043aa:	198080e7          	jalr	408(ra) # 8000053e <panic>
  log.lh.block[i] = b->blockno;
    800043ae:	00878713          	addi	a4,a5,8
    800043b2:	00271693          	slli	a3,a4,0x2
    800043b6:	0001d717          	auipc	a4,0x1d
    800043ba:	0da70713          	addi	a4,a4,218 # 80021490 <log>
    800043be:	9736                	add	a4,a4,a3
    800043c0:	44d4                	lw	a3,12(s1)
    800043c2:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    800043c4:	faf608e3          	beq	a2,a5,80004374 <log_write+0x76>
  }
  release(&log.lock);
    800043c8:	0001d517          	auipc	a0,0x1d
    800043cc:	0c850513          	addi	a0,a0,200 # 80021490 <log>
    800043d0:	ffffd097          	auipc	ra,0xffffd
    800043d4:	8c8080e7          	jalr	-1848(ra) # 80000c98 <release>
}
    800043d8:	60e2                	ld	ra,24(sp)
    800043da:	6442                	ld	s0,16(sp)
    800043dc:	64a2                	ld	s1,8(sp)
    800043de:	6902                	ld	s2,0(sp)
    800043e0:	6105                	addi	sp,sp,32
    800043e2:	8082                	ret

00000000800043e4 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    800043e4:	1101                	addi	sp,sp,-32
    800043e6:	ec06                	sd	ra,24(sp)
    800043e8:	e822                	sd	s0,16(sp)
    800043ea:	e426                	sd	s1,8(sp)
    800043ec:	e04a                	sd	s2,0(sp)
    800043ee:	1000                	addi	s0,sp,32
    800043f0:	84aa                	mv	s1,a0
    800043f2:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    800043f4:	00004597          	auipc	a1,0x4
    800043f8:	2a458593          	addi	a1,a1,676 # 80008698 <syscalls+0x238>
    800043fc:	0521                	addi	a0,a0,8
    800043fe:	ffffc097          	auipc	ra,0xffffc
    80004402:	756080e7          	jalr	1878(ra) # 80000b54 <initlock>
  lk->name = name;
    80004406:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    8000440a:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    8000440e:	0204a423          	sw	zero,40(s1)
}
    80004412:	60e2                	ld	ra,24(sp)
    80004414:	6442                	ld	s0,16(sp)
    80004416:	64a2                	ld	s1,8(sp)
    80004418:	6902                	ld	s2,0(sp)
    8000441a:	6105                	addi	sp,sp,32
    8000441c:	8082                	ret

000000008000441e <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    8000441e:	1101                	addi	sp,sp,-32
    80004420:	ec06                	sd	ra,24(sp)
    80004422:	e822                	sd	s0,16(sp)
    80004424:	e426                	sd	s1,8(sp)
    80004426:	e04a                	sd	s2,0(sp)
    80004428:	1000                	addi	s0,sp,32
    8000442a:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    8000442c:	00850913          	addi	s2,a0,8
    80004430:	854a                	mv	a0,s2
    80004432:	ffffc097          	auipc	ra,0xffffc
    80004436:	7b2080e7          	jalr	1970(ra) # 80000be4 <acquire>
  while (lk->locked) {
    8000443a:	409c                	lw	a5,0(s1)
    8000443c:	cb89                	beqz	a5,8000444e <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    8000443e:	85ca                	mv	a1,s2
    80004440:	8526                	mv	a0,s1
    80004442:	ffffe097          	auipc	ra,0xffffe
    80004446:	d22080e7          	jalr	-734(ra) # 80002164 <sleep>
  while (lk->locked) {
    8000444a:	409c                	lw	a5,0(s1)
    8000444c:	fbed                	bnez	a5,8000443e <acquiresleep+0x20>
  }
  lk->locked = 1;
    8000444e:	4785                	li	a5,1
    80004450:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004452:	ffffd097          	auipc	ra,0xffffd
    80004456:	660080e7          	jalr	1632(ra) # 80001ab2 <myproc>
    8000445a:	591c                	lw	a5,48(a0)
    8000445c:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    8000445e:	854a                	mv	a0,s2
    80004460:	ffffd097          	auipc	ra,0xffffd
    80004464:	838080e7          	jalr	-1992(ra) # 80000c98 <release>
}
    80004468:	60e2                	ld	ra,24(sp)
    8000446a:	6442                	ld	s0,16(sp)
    8000446c:	64a2                	ld	s1,8(sp)
    8000446e:	6902                	ld	s2,0(sp)
    80004470:	6105                	addi	sp,sp,32
    80004472:	8082                	ret

0000000080004474 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004474:	1101                	addi	sp,sp,-32
    80004476:	ec06                	sd	ra,24(sp)
    80004478:	e822                	sd	s0,16(sp)
    8000447a:	e426                	sd	s1,8(sp)
    8000447c:	e04a                	sd	s2,0(sp)
    8000447e:	1000                	addi	s0,sp,32
    80004480:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004482:	00850913          	addi	s2,a0,8
    80004486:	854a                	mv	a0,s2
    80004488:	ffffc097          	auipc	ra,0xffffc
    8000448c:	75c080e7          	jalr	1884(ra) # 80000be4 <acquire>
  lk->locked = 0;
    80004490:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004494:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004498:	8526                	mv	a0,s1
    8000449a:	ffffe097          	auipc	ra,0xffffe
    8000449e:	e56080e7          	jalr	-426(ra) # 800022f0 <wakeup>
  release(&lk->lk);
    800044a2:	854a                	mv	a0,s2
    800044a4:	ffffc097          	auipc	ra,0xffffc
    800044a8:	7f4080e7          	jalr	2036(ra) # 80000c98 <release>
}
    800044ac:	60e2                	ld	ra,24(sp)
    800044ae:	6442                	ld	s0,16(sp)
    800044b0:	64a2                	ld	s1,8(sp)
    800044b2:	6902                	ld	s2,0(sp)
    800044b4:	6105                	addi	sp,sp,32
    800044b6:	8082                	ret

00000000800044b8 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    800044b8:	7179                	addi	sp,sp,-48
    800044ba:	f406                	sd	ra,40(sp)
    800044bc:	f022                	sd	s0,32(sp)
    800044be:	ec26                	sd	s1,24(sp)
    800044c0:	e84a                	sd	s2,16(sp)
    800044c2:	e44e                	sd	s3,8(sp)
    800044c4:	1800                	addi	s0,sp,48
    800044c6:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    800044c8:	00850913          	addi	s2,a0,8
    800044cc:	854a                	mv	a0,s2
    800044ce:	ffffc097          	auipc	ra,0xffffc
    800044d2:	716080e7          	jalr	1814(ra) # 80000be4 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    800044d6:	409c                	lw	a5,0(s1)
    800044d8:	ef99                	bnez	a5,800044f6 <holdingsleep+0x3e>
    800044da:	4481                	li	s1,0
  release(&lk->lk);
    800044dc:	854a                	mv	a0,s2
    800044de:	ffffc097          	auipc	ra,0xffffc
    800044e2:	7ba080e7          	jalr	1978(ra) # 80000c98 <release>
  return r;
}
    800044e6:	8526                	mv	a0,s1
    800044e8:	70a2                	ld	ra,40(sp)
    800044ea:	7402                	ld	s0,32(sp)
    800044ec:	64e2                	ld	s1,24(sp)
    800044ee:	6942                	ld	s2,16(sp)
    800044f0:	69a2                	ld	s3,8(sp)
    800044f2:	6145                	addi	sp,sp,48
    800044f4:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    800044f6:	0284a983          	lw	s3,40(s1)
    800044fa:	ffffd097          	auipc	ra,0xffffd
    800044fe:	5b8080e7          	jalr	1464(ra) # 80001ab2 <myproc>
    80004502:	5904                	lw	s1,48(a0)
    80004504:	413484b3          	sub	s1,s1,s3
    80004508:	0014b493          	seqz	s1,s1
    8000450c:	bfc1                	j	800044dc <holdingsleep+0x24>

000000008000450e <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    8000450e:	1141                	addi	sp,sp,-16
    80004510:	e406                	sd	ra,8(sp)
    80004512:	e022                	sd	s0,0(sp)
    80004514:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004516:	00004597          	auipc	a1,0x4
    8000451a:	19258593          	addi	a1,a1,402 # 800086a8 <syscalls+0x248>
    8000451e:	0001d517          	auipc	a0,0x1d
    80004522:	0ba50513          	addi	a0,a0,186 # 800215d8 <ftable>
    80004526:	ffffc097          	auipc	ra,0xffffc
    8000452a:	62e080e7          	jalr	1582(ra) # 80000b54 <initlock>
}
    8000452e:	60a2                	ld	ra,8(sp)
    80004530:	6402                	ld	s0,0(sp)
    80004532:	0141                	addi	sp,sp,16
    80004534:	8082                	ret

0000000080004536 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004536:	1101                	addi	sp,sp,-32
    80004538:	ec06                	sd	ra,24(sp)
    8000453a:	e822                	sd	s0,16(sp)
    8000453c:	e426                	sd	s1,8(sp)
    8000453e:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004540:	0001d517          	auipc	a0,0x1d
    80004544:	09850513          	addi	a0,a0,152 # 800215d8 <ftable>
    80004548:	ffffc097          	auipc	ra,0xffffc
    8000454c:	69c080e7          	jalr	1692(ra) # 80000be4 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004550:	0001d497          	auipc	s1,0x1d
    80004554:	0a048493          	addi	s1,s1,160 # 800215f0 <ftable+0x18>
    80004558:	0001e717          	auipc	a4,0x1e
    8000455c:	03870713          	addi	a4,a4,56 # 80022590 <ftable+0xfb8>
    if(f->ref == 0){
    80004560:	40dc                	lw	a5,4(s1)
    80004562:	cf99                	beqz	a5,80004580 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004564:	02848493          	addi	s1,s1,40
    80004568:	fee49ce3          	bne	s1,a4,80004560 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    8000456c:	0001d517          	auipc	a0,0x1d
    80004570:	06c50513          	addi	a0,a0,108 # 800215d8 <ftable>
    80004574:	ffffc097          	auipc	ra,0xffffc
    80004578:	724080e7          	jalr	1828(ra) # 80000c98 <release>
  return 0;
    8000457c:	4481                	li	s1,0
    8000457e:	a819                	j	80004594 <filealloc+0x5e>
      f->ref = 1;
    80004580:	4785                	li	a5,1
    80004582:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004584:	0001d517          	auipc	a0,0x1d
    80004588:	05450513          	addi	a0,a0,84 # 800215d8 <ftable>
    8000458c:	ffffc097          	auipc	ra,0xffffc
    80004590:	70c080e7          	jalr	1804(ra) # 80000c98 <release>
}
    80004594:	8526                	mv	a0,s1
    80004596:	60e2                	ld	ra,24(sp)
    80004598:	6442                	ld	s0,16(sp)
    8000459a:	64a2                	ld	s1,8(sp)
    8000459c:	6105                	addi	sp,sp,32
    8000459e:	8082                	ret

00000000800045a0 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    800045a0:	1101                	addi	sp,sp,-32
    800045a2:	ec06                	sd	ra,24(sp)
    800045a4:	e822                	sd	s0,16(sp)
    800045a6:	e426                	sd	s1,8(sp)
    800045a8:	1000                	addi	s0,sp,32
    800045aa:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    800045ac:	0001d517          	auipc	a0,0x1d
    800045b0:	02c50513          	addi	a0,a0,44 # 800215d8 <ftable>
    800045b4:	ffffc097          	auipc	ra,0xffffc
    800045b8:	630080e7          	jalr	1584(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    800045bc:	40dc                	lw	a5,4(s1)
    800045be:	02f05263          	blez	a5,800045e2 <filedup+0x42>
    panic("filedup");
  f->ref++;
    800045c2:	2785                	addiw	a5,a5,1
    800045c4:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    800045c6:	0001d517          	auipc	a0,0x1d
    800045ca:	01250513          	addi	a0,a0,18 # 800215d8 <ftable>
    800045ce:	ffffc097          	auipc	ra,0xffffc
    800045d2:	6ca080e7          	jalr	1738(ra) # 80000c98 <release>
  return f;
}
    800045d6:	8526                	mv	a0,s1
    800045d8:	60e2                	ld	ra,24(sp)
    800045da:	6442                	ld	s0,16(sp)
    800045dc:	64a2                	ld	s1,8(sp)
    800045de:	6105                	addi	sp,sp,32
    800045e0:	8082                	ret
    panic("filedup");
    800045e2:	00004517          	auipc	a0,0x4
    800045e6:	0ce50513          	addi	a0,a0,206 # 800086b0 <syscalls+0x250>
    800045ea:	ffffc097          	auipc	ra,0xffffc
    800045ee:	f54080e7          	jalr	-172(ra) # 8000053e <panic>

00000000800045f2 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    800045f2:	7139                	addi	sp,sp,-64
    800045f4:	fc06                	sd	ra,56(sp)
    800045f6:	f822                	sd	s0,48(sp)
    800045f8:	f426                	sd	s1,40(sp)
    800045fa:	f04a                	sd	s2,32(sp)
    800045fc:	ec4e                	sd	s3,24(sp)
    800045fe:	e852                	sd	s4,16(sp)
    80004600:	e456                	sd	s5,8(sp)
    80004602:	0080                	addi	s0,sp,64
    80004604:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004606:	0001d517          	auipc	a0,0x1d
    8000460a:	fd250513          	addi	a0,a0,-46 # 800215d8 <ftable>
    8000460e:	ffffc097          	auipc	ra,0xffffc
    80004612:	5d6080e7          	jalr	1494(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    80004616:	40dc                	lw	a5,4(s1)
    80004618:	06f05163          	blez	a5,8000467a <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    8000461c:	37fd                	addiw	a5,a5,-1
    8000461e:	0007871b          	sext.w	a4,a5
    80004622:	c0dc                	sw	a5,4(s1)
    80004624:	06e04363          	bgtz	a4,8000468a <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004628:	0004a903          	lw	s2,0(s1)
    8000462c:	0094ca83          	lbu	s5,9(s1)
    80004630:	0104ba03          	ld	s4,16(s1)
    80004634:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004638:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    8000463c:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004640:	0001d517          	auipc	a0,0x1d
    80004644:	f9850513          	addi	a0,a0,-104 # 800215d8 <ftable>
    80004648:	ffffc097          	auipc	ra,0xffffc
    8000464c:	650080e7          	jalr	1616(ra) # 80000c98 <release>

  if(ff.type == FD_PIPE){
    80004650:	4785                	li	a5,1
    80004652:	04f90d63          	beq	s2,a5,800046ac <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004656:	3979                	addiw	s2,s2,-2
    80004658:	4785                	li	a5,1
    8000465a:	0527e063          	bltu	a5,s2,8000469a <fileclose+0xa8>
    begin_op();
    8000465e:	00000097          	auipc	ra,0x0
    80004662:	ac8080e7          	jalr	-1336(ra) # 80004126 <begin_op>
    iput(ff.ip);
    80004666:	854e                	mv	a0,s3
    80004668:	fffff097          	auipc	ra,0xfffff
    8000466c:	2a6080e7          	jalr	678(ra) # 8000390e <iput>
    end_op();
    80004670:	00000097          	auipc	ra,0x0
    80004674:	b36080e7          	jalr	-1226(ra) # 800041a6 <end_op>
    80004678:	a00d                	j	8000469a <fileclose+0xa8>
    panic("fileclose");
    8000467a:	00004517          	auipc	a0,0x4
    8000467e:	03e50513          	addi	a0,a0,62 # 800086b8 <syscalls+0x258>
    80004682:	ffffc097          	auipc	ra,0xffffc
    80004686:	ebc080e7          	jalr	-324(ra) # 8000053e <panic>
    release(&ftable.lock);
    8000468a:	0001d517          	auipc	a0,0x1d
    8000468e:	f4e50513          	addi	a0,a0,-178 # 800215d8 <ftable>
    80004692:	ffffc097          	auipc	ra,0xffffc
    80004696:	606080e7          	jalr	1542(ra) # 80000c98 <release>
  }
}
    8000469a:	70e2                	ld	ra,56(sp)
    8000469c:	7442                	ld	s0,48(sp)
    8000469e:	74a2                	ld	s1,40(sp)
    800046a0:	7902                	ld	s2,32(sp)
    800046a2:	69e2                	ld	s3,24(sp)
    800046a4:	6a42                	ld	s4,16(sp)
    800046a6:	6aa2                	ld	s5,8(sp)
    800046a8:	6121                	addi	sp,sp,64
    800046aa:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    800046ac:	85d6                	mv	a1,s5
    800046ae:	8552                	mv	a0,s4
    800046b0:	00000097          	auipc	ra,0x0
    800046b4:	34c080e7          	jalr	844(ra) # 800049fc <pipeclose>
    800046b8:	b7cd                	j	8000469a <fileclose+0xa8>

00000000800046ba <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    800046ba:	715d                	addi	sp,sp,-80
    800046bc:	e486                	sd	ra,72(sp)
    800046be:	e0a2                	sd	s0,64(sp)
    800046c0:	fc26                	sd	s1,56(sp)
    800046c2:	f84a                	sd	s2,48(sp)
    800046c4:	f44e                	sd	s3,40(sp)
    800046c6:	0880                	addi	s0,sp,80
    800046c8:	84aa                	mv	s1,a0
    800046ca:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    800046cc:	ffffd097          	auipc	ra,0xffffd
    800046d0:	3e6080e7          	jalr	998(ra) # 80001ab2 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    800046d4:	409c                	lw	a5,0(s1)
    800046d6:	37f9                	addiw	a5,a5,-2
    800046d8:	4705                	li	a4,1
    800046da:	04f76763          	bltu	a4,a5,80004728 <filestat+0x6e>
    800046de:	892a                	mv	s2,a0
    ilock(f->ip);
    800046e0:	6c88                	ld	a0,24(s1)
    800046e2:	fffff097          	auipc	ra,0xfffff
    800046e6:	072080e7          	jalr	114(ra) # 80003754 <ilock>
    stati(f->ip, &st);
    800046ea:	fb840593          	addi	a1,s0,-72
    800046ee:	6c88                	ld	a0,24(s1)
    800046f0:	fffff097          	auipc	ra,0xfffff
    800046f4:	2ee080e7          	jalr	750(ra) # 800039de <stati>
    iunlock(f->ip);
    800046f8:	6c88                	ld	a0,24(s1)
    800046fa:	fffff097          	auipc	ra,0xfffff
    800046fe:	11c080e7          	jalr	284(ra) # 80003816 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004702:	46e1                	li	a3,24
    80004704:	fb840613          	addi	a2,s0,-72
    80004708:	85ce                	mv	a1,s3
    8000470a:	05893503          	ld	a0,88(s2)
    8000470e:	ffffd097          	auipc	ra,0xffffd
    80004712:	f64080e7          	jalr	-156(ra) # 80001672 <copyout>
    80004716:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    8000471a:	60a6                	ld	ra,72(sp)
    8000471c:	6406                	ld	s0,64(sp)
    8000471e:	74e2                	ld	s1,56(sp)
    80004720:	7942                	ld	s2,48(sp)
    80004722:	79a2                	ld	s3,40(sp)
    80004724:	6161                	addi	sp,sp,80
    80004726:	8082                	ret
  return -1;
    80004728:	557d                	li	a0,-1
    8000472a:	bfc5                	j	8000471a <filestat+0x60>

000000008000472c <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    8000472c:	7179                	addi	sp,sp,-48
    8000472e:	f406                	sd	ra,40(sp)
    80004730:	f022                	sd	s0,32(sp)
    80004732:	ec26                	sd	s1,24(sp)
    80004734:	e84a                	sd	s2,16(sp)
    80004736:	e44e                	sd	s3,8(sp)
    80004738:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    8000473a:	00854783          	lbu	a5,8(a0)
    8000473e:	c3d5                	beqz	a5,800047e2 <fileread+0xb6>
    80004740:	84aa                	mv	s1,a0
    80004742:	89ae                	mv	s3,a1
    80004744:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004746:	411c                	lw	a5,0(a0)
    80004748:	4705                	li	a4,1
    8000474a:	04e78963          	beq	a5,a4,8000479c <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    8000474e:	470d                	li	a4,3
    80004750:	04e78d63          	beq	a5,a4,800047aa <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004754:	4709                	li	a4,2
    80004756:	06e79e63          	bne	a5,a4,800047d2 <fileread+0xa6>
    ilock(f->ip);
    8000475a:	6d08                	ld	a0,24(a0)
    8000475c:	fffff097          	auipc	ra,0xfffff
    80004760:	ff8080e7          	jalr	-8(ra) # 80003754 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004764:	874a                	mv	a4,s2
    80004766:	5094                	lw	a3,32(s1)
    80004768:	864e                	mv	a2,s3
    8000476a:	4585                	li	a1,1
    8000476c:	6c88                	ld	a0,24(s1)
    8000476e:	fffff097          	auipc	ra,0xfffff
    80004772:	29a080e7          	jalr	666(ra) # 80003a08 <readi>
    80004776:	892a                	mv	s2,a0
    80004778:	00a05563          	blez	a0,80004782 <fileread+0x56>
      f->off += r;
    8000477c:	509c                	lw	a5,32(s1)
    8000477e:	9fa9                	addw	a5,a5,a0
    80004780:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004782:	6c88                	ld	a0,24(s1)
    80004784:	fffff097          	auipc	ra,0xfffff
    80004788:	092080e7          	jalr	146(ra) # 80003816 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    8000478c:	854a                	mv	a0,s2
    8000478e:	70a2                	ld	ra,40(sp)
    80004790:	7402                	ld	s0,32(sp)
    80004792:	64e2                	ld	s1,24(sp)
    80004794:	6942                	ld	s2,16(sp)
    80004796:	69a2                	ld	s3,8(sp)
    80004798:	6145                	addi	sp,sp,48
    8000479a:	8082                	ret
    r = piperead(f->pipe, addr, n);
    8000479c:	6908                	ld	a0,16(a0)
    8000479e:	00000097          	auipc	ra,0x0
    800047a2:	3c8080e7          	jalr	968(ra) # 80004b66 <piperead>
    800047a6:	892a                	mv	s2,a0
    800047a8:	b7d5                	j	8000478c <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    800047aa:	02451783          	lh	a5,36(a0)
    800047ae:	03079693          	slli	a3,a5,0x30
    800047b2:	92c1                	srli	a3,a3,0x30
    800047b4:	4725                	li	a4,9
    800047b6:	02d76863          	bltu	a4,a3,800047e6 <fileread+0xba>
    800047ba:	0792                	slli	a5,a5,0x4
    800047bc:	0001d717          	auipc	a4,0x1d
    800047c0:	d7c70713          	addi	a4,a4,-644 # 80021538 <devsw>
    800047c4:	97ba                	add	a5,a5,a4
    800047c6:	639c                	ld	a5,0(a5)
    800047c8:	c38d                	beqz	a5,800047ea <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    800047ca:	4505                	li	a0,1
    800047cc:	9782                	jalr	a5
    800047ce:	892a                	mv	s2,a0
    800047d0:	bf75                	j	8000478c <fileread+0x60>
    panic("fileread");
    800047d2:	00004517          	auipc	a0,0x4
    800047d6:	ef650513          	addi	a0,a0,-266 # 800086c8 <syscalls+0x268>
    800047da:	ffffc097          	auipc	ra,0xffffc
    800047de:	d64080e7          	jalr	-668(ra) # 8000053e <panic>
    return -1;
    800047e2:	597d                	li	s2,-1
    800047e4:	b765                	j	8000478c <fileread+0x60>
      return -1;
    800047e6:	597d                	li	s2,-1
    800047e8:	b755                	j	8000478c <fileread+0x60>
    800047ea:	597d                	li	s2,-1
    800047ec:	b745                	j	8000478c <fileread+0x60>

00000000800047ee <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    800047ee:	715d                	addi	sp,sp,-80
    800047f0:	e486                	sd	ra,72(sp)
    800047f2:	e0a2                	sd	s0,64(sp)
    800047f4:	fc26                	sd	s1,56(sp)
    800047f6:	f84a                	sd	s2,48(sp)
    800047f8:	f44e                	sd	s3,40(sp)
    800047fa:	f052                	sd	s4,32(sp)
    800047fc:	ec56                	sd	s5,24(sp)
    800047fe:	e85a                	sd	s6,16(sp)
    80004800:	e45e                	sd	s7,8(sp)
    80004802:	e062                	sd	s8,0(sp)
    80004804:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004806:	00954783          	lbu	a5,9(a0)
    8000480a:	10078663          	beqz	a5,80004916 <filewrite+0x128>
    8000480e:	892a                	mv	s2,a0
    80004810:	8aae                	mv	s5,a1
    80004812:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004814:	411c                	lw	a5,0(a0)
    80004816:	4705                	li	a4,1
    80004818:	02e78263          	beq	a5,a4,8000483c <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    8000481c:	470d                	li	a4,3
    8000481e:	02e78663          	beq	a5,a4,8000484a <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004822:	4709                	li	a4,2
    80004824:	0ee79163          	bne	a5,a4,80004906 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004828:	0ac05d63          	blez	a2,800048e2 <filewrite+0xf4>
    int i = 0;
    8000482c:	4981                	li	s3,0
    8000482e:	6b05                	lui	s6,0x1
    80004830:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004834:	6b85                	lui	s7,0x1
    80004836:	c00b8b9b          	addiw	s7,s7,-1024
    8000483a:	a861                	j	800048d2 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    8000483c:	6908                	ld	a0,16(a0)
    8000483e:	00000097          	auipc	ra,0x0
    80004842:	22e080e7          	jalr	558(ra) # 80004a6c <pipewrite>
    80004846:	8a2a                	mv	s4,a0
    80004848:	a045                	j	800048e8 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    8000484a:	02451783          	lh	a5,36(a0)
    8000484e:	03079693          	slli	a3,a5,0x30
    80004852:	92c1                	srli	a3,a3,0x30
    80004854:	4725                	li	a4,9
    80004856:	0cd76263          	bltu	a4,a3,8000491a <filewrite+0x12c>
    8000485a:	0792                	slli	a5,a5,0x4
    8000485c:	0001d717          	auipc	a4,0x1d
    80004860:	cdc70713          	addi	a4,a4,-804 # 80021538 <devsw>
    80004864:	97ba                	add	a5,a5,a4
    80004866:	679c                	ld	a5,8(a5)
    80004868:	cbdd                	beqz	a5,8000491e <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    8000486a:	4505                	li	a0,1
    8000486c:	9782                	jalr	a5
    8000486e:	8a2a                	mv	s4,a0
    80004870:	a8a5                	j	800048e8 <filewrite+0xfa>
    80004872:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004876:	00000097          	auipc	ra,0x0
    8000487a:	8b0080e7          	jalr	-1872(ra) # 80004126 <begin_op>
      ilock(f->ip);
    8000487e:	01893503          	ld	a0,24(s2)
    80004882:	fffff097          	auipc	ra,0xfffff
    80004886:	ed2080e7          	jalr	-302(ra) # 80003754 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    8000488a:	8762                	mv	a4,s8
    8000488c:	02092683          	lw	a3,32(s2)
    80004890:	01598633          	add	a2,s3,s5
    80004894:	4585                	li	a1,1
    80004896:	01893503          	ld	a0,24(s2)
    8000489a:	fffff097          	auipc	ra,0xfffff
    8000489e:	266080e7          	jalr	614(ra) # 80003b00 <writei>
    800048a2:	84aa                	mv	s1,a0
    800048a4:	00a05763          	blez	a0,800048b2 <filewrite+0xc4>
        f->off += r;
    800048a8:	02092783          	lw	a5,32(s2)
    800048ac:	9fa9                	addw	a5,a5,a0
    800048ae:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    800048b2:	01893503          	ld	a0,24(s2)
    800048b6:	fffff097          	auipc	ra,0xfffff
    800048ba:	f60080e7          	jalr	-160(ra) # 80003816 <iunlock>
      end_op();
    800048be:	00000097          	auipc	ra,0x0
    800048c2:	8e8080e7          	jalr	-1816(ra) # 800041a6 <end_op>

      if(r != n1){
    800048c6:	009c1f63          	bne	s8,s1,800048e4 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    800048ca:	013489bb          	addw	s3,s1,s3
    while(i < n){
    800048ce:	0149db63          	bge	s3,s4,800048e4 <filewrite+0xf6>
      int n1 = n - i;
    800048d2:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    800048d6:	84be                	mv	s1,a5
    800048d8:	2781                	sext.w	a5,a5
    800048da:	f8fb5ce3          	bge	s6,a5,80004872 <filewrite+0x84>
    800048de:	84de                	mv	s1,s7
    800048e0:	bf49                	j	80004872 <filewrite+0x84>
    int i = 0;
    800048e2:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    800048e4:	013a1f63          	bne	s4,s3,80004902 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    800048e8:	8552                	mv	a0,s4
    800048ea:	60a6                	ld	ra,72(sp)
    800048ec:	6406                	ld	s0,64(sp)
    800048ee:	74e2                	ld	s1,56(sp)
    800048f0:	7942                	ld	s2,48(sp)
    800048f2:	79a2                	ld	s3,40(sp)
    800048f4:	7a02                	ld	s4,32(sp)
    800048f6:	6ae2                	ld	s5,24(sp)
    800048f8:	6b42                	ld	s6,16(sp)
    800048fa:	6ba2                	ld	s7,8(sp)
    800048fc:	6c02                	ld	s8,0(sp)
    800048fe:	6161                	addi	sp,sp,80
    80004900:	8082                	ret
    ret = (i == n ? n : -1);
    80004902:	5a7d                	li	s4,-1
    80004904:	b7d5                	j	800048e8 <filewrite+0xfa>
    panic("filewrite");
    80004906:	00004517          	auipc	a0,0x4
    8000490a:	dd250513          	addi	a0,a0,-558 # 800086d8 <syscalls+0x278>
    8000490e:	ffffc097          	auipc	ra,0xffffc
    80004912:	c30080e7          	jalr	-976(ra) # 8000053e <panic>
    return -1;
    80004916:	5a7d                	li	s4,-1
    80004918:	bfc1                	j	800048e8 <filewrite+0xfa>
      return -1;
    8000491a:	5a7d                	li	s4,-1
    8000491c:	b7f1                	j	800048e8 <filewrite+0xfa>
    8000491e:	5a7d                	li	s4,-1
    80004920:	b7e1                	j	800048e8 <filewrite+0xfa>

0000000080004922 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004922:	7179                	addi	sp,sp,-48
    80004924:	f406                	sd	ra,40(sp)
    80004926:	f022                	sd	s0,32(sp)
    80004928:	ec26                	sd	s1,24(sp)
    8000492a:	e84a                	sd	s2,16(sp)
    8000492c:	e44e                	sd	s3,8(sp)
    8000492e:	e052                	sd	s4,0(sp)
    80004930:	1800                	addi	s0,sp,48
    80004932:	84aa                	mv	s1,a0
    80004934:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004936:	0005b023          	sd	zero,0(a1)
    8000493a:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    8000493e:	00000097          	auipc	ra,0x0
    80004942:	bf8080e7          	jalr	-1032(ra) # 80004536 <filealloc>
    80004946:	e088                	sd	a0,0(s1)
    80004948:	c551                	beqz	a0,800049d4 <pipealloc+0xb2>
    8000494a:	00000097          	auipc	ra,0x0
    8000494e:	bec080e7          	jalr	-1044(ra) # 80004536 <filealloc>
    80004952:	00aa3023          	sd	a0,0(s4)
    80004956:	c92d                	beqz	a0,800049c8 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004958:	ffffc097          	auipc	ra,0xffffc
    8000495c:	19c080e7          	jalr	412(ra) # 80000af4 <kalloc>
    80004960:	892a                	mv	s2,a0
    80004962:	c125                	beqz	a0,800049c2 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004964:	4985                	li	s3,1
    80004966:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    8000496a:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    8000496e:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004972:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004976:	00004597          	auipc	a1,0x4
    8000497a:	d7258593          	addi	a1,a1,-654 # 800086e8 <syscalls+0x288>
    8000497e:	ffffc097          	auipc	ra,0xffffc
    80004982:	1d6080e7          	jalr	470(ra) # 80000b54 <initlock>
  (*f0)->type = FD_PIPE;
    80004986:	609c                	ld	a5,0(s1)
    80004988:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    8000498c:	609c                	ld	a5,0(s1)
    8000498e:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004992:	609c                	ld	a5,0(s1)
    80004994:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004998:	609c                	ld	a5,0(s1)
    8000499a:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    8000499e:	000a3783          	ld	a5,0(s4)
    800049a2:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    800049a6:	000a3783          	ld	a5,0(s4)
    800049aa:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    800049ae:	000a3783          	ld	a5,0(s4)
    800049b2:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    800049b6:	000a3783          	ld	a5,0(s4)
    800049ba:	0127b823          	sd	s2,16(a5)
  return 0;
    800049be:	4501                	li	a0,0
    800049c0:	a025                	j	800049e8 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    800049c2:	6088                	ld	a0,0(s1)
    800049c4:	e501                	bnez	a0,800049cc <pipealloc+0xaa>
    800049c6:	a039                	j	800049d4 <pipealloc+0xb2>
    800049c8:	6088                	ld	a0,0(s1)
    800049ca:	c51d                	beqz	a0,800049f8 <pipealloc+0xd6>
    fileclose(*f0);
    800049cc:	00000097          	auipc	ra,0x0
    800049d0:	c26080e7          	jalr	-986(ra) # 800045f2 <fileclose>
  if(*f1)
    800049d4:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    800049d8:	557d                	li	a0,-1
  if(*f1)
    800049da:	c799                	beqz	a5,800049e8 <pipealloc+0xc6>
    fileclose(*f1);
    800049dc:	853e                	mv	a0,a5
    800049de:	00000097          	auipc	ra,0x0
    800049e2:	c14080e7          	jalr	-1004(ra) # 800045f2 <fileclose>
  return -1;
    800049e6:	557d                	li	a0,-1
}
    800049e8:	70a2                	ld	ra,40(sp)
    800049ea:	7402                	ld	s0,32(sp)
    800049ec:	64e2                	ld	s1,24(sp)
    800049ee:	6942                	ld	s2,16(sp)
    800049f0:	69a2                	ld	s3,8(sp)
    800049f2:	6a02                	ld	s4,0(sp)
    800049f4:	6145                	addi	sp,sp,48
    800049f6:	8082                	ret
  return -1;
    800049f8:	557d                	li	a0,-1
    800049fa:	b7fd                	j	800049e8 <pipealloc+0xc6>

00000000800049fc <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    800049fc:	1101                	addi	sp,sp,-32
    800049fe:	ec06                	sd	ra,24(sp)
    80004a00:	e822                	sd	s0,16(sp)
    80004a02:	e426                	sd	s1,8(sp)
    80004a04:	e04a                	sd	s2,0(sp)
    80004a06:	1000                	addi	s0,sp,32
    80004a08:	84aa                	mv	s1,a0
    80004a0a:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004a0c:	ffffc097          	auipc	ra,0xffffc
    80004a10:	1d8080e7          	jalr	472(ra) # 80000be4 <acquire>
  if(writable){
    80004a14:	02090d63          	beqz	s2,80004a4e <pipeclose+0x52>
    pi->writeopen = 0;
    80004a18:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004a1c:	21848513          	addi	a0,s1,536
    80004a20:	ffffe097          	auipc	ra,0xffffe
    80004a24:	8d0080e7          	jalr	-1840(ra) # 800022f0 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004a28:	2204b783          	ld	a5,544(s1)
    80004a2c:	eb95                	bnez	a5,80004a60 <pipeclose+0x64>
    release(&pi->lock);
    80004a2e:	8526                	mv	a0,s1
    80004a30:	ffffc097          	auipc	ra,0xffffc
    80004a34:	268080e7          	jalr	616(ra) # 80000c98 <release>
    kfree((char*)pi);
    80004a38:	8526                	mv	a0,s1
    80004a3a:	ffffc097          	auipc	ra,0xffffc
    80004a3e:	fbe080e7          	jalr	-66(ra) # 800009f8 <kfree>
  } else
    release(&pi->lock);
}
    80004a42:	60e2                	ld	ra,24(sp)
    80004a44:	6442                	ld	s0,16(sp)
    80004a46:	64a2                	ld	s1,8(sp)
    80004a48:	6902                	ld	s2,0(sp)
    80004a4a:	6105                	addi	sp,sp,32
    80004a4c:	8082                	ret
    pi->readopen = 0;
    80004a4e:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004a52:	21c48513          	addi	a0,s1,540
    80004a56:	ffffe097          	auipc	ra,0xffffe
    80004a5a:	89a080e7          	jalr	-1894(ra) # 800022f0 <wakeup>
    80004a5e:	b7e9                	j	80004a28 <pipeclose+0x2c>
    release(&pi->lock);
    80004a60:	8526                	mv	a0,s1
    80004a62:	ffffc097          	auipc	ra,0xffffc
    80004a66:	236080e7          	jalr	566(ra) # 80000c98 <release>
}
    80004a6a:	bfe1                	j	80004a42 <pipeclose+0x46>

0000000080004a6c <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004a6c:	7159                	addi	sp,sp,-112
    80004a6e:	f486                	sd	ra,104(sp)
    80004a70:	f0a2                	sd	s0,96(sp)
    80004a72:	eca6                	sd	s1,88(sp)
    80004a74:	e8ca                	sd	s2,80(sp)
    80004a76:	e4ce                	sd	s3,72(sp)
    80004a78:	e0d2                	sd	s4,64(sp)
    80004a7a:	fc56                	sd	s5,56(sp)
    80004a7c:	f85a                	sd	s6,48(sp)
    80004a7e:	f45e                	sd	s7,40(sp)
    80004a80:	f062                	sd	s8,32(sp)
    80004a82:	ec66                	sd	s9,24(sp)
    80004a84:	1880                	addi	s0,sp,112
    80004a86:	84aa                	mv	s1,a0
    80004a88:	8aae                	mv	s5,a1
    80004a8a:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004a8c:	ffffd097          	auipc	ra,0xffffd
    80004a90:	026080e7          	jalr	38(ra) # 80001ab2 <myproc>
    80004a94:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004a96:	8526                	mv	a0,s1
    80004a98:	ffffc097          	auipc	ra,0xffffc
    80004a9c:	14c080e7          	jalr	332(ra) # 80000be4 <acquire>
  while(i < n){
    80004aa0:	0d405163          	blez	s4,80004b62 <pipewrite+0xf6>
    80004aa4:	8ba6                	mv	s7,s1
  int i = 0;
    80004aa6:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004aa8:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004aaa:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004aae:	21c48c13          	addi	s8,s1,540
    80004ab2:	a08d                	j	80004b14 <pipewrite+0xa8>
      release(&pi->lock);
    80004ab4:	8526                	mv	a0,s1
    80004ab6:	ffffc097          	auipc	ra,0xffffc
    80004aba:	1e2080e7          	jalr	482(ra) # 80000c98 <release>
      return -1;
    80004abe:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004ac0:	854a                	mv	a0,s2
    80004ac2:	70a6                	ld	ra,104(sp)
    80004ac4:	7406                	ld	s0,96(sp)
    80004ac6:	64e6                	ld	s1,88(sp)
    80004ac8:	6946                	ld	s2,80(sp)
    80004aca:	69a6                	ld	s3,72(sp)
    80004acc:	6a06                	ld	s4,64(sp)
    80004ace:	7ae2                	ld	s5,56(sp)
    80004ad0:	7b42                	ld	s6,48(sp)
    80004ad2:	7ba2                	ld	s7,40(sp)
    80004ad4:	7c02                	ld	s8,32(sp)
    80004ad6:	6ce2                	ld	s9,24(sp)
    80004ad8:	6165                	addi	sp,sp,112
    80004ada:	8082                	ret
      wakeup(&pi->nread);
    80004adc:	8566                	mv	a0,s9
    80004ade:	ffffe097          	auipc	ra,0xffffe
    80004ae2:	812080e7          	jalr	-2030(ra) # 800022f0 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004ae6:	85de                	mv	a1,s7
    80004ae8:	8562                	mv	a0,s8
    80004aea:	ffffd097          	auipc	ra,0xffffd
    80004aee:	67a080e7          	jalr	1658(ra) # 80002164 <sleep>
    80004af2:	a839                	j	80004b10 <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004af4:	21c4a783          	lw	a5,540(s1)
    80004af8:	0017871b          	addiw	a4,a5,1
    80004afc:	20e4ae23          	sw	a4,540(s1)
    80004b00:	1ff7f793          	andi	a5,a5,511
    80004b04:	97a6                	add	a5,a5,s1
    80004b06:	f9f44703          	lbu	a4,-97(s0)
    80004b0a:	00e78c23          	sb	a4,24(a5)
      i++;
    80004b0e:	2905                	addiw	s2,s2,1
  while(i < n){
    80004b10:	03495d63          	bge	s2,s4,80004b4a <pipewrite+0xde>
    if(pi->readopen == 0 || pr->killed){
    80004b14:	2204a783          	lw	a5,544(s1)
    80004b18:	dfd1                	beqz	a5,80004ab4 <pipewrite+0x48>
    80004b1a:	0289a783          	lw	a5,40(s3)
    80004b1e:	fbd9                	bnez	a5,80004ab4 <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004b20:	2184a783          	lw	a5,536(s1)
    80004b24:	21c4a703          	lw	a4,540(s1)
    80004b28:	2007879b          	addiw	a5,a5,512
    80004b2c:	faf708e3          	beq	a4,a5,80004adc <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004b30:	4685                	li	a3,1
    80004b32:	01590633          	add	a2,s2,s5
    80004b36:	f9f40593          	addi	a1,s0,-97
    80004b3a:	0589b503          	ld	a0,88(s3)
    80004b3e:	ffffd097          	auipc	ra,0xffffd
    80004b42:	bc0080e7          	jalr	-1088(ra) # 800016fe <copyin>
    80004b46:	fb6517e3          	bne	a0,s6,80004af4 <pipewrite+0x88>
  wakeup(&pi->nread);
    80004b4a:	21848513          	addi	a0,s1,536
    80004b4e:	ffffd097          	auipc	ra,0xffffd
    80004b52:	7a2080e7          	jalr	1954(ra) # 800022f0 <wakeup>
  release(&pi->lock);
    80004b56:	8526                	mv	a0,s1
    80004b58:	ffffc097          	auipc	ra,0xffffc
    80004b5c:	140080e7          	jalr	320(ra) # 80000c98 <release>
  return i;
    80004b60:	b785                	j	80004ac0 <pipewrite+0x54>
  int i = 0;
    80004b62:	4901                	li	s2,0
    80004b64:	b7dd                	j	80004b4a <pipewrite+0xde>

0000000080004b66 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004b66:	715d                	addi	sp,sp,-80
    80004b68:	e486                	sd	ra,72(sp)
    80004b6a:	e0a2                	sd	s0,64(sp)
    80004b6c:	fc26                	sd	s1,56(sp)
    80004b6e:	f84a                	sd	s2,48(sp)
    80004b70:	f44e                	sd	s3,40(sp)
    80004b72:	f052                	sd	s4,32(sp)
    80004b74:	ec56                	sd	s5,24(sp)
    80004b76:	e85a                	sd	s6,16(sp)
    80004b78:	0880                	addi	s0,sp,80
    80004b7a:	84aa                	mv	s1,a0
    80004b7c:	892e                	mv	s2,a1
    80004b7e:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004b80:	ffffd097          	auipc	ra,0xffffd
    80004b84:	f32080e7          	jalr	-206(ra) # 80001ab2 <myproc>
    80004b88:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004b8a:	8b26                	mv	s6,s1
    80004b8c:	8526                	mv	a0,s1
    80004b8e:	ffffc097          	auipc	ra,0xffffc
    80004b92:	056080e7          	jalr	86(ra) # 80000be4 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004b96:	2184a703          	lw	a4,536(s1)
    80004b9a:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004b9e:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004ba2:	02f71463          	bne	a4,a5,80004bca <piperead+0x64>
    80004ba6:	2244a783          	lw	a5,548(s1)
    80004baa:	c385                	beqz	a5,80004bca <piperead+0x64>
    if(pr->killed){
    80004bac:	028a2783          	lw	a5,40(s4)
    80004bb0:	ebc1                	bnez	a5,80004c40 <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004bb2:	85da                	mv	a1,s6
    80004bb4:	854e                	mv	a0,s3
    80004bb6:	ffffd097          	auipc	ra,0xffffd
    80004bba:	5ae080e7          	jalr	1454(ra) # 80002164 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004bbe:	2184a703          	lw	a4,536(s1)
    80004bc2:	21c4a783          	lw	a5,540(s1)
    80004bc6:	fef700e3          	beq	a4,a5,80004ba6 <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004bca:	09505263          	blez	s5,80004c4e <piperead+0xe8>
    80004bce:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004bd0:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80004bd2:	2184a783          	lw	a5,536(s1)
    80004bd6:	21c4a703          	lw	a4,540(s1)
    80004bda:	02f70d63          	beq	a4,a5,80004c14 <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004bde:	0017871b          	addiw	a4,a5,1
    80004be2:	20e4ac23          	sw	a4,536(s1)
    80004be6:	1ff7f793          	andi	a5,a5,511
    80004bea:	97a6                	add	a5,a5,s1
    80004bec:	0187c783          	lbu	a5,24(a5)
    80004bf0:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004bf4:	4685                	li	a3,1
    80004bf6:	fbf40613          	addi	a2,s0,-65
    80004bfa:	85ca                	mv	a1,s2
    80004bfc:	058a3503          	ld	a0,88(s4)
    80004c00:	ffffd097          	auipc	ra,0xffffd
    80004c04:	a72080e7          	jalr	-1422(ra) # 80001672 <copyout>
    80004c08:	01650663          	beq	a0,s6,80004c14 <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004c0c:	2985                	addiw	s3,s3,1
    80004c0e:	0905                	addi	s2,s2,1
    80004c10:	fd3a91e3          	bne	s5,s3,80004bd2 <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004c14:	21c48513          	addi	a0,s1,540
    80004c18:	ffffd097          	auipc	ra,0xffffd
    80004c1c:	6d8080e7          	jalr	1752(ra) # 800022f0 <wakeup>
  release(&pi->lock);
    80004c20:	8526                	mv	a0,s1
    80004c22:	ffffc097          	auipc	ra,0xffffc
    80004c26:	076080e7          	jalr	118(ra) # 80000c98 <release>
  return i;
}
    80004c2a:	854e                	mv	a0,s3
    80004c2c:	60a6                	ld	ra,72(sp)
    80004c2e:	6406                	ld	s0,64(sp)
    80004c30:	74e2                	ld	s1,56(sp)
    80004c32:	7942                	ld	s2,48(sp)
    80004c34:	79a2                	ld	s3,40(sp)
    80004c36:	7a02                	ld	s4,32(sp)
    80004c38:	6ae2                	ld	s5,24(sp)
    80004c3a:	6b42                	ld	s6,16(sp)
    80004c3c:	6161                	addi	sp,sp,80
    80004c3e:	8082                	ret
      release(&pi->lock);
    80004c40:	8526                	mv	a0,s1
    80004c42:	ffffc097          	auipc	ra,0xffffc
    80004c46:	056080e7          	jalr	86(ra) # 80000c98 <release>
      return -1;
    80004c4a:	59fd                	li	s3,-1
    80004c4c:	bff9                	j	80004c2a <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004c4e:	4981                	li	s3,0
    80004c50:	b7d1                	j	80004c14 <piperead+0xae>

0000000080004c52 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004c52:	df010113          	addi	sp,sp,-528
    80004c56:	20113423          	sd	ra,520(sp)
    80004c5a:	20813023          	sd	s0,512(sp)
    80004c5e:	ffa6                	sd	s1,504(sp)
    80004c60:	fbca                	sd	s2,496(sp)
    80004c62:	f7ce                	sd	s3,488(sp)
    80004c64:	f3d2                	sd	s4,480(sp)
    80004c66:	efd6                	sd	s5,472(sp)
    80004c68:	ebda                	sd	s6,464(sp)
    80004c6a:	e7de                	sd	s7,456(sp)
    80004c6c:	e3e2                	sd	s8,448(sp)
    80004c6e:	ff66                	sd	s9,440(sp)
    80004c70:	fb6a                	sd	s10,432(sp)
    80004c72:	f76e                	sd	s11,424(sp)
    80004c74:	0c00                	addi	s0,sp,528
    80004c76:	84aa                	mv	s1,a0
    80004c78:	dea43c23          	sd	a0,-520(s0)
    80004c7c:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004c80:	ffffd097          	auipc	ra,0xffffd
    80004c84:	e32080e7          	jalr	-462(ra) # 80001ab2 <myproc>
    80004c88:	892a                	mv	s2,a0

  begin_op();
    80004c8a:	fffff097          	auipc	ra,0xfffff
    80004c8e:	49c080e7          	jalr	1180(ra) # 80004126 <begin_op>

  if((ip = namei(path)) == 0){
    80004c92:	8526                	mv	a0,s1
    80004c94:	fffff097          	auipc	ra,0xfffff
    80004c98:	276080e7          	jalr	630(ra) # 80003f0a <namei>
    80004c9c:	c92d                	beqz	a0,80004d0e <exec+0xbc>
    80004c9e:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004ca0:	fffff097          	auipc	ra,0xfffff
    80004ca4:	ab4080e7          	jalr	-1356(ra) # 80003754 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004ca8:	04000713          	li	a4,64
    80004cac:	4681                	li	a3,0
    80004cae:	e5040613          	addi	a2,s0,-432
    80004cb2:	4581                	li	a1,0
    80004cb4:	8526                	mv	a0,s1
    80004cb6:	fffff097          	auipc	ra,0xfffff
    80004cba:	d52080e7          	jalr	-686(ra) # 80003a08 <readi>
    80004cbe:	04000793          	li	a5,64
    80004cc2:	00f51a63          	bne	a0,a5,80004cd6 <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80004cc6:	e5042703          	lw	a4,-432(s0)
    80004cca:	464c47b7          	lui	a5,0x464c4
    80004cce:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004cd2:	04f70463          	beq	a4,a5,80004d1a <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004cd6:	8526                	mv	a0,s1
    80004cd8:	fffff097          	auipc	ra,0xfffff
    80004cdc:	cde080e7          	jalr	-802(ra) # 800039b6 <iunlockput>
    end_op();
    80004ce0:	fffff097          	auipc	ra,0xfffff
    80004ce4:	4c6080e7          	jalr	1222(ra) # 800041a6 <end_op>
  }
  return -1;
    80004ce8:	557d                	li	a0,-1
}
    80004cea:	20813083          	ld	ra,520(sp)
    80004cee:	20013403          	ld	s0,512(sp)
    80004cf2:	74fe                	ld	s1,504(sp)
    80004cf4:	795e                	ld	s2,496(sp)
    80004cf6:	79be                	ld	s3,488(sp)
    80004cf8:	7a1e                	ld	s4,480(sp)
    80004cfa:	6afe                	ld	s5,472(sp)
    80004cfc:	6b5e                	ld	s6,464(sp)
    80004cfe:	6bbe                	ld	s7,456(sp)
    80004d00:	6c1e                	ld	s8,448(sp)
    80004d02:	7cfa                	ld	s9,440(sp)
    80004d04:	7d5a                	ld	s10,432(sp)
    80004d06:	7dba                	ld	s11,424(sp)
    80004d08:	21010113          	addi	sp,sp,528
    80004d0c:	8082                	ret
    end_op();
    80004d0e:	fffff097          	auipc	ra,0xfffff
    80004d12:	498080e7          	jalr	1176(ra) # 800041a6 <end_op>
    return -1;
    80004d16:	557d                	li	a0,-1
    80004d18:	bfc9                	j	80004cea <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80004d1a:	854a                	mv	a0,s2
    80004d1c:	ffffd097          	auipc	ra,0xffffd
    80004d20:	e4c080e7          	jalr	-436(ra) # 80001b68 <proc_pagetable>
    80004d24:	8baa                	mv	s7,a0
    80004d26:	d945                	beqz	a0,80004cd6 <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004d28:	e7042983          	lw	s3,-400(s0)
    80004d2c:	e8845783          	lhu	a5,-376(s0)
    80004d30:	c7ad                	beqz	a5,80004d9a <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004d32:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004d34:	4b01                	li	s6,0
    if((ph.vaddr % PGSIZE) != 0)
    80004d36:	6c85                	lui	s9,0x1
    80004d38:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80004d3c:	def43823          	sd	a5,-528(s0)
    80004d40:	a42d                	j	80004f6a <exec+0x318>
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004d42:	00004517          	auipc	a0,0x4
    80004d46:	9ae50513          	addi	a0,a0,-1618 # 800086f0 <syscalls+0x290>
    80004d4a:	ffffb097          	auipc	ra,0xffffb
    80004d4e:	7f4080e7          	jalr	2036(ra) # 8000053e <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004d52:	8756                	mv	a4,s5
    80004d54:	012d86bb          	addw	a3,s11,s2
    80004d58:	4581                	li	a1,0
    80004d5a:	8526                	mv	a0,s1
    80004d5c:	fffff097          	auipc	ra,0xfffff
    80004d60:	cac080e7          	jalr	-852(ra) # 80003a08 <readi>
    80004d64:	2501                	sext.w	a0,a0
    80004d66:	1aaa9963          	bne	s5,a0,80004f18 <exec+0x2c6>
  for(i = 0; i < sz; i += PGSIZE){
    80004d6a:	6785                	lui	a5,0x1
    80004d6c:	0127893b          	addw	s2,a5,s2
    80004d70:	77fd                	lui	a5,0xfffff
    80004d72:	01478a3b          	addw	s4,a5,s4
    80004d76:	1f897163          	bgeu	s2,s8,80004f58 <exec+0x306>
    pa = walkaddr(pagetable, va + i);
    80004d7a:	02091593          	slli	a1,s2,0x20
    80004d7e:	9181                	srli	a1,a1,0x20
    80004d80:	95ea                	add	a1,a1,s10
    80004d82:	855e                	mv	a0,s7
    80004d84:	ffffc097          	auipc	ra,0xffffc
    80004d88:	2ea080e7          	jalr	746(ra) # 8000106e <walkaddr>
    80004d8c:	862a                	mv	a2,a0
    if(pa == 0)
    80004d8e:	d955                	beqz	a0,80004d42 <exec+0xf0>
      n = PGSIZE;
    80004d90:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    80004d92:	fd9a70e3          	bgeu	s4,s9,80004d52 <exec+0x100>
      n = sz - i;
    80004d96:	8ad2                	mv	s5,s4
    80004d98:	bf6d                	j	80004d52 <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004d9a:	4901                	li	s2,0
  iunlockput(ip);
    80004d9c:	8526                	mv	a0,s1
    80004d9e:	fffff097          	auipc	ra,0xfffff
    80004da2:	c18080e7          	jalr	-1000(ra) # 800039b6 <iunlockput>
  end_op();
    80004da6:	fffff097          	auipc	ra,0xfffff
    80004daa:	400080e7          	jalr	1024(ra) # 800041a6 <end_op>
  p = myproc();
    80004dae:	ffffd097          	auipc	ra,0xffffd
    80004db2:	d04080e7          	jalr	-764(ra) # 80001ab2 <myproc>
    80004db6:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80004db8:	05053d03          	ld	s10,80(a0)
  sz = PGROUNDUP(sz);
    80004dbc:	6785                	lui	a5,0x1
    80004dbe:	17fd                	addi	a5,a5,-1
    80004dc0:	993e                	add	s2,s2,a5
    80004dc2:	757d                	lui	a0,0xfffff
    80004dc4:	00a977b3          	and	a5,s2,a0
    80004dc8:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004dcc:	6609                	lui	a2,0x2
    80004dce:	963e                	add	a2,a2,a5
    80004dd0:	85be                	mv	a1,a5
    80004dd2:	855e                	mv	a0,s7
    80004dd4:	ffffc097          	auipc	ra,0xffffc
    80004dd8:	64e080e7          	jalr	1614(ra) # 80001422 <uvmalloc>
    80004ddc:	8b2a                	mv	s6,a0
  ip = 0;
    80004dde:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004de0:	12050c63          	beqz	a0,80004f18 <exec+0x2c6>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004de4:	75f9                	lui	a1,0xffffe
    80004de6:	95aa                	add	a1,a1,a0
    80004de8:	855e                	mv	a0,s7
    80004dea:	ffffd097          	auipc	ra,0xffffd
    80004dee:	856080e7          	jalr	-1962(ra) # 80001640 <uvmclear>
  stackbase = sp - PGSIZE;
    80004df2:	7c7d                	lui	s8,0xfffff
    80004df4:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    80004df6:	e0043783          	ld	a5,-512(s0)
    80004dfa:	6388                	ld	a0,0(a5)
    80004dfc:	c535                	beqz	a0,80004e68 <exec+0x216>
    80004dfe:	e9040993          	addi	s3,s0,-368
    80004e02:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80004e06:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    80004e08:	ffffc097          	auipc	ra,0xffffc
    80004e0c:	05c080e7          	jalr	92(ra) # 80000e64 <strlen>
    80004e10:	2505                	addiw	a0,a0,1
    80004e12:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004e16:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80004e1a:	13896363          	bltu	s2,s8,80004f40 <exec+0x2ee>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004e1e:	e0043d83          	ld	s11,-512(s0)
    80004e22:	000dba03          	ld	s4,0(s11)
    80004e26:	8552                	mv	a0,s4
    80004e28:	ffffc097          	auipc	ra,0xffffc
    80004e2c:	03c080e7          	jalr	60(ra) # 80000e64 <strlen>
    80004e30:	0015069b          	addiw	a3,a0,1
    80004e34:	8652                	mv	a2,s4
    80004e36:	85ca                	mv	a1,s2
    80004e38:	855e                	mv	a0,s7
    80004e3a:	ffffd097          	auipc	ra,0xffffd
    80004e3e:	838080e7          	jalr	-1992(ra) # 80001672 <copyout>
    80004e42:	10054363          	bltz	a0,80004f48 <exec+0x2f6>
    ustack[argc] = sp;
    80004e46:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004e4a:	0485                	addi	s1,s1,1
    80004e4c:	008d8793          	addi	a5,s11,8
    80004e50:	e0f43023          	sd	a5,-512(s0)
    80004e54:	008db503          	ld	a0,8(s11)
    80004e58:	c911                	beqz	a0,80004e6c <exec+0x21a>
    if(argc >= MAXARG)
    80004e5a:	09a1                	addi	s3,s3,8
    80004e5c:	fb3c96e3          	bne	s9,s3,80004e08 <exec+0x1b6>
  sz = sz1;
    80004e60:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004e64:	4481                	li	s1,0
    80004e66:	a84d                	j	80004f18 <exec+0x2c6>
  sp = sz;
    80004e68:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    80004e6a:	4481                	li	s1,0
  ustack[argc] = 0;
    80004e6c:	00349793          	slli	a5,s1,0x3
    80004e70:	f9040713          	addi	a4,s0,-112
    80004e74:	97ba                	add	a5,a5,a4
    80004e76:	f007b023          	sd	zero,-256(a5) # f00 <_entry-0x7ffff100>
  sp -= (argc+1) * sizeof(uint64);
    80004e7a:	00148693          	addi	a3,s1,1
    80004e7e:	068e                	slli	a3,a3,0x3
    80004e80:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004e84:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80004e88:	01897663          	bgeu	s2,s8,80004e94 <exec+0x242>
  sz = sz1;
    80004e8c:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004e90:	4481                	li	s1,0
    80004e92:	a059                	j	80004f18 <exec+0x2c6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80004e94:	e9040613          	addi	a2,s0,-368
    80004e98:	85ca                	mv	a1,s2
    80004e9a:	855e                	mv	a0,s7
    80004e9c:	ffffc097          	auipc	ra,0xffffc
    80004ea0:	7d6080e7          	jalr	2006(ra) # 80001672 <copyout>
    80004ea4:	0a054663          	bltz	a0,80004f50 <exec+0x2fe>
  p->trapframe->a1 = sp;
    80004ea8:	060ab783          	ld	a5,96(s5)
    80004eac:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80004eb0:	df843783          	ld	a5,-520(s0)
    80004eb4:	0007c703          	lbu	a4,0(a5)
    80004eb8:	cf11                	beqz	a4,80004ed4 <exec+0x282>
    80004eba:	0785                	addi	a5,a5,1
    if(*s == '/')
    80004ebc:	02f00693          	li	a3,47
    80004ec0:	a039                	j	80004ece <exec+0x27c>
      last = s+1;
    80004ec2:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    80004ec6:	0785                	addi	a5,a5,1
    80004ec8:	fff7c703          	lbu	a4,-1(a5)
    80004ecc:	c701                	beqz	a4,80004ed4 <exec+0x282>
    if(*s == '/')
    80004ece:	fed71ce3          	bne	a4,a3,80004ec6 <exec+0x274>
    80004ed2:	bfc5                	j	80004ec2 <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    80004ed4:	4641                	li	a2,16
    80004ed6:	df843583          	ld	a1,-520(s0)
    80004eda:	160a8513          	addi	a0,s5,352
    80004ede:	ffffc097          	auipc	ra,0xffffc
    80004ee2:	f54080e7          	jalr	-172(ra) # 80000e32 <safestrcpy>
  oldpagetable = p->pagetable;
    80004ee6:	058ab503          	ld	a0,88(s5)
  p->pagetable = pagetable;
    80004eea:	057abc23          	sd	s7,88(s5)
  p->sz = sz;
    80004eee:	056ab823          	sd	s6,80(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80004ef2:	060ab783          	ld	a5,96(s5)
    80004ef6:	e6843703          	ld	a4,-408(s0)
    80004efa:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80004efc:	060ab783          	ld	a5,96(s5)
    80004f00:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80004f04:	85ea                	mv	a1,s10
    80004f06:	ffffd097          	auipc	ra,0xffffd
    80004f0a:	cfe080e7          	jalr	-770(ra) # 80001c04 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80004f0e:	0004851b          	sext.w	a0,s1
    80004f12:	bbe1                	j	80004cea <exec+0x98>
    80004f14:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    80004f18:	e0843583          	ld	a1,-504(s0)
    80004f1c:	855e                	mv	a0,s7
    80004f1e:	ffffd097          	auipc	ra,0xffffd
    80004f22:	ce6080e7          	jalr	-794(ra) # 80001c04 <proc_freepagetable>
  if(ip){
    80004f26:	da0498e3          	bnez	s1,80004cd6 <exec+0x84>
  return -1;
    80004f2a:	557d                	li	a0,-1
    80004f2c:	bb7d                	j	80004cea <exec+0x98>
    80004f2e:	e1243423          	sd	s2,-504(s0)
    80004f32:	b7dd                	j	80004f18 <exec+0x2c6>
    80004f34:	e1243423          	sd	s2,-504(s0)
    80004f38:	b7c5                	j	80004f18 <exec+0x2c6>
    80004f3a:	e1243423          	sd	s2,-504(s0)
    80004f3e:	bfe9                	j	80004f18 <exec+0x2c6>
  sz = sz1;
    80004f40:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004f44:	4481                	li	s1,0
    80004f46:	bfc9                	j	80004f18 <exec+0x2c6>
  sz = sz1;
    80004f48:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004f4c:	4481                	li	s1,0
    80004f4e:	b7e9                	j	80004f18 <exec+0x2c6>
  sz = sz1;
    80004f50:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004f54:	4481                	li	s1,0
    80004f56:	b7c9                	j	80004f18 <exec+0x2c6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80004f58:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004f5c:	2b05                	addiw	s6,s6,1
    80004f5e:	0389899b          	addiw	s3,s3,56
    80004f62:	e8845783          	lhu	a5,-376(s0)
    80004f66:	e2fb5be3          	bge	s6,a5,80004d9c <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80004f6a:	2981                	sext.w	s3,s3
    80004f6c:	03800713          	li	a4,56
    80004f70:	86ce                	mv	a3,s3
    80004f72:	e1840613          	addi	a2,s0,-488
    80004f76:	4581                	li	a1,0
    80004f78:	8526                	mv	a0,s1
    80004f7a:	fffff097          	auipc	ra,0xfffff
    80004f7e:	a8e080e7          	jalr	-1394(ra) # 80003a08 <readi>
    80004f82:	03800793          	li	a5,56
    80004f86:	f8f517e3          	bne	a0,a5,80004f14 <exec+0x2c2>
    if(ph.type != ELF_PROG_LOAD)
    80004f8a:	e1842783          	lw	a5,-488(s0)
    80004f8e:	4705                	li	a4,1
    80004f90:	fce796e3          	bne	a5,a4,80004f5c <exec+0x30a>
    if(ph.memsz < ph.filesz)
    80004f94:	e4043603          	ld	a2,-448(s0)
    80004f98:	e3843783          	ld	a5,-456(s0)
    80004f9c:	f8f669e3          	bltu	a2,a5,80004f2e <exec+0x2dc>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80004fa0:	e2843783          	ld	a5,-472(s0)
    80004fa4:	963e                	add	a2,a2,a5
    80004fa6:	f8f667e3          	bltu	a2,a5,80004f34 <exec+0x2e2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80004faa:	85ca                	mv	a1,s2
    80004fac:	855e                	mv	a0,s7
    80004fae:	ffffc097          	auipc	ra,0xffffc
    80004fb2:	474080e7          	jalr	1140(ra) # 80001422 <uvmalloc>
    80004fb6:	e0a43423          	sd	a0,-504(s0)
    80004fba:	d141                	beqz	a0,80004f3a <exec+0x2e8>
    if((ph.vaddr % PGSIZE) != 0)
    80004fbc:	e2843d03          	ld	s10,-472(s0)
    80004fc0:	df043783          	ld	a5,-528(s0)
    80004fc4:	00fd77b3          	and	a5,s10,a5
    80004fc8:	fba1                	bnez	a5,80004f18 <exec+0x2c6>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80004fca:	e2042d83          	lw	s11,-480(s0)
    80004fce:	e3842c03          	lw	s8,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80004fd2:	f80c03e3          	beqz	s8,80004f58 <exec+0x306>
    80004fd6:	8a62                	mv	s4,s8
    80004fd8:	4901                	li	s2,0
    80004fda:	b345                	j	80004d7a <exec+0x128>

0000000080004fdc <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80004fdc:	7179                	addi	sp,sp,-48
    80004fde:	f406                	sd	ra,40(sp)
    80004fe0:	f022                	sd	s0,32(sp)
    80004fe2:	ec26                	sd	s1,24(sp)
    80004fe4:	e84a                	sd	s2,16(sp)
    80004fe6:	1800                	addi	s0,sp,48
    80004fe8:	892e                	mv	s2,a1
    80004fea:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    80004fec:	fdc40593          	addi	a1,s0,-36
    80004ff0:	ffffe097          	auipc	ra,0xffffe
    80004ff4:	ba8080e7          	jalr	-1112(ra) # 80002b98 <argint>
    80004ff8:	04054063          	bltz	a0,80005038 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80004ffc:	fdc42703          	lw	a4,-36(s0)
    80005000:	47bd                	li	a5,15
    80005002:	02e7ed63          	bltu	a5,a4,8000503c <argfd+0x60>
    80005006:	ffffd097          	auipc	ra,0xffffd
    8000500a:	aac080e7          	jalr	-1364(ra) # 80001ab2 <myproc>
    8000500e:	fdc42703          	lw	a4,-36(s0)
    80005012:	01a70793          	addi	a5,a4,26
    80005016:	078e                	slli	a5,a5,0x3
    80005018:	953e                	add	a0,a0,a5
    8000501a:	651c                	ld	a5,8(a0)
    8000501c:	c395                	beqz	a5,80005040 <argfd+0x64>
    return -1;
  if(pfd)
    8000501e:	00090463          	beqz	s2,80005026 <argfd+0x4a>
    *pfd = fd;
    80005022:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005026:	4501                	li	a0,0
  if(pf)
    80005028:	c091                	beqz	s1,8000502c <argfd+0x50>
    *pf = f;
    8000502a:	e09c                	sd	a5,0(s1)
}
    8000502c:	70a2                	ld	ra,40(sp)
    8000502e:	7402                	ld	s0,32(sp)
    80005030:	64e2                	ld	s1,24(sp)
    80005032:	6942                	ld	s2,16(sp)
    80005034:	6145                	addi	sp,sp,48
    80005036:	8082                	ret
    return -1;
    80005038:	557d                	li	a0,-1
    8000503a:	bfcd                	j	8000502c <argfd+0x50>
    return -1;
    8000503c:	557d                	li	a0,-1
    8000503e:	b7fd                	j	8000502c <argfd+0x50>
    80005040:	557d                	li	a0,-1
    80005042:	b7ed                	j	8000502c <argfd+0x50>

0000000080005044 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005044:	1101                	addi	sp,sp,-32
    80005046:	ec06                	sd	ra,24(sp)
    80005048:	e822                	sd	s0,16(sp)
    8000504a:	e426                	sd	s1,8(sp)
    8000504c:	1000                	addi	s0,sp,32
    8000504e:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005050:	ffffd097          	auipc	ra,0xffffd
    80005054:	a62080e7          	jalr	-1438(ra) # 80001ab2 <myproc>
    80005058:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    8000505a:	0d850793          	addi	a5,a0,216 # fffffffffffff0d8 <end+0xffffffff7ffd90d8>
    8000505e:	4501                	li	a0,0
    80005060:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005062:	6398                	ld	a4,0(a5)
    80005064:	cb19                	beqz	a4,8000507a <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005066:	2505                	addiw	a0,a0,1
    80005068:	07a1                	addi	a5,a5,8
    8000506a:	fed51ce3          	bne	a0,a3,80005062 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    8000506e:	557d                	li	a0,-1
}
    80005070:	60e2                	ld	ra,24(sp)
    80005072:	6442                	ld	s0,16(sp)
    80005074:	64a2                	ld	s1,8(sp)
    80005076:	6105                	addi	sp,sp,32
    80005078:	8082                	ret
      p->ofile[fd] = f;
    8000507a:	01a50793          	addi	a5,a0,26
    8000507e:	078e                	slli	a5,a5,0x3
    80005080:	963e                	add	a2,a2,a5
    80005082:	e604                	sd	s1,8(a2)
      return fd;
    80005084:	b7f5                	j	80005070 <fdalloc+0x2c>

0000000080005086 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005086:	715d                	addi	sp,sp,-80
    80005088:	e486                	sd	ra,72(sp)
    8000508a:	e0a2                	sd	s0,64(sp)
    8000508c:	fc26                	sd	s1,56(sp)
    8000508e:	f84a                	sd	s2,48(sp)
    80005090:	f44e                	sd	s3,40(sp)
    80005092:	f052                	sd	s4,32(sp)
    80005094:	ec56                	sd	s5,24(sp)
    80005096:	0880                	addi	s0,sp,80
    80005098:	89ae                	mv	s3,a1
    8000509a:	8ab2                	mv	s5,a2
    8000509c:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    8000509e:	fb040593          	addi	a1,s0,-80
    800050a2:	fffff097          	auipc	ra,0xfffff
    800050a6:	e86080e7          	jalr	-378(ra) # 80003f28 <nameiparent>
    800050aa:	892a                	mv	s2,a0
    800050ac:	12050f63          	beqz	a0,800051ea <create+0x164>
    return 0;

  ilock(dp);
    800050b0:	ffffe097          	auipc	ra,0xffffe
    800050b4:	6a4080e7          	jalr	1700(ra) # 80003754 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    800050b8:	4601                	li	a2,0
    800050ba:	fb040593          	addi	a1,s0,-80
    800050be:	854a                	mv	a0,s2
    800050c0:	fffff097          	auipc	ra,0xfffff
    800050c4:	b78080e7          	jalr	-1160(ra) # 80003c38 <dirlookup>
    800050c8:	84aa                	mv	s1,a0
    800050ca:	c921                	beqz	a0,8000511a <create+0x94>
    iunlockput(dp);
    800050cc:	854a                	mv	a0,s2
    800050ce:	fffff097          	auipc	ra,0xfffff
    800050d2:	8e8080e7          	jalr	-1816(ra) # 800039b6 <iunlockput>
    ilock(ip);
    800050d6:	8526                	mv	a0,s1
    800050d8:	ffffe097          	auipc	ra,0xffffe
    800050dc:	67c080e7          	jalr	1660(ra) # 80003754 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    800050e0:	2981                	sext.w	s3,s3
    800050e2:	4789                	li	a5,2
    800050e4:	02f99463          	bne	s3,a5,8000510c <create+0x86>
    800050e8:	0444d783          	lhu	a5,68(s1)
    800050ec:	37f9                	addiw	a5,a5,-2
    800050ee:	17c2                	slli	a5,a5,0x30
    800050f0:	93c1                	srli	a5,a5,0x30
    800050f2:	4705                	li	a4,1
    800050f4:	00f76c63          	bltu	a4,a5,8000510c <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    800050f8:	8526                	mv	a0,s1
    800050fa:	60a6                	ld	ra,72(sp)
    800050fc:	6406                	ld	s0,64(sp)
    800050fe:	74e2                	ld	s1,56(sp)
    80005100:	7942                	ld	s2,48(sp)
    80005102:	79a2                	ld	s3,40(sp)
    80005104:	7a02                	ld	s4,32(sp)
    80005106:	6ae2                	ld	s5,24(sp)
    80005108:	6161                	addi	sp,sp,80
    8000510a:	8082                	ret
    iunlockput(ip);
    8000510c:	8526                	mv	a0,s1
    8000510e:	fffff097          	auipc	ra,0xfffff
    80005112:	8a8080e7          	jalr	-1880(ra) # 800039b6 <iunlockput>
    return 0;
    80005116:	4481                	li	s1,0
    80005118:	b7c5                	j	800050f8 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    8000511a:	85ce                	mv	a1,s3
    8000511c:	00092503          	lw	a0,0(s2)
    80005120:	ffffe097          	auipc	ra,0xffffe
    80005124:	49c080e7          	jalr	1180(ra) # 800035bc <ialloc>
    80005128:	84aa                	mv	s1,a0
    8000512a:	c529                	beqz	a0,80005174 <create+0xee>
  ilock(ip);
    8000512c:	ffffe097          	auipc	ra,0xffffe
    80005130:	628080e7          	jalr	1576(ra) # 80003754 <ilock>
  ip->major = major;
    80005134:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    80005138:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    8000513c:	4785                	li	a5,1
    8000513e:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005142:	8526                	mv	a0,s1
    80005144:	ffffe097          	auipc	ra,0xffffe
    80005148:	546080e7          	jalr	1350(ra) # 8000368a <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    8000514c:	2981                	sext.w	s3,s3
    8000514e:	4785                	li	a5,1
    80005150:	02f98a63          	beq	s3,a5,80005184 <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    80005154:	40d0                	lw	a2,4(s1)
    80005156:	fb040593          	addi	a1,s0,-80
    8000515a:	854a                	mv	a0,s2
    8000515c:	fffff097          	auipc	ra,0xfffff
    80005160:	cec080e7          	jalr	-788(ra) # 80003e48 <dirlink>
    80005164:	06054b63          	bltz	a0,800051da <create+0x154>
  iunlockput(dp);
    80005168:	854a                	mv	a0,s2
    8000516a:	fffff097          	auipc	ra,0xfffff
    8000516e:	84c080e7          	jalr	-1972(ra) # 800039b6 <iunlockput>
  return ip;
    80005172:	b759                	j	800050f8 <create+0x72>
    panic("create: ialloc");
    80005174:	00003517          	auipc	a0,0x3
    80005178:	59c50513          	addi	a0,a0,1436 # 80008710 <syscalls+0x2b0>
    8000517c:	ffffb097          	auipc	ra,0xffffb
    80005180:	3c2080e7          	jalr	962(ra) # 8000053e <panic>
    dp->nlink++;  // for ".."
    80005184:	04a95783          	lhu	a5,74(s2)
    80005188:	2785                	addiw	a5,a5,1
    8000518a:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    8000518e:	854a                	mv	a0,s2
    80005190:	ffffe097          	auipc	ra,0xffffe
    80005194:	4fa080e7          	jalr	1274(ra) # 8000368a <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005198:	40d0                	lw	a2,4(s1)
    8000519a:	00003597          	auipc	a1,0x3
    8000519e:	58658593          	addi	a1,a1,1414 # 80008720 <syscalls+0x2c0>
    800051a2:	8526                	mv	a0,s1
    800051a4:	fffff097          	auipc	ra,0xfffff
    800051a8:	ca4080e7          	jalr	-860(ra) # 80003e48 <dirlink>
    800051ac:	00054f63          	bltz	a0,800051ca <create+0x144>
    800051b0:	00492603          	lw	a2,4(s2)
    800051b4:	00003597          	auipc	a1,0x3
    800051b8:	57458593          	addi	a1,a1,1396 # 80008728 <syscalls+0x2c8>
    800051bc:	8526                	mv	a0,s1
    800051be:	fffff097          	auipc	ra,0xfffff
    800051c2:	c8a080e7          	jalr	-886(ra) # 80003e48 <dirlink>
    800051c6:	f80557e3          	bgez	a0,80005154 <create+0xce>
      panic("create dots");
    800051ca:	00003517          	auipc	a0,0x3
    800051ce:	56650513          	addi	a0,a0,1382 # 80008730 <syscalls+0x2d0>
    800051d2:	ffffb097          	auipc	ra,0xffffb
    800051d6:	36c080e7          	jalr	876(ra) # 8000053e <panic>
    panic("create: dirlink");
    800051da:	00003517          	auipc	a0,0x3
    800051de:	56650513          	addi	a0,a0,1382 # 80008740 <syscalls+0x2e0>
    800051e2:	ffffb097          	auipc	ra,0xffffb
    800051e6:	35c080e7          	jalr	860(ra) # 8000053e <panic>
    return 0;
    800051ea:	84aa                	mv	s1,a0
    800051ec:	b731                	j	800050f8 <create+0x72>

00000000800051ee <sys_dup>:
{
    800051ee:	7179                	addi	sp,sp,-48
    800051f0:	f406                	sd	ra,40(sp)
    800051f2:	f022                	sd	s0,32(sp)
    800051f4:	ec26                	sd	s1,24(sp)
    800051f6:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    800051f8:	fd840613          	addi	a2,s0,-40
    800051fc:	4581                	li	a1,0
    800051fe:	4501                	li	a0,0
    80005200:	00000097          	auipc	ra,0x0
    80005204:	ddc080e7          	jalr	-548(ra) # 80004fdc <argfd>
    return -1;
    80005208:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    8000520a:	02054363          	bltz	a0,80005230 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    8000520e:	fd843503          	ld	a0,-40(s0)
    80005212:	00000097          	auipc	ra,0x0
    80005216:	e32080e7          	jalr	-462(ra) # 80005044 <fdalloc>
    8000521a:	84aa                	mv	s1,a0
    return -1;
    8000521c:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    8000521e:	00054963          	bltz	a0,80005230 <sys_dup+0x42>
  filedup(f);
    80005222:	fd843503          	ld	a0,-40(s0)
    80005226:	fffff097          	auipc	ra,0xfffff
    8000522a:	37a080e7          	jalr	890(ra) # 800045a0 <filedup>
  return fd;
    8000522e:	87a6                	mv	a5,s1
}
    80005230:	853e                	mv	a0,a5
    80005232:	70a2                	ld	ra,40(sp)
    80005234:	7402                	ld	s0,32(sp)
    80005236:	64e2                	ld	s1,24(sp)
    80005238:	6145                	addi	sp,sp,48
    8000523a:	8082                	ret

000000008000523c <sys_read>:
{
    8000523c:	7179                	addi	sp,sp,-48
    8000523e:	f406                	sd	ra,40(sp)
    80005240:	f022                	sd	s0,32(sp)
    80005242:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005244:	fe840613          	addi	a2,s0,-24
    80005248:	4581                	li	a1,0
    8000524a:	4501                	li	a0,0
    8000524c:	00000097          	auipc	ra,0x0
    80005250:	d90080e7          	jalr	-624(ra) # 80004fdc <argfd>
    return -1;
    80005254:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005256:	04054163          	bltz	a0,80005298 <sys_read+0x5c>
    8000525a:	fe440593          	addi	a1,s0,-28
    8000525e:	4509                	li	a0,2
    80005260:	ffffe097          	auipc	ra,0xffffe
    80005264:	938080e7          	jalr	-1736(ra) # 80002b98 <argint>
    return -1;
    80005268:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000526a:	02054763          	bltz	a0,80005298 <sys_read+0x5c>
    8000526e:	fd840593          	addi	a1,s0,-40
    80005272:	4505                	li	a0,1
    80005274:	ffffe097          	auipc	ra,0xffffe
    80005278:	946080e7          	jalr	-1722(ra) # 80002bba <argaddr>
    return -1;
    8000527c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000527e:	00054d63          	bltz	a0,80005298 <sys_read+0x5c>
  return fileread(f, p, n);
    80005282:	fe442603          	lw	a2,-28(s0)
    80005286:	fd843583          	ld	a1,-40(s0)
    8000528a:	fe843503          	ld	a0,-24(s0)
    8000528e:	fffff097          	auipc	ra,0xfffff
    80005292:	49e080e7          	jalr	1182(ra) # 8000472c <fileread>
    80005296:	87aa                	mv	a5,a0
}
    80005298:	853e                	mv	a0,a5
    8000529a:	70a2                	ld	ra,40(sp)
    8000529c:	7402                	ld	s0,32(sp)
    8000529e:	6145                	addi	sp,sp,48
    800052a0:	8082                	ret

00000000800052a2 <sys_write>:
{
    800052a2:	7179                	addi	sp,sp,-48
    800052a4:	f406                	sd	ra,40(sp)
    800052a6:	f022                	sd	s0,32(sp)
    800052a8:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800052aa:	fe840613          	addi	a2,s0,-24
    800052ae:	4581                	li	a1,0
    800052b0:	4501                	li	a0,0
    800052b2:	00000097          	auipc	ra,0x0
    800052b6:	d2a080e7          	jalr	-726(ra) # 80004fdc <argfd>
    return -1;
    800052ba:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800052bc:	04054163          	bltz	a0,800052fe <sys_write+0x5c>
    800052c0:	fe440593          	addi	a1,s0,-28
    800052c4:	4509                	li	a0,2
    800052c6:	ffffe097          	auipc	ra,0xffffe
    800052ca:	8d2080e7          	jalr	-1838(ra) # 80002b98 <argint>
    return -1;
    800052ce:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800052d0:	02054763          	bltz	a0,800052fe <sys_write+0x5c>
    800052d4:	fd840593          	addi	a1,s0,-40
    800052d8:	4505                	li	a0,1
    800052da:	ffffe097          	auipc	ra,0xffffe
    800052de:	8e0080e7          	jalr	-1824(ra) # 80002bba <argaddr>
    return -1;
    800052e2:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800052e4:	00054d63          	bltz	a0,800052fe <sys_write+0x5c>
  return filewrite(f, p, n);
    800052e8:	fe442603          	lw	a2,-28(s0)
    800052ec:	fd843583          	ld	a1,-40(s0)
    800052f0:	fe843503          	ld	a0,-24(s0)
    800052f4:	fffff097          	auipc	ra,0xfffff
    800052f8:	4fa080e7          	jalr	1274(ra) # 800047ee <filewrite>
    800052fc:	87aa                	mv	a5,a0
}
    800052fe:	853e                	mv	a0,a5
    80005300:	70a2                	ld	ra,40(sp)
    80005302:	7402                	ld	s0,32(sp)
    80005304:	6145                	addi	sp,sp,48
    80005306:	8082                	ret

0000000080005308 <sys_close>:
{
    80005308:	1101                	addi	sp,sp,-32
    8000530a:	ec06                	sd	ra,24(sp)
    8000530c:	e822                	sd	s0,16(sp)
    8000530e:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005310:	fe040613          	addi	a2,s0,-32
    80005314:	fec40593          	addi	a1,s0,-20
    80005318:	4501                	li	a0,0
    8000531a:	00000097          	auipc	ra,0x0
    8000531e:	cc2080e7          	jalr	-830(ra) # 80004fdc <argfd>
    return -1;
    80005322:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005324:	02054463          	bltz	a0,8000534c <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005328:	ffffc097          	auipc	ra,0xffffc
    8000532c:	78a080e7          	jalr	1930(ra) # 80001ab2 <myproc>
    80005330:	fec42783          	lw	a5,-20(s0)
    80005334:	07e9                	addi	a5,a5,26
    80005336:	078e                	slli	a5,a5,0x3
    80005338:	97aa                	add	a5,a5,a0
    8000533a:	0007b423          	sd	zero,8(a5)
  fileclose(f);
    8000533e:	fe043503          	ld	a0,-32(s0)
    80005342:	fffff097          	auipc	ra,0xfffff
    80005346:	2b0080e7          	jalr	688(ra) # 800045f2 <fileclose>
  return 0;
    8000534a:	4781                	li	a5,0
}
    8000534c:	853e                	mv	a0,a5
    8000534e:	60e2                	ld	ra,24(sp)
    80005350:	6442                	ld	s0,16(sp)
    80005352:	6105                	addi	sp,sp,32
    80005354:	8082                	ret

0000000080005356 <sys_fstat>:
{
    80005356:	1101                	addi	sp,sp,-32
    80005358:	ec06                	sd	ra,24(sp)
    8000535a:	e822                	sd	s0,16(sp)
    8000535c:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    8000535e:	fe840613          	addi	a2,s0,-24
    80005362:	4581                	li	a1,0
    80005364:	4501                	li	a0,0
    80005366:	00000097          	auipc	ra,0x0
    8000536a:	c76080e7          	jalr	-906(ra) # 80004fdc <argfd>
    return -1;
    8000536e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005370:	02054563          	bltz	a0,8000539a <sys_fstat+0x44>
    80005374:	fe040593          	addi	a1,s0,-32
    80005378:	4505                	li	a0,1
    8000537a:	ffffe097          	auipc	ra,0xffffe
    8000537e:	840080e7          	jalr	-1984(ra) # 80002bba <argaddr>
    return -1;
    80005382:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005384:	00054b63          	bltz	a0,8000539a <sys_fstat+0x44>
  return filestat(f, st);
    80005388:	fe043583          	ld	a1,-32(s0)
    8000538c:	fe843503          	ld	a0,-24(s0)
    80005390:	fffff097          	auipc	ra,0xfffff
    80005394:	32a080e7          	jalr	810(ra) # 800046ba <filestat>
    80005398:	87aa                	mv	a5,a0
}
    8000539a:	853e                	mv	a0,a5
    8000539c:	60e2                	ld	ra,24(sp)
    8000539e:	6442                	ld	s0,16(sp)
    800053a0:	6105                	addi	sp,sp,32
    800053a2:	8082                	ret

00000000800053a4 <sys_link>:
{
    800053a4:	7169                	addi	sp,sp,-304
    800053a6:	f606                	sd	ra,296(sp)
    800053a8:	f222                	sd	s0,288(sp)
    800053aa:	ee26                	sd	s1,280(sp)
    800053ac:	ea4a                	sd	s2,272(sp)
    800053ae:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800053b0:	08000613          	li	a2,128
    800053b4:	ed040593          	addi	a1,s0,-304
    800053b8:	4501                	li	a0,0
    800053ba:	ffffe097          	auipc	ra,0xffffe
    800053be:	822080e7          	jalr	-2014(ra) # 80002bdc <argstr>
    return -1;
    800053c2:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800053c4:	10054e63          	bltz	a0,800054e0 <sys_link+0x13c>
    800053c8:	08000613          	li	a2,128
    800053cc:	f5040593          	addi	a1,s0,-176
    800053d0:	4505                	li	a0,1
    800053d2:	ffffe097          	auipc	ra,0xffffe
    800053d6:	80a080e7          	jalr	-2038(ra) # 80002bdc <argstr>
    return -1;
    800053da:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800053dc:	10054263          	bltz	a0,800054e0 <sys_link+0x13c>
  begin_op();
    800053e0:	fffff097          	auipc	ra,0xfffff
    800053e4:	d46080e7          	jalr	-698(ra) # 80004126 <begin_op>
  if((ip = namei(old)) == 0){
    800053e8:	ed040513          	addi	a0,s0,-304
    800053ec:	fffff097          	auipc	ra,0xfffff
    800053f0:	b1e080e7          	jalr	-1250(ra) # 80003f0a <namei>
    800053f4:	84aa                	mv	s1,a0
    800053f6:	c551                	beqz	a0,80005482 <sys_link+0xde>
  ilock(ip);
    800053f8:	ffffe097          	auipc	ra,0xffffe
    800053fc:	35c080e7          	jalr	860(ra) # 80003754 <ilock>
  if(ip->type == T_DIR){
    80005400:	04449703          	lh	a4,68(s1)
    80005404:	4785                	li	a5,1
    80005406:	08f70463          	beq	a4,a5,8000548e <sys_link+0xea>
  ip->nlink++;
    8000540a:	04a4d783          	lhu	a5,74(s1)
    8000540e:	2785                	addiw	a5,a5,1
    80005410:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005414:	8526                	mv	a0,s1
    80005416:	ffffe097          	auipc	ra,0xffffe
    8000541a:	274080e7          	jalr	628(ra) # 8000368a <iupdate>
  iunlock(ip);
    8000541e:	8526                	mv	a0,s1
    80005420:	ffffe097          	auipc	ra,0xffffe
    80005424:	3f6080e7          	jalr	1014(ra) # 80003816 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005428:	fd040593          	addi	a1,s0,-48
    8000542c:	f5040513          	addi	a0,s0,-176
    80005430:	fffff097          	auipc	ra,0xfffff
    80005434:	af8080e7          	jalr	-1288(ra) # 80003f28 <nameiparent>
    80005438:	892a                	mv	s2,a0
    8000543a:	c935                	beqz	a0,800054ae <sys_link+0x10a>
  ilock(dp);
    8000543c:	ffffe097          	auipc	ra,0xffffe
    80005440:	318080e7          	jalr	792(ra) # 80003754 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005444:	00092703          	lw	a4,0(s2)
    80005448:	409c                	lw	a5,0(s1)
    8000544a:	04f71d63          	bne	a4,a5,800054a4 <sys_link+0x100>
    8000544e:	40d0                	lw	a2,4(s1)
    80005450:	fd040593          	addi	a1,s0,-48
    80005454:	854a                	mv	a0,s2
    80005456:	fffff097          	auipc	ra,0xfffff
    8000545a:	9f2080e7          	jalr	-1550(ra) # 80003e48 <dirlink>
    8000545e:	04054363          	bltz	a0,800054a4 <sys_link+0x100>
  iunlockput(dp);
    80005462:	854a                	mv	a0,s2
    80005464:	ffffe097          	auipc	ra,0xffffe
    80005468:	552080e7          	jalr	1362(ra) # 800039b6 <iunlockput>
  iput(ip);
    8000546c:	8526                	mv	a0,s1
    8000546e:	ffffe097          	auipc	ra,0xffffe
    80005472:	4a0080e7          	jalr	1184(ra) # 8000390e <iput>
  end_op();
    80005476:	fffff097          	auipc	ra,0xfffff
    8000547a:	d30080e7          	jalr	-720(ra) # 800041a6 <end_op>
  return 0;
    8000547e:	4781                	li	a5,0
    80005480:	a085                	j	800054e0 <sys_link+0x13c>
    end_op();
    80005482:	fffff097          	auipc	ra,0xfffff
    80005486:	d24080e7          	jalr	-732(ra) # 800041a6 <end_op>
    return -1;
    8000548a:	57fd                	li	a5,-1
    8000548c:	a891                	j	800054e0 <sys_link+0x13c>
    iunlockput(ip);
    8000548e:	8526                	mv	a0,s1
    80005490:	ffffe097          	auipc	ra,0xffffe
    80005494:	526080e7          	jalr	1318(ra) # 800039b6 <iunlockput>
    end_op();
    80005498:	fffff097          	auipc	ra,0xfffff
    8000549c:	d0e080e7          	jalr	-754(ra) # 800041a6 <end_op>
    return -1;
    800054a0:	57fd                	li	a5,-1
    800054a2:	a83d                	j	800054e0 <sys_link+0x13c>
    iunlockput(dp);
    800054a4:	854a                	mv	a0,s2
    800054a6:	ffffe097          	auipc	ra,0xffffe
    800054aa:	510080e7          	jalr	1296(ra) # 800039b6 <iunlockput>
  ilock(ip);
    800054ae:	8526                	mv	a0,s1
    800054b0:	ffffe097          	auipc	ra,0xffffe
    800054b4:	2a4080e7          	jalr	676(ra) # 80003754 <ilock>
  ip->nlink--;
    800054b8:	04a4d783          	lhu	a5,74(s1)
    800054bc:	37fd                	addiw	a5,a5,-1
    800054be:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800054c2:	8526                	mv	a0,s1
    800054c4:	ffffe097          	auipc	ra,0xffffe
    800054c8:	1c6080e7          	jalr	454(ra) # 8000368a <iupdate>
  iunlockput(ip);
    800054cc:	8526                	mv	a0,s1
    800054ce:	ffffe097          	auipc	ra,0xffffe
    800054d2:	4e8080e7          	jalr	1256(ra) # 800039b6 <iunlockput>
  end_op();
    800054d6:	fffff097          	auipc	ra,0xfffff
    800054da:	cd0080e7          	jalr	-816(ra) # 800041a6 <end_op>
  return -1;
    800054de:	57fd                	li	a5,-1
}
    800054e0:	853e                	mv	a0,a5
    800054e2:	70b2                	ld	ra,296(sp)
    800054e4:	7412                	ld	s0,288(sp)
    800054e6:	64f2                	ld	s1,280(sp)
    800054e8:	6952                	ld	s2,272(sp)
    800054ea:	6155                	addi	sp,sp,304
    800054ec:	8082                	ret

00000000800054ee <sys_unlink>:
{
    800054ee:	7151                	addi	sp,sp,-240
    800054f0:	f586                	sd	ra,232(sp)
    800054f2:	f1a2                	sd	s0,224(sp)
    800054f4:	eda6                	sd	s1,216(sp)
    800054f6:	e9ca                	sd	s2,208(sp)
    800054f8:	e5ce                	sd	s3,200(sp)
    800054fa:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    800054fc:	08000613          	li	a2,128
    80005500:	f3040593          	addi	a1,s0,-208
    80005504:	4501                	li	a0,0
    80005506:	ffffd097          	auipc	ra,0xffffd
    8000550a:	6d6080e7          	jalr	1750(ra) # 80002bdc <argstr>
    8000550e:	18054163          	bltz	a0,80005690 <sys_unlink+0x1a2>
  begin_op();
    80005512:	fffff097          	auipc	ra,0xfffff
    80005516:	c14080e7          	jalr	-1004(ra) # 80004126 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    8000551a:	fb040593          	addi	a1,s0,-80
    8000551e:	f3040513          	addi	a0,s0,-208
    80005522:	fffff097          	auipc	ra,0xfffff
    80005526:	a06080e7          	jalr	-1530(ra) # 80003f28 <nameiparent>
    8000552a:	84aa                	mv	s1,a0
    8000552c:	c979                	beqz	a0,80005602 <sys_unlink+0x114>
  ilock(dp);
    8000552e:	ffffe097          	auipc	ra,0xffffe
    80005532:	226080e7          	jalr	550(ra) # 80003754 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005536:	00003597          	auipc	a1,0x3
    8000553a:	1ea58593          	addi	a1,a1,490 # 80008720 <syscalls+0x2c0>
    8000553e:	fb040513          	addi	a0,s0,-80
    80005542:	ffffe097          	auipc	ra,0xffffe
    80005546:	6dc080e7          	jalr	1756(ra) # 80003c1e <namecmp>
    8000554a:	14050a63          	beqz	a0,8000569e <sys_unlink+0x1b0>
    8000554e:	00003597          	auipc	a1,0x3
    80005552:	1da58593          	addi	a1,a1,474 # 80008728 <syscalls+0x2c8>
    80005556:	fb040513          	addi	a0,s0,-80
    8000555a:	ffffe097          	auipc	ra,0xffffe
    8000555e:	6c4080e7          	jalr	1732(ra) # 80003c1e <namecmp>
    80005562:	12050e63          	beqz	a0,8000569e <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005566:	f2c40613          	addi	a2,s0,-212
    8000556a:	fb040593          	addi	a1,s0,-80
    8000556e:	8526                	mv	a0,s1
    80005570:	ffffe097          	auipc	ra,0xffffe
    80005574:	6c8080e7          	jalr	1736(ra) # 80003c38 <dirlookup>
    80005578:	892a                	mv	s2,a0
    8000557a:	12050263          	beqz	a0,8000569e <sys_unlink+0x1b0>
  ilock(ip);
    8000557e:	ffffe097          	auipc	ra,0xffffe
    80005582:	1d6080e7          	jalr	470(ra) # 80003754 <ilock>
  if(ip->nlink < 1)
    80005586:	04a91783          	lh	a5,74(s2)
    8000558a:	08f05263          	blez	a5,8000560e <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    8000558e:	04491703          	lh	a4,68(s2)
    80005592:	4785                	li	a5,1
    80005594:	08f70563          	beq	a4,a5,8000561e <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005598:	4641                	li	a2,16
    8000559a:	4581                	li	a1,0
    8000559c:	fc040513          	addi	a0,s0,-64
    800055a0:	ffffb097          	auipc	ra,0xffffb
    800055a4:	740080e7          	jalr	1856(ra) # 80000ce0 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800055a8:	4741                	li	a4,16
    800055aa:	f2c42683          	lw	a3,-212(s0)
    800055ae:	fc040613          	addi	a2,s0,-64
    800055b2:	4581                	li	a1,0
    800055b4:	8526                	mv	a0,s1
    800055b6:	ffffe097          	auipc	ra,0xffffe
    800055ba:	54a080e7          	jalr	1354(ra) # 80003b00 <writei>
    800055be:	47c1                	li	a5,16
    800055c0:	0af51563          	bne	a0,a5,8000566a <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    800055c4:	04491703          	lh	a4,68(s2)
    800055c8:	4785                	li	a5,1
    800055ca:	0af70863          	beq	a4,a5,8000567a <sys_unlink+0x18c>
  iunlockput(dp);
    800055ce:	8526                	mv	a0,s1
    800055d0:	ffffe097          	auipc	ra,0xffffe
    800055d4:	3e6080e7          	jalr	998(ra) # 800039b6 <iunlockput>
  ip->nlink--;
    800055d8:	04a95783          	lhu	a5,74(s2)
    800055dc:	37fd                	addiw	a5,a5,-1
    800055de:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    800055e2:	854a                	mv	a0,s2
    800055e4:	ffffe097          	auipc	ra,0xffffe
    800055e8:	0a6080e7          	jalr	166(ra) # 8000368a <iupdate>
  iunlockput(ip);
    800055ec:	854a                	mv	a0,s2
    800055ee:	ffffe097          	auipc	ra,0xffffe
    800055f2:	3c8080e7          	jalr	968(ra) # 800039b6 <iunlockput>
  end_op();
    800055f6:	fffff097          	auipc	ra,0xfffff
    800055fa:	bb0080e7          	jalr	-1104(ra) # 800041a6 <end_op>
  return 0;
    800055fe:	4501                	li	a0,0
    80005600:	a84d                	j	800056b2 <sys_unlink+0x1c4>
    end_op();
    80005602:	fffff097          	auipc	ra,0xfffff
    80005606:	ba4080e7          	jalr	-1116(ra) # 800041a6 <end_op>
    return -1;
    8000560a:	557d                	li	a0,-1
    8000560c:	a05d                	j	800056b2 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    8000560e:	00003517          	auipc	a0,0x3
    80005612:	14250513          	addi	a0,a0,322 # 80008750 <syscalls+0x2f0>
    80005616:	ffffb097          	auipc	ra,0xffffb
    8000561a:	f28080e7          	jalr	-216(ra) # 8000053e <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    8000561e:	04c92703          	lw	a4,76(s2)
    80005622:	02000793          	li	a5,32
    80005626:	f6e7f9e3          	bgeu	a5,a4,80005598 <sys_unlink+0xaa>
    8000562a:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000562e:	4741                	li	a4,16
    80005630:	86ce                	mv	a3,s3
    80005632:	f1840613          	addi	a2,s0,-232
    80005636:	4581                	li	a1,0
    80005638:	854a                	mv	a0,s2
    8000563a:	ffffe097          	auipc	ra,0xffffe
    8000563e:	3ce080e7          	jalr	974(ra) # 80003a08 <readi>
    80005642:	47c1                	li	a5,16
    80005644:	00f51b63          	bne	a0,a5,8000565a <sys_unlink+0x16c>
    if(de.inum != 0)
    80005648:	f1845783          	lhu	a5,-232(s0)
    8000564c:	e7a1                	bnez	a5,80005694 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    8000564e:	29c1                	addiw	s3,s3,16
    80005650:	04c92783          	lw	a5,76(s2)
    80005654:	fcf9ede3          	bltu	s3,a5,8000562e <sys_unlink+0x140>
    80005658:	b781                	j	80005598 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    8000565a:	00003517          	auipc	a0,0x3
    8000565e:	10e50513          	addi	a0,a0,270 # 80008768 <syscalls+0x308>
    80005662:	ffffb097          	auipc	ra,0xffffb
    80005666:	edc080e7          	jalr	-292(ra) # 8000053e <panic>
    panic("unlink: writei");
    8000566a:	00003517          	auipc	a0,0x3
    8000566e:	11650513          	addi	a0,a0,278 # 80008780 <syscalls+0x320>
    80005672:	ffffb097          	auipc	ra,0xffffb
    80005676:	ecc080e7          	jalr	-308(ra) # 8000053e <panic>
    dp->nlink--;
    8000567a:	04a4d783          	lhu	a5,74(s1)
    8000567e:	37fd                	addiw	a5,a5,-1
    80005680:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005684:	8526                	mv	a0,s1
    80005686:	ffffe097          	auipc	ra,0xffffe
    8000568a:	004080e7          	jalr	4(ra) # 8000368a <iupdate>
    8000568e:	b781                	j	800055ce <sys_unlink+0xe0>
    return -1;
    80005690:	557d                	li	a0,-1
    80005692:	a005                	j	800056b2 <sys_unlink+0x1c4>
    iunlockput(ip);
    80005694:	854a                	mv	a0,s2
    80005696:	ffffe097          	auipc	ra,0xffffe
    8000569a:	320080e7          	jalr	800(ra) # 800039b6 <iunlockput>
  iunlockput(dp);
    8000569e:	8526                	mv	a0,s1
    800056a0:	ffffe097          	auipc	ra,0xffffe
    800056a4:	316080e7          	jalr	790(ra) # 800039b6 <iunlockput>
  end_op();
    800056a8:	fffff097          	auipc	ra,0xfffff
    800056ac:	afe080e7          	jalr	-1282(ra) # 800041a6 <end_op>
  return -1;
    800056b0:	557d                	li	a0,-1
}
    800056b2:	70ae                	ld	ra,232(sp)
    800056b4:	740e                	ld	s0,224(sp)
    800056b6:	64ee                	ld	s1,216(sp)
    800056b8:	694e                	ld	s2,208(sp)
    800056ba:	69ae                	ld	s3,200(sp)
    800056bc:	616d                	addi	sp,sp,240
    800056be:	8082                	ret

00000000800056c0 <sys_open>:

uint64
sys_open(void)
{
    800056c0:	7131                	addi	sp,sp,-192
    800056c2:	fd06                	sd	ra,184(sp)
    800056c4:	f922                	sd	s0,176(sp)
    800056c6:	f526                	sd	s1,168(sp)
    800056c8:	f14a                	sd	s2,160(sp)
    800056ca:	ed4e                	sd	s3,152(sp)
    800056cc:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    800056ce:	08000613          	li	a2,128
    800056d2:	f5040593          	addi	a1,s0,-176
    800056d6:	4501                	li	a0,0
    800056d8:	ffffd097          	auipc	ra,0xffffd
    800056dc:	504080e7          	jalr	1284(ra) # 80002bdc <argstr>
    return -1;
    800056e0:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    800056e2:	0c054163          	bltz	a0,800057a4 <sys_open+0xe4>
    800056e6:	f4c40593          	addi	a1,s0,-180
    800056ea:	4505                	li	a0,1
    800056ec:	ffffd097          	auipc	ra,0xffffd
    800056f0:	4ac080e7          	jalr	1196(ra) # 80002b98 <argint>
    800056f4:	0a054863          	bltz	a0,800057a4 <sys_open+0xe4>

  begin_op();
    800056f8:	fffff097          	auipc	ra,0xfffff
    800056fc:	a2e080e7          	jalr	-1490(ra) # 80004126 <begin_op>

  if(omode & O_CREATE){
    80005700:	f4c42783          	lw	a5,-180(s0)
    80005704:	2007f793          	andi	a5,a5,512
    80005708:	cbdd                	beqz	a5,800057be <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    8000570a:	4681                	li	a3,0
    8000570c:	4601                	li	a2,0
    8000570e:	4589                	li	a1,2
    80005710:	f5040513          	addi	a0,s0,-176
    80005714:	00000097          	auipc	ra,0x0
    80005718:	972080e7          	jalr	-1678(ra) # 80005086 <create>
    8000571c:	892a                	mv	s2,a0
    if(ip == 0){
    8000571e:	c959                	beqz	a0,800057b4 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005720:	04491703          	lh	a4,68(s2)
    80005724:	478d                	li	a5,3
    80005726:	00f71763          	bne	a4,a5,80005734 <sys_open+0x74>
    8000572a:	04695703          	lhu	a4,70(s2)
    8000572e:	47a5                	li	a5,9
    80005730:	0ce7ec63          	bltu	a5,a4,80005808 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005734:	fffff097          	auipc	ra,0xfffff
    80005738:	e02080e7          	jalr	-510(ra) # 80004536 <filealloc>
    8000573c:	89aa                	mv	s3,a0
    8000573e:	10050263          	beqz	a0,80005842 <sys_open+0x182>
    80005742:	00000097          	auipc	ra,0x0
    80005746:	902080e7          	jalr	-1790(ra) # 80005044 <fdalloc>
    8000574a:	84aa                	mv	s1,a0
    8000574c:	0e054663          	bltz	a0,80005838 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005750:	04491703          	lh	a4,68(s2)
    80005754:	478d                	li	a5,3
    80005756:	0cf70463          	beq	a4,a5,8000581e <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    8000575a:	4789                	li	a5,2
    8000575c:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005760:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005764:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005768:	f4c42783          	lw	a5,-180(s0)
    8000576c:	0017c713          	xori	a4,a5,1
    80005770:	8b05                	andi	a4,a4,1
    80005772:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005776:	0037f713          	andi	a4,a5,3
    8000577a:	00e03733          	snez	a4,a4
    8000577e:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005782:	4007f793          	andi	a5,a5,1024
    80005786:	c791                	beqz	a5,80005792 <sys_open+0xd2>
    80005788:	04491703          	lh	a4,68(s2)
    8000578c:	4789                	li	a5,2
    8000578e:	08f70f63          	beq	a4,a5,8000582c <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005792:	854a                	mv	a0,s2
    80005794:	ffffe097          	auipc	ra,0xffffe
    80005798:	082080e7          	jalr	130(ra) # 80003816 <iunlock>
  end_op();
    8000579c:	fffff097          	auipc	ra,0xfffff
    800057a0:	a0a080e7          	jalr	-1526(ra) # 800041a6 <end_op>

  return fd;
}
    800057a4:	8526                	mv	a0,s1
    800057a6:	70ea                	ld	ra,184(sp)
    800057a8:	744a                	ld	s0,176(sp)
    800057aa:	74aa                	ld	s1,168(sp)
    800057ac:	790a                	ld	s2,160(sp)
    800057ae:	69ea                	ld	s3,152(sp)
    800057b0:	6129                	addi	sp,sp,192
    800057b2:	8082                	ret
      end_op();
    800057b4:	fffff097          	auipc	ra,0xfffff
    800057b8:	9f2080e7          	jalr	-1550(ra) # 800041a6 <end_op>
      return -1;
    800057bc:	b7e5                	j	800057a4 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    800057be:	f5040513          	addi	a0,s0,-176
    800057c2:	ffffe097          	auipc	ra,0xffffe
    800057c6:	748080e7          	jalr	1864(ra) # 80003f0a <namei>
    800057ca:	892a                	mv	s2,a0
    800057cc:	c905                	beqz	a0,800057fc <sys_open+0x13c>
    ilock(ip);
    800057ce:	ffffe097          	auipc	ra,0xffffe
    800057d2:	f86080e7          	jalr	-122(ra) # 80003754 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    800057d6:	04491703          	lh	a4,68(s2)
    800057da:	4785                	li	a5,1
    800057dc:	f4f712e3          	bne	a4,a5,80005720 <sys_open+0x60>
    800057e0:	f4c42783          	lw	a5,-180(s0)
    800057e4:	dba1                	beqz	a5,80005734 <sys_open+0x74>
      iunlockput(ip);
    800057e6:	854a                	mv	a0,s2
    800057e8:	ffffe097          	auipc	ra,0xffffe
    800057ec:	1ce080e7          	jalr	462(ra) # 800039b6 <iunlockput>
      end_op();
    800057f0:	fffff097          	auipc	ra,0xfffff
    800057f4:	9b6080e7          	jalr	-1610(ra) # 800041a6 <end_op>
      return -1;
    800057f8:	54fd                	li	s1,-1
    800057fa:	b76d                	j	800057a4 <sys_open+0xe4>
      end_op();
    800057fc:	fffff097          	auipc	ra,0xfffff
    80005800:	9aa080e7          	jalr	-1622(ra) # 800041a6 <end_op>
      return -1;
    80005804:	54fd                	li	s1,-1
    80005806:	bf79                	j	800057a4 <sys_open+0xe4>
    iunlockput(ip);
    80005808:	854a                	mv	a0,s2
    8000580a:	ffffe097          	auipc	ra,0xffffe
    8000580e:	1ac080e7          	jalr	428(ra) # 800039b6 <iunlockput>
    end_op();
    80005812:	fffff097          	auipc	ra,0xfffff
    80005816:	994080e7          	jalr	-1644(ra) # 800041a6 <end_op>
    return -1;
    8000581a:	54fd                	li	s1,-1
    8000581c:	b761                	j	800057a4 <sys_open+0xe4>
    f->type = FD_DEVICE;
    8000581e:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005822:	04691783          	lh	a5,70(s2)
    80005826:	02f99223          	sh	a5,36(s3)
    8000582a:	bf2d                	j	80005764 <sys_open+0xa4>
    itrunc(ip);
    8000582c:	854a                	mv	a0,s2
    8000582e:	ffffe097          	auipc	ra,0xffffe
    80005832:	034080e7          	jalr	52(ra) # 80003862 <itrunc>
    80005836:	bfb1                	j	80005792 <sys_open+0xd2>
      fileclose(f);
    80005838:	854e                	mv	a0,s3
    8000583a:	fffff097          	auipc	ra,0xfffff
    8000583e:	db8080e7          	jalr	-584(ra) # 800045f2 <fileclose>
    iunlockput(ip);
    80005842:	854a                	mv	a0,s2
    80005844:	ffffe097          	auipc	ra,0xffffe
    80005848:	172080e7          	jalr	370(ra) # 800039b6 <iunlockput>
    end_op();
    8000584c:	fffff097          	auipc	ra,0xfffff
    80005850:	95a080e7          	jalr	-1702(ra) # 800041a6 <end_op>
    return -1;
    80005854:	54fd                	li	s1,-1
    80005856:	b7b9                	j	800057a4 <sys_open+0xe4>

0000000080005858 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005858:	7175                	addi	sp,sp,-144
    8000585a:	e506                	sd	ra,136(sp)
    8000585c:	e122                	sd	s0,128(sp)
    8000585e:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005860:	fffff097          	auipc	ra,0xfffff
    80005864:	8c6080e7          	jalr	-1850(ra) # 80004126 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005868:	08000613          	li	a2,128
    8000586c:	f7040593          	addi	a1,s0,-144
    80005870:	4501                	li	a0,0
    80005872:	ffffd097          	auipc	ra,0xffffd
    80005876:	36a080e7          	jalr	874(ra) # 80002bdc <argstr>
    8000587a:	02054963          	bltz	a0,800058ac <sys_mkdir+0x54>
    8000587e:	4681                	li	a3,0
    80005880:	4601                	li	a2,0
    80005882:	4585                	li	a1,1
    80005884:	f7040513          	addi	a0,s0,-144
    80005888:	fffff097          	auipc	ra,0xfffff
    8000588c:	7fe080e7          	jalr	2046(ra) # 80005086 <create>
    80005890:	cd11                	beqz	a0,800058ac <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005892:	ffffe097          	auipc	ra,0xffffe
    80005896:	124080e7          	jalr	292(ra) # 800039b6 <iunlockput>
  end_op();
    8000589a:	fffff097          	auipc	ra,0xfffff
    8000589e:	90c080e7          	jalr	-1780(ra) # 800041a6 <end_op>
  return 0;
    800058a2:	4501                	li	a0,0
}
    800058a4:	60aa                	ld	ra,136(sp)
    800058a6:	640a                	ld	s0,128(sp)
    800058a8:	6149                	addi	sp,sp,144
    800058aa:	8082                	ret
    end_op();
    800058ac:	fffff097          	auipc	ra,0xfffff
    800058b0:	8fa080e7          	jalr	-1798(ra) # 800041a6 <end_op>
    return -1;
    800058b4:	557d                	li	a0,-1
    800058b6:	b7fd                	j	800058a4 <sys_mkdir+0x4c>

00000000800058b8 <sys_mknod>:

uint64
sys_mknod(void)
{
    800058b8:	7135                	addi	sp,sp,-160
    800058ba:	ed06                	sd	ra,152(sp)
    800058bc:	e922                	sd	s0,144(sp)
    800058be:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    800058c0:	fffff097          	auipc	ra,0xfffff
    800058c4:	866080e7          	jalr	-1946(ra) # 80004126 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800058c8:	08000613          	li	a2,128
    800058cc:	f7040593          	addi	a1,s0,-144
    800058d0:	4501                	li	a0,0
    800058d2:	ffffd097          	auipc	ra,0xffffd
    800058d6:	30a080e7          	jalr	778(ra) # 80002bdc <argstr>
    800058da:	04054a63          	bltz	a0,8000592e <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    800058de:	f6c40593          	addi	a1,s0,-148
    800058e2:	4505                	li	a0,1
    800058e4:	ffffd097          	auipc	ra,0xffffd
    800058e8:	2b4080e7          	jalr	692(ra) # 80002b98 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800058ec:	04054163          	bltz	a0,8000592e <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    800058f0:	f6840593          	addi	a1,s0,-152
    800058f4:	4509                	li	a0,2
    800058f6:	ffffd097          	auipc	ra,0xffffd
    800058fa:	2a2080e7          	jalr	674(ra) # 80002b98 <argint>
     argint(1, &major) < 0 ||
    800058fe:	02054863          	bltz	a0,8000592e <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005902:	f6841683          	lh	a3,-152(s0)
    80005906:	f6c41603          	lh	a2,-148(s0)
    8000590a:	458d                	li	a1,3
    8000590c:	f7040513          	addi	a0,s0,-144
    80005910:	fffff097          	auipc	ra,0xfffff
    80005914:	776080e7          	jalr	1910(ra) # 80005086 <create>
     argint(2, &minor) < 0 ||
    80005918:	c919                	beqz	a0,8000592e <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    8000591a:	ffffe097          	auipc	ra,0xffffe
    8000591e:	09c080e7          	jalr	156(ra) # 800039b6 <iunlockput>
  end_op();
    80005922:	fffff097          	auipc	ra,0xfffff
    80005926:	884080e7          	jalr	-1916(ra) # 800041a6 <end_op>
  return 0;
    8000592a:	4501                	li	a0,0
    8000592c:	a031                	j	80005938 <sys_mknod+0x80>
    end_op();
    8000592e:	fffff097          	auipc	ra,0xfffff
    80005932:	878080e7          	jalr	-1928(ra) # 800041a6 <end_op>
    return -1;
    80005936:	557d                	li	a0,-1
}
    80005938:	60ea                	ld	ra,152(sp)
    8000593a:	644a                	ld	s0,144(sp)
    8000593c:	610d                	addi	sp,sp,160
    8000593e:	8082                	ret

0000000080005940 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005940:	7135                	addi	sp,sp,-160
    80005942:	ed06                	sd	ra,152(sp)
    80005944:	e922                	sd	s0,144(sp)
    80005946:	e526                	sd	s1,136(sp)
    80005948:	e14a                	sd	s2,128(sp)
    8000594a:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    8000594c:	ffffc097          	auipc	ra,0xffffc
    80005950:	166080e7          	jalr	358(ra) # 80001ab2 <myproc>
    80005954:	892a                	mv	s2,a0
  
  begin_op();
    80005956:	ffffe097          	auipc	ra,0xffffe
    8000595a:	7d0080e7          	jalr	2000(ra) # 80004126 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    8000595e:	08000613          	li	a2,128
    80005962:	f6040593          	addi	a1,s0,-160
    80005966:	4501                	li	a0,0
    80005968:	ffffd097          	auipc	ra,0xffffd
    8000596c:	274080e7          	jalr	628(ra) # 80002bdc <argstr>
    80005970:	04054b63          	bltz	a0,800059c6 <sys_chdir+0x86>
    80005974:	f6040513          	addi	a0,s0,-160
    80005978:	ffffe097          	auipc	ra,0xffffe
    8000597c:	592080e7          	jalr	1426(ra) # 80003f0a <namei>
    80005980:	84aa                	mv	s1,a0
    80005982:	c131                	beqz	a0,800059c6 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005984:	ffffe097          	auipc	ra,0xffffe
    80005988:	dd0080e7          	jalr	-560(ra) # 80003754 <ilock>
  if(ip->type != T_DIR){
    8000598c:	04449703          	lh	a4,68(s1)
    80005990:	4785                	li	a5,1
    80005992:	04f71063          	bne	a4,a5,800059d2 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005996:	8526                	mv	a0,s1
    80005998:	ffffe097          	auipc	ra,0xffffe
    8000599c:	e7e080e7          	jalr	-386(ra) # 80003816 <iunlock>
  iput(p->cwd);
    800059a0:	15893503          	ld	a0,344(s2)
    800059a4:	ffffe097          	auipc	ra,0xffffe
    800059a8:	f6a080e7          	jalr	-150(ra) # 8000390e <iput>
  end_op();
    800059ac:	ffffe097          	auipc	ra,0xffffe
    800059b0:	7fa080e7          	jalr	2042(ra) # 800041a6 <end_op>
  p->cwd = ip;
    800059b4:	14993c23          	sd	s1,344(s2)
  return 0;
    800059b8:	4501                	li	a0,0
}
    800059ba:	60ea                	ld	ra,152(sp)
    800059bc:	644a                	ld	s0,144(sp)
    800059be:	64aa                	ld	s1,136(sp)
    800059c0:	690a                	ld	s2,128(sp)
    800059c2:	610d                	addi	sp,sp,160
    800059c4:	8082                	ret
    end_op();
    800059c6:	ffffe097          	auipc	ra,0xffffe
    800059ca:	7e0080e7          	jalr	2016(ra) # 800041a6 <end_op>
    return -1;
    800059ce:	557d                	li	a0,-1
    800059d0:	b7ed                	j	800059ba <sys_chdir+0x7a>
    iunlockput(ip);
    800059d2:	8526                	mv	a0,s1
    800059d4:	ffffe097          	auipc	ra,0xffffe
    800059d8:	fe2080e7          	jalr	-30(ra) # 800039b6 <iunlockput>
    end_op();
    800059dc:	ffffe097          	auipc	ra,0xffffe
    800059e0:	7ca080e7          	jalr	1994(ra) # 800041a6 <end_op>
    return -1;
    800059e4:	557d                	li	a0,-1
    800059e6:	bfd1                	j	800059ba <sys_chdir+0x7a>

00000000800059e8 <sys_exec>:

uint64
sys_exec(void)
{
    800059e8:	7145                	addi	sp,sp,-464
    800059ea:	e786                	sd	ra,456(sp)
    800059ec:	e3a2                	sd	s0,448(sp)
    800059ee:	ff26                	sd	s1,440(sp)
    800059f0:	fb4a                	sd	s2,432(sp)
    800059f2:	f74e                	sd	s3,424(sp)
    800059f4:	f352                	sd	s4,416(sp)
    800059f6:	ef56                	sd	s5,408(sp)
    800059f8:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    800059fa:	08000613          	li	a2,128
    800059fe:	f4040593          	addi	a1,s0,-192
    80005a02:	4501                	li	a0,0
    80005a04:	ffffd097          	auipc	ra,0xffffd
    80005a08:	1d8080e7          	jalr	472(ra) # 80002bdc <argstr>
    return -1;
    80005a0c:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005a0e:	0c054a63          	bltz	a0,80005ae2 <sys_exec+0xfa>
    80005a12:	e3840593          	addi	a1,s0,-456
    80005a16:	4505                	li	a0,1
    80005a18:	ffffd097          	auipc	ra,0xffffd
    80005a1c:	1a2080e7          	jalr	418(ra) # 80002bba <argaddr>
    80005a20:	0c054163          	bltz	a0,80005ae2 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005a24:	10000613          	li	a2,256
    80005a28:	4581                	li	a1,0
    80005a2a:	e4040513          	addi	a0,s0,-448
    80005a2e:	ffffb097          	auipc	ra,0xffffb
    80005a32:	2b2080e7          	jalr	690(ra) # 80000ce0 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005a36:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005a3a:	89a6                	mv	s3,s1
    80005a3c:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005a3e:	02000a13          	li	s4,32
    80005a42:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005a46:	00391513          	slli	a0,s2,0x3
    80005a4a:	e3040593          	addi	a1,s0,-464
    80005a4e:	e3843783          	ld	a5,-456(s0)
    80005a52:	953e                	add	a0,a0,a5
    80005a54:	ffffd097          	auipc	ra,0xffffd
    80005a58:	0aa080e7          	jalr	170(ra) # 80002afe <fetchaddr>
    80005a5c:	02054a63          	bltz	a0,80005a90 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005a60:	e3043783          	ld	a5,-464(s0)
    80005a64:	c3b9                	beqz	a5,80005aaa <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005a66:	ffffb097          	auipc	ra,0xffffb
    80005a6a:	08e080e7          	jalr	142(ra) # 80000af4 <kalloc>
    80005a6e:	85aa                	mv	a1,a0
    80005a70:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005a74:	cd11                	beqz	a0,80005a90 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005a76:	6605                	lui	a2,0x1
    80005a78:	e3043503          	ld	a0,-464(s0)
    80005a7c:	ffffd097          	auipc	ra,0xffffd
    80005a80:	0d4080e7          	jalr	212(ra) # 80002b50 <fetchstr>
    80005a84:	00054663          	bltz	a0,80005a90 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005a88:	0905                	addi	s2,s2,1
    80005a8a:	09a1                	addi	s3,s3,8
    80005a8c:	fb491be3          	bne	s2,s4,80005a42 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005a90:	10048913          	addi	s2,s1,256
    80005a94:	6088                	ld	a0,0(s1)
    80005a96:	c529                	beqz	a0,80005ae0 <sys_exec+0xf8>
    kfree(argv[i]);
    80005a98:	ffffb097          	auipc	ra,0xffffb
    80005a9c:	f60080e7          	jalr	-160(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005aa0:	04a1                	addi	s1,s1,8
    80005aa2:	ff2499e3          	bne	s1,s2,80005a94 <sys_exec+0xac>
  return -1;
    80005aa6:	597d                	li	s2,-1
    80005aa8:	a82d                	j	80005ae2 <sys_exec+0xfa>
      argv[i] = 0;
    80005aaa:	0a8e                	slli	s5,s5,0x3
    80005aac:	fc040793          	addi	a5,s0,-64
    80005ab0:	9abe                	add	s5,s5,a5
    80005ab2:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005ab6:	e4040593          	addi	a1,s0,-448
    80005aba:	f4040513          	addi	a0,s0,-192
    80005abe:	fffff097          	auipc	ra,0xfffff
    80005ac2:	194080e7          	jalr	404(ra) # 80004c52 <exec>
    80005ac6:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005ac8:	10048993          	addi	s3,s1,256
    80005acc:	6088                	ld	a0,0(s1)
    80005ace:	c911                	beqz	a0,80005ae2 <sys_exec+0xfa>
    kfree(argv[i]);
    80005ad0:	ffffb097          	auipc	ra,0xffffb
    80005ad4:	f28080e7          	jalr	-216(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005ad8:	04a1                	addi	s1,s1,8
    80005ada:	ff3499e3          	bne	s1,s3,80005acc <sys_exec+0xe4>
    80005ade:	a011                	j	80005ae2 <sys_exec+0xfa>
  return -1;
    80005ae0:	597d                	li	s2,-1
}
    80005ae2:	854a                	mv	a0,s2
    80005ae4:	60be                	ld	ra,456(sp)
    80005ae6:	641e                	ld	s0,448(sp)
    80005ae8:	74fa                	ld	s1,440(sp)
    80005aea:	795a                	ld	s2,432(sp)
    80005aec:	79ba                	ld	s3,424(sp)
    80005aee:	7a1a                	ld	s4,416(sp)
    80005af0:	6afa                	ld	s5,408(sp)
    80005af2:	6179                	addi	sp,sp,464
    80005af4:	8082                	ret

0000000080005af6 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005af6:	7139                	addi	sp,sp,-64
    80005af8:	fc06                	sd	ra,56(sp)
    80005afa:	f822                	sd	s0,48(sp)
    80005afc:	f426                	sd	s1,40(sp)
    80005afe:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005b00:	ffffc097          	auipc	ra,0xffffc
    80005b04:	fb2080e7          	jalr	-78(ra) # 80001ab2 <myproc>
    80005b08:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005b0a:	fd840593          	addi	a1,s0,-40
    80005b0e:	4501                	li	a0,0
    80005b10:	ffffd097          	auipc	ra,0xffffd
    80005b14:	0aa080e7          	jalr	170(ra) # 80002bba <argaddr>
    return -1;
    80005b18:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005b1a:	0e054063          	bltz	a0,80005bfa <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005b1e:	fc840593          	addi	a1,s0,-56
    80005b22:	fd040513          	addi	a0,s0,-48
    80005b26:	fffff097          	auipc	ra,0xfffff
    80005b2a:	dfc080e7          	jalr	-516(ra) # 80004922 <pipealloc>
    return -1;
    80005b2e:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005b30:	0c054563          	bltz	a0,80005bfa <sys_pipe+0x104>
  fd0 = -1;
    80005b34:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005b38:	fd043503          	ld	a0,-48(s0)
    80005b3c:	fffff097          	auipc	ra,0xfffff
    80005b40:	508080e7          	jalr	1288(ra) # 80005044 <fdalloc>
    80005b44:	fca42223          	sw	a0,-60(s0)
    80005b48:	08054c63          	bltz	a0,80005be0 <sys_pipe+0xea>
    80005b4c:	fc843503          	ld	a0,-56(s0)
    80005b50:	fffff097          	auipc	ra,0xfffff
    80005b54:	4f4080e7          	jalr	1268(ra) # 80005044 <fdalloc>
    80005b58:	fca42023          	sw	a0,-64(s0)
    80005b5c:	06054863          	bltz	a0,80005bcc <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005b60:	4691                	li	a3,4
    80005b62:	fc440613          	addi	a2,s0,-60
    80005b66:	fd843583          	ld	a1,-40(s0)
    80005b6a:	6ca8                	ld	a0,88(s1)
    80005b6c:	ffffc097          	auipc	ra,0xffffc
    80005b70:	b06080e7          	jalr	-1274(ra) # 80001672 <copyout>
    80005b74:	02054063          	bltz	a0,80005b94 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005b78:	4691                	li	a3,4
    80005b7a:	fc040613          	addi	a2,s0,-64
    80005b7e:	fd843583          	ld	a1,-40(s0)
    80005b82:	0591                	addi	a1,a1,4
    80005b84:	6ca8                	ld	a0,88(s1)
    80005b86:	ffffc097          	auipc	ra,0xffffc
    80005b8a:	aec080e7          	jalr	-1300(ra) # 80001672 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005b8e:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005b90:	06055563          	bgez	a0,80005bfa <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005b94:	fc442783          	lw	a5,-60(s0)
    80005b98:	07e9                	addi	a5,a5,26
    80005b9a:	078e                	slli	a5,a5,0x3
    80005b9c:	97a6                	add	a5,a5,s1
    80005b9e:	0007b423          	sd	zero,8(a5)
    p->ofile[fd1] = 0;
    80005ba2:	fc042503          	lw	a0,-64(s0)
    80005ba6:	0569                	addi	a0,a0,26
    80005ba8:	050e                	slli	a0,a0,0x3
    80005baa:	9526                	add	a0,a0,s1
    80005bac:	00053423          	sd	zero,8(a0)
    fileclose(rf);
    80005bb0:	fd043503          	ld	a0,-48(s0)
    80005bb4:	fffff097          	auipc	ra,0xfffff
    80005bb8:	a3e080e7          	jalr	-1474(ra) # 800045f2 <fileclose>
    fileclose(wf);
    80005bbc:	fc843503          	ld	a0,-56(s0)
    80005bc0:	fffff097          	auipc	ra,0xfffff
    80005bc4:	a32080e7          	jalr	-1486(ra) # 800045f2 <fileclose>
    return -1;
    80005bc8:	57fd                	li	a5,-1
    80005bca:	a805                	j	80005bfa <sys_pipe+0x104>
    if(fd0 >= 0)
    80005bcc:	fc442783          	lw	a5,-60(s0)
    80005bd0:	0007c863          	bltz	a5,80005be0 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005bd4:	01a78513          	addi	a0,a5,26
    80005bd8:	050e                	slli	a0,a0,0x3
    80005bda:	9526                	add	a0,a0,s1
    80005bdc:	00053423          	sd	zero,8(a0)
    fileclose(rf);
    80005be0:	fd043503          	ld	a0,-48(s0)
    80005be4:	fffff097          	auipc	ra,0xfffff
    80005be8:	a0e080e7          	jalr	-1522(ra) # 800045f2 <fileclose>
    fileclose(wf);
    80005bec:	fc843503          	ld	a0,-56(s0)
    80005bf0:	fffff097          	auipc	ra,0xfffff
    80005bf4:	a02080e7          	jalr	-1534(ra) # 800045f2 <fileclose>
    return -1;
    80005bf8:	57fd                	li	a5,-1
}
    80005bfa:	853e                	mv	a0,a5
    80005bfc:	70e2                	ld	ra,56(sp)
    80005bfe:	7442                	ld	s0,48(sp)
    80005c00:	74a2                	ld	s1,40(sp)
    80005c02:	6121                	addi	sp,sp,64
    80005c04:	8082                	ret
	...

0000000080005c10 <kernelvec>:
    80005c10:	7111                	addi	sp,sp,-256
    80005c12:	e006                	sd	ra,0(sp)
    80005c14:	e40a                	sd	sp,8(sp)
    80005c16:	e80e                	sd	gp,16(sp)
    80005c18:	ec12                	sd	tp,24(sp)
    80005c1a:	f016                	sd	t0,32(sp)
    80005c1c:	f41a                	sd	t1,40(sp)
    80005c1e:	f81e                	sd	t2,48(sp)
    80005c20:	fc22                	sd	s0,56(sp)
    80005c22:	e0a6                	sd	s1,64(sp)
    80005c24:	e4aa                	sd	a0,72(sp)
    80005c26:	e8ae                	sd	a1,80(sp)
    80005c28:	ecb2                	sd	a2,88(sp)
    80005c2a:	f0b6                	sd	a3,96(sp)
    80005c2c:	f4ba                	sd	a4,104(sp)
    80005c2e:	f8be                	sd	a5,112(sp)
    80005c30:	fcc2                	sd	a6,120(sp)
    80005c32:	e146                	sd	a7,128(sp)
    80005c34:	e54a                	sd	s2,136(sp)
    80005c36:	e94e                	sd	s3,144(sp)
    80005c38:	ed52                	sd	s4,152(sp)
    80005c3a:	f156                	sd	s5,160(sp)
    80005c3c:	f55a                	sd	s6,168(sp)
    80005c3e:	f95e                	sd	s7,176(sp)
    80005c40:	fd62                	sd	s8,184(sp)
    80005c42:	e1e6                	sd	s9,192(sp)
    80005c44:	e5ea                	sd	s10,200(sp)
    80005c46:	e9ee                	sd	s11,208(sp)
    80005c48:	edf2                	sd	t3,216(sp)
    80005c4a:	f1f6                	sd	t4,224(sp)
    80005c4c:	f5fa                	sd	t5,232(sp)
    80005c4e:	f9fe                	sd	t6,240(sp)
    80005c50:	d7bfc0ef          	jal	ra,800029ca <kerneltrap>
    80005c54:	6082                	ld	ra,0(sp)
    80005c56:	6122                	ld	sp,8(sp)
    80005c58:	61c2                	ld	gp,16(sp)
    80005c5a:	7282                	ld	t0,32(sp)
    80005c5c:	7322                	ld	t1,40(sp)
    80005c5e:	73c2                	ld	t2,48(sp)
    80005c60:	7462                	ld	s0,56(sp)
    80005c62:	6486                	ld	s1,64(sp)
    80005c64:	6526                	ld	a0,72(sp)
    80005c66:	65c6                	ld	a1,80(sp)
    80005c68:	6666                	ld	a2,88(sp)
    80005c6a:	7686                	ld	a3,96(sp)
    80005c6c:	7726                	ld	a4,104(sp)
    80005c6e:	77c6                	ld	a5,112(sp)
    80005c70:	7866                	ld	a6,120(sp)
    80005c72:	688a                	ld	a7,128(sp)
    80005c74:	692a                	ld	s2,136(sp)
    80005c76:	69ca                	ld	s3,144(sp)
    80005c78:	6a6a                	ld	s4,152(sp)
    80005c7a:	7a8a                	ld	s5,160(sp)
    80005c7c:	7b2a                	ld	s6,168(sp)
    80005c7e:	7bca                	ld	s7,176(sp)
    80005c80:	7c6a                	ld	s8,184(sp)
    80005c82:	6c8e                	ld	s9,192(sp)
    80005c84:	6d2e                	ld	s10,200(sp)
    80005c86:	6dce                	ld	s11,208(sp)
    80005c88:	6e6e                	ld	t3,216(sp)
    80005c8a:	7e8e                	ld	t4,224(sp)
    80005c8c:	7f2e                	ld	t5,232(sp)
    80005c8e:	7fce                	ld	t6,240(sp)
    80005c90:	6111                	addi	sp,sp,256
    80005c92:	10200073          	sret
    80005c96:	00000013          	nop
    80005c9a:	00000013          	nop
    80005c9e:	0001                	nop

0000000080005ca0 <timervec>:
    80005ca0:	34051573          	csrrw	a0,mscratch,a0
    80005ca4:	e10c                	sd	a1,0(a0)
    80005ca6:	e510                	sd	a2,8(a0)
    80005ca8:	e914                	sd	a3,16(a0)
    80005caa:	6d0c                	ld	a1,24(a0)
    80005cac:	7110                	ld	a2,32(a0)
    80005cae:	6194                	ld	a3,0(a1)
    80005cb0:	96b2                	add	a3,a3,a2
    80005cb2:	e194                	sd	a3,0(a1)
    80005cb4:	4589                	li	a1,2
    80005cb6:	14459073          	csrw	sip,a1
    80005cba:	6914                	ld	a3,16(a0)
    80005cbc:	6510                	ld	a2,8(a0)
    80005cbe:	610c                	ld	a1,0(a0)
    80005cc0:	34051573          	csrrw	a0,mscratch,a0
    80005cc4:	30200073          	mret
	...

0000000080005cca <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005cca:	1141                	addi	sp,sp,-16
    80005ccc:	e422                	sd	s0,8(sp)
    80005cce:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005cd0:	0c0007b7          	lui	a5,0xc000
    80005cd4:	4705                	li	a4,1
    80005cd6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005cd8:	c3d8                	sw	a4,4(a5)
}
    80005cda:	6422                	ld	s0,8(sp)
    80005cdc:	0141                	addi	sp,sp,16
    80005cde:	8082                	ret

0000000080005ce0 <plicinithart>:

void
plicinithart(void)
{
    80005ce0:	1141                	addi	sp,sp,-16
    80005ce2:	e406                	sd	ra,8(sp)
    80005ce4:	e022                	sd	s0,0(sp)
    80005ce6:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005ce8:	ffffc097          	auipc	ra,0xffffc
    80005cec:	d9e080e7          	jalr	-610(ra) # 80001a86 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005cf0:	0085171b          	slliw	a4,a0,0x8
    80005cf4:	0c0027b7          	lui	a5,0xc002
    80005cf8:	97ba                	add	a5,a5,a4
    80005cfa:	40200713          	li	a4,1026
    80005cfe:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005d02:	00d5151b          	slliw	a0,a0,0xd
    80005d06:	0c2017b7          	lui	a5,0xc201
    80005d0a:	953e                	add	a0,a0,a5
    80005d0c:	00052023          	sw	zero,0(a0)
}
    80005d10:	60a2                	ld	ra,8(sp)
    80005d12:	6402                	ld	s0,0(sp)
    80005d14:	0141                	addi	sp,sp,16
    80005d16:	8082                	ret

0000000080005d18 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005d18:	1141                	addi	sp,sp,-16
    80005d1a:	e406                	sd	ra,8(sp)
    80005d1c:	e022                	sd	s0,0(sp)
    80005d1e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005d20:	ffffc097          	auipc	ra,0xffffc
    80005d24:	d66080e7          	jalr	-666(ra) # 80001a86 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005d28:	00d5179b          	slliw	a5,a0,0xd
    80005d2c:	0c201537          	lui	a0,0xc201
    80005d30:	953e                	add	a0,a0,a5
  return irq;
}
    80005d32:	4148                	lw	a0,4(a0)
    80005d34:	60a2                	ld	ra,8(sp)
    80005d36:	6402                	ld	s0,0(sp)
    80005d38:	0141                	addi	sp,sp,16
    80005d3a:	8082                	ret

0000000080005d3c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005d3c:	1101                	addi	sp,sp,-32
    80005d3e:	ec06                	sd	ra,24(sp)
    80005d40:	e822                	sd	s0,16(sp)
    80005d42:	e426                	sd	s1,8(sp)
    80005d44:	1000                	addi	s0,sp,32
    80005d46:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005d48:	ffffc097          	auipc	ra,0xffffc
    80005d4c:	d3e080e7          	jalr	-706(ra) # 80001a86 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005d50:	00d5151b          	slliw	a0,a0,0xd
    80005d54:	0c2017b7          	lui	a5,0xc201
    80005d58:	97aa                	add	a5,a5,a0
    80005d5a:	c3c4                	sw	s1,4(a5)
}
    80005d5c:	60e2                	ld	ra,24(sp)
    80005d5e:	6442                	ld	s0,16(sp)
    80005d60:	64a2                	ld	s1,8(sp)
    80005d62:	6105                	addi	sp,sp,32
    80005d64:	8082                	ret

0000000080005d66 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005d66:	1141                	addi	sp,sp,-16
    80005d68:	e406                	sd	ra,8(sp)
    80005d6a:	e022                	sd	s0,0(sp)
    80005d6c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005d6e:	479d                	li	a5,7
    80005d70:	06a7c963          	blt	a5,a0,80005de2 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    80005d74:	0001d797          	auipc	a5,0x1d
    80005d78:	28c78793          	addi	a5,a5,652 # 80023000 <disk>
    80005d7c:	00a78733          	add	a4,a5,a0
    80005d80:	6789                	lui	a5,0x2
    80005d82:	97ba                	add	a5,a5,a4
    80005d84:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80005d88:	e7ad                	bnez	a5,80005df2 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80005d8a:	00451793          	slli	a5,a0,0x4
    80005d8e:	0001f717          	auipc	a4,0x1f
    80005d92:	27270713          	addi	a4,a4,626 # 80025000 <disk+0x2000>
    80005d96:	6314                	ld	a3,0(a4)
    80005d98:	96be                	add	a3,a3,a5
    80005d9a:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    80005d9e:	6314                	ld	a3,0(a4)
    80005da0:	96be                	add	a3,a3,a5
    80005da2:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80005da6:	6314                	ld	a3,0(a4)
    80005da8:	96be                	add	a3,a3,a5
    80005daa:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    80005dae:	6318                	ld	a4,0(a4)
    80005db0:	97ba                	add	a5,a5,a4
    80005db2:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80005db6:	0001d797          	auipc	a5,0x1d
    80005dba:	24a78793          	addi	a5,a5,586 # 80023000 <disk>
    80005dbe:	97aa                	add	a5,a5,a0
    80005dc0:	6509                	lui	a0,0x2
    80005dc2:	953e                	add	a0,a0,a5
    80005dc4:	4785                	li	a5,1
    80005dc6:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    80005dca:	0001f517          	auipc	a0,0x1f
    80005dce:	24e50513          	addi	a0,a0,590 # 80025018 <disk+0x2018>
    80005dd2:	ffffc097          	auipc	ra,0xffffc
    80005dd6:	51e080e7          	jalr	1310(ra) # 800022f0 <wakeup>
}
    80005dda:	60a2                	ld	ra,8(sp)
    80005ddc:	6402                	ld	s0,0(sp)
    80005dde:	0141                	addi	sp,sp,16
    80005de0:	8082                	ret
    panic("free_desc 1");
    80005de2:	00003517          	auipc	a0,0x3
    80005de6:	9ae50513          	addi	a0,a0,-1618 # 80008790 <syscalls+0x330>
    80005dea:	ffffa097          	auipc	ra,0xffffa
    80005dee:	754080e7          	jalr	1876(ra) # 8000053e <panic>
    panic("free_desc 2");
    80005df2:	00003517          	auipc	a0,0x3
    80005df6:	9ae50513          	addi	a0,a0,-1618 # 800087a0 <syscalls+0x340>
    80005dfa:	ffffa097          	auipc	ra,0xffffa
    80005dfe:	744080e7          	jalr	1860(ra) # 8000053e <panic>

0000000080005e02 <virtio_disk_init>:
{
    80005e02:	1101                	addi	sp,sp,-32
    80005e04:	ec06                	sd	ra,24(sp)
    80005e06:	e822                	sd	s0,16(sp)
    80005e08:	e426                	sd	s1,8(sp)
    80005e0a:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005e0c:	00003597          	auipc	a1,0x3
    80005e10:	9a458593          	addi	a1,a1,-1628 # 800087b0 <syscalls+0x350>
    80005e14:	0001f517          	auipc	a0,0x1f
    80005e18:	31450513          	addi	a0,a0,788 # 80025128 <disk+0x2128>
    80005e1c:	ffffb097          	auipc	ra,0xffffb
    80005e20:	d38080e7          	jalr	-712(ra) # 80000b54 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005e24:	100017b7          	lui	a5,0x10001
    80005e28:	4398                	lw	a4,0(a5)
    80005e2a:	2701                	sext.w	a4,a4
    80005e2c:	747277b7          	lui	a5,0x74727
    80005e30:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005e34:	0ef71163          	bne	a4,a5,80005f16 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005e38:	100017b7          	lui	a5,0x10001
    80005e3c:	43dc                	lw	a5,4(a5)
    80005e3e:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005e40:	4705                	li	a4,1
    80005e42:	0ce79a63          	bne	a5,a4,80005f16 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005e46:	100017b7          	lui	a5,0x10001
    80005e4a:	479c                	lw	a5,8(a5)
    80005e4c:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005e4e:	4709                	li	a4,2
    80005e50:	0ce79363          	bne	a5,a4,80005f16 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005e54:	100017b7          	lui	a5,0x10001
    80005e58:	47d8                	lw	a4,12(a5)
    80005e5a:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005e5c:	554d47b7          	lui	a5,0x554d4
    80005e60:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005e64:	0af71963          	bne	a4,a5,80005f16 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005e68:	100017b7          	lui	a5,0x10001
    80005e6c:	4705                	li	a4,1
    80005e6e:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005e70:	470d                	li	a4,3
    80005e72:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80005e74:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80005e76:	c7ffe737          	lui	a4,0xc7ffe
    80005e7a:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd875f>
    80005e7e:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80005e80:	2701                	sext.w	a4,a4
    80005e82:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005e84:	472d                	li	a4,11
    80005e86:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005e88:	473d                	li	a4,15
    80005e8a:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    80005e8c:	6705                	lui	a4,0x1
    80005e8e:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80005e90:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80005e94:	5bdc                	lw	a5,52(a5)
    80005e96:	2781                	sext.w	a5,a5
  if(max == 0)
    80005e98:	c7d9                	beqz	a5,80005f26 <virtio_disk_init+0x124>
  if(max < NUM)
    80005e9a:	471d                	li	a4,7
    80005e9c:	08f77d63          	bgeu	a4,a5,80005f36 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80005ea0:	100014b7          	lui	s1,0x10001
    80005ea4:	47a1                	li	a5,8
    80005ea6:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80005ea8:	6609                	lui	a2,0x2
    80005eaa:	4581                	li	a1,0
    80005eac:	0001d517          	auipc	a0,0x1d
    80005eb0:	15450513          	addi	a0,a0,340 # 80023000 <disk>
    80005eb4:	ffffb097          	auipc	ra,0xffffb
    80005eb8:	e2c080e7          	jalr	-468(ra) # 80000ce0 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    80005ebc:	0001d717          	auipc	a4,0x1d
    80005ec0:	14470713          	addi	a4,a4,324 # 80023000 <disk>
    80005ec4:	00c75793          	srli	a5,a4,0xc
    80005ec8:	2781                	sext.w	a5,a5
    80005eca:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    80005ecc:	0001f797          	auipc	a5,0x1f
    80005ed0:	13478793          	addi	a5,a5,308 # 80025000 <disk+0x2000>
    80005ed4:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    80005ed6:	0001d717          	auipc	a4,0x1d
    80005eda:	1aa70713          	addi	a4,a4,426 # 80023080 <disk+0x80>
    80005ede:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    80005ee0:	0001e717          	auipc	a4,0x1e
    80005ee4:	12070713          	addi	a4,a4,288 # 80024000 <disk+0x1000>
    80005ee8:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    80005eea:	4705                	li	a4,1
    80005eec:	00e78c23          	sb	a4,24(a5)
    80005ef0:	00e78ca3          	sb	a4,25(a5)
    80005ef4:	00e78d23          	sb	a4,26(a5)
    80005ef8:	00e78da3          	sb	a4,27(a5)
    80005efc:	00e78e23          	sb	a4,28(a5)
    80005f00:	00e78ea3          	sb	a4,29(a5)
    80005f04:	00e78f23          	sb	a4,30(a5)
    80005f08:	00e78fa3          	sb	a4,31(a5)
}
    80005f0c:	60e2                	ld	ra,24(sp)
    80005f0e:	6442                	ld	s0,16(sp)
    80005f10:	64a2                	ld	s1,8(sp)
    80005f12:	6105                	addi	sp,sp,32
    80005f14:	8082                	ret
    panic("could not find virtio disk");
    80005f16:	00003517          	auipc	a0,0x3
    80005f1a:	8aa50513          	addi	a0,a0,-1878 # 800087c0 <syscalls+0x360>
    80005f1e:	ffffa097          	auipc	ra,0xffffa
    80005f22:	620080e7          	jalr	1568(ra) # 8000053e <panic>
    panic("virtio disk has no queue 0");
    80005f26:	00003517          	auipc	a0,0x3
    80005f2a:	8ba50513          	addi	a0,a0,-1862 # 800087e0 <syscalls+0x380>
    80005f2e:	ffffa097          	auipc	ra,0xffffa
    80005f32:	610080e7          	jalr	1552(ra) # 8000053e <panic>
    panic("virtio disk max queue too short");
    80005f36:	00003517          	auipc	a0,0x3
    80005f3a:	8ca50513          	addi	a0,a0,-1846 # 80008800 <syscalls+0x3a0>
    80005f3e:	ffffa097          	auipc	ra,0xffffa
    80005f42:	600080e7          	jalr	1536(ra) # 8000053e <panic>

0000000080005f46 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80005f46:	7159                	addi	sp,sp,-112
    80005f48:	f486                	sd	ra,104(sp)
    80005f4a:	f0a2                	sd	s0,96(sp)
    80005f4c:	eca6                	sd	s1,88(sp)
    80005f4e:	e8ca                	sd	s2,80(sp)
    80005f50:	e4ce                	sd	s3,72(sp)
    80005f52:	e0d2                	sd	s4,64(sp)
    80005f54:	fc56                	sd	s5,56(sp)
    80005f56:	f85a                	sd	s6,48(sp)
    80005f58:	f45e                	sd	s7,40(sp)
    80005f5a:	f062                	sd	s8,32(sp)
    80005f5c:	ec66                	sd	s9,24(sp)
    80005f5e:	e86a                	sd	s10,16(sp)
    80005f60:	1880                	addi	s0,sp,112
    80005f62:	892a                	mv	s2,a0
    80005f64:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80005f66:	00c52c83          	lw	s9,12(a0)
    80005f6a:	001c9c9b          	slliw	s9,s9,0x1
    80005f6e:	1c82                	slli	s9,s9,0x20
    80005f70:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80005f74:	0001f517          	auipc	a0,0x1f
    80005f78:	1b450513          	addi	a0,a0,436 # 80025128 <disk+0x2128>
    80005f7c:	ffffb097          	auipc	ra,0xffffb
    80005f80:	c68080e7          	jalr	-920(ra) # 80000be4 <acquire>
  for(int i = 0; i < 3; i++){
    80005f84:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80005f86:	4c21                	li	s8,8
      disk.free[i] = 0;
    80005f88:	0001db97          	auipc	s7,0x1d
    80005f8c:	078b8b93          	addi	s7,s7,120 # 80023000 <disk>
    80005f90:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    80005f92:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    80005f94:	8a4e                	mv	s4,s3
    80005f96:	a051                	j	8000601a <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    80005f98:	00fb86b3          	add	a3,s7,a5
    80005f9c:	96da                	add	a3,a3,s6
    80005f9e:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    80005fa2:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    80005fa4:	0207c563          	bltz	a5,80005fce <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80005fa8:	2485                	addiw	s1,s1,1
    80005faa:	0711                	addi	a4,a4,4
    80005fac:	25548063          	beq	s1,s5,800061ec <virtio_disk_rw+0x2a6>
    idx[i] = alloc_desc();
    80005fb0:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    80005fb2:	0001f697          	auipc	a3,0x1f
    80005fb6:	06668693          	addi	a3,a3,102 # 80025018 <disk+0x2018>
    80005fba:	87d2                	mv	a5,s4
    if(disk.free[i]){
    80005fbc:	0006c583          	lbu	a1,0(a3)
    80005fc0:	fde1                	bnez	a1,80005f98 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80005fc2:	2785                	addiw	a5,a5,1
    80005fc4:	0685                	addi	a3,a3,1
    80005fc6:	ff879be3          	bne	a5,s8,80005fbc <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    80005fca:	57fd                	li	a5,-1
    80005fcc:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    80005fce:	02905a63          	blez	s1,80006002 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80005fd2:	f9042503          	lw	a0,-112(s0)
    80005fd6:	00000097          	auipc	ra,0x0
    80005fda:	d90080e7          	jalr	-624(ra) # 80005d66 <free_desc>
      for(int j = 0; j < i; j++)
    80005fde:	4785                	li	a5,1
    80005fe0:	0297d163          	bge	a5,s1,80006002 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80005fe4:	f9442503          	lw	a0,-108(s0)
    80005fe8:	00000097          	auipc	ra,0x0
    80005fec:	d7e080e7          	jalr	-642(ra) # 80005d66 <free_desc>
      for(int j = 0; j < i; j++)
    80005ff0:	4789                	li	a5,2
    80005ff2:	0097d863          	bge	a5,s1,80006002 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80005ff6:	f9842503          	lw	a0,-104(s0)
    80005ffa:	00000097          	auipc	ra,0x0
    80005ffe:	d6c080e7          	jalr	-660(ra) # 80005d66 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006002:	0001f597          	auipc	a1,0x1f
    80006006:	12658593          	addi	a1,a1,294 # 80025128 <disk+0x2128>
    8000600a:	0001f517          	auipc	a0,0x1f
    8000600e:	00e50513          	addi	a0,a0,14 # 80025018 <disk+0x2018>
    80006012:	ffffc097          	auipc	ra,0xffffc
    80006016:	152080e7          	jalr	338(ra) # 80002164 <sleep>
  for(int i = 0; i < 3; i++){
    8000601a:	f9040713          	addi	a4,s0,-112
    8000601e:	84ce                	mv	s1,s3
    80006020:	bf41                	j	80005fb0 <virtio_disk_rw+0x6a>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    80006022:	20058713          	addi	a4,a1,512
    80006026:	00471693          	slli	a3,a4,0x4
    8000602a:	0001d717          	auipc	a4,0x1d
    8000602e:	fd670713          	addi	a4,a4,-42 # 80023000 <disk>
    80006032:	9736                	add	a4,a4,a3
    80006034:	4685                	li	a3,1
    80006036:	0ad72423          	sw	a3,168(a4)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    8000603a:	20058713          	addi	a4,a1,512
    8000603e:	00471693          	slli	a3,a4,0x4
    80006042:	0001d717          	auipc	a4,0x1d
    80006046:	fbe70713          	addi	a4,a4,-66 # 80023000 <disk>
    8000604a:	9736                	add	a4,a4,a3
    8000604c:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    80006050:	0b973823          	sd	s9,176(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80006054:	7679                	lui	a2,0xffffe
    80006056:	963e                	add	a2,a2,a5
    80006058:	0001f697          	auipc	a3,0x1f
    8000605c:	fa868693          	addi	a3,a3,-88 # 80025000 <disk+0x2000>
    80006060:	6298                	ld	a4,0(a3)
    80006062:	9732                	add	a4,a4,a2
    80006064:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006066:	6298                	ld	a4,0(a3)
    80006068:	9732                	add	a4,a4,a2
    8000606a:	4541                	li	a0,16
    8000606c:	c708                	sw	a0,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    8000606e:	6298                	ld	a4,0(a3)
    80006070:	9732                	add	a4,a4,a2
    80006072:	4505                	li	a0,1
    80006074:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[0]].next = idx[1];
    80006078:	f9442703          	lw	a4,-108(s0)
    8000607c:	6288                	ld	a0,0(a3)
    8000607e:	962a                	add	a2,a2,a0
    80006080:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd800e>

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006084:	0712                	slli	a4,a4,0x4
    80006086:	6290                	ld	a2,0(a3)
    80006088:	963a                	add	a2,a2,a4
    8000608a:	05890513          	addi	a0,s2,88
    8000608e:	e208                	sd	a0,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    80006090:	6294                	ld	a3,0(a3)
    80006092:	96ba                	add	a3,a3,a4
    80006094:	40000613          	li	a2,1024
    80006098:	c690                	sw	a2,8(a3)
  if(write)
    8000609a:	140d0063          	beqz	s10,800061da <virtio_disk_rw+0x294>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    8000609e:	0001f697          	auipc	a3,0x1f
    800060a2:	f626b683          	ld	a3,-158(a3) # 80025000 <disk+0x2000>
    800060a6:	96ba                	add	a3,a3,a4
    800060a8:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    800060ac:	0001d817          	auipc	a6,0x1d
    800060b0:	f5480813          	addi	a6,a6,-172 # 80023000 <disk>
    800060b4:	0001f517          	auipc	a0,0x1f
    800060b8:	f4c50513          	addi	a0,a0,-180 # 80025000 <disk+0x2000>
    800060bc:	6114                	ld	a3,0(a0)
    800060be:	96ba                	add	a3,a3,a4
    800060c0:	00c6d603          	lhu	a2,12(a3)
    800060c4:	00166613          	ori	a2,a2,1
    800060c8:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    800060cc:	f9842683          	lw	a3,-104(s0)
    800060d0:	6110                	ld	a2,0(a0)
    800060d2:	9732                	add	a4,a4,a2
    800060d4:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    800060d8:	20058613          	addi	a2,a1,512
    800060dc:	0612                	slli	a2,a2,0x4
    800060de:	9642                	add	a2,a2,a6
    800060e0:	577d                	li	a4,-1
    800060e2:	02e60823          	sb	a4,48(a2)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    800060e6:	00469713          	slli	a4,a3,0x4
    800060ea:	6114                	ld	a3,0(a0)
    800060ec:	96ba                	add	a3,a3,a4
    800060ee:	03078793          	addi	a5,a5,48
    800060f2:	97c2                	add	a5,a5,a6
    800060f4:	e29c                	sd	a5,0(a3)
  disk.desc[idx[2]].len = 1;
    800060f6:	611c                	ld	a5,0(a0)
    800060f8:	97ba                	add	a5,a5,a4
    800060fa:	4685                	li	a3,1
    800060fc:	c794                	sw	a3,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    800060fe:	611c                	ld	a5,0(a0)
    80006100:	97ba                	add	a5,a5,a4
    80006102:	4809                	li	a6,2
    80006104:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    80006108:	611c                	ld	a5,0(a0)
    8000610a:	973e                	add	a4,a4,a5
    8000610c:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006110:	00d92223          	sw	a3,4(s2)
  disk.info[idx[0]].b = b;
    80006114:	03263423          	sd	s2,40(a2)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006118:	6518                	ld	a4,8(a0)
    8000611a:	00275783          	lhu	a5,2(a4)
    8000611e:	8b9d                	andi	a5,a5,7
    80006120:	0786                	slli	a5,a5,0x1
    80006122:	97ba                	add	a5,a5,a4
    80006124:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    80006128:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    8000612c:	6518                	ld	a4,8(a0)
    8000612e:	00275783          	lhu	a5,2(a4)
    80006132:	2785                	addiw	a5,a5,1
    80006134:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006138:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    8000613c:	100017b7          	lui	a5,0x10001
    80006140:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006144:	00492703          	lw	a4,4(s2)
    80006148:	4785                	li	a5,1
    8000614a:	02f71163          	bne	a4,a5,8000616c <virtio_disk_rw+0x226>
    sleep(b, &disk.vdisk_lock);
    8000614e:	0001f997          	auipc	s3,0x1f
    80006152:	fda98993          	addi	s3,s3,-38 # 80025128 <disk+0x2128>
  while(b->disk == 1) {
    80006156:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006158:	85ce                	mv	a1,s3
    8000615a:	854a                	mv	a0,s2
    8000615c:	ffffc097          	auipc	ra,0xffffc
    80006160:	008080e7          	jalr	8(ra) # 80002164 <sleep>
  while(b->disk == 1) {
    80006164:	00492783          	lw	a5,4(s2)
    80006168:	fe9788e3          	beq	a5,s1,80006158 <virtio_disk_rw+0x212>
  }

  disk.info[idx[0]].b = 0;
    8000616c:	f9042903          	lw	s2,-112(s0)
    80006170:	20090793          	addi	a5,s2,512
    80006174:	00479713          	slli	a4,a5,0x4
    80006178:	0001d797          	auipc	a5,0x1d
    8000617c:	e8878793          	addi	a5,a5,-376 # 80023000 <disk>
    80006180:	97ba                	add	a5,a5,a4
    80006182:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    80006186:	0001f997          	auipc	s3,0x1f
    8000618a:	e7a98993          	addi	s3,s3,-390 # 80025000 <disk+0x2000>
    8000618e:	00491713          	slli	a4,s2,0x4
    80006192:	0009b783          	ld	a5,0(s3)
    80006196:	97ba                	add	a5,a5,a4
    80006198:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    8000619c:	854a                	mv	a0,s2
    8000619e:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    800061a2:	00000097          	auipc	ra,0x0
    800061a6:	bc4080e7          	jalr	-1084(ra) # 80005d66 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    800061aa:	8885                	andi	s1,s1,1
    800061ac:	f0ed                	bnez	s1,8000618e <virtio_disk_rw+0x248>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    800061ae:	0001f517          	auipc	a0,0x1f
    800061b2:	f7a50513          	addi	a0,a0,-134 # 80025128 <disk+0x2128>
    800061b6:	ffffb097          	auipc	ra,0xffffb
    800061ba:	ae2080e7          	jalr	-1310(ra) # 80000c98 <release>
}
    800061be:	70a6                	ld	ra,104(sp)
    800061c0:	7406                	ld	s0,96(sp)
    800061c2:	64e6                	ld	s1,88(sp)
    800061c4:	6946                	ld	s2,80(sp)
    800061c6:	69a6                	ld	s3,72(sp)
    800061c8:	6a06                	ld	s4,64(sp)
    800061ca:	7ae2                	ld	s5,56(sp)
    800061cc:	7b42                	ld	s6,48(sp)
    800061ce:	7ba2                	ld	s7,40(sp)
    800061d0:	7c02                	ld	s8,32(sp)
    800061d2:	6ce2                	ld	s9,24(sp)
    800061d4:	6d42                	ld	s10,16(sp)
    800061d6:	6165                	addi	sp,sp,112
    800061d8:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    800061da:	0001f697          	auipc	a3,0x1f
    800061de:	e266b683          	ld	a3,-474(a3) # 80025000 <disk+0x2000>
    800061e2:	96ba                	add	a3,a3,a4
    800061e4:	4609                	li	a2,2
    800061e6:	00c69623          	sh	a2,12(a3)
    800061ea:	b5c9                	j	800060ac <virtio_disk_rw+0x166>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800061ec:	f9042583          	lw	a1,-112(s0)
    800061f0:	20058793          	addi	a5,a1,512
    800061f4:	0792                	slli	a5,a5,0x4
    800061f6:	0001d517          	auipc	a0,0x1d
    800061fa:	eb250513          	addi	a0,a0,-334 # 800230a8 <disk+0xa8>
    800061fe:	953e                	add	a0,a0,a5
  if(write)
    80006200:	e20d11e3          	bnez	s10,80006022 <virtio_disk_rw+0xdc>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    80006204:	20058713          	addi	a4,a1,512
    80006208:	00471693          	slli	a3,a4,0x4
    8000620c:	0001d717          	auipc	a4,0x1d
    80006210:	df470713          	addi	a4,a4,-524 # 80023000 <disk>
    80006214:	9736                	add	a4,a4,a3
    80006216:	0a072423          	sw	zero,168(a4)
    8000621a:	b505                	j	8000603a <virtio_disk_rw+0xf4>

000000008000621c <virtio_disk_intr>:

void
virtio_disk_intr()
{
    8000621c:	1101                	addi	sp,sp,-32
    8000621e:	ec06                	sd	ra,24(sp)
    80006220:	e822                	sd	s0,16(sp)
    80006222:	e426                	sd	s1,8(sp)
    80006224:	e04a                	sd	s2,0(sp)
    80006226:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006228:	0001f517          	auipc	a0,0x1f
    8000622c:	f0050513          	addi	a0,a0,-256 # 80025128 <disk+0x2128>
    80006230:	ffffb097          	auipc	ra,0xffffb
    80006234:	9b4080e7          	jalr	-1612(ra) # 80000be4 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006238:	10001737          	lui	a4,0x10001
    8000623c:	533c                	lw	a5,96(a4)
    8000623e:	8b8d                	andi	a5,a5,3
    80006240:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006242:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006246:	0001f797          	auipc	a5,0x1f
    8000624a:	dba78793          	addi	a5,a5,-582 # 80025000 <disk+0x2000>
    8000624e:	6b94                	ld	a3,16(a5)
    80006250:	0207d703          	lhu	a4,32(a5)
    80006254:	0026d783          	lhu	a5,2(a3)
    80006258:	06f70163          	beq	a4,a5,800062ba <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    8000625c:	0001d917          	auipc	s2,0x1d
    80006260:	da490913          	addi	s2,s2,-604 # 80023000 <disk>
    80006264:	0001f497          	auipc	s1,0x1f
    80006268:	d9c48493          	addi	s1,s1,-612 # 80025000 <disk+0x2000>
    __sync_synchronize();
    8000626c:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006270:	6898                	ld	a4,16(s1)
    80006272:	0204d783          	lhu	a5,32(s1)
    80006276:	8b9d                	andi	a5,a5,7
    80006278:	078e                	slli	a5,a5,0x3
    8000627a:	97ba                	add	a5,a5,a4
    8000627c:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    8000627e:	20078713          	addi	a4,a5,512
    80006282:	0712                	slli	a4,a4,0x4
    80006284:	974a                	add	a4,a4,s2
    80006286:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    8000628a:	e731                	bnez	a4,800062d6 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    8000628c:	20078793          	addi	a5,a5,512
    80006290:	0792                	slli	a5,a5,0x4
    80006292:	97ca                	add	a5,a5,s2
    80006294:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    80006296:	00052223          	sw	zero,4(a0)
    wakeup(b);
    8000629a:	ffffc097          	auipc	ra,0xffffc
    8000629e:	056080e7          	jalr	86(ra) # 800022f0 <wakeup>

    disk.used_idx += 1;
    800062a2:	0204d783          	lhu	a5,32(s1)
    800062a6:	2785                	addiw	a5,a5,1
    800062a8:	17c2                	slli	a5,a5,0x30
    800062aa:	93c1                	srli	a5,a5,0x30
    800062ac:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    800062b0:	6898                	ld	a4,16(s1)
    800062b2:	00275703          	lhu	a4,2(a4)
    800062b6:	faf71be3          	bne	a4,a5,8000626c <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    800062ba:	0001f517          	auipc	a0,0x1f
    800062be:	e6e50513          	addi	a0,a0,-402 # 80025128 <disk+0x2128>
    800062c2:	ffffb097          	auipc	ra,0xffffb
    800062c6:	9d6080e7          	jalr	-1578(ra) # 80000c98 <release>
}
    800062ca:	60e2                	ld	ra,24(sp)
    800062cc:	6442                	ld	s0,16(sp)
    800062ce:	64a2                	ld	s1,8(sp)
    800062d0:	6902                	ld	s2,0(sp)
    800062d2:	6105                	addi	sp,sp,32
    800062d4:	8082                	ret
      panic("virtio_disk_intr status");
    800062d6:	00002517          	auipc	a0,0x2
    800062da:	54a50513          	addi	a0,a0,1354 # 80008820 <syscalls+0x3c0>
    800062de:	ffffa097          	auipc	ra,0xffffa
    800062e2:	260080e7          	jalr	608(ra) # 8000053e <panic>

00000000800062e6 <cas>:
    800062e6:	100522af          	lr.w	t0,(a0)
    800062ea:	00b29563          	bne	t0,a1,800062f4 <fail>
    800062ee:	18c5252f          	sc.w	a0,a2,(a0)
    800062f2:	8082                	ret

00000000800062f4 <fail>:
    800062f4:	4505                	li	a0,1
    800062f6:	8082                	ret
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

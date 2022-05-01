
user/_castest:     file format elf64-littleriscv


Disassembly of section .text:

0000000000000000 <castest>:
#include "kernel/fs.h"


int castest(int size){
    int i;
    for(i=0; i<size; i++){
   0:	04a05463          	blez	a0,48 <castest+0x48>
int castest(int size){
   4:	7179                	addi	sp,sp,-48
   6:	f406                	sd	ra,40(sp)
   8:	f022                	sd	s0,32(sp)
   a:	ec26                	sd	s1,24(sp)
   c:	e84a                	sd	s2,16(sp)
   e:	e44e                	sd	s3,8(sp)
  10:	1800                	addi	s0,sp,48
  12:	892a                	mv	s2,a0
    for(i=0; i<size; i++){
  14:	4481                	li	s1,0
        printf("%d\n",fork());
  16:	00000997          	auipc	s3,0x0
  1a:	7e298993          	addi	s3,s3,2018 # 7f8 <malloc+0xe4>
  1e:	00000097          	auipc	ra,0x0
  22:	2b8080e7          	jalr	696(ra) # 2d6 <fork>
  26:	85aa                	mv	a1,a0
  28:	854e                	mv	a0,s3
  2a:	00000097          	auipc	ra,0x0
  2e:	62c080e7          	jalr	1580(ra) # 656 <printf>
    for(i=0; i<size; i++){
  32:	2485                	addiw	s1,s1,1
  34:	fe9915e3          	bne	s2,s1,1e <castest+0x1e>
    }
    return 0;
}
  38:	4501                	li	a0,0
  3a:	70a2                	ld	ra,40(sp)
  3c:	7402                	ld	s0,32(sp)
  3e:	64e2                	ld	s1,24(sp)
  40:	6942                	ld	s2,16(sp)
  42:	69a2                	ld	s3,8(sp)
  44:	6145                	addi	sp,sp,48
  46:	8082                	ret
  48:	4501                	li	a0,0
  4a:	8082                	ret

000000000000004c <main>:


int main (int argc, char *argv[]){
  4c:	1141                	addi	sp,sp,-16
  4e:	e406                	sd	ra,8(sp)
  50:	e022                	sd	s0,0(sp)
  52:	0800                	addi	s0,sp,16
    castest(5);
  54:	4515                	li	a0,5
  56:	00000097          	auipc	ra,0x0
  5a:	faa080e7          	jalr	-86(ra) # 0 <castest>
    return 0;
}
  5e:	4501                	li	a0,0
  60:	60a2                	ld	ra,8(sp)
  62:	6402                	ld	s0,0(sp)
  64:	0141                	addi	sp,sp,16
  66:	8082                	ret

0000000000000068 <strcpy>:
#include "kernel/fcntl.h"
#include "user/user.h"

char*
strcpy(char *s, const char *t)
{
  68:	1141                	addi	sp,sp,-16
  6a:	e422                	sd	s0,8(sp)
  6c:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
  6e:	87aa                	mv	a5,a0
  70:	0585                	addi	a1,a1,1
  72:	0785                	addi	a5,a5,1
  74:	fff5c703          	lbu	a4,-1(a1)
  78:	fee78fa3          	sb	a4,-1(a5)
  7c:	fb75                	bnez	a4,70 <strcpy+0x8>
    ;
  return os;
}
  7e:	6422                	ld	s0,8(sp)
  80:	0141                	addi	sp,sp,16
  82:	8082                	ret

0000000000000084 <strcmp>:

int
strcmp(const char *p, const char *q)
{
  84:	1141                	addi	sp,sp,-16
  86:	e422                	sd	s0,8(sp)
  88:	0800                	addi	s0,sp,16
  while(*p && *p == *q)
  8a:	00054783          	lbu	a5,0(a0)
  8e:	cb91                	beqz	a5,a2 <strcmp+0x1e>
  90:	0005c703          	lbu	a4,0(a1)
  94:	00f71763          	bne	a4,a5,a2 <strcmp+0x1e>
    p++, q++;
  98:	0505                	addi	a0,a0,1
  9a:	0585                	addi	a1,a1,1
  while(*p && *p == *q)
  9c:	00054783          	lbu	a5,0(a0)
  a0:	fbe5                	bnez	a5,90 <strcmp+0xc>
  return (uchar)*p - (uchar)*q;
  a2:	0005c503          	lbu	a0,0(a1)
}
  a6:	40a7853b          	subw	a0,a5,a0
  aa:	6422                	ld	s0,8(sp)
  ac:	0141                	addi	sp,sp,16
  ae:	8082                	ret

00000000000000b0 <strlen>:

uint
strlen(const char *s)
{
  b0:	1141                	addi	sp,sp,-16
  b2:	e422                	sd	s0,8(sp)
  b4:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
  b6:	00054783          	lbu	a5,0(a0)
  ba:	cf91                	beqz	a5,d6 <strlen+0x26>
  bc:	0505                	addi	a0,a0,1
  be:	87aa                	mv	a5,a0
  c0:	4685                	li	a3,1
  c2:	9e89                	subw	a3,a3,a0
  c4:	00f6853b          	addw	a0,a3,a5
  c8:	0785                	addi	a5,a5,1
  ca:	fff7c703          	lbu	a4,-1(a5)
  ce:	fb7d                	bnez	a4,c4 <strlen+0x14>
    ;
  return n;
}
  d0:	6422                	ld	s0,8(sp)
  d2:	0141                	addi	sp,sp,16
  d4:	8082                	ret
  for(n = 0; s[n]; n++)
  d6:	4501                	li	a0,0
  d8:	bfe5                	j	d0 <strlen+0x20>

00000000000000da <memset>:

void*
memset(void *dst, int c, uint n)
{
  da:	1141                	addi	sp,sp,-16
  dc:	e422                	sd	s0,8(sp)
  de:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
  e0:	ce09                	beqz	a2,fa <memset+0x20>
  e2:	87aa                	mv	a5,a0
  e4:	fff6071b          	addiw	a4,a2,-1
  e8:	1702                	slli	a4,a4,0x20
  ea:	9301                	srli	a4,a4,0x20
  ec:	0705                	addi	a4,a4,1
  ee:	972a                	add	a4,a4,a0
    cdst[i] = c;
  f0:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
  f4:	0785                	addi	a5,a5,1
  f6:	fee79de3          	bne	a5,a4,f0 <memset+0x16>
  }
  return dst;
}
  fa:	6422                	ld	s0,8(sp)
  fc:	0141                	addi	sp,sp,16
  fe:	8082                	ret

0000000000000100 <strchr>:

char*
strchr(const char *s, char c)
{
 100:	1141                	addi	sp,sp,-16
 102:	e422                	sd	s0,8(sp)
 104:	0800                	addi	s0,sp,16
  for(; *s; s++)
 106:	00054783          	lbu	a5,0(a0)
 10a:	cb99                	beqz	a5,120 <strchr+0x20>
    if(*s == c)
 10c:	00f58763          	beq	a1,a5,11a <strchr+0x1a>
  for(; *s; s++)
 110:	0505                	addi	a0,a0,1
 112:	00054783          	lbu	a5,0(a0)
 116:	fbfd                	bnez	a5,10c <strchr+0xc>
      return (char*)s;
  return 0;
 118:	4501                	li	a0,0
}
 11a:	6422                	ld	s0,8(sp)
 11c:	0141                	addi	sp,sp,16
 11e:	8082                	ret
  return 0;
 120:	4501                	li	a0,0
 122:	bfe5                	j	11a <strchr+0x1a>

0000000000000124 <gets>:

char*
gets(char *buf, int max)
{
 124:	711d                	addi	sp,sp,-96
 126:	ec86                	sd	ra,88(sp)
 128:	e8a2                	sd	s0,80(sp)
 12a:	e4a6                	sd	s1,72(sp)
 12c:	e0ca                	sd	s2,64(sp)
 12e:	fc4e                	sd	s3,56(sp)
 130:	f852                	sd	s4,48(sp)
 132:	f456                	sd	s5,40(sp)
 134:	f05a                	sd	s6,32(sp)
 136:	ec5e                	sd	s7,24(sp)
 138:	1080                	addi	s0,sp,96
 13a:	8baa                	mv	s7,a0
 13c:	8a2e                	mv	s4,a1
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 13e:	892a                	mv	s2,a0
 140:	4481                	li	s1,0
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
 142:	4aa9                	li	s5,10
 144:	4b35                	li	s6,13
  for(i=0; i+1 < max; ){
 146:	89a6                	mv	s3,s1
 148:	2485                	addiw	s1,s1,1
 14a:	0344d863          	bge	s1,s4,17a <gets+0x56>
    cc = read(0, &c, 1);
 14e:	4605                	li	a2,1
 150:	faf40593          	addi	a1,s0,-81
 154:	4501                	li	a0,0
 156:	00000097          	auipc	ra,0x0
 15a:	1a0080e7          	jalr	416(ra) # 2f6 <read>
    if(cc < 1)
 15e:	00a05e63          	blez	a0,17a <gets+0x56>
    buf[i++] = c;
 162:	faf44783          	lbu	a5,-81(s0)
 166:	00f90023          	sb	a5,0(s2)
    if(c == '\n' || c == '\r')
 16a:	01578763          	beq	a5,s5,178 <gets+0x54>
 16e:	0905                	addi	s2,s2,1
 170:	fd679be3          	bne	a5,s6,146 <gets+0x22>
  for(i=0; i+1 < max; ){
 174:	89a6                	mv	s3,s1
 176:	a011                	j	17a <gets+0x56>
 178:	89a6                	mv	s3,s1
      break;
  }
  buf[i] = '\0';
 17a:	99de                	add	s3,s3,s7
 17c:	00098023          	sb	zero,0(s3)
  return buf;
}
 180:	855e                	mv	a0,s7
 182:	60e6                	ld	ra,88(sp)
 184:	6446                	ld	s0,80(sp)
 186:	64a6                	ld	s1,72(sp)
 188:	6906                	ld	s2,64(sp)
 18a:	79e2                	ld	s3,56(sp)
 18c:	7a42                	ld	s4,48(sp)
 18e:	7aa2                	ld	s5,40(sp)
 190:	7b02                	ld	s6,32(sp)
 192:	6be2                	ld	s7,24(sp)
 194:	6125                	addi	sp,sp,96
 196:	8082                	ret

0000000000000198 <stat>:

int
stat(const char *n, struct stat *st)
{
 198:	1101                	addi	sp,sp,-32
 19a:	ec06                	sd	ra,24(sp)
 19c:	e822                	sd	s0,16(sp)
 19e:	e426                	sd	s1,8(sp)
 1a0:	e04a                	sd	s2,0(sp)
 1a2:	1000                	addi	s0,sp,32
 1a4:	892e                	mv	s2,a1
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 1a6:	4581                	li	a1,0
 1a8:	00000097          	auipc	ra,0x0
 1ac:	176080e7          	jalr	374(ra) # 31e <open>
  if(fd < 0)
 1b0:	02054563          	bltz	a0,1da <stat+0x42>
 1b4:	84aa                	mv	s1,a0
    return -1;
  r = fstat(fd, st);
 1b6:	85ca                	mv	a1,s2
 1b8:	00000097          	auipc	ra,0x0
 1bc:	17e080e7          	jalr	382(ra) # 336 <fstat>
 1c0:	892a                	mv	s2,a0
  close(fd);
 1c2:	8526                	mv	a0,s1
 1c4:	00000097          	auipc	ra,0x0
 1c8:	142080e7          	jalr	322(ra) # 306 <close>
  return r;
}
 1cc:	854a                	mv	a0,s2
 1ce:	60e2                	ld	ra,24(sp)
 1d0:	6442                	ld	s0,16(sp)
 1d2:	64a2                	ld	s1,8(sp)
 1d4:	6902                	ld	s2,0(sp)
 1d6:	6105                	addi	sp,sp,32
 1d8:	8082                	ret
    return -1;
 1da:	597d                	li	s2,-1
 1dc:	bfc5                	j	1cc <stat+0x34>

00000000000001de <atoi>:

int
atoi(const char *s)
{
 1de:	1141                	addi	sp,sp,-16
 1e0:	e422                	sd	s0,8(sp)
 1e2:	0800                	addi	s0,sp,16
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
 1e4:	00054603          	lbu	a2,0(a0)
 1e8:	fd06079b          	addiw	a5,a2,-48
 1ec:	0ff7f793          	andi	a5,a5,255
 1f0:	4725                	li	a4,9
 1f2:	02f76963          	bltu	a4,a5,224 <atoi+0x46>
 1f6:	86aa                	mv	a3,a0
  n = 0;
 1f8:	4501                	li	a0,0
  while('0' <= *s && *s <= '9')
 1fa:	45a5                	li	a1,9
    n = n*10 + *s++ - '0';
 1fc:	0685                	addi	a3,a3,1
 1fe:	0025179b          	slliw	a5,a0,0x2
 202:	9fa9                	addw	a5,a5,a0
 204:	0017979b          	slliw	a5,a5,0x1
 208:	9fb1                	addw	a5,a5,a2
 20a:	fd07851b          	addiw	a0,a5,-48
  while('0' <= *s && *s <= '9')
 20e:	0006c603          	lbu	a2,0(a3)
 212:	fd06071b          	addiw	a4,a2,-48
 216:	0ff77713          	andi	a4,a4,255
 21a:	fee5f1e3          	bgeu	a1,a4,1fc <atoi+0x1e>
  return n;
}
 21e:	6422                	ld	s0,8(sp)
 220:	0141                	addi	sp,sp,16
 222:	8082                	ret
  n = 0;
 224:	4501                	li	a0,0
 226:	bfe5                	j	21e <atoi+0x40>

0000000000000228 <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
 228:	1141                	addi	sp,sp,-16
 22a:	e422                	sd	s0,8(sp)
 22c:	0800                	addi	s0,sp,16
  char *dst;
  const char *src;

  dst = vdst;
  src = vsrc;
  if (src > dst) {
 22e:	02b57663          	bgeu	a0,a1,25a <memmove+0x32>
    while(n-- > 0)
 232:	02c05163          	blez	a2,254 <memmove+0x2c>
 236:	fff6079b          	addiw	a5,a2,-1
 23a:	1782                	slli	a5,a5,0x20
 23c:	9381                	srli	a5,a5,0x20
 23e:	0785                	addi	a5,a5,1
 240:	97aa                	add	a5,a5,a0
  dst = vdst;
 242:	872a                	mv	a4,a0
      *dst++ = *src++;
 244:	0585                	addi	a1,a1,1
 246:	0705                	addi	a4,a4,1
 248:	fff5c683          	lbu	a3,-1(a1)
 24c:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
 250:	fee79ae3          	bne	a5,a4,244 <memmove+0x1c>
    src += n;
    while(n-- > 0)
      *--dst = *--src;
  }
  return vdst;
}
 254:	6422                	ld	s0,8(sp)
 256:	0141                	addi	sp,sp,16
 258:	8082                	ret
    dst += n;
 25a:	00c50733          	add	a4,a0,a2
    src += n;
 25e:	95b2                	add	a1,a1,a2
    while(n-- > 0)
 260:	fec05ae3          	blez	a2,254 <memmove+0x2c>
 264:	fff6079b          	addiw	a5,a2,-1
 268:	1782                	slli	a5,a5,0x20
 26a:	9381                	srli	a5,a5,0x20
 26c:	fff7c793          	not	a5,a5
 270:	97ba                	add	a5,a5,a4
      *--dst = *--src;
 272:	15fd                	addi	a1,a1,-1
 274:	177d                	addi	a4,a4,-1
 276:	0005c683          	lbu	a3,0(a1)
 27a:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
 27e:	fee79ae3          	bne	a5,a4,272 <memmove+0x4a>
 282:	bfc9                	j	254 <memmove+0x2c>

0000000000000284 <memcmp>:

int
memcmp(const void *s1, const void *s2, uint n)
{
 284:	1141                	addi	sp,sp,-16
 286:	e422                	sd	s0,8(sp)
 288:	0800                	addi	s0,sp,16
  const char *p1 = s1, *p2 = s2;
  while (n-- > 0) {
 28a:	ca05                	beqz	a2,2ba <memcmp+0x36>
 28c:	fff6069b          	addiw	a3,a2,-1
 290:	1682                	slli	a3,a3,0x20
 292:	9281                	srli	a3,a3,0x20
 294:	0685                	addi	a3,a3,1
 296:	96aa                	add	a3,a3,a0
    if (*p1 != *p2) {
 298:	00054783          	lbu	a5,0(a0)
 29c:	0005c703          	lbu	a4,0(a1)
 2a0:	00e79863          	bne	a5,a4,2b0 <memcmp+0x2c>
      return *p1 - *p2;
    }
    p1++;
 2a4:	0505                	addi	a0,a0,1
    p2++;
 2a6:	0585                	addi	a1,a1,1
  while (n-- > 0) {
 2a8:	fed518e3          	bne	a0,a3,298 <memcmp+0x14>
  }
  return 0;
 2ac:	4501                	li	a0,0
 2ae:	a019                	j	2b4 <memcmp+0x30>
      return *p1 - *p2;
 2b0:	40e7853b          	subw	a0,a5,a4
}
 2b4:	6422                	ld	s0,8(sp)
 2b6:	0141                	addi	sp,sp,16
 2b8:	8082                	ret
  return 0;
 2ba:	4501                	li	a0,0
 2bc:	bfe5                	j	2b4 <memcmp+0x30>

00000000000002be <memcpy>:

void *
memcpy(void *dst, const void *src, uint n)
{
 2be:	1141                	addi	sp,sp,-16
 2c0:	e406                	sd	ra,8(sp)
 2c2:	e022                	sd	s0,0(sp)
 2c4:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
 2c6:	00000097          	auipc	ra,0x0
 2ca:	f62080e7          	jalr	-158(ra) # 228 <memmove>
}
 2ce:	60a2                	ld	ra,8(sp)
 2d0:	6402                	ld	s0,0(sp)
 2d2:	0141                	addi	sp,sp,16
 2d4:	8082                	ret

00000000000002d6 <fork>:
# generated by usys.pl - do not edit
#include "kernel/syscall.h"
.global fork
fork:
 li a7, SYS_fork
 2d6:	4885                	li	a7,1
 ecall
 2d8:	00000073          	ecall
 ret
 2dc:	8082                	ret

00000000000002de <exit>:
.global exit
exit:
 li a7, SYS_exit
 2de:	4889                	li	a7,2
 ecall
 2e0:	00000073          	ecall
 ret
 2e4:	8082                	ret

00000000000002e6 <wait>:
.global wait
wait:
 li a7, SYS_wait
 2e6:	488d                	li	a7,3
 ecall
 2e8:	00000073          	ecall
 ret
 2ec:	8082                	ret

00000000000002ee <pipe>:
.global pipe
pipe:
 li a7, SYS_pipe
 2ee:	4891                	li	a7,4
 ecall
 2f0:	00000073          	ecall
 ret
 2f4:	8082                	ret

00000000000002f6 <read>:
.global read
read:
 li a7, SYS_read
 2f6:	4895                	li	a7,5
 ecall
 2f8:	00000073          	ecall
 ret
 2fc:	8082                	ret

00000000000002fe <write>:
.global write
write:
 li a7, SYS_write
 2fe:	48c1                	li	a7,16
 ecall
 300:	00000073          	ecall
 ret
 304:	8082                	ret

0000000000000306 <close>:
.global close
close:
 li a7, SYS_close
 306:	48d5                	li	a7,21
 ecall
 308:	00000073          	ecall
 ret
 30c:	8082                	ret

000000000000030e <kill>:
.global kill
kill:
 li a7, SYS_kill
 30e:	4899                	li	a7,6
 ecall
 310:	00000073          	ecall
 ret
 314:	8082                	ret

0000000000000316 <exec>:
.global exec
exec:
 li a7, SYS_exec
 316:	489d                	li	a7,7
 ecall
 318:	00000073          	ecall
 ret
 31c:	8082                	ret

000000000000031e <open>:
.global open
open:
 li a7, SYS_open
 31e:	48bd                	li	a7,15
 ecall
 320:	00000073          	ecall
 ret
 324:	8082                	ret

0000000000000326 <mknod>:
.global mknod
mknod:
 li a7, SYS_mknod
 326:	48c5                	li	a7,17
 ecall
 328:	00000073          	ecall
 ret
 32c:	8082                	ret

000000000000032e <unlink>:
.global unlink
unlink:
 li a7, SYS_unlink
 32e:	48c9                	li	a7,18
 ecall
 330:	00000073          	ecall
 ret
 334:	8082                	ret

0000000000000336 <fstat>:
.global fstat
fstat:
 li a7, SYS_fstat
 336:	48a1                	li	a7,8
 ecall
 338:	00000073          	ecall
 ret
 33c:	8082                	ret

000000000000033e <link>:
.global link
link:
 li a7, SYS_link
 33e:	48cd                	li	a7,19
 ecall
 340:	00000073          	ecall
 ret
 344:	8082                	ret

0000000000000346 <mkdir>:
.global mkdir
mkdir:
 li a7, SYS_mkdir
 346:	48d1                	li	a7,20
 ecall
 348:	00000073          	ecall
 ret
 34c:	8082                	ret

000000000000034e <chdir>:
.global chdir
chdir:
 li a7, SYS_chdir
 34e:	48a5                	li	a7,9
 ecall
 350:	00000073          	ecall
 ret
 354:	8082                	ret

0000000000000356 <dup>:
.global dup
dup:
 li a7, SYS_dup
 356:	48a9                	li	a7,10
 ecall
 358:	00000073          	ecall
 ret
 35c:	8082                	ret

000000000000035e <getpid>:
.global getpid
getpid:
 li a7, SYS_getpid
 35e:	48ad                	li	a7,11
 ecall
 360:	00000073          	ecall
 ret
 364:	8082                	ret

0000000000000366 <sbrk>:
.global sbrk
sbrk:
 li a7, SYS_sbrk
 366:	48b1                	li	a7,12
 ecall
 368:	00000073          	ecall
 ret
 36c:	8082                	ret

000000000000036e <sleep>:
.global sleep
sleep:
 li a7, SYS_sleep
 36e:	48b5                	li	a7,13
 ecall
 370:	00000073          	ecall
 ret
 374:	8082                	ret

0000000000000376 <uptime>:
.global uptime
uptime:
 li a7, SYS_uptime
 376:	48b9                	li	a7,14
 ecall
 378:	00000073          	ecall
 ret
 37c:	8082                	ret

000000000000037e <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
 37e:	1101                	addi	sp,sp,-32
 380:	ec06                	sd	ra,24(sp)
 382:	e822                	sd	s0,16(sp)
 384:	1000                	addi	s0,sp,32
 386:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
 38a:	4605                	li	a2,1
 38c:	fef40593          	addi	a1,s0,-17
 390:	00000097          	auipc	ra,0x0
 394:	f6e080e7          	jalr	-146(ra) # 2fe <write>
}
 398:	60e2                	ld	ra,24(sp)
 39a:	6442                	ld	s0,16(sp)
 39c:	6105                	addi	sp,sp,32
 39e:	8082                	ret

00000000000003a0 <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 3a0:	7139                	addi	sp,sp,-64
 3a2:	fc06                	sd	ra,56(sp)
 3a4:	f822                	sd	s0,48(sp)
 3a6:	f426                	sd	s1,40(sp)
 3a8:	f04a                	sd	s2,32(sp)
 3aa:	ec4e                	sd	s3,24(sp)
 3ac:	0080                	addi	s0,sp,64
 3ae:	84aa                	mv	s1,a0
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if(sgn && xx < 0){
 3b0:	c299                	beqz	a3,3b6 <printint+0x16>
 3b2:	0805c863          	bltz	a1,442 <printint+0xa2>
    neg = 1;
    x = -xx;
  } else {
    x = xx;
 3b6:	2581                	sext.w	a1,a1
  neg = 0;
 3b8:	4881                	li	a7,0
 3ba:	fc040693          	addi	a3,s0,-64
  }

  i = 0;
 3be:	4701                	li	a4,0
  do{
    buf[i++] = digits[x % base];
 3c0:	2601                	sext.w	a2,a2
 3c2:	00000517          	auipc	a0,0x0
 3c6:	44650513          	addi	a0,a0,1094 # 808 <digits>
 3ca:	883a                	mv	a6,a4
 3cc:	2705                	addiw	a4,a4,1
 3ce:	02c5f7bb          	remuw	a5,a1,a2
 3d2:	1782                	slli	a5,a5,0x20
 3d4:	9381                	srli	a5,a5,0x20
 3d6:	97aa                	add	a5,a5,a0
 3d8:	0007c783          	lbu	a5,0(a5)
 3dc:	00f68023          	sb	a5,0(a3)
  }while((x /= base) != 0);
 3e0:	0005879b          	sext.w	a5,a1
 3e4:	02c5d5bb          	divuw	a1,a1,a2
 3e8:	0685                	addi	a3,a3,1
 3ea:	fec7f0e3          	bgeu	a5,a2,3ca <printint+0x2a>
  if(neg)
 3ee:	00088b63          	beqz	a7,404 <printint+0x64>
    buf[i++] = '-';
 3f2:	fd040793          	addi	a5,s0,-48
 3f6:	973e                	add	a4,a4,a5
 3f8:	02d00793          	li	a5,45
 3fc:	fef70823          	sb	a5,-16(a4)
 400:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
 404:	02e05863          	blez	a4,434 <printint+0x94>
 408:	fc040793          	addi	a5,s0,-64
 40c:	00e78933          	add	s2,a5,a4
 410:	fff78993          	addi	s3,a5,-1
 414:	99ba                	add	s3,s3,a4
 416:	377d                	addiw	a4,a4,-1
 418:	1702                	slli	a4,a4,0x20
 41a:	9301                	srli	a4,a4,0x20
 41c:	40e989b3          	sub	s3,s3,a4
    putc(fd, buf[i]);
 420:	fff94583          	lbu	a1,-1(s2)
 424:	8526                	mv	a0,s1
 426:	00000097          	auipc	ra,0x0
 42a:	f58080e7          	jalr	-168(ra) # 37e <putc>
  while(--i >= 0)
 42e:	197d                	addi	s2,s2,-1
 430:	ff3918e3          	bne	s2,s3,420 <printint+0x80>
}
 434:	70e2                	ld	ra,56(sp)
 436:	7442                	ld	s0,48(sp)
 438:	74a2                	ld	s1,40(sp)
 43a:	7902                	ld	s2,32(sp)
 43c:	69e2                	ld	s3,24(sp)
 43e:	6121                	addi	sp,sp,64
 440:	8082                	ret
    x = -xx;
 442:	40b005bb          	negw	a1,a1
    neg = 1;
 446:	4885                	li	a7,1
    x = -xx;
 448:	bf8d                	j	3ba <printint+0x1a>

000000000000044a <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
 44a:	7119                	addi	sp,sp,-128
 44c:	fc86                	sd	ra,120(sp)
 44e:	f8a2                	sd	s0,112(sp)
 450:	f4a6                	sd	s1,104(sp)
 452:	f0ca                	sd	s2,96(sp)
 454:	ecce                	sd	s3,88(sp)
 456:	e8d2                	sd	s4,80(sp)
 458:	e4d6                	sd	s5,72(sp)
 45a:	e0da                	sd	s6,64(sp)
 45c:	fc5e                	sd	s7,56(sp)
 45e:	f862                	sd	s8,48(sp)
 460:	f466                	sd	s9,40(sp)
 462:	f06a                	sd	s10,32(sp)
 464:	ec6e                	sd	s11,24(sp)
 466:	0100                	addi	s0,sp,128
  char *s;
  int c, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
 468:	0005c903          	lbu	s2,0(a1)
 46c:	18090f63          	beqz	s2,60a <vprintf+0x1c0>
 470:	8aaa                	mv	s5,a0
 472:	8b32                	mv	s6,a2
 474:	00158493          	addi	s1,a1,1
  state = 0;
 478:	4981                	li	s3,0
      if(c == '%'){
        state = '%';
      } else {
        putc(fd, c);
      }
    } else if(state == '%'){
 47a:	02500a13          	li	s4,37
      if(c == 'd'){
 47e:	06400c13          	li	s8,100
        printint(fd, va_arg(ap, int), 10, 1);
      } else if(c == 'l') {
 482:	06c00c93          	li	s9,108
        printint(fd, va_arg(ap, uint64), 10, 0);
      } else if(c == 'x') {
 486:	07800d13          	li	s10,120
        printint(fd, va_arg(ap, int), 16, 0);
      } else if(c == 'p') {
 48a:	07000d93          	li	s11,112
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 48e:	00000b97          	auipc	s7,0x0
 492:	37ab8b93          	addi	s7,s7,890 # 808 <digits>
 496:	a839                	j	4b4 <vprintf+0x6a>
        putc(fd, c);
 498:	85ca                	mv	a1,s2
 49a:	8556                	mv	a0,s5
 49c:	00000097          	auipc	ra,0x0
 4a0:	ee2080e7          	jalr	-286(ra) # 37e <putc>
 4a4:	a019                	j	4aa <vprintf+0x60>
    } else if(state == '%'){
 4a6:	01498f63          	beq	s3,s4,4c4 <vprintf+0x7a>
  for(i = 0; fmt[i]; i++){
 4aa:	0485                	addi	s1,s1,1
 4ac:	fff4c903          	lbu	s2,-1(s1)
 4b0:	14090d63          	beqz	s2,60a <vprintf+0x1c0>
    c = fmt[i] & 0xff;
 4b4:	0009079b          	sext.w	a5,s2
    if(state == 0){
 4b8:	fe0997e3          	bnez	s3,4a6 <vprintf+0x5c>
      if(c == '%'){
 4bc:	fd479ee3          	bne	a5,s4,498 <vprintf+0x4e>
        state = '%';
 4c0:	89be                	mv	s3,a5
 4c2:	b7e5                	j	4aa <vprintf+0x60>
      if(c == 'd'){
 4c4:	05878063          	beq	a5,s8,504 <vprintf+0xba>
      } else if(c == 'l') {
 4c8:	05978c63          	beq	a5,s9,520 <vprintf+0xd6>
      } else if(c == 'x') {
 4cc:	07a78863          	beq	a5,s10,53c <vprintf+0xf2>
      } else if(c == 'p') {
 4d0:	09b78463          	beq	a5,s11,558 <vprintf+0x10e>
        printptr(fd, va_arg(ap, uint64));
      } else if(c == 's'){
 4d4:	07300713          	li	a4,115
 4d8:	0ce78663          	beq	a5,a4,5a4 <vprintf+0x15a>
          s = "(null)";
        while(*s != 0){
          putc(fd, *s);
          s++;
        }
      } else if(c == 'c'){
 4dc:	06300713          	li	a4,99
 4e0:	0ee78e63          	beq	a5,a4,5dc <vprintf+0x192>
        putc(fd, va_arg(ap, uint));
      } else if(c == '%'){
 4e4:	11478863          	beq	a5,s4,5f4 <vprintf+0x1aa>
        putc(fd, c);
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
 4e8:	85d2                	mv	a1,s4
 4ea:	8556                	mv	a0,s5
 4ec:	00000097          	auipc	ra,0x0
 4f0:	e92080e7          	jalr	-366(ra) # 37e <putc>
        putc(fd, c);
 4f4:	85ca                	mv	a1,s2
 4f6:	8556                	mv	a0,s5
 4f8:	00000097          	auipc	ra,0x0
 4fc:	e86080e7          	jalr	-378(ra) # 37e <putc>
      }
      state = 0;
 500:	4981                	li	s3,0
 502:	b765                	j	4aa <vprintf+0x60>
        printint(fd, va_arg(ap, int), 10, 1);
 504:	008b0913          	addi	s2,s6,8
 508:	4685                	li	a3,1
 50a:	4629                	li	a2,10
 50c:	000b2583          	lw	a1,0(s6)
 510:	8556                	mv	a0,s5
 512:	00000097          	auipc	ra,0x0
 516:	e8e080e7          	jalr	-370(ra) # 3a0 <printint>
 51a:	8b4a                	mv	s6,s2
      state = 0;
 51c:	4981                	li	s3,0
 51e:	b771                	j	4aa <vprintf+0x60>
        printint(fd, va_arg(ap, uint64), 10, 0);
 520:	008b0913          	addi	s2,s6,8
 524:	4681                	li	a3,0
 526:	4629                	li	a2,10
 528:	000b2583          	lw	a1,0(s6)
 52c:	8556                	mv	a0,s5
 52e:	00000097          	auipc	ra,0x0
 532:	e72080e7          	jalr	-398(ra) # 3a0 <printint>
 536:	8b4a                	mv	s6,s2
      state = 0;
 538:	4981                	li	s3,0
 53a:	bf85                	j	4aa <vprintf+0x60>
        printint(fd, va_arg(ap, int), 16, 0);
 53c:	008b0913          	addi	s2,s6,8
 540:	4681                	li	a3,0
 542:	4641                	li	a2,16
 544:	000b2583          	lw	a1,0(s6)
 548:	8556                	mv	a0,s5
 54a:	00000097          	auipc	ra,0x0
 54e:	e56080e7          	jalr	-426(ra) # 3a0 <printint>
 552:	8b4a                	mv	s6,s2
      state = 0;
 554:	4981                	li	s3,0
 556:	bf91                	j	4aa <vprintf+0x60>
        printptr(fd, va_arg(ap, uint64));
 558:	008b0793          	addi	a5,s6,8
 55c:	f8f43423          	sd	a5,-120(s0)
 560:	000b3983          	ld	s3,0(s6)
  putc(fd, '0');
 564:	03000593          	li	a1,48
 568:	8556                	mv	a0,s5
 56a:	00000097          	auipc	ra,0x0
 56e:	e14080e7          	jalr	-492(ra) # 37e <putc>
  putc(fd, 'x');
 572:	85ea                	mv	a1,s10
 574:	8556                	mv	a0,s5
 576:	00000097          	auipc	ra,0x0
 57a:	e08080e7          	jalr	-504(ra) # 37e <putc>
 57e:	4941                	li	s2,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 580:	03c9d793          	srli	a5,s3,0x3c
 584:	97de                	add	a5,a5,s7
 586:	0007c583          	lbu	a1,0(a5)
 58a:	8556                	mv	a0,s5
 58c:	00000097          	auipc	ra,0x0
 590:	df2080e7          	jalr	-526(ra) # 37e <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
 594:	0992                	slli	s3,s3,0x4
 596:	397d                	addiw	s2,s2,-1
 598:	fe0914e3          	bnez	s2,580 <vprintf+0x136>
        printptr(fd, va_arg(ap, uint64));
 59c:	f8843b03          	ld	s6,-120(s0)
      state = 0;
 5a0:	4981                	li	s3,0
 5a2:	b721                	j	4aa <vprintf+0x60>
        s = va_arg(ap, char*);
 5a4:	008b0993          	addi	s3,s6,8
 5a8:	000b3903          	ld	s2,0(s6)
        if(s == 0)
 5ac:	02090163          	beqz	s2,5ce <vprintf+0x184>
        while(*s != 0){
 5b0:	00094583          	lbu	a1,0(s2)
 5b4:	c9a1                	beqz	a1,604 <vprintf+0x1ba>
          putc(fd, *s);
 5b6:	8556                	mv	a0,s5
 5b8:	00000097          	auipc	ra,0x0
 5bc:	dc6080e7          	jalr	-570(ra) # 37e <putc>
          s++;
 5c0:	0905                	addi	s2,s2,1
        while(*s != 0){
 5c2:	00094583          	lbu	a1,0(s2)
 5c6:	f9e5                	bnez	a1,5b6 <vprintf+0x16c>
        s = va_arg(ap, char*);
 5c8:	8b4e                	mv	s6,s3
      state = 0;
 5ca:	4981                	li	s3,0
 5cc:	bdf9                	j	4aa <vprintf+0x60>
          s = "(null)";
 5ce:	00000917          	auipc	s2,0x0
 5d2:	23290913          	addi	s2,s2,562 # 800 <malloc+0xec>
        while(*s != 0){
 5d6:	02800593          	li	a1,40
 5da:	bff1                	j	5b6 <vprintf+0x16c>
        putc(fd, va_arg(ap, uint));
 5dc:	008b0913          	addi	s2,s6,8
 5e0:	000b4583          	lbu	a1,0(s6)
 5e4:	8556                	mv	a0,s5
 5e6:	00000097          	auipc	ra,0x0
 5ea:	d98080e7          	jalr	-616(ra) # 37e <putc>
 5ee:	8b4a                	mv	s6,s2
      state = 0;
 5f0:	4981                	li	s3,0
 5f2:	bd65                	j	4aa <vprintf+0x60>
        putc(fd, c);
 5f4:	85d2                	mv	a1,s4
 5f6:	8556                	mv	a0,s5
 5f8:	00000097          	auipc	ra,0x0
 5fc:	d86080e7          	jalr	-634(ra) # 37e <putc>
      state = 0;
 600:	4981                	li	s3,0
 602:	b565                	j	4aa <vprintf+0x60>
        s = va_arg(ap, char*);
 604:	8b4e                	mv	s6,s3
      state = 0;
 606:	4981                	li	s3,0
 608:	b54d                	j	4aa <vprintf+0x60>
    }
  }
}
 60a:	70e6                	ld	ra,120(sp)
 60c:	7446                	ld	s0,112(sp)
 60e:	74a6                	ld	s1,104(sp)
 610:	7906                	ld	s2,96(sp)
 612:	69e6                	ld	s3,88(sp)
 614:	6a46                	ld	s4,80(sp)
 616:	6aa6                	ld	s5,72(sp)
 618:	6b06                	ld	s6,64(sp)
 61a:	7be2                	ld	s7,56(sp)
 61c:	7c42                	ld	s8,48(sp)
 61e:	7ca2                	ld	s9,40(sp)
 620:	7d02                	ld	s10,32(sp)
 622:	6de2                	ld	s11,24(sp)
 624:	6109                	addi	sp,sp,128
 626:	8082                	ret

0000000000000628 <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
 628:	715d                	addi	sp,sp,-80
 62a:	ec06                	sd	ra,24(sp)
 62c:	e822                	sd	s0,16(sp)
 62e:	1000                	addi	s0,sp,32
 630:	e010                	sd	a2,0(s0)
 632:	e414                	sd	a3,8(s0)
 634:	e818                	sd	a4,16(s0)
 636:	ec1c                	sd	a5,24(s0)
 638:	03043023          	sd	a6,32(s0)
 63c:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
 640:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
 644:	8622                	mv	a2,s0
 646:	00000097          	auipc	ra,0x0
 64a:	e04080e7          	jalr	-508(ra) # 44a <vprintf>
}
 64e:	60e2                	ld	ra,24(sp)
 650:	6442                	ld	s0,16(sp)
 652:	6161                	addi	sp,sp,80
 654:	8082                	ret

0000000000000656 <printf>:

void
printf(const char *fmt, ...)
{
 656:	711d                	addi	sp,sp,-96
 658:	ec06                	sd	ra,24(sp)
 65a:	e822                	sd	s0,16(sp)
 65c:	1000                	addi	s0,sp,32
 65e:	e40c                	sd	a1,8(s0)
 660:	e810                	sd	a2,16(s0)
 662:	ec14                	sd	a3,24(s0)
 664:	f018                	sd	a4,32(s0)
 666:	f41c                	sd	a5,40(s0)
 668:	03043823          	sd	a6,48(s0)
 66c:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
 670:	00840613          	addi	a2,s0,8
 674:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
 678:	85aa                	mv	a1,a0
 67a:	4505                	li	a0,1
 67c:	00000097          	auipc	ra,0x0
 680:	dce080e7          	jalr	-562(ra) # 44a <vprintf>
}
 684:	60e2                	ld	ra,24(sp)
 686:	6442                	ld	s0,16(sp)
 688:	6125                	addi	sp,sp,96
 68a:	8082                	ret

000000000000068c <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 68c:	1141                	addi	sp,sp,-16
 68e:	e422                	sd	s0,8(sp)
 690:	0800                	addi	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
 692:	ff050693          	addi	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 696:	00000797          	auipc	a5,0x0
 69a:	18a7b783          	ld	a5,394(a5) # 820 <freep>
 69e:	a805                	j	6ce <free+0x42>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
 6a0:	4618                	lw	a4,8(a2)
 6a2:	9db9                	addw	a1,a1,a4
 6a4:	feb52c23          	sw	a1,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
 6a8:	6398                	ld	a4,0(a5)
 6aa:	6318                	ld	a4,0(a4)
 6ac:	fee53823          	sd	a4,-16(a0)
 6b0:	a091                	j	6f4 <free+0x68>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
 6b2:	ff852703          	lw	a4,-8(a0)
 6b6:	9e39                	addw	a2,a2,a4
 6b8:	c790                	sw	a2,8(a5)
    p->s.ptr = bp->s.ptr;
 6ba:	ff053703          	ld	a4,-16(a0)
 6be:	e398                	sd	a4,0(a5)
 6c0:	a099                	j	706 <free+0x7a>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 6c2:	6398                	ld	a4,0(a5)
 6c4:	00e7e463          	bltu	a5,a4,6cc <free+0x40>
 6c8:	00e6ea63          	bltu	a3,a4,6dc <free+0x50>
{
 6cc:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 6ce:	fed7fae3          	bgeu	a5,a3,6c2 <free+0x36>
 6d2:	6398                	ld	a4,0(a5)
 6d4:	00e6e463          	bltu	a3,a4,6dc <free+0x50>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 6d8:	fee7eae3          	bltu	a5,a4,6cc <free+0x40>
  if(bp + bp->s.size == p->s.ptr){
 6dc:	ff852583          	lw	a1,-8(a0)
 6e0:	6390                	ld	a2,0(a5)
 6e2:	02059713          	slli	a4,a1,0x20
 6e6:	9301                	srli	a4,a4,0x20
 6e8:	0712                	slli	a4,a4,0x4
 6ea:	9736                	add	a4,a4,a3
 6ec:	fae60ae3          	beq	a2,a4,6a0 <free+0x14>
    bp->s.ptr = p->s.ptr;
 6f0:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
 6f4:	4790                	lw	a2,8(a5)
 6f6:	02061713          	slli	a4,a2,0x20
 6fa:	9301                	srli	a4,a4,0x20
 6fc:	0712                	slli	a4,a4,0x4
 6fe:	973e                	add	a4,a4,a5
 700:	fae689e3          	beq	a3,a4,6b2 <free+0x26>
  } else
    p->s.ptr = bp;
 704:	e394                	sd	a3,0(a5)
  freep = p;
 706:	00000717          	auipc	a4,0x0
 70a:	10f73d23          	sd	a5,282(a4) # 820 <freep>
}
 70e:	6422                	ld	s0,8(sp)
 710:	0141                	addi	sp,sp,16
 712:	8082                	ret

0000000000000714 <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
 714:	7139                	addi	sp,sp,-64
 716:	fc06                	sd	ra,56(sp)
 718:	f822                	sd	s0,48(sp)
 71a:	f426                	sd	s1,40(sp)
 71c:	f04a                	sd	s2,32(sp)
 71e:	ec4e                	sd	s3,24(sp)
 720:	e852                	sd	s4,16(sp)
 722:	e456                	sd	s5,8(sp)
 724:	e05a                	sd	s6,0(sp)
 726:	0080                	addi	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 728:	02051493          	slli	s1,a0,0x20
 72c:	9081                	srli	s1,s1,0x20
 72e:	04bd                	addi	s1,s1,15
 730:	8091                	srli	s1,s1,0x4
 732:	0014899b          	addiw	s3,s1,1
 736:	0485                	addi	s1,s1,1
  if((prevp = freep) == 0){
 738:	00000517          	auipc	a0,0x0
 73c:	0e853503          	ld	a0,232(a0) # 820 <freep>
 740:	c515                	beqz	a0,76c <malloc+0x58>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 742:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 744:	4798                	lw	a4,8(a5)
 746:	02977f63          	bgeu	a4,s1,784 <malloc+0x70>
 74a:	8a4e                	mv	s4,s3
 74c:	0009871b          	sext.w	a4,s3
 750:	6685                	lui	a3,0x1
 752:	00d77363          	bgeu	a4,a3,758 <malloc+0x44>
 756:	6a05                	lui	s4,0x1
 758:	000a0b1b          	sext.w	s6,s4
  p = sbrk(nu * sizeof(Header));
 75c:	004a1a1b          	slliw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
 760:	00000917          	auipc	s2,0x0
 764:	0c090913          	addi	s2,s2,192 # 820 <freep>
  if(p == (char*)-1)
 768:	5afd                	li	s5,-1
 76a:	a88d                	j	7dc <malloc+0xc8>
    base.s.ptr = freep = prevp = &base;
 76c:	00000797          	auipc	a5,0x0
 770:	0bc78793          	addi	a5,a5,188 # 828 <base>
 774:	00000717          	auipc	a4,0x0
 778:	0af73623          	sd	a5,172(a4) # 820 <freep>
 77c:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
 77e:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
 782:	b7e1                	j	74a <malloc+0x36>
      if(p->s.size == nunits)
 784:	02e48b63          	beq	s1,a4,7ba <malloc+0xa6>
        p->s.size -= nunits;
 788:	4137073b          	subw	a4,a4,s3
 78c:	c798                	sw	a4,8(a5)
        p += p->s.size;
 78e:	1702                	slli	a4,a4,0x20
 790:	9301                	srli	a4,a4,0x20
 792:	0712                	slli	a4,a4,0x4
 794:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
 796:	0137a423          	sw	s3,8(a5)
      freep = prevp;
 79a:	00000717          	auipc	a4,0x0
 79e:	08a73323          	sd	a0,134(a4) # 820 <freep>
      return (void*)(p + 1);
 7a2:	01078513          	addi	a0,a5,16
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
 7a6:	70e2                	ld	ra,56(sp)
 7a8:	7442                	ld	s0,48(sp)
 7aa:	74a2                	ld	s1,40(sp)
 7ac:	7902                	ld	s2,32(sp)
 7ae:	69e2                	ld	s3,24(sp)
 7b0:	6a42                	ld	s4,16(sp)
 7b2:	6aa2                	ld	s5,8(sp)
 7b4:	6b02                	ld	s6,0(sp)
 7b6:	6121                	addi	sp,sp,64
 7b8:	8082                	ret
        prevp->s.ptr = p->s.ptr;
 7ba:	6398                	ld	a4,0(a5)
 7bc:	e118                	sd	a4,0(a0)
 7be:	bff1                	j	79a <malloc+0x86>
  hp->s.size = nu;
 7c0:	01652423          	sw	s6,8(a0)
  free((void*)(hp + 1));
 7c4:	0541                	addi	a0,a0,16
 7c6:	00000097          	auipc	ra,0x0
 7ca:	ec6080e7          	jalr	-314(ra) # 68c <free>
  return freep;
 7ce:	00093503          	ld	a0,0(s2)
      if((p = morecore(nunits)) == 0)
 7d2:	d971                	beqz	a0,7a6 <malloc+0x92>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 7d4:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 7d6:	4798                	lw	a4,8(a5)
 7d8:	fa9776e3          	bgeu	a4,s1,784 <malloc+0x70>
    if(p == freep)
 7dc:	00093703          	ld	a4,0(s2)
 7e0:	853e                	mv	a0,a5
 7e2:	fef719e3          	bne	a4,a5,7d4 <malloc+0xc0>
  p = sbrk(nu * sizeof(Header));
 7e6:	8552                	mv	a0,s4
 7e8:	00000097          	auipc	ra,0x0
 7ec:	b7e080e7          	jalr	-1154(ra) # 366 <sbrk>
  if(p == (char*)-1)
 7f0:	fd5518e3          	bne	a0,s5,7c0 <malloc+0xac>
        return 0;
 7f4:	4501                	li	a0,0
 7f6:	bf45                	j	7a6 <malloc+0x92>

#include "types.h"
#include "param.h"
#include "memlayout.h"
#include "riscv.h"
#include "spinlock.h"
#include "proc.h"
#include "defs.h"

extern uint64 cas (volatile void* address, int expected, int newval);

struct cpu cpus[NCPU];

struct proc* remove_first(int type, int cpu_id);

struct proc *zombie_list = 0;
struct proc *sleeping_list = 0;
struct proc *unused_list = 0;

struct spinlock ready_lock[NCPU];
struct spinlock zombie_lock;
struct spinlock sleeping_lock;
struct spinlock unused_lock;

int init = 0;
char* init_name = "init\n";

enum list_type {READYL, ZOMBIEL, SLEEPINGL, UNUSEDL};


void
increase_size(int cpu_id){
  struct cpu* c = &cpus[cpu_id];
  uint64 old;
  // printf("cpuid is: %d\n", cpu_id);
  do{
    old = c->queue_size;
    // printf("increasing size from: %d\n", old);
  } while(cas(&c->queue_size, old, old+1));
  // printf("now the size is: %d\n", c->queue_size);
}

void
decrease_size(int cpu_id){
  struct cpu* c = &cpus[cpu_id];
  // printf("cpuid is: %d\n", cpu_id);
  uint64 old;
  do{
    old = c->queue_size;
    // printf("decreasing size from: %d\n", old);
  } while(cas(&c->queue_size, old, old-1));
  // printf("now the size is: %d\n", c->queue_size);
}

uint64
get_queue_size(int cpu_id){
  return cpus[cpu_id].queue_size;
}

struct proc*
steal_process(){
  struct proc* p=0;
  for(int i=0; i<NCPU; i++){
    if(get_queue_size(i)>1){
      p = remove_first(READYL, i);
      break;
    }
  }
  return p;
}

int
get_lazy_cpu(){
  int curr_min = 0;
  for(int i=1; i<NCPU; i++){
    // printf("queue size is %d: %d\n", i, cpus[i].queue_size);
    curr_min = (cpus[i].queue_size < cpus[curr_min].queue_size) ? i : curr_min;
  }
  return curr_min;
}


struct proc* get_head(int type, int cpu_id){
  struct proc* p;

  switch (type)
  {
  case READYL:
    p = cpus[cpu_id].head;
    break;
  case ZOMBIEL:
    p = zombie_list;
    break;
  case SLEEPINGL:
    p = sleeping_list;
    break;
  case UNUSEDL:
    p = unused_list;
    break;
  
  default:
    panic("wrong type list");
  }
  return p;
}

void
set_head(struct proc* p, int type, int cpu_id)
{
  // printf("sethead start\n");

  switch (type)
  {
  case READYL:
    cpus[cpu_id].head = p;
    break;
  case ZOMBIEL:
    zombie_list = p;
    break;
  case SLEEPINGL:
    sleeping_list = p;
    break;
  case UNUSEDL:
    unused_list = p;
    break;

  
  default:
    panic("wrong type list");
  }
  // printf("sethead end\n");
}

void
acquire_list(int type, int cpu_id){
  // printf("acuirelist start\n");
  // printf("type: %d\n", type);
  switch (type)
  {
  case READYL:
    acquire(&ready_lock[cpu_id]);
    break;
  case ZOMBIEL:
    acquire(&zombie_lock);
    break;
  case SLEEPINGL:
    // printf("acquire sleeping\n");
    acquire(&sleeping_lock);
    break;
  case UNUSEDL:
    acquire(&unused_lock);
    break;
  
  default:
    panic("wrong type list");
  }
  // printf("acquirelist end\n");
}

void
release_list(int type, int cpu_id){
  // printf("release list start\n");
  switch (type)
  {
  case READYL:
    release(&ready_lock[cpu_id]);
    break;
  case ZOMBIEL:
    release(&zombie_lock);
    break;
  case SLEEPINGL:
    // printf("release sleeping\n");
    release(&sleeping_lock);
    break;
  case UNUSEDL:
    release(&unused_lock);
    break;
  
  default:
    panic("wrong type list");
  }
  // printf("release list end\n");
}




struct proc proc[NPROC];

void
add_to_list(struct proc* p, struct proc* head, int type, int cpu_id)
{
  // printf("add to list start\n");
  if(!p){
    panic("can't add null to list");
  }
  // empty list
  if(!head){
      // if(type==READYL && cpu_id == 1){
      //       printf("nohead\n");
      //       printf("%p\n", p);
      // }
      set_head(p, type, cpu_id);
      // if(type==READYL && cpu_id == 1){
      //       printf("nohead\n");
      //       printf("%p\n", get_head(READYL, cpu_id));
      // }
      release_list(type, cpu_id);
  }
  else{
    struct proc* prev = 0;
    while(head){
      // printf("acquiring add to list1: %d\n", head->pid);
      acquire(&head->list_lock);

      if(prev){
        // printf("releasing add to list1: %d\n", prev->pid);
        release(&prev->list_lock);
      }
      else{
        release_list(type, cpu_id);
      }
      prev = head;
      head = head->next;
    }
    prev->next = p;
    // printf("releasing add to list2: %d\n", prev->pid);
    release(&prev->list_lock);
  }
  // printf("add to list end\n");
}

void 
add_proc_to_list(struct proc* p, int type, int cpu_id)
{
  // printf("add proc to list start\n");
  // bad argument
  if(!p){
    panic("Add proc to list");
  }
  struct proc* head;
  acquire_list(type, cpu_id);
  head = get_head(type, cpu_id);
  add_to_list(p, head, type, cpu_id);
  // if(type == READYL && cpu_id == 1){
  //   printf("hi");
  // }
  // printf("add proc to list end\n");
}

struct proc* 
remove_first(int type, int cpu_id)
{
  // printf("remove_first start\n");
  acquire_list(type, cpu_id);
  struct proc* head = get_head(type, cpu_id);
  struct proc* ret = 0;
  if(!head){
    release_list(type, cpu_id);
  }
  else{
    // if(type==READYL && cpu_id == 1){
    //         printf("yeshead\n");
    //         printf("%p\n", head);
    // }
    // printf("acquiring remove first: %d\n", head->pid);
    acquire(&head->list_lock);
    ret = head;

    set_head(head->next, type, cpu_id);
    // printf("releasing remove first: %d\n", head->pid);
    release(&head->list_lock);

    release_list(type, cpu_id);

  }
  // printf("proc addr: %p\n", ret);
  if(ret){
    // printf("proc->next: %p\n", ret->next);
    // printf("proc name: %s\n", ret->name);
    // printf("start proc: %p\n", proc);
    // printf("end proc: %p\n", &proc[NPROC]);
    ret->next = 0;
    // printf("remove first end\n");}
  }
  return ret;
}

int
remove_proc(struct proc* p, int type){
  // printf("remove proc start\n");
  acquire_list(type, p->cpu_id);
  struct proc* head = get_head(type, p->cpu_id);
  if(!head){
    release_list(type, p->cpu_id);
    return 0;
  }
  else{
    struct proc* prev = 0;
    if(p == head){
      // remove node, p is the first link
      // printf("acquire remove_proc1: %d\n", p->pid);
      acquire(&p->list_lock);
      set_head(p->next, type, p->cpu_id);
      p->next = 0;
      // printf("releasing remove proc: %d\n", head->pid);
      release(&p->list_lock);
      release_list(type, p->cpu_id);
    }
    else{
      while(head){
        // printf("acquire remove_proc2: %d\n", head->pid);
        acquire(&head->list_lock);

        if(p == head){
          // remove node, head is the first link
          prev->next = head->next;
          p->next = 0;
          // printf("releasing remove proc: %d\n", head->pid);
          // printf("releasing remove proc: %d\n", prev->pid);
          release(&head->list_lock);
          release(&prev->list_lock);
          return 1;
        }

        if(!prev)
          release_list(type,p->cpu_id);
        else{
          // printf("releasing remove proc: %d\n", head->pid);
          release(&prev->list_lock);
        }
          
        
        prev = head;
        head = head->next;
      }
    }
    return 0;
  }
  // printf("remove proc end\n");
}

struct proc *initproc;

int nextpid = 1;
struct spinlock pid_lock;

extern void forkret(void);
static void freeproc(struct proc *p);

extern char trampoline[]; // trampoline.S

// helps ensure that wakeups of wait()ing
// parents are not lost. helps obey the
// memory model when using p->parent.
// must be acquired before any p->lock.
struct spinlock wait_lock;

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl) {
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
  }
}

// initialize the proc table at boot time.
void
procinit(void)
{
  struct proc *p;
  
  initlock(&pid_lock, "nextpid");
  initlock(&wait_lock, "wait_lock");
  initlock(&zombie_lock, "zombie lock");
  initlock(&sleeping_lock, "sleeping lock");
  initlock(&unused_lock, "unused lock");
  
  struct spinlock* s;
  for(s = ready_lock; s <&ready_lock[NCPU]; s++){
    initlock(s, "ready lock");
  }

  for(p = proc; p < &proc[NPROC]; p++) {
      initlock(&p->lock, "proc");
      initlock(&p->list_lock, "list lock");
      p->cpu_id = -1;
      p->kstack = KSTACK((int) (p - proc));
      add_proc_to_list(p, UNUSEDL, -1);
  }
}

// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
  int id = r_tp();
  return id;
}

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void) {
  int id = cpuid();
  struct cpu *c = &cpus[id];
  return c;
}

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void) {
  push_off();
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
  pop_off();
  return p;
}

int
allocpid() {
  int pid;

  do
  {
    pid = nextpid;
  } while (cas(&nextpid, pid, pid+1));

  return pid;
}

// Look in the process table for an UNUSED proc.
// If found, initialize state required to run in the kernel,
// and return with p->lock held.
// If there are no free procs, or a memory allocation fails, return 0.
static struct proc*
allocproc(void)
{
  struct proc *p;

  // printf("first removal\n");
  p = remove_first(UNUSEDL, -1);
  acquire(&p->lock);
  goto found;
  return 0;

found:
  p->pid = allocpid();
  p->state = USED;
  p->next = 0;

  // p->cpu_id = myproc()->cpu_id;    //todo
  // p->cpu_id = 0; 

  // Allocate a trapframe page.
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    freeproc(p);
    release(&p->lock);
    return 0;
  }

  // An empty user page table.
  p->pagetable = proc_pagetable(p);
  if(p->pagetable == 0){
    freeproc(p);
    release(&p->lock);
    return 0;
  }

  // Set up new context to start executing at forkret,
  // which returns to user space.
  memset(&p->context, 0, sizeof(p->context));
  p->context.ra = (uint64)forkret;
  p->context.sp = p->kstack + PGSIZE;

  return p;
}

// free a proc structure and the data hanging from it,
// including user pages.
// p->lock must be held.
static void
freeproc(struct proc *p)
{
  if(p->trapframe)
    kfree((void*)p->trapframe);
  p->trapframe = 0;
  if(p->pagetable)
    proc_freepagetable(p->pagetable, p->sz);
  p->pagetable = 0;
  p->sz = 0;
  p->pid = 0;
  p->parent = 0;
  p->name[0] = 0;
  p->chan = 0;
  p->killed = 0;
  p->xstate = 0;
  p->state = UNUSED;
  remove_proc(p, ZOMBIEL);
  add_proc_to_list(p, UNUSEDL, -1);
}

// Create a user page table for a given process,
// with no user memory, but with trampoline pages.
pagetable_t
proc_pagetable(struct proc *p)
{
  pagetable_t pagetable;

  // An empty page table.
  pagetable = uvmcreate();
  if(pagetable == 0)
    return 0;

  // map the trampoline code (for system call return)
  // at the highest user virtual address.
  // only the supervisor uses it, on the way
  // to/from user space, so not PTE_U.
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
              (uint64)trampoline, PTE_R | PTE_X) < 0){
    uvmfree(pagetable, 0);
    return 0;
  }

  // map the trapframe just below TRAMPOLINE, for trampoline.S.
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
              (uint64)(p->trapframe), PTE_R | PTE_W) < 0){
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    uvmfree(pagetable, 0);
    return 0;
  }

  return pagetable;
}

// Free a process's page table, and free the
// physical memory it refers to.
void
proc_freepagetable(pagetable_t pagetable, uint64 sz)
{
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
  uvmfree(pagetable, sz);
}

// a user program that calls exec("/init")
// od -t xC initcode
uchar initcode[] = {
  0x17, 0x05, 0x00, 0x00, 0x13, 0x05, 0x45, 0x02,
  0x97, 0x05, 0x00, 0x00, 0x93, 0x85, 0x35, 0x02,
  0x93, 0x08, 0x70, 0x00, 0x73, 0x00, 0x00, 0x00,
  0x93, 0x08, 0x20, 0x00, 0x73, 0x00, 0x00, 0x00,
  0xef, 0xf0, 0x9f, 0xff, 0x2f, 0x69, 0x6e, 0x69,
  0x74, 0x00, 0x00, 0x24, 0x00, 0x00, 0x00, 0x00,
  0x00, 0x00, 0x00, 0x00
};

// Set up first user process.
void
userinit(void)
{
  if(!init){
    struct cpu* c;
    for(c = cpus; c < &cpus[NCPU]; c++){
      c->head = 0;
      c->queue_size = 0;
    }
    init = 1;
  }
  
  struct proc *p;

  // printf("before\n");
  p = allocproc();
  // printf("after\n");
  initproc = p;
  
  // allocate one user page and copy init's instructions
  // and data into it.
  uvminit(p->pagetable, initcode, sizeof(initcode));
  p->sz = PGSIZE;

  // prepare for the very first "return" from kernel to user.
  p->trapframe->epc = 0;      // user program counter
  p->trapframe->sp = PGSIZE;  // user stack pointer

  safestrcpy(p->name, "initcode", sizeof(p->name));
  p->cwd = namei("/");

  p->state = RUNNABLE;
  p->cpu_id = 0;
  increase_size(p->cpu_id);

  cpus[p->cpu_id].head = p;

  release(&p->lock);
}

// Grow or shrink user memory by n bytes.
// Return 0 on success, -1 on failure.
int
growproc(int n)
{
  uint sz;
  struct proc *p = myproc();

  sz = p->sz;
  if(n > 0){
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
      return -1;
    }
  } else if(n < 0){
    sz = uvmdealloc(p->pagetable, sz, sz + n);
  }
  p->sz = sz;
  return 0;
}

// Create a new process, copying the parent.
// Sets up child kernel stack to return as if from fork() system call.
int
fork(void)
{
  int i, pid;
  struct proc *np;
  struct proc *p = myproc();

  // Allocate process.
  if((np = allocproc()) == 0){
    return -1;
  }

  // Copy user memory from parent to child.
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    freeproc(np);
    release(&np->lock);
    return -1;
  }
  np->sz = p->sz;

  // copy saved user registers.
  *(np->trapframe) = *(p->trapframe);

  // Cause fork to return 0 in the child.
  np->trapframe->a0 = 0;

  // increment reference counts on open file descriptors.
  for(i = 0; i < NOFILE; i++)
    if(p->ofile[i])
      np->ofile[i] = filedup(p->ofile[i]);
  np->cwd = idup(p->cwd);

  safestrcpy(np->name, p->name, sizeof(p->name));

  pid = np->pid;

  release(&np->lock);

  acquire(&wait_lock);
  np->parent = p;
  release(&wait_lock);

  acquire(&np->lock);
  np->state = RUNNABLE;
  
  
  int cpu_id = (BLNCFLG) ? get_lazy_cpu() : p->cpu_id;
  np->cpu_id = cpu_id;
  increase_size(cpu_id);
  add_proc_to_list(np, READYL, cpu_id);
  release(&np->lock);


  return pid;
}

// Pass p's abandoned children to init.
// Caller must hold wait_lock.
void
reparent(struct proc *p)
{
  struct proc *pp;

  for(pp = proc; pp < &proc[NPROC]; pp++){
    if(pp->parent == p){
      pp->parent = initproc;
      wakeup(initproc);
    }
  }
}

// Exit the current process.  Does not return.
// An exited process remains in the zombie state
// until its parent calls wait().
void
exit(int status)
{
  struct proc *p = myproc();

  if(p == initproc)
    panic("init exiting");

  // Close all open files.
  for(int fd = 0; fd < NOFILE; fd++){
    if(p->ofile[fd]){
      struct file *f = p->ofile[fd];
      fileclose(f);
      p->ofile[fd] = 0;
    }
  }

  begin_op();
  iput(p->cwd);
  end_op();
  p->cwd = 0;

  acquire(&wait_lock);

  // Give any children to init.
  reparent(p);

  // Parent might be sleeping in wait().
  wakeup(p->parent);
  
  acquire(&p->lock);

  p->xstate = status;
  p->state = ZOMBIE;
  
  // printf("decreasing exit\n");
  decrease_size(p->cpu_id);
  add_proc_to_list(p, ZOMBIEL, -1);

  release(&wait_lock);

  // Jump into the scheduler, never to return.
  sched();
  panic("zombie exit");
}

// Wait for a child process to exit and return its pid.
// Return -1 if this process has no children.
int
wait(uint64 addr)
{
  struct proc *np;
  int havekids, pid;
  struct proc *p = myproc();

  acquire(&wait_lock);

  for(;;){
    // Scan through table looking for exited children.
    havekids = 0;
    for(np = proc; np < &proc[NPROC]; np++){
      if(np->parent == p){
        // make sure the child isn't still in exit() or swtch().
        acquire(&np->lock);

        havekids = 1;
        if(np->state == ZOMBIE){
          // Found one.
          pid = np->pid;
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
                                  sizeof(np->xstate)) < 0) {
            release(&np->lock);
            release(&wait_lock);
            return -1;
          }
          freeproc(np);
          release(&np->lock);
          release(&wait_lock);
          return pid;
        }
        release(&np->lock);
      }
    }

    // No point waiting if we don't have any children.
    if(!havekids || p->killed){
      release(&wait_lock);
      return -1;
    }
    
    // Wait for a child to exit.
    sleep(p, &wait_lock);  //DOC: wait-sleep
  }
}

// Per-CPU process scheduler.
// Each CPU calls scheduler() after setting itself up.
// Scheduler never returns.  It loops, doing:
//  - choose a process to run.
//  - swtch to start running that process.
//  - eventually that process transfers control
//    via swtch back to the scheduler.
void
scheduler(void)
{
  // printf("here1\n");
  struct proc *p;
  struct cpu *c = mycpu();
  int cpu_id = cpuid();
  // printf("cpu id: %d\n", cpu_id);
  
  c->proc = 0;
  for(;;){
    // printf("cpu id: %d", cpu_id);
  // printf("here2\n");
    // Avoid deadlock by ensuring that devices can interrupt.
    intr_on();
    // printf("here3\n");
    p = remove_first(READYL, cpu_id);
    // if(cpu_id == 1 && p){
    //   printf("%p\n" , p);
    // }
    // printf("here4\n");


    //if empty list
    if(!p){
      if(!BLNCFLG){
        continue;
      }
      p = steal_process();  //maybe deliver my own cpuid so wont steal from myself
      if(!p){ 
        continue;
      }
      decrease_size(p->cpu_id);
      p->cpu_id = cpu_id;
      increase_size(cpu_id);
    }
    
    // printf("here5\n");
    acquire(&p->lock);
    // printf("here6\n");
    if(p->state!=RUNNABLE)
      panic("bad proc was selected");
    // printf("here7\n");
    p->state = RUNNING;
    c->proc = p;
    // printf("here8\n");
    // if(cpu_id == 1 && p){
    //   printf("poop1\n");
    // }
    swtch(&c->context, &p->context);
    // if(cpu_id == 1 && p){
    //   printf("poop2\n");
    // }
    // printf("here9\n");

    c->proc = 0;
    // printf("here10\n");
    release(&p->lock);
    // printf("her119\n");
  }
}

// Switch to scheduler.  Must hold only p->lock
// and have changed proc->state. Saves and restores
// intena because intena is a property of this
// kernel thread, not this CPU. It should
// be proc->intena and proc->noff, but that would
// break in the few places where a lock is held but
// there's no process.
void
sched(void)
{
  int intena;
  struct proc *p = myproc();

  if(!holding(&p->lock))
    panic("sched p->lock");
  if(mycpu()->noff != 1)
    panic("sched locks");
  if(p->state == RUNNING)
    panic("sched running");
  if(intr_get())
    panic("sched interruptible");

  intena = mycpu()->intena;
  swtch(&p->context, &mycpu()->context);
  mycpu()->intena = intena;
}

// Give up the CPU for one scheduling round.
void
yield(void)
{
  struct proc *p = myproc();
  acquire(&p->lock);
  p->state = RUNNABLE;
  add_proc_to_list(p, READYL, p->cpu_id);
  sched();
  release(&p->lock);
}

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);

  if (first) {
    // File system initialization must be run in the context of a
    // regular process (e.g., because it calls sleep), and thus cannot
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
}

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
  struct proc *p = myproc();
  
  // Must acquire p->lock in order to
  // change p->state and then call sched.
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
  release(lk);

  // Go to sleep.
  p->chan = chan;
  p->state = SLEEPING;
  // printf("hihdiqwodhqwoidhqwidqw\n");
  // printf("decreasing sleep\n");
  decrease_size(p->cpu_id);
  add_proc_to_list(p, SLEEPINGL,-1);
  // printf("hihdiqwodhqwoidhqwidqw2\n");


  sched();

  // Tidy up.
  p->chan = 0;

  // Reacquire original lock.
  release(&p->lock);
  acquire(lk);
}

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
  int released_list = 0;
  struct proc *p;
  struct proc* prev = 0;
  struct proc* tmp;
  acquire_list(SLEEPINGL, -1);
  p = get_head(SLEEPINGL, -1);

  while(p){
    // printf("wakeup while\n");
    acquire(&p->lock);
    // printf("wakeup while after normal lock\n");
    // printf("acquire wakeup: %d\n", p->pid);
    acquire(&p->list_lock);
    // printf("wakeup while after list lock\n");
    if(p->chan == chan){
      if(p == get_head(SLEEPINGL, -1)){
        // printf("wakeup yes & head\n");
        //remove fom sleep
        set_head(p->next, SLEEPINGL, -1);
        
        tmp = p;
        p = p->next;
        tmp->next = 0;
        
        //add to runnable
        tmp->state = RUNNABLE;
        int cpu_id = (BLNCFLG) ? get_lazy_cpu() : tmp->cpu_id;
        tmp->cpu_id = cpu_id;
        increase_size(cpu_id);
        add_proc_to_list(tmp, READYL, cpu_id);
        // printf("releasing wakeup : %d\n", tmp->pid);
        release(&tmp->list_lock);
        release(&tmp->lock);
      }
      //we are not on the beginning of the list.
      else{
        // printf("wakeup yes & no\n");

        prev->next = p->next;
        p->next = 0;
        p->state = RUNNABLE;
        int cpu_id = (BLNCFLG) ? get_lazy_cpu() : p->cpu_id;
        p->cpu_id = cpu_id;
        increase_size(cpu_id);
        add_proc_to_list(p, READYL, cpu_id);
        // printf("releasing wakeup: %d\n", p->pid);
        release(&p->list_lock);
        release(&p->lock);
        p = prev->next;
      }
    } 
    else{
      //we are not on the chan
      if(p == get_head(SLEEPINGL, -1)){
        // printf("wakeup no & head\n");

        release_list(SLEEPINGL,-1);
        released_list = 1;
      }
      else{
        // printf("wakeup no & no\n");
        // printf("releasing wakeup: %d\n", prev->pid);
        release(&prev->list_lock);
      }
      release(&p->lock);  //because we dont need to change his fields
      prev = p;
      p = p->next;
    }
  }
  if(!released_list){
    release_list(SLEEPINGL, -1);
  }
  if(prev){
    // printf("releasing wakeup: %d\n", prev->pid);
    release(&prev->list_lock);
  }
  // printf("end wakeup\n");
}



// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    acquire(&p->lock);
    if(p->pid == pid){
      p->killed = 1;
      if(p->state == SLEEPING){
        // Wake process from sleep().
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
  }
  return -1;
}

// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
  struct proc *p = myproc();
  if(user_dst){
    return copyout(p->pagetable, dst, src, len);
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}

// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
  struct proc *p = myproc();
  if(user_src){
    return copyin(p->pagetable, dst, src, len);
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
  static char *states[] = {
  [UNUSED]    "unused",
  [SLEEPING]  "sleep ",
  [RUNNABLE]  "runble",
  [RUNNING]   "run   ",
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
  for(p = proc; p < &proc[NPROC]; p++){
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
      state = states[p->state];
    else
      state = "???";
    printf("%d %s %s", p->pid, state, p->name);
    printf("\n");
  }
}

int 
set_cpu(int cpu_num)
{
  if(cpu_num<0 || cpu_num>NCPU){
    return -1;
  }
  decrease_size(myproc()->cpu_id);
  myproc()->cpu_id = cpu_num;
  increase_size(cpu_num);
  yield();
  return cpu_num;
}

int 
get_cpu()
{
  return myproc()->cpu_id;
}

int
cpu_process_count(int cpu_num){
  return get_queue_size(cpu_num);
}


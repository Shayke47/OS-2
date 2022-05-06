#include "types.h"
#include "param.h"
#include "memlayout.h"
#include "riscv.h"
#include "spinlock.h"
#include "proc.h"
#include "defs.h"

extern uint64 cas (volatile void* address, int expected, int newval);

struct cpu cpus[NCPU];



struct proc* ready_list[NCPU];
struct proc *zombie_list = 0;
struct proc *sleeping_list = 0;
struct proc *unused_list = 0;

struct spinlock ready_lock[NCPU];
struct spinlock zombie_lock;
struct spinlock sleeping_lock;
struct spinlock unused_lock;

enum list_type {READYL, ZOMBIEL, SLEEPINGL, UNUSEDL};

struct proc* get_head(int type){
  struct proc* p;

  switch (type)
  {
  case READYL:
    p = ready_list[cpuid()];
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

struct proc* set_head(struct proc* p, int type){
  switch (type)
  {
  case READYL:
    ready_list[cpuid()] = p;
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
}

void
acquire_list(int type){
  switch (type)
  {
  case READYL:
    acquire(&ready_lock[cpuid()]);
    break;
  case ZOMBIEL:
    acquire(&zombie_lock);
    break;
  case SLEEPINGL:
    acquire(&sleeping_lock);
    break;
  case UNUSEDL:
    acquire(&unused_lock);
    break;
  
  default:
    panic("wrong type list");
  }
}

void
release_list(int type){
  switch (type)
  {
  case READYL:
    release(&ready_lock[cpuid()]);
    break;
  case ZOMBIEL:
    release(&zombie_lock);
    break;
  case SLEEPINGL:
    release(&sleeping_lock);
    break;
  case UNUSEDL:
    release(&unused_lock);
    break;
  
  default:
    panic("wrong type list");
  }
}



// void init_ready(){
//   for(int i=0; i < NCPU; i++){
//     ready_list[i] = 0;
//   }
// }


struct proc proc[NPROC];

// struct proc* get_last(int* head){
//   int index;
//   int curr_head = *head;
//   struct proc* p = &proc[curr_head];
//   for(index = curr_head; index != -1;){
//     p = &proc[index];
//     index = p->next;

//     // in case that the head is removed while adding another process to the list!@#!@#!@#!@#!@
//   }
//   return p;
// }

void 
add_proc_to_list(struct proc* p, int type)
{
  // bad argument
  if(!p){
    panic("Add proc to list");
  }
  struct proc* head;
  acquire_list(type);
  head = get_head(type);
  // empty list
  if(!head){
      set_head(p, type);
      release_list(type);
  }
  else{
    struct proc* prev = 0;
    while(head){
      acquire(&head->list_lock);

      if(prev)
        release(&prev->list_lock);
      else{
        release_list(type);
      }
      prev = head;
      head = head->next;
    }
    prev->next = p;
    release(&prev->list_lock);
  }
}

struct proc* 
remove_first(int type)
{
  acquire_list(type);
  struct proc* head = get_head(type);
  struct proc* ret = 0;
  if(!head){
    release_list(type);
  }
  else{
    acquire(&head->list_lock);
    ret = head;
    set_head(head->next, type);
    release(&head->list_lock);
    release_list(type);
  }
  return ret;
}

int
remove_proc(struct proc* p, int type){
  acquire_list(type);
  struct proc* head = get_head(type);
  if(!head){
    release_list(type);
    return 0;
  }
  else{
    struct proc* curr;
    struct proc* prev = 0;
    if(p == head){
      // remove node, p is the first link
      acquire(&p->list_lock);
      set_head(p->next, type);
      release(&p->list_lock);
      release_list(type);
    }
    else{
      curr = head;
      while(head){
        acquire(&head->list_lock);

        if(p == head){
          // remove node, head is the first link
          prev->next = head->next;
          release(&head->list_lock);
          release(&prev->list_lock);
          return 1;
        }

        if(!prev)
          release_list(type);
        else
          release(&prev->list_lock);
        
        prev = head;
        head = head->next;
      }
    }
    return 0;
  }
}

int 
find_in_proc(struct proc* p)
{
  // (p - proc)/sizeof(struct proc);
  struct proc* curr;
  int index = 0;
  for(curr = proc; curr < &proc[NPROC]; curr++){
    if(curr == p){
      return index;
    }
    index++;
  }
  return -1;
}

// void remove_and_add(int src, int dest){
//   add_proc_to_list(remove(src), dest);
// }

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
      p->kstack = KSTACK((int) (p - proc));
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

  
  // acquire(&pid_lock);
  // pid = nextpid;
  // nextpid = nextpid + 1;
  // release(&pid_lock);

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

  for(p = proc; p < &proc[NPROC]; p++) {
    acquire(&p->lock);
    if(p->state == UNUSED) {
      goto found;
    } else {
      release(&p->lock);
    }
  }
  return 0;

found:
  p->pid = allocpid();
  p->state = USED;
  p->next = -1;

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
  int index = remove_proc(&zombie_list, p);
  if(index == -1){
    panic("Freeproc: failed to remove process from zombie list");
  }
  add_proc_to_list(index, &unused_list);
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
  struct proc *p;

  p = allocproc();
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
  np->cpu_id = p->cpu_id;
  int index = find_in_proc(np);
  if(index < 0){
    panic("Fork, couldn't find in proc table\n");
  }
  add_proc_to_list(index, &(ready_list[np->cpu_id]));
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

  int index = find_in_proc(p);
  if (index == -1){
    panic("Exit: Couldn't find in proc table");
  }
  add_proc_to_list(index, &zombie_list);

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
  struct proc *p;
  struct cpu *c = mycpu();
  
  c->proc = 0;
  int head;
  int torun;
  for(;;){
    // Avoid deadlock by ensuring that devices can interrupt.
    intr_on();

    head = &ready_list[cpuid()];
    torun = remove(head);

    //if empty list
    if(torun == -1){
      continue;
    }

    p = &proc[torun];
    acquire(&p->lock);

    if(p->state!=RUNNABLE)
      panic("bad proc was selected");

    p->state = RUNNING;
    c->proc = p;
    swtch(&c->context, &p->context);

    c->proc = 0;
    release(&p->lock);
    
    // for(p = proc; p < &proc[NPROC]; p++) {
    //   acquire(&p->lock);
    //   if(p->state == RUNNABLE) {
    //     // Switch to chosen process.  It is the process's job
    //     // to release its lock and then reacquire it
    //     // before jumping back to us.
    //     p->state = RUNNING;
    //     c->proc = p;
    //     swtch(&c->context, &p->context);

    //     // Process is done running for now.
    //     // It should have changed its p->state before coming back.
    //     c->proc = 0;
    //   }
    //   release(&p->lock);
    // }
    
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

  // int tosleep = remove(&ready_list[cpuid()]);  //wouldnt be here because it is removed in scheduler
  int tosleep = find_in_proc(p);
  if(tosleep==-1)
    panic("sleep: couldnt find p in proc\n");
  add_proc_to_list(tosleep, &sleeping_list);

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
  struct proc *p;
  struct proc* last;
  int i;
  int p_ind;
  for(i = sleeping_list; i != -1;){
    p = &proc[i];
    acquire(&p->lock);
    if(p->chan == chan){
      p->state = RUNNABLE;
      if(last){
        p_ind = last->next;
        last->next = p->next;
      }
      else{
        p_ind = find_in_proc(p);
        sleeping_list = p->next;    // maybe need CAS !@#!@#!@#!@#!@#
      }
      add_proc_to_list(p_ind, &ready_list[p->cpu_id]);
    }
    i = p->next;
    release(&p->lock);
  }

  // for(p = proc; p < &proc[NPROC]; p++) {
  //   if(p != myproc()){
  //     acquire(&p->lock);
  //     if(p->state == SLEEPING && p->chan == chan) {
  //       p->state = RUNNABLE;

  //     }
  //     release(&p->lock);
  //   }
  // }
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
  myproc()->cpu_id = cpu_num;
  yield();
  return cpu_num;
}

int 
get_cpu()
{
  return cpuid();
}


/* Exercises the corpus's functions so that tools/check-behaviour.sh can tell
   whether a module still does the same thing after a trip through the core.
   Each corpus source has its own macro; hello.c defines its own main. */
#include <stdio.h>
#include <string.h>
/* arith.c */
int sdiv(int,int); unsigned udiv(unsigned,unsigned); int srem(int,int);
unsigned urem(unsigned,unsigned); int ashr(int,int); unsigned lshr(unsigned,unsigned);
long widen(int); unsigned long zwiden(unsigned); short narrow(long); int compare(int,unsigned);
/* branch.c */
int classify(int); int clamp(int,int,int); int select_or(int,int);
/* loop.c */
int sum(const int*,int); int count_down(int); void fill(int*,int,int);
/* memops.c */
void *duplicate(const void*,unsigned long); void clear(void*,unsigned long);
void release(void*); int apply(int(*)(int),int); int total(int,...);
/* escape.c */
int through_pointer(int); int volatile_local(int); int addressed_pair(int,int);
long counted(int); int only_stored(int);
/* jumps.c */
int search(const int*,int,int,int); int digits(unsigned); int falls_through(int);
int two_exits(const int*,int,int); int nested_while(int,int);
/* unions.c -- the by-value aggregates have to be declared the same way here */
union bits { int i; float f; unsigned char b[4]; };
struct flags { unsigned kind:3; unsigned live:1; signed delta:12; };
struct __attribute__((packed)) tight { char c; int n; short s; };
int punned(float); unsigned low_byte(int);
unsigned get_kind(struct flags); int get_delta(struct flags);
struct flags set_live(struct flags, _Bool);
int tight_n(const struct tight*); short tight_s(const struct tight*);
int next_colour(int); _Bool truthy(int);
/* hoist.c */
int scaled_sum(const int*,int,int); int nested_squares(int,int,int);
int sometimes(const int*,int,int); int guarded_divide(int,int,int);
int carried_first(int,int); int jumped_into(int,int);
/* indirect.c */
int dispatch(int,int,int); int fib(int); int gcd(int,int); int parity(int);
int apply_twice(int(*)(int,int),int,int);
/* linkage.c */
int real_answer(void); int aliased_answer(void); int hidden_helper(int);
int never_inlined(int); int uses_them(int);
extern int weak_count; extern int tentative;
/* reload.c -- sink() is defined here so that a call in the middle of a function
   really can write what a pointer handed to that function reads. */
struct pair { int a; int b; };
struct pair *watched;
void sink(void){ if(watched) watched->b += 100; }
int square_b(const struct pair*); int written_then_read(struct pair*,int);
int separate_slots(int); int both_ways(struct pair*); int around_call(struct pair*);
int confined_across_call(int); int through_the_store(struct pair*,struct pair*);
int repeated(const struct pair*,int); int accumulated(const struct pair*,int*,int);
static int twice(int x){return x*2;}
static int plus(int a,int b){return a+b;}
#ifdef HELLO
int olivine_unused_main(void);
#else
int main(void){
#ifdef ARITH
  for(int i=-7;i<=7;i++) for(int j=1;j<=3;j++)
    printf("%d %u %d %u %d %u %ld %lu %d %d\n", sdiv(i,j), udiv((unsigned)i,(unsigned)j),
      srem(i,j), urem((unsigned)i,(unsigned)j), ashr(i,j), lshr((unsigned)i,(unsigned)j),
      widen(i), zwiden((unsigned)i), (int)narrow((long)i*100000), compare(i,(unsigned)j));
#endif
#ifdef BRANCH
  for(int i=-3;i<=105;i++) printf("%d %d %d\n", classify(i), clamp(i,0,50), select_or(i,9));
#endif
#ifdef LOOP
  { int a[8]; for(int i=0;i<8;i++) a[i]=i*3-4;
    printf("%d\n", sum(a,8));
    for(int i=1;i<=40;i++) printf("%d ", count_down(i)); printf("\n");
    fill(a,8,7); for(int i=0;i<8;i++) printf("%d ", a[i]); printf("\n"); }
#endif
#ifdef MEMOPS
  { char src[16]; for(int i=0;i<16;i++) src[i]=(char)(i+1);
    void *d = duplicate(src,16); printf("%d %d\n", ((char*)d)[0], ((char*)d)[15]);
    clear(d,8); printf("%d %d\n", ((char*)d)[0], ((char*)d)[15]); release(d);
    printf("%d\n", apply(twice,21));
    printf("%d\n", total(4,1,2,3,4)); }
#endif
#ifdef ESCAPE
  for(int i=-4;i<=4;i++)
    printf("%d %d %d %ld %d\n", through_pointer(i), volatile_local(i),
      addressed_pair(i,-i), counted(i<1?1:i), only_stored(i));
#endif
#ifdef JUMPS
  { int g[12]; for(int i=0;i<12;i++) g[i]=(i*5)%7-2;
    for(int k=-2;k<=4;k++) printf("%d ", search(g,4,3,k)); printf("\n");
    for(unsigned u=0;u<100000u;u=u*7+1) printf("%d ", digits(u)); printf("\n");
    for(int i=-1;i<=10;i++) printf("%d ", falls_through(i)); printf("\n");
    for(int c=-5;c<=20;c+=5) printf("%d ", two_exits(g,12,c)); printf("\n");
    for(int a=0;a<5;a++) printf("%d ", nested_while(a,3)); printf("\n"); }
#endif
#ifdef UNIONS
  { for(float f=-2.5f;f<=2.5f;f+=1.25f) printf("%d ", punned(f)); printf("\n");
    for(int i=0;i<4;i++) printf("%u ", low_byte(0x11223344+i)); printf("\n");
    struct flags fl = {5,0,-300};
    printf("%u %d ", get_kind(fl), get_delta(fl));
    struct flags on = set_live(fl,1); printf("%u %d %u\n", on.kind, on.delta, on.live);
    struct tight t = {'z', 0x01020304, -9};
    printf("%d %d\n", tight_n(&t), (int)tight_s(&t));
    for(int c=0;c<9;c++) printf("%d ", next_colour(c)); printf("\n");
    for(int i=-1;i<=1;i++) printf("%d ", (int)truthy(i)); printf("\n"); }
#endif
#ifdef HOIST
  { int xs[9]; for(int i=0;i<9;i++) xs[i]=(i*4)%7-3;
    for(int k=-2;k<=2;k++) printf("%d %d ", scaled_sum(xs,9,k), sometimes(xs,9,k)); printf("\n");
    printf("%d %d\n", scaled_sum(xs,0,5), sometimes(xs,0,5));
    for(int r=0;r<4;r++) printf("%d ", nested_squares(3,5,r)); printf("\n");
    /* The divisor is zero on the calls whose loop does not run: a division
       hoisted out of the loop would fault here. */
    printf("%d %d %d\n", guarded_divide(10,0,0), guarded_divide(10,0,-1), guarded_divide(10,3,4));
    for(int n=0;n<4;n++) printf("%d ", carried_first(n,6)); printf("\n");
    for(int n=0;n<5;n++) printf("%d ", jumped_into(n,2)); printf("\n"); }
#endif
#ifdef INDIRECT
  { for(int w=0;w<6;w++) printf("%d ", dispatch(w,9,4)); printf("\n");
    for(int i=0;i<15;i++) printf("%d ", fib(i)); printf("\n");
    for(int a=1;a<=30;a+=7) for(int b=1;b<=12;b+=5) printf("%d ", gcd(a,b)); printf("\n");
    for(int i=-1;i<=6;i++) printf("%d ", parity(i)); printf("\n");
    printf("%d\n", apply_twice(plus,3,4)); }
#endif
#ifdef RELOAD
  { struct pair cell = {3,4}, other = {10,20};
    printf("%d %d %d\n", square_b(&cell), written_then_read(&cell,9), cell.b);
    printf("%d %d\n", separate_slots(5), separate_slots(-2));
    cell.a = 1; cell.b = 2;
    printf("%d %d\n", both_ways(&cell), cell.a);
    /* sink() writes through this one, so a second read that did not happen
       shows up as an answer twice the first read. */
    cell.b = 4; watched = &cell;
    printf("%d %d\n", around_call(&cell), cell.b);
    watched = 0;
    printf("%d\n", confined_across_call(7));
    cell.b = 6;
    printf("%d %d %d\n", through_the_store(&cell,&cell), through_the_store(&cell,&other), other.b);
    cell.b = 5;
    for(int n=-1;n<=3;n++) printf("%d ", repeated(&cell,n)); printf("\n");
    { int out = 0;
      for(int n=0;n<=3;n++) printf("%d ", accumulated(&cell,&out,n));
      printf("%d\n", out);
      /* And with the written address inside the struct being read. */
      cell.b = 5;
      for(int n=0;n<=3;n++) printf("%d ", accumulated(&cell,&cell.b,n)); printf("\n"); } }
#endif
#ifdef LINKAGE
  printf("%d %d %d\n", real_answer(), aliased_answer(), weak_count + tentative);
  for(int i=0;i<5;i++) printf("%d %d %d ", hidden_helper(i), never_inlined(i), uses_them(i));
  printf("\n");
#endif
  return 0;
}
#endif

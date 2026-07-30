/* Exercises the corpus's functions so that tools/check-behaviour.sh can tell
   whether a module still does the same thing after a trip through the core.
   Each corpus source has its own macro; hello.c defines its own main. */
#include <stdio.h>
#include <string.h>
#include <complex.h>
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
/* pick.c */
int larger(int,int); int sign(int); int bumped(int,int); int folded(const int*,int);
int safe_divide(int,int); int if_present(const int*); int one_call(int);
extern int counter;
/* hoist.c */
int scaled_sum(const int*,int,int); int nested_squares(int,int,int);
int sometimes(const int*,int,int); int guarded_divide(int,int,int);
int carried_first(int,int); int jumped_into(int,int);
int scale_now(void); void set_scale(int); int scaled_by_symbol(const int*,int);
int bumping(int*,int); int bumping_symbol(int);
/* rotate.c */
int scale_all(const int*,int,const int*); int consume(int);
int tickets_taken(void); void reset_tickets(void); int countdown(int);
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
/* values.c -- the by-value aggregates have to be declared the same way here */
struct point { double x, y; };
struct box { int a,b,c,d,e; };
struct point scaled(struct point,double); double dot(struct point,struct point);
double sum_scaled(struct point,double); double travelled(struct point,int);
struct box spread(int); int fifth(struct box);
double _Complex turned(double _Complex,double _Complex);
/* atomics.c */
int fetched(_Atomic int*,int); int raised_to(_Atomic int*,int);
int weighted(_Atomic int*,const int*,int); int fenced(int,int);
int published(_Atomic int*,int);
/* bytes.c */
void scale_apart(int*restrict,const int*restrict,int,const int*restrict);
void scale_together(int*,const int*,int,const int*);
unsigned checksum(const unsigned char*,int); int span(const signed char*,int);
unsigned char low_bits(unsigned); short folded_down(int,int);
int length(const char*); void copy_bytes(char*restrict,const char*restrict);
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
    for(int n=0;n<5;n++) printf("%d ", jumped_into(n,2)); printf("\n");
    /* The read of the symbol comes out of this loop, so the call with n = 0
       runs a read the program never ran.  Reading a symbol cannot fault, and
       what it answers is the same either way. */
    for(int s=-1;s<=2;s++) { set_scale(s); printf("%d %d ", scaled_by_symbol(xs,9), scaled_by_symbol(xs,0)); }
    printf("\n");
    /* The loop writes the symbol it reads, so a read hoisted out of it would
       add the first iteration's value four times over. */
    set_scale(3);
    printf("%d %d ", bumping_symbol(4), scale_now());
    { int cell = 10; set_scale(5); printf("%d %d\n", bumping(&cell,3), cell); } }
#endif
#ifdef ROTATE
  { int xs[6]; for(int i=0;i<6;i++) xs[i]=i*3-4; int k=5;
    /* The second call reads nothing at all: the loop does not run, and the
       address the body would have read is null. */
    printf("%d %d\n", scale_all(xs,6,&k), scale_all((const int*)0,0,(const int*)0));
    /* How many tickets the loop took says how many times its test ran. */
    for(int m=0;m<5;m++){ reset_tickets(); printf("%d %d ", consume(m), tickets_taken()); }
    printf("\n");
    for(int n=-2;n<10;n++) printf("%d ", countdown(n)); printf("\n"); }
#endif
#ifdef PICK
  { for(int a=-2;a<3;a++) for(int b=-1;b<2;b++) printf("%d ", larger(a,b)); printf("\n");
    for(int x=-3;x<4;x++) printf("%d ", sign(x)); printf("\n");
    for(int c=0;c<2;c++) printf("%d ", bumped(7,c)); printf("\n");
    { int xs[5] = {3,-4,0,6,-1}; printf("%d %d\n", folded(xs,5), folded(xs,0)); }
    /* b == 0 is where the branch is the only thing keeping the division from
       happening, and p == 0 the same for the load. */
    for(int b=-2;b<3;b++) printf("%d ", safe_divide(12,b)); printf("\n");
    { int one = 1; printf("%d %d\n", if_present(&one), if_present((const int*)0)); }
    /* Exactly one of the two calls may be made, whichever way it goes. */
    counter = 0; printf("%d %d ", one_call(1), counter);
    counter = 0; printf("%d %d\n", one_call(0), counter); }
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
#ifdef VALUES
  { struct point p = {1.5, -2.25}, q = {4.0, 0.5};
    struct point s = scaled(p, 3.0);
    printf("%.3f %.3f %.3f\n", s.x, s.y, dot(p,q));
    for(double k=-1.0;k<=2.0;k+=0.5) printf("%.3f ", sum_scaled(p,k)); printf("\n");
    for(int n=-1;n<=4;n++) printf("%.3f ", travelled(q,n)); printf("\n");
    { struct box b = spread(6); printf("%d %d %d\n", b.a, b.e, fifth(b)); }
    { double _Complex z = 2.0 + 3.0*_Complex_I, w = -1.0 + 0.5*_Complex_I;
      double _Complex r = turned(z,w);
      printf("%.3f %.3f\n", __real__ r, __imag__ r); } }
#endif
#ifdef ATOMICS
  { _Atomic int c = 5;
    for(int n=0;n<4;n++) printf("%d %d ", fetched(&c,n), (int)c); printf("\n");
    /* The cell starts below the floor on one call and above it on the next,
       so the loop runs and then does not. */
    c = 1; printf("%d %d ", raised_to(&c,9), (int)c);
    printf("%d %d\n", raised_to(&c,4), (int)c);
    { int xs[6]; for(int i=0;i<6;i++) xs[i]=i*2-3;
      c = 3; for(int n=0;n<=6;n+=2) printf("%d ", weighted(&c,xs,n)); printf("\n"); }
    for(int a=-2;a<=2;a++) printf("%d ", fenced(a,a+1)); printf("\n");
    c = 0; printf("%d %d\n", published(&c,11), (int)c); }
#endif
#ifdef BYTES
  { int in[8], out[8], k = 3;
    for(int i=0;i<8;i++) in[i]=i*3-5;
    scale_apart(out,in,8,&k); for(int i=0;i<8;i++) printf("%d ", out[i]); printf("\n");
    /* The same loop with nothing promised, called once with the scale apart
       from what is written and once with the scale inside it, where every
       iteration reads what the last one wrote. */
    for(int i=0;i<8;i++) out[i]=0;
    scale_together(out,in,8,&k); for(int i=0;i<8;i++) printf("%d ", out[i]); printf("\n");
    for(int i=0;i<8;i++) out[i]=2;
    scale_together(out,in,8,out); for(int i=0;i<8;i++) printf("%d ", out[i]); printf("\n");
    { unsigned char bs[9]; for(int i=0;i<9;i++) bs[i]=(unsigned char)(i*29+1);
      printf("%u %u\n", checksum(bs,9), checksum(bs,0)); }
    { signed char ss[7] = {0,-128,127,3,-4,50,-50};
      printf("%d %d\n", span(ss,7), span(ss,1)); }
    for(unsigned u=0;u<0x30000u;u=u*11+7) printf("%u ", (unsigned)low_bits(u)); printf("\n");
    for(int a=-3;a<=3;a++) printf("%d ", (int)folded_down(a*10000,a+300)); printf("\n");
    { char buf[16]; const char *src = "hello, corpus";
      copy_bytes(buf,src); printf("%d %d %s\n", length(src), length(buf), buf); } }
#endif
#ifdef LINKAGE
  printf("%d %d %d\n", real_answer(), aliased_answer(), weak_count + tentative);
  for(int i=0;i<5;i++) printf("%d %d %d ", hidden_helper(i), never_inlined(i), uses_them(i));
  printf("\n");
#endif
  return 0;
}
#endif

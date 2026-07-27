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
static int twice(int x){return x*2;}
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
  return 0;
}
#endif

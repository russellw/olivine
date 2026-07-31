; ModuleID = 'test/c/asm.c'
source_filename = "test/c/asm.c"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-linux-gnu"

; Function Attrs: noinline nounwind optnone uwtable
define dso_local i32 @swapped(i32 noundef %0) #0 {
  %2 = alloca i32, align 4
  %3 = alloca i32, align 4
  store i32 %0, ptr %2, align 4
  %4 = load i32, ptr %2, align 4
  %5 = call i32 asm "bswapl $0", "=r,0,~{dirflag},~{fpsr},~{flags}"(i32 %4) #1, !srcloc !6
  store i32 %5, ptr %3, align 4
  %6 = load i32, ptr %3, align 4
  ret i32 %6
}

; Function Attrs: noinline nounwind optnone uwtable
define dso_local i32 @swapped_twice(i32 noundef %0) #0 {
  %2 = alloca i32, align 4
  %3 = alloca i32, align 4
  %4 = alloca i32, align 4
  store i32 %0, ptr %2, align 4
  %5 = load i32, ptr %2, align 4
  %6 = call i32 asm "bswapl $0", "=r,0,~{dirflag},~{fpsr},~{flags}"(i32 %5) #1, !srcloc !7
  store i32 %6, ptr %3, align 4
  %7 = load i32, ptr %3, align 4
  %8 = call i32 asm "bswapl $0", "=r,0,~{dirflag},~{fpsr},~{flags}"(i32 %7) #1, !srcloc !8
  store i32 %8, ptr %4, align 4
  %9 = load i32, ptr %3, align 4
  %10 = load i32, ptr %4, align 4
  %11 = add nsw i32 %9, %10
  ret i32 %11
}

; Function Attrs: noinline nounwind optnone uwtable
define dso_local i32 @reread(ptr noundef %0) #0 {
  %2 = alloca ptr, align 8
  %3 = alloca i32, align 4
  %4 = alloca i32, align 4
  store ptr %0, ptr %2, align 8
  %5 = load ptr, ptr %2, align 8
  %6 = load i32, ptr %5, align 4
  store i32 %6, ptr %3, align 4
  call void asm sideeffect "", "~{memory},~{dirflag},~{fpsr},~{flags}"() #2, !srcloc !9
  %7 = load ptr, ptr %2, align 8
  %8 = load i32, ptr %7, align 4
  store i32 %8, ptr %4, align 4
  %9 = load i32, ptr %3, align 4
  %10 = mul nsw i32 %9, 100
  %11 = load i32, ptr %4, align 4
  %12 = add nsw i32 %10, %11
  ret i32 %12
}

; Function Attrs: noinline nounwind optnone uwtable
define dso_local i32 @barrier_sum(ptr noundef %0, i32 noundef %1, ptr noundef %2) #0 {
  %4 = alloca ptr, align 8
  %5 = alloca i32, align 4
  %6 = alloca ptr, align 8
  %7 = alloca i32, align 4
  %8 = alloca i32, align 4
  store ptr %0, ptr %4, align 8
  store i32 %1, ptr %5, align 4
  store ptr %2, ptr %6, align 8
  store i32 0, ptr %7, align 4
  store i32 0, ptr %8, align 4
  br label %9

9:                                                ; preds = %24, %3
  %10 = load i32, ptr %8, align 4
  %11 = load i32, ptr %5, align 4
  %12 = icmp slt i32 %10, %11
  br i1 %12, label %13, label %27

13:                                               ; preds = %9
  %14 = load ptr, ptr %4, align 8
  %15 = load i32, ptr %8, align 4
  %16 = sext i32 %15 to i64
  %17 = getelementptr inbounds i32, ptr %14, i64 %16
  %18 = load i32, ptr %17, align 4
  %19 = load ptr, ptr %6, align 8
  %20 = load i32, ptr %19, align 4
  %21 = mul nsw i32 %18, %20
  %22 = load i32, ptr %7, align 4
  %23 = add nsw i32 %22, %21
  store i32 %23, ptr %7, align 4
  call void asm sideeffect "", "~{memory},~{dirflag},~{fpsr},~{flags}"() #2, !srcloc !10
  br label %24

24:                                               ; preds = %13
  %25 = load i32, ptr %8, align 4
  %26 = add nsw i32 %25, 1
  store i32 %26, ptr %8, align 4
  br label %9, !llvm.loop !11

27:                                               ; preds = %9
  %28 = load i32, ptr %7, align 4
  ret i32 %28
}

; Function Attrs: noinline nounwind optnone uwtable
define dso_local i32 @through_slot(i32 noundef %0) #0 {
  %2 = alloca i32, align 4
  %3 = alloca i32, align 4
  store i32 %0, ptr %2, align 4
  %4 = load i32, ptr %2, align 4
  store i32 %4, ptr %3, align 4
  call void asm sideeffect "addl $$7, $0", "=*m,*m,~{dirflag},~{fpsr},~{flags}"(ptr elementtype(i32) %3, ptr elementtype(i32) %3) #2, !srcloc !13
  %5 = load i32, ptr %3, align 4
  ret i32 %5
}

; Function Attrs: noinline nounwind optnone uwtable
define dso_local i32 @hidden(i32 noundef %0, i32 noundef %1) #0 {
  %3 = alloca i32, align 4
  %4 = alloca i32, align 4
  %5 = alloca i32, align 4
  store i32 %0, ptr %3, align 4
  store i32 %1, ptr %4, align 4
  %6 = load i32, ptr %3, align 4
  %7 = load i32, ptr %4, align 4
  %8 = add nsw i32 %6, %7
  %9 = mul nsw i32 %8, 2
  store i32 %9, ptr %5, align 4
  %10 = load i32, ptr %5, align 4
  %11 = call i32 asm "", "=r,0,~{dirflag},~{fpsr},~{flags}"(i32 %10) #1, !srcloc !14
  store i32 %11, ptr %5, align 4
  %12 = load i32, ptr %5, align 4
  %13 = load i32, ptr %5, align 4
  %14 = mul nsw i32 %13, 0
  %15 = add nsw i32 %12, %14
  %16 = load i32, ptr %4, align 4
  %17 = load i32, ptr %4, align 4
  %18 = sub nsw i32 %16, %17
  %19 = add nsw i32 %15, %18
  ret i32 %19
}

; Function Attrs: noinline nounwind optnone uwtable
define dso_local i32 @each_time(i32 noundef %0, i32 noundef %1) #0 {
  %3 = alloca i32, align 4
  %4 = alloca i32, align 4
  %5 = alloca i32, align 4
  %6 = alloca i32, align 4
  %7 = alloca i32, align 4
  store i32 %0, ptr %3, align 4
  store i32 %1, ptr %4, align 4
  store i32 0, ptr %5, align 4
  store i32 0, ptr %6, align 4
  br label %8

8:                                                ; preds = %19, %2
  %9 = load i32, ptr %6, align 4
  %10 = load i32, ptr %4, align 4
  %11 = icmp slt i32 %9, %10
  br i1 %11, label %12, label %22

12:                                               ; preds = %8
  %13 = load i32, ptr %3, align 4
  %14 = call i32 asm "bswapl $0", "=r,0,~{dirflag},~{fpsr},~{flags}"(i32 %13) #1, !srcloc !15
  store i32 %14, ptr %7, align 4
  %15 = load i32, ptr %7, align 4
  %16 = ashr i32 %15, 24
  %17 = load i32, ptr %5, align 4
  %18 = add nsw i32 %17, %16
  store i32 %18, ptr %5, align 4
  br label %19

19:                                               ; preds = %12
  %20 = load i32, ptr %6, align 4
  %21 = add nsw i32 %20, 1
  store i32 %21, ptr %6, align 4
  br label %8, !llvm.loop !16

22:                                               ; preds = %8
  %23 = load i32, ptr %5, align 4
  ret i32 %23
}

; Function Attrs: noinline nounwind optnone uwtable
define dso_local i32 @both_kinds(i32 noundef %0) #0 {
  %2 = alloca i32, align 4
  %3 = alloca i32, align 4
  %4 = alloca i32, align 4
  store i32 %0, ptr %2, align 4
  %5 = load i32, ptr %2, align 4
  %6 = mul nsw i32 %5, 3
  store i32 %6, ptr %3, align 4
  %7 = load i32, ptr %2, align 4
  store i32 %7, ptr %4, align 4
  call void asm sideeffect "addl $$1, $0", "=*m,*m,~{dirflag},~{fpsr},~{flags}"(ptr elementtype(i32) %4, ptr elementtype(i32) %4) #2, !srcloc !17
  %8 = load i32, ptr %3, align 4
  %9 = load i32, ptr %4, align 4
  %10 = add nsw i32 %8, %9
  ret i32 %10
}

attributes #0 = { noinline nounwind optnone uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #1 = { nounwind memory(none) }
attributes #2 = { nounwind }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 1, !"wchar_size", i32 4}
!1 = !{i32 8, !"PIC Level", i32 2}
!2 = !{i32 7, !"PIE Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Ubuntu clang version 21.1.8 (6ubuntu1)"}
!6 = !{i64 1081}
!7 = !{i64 1382}
!8 = !{i64 1425}
!9 = !{i64 1681}
!10 = !{i64 2069}
!11 = distinct !{!11, !12}
!12 = !{!"llvm.loop.mustprogress"}
!13 = !{i64 2279}
!14 = !{i64 2594}
!15 = !{i64 3395}
!16 = distinct !{!16, !12}
!17 = !{i64 3686}

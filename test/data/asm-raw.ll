; ModuleID = 'test/c/asm.c'
source_filename = "test/c/asm.c"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-linux-gnu"

; Function Attrs: nounwind uwtable
define dso_local i32 @swapped(i32 noundef %0) #0 {
  %2 = alloca i32, align 4
  %3 = alloca i32, align 4
  store i32 %0, ptr %2, align 4, !tbaa !5
  call void @llvm.lifetime.start.p0(i64 4, ptr %3) #2
  %4 = load i32, ptr %2, align 4, !tbaa !5
  %5 = call i32 asm "bswapl $0", "=r,0,~{dirflag},~{fpsr},~{flags}"(i32 %4) #3, !srcloc !9
  store i32 %5, ptr %3, align 4, !tbaa !5
  %6 = load i32, ptr %3, align 4, !tbaa !5
  call void @llvm.lifetime.end.p0(i64 4, ptr %3) #2
  ret i32 %6
}

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr captures(none)) #1

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr captures(none)) #1

; Function Attrs: nounwind uwtable
define dso_local i32 @swapped_twice(i32 noundef %0) #0 {
  %2 = alloca i32, align 4
  %3 = alloca i32, align 4
  %4 = alloca i32, align 4
  store i32 %0, ptr %2, align 4, !tbaa !5
  call void @llvm.lifetime.start.p0(i64 4, ptr %3) #2
  call void @llvm.lifetime.start.p0(i64 4, ptr %4) #2
  %5 = load i32, ptr %2, align 4, !tbaa !5
  %6 = call i32 asm "bswapl $0", "=r,0,~{dirflag},~{fpsr},~{flags}"(i32 %5) #3, !srcloc !10
  store i32 %6, ptr %3, align 4, !tbaa !5
  %7 = load i32, ptr %3, align 4, !tbaa !5
  %8 = call i32 asm "bswapl $0", "=r,0,~{dirflag},~{fpsr},~{flags}"(i32 %7) #3, !srcloc !11
  store i32 %8, ptr %4, align 4, !tbaa !5
  %9 = load i32, ptr %3, align 4, !tbaa !5
  %10 = load i32, ptr %4, align 4, !tbaa !5
  %11 = add nsw i32 %9, %10
  call void @llvm.lifetime.end.p0(i64 4, ptr %4) #2
  call void @llvm.lifetime.end.p0(i64 4, ptr %3) #2
  ret i32 %11
}

; Function Attrs: nounwind uwtable
define dso_local i32 @reread(ptr noundef %0) #0 {
  %2 = alloca ptr, align 8
  %3 = alloca i32, align 4
  %4 = alloca i32, align 4
  store ptr %0, ptr %2, align 8, !tbaa !12
  call void @llvm.lifetime.start.p0(i64 4, ptr %3) #2
  %5 = load ptr, ptr %2, align 8, !tbaa !12
  %6 = load i32, ptr %5, align 4, !tbaa !5
  store i32 %6, ptr %3, align 4, !tbaa !5
  call void asm sideeffect "", "~{memory},~{dirflag},~{fpsr},~{flags}"() #2, !srcloc !15
  call void @llvm.lifetime.start.p0(i64 4, ptr %4) #2
  %7 = load ptr, ptr %2, align 8, !tbaa !12
  %8 = load i32, ptr %7, align 4, !tbaa !5
  store i32 %8, ptr %4, align 4, !tbaa !5
  %9 = load i32, ptr %3, align 4, !tbaa !5
  %10 = mul nsw i32 %9, 100
  %11 = load i32, ptr %4, align 4, !tbaa !5
  %12 = add nsw i32 %10, %11
  call void @llvm.lifetime.end.p0(i64 4, ptr %4) #2
  call void @llvm.lifetime.end.p0(i64 4, ptr %3) #2
  ret i32 %12
}

; Function Attrs: nounwind uwtable
define dso_local i32 @barrier_sum(ptr noundef %0, i32 noundef %1, ptr noundef %2) #0 {
  %4 = alloca ptr, align 8
  %5 = alloca i32, align 4
  %6 = alloca ptr, align 8
  %7 = alloca i32, align 4
  %8 = alloca i32, align 4
  store ptr %0, ptr %4, align 8, !tbaa !12
  store i32 %1, ptr %5, align 4, !tbaa !5
  store ptr %2, ptr %6, align 8, !tbaa !12
  call void @llvm.lifetime.start.p0(i64 4, ptr %7) #2
  store i32 0, ptr %7, align 4, !tbaa !5
  call void @llvm.lifetime.start.p0(i64 4, ptr %8) #2
  store i32 0, ptr %8, align 4, !tbaa !5
  br label %9

9:                                                ; preds = %25, %3
  %10 = load i32, ptr %8, align 4, !tbaa !5
  %11 = load i32, ptr %5, align 4, !tbaa !5
  %12 = icmp slt i32 %10, %11
  br i1 %12, label %14, label %13

13:                                               ; preds = %9
  call void @llvm.lifetime.end.p0(i64 4, ptr %8) #2
  br label %28

14:                                               ; preds = %9
  %15 = load ptr, ptr %4, align 8, !tbaa !12
  %16 = load i32, ptr %8, align 4, !tbaa !5
  %17 = sext i32 %16 to i64
  %18 = getelementptr inbounds i32, ptr %15, i64 %17
  %19 = load i32, ptr %18, align 4, !tbaa !5
  %20 = load ptr, ptr %6, align 8, !tbaa !12
  %21 = load i32, ptr %20, align 4, !tbaa !5
  %22 = mul nsw i32 %19, %21
  %23 = load i32, ptr %7, align 4, !tbaa !5
  %24 = add nsw i32 %23, %22
  store i32 %24, ptr %7, align 4, !tbaa !5
  call void asm sideeffect "", "~{memory},~{dirflag},~{fpsr},~{flags}"() #2, !srcloc !16
  br label %25

25:                                               ; preds = %14
  %26 = load i32, ptr %8, align 4, !tbaa !5
  %27 = add nsw i32 %26, 1
  store i32 %27, ptr %8, align 4, !tbaa !5
  br label %9, !llvm.loop !17

28:                                               ; preds = %13
  %29 = load i32, ptr %7, align 4, !tbaa !5
  call void @llvm.lifetime.end.p0(i64 4, ptr %7) #2
  ret i32 %29
}

; Function Attrs: nounwind uwtable
define dso_local i32 @through_slot(i32 noundef %0) #0 {
  %2 = alloca i32, align 4
  %3 = alloca i32, align 4
  store i32 %0, ptr %2, align 4, !tbaa !5
  call void @llvm.lifetime.start.p0(i64 4, ptr %3) #2
  %4 = load i32, ptr %2, align 4, !tbaa !5
  store i32 %4, ptr %3, align 4, !tbaa !5
  call void asm sideeffect "addl $$7, $0", "=*m,*m,~{dirflag},~{fpsr},~{flags}"(ptr elementtype(i32) %3, ptr elementtype(i32) %3) #2, !srcloc !20
  %5 = load i32, ptr %3, align 4, !tbaa !5
  call void @llvm.lifetime.end.p0(i64 4, ptr %3) #2
  ret i32 %5
}

; Function Attrs: nounwind uwtable
define dso_local i32 @hidden(i32 noundef %0, i32 noundef %1) #0 {
  %3 = alloca i32, align 4
  %4 = alloca i32, align 4
  %5 = alloca i32, align 4
  store i32 %0, ptr %3, align 4, !tbaa !5
  store i32 %1, ptr %4, align 4, !tbaa !5
  call void @llvm.lifetime.start.p0(i64 4, ptr %5) #2
  %6 = load i32, ptr %3, align 4, !tbaa !5
  %7 = load i32, ptr %4, align 4, !tbaa !5
  %8 = add nsw i32 %6, %7
  %9 = mul nsw i32 %8, 2
  store i32 %9, ptr %5, align 4, !tbaa !5
  %10 = load i32, ptr %5, align 4, !tbaa !5
  %11 = call i32 asm "", "=r,0,~{dirflag},~{fpsr},~{flags}"(i32 %10) #3, !srcloc !21
  store i32 %11, ptr %5, align 4, !tbaa !5
  %12 = load i32, ptr %5, align 4, !tbaa !5
  %13 = load i32, ptr %5, align 4, !tbaa !5
  %14 = mul nsw i32 %13, 0
  %15 = add nsw i32 %12, %14
  %16 = load i32, ptr %4, align 4, !tbaa !5
  %17 = load i32, ptr %4, align 4, !tbaa !5
  %18 = sub nsw i32 %16, %17
  %19 = add nsw i32 %15, %18
  call void @llvm.lifetime.end.p0(i64 4, ptr %5) #2
  ret i32 %19
}

; Function Attrs: nounwind uwtable
define dso_local i32 @each_time(i32 noundef %0, i32 noundef %1) #0 {
  %3 = alloca i32, align 4
  %4 = alloca i32, align 4
  %5 = alloca i32, align 4
  %6 = alloca i32, align 4
  %7 = alloca i32, align 4
  store i32 %0, ptr %3, align 4, !tbaa !5
  store i32 %1, ptr %4, align 4, !tbaa !5
  call void @llvm.lifetime.start.p0(i64 4, ptr %5) #2
  store i32 0, ptr %5, align 4, !tbaa !5
  call void @llvm.lifetime.start.p0(i64 4, ptr %6) #2
  store i32 0, ptr %6, align 4, !tbaa !5
  br label %8

8:                                                ; preds = %20, %2
  %9 = load i32, ptr %6, align 4, !tbaa !5
  %10 = load i32, ptr %4, align 4, !tbaa !5
  %11 = icmp slt i32 %9, %10
  br i1 %11, label %13, label %12

12:                                               ; preds = %8
  call void @llvm.lifetime.end.p0(i64 4, ptr %6) #2
  br label %23

13:                                               ; preds = %8
  call void @llvm.lifetime.start.p0(i64 4, ptr %7) #2
  %14 = load i32, ptr %3, align 4, !tbaa !5
  %15 = call i32 asm "bswapl $0", "=r,0,~{dirflag},~{fpsr},~{flags}"(i32 %14) #3, !srcloc !22
  store i32 %15, ptr %7, align 4, !tbaa !5
  %16 = load i32, ptr %7, align 4, !tbaa !5
  %17 = ashr i32 %16, 24
  %18 = load i32, ptr %5, align 4, !tbaa !5
  %19 = add nsw i32 %18, %17
  store i32 %19, ptr %5, align 4, !tbaa !5
  call void @llvm.lifetime.end.p0(i64 4, ptr %7) #2
  br label %20

20:                                               ; preds = %13
  %21 = load i32, ptr %6, align 4, !tbaa !5
  %22 = add nsw i32 %21, 1
  store i32 %22, ptr %6, align 4, !tbaa !5
  br label %8, !llvm.loop !23

23:                                               ; preds = %12
  %24 = load i32, ptr %5, align 4, !tbaa !5
  call void @llvm.lifetime.end.p0(i64 4, ptr %5) #2
  ret i32 %24
}

; Function Attrs: nounwind uwtable
define dso_local i32 @both_kinds(i32 noundef %0) #0 {
  %2 = alloca i32, align 4
  %3 = alloca i32, align 4
  %4 = alloca i32, align 4
  store i32 %0, ptr %2, align 4, !tbaa !5
  call void @llvm.lifetime.start.p0(i64 4, ptr %3) #2
  %5 = load i32, ptr %2, align 4, !tbaa !5
  %6 = mul nsw i32 %5, 3
  store i32 %6, ptr %3, align 4, !tbaa !5
  call void @llvm.lifetime.start.p0(i64 4, ptr %4) #2
  %7 = load i32, ptr %2, align 4, !tbaa !5
  store i32 %7, ptr %4, align 4, !tbaa !5
  call void asm sideeffect "addl $$1, $0", "=*m,*m,~{dirflag},~{fpsr},~{flags}"(ptr elementtype(i32) %4, ptr elementtype(i32) %4) #2, !srcloc !24
  %8 = load i32, ptr %3, align 4, !tbaa !5
  %9 = load i32, ptr %4, align 4, !tbaa !5
  %10 = add nsw i32 %8, %9
  call void @llvm.lifetime.end.p0(i64 4, ptr %4) #2
  call void @llvm.lifetime.end.p0(i64 4, ptr %3) #2
  ret i32 %10
}

; Function Attrs: nounwind uwtable
define dso_local i32 @jumps_when_zero(i32 noundef %0) #0 {
  %2 = alloca i32, align 4
  %3 = alloca i32, align 4
  store i32 %0, ptr %3, align 4, !tbaa !5
  %4 = load i32, ptr %3, align 4, !tbaa !5
  callbr void asm sideeffect "testl $0, $0; je ${1:l}", "r,!i,~{cc},~{dirflag},~{fpsr},~{flags}"(i32 %4) #2
          to label %5 [label %6], !srcloc !25

5:                                                ; preds = %1
  store i32 1, ptr %2, align 4
  br label %7

6:                                                ; preds = %1
  store i32 0, ptr %2, align 4
  br label %7

7:                                                ; preds = %6, %5
  %8 = load i32, ptr %2, align 4
  ret i32 %8
}

; Function Attrs: nounwind uwtable
define dso_local i32 @swapped_or_low(i32 noundef %0) #0 {
  %2 = alloca i32, align 4
  %3 = alloca i32, align 4
  %4 = alloca i32, align 4
  %5 = alloca i32, align 4
  store i32 %0, ptr %3, align 4, !tbaa !5
  call void @llvm.lifetime.start.p0(i64 4, ptr %4) #2
  %6 = load i32, ptr %3, align 4, !tbaa !5
  %7 = callbr i32 asm "bswapl $0; testl $0, $0; js ${2:l}", "=r,0,!i,~{cc},~{dirflag},~{fpsr},~{flags}"(i32 %6) #3
          to label %8 [label %10], !srcloc !26

8:                                                ; preds = %1
  store i32 %7, ptr %4, align 4, !tbaa !5
  %9 = load i32, ptr %4, align 4, !tbaa !5
  store i32 %9, ptr %2, align 4
  store i32 1, ptr %5, align 4
  br label %14

10:                                               ; preds = %1
  store i32 %7, ptr %4, align 4, !tbaa !5
  br label %11

11:                                               ; preds = %10
  %12 = load i32, ptr %4, align 4, !tbaa !5
  %13 = ashr i32 %12, 24
  store i32 %13, ptr %2, align 4
  store i32 1, ptr %5, align 4
  br label %14

14:                                               ; preds = %11, %8
  call void @llvm.lifetime.end.p0(i64 4, ptr %4) #2
  %15 = load i32, ptr %2, align 4
  ret i32 %15
}

; Function Attrs: nounwind uwtable
define dso_local i32 @counted_jumps(ptr noundef %0, i32 noundef %1) #0 {
  %3 = alloca ptr, align 8
  %4 = alloca i32, align 4
  %5 = alloca i32, align 4
  %6 = alloca i32, align 4
  store ptr %0, ptr %3, align 8, !tbaa !12
  store i32 %1, ptr %4, align 4, !tbaa !5
  call void @llvm.lifetime.start.p0(i64 4, ptr %5) #2
  store i32 0, ptr %5, align 4, !tbaa !5
  call void @llvm.lifetime.start.p0(i64 4, ptr %6) #2
  store i32 0, ptr %6, align 4, !tbaa !5
  br label %7

7:                                                ; preds = %34, %2
  %8 = load i32, ptr %6, align 4, !tbaa !5
  %9 = load i32, ptr %4, align 4, !tbaa !5
  %10 = icmp slt i32 %8, %9
  br i1 %10, label %12, label %11

11:                                               ; preds = %7
  call void @llvm.lifetime.end.p0(i64 4, ptr %6) #2
  br label %37

12:                                               ; preds = %7
  %13 = load ptr, ptr %3, align 8, !tbaa !12
  %14 = load i32, ptr %6, align 4, !tbaa !5
  %15 = sext i32 %14 to i64
  %16 = getelementptr inbounds i32, ptr %13, i64 %15
  %17 = load i32, ptr %16, align 4, !tbaa !5
  callbr void asm sideeffect "cmpl $$0, $0; jl ${1:l}", "r,!i,~{cc},~{dirflag},~{fpsr},~{flags}"(i32 %17) #2
          to label %18 [label %26], !srcloc !27

18:                                               ; preds = %12
  %19 = load ptr, ptr %3, align 8, !tbaa !12
  %20 = load i32, ptr %6, align 4, !tbaa !5
  %21 = sext i32 %20 to i64
  %22 = getelementptr inbounds i32, ptr %19, i64 %21
  %23 = load i32, ptr %22, align 4, !tbaa !5
  %24 = load i32, ptr %5, align 4, !tbaa !5
  %25 = add nsw i32 %24, %23
  store i32 %25, ptr %5, align 4, !tbaa !5
  br label %34

26:                                               ; preds = %12
  %27 = load ptr, ptr %3, align 8, !tbaa !12
  %28 = load i32, ptr %6, align 4, !tbaa !5
  %29 = sext i32 %28 to i64
  %30 = getelementptr inbounds i32, ptr %27, i64 %29
  %31 = load i32, ptr %30, align 4, !tbaa !5
  %32 = load i32, ptr %5, align 4, !tbaa !5
  %33 = sub nsw i32 %32, %31
  store i32 %33, ptr %5, align 4, !tbaa !5
  br label %34

34:                                               ; preds = %26, %18
  %35 = load i32, ptr %6, align 4, !tbaa !5
  %36 = add nsw i32 %35, 1
  store i32 %36, ptr %6, align 4, !tbaa !5
  br label %7, !llvm.loop !28

37:                                               ; preds = %11
  %38 = load i32, ptr %5, align 4, !tbaa !5
  call void @llvm.lifetime.end.p0(i64 4, ptr %5) #2
  ret i32 %38
}

; Function Attrs: nounwind uwtable
define dso_local i32 @held_and_jumped(i32 noundef %0) #0 {
  %2 = alloca i32, align 4
  %3 = alloca i32, align 4
  %4 = alloca i32, align 4
  %5 = alloca i32, align 4
  store i32 %0, ptr %3, align 4, !tbaa !5
  call void @llvm.lifetime.start.p0(i64 4, ptr %4) #2
  %6 = load i32, ptr %3, align 4, !tbaa !5
  store i32 %6, ptr %4, align 4, !tbaa !5
  callbr void asm "addl $$7, $0; jns ${2:l}", "=*m,*m,!i,~{cc},~{dirflag},~{fpsr},~{flags}"(ptr elementtype(i32) %4, ptr elementtype(i32) %4) #2
          to label %7 [label %10], !srcloc !29

7:                                                ; preds = %1
  %8 = load i32, ptr %4, align 4, !tbaa !5
  %9 = sub nsw i32 0, %8
  store i32 %9, ptr %2, align 4
  store i32 1, ptr %5, align 4
  br label %12

10:                                               ; preds = %1
  %11 = load i32, ptr %4, align 4, !tbaa !5
  store i32 %11, ptr %2, align 4
  store i32 1, ptr %5, align 4
  br label %12

12:                                               ; preds = %10, %7
  call void @llvm.lifetime.end.p0(i64 4, ptr %4) #2
  %13 = load i32, ptr %2, align 4
  ret i32 %13
}

attributes #0 = { nounwind uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #1 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { nounwind }
attributes #3 = { nounwind memory(none) }

!llvm.module.flags = !{!0, !1, !2, !3}
!llvm.ident = !{!4}

!0 = !{i32 1, !"wchar_size", i32 4}
!1 = !{i32 8, !"PIC Level", i32 2}
!2 = !{i32 7, !"PIE Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{!"Ubuntu clang version 21.1.8 (6ubuntu1)"}
!5 = !{!6, !6, i64 0}
!6 = !{!"int", !7, i64 0}
!7 = !{!"omnipotent char", !8, i64 0}
!8 = !{!"Simple C/C++ TBAA"}
!9 = !{i64 1244}
!10 = !{i64 1545}
!11 = !{i64 1588}
!12 = !{!13, !13, i64 0}
!13 = !{!"p1 int", !14, i64 0}
!14 = !{!"any pointer", !7, i64 0}
!15 = !{i64 1844}
!16 = !{i64 2232}
!17 = distinct !{!17, !18, !19}
!18 = !{!"llvm.loop.mustprogress"}
!19 = !{!"llvm.loop.unroll.disable"}
!20 = !{i64 2442}
!21 = !{i64 2757}
!22 = !{i64 3558}
!23 = distinct !{!23, !18, !19}
!24 = !{i64 3849}
!25 = !{i64 4328}
!26 = !{i64 4728}
!27 = !{i64 5327}
!28 = distinct !{!28, !18, !19}
!29 = !{i64 5749}

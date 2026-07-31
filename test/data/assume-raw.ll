; ModuleID = 'test/c/assume.c'
source_filename = "test/c/assume.c"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-linux-gnu"

; Function Attrs: nounwind uwtable
define dso_local i32 @sum_aligned(ptr noundef %0, i32 noundef %1) #0 {
  %3 = alloca ptr, align 8
  %4 = alloca i32, align 4
  %5 = alloca ptr, align 8
  %6 = alloca i32, align 4
  %7 = alloca i32, align 4
  store ptr %0, ptr %3, align 8, !tbaa !5
  store i32 %1, ptr %4, align 4, !tbaa !10
  call void @llvm.lifetime.start.p0(i64 8, ptr %5) #5
  %8 = load ptr, ptr %3, align 8, !tbaa !5
  call void @llvm.assume(i1 true) [ "align"(ptr %8, i64 16) ]
  store ptr %8, ptr %5, align 8, !tbaa !5
  call void @llvm.lifetime.start.p0(i64 4, ptr %6) #5
  store i32 0, ptr %6, align 4, !tbaa !10
  call void @llvm.lifetime.start.p0(i64 4, ptr %7) #5
  store i32 0, ptr %7, align 4, !tbaa !10
  br label %9

9:                                                ; preds = %22, %2
  %10 = load i32, ptr %7, align 4, !tbaa !10
  %11 = load i32, ptr %4, align 4, !tbaa !10
  %12 = icmp slt i32 %10, %11
  br i1 %12, label %14, label %13

13:                                               ; preds = %9
  call void @llvm.lifetime.end.p0(i64 4, ptr %7) #5
  br label %25

14:                                               ; preds = %9
  %15 = load ptr, ptr %5, align 8, !tbaa !5
  %16 = load i32, ptr %7, align 4, !tbaa !10
  %17 = sext i32 %16 to i64
  %18 = getelementptr inbounds i32, ptr %15, i64 %17
  %19 = load i32, ptr %18, align 4, !tbaa !10
  %20 = load i32, ptr %6, align 4, !tbaa !10
  %21 = add nsw i32 %20, %19
  store i32 %21, ptr %6, align 4, !tbaa !10
  br label %22

22:                                               ; preds = %14
  %23 = load i32, ptr %7, align 4, !tbaa !10
  %24 = add nsw i32 %23, 1
  store i32 %24, ptr %7, align 4, !tbaa !10
  br label %9, !llvm.loop !12

25:                                               ; preds = %13
  %26 = load i32, ptr %6, align 4, !tbaa !10
  call void @llvm.lifetime.end.p0(i64 4, ptr %6) #5
  call void @llvm.lifetime.end.p0(i64 8, ptr %5) #5
  ret i32 %26
}

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr captures(none)) #1

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(inaccessiblemem: write)
declare void @llvm.assume(i1 noundef) #2

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr captures(none)) #1

; Function Attrs: nounwind uwtable
define dso_local i32 @sum_plain(ptr noundef %0, i32 noundef %1) #0 {
  %3 = alloca ptr, align 8
  %4 = alloca i32, align 4
  %5 = alloca i32, align 4
  %6 = alloca i32, align 4
  store ptr %0, ptr %3, align 8, !tbaa !5
  store i32 %1, ptr %4, align 4, !tbaa !10
  call void @llvm.lifetime.start.p0(i64 4, ptr %5) #5
  store i32 0, ptr %5, align 4, !tbaa !10
  call void @llvm.lifetime.start.p0(i64 4, ptr %6) #5
  store i32 0, ptr %6, align 4, !tbaa !10
  br label %7

7:                                                ; preds = %20, %2
  %8 = load i32, ptr %6, align 4, !tbaa !10
  %9 = load i32, ptr %4, align 4, !tbaa !10
  %10 = icmp slt i32 %8, %9
  br i1 %10, label %12, label %11

11:                                               ; preds = %7
  call void @llvm.lifetime.end.p0(i64 4, ptr %6) #5
  br label %23

12:                                               ; preds = %7
  %13 = load ptr, ptr %3, align 8, !tbaa !5
  %14 = load i32, ptr %6, align 4, !tbaa !10
  %15 = sext i32 %14 to i64
  %16 = getelementptr inbounds i32, ptr %13, i64 %15
  %17 = load i32, ptr %16, align 4, !tbaa !10
  %18 = load i32, ptr %5, align 4, !tbaa !10
  %19 = add nsw i32 %18, %17
  store i32 %19, ptr %5, align 4, !tbaa !10
  br label %20

20:                                               ; preds = %12
  %21 = load i32, ptr %6, align 4, !tbaa !10
  %22 = add nsw i32 %21, 1
  store i32 %22, ptr %6, align 4, !tbaa !10
  br label %7, !llvm.loop !15

23:                                               ; preds = %11
  %24 = load i32, ptr %5, align 4, !tbaa !10
  call void @llvm.lifetime.end.p0(i64 4, ptr %5) #5
  ret i32 %24
}

; Function Attrs: nounwind uwtable
define dso_local i32 @sum_each(ptr noundef %0, i32 noundef %1) #0 {
  %3 = alloca ptr, align 8
  %4 = alloca i32, align 4
  %5 = alloca i32, align 4
  %6 = alloca i32, align 4
  %7 = alloca ptr, align 8
  store ptr %0, ptr %3, align 8, !tbaa !5
  store i32 %1, ptr %4, align 4, !tbaa !10
  call void @llvm.lifetime.start.p0(i64 4, ptr %5) #5
  store i32 0, ptr %5, align 4, !tbaa !10
  call void @llvm.lifetime.start.p0(i64 4, ptr %6) #5
  store i32 0, ptr %6, align 4, !tbaa !10
  br label %8

8:                                                ; preds = %22, %2
  %9 = load i32, ptr %6, align 4, !tbaa !10
  %10 = load i32, ptr %4, align 4, !tbaa !10
  %11 = icmp slt i32 %9, %10
  br i1 %11, label %13, label %12

12:                                               ; preds = %8
  call void @llvm.lifetime.end.p0(i64 4, ptr %6) #5
  br label %25

13:                                               ; preds = %8
  call void @llvm.lifetime.start.p0(i64 8, ptr %7) #5
  %14 = load ptr, ptr %3, align 8, !tbaa !5
  %15 = load i32, ptr %6, align 4, !tbaa !10
  %16 = sext i32 %15 to i64
  %17 = getelementptr inbounds i32, ptr %14, i64 %16
  call void @llvm.assume(i1 true) [ "align"(ptr %17, i64 4) ]
  store ptr %17, ptr %7, align 8, !tbaa !5
  %18 = load ptr, ptr %7, align 8, !tbaa !5
  %19 = load i32, ptr %18, align 4, !tbaa !10
  %20 = load i32, ptr %5, align 4, !tbaa !10
  %21 = add nsw i32 %20, %19
  store i32 %21, ptr %5, align 4, !tbaa !10
  call void @llvm.lifetime.end.p0(i64 8, ptr %7) #5
  br label %22

22:                                               ; preds = %13
  %23 = load i32, ptr %6, align 4, !tbaa !10
  %24 = add nsw i32 %23, 1
  store i32 %24, ptr %6, align 4, !tbaa !10
  br label %8, !llvm.loop !16

25:                                               ; preds = %12
  %26 = load i32, ptr %5, align 4, !tbaa !10
  call void @llvm.lifetime.end.p0(i64 4, ptr %5) #5
  ret i32 %26
}

; Function Attrs: nounwind uwtable
define dso_local void @scale_aligned(ptr noundef %0, ptr noundef %1, i32 noundef %2, i32 noundef %3) #0 {
  %5 = alloca ptr, align 8
  %6 = alloca ptr, align 8
  %7 = alloca i32, align 4
  %8 = alloca i32, align 4
  %9 = alloca ptr, align 8
  %10 = alloca ptr, align 8
  %11 = alloca i32, align 4
  store ptr %0, ptr %5, align 8, !tbaa !5
  store ptr %1, ptr %6, align 8, !tbaa !5
  store i32 %2, ptr %7, align 4, !tbaa !10
  store i32 %3, ptr %8, align 4, !tbaa !10
  call void @llvm.lifetime.start.p0(i64 8, ptr %9) #5
  %12 = load ptr, ptr %5, align 8, !tbaa !5
  call void @llvm.assume(i1 true) [ "align"(ptr %12, i64 16) ]
  store ptr %12, ptr %9, align 8, !tbaa !5
  call void @llvm.lifetime.start.p0(i64 8, ptr %10) #5
  %13 = load ptr, ptr %6, align 8, !tbaa !5
  call void @llvm.assume(i1 true) [ "align"(ptr %13, i64 16) ]
  store ptr %13, ptr %10, align 8, !tbaa !5
  call void @llvm.lifetime.start.p0(i64 4, ptr %11) #5
  store i32 0, ptr %11, align 4, !tbaa !10
  br label %14

14:                                               ; preds = %31, %4
  %15 = load i32, ptr %11, align 4, !tbaa !10
  %16 = load i32, ptr %7, align 4, !tbaa !10
  %17 = icmp slt i32 %15, %16
  br i1 %17, label %19, label %18

18:                                               ; preds = %14
  call void @llvm.lifetime.end.p0(i64 4, ptr %11) #5
  br label %34

19:                                               ; preds = %14
  %20 = load ptr, ptr %10, align 8, !tbaa !5
  %21 = load i32, ptr %11, align 4, !tbaa !10
  %22 = sext i32 %21 to i64
  %23 = getelementptr inbounds i32, ptr %20, i64 %22
  %24 = load i32, ptr %23, align 4, !tbaa !10
  %25 = load i32, ptr %8, align 4, !tbaa !10
  %26 = mul nsw i32 %24, %25
  %27 = load ptr, ptr %9, align 8, !tbaa !5
  %28 = load i32, ptr %11, align 4, !tbaa !10
  %29 = sext i32 %28 to i64
  %30 = getelementptr inbounds i32, ptr %27, i64 %29
  store i32 %26, ptr %30, align 4, !tbaa !10
  br label %31

31:                                               ; preds = %19
  %32 = load i32, ptr %11, align 4, !tbaa !10
  %33 = add nsw i32 %32, 1
  store i32 %33, ptr %11, align 4, !tbaa !10
  br label %14, !llvm.loop !17

34:                                               ; preds = %18
  call void @llvm.lifetime.end.p0(i64 8, ptr %10) #5
  call void @llvm.lifetime.end.p0(i64 8, ptr %9) #5
  ret void
}

; Function Attrs: nounwind uwtable
define dso_local i32 @dot_aligned(ptr noundef %0, ptr noundef %1, i32 noundef %2) #0 {
  %4 = alloca ptr, align 8
  %5 = alloca ptr, align 8
  %6 = alloca i32, align 4
  %7 = alloca ptr, align 8
  %8 = alloca ptr, align 8
  %9 = alloca i32, align 4
  %10 = alloca i32, align 4
  store ptr %0, ptr %4, align 8, !tbaa !5
  store ptr %1, ptr %5, align 8, !tbaa !5
  store i32 %2, ptr %6, align 4, !tbaa !10
  call void @llvm.lifetime.start.p0(i64 8, ptr %7) #5
  %11 = load ptr, ptr %4, align 8, !tbaa !5
  call void @llvm.assume(i1 true) [ "align"(ptr %11, i64 16) ]
  store ptr %11, ptr %7, align 8, !tbaa !5
  call void @llvm.lifetime.start.p0(i64 8, ptr %8) #5
  %12 = load ptr, ptr %5, align 8, !tbaa !5
  call void @llvm.assume(i1 true) [ "align"(ptr %12, i64 16) ]
  store ptr %12, ptr %8, align 8, !tbaa !5
  call void @llvm.lifetime.start.p0(i64 4, ptr %9) #5
  store i32 0, ptr %9, align 4, !tbaa !10
  call void @llvm.lifetime.start.p0(i64 4, ptr %10) #5
  store i32 0, ptr %10, align 4, !tbaa !10
  br label %13

13:                                               ; preds = %32, %3
  %14 = load i32, ptr %10, align 4, !tbaa !10
  %15 = load i32, ptr %6, align 4, !tbaa !10
  %16 = icmp slt i32 %14, %15
  br i1 %16, label %18, label %17

17:                                               ; preds = %13
  call void @llvm.lifetime.end.p0(i64 4, ptr %10) #5
  br label %35

18:                                               ; preds = %13
  %19 = load ptr, ptr %7, align 8, !tbaa !5
  %20 = load i32, ptr %10, align 4, !tbaa !10
  %21 = sext i32 %20 to i64
  %22 = getelementptr inbounds i32, ptr %19, i64 %21
  %23 = load i32, ptr %22, align 4, !tbaa !10
  %24 = load ptr, ptr %8, align 8, !tbaa !5
  %25 = load i32, ptr %10, align 4, !tbaa !10
  %26 = sext i32 %25 to i64
  %27 = getelementptr inbounds i32, ptr %24, i64 %26
  %28 = load i32, ptr %27, align 4, !tbaa !10
  %29 = mul nsw i32 %23, %28
  %30 = load i32, ptr %9, align 4, !tbaa !10
  %31 = add nsw i32 %30, %29
  store i32 %31, ptr %9, align 4, !tbaa !10
  br label %32

32:                                               ; preds = %18
  %33 = load i32, ptr %10, align 4, !tbaa !10
  %34 = add nsw i32 %33, 1
  store i32 %34, ptr %10, align 4, !tbaa !10
  br label %13, !llvm.loop !18

35:                                               ; preds = %17
  %36 = load i32, ptr %9, align 4, !tbaa !10
  call void @llvm.lifetime.end.p0(i64 4, ptr %9) #5
  call void @llvm.lifetime.end.p0(i64 8, ptr %8) #5
  call void @llvm.lifetime.end.p0(i64 8, ptr %7) #5
  ret i32 %36
}

; Function Attrs: nounwind uwtable
define dso_local i32 @halved(i32 noundef %0) #0 {
  %2 = alloca i32, align 4
  store i32 %0, ptr %2, align 4, !tbaa !10
  %3 = load i32, ptr %2, align 4, !tbaa !10
  %4 = icmp sgt i32 %3, 0
  call void @llvm.assume(i1 %4)
  %5 = load i32, ptr %2, align 4, !tbaa !10
  %6 = sdiv i32 %5, 2
  ret i32 %6
}

; Function Attrs: nounwind uwtable
define dso_local i32 @through_call(ptr noundef %0, i32 noundef %1) #0 {
  %3 = alloca ptr, align 8
  %4 = alloca i32, align 4
  %5 = alloca ptr, align 8
  store ptr %0, ptr %3, align 8, !tbaa !5
  store i32 %1, ptr %4, align 4, !tbaa !10
  call void @llvm.lifetime.start.p0(i64 8, ptr %5) #5
  %6 = load ptr, ptr %3, align 8, !tbaa !5
  call void @llvm.assume(i1 true) [ "align"(ptr %6, i64 16) ]
  store ptr %6, ptr %5, align 8, !tbaa !5
  %7 = load ptr, ptr %5, align 8, !tbaa !5
  %8 = load i32, ptr %4, align 4, !tbaa !10
  %9 = call i32 @sum_plain(ptr noundef %7, i32 noundef %8)
  %10 = load ptr, ptr %5, align 8, !tbaa !5
  %11 = load i32, ptr %4, align 4, !tbaa !10
  %12 = call i32 @sum_aligned(ptr noundef %10, i32 noundef %11)
  %13 = add nsw i32 %9, %12
  call void @llvm.lifetime.end.p0(i64 8, ptr %5) #5
  ret i32 %13
}

; Function Attrs: nounwind uwtable
define dso_local i32 @local_aligned(i32 noundef %0) #0 {
  %2 = alloca i32, align 4
  %3 = alloca i32, align 4
  %4 = alloca ptr, align 8
  %5 = alloca i32, align 4
  %6 = alloca ptr, align 8
  %7 = alloca i32, align 4
  %8 = alloca i32, align 4
  %9 = alloca i32, align 4
  store i32 %0, ptr %3, align 4, !tbaa !10
  call void @llvm.lifetime.start.p0(i64 8, ptr %4) #5
  %10 = call noalias align 16 ptr @aligned_alloc(i64 noundef 16, i64 noundef 256) #6
  store ptr %10, ptr %4, align 8, !tbaa !5
  %11 = load ptr, ptr %4, align 8, !tbaa !5
  %12 = icmp ne ptr %11, null
  br i1 %12, label %14, label %13

13:                                               ; preds = %1
  store i32 0, ptr %2, align 4
  store i32 1, ptr %5, align 4
  br label %50

14:                                               ; preds = %1
  call void @llvm.lifetime.start.p0(i64 8, ptr %6) #5
  %15 = load ptr, ptr %4, align 8, !tbaa !5
  call void @llvm.assume(i1 true) [ "align"(ptr %15, i64 16) ]
  store ptr %15, ptr %6, align 8, !tbaa !5
  call void @llvm.lifetime.start.p0(i64 4, ptr %7) #5
  store i32 0, ptr %7, align 4, !tbaa !10
  br label %16

16:                                               ; preds = %28, %14
  %17 = load i32, ptr %7, align 4, !tbaa !10
  %18 = icmp slt i32 %17, 64
  br i1 %18, label %20, label %19

19:                                               ; preds = %16
  store i32 2, ptr %5, align 4
  call void @llvm.lifetime.end.p0(i64 4, ptr %7) #5
  br label %31

20:                                               ; preds = %16
  %21 = load i32, ptr %7, align 4, !tbaa !10
  %22 = load i32, ptr %3, align 4, !tbaa !10
  %23 = mul nsw i32 %21, %22
  %24 = load ptr, ptr %6, align 8, !tbaa !5
  %25 = load i32, ptr %7, align 4, !tbaa !10
  %26 = sext i32 %25 to i64
  %27 = getelementptr inbounds i32, ptr %24, i64 %26
  store i32 %23, ptr %27, align 4, !tbaa !10
  br label %28

28:                                               ; preds = %20
  %29 = load i32, ptr %7, align 4, !tbaa !10
  %30 = add nsw i32 %29, 1
  store i32 %30, ptr %7, align 4, !tbaa !10
  br label %16, !llvm.loop !19

31:                                               ; preds = %19
  call void @llvm.lifetime.start.p0(i64 4, ptr %8) #5
  store i32 0, ptr %8, align 4, !tbaa !10
  call void @llvm.lifetime.start.p0(i64 4, ptr %9) #5
  store i32 0, ptr %9, align 4, !tbaa !10
  br label %32

32:                                               ; preds = %44, %31
  %33 = load i32, ptr %9, align 4, !tbaa !10
  %34 = icmp slt i32 %33, 64
  br i1 %34, label %36, label %35

35:                                               ; preds = %32
  store i32 5, ptr %5, align 4
  call void @llvm.lifetime.end.p0(i64 4, ptr %9) #5
  br label %47

36:                                               ; preds = %32
  %37 = load ptr, ptr %6, align 8, !tbaa !5
  %38 = load i32, ptr %9, align 4, !tbaa !10
  %39 = sext i32 %38 to i64
  %40 = getelementptr inbounds i32, ptr %37, i64 %39
  %41 = load i32, ptr %40, align 4, !tbaa !10
  %42 = load i32, ptr %8, align 4, !tbaa !10
  %43 = add nsw i32 %42, %41
  store i32 %43, ptr %8, align 4, !tbaa !10
  br label %44

44:                                               ; preds = %36
  %45 = load i32, ptr %9, align 4, !tbaa !10
  %46 = add nsw i32 %45, 1
  store i32 %46, ptr %9, align 4, !tbaa !10
  br label %32, !llvm.loop !20

47:                                               ; preds = %35
  %48 = load ptr, ptr %4, align 8, !tbaa !5
  call void @free(ptr noundef %48) #5
  %49 = load i32, ptr %8, align 4, !tbaa !10
  store i32 %49, ptr %2, align 4
  store i32 1, ptr %5, align 4
  call void @llvm.lifetime.end.p0(i64 4, ptr %8) #5
  call void @llvm.lifetime.end.p0(i64 8, ptr %6) #5
  br label %50

50:                                               ; preds = %47, %13
  call void @llvm.lifetime.end.p0(i64 8, ptr %4) #5
  %51 = load i32, ptr %2, align 4
  ret i32 %51
}

; Function Attrs: nounwind allocsize(1)
declare noalias ptr @aligned_alloc(i64 noundef, i64 noundef) #3

; Function Attrs: nounwind
declare void @free(ptr noundef) #4

attributes #0 = { nounwind uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #1 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { nocallback nofree nosync nounwind willreturn memory(inaccessiblemem: write) }
attributes #3 = { nounwind allocsize(1) "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #4 = { nounwind "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #5 = { nounwind }
attributes #6 = { nounwind allocsize(1) }

!llvm.module.flags = !{!0, !1, !2, !3}
!llvm.ident = !{!4}

!0 = !{i32 1, !"wchar_size", i32 4}
!1 = !{i32 8, !"PIC Level", i32 2}
!2 = !{i32 7, !"PIE Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{!"Ubuntu clang version 21.1.8 (6ubuntu1)"}
!5 = !{!6, !6, i64 0}
!6 = !{!"p1 int", !7, i64 0}
!7 = !{!"any pointer", !8, i64 0}
!8 = !{!"omnipotent char", !9, i64 0}
!9 = !{!"Simple C/C++ TBAA"}
!10 = !{!11, !11, i64 0}
!11 = !{!"int", !8, i64 0}
!12 = distinct !{!12, !13, !14}
!13 = !{!"llvm.loop.mustprogress"}
!14 = !{!"llvm.loop.unroll.disable"}
!15 = distinct !{!15, !13, !14}
!16 = distinct !{!16, !13, !14}
!17 = distinct !{!17, !13, !14}
!18 = distinct !{!18, !13, !14}
!19 = distinct !{!19, !13, !14}
!20 = distinct !{!20, !13, !14}

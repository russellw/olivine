; ModuleID = 'test/c/bytes.c'
source_filename = "test/c/bytes.c"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-linux-gnu"

; Function Attrs: nounwind uwtable
define dso_local void @scale_apart(ptr noalias noundef %0, ptr noalias noundef %1, i32 noundef %2, ptr noalias noundef %3) #0 {
  %5 = alloca ptr, align 8
  %6 = alloca ptr, align 8
  %7 = alloca i32, align 4
  %8 = alloca ptr, align 8
  %9 = alloca i32, align 4
  store ptr %0, ptr %5, align 8, !tbaa !5
  store ptr %1, ptr %6, align 8, !tbaa !5
  store i32 %2, ptr %7, align 4, !tbaa !10
  store ptr %3, ptr %8, align 8, !tbaa !5
  call void @llvm.lifetime.start.p0(i64 4, ptr %9) #2
  store i32 0, ptr %9, align 4, !tbaa !10
  br label %10

10:                                               ; preds = %28, %4
  %11 = load i32, ptr %9, align 4, !tbaa !10
  %12 = load i32, ptr %7, align 4, !tbaa !10
  %13 = icmp slt i32 %11, %12
  br i1 %13, label %15, label %14

14:                                               ; preds = %10
  call void @llvm.lifetime.end.p0(i64 4, ptr %9) #2
  br label %31

15:                                               ; preds = %10
  %16 = load ptr, ptr %6, align 8, !tbaa !5
  %17 = load i32, ptr %9, align 4, !tbaa !10
  %18 = sext i32 %17 to i64
  %19 = getelementptr inbounds i32, ptr %16, i64 %18
  %20 = load i32, ptr %19, align 4, !tbaa !10
  %21 = load ptr, ptr %8, align 8, !tbaa !5
  %22 = load i32, ptr %21, align 4, !tbaa !10
  %23 = mul nsw i32 %20, %22
  %24 = load ptr, ptr %5, align 8, !tbaa !5
  %25 = load i32, ptr %9, align 4, !tbaa !10
  %26 = sext i32 %25 to i64
  %27 = getelementptr inbounds i32, ptr %24, i64 %26
  store i32 %23, ptr %27, align 4, !tbaa !10
  br label %28

28:                                               ; preds = %15
  %29 = load i32, ptr %9, align 4, !tbaa !10
  %30 = add nsw i32 %29, 1
  store i32 %30, ptr %9, align 4, !tbaa !10
  br label %10, !llvm.loop !12

31:                                               ; preds = %14
  ret void
}

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr captures(none)) #1

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr captures(none)) #1

; Function Attrs: nounwind uwtable
define dso_local void @scale_together(ptr noundef %0, ptr noundef %1, i32 noundef %2, ptr noundef %3) #0 {
  %5 = alloca ptr, align 8
  %6 = alloca ptr, align 8
  %7 = alloca i32, align 4
  %8 = alloca ptr, align 8
  %9 = alloca i32, align 4
  store ptr %0, ptr %5, align 8, !tbaa !5
  store ptr %1, ptr %6, align 8, !tbaa !5
  store i32 %2, ptr %7, align 4, !tbaa !10
  store ptr %3, ptr %8, align 8, !tbaa !5
  call void @llvm.lifetime.start.p0(i64 4, ptr %9) #2
  store i32 0, ptr %9, align 4, !tbaa !10
  br label %10

10:                                               ; preds = %28, %4
  %11 = load i32, ptr %9, align 4, !tbaa !10
  %12 = load i32, ptr %7, align 4, !tbaa !10
  %13 = icmp slt i32 %11, %12
  br i1 %13, label %15, label %14

14:                                               ; preds = %10
  call void @llvm.lifetime.end.p0(i64 4, ptr %9) #2
  br label %31

15:                                               ; preds = %10
  %16 = load ptr, ptr %6, align 8, !tbaa !5
  %17 = load i32, ptr %9, align 4, !tbaa !10
  %18 = sext i32 %17 to i64
  %19 = getelementptr inbounds i32, ptr %16, i64 %18
  %20 = load i32, ptr %19, align 4, !tbaa !10
  %21 = load ptr, ptr %8, align 8, !tbaa !5
  %22 = load i32, ptr %21, align 4, !tbaa !10
  %23 = mul nsw i32 %20, %22
  %24 = load ptr, ptr %5, align 8, !tbaa !5
  %25 = load i32, ptr %9, align 4, !tbaa !10
  %26 = sext i32 %25 to i64
  %27 = getelementptr inbounds i32, ptr %24, i64 %26
  store i32 %23, ptr %27, align 4, !tbaa !10
  br label %28

28:                                               ; preds = %15
  %29 = load i32, ptr %9, align 4, !tbaa !10
  %30 = add nsw i32 %29, 1
  store i32 %30, ptr %9, align 4, !tbaa !10
  br label %10, !llvm.loop !15

31:                                               ; preds = %14
  ret void
}

; Function Attrs: nounwind uwtable
define dso_local i32 @checksum(ptr noundef %0, i32 noundef %1) #0 {
  %3 = alloca ptr, align 8
  %4 = alloca i32, align 4
  %5 = alloca i32, align 4
  %6 = alloca i32, align 4
  store ptr %0, ptr %3, align 8, !tbaa !16
  store i32 %1, ptr %4, align 4, !tbaa !10
  call void @llvm.lifetime.start.p0(i64 4, ptr %5) #2
  store i32 0, ptr %5, align 4, !tbaa !10
  call void @llvm.lifetime.start.p0(i64 4, ptr %6) #2
  store i32 0, ptr %6, align 4, !tbaa !10
  br label %7

7:                                                ; preds = %22, %2
  %8 = load i32, ptr %6, align 4, !tbaa !10
  %9 = load i32, ptr %4, align 4, !tbaa !10
  %10 = icmp slt i32 %8, %9
  br i1 %10, label %12, label %11

11:                                               ; preds = %7
  call void @llvm.lifetime.end.p0(i64 4, ptr %6) #2
  br label %25

12:                                               ; preds = %7
  %13 = load i32, ptr %5, align 4, !tbaa !10
  %14 = mul i32 %13, 31
  %15 = load ptr, ptr %3, align 8, !tbaa !16
  %16 = load i32, ptr %6, align 4, !tbaa !10
  %17 = sext i32 %16 to i64
  %18 = getelementptr inbounds i8, ptr %15, i64 %17
  %19 = load i8, ptr %18, align 1, !tbaa !18
  %20 = zext i8 %19 to i32
  %21 = add i32 %14, %20
  store i32 %21, ptr %5, align 4, !tbaa !10
  br label %22

22:                                               ; preds = %12
  %23 = load i32, ptr %6, align 4, !tbaa !10
  %24 = add nsw i32 %23, 1
  store i32 %24, ptr %6, align 4, !tbaa !10
  br label %7, !llvm.loop !19

25:                                               ; preds = %11
  %26 = load i32, ptr %5, align 4, !tbaa !10
  call void @llvm.lifetime.end.p0(i64 4, ptr %5) #2
  ret i32 %26
}

; Function Attrs: nounwind uwtable
define dso_local i32 @span(ptr noundef %0, i32 noundef %1) #0 {
  %3 = alloca ptr, align 8
  %4 = alloca i32, align 4
  %5 = alloca i32, align 4
  %6 = alloca i32, align 4
  %7 = alloca i32, align 4
  store ptr %0, ptr %3, align 8, !tbaa !16
  store i32 %1, ptr %4, align 4, !tbaa !10
  call void @llvm.lifetime.start.p0(i64 4, ptr %5) #2
  store i32 127, ptr %5, align 4, !tbaa !10
  call void @llvm.lifetime.start.p0(i64 4, ptr %6) #2
  store i32 -128, ptr %6, align 4, !tbaa !10
  call void @llvm.lifetime.start.p0(i64 4, ptr %7) #2
  store i32 0, ptr %7, align 4, !tbaa !10
  br label %8

8:                                                ; preds = %46, %2
  %9 = load i32, ptr %7, align 4, !tbaa !10
  %10 = load i32, ptr %4, align 4, !tbaa !10
  %11 = icmp slt i32 %9, %10
  br i1 %11, label %13, label %12

12:                                               ; preds = %8
  call void @llvm.lifetime.end.p0(i64 4, ptr %7) #2
  br label %49

13:                                               ; preds = %8
  %14 = load ptr, ptr %3, align 8, !tbaa !16
  %15 = load i32, ptr %7, align 4, !tbaa !10
  %16 = sext i32 %15 to i64
  %17 = getelementptr inbounds i8, ptr %14, i64 %16
  %18 = load i8, ptr %17, align 1, !tbaa !18
  %19 = sext i8 %18 to i32
  %20 = load i32, ptr %5, align 4, !tbaa !10
  %21 = icmp slt i32 %19, %20
  br i1 %21, label %22, label %29

22:                                               ; preds = %13
  %23 = load ptr, ptr %3, align 8, !tbaa !16
  %24 = load i32, ptr %7, align 4, !tbaa !10
  %25 = sext i32 %24 to i64
  %26 = getelementptr inbounds i8, ptr %23, i64 %25
  %27 = load i8, ptr %26, align 1, !tbaa !18
  %28 = sext i8 %27 to i32
  store i32 %28, ptr %5, align 4, !tbaa !10
  br label %29

29:                                               ; preds = %22, %13
  %30 = load ptr, ptr %3, align 8, !tbaa !16
  %31 = load i32, ptr %7, align 4, !tbaa !10
  %32 = sext i32 %31 to i64
  %33 = getelementptr inbounds i8, ptr %30, i64 %32
  %34 = load i8, ptr %33, align 1, !tbaa !18
  %35 = sext i8 %34 to i32
  %36 = load i32, ptr %6, align 4, !tbaa !10
  %37 = icmp sgt i32 %35, %36
  br i1 %37, label %38, label %45

38:                                               ; preds = %29
  %39 = load ptr, ptr %3, align 8, !tbaa !16
  %40 = load i32, ptr %7, align 4, !tbaa !10
  %41 = sext i32 %40 to i64
  %42 = getelementptr inbounds i8, ptr %39, i64 %41
  %43 = load i8, ptr %42, align 1, !tbaa !18
  %44 = sext i8 %43 to i32
  store i32 %44, ptr %6, align 4, !tbaa !10
  br label %45

45:                                               ; preds = %38, %29
  br label %46

46:                                               ; preds = %45
  %47 = load i32, ptr %7, align 4, !tbaa !10
  %48 = add nsw i32 %47, 1
  store i32 %48, ptr %7, align 4, !tbaa !10
  br label %8, !llvm.loop !20

49:                                               ; preds = %12
  %50 = load i32, ptr %6, align 4, !tbaa !10
  %51 = load i32, ptr %5, align 4, !tbaa !10
  %52 = sub nsw i32 %50, %51
  call void @llvm.lifetime.end.p0(i64 4, ptr %6) #2
  call void @llvm.lifetime.end.p0(i64 4, ptr %5) #2
  ret i32 %52
}

; Function Attrs: nounwind uwtable
define dso_local zeroext i8 @low_bits(i32 noundef %0) #0 {
  %2 = alloca i32, align 4
  store i32 %0, ptr %2, align 4, !tbaa !10
  %3 = load i32, ptr %2, align 4, !tbaa !10
  %4 = lshr i32 %3, 3
  %5 = trunc i32 %4 to i8
  ret i8 %5
}

; Function Attrs: nounwind uwtable
define dso_local signext i16 @folded_down(i32 noundef %0, i32 noundef %1) #0 {
  %3 = alloca i32, align 4
  %4 = alloca i32, align 4
  %5 = alloca i16, align 2
  %6 = alloca i16, align 2
  store i32 %0, ptr %3, align 4, !tbaa !10
  store i32 %1, ptr %4, align 4, !tbaa !10
  call void @llvm.lifetime.start.p0(i64 2, ptr %5) #2
  %7 = load i32, ptr %3, align 4, !tbaa !10
  %8 = trunc i32 %7 to i16
  store i16 %8, ptr %5, align 2, !tbaa !21
  call void @llvm.lifetime.start.p0(i64 2, ptr %6) #2
  %9 = load i32, ptr %4, align 4, !tbaa !10
  %10 = trunc i32 %9 to i16
  store i16 %10, ptr %6, align 2, !tbaa !21
  %11 = load i16, ptr %5, align 2, !tbaa !21
  %12 = sext i16 %11 to i32
  %13 = load i16, ptr %6, align 2, !tbaa !21
  %14 = sext i16 %13 to i32
  %15 = mul nsw i32 %12, %14
  %16 = load i16, ptr %5, align 2, !tbaa !21
  %17 = sext i16 %16 to i32
  %18 = add nsw i32 %15, %17
  %19 = trunc i32 %18 to i16
  call void @llvm.lifetime.end.p0(i64 2, ptr %6) #2
  call void @llvm.lifetime.end.p0(i64 2, ptr %5) #2
  ret i16 %19
}

; Function Attrs: nounwind uwtable
define dso_local i32 @length(ptr noundef %0) #0 {
  %2 = alloca ptr, align 8
  %3 = alloca i32, align 4
  store ptr %0, ptr %2, align 8, !tbaa !16
  call void @llvm.lifetime.start.p0(i64 4, ptr %3) #2
  store i32 0, ptr %3, align 4, !tbaa !10
  br label %4

4:                                                ; preds = %11, %1
  %5 = load ptr, ptr %2, align 8, !tbaa !16
  %6 = load i32, ptr %3, align 4, !tbaa !10
  %7 = sext i32 %6 to i64
  %8 = getelementptr inbounds i8, ptr %5, i64 %7
  %9 = load i8, ptr %8, align 1, !tbaa !18
  %10 = icmp ne i8 %9, 0
  br i1 %10, label %11, label %14

11:                                               ; preds = %4
  %12 = load i32, ptr %3, align 4, !tbaa !10
  %13 = add nsw i32 %12, 1
  store i32 %13, ptr %3, align 4, !tbaa !10
  br label %4, !llvm.loop !23

14:                                               ; preds = %4
  %15 = load i32, ptr %3, align 4, !tbaa !10
  call void @llvm.lifetime.end.p0(i64 4, ptr %3) #2
  ret i32 %15
}

; Function Attrs: nounwind uwtable
define dso_local void @copy_bytes(ptr noalias noundef %0, ptr noalias noundef %1) #0 {
  %3 = alloca ptr, align 8
  %4 = alloca ptr, align 8
  store ptr %0, ptr %3, align 8, !tbaa !16
  store ptr %1, ptr %4, align 8, !tbaa !16
  br label %5

5:                                                ; preds = %12, %2
  %6 = load ptr, ptr %4, align 8, !tbaa !16
  %7 = getelementptr inbounds nuw i8, ptr %6, i32 1
  store ptr %7, ptr %4, align 8, !tbaa !16
  %8 = load i8, ptr %6, align 1, !tbaa !18
  %9 = load ptr, ptr %3, align 8, !tbaa !16
  %10 = getelementptr inbounds nuw i8, ptr %9, i32 1
  store ptr %10, ptr %3, align 8, !tbaa !16
  store i8 %8, ptr %9, align 1, !tbaa !18
  %11 = icmp ne i8 %8, 0
  br i1 %11, label %12, label %13

12:                                               ; preds = %5
  br label %5, !llvm.loop !24

13:                                               ; preds = %5
  ret void
}

attributes #0 = { nounwind uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #1 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { nounwind }

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
!16 = !{!17, !17, i64 0}
!17 = !{!"p1 omnipotent char", !7, i64 0}
!18 = !{!8, !8, i64 0}
!19 = distinct !{!19, !13, !14}
!20 = distinct !{!20, !13, !14}
!21 = !{!22, !22, i64 0}
!22 = !{!"short", !8, i64 0}
!23 = distinct !{!23, !13, !14}
!24 = distinct !{!24, !13, !14}

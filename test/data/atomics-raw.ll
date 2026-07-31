; ModuleID = 'test/c/atomics.c'
source_filename = "test/c/atomics.c"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-linux-gnu"

; Function Attrs: nounwind uwtable
define dso_local i32 @fetched(ptr noundef %0, i32 noundef %1) #0 {
  %3 = alloca ptr, align 8
  %4 = alloca i32, align 4
  %5 = alloca i32, align 4
  %6 = alloca i32, align 4
  %7 = alloca i32, align 4
  %8 = alloca i32, align 4
  store ptr %0, ptr %3, align 8, !tbaa !5
  store i32 %1, ptr %4, align 4, !tbaa !9
  call void @llvm.lifetime.start.p0(i64 4, ptr %5) #2
  %9 = load i32, ptr %4, align 4, !tbaa !9
  %10 = mul nsw i32 %9, 2
  %11 = add nsw i32 %10, 1
  store i32 %11, ptr %5, align 4, !tbaa !9
  call void @llvm.lifetime.start.p0(i64 4, ptr %6) #2
  %12 = load ptr, ptr %3, align 8, !tbaa !5
  %13 = load i32, ptr %5, align 4, !tbaa !9
  store i32 %13, ptr %7, align 4, !tbaa !9
  %14 = load i32, ptr %7, align 4
  %15 = atomicrmw add ptr %12, i32 %14 seq_cst, align 4
  store i32 %15, ptr %8, align 4
  %16 = load i32, ptr %8, align 4, !tbaa !9
  store i32 %16, ptr %6, align 4, !tbaa !9
  %17 = load i32, ptr %6, align 4, !tbaa !9
  %18 = mul nsw i32 %17, 3
  %19 = load i32, ptr %5, align 4, !tbaa !9
  %20 = add nsw i32 %18, %19
  call void @llvm.lifetime.end.p0(i64 4, ptr %6) #2
  call void @llvm.lifetime.end.p0(i64 4, ptr %5) #2
  ret i32 %20
}

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr captures(none)) #1

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr captures(none)) #1

; Function Attrs: nounwind uwtable
define dso_local i32 @raised_to(ptr noundef %0, i32 noundef %1) #0 {
  %3 = alloca i32, align 4
  %4 = alloca ptr, align 8
  %5 = alloca i32, align 4
  %6 = alloca i32, align 4
  %7 = alloca i32, align 4
  %8 = alloca i32, align 4
  %9 = alloca i8, align 1
  %10 = alloca i32, align 4
  store ptr %0, ptr %4, align 8, !tbaa !5
  store i32 %1, ptr %5, align 4, !tbaa !9
  call void @llvm.lifetime.start.p0(i64 4, ptr %6) #2
  %11 = load ptr, ptr %4, align 8, !tbaa !5
  %12 = load atomic i32, ptr %11 seq_cst, align 4
  store i32 %12, ptr %7, align 4
  %13 = load i32, ptr %7, align 4, !tbaa !9
  store i32 %13, ptr %6, align 4, !tbaa !9
  br label %14

14:                                               ; preds = %32, %2
  %15 = load i32, ptr %6, align 4, !tbaa !9
  %16 = load i32, ptr %5, align 4, !tbaa !9
  %17 = icmp slt i32 %15, %16
  br i1 %17, label %18, label %33

18:                                               ; preds = %14
  %19 = load ptr, ptr %4, align 8, !tbaa !5
  %20 = load i32, ptr %5, align 4, !tbaa !9
  store i32 %20, ptr %8, align 4, !tbaa !9
  %21 = load i32, ptr %6, align 4
  %22 = load i32, ptr %8, align 4
  %23 = cmpxchg weak ptr %19, i32 %21, i32 %22 seq_cst seq_cst, align 4
  %24 = extractvalue { i32, i1 } %23, 0
  %25 = extractvalue { i32, i1 } %23, 1
  br i1 %25, label %27, label %26

26:                                               ; preds = %18
  store i32 %24, ptr %6, align 4
  br label %27

27:                                               ; preds = %26, %18
  %28 = zext i1 %25 to i8
  store i8 %28, ptr %9, align 1, !tbaa !11
  %29 = load i8, ptr %9, align 1, !tbaa !11, !range !13, !noundef !14
  %30 = trunc i8 %29 to i1
  br i1 %30, label %31, label %32

31:                                               ; preds = %27
  store i32 1, ptr %3, align 4
  store i32 1, ptr %10, align 4
  br label %34

32:                                               ; preds = %27
  br label %14, !llvm.loop !15

33:                                               ; preds = %14
  store i32 0, ptr %3, align 4
  store i32 1, ptr %10, align 4
  br label %34

34:                                               ; preds = %33, %31
  call void @llvm.lifetime.end.p0(i64 4, ptr %6) #2
  %35 = load i32, ptr %3, align 4
  ret i32 %35
}

; Function Attrs: nounwind uwtable
define dso_local i32 @weighted(ptr noundef %0, ptr noundef %1, i32 noundef %2) #0 {
  %4 = alloca ptr, align 8
  %5 = alloca ptr, align 8
  %6 = alloca i32, align 4
  %7 = alloca i32, align 4
  %8 = alloca i32, align 4
  %9 = alloca i32, align 4
  %10 = alloca i32, align 4
  store ptr %0, ptr %4, align 8, !tbaa !5
  store ptr %1, ptr %5, align 8, !tbaa !18
  store i32 %2, ptr %6, align 4, !tbaa !9
  call void @llvm.lifetime.start.p0(i64 4, ptr %7) #2
  store i32 0, ptr %7, align 4, !tbaa !9
  call void @llvm.lifetime.start.p0(i64 4, ptr %8) #2
  store i32 0, ptr %8, align 4, !tbaa !9
  br label %11

11:                                               ; preds = %29, %3
  %12 = load i32, ptr %8, align 4, !tbaa !9
  %13 = load i32, ptr %6, align 4, !tbaa !9
  %14 = icmp slt i32 %12, %13
  br i1 %14, label %16, label %15

15:                                               ; preds = %11
  call void @llvm.lifetime.end.p0(i64 4, ptr %8) #2
  br label %32

16:                                               ; preds = %11
  call void @llvm.lifetime.start.p0(i64 4, ptr %9) #2
  %17 = load ptr, ptr %4, align 8, !tbaa !5
  %18 = load atomic i32, ptr %17 monotonic, align 4
  store i32 %18, ptr %10, align 4
  %19 = load i32, ptr %10, align 4, !tbaa !9
  store i32 %19, ptr %9, align 4, !tbaa !9
  %20 = load ptr, ptr %5, align 8, !tbaa !18
  %21 = load i32, ptr %8, align 4, !tbaa !9
  %22 = sext i32 %21 to i64
  %23 = getelementptr inbounds i32, ptr %20, i64 %22
  %24 = load i32, ptr %23, align 4, !tbaa !9
  %25 = load i32, ptr %9, align 4, !tbaa !9
  %26 = mul nsw i32 %24, %25
  %27 = load i32, ptr %7, align 4, !tbaa !9
  %28 = add nsw i32 %27, %26
  store i32 %28, ptr %7, align 4, !tbaa !9
  call void @llvm.lifetime.end.p0(i64 4, ptr %9) #2
  br label %29

29:                                               ; preds = %16
  %30 = load i32, ptr %8, align 4, !tbaa !9
  %31 = add nsw i32 %30, 1
  store i32 %31, ptr %8, align 4, !tbaa !9
  br label %11, !llvm.loop !20

32:                                               ; preds = %15
  %33 = load i32, ptr %7, align 4, !tbaa !9
  call void @llvm.lifetime.end.p0(i64 4, ptr %7) #2
  ret i32 %33
}

; Function Attrs: nounwind uwtable
define dso_local i32 @fenced(i32 noundef %0, i32 noundef %1) #0 {
  %3 = alloca i32, align 4
  %4 = alloca i32, align 4
  %5 = alloca i32, align 4
  %6 = alloca i32, align 4
  store i32 %0, ptr %3, align 4, !tbaa !9
  store i32 %1, ptr %4, align 4, !tbaa !9
  call void @llvm.lifetime.start.p0(i64 4, ptr %5) #2
  %7 = load i32, ptr %3, align 4, !tbaa !9
  %8 = load i32, ptr %3, align 4, !tbaa !9
  %9 = mul nsw i32 %7, %8
  %10 = load i32, ptr %4, align 4, !tbaa !9
  %11 = add nsw i32 %9, %10
  store i32 %11, ptr %5, align 4, !tbaa !9
  fence seq_cst
  call void @llvm.lifetime.start.p0(i64 4, ptr %6) #2
  %12 = load i32, ptr %4, align 4, !tbaa !9
  %13 = load i32, ptr %4, align 4, !tbaa !9
  %14 = mul nsw i32 %12, %13
  %15 = load i32, ptr %3, align 4, !tbaa !9
  %16 = add nsw i32 %14, %15
  store i32 %16, ptr %6, align 4, !tbaa !9
  %17 = load i32, ptr %5, align 4, !tbaa !9
  %18 = load i32, ptr %6, align 4, !tbaa !9
  %19 = add nsw i32 %17, %18
  call void @llvm.lifetime.end.p0(i64 4, ptr %6) #2
  call void @llvm.lifetime.end.p0(i64 4, ptr %5) #2
  ret i32 %19
}

; Function Attrs: nounwind uwtable
define dso_local i32 @published(ptr noundef %0, i32 noundef %1) #0 {
  %3 = alloca ptr, align 8
  %4 = alloca i32, align 4
  %5 = alloca i32, align 4
  %6 = alloca i32, align 4
  store ptr %0, ptr %3, align 8, !tbaa !5
  store i32 %1, ptr %4, align 4, !tbaa !9
  call void @llvm.lifetime.start.p0(i64 4, ptr %5) #2
  %7 = load i32, ptr %4, align 4, !tbaa !9
  store i32 %7, ptr %5, align 4, !tbaa !9
  %8 = load i32, ptr %5, align 4, !tbaa !9
  %9 = load i32, ptr %5, align 4, !tbaa !9
  %10 = add nsw i32 %8, %9
  store i32 %10, ptr %5, align 4, !tbaa !9
  %11 = load ptr, ptr %3, align 8, !tbaa !5
  %12 = load i32, ptr %5, align 4, !tbaa !9
  store i32 %12, ptr %6, align 4, !tbaa !9
  %13 = load i32, ptr %6, align 4
  store atomic i32 %13, ptr %11 seq_cst, align 4
  %14 = load i32, ptr %5, align 4, !tbaa !9
  call void @llvm.lifetime.end.p0(i64 4, ptr %5) #2
  ret i32 %14
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
!6 = !{!"any pointer", !7, i64 0}
!7 = !{!"omnipotent char", !8, i64 0}
!8 = !{!"Simple C/C++ TBAA"}
!9 = !{!10, !10, i64 0}
!10 = !{!"int", !7, i64 0}
!11 = !{!12, !12, i64 0}
!12 = !{!"_Bool", !7, i64 0}
!13 = !{i8 0, i8 2}
!14 = !{}
!15 = distinct !{!15, !16, !17}
!16 = !{!"llvm.loop.mustprogress"}
!17 = !{!"llvm.loop.unroll.disable"}
!18 = !{!19, !19, i64 0}
!19 = !{!"p1 int", !6, i64 0}
!20 = distinct !{!20, !16, !17}

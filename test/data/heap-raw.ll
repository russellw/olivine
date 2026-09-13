; ModuleID = 'test/c/heap.c'
source_filename = "test/c/heap.c"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-linux-gnu"

@watched_heap = external global ptr, align 8

; Function Attrs: nounwind uwtable
define dso_local i32 @filled_then_read(i32 noundef %0) #0 {
  %2 = alloca i32, align 4
  %3 = alloca ptr, align 8
  %4 = alloca i32, align 4
  store i32 %0, ptr %2, align 4, !tbaa !5
  call void @llvm.lifetime.start.p0(i64 8, ptr %3) #5
  %5 = call noalias ptr @malloc(i64 noundef 16) #6
  store ptr %5, ptr %3, align 8, !tbaa !9
  %6 = load i32, ptr %2, align 4, !tbaa !5
  %7 = load ptr, ptr %3, align 8, !tbaa !9
  %8 = getelementptr inbounds i32, ptr %7, i64 0
  store i32 %6, ptr %8, align 4, !tbaa !5
  %9 = load i32, ptr %2, align 4, !tbaa !5
  %10 = add nsw i32 %9, 1
  %11 = load ptr, ptr %3, align 8, !tbaa !9
  %12 = getelementptr inbounds i32, ptr %11, i64 1
  store i32 %10, ptr %12, align 4, !tbaa !5
  call void @llvm.lifetime.start.p0(i64 4, ptr %4) #5
  %13 = load ptr, ptr %3, align 8, !tbaa !9
  %14 = getelementptr inbounds i32, ptr %13, i64 0
  %15 = load i32, ptr %14, align 4, !tbaa !5
  %16 = load ptr, ptr %3, align 8, !tbaa !9
  %17 = getelementptr inbounds i32, ptr %16, i64 1
  %18 = load i32, ptr %17, align 4, !tbaa !5
  %19 = add nsw i32 %15, %18
  store i32 %19, ptr %4, align 4, !tbaa !5
  %20 = load ptr, ptr %3, align 8, !tbaa !9
  call void @free(ptr noundef %20) #5
  %21 = load i32, ptr %4, align 4, !tbaa !5
  call void @llvm.lifetime.end.p0(i64 4, ptr %4) #5
  call void @llvm.lifetime.end.p0(i64 8, ptr %3) #5
  ret i32 %21
}

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr captures(none)) #1

; Function Attrs: nounwind allocsize(0)
declare noalias ptr @malloc(i64 noundef) #2

; Function Attrs: nounwind
declare void @free(ptr noundef) #3

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr captures(none)) #1

; Function Attrs: nounwind uwtable
define dso_local i32 @other_element(i32 noundef %0) #0 {
  %2 = alloca i32, align 4
  %3 = alloca ptr, align 8
  %4 = alloca i32, align 4
  store i32 %0, ptr %2, align 4, !tbaa !5
  call void @llvm.lifetime.start.p0(i64 8, ptr %3) #5
  %5 = call noalias ptr @malloc(i64 noundef 16) #6
  store ptr %5, ptr %3, align 8, !tbaa !9
  %6 = load i32, ptr %2, align 4, !tbaa !5
  %7 = load ptr, ptr %3, align 8, !tbaa !9
  %8 = getelementptr inbounds i32, ptr %7, i64 0
  store i32 %6, ptr %8, align 4, !tbaa !5
  %9 = load i32, ptr %2, align 4, !tbaa !5
  %10 = add nsw i32 %9, 1
  %11 = load ptr, ptr %3, align 8, !tbaa !9
  %12 = getelementptr inbounds i32, ptr %11, i64 1
  store i32 %10, ptr %12, align 4, !tbaa !5
  %13 = load ptr, ptr %3, align 8, !tbaa !9
  %14 = getelementptr inbounds i32, ptr %13, i64 2
  store i32 0, ptr %14, align 4, !tbaa !5
  call void @llvm.lifetime.start.p0(i64 4, ptr %4) #5
  %15 = load ptr, ptr %3, align 8, !tbaa !9
  %16 = getelementptr inbounds i32, ptr %15, i64 0
  %17 = load i32, ptr %16, align 4, !tbaa !5
  store i32 %17, ptr %4, align 4, !tbaa !5
  %18 = load ptr, ptr %3, align 8, !tbaa !9
  call void @free(ptr noundef %18) #5
  %19 = load i32, ptr %4, align 4, !tbaa !5
  call void @llvm.lifetime.end.p0(i64 4, ptr %4) #5
  call void @llvm.lifetime.end.p0(i64 8, ptr %3) #5
  ret i32 %19
}

; Function Attrs: nounwind uwtable
define dso_local i32 @somewhere_in_it(i32 noundef %0, i32 noundef %1) #0 {
  %3 = alloca i32, align 4
  %4 = alloca i32, align 4
  %5 = alloca ptr, align 8
  %6 = alloca i32, align 4
  store i32 %0, ptr %3, align 4, !tbaa !5
  store i32 %1, ptr %4, align 4, !tbaa !5
  call void @llvm.lifetime.start.p0(i64 8, ptr %5) #5
  %7 = call noalias ptr @malloc(i64 noundef 16) #6
  store ptr %7, ptr %5, align 8, !tbaa !9
  %8 = load i32, ptr %3, align 4, !tbaa !5
  %9 = load ptr, ptr %5, align 8, !tbaa !9
  %10 = getelementptr inbounds i32, ptr %9, i64 0
  store i32 %8, ptr %10, align 4, !tbaa !5
  %11 = load ptr, ptr %5, align 8, !tbaa !9
  %12 = load i32, ptr %4, align 4, !tbaa !5
  %13 = and i32 %12, 3
  %14 = sext i32 %13 to i64
  %15 = getelementptr inbounds i32, ptr %11, i64 %14
  store i32 0, ptr %15, align 4, !tbaa !5
  call void @llvm.lifetime.start.p0(i64 4, ptr %6) #5
  %16 = load ptr, ptr %5, align 8, !tbaa !9
  %17 = getelementptr inbounds i32, ptr %16, i64 0
  %18 = load i32, ptr %17, align 4, !tbaa !5
  store i32 %18, ptr %6, align 4, !tbaa !5
  %19 = load ptr, ptr %5, align 8, !tbaa !9
  call void @free(ptr noundef %19) #5
  %20 = load i32, ptr %6, align 4, !tbaa !5
  call void @llvm.lifetime.end.p0(i64 4, ptr %6) #5
  call void @llvm.lifetime.end.p0(i64 8, ptr %5) #5
  ret i32 %20
}

; Function Attrs: nounwind uwtable
define dso_local i32 @two_buffers(i32 noundef %0) #0 {
  %2 = alloca i32, align 4
  %3 = alloca ptr, align 8
  %4 = alloca ptr, align 8
  %5 = alloca i32, align 4
  store i32 %0, ptr %2, align 4, !tbaa !5
  call void @llvm.lifetime.start.p0(i64 8, ptr %3) #5
  %6 = call noalias ptr @malloc(i64 noundef 16) #6
  store ptr %6, ptr %3, align 8, !tbaa !9
  call void @llvm.lifetime.start.p0(i64 8, ptr %4) #5
  %7 = call noalias ptr @malloc(i64 noundef 16) #6
  store ptr %7, ptr %4, align 8, !tbaa !9
  %8 = load i32, ptr %2, align 4, !tbaa !5
  %9 = load ptr, ptr %3, align 8, !tbaa !9
  %10 = getelementptr inbounds i32, ptr %9, i64 0
  store i32 %8, ptr %10, align 4, !tbaa !5
  %11 = load i32, ptr %2, align 4, !tbaa !5
  %12 = add nsw i32 %11, 1
  %13 = load ptr, ptr %4, align 8, !tbaa !9
  %14 = getelementptr inbounds i32, ptr %13, i64 0
  store i32 %12, ptr %14, align 4, !tbaa !5
  call void @llvm.lifetime.start.p0(i64 4, ptr %5) #5
  %15 = load ptr, ptr %3, align 8, !tbaa !9
  %16 = getelementptr inbounds i32, ptr %15, i64 0
  %17 = load i32, ptr %16, align 4, !tbaa !5
  %18 = load ptr, ptr %4, align 8, !tbaa !9
  %19 = getelementptr inbounds i32, ptr %18, i64 0
  %20 = load i32, ptr %19, align 4, !tbaa !5
  %21 = add nsw i32 %17, %20
  store i32 %21, ptr %5, align 4, !tbaa !5
  %22 = load ptr, ptr %3, align 8, !tbaa !9
  call void @free(ptr noundef %22) #5
  %23 = load ptr, ptr %4, align 8, !tbaa !9
  call void @free(ptr noundef %23) #5
  %24 = load i32, ptr %5, align 4, !tbaa !5
  call void @llvm.lifetime.end.p0(i64 4, ptr %5) #5
  call void @llvm.lifetime.end.p0(i64 8, ptr %4) #5
  call void @llvm.lifetime.end.p0(i64 8, ptr %3) #5
  ret i32 %24
}

; Function Attrs: nounwind uwtable
define dso_local i32 @through_a_parameter(ptr noundef %0, i32 noundef %1) #0 {
  %3 = alloca ptr, align 8
  %4 = alloca i32, align 4
  %5 = alloca ptr, align 8
  %6 = alloca i32, align 4
  store ptr %0, ptr %3, align 8, !tbaa !9
  store i32 %1, ptr %4, align 4, !tbaa !5
  call void @llvm.lifetime.start.p0(i64 8, ptr %5) #5
  %7 = call noalias ptr @malloc(i64 noundef 16) #6
  store ptr %7, ptr %5, align 8, !tbaa !9
  %8 = load i32, ptr %4, align 4, !tbaa !5
  %9 = load ptr, ptr %5, align 8, !tbaa !9
  %10 = getelementptr inbounds i32, ptr %9, i64 0
  store i32 %8, ptr %10, align 4, !tbaa !5
  %11 = load ptr, ptr %3, align 8, !tbaa !9
  store i32 0, ptr %11, align 4, !tbaa !5
  call void @llvm.lifetime.start.p0(i64 4, ptr %6) #5
  %12 = load ptr, ptr %5, align 8, !tbaa !9
  %13 = getelementptr inbounds i32, ptr %12, i64 0
  %14 = load i32, ptr %13, align 4, !tbaa !5
  store i32 %14, ptr %6, align 4, !tbaa !5
  %15 = load ptr, ptr %5, align 8, !tbaa !9
  call void @free(ptr noundef %15) #5
  %16 = load i32, ptr %6, align 4, !tbaa !5
  call void @llvm.lifetime.end.p0(i64 4, ptr %6) #5
  call void @llvm.lifetime.end.p0(i64 8, ptr %5) #5
  ret i32 %16
}

; Function Attrs: nounwind uwtable
define dso_local i32 @around_a_call(i32 noundef %0) #0 {
  %2 = alloca i32, align 4
  %3 = alloca ptr, align 8
  %4 = alloca i32, align 4
  store i32 %0, ptr %2, align 4, !tbaa !5
  call void @llvm.lifetime.start.p0(i64 8, ptr %3) #5
  %5 = call noalias ptr @malloc(i64 noundef 16) #6
  store ptr %5, ptr %3, align 8, !tbaa !9
  %6 = load i32, ptr %2, align 4, !tbaa !5
  %7 = load ptr, ptr %3, align 8, !tbaa !9
  %8 = getelementptr inbounds i32, ptr %7, i64 0
  store i32 %6, ptr %8, align 4, !tbaa !5
  %9 = load ptr, ptr %3, align 8, !tbaa !9
  store ptr %9, ptr @watched_heap, align 8, !tbaa !9
  call void @sink()
  call void @llvm.lifetime.start.p0(i64 4, ptr %4) #5
  %10 = load ptr, ptr %3, align 8, !tbaa !9
  %11 = getelementptr inbounds i32, ptr %10, i64 0
  %12 = load i32, ptr %11, align 4, !tbaa !5
  store i32 %12, ptr %4, align 4, !tbaa !5
  store ptr null, ptr @watched_heap, align 8, !tbaa !9
  %13 = load ptr, ptr %3, align 8, !tbaa !9
  call void @free(ptr noundef %13) #5
  %14 = load i32, ptr %4, align 4, !tbaa !5
  call void @llvm.lifetime.end.p0(i64 4, ptr %4) #5
  call void @llvm.lifetime.end.p0(i64 8, ptr %3) #5
  ret i32 %14
}

declare void @sink() #4

; Function Attrs: nounwind uwtable
define dso_local i32 @allocated_each_turn(i32 noundef %0) #0 {
  %2 = alloca i32, align 4
  %3 = alloca i32, align 4
  %4 = alloca i32, align 4
  %5 = alloca ptr, align 8
  store i32 %0, ptr %2, align 4, !tbaa !5
  call void @llvm.lifetime.start.p0(i64 4, ptr %3) #5
  store i32 0, ptr %3, align 4, !tbaa !5
  call void @llvm.lifetime.start.p0(i64 4, ptr %4) #5
  store i32 0, ptr %4, align 4, !tbaa !5
  br label %6

6:                                                ; preds = %29, %1
  %7 = load i32, ptr %4, align 4, !tbaa !5
  %8 = load i32, ptr %2, align 4, !tbaa !5
  %9 = icmp slt i32 %7, %8
  br i1 %9, label %11, label %10

10:                                               ; preds = %6
  call void @llvm.lifetime.end.p0(i64 4, ptr %4) #5
  br label %32

11:                                               ; preds = %6
  call void @llvm.lifetime.start.p0(i64 8, ptr %5) #5
  %12 = call noalias ptr @malloc(i64 noundef 16) #6
  store ptr %12, ptr %5, align 8, !tbaa !9
  %13 = load i32, ptr %4, align 4, !tbaa !5
  %14 = load ptr, ptr %5, align 8, !tbaa !9
  %15 = getelementptr inbounds i32, ptr %14, i64 0
  store i32 %13, ptr %15, align 4, !tbaa !5
  %16 = load i32, ptr %3, align 4, !tbaa !5
  %17 = load ptr, ptr %5, align 8, !tbaa !9
  %18 = getelementptr inbounds i32, ptr %17, i64 1
  store i32 %16, ptr %18, align 4, !tbaa !5
  %19 = load ptr, ptr %5, align 8, !tbaa !9
  %20 = getelementptr inbounds i32, ptr %19, i64 0
  %21 = load i32, ptr %20, align 4, !tbaa !5
  %22 = load ptr, ptr %5, align 8, !tbaa !9
  %23 = getelementptr inbounds i32, ptr %22, i64 1
  %24 = load i32, ptr %23, align 4, !tbaa !5
  %25 = add nsw i32 %21, %24
  %26 = load i32, ptr %3, align 4, !tbaa !5
  %27 = add nsw i32 %26, %25
  store i32 %27, ptr %3, align 4, !tbaa !5
  %28 = load ptr, ptr %5, align 8, !tbaa !9
  call void @free(ptr noundef %28) #5
  call void @llvm.lifetime.end.p0(i64 8, ptr %5) #5
  br label %29

29:                                               ; preds = %11
  %30 = load i32, ptr %4, align 4, !tbaa !5
  %31 = add nsw i32 %30, 1
  store i32 %31, ptr %4, align 4, !tbaa !5
  br label %6, !llvm.loop !12

32:                                               ; preds = %10
  %33 = load i32, ptr %3, align 4, !tbaa !5
  call void @llvm.lifetime.end.p0(i64 4, ptr %3) #5
  ret i32 %33
}

; Function Attrs: nounwind uwtable
define dso_local i32 @carried_along(i32 noundef %0) #0 {
  %2 = alloca i32, align 4
  %3 = alloca ptr, align 8
  %4 = alloca i32, align 4
  %5 = alloca i32, align 4
  %6 = alloca i32, align 4
  store i32 %0, ptr %2, align 4, !tbaa !5
  call void @llvm.lifetime.start.p0(i64 8, ptr %3) #5
  %7 = call noalias ptr @malloc(i64 noundef 64) #6
  store ptr %7, ptr %3, align 8, !tbaa !9
  %8 = load ptr, ptr %3, align 8, !tbaa !9
  %9 = getelementptr inbounds i32, ptr %8, i64 0
  store i32 1, ptr %9, align 4, !tbaa !5
  call void @llvm.lifetime.start.p0(i64 4, ptr %4) #5
  store i32 1, ptr %4, align 4, !tbaa !5
  br label %10

10:                                               ; preds = %33, %1
  %11 = load i32, ptr %4, align 4, !tbaa !5
  %12 = load i32, ptr %2, align 4, !tbaa !5
  %13 = icmp slt i32 %11, %12
  br i1 %13, label %14, label %17

14:                                               ; preds = %10
  %15 = load i32, ptr %4, align 4, !tbaa !5
  %16 = icmp slt i32 %15, 16
  br label %17

17:                                               ; preds = %14, %10
  %18 = phi i1 [ false, %10 ], [ %16, %14 ]
  br i1 %18, label %20, label %19

19:                                               ; preds = %17
  call void @llvm.lifetime.end.p0(i64 4, ptr %4) #5
  br label %36

20:                                               ; preds = %17
  %21 = load ptr, ptr %3, align 8, !tbaa !9
  %22 = load i32, ptr %4, align 4, !tbaa !5
  %23 = sub nsw i32 %22, 1
  %24 = sext i32 %23 to i64
  %25 = getelementptr inbounds i32, ptr %21, i64 %24
  %26 = load i32, ptr %25, align 4, !tbaa !5
  %27 = load i32, ptr %4, align 4, !tbaa !5
  %28 = add nsw i32 %26, %27
  %29 = load ptr, ptr %3, align 8, !tbaa !9
  %30 = load i32, ptr %4, align 4, !tbaa !5
  %31 = sext i32 %30 to i64
  %32 = getelementptr inbounds i32, ptr %29, i64 %31
  store i32 %28, ptr %32, align 4, !tbaa !5
  br label %33

33:                                               ; preds = %20
  %34 = load i32, ptr %4, align 4, !tbaa !5
  %35 = add nsw i32 %34, 1
  store i32 %35, ptr %4, align 4, !tbaa !5
  br label %10, !llvm.loop !15

36:                                               ; preds = %19
  call void @llvm.lifetime.start.p0(i64 4, ptr %5) #5
  store i32 0, ptr %5, align 4, !tbaa !5
  call void @llvm.lifetime.start.p0(i64 4, ptr %6) #5
  store i32 0, ptr %6, align 4, !tbaa !5
  br label %37

37:                                               ; preds = %55, %36
  %38 = load i32, ptr %6, align 4, !tbaa !5
  %39 = load i32, ptr %2, align 4, !tbaa !5
  %40 = icmp slt i32 %38, %39
  br i1 %40, label %41, label %44

41:                                               ; preds = %37
  %42 = load i32, ptr %6, align 4, !tbaa !5
  %43 = icmp slt i32 %42, 16
  br label %44

44:                                               ; preds = %41, %37
  %45 = phi i1 [ false, %37 ], [ %43, %41 ]
  br i1 %45, label %47, label %46

46:                                               ; preds = %44
  call void @llvm.lifetime.end.p0(i64 4, ptr %6) #5
  br label %58

47:                                               ; preds = %44
  %48 = load ptr, ptr %3, align 8, !tbaa !9
  %49 = load i32, ptr %6, align 4, !tbaa !5
  %50 = sext i32 %49 to i64
  %51 = getelementptr inbounds i32, ptr %48, i64 %50
  %52 = load i32, ptr %51, align 4, !tbaa !5
  %53 = load i32, ptr %5, align 4, !tbaa !5
  %54 = add nsw i32 %53, %52
  store i32 %54, ptr %5, align 4, !tbaa !5
  br label %55

55:                                               ; preds = %47
  %56 = load i32, ptr %6, align 4, !tbaa !5
  %57 = add nsw i32 %56, 1
  store i32 %57, ptr %6, align 4, !tbaa !5
  br label %37, !llvm.loop !16

58:                                               ; preds = %46
  %59 = load ptr, ptr %3, align 8, !tbaa !9
  call void @free(ptr noundef %59) #5
  %60 = load i32, ptr %5, align 4, !tbaa !5
  call void @llvm.lifetime.end.p0(i64 4, ptr %5) #5
  call void @llvm.lifetime.end.p0(i64 8, ptr %3) #5
  ret i32 %60
}

attributes #0 = { nounwind uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #1 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { nounwind allocsize(0) "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #3 = { nounwind "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #4 = { "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #5 = { nounwind }
attributes #6 = { nounwind allocsize(0) }

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
!9 = !{!10, !10, i64 0}
!10 = !{!"p1 int", !11, i64 0}
!11 = !{!"any pointer", !7, i64 0}
!12 = distinct !{!12, !13, !14}
!13 = !{!"llvm.loop.mustprogress"}
!14 = !{!"llvm.loop.unroll.disable"}
!15 = distinct !{!15, !13, !14}
!16 = distinct !{!16, !13, !14}

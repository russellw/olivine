; ModuleID = 'test/c/escape.c'
source_filename = "test/c/escape.c"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-linux-gnu"

; Function Attrs: nounwind uwtable
define dso_local i32 @through_pointer(i32 noundef %0) #0 {
  %2 = alloca i32, align 4
  %3 = alloca i32, align 4
  %4 = alloca i32, align 4
  store i32 %0, ptr %2, align 4, !tbaa !5
  call void @llvm.lifetime.start.p0(i64 4, ptr %3) #3
  %5 = load i32, ptr %2, align 4, !tbaa !5
  store i32 %5, ptr %3, align 4, !tbaa !5
  call void @llvm.lifetime.start.p0(i64 4, ptr %4) #3
  %6 = load i32, ptr %2, align 4, !tbaa !5
  %7 = add nsw i32 %6, 1
  store i32 %7, ptr %4, align 4, !tbaa !5
  %8 = load i32, ptr %3, align 4, !tbaa !5
  %9 = add nsw i32 %8, 2
  call void @writeback(ptr noundef %4, i32 noundef %9)
  %10 = load i32, ptr %3, align 4, !tbaa !5
  %11 = load i32, ptr %4, align 4, !tbaa !5
  %12 = add nsw i32 %10, %11
  call void @llvm.lifetime.end.p0(i64 4, ptr %4) #3
  call void @llvm.lifetime.end.p0(i64 4, ptr %3) #3
  ret i32 %12
}

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr captures(none)) #1

; Function Attrs: nounwind uwtable
define internal void @writeback(ptr noundef %0, i32 noundef %1) #0 {
  %3 = alloca ptr, align 8
  %4 = alloca i32, align 4
  store ptr %0, ptr %3, align 8, !tbaa !9
  store i32 %1, ptr %4, align 4, !tbaa !5
  %5 = load i32, ptr %4, align 4, !tbaa !5
  %6 = load ptr, ptr %3, align 8, !tbaa !9
  store i32 %5, ptr %6, align 4, !tbaa !5
  ret void
}

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr captures(none)) #1

; Function Attrs: nounwind uwtable
define dso_local i32 @volatile_local(i32 noundef %0) #0 {
  %2 = alloca i32, align 4
  %3 = alloca i32, align 4
  store i32 %0, ptr %2, align 4, !tbaa !5
  call void @llvm.lifetime.start.p0(i64 4, ptr %3) #3
  %4 = load i32, ptr %2, align 4, !tbaa !5
  store volatile i32 %4, ptr %3, align 4, !tbaa !5
  %5 = load volatile i32, ptr %3, align 4, !tbaa !5
  %6 = add nsw i32 %5, 1
  store volatile i32 %6, ptr %3, align 4, !tbaa !5
  %7 = load volatile i32, ptr %3, align 4, !tbaa !5
  %8 = load volatile i32, ptr %3, align 4, !tbaa !5
  %9 = add nsw i32 %7, %8
  call void @llvm.lifetime.end.p0(i64 4, ptr %3) #3
  ret i32 %9
}

; Function Attrs: nounwind uwtable
define dso_local i32 @picked_pair(i32 noundef %0, i32 noundef %1, i32 noundef %2) #0 {
  %4 = alloca i32, align 4
  %5 = alloca i32, align 4
  %6 = alloca i32, align 4
  %7 = alloca [2 x i32], align 4
  store i32 %0, ptr %4, align 4, !tbaa !5
  store i32 %1, ptr %5, align 4, !tbaa !5
  store i32 %2, ptr %6, align 4, !tbaa !5
  call void @llvm.lifetime.start.p0(i64 8, ptr %7) #3
  %8 = load i32, ptr %4, align 4, !tbaa !5
  store i32 %8, ptr %7, align 4, !tbaa !5
  %9 = getelementptr inbounds i32, ptr %7, i64 1
  %10 = load i32, ptr %5, align 4, !tbaa !5
  store i32 %10, ptr %9, align 4, !tbaa !5
  %11 = load i32, ptr %6, align 4, !tbaa !5
  %12 = icmp ne i32 %11, 0
  br i1 %12, label %13, label %16

13:                                               ; preds = %3
  %14 = load i32, ptr %5, align 4, !tbaa !5
  %15 = getelementptr inbounds [2 x i32], ptr %7, i64 0, i64 0
  store i32 %14, ptr %15, align 4, !tbaa !5
  br label %16

16:                                               ; preds = %13, %3
  %17 = getelementptr inbounds [2 x i32], ptr %7, i64 0, i64 0
  %18 = load i32, ptr %17, align 4, !tbaa !5
  %19 = mul nsw i32 %18, 2
  %20 = getelementptr inbounds [2 x i32], ptr %7, i64 0, i64 1
  %21 = load i32, ptr %20, align 4, !tbaa !5
  %22 = add nsw i32 %19, %21
  call void @llvm.lifetime.end.p0(i64 8, ptr %7) #3
  ret i32 %22
}

; Function Attrs: nounwind uwtable
define dso_local i32 @addressed_pair(i32 noundef %0, i32 noundef %1) #0 {
  %3 = alloca i32, align 4
  %4 = alloca i32, align 4
  %5 = alloca [2 x i32], align 4
  %6 = alloca ptr, align 8
  store i32 %0, ptr %3, align 4, !tbaa !5
  store i32 %1, ptr %4, align 4, !tbaa !5
  call void @llvm.lifetime.start.p0(i64 8, ptr %5) #3
  %7 = load i32, ptr %3, align 4, !tbaa !5
  store i32 %7, ptr %5, align 4, !tbaa !5
  %8 = getelementptr inbounds i32, ptr %5, i64 1
  %9 = load i32, ptr %4, align 4, !tbaa !5
  store i32 %9, ptr %8, align 4, !tbaa !5
  call void @llvm.lifetime.start.p0(i64 8, ptr %6) #3
  %10 = getelementptr inbounds [2 x i32], ptr %5, i64 0, i64 0
  %11 = load i32, ptr %3, align 4, !tbaa !5
  %12 = load i32, ptr %4, align 4, !tbaa !5
  %13 = icmp sgt i32 %11, %12
  %14 = zext i1 %13 to i32
  %15 = sext i32 %14 to i64
  %16 = getelementptr inbounds i32, ptr %10, i64 %15
  store ptr %16, ptr %6, align 8, !tbaa !9
  %17 = load ptr, ptr %6, align 8, !tbaa !9
  %18 = load i32, ptr %17, align 4, !tbaa !5
  call void @llvm.lifetime.end.p0(i64 8, ptr %6) #3
  call void @llvm.lifetime.end.p0(i64 8, ptr %5) #3
  ret i32 %18
}

; Function Attrs: nounwind uwtable
define dso_local i64 @counted(i32 noundef %0) #0 {
  %2 = alloca i32, align 4
  %3 = alloca ptr, align 8
  %4 = alloca i64, align 8
  %5 = alloca i32, align 4
  %6 = alloca i64, align 8
  %7 = alloca i32, align 4
  store i32 %0, ptr %2, align 4, !tbaa !5
  %8 = load i32, ptr %2, align 4, !tbaa !5
  %9 = zext i32 %8 to i64
  %10 = call ptr @llvm.stacksave.p0()
  store ptr %10, ptr %3, align 8
  %11 = alloca i32, i64 %9, align 16
  store i64 %9, ptr %4, align 8
  call void @llvm.lifetime.start.p0(i64 4, ptr %5) #3
  store i32 0, ptr %5, align 4, !tbaa !5
  br label %12

12:                                               ; preds = %26, %1
  %13 = load i32, ptr %5, align 4, !tbaa !5
  %14 = load i32, ptr %2, align 4, !tbaa !5
  %15 = icmp slt i32 %13, %14
  br i1 %15, label %17, label %16

16:                                               ; preds = %12
  call void @llvm.lifetime.end.p0(i64 4, ptr %5) #3
  br label %29

17:                                               ; preds = %12
  %18 = load i32, ptr %5, align 4, !tbaa !5
  %19 = load i32, ptr %5, align 4, !tbaa !5
  %20 = mul nsw i32 %18, %19
  %21 = load i32, ptr %2, align 4, !tbaa !5
  %22 = sub nsw i32 %20, %21
  %23 = load i32, ptr %5, align 4, !tbaa !5
  %24 = sext i32 %23 to i64
  %25 = getelementptr inbounds i32, ptr %11, i64 %24
  store i32 %22, ptr %25, align 4, !tbaa !5
  br label %26

26:                                               ; preds = %17
  %27 = load i32, ptr %5, align 4, !tbaa !5
  %28 = add nsw i32 %27, 1
  store i32 %28, ptr %5, align 4, !tbaa !5
  br label %12, !llvm.loop !12

29:                                               ; preds = %16
  call void @llvm.lifetime.start.p0(i64 8, ptr %6) #3
  store i64 0, ptr %6, align 8, !tbaa !15
  call void @llvm.lifetime.start.p0(i64 4, ptr %7) #3
  store i32 0, ptr %7, align 4, !tbaa !5
  br label %30

30:                                               ; preds = %43, %29
  %31 = load i32, ptr %7, align 4, !tbaa !5
  %32 = load i32, ptr %2, align 4, !tbaa !5
  %33 = icmp slt i32 %31, %32
  br i1 %33, label %35, label %34

34:                                               ; preds = %30
  call void @llvm.lifetime.end.p0(i64 4, ptr %7) #3
  br label %46

35:                                               ; preds = %30
  %36 = load i32, ptr %7, align 4, !tbaa !5
  %37 = sext i32 %36 to i64
  %38 = getelementptr inbounds i32, ptr %11, i64 %37
  %39 = load i32, ptr %38, align 4, !tbaa !5
  %40 = sext i32 %39 to i64
  %41 = load i64, ptr %6, align 8, !tbaa !15
  %42 = add nsw i64 %41, %40
  store i64 %42, ptr %6, align 8, !tbaa !15
  br label %43

43:                                               ; preds = %35
  %44 = load i32, ptr %7, align 4, !tbaa !5
  %45 = add nsw i32 %44, 1
  store i32 %45, ptr %7, align 4, !tbaa !5
  br label %30, !llvm.loop !17

46:                                               ; preds = %34
  %47 = load i64, ptr %6, align 8, !tbaa !15
  call void @llvm.lifetime.end.p0(i64 8, ptr %6) #3
  %48 = load ptr, ptr %3, align 8
  call void @llvm.stackrestore.p0(ptr %48)
  ret i64 %47
}

; Function Attrs: nocallback nofree nosync nounwind willreturn
declare ptr @llvm.stacksave.p0() #2

; Function Attrs: nocallback nofree nosync nounwind willreturn
declare void @llvm.stackrestore.p0(ptr) #2

; Function Attrs: nounwind uwtable
define dso_local i32 @only_stored(i32 noundef %0) #0 {
  %2 = alloca i32, align 4
  %3 = alloca i32, align 4
  store i32 %0, ptr %2, align 4, !tbaa !5
  call void @llvm.lifetime.start.p0(i64 4, ptr %3) #3
  %4 = load i32, ptr %2, align 4, !tbaa !5
  %5 = mul nsw i32 %4, 7
  store i32 %5, ptr %3, align 4, !tbaa !5
  %6 = load i32, ptr %3, align 4, !tbaa !5
  %7 = load i32, ptr %2, align 4, !tbaa !5
  call void @llvm.lifetime.end.p0(i64 4, ptr %3) #3
  ret i32 %7
}

attributes #0 = { nounwind uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #1 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { nocallback nofree nosync nounwind willreturn }
attributes #3 = { nounwind }

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
!15 = !{!16, !16, i64 0}
!16 = !{!"long", !7, i64 0}
!17 = distinct !{!17, !13, !14}

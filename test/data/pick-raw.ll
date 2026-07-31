; ModuleID = 'test/c/pick.c'
source_filename = "test/c/pick.c"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-linux-gnu"

@counter = dso_local global i32 0, align 4

; Function Attrs: nounwind uwtable
define dso_local i32 @larger(i32 noundef %0, i32 noundef %1) #0 {
  %3 = alloca i32, align 4
  %4 = alloca i32, align 4
  store i32 %0, ptr %3, align 4, !tbaa !5
  store i32 %1, ptr %4, align 4, !tbaa !5
  %5 = load i32, ptr %3, align 4, !tbaa !5
  %6 = load i32, ptr %4, align 4, !tbaa !5
  %7 = icmp sgt i32 %5, %6
  br i1 %7, label %8, label %10

8:                                                ; preds = %2
  %9 = load i32, ptr %3, align 4, !tbaa !5
  br label %12

10:                                               ; preds = %2
  %11 = load i32, ptr %4, align 4, !tbaa !5
  br label %12

12:                                               ; preds = %10, %8
  %13 = phi i32 [ %9, %8 ], [ %11, %10 ]
  ret i32 %13
}

; Function Attrs: nounwind uwtable
define dso_local i32 @sign(i32 noundef %0) #0 {
  %2 = alloca i32, align 4
  store i32 %0, ptr %2, align 4, !tbaa !5
  %3 = load i32, ptr %2, align 4, !tbaa !5
  %4 = icmp slt i32 %3, 0
  br i1 %4, label %5, label %6

5:                                                ; preds = %1
  br label %11

6:                                                ; preds = %1
  %7 = load i32, ptr %2, align 4, !tbaa !5
  %8 = icmp sgt i32 %7, 0
  %9 = zext i1 %8 to i64
  %10 = select i1 %8, i32 1, i32 0
  br label %11

11:                                               ; preds = %6, %5
  %12 = phi i32 [ -1, %5 ], [ %10, %6 ]
  ret i32 %12
}

; Function Attrs: nounwind uwtable
define dso_local i32 @bumped(i32 noundef %0, i32 noundef %1) #0 {
  %3 = alloca i32, align 4
  %4 = alloca i32, align 4
  %5 = alloca i32, align 4
  store i32 %0, ptr %3, align 4, !tbaa !5
  store i32 %1, ptr %4, align 4, !tbaa !5
  call void @llvm.lifetime.start.p0(i64 4, ptr %5) #2
  %6 = load i32, ptr %3, align 4, !tbaa !5
  store i32 %6, ptr %5, align 4, !tbaa !5
  %7 = load i32, ptr %4, align 4, !tbaa !5
  %8 = icmp ne i32 %7, 0
  br i1 %8, label %9, label %12

9:                                                ; preds = %2
  %10 = load i32, ptr %3, align 4, !tbaa !5
  %11 = add nsw i32 %10, 1
  store i32 %11, ptr %5, align 4, !tbaa !5
  br label %12

12:                                               ; preds = %9, %2
  %13 = load i32, ptr %5, align 4, !tbaa !5
  call void @llvm.lifetime.end.p0(i64 4, ptr %5) #2
  ret i32 %13
}

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr captures(none)) #1

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr captures(none)) #1

; Function Attrs: nounwind uwtable
define dso_local i32 @folded(ptr noundef %0, i32 noundef %1) #0 {
  %3 = alloca ptr, align 8
  %4 = alloca i32, align 4
  %5 = alloca i32, align 4
  %6 = alloca i32, align 4
  %7 = alloca i32, align 4
  store ptr %0, ptr %3, align 8, !tbaa !9
  store i32 %1, ptr %4, align 4, !tbaa !5
  call void @llvm.lifetime.start.p0(i64 4, ptr %5) #2
  store i32 0, ptr %5, align 4, !tbaa !5
  call void @llvm.lifetime.start.p0(i64 4, ptr %6) #2
  store i32 0, ptr %6, align 4, !tbaa !5
  br label %8

8:                                                ; preds = %30, %2
  %9 = load i32, ptr %6, align 4, !tbaa !5
  %10 = load i32, ptr %4, align 4, !tbaa !5
  %11 = icmp slt i32 %9, %10
  br i1 %11, label %13, label %12

12:                                               ; preds = %8
  call void @llvm.lifetime.end.p0(i64 4, ptr %6) #2
  br label %33

13:                                               ; preds = %8
  call void @llvm.lifetime.start.p0(i64 4, ptr %7) #2
  %14 = load ptr, ptr %3, align 8, !tbaa !9
  %15 = load i32, ptr %6, align 4, !tbaa !5
  %16 = sext i32 %15 to i64
  %17 = getelementptr inbounds i32, ptr %14, i64 %16
  %18 = load i32, ptr %17, align 4, !tbaa !5
  store i32 %18, ptr %7, align 4, !tbaa !5
  %19 = load i32, ptr %7, align 4, !tbaa !5
  %20 = icmp sgt i32 %19, 0
  br i1 %20, label %21, label %25

21:                                               ; preds = %13
  %22 = load i32, ptr %7, align 4, !tbaa !5
  %23 = load i32, ptr %5, align 4, !tbaa !5
  %24 = add nsw i32 %23, %22
  store i32 %24, ptr %5, align 4, !tbaa !5
  br label %29

25:                                               ; preds = %13
  %26 = load i32, ptr %7, align 4, !tbaa !5
  %27 = load i32, ptr %5, align 4, !tbaa !5
  %28 = sub nsw i32 %27, %26
  store i32 %28, ptr %5, align 4, !tbaa !5
  br label %29

29:                                               ; preds = %25, %21
  call void @llvm.lifetime.end.p0(i64 4, ptr %7) #2
  br label %30

30:                                               ; preds = %29
  %31 = load i32, ptr %6, align 4, !tbaa !5
  %32 = add nsw i32 %31, 1
  store i32 %32, ptr %6, align 4, !tbaa !5
  br label %8, !llvm.loop !12

33:                                               ; preds = %12
  %34 = load i32, ptr %5, align 4, !tbaa !5
  call void @llvm.lifetime.end.p0(i64 4, ptr %5) #2
  ret i32 %34
}

; Function Attrs: nounwind uwtable
define dso_local i32 @safe_divide(i32 noundef %0, i32 noundef %1) #0 {
  %3 = alloca i32, align 4
  %4 = alloca i32, align 4
  store i32 %0, ptr %3, align 4, !tbaa !5
  store i32 %1, ptr %4, align 4, !tbaa !5
  %5 = load i32, ptr %4, align 4, !tbaa !5
  %6 = icmp ne i32 %5, 0
  br i1 %6, label %7, label %11

7:                                                ; preds = %2
  %8 = load i32, ptr %3, align 4, !tbaa !5
  %9 = load i32, ptr %4, align 4, !tbaa !5
  %10 = sdiv i32 %8, %9
  br label %12

11:                                               ; preds = %2
  br label %12

12:                                               ; preds = %11, %7
  %13 = phi i32 [ %10, %7 ], [ -1, %11 ]
  ret i32 %13
}

; Function Attrs: nounwind uwtable
define dso_local i32 @if_present(ptr noundef %0) #0 {
  %2 = alloca ptr, align 8
  store ptr %0, ptr %2, align 8, !tbaa !9
  %3 = load ptr, ptr %2, align 8, !tbaa !9
  %4 = icmp ne ptr %3, null
  br i1 %4, label %5, label %8

5:                                                ; preds = %1
  %6 = load ptr, ptr %2, align 8, !tbaa !9
  %7 = load i32, ptr %6, align 4, !tbaa !5
  br label %9

8:                                                ; preds = %1
  br label %9

9:                                                ; preds = %8, %5
  %10 = phi i32 [ %7, %5 ], [ 0, %8 ]
  ret i32 %10
}

; Function Attrs: nounwind uwtable
define dso_local i32 @one_call(i32 noundef %0) #0 {
  %2 = alloca i32, align 4
  store i32 %0, ptr %2, align 4, !tbaa !5
  %3 = load i32, ptr %2, align 4, !tbaa !5
  %4 = icmp ne i32 %3, 0
  br i1 %4, label %5, label %7

5:                                                ; preds = %1
  %6 = call i32 @bump(i32 noundef 2)
  br label %9

7:                                                ; preds = %1
  %8 = call i32 @bump(i32 noundef 5)
  br label %9

9:                                                ; preds = %7, %5
  %10 = phi i32 [ %6, %5 ], [ %8, %7 ]
  ret i32 %10
}

; Function Attrs: nounwind uwtable
define internal i32 @bump(i32 noundef %0) #0 {
  %2 = alloca i32, align 4
  store i32 %0, ptr %2, align 4, !tbaa !5
  %3 = load i32, ptr %2, align 4, !tbaa !5
  %4 = load i32, ptr @counter, align 4, !tbaa !5
  %5 = add nsw i32 %4, %3
  store i32 %5, ptr @counter, align 4, !tbaa !5
  %6 = load i32, ptr @counter, align 4, !tbaa !5
  ret i32 %6
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
!6 = !{!"int", !7, i64 0}
!7 = !{!"omnipotent char", !8, i64 0}
!8 = !{!"Simple C/C++ TBAA"}
!9 = !{!10, !10, i64 0}
!10 = !{!"p1 int", !11, i64 0}
!11 = !{!"any pointer", !7, i64 0}
!12 = distinct !{!12, !13, !14}
!13 = !{!"llvm.loop.mustprogress"}
!14 = !{!"llvm.loop.unroll.disable"}

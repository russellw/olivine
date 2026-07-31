; ModuleID = 'test/c/setjmp.c'
source_filename = "test/c/setjmp.c"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-linux-gnu"

%struct.__jmp_buf_tag = type { [8 x i64], i32, %struct.__sigset_t }
%struct.__sigset_t = type { [16 x i64] }

@landings = dso_local global i32 0, align 4
@env = internal global [1 x %struct.__jmp_buf_tag] zeroinitializer, align 16

; Function Attrs: nounwind uwtable
define dso_local i32 @over(ptr noundef %0, i32 noundef %1) #0 {
  %3 = alloca ptr, align 8
  %4 = alloca i32, align 4
  %5 = alloca i32, align 4
  %6 = alloca i32, align 4
  %7 = alloca i32, align 4
  store ptr %0, ptr %3, align 8, !tbaa !5
  store i32 %1, ptr %4, align 4, !tbaa !10
  call void @llvm.lifetime.start.p0(i64 4, ptr %5) #4
  store i32 0, ptr %5, align 4, !tbaa !10
  call void @llvm.lifetime.start.p0(i64 4, ptr %6) #4
  store i32 0, ptr %6, align 4, !tbaa !10
  br label %8

8:                                                ; preds = %29, %2
  %9 = load i32, ptr %6, align 4, !tbaa !10
  %10 = load i32, ptr %4, align 4, !tbaa !10
  %11 = icmp slt i32 %9, %10
  br i1 %11, label %13, label %12

12:                                               ; preds = %8
  call void @llvm.lifetime.end.p0(i64 4, ptr %6) #4
  br label %32

13:                                               ; preds = %8
  call void @llvm.lifetime.start.p0(i64 4, ptr %7) #4
  %14 = load ptr, ptr %3, align 8, !tbaa !5
  %15 = load i32, ptr %6, align 4, !tbaa !10
  %16 = sext i32 %15 to i64
  %17 = getelementptr inbounds i32, ptr %14, i64 %16
  %18 = load i32, ptr %17, align 4, !tbaa !10
  %19 = call i32 @guarded(i32 noundef %18)
  store i32 %19, ptr %7, align 4, !tbaa !10
  %20 = load i32, ptr %7, align 4, !tbaa !10
  %21 = icmp slt i32 %20, 0
  br i1 %21, label %22, label %25

22:                                               ; preds = %13
  %23 = load i32, ptr @landings, align 4, !tbaa !10
  %24 = add nsw i32 %23, 1
  store i32 %24, ptr @landings, align 4, !tbaa !10
  br label %25

25:                                               ; preds = %22, %13
  %26 = load i32, ptr %7, align 4, !tbaa !10
  %27 = load i32, ptr %5, align 4, !tbaa !10
  %28 = add nsw i32 %27, %26
  store i32 %28, ptr %5, align 4, !tbaa !10
  call void @llvm.lifetime.end.p0(i64 4, ptr %7) #4
  br label %29

29:                                               ; preds = %25
  %30 = load i32, ptr %6, align 4, !tbaa !10
  %31 = add nsw i32 %30, 1
  store i32 %31, ptr %6, align 4, !tbaa !10
  br label %8, !llvm.loop !12

32:                                               ; preds = %12
  %33 = load i32, ptr %5, align 4, !tbaa !10
  call void @llvm.lifetime.end.p0(i64 4, ptr %5) #4
  ret i32 %33
}

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr captures(none)) #1

; Function Attrs: nounwind uwtable
define internal i32 @guarded(i32 noundef %0) #0 {
  %2 = alloca i32, align 4
  %3 = alloca i32, align 4
  store i32 %0, ptr %3, align 4, !tbaa !10
  %4 = call i32 @_setjmp(ptr noundef @env) #5
  %5 = icmp ne i32 %4, 0
  br i1 %5, label %6, label %7

6:                                                ; preds = %1
  store i32 -1, ptr %2, align 4
  br label %13

7:                                                ; preds = %1
  %8 = load i32, ptr %3, align 4, !tbaa !10
  %9 = icmp sgt i32 %8, 2
  br i1 %9, label %10, label %11

10:                                               ; preds = %7
  call void @longjmp(ptr noundef @env, i32 noundef 1) #6
  unreachable

11:                                               ; preds = %7
  %12 = load i32, ptr %3, align 4, !tbaa !10
  store i32 %12, ptr %2, align 4
  br label %13

13:                                               ; preds = %11, %6
  %14 = load i32, ptr %2, align 4
  ret i32 %14
}

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr captures(none)) #1

; Function Attrs: nounwind uwtable
define dso_local i32 @with_helper(i32 noundef %0) #0 {
  %2 = alloca i32, align 4
  %3 = alloca i32, align 4
  %4 = alloca i32, align 4
  %5 = alloca i32, align 4
  store i32 %0, ptr %3, align 4, !tbaa !10
  call void @llvm.lifetime.start.p0(i64 4, ptr %4) #4
  store volatile i32 0, ptr %4, align 4, !tbaa !10
  %6 = call i32 @_setjmp(ptr noundef @env) #5
  %7 = icmp ne i32 %6, 0
  br i1 %7, label %8, label %10

8:                                                ; preds = %1
  %9 = load volatile i32, ptr %4, align 4, !tbaa !10
  store i32 %9, ptr %2, align 4
  store i32 1, ptr %5, align 4
  br label %19

10:                                               ; preds = %1
  %11 = load i32, ptr %3, align 4, !tbaa !10
  %12 = call i32 @twice(i32 noundef %11)
  store volatile i32 %12, ptr %4, align 4, !tbaa !10
  %13 = load volatile i32, ptr %4, align 4, !tbaa !10
  %14 = icmp sgt i32 %13, 8
  br i1 %14, label %15, label %16

15:                                               ; preds = %10
  call void @longjmp(ptr noundef @env, i32 noundef 1) #6
  unreachable

16:                                               ; preds = %10
  %17 = load volatile i32, ptr %4, align 4, !tbaa !10
  %18 = add nsw i32 %17, 100
  store i32 %18, ptr %2, align 4
  store i32 1, ptr %5, align 4
  br label %19

19:                                               ; preds = %16, %8
  call void @llvm.lifetime.end.p0(i64 4, ptr %4) #4
  %20 = load i32, ptr %2, align 4
  ret i32 %20
}

; Function Attrs: nounwind returns_twice
declare i32 @_setjmp(ptr noundef) #2

; Function Attrs: nounwind uwtable
define internal i32 @twice(i32 noundef %0) #0 {
  %2 = alloca i32, align 4
  store i32 %0, ptr %2, align 4, !tbaa !10
  %3 = load i32, ptr %2, align 4, !tbaa !10
  %4 = load i32, ptr %2, align 4, !tbaa !10
  %5 = add nsw i32 %3, %4
  ret i32 %5
}

; Function Attrs: noreturn nounwind
declare void @longjmp(ptr noundef, i32 noundef) #3

; Function Attrs: nounwind uwtable
define dso_local i32 @depth(i32 noundef %0) #0 {
  %2 = alloca i32, align 4
  %3 = alloca i32, align 4
  store i32 %0, ptr %2, align 4, !tbaa !10
  call void @llvm.lifetime.start.p0(i64 4, ptr %3) #4
  store volatile i32 0, ptr %3, align 4, !tbaa !10
  %4 = call i32 @_setjmp(ptr noundef @env) #5
  %5 = icmp eq i32 %4, 0
  br i1 %5, label %6, label %19

6:                                                ; preds = %1
  br label %7

7:                                                ; preds = %17, %6
  %8 = load volatile i32, ptr %3, align 4, !tbaa !10
  %9 = load i32, ptr %2, align 4, !tbaa !10
  %10 = icmp slt i32 %8, %9
  br i1 %10, label %11, label %18

11:                                               ; preds = %7
  %12 = load volatile i32, ptr %3, align 4, !tbaa !10
  %13 = add nsw i32 %12, 1
  store volatile i32 %13, ptr %3, align 4, !tbaa !10
  %14 = load volatile i32, ptr %3, align 4, !tbaa !10
  %15 = icmp eq i32 %14, 3
  br i1 %15, label %16, label %17

16:                                               ; preds = %11
  call void @longjmp(ptr noundef @env, i32 noundef 1) #6
  unreachable

17:                                               ; preds = %11
  br label %7, !llvm.loop !15

18:                                               ; preds = %7
  br label %19

19:                                               ; preds = %18, %1
  %20 = load volatile i32, ptr %3, align 4, !tbaa !10
  call void @llvm.lifetime.end.p0(i64 4, ptr %3) #4
  ret i32 %20
}

attributes #0 = { nounwind uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #1 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { nounwind returns_twice "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #3 = { noreturn nounwind "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #4 = { nounwind }
attributes #5 = { nounwind returns_twice }
attributes #6 = { noreturn nounwind }

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

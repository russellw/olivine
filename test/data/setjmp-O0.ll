; ModuleID = 'test/c/setjmp.c'
source_filename = "test/c/setjmp.c"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-linux-gnu"

%struct.__jmp_buf_tag = type { [8 x i64], i32, %struct.__sigset_t }
%struct.__sigset_t = type { [16 x i64] }

@landings = dso_local global i32 0, align 4
@env = internal global [1 x %struct.__jmp_buf_tag] zeroinitializer, align 16

; Function Attrs: noinline nounwind optnone uwtable
define dso_local i32 @over(ptr noundef %0, i32 noundef %1) #0 {
  %3 = alloca ptr, align 8
  %4 = alloca i32, align 4
  %5 = alloca i32, align 4
  %6 = alloca i32, align 4
  %7 = alloca i32, align 4
  store ptr %0, ptr %3, align 8
  store i32 %1, ptr %4, align 4
  store i32 0, ptr %5, align 4
  store i32 0, ptr %6, align 4
  br label %8

8:                                                ; preds = %28, %2
  %9 = load i32, ptr %6, align 4
  %10 = load i32, ptr %4, align 4
  %11 = icmp slt i32 %9, %10
  br i1 %11, label %12, label %31

12:                                               ; preds = %8
  %13 = load ptr, ptr %3, align 8
  %14 = load i32, ptr %6, align 4
  %15 = sext i32 %14 to i64
  %16 = getelementptr inbounds i32, ptr %13, i64 %15
  %17 = load i32, ptr %16, align 4
  %18 = call i32 @guarded(i32 noundef %17)
  store i32 %18, ptr %7, align 4
  %19 = load i32, ptr %7, align 4
  %20 = icmp slt i32 %19, 0
  br i1 %20, label %21, label %24

21:                                               ; preds = %12
  %22 = load i32, ptr @landings, align 4
  %23 = add nsw i32 %22, 1
  store i32 %23, ptr @landings, align 4
  br label %24

24:                                               ; preds = %21, %12
  %25 = load i32, ptr %7, align 4
  %26 = load i32, ptr %5, align 4
  %27 = add nsw i32 %26, %25
  store i32 %27, ptr %5, align 4
  br label %28

28:                                               ; preds = %24
  %29 = load i32, ptr %6, align 4
  %30 = add nsw i32 %29, 1
  store i32 %30, ptr %6, align 4
  br label %8, !llvm.loop !6

31:                                               ; preds = %8
  %32 = load i32, ptr %5, align 4
  ret i32 %32
}

; Function Attrs: noinline nounwind optnone uwtable
define internal i32 @guarded(i32 noundef %0) #0 {
  %2 = alloca i32, align 4
  %3 = alloca i32, align 4
  store i32 %0, ptr %3, align 4
  %4 = call i32 @_setjmp(ptr noundef @env) #3
  %5 = icmp ne i32 %4, 0
  br i1 %5, label %6, label %7

6:                                                ; preds = %1
  store i32 -1, ptr %2, align 4
  br label %13

7:                                                ; preds = %1
  %8 = load i32, ptr %3, align 4
  %9 = icmp sgt i32 %8, 2
  br i1 %9, label %10, label %11

10:                                               ; preds = %7
  call void @longjmp(ptr noundef @env, i32 noundef 1) #4
  unreachable

11:                                               ; preds = %7
  %12 = load i32, ptr %3, align 4
  store i32 %12, ptr %2, align 4
  br label %13

13:                                               ; preds = %11, %6
  %14 = load i32, ptr %2, align 4
  ret i32 %14
}

; Function Attrs: noinline nounwind optnone uwtable
define dso_local i32 @with_helper(i32 noundef %0) #0 {
  %2 = alloca i32, align 4
  %3 = alloca i32, align 4
  %4 = alloca i32, align 4
  store i32 %0, ptr %3, align 4
  store volatile i32 0, ptr %4, align 4
  %5 = call i32 @_setjmp(ptr noundef @env) #3
  %6 = icmp ne i32 %5, 0
  br i1 %6, label %7, label %9

7:                                                ; preds = %1
  %8 = load volatile i32, ptr %4, align 4
  store i32 %8, ptr %2, align 4
  br label %18

9:                                                ; preds = %1
  %10 = load i32, ptr %3, align 4
  %11 = call i32 @twice(i32 noundef %10)
  store volatile i32 %11, ptr %4, align 4
  %12 = load volatile i32, ptr %4, align 4
  %13 = icmp sgt i32 %12, 8
  br i1 %13, label %14, label %15

14:                                               ; preds = %9
  call void @longjmp(ptr noundef @env, i32 noundef 1) #4
  unreachable

15:                                               ; preds = %9
  %16 = load volatile i32, ptr %4, align 4
  %17 = add nsw i32 %16, 100
  store i32 %17, ptr %2, align 4
  br label %18

18:                                               ; preds = %15, %7
  %19 = load i32, ptr %2, align 4
  ret i32 %19
}

; Function Attrs: nounwind returns_twice
declare i32 @_setjmp(ptr noundef) #1

; Function Attrs: noinline nounwind optnone uwtable
define internal i32 @twice(i32 noundef %0) #0 {
  %2 = alloca i32, align 4
  store i32 %0, ptr %2, align 4
  %3 = load i32, ptr %2, align 4
  %4 = load i32, ptr %2, align 4
  %5 = add nsw i32 %3, %4
  ret i32 %5
}

; Function Attrs: noreturn nounwind
declare void @longjmp(ptr noundef, i32 noundef) #2

; Function Attrs: noinline nounwind optnone uwtable
define dso_local i32 @depth(i32 noundef %0) #0 {
  %2 = alloca i32, align 4
  %3 = alloca i32, align 4
  store i32 %0, ptr %2, align 4
  store volatile i32 0, ptr %3, align 4
  %4 = call i32 @_setjmp(ptr noundef @env) #3
  %5 = icmp eq i32 %4, 0
  br i1 %5, label %6, label %19

6:                                                ; preds = %1
  br label %7

7:                                                ; preds = %17, %6
  %8 = load volatile i32, ptr %3, align 4
  %9 = load i32, ptr %2, align 4
  %10 = icmp slt i32 %8, %9
  br i1 %10, label %11, label %18

11:                                               ; preds = %7
  %12 = load volatile i32, ptr %3, align 4
  %13 = add nsw i32 %12, 1
  store volatile i32 %13, ptr %3, align 4
  %14 = load volatile i32, ptr %3, align 4
  %15 = icmp eq i32 %14, 3
  br i1 %15, label %16, label %17

16:                                               ; preds = %11
  call void @longjmp(ptr noundef @env, i32 noundef 1) #4
  unreachable

17:                                               ; preds = %11
  br label %7, !llvm.loop !8

18:                                               ; preds = %7
  br label %19

19:                                               ; preds = %18, %1
  %20 = load volatile i32, ptr %3, align 4
  ret i32 %20
}

attributes #0 = { noinline nounwind optnone uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #1 = { nounwind returns_twice "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #2 = { noreturn nounwind "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #3 = { nounwind returns_twice }
attributes #4 = { noreturn nounwind }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 1, !"wchar_size", i32 4}
!1 = !{i32 8, !"PIC Level", i32 2}
!2 = !{i32 7, !"PIE Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Ubuntu clang version 21.1.8 (6ubuntu1)"}
!6 = distinct !{!6, !7}
!7 = !{!"llvm.loop.mustprogress"}
!8 = distinct !{!8, !7}

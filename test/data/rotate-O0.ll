; ModuleID = 'test/c/rotate.c'
source_filename = "test/c/rotate.c"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-linux-gnu"

@ticket = internal global i32 0, align 4

; Function Attrs: noinline nounwind optnone uwtable
define dso_local i32 @scale_all(ptr noundef %0, i32 noundef %1, ptr noundef %2) #0 {
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
  br label %24

24:                                               ; preds = %13
  %25 = load i32, ptr %8, align 4
  %26 = add nsw i32 %25, 1
  store i32 %26, ptr %8, align 4
  br label %9, !llvm.loop !6

27:                                               ; preds = %9
  %28 = load i32, ptr %7, align 4
  ret i32 %28
}

; Function Attrs: noinline nounwind optnone uwtable
define dso_local i32 @tickets_taken() #0 {
  %1 = load i32, ptr @ticket, align 4
  ret i32 %1
}

; Function Attrs: noinline nounwind optnone uwtable
define dso_local void @reset_tickets() #0 {
  store i32 0, ptr @ticket, align 4
  ret void
}

; Function Attrs: noinline nounwind optnone uwtable
define dso_local i32 @consume(i32 noundef %0) #0 {
  %2 = alloca i32, align 4
  %3 = alloca i32, align 4
  store i32 %0, ptr %2, align 4
  store i32 0, ptr %3, align 4
  br label %4

4:                                                ; preds = %8, %1
  %5 = call i32 @next_ticket()
  %6 = load i32, ptr %2, align 4
  %7 = icmp sle i32 %5, %6
  br i1 %7, label %8, label %12

8:                                                ; preds = %4
  %9 = load i32, ptr @ticket, align 4
  %10 = load i32, ptr %3, align 4
  %11 = add nsw i32 %10, %9
  store i32 %11, ptr %3, align 4
  br label %4, !llvm.loop !8

12:                                               ; preds = %4
  %13 = load i32, ptr %3, align 4
  ret i32 %13
}

; Function Attrs: noinline nounwind optnone uwtable
define internal i32 @next_ticket() #0 {
  %1 = load i32, ptr @ticket, align 4
  %2 = add nsw i32 %1, 1
  store i32 %2, ptr @ticket, align 4
  ret i32 %2
}

; Function Attrs: noinline nounwind optnone uwtable
define dso_local i32 @countdown(i32 noundef %0) #0 {
  %2 = alloca i32, align 4
  %3 = alloca i32, align 4
  store i32 %0, ptr %2, align 4
  store i32 0, ptr %3, align 4
  br label %4

4:                                                ; preds = %9, %1
  %5 = load i32, ptr %3, align 4
  %6 = add nsw i32 %5, 1
  store i32 %6, ptr %3, align 4
  %7 = load i32, ptr %2, align 4
  %8 = sub nsw i32 %7, 3
  store i32 %8, ptr %2, align 4
  br label %9

9:                                                ; preds = %4
  %10 = load i32, ptr %2, align 4
  %11 = icmp sgt i32 %10, 0
  br i1 %11, label %4, label %12, !llvm.loop !9

12:                                               ; preds = %9
  %13 = load i32, ptr %3, align 4
  ret i32 %13
}

attributes #0 = { noinline nounwind optnone uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }

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
!9 = distinct !{!9, !7}

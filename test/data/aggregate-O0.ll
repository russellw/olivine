; ModuleID = 'test/c/aggregate.c'
source_filename = "test/c/aggregate.c"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-linux-gnu"

%struct.body = type { %struct.point, %struct.point, double, [8 x i8] }
%struct.point = type { i32, i32 }

; Function Attrs: noinline nounwind optnone uwtable
define dso_local i32 @get_x(ptr noundef %0) #0 {
  %2 = alloca ptr, align 8
  store ptr %0, ptr %2, align 8
  %3 = load ptr, ptr %2, align 8
  %4 = getelementptr inbounds nuw %struct.body, ptr %3, i32 0, i32 0
  %5 = getelementptr inbounds nuw %struct.point, ptr %4, i32 0, i32 0
  %6 = load i32, ptr %5, align 8
  ret i32 %6
}

; Function Attrs: noinline nounwind optnone uwtable
define dso_local void @advance(ptr noundef %0) #0 {
  %2 = alloca ptr, align 8
  store ptr %0, ptr %2, align 8
  %3 = load ptr, ptr %2, align 8
  %4 = getelementptr inbounds nuw %struct.body, ptr %3, i32 0, i32 1
  %5 = getelementptr inbounds nuw %struct.point, ptr %4, i32 0, i32 0
  %6 = load i32, ptr %5, align 8
  %7 = load ptr, ptr %2, align 8
  %8 = getelementptr inbounds nuw %struct.body, ptr %7, i32 0, i32 0
  %9 = getelementptr inbounds nuw %struct.point, ptr %8, i32 0, i32 0
  %10 = load i32, ptr %9, align 8
  %11 = add nsw i32 %10, %6
  store i32 %11, ptr %9, align 8
  %12 = load ptr, ptr %2, align 8
  %13 = getelementptr inbounds nuw %struct.body, ptr %12, i32 0, i32 1
  %14 = getelementptr inbounds nuw %struct.point, ptr %13, i32 0, i32 1
  %15 = load i32, ptr %14, align 4
  %16 = load ptr, ptr %2, align 8
  %17 = getelementptr inbounds nuw %struct.body, ptr %16, i32 0, i32 0
  %18 = getelementptr inbounds nuw %struct.point, ptr %17, i32 0, i32 1
  %19 = load i32, ptr %18, align 4
  %20 = add nsw i32 %19, %15
  store i32 %20, ptr %18, align 4
  ret void
}

; Function Attrs: noinline nounwind optnone uwtable
define dso_local i64 @make(i32 noundef %0, i32 noundef %1) #0 {
  %3 = alloca %struct.point, align 4
  %4 = alloca i32, align 4
  %5 = alloca i32, align 4
  store i32 %0, ptr %4, align 4
  store i32 %1, ptr %5, align 4
  %6 = getelementptr inbounds nuw %struct.point, ptr %3, i32 0, i32 0
  %7 = load i32, ptr %4, align 4
  store i32 %7, ptr %6, align 4
  %8 = getelementptr inbounds nuw %struct.point, ptr %3, i32 0, i32 1
  %9 = load i32, ptr %5, align 4
  store i32 %9, ptr %8, align 4
  %10 = load i64, ptr %3, align 4
  ret i64 %10
}

; Function Attrs: noinline nounwind optnone uwtable
define dso_local i32 @grid_at(ptr noundef %0, i32 noundef %1, i32 noundef %2) #0 {
  %4 = alloca ptr, align 8
  %5 = alloca i32, align 4
  %6 = alloca i32, align 4
  store ptr %0, ptr %4, align 8
  store i32 %1, ptr %5, align 4
  store i32 %2, ptr %6, align 4
  %7 = load ptr, ptr %4, align 8
  %8 = load i32, ptr %5, align 4
  %9 = sext i32 %8 to i64
  %10 = getelementptr inbounds [8 x i32], ptr %7, i64 %9
  %11 = load i32, ptr %6, align 4
  %12 = sext i32 %11 to i64
  %13 = getelementptr inbounds [8 x i32], ptr %10, i64 0, i64 %12
  %14 = load i32, ptr %13, align 4
  ret i32 %14
}

; Function Attrs: noinline nounwind optnone uwtable
define dso_local signext i8 @first_letter(ptr noundef %0) #0 {
  %2 = alloca ptr, align 8
  store ptr %0, ptr %2, align 8
  %3 = load ptr, ptr %2, align 8
  %4 = getelementptr inbounds nuw %struct.body, ptr %3, i32 0, i32 3
  %5 = getelementptr inbounds [8 x i8], ptr %4, i64 0, i64 0
  %6 = load i8, ptr %5, align 8
  ret i8 %6
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

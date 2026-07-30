; ModuleID = 'test/c/reload.c'
source_filename = "test/c/reload.c"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-linux-gnu"

%struct.pair = type { i32, i32 }

; Function Attrs: noinline nounwind optnone uwtable
define dso_local i32 @square_b(ptr noundef %0) #0 {
  %2 = alloca ptr, align 8
  store ptr %0, ptr %2, align 8
  %3 = load ptr, ptr %2, align 8
  %4 = getelementptr inbounds nuw %struct.pair, ptr %3, i32 0, i32 1
  %5 = load i32, ptr %4, align 4
  %6 = load ptr, ptr %2, align 8
  %7 = getelementptr inbounds nuw %struct.pair, ptr %6, i32 0, i32 1
  %8 = load i32, ptr %7, align 4
  %9 = mul nsw i32 %5, %8
  ret i32 %9
}

; Function Attrs: noinline nounwind optnone uwtable
define dso_local i32 @written_then_read(ptr noundef %0, i32 noundef %1) #0 {
  %3 = alloca ptr, align 8
  %4 = alloca i32, align 4
  store ptr %0, ptr %3, align 8
  store i32 %1, ptr %4, align 4
  %5 = load i32, ptr %4, align 4
  %6 = load ptr, ptr %3, align 8
  %7 = getelementptr inbounds nuw %struct.pair, ptr %6, i32 0, i32 1
  store i32 %5, ptr %7, align 4
  %8 = load ptr, ptr %3, align 8
  %9 = getelementptr inbounds nuw %struct.pair, ptr %8, i32 0, i32 1
  %10 = load i32, ptr %9, align 4
  ret i32 %10
}

; Function Attrs: noinline nounwind optnone uwtable
define dso_local i32 @separate_slots(i32 noundef %0) #0 {
  %2 = alloca i32, align 4
  %3 = alloca %struct.pair, align 4
  %4 = alloca %struct.pair, align 4
  %5 = alloca i32, align 4
  store i32 %0, ptr %2, align 4
  %6 = getelementptr inbounds nuw %struct.pair, ptr %3, i32 0, i32 0
  %7 = load i32, ptr %2, align 4
  store i32 %7, ptr %6, align 4
  %8 = getelementptr inbounds nuw %struct.pair, ptr %3, i32 0, i32 1
  %9 = load i32, ptr %2, align 4
  %10 = add nsw i32 %9, 1
  store i32 %10, ptr %8, align 4
  call void @llvm.memset.p0.i64(ptr align 4 %4, i8 0, i64 8, i1 false)
  %11 = getelementptr inbounds nuw %struct.pair, ptr %3, i32 0, i32 1
  %12 = load i32, ptr %11, align 4
  store i32 %12, ptr %5, align 4
  %13 = getelementptr inbounds nuw %struct.pair, ptr %4, i32 0, i32 0
  store i32 3, ptr %13, align 4
  %14 = load i32, ptr %5, align 4
  %15 = getelementptr inbounds nuw %struct.pair, ptr %3, i32 0, i32 1
  %16 = load i32, ptr %15, align 4
  %17 = add nsw i32 %14, %16
  %18 = getelementptr inbounds nuw %struct.pair, ptr %4, i32 0, i32 0
  %19 = load i32, ptr %18, align 4
  %20 = add nsw i32 %17, %19
  ret i32 %20
}

; Function Attrs: nocallback nofree nounwind willreturn memory(argmem: write)
declare void @llvm.memset.p0.i64(ptr writeonly captures(none), i8, i64, i1 immarg) #1

; Function Attrs: noinline nounwind optnone uwtable
define dso_local i32 @both_ways(ptr noundef %0) #0 {
  %2 = alloca ptr, align 8
  %3 = alloca i32, align 4
  store ptr %0, ptr %2, align 8
  %4 = load ptr, ptr %2, align 8
  %5 = getelementptr inbounds nuw %struct.pair, ptr %4, i32 0, i32 1
  %6 = load i32, ptr %5, align 4
  store i32 %6, ptr %3, align 4
  %7 = load ptr, ptr %2, align 8
  %8 = getelementptr inbounds nuw %struct.pair, ptr %7, i32 0, i32 0
  store i32 7, ptr %8, align 4
  %9 = load i32, ptr %3, align 4
  %10 = load ptr, ptr %2, align 8
  %11 = getelementptr inbounds nuw %struct.pair, ptr %10, i32 0, i32 1
  %12 = load i32, ptr %11, align 4
  %13 = add nsw i32 %9, %12
  ret i32 %13
}

; Function Attrs: noinline nounwind optnone uwtable
define dso_local i32 @around_call(ptr noundef %0) #0 {
  %2 = alloca ptr, align 8
  %3 = alloca i32, align 4
  store ptr %0, ptr %2, align 8
  %4 = load ptr, ptr %2, align 8
  %5 = getelementptr inbounds nuw %struct.pair, ptr %4, i32 0, i32 1
  %6 = load i32, ptr %5, align 4
  store i32 %6, ptr %3, align 4
  call void @sink()
  %7 = load i32, ptr %3, align 4
  %8 = load ptr, ptr %2, align 8
  %9 = getelementptr inbounds nuw %struct.pair, ptr %8, i32 0, i32 1
  %10 = load i32, ptr %9, align 4
  %11 = add nsw i32 %7, %10
  ret i32 %11
}

declare void @sink() #2

; Function Attrs: noinline nounwind optnone uwtable
define dso_local i32 @confined_across_call(i32 noundef %0) #0 {
  %2 = alloca i32, align 4
  %3 = alloca %struct.pair, align 4
  %4 = alloca i32, align 4
  store i32 %0, ptr %2, align 4
  %5 = getelementptr inbounds nuw %struct.pair, ptr %3, i32 0, i32 0
  %6 = load i32, ptr %2, align 4
  store i32 %6, ptr %5, align 4
  %7 = getelementptr inbounds nuw %struct.pair, ptr %3, i32 0, i32 1
  %8 = load i32, ptr %2, align 4
  %9 = add nsw i32 %8, 1
  store i32 %9, ptr %7, align 4
  %10 = getelementptr inbounds nuw %struct.pair, ptr %3, i32 0, i32 1
  %11 = load i32, ptr %10, align 4
  store i32 %11, ptr %4, align 4
  call void @sink()
  %12 = load i32, ptr %4, align 4
  %13 = getelementptr inbounds nuw %struct.pair, ptr %3, i32 0, i32 1
  %14 = load i32, ptr %13, align 4
  %15 = add nsw i32 %12, %14
  ret i32 %15
}

; Function Attrs: noinline nounwind optnone uwtable
define dso_local i32 @through_the_store(ptr noundef %0, ptr noundef %1) #0 {
  %3 = alloca ptr, align 8
  %4 = alloca ptr, align 8
  %5 = alloca i32, align 4
  store ptr %0, ptr %3, align 8
  store ptr %1, ptr %4, align 8
  %6 = load ptr, ptr %3, align 8
  %7 = getelementptr inbounds nuw %struct.pair, ptr %6, i32 0, i32 1
  %8 = load i32, ptr %7, align 4
  store i32 %8, ptr %5, align 4
  %9 = load ptr, ptr %4, align 8
  %10 = getelementptr inbounds nuw %struct.pair, ptr %9, i32 0, i32 1
  store i32 100, ptr %10, align 4
  %11 = load i32, ptr %5, align 4
  %12 = load ptr, ptr %3, align 8
  %13 = getelementptr inbounds nuw %struct.pair, ptr %12, i32 0, i32 1
  %14 = load i32, ptr %13, align 4
  %15 = add nsw i32 %11, %14
  ret i32 %15
}

; Function Attrs: noinline nounwind optnone uwtable
define dso_local i32 @repeated(ptr noundef %0, i32 noundef %1) #0 {
  %3 = alloca ptr, align 8
  %4 = alloca i32, align 4
  %5 = alloca i32, align 4
  %6 = alloca i32, align 4
  store ptr %0, ptr %3, align 8
  store i32 %1, ptr %4, align 4
  %7 = load ptr, ptr %3, align 8
  %8 = getelementptr inbounds nuw %struct.pair, ptr %7, i32 0, i32 1
  %9 = load i32, ptr %8, align 4
  store i32 %9, ptr %5, align 4
  store i32 0, ptr %6, align 4
  br label %10

10:                                               ; preds = %20, %2
  %11 = load i32, ptr %6, align 4
  %12 = load i32, ptr %4, align 4
  %13 = icmp slt i32 %11, %12
  br i1 %13, label %14, label %23

14:                                               ; preds = %10
  %15 = load ptr, ptr %3, align 8
  %16 = getelementptr inbounds nuw %struct.pair, ptr %15, i32 0, i32 1
  %17 = load i32, ptr %16, align 4
  %18 = load i32, ptr %5, align 4
  %19 = add nsw i32 %18, %17
  store i32 %19, ptr %5, align 4
  br label %20

20:                                               ; preds = %14
  %21 = load i32, ptr %6, align 4
  %22 = add nsw i32 %21, 1
  store i32 %22, ptr %6, align 4
  br label %10, !llvm.loop !6

23:                                               ; preds = %10
  %24 = load i32, ptr %5, align 4
  ret i32 %24
}

; Function Attrs: noinline nounwind optnone uwtable
define dso_local i32 @accumulated(ptr noundef %0, ptr noundef %1, i32 noundef %2) #0 {
  %4 = alloca ptr, align 8
  %5 = alloca ptr, align 8
  %6 = alloca i32, align 4
  %7 = alloca i32, align 4
  %8 = alloca i32, align 4
  store ptr %0, ptr %4, align 8
  store ptr %1, ptr %5, align 8
  store i32 %2, ptr %6, align 4
  store i32 0, ptr %7, align 4
  store i32 0, ptr %8, align 4
  br label %9

9:                                                ; preds = %21, %3
  %10 = load i32, ptr %8, align 4
  %11 = load i32, ptr %6, align 4
  %12 = icmp slt i32 %10, %11
  br i1 %12, label %13, label %24

13:                                               ; preds = %9
  %14 = load i32, ptr %8, align 4
  %15 = load ptr, ptr %5, align 8
  store i32 %14, ptr %15, align 4
  %16 = load ptr, ptr %4, align 8
  %17 = getelementptr inbounds nuw %struct.pair, ptr %16, i32 0, i32 1
  %18 = load i32, ptr %17, align 4
  %19 = load i32, ptr %7, align 4
  %20 = add nsw i32 %19, %18
  store i32 %20, ptr %7, align 4
  br label %21

21:                                               ; preds = %13
  %22 = load i32, ptr %8, align 4
  %23 = add nsw i32 %22, 1
  store i32 %23, ptr %8, align 4
  br label %9, !llvm.loop !8

24:                                               ; preds = %9
  %25 = load i32, ptr %7, align 4
  ret i32 %25
}

attributes #0 = { noinline nounwind optnone uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #1 = { nocallback nofree nounwind willreturn memory(argmem: write) }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }

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

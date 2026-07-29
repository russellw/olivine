; ModuleID = 'test/c/unions.c'
source_filename = "test/c/unions.c"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-linux-gnu"

%union.bits = type { i32 }
%struct.flags = type { i16, [2 x i8] }
%struct.tight = type <{ i8, i32, i16 }>

; Function Attrs: noinline nounwind optnone uwtable
define dso_local i32 @punned(float noundef %0) #0 {
  %2 = alloca float, align 4
  %3 = alloca %union.bits, align 4
  store float %0, ptr %2, align 4
  %4 = load float, ptr %2, align 4
  store float %4, ptr %3, align 4
  %5 = load i32, ptr %3, align 4
  ret i32 %5
}

; Function Attrs: noinline nounwind optnone uwtable
define dso_local i32 @low_byte(i32 noundef %0) #0 {
  %2 = alloca i32, align 4
  %3 = alloca %union.bits, align 4
  store i32 %0, ptr %2, align 4
  %4 = load i32, ptr %2, align 4
  store i32 %4, ptr %3, align 4
  %5 = getelementptr inbounds [4 x i8], ptr %3, i64 0, i64 0
  %6 = load i8, ptr %5, align 4
  %7 = zext i8 %6 to i32
  ret i32 %7
}

; Function Attrs: noinline nounwind optnone uwtable
define dso_local i32 @get_kind(i32 %0) #0 {
  %2 = alloca %struct.flags, align 4
  store i32 %0, ptr %2, align 4
  %3 = load i16, ptr %2, align 4
  %4 = and i16 %3, 7
  %5 = zext i16 %4 to i32
  ret i32 %5
}

; Function Attrs: noinline nounwind optnone uwtable
define dso_local i32 @get_delta(i32 %0) #0 {
  %2 = alloca %struct.flags, align 4
  store i32 %0, ptr %2, align 4
  %3 = load i16, ptr %2, align 4
  %4 = ashr i16 %3, 4
  %5 = sext i16 %4 to i32
  ret i32 %5
}

; Function Attrs: noinline nounwind optnone uwtable
define dso_local i32 @set_live(i32 %0, i1 noundef zeroext %1) #0 {
  %3 = alloca %struct.flags, align 4
  %4 = alloca %struct.flags, align 4
  %5 = alloca i8, align 1
  store i32 %0, ptr %4, align 4
  %6 = zext i1 %1 to i8
  store i8 %6, ptr %5, align 1
  %7 = load i8, ptr %5, align 1
  %8 = trunc i8 %7 to i1
  %9 = zext i1 %8 to i32
  %10 = trunc i32 %9 to i16
  %11 = load i16, ptr %4, align 4
  %12 = and i16 %10, 1
  %13 = shl i16 %12, 3
  %14 = and i16 %11, -9
  %15 = or i16 %14, %13
  store i16 %15, ptr %4, align 4
  %16 = zext i16 %12 to i32
  call void @llvm.memcpy.p0.p0.i64(ptr align 4 %3, ptr align 4 %4, i64 4, i1 false)
  %17 = load i32, ptr %3, align 4
  ret i32 %17
}

; Function Attrs: nocallback nofree nounwind willreturn memory(argmem: readwrite)
declare void @llvm.memcpy.p0.p0.i64(ptr noalias writeonly captures(none), ptr noalias readonly captures(none), i64, i1 immarg) #1

; Function Attrs: noinline nounwind optnone uwtable
define dso_local i32 @tight_n(ptr noundef %0) #0 {
  %2 = alloca ptr, align 8
  store ptr %0, ptr %2, align 8
  %3 = load ptr, ptr %2, align 8
  %4 = getelementptr inbounds nuw %struct.tight, ptr %3, i32 0, i32 1
  %5 = load i32, ptr %4, align 1
  ret i32 %5
}

; Function Attrs: noinline nounwind optnone uwtable
define dso_local signext i16 @tight_s(ptr noundef %0) #0 {
  %2 = alloca ptr, align 8
  store ptr %0, ptr %2, align 8
  %3 = load ptr, ptr %2, align 8
  %4 = getelementptr inbounds nuw %struct.tight, ptr %3, i32 0, i32 2
  %5 = load i16, ptr %4, align 1
  ret i16 %5
}

; Function Attrs: noinline nounwind optnone uwtable
define dso_local i32 @next_colour(i32 noundef %0) #0 {
  %2 = alloca i32, align 4
  store i32 %0, ptr %2, align 4
  %3 = load i32, ptr %2, align 4
  %4 = icmp eq i32 %3, 8
  br i1 %4, label %5, label %6

5:                                                ; preds = %1
  br label %9

6:                                                ; preds = %1
  %7 = load i32, ptr %2, align 4
  %8 = add i32 %7, 1
  br label %9

9:                                                ; preds = %6, %5
  %10 = phi i32 [ 0, %5 ], [ %8, %6 ]
  ret i32 %10
}

; Function Attrs: noinline nounwind optnone uwtable
define dso_local zeroext i1 @truthy(i32 noundef %0) #0 {
  %2 = alloca i32, align 4
  store i32 %0, ptr %2, align 4
  %3 = load i32, ptr %2, align 4
  %4 = icmp ne i32 %3, 0
  ret i1 %4
}

attributes #0 = { noinline nounwind optnone uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #1 = { nocallback nofree nounwind willreturn memory(argmem: readwrite) }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 1, !"wchar_size", i32 4}
!1 = !{i32 8, !"PIC Level", i32 2}
!2 = !{i32 7, !"PIE Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Ubuntu clang version 21.1.8 (6ubuntu1)"}

; ModuleID = 'test/c/dse.c'
source_filename = "test/c/dse.c"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-linux-gnu"

%struct.triple = type { i32, i32, i32 }

@beacon = dso_local global i32 0, align 4

; Function Attrs: nounwind uwtable
define dso_local i32 @overwritten(ptr noundef %0, i32 noundef %1) #0 {
  %3 = alloca ptr, align 8
  %4 = alloca i32, align 4
  store ptr %0, ptr %3, align 8, !tbaa !5
  store i32 %1, ptr %4, align 4, !tbaa !10
  %5 = load i32, ptr %4, align 4, !tbaa !10
  %6 = load ptr, ptr %3, align 8, !tbaa !5
  store i32 %5, ptr %6, align 4, !tbaa !10
  %7 = load i32, ptr %4, align 4, !tbaa !10
  %8 = add nsw i32 %7, 1
  %9 = load ptr, ptr %3, align 8, !tbaa !5
  store i32 %8, ptr %9, align 4, !tbaa !10
  %10 = load ptr, ptr %3, align 8, !tbaa !5
  %11 = load i32, ptr %10, align 4, !tbaa !10
  ret i32 %11
}

; Function Attrs: nounwind uwtable
define dso_local i32 @guarded(ptr noundef %0, i32 noundef %1) #0 {
  %3 = alloca ptr, align 8
  %4 = alloca i32, align 4
  %5 = alloca i32, align 4
  store ptr %0, ptr %3, align 8, !tbaa !5
  store i32 %1, ptr %4, align 4, !tbaa !10
  %6 = load i32, ptr %4, align 4, !tbaa !10
  %7 = load ptr, ptr %3, align 8, !tbaa !5
  store i32 %6, ptr %7, align 4, !tbaa !10
  call void @llvm.lifetime.start.p0(i64 4, ptr %5) #3
  %8 = load ptr, ptr %3, align 8, !tbaa !5
  %9 = call i32 @peek(ptr noundef %8)
  store i32 %9, ptr %5, align 4, !tbaa !10
  %10 = load i32, ptr %4, align 4, !tbaa !10
  %11 = add nsw i32 %10, 1
  %12 = load ptr, ptr %3, align 8, !tbaa !5
  store i32 %11, ptr %12, align 4, !tbaa !10
  %13 = load i32, ptr %5, align 4, !tbaa !10
  call void @llvm.lifetime.end.p0(i64 4, ptr %5) #3
  ret i32 %13
}

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr captures(none)) #1

; Function Attrs: noinline nounwind uwtable
define internal i32 @peek(ptr noundef %0) #2 {
  %2 = alloca ptr, align 8
  store ptr %0, ptr %2, align 8, !tbaa !5
  %3 = load ptr, ptr %2, align 8, !tbaa !5
  %4 = load i32, ptr %3, align 4, !tbaa !10
  ret i32 %4
}

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr captures(none)) #1

; Function Attrs: nounwind uwtable
define dso_local i32 @one_way(ptr noundef %0, i32 noundef %1, i32 noundef %2) #0 {
  %4 = alloca ptr, align 8
  %5 = alloca i32, align 4
  %6 = alloca i32, align 4
  store ptr %0, ptr %4, align 8, !tbaa !5
  store i32 %1, ptr %5, align 4, !tbaa !10
  store i32 %2, ptr %6, align 4, !tbaa !10
  %7 = load i32, ptr %5, align 4, !tbaa !10
  %8 = load ptr, ptr %4, align 8, !tbaa !5
  store i32 %7, ptr %8, align 4, !tbaa !10
  %9 = load i32, ptr %6, align 4, !tbaa !10
  %10 = icmp ne i32 %9, 0
  br i1 %10, label %11, label %15

11:                                               ; preds = %3
  %12 = load i32, ptr %5, align 4, !tbaa !10
  %13 = add nsw i32 %12, 1
  %14 = load ptr, ptr %4, align 8, !tbaa !5
  store i32 %13, ptr %14, align 4, !tbaa !10
  br label %15

15:                                               ; preds = %11, %3
  %16 = load ptr, ptr %4, align 8, !tbaa !5
  %17 = load i32, ptr %16, align 4, !tbaa !10
  ret i32 %17
}

; Function Attrs: nounwind uwtable
define dso_local i32 @filled(i32 noundef %0) #0 {
  %2 = alloca i32, align 4
  %3 = alloca [4 x i32], align 16
  %4 = alloca i32, align 4
  store i32 %0, ptr %2, align 4, !tbaa !10
  call void @llvm.lifetime.start.p0(i64 16, ptr %3) #3
  %5 = load i32, ptr %2, align 4, !tbaa !10
  %6 = getelementptr inbounds [4 x i32], ptr %3, i64 0, i64 0
  store i32 %5, ptr %6, align 16, !tbaa !10
  %7 = load i32, ptr %2, align 4, !tbaa !10
  %8 = add nsw i32 %7, 1
  %9 = getelementptr inbounds [4 x i32], ptr %3, i64 0, i64 1
  store i32 %8, ptr %9, align 4, !tbaa !10
  call void @llvm.lifetime.start.p0(i64 4, ptr %4) #3
  %10 = getelementptr inbounds [4 x i32], ptr %3, i64 0, i64 0
  %11 = call i32 @head(ptr noundef %10)
  store i32 %11, ptr %4, align 4, !tbaa !10
  %12 = load i32, ptr %4, align 4, !tbaa !10
  %13 = getelementptr inbounds [4 x i32], ptr %3, i64 0, i64 2
  store i32 %12, ptr %13, align 8, !tbaa !10
  %14 = load i32, ptr %4, align 4, !tbaa !10
  %15 = add nsw i32 %14, 1
  %16 = getelementptr inbounds [4 x i32], ptr %3, i64 0, i64 3
  store i32 %15, ptr %16, align 4, !tbaa !10
  %17 = load i32, ptr %4, align 4, !tbaa !10
  call void @llvm.lifetime.end.p0(i64 4, ptr %4) #3
  call void @llvm.lifetime.end.p0(i64 16, ptr %3) #3
  ret i32 %17
}

; Function Attrs: noinline nounwind uwtable
define internal i32 @head(ptr noundef %0) #2 {
  %2 = alloca ptr, align 8
  store ptr %0, ptr %2, align 8, !tbaa !5
  %3 = load ptr, ptr %2, align 8, !tbaa !5
  %4 = getelementptr inbounds i32, ptr %3, i64 0
  %5 = load i32, ptr %4, align 4, !tbaa !10
  %6 = load ptr, ptr %2, align 8, !tbaa !5
  %7 = getelementptr inbounds i32, ptr %6, i64 1
  %8 = load i32, ptr %7, align 4, !tbaa !10
  %9 = add nsw i32 %5, %8
  ret i32 %9
}

; Function Attrs: nounwind uwtable
define dso_local i32 @refilled(i32 noundef %0) #0 {
  %2 = alloca i32, align 4
  %3 = alloca [4 x i32], align 16
  %4 = alloca i32, align 4
  store i32 %0, ptr %2, align 4, !tbaa !10
  call void @llvm.lifetime.start.p0(i64 16, ptr %3) #3
  %5 = load i32, ptr %2, align 4, !tbaa !10
  %6 = getelementptr inbounds [4 x i32], ptr %3, i64 0, i64 0
  store i32 %5, ptr %6, align 16, !tbaa !10
  %7 = load i32, ptr %2, align 4, !tbaa !10
  %8 = add nsw i32 %7, 1
  %9 = getelementptr inbounds [4 x i32], ptr %3, i64 0, i64 1
  store i32 %8, ptr %9, align 4, !tbaa !10
  call void @llvm.lifetime.start.p0(i64 4, ptr %4) #3
  %10 = getelementptr inbounds [4 x i32], ptr %3, i64 0, i64 0
  %11 = call i32 @head(ptr noundef %10)
  store i32 %11, ptr %4, align 4, !tbaa !10
  %12 = load i32, ptr %4, align 4, !tbaa !10
  %13 = getelementptr inbounds [4 x i32], ptr %3, i64 0, i64 2
  store i32 %12, ptr %13, align 8, !tbaa !10
  %14 = load i32, ptr %4, align 4, !tbaa !10
  %15 = add nsw i32 %14, 1
  %16 = getelementptr inbounds [4 x i32], ptr %3, i64 0, i64 3
  store i32 %15, ptr %16, align 4, !tbaa !10
  %17 = load i32, ptr %4, align 4, !tbaa !10
  %18 = getelementptr inbounds [4 x i32], ptr %3, i64 0, i64 0
  %19 = getelementptr inbounds i32, ptr %18, i64 2
  %20 = call i32 @peek(ptr noundef %19)
  %21 = add nsw i32 %17, %20
  %22 = getelementptr inbounds [4 x i32], ptr %3, i64 0, i64 0
  %23 = getelementptr inbounds i32, ptr %22, i64 3
  %24 = call i32 @peek(ptr noundef %23)
  %25 = add nsw i32 %21, %24
  call void @llvm.lifetime.end.p0(i64 4, ptr %4) #3
  call void @llvm.lifetime.end.p0(i64 16, ptr %3) #3
  ret i32 %25
}

; Function Attrs: nounwind uwtable
define dso_local i32 @built(i32 noundef %0) #0 {
  %2 = alloca i32, align 4
  %3 = alloca %struct.triple, align 4
  %4 = alloca i32, align 4
  store i32 %0, ptr %2, align 4, !tbaa !10
  call void @llvm.lifetime.start.p0(i64 12, ptr %3) #3
  %5 = load i32, ptr %2, align 4, !tbaa !10
  %6 = getelementptr inbounds nuw %struct.triple, ptr %3, i32 0, i32 0
  store i32 %5, ptr %6, align 4, !tbaa !12
  %7 = load i32, ptr %2, align 4, !tbaa !10
  %8 = mul nsw i32 %7, 2
  %9 = getelementptr inbounds nuw %struct.triple, ptr %3, i32 0, i32 1
  store i32 %8, ptr %9, align 4, !tbaa !14
  call void @llvm.lifetime.start.p0(i64 4, ptr %4) #3
  %10 = call i32 @flatten(ptr noundef %3)
  store i32 %10, ptr %4, align 4, !tbaa !10
  %11 = load i32, ptr %4, align 4, !tbaa !10
  %12 = getelementptr inbounds nuw %struct.triple, ptr %3, i32 0, i32 2
  store i32 %11, ptr %12, align 4, !tbaa !15
  %13 = load i32, ptr %4, align 4, !tbaa !10
  call void @llvm.lifetime.end.p0(i64 4, ptr %4) #3
  call void @llvm.lifetime.end.p0(i64 12, ptr %3) #3
  ret i32 %13
}

; Function Attrs: noinline nounwind uwtable
define internal i32 @flatten(ptr noundef %0) #2 {
  %2 = alloca ptr, align 8
  store ptr %0, ptr %2, align 8, !tbaa !16
  %3 = load ptr, ptr %2, align 8, !tbaa !16
  %4 = getelementptr inbounds nuw %struct.triple, ptr %3, i32 0, i32 0
  %5 = load i32, ptr %4, align 4, !tbaa !12
  %6 = load ptr, ptr %2, align 8, !tbaa !16
  %7 = getelementptr inbounds nuw %struct.triple, ptr %6, i32 0, i32 1
  %8 = load i32, ptr %7, align 4, !tbaa !14
  %9 = add nsw i32 %5, %8
  ret i32 %9
}

; Function Attrs: nounwind uwtable
define dso_local void @announce(i32 noundef %0) #0 {
  %2 = alloca i32, align 4
  store i32 %0, ptr %2, align 4, !tbaa !10
  %3 = load i32, ptr %2, align 4, !tbaa !10
  store volatile i32 %3, ptr @beacon, align 4, !tbaa !10
  %4 = load i32, ptr %2, align 4, !tbaa !10
  %5 = add nsw i32 %4, 1
  store volatile i32 %5, ptr @beacon, align 4, !tbaa !10
  ret void
}

; Function Attrs: nounwind uwtable
define dso_local void @each_turn(ptr noundef %0, i32 noundef %1) #0 {
  %3 = alloca ptr, align 8
  %4 = alloca i32, align 4
  %5 = alloca i32, align 4
  store ptr %0, ptr %3, align 8, !tbaa !5
  store i32 %1, ptr %4, align 4, !tbaa !10
  call void @llvm.lifetime.start.p0(i64 4, ptr %5) #3
  store i32 0, ptr %5, align 4, !tbaa !10
  br label %6

6:                                                ; preds = %14, %2
  %7 = load i32, ptr %5, align 4, !tbaa !10
  %8 = load i32, ptr %4, align 4, !tbaa !10
  %9 = icmp slt i32 %7, %8
  br i1 %9, label %11, label %10

10:                                               ; preds = %6
  call void @llvm.lifetime.end.p0(i64 4, ptr %5) #3
  br label %17

11:                                               ; preds = %6
  %12 = load i32, ptr %5, align 4, !tbaa !10
  %13 = load ptr, ptr %3, align 8, !tbaa !5
  store i32 %12, ptr %13, align 4, !tbaa !10
  br label %14

14:                                               ; preds = %11
  %15 = load i32, ptr %5, align 4, !tbaa !10
  %16 = add nsw i32 %15, 1
  store i32 %16, ptr %5, align 4, !tbaa !10
  br label %6, !llvm.loop !18

17:                                               ; preds = %10
  ret void
}

; Function Attrs: nounwind uwtable
define dso_local i32 @last_seen(i32 noundef %0) #0 {
  %2 = alloca i32, align 4
  %3 = alloca [2 x i32], align 4
  %4 = alloca i32, align 4
  store i32 %0, ptr %2, align 4, !tbaa !10
  call void @llvm.lifetime.start.p0(i64 8, ptr %3) #3
  %5 = getelementptr inbounds [2 x i32], ptr %3, i64 0, i64 0
  store i32 0, ptr %5, align 4, !tbaa !10
  %6 = getelementptr inbounds [2 x i32], ptr %3, i64 0, i64 1
  store i32 0, ptr %6, align 4, !tbaa !10
  call void @llvm.lifetime.start.p0(i64 4, ptr %4) #3
  store i32 0, ptr %4, align 4, !tbaa !10
  br label %7

7:                                                ; preds = %18, %1
  %8 = load i32, ptr %4, align 4, !tbaa !10
  %9 = load i32, ptr %2, align 4, !tbaa !10
  %10 = icmp slt i32 %8, %9
  br i1 %10, label %12, label %11

11:                                               ; preds = %7
  call void @llvm.lifetime.end.p0(i64 4, ptr %4) #3
  br label %21

12:                                               ; preds = %7
  %13 = load i32, ptr %4, align 4, !tbaa !10
  %14 = getelementptr inbounds [2 x i32], ptr %3, i64 0, i64 0
  store i32 %13, ptr %14, align 4, !tbaa !10
  %15 = load i32, ptr %4, align 4, !tbaa !10
  %16 = mul nsw i32 %15, 2
  %17 = getelementptr inbounds [2 x i32], ptr %3, i64 0, i64 1
  store i32 %16, ptr %17, align 4, !tbaa !10
  br label %18

18:                                               ; preds = %12
  %19 = load i32, ptr %4, align 4, !tbaa !10
  %20 = add nsw i32 %19, 1
  store i32 %20, ptr %4, align 4, !tbaa !10
  br label %7, !llvm.loop !21

21:                                               ; preds = %11
  %22 = getelementptr inbounds [2 x i32], ptr %3, i64 0, i64 0
  %23 = call i32 @head(ptr noundef %22)
  call void @llvm.lifetime.end.p0(i64 8, ptr %3) #3
  ret i32 %23
}

attributes #0 = { nounwind uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #1 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { noinline nounwind uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #3 = { nounwind }

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
!12 = !{!13, !11, i64 0}
!13 = !{!"triple", !11, i64 0, !11, i64 4, !11, i64 8}
!14 = !{!13, !11, i64 4}
!15 = !{!13, !11, i64 8}
!16 = !{!17, !17, i64 0}
!17 = !{!"p1 _ZTS6triple", !7, i64 0}
!18 = distinct !{!18, !19, !20}
!19 = !{!"llvm.loop.mustprogress"}
!20 = !{!"llvm.loop.unroll.disable"}
!21 = distinct !{!21, !19, !20}

; ModuleID = 'test/c/reload.c'
source_filename = "test/c/reload.c"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-linux-gnu"

%struct.pair = type { i32, i32 }

; Function Attrs: nounwind uwtable
define dso_local i32 @square_b(ptr noundef %0) #0 {
  %2 = alloca ptr, align 8
  store ptr %0, ptr %2, align 8, !tbaa !5
  %3 = load ptr, ptr %2, align 8, !tbaa !5
  %4 = getelementptr inbounds nuw %struct.pair, ptr %3, i32 0, i32 1
  %5 = load i32, ptr %4, align 4, !tbaa !10
  %6 = load ptr, ptr %2, align 8, !tbaa !5
  %7 = getelementptr inbounds nuw %struct.pair, ptr %6, i32 0, i32 1
  %8 = load i32, ptr %7, align 4, !tbaa !10
  %9 = mul nsw i32 %5, %8
  ret i32 %9
}

; Function Attrs: nounwind uwtable
define dso_local i32 @written_then_read(ptr noundef %0, i32 noundef %1) #0 {
  %3 = alloca ptr, align 8
  %4 = alloca i32, align 4
  store ptr %0, ptr %3, align 8, !tbaa !5
  store i32 %1, ptr %4, align 4, !tbaa !13
  %5 = load i32, ptr %4, align 4, !tbaa !13
  %6 = load ptr, ptr %3, align 8, !tbaa !5
  %7 = getelementptr inbounds nuw %struct.pair, ptr %6, i32 0, i32 1
  store i32 %5, ptr %7, align 4, !tbaa !10
  %8 = load ptr, ptr %3, align 8, !tbaa !5
  %9 = getelementptr inbounds nuw %struct.pair, ptr %8, i32 0, i32 1
  %10 = load i32, ptr %9, align 4, !tbaa !10
  ret i32 %10
}

; Function Attrs: nounwind uwtable
define dso_local i32 @separate_slots(i32 noundef %0) #0 {
  %2 = alloca i32, align 4
  %3 = alloca %struct.pair, align 4
  %4 = alloca %struct.pair, align 4
  %5 = alloca i32, align 4
  store i32 %0, ptr %2, align 4, !tbaa !13
  call void @llvm.lifetime.start.p0(i64 8, ptr %3) #4
  %6 = getelementptr inbounds nuw %struct.pair, ptr %3, i32 0, i32 0
  %7 = load i32, ptr %2, align 4, !tbaa !13
  store i32 %7, ptr %6, align 4, !tbaa !14
  %8 = getelementptr inbounds nuw %struct.pair, ptr %3, i32 0, i32 1
  %9 = load i32, ptr %2, align 4, !tbaa !13
  %10 = add nsw i32 %9, 1
  store i32 %10, ptr %8, align 4, !tbaa !10
  call void @llvm.lifetime.start.p0(i64 8, ptr %4) #4
  call void @llvm.memset.p0.i64(ptr align 4 %4, i8 0, i64 8, i1 false)
  call void @llvm.lifetime.start.p0(i64 4, ptr %5) #4
  %11 = getelementptr inbounds nuw %struct.pair, ptr %3, i32 0, i32 1
  %12 = load i32, ptr %11, align 4, !tbaa !10
  store i32 %12, ptr %5, align 4, !tbaa !13
  %13 = getelementptr inbounds nuw %struct.pair, ptr %4, i32 0, i32 0
  store i32 3, ptr %13, align 4, !tbaa !14
  %14 = load i32, ptr %5, align 4, !tbaa !13
  %15 = getelementptr inbounds nuw %struct.pair, ptr %3, i32 0, i32 1
  %16 = load i32, ptr %15, align 4, !tbaa !10
  %17 = add nsw i32 %14, %16
  %18 = getelementptr inbounds nuw %struct.pair, ptr %4, i32 0, i32 0
  %19 = load i32, ptr %18, align 4, !tbaa !14
  %20 = add nsw i32 %17, %19
  call void @llvm.lifetime.end.p0(i64 4, ptr %5) #4
  call void @llvm.lifetime.end.p0(i64 8, ptr %4) #4
  call void @llvm.lifetime.end.p0(i64 8, ptr %3) #4
  ret i32 %20
}

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr captures(none)) #1

; Function Attrs: nocallback nofree nounwind willreturn memory(argmem: write)
declare void @llvm.memset.p0.i64(ptr writeonly captures(none), i8, i64, i1 immarg) #2

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr captures(none)) #1

; Function Attrs: nounwind uwtable
define dso_local i32 @both_ways(ptr noundef %0) #0 {
  %2 = alloca ptr, align 8
  %3 = alloca i32, align 4
  store ptr %0, ptr %2, align 8, !tbaa !5
  call void @llvm.lifetime.start.p0(i64 4, ptr %3) #4
  %4 = load ptr, ptr %2, align 8, !tbaa !5
  %5 = getelementptr inbounds nuw %struct.pair, ptr %4, i32 0, i32 1
  %6 = load i32, ptr %5, align 4, !tbaa !10
  store i32 %6, ptr %3, align 4, !tbaa !13
  %7 = load ptr, ptr %2, align 8, !tbaa !5
  %8 = getelementptr inbounds nuw %struct.pair, ptr %7, i32 0, i32 0
  store i32 7, ptr %8, align 4, !tbaa !14
  %9 = load i32, ptr %3, align 4, !tbaa !13
  %10 = load ptr, ptr %2, align 8, !tbaa !5
  %11 = getelementptr inbounds nuw %struct.pair, ptr %10, i32 0, i32 1
  %12 = load i32, ptr %11, align 4, !tbaa !10
  %13 = add nsw i32 %9, %12
  call void @llvm.lifetime.end.p0(i64 4, ptr %3) #4
  ret i32 %13
}

; Function Attrs: nounwind uwtable
define dso_local i32 @around_call(ptr noundef %0) #0 {
  %2 = alloca ptr, align 8
  %3 = alloca i32, align 4
  store ptr %0, ptr %2, align 8, !tbaa !5
  call void @llvm.lifetime.start.p0(i64 4, ptr %3) #4
  %4 = load ptr, ptr %2, align 8, !tbaa !5
  %5 = getelementptr inbounds nuw %struct.pair, ptr %4, i32 0, i32 1
  %6 = load i32, ptr %5, align 4, !tbaa !10
  store i32 %6, ptr %3, align 4, !tbaa !13
  call void @sink()
  %7 = load i32, ptr %3, align 4, !tbaa !13
  %8 = load ptr, ptr %2, align 8, !tbaa !5
  %9 = getelementptr inbounds nuw %struct.pair, ptr %8, i32 0, i32 1
  %10 = load i32, ptr %9, align 4, !tbaa !10
  %11 = add nsw i32 %7, %10
  call void @llvm.lifetime.end.p0(i64 4, ptr %3) #4
  ret i32 %11
}

declare void @sink() #3

; Function Attrs: nounwind uwtable
define dso_local i32 @confined_across_call(i32 noundef %0) #0 {
  %2 = alloca i32, align 4
  %3 = alloca %struct.pair, align 4
  %4 = alloca i32, align 4
  store i32 %0, ptr %2, align 4, !tbaa !13
  call void @llvm.lifetime.start.p0(i64 8, ptr %3) #4
  %5 = getelementptr inbounds nuw %struct.pair, ptr %3, i32 0, i32 0
  %6 = load i32, ptr %2, align 4, !tbaa !13
  store i32 %6, ptr %5, align 4, !tbaa !14
  %7 = getelementptr inbounds nuw %struct.pair, ptr %3, i32 0, i32 1
  %8 = load i32, ptr %2, align 4, !tbaa !13
  %9 = add nsw i32 %8, 1
  store i32 %9, ptr %7, align 4, !tbaa !10
  call void @llvm.lifetime.start.p0(i64 4, ptr %4) #4
  %10 = getelementptr inbounds nuw %struct.pair, ptr %3, i32 0, i32 1
  %11 = load i32, ptr %10, align 4, !tbaa !10
  store i32 %11, ptr %4, align 4, !tbaa !13
  call void @sink()
  %12 = load i32, ptr %4, align 4, !tbaa !13
  %13 = getelementptr inbounds nuw %struct.pair, ptr %3, i32 0, i32 1
  %14 = load i32, ptr %13, align 4, !tbaa !10
  %15 = add nsw i32 %12, %14
  call void @llvm.lifetime.end.p0(i64 4, ptr %4) #4
  call void @llvm.lifetime.end.p0(i64 8, ptr %3) #4
  ret i32 %15
}

; Function Attrs: nounwind uwtable
define dso_local i32 @through_the_store(ptr noundef %0, ptr noundef %1) #0 {
  %3 = alloca ptr, align 8
  %4 = alloca ptr, align 8
  %5 = alloca i32, align 4
  store ptr %0, ptr %3, align 8, !tbaa !5
  store ptr %1, ptr %4, align 8, !tbaa !5
  call void @llvm.lifetime.start.p0(i64 4, ptr %5) #4
  %6 = load ptr, ptr %3, align 8, !tbaa !5
  %7 = getelementptr inbounds nuw %struct.pair, ptr %6, i32 0, i32 1
  %8 = load i32, ptr %7, align 4, !tbaa !10
  store i32 %8, ptr %5, align 4, !tbaa !13
  %9 = load ptr, ptr %4, align 8, !tbaa !5
  %10 = getelementptr inbounds nuw %struct.pair, ptr %9, i32 0, i32 1
  store i32 100, ptr %10, align 4, !tbaa !10
  %11 = load i32, ptr %5, align 4, !tbaa !13
  %12 = load ptr, ptr %3, align 8, !tbaa !5
  %13 = getelementptr inbounds nuw %struct.pair, ptr %12, i32 0, i32 1
  %14 = load i32, ptr %13, align 4, !tbaa !10
  %15 = add nsw i32 %11, %14
  call void @llvm.lifetime.end.p0(i64 4, ptr %5) #4
  ret i32 %15
}

; Function Attrs: nounwind uwtable
define dso_local i32 @repeated(ptr noundef %0, i32 noundef %1) #0 {
  %3 = alloca ptr, align 8
  %4 = alloca i32, align 4
  %5 = alloca i32, align 4
  %6 = alloca i32, align 4
  store ptr %0, ptr %3, align 8, !tbaa !5
  store i32 %1, ptr %4, align 4, !tbaa !13
  call void @llvm.lifetime.start.p0(i64 4, ptr %5) #4
  %7 = load ptr, ptr %3, align 8, !tbaa !5
  %8 = getelementptr inbounds nuw %struct.pair, ptr %7, i32 0, i32 1
  %9 = load i32, ptr %8, align 4, !tbaa !10
  store i32 %9, ptr %5, align 4, !tbaa !13
  call void @llvm.lifetime.start.p0(i64 4, ptr %6) #4
  store i32 0, ptr %6, align 4, !tbaa !13
  br label %10

10:                                               ; preds = %21, %2
  %11 = load i32, ptr %6, align 4, !tbaa !13
  %12 = load i32, ptr %4, align 4, !tbaa !13
  %13 = icmp slt i32 %11, %12
  br i1 %13, label %15, label %14

14:                                               ; preds = %10
  call void @llvm.lifetime.end.p0(i64 4, ptr %6) #4
  br label %24

15:                                               ; preds = %10
  %16 = load ptr, ptr %3, align 8, !tbaa !5
  %17 = getelementptr inbounds nuw %struct.pair, ptr %16, i32 0, i32 1
  %18 = load i32, ptr %17, align 4, !tbaa !10
  %19 = load i32, ptr %5, align 4, !tbaa !13
  %20 = add nsw i32 %19, %18
  store i32 %20, ptr %5, align 4, !tbaa !13
  br label %21

21:                                               ; preds = %15
  %22 = load i32, ptr %6, align 4, !tbaa !13
  %23 = add nsw i32 %22, 1
  store i32 %23, ptr %6, align 4, !tbaa !13
  br label %10, !llvm.loop !15

24:                                               ; preds = %14
  %25 = load i32, ptr %5, align 4, !tbaa !13
  call void @llvm.lifetime.end.p0(i64 4, ptr %5) #4
  ret i32 %25
}

; Function Attrs: nounwind uwtable
define dso_local i32 @accumulated(ptr noundef %0, ptr noundef %1, i32 noundef %2) #0 {
  %4 = alloca ptr, align 8
  %5 = alloca ptr, align 8
  %6 = alloca i32, align 4
  %7 = alloca i32, align 4
  %8 = alloca i32, align 4
  store ptr %0, ptr %4, align 8, !tbaa !5
  store ptr %1, ptr %5, align 8, !tbaa !18
  store i32 %2, ptr %6, align 4, !tbaa !13
  call void @llvm.lifetime.start.p0(i64 4, ptr %7) #4
  store i32 0, ptr %7, align 4, !tbaa !13
  call void @llvm.lifetime.start.p0(i64 4, ptr %8) #4
  store i32 0, ptr %8, align 4, !tbaa !13
  br label %9

9:                                                ; preds = %22, %3
  %10 = load i32, ptr %8, align 4, !tbaa !13
  %11 = load i32, ptr %6, align 4, !tbaa !13
  %12 = icmp slt i32 %10, %11
  br i1 %12, label %14, label %13

13:                                               ; preds = %9
  call void @llvm.lifetime.end.p0(i64 4, ptr %8) #4
  br label %25

14:                                               ; preds = %9
  %15 = load i32, ptr %8, align 4, !tbaa !13
  %16 = load ptr, ptr %5, align 8, !tbaa !18
  store i32 %15, ptr %16, align 4, !tbaa !13
  %17 = load ptr, ptr %4, align 8, !tbaa !5
  %18 = getelementptr inbounds nuw %struct.pair, ptr %17, i32 0, i32 1
  %19 = load i32, ptr %18, align 4, !tbaa !10
  %20 = load i32, ptr %7, align 4, !tbaa !13
  %21 = add nsw i32 %20, %19
  store i32 %21, ptr %7, align 4, !tbaa !13
  br label %22

22:                                               ; preds = %14
  %23 = load i32, ptr %8, align 4, !tbaa !13
  %24 = add nsw i32 %23, 1
  store i32 %24, ptr %8, align 4, !tbaa !13
  br label %9, !llvm.loop !20

25:                                               ; preds = %13
  %26 = load i32, ptr %7, align 4, !tbaa !13
  call void @llvm.lifetime.end.p0(i64 4, ptr %7) #4
  ret i32 %26
}

attributes #0 = { nounwind uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #1 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { nocallback nofree nounwind willreturn memory(argmem: write) }
attributes #3 = { "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #4 = { nounwind }

!llvm.module.flags = !{!0, !1, !2, !3}
!llvm.ident = !{!4}

!0 = !{i32 1, !"wchar_size", i32 4}
!1 = !{i32 8, !"PIC Level", i32 2}
!2 = !{i32 7, !"PIE Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{!"Ubuntu clang version 21.1.8 (6ubuntu1)"}
!5 = !{!6, !6, i64 0}
!6 = !{!"p1 _ZTS4pair", !7, i64 0}
!7 = !{!"any pointer", !8, i64 0}
!8 = !{!"omnipotent char", !9, i64 0}
!9 = !{!"Simple C/C++ TBAA"}
!10 = !{!11, !12, i64 4}
!11 = !{!"pair", !12, i64 0, !12, i64 4}
!12 = !{!"int", !8, i64 0}
!13 = !{!12, !12, i64 0}
!14 = !{!11, !12, i64 0}
!15 = distinct !{!15, !16, !17}
!16 = !{!"llvm.loop.mustprogress"}
!17 = !{!"llvm.loop.unroll.disable"}
!18 = !{!19, !19, i64 0}
!19 = !{!"p1 int", !7, i64 0}
!20 = distinct !{!20, !16, !17}

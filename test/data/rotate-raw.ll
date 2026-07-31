; ModuleID = 'test/c/rotate.c'
source_filename = "test/c/rotate.c"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-linux-gnu"

@ticket = internal global i32 0, align 4

; Function Attrs: nounwind uwtable
define dso_local i32 @scale_all(ptr noundef %0, i32 noundef %1, ptr noundef %2) #0 {
  %4 = alloca ptr, align 8
  %5 = alloca i32, align 4
  %6 = alloca ptr, align 8
  %7 = alloca i32, align 4
  %8 = alloca i32, align 4
  store ptr %0, ptr %4, align 8, !tbaa !5
  store i32 %1, ptr %5, align 4, !tbaa !10
  store ptr %2, ptr %6, align 8, !tbaa !5
  call void @llvm.lifetime.start.p0(i64 4, ptr %7) #2
  store i32 0, ptr %7, align 4, !tbaa !10
  call void @llvm.lifetime.start.p0(i64 4, ptr %8) #2
  store i32 0, ptr %8, align 4, !tbaa !10
  br label %9

9:                                                ; preds = %25, %3
  %10 = load i32, ptr %8, align 4, !tbaa !10
  %11 = load i32, ptr %5, align 4, !tbaa !10
  %12 = icmp slt i32 %10, %11
  br i1 %12, label %14, label %13

13:                                               ; preds = %9
  call void @llvm.lifetime.end.p0(i64 4, ptr %8) #2
  br label %28

14:                                               ; preds = %9
  %15 = load ptr, ptr %4, align 8, !tbaa !5
  %16 = load i32, ptr %8, align 4, !tbaa !10
  %17 = sext i32 %16 to i64
  %18 = getelementptr inbounds i32, ptr %15, i64 %17
  %19 = load i32, ptr %18, align 4, !tbaa !10
  %20 = load ptr, ptr %6, align 8, !tbaa !5
  %21 = load i32, ptr %20, align 4, !tbaa !10
  %22 = mul nsw i32 %19, %21
  %23 = load i32, ptr %7, align 4, !tbaa !10
  %24 = add nsw i32 %23, %22
  store i32 %24, ptr %7, align 4, !tbaa !10
  br label %25

25:                                               ; preds = %14
  %26 = load i32, ptr %8, align 4, !tbaa !10
  %27 = add nsw i32 %26, 1
  store i32 %27, ptr %8, align 4, !tbaa !10
  br label %9, !llvm.loop !12

28:                                               ; preds = %13
  %29 = load i32, ptr %7, align 4, !tbaa !10
  call void @llvm.lifetime.end.p0(i64 4, ptr %7) #2
  ret i32 %29
}

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr captures(none)) #1

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr captures(none)) #1

; Function Attrs: nounwind uwtable
define dso_local i32 @tickets_taken() #0 {
  %1 = load i32, ptr @ticket, align 4, !tbaa !10
  ret i32 %1
}

; Function Attrs: nounwind uwtable
define dso_local void @reset_tickets() #0 {
  store i32 0, ptr @ticket, align 4, !tbaa !10
  ret void
}

; Function Attrs: nounwind uwtable
define dso_local i32 @consume(i32 noundef %0) #0 {
  %2 = alloca i32, align 4
  %3 = alloca i32, align 4
  store i32 %0, ptr %2, align 4, !tbaa !10
  call void @llvm.lifetime.start.p0(i64 4, ptr %3) #2
  store i32 0, ptr %3, align 4, !tbaa !10
  br label %4

4:                                                ; preds = %8, %1
  %5 = call i32 @next_ticket()
  %6 = load i32, ptr %2, align 4, !tbaa !10
  %7 = icmp sle i32 %5, %6
  br i1 %7, label %8, label %12

8:                                                ; preds = %4
  %9 = load i32, ptr @ticket, align 4, !tbaa !10
  %10 = load i32, ptr %3, align 4, !tbaa !10
  %11 = add nsw i32 %10, %9
  store i32 %11, ptr %3, align 4, !tbaa !10
  br label %4, !llvm.loop !15

12:                                               ; preds = %4
  %13 = load i32, ptr %3, align 4, !tbaa !10
  call void @llvm.lifetime.end.p0(i64 4, ptr %3) #2
  ret i32 %13
}

; Function Attrs: nounwind uwtable
define internal i32 @next_ticket() #0 {
  %1 = load i32, ptr @ticket, align 4, !tbaa !10
  %2 = add nsw i32 %1, 1
  store i32 %2, ptr @ticket, align 4, !tbaa !10
  ret i32 %2
}

; Function Attrs: nounwind uwtable
define dso_local i32 @countdown(i32 noundef %0) #0 {
  %2 = alloca i32, align 4
  %3 = alloca i32, align 4
  store i32 %0, ptr %2, align 4, !tbaa !10
  call void @llvm.lifetime.start.p0(i64 4, ptr %3) #2
  store i32 0, ptr %3, align 4, !tbaa !10
  br label %4

4:                                                ; preds = %9, %1
  %5 = load i32, ptr %3, align 4, !tbaa !10
  %6 = add nsw i32 %5, 1
  store i32 %6, ptr %3, align 4, !tbaa !10
  %7 = load i32, ptr %2, align 4, !tbaa !10
  %8 = sub nsw i32 %7, 3
  store i32 %8, ptr %2, align 4, !tbaa !10
  br label %9

9:                                                ; preds = %4
  %10 = load i32, ptr %2, align 4, !tbaa !10
  %11 = icmp sgt i32 %10, 0
  br i1 %11, label %4, label %12, !llvm.loop !16

12:                                               ; preds = %9
  %13 = load i32, ptr %3, align 4, !tbaa !10
  call void @llvm.lifetime.end.p0(i64 4, ptr %3) #2
  ret i32 %13
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
!16 = distinct !{!16, !13, !14}

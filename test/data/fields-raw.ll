; ModuleID = 'test/c/fields.c'
source_filename = "test/c/fields.c"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-linux-gnu"

%struct.frame = type { %struct.corner, %struct.corner }
%struct.corner = type { i32, i32 }
%struct.label = type { i32, [4 x i8] }

; Function Attrs: nounwind uwtable
define dso_local i32 @area(i32 noundef %0, i32 noundef %1, i32 noundef %2, i32 noundef %3) #0 {
  %5 = alloca i32, align 4
  %6 = alloca i32, align 4
  %7 = alloca i32, align 4
  %8 = alloca i32, align 4
  %9 = alloca %struct.frame, align 4
  store i32 %0, ptr %5, align 4, !tbaa !5
  store i32 %1, ptr %6, align 4, !tbaa !5
  store i32 %2, ptr %7, align 4, !tbaa !5
  store i32 %3, ptr %8, align 4, !tbaa !5
  call void @llvm.lifetime.start.p0(i64 16, ptr %9) #3
  %10 = load i32, ptr %5, align 4, !tbaa !5
  %11 = getelementptr inbounds nuw %struct.frame, ptr %9, i32 0, i32 0
  %12 = getelementptr inbounds nuw %struct.corner, ptr %11, i32 0, i32 0
  store i32 %10, ptr %12, align 4, !tbaa !9
  %13 = load i32, ptr %6, align 4, !tbaa !5
  %14 = getelementptr inbounds nuw %struct.frame, ptr %9, i32 0, i32 0
  %15 = getelementptr inbounds nuw %struct.corner, ptr %14, i32 0, i32 1
  store i32 %13, ptr %15, align 4, !tbaa !12
  %16 = load i32, ptr %7, align 4, !tbaa !5
  %17 = getelementptr inbounds nuw %struct.frame, ptr %9, i32 0, i32 1
  %18 = getelementptr inbounds nuw %struct.corner, ptr %17, i32 0, i32 0
  store i32 %16, ptr %18, align 4, !tbaa !13
  %19 = load i32, ptr %8, align 4, !tbaa !5
  %20 = getelementptr inbounds nuw %struct.frame, ptr %9, i32 0, i32 1
  %21 = getelementptr inbounds nuw %struct.corner, ptr %20, i32 0, i32 1
  store i32 %19, ptr %21, align 4, !tbaa !14
  %22 = getelementptr inbounds nuw %struct.frame, ptr %9, i32 0, i32 1
  %23 = getelementptr inbounds nuw %struct.corner, ptr %22, i32 0, i32 0
  %24 = load i32, ptr %23, align 4, !tbaa !13
  %25 = getelementptr inbounds nuw %struct.frame, ptr %9, i32 0, i32 0
  %26 = getelementptr inbounds nuw %struct.corner, ptr %25, i32 0, i32 0
  %27 = load i32, ptr %26, align 4, !tbaa !9
  %28 = sub nsw i32 %24, %27
  %29 = getelementptr inbounds nuw %struct.frame, ptr %9, i32 0, i32 1
  %30 = getelementptr inbounds nuw %struct.corner, ptr %29, i32 0, i32 1
  %31 = load i32, ptr %30, align 4, !tbaa !14
  %32 = getelementptr inbounds nuw %struct.frame, ptr %9, i32 0, i32 0
  %33 = getelementptr inbounds nuw %struct.corner, ptr %32, i32 0, i32 1
  %34 = load i32, ptr %33, align 4, !tbaa !12
  %35 = sub nsw i32 %31, %34
  %36 = mul nsw i32 %28, %35
  call void @llvm.lifetime.end.p0(i64 16, ptr %9) #3
  ret i32 %36
}

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr captures(none)) #1

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr captures(none)) #1

; Function Attrs: nounwind uwtable
define dso_local i32 @pick_corner(i32 noundef %0, i32 noundef %1, i32 noundef %2) #0 {
  %4 = alloca i32, align 4
  %5 = alloca i32, align 4
  %6 = alloca i32, align 4
  %7 = alloca %struct.corner, align 4
  store i32 %0, ptr %4, align 4, !tbaa !5
  store i32 %1, ptr %5, align 4, !tbaa !5
  store i32 %2, ptr %6, align 4, !tbaa !5
  call void @llvm.lifetime.start.p0(i64 8, ptr %7) #3
  %8 = load i32, ptr %6, align 4, !tbaa !5
  %9 = icmp ne i32 %8, 0
  br i1 %9, label %10, label %15

10:                                               ; preds = %3
  %11 = load i32, ptr %4, align 4, !tbaa !5
  %12 = getelementptr inbounds nuw %struct.corner, ptr %7, i32 0, i32 0
  store i32 %11, ptr %12, align 4, !tbaa !15
  %13 = load i32, ptr %5, align 4, !tbaa !5
  %14 = getelementptr inbounds nuw %struct.corner, ptr %7, i32 0, i32 1
  store i32 %13, ptr %14, align 4, !tbaa !16
  br label %20

15:                                               ; preds = %3
  %16 = load i32, ptr %5, align 4, !tbaa !5
  %17 = getelementptr inbounds nuw %struct.corner, ptr %7, i32 0, i32 0
  store i32 %16, ptr %17, align 4, !tbaa !15
  %18 = load i32, ptr %4, align 4, !tbaa !5
  %19 = getelementptr inbounds nuw %struct.corner, ptr %7, i32 0, i32 1
  store i32 %18, ptr %19, align 4, !tbaa !16
  br label %20

20:                                               ; preds = %15, %10
  %21 = getelementptr inbounds nuw %struct.corner, ptr %7, i32 0, i32 0
  %22 = load i32, ptr %21, align 4, !tbaa !15
  %23 = mul nsw i32 %22, 10
  %24 = getelementptr inbounds nuw %struct.corner, ptr %7, i32 0, i32 1
  %25 = load i32, ptr %24, align 4, !tbaa !16
  %26 = add nsw i32 %23, %25
  call void @llvm.lifetime.end.p0(i64 8, ptr %7) #3
  ret i32 %26
}

; Function Attrs: nounwind uwtable
define dso_local i32 @walk(i32 noundef %0) #0 {
  %2 = alloca i32, align 4
  %3 = alloca i32, align 4
  %4 = alloca i32, align 4
  %5 = alloca %struct.corner, align 4
  store i32 %0, ptr %2, align 4, !tbaa !5
  call void @llvm.lifetime.start.p0(i64 4, ptr %3) #3
  store i32 0, ptr %3, align 4, !tbaa !5
  call void @llvm.lifetime.start.p0(i64 4, ptr %4) #3
  store i32 0, ptr %4, align 4, !tbaa !5
  br label %6

6:                                                ; preds = %25, %1
  %7 = load i32, ptr %4, align 4, !tbaa !5
  %8 = load i32, ptr %2, align 4, !tbaa !5
  %9 = icmp slt i32 %7, %8
  br i1 %9, label %11, label %10

10:                                               ; preds = %6
  call void @llvm.lifetime.end.p0(i64 4, ptr %4) #3
  br label %28

11:                                               ; preds = %6
  call void @llvm.lifetime.start.p0(i64 8, ptr %5) #3
  %12 = load i32, ptr %4, align 4, !tbaa !5
  %13 = getelementptr inbounds nuw %struct.corner, ptr %5, i32 0, i32 0
  store i32 %12, ptr %13, align 4, !tbaa !15
  %14 = load i32, ptr %2, align 4, !tbaa !5
  %15 = load i32, ptr %4, align 4, !tbaa !5
  %16 = sub nsw i32 %14, %15
  %17 = getelementptr inbounds nuw %struct.corner, ptr %5, i32 0, i32 1
  store i32 %16, ptr %17, align 4, !tbaa !16
  %18 = getelementptr inbounds nuw %struct.corner, ptr %5, i32 0, i32 0
  %19 = load i32, ptr %18, align 4, !tbaa !15
  %20 = getelementptr inbounds nuw %struct.corner, ptr %5, i32 0, i32 1
  %21 = load i32, ptr %20, align 4, !tbaa !16
  %22 = mul nsw i32 %19, %21
  %23 = load i32, ptr %3, align 4, !tbaa !5
  %24 = add nsw i32 %23, %22
  store i32 %24, ptr %3, align 4, !tbaa !5
  call void @llvm.lifetime.end.p0(i64 8, ptr %5) #3
  br label %25

25:                                               ; preds = %11
  %26 = load i32, ptr %4, align 4, !tbaa !5
  %27 = add nsw i32 %26, 1
  store i32 %27, ptr %4, align 4, !tbaa !5
  br label %6, !llvm.loop !17

28:                                               ; preds = %10
  %29 = load i32, ptr %3, align 4, !tbaa !5
  call void @llvm.lifetime.end.p0(i64 4, ptr %3) #3
  ret i32 %29
}

; Function Attrs: nounwind uwtable
define dso_local i32 @through_field(i32 noundef %0, i32 noundef %1) #0 {
  %3 = alloca i32, align 4
  %4 = alloca i32, align 4
  %5 = alloca %struct.corner, align 4
  store i32 %0, ptr %3, align 4, !tbaa !5
  store i32 %1, ptr %4, align 4, !tbaa !5
  call void @llvm.lifetime.start.p0(i64 8, ptr %5) #3
  %6 = load i32, ptr %3, align 4, !tbaa !5
  %7 = getelementptr inbounds nuw %struct.corner, ptr %5, i32 0, i32 0
  store i32 %6, ptr %7, align 4, !tbaa !15
  %8 = load i32, ptr %4, align 4, !tbaa !5
  %9 = getelementptr inbounds nuw %struct.corner, ptr %5, i32 0, i32 1
  store i32 %8, ptr %9, align 4, !tbaa !16
  %10 = getelementptr inbounds nuw %struct.corner, ptr %5, i32 0, i32 0
  %11 = load i32, ptr %4, align 4, !tbaa !5
  %12 = call i32 @add_into(ptr noundef %10, i32 noundef %11)
  %13 = getelementptr inbounds nuw %struct.corner, ptr %5, i32 0, i32 1
  %14 = load i32, ptr %13, align 4, !tbaa !16
  %15 = add nsw i32 %12, %14
  call void @llvm.lifetime.end.p0(i64 8, ptr %5) #3
  ret i32 %15
}

declare i32 @add_into(ptr noundef, i32 noundef) #2

; Function Attrs: nounwind uwtable
define dso_local i64 @make_corner(i32 noundef %0, i32 noundef %1) #0 {
  %3 = alloca %struct.corner, align 4
  %4 = alloca i32, align 4
  %5 = alloca i32, align 4
  store i32 %0, ptr %4, align 4, !tbaa !5
  store i32 %1, ptr %5, align 4, !tbaa !5
  %6 = load i32, ptr %4, align 4, !tbaa !5
  %7 = getelementptr inbounds nuw %struct.corner, ptr %3, i32 0, i32 0
  store i32 %6, ptr %7, align 4, !tbaa !15
  %8 = load i32, ptr %5, align 4, !tbaa !5
  %9 = getelementptr inbounds nuw %struct.corner, ptr %3, i32 0, i32 1
  store i32 %8, ptr %9, align 4, !tbaa !16
  %10 = load i64, ptr %3, align 4
  ret i64 %10
}

; Function Attrs: nounwind uwtable
define dso_local i32 @diagonal(i32 noundef %0, i32 noundef %1) #0 {
  %3 = alloca i32, align 4
  %4 = alloca i32, align 4
  %5 = alloca %struct.corner, align 4
  store i32 %0, ptr %3, align 4, !tbaa !5
  store i32 %1, ptr %4, align 4, !tbaa !5
  call void @llvm.lifetime.start.p0(i64 8, ptr %5) #3
  %6 = load i32, ptr %3, align 4, !tbaa !5
  %7 = load i32, ptr %4, align 4, !tbaa !5
  %8 = call i64 @make_corner(i32 noundef %6, i32 noundef %7)
  store i64 %8, ptr %5, align 4
  %9 = getelementptr inbounds nuw %struct.corner, ptr %5, i32 0, i32 0
  %10 = load i32, ptr %9, align 4, !tbaa !15
  %11 = getelementptr inbounds nuw %struct.corner, ptr %5, i32 0, i32 1
  %12 = load i32, ptr %11, align 4, !tbaa !16
  %13 = sub nsw i32 %10, %12
  call void @llvm.lifetime.end.p0(i64 8, ptr %5) #3
  ret i32 %13
}

; Function Attrs: nounwind uwtable
define dso_local i32 @tag_at(i32 noundef %0, i32 noundef %1) #0 {
  %3 = alloca i32, align 4
  %4 = alloca i32, align 4
  %5 = alloca %struct.label, align 4
  store i32 %0, ptr %3, align 4, !tbaa !5
  store i32 %1, ptr %4, align 4, !tbaa !5
  call void @llvm.lifetime.start.p0(i64 8, ptr %5) #3
  %6 = load i32, ptr %3, align 4, !tbaa !5
  %7 = getelementptr inbounds nuw %struct.label, ptr %5, i32 0, i32 0
  store i32 %6, ptr %7, align 4, !tbaa !20
  %8 = getelementptr inbounds nuw %struct.label, ptr %5, i32 0, i32 1
  %9 = getelementptr inbounds [4 x i8], ptr %8, i64 0, i64 0
  store i8 111, ptr %9, align 4, !tbaa !22
  %10 = getelementptr inbounds nuw %struct.label, ptr %5, i32 0, i32 1
  %11 = getelementptr inbounds [4 x i8], ptr %10, i64 0, i64 1
  store i8 108, ptr %11, align 1, !tbaa !22
  %12 = getelementptr inbounds nuw %struct.label, ptr %5, i32 0, i32 1
  %13 = getelementptr inbounds [4 x i8], ptr %12, i64 0, i64 2
  store i8 105, ptr %13, align 2, !tbaa !22
  %14 = getelementptr inbounds nuw %struct.label, ptr %5, i32 0, i32 1
  %15 = getelementptr inbounds [4 x i8], ptr %14, i64 0, i64 3
  store i8 0, ptr %15, align 1, !tbaa !22
  %16 = getelementptr inbounds nuw %struct.label, ptr %5, i32 0, i32 0
  %17 = load i32, ptr %16, align 4, !tbaa !20
  %18 = getelementptr inbounds nuw %struct.label, ptr %5, i32 0, i32 1
  %19 = load i32, ptr %4, align 4, !tbaa !5
  %20 = and i32 %19, 3
  %21 = sext i32 %20 to i64
  %22 = getelementptr inbounds [4 x i8], ptr %18, i64 0, i64 %21
  %23 = load i8, ptr %22, align 1, !tbaa !22
  %24 = sext i8 %23 to i32
  %25 = add nsw i32 %17, %24
  call void @llvm.lifetime.end.p0(i64 8, ptr %5) #3
  ret i32 %25
}

attributes #0 = { nounwind uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #1 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #3 = { nounwind }

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
!9 = !{!10, !6, i64 0}
!10 = !{!"frame", !11, i64 0, !11, i64 8}
!11 = !{!"corner", !6, i64 0, !6, i64 4}
!12 = !{!10, !6, i64 4}
!13 = !{!10, !6, i64 8}
!14 = !{!10, !6, i64 12}
!15 = !{!11, !6, i64 0}
!16 = !{!11, !6, i64 4}
!17 = distinct !{!17, !18, !19}
!18 = !{!"llvm.loop.mustprogress"}
!19 = !{!"llvm.loop.unroll.disable"}
!20 = !{!21, !6, i64 0}
!21 = !{!"label", !6, i64 0, !7, i64 4}
!22 = !{!7, !7, i64 0}

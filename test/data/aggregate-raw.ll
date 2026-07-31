; ModuleID = 'test/c/aggregate.c'
source_filename = "test/c/aggregate.c"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-linux-gnu"

%struct.body = type { %struct.point, %struct.point, double, [8 x i8] }
%struct.point = type { i32, i32 }

; Function Attrs: nounwind uwtable
define dso_local i32 @get_x(ptr noundef %0) #0 {
  %2 = alloca ptr, align 8
  store ptr %0, ptr %2, align 8, !tbaa !5
  %3 = load ptr, ptr %2, align 8, !tbaa !5
  %4 = getelementptr inbounds nuw %struct.body, ptr %3, i32 0, i32 0
  %5 = getelementptr inbounds nuw %struct.point, ptr %4, i32 0, i32 0
  %6 = load i32, ptr %5, align 8, !tbaa !10
  ret i32 %6
}

; Function Attrs: nounwind uwtable
define dso_local void @advance(ptr noundef %0) #0 {
  %2 = alloca ptr, align 8
  store ptr %0, ptr %2, align 8, !tbaa !5
  %3 = load ptr, ptr %2, align 8, !tbaa !5
  %4 = getelementptr inbounds nuw %struct.body, ptr %3, i32 0, i32 1
  %5 = getelementptr inbounds nuw %struct.point, ptr %4, i32 0, i32 0
  %6 = load i32, ptr %5, align 8, !tbaa !15
  %7 = load ptr, ptr %2, align 8, !tbaa !5
  %8 = getelementptr inbounds nuw %struct.body, ptr %7, i32 0, i32 0
  %9 = getelementptr inbounds nuw %struct.point, ptr %8, i32 0, i32 0
  %10 = load i32, ptr %9, align 8, !tbaa !10
  %11 = add nsw i32 %10, %6
  store i32 %11, ptr %9, align 8, !tbaa !10
  %12 = load ptr, ptr %2, align 8, !tbaa !5
  %13 = getelementptr inbounds nuw %struct.body, ptr %12, i32 0, i32 1
  %14 = getelementptr inbounds nuw %struct.point, ptr %13, i32 0, i32 1
  %15 = load i32, ptr %14, align 4, !tbaa !16
  %16 = load ptr, ptr %2, align 8, !tbaa !5
  %17 = getelementptr inbounds nuw %struct.body, ptr %16, i32 0, i32 0
  %18 = getelementptr inbounds nuw %struct.point, ptr %17, i32 0, i32 1
  %19 = load i32, ptr %18, align 4, !tbaa !17
  %20 = add nsw i32 %19, %15
  store i32 %20, ptr %18, align 4, !tbaa !17
  ret void
}

; Function Attrs: nounwind uwtable
define dso_local i64 @make(i32 noundef %0, i32 noundef %1) #0 {
  %3 = alloca %struct.point, align 4
  %4 = alloca i32, align 4
  %5 = alloca i32, align 4
  store i32 %0, ptr %4, align 4, !tbaa !18
  store i32 %1, ptr %5, align 4, !tbaa !18
  %6 = getelementptr inbounds nuw %struct.point, ptr %3, i32 0, i32 0
  %7 = load i32, ptr %4, align 4, !tbaa !18
  store i32 %7, ptr %6, align 4, !tbaa !19
  %8 = getelementptr inbounds nuw %struct.point, ptr %3, i32 0, i32 1
  %9 = load i32, ptr %5, align 4, !tbaa !18
  store i32 %9, ptr %8, align 4, !tbaa !20
  %10 = load i64, ptr %3, align 4
  ret i64 %10
}

; Function Attrs: nounwind uwtable
define dso_local i32 @grid_at(ptr noundef %0, i32 noundef %1, i32 noundef %2) #0 {
  %4 = alloca ptr, align 8
  %5 = alloca i32, align 4
  %6 = alloca i32, align 4
  store ptr %0, ptr %4, align 8, !tbaa !21
  store i32 %1, ptr %5, align 4, !tbaa !18
  store i32 %2, ptr %6, align 4, !tbaa !18
  %7 = load ptr, ptr %4, align 8, !tbaa !21
  %8 = load i32, ptr %5, align 4, !tbaa !18
  %9 = sext i32 %8 to i64
  %10 = getelementptr inbounds [8 x i32], ptr %7, i64 %9
  %11 = load i32, ptr %6, align 4, !tbaa !18
  %12 = sext i32 %11 to i64
  %13 = getelementptr inbounds [8 x i32], ptr %10, i64 0, i64 %12
  %14 = load i32, ptr %13, align 4, !tbaa !18
  ret i32 %14
}

; Function Attrs: nounwind uwtable
define dso_local signext i8 @first_letter(ptr noundef %0) #0 {
  %2 = alloca ptr, align 8
  store ptr %0, ptr %2, align 8, !tbaa !5
  %3 = load ptr, ptr %2, align 8, !tbaa !5
  %4 = getelementptr inbounds nuw %struct.body, ptr %3, i32 0, i32 3
  %5 = getelementptr inbounds [8 x i8], ptr %4, i64 0, i64 0
  %6 = load i8, ptr %5, align 8, !tbaa !23
  ret i8 %6
}

attributes #0 = { nounwind uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }

!llvm.module.flags = !{!0, !1, !2, !3}
!llvm.ident = !{!4}

!0 = !{i32 1, !"wchar_size", i32 4}
!1 = !{i32 8, !"PIC Level", i32 2}
!2 = !{i32 7, !"PIE Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{!"Ubuntu clang version 21.1.8 (6ubuntu1)"}
!5 = !{!6, !6, i64 0}
!6 = !{!"p1 _ZTS4body", !7, i64 0}
!7 = !{!"any pointer", !8, i64 0}
!8 = !{!"omnipotent char", !9, i64 0}
!9 = !{!"Simple C/C++ TBAA"}
!10 = !{!11, !13, i64 0}
!11 = !{!"body", !12, i64 0, !12, i64 8, !14, i64 16, !8, i64 24}
!12 = !{!"point", !13, i64 0, !13, i64 4}
!13 = !{!"int", !8, i64 0}
!14 = !{!"double", !8, i64 0}
!15 = !{!11, !13, i64 8}
!16 = !{!11, !13, i64 12}
!17 = !{!11, !13, i64 4}
!18 = !{!13, !13, i64 0}
!19 = !{!12, !13, i64 0}
!20 = !{!12, !13, i64 4}
!21 = !{!22, !22, i64 0}
!22 = !{!"p1 int", !7, i64 0}
!23 = !{!8, !8, i64 0}

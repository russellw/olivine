; ModuleID = 'test/c/indirect.c'
source_filename = "test/c/indirect.c"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-linux-gnu"

@ops = internal unnamed_addr constant [3 x ptr] [ptr @add, ptr @sub, ptr @mul], align 16

; Function Attrs: nounwind uwtable
define dso_local i32 @dispatch(i32 noundef %0, i32 noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = urem i32 %0, 3
  %5 = zext nneg i32 %4 to i64
  %6 = getelementptr inbounds nuw [3 x ptr], ptr @ops, i64 0, i64 %5
  %7 = load ptr, ptr %6, align 8, !tbaa !5
  %8 = tail call i32 %7(i32 noundef %1, i32 noundef %2) #3
  ret i32 %8
}

; Function Attrs: nofree nosync nounwind memory(none) uwtable
define dso_local i32 @fib(i32 noundef %0) local_unnamed_addr #1 {
  br label %2

2:                                                ; preds = %6, %1
  %3 = phi i32 [ 0, %1 ], [ %10, %6 ]
  %4 = phi i32 [ %0, %1 ], [ %9, %6 ]
  %5 = icmp slt i32 %4, 2
  br i1 %5, label %11, label %6

6:                                                ; preds = %2
  %7 = add nsw i32 %4, -1
  %8 = tail call i32 @fib(i32 noundef %7)
  %9 = add nsw i32 %4, -2
  %10 = add nsw i32 %3, %8
  br label %2

11:                                               ; preds = %2
  %12 = add nsw i32 %3, %4
  ret i32 %12
}

; Function Attrs: nofree nosync nounwind memory(none) uwtable
define dso_local i32 @gcd(i32 noundef %0, i32 noundef %1) local_unnamed_addr #1 {
  br label %3

3:                                                ; preds = %7, %2
  %4 = phi i32 [ %0, %2 ], [ %5, %7 ]
  %5 = phi i32 [ %1, %2 ], [ %8, %7 ]
  %6 = icmp eq i32 %5, 0
  br i1 %6, label %9, label %7

7:                                                ; preds = %3
  %8 = srem i32 %4, %5
  br label %3

9:                                                ; preds = %3
  ret i32 %4
}

; Function Attrs: nofree nosync nounwind memory(none) uwtable
define dso_local range(i32 -1, 2) i32 @parity(i32 noundef %0) local_unnamed_addr #1 {
  %2 = icmp slt i32 %0, 0
  br i1 %2, label %5, label %3

3:                                                ; preds = %1
  %4 = tail call fastcc i32 @even_(i32 noundef %0)
  br label %5

5:                                                ; preds = %1, %3
  %6 = phi i32 [ %4, %3 ], [ -1, %1 ]
  ret i32 %6
}

; Function Attrs: nofree nosync nounwind memory(none) uwtable
define internal fastcc range(i32 0, 2) i32 @even_(i32 noundef range(i32 0, -2147483648) %0) unnamed_addr #1 {
  br label %2

2:                                                ; preds = %4, %1
  %3 = phi i32 [ %0, %1 ], [ %5, %4 ]
  switch i32 %3, label %4 [
    i32 0, label %7
    i32 1, label %6
  ]

4:                                                ; preds = %2
  %5 = add nsw i32 %3, -2
  br label %2

6:                                                ; preds = %2
  br label %7

7:                                                ; preds = %2, %6
  %8 = phi i32 [ 1, %2 ], [ 0, %6 ]
  ret i32 %8
}

; Function Attrs: nounwind uwtable
define dso_local i32 @apply_twice(ptr noundef readonly captures(none) %0, i32 noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = tail call i32 %0(i32 noundef %1, i32 noundef %2) #3
  %5 = tail call i32 %0(i32 noundef %4, i32 noundef %2) #3
  ret i32 %5
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind willreturn memory(none) uwtable
define internal i32 @add(i32 noundef %0, i32 noundef %1) #2 {
  %3 = add nsw i32 %1, %0
  ret i32 %3
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind willreturn memory(none) uwtable
define internal i32 @sub(i32 noundef %0, i32 noundef %1) #2 {
  %3 = sub nsw i32 %0, %1
  ret i32 %3
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind willreturn memory(none) uwtable
define internal i32 @mul(i32 noundef %0, i32 noundef %1) #2 {
  %3 = mul nsw i32 %1, %0
  ret i32 %3
}

attributes #0 = { nounwind uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #1 = { nofree nosync nounwind memory(none) uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #2 = { mustprogress nofree norecurse nosync nounwind willreturn memory(none) uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #3 = { nounwind }

!llvm.module.flags = !{!0, !1, !2, !3}
!llvm.ident = !{!4}

!0 = !{i32 1, !"wchar_size", i32 4}
!1 = !{i32 8, !"PIC Level", i32 2}
!2 = !{i32 7, !"PIE Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{!"Ubuntu clang version 21.1.8 (6ubuntu1)"}
!5 = !{!6, !6, i64 0}
!6 = !{!"any pointer", !7, i64 0}
!7 = !{!"omnipotent char", !8, i64 0}
!8 = !{!"Simple C/C++ TBAA"}

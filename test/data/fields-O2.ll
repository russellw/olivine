; ModuleID = 'test/c/fields.c'
source_filename = "test/c/fields.c"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-linux-gnu"

%struct.corner = type { i32, i32 }
%struct.label = type { i32, [4 x i8] }

; Function Attrs: mustprogress nofree norecurse nosync nounwind willreturn memory(none) uwtable
define dso_local i32 @area(i32 noundef %0, i32 noundef %1, i32 noundef %2, i32 noundef %3) local_unnamed_addr #0 {
  %5 = sub nsw i32 %2, %0
  %6 = sub nsw i32 %3, %1
  %7 = mul nsw i32 %6, %5
  ret i32 %7
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr captures(none)) #1

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr captures(none)) #1

; Function Attrs: mustprogress nofree norecurse nosync nounwind willreturn memory(none) uwtable
define dso_local i32 @pick_corner(i32 noundef %0, i32 noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = icmp eq i32 %2, 0
  %5 = select i1 %4, i32 %0, i32 %1
  %6 = select i1 %4, i32 %1, i32 %0
  %7 = mul nsw i32 %6, 10
  %8 = add nsw i32 %7, %5
  ret i32 %8
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind willreturn memory(none) uwtable
define dso_local i32 @walk(i32 noundef %0) local_unnamed_addr #0 {
  %2 = icmp sgt i32 %0, 0
  br i1 %2, label %3, label %21

3:                                                ; preds = %1
  %4 = add nsw i32 %0, -1
  %5 = mul i32 %4, %4
  %6 = add nsw i32 %0, -3
  %7 = zext nneg i32 %4 to i33
  %8 = add nsw i32 %0, -2
  %9 = zext i32 %8 to i33
  %10 = mul i33 %7, %9
  %11 = lshr i33 %10, 1
  %12 = trunc nuw i33 %11 to i32
  %13 = mul i32 %6, %12
  %14 = add i32 %5, %13
  %15 = zext i32 %6 to i33
  %16 = mul i33 %10, %15
  %17 = lshr i33 %16, 1
  %18 = trunc nuw i33 %17 to i32
  %19 = mul i32 %18, -1431655766
  %20 = add i32 %19, %14
  br label %21

21:                                               ; preds = %3, %1
  %22 = phi i32 [ 0, %1 ], [ %20, %3 ]
  ret i32 %22
}

; Function Attrs: nounwind uwtable
define dso_local i32 @through_field(i32 noundef %0, i32 noundef %1) local_unnamed_addr #2 {
  %3 = alloca %struct.corner, align 4
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %3) #4
  store i32 %0, ptr %3, align 4, !tbaa !5
  %4 = getelementptr inbounds nuw i8, ptr %3, i64 4
  store i32 %1, ptr %4, align 4, !tbaa !10
  %5 = call i32 @add_into(ptr noundef nonnull %3, i32 noundef %1) #4
  %6 = load i32, ptr %4, align 4, !tbaa !10
  %7 = add nsw i32 %6, %5
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %3) #4
  ret i32 %7
}

declare i32 @add_into(ptr noundef, i32 noundef) local_unnamed_addr #3

; Function Attrs: mustprogress nofree norecurse nosync nounwind willreturn memory(none) uwtable
define dso_local i64 @make_corner(i32 noundef %0, i32 noundef %1) local_unnamed_addr #0 {
  %3 = zext i32 %1 to i64
  %4 = shl nuw i64 %3, 32
  %5 = zext i32 %0 to i64
  %6 = or disjoint i64 %4, %5
  ret i64 %6
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind willreturn memory(none) uwtable
define dso_local i32 @diagonal(i32 noundef %0, i32 noundef %1) local_unnamed_addr #0 {
  %3 = sub nsw i32 %0, %1
  ret i32 %3
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind willreturn memory(none) uwtable
define dso_local i32 @tag_at(i32 noundef %0, i32 noundef %1) local_unnamed_addr #0 {
  %3 = alloca %struct.label, align 4
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %3) #4
  %4 = getelementptr inbounds nuw i8, ptr %3, i64 4
  store <4 x i8> <i8 111, i8 108, i8 105, i8 0>, ptr %4, align 4, !tbaa !11
  %5 = and i32 %1, 3
  %6 = zext nneg i32 %5 to i64
  %7 = getelementptr inbounds nuw [4 x i8], ptr %4, i64 0, i64 %6
  %8 = load i8, ptr %7, align 1, !tbaa !11
  %9 = sext i8 %8 to i32
  %10 = add nsw i32 %0, %9
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %3) #4
  ret i32 %10
}

attributes #0 = { mustprogress nofree norecurse nosync nounwind willreturn memory(none) uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { nounwind uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #3 = { "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #4 = { nounwind }

!llvm.module.flags = !{!0, !1, !2, !3}
!llvm.ident = !{!4}

!0 = !{i32 1, !"wchar_size", i32 4}
!1 = !{i32 8, !"PIC Level", i32 2}
!2 = !{i32 7, !"PIE Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{!"Ubuntu clang version 21.1.8 (6ubuntu1)"}
!5 = !{!6, !7, i64 0}
!6 = !{!"corner", !7, i64 0, !7, i64 4}
!7 = !{!"int", !8, i64 0}
!8 = !{!"omnipotent char", !9, i64 0}
!9 = !{!"Simple C/C++ TBAA"}
!10 = !{!6, !7, i64 4}
!11 = !{!8, !8, i64 0}

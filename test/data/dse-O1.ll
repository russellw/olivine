; ModuleID = 'test/c/dse.c'
source_filename = "test/c/dse.c"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-linux-gnu"

%struct.triple = type { i32, i32, i32 }

@beacon = dso_local global i32 0, align 4

; Function Attrs: mustprogress nofree norecurse nosync nounwind willreturn memory(argmem: write) uwtable
define dso_local range(i32 -2147483647, -2147483648) i32 @overwritten(ptr noundef writeonly captures(none) initializes((0, 4)) %0, i32 noundef %1) local_unnamed_addr #0 {
  %3 = add nsw i32 %1, 1
  store i32 %3, ptr %0, align 4, !tbaa !5
  ret i32 %3
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind willreturn memory(argmem: readwrite) uwtable
define dso_local i32 @guarded(ptr noundef captures(none) initializes((0, 4)) %0, i32 noundef %1) local_unnamed_addr #1 {
  store i32 %1, ptr %0, align 4, !tbaa !5
  %3 = tail call fastcc i32 @peek(ptr noundef nonnull %0)
  %4 = add nsw i32 %1, 1
  store i32 %4, ptr %0, align 4, !tbaa !5
  ret i32 %3
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr captures(none)) #2

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind willreturn memory(argmem: read) uwtable
define internal fastcc i32 @peek(ptr noundef readonly captures(none) %0) unnamed_addr #3 {
  %2 = load i32, ptr %0, align 4, !tbaa !5
  ret i32 %2
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr captures(none)) #2

; Function Attrs: mustprogress nofree norecurse nosync nounwind willreturn memory(argmem: write) uwtable
define dso_local i32 @one_way(ptr noundef writeonly captures(none) initializes((0, 4)) %0, i32 noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = icmp ne i32 %2, 0
  %5 = zext i1 %4 to i32
  %6 = add nsw i32 %1, %5
  store i32 %6, ptr %0, align 4, !tbaa !5
  ret i32 %6
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind willreturn memory(none) uwtable
define dso_local i32 @filled(i32 noundef %0) local_unnamed_addr #4 {
  %2 = alloca [4 x i32], align 16
  call void @llvm.lifetime.start.p0(i64 16, ptr nonnull %2) #6
  store i32 %0, ptr %2, align 16, !tbaa !5
  %3 = add nsw i32 %0, 1
  %4 = getelementptr inbounds nuw i8, ptr %2, i64 4
  store i32 %3, ptr %4, align 4, !tbaa !5
  %5 = call fastcc i32 @head(ptr noundef %2)
  %6 = getelementptr inbounds nuw i8, ptr %2, i64 8
  store i32 %5, ptr %6, align 8, !tbaa !5
  %7 = add nsw i32 %5, 1
  %8 = getelementptr inbounds nuw i8, ptr %2, i64 12
  store i32 %7, ptr %8, align 4, !tbaa !5
  call void @llvm.lifetime.end.p0(i64 16, ptr nonnull %2) #6
  ret i32 %5
}

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind willreturn memory(argmem: read) uwtable
define internal fastcc i32 @head(ptr noundef nonnull readonly captures(none) %0) unnamed_addr #3 {
  %2 = load i32, ptr %0, align 4, !tbaa !5
  %3 = getelementptr inbounds nuw i8, ptr %0, i64 4
  %4 = load i32, ptr %3, align 4, !tbaa !5
  %5 = add nsw i32 %4, %2
  ret i32 %5
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind willreturn memory(none) uwtable
define dso_local i32 @refilled(i32 noundef %0) local_unnamed_addr #4 {
  %2 = alloca [4 x i32], align 16
  call void @llvm.lifetime.start.p0(i64 16, ptr nonnull %2) #6
  store i32 %0, ptr %2, align 16, !tbaa !5
  %3 = add nsw i32 %0, 1
  %4 = getelementptr inbounds nuw i8, ptr %2, i64 4
  store i32 %3, ptr %4, align 4, !tbaa !5
  %5 = call fastcc i32 @head(ptr noundef %2)
  %6 = getelementptr inbounds nuw i8, ptr %2, i64 8
  store i32 %5, ptr %6, align 8, !tbaa !5
  %7 = add nsw i32 %5, 1
  %8 = getelementptr inbounds nuw i8, ptr %2, i64 12
  store i32 %7, ptr %8, align 4, !tbaa !5
  %9 = call fastcc i32 @peek(ptr noundef nonnull %6)
  %10 = add nsw i32 %9, %5
  %11 = call fastcc i32 @peek(ptr noundef nonnull %8)
  %12 = add nsw i32 %10, %11
  call void @llvm.lifetime.end.p0(i64 16, ptr nonnull %2) #6
  ret i32 %12
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind willreturn memory(none) uwtable
define dso_local i32 @built(i32 noundef %0) local_unnamed_addr #4 {
  %2 = alloca %struct.triple, align 4
  call void @llvm.lifetime.start.p0(i64 12, ptr nonnull %2) #6
  store i32 %0, ptr %2, align 4, !tbaa !9
  %3 = shl nsw i32 %0, 1
  %4 = getelementptr inbounds nuw i8, ptr %2, i64 4
  store i32 %3, ptr %4, align 4, !tbaa !11
  %5 = call fastcc i32 @flatten(ptr noundef %2)
  %6 = getelementptr inbounds nuw i8, ptr %2, i64 8
  store i32 %5, ptr %6, align 4, !tbaa !12
  call void @llvm.lifetime.end.p0(i64 12, ptr nonnull %2) #6
  ret i32 %5
}

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind willreturn memory(argmem: read) uwtable
define internal fastcc i32 @flatten(ptr noundef nonnull readonly captures(none) %0) unnamed_addr #3 {
  %2 = load i32, ptr %0, align 4, !tbaa !9
  %3 = getelementptr inbounds nuw i8, ptr %0, i64 4
  %4 = load i32, ptr %3, align 4, !tbaa !11
  %5 = add nsw i32 %4, %2
  ret i32 %5
}

; Function Attrs: nofree norecurse nounwind memory(readwrite, argmem: none) uwtable
define dso_local void @announce(i32 noundef %0) local_unnamed_addr #5 {
  store volatile i32 %0, ptr @beacon, align 4, !tbaa !5
  %2 = add nsw i32 %0, 1
  store volatile i32 %2, ptr @beacon, align 4, !tbaa !5
  ret void
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind willreturn memory(argmem: write) uwtable
define dso_local void @each_turn(ptr noundef writeonly captures(none) %0, i32 noundef %1) local_unnamed_addr #0 {
  %3 = icmp sgt i32 %1, 0
  br i1 %3, label %4, label %6

4:                                                ; preds = %2
  %5 = add nsw i32 %1, -1
  store i32 %5, ptr %0, align 4, !tbaa !5
  br label %6

6:                                                ; preds = %4, %2
  ret void
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind willreturn memory(none) uwtable
define dso_local i32 @last_seen(i32 noundef %0) local_unnamed_addr #4 {
  %2 = alloca [2 x i32], align 4
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %2) #6
  store i32 0, ptr %2, align 4, !tbaa !5
  %3 = getelementptr inbounds nuw i8, ptr %2, i64 4
  store i32 0, ptr %3, align 4, !tbaa !5
  %4 = icmp sgt i32 %0, 0
  %5 = add nsw i32 %0, -1
  %6 = shl nuw nsw i32 %5, 1
  %7 = select i1 %4, i32 %6, i32 0
  %8 = select i1 %4, i32 %5, i32 0
  store i32 %8, ptr %2, align 4
  store i32 %7, ptr %3, align 4
  %9 = call fastcc i32 @head(ptr noundef %2)
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %2) #6
  ret i32 %9
}

attributes #0 = { mustprogress nofree norecurse nosync nounwind willreturn memory(argmem: write) uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nofree norecurse nosync nounwind willreturn memory(argmem: readwrite) uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #2 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #3 = { mustprogress nofree noinline norecurse nosync nounwind willreturn memory(argmem: read) uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #4 = { mustprogress nofree norecurse nosync nounwind willreturn memory(none) uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #5 = { nofree norecurse nounwind memory(readwrite, argmem: none) uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #6 = { nounwind }

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
!10 = !{!"triple", !6, i64 0, !6, i64 4, !6, i64 8}
!11 = !{!10, !6, i64 4}
!12 = !{!10, !6, i64 8}

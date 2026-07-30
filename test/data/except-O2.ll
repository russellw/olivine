; ModuleID = 'test/c/except.cpp'
source_filename = "test/c/except.cpp"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-linux-gnu"

$__clang_call_terminate = comdat any

@cleanups_run = dso_local local_unnamed_addr global i32 0, align 4
@_ZTIi = external constant ptr

; Function Attrs: mustprogress uwtable
define dso_local range(i32 -2147483648, 2147483647) i32 @caught_value(i32 noundef %0) local_unnamed_addr #0 personality ptr @__gxx_personality_v0 {
  %2 = icmp slt i32 %0, 0
  br i1 %2, label %3, label %6

3:                                                ; preds = %1
  %4 = tail call ptr @__cxa_allocate_exception(i64 4) #5
  store i32 %0, ptr %4, align 16, !tbaa !5
  invoke void @__cxa_throw(ptr nonnull %4, ptr nonnull @_ZTIi, ptr null) #6
          to label %5 unwind label %8

5:                                                ; preds = %3
  unreachable

6:                                                ; preds = %1
  %7 = shl nuw nsw i32 %0, 1
  br label %18

8:                                                ; preds = %3
  %9 = landingpad { ptr, i32 }
          catch ptr @_ZTIi
  %10 = extractvalue { ptr, i32 } %9, 1
  %11 = tail call i32 @llvm.eh.typeid.for.p0(ptr nonnull @_ZTIi) #5
  %12 = icmp eq i32 %10, %11
  br i1 %12, label %13, label %20

13:                                               ; preds = %8
  %14 = extractvalue { ptr, i32 } %9, 0
  %15 = tail call ptr @__cxa_begin_catch(ptr %14) #5
  %16 = load i32, ptr %15, align 4, !tbaa !5
  %17 = add nsw i32 %16, -1
  tail call void @__cxa_end_catch() #5
  br label %18

18:                                               ; preds = %6, %13
  %19 = phi i32 [ %17, %13 ], [ %7, %6 ]
  ret i32 %19

20:                                               ; preds = %8
  resume { ptr, i32 } %9
}

declare i32 @__gxx_personality_v0(...)

; Function Attrs: nofree nosync nounwind memory(none)
declare i32 @llvm.eh.typeid.for.p0(ptr) #1

declare ptr @__cxa_begin_catch(ptr) local_unnamed_addr

declare void @__cxa_end_catch() local_unnamed_addr

; Function Attrs: mustprogress uwtable
define dso_local range(i32 -1, 2147483647) i32 @caught_anything(i32 noundef %0) local_unnamed_addr #0 personality ptr @__gxx_personality_v0 {
  %2 = icmp slt i32 %0, 0
  br i1 %2, label %3, label %6

3:                                                ; preds = %1
  %4 = tail call ptr @__cxa_allocate_exception(i64 4) #5
  store i32 %0, ptr %4, align 16, !tbaa !5
  invoke void @__cxa_throw(ptr nonnull %4, ptr nonnull @_ZTIi, ptr null) #6
          to label %5 unwind label %8

5:                                                ; preds = %3
  unreachable

6:                                                ; preds = %1
  %7 = shl nuw nsw i32 %0, 1
  br label %12

8:                                                ; preds = %3
  %9 = landingpad { ptr, i32 }
          catch ptr null
  %10 = extractvalue { ptr, i32 } %9, 0
  %11 = tail call ptr @__cxa_begin_catch(ptr %10) #5
  tail call void @__cxa_end_catch()
  br label %12

12:                                               ; preds = %6, %8
  %13 = phi i32 [ -1, %8 ], [ %7, %6 ]
  ret i32 %13
}

; Function Attrs: mustprogress uwtable
define dso_local i32 @cleanup_on_both(i32 noundef %0) local_unnamed_addr #0 personality ptr @__gxx_personality_v0 {
  %2 = icmp slt i32 %0, 0
  br i1 %2, label %3, label %6

3:                                                ; preds = %1
  %4 = tail call ptr @__cxa_allocate_exception(i64 4) #5
  store i32 %0, ptr %4, align 16, !tbaa !5
  invoke void @__cxa_throw(ptr nonnull %4, ptr nonnull @_ZTIi, ptr null) #6
          to label %5 unwind label %10

5:                                                ; preds = %3
  unreachable

6:                                                ; preds = %1
  %7 = shl nuw nsw i32 %0, 1
  %8 = load i32, ptr @cleanups_run, align 4, !tbaa !5
  %9 = add nsw i32 %8, 1
  store i32 %9, ptr @cleanups_run, align 4, !tbaa !5
  br label %21

10:                                               ; preds = %3
  %11 = landingpad { ptr, i32 }
          cleanup
          catch ptr @_ZTIi
  %12 = extractvalue { ptr, i32 } %11, 1
  %13 = load i32, ptr @cleanups_run, align 4, !tbaa !5
  %14 = add nsw i32 %13, 1
  store i32 %14, ptr @cleanups_run, align 4, !tbaa !5
  %15 = tail call i32 @llvm.eh.typeid.for.p0(ptr nonnull @_ZTIi) #5
  %16 = icmp eq i32 %12, %15
  br i1 %16, label %17, label %23

17:                                               ; preds = %10
  %18 = extractvalue { ptr, i32 } %11, 0
  %19 = tail call ptr @__cxa_begin_catch(ptr %18) #5
  %20 = load i32, ptr %19, align 4, !tbaa !5
  tail call void @__cxa_end_catch() #5
  br label %21

21:                                               ; preds = %17, %6
  %22 = phi i32 [ %7, %6 ], [ %20, %17 ]
  ret i32 %22

23:                                               ; preds = %10
  resume { ptr, i32 } %11
}

; Function Attrs: mustprogress uwtable
define dso_local i32 @passed_on(i32 noundef %0) local_unnamed_addr #0 personality ptr @__gxx_personality_v0 {
  %2 = icmp slt i32 %0, 0
  br i1 %2, label %3, label %18

3:                                                ; preds = %1
  %4 = tail call ptr @__cxa_allocate_exception(i64 4) #5
  store i32 %0, ptr %4, align 16, !tbaa !5
  invoke void @__cxa_throw(ptr nonnull %4, ptr nonnull @_ZTIi, ptr null) #6
          to label %5 unwind label %6

5:                                                ; preds = %3
  unreachable

6:                                                ; preds = %3
  %7 = landingpad { ptr, i32 }
          catch ptr null
  %8 = extractvalue { ptr, i32 } %7, 0
  %9 = load i32, ptr @cleanups_run, align 4, !tbaa !5
  %10 = add nsw i32 %9, 1
  store i32 %10, ptr @cleanups_run, align 4, !tbaa !5
  %11 = tail call ptr @__cxa_begin_catch(ptr %8) #5
  invoke void @__cxa_rethrow() #6
          to label %17 unwind label %12

12:                                               ; preds = %6
  %13 = landingpad { ptr, i32 }
          cleanup
          catch ptr @_ZTIi
  invoke void @__cxa_end_catch()
          to label %22 unwind label %14

14:                                               ; preds = %12
  %15 = landingpad { ptr, i32 }
          catch ptr null
  %16 = extractvalue { ptr, i32 } %15, 0
  tail call void @__clang_call_terminate(ptr %16) #7
  unreachable

17:                                               ; preds = %6
  unreachable

18:                                               ; preds = %1
  %19 = shl nuw nsw i32 %0, 1
  %20 = load i32, ptr @cleanups_run, align 4, !tbaa !5
  %21 = add nsw i32 %20, 1
  store i32 %21, ptr @cleanups_run, align 4, !tbaa !5
  br label %31

22:                                               ; preds = %12
  %23 = extractvalue { ptr, i32 } %13, 1
  %24 = tail call i32 @llvm.eh.typeid.for.p0(ptr nonnull @_ZTIi) #5
  %25 = icmp eq i32 %23, %24
  br i1 %25, label %26, label %33

26:                                               ; preds = %22
  %27 = extractvalue { ptr, i32 } %13, 0
  %28 = tail call ptr @__cxa_begin_catch(ptr %27) #5
  %29 = load i32, ptr %28, align 4, !tbaa !5
  %30 = mul nsw i32 %29, 3
  tail call void @__cxa_end_catch() #5
  br label %31

31:                                               ; preds = %18, %26
  %32 = phi i32 [ %30, %26 ], [ %19, %18 ]
  ret i32 %32

33:                                               ; preds = %22
  resume { ptr, i32 } %13
}

; Function Attrs: mustprogress uwtable
define dso_local i32 @summed(ptr noundef readonly captures(none) %0, i32 noundef %1) local_unnamed_addr #0 personality ptr @__gxx_personality_v0 {
  %3 = icmp sgt i32 %1, 0
  br i1 %3, label %4, label %6

4:                                                ; preds = %2
  %5 = zext nneg i32 %1 to i64
  br label %8

6:                                                ; preds = %30, %2
  %7 = phi i32 [ 0, %2 ], [ %31, %30 ]
  ret i32 %7

8:                                                ; preds = %4, %30
  %9 = phi i64 [ 0, %4 ], [ %32, %30 ]
  %10 = phi i32 [ 0, %4 ], [ %31, %30 ]
  %11 = getelementptr inbounds nuw i32, ptr %0, i64 %9
  %12 = load i32, ptr %11, align 4, !tbaa !5
  %13 = icmp slt i32 %12, 0
  br i1 %13, label %14, label %17

14:                                               ; preds = %8
  %15 = tail call ptr @__cxa_allocate_exception(i64 4) #5
  store i32 %12, ptr %15, align 16, !tbaa !5
  invoke void @__cxa_throw(ptr nonnull %15, ptr nonnull @_ZTIi, ptr null) #6
          to label %16 unwind label %20

16:                                               ; preds = %14
  unreachable

17:                                               ; preds = %8
  %18 = shl nuw nsw i32 %12, 1
  %19 = add nsw i32 %18, %10
  br label %30

20:                                               ; preds = %14
  %21 = landingpad { ptr, i32 }
          cleanup
          catch ptr @_ZTIi
  %22 = extractvalue { ptr, i32 } %21, 1
  %23 = tail call i32 @llvm.eh.typeid.for.p0(ptr nonnull @_ZTIi) #5
  %24 = icmp eq i32 %22, %23
  br i1 %24, label %25, label %34

25:                                               ; preds = %20
  %26 = extractvalue { ptr, i32 } %21, 0
  %27 = tail call ptr @__cxa_begin_catch(ptr %26) #5
  %28 = load i32, ptr %27, align 4, !tbaa !5
  %29 = sub nsw i32 %10, %28
  tail call void @__cxa_end_catch() #5
  br label %30

30:                                               ; preds = %17, %25
  %31 = phi i32 [ %19, %17 ], [ %29, %25 ]
  %32 = add nuw nsw i64 %9, 1
  %33 = icmp eq i64 %32, %5
  br i1 %33, label %6, label %8, !llvm.loop !9

34:                                               ; preds = %20
  resume { ptr, i32 } %21
}

declare ptr @__cxa_allocate_exception(i64) local_unnamed_addr

; Function Attrs: cold noreturn
declare void @__cxa_throw(ptr, ptr, ptr) local_unnamed_addr #2

declare void @__cxa_rethrow() local_unnamed_addr

; Function Attrs: noinline noreturn nounwind uwtable
define linkonce_odr hidden void @__clang_call_terminate(ptr noundef %0) local_unnamed_addr #3 comdat {
  %2 = tail call ptr @__cxa_begin_catch(ptr %0) #5
  tail call void @_ZSt9terminatev() #7
  unreachable
}

; Function Attrs: cold nofree noreturn
declare void @_ZSt9terminatev() local_unnamed_addr #4

attributes #0 = { mustprogress uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #1 = { nofree nosync nounwind memory(none) }
attributes #2 = { cold noreturn }
attributes #3 = { noinline noreturn nounwind uwtable "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #4 = { cold nofree noreturn }
attributes #5 = { nounwind }
attributes #6 = { noreturn }
attributes #7 = { noreturn nounwind }

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
!8 = !{!"Simple C++ TBAA"}
!9 = distinct !{!9, !10}
!10 = !{!"llvm.loop.mustprogress"}

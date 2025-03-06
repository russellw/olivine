10 REM Simple BASIC test program
20 PRINT "Welcome to BASIC Interpreter Test"
30 PRINT "This program counts from 1 to a number you choose"
40 PRINT
50 INPUT "Enter a number: "; N
60 PRINT "Counting from 1 to "; N
70 FOR I = 1 TO N
80   PRINT I;
90   IF I < N THEN PRINT ", ";
100 NEXT I
110 PRINT
120 PRINT "All done!"
130 END

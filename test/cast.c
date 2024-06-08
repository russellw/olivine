// argv: $f
#include <inttypes.h>
#include <stdio.h>
#include <stdlib.h>

uint8_t u8;
uint16_t u16;
uint32_t u32;
uint64_t u64;
// i128 is not really supported on Windows x64

int8_t s8;
int16_t s16;
int32_t s32;
int64_t s64;

float f32;
double f64;
// the other floating-point types are not really supported on Windows x64

float F32(float x) {
	return x;
}

double F64(double x) {
	return x;
}

int main(int argc, char** argv) {
	if (argc != 2) {
		fprintf(stderr, "Usage: sqrt x\n");
		return 1;
	}
	errno = 0;
	double x = strtod(argv[1], 0);
	if (errno) {
		perror(argv[1]);
		return 1;
	}
	x *= 100;

	u8 = x;
	u16 = x;
	u32 = x;
	u64 = x;

	s8 = x;
	s16 = x;
	s32 = x;
	s64 = x;

	f32 = x;
	f64 = x;

	printf("%f\n", (double)u8);
	printf("%f\n", (double)u16);
	printf("%f\n", (double)u32);
	printf("%f\n", (double)u64);

	printf("%f\n", (double)s8);
	printf("%f\n", (double)s16);
	printf("%f\n", (double)s32);
	printf("%f\n", (double)s64);

	printf("%f\n", (double)f32);
	printf("%f\n", (double)f64);

	u8 = 100.0;
	u16 = 100.0;
	u32 = 100.0;
	u64 = 100.0;

	s8 = 100.0;
	s16 = 100.0;
	s32 = 100.0;
	s64 = 100.0;

	f32 = 100.0;
	f64 = 100.0;

	printf("%f\n", (double)u8);
	printf("%f\n", (double)u16);
	printf("%f\n", (double)u32);
	printf("%f\n", (double)u64);

	printf("%f\n", (double)s8);
	printf("%f\n", (double)s16);
	printf("%f\n", (double)s32);
	printf("%f\n", (double)s64);

	printf("%f\n", (double)f32);
	printf("%f\n", (double)f64);

	f32 = F32(100.0f);
	f64 = F64(100.0f);

	f32 = F32(100.0);
	f64 = F64(100.0);

	return 0;
}

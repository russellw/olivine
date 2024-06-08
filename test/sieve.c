#include <stdio.h>
#include <string.h>

#define N 1000
char a[N];

int main() {
	memset(a + 2, 1, N - 2);
	for (int i = 2; i * i < N; i++)
		if (a[i])
			for (int j = i * i; j < N; j += i) a[j] = 0;
	int n = 0;
	for (int i = 2; i < N; i++) n += a[i];
	printf("%d\n", n);
	return 0;
}

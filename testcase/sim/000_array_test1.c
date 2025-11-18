// #include "io.h"
// //input: 1 2 3 4

// int a[4];
// int main()
// {
//     int b[4];
// 	int i;
//     for (i = 0; i < 4; i++)
// 	{
// 		a[i] = 0;
// 		b[i] = i + 1;
// 	}
// 	for (i = 0; i < 4; i++)
// 	{
// 		outl(a[i]);
// 	}
// 	println("");
// 	int *p;
// 	p=b;
// 	for (i = 0; i < 4; i++)
// 	{
// 		outl(p[i]);
// 	}
// }
#include "io.h"
int a[100] = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10};
int b[100] = {10, 9, 8, 7, 6, 5, 4, 3, 2, 1};
int main() {
  int e = 5;
  int c = 9;
  int d = 1;
  for (int i = 0; i < 100; ++i) {
    a[i] = i;
    b[i] = i;
  }
  for (int i = 0; i < 100; ++i) {
    c += a[i] + b[i];
    e = d + e;
  }
  outl(c);
  outl(e);
}
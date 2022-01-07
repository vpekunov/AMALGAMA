#include <stdio.h>
#include <stdlib.h>
int main() {
  double V[10];
  double max;
  double min;
  int i;
  for (i = 0; i < 10; i++) {
    printf("V[%i] = ", i);
    scanf("%lf", &V[i]);
  }
  min = 1E300;
  for (i = 0; i < 10; i++)
    if (V[i] < min)
       min = V[i];
  max = -1E300;
  for (i = 0; i < 10; i++)
    if (V[i] > max)
       max = V[i];
  printf("V = [");
  for (i = 0; i < 10; i++)
    printf("%lf ", V[i]);
  printf("]\n");
  printf("min = %lf\n", min);
  printf("max = %lf\n", max);
  return 0;
}

/*
 *  Please write your name and net ID below
 *
 *  Last name: Bora
 *  First name: Anuj
 *  Net ID: aab688
 *
 */


/*
 * This file contains the code for finding prime numbers till N using CPU
 *
 *  You compile with:
 * 		gcc -o seqgenprimes seqgenprimes.c -lm
 *
 *  And run as :
 *    ./seqgenprimes 100
 */

#include <stdlib.h>
#include <stdio.h>
#include <time.h>
#include <string.h>
#include <math.h>

/*****************************************************************/

// Function declarations: 
void  cpu_genprimes(unsigned int, int *);
/*****************************************************************/

int main(int argc, char * argv[])
{
  unsigned int N; /* Dimention of NxN matrix */

  int* numbers;

  if(argc != 2)
  {
    fprintf(stderr, "N: number till which the primes should be generated\n");
    exit(1);
  }

  char* filename = argv[1];
  N = (unsigned int) atoi(argv[1]);

  numbers = (int *)malloc((N + 1) * sizeof(int));

  if( !numbers )
  {
   fprintf(stderr, " Cannot allocate the %u array\n", N);
   exit(1);
  }

  int i = 0;
  for (i = 0; i <= N; i++)
  {
    numbers[i] = 1;
  }

  printf("Generating Prime Numbers ...\n");
  cpu_genprimes(N, numbers);

  FILE *fp;
  const char* extension = ".txt";
  char* file = (char *) malloc(1 + strlen(filename)+ strlen(extension) );
  strcpy(file, filename);
  strcat(file, extension);
  fp = fopen(file, "w+");

  int count = 0;
  for (i = 2; i <= N; i++)
  {
    if (numbers[i] == 1)
    {
      fprintf(fp, "%d ", i);
      count++;
    }
  }
  fclose(fp);
  printf("Number of Prime Numbers = %d \n", count);
  free(numbers);

  return 0;

}

/*****************  The CPU sequential version  **************/
void cpu_genprimes(unsigned int N, int* numbers)
{
  int i = 0;
  int j = 0;

  for (i = 2; i <= floor((N + 1) / 2); i++)
  {
    if (numbers[i] != 0)
    {
      for (j = (i + i); j <= N; j = j + i)
      {
          numbers[j] = 0;
      }
    }
  }
}

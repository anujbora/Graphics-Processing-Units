/*
 *
 *  Last name: Bora
 *  First name: Anuj
 *  Net ID: aab688
 *
 */


/*
 * This file contains the code for finding prime numbers till N using GPU
 * It uses device 1 in the cluster
 * You compile with:
 * 	  nvcc -o genprimes genprimes.cu --generate-code arch=compute_30,code=sm_30
 *
 * And run as :
 *    time ./genprimes 100
 */

#include <cuda.h>
#include <stdlib.h>
#include <stdio.h>
#include <time.h>
#include <cuda_profiler_api.h>

#define TILE 64

/*****************************************************************/

// Function declarations:
void  gpu_genprimes(char*, unsigned int);

/*****************************************************************/

/*********************  Kernel  *********************************/

__global__
void warmUpGPU()
{
  // do nothing
}

__global__
void checkEven(char* primes, unsigned int N)
{
   int index = blockIdx.x * blockDim.x + threadIdx.x;
   if (index > 2 && index <= N && (index % 2 == 0))
   {
     primes[index] = '0';
   }
}

__global__
void checkOdd(char* primes, unsigned int N, unsigned int ceiling)
{
  int index = blockIdx.x * blockDim.x + threadIdx.x;

  if ((index <= ceiling) && (primes[index] == '1'))
  {
    for (int i = index * 2; i <= N; i = i + index)
    {
       primes[i] = '0';
    }
  }

}

/*****************************************************************/

int main(int argc, char * argv[])
{
  //cudaProfilerStart();
  unsigned int N;

  /* The 1D array of chars will be treated as 1D array of N elements */
  char* numbers;

  if(argc != 2)
  {
    fprintf(stderr, "N: number till which the primes should be generated\n");
    exit(1);
  }
  char* filename = argv[1];
  N = (unsigned int) atoi(argv[1]);

  if (N < 2)
  {
    printf("Zero prime numbers till %d", N);
    printf("\nNo file created");
    return 0;
  }

  numbers = (char*)malloc((N + 1) * sizeof(char));

  if( !numbers )
  {
   fprintf(stderr, " Cannot allocate the %u array\n", N);
   exit(1);
  }

  for (int i = 0; i <= N; i++)
  {
    numbers[i] = '1';
  }

  /**
   *  Initialize 0 and 1 as non-prime numbers
   */
  numbers[0] = '0';
  numbers[1] = '0';

  printf("Generating Prime Numbers ...\n");
  gpu_genprimes(numbers, N);

  FILE *fp;
  const char* extension = ".txt";
  char* file = (char *) malloc(1 + strlen(filename)+ strlen(extension) );
  strcpy(file, filename);
  strcat(file, extension);
  fp = fopen(file, "w+");

  int count = 0;
  for (int i = 2; i <= N; i++)
  {
    if (numbers[i] == '1')
    {
      //fprintf(fp, "%d ", i);
      //printf("%d", i);
      count++;
    }
  }
  fclose(fp);
  printf("Number of Prime Numbers = %d \n", count);
  free(numbers);
  //cudaProfilerStop();
  return 0;
}

/***************** The GPU version  *********************/
void  gpu_genprimes(char* numbers, unsigned int N)
{
  cudaSetDevice(1);
  /**
   *  First kernel takes more time to initialize.
   *  Send a kernel which does nothing which will warm up
   *  the GPU and in that time do other work on CPU.
   */
  warmUpGPU<<<1, 1>>>();


  int size = (N + 1) * sizeof(char);
  char* d_numbers;
  unsigned int ceiling = ceil((N + 1) / 2);

  // Made use of 1d blocks and threads as it will make it easier to work on data
  // represented as 1d
  dim3 numBlocks(ceil(1.0*(N + 1)/TILE), 1, 1);
  dim3 threadsPerBlock(TILE, 1, 1);


  // Step 1 : Allocate Memory on Device and copy values to device
  cudaMalloc((void **) &d_numbers, size);

  cudaMemcpy(d_numbers, numbers, size, cudaMemcpyHostToDevice);

  // Step 2 : Launch Kernels
  checkEven<<<numBlocks, threadsPerBlock>>>(d_numbers, N);
  checkOdd<<<numBlocks, threadsPerBlock>>>(d_numbers, N, ceiling);

  // Step 3 : Bring result back to host
  cudaMemcpy(numbers, d_numbers, size, cudaMemcpyDeviceToHost);

  // Step 4 : Free device memory
  cudaFree(d_numbers);

}

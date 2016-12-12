/*
 *  Please write your name and net ID below
 *
 *  Last name: Bora
 *  First name: Anuj
 *  Net ID: aab688
 *
 */


/*
 * This file contains the code for doing the heat distribution problem.
 * You do not need to modify anything except starting  gpu_heat_dist() at the bottom
 * of this file.
 * In gpu_heat_dist() you can organize your data structure and the call to your
 * kernel(s) that you need to write too.
 *
 * You compile with:
 * 		nvcc -o heatdist heatdist.cu
 */

#include <cuda.h>
#include <stdlib.h>
#include <stdio.h>
#include <time.h>

/* To index element (i,j) of a 2D array stored as 1D */
#define index(i, j, N)  ((i)*(N)) + (j)
#define BLOCKSIZE 256


/*****************************************************************/

// Function declarations: Feel free to add any functions you want.
int  gpu_levenshtein( char * ,
                       char * ,
                     int , int );
void printMatrix(int*, unsigned int);
int getBlocks(int , int );

/*****************************************************************/

/*****************************************************************/
__global__ void warmUpGPU()
{
  // do nothing
}

__global__ void antiparallelUT(unsigned short* d_A, int step, int len1, int len2,
  const char* d_word1, const char* d_word2, int* d_result)
{

	int i = threadIdx.x + blockIdx.x * blockDim.x;
	int j = step-i;

  if (i == 0 && j <= len2) {
    d_A[index(i + j, j, len2 + 1)] = j;
  }

  if (j == 0 && i <= len2) {
    d_A[index(i + j, j, len2 + 1)] = i;
  }

  if (i <= len1 && j <= len2 && i>=1 && j>=1) {
      //printf("[%d][%d]\n", i, j);
      //d_A[i*N+j] = 1;

      int delete_count;
      int insert;
      int substitute;

      char c2;
      char c1;

      c1 = d_word1[i-1];
      c2 = d_word2[j-1];

      int score = 1;


      if (c1 == c2) {
          score = 0;
      }
      /*
      delete_count = d_A[index(i - 1, j, len2 + 1)] + 1;
      insert = d_A[index(i, j - 1, len2 + 1)] + 1;
      substitute = d_A[index(i - 1, j - 1, len2 + 1)] + score;
      */

      int old_x = i - 1;
      int y = j;
      int x = old_x + y;
      if (x > len1 ) {
        x = x - len1 - 1;
      }
      delete_count = d_A[index(x, y, len2 + 1)] + 1;

      old_x = i - 1;
      y = j - 1;
      x = old_x + y;
      if (x > len1 ) {
        x = x - len1 - 1;
      }
      insert = d_A[index(x, y, len2 + 1)] + score;

      old_x = i;
      y = j - 1;
      x = old_x + y;
      if (x > len1 ) {
        x = x - len1 - 1;
      }
      substitute = d_A[index(x, y, len2 + 1)] + 1;


      int min;

      if (delete_count < insert) {
        min = delete_count;
      } else {
         min = insert;
      }

      if (substitute < min) {
        min = substitute;
      }
      x = i + j;
      y = j;
      if (x > len1 ) {
        x = x - len1 - 1;
      }
      d_A[index(x, y, len2 + 1)] = min;

      if (i == len1 && j == len2) {
        //printf("updating result...");
        //printf("\nmin = %d\n", min);
         d_result[0] = min;
      }

  }

  //__syncthreads();
}


// Print
void printMatrix(int* playground, int len1, int len2)
{

  for (int i = 0; i < len1; i++)
  {
    for (int j = 0; j < len2; j++)
    {
      printf("%d ", playground[index(i,j,len2)]);
    }
    printf("\n ");
  }

}

int getBlocks(int a, int b) {
  return (a % b != 0) ? (a / b + 1) : (a / b);
}

/*****************************************************************/

int main(int argc, char * argv[])
{
  //char string1[4] = {'a', 'n', 'u', 'j'};
  //char string2[5] = {'a', 'n', 't', 'j', 'b'};

  int size =32000;
  char string1[size];
  char string2[size];
  for (int i = 0; i < size; i++) {
    string1[i] = 'a';
    string2[i] = 'b';
  }

  //string1[0] = 'b';

  int dis = gpu_levenshtein(string1, string2, size, size);

  printf("Result = %d", dis);

  return 0;

}

/***************** The GPU version: Write your code here *********************/
int  gpu_levenshtein( char * word1,
                     char * word2,
                     int len1, int len2)
{
  warmUpGPU<<<1, 1>>>();

  int N = len1 + 1;
  int size = (N) * (N) * sizeof(unsigned short);
  int word1_size = len1 * sizeof(char);
  int word2_size = len2 * sizeof(char);
  int* result_host = (int*)malloc(sizeof(int));
  result_host[0] = 0;

  unsigned short *zero_matrix;
  unsigned short *d_A;
  int *d_result;
  char *d_word1, *d_word2;

  zero_matrix = (unsigned short *)calloc((N) * (N), sizeof(unsigned short));

  if(zero_matrix == NULL)
  {
    printf("Memory allocation failed on CPU");
  }
//  int i, j;
  /*
  for(i = 0; i <= len1; i++) {
    for (j = 0; j <= len2; j++) {
      zero_matrix[index(i, j, (len2 + 1))] = 0;
    }
  } */
  /*
  for (i = 0; i < (2 * N)-1; i++) {
    for (j = 0; j < N; j++) {
      zero_matrix[index(i, 0, (len2 + 1))] = 0;

      if (i == 0) {
        zero_matrix[index(0, j, (len2 + 1))] = j;
      }

      if (j == 0) {
        zero_matrix[index(i, 0, (len2 + 1))] = i;
      }
    }

  }*/

  //printMatrix(zero_matrix, ((2 * N)-1), N);
  /*
  for (i = 0; i <= len1; i++) {
      zero_matrix[index(i, 0, (len2 + 1))] = i;
  }

  for (i = 0; i <= len2; i++) {
      zero_matrix[index(0, i, (len2 + 1))] = i;
  }
  */

  if ( cudaSuccess != cudaMalloc((void **) &d_A, size) )
  {
      printf( "Error in allocating memory on GPU!!\n" );
  }

  cudaMalloc((void **) &d_result, sizeof(int));
  cudaMalloc((void **) &d_word1, word1_size);
  cudaMalloc((void **) &d_word2, word2_size);

  cudaMemcpy(d_A, zero_matrix, size, cudaMemcpyHostToDevice);
  cudaMemcpy(d_result, result_host, sizeof(int), cudaMemcpyHostToDevice);
  cudaMemcpy(d_word1, word1, word1_size, cudaMemcpyHostToDevice);
  cudaMemcpy(d_word2, word2, word2_size, cudaMemcpyHostToDevice);
  int step = 0;

  for ( step = 0; step < (2 * N) - 1; step++) {

    dim3 dimBlock(BLOCKSIZE);
    dim3 dimGrid(getBlocks(step, BLOCKSIZE));

    if (step == 0) {
      antiparallelUT<<<1,dimBlock.x>>>(d_A,step,len1, len2, d_word1, d_word2, d_result);
    } else {
      antiparallelUT<<<dimGrid.x,dimBlock.x>>>(d_A,step,len1, len2, d_word1, d_word2, d_result);
    }
  }


  // Step 3 : Bring result back to host
  //cudaMemcpy(zero_matrix, d_A, size, cudaMemcpyDeviceToHost);
  //int *result_host = 0;
  cudaMemcpy(result_host, d_result, sizeof(int), cudaMemcpyDeviceToHost);

  // Step 4 : Free device memory
  cudaFree(d_A);
  cudaFree(d_word1);
  cudaFree(d_word2);
  //printf("\n\n\n");
  //printMatrix(zero_matrix, N, N);
  //printMatrix(flags, len1, len2);
  //printf("%d \n", index(len1, len2, len2 + 1));
  //int result = zero_matrix[index(len1, len2, (len2 + 1))];
  free(zero_matrix);
  return result_host[0];
}

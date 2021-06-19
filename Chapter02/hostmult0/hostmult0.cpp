﻿// example 2.11 hostmult0 simple matrix multiply
#include "thrust/host_vector.h"
#include "cxtimers.h"
#include <random>
int hostmult0(float * C, float * A, float * B, int Ay, int Ax, int Bx)
{
	// compute C = A * B for matrices (assume Ax = By and C  is Ay x Bx)
	for(int i=0;i<Ay;i++) for(int j=0;j<Bx;j++){
		C[i*Bx+j] = 0.0;      // Cij   = ∑k      Aik  *   Bkj
		for(int k=0;k<Ax;k++) C[i*Bx+j] += A[i*Ax+k]*B[k*Bx+j];
	}
	return 0;
}
int main(int argc,char *argv[])
{
	int Arow = (argc > 1) ? atoi(argv[1]) : 1024; // default 2^10
	int Acol = (argc > 2) ? atoi(argv[2]) : Arow;
	int Brow = Acol;
	int Bcol = (argc > 3) ? atoi(argv[3]) : Brow;
	int Crow = Arow;
	int Ccol = Bcol;
	thrust::host_vector<float> A(Arow*Acol);
	thrust::host_vector<float> B(Brow*Bcol);
	thrust::host_vector<float> C(Crow*Ccol);
	// initialise A and B with random numbers
	std::default_random_engine gen(12345678);
	std::uniform_real_distribution<float> fran(0.0,1.0);
	for(int k = 0; k<Arow*Acol; k++) A[k] = fran(gen);
	for(int k = 0; k<Brow*Bcol; k++) B[k] = fran(gen);
	cx::timer tim;
	hostmult0(C.data(),A.data(),B.data(),Arow,Acol,Bcol);
	double t1 = tim.lap_ms();
	double flops = 2.0*(double)Arow*(double)Acol*(double)Bcol;
	double gflops= flops/(t1*1000000.0);
	double gbytes = gflops*6.0; // i.e. 12 bytes per term
	printf("A %d x %d B %d x %d host time %.3f ms Gflops/sec %.3f\n",
		Arow,Acol,Brow,Bcol,t1,gflops);
	return 0;
}

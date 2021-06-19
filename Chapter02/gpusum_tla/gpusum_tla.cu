// program gpusum_tla includes:
// example 2.1 tls using while loop
// example 2.2 tla using for   loop

#include "cx.h"
#include "cxtimers.h"                    // timers

__host__ __device__ inline float sinsum(float x,int terms)
{
	float x2 = x*x;
	float term = x;   // first term of series
	float sum = term; // sum of terms so far
	for(int n = 1; n < terms; n++){
		term *= -x2 / (2*n*(2*n+1));
		sum += term;
	}
	return sum;
}

// kernel uses many parallel threads for sinsum calls
__global__ void gpu_sin_tla_whileloop(float *sums,int steps,int terms,float step_size)
{
	int step = blockIdx.x*blockDim.x+threadIdx.x; // start with unique thread ID
	while(step<steps){
		float x = step_size*step;
		sums[step] = sinsum(x,terms);  // save sum
		step += blockDim.x*gridDim.x; //  large stride to next step.
	}
}

__global__ void gpu_sin_tla_forloop(float *sums,int steps,int terms,float step_size)
{
	for(int step = blockIdx.x*blockDim.x+threadIdx.x; step<steps; step += gridDim.x*blockDim.x){
		float x = step_size*step;
		sums[step] = sinsum(x,terms);  // save sum
	}
}

int main(int argc,char *argv[])
{
	int steps   = (argc > 1) ? atoi(argv[1]) : 1000000;
	int terms   = (argc > 2) ? atoi(argv[2]) : 1000;
	int threads = (argc > 3) ? atoi(argv[3]) : 256;
	int blocks  = (argc > 4) ? atoi(argv[4]) : (steps+threads-1)/threads;  // ensure threads*blocks >= steps

	double pi = 3.14159265358979323;
	double step_size = pi / (steps-1); // NB n-1 steps between n points

	thrust::device_vector<float> dsums(steps);         // GPU buffer    
	float *dptr = thrust::raw_pointer_cast(&dsums[0]); // get pointer    

	cx::timer tim;                  // declare and start timer
	gpu_sin_tla_whileloop<<<blocks,threads>>>(dptr,steps,terms,(float)step_size);  // tla using while loop
	//gpu_sin_tla_forloop<<<blocks,threads>>>(dptr,steps,terms,(float)step_size);  // tla using for loop
	double gpu_sum = thrust::reduce(dsums.begin(),dsums.end());
	double gpu_time = tim.lap_ms(); // get elapsed time

	double rate = (double)steps*(double)terms/(gpu_time*1000000.0);
	gpu_sum -= 0.5*(sinsum(0.0f,terms)+sinsum(pi,terms));
	gpu_sum *= step_size;
	printf("gpu sum = %.10f, steps %d terms %d time %.3f ms config %7d %4d rate %f \n",gpu_sum,steps,terms,gpu_time,blocks,threads,rate);

	return 0;
}

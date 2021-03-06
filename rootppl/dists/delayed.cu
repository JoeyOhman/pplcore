#include <random>
#include <time.h>
#include <cassert>

#ifdef _OPENMP
#include <omp.h>
#endif

#ifdef __NVCC__
#include <curand_kernel.h>
#endif

#include "inference/smc/smc.cuh"
#include "utils/misc.cuh"
#include "utils/math.cuh"
#include "scores.cuh"
#include "macros/macros.cuh"

#include "delayed.cuh"

DEV floating_t sample_GammaExponential(RAND_STATE_DECLARE gamma_t& rate, floating_t f) {
  floating_t t = SAMPLE(lomax, 1/(f*rate.theta), rate.k);

  assert(0.0 < rate.theta/(1 + t*f*rate.theta));					  
  rate.k = rate.k + 1;
  rate.theta = rate.theta/(1 + t*f*rate.theta);
  return t;
}


DEV floating_t score_GammaExponential( floating_t x, gamma_t& rate,  floating_t f) {
  
  floating_t score = lomaxScore(x, 1/(f*rate.theta), rate.k);

  assert(0.0 < rate.theta/(1 + x*f*rate.theta));
  
  rate.k = rate.k + 1;
  rate.theta =  rate.theta/(1 + x*f*rate.theta);
  return score;
}


DEV floating_t score_GammaPoisson(floating_t x, floating_t t, gamma_t& rate, floating_t f)
{
  assert(0.0 <= f);
  assert(0.0 <= t);
  assert(0.0 <= rate.theta);
 
  floating_t score = negativeBinomialScore(x, rate.k, 1/(1 + t*f*rate.theta));

  assert(0.0 < rate.theta/(1 + t*f*rate.theta));
  rate.theta = rate.theta / (1 + t*f*rate.theta);
  return score;
}



DEV floating_t sample_NormalInverseGammaNormal(RAND_STATE_DECLARE normalInverseGamma_t& prior) {
  floating_t m0 = prior.m0;
  floating_t v = prior.v;
  floating_t a = prior.a;
  floating_t b = prior.b;
  floating_t f = SAMPLE(student_t, 2.0*a, m0, (1.0 + 1.0/v)*2.0*b);
  prior.m0 = (v*m0 + f)/(v + 1);
  prior.v  = v + 1;
  prior.a  = a + 0.5;
  prior.b  = b + 0.5*(v/(v + 1)*(f - m0)*(f - m0));
  return f;
}

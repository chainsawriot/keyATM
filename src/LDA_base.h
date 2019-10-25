#ifndef __LDAbase__INCLUDED__
#define __LDAbase__INCLUDED__

#include <Rcpp.h>
#include <RcppEigen.h>
#include <unordered_set>
#include "sampler.h"
#include "keyATM.h"

using namespace Eigen;
using namespace Rcpp;
using namespace std;

class LDAbase : virtual public keyATMbase
{
  public:

    // Constructor
    LDAbase(List model_, const int iter_, const int output_per_) :
      keyATMbase(model_, iter_, output_per_) {};
  
    // Variables
    MatrixXd n_kv;
    VectorXd n_k;
    VectorXd n_k_noWeight;

    // Functions
    // In LDA, we do not need to read and initialize X
    virtual void read_data_common() final;
    virtual void initialize_common() final;
    virtual void iteration_single(int &it) = 0;
    virtual int sample_z(VectorXd &alpha, int &z, int &x,
                         int &w, int &doc_id) final;
    virtual double loglik_total() = 0;
};

#endif


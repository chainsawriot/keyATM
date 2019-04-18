#ifndef __keyATM_HMM__INCLUDED__
#define __keyATM_HMM__INCLUDED__

#include <Rcpp.h>
#include <RcppEigen.h>
#include <unordered_set>
#include "sampler.h"
#include "keyATM.h"

using namespace Eigen;
using namespace Rcpp;
using namespace std;

class keyATMhmm : public keyATMbase
{
	public:
		// Parameters
		int num_states;
		int index_states;  // num_states - 1
		MatrixXd Psk;    // (num_doc, num_states)
		VectorXi S_est;  // stores state index, (num_doc)
		MatrixXd P_est;  // (num_states, num_states)
		MatrixXd alphas;  // (num_states, num_topics)
		double loglik;
	
		// Constructor
		keyATMhmm(List model_, const int iter_, const int output_per_);

		// During sampling
			// sample_forward()
			VectorXd logfy;  // (num_states)
			VectorXd st_1l;
			VectorXd st_k;
			VectorXd logst_k;
			double logsum;
	
		// 
		// Functions
		//
	
		// Read data and Initialize
		void read_data_specific();
		void initialize_specific();
	
		// Iteration
		void iteration_single();
		void sample_parameters();
		void sample_forward();  // calculate Psk
		void sample_backward();  // sample S_est
		void sample_P();  // sample P_est
		void store_S_est();

		double polyapdfln(int &doc_id, VectorXd &alpha);
		double loglik_total();
};

#endif


#ifndef __ANALYZE_NNET_H__
#define __ANALYZE_NNET_H__

// #define _CRT_SECURE_NO_WARNINGS

#include "nnets.h"
#include "symbolic.h"

#include <stdio.h>
#include <stdlib.h>
#include <memory.h>
#include <math.h>
#include <time.h>
#include <float.h>

#include <omp.h>

#include <vector>
#include <map>
#include <string>

using namespace std;

#ifndef max
#define max(a,b) ((a)>(b) ? (a) : (b))
#endif

#define VARIANTS_FILE "variants.txt"

typedef struct {
	int kind;
	int N;
	long double * KF;
} VARIANT;

static int NVARIANTS = 1;

const int n_kinds = 5;

typedef enum { vkPoly = 0, vkPolySqr = 1, vkPolyRev = 2, vkPolySqrRev = 3, vkLinear = 4 } variant_kinds;

char * kinds[n_kinds] = {"POLY", "POLYSQR", "POLYREV", "POLYSQRREV", "LIN"};

typedef map<string, ITEM *> zVars;

void * 	BUILD_FUNC(FILE * VARIANTS,
				   vector<string> & BEST,
				   int nInputs, char ** Vars, long double * W, long double * B,
				   vector<vector<VARIANT> *>_VARS,
				   int layer, zVars &zvars, char * Scheme = NULL, SUM ** Inputs = NULL) {
	int NPP = NPROCS;

	int n_input[3] = {nInputs, NEURO1, NEURO2};
	int n_output[3] = {NEURO1, NEURO2, 1};
	int w_base[3] = {0, nInputs*NEURO1, nInputs*NEURO1 + NEURO1*NEURO2};
	int b_base[3] = {0, NEURO1, NEURO1 + NEURO2};

	SUM * INPUTS[256];
	SUM * OUTPUTS[256];

	if (!Scheme) {
		Scheme = new char[65536*4];
		Scheme[0] = 0x0;
	}

	char * _Scheme = new char[65536*4];
	_strcpy(_Scheme, 65536*4, Scheme);

	for (int i = 0; i < n_input[layer-1]; i++)
		if (layer == 1) {
			MUL * INP = new MUL(1.0);
			INP->Mul(i, 1.0);
			INPUTS[i] = new SUM(INP);
		} else
			INPUTS[i] = dynamic_cast<SUM *>(Inputs[i]->clone());

	for (int i = 0; i < n_output[layer-1]; i++) {
		OUTPUTS[i] = new SUM(B[b_base[layer-1] + i]);
		for (int j = 0; j < n_input[layer-1]; j++) {
			SUM * KFI = new SUM(W[w_base[layer-1] + j*n_output[layer-1] + i]);
			SUM * I = dynamic_cast<SUM *>(INPUTS[j]->clone());
			KFI->Mul(I);
			OUTPUTS[i]->Add(KFI);
		}
		OUTPUTS[i]->AccountSimilars();
	}

	int N = 1;
	unsigned int variant[256] = {0};
	for (int i = 0; i < n_output[layer - 1]; i++)
		N *= _VARS[b_base[layer-1]+i]->size();
	for (int i = 0; i < N; i++) {
		int P = n_output[layer-1];

		if (layer == 1) {
			_strcpy(_Scheme, 65536*4, "|");
			zVars::iterator it;
			for (it = zvars.begin(); it != zvars.end(); it++)
				delete it->second;
			zvars.clear();
		} else
			_strcpy(_Scheme, 65536*4, Scheme);

		SUM * _OUTPUTS[256];
		for (int j = 0; j < P; j++) {
			int neuro_num = b_base[layer-1] + j;
			int sqrt_var = nInputs + neuro_num;
			VARIANT & VAR = (*_VARS[b_base[layer-1]+j])[variant[j]];
			SUM * ARG = dynamic_cast<SUM *>(OUTPUTS[j]->clone());
			char sqrt_name[4] = "z00";
			sqrt_name[1] = neuro_num >= 10 ? '0' + neuro_num/10 : '0';
			sqrt_name[2] = '0' + neuro_num%10;
			string zvar(sqrt_name);
			zvars[zvar] = ARG->clone();
			_OUTPUTS[j] = new SUM(0.0);
			_strcat(_Scheme, 65536*4, kinds[VAR.kind]);
			_strcat(_Scheme, 65536*4, "|");
			switch (VAR.kind) {
				case vkPoly:
				case vkPolyRev:
					_OUTPUTS[j]->SETPOLY(ARG, VAR.N, VAR.KF, VAR.kind == vkPolyRev);
					break;
				case vkPolySqr:
				case vkPolySqrRev:
					_OUTPUTS[j]->SETPOLYSQR(ARG, sqrt_var, VAR.N, VAR.KF, VAR.kind == vkPolySqrRev);
					break;
				case vkLinear:
					delete _OUTPUTS[j];
					_OUTPUTS[j] = ARG;
					_OUTPUTS[j]->AccountSimilars();
			}
		}
		if (layer < 3) {
			BUILD_FUNC(VARIANTS, BEST, nInputs, Vars, W, B, _VARS, layer+1, zvars, _Scheme, _OUTPUTS);
		} else {
		  if (NVARIANTS > 0) {
			NVARIANTS--;
			ITEM * OUT = dynamic_cast<ITEM *>(_OUTPUTS[0]->clone());
#ifdef TASKED
			char * SCHEME = new char[65536*4];
			zVars * _zvars = new zVars();
			_zvars->insert(zvars.begin(), zvars.end());
			for (zVars::iterator z_it = _zvars->begin(); z_it != _zvars->end(); z_it++) {
				z_it->second = z_it->second->clone();
			}
			_strcpy(SCHEME, 65536*4, _Scheme);
			#pragma omp task shared(BEST) if((int)(NPP*TASK_PART) > 1) untied
			{
#else
				char SCHEME[65536] = "";
				zVars * _zvars = &zvars;
				_strcpy(SCHEME, 65536, _Scheme);
#endif
				zVars::iterator _z_last = _zvars->end();
				zVars::iterator z_it;
				// The last layer is LINEAR. z[last] is not considered (= OUT)
				_z_last--;
				for (z_it = _zvars->begin(); z_it != _z_last; z_it++) {
					do {
						ITEM * z__S = SUBSTITUTE_SQRS(z_it->second, nInputs, Vars, *_zvars);
						z_it->second = SIMPLIFY(z__S);
					} while (PRESENT_SQRS(z_it->second, nInputs));
				}
				char * Buf = new char[65536*16];
				Buf[0] = 0x0;
				ITEM * _S = OUT;
				do {
					ITEM * __S = SUBSTITUTE_SQRS(_S, nInputs, Vars, *_zvars);
					_S = SIMPLIFY(__S);
				} while (PRESENT_SQRS(_S, nInputs));
				_S->sprint(Vars, Buf);
				_strcat(Buf, 65536*16, "\n");
				long long used_mask = 0;
				_S->CHECK_VARS(used_mask, nInputs, Vars, *_zvars);
				long long k = ONE64<<nInputs;
				// The last layer is LINEAR. z[last] is not considered (= OUT)
				for (z_it = _zvars->begin(); z_it != _z_last; z_it++, k <<= 1)
				  if (used_mask & k) {
					ITEM * z_S = z_it->second;
					char zBuf[65536*2] = "";
					z_S->sprint(Vars, zBuf);
					_strcat(Buf, 65536*16, z_it->first.c_str());
					_strcat(Buf, 65536*16, " = sqrt(");
					_strcat(Buf, 65536*16, zBuf);
					_strcat(Buf, 65536*16, ")\n");
				}
				delete _S;
				#pragma omp critical
				{
					char * STR = new char[strlen(SCHEME)+strlen(Buf)+100];
					_sprintf2(STR, 65536*16, "\nNET<%s>: %s\n", SCHEME, Buf);
					fprintf(VARIANTS, "%s", STR);

					unsigned int L = strlen(STR);
					vector<string>::iterator after = BEST.begin();
					while (after != BEST.end() && after->length() < L) after++;
					BEST.insert(after, string(STR));
					if (BEST.size() > 3) BEST.pop_back();
					
					delete[] STR;
					
					fflush(VARIANTS);
				}
				delete[] Buf;
#ifdef TASKED
				_z_last++;
				for (z_it = _zvars->begin(); z_it != _z_last; z_it++) {
					delete z_it->second;
				}
				delete _zvars;
				delete[] SCHEME;
			}
#endif
		  }
		}

		variant[0]++;
		for (int j = 0; j < P && variant[j] >= _VARS[b_base[layer-1]+j]->size(); j++) {
			variant[j] = 0;
			if (j < P-1) variant[j+1]++;
		}

		for (int j = 0; j < P; j++)
			delete _OUTPUTS[j];
	}

	for (int i = 0; i < n_input[layer-1]; i++)
		delete INPUTS[i];
	for (int i = 0; i < n_output[layer-1]; i++)
		delete OUTPUTS[i];

	if (layer == 1 && !Scheme)
		delete[] Scheme;

	delete[] _Scheme;

	if (layer == 1) {
		zVars::iterator it;
		for (it = zvars.begin(); it != zvars.end(); it++)
			delete it->second;
		zvars.clear();
	}

	return NULL;
};

void * ANALYZE(int nInputs, long double * W, long double * B,
			   long double * SMIN, long double * SMAX, int * SFREQ,
			   vector<long double> XX[], vector<long double> YY[]) {
	int NPP = NPROCS;

	double start_time = omp_get_wtime();

	vector<vector<VARIANT> *> _VARS(NEURO1+NEURO2+1);

	const long double eps_stand = 1E-2;
	const long double eps_min = 1E-3;

	int nk[2] = {0, 0};
	int ns[n_kinds-1] = {0, 0, 1, 1};
	long double tols[2] = {eps_stand, eps_stand};
	int n_layer[3] = {NEURO1, NEURO2, 1};
	int base = 0;

	for (int layer = 0; layer < 3; base += n_layer[layer++]) {
		if (layer == 1) {
			int n = nk[0] + nk[1];
			for (int i = 0; i < 2; i++)
				tols[i] = eps_min + (4.0 - 4.0*nk[i]/n)*(eps_stand - eps_min);
			printf("SECOND LAYER TOLS: DIR(%Lf) && REV(%Lf)\n", tols[0], tols[1]);
		}
		#pragma omp parallel for schedule(guided) num_threads(NPP)
		for (int k = 0; k < n_layer[layer]; k++) {
			int j = base + k;
			int N = XX[j].size();
			vector<VARIANT> * VARS = new vector<VARIANT>();
			double errw[n_kinds] = {1E300, 1E300, 1E300, 1E300, 1E300};
			long double * bestKF[n_kinds] = {NULL, NULL, NULL, NULL, NULL};
			int bestN[n_kinds] = {-1, -1, -1, -1, -1};
			long double min_errw = 1E300;
			int kind = -1;

			if (j != NEURO1+NEURO2) {
				long double DIAP = SMAX[j]-SMIN[j];
				long double d = (_div-1)/DIAP;
				int NP = XX[j].size();
				for (int i = 0; i < NP; i++)
					SFREQ[j*_div+(int)((XX[j][i]-SMIN[j])*d)]++;
				vector<long double> W(NP);
				for (int i = 0; i < NP; i++)
					W[i] = SFREQ[j*_div+(int)((XX[j][i]-SMIN[j])*d)];
				vector<long double> XXSQR(N);
				for (int i = 0; i < N; i++)
					XXSQR[i] = sqrt(XX[j][i]);
				vector<long double> XXREV(N);
				for (int i = 0; i < N; i++)
					XXREV[i] = 1/XX[j][i];
				vector<long double> XXSQRREV(N);
				for (int i = 0; i < N; i++)
					XXSQRREV[i] = 1/sqrt(XX[j][i]);
				vector<long double> * XXX[n_kinds] = {&XX[j], &XXSQR, &XXREV, &XXSQRREV, NULL};
				for (int X = 0; X < n_kinds-1; X++) {
					for (int n = 2; n <= maxN; n++) {
						double cur_err;
						long double * KF = MNK_of_X(n, W, *XXX[X], YY[j], cur_err);
						if (errw[X] > 0.01 && cur_err < 0.9*errw[X]) {
							delete[] bestKF[X];
							bestKF[X] = KF;
							bestN[X] = n;
							errw[X] = cur_err;
						} else
							delete[] KF;
					}
				}

				for (int X = 0; X < n_kinds-1; X++)
					if (errw[X] < min_errw) {
						min_errw = errw[X];
						kind = X;
					}
			} else {
				kind = vkLinear;
				bestN[kind] = 0;
				errw[kind] = 0.0;
				min_errw = 0.0;
			}
			VARIANT V = {kind, bestN[kind], bestKF[kind]};
			VARS->push_back(V);
			if (layer == 0)
				nk[ns[kind]]++;
			if (layer < 2) {
				for (int X = 0; X < n_kinds-1; X++)
					if (X != kind)
						if (fabs(errw[X]-errw[kind])<tols[ns[X]]) {
							VARIANT V1 = {X, bestN[X], bestKF[X]};
							VARS->push_back(V1);
							if (layer == 0)
								nk[ns[X]]++;
						}
			}

			#pragma omp critical
			{
				printf("LAYER %i : NEURON [%i] has range [%lf - %lf] described as { ",
					   layer+1, k, (double)SMIN[j], (double)SMAX[j]
				);
				for (unsigned int k = 0; k < VARS->size(); k++) {
					printf("%s%i[", kinds[(*VARS)[k].kind], (*VARS)[k].N);
					for (int i = 0; i < (*VARS)[k].N; i++)
						printf("%lf%s", (double)(*VARS)[k].KF[i], i<(*VARS)[k].N-1 ? "," : "");
					printf("]");
					printf("%s", k<VARS->size()-1 ? " , " : " }\n");
				}
				_VARS[j] = VARS;
			}
			fflush(stdout);
		}
	}

	char * Vars[256];
	for (int i = 0; i < nInputs + NEURO1 + NEURO2 + 1; i++) {
		Vars[i] = new char[8];
		Vars[i][0] = i < nInputs ? 'a' + i : 'z';
		Vars[i][1] = i < nInputs ? 0x0 : '0' + (i-nInputs)/10;
		Vars[i][2] = i < nInputs ? 0x0 : '0' + (i-nInputs)%10;
		Vars[i][3] = 0x0;
	}
	zVars zvars;
	FILE * VFile = NULL;
	_fopen(VFile, VARIANTS_FILE, "w+t");
	vector<string> BEST;
	#pragma omp parallel if((int)(NPP*TASK_PART) > 1) num_threads(max(1,(int)(NPP*TASK_PART)))
	{
		#pragma omp single
		{
			BUILD_FUNC(VFile, BEST, nInputs, Vars, W, B, _VARS, 1, zvars);
#ifdef TASKED
			if ((int)(NPP*TASK_PART) > 1) {
				#pragma omp taskwait
			}
#endif
		}
	}
	fclose(VFile);
	printf("\nThe compactest results:\n");
	for (unsigned int i = 0; i < BEST.size(); i++)
		printf("%i.%s\n", i, BEST[i].c_str());
	printf("More information see in '%s'\n\n", VARIANTS_FILE);
	for (int i = 0; i < nInputs+1; i++) {
		delete[] Vars[i];
	}

	for (unsigned int j = 0; j < _VARS.size(); j++) {
		for (unsigned int X = 0; X < _VARS[j]->size(); X++)
			delete[] (*_VARS[j])[X].KF;
		delete _VARS[j];
		_VARS[j] = NULL;
	}
	fflush(stdout);

	double time = omp_get_wtime() - start_time;

	printf("ANALYZE Time = %lf sec.\n", time);

	return NULL;
}

#endif
#ifndef __NNETS_H__
#define __NNETS_H__

// #define _CRT_SECURE_NO_WARNINGS

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

using namespace std;

#if defined(__linux__) || defined(__LINUX__)
#define _isnan isnan
#endif

const int _div = 20;

const int maxN = 4;

const int MAX_P = 256;

int NEURO1 = 3;
int NEURO2 = 2;

const int MAX_NN = 256;
const int MAX_NW = 1024;
const int MAX_NB = MAX_NN;

const int MAX_EPOCHS = 1000;

const double tol = 1E-4;

typedef void *(*ANALYZER)(int nInputs, long double * W, long double * B,
			   long double * SMIN, long double * SMAX, int * SFREQ,
			   vector<long double> XX[], vector<long double> YY[]);

/* LU - разложение  с выбором максимального элемента по диагонали */
bool _GetLU(int NN, int * iRow, long double * A, long double * LU)
{
 int i,j,k;
 try {
   memmove(LU,A,NN*NN*sizeof(long double));
   for (i=0;i<NN;i++)
       iRow[i]=i;
   for (i=0;i<NN-1;i++)
     {
      long double Big  = fabs(LU[iRow[i]*NN+i]);
      int iBig = i;

      long double Kf;

      for (j=i+1;j<NN;j++)
          {
           long double size = fabs(LU[iRow[j]*NN+i]);

           if (size>Big)
              {
               Big  = size;
               iBig = j;
              }
          }
      if (iBig!=i)
         {
          int V = iRow[i];
          iRow[i] = iRow[iBig];
          iRow[iBig] = V;
         }
      Kf = 1.0/LU[iRow[i]*NN+i];

      LU[iRow[i]*NN+i] = Kf;
      for (j=i+1;j<NN;j++)
          {
           long double Fact = Kf*LU[iRow[j]*NN+i];

           LU[iRow[j]*NN+i] = Fact;
           for (k=i+1;k<NN;k++)
               LU[iRow[j]*NN+k] -= Fact*LU[iRow[i]*NN+k];
          }
     }
   LU[(iRow[NN-1]+1)*NN-1] = 1.0/LU[(iRow[NN-1]+1)*NN-1];
 }
 catch (...) {
   return false;
 }
 return true;
}

/* Метод LU - разложения */
bool _SolveLU(int NN, int * iRow, long double * LU, long double * Y, long double * X)
{
 int i,j,k;
 try {
   X[0] = Y[iRow[0]];
   for (i=1;i<NN;i++)
       {
        long double V  = Y[iRow[i]];

        for (j=0;j<i;j++)
            V -= LU[iRow[i]*NN+j]*X[j];
        X[i] = V;
       }

   X[NN-1]*=LU[(iRow[NN-1]+1)*NN-1];

   for (i=1,j=NN-2;i<NN;i++,j--)
       {
        long double V = X[j];

        for (k=j+1;k<NN;k++)
            V -= LU[iRow[j]*NN+k]*X[k];
        X[j] = V*LU[iRow[j]*NN+j];
       }
 }
 catch (...) {
   return false;
 }
 return true;
}

long double * MNK_of_X(int N,
					   const vector<long double> W,
					   const vector<long double> X,
					   const vector<long double> Y,
					   double &err) {
 int Z = X.size();
 vector<long double> _XP(Z,1.0);
 long double * A   = new long double[N*N];
 long double * LU  = new long double[N*N];
 long double * B   = new long double[N];
 long double * XX  = new long double[N];
 int *    iLU = new int[N];
 int i,j,k;

 for (i=0; i<2*N-1; i++) {
   long double QX = 0.0;
   long double QY = 0.0;
   for (j=0; j<Z; j++) {
     QX += W[j]*_XP[j];
     if (i<N) QY += W[j]*_XP[j]*Y[j];
     _XP[j] *= X[j];
   }
   for (j = (i<N ? i : N-1), k = (i<N ? 0 : i-N+1) ; j>=0 && k<N; j--, k++)
     A[k*N+j] = QX;
   if (i<N) B[i] = QY;
 }    
 long double ZZ = 0.0;
 if (!(_GetLU(N, iLU, A, LU) && _SolveLU(N, iLU, LU, B, XX))) {
    memset(XX,0,N*sizeof(long double));
    err = 1E300;
 } else {
   for (k=0; k<N; k++)
     if (_isnan(XX[k])) {
        memset(XX,0,N*sizeof(long double));
        err = 1E300;
        return XX;
     }
   err = 0.0;
   for (j=0; j<Z; j++) {
     long double R = 0.0;
     for (k=N-1; k>=0; k--)
       R = R*X[j]+XX[k];
     double cur_err = fabs(R-Y[j]);
     err += W[j]*cur_err;
	 ZZ += W[j];
   }
 }

 delete[] A;
 delete[] LU;
 delete[] B;
 delete[] iLU;
 
 if (ZZ > 0.0) err /= ZZ;

 return XX;
}

inline long double S(long double s) {
	return 1.0 / (1.0 + exp(-s));
};

int P = 0;

long double * W = NULL;
long double * B = NULL;

long double * X[MAX_P];

long double Y1[MAX_NN] = {0.0};
long double Y2[MAX_NN] = {0.0};

inline long double NET(int i, long double * SMIN, long double * SMAX,
			vector<long double> * XX, vector<long double> * YY) {
	memset(Y1, 0, NEURO1*sizeof(long double));
	memset(Y2, 0, NEURO2*sizeof(long double));
	int ptr = 0;
	for (int j = 0; j < P; j++)
		for (int k = 0; k < NEURO1; k++, ptr++)
			Y1[k] += W[ptr]*X[j][i];
	int ptr1 = 0;
	for (int k = 0; k < NEURO1; k++, ptr1++) {
		Y1[k] += B[ptr1];
		if (SMIN && SMAX) {
			if (Y1[k] < SMIN[k]) SMIN[k] = Y1[k];
			if (Y1[k] > SMAX[k]) SMAX[k] = Y1[k];
		}
		if (XX) XX[k].push_back(Y1[k]);
		Y1[k] = S(Y1[k]);
		if (YY) YY[k].push_back(Y1[k]);
	}

	for (int j = 0; j < NEURO1; j++)
		for (int k = 0; k < NEURO2; k++, ptr++)
			Y2[k] += W[ptr]*Y1[j];
	for (int k = 0; k < NEURO2; k++, ptr1++) {
		Y2[k] += B[ptr1];
		if (SMIN && SMAX) {
			if (Y2[k] < SMIN[ptr1]) SMIN[ptr1] = Y2[k];
			if (Y2[k] > SMAX[ptr1]) SMAX[ptr1] = Y2[k];
		}
		if (XX) XX[ptr1].push_back(Y2[k]);
		Y2[k] = S(Y2[k]);
		if (YY) YY[ptr1].push_back(Y2[k]);
	}

	long double res = B[ptr1];
	for (int k = 0; k < NEURO2; k++, ptr++) {
		res += Y2[k]*W[ptr];
	}
	if (XX) XX[ptr1].push_back(res);
	if (YY) YY[ptr1].push_back(res);

	if (SMIN && SMAX) {
		int idx = NEURO1+NEURO2;
		if (res < SMIN[idx]) SMIN[idx] = res;
		if (res > SMAX[idx]) SMAX[idx] = res;
	}

	return res;
};

FILE * ReadNetHeader(const char * NET_FILE_NAME, int & NInputs, char * DAT_FILE_NAME,
	int & NRows, int & NCols, int * NCC, int & N1, int & N2, int & N3) {
	FILE * NET = NULL;
	_fopen(NET, NET_FILE_NAME, "rt");

	if (!NET) {
		printf("Can't open NET FILE\n");
		exit(-10);
	}

	char Buf[512] = "";
	while (!feof(NET) && (strlen(Buf)<3 || Buf[0] != '-' || Buf[1] != '-' || Buf[2] != '-'))
		fgets(Buf, 510, NET);

	if (feof(NET)) {
		printf("No NET data in the NET FILE\n");
		exit(-11);
	}

	_fscanf(NET, "%i", &NInputs);
	do {
		fgets(DAT_FILE_NAME, 254, NET);
		if (strlen(DAT_FILE_NAME)) {
			if (DAT_FILE_NAME[strlen(DAT_FILE_NAME)-1] == '\n')
				DAT_FILE_NAME[strlen(DAT_FILE_NAME)-1] = 0;
		}
	} while (!feof(NET) && strlen(DAT_FILE_NAME) == 0);
	if (feof(NET)) {
		printf("No DATA FILE NAME in the NET FILE\n");
		exit(-12);
	}

	_fscanf(NET, "%i", &NRows);
	_fscanf(NET, "%i", &NCols);

	for (int i = 0; i <= NInputs; i++)
		_fscanf(NET, "%i", &NCC[i]);

	_fscanf(NET, "%i", &N1);
	_fscanf(NET, "%i", &N2);
	_fscanf(NET, "%i", &N3);

	if (N3 != 1) {
		printf("In this version ONLY 3-layer 1-output nets are processed\n");
		exit(-13);
	}

	return NET;
}

FILE * WriteNetHeader(const char * NET_FILE_NAME,
	int NInputs, const char * DAT_FILE_NAME,
	int NRows, int NCols, int * NCC, int N1, int N2, int N3) {

	FILE * NET = NULL;
	_fopen(NET, NET_FILE_NAME, "w+t");

	if (!NET) {
		printf("Can't open NET FILE for writing\n");
		exit(-20);
	}

	fprintf(NET, "Net file after additional training by the nnets_simplify\n");
	fprintf(NET, "-------------------------------------------------------\n");

	fprintf(NET, "%i\n\n", NInputs);
	fprintf(NET, "%s\n\n", DAT_FILE_NAME);

	fprintf(NET, "%i %i\n\n", NRows, NCols);

	for (int i = 0; i <= NInputs; i++)
		fprintf(NET, "%i ", NCC[i]);
	fprintf(NET, "\n\n");

	fprintf(NET, "%i %i %i\n\n", N1, N2, N3);

	return NET;
}

void WriteOut(const char * NET_FILE, int L, long double * YS,
			  long double NUMIN, long double NUMAX,
			  long double numin, long double numax) {
	char Buf1[512];
	_strcpy(Buf1, 512, NET_FILE);
	char * point = strrchr(Buf1, '.');
	if (point) *point = 0;
	_strcat(Buf1, 512, ".net_out");
	FILE * RES;
	_fopen(RES, Buf1, "w+t");
	for (int i = 0; i < L; i++)
		fprintf(RES, "%Lf\n", NUMIN + (NUMAX - NUMIN)*(YS[i]-numin)/(numax-numin));
	fclose(RES);
}


long double PREDICT(FILE * BEST,
					int PP, int L, int Cols, int * NCC, long double * M[], double * OUT, long double * ERR,
					const char * NET_FILE, const char * DAT_FILE, bool continued,
					ANALYZER analyzer = NULL, void ** analyzer_result = NULL) {
	P = PP;
	
	memset(ERR, 0, L*sizeof(long double));

	W = new long double[P*NEURO1+NEURO1*NEURO2+NEURO2];
	B = new long double[NEURO1+NEURO2+1];

	for (int p = 0; p < P; p++)
		X[p] = new long double[L];

	long double * Y = new long double[L];
	long double * YS = new long double[L];

	long double MMIN[MAX_P];
	long double MMAX[MAX_P];
	long double mmin[MAX_P];
	long double mmax[MAX_P];
	long double d[MAX_P];

	long double NUMIN, numin;
	long double NUMAX, numax;

	long double err = 1E300;

	memset(Y1, 0, NEURO1*sizeof(long double));
	memset(Y2, 0, NEURO2*sizeof(long double));

	int ptr;

	long double best_err;

	_fscanf(BEST, "%Lf", &err);
	best_err = err;
	if (err >= 1E300)
		printf("Untrained net accepted\n");
	else
		printf("Best err = <%Lf = %Lf>\n", err, (long double)(err/L));
	fflush(stdout);
	err /= L;
		
	for (int i = 0; i < P; i++)
		_fscanf(BEST, "%Lf", &MMIN[i]);
	for (int i = 0; i < P; i++)
		_fscanf(BEST, "%Lf", &MMAX[i]);
	for (int i = 0; i < P; i++)
		_fscanf(BEST, "%Lf", &mmin[i]);
	for (int i = 0; i < P; i++)
		_fscanf(BEST, "%Lf", &mmax[i]);
	_fscanf(BEST, "%Lf", &NUMIN);
	_fscanf(BEST, "%Lf", &NUMAX);
	_fscanf(BEST, "%Lf", &numin);
	_fscanf(BEST, "%Lf", &numax);
	ptr = 0;
	for (int i = 0; i < P; i++)
		for (int j = 0; j < NEURO1; j++, ptr++)
			_fscanf(BEST, "%Lf", &W[ptr]);
	for (int i = 0; i < NEURO1; i++)
		for (int j = 0; j < NEURO2; j++, ptr++)
			_fscanf(BEST, "%Lf", &W[ptr]);
	for (int j = 0; j < NEURO2; j++, ptr++)
		_fscanf(BEST, "%Lf", &W[ptr]);
	ptr = 0;
	for (int j = 0; j < NEURO1; j++, ptr++)
		_fscanf(BEST, "%Lf", &B[ptr]);
	for (int j = 0; j < NEURO2; j++, ptr++)
		_fscanf(BEST, "%Lf", &B[ptr]);
	_fscanf(BEST, "%Lf", &B[ptr++]);
	fclose(BEST);

	for (int p = 0; p < P; p++) {
		d[p] = MMAX[p]==MMIN[p] ? 1.0 : (mmax[p]-mmin[p])/(MMAX[p]-MMIN[p]);
		for (int i = 0; i < L; i++)
			X[p][i] = mmin[p] + (M[p][i]-MMIN[p])*d[p];
	}

	long double nud = NUMAX==NUMIN ? 1.0 : (numax-numin)/(NUMAX-NUMIN);
	for (int i = 0; i < L; i++)
		Y[i] = numin + (OUT[i]-NUMIN)*nud;

//	long double _test_err = 0.0; // TEST
	for (int i = 0; i < L; i++) {
		YS[i] = NET(i, NULL, NULL, NULL, NULL);
		long double delta = YS[i]-Y[i];
		ERR[i] = fabs(delta);
		// TEST
//				long double a = X[0][i];
//				long double b = X[1][i];
//				long double c = X[2][i];
//				long double z06 = sqrt(1.416076e+000+1.518198e+001*a-5.094359e-001*pow(a,2)+4.024536e-001*b-3.524729e+000*b*a-6.096799e+000*pow(b,2)+1.107693e+001*c-5.024675e+000*c*a-1.738258e+001*c*b-1.238986e+001*pow(c,2));
//				long double f = (3.302393e+000+2.278103e+001*a-2.830472e+001*pow(a,2)+2.296270e+001*pow(a,3)-4.273830e+000*b-2.098326e+001*b*a+2.907038e+001*b*pow(a,2)+5.984606e-001*pow(b,2)+1.226753e+001*pow(b,2)*a+1.725609e+000*pow(b,3)+1.642059e+001*c+4.717526e+000*c*a+1.632001e+001*c*b+1.163249e+001*pow(c,2)-6.437025e+002*z06-4.319872e+003*a*z06+6.276566e+003*pow(a,2)*z06-5.402677e+003*pow(a,3)*z06+7.147914e+002*pow(a,4)*z06-1.750849e+002*pow(a,5)*z06+2.109694e+003*pow(a,6)*z06-2.571579e+003*pow(a,7)*z06+1.826297e+003*pow(a,8)*z06-1.614967e+002*pow(a,9)*z06+8.310175e+002*b*z06+3.885895e+003*b*a*z06-6.687806e+003*b*pow(a,2)*z06+1.379170e+003*pow(a,3)*b*z06-9.825926e+002*pow(a,4)*b*z06+2.381351e+003*pow(a,5)*b*z06-4.746731e+003*pow(a,6)*b*z06+4.004742e+003*pow(a,7)*b*z06-6.133561e+002*pow(a,8)*b*z06-1.163097e+002*pow(b,2)*z06-2.265162e+003*pow(b,2)*a*z06+8.111447e+002*pow(a,2)*pow(b,2)*z06-1.587360e+003*pow(a,3)*pow(b,2)*z06+3.238551e+003*pow(a,4)*pow(b,2)*z06-5.155565e+003*pow(a,5)*pow(b,2)*z06+4.547185e+003*pow(a,6)*pow(b,2)*z06-1.035331e+003*pow(a,7)*pow(b,2)*z06-3.320577e+002*pow(b,3)*z06-5.063380e+000*a*pow(b,3)*z06-3.787891e+002*pow(a,2)*pow(b,3)*z06+1.873783e+003*pow(a,3)*pow(b,3)*z06-3.795102e+003*pow(a,4)*pow(b,3)*z06+3.452986e+003*pow(a,5)*pow(b,3)*z06-1.019442e+003*pow(a,6)*pow(b,3)*z06-8.528884e+000*pow(b,4)*z06-1.378162e+001*pow(b,4)*a*z06+3.808916e+002*pow(b,4)*pow(a,2)*z06-1.530795e+003*pow(b,4)*pow(a,3)*z06+1.780831e+003*pow(b,4)*pow(a,4)*z06-6.452976e+002*pow(b,4)*pow(a,5)*z06+6.702111e+000*pow(b,5)*z06+3.498854e+001*pow(b,5)*a*z06-3.273098e+002*pow(b,5)*pow(a,2)*z06+5.969774e+002*pow(b,5)*pow(a,3)*z06-2.723118e+002*pow(b,5)*pow(a,4)*z06-4.356662e-001*pow(b,6)*z06-3.229136e+001*pow(b,6)*a*z06+1.215056e+002*pow(b,6)*pow(a,2)*z06-7.660933e+001*pow(b,6)*pow(a,3)*z06-1.408312e+000*pow(b,7)*z06+1.564745e+001*pow(b,7)*a*z06-1.709665e+001*pow(b,7)*pow(a,2)*z06+2.629718e+000*pow(b,7)*pow(a,3)*z06-3.864728e+000*pow(b,8)*a*z06+3.329176e+000*pow(b,8)*pow(a,2)*z06+1.404893e+000*pow(b,9)*a*z06+1.976189e-001*pow(b,10)*z06-3.131474e+003*c*z06-9.715712e+002*pow(a,2)*c*z06-2.636956e+002*pow(a,4)*c*z06+1.005290e+003*pow(a,5)*c*z06-5.015294e+002*pow(a,6)*c*z06-3.254117e+003*c*b*z06+1.040436e+003*pow(a,2)*c*b*z06-1.724463e+001*pow(b,2)*c*z06-6.428524e+002*pow(b,2)*pow(a,2)*c*z06-4.907990e+002*pow(b,2)*pow(a,3)*c*z06+5.067301e+001*pow(b,3)*c*z06-4.240024e+002*pow(b,3)*pow(a,2)*c*z06+1.645370e+002*pow(b,3)*pow(a,3)*c*z06+2.760883e+001*pow(b,4)*c*z06-3.287803e+001*pow(b,5)*c*z06-3.052773e+001*pow(b,5)*a*c*z06-8.872485e+000*pow(b,6)*c*z06+1.880507e+000*pow(b,7)*c*z06+5.402571e-001*pow(b,7)*c*a*z06+1.868988e+000*pow(b,8)*c*z06-1.851247e+003*pow(c,2)*z06+8.664473e+002*a*pow(c,2)*z06-1.450162e+003*pow(a,2)*pow(c,2)*z06-5.572930e+002*pow(a,3)*pow(c,2)*z06+3.812501e+002*pow(a,4)*pow(c,2)*z06+4.064907e+002*pow(a,5)*pow(c,2)*z06+1.913916e+002*b*pow(c,2)*z06-1.287354e+003*b*a*pow(c,2)*z06-1.045559e+002*pow(b,2)*pow(c,2)*z06+1.706183e+002*pow(b,2)*a*pow(c,2)*z06+6.665116e+001*pow(b,2)*pow(a,3)*pow(c,2)*z06-1.301815e+002*pow(b,3)*pow(c,2)*z06+4.681209e+001*pow(b,3)*a*pow(c,2)*z06-1.415867e+002*pow(b,4)*pow(c,2)*z06-1.780377e+001*pow(b,4)*a*pow(c,2)*z06-6.146108e+000*pow(b,5)*pow(c,2)*z06+1.332168e+000*pow(b,7)*pow(c,2)*z06+7.273013e+002*pow(c,3)*z06+1.050891e+002*pow(c,3)*a*z06-8.468980e+002*pow(c,3)*pow(a,2)*z06-1.574745e+002*pow(c,3)*pow(a,3)*z06-7.635641e+001*pow(c,3)*pow(a,4)*z06+4.828698e+002*pow(c,3)*b*z06-2.225009e+001*pow(c,3)*b*a*z06-2.314990e+002*pow(c,3)*pow(b,2)*z06-7.607710e+001*pow(c,3)*pow(b,2)*a*z06+8.158487e+001*pow(c,3)*pow(b,2)*pow(a,2)*z06-2.316549e+002*pow(c,3)*pow(b,3)*z06+4.590445e+001*pow(c,3)*pow(b,3)*a*z06+7.264279e+000*pow(c,3)*pow(b,4)*z06+3.893654e+002*pow(c,4)*z06+4.999124e+000*pow(c,4)*a*z06-1.355422e+002*pow(c,4)*pow(a,2)*z06+2.943638e+001*pow(c,4)*b*z06-9.421044e+001*pow(c,4)*b*a*z06-1.221850e+002*pow(c,4)*pow(b,2)*z06+3.468924e-001*pow(c,5)*z06-6.422403e+001*pow(c,5)*a*z06-3.939618e+001*pow(c,5)*b*z06-2.099487e+001*pow(c,6)*z06)/(-1.215354e+000*z06-8.383922e+000*a*z06+1.041676e+001*pow(a,2)*z06-8.450781e+000*pow(a,3)*z06+1.572864e+000*b*z06+7.722302e+000*b*a*z06-1.069854e+001*b*pow(a,2)*z06-2.202467e-001*pow(b,2)*z06-4.514722e+000*pow(b,2)*a*z06-6.350621e-001*pow(b,3)*z06-6.043141e+000*c*z06-1.736154e+000*c*a*z06-6.006125e+000*c*b*z06-4.281014e+000*pow(c,2)*z06)-5.273875e+002+9.174887e+001*a+1.211802e+002*pow(a,5)+9.201397e+000*pow(a,6)-4.188816e+001*b*a+2.329761e+001*pow(a,5)*b+2.034626e+001*pow(b,2)*a-5.561711e+001*pow(b,2)*pow(a,2)+2.457864e+001*pow(a,4)*pow(b,2)+1.382939e+001*pow(a,3)*pow(b,3)+4.376942e+000*pow(a,2)*pow(b,4)-4.996782e-001*pow(b,5)+7.388176e-001*pow(b,5)*a+5.196278e-002*pow(b,6)+3.111804e-001*pow(b,7)+5.114904e+001*c-5.682437e+001*a*c-9.613491e+001*pow(a,2)*c-8.810648e+001*pow(a,3)*c-1.618841e+001*pow(b,2)*c-1.771757e+001*pow(b,3)*c+8.359988e+001*pow(c,2)+2.666423e+001*a*pow(c,2)-2.597796e+001*pow(a,2)*pow(c,2)-2.042661e+001*pow(b,2)*pow(c,2)+9.167390e+000*pow(c,3)-1.234194e+001*a*pow(c,3)-4.076605e+000*pow(c,4);
//				long double f = (2.618692e+001+3.852924e+002*a-1.567662e+003*pow(a,2)-3.82549e+002*pow(a,3)+4.355653e+003*pow(a,4)-9.543897e+003*pow(a,5)+9.149674e+003*pow(a,6)-5.828747e+003*pow(a,7)+1.844247e+003*pow(a,8)-2.873477e+002*pow(a,9)-6.207829e+001*b-9.053027e+002*b*a+7.298168e+003*b*pow(a,2)+8.342633e+003*b*pow(a,3)-3.262483e+004*b*pow(a,4)+4.674065e+004*b*pow(a,5)-3.327548e+004*pow(a,6)*b+1.286348e+004*pow(a,7)*b-2.058133e+003*pow(a,8)*b-1.711104e+002*pow(b,2)-7.831696e+002*pow(b,2)*a-2.92401e+004*pow(b,2)*pow(a,2)+1.032005e+005*pow(b,2)*pow(a,3)-1.195438e+005*pow(b,2)*pow(a,4)+1.114693e+005*pow(a,5)*pow(b,2)-3.354658e+004*pow(a,6)*pow(b,2)+4.743298e+003*pow(a,7)*pow(b,2)+7.676661e+001*pow(b,3)+1.237846e+003*pow(b,3)*a+5.386248e+004*pow(b,3)*pow(a,2)-5.783287e+005*pow(b,3)*pow(a,3)+6.714845e+005*pow(a,4)*pow(b,3)-3.494156e+005*pow(a,5)*pow(b,3)+6.083485e+004*pow(a,6)*pow(b,3)+4.10061e+002*pow(b,4)+1.119301e+004*pow(b,4)*a-5.187535e+004*pow(b,4)*pow(a,2)+6.692282e+005*pow(a,3)*pow(b,4)-6.878378e+005*pow(a,4)*pow(b,4)+2.159192e+005*pow(a,5)*pow(b,4)+8.229334e+002*pow(b,5)-1.082304e+004*pow(b,5)*a+2.328241e+005*pow(a,2)*pow(b,5)-5.157045e+005*pow(a,3)*pow(b,5)+3.069713e+005*pow(a,4)*pow(b,5)+6.972819e+002*pow(b,6)-3.755453e+004*a*pow(b,6)-1.612513e+004*pow(a,2)*pow(b,6)-9.948829e+004*pow(a,3)*pow(b,6)+7.556903e+002*pow(b,7)-5.391528e+004*pow(b,7)*a+1.665283e+005*pow(b,7)*pow(a,2)+6.934908e+002*pow(b,8)-1.857484e+004*pow(b,8)*a+1.86065e+002*pow(b,9)+4.368267e+001*c-2.403912e+003*c*a+8.395637e+003*c*pow(a,2)+7.459021e+003*c*pow(a,3)-1.929844e+004*c*pow(a,4)+3.586939e+004*c*pow(a,5)-2.886426e+004*pow(a,6)*c+1.828132e+004*pow(a,7)*c-5.782133e+003*pow(a,8)*c+7.43646e+002*c*b+9.800835e+003*c*b*a-2.427011e+004*c*b*pow(a,2)-1.020004e+005*c*b*pow(a,3)+1.791982e+005*c*b*pow(a,4)-1.88384e+005*pow(a,5)*c*b+9.77948e+004*pow(a,6)*c*b-2.434605e+004*pow(a,7)*c*b+9.203218e+002*c*pow(b,2)-2.912317e+003*c*pow(b,2)*a+1.244412e+005*c*pow(b,2)*pow(a,2)-5.379941e+005*c*pow(b,2)*pow(a,3)+5.330946e+005*pow(a,4)*c*pow(b,2)-5.568416e+005*pow(a,5)*c*pow(b,2)+2.457443e+005*pow(a,6)*c*pow(b,2)-5.200467e+003*c*pow(b,3)-3.002691e+004*c*pow(b,3)*a-6.434954e+005*c*pow(b,3)*pow(a,2)+3.430504e+006*pow(a,3)*c*pow(b,3)-2.674787e+006*pow(a,4)*c*pow(b,3)+7.887447e+005*pow(a,5)*c*pow(b,3)-7.927865e+003*c*pow(b,4)-3.002606e+004*pow(a,2)*c*pow(b,4)-1.14164e+006*pow(a,3)*c*pow(b,4)+2.773127e+004*pow(a,4)*c*pow(b,4)-1.2014e+004*c*pow(b,5)+4.607162e+005*a*c*pow(b,5)-2.325192e+006*pow(a,2)*c*pow(b,5)+2.663942e+006*pow(a,3)*c*pow(b,5)-1.340438e+004*pow(b,6)*c+5.75907e+005*pow(b,6)*a*c-1.172031e+006*pow(b,6)*pow(a,2)*c-1.196249e+004*pow(b,7)*c+4.431917e+005*pow(b,7)*a*c-5.520681e+003*pow(b,8)*c-1.530209e+003*pow(c,2)-2.874503e+003*pow(c,2)*a+2.184666e+004*pow(c,2)*pow(a,2)-4.468267e+004*pow(c,2)*pow(a,3)+9.42314e+003*pow(c,2)*pow(a,4)+2.049808e+004*pow(a,5)*pow(c,2)-3.84132e+004*pow(a,6)*pow(c,2)+1.848836e+004*pow(a,7)*pow(c,2)+4.284863e+002*pow(c,2)*b-4.202481e+004*pow(c,2)*b*a-1.732688e+005*pow(c,2)*b*pow(a,2)+4.882073e+005*pow(c,2)*b*pow(a,3)-4.151967e+005*pow(a,4)*pow(c,2)*b+2.619922e+005*pow(a,5)*pow(c,2)*b-9.779356e+004*pow(a,6)*pow(c,2)*b+1.249557e+004*pow(c,2)*pow(b,2)+5.526578e+003*pow(c,2)*pow(b,2)*a+3.581753e+005*pow(c,2)*pow(b,2)*pow(a,2)-2.604053e+005*pow(a,3)*pow(c,2)*pow(b,2)+4.746883e+005*pow(a,4)*pow(c,2)*pow(b,2)-2.509119e+005*pow(a,5)*pow(c,2)*pow(b,2)+4.066114e+004*pow(c,2)*pow(b,3)-3.672912e+004*pow(c,2)*pow(b,3)*a+4.36244e+006*pow(a,2)*pow(c,2)*pow(b,3)-9.257838e+006*pow(a,3)*pow(c,2)*pow(b,3)+4.96612e+006*pow(a,4)*pow(c,2)*pow(b,3)+5.761021e+004*pow(c,2)*pow(b,4)-1.277002e+006*a*pow(c,2)*pow(b,4)+3.673388e+006*pow(a,2)*pow(c,2)*pow(b,4)-4.596146e+006*pow(a,3)*pow(c,2)*pow(b,4)+7.695017e+004*pow(b,5)*pow(c,2)-3.478047e+006*pow(b,5)*a*pow(c,2)+7.382868e+006*pow(b,5)*pow(a,2)*pow(c,2)+1.000254e+005*pow(b,6)*pow(c,2)-2.247792e+006*pow(b,6)*a*pow(c,2)+4.654457e+004*pow(b,7)*pow(c,2)+2.153641e+003*pow(c,3)+5.619928e+004*pow(c,3)*a-1.555921e+005*pow(c,3)*pow(a,2)+3.68508e+004*pow(c,3)*pow(a,3)+9.998292e+004*pow(a,4)*pow(c,3)-1.088099e+005*pow(a,5)*pow(c,3)+6.010821e+004*pow(a,6)*pow(c,3)-3.267581e+004*pow(c,3)*b-2.39885e+004*pow(c,3)*b*a+9.049419e+005*pow(c,3)*b*pow(a,2)-7.407692e+005*pow(a,3)*pow(c,3)*b+3.455129e+004*pow(a,4)*pow(c,3)*b+2.474671e+004*pow(a,5)*pow(c,3)*b-8.140891e+004*pow(c,3)*pow(b,2)+2.597857e+005*pow(c,3)*pow(b,2)*a-3.345351e+006*pow(a,2)*pow(c,3)*pow(b,2)+5.270082e+006*pow(a,3)*pow(c,3)*pow(b,2)-3.218347e+006*pow(a,4)*pow(c,3)*pow(b,2)-8.252582e+004*pow(c,3)*pow(b,3)+1.982803e+006*a*pow(c,3)*pow(b,3)-1.413205e+007*pow(a,2)*pow(c,3)*pow(b,3)+1.407348e+007*pow(a,3)*pow(c,3)*pow(b,3)-2.41014e+005*pow(b,4)*pow(c,3)+7.101443e+006*pow(b,4)*a*pow(c,3)-1.242178e+007*pow(b,4)*pow(a,2)*pow(c,3)-3.72328e+005*pow(b,5)*pow(c,3)+8.033621e+006*pow(b,5)*a*pow(c,3)-2.499963e+005*pow(b,6)*pow(c,3)+2.301336e+004*pow(c,4)-1.271766e+005*pow(c,4)*a+1.277454e+005*pow(c,4)*pow(a,2)+1.041426e+005*pow(a,3)*pow(c,4)-2.954505e+004*pow(a,4)*pow(c,4)-1.46398e+004*pow(a,5)*pow(c,4)+1.194154e+004*pow(c,4)*pow(a,6)+9.722505e+004*pow(c,4)*b+7.668681e+005*pow(c,4)*b*a-1.875122e+006*pow(a,2)*pow(c,4)*b+6.29694e+005*pow(a,4)*pow(c,4)*b+7.443147e+004*pow(c,4)*b*pow(a,5)+6.645627e+004*pow(c,4)*pow(b,2)-1.850845e+006*a*pow(c,4)*pow(b,2)+1.052834e+007*pow(a,2)*pow(c,4)*pow(b,2)-1.032674e+007*pow(a,3)*pow(c,4)*pow(b,2)+2.241496e+005*pow(c,4)*pow(b,2)*pow(a,4)-9.115182e+006*pow(b,3)*a*pow(c,4)+1.914435e+007*pow(b,3)*pow(a,2)*pow(c,4)+3.150428e+005*pow(c,4)*pow(b,3)*pow(a,3)+8.992928e+005*pow(b,4)*pow(c,4)-1.311096e+007*pow(b,4)*a*pow(c,4)-9.379569e+004*pow(c,4)*pow(b,4)*pow(a,2)+7.832567e+005*pow(b,5)*pow(c,4)+1.670743e+005*pow(c,4)*pow(b,5)*a-1.693769e+004*pow(c,4)*pow(b,6)-8.097431e+004*pow(c,5)-1.182653e+005*pow(c,5)*a+5.902978e+005*pow(a,3)*pow(c,5)-9.855877e+005*pow(a,4)*pow(c,5)+2.666291e+005*pow(c,5)*pow(a,5)+1.441899e+005*pow(c,5)*b-2.262188e+006*a*pow(c,5)*b+2.695768e+006*pow(a,2)*pow(c,5)*b+8.724712e+005*pow(c,5)*b*pow(a,4)+2.629363e+005*pow(b,2)*pow(c,5)+6.148484e+006*pow(b,2)*a*pow(c,5)-1.421658e+007*pow(b,2)*pow(a,2)*pow(c,5)+9.975779e+004*pow(c,5)*pow(b,2)*pow(a,3)-3.697106e+005*pow(b,3)*pow(c,5)+1.29429e+007*pow(b,3)*a*pow(c,5)+2.646043e+006*pow(c,5)*pow(b,3)*pow(a,2)-1.435749e+006*pow(b,4)*pow(c,5)-1.122275e+006*pow(c,5)*pow(b,4)*a+4.256081e+005*pow(c,5)*pow(b,5)+8.805059e+005*a*pow(c,6)+1.448065e+005*pow(a,2)*pow(c,6)-8.775105e+005*pow(a,3)*pow(c,6)-1.590284e+005*pow(c,6)*pow(a,4)-1.04034e+006*b*pow(c,6)+4.213588e+006*b*a*pow(c,6)-4.945305e+006*b*pow(a,2)*pow(c,6)+4.94985e+006*pow(c,6)*b*pow(a,3)-4.933727e+005*pow(b,2)*pow(c,6)-6.893481e+006*pow(b,2)*a*pow(c,6)-4.076858e+006*pow(c,6)*pow(b,2)*pow(a,2)-2.746693e+005*pow(b,3)*pow(c,6)+7.072544e+006*pow(c,6)*pow(b,3)*a-2.063852e+006*pow(c,6)*pow(b,4)+3.786022e+005*pow(c,7)-2.08483e+006*pow(c,7)*a+1.941467e+006*pow(c,7)*pow(a,2)-2.324895e+006*pow(c,7)*pow(a,3)+2.387919e+006*pow(c,7)*b-9.588854e+006*pow(c,7)*b*a+1.292588e+007*pow(c,7)*b*pow(a,2)+2.821082e+006*pow(c,7)*pow(b,2)-1.066924e+007*pow(c,7)*pow(b,2)*a+7.207399e+006*pow(c,7)*pow(b,3)-1.120302e+006*pow(c,8)+5.213328e+006*pow(c,8)*a-6.506187e+006*pow(c,8)*pow(a,2)-5.955705e+006*pow(c,8)*b+1.613882e+007*pow(c,8)*b*a-1.038747e+007*pow(c,8)*pow(b,2)+2.808603e+006*pow(c,9)-7.178962e+006*pow(c,9)*a+1.063347e+007*pow(c,9)*b-4.289917e+006*pow(c,10))/(-1.504923e+001-2.003206e+002*a+1.162896e+003*pow(a,2)-1.636523e+003*pow(a,3)+1.560162e+003*pow(a,4)-5.871092e+002*pow(a,5)+1.042909e+002*pow(a,6)+3.8288e+001*b+4.680516e+002*b*a-5.425426e+003*b*pow(a,2)+6.487079e+003*b*pow(a,3)-3.464556e+003*b*pow(a,4)+6.500437e+002*b*pow(a,5)+9.805184e+001*pow(b,2)-5.778307e+002*pow(b,2)*a+6.138314e+003*pow(b,2)*pow(a,2)-6.292967e+003*pow(b,2)*pow(a,3)+1.9576e+003*pow(b,2)*pow(a,4)-6.645607e+001*pow(b,3)+2.135853e+003*pow(b,3)*a-4.626525e+003*pow(b,3)*pow(a,2)+2.751411e+003*pow(b,3)*pow(a,3)-2.932686e+002*pow(b,4)-2.565852e+002*pow(b,4)*a-8.191602e+002*pow(b,4)*pow(a,2)-4.647685e+002*pow(b,5)+1.459135e+003*pow(b,5)*a-1.479245e+002*pow(b,6)-2.28752e+001*c+1.443248e+003*c*a-7.100122e+003*c*pow(a,2)+7.041642e+003*c*pow(a,3)-6.093799e+003*c*pow(a,4)+2.328593e+003*c*pow(a,5)-4.774268e+002*c*b-5.866609e+003*c*b*a+3.218456e+004*c*b*pow(a,2)-2.526252e+004*c*b*pow(a,3)+7.619685e+003*c*b*pow(a,4)-3.771931e+002*c*pow(b,2)+7.154531e+002*c*pow(b,2)*a-1.162999e+004*c*pow(b,2)*pow(a,2)+8.712299e+002*c*pow(b,2)*pow(a,3)+3.723281e+003*c*pow(b,3)-1.989077e+004*c*pow(b,3)*a+2.310909e+004*c*pow(b,3)*pow(a,2)+4.565996e+003*c*pow(b,4)-9.801339e+003*c*pow(b,4)*a+3.717028e+003*c*pow(b,5)+6.907003e+002*pow(c,2)-2.128757e+003*pow(c,2)*a+6.5321e+003*pow(c,2)*pow(a,2)-8.05084e+002*pow(c,2)*pow(a,3)-1.388867e+003*pow(c,2)*pow(a,4)+2.735771e+002*pow(c,2)*b+3.947379e+004*pow(c,2)*b*a-8.196008e+004*pow(c,2)*b*pow(a,2)+4.322928e+004*pow(c,2)*b*pow(a,3)-8.214665e+003*pow(c,2)*pow(b,2)+2.532291e+004*pow(c,2)*pow(b,2)*a-3.560505e+004*pow(c,2)*pow(b,2)*pow(a,2)-2.77381e+004*pow(c,2)*pow(b,3)+6.176773e+004*pow(c,2)*pow(b,3)*a-1.802455e+004*pow(c,2)*pow(b,4)-1.729227e+003*pow(c,3)-1.250265e+004*pow(c,3)*a+2.722049e+004*pow(c,3)*pow(a,2)-2.030436e+004*pow(c,3)*pow(a,3)+1.564652e+004*pow(c,3)*b-1.155327e+005*pow(c,3)*b*a+1.128876e+005*pow(c,3)*b*pow(a,2)+4.986644e+004*pow(c,3)*pow(b,2)-9.317927e+004*pow(c,3)*pow(b,2)*a+6.294548e+004*pow(c,3)*pow(b,3)-5.292758e+003*pow(c,4)+5.33032e+004*pow(c,4)*a-5.682147e+004*pow(c,4)*pow(a,2)-6.697212e+004*pow(c,4)*b+1.409476e+005*pow(c,4)*b*a-9.071844e+004*pow(c,4)*pow(b,2)+2.821389e+004*pow(c,5)-6.269712e+004*pow(c,5)*a+9.286692e+004*pow(c,5)*b-3.746579e+004*pow(c,6))+1.930187e+000+1.760087e+000*a-1.119762e+002*pow(b,2)*a-9.388992e-001*c*a-2.550599e+001*pow(c,2)-1.145023e+002*pow(c,4);
//				_test_err += fabs(Y[i]-f);
		// TEST
		}
	// TEST
//		printf("Y TO (NET SIMPLIFIED) TEST: %Lf : averaged = %Lf\n", _test_err, _test_err/L);
	// TEST
	fflush(stdout);	

	const double nu = 0.01;
	const double alpha = 0.2;

	int epochs = 0;
	long double DW[MAX_NW] = {0.0};
	long double DB[MAX_NB] = {0.0};

	double real_err = best_err;

	vector<int> nums(L);
	for (int i = 0; i < L; i++)
		nums[i] = i;
	vector<int> idxs(L);
	for (int i = 0; i < L; i++) {
		int idx = (int)(1.0*(nums.size()-1)*rand()/RAND_MAX);
		idxs[i] = nums[idx];
		nums.erase(nums.begin()+idx);
	}

	for (int i = 0; i < L; i++)
		YS[i] = NET(i, NULL, NULL, NULL, NULL);
	WriteOut(NET_FILE, L, YS, NUMIN, NUMAX, numin, numax);

	if (continued) {
	  do {
		err = 0.0;
		for (int ii = 0; ii < L; ii++) {
			int i = idxs[ii];
			int ptr1;

			YS[i] = NET(i, NULL, NULL, NULL, NULL);
			long double delta = YS[i]-Y[i];
			ERR[i] = fabs(delta);
			err += ERR[i];

			DB[NEURO1+NEURO2] = alpha*DB[NEURO1+NEURO2] + (1-alpha)*(-nu*delta);
			B[NEURO1+NEURO2] += DB[NEURO1+NEURO2];
			ptr = P*NEURO1+NEURO1*NEURO2;
			for (int k = 0; k < NEURO2; k++, ptr++) {
				DW[ptr] = alpha*DW[ptr] + (1-alpha)*(-nu*delta*Y2[k]);
				W[ptr] += DW[ptr];
			}

			long double deltas[MAX_NN] = {0.0};

			ptr = P*NEURO1+NEURO1*NEURO2;
			for (int k = 0; k < NEURO2; k++, ptr++) {
				deltas[k] = Y2[k]*(1.0-Y2[k])*delta*W[ptr];
			}
			ptr = P*NEURO1;
			for (int j = 0; j < NEURO1; j++)
				for (int k = 0; k < NEURO2; k++, ptr++) {
					DW[ptr] = alpha*DW[ptr] + (1-alpha)*(-nu*deltas[k]*Y1[j]);
					W[ptr] += DW[ptr];
				}
			ptr1 = NEURO1;
			for (int k = 0; k < NEURO2; k++, ptr1++) {
				DB[ptr1] = alpha*DB[ptr1] + (1-alpha)*(-nu*deltas[k]);
				B[ptr1] += DB[ptr1];
			}

			long double deltas1[MAX_NN] = {0.0};

			ptr = P*NEURO1;
			for (int j = 0; j < NEURO1; j++)
				for (int k = 0; k < NEURO2; k++, ptr++) {
					deltas1[j] += Y1[j]*(1.0-Y1[j])*deltas[k]*W[ptr];
				}
			ptr = 0;
			for (int j = 0; j < P; j++)
				for (int k = 0; k < NEURO1; k++, ptr++) {
					DW[ptr] = alpha*DW[ptr] + (1-alpha)*(-nu*deltas1[k]*X[j][i]);
					W[ptr] += DW[ptr];
				}
			for (int k = 0; k < NEURO1; k++) {
				DB[k] = alpha*DB[k] + (1-alpha)*(-nu*deltas1[k]);
				B[k] += DB[k];
			}
		}
		err /= L;
		if (epochs%100 == 0) {
			real_err = 0.0;
			for (int i = 0; i < L; i++) {
				YS[i] = NET(i, NULL, NULL, NULL, NULL);
				long double delta = YS[i]-Y[i];
				real_err += fabs(delta);
			  }
			printf("%i epochs reached, err = [%lf (really = %lf) / %i] = %lf (really = %lf)\n", epochs, (double)(err*L), real_err, L, (double)err, (double)(real_err/L));
			fflush(stdout);
		}
	  } while (err > tol && epochs++ < MAX_EPOCHS);

	  err = real_err/L;
	  if (err*L < best_err) {
		  char Buf1[512];
		  _sprintf2(Buf1, 512, "%s.%Lf.bak", NET_FILE, best_err);
		  rename(NET_FILE, Buf1);

		  best_err = err*L;
		  FILE * _BEST = WriteNetHeader(NET_FILE, P, DAT_FILE, L, Cols, NCC, NEURO1, NEURO2, 1);
		  fprintf(_BEST,"%Lf\n\n", best_err);
		  for (int i = 0; i < P; i++)
			  fprintf(_BEST, "%Lf ", MMIN[i]);
		  fprintf(_BEST, "\n");
		  for (int i = 0; i < P; i++)
			  fprintf(_BEST, "%Lf ", MMAX[i]);
		  fprintf(_BEST, "\n\n");
		  for (int i = 0; i < P; i++)
			  fprintf(_BEST, "%Lf ", mmin[i]);
		  fprintf(_BEST, "\n");
		  for (int i = 0; i < P; i++)
			  fprintf(_BEST, "%Lf ", mmax[i]);
		  fprintf(_BEST, "\n\n");
		  fprintf(_BEST, "%Lf\n", NUMIN);
		  fprintf(_BEST, "%Lf\n\n", NUMAX);
		  fprintf(_BEST, "%Lf\n", numin);
		  fprintf(_BEST, "%Lf\n\n", numax);
		  ptr = 0;
		  for (int i = 0; i < P; i++) {
			for (int j = 0; j < NEURO1; j++, ptr++)
				fprintf(_BEST, "%Lf ", W[ptr]);
			fprintf(_BEST,"\n");
		  }
		  fprintf(_BEST,"\n");
		  for (int i = 0; i < NEURO1; i++) {
			for (int j = 0; j < NEURO2; j++, ptr++)
				fprintf(_BEST, "%Lf ", W[ptr]);
			fprintf(_BEST,"\n");
		  }
		  fprintf(_BEST,"\n");
		  for (int j = 0; j < NEURO2; j++, ptr++)
			fprintf(_BEST, "%Lf\n", W[ptr]);
		  fprintf(_BEST,"\n");
		  ptr = 0;
		  for (int j = 0; j < NEURO1; j++, ptr++)
			fprintf(_BEST, "%Lf ", B[ptr]);
		  fprintf(_BEST,"\n\n");
		  for (int j = 0; j < NEURO2; j++, ptr++)
			fprintf(_BEST, "%Lf ", B[ptr]);
		  fprintf(_BEST,"\n\n");
		  fprintf(_BEST, "%Lf\n", B[ptr++]);
		  fprintf(_BEST,"\n");
		  fclose(_BEST);

		  WriteOut(NET_FILE, L, YS, NUMIN, NUMAX, numin, numax);
	  }
	}

	long double err1 = err*L;

	long double tol_err = err1*1.05;

	bool enhanced = true;
	int NW = P*NEURO1 + NEURO1*NEURO2 + NEURO2;
	do {
		long double min_delta = 1E300;
		int min_n_w = -1;
		for (int j = 0; j < NW; j++)
		  if (fabs(W[j]) >= 1e-14) {
			long double save = W[j];
			W[j] = 0.0;
			long double err2 = 0.0;
			for (int i = 0; i < L; i++)
				err2 += fabs(Y[i] - NET(idxs[i], NULL, NULL, NULL, NULL));
			if (err2-err1 < min_delta) {
				min_delta = err2-err1;
				min_n_w = j;
			}
			W[j] = save;
		  }

		if (min_n_w >= 0 && err1+min_delta < tol_err) {
			W[min_n_w] = 0.0;
			int k = min_n_w;
			int layer = 1;
			if (k >= P*NEURO1) {
				k -= P*NEURO1;
				layer++;
				if (k >= NEURO1*NEURO2) {
					k -= NEURO1*NEURO2;
					layer++;
				}
			}
			printf("AT ERROR(%lf to %lf) WEIGHT in %i layer (%i-%i) is excluded\n",
				   (double)err1, (double)(err1+min_delta),
				   layer,
				   layer == 1 ? (k/NEURO1) : (layer == 2 ? k/NEURO2 : k),
				   layer == 1 ? (k%NEURO1) : (layer == 2 ? k%NEURO2 : 0)
			);
			fflush(stdout);
		} else
			enhanced = false;
	} while (enhanced);

	if (analyzer) {
		long double SMIN[MAX_NN];
		long double SMAX[MAX_NN];
		int * SFREQ = new int[(NEURO1+NEURO2+1)*_div];
		memset(SFREQ, 0, (NEURO1+NEURO2+1)*_div*sizeof(int));
		for (int j = 0; j < NEURO1+NEURO2+1; j++) {
			SMIN[j] = 1E300;
			SMAX[j] = -1E300;
		}

		vector<long double> XX[MAX_NN];
		vector<long double> YY[MAX_NN];
		for (int i = 0; i < L; i++)
			NET(i, SMIN, SMAX, XX, YY);

		void * a_res = analyzer(P, W, B, SMIN, SMAX, SFREQ, XX, YY);
		if (analyzer_result) *analyzer_result = a_res;
	}

	fflush(stdout);

	for (int p = 0; p < P; p++)
		delete[] X[p];

	delete[] W;
	delete[] B;
	delete[] Y;
	delete[] YS;

	err = err1/L;

	return err;
}

#endif
#ifndef __NNETS_H__
#define __NNETS_H__

// #define _CRT_SECURE_NO_WARNINGS

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <memory.h>
#include <math.h>
#include <time.h>
#include <float.h>

#include <vector>
#include <map>

#include <omp.h>

using namespace std;

#ifndef max
#define max(a,b) ((a)>(b)?(a):(b))
#endif

#ifdef __LINUX__
#define _isnan isnan
#endif

#ifndef __LINUX__

#define THROW_EXCEPTION(msg) throw exception(msg)

#define _strcat(Dest, N, Src) strcat_s(Dest, N, Src)
#define _strcpy(Dest, N, Src) strcpy_s(Dest, N, Src)
#define _strtok(Str, Delims, Context) strtok_s(Str, Delims, Context)

#define _sprintf1(Buf, N, Fmt, Arg0) sprintf_s(Buf, N, Fmt, Arg0)
#define _sprintf2(Buf, N, Fmt, Arg0, Arg1) sprintf_s(Buf, N, Fmt, Arg0, Arg1)
#define _sprintf3(Buf, N, Fmt, Arg0, Arg1, Arg2) sprintf_s(Buf, N, Fmt, Arg0, Arg1, Arg2)

#define _fopen(F, Name, Mode) fopen_s(&F, Name, Mode)

#define _fscanf(F, Fmt, Arg) fscanf_s(F, Fmt, Arg)

#else

#define THROW_EXCEPTION(msg) { printf(msg); printf("\n"); throw exception(); }

#define _strcat(Dest, N, Src) strcat(Dest, Src)
#define _strcpy(Dest, N, Src) strcpy(Dest, Src)
#define _strtok(Str, Delims, Context) strtok(Str, Delims)

#define _sprintf1(Buf, N, Fmt, Arg0) sprintf(Buf, Fmt, Arg0)
#define _sprintf2(Buf, N, Fmt, Arg0, Arg1) sprintf(Buf, Fmt, Arg0, Arg1)
#define _sprintf3(Buf, N, Fmt, Arg0, Arg1, Arg2) sprintf(Buf, Fmt, Arg0, Arg1, Arg2)

#define _fopen(F, Name, Mode) F = fopen(Name, Mode)

#define _fscanf(F, Fmt, Arg) fscanf(F, Fmt, Arg)

#endif

const int _div = 20;

const int maxN = 4;

const int MAX_P = 256;

int NEURO1 = 3;
int NEURO2[64] = { 0 };

const int MAX_NN = 256;
const int MAX_NW = 8192;
const int MAX_NB = MAX_NN;

const int MAX_EPOCHS = 1000;

const double tol = 1E-4;

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

inline long double NET(int i, long double * W, long double * B, long double * X[], long double Y1[64][MAX_NN]) {
	memset(Y1, 0, 64*MAX_NN*sizeof(long double));
	int ptr = 0;
	for (int j = 0; j < P; j++)
		for (int k = 0; k < NEURO1; k++, ptr++)
			Y1[0][k] += W[ptr]*X[j][i];
	int ptr1 = 0;
	for (int k = 0; k < NEURO1; k++, ptr1++) {
		Y1[0][k] += B[ptr1];
		Y1[0][k] = S(Y1[0][k]);
	}

	int NP = NEURO1;
	int n = 0;
	for (; NEURO2[n]; n++) {
		for (int j = 0; j < NP; j++)
			for (int k = 0; k < NEURO2[n]; k++, ptr++)
				Y1[n+1][k] += W[ptr] * Y1[n][j];
		for (int k = 0; k < NEURO2[n]; k++, ptr1++) {
			Y1[n+1][k] += B[ptr1];
			Y1[n+1][k] = S(Y1[n+1][k]);
		}
		NP = NEURO2[n];
	}

	long double res = B[ptr1];
	for (int k = 0; k < NP; k++, ptr++) {
		res += Y1[n][k]*W[ptr];
	}

	return res;
};

FILE * ReadNetHeader(const char * NET_FILE_NAME, int & NInputs, char * DAT_FILE_NAME,
	int & NRows, int & NCols, int * NCC, int & N1, int * N2, int & N3) {
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

	char * Next = NULL;
	char Config[512];

	_fscanf(NET, "%i", &N1);
	fgets(Config, 512, NET);
	char * NN = _strtok(Config, ", ", &Next);
	int n = 0;
	while (NN) {
		N2[n] = atoi(NN);
		NN = _strtok(NULL, ", ", &Next);
		n++;
	}
	if (n == 0 || N2[n-1] != 1) {
		printf("In this version ONLY 2<=layered 1-output nets are processed\n");
		exit(-13);
	}

	N3 = N2[n - 1];
	N2[n - 1] = 0;

	return NET;
}

FILE * WriteNetHeader(const char * NET_FILE_NAME,
	int NInputs, const char * DAT_FILE_NAME,
	int NRows, int NCols, int * NCC, int N1, int * N2, int N3) {

	FILE * NET = NULL;
	_fopen(NET, NET_FILE_NAME, "w+t");

	if (!NET) {
		printf("Can't open NET FILE for writing\n");
		exit(-20);
	}

	fprintf(NET, "Net file after training\n");
	fprintf(NET, "-------------------------------------------------------\n");

	fprintf(NET, "%i\n\n", NInputs);
	fprintf(NET, "%s\n\n", DAT_FILE_NAME);

	fprintf(NET, "%i %i\n\n", NRows, NCols);

	for (int i = 0; i <= NInputs; i++)
		fprintf(NET, "%i ", NCC[i]);
	fprintf(NET, "\n\n");

	fprintf(NET, "%i ", N1);
	for (int i = 0; N2[i]; i++)
		fprintf(NET, "%i ", N2[i]);
	fprintf(NET, "%i\n\n", N3);

	return NET;
}

bool UNIFY(char * MAP, long double * VALS,
	        FILE * BEST,
			int PP, int L, int Cols, int * NCC, long double * M[], double * OUT, long double * ERR,
			const char * NET_FILE, const char * DAT_FILE) {
	P = PP;
	
	memset(ERR, 0, L*sizeof(long double));

	int NW = P*NEURO1;
	int NB = NEURO1;
	int NP = NEURO1;
	int n = 0;
	for (; NEURO2[n]; n++) {
		NW += NP*NEURO2[n];
		NB += NEURO2[n];
		NP = NEURO2[n];
	}
	NW += NP;
	NB++;

	long double * W = new long double[NW];
	long double * B = new long double[NB];

	long double * X[MAX_P];

	long double Y1[64][MAX_NN] = { 0.0 };

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

	memset(Y1, 0, sizeof(Y1));

	int ptr;

	long double best_err;

	_fscanf(BEST, "%Lf", &err);
	best_err = err;
//	if (err >= 1E300)
//		printf("Untrained net accepted\n");
//	else
//		printf("Best err = <%Lf = %Lf>\n", err, (long double)(err/L));
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
	NP = NEURO1;
	n = 0;
	for (; NEURO2[n]; n++) {
		for (int i = 0; i < NP; i++)
			for (int j = 0; j < NEURO2[n]; j++, ptr++)
				_fscanf(BEST, "%Lf", &W[ptr]);
		NP = NEURO2[n];
	}
	for (int j = 0; j < NP; j++, ptr++)
		_fscanf(BEST, "%Lf", &W[ptr]);
	ptr = 0;
	for (int j = 0; j < NEURO1; j++, ptr++)
		_fscanf(BEST, "%Lf", &B[ptr]);
	n = 0;
	for (; NEURO2[n]; n++) {
		for (int j = 0; j < NEURO2[n]; j++, ptr++)
			_fscanf(BEST, "%Lf", &B[ptr]);
	}
	_fscanf(BEST, "%Lf", &B[ptr++]);
	fclose(BEST);

	for (int p = 0; p < P; p++) {
		d[p] = MMAX[p]==MMIN[p] ? 1.0 : (mmax[p]-mmin[p])/(MMAX[p]-MMIN[p]);
		for (int i = 0; i < L; i++)
			X[p][i] = mmin[p] + (M[p][i]-MMIN[p])*d[p];

		if (MAP[0] && MAP[p] != '*') VALS[p] = mmin[p] + (VALS[p] - MMIN[p])*d[p];
		else VALS[p] = 0.5*(mmin[p] + mmax[p]);
	}

	long double nud = NUMAX==NUMIN ? 1.0 : (numax-numin)/(NUMAX-NUMIN);
	for (int i = 0; i < L; i++)
		Y[i] = numin + (OUT[i]-NUMIN)*nud;

	if (MAP[0] && MAP[P] != '*') VALS[P] = numin + (VALS[P] - NUMIN)*nud;

	for (int i = 0; i < L; i++) {
		YS[i] = NET(i, W, B, X, Y1);
		long double delta = YS[i]-Y[i];
		ERR[i] = fabs(delta);
		}
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
		YS[i] = NET(i, W, B, X, Y1);

	if (MAP[0] == 0) { // teach
	  do {
		err = 0.0;
		for (int ii = 0; ii < L; ii++) {
			int i = idxs[ii];
			int ptr1;

			YS[i] = NET(i, W, B, X, Y1);
			long double delta = YS[i]-Y[i];
			ERR[i] = fabs(delta);
			err += ERR[i];

			DB[NB-1] = alpha*DB[NB-1] + (1-alpha)*(-nu*delta);
			B[NB-1] += DB[NB-1];
			ptr = NW - NEURO2[n-1];
			for (int k = 0; k < NEURO2[n-1]; k++, ptr++) {
				DW[ptr] = alpha*DW[ptr] + (1-alpha)*(-nu*delta*Y1[n][k]);
				W[ptr] += DW[ptr];
			}

			long double deltas[MAX_NN] = {0.0};

			ptr = NW - NEURO2[n - 1];

			for (int k = 0; k < NEURO2[n - 1]; k++, ptr++) {
				deltas[k] = Y1[n][k] * (1.0 - Y1[n][k])*delta*W[ptr];
			}

			ptr = NW - NEURO2[n - 1];
			int ptrb = NB - 1;

			int lr = n;
			for (; lr > 0; lr--) {
				int N1 = lr == 1 ? NEURO1 : NEURO2[lr - 2];
				ptr -= N1*NEURO2[lr - 1];
				int ptr2 = ptr;
				for (int j = 0; j < N1; j++)
					for (int k = 0; k < NEURO2[lr - 1]; k++, ptr2++) {
						DW[ptr2] = alpha*DW[ptr2] + (1 - alpha)*(-nu*deltas[k] * Y1[lr-1][j]);
						W[ptr2] += DW[ptr2];
					}
				ptrb -= NEURO2[lr - 1];
				ptr1 = ptrb;
				for (int k = 0; k < NEURO2[lr-1]; k++, ptr1++) {
					DB[ptr1] = alpha*DB[ptr1] + (1 - alpha)*(-nu*deltas[k]);
					B[ptr1] += DB[ptr1];
				}

				long double deltas1[MAX_NN] = { 0.0 };

				ptr2 = ptr;
				for (int j = 0; j < N1; j++)
					for (int k = 0; k < NEURO2[lr - 1]; k++, ptr2++) {
						deltas1[j] += Y1[lr-1][j] * (1.0 - Y1[lr-1][j])*deltas[k] * W[ptr2];
					}
				for (int j = 0; j < N1; j++)
					deltas[j] = deltas1[j];
			}

			ptr = 0;
			for (int j = 0; j < P; j++)
				for (int k = 0; k < NEURO1; k++, ptr++) {
					DW[ptr] = alpha*DW[ptr] + (1-alpha)*(-nu*deltas[k]*X[j][i]);
					W[ptr] += DW[ptr];
				}
			for (int k = 0; k < NEURO1; k++) {
				DB[k] = alpha*DB[k] + (1-alpha)*(-nu*deltas[k]);
				B[k] += DB[k];
			}
		}
		err /= L;
		if (epochs%100 == 0) {
			real_err = 0.0;
			for (int i = 0; i < L; i++) {
				YS[i] = NET(i, W, B, X, Y1);
				long double delta = YS[i]-Y[i];
				real_err += fabs(delta);
			  }
//			printf("%i epochs reached, err = [%lf (really = %lf) / %i] = %lf (really = %lf)\n", epochs, (double)(err*L), real_err, L, (double)err, (double)(real_err/L));
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
		  NP = NEURO1;
		  n = 0;
		  for (; NEURO2[n]; n++) {
			  for (int i = 0; i < NP; i++) {
				  for (int j = 0; j < NEURO2[n]; j++, ptr++)
					  fprintf(_BEST, "%Lf ", W[ptr]);
				  fprintf(_BEST, "\n");
			  }
			  fprintf(_BEST, "\n");
			  NP = NEURO2[n];
		  }
		  for (int j = 0; j < NP; j++, ptr++)
			fprintf(_BEST, "%Lf\n", W[ptr]);
		  fprintf(_BEST,"\n");
		  ptr = 0;
		  for (int j = 0; j < NEURO1; j++, ptr++)
			fprintf(_BEST, "%Lf ", B[ptr]);
		  fprintf(_BEST,"\n\n");
		  n = 0;
		  for (; NEURO2[n]; n++) {
			  for (int j = 0; j < NEURO2[n]; j++, ptr++)
				  fprintf(_BEST, "%Lf ", B[ptr]);
			  fprintf(_BEST, "\n\n");
		  }
		  fprintf(_BEST, "%Lf\n", B[ptr++]);
		  fprintf(_BEST,"\n");
		  fclose(_BEST);
	  }
	}
    else { // unify
		int findX = 0;

		for (int i = 0; i < P; i++)
			if (MAP[i] == '*')
				findX++;

		for (int p = 0; p < P; p++)
			X[p][0] = VALS[p];

		if (findX == 0) {
			// Просто вычисляем выход
			VALS[P] = NET(0, W, B, X, Y1);
		}
		else if (MAP[P] == '*') {
			printf("Undefined task: can't find both inputs and outputs");

			exit(-10);
		}
		else { // Вычисляем входы
			// Используем метод Ньютона
			int np = omp_get_num_procs();

			double * pVALS[256];
			for (int i = 0; i < np; i++) {
				pVALS[i] = new double[P + 1];
				for (int j = 0; j <= P; j++)
					pVALS[i][j] = VALS[j];
			}

			int rands[2048];
			for (int i = 0; i < 2048; i++)
				rands[i] = rand();

			#pragma omp parallel num_threads(np) shared(pVALS)
			{
				int id = omp_get_thread_num();

				long double * _W = new long double[NW];
				long double * _B = new long double[NB];

				memmove(_W, W, NW*sizeof(long double));
				memmove(_B, B, NB*sizeof(long double));

				long double * _X[MAX_P];

				long double _Y1[64][MAX_NN] = { 0.0 };

				for (int p = 0; p < P; p++)
					_X[p] = new long double;

				long double * A = new long double[findX*findX];
				long double * LU = new long double[findX*findX];
				long double * B = new long double[findX];
				long double * XX = new long double[findX];
				int *    iLU = new int[findX];

				const double eps = 0.001;

				const int max_tries = max(1, 16 / np);
				int tries = 0;

				double YY = pVALS[id][P];

				double df = 1E300;

				int r = (127 * id) % 2048;

				do {
					const int max_iters = 50;
					const double dx = 0.00001;

					int iters = 0;

					double delta = 0.0;

					double _VALS[1024];

					for (int p = 0; p < P; p++) {
						if (MAP[p] == '*')
							_VALS[p] = mmin[p] + (1.0*rands[r] / RAND_MAX)*(mmax[p] - mmin[p]);
						else
							_VALS[p] = pVALS[id][p];
						_X[p][0] = _VALS[p];
						r = (r + 1) % 2048;
					}
					_VALS[P] = YY;

					do {
						long double NETx = NET(0, _W, _B, _X, _Y1);

						int k = 0;
						for (int i = 0; i < P; i++)
							if (MAP[i] == '*') {
								int m = 0;
								for (int j = 0; j < P; j++)
									if (MAP[j] == '*') {
										if (k == m) {
											_X[i][0] = _VALS[i] - dx;
											long double MN = NET(0, _W, _B, _X, _Y1);
											_X[i][0] = _VALS[i] + dx;
											long double PN = NET(0, _W, _B, _X, _Y1);
											_X[i][0] = _VALS[i];
											A[m*findX + k] = 2.0*((PN - _VALS[P])*(PN - NETx) / dx - (MN - _VALS[P])*(NETx - MN) / dx) / dx;
											B[m] = -2.0*(NETx - _VALS[P])*(PN - MN) / (2.0*dx);
										}
										else {
											_X[i][0] = _VALS[i] - dx;
											_X[j][0] = _VALS[j] - dx;
											long double MN1 = NET(0, _W, _B, _X, _Y1);
											_X[j][0] = _VALS[j] + dx;
											long double PN1 = NET(0, _W, _B, _X, _Y1);
											long double G1 = 2.0*(MN1 - _VALS[P])*(PN1 - MN1) / (2.0*dx);

											_X[i][0] = _VALS[i] + dx;
											_X[j][0] = _VALS[j] - dx;
											long double MN2 = NET(0, _W, _B, _X, _Y1);
											_X[j][0] = _VALS[j] + dx;
											long double PN2 = NET(0, _W, _B, _X, _Y1);
											long double G2 = 2.0*(PN2 - _VALS[P])*(PN2 - MN2) / (2.0*dx);

											_X[j][0] = _VALS[j];
											_X[i][0] = _VALS[i];

											A[m*findX + k] = (G2 - G1) / (2.0*dx);
										}
										m++;
									}
								k++;
							}
						if (!(_GetLU(findX, iLU, A, LU) && _SolveLU(findX, iLU, LU, B, XX))) {
							exit(-50);
						}

						k = 0;
						delta = 0.0;
						for (int i = 0; i < P; i++)
							if (MAP[i] == '*') {
								_VALS[i] += 0.25*XX[k];
								if (_VALS[i] < mmin[i]) _VALS[i] = mmin[i];
								if (_VALS[i] > mmax[i]) _VALS[i] = mmax[i];
								_X[i][0] = _VALS[i];
								delta += fabs(XX[k]);
								k++;
							}
					} while (++iters < max_iters && delta > eps);
					_VALS[P] = NET(0, _W, _B, _X, _Y1);

					double ddf = fabs(YY - _VALS[P]);
					if (ddf < df) {
						df = ddf;
						for (int i = 0; i <= P; i++)
							pVALS[id][i] = _VALS[i];
					}
				} while (++tries < max_tries && df > eps);

				delete[] A;
				delete[] LU;
				delete[] B;
				delete[] XX;
				delete[] iLU;

				delete[] _W;
				delete[] _B;
				for (int p = 0; p < P; p++)
					delete _X[p];
			}

			int k = 0;
			double d = fabs(VALS[P] - pVALS[0][P]);
			for (int p = 1; p < np; p++) {
				double dd = fabs(VALS[P] - pVALS[p][P]);
				if (dd < d) {
					d = dd;
					k = p;
				}
			}
			for (int i = 0; i <= P; i++)
				VALS[i] = pVALS[k][i];

			for (int i = 0; i < np; i++)
				delete[] pVALS[i];
		}

		//
		for (int p = 0; p < P; p++)
			VALS[p] = MMIN[p] + (VALS[p] - mmin[p])/d[p];
		VALS[P] = NUMIN + (VALS[P] - numin) / nud;
	}

	fflush(stdout);

	for (int p = 0; p < P; p++)
		delete[] X[p];

	delete[] W;
	delete[] B;
	delete[] Y;
	delete[] YS;

	return true;
}

#endif
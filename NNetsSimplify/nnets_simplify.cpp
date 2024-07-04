// nnets_simplify file.net continue_teach(Y/N) NProcs NVars TaskPart

// #define _CRT_SECURE_NO_WARNINGS

#include "symbolic.h"
#include "nnets.h"
#include "analyze_nnet.h"

#include <stdio.h>
#include <stdlib.h>
#include <time.h>

#include <omp.h>

int main(int argc, char ** argv) {
	if (argc < 3) {
		printf("Usage: nnets_simplify file.net teach(Y/N) [NProcs [NVariants [TaskPart]]]\n");
		exit(-1);
	}

	if (argc > 3) {
		NPROCS = atoi(argv[3]);
	} else
		NPROCS = omp_get_num_procs();

	if (argc > 4)
		NVARIANTS = atoi(argv[4]);
	else
		NVARIANTS = 65536*32;

#if defined(__linux__) || defined(__LINUX__)
	if (argc > 5)
		TASK_PART = atof(argv[5]);
	else
		TASK_PART = 3.0/4.0;
#else
	TASK_PART = 0.0;
#endif

	omp_set_dynamic(1);
	omp_set_nested(1);

	srand((unsigned int)time(NULL));

	int P;
	char F[256];
	int NR, NC;
	int NCC[1024];
	int N3;

	FILE * NET = ReadNetHeader(
		argv[1], P, F, NR, NC, NCC, NEURO1, NEURO2, N3
	);

	FILE * DAT = NULL;
	_fopen(DAT, F, "rt");

	long double * M[MAX_P] = {NULL};

	for (int i = 0; i < P; i++)
		M[i] = new long double[NR];

	double * Y = new double[NR];

	for (int i = 0; i < NR; i++) {
		long double VALS[1024];
		for (int j = 0; j < NC; j++)
			_fscanf(DAT, "%Lf", &VALS[j]);
		for (int j = 0; j < P; j++)
			M[j][i] = VALS[NCC[j]];
		Y[i] = VALS[NCC[P]];
	}

	fclose(DAT);

	long double * ERR = new long double[NR];

	void * a_res = NULL;
	long double err = PREDICT(NET, P, NR, NC, NCC, M, Y, ERR,
		argv[1], F, argv[2][0] == 'Y' || argv[2][0] == 'y',
		ANALYZE, &a_res);
	delete a_res;

	delete[] ERR;

// Symbolic kernel tests
/*
	MUL * _M = new MUL(3.5);
	_M->Mul(0, 1.0);
	SUMMAND * d1 = new DIV(_M);
	SUM * d2s1 = new SUM(1.0);
	SUM * d2s2 = new SUM(2.5);
	SUMMAND * d2 = new DIV(d2s1, d2s2);
	SUMMAND * m3 = new MUL(1.5);
	SUM * s123 = new SUM(0.0);
	s123->Add(d1);
	s123->Add(d2);
	s123->Add(m3);
	SUMMAND * _d1 = new DIV(3.0);
	SUM * _d2s1 = new SUM(-1.0);
	SUM * _d2s2 = new SUM(2.0);
	SUMMAND * _M1 = new MUL(1.0);
	((MUL *)_M1)->Mul(1, 1.0);
	_d2s1->Mul(_M1);
	SUMMAND * _d2 = new DIV(_d2s1, _d2s2);
	SUM * _s123 = new SUM(0.0);
	_s123->Add(_d1);
	_s123->Add(_d2);

	SUMMAND * __d1 = new DIV(3.0);
	SUM * __d2s1 = new SUM(-1.0);
	SUM * __d2s2 = new SUM(2.0);
	SUMMAND * __M1 = new MUL(1.0);
	((MUL *)__M1)->Mul(0, 1.0);
	__d2s1->Mul(__M1);
	SUMMAND * __d2 = new DIV(__d2s1, __d2s2);
	SUM * __s123 = new SUM(0.0);
	__s123->Add(__d1);
	__s123->Add(__d2);

	s123->Mul(_s123);
	SUM * s4 = new SUM(3.0);
	ITEM * D = new DIV(s123, s4);
	((DIV *)D)->divisor->Mul(__s123);
	ITEM * R = REGULARIZE(D);
	ITEM * RR = dynamic_cast<DIV *>(R)->Divide();

	char Buf[65536];
	char * Vars1[2] = {"a", "b"};
	Buf[0] = 0x0;
	RR->sprint(Vars1, Buf);
	printf("\nFORMULA1: %s\n", Buf);

	long double poly1[3] = {-1.0, 0.0, 1.0};
	SUM * SS1 = new SUM(0, 3, poly1);
	long double poly2[2] = {-1.0, 1.0};
	SUM * SS2 = new SUM(0, 2, poly2, 1.0);
	SUM * SSS = new SUM(0.0);
	long double poly3[5] = {1.0, 0.0, 2.0, 0.0, 3.0};
	SSS->SETPOLYSQR(SS2, 1, 5, poly3, true);
	ITEM * DD = dynamic_cast<ITEM *>(new DIV(SS1, SSS));
	ITEM * _RRR = REGULARIZE(DD);
	ITEM * RRR = dynamic_cast<DIV *>(_RRR)->Divide();

	char * Vars2[2] = {"a", "z"};
	Buf[0] = 0x0;
	RRR->sprint(Vars2, Buf);
	printf("\nFORMULA2: %s\n", Buf);
*/

	return 0;
}
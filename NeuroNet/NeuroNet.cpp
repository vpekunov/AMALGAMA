// NeuroNet.exe file.net "command"

#include "nnets.h"

int main(int argc, char ** argv) {
	if (argc < 3) {
		printf("Usage: NeuroNet.exe file.net command\n");
		printf("  command1: create file.dat [IN1,...,INn] [OUT1, ...,OUTn] [N1,N2,N3]\n");
		printf("  command2: teach\n");
		printf("  command3: unify [INVal1|*,..,INValn|*,OUTVal1|*,...,OUTValn|*]\n");
		exit(-1);
	}

	srand((unsigned int)time(NULL));

	int P;
	char F[256];
	int NR, NC;
	int NCC[1024];
	int N3;

	FILE * NET = NULL;
	
	if (strcmp(argv[2], "create") != 0)
		NET = ReadNetHeader(
			argv[1], P, F, NR, NC, NCC, NEURO1, NEURO2, N3
			);
	else {
		char * next = NULL;

		_strcpy(F, 256, argv[3]);

		char * in = _strtok(argv[4], ",[]", &next);
		NC = 0;
		NR = 0;
		while (in != NULL) {
			NCC[NC++] = atoi(in);

			in = _strtok(NULL, ",[]", &next);
		}
		P = NC;

		next = NULL;
		char * out = _strtok(argv[5], ",[]", &next);
		while (out != NULL) {
			NCC[NC++] = atoi(out);

			out = _strtok(NULL, ",[]", &next);
		}

		next = NULL;
		char * nn = _strtok(argv[6], ", []", &next);
		NEURO1 = atoi(nn);

		int n = 0;
		nn = _strtok(NULL, ", []", &next);
		while (nn) {
			NEURO2[n] = atoi(nn);
			nn = _strtok(NULL, ", []", &next);
			n++;
		}
		if (n == 0 || NEURO2[n - 1] != 1) {
			printf("In this version ONLY 2<=layered 1-output nets are processed\n");
			exit(-13);
		}

		N3 = NEURO2[n - 1];
		NEURO2[n - 1] = 0;
	}

	FILE * DAT = NULL;
	_fopen(DAT, F, "rt");

	long double * M[MAX_P] = { NULL };

	NR = 0;
	char Buf[1024] = { 0 };
	while (fgets(Buf, 1024, DAT) != NULL)
		if (Buf[0]) NR++;
	fseek(DAT, 0, SEEK_SET);

	for (int i = 0; i < P; i++)
		M[i] = new long double[NR];

	double * Y = new double[NR];

	for (int i = 0; i < NR; i++) {
		long double VALS[1024];

		fgets(Buf, 1024, DAT);

		char * next = NULL;
		char * val = _strtok(Buf, "\t, ", &next);

		for (int j = 0; j < NC; j++) {
			VALS[j] = atof(val);
			val = _strtok(NULL, "\t, ", &next);
		}
		for (int j = 0; j < P; j++)
			M[j][i] = VALS[NCC[j]];
		Y[i] = VALS[NCC[P]];
	}

	fclose(DAT);

	char MAP[1024];

	long double * ERR = new long double[NR];
	long double * VALS = new long double[P + N3];

	if (strcmp(argv[2], "create") == 0) {
		long double MMIN[1024];
		long double MMAX[1024];
		long double NUMIN = 1E300L, NUMAX = -1E300L;

		FILE * _BEST = WriteNetHeader(argv[1], P, argv[3], NR, NC, NCC, NEURO1, NEURO2, N3);

		for (int j = 0; j < P; j++) {
			MMIN[j] = 1E300L;
			MMAX[j] = -1E300L;
		}
		for (int i = 0; i < NR; i++) {
			for (int j = 0; j < P; j++) {
				if (M[j][i] < MMIN[j]) MMIN[j] = M[j][i];
				if (M[j][i] > MMAX[j]) MMAX[j] = M[j][i];
			}
			if (Y[i] < NUMIN) NUMIN = Y[i];
			if (Y[i] > NUMAX) NUMAX = Y[i];
		}

		fprintf(_BEST, "%Lf\n\n", 1E300L);
		for (int i = 0; i < P; i++)
			fprintf(_BEST, "%Lf ", MMIN[i]);
		fprintf(_BEST, "\n");
		for (int i = 0; i < P; i++)
			fprintf(_BEST, "%Lf ", MMAX[i]);
		fprintf(_BEST, "\n\n");
		for (int i = 0; i < P; i++)
			fprintf(_BEST, "%Lf ", -1.0L);
		fprintf(_BEST, "\n");
		for (int i = 0; i < P; i++)
			fprintf(_BEST, "%Lf ", 1.0L);
		fprintf(_BEST, "\n\n");
		fprintf(_BEST, "%Lf\n", NUMIN);
		fprintf(_BEST, "%Lf\n\n", NUMAX);
		fprintf(_BEST, "%Lf\n", -1.0L);
		fprintf(_BEST, "%Lf\n\n", 1.0L);
		for (int i = 0; i < P; i++) {
			for (int j = 0; j < NEURO1; j++)
				fprintf(_BEST, "%Lf ", (long double)(1.0L*rand() / RAND_MAX));
			fprintf(_BEST, "\n");
		}
		fprintf(_BEST, "\n");
		int NP = NEURO1;
		int n = 0;
		for (; NEURO2[n]; n++) {
			for (int i = 0; i < NP; i++) {
				for (int j = 0; j < NEURO2[n]; j++)
					fprintf(_BEST, "%Lf ", (long double)(1.0L*rand() / RAND_MAX));
				fprintf(_BEST, "\n");
			}
			fprintf(_BEST, "\n");
			NP = NEURO2[n];
		}
		for (int j = 0; j < NP; j++)
			fprintf(_BEST, "%Lf\n", (long double)(1.0L*rand() / RAND_MAX));
		fprintf(_BEST, "\n");
		for (int j = 0; j < NEURO1; j++)
			fprintf(_BEST, "%Lf ", (long double)(1.0L*rand() / RAND_MAX));
		fprintf(_BEST, "\n\n");
		n = 0;
		for (; NEURO2[n]; n++) {
			for (int j = 0; j < NEURO2[n]; j++)
				fprintf(_BEST, "%Lf ", (long double)(1.0L*rand() / RAND_MAX));
			fprintf(_BEST, "\n\n");
		}
		fprintf(_BEST, "%Lf\n", (long double)(1.0L*rand() / RAND_MAX));
		fprintf(_BEST, "\n");
		fclose(_BEST);

		delete[] ERR;
		delete[] VALS;

		for (int i = 0; i < P; i++)
			delete[] M[i];

		delete[] Y;

		printf("#");

		exit(0);
	}
	else if (strcmp(argv[2], "teach") == 0)
		MAP[0] = 0;
	else if (strcmp(argv[2], "unify") == 0) {
		// argv[3]
		char * next = NULL;
		int k = 0;

		char * val = _strtok(argv[3], ",[]", &next);
		while (val != NULL) {
			if (strcmp(val, "*") == 0) {
				VALS[k] = 0.0;
				MAP[k++] = '*';
			}
			else {
				VALS[k] = atof(val);
				MAP[k++] = ' ';
			}

			val = _strtok(NULL, ",[]", &next);
		}
		MAP[k] = 0;
	}
	else {
		printf("Unknown command: %s\n", argv[2]);

		delete[] ERR;
		delete[] VALS;

		for (int i = 0; i < P; i++)
			delete[] M[i];

		delete[] Y;

		exit(0);
	}

	bool result = UNIFY(MAP, VALS, NET, P, NR, NC, NCC, M, Y, ERR,
		argv[1], F);

	printf("#");
	if (strcmp(argv[2], "unify") == 0) {
		for (int i = 0; i < P + N3; i++)
			printf("%Lf ", VALS[i]);
		printf("\n");
	}

	delete[] ERR;
	delete[] VALS;

	for (int i = 0; i < P; i++)
		delete[] M[i];

	delete[] Y;

	return 0;
}
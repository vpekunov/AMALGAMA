// Up to 20 variables.
// In nnets.h: N(neurons)+N(inputs), e.g. (7+5+1)+(4)+tag(3)
// Such restrictions are introduced because each var occupies 6 bit,
//   and var_mask[2] (long long[2]) contains 128 bits.
#ifndef __SYMBOLIC_H__
#define __SYMBOLIC_H__

#include <stdio.h>
#include <stdlib.h>
#include <memory.h>
#include <math.h>
#include <float.h>

#include <vector>
#include <map>
#include <string>

#include <omp.h>

static int NPROCS = 1;

static double TASK_PART = 3.0/4.0;

#if !defined(__linux__) && !defined(__LINUX__)

#define ONE64 1i64
#define FULL64 0x3Fi64
#define ZERO64 0x0i64
#define MINUS64 0x20i64
#define THROW_EXCEPTION(msg) throw exception(msg)

#define _strcat(Dest, N, Src) strcat_s(Dest, N, Src)
#define _strcpy(Dest, N, Src) strcpy_s(Dest, N, Src)
#define _sprintf1(Buf, N, Fmt, Arg0) sprintf_s(Buf, N, Fmt, Arg0)
#define _sprintf2(Buf, N, Fmt, Arg0, Arg1) sprintf_s(Buf, N, Fmt, Arg0, Arg1)
#define _sprintf3(Buf, N, Fmt, Arg0, Arg1, Arg2) sprintf_s(Buf, N, Fmt, Arg0, Arg1, Arg2)

#define _fopen(F, Name, Mode) fopen_s(&F, Name, Mode)

#define _fscanf(F, Fmt, Arg) fscanf_s(F, Fmt, Arg)

#else

#define ONE64 1LL
#define FULL64 0x3FLL
#define ZERO64 0x0LL
#define MINUS64 0x20LL
#define THROW_EXCEPTION(msg) { printf(msg); printf("\n"); throw exception(); }

#define _strcat(Dest, N, Src) strcat(Dest, Src)
#define _strcpy(Dest, N, Src) strcpy(Dest, Src)

#define _sprintf1(Buf, N, Fmt, Arg0) sprintf(Buf, Fmt, Arg0)
#define _sprintf2(Buf, N, Fmt, Arg0, Arg1) sprintf(Buf, Fmt, Arg0, Arg1)
#define _sprintf3(Buf, N, Fmt, Arg0, Arg1, Arg2) sprintf(Buf, Fmt, Arg0, Arg1, Arg2)

#define _fopen(F, Name, Mode) F = fopen(Name, Mode)

#define _fscanf(F, Fmt, Arg) fscanf(F, Fmt, Arg)

#endif

#ifdef _OPENMP
#if defined(__linux__) || defined(__LINUX__) || _OPENMP >= 200800
#define TASKED
#endif
#endif

using namespace std;

struct VarMask {
public:
	long long var_mask[2];

	inline bool operator > (const VarMask op2) const {
		if (var_mask[1] > op2.var_mask[1])
			return true;
		else if (var_mask[1] == op2.var_mask[1])
			return var_mask[0] > op2.var_mask[0];
		else
			return false;
	};

	inline bool operator < (const VarMask op2) const {
		if (var_mask[1] < op2.var_mask[1])
			return true;
		else if (var_mask[1] == op2.var_mask[1])
			return var_mask[0] < op2.var_mask[0];
		else
			return false;
	};

	inline bool operator == (VarMask op2) {
		return var_mask[0] == op2.var_mask[0] && var_mask[1] == op2.var_mask[1];
	};

	inline bool operator == (const VarMask op2) const {
		return var_mask[0] == op2.var_mask[0] && var_mask[1] == op2.var_mask[1];
	};

	inline bool operator != (VarMask op2) {
		return var_mask[0] != op2.var_mask[0] || var_mask[1] != op2.var_mask[1];
	};

	inline bool operator != (const VarMask op2) const {
		return var_mask[0] != op2.var_mask[0] || var_mask[1] != op2.var_mask[1];
	};

	inline bool IsZero() const {
		return var_mask[0] == ZERO64 && var_mask[1] == ZERO64;
	};

	inline void clear() {
		var_mask[0] = 0;
		var_mask[1] = 0;
	};

	inline void setDIV() {
		var_mask[0] = -1;
		var_mask[1] = -1;
	};

	inline void set_mask(long double pow, int var) {
		long long p = (long long)(pow >= 0.0 ? 0.5+pow : -(0.5-pow));
		long long sign = p < 0 ? MINUS64 : ZERO64;
		long long mask = ((abs(p) | sign)<<(6*(var%10)));
		if (var >= 10) {
			var_mask[1] |= mask;
		} else {
			var_mask[0] |= mask;
		}
	};

	inline long long is_mask(int var) {
		return var_mask[var/10] & (FULL64<<(6*(var%10)));
	};

	inline void VarMask::clear(int var) {
		var_mask[var/10] &= ~(FULL64<<(6*(var%10)));
	};

	inline bool isDIV() const {
		return var_mask[0] < 0 && var_mask[1] < 0;
	};
};

class ITEM {
public:
	virtual ~ITEM() {
	};

	virtual ITEM * clone() = 0;
	
	virtual bool IsZero() = 0;
	virtual bool IsOne() = 0;

	virtual void sprint(char ** Vars, char * Buf) = 0;

	virtual VarMask get_mask(long double pow, int var) {
		VarMask result;
		long long p = (long long)(pow >= 0.0 ? 0.5+pow : -(0.5-pow));
		long long sign = p < 0 ? MINUS64 : ZERO64;
		long long mask = ((abs(p) | sign)<<(6*(var%10)));
		if (var >= 10) {
			result.var_mask[0] = ZERO64;
			result.var_mask[1] = mask;
		} else {
			result.var_mask[0] = mask;
			result.var_mask[1] = ZERO64;
		}
		return result;
	};

	virtual void CHECK_VARS(long long &used_mask, int first_sqrt_var, char ** Vars, map<string, ITEM *> &SUBSTS) = 0;
};

class MUL;
class DIV;

class SUMMAND: public ITEM {
public:
	VarMask var_mask;

	virtual ~SUMMAND() {
	};

	virtual void Mul(MUL * &S) = 0;
	virtual void Mul(DIV * &D) = 0;
	virtual bool TryAdd(SUMMAND * &S) = 0;
	virtual bool IsEqual(bool UseK, SUMMAND * S) = 0;
};

class SUM: public ITEM {
public:
	map<VarMask, SUMMAND *> summands;

	SUM();
	SUM(long double k);
	SUM(MUL * &S);
	SUM(int var_idx, int n, long double * KF, long double kpow = 1.0);
	SUM(int var_idx, int sqrt_idx, int n, long double * KF, long double kpow = 1.0);

	virtual ~SUM();

	virtual ITEM * clone();

	void SETPOLY(SUM * &ARG, int n, long double * KF, const bool reversed = false);
	void SETPOLYSQR(SUM * &ARG, int sqrt_var, int n, long double * KF, const bool reversed);

	void Add(SUMMAND * &Item, bool account_similars = true);
	void Add(SUM * &S, bool account_similars = true);

	void Mul(SUMMAND * &S);
	void Mul(SUM * &S);
	void Mul(long double k);

	void AccountSimilars();

	bool IsEqual(bool UseK, SUM * S);
	virtual bool IsZero();
	virtual bool IsOne();

	virtual void sprint(char ** Vars, char * Buf);

	virtual void CHECK_VARS(long long &used_mask, int first_sqrt_var, char ** Vars, map<string, ITEM *> &SUBSTS) {
		map<VarMask, SUMMAND *>::iterator it;
		for (it = summands.begin(); it != summands.end(); it++)
			it->second->CHECK_VARS(used_mask, first_sqrt_var, Vars, SUBSTS);
	}
};

class MUL: public SUMMAND {
public:
	long double card;
	vector<int> vars;
	vector<long double> pows;

	MUL(long double k);

	virtual ~MUL() {
		vars.clear();
		pows.clear();
	};

	virtual ITEM * clone();

	virtual void Mul(MUL * &S);
	virtual void Mul(DIV * &D);
	virtual void Mul(long double k);
	virtual void Mul(int var_idx, long double pow);

	virtual MUL * CheckDiv(MUL * S);

	virtual bool TryAdd(SUMMAND * &S);

	virtual bool IsEqual(bool UseK, SUMMAND * S);
	virtual bool IsZero();
	virtual bool IsOne();

	virtual void sprint(char ** Vars, char * Buf);

	virtual void CHECK_VARS(long long &used_mask, int first_sqrt_var, char ** Vars, map<string, ITEM *> &SUBSTS) {
		for (unsigned int i = 1; i < vars.size(); i++) {
			used_mask |= (ONE64<<vars[i]);
			if (vars[i] >= first_sqrt_var)
				SUBSTS[Vars[vars[i]]]->CHECK_VARS(used_mask, first_sqrt_var, Vars, SUBSTS);
		}
	}
};

class DIV: public SUMMAND {
public:
	SUM * dividend;
	SUM * divisor;

	DIV(long double k);
	DIV(MUL * &S);
	DIV(SUM * &div1, SUM * &div2);

	virtual ~DIV();

	virtual ITEM * clone();

	virtual void Mul(MUL * &S);
	virtual void Mul(DIV * &D);

	long double CARD(SUM * _rest);

	SUM * Divide();

	void AddToDividend(SUMMAND * dd);
	void AddToDivisor(SUMMAND * dd);

	virtual bool TryAdd(SUMMAND * &S);

	virtual bool IsEqual(bool UseK, SUMMAND * S);
	virtual bool IsZero();
	virtual bool IsOne();

	virtual void sprint(char ** Vars, char * Buf);

	virtual void CHECK_VARS(long long &used_mask, int first_sqrt_var, char ** Vars, map<string, ITEM *> &SUBSTS) {
		dividend->CHECK_VARS(used_mask, first_sqrt_var, Vars, SUBSTS);
		divisor->CHECK_VARS(used_mask, first_sqrt_var, Vars, SUBSTS);
	}
};

SUM::SUM() {
	SUM(0.0);
};

SUM::SUM(long double k) {
	SUMMAND * S = (SUMMAND *)(new MUL(k));
	summands[S->var_mask] = S;
};

SUM::SUM(MUL * &S) {
	summands[S->var_mask] = S;
	S = NULL;
};

SUM::SUM(int var_idx, int n, long double * KF, long double kpow) {
	if (n < 1) {
		SUMMAND * S = (SUMMAND *)(new MUL(0.0));
		summands[S->var_mask] = S;
		return;
	}
	for (int i = 0; i < n; i++) {
		SUMMAND * item = dynamic_cast<SUMMAND *>(new MUL(KF[i]));
		if (i > 0) ((MUL *)item)->Mul(var_idx, kpow*i);
		Add(item);
	}
};

SUM::SUM(int var_idx, int sqrt_idx, int n, long double * KF, long double kpow) {
	if (n < 1) {
		SUMMAND * S = (SUMMAND *)(new MUL(0.0));
		summands[S->var_mask] = S;
		return;
	}
	for (int i = 0; i < n; i++) {
		SUMMAND * item = dynamic_cast<SUMMAND *>(new MUL(KF[i]));
		if (i > 0)
			if (sqrt_idx >= 0) {
				if (i > 1) ((MUL *)item)->Mul(var_idx, kpow*floor(i/2.0));
				if (i % 2) ((MUL *)item)->Mul(sqrt_idx, kpow*0.5);
			} else {
				((MUL *)item)->Mul(sqrt_idx, kpow*0.5*i);
			}
		Add(item);
	}
};

SUM::~SUM() {
	map<VarMask, SUMMAND *>::iterator it;
	for (it = summands.begin(); it != summands.end(); it++)
		delete it->second;
};

ITEM * SUM::clone() {
	SUM * result = new SUM(0.0);
	map<VarMask, SUMMAND *>::iterator it;
	for (it = summands.begin(); it != summands.end(); it++) {
		SUMMAND * S = dynamic_cast<SUMMAND *>(it->second->clone());
		result->Add(S, false);
	}
	return result;
};

void SUM::SETPOLY(SUM * &ARG, int n, long double * KF, const bool reversed) {
	map<VarMask, SUMMAND *>::iterator it;
	for (it = summands.begin(); it != summands.end(); it++)
		delete it->second;
	summands.clear();
	SUMMAND * S = new MUL(0.0);
	summands[S->var_mask] = S;
	if (n < 1) {
		delete ARG;
		ARG = NULL;
		return;
	}
	SUM * POWARG = new SUM(1.0);
	for (int i = 0; i < n; i++) {
		SUM * _ARG = dynamic_cast<SUM *>(POWARG->clone());
		if (reversed && i>0) {
			SUM * _ARG0 = new SUM(KF[i]);
			SUMMAND * ARG0 = new DIV(_ARG0, _ARG);
			Add(ARG0, false);
		} else {
			_ARG->Mul(KF[i]);
			Add(_ARG, false);
		}
		AccountSimilars();
		SUM * ARG1 = dynamic_cast<SUM *>(ARG->clone());
		POWARG->Mul(ARG1);
		POWARG->AccountSimilars();
	}
	delete POWARG;
	delete ARG;
	ARG = NULL;
};

void SUM::SETPOLYSQR(SUM * &ARG, int sqrt_var, int n, long double * KF, const bool reversed) {
	map<VarMask, SUMMAND *>::iterator it;
	for (it = summands.begin(); it != summands.end(); it++)
		delete it->second;
	summands.clear();
	SUMMAND * S = new MUL(0.0);
	summands[S->var_mask] = S;
	if (n < 1) {
		delete ARG;
		ARG = NULL;
		return;
	}
	SUM * POWARG = new SUM(1.0);
	for (int i = 0; i < n; i++) {
		SUM * _ARG = dynamic_cast<SUM *>(POWARG->clone());
		SUMMAND * zARG = new MUL(1.0);
		if (i % 2)
			((MUL *)zARG)->Mul(sqrt_var, (i+1)/2.0);
		_ARG->Mul(zARG);
		if (reversed && i>0) {
			SUM * _ARG0 = new SUM(KF[i]);
			SUMMAND * ARG0 = new DIV(_ARG0, _ARG);
			Add(ARG0, false);
		} else {
			_ARG->Mul(KF[i]);
			Add(_ARG, false);
		}
		AccountSimilars();
		if (i % 2) {
			SUM * ARG1 = dynamic_cast<SUM *>(ARG->clone());
			POWARG->Mul(ARG1);
			POWARG->AccountSimilars();
		}
	}
	delete POWARG;
	delete ARG;
	ARG = NULL;
};

void SUM::Add(SUMMAND * &Item, bool account_similars) {
	if (Item->IsZero()) {
		delete Item;
		Item = NULL;
		return;
	}
	if (summands.size() == 1 && summands.begin()->second->IsZero()) {
		delete summands.begin()->second;
		summands.clear();
		summands[Item->var_mask] = Item;
		Item = NULL;
		return;
	}
	map<VarMask, SUMMAND *>::iterator it = summands.find(Item->var_mask);
	if (it != summands.end()) {
		if (it->second->TryAdd(Item)) {
			if (it->second->IsZero()) {
				delete it->second;
				summands.erase(it);
			}
			if (summands.size() == 0) {
				SUMMAND * S = new MUL(0.0);
				summands[S->var_mask] = S;
			}
			return;
		}
	}
	summands[Item->var_mask] = Item;
};

void SUM::Add(SUM * &S, bool account_similars) {
	map<VarMask, SUMMAND *>::iterator it;
	for (it = S->summands.begin(); it != S->summands.end(); it++)
		Add(it->second, false);
	if (account_similars)
		AccountSimilars();
	S->summands.clear();
	delete S;
	S = NULL;
};

void SUM::Mul(SUMMAND * &S) {
	MUL * SS = dynamic_cast<MUL *>(S);
	DIV * DD = dynamic_cast<DIV *>(S);
	map<VarMask, SUMMAND *>::iterator it;
	if (SS) {
		vector<SUMMAND *> buf;
		for (it = summands.begin(); it != summands.end(); it++) {
			MUL * op = dynamic_cast<MUL *>(SS->clone());
			it->second->Mul(op);
			if (!SS->var_mask.IsZero()) buf.push_back(it->second);
		}
		if (!SS->var_mask.IsZero()) {
			summands.clear();
			while (buf.size() > 0) {
				unsigned int i = (unsigned int)(1.0*(buf.size()-1)*rand()/RAND_MAX);
// Здесь, возможно, следует поставить проверку, что слагаемое с такой маской уже существует. Тогда сложить их.
				summands[buf[i]->var_mask] = buf[i];
				buf.erase(buf.begin()+i);
			}
		}
	} else if (DD) {
		Mul(DD->dividend);
		SUM * op1 = dynamic_cast<SUM *>(this->clone());
		DIV * op = new DIV(op1, DD->divisor);

		for (it = summands.begin(); it != summands.end(); it++) {
			delete it->second;
		}
		summands.clear();
		summands[op->var_mask] = op;
	} else
		THROW_EXCEPTION("Unknown summand type in MULTIPLY");
	delete S;
	S = NULL;
};

void SUM::Mul(SUM * &S) {
	SUM * op1 = dynamic_cast<SUM *>(clone());
	map<VarMask, SUMMAND *>::iterator it = S->summands.begin();
	Mul(it->second);
	for (it++; it != S->summands.end(); it++) {
		SUM * multiplied = dynamic_cast<SUM *>(op1->clone());
		multiplied->Mul(it->second);
		Add(multiplied, false);
	}
	AccountSimilars();
	delete op1;
	delete S;
	S = NULL;
};

void SUM::Mul(long double k) {
	map<VarMask, SUMMAND *>::iterator it;
	if (fabs(k)<1E-9) {
		for (it = summands.begin(); it != summands.end(); it++)
			delete it->second;
		summands.clear();
		SUMMAND * S = new MUL(0.0);
		summands[S->var_mask] = S;
		return;
	}
	for (it = summands.begin(); it != summands.end(); it++) {
		MUL * SS = dynamic_cast<MUL *>(it->second);
		DIV * DD = dynamic_cast<DIV *>(it->second);
		if (SS)
			SS->Mul(k);
		else if (DD)
			DD->dividend->Mul(k);
	}
};

void SUM::AccountSimilars() {
	map<VarMask, SUMMAND *>::iterator it;
	for (it = summands.begin(); it != summands.end(); ) {
		DIV * DD = dynamic_cast<DIV *>(it->second);
		if (DD) {
			DD->dividend->AccountSimilars();
			DD->divisor->AccountSimilars();
		}
		if (it->second->IsZero()) {
			delete it->second;
			summands.erase(it++);
		} else
			it++;
	}
	if (summands.size() == 0) {
		SUMMAND * S = new MUL(0.0);
		summands[S->var_mask] = S;
	}
};

bool SUM::IsEqual(bool UseK, SUM * S) {
	if (summands.size() != S->summands.size())
		return false;
	map<VarMask, SUMMAND *>::iterator it1;
	map<VarMask, SUMMAND *>::iterator it2;
	for (it1 = summands.begin(), it2 = S->summands.begin(); it1 != summands.end(); it1++, it2++)
		if (it1->first != it2->first)
			return false;
	for (it1 = summands.begin(), it2 = S->summands.begin(); it1 != summands.end(); it1++, it2++) {
		if (!it1->second->IsEqual(UseK, it2->second)) {
			return false;
		}
	}
	return true;
};

bool SUM::IsZero() {
	return summands.size()==1 && summands.begin()->second->IsZero();
};

bool SUM::IsOne() {
	return summands.size()==1 && summands.begin()->second->IsOne();
};

void SUM::sprint(char ** Vars, char * Buf) {
	char * _Buf = new char[65536*4];
	map<VarMask, SUMMAND *>::iterator it;
	map<VarMask, SUMMAND *>::iterator it_last = summands.end();
	if (summands.size() > 0) it_last--;
	for (it = summands.begin(); it != summands.end(); it++) {
		_Buf[0] = 0x0;
		it->second->sprint(Vars, _Buf);

		if (it != it_last) _strcat(_Buf, 65536*4, "+");
		if (it != summands.begin() && _Buf[0] == '-')
			Buf[strlen(Buf)-1] = 0x0;
		_strcat(Buf, 65536*4, _Buf);
	}
	delete _Buf;
};

MUL::MUL(long double k): SUMMAND() {
	vars.push_back(-1);
	pows.push_back(k);
	card = 0;
	var_mask.clear();
};

ITEM * MUL::clone() {
	MUL * result = new MUL(0.0);
	result->vars.clear();
	result->vars.assign(vars.begin(), vars.end());
	result->pows.clear();
	result->pows.assign(pows.begin(), pows.end());
	result->card = card;
	result->var_mask = var_mask;
	return result;
};

void MUL::Mul(MUL * &S) {
	pows[0] *= S->pows[0];
	if (fabs(pows[0])<1e-9) {
		pows.erase(pows.begin()+1, pows.end());
		vars.erase(vars.begin()+1, vars.end());
		pows[0] = 0.0;
		card = 0;
		var_mask.clear();
		delete S;
		S = NULL;
		return;
	}
	for (unsigned int i = 1; i < S->vars.size(); i++) {
		int found = -1;
		for (unsigned int j = 1; found<0 && j < vars.size(); j++)
			if (S->vars[i] == vars[j])
				found = j;
		if (found >= 0) {
			pows[found] += S->pows[i];
			card += S->pows[i];
			var_mask.clear(S->vars[i]);
			if (fabs(pows[found])<1e-9) {
				pows.erase(pows.begin()+found);
				vars.erase(vars.begin()+found);
			} else {
				var_mask.set_mask(pows[found], S->vars[i]);;
			}
		} else {
			vars.push_back(S->vars[i]);
			pows.push_back(S->pows[i]);
			card += S->pows[i];
			var_mask.clear(S->vars[i]);
			var_mask.set_mask(S->pows[i], S->vars[i]);
		}
	}
	delete S;
	S = NULL;
};

void MUL::Mul(DIV * &D) {
	THROW_EXCEPTION("MUL*DIV can't be performed");
};

void MUL::Mul(long double k) {
	pows[0] *= k;
	if (fabs(pows[0])<1e-9) {
		vars.erase(vars.begin()+1, vars.end());
		pows.erase(pows.begin()+1, pows.end());
		card = 0;
		var_mask.clear();
	}
};

void MUL::Mul(int var_idx, long double pow) {
	if (var_idx < 0)
		Mul(pow);
	else {
		for (unsigned int i = 1; i < vars.size(); i++)
			if (vars[i] == var_idx) {
				pows[i] += pow;
				card += pow;
				var_mask.clear(var_idx);
				if (fabs(pows[i]) < 1e-9) {
					vars.erase(vars.begin()+i);
					pows.erase(pows.begin()+i);
				} else {
					var_mask.set_mask(pows[i], var_idx);
				}
				return;
			}
		vars.push_back(var_idx);
		pows.push_back(pow);
		card += pow;
		var_mask.clear(var_idx);
		var_mask.set_mask(pow, var_idx);
	}
};

MUL * MUL::CheckDiv(MUL * S) {
	MUL * result = new MUL(pows[0]/S->pows[0]);
	vector<unsigned int> rest_vars;
	for (unsigned int j = 1; j < vars.size(); j++)
		rest_vars.push_back(j);
	for (unsigned int i = 1; i < S->vars.size(); i++) {
		bool found = false;
		if (var_mask.is_mask(S->vars[i])) {
			for (unsigned int j = 0; !found && j < rest_vars.size(); j++)
				if (S->vars[i] == vars[rest_vars[j]]) {
					long double rest_pow = pows[rest_vars[j]]-S->pows[i];
					if (fabs(rest_pow) > 1e-9) {
						result->vars.push_back(vars[rest_vars[j]]);
						result->pows.push_back(rest_pow);
						result->card += rest_pow;
						result->var_mask.clear(vars[rest_vars[j]]);
						result->var_mask.set_mask(rest_pow, vars[rest_vars[j]]);
					}
					rest_vars.erase(rest_vars.begin()+j);
					found = true;
				}
		}
		if (!found) {
			delete result;
			return NULL;
		}
	}
	for (unsigned int j = 0; j < rest_vars.size(); j++) {
		result->vars.push_back(vars[rest_vars[j]]);
		result->pows.push_back(pows[rest_vars[j]]);
		result->card += pows[rest_vars[j]];
		result->var_mask.clear(vars[rest_vars[j]]);
		result->var_mask.set_mask(pows[rest_vars[j]], vars[rest_vars[j]]);
	}
	return result;
};

bool MUL::TryAdd(SUMMAND * &S) {
	MUL * SS = dynamic_cast<MUL *>(S);
	if (!SS)
		return false;
	if (S->IsZero()) {
		delete S;
		S = NULL;
		return true;
	}
	if (IsZero()) {
		vars.clear();
		pows.clear();
		vars.assign(SS->vars.begin(), SS->vars.end());
		pows.assign(SS->pows.begin(), SS->pows.end());
		card = SS->card;
		var_mask = SS->var_mask;
		delete S;
		S = NULL;
		return true;
	}
	if (!IsEqual(false, SS))
		return false;
	pows[0] += SS->pows[0];
	delete S;
	S = NULL;
	return true;
};

bool MUL::IsEqual(bool UseK, SUMMAND * S) {
	MUL * SS = dynamic_cast<MUL *>(S);
	DIV * DD = dynamic_cast<DIV *>(S);
	if (SS) {
		if (vars.size() != SS->vars.size())
			return false;
		if (UseK && fabs(pows[0]-SS->pows[0])>1e-9)
			return false;
		if (fabs(card-SS->card)>1E-9 || var_mask != SS->var_mask)
			return false;
/*
		vector<unsigned int> not_seen;
		for (unsigned int j = 1; j < SS->vars.size(); j++)
			not_seen.push_back(j);
		for (unsigned int i = 1; i < vars.size(); i++) {
			bool found = false;
			if (SS->var_mask.is_mask(vars[i])) {
				for (unsigned int j = 0; !found && j < not_seen.size(); j++)
					if (vars[i] == SS->vars[not_seen[j]] && fabs(pows[i]-SS->pows[not_seen[j]])<1e-9) {
						not_seen.erase(not_seen.begin()+j);
						found = true;
					}
			}
			if (!found)
				return false;
		}
*/
		return true;
	}
	if (DD) {
		MUL * SS1 = dynamic_cast<MUL *>(this->clone());
		DIV * D = new DIV(SS1);
		bool result = D->IsEqual(true, DD);
		delete SS1;
		delete D;
		return result;
	}
	return false;
};

bool MUL::IsZero() {
	bool result = vars.size()>0 && vars[0]<0 && fabs(pows[0])<1e-9;
	if (result) {
		vars.erase(vars.begin()+1, vars.end());
		pows.erase(pows.begin()+1, pows.end());
		card = 0;
		var_mask.clear();
	}
	return result;
};

bool MUL::IsOne() {
	bool result = vars.size()>0 && vars[0]<0 && fabs(1.0-pows[0])<1e-9;
	if (result) {
		for (unsigned int i = 1; i < pows.size(); i++)
			if (fabs(pows[i]) >= 1e-9)
				return false;
		vars.erase(vars.begin()+1, vars.end());
		pows.erase(pows.begin()+1, pows.end());
		card = 0;
		var_mask.clear();
	}
	return result;
};

void STRIP(char * _Buf) {
	int j = strlen(_Buf)-1;
	while (j >= 0 && _Buf[j] == '0') j--;
	if (j >= 0 && _Buf[j] == '.') j--;
	_Buf[j+1] = 0x0;
};

void ESTRIP(char * _Buf) {
	int e = strcspn(_Buf, "Ee");
	int j = e-1;
	while (j >= 0 && _Buf[j] == '0') j--;
	if (j >= 0 && _Buf[j] == '.') j--;
	j++;
	while (_Buf[j++] = _Buf[e++]);
};

void MUL::sprint(char ** Vars, char * Buf) {
	char * _Buf = new char[16384];
	_Buf[0] = 0x0;
	for (unsigned int i = 0; i < vars.size(); i++) {
		bool print_star = i < vars.size()-1;

		if (vars[i] < 0) {
			if (fabs(1.0-pows[i]) > 1E-9)
				if (fabs(-1.0-pows[i]) < 1E-9) {
					_strcat(Buf, 65536*16, "-");
					print_star = false;
				} else {
					_sprintf1(_Buf, 16384, "%Le", pows[i]);
					ESTRIP(_Buf);
					_strcat(Buf, 65536*16, _Buf);
				}
			else {
				print_star = false;
			}
		} else {
			if (fabs(1.0-pows[i]) > 1E-9) {
				_strcat(Buf, 65536*16, "pow(");
				_strcat(Buf, 65536*16, Vars[vars[i]]);
				char Num[32] = "";
				_sprintf1(Num, 32, "%Lf", pows[i]);
				STRIP(Num);
				if (pows[i] >= 0.0)
					_sprintf1(_Buf, 16384, ",%s)", Num);
				else
					_sprintf1(_Buf, 16384, ",(%s))", Num);
				_strcat(Buf, 65536*16, _Buf);
			} else
				_strcat(Buf, 65536*16, Vars[vars[i]]);
		}
		if (print_star) _strcat(Buf, 65536*16, "*");
	}
	delete _Buf;
};

DIV::DIV(long double k): SUMMAND() {
	dividend = new SUM(k);
	divisor = new SUM(1.0);
	var_mask.setDIV();
};

DIV::DIV(MUL * &S) {
	dividend = new SUM(S);
	divisor = new SUM(1.0);
	var_mask.setDIV();
};

DIV::DIV(SUM * &div1, SUM * &div2) {
	dividend = div1; div1 = NULL;
	divisor  = div2; div2 = NULL;
	var_mask.setDIV();
}

DIV::~DIV() {
	delete dividend;
	delete divisor;
}

ITEM * DIV::clone() {
	SUM * S1 = (SUM *)dividend->clone();
	SUM * S2 = (SUM *)divisor->clone();
	return new DIV(S1, S2);
};

void DIV::Mul(MUL * &S) {
	SUMMAND * SS = dynamic_cast<SUMMAND *>(S);
	dividend->Mul(SS);
	S = dynamic_cast<MUL *>(SS);
};

void DIV::Mul(DIV * &D) {
	dividend->Mul(D->dividend);
	divisor->Mul(D->divisor);
	delete D;
	D = NULL;
};

long double DIV::CARD(SUM * _rest) {
	long double result = _rest->summands.size();
	map<VarMask, SUMMAND *>::iterator it;
	long double max_card = -1E300;
	long double sum_cards = 0.0;
	for (it = _rest->summands.begin(); it != _rest->summands.end(); it++) {
		MUL * SS = dynamic_cast<MUL *>(it->second);
		if (!SS)
			THROW_EXCEPTION("Expression is irregular: is not a pure dividend/divisor. REGULARIZE needed");
		if (SS->card > max_card) {
			max_card = SS->card;
			sum_cards = SS->card;
		} else if (fabs(SS->card - max_card) < 1E-9)
			sum_cards += max_card;
		else
			sum_cards += 0.0001*fabs(SS->card);
	}
	return result + sum_cards;
};

SUM * DIV::Divide() {
	SUM * result = new SUM(0.0);
	dividend->AccountSimilars();
	divisor->AccountSimilars();

	int NPP = NPROCS;

	const long double max_gap = 31;
	const long double min_gap = 0;
	const long double std_time = 5.0/divisor->summands.size();

	bool success = false;
	long double super_card = 1E300;
	long double gap = min_gap + (max_gap-min_gap)/4.0;
	do {
		long double _best_rest_card[256];
		SUM * _best_rest[256];
		MUL * _best_quot[256];
		long double _gap[256];
		for (int i = 0; i < NPP; i++) {
			_best_rest_card[i] = 1E300;
			_best_rest[i] = NULL;
			_best_quot[i] = NULL;
			_gap[i] = gap;
		}
		vector<map<VarMask, SUMMAND *>::iterator> it_divisors(divisor->summands.size());
		map<VarMask, SUMMAND *>::iterator it_divisor;
		int ii = 0;
		for (it_divisor = divisor->summands.begin(); it_divisor != divisor->summands.end(); it_divisor++, ii++) {
			it_divisors[ii] = it_divisor;
		}

		#pragma omp parallel for schedule(guided) if(NPP-(int)(NPP*TASK_PART) > 1) num_threads(NPP-(int)(NPP*TASK_PART))
		for (int w = 0; w < (int)it_divisors.size(); w++) {
			int ID = omp_get_thread_num();
			it_divisor = it_divisors[w];
			MUL * _divisor = dynamic_cast<MUL *>(it_divisor->second);
			if (!_divisor)
				THROW_EXCEPTION("DIVIDE POLY/POLY: divisor contains DIV");
			long double quot_card = -10000000.0;
			MUL * quot = NULL;
			SUM * rest = NULL;
			vector<MUL *> quots;
			double start_time = omp_get_wtime();
			map<VarMask, SUMMAND *>::iterator it_dividend;
			for (it_dividend = dividend->summands.begin(); it_dividend != dividend->summands.end(); it_dividend++) {
				MUL * _dividend = dynamic_cast<MUL *>(it_dividend->second);
				if (!_dividend)
					THROW_EXCEPTION("DIVIDE POLY/POLY: dividend contains DIV");
				MUL * _quotient = _dividend->CheckDiv(_divisor);
				if (_quotient && _quotient->card >= quot_card-_gap[ID]) {
					if (_quotient->card > quot_card+_gap[ID]) {
						for (unsigned int jj = 0; jj < quots.size(); jj++)
							delete quots[jj];
						quots.clear();
						quot_card = _quotient->card;
					}
					quots.push_back(_quotient);
				} else
					delete _quotient;
			}
			long double rest_card = 1E300;
			if (quots.size()) {
				for (unsigned int jj = 0; jj < quots.size(); jj++) {
					SUM * _rest = dynamic_cast<SUM *>(dividend->clone());
					map<VarMask, SUMMAND *>::iterator it_k;
					for (it_k = divisor->summands.begin(); it_k != divisor->summands.end(); it_k++) {
						MUL * item1 = dynamic_cast<MUL *>(quots[jj]->clone());
						MUL * item2 = dynamic_cast<MUL *>(it_k->second->clone());
						if (!item2)
							THROW_EXCEPTION("DIVIDE POLY/POLY: divisor contains DIV");
						item1->Mul(item2);
						item1->Mul(-1.0);
						SUMMAND * _item1 = dynamic_cast<SUMMAND *>(item1);
						_rest->Add(_item1);
					}
					_rest->AccountSimilars();
					long double _rest_card = CARD(_rest);
					if (_rest_card < rest_card) {
						rest_card = _rest_card;
						delete quot;
						quot = quots[jj];
						delete rest;
						rest = _rest;
					} else {
						delete quots[jj];
						quots[jj] = NULL;
						delete _rest;
					}
				}
			}
			if (rest_card < _best_rest_card[ID]) {
				_best_rest_card[ID] = rest_card;
				delete _best_rest[ID];
				_best_rest[ID] = rest;
				delete _best_quot[ID];
				_best_quot[ID] = quot;
			}
			double time = omp_get_wtime() - start_time;
			if (time < std_time) {
				if (_gap[ID] < max_gap)
					_gap[ID]++;
			} else if (time > std_time) {
				if (_gap[ID] > min_gap)
					_gap[ID]--;
			}
		}
		long double best_rest_card = _best_rest_card[0];
		SUM * best_rest = _best_rest[0];
		MUL * best_quot = _best_quot[0];
		gap = _gap[0];
		for (int i = 1; i < NPP; i++) {
			if (_best_rest_card[i] < best_rest_card) {
				best_rest_card = _best_rest_card[i];
				delete best_rest;
				best_rest = _best_rest[i];
				delete best_quot;
				best_quot = _best_quot[i];
			} else {
				delete _best_rest[i];
				delete _best_quot[i];
			}
			if (gap > _gap[i])
				gap = _gap[i];
		}
		long double divid_card = CARD(dividend);
		success = best_rest_card < super_card && best_rest_card < divid_card && CARD(divisor) < divid_card;
		if (success) {
			delete dividend;
			dividend = best_rest;
			SUMMAND * _quot = dynamic_cast<SUMMAND *>(best_quot);
			result->Add(_quot);
			super_card = best_rest_card;
		} else {
			SUMMAND * div = dynamic_cast<SUMMAND *>(this->clone());
			result->Add(div);
			delete best_rest;
			delete best_quot;
		}
	} while (success && !dividend->IsZero());
	delete this;
	return result;
};

void DIV::AddToDividend(SUMMAND * dd) {
	dividend->Add(dd);
};

void DIV::AddToDivisor(SUMMAND * dd) {
	divisor->Add(dd);
};

bool DIV::TryAdd(SUMMAND * &S) {
	// add to dividend/divisor
	DIV * DD = dynamic_cast<DIV *>(S);
	MUL * SS = dynamic_cast<MUL *>(S);
	bool result = false;
	if (SS) {
		SUMMAND * _DD = dynamic_cast<SUMMAND *>(new DIV(SS));
		S = SS;
		result = TryAdd(_DD);
		delete S;
		S = NULL;
		return true;
	}
	if (divisor->IsEqual(true, DD->divisor)) {
		dividend->Add(DD->dividend);
		result = true;
	} else {
		SUM * _divisor1 = dynamic_cast<SUM *>(DD->divisor->clone());
		SUM * __divisor1 = dynamic_cast<SUM *>(DD->divisor->clone());
		SUM * _divisor2 = dynamic_cast<SUM *>(divisor->clone());
//		SUM * __divisor2 = dynamic_cast<SUM *>(divisor->clone());
		dividend->Mul(_divisor1);
		divisor->Mul(__divisor1);
		DD->dividend->Mul(_divisor2);
//		DD->divisor->Mul(__divisor2);
		DIV * _DD = DD;
		dividend->Add(_DD->dividend);
		delete _DD;
		_DD = NULL;
		result = true;
		if (DD == S) S = _DD;
	}
	if (result) {
		delete S;
		S = NULL;
	}
	return result;
};

bool DIV::IsEqual(bool UseK, SUMMAND * S) {
	MUL * SS = dynamic_cast<MUL *>(S);
	DIV * DD = dynamic_cast<DIV *>(S);
	if (DD) {
		return dividend->IsEqual(UseK, DD->dividend) && divisor->IsEqual(UseK, DD->divisor);
	} else if (SS) {
		DIV * D = new DIV(SS);
		bool result = IsEqual(UseK, D);
		delete D;
		return result;
	}
	return false;
};

bool DIV::IsZero() {
	return dividend->IsZero();
};

bool DIV::IsOne() {
	return dividend->IsOne() && divisor->IsOne();
};

void DIV::sprint(char ** Vars, char * Buf) {
	_strcat(Buf, 65536*16, "(");
	dividend->sprint(Vars, Buf);
	_strcat(Buf, 65536*16, ")/(");
	divisor->sprint(Vars, Buf);
	_strcat(Buf, 65536*16, ")");
};

ITEM * REGULARIZE(ITEM * &SRC) {
	MUL * SS = dynamic_cast<MUL *>(SRC);
	DIV * DD = dynamic_cast<DIV *>(SRC);
	SUM * PP = dynamic_cast<SUM *>(SRC);
	if (SS) return SS;
	if (PP) {
		// simplify members and find dividend/divider
		VarMask _DIV = {-ONE64, -ONE64};
		map<VarMask, SUMMAND *>::iterator first_rel_it = PP->summands.find(_DIV);
		DIV * first_rel = first_rel_it == PP->summands.end() ? NULL : dynamic_cast<DIV *>(first_rel_it->second);
		map<VarMask, SUMMAND *>::iterator it;
		for (it = PP->summands.begin(); it != PP->summands.end(); ) {
			ITEM * SMND = dynamic_cast<ITEM *>(it->second);
			it->second = dynamic_cast<SUMMAND *>(REGULARIZE(SMND));
			if (it->second) {
				it++;
			} else {
				PP->summands.erase(it++);
			}
		}
		// add others summands to dividend/divider
		if (first_rel_it != PP->summands.end() && PP->summands.size() > 1) {
			it = PP->summands.begin();
			it++;
			while (it != PP->summands.end()) {
				first_rel_it->second->TryAdd(it->second);
				if (it->second)
					it++;
				else
					PP->summands.erase(it++);
			}
		}
		// account similar members
		PP->AccountSimilars();
		return PP;
	}
	if (DD) {
		ITEM * dd = dynamic_cast<ITEM *>(DD->dividend);
		DD->dividend = (SUM *)REGULARIZE(dd);
		ITEM * dr = dynamic_cast<ITEM *>(DD->divisor);
		DD->divisor = (SUM *)REGULARIZE(dr);
		if (DD->dividend->summands.size()==1 && DD->divisor->summands.size()>0 ||
			DD->divisor->summands.size()==1 && DD->dividend->summands.size()>0) {
			DIV * dop1 = DD->dividend->summands.size()==1 ? dynamic_cast<DIV *>(DD->dividend->summands.begin()->second) : NULL;
			DIV * dop2 = DD->divisor->summands.size()==1 ? dynamic_cast<DIV *>(DD->divisor->summands.begin()->second) : NULL;
			if (!dop1 && dop2) {
				// sum/[dividend/divisor]
				DD->dividend->Mul(dop2->divisor);
				SUM * oldDivisor = DD->divisor;
				DD->divisor = dop2->dividend;
				dop2->dividend = NULL;
				delete oldDivisor;
			}
			if (dop1 && !dop2) {
				// [dividend/divisor]/sum
				dop1->divisor->Mul(DD->divisor);
				DD->divisor = dop1->divisor;
				dop1->divisor = NULL;
				SUM * oldDividend = DD->dividend;
				DD->dividend = dop1->dividend;
				dop1->dividend = NULL;
				delete oldDividend;
			}
			if (dop1 && dop2) {
				// [dividend/divisor]/[dividend/divisor]
				dop1->dividend->Mul(dop2->divisor);
				dop1->divisor->Mul(dop2->dividend);
				delete DD->divisor;
				DD->divisor = dop1->divisor;
				dop1->divisor = NULL;
				SUM * oldDividend = DD->dividend;
				DD->dividend = dop1->dividend;
				dop1->dividend = NULL;
				delete oldDividend;
			}
		}
		return DD;
	}
	return NULL;
}

ITEM * SIMPLIFY(ITEM * &SRC) {
	ITEM * S = REGULARIZE(SRC);
	ITEM * _S = S;
	DIV * D = dynamic_cast<DIV *>(S);
	if (D)
		_S = D->Divide();
	else {
		SUM * SS = dynamic_cast<SUM *>(S);
		if (SS && SS->summands.size() == 1 && SS->summands.begin()->first.isDIV()) {
			D = dynamic_cast<DIV *>(SS->summands.begin()->second);
			SS->summands.clear();
			delete SS;
			S = NULL;
			_S = D->Divide();
		}
	}
	return _S;
}

ITEM * SUBSTITUTE_SQRS(ITEM * &SRC, int first_sqrt_var, char ** Vars, map<string, ITEM *> &SUBSTS) {
	MUL * SS = dynamic_cast<MUL *>(SRC);
	DIV * DD = dynamic_cast<DIV *>(SRC);
	SUM * PP = dynamic_cast<SUM *>(SRC);
	if (SS) {
		for (unsigned int i = 1; i < SS->vars.size(); i++) {
			if (SS->vars[i] >= first_sqrt_var &&
				fabs(1.0-SS->pows[i]) > 1E-9 && fabs(-1.0-SS->pows[i]) > 1E-9) {
				SUM * Z2 = dynamic_cast<SUM *>(SUBSTS[Vars[SS->vars[i]]]->clone());
				SUM * mult = dynamic_cast<SUM *>(Z2->clone());
				MUL * NEW = dynamic_cast<MUL *>(SRC->clone());
				NEW->var_mask.clear(SS->vars[i]);
				int p = (int)(SS->pows[i] >= 0.0 ? 0.5+SS->pows[i] : -(0.5-SS->pows[i]));
				if (abs(p)%2) {
					NEW->var_mask.set_mask(1.0, SS->vars[i]);
					NEW->pows[i] = p > 0 ? 1.0 : -1.0;
				} else {
					NEW->vars.erase(NEW->vars.begin()+i);
					NEW->pows.erase(NEW->pows.begin()+i);
				}
				p /= 2;
				int _p = abs(p);
				while (--_p) {
					SUM * _mult = dynamic_cast<SUM *>(mult->clone());
					Z2->Mul(_mult);
				}
				delete mult;
				SUMMAND * __NEW = dynamic_cast<SUMMAND *>(NEW);
				if (p < 0) {
					DIV * D = new DIV(1.0);
					delete D->divisor;
					Z2->AccountSimilars();
					D->divisor = Z2;
					D->Mul(NEW);
					Z2 = new SUM(0.0);
					SUMMAND * _D = dynamic_cast<SUMMAND *>(D);
					Z2->Add(_D, true);
				} else {
					Z2->Mul(__NEW);
					Z2->AccountSimilars();
				}

				delete SRC;
				SRC = NULL;
				ITEM * _Z2 = dynamic_cast<ITEM *>(Z2);
				return SUBSTITUTE_SQRS(_Z2, first_sqrt_var, Vars, SUBSTS);
			}
		}
		ITEM * result = SRC;
		SRC = NULL;
		return result;
	} else if (PP) {
		map<VarMask, SUMMAND *>::iterator it;
		vector<ITEM *> modified;
		vector<ITEM *>::iterator it_modified;
		for (it = PP->summands.begin(); it != PP->summands.end(); ) {
			ITEM * ARG = dynamic_cast<ITEM *>(it->second);
			ITEM * item = SUBSTITUTE_SQRS(ARG, first_sqrt_var, Vars, SUBSTS);
			if (item != it->second) {
				modified.push_back(item);
				PP->summands.erase(it++);
			} else {
				it++;
			}
		}
		for (it_modified = modified.begin(); it_modified != modified.end(); it_modified++) {
			SUMMAND * _SS = dynamic_cast<SUMMAND *>(*it_modified);
			SUM * _PP = dynamic_cast<SUM *>(*it_modified);
			if (_SS)
				PP->Add(_SS);
			else if (_PP)
				PP->Add(_PP, false);
		}
		PP->AccountSimilars();
		SRC = NULL;
		return PP;
	} else if (DD) {
		ITEM * _dividend = dynamic_cast<ITEM *>(DD->dividend);
		DD->dividend = (SUM *) SUBSTITUTE_SQRS(_dividend, first_sqrt_var, Vars, SUBSTS);
		ITEM * _divisor = dynamic_cast<ITEM *>(DD->divisor);
		DD->divisor = (SUM *) SUBSTITUTE_SQRS(_divisor, first_sqrt_var, Vars, SUBSTS);
		SRC = NULL;
		return DD;
	}
	return NULL;
}

bool PRESENT_SQRS(ITEM * SRC, int first_sqrt_var) {
	MUL * SS = dynamic_cast<MUL *>(SRC);
	DIV * DD = dynamic_cast<DIV *>(SRC);
	SUM * PP = dynamic_cast<SUM *>(SRC);
	if (SS) {
		for (unsigned int i = 1; i < SS->vars.size(); i++) {
			if (SS->vars[i] >= first_sqrt_var &&
				fabs(1.0-SS->pows[i]) > 1E-9 && fabs(-1.0-SS->pows[i]) > 1E-9) {
				return true;
			}
		}
		return false;
	} else if (PP) {
		map<VarMask, SUMMAND *>::iterator it;
		for (it = PP->summands.begin(); it != PP->summands.end(); it++) {
			ITEM * ARG = dynamic_cast<ITEM *>(it->second);
			if (PRESENT_SQRS(ARG, first_sqrt_var))
				return true;
		}
		return false;
	} else if (DD) {
		ITEM * _dividend = dynamic_cast<ITEM *>(DD->dividend);
		if (PRESENT_SQRS(_dividend, first_sqrt_var))
			return true;
		ITEM * _divisor = dynamic_cast<ITEM *>(DD->divisor);
		if (PRESENT_SQRS(_divisor, first_sqrt_var))
			return true;
		return false;
	}
	return false;
}

#endif

#ifndef __PROLOG_MICRO_BRAIN_H__
#define __PROLOG_MICRO_BRAIN_H__

#define _CRT_SECURE_NO_WARNINGS

#include <vector>
#include <string>
#include <set>
#include <thread>
#include <condition_variable>
#include <mutex>
#include <functional>
#include <algorithm>
#include <atomic>

#include <stdlib.h>
#include <time.h>

using namespace std;

#include "elements.h"

extern bool fast_memory_manager;
extern unsigned int mem_block_size;

extern const char * STD_INPUT;
extern const char * STD_OUTPUT;

const int once_flag = 0x1;
const int call_flag = 0x2;

unsigned long long getTotalSystemMemory();
unsigned int getTotalProcs();
void * __alloc(size_t size);
void __free(void * ptr);

#ifdef __linux__
#include <sys/resource.h>
#include <unistd.h>
#include <pthread.h>
#include <dlfcn.h>

typedef void * HMODULE;

HMODULE LoadLibrary(wchar_t * _fname) {
	return dlopen(wstring_to_utf8(_fname).c_str(), RTLD_LAZY);
}

void * GetProcAddress(HMODULE handle, char * fname) {
	return dlsym(handle, fname);
}

void FreeLibrary(HMODULE handle) {
	dlclose(handle);
}
#else
#include <Windows.h>
#endif

template<class T> class stack_container : public vector<T>{
public:
	virtual void push_back(const T & v) {
		if (this->capacity() == this->size())
			this->reserve((int)(1.5*this->size()));
		vector<T>::push_back(v);
	}

	virtual void push(const T & v) { this->push_back(v); }
	virtual void pop() { this->pop_back(); }
	virtual T top() { return this->back(); }
};

class interpreter;
class frame_item;
class thread_pool;
class predicate;
class clause;
class predicate_item;
class predicate_item_user;
class generated_vars;
class term;
class tthread;
class context;
class tframe_item;

class value {
protected:
	std::atomic<int> refs;
public:
	value() { refs = 1; }

	virtual void use() { refs++; }
	virtual void free() { refs--; if (refs == 0) delete this; }

	virtual int get_refs() { return refs; }

	virtual value* fill(context* CTX, frame_item* vars) = 0;
	virtual value* copy(context* CTX, frame_item* f, int unwind = 0) = 0;
	virtual value* const_copy(context* CTX, frame_item* f) {
		if (this->defined()) {
			this->use();
			return this;
		}
		else
			return copy(CTX, f);
	}
	virtual bool unify(context* CTX, frame_item* ff, value* from) = 0;
	virtual bool defined() = 0;

	virtual string to_str(bool simple = false) = 0;

	virtual void escape_vars(context* CTX, frame_item* ff) = 0;

	virtual string make_str() {
		return to_str();
	}

	virtual string export_str(bool simple = false, bool double_slashes = true) {
		return to_str();
	}

	virtual void write(basic_ostream<char>* outs, bool simple = false) {
		(*outs) << to_str(simple);
	}

	void* operator new (size_t size) {
		if (fast_memory_manager)
			return __alloc(size);
		else {
			void* ptr = ::operator new(size);
			//			cout<<"new:"<<ptr<<endl;
			return ptr;
		}
	}

	void operator delete (void* ptr) {
		//	cout << "del:" << ptr << endl;
		if (fast_memory_manager)
			__free(ptr);
		else
			::operator delete(ptr);
	}
};

typedef struct {
	char* _name;
	value* ptr;
} mapper;

class journal_item;
class journal;

typedef enum { jInsert = 0, jDelete } jTypes;

typedef enum { seqNone = 0, seqGenerated, seqStopped, seqTrue } seqModes;

class context {
public:
	context(bool locals_in_forked, bool transactable_facts, predicate_item* forker, int RESERVE, context* parent, tframe_item* tframe, predicate_item* starting, predicate_item* ending, interpreter* prolog);

	virtual void clearDBJournals();

	virtual ~context();

	bool forked() {
		context* C = this;
		while (C && !C->THR)
			C = C->parent;
		bool result = C && C->THR;
		return result;
	}

	virtual void set_rollback(bool val) {
		rollback = val;
	}

	context* parent;
	interpreter* prolog;
	predicate_item* forker;
	predicate_item* starting;
	predicate_item* ending;
	bool locals_in_forked;
	bool transactable_facts;
	bool rollback;

	stack_container<seqModes> SEQ_MODE;
	stack_container<frame_item*> SEQ_RESULT;
	stack_container<predicate_item*> GENERATORS;
	stack_container<predicate_item *> SEQ_START;
	stack_container<predicate_item*> SEQ_END;
	stack_container<tframe_item*> FRAMES_TO_DELETE;

	std::mutex * DBLOCK;
	map< string, std::atomic<vector<term*>*>> * DB;
	map<string, std::atomic<journal*>> * DBJournal;

	vector<context*> CONTEXTS;
	std::atomic<tframe_item*> INIT;
	std::atomic<tframe_item*> FRAME;
	tthread* THR;

	stack_container<predicate_item*> CALLS;
	stack_container<frame_item*> FRAMES;
	stack_container<context*> CTXS;
	stack_container<bool> NEGS;
	stack_container<int> _FLAGS;
	stack_container<predicate_item_user*> PARENT_CALLS;
	stack_container<int> PARENT_CALL_VARIANT;
	stack_container<clause*> CLAUSES;
	std::list<int> FLAGS;
	stack_container<int> LEVELS;
	stack_container<generated_vars*> TRACE;
	stack_container<vector<value*>**> TRACEARGS;
	stack_container<predicate_item*> TRACERS;
	stack_container<int> ptrTRACE;

	std::mutex pages_mutex;

	virtual context* add_page(bool locals_in_forked, bool transactable_facts, predicate_item * forker, tframe_item* f, predicate_item* starting, predicate_item* ending, interpreter* prolog);

	virtual void register_db_read(const std::string& iid);

	virtual void register_db_write(const std::string& iid, jTypes t, value* data, int position, journal * src = NULL);
	
	virtual bool join(bool sequential_mode, int K, frame_item* f, interpreter* INTRP);

	virtual void apply_transactional_db_to_parent(const std::string& fact);
};

class interpreter {
private:
	predicate_item_user * starter;
	HMODULE xpathInductLib;
	char env[65536 * 4];
	bool xpath_compiled;
	bool xpath_loaded;

	bool forking;
public:
	typedef enum {
		id_append = 0,
		id_sublist,
		id_delete,
		id_member,
		id_last,
		id_reverse,
		id_for,
		id_length,
		id_max_list,
		id_atom_length,
		id_nth,
		id_page_id,
		id_thread_id,
		id_atom_concat,
		id_atom_chars,
		id_atom_codes,
		id_atom_hex,
		id_atom_hexs,
		id_number_atom,
		id_number,
		id_consistency,
		id_listing,
		id_current_predicate,
		id_findall,
		id_functor,
		id_predicate_property,
		id_spredicate_property_pi,
		id_eq,
		id_neq,
		id_less,
		id_greater,
		id_term_split,
		id_g_assign,
		id_g_assign_nth,
		id_g_read,
		id_fail,
		id_true,
		id_change_directory,
		id_open,
		id_close,
		id_get_char,
		id_peek_char,
		id_read_token,
		id_read_token_from_atom,
		id_mars,
		id_mars_decode,
		id_unset,
		id_write,
		id_write_to_atom,
		id_write_term,
		id_write_term_to_atom,
		id_nl,
		id_file_exists,
		id_unlink,
		id_rename_file,
		id_seeing,
		id_telling,
		id_seen,
		id_told,
		id_see,
		id_tell,
		id_set_iteration_star_packet,
		id_repeat,
		id_random,
		id_randomize,
		id_char_code,
		id_get_code,
		id_at_end_of_stream,
		id_open_url,
		id_track_post,
		id_consult,
		id_assert,
		id_asserta,
		id_assertz,
		id_retract,
		id_retractall,
		id_inc,
		id_halt,
		id_load_classes,
		id_init_xpathing,
		id_induct_xpathing,
		id_import_model_after_induct,
		id_unload_classes,
		id_var,
		id_nonvar,
		id_get_icontacts,
		id_get_ocontacts,
		id_rollback
	} ids;

	thread_pool* THREAD_POOL;
	std::mutex VARLOCK;
	unsigned int ITERATION_STAR_PACKET;

	map<string, ids> MAP;

	string CLASSES_ROOT;
	string INDUCT_MODE;

	map<string, predicate *> PREDICATES;
	std::mutex GLOCK;
	map<string, value *> GVars;
	map<string, std::recursive_mutex *> STARLOCKS;
	std::recursive_mutex STARLOCK;

	map< string, set<int>*> DBIndicators;
	std::mutex DBILock;

	context* CONTEXT;

	string current_output;
	string current_input;
	string out_buf;

	basic_istream<char> * ins;
	basic_ostream<char> * outs;

	int file_num;
	map<int, std::basic_fstream<char> > files;

	interpreter(const string & fname, const string & starter_name);
	~interpreter();

	bool XPathCompiled() {
		return xpath_compiled;
	}
	bool XPathLoaded() {
		return xpath_loaded;
	}
	void SetXPathCompiled(bool v) {
		xpath_compiled = v;
	}
	void SetXPathLoaded(bool v) {
		xpath_loaded = v;
	}

	bool LoadXPathing() {
		bool result = false;
		if (!xpathInductLib) {
			xpathInductLib = LoadLibrary(
#ifdef __linux__
				L"./libxpathInduct.so"
#else
				L"xpathInduct.dll"
#endif
				);
			if (xpathInductLib) {
				XPathInduct = (XPathInductF)GetProcAddress(xpathInductLib, "XPathInduct");
				CompileXPathing = (CompileXPathingF)GetProcAddress(xpathInductLib, "CompileXPathing");
				SetInterval = (SetIntervalF)GetProcAddress(xpathInductLib, "SetInterval");
				ClearRestrictions = (ClearRestrictionsF)GetProcAddress(xpathInductLib, "ClearRestrictions");
				ClearRuler = (ClearRulerF)GetProcAddress(xpathInductLib, "ClearRuler");
				SetDeduceLogFile = (SetDeduceLogFileF)GetProcAddress(xpathInductLib, "SetDeduceLogFile");
				CreateDOMContact = (CreateDOMContactF)GetProcAddress(xpathInductLib, "CreateDOMContact");
				GetMSG = (GetMSGF)GetProcAddress(xpathInductLib, "GetMSG");
				result = true;
			}
		}
		return result;
	}

	void UnloadXPathing() {
		if (xpathInductLib)
			FreeLibrary(xpathInductLib);
		xpathInductLib = 0;
	}

	char * ENV() {
		return env;
	}

	string open_file(const string & fname, const string & mode);
	void close_file(const string & obj);
	std::basic_fstream<char> & get_file(const string & obj, int & fn);

	void block_process(context * CNT, bool clear_flag, bool cut_flag, predicate_item * frontier, bool frontier_enough = false);

	double evaluate(context* CTX, frame_item * ff, const string & expression, int & p);

	bool check_consistency(set<string> & dynamic_prefixes);

	void add_std_body(string & body);

	vector<value *> * accept(context* CTX, frame_item * ff, predicate_item * current);
	vector<value *> * accept(context* CTX, frame_item * ff, clause * current);
	bool retrieve(context* CTX, frame_item * ff, clause * current, vector<value *> * vals, bool escape_vars);
	bool retrieve(context* CTX, frame_item * ff, predicate_item * current, vector<value *> * vals, bool escape_vars);
	bool process(context* CNT, bool neg, clause * this_clause_call, predicate_item * p, frame_item * f, vector<value *> ** positional_vals);

	void consult(const string & fname, bool renew);
	void bind();
	predicate_item_user * load_program(const string & fname, const string & starter_name);

	value * parse(context* CTX, bool exit_on_error, bool parse_complex_terms, frame_item * ff, const string & s, int & p);
	void parse_program(vector<string> & renew, string & s);
	void parse_clause(context* CTX, vector<string> & renew, frame_item * ff, string & s, int & p);
	bool unify(context* CTX, frame_item * ff, value * from, value * to);

	void run();
	bool loaded();
};

class stack_values : public stack_container<value *> {
public:
	virtual void free() {
		for (int i = 0; i < this->size(); i++)
			at(i)->free();
	}
};

class frame_item {
protected:
	friend class tframe_item;

	vector<char> names;

	vector<mapper> vars;

	char* deleted;
public:
	frame_item(context * CTX = NULL, frame_item* inheriting = NULL) {
		names.reserve(32);
		vars.reserve(8);
		deleted = NULL;

		import_transacted_globs(CTX, inheriting);
	}

	virtual ~frame_item() {
		int it = 0;
		while (it < vars.size()) {
			if (vars[it].ptr)
				vars[it].ptr->free();
			it++;
		}
		if (deleted)
			free(deleted);
	}

	virtual void forced_import_transacted_globs(context* CTX, frame_item* inheriting) {
		for (mapper& m : inheriting->vars) {
			if (m._name[0] == '*')
				set(CTX, m._name, m.ptr, true);
		}
	}

	virtual void import_transacted_globs(context* CTX, frame_item* inheriting) {
		if (CTX && inheriting && (CTX->THR || CTX->forked())) {
			forced_import_transacted_globs(CTX, inheriting);
		}
	}

	virtual void add_local_names(bool locals_in_forked, std::set<string>& s) {
		for (mapper& m : vars)
			if (m._name[0] != '$' && (!locals_in_forked || m._name[0] == '*'))
				s.insert(m._name);
	}

	virtual void sync(bool not_sync_globs, context * CTX, frame_item * other) {
		int it = 0;
		while (it < other->vars.size()) {
			char * itc = other->vars[it]._name;
			if (not_sync_globs || *itc == '*')
				set(CTX, itc, other->vars[it].ptr, true);
			it++;
		}
		if (not_sync_globs && other->deleted) {
			char* cur = other->deleted;
			while (*cur) {
				unset(CTX, cur);
				while (*cur++);
			}
		}
	}

	virtual frame_item * copy(context * CTX) {
		frame_item * result = new frame_item();
		result->names = names;
		long long d = result->names.size() == 0 ? 0 : &result->names[0] - &names[0];
		result->vars = vars;
		for (mapper & m : result->vars) {
			m.ptr = m.ptr ? m.ptr->const_copy(CTX, this) : NULL;
			m._name += d;
		}
		return result;
	}

	virtual tframe_item* tcopy(context* CTX, interpreter * INTRP, bool import_globs);

	virtual void register_write(const std::string & name) { }

	int get_size() { return vars.size(); }

	value * at(int i) {
		return vars[i].ptr;
	}

	char * atn(int i) {
		return vars[i]._name;
	}

	int find(const char * what, bool & found) {
		found = false;

		if (vars.size() == 0)
			return 0;
		if (strcmp(what, vars[0]._name) < 0)
			return 0;
		if (strcmp(what, vars.back()._name) > 0)
			return vars.size();

		int a = 0;
		int b = vars.size() - 1;
		while (a < b) {
			int c = (a + b) / 2;
			int r = strcmp(what, vars[c]._name);
			if (r == 0) {
				found = true;
				return c;
			}
			if (r < 0)
				b = c;
			else
				a = c + 1;
		}
		if (strcmp(what, vars[b]._name) == 0)
			found = true;
		return b;
	}

	void escape(const char * name, char prepend) {
		bool found = false;
		int it = find(name, found);
		if (found) {
			char * oldp = &names[0];
			char * s = atn(it);
			names.insert(names.begin() + (s - oldp), prepend);
			char * newp = &names[0];
			char * news = newp + (s - oldp);
			for (int i = 0; i < vars.size(); i++)
				if (i != it)
					if (atn(i) > s)
						vars[i]._name += (newp - oldp) + 1;
					else
						vars[i]._name += (newp - oldp);
			value * v = vars[it].ptr;
			vars.erase(vars.begin() + it);

			found = false;
			it = find(news, found);
			if (found) {
				cout << "Internal FRAME collision : " << news << " already exists and can't be escaped?!" << endl;
				exit(4000);
			}
			else {
				mapper m = { news, v };
				vars.insert(vars.begin() + it, m);
			}
		}
	}

	virtual void set(context * CTX, const char * name, value * v, bool set_time_zero = false) {
		bool found = false;
		int it = find(name, found);
		if (found) {
			if (vars[it].ptr) vars[it].ptr->free();
			vars[it].ptr = v ? v->copy(CTX, this) : NULL;
		}
		else {
			char * oldp = names.size() == 0 ? NULL : &names[0];
			int oldn = names.size();
			int n = strlen(name);
			names.resize(oldn + n + 1);
			char * newp = &names[0];
			for (int i = 0; i < vars.size(); i++)
				vars[i]._name += newp - oldp;
			char * _name = newp + oldn;
			strcpy(_name, name);
			mapper m = { _name, v ? v->copy(CTX, this) : NULL };
			vars.insert(vars.begin() + it, m);
		}
	}

	virtual int unset(context* CTX, const char* name) {
		bool found = false;
		int it = find(name, found);
		if (found) {
			int size_deleted = 0;
			if (deleted) {
				char* ptr = deleted;
				while (*ptr++ || *ptr);
				size_deleted = ptr - deleted + 1;
			}
			int old_size = size_deleted ? size_deleted : 1;
			int n = strlen(name);
			size_deleted = old_size + n + 1;
			deleted = (char *) realloc(deleted, size_deleted*sizeof(char));
			strcpy(&deleted[size_deleted - n - 2], name);
			deleted[size_deleted - 1] = 0;

			char* oldp = names.size() == 0 ? NULL : &names[0];
			int oldn = names.size();
			names.erase(names.begin() + (vars[it]._name - oldp), names.begin() + (vars[it]._name - oldp) + n + 1);
			if (names.size() > 0) {
				char* newp = &names[0];
				for (int i = 0; i < vars.size(); i++)
					if (i != it)
						if (vars[i]._name < vars[it]._name)
							vars[i]._name += newp - oldp;
						else
							vars[i]._name += newp - oldp - n - 1;
			}
			vars.erase(vars.begin() + it);
			return it;
		} else
			return -1;
	}

	virtual value * get(context * CTX, const char * name, int unwind = 0) {
		bool found = false;
		int it = find(name, found);
		if (found)
			return vars[it].ptr;
		else if (unwind && name[0] == '$') {
			return get(CTX, &name[1], unwind-1);
		}
		else
			return NULL;
	}

	virtual void register_facts(context* CTX, std::set<string>& names) {
		std::unique_lock<std::mutex> lock(*CTX->DBLOCK);
		map<string, std::atomic<journal*>>::iterator it = CTX->DBJournal->begin();
		while (it != CTX->DBJournal->end()) {
			string fact = it->first;
			register_fact_group(CTX, fact, it->second);
			names.insert(fact);
			it++;
		}
		lock.unlock();
	}

	virtual void unregister_facts(context* CTX) {
		std::unique_lock<std::mutex> lock(*CTX->DBLOCK);
		map<string, std::atomic<journal*>>::iterator it = CTX->DBJournal->begin();
		while (it != CTX->DBJournal->end()) {
			string fact = it->first;
			unregister_fact_group(CTX, fact);
			it++;
		}
		lock.unlock();
	}

	virtual void register_fact_group(context* CTX, string& fact, journal* J);

	virtual void unregister_fact_group(context* CTX, string& fact);
};

class tthread {
	volatile std::atomic<int> _id;
	volatile std::atomic<bool> stopped;
	volatile std::atomic<bool> terminated; // If needs to be terminated
	volatile std::atomic<bool> result; // Logical result
	volatile std::atomic<bool> allow_stop;

	volatile std::atomic<context*> CONTEXT;

	std::condition_variable cv;
	std::mutex cv_m;

	std::condition_variable cvs;
	std::mutex cvs_m;

	std::condition_variable cvt;
	std::mutex cvt_m;

	std::condition_variable cvf;
	std::mutex cvf_m;

	std::thread * runner;
public:
	tthread(int _id, context * CTX) : CONTEXT(NULL) {
		reinit(_id, CTX);

		allow_stop.store(false);

		runner = new std::thread(&tthread::body, this);
	}

	void reinit(int _id, context* CTX);

	virtual ~tthread();

	void body();

	virtual std::condition_variable& get_stopped_var() { return cvs; }
	virtual std::mutex& get_stopped_mutex() { return cvs_m; }

	virtual std::condition_variable& get_terminated_var() { return cvt; }
	virtual std::mutex& get_terminated_mutex() { return cvt_m; }

	virtual std::condition_variable& get_finished_var() { return cvf; }
	virtual std::mutex& get_finished_mutex() { return cvf_m; }

	virtual context* get_context() { return CONTEXT; }
	virtual void set_context(context* CTX) {
		CONTEXT.store(CTX);
	}

	virtual int get_nthread() { return _id; }
	virtual bool is_stopped() { return stopped.load(); }
	virtual void set_stopped(bool v) { stopped.store(v); }
	virtual bool is_terminated() {
		return terminated.load();
	}
	virtual void set_terminated(bool v) {
		terminated.store(v);
	}
	virtual bool get_result() {
		return result.load();
	}
	virtual void set_result(bool v) {
		result.store(v);
	}
};

class thread_pool {
private:
	std::set<tthread*> available;
	std::set<tthread*> used;
	std::mutex guard;
public:
	thread_pool() { }

	tthread* get_thread(int _id, context* CTX);

	void free_thread(tthread* t);

	virtual ~thread_pool();
};

class tframe_item : public frame_item {
	friend class frame_item;
	friend class journal;

	vector<clock_t> last_reads;
	vector<clock_t> first_writes;
	vector<clock_t> last_writes;
	vector<clock_t> first_reads;

	clock_t creation;

	std::mutex mutex;
public:
	tframe_item() : frame_item() {
		creation = clock();
	}

	virtual void set(context * CTX, const char* name, value* v, bool set_time_zero = false) {
		bool locked = mutex.try_lock();
		bool found = false;
		int it = find(name, found);
		if (!found) {
			char* oldp = names.size() == 0 ? NULL : &names[0];
			int oldn = names.size();
			int n = strlen(name);
			names.resize(oldn + n + 1);
			char* newp = &names[0];
			for (int i = 0; i < vars.size(); i++)
				vars[i]._name += newp - oldp;
			char* _name = newp + oldn;
			strcpy(_name, name);
			mapper m = { _name, v ? v->copy(CTX, this) : NULL };
			vars.insert(vars.begin() + it, m);
			last_reads.insert(last_reads.begin() + it, 0);
			first_writes.insert(first_writes.begin() + it, 0);
			last_writes.insert(last_writes.begin() + it, 0);
			first_reads.insert(first_reads.begin() + it, 0);
		}
		else {
			if (vars[it].ptr)
				vars[it].ptr->free();
			vars[it].ptr = v ? v->copy(CTX, this) : NULL;
		}
		if (set_time_zero) {
			first_writes[it] = last_writes[it] = first_reads[it] = last_reads[it] = 0;
		}
		else {
			if (first_writes[it] == 0)
				first_writes[it] = clock();
			last_writes[it] = clock();
		}
		if (locked) mutex.unlock();
	}

	virtual value* get(context * CTX, const char* name, int unwind = 0) {
		bool locked = mutex.try_lock();
		value* result = NULL;
		bool found = false;
		int it = find(name, found);
		if (found) {
			result = vars[it].ptr;
			if (first_reads[it] == 0)
				first_reads[it] = clock();
			last_reads[it] = clock();
		}
		else if (unwind && name[0] == '$') {
			result = frame_item::get(CTX, &name[1], unwind - 1);
		}
		if (locked) mutex.unlock();
		return result;
	}

	virtual int unset(context* CTX, const char* name) {
		bool locked = mutex.try_lock();
		int it = frame_item::unset(CTX, name);
		if (it >= 0) {
			last_reads.erase(last_reads.begin() + it);
			first_writes.erase(first_writes.begin() + it);
			last_writes.erase(last_writes.begin() + it);
			first_reads.erase(first_reads.begin() + it);
		}
		if (locked) mutex.unlock();
		return it;
	}

	virtual void register_write(const std::string & name) {
		bool found = false;
		int it = find(name.c_str(), found);
		if (found && first_writes[it] == 0)
			first_writes[it] = clock();
		if (found)
			last_writes[it] = clock();
	}

	virtual clock_t first_write(const std::string& vname) {
		bool found = false;
		int it = find(vname.c_str(), found);
		if (found)
			return first_writes[it];
		else
			return 0;
	}

	virtual clock_t last_read(const std::string& vname) {
		bool found = false;
		int it = find(vname.c_str(), found);
		if (found)
			return last_reads[it];
		else
			return 0;
	}

	virtual clock_t first_read(const std::string& vname) {
		bool found = false;
		int it = find(vname.c_str(), found);
		if (found)
			return first_reads[it];
		else
			return 0;
	}

	virtual clock_t last_write(const std::string& vname) {
		bool found = false;
		int it = find(vname.c_str(), found);
		if (found)
			return last_writes[it];
		else
			return 0;
	}

	virtual void set_written_new(frame_item* src) {
		for (mapper& m : vars)
			if (m._name[0] != '*') {
				bool found;
				src->find(m._name, found);
				if (!found)
					register_write(m._name);
			}
	}

	virtual void statistics(const std::string & vname, clock_t & cr, clock_t &fw, clock_t &fr, clock_t &lw, clock_t &lr) {
		bool found = false;
		int it = find(vname.c_str(), found);
		if (found) {
			lw = last_writes[it];
			lr = last_reads[it];
			fw = first_writes[it];
			fr = first_reads[it];
		}
		else {
			fw = fr = lw = lr = 0;
		}
		cr = creation;
	}

	virtual void register_fact_group(context* CTX, string & fact, journal* J);

	virtual void unregister_fact_group(context* CTX, string& fact);

	virtual void sync(bool not_sync_globs, context* CTX, frame_item* other) {
		bool locked = mutex.try_lock();
		tframe_item* _other = dynamic_cast<tframe_item*>(other);
		if (!_other) {
			frame_item::sync(not_sync_globs, CTX, other);
			if (locked) mutex.unlock();
			return;
		}
		int it = 0;
		while (it < _other->vars.size()) {
			bool f;
			char* itc = _other->vars[it]._name;
			if (not_sync_globs || *itc == '*') {
				set(CTX, itc, _other->vars[it].ptr, true);
				int _it = find(itc, f);
				if (f) {
					first_writes[_it] = _other->first_writes[it];
					last_writes[_it] = _other->last_writes[it];
					first_reads[_it] = _other->first_reads[it];
					last_reads[_it] = _other->last_reads[it];
				}
				else {
					cout << "Internal ERROR : can't sync tframe_item : var '" << itc << "'" << endl;
					exit(-60);
				}
			}
			it++;
		}
		if (not_sync_globs && other->deleted) {
			char* cur = other->deleted;
			while (*cur) {
				unset(CTX, cur);
				while (*cur++);
			}
		}
		if (locked) mutex.unlock();
	}

	virtual frame_item* copy(context* CTX) {
		frame_item* result = new tframe_item();
		result->names = names;
		long long d = result->names.size() == 0 ? 0 : &result->names[0] - &names[0];
		result->vars = vars;
		for (mapper& m : result->vars) {
			m.ptr = m.ptr ? m.ptr->copy(CTX, this) : NULL;
			m._name += d;
		}
		((tframe_item*)result)->first_writes = first_writes;
		((tframe_item*)result)->last_reads = last_reads;
		((tframe_item*)result)->first_reads = first_reads;
		((tframe_item*)result)->last_writes = last_writes;
		return result;
	}

	virtual tframe_item* tcopy(context* CTX, interpreter* INTRP) {
		return dynamic_cast<tframe_item *>(copy(CTX));
	}
};

class generated_vars : public vector<frame_item *> {
public:
	generated_vars() : vector<frame_item *>() { }
	generated_vars(int n, frame_item * filler) : vector<frame_item *>(n, filler) { }

	virtual bool has_variant(int i) { return i < size(); }
	virtual bool had_variants() { return size() != 0; }

	virtual void trunc_from(int k) {
		delete_from(k);
		this->resize(k);
	}

	virtual frame_item * get_next_variant(context * CTX, int i) { return at(i); }

	virtual void delete_from(int i) {
		for (int j = i; j < size(); j++)
			delete at(j);
	}
};

class clause {
	friend predicate_item;
private:
	predicate * parent;
	std::list<string> args;
	std::list<value *> _args;
	vector<predicate_item *> items;
	std::mutex mutex;
	bool forking;
public:
	clause(predicate * pp) : parent(pp), forking(false) { }
	~clause();

	void lock() { mutex.lock(); }
	void unlock() { mutex.unlock(); }

	virtual void bind();

	predicate * get_predicate() { return parent; }

	bool is_forking() { return forking; }
	void set_forking(bool v) {
		forking = v;
	}

	const std::list<string> * get_args() {
		return &args;
	}

	const std::list<value *> * _get_args() {
		return &_args;
	}

	void push_cashed_arg(value * v) {
		v->use();
		_args.push_back(v);
	}

	void set_args(const std::list<string> & other_args) {
		args = other_args;
	}

	void add_item(predicate_item * p) {
		items.push_back(p);
	}

	void add_arg(const string & a) {
		args.push_back(a);
	}

	virtual int num_items() { return items.size(); }
	virtual predicate_item * get_item(int i) { return items[i]; }
};

class predicate_item {
protected:
	int self_number;
	int starred_end;
	clause * parent;
	std::list<string> args;
	std::list<value *> _args;

	interpreter * prolog;

	bool neg;
	bool once;
	bool call;

	std::mutex mutex;
	std::recursive_mutex* critical;
public:
	predicate_item(bool _neg, bool _once, bool _call, int num, clause * c, interpreter * _prolog) : neg(_neg), once(_once), call(_call),
		self_number(num), starred_end(-1), parent(c), critical(NULL), prolog(_prolog) { }

	virtual ~predicate_item() {
		for (value * v : _args)
			v->free();
	}

	virtual void set_starred_end(int end) {
		this->starred_end = end;
	}

	virtual int get_starred_end() {
		return this->starred_end;
	}

	virtual predicate_item* get_last(int variant) {
		return this->starred_end < 0 ? NULL : parent->get_item(this->starred_end - 1);
	}

	void set_critical(std::recursive_mutex* critical) {
		this->critical = critical;
	}

	void enter_critical() {
		if (this->critical)
			this->critical->lock();
	}

	void leave_critical() {
		if (this->critical)
			this->critical->unlock();
	}

	void lock() { mutex.lock(); }
	void unlock() { mutex.unlock(); }

	virtual void bind() { }

	virtual const string get_id() = 0;

	bool is_negated() { return neg; }
	bool is_once() { return once; }
	bool is_call() { return call; }

	void make_once() { once = true; }
	void clear_negated() { neg = false; }

	const std::list<value *> * _get_args() {
		return &_args;
	}

	void push_cashed_arg(value * v) {
		v->use();
		_args.push_back(v);
	}

	void add_arg(const string & a) {
		args.push_back(a);
	}

	virtual predicate_item * get_next(int variant) {
		if (!is_last()) {
			if (starred_end >= 0)
				return parent->get_item(starred_end);
			else
				return parent->items[self_number + 1];
		}
		else
			return NULL;
	}

	virtual predicate_item* get_strict_next() {
		return parent->get_item(self_number + 1);
	}

	virtual frame_item * get_next_variant(context * CTX, frame_item * f, int & internal_variant, vector<value *> * positional_vals) { return NULL; }

	const std::list<string> * get_args() {
		return &args;
	}

	clause * get_parent() { return parent; }

	bool is_first() { return self_number == 0; }
	bool is_last() { return !parent || self_number == parent->items.size() - 1; }

	virtual generated_vars * generate_variants(context * CTX, frame_item * f, vector<value *> * & positional_vals) = 0;

	virtual bool execute(context * CTX, frame_item * &f, int i, generated_vars* variants) {
		return true;
	}
};

class predicate {
	friend predicate_item;
	friend clause;
private:
	string name;
	vector<clause *> clauses;
	bool forking;
public:
	predicate(const string & _name) : name(_name), forking(false) { }
	~predicate();

	void bind() {
		for (clause * c : clauses)
			c->bind();
	}

	void add_clause(clause * c) {
		clauses.push_back(c);
	}

	bool is_forking() { return forking; }
	void set_forking(bool v) {
		forking = v;
	}
	bool is_forking_variant(int variant) {
		return clauses[variant]->is_forking();
	}

	virtual int num_clauses() { return clauses.size(); }
	virtual clause * get_clause(int i) { return clauses[i]; }
};

class predicate_item_user : public predicate_item {
private:
	string id;
	predicate * user_p;
public:
	predicate_item_user(bool _neg, bool _once, bool _call, int num, clause * c, interpreter * _prolog, const string & _name) : predicate_item(_neg, _once, _call, num, c, _prolog), id(_name) {
		user_p = NULL;
	}

	virtual void bind() {
		if (prolog->PREDICATES.find(id) == prolog->PREDICATES.end())
			user_p = NULL;
		else
			user_p = prolog->PREDICATES[id];
	}

	bool is_dynamic() { return user_p == NULL; }

	bool is_forking_variant(int variant) { return user_p != NULL && user_p->is_forking_variant(variant); }

	predicate * get_user_predicate() { return user_p; }

	virtual const string get_id() { return id; }

	virtual generated_vars * generate_variants(context * CTX, frame_item * f, vector<value *> * & positional_vals);

	virtual bool processing(context * CONTEXT, bool line_neg, int variant, generated_vars * variants, vector<value *> ** positional_vals, frame_item * up_f, context * up_c);
};

class journal_item {
public:
	jTypes type;
	value* data;
	int position;

	journal_item(jTypes t, value* data, int position) {
		this->type = t;
		this->data = data;
		this->position = position;
	}

	virtual ~journal_item() {
		if (this->type == jDelete)
			this->data->free();
	}
};

class journal {
public:
	clock_t creation;
	clock_t first_write, last_write, first_read, last_read;

	vector<journal_item*> log;

	journal() {
		creation = clock();

		first_write = last_write = first_read = last_read = 0;
	}

	virtual ~journal() {
		for (journal_item* it : log)
			delete it;
	}

	virtual void register_read() {
		if (!first_read)
			first_read = clock();
		last_read = clock();
	}

	virtual void register_write(jTypes t, value* data, int position, journal * src = NULL) {
		if (src) {
			if (!first_write || src->first_write < first_write)
				first_write = src->first_write;
			if (!last_write || src->last_write > last_write)
				last_write = src->last_write;
			if (!first_read || src->first_read < first_read)
				first_read = src->first_read;
			if (!last_read || src->last_read > last_read)
				last_read = src->last_read;
		}
		else {
			if (!first_write) {
				first_write = clock();
			}
			last_write = clock();
		}

		log.push_back(new journal_item(t, data, position));
	}
};

#endif

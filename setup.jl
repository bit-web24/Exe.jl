# Setup file to make executable from ProjectBase file
print("Project File: "); 
ProjectBase = readline()

if isfile(ProjectBase)
	println("Search $ProjectBase: OK")
else
	println("Search $ProjectBase: ERROR")
	exit(1)
end

try
	include(ProjectBase)
catch err
	throw(err)
	exit(1)
end

ccode = """
#include <julia.h>
#include <stdio.h>

#ifndef MAX_JL_ARGV_SZ
#define MAX_JL_ARGV_SZ 1024
#endif

int main(int argc, char **argv)
{
	jl_init();

	// NOTImplemented: check whether main.jl file exist or not
	jl_eval_string("include(\\"$ProjectBase\\")");

	// NOTImplemented: check if there any function named 'main' exist in main.jl
	jl_function_t *main = jl_get_function(jl_main_module, "main");
	jl_value_t *jl_argc = jl_box_int32(argc);

	// Creating a 1-d array of characters to eval it to the corresponding
	// julia type using jl_eval_string function
	#ifdef MAX_JL_ARGV_SZ
	char jl_argv[MAX_JL_ARGV_SZ];
	#else
	char jl_argv[1024];
	#endif

	int argv_ndx = 0;
    
	jl_argv[argv_ndx] = '[';
	argv_ndx += 1;
	
	for(int i =0; i<argc; i++){
		jl_argv[argv_ndx] = '"';
		argv_ndx += 1;

		for(int j=0; j< (int) strlen(argv[i]); j++){
			jl_argv[argv_ndx] = argv[i][j];
			argv_ndx += 1;
		}

		jl_argv[argv_ndx] = '"';
		argv_ndx += 1;

		jl_argv[argv_ndx] = ',';
		argv_ndx += 1;
	}

	jl_argv[argv_ndx-1] = ']';
	jl_argv[argv_ndx] = '\\0';

	jl_value_t *xargv = jl_eval_string(jl_argv);
	
	jl_call2(main, jl_argc, (jl_value_t *) xargv);
	
	jl_atexit_hook(0);
	return 0;
}
"""

# BUILD PROCESS

# Put the ccode into a C file
cfile = open("./setup.c", "w")
write(cfile, ccode)
close(cfile)

# Compile the C code using GCC compiler
print("julia Path: ")
JULIA_DIR = readline()
run(`gcc -o app -fPIC -I$JULIA_DIR/include/julia -L$JULIA_DIR/lib -Wl,-rpath,$JULIA_DIR/lib setup.c -ljulia`)

# Removing unnecessary files
rm("./setup.c")

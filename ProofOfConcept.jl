#=
NOTICE:
This file cannot just be run as a script as there
are required manual steps listed in the comments.
=#

# Define a method for a function
# Notice that this is a *very* simple function
# so we are not dealing with linking in this sample

addone(x) = x + 1

# Trigger a specialization to be created

precompile(addone, Tuple{Int64})

# Generate and output LLVM textual IR to a file

open("sample.ll", "w") do io
    code_llvm(io, addone, (Int64,); dump_module=true)
end

# Take a look at the file.
# You will notice two functions getting defined.
# The one named jfptr_addone_somenumber is the wrapper.
# The one named julia_addone_someothernumber is the real one.
# Both are needed.
# You may want to fiddle with the literal number added
# by the julia_addone_somenumber function so you can tell
# later that you are running the shared library code
# rather than the jit code.

# In your shell convert the LLVM ll code to bc format
# You will have to figure out what your julia build directory is

julia_build_dir/usr/tools/llvm-as sample.ll -o sample.bc
julia_build_dir/usr/tools/clang -shared -fpic sample.bc -o sample.so

# Dig down in the metadata of the function
# to get to the method specializations

s = methods(addone).ms[1].specializations

# The cache is a linked list of code instances
# Since we only caused one instance to be created
# we know we are looking at the right one ;)

c = s.func.cache

# Here are the two function pointers needed
# to call the method with normal julia code

c.invoke
c.specptr

# If we had a native compiled shared library we could load it
using Libdl

# Get pointers to the functions
# (Look in the sample.ll file created aboe to get the numbers)

so = dlopen("somepath", someflags)
invoke_fptr = dlsym(so, "jfptr_addone_somenumber")
specptr_fptr = dlsym(so, "julia_addone_someothernumber")

# Save the pointers into the code instance from above

c.invoke = invoke_fptr
c.specptr = specptr_fptr

# Call the version of the method from the shared library

addone(Int64(1))



NativeCache

This project is to design and implement native code caching
for Julia packages. Think of it as an aumgented package precompile,
with shared libraries holding caches of ahead-of-time compiled methods
and data for the dynamic julia system. Let's think of these as transient,
living as long as their corresponding ji file.

Speed up first run after after restarting julia.

This issues associated with building multiple native shared libraries
ahead of time for distribution can be a separate project.

Speed up first run after downloading.

Code to ahead-of-time native compile must be identified somehow.
We could use precompile statements to drive the compilation.
The precompile statements could be generated via premade tests,
a tracer like Fezzik, or some other logic.
Could have layers of libraries:
    Test-suite based library
    Tracing based library
   
The selected code would be compiled to a native shared library.

When a precompiled package is loaded these thing would also happen:
* Load the corresponding native shared library
* Link the library functions into the loaded package

How do you identify what code you already have?
Slow-but-general way would be to check the serialized the type signature
Fast way would be to have a linking table

Julia currently solves this in the JIT by numbering the method instances
and using a pointer (to the native code) and a string name (matching the
numbered method instance.) This associate is created when the native
code is generated. If the numbered names stuck around in the ji file and
we generated shared library code using the same numbered names then we
could use them for linking.
The trouble is this changes the ji serialization format and is still slow,
requiring name lookups.
We could have an array of pointers to functions in the shared library.
Then walk the array in sequence and the method tree in a defined order to
drop the pointers into place.
Alternately we could walk the tree and replace array indexes with pointers.

When encountering a precompile statement:
* Compile the associated code.
* Record an association between the compiled code and the jl_code_instance_t.
  [Could temporarily use the function names and jl_code_instance_t pointers.]

During serialization build a list of methods.
Write an array to the library with the pointer to the appropriate function
for each index of this list.

During deserialization build a list of methods.
The library could have an array mapping from indexes in this list to functions.

====

Collect code fragments to:
* Compile a shared library when a package is precompiled
  * Trigger compilation on precompile calls when in outputji mode
  * Compile a specialized method to IR
  * Compile a collection of IR to a shared library
  [These happens roughly during src/precompile.c]
* Load a shared libary and link it in during loading
  [This happens roughly during base/loading.jl]
* Trigger a shared libary to be closed when a package precompile happens
  [This happens roughly during base/loading.jl]

====

Ideally, the data in the ji would be in the shared libary so the
data structures could be prebuilt and make use of the dynamic linker.
An init function could handle the fancier parts of the linking that the
base linker cannot do.

====

Latency:
* When
* How many times per person
* How many times per community


Package latency:
    Design
    Implement
    Build
    Find
    Download
    Rebuild
    Precompile (per: source change | dependency change)
    Native compile (per: session | source change | dependency change)

Reproducability


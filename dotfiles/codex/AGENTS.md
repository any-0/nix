# Rules for the agent

Do not add a fallback if the code does not need one.

Do not correct an error with a new code path around the error. Correct the cause of
the error.

Write simple code that operates correctly. Do not write complex code with dead code
paths.

Write code that is easy to read.

Do not add a check for the existence of a stable project file. Do not add a check
for the existence of a stable project directory. Add a check only if the item is
optional, external, or from the user.

Do not use the Python interpreter of the system. Do not install a Python package
with the pip tool of the system.

Test a project for Docker in Docker. Do not run `npm install` on the local machine
instead.

Do NOT use fallbacks when not needed.
Do NOT solve errors by simply introducing a new code path around where the error happens.
We prefer working, simple code over unmanagable code with dead paths.
Do not add routine existence checks for stable project files or directories that are expected to be present; only check when something is genuinely optional, user-provided, external, or otherwise uncertain.
The code you write should be readable and simple.
If you want to run a python file, do not use system python, and do not try to install stuff with system pip.
If you want to test a project running in docker locally, ALSO run it in docker and dont just npm install to my machine.
If a project includes a .dev directory with a flake.nix, use THAT dev environment to run commands.

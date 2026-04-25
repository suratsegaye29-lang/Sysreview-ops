## 2024-04-24 - File lookup bottleneck in batch runner
**Learning:** Using `find` inside a loop in bash scripts for a directory with many files spawns a new process and scans the directory each time, resulting in O(N * M) performance where N is the number of files we are searching for and M is the total files in the directory.
**Action:** Use native bash globbing (e.g. `matches=("$DIR"/"$PREFIX"*)`) which avoids spawning processes and takes advantage of bash's internal path expansion, resulting in a >10x speedup for large directories.
## 2024-04-24 - Token Optimization via --file flag
**Learning:** Claude CLI's `--file` flag loads file contents efficiently and is often necessary to avoid the agent burning input tokens by making repetitive tool calls to read standard context files like extraction forms and mode instructions for every single sub-agent worker.
**Action:** When spawning repetitive worker agents in bash, pass the fixed context files (like forms and shared mode rules) upfront using `--file` rather than relying on the agent to read them manually each time. This provides significant token optimization.

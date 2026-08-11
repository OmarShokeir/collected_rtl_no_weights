# Script to generate a SystemVerilog function that returns a 
#conjunction of equality assumptions between pairs of signals.

import sys
from collections import defaultdict

if len(sys.argv) < 4:
    print("Usage: python3 generate_assumption_func.py <input> <output> <func_name>")
    sys.exit(1)

inp = sys.argv[1]
out = sys.argv[2]
func_name = sys.argv[3]

with open(inp, "r") as f:
    signals = [line.strip() for line in f if line.strip()]

# group signals by suffix after first "."
groups = defaultdict(dict)

for sig in signals:
    parts = sig.split(".", 1)

    if len(parts) != 2:
        continue

    dut, suffix = parts

    groups[suffix][dut] = sig

pairs = []

# create dut0 <-> dut1 pairs
for suffix, entries in groups.items():
    if "golden" in entries and "faulty" in entries:
        pairs.append((entries["golden"], entries["faulty"]))

# deterministic ordering
pairs.sort(key=lambda x: x[0])

with open(out, "w") as f:
    f.write(f"function {func_name}();\n")
    f.write(f"{func_name} =\n")

    for i, (lhs_sig, rhs_sig) in enumerate(pairs):

        # lhs = f"top.{lhs_sig}"
        # rhs = f"top.{rhs_sig}"
        lhs = f"{lhs_sig}"
        rhs = f"{rhs_sig}"

        if i == len(pairs) - 1:
            f.write(f"\t{lhs} ==\n\t{rhs};\n")
        else:
            f.write(f"\t{lhs} ==\n\t{rhs} &&\n")

    f.write("endfunction\n")

print(f"Generated function → {out}")
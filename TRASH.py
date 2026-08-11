#!/usr/bin/env python3

import re

MAX_FAULTS = 10

ASSUMPTIONS_FILE = "assumptions.sv"
FAULT_FILE = "fault.sv"

# ---------------------------------------------------------
# Read files
# ---------------------------------------------------------

with open(ASSUMPTIONS_FILE, "r") as f:
    assumptions = f.readlines()

with open(FAULT_FILE, "r") as f:
    fault = f.readlines()

# ---------------------------------------------------------
# Find first MAX_FAULTS assumption pairs
# ---------------------------------------------------------

fault_pairs = []
fault_count = 0

i = 0
while i < len(assumptions) - 1 and fault_count < MAX_FAULTS:

    l1 = assumptions[i].strip()
    l2 = assumptions[i + 1].strip()

    if l1.startswith("golden") and "==" in l1 and l2.startswith("faulty"):

        # Comment out the original assumptions
        assumptions[i] = "// " + assumptions[i]
        assumptions[i + 1] = "// " + assumptions[i + 1]

        # Extract signal names
        golden_sig = re.sub(r"\s*==.*", "", l1).strip()
        faulty_sig = re.sub(r"&&\s*$", "", l2).strip()

        fault_pairs.append((golden_sig, faulty_sig))
        fault_count += 1
        i += 2
        continue

    i += 1

print(f"Found {fault_count} properties.")

# ---------------------------------------------------------
# Build new fault expression
# ---------------------------------------------------------

expr = [
    "    fault_assumptions =\n",
    "(\n"
]

for idx, (golden_sig, faulty_sig) in enumerate(fault_pairs):

    # XOR with an MSB-only mask
    line = (
        f"        {faulty_sig} == "
        f"({golden_sig} ^ "
        f"{{1'b1, {{($bits({golden_sig})-1){{1'b0}}}}}})"
    )

    if idx != len(fault_pairs) - 1:
        line += " &&"

    line += "\n"

    expr.append(line)

expr.append("    );\n")

# ---------------------------------------------------------
# Replace old fault assignment
# ---------------------------------------------------------

new_fault = []

inside_assignment = False

for line in fault:

    if "fault_assumptions =" in line:
        inside_assignment = True
        new_fault.extend(expr)
        continue

    if inside_assignment:
        if ");" in line:
            inside_assignment = False
        continue

    new_fault.append(line)

# ---------------------------------------------------------
# Write assumptions.sv
# ---------------------------------------------------------

with open(ASSUMPTIONS_FILE, "w") as f:
    f.writelines(assumptions)

# ---------------------------------------------------------
# Write fault.sv
# ---------------------------------------------------------

with open(FAULT_FILE, "w") as f:
    f.writelines(new_fault)

print(f"Injected {fault_count} simultaneous MSB-flip faults.")
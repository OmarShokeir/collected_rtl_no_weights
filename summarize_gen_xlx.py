import os
import sys
from datetime import datetime
from openpyxl import Workbook

if len(sys.argv) != 2:
    print("Usage: python summarize.py <campaign_folder>")
    sys.exit(1)

# Campaign folder inside results/
campaign_dir = os.path.join("results", sys.argv[1])

if not os.path.isdir(campaign_dir):
    print(f"Error: '{campaign_dir}' does not exist.")
    sys.exit(1)

KNOWN_RESULTS = [
    "hold_bounded",
    "hold",
    "vacuous",
    "fail",
    "open"
]

# ------------------------------------------------------
# Create workbook
# ------------------------------------------------------

wb = Workbook()
ws = wb.active
ws.title = "Fault Injection Results"

ws.append([
    "File",
    "Faulted Signal",
    "Result",
    "Time (s)",
    "Report Created"
])

counts = {}
previous_timestamp = None

# ------------------------------------------------------
# Process all fault reports
# ------------------------------------------------------

detail_files = sorted(
    f for f in os.listdir(campaign_dir)
    if f.startswith("fault_") and f.endswith(".txt")
)

for fname in detail_files:

    path = os.path.join(campaign_dir, fname)

    signal = "UNKNOWN_SIGNAL"
    result = "ERROR_PLEASE_REVIEW"
    report_timestamp = None
    elapsed = 0

    try:

        with open(path, "r", errors="ignore") as f:
            lines = f.readlines()

        # ------------------------------------------
        # Extract faulted signal
        # ------------------------------------------

        for i, line in enumerate(lines):
            if (
                line.strip() == "Faulted signal:"
                or line.strip() == "Permanent stuck-at-1 fault:"
            ):
                if i + 1 < len(lines):
                    signal = lines[i + 1].strip()

                    # Remove trailing ==
                    if signal.endswith("=="):
                        signal = signal[:-2].strip()

                break

        # ------------------------------------------
        # Extract report timestamp
        # ------------------------------------------

        for line in lines:
            if "report created on" in line.lower():

                ts = line.split("report created on", 1)[1].strip()

                # Remove timezone (CEST/CET/etc.)
                parts = [
                    p for p in ts.split()
                    if p not in ("CEST", "CET", "UTC", "GMT")
                ]

                ts = " ".join(parts)

                try:
                    report_timestamp = datetime.strptime(
                        ts,
                        "%a %b %d %H:%M:%S %Y"
                    )
                except Exception:
                    report_timestamp = None

                break

        if report_timestamp is not None:
            if previous_timestamp is None:
                elapsed = "Not available"
            else:
                elapsed = int(
                    (report_timestamp - previous_timestamp).total_seconds()
                )

            previous_timestamp = report_timestamp

        # ------------------------------------------
        # Extract property result
        # ------------------------------------------

        text = "".join(lines).lower()

        for candidate in KNOWN_RESULTS:
            if f"assertion    {candidate}" in text:
                result = candidate
                break

    except Exception as e:
        print(f"Error reading {fname}: {e}")

    counts[result] = counts.get(result, 0) + 1

    ws.append([
        fname,
        signal,
        result,
        elapsed,
        report_timestamp.strftime("%H:%M:%S")
        if report_timestamp else ""
    ])

# ------------------------------------------------------
# Statistics
# ------------------------------------------------------

ws.append([])
ws.append(["Statistics"])
ws.append(["Result", "Count"])

for status in sorted(counts):
    ws.append([status, counts[status]])

ws.append(["Total", sum(counts.values())])

# ------------------------------------------------------
# Auto-size columns
# ------------------------------------------------------

for column in ws.columns:

    max_length = 0
    column_letter = column[0].column_letter

    for cell in column:
        try:
            if cell.value is not None:
                max_length = max(max_length, len(str(cell.value)))
        except Exception:
            pass

    ws.column_dimensions[column_letter].width = min(max_length + 2, 100)

# ------------------------------------------------------
# Save
# ------------------------------------------------------

output_file = os.path.join(campaign_dir, "summary.xlsx")
wb.save(output_file)

print(f"Summary written to {output_file}")
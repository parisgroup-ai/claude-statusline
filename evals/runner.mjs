import fs from "node:fs";
import path from "node:path";
import { spawnSync } from "node:child_process";
import { fileURLToPath } from "node:url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const repoRoot = path.resolve(__dirname, "..");
const casesDir = path.join(__dirname, "cases");
const scriptPath = path.join(repoRoot, "bin/cc-statusline.sh");

const caseFiles = fs
  .readdirSync(casesDir)
  .filter((f) => f.endsWith(".json") && !f.startsWith("."));

let passed = 0;
let failed = 0;
const results = [];

for (const file of caseFiles) {
  const filePath = path.join(casesDir, file);
  let caseData;
  try {
    caseData = JSON.parse(fs.readFileSync(filePath, "utf-8"));
  } catch (err) {
    failed++;
    results.push({ id: file, pass: false, reason: "Invalid JSON: " + err.message });
    continue;
  }

  const { id, input, expected } = caseData;
  const env = {
    ...process.env,
    ...(input.env || {}),
  };

  const stdinInput = JSON.stringify(input.stdin || {});

  const proc = spawnSync("bash", [scriptPath], {
    input: stdinInput,
    env,
    encoding: "utf-8",
    cwd: repoRoot,
  });

  const stdout = proc.stdout || "";
  const exitCode = proc.status ?? 0;
  let casePass = true;
  const failureReasons = [];

  if (expected.exitCode !== undefined && exitCode !== expected.exitCode) {
    casePass = false;
    failureReasons.push(`Expected exit code ${expected.exitCode}, got ${exitCode}`);
  }

  if (Array.isArray(expected.contains)) {
    for (const needle of expected.contains) {
      if (!stdout.includes(needle)) {
        casePass = false;
        failureReasons.push(`Stdout missing expected needle "${needle}". Output: "${stdout.trim()}"`);
      }
    }
  }

  if (Array.isArray(expected.doesNotContain)) {
    for (const needle of expected.doesNotContain) {
      if (stdout.includes(needle)) {
        casePass = false;
        failureReasons.push(`Stdout unexpectedly contained "${needle}". Output: "${stdout.trim()}"`);
      }
    }
  }

  if (expected.minSegments !== undefined) {
    const segments = stdout.split("│").map((s) => s.trim()).filter(Boolean);
    if (segments.length < expected.minSegments) {
      casePass = false;
      failureReasons.push(`Expected at least ${expected.minSegments} segments, found ${segments.length}`);
    }
  }

  if (casePass) {
    passed++;
    results.push({ id, pass: true });
  } else {
    failed++;
    results.push({ id, pass: false, reasons: failureReasons });
  }
}

const total = passed + failed;
const score = total > 0 ? Number((passed / total).toFixed(2)) : 0;

const summary = {
  passed,
  failed,
  score,
  results,
};

console.log(JSON.stringify({ passed, failed, score }));

if (failed > 0) {
  process.stderr.write(JSON.stringify(summary, null, 2) + "\n");
  process.exit(1);
} else {
  process.exit(0);
}

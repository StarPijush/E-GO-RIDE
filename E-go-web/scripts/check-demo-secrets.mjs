import { existsSync, readdirSync, readFileSync } from "node:fs";
import { extname, join } from "node:path";

const BUILD_DIR = ".next";
const TEXT_EXTENSIONS = new Set([".css", ".html", ".js", ".json", ".map", ".mjs", ".rsc", ".txt"]);
const PATTERNS = [
  ["demo password", "EgoDemo@123"],
  ["demo OTP label", "Demo OTP: 123456"],
  ["quoted demo OTP", '"123456"'],
  ["quoted demo OTP", "'123456'"],
];

if (!existsSync(BUILD_DIR)) {
  console.error("Build output not found. Run `npm run build` first.");
  process.exit(1);
}

const hits = [];

function walk(directory) {
  for (const entry of readdirSync(directory, { withFileTypes: true })) {
    const file = join(directory, entry.name);
    if (entry.isDirectory()) {
      walk(file);
      continue;
    }
    if (!entry.isFile() || !TEXT_EXTENSIONS.has(extname(entry.name))) continue;

    const contents = readFileSync(file, "utf8");
    for (const [label, pattern] of PATTERNS) {
      if (contents.includes(pattern)) hits.push(`${file}: ${label}`);
    }
  }
}

walk(BUILD_DIR);

if (hits.length > 0) {
  console.error("Demo credentials found in the build output:");
  for (const hit of hits) console.error(`  ${hit}`);
  process.exit(1);
}

console.log("Build output contains no plaintext demo credentials.");

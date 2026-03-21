#!/usr/bin/env node
/**
 * Grouped Mechanism Tag Selector for Mini-Game Generation
 *
 * Selects mechanism tags from 4 group files with specified counts.
 *
 * Groups:
 *   player  (1 tag)  — data/tags/mechanism_player_tags.csv
 *   action  (2 tags) — data/tags/mechanism_action_tags.csv
 *   ability (1 tag)  — data/tags/mechanism_ability_tags.csv
 *   context (1 tag) — data/tags/mechanism_context_tags.csv
 *
 * Usage:
 *   node scripts/random_mechanism_selector.js [options]
 *
 * Options:
 *   -s, --seed <number>    Random seed (uses current time if omitted)
 *   -f, --format <type>    Output format: text, json, markdown (default: markdown)
 *   -h, --help             Show help
 */

const fs = require("fs");
const path = require("path");

const GROUPS = [
  { name: "player", file: "data/tags/mechanism_player_tags.csv", count: 1 },
  { name: "action", file: "data/tags/mechanism_action_tags.csv", count: 2 },
  { name: "ability", file: "data/tags/mechanism_ability_tags.csv", count: 1 },
  { name: "context", file: "data/tags/mechanism_context_tags.csv", count: 1 },
];

// Xorshift128 PRNG (same as random_tag_selector.js for seed compatibility)
class Xorshift128 {
  constructor(seed = Date.now()) {
    this.x = seed >>> 0;
    this.y = 362436069;
    this.z = 521288629;
    this.w = 88675123;
    for (let i = 0; i < 10; i++) this.next();
  }

  next() {
    const t = this.x ^ (this.x << 11);
    this.x = this.y;
    this.y = this.z;
    this.z = this.w;
    this.w = (this.w ^ (this.w >>> 19) ^ (t ^ (t >>> 8))) >>> 0;
    return this.w / 0x100000000;
  }

  nextInt(min, max) {
    return Math.floor(min + this.next() * (max - min + 1));
  }

  shuffle(array) {
    const result = [...array];
    for (let i = result.length - 1; i > 0; i--) {
      const j = this.nextInt(0, i);
      [result[i], result[j]] = [result[j], result[i]];
    }
    return result;
  }
}

function parseCSV(content) {
  const lines = content.trim().split("\n");
  return lines.slice(1).map((line) => {
    const fields = [];
    let current = "";
    let inQuotes = false;

    for (let i = 0; i < line.length; i++) {
      const char = line[i];
      if (char === '"') {
        inQuotes = !inQuotes;
      } else if (char === "," && !inQuotes) {
        fields.push(current.trim());
        current = "";
      } else {
        current += char;
      }
    }
    fields.push(current.trim());

    return {
      name: fields[0] || "",
      overview: fields[1] || "",
      description: fields[2] || "",
      keywords: fields[3] || "",
    };
  });
}

function loadTags(filePath) {
  const resolved = path.isAbsolute(filePath)
    ? filePath
    : path.join(__dirname, "..", filePath);

  if (!fs.existsSync(resolved)) {
    console.error(`Error: file not found: ${resolved}`);
    process.exit(1);
  }

  return parseCSV(fs.readFileSync(resolved, "utf-8"));
}

function selectFromGroups(groups, tagsByGroup, rng) {
  const result = [];
  for (const group of groups) {
    const shuffled = rng.shuffle(tagsByGroup[group.name]);
    result.push(...shuffled.slice(0, group.count));
  }
  return result;
}

function getCategory(name) {
  const hyphenIndex = name.indexOf("-");
  if (hyphenIndex === -1) return name;
  return name.substring(0, hyphenIndex);
}

function formatOutput(selectedTags, seed, format, groupResults) {
  switch (format) {
    case "json":
      return JSON.stringify(
        {
          seed,
          type: "mechanism",
          groups: groupResults,
          tags: selectedTags.map((t) => ({
            name: t.name,
            category: getCategory(t.name),
            overview: t.overview,
            description: t.description,
            keywords: t.keywords,
          })),
        },
        null,
        2
      );

    case "text":
      return selectedTags
        .map((t) => `${t.name}: ${t.overview} - ${t.description}`)
        .join("\n");

    case "markdown":
    default: {
      const lines = [
        "## Selected Mechanism Tags (Grouped)",
        "",
        `**Seed**: ${seed}`,
        "",
      ];

      for (const gr of groupResults) {
        lines.push(`### ${gr.group} (${gr.tags.length} selected)`);
        lines.push("");
        lines.push("| Tag | Category | Overview | Description |");
        lines.push("|:---|:---|:---|:---|");
        for (const t of gr.tags) {
          lines.push(
            `| \`${t.name}\` | ${getCategory(t.name)} | ${t.overview} | ${t.description} |`
          );
        }
        lines.push("");
      }

      lines.push("### Keywords");
      lines.push("");
      selectedTags.forEach((t) => {
        lines.push(`- **${t.name}**: ${t.keywords}`);
      });

      lines.push("");
      lines.push("## Usage");
      lines.push("");
      lines.push("```");
      lines.push(
        "Use the above tags as inspiration starting points for game design,"
      );
      lines.push("following the procedures in guides/mini-game-design-guide.md §7.");
      lines.push("Tags are stimuli, not constraints. Don't be afraid to deviate.");
      lines.push("```");

      return lines.join("\n");
    }
  }
}

function showHelp() {
  console.log(`
Grouped Mechanism Tag Selector - Selects mechanism tags from 4 groups

Groups:
  player  (1 tag)  — data/tags/mechanism_player_tags.csv
  action  (2 tags) — data/tags/mechanism_action_tags.csv
  ability (1 tag)  — data/tags/mechanism_ability_tags.csv
  context (1 tag) — data/tags/mechanism_context_tags.csv

Usage:
  node scripts/random_mechanism_selector.js [options]

Options:
  -s, --seed <number>    Random seed (uses current time if omitted)
  -f, --format <type>    Output format: text, json, markdown (default: markdown)
  -h, --help             Show this help

Examples:
  node scripts/random_mechanism_selector.js
  node scripts/random_mechanism_selector.js -s 42
  node scripts/random_mechanism_selector.js -s 42 -f json
`);
}

function parseArgs(args) {
  const options = {
    seed: Date.now(),
    format: "markdown",
  };

  for (let i = 0; i < args.length; i++) {
    const arg = args[i];
    switch (arg) {
      case "-s":
      case "--seed":
        options.seed = parseInt(args[++i], 10);
        break;
      case "-f":
      case "--format":
        options.format = args[++i];
        break;
      case "-h":
      case "--help":
        showHelp();
        process.exit(0);
    }
  }

  return options;
}

function main() {
  const options = parseArgs(process.argv.slice(2));

  if (!["text", "json", "markdown"].includes(options.format)) {
    console.error("Error: format must be text, json, or markdown");
    process.exit(1);
  }

  // Load all group tag files
  const tagsByGroup = {};
  for (const group of GROUPS) {
    tagsByGroup[group.name] = loadTags(group.file);
  }

  const rng = new Xorshift128(options.seed);
  const allSelected = selectFromGroups(GROUPS, tagsByGroup, rng);

  // Build group results for formatted output
  const groupResults = [];
  let offset = 0;
  for (const group of GROUPS) {
    groupResults.push({
      group: group.name,
      tags: allSelected.slice(offset, offset + group.count),
    });
    offset += group.count;
  }

  console.log(formatOutput(allSelected, options.seed, options.format, groupResults));
}

main();

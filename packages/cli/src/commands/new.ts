/**
 * kaguya new <name> - Create a new Kaguya project
 */
import { Command } from "commander";
import { mkdir, cp, readFile, writeFile } from "node:fs/promises";
import { join, dirname } from "node:path";
import { fileURLToPath } from "node:url";
import { existsSync } from "node:fs";
import pc from "picocolors";

const __dirname = dirname(fileURLToPath(import.meta.url));
const templatesDir = join(__dirname, "..", "..", "templates");

export const newCommand = new Command("new")
  .description("Create a new Kaguya project")
  .argument("<name>", "Project name")
  .option("-t, --template <template>", "Template to use", "default")
  .action(async (name: string, options: { template: string }) => {
    const projectDir = join(process.cwd(), name);
    const templateDir = join(templatesDir, options.template);

    // Check if project directory already exists
    if (existsSync(projectDir)) {
      console.error(pc.red(`Error: Directory '${name}' already exists`));
      process.exit(1);
    }

    // Check if template exists
    if (!existsSync(templateDir)) {
      console.error(pc.red(`Error: Template '${options.template}' not found`));
      process.exit(1);
    }

    console.log(pc.cyan(`Creating new Kaguya project: ${name}`));

    try {
      // Copy template
      await cp(templateDir, projectDir, { recursive: true });

      // Update moon.mod.json with project name
      const moonModPath = join(projectDir, "moon.mod.json");
      if (existsSync(moonModPath)) {
        const content = await readFile(moonModPath, "utf-8");
        const updated = content.replace(/"name"\s*:\s*"[^"]*"/, `"name": "${name}"`);
        await writeFile(moonModPath, updated);
      }

      console.log(pc.green(`\n✓ Project created successfully!\n`));
      console.log(`Next steps:`);
      console.log(pc.cyan(`  cd ${name}`));
      console.log(pc.cyan(`  moon update`));
      console.log(pc.cyan(`  kaguya dev`));
    } catch (err) {
      console.error(pc.red(`Error creating project: ${err}`));
      process.exit(1);
    }
  });

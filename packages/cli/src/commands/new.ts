/**
 * kaguya new <name> - Create a new Kaguya project
 */
import { Command } from "commander";
import { mkdir, readFile, writeFile, readdir, stat } from "node:fs/promises";
import { join, dirname, basename } from "node:path";
import { fileURLToPath } from "node:url";
import { existsSync } from "node:fs";
import pc from "picocolors";

const __dirname = dirname(fileURLToPath(import.meta.url));
const templatesDir = join(__dirname, "..", "..", "templates");

/**
 * Copy template directory, removing .template extension from filenames
 * and replacing template variables
 */
async function copyTemplate(
  src: string,
  dest: string,
  variables: Record<string, string> = {}
): Promise<void> {
  await mkdir(dest, { recursive: true });

  const entries = await readdir(src, { withFileTypes: true });

  for (const entry of entries) {
    const srcPath = join(src, entry.name);
    // Remove .template extension if present
    const destName = entry.name.endsWith(".template")
      ? entry.name.slice(0, -9) // Remove ".template" (9 chars)
      : entry.name;
    const destPath = join(dest, destName);

    if (entry.isDirectory()) {
      await copyTemplate(srcPath, destPath, variables);
    } else {
      let content = await readFile(srcPath, "utf-8");
      // Replace template variables
      for (const [key, value] of Object.entries(variables)) {
        content = content.replace(new RegExp(`\\{\\{${key}\\}\\}`, "g"), value);
      }
      await writeFile(destPath, content);
    }
  }
}

export const newCommand = new Command("new")
  .description("Create a new Kaguya project")
  .argument("<name>", "Project name or path")
  .option("-t, --template <template>", "Template to use", "")
  .action(async (name: string, options: { template: string }) => {
    // Support both relative and absolute paths
    const projectDir = name.startsWith("/") ? name : join(process.cwd(), name);
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

    // Use directory name for package name (not full path)
    const packageName = basename(projectDir);
    console.log(pc.cyan(`Creating new Kaguya project: ${projectDir}`));

    try {
      // Template variables for substitution
      const variables = {
        PACKAGE_NAME: packageName,
      };

      // Copy template with .template extension removal and variable substitution
      await copyTemplate(templateDir, projectDir, variables);

      // Update moon.mod.json with project name
      const moonModPath = join(projectDir, "moon.mod.json");
      if (existsSync(moonModPath)) {
        const content = await readFile(moonModPath, "utf-8");
        const updated = content.replace(/"name"\s*:\s*"[^"]*"/, `"name": "${packageName}"`);
        await writeFile(moonModPath, updated);
      }

      // Update package.json with project name
      const packageJsonPath = join(projectDir, "package.json");
      if (existsSync(packageJsonPath)) {
        const content = await readFile(packageJsonPath, "utf-8");
        const updated = content.replace(/"name"\s*:\s*"[^"]*"/, `"name": "${packageName}"`);
        await writeFile(packageJsonPath, updated);
      }

      console.log(pc.green(`\n✓ Project created successfully!\n`));
      console.log(`Next steps:`);
      console.log(pc.cyan(`  cd ${name}`));
      console.log(pc.cyan(`  npm install`));
      console.log(pc.cyan(`  npm run dev`));
    } catch (err) {
      console.error(pc.red(`Error creating project: ${err}`));
      process.exit(1);
    }
  });

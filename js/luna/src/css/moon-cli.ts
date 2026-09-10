import { runCssCommand } from "./command.js";

void runCssCommand(process.argv.slice(2)).catch(error => {
  console.error(`Error: ${error instanceof Error ? error.message : String(error)}`);
  process.exitCode = 1;
});

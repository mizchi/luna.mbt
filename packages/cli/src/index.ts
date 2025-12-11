#!/usr/bin/env node
/**
 * Kaguya CLI - MoonBit Web Framework CLI
 */
import { Command } from "commander";
import { newCommand } from "./commands/new.js";
import { devCommand } from "./commands/dev.js";
import { buildCommand } from "./commands/build.js";
import pc from "picocolors";

const program = new Command();

program
  .name("kaguya")
  .description("CLI for Kaguya MoonBit Web Framework")
  .version("0.1.0");

program.addCommand(newCommand);
program.addCommand(devCommand);
program.addCommand(buildCommand);

program.parse();

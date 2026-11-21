import * as path from "node:path";
import {runTests} from "@vscode/test-electron";

async function main(): Promise<void> {
  const extensionDevelopmentPath = path.resolve(__dirname, "..", "..");
  const workspace = path.resolve(extensionDevelopmentPath, "..");
  await runTests({
    version: process.env.VSCODE_TEST_VERSION ?? "stable",
    extensionDevelopmentPath,
    extensionTestsPath: path.resolve(__dirname, "suite", "index"),
    launchArgs: [workspace, "--disable-extensions", "--disable-workspace-trust"]
  });
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});

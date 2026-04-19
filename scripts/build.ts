import * as fs from 'fs';
import * as path from 'path';
import * as readline from 'readline';
import { execSync } from 'child_process';

const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout
});

const PUBSPEC_PATH = path.join(process.cwd(), 'pubspec.yaml');

async function ask(question: string): Promise<string> {
  return new Promise((resolve) => rl.question(question, resolve));
}

function getVersion(): { name: string, build: number } {
  const content = fs.readFileSync(PUBSPEC_PATH, 'utf8');
  const match = content.match(/^version:\s*([^+]+)\+(\d+)/m);
  if (!match) throw new Error('Could not find version in pubspec.yaml');
  return { name: match[1], build: parseInt(match[2]) };
}

function updateVersion(newName: string, newBuild: number) {
  const content = fs.readFileSync(PUBSPEC_PATH, 'utf8');
  const newContent = content.replace(/^version:.*$/m, `version: ${newName}+${newBuild}`);
  fs.writeFileSync(PUBSPEC_PATH, newContent);
  console.log(`✅ Version updated to: ${newName}+${newBuild}`);
}

async function runBuild() {
  console.log('\n🚀 Mubashir Real Estate Build Automation\n');

  // 1. Version Bumping
  const current = getVersion();
  console.log(`Current Version: ${current.name}+${current.build}`);
  const bump = await ask('Bump version number? (y/n): ');

  if (bump.toLowerCase() === 'y') {
    const nextBuild = current.build + 1;
    updateVersion(current.name, nextBuild);
  }

  // 2. Select App
  console.log('\nSelect App to build:');
  console.log('1. Customer App (lib/main_customer.dart)');
  console.log('2. Admin App (lib/main_admin.dart)');
  console.log('3. Both');
  const appSelection = await ask('Selection (1-3): ');

  // 3. Select Target
  console.log('\nSelect Build Type:');
  console.log('1. APK (Typical for direct install)');
  console.log('2. AppBundle (AAB - Required for Google Play)');
  console.log('3. Both');
  const targetSelection = await ask('Selection (1-3): ');

  const apps = [];
  if (appSelection === '1') apps.push({ name: 'Customer', target: 'lib/main_customer.dart' });
  else if (appSelection === '2') apps.push({ name: 'Admin', target: 'lib/main_admin.dart' });
  else if (appSelection === '3') {
    apps.push({ name: 'Customer', target: 'lib/main_customer.dart' });
    apps.push({ name: 'Admin', target: 'lib/main_admin.dart' });
  }

  const formats = [];
  if (targetSelection === '1') formats.push({ name: 'apk', cmd: 'apk' });
  else if (targetSelection === '2') formats.push({ name: 'aab', cmd: 'appbundle' });
  else if (targetSelection === '3') {
    formats.push({ name: 'apk', cmd: 'apk' });
    formats.push({ name: 'aab', cmd: 'appbundle' });
  }

  // 4. Execute Builds
  for (const app of apps) {
    for (const format of formats) {
      console.log(`\n🔨 Building ${app.name} ${format.name.toUpperCase()}...`);
      try {
        const cmd = `flutter build ${format.cmd} --release -t ${app.target}`;
        console.log(`Running: ${cmd}`);
        execSync(cmd, { stdio: 'inherit' });
        console.log(`✨ Success: ${app.name} ${format.name.toUpperCase()} completed.`);
      } catch (error) {
        console.error(`❌ Failed to build ${app.name} ${format.name.toUpperCase()}`);
      }
    }
  }

  console.log('\n🏁 Build process finished!');
  rl.close();
}

runBuild().catch(console.error);

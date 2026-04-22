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
  const formats = [];
  console.log('\nSelect Build Type:');
  
  if (appSelection === '2') { // Admin specifically
    console.log('1. EXE (Portable)');
    console.log('2. Classic Setup (Next-Next-Finish)');
    console.log('3. All (Portable + Classic Setup)');
    const targetSelection = await ask('Selection (1-3): ');
    
    if (targetSelection === '1' || targetSelection === '3') {
      formats.push({ name: 'portable exe', cmd: 'windows' });
    }
    if (targetSelection === '2' || targetSelection === '3') {
      formats.push({ name: 'classic setup', cmd: 'inno', isFull: true });
    }
  } else { // Customer or Both
    console.log('1. APK (Typical for direct install)');
    console.log('2. AppBundle (AAB - Required for Google Play)');
    console.log('3. EXE (Windows Desktop - Portable)');
    console.log('4. All (Mobile + Windows)');
    const targetSelection = await ask('Selection (1-4): ');

    if (targetSelection === '1') formats.push({ name: 'apk', cmd: 'apk' });
    else if (targetSelection === '2') formats.push({ name: 'aab', cmd: 'appbundle' });
    else if (targetSelection === '3') formats.push({ name: 'exe', cmd: 'windows' });
    else if (targetSelection === '4') {
      formats.push({ name: 'apk', cmd: 'apk' });
      formats.push({ name: 'aab', cmd: 'appbundle' });
      formats.push({ name: 'exe', cmd: 'windows' });
    }
  }

  const apps = [];
  if (appSelection === '1') apps.push({ name: 'Customer', target: 'lib/main_customer.dart' });
  else if (appSelection === '2') apps.push({ name: 'Admin', target: 'lib/main_admin.dart' });
  else if (appSelection === '3') {
    apps.push({ name: 'Customer', target: 'lib/main_customer.dart' });
    apps.push({ name: 'Admin', target: 'lib/main_admin.dart' });
  }

  // 4. Execute Builds
  for (const app of apps) {
    for (const format of formats) {
      console.log(`\n🔨 Building ${app.name} ${format.name.toUpperCase()}...`);
      try {
        let cmd = "";
        if (format.isFull) {
          // Both MSIX and Inno require the windows build to exist first
          console.log(`🔨 Pre-building Windows for Installer...`);
          const preBuildCmd = `flutter build windows --release -t ${app.target}`;
          execSync(preBuildCmd, { stdio: 'inherit' });
          
          if (format.cmd === 'inno') {
            const isccPath = '"C:\\Program Files (x86)\\Inno Setup 6\\ISCC.exe"';
            cmd = `${isccPath} scripts/admin_installer.iss`;
          } else {
            cmd = `flutter ${format.cmd}`;
          }
        } else {
          cmd = `flutter build ${format.cmd} --release -t ${app.target}`;
        }
        
        console.log(`Running: ${cmd}`);
        execSync(cmd, { stdio: 'inherit' });
        console.log(`\n✨ Success: ${app.name} ${format.name.toUpperCase()} completed.`);
        
        if (format.cmd === 'inno') {
          const outPath = path.join(process.cwd(), 'scripts', 'Output', 'MubashirAdmin_Setup.exe');
          console.log(`📍 Setup File: ${outPath}`);
          console.log(`💡 This is your professional "Next-Next-Finish" installer!`);
        } else if (format.cmd === 'windows') {
          const outPath = path.join(process.cwd(), 'build', 'windows', 'x64', 'runner', 'Release');
          console.log(`📍 Standalone Folder: ${outPath}`);
          console.log(`💡 You can zip this folder and send it to any PC to run the app!`);
        }
      } catch (error) {
        console.error(`❌ Failed to build ${app.name} ${format.name.toUpperCase()}`);
      }
    }
  }

  console.log('\n🏁 Build process finished!');
  rl.close();
}

runBuild().catch(console.error);

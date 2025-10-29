/**
 * Script to replace console.log/error with logger calls
 * Run with: node replace_console_logs.js
 */

const fs = require('fs');
const path = require('path');

// Files to process
const filesToProcess = [
  'server.js',
  'routes/users.js',
  'routes/bills.js',
  'routes/sessions.js',
  'routes/transactions.js',
  'routes/contacts.js',
  'jobs/sessionCleanup.js',
  'services/emailService.js'
];

function replaceInFile(filePath) {
  const fullPath = path.join(__dirname, filePath);

  if (!fs.existsSync(fullPath)) {
    console.log(`Skipping ${filePath} - file not found`);
    return;
  }

  let content = fs.readFileSync(fullPath, 'utf8');
  let modified = false;

  // Add logger import if not present
  if (!content.includes("require('./utils/logger')") &&
      !content.includes("require('../utils/logger')")) {

    const loggerPath = filePath.startsWith('routes/') || filePath.startsWith('services/') || filePath.startsWith('jobs/')
      ? "'../utils/logger'"
      : "'./utils/logger'";

    // Add after other requires
    const requireRegex = /(const .+ = require\(.+\);?\n)/;
    if (requireRegex.test(content)) {
      content = content.replace(requireRegex, (match) => {
        // Find last require statement
        const lastRequireIndex = content.lastIndexOf('const ', content.indexOf(match) + match.length + 100);
        if (lastRequireIndex > content.indexOf(match)) {
          return match;
        }
        return match + `const logger = require(${loggerPath});\n`;
      });

      // Better approach: find all requires and insert after the last one
      const lines = content.split('\n');
      let lastRequireLine = -1;

      for (let i = 0; i < lines.length; i++) {
        if (lines[i].includes('require(') && lines[i].includes('const ')) {
          lastRequireLine = i;
        }
      }

      if (lastRequireLine >= 0) {
        lines.splice(lastRequireLine + 1, 0, `const logger = require(${loggerPath});`);
        content = lines.join('\n');
        modified = true;
      }
    }
  }

  // Replace console.log with logger.info
  const logRegex = /console\.log\(/g;
  if (logRegex.test(content)) {
    content = content.replace(/console\.log\(/g, 'logger.info(');
    modified = true;
  }

  // Replace console.error with logger.error
  const errorRegex = /console\.error\(/g;
  if (errorRegex.test(content)) {
    content = content.replace(/console\.error\(/g, 'logger.error(');
    modified = true;
  }

  // Replace console.warn with logger.warn
  const warnRegex = /console\.warn\(/g;
  if (warnRegex.test(content)) {
    content = content.replace(/console\.warn\(/g, 'logger.warn(');
    modified = true;
  }

  if (modified) {
    fs.writeFileSync(fullPath, content, 'utf8');
    console.log(`✓ Updated ${filePath}`);
  } else {
    console.log(`- No changes needed for ${filePath}`);
  }
}

console.log('Starting console.log replacement...\n');

filesToProcess.forEach(file => {
  try {
    replaceInFile(file);
  } catch (error) {
    console.error(`Error processing ${file}:`, error.message);
  }
});

console.log('\nDone! Review the changes and commit.');
console.log('\nReminder: Make sure to create logs/ directory and add it to .gitignore');

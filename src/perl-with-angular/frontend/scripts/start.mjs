import { spawn } from 'node:child_process';

const port = process.env.PORT ?? '4200';
const child = spawn(
  process.execPath,
  [
    'node_modules/@angular/cli/bin/ng.js',
    'serve',
    'web',
    '--host',
    '0.0.0.0',
    '--port',
    port,
  ],
  {
    stdio: 'inherit',
    env: process.env,
  },
);

child.on('exit', (code) => {
  process.exit(code ?? 0);
});
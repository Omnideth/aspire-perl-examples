import { spawn } from 'node:child_process';

const port = process.env.PORT ?? '3000';
const child = spawn(
  process.execPath,
  ['node_modules/next/dist/bin/next', 'dev', '-p', port, '-H', '0.0.0.0'],
  {
    stdio: 'inherit',
    env: process.env,
  },
);

child.on('exit', (code) => {
  process.exit(code ?? 0);
});
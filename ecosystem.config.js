module.exports = {
  apps: [{
    name: 'telega2',
    script: './run.sh',
    cwd: '/home/dima/projects/telega2',
    autorestart: false,
    watch: false,
    output: '/tmp/telega2-out.log',
    error: '/tmp/telega2-err.log',
    merge_logs: true,
  }]
};

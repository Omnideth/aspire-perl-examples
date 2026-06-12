const target = process.env.services__api__http__0
  || process.env.services__api__https__0
  || 'http://localhost:8080';

module.exports = [
  {
    context: ['/api', '/health'],
    target,
    secure: false,
    changeOrigin: true,
  },
];
const express = require('express');
const os = require('os');
const app = express();
const PORT = 3000;

const VERSION = process.env.VERSION || 'undefined';

function getLocalIP() {
  const interfaces = os.networkInterfaces();
  for (const name of Object.keys(interfaces)) {
    for (const iface of interfaces[name]) {
      if (iface.family === 'IPv4' && !iface.internal) {
        return iface.address;
      }
    }
  }
  return '127.0.0.1';
}

app.get('/', (req, res) => {
  const hostname = os.hostname();
  const ip = getLocalIP();
  
  res.send(`
    <html>
      <head>
        <title>Informacje o serwerze</title>
        <style>
          body { font-family: Arial, sans-serif; margin: 40px; line-height: 1.6; }
          h1 { color: #333; }
          .info { background: #f5f5f5; padding: 20px; border-radius: 5px; }
        </style>
      </head>
      <body>
        <h1>Informacje o serwerze</h1>
        <div class="info">
          <p><strong>Adres IP serwera:</strong> ${ip}</p>
          <p><strong>Nazwa serwera (hostname):</strong> ${hostname}</p>
          <p><strong>Wersja aplikacji:</strong> ${VERSION}</p>
        </div>
      </body>
    </html>
  `);
});

app.listen(PORT, () => {
  console.log(`Aplikacja działa na porcie ${PORT}`);
});
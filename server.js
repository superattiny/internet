const ws = require('ws');
const http = require('http');

const wss = new ws.Server({ port: 8080 });
const clients = new Set();

wss.on('connection', s => {
  clients.add(s);
  s.on('close', () => clients.delete(s));
  console.log('CRM ulandi. Jami:', clients.size);
});

http.createServer((req, res) => {
  res.setHeader('Access-Control-Allow-Origin', '*');
  let d = '';
  req.on('data', c => d += c);
  req.on('end', () => {
    console.log('Qongiroq:', d);
    clients.forEach(c => c.readyState === 1 && c.send(d));
    res.end('OK');
  });
}).listen(8081);

console.log('✅ Server ishga tushdi');
console.log('📡 WS:   ws://127.0.0.1:8080');
console.log('📬 HTTP: http://127.0.0.1:8081');

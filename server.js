const ws    = require('ws');
const http  = require('http');
const https = require('https');
const cfg   = require('./config');

// ── SOZLAMALAR ──────────────────────────────────────────────────
const TELEGRAM_TOKEN = cfg.TELEGRAM_TOKEN;
const GEMINI_KEY     = cfg.GEMINI_KEY;

const SYSTEM_PROMPT = `Sen "TV Ta'mirlash Ustaxonasi" uchun aqlli yordamchi botsan.
Vazifang: mijozlar savollariga qisqa, aniq, do'stona javob berish.

Bilimlar:
- TV ta'mirlash: ekran, ovoz, elektron platalar, backlight muammolari
- Narxlar (taxminiy): oddiy ta'mirlash 50-200k, ekran 300-800k, platalar 100-400k so'm
- Muddat: 1-3 ish kuni
- Qabul: har kuni 9:00-18:00

Qoidalar:
- Har doim O'zbek tilida javob ber
- Javobni 3-5 jumladan oshirma
- Manzil so'ralsa: "Operatorimiz siz bilan bog'lanadi" de
- Narx haqida aniq savol bo'lsa taxminiy narx ayt
- Har doim xushmuomala bo'l`;

// ── WEBSOCKET SERVER ────────────────────────────────────────────
const wss = new ws.Server({ port: 8080 });
const clients = new Set();

wss.on('connection', s => {
  clients.add(s);
  console.log(`✅ CRM ulandi (${clients.size} ta)`);

  s.on('close', () => {
    clients.delete(s);
    console.log(`❌ CRM uzildi (${clients.size} ta)`);
  });

  // CRM dan qo'lda javob kelsa
  s.on('message', raw => {
    try {
      const data = JSON.parse(raw);
      if (data.type === 'tg_reply') {
        sendTelegram(data.chatId, data.text);
        console.log(`📤 Qo'lda javob [${data.chatId}]: ${data.text}`);
      }
    } catch(e) {}
  });
});

function broadcast(obj) {
  const str = JSON.stringify(obj);
  clients.forEach(c => c.readyState === 1 && c.send(str));
}

// ── TELEGRAM ────────────────────────────────────────────────────
function sendTelegram(chatId, text) {
  const body = JSON.stringify({
    chat_id: chatId,
    text: text,
    parse_mode: 'HTML'
  });
  const req = https.request({
    hostname: 'api.telegram.org',
    path: `/bot${TELEGRAM_TOKEN}/sendMessage`,
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Content-Length': Buffer.byteLength(body)
    }
  }, res => {
    let d = '';
    res.on('data', c => d += c);
    res.on('end', () => {
      const j = JSON.parse(d);
      if (!j.ok) console.error('Telegram xato:', j.description);
    });
  });
  req.on('error', e => console.error('Telegram error:', e.message));
  req.write(body);
  req.end();
}

// Long polling
let lastId = 0;
function pollTelegram() {
  const req = https.request({
    hostname: 'api.telegram.org',
    path: `/bot${TELEGRAM_TOKEN}/getUpdates?offset=${lastId + 1}&timeout=25`,
    method: 'GET'
  }, res => {
    let data = '';
    res.on('data', c => data += c);
    res.on('end', () => {
      try {
        const json = JSON.parse(data);
        if (json.ok && json.result.length > 0) {
          json.result.forEach(u => {
            lastId = u.update_id;
            handleUpdate(u);
          });
        }
      } catch(e) {
        console.error('Polling parse error:', e.message);
      }
      setTimeout(pollTelegram, 500);
    });
  });
  req.on('error', e => {
    console.error('Polling error:', e.message);
    setTimeout(pollTelegram, 5000);
  });
  req.end();
}

function handleUpdate(u) {
  if (!u.message) return;
  const msg      = u.message;
  const chatId   = msg.chat.id;
  const text     = msg.text || '';
  const from     = msg.from.first_name + (msg.from.last_name ? ' ' + msg.from.last_name : '');
  const username = msg.from.username || '';
  const source   = msg.chat.type === 'private' ? 'telegram' : 'telegram_group';

  if (!text) return;

  console.log(`\n📩 [${from}${username ? ' @' + username : ''}]: ${text}`);

  // CRM ga xabar yuborish
  broadcast({
    type:     'tg_message',
    chatId:   String(chatId),
    from,
    username,
    text,
    source,
    date: new Date().toISOString()
  });

  // AI javob berish uchun yuborish
  askGemini(text, chatId, from);
}

// ── GEMINI AI ───────────────────────────────────────────────────
const chatHistories = {}; // chatId → messages[]

function askGemini(userText, chatId, fromName) {
  if (!chatHistories[chatId]) chatHistories[chatId] = [];

  chatHistories[chatId].push({
    role: 'user',
    parts: [{ text: userText }]
  });

  // Oxirgi 10 ta xabar (context uchun)
  const contents = chatHistories[chatId].slice(-10);

  const body = JSON.stringify({
    system_instruction: { parts: [{ text: SYSTEM_PROMPT }] },
    contents
  });

  let responseData = '';
  const req = https.request({
    hostname: 'generativelanguage.googleapis.com',
    path: `/v1beta/models/gemini-1.5-flash:generateContent?key=${GEMINI_KEY}`,
    method: 'POST',
    headers: { 'Content-Type': 'application/json' }
  }, res => {
    res.on('data', c => responseData += c);
    res.on('end', () => {
      try {
        const json  = JSON.parse(responseData);
        const reply = json.candidates?.[0]?.content?.parts?.[0]?.text;

        if (!reply) {
          console.error('Gemini bo\'sh javob:', responseData.slice(0, 300));
          return;
        }

        // Tarixga qo'shish
        chatHistories[chatId].push({
          role: 'model',
          parts: [{ text: reply }]
        });

        // Telegram ga yuborish
        sendTelegram(chatId, reply);

        // CRM ga yuborish
        broadcast({
          type:   'tg_bot_reply',
          chatId: String(chatId),
          text:   reply,
          date:   new Date().toISOString()
        });

        console.log(`🤖 AI → [${fromName}]: ${reply.slice(0, 80)}...`);

      } catch(e) {
        console.error('Gemini parse error:', e.message);
        console.error('Response:', responseData.slice(0, 300));
      }
    });
  });

  req.on('error', e => console.error('Gemini error:', e.message));
  req.write(body);
  req.end();
}

// ── HTTP (qo'ng'iroq uchun) ─────────────────────────────────────
http.createServer((req, res) => {
  res.setHeader('Access-Control-Allow-Origin', '*');
  let d = '';
  req.on('data', c => d += c);
  req.on('end', () => {
    broadcast({ type: 'call', number: d });
    res.end('OK');
  });
}).listen(8081);

// ── START ───────────────────────────────────────────────────────
console.log('\n╔════════════════════════════════════╗');
console.log('║   TV CRM Server ishga tushdi! 🚀   ║');
console.log('╠════════════════════════════════════╣');
console.log('║ 📡 WS:   ws://127.0.0.1:8080       ║');
console.log('║ 📬 HTTP: http://127.0.0.1:8081     ║');
console.log('║ 🤖 Telegram bot: FAOL              ║');
console.log('║ 🧠 Gemini AI:    FAOL              ║');
console.log('╚════════════════════════════════════╝\n');

pollTelegram();

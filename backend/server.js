/**
 * ================================================================
 *  TV CRM — WebSocket + Telegram Bot + Gemini AI Server
 *  
 *  Ishga tushirish:
 *    npm install
 *    node server.js
 *  
 *  Yoki avtomatik qayta ishga tushirish uchun:
 *    npm run dev
 * ================================================================
 */

const WebSocket = require('ws');
const TelegramBot = require('node-telegram-bot-api');
require('dotenv').config({ path: '.env' });

// ── Konfiguratsiya ────────────────────────────────────────────
const PORT            = parseInt(process.env.WS_PORT || '8080');
const TG_TOKEN        = process.env.TELEGRAM_BOT_TOKEN || '';
const TG_ADMIN_CHAT   = process.env.TELEGRAM_ADMIN_CHAT_ID || '';
const GEMINI_KEY      = process.env.GEMINI_API_KEY || '';
const AUTO_REPLY      = process.env.AUTO_REPLY_ENABLED === 'true';
const SHOP_NAME       = process.env.SHOP_NAME || "TV Ta'mirlash Ustaxonasi";

// ── Ranglar (console log uchun) ───────────────────────────────
const C = {
  green:  (s) => `\x1b[32m${s}\x1b[0m`,
  red:    (s) => `\x1b[31m${s}\x1b[0m`,
  yellow: (s) => `\x1b[33m${s}\x1b[0m`,
  cyan:   (s) => `\x1b[36m${s}\x1b[0m`,
  bold:   (s) => `\x1b[1m${s}\x1b[0m`,
};

const log = (icon, msg) => console.log(`${icon} [${new Date().toLocaleTimeString('uz-UZ')}] ${msg}`);

// ================================================================
//  1. WEBSOCKET SERVER (CRM bilan muloqot)
// ================================================================
const wss = new WebSocket.Server({ port: PORT });
const crmClients = new Set();

wss.on('connection', (ws) => {
  crmClients.add(ws);
  log('📡', C.green(`CRM ulandi. Jami: ${crmClients.size} ta`));

  // CRM dan kelgan xabarlarni qayta ishlash
  ws.on('message', async (rawData) => {
    try {
      const msg = JSON.parse(rawData.toString());

      // CRM → Telegram javob
      if (msg.type === 'tg_reply') {
        log('✈️', `CRM javob → Telegram [${msg.chatId}]: ${(msg.text||'').slice(0,60)}`);
        await sendToTelegram(msg.chatId, msg.text);
      }

      // CRM → Hammaga broadcast (masalan, yangi buyurtma bildirishnomasi)
      if (msg.type === 'broadcast') {
        broadcastToCRM(msg.data, ws);
      }

    } catch (e) {
      log('⚠️', 'WS xabar parse xatosi: ' + e.message);
    }
  });

  ws.on('close', () => {
    crmClients.delete(ws);
    log('📡', `CRM uzildi. Jami: ${crmClients.size} ta`);
  });

  ws.on('error', (err) => {
    log('❌', 'WS xato: ' + err.message);
    crmClients.delete(ws);
  });
});

/**
 * Barcha ulangan CRM larga xabar yuborish
 * sender — o'zi yubormagan tomon (ixtiyoriy)
 */
function broadcastToCRM(data, sender = null) {
  const json = JSON.stringify(data);
  let count = 0;
  crmClients.forEach((ws) => {
    if (ws !== sender && ws.readyState === WebSocket.OPEN) {
      ws.send(json);
      count++;
    }
  });
  return count;
}

// ================================================================
//  2. TELEGRAM BOT
// ================================================================
let bot = null;

if (!TG_TOKEN) {
  log('⚠️', C.yellow('Telegram token yo\'q! .env da TELEGRAM_BOT_TOKEN ni sozlang.'));
} else {
  bot = new TelegramBot(TG_TOKEN, {
    polling: {
      interval: 1000,
      autoStart: true,
      params: { timeout: 10 }
    }
  });

  // Bot tayyor bo'lganda
  bot.getMe().then((info) => {
    log('🤖', C.green(`Telegram bot: @${info.username} (id: ${info.id})`));
  }).catch((e) => {
    log('❌', C.red('Telegram token noto\'g\'ri: ' + e.message));
  });

  // ── Xabar keldi ──────────────────────────────────────────────
  bot.on('message', async (msg) => {
    const chatId   = String(msg.chat.id);
    const text     = msg.text || '';
    const from     = [msg.chat.first_name, msg.chat.last_name].filter(Boolean).join(' ')
                     || msg.chat.username || 'Noma\'lum';
    const username = msg.chat.username || '';
    const msgDate  = new Date(msg.date * 1000).toISOString();

    log('📩', `[${from}${username ? ' @' + username : ''}]: ${text.slice(0, 80)}`);

    // /start buyrug'i — avtomatik javob
    if (text === '/start') {
      await sendToTelegram(chatId,
        `👋 Salom, <b>${from}</b>!\n\n` +
        `📺 <b>${SHOP_NAME}</b>ga xush kelibsiz!\n\n` +
        `TV yoki monitor nosoz bo'lsa, shunchaki muammoni yozing.\n` +
        `Masalan: <i>Samsung TV ekrani yonmayapti</i>\n\n` +
        `Biz tez orada bog'lanamiz! 📞`
      );
      return;
    }

    // /status buyrug'i
    if (text.startsWith('/status')) {
      await sendToTelegram(chatId,
        `📋 Zakazingiz holati haqida so'rash uchun\n` +
        `zakaz raqamingizni yuboring:\n` +
        `Masalan: <code>TV-2025-0001</code>`
      );
      return;
    }

    // /help buyrug'i
    if (text === '/help') {
      await sendToTelegram(chatId,
        `ℹ️ <b>Yordam</b>\n\n` +
        `/start — Boshlash\n` +
        `/status — Zakaz holati\n\n` +
        `Muammongizni yozsangiz, ustalarimiz javob beradi! 🔧`
      );
      return;
    }

    // ── CRM ga yuborish ──────────────────────────────────────
    const crmCount = broadcastToCRM({
      type:     'tg_message',
      chatId,
      text,
      from,
      username,
      source:   'telegram',
      date:     msgDate,
    });

    log('📡', `CRM ga yuborildi (${crmCount} ta mijoz)`);

    // ── Gemini AI avtomatik javob ─────────────────────────────
    if (AUTO_REPLY && text && !text.startsWith('/')) {
      await autoReplyWithAI(chatId, from, text);
    }
  });

  // Polling xatolarini tutish
  bot.on('polling_error', (err) => {
    if (err.code === 'ETELEGRAM') {
      log('⚠️', 'Telegram API xato: ' + (err.response?.body?.description || err.message));
    }
  });
}

/**
 * Telegram ga xabar yuborish va CRM ga ham qaytarish
 */
async function sendToTelegram(chatId, text, options = {}) {
  if (!bot) return false;
  try {
    await bot.sendMessage(chatId, text, {
      parse_mode: 'HTML',
      ...options
    });

    // CRM ga ham ko'rsatish (bot javobini)
    broadcastToCRM({
      type:   'tg_bot_reply',
      chatId,
      text,
      date:   new Date().toISOString(),
    });

    log('✅', `Yuborildi → [${chatId}]: ${text.slice(0, 60)}`);
    return true;
  } catch (e) {
    log('❌', `Telegram yuborish xatosi [${chatId}]: ${e.message}`);
    return false;
  }
}

// ================================================================
//  3. GEMINI AI — Avtomatik javob
// ================================================================
let geminiModel = null;

if (!GEMINI_KEY) {
  log('⚠️', C.yellow('Gemini API key yo\'q! .env da GEMINI_API_KEY ni sozlang.'));
} else {
  try {
    const { GoogleGenerativeAI } = require('@google/generative-ai');
    const genAI = new GoogleGenerativeAI(GEMINI_KEY);
    geminiModel = genAI.getGenerativeModel({
      model: 'gemini-1.5-flash',
      generationConfig: {
        temperature:    0.7,
        maxOutputTokens: 256,
      }
    });
    log('🧠', C.green('Gemini AI tayyor (gemini-1.5-flash)'));
  } catch (e) {
    log('⚠️', 'Gemini yuklanmadi: ' + e.message);
  }
}

/**
 * Gemini AI bilan avtomatik javob
 */
async function autoReplyWithAI(chatId, fromName, userText) {
  if (!geminiModel) return;

  try {
    const prompt =
      `Sen "${SHOP_NAME}" ustaxonasining yordamchi botisan (Uzbek tilida yozasan).\n` +
      `Mijoz ismi: ${fromName}\n` +
      `Mijoz xabari: "${userText}"\n\n` +
      `Qoidalar:\n` +
      `- Qisqa va do'stona javob ber (2-3 jumla)\n` +
      `- Texnik muammo haqida so'rasa — ustaxonaga olib kelishni tavsiya qil\n` +
      `- Narx so'rasa — "Ko'rib chiqqandan keyin aytamiz, taxminan 50,000-500,000 so'm" de\n` +
      `- Vaqt so'rasa — "1-3 ish kuni" de\n` +
      `- Emoji ishlatma\n` +
      `- Hech qachon yolg'on ma'lumot berma`;

    const result = await geminiModel.generateContent(prompt);
    const aiText = result.response.text().trim();

    if (aiText) {
      await sendToTelegram(chatId, `🤖 ${aiText}`);
      log('🧠', `AI javob [${chatId}]: ${aiText.slice(0, 60)}`);
    }
  } catch (e) {
    log('⚠️', 'Gemini xato: ' + e.message);
  }
}

// ================================================================
//  4. ADMIN BILDIRISHNOMALAR
// ================================================================

/**
 * Admin ga tizim holati haqida xabar yuborish
 */
async function notifyAdmin(text) {
  if (!TG_ADMIN_CHAT || !bot) return;
  await sendToTelegram(TG_ADMIN_CHAT, text);
}

// Server ishga tushganda admin ga xabar
if (TG_ADMIN_CHAT) {
  setTimeout(() => {
    notifyAdmin(
      `✅ <b>TV CRM Server ishga tushdi!</b>\n\n` +
      `📡 WebSocket: port ${PORT}\n` +
      `🤖 Telegram bot: ulangan\n` +
      `🧠 Gemini AI: ${geminiModel ? 'faol' : 'sozlanmagan'}\n` +
      `🕐 ${new Date().toLocaleString('uz-UZ')}`
    );
  }, 3000);
}

// ================================================================
//  STARTUP XABARI
// ================================================================
console.log('\n' + '='.repeat(55));
console.log(C.bold(`  📺 ${SHOP_NAME}`));
console.log(C.bold('  WebSocket + Telegram + Gemini AI Server'));
console.log('='.repeat(55));
console.log(`  📡 WebSocket:   ${C.green('ws://127.0.0.1:' + PORT)}`);
console.log(`  🤖 Telegram:    ${TG_TOKEN ? C.green('Ulangan ✅') : C.red('Token yo\'q ❌')}`);
console.log(`  🧠 Gemini AI:   ${GEMINI_KEY ? C.green('Tayyor ✅') : C.yellow('Key yo\'q ⚠️')}`);
console.log(`  🔄 Auto-javob:  ${AUTO_REPLY ? C.green('Yoqilgan ✅') : C.yellow('O\'chirilgan')}`);
console.log('='.repeat(55) + '\n');

#!/usr/bin/env python3
"""
Lightweight Ollama Chat UI
Zero dependencies — pure Python stdlib only
Runs on port 8080, proxies to Ollama on 11434
"""

from http.server import HTTPServer, BaseHTTPRequestHandler
import urllib.request
import json
import threading

PORT = 8080
OLLAMA = "http://localhost:11434"

HTML = b"""<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>AI Node</title>
<style>
  *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }

  body {
    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
    background: #111;
    color: #e8e8e8;
    height: 100dvh;
    display: flex;
    flex-direction: column;
    overflow: hidden;
  }

  header {
    padding: 12px 16px;
    background: #1c1c1e;
    border-bottom: 1px solid #2c2c2e;
    display: flex;
    align-items: center;
    justify-content: space-between;
    flex-shrink: 0;
  }

  header h1 {
    font-size: 15px;
    font-weight: 600;
    color: #fff;
    letter-spacing: 0.3px;
  }

  #status {
    font-size: 11px;
    color: #30d158;
    display: flex;
    align-items: center;
    gap: 5px;
  }

  #status::before {
    content: '';
    width: 7px;
    height: 7px;
    background: #30d158;
    border-radius: 50%;
    display: inline-block;
  }

  #status.offline { color: #ff453a; }
  #status.offline::before { background: #ff453a; }

  .model-bar {
    padding: 8px 16px;
    background: #1c1c1e;
    border-bottom: 1px solid #2c2c2e;
    display: flex;
    align-items: center;
    gap: 8px;
    flex-shrink: 0;
  }

  .model-bar label { font-size: 12px; color: #888; }

  select {
    background: #2c2c2e;
    color: #e8e8e8;
    border: 1px solid #3a3a3c;
    border-radius: 8px;
    padding: 5px 10px;
    font-size: 13px;
    flex: 1;
    max-width: 280px;
  }

  #clear-btn {
    margin-left: auto;
    background: none;
    border: 1px solid #3a3a3c;
    color: #888;
    border-radius: 8px;
    padding: 5px 10px;
    font-size: 12px;
    cursor: pointer;
  }

  #messages {
    flex: 1;
    overflow-y: auto;
    padding: 16px;
    display: flex;
    flex-direction: column;
    gap: 14px;
  }

  .msg-wrap {
    display: flex;
    flex-direction: column;
    gap: 3px;
  }

  .msg-wrap.user { align-items: flex-end; }
  .msg-wrap.assistant { align-items: flex-start; }

  .role-label {
    font-size: 10px;
    color: #555;
    padding: 0 4px;
    text-transform: uppercase;
    letter-spacing: 0.5px;
  }

  .bubble {
    max-width: 82%;
    padding: 10px 14px;
    border-radius: 18px;
    font-size: 14px;
    line-height: 1.55;
    white-space: pre-wrap;
    word-break: break-word;
  }

  .user .bubble {
    background: #0a84ff;
    color: #fff;
    border-bottom-right-radius: 5px;
  }

  .assistant .bubble {
    background: #1c1c1e;
    border: 1px solid #2c2c2e;
    color: #e8e8e8;
    border-bottom-left-radius: 5px;
  }

  .thinking .bubble {
    color: #555;
    font-style: italic;
    background: #1c1c1e;
    border: 1px solid #2c2c2e;
    animation: pulse 1.4s ease-in-out infinite;
  }

  @keyframes pulse {
    0%, 100% { opacity: 0.6; }
    50% { opacity: 1; }
  }

  footer {
    padding: 10px 12px;
    background: #1c1c1e;
    border-top: 1px solid #2c2c2e;
    display: flex;
    gap: 8px;
    align-items: flex-end;
    flex-shrink: 0;
  }

  textarea {
    flex: 1;
    background: #2c2c2e;
    color: #e8e8e8;
    border: 1px solid #3a3a3c;
    border-radius: 14px;
    padding: 10px 14px;
    font-size: 14px;
    resize: none;
    min-height: 44px;
    max-height: 130px;
    font-family: inherit;
    line-height: 1.4;
    overflow-y: auto;
  }

  textarea::placeholder { color: #555; }
  textarea:focus { outline: none; border-color: #0a84ff; }

  #send-btn {
    background: #0a84ff;
    color: #fff;
    border: none;
    border-radius: 50%;
    width: 44px;
    height: 44px;
    font-size: 20px;
    cursor: pointer;
    display: flex;
    align-items: center;
    justify-content: center;
    flex-shrink: 0;
    transition: opacity 0.15s;
  }

  #send-btn:disabled { opacity: 0.35; cursor: default; }

  .empty-state {
    flex: 1;
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    color: #444;
    gap: 8px;
    text-align: center;
    padding: 32px;
  }

  .empty-state .icon { font-size: 48px; }
  .empty-state p { font-size: 14px; }
</style>
</head>
<body>

<header>
  <h1>AI Node</h1>
  <span id="status">Ollama</span>
</header>

<div class="model-bar">
  <label>Model</label>
  <select id="model-sel"><option value="">Loading...</option></select>
  <button id="clear-btn">Clear</button>
</div>

<div id="messages">
  <div class="empty-state" id="empty">
    <div class="icon">&#129302;</div>
    <p>Your pocket AI is ready.<br>Ask it anything.</p>
  </div>
</div>

<footer>
  <textarea id="input" placeholder="Message..." rows="1"></textarea>
  <button id="send-btn" disabled>&#8593;</button>
</footer>

<script>
const msgsEl   = document.getElementById('messages');
const inputEl  = document.getElementById('input');
const sendBtn  = document.getElementById('send-btn');
const modelSel = document.getElementById('model-sel');
const statusEl = document.getElementById('status');
const emptyEl  = document.getElementById('empty');
const clearBtn = document.getElementById('clear-btn');

let history = [];
let busy = false;

// Load models
fetch('/api/tags')
  .then(r => r.json())
  .then(data => {
    const models = data.models || [];
    if (models.length === 0) {
      modelSel.innerHTML = '<option value="">No models — run: ollama pull phi3:mini</option>';
      return;
    }
    modelSel.innerHTML = models.map(m =>
      `<option value="${m.name}">${m.name}</option>`
    ).join('');
    sendBtn.disabled = false;
    statusEl.textContent = 'Ollama';
    statusEl.className = '';
  })
  .catch(() => {
    statusEl.textContent = 'Ollama offline';
    statusEl.className = 'offline';
    modelSel.innerHTML = '<option value="">Ollama not reachable</option>';
  });

function addBubble(role, text, isThinking) {
  if (emptyEl) emptyEl.remove();
  const wrap = document.createElement('div');
  wrap.className = 'msg-wrap ' + role + (isThinking ? ' thinking' : '');
  const label = document.createElement('div');
  label.className = 'role-label';
  label.textContent = role === 'user' ? 'You' : 'AI';
  const bubble = document.createElement('div');
  bubble.className = 'bubble';
  bubble.textContent = text;
  wrap.appendChild(label);
  wrap.appendChild(bubble);
  msgsEl.appendChild(wrap);
  msgsEl.scrollTop = msgsEl.scrollHeight;
  return { wrap, bubble };
}

async function send() {
  const text = inputEl.value.trim();
  if (!text || busy || !modelSel.value) return;

  busy = true;
  sendBtn.disabled = true;
  inputEl.value = '';
  inputEl.style.height = 'auto';

  history.push({ role: 'user', content: text });
  addBubble('user', text, false);

  const { wrap, bubble } = addBubble('assistant', 'Thinking...', true);

  try {
    const res = await fetch('/api/chat', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        model: modelSel.value,
        messages: history
      })
    });

    const data = await res.json();

    if (data.error) {
      bubble.textContent = 'Error: ' + data.error;
      wrap.classList.remove('thinking');
      history.pop();
    } else {
      const reply = data.message?.content || '';
      wrap.classList.remove('thinking');
      bubble.textContent = reply;
      history.push({ role: 'assistant', content: reply });
    }
  } catch (e) {
    wrap.classList.remove('thinking');
    bubble.textContent = 'Connection error: ' + e.message;
    history.pop();
  }

  msgsEl.scrollTop = msgsEl.scrollHeight;
  busy = false;
  sendBtn.disabled = false;
  inputEl.focus();
}

sendBtn.onclick = send;

inputEl.addEventListener('keydown', e => {
  if (e.key === 'Enter' && !e.shiftKey) {
    e.preventDefault();
    send();
  }
});

inputEl.addEventListener('input', () => {
  inputEl.style.height = 'auto';
  inputEl.style.height = Math.min(inputEl.scrollHeight, 130) + 'px';
});

clearBtn.onclick = () => {
  history = [];
  msgsEl.innerHTML = '';
  const empty = document.createElement('div');
  empty.className = 'empty-state';
  empty.id = 'empty';
  empty.innerHTML = '<div class="icon">&#129302;</div><p>Your pocket AI is ready.<br>Ask it anything.</p>';
  msgsEl.appendChild(empty);
};
</script>
</body>
</html>
"""


class ChatHandler(BaseHTTPRequestHandler):
    def log_message(self, fmt, *args):
        pass  # silence request logs

    def do_GET(self):
        if self.path in ('/', '/index.html'):
            self._reply(200, 'text/html; charset=utf-8', HTML)

        elif self.path == '/api/tags':
            try:
                with urllib.request.urlopen(f"{OLLAMA}/api/tags", timeout=5) as r:
                    self._reply(200, 'application/json', r.read())
            except Exception as e:
                self._reply(502, 'application/json',
                            json.dumps({'error': str(e)}).encode())
        else:
            self._reply(404, 'text/plain', b'Not found')

    def do_POST(self):
        if self.path == '/api/chat':
            length = int(self.headers.get('Content-Length', 0))
            body = self.rfile.read(length)
            try:
                data = json.loads(body)
                data['stream'] = False  # collect full response, simpler on Android
                req = urllib.request.Request(
                    f"{OLLAMA}/api/chat",
                    data=json.dumps(data).encode(),
                    headers={'Content-Type': 'application/json'}
                )
                with urllib.request.urlopen(req, timeout=180) as r:
                    self._reply(200, 'application/json', r.read())
            except Exception as e:
                self._reply(502, 'application/json',
                            json.dumps({'error': str(e)}).encode())
        else:
            self._reply(404, 'text/plain', b'Not found')

    def _reply(self, code, ctype, body):
        self.send_response(code)
        self.send_header('Content-Type', ctype)
        self.send_header('Content-Length', str(len(body)))
        self.send_header('Access-Control-Allow-Origin', '*')
        self.end_headers()
        self.wfile.write(body)


class ThreadedServer(HTTPServer):
    """Handle each request in its own thread."""
    def process_request(self, request, client_address):
        t = threading.Thread(
            target=self._handle,
            args=(request, client_address),
            daemon=True
        )
        t.start()

    def _handle(self, request, client_address):
        self.finish_request(request, client_address)
        self.shutdown_request(request)


if __name__ == '__main__':
    server = ThreadedServer(('0.0.0.0', PORT), ChatHandler)
    print(f'[+] Chat UI running → http://0.0.0.0:{PORT}')
    server.serve_forever()

// Browser smoke test against controlled API responses; no database or external accounts.
// Run after `npm --prefix admin run build`. Uses an installed Chromium browser.
const fs = require('node:fs');
const path = require('node:path');
const http = require('node:http');
const { spawn } = require('node:child_process');
const assert = require('node:assert/strict');
const root = path.resolve(__dirname, '..');
const output = path.join(root, 'artifacts', 'admin-check');
fs.mkdirSync(output, { recursive: true });
const browserPath = [process.env.BROWSER_PATH,
  'C:/Program Files/Google/Chrome/Application/chrome.exe',
  'C:/Program Files (x86)/Microsoft/Edge/Application/msedge.exe',
].find(p => p && fs.existsSync(p));
assert(browserPath, 'Set BROWSER_PATH to an installed Chromium browser.');
const mime = { '.html': 'text/html', '.js': 'application/javascript', '.css': 'text/css', '.svg': 'image/svg+xml' };
const server = http.createServer((req, res) => {
  const relative = decodeURIComponent(new URL(req.url, 'http://localhost').pathname).replace(/^\/+/, '') || 'index.html';
  const target = path.resolve(root, 'admin/dist', relative);
  if (!target.startsWith(path.join(root, 'admin/dist') + path.sep)) { res.writeHead(403); res.end(); return; }
  if (!fs.existsSync(target) || fs.statSync(target).isDirectory()) { res.writeHead(404); res.end(); return; }
  res.setHeader('Content-Type', mime[path.extname(target)] || 'application/octet-stream');
  fs.createReadStream(target).pipe(res);
});
const delay = ms => new Promise(r => setTimeout(r, ms));
let child, ws;
const pending = new Map();
let sequence = 0;
function command(method, params = {}) {
  return new Promise((resolve, reject) => {
    const id = ++sequence;
    const timer = setTimeout(() => { pending.delete(id); reject(new Error(`CDP timeout: ${method}`)); }, 15000);
    pending.set(id, { resolve: v => { clearTimeout(timer); resolve(v); }, reject: e => { clearTimeout(timer); reject(e); } });
    ws.send(JSON.stringify({ id, method, params }));
  });
}
async function evaluate(expression) {
  const result = await command('Runtime.evaluate', { expression, returnByValue: true, awaitPromise: true });
  if (result.exceptionDetails) throw new Error(JSON.stringify(result.exceptionDetails));
  return result.result.value;
}
async function until(expression) {
  for (let i = 0; i < 100; i++) { if (await evaluate(expression)) return; await delay(100); }
  throw new Error(`UI timeout: ${expression}`);
}
const button = text => `Array.from(document.querySelectorAll('button')).find(b => b.textContent.trim() === ${JSON.stringify(text)})`;
async function click(text) { await evaluate(`${button(text)}.click()`); }
async function fill(selector, value) {
  await evaluate(`(() => { const el = document.querySelector(${JSON.stringify(selector)}); const prototype = el.tagName === 'TEXTAREA' ? HTMLTextAreaElement.prototype : el.tagName === 'SELECT' ? HTMLSelectElement.prototype : HTMLInputElement.prototype; Object.getOwnPropertyDescriptor(prototype, 'value').set.call(el, ${JSON.stringify(value)}); el.dispatchEvent(new Event(el.tagName === 'SELECT' ? 'change' : 'input', {bubbles: true})); })()`);
}
const fixture = `(() => {
  const categories = [{id: 1, name: 'Vías públicas', slug: 'vias', description: 'Daños en calles y vías.', iconName: 'road', colorHex: '#31748F', displayOrder: 1}];
  const post = {id: 'post-1', userId: 'user-1', authorUsername: 'vecino', categoryId: 1, categoryName: 'Vías públicas', categoryColor: '#31748F', title: 'Bache en la avenida principal', description: 'Incidencia de prueba para revisar el panel.', province: 'Distrito Nacional', municipality: 'Santo Domingo', latitude: 18.48, longitude: -69.93, status: 'Active', viewsCount: 12, reactionsCount: 3, images: [], createdAt: '2026-09-28T12:00:00Z'};
  let reports = [{id: 'report-1', postId: post.id, postTitle: post.title, reporterUsername: 'ciudadano', reason: 'UbicacionIncorrecta', description: 'Revisar la referencia.', status: 'Pending', createdAt: post.createdAt}];
  window.__calls = [];
  window.fetch = async (url, options = {}) => {
    const u = new URL(url, location.href); const route = u.pathname; const data = options.body ? JSON.parse(options.body) : {};
    window.__calls.push({route, method: options.method || 'GET', data});
    let result;
    if (route === '/api/auth/login') result = {username: 'Moderación RD', email: 'admin@example.test', roles: ['Administrador'], accessToken: 'fixture-access', refreshToken: 'fixture-refresh'};
    else if (route === '/api/auth/logout') result = true;
    else if (route === '/api/management/stats') result = {totalPosts: 148, activePosts: 92, resolvedPosts: 56, totalViews: 624, totalReactions: 301, pendingReports: reports.length};
    else if (route === '/api/management/posts') result = {items: [post], totalCount: 1, pageNumber: 1, pageSize: 20};
    else if (route === '/api/management/posts/post-1') result = post;
    else if (route === '/api/management/posts/post-1/status') { post.status = data.status; result = true; }
    else if (route === '/api/categories' && options.method === 'POST') { categories.push({...data, id: 2}); result = categories.at(-1); }
    else if (route === '/api/categories') result = categories;
    else if (route === '/api/moderation/reports') result = {items: reports, totalCount: reports.length, pageNumber: 1, pageSize: 20};
    else if (route === '/api/moderation/reports/report-1/resolve') { reports = []; result = true; }
    else return new Response(JSON.stringify({success: false, message: 'Unexpected test route'}), {status: 404});
    return new Response(JSON.stringify({success: true, data: result}), {status: 200, headers: {'Content-Type': 'application/json'}});
  };
})();`;

(async () => {
  await new Promise(r => server.listen(0, '127.0.0.1', r));
  const profile = fs.mkdtempSync(path.join(output, 'profile-'));
  child = spawn(browserPath, ['--headless=new', '--disable-gpu', '--no-first-run', '--no-default-browser-check', '--remote-debugging-port=0', `--user-data-dir=${profile}`, 'about:blank'], {windowsHide: true, stdio: 'ignore'});
  const portFile = path.join(profile, 'DevToolsActivePort');
  for (let i = 0; i < 100 && !fs.existsSync(portFile); i++) await delay(100);
  assert(fs.existsSync(portFile), 'Browser did not start.');
  const port = fs.readFileSync(portFile, 'utf8').split('\n')[0];
  const tabs = await (await fetch(`http://127.0.0.1:${port}/json/list`)).json();
  ws = new WebSocket(tabs.find(t => t.type === 'page').webSocketDebuggerUrl);
  ws.addEventListener('message', event => {
    const message = JSON.parse(event.data); const wait = pending.get(message.id);
    if (wait) { pending.delete(message.id); message.error ? wait.reject(new Error(JSON.stringify(message.error))) : wait.resolve(message.result); }
  });
  await new Promise((resolve, reject) => { ws.addEventListener('open', resolve, {once:true}); ws.addEventListener('error', reject, {once:true}); });
  await command('Page.enable');
  await command('Emulation.setDeviceMetricsOverride', {width: 1440, height: 1000, deviceScaleFactor: 1, mobile: false});
  await command('Page.addScriptToEvaluateOnNewDocument', {source: fixture});
  await command('Page.navigate', {url: `http://127.0.0.1:${server.address().port}`});
  await until(`!!document.querySelector('input[type=email]')`);
  await fill('input[type=email]', 'admin@example.test'); await fill('input[type=password]', 'test-password');
  await evaluate(`document.querySelector('form').requestSubmit()`);
  await until(`document.body.textContent.includes('148') && !document.body.textContent.includes('Cargando información')`);
  fs.writeFileSync(path.join(output, 'dashboard.png'), Buffer.from((await command('Page.captureScreenshot')).data, 'base64'));
  await click('Publicaciones'); await until(`!!document.querySelector('input[aria-label="Buscar publicaciones"]') && !document.body.textContent.includes('Cargando información')`);
  await fill('input[aria-label="Buscar publicaciones"]', 'Bache'); await click('Buscar');
  await until(`!document.body.textContent.includes('Cargando información')`);
  await click('Ver detalle'); await fill('.modal select', 'Resolved');
  await until(`window.__calls.some(c => c.data.status === 'Resolved')`);
  await until(`!document.querySelector('[aria-label="Cerrar detalle"]').disabled`);
  assert(await evaluate(`document.querySelector('dialog').contains(document.activeElement)`), 'Dialog must contain keyboard focus.');
  await click(''); // close button has an accessible label and no text
  await until(`!document.querySelector('.modal') && !document.body.textContent.includes('Cargando información')`);
  await click('Moderación'); await until(`!!${button('Ocultar publicación')} && !document.body.textContent.includes('Cargando información')`);
  await click('Bache en la avenida principal');
  await until(`!!document.querySelector('dialog[open]') && !document.querySelector('[aria-label="Cerrar detalle"]').disabled`);
  await command('Input.dispatchKeyEvent', {type: 'keyDown', key: 'Escape', code: 'Escape', windowsVirtualKeyCode: 27});
  await command('Input.dispatchKeyEvent', {type: 'keyUp', key: 'Escape', code: 'Escape', windowsVirtualKeyCode: 27});
  await until(`!document.querySelector('dialog')`);
  await click('Ocultar publicación'); await fill('.modal textarea', 'Revisado durante la prueba.'); await click('Confirmar resolución');
  await until(`document.body.textContent.includes('No hay denuncias pendientes')`);
  assert(await evaluate(`window.__calls.some(c => c.data.hidePost === true && c.data.status === 'ActionTaken')`));
  await click('Categorías'); await until(`!!${button('Nueva categoría')} && !document.body.textContent.includes('Cargando información')`);
  await click('Nueva categoría'); await fill('.modal input[maxlength="50"]', 'Alumbrado'); await fill('.modal input[maxlength="60"]', 'alumbrado');
  await click('Guardar'); await until(`!document.querySelector('.modal') && document.body.textContent.includes('Alumbrado')`);
  await click('Cerrar sesión'); await until(`!!document.querySelector('input[type=email]')`);
  await command('Emulation.setDeviceMetricsOverride', {width: 390, height: 844, deviceScaleFactor: 1, mobile: true});
  await delay(200);
  assert(await evaluate(`document.documentElement.scrollWidth <= window.innerWidth`), 'Horizontal overflow in mobile login.');
  fs.writeFileSync(path.join(output, 'login-mobile.png'), Buffer.from((await command('Page.captureScreenshot')).data, 'base64'));
  console.log('PASS: admin login, dashboard, search, status, moderation, category creation, logout, mobile layout.');
  console.log('Screenshots: artifacts/admin-check/dashboard.png and login-mobile.png');
})().catch(error => { console.error(error); process.exitCode = 1; }).finally(() => {
  if (ws) ws.close();
  if (child) child.kill();
  server.close();
});

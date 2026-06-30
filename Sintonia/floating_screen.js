(function () {
  // ===== estilos injetados =====
  const css = `
  .pid-panel{position:fixed;z-index:999999;background:#111;border-radius:10px;box-shadow:0 18px 52px rgba(0,0,0,.55);overflow:hidden;display:none}
  .pid-head{height:40px;display:flex;align-items:center;justify-content:space-between;padding:0 10px;background:#2d7bd6;border-bottom:none;color:#000;font-weight:700;cursor:move;user-select:none}
  .pid-body{position:absolute;inset:40px 0 0 0}
  .pid-iframe{width:100%;height:100%;border:0;background:#fff}
  .pid-btn{background:transparent;border:0;cursor:pointer;font-size:16px;color:#000}
  .pid-btn-open{padding:6px 12px;margin:4px;border:1px solid #1abc9c;border-radius:6px;background:#2c3e50;color:#fff;cursor:pointer;font-size:14px;font-weight:bold}
  .pid-btn-open:hover{background:#1abc9c}
  /* tamanho/click target */
  .pid-btn{
    width: 24px; height: 24px; padding: 0; margin: 0 2px;
    background: transparent; border: 0; cursor: pointer;
    position: relative; color: #000;
  }
  /* desenha o X sem caracteres */
  .pid-btn::before,
  .pid-btn::after{
    content: ""; position: absolute; left: 50%; top: 50%;
    width: 14px; height: 2px; background: currentColor;
    transform-origin: center;
  }
  .pid-btn::before{ transform: translate(-50%,-50%) rotate(45deg); }
  .pid-btn::after { transform: translate(-50%,-50%) rotate(-45deg); }

  /* foco/hover opcional */
  .pid-btn:hover{ color:#111; opacity: .9; }
  .pid-btn:focus{ outline: 2px solid #1abc9c; outline-offset: 2px; }
  /* 🔹 Aqui controla o título */
  #pidTitle {
    font-size: 20px;     /* tamanho da fonte */
    font-weight: bold;   /* negrito (opcional) */
    color: #000;         /* cor do texto */
  }  
  `;
  const st = document.createElement('style'); st.textContent = css; document.head.appendChild(st);

  // ===== markup do painel =====
  const box = document.createElement('div');
  box.id = 'pidPanel';
  box.className = 'pid-panel';
  box.setAttribute('role', 'dialog');
  box.setAttribute('aria-label', 'PID Controller');
  box.innerHTML = `
    <div id="pidHead" class="pid-head">
      <span id="pidTitle">PID - Controller</span>
      <button id="pidClose" class="pid-btn" title="Fechar" aria-label="Fechar"></button>
    </div>
    <div class="pid-body"><iframe id="pidFrame" class="pid-iframe" src="about:blank" scrolling="no"></iframe></div>
  `;
  document.body.appendChild(box);

  // ===== config =====
  const PID_BASE_URL = '/Scada-LTS/graphics/Sintonia/pid_dialog.jsp';
  const PANEL_W = 900;  // tamanho fixo
  const PANEL_H = 513;

  const head = box.querySelector('#pidHead');
  const ttl = box.querySelector('#pidTitle');
  const ifr = box.querySelector('#pidFrame');
  const btnX = box.querySelector('#pidClose');

  function qs(o) {
    const p = new URLSearchParams();
    Object.entries(o || {}).forEach(([k, v]) => { if (v !== undefined && v !== null && v !== '') p.set(k, String(v)); });
    return p.toString();
  }

  function placeFixed() {
    const w = Math.min(PANEL_W, window.innerWidth - 24);
    const h = Math.min(PANEL_H, window.innerHeight - 24);
    box.style.width = w + 'px';
    box.style.height = h + 'px';
    box.style.left = Math.max(12, Math.floor((window.innerWidth - w) / 2)) + 'px';
    box.style.top = Math.max(12, Math.floor((window.innerHeight - h) / 6)) + 'px';
  }

  // drag básico
  let dragging = false, sx = 0, sy = 0, bx0 = 0, by0 = 0;
  head.addEventListener('mousedown', e => {
    dragging = true; sx = e.clientX; sy = e.clientY; bx0 = box.offsetLeft; by0 = box.offsetTop; e.preventDefault();
  });
  window.addEventListener('mousemove', e => {
    if (!dragging) return;
    const nx = bx0 + (e.clientX - sx);
    const ny = by0 + (e.clientY - sy);
    box.style.left = Math.max(0, Math.min(window.innerWidth - 100, nx)) + 'px';
    box.style.top = Math.max(0, Math.min(window.innerHeight - 60, ny)) + 'px';
  });
  window.addEventListener('mouseup', () => dragging = false);

  btnX.addEventListener('click', () => {
    box.style.display = 'none';
    ifr.src = 'about:blank'; // para parar pooling do JSP
  });

  window.addEventListener('resize', () => { if (box.style.display !== 'none') placeFixed(); });

  // ===== função pública =====
  window.openPidFloatFixed = function ({ title = 'Controller', sp, pv, mv, am, lr, units = '%', period = 1000, demo = false } = {}) {
    ttl.textContent = `Tela de Sintonia da Malha ${title}`;
    const url = PID_BASE_URL + '?' + qs({ title, sp, pv, mv, am, lr, units, period, demo: demo ? 1 : 0 });
    placeFixed();
    box.style.display = 'block';
    window.__PID_Z__ = (window.__PID_Z__ || 999999) + 1;
    box.style.zIndex = window.__PID_Z__;
    ifr.src = url;
  };
})();

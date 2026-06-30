<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
  <%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
    <!DOCTYPE html>
    <html lang="pt-br">

    <head>
      <meta charset="UTF-8" />
      <meta name="viewport" content="width=device-width, initial-scale=1.0" />
      <title>PID - Dialog</title>

      <script>
        // ================= PARÂMETROS via querystring =================
        let SP_XID = "DP_SP_XID";
        let PV_XID = "DP_PV_XID";
        let MV_XID = "DP_MV_XID";
        let AM_XID = "DP_AM_XID";
        let LR_XID = "DP_LR_XID";

        let TITLE = "Controller";
        let UNITS = "%";          // SP/PV; MV sempre em %
        let PERIOD_MS = 1000;     // ?period= em ms
        let DEMO_MODE = false;    // ?demo=1

        function QS() { return new URLSearchParams(window.location.search); }
        function qStr(k, d) { const v = QS().get(k); return (v !== null && v !== "") ? v : d; }
        function qNum(k, d) { const v = QS().get(k); if (v === null) return d; const n = Number(v); return Number.isFinite(n) ? n : d; }
        function qBool(k, d) { const v = QS().get(k); if (v === null) return d; return ["1", "true", "on", "yes", "sim"].includes(String(v).toLowerCase()); }

        (function applyParams() {
          SP_XID = qStr("sp", SP_XID);
          PV_XID = qStr("pv", PV_XID);
          MV_XID = qStr("mv", MV_XID);
          AM_XID = qStr("am", AM_XID);
          LR_XID = qStr("lr", LR_XID);

          TITLE = qStr("title", qStr("tag", TITLE));
          UNITS = qStr("units", UNITS);
          PERIOD_MS = qNum("period", PERIOD_MS);
          DEMO_MODE = qBool("demo", DEMO_MODE);

          if (TITLE) document.title = "PID - " + TITLE;
        })();
      </script>

      <style>
        * {
          margin: 0;
          padding: 0;
          box-sizing: border-box;
          font-family: Arial, sans-serif;
        }

        html,
        body {
          height: 100%;
        }

        body {
          background: #ffffff;
          color: #ffffff;
          display: flex;
          justify-content: center;
          align-items: center;
          min-height: 100vh;
          overflow: hidden;
          padding: 3px 0 0 0;
        }

        /* ===== Layout principal ===== */
        .controller-body {
          width: 100%;
          display: grid;
          grid-template-columns: 0.6fr 2.4fr;
          column-gap: 14px;
          row-gap: 0;
          background: #ffffff;
          padding: 0 6px 6px 6px;
        }

        @media (max-width:850px) {
          .controller-body {
            grid-template-columns: 1fr;
          }
        }

        /* ===== Coluna esquerda ===== */
        .controller-display {
          background: #2c3e50;
          border-radius: 8px;
          padding: 15px;
          box-shadow: inset 0 0 10px rgba(0, 0, 0, .3);
          color: #ecf0f1;
        }

        .display-title {
          text-align: center;
          font-size: 16px;
          margin-bottom: 12px;
          color: #1abc9c;
          font-weight: bold;
        }

        .display-values {
          display: flex;
          flex-direction: column;
          gap: 10px;
        }

        .value-group {
          position: relative;
          margin-bottom: 10px;
        }

        .value-label {
          font-size: 13px;
          color: #bdc3c7;
          margin-bottom: 4px;
        }

        .value-input {
          width: 100%;
          font-size: 16px;
          padding: 5px 26px 5px 8px;
          font-weight: bold;
          color: #1abc9c;
          background: rgba(0, 0, 0, .2);
          border-radius: 5px;
          text-align: right;
          border: 1px solid #1abc9c;
        }

        .value-input:disabled {
          color: #7f8c8d;
          border-color: #7f8c8d;
          background: rgba(0, 0, 0, .1);
          cursor: not-allowed;
        }

        .percent-symbol {
          position: absolute;
          right: 10px;
          top: 27px;
          color: #1abc9c;
          font-weight: bold;
          font-size: 14px;
          pointer-events: none;
        }

        .percent-symbol.disabled {
          color: #7f8c8d;
        }

        .mode-selector {
          display: flex;
          gap: 8px;
          margin-top: 8px;
        }

        .mode-btn {
          width: 68px;
          white-space: nowrap;
          text-align: center;
          flex: 0 0 68px;
          padding: 4px 10px;
          font-size: 12px;
          border: 1px solid #7f8c8d;
          border-radius: 4px;
          background: #2c3e50;
          color: #bdc3c7;
          cursor: pointer;
          transition: .2s;
        }

        .mode-btn[disabled] {
          opacity: .5;
          pointer-events: none;
          filter: grayscale(.2);
        }

        .mode-btn:hover {
          filter: brightness(1.1);
        }

        .mode-btn.active {
          background: #1abc9c;
          color: #fff;
          border-color: #1abc9c;
        }

        .mode-section {
          margin-bottom: 12px;
        }

        .mode-section-title {
          text-align: left;
          font-size: 13px;
          color: #bdc3c7;
          margin-bottom: 4px;
        }

        .input-group {
          margin-top: 8px;
        }

        .input-group label {
          display: block;
          font-size: 13px;
          color: #bdc3c7;
          margin-bottom: 4px;
        }

        .input-group select,
        .input-group input {
          width: 100%;
          padding: 6px;
          border: 1px solid #7f8c8d;
          border-radius: 4px;
          background: #2c3e50;
          color: #ecf0f1;
          text-align: center;
          font-size: 14px;
        }

        .input-group select:focus,
        .input-group input:focus {
          border-color: #1abc9c;
          outline: none;
        }

        /* ===== Área do gráfico ===== */
        .controller-graph {
          background: #2c3e50;
          border-radius: 8px;
          padding: 12px;
          position: relative;
          display: flex;
          flex-direction: column;
        }

        .controller-graph .display-title {
          color: #1abc9c;
        }

        /* Toolbar de ícones */
        .tb {
          display: flex;
          gap: 8px;
          align-items: center;
          padding: 8px;
          background: #e8ecef;
          border-radius: 10px;
          border: 1px solid #cfd8dc;
        }

        .tb button {
          appearance: none;
          border: 1px solid #cfd8dc;
          background: #fff;
          border-radius: 8px;
          width: 34px;
          height: 30px;
          display: inline-flex;
          align-items: center;
          justify-content: center;
          cursor: pointer;
          transition: .15s;
          box-shadow: 0 1px 0 rgba(0, 0, 0, .05);
        }

        .tb button:hover {
          background: #f6f9fb;
        }

        .tb button.active {
          outline: 2px solid #1e88e5;
        }

        .tb button[disabled] {
          opacity: .45;
          pointer-events: none;
        }

        .tb svg {
          width: 18px;
          height: 18px;
          fill: #263238;
        }

        /* Pills na toolbar */
        .pillbox {
          margin-left: auto;
          display: flex;
          gap: 8px;
        }

        .pill {
          padding: 4px 10px;
          border-radius: 16px;
          background: #2f4354;
          color: #eaf2f6;
          font-size: 12px;
          border: 1px solid #b7c5cf;
          display: none;
        }

        /* Plotly container */
        #plotBox {
          background: #fff;
          border: 1px solid #b0bec5;
          border-radius: 8px;
          margin-top: 10px;
          flex: 1 1 auto;
          min-height: 300px;
        }

        /* Checkboxes (mostrar traços) */
        .graph-controls {
          display: flex;
          gap: 14px;
          align-items: center;
          padding-top: 10px;
          color: #e6eff3;
        }

        .graph-controls label {
          font-size: 13px;
          color: #e6eff3;
        }

        .graph-controls input[type="checkbox"] {
          accent-color: #1976d2;
        }

        /* Linha "A" toda em uma só linha */
        .value-group-inline {
          display: flex;
          align-items: center;
          gap: 8px;
          /* top 0, right 0px, bottom 0px, left 0px */
          padding: 8px 0 0 0;
          /* espaço entre itens */
        }

        /* o rótulo "A" não quebra linha nem cria margem inferior */
        .value-group-inline .value-label {
          display: inline;
          margin: 0;
        }

        /* display compacto para não alargar a coluna */
        .value-group-inline .value-input.compact {
          width: 48px;
          /* ajuste como preferir */
          padding: 4px 6px;
          text-align: right;
        }

        /* botões mínimos */
        .mode-btn.mini {
          flex: 0 0 auto;
          width: auto;
          min-width: 0;
          padding: 4px 8px;
          font-size: 12px;
          line-height: 1.1;
          white-space: nowrap;
        }

        html,
        body {
          overflow: hidden;
        }
      </style>
    </head>

    <body>

      <div class="controller-body">
        <!-- ===== Coluna esquerda ===== -->
        <div class="controller-display">
          <div class="display-title">VALORES ATUAIS</div>
          <div class="display-values">
            <div class="value-group">
              <div class="value-label">PV</div>
              <input type="number" class="value-input" id="pv-value" value="54.0" step="0.1" disabled />
              <span class="percent-symbol" id="pv-percent">%</span>
            </div>

            <div class="value-group">
              <div class="value-label">SP</div>
              <input type="number" class="value-input" id="sp-value" value="54.0" step="0.1" />
              <span class="percent-symbol" id="sp-percent">%</span>
              <div class="mode-selector" id="access-selector">
                <button class="mode-btn" data-access="local" id="btn-local">Local</button>
                <button class="mode-btn" data-access="remoto" id="btn-remoto">Remoto</button>
              </div>
            </div>

            <div class="value-group">
              <div class="value-label">MV</div>
              <input type="number" class="value-input" id="mv-value" value="47.77" step="0.01" disabled />
              <span class="percent-symbol" id="mv-percent">%</span>
              <div class="value-group-inline">
                <span class="value-label">A</span>
                <input type="number" id="a-display" class="value-input compact" value="10" />
                <button class="mode-btn mini" id="btn-a-plus">A+</button>
                <button class="mode-btn mini" id="btn-a-minus">A-</button>
              </div>
              <div class="mode-selector" id="mode-selector">
                <button class="mode-btn" data-mode="auto" id="btn-auto">Auto</button>
                <button class="mode-btn" data-mode="manual" id="btn-manual">Manual</button>
              </div>
            </div>

            <div class="mode-section">
              <div class="input-group">
                <label for="division-time">Division time</label>
                <select id="division-time">
                  <option value="0.5">0.5 segundo</option>
                  <option value="1" selected>1 segundos</option>
                  <option value="2">2 segundos</option>
                  <option value="3">3 segundos</option>
                  <option value="5">5 segundos</option>
                </select>
              </div>
            </div>

          </div>
        </div>

        <!-- ===== Coluna do gráfico ===== -->
        <div class="controller-graph">
          <div class="display-title">GRÁFICO DE CONTROLE</div>

          <!-- Toolbar + pills -->
          <div class="tb" id="toolbar">
            <!-- Play/Stop -->
            <button id="tb-run" title="Stop">
              <!-- ícone STOP inicial (pois começamos rodando) -->
              <svg viewBox="0 0 24 24">
                <path d="M6 5h4v14H6zM14 5h4v14h-4z"/>
              </svg>
            </button>

            <button id="tb-home" title="Home (reset)">
              <svg viewBox="0 0 24 24">
                <path d="M10 20v-6h4v6h5v-8h3L12 3 2 12h3v8z" />
              </svg>
            </button>
            <button id="tb-pan" title="Pan">
              <svg viewBox="0 0 24 24">
                <path
                  d="M9 11V2h2v9h1V4h2v7h1V6h2v5.5l.5.5H22v2h-3.09l-1.41 6.59A2 2 0 0 1 15.55 22H9a2 2 0 0 1-2-2v-7h2z" />
              </svg>
            </button>
            <button id="tb-zoom" title="Zoom">
              <svg viewBox="0 0 24 24">
                <path
                  d="M15.5 14h-.79l-.28-.27A6.471 6.471 0 0 0 16 9.5 6.5 6.5 0 1 0 9.5 16c1.61 0 3.09-.59 4.23-1.57l.27.28v.79l5 4.99L20.49 19l-4.99-5zM9.5 14C7.01 14 5 11.99 5 9.5S7.01 5 9.5 5 14 7.01 14 9.5 11.99 14 9.5 14z" />
              </svg>
            </button>
            <button id="tb-cv" title="Cursor Vertical">
              <svg viewBox="0 0 24 24">
                <path d="M11 3h2v18h-2z" />
              </svg>
            </button>
            <button id="tb-ch" title="Cursor Horizontal">
              <svg viewBox="0 0 24 24">
                <path d="M3 11h18v2H3z" />
              </svg>
            </button>
            <button id="tb-kp" title="Kp (tangente)">
              <svg viewBox="0 0 24 24">
                <path d="M3 17h2l3.5-6 4 7 3-5 3.5 4H21l-5-7-3 5-4-7L5 17z" />
              </svg>
            </button>
            <button id="tb-clear-cursors" title="Limpar cursores">
              <svg viewBox="0 0 24 24">
                <path
                  d="M16 14l-6-6 1.41-1.41L17.41 12 16 14zm3.3-9.9l-1.4-1.4-2.1 2.1-1.5-1.5-1.4 1.4 1.5 1.5L5 19v2h2l9.9-9.9 1.5 1.5 1.4-1.4-1.5-1.5 2.1-2.1z" />
              </svg>
            </button>
            <button id="tb-clear" title="Limpar Tela">
              <svg viewBox="0 0 24 24">
                <path d="M16 11V7H8v4H2l10 9 10-9h-6zM16 5V3H8v2h8z" />
              </svg>
            </button>

            <div class="pillbox">
              <span class="pill" id="pill-dt">Δt = s</span>
              <span class="pill" id="pill-dpv">ΔPV =</span>
              <span class="pill" id="pill-dmv">ΔMV =</span>
            </div>
          </div>

          <div id="plotBox"></div>

          <div class="graph-controls">
            <label><input type="checkbox" id="chk-pv" checked> PV</label>
            <label><input type="checkbox" id="chk-sp" checked> SP</label>
            <label><input type="checkbox" id="chk-mv" checked> MV</label>
          </div>
        </div>
      </div>

      <script>
        // ================= DWR =================
        const ctxPath = "<c:out value='${pageContext.request.contextPath}'/>";
        (function injectDwr() {
          try {
            var s1 = document.createElement('script'); s1.src = ctxPath + '/dwr/engine.js';
            s1.onload = function () {
              var s2 = document.createElement('script'); s2.src = ctxPath + '/dwr/util.js'; document.head.appendChild(s2);
              var s3 = document.createElement('script'); s3.src = ctxPath + '/dwr/interface/DataPointDwr.js'; document.head.appendChild(s3);
            };
            document.head.appendChild(s1);
          } catch (e) { }
        })();
        function dwrOk() { try { return typeof DataPointDwr !== "undefined"; } catch (e) { return false; } }

        function readLatest(xid, cb) {
          if (!xid) { cb(null); return; }
          if (dwrOk() && typeof DataPointDwr.getLatestPointValue === 'function') {
            try {
              DataPointDwr.getLatestPointValue(xid, function (pv) {
                const v = (pv && typeof pv.value !== 'undefined') ? pv.value : pv;
                cb(Number(v));
              });
              return;
            } catch (e) { }
          }
          fetch(ctxPath + '/getLatestPointValue.htm?xid=' + encodeURIComponent(xid), { cache: 'no-store' })
            .then(r => r.ok ? r.json() : null)
            .then(j => cb(j ? Number(j.value) : null))
            .catch(() => cb(null));
        }

        function writePoint(xid, value, cb) {
          if (!xid) { cb && cb(false); return; }
          if (dwrOk() && typeof DataPointDwr.setPointValueXid === 'function') {
            try { DataPointDwr.setPointValueXid(xid, String(value), () => cb && cb(true)); return; } catch (e) { }
          }
          if (dwrOk() && typeof DataPointDwr.setPointValue === 'function') {
            try { DataPointDwr.setPointValue(xid, String(value), null, () => cb && cb(true)); return; } catch (e) { }
          }
          fetch(ctxPath + '/setPointValue.htm', {
            method: 'POST',
            headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
            body: new URLSearchParams({ xid: xid, value: String(value) })
          }).then(r => cb && cb(r.ok)).catch(() => cb && cb(false));
        }

        // ================= UI: elementos/estado =================
        const spValueInput = document.getElementById('sp-value');
        const pvValueInput = document.getElementById('pv-value');
        const mvValueInput = document.getElementById('mv-value');
        const spPercentSymbol = document.getElementById('sp-percent');
        const pvPercentSymbol = document.getElementById('pv-percent');
        const mvPercentSymbol = document.getElementById('mv-percent');
        const divisionTimeSelect = document.getElementById('division-time');

        const btnAuto = document.getElementById('btn-auto');
        const btnManual = document.getElementById('btn-manual');
        const btnLocal = document.getElementById('btn-local');
        const btnRemoto = document.getElementById('btn-remoto');

        const chkPV = document.getElementById('chk-pv');
        const chkSP = document.getElementById('chk-sp');
        const chkMV = document.getElementById('chk-mv');

        const aDisplay = document.getElementById('a-display');
        const btnAPlus = document.getElementById('btn-a-plus');
        const btnAMinus = document.getElementById('btn-a-minus');

        let setpoint = 50.0;

        // ======== Play/Pause state (tempo contínuo) ========
        let timerId = null;
        let isPlaying = true;        // começamos rodando
        let tAccum = 0;              // segundos acumulados só enquanto em Play
        let lastTickMs = 0;          // marcação do último tick (ms)

        // ================= Plot / cursores / kp =================
        let plot;              // DOM do plot (gd)
        let shapes = [];       // linhas desenhadas
        let tool = 'pan';      // 'pan'|'zoom'|'cv'|'ch'|'kp'
        let cvXs = [];         // x das verticais
        let chYs = [];         // y (eixo esquerdo) das horizontais

        const pillDt = () => document.getElementById('pill-dt');
        const pillPV = () => document.getElementById('pill-dpv');
        const pillMV = () => document.getElementById('pill-dmv');

        function showPill(el, txt) { el.style.display = 'inline-block'; el.textContent = txt; }
        function hidePills() { [pillDt(), pillPV(), pillMV()].forEach(p => { p.style.display = 'none'; }); }

        function setupPlot() {
          const el = document.getElementById('plotBox');

          const traces = [
            { name: 'PV', x: [], y: [], mode: 'lines', line: { width: 2, color: '#1976d2' } },
            { name: 'SP', x: [], y: [], mode: 'lines', line: { width: 2, dash: 'dot', color: '#2e7d32' } },
            { name: 'MV', x: [], y: [], mode: 'lines', line: { width: 2, color: '#fb8c00' }, yaxis: 'y2' }
          ];

          const layout = {
            margin: { l: 60, r: 60, t: 6, b: 48 },
            paper_bgcolor: '#ffffff',
            plot_bgcolor: '#ffffff',
            borderradius: 10,
            showlegend: true,
            legend: { x: 1, y: 0, xanchor: 'right', yanchor: 'bottom', bgcolor: '#ffffff', bordercolor: '#cfd8dc', borderwidth: 1, font: { color: '#263238' } },
            dragmode: 'pan',
            xaxis: {
              title: { text: 'Tempo (s)', font: { color: '#37474f' } },
              tickfont: { color: '#546e7a' },
              gridcolor: '#eceff1',
              linecolor: '#90a4ae', showline: true, mirror: true,
              zeroline: false, showspikes: true, spikemode: 'across', spikecolor: '#90a4ae', spikethickness: 1,
              automargin: true, autorange: true
            },
            yaxis: {
              title: { text: 'PV/SP (' + UNITS + ')', font: { color: '#37474f' } },
              tickfont: { color: '#546e7a' },
              gridcolor: '#eceff1',
              linecolor: '#90a4ae', showline: true, mirror: true,
              zeroline: false, showspikes: true, spikemode: 'across', spikecolor: '#90a4ae', spikethickness: 1,
              automargin: true, autorange: true
            },
            yaxis2: {
              title: { text: 'MV (%)', font: { color: '#8d6e63' } },
              tickfont: { color: '#8d6e63' },
              overlaying: 'y', side: 'right',
              linecolor: '#8d6e63', showline: true, mirror: true,
              zeroline: false, automargin: true, autorange: true
            },
            hovermode: 'x unified',
            shapes: []
          };

          const config = { responsive: true, displayModeBar: false };

          Plotly.newPlot(el, traces, layout, config).then(gd => {
            plot = gd;
            bindToolbar();
            bindPlotInteractions();
            // start in play mode
            setPlaying(true);
          });
        }

        /* Toolbar */
        function bindToolbar() {
          const $ = id => document.getElementById(id);
          const run = $('tb-run');
          const home = $('tb-home');
          const pan = $('tb-pan');
          const zoom = $('tb-zoom');
          const cv = $('tb-cv');
          const ch = $('tb-ch');
          const kp = $('tb-kp');
          const clrC = $('tb-clear-cursors');
          const clr = $('tb-clear');

          function mark(btn) {
            [pan, zoom, cv, ch, kp].forEach(b => b.classList.remove('active'));
            if (btn) btn.classList.add('active');
          }
          function setTool(t, btn) {
            tool = t; mark(btn); hidePills();
            if (t === 'pan') Plotly.relayout(plot, { 'dragmode': 'pan' });
            if (t === 'zoom') Plotly.relayout(plot, { 'dragmode': 'zoom' });
            if (t === 'cv') { Plotly.relayout(plot, { 'dragmode': 'pan' }); cvXs.length = 0; removeShapesByName(['cv1', 'cv2']); }
            if (t === 'ch') { Plotly.relayout(plot, { 'dragmode': 'pan' }); chYs.length = 0; removeShapesByName(['ch1', 'ch2']); }
            if (t === 'kp') { Plotly.relayout(plot, { 'dragmode': 'pan' }); removeShapesByName(['kp']); }
          }
          function setCursorButtonsDisabled(disabled) {
            [cv, ch, kp].forEach(b => b.disabled = disabled);
            if (disabled) { tool = 'pan'; mark(pan); Plotly.relayout(plot, { 'dragmode': 'pan' }); }
          }
          function updateRunIcon() {
            if (isPlaying) {
              run.title = 'pause';
              run.innerHTML = '<svg viewBox="0 0 24 24"><path d="M6 5h4v14H6zM14 5h4v14h-4z"/></svg>';
            } else {
              run.title = 'Play';
              run.innerHTML = '<svg viewBox="0 0 24 24"><path d="M8 5v14l11-7z"/></svg>';
            }
          }
          run.addEventListener('click', () => setPlaying(!isPlaying));

          home.addEventListener('click', () => Plotly.relayout(plot, {
            'xaxis.autorange': true, 'yaxis.autorange': true, 'yaxis2.autorange': true
          }));
          pan.addEventListener('click', () => setTool('pan', pan));
          zoom.addEventListener('click', () => setTool('zoom', zoom));
          cv.addEventListener('click', () => setTool('cv', cv));
          ch.addEventListener('click', () => setTool('ch', ch));
          kp.addEventListener('click', () => setTool('kp', kp));

          clrC.addEventListener('click', () => {
            removeShapesByName(['cv1', 'cv2', 'ch1', 'ch2', 'kp']);
            cvXs.length = 0; chYs.length = 0; hidePills();
          });

          clr.addEventListener('click', () => {
            Plotly.restyle(plot, { x: [[], [], []], y: [[], [], []] });
            removeShapesByName(['cv1', 'cv2', 'ch1', 'ch2', 'kp']);
            cvXs.length = 0; chYs.length = 0; hidePills();
            Plotly.relayout(plot, { 'xaxis.autorange': true, 'yaxis.autorange': true, 'yaxis2.autorange': true });
          });

          // expose helpers
          window.__setCursorButtonsDisabled = setCursorButtonsDisabled;
          window.__updateRunIcon = updateRunIcon;

          setTool('pan', pan); // estado inicial
          updateRunIcon();
        }

        function removeShapesByName(names) {
          shapes = shapes.filter(s => !names.includes(s.name));
          Plotly.relayout(plot, { shapes });
        }

        /* ===== Conversões e captura de clique por pixel ===== */
        function getPlotRect() {
          const el = plot.querySelector('.cartesianlayer .subplot.xy .plot') ||
            plot.querySelector('.cartesianlayer .plot');
          return el ? el.getBoundingClientRect() : null;
        }
        function getRanges() {
          const fl = plot._fullLayout;
          const xr = fl.xaxis.range || fl.xaxis._range;
          const yr = fl.yaxis.range || fl.yaxis._range;
          const y2r = fl.yaxis2.range || fl.yaxis2._range;
          return { xr, yr, y2r };
        }
        function pixelToData(evt) {
          const r = getPlotRect(); if (!r) return null;
          const { xr, yr } = getRanges(); if (!xr || !yr) return null;
          const px = evt.clientX, py = evt.clientY;
          if (px < r.left || px > r.right || py < r.top || py > r.bottom) return null;
          const x = xr[0] + (px - r.left) / (r.width) * (xr[1] - xr[0]);
          const y = yr[1] - (py - r.top) / (r.height) * (yr[1] - yr[0]);
          return { x, y };
        }
        function rightToLeft(mv) {
          const { yr, y2r } = getRanges();
          const a = (yr[1] - yr[0]) / (y2r[1] - y2r[0]);
          return yr[0] + (mv - y2r[0]) * a;
        }
        function leftToRight(yLeft) {
          const { yr, y2r } = getRanges();
          const a = (y2r[1] - y2r[0]) / (yr[1] - yr[0]);
          return y2r[0] + (yLeft - yr[0]) * a;
        }

        /* Eventos de clique (qualquer pixel do plano) */
        function bindPlotInteractions() {
          let down = { x: 0, y: 0 };
          plot.addEventListener('pointerdown', e => { down = { x: e.clientX, y: e.clientY }; });
          plot.addEventListener('click', e => {
            if (isPlaying) return; // cursores só funcionam em STOP
            if (Math.hypot(e.clientX - down.x, e.clientY - down.y) > 4) return;

            const pt = pixelToData(e);
            if (!pt) return;

            if (tool === 'cv') handleCV(pt.x);
            else if (tool === 'ch') handleCH(pt.y);
            else if (tool === 'kp') handleKP(pt.x);
          });
        }

        /* ===== CV ===== */
        function handleCV(xv) {
          if (cvXs.length === 0) {
            cvXs.push(xv);
            addLine({ name: 'cv1', x0: xv, x1: xv, y0: 0, y1: 1, xref: 'x', yref: 'paper', color: '#1e88e5' });
            hidePills();
          } else if (cvXs.length === 1) {
            cvXs.push(xv);
            addLine({ name: 'cv2', x0: xv, x1: xv, y0: 0, y1: 1, xref: 'x', yref: 'paper', color: '#1e88e5' });
            const dt = Math.abs(cvXs[1] - cvXs[0]);
            showPill(pillDt(), `Δt = ${dt.toFixed(2)} s`);
          } else {
            removeShapesByName(['cv1', 'cv2']);
            cvXs = [xv];
            addLine({ name: 'cv1', x0: xv, x1: xv, y0: 0, y1: 1, xref: 'x', yref: 'paper', color: '#1e88e5' });
            hidePills();
          }
        }

        /* ===== CH ===== */
        function handleCH(yLeft) {
          if (chYs.length === 0) {
            chYs.push(yLeft);
            addLine({ name: 'ch1', x0: 0, x1: 1, y0: yLeft, y1: yLeft, xref: 'paper', yref: 'y', color: '#8e24aa' });
            hidePills();
          } else if (chYs.length === 1) {
            chYs.push(yLeft);
            addLine({ name: 'ch2', x0: 0, x1: 1, y0: yLeft, y1: yLeft, xref: 'paper', yref: 'y', color: '#8e24aa' });

            const dPV = chYs[1] - chYs[0];
            const mv1 = leftToRight(chYs[0]);
            const mv2 = leftToRight(chYs[1]);
            const dMV = mv2 - mv1;

            showPill(pillPV(), `ΔPV = ${dPV.toFixed(2)} ${UNITS}`);
            showPill(pillMV(), `ΔMV = ${dMV.toFixed(2)} %`);
          } else {
            removeShapesByName(['ch1', 'ch2']);
            chYs = [yLeft];
            addLine({ name: 'ch1', x0: 0, x1: 1, y0: yLeft, y1: yLeft, xref: 'paper', yref: 'y', color: '#8e24aa' });
            hidePills();
          }
        }

        /* ===== KP (tangente) ===== */
        function handleKP(xClick) {
          try {
            const d = plot.data;
            const xpv = d[0].x, ypv = d[0].y;
            const xmv = d[2].x, ymv = d[2].y;

            if (!xpv || xpv.length < 3) return;

            // índice mais próximo na PV
            let i0 = 0, best = Infinity;
            for (let i = 0; i < xpv.length; i++) {
              const dd = Math.abs(xpv[i] - xClick);
              if (dd < best) { best = dd; i0 = i; }
            }
            const iPrev = Math.max(0, i0 - 1);
            const iNext = Math.min(xpv.length - 1, i0 + 1);
            if (iNext === iPrev) return;

            const x0 = xpv[i0], y0 = ypv[i0];
            const m = (ypv[iNext] - ypv[iPrev]) / (xpv[iNext] - xpv[iPrev]);

            // interseção com MV (convertida ao eixo esquerdo)
            let bestIdx = -1, bestAbs = Infinity;
            for (let i = 0; i < xpv.length; i++) {
              const t = xpv[i];
              const yTan = y0 + m * (t - x0);
              // mv(t) mais próximo
              let j = Math.min(i, xmv.length - 1);
              while (j > 0 && Math.abs(xmv[j - 1] - t) < Math.abs(xmv[j] - t)) j--;
              while (j < xmv.length - 1 && Math.abs(xmv[j + 1] - t) < Math.abs(xmv[j] - t)) j++;
              const yMvLeft = rightToLeft(ymv[j]);
              const diff = Math.abs(yTan - yMvLeft);
              if (diff < bestAbs) { bestAbs = diff; bestIdx = i; }
            }
            if (bestIdx < 0) return;

            const x1 = xpv[bestIdx];
            const y1 = y0 + m * (x1 - x0);

            removeShapesByName(['kp']);
            addLine({ name: 'kp', x0: x0, x1: x1, y0: y0, y1: y1, xref: 'x', yref: 'y', color: '#455a64', dash: 'dot', width: 3 });

            const dT = x1 - x0;
            const dPV = y1 - y0;
            showPill(pillDt(), `Δt = ${dT.toFixed(2)} s`);
            showPill(pillPV(), `ΔPV = ${dPV.toFixed(2)} ${UNITS}`);
            pillMV().style.display = 'none';
          } catch (e) { }
        }

        function addLine({ name, x0, x1, y0, y1, xref, yref, color, width = 2, dash = 'dot' }) {
          shapes = shapes.filter(s => s.name !== name);
          shapes.push({ name, type: 'line', xref, yref, x0, x1, y0, y1, line: { color, width, dash } });
          Plotly.relayout(plot, { shapes });
        }

        // ================= Amostragem / loop =================
        const MAX_POINTS = 2000;

        function extendAt(t, pv, sp, mv) {
          Plotly.extendTraces(plot, { x: [[t], [t], [t]], y: [[pv], [sp], [mv]] }, [0, 1, 2], MAX_POINTS);
          Plotly.relayout(plot, { 'yaxis.autorange': true, 'yaxis2.autorange': true });
        }

        function tickOnce() {
          const now = Date.now();
          const dt = (now - lastTickMs) / 1000;
          lastTickMs = now;
          tAccum += dt;

          const tNow = tAccum;

          if (DEMO_MODE) {
            const tt = now / 1000;
            const sp = setpoint;
            const pv = 50 + 8 * Math.sin(tt / 3) + (sp - 50) * 0.05;
            const mv = 40 + 12 * Math.sin(tt / 2.5);
            if (document.activeElement !== pvValueInput) pvValueInput.value = pv.toFixed(1);
            mvValueInput.value = mv.toFixed(2);
            extendAt(tNow, pv, sp, mv);
          } else {
            Promise.all([
              new Promise(r => readLatest(SP_XID, v => r(v))),
              new Promise(r => readLatest(PV_XID, v => r(v))),
              new Promise(r => readLatest(MV_XID, v => r(v))),
              new Promise(r => readLatest(AM_XID, v => r(v))),
              new Promise(r => readLatest(LR_XID, v => r(v))),
            ]).then(([sp, pv, mv, am, lr]) => {
              if (sp != null && document.activeElement !== spValueInput) { spValueInput.value = Number(sp).toFixed(1); setpoint = Number(sp); }
              if (pv != null && document.activeElement !== pvValueInput) { pvValueInput.value = Number(pv).toFixed(1); }
              if (mv != null) { mvValueInput.value = Number(mv).toFixed(2); }
              if (am != null) updateModeButtons(am);
              if (lr != null) updateAccessButtons(lr);
              extendAt(tNow, Number(pv ?? 0), Number(sp ?? setpoint), Number(mv ?? 0));
            });
          }
        }

        function startLoop() {
          if (timerId) clearInterval(timerId);
          lastTickMs = Date.now();
          timerId = setInterval(tickOnce, PERIOD_MS);
        }

        function setPlaying(on) {
          isPlaying = on;
          window.__updateRunIcon && window.__updateRunIcon();
          window.__setCursorButtonsDisabled && window.__setCursorButtonsDisabled(isPlaying);
          if (isPlaying) {
            startLoop();
          } else {
            if (timerId) { clearInterval(timerId); timerId = null; }
          }
        }

        // ================== UI binds ==================
        function setActive(btn, on) { if (on) btn.classList.add('active'); else btn.classList.remove('active'); }
        function updateModeButtons(amVal) {
          const auto = Number(amVal) === 1; // 1=Auto
          setActive(btnAuto, auto); setActive(btnManual, !auto);
          mvValueInput.disabled = auto;
          aDisplay.disabled = auto;
          btnAPlus.disabled = auto;
          btnAMinus.disabled = auto;
        }
        function updateAccessButtons(lrVal) {
          const local = Number(lrVal) != 1; // 1=Local
          setActive(btnLocal, !local);
          setActive(btnRemoto, local);
          spValueInput.disabled = local;
        }
        function bindModeActions() {
          btnAuto.addEventListener('click', () => { updateModeButtons(1); if (AM_XID) writePoint(AM_XID, 1, () => { }); });
          btnManual.addEventListener('click', () => { updateModeButtons(0); if (AM_XID) writePoint(AM_XID, 0, () => { }); });
          btnLocal.addEventListener('click', () => { updateAccessButtons(1); if (LR_XID) writePoint(LR_XID, 1, () => { }); });
          btnRemoto.addEventListener('click', () => { updateAccessButtons(0); if (LR_XID) writePoint(LR_XID, 0, () => { }); });

          spValueInput.addEventListener('change', () => {
            const v = Number(String(spValueInput.value).replace(',', '.'));
            if (isFinite(v)) { setpoint = v; if (!DEMO_MODE && SP_XID) writePoint(SP_XID, v, () => { }); }
          });

          divisionTimeSelect.addEventListener('change', () => {
            const s = Number(divisionTimeSelect.value) || 1; PERIOD_MS = s * 1000;
            if (isPlaying) startLoop();
          });

          chkPV.addEventListener('change', () => { Plotly.restyle(plot, { visible: chkPV.checked ? true : 'legendonly' }, [0]); });
          chkSP.addEventListener('change', () => { Plotly.restyle(plot, { visible: chkSP.checked ? true : 'legendonly' }, [1]); });
          chkMV.addEventListener('change', () => { Plotly.restyle(plot, { visible: chkMV.checked ? true : 'legendonly' }, [2]); });
        }

        // ================= Bootstrap =================
        window.addEventListener('load', () => {
          // símbolos de unidade
          spPercentSymbol.textContent = UNITS || '';
          pvPercentSymbol.textContent = UNITS || '';
          mvPercentSymbol.textContent = '%';
          bindModeActions();

          // select period
          const s = Math.max(0.5, Math.round(PERIOD_MS / 100) / 10);
          const opts = ["0.5", "1", "2", "3", "5"];
          divisionTimeSelect.value = opts.includes(String(s)) ? String(s) : "1";

          // Plotly
          const local = ctxPath + "/resources/plotly-2.30.0.min.js";
          const loadScript = src => new Promise((res, rej) => { const sc = document.createElement('script'); sc.src = src; sc.onload = res; sc.onerror = rej; document.head.appendChild(sc); });
          loadScript(local).catch(() => loadScript("https://cdn.plot.ly/plotly-2.30.0.min.js"))
            .then(() => setupPlot())
            .catch(() => {
              const el = document.getElementById('plotBox');
              el.style.padding = '16px'; el.style.color = '#c62828';
              el.innerText = 'Plotly não encontrado (local e CDN).';
            });
        });
      </script>

      <script>
        /* Ajuste automático de tamanho para o pai (synoptic) */
        (function () {
          function reportSize() {
            const w = Math.ceil(document.documentElement.scrollWidth);
            const h = Math.ceil(document.documentElement.scrollHeight);
            try { parent.postMessage({ type: 'PID_SIZE', w, h }, '*'); } catch (e) { }
          }
          window.addEventListener('load', reportSize);
          new ResizeObserver(reportSize).observe(document.documentElement);
          new ResizeObserver(reportSize).observe(document.body);
        })();
      </script>
    </body>

    </html>
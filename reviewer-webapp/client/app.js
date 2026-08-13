const state = {
  file: null,
  content: null,
  format: null,
  result: null,
  filter: "all",
  token: null,
  capabilities: null
};

const $ = (selector) => document.querySelector(selector);
const $$ = (selector) => Array.from(document.querySelectorAll(selector));

function showToast(message) {
  const toast = $("#toast");
  toast.textContent = message;
  toast.hidden = false;
  window.clearTimeout(showToast.timer);
  showToast.timer = window.setTimeout(() => { toast.hidden = true; }, 3200);
}

function setUploadError(message) {
  const error = $("#upload-error");
  error.textContent = message || "";
  error.hidden = !message;
}

function isSupported(file) {
  const format = formatFor(file);
  return Boolean(format && state.capabilities?.formats?.includes(format));
}

function formatFor(file) {
  if (/\.pdf$/i.test(file.name) || file.type === "application/pdf") return "pdf";
  if (/\.txt$/i.test(file.name) || file.type === "text/plain") return "text";
  if (/\.(md|markdown)$/i.test(file.name) || file.type === "text/markdown") return "markdown";
  return null;
}

async function readFile(file, format) {
  if (format !== "pdf") return { content: await file.text() };

  const bytes = new Uint8Array(await file.arrayBuffer());
  const chunks = [];
  const chunkSize = 32 * 1024;
  for (let offset = 0; offset < bytes.length; offset += chunkSize) {
    chunks.push(String.fromCharCode(...bytes.subarray(offset, offset + chunkSize)));
  }
  return { data_base64: btoa(chunks.join("")) };
}

async function selectFile(file) {
  setUploadError("");
  if (!file) return;
  if (!isSupported(file)) {
    const pdfUnavailable = formatFor(file) === "pdf" && !state.capabilities?.formats?.includes("pdf");
    setUploadError(pdfUnavailable ? "O conversor de PDF não está instalado. Execute bundle install e reinicie o revisor." : "Formato não aceito. Escolha um arquivo .md, .markdown, .txt ou .pdf.");
    return;
  }
  if (file.size > (state.capabilities?.max_bytes || 5 * 1024 * 1024)) {
    setUploadError("O arquivo excede o limite local de 5 MB.");
    return;
  }
  try {
    const format = formatFor(file);
    const content = await readFile(file, format);
    if (format !== "pdf" && !content.content) {
      setUploadError("O documento está vazio.");
      return;
    }
    state.file = file;
    state.content = content;
    state.format = format;
    const conversionNote = format === "pdf" ? " · conversão local" : "";
    $("#selection-note").textContent = `${file.name} · ${formatBytes(file.size)}${conversionNote} · pronto para revisar`;
    $("#review-button").disabled = false;
    $("#drop-zone").classList.add("has-file");
    showToast("Documento importado em memória.");
  } catch {
    setUploadError("Não foi possível ler o arquivo no dispositivo.");
  }
}

function formatBytes(bytes) {
  if (bytes < 1024) return `${bytes} B`;
  if (bytes < 1024 * 1024) return `${Math.round(bytes / 1024)} KB`;
  return `${(bytes / (1024 * 1024)).toFixed(1)} MB`;
}

function setBusy(busy) {
  const button = $("#review-button");
  button.disabled = busy || !state.file;
  button.innerHTML = busy ? "Analisando…" : 'Iniciar revisão <span aria-hidden="true">→</span>';
}

async function reviewDocument() {
  if (!state.file || state.content === null) return;
  setBusy(true);
  setUploadError("");
  try {
    const response = await fetch("/api/v1/reviews", {
      method: "POST",
      headers: { "Content-Type": "application/json", "X-PTE-Session": state.token || "" },
      body: JSON.stringify({
        document: { name: state.file.name, format: state.format, ...state.content },
        configuration: { locale: $("#locale-select").value, level: $("#level-select").value }
      })
    });
    const payload = await response.json();
    if (!response.ok) throw new Error(payload.error?.message || "O serviço local recusou a revisão.");
    state.result = payload;
    state.filter = "all";
    renderResults();
    $("#results-panel").hidden = false;
    $("#results-panel").scrollIntoView({ behavior: "smooth", block: "start" });
  } catch (error) {
    showToast(error.message || "Falha ao executar a revisão local.");
  } finally {
    setBusy(false);
  }
}

function renderResults() {
  const result = state.result;
  const summary = result.summary;
  $("#total-count").textContent = result.diagnostics.length;
  $("#error-count").textContent = summary.errors;
  $("#warning-count").textContent = summary.warnings;
  $("#info-count").textContent = summary.info;
  $("#filter-all-count").textContent = result.diagnostics.length;
  $("#filter-error-count").textContent = summary.errors;
  $("#filter-warning-count").textContent = summary.warnings;
  $("#filter-info-count").textContent = summary.info;
  $("#result-filename").textContent = state.file.name;
  const sourceMeta = state.format === "pdf" ? "PDF convertido localmente · " : "";
  $("#result-file-meta").textContent = `${sourceMeta}${result.configuration.level} · ${result.configuration.locale}`;
  $$(".filter-button").forEach((button) => button.classList.toggle("active", button.dataset.filter === state.filter));

  const diagnostics = state.filter === "all" ? result.diagnostics : result.diagnostics.filter((item) => item.severity === state.filter);
  $("#empty-results").hidden = diagnostics.length > 0;
  $("#diagnostics-list").innerHTML = diagnostics.map((item, index) => diagnosticMarkup(item, index)).join("");
  $("#diagnostics-list").hidden = diagnostics.length === 0;
  $$(".copy-button").forEach((button) => button.addEventListener("click", () => copySuggestion(button.dataset.value)));
}

function diagnosticMarkup(item, index) {
  const severity = item.severity || "info";
  const position = item.range?.start || { line: 0, column: 0 };
  const evidence = escapeHtml(item.evidence || "Trecho não informado");
  const suggestion = item.suggestion ? `<p class="diagnostic-suggestion"><span>↳ sugestão</span>${escapeHtml(item.suggestion)}</p>` : "";
  const copyValue = item.suggestion || item.message;
  return `<article class="diagnostic-item">
    <div class="diagnostic-index">${String(index + 1).padStart(2, "0")}<br><span>L${position.line}:C${position.column}</span></div>
    <div class="diagnostic-main">
      <h3>${escapeHtml(item.message)}</h3>
      <div class="diagnostic-meta"><span class="severity-tag severity-${severity}">${severity}</span><span>${escapeHtml(item.rule)}</span><span>·</span><span>${escapeHtml(item.mode || "automatic")}</span>${item.confidence !== null && item.confidence !== undefined ? `<span>· confiança ${Math.round(item.confidence * 100)}%</span>` : ""}</div>
      <p class="diagnostic-evidence"><strong>evidência</strong> ${evidence}</p>${suggestion}
    </div>
    <button class="copy-button" type="button" data-value="${escapeAttribute(copyValue)}">${item.suggestion ? "Copiar sugestão" : "Copiar achado"}</button>
  </article>`;
}

function escapeHtml(value) { return String(value).replace(/[&<>\"']/g, (char) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#039;" })[char]); }
function escapeAttribute(value) { return escapeHtml(value).replace(/`/g, "&#096;"); }

async function copySuggestion(value) {
  try { await navigator.clipboard.writeText(value); showToast("Texto copiado."); }
  catch { showToast("Não foi possível copiar automaticamente."); }
}

function exportResult() {
  if (!state.result) return;
  const blob = new Blob([JSON.stringify(state.result, null, 2)], { type: "application/json" });
  const link = document.createElement("a");
  link.href = URL.createObjectURL(blob);
  link.download = `${state.file.name.replace(/\.[^.]+$/, "") || "revisao"}.pte-report.json`;
  link.click();
  URL.revokeObjectURL(link.href);
  showToast("Relatório JSON exportado.");
}

function clearDocument() {
  state.file = null; state.content = null; state.format = null; state.result = null;
  $("#file-input").value = "";
  $("#selection-note").textContent = "Nenhum documento selecionado.";
  $("#review-button").disabled = true;
  $("#results-panel").hidden = true;
  setUploadError("");
  $(".hero").scrollIntoView({ behavior: "smooth", block: "start" });
  showToast("Documento removido da sessão.");
}

async function boot() {
  try {
    const response = await fetch("/api/v1/capabilities", { cache: "no-store" });
    if (!response.ok) throw new Error("Serviço local indisponível");
    state.capabilities = await response.json();
    state.token = state.capabilities.session_token;
    $("#engine-version").textContent = `PTE-LINT ${state.capabilities.engine_version}`;
    if (!state.capabilities.formats.includes("pdf")) {
      $("#upload-help").textContent = "Markdown ou texto simples · PDF requer bundle install";
    }
  } catch {
    $("#engine-version").textContent = "serviço local indisponível";
    setUploadError("Inicie o serviço local para usar o revisor.");
  }
}

$("#browse-button").addEventListener("click", () => $("#file-input").click());
$("#file-input").addEventListener("change", (event) => selectFile(event.target.files[0]));
$("#review-button").addEventListener("click", reviewDocument);
$("#export-button").addEventListener("click", exportResult);
$("#clear-button").addEventListener("click", clearDocument);
$$('.filter-button').forEach((button) => button.addEventListener("click", () => { state.filter = button.dataset.filter; renderResults(); }));

const dropZone = $("#drop-zone");
dropZone.addEventListener("dragover", (event) => { event.preventDefault(); dropZone.classList.add("is-dragover"); });
dropZone.addEventListener("dragleave", () => dropZone.classList.remove("is-dragover"));
dropZone.addEventListener("drop", (event) => { event.preventDefault(); dropZone.classList.remove("is-dragover"); selectFile(event.dataTransfer.files[0]); });
dropZone.addEventListener("keydown", (event) => { if (event.key === "Enter" || event.key === " ") { event.preventDefault(); $("#file-input").click(); } });

boot();

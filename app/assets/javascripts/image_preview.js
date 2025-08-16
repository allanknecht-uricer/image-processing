document.addEventListener("DOMContentLoaded", () => {
  // ---- refs de A e B para preview ----
  const inputA   = document.getElementById("inputA");
  const previewA = document.getElementById("previewA");
  const captionA = document.getElementById("captionA");

  const inputB   = document.getElementById("inputB");
  const previewB = document.getElementById("previewB");
  const captionB = document.getElementById("captionB");

  // ---- função de preview (proporcional, sem distorcer) ----
  function setPreview(file, previewEl, captionEl) {
    if (!previewEl) return;
    if (!file) {
      previewEl.innerHTML = '<div class="text-muted">Nenhuma imagem</div>';
      if (captionEl) captionEl.textContent = "";
      return;
    }
    if (!file.type.startsWith("image/")) {
      previewEl.innerHTML = '<div class="text-danger">Arquivo não é uma imagem</div>';
      if (captionEl) captionEl.textContent = "";
      return;
    }

    const url = URL.createObjectURL(file);
    const img = document.createElement("img");
    img.className = "img-preview";     // CSS garante contain
    img.alt = `Prévia de ${file.name}`;
    img.onload = () => URL.revokeObjectURL(url);
    img.src = url;

    previewEl.innerHTML = "";
    previewEl.appendChild(img);
    if (captionEl) captionEl.textContent = file.name;
  }

  function wirePreview(inputEl, previewEl, captionEl) {
    if (!inputEl || !previewEl) return;
    // estado inicial
    previewEl.innerHTML = '<div class="text-muted">Nenhuma imagem</div>';
    if (captionEl) captionEl.textContent = "";
    // change
    inputEl.addEventListener("change", () => {
      const file = inputEl.files && inputEl.files[0];
      setPreview(file, previewEl, captionEl);
    });
  }

  wirePreview(inputA, previewA, captionA);
  wirePreview(inputB, previewB, captionB);

  // ---- toggle B (input/card/abas/panes) ----
  const useB        = document.getElementById("useB");
  const inputBGroup = document.getElementById("inputBGroup");
  const cardB       = document.getElementById("cardB");
  const tabBItem    = document.getElementById("tab-b-item");
  const paneB       = document.getElementById("pane-b");
  const tabMixItem  = document.getElementById("tab-mix-item");
  const paneMix     = document.getElementById("pane-mix");
  const tabAButton  = document.getElementById("tab-a");

  function ensureTabAIfHidden() {
    const active = document.querySelector('#opsContent .tab-pane.show.active');
    if (active && (active.id === "pane-b" || active.id === "pane-mix")) {
      const tab = new bootstrap.Tab(tabAButton);
      tab.show();
    }
  }

  function toggleB() {
    const on = useB && useB.checked;
    [inputBGroup, cardB, tabBItem, paneB, tabMixItem, paneMix].forEach(el => {
      if (el) el.classList.toggle("d-none", !on);
    });
    if (!on) {
      ensureTabAIfHidden();
      if (inputB)   inputB.value = "";
      if (previewB) previewB.innerHTML = '<div class="text-muted">Nenhuma imagem</div>';
      if (captionB) captionB.textContent = "";
    }
  }

  if (useB) {
    toggleB();                   // estado inicial
    useB.addEventListener("change", toggleB);
  }

  // ---- sliders: mostrar valor em tempo real ----
  function bindSlider(id, outId, suffix = "") {
    const s = document.getElementById(id);
    const o = document.getElementById(outId);
    if (s && o) {
      o.textContent = `${s.value}${suffix}`;
      s.addEventListener("input", () => (o.textContent = `${s.value}${suffix}`));
    }
  }
  bindSlider("addA", "addA_out");
  bindSlider("addB", "addB_out");
  bindSlider("alphaA", "alphaA_out", "%");
  bindSlider("alphaB", "alphaB_out", "%");
});

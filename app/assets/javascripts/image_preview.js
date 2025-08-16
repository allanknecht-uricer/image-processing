document.addEventListener("DOMContentLoaded", () => {
    const inputA   = document.getElementById("inputA");
    const inputB   = document.getElementById("inputB");
    const previewA = document.getElementById("previewA");
    const previewB = document.getElementById("previewB");
  
    function showPreview(input, preview) {
      if (!input || !preview) return;
  
      input.addEventListener("change", () => {
        const file = input.files && input.files[0];
  
        if (!file) {
          preview.innerHTML = '<div class="text-muted">Nenhuma imagem</div>';
          return;
        }
        if (!file.type.startsWith("image/")) {
          preview.innerHTML = '<div class="text-danger">Arquivo não é imagem</div>';
          return;
        }
  
        const reader = new FileReader();
        reader.onload = (e) => {
          preview.innerHTML = `<img src="${e.target.result}" class="img-fluid rounded" alt="Prévia">`;
        };
        reader.readAsDataURL(file);
      });
    }
  
    showPreview(inputA, previewA);
    showPreview(inputB, previewB);
  });
  
document.addEventListener("DOMContentLoaded", () => {
  const dots = Array.from(document.querySelectorAll(".pin-dots span"));
  const buttons = Array.from(document.querySelectorAll(".pin-pad .horse-btn"));

  if (!dots.length || !buttons.length) return;

  let pin = "";

  const renderDots = () => {
    dots.forEach((d, i) => d.style.background = i < pin.length ? "#ff7a00" : "#ddd");
  };

  const reset = () => {
    pin = "";
    renderDots();
  };

  const unlock = async () => {
    try {
      const res = await fetch("/api/vault/unlock", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ pin })
      });
      const data = await res.json();
      if (data.ok) {
        window.location.href = "/vault/home";
      } else {
        reset();
        alert("PINが違う");
      }
    } catch (e) {
      reset();
      alert("通信エラー");
    }
  };

  buttons.forEach(btn => {
    btn.addEventListener("click", () => {
      const v = btn.textContent.trim();
      if (!/^\d$/.test(v)) return;

      if (pin.length >= 4) return;
      pin += v;
      renderDots();

      if (pin.length === 4) unlock();
    });
  });

  // 長押しでリセット（スマホ向け）
  document.querySelector(".pin-dots")?.addEventListener("click", reset);
});

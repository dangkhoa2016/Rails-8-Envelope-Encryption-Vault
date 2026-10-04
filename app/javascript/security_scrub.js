const scrubSecrets = () => {
  document.querySelectorAll("[data-secret-value]").forEach((node) => {
    node.textContent = "••••••••••••"
  })

  document.querySelectorAll("[data-secret-input]").forEach((node) => {
    if (node instanceof HTMLInputElement || node instanceof HTMLTextAreaElement) node.value = ""
  })
}

document.addEventListener("turbo:before-cache", scrubSecrets)
window.addEventListener("pagehide", scrubSecrets)
document.addEventListener("visibilitychange", () => {
  if (document.visibilityState === "hidden") scrubSecrets()
})

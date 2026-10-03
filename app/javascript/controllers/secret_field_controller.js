import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "input",
    "toggle",
    "generator",
    "length",
    "lengthOutput",
    "uppercase",
    "lowercase",
    "numbers",
    "symbols",
    "ambiguous",
    "status",
    "strength"
  ]

  static characterSets = {
    uppercase: "ABCDEFGHJKLMNPQRSTUVWXYZ",
    lowercase: "abcdefghijkmnopqrstuvwxyz",
    numbers: "23456789",
    symbols: "!@#$%^&*_-+="
  }

  static ambiguousCharacters = "Il1O0o"

  toggle() {
    const revealed = this.inputTarget.type === "text"
    this.inputTarget.type = revealed ? "password" : "text"
    if (this.hasToggleTarget) this.toggleTarget.textContent = revealed ? "Reveal" : "Hide"
  }

  toggleGenerator() {
    if (!this.hasGeneratorTarget) return

    const hidden = this.generatorTarget.classList.toggle("hidden")
    this.element.querySelector("[data-generator-toggle]")?.setAttribute("aria-expanded", (!hidden).toString())
    if (!hidden) this.updateStrength()
  }

  applyPreset(event) {
    const preset = event.currentTarget.dataset.preset

    if (preset === "balanced") {
      this.lengthTarget.value = 24
      this.setGroups({ uppercase: true, lowercase: true, numbers: true, symbols: true, ambiguous: true })
    } else if (preset === "strong") {
      this.lengthTarget.value = 32
      this.setGroups({ uppercase: true, lowercase: true, numbers: true, symbols: true, ambiguous: true })
    } else if (preset === "compatible") {
      this.lengthTarget.value = 20
      this.setGroups({ uppercase: true, lowercase: true, numbers: true, symbols: false, ambiguous: true })
    }

    this.updateLength()
    this.generate()
  }

  setGroups({ uppercase, lowercase, numbers, symbols, ambiguous }) {
    this.uppercaseTarget.checked = uppercase
    this.lowercaseTarget.checked = lowercase
    this.numbersTarget.checked = numbers
    this.symbolsTarget.checked = symbols
    this.ambiguousTarget.checked = ambiguous
  }

  updateLength() {
    if (this.hasLengthOutputTarget) this.lengthOutputTarget.textContent = this.lengthTarget.value
    this.updateStrength()
  }

  updateStrength() {
    if (!this.hasStrengthTarget) return

    const groups = this.selectedGroups()
    const alphabetSize = groups.join("").length
    if (alphabetSize === 0) {
      this.strengthTarget.textContent = "Choose at least one character type."
      return
    }

    const bits = Math.floor(this.clampedLength() * Math.log2(alphabetSize))
    this.strengthTarget.textContent = `Estimated search space: about ${bits} bits. This is an estimate, not a guarantee of security.`
  }

  generate() {
    const groups = this.selectedGroups()

    if (groups.length === 0) {
      this.announce("Choose at least one character type")
      this.updateStrength()
      return
    }

    const length = this.clampedLength()
    const required = groups.map(group => this.randomCharacter(group))
    const alphabet = groups.join("")
    const remaining = Array.from({ length: Math.max(length - required.length, 0) }, () => this.randomCharacter(alphabet))
    const generated = this.secureShuffle(required.concat(remaining)).join("").slice(0, length)

    this.inputTarget.value = generated
    this.inputTarget.dispatchEvent(new Event("input", { bubbles: true }))
    this.updateStrength()
    this.announce(`Generated ${length}-character secret`)
  }

  selectedGroups() {
    const groups = []
    if (this.uppercaseTarget.checked) groups.push(this.filteredSet(this.constructor.characterSets.uppercase))
    if (this.lowercaseTarget.checked) groups.push(this.filteredSet(this.constructor.characterSets.lowercase))
    if (this.numbersTarget.checked) groups.push(this.filteredSet(this.constructor.characterSets.numbers))
    if (this.symbolsTarget.checked) groups.push(this.filteredSet(this.constructor.characterSets.symbols))
    return groups.filter(group => group.length > 0)
  }

  filteredSet(characters) {
    if (!this.hasAmbiguousTarget || !this.ambiguousTarget.checked) return characters

    const ambiguous = new Set(this.constructor.ambiguousCharacters.split(""))
    return characters.split("").filter(character => !ambiguous.has(character)).join("")
  }

  clampedLength() {
    return Math.min(64, Math.max(16, Number.parseInt(this.lengthTarget.value, 10) || 24))
  }

  randomCharacter(characters) {
    return characters[this.randomIndex(characters.length)]
  }

  randomIndex(limit) {
    if (limit <= 0) throw new Error("Character set cannot be empty")

    const max = 0x100000000
    const cutoff = max - (max % limit)
    const value = new Uint32Array(1)

    do {
      window.crypto.getRandomValues(value)
    } while (value[0] >= cutoff)

    return value[0] % limit
  }

  secureShuffle(values) {
    for (let index = values.length - 1; index > 0; index -= 1) {
      const swapIndex = this.randomIndex(index + 1)
      ;[values[index], values[swapIndex]] = [values[swapIndex], values[index]]
    }
    return values
  }

  announce(message) {
    if (!this.hasStatusTarget) return

    this.statusTarget.textContent = message
    window.clearTimeout(this.statusTimer)
    this.statusTimer = window.setTimeout(() => {
      this.statusTarget.textContent = ""
    }, 2800)
  }

  disconnect() {
    window.clearTimeout(this.statusTimer)
  }
}

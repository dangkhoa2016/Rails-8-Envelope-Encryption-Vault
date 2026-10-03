module VaultItemsHelper
  KIND_ICONS = {
    "login" => "M13.5 4.5H7.5A2.25 2.25 0 0 0 5.25 6.75v10.5A2.25 2.25 0 0 0 7.5 19.5h6M10.5 12h8.25m-3-3 3 3-3 3",
    "code" => "m8.25 9-3 3 3 3m7.5-6 3 3-3 3M14.25 6l-4.5 12",
    "terminal" => "M6.75 7.5 10.5 11.25 6.75 15m5.25 0h5.25",
    "database" => "M4.5 6.75c0 1.243 3.358 2.25 7.5 2.25s7.5-1.007 7.5-2.25S16.142 4.5 12 4.5 4.5 5.507 4.5 6.75Zm0 0v4.5c0 1.243 3.358 2.25 7.5 2.25s7.5-1.007 7.5-2.25v-4.5m-15 4.5v4.5C4.5 16.993 7.858 18 12 18s7.5-1.007 7.5-2.25v-4.5",
    "note" => "M6.75 3.75h7.5l3 3v13.5H6.75V3.75Zm7.5 0v3h3m-7.5 4.5h4.5m-4.5 3h4.5",
    "server" => "M5.25 5.25h13.5v5.25H5.25V5.25Zm0 8.25h13.5v5.25H5.25V13.5Zm2.25-5.625h.008v.008H7.5v-.008Zm0 8.25h.008v.008H7.5v-.008Z",
    "lock" => "M7.5 10.5V8.25a4.5 4.5 0 0 1 9 0v2.25m-10.5 0h12v9h-12v-9Z"
  }.freeze

  KIND_ACCENTS = {
    "indigo" => "border-indigo-400/20 bg-indigo-400/10 text-indigo-200",
    "cyan" => "border-cyan-400/20 bg-cyan-400/10 text-cyan-200",
    "emerald" => "border-emerald-400/20 bg-emerald-400/10 text-emerald-200",
    "violet" => "border-violet-400/20 bg-violet-400/10 text-violet-200",
    "amber" => "border-amber-400/20 bg-amber-400/10 text-amber-200",
    "sky" => "border-sky-400/20 bg-sky-400/10 text-sky-200",
    "slate" => "border-slate-400/20 bg-slate-400/10 text-slate-200"
  }.freeze

  def vault_kind_metadata(kind)
    VaultItem::KIND_METADATA.fetch(kind.to_s, VaultItem::KIND_METADATA.fetch("generic"))
  end

  def vault_kind_label(kind)
    vault_kind_metadata(kind).fetch(:label)
  end

  def vault_kind_description(kind)
    vault_kind_metadata(kind).fetch(:description)
  end

  def vault_kind_best_for(kind)
    vault_kind_metadata(kind).fetch(:best_for)
  end

  def vault_kind_fields(kind)
    vault_kind_metadata(kind).fetch(:fields)
  end

  def vault_kind_badge_classes(kind)
    accent = vault_kind_metadata(kind).fetch(:accent)
    "inline-flex items-center rounded-full border px-2.5 py-1 text-xs font-medium #{KIND_ACCENTS.fetch(accent)}"
  end

  def vault_kind_icon(kind, css: "h-5 w-5")
    path = KIND_ICONS.fetch(vault_kind_metadata(kind).fetch(:icon))
    tag.svg(class: css, viewBox: "0 0 24 24", fill: "none", stroke: "currentColor", "stroke-width": 1.6, "aria-hidden": true) do
      tag.path(d: path, "stroke-linecap": "round", "stroke-linejoin": "round")
    end
  end
end

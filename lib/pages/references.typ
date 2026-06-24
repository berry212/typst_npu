#import "@preview/gb7714-bilingual:0.2.3": gb7714-bibliography
#import "../utils/style.typ": 字号

#let normalize-patent-owner(owner) = {
  if owner == none { return "" }
  str(owner).replace(regex("\s+and\s+"), "、")
}

#let normalize-biblio-names(names, lang: "zh") = {
  if names == none { return "" }
  let text = str(names)
  if lang == "zh" {
    text.replace(regex("\s+and\s+"), "、")
  } else {
    text.replace(regex("\s+and\s+"), ", ")
  }
}

// 将英文 "First Last" 格式转换为 "Last F." 格式（姓首字母大写，名缩写）
#let format-en-name(text) = {
  if text == "" { return "" }
  // 如果已经是 "Last, First" 格式（含逗号），翻转并缩写
  if text.find(",") != none {
    let parts = text.split(", ")
    let last = parts.at(0)
    let first = parts.at(1)
    let initials = first
      .split(" ")
      .map(g => {
        if g.len() > 0 { upper(g.first()) } else { "" }
      })
      .join(" ")
    return last + " " + initials
  }
  // "First Middle Last" 格式 → "Last F M"
  let parts = text.split(" ")
  if parts.len() == 1 { return text } // 只有一个词，直接返回
  let last = parts.last()
  let first-parts = parts.slice(0, parts.len() - 1)
  let initials = first-parts
    .map(g => {
      if g.len() > 0 { upper(g.first()) } else { "" }
    })
    .join(" ")
  return last + " " + initials
}

// 格式化作者字符串，正确处理英文姓/名顺序，超过3个作者显示 et al.
#let format-authors-en(text) = {
  if text == "" { return "" }
  let names = text.split(regex("\s+and\s+"))
  let formatted = names.map(name => format-en-name(name.trim()))
  let max-authors = 3
  if formatted.len() > max-authors {
    formatted.slice(0, max-authors).join(", ") + ", et al"
  } else {
    formatted.join(", ")
  }
}

#let is-custom-standard-entry(entry) = {
  let raw-type = lower(str(entry.entry-type))
  let fields = entry.fields
  let mark = upper(str(fields.at("mark", default: fields.at("usera", default: ""))))
  let subtype = lower(str(fields.at("entrysubtype", default: "")))
  let note = lower(str(fields.at("note", default: "")))
  let number = upper(str(fields.at("number", default: fields.at("serial-number", default: ""))))
  let std-prefixes = ("GB", "ISO", "IEC", "IEEE", "ANSI", "DIN", "JIS", "BS")

  return (
    raw-type == "standard"
      or mark == "S"
      or (
        (raw-type == "book" or raw-type == "inbook" or raw-type == "unknown")
          and (subtype == "standard" or note == "standard")
      )
      or ((raw-type == "unknown" or raw-type == "misc") and std-prefixes.any(prefix => number.starts-with(prefix)))
  )
}

#let is-custom-other-entry(entry) = {
  let raw-type = lower(str(entry.entry-type))
  let fields = entry.fields
  let subtype = lower(str(fields.at("entrysubtype", default: "")))
  let note = lower(str(fields.at("note", default: "")))
  let mark = str(fields.at("mark", default: fields.at("usera", default: "")))
  let medium = str(fields.at("medium", default: ""))
  let url = str(fields.at("url", default: fields.at("howpublished", default: "")))

  return (
    raw-type == "other"
      or subtype == "other"
      or note == "other"
      or (raw-type in ("misc", "unknown") and url != "" and mark == "" and medium == "")
  )
}

#let render-custom-patent(entry) = {
  let fields = entry.fields
  let owner = normalize-patent-owner(fields.at("author", default: fields.at("holder", default: "")))
  let title = fields.at("title", default: "")
  let country = fields.at("location", default: fields.at("address", default: ""))
  let patent-number = fields.at("number", default: fields.at("call-number", default: ""))
  let publish-date = fields.at("date", default: fields.at("issued", default: fields.at("year", default: "")))

  let body = []
  if owner != "" {
    body += [#owner. ]
  }
  body += [#title]
  body += [[P]. ]
  if country != "" {
    body += [#country: ]
  }
  if patent-number != "" {
    body += [#patent-number]
  }
  if patent-number != "" and publish-date != "" {
    body += [, ]
  }
  if publish-date != "" {
    body += [#publish-date]
  }
  body += [. #entry.ref-label]
  body
}

#let render-custom-article(entry) = {
  let fields = entry.fields
  let lang = entry.lang
  let raw-author = fields.at("author", default: "")
  let author = if lang == "zh" {
    normalize-biblio-names(raw-author, lang: lang)
  } else {
    format-authors-en(str(raw-author))
  }
  let title = fields.at("title", default: "")
  let journal = fields.at("journal", default: fields.at("booktitle", default: ""))
  let year = str(fields.at("year", default: ""))
  let volume = str(fields.at("volume", default: ""))
  let number = str(fields.at("number", default: ""))
  let pages = str(fields.at("pages", default: "")).replace("--", "-")
  let pub-sep = if lang == "zh" { "：" } else { ": " }
  let year-sep = if lang == "zh" { "，" } else { ", " }

  let body = []
  if author != "" {
    body += [#author. ]
  }
  body += [#title]
  body += [[J]. ]
  if journal != "" {
    body += [#journal]
  }
  if year != "" {
    body += [. #year]
  }
  if volume != "" {
    body += [, #volume]
  }
  if number != "" {
    body += [(#number)]
  }
  if pages != "" {
    body += [: #pages]
  }
  body += [. #entry.ref-label]
  body
}

#let render-custom-conference(entry, graduate: false) = {
  let fields = entry.fields
  let lang = entry.lang
  let raw-author = fields.at("author", default: "")
  let author = if lang == "zh" {
    normalize-biblio-names(raw-author, lang: lang)
  } else {
    format-authors-en(str(raw-author))
  }
  let editor = normalize-biblio-names(
    fields.at("editor", default: fields.at("bookauthor", default: "")),
    lang: lang,
  )
  let title = fields.at("title", default: "")
  let proceedings-title = fields.at("booktitle", default: fields.at("titleaddon", default: ""))
  let location = fields.at("location", default: fields.at("address", default: ""))
  let publisher = fields.at("publisher", default: fields.at("institution", default: ""))
  let year = str(fields.at("year", default: fields.at("date", default: "")))
  let pages = str(fields.at("pages", default: "")).replace("--", "-")
  let year-sep = if lang == "zh" { "，" } else { ", " }

  let body = []
  if author != "" {
    body += [#author. ]
  }
  body += [#title]
  body += [[C]. ]
  if proceedings-title != "" {
    body += [#proceedings-title]
  }
  if location != "" {
    body += [, #location]
  }
  if publisher != "" {
    body += [, #publisher]
  }
  if year != "" {
    body += [. #year]
  }
  if pages != "" {
    if graduate {
      body += [: #pages. #entry.ref-label]
    } else {
      body += [. #pages. #entry.ref-label]
    }
  } else {
    body += [. #entry.ref-label]
  }
  body
}

#let render-custom-other(entry) = {
  let fields = entry.fields
  let lang = entry.lang
  let author = normalize-biblio-names(fields.at("author", default: fields.at("organization", default: "")), lang: lang)
  let title = fields.at("title", default: "")
  let publish-date = str(fields.at("date", default: fields.at("year", default: fields.at("issued", default: fields.at(
    "updated",
    default: "",
  )))))
  let cited-date = str(fields.at("urldate", default: fields.at("accessed", default: "")))
  let url = str(fields.at("url", default: fields.at("howpublished", default: "")))

  let body = []
  if author != "" {
    body += [#author. ]
  }
  if title != "" {
    body += [#title. ]
  }
  if publish-date != "" {
    body += [#publish-date]
    if cited-date != "" {
      body += [/#cited-date]
    }
    body += [. ]
  } else if cited-date != "" {
    body += [/#cited-date. ]
  }
  if url != "" {
    body += [#url. #entry.ref-label]
  } else {
    body += [#entry.ref-label]
  }
  body
}

#let render-custom-standard(entry) = {
  let fields = entry.fields
  let lang = entry.lang
  let drafter = normalize-biblio-names(fields.at("author", default: fields.at("organization", default: "")), lang: lang)
  let standard-number = str(fields.at("number", default: fields.at("serial-number", default: "")))
  let title = fields.at("title", default: "")
  let location = fields.at("location", default: fields.at("address", default: ""))
  let publisher = fields.at("publisher", default: fields.at("institution", default: ""))
  let year = str(fields.at("year", default: fields.at("date", default: "")))

  let body = []
  if drafter != "" {
    body += [#drafter. ]
  }
  if standard-number != "" and title != "" {
    body += [#(standard-number + "，" + str(title))]
  } else if standard-number != "" {
    body += [#standard-number]
  } else if title != "" {
    body += [#title]
  }
  if location == "" and publisher == "" and year == "" {
    body += [[S]. #entry.ref-label]
    return body
  }

  body += [[S]. ]
  if location != "" {
    body += [#location]
    if publisher != "" {
      body += [：]
    } else if year != "" {
      body += [，]
    } else {
      body += [. #entry.ref-label]
      return body
    }
  }
  if publisher != "" {
    body += [#publisher]
    if year != "" {
      body += [，]
    } else {
      body += [. #entry.ref-label]
      return body
    }
  }
  if year != "" {
    body += [#year. #entry.ref-label]
  } else {
    body += [#entry.ref-label]
  }
  body
}

#let bilingual-bibliography(
  graduate: false,
  english-writing: false,
  title: auto,
  full: false,
) = {
  if title == auto {
    title = if english-writing { "References" } else { "参考文献" }
  }

  heading(level: 1, numbering: none, outlined: true)[#title]

  gb7714-bibliography(
    title: none,
    full: full,
    full-control: entries => {
      set par(
        hanging-indent: 0em,
        first-line-indent: if graduate { (amount: 2em, all: true) } else { (amount: 0em, all: true) },
      )
      for entry in entries {
        if entry.entry-type == "patent" {
          [[#entry.order]#h(0.5em)#render-custom-patent(entry)]
        } else if entry.entry-type == "inproceedings" or entry.entry-type == "conference" {
          [[#entry.order]#h(0.5em)#render-custom-conference(entry, graduate: graduate)]
        } else if is-custom-other-entry(entry) {
          [[#entry.order]#h(0.5em)#render-custom-other(entry)]
        } else if is-custom-standard-entry(entry) {
          [[#entry.order]#h(0.5em)#render-custom-standard(entry)]
        } else if entry.entry-type == "article" {
          // 对 article 类型也使用自定义渲染，避免 v2025 中文标点问题
          [[#entry.order]#h(0.5em)#render-custom-article(entry)]
        } else {
          [[#entry.order]#h(0.5em)#entry.labeled-rendered]
        }
        parbreak()
      }
    },
  )
}

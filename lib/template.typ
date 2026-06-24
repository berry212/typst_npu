#import "layouts/doc.typ": doc
#import "utils/algorithm.typ": algorithm, algorithm-ref, indent, no-number, pseudocode-list, with-english-writing
#import "utils/equation-note.typ": equation-note
#import "layouts/mainmatter.typ": frontmatter, mainmatter
#import "layouts/appendix.typ": appendix as appendix-layout
#import "pages/bachelor-cover.typ": bachelor-cover
#import "pages/graduate-cover.typ": master-cover
#import "pages/abstract.typ": abstract as abstract-page
#import "pages/outline.typ": outline-page
#import "pages/backmatter-page.typ": backmatter-page
#import "@preview/gb7714-bilingual:0.2.3": init-gb7714, multicite
#import "pages/references.typ": bilingual-bibliography
#import "@preview/cap-able:0.0.2": capfig, capfig-style, capsubfig, captab, captab-style, captnote
#import "format.typ": body-format, heading-format
#import "utils/chinese-number.typ": chinese-chapter-number
#import "utils/cover-utils.typ": blind-review

#let default-bibliography(graduate) = {
  if not graduate {
    "../template/bib/bachelor.bib"
  } else {
    "../template/bib/graduate.bib"
  }
}

// 主配置函数
#let nwpu-thesis(
  // 文档类型
  graduate: false,
  degree: "master", // "master" | "doctor"（仅研究生）
  track: "academic", // "academic" | "professional"（仅研究生）
  anonymous: false,
  english-writing: false,
  colored-cover: false,
  // 基本信息（本科 & 研究生共用）
  title: ("基于 Typst 的", "西北工业大学学位论文"),
  author: "张三",
  major: "某专业",
  supervisor: ("李四", "教授"),
  submit-date: datetime.today(),
  // 研究生额外信息
  title-en: "NPU Thesis Template for Typst",
  student-id: "1234567890",
  class-no: "O643.12",
  author-en: "Zhang San",
  department: "某学院",
  major-en: "XX",
  supervisor-en: "Li Si",
  secret-level: "公开",
  school-code: "10699",
  reviewers: (
    (name: "", title: "", unit: ""),
  ),
  defence-committee: (
    date: datetime.today(),
    chairman: (name: "", title: "", unit: ""),
    members: (
      (name: "", title: "", unit: ""),
      (name: "", title: "", unit: ""),
    ),
    secretary: (name: "", title: "", unit: ""),
  ),
  // 页面内容
  abstract: none,
  keywords: (),
  funding: none,
  abstract-en: none,
  keywords-en: (),
  funding-en: none,
  acknowledgement: none,
  academic-achievements: none,
  appendix: none,
  scan-declaration: none,
  design_summary: none,
  bibliography: none,
  info: (:),
  // 文档正文
  body,
) = {
  if bibliography == none {
    bibliography = default-bibliography(graduate)
  }

  // 默认参数
  info = (
    (
      title: title,
      title-en: title-en,
      student-id: student-id,
      class-no: class-no,
      author: author,
      author-en: author-en,
      department: department,
      major: major,
      major-en: major-en,
      supervisor: supervisor,
      supervisor-en: supervisor-en,
      submit-date: if type(submit-date) == dictionary {
        datetime(year: submit-date.year, month: submit-date.month, day: 1)
      } else {
        submit-date
      },
      secret-level: secret-level,
      school-code: school-code,
      degree: if degree == "doctor" { "工学博士" } else { "工学硕士" },
      reviewers: reviewers,
      defence-committee: defence-committee,
    )
      + info
  )

  // 1. 文稿设置
  show: doc.with(graduate: graduate)

  // 2. 封面
  if graduate {
    master-cover(
      degree: degree,
      track: track,
      colored-cover: colored-cover,
      anonymous: anonymous,
      info: info,
    )
  } else {
    bachelor-cover(
      anonymous: anonymous,
      info: info,
    )
  }

  show: init-gb7714.with(read(bibliography), style: "numeric", version: "2025")

  // 3. mainmatter 包裹所有后续内容（前置 + 正文 + 后置）
  show: mainmatter.with(
    graduate: graduate,
    degree: degree,
    english-writing: english-writing,
    leading: if graduate { body-format.graduate.leading } else { body-format.bachelor.leading },
    spacing: if graduate { body-format.graduate.spacing } else { body-format.bachelor.spacing },
    first-line-indent: if graduate { body-format.graduate.first-line-indent } else {
      body-format.bachelor.first-line-indent
    },
    heading-numbering: (..nums) => {
      let nums = nums.pos()
      if nums.len() == 1 {
        if english-writing {
          [Chapter #nums.at(0)#h(0.7em)]
        } else if graduate {
          [第 #nums.at(0) 章#h(0.7em)]
        } else {
          [第#chinese-chapter-number(nums.at(0))章　]
        }
      } else if nums.len() <= 3 {
        numbering("1.1", ..nums)
      }
    },
    heading_leading: if graduate { heading-format.graduate.leading } else { heading-format.bachelor.leading },
    heading-above: if graduate { heading-format.graduate.above } else { heading-format.bachelor.above },
    heading-below: if graduate { heading-format.graduate.below } else { heading-format.bachelor.below },
  )

  // 4. 前置部分（摘要、目录）
  frontmatter[
    #if abstract != none {
      if graduate {
        abstract-page(
          keywords: keywords,
          funding: funding,
          keywords-above: body-format.graduate.keywords-above,
        )[#abstract]
      } else {
        abstract-page(
          keywords: keywords,
          keyword-label: "关键词",
          keyword-sep: "，",
          keyword-indent: 0pt,
          outline-title: "摘 要",
          outlined: false,
          funding: none,
        )[#abstract]
      }
    }
    #if abstract-en != none {
      if graduate {
        abstract-page(
          keywords: keywords-en,
          funding: funding-en,
          keywords-above: body-format.graduate.keywords-above,
          keyword-label: "Key words",
          keyword-weight: "bold",
          keyword-sep: "; ",
          outline-title: "ABSTRACT",
          title: [*Abstract*],
        )[#abstract-en]
      } else {
        abstract-page(
          keywords: keywords-en,
          keyword-label: "KEY WORDS",
          keyword-weight: "bold",
          keyword-sep: ", ",
          keyword-indent: 0pt,
          outline-title: "ABSTRACT",
          outlined: false,
          funding: none,
        )[#abstract-en]
      }
    }

    #if graduate {
      outline-page(title: if english-writing { "Contents" } else { "目　录" })
    } else {
      outline-page(
        title: if english-writing { "Contents" } else { "目 录" },
        indent: (0pt, 24pt, 18pt),
        weight: ("bold", "regular", "regular"),
        fill: (repeat([#move(dy: -0.1em, text(size: 0.4em)[·])], gap: -0.1em),),
        title-weight: "bold",
        entry-spacing: (1.5em, 1em, 0.1em),
      )
    }

    #if graduate {
      pagebreak(weak: true, to: "odd")
    }
  ]

  [#metadata(none) <__nwpu_mainmatter_start__>]
  counter(page).update(1)

  // 5. 正文
  with-english-writing(english-writing, body)

  // 6. 后置部分
  if bibliography != none {
    bilingual-bibliography(
      graduate: graduate,
      english-writing: english-writing,
    )
  }

  if graduate {
    if appendix != none {
      show: appendix-layout.with(
        graduate: graduate,
        english-writing: english-writing,
      )
      [
        #heading(level: 1)[]
        #appendix
      ]
    }

    if acknowledgement != none {
      backmatter-page(title: if english-writing { "Acknowledgements" } else { "致　谢" })[#acknowledgement]
    }

    if academic-achievements != none {
      backmatter-page(
        title: if english-writing {
          "Academic Achievements and Research Experience"
        } else {
          "在学期间取得的学术成果和参加科研情况"
        },
      )[#academic-achievements]
    }
  } else {
    if acknowledgement != none {
      backmatter-page(title: if english-writing { "Acknowledgements" } else { "致 谢" })[#acknowledgement]
    }

    if design_summary != none {
      backmatter-page(
        title: if english-writing { "Design Summary" } else { "毕业设计小结" },
      )[#design_summary]
    }

    if appendix != none {
      show: appendix-layout.with(
        graduate: graduate,
        english-writing: english-writing,
      )
      [
        #heading(level: 1)[]
        #appendix
      ]
    }
  }

  if graduate {
    pagebreak(weak: true, to: "odd")
  }

  // 尾部独立页面（声明、封底）：统一无页眉页脚、无边距
  set page(margin: 0pt, header: none, footer: none)

  if scan-declaration != none and graduate {
    page[
      #scan-declaration
      #box(width: 0pt, height: 0pt)
    ]
  }

  if colored-cover and graduate {
    let bg = if degree == "doctor" {
      "assets/doctor-back-cover.jpg"
    } else if track == "professional" {
      "assets/professional-back-cover.jpg"
    } else {
      "assets/academic-back-cover.jpg"
    }
    page[
      #box(width: 0pt, height: 0pt)
    ]
    page(
      background: image(bg, width: 100%, height: 100%),
    )[
      #box(width: 1pt, height: 1pt)
    ]
  }
}

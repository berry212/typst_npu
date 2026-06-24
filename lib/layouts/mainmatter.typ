#import "@preview/cap-able:0.0.2": cap-style, capfig-style, captab-style
#import "../utils/style.typ": 字体, 字号
#import "../utils/custom-numbering.typ": show-equation-handler
#import "../utils/custom-heading.typ": active-heading, heading-display
#import "../utils/chinese-number.typ": chinese-chapter-number
#import "../utils/header.typ": bachelor-header-render, graduate-header-title, header-render, page-footer
#import "../format.typ": body-format, caption-format, heading-format, table-format

#let mainmatter(
  graduate: false,
  degree: "master",
  english-writing: false,
  leading: body-format.bachelor.leading,
  spacing: body-format.bachelor.spacing,
  first-line-indent: body-format.bachelor.first-line-indent,
  heading-numbering: none,
  heading_leading: heading-format.bachelor.leading,
  heading-above: heading-format.bachelor.above,
  heading-below: heading-format.bachelor.below,
  ..args,
  it,
) = {
  let equation-handler = show-equation-handler("1-1", graduate)

  // 重置页码为阿拉伯数字从1开始（由调用方在正文开始位置处理 pagebreak 和 counter reset）
  set page(footer: page-footer("1"))

  // 3.  辅助函数
  let array-at(arr, pos) = {
    arr.at(calc.min(pos, arr.len()) - 1)
  }

  // 4.  设置基本样式
  // 4.1 文本和段落样式
  set align(left)
  set par(
    leading: leading,
    justify: true,
    first-line-indent: first-line-indent,
    spacing: spacing,
  )
  // 4.4 设置 equation 的编号和假段落首行缩进
  set math.equation(supplement: if english-writing { [Equation] } else { [式] })
  show math.equation.where(block: true): equation-handler
  // 4.5 表格样式
  show table: set par(justify: false)
  set table(align: center + horizon)

  // 5.  处理标题
  // 5.1 设置标题的 Numbering
  set heading(numbering: heading-numbering)
  // 5.2 设置字体、字号、换页及段后段后间距
  show heading: it => {
    if it.level == 1 {
      counter(figure.where(kind: "algorithm")).update(0)
      counter(figure.where(kind: image)).update(0)
      counter(figure.where(kind: table)).update(0)
      counter(math.equation).update(0)
    }

    set text(
      font: 字体.黑体,
      size: (字号.三号, 字号.四号, 字号.小四).at(calc.min(it.level, 3) - 1),
      weight: "regular",
    )
    set par(leading: array-at(heading_leading, it.level), spacing: 0pt)

    // 一级标题统一换页
    if it.level == 1 {
      pagebreak(weak: true, to: if graduate { "odd" })
      v(array-at(heading-above, it.level))
    }

    let current-block-above = if it.level == 1 { 0pt } else { array-at(heading-above, it.level) }
    let current-block-below = array-at(heading-below, it.level)

    if it.level == 1 {
      set align(center)
      set block(above: current-block-above, below: current-block-below)
      it
    } else {
      set block(above: current-block-above, below: current-block-below)
      it
    }
  }

  // 6.  处理页眉
  set page(header: context {
    let loc = here()
    // 页眉内容
    let header-content = if graduate and calc.rem(loc.page(), 2) == 0 {
      // 偶数页：显示论文标题
      graduate-header-title(degree)
    } else {
      // 奇数页或单面打印：显示当前章标题
      heading-display(active-heading(level: 1, prev: false))
    }
    // 使用统一的页眉格式
    if graduate {
      header-render(header-content)
    } else {
      bachelor-header-render()
    }
  })

  // cap-able 全局样式（共享参数）
  show: cap-style.with(
    numbering-format: "1-1",
    use-chapter: true,
    caption-size: caption-format.size,
    pre-supplement-number-spacing: if english-writing { 0.3em } else { 0em },
  )

  // 表格独有配置
  show: captab-style.with(
    supplement: if english-writing { "Table" } else { "表" },
    body-size: 字号.五号,
    cell-inset: (x: 0.3em, y: if graduate { 0.55em } else { 0.7em }),
    middle-rule: (paint: black, thickness: 1pt),
  )

  // 图片独有配置
  show: capfig-style.with(
    supplement: if english-writing { "Figure" } else { "图" },
    show-subcaption: true,
    show-subcaption-label: true,
    label-style: "(a)",
  )
  it
}

// 前置部分（摘要、目录）：罗马数字页码 + 标题不编号
#let frontmatter(body) = {
  set page(footer: page-footer("I"))
  set heading(numbering: none)
  counter(page).update(1)
  body
}

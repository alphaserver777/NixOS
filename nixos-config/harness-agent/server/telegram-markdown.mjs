const MAX_MESSAGE = 3600

function escapeHtml(value = '') {
  return String(value)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
}

function formatInline(source) {
  const saved = []
  const hold = (html) => {
    const token = `@@DSHFORMAT${saved.length}@@`
    saved.push(html)
    return token
  }

  let text = source.replace(/`([^`\n]+)`/g, (_, code) =>
    hold(`<code>${escapeHtml(code)}</code>`))
  text = escapeHtml(text)
  text = text.replace(/\[([^\]]+)]\((https?:\/\/[^\s)]+)\)/g,
    (_, label, url) => `<a href="${url}">${label}</a>`)
  text = text.replace(/\[([^\]]+)]\(([^\s)]+)\)/g,
    (_, label, path) => `${label} (<code>${path}</code>)`)
  text = text.replace(/\*\*([^*\n]+)\*\*/g, '<b>$1</b>')
  text = text.replace(/__([^_\n]+)__/g, '<b>$1</b>')
  text = text.replace(/~~([^~\n]+)~~/g, '<s>$1</s>')
  text = text.replace(/(^|[^*])\*([^*\n]+)\*/g, '$1<i>$2</i>')

  return text.replace(/@@DSHFORMAT(\d+)@@/g, (_, index) => saved[Number(index)])
}

export function markdownToTelegramHtml(markdown = '') {
  const blocks = []
  const holdBlock = (html) => {
    const token = `@@DSHBLOCK${blocks.length}@@`
    blocks.push(html)
    return token
  }

  let text = String(markdown).replace(/```[^\n]*\n([\s\S]*?)```/g,
    (_, code) => holdBlock(`<pre><code>${escapeHtml(code.replace(/\n$/, ''))}</code></pre>`))

  const lines = text.split('\n').map((line) => {
    if (/^@@DSHBLOCK\d+@@$/.test(line.trim())) return line.trim()
    if (/^\s*\|?\s*:?-{3,}/.test(line)) return ''

    const heading = line.match(/^#{1,6}\s+(.+)$/)
    if (heading) return `<b>${formatInline(heading[1])}</b>`

    const quote = line.match(/^>\s?(.*)$/)
    if (quote) return `<blockquote>${formatInline(quote[1])}</blockquote>`

    const bullet = line.match(/^\s*[-*+]\s+(.+)$/)
    if (bullet) return `• ${formatInline(bullet[1])}`

    if (/^\s*\|.*\|\s*$/.test(line)) {
      const cells = line.trim().replace(/^\||\|$/g, '').split('|')
        .map((cell) => formatInline(cell.trim()))
      return cells.join(' · ')
    }

    return formatInline(line)
  })

  return lines.join('\n')
    .replace(/\n{3,}/g, '\n\n')
    .replace(/@@DSHBLOCK(\d+)@@/g, (_, index) => blocks[Number(index)])
    .trim()
}

function largestFittingPrefix(text) {
  let low = 1
  let high = text.length
  let best = 0

  while (low <= high) {
    const middle = Math.floor((low + high) / 2)
    if (markdownToTelegramHtml(text.slice(0, middle)).length <= MAX_MESSAGE) {
      best = middle
      low = middle + 1
    } else {
      high = middle - 1
    }
  }

  return Math.max(best, 1)
}

export function splitMarkdown(markdown) {
  const parts = []
  let current = ''

  for (const paragraph of String(markdown).split(/\n{2,}/)) {
    const candidate = current ? `${current}\n\n${paragraph}` : paragraph
    if (markdownToTelegramHtml(candidate).length <= MAX_MESSAGE) {
      current = candidate
      continue
    }
    if (current) parts.push(current)
    current = ''

    for (const line of paragraph.split('\n')) {
      const lineCandidate = current ? `${current}\n${line}` : line
      if (markdownToTelegramHtml(lineCandidate).length <= MAX_MESSAGE) {
        current = lineCandidate
      } else {
        if (current) parts.push(current)
        current = ''

        let remainder = line
        while (markdownToTelegramHtml(remainder).length > MAX_MESSAGE) {
          const boundary = largestFittingPrefix(remainder)
          parts.push(remainder.slice(0, boundary))
          remainder = remainder.slice(boundary)
        }
        current = remainder
      }
    }
  }

  if (current) parts.push(current)
  return parts.length ? parts : ['Ответ агента пуст.']
}

function splitEscapedText(text) {
  const parts = []
  let remainder = String(text)

  while (remainder) {
    let low = 1
    let high = remainder.length
    let best = 1
    while (low <= high) {
      const middle = Math.floor((low + high) / 2)
      if (escapeHtml(remainder.slice(0, middle)).length <= MAX_MESSAGE) {
        best = middle
        low = middle + 1
      } else {
        high = middle - 1
      }
    }
    parts.push(remainder.slice(0, best))
    remainder = remainder.slice(best)
  }

  return parts
}

export async function sendMarkdown(chatId, markdown, sender) {
  for (const part of splitMarkdown(markdown)) {
    const html = markdownToTelegramHtml(part)
    try {
      await sender(chatId, html)
    } catch {
      for (const plainPart of splitEscapedText(part)) {
        await sender(chatId, escapeHtml(plainPart))
      }
    }
  }
}

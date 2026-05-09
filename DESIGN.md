---
colors:
  primary:
    default: "#1A73E8"
    hover: "#1557B0"
    active: "#0D47A1"
    subtle: "#E8F0FE"
  neutral:
    background: "#FFFFFF"
    surface: "#F8F9FA"
    border: "#DADCE0"
    muted: "#5F6368"
    text: "#202124"
  feedback:
    success: "#1E8E3E"
    warning: "#F9AB00"
    error: "#D93025"
    info: "#1A73E8"
  accent:
    default: "#E8710A"

typography:
  heading:
    fontFamily: "Inter, sans-serif"
    fontWeight: 700
    lineHeight: 1.2
    letterSpacing: "-0.01em"
  body:
    fontFamily: "Inter, sans-serif"
    fontSize: "16px"
    fontWeight: 400
    lineHeight: 1.5
  label:
    fontFamily: "Inter, sans-serif"
    fontSize: "14px"
    fontWeight: 500
    lineHeight: 1.4
  code:
    fontFamily: "JetBrains Mono, monospace"
    fontSize: "14px"
    fontWeight: 400
    lineHeight: 1.6

spacing:
  xs: "4px"
  sm: "8px"
  md: "16px"
  lg: "24px"
  xl: "32px"
  2xl: "48px"
  3xl: "64px"

radius:
  sm: "4px"
  md: "8px"
  lg: "12px"
  xl: "24px"
  full: "9999px"

components:
  button:
    primary:
      background: "{colors.primary.default}"
      color: "#FFFFFF"
      radius: "{radius.md}"
      padding: "10px 20px"
    secondary:
      background: "transparent"
      border: "1px solid {colors.primary.default}"
      color: "{colors.primary.default}"
      radius: "{radius.md}"
      padding: "10px 20px"
    hover:
      primary:
        background: "{colors.primary.hover}"
      secondary:
        background: "{colors.primary.subtle}"
  card:
    background: "{colors.neutral.background}"
    border: "1px solid {colors.neutral.border}"
    radius: "{radius.lg}"
    padding: "{spacing.lg}"
  input:
    border: "1px solid {colors.neutral.border}"
    radius: "{radius.md}"
    padding: "10px 14px"
    focus:
      border: "2px solid {colors.primary.default}"
---

## Overview

Interface limpa e profissional com foco em clareza e usabilidade. Paleta neutra com azul primário de alta confiança, tipografia legível e espaçamento generoso. Destaque em hierarquia visual clara e feedback explícito ao usuário.

## Colors

**Primário (`#1A73E8`)** — ações principais, links, estados ativos. Nunca usar em backgrounds grandes.

**Neutros** — base de superfícies e textos. `surface` (#F8F9FA) para containers secundários; `text` (#202124) para corpo de texto.

**Feedback** — usar apenas para estados de sistema (sucesso, erro, alerta). Não decorativo.

**Acento** — use com parcimônia para destacar elementos secundários importantes.

Contraste mínimo de 4.5:1 para texto normal (WCAG AA). Texto grande: 3:1.

## Typography

Fonte única **Inter** para consistência. JetBrains Mono exclusivamente para código.

- `heading` — hierarquia de títulos (h1–h4), sempre negrito
- `body` — leitura corrida, 16px base
- `label` — labels de formulário, badges, metadados
- `code` — inline code e blocos de código

Nunca misturar mais de duas famílias tipográficas na mesma tela.

## Layout

Grade de 12 colunas em desktop, 4 colunas em mobile. Escala de espaçamento baseada em múltiplos de **8px**.

- Gap interno de componentes: `sm` (8px) a `md` (16px)
- Separação entre seções: `xl` (32px) a `2xl` (48px)
- Margens laterais em mobile: `md` (16px)
- Container máximo: 1280px, centralizado

## Elevation & Depth

Usar sombras com moderação — profundidade deve ser funcional, não decorativa.

- **Nível 0** — sem sombra (cards em surface)
- **Nível 1** — `0 1px 3px rgba(0,0,0,0.12)` (dropdowns, tooltips)
- **Nível 2** — `0 4px 12px rgba(0,0,0,0.15)` (modais, popovers)

## Shapes

Arredondamento progressivo conforme o tamanho do componente:

- Inputs e botões: `md` (8px) — estrutural, não suave demais
- Cards e painéis: `lg` (12px) — contenção amigável
- Badges e chips: `full` (9999px) — elementos de status
- Nunca misturar raios muito diferentes na mesma tela

## Components

**Botão primário** — fundo `primary.default`, texto branco, `radius.md`. Hover escurece para `primary.hover`.

**Botão secundário** — borda `primary.default`, texto `primary.default`, fundo transparente. Hover preenche com `primary.subtle`.

**Card** — fundo branco, borda `neutral.border`, padding `lg`. Sem sombra por padrão.

**Input** — borda `neutral.border`, focus troca para borda dupla `primary.default` para acessibilidade clara.

## Do's and Don'ts

**Fazer:**
- Usar `spacing` tokens para todos os espaçamentos — nunca valores arbitrários
- Preferir `surface` como fundo de containers secundários, não cinzas customizados
- Manter hierarquia tipográfica consistente (heading → body → label)
- Testar contraste antes de finalizar qualquer combinação cor/texto

**Não fazer:**
- Não usar `primary` como cor de fundo em áreas grandes
- Não criar novas variações de componentes sem antes verificar se alguma existente atende
- Não misturar mais de 3 pesos tipográficos na mesma tela
- Não usar sombras em elementos planos ou de status

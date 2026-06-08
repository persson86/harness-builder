# Acessibilidade — WCAG 2.1 AA

Critérios essenciais que todo componente e tela deve atender. Nível mínimo exigido: **AA**.

---

## 1. Contraste de cores

| Tipo de texto | Proporção mínima |
|---|---|
| Texto normal (< 18pt / < 14pt bold) | **4.5:1** |
| Texto grande (≥ 18pt / ≥ 14pt bold) | **3:1** |
| Componentes UI e gráficos | **3:1** |

**Critério WCAG:** 1.4.3, 1.4.11

> Nunca transmita informação apenas por cor. Sempre combine cor com ícone, texto ou padrão.

---

## 2. Formulários

- Todo campo deve ter `<label>` visível associado
- Mensagens de erro devem ser descritivas ("E-mail inválido" — não "Erro no campo")
- Campos obrigatórios sinalizados visualmente E em texto (não só com asterisco)
- Sugestões de preenchimento fora do placeholder (que some ao digitar)

**Critério WCAG:** 1.3.1, 3.3.1, 3.3.2

---

## 3. Navegação por teclado

- Todo elemento interativo acessível via `Tab`
- Ordem de foco segue a ordem visual lógica
- Foco nunca fica preso em um elemento (exceto modais — veja abaixo)
- Indicador de foco visível com contraste de pelo menos 3:1

**Em modais e dialogs:**
- Foco capturado dentro do modal enquanto aberto
- `Esc` fecha o modal
- Ao fechar, foco retorna ao elemento que abriu o modal

**Critério WCAG:** 2.1.1, 2.4.3, 2.4.7

---

## 4. Textos alternativos

- Imagens informativas: `alt` descrevendo o conteúdo ("Gráfico de barras mostrando crescimento de 40% em Janeiro")
- Imagens decorativas: `alt=""` (string vazia)
- Ícones interativos sem texto visível: `aria-label` descrevendo a ação ("Fechar modal")
- Ícones ao lado de texto: decorativos — `aria-hidden="true"`

**Critério WCAG:** 1.1.1

---

## 5. Tamanho mínimo de alvo

- Área clicável mínima: **44 × 44px** (mesmo que o elemento visual seja menor)
- Espaçamento entre alvos: pelo menos **8px** para evitar toques acidentais no mobile

**Critério WCAG:** 2.5.5

---

## 6. Feedback de estado

- Mudanças de estado que não alteram o foco devem usar `aria-live` (ex: contador de caracteres, mensagens de sucesso inline)
- Ações assíncronas devem indicar estado de carregamento (spinner com `aria-label="Carregando"`)
- Erros de validação devem ser anunciados por leitores de tela

**Critério WCAG:** 4.1.3

---

## 7. Escala de texto

- A interface não deve quebrar com zoom de até 200%
- Não usar `px` fixo para `font-size` no CSS — prefira `rem`

**Critério WCAG:** 1.4.4

---

## Ferramentas recomendadas

| Ferramenta | Para | Quando usar |
|---|---|---|
| axe DevTools | Auditoria automática no browser | QA visual |
| NVDA / VoiceOver | Teste com leitor de tela | QA visual |
| Keyboard testing manual | Verificar navegação por teclado | QA visual |

---

## Referências

- [WCAG 2.1 completo](https://www.w3.org/TR/WCAG21/)
- Critérios cobertos: 1.1.1, 1.3.1, 1.4.3, 1.4.4, 1.4.11, 2.1.1, 2.4.3, 2.4.7, 2.5.5, 3.3.1, 3.3.2, 4.1.3

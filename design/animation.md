# Diretrizes de Animação

Princípios e especificações de motion para interfaces nos produtos de Ops. Os valores dos tokens estão em `design/DESIGN.md` → seção `animation`.

---

## Princípios

**1. Propositada**
Toda animação deve ter um propósito funcional: orientar o olhar, comunicar estado, confirmar ação ou criar continuidade entre telas. Animações puramente decorativas são evitadas.

**2. Discreta**
A animação nunca deve competir com o conteúdo. O usuário não deve perceber a animação — deve perceber o resultado.

**3. Responsiva**
Animações devem respeitar `prefers-reduced-motion`. Quando o usuário sinaliza preferência por menos movimento, use transições de opacidade ou desative animações não essenciais.

**4. Consistente**
Use os tokens de `animation` do `DESIGN.md`. Nunca crie durações ou easings ad-hoc.

---

## Tokens de referência

| Token | Valor | Uso |
|---|---|---|
| `animation.duration.instant` | 100ms | Hover, foco, feedback de clique |
| `animation.duration.fast` | 200ms | Transições de estado de componente |
| `animation.duration.normal` | 300ms | Padrão para a maioria das animações |
| `animation.duration.slow` | 500ms | Entradas de tela, modais, drawers |
| `animation.easing.default` | ease-in-out | Uso geral |
| `animation.easing.decelerate` | ease-out | Elementos entrando na tela |
| `animation.easing.accelerate` | ease-in | Elementos saindo da tela |

---

## Padrões por tipo

### Entrada de elemento na tela

```css
opacity: 0 → 1;
transform: translateY(8px) → translateY(0);
duration: slow (500ms);
easing: decelerate;
```

Usar para: modais, drawers, toasts, painéis laterais, conteúdo carregado assincronamente.

### Saída de elemento da tela

```css
opacity: 1 → 0;
transform: translateY(0) → translateY(4px);
duration: fast (200ms);
easing: accelerate;
```

> Saídas são mais rápidas que entradas — o usuário já sabe o que vai sumir.

### Hover de botão / elemento interativo

```css
background-color: [color] → [color-hover];
duration: instant (100ms);
easing: default;
```

### Loading skeleton

```css
background: linear-gradient(90deg, neutral.surface, neutral.border, neutral.surface);
background-size: 200%;
animation: shimmer 1.5s infinite;
easing: linear;
```

### Feedback de ação (sucesso/erro)

```css
opacity: 0 → 1;
transform: scale(0.8) → scale(1);
duration: fast (200ms);
easing: decelerate;
```

### Transição entre telas

```css
/* Saída da tela atual */
opacity: 1 → 0;
transform: translateX(0) → translateX(-16px);
duration: fast (200ms);

/* Entrada da nova tela */
opacity: 0 → 1;
transform: translateX(16px) → translateX(0);
duration: normal (300ms);
```

---

## Acessibilidade

```css
@media (prefers-reduced-motion: reduce) {
  * {
    animation-duration: 0.01ms !important;
    transition-duration: 0.01ms !important;
  }
}
```

---

## O que evitar

- ❌ Bounce e spring em elementos funcionais (reservar para momentos de celebração, com parcimônia)
- ❌ Durações acima de 600ms para qualquer interação corriqueira
- ❌ Animações em loop sem pausa ou interação do usuário
- ❌ Paralax pesado em páginas com muito conteúdo
- ❌ Easing linear para elementos com peso visual (parece mecânico)

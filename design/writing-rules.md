# Regras de Escrita

Decisões técnicas de escrita — consulte este arquivo ao criar ou revisar textos de interface.

---

## Verbos e ações

- Use verbos no infinitivo em botões e CTAs: "Salvar", "Enviar", "Cancelar"
- CTAs primários descrevem o resultado, não a ação mecânica
  > ✅ "Criar conta" — ❌ "Submeter formulário"
- Seja específico: evite verbos genéricos sem contexto
  > ✅ "Excluir projeto" — ❌ "Excluir"

---

## Pontuação

- Use ponto final em mensagens completas (erros, confirmações, instruções)
- Não use ponto final em títulos, labels, botões e placeholders
- Evite exclamação — reservado para momentos de celebração genuína, com moderação
- Reticências só em loading states: "Carregando…", "Salvando…"

---

## Capitalização

- Títulos de seção e funcionalidades: apenas a primeira letra maiúscula
  > ✅ "Configurações de conta" — ❌ "Configurações De Conta"
- Botões: apenas a primeira letra maiúscula
  > ✅ "Criar projeto" — ❌ "Criar Projeto"
- Siglas que não podem ser lidas como uma palavra: sempre em maiúsculas
  > ✅ CPF, CNPJ, CEP, URL, API
- Acrônimos curtos (até 3 letras): sempre em maiúsculas
  > ✅ ONU, MEC
- Acrônimos longos (4+ letras): apenas a primeira letra maiúscula
  > ✅ Susep, Detran, Unesco

---

## Números

- Números de 1 a 9: escrever por extenso em textos corridos
  > "Você tem três notificações"
- Números 10 em diante: usar algarismos
  > "Você tem 14 notificações"
- Em interfaces de dados e métricas: sempre algarismos, independentemente do valor
- Porcentagens: sempre algarismo + símbolo sem espaço
  > ✅ "10%" — ❌ "10 %"

---

## Estrangeirismos

- Evitar termos em inglês quando existe equivalente claro em português
  > ✅ "Tentar novamente" — ❌ "Retry"
  > ✅ "Carregar mais" — ❌ "Load more"
- Termos sem equivalente consolidado podem ser mantidos em inglês, mas de forma consistente
- Nunca expor erros técnicos em inglês para o usuário: "timeout", "null pointer", "not found"

---

## Acessibilidade na escrita

- Prefira construções neutras sempre que possível
  > ✅ "Pessoa responsável" — ❌ "O responsável" (quando gênero não é relevante)
- Evite generalizações que assumam perfil do usuário

**Clareza para leitores de tela:**
- Não use apenas elementos visuais para transmitir informação — acompanhe com texto
  > ✅ "Erro: e-mail inválido" — ❌ Apenas um ícone vermelho
- Links e botões devem fazer sentido fora de contexto
  > ✅ "Acessar detalhes do pedido" — ❌ "Clique aqui"
- Textos alternativos descrevem a função, não a aparência
  > ✅ "Ícone de aviso: ação irreversível" — ❌ "Triângulo amarelo"

**Linguagem simples:**
- Prefira frases curtas e diretas — uma ideia por frase
- Evite dupla negativa
  > ✅ "Só usuários com permissão podem editar" — ❌ "Não é possível editar sem permissão de acesso"
- Use a voz ativa sempre que possível
  > ✅ "O sistema salvou suas alterações" — ❌ "Suas alterações foram salvas pelo sistema"

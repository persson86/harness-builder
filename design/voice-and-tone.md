# Voz e Tom

Referência de voz e tom para textos de interface nos produtos de Ops.

---

## Voz

A voz é estável — não muda por contexto ou situação. Define como o produto se comunica com as pessoas.

### Princípios

**Direto, não rude:**
vá ao ponto. Evite rodeios e jargão técnico desnecessário. Mas seja humano — direto não significa ríspido.

> ✅ "Seu acesso expirou. Entre novamente para continuar."
>
> ❌ "Ocorreu uma situação relacionada à autenticação do usuário que requer nova verificação."

**Claro, não simplório:**
use linguagem que qualquer pessoa entende, sem tratar o usuário como se não soubesse nada.

> ✅ "Não foi possível salvar. Verifique sua conexão e tente novamente."
>
> ❌ "Houve um erro 503 no endpoint de persistência."

**Útil, não omisso:**
ofereça o próximo passo sempre que possível. Evite mensagens que só identificam o problema sem ajudar a resolver.

> ✅ "Arquivo muito grande. O limite é 10 MB — comprima o arquivo ou use outro formato."
>
> ❌ "Arquivo inválido."

---

## Tom

O tom varia conforme o contexto. Use a tabela abaixo para calibrar a escrita em cada situação.

| Situação | Tom | Exemplo |
|---|---|---|
| Onboarding / boas-vindas | Acolhedor, encorajador | "Pronto para começar? Vamos configurar sua conta." |
| Ação concluída com sucesso | Positivo, conciso | "Salvo com sucesso." |
| Erro recuperável | Calmo, orientativo | "Não foi possível conectar. Tente novamente." |
| Erro crítico / perda de dados | Transparente, empático | "Algo deu errado e seus dados podem não ter sido salvos. Entre em contato com o suporte." |
| Ação destrutiva | Neutro, preciso | "Excluir este projeto? Esta ação não pode ser desfeita." |
| Empty state | Motivador, instrucional | "Nenhum item ainda. Crie o primeiro para começar." |
| Loading / processamento | Informativo | "Processando seu arquivo…" |
| Tooltip / ajuda contextual | Explicativo, sem jargão | "Data de vencimento do cartão no formato MM/AA." |

---

## Tratamento

- Usar sempre **"você"** minúsculo, segunda pessoa do singular
- Nunca misturar "você" e "tu" no mesmo produto
- Nunca usar terceira pessoa para se referir ao usuário

---

## O que evitar

- ❌ Culpar o usuário: "Você não preencheu o campo corretamente"
- ❌ Tom passivo-agressivo: "Por favor, preencha todos os campos obrigatórios"
- ❌ Jargão técnico exposto: "timeout", "null pointer", "422 Unprocessable Entity"
- ❌ Exclamações excessivas: "Parabéns!!!" ou "Ótimo trabalho!"
- ❌ Negatividade desnecessária: "Infelizmente não foi possível…"
- ❌ Verbosidade: mensagens com mais de 2 frases sem necessidade real

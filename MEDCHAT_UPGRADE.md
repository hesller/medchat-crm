# MedChat CRM: subir a nova versão na VPS

## De onde para onde

| | Versão |
| :-- | :-- |
| Rodando hoje (Super Admin) | `4.17.0-fazer-ai.109` (imagem `ghcr.io/fazer-ai/chatwoot:latest`) |
| Base deste fork | `4.18.0-fazer-ai.128` (upstream `fazer-ai/chatwoot`) + mudanças MedChat |

São 19 releases do upstream no intervalo (.110 a .128). Notas lidas inteiras; o que importa para a nossa instalação:

| Release | Mudança | Impacto em nós |
| :-- | :-- | :-- |
| .124 | O conector de WhatsApp nativo passa a rodar dentro do Sidekiq por padrão; quem roda conector separado deve definir `WHATSAPP_CONNECTOR_EMBEDDED=false` antes de atualizar. WhatsApp (nativo) liberado para todas as contas. Baileys e Z-API marcados como "legado". | **Nenhum.** Não rodamos conector separado (o compose tem `baileys-api`, que é outro serviço), e a única inbox é do tipo API (`Channel::Api`, ligada ao WAHA). |
| .126 | Segurança: todo webhook de WhatsApp (Baileys, nativo, Uazapi, Z-API, Cloud) é autenticado antes de virar mensagem. Z-API migra sozinha ~10 min depois. Cloud manual pede App Secret. Cria um índice parcial para o relatório "Handled". | **Nenhum para a inbox API/WAHA.** O índice é criado no primeiro boot (banco pequeno: segundos). |
| .113 / .117 / .119 | Correções no entrypoint: o schema/migrations passam a ser conferidos pela própria imagem (`docker/entrypoints`). | Já cobertos pelo `post_start` do compose (`rails db:chatwoot_prepare`). |
| .116 a .127 | Automações (nova ação "remover atributo personalizado"), relatórios ("Handled"), Central de ajuda (ordenação de artigos), correções de contatos duplicados com 9º dígito, proxy por inbox nativa. | Só melhorias. |

Nenhuma release exige variável de ambiente nova nem ação manual para a nossa instalação.

## O que é diferente na imagem MedChat

- Construída pelo workflow `.github/workflows/publish_medchat_docker.yml`, **sem** a pasta `enterprise/` (igual ao build FOSS do upstream).
- Versões de três números (`MAJOR.MINOR.PATCH`: 4.0.1, 4.0.2, 4.1.0...), independentes da versão do Chatwoot. A imagem é `ghcr.io/hesller/medchat-crm:<versão>`, sem `latest`: nada muda na VPS até alguém trocar a tag. A base do upstream fica no label `io.hexcode.upstream` da imagem e na release do GitHub.
- O aviso de "atualização disponível" compara com as releases **deste** repositório (variável `VERSION_CHECK_REPO`, padrão `hesller/medchat-crm`), e não com as do fazer.ai.
- Branding por conta (`branded_dashboard`): comportamento atual preservado para toda conta que não ligar a flag.

## Passo a passo (nenhum já executado)

1. **Backup do banco** do Chatwoot antes de tudo (`pg_dump` do `chatwoot_production`), porque são 19 releases de migrations.
2. Tag: `git tag v4.0.1 && git push origin v4.0.1` (o workflow também publica a release no GitHub), ou Actions → "Publish MedChat CRM image" → Run workflow informando `4.0.1`. Demora (build do Vite + gems).
3. Conferir o pacote em `ghcr.io/hesller/medchat-crm` (visibilidade pública, igual ao repositório) e que a tag existe.
4. No Coolify, serviço `chatwoot`, trocar nos serviços `rails` e `sidekiq`:
   `image: 'ghcr.io/fazer-ai/chatwoot:latest'` → `image: 'ghcr.io/hesller/medchat-crm:medchat-v1'`
   (mantém `pull_policy: always`; não mexer em `baileys-api`, `waha`, `postgres`, `redis`). Reimplantar.
5. Conferir: login, Super Admin mostra `4.0.1`, mensagem de teste pelo WAHA entra e sai, o `branding:update` do `post_start` continua rodando.
6. Para ligar a marca de uma clínica: Super Admin → Accounts → conta → feature "Branded Dashboard", e preencher nome/cor/logo em Configurações → Geral.

## Histórico

As tags `medchat-v1` a `medchat-v3` (imagens `ghcr.io/hesller/medchat-crm:medchat-v1..v3`) são do esquema antigo e continuam no registro; a `medchat-v3` está em produção até a primeira versão `4.x.y`. A partir de `4.0.1` vale a numeração de três números.

## Reverter

Voltar a imagem de `rails` e `sidekiq` para `ghcr.io/fazer-ai/chatwoot:latest` e reimplantar. Atenção: as migrations já aplicadas ficam no banco; reverter a imagem de um salto de versões grande pode exigir restaurar o backup do passo 1.

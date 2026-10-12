# MedChat CRM: branding por clínica

Fork de `fazer-ai/chatwoot` (v4.18.0-fazer-ai.127/128), usado como CRM das clínicas.
Levantamento de onde a marca (nome, logo, cor) é definida hoje e o que precisa mudar
para cada clínica (cada uma é uma *account* do Chatwoot) ter a sua.

## Implementado: `branded_dashboard` (branch `medchat/branded-dashboard`)

Camada própria, só no código MIT (nada em `enterprise/`), com fallback total para o comportamento anterior:

- Feature flag de conta `branded_dashboard` (desligada por padrão), no fim da coluna `feature_flags_ext_1`, então os bits das flags existentes não mudam.
- `Brand#dashboard_config` (`lib/brand.rb`) devolve só o que a conta sobrescreve: nome (`INSTALLATION_NAME`/`BRAND_NAME`), cor (`BRAND_COLOR`, só hex válido) e logo (a imagem de e-mail da conta vira `LOGO`, `LOGO_DARK` e `LOGO_THUMBNAIL`).
- `DashboardController` mescla isso por cima da configuração global quando a URL é `/app/accounts/:id/...` e a conta ligou a flag. O id vem do caminho, porque a rota `/app/*params` não tem `:account_id`.
- `ManifestController` aceita `?account_id=` (o layout já aponta o `<link rel="manifest">` para ele quando há marca da conta), então o PWA instalado leva o nome e o ícone da clínica.
- Os campos são os mesmos de Configurações → Geral → Email branding; não há tela nova.
- Ainda global: tela de login (sem conta antes do login; precisa de domínio/subdomínio por conta), favicon estático e widget do site.

## O que já é por conta (não precisa mudar código)

O fork já tem `lib/brand.rb` (`Brand.for(account:)`) e a feature flag `branded_email_templates`.
Com a flag ligada na conta, em **Configurações → Geral → Email branding** a clínica define:

| Campo | Onde aparece |
| :-- | :-- |
| `brand_name`, `brand_url`, `brand_color` (guardados em `accounts.settings`) | e-mails da conta, página pública de pesquisa CSAT |
| logo de e-mail (upload, PNG/JPG/GIF até 2 MB) | topo do e-mail, rodapé/topo da página CSAT |

Para ligar a flag numa conta: console Rails ou Super Admin → Accounts → feature `branded_email_templates`.
`disable_branding` na conta remove o "Powered by" do widget, portal e CSAT.

## O que hoje é global da instalação (precisa de código)

Tudo abaixo lê `GlobalConfig` (variáveis de ambiente / Super Admin): `INSTALLATION_NAME`, `LOGO`,
`LOGO_DARK`, `LOGO_THUMBNAIL`, `BRAND_NAME`, `BRAND_COLOR`, `BRAND_URL`, `WIDGET_BRAND_URL`.

| Superfície | Arquivo | Observação |
| :-- | :-- | :-- |
| Título da aba, `theme-color`, ícones, `window.globalConfig` do dashboard | `app/controllers/dashboard_controller.rb` (`GLOBAL_CONFIG_KEYS`, `set_global_config`), `app/views/layouts/vueapp.html.erb` | Rota `/app/accounts/:id/...` já traz a conta; dá para resolver `Brand` pela conta da URL e mesclar em `@global_config` (nome, cores, logo, logo escuro, thumbnail) |
| Logo e nome dentro do app (menu lateral, seletor de conta, banners, textos que trocam "Chatwoot" pelo nome) | `app/javascript/shared/store/globalConfig.js`, `shared/composables/useBranding.js`, `dashboard/components-next/icon/Logo.vue`, `components-next/sidebar/SidebarAccountSwitcher.vue`, `SidebarProfileMenu.vue`, `components/app/StatusBanner.vue`, `UpdateBanner.vue` | Todos leem o store `globalConfig`; se o controller já entregar os valores da conta, o front quase não muda |
| Manifest do PWA (nome do app instalado, ícone, cor) | `app/controllers/manifest_controller.rb` (`/manifest.json`) | Hoje sem conta no request. Opção: `manifest.json?account_id=` ou por host |
| Favicon estático | `public/favicon-*.png`, `deployment/extract_brand_assets.sh` | Arquivos fixos. Por clínica só com rota dinâmica (`/favicon/:account_id`) ou usar o `LOGO_THUMBNAIL` da conta |
| Tela de login / recuperação de senha | `app/javascript/v3/...`, `app/views/layouts/vueapp.html.erb` | **Sem conta antes do login.** Precisa mapear por host: subdomínio ou domínio próprio por clínica (ex.: `acme.crm.dominio.com`). O fork já faz algo parecido para portais: `render_hc_if_custom_domain` com `Portal.custom_domain` |
| Widget de chat do site | `app/controllers/widgets_controller.rb` (`set_global_config`), `api/v1/widget/configs_controller.rb`, `app/views/widgets/show.html.erb` | O widget é identificado por `website_token` → inbox → conta, então dá para usar `Brand.for(account: inbox.account).web_config` (já usado em `survey/responses_controller.rb`) |
| Portal / central de ajuda | `public/api/v1/portals/base_controller.rb`, `_footer.html.erb` | Idem: conta conhecida pelo portal |
| E-mails | `lib/brand.rb`, `app/views/layouts/mailer/base.liquid` | Já por conta |

## Pontos de decisão

1. **Como identificar a clínica antes do login.** Recomendo uma coluna `custom_domain` (ou `subdomain`) em `accounts`, resolvida em `DashboardController` e `ManifestController`. Sem isso o login fica sempre com a marca da instalação.
2. **Onde guardar logos do dashboard.** O e-mail já usa upload (ActiveStorage, `email_logo`). Replicar o mesmo para `logo`, `logo_dark` e `logo_thumbnail` (ou reaproveitar um único logo).
3. **Sobre `Brand`.** Estender `lib/brand.rb` com `dashboard_config` (chaves `LOGO`, `LOGO_DARK`, `LOGO_THUMBNAIL`, `INSTALLATION_NAME`, `BRAND_COLOR`) e usá-lo em `DashboardController`, `ManifestController` e `WidgetsController`. É a mudança central; o resto são ajustes pequenos.
4. **Telas de configuração.** Ampliar `settings/account/components/EmailBranding.vue` (ou criar `Branding.vue`) com nome da instalação, logos e cores, mais `AccountSettingsSchema` / `accounts_controller.rb` para aceitar os campos.

## Implantação

A VPS (Coolify, serviço `chatwoot`) roda `ghcr.io/fazer-ai/chatwoot:latest` (rails + sidekiq), junto de WAHA e baileys-api.
Para rodar este fork é preciso publicar uma imagem própria (GitHub Actions → `ghcr.io/hesller/medchat-crm`)
e trocar a imagem de `rails` e `sidekiq` no compose do Coolify. As migrations rodam no boot.

## Sincronizar com o upstream

`git fetch upstream && git merge upstream/main` (remote `upstream` = `fazer-ai/chatwoot`).
Manter as mudanças de marca concentradas em `lib/brand.rb`, nos controllers acima e em arquivos novos
reduz conflitos nos merges.

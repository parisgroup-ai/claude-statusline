# 1.0.0 (2026-04-17)


### Bug Fixes

* **actions:** raise heap for package build step ([#2](https://github.com/parisgroup-ai/infra/issues/2)) ([8ef580f](https://github.com/parisgroup-ai/infra/commit/8ef580fd32cdf73812abea662daa46968bf1f607))
* **actions:** skip cache setup when lockfile is absent ([#1](https://github.com/parisgroup-ai/infra/issues/1)) ([c910b75](https://github.com/parisgroup-ai/infra/commit/c910b75f0fc6e435ae446d99654adef1c1b90ec3))
* CI injection + pin all GitHub Actions to SHAs (H1-H8) ([611bd87](https://github.com/parisgroup-ai/infra/commit/611bd875587af0f1998cd6e005dadb1d3f80f618))
* **ci:** bootstrap reusable workflow helpers ([db4d12f](https://github.com/parisgroup-ai/infra/commit/db4d12f35f5987dcab4229d9e4357266d000e802))
* **ci:** pin GitHub Actions to SHAs for supply chain security ([4b58416](https://github.com/parisgroup-ai/infra/commit/4b584168a79f228d5e7a3be117427c17560164c2))
* **ci:** quote-trailing-scalar YAML parse error in release-npm.yml ([ae924ec](https://github.com/parisgroup-ai/infra/commit/ae924ec03bc02a68eaa0375b09df5340055903d0))
* **claude-statusline:** portable md5/stat/tac fallbacks for Linux CI ([11e798a](https://github.com/parisgroup-ai/infra/commit/11e798a64e0083c567d9d68aa5938664b8c69a5a))
* **claude-statusline:** suppress SC2015 on best-effort cache writes ([63cf953](https://github.com/parisgroup-ai/infra/commit/63cf953989f9424fd6735e1233509d6881c1330d))
* **claude-statusline:** warm git-cache reread no longer concatenates timestamp into branch (CHORE-008) ([0fcd491](https://github.com/parisgroup-ai/infra/commit/0fcd491b8f15074b9eb5acfcd51546de83bdd2b5))
* harden CI workflows and resolve audit findings ([f8b83c1](https://github.com/parisgroup-ai/infra/commit/f8b83c1089a7748d93a85f33f5163b8c0eef058d))


### Features

* add bootstrap-project script for scaffolding new projects ([3fcfa73](https://github.com/parisgroup-ai/infra/commit/3fcfa73bf4218a8c2f638c11b02be11299016acf))
* add ci-node reusable workflow with lint, typecheck, test, build, e2e ([735b7b5](https://github.com/parisgroup-ai/infra/commit/735b7b5018daa051ad6398e80e718c57a774e040))
* add ci-package reusable workflow for npm packages ([44afce3](https://github.com/parisgroup-ai/infra/commit/44afce301def772096c56e470febd3a2b00493ca))
* add deploy-railway reusable workflow with maturity gates ([944c660](https://github.com/parisgroup-ai/infra/commit/944c660aa30425a1d671053fe879190bbef1c43c))
* add deploy-vercel reusable workflow with maturity gates ([1014693](https://github.com/parisgroup-ai/infra/commit/1014693e8c88dcdc9c25442aa7c8eb4af82a4047))
* add platform templates export helper ([e86c570](https://github.com/parisgroup-ai/infra/commit/e86c57051012ca2bb59e9f590eb15234083adbff))
* add release-npm reusable workflow with semantic-release ([983c22e](https://github.com/parisgroup-ai/infra/commit/983c22e752d09771d935370913c067c5f7699816))
* add secret templates for all services and projects ([67ad607](https://github.com/parisgroup-ai/infra/commit/67ad6073d03d3326dd33a993ffe0426595a7d85a))
* add secrets audit script with per-project and CI mode ([8b5dbb0](https://github.com/parisgroup-ai/infra/commit/8b5dbb070d289299cf5f8525d4b38cfc46b59a55))
* add setup-node composite action with caching and GitHub Packages auth ([770c76b](https://github.com/parisgroup-ai/infra/commit/770c76bee6714f2081d3679e32baa756afbcf0c8))
* **ci:** add extra-body-text input to notify-ci-red (TASK-034) ([73e79de](https://github.com/parisgroup-ai/infra/commit/73e79dee85b98f39b0e2c3022df842dd1a45e753))
* **ci:** add reusable notify-ci-red workflow (TASK-031) ([5d2ad81](https://github.com/parisgroup-ai/infra/commit/5d2ad81fb7bccf2ef80cf427bb1b4636eacf15c5))
* **ci:** add workflow timing summaries ([5f29b60](https://github.com/parisgroup-ai/infra/commit/5f29b607a7aa2e8b3a15e4b0e38d3033db5294c9))
* **claude-statusline:** add CC_STATUSLINE_NO_ICONS env var (FEAT-004) ([6a6fddd](https://github.com/parisgroup-ai/infra/commit/6a6fddd135704d9388ab3c0f77795ebb4a1b4353))
* **claude-statusline:** add CC_STATUSLINE_SEGMENTS env var (FEAT-005) ([9a31609](https://github.com/parisgroup-ai/infra/commit/9a31609e66ad1053b79d1b99443668606a9cd619))
* **claude-statusline:** port statusline script from ~/.claude (FEAT-003) ([10d586e](https://github.com/parisgroup-ai/infra/commit/10d586e4f592ef7fd00d7cc8c0c0a5a1193e55e6))
* **infra-core:** add circuit breaker ([3a127d7](https://github.com/parisgroup-ai/infra/commit/3a127d7b488cd2cac660516b1c1d052d2838e603))
* **infra-core:** add input sanitization ([2da0cf8](https://github.com/parisgroup-ai/infra/commit/2da0cf8b75446bd58846fd79248dbd64c4bc137a))
* **infra-core:** add rate limiter with Redis adapter pattern ([bcff825](https://github.com/parisgroup-ai/infra/commit/bcff8257fcc757a664e24800bd5a39dba63cfbe1))
* **infra-core:** add retry with exponential backoff ([07a9bcc](https://github.com/parisgroup-ai/infra/commit/07a9bcc3b70abcf4fdaba301de198e132a06dde4))
* **infra-core:** add Sentry config factory ([d0f724f](https://github.com/parisgroup-ai/infra/commit/d0f724f240a87f3fd9cabe56b030ab2c84c933c4))
* **infra-core:** add structured logger with PII sanitization ([8170043](https://github.com/parisgroup-ai/infra/commit/8170043cad2c91edd1fc9b25885761536ff47361))
* **infra-core:** scaffold package structure with tsup, vitest, GitHub Packages ([7c88238](https://github.com/parisgroup-ai/infra/commit/7c88238c64ec438c1a306b67d1c6a0330ad24e08))
* **infra-core:** wire root exports, verify build ([a9c825a](https://github.com/parisgroup-ai/infra/commit/a9c825a645c9e2f603fd047935db6c9af52660b6))

# terraform-plan-verdict — demo

A sample repository that uses
[**terraform-plan-verdict**](https://github.com/nandotorres/terraform-plan-verdict) in CI, with a tiny
Terraform project that runs **entirely in CI with no cloud credentials** (it only uses the `random`,
`local`, and `terraform_data` providers).

Two ways to see it work:

## 1. Interactive — open a pull request

[`infra/`](infra/) is a mock "service" (10 instances). The
[Plan Verdict workflow](.github/workflows/plan-verdict.yml) runs on any PR that touches `infra/`: it applies
the base branch offline, plans your change, and the action posts a **verdict comment + labels** on the PR.

Try these edits in [`infra/terraform.tfvars`](infra/terraform.tfvars) in a PR (each lands a different
verdict):

| Edit | What it does | Verdict |
| --- | --- | --- |
| `replicas = 12` | adds two instances | 🟢 LOW |
| `image_tag = "v2"` | in-place update of all instances | 🟡 MEDIUM |
| `config_version = "2"` | forces **replacement** of all instances | 🟠 HIGH |
| `config_version = "2"` + `ingress_cidr = "0.0.0.0/0"` | opens to the world **and** replaces | 🔴 CRITICAL |

## 2. Instant — the simulations

[`simulations/`](simulations/) holds four pre-generated `terraform show -json` plans, one per verdict.
The [Simulations workflow](.github/workflows/simulations.yml) scores each and writes the verdict to the job
summary — so you can see the full spectrum in one run, no Terraform required.

| Simulation | Verdict | Score |
| --- | --- | --- |
| `low` | 🟢 LOW | 17 |
| `medium` | 🟡 MEDIUM | 32 |
| `high` | 🟠 HIGH | 70 |
| `critical` | 🔴 CRITICAL | 88 |

## Recipes

### Input formats

```yaml
# terraform show -json (single JSON object)
- run: terraform show -json tfplan > plan.json
- uses: nandotorres/terraform-plan-verdict@v0
  with: { plan-json: plan.json }

# terraform plan -json (NDJSON stream) — no `show` step needed
- run: terraform plan -json > plan.ndjson
- uses: nandotorres/terraform-plan-verdict@v0
  with: { plan-json: plan.ndjson }
```

(The [`stream` job](.github/workflows/simulations.yml) scores a committed NDJSON file to prove this works.)

### AI providers (optional — require a key)

```yaml
# OpenAI
- uses: nandotorres/terraform-plan-verdict@v0
  with:
    plan-json: plan.json
    provider: openai
    model: gpt-4o-mini
    api-key: ${{ secrets.OPENAI_API_KEY }}

# Anthropic (Claude)
- uses: nandotorres/terraform-plan-verdict@v0
  with:
    plan-json: plan.json
    provider: openai
    base-url: https://api.anthropic.com/v1
    model: claude-sonnet-4-5
    api-key: ${{ secrets.ANTHROPIC_API_KEY }}

# Google Gemini
- uses: nandotorres/terraform-plan-verdict@v0
  with:
    plan-json: plan.json
    provider: openai
    base-url: https://generativelanguage.googleapis.com/v1beta/openai
    model: gemini-2.0-flash
    api-key: ${{ secrets.GEMINI_API_KEY }}

# Azure OpenAI (needs api-version query + api-key header)
- uses: nandotorres/terraform-plan-verdict@v0
  with:
    plan-json: plan.json
    provider: openai
    base-url: https://my-resource.openai.azure.com/openai/deployments/gpt-4o
    model: gpt-4o
    provider-options: |
      headers:
        api-key: ${{ secrets.AZURE_OPENAI_KEY }}
      query:
        api-version: "2024-08-01-preview"

# Local Ollama (free, no key)
- uses: nandotorres/terraform-plan-verdict@v0
  with:
    plan-json: plan.json
    provider: openai
    base-url: http://localhost:11434/v1
    model: llama3.1
```

### Gate merges and label PRs

```yaml
- uses: nandotorres/terraform-plan-verdict@v0
  with:
    plan-json: plan.json
    comment: true
    labels: true
    fail-on: critical   # fail the job on a CRITICAL verdict
```

## Notes

- The workflows pin the action at `@v0` (the floating major tag). Pin a patch like `@v0.1.0` for stricter reproducibility.
- The default provider is `rules` — free, deterministic, offline. The AI recipes above are optional.

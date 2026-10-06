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

## Notes

- The workflows reference the action at `@main` so this demo works immediately. Pin to a released tag
  (e.g. `@v1`) for real use.
- The default provider is `rules` — free, deterministic, offline. Swap to `provider: systemone` or
  `provider: openai` (with an `api-key`) to try AI-graded verdicts.

# CostLingo FinOps NLP 🚀

> Turn messy cloud-cost notes, budget alerts, invoice comments, and optimization tickets into structured FinOps signals with one Bash script and Google Cloud Natural Language API.

![Shell](https://img.shields.io/badge/Shell-Bash-4EAA25?logo=gnu-bash&logoColor=white)
![Google Cloud](https://img.shields.io/badge/Google%20Cloud-Natural%20Language%20API-4285F4?logo=googlecloud&logoColor=white)
![FinOps](https://img.shields.io/badge/Use%20case-FinOps-purple)
![License](https://img.shields.io/badge/License-MIT-green)

**CostLingo** is a small but practical FinOps lab/helper that uses the **Google Cloud Natural Language API** to analyze unstructured cost-related text.

It helps answer questions like:

- Which cloud services, teams, regions, projects, or vendors are mentioned in this cost incident?
- Does this budget alert sound urgent, negative, neutral, or positive?
- Which entities are associated with negative sentiment?
- What nouns, verbs, and cost drivers dominate this support ticket?
- Can we quickly prototype NLP-powered FinOps workflows without building an app?

---

## Why this exists

FinOps teams often live inside unstructured text:

- Budget alerts
- Billing anomaly notes
- Cloud cost support tickets
- Invoice comments
- Jira stories
- Slack incident summaries
- Optimization recommendations
- Executive cost updates

Dashboards show numbers. Text explains **why the numbers moved**.

CostLingo gives you a quick way to extract meaning from that text using Google Cloud Natural Language API.

---

## What it can do

| Mode | API method | FinOps use case |
|---|---|---|
| `--entities` | `analyzeEntities` | Extract services, teams, projects, regions, vendors, and cost drivers |
| `--sentiment` | `analyzeSentiment` | Understand tone and urgency of cost updates |
| `--entity-sentiment` | `analyzeEntitySentiment` | See which specific entities are viewed positively or negatively |
| `--syntax` | `analyzeSyntax` | Inspect grammar, tokens, verbs, nouns, and sentence structure |
| `--multilingual` | `analyzeEntities` | Analyze non-English FinOps notes |
| `--custom-*` | Multiple | Analyze your own FinOps text without editing the script |

---

## Quick start

### 1. Clone the repo

```bash
git clone https://github.com/YOUR_USERNAME/costlingo-finops-nlp.git
cd costlingo-finops-nlp
```

### 2. Make the script executable

```bash
chmod +x finops_natural_language_api_lab.sh
```

### 3. Set your API key

```bash
export API_KEY=<YOUR_API_KEY>
```

### 4. Run everything

```bash
./finops_natural_language_api_lab.sh --all
```

Results are saved in:

```bash
finops-nl-api-results/
```

---

## Example: analyze a cloud cost alert

```bash
./finops_natural_language_api_lab.sh --entities
```

Example input:

```text
Project analytics-prod in us-central1 triggered a budget alert after BigQuery on-demand query costs increased by 42 percent this week. The Data Platform team should review expensive scheduled queries and consider flat-rate reservations or query optimization.
```

Possible output files:

```text
finops-nl-api-results/finops_entities.json
finops-nl-api-results/finops_entities.tsv
```

The TSV summary makes it easier to review detected entities in spreadsheets, notebooks, or downstream scripts.

---

## Analyze your own FinOps text

You can pass your own cost note, incident summary, or optimization recommendation without changing the script.

### Entity extraction

```bash
export CUSTOM_TEXT="Cloud SQL spend increased 60% after backup retention changed. The database team needs to review snapshots."
./finops_natural_language_api_lab.sh --custom-entities
```

### Sentiment analysis

```bash
export CUSTOM_TEXT="The GKE autoscaling change reduced waste, but the invoice is still above forecast."
./finops_natural_language_api_lab.sh --custom-sentiment
```

### Entity sentiment analysis

```bash
export CUSTOM_TEXT="BigQuery performance is excellent, but storage costs are too high and idle Compute Engine instances are wasting money."
./finops_natural_language_api_lab.sh --custom-entity-sentiment
```

---

## Run modes

```bash
./finops_natural_language_api_lab.sh --all
./finops_natural_language_api_lab.sh --setup
./finops_natural_language_api_lab.sh --entities
./finops_natural_language_api_lab.sh --sentiment
./finops_natural_language_api_lab.sh --entity-sentiment
./finops_natural_language_api_lab.sh --syntax
./finops_natural_language_api_lab.sh --multilingual
./finops_natural_language_api_lab.sh --custom-entities
./finops_natural_language_api_lab.sh --custom-sentiment
./finops_natural_language_api_lab.sh --custom-entity-sentiment
./finops_natural_language_api_lab.sh --non-interactive
./finops_natural_language_api_lab.sh --help
```

For automation or CI-style demos:

```bash
INTERACTIVE=false ./finops_natural_language_api_lab.sh --all
```

or:

```bash
./finops_natural_language_api_lab.sh --all --non-interactive
```

---

## Customize the built-in examples

Override any sample text with environment variables.

```bash
export COST_ALERT_TEXT="GKE cluster spend in project retail-prod increased because autoscaling created extra nodes."
export SENTIMENT_TEXT="The budget overrun is worrying, but the savings plan is promising."
export ENTITY_SENTIMENT_TEXT="Cloud CDN improved performance, but egress costs disappointed the platform team."
export SYNTAX_TEXT="The FinOps analyst reviewed idle resources and recommended rightsizing oversized VMs."
export MULTILINGUAL_TEXT="Projekt analytics-prod przekroczył budżet przez wzrost kosztów BigQuery."

./finops_natural_language_api_lab.sh --all
```

Change the output folder:

```bash
export OUTPUT_DIR="my-finops-results"
./finops_natural_language_api_lab.sh --all
```

---

## Requirements

Required:

- Bash
- `curl`
- `python3`
- Google Cloud API key with access to Cloud Natural Language API

Recommended:

- `jq` for readable JSON and generated TSV/text summaries

Install `jq` on Debian/Ubuntu:

```bash
sudo apt-get update
sudo apt-get install -y jq
```

---

## API key setup

Create a Google Cloud API key:

1. Open Google Cloud Console.
2. Go to **APIs & Services > Credentials**.
3. Click **Create credentials > API key**.
4. Restrict the key to **Cloud Natural Language API** when possible.
5. Export it in your terminal:

```bash
export API_KEY=<YOUR_API_KEY>
```

Security tips:

- Do not commit API keys.
- Do not paste keys into tickets, chat, or shared docs.
- Use restricted keys for demos and labs.
- Rotate or delete temporary keys after testing.

---

## Suggested repo structure

```text
costlingo-finops-nlp/
├── finops_natural_language_api_lab.sh
├── README.md
├── LICENSE
├── .gitignore
└── examples/
    ├── cost-alert.txt
    ├── invoice-note.txt
    └── optimization-ticket.txt
```

Recommended `.gitignore`:

```gitignore
finops-nl-api-results/
request.json
*.log
.env
```

---

## FinOps ideas to build next

This script is intentionally simple, but it can become the foundation for larger workflows:

- Detect cost-risk sentiment in Jira tickets
- Extract services and teams from budget incidents
- Summarize negative cost drivers from support notes
- Compare sentiment before and after optimization work
- Create weekly FinOps text intelligence reports
- Send high-risk cost notes to Slack
- Store extracted entities in BigQuery for trend analysis
- Combine NLP results with billing export data

---

## Example workflows

### Cost anomaly triage

1. Paste anomaly explanation into `CUSTOM_TEXT`.
2. Run `--custom-entity-sentiment`.
3. Review entities with negative sentiment.
4. Route the issue to the responsible team.

```bash
export CUSTOM_TEXT="Dataflow costs increased sharply after the fraud pipeline started processing duplicate events. The payments team is concerned about the forecast."
./finops_natural_language_api_lab.sh --custom-entity-sentiment
```

### Invoice comment analysis

```bash
export CUSTOM_TEXT="The Marketplace invoice includes unexpected third-party monitoring charges for the observability platform. Finance needs owner confirmation."
./finops_natural_language_api_lab.sh --custom-entities
```

### Optimization recommendation review

```bash
export CUSTOM_TEXT="Rightsizing recommendations for Compute Engine look promising, but the production team is worried about performance risk."
./finops_natural_language_api_lab.sh --custom-entity-sentiment
```

---

## Output files

Depending on the mode, CostLingo creates raw JSON and optional summaries.

```text
finops-nl-api-results/
├── finops_entities.json
├── finops_entities.tsv
├── finops_sentiment.json
├── finops_sentiment_summary.txt
├── finops_entity_sentiment.json
├── finops_entity_sentiment.tsv
├── finops_syntax.json
└── finops_multilingual_entities.json
```

Raw JSON is useful for developers. TSV/text summaries are useful for analysts and FinOps practitioners.

---

## Who this is for

- FinOps practitioners
- Cloud cost analysts
- Platform teams
- Cloud engineers
- Billing operations teams
- SREs handling cloud cost incidents
- Anyone learning Google Cloud Natural Language API through a practical FinOps lens

---

## Project name ideas

The recommended repo name is:

```text
costlingo-finops-nlp
```

Other catchy alternatives:

- `cost-whisperer`
- `finops-text-radar`
- `cloud-cost-nlp-lab`
- `budget-sentiment-cli`
- `spend-signal`

---

## Contributing

Contributions are welcome.

Good first issues:

- Add more FinOps sample texts
- Add BigQuery export examples
- Add CSV output
- Add GitHub Actions smoke test
- Add support for reading text from a file
- Add Markdown report generation
- Add Slack/Jira integration examples

---

## Disclaimer

This project is a learning and prototyping helper. Natural language results can be imperfect, and sentiment scores should not be treated as financial truth. Use the output as a triage signal, not as an automated decision system.

---

## Star the repo ⭐

If this helps you explain cloud cost stories faster, give the project a star and share it with a FinOps teammate.

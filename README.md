# CostLingo FinOps NLP 🚀

> Turn messy cloud-cost notes, budget alerts, invoice comments, and optimization tickets into structured FinOps signals with one Bash script and Google Cloud Natural Language API.

![Shell](https://img.shields.io/badge/Shell-Bash-4EAA25?logo=gnu-bash&logoColor=white)
![Google Cloud](https://img.shields.io/badge/Google%20Cloud-Natural%20Language%20API-4285F4?logo=googlecloud&logoColor=white)
![FinOps](https://img.shields.io/badge/Use%20case-FinOps-purple)
![License](https://img.shields.io/badge/License-MIT-green)

> A hands-on developer + FinOps lesson showing how to turn messy cloud-cost notes into structured signals using Google Cloud Natural Language API.

CostLingo FinOps NLP is a small Bash-based learning project built from the Google Cloud Natural Language API lab and adapted for a practical FinOps use case.

Instead of analyzing generic textbook sentences, this project analyzes realistic cloud-cost language:

- budget alerts
- cost anomaly notes
- rightsizing recommendations
- idle resource warnings
- commitment discount suggestions
- multilingual FinOps updates

The goal is not to automate financial decisions. The goal is to teach developers and FinOps practitioners how Natural Language Processing can help convert unstructured cost conversations into useful review signals.

---

## What this project does

The script `EntityAndSentimentAnalysis.sh` calls several Google Cloud Natural Language API endpoints with FinOps-style text examples.

It creates a `request.json` file, sends it to the API with `curl`, saves the raw JSON responses, and, when `jq` is available, creates easier-to-read summary files.

The generated output is saved in:

```bash
finops-nl-api-results/
```

---

## Why this matters for FinOps

FinOps teams often deal with unstructured text:

```text
BigQuery costs increased 42% this week.
The Data Platform team should review scheduled queries.
Idle Compute Engine instances are wasting money.
The committed use discount recommendation looks helpful.
```

That text may live in tickets, Slack threads, incident reports, budget alerts, pull requests, or email updates.

Natural Language API can help extract:

| Signal | FinOps value |
|---|---|
| Entities | Services, projects, teams, regions, cost drivers |
| Sentiment | Whether a note sounds risky, neutral, or optimistic |
| Entity sentiment | Which specific service or cost driver is causing concern |
| Syntax tokens | Action verbs and cost-related nouns for workflow routing |
| Language detection | Support for multilingual cost governance notes |

---

## Quick start

```bash
chmod +x EntityAndSentimentAnalysis.sh
export API_KEY=<YOUR_API_KEY>
./EntityAndSentimentAnalysis.sh --all
```

You can also run individual sections:

```bash
./EntityAndSentimentAnalysis.sh --entities
./EntityAndSentimentAnalysis.sh --sentiment
./EntityAndSentimentAnalysis.sh --entity-sentiment
./EntityAndSentimentAnalysis.sh --syntax
./EntityAndSentimentAnalysis.sh --multilingual
```

Analyze your own FinOps text:

```bash
export CUSTOM_TEXT="Cloud SQL spend increased 60% after backup retention changed. The database team needs to review snapshots."
./EntityAndSentimentAnalysis.sh --custom-entity-sentiment
```

---

## What really happens in the script

### 1. The script checks for an API key

The script expects a Google Cloud API key in the `API_KEY` environment variable.

```bash
export API_KEY=<YOUR_API_KEY>
```

If `API_KEY` is missing, the script prompts you to paste it.

This key is then used in API URLs like:

```bash
https://language.googleapis.com/v1/documents:analyzeEntities?key=${API_KEY}
```

Security lesson:

- Do not commit API keys.
- Do not paste real keys into GitHub issues, README files, screenshots, or terminal logs.
- Restrict keys to the Cloud Natural Language API when possible.
- Rotate or delete temporary lab keys after testing.

---

### 2. The script creates `request.json`

For each API call, the script writes a new request body to `request.json`.

Example:

```json
{
  "document": {
    "type": "PLAIN_TEXT",
    "content": "Project analytics-prod in us-central1 triggered a budget alert after BigQuery on-demand query costs increased by 42 percent this week. The Data Platform team should review expensive scheduled queries and consider flat-rate reservations or query optimization."
  },
  "encodingType": "UTF8"
}
```

Developer lesson:

The API receives a plain text document. The script changes the `content` field depending on the use case being tested.

---

### 3. The script sends the request with `curl`

Example entity extraction call:

```bash
curl "https://language.googleapis.com/v1/documents:analyzeEntities?key=${API_KEY}" \
  -s -X POST \
  -H "Content-Type: application/json" \
  --data-binary @request.json \
  > finops-nl-api-results/finops_entities.json
```

Developer lesson:

This is a minimal API integration pattern:

1. create JSON request
2. POST request to API endpoint
3. save JSON response
4. parse or summarize response

---

### 4. The script saves raw JSON responses

The raw API responses are saved so developers can inspect the full structure.

Example files:

```text
finops_entities.json
finops_sentiment.json
finops_entity_sentiment.json
finops_syntax.json
finops_multilingual_entities.json
```

These raw files are useful for debugging, learning, and building future integrations.

---

### 5. The script creates summary files when `jq` is available

If `jq` is installed, the script creates easier-to-read summaries such as:

```text
finops_entities.tsv
finops_sentiment_summary.txt
finops_entity_sentiment.tsv
finops_syntax_tokens.tsv
finops_multilingual_entities.tsv
```

Developer lesson:

The API response is JSON, but FinOps users often need tables. Converting JSON into TSV makes it easier to review, paste into spreadsheets, or feed into lightweight automation.

---

## What happened in the real output

The successful run produced all main outputs.

```text
finops-nl-api-results/
```

---

## 1. Entity extraction: `analyzeEntities`

### Input text

```text
Project analytics-prod in us-central1 triggered a budget alert after BigQuery on-demand query costs increased by 42 percent this week. The Data Platform team should review expensive scheduled queries and consider flat-rate reservations or query optimization.
```

### API endpoint

```text
documents:analyzeEntities
```

### Output file

```text
finops-nl-api-results/finops_entities.json
finops-nl-api-results/finops_entities.tsv
```

### Important entities detected

| Entity | Type | Why it matters |
|---|---|---|
| Project analytics | OTHER | Project context, although not perfectly extracted |
| budget alert | OTHER | Cost governance event |
| costs | OTHER | Financial signal |
| BigQuery | OTHER | Cloud service / cost driver |
| queries | OTHER | Possible optimization target |
| Data Platform | OTHER | Responsible team |
| reservations | OTHER | Potential commitment / pricing option |
| query optimization | OTHER | Recommended remediation |
| 42 | NUMBER | Spend increase percentage |

### FinOps interpretation

The API successfully identified the most important parts of a cost alert:

- the project context
- the budget event
- the affected service
- the cost increase
- the team involved
- possible optimization paths

### Developer lesson

Entity extraction is useful, but imperfect.

The text contained:

```text
analytics-prod
```

The API returned:

```text
Project analytics
```

A production FinOps tool should not rely only on generic NLP to extract exact cloud resource IDs. For resource IDs, combine NLP with regex, tags, billing export data, or cloud asset inventory.

Good production pattern:

```text
NLP entities + regex extraction + billing labels + asset metadata
```

---

## 2. Document sentiment: `analyzeSentiment`

### Input text

```text
The finance team is concerned because Compute Engine spend exceeded the monthly forecast, but the new rightsizing plan should reduce waste and improve budget confidence.
```

### API endpoint

```text
documents:analyzeSentiment
```

### Output file

```text
finops-nl-api-results/finops_sentiment.json
finops-nl-api-results/finops_sentiment_summary.txt
```

### Output

```json
{
  "documentSentiment": {
    "magnitude": 0.2,
    "score": -0.2
  },
  "language": "en"
}
```

### FinOps interpretation

| Field | Value | Meaning |
|---|---:|---|
| score | -0.2 | Slightly negative / mildly concerned |
| magnitude | 0.2 | Low emotional intensity |

This makes sense because the sentence contains both negative and positive signals.

Negative:

```text
concerned
spend exceeded the monthly forecast
```

Positive:

```text
rightsizing plan
reduce waste
improve budget confidence
```

### Developer lesson

Document-level sentiment is useful for triage, but it compresses the whole message into one score.

For FinOps, that can be too broad. A single cost note may include both a problem and a solution.

Use document sentiment for quick routing, not final decisions.

Possible uses:

- prioritize cost tickets with negative tone
- identify anxious stakeholder updates
- detect escalation language
- compare tone across many cost incident summaries

Do not use it to approve or deny budgets automatically.

---

## 3. Entity-level sentiment: `analyzeEntitySentiment`

### Input text

```text
BigQuery performance is excellent, but storage costs are too high and idle Compute Engine instances are wasting money. The committed use discount recommendation looks helpful.
```

### API endpoint

```text
documents:analyzeEntitySentiment
```

### Output file

```text
finops-nl-api-results/finops_entity_sentiment.json
finops-nl-api-results/finops_entity_sentiment.tsv
```

### Important output

| Entity | Sentiment score | Interpretation |
|---|---:|---|
| performance | -0.4 | Negative signal in the API output |
| BigQuery | -0.3 | Slight concern associated with BigQuery |
| storage costs | -0.2 | Cost pain point |
| Engine instances | -0.4 | Negative cost/resource signal |
| money | -0.4 | Negative financial signal |
| use discount recommendation | 0.5 | Positive remediation signal |

### FinOps interpretation

This is the most useful endpoint for FinOps-style text.

The text contains both problems and a solution.

Problems:

```text
storage costs are too high
idle Compute Engine instances are wasting money
```

Possible solution:

```text
committed use discount recommendation looks helpful
```

Entity-level sentiment separates these better than document-level sentiment.

### Developer lesson

Entity sentiment can help answer:

- Which service is causing concern?
- Which cost driver has negative tone?
- Which recommendation is seen positively?
- Which part of a mixed message should be routed to a team?

This can support ticket enrichment:

```text
Service: Compute Engine
Cost issue: idle instances
Tone: negative
Suggested action: investigate waste
Positive recommendation: committed use discount
```

The output still needs human review. For example, the API associated negative sentiment with `performance`, even though the sentence says `performance is excellent`. This is a reminder that generic NLP models can misread domain-specific or mixed sentiment.

---

## 4. Syntax analysis: `analyzeSyntax`

### Input text

```text
The FinOps analyst reviewed the billing anomaly, tagged idle resources, and recommended rightsizing oversized virtual machines.
```

### API endpoint

```text
documents:analyzeSyntax
```

### Output file

```text
finops-nl-api-results/finops_syntax.json
finops-nl-api-results/finops_syntax_tokens.tsv
```

### Useful verbs found

| Token | Lemma | Why it matters |
|---|---|---|
| reviewed | review | Investigation action |
| tagged | tag | Governance action |
| recommended | recommend | Advisory action |
| rightsizing | rightsize | Optimization action |

### Useful nouns found

| Token | Lemma | Why it matters |
|---|---|---|
| FinOps | FinOps | Practice/team context |
| analyst | analyst | Actor |
| billing | billing | Cost domain |
| anomaly | anomaly | Incident / detection object |
| resources | resource | Cloud objects |
| machines | machine | Infrastructure object |

### FinOps interpretation

Syntax analysis is useful when you want to identify action language.

For example, a workflow could route tickets based on verbs:

| Verb lemma | Possible workflow |
|---|---|
| review | Send to analyst queue |
| tag | Send to governance/tagging workflow |
| recommend | Attach recommendation summary |
| rightsize | Send to optimization backlog |

### Developer lesson

Syntax is not primarily about cost insight. It is about structure.

It helps developers build lightweight rules from text:

```text
if lemma contains "rightsize" -> optimization workflow
if lemma contains "tag" -> tagging policy workflow
if lemma contains "exceed" -> budget alert workflow
```

---

## 5. Multilingual entity extraction

### Original problem

The first multilingual example used Polish:

```text
Projekt analytics-prod przekroczył budżet...
```

The API returned:

```json
{
  "error": {
    "code": 400,
    "message": "The language pl is not supported for entity analysis.",
    "status": "INVALID_ARGUMENT"
  }
}
```

### What this taught us

Not every Natural Language API feature supports every language.

The script was updated to use Japanese for multilingual entity analysis.

### Working Japanese input

```text
analytics-prod プロジェクトは BigQuery の費用が asia-northeast1 リージョンで増加したため、予算を超過しました。FinOps チームはクエリと未使用リソースを確認する必要があります。
```

### Output file

```text
finops-nl-api-results/finops_multilingual_entities.json
finops-nl-api-results/finops_multilingual_entities.tsv
```

### Important entities detected

| Entity | Why it matters |
|---|---|
| analytics-prod プロジェクト | Project context |
| Query / クエリ | Query workload |
| 費用 | Cost |
| asia-northeast1 | Region |
| 予算 | Budget |
| FinOps チーム | Responsible team |
| 未使用リソース | Unused resources |

### FinOps interpretation

This is useful for global organizations where cloud-cost notes may be written in multiple languages.

The API detected:

```text
language: ja
```

and extracted FinOps-relevant concepts from the Japanese text.

### Developer lesson

A production-grade multilingual FinOps workflow should check language support before calling a specific endpoint.

Recommended logic:

```text
1. Detect language.
2. Check whether the desired API feature supports that language.
3. If supported, call the endpoint.
4. If unsupported, translate first or fallback to another workflow.
5. Log unsupported language cases clearly.
```

---

## Generated files explained

After a full run, you should see files like this:

```text
finops-nl-api-results/
├── finops_entities.json
├── finops_entities.tsv
├── finops_sentiment.json
├── finops_sentiment_summary.txt
├── finops_entity_sentiment.json
├── finops_entity_sentiment.tsv
├── finops_syntax.json
├── finops_syntax_tokens.tsv
├── finops_multilingual_entities.json
└── finops_multilingual_entities.tsv
```

### Raw JSON files

Use these when building integrations.

They preserve the full API response.

### TSV files

Use these for human review, spreadsheets, demos, or simple CLI inspection.

Example:

```bash
column -t -s $'\t' finops-nl-api-results/finops_entities.tsv
```

---

## Suggested repo structure

```text
costlingo-finops-nlp/
├── README.md
├── EntityAndSentimentAnalysis.sh
├── examples/
│   ├── finops_entities.example.json
│   ├── finops_entities.example.tsv
│   ├── finops_sentiment.example.json
│   ├── finops_entity_sentiment.example.json
│   ├── finops_syntax_tokens.example.tsv
│   └── finops_multilingual_entities.example.json
├── .gitignore
└── LICENSE
```

---

## What to commit

Commit:

```text
README.md
EntityAndSentimentAnalysis.sh
examples/*.example.json
examples/*.example.tsv
.gitignore
LICENSE
```

Do not commit:

```text
API keys
.env files
request.json with private text
real company tickets
billing exports
customer names
vendor contracts
terminal logs containing secrets
```

---

## Recommended `.gitignore`

```gitignore
# Secrets
.env
*.env
api_key.txt
credentials.json
service-account*.json

# Runtime files
request.json
result.json
finops-nl-api-results/

# OS/editor noise
.DS_Store
.vscode/
.idea/
```

---

## Install optional tools

The script works with Bash and `curl`.

For better summaries, install `jq`.

Debian / Ubuntu:

```bash
sudo apt-get update
sudo apt-get install -y jq
```

Then review TSV summaries:

```bash
column -t -s $'\t' finops-nl-api-results/finops_entities.tsv
column -t -s $'\t' finops-nl-api-results/finops_entity_sentiment.tsv
column -t -s $'\t' finops-nl-api-results/finops_syntax_tokens.tsv
```

---

## Practical FinOps extensions

This demo can be extended into a real internal tool.

### 1. Ticket enrichment

Input:

```text
Cloud SQL spend increased after backup retention changed.
```

Output:

```text
service: Cloud SQL
issue: backup retention
sentiment: negative
suggested queue: database platform team
```

### 2. Cost anomaly triage

Use entity extraction to find:

```text
service
project
region
team
cost driver
percentage increase
```

Then combine with billing export data.

### 3. Commitment recommendation review

Use entity sentiment to detect whether recommendations are framed positively or negatively.

Example:

```text
committed use discount recommendation looks helpful
```

could become:

```text
recommendation_type: commitment
tone: positive
action: review for purchase planning
```

### 4. Governance routing

Use syntax lemmas:

```text
tag
review
rightsize
delete
resize
commit
forecast
```

to route notes into the right workflow.

### 5. Multilingual cost operations

Use language detection and supported NLP endpoints for international FinOps teams.

---

## Important limitations

This project is a learning tool, not a production FinOps decision engine.

Known limitations:

- Entity extraction may not perfectly capture cloud resource names.
- Sentiment can be wrong on mixed technical sentences.
- API language support differs by endpoint.
- Natural Language API does not understand your billing hierarchy, labels, accounts, or ownership model by itself.
- You should combine NLP output with billing data, tags, asset inventory, and human review.

---

## Best production architecture idea

A stronger FinOps architecture could look like this:

```text
Cost note / ticket / alert
        |
        v
Natural Language API
        |
        +--> entities
        +--> sentiment
        +--> syntax
        |
        v
Post-processing layer
        |
        +--> regex for project IDs and regions
        +--> billing export lookup
        +--> label / owner lookup
        +--> policy rules
        |
        v
FinOps workflow
        |
        +--> route ticket
        +--> enrich alert
        +--> assign owner
        +--> suggest optimization
        +--> prepare human review
```

---

## Example learning questions

Use this project to answer:

1. Which cloud service is mentioned most clearly?
2. Which entity has the highest salience?
3. Does the document sound negative, neutral, or positive?
4. Which specific entity has negative sentiment?
5. Which verbs represent FinOps actions?
6. Did multilingual entity extraction preserve the important cost concepts?
7. Where did generic NLP fail to understand cloud-specific terms?

---

## Project name

Suggested GitHub repo name:

```text
costlingo-finops-nlp
```

Tagline:

```text
Turn cloud cost chatter into FinOps signals with Google Cloud Natural Language API.
```

---

## License

MIT License is recommended for a small educational open-source project.

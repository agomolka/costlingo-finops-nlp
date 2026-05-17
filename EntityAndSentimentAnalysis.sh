#!/usr/bin/env bash

###############################################################################
# FinOps Natural Language API Helper
#
# Purpose:
#   Use Google Cloud Natural Language API to analyze FinOps text such as:
#   - Cloud cost incident notes
#   - Billing alerts
#   - Invoice descriptions
#   - Optimization recommendations
#   - Support tickets about spend, waste, commitments, budgets, and anomalies
#
# What this script does:
#   - Reads your Natural Language API key from API_KEY or prompts for it.
#   - Creates request.json automatically for each analysis.
#   - Calls Natural Language API methods with curl.
#   - Saves raw JSON responses in a results folder.
#   - Creates small FinOps-friendly summary files when jq is installed.
#
# Typical FinOps questions this helps answer:
#   - Which services, teams, projects, regions, or vendors are mentioned?
#   - Is a cost-related message urgent, negative, neutral, or positive?
#   - Which entities are associated with negative sentiment?
#   - What nouns/verbs dominate a ticket or incident note?
#
# Important:
#   This script does not create the API key. In many labs, you must create the
#   key manually in Google Cloud Console so the progress checker can verify it.
###############################################################################

set -euo pipefail

API_BASE_URL="https://language.googleapis.com/v1/documents"
OUTPUT_DIR="${OUTPUT_DIR:-finops-nl-api-results}"
REQUEST_FILE="${REQUEST_FILE:-request.json}"
INTERACTIVE="${INTERACTIVE:-true}"

# -----------------------------------------------------------------------------
# Default FinOps sample texts.
# Override any of these before running, for example:
#   export COST_ALERT_TEXT="BigQuery spend for project analytics-prod rose 35% today."
# -----------------------------------------------------------------------------

COST_ALERT_TEXT="${COST_ALERT_TEXT:-Project analytics-prod in us-central1 triggered a budget alert after BigQuery on-demand query costs increased by 42 percent this week. The Data Platform team should review expensive scheduled queries and consider flat-rate reservations or query optimization.}"

SENTIMENT_TEXT="${SENTIMENT_TEXT:-The finance team is concerned because Compute Engine spend exceeded the monthly forecast, but the new rightsizing plan should reduce waste and improve budget confidence.}"

ENTITY_SENTIMENT_TEXT="${ENTITY_SENTIMENT_TEXT:-BigQuery performance is excellent, but storage costs are too high and idle Compute Engine instances are wasting money. The committed use discount recommendation looks helpful.}"

SYNTAX_TEXT="${SYNTAX_TEXT:-The FinOps analyst reviewed the billing anomaly, tagged idle resources, and recommended rightsizing oversized virtual machines.}"

MULTILINGUAL_TEXT="${MULTILINGUAL_TEXT:-Projekt analytics-prod przekroczył budżet, ponieważ koszty BigQuery wzrosły w regionie europe-west1. Zespół FinOps powinien sprawdzić zapytania i nieużywane zasoby.}"

CUSTOM_TEXT="${CUSTOM_TEXT:-}"

print_header() {
  printf '\n===============================================================================\n'
  printf '%s\n' "$1"
  printf '===============================================================================\n'
}

print_step() {
  printf '\n--- %s ---\n' "$1"
}

info() {
  printf 'INFO: %s\n' "$1"
}

warn() {
  printf 'WARNING: %s\n' "$1"
}

error_exit() {
  printf 'ERROR: %s\n' "$1" >&2
  exit 1
}

pause_if_interactive() {
  if [[ "${INTERACTIVE}" == "true" ]]; then
    printf '\n'
    read -r -p "Press ENTER to continue... " _
  fi
}

progress_pause() {
  if [[ "${INTERACTIVE}" == "true" ]]; then
    printf '\nIf this is part of a lab, click Check my progress when appropriate.\n'
    read -r -p "Press ENTER to continue... " _
  fi
}

require_command() {
  command -v "$1" >/dev/null 2>&1 || error_exit "Required command '$1' is missing."
}

show_usage() {
  cat <<'USAGE'
Usage:
  ./finops_natural_language_api_lab.sh [option]

Modes:
  --all                    Run every FinOps Natural Language API example. Default.
  --setup                  Show setup instructions and check API key only.
  --entities               Extract FinOps entities from a cost alert.
  --sentiment              Analyze sentiment of a FinOps update.
  --entity-sentiment       Find sentiment for each FinOps entity.
  --syntax                 Analyze grammar/tokens in a FinOps note.
  --multilingual           Analyze FinOps entities in non-English text.
  --custom-entities        Analyze entities from CUSTOM_TEXT.
  --custom-sentiment       Analyze sentiment from CUSTOM_TEXT.
  --custom-entity-sentiment Analyze entity sentiment from CUSTOM_TEXT.
  --non-interactive        Do not pause between steps.
  --help                   Show this help.

Basic run:
  chmod +x finops_natural_language_api_lab.sh
  export API_KEY=<YOUR_API_KEY>
  ./finops_natural_language_api_lab.sh --all

Run a specific FinOps analysis:
  ./finops_natural_language_api_lab.sh --entities
  ./finops_natural_language_api_lab.sh --entity-sentiment

Analyze your own FinOps note without editing the script:
  export CUSTOM_TEXT="Cloud SQL spend increased 60% after backup retention changed. The database team needs to review snapshots."
  ./finops_natural_language_api_lab.sh --custom-entity-sentiment

Override built-in examples:
  export COST_ALERT_TEXT="GKE cluster spend in project retail-prod increased because autoscaling created extra nodes."
  export SENTIMENT_TEXT="The budget overrun is worrying, but the savings plan is promising."
  ./finops_natural_language_api_lab.sh --all

Change output folder:
  export OUTPUT_DIR="my-finops-results"
  ./finops_natural_language_api_lab.sh --all

Run without pauses:
  ./finops_natural_language_api_lab.sh --all --non-interactive
  INTERACTIVE=false ./finops_natural_language_api_lab.sh --all
USAGE
}

json_escape() {
  python3 -c 'import json, sys; print(json.dumps(sys.stdin.read().rstrip("\n"), ensure_ascii=False))'
}

write_request() {
  local text="$1"
  local include_encoding="${2:-true}"
  local escaped_text
  escaped_text="$(printf '%s' "$text" | json_escape)"

  if [[ "${include_encoding}" == "true" ]]; then
    cat > "${REQUEST_FILE}" <<JSON
{
  "document": {
    "type": "PLAIN_TEXT",
    "content": ${escaped_text}
  },
  "encodingType": "UTF8"
}
JSON
  else
    cat > "${REQUEST_FILE}" <<JSON
{
  "document": {
    "type": "PLAIN_TEXT",
    "content": ${escaped_text}
  }
}
JSON
  fi
}

call_api() {
  local method="$1"
  local output_file="$2"

  curl "${API_BASE_URL}:${method}?key=${API_KEY}" \
    -sS -X POST \
    -H "Content-Type: application/json" \
    --data-binary "@${REQUEST_FILE}" \
    -o "${output_file}"

  if grep -q '"error"' "${output_file}"; then
    printf '\nThe API returned an error. Response saved in %s:\n' "${output_file}"
    cat "${output_file}"
    error_exit "Common causes: invalid API key, API not enabled/restricted correctly, quota issue, or malformed JSON."
  fi
}

show_json() {
  local file="$1"
  if command -v jq >/dev/null 2>&1; then
    jq . "$file"
  else
    cat "$file"
  fi
}

write_finops_entity_summary() {
  local input_file="$1"
  local output_file="$2"

  if command -v jq >/dev/null 2>&1; then
    jq -r '
      ["name","type","salience","wikipedia_url"],
      (.entities[]? | [.name, .type, (.salience|tostring), (.metadata.wikipedia_url // "")])
      | @tsv
    ' "$input_file" > "$output_file"
    info "FinOps entity summary saved to: ${output_file}"
  else
    warn "Install jq to generate TSV summaries. Raw JSON was still saved."
  fi
}

write_finops_sentiment_summary() {
  local input_file="$1"
  local output_file="$2"

  if command -v jq >/dev/null 2>&1; then
    {
      echo "FinOps sentiment summary"
      echo "========================"
      echo
      jq -r '"Document score: \(.documentSentiment.score)\nDocument magnitude: \(.documentSentiment.magnitude)\nLanguage: \(.language)"' "$input_file"
      echo
      echo "Sentence-level sentiment:"
      jq -r '.sentences[]? | "- score=\(.sentiment.score), magnitude=\(.sentiment.magnitude): \(.text.content)"' "$input_file"
      echo
      echo "Interpretation guide:"
      echo "- Negative score can indicate concern, complaints, risk, or urgency."
      echo "- Positive score can indicate confidence, improvement, or satisfaction."
      echo "- Magnitude shows emotional strength, not direction."
    } > "$output_file"
    info "FinOps sentiment summary saved to: ${output_file}"
  else
    warn "Install jq to generate text summaries. Raw JSON was still saved."
  fi
}

write_finops_entity_sentiment_summary() {
  local input_file="$1"
  local output_file="$2"

  if command -v jq >/dev/null 2>&1; then
    jq -r '
      ["entity","type","salience","sentiment_score","sentiment_magnitude"],
      (.entities[]? | [.name, .type, (.salience|tostring), ((.sentiment.score // "")|tostring), ((.sentiment.magnitude // "")|tostring)])
      | @tsv
    ' "$input_file" > "$output_file"
    info "FinOps entity sentiment summary saved to: ${output_file}"
  else
    warn "Install jq to generate TSV summaries. Raw JSON was still saved."
  fi
}

check_api_key() {
  print_header "API key setup"

  cat <<'INSTRUCTIONS'
Before API calls can work, create or use a Google Cloud API key:

1. Open Google Cloud Console.
2. Go to APIs & Services > Credentials.
3. Click Create credentials > API key.
4. If restrictions are required, allow Cloud Natural Language API.
5. Copy the generated key.
6. In this terminal, run:

   export API_KEY=<YOUR_API_KEY>

Security note for FinOps teams:
- Do not paste API keys into shared docs, tickets, Slack, or source control.
- Prefer a restricted key for labs and temporary testing.
- Rotate or delete temporary keys after the exercise.
INSTRUCTIONS

  if [[ -z "${API_KEY:-}" ]]; then
    if [[ "${INTERACTIVE}" == "true" ]]; then
      printf '\n'
      read -r -s -p "Paste your API key now, then press ENTER: " API_KEY
      printf '\n'
      export API_KEY
    else
      error_exit "API_KEY is not set. Run: export API_KEY=<YOUR_API_KEY>"
    fi
  fi

  [[ -n "${API_KEY:-}" ]] || error_exit "API_KEY is empty."
  info "API_KEY is set for this terminal session."
}

prepare_environment() {
  require_command curl
  require_command python3
  mkdir -p "${OUTPUT_DIR}"
  info "Responses and FinOps summaries will be saved in: ${OUTPUT_DIR}/"
  if ! command -v jq >/dev/null 2>&1; then
    warn "jq is not installed. The script will show raw JSON, but TSV/text summaries will be skipped."
  fi
}

run_entities() {
  print_header "FinOps entity extraction: analyzeEntities"
  cat <<'EXPLANATION'
Use this for:
- Billing alerts
- Cost anomaly notes
- Budget incident summaries
- Optimization recommendations

FinOps value:
- Extracts services, projects, teams, regions, vendors, products, and cost drivers.
- Helps turn unstructured cost notes into structured signals for review.
EXPLANATION

  print_step "Create ${REQUEST_FILE} from COST_ALERT_TEXT"
  write_request "${COST_ALERT_TEXT}" true
  cat "${REQUEST_FILE}"

  print_step "Call Natural Language API: analyzeEntities"
  local output="${OUTPUT_DIR}/finops_entities.json"
  call_api "analyzeEntities" "${output}"

  print_step "Raw API response saved to ${output}"
  show_json "${output}"

  write_finops_entity_summary "${output}" "${OUTPUT_DIR}/finops_entities.tsv"

  cat <<'LOOK_FOR'

FinOps review checklist:
- Which cloud services were detected? Example: BigQuery, Compute Engine, Cloud SQL, GKE.
- Which business or engineering teams were detected?
- Which projects, regions, products, vendors, or cost drivers were detected?
- Which entities have the highest salience and therefore seem most central?
LOOK_FOR
  progress_pause
}

run_sentiment() {
  print_header "FinOps document sentiment: analyzeSentiment"
  cat <<'EXPLANATION'
Use this for:
- Cost incident updates
- Executive summaries
- Stakeholder feedback
- Budget-risk notes

FinOps value:
- Detects whether a cost message sounds concerning, neutral, or optimistic.
- Useful for triaging spend-related tickets and stakeholder comments.
EXPLANATION

  print_step "Create ${REQUEST_FILE} from SENTIMENT_TEXT"
  write_request "${SENTIMENT_TEXT}" true
  cat "${REQUEST_FILE}"

  print_step "Call Natural Language API: analyzeSentiment"
  local output="${OUTPUT_DIR}/finops_sentiment.json"
  call_api "analyzeSentiment" "${output}"

  print_step "Raw API response saved to ${output}"
  show_json "${output}"

  write_finops_sentiment_summary "${output}" "${OUTPUT_DIR}/finops_sentiment_summary.txt"

  cat <<'LOOK_FOR'

FinOps interpretation:
- score near -1.0: negative tone, possible concern, escalation, frustration, or risk.
- score near 0.0: neutral or mixed tone.
- score near 1.0: positive tone, confidence, improvement, or satisfaction.
- magnitude: strength of sentiment, regardless of positive or negative direction.
LOOK_FOR
  progress_pause
}

run_entity_sentiment() {
  print_header "FinOps entity-level sentiment: analyzeEntitySentiment"
  cat <<'EXPLANATION'
Use this for:
- Mixed feedback about different services or cost drivers
- Reviews of optimization plans
- Cost incident notes mentioning several resources

FinOps value:
- Shows which specific service, project, team, or cost driver is associated with negative or positive sentiment.
- Better than document-level sentiment when one note contains both problems and solutions.
EXPLANATION

  print_step "Create ${REQUEST_FILE} from ENTITY_SENTIMENT_TEXT"
  write_request "${ENTITY_SENTIMENT_TEXT}" true
  cat "${REQUEST_FILE}"

  print_step "Call Natural Language API: analyzeEntitySentiment"
  local output="${OUTPUT_DIR}/finops_entity_sentiment.json"
  call_api "analyzeEntitySentiment" "${output}"

  print_step "Raw API response saved to ${output}"
  show_json "${output}"

  write_finops_entity_sentiment_summary "${output}" "${OUTPUT_DIR}/finops_entity_sentiment.tsv"

  cat <<'LOOK_FOR'

FinOps review checklist:
- Which entity has the most negative score?
- Is the negative entity a service, resource type, process, or team?
- Which entity has positive sentiment and may represent a good remediation path?
- Use this output as a signal, not as the only decision source.
LOOK_FOR
  progress_pause
}

run_syntax() {
  print_header "FinOps syntax analysis: analyzeSyntax"
  cat <<'EXPLANATION'
Use this for:
- Understanding recurring verbs and nouns in FinOps tickets
- Building lightweight keyword logic for cost operations workflows
- Exploring how Natural Language API tokenizes FinOps notes

FinOps value:
- Helps identify action words such as reviewed, tagged, recommended, reduced, increased, exceeded.
- Helps identify nouns such as anomaly, resources, budget, invoice, commitment, discount.
EXPLANATION

  print_step "Create ${REQUEST_FILE} from SYNTAX_TEXT"
  write_request "${SYNTAX_TEXT}" true
  cat "${REQUEST_FILE}"

  print_step "Call Natural Language API: analyzeSyntax"
  local output="${OUTPUT_DIR}/finops_syntax.json"
  call_api "analyzeSyntax" "${output}"

  print_step "Raw API response saved to ${output}"
  show_json "${output}"

  if command -v jq >/dev/null 2>&1; then
    jq -r '["token","part_of_speech","lemma","dependency_label"], (.tokens[]? | [.text.content, .partOfSpeech.tag, .lemma, .dependencyEdge.label]) | @tsv' "${output}" > "${OUTPUT_DIR}/finops_syntax_tokens.tsv"
    info "FinOps syntax token summary saved to: ${OUTPUT_DIR}/finops_syntax_tokens.tsv"
  fi

  cat <<'LOOK_FOR'

FinOps review checklist:
- Which nouns represent cost objects?
- Which verbs represent actions or changes?
- Which lemmas could become search or routing keywords?
LOOK_FOR
  progress_pause
}

run_multilingual() {
  print_header "Multilingual FinOps entity extraction: analyzeEntities"
  cat <<'EXPLANATION'
Use this for:
- FinOps notes from international teams
- Non-English budget alerts or support tickets
- Global cloud cost governance workflows

FinOps value:
- Demonstrates language auto-detection.
- Extracts entities from non-English FinOps notes.
EXPLANATION

  print_step "Create ${REQUEST_FILE} from MULTILINGUAL_TEXT"
  write_request "${MULTILINGUAL_TEXT}" false
  cat "${REQUEST_FILE}"

  print_step "Call Natural Language API: analyzeEntities"
  local output="${OUTPUT_DIR}/finops_multilingual_entities.json"
  call_api "analyzeEntities" "${output}"

  print_step "Raw API response saved to ${output}"
  show_json "${output}"

  write_finops_entity_summary "${output}" "${OUTPUT_DIR}/finops_multilingual_entities.tsv"

  cat <<'LOOK_FOR'

FinOps review checklist:
- What language did the API detect?
- Which services, projects, regions, or teams were extracted?
- Did important FinOps concepts survive translation/language differences?
LOOK_FOR
  progress_pause
}

require_custom_text() {
  if [[ -z "${CUSTOM_TEXT}" ]]; then
    error_exit "CUSTOM_TEXT is empty. Example: export CUSTOM_TEXT='Cloud SQL spend increased after backup retention changed.'"
  fi
}

run_custom_entities() {
  require_custom_text
  local original="${COST_ALERT_TEXT}"
  COST_ALERT_TEXT="${CUSTOM_TEXT}"
  run_entities
  COST_ALERT_TEXT="${original}"
}

run_custom_sentiment() {
  require_custom_text
  local original="${SENTIMENT_TEXT}"
  SENTIMENT_TEXT="${CUSTOM_TEXT}"
  run_sentiment
  SENTIMENT_TEXT="${original}"
}

run_custom_entity_sentiment() {
  require_custom_text
  local original="${ENTITY_SENTIMENT_TEXT}"
  ENTITY_SENTIMENT_TEXT="${CUSTOM_TEXT}"
  run_entity_sentiment
  ENTITY_SENTIMENT_TEXT="${original}"
}

final_summary() {
  print_header "Finished: FinOps Natural Language API analysis"
  cat <<SUMMARY
Created/updated request file:
- ${REQUEST_FILE}

Raw JSON responses and optional summaries are in:
- ${OUTPUT_DIR}/

Useful review commands:
  ls -lh ${OUTPUT_DIR}/
  cat ${OUTPUT_DIR}/finops_entities.json
  cat ${OUTPUT_DIR}/finops_sentiment.json
  cat ${OUTPUT_DIR}/finops_entity_sentiment.json

If jq is installed, also review:
  column -t -s $'\t' ${OUTPUT_DIR}/finops_entities.tsv
  cat ${OUTPUT_DIR}/finops_sentiment_summary.txt
  column -t -s $'\t' ${OUTPUT_DIR}/finops_entity_sentiment.tsv
  column -t -s $'\t' ${OUTPUT_DIR}/finops_syntax_tokens.tsv

Suggested FinOps next steps:
1. Use entity extraction to tag cost tickets with service, project, region, team, or vendor.
2. Use entity sentiment to identify which cost drivers are causing concern.
3. Combine this Natural Language API output with billing export data before making financial decisions.
4. Treat sentiment as a triage signal, not as an automated approval or chargeback decision.

Analyze your own FinOps text:
  export CUSTOM_TEXT="Cloud SQL spend increased 60% after backup retention changed. The database team needs to review snapshots."
  ./finops_natural_language_api_lab.sh --custom-entity-sentiment
SUMMARY
}

MODE="all"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --all) MODE="all" ;;
    --setup) MODE="setup" ;;
    --entities) MODE="entities" ;;
    --sentiment) MODE="sentiment" ;;
    --entity-sentiment) MODE="entity_sentiment" ;;
    --syntax) MODE="syntax" ;;
    --multilingual) MODE="multilingual" ;;
    --custom-entities) MODE="custom_entities" ;;
    --custom-sentiment) MODE="custom_sentiment" ;;
    --custom-entity-sentiment) MODE="custom_entity_sentiment" ;;
    --non-interactive) INTERACTIVE="false" ;;
    --help|-h) show_usage; exit 0 ;;
    *) show_usage; error_exit "Unknown option: $1" ;;
  esac
  shift
done

print_header "FinOps Natural Language API Helper"
prepare_environment
check_api_key

case "${MODE}" in
  setup)
    info "Setup check completed."
    ;;
  entities)
    run_entities
    ;;
  sentiment)
    run_sentiment
    ;;
  entity_sentiment)
    run_entity_sentiment
    ;;
  syntax)
    run_syntax
    ;;
  multilingual)
    run_multilingual
    ;;
  custom_entities)
    run_custom_entities
    ;;
  custom_sentiment)
    run_custom_sentiment
    ;;
  custom_entity_sentiment)
    run_custom_entity_sentiment
    ;;
  all)
    run_entities
    run_sentiment
    run_entity_sentiment
    run_syntax
    run_multilingual
    final_summary
    ;;
  *)
    error_exit "Invalid mode: ${MODE}"
    ;;
esac

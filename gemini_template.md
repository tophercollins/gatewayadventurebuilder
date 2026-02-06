# Gemini LLM Classifier Reference Guide

> A standalone reference for replicating the Argus project's Vertex AI / Gemini classification pipeline in new projects.
> All code snippets are taken directly from the Argus source with file-path annotations.

---

## Table of Contents

1. [Overview & Architecture](#1-overview--architecture)
2. [GCP / Vertex AI Session Setup](#2-gcp--vertex-ai-session-setup)
3. [Configuration System](#3-configuration-system)
4. [Prompt Engineering for Structured Output](#4-prompt-engineering-for-structured-output)
5. [Classifier Architecture](#5-classifier-architecture)
6. [Batch Processing & Parallelization](#6-batch-processing--parallelization)
7. [Error Handling & Resilience](#7-error-handling--resilience)
8. [BigQuery Integration](#8-bigquery-integration)
9. [Adapting This Template for a New Classification Task](#9-adapting-this-template-for-a-new-classification-task)

---

## 1. Overview & Architecture

### Data Flow

```
BigQuery (input)
    │
    ▼
┌──────────────────────────────────┐
│  main.py                         │
│  ─ Loads SQL, fetches DataFrame  │
│  ─ Splits into batches of 10    │
│  ─ asyncio.gather() dispatches   │
│    batches in parallel            │
└──────────┬───────────────────────┘
           │
           ▼
┌──────────────────────────────────┐
│  config.py                       │
│  ─ Reads <client>.json config    │
│  ─ Loads prompt .txt files       │
│  ─ get_classifier() factory      │
│    returns the right subclass     │
└──────────┬───────────────────────┘
           │
           ▼
┌──────────────────────────────────┐
│  Classifier (base + subclass)    │
│  ─ classify_bulk(texts)          │
│  ─ Sends prompt + '||'-joined    │
│    texts to Gemini               │
│  ─ Parses JSON response          │
│  ─ Falls back to individual      │
│    calls if bulk parse fails      │
└──────────┬───────────────────────┘
           │
           ▼
┌──────────────────────────────────┐
│  Vertex AI (Gemini)              │
│  ─ GenerativeModel.generate_     │
│    content(prompt + text)         │
│  ─ Returns JSON string           │
└──────────┬───────────────────────┘
           │
           ▼
┌──────────────────────────────────┐
│  Results                         │
│  ─ Saved to temp CSV per batch   │
│  ─ Bulk-uploaded to BigQuery     │
│    at end (WRITE_APPEND)         │
└──────────────────────────────────┘
```

### Component Summary

| Component | File | Responsibility |
|-----------|------|----------------|
| Global settings | `common/global_settings.py` | GCP project, region, dataset routing |
| Config loader | `vertex_classification/config.py` | Read JSON config, load prompts, factory function |
| Base classifier | `vertex_classification/base_classifier.py` | LLM call, JSON parsing, validation, abstract hooks |
| Passthrough classifier | `vertex_classification/passthrough_classifier.py` | Returns LLM JSON output directly |
| Ski classifier | `vertex_classification/ski_classifier.py` | Domain-specific: locations + offers, post-processing |
| Legacy classifier | `vertex_classification/classifier.py` | Original monolithic implementation (pre-refactor) |
| Orchestrator | `vertex_classification/main.py` | Async batch processing, CSV storage, BQ upload |
| Recovery script | `vertex_classification/upload_csv_to_bq.py` | Manual upload of partial results after failure |

---

## 2. GCP / Vertex AI Session Setup

### Global Settings

```python
# common/global_settings.py

from variables import EnvironmentVariables as Env

TARGET_CLIENT_NAME = 'Travel Report'

GCP_PROJECT_ID = "skillful-mason-290912"
GCP_REGION = "us-central1"

INPUT_DATASET = {
    'development': Env.DBT_SOLUTIONS_DEV_SCHEMA,
    'staging': 'dbt_solutions_staging',
    'production': 'dbt_solutions'
}.get(Env.ENVIRONMENT)

OUTPUT_DATASET = {
    'development': 'argus_development',
    'staging': 'argus_staging',
    'production': 'argus'
}.get(Env.ENVIRONMENT)
```

**Key points:**
- `TARGET_CLIENT_NAME` is the single switch that controls which config / prompts / data are used.
- `GCP_PROJECT_ID` and `GCP_REGION` are passed to `vertexai.init()`.
- Environment-based dataset routing keeps dev/staging/production separate.

### Vertex AI Initialization & Model Creation

```python
# vertex_classification/base_classifier.py:47-49

import vertexai
from vertexai.preview.generative_models import GenerativeModel

vertexai.init(project=settings.GCP_PROJECT_ID, location=settings.GCP_REGION)
self.model = GenerativeModel(self.llm_model)
```

**How it works:**
1. `vertexai.init()` sets the GCP project and region for all subsequent calls.
2. `GenerativeModel(model_name)` creates a reusable model handle.
3. The model name comes from config (e.g., `"gemini-2.5-flash"`, `"gemini-2.0-flash-001"`).

### Model Selection

Models used across configs in this project:

| Config | Model | Notes |
|--------|-------|-------|
| `travel_report.json` | `gemini-2.5-flash` | Best balance of speed and capability |
| `heidi.json` | `gemini-2.0-flash-001` | Older, cheaper |
| `virgin_bet.json` | `gemini-2.5-flash-lite` | Fastest/cheapest, good enough for simpler extraction |
| `ballys_spain.json` | `gemini-2.5-flash` | Handles multilingual (Spanish) input |

---

## 3. Configuration System

### JSON Config Structure

Each client has a JSON config at `vertex_classification/src/configs/<client_slug>.json`.

**Example: `travel_report.json`**

```json
{
  "classifier_type": "passthrough",
  "response_schema": {
    "required_keys": ["product_focus"]
  },
  "standard": {
    "classification_settings": [],
    "llm": {
      "model": "gemini-2.5-flash",
      "category_name": null,
      "prompt_context": "travel_report_prompt_v2.txt",
      "bulk_prompt_context": "travel_report_bulk_prompt_v2.txt"
    }
  },
  "KEYWORDS_TO_REMOVE": []
}
```

**Example: `heidi.json` (Ski classifier)**

```json
{
  "classifier_type": "ski",
  "standard": {
    "classification_settings": [
      {
        "name": "Ski Location",
        "priority": 1,
        "classification_list": ["france", "italy", "austria", "switzerland", "andorra", "canada"],
        "translation_layer": {}
      }
    ],
    "llm": {
      "model": "gemini-2.0-flash-001",
      "category_name": "Ski Location",
      "prompt_context": "For the following advert text identify any ski locations...",
      "bulk_prompt_context": "For each advert separated by '||' analyse the text..."
    }
  },
  "KEYWORDS_TO_REMOVE": []
}
```

### Config Fields Reference

| Field | Type | Description |
|-------|------|-------------|
| `classifier_type` | `"ski"` \| `"passthrough"` | Which classifier subclass to instantiate |
| `response_schema` | object or null | Controls validation (`required_keys`) and output filtering (`allowed_keys`) |
| `response_schema.required_keys` | list[str] | Keys that MUST be present in LLM output; row is rejected if missing |
| `response_schema.allowed_keys` | list[str] | Only these keys are kept in the final output (passthrough only) |
| `standard.classification_settings` | list[dict] | Regex fallback categories (ski classifier only) |
| `standard.llm.model` | str | Gemini model name |
| `standard.llm.category_name` | str or null | Category label applied when LLM finds entities |
| `standard.llm.prompt_context` | str | Single-item prompt text OR filename in `src/prompts/` |
| `standard.llm.bulk_prompt_context` | str | Bulk prompt text OR filename in `src/prompts/` |
| `KEYWORDS_TO_REMOVE` | list[str] | Entities to filter out in post-processing |

### Dataclass Settings

```python
# vertex_classification/config.py:13-50

@dataclass
class ActivitySettings:
    classifier_type: str = "ski"
    response_schema: dict | None = None
    classification_settings: list = field(default_factory=list)
    keywords_to_remove: list = field(default_factory=list)
    llm_prompt_context: str | None = None
    llm_bulk_prompt_context: str | None = None
    llm_model: str | None = None
    llm_category: str | None = None

    @classmethod
    def for_client(cls, slug: str, config_dir: Path, prompts_dir: Path) -> "ActivitySettings":
        config_path = config_dir / f"{slug}.json"
        if not config_path.exists():
            raise FileNotFoundError(f"No config found for client: {slug}")
        with open(config_path, "r") as f:
            config = json.load(f)
        settings = config.get("standard", config)
        llm = settings.get("llm", {})
        prompt_context = llm.get("prompt_context")
        bulk_prompt_context = llm.get("bulk_prompt_context")

        # Load prompt files
        prompt_file = prompts_dir / prompt_context
        with open(prompt_file, "r", encoding="utf-8") as f:
            prompt_context = f.read()
        bulk_prompt_file = prompts_dir / bulk_prompt_context
        with open(bulk_prompt_file, "r", encoding="utf-8") as f:
            bulk_prompt_context = f.read()

        return cls(
            classifier_type=config.get("classifier_type", "ski"),
            response_schema=config.get("response_schema"),
            classification_settings=settings.get("classification_settings", []),
            keywords_to_remove=config.get("KEYWORDS_TO_REMOVE", []),
            llm_prompt_context=prompt_context,
            llm_bulk_prompt_context=bulk_prompt_context,
            llm_model=llm.get("model"),
            llm_category=llm.get("category_name"),
        )
```

**Key design decisions:**
- Prompt text can be **inline** in the JSON (older configs like `heidi.json`) or **referenced as a filename** in `src/prompts/` (newer configs like `travel_report.json`, `ballys_spain.json`). The config loader reads the file contents at startup.
- The `for_client` classmethod acts as a named constructor, tying a slug (derived from `TARGET_CLIENT_NAME`) to the right files.

### Factory Function

```python
# vertex_classification/config.py:68-89

def get_classifier():
    """Factory function to get the appropriate classifier based on config."""
    classifier_type = _THIS.classifier_type

    if classifier_type == "passthrough":
        from .passthrough_classifier import PassthroughActivityClassifier
        return PassthroughActivityClassifier()
    elif classifier_type == "ski":
        from .ski_classifier import SkiActivityClassifier
        return SkiActivityClassifier()
    else:
        raise ValueError(
            f"Unknown classifier_type: '{classifier_type}'. "
            f"Valid options: 'ski', 'passthrough'"
        )
```

Usage in `main.py`:
```python
classifier = config.get_classifier()
```

---

## 4. Prompt Engineering for Structured Output

### Core Principles

1. **End with the data** — Prompts always end with `Text to Analyze:` (or `Adverts:`) so the user text is appended directly.
2. **Demand raw JSON** — Explicitly say `"Return strictly valid JSON with no markdown formatting (no ```json blocks)"`.
3. **Define the exact schema in the prompt** — Specify every key name, type, and allowed values.
4. **Use `null` for missing data** — Not empty strings, not `"N/A"`.
5. **Provide worked examples of allowed values** — e.g., `"String (Flight Only, Package, Accommodation Only, Experience, Other)"`.

### Single-Item Prompt Template

```
<!-- vertex_classification/src/prompts/travel_report_prompt_v2.txt -->

You are an information extraction and classification engine for UK travel-industry
Google Search ads.
Your goal is to analyze the text of a search engine advertisement and extract
structured data into a precise JSON format.

### INPUT CONTEXT
You will be provided with the ad description of one of the following advertiser
categories:
   - "OTA" (e.g., Expedia, Booking.com, Opodo)
   - "Airline" (e.g., British Airways, Ryanair)
   ...

### CLASSIFICATION RULES
Analyze the text for the following dimensions. If a field is not present then use
null. If a field is present but doesn't clearly fall into a category then use
'Other -' and include your best attempt at the category after the dash.

1. **Product Focus**: What is primarily being sold?
   - "Flight Only"
   - "Package" (Flight + Hotel/Car)
   ...

### OUTPUT FORMAT
Return strictly valid JSON with no markdown formatting (no ```json blocks).
Use the exact keys below. Do NOT miss any of the keys, rather just insert a null
value for it.

{
  "product_focus": "String (Flight Only, Package, Accommodation Only, Experience, Other)",
  "language_of_ad": "String (e.g., 'English', 'Spanish')",
  "seasonality_mentioned": "String or null",
  ...
  "call_to_action": "Boolean"
}

Text to Analyze:
```

The classifier appends the actual ad text directly after this prompt:
```python
# base_classifier.py:81
response = self.model.generate_content(self.llm_prompt_context + text)
```

### Bulk Prompt Template

The bulk prompt is nearly identical but changes the framing:

```
<!-- vertex_classification/src/prompts/travel_report_bulk_prompt_v2.txt -->

You are an information extraction and classification engine for UK travel-industry
Google Search ads.
Your goal is to analyze the text in each of the following search engine
advertisements separated by '||', and extract structured data into a precise JSON
format.
...
```

And texts are joined with the `||` delimiter:
```python
# base_classifier.py:103
prompt = self.llm_bulk_prompt_context + '||'.join(texts)
```

### The `||` Delimiter Pattern

**Why `||`?** It's unlikely to appear in ad text, visually distinct, and easy to instruct the LLM about.

**The contract:** The prompt says "for each advert separated by `||`", and the expected response is a JSON **array** with one object per input, in the same order.

```python
# base_classifier.py:107
if isinstance(parsed, list) and len(parsed) == len(texts):
    # Success — one result per input text
```

### Prompt Patterns for Multilingual Input

For non-English ads (e.g., the `ballys_spain` config), the prompt adds a **translation scratchpad** step:

```
<!-- vertex_classification/src/prompts/ballys_spain_prompt.txt -->

PROCESSING STEPS (DO THESE IN ORDER)

1) Translation scratchpad
   - Translate the Spanish ad into clear English.
   - Summarize the main content in 1-3 concise sentences.
   - Store this English summary in the JSON field "translation_scratchpad".

2) Extraction based on the English translation
   - Using ONLY the meaning of that English translation, fill in all the
     remaining fields described below.
```

This "think then extract" pattern significantly improves accuracy for non-English text.

### Inline vs. File-Based Prompts

Older configs embed prompts directly in the JSON:
```json
"prompt_context": "For the following advert text identify any ski locations..."
```

Newer configs reference files:
```json
"prompt_context": "travel_report_prompt_v2.txt"
```

The file-based approach is strongly recommended for complex prompts because:
- Easier to version and diff
- Supports multi-line formatting with markdown headers
- Can be iterated on independently of the config

---

## 5. Classifier Architecture

### Abstract Base Class

```python
# vertex_classification/base_classifier.py

class BaseActivityClassifier(ABC):
    """Abstract base class for activity classifiers."""

    def __init__(self, use_regex_fallback: bool = False, use_post_processing: bool = False):
        # Load settings from config
        self.llm_prompt_context = self.settings.llm_prompt_context
        self.llm_bulk_prompt_context = self.settings.llm_bulk_prompt_context
        self.llm_model = self.settings.llm_model
        self.response_schema = self.settings.response_schema

        # Initialize Vertex AI
        vertexai.init(project=settings.GCP_PROJECT_ID, location=settings.GCP_REGION)
        self.model = GenerativeModel(self.llm_model)
```

### Three Abstract Hooks

Every subclass must implement these:

| Hook | Purpose | Signature |
|------|---------|-----------|
| `_interpret_llm_result` | Parse the LLM's JSON into `(entities, metadata)` | `(parsed_data: Any) -> Tuple[List[str], Dict[str, Any]]` |
| `_build_result` | Assemble the final output dict | `(classified, entities, metadata) -> Dict[str, Any]` |
| `_apply_post_processing` | Deduplicate/filter entities and categories | `(entities, classified) -> Tuple[List[str], List[str]]` |

### Classification Flow

```python
# base_classifier.py:226-267 (simplified)

def classify(self, text: str) -> Dict[str, Any] | None:
    # 1. Primary: LLM classification
    llm_entities, metadata = self._classify_with_llm(text)

    # 2. Fallback: Regex (if enabled and LLM returned nothing)
    if not entities and self.use_regex_fallback:
        self._classify_with_regex(text, classified, entities)

    # 3. Validate required keys
    if not self._validate_required_keys(metadata):
        return None  # Row rejected

    # 4. Default to "Unclassified"
    if not classified:
        classified.append("Unclassified")

    # 5. Post-processing (if enabled)
    if self.use_post_processing:
        entities, classified = self._apply_post_processing(entities, classified)

    return self._build_result(classified, entities, metadata)
```

### Passthrough Classifier

Use when: you want to return the LLM's JSON output directly (or a filtered subset of it).

```python
# vertex_classification/passthrough_classifier.py

class PassthroughActivityClassifier(BaseActivityClassifier):
    def __init__(self):
        super().__init__(use_regex_fallback=False, use_post_processing=False)

    def _interpret_llm_result(self, parsed_data):
        # Just pass through the dict
        if isinstance(parsed_data, dict):
            return [], parsed_data
        else:
            return [], {"output": parsed_data}

    def _build_result(self, classified, entities, metadata):
        if not self.response_schema:
            return metadata

        allowed_keys = self.response_schema.get("allowed_keys")
        if allowed_keys:
            return {k: metadata.get(k) for k in allowed_keys}

        return metadata
```

**Key behavior:** The `allowed_keys` in `response_schema` acts as a whitelist, filtering out any extra keys the LLM might produce (e.g., the `translation_scratchpad` in the Bally's Spain config is included in `allowed_keys` to keep it, but could be excluded if unwanted).

### Ski Classifier (Domain-Specific)

Use when: you need entity extraction + regex fallback + post-processing.

```python
# vertex_classification/ski_classifier.py

class SkiActivityClassifier(BaseActivityClassifier):
    def __init__(self, classification_settings=None):
        super().__init__(use_regex_fallback=True, use_post_processing=True)

    def _interpret_llm_result(self, parsed_data):
        # Extract "locations" and "offer" from structured response
        if isinstance(parsed_data, dict):
            locations = [str(a).lower() for a in parsed_data.get("locations", []) if a]
            offer = parsed_data.get("offer", {}) or {}
            return locations, {"type": offer.get("type"), "amount": offer.get("amount")}
        ...

    def _apply_post_processing(self, entities, classified):
        # 1. Deduplicate
        unique_entities = list(set(entities))
        # 2. Remove substring matches (keep longer strings)
        for entity in unique_entities[:]:
            for other in unique_entities:
                if entity != other and entity in other and entity in unique_entities:
                    unique_entities.remove(entity)
        # 3. Filter blacklisted keywords
        unique_entities = [e for e in unique_entities if e not in config.KEYWORDS_TO_REMOVE]
        return unique_entities, list(set(classified))

    def _build_result(self, classified, entities, metadata):
        return {
            "entity_type": classified,
            "identified_entities": entities,
            "identified_offers": metadata,
        }
```

### When to Use Each

| Scenario | Classifier | Why |
|----------|------------|-----|
| Flat extraction (all data comes from LLM JSON) | `passthrough` | No entity/category separation needed; just validate + filter keys |
| Entity extraction + category tagging + regex fallback | `ski` | Needs the full `entities → categories → post-processing` pipeline |
| New simple extraction task | `passthrough` | Start here; only graduate to a custom subclass if you need post-processing |

---

## 6. Batch Processing & Parallelization

### Architecture: asyncio + ThreadPoolExecutor

The Gemini API calls are synchronous (`model.generate_content()`), so the pipeline wraps them in a ThreadPoolExecutor and uses asyncio for concurrency control.

```python
# vertex_classification/main.py:1-17

import asyncio
from concurrent.futures import ThreadPoolExecutor, TimeoutError

BATCH_SIZE = 10
CLASSIFICATION_TIMEOUT = 300  # seconds per batch
MAX_CONCURRENT_BATCHES = 100  # adjust based on your quota limits
```

### Processing a Single Batch

```python
# vertex_classification/main.py:40-128

async def process_batch(
    batch_num, start_idx, df, classifier, output_column_names,
    semaphore, completed_batches, start_time, total_batches, csv_lock
):
    async with semaphore:  # Rate limiting
        try:
            df_batch = df.iloc[start_idx:start_idx + BATCH_SIZE].copy()
            batch_texts = df_batch['cleaned_ad_text'].tolist()

            # Run synchronous classify_bulk in executor with timeout
            loop = asyncio.get_event_loop()
            with ThreadPoolExecutor(max_workers=1) as executor:
                future = loop.run_in_executor(
                    executor,
                    classifier.classify_bulk,
                    batch_texts
                )
                try:
                    batch_results = await asyncio.wait_for(
                        future, timeout=CLASSIFICATION_TIMEOUT
                    )
                except asyncio.TimeoutError:
                    raise TimeoutError(
                        f"Classification timed out after {CLASSIFICATION_TIMEOUT} seconds"
                    )

            # Save results to CSV (thread-safe)
            df_batch['vertex_classification'] = [json.dumps(r) for r in batch_results]
            async with csv_lock:
                write_header = not _TEMP_CSV_PATH.exists()
                df_batch[output_column_names].to_csv(
                    _TEMP_CSV_PATH, mode='a', header=write_header, index=False
                )

            # Track progress
            completed_batches.append(batch_num)
            elapsed = time.time() - start_time
            avg = elapsed / len(completed_batches)
            remaining = avg * (total_batches - len(completed_batches))
            print(f"Batch {batch_num}/{total_batches} complete | "
                  f"Estimated time remaining: {int(remaining//60)}m {int(remaining%60)}s")

            return {'batch_num': batch_num, 'success': True, 'rows_saved': len(df_batch)}
        except Exception as e:
            return {'batch_num': batch_num, 'success': False, 'error': str(e),
                    'row_range': (start_idx, start_idx + BATCH_SIZE - 1)}
```

### Dispatching All Batches

```python
# vertex_classification/main.py:131-179

async def process_all_batches(df, classifier, output_column_names):
    total_batches = (len(df) + BATCH_SIZE - 1) // BATCH_SIZE
    semaphore = asyncio.Semaphore(MAX_CONCURRENT_BATCHES)
    csv_lock = asyncio.Lock()

    # Clear existing temp CSV
    if _TEMP_CSV_PATH.exists():
        os.remove(_TEMP_CSV_PATH)

    # Create and dispatch all batch tasks
    tasks = []
    for batch_num, i in enumerate(range(0, len(df), BATCH_SIZE), 1):
        task = process_batch(
            batch_num=batch_num, start_idx=i, df=df,
            classifier=classifier, output_column_names=output_column_names,
            semaphore=semaphore, completed_batches=[], start_time=time.time(),
            total_batches=total_batches, csv_lock=csv_lock
        )
        tasks.append(task)

    results = await asyncio.gather(*tasks)
    failed_batches = [r for r in results if not r['success']]
    return failed_batches
```

### Key Design Choices

| Choice | Value | Rationale |
|--------|-------|-----------|
| `BATCH_SIZE` | 10 | Each Gemini call classifies 10 texts. Balances throughput vs. reliability. |
| `MAX_CONCURRENT_BATCHES` | 100 | Semaphore cap. Adjust to your Vertex AI QPM quota. |
| `CLASSIFICATION_TIMEOUT` | 300s | Per-batch timeout. Gemini can stall on complex prompts. |
| CSV intermediate storage | append per batch | Crash recovery — partial results survive script failure. |
| `asyncio.Lock` for CSV writes | per-batch | Prevents interleaved writes from concurrent batches. |

---

## 7. Error Handling & Resilience

### JSON Cleaning (Strip Markdown Blocks)

Despite prompt instructions, Gemini sometimes wraps responses in markdown code blocks. The classifier strips these:

```python
# base_classifier.py:65-66

def _clean_and_parse_json(self, response_text: str) -> Any:
    cleaned = re.sub(r"^```json|```$", "", response_text, flags=re.MULTILINE).strip()
    return json.loads(cleaned)
```

### Bulk-to-Individual Fallback

If the bulk JSON array doesn't parse or has the wrong length, the system falls back to classifying each text individually:

```python
# base_classifier.py:88-121

def _classify_bulk_with_llm(self, texts):
    try:
        prompt = self.llm_bulk_prompt_context + '||'.join(texts)
        response = self.model.generate_content(prompt)
        parsed = self._clean_and_parse_json(response.text.strip())

        if isinstance(parsed, list) and len(parsed) == len(texts):
            # Parse each item individually
            results = []
            for item in parsed:
                try:
                    entities, metadata = self._interpret_llm_result(item)
                    results.append((entities, metadata))
                except Exception:
                    results.append(([], {}))
            return results
    except Exception:
        pass

    # Fallback: classify each text separately
    return [self._classify_with_llm(t) for t in texts]
```

**Fallback chain:**
1. Try bulk classification (1 API call for N texts)
2. If JSON parse fails → fall back to N individual API calls
3. If individual call fails → return empty `([], {})` for that item

### Timeout Handling

```python
# main.py:83-87

try:
    batch_results = await asyncio.wait_for(future, timeout=CLASSIFICATION_TIMEOUT)
except asyncio.TimeoutError:
    raise TimeoutError(f"Classification timed out after {CLASSIFICATION_TIMEOUT} seconds")
```

Timed-out batches are recorded in the `failed_batches` list with their row ranges, so you can retry just those rows.

### Required Key Validation

```python
# base_classifier.py:148-165

def _validate_required_keys(self, metadata: Dict) -> bool:
    if not self.response_schema:
        return True

    required_keys = self.response_schema.get("required_keys", [])
    for key in required_keys:
        if key not in metadata or metadata[key] is None:
            print(f"Validation failed: missing required key '{key}'")
            return False
    return True
```

If validation fails, the row returns `None` (single classify) or `{}` (bulk classify), and the `failed_count` counter increments.

### Failed Batch Tracking

```python
# main.py:216-220

if failed_batches:
    print("\nFailed batch details:")
    for failure in failed_batches:
        print(f"  - Batch {failure['batch_num']}: "
              f"rows {failure['row_range'][0]}-{failure['row_range'][1]}")
        print(f"    Error: {failure['error']}")
```

---

## 8. BigQuery Integration

### Loading Input Data

Input data is loaded via a parameterized SQL file:

```sql
-- vertex_classification/src/sql/load_data__cleaned_ads.sql

SELECT DISTINCT
      C.ad_text_guid
    , REGEXP_REPLACE(TRIM(C.cleaned_ad_text), r'\s+', ' ') AS cleaned_ad_text
    , CURRENT_TIMESTAMP AS updated_at
FROM
    {input_dataset}.stg_argus_ads_transparency_image_text_extracts A
    JOIN {output_dataset}.dim_argus_cleaned_unique_ad_text C
        ON C.ad_text_guid = A.ad_text_guid
WHERE
    A.client_name = '{client_name}'
    AND C.cleaned_ad_text IS NOT NULL
    AND C.ad_text_guid NOT IN (
        SELECT DISTINCT ad_text_guid FROM {output_table_ref}
    )
;
```

Parameters are injected via Python string formatting:

```python
# main.py:32-37, 192-195

_QUERY_PARAMETERS = {
    'client_name': settings.TARGET_CLIENT_NAME,
    'input_dataset': settings.INPUT_DATASET,
    'output_dataset': settings.OUTPUT_DATASET,
    'output_table_ref': _OUTPUT_TABLE_REF,
}

with open(_LOAD_DATA_SQL_FILEPATH, 'r') as f:
    sql = f.read().format_map(_QUERY_PARAMETERS)
df = bq_client.query(sql).to_dataframe()
```

**Key pattern:** The `NOT IN (SELECT ... FROM output_table)` clause ensures only unprocessed rows are fetched — making the pipeline idempotent.

### Writing Results with WRITE_APPEND

```python
# main.py:186-232

_OUTPUT_TABLE_SCHEMA = [
    bigquery.SchemaField("ad_text_guid", "STRING"),
    bigquery.SchemaField("vertex_classification", "STRING"),
    bigquery.SchemaField("updated_at", "TIMESTAMP"),
]

job_config = bigquery.LoadJobConfig(
    write_disposition="WRITE_APPEND",
    schema=_OUTPUT_TABLE_SCHEMA,
)

# After all batches complete, load CSV to BigQuery
df_results = pd.read_csv(_TEMP_CSV_PATH, parse_dates=['updated_at'])
job = bq_client.load_table_from_dataframe(
    df_results, _OUTPUT_TABLE_REF, job_config=job_config
)
job.result()
```

**Design:** The classification result (a full JSON dict) is stored as a single `STRING` column (`vertex_classification`). This is unpacked downstream in SQL/dbt using `JSON_EXTRACT_SCALAR()`.

### Recovery Script

If `main.py` crashes mid-run, partial results are saved in `temp_classification_results.csv`. The recovery script uploads them:

```python
# vertex_classification/upload_csv_to_bq.py

if __name__ == '__main__':
    if not _TEMP_CSV_PATH.exists():
        print(f"CSV file not found: {_TEMP_CSV_PATH}")
        exit(1)

    df = pd.read_csv(_TEMP_CSV_PATH, parse_dates=['updated_at'])
    client = bigquery.Client()
    job_config = bigquery.LoadJobConfig(
        write_disposition="WRITE_APPEND",
        schema=_OUTPUT_TABLE_SCHEMA,
    )
    job = client.load_table_from_dataframe(df, _OUTPUT_TABLE_REF, job_config=job_config)
    job.result()
    print(f"Loaded {job.output_rows} rows to {_OUTPUT_TABLE_REF}")

    response = input("\nDelete CSV file? (y/n): ").strip().lower()
    if response == 'y':
        os.remove(_TEMP_CSV_PATH)
```

---

## 9. Adapting This Template for a New Classification Task

### Step-by-Step Guide

#### Step 1: Define Your Output Schema

Decide what fields your LLM should extract. Example for a new "restaurant review" classifier:

```json
{
  "cuisine_type": "String (Italian, Chinese, Indian, ...)",
  "rating_sentiment": "String (Positive, Negative, Neutral)",
  "price_range": "String ($, $$, $$$, $$$$)",
  "dietary_options_mentioned": "List of strings or null",
  "has_delivery": "Boolean"
}
```

#### Step 2: Write Your Prompts

Create two files in `src/prompts/`:

**`your_task_prompt.txt`** (single item):
```
You are a [domain] classification engine.
Your goal is to analyze the text and extract structured data into a precise JSON format.

### INPUT CONTEXT
[Describe what the input looks like]

### CLASSIFICATION RULES
[Define each field, its allowed values, and edge cases]

### OUTPUT FORMAT
Return strictly valid JSON with no markdown formatting (no ```json blocks).
Use the exact keys below. Do NOT miss any of the keys, rather just insert a null
value for it.

{
  "key1": "description of type and allowed values",
  "key2": "description of type and allowed values",
  ...
}

Text to Analyze:
```

**`your_task_bulk_prompt.txt`** (bulk):
- Same content, but change the intro to say "for each of the following texts separated by `||`"
- Change the output description to say "Return a JSON **array** of objects in the same order"

#### Step 3: Create Your Config JSON

Create `src/configs/your_client.json`:

```json
{
  "classifier_type": "passthrough",
  "response_schema": {
    "required_keys": ["cuisine_type"],
    "allowed_keys": ["cuisine_type", "rating_sentiment", "price_range",
                     "dietary_options_mentioned", "has_delivery"]
  },
  "standard": {
    "classification_settings": [],
    "llm": {
      "model": "gemini-2.5-flash",
      "category_name": null,
      "prompt_context": "your_task_prompt.txt",
      "bulk_prompt_context": "your_task_bulk_prompt.txt"
    }
  },
  "KEYWORDS_TO_REMOVE": []
}
```

#### Step 4: Set `TARGET_CLIENT_NAME`

In `global_settings.py`:
```python
TARGET_CLIENT_NAME = 'Your Client'
```

The config loader slugifies this to `your_client` and looks for `src/configs/your_client.json`.

#### Step 5: (Optional) Create a Custom Classifier Subclass

Only needed if the passthrough classifier isn't enough. Create `your_classifier.py`:

```python
from .base_classifier import BaseActivityClassifier

class YourClassifier(BaseActivityClassifier):
    def __init__(self):
        super().__init__(use_regex_fallback=False, use_post_processing=True)

    def _interpret_llm_result(self, parsed_data):
        # Extract your entities and metadata from parsed_data
        entities = parsed_data.get("your_entities_field", [])
        metadata = {k: parsed_data.get(k) for k in ["field1", "field2"]}
        return entities, metadata

    def _apply_post_processing(self, entities, classified):
        # Your deduplication / filtering logic
        return list(set(entities)), list(set(classified))

    def _build_result(self, classified, entities, metadata):
        return {
            "categories": classified,
            "entities": entities,
            **metadata
        }
```

Then register it in the factory:
```python
# config.py get_classifier()
elif classifier_type == "your_type":
    from .your_classifier import YourClassifier
    return YourClassifier()
```

#### Step 6: Adjust the SQL

Create or modify `src/sql/load_data__cleaned_ads.sql` to query your input table. The key columns needed are:
- A unique ID column (maps to `ad_text_guid`)
- A text column (maps to `cleaned_ad_text`)
- A timestamp column (maps to `updated_at`)

#### Step 7: Update BigQuery Output Schema

In `main.py`, adjust `_OUTPUT_TABLE_SCHEMA` and `_OUTPUT_TABLE_REF` if your output table differs.

#### Step 8: Run and Iterate

```bash
python -m vertex_classification.main
```

Monitor the batch progress. If it crashes, use `upload_csv_to_bq.py` to save partial results.

### Checklist

- [ ] `global_settings.py` — `TARGET_CLIENT_NAME` set
- [ ] `src/configs/<slug>.json` — Created with correct `classifier_type`, `model`, prompt filenames
- [ ] `src/prompts/<name>.txt` — Single-item prompt ending with `Text to Analyze:`
- [ ] `src/prompts/<name>_bulk.txt` — Bulk prompt mentioning `||` separator, expecting JSON array
- [ ] `response_schema.required_keys` — Set to catch malformed LLM output
- [ ] `response_schema.allowed_keys` — Set if using passthrough to filter output keys
- [ ] `src/sql/load_data__cleaned_ads.sql` — Updated if input tables differ
- [ ] `main.py` — `_OUTPUT_TABLE_SCHEMA` and `_OUTPUT_TABLE_REF` match your BQ output table
- [ ] Test with `df = df.sample(100)` uncommented before running on full data
- [ ] Verify JSON output by spot-checking a few rows in BQ

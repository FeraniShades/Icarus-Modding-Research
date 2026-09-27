# Recording And Publishing Experiments

Raw experiment history is valuable, but a useful research library should not force every reader through every intermediate file and repeated test.

## Three Layers

### 1. Working Recipe

Publish the shortest reproducible path once a method is verified. Include prerequisites, exact systems touched, validation, and common symptoms.

### 2. Experiment Ledger

Publish the failed tests that changed the diagnosis, revealed a hazard, or ruled out an attractive theory. A compact ledger is usually enough:

| Attempt | Decisive change | Result | What it taught us | Status |
| --- | --- | --- | --- | --- |
| 01 | Changed one suspected parent field | Prompt appeared; behavior absent | Inheritance conversion was incomplete | Known bad |
| 02 | Added missing linked trait | Inventory opened | The DataTable chain required another layer | Verified clue |

Combine retries that produced the same result. Preserve exact crash signatures when they distinguish one failure from another.

### 3. Private Raw Archive

Keep complete working folders, generated JSON, crash logs, backups, and attempt-by-attempt notes locally. Promote material from this archive after it becomes informative and has been cleaned of game assets, personal paths, account identifiers, and irrelevant repetition.

## What Belongs In Public

- successful reproducible procedures;
- failures that establish a reusable rule;
- tests that isolate which layer owns a behavior;
- concise before/after field maps;
- crash or import messages needed to recognize the same problem;
- unresolved questions with enough evidence for another researcher to continue.

## What Can Stay Private

- repeated attempts with no new evidence;
- temporary copies and generated files;
- full extracted or cooked game assets;
- personal filesystem paths and account data;
- speculative notes that have not yet been separated from verified behavior;
- abandoned project details that would confuse the current method.

## Long Investigations

A project with dozens of attempts is not embarrassing or wasteful; it is often where the strongest rules come from. Publish it in stages:

1. Add the present understanding and unresolved question.
2. Keep the detailed live diary local while testing continues.
3. Promote decisive failures into a compact ledger.
4. Publish the working recipe when the mechanism is established.
5. Retain the raw archive as provenance and recovery material.

Friendly-fire research such as Friendly Paws is best handled this way: publish confirmed DataTable and damage-path findings now, keep repeated implementation attempts in the private archive, and add a focused case study once the working attack filter is established or a failed approach yields a durable safety rule.

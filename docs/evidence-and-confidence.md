# Evidence And Confidence

Icarus modding crosses several layers: DataTables, cooked Blueprints, inherited components, behavior trees, widgets, meshes, materials, generated maps, native systems, and save data. A convincing filename is not proof that a code path is active.

## Labels

### Verified

The behavior was reproduced in game, preferably from a clean savepoint and with a control comparison. Package read-back may support the result, but runtime behavior is the deciding evidence.

### Observed

The property, reference, function signature, error, or UI response was directly present in an export, asset read-back, log, or screenshot. It may not prove execution order or causation.

### Inferred

Several observations support the explanation, but one or more competing explanations remain. Inferences should state what test would promote them to Verified.

### Open Question

A bounded unknown with a useful next experiment. Open questions are not failed research; they stop us from accidentally presenting guesses as rules.

## Two Verification Gates

Cooked asset work has two separate gates:

1. **Package integrity:** the file writes, imports, and reads back with the intended references and properties.
2. **Runtime behavior:** the game constructs the components, binds delegates, follows inherited callbacks, and produces the intended result.

Passing the first gate does not imply the second. Many of our most useful lessons came from packages that serialized perfectly but lacked a compiled runtime connection.

## Experiment Record

Every significant experiment should capture:

- Goal and hypothesis.
- Game version.
- Files and rows touched.
- Backup or savepoint.
- Exact change.
- Expected result.
- Actual result.
- Verdict: keep, revert, or investigate.
- Durable lesson and next question.

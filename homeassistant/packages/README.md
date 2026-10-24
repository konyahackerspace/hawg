# Packages

One YAML file per feature (e.g. `presence.yaml`). Each file can contain any
top-level HA keys — `automation:`, `script:`, `input_boolean:`, `template:`, … —
and is loaded as `homeassistant.packages.<filename>`.

Give every automation a stable `id`; HA uses it to link the automation to its
entity, so changing it creates a new entity.

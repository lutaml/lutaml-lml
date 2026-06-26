# 8 — Update CLAUDE.md for lutaml-uml independence

**Status:** ✅ DONE

## Changes

Replaced all 6 lutaml-uml references with accurate descriptions:
- Key dependencies → removed lutaml-uml
- Bundle install → removed path dependency note
- Converter Registries → single LmlConverter::MODEL_REGISTRY section
- Domain Models → all inherit from Serializable, flattened attributes
- Added Model Compiler, Format Adapter, Executor sections
- Added CLI `compile` command documentation
- Updated Key Conventions to reflect current architecture

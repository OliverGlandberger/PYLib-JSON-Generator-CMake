# PYLib-JSON-Generator-CMake - Project Context

## Open Decisions

### Cross-Project
- **No CI/CD**: Consider adding GitHub Actions (free for public repos). A simple workflow running CMake configure + build + ctest on push catches regressions early. Completely free.
- **Naming consistency**: Ecosystem uses mixed conventions — underscores and hyphens. Pick one and standardize across all repos.

### This Project
- **Does this project actually need its own FetchContent dependencies?** `fetch_requirements.txt` is empty and `FetchModules_JSONGEN.cmake` is a no-op. If this library will never fetch sub-dependencies, drop the fetch module entirely to simplify the project and reduce surface area when consuming Core.

## What This Project Is

PYLib-JSON-Generator-CMake is intended to be a **general-purpose JSON builder library** - a Python library that programmatically constructs and writes JSON files from structured input (builder pattern API). It is consumed by PYLib-Init-Proj-CMake as a fetched submodule.

**CRITICAL**: The JSON generation logic has **not been implemented yet**. The project currently contains only placeholder/template Python code (`src/text_parser.py` returning the integer `1`). The CMake infrastructure for building, testing, and integrating as a submodule is functional, but the actual library purpose (JSON building) is entirely unimplemented.

## Role In The Ecosystem

```
PYLib-Init-Proj-CMake
  └── fetches via FetchContent: PYLib-JSON-Generator-CMake (THIS PROJECT)
                                  └── will consume: PYLib_CMakeCore [NOT YET]
```

This project is a **dependency** of PYLib-Init-Proj-CMake. When Init-Proj runs its CMake configure, it fetches this project from GitHub via `fetch_requirements.txt`, copies it into `modules/pylib_json_generator/`, and rewrites its Python imports to work from that location.

## Critical: Does NOT Yet Consume PYLib_CMakeCore

Like Init-Proj, this project has its **own independent CMake implementations** rather than consuming PYLib_CMakeCore. Its CMake modules use a `JSONGEN_` prefix convention:

- `cmake/PythonSetup_JSONGEN.cmake` - Python setup, dependency installation, file copying
- `cmake/FetchModules_JSONGEN.cmake` - FetchContent-based module fetching
- `cmake/Tests_JSONGEN.cmake` - Test discovery and CTest registration

These are **functionally similar but structurally different** from both PYLib_CMakeCore and Init-Proj. Key differences:
- Uses build-time `add_custom_target`/`add_custom_command` for file copying (vs. configure-time `file(COPY)` in the other projects)
- Has a 4-part fetch_requirements format (`Name|Namespace|URL|Tag`) vs. the canonical 3-part format
- No utility modules (no validation.cmake, directory.cmake, etc.)
- Self-fetch prevention logic (skips entries named "PYLib-JSONGenerator")

**BETA plan**: Replace entire `cmake/` directory with PYLib_CMakeCore consumption via `add_subdirectory()`, align fetch_requirements format to 3-part.

## Current State Assessment

### Functional (CMake Infrastructure)
- **CMakeLists.txt**: Root orchestration with `JSONGEN_IS_ROOT_PROJECT` detection, config loading, `PROJECT_OVERRIDE_NAME` support, sequential module inclusion. Works both as root project and as a subproject fetched by Init-Proj.
- **PythonSetup_JSONGEN.cmake**: Finds Python3 (or uses custom), installs pip deps, copies main.py/src/modules to output dir at build time, optional git init. Returns early if not root project (only installs deps as subproject).
- **FetchModules_JSONGEN.cmake**: Only runs when root project. Parses 4-part fetch_requirements, fetches via FetchContent. Currently fetch_requirements.txt is empty so this is a no-op.
- **Tests_JSONGEN.cmake**: Only runs when root project. Copies tests/ at configure time, recursively discovers test dirs, registers CTest targets (`JSONGenTests_*`), generates VS Code settings.json with unittest args.
- **config.cmake**: `PROJ_NAME` ("PYLib-JSONGenerator"), `CUSTOM_PYTHON_EXECUTABLE`, `AUTO_GIT_INIT` (ON), `OPTIONAL_MODULES` (OFF).

### Placeholder / Template Content (Python)
- **src/text_parser.py**: Returns integer `1`. Exports `src_func()`. This is a placeholder - the actual JSON builder API will replace this entirely.
- **main.py**: Prints greeting, arguments, and result of `src_func()`. Template.
- **tests/test_suite_template_one.py**: One real test: `self.assertTrue(src_func() == 1)`. Will need rewriting when JSON builder is implemented.
- **tests/test_suite_template_two.py**: Two auto-passing `self.assertTrue(True)` placeholders.
- **requirements.txt**: All dependencies commented out.
- **fetch_requirements.txt**: Empty (only has format comment).
- **README.md**: Minimal - contains setup instructions for CMake GUI but marked as incomplete.

### Outdated / Needs Alignment
1. **fetch_requirements.txt format**: Uses 4-part format (`Name|Namespace|URL|Tag`) while the canonical format (PYLib_CMakeCore and Init-Proj) is 3-part (`Name|URL|Tag`). Must be aligned to 3-part when consuming Core.
2. **File copying approach**: Uses `add_custom_command` (build-time) instead of `file(COPY)` (configure-time). The Core uses configure-time copying. This behavioral difference will disappear when this project's cmake/ is replaced by Core consumption.
3. **No utility functions**: No input validation, no directory utilities, no include guards. The Core provides all of these.

### Bugs / Issues
1. **PythonSetup_JSONGEN.cmake:14**: Sets requirements file path to `${CMAKE_SOURCE_DIR}/requirements.txt`. When this project is fetched as a submodule, `CMAKE_SOURCE_DIR` points to the **root project** (Init-Proj), not to this project. This means it would try to read Init-Proj's requirements.txt instead of its own. The fetch_requirements path (lines 16-20) correctly handles this with `CMAKE_CURRENT_LIST_DIR` for non-root case, but the requirements path does not.
2. **Tests_JSONGEN.cmake:40**: `jsongen_collect_tests("${CMAKE_BINARY_DIR}/_deps")` scans ALL _deps, not just this project's dependencies. When fetched as a submodule, this could pick up unrelated test directories from the parent project's _deps.
3. **config.cmake**: Uses `CACHE STRING` for config values, which persists across reconfigures and may cause unexpected behavior when switching between root and subproject modes.

## File Structure

```
CMakeLists.txt              # Root orchestration (48 lines)
config.cmake                # Project config (PROJ_NAME, AUTO_GIT_INIT, etc.)
main.py                     # Entry point template (calls src_func)
README.md                   # Minimal setup instructions
requirements.txt            # pip dependencies (all commented out)
fetch_requirements.txt      # Empty (4-part format comment only)
settings.json.in            # VS Code unittest config template
src/
  __init__.py
  text_parser.py            # PLACEHOLDER - will become JSON builder API
modules/
  __init__.py               # Empty
tests/
  __init__.py
  test_suite_template_one.py  # Has one real assertion (src_func() == 1)
  test_suite_template_two.py  # Two auto-pass placeholders
cmake/
  PythonSetup_JSONGEN.cmake   # Python setup + file copy (OUTDATED - replace with Core)
  FetchModules_JSONGEN.cmake  # FetchContent fetching (OUTDATED - replace with Core)
  Tests_JSONGEN.cmake         # Test discovery/CTest (OUTDATED - replace with Core)
```

## How It's Consumed By Init-Proj

Init-Proj's `fetch_requirements.txt` contains:
```
pylib_json_generator | https://github.com/OliverGlandberger/PYLib-JSON-Generator-CMake.git | master
```

When Init-Proj configures:
1. FetchContent clones this repo to `${CMAKE_BINARY_DIR}/_deps/pylib_json_generator-src`
2. `FetchContent_MakeAvailable` triggers this project's CMakeLists.txt as a subproject
3. `JSONGEN_IS_ROOT_PROJECT` = FALSE, so only pip deps are installed
4. Init-Proj copies this project's src/, modules/, tests/ to `output/modules/pylib_json_generator/`
5. Python imports are rewritten: `from src.text_parser` -> `from modules.pylib_json_generator.src.text_parser`
6. `PROJECT_OVERRIDE_NAME` is set to "pylib_json_generator" by Init-Proj

## BETA Target State

1. **Replace cmake/ directory** with PYLib_CMakeCore consumption (same as Init-Proj's BETA plan)
2. **Align fetch_requirements format** to 3-part (`Name|URL|Tag`)
   - **DECISION: Core integration first, or JSON implementation first?** Recommendation: do Core integration (items 1-2) before JSON builder (items 3-5). Otherwise you'll write tests against infrastructure that's about to be ripped out.
3. **Implement the JSON builder library**:
   - Replace `src/text_parser.py` with actual JSON generation modules
   - Design a builder-pattern API for programmatic JSON construction
   - The library should be importable as `from modules.pylib_json_generator.src.json_builder import ...` when consumed by Init-Proj
   - **DECISION: What is the actual API?** Options: (a) builder pattern with fluent chaining (`JsonBuilder().object().key("name").value("foo").end().build()`), (b) dict-like construction with file I/O (thin wrapper around `json.dumps()`), (c) template-based (define JSON schemas and fill in values). If it's just a thin wrapper around Python's built-in `json` module, consider whether this library needs to exist at all, or should provide value the stdlib doesn't (schema validation, templating, merge strategies).
   - **Free tools to consider building on**: [Pydantic](https://pydantic-docs.helpmanual.io/) (MIT) for structured data validation + serialization. [jsonschema](https://python-jsonschema.readthedocs.io/) (MIT) for JSON schema validation. Python's built-in `json` module already provides `json.dumps()`, `json.dump()`, `json.load()`, `json.JSONEncoder`.
4. **Write real tests** for the JSON builder functionality
5. **Update main.py** to demonstrate JSON builder usage
6. This project reaches BETA after Init-Proj, roughly simultaneously with Init-Proj's own BETA

## Design Notes

- **Namespace pattern**: `JSONGEN_NAMESPACE` = `PROJ_NAME`. All CMake variables use `${JSONGEN_NAMESPACE}_` prefix.
- **Subproject mode**: When `JSONGEN_IS_ROOT_PROJECT=FALSE`, only pip dependencies are installed. File copying, test discovery, and fetch_modules are all skipped. The parent project handles copying and test integration.
- **CMake minimum version**: 3.15 (will need to be raised to 3.28 when consuming Core).
- **Git history**: 44 commits on master, most recent adds `PROJECT_OVERRIDE_NAME` support.

// WireMudder Import and Migration Pane Boundary (EP-030)
//
// Model-side passive implementation: reflects crate-produced import
// summaries and migration reports for the operator. This translation unit
// is wired into the inherited CMake source list beside soundscape,
// diagnostics, and help so the boundary compiles with the real Qt6 build.
#include "import_boundary.h"

namespace wiremudder::ui::import {

// The boundary is intentionally model-only at this layer; the widget
// surface that renders ImportPaneModel lives behind the same header and
// stays passive (display + request flags, no mutation).
static_assert(sizeof(ImportPaneModel) > 0, "ImportPaneModel must be complete");

} // namespace wiremudder::ui::import

# Blueprint Known Risks

- The pinned upstream branch may advance; EP-000 re-verifies source evidence.
- Mudlet internal integration points may be less stable than public interfaces; discovered paths must remain narrow.
- A sidecar introduces IPC, process lifecycle, and packaging complexity; EP-005 can fall back to disabled optional systems while preserving the inherited client.
- Lua and package compatibility is broad and historically nuanced; independent corpora and user migration reports are required.
- Voice, model, renderer, audio, and update providers carry privacy, cost, license, and supply-chain risk and remain optional until certified.
- Cross-platform packaging and signing are expensive; release profiles may initially advertise only fully certified platforms.
- No prompt can make a stochastic model incapable of local hallucination. The design prevents unsupported claims and paths from promoting through gates.

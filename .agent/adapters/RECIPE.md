# Adapter Recipe

1. Find the platform's documented standing-instruction path.
2. Copy the exact text between `PRIME-BLOCK-BEGIN` and `PRIME-BLOCK-END` from AGENTS.md.
3. Add one line naming the platform after the block.
4. Add the path to `scripts/adapter-parity-check.sh` and `.agent/MANIFEST.md`.
5. Run `sh scripts/adapter-parity-check.sh` and require `adapter parity: ok`.

Do not add platform-specific project law or volatile state to an adapter.

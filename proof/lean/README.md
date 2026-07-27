# Lean proof

`Poseidon2NoOverflow.lean` is a dependency-free Lean 4 proof that no `unchecked`
arithmetic in `src/Poseidon2T2_BN254.sol`, `src/Poseidon2T3_BN254.sol`, and
`src/Poseidon2T4_BN254.sol` can overflow `uint256`. It proves:

- T2's external and internal linear layers stay below `2^256`
  (`t2ExternalLayer_safe`, `t2InternalLayer_safe`);
- T3's external and internal linear layers stay below `2^256`
  (`t3ExternalLayer_safe`, `t3InternalLayer_safe`); the internal layer's
  `s2 += s2 + sum` is the widest expression in either file, bounded by `5 * PRIME`;
- T4's M4 external linear layer and its internal linear layer stay below `2^256`
  (`t4ExternalLayer_safe`, `t4InternalLayerEntry_safe`, `t4InternalLayerOutput_safe`);
- the `t << 2` shifts in T4's M4 layer equal the exact product `t * 4`: Solidity's
  `<<` never reverts on overflow, so a shift that silently truncated would be wrong
  rather than reverting, and this needs its own bound;
- round-constant additions are safe for any constant `< PRIME`
  (`roundConstantAdd_safe`), so a single lemma covers every round;
- `allUncheckedBlockShapes_safe` and `t4AllUncheckedBlockShapes_safe` package the
  finitely many syntactic shapes of `unchecked` block that appear across the three
  permutations, so each applies to every occurrence of its shape.

Run it with:

```sh
lake build
```

Arithmetic in the proof is `Nat` arithmetic: showing every intermediate result is
below `2^256` is exactly what makes Solidity's `unchecked` arithmetic agree with
ordinary (non-wrapping) arithmetic.

The proof relies on the public precondition of `_perm`: input lanes are below
`PRIME`. It assumes, rather than reproves, that `mulmod`, `addmod`, and `% PRIME`
produce values below `PRIME`. The lemmas are matched by hand to the unchecked-block
shapes in the Solidity source rather than mechanically extracted from it. It proves
absence of overflow only, not that the permutation computes Poseidon2 correctly.

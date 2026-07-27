import Lean.Elab.Tactic.Omega

/-!
# Absence of uint256 overflow in the Poseidon2 Solidity implementations

This file proves the bounds used by `Poseidon2T2_BN254._perm`,
`Poseidon2T3_BN254._perm`, and `Poseidon2T4_BN254._perm`.  Arithmetic here is
`Nat` arithmetic: proving that every intermediate result is below
`uint256Limit` proves that Solidity's `unchecked` arithmetic agrees with
ordinary (non-wrapping) arithmetic.

The proof relies on the public precondition of `_perm`: input lanes are below
`prime`.  `mulmod(_, _, prime)`, `addmod(_, _, prime)`, and `% prime` also
produce values below `prime`.  Every round constant in the three Solidity
files is below `prime`.  The lemmas are parametric in such a constant, so
they apply to every round.

T4's external (M4) linear layer additionally shifts an `addmod` result left
by 2 bits (`t1 << 2`) outside of any `unchecked` block. Solidity's `<<` never
reverts on overflow, checked or not, so a shift that silently truncated would
be wrong rather than reverting; the T4 lemmas below prove `t * 4 < uint256Limit`
at each such shift, which is exactly the condition for `t << 2` to equal the
exact product `t * 4`.
-/

namespace Poseidon2NoOverflow

def prime : Nat :=
  0x30644e72e131a029b85045b68181585d2833e84879b9709143e1f593f0000001

def uint256Limit : Nat := 2 ^ 256

theorem five_prime_lt_uint256 : 5 * prime < uint256Limit := by
  decide

/- `x + c` is used for unchecked round-constant additions whenever the lane
   has a strict `4 * prime` bound. -/
theorem roundConstantAdd_safe
    {x c : Nat} (hx : x < 4 * prime) (hc : c < prime) :
    x + c < uint256Limit := by
  have h5 := five_prime_lt_uint256
  omega

/- T2 external matrix block:
     s = l + r; l += s; r += s
   The conjunction includes the temporary `s` and both assignments. -/
theorem t2ExternalLayer_safe
    {l r : Nat} (hl : l < prime) (hr : r < prime) :
    l + r < uint256Limit ∧
    l + (l + r) < uint256Limit ∧
    r + (l + r) < uint256Limit ∧
    l + (l + r) < 3 * prime ∧
    r + (l + r) < 3 * prime := by
  have h5 := five_prime_lt_uint256
  omega

/- T2 internal matrix block after `mulmod` resets `l` and `% prime` resets
   `r`:
     s = l + r; l += s; r = r + r + s
   Both the left-associated intermediate `r + r` and its final addition are
   covered. -/
theorem t2InternalLayer_safe
    {l r : Nat} (hl : l < prime) (hr : r < prime) :
    l + r < uint256Limit ∧
    l + (l + r) < uint256Limit ∧
    r + r < uint256Limit ∧
    (r + r) + (l + r) < uint256Limit ∧
    l + (l + r) < 3 * prime ∧
    (r + r) + (l + r) < 4 * prime := by
  have h5 := five_prime_lt_uint256
  omega

/- T3 external matrix block:
     sum = s0 + s1 + s2; si += sum
   Solidity parses the sum left-associatively, so `s0 + s1` is included. -/
theorem t3ExternalLayer_safe
    {s0 s1 s2 : Nat}
    (h0 : s0 < prime) (h1 : s1 < prime) (h2 : s2 < prime) :
    s0 + s1 < uint256Limit ∧
    (s0 + s1) + s2 < uint256Limit ∧
    s0 + ((s0 + s1) + s2) < uint256Limit ∧
    s1 + ((s0 + s1) + s2) < uint256Limit ∧
    s2 + ((s0 + s1) + s2) < uint256Limit ∧
    s0 + ((s0 + s1) + s2) < 4 * prime ∧
    s1 + ((s0 + s1) + s2) < 4 * prime ∧
    s2 + ((s0 + s1) + s2) < 4 * prime := by
  have h5 := five_prime_lt_uint256
  omega

/- T3 internal matrix block after all three lanes have been reset below the
   prime:
     sum = s0 + s1 + s2
     s0 += sum; s1 += sum; s2 += s2 + sum
   The last assignment is the largest unchecked expression in either file.
   Its strict `5 * prime` bound is what makes the optimization safe. -/
theorem t3InternalLayer_safe
    {s0 s1 s2 : Nat}
    (h0 : s0 < prime) (h1 : s1 < prime) (h2 : s2 < prime) :
    s0 + s1 < uint256Limit ∧
    (s0 + s1) + s2 < uint256Limit ∧
    s0 + ((s0 + s1) + s2) < uint256Limit ∧
    s1 + ((s0 + s1) + s2) < uint256Limit ∧
    s2 + ((s0 + s1) + s2) < uint256Limit ∧
    s2 + (s2 + ((s0 + s1) + s2)) < uint256Limit ∧
    s0 + ((s0 + s1) + s2) < 4 * prime ∧
    s1 + ((s0 + s1) + s2) < 4 * prime ∧
    s2 + (s2 + ((s0 + s1) + s2)) < 5 * prime := by
  have h5 := five_prime_lt_uint256
  omega

/- This packages the four syntactic unchecked-block shapes used throughout
   the t=2 and t=3 permutations.  Repetition of a block does not weaken its
   result: every S-box `mulmod` (and each explicit remainder) restores its
   hypotheses.  Thus the theorem applies to all 8 external rounds and every
   internal round, independently of the number of repetitions. -/
theorem allUncheckedBlockShapes_safe
    {a b c k : Nat}
    (ha : a < prime) (hb : b < prime) (hc : c < prime) (hk : k < prime) :
    (a + (a + b) < uint256Limit) ∧
    ((b + b) + (a + b) < uint256Limit) ∧
    (c + (c + ((a + b) + c)) < uint256Limit) ∧
    (a + (a + b) + k < uint256Limit) := by
  have ht2 := t2InternalLayer_safe ha hb
  have ht3 := t3InternalLayer_safe ha hb hc
  have hconst : a + (a + b) + k < uint256Limit := by
    apply roundConstantAdd_safe
    · omega
    · exact hk
  omega

/- T4 external (M4) linear layer, entered with `s1, s3 < prime` (`s0`, `s2`
   are dead on entry: both are fully overwritten below, so they carry no
   precondition). `t0 = addmod(s0, s1, PRIME)` and `t1 = addmod(s2, s3, PRIME)`
   are computed from the old state; `t4`, `t5` are the two later `addmod`
   calls. The Solidity, in order:
     s1 = s1 + s1 + t1; s3 = s3 + s3 + t0
     t4 = addmod(t1 << 2, s3, PRIME); t5 = addmod(t0 << 2, s1, PRIME)
     s0 = s3 + t5; s2 = s1 + t4
   (`s1`, `s3` on the right of the last two lines are the already-updated
   values.) The `t0 * 4` / `t1 * 4` conjuncts are the shift-safety condition
   from the module docstring. This shape occurs 9 times: the initial linear
   layer plus all 8 external rounds. -/
theorem t4ExternalLayer_safe
    {s1 s3 t0 t1 t4 t5 : Nat}
    (h1 : s1 < prime) (h3 : s3 < prime)
    (ht0 : t0 < prime) (ht1 : t1 < prime) (ht4 : t4 < prime) (ht5 : t5 < prime) :
    s1 + s1 < uint256Limit ∧
    (s1 + s1) + t1 < uint256Limit ∧
    s3 + s3 < uint256Limit ∧
    (s3 + s3) + t0 < uint256Limit ∧
    t0 * 4 < uint256Limit ∧
    t1 * 4 < uint256Limit ∧
    ((s3 + s3) + t0) + t5 < uint256Limit ∧
    ((s1 + s1) + t1) + t4 < uint256Limit ∧
    ((s3 + s3) + t0) + t5 < 4 * prime ∧
    ((s1 + s1) + t1) + t4 < 4 * prime := by
  have h5 := five_prime_lt_uint256
  omega

/- T4 internal linear layer entry:
     sum = addmod(s0 + s1, s2 + s3, PRIME)
   The raw `s0 + s1` and `s2 + s3` are computed in an `unchecked` block, so
   both must stay below `uint256Limit`. Two shapes occur, depending on which
   round this is:
   - Internal round 0: reached from the last of the 4 initial external
     rounds, where only `s0` has since been round-constant-added and
     S-boxed (`s0 < prime`); `s1`, `s2`, `s3` are untouched M4 outputs
     (`s1, s3 < prime`, `s2 < 4 * prime` from `t4ExternalLayer_safe`).
   - Internal rounds 1-55: reached from the previous internal round's
     output (`t4InternalLayerOutput_safe` below), where every lane is
     `< 2 * prime`, and only `s0` has since been round-constant-added and
     S-boxed (`s0 < prime`).
   This is the tightest point in T4: round 0's `s2 + s3` reaches
   `< 5 * prime`, the same ceiling T3 hits at its internal/external
   boundary. -/
theorem t4InternalLayerEntry_safe
    {s0 s1 s2 s3 : Nat}
    (h : (s0 < prime ∧ s1 < prime ∧ s2 < 4 * prime ∧ s3 < prime) ∨
         (s0 < prime ∧ s1 < 2 * prime ∧ s2 < 2 * prime ∧ s3 < 2 * prime)) :
    s0 + s1 < uint256Limit ∧ s2 + s3 < uint256Limit := by
  have h5 := five_prime_lt_uint256
  rcases h with ⟨_, _, _, _⟩ | ⟨_, _, _, _⟩ <;> omega

/- T4 internal linear layer output, for each lane i:
     s_i = mulmod(s_i, MAT_DIAG_i, PRIME) + sum
   `d` stands for the `mulmod` result and is generic across all four lanes;
   `sum` is the `addmod` result from `t4InternalLayerEntry_safe`. The
   `< 2 * prime` bound is what re-establishes the hypotheses of
   `t4InternalLayerEntry_safe`'s second case for the next round, and what
   satisfies `roundConstantAdd_safe`'s `< 4 * prime` precondition for the
   following external round's constant add. -/
theorem t4InternalLayerOutput_safe
    {d sum : Nat} (hd : d < prime) (hsum : sum < prime) :
    d + sum < uint256Limit ∧ d + sum < 2 * prime := by
  have h5 := five_prime_lt_uint256
  omega

/- Packages the T4-specific unchecked-block shapes (the M4 layer and the
   internal layer's `mulmod _ + sum` output). Round-constant adds reuse
   `roundConstantAdd_safe` directly, since every lane entering one is
   `< 4 * prime` (shown above); the internal layer's raw `s0 + s1` /
   `s2 + s3` reuse `t4InternalLayerEntry_safe` directly, since it already
   concludes `< uint256Limit`. Combined with those two, this covers every
   unchecked block in `Poseidon2T4_BN254._perm`: the initial linear layer,
   all 8 external rounds, and all 56 internal rounds. -/
theorem t4AllUncheckedBlockShapes_safe
    {s1 s3 t0 t1 t4 t5 d sum k x : Nat}
    (h1 : s1 < prime) (h3 : s3 < prime)
    (ht0 : t0 < prime) (ht1 : t1 < prime) (ht4 : t4 < prime) (ht5 : t5 < prime)
    (hd : d < prime) (hsum : sum < prime)
    (hx : x < 4 * prime) (hk : k < prime) :
    (s1 + s1 < uint256Limit) ∧
    ((s1 + s1) + t1 < uint256Limit) ∧
    (s3 + s3 < uint256Limit) ∧
    ((s3 + s3) + t0 < uint256Limit) ∧
    (t0 * 4 < uint256Limit) ∧
    (t1 * 4 < uint256Limit) ∧
    (((s3 + s3) + t0) + t5 < uint256Limit) ∧
    (((s1 + s1) + t1) + t4 < uint256Limit) ∧
    (d + sum < uint256Limit) ∧
    (x + k < uint256Limit) := by
  have hext := t4ExternalLayer_safe h1 h3 ht0 ht1 ht4 ht5
  have hout := t4InternalLayerOutput_safe hd hsum
  have hconst := roundConstantAdd_safe hx hk
  omega

end Poseidon2NoOverflow

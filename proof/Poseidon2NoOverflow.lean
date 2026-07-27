import Lean.Elab.Tactic.Omega

/-!
# Absence of uint256 overflow in the Poseidon2 Solidity implementations

This file proves the bounds used by `Poseidon2T2_BN254._perm` and
`Poseidon2T3_BN254._perm`.  Arithmetic here is `Nat` arithmetic: proving that
every intermediate result is below `uint256Limit` proves that Solidity's
`unchecked` arithmetic agrees with ordinary (non-wrapping) arithmetic.

The proof relies on the public precondition of `_perm`: input lanes are below
`prime`.  `mulmod(_, _, prime)` and `% prime` also produce values below
`prime`.  Every round constant in the two Solidity files is below `prime`.
The lemmas are parametric in such a constant, so they apply to every round.
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
   both permutations.  Repetition of a block does not weaken its result:
   every S-box `mulmod` (and each explicit remainder) restores its hypotheses.
   Thus the theorem applies to all 8 external rounds and every internal round,
   independently of the number of repetitions. -/
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

end Poseidon2NoOverflow

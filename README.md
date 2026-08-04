 [![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
# Poseidon2 Solidity Library

Minimal Solidity implementation of the **Poseidon2 hash function** over the BN254 scalar field, for EVM compatible chains.

## Install

Using Foundry:

```bash
forge install TaceoLabs/poseidon2-solidity
```

Using [Soldeer](https://soldeer.xyz):

```bash
forge soldeer install poseidon2-solidity~0.2.0
```

Or add it to your `foundry.toml`:
```toml
[dependencies]
poseidon2-solidity = "0.2.0"
```

## Usage

```solidity
import "@taceo/poseidon2/Poseidon2T2_BN254.sol";
import "@taceo/poseidon2/Poseidon2T3_BN254.sol";
import "@taceo/poseidon2/Poseidon2T4_BN254.sol";

uint256 h2 = Poseidon2T2_BN254.compress([a, b]);
uint256 h3 = Poseidon2T3_BN254.compress([a, b, c]);
uint256 h4 = Poseidon2T4_BN254.compress([a, b, c, d]);
```

Each state size also provides scalar internal overloads. These inline the
permutation into the consumer and avoid the linked library call:

```solidity
uint256 h2Inline = Poseidon2T2_BN254.compress(a, b);
uint256 h3Inline = Poseidon2T3_BN254.compress(a, b, c);
uint256 h4Inline = Poseidon2T4_BN254.compress(a, b, c, d);
uint256 h2InlineUnchecked = Poseidon2T2_BN254.compressUnchecked(a, b);
uint256[3] memory state = Poseidon2T3_BN254.permutation(a, b, c);
```

Use the array overload when bytecode size matters, and the scalar overload when
call gas matters.

### Gas and bytecode trade-offs

The following measurements use Solidity 0.8.24, the legacy compilation pipeline,
and the default 200 optimizer runs. Gas is for the direct checked library
entrypoint; runtime size excludes initcode.

| State size | Solidity gas | Yul gas | Gas savings | Solidity runtime | Yul runtime |
| --- | ---: | ---: | ---: | ---: | ---: |
| T2 | 21,195 | 11,252 | 46.9% | 9,945 bytes | 5,161 bytes |
| T3 | 29,449 | 14,169 | 51.9% | 12,687 bytes | 6,254 bytes |
| T4 | 47,047 | 25,724 | 45.3% | 21,647 bytes | 6,760 bytes |

The Yul implementation does not perform less Poseidon arithmetic. A trace of
the unchecked T4 compression executes the same 488 `MULMOD` and 93 `ADDMOD`
instructions in both implementations:

| Trace metric | Solidity | Yul |
| --- | ---: | ---: |
| Gas | 46,789 | 25,466 |
| EVM instructions | 14,124 | 7,708 |
| `MULMOD` | 488 | 488 |
| `ADDMOD` | 93 | 93 |
| `CODECOPY` | 809 | 2 |
| `MLOAD` | 1,627 | 6 |
| `MSTORE` | 821 | 4 |
| `JUMPI` | 159 | 8 |

At 200 optimizer runs, the legacy Solidity code generator reduces bytecode size
by placing repeated field and matrix constants in the code data section. Each
use then requires `CODECOPY` and memory operations. It also emits nonzero-modulus
checks around high-level modular operations. The Yul core keeps the field modulus
on the stack, uses shared helpers for repeated round logic, and emits the raw EVM
modular operations because the fixed modulus is known to be nonzero.

Increasing the optimizer setting to 1,000,000 makes the old Solidity core
faster, but it still does not beat Yul and its bytecode grows substantially:

| State size | Solidity gas | Yul gas | Solidity runtime | Yul runtime |
| --- | ---: | ---: | ---: | ---: |
| T2 | 12,331 | 11,124 | 15,364 bytes | 5,318 bytes |
| T3 | 17,865 | 14,009 | 19,740 bytes | 6,474 bytes |
| T4 | Not deployable | 25,532 | 37,104 bytes | 7,018 bytes |

The old T4 runtime exceeds the EIP-170 limit of 24,576 bytes at 1,000,000
optimizer runs.

The scalar overload saves the library call overhead, at the cost of copying the
permutation into the consumer:

| State size | Linked call gas | Inline call gas | Gas savings | Library runtime | Minimal linked consumer | Minimal inline consumer | Inline size increase |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| T2 | 14,488 | 11,275 | 22.2% | 5,161 bytes | 337 bytes | 4,671 bytes | 4,334 bytes |
| T3 | 17,433 | 14,241 | 18.3% | 6,254 bytes | 337 bytes | 5,738 bytes | 5,401 bytes |
| T4 | 29,005 | 25,782 | 11.1% | 6,760 bytes | 337 bytes | 6,197 bytes | 5,860 bytes |

These consumer-level figures use the default 200 optimizer runs. Inlined code is
copied into every consumer that uses an internal overload and can push a larger
contract over the EIP-170 runtime limit.

Run the following commands on this revision and the pre-Yul revision (`21b6a9f`)
to reproduce the comparisons:

```bash
forge test --gas-report
forge build --sizes
forge test --optimizer-runs 1000000 --gas-report
forge build --optimizer-runs 1000000 --sizes
```

Add one of the following to your `remappings.txt`, depending on how you installed the library:
```
# forge install
@taceo/poseidon2/=lib/poseidon2-solidity/src/

# Soldeer
@taceo/poseidon2/=dependencies/poseidon2-solidity-0.2.0/src/
```

## Security

This library is currently **unaudited**. Use at your own risk in production systems.

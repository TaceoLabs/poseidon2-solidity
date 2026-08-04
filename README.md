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
call gas matters. With Solidity 0.8.24 and this repository's optimizer settings,
the Yul permutation cores reduce the gas of the checked linked-library calls as
follows:

| State size | Previous gas | Optimized gas | Savings |
| --- | ---: | ---: | ---: |
| T2 | 21,195 | 11,252 | 46.9% |
| T3 | 29,449 | 14,169 | 51.9% |

The scalar overload saves the library call overhead, at the cost of copying the
permutation into the consumer:

| State size | Linked call gas | Inline call gas | Gas savings | Library runtime | Minimal linked consumer | Minimal inline consumer | Inline size increase |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| T2 | 14,488 | 11,275 | 22.2% | 5,161 bytes | 337 bytes | 4,671 bytes | 4,334 bytes |
| T3 | 17,433 | 14,241 | 18.3% | 6,254 bytes | 337 bytes | 5,738 bytes | 5,401 bytes |
| T4 | 29,005 | 25,782 | 11.1% | 6,760 bytes | 337 bytes | 6,197 bytes | 5,860 bytes |

See `forge test --gas-report` and `forge build --sizes` to reproduce these
figures. Inlined code is copied into every consumer that uses an internal
overload and can push a larger contract over the EIP-170 limit of 24,576 runtime
bytes.

Add one of the following to your `remappings.txt`, depending on how you installed the library:
```
# forge install
@taceo/poseidon2/=lib/poseidon2-solidity/src/

# Soldeer
@taceo/poseidon2/=dependencies/poseidon2-solidity-0.2.0/src/
```

## Security

This library is currently **unaudited**. Use at your own risk in production systems.

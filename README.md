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

T4 also provides four-scalar internal overloads. These inline the permutation into
the consumer and avoid the linked library call:

```solidity
uint256 h4Inline = Poseidon2T4_BN254.compress(a, b, c, d);
uint256 h4InlineUnchecked = Poseidon2T4_BN254.compressUnchecked(a, b, c, d);
uint256[4] memory state = Poseidon2T4_BN254.permutation(a, b, c, d);
```

Use the array overload when bytecode size matters, and the scalar overload when
call gas matters. With Solidity 0.8.24 and this repository's optimizer settings,
checked T4 compression costs 25,724 gas in the library itself; a minimal external
consumer's call costs 29,005 gas, while the inline consumer costs 25,782 gas
(11.1% less). The deployed library is 6,760 runtime bytes. See
`forge build --sizes` for the exact consumer sizes: the minimal external consumer
is 337 runtime bytes and the minimal inline consumer is 6,197 bytes, an increase
of exactly 5,860 bytes. This code is copied into every consumer that uses an
internal overload and can push a larger contract over the EIP-170 limit of
24,576 runtime bytes.

Add one of the following to your `remappings.txt`, depending on how you installed the library:
```
# forge install
@taceo/poseidon2/=lib/poseidon2-solidity/src/

# Soldeer
@taceo/poseidon2/=dependencies/poseidon2-solidity-0.2.0/src/
```

## Security

This library is currently **unaudited**. Use at your own risk in production systems.

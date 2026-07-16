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
forge soldeer install poseidon2-solidity~0.1.0
```

Or add it to your `foundry.toml`:
```toml
[dependencies]
poseidon2-solidity = "0.1.0"
```

## Usage

```solidity
import "@taceo/poseidon2/Poseidon2T2_BN254.sol";
import "@taceo/poseidon2/Poseidon2T3_BN254.sol";

uint256 h2 = Poseidon2T2_BN254.compress([a, b], domainSep);
uint256 h3 = Poseidon2T3_BN254.compress([a, b, c], domainSep);
```

Add one of the following to your `remappings.txt`, depending on how you installed the library:
```
# forge install
@taceo/poseidon2/=lib/poseidon2/src/

# Soldeer
@taceo/poseidon2/=dependencies/poseidon2-0.1.0/src/
```

## Security

This library is currently **unaudited**. Use at your own risk in production systems.

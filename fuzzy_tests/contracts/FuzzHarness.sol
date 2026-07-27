// SPDX-License-Identifier: MIT
pragma solidity >=0.8.8;

import {Poseidon2T2_BN254} from "../../src/Poseidon2T2_BN254.sol";
import {Poseidon2T3_BN254} from "../../src/Poseidon2T3_BN254.sol";
import {Poseidon2T4_BN254} from "../../src/Poseidon2T4_BN254.sol";

/// @title Differential-fuzzing harness for the Poseidon2 libraries.
/// @dev Runs a whole chain of hashes in a single call and returns every
/// intermediate output, so one EVM call covers many hashes and a mismatch
/// can be pinned to the exact step. Chaining rules (mirrored in Rust):
/// compress feeds its single output into every input slot of the next step;
/// permutation feeds the full output state into the next step.
contract FuzzHarness {
    function chainCompressT2(uint256[2] calldata input, uint256 n) external pure returns (uint256[] memory outs) {
        outs = new uint256[](n);
        uint256[2] memory st = input;
        for (uint256 i = 0; i < n; i++) {
            uint256 out = Poseidon2T2_BN254.compress(st);
            outs[i] = out;
            st[0] = out;
            st[1] = out;
        }
    }

    function chainCompressUncheckedT2(uint256[2] calldata input, uint256 n)
        external
        pure
        returns (uint256[] memory outs)
    {
        outs = new uint256[](n);
        uint256[2] memory st = input;
        for (uint256 i = 0; i < n; i++) {
            uint256 out = Poseidon2T2_BN254.compressUnchecked(st);
            outs[i] = out;
            st[0] = out;
            st[1] = out;
        }
    }

    function chainPermT2(uint256[2] calldata state, uint256 n) external pure returns (uint256[] memory outs) {
        outs = new uint256[](2 * n);
        uint256[2] memory st = state;
        for (uint256 i = 0; i < n; i++) {
            st = Poseidon2T2_BN254.permutation(st);
            outs[2 * i] = st[0];
            outs[2 * i + 1] = st[1];
        }
    }

    function chainPermUncheckedT2(uint256[2] calldata state, uint256 n) external pure returns (uint256[] memory outs) {
        outs = new uint256[](2 * n);
        uint256[2] memory st = state;
        for (uint256 i = 0; i < n; i++) {
            st = Poseidon2T2_BN254.permutationUnchecked(st);
            outs[2 * i] = st[0];
            outs[2 * i + 1] = st[1];
        }
    }

    function chainCompressT3(uint256[3] calldata input, uint256 n) external pure returns (uint256[] memory outs) {
        outs = new uint256[](n);
        uint256[3] memory st = input;
        for (uint256 i = 0; i < n; i++) {
            uint256 out = Poseidon2T3_BN254.compress(st);
            outs[i] = out;
            st[0] = out;
            st[1] = out;
            st[2] = out;
        }
    }

    function chainCompressUncheckedT3(uint256[3] calldata input, uint256 n)
        external
        pure
        returns (uint256[] memory outs)
    {
        outs = new uint256[](n);
        uint256[3] memory st = input;
        for (uint256 i = 0; i < n; i++) {
            uint256 out = Poseidon2T3_BN254.compressUnchecked(st);
            outs[i] = out;
            st[0] = out;
            st[1] = out;
            st[2] = out;
        }
    }

    function chainPermT3(uint256[3] calldata state, uint256 n) external pure returns (uint256[] memory outs) {
        outs = new uint256[](3 * n);
        uint256[3] memory st = state;
        for (uint256 i = 0; i < n; i++) {
            st = Poseidon2T3_BN254.permutation(st);
            outs[3 * i] = st[0];
            outs[3 * i + 1] = st[1];
            outs[3 * i + 2] = st[2];
        }
    }

    function chainPermUncheckedT3(uint256[3] calldata state, uint256 n) external pure returns (uint256[] memory outs) {
        outs = new uint256[](3 * n);
        uint256[3] memory st = state;
        for (uint256 i = 0; i < n; i++) {
            st = Poseidon2T3_BN254.permutationUnchecked(st);
            outs[3 * i] = st[0];
            outs[3 * i + 1] = st[1];
            outs[3 * i + 2] = st[2];
        }
    }

    function chainCompressT4(uint256[4] calldata input, uint256 n) external pure returns (uint256[] memory outs) {
        outs = new uint256[](n);
        uint256[4] memory st = input;
        for (uint256 i = 0; i < n; i++) {
            uint256 out = Poseidon2T4_BN254.compress(st);
            outs[i] = out;
            st[0] = out;
            st[1] = out;
            st[2] = out;
            st[3] = out;
        }
    }

    function chainCompressUncheckedT4(uint256[4] calldata input, uint256 n)
        external
        pure
        returns (uint256[] memory outs)
    {
        outs = new uint256[](n);
        uint256[4] memory st = input;
        for (uint256 i = 0; i < n; i++) {
            uint256 out = Poseidon2T4_BN254.compressUnchecked(st);
            outs[i] = out;
            st[0] = out;
            st[1] = out;
            st[2] = out;
            st[3] = out;
        }
    }

    function chainPermT4(uint256[4] calldata state, uint256 n) external pure returns (uint256[] memory outs) {
        outs = new uint256[](4 * n);
        uint256[4] memory st = state;
        for (uint256 i = 0; i < n; i++) {
            st = Poseidon2T4_BN254.permutation(st);
            outs[4 * i] = st[0];
            outs[4 * i + 1] = st[1];
            outs[4 * i + 2] = st[2];
            outs[4 * i + 3] = st[3];
        }
    }

    function chainPermUncheckedT4(uint256[4] calldata state, uint256 n) external pure returns (uint256[] memory outs) {
        outs = new uint256[](4 * n);
        uint256[4] memory st = state;
        for (uint256 i = 0; i < n; i++) {
            st = Poseidon2T4_BN254.permutationUnchecked(st);
            outs[4 * i] = st[0];
            outs[4 * i + 1] = st[1];
            outs[4 * i + 2] = st[2];
            outs[4 * i + 3] = st[3];
        }
    }
}

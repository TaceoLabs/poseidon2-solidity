//! Differential fuzzer: Solidity Poseidon2 libraries vs the taceo-poseidon2 Rust crate.
//!
//! Compiles `contracts/FuzzHarness.sol` with forge, loads the runtime bytecode of the
//! two libraries and the link-patched harness into an in-process revm instance, then
//! runs seeded hash chains through both the EVM and the Rust reference and compares
//! every intermediate output.

use std::collections::BTreeMap;
use std::path::{Path, PathBuf};
use std::process::Command;
use std::time::Instant;

use alloy_primitives::{address, hex, uint, Address, U256};
use alloy_sol_types::{sol, SolCall, SolValue};
use anyhow::{anyhow, bail, ensure, Context as _, Result};
use ark_bn254::Fr;
use ark_ff::{BigInteger, PrimeField};
use clap::Parser;
use rand::{Rng, RngCore, SeedableRng};
use rand_chacha::ChaCha12Rng;
use rayon::prelude::*;
use revm::context::result::{ExecutionResult, Output};
use revm::context::TxEnv;
use revm::database::{CacheDB, EmptyDB};
use revm::primitives::TxKind;
use revm::state::{AccountInfo, Bytecode};
use revm::{Context, ExecuteEvm, MainBuilder, MainContext};

const PRIME: U256 = uint!(0x30644e72e131a029b85045b68181585d2833e84879b9709143e1f593f0000001_U256);

const LIB_T2: Address = address!("0000000000000000000000000000000000001002");
const LIB_T3: Address = address!("0000000000000000000000000000000000001003");
const LIB_T4: Address = address!("0000000000000000000000000000000000001004");
const HARNESS: Address = address!("00000000000000000000000000000000000fa221");
const CALLER: Address = address!("00000000000000000000000000000000000ca11e");

sol! {
    interface IFuzzHarness {
        function chainCompressT2(uint256[2] input, uint256 n) external pure returns (uint256[] memory);
        function chainCompressUncheckedT2(uint256[2] input, uint256 n) external pure returns (uint256[] memory);
        function chainPermT2(uint256[2] state, uint256 n) external pure returns (uint256[] memory);
        function chainPermUncheckedT2(uint256[2] state, uint256 n) external pure returns (uint256[] memory);
        function chainCompressT3(uint256[3] input, uint256 n) external pure returns (uint256[] memory);
        function chainCompressUncheckedT3(uint256[3] input, uint256 n) external pure returns (uint256[] memory);
        function chainPermT3(uint256[3] state, uint256 n) external pure returns (uint256[] memory);
        function chainPermUncheckedT3(uint256[3] state, uint256 n) external pure returns (uint256[] memory);
        function chainCompressT4(uint256[4] input, uint256 n) external pure returns (uint256[] memory);
        function chainCompressUncheckedT4(uint256[4] input, uint256 n) external pure returns (uint256[] memory);
        function chainPermT4(uint256[4] state, uint256 n) external pure returns (uint256[] memory);
        function chainPermUncheckedT4(uint256[4] state, uint256 n) external pure returns (uint256[] memory);
    }
}

#[derive(Parser)]
#[command(about = "Differential fuzzer: Solidity Poseidon2 vs taceo-poseidon2")]
struct Args {
    /// Master seed; random (and printed) if omitted.
    #[arg(long)]
    seed: Option<u64>,
    /// Number of independent hash chains per scenario.
    #[arg(long, default_value_t = 8)]
    chains: u64,
    /// Number of hashes per chain.
    #[arg(long, default_value_t = 1000)]
    length: u64,
    /// Repo root containing foundry.toml; defaults to the crate's parent directory.
    #[arg(long)]
    root: Option<PathBuf>,
}

#[derive(Clone, Copy, PartialEq)]
enum Op {
    Compress,
    Perm,
}

#[derive(Clone, Copy)]
struct Scenario {
    t: usize,
    op: Op,
    checked: bool,
}

const SCENARIOS: [Scenario; 12] = [
    Scenario { t: 2, op: Op::Compress, checked: true },
    Scenario { t: 2, op: Op::Compress, checked: false },
    Scenario { t: 2, op: Op::Perm, checked: true },
    Scenario { t: 2, op: Op::Perm, checked: false },
    Scenario { t: 3, op: Op::Compress, checked: true },
    Scenario { t: 3, op: Op::Compress, checked: false },
    Scenario { t: 3, op: Op::Perm, checked: true },
    Scenario { t: 3, op: Op::Perm, checked: false },
    Scenario { t: 4, op: Op::Compress, checked: true },
    Scenario { t: 4, op: Op::Compress, checked: false },
    Scenario { t: 4, op: Op::Perm, checked: true },
    Scenario { t: 4, op: Op::Perm, checked: false },
];

impl Scenario {
    fn name(&self) -> &'static str {
        match (self.t, self.op, self.checked) {
            (2, Op::Compress, true) => "compressT2",
            (2, Op::Compress, false) => "compressUncheckedT2",
            (2, Op::Perm, true) => "permT2",
            (2, Op::Perm, false) => "permUncheckedT2",
            (3, Op::Compress, true) => "compressT3",
            (3, Op::Compress, false) => "compressUncheckedT3",
            (3, Op::Perm, true) => "permT3",
            (3, Op::Perm, false) => "permUncheckedT3",
            (4, Op::Compress, true) => "compressT4",
            (4, Op::Compress, false) => "compressUncheckedT4",
            (4, Op::Perm, true) => "permT4",
            (4, Op::Perm, false) => "permUncheckedT4",
            _ => unreachable!(),
        }
    }

    fn elems_per_step(&self) -> usize {
        match self.op {
            Op::Compress => 1,
            Op::Perm => self.t,
        }
    }

    fn calldata(&self, input: &[U256], n: U256) -> Vec<u8> {
        use IFuzzHarness as H;
        match (self.t, self.op, self.checked) {
            (2, Op::Compress, true) => H::chainCompressT2Call { input: [input[0], input[1]], n }.abi_encode(),
            (2, Op::Compress, false) => {
                H::chainCompressUncheckedT2Call { input: [input[0], input[1]], n }.abi_encode()
            }
            (2, Op::Perm, true) => H::chainPermT2Call { state: [input[0], input[1]], n }.abi_encode(),
            (2, Op::Perm, false) => H::chainPermUncheckedT2Call { state: [input[0], input[1]], n }.abi_encode(),
            (3, Op::Compress, true) => {
                H::chainCompressT3Call { input: [input[0], input[1], input[2]], n }.abi_encode()
            }
            (3, Op::Compress, false) => {
                H::chainCompressUncheckedT3Call { input: [input[0], input[1], input[2]], n }.abi_encode()
            }
            (3, Op::Perm, true) => H::chainPermT3Call { state: [input[0], input[1], input[2]], n }.abi_encode(),
            (3, Op::Perm, false) => {
                H::chainPermUncheckedT3Call { state: [input[0], input[1], input[2]], n }.abi_encode()
            }
            (4, Op::Compress, true) => {
                H::chainCompressT4Call { input: [input[0], input[1], input[2], input[3]], n }.abi_encode()
            }
            (4, Op::Compress, false) => {
                H::chainCompressUncheckedT4Call { input: [input[0], input[1], input[2], input[3]], n }.abi_encode()
            }
            (4, Op::Perm, true) => {
                H::chainPermT4Call { state: [input[0], input[1], input[2], input[3]], n }.abi_encode()
            }
            (4, Op::Perm, false) => {
                H::chainPermUncheckedT4Call { state: [input[0], input[1], input[2], input[3]], n }.abi_encode()
            }
            _ => unreachable!(),
        }
    }

    /// Rust reference chain; same chaining rules as the harness.
    fn expected(&self, input: &[Fr], n: usize) -> Vec<U256> {
        let mut outs = Vec::with_capacity(n * self.elems_per_step());
        match (self.t, self.op) {
            (2, Op::Compress) => {
                let mut st = [input[0], input[1]];
                for _ in 0..n {
                    let out = compress_t2(st);
                    outs.push(fr_to_u256(out));
                    st = [out, out];
                }
            }
            (2, Op::Perm) => {
                let mut st = [input[0], input[1]];
                for _ in 0..n {
                    st = taceo_poseidon2::bn254::t2::permutation(&st);
                    outs.extend(st.iter().map(|&f| fr_to_u256(f)));
                }
            }
            (3, Op::Compress) => {
                let mut st = [input[0], input[1], input[2]];
                for _ in 0..n {
                    let out = compress_t3(st);
                    outs.push(fr_to_u256(out));
                    st = [out, out, out];
                }
            }
            (3, Op::Perm) => {
                let mut st = [input[0], input[1], input[2]];
                for _ in 0..n {
                    st = taceo_poseidon2::bn254::t3::permutation(&st);
                    outs.extend(st.iter().map(|&f| fr_to_u256(f)));
                }
            }
            (4, Op::Compress) => {
                let mut st = [input[0], input[1], input[2], input[3]];
                for _ in 0..n {
                    let out = compress_t4(st);
                    outs.push(fr_to_u256(out));
                    st = [out, out, out, out];
                }
            }
            (4, Op::Perm) => {
                let mut st = [input[0], input[1], input[2], input[3]];
                for _ in 0..n {
                    st = taceo_poseidon2::bn254::t4::permutation(&st);
                    outs.extend(st.iter().map(|&f| fr_to_u256(f)));
                }
            }
            _ => unreachable!(),
        }
        outs
    }
}

/// Mirrors `Poseidon2T2_BN254._compress`.
fn compress_t2(inputs: [Fr; 2]) -> Fr {
    let state = taceo_poseidon2::bn254::t2::permutation(&[inputs[0], inputs[1]]);
    state[0] + inputs[0]
}

/// Mirrors `Poseidon2T3_BN254._compress`.
fn compress_t3(inputs: [Fr; 3]) -> Fr {
    let state = taceo_poseidon2::bn254::t3::permutation(&[inputs[0], inputs[1], inputs[2]]);
    state[0] + inputs[0]
}

/// Mirrors `Poseidon2T4_BN254._compress`.
fn compress_t4(inputs: [Fr; 4]) -> Fr {
    let state = taceo_poseidon2::bn254::t4::permutation(&[inputs[0], inputs[1], inputs[2], inputs[3]]);
    state[0] + inputs[0]
}

fn u256_to_fr(x: U256) -> Fr {
    Fr::from_be_bytes_mod_order(&x.to_be_bytes::<32>())
}

fn fr_to_u256(f: Fr) -> U256 {
    U256::from_be_slice(&f.into_bigint().to_bytes_be())
}

fn chain_rng(seed: u64, scenario_idx: usize, chain: u64) -> ChaCha12Rng {
    let mut s = [0u8; 32];
    s[..8].copy_from_slice(&seed.to_le_bytes());
    s[8..16].copy_from_slice(&(scenario_idx as u64).to_le_bytes());
    s[16..24].copy_from_slice(&chain.to_le_bytes());
    ChaCha12Rng::from_seed(s)
}

/// A uniform-ish field element, already reduced below the BN254 scalar prime so the
/// checked and unchecked Solidity variants see identical inputs.
fn rand_fe(rng: &mut impl RngCore) -> U256 {
    let mut b = [0u8; 32];
    rng.fill_bytes(&mut b);
    U256::from_be_bytes(b) % PRIME
}

#[derive(serde::Deserialize)]
struct Artifact {
    #[serde(rename = "deployedBytecode")]
    deployed_bytecode: DeployedBytecode,
}

#[derive(serde::Deserialize)]
struct DeployedBytecode {
    object: String,
    #[serde(rename = "linkReferences", default)]
    link_references: BTreeMap<String, BTreeMap<String, Vec<LinkRef>>>,
}

#[derive(serde::Deserialize)]
struct LinkRef {
    start: usize,
    length: usize,
}

fn forge_build(root: &Path) -> Result<()> {
    let status = Command::new("forge")
        .args(["build", "fuzzy_tests/contracts/FuzzHarness.sol"])
        .current_dir(root)
        .status()
        .context("failed to run `forge build` (is foundry installed?)")?;
    ensure!(status.success(), "forge build failed");
    Ok(())
}

fn read_artifact(root: &Path, rel: &str) -> Result<Artifact> {
    let path = root.join(rel);
    let data = std::fs::read(&path).with_context(|| format!("reading artifact {}", path.display()))?;
    serde_json::from_slice(&data).with_context(|| format!("parsing artifact {}", path.display()))
}

/// Runtime bytecode of a library; must have no link references of its own.
fn library_code(root: &Path, rel: &str) -> Result<Vec<u8>> {
    let art = read_artifact(root, rel)?;
    ensure!(art.deployed_bytecode.link_references.is_empty(), "{rel}: unexpected link references");
    Ok(hex::decode(&art.deployed_bytecode.object)?)
}

/// Harness runtime bytecode with the library link placeholders patched to our
/// fixed in-EVM library addresses.
fn linked_harness_code(root: &Path) -> Result<Vec<u8>> {
    let art = read_artifact(root, "out/FuzzHarness.sol/FuzzHarness.json")?;
    let mut hexstr = art.deployed_bytecode.object.into_bytes();
    ensure!(hexstr.starts_with(b"0x"), "bytecode object missing 0x prefix");
    for (file, contracts) in &art.deployed_bytecode.link_references {
        for (name, refs) in contracts {
            let addr = match (file.as_str(), name.as_str()) {
                ("src/Poseidon2T2_BN254.sol", "Poseidon2T2_BN254") => LIB_T2,
                ("src/Poseidon2T3_BN254.sol", "Poseidon2T3_BN254") => LIB_T3,
                ("src/Poseidon2T4_BN254.sol", "Poseidon2T4_BN254") => LIB_T4,
                _ => bail!("unknown link reference {file}:{name}"),
            };
            let addr_hex = hex::encode(addr.as_slice());
            for r in refs {
                ensure!(r.length == 20, "unexpected link reference length {}", r.length);
                let lo = 2 + 2 * r.start;
                ensure!(hexstr.len() >= lo + 40, "link reference out of bounds");
                hexstr[lo..lo + 40].copy_from_slice(addr_hex.as_bytes());
            }
        }
    }
    let s = std::str::from_utf8(&hexstr)?;
    ensure!(!s.contains("__$"), "unresolved link placeholders remain in harness bytecode");
    Ok(hex::decode(s)?)
}

fn build_db(root: &Path) -> Result<CacheDB<EmptyDB>> {
    let t2 = library_code(root, "out/Poseidon2T2_BN254.sol/Poseidon2T2_BN254.json")?;
    let t3 = library_code(root, "out/Poseidon2T3_BN254.sol/Poseidon2T3_BN254.json")?;
    let t4 = library_code(root, "out/Poseidon2T4_BN254.sol/Poseidon2T4_BN254.json")?;
    let harness = linked_harness_code(root)?;
    let mut db = CacheDB::new(EmptyDB::default());
    for (addr, code) in [(LIB_T2, t2), (LIB_T3, t3), (LIB_T4, t4), (HARNESS, harness)] {
        db.insert_account_info(addr, AccountInfo::from_bytecode(Bytecode::new_raw(code.into())));
    }
    Ok(db)
}

fn run_call(db: &CacheDB<EmptyDB>, calldata: Vec<u8>) -> Result<Vec<u8>> {
    let mut evm = Context::mainnet()
        .with_db(db.clone())
        // The default (Osaka) spec caps tx gas at 16.7M (EIP-7825), far too low for long chains.
        .modify_cfg_chained(|cfg| cfg.tx_gas_limit_cap = Some(u64::MAX))
        .build_mainnet();
    let tx = TxEnv::builder()
        .caller(CALLER)
        .kind(TxKind::Call(HARNESS))
        .data(calldata.into())
        .gas_limit(1 << 50)
        .build_fill();
    let result = evm.transact(tx).map_err(|e| anyhow!("EVM error: {e:?}"))?.result;
    match result {
        ExecutionResult::Success { output: Output::Call(bytes), .. } => Ok(bytes.to_vec()),
        ExecutionResult::Success { .. } => bail!("unexpected create output"),
        ExecutionResult::Revert { output, .. } => bail!("call reverted: 0x{}", hex::encode(&output)),
        ExecutionResult::Halt { reason, .. } => bail!("call halted: {reason:?}"),
    }
}

fn run_chain(db: &CacheDB<EmptyDB>, scenario_idx: usize, chain: u64, seed: u64, length: u64) -> Result<()> {
    let sc = SCENARIOS[scenario_idx];
    let mut rng = chain_rng(seed, scenario_idx, chain);
    let input: Vec<U256> = (0..sc.t).map(|_| rand_fe(&mut rng)).collect();

    let ret = run_call(db, sc.calldata(&input, U256::from(length)))?;
    let got = <Vec<U256>>::abi_decode(&ret).context("decoding harness return data")?;

    let input_fr: Vec<Fr> = input.iter().map(|&x| u256_to_fr(x)).collect();
    let expected = sc.expected(&input_fr, length as usize);
    ensure!(got.len() == expected.len(), "output length mismatch: solidity {} vs rust {}", got.len(), expected.len());

    for (i, (g, e)) in got.iter().zip(&expected).enumerate() {
        if g != e {
            let per = sc.elems_per_step();
            bail!(
                "MISMATCH at step {} (element {}):\n  solidity = {:#066x}\n  rust     = {:#066x}\n  initial input = {:?}",
                i / per,
                i % per,
                g,
                e,
                input
            );
        }
    }
    Ok(())
}

fn main() -> Result<()> {
    let args = Args::parse();
    let seed = args.seed.unwrap_or_else(|| rand::thread_rng().gen());
    let root = match args.root {
        Some(r) => r,
        None => PathBuf::from(env!("CARGO_MANIFEST_DIR"))
            .parent()
            .ok_or_else(|| anyhow!("cannot determine repo root"))?
            .to_path_buf(),
    };
    println!(
        "config: seed={seed} chains={} length={} (reproduce with: cargo run --release -- --seed {seed} --chains {} --length {})",
        args.chains, args.length, args.chains, args.length
    );

    forge_build(&root)?;
    let db = build_db(&root)?;

    let work: Vec<(usize, u64)> =
        (0..SCENARIOS.len()).flat_map(|s| (0..args.chains).map(move |c| (s, c))).collect();

    let start = Instant::now();
    let failures: Vec<String> = work
        .into_par_iter()
        .filter_map(|(scenario_idx, chain)| {
            run_chain(&db, scenario_idx, chain, seed, args.length)
                .err()
                .map(|e| format!("[{} chain {}] {:#}", SCENARIOS[scenario_idx].name(), chain, e))
        })
        .collect();
    let elapsed = start.elapsed();

    let total_hashes = SCENARIOS.len() as u64 * args.chains * args.length;
    println!(
        "compared {total_hashes} hashes ({} scenarios x {} chains x {} hashes) in {:.2}s ({:.0} hashes/s)",
        SCENARIOS.len(),
        args.chains,
        args.length,
        elapsed.as_secs_f64(),
        total_hashes as f64 / elapsed.as_secs_f64()
    );

    if failures.is_empty() {
        println!("all Solidity and Rust outputs match");
        Ok(())
    } else {
        for f in &failures {
            eprintln!("{f}");
        }
        bail!("{} of {} chains diverged", failures.len(), SCENARIOS.len() as u64 * args.chains);
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn dec(s: &str) -> Fr {
        u256_to_fr(U256::from_str_radix(s, 10).unwrap())
    }

    // Vectors lifted from test/Poseidon2T2_BN254.t.sol and test/Poseidon2T3_BN254.t.sol,
    // anchoring the Rust reference mirror (incl. the compress feed-forward) to the
    // same KATs the Solidity libraries are tested against.
    #[test]
    fn reference_matches_solidity_kats() {
        let out = taceo_poseidon2::bn254::t2::permutation(&[Fr::from(0u64), Fr::from(1u64)]);
        assert_eq!(
            fr_to_u256(out[0]),
            uint!(0x1d01e56f49579cec72319e145f06f6177f6c5253206e78c2689781452a31878b_U256)
        );
        assert_eq!(
            fr_to_u256(out[1]),
            uint!(0x0d189ec589c41b8cffa88cfc523618a055abe8192c70f75aa72fc514560f6c61_U256)
        );

        let out = taceo_poseidon2::bn254::t3::permutation(&[Fr::from(0u64), Fr::from(1u64), Fr::from(2u64)]);
        assert_eq!(
            fr_to_u256(out[0]),
            uint!(0x0bb61d24daca55eebcb1929a82650f328134334da98ea4f847f760054f4a3033_U256)
        );

        let got = compress_t2([
            dec("20457494674368011577698787033167541464070895955057742021881406527394550967066"),
            dec("21444671219328533920402987889514525745813105369108346788316711824094480574542"),
        ]);
        assert_eq!(got, dec("2832391002711650597078084662530627544976903336819888740235684339967297026936"));

        let got = compress_t3([
            dec("898806166821139162552132088403958488384503106165081617184346559456501738999"),
            dec("5965168078856614482694323653344381108309427800607037671123008596071823952253"),
            dec("276435419372390923140774542356582007830246927446975692596430793358221695016"),
        ]);
        assert_eq!(got, dec("1113727409077897104878085522198678951849017209223827130117214728715352275349"));

        let out = taceo_poseidon2::bn254::t4::permutation(&[
            Fr::from(0u64),
            Fr::from(1u64),
            Fr::from(2u64),
            Fr::from(3u64),
        ]);
        assert_eq!(
            fr_to_u256(out[0]),
            uint!(0x01bd538c2ee014ed5141b29e9ae240bf8db3fe5b9a38629a9647cf8d76c01737_U256)
        );

        let got = compress_t4([
            dec("984638434826781072326755424132850106087537134535547037215571762992188258715"),
            dec("3437631445512178874044956757555414135117642720286593411444040537437963552166"),
            dec("2632313501648279494893764902570957563092298872877493247174692944294802639041"),
            dec("16778519398826163995565032500397037357824449594581267746327139608253580742520"),
        ]);
        assert_eq!(got, dec("13965228124958503975421203951945842220982129932391833857581914997066488337370"));
    }
}

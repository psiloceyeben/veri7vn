# veri7vn in Oracle7 release 3.2

[veri7vn](https://github.com/emberian/veri7vn) is ember arlynx's re-implementation of Oracle7's specialists as kernels written
and proved in Isabelle/HOL, exported to Standard ML and compiled with MLton. It is released under CC0. This branch of the fork
holds what Oracle7 release 3.2 used to build, measure and ship the kernels. Nothing in `src/` was changed.

## What release 3.2 does with the kernels

The kernels ship in the release under `specialists/_proved/` (static Linux x86-64 binaries, `SHA256SUMS`, `PROVED.json`,
`NOTICE`). Release fold w551 uses them as a cross-check:

- when one of Oracle7's specialists answers and its kernel gives the same answer, the reply is unchanged, its path gains
  `>proved:<session>`, and it names the theorems the kernel's answer rests on;
- when the kernel gives a different answer, the reply is withheld;
- when there is no kernel for that specialist, or the kernel declines, or the machine is not Linux x86-64, nothing changes.

## How the kernels were built (`oracle7/`)

- `build_all_box5.sh`: one `isabelle build` over every family session (Isabelle2026-RC1 on Linux; the proofs are checked
  during the build), then each family's own `build.sh` to export the generated SML and compile it. 18 of 20 families built;
  `chemistry` and `anatomyagri` stop in MLton on a type the compiler cannot generalise in their recognizer cache (their proofs
  are unaffected).
- `static_box5.sh`: the same `.mlb` files linked statically, so the binaries need no particular glibc or libgmp.
- `make_proved_json.py`: the map from Oracle7 specialist id to kernel binary, with the source commit and checksums.

## How they were measured

- `parity_box5.sh`: every built kernel over the held-out exams of the Oracle7 specialists it stands in for (6,444
  questions), scored by each specialist's own scorer with this repository's parity harness. Held-out exams are read, not spent.
- `alone_box5.sh`: the released Python specialists alone over the same questions.
- `agree_box5.py`: item by item. The kernels and the specialists gave the same answer value on every question both answered,
  apart from display rounding; there the kernels' exact rational arithmetic was the better (a Python float stores 0.675 as
  0.67499..., so the specialist printed 0.67 where the kernel printed 0.68).

Credit: the kernels, proofs and parity harness are ember arlynx's work. The build, measurement and release wiring in
`oracle7/` are Oracle7's (Prometheus7), also CC0.

s=17
e=22
cargo build --release
for ((i=s; i<=e; i++)); do
    TEST_NPOW=$i cargo test
done
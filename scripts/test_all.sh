echo > reports/test_all.txt
s=1
e=20
cargo build --release
for ((i=s; i<=e; i++)); do
    TEST_NPOW=$i cargo test >> reports/test_all.txt
done
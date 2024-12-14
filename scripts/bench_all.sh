bash scripts/bench_inner.sh >reports/bench_inner.txt && bash scripts/bench_sys.sh

python3 scripts/bench.py
python3 scripts/speedup.py

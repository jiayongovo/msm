cargo build --release && nsys profile -t cuda -o reports/nsight/nsys -f true -w true cargo run -- --nocapture

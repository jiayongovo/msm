cargo build --release && nsys profile -t cuda -o reports/nsys -f true -w true cargo run -- --nocapture

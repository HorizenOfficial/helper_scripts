# gen_stats.sh

A tool that generates transaction and unique address usage statistics for the last 90 days.

## Requirements
- A fully synchronized Horizen Mainchain node and RPC credentials.
- The following programms installed on the host: bc, jq, curl
- Storage space to download 90 days worth of block history

## Usage

RPC_USER="username" RPC_PASSWORD="password" RPC_HOST="127.0.0.1" RPC_PORT="8231" ./gen_stats.sh

## Output
- A CSV file with 'date;blocks;txs;unique_addresses' with one entry per day for the last 90 days in current working dir
- A summary file with averages for the last 90 Days in current working dir


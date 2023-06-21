#!/bin/bash

# calculate average unique active transparent addresses per day and total transactions (transparent, shielded, certificates) per day
# store data in a csv and print the averages

set -eEuo pipefail

# functions
fetch_block_batch () {
  local post_data
  for height in "$@"; do
    [ -s "${CACHE_FOLDER}/block_${height}.json" ] && continue
    post_data+='{"jsonrpc":"2.0","id":"'"${height}"'","method":"getblock","params":["'"${height}"'",2]}'
  done
  [ -z "${post_data:-}" ] && return 0
  post_data="$(jq -rcs '' <<< "${post_data}")"
  response="$(curl -sSfH 'content-type: application/json' -d "${post_data}" "http://${RPC_USER}:${RPC_PASSWORD}@${RPC_HOST}:${RPC_PORT}")" ||
    { printf "%s\n" "@" >> "${RETRIES_FILE}" && return 0; }
  while read -r block; do
    [ -n "$(jq 'select(has("code") or has("error") and ."error" != null)' <<< "${block}")" ] && { jq -rc '.id' <<< "${block}" >> "${RETRIES_FILE}"; continue; }
    jq -rc '.result' <<< "${block}" > "${CACHE_FOLDER}/block_$(jq -rc '.id' <<< "${block}").json"
  done < <( jq -rc '.[]' <<< "${response}" )
  return 0
}
export -f fetch_block_batch

generate_csv () {
  echo "Generating csv report."
  local start="${1}"
  local end="${2}"
  local header="date;blocks;txs;unique_addresses"
  local date date_prev tx_cert_json unique_addresses
  local blocks="0"
  local txs="0"
  local addresses=()
  echo "${header}" > "${CSV_FILE}"
  for (( i=start; i<=end; i++ )); do
    file="${CACHE_FOLDER}/block_${i}.json"
    date="$(date -d@"$(jq -rc '.time' "${file}")" +"%Y-%m-%d")"
    if [ -n "${date_prev:-}" ] && [ "${date}" != "${date_prev}" ]; then
      unique_addresses="$(tr ' ' '\n' <<< "${addresses[*]}" | sort -u | wc -l)"
      echo "${date};${blocks};${txs};${unique_addresses}" >> "${CSV_FILE}"
      blocks="0"
      txs="0"
      addresses=()
      echo "Wrote results for ${date}."
    fi
    blocks="$((blocks+1))"
    tx_cert_json="$(jq -rc '[.tx[]] + [.cert[]]' "${file}")"
    txs="$((txs+$(jq -rc 'length' <<< "${tx_cert_json}")))"
    mapfile -O "${#addresses[@]}" -t addresses < <(jq -rc '.[].vout[].scriptPubKey.addresses[0]' <<< "${tx_cert_json}")
    date_prev="${date}"
  done
  echo "Csv report generated."
}

generate_summary () {
  echo "Generating summary."
  local i=0
  local blocks=0
  local txs=0
  local unique_addresses=0
  local blocks_avg txs_avg unique_addresses_avg
  while read -r line; do
    i="$((i+1))"
    blocks="$((blocks+$(cut -d ';' -f 2 <<< "$line")))"
    txs="$((txs+$(cut -d ';' -f 3 <<< "$line")))"
    unique_addresses="$((unique_addresses+$(cut -d ';' -f 4 <<< "$line")))"
  done < <(tail -n+2 "${CSV_FILE}")
  blocks_avg="$(echo "scale=2; $blocks/$i" | bc)"
  txs_avg="$(echo "scale=2; $txs/$i" | bc)"
  unique_addresses_avg="$(echo "scale=2; $unique_addresses/$i" | bc)"
  echo -n > "${SUMMARY_FILE}"
  echo -e "Last $((MONTHS*30))d summary" | tee -a "${SUMMARY_FILE}"
  echo "Blocks per day: ${blocks_avg}" | tee -a "${SUMMARY_FILE}"
  echo "Transactions per day: ${txs_avg}" | tee -a "${SUMMARY_FILE}"
  echo "Unique active addresses per day: ${unique_addresses_avg}" | tee -a "${SUMMARY_FILE}"
}

have_prog () {
  command -v "${1}" &> /dev/null || { echo "Error: Command ${1} is required!"; exit 1; }
  return 0
}

is_set () {
  [ -z "${!1}" ] && { echo "Error: Variable ${1} is required!"; exit 1; }
  return 0
}

# check requirements
for cmd in bc jq curl; do
  have_prog "${cmd}"
done

# variables
explorer_url="https://explorer.horizen.io/api/"
RPC_USER="${RPC_USER:-}"
RPC_PASSWORD="${RPC_PASSWORD:-}"
RPC_HOST="${RPC_HOST:-}"
RPC_PORT="${RPC_PORT:-}"
for var in RPC_{USER,PASSWORD,HOST,PORT}; do
  is_set "${var}"
done

# timeframe to go back in months
MONTHS="3"
CACHE_FOLDER="./json_block_cache"
RETRIES_FILE="${CACHE_FOLDER}/retry_blocks.txt"
CSV_FILE="./horizen_address_activity"
SUMMARY_FILE="./horizen_address_activity_summary"
max_retries=5
# parallel RPC requests
workers="$(echo "x=($(nproc) * 0.75 / 1); if (x>=1) x else 1" | bc)"
# batch size of each RPC request
batch_size="1"
past_date="$(date --date="$((MONTHS * 30 + 1)) days ago" +"%Y-%m-%d")"
past_date_plus_one_day="$(date --date="$((MONTHS * 30 + 2)) days ago" +"%Y-%m-%d")"
today_epoch="$(date --date="$(date +"%Y-%m-%d")" +"%s")"
past_date_epoch="$(date --date="${past_date}" +"%s")"
# latest block - 10 block finality
# blocks from today to yesterday will be ignored in generation step
# workaround as blocks?blockDate= explorer endpoint is inaccurate
newest_block="$(($(curl -LsSf "${explorer_url}status" | jq -rc '.info.blocks') - 10))"
# past_date_plus_one_day is used to make sure all blocks of past_date are included
# blocks < past_date will be ignored in generation step
oldest_block="$(curl -LsSf "${explorer_url}blocks?blockDate=${past_date_plus_one_day}" | jq -rc '.blocks[-1].height')"
export MONTHS RPC_USER RPC_PASSWORD RPC_HOST RPC_PORT CACHE_FOLDER RETRIES_FILE CSV_FILE SUMMARY_FILE

# fetch blocks
mkdir -p "${CACHE_FOLDER}"
echo -n > "${RETRIES_FILE}"

echo "Fetching $((newest_block-oldest_block)) blocks."
seq "${oldest_block}" 1 "${newest_block}" | xargs -P"${workers}" -n"${batch_size}" bash -c 'set -eEuo pipefail; fetch_block_batch "$@"' argv0
# retry fetching failed blocks with batch_size=1, reduce workers by half after each retry
batch_size="1"
for (( i=0; i<max_retries; i++ )); do
  if [ -s "${RETRIES_FILE}" ]; then
    mv "${RETRIES_FILE}" "${RETRIES_FILE}.1"
    xargs -P"${workers}" -L"${batch_size}" -a "${RETRIES_FILE}.1" bash -c 'set -eEuo pipefail; fetch_block_batch "$@"' argv0
    workers="$(echo "x=(${workers} * 0.5 / 1); if (x>=1) x else 1" | bc)"
    rm "${RETRIES_FILE}.1"
  fi
done
[ -s "${RETRIES_FILE}" ] && { echo "Failed to fetch all blocks after ${max_retries} retries!"; exit 1; }
rm "${RETRIES_FILE}"

# set last block of yesterday as newest_block
for (( i=newest_block; i>=oldest_block; i-- )); do
  file="${CACHE_FOLDER}/block_${i}.json"
  timestamp="$(jq -rc '.time' "${file}")"
  if [ "${timestamp}" -lt "${today_epoch}" ]; then
    newest_block="${i}"
    break
  fi
done

# set first block of past_date as oldest_block
for (( i=oldest_block; i<=newest_block; i++ )); do
  file="${CACHE_FOLDER}/block_${i}.json"
  timestamp="$(jq -rc '.time' "${file}")"
  if [ "${timestamp}" -ge "${past_date_epoch}" ]; then
    oldest_block="${i}"
    break
  fi
done
echo "Blocks fetched."

generate_csv "${oldest_block}" "${newest_block}"

generate_summary

report_date="$(tail -n1 "${CSV_FILE}" | cut -d ';' -f1)"
mv "${CSV_FILE}" "${CSV_FILE}_${report_date}.csv"
mv "${SUMMARY_FILE}" "${SUMMARY_FILE}_${report_date}.txt"

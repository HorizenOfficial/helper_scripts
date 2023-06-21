# merge_to_address.py

Requirements: python3 and python-bitcoinrpc (install with `pip3 install -r requirements.txt`)

Alternatively Docker can be used with ./docker_build.sh, then execute the script with ./docker_run.sh -d DEST_ADDR ...

```shell
usage: merge_to_address.py [-h] -d DEST_ADDR [-f FROM_ADDR [FROM_ADDR ...]]
                           [--min-conf [MIN_CONF]] -u RPC_USER -p RPC_PASS -r
                           RPC_URL [-t [RPC_TIMEOUT]] [-l [LIMIT_VIN]]
                           [--debug]

optional arguments:
  -h, --help            show this help message and exit
  -f FROM_ADDR [FROM_ADDR ...], --fromaddr FROM_ADDR [FROM_ADDR ...]
                        ZEN addresses to send from, space separated e.g. "-f
                        addr1 addr2"
  --min-conf [MIN_CONF]
                        minimum number of confirmations to pass to listunspent
                        (default 1)
  -t [RPC_TIMEOUT], --rpc-timeout [RPC_TIMEOUT]
                        timeout for RPC requests in seconds (default 300)
  -l [LIMIT_VIN], --limit-vin [LIMIT_VIN]
                        utxo inputs per transaction (default 300, max 600)
  --debug               print debug messages

required arguments:
  -d DEST_ADDR, --destinationaddr DEST_ADDR
                        ZEN address to send to
  -u RPC_USER, --rpc-user RPC_USER
                        zend RPC username
  -p RPC_PASS, --rpc-password RPC_PASS
                        zend RPC password
  -r RPC_URL, --rpc-url RPC_URL
                        zend RPC interface to connect to, e.g.
                        "http://127.0.0.1:8231"
```

Example output:
```shell
$ python3 merge_to_address.py -d zto4YEJgg4dvbkGebcDiY2E2EYrcB1Qj5ws -f zta3WgVaAKS7kVReNUdhaBgW9FqVCrk5PcY -u user -p password -r http://127.0.0.1:18231
#
#Commands for address: zta3WgVaAKS7kVReNUdhaBgW9FqVCrk5PcY
#Transaction 1:
OPID=$(zen-cli z_sendmany "zta3WgVaAKS7kVReNUdhaBgW9FqVCrk5PcY" '[{"address": "zto4YEJgg4dvbkGebcDiY2E2EYrcB1Qj5ws", "amount": 0.11708846}]' 1 0.0001); sleep 5 && zen-cli z_getoperationstatus '["'$OPID'"]'; echo -e "\n\nPlease verify that the output contains \"status\": \"success\".\n\nIf this is not the case, please run the python script again and retry with the same address or a different address.\n" && read -p "Press enter to continue."
#Transaction 2:
OPID=$(zen-cli z_sendmany "zta3WgVaAKS7kVReNUdhaBgW9FqVCrk5PcY" '[{"address": "zto4YEJgg4dvbkGebcDiY2E2EYrcB1Qj5ws", "amount": 0.13708757}]' 1 0.0001); sleep 5 && zen-cli z_getoperationstatus '["'$OPID'"]'; echo -e "\n\nPlease verify that the output contains \"status\": \"success\".\n\nIf this is not the case, please run the python script again and retry with the same address or a different address.\n" && read -p "Press enter to continue."
#Transaction 3:
OPID=$(zen-cli z_sendmany "zta3WgVaAKS7kVReNUdhaBgW9FqVCrk5PcY" '[{"address": "zto4YEJgg4dvbkGebcDiY2E2EYrcB1Qj5ws", "amount": 0.15574512}]' 1 0.0001); sleep 5 && zen-cli z_getoperationstatus '["'$OPID'"]'; echo -e "\n\nPlease verify that the output contains \"status\": \"success\".\n\nIf this is not the case, please run the python script again and retry with the same address or a different address.\n" && read -p "Press enter to continue."
#Transaction 4:
OPID=$(zen-cli z_sendmany "zta3WgVaAKS7kVReNUdhaBgW9FqVCrk5PcY" '[{"address": "zto4YEJgg4dvbkGebcDiY2E2EYrcB1Qj5ws", "amount": 0.17505940}]' 1 0.0001); sleep 5 && zen-cli z_getoperationstatus '["'$OPID'"]'; echo -e "\n\nPlease verify that the output contains \"status\": \"success\".\n\nIf this is not the case, please run the python script again and retry with the same address or a different address.\n" && read -p "Press enter to continue."
#Transaction 5:
OPID=$(zen-cli z_sendmany "zta3WgVaAKS7kVReNUdhaBgW9FqVCrk5PcY" '[{"address": "zto4YEJgg4dvbkGebcDiY2E2EYrcB1Qj5ws", "amount": 0.19644559}]' 1 0.0001); sleep 5 && zen-cli z_getoperationstatus '["'$OPID'"]'; echo -e "\n\nPlease verify that the output contains \"status\": \"success\".\n\nIf this is not the case, please run the python script again and retry with the same address or a different address.\n" && read -p "Press enter to continue."
#Transaction 6:
OPID=$(zen-cli z_sendmany "zta3WgVaAKS7kVReNUdhaBgW9FqVCrk5PcY" '[{"address": "zto4YEJgg4dvbkGebcDiY2E2EYrcB1Qj5ws", "amount": 0.21691195}]' 1 0.0001); sleep 5 && zen-cli z_getoperationstatus '["'$OPID'"]'; echo -e "\n\nPlease verify that the output contains \"status\": \"success\".\n\nIf this is not the case, please run the python script again and retry with the same address or a different address.\n" && read -p "Press enter to continue."
#Transaction 7:
OPID=$(zen-cli z_sendmany "zta3WgVaAKS7kVReNUdhaBgW9FqVCrk5PcY" '[{"address": "zto4YEJgg4dvbkGebcDiY2E2EYrcB1Qj5ws", "amount": 0.23715688}]' 1 0.0001); sleep 5 && zen-cli z_getoperationstatus '["'$OPID'"]'; echo -e "\n\nPlease verify that the output contains \"status\": \"success\".\n\nIf this is not the case, please run the python script again and retry with the same address or a different address.\n" && read -p "Press enter to continue."
#Transaction 8:
OPID=$(zen-cli z_sendmany "zta3WgVaAKS7kVReNUdhaBgW9FqVCrk5PcY" '[{"address": "zto4YEJgg4dvbkGebcDiY2E2EYrcB1Qj5ws", "amount": 0.25660608}]' 1 0.0001); sleep 5 && zen-cli z_getoperationstatus '["'$OPID'"]'; echo -e "\n\nPlease verify that the output contains \"status\": \"success\".\n\nIf this is not the case, please run the python script again and retry with the same address or a different address.\n" && read -p "Press enter to continue."
#Transaction 9:
OPID=$(zen-cli z_sendmany "zta3WgVaAKS7kVReNUdhaBgW9FqVCrk5PcY" '[{"address": "zto4YEJgg4dvbkGebcDiY2E2EYrcB1Qj5ws", "amount": 0.27687864}]' 1 0.0001); sleep 5 && zen-cli z_getoperationstatus '["'$OPID'"]'; echo -e "\n\nPlease verify that the output contains \"status\": \"success\".\n\nIf this is not the case, please run the python script again and retry with the same address or a different address.\n" && read -p "Press enter to continue."
#Transaction 10:
OPID=$(zen-cli z_sendmany "zta3WgVaAKS7kVReNUdhaBgW9FqVCrk5PcY" '[{"address": "zto4YEJgg4dvbkGebcDiY2E2EYrcB1Qj5ws", "amount": 0.17557649}]' 1 0.0001); sleep 5 && zen-cli z_getoperationstatus '["'$OPID'"]'; echo -e "\n\nPlease verify that the output contains \"status\": \"success\".\n\nIf this is not the case, please run the python script again and retry with the same address or a different address.\n" && read -p "Press enter to continue."
```

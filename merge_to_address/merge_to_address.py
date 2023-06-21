#!/usr/bin/env python3
from bitcoinrpc.authproxy import AuthServiceProxy, JSONRPCException
import logging
from decimal import *
from collections import OrderedDict
import argparse

getcontext().prec = 42
FEE = Decimal("0.0001")
DUST_THRESHOLD = Decimal("0.00000066")
MAX_CONF = 9999999

def is_spendable(utxo):
    if utxo["generated"] == False and utxo["spendable"] == True:
        return True
    return False

def filter_unspendable(all_unspent):
    return [x for x in all_unspent if is_spendable(x)]

def group_by_address(spendable_utxo):
    result = OrderedDict()
    for utxo in spendable_utxo:
        address = utxo["address"]
        if address in result.keys():
            result[address].append(utxo)
        else:
            result.update({ address: [utxo] })
    return result

def main():
    parser = argparse.ArgumentParser()
    requiredNamed = parser.add_argument_group("required arguments")
    requiredNamed.add_argument("-d", "--destinationaddr", dest="dest_addr", type=str,
                        required=True, help="ZEN address to send to")
    parser.add_argument("-f", "--fromaddr", dest="from_addr", nargs="+", default=[],
                        required=False, help="ZEN addresses to send from, space separated e.g. \"-f addr1 addr2\"")
    parser.add_argument("--min-conf", dest="min_conf", nargs="?", type=int, default=1, const=1,
                        required=False, help="minimum number of confirmations to pass to listunspent (default 1)")
    requiredNamed.add_argument("-u", "--rpc-user", dest="rpc_user", type=str,
                        required=True, help="zend RPC username")
    requiredNamed.add_argument("-p", "--rpc-password", dest="rpc_pass", type=str,
                        required=True, help="zend RPC password")
    requiredNamed.add_argument("-r", "--rpc-url", dest="rpc_url", type=str,
                        required=True, help="zend RPC interface to connect to, e.g. \"http://127.0.0.1:8231\"")
    parser.add_argument("-t", "--rpc-timeout", dest="rpc_timeout", nargs="?", type=int, default=300, const=300,
                        required=False, help="timeout for RPC requests in seconds (default 300)")
    parser.add_argument("-l", "--limit-vin", dest="limit_vin", nargs="?", type=int, default=300, const=300,
                        required=False, help="utxo inputs per transaction (default 300, max 600)")
    parser.add_argument("--debug", dest="debug", action="store_true",
                        required=False, help="print debug messages")

    args = parser.parse_args()
    DEST_ADDR = args.dest_addr
    FROM_ADDR = args.from_addr
    MIN_CONF = args.min_conf
    RPC_URL = args.rpc_url
    creds = ""
    if args.rpc_user:
        creds = args.rpc_user
        if args.rpc_pass:
            creds +=  ":" + args.rpc_pass
        creds += "@"
    if creds:
        RPC_URL = RPC_URL.split("/", 2)[0] + "//"  + creds + RPC_URL.split("/", 2)[2]
    RPC_TIMEOUT = args.rpc_timeout
    LIMIT_VIN = min(args.limit_vin, 600)
    DEBUG = args.debug

    if DEBUG:
        logging.basicConfig()
        logging.getLogger("BitcoinRPC").setLevel(logging.DEBUG)
        print("DEST_ADDR: %s, FROM_ADDR: %s, MIN_CONF: %d, RPC_URL: %s, RPC_TIMEOUT: %d, LIMIT_VIN: %d"
              % (DEST_ADDR, FROM_ADDR, MIN_CONF, RPC_URL, RPC_TIMEOUT, LIMIT_VIN))

    rpc_connection = AuthServiceProxy(RPC_URL, timeout=RPC_TIMEOUT)
    all_unspent = rpc_connection.listunspent(MIN_CONF, MAX_CONF, FROM_ADDR)
    spendable_utxo = filter_unspendable(all_unspent)
    # sort by amount, low to high
    spendable_utxo_sorted = sorted(spendable_utxo, key = lambda i: i["amount"])
    utxo_by_address = group_by_address(spendable_utxo_sorted)

    commands = OrderedDict()
    for address, utxos in utxo_by_address.items():
        n = LIMIT_VIN
        # split into chunks of LIMIT_VIN size
        chunks = [utxos[i * n:(i + 1) * n] for i in range((len(utxos) + n - 1) // n )]
        for chunk in chunks:
            amount = Decimal("0")
            for utxo in chunk:
                amount += utxo["amount"]
            warning = ""
            if amount - FEE < DUST_THRESHOLD or amount - FEE < FEE:
                warning = "#Error: Transaction output below dust threshold or smaller than fee"
            command = (warning + "OPID=$(zen-cli z_sendmany \"" + address  + "\" '[{\"address\": \"" + DEST_ADDR + "\", \"amount\": " +
                       str(amount - FEE) + "}]' " + str(MIN_CONF) + " " + str(FEE) + "); sleep 5 && zen-cli z_getoperationstatus '[\"'" +
                       "$OPID'\"]'; echo -e \"\\n\\nPlease verify that the output contains \\\"status\\\": \\\"success\\\".\\n\\nIf this is not the case," +
                       " please run the python script again and retry with the same address or a different address.\\n\" && read -p " +
                       "\"Press enter to continue.\"")
            if address in commands.keys():
                commands[address].append(command)
            else:
                commands.update({ address: [command] })

    for address, cmds in commands.items():
        print("#")
        print("#Commands for address: " + address)
        for i in range(len(cmds)):
            print("#Transaction " + str(i+1) + ":")
            print(cmds[i])

if __name__ == '__main__':
    main()


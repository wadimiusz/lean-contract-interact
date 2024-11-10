import json
from argparse import ArgumentParser
import getpass
from web3 import Web3


def main():
    parser = ArgumentParser()
    parser.add_argument("--infura-project-id", "-i", required=True)
    parser.add_argument("--contract-address", "-c", required=True)
    parser.add_argument("--ABI-file", "-a", required=True)
    parser.add_argument("--function-name", "-fn", required=True, help="Name of the function, "
                                                                      "e.g. declareBounty, requireBountry etc.")
    parser.add_argument("--function-args", "-fa", required=False, default=None,
                        help="A json list with function positional arguments."
                             "If not specified, function will be called without positional arguments.")
    parser.add_argument("--function-kwargs", "-fk", required=False, default=None,
                        help="A json dictionary with function keyword arguments."
                             "If not specified, function will be called without keyword arguments.")
    parser.add_argument("--value", "-v", type=float, default=None,
                        help="If you call a payable function, specify this argument to pass this much Ether "
                             "(i.e. 0.01 means 0.01 Ether). Ignore this value for functions that are not payable.")
    args = parser.parse_args()

    with open(args.ABI_file) as f:
        contract_ABI = json.load(f)

    if args.function_args is None:
        function_args = dict()
    else:
        function_args = json.loads(args.function_args)

    if args.function_kwargs is None:
        function_kwargs = dict()
    else:
        function_kwargs = json.loads(args.function_kwargs)

    private_key = getpass.getpass(prompt='Enter your private key: ')
    web3 = Web3(Web3.HTTPProvider(f'https://sepolia.infura.io/v3/{args.infura_project_id}'))
    assert web3.is_connected()

    contract = web3.eth.contract(address=args.contract_address, abi=contract_ABI)
    account = web3.eth.account.from_key(private_key)

    transaction_kwargs = {
        'nonce': web3.eth.get_transaction_count(account.address),
        'gasPrice': web3.eth.gas_price,
        'from': account.address,
    }

    if args.value is not None:
        transaction_kwargs["value"] = web3.to_wei(args.value, 'ether')

    function = getattr(contract.functions, args.function_name)
    transaction = function(*function_args, **function_kwargs).build_transaction(transaction_kwargs)
    signed_transaction = account.sign_transaction(transaction)
    transaction_hash = web3.eth.send_raw_transaction(signed_transaction.raw_transaction)
    print(f"Transaction hash: {transaction_hash.hex()}. "
          f"You can check its status at https://sepolia.etherscan.io/tx/0x{transaction_hash.hex()}")


if __name__ == '__main__':
    main()

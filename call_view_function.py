import json
from argparse import ArgumentParser
import getpass
from web3 import Web3


def main():
    parser = ArgumentParser()
    parser.add_argument("--metamask-developer-key", "-i", required=True)
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

    web3 = Web3(Web3.HTTPProvider(f'https://sepolia.infura.io/v3/{args.metamask_developer_key}'))
    assert web3.is_connected()

    contract = web3.eth.contract(address=args.contract_address, abi=contract_ABI)

    function = getattr(contract.functions, args.function_name)
    result = function(*function_args, **function_kwargs).call()
    print(f"Output: {result}")

if __name__ == '__main__':
    main()

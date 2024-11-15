TheoremMarketplace.sol is a smart contract whose purpose is to enable people to declare and collect bounties on theorems in Lean.
My version of it is deployed at `0xAFb8B0f654cC497FDD7901956fE37C7f927ecfDF` in Sepolia. 
(It's not currently on the mainnet, though I plan to move there soon.)

This repository contains the source code and the ABI of the contract, and a couple of scripts for interacting with said contract, i.e. declaring a bounty on a theorem, requesting the bounty if you think you have a valid Lean proof, checking for a given theorem if an active bounty exists for it, etc.

I do realize that not many Lean enthusiasts have messed around with smart contracts. So I tried to hide away the pain of interacting with blockchain into the scripts, and to make their use simple for people who are comfortable with Python. Please don't hesitate to reach out with anything unclear, and with suggestions as to how to make the interaction with the contract easier. 

Also, please don't hesitate to reach out if you find any vulnerability. For now I've defended against reentrancy attacks by using the checks-effects-interactions pattern and by setting up a reentrancy guard, but I probably missed something.

# Installation

Just create a venv, enter it, and `pip install` the requirements. 

```commandline
python3 -m venv env
source env/bin/activate
python3 -m pip install -r requirements.txt
```

# Preparations

You will need an Metamask Developer account to interact with the smart contract. (It allows you to interact with blockchain without setting up your own nodes.) 

So if you don't have an account yet, go to https://developer.metamask.io/register and sign up.
Then go to https://developer.metamask.io and copy an API key. It will be required by the scripts.

You will also need an Ethereum account on Sepolia (play money; not on mainnet!). You can do this by installing MetaMask at https://metamask.io and setting up an account, or in any other way you prefer. The script will require your private key. In Metamask, you can get it from the "Account details" button.

The scripts don't store your private key or send it anywhere, they just use it to locally sign a transaction. You can read the script and make sure.

You need to get some play money (Sepolia Ether) to interact the smart contract. You can do this by:
1. Pinging me on the Lean Zulip so that I wire you some.
2. Or going to any Sepolia faucets, for example here is a nice list: https://faucet.triangleplatform.com/ethereum/sepolia
For example:
- https://www.alchemy.com/faucets/ethereum-sepolia is convenient, but requires a free account.
- https://faucet.triangleplatform.com/ethereum/sepolia doesn't require accounts, but it only wires a little.

# Usage

For calling most smart contract functions (except "view functions" - I'll explain later), you will use the `call_transaction.py` script.
It will prompt you to enter your private key. The key will be stored into RAM, but not written or sent anywhere.

For depositing a bounty on a theorem, you need the `declareBounty` function, and for claiming a bounty, you'll need the `requestBounty` function.

## Depositing bounties

The `declareBounty` function requires one argument named `theorem`.
Here's an example:

```commandline
python3 call_transaction.py --metamask-developer-key <YOUR_INFURA_KEY> --contract-address 0xAFb8B0f654cC497FDD7901956fE37C7f927ecfDF --ABI-file ABI.json --function-name declareBounty --function-kwargs '{"theorem": "(a b : Nat) : a + b = b + a"}' --value 0.01
```

Replace the `theorem` in `--function-kwargs` with any theorem you like.
The `value` argument here means the size of the bounty. For example, 0.01 means 0.01 Ether. Adjust as necessary, but don't waste all your play money :)


## Claiming and collecting bounties

The `requestBounty` function requires two arguments: `theorem` and `proof`. It will use an offchain oracle to check if lean validates this proof or not.
You can call it like this:

```commandline
python3 call_transaction.py --metamask-developer-key <YOUR_INFURA_KEY> --contract-address 0xAFb8B0f654cC497FDD7901956fE37C7f927ecfDF --ABI-file ABI.json --function-name requestBounty --function-kwargs '{"theorem": "(a b : Nat) : a + b = b + a", "proof": "by induction a with | zero => rw [Nat.zero_add, Nat.add_zero] | succ a ih => rw [Nat.succ_add, ih, Nat.add_succ]"}'
```

If the offchain oracle confirms that the proof is valid, your account will receive all bounties declared on this theorem so far.

## Checking bounties

To check if there is an active bounty for a given theorem, we can use the contract's `theoremBounties` hashmap.
It does not change the state of the network, so we don't need an account or any fees to run it. Thus, you can use the `call_view_function.py` for that. (In Solidity, view functions are functions that do not change the state of the network and can be triggered for free.)

Here's how you would call it:

```commandline
python3 call_view_function.py --metamask-developer-key <YOUR_INFURA_KEY> --contract-address 0xAFb8B0f654cC497FDD7901956fE37C7f927ecfDF --ABI-file ABI.json --function-name theoremBounties --function-args '["(a b : Nat) : a + b = b + a"]'
```

(Replace the actual theorem with whatever you like)


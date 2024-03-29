# XAP - Cross-Chain Accounts Protocol
![Test](https://github.com/kamescg/delegatable-sol/actions/workflows/test.yml/badge.svg)
[![MIT license](https://img.shields.io/badge/License-MIT-blue.svg)](http://perso.crans.org/besson/LICENSE.html)

## What is XAP?

XAP is an immutable domain name registry designed to simplify cross-chain communication by providing a single human-readable address that works across all compatible blockchains. For example, Uniswap's UniversalRouter has different addresses on different blockchains, making it difficult to remember and use. However, with XAP, you can use a simple, human-readable name that refers to the UniversalRouter on every chain it's deployed to, such as uniswap-ur.xap.eth.

One of the key advantages of XAP is its immutability. XAP names are permanent and unchanging, making them an ideal substitute for addresses in many situations. Additionally, unlike ENS, which uses namehashes, XAP names use human-readable bytes as token ids. As a result, short XAP names can be stored on-chain using significantly fewer bytes than a full address. For example, you could register 'uniur' as a short name for the Uniswap UniversalRouter. This would allow any smart contract to reference the Uniswap contract by its XAP name and retrieve the full address only when necessary.

XAP names never expire! Once a name is registered, it becomes the property of the owner who can register new addresses under new chain IDs, but cannot modify previously registered addresses. To maintain simplicity in the registry, XAP names are not represented as NFTs.

## How is XAP different than ENS?

XAP is it's own separate registry from ENS with several differences. One key difference is that XAP is immutable by default, while ENS is mutable. XAP uses human-readable names as ids instead of namehashes, which enables names to be stored on-chain based on the length of the name in bytes. In contrast, ENS uses namehashes, which are always a fixed length of 32 bytes, making it more difficult to store short names on-chain. XAP leverages ENS to ensure that every XAP account is a subname of 'xap.eth', e.g., 'nifty.xap.eth'.


## XAPRegistry

The XAP registry is the central contract that forms the core of the XAP protocol. All XAP lookups query the registry. The registry maintains a list of names, with each name associated with an owner, account data, and a mapping of chain ids to addresses and address data. Once registered with a chain id, these mapped addresses become immutable and cannot be changed. Because XAP addresses are always immutable, it is also possible to cache addresses without any loss of security or functionality.

At the heart of the XAP registry is the mapping of names to records, wherein each record has a mapping of chain ids to addresses:
```
    struct Record {

        uint256 owner;
        // A mapping of chain ids to addresses and data (stored as a single uint256). 
        mapping(uint256 chainId => uint256 addressAndData) addresses;

    }

    /**
     * A mapping of names to records.
     */
    mapping(bytes32 name => Record record) records;
```

This contract implements the following functionality:

- The owner of a name or an authorized caller can register a name with any chain id.
- The owner of a name or an authorized caller can transfer ownership to another address.
- The owner of a name or an authorized caller can change the "account data" value (a uint96 value associated with every account).
- The registered addresses and address data of a chain id associated with a name are immutable and cannot be modified by anyone.

## XAPRegistrar

The XAPRegistrar is a trusted controller of the XAPRegistry that is authorized to register new XAP names. This contract provides the following functionality:

- The owner of the registrar can set the pricing for registering names, which may include free tiers, and prevent names from being registered if desired.
- The ownership of XAP names are fully trustless and cannot be changed by the owner of the registrar or anyone else other than the owner or an approved address. The resolved addresses associated with a name are also immutable and cannot be modified after they are set by anyone.
- Users can register new XAP names by paying the amount specified by the pricing data.
To prevent frontrunning attacks, a commit/reveal process is used, as follows:

A user commits to a hash which contains the name to be registered and a secret value.
1. After a minimum delay period and before the commitment expires, the user calls the register function with the name to be registered and the secret value from the commitment.
2. If a valid commitment is found and the other preconditions are met, the name is registered.
3. The minimum delay and expiry for commitments are in place to prevent miners or other users from front-running registrations.

## XAPResolver

The XAP resolver implements an ENS wildcard resolver that enables the resolution of XAP names as subnames of xap.eth. Using wildcard resolution (ENSIP-10), the XAP name 'firefly' is resolved to 'firefly.xap.eth'. ENS uses Coin Type to resolve names and XAP uses chain id, however using ENSIP-11 it is possible to convert ENS Coin Types of EVM compatible names to chain ids. 

## Developer guide

### How to set up

```
git clone https://github.com/nxt3d/xap
cd xap
git submodule update --init --recursive
```

### How to run tests

```
forge test
```

### How to use XAP names in smart contracts

```
//SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "xap/contracts/IXAPRegistry.sol";

contract ExampleContract {

    IXAPRegistry public xap;

    // XAP names can be stored with any length of bytes, e.g., Bytes10 for a 
    // maximum ten character name. The maximum number of bytes is 32.

    bytes10 public xapName;

    constructor(IXAPRegistry _xap) {
        xap = _xap;
    }

    function resolveXAPAddress() public view returns (address) {
        return xap.resolveAddress(bytes32(xapName),1);
    }

    function setXAPName(bytes10 _name) public {
        xapName = _name;
    }
}
```
### Features and Limitations

One important feature of XAP is its ability to provide resolved addresses for a single name on each EVM compatible chain using the chain ID. This is particularly significant for multisig wallets that may have different addresses on various EVM chains. However, currently, popular clients like ethers.js and Metamask do not support ENSIP-11, which enables EVM compatible chain address resolution, such as mywallet.xap.eth. As a result, it is necessary to use the XAP registry directly to resolve any addresses other than those on the mainnet Ethereum, such as Layer 2s. Once ENSIP-11 gains more widespread support, alternative EVM chains can be used directly via clients such as Ethers.js and Metamask.

### Security and Audits

Please note that the XAP protocol is currently in development, and our team is working diligently to ensure its security. We recommend that you avoid using the smart contracts in a production environment until a security audit has been completed.

### Contributions

XAP is an open source project, and we welcome contributions, including raising issues on GitHub. For direct communication, please DM @nxt3d on Twitter. To contribute code, please fork the repository, create a feature branch (features/$BRANCH_NAME) or a bug fix branch (fix/$BRANCH_NAME), and submit a pull request against the branch. We appreciate your interest in contributing to the development of XAP!

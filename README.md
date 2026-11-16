# Bitcoin-MoneyMoney
Fetches amount and value of privately held Bitcoin address via blockexplorer and returns it as a security.
This can be also be used to track your cold storage.

Originally developed by Dr. Johannes Jacubeit. (https://github.com/Jacubeit/Bitcoin-MoneyMoney)
As it was no longer actively maintained I took the liberty to fork it and maintain it further.

![MoneyMoney screenshot with Bitcoin Balance](screens/bitcoin-balance.png)

## Extension Setup

You can get a signed version of this extension from

* my [GitHub releases page](https://github.com/UdoBretz/Bitcoin-MoneyMoney/releases), or
* the [MoneyMoney Extensions](https://moneymoney-app.com/extensions/) page

Once downloaded, move `Bitcoin.lua` to your MoneyMoney Extensions folder.

**Note:** This extension requires MoneyMoney **Version 2.2.19** or newer.

## MoneyMoney Setup

Add a new account (type "Bitcoin").

**Use your Bitcoin addresses and/or extended public keys comma separated as user name**
`1KuWLoZuoJgz3N6sLoAwGth9XGm8YuFTGt, zpub6rFR7y4Q2AijBEqTUquhVz398htDFrtymD9xYYfG1m4wAcvPhXNfE3EfH1r1ADqtfSdVCToUG868RvUUkgDKf31mGDtKsAYz2oz2AGutZYs` (example)

### Extended public keys (xpub / ypub / zpub)

Instead of listing every single address you can enter the extended public key of your wallet. The balance of all addresses derived from it (receive and change) is shown as one position.

| Prefix | Address type | Derivation |
|--------|--------------|------------|
| `xpub` | Legacy (`1...`) | BIP44 |
| `ypub` | Nested SegWit (`3...`) | BIP49 |
| `zpub` | Native SegWit (`bc1q...`) | BIP84 |

Output descriptors without commas are supported as well, e.g. `tr(xpub...)` for Taproot or `wpkh(xpub...)` if your wallet exports native SegWit keys with an `xpub` prefix.

**Privacy note:** Balances for extended public keys are fetched from Trezor's public Blockbook servers (`btc1.trezor.io` ... `btc5.trezor.io`). An extended public key reveals all addresses of your wallet to the server operator. It cannot be used to spend your coins.

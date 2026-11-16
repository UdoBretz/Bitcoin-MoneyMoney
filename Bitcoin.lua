-- Inofficial Bitcoin Extension for MoneyMoney
-- Fetches Bitcoin quantity for addresses via api.blockcypher.com API
-- Fetches Bitcoin quantity for extended public keys (xpub/ypub/zpub) and
-- output descriptors via Trezor's public Blockbook API
-- Fetches Bitcoin price in EUR via blockchain.info API
-- Returns cryptoassets as securities
--
-- Username: Bitcoin addresses and/or extended public keys, comma separated

-- MIT License

-- Copyright (c) 2017 Jacubeit

-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:

-- The above copyright notice and this permission notice shall be included in all
-- copies or substantial portions of the Software.

-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
-- SOFTWARE.


WebBanking{
  version = 0.6,
  description = "Include your Bitcoins as cryptoportfolio in MoneyMoney by providing Bitcoin addresses and/or extended public keys (xpub, ypub, zpub) as username (comma separated).",
  services= { "Bitcoin" }
}

local bitcoinAddress
local connection = Connection()
local currency = "EUR" -- fixme: make dynamic if MM enables input field

-- Public Blockbook instances run by Trezor. They are tried in order, because
-- single instances are occasionally unavailable (HTTP 503).
local blockbookHosts = {
  "btc1.trezor.io",
  "btc2.trezor.io",
  "btc3.trezor.io",
  "btc4.trezor.io",
  "btc5.trezor.io"
}

function SupportsBank (protocol, bankCode)
  return protocol == ProtocolWebBanking and bankCode == "Bitcoin"
end

function InitializeSession (protocol, bankCode, username, username2, password, username3)
  bitcoinAddress = username:gsub("%s+", "")
end

function ListAccounts (knownAccounts)
  local account = {
    name = "Bitcoin",
    accountNumber = "Bitcoin",
    currency = currency,
    portfolio = true,
    type = "AccountTypePortfolio"
  }

  return {account}
end

function RefreshAccount (account, since)
  local s = {}
  BTCinEURprice = requestBitcoinPrice()

  for address in string.gmatch(bitcoinAddress, '([^,]+)') do
    local bitcoinQuantity, err
    if isExtendedPublicKey(address) then
      bitcoinQuantity, err = requestBitcoinQuantityForExtendedPublicKey(address)
      if err then
        return err
      end
    else
      bitcoinQuantity = requestBitcoinQuantityForBitcoinAddress(address)
    end

    s[#s+1] = {
      name = displayName(address),
      currency = nil,
      market = "blockchain.info",
      quantity = bitcoinQuantity,
      price = BTCinEURprice,
    }

    -- Add sleep for 1 second to avoid possible rate limitation of the API
    MM.sleep(1)
  end

  return {securities = s}
end

function EndSession ()
end


-- Query Functions
function requestBitcoinPrice()
  response = connection:request("GET", priceRequestUrl(), {})
  json = JSON(response)
  return json:dictionary()["EUR"]["last"]
end

function requestBitcoinQuantityForBitcoinAddress(bitcoinAddress)
  response = connection:request("GET", bitcoinRequestUrl(bitcoinAddress), {})

  json = JSON(response)
  satoshi = json:dictionary()["balance"]

  return convertSatoshiToBitcoin(satoshi)
end

-- Returns the confirmed balance of all addresses derived from an extended
-- public key (xpub = legacy, ypub = nested SegWit, zpub = native SegWit) or
-- an output descriptor such as tr(xpub...). Returns nil and an error message
-- if no Blockbook instance could answer.
function requestBitcoinQuantityForExtendedPublicKey(xpub)
  local lastError = "no Blockbook instance reachable"

  for _, host in ipairs(blockbookHosts) do
    local ok, response = pcall(function()
      return connection:request("GET", blockbookRequestUrl(host, xpub), nil, nil, {Accept = "application/json"})
    end)

    if ok and response then
      local parsed, data = pcall(function() return JSON(response):dictionary() end)

      if parsed and type(data) == "table" then
        if data["balance"] ~= nil then
          return convertSatoshiToBitcoin(tonumber(data["balance"]))
        elseif data["error"] ~= nil then
          -- The key itself was rejected (e.g. typo). Other hosts would say the same.
          return nil, "Extended public key " .. displayName(xpub) .. " rejected: " .. tostring(data["error"])
        end
      end
      lastError = host .. " returned an unexpected response"
    else
      lastError = host .. ": " .. tostring(response)
    end
  end

  return nil, "Could not fetch balance for " .. displayName(xpub) .. " (" .. lastError .. ")"
end


-- Helper Functions
function isExtendedPublicKey(entry)
  -- xpub/ypub/zpub (and multisig Ypub/Zpub) or an output descriptor like wpkh(...)
  return entry:match("^[xyzYZ]pub") ~= nil or entry:find("(", 1, true) ~= nil
end

function displayName(entry)
  if isExtendedPublicKey(entry) and #entry > 20 then
    return entry:sub(1, 10) .. "…" .. entry:sub(-6)
  end
  return entry
end

function convertSatoshiToBitcoin(satoshi)
  return satoshi / 100000000
end

function priceRequestUrl()
  return "https://blockchain.info/ticker"
end

function bitcoinRequestUrl(bitcoinAddress)
  return "https://api.blockcypher.com/v1/btc/main/addrs/" .. bitcoinAddress
end

function blockbookRequestUrl(host, xpub)
  return "https://" .. host .. "/api/v2/xpub/" .. MM.urlencode(xpub) .. "?details=basic"
end

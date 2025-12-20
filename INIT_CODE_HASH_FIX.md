# Perbaikan Init Code Hash Issue

## 📋 Ringkasan Masalah

**Problem**: `router.getAmountsOut()` mengembalikan `[0, 0]` karena init code hash yang salah di `UniswapV2Library.sol`

**Impact**:
- ❌ Quote/preview swap tidak berfungsi
- ❌ Frontend tidak bisa menampilkan expected output
- ✅ Swap masih berfungsi (core functionality OK)

**Severity**: 🟡 MEDIUM-HIGH

---

## 🔧 Solusi

### **Opsi 1: Deploy Custom Router dengan Fix (Recommended)**

#### **Langkah 1: Buat Custom UniswapV2Library**

Buat file baru: `src/libraries/UniswapV2LibraryFixed.sol`

```solidity
// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol';

library UniswapV2LibraryFixed {
    using SafeMath for uint;

    // ✅ FIX: Gunakan factory.getPair() instead of pairFor()
    function getReserves(address factory, address tokenA, address tokenB) 
        internal view returns (uint reserveA, uint reserveB) 
    {
        (address token0,) = sortTokens(tokenA, tokenB);
        
        // ✅ Query pair address dari factory (bukan hitung dengan CREATE2)
        address pair = IUniswapV2Factory(factory).getPair(tokenA, tokenB);
        require(pair != address(0), 'UniswapV2Library: PAIR_NOT_FOUND');
        
        (uint reserve0, uint reserve1,) = IUniswapV2Pair(pair).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    // ... copy fungsi lainnya dari UniswapV2Library.sol
}
```

#### **Langkah 2: Deploy Router Baru**

```bash
# Deploy router yang menggunakan UniswapV2LibraryFixed
forge script script/DeployRouterFixed.s.sol --broadcast --legacy
```

#### **Langkah 3: Update Frontend/Scripts**

Ganti router address dari yang lama ke yang baru.

---

### **Opsi 2: Workaround - Custom Quote Contract**

Deploy contract khusus untuk quote yang tidak pakai `pairFor()`:

```solidity
// src/QuoteHelper.sol
contract QuoteHelper {
    IUniswapV2Factory public factory;
    
    function getQuote(address tokenIn, address tokenOut, uint amountIn) 
        external view returns (uint amountOut) 
    {
        address pair = factory.getPair(tokenIn, tokenOut);
        require(pair != address(0), "No pair");
        
        (uint reserve0, uint reserve1,) = IUniswapV2Pair(pair).getReserves();
        address token0 = IUniswapV2Pair(pair).token0();
        
        (uint reserveIn, uint reserveOut) = tokenIn == token0 
            ? (reserve0, reserve1) 
            : (reserve1, reserve0);
        
        // Uniswap formula
        uint amountInWithFee = amountIn.mul(997);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }
}
```

---

### **Opsi 3: Frontend Workaround (Temporary)**

Gunakan script `direct-quote.sh` atau implement logic yang sama di frontend:

```javascript
// Frontend: Calculate quote manually
async function getQuote(tokenIn, tokenOut, amountIn) {
  // 1. Get pair address from factory
  const pair = await factory.getPair(tokenIn, tokenOut);
  
  // 2. Get reserves
  const { reserve0, reserve1 } = await pairContract.getReserves();
  const token0 = await pairContract.token0();
  
  // 3. Determine which reserve is which
  const [reserveIn, reserveOut] = tokenIn === token0 
    ? [reserve0, reserve1] 
    : [reserve1, reserve0];
  
  // 4. Calculate output
  const amountInWithFee = amountIn * 997;
  const numerator = amountInWithFee * reserveOut;
  const denominator = reserveIn * 1000 + amountInWithFee;
  const amountOut = numerator / denominator;
  
  return amountOut;
}
```

---

## 📊 Perbandingan Opsi

| Opsi | Effort | Gas Cost | Permanence | Recommended |
|------|--------|----------|------------|-------------|
| **1. Deploy Router Baru** | High | One-time | Permanent | ✅ Yes |
| **2. Quote Contract** | Medium | One-time | Permanent | ⚠️ OK |
| **3. Frontend Workaround** | Low | None | Temporary | ❌ No |

---

## 🎯 Rekomendasi

### **Short-term (Sekarang)**
✅ Gunakan `direct-quote.sh` untuk testing
✅ Implement quote logic di frontend/backend

### **Long-term (Production)**
✅ Deploy router baru dengan `UniswapV2LibraryFixed`
✅ Atau deploy `QuoteHelper` contract

---

## 📝 Checklist Implementasi

### **Untuk Opsi 1 (Router Baru):**
- [ ] Buat `UniswapV2LibraryFixed.sol`
- [ ] Buat deployment script
- [ ] Deploy ke testnet
- [ ] Test `getAmountsOut()`
- [ ] Update frontend/backend dengan router address baru
- [ ] Deploy ke mainnet

### **Untuk Opsi 2 (Quote Helper):**
- [ ] Buat `QuoteHelper.sol`
- [ ] Deploy ke testnet
- [ ] Test quote function
- [ ] Integrate ke frontend
- [ ] Deploy ke mainnet

---

## 🔍 Verification

Setelah fix, test dengan:

```bash
# Test getAmountsOut
cast call <ROUTER> \
  "getAmountsOut(uint256,address[])(uint256[])" \
  1000000000 \
  "[0x6EC7D79792D4D73eb711d36aB5b5f24014f18d05,0x96ABff3a2668B811371d7d763f06B3832CEdf38d]" \
  --rpc-url $MANTLE_TESTNET_RPC

# Expected: [1000000000, <expected_output>]
# NOT: [0, 0]
```

---

## 💡 Kesimpulan

**Masalah ini HARUS diperbaiki** sebelum production karena:
1. User experience sangat buruk tanpa quote
2. Slippage protection sulit diimplementasikan
3. Frontend tidak bisa menampilkan preview

**Solusi terbaik**: Deploy router baru dengan library yang fixed.

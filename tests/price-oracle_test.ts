import { Clarinet, Tx, Chain, Account, types } from 'https://deno.land/x/clarinet@v1.0.3/index.ts';
import { assertEquals } from 'https://deno.land/std@0.170.0/testing/asserts.ts';

Clarinet.test({
  name: "Price Oracle: Can register oracle",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    const block = chain.mineBlock([
      Tx.contractCall('price-oracle', 'register-oracle', [], deployer.address)
    ]);

    assertEquals(block.receipts.length, 1);
    assertEquals(block.height, 2);
    block.receipts[0].result.expectOk().expectBool(true);
  }
}),

Clarinet.test({
  name: "Price Oracle: Can update price for a symbol",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    const block = chain.mineBlock([
      Tx.contractCall('price-oracle', 'register-oracle', [], deployer.address),
      Tx.contractCall('price-oracle', 'update-price', 
        [
          types.utf8('STX'), 
          types.uint(100), 
          types.uint(6), 
          types.utf8('Binance')
        ], 
        deployer.address
      )
    ]);

    assertEquals(block.receipts.length, 2);
    block.receipts[1].result.expectOk().expectBool(true);
  }
}),

Clarinet.test({
  name: "Price Oracle: Cannot update price without oracle registration",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const alice = accounts.get('wallet_1')!;
    const block = chain.mineBlock([
      Tx.contractCall('price-oracle', 'update-price', 
        [
          types.utf8('STX'), 
          types.uint(100), 
          types.uint(6), 
          types.utf8('Binance')
        ], 
        alice.address
      )
    ]);

    assertEquals(block.receipts.length, 1);
    block.receipts[0].result.expectErr().expectUint(100);
  }
})
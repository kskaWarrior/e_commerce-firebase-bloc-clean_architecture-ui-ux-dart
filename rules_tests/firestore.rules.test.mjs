// Firestore security-rules tests for multi-tenant isolation.
// Run with the emulator:
//   firebase emulators:exec --only firestore "npm --prefix rules_tests test"
import { readFileSync } from 'node:fs';
import {
  initializeTestEnvironment,
  assertSucceeds,
  assertFails,
} from '@firebase/rules-unit-testing';
import { doc, getDoc, getDocs, setDoc, updateDoc, deleteDoc, collection } from 'firebase/firestore';

let env;

const STORE_A = 'store-a';
const STORE_B = 'store-b';

// Auth contexts
const shopper = () => env.authenticatedContext('shopper-1');
const shopper2 = () => env.authenticatedContext('shopper-2');
const ownerA = () =>
  env.authenticatedContext('owner-a', { role: 'owner', storeId: STORE_A });
const superAdmin = () => env.authenticatedContext('super-1', { role: 'super' });
const anon = () => env.unauthenticatedContext();

const path = {
  store: (s) => `stores/${s}`,
  product: (s, id) => `stores/${s}/products/${id}`,
  category: (s, id) => `stores/${s}/categories/${id}`,
  user: (s, uid) => `stores/${s}/users/${uid}`,
  favorite: (s, id) => `stores/${s}/favorites/${id}`,
  sale: (s, id) => `stores/${s}/sales/${id}`,
  saleProduct: (s, id) => `stores/${s}/sales_products/${id}`,
  storePrivate: (s, id) => `stores/${s}/private/${id}`,
};

before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-rules-test',
    firestore: { rules: readFileSync('../firestore.rules', 'utf8') },
  });
});

after(async () => {
  await env.cleanup();
});

beforeEach(async () => {
  await env.clearFirestore();
  await env.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    await setDoc(doc(db, path.store(STORE_A)), {
      name: 'Store A',
      ownerUid: 'owner-a',
      status: 'active',
      branding: { primaryColorHex: 'FF000000' },
    });
    await setDoc(doc(db, path.store(STORE_B)), {
      name: 'Store B',
      ownerUid: 'owner-b',
      status: 'active',
      branding: {},
    });
    await setDoc(doc(db, path.product(STORE_A, 'p1')), {
      id: 'p1',
      title: 'Shirt',
      price: 10,
    });
    await setDoc(doc(db, path.product(STORE_B, 'p9')), {
      id: 'p9',
      title: 'Other tenant product',
      price: 99,
    });
    await setDoc(doc(db, path.sale(STORE_A, 's1')), {
      id: 's1',
      userId: 'shopper-1',
      storeId: STORE_A,
      status: 'pending',
      totalPrice: 10,
    });
    await setDoc(doc(db, path.sale(STORE_A, 's2')), {
      id: 's2',
      userId: 'shopper-2',
      storeId: STORE_A,
      status: 'pending',
      totalPrice: 20,
    });
    await setDoc(doc(db, path.sale(STORE_B, 's9')), {
      id: 's9',
      userId: 'someone-else',
      storeId: STORE_B,
      status: 'pending',
      totalPrice: 30,
    });
    await setDoc(doc(db, path.favorite(STORE_A, 'f1')), {
      id: 'f1',
      userId: 'shopper-1',
      productId: 'p1',
    });
    // Payment secrets: written only by Cloud Functions (Admin SDK).
    await setDoc(doc(db, path.storePrivate(STORE_A, 'payment')), {
      mpAccessToken: 'APP_USR-secret',
      mpWebhookSecret: 'whsec',
    });
    // Legacy global collection (pre-migration) must be sealed.
    await setDoc(doc(db, 'products/legacy1'), { id: 'legacy1' });
  });
});

describe('store docs', () => {
  it('anyone can get a store doc (branding pre-login)', async () => {
    await assertSucceeds(getDoc(doc(anon().firestore(), path.store(STORE_A))));
  });

  it('only super can list stores', async () => {
    await assertFails(getDocs(collection(ownerA().firestore(), 'stores')));
    await assertSucceeds(getDocs(collection(superAdmin().firestore(), 'stores')));
  });

  it('owner can update only branding/name of own store', async () => {
    const db = ownerA().firestore();
    await assertSucceeds(
      updateDoc(doc(db, path.store(STORE_A)), { name: 'Renamed', branding: { x: 1 } }),
    );
    await assertFails(
      updateDoc(doc(db, path.store(STORE_A)), { ownerUid: 'owner-a-again' }),
    );
    await assertFails(updateDoc(doc(db, path.store(STORE_B)), { name: 'Hijack' }));
  });

  it('owner can update shipping config of own store only', async () => {
    const shipping = {
      pickupEnabled: true,
      freeShippingThreshold: 200,
      zones: [{ label: 'Capital', cepStart: '01000000', cepEnd: '05999999', fee: 15.9 }],
    };
    await assertSucceeds(
      updateDoc(doc(ownerA().firestore(), path.store(STORE_A)), { shipping }),
    );
    await assertFails(
      updateDoc(doc(ownerA().firestore(), path.store(STORE_B)), { shipping }),
    );
    await assertFails(
      updateDoc(doc(shopper().firestore(), path.store(STORE_A)), { shipping }),
    );
  });

  it('owner cannot sneak other fields alongside shipping', async () => {
    await assertFails(
      updateDoc(doc(ownerA().firestore(), path.store(STORE_A)), {
        shipping: { pickupEnabled: true },
        plan: 'premium',
      }),
    );
  });

  it('only super creates stores', async () => {
    await assertFails(
      setDoc(doc(ownerA().firestore(), path.store('new-store')), { name: 'X' }),
    );
    await assertSucceeds(
      setDoc(doc(superAdmin().firestore(), path.store('new-store')), { name: 'X' }),
    );
  });
});

describe('store private docs (payment secrets)', () => {
  it('nobody reads them from a client — not even owner or super', async () => {
    await assertFails(getDoc(doc(shopper().firestore(), path.storePrivate(STORE_A, 'payment'))));
    await assertFails(getDoc(doc(ownerA().firestore(), path.storePrivate(STORE_A, 'payment'))));
    await assertFails(getDoc(doc(superAdmin().firestore(), path.storePrivate(STORE_A, 'payment'))));
    await assertFails(getDoc(doc(anon().firestore(), path.storePrivate(STORE_A, 'payment'))));
  });

  it('nobody writes them from a client', async () => {
    const payload = { mpAccessToken: 'stolen' };
    await assertFails(
      setDoc(doc(shopper().firestore(), path.storePrivate(STORE_A, 'payment')), payload),
    );
    await assertFails(
      setDoc(doc(ownerA().firestore(), path.storePrivate(STORE_A, 'payment')), payload),
    );
    await assertFails(
      setDoc(doc(superAdmin().firestore(), path.storePrivate(STORE_A, 'payment')), payload),
    );
    await assertFails(
      deleteDoc(doc(ownerA().firestore(), path.storePrivate(STORE_A, 'payment'))),
    );
  });
});

describe('products & categories', () => {
  it('signed-in shopper reads products; anonymous cannot', async () => {
    await assertSucceeds(getDoc(doc(shopper().firestore(), path.product(STORE_A, 'p1'))));
    await assertFails(getDoc(doc(anon().firestore(), path.product(STORE_A, 'p1'))));
  });

  it('shopper cannot write products', async () => {
    await assertFails(
      setDoc(doc(shopper().firestore(), path.product(STORE_A, 'hack')), { id: 'hack' }),
    );
  });

  it('owner writes own store products only', async () => {
    await assertSucceeds(
      setDoc(doc(ownerA().firestore(), path.product(STORE_A, 'p2')), { id: 'p2' }),
    );
    await assertFails(
      setDoc(doc(ownerA().firestore(), path.product(STORE_B, 'p2')), { id: 'p2' }),
    );
    await assertFails(
      deleteDoc(doc(ownerA().firestore(), path.product(STORE_B, 'p9'))),
    );
  });

  it('super writes anywhere', async () => {
    await assertSucceeds(
      setDoc(doc(superAdmin().firestore(), path.product(STORE_B, 'p10')), { id: 'p10' }),
    );
  });
});

describe('per-store user profiles', () => {
  it('user reads/writes own profile; not others', async () => {
    const db = shopper().firestore();
    await assertSucceeds(
      setDoc(doc(db, path.user(STORE_A, 'shopper-1')), { name: 'Me' }),
    );
    await assertFails(
      setDoc(doc(db, path.user(STORE_A, 'shopper-2')), { name: 'Not me' }),
    );
    await assertFails(getDoc(doc(db, path.user(STORE_A, 'shopper-2'))));
  });

  it('owner reads profiles in own store only', async () => {
    await env.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), path.user(STORE_B, 'shopper-1')), { name: 'B profile' });
    });
    await assertSucceeds(getDoc(doc(ownerA().firestore(), path.user(STORE_A, 'shopper-1'))));
    await assertFails(getDoc(doc(ownerA().firestore(), path.user(STORE_B, 'shopper-1'))));
  });
});

describe('favorites', () => {
  it('shopper creates/deletes own favorites only', async () => {
    const db = shopper().firestore();
    await assertSucceeds(
      setDoc(doc(db, path.favorite(STORE_A, 'f2')), { id: 'f2', userId: 'shopper-1', productId: 'p1' }),
    );
    await assertFails(
      setDoc(doc(db, path.favorite(STORE_A, 'f3')), { id: 'f3', userId: 'shopper-2', productId: 'p1' }),
    );
    await assertSucceeds(deleteDoc(doc(db, path.favorite(STORE_A, 'f1'))));
  });

  it('shopper cannot read or delete another user\'s favorite', async () => {
    const db = shopper2().firestore();
    await assertFails(getDoc(doc(db, path.favorite(STORE_A, 'f1'))));
    await assertFails(deleteDoc(doc(db, path.favorite(STORE_A, 'f1'))));
  });
});

describe('sales (orders)', () => {
  it('shopper creates own pending sale pinned to the store', async () => {
    const db = shopper().firestore();
    await assertSucceeds(
      setDoc(doc(db, path.sale(STORE_A, 's3')), {
        id: 's3', userId: 'shopper-1', storeId: STORE_A, status: 'pending', totalPrice: 5,
      }),
    );
  });

  it('shopper cannot create a sale as paid, for someone else, or mislabeled', async () => {
    const db = shopper().firestore();
    await assertFails(
      setDoc(doc(db, path.sale(STORE_A, 's4')), {
        id: 's4', userId: 'shopper-1', storeId: STORE_A, status: 'paid', totalPrice: 5,
      }),
    );
    await assertFails(
      setDoc(doc(db, path.sale(STORE_A, 's5')), {
        id: 's5', userId: 'shopper-2', storeId: STORE_A, status: 'pending', totalPrice: 5,
      }),
    );
    await assertFails(
      setDoc(doc(db, path.sale(STORE_A, 's6')), {
        id: 's6', userId: 'shopper-1', storeId: STORE_B, status: 'pending', totalPrice: 5,
      }),
    );
  });

  it('shopper reads own sales only; cannot flip status', async () => {
    const db = shopper().firestore();
    await assertSucceeds(getDoc(doc(db, path.sale(STORE_A, 's1'))));
    await assertFails(getDoc(doc(db, path.sale(STORE_A, 's2'))));
    await assertFails(updateDoc(doc(db, path.sale(STORE_A, 's1')), { status: 'paid' }));
  });

  it('sale create may carry checkout fields (address, deliveryMethod, null payment)', async () => {
    await assertSucceeds(
      setDoc(doc(shopper().firestore(), path.sale(STORE_A, 's7')), {
        id: 's7', userId: 'shopper-1', storeId: STORE_A, status: 'pending', totalPrice: 5,
        deliveryMethod: 'delivery',
        address: { cep: '01310100', street: 'Av. Paulista', city: 'Sao Paulo', state: 'SP' },
        payment: null,
      }),
    );
  });

  it('shopper cannot write a payment map onto a sale', async () => {
    await assertFails(
      updateDoc(doc(shopper().firestore(), path.sale(STORE_A, 's1')), {
        payment: { preferenceId: 'forged' },
      }),
    );
  });

  it('owner updates only the status field, only in own store, only to valid values', async () => {
    const db = ownerA().firestore();
    await assertSucceeds(updateDoc(doc(db, path.sale(STORE_A, 's1')), { status: 'paid' }));
    await assertFails(
      updateDoc(doc(db, path.sale(STORE_A, 's1')), { status: 'paid', totalPrice: 0 }),
    );
    await assertFails(updateDoc(doc(db, path.sale(STORE_A, 's1')), { status: 'bogus' }));
    await assertFails(updateDoc(doc(db, path.sale(STORE_B, 's9')), { status: 'paid' }));
  });

  it('owner reads own store sales; not other stores', async () => {
    await assertSucceeds(getDoc(doc(ownerA().firestore(), path.sale(STORE_A, 's2'))));
    await assertFails(getDoc(doc(ownerA().firestore(), path.sale(STORE_B, 's9'))));
  });

  it('only super deletes sales', async () => {
    await assertFails(deleteDoc(doc(ownerA().firestore(), path.sale(STORE_A, 's1'))));
    await assertSucceeds(deleteDoc(doc(superAdmin().firestore(), path.sale(STORE_A, 's1'))));
  });
});

describe('sales_products line items', () => {
  it('shopper creates own line items pinned to the store', async () => {
    const db = shopper().firestore();
    await assertSucceeds(
      setDoc(doc(db, path.saleProduct(STORE_A, 'sp1')), {
        id: 'sp1', userId: 'shopper-1', storeId: STORE_A, salesId: 's1',
      }),
    );
    await assertFails(
      setDoc(doc(db, path.saleProduct(STORE_A, 'sp2')), {
        id: 'sp2', userId: 'shopper-2', storeId: STORE_A, salesId: 's2',
      }),
    );
  });
});

describe('legacy global collections', () => {
  it('are sealed for everyone (except nothing)', async () => {
    await assertFails(getDoc(doc(shopper().firestore(), 'products/legacy1')));
    await assertFails(getDoc(doc(ownerA().firestore(), 'products/legacy1')));
    await assertFails(setDoc(doc(superAdmin().firestore(), 'products/legacy2'), { id: 'x' }));
  });
});

import 'package:flutter/widgets.dart';

/// Central string catalog for every app surface (shopper mobile, shopper
/// web storefront, admin dashboard).
///
/// Usage: `final s = S.of(context);` then `s.addToCart`. Resolution follows
/// the ambient `Localizations` locale, which the entrypoints drive from
/// [AppLocaleController]; bare test MaterialApps resolve to English.
///
/// When adding a key, add it to BOTH [AppStringsEn] and [AppStringsPtBr].
class S {
  S._();

  static AppStrings of(BuildContext context) {
    final locale = Localizations.maybeLocaleOf(context);
    return (locale?.languageCode.toLowerCase() == 'pt')
        ? const AppStringsPtBr()
        : const AppStringsEn();
  }
}

abstract class AppStrings {
  const AppStrings();

  // ---------------------------------------------------------------- common
  String get home;
  String get favorites;
  String get myOrders;
  String get myPurchases;
  String get myProfile;
  String get myFavorites;
  String get myCart;
  String get signOut;
  String get logout;
  String get cancel;
  String get delete;
  String get remove;
  String get refresh;
  String get save;
  String get language;
  String get confirmLogoutTitle;
  String get confirmLogoutBody;
  String get pleaseSignIn;
  String get returnToHome;
  String get goToFavorites;
  String get continueLabel;
  String get signedInUser;

  // ------------------------------------------------------------- statuses
  String statusLabel(String status);

  // ------------------------------------------------------------- shopping
  String get searchProductsHint;
  String get searchResults;
  String get categories;
  String get shopByCategory;
  String get shopByCategorySubtitle;
  String get topSelling;
  String get topSellingSubtitle;
  String get newIn;
  String get newInSubtitle;
  String get noProductsFound;
  String get noNewProductsFound;
  String get noCategoriesFound;
  String get noCategoriesYet;
  String heroWelcome(String appName);
  String get heroTitle;
  String get heroSubtitle;
  String get footerTagline;
  String allRightsReserved(int year, String appName);
  String resultsFor(String query);
  String productsFound(int count);
  String get nothingMatchedSearch;
  String productsInCategory(int count);
  String get noProductsInCategory;
  String get clearSearch;
  String get clearCategory;
  String get youMayAlsoLike;
  String get youMayAlsoLikeSubtitle;
  String get youMightAlsoLike;

  // ------------------------------------------------------ product details
  String get productDetails;
  String get description;
  String get sizes;
  String get size;
  String get colors;
  String get color;
  String get quantity;
  String get price;
  String get addToCart;
  String get goToCart;
  String get noSizesAvailable;
  String get noColorsAvailable;
  // Fullscreen image viewer (web zoom)
  String get viewLarger;
  String get zoomIn;
  String get zoomOut;
  String get resetZoom;
  String get closeViewer;
  String get previousImage;
  String get nextImage;
  String soldAndCode(int sold, String code);
  String salesCount(int count);
  String codeLabel(String code);
  String percentOff(num percent);
  String get pleaseSelectSize;
  String get pleaseSelectColor;
  String get pleaseSignInAddToCart;
  String get pleaseSignInFavorites;
  String get pleaseSignInAddFavorites;
  String get favoritesUnavailableNow;
  String addedToCart(int count);

  // ----------------------------------------------------------------- cart
  String itemsReadyForCheckout(int count);
  String get cartEmptyTitle;
  String get cartEmptyBody;
  String get continueShopping;
  String get signInToViewCart;
  String get orderSummary;
  String get subtotal;
  String get savings;
  String get freightNote;
  String get total;
  String get payment;
  String get paymentMethod;
  String get creditCard;
  String get debitCard;
  String get credit;
  String get debit;
  String get installments;
  String get installmentsNumber;
  String get cardholderName;
  String get cardNumber;
  String get expiryMmYy;
  String get cvv;
  String get demoCheckoutNote;
  String get confirmPurchase;
  String get confirmingPurchase;
  String get purchaseConfirmed;
  String get enterCardholderName;
  String get enterValidCardNumber;
  String get enterExpiryAsMmYy;
  String get cardExpired;
  String get enterValidCvv;
  String get signInToConfirmPurchase;
  String get unableToLoadProfile;
  String get productDetailsUnavailable;
  String get unableToOpenProduct;
  String itemMeta(String size, String color, String quantity, String price);
  String get draftItems;
  String itemsCount(int count);
  String savedAmount(String amount);
  String totalAmount(String amount);
  String get originalTotal;
  String get discountedTotal;
  String get totalSaved;
  String get cartSummary;
  String get unitPrice;
  String get unitDiscounted;
  String get discounted;

  // ------------------------------------------------------------ favorites
  String savedProducts(int count);
  String get favoritesEmptyHint;
  String get favoritesEmptyWebHint;
  String get signInToViewFavorites;
  String get couldNotLoadFavorites;
  String favoritesCount(int count);
  String get noFavoritesYet;

  // ------------------------------------------------------------ purchases
  String orderPlaced(String date);
  String ordersCount(int count);
  String get purchasesEmptySubtitle;
  String get noPurchasesYet;
  String get purchasesEmptyBody;
  String get signInToViewPurchases;
  String get couldNotLoadPurchases;
  String youSaved(String amount);
  String freightLabel(String amount);
  String totalLabel(String amount);

  // ----------------------------------------------------------------- auth
  String get signInWithYourEmail;
  String get pleaseEnterEmail;
  String get pleaseEnterValidEmail;
  String emailTemporarilyLocked(String remaining);
  String get dontHaveAccount;
  String get signUpExclamation;

  // ---------------------------------------------------------------- admin
  String get storeAdmin;
  String get manage;
  String get orders;
  String get products;
  String get settings;
  String get welcomeBack;
  String get signInToManageStore;
  String get email;
  String get password;
  String get signIn;
  String get accessRestrictedToOwners;
  String get selectStore;
  String get signedInAsPlatformOwner;
  String get storeIdLabel;
  String get storeIdHint;
  String adminOrdersSubtitle(int count);
  String get adminOrdersEmpty;
  String get adminProductsSubtitle;
  String adminProductsCount(int count);
  String get newProduct;
  String get adminProductsEmpty;
  String get deleteProduct;
  String deleteProductConfirm(String title);
  String get adminCategoriesSubtitle;
  String adminCategoriesCount(int count);
  String get newCategory;
  String get adminCategoriesEmpty;
  String get deleteCategory;
  String deleteCategoryConfirm(String title);
  String get settingsSubtitle;
  String get saveChanges;
  String get savingEllipsis;
  String get storeIdentity;
  String get storeIdentityBody;
  String get brandColors;
  String get brandColorsBody;
  String get storeName;
  String get appTitle;
  String get primaryColor;
  String get secondaryColor;
  String get backgroundColor;

  // -------------------------------------------------- web storefront chrome
  String get shopNow;
  String get allCategories;
  String get seeAll;
  String get footerShop;
  String get footerAccount;

  // ----------------------------------------------------- localization tail
  // Auth: sign-in password step
  String get signingIn;
  String get typeYourPassword;
  String get welcomeBackTo;
  String get signInButton;
  String get pleaseEnterPassword;
  String tooManyAttemptsLocked(String remaining);
  String attemptsLeftBeforeLock(int count);
  String emailLockedTryAgainIn(String remaining);
  String get signinSessionExpired;
  String get forgotYourPassword;
  String get clickHere;

  // Auth: forgot password
  String get forgotPassword;
  String get forgotPasswordSubtitle;
  String get pleaseConfirmEmailHere;
  String get resetPassword;
  String get pleaseEnterEmailShort;

  // Auth: sign-up flow
  String get signingUp;
  String get onlyTwoSteps;
  String get fillProfileBelow;
  String get name;
  String get phone;
  String get pleaseEnterName;
  String get pleaseEnterPhone;
  String get pleaseEnterPasswordPeriod;
  String get oneStepAway;
  String get whatGenderInterested;
  String get selectYourBirthDate;
  String get typeYourAddress;
  String get signUpButton;
  String get pleaseEnterAddress;
  String get mustBeAtLeastTwelve;

  // Profile
  String get tapToChangePhoto;
  String get registeredEmailLocked;
  String get newPasswordOptional;
  String get address;
  String get mostInterestedIn;
  String get birthDate;
  String get fillAllEditableFields;
  String get imageTooLarge;
  String get profileImageUpdated;

  // Home / product / cart / web shell
  String get hideCategory;
  String get categoryFallback;
  String get favoriteTooltip;
  String get favoritesUnavailableOnScreen;
  String get cartTooltip;
  String productFallback(String code);
  String get productLabel;
  String get account;

  // Purchases
  String get confirmedPurchasesHere;
  String ordersLabelCount(int count);
  String avgTicketLabel(String amount);
  String get purchaseSummary;
  String get recentPurchases;
  String orderNumber(String id);
  String get created;
  String itemCountLabel(int count);
  String get showMore;
  String get showLess;
  String get subtotalAfterDiscount;
  String get freight;
  String get installmentValue;
  String get productsDetails;
  String get noProductDetails;
  String get tapToViewDetails;
  String get lineTotal;
  String colorMeta(String name, String hex);
  String get totalSpent;
  String get averageTicket;

  // Favorites
  String get favoritesUnavailableTitle;
  String get favoritesFoundButUnavailable;
  String get noFavoriteProductsAvailable;
  String unavailableCount(int count);
  String get note;
  String favoritesCouldNotBeShown(int count);

  // Admin
  String get adminOrdersTagline;
  String get adminOrdersEmptyBody;
  String get colOrder;
  String get colDate;
  String get colCustomer;
  String get colItems;
  String get colStatus;
  String get changeStatus;
  String get editProduct;
  String get pleaseChooseCategory;
  String get title;
  String get titleRequired;
  String get enterValidPrice;
  String get discountedPriceOptional;
  String get gender;
  String get genderUnisex;
  String get genderMen;
  String get genderWomen;
  String get sizesHint;
  String get colorsHint;
  String get images;
  String get uploadImage;
  String get saveProduct;
  String get editCategory;
  String get saveCategory;
}

class AppStringsEn extends AppStrings {
  const AppStringsEn();

  @override
  String get home => 'Home';
  @override
  String get favorites => 'Favorites';
  @override
  String get myOrders => 'My Orders';
  @override
  String get myPurchases => 'My Purchases';
  @override
  String get myProfile => 'My Profile';
  @override
  String get myFavorites => 'My Favorites';
  @override
  String get myCart => 'My Cart';
  @override
  String get signOut => 'Sign out';
  @override
  String get logout => 'Logout';
  @override
  String get cancel => 'Cancel';
  @override
  String get delete => 'Delete';
  @override
  String get remove => 'Remove';
  @override
  String get refresh => 'Refresh';
  @override
  String get save => 'Save';
  @override
  String get language => 'Language';
  @override
  String get confirmLogoutTitle => 'Confirm logout';
  @override
  String get confirmLogoutBody =>
      'Are you sure you want to log out of your account?';
  @override
  String get pleaseSignIn => 'Please sign in';
  @override
  String get returnToHome => 'Return to home';
  @override
  String get goToFavorites => 'Go to favorites';
  @override
  String get continueLabel => 'Continue';
  @override
  String get signedInUser => 'Signed in user';

  @override
  String statusLabel(String status) {
    switch (status) {
      case 'paid':
        return 'PAID';
      case 'shipped':
        return 'SHIPPED';
      case 'delivered':
        return 'DELIVERED';
      case 'cancelled':
        return 'CANCELLED';
      default:
        return 'PENDING';
    }
  }

  @override
  String get searchProductsHint => 'Search products…';
  @override
  String get searchResults => 'Search results';
  @override
  String get categories => 'Categories';
  @override
  String get shopByCategory => 'Shop by category';
  @override
  String get shopByCategorySubtitle =>
      'Pick a category to browse its products';
  @override
  String get topSelling => 'Top Selling';
  @override
  String get topSellingSubtitle => 'What everyone is buying right now';
  @override
  String get newIn => 'New In';
  @override
  String get newInSubtitle => 'Fresh arrivals, straight to the shelf';
  @override
  String get noProductsFound => 'No products found';
  @override
  String get noNewProductsFound => 'No new products found';
  @override
  String get noCategoriesFound => 'No categories found';
  @override
  String get noCategoriesYet => 'No categories yet.';
  @override
  String heroWelcome(String appName) => 'Welcome to $appName';
  @override
  String get heroTitle => 'Shop the latest drops,\ncurated for you.';
  @override
  String get heroSubtitle =>
      'Discover top sellers and fresh arrivals — with favorites, carts and '
      'orders synced to your account.';
  @override
  String get footerTagline => 'Curated products, delivered with care.';
  @override
  String allRightsReserved(int year, String appName) =>
      '© $year $appName. All rights reserved.';
  @override
  String resultsFor(String query) => 'Results for "$query"';
  @override
  String productsFound(int count) => '$count product(s) found';
  @override
  String get nothingMatchedSearch =>
      'Nothing matched your search — try another term.';
  @override
  String productsInCategory(int count) =>
      '$count product(s) in this category';
  @override
  String get noProductsInCategory => 'No products in this category yet.';
  @override
  String get clearSearch => 'Clear search';
  @override
  String get clearCategory => 'Clear category';
  @override
  String get youMayAlsoLike => 'You may also like';
  @override
  String get youMayAlsoLikeSubtitle => 'More from the top sellers';
  @override
  String get youMightAlsoLike => 'You might also like these';

  @override
  String get productDetails => 'Product details';
  @override
  String get viewLarger => 'View larger';
  @override
  String get zoomIn => 'Zoom in';
  @override
  String get zoomOut => 'Zoom out';
  @override
  String get resetZoom => 'Reset zoom';
  @override
  String get closeViewer => 'Close';
  @override
  String get previousImage => 'Previous image';
  @override
  String get nextImage => 'Next image';
  @override
  String get description => 'Description';
  @override
  String get sizes => 'Sizes';
  @override
  String get size => 'Size';
  @override
  String get colors => 'Colors';
  @override
  String get color => 'Color';
  @override
  String get quantity => 'Quantity';
  @override
  String get price => 'Price';
  @override
  String get addToCart => 'Add to cart';
  @override
  String get goToCart => 'Go to cart';
  @override
  String get noSizesAvailable => 'No sizes available';
  @override
  String get noColorsAvailable => 'No colors available';
  @override
  String soldAndCode(int sold, String code) => '$sold sold · Code $code';
  @override
  String salesCount(int count) => 'Sales: $count';
  @override
  String codeLabel(String code) => 'Code: $code';
  @override
  String percentOff(num percent) => '$percent% OFF';
  @override
  String get pleaseSelectSize => 'Please select a size.';
  @override
  String get pleaseSelectColor => 'Please select a color.';
  @override
  String get pleaseSignInAddToCart =>
      'Please sign in to add products to cart.';
  @override
  String get pleaseSignInFavorites => 'Please sign in to manage favorites.';
  @override
  String get pleaseSignInAddFavorites => 'Please sign in to add favorites.';
  @override
  String get favoritesUnavailableNow =>
      'Favorites are unavailable right now.';
  @override
  String addedToCart(int count) =>
      'Added to cart — $count item(s) in your cart.';

  @override
  String itemsReadyForCheckout(int count) =>
      '$count item(s) ready for checkout';
  @override
  String get cartEmptyTitle => 'Your cart is empty';
  @override
  String get cartEmptyBody => 'Items you add to cart will appear here.';
  @override
  String get continueShopping => 'Continue shopping';
  @override
  String get signInToViewCart => 'Sign in to view and confirm your cart.';
  @override
  String get orderSummary => 'Order summary';
  @override
  String get subtotal => 'Subtotal';
  @override
  String get savings => 'Savings';
  @override
  String get freightNote => 'Freight is calculated at confirmation.';
  @override
  String get total => 'Total';
  @override
  String get payment => 'Payment';
  @override
  String get paymentMethod => 'Payment method';
  @override
  String get creditCard => 'Credit card';
  @override
  String get debitCard => 'Debit card';
  @override
  String get credit => 'Credit';
  @override
  String get debit => 'Debit';
  @override
  String get installments => 'Installments';
  @override
  String get installmentsNumber => 'Installments number';
  @override
  String get cardholderName => 'Cardholder name';
  @override
  String get cardNumber => 'Card number';
  @override
  String get expiryMmYy => 'Expiry (MM/YY)';
  @override
  String get cvv => 'CVV';
  @override
  String get demoCheckoutNote => 'Demo checkout — no real charge is made.';
  @override
  String get confirmPurchase => 'Confirm purchase';
  @override
  String get confirmingPurchase => 'Confirming purchase…';
  @override
  String get purchaseConfirmed => 'Purchase confirmed successfully!';
  @override
  String get enterCardholderName => 'Please enter the cardholder name.';
  @override
  String get enterValidCardNumber => 'Please enter a valid card number.';
  @override
  String get enterExpiryAsMmYy => 'Please enter the expiry date as MM/YY.';
  @override
  String get cardExpired => 'This card appears to be expired.';
  @override
  String get enterValidCvv => 'Please enter a valid CVV.';
  @override
  String get signInToConfirmPurchase =>
      'Please sign in to confirm your purchase.';
  @override
  String get unableToLoadProfile =>
      'Unable to load your profile data. Please try again.';
  @override
  String get productDetailsUnavailable =>
      'Product details are unavailable for this item.';
  @override
  String get unableToOpenProduct =>
      'Unable to open product details right now.';
  @override
  String itemMeta(String size, String color, String quantity, String price) =>
      'Size $size · Color $color · Qty $quantity · $price each';
  @override
  String get draftItems => 'Draft items';
  @override
  String itemsCount(int count) => 'Items: $count';
  @override
  String savedAmount(String amount) => 'Saved: $amount';
  @override
  String totalAmount(String amount) => 'Total: $amount';
  @override
  String get originalTotal => 'Original total';
  @override
  String get discountedTotal => 'Discounted total';
  @override
  String get totalSaved => 'Total saved';
  @override
  String get cartSummary => 'Cart summary';
  @override
  String get unitPrice => 'Unit price';
  @override
  String get unitDiscounted => 'Unit discounted';
  @override
  String get discounted => 'Discounted';

  @override
  String savedProducts(int count) => '$count saved product(s)';
  @override
  String get favoritesEmptyHint =>
      'Tap the heart icon in product lists to save favorites.';
  @override
  String get favoritesEmptyWebHint =>
      'No favorites yet — tap the heart on any product to save it.';
  @override
  String get signInToViewFavorites =>
      'Sign in to view your favorite products.';
  @override
  String get couldNotLoadFavorites => 'Could not load favorites';
  @override
  String favoritesCount(int count) => 'Favorites count: $count';
  @override
  String get noFavoritesYet => 'No favorites yet';

  @override
  String orderPlaced(String date) => 'Order placed $date';
  @override
  String ordersCount(int count) => '$count order(s)';
  @override
  String get purchasesEmptySubtitle => 'Orders you place will appear here';
  @override
  String get noPurchasesYet => 'No purchases yet';
  @override
  String get purchasesEmptyBody =>
      'When you confirm a purchase it will show up here.';
  @override
  String get signInToViewPurchases => 'Sign in to view your purchases.';
  @override
  String get couldNotLoadPurchases => 'Could not load purchases';
  @override
  String youSaved(String amount) => 'You saved $amount';
  @override
  String freightLabel(String amount) => 'Freight $amount';
  @override
  String totalLabel(String amount) => 'Total $amount';

  @override
  String get signInWithYourEmail => 'Sign in with your email';
  @override
  String get pleaseEnterEmail => 'Please enter your email.';
  @override
  String get pleaseEnterValidEmail => 'Please enter a valid email address.';
  @override
  String emailTemporarilyLocked(String remaining) =>
      'This email is temporarily locked. Try again in $remaining.';
  @override
  String get dontHaveAccount => "Don't have an account? ";
  @override
  String get signUpExclamation => 'Sign Up!';

  @override
  String get storeAdmin => 'Store Admin';
  @override
  String get manage => 'MANAGE';
  @override
  String get orders => 'Orders';
  @override
  String get products => 'Products';
  @override
  String get settings => 'Settings';
  @override
  String get welcomeBack => 'Welcome back';
  @override
  String get signInToManageStore => 'Sign in to manage your store';
  @override
  String get email => 'Email';
  @override
  String get password => 'Password';
  @override
  String get signIn => 'Sign in';
  @override
  String get accessRestrictedToOwners =>
      'Access restricted to store owners.';
  @override
  String get selectStore => 'Select a store';
  @override
  String get signedInAsPlatformOwner =>
      'You are signed in as platform owner.';
  @override
  String get storeIdLabel => 'Store ID';
  @override
  String get storeIdHint => 'e.g. buybuy';
  @override
  String adminOrdersSubtitle(int count) => '$count order(s) in your store';
  @override
  String get adminOrdersEmpty => 'No orders yet.';
  @override
  String get adminProductsSubtitle => "Manage your store's catalog";
  @override
  String adminProductsCount(int count) =>
      '$count product(s) in your catalog';
  @override
  String get newProduct => 'New product';
  @override
  String get adminProductsEmpty => 'No products yet — create the first one.';
  @override
  String get deleteProduct => 'Delete product';
  @override
  String deleteProductConfirm(String title) =>
      'Delete "$title"? This cannot be undone.';
  @override
  String get adminCategoriesSubtitle => 'Organize your catalog';
  @override
  String adminCategoriesCount(int count) =>
      '$count categor${count == 1 ? 'y' : 'ies'} in your catalog';
  @override
  String get newCategory => 'New category';
  @override
  String get adminCategoriesEmpty =>
      'No categories yet — create the first one.';
  @override
  String get deleteCategory => 'Delete category';
  @override
  String deleteCategoryConfirm(String title) =>
      'Delete "$title"? Products keep their categoryId.';
  @override
  String get settingsSubtitle => 'Store identity and brand colors';
  @override
  String get saveChanges => 'Save changes';
  @override
  String get savingEllipsis => 'Saving…';
  @override
  String get storeIdentity => 'Store identity';
  @override
  String get storeIdentityBody =>
      'Shown across the platform and in reports.';
  @override
  String get brandColors => 'Brand colors';
  @override
  String get brandColorsBody =>
      'AARRGGBB hex values. Shipped apps use the compiled brand palette; '
      'these feed dashboards and future runtime theming.';
  @override
  String get storeName => 'Store name';
  @override
  String get appTitle => 'App title';
  @override
  String get primaryColor => 'Primary';
  @override
  String get secondaryColor => 'Secondary';
  @override
  String get backgroundColor => 'Background';

  // -------------------------------------------------- web storefront chrome
  @override
  String get shopNow => 'Shop now';
  @override
  String get allCategories => 'All categories';
  @override
  String get seeAll => 'See all';
  @override
  String get footerShop => 'Shop';
  @override
  String get footerAccount => 'Account';

  // ----------------------------------------------------- localization tail
  @override
  String get signingIn => 'Signing In';
  @override
  String get typeYourPassword => 'Type your password';
  @override
  String get welcomeBackTo => 'Welcome back to';
  @override
  String get signInButton => 'Sign In';
  @override
  String get pleaseEnterPassword => 'Please enter your password';
  @override
  String tooManyAttemptsLocked(String remaining) =>
      'Too many invalid attempts. This email is locked for $remaining.';
  @override
  String attemptsLeftBeforeLock(int count) =>
      'Attempts left before lock: $count.';
  @override
  String emailLockedTryAgainIn(String remaining) =>
      'This email is locked. Try again in $remaining.';
  @override
  String get signinSessionExpired =>
      'Sign-in session expired. Please try again.';
  @override
  String get forgotYourPassword => 'Forgot your password? ';
  @override
  String get clickHere => 'Click here!';

  @override
  String get forgotPassword => 'Forgot Password';
  @override
  String get forgotPasswordSubtitle =>
      'Don\'t worry, we will help you recover your password in a blink of an eye ;)';
  @override
  String get pleaseConfirmEmailHere => 'Please confirm your email here';
  @override
  String get resetPassword => 'Reset Password';
  @override
  String get pleaseEnterEmailShort => 'Please enter your email';

  @override
  String get signingUp => 'Signing Up';
  @override
  String get onlyTwoSteps => 'Only two steps!';
  @override
  String get fillProfileBelow => '1. Please fill in your profile below:';
  @override
  String get name => 'Name';
  @override
  String get phone => 'Phone';
  @override
  String get pleaseEnterName => 'Please enter your name.';
  @override
  String get pleaseEnterPhone => 'Please enter your phone number.';
  @override
  String get pleaseEnterPasswordPeriod => 'Please enter your password.';
  @override
  String get oneStepAway => '2. Just one step away from the best offers!';
  @override
  String get whatGenderInterested =>
      'What gender of products are you most interested in?';
  @override
  String get selectYourBirthDate => 'Select your birth date';
  @override
  String get typeYourAddress => 'Type your Address';
  @override
  String get signUpButton => 'Sign Up';
  @override
  String get pleaseEnterAddress => 'Please enter your address.';
  @override
  String get mustBeAtLeastTwelve =>
      'You must be at least 12 years old to create an account.';

  @override
  String get tapToChangePhoto => 'Tap to change photo';
  @override
  String get registeredEmailLocked => 'Registered email (locked)';
  @override
  String get newPasswordOptional => 'New password (optional)';
  @override
  String get address => 'Address';
  @override
  String get mostInterestedIn => 'Most interested in products for:';
  @override
  String get birthDate => 'Birth Date';
  @override
  String get fillAllEditableFields => 'Please fill in all editable fields.';
  @override
  String get imageTooLarge =>
      'Selected image is larger than 10 MB. Please choose a smaller file.';
  @override
  String get profileImageUpdated => 'Profile image updated successfully.';

  @override
  String get hideCategory => 'Hide category';
  @override
  String get categoryFallback => 'Category';
  @override
  String get favoriteTooltip => 'Favorite';
  @override
  String get favoritesUnavailableOnScreen =>
      'Favorites unavailable on this screen';
  @override
  String get cartTooltip => 'Cart';
  @override
  String productFallback(String code) => 'Product $code';
  @override
  String get productLabel => 'Product';
  @override
  String get account => 'Account';

  @override
  String get confirmedPurchasesHere =>
      'Confirmed purchases will appear here.';
  @override
  String ordersLabelCount(int count) => 'Orders: $count';
  @override
  String avgTicketLabel(String amount) => 'Avg ticket: $amount';
  @override
  String get purchaseSummary => 'Purchase summary';
  @override
  String get recentPurchases => 'Recent Purchases';
  @override
  String orderNumber(String id) => 'Order #$id';
  @override
  String get created => 'Created';
  @override
  String itemCountLabel(int count) => '$count item(s)';
  @override
  String get showMore => 'Show more';
  @override
  String get showLess => 'Show less';
  @override
  String get subtotalAfterDiscount => 'Subtotal after discount';
  @override
  String get freight => 'Freight';
  @override
  String get installmentValue => 'Installment value';
  @override
  String get productsDetails => 'Products details:';
  @override
  String get noProductDetails => 'No product details available.';
  @override
  String get tapToViewDetails => 'Tap to view details';
  @override
  String get lineTotal => 'Line total';
  @override
  String colorMeta(String name, String hex) => 'Color: $name ($hex)';
  @override
  String get totalSpent => 'Total spent';
  @override
  String get averageTicket => 'Average ticket';

  @override
  String get favoritesUnavailableTitle => 'Favorites unavailable';
  @override
  String get favoritesFoundButUnavailable =>
      'We found your favorites, but product details are unavailable right now.';
  @override
  String get noFavoriteProductsAvailable =>
      'No favorite products available.';
  @override
  String unavailableCount(int count) => 'Unavailable: $count';
  @override
  String get note => 'Note';
  @override
  String favoritesCouldNotBeShown(int count) =>
      '$count favorite item(s) could not be shown because full product data is currently unavailable.';

  @override
  String get adminOrdersTagline => 'Track and manage your store\'s orders';
  @override
  String get adminOrdersEmptyBody =>
      'Orders placed in the shopper app will appear here.';
  @override
  String get colOrder => 'ORDER';
  @override
  String get colDate => 'DATE';
  @override
  String get colCustomer => 'CUSTOMER';
  @override
  String get colItems => 'ITEMS';
  @override
  String get colStatus => 'STATUS';
  @override
  String get changeStatus => 'Change status';
  @override
  String get editProduct => 'Edit product';
  @override
  String get pleaseChooseCategory => 'Please choose a category.';
  @override
  String get title => 'Title';
  @override
  String get titleRequired => 'Title is required';
  @override
  String get enterValidPrice => 'Enter a valid price';
  @override
  String get discountedPriceOptional => 'Discounted price (optional)';
  @override
  String get gender => 'Gender';
  @override
  String get genderUnisex => 'Unisex';
  @override
  String get genderMen => 'Men';
  @override
  String get genderWomen => 'Women';
  @override
  String get sizesHint => 'Comma separated, e.g. S, M, L';
  @override
  String get colorsHint =>
      'One per line: "<name> <hex>", e.g. Navy #0A2035';
  @override
  String get images => 'Images';
  @override
  String get uploadImage => 'Upload image';
  @override
  String get saveProduct => 'Save product';
  @override
  String get editCategory => 'Edit category';
  @override
  String get saveCategory => 'Save category';
}

class AppStringsPtBr extends AppStrings {
  const AppStringsPtBr();

  @override
  String get home => 'Início';
  @override
  String get favorites => 'Favoritos';
  @override
  String get myOrders => 'Meus Pedidos';
  @override
  String get myPurchases => 'Minhas Compras';
  @override
  String get myProfile => 'Meu Perfil';
  @override
  String get myFavorites => 'Meus Favoritos';
  @override
  String get myCart => 'Meu Carrinho';
  @override
  String get signOut => 'Sair';
  @override
  String get logout => 'Sair';
  @override
  String get cancel => 'Cancelar';
  @override
  String get delete => 'Excluir';
  @override
  String get remove => 'Remover';
  @override
  String get refresh => 'Atualizar';
  @override
  String get save => 'Salvar';
  @override
  String get language => 'Idioma';
  @override
  String get confirmLogoutTitle => 'Confirmar saída';
  @override
  String get confirmLogoutBody =>
      'Tem certeza de que deseja sair da sua conta?';
  @override
  String get pleaseSignIn => 'Faça login';
  @override
  String get returnToHome => 'Voltar ao início';
  @override
  String get goToFavorites => 'Ir para favoritos';
  @override
  String get continueLabel => 'Continuar';
  @override
  String get signedInUser => 'Usuário conectado';

  @override
  String statusLabel(String status) {
    switch (status) {
      case 'paid':
        return 'PAGO';
      case 'shipped':
        return 'ENVIADO';
      case 'delivered':
        return 'ENTREGUE';
      case 'cancelled':
        return 'CANCELADO';
      default:
        return 'PENDENTE';
    }
  }

  @override
  String get searchProductsHint => 'Buscar produtos…';
  @override
  String get searchResults => 'Resultados da busca';
  @override
  String get categories => 'Categorias';
  @override
  String get shopByCategory => 'Compre por categoria';
  @override
  String get shopByCategorySubtitle =>
      'Escolha uma categoria para ver seus produtos';
  @override
  String get topSelling => 'Mais Vendidos';
  @override
  String get topSellingSubtitle => 'O que todo mundo está comprando agora';
  @override
  String get newIn => 'Novidades';
  @override
  String get newInSubtitle => 'Lançamentos fresquinhos, direto na prateleira';
  @override
  String get noProductsFound => 'Nenhum produto encontrado';
  @override
  String get noNewProductsFound => 'Nenhum produto novo encontrado';
  @override
  String get noCategoriesFound => 'Nenhuma categoria encontrada';
  @override
  String get noCategoriesYet => 'Ainda não há categorias.';
  @override
  String heroWelcome(String appName) => 'Bem-vindo à $appName';
  @override
  String get heroTitle =>
      'Compre os últimos lançamentos,\nselecionados para você.';
  @override
  String get heroSubtitle =>
      'Descubra os mais vendidos e as novidades — com favoritos, carrinho e '
      'pedidos sincronizados na sua conta.';
  @override
  String get footerTagline => 'Produtos selecionados, entregues com carinho.';
  @override
  String allRightsReserved(int year, String appName) =>
      '© $year $appName. Todos os direitos reservados.';
  @override
  String resultsFor(String query) => 'Resultados para "$query"';
  @override
  String productsFound(int count) => '$count produto(s) encontrado(s)';
  @override
  String get nothingMatchedSearch =>
      'Nada corresponde à sua busca — tente outro termo.';
  @override
  String productsInCategory(int count) =>
      '$count produto(s) nesta categoria';
  @override
  String get noProductsInCategory =>
      'Ainda não há produtos nesta categoria.';
  @override
  String get clearSearch => 'Limpar busca';
  @override
  String get clearCategory => 'Limpar categoria';
  @override
  String get youMayAlsoLike => 'Você também pode gostar';
  @override
  String get youMayAlsoLikeSubtitle => 'Mais entre os mais vendidos';
  @override
  String get youMightAlsoLike => 'Você também pode gostar destes';

  @override
  String get productDetails => 'Detalhes do produto';
  @override
  String get viewLarger => 'Ver maior';
  @override
  String get zoomIn => 'Ampliar';
  @override
  String get zoomOut => 'Reduzir';
  @override
  String get resetZoom => 'Redefinir zoom';
  @override
  String get closeViewer => 'Fechar';
  @override
  String get previousImage => 'Imagem anterior';
  @override
  String get nextImage => 'Próxima imagem';
  @override
  String get description => 'Descrição';
  @override
  String get sizes => 'Tamanhos';
  @override
  String get size => 'Tamanho';
  @override
  String get colors => 'Cores';
  @override
  String get color => 'Cor';
  @override
  String get quantity => 'Quantidade';
  @override
  String get price => 'Preço';
  @override
  String get addToCart => 'Adicionar ao carrinho';
  @override
  String get goToCart => 'Ir para o carrinho';
  @override
  String get noSizesAvailable => 'Nenhum tamanho disponível';
  @override
  String get noColorsAvailable => 'Nenhuma cor disponível';
  @override
  String soldAndCode(int sold, String code) =>
      '$sold vendido(s) · Código $code';
  @override
  String salesCount(int count) => 'Vendas: $count';
  @override
  String codeLabel(String code) => 'Código: $code';
  @override
  String percentOff(num percent) => '$percent% OFF';
  @override
  String get pleaseSelectSize => 'Selecione um tamanho.';
  @override
  String get pleaseSelectColor => 'Selecione uma cor.';
  @override
  String get pleaseSignInAddToCart =>
      'Faça login para adicionar produtos ao carrinho.';
  @override
  String get pleaseSignInFavorites =>
      'Faça login para gerenciar seus favoritos.';
  @override
  String get pleaseSignInAddFavorites =>
      'Faça login para adicionar favoritos.';
  @override
  String get favoritesUnavailableNow =>
      'Os favoritos estão indisponíveis no momento.';
  @override
  String addedToCart(int count) =>
      'Adicionado ao carrinho — $count item(ns) no seu carrinho.';

  @override
  String itemsReadyForCheckout(int count) =>
      '$count item(ns) pronto(s) para finalizar';
  @override
  String get cartEmptyTitle => 'Seu carrinho está vazio';
  @override
  String get cartEmptyBody =>
      'Os itens que você adicionar ao carrinho aparecerão aqui.';
  @override
  String get continueShopping => 'Continuar comprando';
  @override
  String get signInToViewCart =>
      'Faça login para ver e confirmar seu carrinho.';
  @override
  String get orderSummary => 'Resumo do pedido';
  @override
  String get subtotal => 'Subtotal';
  @override
  String get savings => 'Descontos';
  @override
  String get freightNote => 'O frete é calculado na confirmação.';
  @override
  String get total => 'Total';
  @override
  String get payment => 'Pagamento';
  @override
  String get paymentMethod => 'Forma de pagamento';
  @override
  String get creditCard => 'Cartão de crédito';
  @override
  String get debitCard => 'Cartão de débito';
  @override
  String get credit => 'Crédito';
  @override
  String get debit => 'Débito';
  @override
  String get installments => 'Parcelas';
  @override
  String get installmentsNumber => 'Número de parcelas';
  @override
  String get cardholderName => 'Nome no cartão';
  @override
  String get cardNumber => 'Número do cartão';
  @override
  String get expiryMmYy => 'Validade (MM/AA)';
  @override
  String get cvv => 'CVV';
  @override
  String get demoCheckoutNote =>
      'Checkout de demonstração — nenhuma cobrança real é feita.';
  @override
  String get confirmPurchase => 'Confirmar compra';
  @override
  String get confirmingPurchase => 'Confirmando compra…';
  @override
  String get purchaseConfirmed => 'Compra confirmada com sucesso!';
  @override
  String get enterCardholderName => 'Informe o nome impresso no cartão.';
  @override
  String get enterValidCardNumber =>
      'Informe um número de cartão válido.';
  @override
  String get enterExpiryAsMmYy => 'Informe a validade no formato MM/AA.';
  @override
  String get cardExpired => 'Este cartão parece estar vencido.';
  @override
  String get enterValidCvv => 'Informe um CVV válido.';
  @override
  String get signInToConfirmPurchase =>
      'Faça login para confirmar sua compra.';
  @override
  String get unableToLoadProfile =>
      'Não foi possível carregar seus dados. Tente novamente.';
  @override
  String get productDetailsUnavailable =>
      'Os detalhes deste produto estão indisponíveis.';
  @override
  String get unableToOpenProduct =>
      'Não foi possível abrir os detalhes do produto agora.';
  @override
  String itemMeta(String size, String color, String quantity, String price) =>
      'Tam $size · Cor $color · Qtd $quantity · $price cada';
  @override
  String get draftItems => 'Itens do carrinho';
  @override
  String itemsCount(int count) => 'Itens: $count';
  @override
  String savedAmount(String amount) => 'Economia: $amount';
  @override
  String totalAmount(String amount) => 'Total: $amount';
  @override
  String get originalTotal => 'Total original';
  @override
  String get discountedTotal => 'Total com desconto';
  @override
  String get totalSaved => 'Total economizado';
  @override
  String get cartSummary => 'Resumo do carrinho';
  @override
  String get unitPrice => 'Preço unitário';
  @override
  String get unitDiscounted => 'Unitário com desconto';
  @override
  String get discounted => 'Com desconto';

  @override
  String savedProducts(int count) => '$count produto(s) salvo(s)';
  @override
  String get favoritesEmptyHint =>
      'Toque no coração nas listas de produtos para salvar favoritos.';
  @override
  String get favoritesEmptyWebHint =>
      'Nenhum favorito ainda — toque no coração de um produto para salvá-lo.';
  @override
  String get signInToViewFavorites =>
      'Faça login para ver seus produtos favoritos.';
  @override
  String get couldNotLoadFavorites =>
      'Não foi possível carregar os favoritos';
  @override
  String favoritesCount(int count) => 'Favoritos: $count';
  @override
  String get noFavoritesYet => 'Nenhum favorito ainda';

  @override
  String orderPlaced(String date) => 'Pedido realizado em $date';
  @override
  String ordersCount(int count) => '$count pedido(s)';
  @override
  String get purchasesEmptySubtitle =>
      'Os pedidos que você fizer aparecerão aqui';
  @override
  String get noPurchasesYet => 'Nenhuma compra ainda';
  @override
  String get purchasesEmptyBody =>
      'Quando você confirmar uma compra, ela aparecerá aqui.';
  @override
  String get signInToViewPurchases =>
      'Faça login para ver suas compras.';
  @override
  String get couldNotLoadPurchases =>
      'Não foi possível carregar as compras';
  @override
  String youSaved(String amount) => 'Você economizou $amount';
  @override
  String freightLabel(String amount) => 'Frete $amount';
  @override
  String totalLabel(String amount) => 'Total $amount';

  @override
  String get signInWithYourEmail => 'Entre com seu e-mail';
  @override
  String get pleaseEnterEmail => 'Informe seu e-mail.';
  @override
  String get pleaseEnterValidEmail => 'Informe um endereço de e-mail válido.';
  @override
  String emailTemporarilyLocked(String remaining) =>
      'Este e-mail está temporariamente bloqueado. Tente novamente em '
      '$remaining.';
  @override
  String get dontHaveAccount => 'Não tem uma conta? ';
  @override
  String get signUpExclamation => 'Cadastre-se!';

  @override
  String get storeAdmin => 'Admin da Loja';
  @override
  String get manage => 'GERENCIAR';
  @override
  String get orders => 'Pedidos';
  @override
  String get products => 'Produtos';
  @override
  String get settings => 'Configurações';
  @override
  String get welcomeBack => 'Bem-vindo de volta';
  @override
  String get signInToManageStore => 'Entre para gerenciar sua loja';
  @override
  String get email => 'E-mail';
  @override
  String get password => 'Senha';
  @override
  String get signIn => 'Entrar';
  @override
  String get accessRestrictedToOwners =>
      'Acesso restrito a donos de loja.';
  @override
  String get selectStore => 'Selecione uma loja';
  @override
  String get signedInAsPlatformOwner =>
      'Você está conectado como dono da plataforma.';
  @override
  String get storeIdLabel => 'ID da loja';
  @override
  String get storeIdHint => 'ex.: buybuy';
  @override
  String adminOrdersSubtitle(int count) => '$count pedido(s) na sua loja';
  @override
  String get adminOrdersEmpty => 'Nenhum pedido ainda.';
  @override
  String get adminProductsSubtitle => 'Gerencie o catálogo da sua loja';
  @override
  String adminProductsCount(int count) =>
      '$count produto(s) no seu catálogo';
  @override
  String get newProduct => 'Novo produto';
  @override
  String get adminProductsEmpty =>
      'Nenhum produto ainda — crie o primeiro.';
  @override
  String get deleteProduct => 'Excluir produto';
  @override
  String deleteProductConfirm(String title) =>
      'Excluir "$title"? Esta ação não pode ser desfeita.';
  @override
  String get adminCategoriesSubtitle => 'Organize seu catálogo';
  @override
  String adminCategoriesCount(int count) =>
      '$count categoria(s) no seu catálogo';
  @override
  String get newCategory => 'Nova categoria';
  @override
  String get adminCategoriesEmpty =>
      'Nenhuma categoria ainda — crie a primeira.';
  @override
  String get deleteCategory => 'Excluir categoria';
  @override
  String deleteCategoryConfirm(String title) =>
      'Excluir "$title"? Os produtos mantêm seu categoryId.';
  @override
  String get settingsSubtitle => 'Identidade da loja e cores da marca';
  @override
  String get saveChanges => 'Salvar alterações';
  @override
  String get savingEllipsis => 'Salvando…';
  @override
  String get storeIdentity => 'Identidade da loja';
  @override
  String get storeIdentityBody =>
      'Exibida em toda a plataforma e nos relatórios.';
  @override
  String get brandColors => 'Cores da marca';
  @override
  String get brandColorsBody =>
      'Valores hex AARRGGBB. Os apps publicados usam a paleta compilada da '
      'marca; estes valores alimentam dashboards e o tema dinâmico futuro.';
  @override
  String get storeName => 'Nome da loja';
  @override
  String get appTitle => 'Título do app';
  @override
  String get primaryColor => 'Primária';
  @override
  String get secondaryColor => 'Secundária';
  @override
  String get backgroundColor => 'Fundo';

  // -------------------------------------------------- web storefront chrome
  @override
  String get shopNow => 'Comprar agora';
  @override
  String get allCategories => 'Todas as categorias';
  @override
  String get seeAll => 'Ver tudo';
  @override
  String get footerShop => 'Loja';
  @override
  String get footerAccount => 'Conta';

  // ----------------------------------------------------- localization tail
  @override
  String get signingIn => 'Entrando';
  @override
  String get typeYourPassword => 'Digite sua senha';
  @override
  String get welcomeBackTo => 'Bem-vindo de volta à';
  @override
  String get signInButton => 'Entrar';
  @override
  String get pleaseEnterPassword => 'Informe sua senha';
  @override
  String tooManyAttemptsLocked(String remaining) =>
      'Muitas tentativas inválidas. Este e-mail está bloqueado por '
      '$remaining.';
  @override
  String attemptsLeftBeforeLock(int count) =>
      'Tentativas restantes antes do bloqueio: $count.';
  @override
  String emailLockedTryAgainIn(String remaining) =>
      'Este e-mail está bloqueado. Tente novamente em $remaining.';
  @override
  String get signinSessionExpired =>
      'A sessão de login expirou. Tente novamente.';
  @override
  String get forgotYourPassword => 'Esqueceu sua senha? ';
  @override
  String get clickHere => 'Clique aqui!';

  @override
  String get forgotPassword => 'Recuperar Senha';
  @override
  String get forgotPasswordSubtitle =>
      'Não se preocupe, vamos ajudar você a recuperar sua senha num piscar '
      'de olhos ;)';
  @override
  String get pleaseConfirmEmailHere => 'Confirme seu e-mail aqui';
  @override
  String get resetPassword => 'Redefinir Senha';
  @override
  String get pleaseEnterEmailShort => 'Informe seu e-mail';

  @override
  String get signingUp => 'Cadastrando';
  @override
  String get onlyTwoSteps => 'Só dois passos!';
  @override
  String get fillProfileBelow => '1. Preencha seu perfil abaixo:';
  @override
  String get name => 'Nome';
  @override
  String get phone => 'Telefone';
  @override
  String get pleaseEnterName => 'Informe seu nome.';
  @override
  String get pleaseEnterPhone => 'Informe seu número de telefone.';
  @override
  String get pleaseEnterPasswordPeriod => 'Informe sua senha.';
  @override
  String get oneStepAway => '2. A um passo das melhores ofertas!';
  @override
  String get whatGenderInterested =>
      'Produtos de qual gênero mais interessam a você?';
  @override
  String get selectYourBirthDate => 'Selecione sua data de nascimento';
  @override
  String get typeYourAddress => 'Digite seu endereço';
  @override
  String get signUpButton => 'Cadastrar';
  @override
  String get pleaseEnterAddress => 'Informe seu endereço.';
  @override
  String get mustBeAtLeastTwelve =>
      'Você precisa ter pelo menos 12 anos para criar uma conta.';

  @override
  String get tapToChangePhoto => 'Toque para trocar a foto';
  @override
  String get registeredEmailLocked => 'E-mail cadastrado (bloqueado)';
  @override
  String get newPasswordOptional => 'Nova senha (opcional)';
  @override
  String get address => 'Endereço';
  @override
  String get mostInterestedIn => 'Mais interessado em produtos para:';
  @override
  String get birthDate => 'Data de Nascimento';
  @override
  String get fillAllEditableFields =>
      'Preencha todos os campos editáveis.';
  @override
  String get imageTooLarge =>
      'A imagem selecionada é maior que 10 MB. Escolha um arquivo menor.';
  @override
  String get profileImageUpdated =>
      'Foto de perfil atualizada com sucesso.';

  @override
  String get hideCategory => 'Ocultar categoria';
  @override
  String get categoryFallback => 'Categoria';
  @override
  String get favoriteTooltip => 'Favoritar';
  @override
  String get favoritesUnavailableOnScreen =>
      'Favoritos indisponíveis nesta tela';
  @override
  String get cartTooltip => 'Carrinho';
  @override
  String productFallback(String code) => 'Produto $code';
  @override
  String get productLabel => 'Produto';
  @override
  String get account => 'Conta';

  @override
  String get confirmedPurchasesHere =>
      'As compras confirmadas aparecerão aqui.';
  @override
  String ordersLabelCount(int count) => 'Pedidos: $count';
  @override
  String avgTicketLabel(String amount) => 'Ticket médio: $amount';
  @override
  String get purchaseSummary => 'Resumo das compras';
  @override
  String get recentPurchases => 'Compras Recentes';
  @override
  String orderNumber(String id) => 'Pedido #$id';
  @override
  String get created => 'Criado em';
  @override
  String itemCountLabel(int count) => '$count item(ns)';
  @override
  String get showMore => 'Mostrar mais';
  @override
  String get showLess => 'Mostrar menos';
  @override
  String get subtotalAfterDiscount => 'Subtotal com desconto';
  @override
  String get freight => 'Frete';
  @override
  String get installmentValue => 'Valor da parcela';
  @override
  String get productsDetails => 'Detalhes dos produtos:';
  @override
  String get noProductDetails =>
      'Nenhum detalhe de produto disponível.';
  @override
  String get tapToViewDetails => 'Toque para ver os detalhes';
  @override
  String get lineTotal => 'Total do item';
  @override
  String colorMeta(String name, String hex) => 'Cor: $name ($hex)';
  @override
  String get totalSpent => 'Total gasto';
  @override
  String get averageTicket => 'Ticket médio';

  @override
  String get favoritesUnavailableTitle => 'Favoritos indisponíveis';
  @override
  String get favoritesFoundButUnavailable =>
      'Encontramos seus favoritos, mas os detalhes dos produtos estão '
      'indisponíveis no momento.';
  @override
  String get noFavoriteProductsAvailable =>
      'Nenhum produto favorito disponível.';
  @override
  String unavailableCount(int count) => 'Indisponíveis: $count';
  @override
  String get note => 'Observação';
  @override
  String favoritesCouldNotBeShown(int count) =>
      '$count item(ns) favorito(s) não puderam ser exibidos porque os dados '
      'completos dos produtos estão indisponíveis no momento.';

  @override
  String get adminOrdersTagline =>
      'Acompanhe e gerencie os pedidos da sua loja';
  @override
  String get adminOrdersEmptyBody =>
      'Os pedidos feitos no app do comprador aparecerão aqui.';
  @override
  String get colOrder => 'PEDIDO';
  @override
  String get colDate => 'DATA';
  @override
  String get colCustomer => 'CLIENTE';
  @override
  String get colItems => 'ITENS';
  @override
  String get colStatus => 'STATUS';
  @override
  String get changeStatus => 'Alterar status';
  @override
  String get editProduct => 'Editar produto';
  @override
  String get pleaseChooseCategory => 'Escolha uma categoria.';
  @override
  String get title => 'Título';
  @override
  String get titleRequired => 'O título é obrigatório';
  @override
  String get enterValidPrice => 'Informe um preço válido';
  @override
  String get discountedPriceOptional => 'Preço com desconto (opcional)';
  @override
  String get gender => 'Gênero';
  @override
  String get genderUnisex => 'Unissex';
  @override
  String get genderMen => 'Masculino';
  @override
  String get genderWomen => 'Feminino';
  @override
  String get sizesHint => 'Separados por vírgula, ex.: P, M, G';
  @override
  String get colorsHint =>
      'Um por linha: "<nome> <hex>", ex.: Azul-marinho #0A2035';
  @override
  String get images => 'Imagens';
  @override
  String get uploadImage => 'Enviar imagem';
  @override
  String get saveProduct => 'Salvar produto';
  @override
  String get editCategory => 'Editar categoria';
  @override
  String get saveCategory => 'Salvar categoria';
}

enum Flavor {
  courier,  // Motokurye uygulaması
  cargo     // Kargo uygulaması
}

class F {
  static Flavor? appFlavor;

  static String get title {
    switch (appFlavor) {
      case Flavor.courier:
        return 'ONLOG Kurye';
      case Flavor.cargo:
        return 'ONLOG Kargo';
      default:
        return 'ONLOG Teslimat';
    }
  }

  static String get appId {
    switch (appFlavor) {
      case Flavor.courier:
        return 'com.onlog.courier';
      case Flavor.cargo:
        return 'com.onlog.cargo';
      default:
        return 'com.onlog.delivery';
    }
  }

  static String get apiBaseUrl {
    switch (appFlavor) {
      case Flavor.courier:
        return 'https://api.onlog.com/courier';
      case Flavor.cargo:
        return 'https://api.onlog.com/cargo';
      default:
        return 'https://api.onlog.com';
    }
  }
  
  static bool get isCourier => appFlavor == Flavor.courier;
  static bool get isCargo => appFlavor == Flavor.cargo;
}
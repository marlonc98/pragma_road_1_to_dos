enum Flavor { mock, dev, prod }

class F {
  static late final Flavor appFlavor;

  static String get name => appFlavor.name;

  static String get title {
    switch (appFlavor) {
      case Flavor.mock:
        return '[MOCK] Gestor de Tareas';
      case Flavor.dev:
        return '[DEV] Gestor de Tareas';
      case Flavor.prod:
        return 'Gestor de Tareas';
    }
  }
}

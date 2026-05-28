/// Frases de guía por voz para Comercialización (rol campesino).
///
/// Nota: se usan frases cortas para que el audio sea ágil y repetible.
final class ComercializacionAudioPhrases {
  ComercializacionAudioPhrases._();

  // --- Pantallas (welcome) ---

  static const List<String> homeWelcome = [
    'Bienvenido al mercado.',
    'Aquí gestionas tus productos, tus pedidos y herramientas para vender mejor.',
    'Si quieres volver a escuchar, pulsa Repetir.',
    'Elige una opción para continuar.',
  ];

  static const List<String> misProductosWelcome = [
    'Mis productos.',
    'Aquí publicas, editas o eliminas lo que ofreces en tu tienda.',
    'Pulsa Añadir producto para publicar algo nuevo.',
  ];

  static const List<String> ordenesWelcome = [
    'Mis pedidos.',
    'Toca un pedido para ver detalles y coordinar por chat.',
  ];

  static const List<String> ordenDetalleWelcome = [
    'Detalle del pedido.',
    'Revisa los productos, el estado y usa el chat para coordinar la entrega.',
  ];

  static const List<String> redComunitariaWelcome = [
    'Red comunitaria.',
    'Aquí ves productores cercanos y pedidos de ayuda.',
    'Puedes ajustar la distancia con el control.',
  ];

  static const List<String> ayudaChatWelcome = [
    'Chat de ayuda entre productores.',
    'Escribe un mensaje para coordinar la entrega o el apoyo.',
  ];

  static const List<String> beneficiosWelcome = [
    'Beneficios.',
    'Aquí canjeas puntos para que tu tienda destaque y más personas te vean.',
  ];

  static const List<String> indicadoresWelcome = [
    'Precios de referencia.',
    'Consulta indicadores para orientar tus precios.',
  ];

  static const List<String> productoFormWelcome = [
    'Añadir producto.',
    'Primero agrega una foto, luego nombre y precio, y al final pulsa Guardar.',
  ];

  static const List<String> productoFormEditWelcome = [
    'Editar producto.',
    'Actualiza los datos y pulsa Guardar cuando termines.',
  ];

  // --- Acciones (frases cortas) ---

  // Home / navegación
  static const String goMisProductos = 'Abriendo Mis productos.';
  static const String goMisPedidos = 'Abriendo Mis pedidos.';
  static const String goRed = 'Abriendo Red comunitaria.';
  static const String goBeneficios = 'Abriendo Beneficios.';
  static const String goIndicadores = 'Abriendo Precios de referencia.';

  // Mis productos
  static const String addProducto = 'Vamos a añadir un producto.';
  static const String editProducto = 'Editar producto.';
  static const String deleteProducto = 'Eliminar producto.';
  static const String deletedOk = 'Producto eliminado.';

  // Orden detalle
  static const String cancelPedido = 'Cancelando pedido.';
  static const String entregado = 'Marcando como entregado.';
  static const String pedirAyuda = 'Pidiendo ayuda a productores cercanos.';
  static const String abrirChatAyuda = 'Abriendo chat de ayuda.';

  // Producto form (interacciones)
  static const String formFoto = 'Toca para agregar una foto del producto.';
  static const String formNombre = 'Escribe el nombre del producto.';
  static const String formDescripcion = 'La descripción es opcional, pero ayuda.';
  static const String formPrecio = 'Escribe el precio. Solo números.';
  static const String formUnidad = 'Elige si vendes por kilos, libras o por unidad.';
  static const String formGuardar = 'Pulsa Guardar para publicar.';
  static const String formRevisaCampos = 'Revisa los campos marcados.';
  static const String formGuardado = 'Guardado.';

  // Beneficios
  static const String beneficioActivando = 'Activando beneficio.';

  // Indicadores
  static const String indicadoresActualizar = 'Actualizando precios de referencia.';
}

